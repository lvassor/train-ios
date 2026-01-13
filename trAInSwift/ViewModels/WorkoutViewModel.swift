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
            print("📧 [VIEWMODEL] 🚨🚨🚨 showEmailSignup changed from \(oldValue) to \(showEmailSignup)")
            if !showEmailSignup && oldValue {
                print("📧 [VIEWMODEL] ❌❌❌ EMAIL SHEET WAS DISMISSED! This should only happen on successful signup or user cancellation")
                print("📧 [VIEWMODEL] 🕵️ Call stack trace for debugging:")
                for symbol in Thread.callStackSymbols {
                    print("📧 [VIEWMODEL] \(symbol)")
                }
            }
        }
    }

    // Navigation state to prevent overlapping transitions
    @Published var isNavigationInProgress = false {
        didSet {
            print("🚦 [NAVIGATION] isNavigationInProgress changed from \(oldValue) to \(isNavigationInProgress)")
        }
    }

    // Store warnings for display after program ready screen
    private var pendingWarnings: [ExerciseSelectionWarning] = []

    // MARK: - Initialization
    private init() {
        // Private init to enforce singleton pattern
        print("🧠 [VIEWMODEL] 🎬 WorkoutViewModel.shared created - instance: \(ObjectIdentifier(self))")
        print("🧠 [VIEWMODEL] 🔒 This is the ONLY instance that should ever exist!")
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

    // MARK: - Navigation Management

    /// Safely execute navigation operations to prevent UIKit conflicts
    func safeNavigate(operation: @escaping () -> Void) {
        // Prevent overlapping navigation operations
        guard !isNavigationInProgress else {
            print("🚦 [NAVIGATION] ⚠️ Navigation already in progress - skipping operation")
            return
        }

        print("🚦 [NAVIGATION] ✅ Starting safe navigation operation")
        isNavigationInProgress = true

        // Execute on main queue with slight delay to ensure UI stability
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            operation()

            // Reset navigation state after completion
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.isNavigationInProgress = false
                print("🚦 [NAVIGATION] ✅ Navigation operation completed")
            }
        }
    }
}
