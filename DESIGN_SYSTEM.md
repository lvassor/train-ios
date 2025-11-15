# trAIn iOS Design System

This document outlines the design system extracted from Figma and implemented in Swift/SwiftUI.

## Overview

The design system is color-agnostic for easy theme changes. All colors are defined in `ColorPalette.swift`, while sizing, typography, and spacing are defined in `Theme.swift`.

## Typography

Based on the Inter font family from Figma designs.

### Font Sizes & Weights

| Element | Size | Weight | SwiftUI Font |
|---------|------|--------|--------------|
| Main Title | 24px | Medium (500) | `.trainTitle` |
| Section Title | 24px | Medium (500) | `.trainTitle2` |
| Card Title | 20px | Medium (500) | `.trainHeadline` |
| Body Text | 16px | Light (300) | `.trainBody` |
| Subtitle | 16px | Light (300) | `.trainSubtitle` |
| Button Text | 18px | Medium (500) | `.trainBodyMedium` |
| Caption | 16px | Light (300) | `.trainCaption` |

### Line Height

Figma uses `line-height: 1.08` consistently across all text elements (very tight line spacing).

## Spacing

| Name | Value | Usage |
|------|-------|-------|
| `Spacing.xs` | 4px | Gap between progress bar segments, minimal spacing |
| `Spacing.sm` | 8px | Internal padding for compact elements |
| `Spacing.md` | 16px | Standard spacing between elements |
| `Spacing.lg` | 24px | Card padding, button padding |
| `Spacing.xl` | 32px | Section spacing |
| `Spacing.xxl` | 48px | Major section breaks |

## Corner Radius

| Name | Value | Usage |
|------|-------|-------|
| `CornerRadius.sm` | 8px | Small elements |
| `CornerRadius.md` | 16px | Cards, buttons (standard) |
| `CornerRadius.lg` | 16px | Same as md for consistency |
| `CornerRadius.xl` | 40px | Main screen container |

## Element Heights

| Element | Height | Constant |
|---------|--------|----------|
| Button | 50px | `ElementHeight.button` |
| Option Card | 80px | `ElementHeight.optionCard` |
| Progress Bar | 4px | `ElementHeight.progressBar` |

## Layout

Based on 393px viewport width (iPhone standard).

| Property | Value | Usage |
|----------|-------|-------|
| Screen Width | 393px | Figma viewport |
| Content Width | 340px | Standard content container |
| Horizontal Padding | 20px | Side margins |

## Components

### Button (CustomButton)

- Height: 50px
- Corner Radius: 16px
- Padding: 24px
- Font: 18px Medium
- Background: Color-agnostic (uses `ColorPalette`)

### Option Card (OptionCard)

- Height: 80px
- Corner Radius: 16px
- Padding: 24px
- Title Font: 20px Medium
- Subtitle Font: 16px Light
- Border: 1px solid black (when not selected)
- Background: White/Color-agnostic selected state

### Progress Bar (QuestionnaireProgressBar)

- Height: 4px
- Gap: 4px between segments
- Shape: Capsule (rounded)
- Active Color: #666666 (from Figma, can be customized in ColorPalette)
- Inactive Color: #E0E0E0 (from Figma)

## Color System

Colors are centralized in [ColorPalette.swift](trAInSwift/Components/ColorPalette.swift) for easy theme changes.

### Current Color Palette

Edit these hex values in `ColorPalette.swift` to change the app theme:

```swift
struct ColorPalette {
    static let primary = "#0F7A6B"           // Main brand color
    static let primaryLight = "#72A99C"      // Lighter tint
    static let primaryHover = "#F0F9F7"      // Very light tint
    static let background = "#F5F5F5"        // App background
    static let dark = "#1A1A1A"              // Dark backgrounds
    static let textPrimary = "#1A1A1A"       // Main text
    static let textSecondary = "#6B6B6B"     // Secondary text
    static let border = "#E0E0E0"            // Borders
    static let disabled = "#72A99C"          // Disabled states
}
```

### Usage in Code

Always use the semantic color names, never hardcode colors:

```swift
.foregroundColor(.trainTextPrimary)  // ✅ Good
.foregroundColor(Color(hex: "#1A1A1A"))  // ❌ Bad
```

## Figma Reference

The design specifications are based on the exported Figma designs located at:
`~/Users/lukevassor/Downloads/Splash Page Design/src`

### Key Figma Specs

- Viewport: 393 x 852 px
- Container width: 340px
- Main container border radius: 40px
- Card border radius: 16px
- Font family: Inter (Light 300, Medium 500)
- Progress bar segments: 4px tall with 4px gaps

## Implementation Notes

1. **Color Independence**: All sizing, spacing, and typography are independent of colors. Change colors only in `ColorPalette.swift`.

2. **Consistency**: Use the provided constants (`Spacing.*`, `CornerRadius.*`, `ElementHeight.*`) rather than hardcoded values.

3. **Typography**: Use the semantic font names (`.trainTitle`, `.trainBody`, etc.) for consistency.

4. **Responsive**: While based on 393px viewport, components use relative sizing where appropriate.

## Migration Guide

If updating existing views to match Figma designs:

1. Replace hardcoded font sizes with semantic fonts (`.trainTitle`, `.trainBody`, etc.)
2. Replace hardcoded spacing with `Spacing.*` constants
3. Replace hardcoded corner radii with `CornerRadius.*` constants
4. Use `ElementHeight.*` for component heights
5. Ensure colors use `ColorPalette` references, not hardcoded hex values

## Examples

### Good Practice

```swift
VStack(spacing: Spacing.lg) {
    Text("Welcome")
        .font(.trainTitle)
        .foregroundColor(.trainTextPrimary)

    CustomButton(
        title: "Get Started",
        action: { }
    )
    .padding(.horizontal, Layout.horizontalPadding)
}
```

### Bad Practice

```swift
VStack(spacing: 24) {  // ❌ Hardcoded
    Text("Welcome")
        .font(.system(size: 28, weight: .bold))  // ❌ Hardcoded
        .foregroundColor(Color(hex: "#1A1A1A"))  // ❌ Hardcoded color

    Button(action: {}) {
        Text("Get Started")
    }
    .frame(height: 56)  // ❌ Hardcoded height
    .padding(.horizontal, 20)  // ❌ Should use Layout.horizontalPadding
}
```
