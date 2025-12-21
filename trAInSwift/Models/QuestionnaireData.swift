//
//  QuestionnaireData.swift
//  trAInApp
//
//  Updated for new questionnaire design
//

import Foundation

struct QuestionnaireData: Codable {
    // Authentication (not part of questionnaire, but for future use)
    var name: String = ""
    var email: String = ""
    var password: String = ""

    // Q1: Gender
    var gender: String = "" // "male", "female", "other"

    // Q2: Date of Birth (age calculated from this)
    var dateOfBirth: Date = Calendar.current.date(byAdding: .year, value: -25, to: Date()) ?? Date()
    var age: Int {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: dateOfBirth, to: Date())
        return ageComponents.year ?? 25
    }

    // Q3: Height
    var heightCm: Double = 180.0
    var heightFt: Int = 5
    var heightIn: Int = 10
    var heightUnit: HeightUnit = .cm

    // Q4: Weight
    var weightKg: Double = 70.0
    var weightLbs: Double = 150.0
    var weightUnit: WeightUnit = .kg

    // Q5: Primary Goals (single select)
    var primaryGoal: String = "" // "get_stronger", "build_muscle", "tone_up"

    // Q6: Muscle Groups (multi-select, max 3)
    var targetMuscleGroups: [String] = []

    // Q7: Experience Level
    var experienceLevel: String = "" // "0_months", "0_6_months", "6_months_2_years", "2_plus_years"

    // Q8: Motivation (multi-select)
    var motivations: [String] = []
    var motivationOther: String = ""

    // Q9: Equipment (multi-select) - default to all selected
    var equipmentAvailable: [String] = [
        "barbells", "dumbbells", "kettlebells", "cable_machines", "pin_loaded", "plate_loaded", "other"
    ]
    var detailedEquipment: [String: Set<String>] = [
        "barbells": ["Squat Rack", "Flat Bench Press", "Incline Bench Press", "Decline Bench Press", "Landmine Attachment", "Hip Thrust Bench"],
        "cable_machines": ["Single Adjustable Cable Machine", "Dual Cable Machine", "Lat Pull Down Machine", "Cable Row Machine"],
        "pin_loaded": ["Leg Press Machine", "Leg Extension Machine", "Lying Leg Curl Machine", "Seated Leg Curl Machine", "Standing Calf Raise Machine", "Seated Calf Raise Machine", "Hip Abduction Machine", "Hip Adduction Machine", "Assisted Pull-Up/Dip Machine"],
        "plate_loaded": ["Leg Press Machine", "Hack Squat Machine", "Leg Extension Machine", "Lying Leg Curl Machine", "Seated Leg Curl Machine", "Standing Calf Raise Machine", "Seated Calf Raise Machine", "Glute Kickback Machine"],
        "other": ["Ab Wheel", "Dip Station", "Flat Bench", "Pull-Up Bar", "Roman Chair"]
    ]  // Category -> specific items (e.g., "barbells" -> ["Squat Rack", "Flat Bench"])

    // Q10: Training Frequency
    var trainingDaysPerWeek: Int = 3

    // Additional fields for program generation
    var sessionDuration: String = "" // "30-45 min", "45-60 min", "60-90 min" - no default, user must select
    var injuries: [String] = [] // List of current injuries/limitations

    enum HeightUnit: String, Codable {
        case cm, ftIn
    }

    enum WeightUnit: String, Codable {
        case kg, lbs
    }
}
