//
//  OnboardingFlowExample.swift
//  TrainSwift
//
//  Example implementation of how video interstitials can be integrated into the main flow
//

import SwiftUI

struct OnboardingFlowExample: View {
    @State private var showingVideoInterstitials = false
    @State private var currentPhase: OnboardingPhase = .welcome

    enum OnboardingPhase {
        case welcome
        case videoInterstitials
        case questionnaire
        case complete
    }

    var body: some View {
        switch currentPhase {
        case .welcome:
            WelcomeView(
                onContinue: {
                    currentPhase = .videoInterstitials
                },
                onLogin: {
                    // Handle login
                }
            )

        case .videoInterstitials:
            FirstVideoInterstitialView(
                onComplete: {
                    currentPhase = .questionnaire
                }
            )

        case .questionnaire:
            QuestionnaireView(
                onComplete: {
                    currentPhase = .complete
                }
            )

        case .complete:
            Text("Onboarding Complete!")
                .font(.trainTitle)
                .foregroundColor(.trainTextPrimary)
        }
    }
}

// MARK: - Alternative: Integrated into QuestionnaireView

/*
 To integrate video interstitials directly into the questionnaire flow,
 you could modify QuestionnaireView to include interstitial steps:

 1. Update totalSteps to include interstitials:
    - Add 2 more steps for the video interstitials
    - Place after goals (step 1) and after experience (step 7)

 2. Modify currentStepView to show interstitials:
    ```swift
    case 2: // First Video Interstitial (after goals)
        VideoInterstitialView(onComplete: proceedToNextStep)

    case 8: // Second Video Interstitial (after experience)
        VideoInterstitialView(onComplete: proceedToNextStep)
    ```

 3. Update validation logic to auto-validate interstitials:
    ```swift
    case 2, 8: // Video interstitials are always valid
        return true
    ```

 This approach would seamlessly blend the video content into the questionnaire
 flow while maintaining progress tracking and navigation consistency.
*/

#Preview {
    OnboardingFlowExample()
}