//
//  AppViewModel.swift
//  TrainSwift
//
//  Main view model coordinating authentication, program generation, and workout tracking
//

import Foundation
import SwiftUI
import Combine

@MainActor
class AppViewModel: ObservableObject {
    @Published var authService = AuthService.shared
    @Published var questionnaireData = QuestionnaireData()
    @Published var isGeneratingProgram = false

    // Warning alert state for native iOS modals
    @Published var showWarningAlert = false
    @Published var warningAlertTitle = ""
    @Published var warningAlertMessage = ""

    private let programGenerator = ProgramGenerator()

    init() {
        // Database is now loaded directly via GRDB models
    }

    // MARK: - Questionnaire Completion

    func completeQuestionnaire() {
        guard let user = authService.currentUser else { return }

        isGeneratingProgram = true

        // Save questionnaire data to user
        authService.updateQuestionnaireData(questionnaireData)

        // Generate program based on questionnaire (with warnings)
        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self = self else { return }

            let result = self.programGenerator.generateProgramWithWarnings(from: await self.questionnaireData)

            await MainActor.run {
                self.authService.updateProgram(result.program)
                self.isGeneratingProgram = false

                // Show warning alert if there are any warnings
                if result.hasWarnings {
                    self.showWarnings(result.uniqueWarnings)
                }
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

    // MARK: - Program Management

    func retakeQuestionnaire() {
        questionnaireData = QuestionnaireData()
    }

    // MARK: - User State

    var hasActiveProgram: Bool {
        authService.getCurrentProgram() != nil
    }

    var needsQuestionnaire: Bool {
        authService.currentUser?.getQuestionnaireData() == nil
    }
}
