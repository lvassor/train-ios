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

/// Theme selection - includes both dark and light mode variants
enum ThemeVariant {
    case gold    // Original: #f1bc50 primary, #f5c4a1 secondary
    case orange  // New: #f0aa3e primary, #fce4be secondary
    case light   // Train Pearl light mode
}

/// Theme mode selection
enum AppThemeMode {
    case dark
    case light
}

/// Theme Manager for handling app-wide theme state
class ThemeManager: ObservableObject {
    @Published var currentMode: AppThemeMode

    init() {
        // Check for saved preference, default to dark mode
        let savedMode = UserDefaults.standard.string(forKey: "AppThemeMode")
        self.currentMode = savedMode == "light" ? .light : .dark
    }

    func setTheme(_ mode: AppThemeMode) {
        currentMode = mode
        UserDefaults.standard.set(mode == .light ? "light" : "dark", forKey: "AppThemeMode")
    }

    var activeTheme: ThemeVariant {
        switch currentMode {
        case .dark: return .orange  // Keep existing orange theme for dark mode
        case .light: return .light  // Use new Train Pearl theme for light mode
        }
    }
}

/// Main color palette configuration
/// Supports both Train Dark Mode and Train Pearl Light Mode
struct ColorPalette {
    // MARK: - Primary Colors (Accent)

    /// Main brand color - vibrant gold/orange for CTAs, stat values, active states
    static func primary(for theme: ThemeVariant) -> String {
        switch theme {
        case .gold: return "#f1bc50"
        case .orange: return "#f0aa3e"
        case .light: return "#C4820E"  // Train Pearl primary accent (4.7:1 contrast on white)
        }
    }

    /// Lighter version of primary - used for hover states
    static func primaryLight(for theme: ThemeVariant) -> String {
        switch theme {
        case .gold: return "#F5CD73"
        case .orange: return "#f5c06a"
        case .light: return "#D6941A"  // Lighter version of Train Pearl primary
        }
    }

    /// Very light primary tint - used for subtle backgrounds
    static func primaryHover(for theme: ThemeVariant) -> String {
        switch theme {
        case .gold: return "#F7D78F"
        case .orange: return "#f8d08c"
        case .light: return "#E8A52B"  // Even lighter for hover states
        }
    }

    // MARK: - Background Colors

    /// Background gradient colors based on theme
    static func gradientLight(for theme: ThemeVariant) -> String {
        switch theme {
        case .gold, .orange: return "#5E5E5E"  // Dark mode: medium gray
        case .light: return "#FBF7F2"  // Train Pearl: 0% gradient stop
        }
    }

    static func gradientMid(for theme: ThemeVariant) -> String {
        switch theme {
        case .gold, .orange: return "#101010"  // Dark mode: very dark gray
        case .light: return "#FEFEFE"  // Train Pearl: 30% gradient stop
        }
    }

    static func gradientDark(for theme: ThemeVariant) -> String {
        switch theme {
        case .gold, .orange: return "#0B0B0B"  // Dark mode: near black
        case .light: return "#FFFFFF"  // Train Pearl: 100% gradient stop
        }
    }

    /// Main background color
    static func background(for theme: ThemeVariant) -> String {
        switch theme {
        case .gold, .orange: return "#101010"  // Dark mode: dark charcoal
        case .light: return "#FFFFFF"  // Train Pearl: pure white
        }
    }

    /// Dark background variant
    static func dark(for theme: ThemeVariant) -> String {
        switch theme {
        case .gold, .orange: return "#0B0B0B"  // Dark mode: near black
        case .light: return "#F0EDE8"  // Train Pearl: subtle border color
        }
    }

    /// Elevated surface color for cards
    static func surface(for theme: ThemeVariant) -> String {
        switch theme {
        case .gold, .orange: return "#141414"  // Dark mode: slightly lighter
        case .light: return "#FEFEFE"  // Train Pearl: very light background
        }
    }

    // MARK: - Text Colors

    /// Primary text color
    static func textPrimary(for theme: ThemeVariant) -> String {
        switch theme {
        case .gold, .orange: return "#FFFFFF"  // Dark mode: pure white
        case .light: return "#1C1917"  // Train Pearl: primary text
        }
    }

    /// Secondary text color
    static func textSecondary(for theme: ThemeVariant) -> String {
        switch theme {
        case .gold: return "#f5c4a1"  // Dark mode: soft peach
        case .orange: return "#fce4be"  // Dark mode: soft cream
        case .light: return "#57534E"  // Train Pearl: secondary text
        }
    }

    /// Muted text color
    static func textMuted(for theme: ThemeVariant) -> String {
        switch theme {
        case .gold, .orange: return "#A8A8A8"  // Dark mode: neutral gray
        case .light: return "#A8A29E"  // Train Pearl: muted text
        }
    }

    // MARK: - UI Element Colors

    /// Border colors based on theme
    static func borderSubtle(for theme: ThemeVariant) -> String {
        switch theme {
        case .gold, .orange: return "#FFFFFF"  // Dark mode: white border
        case .light: return "#F0EDE8"  // Train Pearl: subtle border
        }
    }

    static func borderDefault(for theme: ThemeVariant) -> String {
        switch theme {
        case .gold, .orange: return "#FFFFFF"  // Dark mode: white border
        case .light: return "#E7E5E0"  // Train Pearl: default border
        }
    }

    static func borderStrong(for theme: ThemeVariant) -> String {
        switch theme {
        case .gold, .orange: return "#FFFFFF"  // Dark mode: white border
        case .light: return "#D6D3CE"  // Train Pearl: strong border
        }
    }

    /// Timeline/divider line color
    static func timelineLine(for theme: ThemeVariant) -> String {
        switch theme {
        case .gold, .orange: return "#333333"  // Dark mode: subtle white
        case .light: return "#E7E5E0"  // Train Pearl: default border
        }
    }

    /// Disabled state color
    static func disabled(for theme: ThemeVariant) -> String {
        switch theme {
        case .gold, .orange: return "#A8A8A8"  // Dark mode: neutral gray
        case .light: return "#A8A29E"  // Train Pearl: muted color
        }
    }
}

// MARK: - Apply Palette to Theme

/// Theme-aware color extensions - requires ThemeManager in environment
extension Color {
    // Primary Colors
    static func trainPrimary(theme: ThemeVariant) -> Color {
        Color(hex: ColorPalette.primary(for: theme))
    }
    static func trainLight(theme: ThemeVariant) -> Color {
        Color(hex: ColorPalette.primaryLight(for: theme))
    }
    static func trainHover(theme: ThemeVariant) -> Color {
        Color(hex: ColorPalette.primaryHover(for: theme))
    }

    // Backgrounds
    static func trainBackground(theme: ThemeVariant) -> Color {
        Color(hex: ColorPalette.background(for: theme))
    }
    static func trainDark(theme: ThemeVariant) -> Color {
        Color(hex: ColorPalette.dark(for: theme))
    }
    static func trainSurface(theme: ThemeVariant) -> Color {
        Color(hex: ColorPalette.surface(for: theme))
    }

    // Gradient Colors
    static func trainGradientLight(theme: ThemeVariant) -> Color {
        Color(hex: ColorPalette.gradientLight(for: theme))
    }
    static func trainGradientMid(theme: ThemeVariant) -> Color {
        Color(hex: ColorPalette.gradientMid(for: theme))
    }
    static func trainGradientDark(theme: ThemeVariant) -> Color {
        Color(hex: ColorPalette.gradientDark(for: theme))
    }

    // Text
    static func trainTextPrimary(theme: ThemeVariant) -> Color {
        Color(hex: ColorPalette.textPrimary(for: theme))
    }
    static func trainTextSecondary(theme: ThemeVariant) -> Color {
        Color(hex: ColorPalette.textSecondary(for: theme))
    }
    static func trainTextMuted(theme: ThemeVariant) -> Color {
        Color(hex: ColorPalette.textMuted(for: theme))
    }

    // UI Elements
    static func trainBorderSubtle(theme: ThemeVariant) -> Color {
        Color(hex: ColorPalette.borderSubtle(for: theme))
    }
    static func trainBorderDefault(theme: ThemeVariant) -> Color {
        Color(hex: ColorPalette.borderDefault(for: theme))
    }
    static func trainBorderStrong(theme: ThemeVariant) -> Color {
        Color(hex: ColorPalette.borderStrong(for: theme))
    }
    static func trainDisabled(theme: ThemeVariant) -> Color {
        Color(hex: ColorPalette.disabled(for: theme))
    }
    static func trainTimelineLine(theme: ThemeVariant) -> Color {
        Color(hex: ColorPalette.timelineLine(for: theme))
    }
}

// MARK: - Legacy Compatibility (backwards compatible with existing code)
extension Color {
    // These provide backwards compatibility with existing code
    static let trainPrimary = Color.trainPrimary(theme: .orange)
    static let trainLight = Color.trainLight(theme: .orange)
    static let trainHover = Color.trainHover(theme: .orange)
    static let trainBackground = Color.trainBackground(theme: .orange)
    static let trainDark = Color.trainDark(theme: .orange)
    static let trainGradientLight = Color.trainGradientLight(theme: .orange)
    static let trainGradientMid = Color.trainGradientMid(theme: .orange)
    static let trainGradientDark = Color.trainGradientDark(theme: .orange)
    static let trainGradientEdge = Color.trainGradientDark(theme: .orange)  // Legacy alias
    static let trainGradientCenter = Color.trainGradientMid(theme: .orange)  // Legacy alias
    static let trainTextPrimary = Color.trainTextPrimary(theme: .orange)
    static let trainTextSecondary = Color.trainTextSecondary(theme: .orange)
    static let trainBorder = Color.trainBorderDefault(theme: .orange)
    static let trainDisabled = Color.trainDisabled(theme: .orange)
    static let trainMutedFill = Color.trainDisabled(theme: .orange)  // Legacy alias
    static let trainTimelineLine = Color.trainTimelineLine(theme: .orange)
}
