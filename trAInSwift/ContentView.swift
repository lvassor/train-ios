//
//  ContentView.swift
//  trAInSwift
//
//  Main app coordinator managing full app flow
//  FLOW: Launch Animation → Welcome → Questionnaire → Account → REAL Paywall → Dashboard
//        isAuthenticated = true → Dashboard (with hardcoded program)
//

import SwiftUI

struct ContentView: View {
    @ObservedObject private var workoutViewModel = WorkoutViewModel.shared
    @ObservedObject private var authService = AuthService.shared

    @State private var showLogin = false
    @State private var isSplashing = true

    var body: some View {
        ZStack {
            if isSplashing {
                LaunchScreenView()
                    .transition(.opacity)
                    .zIndex(1)
            } else {
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
                .zIndex(0)
            }
        }
        .task {
            // Wait for exact animation duration (3.5 seconds) then fade to main app
            try? await Task.sleep(for: .seconds(3.5))
            withAnimation(.easeInOut(duration: 0.5)) {
                isSplashing = false
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
