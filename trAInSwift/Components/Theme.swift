//
//  Theme.swift
//  trAInApp
//
//  Design system for train. app
//

import SwiftUI

// MARK: - Color Hex Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Color System
// NOTE: Colors are now defined in ColorPalette.swift for easy theme changes
// The Color extensions are applied there automatically

// MARK: - Typography
// Based on Figma design system - uses Inter font family
extension Font {
    // Headers - using Figma specs
    static let trainTitle = Font.system(size: 24, weight: .medium)        // 24px, Medium (500)
    static let trainTitle2 = Font.system(size: 24, weight: .medium)       // 24px, Medium (500)
    static let trainHeadline = Font.system(size: 20, weight: .medium)     // 20px, Medium (500)

    // Body - using Figma specs
    static let trainSubtitle = Font.system(size: 16, weight: .light)      // 16px, Light (300)
    static let trainBody = Font.system(size: 16, weight: .light)          // 16px, Light (300)
    static let trainBodyMedium = Font.system(size: 18, weight: .medium)   // 18px, Medium (500) for buttons
    static let trainCaption = Font.system(size: 16, weight: .light)       // 16px, Light (300)

    // Special
    static let trainLargeNumber = Font.system(size: 72, weight: .bold)
}

// MARK: - Line Height
// Figma uses line-height: 1.08 across the board
extension Text {
    func figmaLineHeight() -> some View {
        self.lineSpacing(0)  // 1.08 line height is very tight
            .minimumScaleFactor(0.9)
    }
}

// MARK: - Spacing
// Based on Figma design system
struct Spacing {
    static let xs: CGFloat = 4        // Gap between progress segments, small gaps
    static let sm: CGFloat = 8        // Internal padding for compact elements
    static let md: CGFloat = 16       // Standard spacing between elements
    static let lg: CGFloat = 24       // Card padding, larger spacing
    static let xl: CGFloat = 32       // Section spacing
    static let xxl: CGFloat = 48      // Major section breaks
}

// MARK: - Corner Radius
// Based on Figma design system
struct CornerRadius {
    static let sm: CGFloat = 8        // Small elements
    static let md: CGFloat = 16       // Standard cards and buttons (from Figma)
    static let lg: CGFloat = 16       // Same as md for consistency
    static let xl: CGFloat = 40       // Main container/screen (from Figma)
}

// MARK: - Element Heights
// Based on Figma design system
struct ElementHeight {
    static let button: CGFloat = 50           // Standard button height (from Figma)
    static let optionCard: CGFloat = 80       // Option card height (from Figma)
    static let progressBar: CGFloat = 4       // Progress bar height (from Figma)
}

// MARK: - Button Heights (kept for backward compatibility)
struct ButtonHeight {
    static let standard: CGFloat = ElementHeight.button  // 50 from Figma
    static let compact: CGFloat = 48
}

// MARK: - Layout
// Based on Figma design system (393px viewport)
struct Layout {
    static let screenWidth: CGFloat = 393           // Figma viewport width
    static let contentWidth: CGFloat = 340          // Standard content width from Figma
    static let horizontalPadding: CGFloat = 20      // Side padding: (393-340)/2 ≈ 26.5, but Figma uses 20
}
