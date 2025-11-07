//
//  ExerciseDatabaseService.swift
//  trAInApp
//
//  Service to manage and query the exercise database
//

import Foundation

class ExerciseDatabaseService {
    static let shared = ExerciseDatabaseService()

    private var exercises: [ExerciseDBEntry] = []
    private var exercisesByMuscle: [String: [ExerciseDBEntry]] = [:]
    private var exercisesById: [String: ExerciseDBEntry] = [:]

    private init() {
        loadDatabase()
    }

    func loadDatabase() {
        exercises = CSVParser.parseExerciseDatabase(from: "ExerciseDatabase")

        // Build lookup tables for fast querying
        for exercise in exercises {
            // Index by primary muscle
            if exercisesByMuscle[exercise.primaryMuscle] == nil {
                exercisesByMuscle[exercise.primaryMuscle] = []
            }
            exercisesByMuscle[exercise.primaryMuscle]?.append(exercise)

            // Index by ID
            exercisesById[exercise.id] = exercise
        }

        print("Exercise database initialized with \(exercises.count) exercises")
        print("Muscles available: \(exercisesByMuscle.keys.sorted())")
    }

    func getExercise(byId id: String) -> ExerciseDBEntry? {
        return exercisesById[id]
    }

    func getExercises(filter: ExerciseFilter) -> [ExerciseDBEntry] {
        var filtered = exercises

        // Filter by primary muscle if specified
        if let muscle = filter.primaryMuscle {
            filtered = filtered.filter { $0.primaryMuscle == muscle }
        }

        // Filter by equipment
        if !filter.equipmentTypes.isEmpty {
            filtered = filtered.filter { exercise in
                filter.equipmentTypes.contains(exercise.equipmentType)
            }
        }

        // Filter by experience level
        filtered = filtered.filter { exercise in
            exercise.experienceLevel.rank <= filter.maxExperienceLevel.rank
        }

        // Filter out contraindicated exercises
        if !filter.excludedInjuries.isEmpty {
            filtered = filtered.filter { exercise in
                // Check if any of the user's injuries are in this exercise's contraindications
                let hasContraindication = exercise.contraindicatedInjuries.contains { injury in
                    filter.excludedInjuries.contains(injury)
                }
                return !hasContraindication
            }
        }

        // Filter out already used exercises
        if !filter.excludedExerciseIds.isEmpty {
            filtered = filtered.filter { !filter.excludedExerciseIds.contains($0.id) }
        }

        return filtered
    }

    // Select exercises ensuring variety (prefer different base exercises)
    func selectExercises(count: Int, filter: ExerciseFilter) -> [ExerciseDBEntry] {
        let candidates = getExercises(filter: filter)
        guard !candidates.isEmpty else { return [] }

        var selected: [ExerciseDBEntry] = []
        var usedBaseNames = Set<String>()

        // First pass: select exercises with unique base names
        for exercise in candidates {
            if selected.count >= count { break }

            if !usedBaseNames.contains(exercise.baseExerciseName) {
                selected.append(exercise)
                usedBaseNames.insert(exercise.baseExerciseName)
            }
        }

        // Second pass: fill remaining slots if needed
        if selected.count < count {
            for exercise in candidates {
                if selected.count >= count { break }

                if !selected.contains(where: { $0.id == exercise.id }) {
                    selected.append(exercise)
                }
            }
        }

        return Array(selected.prefix(count))
    }

    // Get all available muscles
    func getAvailableMuscles() -> [String] {
        return Array(exercisesByMuscle.keys).sorted()
    }

    // Get all available equipment types
    func getAvailableEquipment() -> [String] {
        return Array(Set(exercises.map { $0.equipmentType })).sorted()
    }
}
