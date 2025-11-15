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

    @State private var isHovered = false

    init(title: String, subtitle: String? = nil, isSelected: Bool, action: @escaping () -> Void) {
        self.title = title
        self.subtitle = subtitle
        self.isSelected = isSelected
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.trainHeadline)  // 20px Medium from Figma
                    .foregroundColor(isSelected ? .white : .trainTextPrimary)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.trainBody)  // 16px Light from Figma
                        .foregroundColor(isSelected ? .white.opacity(0.9) : .trainTextSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.lg)  // 24px padding from Figma
            .frame(height: ElementHeight.optionCard)  // 80px from Figma
            .background(isSelected ? Color.trainPrimary : Color.white)
            .cornerRadius(CornerRadius.md)  // 16px from Figma
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .stroke(isSelected ? Color.clear : Color.black, lineWidth: 1)  // Black border from Figma
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}
