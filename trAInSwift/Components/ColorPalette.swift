//
//  ColorPalette.swift
//  trAInSwift
//
//  Centralized color palette configuration
//  Change colors here to update the entire app theme
//

import SwiftUI

/// Main color palette configuration
/// Train Dark Mode - clean, minimal dark mode with solid black background
/// Food-app inspired simplicity with warm gold and peach accents against pure black
struct ColorPalette {
    // MARK: - Primary Colors (Gold Accent)

    /// Main brand color - vibrant gold for CTAs, stat values, active states
    static let primary = "#f1bc50"

    /// Lighter version of primary - used for hover states
    static let primaryLight = "#F5CD73"

    /// Very light primary tint - used for subtle backgrounds
    static let primaryHover = "#F7D78F"

    // MARK: - Background Colors (Solid Black)

    /// Solid black background - no gradient
    static let gradientEdge = "#0a0a0a"

    /// Same as edge - solid color throughout
    static let gradientMid = "#0a0a0a"

    /// Same as edge - solid color throughout
    static let gradientCenter = "#0a0a0a"

    /// Main background - pure black
    static let background = "#0a0a0a"

    /// Dark background - pure black
    static let dark = "#0a0a0a"

    /// Elevated surface color - slightly lighter for cards if needed
    static let surface = "#141414"

    // MARK: - Text Colors

    /// Primary text color - pure white for titles, exercise names, weights
    static let textPrimary = "#FFFFFF"

    /// Secondary text color - soft peach for labels, dates, section headers
    static let textSecondary = "#f5c4a1"

    // MARK: - UI Element Colors

    /// Border color for glass cards - subtle white at 10% opacity
    static let border = "#FFFFFF"

    /// Muted circle fill - neutral gray
    static let mutedFill = "#A8A8A8"

    /// Timeline/divider line color - subtle white
    static let timelineLine = "#333333"

    /// Disabled state color - neutral gray
    static let disabled = "#A8A8A8"
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

    // Gradient Colors
    static let trainGradientEdge = Color(hex: ColorPalette.gradientEdge)
    static let trainGradientMid = Color(hex: ColorPalette.gradientMid)
    static let trainGradientCenter = Color(hex: ColorPalette.gradientCenter)

    // Text
    static let trainTextPrimary = Color(hex: ColorPalette.textPrimary)
    static let trainTextSecondary = Color(hex: ColorPalette.textSecondary)

    // UI Elements
    static let trainBorder = Color(hex: ColorPalette.border)
    static let trainDisabled = Color(hex: ColorPalette.disabled)
    static let trainMutedFill = Color(hex: ColorPalette.mutedFill)
    static let trainTimelineLine = Color(hex: ColorPalette.timelineLine)
}
