//
//  OnboardingFlowView.swift
//  TrainSwift
//
//  Unified onboarding flow from Welcome to Questionnaire
//  Fixes sheet overlay issue by using proper navigation
//

import SwiftUI

struct OnboardingFlowView: View {
    @EnvironmentObject var workoutViewModel: WorkoutViewModel
    @Environment(\.dismiss) var dismiss

    /// If true, skip welcome screen (for retaking questionnaire when already authenticated)
    var isRetake: Bool = false

    @State private var showQuestionnaire = false
    @State private var showLogin = false

    /// Unique ID for this instance to track in logs
    private let instanceId = UUID().uuidString.prefix(8)

    var body: some View {
        NavigationStack {
            // For retake, skip welcome and go directly to questionnaire
            if !showQuestionnaire && !isRetake {
                WelcomeView(
                    onContinue: {
                        onboardingDebugLog("FLOW", "WelcomeView.onContinue.tapped", [
                            "instanceId": String(instanceId),
                            "previousShowQuestionnaire": "\(showQuestionnaire)",
                            "action": "Setting showQuestionnaire = true"
                        ])
                        showQuestionnaire = true
                        onboardingDebugLog("FLOW", "WelcomeView.onContinue.complete", [
                            "instanceId": String(instanceId),
                            "newShowQuestionnaire": "\(showQuestionnaire)"
                        ])
                    },
                    onLogin: {
                        onboardingDebugLog("FLOW", "WelcomeView.onLogin.tapped", [
                            "instanceId": String(instanceId),
                            "action": "Opening login sheet"
                        ])
                        showLogin = true
                    }
                )
                .onAppear {
                    onboardingDebugLog("FLOW", "WelcomeView.onAppear", [
                        "instanceId": String(instanceId),
                        "showQuestionnaire": "\(showQuestionnaire)",
                        "showLogin": "\(showLogin)",
                        "status": "✅ WelcomeView IS VISIBLE"
                    ])
                }
                .onDisappear {
                    onboardingDebugLog("FLOW", "WelcomeView.onDisappear", [
                        "instanceId": String(instanceId),
                        "showQuestionnaire": "\(showQuestionnaire)",
                        "reason": showQuestionnaire ? "Navigating to QuestionnaireView" : "Unknown"
                    ])
                }
                .sheet(isPresented: $showLogin) {
                    LoginView()
                }
            } else {
                QuestionnaireView(
                    onComplete: {
                        onboardingDebugLog("FLOW", "QuestionnaireView.onComplete", [
                            "instanceId": String(instanceId),
                            "isRetake": "\(isRetake)",
                            "action": isRetake ? "Retake complete - dismissing fullScreenCover" : "Questionnaire finished, ContentView will show Dashboard"
                        ])
                        // For retake flows (presented as fullScreenCover), dismiss the view
                        // For new user flows, ContentView will automatically show Dashboard based on isAuthenticated
                        if isRetake {
                            dismiss()
                        }
                    },
                    onBack: {
                        onboardingDebugLog("FLOW", "QuestionnaireView.onBack.tapped", [
                            "instanceId": String(instanceId),
                            "action": "Going back to WelcomeView"
                        ])
                        showQuestionnaire = false
                    }
                )
                .onAppear {
                    onboardingDebugLog("FLOW", "QuestionnaireView.onAppear", [
                        "instanceId": String(instanceId),
                        "showQuestionnaire": "\(showQuestionnaire)"
                    ])
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle()) // Ensures consistent behavior
        .onAppear {
            onboardingDebugLog("FLOW", "OnboardingFlowView.onAppear", [
                "instanceId": String(instanceId),
                "showQuestionnaire": "\(showQuestionnaire)",
                "showLogin": "\(showLogin)",
                "expectedFirstScreen": showQuestionnaire ? "QuestionnaireView" : "WelcomeView"
            ])
        }
    }
}

// MARK: - Debug Logging Helper

/// Comprehensive debug logging for onboarding flow troubleshooting
private func onboardingDebugLog(_ category: String, _ action: String, _ params: [String: String] = [:]) {
    var message = "[ONBOARDING-\(category)] \(action)"
    if !params.isEmpty {
        let paramString = params.map { "\($0.key)=\($0.value)" }.sorted().joined(separator: " | ")
        message += " | \(paramString)"
    }
    AppLogger.logUI(message)
}