//
//  EngagementPromptCard.swift
//  TrainSwift
//
//  Engagement prompt carousel card for user actions and feedback
//

import SwiftUI

struct EngagementPromptCard: View {
    let data: EngagementPromptData
    var onDismiss: (() -> Void)? = nil

    var body: some View {
        ZStack(alignment: .topTrailing) {
            HStack(spacing: Spacing.md) {
                // Content
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text(data.title)
                        .font(.trainBodyMedium)
                        .foregroundColor(.trainTextPrimary)

                    Text(data.description)
                        .font(.trainCaption)
                        .foregroundColor(.trainTextSecondary)
                        .lineLimit(3)
                }

                Spacer()

                // Action indicator
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: IconSize.md))
                    .foregroundColor(.trainPrimary)
            }
            .padding(Spacing.lg)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture {
                data.action?()
            }

            // Dismiss button
            if let onDismiss = onDismiss {
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.trainCaptionSmall).fontWeight(.semibold)
                        .foregroundColor(.trainTextSecondary)
                        .frame(width: IconSize.md, height: IconSize.md)
                }
                .padding(Spacing.sm)
                .accessibilityLabel("Dismiss prompt")
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let sampleData = EngagementPromptData(
        title: "Leave us a review!",
        description: "Help other athletes discover train by sharing your experience on the App Store",
        action: {
            AppLogger.logUI("Tapped engagement prompt")
        }
    )

    return ZStack {
        AppGradient.background
            .ignoresSafeArea()

        EngagementPromptCard(data: sampleData)
            .appCard()
            .padding()
    }
}