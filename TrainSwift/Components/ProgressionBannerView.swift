//
//  ProgressionBannerView.swift
//  TrainSwift
//
//  WHOOP-style progression banner shown when previous session
//  exceeded the rep range, indicating readiness to increase weight.
//

import SwiftUI

struct ProgressionBannerView: View {
    let exerciseName: String
    @Binding var isVisible: Bool

    var body: some View {
        HStack(spacing: Spacing.smd) {
            // Upward arrow icon
            Image(systemName: "arrow.up.circle.fill")
                .font(.system(size: IconSize.md))
                .foregroundColor(.white)

            // Message text
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text("You're ready to increase the weight!")
                    .font(.trainBodyMedium)
                    .foregroundColor(.white)

                Text("You exceeded the rep range last session. Consider progressing to a higher weight.")
                    .font(.trainCaption)
                    .foregroundColor(.white.opacity(0.85))
                    .lineLimit(2)
            }

            Spacer()

            // Dismiss button
            Button(action: {
                withAnimation(.easeOut(duration: 0.2)) {
                    isVisible = false
                }
            }) {
                Image(systemName: "xmark")
                    .font(.trainCaption).fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: IconSize.md, height: IconSize.md)
            }
        }
        .padding(Spacing.md)
        .background(Color.trainSuccess.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous))
    }
}
