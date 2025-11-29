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
    let selectedMuscleGroups: [String]  // Added for muscle groups display
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
            // Gradient base layer
            LinearGradient(
                stops: [
                    .init(color: Color(hex: "#a05608"), location: 0.0),
                    .init(color: Color(hex: "#692a00"), location: 0.15),
                    .init(color: Color(hex: "#1A1410"), location: 0.5),
                    .init(color: Color(hex: "#692a00"), location: 0.85),
                    .init(color: Color(hex: "#a05608"), location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
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

                // Program details - reordered as requested
                VStack(spacing: 12) {
                    ProgramInfoCard(
                        label: "Workout Split",
                        value: program.type.description
                    )

                    ProgramInfoCard(
                        label: "Prioritised Muscle Groups",
                        value: selectedMuscleGroups.isEmpty ? "Full body" : selectedMuscleGroups.joined(separator: ", ")
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
        .appCard()
    }
}
