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

    var body: some View {
        Group {
            if authService.isAuthenticated, let user = authService.currentUser {
                // User is authenticated - show dashboard with program
                DashboardView()
            } else {
                // Not authenticated - show onboarding flow
                if showQuestionnaire {
                    // Show questionnaire (internally handles: questionnaire → programme ready → signup → loading → REAL paywall)
                    QuestionnaireView(onComplete: {
                        // After paywall completion, create authenticated user with program
                        createAuthenticatedUserWithProgram()
                    })
                    .environmentObject(workoutViewModel)
                } else {
                    // Show welcome screen first
                    WelcomeView(onContinue: {
                        showQuestionnaire = true
                    })
                }
            }
        }
    }

    // Create authenticated user with database-generated program after paywall completion
    private func createAuthenticatedUserWithProgram() {
        print("🎉 Creating authenticated user with database-generated program after paywall")

        // Create user
        var newUser = User(
            id: UUID().uuidString,
            email: "user@train.com",
            password: "password123"
        )

        // Set questionnaire data
        newUser.questionnaireData = workoutViewModel.questionnaireData

        // Generate personalized program using database and questionnaire data
        let generator = ProgramGenerator()
        let program = generator.generateProgram(from: workoutViewModel.questionnaireData)

        // Log program details for verification
        print("✅ Generated program type: \(program.type.description)")
        print("✅ Days per week: \(program.daysPerWeek)")
        print("✅ Session duration: \(program.sessionDuration.rawValue)")
        print("✅ Total sessions: \(program.sessions.count)")
        print("✅ Session names: \(program.sessions.map { $0.dayName }.joined(separator: ", "))")

        for (index, session) in program.sessions.enumerated() {
            print("✅ Session \(index + 1) - \(session.dayName): \(session.exercises.count) exercises")
            for exercise in session.exercises {
                print("   - \(exercise.exerciseName) (\(exercise.equipmentType))")
            }
        }

        let userProgram = UserProgram(program: program)
        newUser.currentProgram = userProgram

        // Authenticate user
        authService.currentUser = newUser
        authService.isAuthenticated = true
        authService.saveSession()

        print("✅ User authenticated with personalized program")
    }
}

#Preview {
    ContentView()
}
