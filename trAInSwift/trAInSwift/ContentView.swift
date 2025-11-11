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
                    QuestionnaireView(onComplete: {
                        // After paywall completion, create authenticated user with program
                        createAuthenticatedUserWithProgram()
                    })
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
    }

    // Create authenticated user with database-generated program after paywall completion
    private func createAuthenticatedUserWithProgram() {
        print("🎉 Creating authenticated user with database-generated program after paywall")

        // For now, use signup to create a demo user
        // In production, this would be a real signup flow
        let email = "demo\(Int.random(in: 1000...9999))@train.com"
        let password = "demo123"

        let result = authService.signup(email: email, password: password)

        switch result {
        case .success:
            // Save questionnaire data
            authService.updateQuestionnaireData(workoutViewModel.questionnaireData)

            // Generate personalized program
            let generator = ProgramGenerator()
            let program = generator.generateProgram(from: workoutViewModel.questionnaireData)

            // Log program details for verification
            print("✅ Generated program type: \(program.type.description)")
            print("✅ Days per week: \(program.daysPerWeek)")
            print("✅ Session duration: \(program.sessionDuration.rawValue)")
            print("✅ Total sessions: \(program.sessions.count)")
            print("✅ Session names: \(program.sessions.map { $0.dayName }.joined(separator: ", "))")

            // Save program
            authService.updateProgram(program)

            print("✅ User authenticated with personalized program")

        case .failure(let error):
            print("❌ Failed to create user: \(error.localizedDescription)")
        }
    }
}

#Preview {
    ContentView()
}
