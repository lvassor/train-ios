//
//  OnboardingFlowView.swift
//  trAInSwift
//
//  Unified onboarding flow from Welcome to Questionnaire
//  Fixes sheet overlay issue by using proper navigation
//

import SwiftUI

struct OnboardingFlowView: View {
    @EnvironmentObject var workoutViewModel: WorkoutViewModel
    @State private var showQuestionnaire = false
    @State private var showLogin = false

    var body: some View {
        NavigationStack {
            if !showQuestionnaire {
                WelcomeView(
                    onContinue: {
                        print("🚀 [ONBOARDING] WelcomeView onContinue - navigating to questionnaire")
                        showQuestionnaire = true
                    },
                    onLogin: {
                        print("🔐 [ONBOARDING] WelcomeView onLogin triggered - showing login")
                        showLogin = true
                    }
                )
                .onAppear {
                    print("🎬 [ONBOARDING] WelcomeView appeared in unified flow")
                }
                .sheet(isPresented: $showLogin) {
                    LoginView()
                }
            } else {
                QuestionnaireView(
                    onComplete: {
                        print("✅ [ONBOARDING] Questionnaire completed")
                        // The QuestionnaireView handles authentication internally
                        // Once complete, ContentView will automatically show Dashboard
                    },
                    onBack: {
                        print("⬅️ [ONBOARDING] Going back to WelcomeView")
                        showQuestionnaire = false
                    }
                )
            }
        }
        .navigationViewStyle(StackNavigationViewStyle()) // Ensures consistent behavior
    }
}