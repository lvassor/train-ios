//
//  OptionCard.swift
//  trAInApp
//
//  Single-select option card component
//

import SwiftUI

struct OptionCard: View {
    let title: String
    let subtitle: String?
    let icon: String?
    let isSelected: Bool
    let action: () -> Void

    init(title: String, subtitle: String? = nil, icon: String? = nil, isSelected: Bool, action: @escaping () -> Void) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.isSelected = isSelected
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(isSelected ? .white : .trainPrimary)
                        .frame(width: 32, height: 32)
                }

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

                Spacer()
            }
            .padding(Spacing.md)
            .frame(maxWidth: .infinity)
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

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
