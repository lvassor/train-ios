//
//  ContentView.swift
//  trAInSwift
//
//  Main app coordinator managing full app flow
//  FLOW: isAuthenticated = false → Welcome → Questionnaire → Account → REAL Paywall → Dashboard
//        isAuthenticated = true → Dashboard (with hardcoded program)
//

import SwiftUI

struct ContentView: View {
    @StateObject private var workoutViewModel = WorkoutViewModel()
    @ObservedObject private var authService = AuthService.shared

    @State private var showQuestionnaire = false
    @State private var showLogin = false

    var body: some View {
        Group {
            if authService.isAuthenticated, let user = authService.currentUser {
                // User is authenticated - show dashboard with program
                DashboardView()
            } else {
                // Not authenticated - show onboarding flow
                if showLogin {
                    // Show login screen
                    LoginView()
                } else if showQuestionnaire {
                    // Show questionnaire (internally handles: questionnaire → programme ready → signup → loading → REAL paywall)
                    // NOTE: Program is saved immediately after signup in PostQuestionnaireSignupView
                    QuestionnaireView(
                        onComplete: {
                            // Paywall completed - user and program already saved
                            // Just refresh the auth state
                            print("✅ Onboarding flow complete - user authenticated with program")
                        },
                        onBack: {
                            // Go back to welcome screen
                            showQuestionnaire = false
                        }
                    )
                    .environmentObject(workoutViewModel)
                } else {
                    // Show welcome screen first
                    WelcomeView(
                        onContinue: {
                            showQuestionnaire = true
                        },
                        onLogin: {
                            showLogin = true
                        }
                    )
                }
            }
        }
        .warmDarkGradientBackground()
    }

    // DEPRECATED: This function is no longer used
    // Program is now saved immediately after signup in PostQuestionnaireSignupView
    // This prevents the bug where users got stuck with no program
    private func createAuthenticatedUserWithProgram() {
        print("⚠️ DEPRECATED: createAuthenticatedUserWithProgram() called but no longer needed")
        print("⚠️ Program should already be saved in PostQuestionnaireSignupView")
    }
}

#Preview {
    ContentView()
}
