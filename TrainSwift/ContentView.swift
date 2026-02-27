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
                NavigationStack {
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
