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
        configuration.label
            .padding(.vertical, Spacing.md)
            .padding(.horizontal, Spacing.md)
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color.trainPrimary : Color.white)
            .foregroundColor(isSelected ? .white : .trainTextPrimary)
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(isSelected ? Color.clear : Color.trainBorder, lineWidth: isSelected ? 0 : 1)
            )
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

/// Secondary action button style (outlined)
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.trainBodyMedium)
            .foregroundColor(.trainPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: ButtonHeight.standard)
            .background(Color.white)
            .cornerRadius(CornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .stroke(Color.trainPrimary, lineWidth: 2)
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
