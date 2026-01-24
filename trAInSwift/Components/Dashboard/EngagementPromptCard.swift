//
//  EngagementPromptCard.swift
//  trAInSwift
//
//  Engagement prompt carousel card for user actions and feedback
//

import SwiftUI

struct EngagementPromptCard: View {
    let data: EngagementPromptData

    var body: some View {
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
                .font(.system(size: 20))
                .foregroundColor(.trainPrimary)
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .onTapGesture {
            data.action?()
        }
    }
}

// MARK: - Preview

#Preview {
    let sampleData = EngagementPromptData(
        title: "Leave us a review!",
        description: "Help other athletes discover trAIn by sharing your experience on the App Store",
        action: {
            print("Tapped engagement prompt")
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