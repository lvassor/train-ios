//
//  Theme.swift
//  trAInApp
//
//  Design system for train. app
//

import SwiftUI

// MARK: - Color System
extension Color {
    // Primary Colors
    static let trainPrimary = Color(hex: "0F7A6B")
    static let trainLight = Color(hex: "72A99C")
    static let trainHover = Color(hex: "F0F9F7")

    // Backgrounds
    static let trainBackground = Color(hex: "F5F5F5")
    static let trainDark = Color(hex: "1A1A1A")

    // Text
    static let trainTextPrimary = Color(hex: "1A1A1A")
    static let trainTextSecondary = Color(hex: "6B6B6B")

    // UI Elements
    static let trainBorder = Color(hex: "E0E0E0")
    static let trainDisabled = Color(hex: "72A99C")
}

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
