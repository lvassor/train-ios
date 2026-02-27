//
//  DatabaseModels.swift
//  TrainSwift
//
//  Models matching the SQLite database schema for exercises.db
//  Schema uses normalized equipment references: equipment_id_1/equipment_id_2 → equipment table
//

import Foundation
import GRDB

// MARK: - Equipment Model

struct DBEquipment: Codable, FetchableRecord, TableRecord, Identifiable, Hashable {
    static let databaseTableName = "equipment"

    var id: String { equipmentId }
    let equipmentId: String     // e.g., "EP001"
    let category: String        // "Barbells", "Dumbbells", "Cables", etc.
    let name: String            // "Barbells", "Squat Rack", "Single Adjustable Cable Machine", etc.
    let imageFilename: String?

    private enum CodingKeys: String, CodingKey {
        case equipmentId = "equipment_id"
        case category
        case name
        case imageFilename = "image_filename"
    }
}

// MARK: - Database Exercise Model

struct DBExercise: Codable, FetchableRecord, TableRecord, Identifiable, Hashable {
    static let databaseTableName = "exercises"

    var id: String { exerciseId }
    let exerciseId: String              // e.g., "EX001"
    let canonicalName: String           // Movement pattern grouping for swaps
    let displayName: String             // User-facing name
    let equipmentId1: String            // FK → equipment table (primary equipment)
    let equipmentId2: String?           // FK → equipment table (secondary/attachment, optional)
    let complexityLevel: String         // "All", "1", "2"
    let primaryMuscle: String
    let secondaryMuscle: String?
    let instructions: String?
    let isInProgramme: Bool             // Whether to include in generated programmes
    let canonicalRating: Int            // 0-100 score for MCV heuristic ordering
    let progressionId: String?          // Comma-separated exercise_ids for progressions
    let regressionId: String?           // Comma-separated exercise_ids for regressions

    enum Columns {
        static let exerciseId = Column("exercise_id")
        static let canonicalName = Column("canonical_name")
        static let displayName = Column("display_name")
        static let equipmentId1 = Column("equipment_id_1")
        static let equipmentId2 = Column("equipment_id_2")
        static let complexityLevel = Column("complexity_level")
        static let primaryMuscle = Column("primary_muscle")
        static let secondaryMuscle = Column("secondary_muscle")
        static let instructions = Column("instructions")
        static let isInProgramme = Column("is_in_programme")
        static let canonicalRating = Column("canonical_rating")
        static let progressionId = Column("progression_id")
        static let regressionId = Column("regression_id")
    }

    private enum CodingKeys: String, CodingKey {
        case exerciseId = "exercise_id"
        case canonicalName = "canonical_name"
        case displayName = "display_name"
        case equipmentId1 = "equipment_id_1"
        case equipmentId2 = "equipment_id_2"
        case complexityLevel = "complexity_level"
        case primaryMuscle = "primary_muscle"
        case secondaryMuscle = "secondary_muscle"
        case instructions
        case isInProgramme = "is_in_programme"
        case canonicalRating = "canonical_rating"
        case progressionId = "progression_id"
        case regressionId = "regression_id"
    }

    // Convert boolean from SQLite integer
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        exerciseId = try container.decode(String.self, forKey: .exerciseId)
        canonicalName = try container.decode(String.self, forKey: .canonicalName)
        displayName = try container.decode(String.self, forKey: .displayName)
        equipmentId1 = try container.decode(String.self, forKey: .equipmentId1)
        equipmentId2 = try container.decodeIfPresent(String.self, forKey: .equipmentId2)
        complexityLevel = try container.decode(String.self, forKey: .complexityLevel)
        primaryMuscle = try container.decode(String.self, forKey: .primaryMuscle)
        secondaryMuscle = try container.decodeIfPresent(String.self, forKey: .secondaryMuscle)
        instructions = try container.decodeIfPresent(String.self, forKey: .instructions)
        canonicalRating = try container.decode(Int.self, forKey: .canonicalRating)
        progressionId = try container.decodeIfPresent(String.self, forKey: .progressionId)
        regressionId = try container.decodeIfPresent(String.self, forKey: .regressionId)

        // SQLite stores boolean as integer (0 or 1)
        let isInProgrammeInt = try container.decode(Int.self, forKey: .isInProgramme)
        isInProgramme = isInProgrammeInt == 1
    }

    /// Get numeric complexity level for filtering (convert string to int)
    /// DB stores "All" (capital A), "1", "2"
    var numericComplexity: Int {
        switch complexityLevel.lowercased() {
        case "all": return 0
        case "1": return 1
        case "2": return 2
        default: return 0
        }
    }

    // MARK: - Equipment Lookups (from cache)

    /// Primary equipment record
    var equipment1: DBEquipment? {
        ExerciseDatabaseManager.shared.equipment(for: equipmentId1)
    }

    /// Secondary equipment record (if any)
    var equipment2: DBEquipment? {
        guard let id2 = equipmentId2 else { return nil }
        return ExerciseDatabaseManager.shared.equipment(for: id2)
    }

    /// Equipment category (e.g., "Barbells", "Dumbbells") — resolved from equipment_id_1
    var equipmentCategory: String {
        equipment1?.category ?? "Unknown"
    }

    /// Specific equipment name (e.g., "Squat Rack", "Single Adjustable Cable Machine")
    var equipmentSpecific: String? {
        equipment1?.name
    }

    /// Secondary/attachment name (e.g., "Straight Bar", "Roman Chair")
    var attachmentSpecific: String? {
        equipment2?.name
    }

    /// For backward compatibility — returns equipment category
    var equipmentName: String? {
        return equipmentCategory
    }

    /// For backward compatibility — returns equipment category
    var equipmentType: String {
        return equipmentCategory
    }

    /// Get formatted instructions as array of steps
    var instructionSteps: [String] {
        guard let instructions = instructions else { return [] }
        return instructions.components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }
}

// MARK: - Exercise Contraindication Model

struct DBExerciseContraindication: Codable, FetchableRecord, TableRecord {
    static let databaseTableName = "exercise_contraindications"

    let id: Int
    let canonicalName: String    // Changed from exerciseId to canonicalName
    let injuryType: String

    enum Columns {
        static let id = Column("id")
        static let canonicalName = Column("canonical_name")
        static let injuryType = Column("injury_type")
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case canonicalName = "canonical_name"
        case injuryType = "injury_type"
    }
}

// MARK: - Exercise Video Model

struct DBExerciseVideo: Codable, FetchableRecord, TableRecord, Identifiable {
    static let databaseTableName = "exercise_videos"

    let id: Int
    let exerciseId: String
    let supplierId: String?
    let filename: String
    let bunnyGuid: String

    private enum CodingKeys: String, CodingKey {
        case id
        case exerciseId = "exercise_id"
        case supplierId = "supplier_id"
        case filename
        case bunnyGuid = "bunny_guid"
    }
}

// MARK: - Experience Complexity Rules (Hardcoded)

/// Complexity rules for exercise selection based on experience level.
/// These rules determine which exercises are eligible for a user's programme.
struct ExperienceComplexityRules {
    let maxComplexity: Int
    let maxComplexity4PerSession: Int
    let complexity4MustBeFirst: Bool
}

// MARK: - Experience Level Enum

enum ExperienceLevel: String, Codable, CaseIterable {
    case noExperience = "NO_EXPERIENCE"
    case beginner = "BEGINNER"
    case intermediate = "INTERMEDIATE"
    case advanced = "ADVANCED"

    var displayName: String {
        switch self {
        case .noExperience: return "Just Starting Out"
        case .beginner: return "Finding My Feet"
        case .intermediate: return "Getting Comfortable"
        case .advanced: return "Confident & Consistent"
        }
    }

    var subtitle: String {
        switch self {
        case .noExperience:
            return "New to the gym or never tried strength training? Perfect — we'll guide you through the fundamentals with exercises that build confidence."
        case .beginner:
            return "You've tried a few things but still figuring it out? We'll give you a solid foundation with straightforward movements."
        case .intermediate:
            return "You know your way around the gym and feel fairly confident with the basics. We'll build on that with some variety."
        case .advanced:
            return "You train regularly and feel confident with most exercises. We'll challenge you with the full range of movements."
        }
    }

    // Map from questionnaire format to database format
    static func fromQuestionnaire(_ level: String) -> ExperienceLevel {
        switch level {
        // Current UI values
        case "no_experience":
            return .noExperience
        case "beginner":
            return .beginner
        case "intermediate":
            return .intermediate
        case "advanced":
            return .advanced
        // Legacy values (for backward compatibility)
        case "0_months":
            return .noExperience
        case "0_6_months":
            return .beginner
        case "6_months_2_years":
            return .intermediate
        case "2_plus_years":
            return .advanced
        default:
            return .noExperience
        }
    }

    // Map to questionnaire format (for backward compatibility)
    var questionnaireValue: String {
        switch self {
        case .noExperience: return "0_months"
        case .beginner: return "0_6_months"
        case .intermediate: return "6_months_2_years"
        case .advanced: return "2_plus_years"
        }
    }

    /// Complexity rules for exercise selection.
    /// - noExperience: Only "all" and "1" exercises (simplest movements)
    /// - beginner: Only "all" and "1" exercises (simplest movements)
    /// - intermediate: Up to "2" exercises (all levels including intermediate)
    /// - advanced: Up to "2" exercises (all levels including intermediate)
    var complexityRules: ExperienceComplexityRules {
        switch self {
        case .noExperience:
            return ExperienceComplexityRules(maxComplexity: 1, maxComplexity4PerSession: 0, complexity4MustBeFirst: false)
        case .beginner:
            return ExperienceComplexityRules(maxComplexity: 1, maxComplexity4PerSession: 0, complexity4MustBeFirst: false)
        case .intermediate:
            return ExperienceComplexityRules(maxComplexity: 2, maxComplexity4PerSession: 0, complexity4MustBeFirst: false)
        case .advanced:
            return ExperienceComplexityRules(maxComplexity: 2, maxComplexity4PerSession: 0, complexity4MustBeFirst: false)
        }
    }
}

// MARK: - Exercise Query Filter

struct ExerciseDatabaseFilter {
    var canonicalName: String?              // Filter by movement pattern (for exercise swaps)
    var equipmentCategories: [String] = []  // Equipment category names (e.g., "Barbells", "Cables")
    var equipmentSpecific: [String] = []    // Specific equipment names (e.g., "Squat Rack")
    var attachmentSpecific: [String] = []   // Attachment names (e.g., "Rope", "Straight Bar")
    var allowedEquipmentIds: Set<String>? = nil  // Pre-resolved equipment IDs (overrides above if set)
    var maxComplexity: Int = 4              // Maximum complexity level (1-4)
    var primaryMuscle: String?
    var excludeInjuries: [String] = []
    var excludeExerciseIds: Set<String> = []
    var onlyProgrammeExercises: Bool = true // Only include exercises with is_in_programme = 1

    init(canonicalName: String? = nil,
         equipmentCategories: [String] = [],
         equipmentSpecific: [String] = [],
         attachmentSpecific: [String] = [],
         allowedEquipmentIds: Set<String>? = nil,
         maxComplexity: Int = 4,
         primaryMuscle: String? = nil,
         excludeInjuries: [String] = [],
         excludeExerciseIds: Set<String> = [],
         onlyProgrammeExercises: Bool = true) {
        self.canonicalName = canonicalName
        self.equipmentCategories = equipmentCategories
        self.equipmentSpecific = equipmentSpecific
        self.attachmentSpecific = attachmentSpecific
        self.allowedEquipmentIds = allowedEquipmentIds
        self.maxComplexity = maxComplexity
        self.primaryMuscle = primaryMuscle
        self.excludeInjuries = excludeInjuries
        self.excludeExerciseIds = excludeExerciseIds
        self.onlyProgrammeExercises = onlyProgrammeExercises
    }

    // Legacy properties for backward compatibility
    var equipmentNames: [String] {
        get { equipmentCategories }
        set { equipmentCategories = newValue }
    }

    var equipmentTypes: [String] {
        get { equipmentCategories }
        set { equipmentCategories = newValue }
    }
}

// MARK: - Equipment Type Mapping

extension ExerciseDatabaseFilter {
    /// Map questionnaire equipment choices to database equipment categories
    static func mapEquipmentFromQuestionnaire(_ questionnaireEquipment: [String]) -> [String] {
        return ConstantsManager.shared.mapEquipment(questionnaireEquipment)
    }

    /// Map questionnaire attachment choices to database attachment values
    static func mapAttachmentsFromQuestionnaire(_ questionnaireAttachments: Set<String>) -> [String] {
        return ConstantsManager.shared.mapAttachments(questionnaireAttachments)
    }

    /// Map questionnaire machine choices to database equipment types (legacy)
    static func mapMachineTypesFromQuestionnaire(_ questionnaireEquipment: [String]) -> [String] {
        return []
    }
}

// MARK: - Injury Type (for questionnaire)
// These now map to muscle groups (primary_muscle values in exercises table)

enum InjuryType: String, CaseIterable, Codable {
    case back = "Back"
    case biceps = "Biceps"
    case calves = "Calves"
    case chest = "Chest"
    case core = "Core"
    case glutes = "Glutes"
    case hamstrings = "Hamstrings"
    case quads = "Quads"
    case shoulders = "Shoulders"
    case triceps = "Triceps"

    var displayName: String { rawValue }
}

// MARK: - Equipment Hierarchy (for expandable questionnaire)

struct EquipmentHierarchy {
    /// Equipment categories that have expandable specific items.
    /// Maps questionnaire key → list of specific equipment names (matching equipment.name in DB).
    static let expandableCategories: [String: [String]] = [
        "bodyweight": [
            "Flat Bench",
            "Pull-Up Bar",
            "Dip Station",
            "Roman Chair",
            "Ab Wheel"
        ],
        "barbells": [
            "Squat Rack",
            "Flat Bench Press",
            "Incline Bench Press",
            "Decline Bench Press",
            "Landmine Attachment",
            "Hip Thrust Bench",
            "Preacher Bench",
            "Smith Machine"
        ],
        "dumbbells": [
            "Adjustable Bench"
        ],
        "cable_machines": [
            "Single Adjustable Cable Machine",
            "Dual Cable Machine",
            "Lat Pull Down Machine",
            "Cable Row Machine"
        ],
        "pin_loaded": [
            "Leg Press Machine",
            "Leg Extension Machine",
            "Lying Leg Curl Machine",
            "Seated Leg Curl Machine",
            "Standing Calf Raise Machine",
            "Seated Calf Raise Machine",
            "Hip Abduction Machine",
            "Hip Adduction Machine",
            "Assisted Pull-Up/Dip Machine",
            "Machine Chest Press",
            "Pec Deck",
            "Shoulder Press Machine",
            "Chest Supported Row Machine",
            "Preacher Curl Machine"
        ],
        "plate_loaded": [
            "Leg Press Machine",
            "Hack Squat Machine",
            "Leg Extension Machine",
            "Lying Leg Curl Machine",
            "Seated Leg Curl Machine",
            "Standing Calf Raise Machine",
            "Seated Calf Raise Machine",
            "Glute Kickback Machine",
            "Machine Chest Press",
            "Shoulder Press Machine",
            "Chest Supported Row Machine",
            "Hip Thrust Machine"
        ]
    ]

    /// Categories that don't expand (no specific equipment sub-items)
    static let simpleCategories = ["kettlebells"]
}
