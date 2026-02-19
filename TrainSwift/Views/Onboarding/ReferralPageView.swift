//
//  ReferralPageView.swift
//  TrainSwift
//
//  How did you hear about us referral tracking (Step 19)
//

import SwiftUI

struct ReferralPageView: View {
    let onComplete: () -> Void
    let onBack: (() -> Void)?

    @State private var selectedReferralSource: String = ""

    init(onComplete: @escaping () -> Void, onBack: (() -> Void)? = nil) {
        self.onComplete = onComplete
        self.onBack = onBack
    }

    private let referralOptions = [
        ReferralOption(id: "tiktok", title: "TikTok", icon: "play.rectangle.fill"),
        ReferralOption(id: "instagram", title: "Instagram", icon: "camera"),
        ReferralOption(id: "chatgpt", title: "ChatGPT", icon: "message"),
        ReferralOption(id: "google", title: "Google", icon: "magnifyingglass"),
        ReferralOption(id: "friend", title: "Friend", icon: "person.2"),
        ReferralOption(id: "influencer", title: "Influencer", icon: "star"),
        ReferralOption(id: "app_store", title: "App Store", icon: "square.stack.3d.down.right"),
        ReferralOption(id: "other", title: "Other", icon: "ellipsis")
    ]

    private struct ReferralOption: Identifiable {
        let id: String
        let title: String
        let icon: String
    }

    var body: some View {
        ZStack {
            AppGradient.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    backButtonSection
                    headerSection
                    referralGrid
                    Spacer().frame(height: 32)
                    startButton
                }
            }
        }
        .onAppear {
            AppLogger.logUI("[REFERRAL] ReferralPageView appeared")
        }
    }

    @ViewBuilder
    private var backButtonSection: some View {
        if let onBack = onBack {
            HStack {
                Button(action: {
                    AppLogger.logUI("[REFERRAL] Back button tapped")
                    onBack()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                            .font(.title3)
                            .foregroundColor(.trainTextPrimary)
                        Text("Back")
                            .font(.trainBody)
                            .foregroundColor(.trainTextPrimary)
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
        } else {
            Spacer().frame(height: 60)
        }
    }

    private var headerSection: some View {
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
    }

    private var referralGrid: some View {
        LazyVGrid(columns: gridColumns, spacing: Spacing.sm) {
            ForEach(referralOptions) { option in
                referralTile(for: option)
            }
        }
        .padding(.horizontal, 24)
    }

    private var gridColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: Spacing.sm),
            GridItem(.flexible(), spacing: Spacing.sm),
            GridItem(.flexible(), spacing: Spacing.sm),
            GridItem(.flexible(), spacing: Spacing.sm)
        ]
    }

    private func referralTile(for option: ReferralOption) -> some View {
        let isSelected = selectedReferralSource == option.id
        return Button(action: {
            selectedReferralSource = option.id
            AppLogger.logUI("[REFERRAL] Selected referral source: \(option.id)")
        }) {
            VStack(spacing: Spacing.xs) {
                Image(systemName: option.icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(isSelected ? .white : .trainPrimary)

                Text(option.title)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(isSelected ? .white : .trainTextPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
            }
            .padding(Spacing.md)
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .background(tileBackground(isSelected: isSelected))
            .overlay(tileOverlay(isSelected: isSelected))
        }
        .buttonStyle(ScaleButtonStyle())
    }

    @ViewBuilder
    private func tileBackground(isSelected: Bool) -> some View {
        if isSelected {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.trainPrimary)
        } else {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
        }
    }

    private func tileOverlay(isSelected: Bool) -> some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .stroke(
                isSelected ? Color.trainPrimary : Color.trainTextSecondary.opacity(0.3),
                lineWidth: 1
            )
    }

    private var startButton: some View {
        Button(action: {
            if !selectedReferralSource.isEmpty {
                AppLogger.logUI("[REFERRAL] Saving referral source: \(selectedReferralSource)")
                UserDefaults.standard.set(selectedReferralSource, forKey: "referral_source")
            } else {
                AppLogger.logUI("[REFERRAL] No referral source selected")
            }

            AppLogger.logUI("[REFERRAL] Completing onboarding flow - proceeding to dashboard")
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

#Preview {
    ReferralPageView(
        onComplete: {
            AppLogger.logUI("Referral page completed")
        }
    )
}