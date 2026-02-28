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
    var nextExerciseName: String? = nil
    let onPrimaryAction: () -> Void
    let onSecondaryAction: () -> Void
    var onNextExercise: (() -> Void)? = nil

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0)
                .ignoresSafeArea()

            // Modal card with liquid glass effect
            VStack(spacing: Spacing.lg) {
                // Title
                Text(title)
                    .font(.trainHeadline).fontWeight(.bold)
                    .foregroundColor(.trainTextPrimary)
                    .multilineTextAlignment(.center)

                // Message
                Text(message)
                    .font(.trainBody)
                    .foregroundColor(.trainTextSecondary)
                    .multilineTextAlignment(.center)

                // Buttons
                HStack(spacing: Spacing.md) {
                    // Secondary button (translucent)
                    Button(action: onSecondaryAction) {
                        Text("Edit")
                            .font(.trainBody).fontWeight(.semibold)
                            .foregroundColor(.trainTextPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: ElementHeight.button)
                            .background(Color.trainSurface.opacity(0.5))
                            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.pill, style: .continuous))
                    }

                    // Primary button (accent color)
                    Button(action: onPrimaryAction) {
                        Text("Continue")
                            .font(.trainBody).fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: ElementHeight.button)
                            .background(type.color)
                            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.pill, style: .continuous))
                    }
                }

                // Next Exercise button (only if there is a next exercise)
                if let nextName = nextExerciseName {
                    Button(action: { onNextExercise?() }) {
                        HStack {
                            Text("Next: \(nextName)")
                                .font(.trainBody).fontWeight(.medium)
                                .foregroundColor(.trainPrimary)
                            Image(systemName: "arrow.right")
                                .font(.trainCaption)
                                .foregroundColor(.trainPrimary)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: ElementHeight.touchTarget)
                        .background(Color.trainPrimary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.pill, style: .continuous))
                    }
                }
            }
            .padding(Spacing.xl)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.modal, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.modal, style: .continuous)
                    .stroke(Color.trainBorderSubtle.opacity(0.5), lineWidth: 1)
            )
            .shadowStyle(.modal)
            .padding(.horizontal, Spacing.xl)
        }
    }
}
