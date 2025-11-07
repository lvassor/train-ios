//
//  QuestionnaireSteps.swift
//  trAInApp
//
//  Individual questionnaire step views (Q1-Q10)
//

import SwiftUI
import UIKit
import SlidingRuler

// MARK: - Q1: Gender
struct GenderStepView: View {
    @Binding var selectedGender: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Gender")
                    .font(.trainTitle2)
                    .foregroundColor(.trainTextPrimary)

                Text("We may require this for exercise prescription")
                    .font(.trainSubtitle)
                    .foregroundColor(.trainTextSecondary)
            }

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
                        .background(selectedGender == "Male" ? Color.trainPrimary : Color.white)
                        .cornerRadius(CornerRadius.md)
                        .overlay(
                            RoundedRectangle(cornerRadius: CornerRadius.md)
                                .stroke(selectedGender == "Male" ? Color.clear : Color.trainBorder, lineWidth: 1)
                        )
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
                        .background(selectedGender == "Female" ? Color.trainPrimary : Color.white)
                        .cornerRadius(CornerRadius.md)
                        .overlay(
                            RoundedRectangle(cornerRadius: CornerRadius.md)
                                .stroke(selectedGender == "Female" ? Color.clear : Color.trainBorder, lineWidth: 1)
                        )
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
                    .background(selectedGender == "Other / Prefer not to say" ? Color.trainPrimary : Color.white)
                    .cornerRadius(CornerRadius.md)
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .stroke(selectedGender == "Other / Prefer not to say" ? Color.clear : Color.trainBorder, lineWidth: 1)
                    )
                }
                .buttonStyle(ScaleButtonStyle())
            }

            Spacer()
        }
        .padding(.horizontal, Spacing.lg)
    }
}

// MARK: - Q2: Age
struct AgeStepView: View {
    @Binding var age: Int

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Age")
                    .font(.trainTitle2)
                    .foregroundColor(.trainTextPrimary)

                Text("This helps us tailor your training intensity")
                    .font(.trainSubtitle)
                    .foregroundColor(.trainTextSecondary)
            }
            .padding(.horizontal, Spacing.lg)

            // Age Scroller Picker
            AgeScrollerPicker(age: $age)

            if age > 0 && age < 18 {
                Text("You must be at least 18 years old")
                    .font(.trainCaption)
                    .foregroundColor(.red)
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
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Height")
                    .font(.trainTitle2)
                    .foregroundColor(.trainTextPrimary)

                Text("This helps us calculate your body metrics")
                    .font(.trainSubtitle)
                    .foregroundColor(.trainTextSecondary)
            }
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
                        .background(unit == .cm ? Color.trainPrimary : Color.white)
                        .cornerRadius(CornerRadius.sm)
                        .overlay(
                            RoundedRectangle(cornerRadius: CornerRadius.sm)
                                .stroke(Color.trainBorder, lineWidth: 1)
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
                        .background(unit == .ftIn ? Color.trainPrimary : Color.white)
                        .cornerRadius(CornerRadius.sm)
                        .overlay(
                            RoundedRectangle(cornerRadius: CornerRadius.sm)
                                .stroke(Color.trainBorder, lineWidth: 1)
                        )
                }
            }
            .frame(maxWidth: .infinity)

            // Sliding Ruler for Height
            if unit == .cm {
                VStack(spacing: Spacing.md) {
                    // Display current value
                    Text("\(Int(heightCm))")
                        .font(.system(size: 56, weight: .bold))
                        .foregroundColor(.trainPrimary)
                        .frame(height: 80)

                    Text("cm")
                        .font(.trainTitle)
                        .foregroundColor(.trainTextSecondary)
                        .offset(y: -20)

                    // SlidingRuler
                    SlidingRuler(
                        value: $heightCm,
                        bounds: 120...220,
                        step: 1,
                        snap: .unit,
                        tick: .unit
                    )
                    .frame(height: 60)
                    .padding(.horizontal, Spacing.lg)
                    .onChange(of: heightCm) { _, newValue in
                        let totalInches = newValue / 2.54
                        heightFt = Int(totalInches / 12)
                        heightIn = Int(totalInches.truncatingRemainder(dividingBy: 12))
                    }
                }
            } else {
                // For ft/in, we'll use a combined height in cm and display conversion
                VStack(spacing: Spacing.md) {
                    let combinedHeightCm = Double(heightFt) * 30.48 + Double(heightIn) * 2.54

                    HStack(spacing: Spacing.sm) {
                        Text("\(heightFt)")
                            .font(.trainLargeNumber)
                            .foregroundColor(.trainPrimary)
                        Text("ft")
                            .font(.trainTitle)
                            .foregroundColor(.trainTextSecondary)

                        Text("\(heightIn)")
                            .font(.trainLargeNumber)
                            .foregroundColor(.trainPrimary)
                        Text("in")
                            .font(.trainTitle)
                            .foregroundColor(.trainTextSecondary)
                    }
                    .frame(height: 80)

                    HStack(spacing: Spacing.lg) {
                        // Feet picker
                        VStack {
                            Text("Feet")
                                .font(.trainCaption)
                                .foregroundColor(.trainTextSecondary)
                            Picker("Feet", selection: $heightFt) {
                                ForEach(3...8, id: \.self) { ft in
                                    Text("\(ft)").tag(ft)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 80, height: 120)
                            .onChange(of: heightFt) { _, _ in
                                heightCm = Double(heightFt) * 30.48 + Double(heightIn) * 2.54
                            }
                        }

                        // Inches picker
                        VStack {
                            Text("Inches")
                                .font(.trainCaption)
                                .foregroundColor(.trainTextSecondary)
                            Picker("Inches", selection: $heightIn) {
                                ForEach(0...11, id: \.self) { inches in
                                    Text("\(inches)").tag(inches)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 80, height: 120)
                            .onChange(of: heightIn) { _, _ in
                                heightCm = Double(heightFt) * 30.48 + Double(heightIn) * 2.54
                            }
                        }
                    }
                    .background(Color.white)
                    .cornerRadius(CornerRadius.md)
                }
                .padding(.horizontal, Spacing.lg)
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
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Weight")
                    .font(.trainTitle2)
                    .foregroundColor(.trainTextPrimary)

                Text("This helps us calculate your body metrics")
                    .font(.trainSubtitle)
                    .foregroundColor(.trainTextSecondary)
            }
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
                        .background(unit == .kg ? Color.trainPrimary : Color.white)
                        .cornerRadius(CornerRadius.sm)
                        .overlay(
                            RoundedRectangle(cornerRadius: CornerRadius.sm)
                                .stroke(Color.trainBorder, lineWidth: 1)
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
                        .background(unit == .lbs ? Color.trainPrimary : Color.white)
                        .cornerRadius(CornerRadius.sm)
                        .overlay(
                            RoundedRectangle(cornerRadius: CornerRadius.sm)
                                .stroke(Color.trainBorder, lineWidth: 1)
                        )
                }
            }
            .frame(maxWidth: .infinity)

            // Sliding Ruler for Weight
            if unit == .kg {
                VStack(spacing: Spacing.md) {
                    // Display current value
                    HStack(alignment: .lastTextBaseline, spacing: Spacing.xs) {
                        Text(String(format: "%.1f", weightKg))
                            .font(.system(size: 56, weight: .bold))
                            .foregroundColor(.trainPrimary)
                        Text("kg")
                            .font(.trainTitle)
                            .foregroundColor(.trainTextSecondary)
                    }
                    .frame(height: 80)

                    // SlidingRuler
                    SlidingRuler(
                        value: $weightKg,
                        bounds: 30...200,
                        step: 0.5,
                        snap: .half,
                        tick: .unit
                    )
                    .frame(height: 60)
                    .padding(.horizontal, Spacing.lg)
                    .onChange(of: weightKg) { _, newValue in
                        weightLbs = newValue * 2.20462
                    }
                }
            } else {
                VStack(spacing: Spacing.md) {
                    // Display current value
                    HStack(alignment: .lastTextBaseline, spacing: Spacing.xs) {
                        Text(String(format: "%.1f", weightLbs))
                            .font(.system(size: 56, weight: .bold))
                            .foregroundColor(.trainPrimary)
                        Text("lbs")
                            .font(.trainTitle)
                            .foregroundColor(.trainTextSecondary)
                    }
                    .frame(height: 80)

                    // SlidingRuler
                    SlidingRuler(
                        value: $weightLbs,
                        bounds: 65...440,
                        step: 1,
                        snap: .unit,
                        tick: .unit
                    )
                    .frame(height: 60)
                    .padding(.horizontal, Spacing.lg)
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
    @Binding var selectedGoal: String

    let goals = [
        ("get_stronger", "Get Stronger", "Build maximum strength & power"),
        ("build_muscle", "Build Muscle Mass", "Both size and definition"),
        ("tone_up", "Tone Up", "Lose fat while building muscle")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("What are your primary goals?")
                    .font(.trainTitle2)
                    .foregroundColor(.trainTextPrimary)

                Text("Let's customise your training programme")
                    .font(.trainSubtitle)
                    .foregroundColor(.trainTextSecondary)
            }

            VStack(spacing: Spacing.md) {
                ForEach(goals, id: \.0) { value, title, subtitle in
                    OptionCard(
                        title: title,
                        subtitle: subtitle,
                        isSelected: selectedGoal == value,
                        action: { selectedGoal = value }
                    )
                }
            }

            Spacer()
        }
        .padding(.horizontal, Spacing.lg)
    }
}

// MARK: - Q6: Muscle Groups
struct MuscleGroupsStepView: View {
    @Binding var selectedGroups: [String]

    let muscleGroups = [
        ["Chest", "Shoulders"],
        ["Back", "Triceps"],
        ["Biceps", "Abs"],
        ["Quads", "Hamstrings"],
        ["Glutes", "Calves"]
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Which muscle groups do you want to prioritise?")
                    .font(.trainTitle2)
                    .foregroundColor(.trainTextPrimary)

                Text("Select up to 3 muscle groups")
                    .font(.trainSubtitle)
                    .foregroundColor(.trainTextSecondary)
            }

            VStack(spacing: Spacing.md) {
                ForEach(muscleGroups, id: \.self) { row in
                    HStack(spacing: Spacing.md) {
                        ForEach(row, id: \.self) { group in
                            MuscleGroupButton(
                                title: group,
                                isSelected: selectedGroups.contains(group),
                                action: { toggleGroup(group) }
                            )
                        }
                    }
                }

                if selectedGroups.count > 0 {
                    Text("\(selectedGroups.count) of 3 selected")
                        .font(.trainCaption)
                        .foregroundColor(.trainTextSecondary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }

            Spacer()
        }
        .padding(.horizontal, Spacing.lg)
    }

    private func toggleGroup(_ group: String) {
        if selectedGroups.contains(group) {
            selectedGroups.removeAll { $0 == group }
        } else if selectedGroups.count < 3 {
            selectedGroups.append(group)
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
                .background(isSelected ? Color.trainPrimary : Color.white)
                .cornerRadius(CornerRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .stroke(isSelected ? Color.clear : Color.trainBorder, lineWidth: 1)
                )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Q7: Experience
struct ExperienceStepView: View {
    @Binding var experience: String

    let experiences = [
        ("0_months", "0 months", "Complete beginner"),
        ("0_6_months", "0-6 months", "Learning the basics"),
        ("6_months_2_years", "6 months - 2 years", "Starting to find your feet"),
        ("2_plus_years", "2+ years", "Feeling confident")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("What's your current experience with strength training?")
                    .font(.trainTitle2)
                    .foregroundColor(.trainTextPrimary)

                Text("This helps us set the right difficulty level")
                    .font(.trainSubtitle)
                    .foregroundColor(.trainTextSecondary)
            }

            VStack(spacing: Spacing.md) {
                ForEach(experiences, id: \.0) { value, title, subtitle in
                    OptionCard(
                        title: title,
                        subtitle: subtitle,
                        isSelected: experience == value,
                        action: { experience = value }
                    )
                }
            }

            Spacer()
        }
        .padding(.horizontal, Spacing.lg)
    }
}

// MARK: - Q8: Motivation
struct MotivationStepView: View {
    @Binding var selectedMotivations: [String]
    @Binding var otherText: String

    let motivations = [
        ("lack_structure", "I lack structure in the gym"),
        ("lack_knowledge", "I lack knowledge in the gym"),
        ("lack_confidence", "I lack confidence in the gym"),
        ("need_motivation", "I need more motivation"),
        ("need_accountability", "I need more accountability"),
        ("other", "Other")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Why have you considered using this app?")
                    .font(.trainTitle2)
                    .foregroundColor(.trainTextPrimary)

                Text("Select all that apply")
                    .font(.trainSubtitle)
                    .foregroundColor(.trainTextSecondary)
            }

            VStack(spacing: Spacing.md) {
                ForEach(motivations, id: \.0) { value, title in
                    MultiSelectCard(
                        title: title,
                        isSelected: selectedMotivations.contains(value),
                        action: { toggleMotivation(value) }
                    )
                }

                if selectedMotivations.contains("other") {
                    TextField("Please specify", text: $otherText)
                        .font(.trainBody)
                        .padding(Spacing.md)
                        .background(Color.white)
                        .cornerRadius(CornerRadius.md)
                        .overlay(
                            RoundedRectangle(cornerRadius: CornerRadius.md)
                                .stroke(Color.trainPrimary, lineWidth: 2)
                        )
                }
            }

            Spacer()
        }
        .padding(.horizontal, Spacing.lg)
    }

    private func toggleMotivation(_ motivation: String) {
        if selectedMotivations.contains(motivation) {
            selectedMotivations.removeAll { $0 == motivation }
            if motivation == "other" {
                otherText = ""
            }
        } else {
            selectedMotivations.append(motivation)
        }
    }
}

// MARK: - Q9: Equipment
struct EquipmentStepView: View {
    @Binding var selectedEquipment: [String]

    let equipment = [
        ("bodyweight", "Bodyweight only"),
        ("dumbbells", "Dumbbells"),
        ("barbells", "Barbells"),
        ("cable_machines", "Cable machines"),
        ("pin_loaded", "Pin-loaded machines"),
        ("plate_loaded", "Plate-loaded machines"),
        ("kettlebells", "Kettlebells")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("What equipment do you have at your availability?")
                    .font(.trainTitle2)
                    .foregroundColor(.trainTextPrimary)

                Text("Select all that apply")
                    .font(.trainSubtitle)
                    .foregroundColor(.trainTextSecondary)
            }

            VStack(spacing: Spacing.md) {
                ForEach(equipment, id: \.0) { value, title in
                    MultiSelectCard(
                        title: title,
                        isSelected: selectedEquipment.contains(value),
                        action: { toggleEquipment(value) }
                    )
                }
            }

            Spacer()
        }
        .padding(.horizontal, Spacing.lg)
    }

    private func toggleEquipment(_ item: String) {
        if selectedEquipment.contains(item) {
            selectedEquipment.removeAll { $0 == item }
        } else {
            selectedEquipment.append(item)
        }
    }
}

// MARK: - Q10: Training Days
struct TrainingDaysStepView: View {
    @Binding var trainingDays: Int

    let dayOptions = [2, 3, 4, 5]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("How many days per week would you like to train?")
                    .font(.trainTitle2)
                    .foregroundColor(.trainTextPrimary)

                Text("Be realistic with your commitment")
                    .font(.trainSubtitle)
                    .foregroundColor(.trainTextSecondary)
            }

            HStack(spacing: Spacing.md) {
                ForEach(dayOptions, id: \.self) { days in
                    Button(action: { trainingDays = days }) {
                        VStack(spacing: Spacing.sm) {
                            Text("\(days)")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(trainingDays == days ? .white : .trainPrimary)

                            Text("days")
                                .font(.trainCaption)
                                .foregroundColor(trainingDays == days ? .white : .trainTextSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.lg)
                        .background(trainingDays == days ? Color.trainPrimary : Color.white)
                        .cornerRadius(CornerRadius.md)
                        .overlay(
                            RoundedRectangle(cornerRadius: CornerRadius.md)
                                .stroke(trainingDays == days ? Color.clear : Color.trainBorder, lineWidth: 1)
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }

            Spacer()
        }
        .padding(.horizontal, Spacing.lg)
    }
}

// MARK: - Q11: Session Duration
struct SessionDurationStepView: View {
    @Binding var sessionDuration: String

    let durations = [
        ("30-45 min", "30-45 minutes", "Quick and efficient"),
        ("45-60 min", "45-60 minutes", "Balanced approach"),
        ("60-90 min", "60-90 minutes", "Maximum volume")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("How long can you spend per session?")
                    .font(.trainTitle2)
                    .foregroundColor(.trainTextPrimary)

                Text("This affects the number of exercises in your program")
                    .font(.trainSubtitle)
                    .foregroundColor(.trainTextSecondary)
            }

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
        .padding(.horizontal, Spacing.lg)
    }
}

// MARK: - Q12: Injuries/Limitations
struct InjuriesStepView: View {
    @Binding var injuries: [String]

    let injuryOptions = [
        "Lower Back",
        "Shoulder",
        "Knee",
        "Wrist",
        "Elbow",
        "Hip",
        "Neck",
        "Ankle"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Do you have any current injuries or limitations?")
                    .font(.trainTitle2)
                    .foregroundColor(.trainTextPrimary)

                Text("We'll avoid exercises that may aggravate these areas")
                    .font(.trainSubtitle)
                    .foregroundColor(.trainTextSecondary)
            }

            VStack(spacing: Spacing.md) {
                ForEach(injuryOptions, id: \.self) { injury in
                    MultiSelectCard(
                        title: injury,
                        isSelected: injuries.contains(injury),
                        action: { toggleInjury(injury) }
                    )
                }

                // None option
                Button(action: { injuries = [] }) {
                    HStack {
                        Image(systemName: injuries.isEmpty ? "checkmark.circle.fill" : "circle")
                            .font(.title3)
                            .foregroundColor(injuries.isEmpty ? .trainPrimary : .trainBorder)

                        Text("No injuries or limitations")
                            .font(.trainBody)
                            .foregroundColor(.trainTextPrimary)

                        Spacer()
                    }
                    .padding(Spacing.md)
                    .background(Color.white)
                    .cornerRadius(CornerRadius.md)
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .stroke(injuries.isEmpty ? Color.trainPrimary : Color.trainBorder, lineWidth: injuries.isEmpty ? 2 : 1)
                    )
                }
                .buttonStyle(ScaleButtonStyle())
            }

            Spacer()
        }
        .padding(.horizontal, Spacing.lg)
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
