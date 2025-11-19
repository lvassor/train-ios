//
//  ExerciseRepository.swift
//  trAInSwift
//
//  High-level service for exercise selection with business rules
//

import Foundation

class ExerciseRepository {
    private let dbManager = ExerciseDatabaseManager.shared

    init() {
        print("🔧 ExerciseRepository init() called")
        print("🔧 Using ExerciseDatabaseManager.shared")
    }

    // MARK: - Exercise Selection for Program Generation

    /// Select exercises for a workout session with intelligent variety and business rules
    func selectExercises(
        count: Int,
        movementPattern: String? = nil,
        primaryMuscle: String? = nil,
        experienceLevel: ExperienceLevel,
        availableEquipment: [String],
        userInjuries: [String],
        excludedExerciseIds: Set<Int>,
        allowComplexity4: Bool = false,
        requireComplexity4First: Bool = false
    ) throws -> [DBExercise] {

        // Get experience complexity rules
        guard let complexityRules = try dbManager.fetchExperienceComplexity(for: experienceLevel) else {
            throw RepositoryError.experienceLevelNotFound
        }

        var selectedExercises: [DBExercise] = []
        var usedExerciseIds = excludedExerciseIds

        // BUSINESS RULE: If complexity-4 allowed and must be first, select one first
        if allowComplexity4 && requireComplexity4First && complexityRules.maxComplexity4PerSession > 0 {
            let complexity4Filter = ExerciseDatabaseFilter(
                movementPattern: movementPattern,
                equipmentTypes: availableEquipment,
                maxComplexity: 4,
                primaryMuscle: primaryMuscle,
                excludeInjuries: userInjuries,
                excludeExerciseIds: usedExerciseIds
            )

            // Find complexity-4 exercises only
            var complexity4Exercises = try dbManager.fetchExercises(filter: complexity4Filter)
                .filter { $0.complexityLevel == 4 }

            // FALLBACK: If no complexity-4 exercises found with injuries, try without injury filter
            if complexity4Exercises.isEmpty && !userInjuries.isEmpty {
                print("⚠️ No complexity-4 exercises found for \(primaryMuscle ?? "unknown") with injury filters")
                print("   Retrying without injury contraindications as fallback...")

                let fallbackFilter = ExerciseDatabaseFilter(
                    movementPattern: movementPattern,
                    equipmentTypes: availableEquipment,
                    maxComplexity: 4,
                    primaryMuscle: primaryMuscle,
                    excludeInjuries: [], // Remove injury filter
                    excludeExerciseIds: usedExerciseIds
                )

                complexity4Exercises = try dbManager.fetchExercises(filter: fallbackFilter)
                    .filter { $0.complexityLevel == 4 }
                print("   ✅ Fallback found \(complexity4Exercises.count) complexity-4 exercises")
            }

            if let firstExercise = complexity4Exercises.first {
                selectedExercises.append(firstExercise)
                usedExerciseIds.insert(firstExercise.exerciseId)
            }
        }

        // Select remaining exercises
        let remainingCount = count - selectedExercises.count
        if remainingCount > 0 {
            // BUSINESS RULE: Don't allow more complexity-4 exercises
            let maxComplexityForRemaining = selectedExercises.contains(where: { $0.complexityLevel == 4 }) ?
                3 : complexityRules.maxComplexity

            let filter = ExerciseDatabaseFilter(
                movementPattern: movementPattern,
                equipmentTypes: availableEquipment,
                maxComplexity: maxComplexityForRemaining,
                primaryMuscle: primaryMuscle,
                excludeInjuries: userInjuries,
                excludeExerciseIds: usedExerciseIds
            )

            var candidates = try dbManager.fetchExercises(filter: filter)

            // FALLBACK: If no exercises found and injuries were specified, retry without injury filter
            if candidates.isEmpty && !userInjuries.isEmpty {
                print("⚠️ No exercises found for \(primaryMuscle ?? "unknown") with injury filters")
                print("   Retrying without injury contraindications as fallback...")

                let fallbackFilter = ExerciseDatabaseFilter(
                    movementPattern: movementPattern,
                    equipmentTypes: availableEquipment,
                    maxComplexity: maxComplexityForRemaining,
                    primaryMuscle: primaryMuscle,
                    excludeInjuries: [], // Remove injury filter
                    excludeExerciseIds: usedExerciseIds
                )

                candidates = try dbManager.fetchExercises(filter: fallbackFilter)
                print("   ✅ Fallback found \(candidates.count) exercises (use with caution)")
            }

            let additionalExercises = selectDiverseExercises(
                from: candidates,
                count: remainingCount,
                avoidingIds: usedExerciseIds
            )

            selectedExercises.append(contentsOf: additionalExercises)
        }

        return selectedExercises
    }

    /// Select exercises ensuring variety (prefer different canonical names)
    private func selectDiverseExercises(
        from candidates: [DBExercise],
        count: Int,
        avoidingIds: Set<Int>
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

    /// Find alternative exercises for a given exercise (same movement pattern)
    func findAlternatives(
        for exercise: DBExercise,
        experienceLevel: ExperienceLevel,
        availableEquipment: [String],
        userInjuries: [String],
        excludedExerciseIds: Set<Int>
    ) throws -> [DBExercise] {

        guard let complexityRules = try dbManager.fetchExperienceComplexity(for: experienceLevel) else {
            throw RepositoryError.experienceLevelNotFound
        }

        var excludedIds = excludedExerciseIds
        excludedIds.insert(exercise.exerciseId)

        let filter = ExerciseDatabaseFilter(
            movementPattern: exercise.movementPattern,
            equipmentTypes: availableEquipment,
            maxComplexity: complexityRules.maxComplexity,
            primaryMuscle: exercise.primaryMuscle,
            excludeInjuries: userInjuries,
            excludeExerciseIds: excludedIds
        )

        return try dbManager.fetchAlternatives(for: exercise, filter: filter)
    }

    // MARK: - Utility Methods

    /// Get experience complexity rules
    func getComplexityRules(for experienceLevel: ExperienceLevel) throws -> DBUserExperienceComplexity {
        guard let rules = try dbManager.fetchExperienceComplexity(for: experienceLevel) else {
            throw RepositoryError.experienceLevelNotFound
        }
        return rules
    }

    /// Check if an exercise is contraindicated for given injuries
    func isExerciseContraindicated(exerciseId: Int, for injuries: [String]) throws -> Bool {
        let contraindications = try dbManager.fetchContraindications(forExerciseId: exerciseId)
        return contraindications.contains(where: { injuries.contains($0) })
    }

    /// Get all available movement patterns
    func getAvailableMovementPatterns() throws -> [String] {
        return try dbManager.fetchAvailableMovementPatterns()
    }

    /// Get all available muscles
    func getAvailableMuscles() throws -> [String] {
        return try dbManager.fetchAvailableMuscles()
    }

    /// Fetch exercise by ID
    func getExercise(byId id: Int) throws -> DBExercise? {
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
