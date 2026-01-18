//
//  ContentView.swift
//  trAInSwift
//
//  Main app coordinator managing full app flow
//  FLOW: Launch Animation → Welcome → Questionnaire → Account → REAL Paywall → Dashboard
//        isAuthenticated = true → Dashboard (with hardcoded program)
//

import SwiftUI

// Notification name for splash screen reset
extension Notification.Name {
    static let resetToSplash = Notification.Name("resetToSplash")
}

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
                    .onAppear {
                        print("🚀 [LAUNCH] LaunchScreenView appeared - starting animation sequence")
                    }
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
            print("🚀 [LAUNCH] ContentView.task started - beginning 3.5s countdown")
            // Wait for exact animation duration (3.5 seconds) then fade to main app
            try? await Task.sleep(for: .seconds(3.5))
            print("🚀 [LAUNCH] 3.5s elapsed - transitioning to main app")
            withAnimation(.easeInOut(duration: 0.5)) {
                isSplashing = false
            }
            print("🚀 [LAUNCH] Transition animation started (0.5s duration)")
        }
        .onAppear {
            print("🚀 [LAUNCH] ContentView appeared - isSplashing: \(isSplashing)")
        }
        .onReceive(NotificationCenter.default.publisher(for: .resetToSplash)) { _ in
            print("🚀 [LAUNCH] Reset to splash notification received")
            withAnimation(.easeInOut(duration: 0.5)) {
                isSplashing = true
            }
            // Restart the splash animation sequence
            Task {
                try? await Task.sleep(for: .seconds(3.5))
                print("🚀 [LAUNCH] Reset animation completed - transitioning to main app")
                withAnimation(.easeInOut(duration: 0.5)) {
                    isSplashing = false
                }
            }
        }
    }

}

#Preview {
    ContentView()
}
