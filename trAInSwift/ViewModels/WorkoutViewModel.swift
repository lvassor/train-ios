//
//  WorkoutViewModel.swift
//  trAInApp
//
//  Simplified to only handle questionnaire data
//  Updated with warning alerts for exercise selection issues
//

import Foundation
import SwiftUI
import Combine

class WorkoutViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var questionnaireData = QuestionnaireData()
    @Published var generatedProgram: Program?

    // Warning alert state for native iOS modals
    @Published var showWarningAlert = false
    @Published var warningAlertTitle = ""
    @Published var warningAlertMessage = ""

    // Store warnings for display after program ready screen
    private var pendingWarnings: [ExerciseSelectionWarning] = []

    // MARK: - Initialization
    init() {
        // Simplified initialization
    }

    // MARK: - Program Generation
    func generateProgram() {
        // Generate program using ProgramGenerator with warnings
        let generator = ProgramGenerator()
        let result = generator.generateProgramWithWarnings(from: questionnaireData)

        // Store the generated program
        generatedProgram = result.program

        // Store warnings for display after user starts the program
        pendingWarnings = result.uniqueWarnings

        print("✅ Program generated: \(result.program.type.description)")
        print("✅ Sessions: \(result.program.sessions.map { $0.dayName }.joined(separator: ", "))")
        print("✅ Days per week: \(result.program.daysPerWeek)")
        print("✅ Total weeks: \(result.program.totalWeeks)")

        if result.hasWarnings {
            print("⚠️ Generation warnings: \(result.uniqueWarnings.count)")
        }
    }

    // MARK: - Questionnaire Completion
    func completeQuestionnaire() {
        // Save to current user
        if let program = generatedProgram, AuthService.shared.currentUser != nil {
            AuthService.shared.updateQuestionnaireData(questionnaireData)
            AuthService.shared.updateProgram(program)

            print("✅ Program saved to user")

            // Show any pending warnings after saving
            if !pendingWarnings.isEmpty {
                showWarnings(pendingWarnings)
                pendingWarnings = []
            }
        }
    }

    // MARK: - Warning Display

    /// Show warnings to user via native iOS alert
    private func showWarnings(_ warnings: [ExerciseSelectionWarning]) {
        guard !warnings.isEmpty else { return }

        // Build warning message from unique warnings
        let messages = warnings.map { $0.message }
        let combinedMessage = messages.joined(separator: "\n\n")

        warningAlertTitle = "Program Generation Notice"
        warningAlertMessage = combinedMessage
        showWarningAlert = true
    }

    /// Dismiss warning alert
    func dismissWarningAlert() {
        showWarningAlert = false
        warningAlertTitle = ""
        warningAlertMessage = ""
    }
}
