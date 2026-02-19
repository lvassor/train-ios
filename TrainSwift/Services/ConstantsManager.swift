import Foundation

/// Singleton service that loads and provides access to constants.json
/// Ensures single source of truth between Python generator and Swift app
class ConstantsManager {
    static let shared = ConstantsManager()

    // MARK: - Equipment Mappings
    /// Maps questionnaire keys to database values (e.g., "cable_machines" -> "Cables")
    private(set) var equipmentMappings: [String: String] = [:]
    /// List of valid equipment categories in database
    private(set) var equipmentCategories: [String] = []

    // MARK: - Attachment Mappings
    /// Maps questionnaire keys to database values (e.g., "straight_bar" -> "Straight Bar")
    private(set) var attachmentMappings: [String: String] = [:]
    /// List of valid attachment categories in database
    private(set) var attachmentCategories: [String] = []
    /// Attachments specific to cable machines (for warning validation)
    private(set) var cableAttachments: [String] = []

    // MARK: - Experience Level Mappings
    /// Maps questionnaire keys to database values
    private(set) var experienceLevelMappings: [String: String] = [:]

    // MARK: - Injury Types
    /// List of valid injury types for contraindications
    private(set) var injuryTypes: [String] = []

    // MARK: - Gym Type Presets
    /// Preset equipment configurations for different gym types
    private(set) var gymTypePresets: [String: GymPreset] = [:]

    /// Represents a gym type preset configuration
    struct GymPreset {
        let description: String
        let equipmentCategories: [String]
        let equipmentSpecific: [String: [String]]
        let attachments: [String]
    }

    // MARK: - Initialization
    private init() {
        load()
    }

    // MARK: - Loading
    private func load() {
        guard let path = Bundle.main.path(forResource: "constants", ofType: "json") else {
            print("⚠️ ConstantsManager: constants.json not found in bundle, using defaults")
            loadDefaults()
            return
        }

        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]

            // Equipment
            equipmentMappings = json["equipment_mappings"] as? [String: String] ?? [:]
            equipmentCategories = json["equipment_categories"] as? [String] ?? []

            // Attachments
            attachmentMappings = json["attachment_mappings"] as? [String: String] ?? [:]
            attachmentCategories = json["attachment_categories"] as? [String] ?? []
            cableAttachments = json["cable_attachments"] as? [String] ?? []

            // Experience levels
            experienceLevelMappings = json["experience_level_mappings"] as? [String: String] ?? [:]

            // Injuries
            injuryTypes = json["injury_types"] as? [String] ?? []

            // Gym type presets
            if let presets = json["gym_type_presets"] as? [String: [String: Any]] {
                for (gymType, presetData) in presets {
                    let description = presetData["description"] as? String ?? ""
                    let categories = presetData["equipment_categories"] as? [String] ?? []
                    let specific = presetData["equipment_specific"] as? [String: [String]] ?? [:]
                    let attachments = presetData["attachments"] as? [String] ?? []

                    gymTypePresets[gymType] = GymPreset(
                        description: description,
                        equipmentCategories: categories,
                        equipmentSpecific: specific,
                        attachments: attachments
                    )
                }
            }

            print("✅ ConstantsManager: Loaded constants from JSON")
            print("   - Equipment mappings: \(equipmentMappings.count)")
            print("   - Attachment mappings: \(attachmentMappings.count)")
            print("   - Cable attachments: \(cableAttachments.count)")
            print("   - Gym type presets: \(gymTypePresets.count)")

        } catch {
            print("❌ ConstantsManager: Failed to load constants.json: \(error)")
            loadDefaults()
        }
    }

    /// Fallback defaults if JSON loading fails
    private func loadDefaults() {
        equipmentMappings = [
            "bodyweight": "Bodyweight",
            "barbells": "Barbells",
            "dumbbells": "Dumbbells",
            "kettlebells": "Kettlebells",
            "cable_machines": "Cables",
            "pin_loaded": "Pin-Loaded Machines",
            "plate_loaded": "Plate-Loaded Machines",
            "other": "Other"
        ]

        equipmentCategories = [
            "Bodyweight", "Barbells", "Dumbbells", "Kettlebells",
            "Cables", "Pin-Loaded Machines", "Plate-Loaded Machines", "Other"
        ]

        attachmentMappings = [
            "straight_bar": "Straight Bar",
            "rope": "Rope",
            "d_handles": "D-Handles",
            "ez_bar": "EZ-Bar",
            "ez_bar_cable": "EZ-Bar Cable",
            "ankle_strap": "Ankle Strap",
            "resistance_band": "Resistance Band",
            "weight_belt": "Weight Belt"
        ]

        attachmentCategories = [
            "Straight Bar", "Rope", "D-Handles", "EZ-Bar",
            "EZ-Bar Cable", "Ankle Strap", "Resistance Band", "Weight Belt"
        ]

        cableAttachments = ["Straight Bar", "Rope", "D-Handles", "EZ-Bar Cable"]

        experienceLevelMappings = [
            "no_experience": "NO_EXPERIENCE",
            "beginner": "BEGINNER",
            "intermediate": "INTERMEDIATE",
            "advanced": "ADVANCED",
            "0_months": "NO_EXPERIENCE",
            "0_6_months": "BEGINNER",
            "6_months_2_years": "INTERMEDIATE",
            "2_plus_years": "ADVANCED"
        ]

        injuryTypes = [
            "Back", "Biceps", "Calves", "Chest", "Core", "Forearms",
            "Glutes", "Hamstrings", "Quads", "Shoulders", "Traps", "Triceps"
        ]

        print("⚠️ ConstantsManager: Using hardcoded defaults")
    }

    // MARK: - Mapping Functions

    /// Map questionnaire equipment keys to database values
    /// - Parameter questionnaireKeys: Array of keys like ["barbells", "cable_machines"]
    /// - Returns: Array of database values like ["Barbells", "Cables"]
    func mapEquipment(_ questionnaireKeys: [String]) -> [String] {
        var dbValues: [String] = []

        for key in questionnaireKeys {
            if let dbValue = equipmentMappings[key] {
                dbValues.append(dbValue)
            }
        }

        // If nothing mapped, return all categories as fallback
        if dbValues.isEmpty {
            return equipmentCategories
        }

        return dbValues
    }

    /// Map questionnaire attachment keys to database values
    /// - Parameter questionnaireKeys: Set of keys like ["straight_bar", "rope"]
    /// - Returns: Array of database values like ["Straight Bar", "Rope"]
    func mapAttachments(_ questionnaireKeys: Set<String>) -> [String] {
        var dbValues: [String] = []

        for key in questionnaireKeys {
            if let dbValue = attachmentMappings[key] {
                dbValues.append(dbValue)
            } else if attachmentCategories.contains(key) {
                // Key is already a database value (display name selected directly)
                dbValues.append(key)
            }
        }

        return dbValues
    }

    /// Map questionnaire experience level key to database value
    /// - Parameter questionnaireKey: Key like "intermediate" or "6_months_2_years"
    /// - Returns: Database value like "INTERMEDIATE", or nil if not found
    func mapExperienceLevel(_ questionnaireKey: String) -> String? {
        return experienceLevelMappings[questionnaireKey]
    }

    // MARK: - Validation

    /// Check if user has cable machines but no cable attachments selected
    /// - Parameters:
    ///   - equipment: User's selected equipment keys
    ///   - attachments: User's selected attachment database values
    /// - Returns: True if warning should be shown
    func shouldShowCableAttachmentWarning(equipment: [String], attachments: [String]) -> Bool {
        let hasCables = equipment.contains("cable_machines")
        if !hasCables { return false }

        let hasAnyCableAttachment = attachments.contains { cableAttachments.contains($0) }
        return !hasAnyCableAttachment
    }

    // MARK: - Gym Type Preset Functions

    /// Get equipment configuration for a specific gym type
    /// - Parameter gymType: The gym type key (e.g., "large_gym", "small_gym", "garage_gym")
    /// - Returns: Tuple of (equipment categories, detailed equipment, attachments) or nil if not found
    func getEquipmentForGymType(_ gymType: String) -> (categories: [String], specific: [String: Set<String>], attachments: Set<String>)? {
        guard let preset = gymTypePresets[gymType] else {
            print("⚠️ ConstantsManager: Unknown gym type '\(gymType)'")
            return nil
        }

        // Convert specific arrays to sets
        var specificSets: [String: Set<String>] = [:]
        for (category, items) in preset.equipmentSpecific {
            specificSets[category] = Set(items)
        }

        // For dumbbells and kettlebells, they don't have specific items so just mark them as selected
        // by ensuring they're in the categories list (the Set will be empty for them)

        return (
            categories: preset.equipmentCategories,
            specific: specificSets,
            attachments: Set(preset.attachments)
        )
    }
}
