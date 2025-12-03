//
//  ButtonStyles.swift
//  trAInSwift
//
//  Reusable button styles to reduce code duplication
//

import SwiftUI

// MARK: - Selection Button Style

/// Style for selection buttons (used in questionnaire and multi-select cards)
/// Automatically handles selected/unselected states
struct SelectionButtonStyle: ButtonStyle {
    let isSelected: Bool
    let cornerRadius: CGFloat

    init(isSelected: Bool, cornerRadius: CGFloat = CornerRadius.md) {
        self.isSelected = isSelected
        self.cornerRadius = cornerRadius
    }

    func makeBody(configuration: Configuration) -> some View {
        Group {
            if isSelected {
                configuration.label
                    .padding(.vertical, Spacing.md)
                    .padding(.horizontal, Spacing.md)
                    .frame(maxWidth: .infinity)
                    .background(Color.trainPrimary)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            } else {
                configuration.label
                    .padding(.vertical, Spacing.md)
                    .padding(.horizontal, Spacing.md)
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.trainTextPrimary)
                    .appCard(cornerRadius: cornerRadius)
            }
        }
        .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// Note: ScaleButtonStyle already exists in OptionCard.swift

// MARK: - Primary Button Style

/// Primary action button style (filled with primary color)
struct PrimaryButtonStyle: ButtonStyle {
    let isEnabled: Bool

    init(isEnabled: Bool = true) {
        self.isEnabled = isEnabled
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.trainBodyMedium)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: ButtonHeight.standard)
            .background(isEnabled ? Color.trainPrimary : Color.trainTextSecondary)
            .cornerRadius(CornerRadius.md)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Secondary Button Style

/// Secondary action button style (outlined with glass effect)
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.trainBodyMedium)
            .foregroundColor(.trainPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: ButtonHeight.standard)
            .appCard(cornerRadius: CornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                    .stroke(Color.trainPrimary.opacity(0.6), lineWidth: 1.5)
            )
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - View Extensions

extension View {
    /// Apply selection button style
    func selectionButtonStyle(isSelected: Bool, cornerRadius: CGFloat = CornerRadius.md) -> some View {
        self.buttonStyle(SelectionButtonStyle(isSelected: isSelected, cornerRadius: cornerRadius))
    }

    // Note: scaleButtonStyle() extension already exists in OptionCard.swift

    /// Apply primary button style
    func primaryButtonStyle(isEnabled: Bool = true) -> some View {
        self.buttonStyle(PrimaryButtonStyle(isEnabled: isEnabled))
    }

    /// Apply secondary button style
    func secondaryButtonStyle() -> some View {
        self.buttonStyle(SecondaryButtonStyle())
    }
}
