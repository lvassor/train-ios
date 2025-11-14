//
//  WorkoutViewModel.swift
//  trAInApp
//
//  Simplified to only handle questionnaire data
//

import Foundation
import SwiftUI
import Combine

class WorkoutViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var questionnaireData = QuestionnaireData()

    // MARK: - Initialization
    init() {
        // Simplified initialization
    }

    // MARK: - Questionnaire Completion
    func completeQuestionnaire() {
        // Generate program using ProgramGenerator
        let generator = ProgramGenerator()
        let program = generator.generateProgram(from: questionnaireData)

        // Save to current user
        if AuthService.shared.currentUser != nil {
            AuthService.shared.updateQuestionnaireData(questionnaireData)
            AuthService.shared.updateProgram(program)

            print("✅ Program generated and saved: \(program.type.description)")
            print("✅ Sessions: \(program.sessions.map { $0.dayName }.joined(separator: ", "))")
        }
    }
}
