//
//  PostSignupFlowView.swift
//  TrainSwift
//
//  Coordinator for post-signup onboarding steps (Steps 18-19)
//  Handles notifications permission and referral tracking
//

import SwiftUI

struct PostSignupFlowView: View {
    let onComplete: () -> Void

    @State private var currentStep: PostSignupStep = .notifications

    enum PostSignupStep {
        case notifications  // Step 18
        case referral      // Step 19
    }

    var body: some View {
        ZStack {
            switch currentStep {
            case .notifications:
                NotificationPermissionView(
                    onContinue: {
                        print("🔄 [POST-SIGNUP] Step 18 (Notifications) completed, moving to step 19 (Referral)")
                        withAnimation {
                            currentStep = .referral
                        }
                    }
                )
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))

            case .referral:
                ReferralPageView(
                    onComplete: {
                        print("🔄 [POST-SIGNUP] Step 19 (Referral) completed, finishing onboarding flow")
                        onComplete()
                    },
                    onBack: {
                        print("⬅️ [POST-SIGNUP] Back from referral step, returning to notifications")
                        withAnimation {
                            currentStep = .notifications
                        }
                    }
                )
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            }
        }
        .onAppear {
            print("🔄 [POST-SIGNUP] PostSignupFlowView appeared, starting with step 18 (Notifications)")
        }
    }
}

#Preview {
    PostSignupFlowView(
        onComplete: {
            print("Post-signup flow completed")
        }
    )
}