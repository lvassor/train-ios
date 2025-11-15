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
    @Published var generatedProgram: Program?

    // MARK: - Initialization
    init() {
        // Simplified initialization
    }

    // MARK: - Program Generation
    func generateProgram() {
        // Generate program using ProgramGenerator
        let generator = ProgramGenerator()
        let program = generator.generateProgram(from: questionnaireData)

        // Store the generated program
        generatedProgram = program

        print("✅ Program generated: \(program.type.description)")
        print("✅ Sessions: \(program.sessions.map { $0.dayName }.joined(separator: ", "))")
        print("✅ Days per week: \(program.daysPerWeek)")
        print("✅ Total weeks: \(program.totalWeeks)")
    }

    // MARK: - Questionnaire Completion
    func completeQuestionnaire() {
        // Save to current user
        if let program = generatedProgram, AuthService.shared.currentUser != nil {
            AuthService.shared.updateQuestionnaireData(questionnaireData)
            AuthService.shared.updateProgram(program)

            print("✅ Program saved to user")
        }
    }
}
