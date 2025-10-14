//
//  CompletionModal.swift
//  trAInApp
//
//  Created by Claude Code on 2025-10-06.
//

import SwiftUI

struct CompletionModal: View {
    let feedback: PromptFeedback
    let onHide: () -> Void
    let onComplete: () -> Void

    var backgroundColor: Color {
        switch feedback.type {
        case .regression:
            return Color.red.opacity(0.1)
        case .consistency:
            return Color.orange.opacity(0.1)
        case .progression:
            return Color.green.opacity(0.1)
        }
    }

    var borderColor: Color {
        switch feedback.type {
        case .regression:
            return Color.red
        case .consistency:
            return Color.orange
        case .progression:
            return Color.green
        }
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Text(feedback.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .padding(.top)

                Text(feedback.message)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)

                Divider()
                    .padding(.vertical, 10)

                VStack(spacing: 12) {
                    Button(action: onHide) {
                        Text("Hide Prompt")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(hex: "404D53"))
                            .cornerRadius(12)
                    }

                    Button(action: onComplete) {
                        Text("Complete Exercise")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(hex: "3C825E"))
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .frame(maxWidth: 350)
            .background(backgroundColor)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(borderColor, lineWidth: 2)
            )
            .padding(40)
        }
    }
}
