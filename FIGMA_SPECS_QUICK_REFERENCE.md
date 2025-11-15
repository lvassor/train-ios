# Figma Design Specs - Quick Reference

A quick reference guide for the design specifications extracted from Figma.

## 📐 Typography

```
Title (Questions)      → 24px, Medium (500)  → .trainTitle
Card Title            → 20px, Medium (500)  → .trainHeadline
Button Text           → 18px, Medium (500)  → .trainBodyMedium
Body Text             → 16px, Light (300)   → .trainBody
Subtitle              → 16px, Light (300)   → .trainSubtitle

Line Height: 1.08 (tight)
Font Family: Inter
```

## 📏 Spacing

```
Gap (Progress)        → 4px   → Spacing.xs
Internal Padding      → 8px   → Spacing.sm
Standard Spacing      → 16px  → Spacing.md
Card/Button Padding   → 24px  → Spacing.lg
Section Spacing       → 32px  → Spacing.xl
Major Breaks          → 48px  → Spacing.xxl
```

## 🔲 Element Heights

```
Button                → 50px  → ElementHeight.button
Option Card           → 80px  → ElementHeight.optionCard
Progress Bar          → 4px   → ElementHeight.progressBar
```

## ⚪ Corner Radius

```
Cards & Buttons       → 16px  → CornerRadius.md
Main Container        → 40px  → CornerRadius.xl
```

## 📱 Layout

```
Screen Width          → 393px → Layout.screenWidth
Content Width         → 340px → Layout.contentWidth
Horizontal Padding    → 20px  → Layout.horizontalPadding
```

## 🎨 Colors (from Figma)

**Note**: Colors can be customized in [ColorPalette.swift](trAInSwift/Components/ColorPalette.swift)

```
Progress Active       → #666666
Progress Inactive     → #E0E0E0
Card Border           → #000000 (Black)
Background (Figma)    → #FFFFFF (White)
```

## 🔧 Usage Examples

### Button
```swift
CustomButton(
    title: "Continue",
    action: { }
)
// Height: 50px
// Corner Radius: 16px
// Padding: 24px
// Font: 18px Medium
```

### Option Card
```swift
OptionCard(
    title: "Get Stronger",           // 20px Medium
    subtitle: "Build maximum strength", // 16px Light
    isSelected: false,
    action: { }
)
// Height: 80px
// Padding: 24px
// Border: 1px solid black
```

### Progress Bar
```swift
QuestionnaireProgressBar(
    currentStep: 3,
    totalSteps: 8
)
// Height: 4px
// Gap: 4px
// Shape: Capsule (rounded)
```

### Text Styles
```swift
Text("What are your primary goals?")
    .font(.trainTitle)              // 24px Medium

Text("Let's customise your training")
    .font(.trainSubtitle)           // 16px Light

Text("Get stronger")
    .font(.trainHeadline)           // 20px Medium
```

## 📋 Component Checklist

Use this when creating new components:

- [ ] Typography uses `.train*` fonts (not hardcoded sizes)
- [ ] Spacing uses `Spacing.*` constants
- [ ] Heights use `ElementHeight.*` constants
- [ ] Corner radius uses `CornerRadius.*` constants
- [ ] Colors use `ColorPalette` references (not hex values)
- [ ] Padding is 24px for cards/buttons (`Spacing.lg`)
- [ ] Cards have 1px black border when not selected

## 🎯 Key Differences from Previous Design

| Element | Before | After (Figma) |
|---------|--------|---------------|
| Button Height | 56px | **50px** |
| Card Height | Dynamic | **80px fixed** |
| Button Corner | 12px | **16px** |
| Card Padding | 16px | **24px** |
| Button Font | 16px Medium | **18px Medium** |
| Card Title | 16px Medium | **20px Medium** |
| Subtitle | 14px Regular | **16px Light** |
| Body Weight | Regular (400) | **Light (300)** |

## 💡 Tips

1. **Always use constants**, never hardcode values
2. **Colors are separate** - change only in ColorPalette.swift
3. **Figma uses tight line height** (1.08) - be mindful of text wrapping
4. **Content width is 340px** in 393px viewport (26.5px padding each side, but Figma uses 20px)
5. **Black borders** on unselected cards match Figma exactly

## 📱 Figma Viewport

```
Width:  393px (iPhone standard)
Height: 852px
Content: 340px wide (centered)
```

## 🔗 Related Files

- [Theme.swift](trAInSwift/Components/Theme.swift) - Typography, spacing, sizing
- [ColorPalette.swift](trAInSwift/Components/ColorPalette.swift) - All colors
- [DESIGN_SYSTEM.md](DESIGN_SYSTEM.md) - Full documentation
- [FIGMA_MIGRATION_SUMMARY.md](FIGMA_MIGRATION_SUMMARY.md) - What changed
