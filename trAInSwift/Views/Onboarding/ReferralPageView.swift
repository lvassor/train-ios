//
//  ReferralPageView.swift
//  trAInSwift
//
//  How did you hear about us referral tracking (Step 19)
//

import SwiftUI

struct ReferralPageView: View {
    let onComplete: () -> Void

    @State private var selectedReferralSource: String = ""

    private let referralSources = [
        "Friend or Family",
        "Social Media",
        "Search Engine",
        "App Store",
        "Advertisement",
        "Fitness Blog/Website",
        "Gym/Trainer Recommendation",
        "Podcast",
        "Other"
    ]

    var body: some View {
        ZStack {
            AppGradient.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    Spacer()
                        .frame(height: 60)

                    // Header
                    VStack(spacing: 16) {
                        Text("How did you hear about us?")
                            .font(.trainTitle)
                            .foregroundColor(.trainTextPrimary)
                            .multilineTextAlignment(.center)

                        Text("Help us understand how people discover Train so we can reach more fitness enthusiasts.")
                            .font(.trainBody)
                            .foregroundColor(.trainTextSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }

                    // Referral sources
                    VStack(spacing: 12) {
                        ForEach(referralSources, id: \.self) { source in
                            Button(action: {
                                selectedReferralSource = source
                                print("📊 [REFERRAL] Selected referral source: \(source)")
                            }) {
                                HStack {
                                    Text(source)
                                        .font(.trainBody)
                                        .foregroundColor(.trainTextPrimary)
                                        .frame(maxWidth: .infinity, alignment: .leading)

                                    if selectedReferralSource == source {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.trainPrimary)
                                            .font(.title3)
                                    } else {
                                        Image(systemName: "circle")
                                            .foregroundColor(.trainBorder)
                                            .font(.title3)
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .background(
                                    selectedReferralSource == source ?
                                    Color.trainPrimary.opacity(0.1) :
                                    Color.trainBackground
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: CornerRadius.md)
                                        .stroke(
                                            selectedReferralSource == source ?
                                            Color.trainPrimary :
                                            Color.trainBorder,
                                            lineWidth: selectedReferralSource == source ? 2 : 1
                                        )
                                )
                                .cornerRadius(CornerRadius.md)
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                    }
                    .padding(.horizontal, 24)

                    Spacer()
                        .frame(height: 32)

                    // Start Training Now Button
                    Button(action: {
                        // Save referral source if selected
                        if !selectedReferralSource.isEmpty {
                            print("📊 [REFERRAL] Saving referral source: \(selectedReferralSource)")
                            // TODO: Save to analytics or user profile
                            UserDefaults.standard.set(selectedReferralSource, forKey: "referral_source")
                        } else {
                            print("📊 [REFERRAL] No referral source selected")
                        }

                        print("📊 [REFERRAL] Completing onboarding flow - proceeding to dashboard")
                        onComplete()
                    }) {
                        Text("Start Training Now!")
                            .font(.trainBodyMedium)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: ButtonHeight.standard)
                            .background(Color.trainPrimary)
                            .cornerRadius(CornerRadius.md)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 50)
                }
            }
        }
        .onAppear {
            print("📊 [REFERRAL] ReferralPageView appeared")
        }
    }
}

#Preview {
    ReferralPageView(
        onComplete: {
            print("Referral page completed")
        }
    )
}