//
//  WorkoutViewModel.swift
//  TrainSwift
//
//  Simplified to only handle questionnaire data
//  Updated with warning alerts for exercise selection issues
//

import Foundation
import SwiftUI
import Combine

@MainActor
class WorkoutViewModel: ObservableObject {
    // MARK: - Singleton
    static let shared = WorkoutViewModel()

    // MARK: - Published Properties
    @Published var questionnaireData = QuestionnaireData()
    @Published var generatedProgram: Program?

    // Warning alert state for native iOS modals
    @Published var showWarningAlert = false
    @Published var warningAlertTitle = ""
    @Published var warningAlertMessage = ""

    // Email signup state that persists across view recreations
    @Published var showEmailSignup = false {
        didSet {
            AppLogger.logUI("showEmailSignup changed from \(oldValue) to \(showEmailSignup)")
            if !showEmailSignup && oldValue {
                AppLogger.logUI("Email sheet dismissed", level: .warning)
            }
        }
    }

    // Navigation state to prevent overlapping transitions
    @Published var isNavigationInProgress = false {
        didSet {
            AppLogger.logUI("isNavigationInProgress changed from \(oldValue) to \(isNavigationInProgress)")
        }
    }

    // Store warnings for display after program ready screen
    private var pendingWarnings: [ExerciseSelectionWarning] = []

    // MARK: - Initialization
    private init() {
        // Private init to enforce singleton pattern
        AppLogger.logUI("WorkoutViewModel.shared created — instance: \(ObjectIdentifier(self))")
    }

    // MARK: - Program Generation
    func generateProgram() {
        // Generate program using ProgramGenerator with warnings
        let generator = ProgramGenerator()
        let result = generator.generateProgramWithWarnings(from: questionnaireData)

        // Store the generated program
        generatedProgram = result.program

        // Store warnings for display after user starts the program
        // Include both the unique warnings AND the boolean flags converted to warnings
        pendingWarnings = result.uniqueWarnings

        // Add low fill rate warning if applicable
        if result.lowFillWarning {
            pendingWarnings.append(.lowFillRate(fillRate: 0))
        }

        // Note: repeatWarning is already captured in uniqueWarnings via .exerciseRepeats

        AppLogger.logProgram("Program generated: \(result.program.type.description), sessions: \(result.program.sessions.map { $0.dayName }.joined(separator: ", ")), \(result.program.daysPerWeek) days/week, \(result.program.totalWeeks) weeks")

        if result.hasWarnings {
            AppLogger.logProgram("Generation warnings: \(result.uniqueWarnings.count)", level: .warning)
        }
        if result.lowFillWarning {
            AppLogger.logProgram("Low fill rate warning triggered", level: .warning)
        }
    }

    // MARK: - Questionnaire Completion

    /// Completes the questionnaire and saves program. Returns true if there are warnings to show.
    /// If true is returned, the caller should NOT proceed to dashboard until user dismisses warning.
    func completeQuestionnaire() -> Bool {
        // Save to current user
        if let program = generatedProgram, AuthService.shared.currentUser != nil {
            AuthService.shared.updateQuestionnaireData(questionnaireData)
            AuthService.shared.updateProgram(program)

            AppLogger.logProgram("Program saved to user")

            // Show any pending warnings after saving
            if !pendingWarnings.isEmpty {
                showWarnings(pendingWarnings)
                // Don't clear warnings yet - they'll be cleared when user proceeds
                AppLogger.logProgram("Showing \(pendingWarnings.count) warnings — waiting for user decision", level: .warning)
                return true  // Caller should wait for user to choose Amend or Proceed
            }
        }
        return false  // No warnings, can proceed immediately
    }

    /// Called when user chooses "Proceed Anyway" after seeing warnings
    func proceedAfterWarning() {
        AppLogger.logProgram("User chose to proceed despite warnings")
        pendingWarnings = []
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

    // MARK: - Navigation Management

    /// Safely execute navigation operations to prevent UIKit conflicts
    func safeNavigate(operation: @escaping @MainActor () -> Void) {
        // Prevent overlapping navigation operations
        guard !isNavigationInProgress else {
            AppLogger.logUI("Navigation already in progress — skipping operation", level: .warning)
            return
        }

        isNavigationInProgress = true

        Task {
            // Brief delay to ensure UI stability before navigating
            try? await Task.sleep(for: .milliseconds(100))
            operation()

            // Reset navigation state after completion
            try? await Task.sleep(for: .milliseconds(500))
            self.isNavigationInProgress = false
        }
    }
}
