//
//  ReferralStepView.swift
//  trAInSwift
//
//  Referral tracking step for marketing attribution
//

import SwiftUI

struct ReferralStepView: View {
    @Binding var selectedReferral: String

    private let referralOptions = [
        ReferralOption(id: "tiktok", title: "TikTok", icon: "play.rectangle.fill"),
        ReferralOption(id: "instagram", title: "Instagram", icon: "camera"),
        ReferralOption(id: "chatgpt", title: "ChatGPT", icon: "message"),
        ReferralOption(id: "google", title: "Google Search", icon: "magnifyingglass"),
        ReferralOption(id: "friend", title: "Friend or Family", icon: "person.2"),
        ReferralOption(id: "influencer", title: "Influencer", icon: "star"),
        ReferralOption(id: "app_store", title: "App Store", icon: "square.stack.3d.down.right"),
        ReferralOption(id: "other", title: "Other", icon: "ellipsis")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            // Header
            VStack(alignment: .center, spacing: Spacing.sm) {
                Text("How did you hear about us?")
                    .font(.trainTitle2)
                    .foregroundColor(.trainTextPrimary)

                Text("Help us understand how people discover Train")
                    .font(.trainSubtitle)
                    .foregroundColor(.trainTextSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)

            // Referral options in a grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: Spacing.md) {
                ForEach(referralOptions, id: \.id) { option in
                    Button(action: { selectedReferral = option.id }) {
                        VStack(spacing: Spacing.md) {
                            // Enhanced icon container with better visual hierarchy
                            ZStack {
                                Circle()
                                    .fill(selectedReferral == option.id ? Color.trainPrimary : Color.trainHover)
                                    .frame(width: 56, height: 56)
                                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)

                                Image(systemName: option.icon)
                                    .font(.system(size: 24, weight: .medium))
                                    .foregroundColor(selectedReferral == option.id ? .white : .trainPrimary)
                            }

                            Text(option.title)
                                .font(.trainBodyMedium)
                                .foregroundColor(selectedReferral == option.id ? .trainPrimary : .trainTextPrimary)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.lg)
                        .background(
                            selectedReferral == option.id
                                ? Color.trainPrimary.opacity(0.05)
                                : Color.clear
                        )
                        .overlay(
                            // Border highlight for selected state
                            RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous)
                                .stroke(
                                    selectedReferral == option.id
                                        ? Color.trainPrimary.opacity(0.3)
                                        : Color.clear,
                                    lineWidth: 2
                                )
                        )
                        .appCard()
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }

            Spacer()
        }
    }
}

private struct ReferralOption {
    let id: String
    let title: String
    let icon: String
}

#Preview {
    ReferralStepView(selectedReferral: .constant(""))
        .charcoalGradientBackground()
}