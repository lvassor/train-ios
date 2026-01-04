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
        return (isCompound ? 0 : 1, -exercise.complexityLevel)
    }
}

// MARK: - Exercise Selection Validation

/// Warnings that can occur during exercise selection
/// NOTE: Injuries do NOT filter exercises - they only show warning icons in UI
enum ExerciseSelectionWarning: Equatable {
    case noExercisesForMuscle(muscle: String)
    case insufficientExercises(muscle: String, requested: Int, found: Int)
    case equipmentLimitedSelection(muscle: String)

    var message: String {
        switch self {
        case .noExercisesForMuscle(let muscle):
            return "No exercises available for \(muscle). Check your equipment selection."
        case .insufficientExercises(let muscle, let requested, let found):
            return "Only found \(found) of \(requested) exercises for \(muscle)."
        case .equipmentLimitedSelection(let muscle):
            return "Limited exercise variety for \(muscle) with selected equipment."
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

    /// Score exercises and select based on weighted random selection
    /// Scoring rules:
    /// - Compounds: complexity 4 = 20pts, complexity 3 = 15pts, complexity 2 = 10pts, complexity 1 = 5pts
    /// - Isolations: Advanced = 8pts, Intermediate = 6pts, Beginner/NoExp = 4pts
    /// excludedDisplayNames: Program-level tracking of used display names to prevent duplicates across sessions
    func scoreAndSelectExercises(
        from pool: [DBExercise],
        count: Int,
        experienceLevel: ExperienceLevel,
        excludedExerciseIds: Set<String>,
        excludedDisplayNames: Set<String>,
        excludedCanonicalNames: Set<String> = [],  // Session-level canonical name exclusion
        allowComplexity4: Bool,
        requireComplexity4First: Bool,
        maxComplexity: Int
    ) -> [ScoredExercise] {

        guard !pool.isEmpty else { return [] }

        // Filter out exercises by ID, display name (program-level), and canonical name (session-level)
        let availablePool = pool.filter {
            !excludedExerciseIds.contains($0.exerciseId) &&
            !excludedDisplayNames.contains($0.displayName) &&
            !excludedCanonicalNames.contains($0.canonicalName)
        }
        var selectedExercises: [ScoredExercise] = []

        print("🎯 Scoring \(availablePool.count) exercises for selection (need \(count))")
        print("   Already excluded \(excludedDisplayNames.count) display names from program")
        print("   Already excluded \(excludedCanonicalNames.count) canonical names from session")
        print("   Experience level for scoring: \(experienceLevel)")

        // Score all exercises
        var scoredPool = availablePool.map { exercise -> ScoredExercise in
            let score = calculateScore(for: exercise, experienceLevel: experienceLevel)
            let isCompound = !exercise.isIsolation
            return ScoredExercise(exercise: exercise, score: score, isCompound: isCompound)
        }

        // Debug: Print top 5 scored exercises
        let topScored = scoredPool.sorted { $0.score > $1.score }.prefix(5)
        print("   📊 Top 5 scored exercises in pool:")
        for scored in topScored {
            print("      - \(scored.exercise.displayName): \(scored.score)pts (complexity: \(scored.exercise.complexityLevel), equip: \(scored.exercise.equipmentCategory ?? "?"))")
        }

        // Track canonical names used within this selection to prevent variations
        var usedCanonicalNamesInSelection = Set<String>()

        // BUSINESS RULE: If complexity-4 required first, select one first
        if requireComplexity4First && allowComplexity4 {
            let complexity4Candidates = scoredPool.filter {
                $0.exercise.complexityLevel == 4 && $0.isCompound
            }

            if let selected = weightedRandomSelect(from: complexity4Candidates) {
                selectedExercises.append(selected)
                usedCanonicalNamesInSelection.insert(selected.exercise.canonicalName)
                // Remove all exercises with same canonical name (no bench press variations in same session)
                scoredPool.removeAll { $0.exercise.canonicalName == selected.exercise.canonicalName }
                print("   ✅ Selected complexity-4 first: \(selected.exercise.displayName) (score: \(selected.score))")
            }
        }

        // Select remaining exercises with weighted random selection
        while selectedExercises.count < count && !scoredPool.isEmpty {
            // Apply complexity cap if we already have a complexity-4
            let hasComplexity4 = selectedExercises.contains { $0.exercise.complexityLevel == 4 }
            let candidates: [ScoredExercise]

            if hasComplexity4 {
                // Only allow up to complexity 3 for remaining (unless isolation)
                candidates = scoredPool.filter {
                    $0.exercise.complexityLevel <= 3 || $0.exercise.isIsolation
                }
            } else {
                candidates = scoredPool
            }

            guard let selected = weightedRandomSelect(from: candidates.isEmpty ? scoredPool : candidates) else {
                break
            }

            selectedExercises.append(selected)
            usedCanonicalNamesInSelection.insert(selected.exercise.canonicalName)
            // Remove all exercises with same canonical name (no bench press variations in same session)
            scoredPool.removeAll { $0.exercise.canonicalName == selected.exercise.canonicalName }

            print("   ✅ Selected: \(selected.exercise.displayName) (score: \(selected.score), compound: \(selected.isCompound))")
        }

        return selectedExercises
    }

    /// Calculate score for an exercise based on business rules
    private func calculateScore(for exercise: DBExercise, experienceLevel: ExperienceLevel) -> Int {
        if exercise.isIsolation {
            // Isolation scoring based on experience level
            switch experienceLevel {
            case .advanced:
                return 10
            case .intermediate:
                return 6
            case .beginner, .noExperience:
                return 5  // Equal to complexity-1 compounds for beginners
            }
        } else {
            // Compound scoring based on complexity - heavily favor high complexity
            switch exercise.complexityLevel {
            case 4:
                return 100
            case 3:
                return 50
            case 2:
                return 20
            default:
                return 5
            }
        }
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

    /// Select exercises with detailed warnings for UI display
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
        let (pool, maxComplexity, poolWarnings) = try buildUserPool(
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

        // Get complexity rules for complexity-4 handling
        let complexityRules = experienceLevel.complexityRules

        // Stage 2: Score and Select
        let shouldAllowComplexity4 = allowComplexity4 && complexityRules.maxComplexity4PerSession > 0
        let shouldRequireComplexity4First = requireComplexity4First && complexityRules.complexity4MustBeFirst

        let scoredExercises = scoreAndSelectExercises(
            from: pool,
            count: count,
            experienceLevel: experienceLevel,
            excludedExerciseIds: excludedExerciseIds,
            excludedDisplayNames: excludedDisplayNames,
            excludedCanonicalNames: excludedCanonicalNames,
            allowComplexity4: shouldAllowComplexity4,
            requireComplexity4First: shouldRequireComplexity4First,
            maxComplexity: maxComplexity
        )

        // Check for insufficient exercises
        if scoredExercises.count < count, let muscle = primaryMuscle {
            allWarnings.append(.insufficientExercises(
                muscle: muscle,
                requested: count,
                found: scoredExercises.count
            ))
        }

        // Stage 3: Sort for Display
        let sortedExercises = sortForDisplay(scoredExercises)

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
