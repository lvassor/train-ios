//
//  ProgrammeReadyView.swift
//  trAInApp
//
//  Final screen showing programme summary
//

import SwiftUI

struct ProgrammeReadyView: View {
    let onStart: () -> Void
    @State private var showSignup = false
    @State private var showLoading = false
    @State private var showPaywall = false

    var body: some View {
        ZStack {
            // Show different screens based on state
            if showPaywall {
                PaywallView(onComplete: {
                    // After paywall, complete the whole flow
                    onStart()
                })
            } else if showLoading {
                AccountCreationLoadingView(onComplete: {
                    withAnimation {
                        showPaywall = true
                    }
                })
            } else if showSignup {
                PostQuestionnaireSignupView(onSignupSuccess: {
                    withAnimation {
                        showLoading = true
                    }
                })
            } else {
                // Original Programme Ready View
                programmeReadyContent
            }
        }
    }

    private var programmeReadyContent: some View {
        ZStack {
            Color.trainBackground
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Success icon
                ZStack {
                    Circle()
                        .fill(Color.trainPrimary)
                        .frame(width: 80, height: 80)

                    Image(systemName: "checkmark")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.white)
                }

                // Title
                VStack(spacing: 8) {
                    Text("Programme Ready!")
                        .font(.trainTitle)
                        .foregroundColor(.trainTextPrimary)

                    Text("Your personalised plan is complete")
                        .font(.trainSubtitle)
                        .foregroundColor(.trainTextSecondary)
                }

                // Programme details
                VStack(spacing: 12) {
                    ProgrammeInfoCard(
                        label: "Programme Duration",
                        value: "12 weeks"
                    )

                    ProgrammeInfoCard(
                        label: "Exercise Split",
                        value: "Upper/Lower"
                    )

                    ProgrammeInfoCard(
                        label: "Frequency",
                        value: "4 days per week"
                    )

                    ProgrammeInfoCard(
                        label: "Session Length",
                        value: "45-60 minutes"
                    )
                }
                .padding(.horizontal, 24)

                Spacer()

                // Start button
                CustomButton(
                    title: "Start Training Now!",
                    action: {
                        withAnimation {
                            showSignup = true
                        }
                    }
                )
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
    }
}

struct ProgrammeInfoCard: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: Spacing.sm) {
            Text(label)
                .font(.trainCaption)
                .foregroundColor(.trainTextSecondary)

            Text(value)
                .font(.trainBodyMedium)
                .foregroundColor(.trainTextPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.lg)
        .background(Color.white)
        .cornerRadius(CornerRadius.md)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}
