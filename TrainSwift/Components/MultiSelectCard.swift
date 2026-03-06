//
//  MultiSelectCard.swift
//  TrainSwift
//
//  Multi-select option card component
//

import SwiftUI
import UIKit

struct MultiSelectCard: View {
    let title: String
    let subtitle: String?
    let isSelected: Bool
    let action: () -> Void
    var isCompact: Bool = false  // For smaller cards

    @State private var isHovered = false

    init(title: String, subtitle: String? = nil, isSelected: Bool, isCompact: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.subtitle = subtitle
        self.isSelected = isSelected
        self.isCompact = isCompact
        self.action = action
    }

    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        }) {
            HStack(spacing: Spacing.md) {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text(title)
                        .font(isCompact ? .trainBodyMedium : .trainHeadline)  // Smaller font for compact mode
                        .foregroundColor(isSelected ? .white : .trainTextPrimary)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.trainBody)  // 16px Light from Figma
                            .foregroundColor(isSelected ? .white.opacity(0.9) : .trainTextSecondary)
                    }
                }

                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(isCompact ? Spacing.md : Spacing.lg)  // Smaller padding for compact
            .frame(height: isCompact ? ElementHeight.optionCardCompact : ElementHeight.optionCard)
            .background(
                Group {
                    if isSelected {
                        Color.trainPrimary
                    } else {
                        Color.clear
                    }
                }
            )
            .modifier(ConditionalGlassModifier(isSelected: isSelected))
            .overlay(alignment: .topTrailing) {
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .background(
                            Circle()
                                .fill(Color.trainPrimary)
                                .frame(width: 20, height: 20)
                        )
                        .offset(x: -8, y: 8)
                }
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }
}
