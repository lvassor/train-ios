//
//  ColorPalette.swift
//  trAInSwift
//
//  Centralized color palette configuration
//  Change colors here to update the entire app theme
//
//  THEME SWITCHING: To switch between gold and orange palettes,
//  change the `activeTheme` variable below. Options:
//  - .gold (original Train Dark Mode)
//  - .orange (new Train Dark Mode Orange)
//

import SwiftUI

/// Theme selection - change this to switch between palettes
enum ThemeVariant {
    case gold    // Original: #f1bc50 primary, #f5c4a1 secondary
    case orange  // New: #f0aa3e primary, #fce4be secondary
}

/// Active theme - CHANGE THIS TO SWITCH PALETTES
let activeTheme: ThemeVariant = .orange

/// Main color palette configuration
/// Train Dark Mode - clean, minimal dark mode with solid black background
/// Food-app inspired simplicity with warm gold/orange and peach accents against pure black
struct ColorPalette {
    // MARK: - Primary Colors (Accent)

    /// Main brand color - vibrant gold/orange for CTAs, stat values, active states
    static var primary: String {
        switch activeTheme {
        case .gold: return "#f1bc50"
        case .orange: return "#f0aa3e"
        }
    }

    /// Lighter version of primary - used for hover states
    static var primaryLight: String {
        switch activeTheme {
        case .gold: return "#F5CD73"
        case .orange: return "#f5c06a"
        }
    }

    /// Very light primary tint - used for subtle backgrounds
    static var primaryHover: String {
        switch activeTheme {
        case .gold: return "#F7D78F"
        case .orange: return "#f8d08c"
        }
    }

    // MARK: - Background Colors (Charcoal Gradient)

    /// Lightest point - medium gray (top-left region)
    static let gradientLight = "#5E5E5E"

    /// Midpoint - very dark gray
    static let gradientMid = "#101010"

    /// Darkest point - near black (bottom-right region)
    static let gradientDark = "#0B0B0B"

    /// Legacy alias for edge (uses dark corner)
    static let gradientEdge = "#0B0B0B"

    /// Legacy alias for center (uses midpoint)
    static let gradientCenter = "#101010"

    /// Main background - dark charcoal
    static let background = "#101010"

    /// Dark background - near black
    static let dark = "#0B0B0B"

    /// Elevated surface color - slightly lighter for cards if needed
    static let surface = "#141414"

    // MARK: - Text Colors

    /// Primary text color - pure white for titles, exercise names, weights
    static let textPrimary = "#FFFFFF"

    /// Secondary text color - soft peach/cream for labels, dates, section headers
    static var textSecondary: String {
        switch activeTheme {
        case .gold: return "#f5c4a1"
        case .orange: return "#fce4be"
        }
    }

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
    static let trainGradientLight = Color(hex: ColorPalette.gradientLight)
    static let trainGradientMid = Color(hex: ColorPalette.gradientMid)
    static let trainGradientDark = Color(hex: ColorPalette.gradientDark)
    static let trainGradientEdge = Color(hex: ColorPalette.gradientEdge)
    static let trainGradientCenter = Color(hex: ColorPalette.gradientCenter)

    // Text
    static let trainTextPrimary = Color(hex: ColorPalette.textPrimary)
    static let trainTextSecondary = Color(hex: ColorPalette.textSecondary)

    // Secondary accent color (alias for text secondary)
    static let trainSecondary = Color(hex: ColorPalette.textSecondary)

    // UI Elements
    static let trainBorder = Color(hex: ColorPalette.border)
    static let trainDisabled = Color(hex: ColorPalette.disabled)
    static let trainMutedFill = Color(hex: ColorPalette.mutedFill)
    static let trainTimelineLine = Color(hex: ColorPalette.timelineLine)
}
