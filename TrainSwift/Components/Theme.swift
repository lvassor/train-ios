//
//  Theme.swift
//  TrainSwift
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

    // Small text
    static let trainCaptionSmall = Font.system(size: 12, weight: .regular)    // Day labels, secondary counts
    static let trainTag = Font.system(size: 11, weight: .medium)              // Tags, badges
    static let trainMicro = Font.system(size: 10, weight: .regular)           // Micro labels

    // Special - rounded design for numbers
    static let trainLargeNumber = Font.system(size: 72, weight: .bold, design: .rounded)
    static let trainMediumNumber = Font.system(size: 48, weight: .semibold, design: .rounded)  // For stats
    static let trainSmallNumber = Font.system(size: 24, weight: .semibold, design: .rounded)   // For compact displays
    static let trainPickerNumber = Font.system(size: 56, weight: .bold, design: .rounded)      // Picker wheels
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
// Baseline values — used for VStack/HStack spacing: parameters and static contexts.
// These are the design-system foundation; views needing Dynamic Type scaling
// can use @ScaledMetric with these as default values.
struct Spacing {
    static let xxs: CGFloat = 2       // Ultra-tight pairs (stat value + unit)
    static let xs: CGFloat = 4        // Gap between progress segments, small gaps
    static let sm: CGFloat = 8        // Internal padding for compact elements
    static let smd: CGFloat = 12      // Compact lists, form field spacing
    static let md: CGFloat = 16       // Standard spacing between elements
    static let lg: CGFloat = 24       // Card padding, larger spacing
    static let xl: CGFloat = 32       // Section spacing
    static let xxl: CGFloat = 48      // Major section breaks
}

// MARK: - Corner Radius
// Fixed tokens — corner radii don't need to scale with Dynamic Type.
// Figma-confirmed: 8px thumbnails, 16px cards, 40px containers. No 10px exists.
struct CornerRadius {
    static let xxs: CGFloat = 4       // Progress bars, thin elements
    static let xs: CGFloat = 8        // Tags, badges, thumbnails
    static let sm: CGFloat = 12       // Small elements, filter chips
    static let md: CGFloat = 16       // Standard cards and buttons
    static let lg: CGFloat = 16       // Large cards — unified with md
    static let modal: CGFloat = 20    // Modals, success overlays
    static let pill: CGFloat = 30     // Fully-rounded pill buttons
    static let xl: CGFloat = 40       // Main container/screen

    // Continuous corner style for Apple aesthetic
    static let continuousStyle: RoundedCornerStyle = .continuous
}

// MARK: - Element Heights
// Baseline heights — use .frame(minHeight:) in views so content can grow with Dynamic Type.
// Use .frame(height:) only for decorative elements (progress bars).
struct ElementHeight {
    static let button: CGFloat = 50           // Standard button height
    static let optionCard: CGFloat = 80       // Option card height
    static let optionCardCompact: CGFloat = 56  // Compact option card for dense lists
    static let progressBar: CGFloat = 4       // Progress bar height (decorative — fixed)
    static let touchTarget: CGFloat = 44      // iOS HIG minimum touch target
    static let tabSelector: CGFloat = 40      // Tab/segment controls
    static let tabBar: CGFloat = 70           // Bottom navigation bar
    static let chart: CGFloat = 180           // Chart containers
}

// MARK: - Button Heights (kept for backward compatibility)
struct ButtonHeight {
    static let standard: CGFloat = ElementHeight.button  // 50 from Figma
    static let compact: CGFloat = 48
}

// MARK: - Layout
// Screen-edge constants. Content should use .frame(maxWidth: .infinity) + horizontal padding
// to adapt to any screen width — never hardcode content widths.
struct Layout {
    static let horizontalPadding: CGFloat = 20      // Screen-edge inset (safe across all iPhones)
}

// MARK: - Icon Sizes
struct IconSize {
    static let sm: CGFloat = 16       // Chevrons, tiny indicators
    static let md: CGFloat = 24       // Navigation/action icons
    static let lg: CGFloat = 32       // Option card icons
    static let xl: CGFloat = 48       // Feature icons, empty states
    static let xxl: CGFloat = 56      // Avatars (questionnaire goals)
    static let display: CGFloat = 80  // Celebration emojis, loading
}

// MARK: - Thumbnail Size
// Figma-confirmed: exercise video thumbnails at 80×64 rounded-8
struct ThumbnailSize {
    static let width: CGFloat = 80
    static let height: CGFloat = 64
    static let cornerRadius: CGFloat = CornerRadius.xs
}

// MARK: - Centralized App Gradient

/// Centralized gradient/background — colours resolve light/dark from Asset Catalog
struct AppGradient {
    static var stops: [Gradient.Stop] {
        [
            .init(color: .trainGradientLight, location: 0.0),
            .init(color: .trainGradientMid, location: 0.45),
            .init(color: .trainGradientDark, location: 1.0)
        ]
    }
    static var background: LinearGradient {
        LinearGradient(stops: stops, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    static var solid: Color { .trainGradientMid }
    static var simple: LinearGradient {
        LinearGradient(colors: [solid, solid], startPoint: .top, endPoint: .bottom)
    }
}

// MARK: - Background Gradients

extension View {
    /// Adaptive app background — gradient colours resolve from Asset Catalog
    /// Use ONLY for full-screen view backgrounds, NOT for scroll content or cards
    func charcoalGradientBackground() -> some View {
        ZStack {
            AppGradient.background
                .ignoresSafeArea()
            self
        }
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
    func warmGlassCard(cornerRadius: CGFloat = CornerRadius.md) -> some View {
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

    /// Semantic app card - uses environment-based card style
    /// Change style app-wide via .environment(\.cardStyle, .warm) in TrainSwiftApp.swift
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
