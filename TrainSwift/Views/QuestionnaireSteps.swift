//
//  QuestionnaireSteps.swift
//  TrainSwift
//
//  Individual questionnaire step views (Q1-Q10)
//

import SwiftUI
import UIKit
import SlidingRuler

// MARK: - Name Step (First question in About You section)
struct NameStepView: View {
    @Binding var name: String
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            VStack(alignment: .center, spacing: Spacing.sm) {
                Text("What shall we call you?")
                    .font(.trainTitle2)
                    .foregroundColor(.trainTextPrimary)

                Text("Please enter your username")
                    .font(.trainSubtitle)
                    .foregroundColor(.trainTextSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)

            // Text field with styling
            TextField("", text: $name)
                .placeholder(when: name.isEmpty) {
                    Text("Enter your name")
                        .foregroundColor(.trainTextSecondary.opacity(0.6))
                }
                .font(.trainBody)
                .foregroundColor(.trainTextPrimary)
                .padding(Spacing.md)
                .appCard(cornerRadius: CornerRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                        .stroke(isTextFieldFocused ? Color.trainPrimary : Color.white.opacity(0.12), lineWidth: isTextFieldFocused ? 2 : 1)
                )
                .autocorrectionDisabled()
                .textInputAutocapitalization(.words)
                .focused($isTextFieldFocused)
                .onChange(of: name) { _, newValue in
                    // Sanitize input: remove potentially dangerous characters
                    name = sanitizeUsername(newValue)
                }

            // Character count hint
            Text("\(name.count)/30 characters")
                .font(.trainCaption)
                .foregroundColor(name.count > 30 ? .red : .trainTextSecondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .onAppear {
            // Auto-focus the text field
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isTextFieldFocused = true
            }
        }
    }

    /// Sanitize username to prevent SQL injection and other issues
    private func sanitizeUsername(_ input: String) -> String {
        // Remove SQL injection characters and limit length
        let dangerous = CharacterSet(charactersIn: "';\"\\--/*<>")
        var sanitized = input.components(separatedBy: dangerous).joined()

        // Remove excessive whitespace
        sanitized = sanitized.replacingOccurrences(of: "  ", with: " ")

        // Limit to 30 characters
        if sanitized.count > 30 {
            sanitized = String(sanitized.prefix(30))
        }

        return sanitized
    }
}

// MARK: - Placeholder extension for TextField
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

// MARK: - Q1: Gender
struct GenderStepView: View {
    @Binding var selectedGender: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            VStack(alignment: .center, spacing: Spacing.sm) {
                Text("Gender")
                    .font(.trainTitle2)
                    .foregroundColor(.trainTextPrimary)

                Text("We may require this for exercise prescription")
                    .font(.trainSubtitle)
                    .foregroundColor(.trainTextSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)

            VStack(spacing: Spacing.md) {
                // Male and Female as large square cards side by side
                HStack(spacing: Spacing.md) {
                    // Male card
                    Button(action: { selectedGender = "Male" }) {
                        VStack(spacing: Spacing.md) {
                            ZStack {
                                Circle()
                                    .fill(selectedGender == "Male" ? Color.white.opacity(0.3) : Color.trainHover)
                                    .frame(width: 56, height: 56)

                                Image(systemName: "figure.stand")
                                    .font(.title)
                                    .foregroundColor(selectedGender == "Male" ? .white : .trainPrimary)
                            }

                            Text("Male")
                                .font(.trainBodyMedium)
                                .foregroundColor(selectedGender == "Male" ? .white : .trainTextPrimary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.xl)
                        .background(selectedGender == "Male" ? Color.trainPrimary : .clear)
                        .appCard()
                    }
                    .buttonStyle(ScaleButtonStyle())

                    // Female card
                    Button(action: { selectedGender = "Female" }) {
                        VStack(spacing: Spacing.md) {
                            ZStack {
                                Circle()
                                    .fill(selectedGender == "Female" ? Color.white.opacity(0.3) : Color.trainHover)
                                    .frame(width: 56, height: 56)

                                Image(systemName: "figure.stand.dress")
                                    .font(.title)
                                    .foregroundColor(selectedGender == "Female" ? .white : .trainPrimary)
                            }

                            Text("Female")
                                .font(.trainBodyMedium)
                                .foregroundColor(selectedGender == "Female" ? .white : .trainTextPrimary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.xl)
                        .background(selectedGender == "Female" ? Color.trainPrimary : .clear)
                        .appCard()
                    }
                    .buttonStyle(ScaleButtonStyle())
                }

                // Other / Prefer not to say as separate full-width card
                Button(action: { selectedGender = "Other / Prefer not to say" }) {
                    HStack(spacing: Spacing.md) {
                        ZStack {
                            Circle()
                                .fill(selectedGender == "Other / Prefer not to say" ? Color.white.opacity(0.3) : Color.trainHover)
                                .frame(width: 48, height: 48)

                            Image(systemName: "person.fill")
                                .font(.title2)
                                .foregroundColor(selectedGender == "Other / Prefer not to say" ? .white : .trainPrimary)
                        }

                        Text("Other / Prefer not to say")
                            .font(.trainBodyMedium)
                            .foregroundColor(selectedGender == "Other / Prefer not to say" ? .white : .trainTextPrimary)

                        Spacer()
                    }
                    .padding(Spacing.md)
                    .frame(maxWidth: .infinity)
                    .background(selectedGender == "Other / Prefer not to say" ? Color.trainPrimary : .clear)
                    .appCard()
                }
                .buttonStyle(ScaleButtonStyle())
            }

            Spacer()
        }
    }
}

// MARK: - Q2: Date of Birth
struct AgeStepView: View {
    @Binding var dateOfBirth: Date

    // Calculate age from date of birth
    private var age: Int {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: dateOfBirth, to: Date())
        return ageComponents.year ?? 0
    }

    // Date range: 18 years ago to 100 years ago
    private var dateRange: ClosedRange<Date> {
        let calendar = Calendar.current
        let now = Date()
        let minDate = calendar.date(byAdding: .year, value: -100, to: now) ?? now
        let maxDate = calendar.date(byAdding: .year, value: -18, to: now) ?? now
        return minDate...maxDate
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            VStack(alignment: .center, spacing: Spacing.sm) {
                Text("Date of Birth")
                    .font(.trainTitle2)
                    .foregroundColor(.trainTextPrimary)

                Text("This helps us tailor your training intensity")
                    .font(.trainSubtitle)
                    .foregroundColor(.trainTextSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, Spacing.lg)

            // Age display
            HStack(alignment: .lastTextBaseline, spacing: Spacing.xs) {
                Text("\(age)")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundColor(.trainPrimary)
                Text("years old")
                    .font(.trainTitle)
                    .foregroundColor(.white)  // Changed to white per requirements
            }
            .frame(maxWidth: .infinity)
            .padding(.top, Spacing.md)

            // Native Date Picker with wheel style
            DatePicker(
                "",
                selection: $dateOfBirth,
                in: dateRange,
                displayedComponents: .date
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .frame(maxWidth: .infinity)
            .padding(.horizontal, Spacing.lg)

            if age < 18 {
                Text("You must be at least 18 years old")
                    .font(.trainCaption)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, Spacing.lg)
            }

            Spacer()
        }
    }
}

// MARK: - Q3: Height
struct HeightStepView: View {
    @Binding var heightCm: Double
    @Binding var heightFt: Int
    @Binding var heightIn: Int
    @Binding var unit: QuestionnaireData.HeightUnit

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            VStack(alignment: .center, spacing: Spacing.sm) {
                Text("Height")
                    .font(.trainTitle2)
                    .foregroundColor(.trainTextPrimary)

                Text("This helps us calculate your body metrics")
                    .font(.trainSubtitle)
                    .foregroundColor(.trainTextSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, Spacing.lg)

            // Unit toggle - center aligned with spacing
            HStack(spacing: Spacing.sm) {
                Button(action: {
                    unit = .cm
                    // Convert ft/in to cm if needed
                    if heightFt > 0 || heightIn > 0 {
                        heightCm = Double(heightFt) * 30.48 + Double(heightIn) * 2.54
                    }
                }) {
                    Text("cm")
                        .font(.trainBodyMedium)
                        .foregroundColor(unit == .cm ? .white : .trainTextPrimary)
                        .padding(.vertical, Spacing.sm)
                        .padding(.horizontal, Spacing.lg)
                        .background(unit == .cm ? Color.trainPrimary : Color.clear)
                        .warmGlassCard(cornerRadius: CornerRadius.sm)
                        .overlay(
                            RoundedRectangle(cornerRadius: CornerRadius.sm, style: .continuous)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                }

                Button(action: {
                    unit = .ftIn
                    // Convert cm to ft/in if needed
                    if heightCm > 0 {
                        let totalInches = heightCm / 2.54
                        heightFt = Int(totalInches / 12)
                        heightIn = Int(totalInches.truncatingRemainder(dividingBy: 12))
                    }
                }) {
                    Text("ft/in")
                        .font(.trainBodyMedium)
                        .foregroundColor(unit == .ftIn ? .white : .trainTextPrimary)
                        .padding(.vertical, Spacing.sm)
                        .padding(.horizontal, Spacing.lg)
                        .background(unit == .ftIn ? Color.trainPrimary : Color.clear)
                        .warmGlassCard(cornerRadius: CornerRadius.sm)
                        .overlay(
                            RoundedRectangle(cornerRadius: CornerRadius.sm, style: .continuous)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                }
            }
            .frame(maxWidth: .infinity)

            // Sliding Ruler for Height
            if unit == .cm {
                VStack(spacing: Spacing.md) {
                    // Display current value with unit on same line
                    HStack(alignment: .lastTextBaseline, spacing: Spacing.xs) {
                        Text("\(Int(heightCm))")
                            .font(.system(size: 56, weight: .bold))
                            .foregroundColor(.trainPrimary)
                        Text("cm")
                            .font(.trainTitle)
                            .foregroundColor(.trainTextSecondary)
                    }
                    .frame(height: 80)

                    // SlidingRuler - Each major tick = 10cm (e.g., 140, 150, 160)
                    SlidingRuler(
                        value: $heightCm,
                        in: 120...220,
                        step: 10,  // Step of 10 means each major tick is 10cm
                        snap: .none,  // No snapping - allows precise values
                        tick: .unit  // Major ticks every 10 units
                    )
                    .tint(.trainPrimary)  // Primary color indicator bar
                    .colorScheme(.dark)  // Force dark mode for white labels
                    .frame(height: 60)
                    .padding(.horizontal, Spacing.lg)
                    .onAppear {
                        if heightCm < 120 {
                            heightCm = 170 // Default to 170cm
                        }
                    }
                    .onChange(of: heightCm) { _, newValue in
                        let totalInches = newValue / 2.54
                        heightFt = Int(totalInches / 12)
                        heightIn = Int(totalInches.truncatingRemainder(dividingBy: 12))
                    }
                }
            } else {
                // For ft/in, use sliding ruler in feet (with decimal for inches)
                VStack(spacing: Spacing.md) {
                    // Convert height to feet as decimal for the slider
                    let heightInFeet = Binding<Double>(
                        get: { Double(heightFt) + Double(heightIn) / 12.0 },
                        set: { newFeet in
                            heightFt = Int(newFeet)
                            heightIn = Int((newFeet - Double(Int(newFeet))) * 12.0)
                            heightCm = (Double(heightFt) * 30.48) + (Double(heightIn) * 2.54)
                        }
                    )

                    // Display current value as Xft Yin
                    HStack(alignment: .lastTextBaseline, spacing: Spacing.xs) {
                        Text("\(heightFt)")
                            .font(.system(size: 56, weight: .bold))
                            .foregroundColor(.trainPrimary)
                        Text("ft")
                            .font(.trainTitle)
                            .foregroundColor(.trainTextSecondary)

                        Text("\(heightIn)")
                            .font(.system(size: 56, weight: .bold))
                            .foregroundColor(.trainPrimary)
                        Text("in")
                            .font(.trainTitle)
                            .foregroundColor(.trainTextSecondary)
                    }
                    .frame(height: 80)

                    // SlidingRuler - Each major tick = 1 foot, labels show 4, 5, 6, 7
                    SlidingRuler(
                        value: heightInFeet,
                        in: 3...8,
                        step: 1,  // Step of 1 means each major tick is 1 foot
                        snap: .none,  // No snapping - allows precise values
                        tick: .unit  // Major ticks every 1 foot
                    )
                    .tint(.trainPrimary)  // Primary color indicator bar
                    .colorScheme(.dark)  // Force dark mode for white labels
                    .frame(height: 60)
                    .padding(.horizontal, Spacing.lg)
                    .onAppear {
                        if heightFt == 0 && heightIn == 0 {
                            heightFt = 5
                            heightIn = 7
                            heightCm = 170.18 // 5ft 7in in cm
                        }
                    }
                }
            }

            Spacer()
        }
    }
}

// MARK: - Q4: Weight
struct WeightStepView: View {
    @Binding var weightKg: Double
    @Binding var weightLbs: Double
    @Binding var unit: QuestionnaireData.WeightUnit

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            VStack(alignment: .center, spacing: Spacing.sm) {
                Text("Weight")
                    .font(.trainTitle2)
                    .foregroundColor(.trainTextPrimary)

                Text("This helps us calculate your body metrics")
                    .font(.trainSubtitle)
                    .foregroundColor(.trainTextSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, Spacing.lg)

            // Unit toggle - center aligned with spacing
            HStack(spacing: Spacing.sm) {
                Button(action: {
                    unit = .kg
                    // Convert lbs to kg if needed
                    if weightLbs > 0 {
                        weightKg = weightLbs * 0.453592
                    }
                }) {
                    Text("kg")
                        .font(.trainBodyMedium)
                        .foregroundColor(unit == .kg ? .white : .trainTextPrimary)
                        .padding(.vertical, Spacing.sm)
                        .padding(.horizontal, Spacing.lg)
                        .background(unit == .kg ? Color.trainPrimary : Color.clear)
                        .warmGlassCard(cornerRadius: CornerRadius.sm)
                        .overlay(
                            RoundedRectangle(cornerRadius: CornerRadius.sm, style: .continuous)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                }

                Button(action: {
                    unit = .lbs
                    // Convert kg to lbs if needed
                    if weightKg > 0 {
                        weightLbs = weightKg * 2.20462
                    }
                }) {
                    Text("lbs")
                        .font(.trainBodyMedium)
                        .foregroundColor(unit == .lbs ? .white : .trainTextPrimary)
                        .padding(.vertical, Spacing.sm)
                        .padding(.horizontal, Spacing.lg)
                        .background(unit == .lbs ? Color.trainPrimary : Color.clear)
                        .warmGlassCard(cornerRadius: CornerRadius.sm)
                        .overlay(
                            RoundedRectangle(cornerRadius: CornerRadius.sm, style: .continuous)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                }
            }
            .frame(maxWidth: .infinity)

            // Sliding Ruler for Weight
            if unit == .kg {
                VStack(spacing: Spacing.md) {
                    // Display current value
                    HStack(alignment: .lastTextBaseline, spacing: Spacing.xs) {
                        Text("\(Int(weightKg))")
                            .font(.system(size: 56, weight: .bold))
                            .foregroundColor(.trainPrimary)
                        Text("kg")
                            .font(.trainTitle)
                            .foregroundColor(.trainTextSecondary)
                    }
                    .frame(height: 80)

                    // SlidingRuler - Each major tick = 10kg (e.g., 60, 70, 80)
                    SlidingRuler(
                        value: $weightKg,
                        in: 30...200,
                        step: 10,  // Step of 10 means each major tick is 10kg
                        snap: .none,  // No snapping - allows precise values
                        tick: .unit  // Major ticks every 10 units
                    )
                    .tint(.trainPrimary)  // Primary color indicator bar
                    .colorScheme(.dark)  // Force dark mode for white labels
                    .frame(height: 60)
                    .padding(.horizontal, Spacing.lg)
                    .onAppear {
                        if weightKg < 30 {
                            weightKg = 70 // Default to 70kg
                        }
                    }
                    .onChange(of: weightKg) { _, newValue in
                        weightLbs = newValue * 2.20462
                    }
                }
            } else {
                VStack(spacing: Spacing.md) {
                    // Display current value
                    HStack(alignment: .lastTextBaseline, spacing: Spacing.xs) {
                        Text("\(Int(weightLbs))")
                            .font(.system(size: 56, weight: .bold))
                            .foregroundColor(.trainPrimary)
                        Text("lbs")
                            .font(.trainTitle)
                            .foregroundColor(.trainTextSecondary)
                    }
                    .frame(height: 80)

                    // SlidingRuler - Each major tick = 20lbs (e.g., 140, 160, 180)
                    SlidingRuler(
                        value: $weightLbs,
                        in: 60...440,
                        step: 20,  // Step of 20 means each major tick is 20lbs
                        snap: .none,  // No snapping - allows precise values
                        tick: .unit  // Major ticks every 20 units
                    )
                    .tint(.trainPrimary)  // Primary color indicator bar
                    .colorScheme(.dark)  // Force dark mode for white labels
                    .frame(height: 60)
                    .padding(.horizontal, Spacing.lg)
                    .onAppear {
                        if weightLbs < 65 {
                            weightLbs = 154 // Default to 154lbs (70kg equivalent)
                        }
                    }
                    .onChange(of: weightLbs) { _, newValue in
                        weightKg = newValue * 0.453592
                    }
                }
            }

            Spacer()
        }
    }
}

// MARK: - Q5: Goals
struct GoalsStepView: View {
    @Binding var selectedGoals: [String]

    let goals = [
        ("get_stronger", "Get Stronger", "Build maximum strength & power"),
        ("build_muscle", "Build Muscle Mass", "Both size and definition"),
        ("tone_up", "Tone Up", "Lose fat while building muscle")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            VStack(alignment: .center, spacing: Spacing.sm) {
                Text("What are your primary goals?")
                    .font(.trainTitle2)
                    .foregroundColor(.trainTextPrimary)
                    .multilineTextAlignment(.center)

                Text("Select all that apply (at least 1)")
                    .font(.trainSubtitle)
                    .foregroundColor(.trainTextSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)

            VStack(spacing: Spacing.md) {
                ForEach(goals, id: \.0) { value, title, subtitle in
                    OptionCard(
                        title: title,
                        subtitle: subtitle,
                        isSelected: selectedGoals.contains(value),
                        action: { toggleGoal(value) }
                    )
                }

                // Show selection count
                if !selectedGoals.isEmpty {
                    Text("\(selectedGoals.count) of 3 selected")
                        .font(.trainCaption)
                        .foregroundColor(.trainTextSecondary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }

            Spacer()
        }
    }

    private func toggleGoal(_ goal: String) {
        if selectedGoals.contains(goal) {
            selectedGoals.removeAll { $0 == goal }
        } else if selectedGoals.count < 3 {
            selectedGoals.append(goal)
        }
    }
}

// MARK: - Q6: Muscle Groups
struct MuscleGroupsStepView: View {
    @Binding var selectedGroups: [String]
    var gender: String = "Male"

    /// Convert gender string to MuscleSelector.BodyGender
    private var bodyGender: MuscleSelector.BodyGender {
        gender.lowercased() == "female" ? .female : .male
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            VStack(alignment: .center, spacing: Spacing.sm) {
                Text("Any muscle groups you want to prioritise?")
                    .font(.trainTitle2)
                    .foregroundColor(.trainTextPrimary)
                    .multilineTextAlignment(.center)

                // Combined subtitle with selection status
                Text(selectionStatusText)
                    .font(.trainSubtitle)
                    .foregroundColor(.trainTextSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)

            // Interactive body diagram - uses gender from questionnaire, larger height after removing toggle
            CompactMuscleSelector(selectedMuscles: $selectedGroups, maxSelections: 3, gender: bodyGender)
                .frame(maxWidth: .infinity)
                .frame(height: 440)

            // Selected muscles pills (only shown when selections exist)
            if !selectedGroups.isEmpty {
                HStack(spacing: Spacing.sm) {
                    ForEach(selectedGroups, id: \.self) { muscle in
                        HStack(spacing: 6) {
                            Text(muscle)
                                .font(.trainCaption)
                                .foregroundColor(.white)

                            Button(action: {
                                selectedGroups.removeAll { $0 == muscle }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.9))
                            }
                        }
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, 6)
                        .background(Color.trainPrimary)
                        .cornerRadius(CornerRadius.lg)
                    }
                }
                .frame(maxWidth: .infinity)
            }

            Spacer()
        }
    }

    // Combined selection status text
    private var selectionStatusText: String {
        if selectedGroups.isEmpty {
            return "Optional: Select up to 3, or skip for a balanced program"
        } else {
            return "Selected \(selectedGroups.count) of 3\nTap to remove"
        }
    }
}

struct MuscleGroupButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.trainBodyMedium)
                .foregroundColor(isSelected ? .white : .trainTextPrimary)
                .frame(maxWidth: .infinity)
                .padding(Spacing.md)
                .background(isSelected ? Color.trainPrimary : .clear)
                .appCard(cornerRadius: CornerRadius.md)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Q7: Experience (Confidence-Based)
struct ExperienceStepView: View {
    @Binding var experience: String

    // Experience levels (maps to complexity constraints in BUSINESS_RULES.md Section 6)
    let experiences = [
        ("no_experience", "No Experience", "Brand new to resistance training? We'll start with simple, effective exercises."),
        ("beginner", "Beginner", "Getting started with lifting? We'll build your foundation with approachable movements."),
        ("intermediate", "Intermediate", "Comfortable in the gym? We'll add variety with more compound exercises."),
        ("advanced", "Advanced", "Confident and consistent? We'll include the full range of complex lifts.")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            VStack(alignment: .center, spacing: Spacing.sm) {
                Text("How confident do you feel in the gym?")
                    .font(.trainTitle2)
                    .foregroundColor(.trainTextPrimary)
                    .multilineTextAlignment(.center)

                Text("This helps us match exercises to your comfort level")
                    .font(.trainSubtitle)
                    .foregroundColor(.trainTextSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)

            VStack(spacing: Spacing.sm) {
                ForEach(experiences, id: \.0) { value, title, subtitle in
                    OptionCard(
                        title: title,
                        subtitle: subtitle,
                        isSelected: experience == value,
                        useAutoHeight: true,
                        subtitleFont: .trainCaptionLarge,
                        action: { experience = value }
                    )
                    .frame(minHeight: 70)
                }
            }

            Spacer()
        }
    }
}

// MARK: - Q8: Motivation (Optional)
struct MotivationStepView: View {
    @Binding var selectedMotivations: [String]
    @Binding var otherText: String

    let motivations = [
        ("lack_structure", "I lack structure in my workouts"),
        ("need_guidance", "I need more guidance"),
        ("lack_confidence", "I lack confidence when I exercise"),
        ("need_motivation", "I need motivation"),
        ("need_accountability", "I need accountability")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            VStack(alignment: .center, spacing: Spacing.sm) {
                Text("Why have you considered using this app?")
                    .font(.trainTitle2)
                    .foregroundColor(.trainTextPrimary)
                    .multilineTextAlignment(.center)

                Text("Select all that apply (optional)")
                    .font(.trainSubtitle)
                    .foregroundColor(.trainTextSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)

            VStack(spacing: Spacing.md) {
                ForEach(motivations, id: \.0) { value, title in
                    MultiSelectCard(
                        title: title,
                        isSelected: selectedMotivations.contains(value),
                        isCompact: true,
                        action: { toggleMotivation(value) }
                    )
                }
            }

            Spacer()
        }
    }

    private func toggleMotivation(_ motivation: String) {
        if selectedMotivations.contains(motivation) {
            selectedMotivations.removeAll { $0 == motivation }
        } else {
            selectedMotivations.append(motivation)
        }
    }
}

// MARK: - Q9: Training Place (Where do you exercise?)
struct TrainingPlaceStepView: View {
    @Binding var selectedTrainingPlace: String

    let trainingPlaces = [
        ("large_gym", "Large Gym", "Full commercial gym with all equipment", "building.2.fill"),
        ("small_gym", "Small Gym", "Smaller gym with essential equipment", "dumbbell.fill"),
        ("garage_gym", "Garage Gym", "Home/garage gym with basic equipment", "house.fill")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            VStack(alignment: .center, spacing: Spacing.sm) {
                Text("Where do you exercise?")
                    .font(.trainTitle2)
                    .foregroundColor(.trainTextPrimary)
                    .multilineTextAlignment(.center)

                Text("This helps us pre-select appropriate equipment")
                    .font(.trainSubtitle)
                    .foregroundColor(.trainTextSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)

            VStack(spacing: Spacing.md) {
                ForEach(trainingPlaces, id: \.0) { value, title, subtitle, iconName in
                    Button(action: { selectedTrainingPlace = value }) {
                        HStack(spacing: Spacing.md) {
                            ZStack {
                                Circle()
                                    .fill(selectedTrainingPlace == value ? Color.white.opacity(0.3) : Color.trainHover)
                                    .frame(width: 48, height: 48)

                                Image(systemName: iconName)
                                    .font(.title2)
                                    .foregroundColor(selectedTrainingPlace == value ? .white : .trainPrimary)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(title)
                                    .font(.trainBodyMedium)
                                    .foregroundColor(selectedTrainingPlace == value ? .white : .trainTextPrimary)

                                Text(subtitle)
                                    .font(.trainCaption)
                                    .foregroundColor(selectedTrainingPlace == value ? .white.opacity(0.8) : .trainTextSecondary)
                            }

                            Spacer()

                            if selectedTrainingPlace == value {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(Spacing.md)
                        .frame(maxWidth: .infinity)
                        .background(selectedTrainingPlace == value ? Color.trainPrimary : .clear)
                        .appCard()
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }

            Spacer()
        }
    }
}

// MARK: - Q10: Equipment

// MARK: - Equipment Card Component
/// Individual equipment item card with thumbnail placeholder and circular selection indicator
struct EquipmentCard: View {
    let equipmentName: String
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: Spacing.md) {
                // Equipment thumbnail (64x64)
                ZStack {
                    RoundedRectangle(cornerRadius: CornerRadius.sm, style: .continuous)
                        .fill(Color.trainPrimary.opacity(0.1))
                        .frame(width: 64, height: 64)

                    if let uiImage = EquipmentImageMapping.image(for: equipmentName) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 52, height: 52)
                    } else {
                        Image(systemName: equipmentIcon)
                            .font(.system(size: 24))
                            .foregroundColor(.trainPrimary.opacity(0.6))
                    }
                }

                // Equipment name
                Text(equipmentName)
                    .font(.trainBody)
                    .foregroundColor(.trainTextPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Spacer()

                // Circular selection indicator (24pt diameter)
                // Trailing padding matches vertical spacing from tick to card edge
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.trainPrimary : Color.trainTextSecondary.opacity(0.4), lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Circle()
                            .fill(Color.trainPrimary)
                            .frame(width: 24, height: 24)

                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(.leading, Spacing.sm)
            .padding(.trailing, 28) // Matches vertical spacing: (80 - 24) / 2
            .padding(.vertical, Spacing.sm)
            .frame(height: 80)
            .appCard(cornerRadius: CornerRadius.md)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    /// Icon based on equipment name
    private var equipmentIcon: String {
        let name = equipmentName.lowercased()
        if name.contains("rack") || name.contains("bench press") {
            return "figure.strengthtraining.traditional"
        } else if name.contains("cable") || name.contains("pull") || name.contains("row") {
            return "cable.connector"
        } else if name.contains("leg") || name.contains("calf") || name.contains("hip") {
            return "figure.walk"
        } else if name.contains("bar") || name.contains("rope") || name.contains("handle") || name.contains("strap") {
            return "lasso"
        } else if name.contains("wheel") || name.contains("dip") || name.contains("roman") {
            return "figure.core.training"
        } else if name.contains("band") {
            return "arrow.left.arrow.right"
        } else if name.contains("belt") {
            return "circle.dashed"
        } else {
            return "dumbbell.fill"
        }
    }
}

// MARK: - Equipment Group Section Component
/// Category heading with max 2 equipment cards and "See more..." link
struct EquipmentGroupSection: View {
    let categoryKey: String
    let title: String
    let allItems: [String]
    let selectedItems: Set<String>
    let onToggleItem: (String) -> Void
    let onSeeMore: () -> Void

    /// Items to display in the preview (max 2)
    private var previewItems: [String] {
        Array(allItems.prefix(2))
    }

    /// Whether there are more items beyond the preview
    private var hasMoreItems: Bool {
        allItems.count > 2
    }

    /// Count of additional items not shown in preview
    private var moreItemsCount: Int {
        max(0, allItems.count - 2)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Category heading
            Text(title)
                .font(.trainHeadline)
                .foregroundColor(.trainTextPrimary)
                .padding(.leading, Spacing.xs)

            // Equipment cards (max 2)
            VStack(spacing: Spacing.sm) {
                ForEach(previewItems, id: \.self) { item in
                    EquipmentCard(
                        equipmentName: item,
                        isSelected: selectedItems.contains(item),
                        onToggle: { onToggleItem(item) }
                    )
                }
            }

            // "See more..." link if there are additional items
            if hasMoreItems {
                Button(action: onSeeMore) {
                    HStack(spacing: Spacing.xs) {
                        Text("See more...")
                            .font(.trainBody)
                            .foregroundColor(.trainPrimary)

                        Text("(\(moreItemsCount) more)")
                            .font(.trainCaption)
                            .foregroundColor(.trainTextSecondary)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.trainPrimary)
                    }
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.sm)
                }
            }
        }
    }
}

// MARK: - Equipment Category Sheet Component
/// Full-height sheet showing all equipment items for a category
struct EquipmentCategorySheet: View {
    let title: String
    let items: [String]
    let selectedItems: Set<String>
    let onToggleItem: (String) -> Void
    let onDone: () -> Void

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: Spacing.sm) {
                    ForEach(items, id: \.self) { item in
                        EquipmentCard(
                            equipmentName: item,
                            isSelected: selectedItems.contains(item),
                            onToggle: { onToggleItem(item) }
                        )
                    }
                }
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.md)
                .padding(.bottom, Spacing.xxl)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onDone()
                    }
                    .font(.trainBodyMedium)
                    .foregroundColor(.trainPrimary)
                }
            }
        }
    }
}

// MARK: - Simple Equipment Toggle Card (for categories without sub-items)
/// Simple toggle card for categories like Dumbbells/Kettlebells that don't have sub-items
struct SimpleEquipmentToggleCard: View {
    let title: String
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: Spacing.md) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: CornerRadius.sm, style: .continuous)
                        .fill(Color.trainPrimary.opacity(0.1))
                        .frame(width: 64, height: 64)

                    Image(systemName: iconName)
                        .font(.system(size: 24))
                        .foregroundColor(.trainPrimary.opacity(0.6))
                }

                // Title
                Text(title)
                    .font(.trainBodyMedium)
                    .foregroundColor(.trainTextPrimary)

                Spacer()

                // Selection indicator
                // Trailing padding matches vertical spacing from tick to card edge
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.trainPrimary : Color.trainTextSecondary.opacity(0.4), lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Circle()
                            .fill(Color.trainPrimary)
                            .frame(width: 24, height: 24)

                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(.leading, Spacing.sm)
            .padding(.trailing, 28) // Matches vertical spacing: (80 - 24) / 2
            .padding(.vertical, Spacing.sm)
            .frame(height: 80)
            .appCard(cornerRadius: CornerRadius.md)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private var iconName: String {
        switch title.lowercased() {
        case "dumbbells": return "dumbbell.fill"
        case "kettlebells": return "figure.strengthtraining.functional"
        default: return "dumbbell.fill"
        }
    }
}

struct EquipmentStepView: View {
    @Binding var selectedEquipment: [String]
    @Binding var selectedDetailedEquipment: [String: Set<String>]  // Category -> selected items
    @State private var showingCategorySheet: (key: String, title: String, items: [String])?

    // All equipment categories with sub-items - ordered as specified
    // Order: Barbells, Dumbbells, Kettlebells, Cable Machines, Pin-Loaded, Plate-Loaded, Other
    let equipmentCategories: [(String, String, [String])] = [
        ("barbells", "Barbells", [
            "Squat Rack",
            "Flat Bench Press",
            "Incline Bench Press",
            "Decline Bench Press",
            "Landmine Attachment",
            "Hip Thrust Bench"
        ]),
        ("dumbbells", "Dumbbells", []),  // No sub-items
        ("kettlebells", "Kettlebells", []),  // No sub-items
        ("cable_machines", "Cable Machines", [
            "Single Adjustable Cable Machine",
            "Dual Cable Machine",
            "Lat Pull Down Machine",
            "Cable Row Machine"
        ]),
        ("pin_loaded", "Pin-Loaded Machines", [
            "Leg Press Machine",
            "Leg Extension Machine",
            "Lying Leg Curl Machine",
            "Seated Leg Curl Machine",
            "Standing Calf Raise Machine",
            "Seated Calf Raise Machine",
            "Hip Abduction Machine",
            "Hip Adduction Machine",
            "Assisted Pull-Up/Dip Machine"
        ]),
        ("plate_loaded", "Plate-Loaded Machines", [
            "Leg Press Machine",
            "Hack Squat Machine",
            "Leg Extension Machine",
            "Lying Leg Curl Machine",
            "Seated Leg Curl Machine",
            "Standing Calf Raise Machine",
            "Seated Calf Raise Machine",
            "Glute Kickback Machine"
        ]),
        ("other", "Other", [
            "Ab Wheel",
            "Dip Station",
            "Flat Bench",
            "Pull-Up Bar",
            "Roman Chair"
        ]),
        ("attachments", "Attachments", [
            "Straight Bar",
            "Rope",
            "D-Handles",
            "EZ-Bar",
            "EZ-Bar Cable",
            "Ankle Strap",
            "Resistance Band",
            "Weight Belt"
        ])
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            VStack(alignment: .center, spacing: Spacing.sm) {
                Text("What equipment do you have available?")
                    .font(.trainTitle2)
                    .foregroundColor(.trainTextPrimary)
                    .multilineTextAlignment(.center)

                Text("Pre-selected based on your gym type")
                    .font(.trainSubtitle)
                    .foregroundColor(.trainTextSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)

            // Equipment sections
            VStack(spacing: Spacing.lg) {
                ForEach(equipmentCategories, id: \.0) { categoryKey, title, subItems in
                    if subItems.isEmpty {
                        // Simple toggle for categories without sub-items (Dumbbells, Kettlebells)
                        SimpleEquipmentToggleCard(
                            title: title,
                            isSelected: selectedEquipment.contains(categoryKey),
                            onToggle: { toggleCategory(categoryKey) }
                        )
                    } else {
                        // Group section with equipment cards for categories with sub-items
                        EquipmentGroupSection(
                            categoryKey: categoryKey,
                            title: title,
                            allItems: subItems,
                            selectedItems: selectedDetailedEquipment[categoryKey] ?? Set<String>(),
                            onToggleItem: { item in toggleSubItem(category: categoryKey, subItem: item, allSubItems: subItems) },
                            onSeeMore: { showingCategorySheet = (categoryKey, title, subItems) }
                        )
                    }
                }
            }
        }
        .sheet(item: Binding(
            get: { showingCategorySheet.map { SheetData(key: $0.key, title: $0.title, items: $0.items) } },
            set: { _ in showingCategorySheet = nil }
        )) { sheetData in
            EquipmentCategorySheet(
                title: sheetData.title,
                items: sheetData.items,
                selectedItems: selectedDetailedEquipment[sheetData.key] ?? Set<String>(),
                onToggleItem: { item in
                    toggleSubItem(category: sheetData.key, subItem: item, allSubItems: sheetData.items)
                },
                onDone: { showingCategorySheet = nil }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }

    /// Helper struct to make sheet data Identifiable
    private struct SheetData: Identifiable {
        let key: String
        let title: String
        let items: [String]
        var id: String { key }
    }

    private func toggleCategory(_ categoryKey: String) {
        if selectedEquipment.contains(categoryKey) {
            selectedEquipment.removeAll { $0 == categoryKey }
        } else {
            selectedEquipment.append(categoryKey)
        }
    }

    private func toggleSubItem(category: String, subItem: String, allSubItems: [String]) {
        var currentSet = selectedDetailedEquipment[category] ?? Set<String>()
        if currentSet.contains(subItem) {
            currentSet.remove(subItem)
        } else {
            currentSet.insert(subItem)
        }
        selectedDetailedEquipment[category] = currentSet

        // If all sub-items are unchecked, uncheck the parent too
        if currentSet.isEmpty {
            selectedEquipment.removeAll { $0 == category }
        } else if !selectedEquipment.contains(category) {
            // If any sub-item is checked, ensure parent is checked
            selectedEquipment.append(category)
        }
    }
}


// MARK: - Equipment Info Modal

struct EquipmentInfoModal: View {
    let equipmentType: String
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            // Semi-transparent background with blur
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }

            // Modal card with glassmorphic styling
            VStack(spacing: 0) {
                // Equipment image (top 40%)
                ZStack {
                    Color.trainPrimary.opacity(0.1)

                    if let uiImage = EquipmentImageMapping.categoryImage(for: equipmentType) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 160)
                    } else {
                        Image(systemName: equipmentIcon)
                            .font(.system(size: 80))
                            .foregroundColor(.trainPrimary)
                    }
                }
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous))
                .padding(Spacing.md)

                // Content (bottom 60%)
                VStack(alignment: .leading, spacing: Spacing.md) {
                    Text(equipmentName)
                        .font(.trainTitle2)
                        .foregroundColor(.trainTextPrimary)

                    Text(equipmentDescription)
                        .font(.trainBody)
                        .foregroundColor(.trainTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer()
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.lg)
            }
            .frame(width: 320, height: 480)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous))
            .shadow(color: .black.opacity(0.15), radius: 30, x: 0, y: 15)
            .overlay(
                // Close button with glassmorphic style
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.trainTextPrimary)
                        .frame(width: 28, height: 28)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
                .padding(Spacing.md),
                alignment: .topTrailing
            )
            .transition(.scale.combined(with: .opacity))
        }
        .animation(.spring(response: 0.3), value: equipmentType)
    }

    private var equipmentIcon: String {
        switch equipmentType {
        case "dumbbells": return "dumbbell.fill"
        case "barbells": return "figure.strengthtraining.traditional"
        case "kettlebells": return "figure.strengthtraining.functional"
        case "cable_machines": return "cable.connector"
        case "pin_loaded", "plate_loaded": return "gearshape.2.fill"
        default: return "dumbbell.fill"
        }
    }

    private var equipmentName: String {
        switch equipmentType {
        case "dumbbells": return "Dumbbells"
        case "barbells": return "Barbells"
        case "kettlebells": return "Kettlebells"
        case "cable_machines": return "Cable Machines"
        case "pin_loaded": return "Pin-loaded Machines"
        case "plate_loaded": return "Plate-loaded Machines"
        default: return "Equipment"
        }
    }

    private var equipmentDescription: String {
        switch equipmentType {
        case "dumbbells":
            return "Free weights held in each hand. Excellent for unilateral training and building stabilizer muscles. Great for home gyms."
        case "barbells":
            return "A long bar with weight plates on each end. Ideal for heavy compound movements like squats, deadlifts, and bench press."
        case "kettlebells":
            return "Cast iron weights with a handle on top. Perfect for dynamic movements, swings, and functional training."
        case "cable_machines":
            return "Adjustable pulley systems with weight stacks. Provide constant tension throughout movements and allow for various angles."
        case "pin_loaded":
            return "Machines with weight stacks selected by pins. User-friendly and great for isolating specific muscle groups safely."
        case "plate_loaded":
            return "Machines where you manually load weight plates. Combine the benefits of free weights with guided movement patterns."
        default:
            return "Equipment description coming soon."
        }
    }
}

// MARK: - Q10: Training Days
struct TrainingDaysStepView: View {
    @Binding var trainingDays: Int
    @Binding var experienceLevel: String

    // Determine recommended range based on experience level
    private var recommendedRange: ClosedRange<Int> {
        switch experienceLevel {
        case "no_experience", "beginner":
            return 2...3  // No experience/Beginner: 2-3 days
        case "intermediate", "advanced":
            return 3...4  // Intermediate/Advanced: 3-4 days
        // Legacy support for old format
        case "0_months", "0_6_months":
            return 2...3  // Beginners: 2-3 days
        case "6_months_2_years", "2_plus_years":
            return 3...4  // Intermediate/Advanced: 3-4 days
        default:
            return 3...4  // Default to higher range
        }
    }

    // Check if current selection is outside recommended range
    private var isOutsideRecommendedRange: Bool {
        !recommendedRange.contains(trainingDays)
    }

    // Warning message for out-of-range selections
    private var warningMessage: String {
        return "We recommend a maximum of \(recommendedRange.upperBound) sessions per week for your experience level, in order for your brain to learn new movements and for your body to recover properly"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            VStack(alignment: .center, spacing: Spacing.sm) {
                Text("How many days per week would you like to commit to strength training?")
                    .font(.trainTitle2)
                    .foregroundColor(.trainTextPrimary)
                    .multilineTextAlignment(.center)

                Text("Be realistic with your commitment")
                    .font(.trainSubtitle)
                    .foregroundColor(.trainTextSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)

            // Large number display
            VStack(spacing: Spacing.xs) {
                HStack(alignment: .lastTextBaseline, spacing: Spacing.xs) {
                    Text("\(trainingDays)")
                        .font(.trainLargeNumber)
                        .foregroundColor(.trainPrimary)
                    Text(trainingDays == 1 ? "day" : "days")
                        .font(.trainTitle)
                        .foregroundColor(.white)  // Changed to white per requirements
                }
                .frame(maxWidth: .infinity)

                Text("per week")
                    .font(.trainBody)
                    .foregroundColor(.white)  // Changed to white per requirements
            }
            .padding(.vertical, Spacing.md)

            // Horizontal slider with range indicator
            VStack(spacing: Spacing.sm) {
                // Recommended label and bracket above everything
                GeometryReader { geometry in
                    let segmentWidth = geometry.size.width / 6  // 6 equal segments for 6 positions (1-6 days)
                    let rangeStart = (CGFloat(recommendedRange.lowerBound - 1) * segmentWidth)
                    let rangeWidth = (CGFloat(recommendedRange.upperBound - recommendedRange.lowerBound + 1) * segmentWidth)

                    VStack(spacing: 8) {
                        // "Recommended" label at top - centered above bracket
                        HStack {
                            Spacer()
                                .frame(width: rangeStart)
                            Text("Recommended")
                                .font(.trainCaption)
                                .foregroundColor(.trainPrimary)
                                .frame(width: rangeWidth)
                            Spacer()
                        }

                        // Three-sided bracket shape immediately below label
                        Path { path in
                            let height: CGFloat = 20
                            let cornerRadius: CGFloat = 4
                            // Start at bottom left
                            path.move(to: CGPoint(x: rangeStart, y: height))
                            // Left vertical line
                            path.addLine(to: CGPoint(x: rangeStart, y: cornerRadius))
                            // Top left corner
                            path.addArc(center: CGPoint(x: rangeStart + cornerRadius, y: cornerRadius),
                                       radius: cornerRadius,
                                       startAngle: .degrees(180),
                                       endAngle: .degrees(270),
                                       clockwise: false)
                            // Top horizontal line
                            path.addLine(to: CGPoint(x: rangeStart + rangeWidth - cornerRadius, y: 0))
                            // Top right corner
                            path.addArc(center: CGPoint(x: rangeStart + rangeWidth - cornerRadius, y: cornerRadius),
                                       radius: cornerRadius,
                                       startAngle: .degrees(270),
                                       endAngle: .degrees(0),
                                       clockwise: false)
                            // Right vertical line
                            path.addLine(to: CGPoint(x: rangeStart + rangeWidth, y: height))
                        }
                        .stroke(Color.trainPrimary, lineWidth: 2)
                    }
                }
                .frame(height: 40)

                // Days numbers
                HStack {
                    ForEach(1...6, id: \.self) { day in
                        Text("\(day)")
                            .font(.trainBodyMedium)
                            .foregroundColor(trainingDays == day ? .trainPrimary : .trainTextSecondary)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.top, Spacing.xs)

                // Slider track
                GeometryReader { geometry in
                    let segmentWidth = geometry.size.width / 6  // 6 equal segments for 6 positions (1-6 days)
                    let circlePosition = (CGFloat(trainingDays - 1) * segmentWidth) + (segmentWidth / 2)

                    ZStack(alignment: .leading) {
                        // Background line (full width)
                        Rectangle()
                            .fill(Color.trainBorder)
                            .frame(height: 4)
                            .cornerRadius(2)

                        // Orange filled portion up to selected value
                        Rectangle()
                            .fill(Color.trainPrimary)
                            .frame(width: circlePosition, height: 4)
                            .cornerRadius(2)

                        // Draggable circle
                        Circle()
                            .fill(Color.trainPrimary)
                            .frame(width: 24, height: 24)
                            .offset(x: circlePosition - 12)
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        // Calculate which day position the drag is closest to
                                        let newPosition = max(0, min(value.location.x, geometry.size.width))
                                        let dayIndex = Int(round((newPosition - segmentWidth / 2) / segmentWidth))
                                        let newDays = min(6, max(1, dayIndex + 1))
                                        if newDays != trainingDays {
                                            trainingDays = newDays
                                        }
                                    }
                            )
                    }
                }
                .frame(height: 30)
            }

            // Warning box for out-of-range selections
            if isOutsideRecommendedRange {
                VStack(spacing: Spacing.sm) {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.orange)

                        Text("Training Frequency Warning")
                            .font(.trainCaption)
                            .foregroundColor(.orange)

                        Spacer()
                    }

                    Text(warningMessage)
                        .font(.trainBody)
                        .foregroundColor(.trainTextPrimary)
                        .multilineTextAlignment(.leading)
                }
                .padding(Spacing.md)
                .background(Color.orange.opacity(0.1))
                .appCard()
            }

            // Split suggestion based on days selected
            VStack(spacing: Spacing.sm) {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.trainPrimary)

                    Text("Your program will be:")
                        .font(.trainCaption)
                        .foregroundColor(.trainTextSecondary)

                    Spacer()
                }

                Text(splitSuggestion)
                    .font(.trainBodyMedium)
                    .foregroundColor(.trainTextPrimary)
            }
            .padding(Spacing.md)
            .appCard()

            Spacer()
        }
    }

    // Split suggestion text based on days selected
    private var splitSuggestion: String {
        switch trainingDays {
        case 1:
            return "Full Body (1x per week)"
        case 2:
            return "Upper/Lower or Full Body (2x per week)"
        case 3:
            return "Push/Pull/Legs (1x per week each)"
        case 4:
            return "Upper/Lower (2x per week each)"
        case 5:
            return "Push/Pull/Legs + Upper/Lower hybrid"
        case 6:
            return "Push/Pull/Legs (2x per week each)"
        default:
            return "Custom split"
        }
    }
}

// MARK: - Q11: Split Selection
struct SplitSelectionStepView: View {
    @Binding var selectedSplit: String
    @Binding var trainingDays: Int
    @Binding var experience: String
    @Binding var targetMuscleGroups: [String]

    // Load split templates from JSON
    @State private var splitTemplates: [String: [String: Any]] = [:]

    // Get available splits for current day count
    private var availableSplits: [String] {
        let dayKey = "\(trainingDays)-day"
        guard let daysData = splitTemplates[dayKey] as? [String: Any] else {
            return []
        }
        return Array(daysData.keys).sorted()
    }

    // Generate brief explanation for each split
    private func splitExplanation(for splitName: String) -> String {
        switch splitName {
        case "Full Body":
            return "Hit every muscle group in one efficient session. Perfect for maintaining strength and fitness with a busy schedule."
        case "Full Body x2":
            return "Train your whole body twice per week for balanced development. Great for building a foundation or fitting fitness around a packed schedule."
        case "Upper Lower":
            return "Dedicate one day to upper body, one to lower. Allows more focus on each area while keeping things simple."
        case "Push Pull Legs":
            return "Organise training by movement pattern: pushing, pulling, and legs. Lets you train harder on each muscle with more recovery time between sessions."
        case "Full Body x3":
            return "Hit every muscle group three times per week. Higher frequency means faster skill development and consistent progress."
        case "2 Upper 1 Lower":
            return "Two upper body sessions and one lower. Ideal if building your upper body is a priority right now."
        case "1 Upper 2 Lower":
            return "One upper body session and two lower. Perfect if you're focusing on building stronger legs and glutes."
        case "Upper Lower x2":
            return "Train upper and lower body twice each per week. A proven split that balances volume, intensity, and recovery."
        case "PPL Upper Lower":
            return "Combines Push/Pull/Legs with an Upper/Lower split. Gives you the best of both approaches with optimal training frequency."
        case "Push Pull Legs x2":
            return "Push/Pull/Legs twice per week for maximum volume. Best suited for experienced lifters ready to commit to serious training."
        default:
            return "Balanced training split"
        }
    }

    // Check if a split is recommended
    private func isRecommended(_ splitName: String) -> Bool {
        switch trainingDays {
        case 2:
            if experience == "no_experience" || experience == "beginner" {
                return splitName == "Full Body x2"
            } else {
                return splitName == "Upper Lower"
            }
        case 3:
            if experience == "no_experience" || experience == "beginner" {
                return splitName == "Full Body x3"
            } else {
                // Check for muscle priority overrides
                let upperMuscles = ["Chest", "Shoulders", "Back", "Biceps", "Triceps", "Traps"]
                let lowerMuscles = ["Quads", "Hamstrings", "Glutes", "Calves", "Abductors", "Adductors"]

                // Check if ALL priority muscles are lower body
                let allPriorityMusclesAreLower = !targetMuscleGroups.isEmpty &&
                    targetMuscleGroups.allSatisfy { lowerMuscles.contains($0) }

                // Check if ALL priority muscles are upper body
                let allPriorityMusclesAreUpper = !targetMuscleGroups.isEmpty &&
                    targetMuscleGroups.allSatisfy { upperMuscles.contains($0) }

                if allPriorityMusclesAreLower {
                    return splitName == "1 Upper 2 Lower"
                } else if allPriorityMusclesAreUpper {
                    return splitName == "2 Upper 1 Lower"
                } else {
                    return splitName == "Push Pull Legs"
                }
            }
        default:
            return false
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            VStack(alignment: .center, spacing: Spacing.sm) {
                Text("Choose your training split")
                    .font(.trainTitle2)
                    .foregroundColor(.trainTextPrimary)
                    .multilineTextAlignment(.center)

                Text("Based on your \(trainingDays)-day schedule")
                    .font(.trainSubtitle)
                    .foregroundColor(.trainTextSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)

            VStack(spacing: Spacing.md) {
                // First show recommended splits
                ForEach(availableSplits.filter { isRecommended($0) }, id: \.self) { splitName in
                    SplitOptionCard(
                        title: splitName,
                        subtitle: splitExplanation(for: splitName),
                        isSelected: selectedSplit == splitName,
                        isRecommended: true,
                        action: { selectedSplit = splitName }
                    )
                }

                // Then show other splits
                ForEach(availableSplits.filter { !isRecommended($0) }, id: \.self) { splitName in
                    SplitOptionCard(
                        title: splitName,
                        subtitle: splitExplanation(for: splitName),
                        isSelected: selectedSplit == splitName,
                        isRecommended: false,
                        action: { selectedSplit = splitName }
                    )
                }
            }

            Spacer()
        }
        .onAppear {
            loadSplitTemplates()
        }
    }

    private func loadSplitTemplates() {
        guard let path = Bundle.main.path(forResource: "split_templates", ofType: "json"),
              let data = NSData(contentsOfFile: path),
              let json = try? JSONSerialization.jsonObject(with: data as Data, options: []) as? [String: [String: Any]] else {
            AppLogger.logUI("Failed to load split_templates.json", level: .error)
            return
        }
        splitTemplates = json
    }
}

// MARK: - Split Option Card
struct SplitOptionCard: View {
    let title: String
    let subtitle: String
    let isSelected: Bool
    let isRecommended: Bool
    let action: () -> Void

    var body: some View {
        ZStack(alignment: .topLeading) {
            Button(action: action) {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text(title)
                        .font(.trainBodyMedium)
                        .foregroundColor(isSelected ? .white : .trainTextPrimary)
                        .multilineTextAlignment(.leading)

                    Text(subtitle)
                        .font(.trainCaption)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .trainTextSecondary)
                        .multilineTextAlignment(.leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Spacing.md)
                .background(isSelected ? Color.trainPrimary : .clear)
                .appCard()
            }
            .buttonStyle(ScaleButtonStyle())

            // Recommended label
            if isRecommended {
                Text("Recommended")
                    .font(.trainCaption)
                    .foregroundColor(.white)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, 4)
                    .background(Color.trainPrimary)
                    .cornerRadius(8)
                    .offset(x: 12, y: -8)
            }
        }
    }
}

// MARK: - Q12: Session Duration
struct SessionDurationStepView: View {
    @Binding var sessionDuration: String

    let durations = [
        ("30-45 min", "30-45 minutes", "Quick and efficient"),
        ("45-60 min", "45-60 minutes", "Balanced approach"),
        ("60-90 min", "60-90 minutes", "Maximum volume")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            VStack(alignment: .center, spacing: Spacing.sm) {
                Text("How long can you spend per session?")
                    .font(.trainTitle2)
                    .foregroundColor(.trainTextPrimary)
                    .multilineTextAlignment(.center)

                Text("This affects the number of exercises in your program")
                    .font(.trainSubtitle)
                    .foregroundColor(.trainTextSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)

            VStack(spacing: Spacing.md) {
                ForEach(durations, id: \.0) { value, title, subtitle in
                    OptionCard(
                        title: title,
                        subtitle: subtitle,
                        isSelected: sessionDuration == value,
                        action: { sessionDuration = value }
                    )
                }
            }

            Spacer()
        }
    }
}

// MARK: - Q12: Injuries/Limitations
struct InjuriesStepView: View {
    @Binding var injuries: [String]

    // Muscle group injury options - matches database injury_type values
    // These correspond to primary_muscle values in exercises table
    let injuryOptions = [
        ["Chest", "Back"],
        ["Shoulders", "Triceps"],
        ["Biceps", "Quads"],
        ["Hamstrings", "Glutes"],
        ["Calves", "Core"]
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            VStack(alignment: .center, spacing: Spacing.sm) {
                Text("Do you have any injuries?")
                    .font(.trainTitle2)
                    .foregroundColor(.trainTextPrimary)
                    .multilineTextAlignment(.center)

                Text("We'll avoid exercises that might aggravate these areas")
                    .font(.trainSubtitle)
                    .foregroundColor(.trainTextSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)

            VStack(spacing: Spacing.md) {
                // Two column grid for body parts
                ForEach(injuryOptions, id: \.self) { row in
                    HStack(spacing: Spacing.md) {
                        ForEach(row, id: \.self) { injury in
                            Button(action: { toggleInjury(injury) }) {
                                Text(injury)
                                    .font(.trainBodyMedium)
                                    .foregroundColor(injuries.contains(injury) ? .white : .trainTextPrimary)
                                    .frame(maxWidth: .infinity)
                                    .padding(Spacing.md)
                                    .background(injuries.contains(injury) ? Color.trainPrimary : .clear)
                                    .appCard(cornerRadius: CornerRadius.md)
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                        // Add empty spacer if odd number in row
                        if row.count == 1 {
                            Color.clear.frame(maxWidth: .infinity)
                        }
                    }
                }

                // None option - spans full width
                Button(action: { injuries = [] }) {
                    Text("No injuries")
                        .font(.trainBodyMedium)
                        .foregroundColor(injuries.isEmpty ? .white : .trainTextPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(Spacing.md)
                        .background(injuries.isEmpty ? Color.trainPrimary : .clear)
                        .appCard(cornerRadius: CornerRadius.md)
                }
                .buttonStyle(ScaleButtonStyle())
            }

            Spacer()
        }
    }

    private func toggleInjury(_ injury: String) {
        if injuries.contains(injury) {
            injuries.removeAll { $0 == injury }
        } else {
            injuries.append(injury)
        }
    }
}

// MARK: - Helper Extension for Rounded Corners
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
