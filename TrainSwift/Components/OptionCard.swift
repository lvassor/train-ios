//
//  OptionCard.swift
//  TrainSwift
//
//  Single-select option card component
//

import SwiftUI

struct OptionCard: View {
    let title: String
    let subtitle: String?
    let icon: String?
    let isSelected: Bool
    var useAutoHeight: Bool = false  // When true, auto-fills height based on content
    var subtitleFont: Font = .trainBody  // Customizable subtitle font
    let action: () -> Void

    init(title: String, subtitle: String? = nil, icon: String? = nil, isSelected: Bool, useAutoHeight: Bool = false, subtitleFont: Font = .trainBody, action: @escaping () -> Void) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.isSelected = isSelected
        self.useAutoHeight = useAutoHeight
        self.subtitleFont = subtitleFont
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(isSelected ? .white : .trainPrimary)
                        .frame(width: IconSize.lg, height: IconSize.lg)
                }

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(title)
                        .font(.trainHeadline)  // 20px Medium from Figma
                        .foregroundColor(isSelected ? .white : .trainTextPrimary)
                        .lineLimit(1)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(subtitleFont)
                            .foregroundColor(isSelected ? .white.opacity(0.9) : .trainTextSecondary)
                            .lineLimit(useAutoHeight ? nil : 2)  // Allow full text when auto height
                            .fixedSize(horizontal: false, vertical: useAutoHeight)
                    }
                }

                Spacer()
            }
            .padding(Spacing.md)
            .frame(maxWidth: .infinity)
            .frame(minHeight: useAutoHeight ? nil : ElementHeight.optionCard)  // Use minHeight for auto-height mode
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

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
