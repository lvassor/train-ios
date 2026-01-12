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
                        VStack(spacing: Spacing.sm) {
                            ZStack {
                                Circle()
                                    .fill(selectedReferral == option.id ? Color.white.opacity(0.3) : Color.trainHover)
                                    .frame(width: 48, height: 48)

                                Image(systemName: option.icon)
                                    .font(.title2)
                                    .foregroundColor(selectedReferral == option.id ? .white : .trainPrimary)
                            }

                            Text(option.title)
                                .font(.trainBody)
                                .foregroundColor(selectedReferral == option.id ? .white : .trainTextPrimary)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.lg)
                        .background(selectedReferral == option.id ? Color.trainPrimary : .clear)
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