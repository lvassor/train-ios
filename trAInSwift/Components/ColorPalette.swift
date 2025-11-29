//
//  ColorPalette.swift
//  trAInSwift
//
//  Centralized color palette configuration
//  Change colors here to update the entire app theme
//

import SwiftUI

/// Main color palette configuration
/// Warm dark theme with orange accents inspired by "Wisdom Takes Work" UI
struct ColorPalette {
    // MARK: - Primary Colors

    /// Main brand color - vibrant orange for buttons, highlights, selected states
    static let primary = "#FF7A00"

    /// Lighter version of primary - used for hover states
    static let primaryLight = "#FF9433"

    /// Very light primary tint - used for subtle backgrounds
    static let primaryHover = "#FFA94D"

    // MARK: - Background Colors (Warm Dark Gradient)

    /// Gradient top - warm dark brown
    static let backgroundGradientTop = "#3D2A1A"

    /// Gradient bottom - near-black with warm undertone
    static let backgroundGradientBottom = "#1A1410"

    /// Legacy background (deprecated - use gradient instead)
    static let background = "#1A1410"

    /// Dark background - warm near-black
    static let dark = "#1A1410"

    // MARK: - Text Colors (for dark mode)

    /// Primary text color - white for dark backgrounds
    static let textPrimary = "#FFFFFF"

    /// Secondary text color - muted warm gray
    static let textSecondary = "#8A8078"

    // MARK: - UI Element Colors

    /// Border color for glass cards - subtle white
    static let border = "#FFFFFF"

    /// Muted circle fill - warm gray with opacity
    static let mutedFill = "#4A4540"

    /// Timeline line color - muted warm gray
    static let timelineLine = "#3A3530"

    /// Disabled state color
    static let disabled = "#8A8078"
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
    static let trainGradientTop = Color(hex: ColorPalette.backgroundGradientTop)
    static let trainGradientBottom = Color(hex: ColorPalette.backgroundGradientBottom)

    // Text
    static let trainTextPrimary = Color(hex: ColorPalette.textPrimary)
    static let trainTextSecondary = Color(hex: ColorPalette.textSecondary)

    // UI Elements
    static let trainBorder = Color(hex: ColorPalette.border)
    static let trainDisabled = Color(hex: ColorPalette.disabled)
    static let trainMutedFill = Color(hex: ColorPalette.mutedFill)
    static let trainTimelineLine = Color(hex: ColorPalette.timelineLine)
}
