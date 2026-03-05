//
//  ContentView.swift
//  TrainSwift
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
                // No outer NavigationStack — each tab has its own in MainTabView
                // and OnboardingFlowView has its own NavigationStack internally.
                // A wrapping NavigationStack here causes double-stack, which makes
                // pushed views go full-screen and hides the tab bar.
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
        .task {
            try? await Task.sleep(for: .seconds(3.5))
            withAnimation(.easeInOut(duration: 0.5)) {
                isSplashing = false
            }
        }
    }

}

#Preview {
    ContentView()
}
