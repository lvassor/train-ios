//
//  ContentView.swift
//  TrainSwift
//
//  Main app coordinator managing full app flow
//  FLOW: Launch Animation → Welcome → Questionnaire → Account → REAL Paywall → Dashboard
//        isAuthenticated = true → Dashboard (with hardcoded program)
//

import SwiftUI

// Notification name for splash screen reset (legacy - no longer used for retake)
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
                        debugLog("CONTENT", "LaunchScreenView.onAppear", [
                            "isSplashing": "\(isSplashing)"
                        ])
                    }
            } else {
                NavigationView {
                    if authService.isAuthenticated {
                        DashboardView()
                            .environmentObject(workoutViewModel)
                            .onAppear {
                                debugLog("CONTENT", "DashboardView.onAppear", [
                                    "isAuthenticated": "\(authService.isAuthenticated)",
                                    "userId": authService.currentUser?.id?.uuidString ?? "nil"
                                ])
                            }
                    } else {
                        OnboardingFlowView()
                            .environmentObject(workoutViewModel)
                            .sheet(isPresented: $showLogin) {
                                LoginView()
                            }
                            .onAppear {
                                debugLog("CONTENT", "OnboardingFlowView.onAppear (from ContentView)", [
                                    "isAuthenticated": "\(authService.isAuthenticated)",
                                    "showLogin": "\(showLogin)"
                                ])
                            }
                    }
                }
                .zIndex(0)
            }
        }
        .task {
            debugLog("CONTENT", "task.started", [
                "isSplashing": "\(isSplashing)",
                "isAuthenticated": "\(authService.isAuthenticated)",
                "waitingFor": "3.5 seconds"
            ])
            // Wait for exact animation duration (3.5 seconds) then fade to main app
            try? await Task.sleep(for: .seconds(3.5))
            debugLog("CONTENT", "task.splashComplete", [
                "isAuthenticated": "\(authService.isAuthenticated)",
                "willShow": authService.isAuthenticated ? "DashboardView" : "OnboardingFlowView"
            ])
            withAnimation(.easeInOut(duration: 0.5)) {
                isSplashing = false
            }
            debugLog("CONTENT", "task.transitionStarted", [
                "isSplashing": "\(isSplashing)",
                "animationDuration": "0.5s"
            ])
        }
        .onAppear {
            debugLog("CONTENT", "ContentView.onAppear", [
                "isSplashing": "\(isSplashing)",
                "isAuthenticated": "\(authService.isAuthenticated)",
                "hasCurrentUser": "\(authService.currentUser != nil)"
            ])
        }
        .onReceive(NotificationCenter.default.publisher(for: .resetToSplash)) { _ in
            // NOTE: This is legacy and should NOT be used for retake questionnaire
            // The retake flow now uses fullScreenCover directly without resetting ContentView
            debugLog("CONTENT", "⚠️ resetToSplash.received (LEGACY)", [
                "currentIsSplashing": "\(isSplashing)",
                "isAuthenticated": "\(authService.isAuthenticated)",
                "warning": "This notification should NOT be used for retake questionnaire"
            ])
            withAnimation(.easeInOut(duration: 0.5)) {
                isSplashing = true
            }
            // Restart the splash animation sequence
            Task {
                try? await Task.sleep(for: .seconds(3.5))
                debugLog("CONTENT", "resetToSplash.animationComplete", [
                    "isAuthenticated": "\(authService.isAuthenticated)",
                    "willShow": authService.isAuthenticated ? "DashboardView (BUG!)" : "OnboardingFlowView"
                ])
                withAnimation(.easeInOut(duration: 0.5)) {
                    isSplashing = false
                }
            }
        }
    }

}

// MARK: - Debug Logging Helper

/// Comprehensive debug logging for onboarding flow troubleshooting
/// Format: 🔍 [CATEGORY] action | key1=value1 | key2=value2
private func debugLog(_ category: String, _ action: String, _ params: [String: String] = [:]) {
    let timestamp = Date().formatted(date: .omitted, time: .standard)
    var message = "🔍 [\(category)] \(action)"
    if !params.isEmpty {
        let paramString = params.map { "\($0.key)=\($0.value)" }.sorted().joined(separator: " | ")
        message += " | \(paramString)"
    }
    AppLogger.logUI("[\(timestamp)] \(message)")
}

#Preview {
    ContentView()
}
