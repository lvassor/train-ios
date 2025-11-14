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
extension Font {
    // Headers
    static let trainTitle = Font.system(size: 28, weight: .bold)
    static let trainTitle2 = Font.system(size: 24, weight: .bold)
    static let trainHeadline = Font.system(size: 20, weight: .semibold)

    // Body
    static let trainSubtitle = Font.system(size: 16, weight: .regular)
    static let trainBody = Font.system(size: 16, weight: .regular)
    static let trainBodyMedium = Font.system(size: 16, weight: .medium)
    static let trainCaption = Font.system(size: 14, weight: .regular)

    // Special
    static let trainLargeNumber = Font.system(size: 72, weight: .bold)
}

// MARK: - Spacing
struct Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

// MARK: - Corner Radius
struct CornerRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
}

// MARK: - Button Heights
struct ButtonHeight {
    static let standard: CGFloat = 56
    static let compact: CGFloat = 48
}
