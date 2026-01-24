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
// Apple-inspired glassmorphic design system with SF Pro Rounded
extension Font {
    // Headers - using SF Pro Rounded for softer, more approachable feel
    static let trainTitle = Font.system(size: 28, weight: .semibold, design: .rounded)        // Bumped for rounded design
    static let trainTitle2 = Font.system(size: 24, weight: .semibold, design: .rounded)       // Bumped weight for presence
    static let trainHeadline = Font.system(size: 20, weight: .semibold, design: .rounded)     // Semibold for headers

    // Body - default design for better readability
    static let trainSubtitle = Font.system(size: 16, weight: .regular)      // Regular for body text
    static let trainBody = Font.system(size: 16, weight: .regular)          // Regular for body text
    static let trainBodyMedium = Font.system(size: 18, weight: .medium, design: .rounded)   // Rounded for interactive elements
    static let trainCaption = Font.system(size: 14, weight: .regular)       // Slightly smaller caption
    static let trainCaptionLarge = Font.system(size: 15.5, weight: .regular)  // Larger caption for questionnaire descriptions

    // Special - rounded design for numbers
    static let trainLargeNumber = Font.system(size: 72, weight: .bold, design: .rounded)
    static let trainMediumNumber = Font.system(size: 48, weight: .semibold, design: .rounded)  // For stats
    static let trainSmallNumber = Font.system(size: 24, weight: .semibold, design: .rounded)   // For compact displays
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
// Apple glassmorphic design system - continuous curves
struct CornerRadius {
    static let sm: CGFloat = 12       // Small elements
    static let md: CGFloat = 16       // Standard cards and buttons
    static let lg: CGFloat = 16       // Large cards - unified to 16pt
    static let xl: CGFloat = 40       // Main container/screen (from Figma)

    // Continuous corner style for Apple aesthetic
    static let continuousStyle: RoundedCornerStyle = .continuous
}

// MARK: - Element Heights
// Based on Figma design system
struct ElementHeight {
    static let button: CGFloat = 50           // Standard button height (from Figma)
    static let optionCard: CGFloat = 80       // Option card height (from Figma)
    static let optionCardCompact: CGFloat = 56  // Compact option card for dense lists
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

// MARK: - Centralized App Gradient

/// Centralized gradient/background configuration - supports theme switching
struct AppGradient {
    /// The main app background stops based on theme
    static func stops(for theme: ThemeVariant) -> [Gradient.Stop] {
        switch theme {
        case .gold, .orange:
            // Dark mode: diagonal gradient with charcoal tones
            return [
                .init(color: .trainGradientLight(theme: theme), location: 0.0),
                .init(color: .trainGradientMid(theme: theme), location: 0.45),
                .init(color: .trainGradientDark(theme: theme), location: 1.0)
            ]
        case .light:
            // Light mode: Train Pearl diagonal gradient
            return [
                .init(color: .trainGradientLight(theme: theme), location: 0.0),
                .init(color: .trainGradientMid(theme: theme), location: 0.30),
                .init(color: .trainGradientDark(theme: theme), location: 1.0)
            ]
        }
    }

    /// The main app background gradient based on theme
    static func background(for theme: ThemeVariant) -> LinearGradient {
        LinearGradient(
            stops: stops(for: theme),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Solid color for sheets, toolbars, etc.
    static func solid(for theme: ThemeVariant) -> Color {
        .trainGradientMid(theme: theme)
    }

    /// Legacy compatibility - uses orange theme by default
    static var stops: [Gradient.Stop] { stops(for: .orange) }
    static var background: LinearGradient { background(for: .orange) }
    static var solid: Color { solid(for: .orange) }
    static var simple: LinearGradient {
        LinearGradient(
            colors: [solid(for: .orange), solid(for: .orange)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// MARK: - Background Gradients

extension View {
    /// Theme-aware app background - applies appropriate gradient based on theme
    /// Use ONLY for full-screen view backgrounds, NOT for scroll content or cards
    func appThemeBackground(theme: ThemeVariant) -> some View {
        ZStack {
            // Gradient MUST be the first layer to ensure it's always visible
            AppGradient.background(for: theme)
                .ignoresSafeArea()

            // Content on top of gradient
            self
        }
    }

    /// Main app background - applies charcoal gradient from ColorPalette (legacy)
    /// Use ONLY for full-screen view backgrounds, NOT for scroll content or cards
    func charcoalGradientBackground() -> some View {
        ZStack {
            // Gradient MUST be the first layer to ensure it's always visible
            AppGradient.background
                .ignoresSafeArea()

            // Content on top of gradient
            self
        }
    }

    /// Legacy alias - will be removed
    @available(*, deprecated, renamed: "charcoalGradientBackground")
    func warmDarkGradientBackground() -> some View {
        charcoalGradientBackground()
    }
}

// MARK: - Design System Configuration

/// Card style types for the design system
enum CardStyleType {
    case ultraThin  // Maximum transparency, no tint - pure frosted glass
    case warm       // Warm brown tint, atmospheric feel
}

// MARK: - Card Style Environment Key

struct CardStyleKey: EnvironmentKey {
    static let defaultValue: CardStyleType = .warm
}

extension EnvironmentValues {
    var cardStyle: CardStyleType {
        get { self[CardStyleKey.self] }
        set { self[CardStyleKey.self] = newValue }
    }
}

// MARK: - Glassmorphic Design System
// Apple-inspired material design with continuous corners and subtle shadows

extension View {
    /// Standard glassmorphic card with ultra-thin material background
    func glassCard(cornerRadius: CGFloat = CornerRadius.lg) -> some View {
        self
            .background(.regularMaterial)  // More opaque for better contrast on grey backgrounds
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: .black.opacity(0.08), radius: 20, x: 0, y: 10)
    }

    /// Neutral frosted glass card for Train Dark Mode
    /// Uses ultraThinMaterial for consistent blur across all card elements
    func warmGlassCard(cornerRadius: CGFloat = 16) -> some View {
        self
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.trainTextSecondary.opacity(0.3), lineWidth: 1)
            )
    }

    /// Premium glassmorphic card with thin material (more opacity)
    func glassPremiumCard(cornerRadius: CGFloat = CornerRadius.lg) -> some View {
        self
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: .black.opacity(0.1), radius: 24, x: 0, y: 12)
    }

    /// Compact glassmorphic card for smaller elements
    func glassCompactCard(cornerRadius: CGFloat = CornerRadius.md) -> some View {
        self
            .background(.regularMaterial)  // More opaque for better contrast
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 6)
    }

    /// Glassmorphic button style
    func glassButton(cornerRadius: CGFloat = CornerRadius.md) -> some View {
        self
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: .black.opacity(0.1), radius: 16, x: 0, y: 8)
    }

    /// Standard card padding for glassmorphic designs
    func glassCardPadding() -> some View {
        self.padding(Spacing.lg)  // 24pt generous padding
    }

    /// Compact card padding
    func glassCompactPadding() -> some View {
        self.padding(Spacing.md)  // 16pt standard padding
    }

    /// Accent glow effect for active/selected states
    func accentGlow(color: Color = .green, intensity: Double = 0.6) -> some View {
        self.shadow(color: color.opacity(intensity), radius: 16, x: 0, y: 0)
    }

    /// White card with subtle shadow - for workout logger and other white-on-grey contexts
    func whiteCard(cornerRadius: CGFloat = CornerRadius.lg) -> some View {
        self
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: .black.opacity(0.08), radius: 20, x: 0, y: 10)
    }

    /// Semantic app card - uses environment-based card style
    /// Change style app-wide via .environment(\.cardStyle, .warm) in trAInSwiftApp.swift
    /// Change style per-section by applying .environment(\.cardStyle, .ultraThin) to specific views
    func appCard(cornerRadius: CGFloat = CornerRadius.lg) -> some View {
        AppCardView(content: self, cornerRadius: cornerRadius)
    }
}

// MARK: - Helper Modifiers

/// Conditionally applies warm glass card effect based on selection state
struct ConditionalGlassModifier: ViewModifier {
    let isSelected: Bool

    func body(content: Content) -> some View {
        if isSelected {
            content
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous))
        } else {
            content
                .warmGlassCard(cornerRadius: CornerRadius.lg)
        }
    }
}

/// Environment-aware card view that switches style based on cardStyle environment value
struct AppCardView<Content: View>: View {
    @Environment(\.cardStyle) var style
    let content: Content
    let cornerRadius: CGFloat

    var body: some View {
        switch style {
        case .warm:
            content.warmGlassCard(cornerRadius: cornerRadius)
        case .ultraThin:
            content.glassCard(cornerRadius: cornerRadius)
        }
    }
}

// MARK: - Edge Fade Mask (Apple-style scroll fade)

extension View {
    /// Apple-style edge fade effect for scrollable content
    /// Creates a soft blur/fade at the top and bottom edges as content scrolls
    /// - Parameters:
    ///   - topFade: Height of the top fade gradient (default: 20)
    ///   - bottomFade: Height of the bottom fade gradient (default: 40)
    func edgeFadeMask(topFade: CGFloat = 20, bottomFade: CGFloat = 40) -> some View {
        self.mask(
            VStack(spacing: 0) {
                // Top fade: transparent to opaque
                LinearGradient(
                    colors: [.clear, .black],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: topFade)

                // Middle: fully opaque
                Rectangle()
                    .fill(Color.black)

                // Bottom fade: opaque to transparent
                LinearGradient(
                    colors: [.black, .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: bottomFade)
            }
        )
    }

    /// Scrollable content with Apple-style edge fading
    /// Wraps content in a ScrollView with edge fade mask applied
    func scrollableWithEdgeFade(
        _ axes: Axis.Set = .vertical,
        showsIndicators: Bool = true,
        topFade: CGFloat = 20,
        bottomFade: CGFloat = 40
    ) -> some View {
        ScrollView(axes, showsIndicators: showsIndicators) {
            self
        }
        .edgeFadeMask(topFade: topFade, bottomFade: bottomFade)
    }
}
