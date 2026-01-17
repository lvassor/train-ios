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
    @ObservedObject private var workoutViewModel = WorkoutViewModel.shared
    @ObservedObject private var authService = AuthService.shared

    @State private var showLogin = false

    var body: some View {
        NavigationView {
            if authService.isAuthenticated {
                DashboardView()
                    .environmentObject(workoutViewModel)
            } else {
                OnboardingFlowView()
                    .environmentObject(workoutViewModel)
                    .sheet(isPresented: $showLogin) {
                        LoginView()
                    }
            }
        }
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
