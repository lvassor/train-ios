//
//  ColorPalette.swift
//  trAInSwift
//
//  Centralized color palette configuration
//  Change colors here to update the entire app theme
//

import SwiftUI

/// Main color palette configuration
/// Edit the hex values below to change the app's color scheme
struct ColorPalette {
    // MARK: - Primary Colors

    /// Main brand color - used for buttons, highlights, selected states
    static let primary = "#0F7A6B"

    /// Lighter version of primary - used for hover states
    static let primaryLight = "#72A99C"

    /// Very light primary tint - used for subtle backgrounds
    static let primaryHover = "#F0F9F7"

    // MARK: - Background Colors

    /// Main app background color
    static let background = "#F5F5F5"

    /// Dark background - used for dark mode or specific components
    static let dark = "#1A1A1A"

    // MARK: - Text Colors

    /// Primary text color - main headings and body text
    static let textPrimary = "#1A1A1A"

    /// Secondary text color - captions and less important text
    static let textSecondary = "#6B6B6B"

    // MARK: - UI Element Colors

    /// Border color for cards and inputs
    static let border = "#E0E0E0"

    /// Disabled state color
    static let disabled = "#72A99C"
}

// MARK: - Apply Palette to Theme

extension Color {
    // Primary Colors
    static let trainPrimary = Color(hex: ColorPalette.primary)
    static let trainLight = Color(hex: ColorPalette.primaryLight)
    static let trainHover = Color(hex: ColorPalette.primaryHover)

    // Backgrounds
    static let trainBackground = Color(hex: ColorPalette.background)
    static let trainDark = Color(hex: ColorPalette.dark)

    // Text
    static let trainTextPrimary = Color(hex: ColorPalette.textPrimary)
    static let trainTextSecondary = Color(hex: ColorPalette.textSecondary)

    // UI Elements
    static let trainBorder = Color(hex: ColorPalette.border)
    static let trainDisabled = Color(hex: ColorPalette.disabled)
}
