//
//  MultiSelectCard.swift
//  trAInApp
//
//  Multi-select option card component
//

import SwiftUI

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
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(isCompact ? .trainBodyMedium : .trainHeadline)  // Smaller font for compact mode
                    .foregroundColor(isSelected ? .white : .trainTextPrimary)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.trainBody)  // 16px Light from Figma
                        .foregroundColor(isSelected ? .white.opacity(0.9) : .trainTextSecondary)
                }
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
        }
        .buttonStyle(ScaleButtonStyle())
    }
}
