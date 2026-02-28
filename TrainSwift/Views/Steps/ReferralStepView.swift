//
//  ReferralStepView.swift
//  TrainSwift
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
        ReferralOption(id: "google", title: "Google", icon: "magnifyingglass"),
        ReferralOption(id: "friend", title: "Friend", icon: "person.2"),
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

            // Referral options as square grid tiles
            referralGrid

            Spacer()
        }
    }

    private var referralGrid: some View {
        LazyVGrid(columns: gridColumns, spacing: Spacing.sm) {
            ForEach(referralOptions, id: \.id) { option in
                referralTile(for: option)
            }
        }
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
        let isSelected = selectedReferral == option.id
        return Button(action: { selectedReferral = option.id }) {
            VStack(spacing: Spacing.xs) {
                Image(systemName: option.icon)
                    .font(.trainHeadline).fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .trainPrimary)

                Text(option.title)
                    .font(.trainTag).fontWeight(.regular)
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
            RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                .fill(Color.trainPrimary)
        } else {
            RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                .fill(.ultraThinMaterial)
        }
    }

    private func tileOverlay(isSelected: Bool) -> some View {
        RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
            .stroke(
                isSelected ? Color.trainPrimary : Color.trainTextSecondary.opacity(0.3),
                lineWidth: 1
            )
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