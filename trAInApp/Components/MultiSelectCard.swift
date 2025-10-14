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
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.trainBodyMedium)
                    .foregroundColor(isSelected ? .white : .trainTextPrimary)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.trainCaption)
                        .foregroundColor(isSelected ? .white.opacity(0.9) : .trainTextSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.md)
            .background(isSelected ? Color.trainPrimary : Color.white)
            .cornerRadius(CornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .stroke(isSelected ? Color.clear : Color.trainBorder, lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}
