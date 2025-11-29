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

                Spacer()
            }
            .padding(Spacing.lg)  // 24px padding from Figma
            .frame(maxWidth: .infinity)
            .frame(height: ElementHeight.optionCard)  // 80px from Figma
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
            .shadow(color: isSelected ? Color.trainPrimary.opacity(0.4) : .clear, radius: 16, x: 0, y: 0)
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
