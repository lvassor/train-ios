//
//  QuestionnaireStateManager.swift
//  TrainSwift
//
//  Persists questionnaire progress so users can resume after app kill
//

import Foundation

/// Persists questionnaire progress to UserDefaults so users can resume after app kill
struct QuestionnaireStateManager {
    private static let stepKey = "questionnaire_currentStep"
    private static let dataKey = "questionnaire_savedData"

    /// Save current step and questionnaire data
    static func save(step: Int, data: QuestionnaireData) {
        UserDefaults.standard.set(step, forKey: stepKey)
        if let encoded = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encoded, forKey: dataKey)
        }
    }

    /// Restore saved step (returns nil if no saved state)
    static func savedStep() -> Int? {
        let step = UserDefaults.standard.integer(forKey: stepKey)
        return step > 0 ? step : nil
    }

    /// Restore saved questionnaire data
    static func savedData() -> QuestionnaireData? {
        guard let data = UserDefaults.standard.data(forKey: dataKey) else { return nil }
        return try? JSONDecoder().decode(QuestionnaireData.self, from: data)
    }

    /// Clear saved state (call on questionnaire completion)
    static func clear() {
        UserDefaults.standard.removeObject(forKey: stepKey)
        UserDefaults.standard.removeObject(forKey: dataKey)
    }
}
