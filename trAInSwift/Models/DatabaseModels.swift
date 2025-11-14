//
//  DatabaseModels.swift
//  trAInSwift
//
//  Models matching the SQLite database schema for exercises.db
//

import Foundation
import GRDB

// MARK: - Database Exercise Model

struct DBExercise: Codable, FetchableRecord, TableRecord, Identifiable {
    static let databaseTableName = "exercises"

    var id: Int { exerciseId }
    let exerciseId: Int
    let canonicalName: String
    let displayName: String
    let movementPattern: String
    let equipmentType: String
    let complexityLevel: Int
    let primaryMuscle: String
    let secondaryMuscle: String?
    let instructions: String?
    let isActive: Bool

    enum Columns {
        static let exerciseId = Column("exercise_id")
        static let canonicalName = Column("canonical_name")
        static let displayName = Column("display_name")
        static let movementPattern = Column("movement_pattern")
        static let equipmentType = Column("equipment_type")
        static let complexityLevel = Column("complexity_level")
        static let primaryMuscle = Column("primary_muscle")
        static let secondaryMuscle = Column("secondary_muscle")
        static let instructions = Column("instructions")
        static let isActive = Column("is_active")
    }

    private enum CodingKeys: String, CodingKey {
        case exerciseId = "exercise_id"
        case canonicalName = "canonical_name"
        case displayName = "display_name"
        case movementPattern = "movement_pattern"
        case equipmentType = "equipment_type"
        case complexityLevel = "complexity_level"
        case primaryMuscle = "primary_muscle"
        case secondaryMuscle = "secondary_muscle"
        case instructions
        case isActive = "is_active"
    }

    // Convert boolean from SQLite integer
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        exerciseId = try container.decode(Int.self, forKey: .exerciseId)
        canonicalName = try container.decode(String.self, forKey: .canonicalName)
        displayName = try container.decode(String.self, forKey: .displayName)
        movementPattern = try container.decode(String.self, forKey: .movementPattern)
        equipmentType = try container.decode(String.self, forKey: .equipmentType)
        complexityLevel = try container.decode(Int.self, forKey: .complexityLevel)
        primaryMuscle = try container.decode(String.self, forKey: .primaryMuscle)
        secondaryMuscle = try container.decodeIfPresent(String.self, forKey: .secondaryMuscle)
        instructions = try container.decodeIfPresent(String.self, forKey: .instructions)

        // SQLite stores boolean as integer (0 or 1)
        let isActiveInt = try container.decode(Int.self, forKey: .isActive)
        isActive = isActiveInt == 1
    }
}

// MARK: - Exercise Contraindication Model

struct DBExerciseContraindication: Codable, FetchableRecord, TableRecord {
    static let databaseTableName = "exercise_contraindications"

    let id: Int
    let exerciseId: Int
    let injuryType: String

    enum Columns {
        static let id = Column("id")
        static let exerciseId = Column("exercise_id")
        static let injuryType = Column("injury_type")
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case exerciseId = "exercise_id"
        case injuryType = "injury_type"
    }
}

// MARK: - User Experience Complexity Model

struct DBUserExperienceComplexity: Codable, FetchableRecord, TableRecord {
    static let databaseTableName = "user_experience_complexity"

    let experienceLevel: String
    let displayName: String
    let maxComplexity: Int
    let maxComplexity4PerSession: Int
    let complexity4MustBeFirst: Bool

    enum Columns {
        static let experienceLevel = Column("experience_level")
        static let displayName = Column("display_name")
        static let maxComplexity = Column("max_complexity")
        static let maxComplexity4PerSession = Column("max_complexity_4_per_session")
        static let complexity4MustBeFirst = Column("complexity_4_must_be_first")
    }

    private enum CodingKeys: String, CodingKey {
        case experienceLevel = "experience_level"
        case displayName = "display_name"
        case maxComplexity = "max_complexity"
        case maxComplexity4PerSession = "max_complexity_4_per_session"
        case complexity4MustBeFirst = "complexity_4_must_be_first"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        experienceLevel = try container.decode(String.self, forKey: .experienceLevel)
        displayName = try container.decode(String.self, forKey: .displayName)
        maxComplexity = try container.decode(Int.self, forKey: .maxComplexity)
        maxComplexity4PerSession = try container.decode(Int.self, forKey: .maxComplexity4PerSession)

        // SQLite stores boolean as integer (0 or 1)
        let boolInt = try container.decode(Int.self, forKey: .complexity4MustBeFirst)
        complexity4MustBeFirst = boolInt == 1
    }
}

// MARK: - Experience Level Enum

enum ExperienceLevel: String, Codable {
    case beginner = "BEGINNER"
    case intermediate = "INTERMEDIATE"
    case advanced = "ADVANCED"

    var displayName: String {
        switch self {
        case .beginner: return "Beginner (0-6 months)"
        case .intermediate: return "Intermediate (6mo-2yr)"
        case .advanced: return "Advanced (2+ years)"
        }
    }

    // Map from questionnaire format to database format
    static func fromQuestionnaire(_ level: String) -> ExperienceLevel {
        switch level {
        case "0_months", "0_6_months":
            return .beginner
        case "6_months_2_years":
            return .intermediate
        case "2_plus_years":
            return .advanced
        default:
            return .beginner
        }
    }
}

// MARK: - Exercise Query Filter

struct ExerciseDatabaseFilter {
    var movementPattern: String?
    var equipmentTypes: [String] = []
    var maxComplexity: Int = 4
    var primaryMuscle: String?
    var excludeInjuries: [String] = []
    var excludeExerciseIds: Set<Int> = []
    var requireActive: Bool = true

    init(movementPattern: String? = nil,
         equipmentTypes: [String] = [],
         maxComplexity: Int = 4,
         primaryMuscle: String? = nil,
         excludeInjuries: [String] = [],
         excludeExerciseIds: Set<Int> = [],
         requireActive: Bool = true) {
        self.movementPattern = movementPattern
        self.equipmentTypes = equipmentTypes
        self.maxComplexity = maxComplexity
        self.primaryMuscle = primaryMuscle
        self.excludeInjuries = excludeInjuries
        self.excludeExerciseIds = excludeExerciseIds
        self.requireActive = requireActive
    }
}

// MARK: - Equipment Type Mapping

extension ExerciseDatabaseFilter {
    /// Map questionnaire equipment choices to database equipment types
    static func mapEquipmentFromQuestionnaire(_ questionnaireEquipment: [String]) -> [String] {
        var dbEquipment: [String] = []

        for item in questionnaireEquipment {
            switch item {
            case "bodyweight":
                dbEquipment.append("Bodyweight")
            case "dumbbells":
                dbEquipment.append("Dumbbell")
            case "barbells":
                dbEquipment.append("Barbell")
            case "cable_machines":
                dbEquipment.append("Cable")
            case "pin_loaded", "plate_loaded":
                dbEquipment.append("Machine")
            case "kettlebells":
                dbEquipment.append("Kettlebell")
            default:
                break
            }
        }

        // If no equipment selected, allow all types
        if dbEquipment.isEmpty {
            dbEquipment = ["Barbell", "Dumbbell", "Cable", "Machine", "Kettlebell", "Bodyweight"]
        }

        return dbEquipment
    }
}
