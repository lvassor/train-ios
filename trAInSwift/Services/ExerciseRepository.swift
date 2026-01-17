//
//  ExerciseRepository.swift
//  trAInSwift
//
//  High-level service for exercise selection with business rules
//  Updated for new database schema with equipment_category/equipment_specific
//  Updated with scoring-based selection algorithm
//

import Foundation

// MARK: - Exercise Scoring Result

/// Result of scoring an exercise for selection
struct ScoredExercise {
    let exercise: DBExercise
    let score: Int
    let isCompound: Bool

    /// For sorting: compounds first, then by complexity (descending)
    var displaySortKey: (Int, Int) {
        return (isCompound ? 0 : 1, -exercise.numericComplexity)
    }
}

// MARK: - Exercise Selection Validation

/// Warnings that can occur during exercise selection
/// NOTE: Injuries do NOT filter exercises - they only show warning icons in UI
enum ExerciseSelectionWarning: Equatable {
    case noExercisesForMuscle(muscle: String)
    case insufficientExercises(muscle: String, requested: Int, found: Int)
    case equipmentLimitedSelection(muscle: String)
    case lowFillRate(fillRate: Double)
    case exerciseRepeats

    var message: String {
        switch self {
        case .noExercisesForMuscle(let muscle):
            return "No exercises available for \(muscle). Check your equipment selection."
        case .insufficientExercises(let muscle, let requested, let found):
            return "Only found \(found) of \(requested) exercises for \(muscle)."
        case .equipmentLimitedSelection(let muscle):
            return "Limited exercise variety for \(muscle) with selected equipment."
        case .lowFillRate(let fillRate):
            return "Programme only \(String(format: "%.1f", fillRate))% filled due to equipment limitations."
        case .exerciseRepeats:
            return "Some exercises repeated due to limited equipment variety."
        }
    }

    var title: String {
        return "Exercise Selection Notice"
    }
}

/// Result of exercise selection including any warnings
struct ExerciseSelectionResult {
    let exercises: [DBExercise]
    let warnings: [ExerciseSelectionWarning]

    var hasWarnings: Bool { !warnings.isEmpty }
}

class ExerciseRepository {
    private let dbManager = ExerciseDatabaseManager.shared

    init() {
        print("🔧 ExerciseRepository init() called")
        print("🔧 Using ExerciseDatabaseManager.shared")
    }

    // MARK: - Stage 1: Build User Pool

    /// Build the pool of available exercises based on user's equipment and experience level
    /// This is the first stage of the selection algorithm
    /// NOTE: Injuries do NOT filter exercises - they are only used for UI warnings in WorkoutOverview
    func buildUserPool(
        primaryMuscle: String?,
        availableEquipment: [String],
        experienceLevel: ExperienceLevel,
        userInjuries: [String],
        excludedExerciseIds: Set<String>
    ) throws -> (pool: [DBExercise], maxComplexity: Int, warnings: [ExerciseSelectionWarning]) {

        // Get max complexity from experience level (hardcoded rules)
        let complexityRules = experienceLevel.complexityRules
        let maxComplexity = complexityRules.maxComplexity
        let warnings: [ExerciseSelectionWarning] = []

        print("🏊 Building user pool for \(primaryMuscle ?? "all muscles")")
        print("   Equipment: \(availableEquipment)")
        print("   Max complexity: \(maxComplexity)")
        print("   User injuries (for UI only, not filtering): \(userInjuries)")

        // Stage 1: Filter by equipment AND complexity (from DB)
        // NOTE: Injuries are NOT used for filtering - exercises with injury contraindications
        // are still included but will show a warning icon in the UI
        let filter = ExerciseDatabaseFilter(
            equipmentCategories: availableEquipment,
            maxComplexity: maxComplexity,
            primaryMuscle: primaryMuscle,
            excludeInjuries: [], // Never filter by injuries - they're for UI warnings only
            excludeExerciseIds: excludedExerciseIds
        )

        let pool = try dbManager.fetchExercises(filter: filter)

        print("   Pool size: \(pool.count)")

        // Add warning if pool is empty
        var resultWarnings = warnings
        if pool.isEmpty, let muscle = primaryMuscle {
            resultWarnings.append(.noExercisesForMuscle(muscle: muscle))
        }

        return (pool, maxComplexity, resultWarnings)
    }

    // MARK: - Stage 2: Score and Select Exercises

    /// MCV Heuristic: Select exercises using Most Constrained Variable approach
    /// Uses canonical_rating for deterministic ordering instead of weighted random
    func mcvSelectExercises(
        from pool: [DBExercise],
        count: Int,
        experienceLevel: ExperienceLevel,
        excludedExerciseIds: Set<String>,
        excludedDisplayNames: Set<String>,
        excludedCanonicalNames: Set<String> = [],  // Session-level canonical name exclusion
        allowDisplayNameRepeats: Bool = false  // Soft constraint relaxation
    ) -> ([DBExercise], Bool) {  // Returns (exercises, wasRelaxed)

        guard !pool.isEmpty else { return ([], false) }

        // Hard constraints: filter by IDs and canonical names (within session)
        var availablePool = pool.filter {
            !excludedExerciseIds.contains($0.exerciseId) &&
            !excludedCanonicalNames.contains($0.canonicalName)
        }

        // Soft constraint: filter by display names (across programme) unless relaxed
        if !allowDisplayNameRepeats {
            availablePool = availablePool.filter {
                !excludedDisplayNames.contains($0.displayName)
            }
        }

        var selectedExercises: [DBExercise] = []
        var usedCanonicalNames = Set<String>()
        let relaxationUsed = allowDisplayNameRepeats && !excludedDisplayNames.isEmpty

        print("🎯 MCV Heuristic selecting \(count) exercises from pool of \(availablePool.count)")
        print("   Display name relaxation: \(allowDisplayNameRepeats ? "ENABLED" : "DISABLED")")

        // MCV Selection: Select highest canonical_rating exercises
        let sortedPool = availablePool.sorted { lhs, rhs in
            // First: Higher canonical rating
            if lhs.canonicalRating != rhs.canonicalRating {
                return lhs.canonicalRating > rhs.canonicalRating
            }
            // Tie-breaker: Alphabetical by display name for deterministic results
            return lhs.displayName < rhs.displayName
        }

        for exercise in sortedPool {
            if selectedExercises.count >= count { break }

            // Skip if canonical name already used in this selection
            if usedCanonicalNames.contains(exercise.canonicalName) { continue }

            selectedExercises.append(exercise)
            usedCanonicalNames.insert(exercise.canonicalName)

            print("   ✅ Selected: \(exercise.displayName) (rating: \(exercise.canonicalRating))")
        }

        print("   📊 Selected \(selectedExercises.count) of \(count) requested exercises")

        return (selectedExercises, relaxationUsed)
    }

    /// Calculate score for an exercise based on business rules
    /// Uses canonical_rating (0-100) as primary scoring mechanism
    private func calculateScore(for exercise: DBExercise, experienceLevel: ExperienceLevel) -> Int {
        // Use canonical_rating directly as the scoring mechanism
        // Higher canonical_rating = more important/compound exercises get higher scores
        // This replaces the old isolation vs compound distinction
        return exercise.canonicalRating
    }

    /// Weighted random selection - higher scores have higher probability
    private func weightedRandomSelect(from candidates: [ScoredExercise]) -> ScoredExercise? {
        guard !candidates.isEmpty else { return nil }

        let totalScore = candidates.reduce(0) { $0 + $1.score }
        guard totalScore > 0 else { return candidates.first }

        let randomValue = Int.random(in: 0..<totalScore)
        var cumulative = 0

        for candidate in candidates {
            cumulative += candidate.score
            if randomValue < cumulative {
                return candidate
            }
        }

        return candidates.last
    }

    // MARK: - Stage 3: Sort for Display

    /// Sort exercises for display: compounds first, then by complexity (descending)
    func sortForDisplay(_ exercises: [ScoredExercise]) -> [DBExercise] {
        return exercises
            .sorted { lhs, rhs in
                // First: compounds before isolations
                if lhs.isCompound != rhs.isCompound {
                    return lhs.isCompound
                }
                // Second: higher complexity first
                return lhs.exercise.complexityLevel > rhs.exercise.complexityLevel
            }
            .map { $0.exercise }
    }

    // MARK: - Main Selection Method (Updated with Scoring)

    /// Select exercises for a workout session using the new scoring algorithm
    func selectExercises(
        count: Int,
        movementPattern: String? = nil,
        primaryMuscle: String? = nil,
        experienceLevel: ExperienceLevel,
        availableEquipment: [String],
        userInjuries: [String],
        excludedExerciseIds: Set<String>,
        allowComplexity4: Bool = false,
        requireComplexity4First: Bool = false
    ) throws -> [DBExercise] {

        let result = try selectExercisesWithWarnings(
            count: count,
            movementPattern: movementPattern,
            primaryMuscle: primaryMuscle,
            experienceLevel: experienceLevel,
            availableEquipment: availableEquipment,
            userInjuries: userInjuries,
            excludedExerciseIds: excludedExerciseIds,
            allowComplexity4: allowComplexity4,
            requireComplexity4First: requireComplexity4First
        )

        return result.exercises
    }

    /// Select exercises with detailed warnings for UI display using MCV heuristic
    func selectExercisesWithWarnings(
        count: Int,
        movementPattern: String? = nil,
        primaryMuscle: String? = nil,
        experienceLevel: ExperienceLevel,
        availableEquipment: [String],
        userInjuries: [String],
        excludedExerciseIds: Set<String>,
        excludedDisplayNames: Set<String> = [],
        excludedCanonicalNames: Set<String> = [],  // Session-level: no same movement pattern in one session
        allowComplexity4: Bool = false,
        requireComplexity4First: Bool = false
    ) throws -> ExerciseSelectionResult {

        var allWarnings: [ExerciseSelectionWarning] = []

        // Stage 1: Build User Pool
        let (pool, _, poolWarnings) = try buildUserPool(
            primaryMuscle: primaryMuscle,
            availableEquipment: availableEquipment,
            experienceLevel: experienceLevel,
            userInjuries: userInjuries,
            excludedExerciseIds: excludedExerciseIds
        )
        allWarnings.append(contentsOf: poolWarnings)

        // Handle empty pool
        if pool.isEmpty {
            return ExerciseSelectionResult(exercises: [], warnings: allWarnings)
        }

        // Stage 2: MCV Selection with soft constraint relaxation
        var (selectedExercises, wasRelaxed) = mcvSelectExercises(
            from: pool,
            count: count,
            experienceLevel: experienceLevel,
            excludedExerciseIds: excludedExerciseIds,
            excludedDisplayNames: excludedDisplayNames,
            excludedCanonicalNames: excludedCanonicalNames,
            allowDisplayNameRepeats: false
        )

        // If insufficient exercises and haven't relaxed constraints, try with relaxation
        if selectedExercises.count < count && !wasRelaxed {
            print("🔄 Attempting soft constraint relaxation for \(primaryMuscle ?? "muscle")")
            let (relaxedExercises, _) = mcvSelectExercises(
                from: pool,
                count: count,
                experienceLevel: experienceLevel,
                excludedExerciseIds: excludedExerciseIds,
                excludedDisplayNames: excludedDisplayNames,
                excludedCanonicalNames: excludedCanonicalNames,
                allowDisplayNameRepeats: true
            )

            if relaxedExercises.count > selectedExercises.count {
                selectedExercises = relaxedExercises
                allWarnings.append(.exerciseRepeats)
                print("   ✅ Relaxation improved selection: \(relaxedExercises.count) exercises")
            }
        }

        // Check for insufficient exercises
        if selectedExercises.count < count, let muscle = primaryMuscle {
            allWarnings.append(.insufficientExercises(
                muscle: muscle,
                requested: count,
                found: selectedExercises.count
            ))
        }

        // Stage 3: Sort by canonical_rating (already sorted by MCV, but ensure consistency)
        let sortedExercises = selectedExercises.sorted { lhs, rhs in
            // Higher canonical rating first
            if lhs.canonicalRating != rhs.canonicalRating {
                return lhs.canonicalRating > rhs.canonicalRating
            }
            // Tie-breaker: alphabetical
            return lhs.displayName < rhs.displayName
        }

        print("✅ Selection complete: \(sortedExercises.count) exercises for \(primaryMuscle ?? "session")")

        return ExerciseSelectionResult(exercises: sortedExercises, warnings: allWarnings)
    }

    /// Select exercises ensuring variety (prefer different canonical names) - LEGACY METHOD
    private func selectDiverseExercises(
        from candidates: [DBExercise],
        count: Int,
        avoidingIds: Set<String>
    ) -> [DBExercise] {
        var selected: [DBExercise] = []
        var usedCanonicalNames = Set<String>()

        // First pass: select exercises with unique canonical names
        for exercise in candidates {
            if selected.count >= count { break }
            if avoidingIds.contains(exercise.exerciseId) { continue }

            if !usedCanonicalNames.contains(exercise.canonicalName) {
                selected.append(exercise)
                usedCanonicalNames.insert(exercise.canonicalName)
            }
        }

        // Second pass: fill remaining slots if needed
        if selected.count < count {
            for exercise in candidates {
                if selected.count >= count { break }
                if avoidingIds.contains(exercise.exerciseId) { continue }
                if selected.contains(where: { $0.exerciseId == exercise.exerciseId }) { continue }

                selected.append(exercise)
            }
        }

        return Array(selected.prefix(count))
    }

    // MARK: - Alternative Exercise Lookup

    /// Find alternative exercises for a given exercise (same canonical name)
    /// NOTE: Injuries do NOT filter alternatives - they're for UI warnings only
    func findAlternatives(
        for exercise: DBExercise,
        experienceLevel: ExperienceLevel,
        availableEquipment: [String],
        userInjuries: [String],
        excludedExerciseIds: Set<String>
    ) throws -> [DBExercise] {

        let complexityRules = experienceLevel.complexityRules

        var excludedIds = excludedExerciseIds
        excludedIds.insert(exercise.exerciseId)

        let filter = ExerciseDatabaseFilter(
            canonicalName: exercise.canonicalName,
            equipmentCategories: availableEquipment,
            maxComplexity: complexityRules.maxComplexity,
            primaryMuscle: exercise.primaryMuscle,
            excludeInjuries: [], // Never filter by injuries - they're for UI warnings only
            excludeExerciseIds: excludedIds
        )

        return try dbManager.fetchAlternatives(for: exercise, filter: filter)
    }

    // MARK: - Utility Methods

    /// Get experience complexity rules
    func getComplexityRules(for experienceLevel: ExperienceLevel) -> ExperienceComplexityRules {
        return experienceLevel.complexityRules
    }

    /// Check if an exercise is contraindicated for given injuries
    func isExerciseContraindicated(exercise: DBExercise, for injuries: [String]) throws -> Bool {
        return try dbManager.isContraindicated(exercise: exercise, forInjuries: injuries)
    }

    /// Get all available canonical names (movement patterns)
    func getAvailableCanonicalNames() throws -> [String] {
        return try dbManager.fetchAvailableCanonicalNames()
    }

    /// Get all available muscles
    func getAvailableMuscles() throws -> [String] {
        return try dbManager.fetchAvailableMuscles()
    }

    /// Fetch exercise by ID
    func getExercise(byId id: String) throws -> DBExercise? {
        return try dbManager.fetchExercise(byId: id)
    }
}

// MARK: - Repository Errors

enum RepositoryError: LocalizedError {
    case experienceLevelNotFound
    case noExercisesFound
    case invalidFilter

    var errorDescription: String? {
        switch self {
        case .experienceLevelNotFound:
            return "Experience level not found in database."
        case .noExercisesFound:
            return "No exercises match the specified criteria."
        case .invalidFilter:
            return "Invalid filter parameters."
        }
    }
}
