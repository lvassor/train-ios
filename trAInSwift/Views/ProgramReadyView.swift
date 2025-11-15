//
//  ProgramReadyView.swift
//  trAInApp
//
//  Final screen showing program summary
//

import SwiftUI

struct ProgramReadyView: View {
    let program: Program
    let onStart: () -> Void
    @State private var showSignup = false
    @State private var showLoading = false
    @State private var showPaywall = false

    // MARK: - Feature Flags
    // Set to true to skip paywall for MVP/TestFlight
    // Set to false to enable paywall for production
    private let skipPaywallForMVP = true

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
                        if skipPaywallForMVP {
                            // MVP: Skip paywall and go straight to dashboard
                            print("🚀 MVP Mode: Skipping paywall")
                            onStart()
                        } else {
                            // Production: Show paywall
                            showPaywall = true
                        }
                    }
                })
            } else if showSignup {
                PostQuestionnaireSignupView(onSignupSuccess: {
                    withAnimation {
                        showLoading = true
                    }
                })
            } else {
                // Original Program Ready View
                programReadyContent
            }
        }
    }

    private var programReadyContent: some View {
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
                    Text("Program Ready!")
                        .font(.trainTitle)
                        .foregroundColor(.trainTextPrimary)

                    Text("Your personalised plan is complete")
                        .font(.trainSubtitle)
                        .foregroundColor(.trainTextSecondary)
                }

                // Program details
                VStack(spacing: 12) {
                    ProgramInfoCard(
                        label: "Program Duration",
                        value: "\(program.totalWeeks) weeks"
                    )

                    ProgramInfoCard(
                        label: "Exercise Split",
                        value: program.type.rawValue
                    )

                    ProgramInfoCard(
                        label: "Frequency",
                        value: "\(program.daysPerWeek) days per week"
                    )

                    ProgramInfoCard(
                        label: "Session Length",
                        value: program.sessionDuration.rawValue
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

struct ProgramInfoCard: View {
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
