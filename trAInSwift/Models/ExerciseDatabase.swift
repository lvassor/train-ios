//
//  ExerciseDatabase.swift
//  trAInApp
//
//  Exercise database model matching the CSV structure
//

import Foundation

struct ExerciseDBEntry: Codable, Identifiable {
    let id: String // Exercise_ID from CSV
    let exerciseName: String
    let baseExerciseName: String
    let primaryMuscle: String
    let secondaryMuscles: [String]
    let movementPattern: String
    let equipmentType: String
    let experienceLevel: ExperienceLevel
    let progressionLevel: Int
    let contraindicatedInjuries: [String]
    let alternativeExerciseIds: [String]
    let addedByClaude: Bool

    enum ExperienceLevel: String, Codable {
        case beginner = "Beginner"
        case intermediate = "Intermediate"
        case advanced = "Advanced"

        var rank: Int {
            switch self {
            case .beginner: return 1
            case .intermediate: return 2
            case .advanced: return 3
            }
        }
    }

    // Initialize from CSV row
    init(csvRow: [String: String]) {
        self.id = csvRow["Exercise_ID"] ?? ""
        self.exerciseName = csvRow["Exercise_Name"] ?? ""
        self.baseExerciseName = csvRow["Base_Exercise_Name"] ?? ""
        self.primaryMuscle = csvRow["Primary_Muscle"] ?? ""

        let secondaryString = csvRow["Secondary_Muscles"] ?? ""
        self.secondaryMuscles = secondaryString.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }

        self.movementPattern = csvRow["Movement_Pattern"] ?? ""
        self.equipmentType = csvRow["Equipment_Type"] ?? ""

        let expLevel = csvRow["Experience_Level"] ?? "Beginner"
        self.experienceLevel = ExperienceLevel(rawValue: expLevel) ?? .beginner

        self.progressionLevel = Int(csvRow["Progression_Level"] ?? "1") ?? 1

        let injuriesString = csvRow["Contraindicated_Injuries"] ?? ""
        self.contraindicatedInjuries = injuriesString.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }

        let altString = csvRow["Alternative_Exercise_IDs"] ?? ""
        self.alternativeExerciseIds = altString.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }

        self.addedByClaude = csvRow["Added_By_Claude"]?.lowercased() == "yes"
    }

    // Manual init
    init(id: String,
         exerciseName: String,
         baseExerciseName: String,
         primaryMuscle: String,
         secondaryMuscles: [String],
         movementPattern: String,
         equipmentType: String,
         experienceLevel: ExperienceLevel,
         progressionLevel: Int,
         contraindicatedInjuries: [String],
         alternativeExerciseIds: [String],
         addedByClaude: Bool) {
        self.id = id
        self.exerciseName = exerciseName
        self.baseExerciseName = baseExerciseName
        self.primaryMuscle = primaryMuscle
        self.secondaryMuscles = secondaryMuscles
        self.movementPattern = movementPattern
        self.equipmentType = equipmentType
        self.experienceLevel = experienceLevel
        self.progressionLevel = progressionLevel
        self.contraindicatedInjuries = contraindicatedInjuries
        self.alternativeExerciseIds = alternativeExerciseIds
        self.addedByClaude = addedByClaude
    }
}

// Exercise filtering criteria
struct ExerciseFilter {
    var primaryMuscle: String?
    var equipmentTypes: [String]
    var maxExperienceLevel: ExerciseDBEntry.ExperienceLevel
    var excludedInjuries: [String]
    var excludedExerciseIds: Set<String> // For variety

    init(primaryMuscle: String? = nil,
         equipmentTypes: [String] = [],
         maxExperienceLevel: ExerciseDBEntry.ExperienceLevel = .advanced,
         excludedInjuries: [String] = [],
         excludedExerciseIds: Set<String> = []) {
        self.primaryMuscle = primaryMuscle
        self.equipmentTypes = equipmentTypes
        self.maxExperienceLevel = maxExperienceLevel
        self.excludedInjuries = excludedInjuries
        self.excludedExerciseIds = excludedExerciseIds
    }
}
