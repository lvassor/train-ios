# Design System - Code Examples

Practical examples showing how to use the Figma-based design system in your Swift code.

## ✅ Good Practices

### Example 1: Questionnaire Step View

```swift
import SwiftUI

struct MyQuestionView: View {
    @Binding var selectedOption: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            // Header section
            VStack(alignment: .center, spacing: Spacing.sm) {
                Text("What are your primary goals?")
                    .font(.trainTitle)  // 24px Medium
                    .foregroundColor(.trainTextPrimary)

                Text("Let's customise your training programme")
                    .font(.trainSubtitle)  // 16px Light
                    .foregroundColor(.trainTextSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)

            // Options
            VStack(spacing: Spacing.md) {
                OptionCard(
                    title: "Get Stronger",
                    subtitle: "Build maximum strength and power",
                    isSelected: selectedOption == "strength",
                    action: { selectedOption = "strength" }
                )

                OptionCard(
                    title: "Build Muscle Mass",
                    subtitle: "Both size and definition",
                    isSelected: selectedOption == "muscle",
                    action: { selectedOption = "muscle" }
                )
            }

            Spacer()

            // Continue button
            CustomButton(
                title: "Continue",
                action: { /* next step */ },
                isEnabled: !selectedOption.isEmpty
            )
            .padding(.horizontal, Layout.horizontalPadding)
        }
        .padding(Spacing.lg)
        .background(Color.trainBackground)
    }
}
```

### Example 2: Custom Button with Figma Specs

```swift
import SwiftUI

struct MyCustomButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.trainBodyMedium)  // 18px Medium from Figma ✅
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: ElementHeight.button)  // 50px from Figma ✅
                .background(Color.trainPrimary)
                .cornerRadius(CornerRadius.md)  // 16px from Figma ✅
        }
        .padding(.horizontal, Layout.horizontalPadding)  // 20px ✅
    }
}
```

### Example 3: Progress Bar Header

```swift
import SwiftUI

struct QuestionnaireHeader: View {
    let currentStep: Int
    let totalSteps: Int
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: Spacing.md) {
            // Back button
            HStack {
                Button(action: onBack) {
                    Image(systemName: "arrow.left")
                        .font(.title3)
                        .foregroundColor(.trainTextPrimary)
                }
                Spacer()
            }
            .padding(.horizontal, Layout.horizontalPadding)

            // Progress bar
            QuestionnaireProgressBar(
                currentStep: currentStep,
                totalSteps: totalSteps
            )
            .padding(.horizontal, Layout.horizontalPadding)
        }
        .padding(.top, Spacing.md)
    }
}
```

### Example 4: Multi-Select Options

```swift
import SwiftUI

struct EquipmentSelectionView: View {
    @Binding var selectedEquipment: Set<String>

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            // Title
            Text("What equipment do you have?")
                .font(.trainTitle)  // 24px Medium ✅
                .foregroundColor(.trainTextPrimary)

            // Subtitle
            Text("Select all that apply")
                .font(.trainSubtitle)  // 16px Light ✅
                .foregroundColor(.trainTextSecondary)

            // Options grid
            VStack(spacing: Spacing.md) {
                ForEach(equipmentOptions, id: \.self) { option in
                    MultiSelectCard(
                        title: option,
                        isSelected: selectedEquipment.contains(option),
                        action: {
                            if selectedEquipment.contains(option) {
                                selectedEquipment.remove(option)
                            } else {
                                selectedEquipment.insert(option)
                            }
                        }
                    )
                }
            }
        }
        .padding(Spacing.lg)
    }

    let equipmentOptions = [
        "Barbell",
        "Dumbbells",
        "Resistance Bands",
        "Pull-up Bar"
    ]
}
```

### Example 5: Section Cover Page

```swift
import SwiftUI

struct SectionCoverView: View {
    let title: String
    let subtitle: String
    let iconName: String
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: Spacing.xxl) {  // 48px major spacing ✅
            Spacer()

            VStack(spacing: Spacing.xl) {  // 32px section spacing ✅
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.trainPrimary.opacity(0.1))
                        .frame(width: 100, height: 100)

                    Image(systemName: iconName)
                        .font(.system(size: 48))
                        .foregroundColor(.trainPrimary)
                }

                // Title
                Text(title)
                    .font(.trainTitle)  // 24px Medium ✅
                    .foregroundColor(.trainTextPrimary)
                    .multilineTextAlignment(.center)

                // Subtitle
                Text(subtitle)
                    .font(.trainBody)  // 16px Light ✅
                    .foregroundColor(.trainTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xl)
            }

            Spacer()

            // Continue button
            CustomButton(
                title: "Let's Go",
                action: onContinue
            )
            .padding(.horizontal, Layout.horizontalPadding)  // 20px ✅
        }
        .padding(Spacing.lg)  // 24px ✅
        .background(Color.white)
    }
}
```

## ❌ Bad Practices (Avoid These)

### Example 1: Hardcoded Values

```swift
// ❌ DON'T DO THIS
VStack(spacing: 32) {  // Hardcoded
    Text("Title")
        .font(.system(size: 24, weight: .bold))  // Hardcoded
        .foregroundColor(Color(hex: "#1A1A1A"))  // Hardcoded color

    Button(action: {}) {
        Text("Continue")
            .font(.system(size: 18))  // Hardcoded
    }
    .frame(height: 50)  // Hardcoded
    .cornerRadius(16)  // Hardcoded
    .padding(.horizontal, 20)  // Hardcoded
}

// ✅ DO THIS INSTEAD
VStack(spacing: Spacing.xl) {  // Constant
    Text("Title")
        .font(.trainTitle)  // Semantic font
        .foregroundColor(.trainTextPrimary)  // Color palette

    CustomButton(
        title: "Continue",
        action: {}
    )
    .padding(.horizontal, Layout.horizontalPadding)  // Constant
}
```

### Example 2: Inconsistent Styling

```swift
// ❌ DON'T DO THIS
Button(action: {}) {
    Text("Get Started")
        .font(.headline)  // System font, not design system
        .foregroundColor(.blue)  // System color, not palette
        .padding()  // Default padding, not spec
        .background(Color.green)  // Random color
        .cornerRadius(10)  // Random radius
}

// ✅ DO THIS INSTEAD
CustomButton(
    title: "Get Started",
    action: {},
    style: .primary  // Uses design system automatically
)
```

### Example 3: Mixed Spacing

```swift
// ❌ DON'T DO THIS
VStack(spacing: 16) {
    Text("Title")

    HStack(spacing: 8) {  // Inconsistent
        Text("Item 1")
        Text("Item 2")
    }
    .padding(12)  // Random value

    Text("Subtitle")
        .padding(.top, 24)  // Mixed approaches
}

// ✅ DO THIS INSTEAD
VStack(spacing: Spacing.md) {  // Consistent
    Text("Title")

    HStack(spacing: Spacing.sm) {
        Text("Item 1")
        Text("Item 2")
    }
    .padding(Spacing.md)

    Text("Subtitle")
        .padding(.top, Spacing.lg)
}
```

## 🎨 Color Palette Usage

### Correct Color Usage

```swift
// ✅ Always use semantic color names from ColorPalette
VStack {
    Text("Primary Text")
        .foregroundColor(.trainTextPrimary)  // ✅

    Text("Secondary Text")
        .foregroundColor(.trainTextSecondary)  // ✅

    Rectangle()
        .fill(Color.trainPrimary)  // ✅
        .frame(height: 4)

    Divider()
        .background(Color.trainBorder)  // ✅
}
```

### Incorrect Color Usage

```swift
// ❌ Never hardcode hex colors
VStack {
    Text("Primary Text")
        .foregroundColor(Color(hex: "#1A1A1A"))  // ❌

    Text("Secondary Text")
        .foregroundColor(Color(hex: "#6B6B6B"))  // ❌

    Rectangle()
        .fill(Color(hex: "#0F7A6B"))  // ❌
        .frame(height: 4)
}
```

## 📱 Layout Examples

### Full-Width Content with Padding

```swift
VStack(spacing: Spacing.lg) {
    Text("Welcome")
        .font(.trainTitle)

    // Content that respects Figma layout
    VStack(spacing: Spacing.md) {
        OptionCard(...)
        OptionCard(...)
    }
    .frame(width: Layout.contentWidth)  // 340px from Figma ✅

    // Or use padding for full-width
    CustomButton(
        title: "Continue",
        action: {}
    )
    .padding(.horizontal, Layout.horizontalPadding)  // 20px from Figma ✅
}
```

### Centered Content

```swift
ScrollView {
    VStack(spacing: Spacing.lg) {
        // Content
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Question Title")
                .font(.trainTitle)

            ForEach(options, id: \.self) { option in
                OptionCard(...)
            }
        }
        .frame(maxWidth: Layout.contentWidth)  // Max 340px ✅
    }
    .frame(maxWidth: .infinity)  // Center in screen
    .padding(.horizontal, Layout.horizontalPadding)
}
```

## 🔧 Custom Components

When creating new components, follow these patterns:

### Pattern 1: Selection Card

```swift
struct MySelectionCard: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.trainHeadline)  // 20px Medium ✅
                .foregroundColor(isSelected ? .white : .trainTextPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: ElementHeight.optionCard)  // 80px ✅
                .padding(.horizontal, Spacing.lg)  // 24px ✅
                .background(isSelected ? Color.trainPrimary : Color.white)
                .cornerRadius(CornerRadius.md)  // 16px ✅
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .stroke(isSelected ? Color.clear : Color.black, lineWidth: 1)
                )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}
```

### Pattern 2: Section Header

```swift
struct MySectionHeader: View {
    let title: String
    let subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(title)
                .font(.trainTitle)  // 24px Medium ✅
                .foregroundColor(.trainTextPrimary)

            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.trainSubtitle)  // 16px Light ✅
                    .foregroundColor(.trainTextSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
```

## 🎯 Component Checklist

Before creating a new component, verify:

- [ ] Uses `.train*` fonts (not hardcoded)
- [ ] Uses `Spacing.*` for all spacing
- [ ] Uses `ElementHeight.*` for fixed heights
- [ ] Uses `CornerRadius.*` for border radius
- [ ] Uses `Layout.*` for widths/padding
- [ ] Uses `ColorPalette` colors (`.train*`)
- [ ] Matches Figma specs (check FIGMA_SPECS_QUICK_REFERENCE.md)
- [ ] Has proper documentation comments

## 📚 Reference

- See [DESIGN_SYSTEM.md](DESIGN_SYSTEM.md) for complete specs
- See [FIGMA_SPECS_QUICK_REFERENCE.md](FIGMA_SPECS_QUICK_REFERENCE.md) for quick lookup
- See [ColorPalette.swift](trAInSwift/Components/ColorPalette.swift) to change colors
- See [Theme.swift](trAInSwift/Components/Theme.swift) for all constants
