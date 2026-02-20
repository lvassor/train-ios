//
//  ExerciseLoggerFeedback.swift
//  TrainSwift
//
//  Feedback modal overlay for exercise completion
//

import SwiftUI

// MARK: - Feedback Modal Overlay (Central Popup Style with Liquid Glass)

struct FeedbackModalOverlay: View {
    let title: String
    let message: String
    let type: ExerciseLoggerView.FeedbackType
    let onPrimaryAction: () -> Void
    let onSecondaryAction: () -> Void

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0)
                .ignoresSafeArea()

            // Modal card with liquid glass effect
            VStack(spacing: Spacing.lg) {
                // Title
                Text(title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.trainTextPrimary)
                    .multilineTextAlignment(.center)

                // Message
                Text(message)
                    .font(.system(size: 16))
                    .foregroundColor(.trainTextSecondary)
                    .multilineTextAlignment(.center)

                // Buttons
                HStack(spacing: Spacing.md) {
                    // Secondary button (translucent)
                    Button(action: onSecondaryAction) {
                        Text("Edit")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.trainTextPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.white.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
                    }

                    // Primary button (accent color)
                    Button(action: onPrimaryAction) {
                        Text("Continue")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(type.color)
                            .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
                    }
                }
            }
            .padding(Spacing.xl)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.25), radius: 30, x: 0, y: 10)
            .padding(.horizontal, Spacing.xl)
        }
    }
}
