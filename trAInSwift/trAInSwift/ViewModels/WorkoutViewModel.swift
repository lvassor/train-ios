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

        // Create UserProgram wrapper
        let userProgram = UserProgram(program: program)

        // Save to current user
        if var user = AuthService.shared.currentUser {
            user.questionnaireData = questionnaireData
            user.currentProgram = userProgram
            AuthService.shared.currentUser = user
            AuthService.shared.saveSession()

            print("✅ Program generated and saved: \(program.type.description)")
            print("✅ Sessions: \(program.sessions.map { $0.dayName }.joined(separator: ", "))")
        }
    }
}
