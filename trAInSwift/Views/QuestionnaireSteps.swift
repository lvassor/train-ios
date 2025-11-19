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
                        .glassCard()
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
                        .glassCard()
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
                    .glassCard()
                }
                .buttonStyle(ScaleButtonStyle())
            }

            Spacer()
        }
    }
}

// MARK: - Q2: Age
struct AgeStepView: View {
    @Binding var age: Int

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            VStack(alignment: .center, spacing: Spacing.sm) {
                Text("Age")
                    .font(.trainTitle2)
                    .foregroundColor(.trainTextPrimary)

                Text("This helps us tailor your training intensity")
                    .font(.trainSubtitle)
                    .foregroundColor(.trainTextSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
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
                        snap: .unit,
                        tick: .unit  // Major ticks every 10 units
                    )
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
                        snap: .unit,
                        tick: .unit  // Major ticks every 1 foot
                    )
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
                        snap: .unit,
                        tick: .unit  // Major ticks every 10 units
                    )
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
                        snap: .unit,
                        tick: .unit  // Major ticks every 20 units
                    )
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
    @Binding var selectedGoal: String

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

                Text("Let's customise your training program")
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
                        isSelected: selectedGoal == value,
                        action: { selectedGoal = value }
                    )
                }
            }

            Spacer()
        }
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
            VStack(alignment: .center, spacing: Spacing.sm) {
                Text("Which muscle groups do you want to prioritise?")
                    .font(.trainTitle2)
                    .foregroundColor(.trainTextPrimary)
                    .multilineTextAlignment(.center)

                Text("Select up to 3 muscle groups")
                    .font(.trainSubtitle)
                    .foregroundColor(.trainTextSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)

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
                .background(isSelected ? Color.trainPrimary : .clear)
                .glassCard(cornerRadius: CornerRadius.md)
                .shadow(color: isSelected ? Color.trainPrimary.opacity(0.4) : .clear, radius: 16, x: 0, y: 0)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Q7: Experience
struct ExperienceStepView: View {
    @Binding var experience: String

    let experiences = [
        ("0_months", "0 months", "Complete beginner"),
        ("0_6_months", "0 - 6 months", "Learning the basics"),
        ("6_months_2_years", "6 months - 2 years", "Starting to find your feet"),
        ("2_plus_years", "2+ years", "Feeling confident")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            VStack(alignment: .center, spacing: Spacing.sm) {
                Text("What's your current experience with strength training?")
                    .font(.trainTitle2)
                    .foregroundColor(.trainTextPrimary)
                    .multilineTextAlignment(.center)

                Text("This helps us set the right difficulty level")
                    .font(.trainSubtitle)
                    .foregroundColor(.trainTextSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)

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
    }
}

// MARK: - Q8: Motivation
struct MotivationStepView: View {
    @Binding var selectedMotivations: [String]
    @Binding var otherText: String

    let motivations = [
        ("lack_structure", "I lack structure in my workouts"),
        ("need_guidance", "I need more guidance"),
        ("lack_confidence", "I lack confidence when I exercise"),
        ("need_motivation", "I need motivation"),
        ("need_accountability", "I need accountability"),
        ("other", "Other")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            VStack(alignment: .center, spacing: Spacing.sm) {
                Text("Why have you considered using this app?")
                    .font(.trainTitle2)
                    .foregroundColor(.trainTextPrimary)
                    .multilineTextAlignment(.center)

                Text("Select all that apply")
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
                        isCompact: true,  // Use compact version
                        action: { toggleMotivation(value) }
                    )
                }

                if selectedMotivations.contains("other") {
                    TextField("Please specify", text: $otherText)
                        .font(.trainBody)
                        .padding(Spacing.md)
                        .glassCard()
                }
            }

            Spacer()
        }
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
    @State private var showingEquipmentInfo: String?

    let equipment = [
        ("dumbbells", "Dumbbells"),
        ("barbells", "Barbells"),
        ("kettlebells", "Kettlebells"),
        ("cable_machines", "Cable Machines"),
        ("pin_loaded", "Pin-loaded Machines"),
        ("plate_loaded", "Plate-loaded Machines")
    ]

    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                VStack(alignment: .center, spacing: Spacing.sm) {
                    Text("What equipment do you have at your availability?")
                        .font(.trainTitle2)
                        .foregroundColor(.trainTextPrimary)
                        .multilineTextAlignment(.center)

                    Text("Select all that apply")
                        .font(.trainSubtitle)
                        .foregroundColor(.trainTextSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: Spacing.md) {
                    ForEach(equipment, id: \.0) { value, title in
                        EquipmentCard(
                            title: title,
                            isSelected: selectedEquipment.contains(value),
                            onSelect: { toggleEquipment(value) },
                            onInfo: { showingEquipmentInfo = value }
                        )
                    }
                }

                Spacer()
            }
            .padding(.horizontal, Spacing.lg)

            // Equipment Info Modal
            if let equipmentType = showingEquipmentInfo {
                EquipmentInfoModal(
                    equipmentType: equipmentType,
                    onDismiss: { showingEquipmentInfo = nil }
                )
            }
        }
    }

    private func toggleEquipment(_ item: String) {
        if selectedEquipment.contains(item) {
            selectedEquipment.removeAll { $0 == item }
        } else {
            selectedEquipment.append(item)
        }
    }
}

// MARK: - Equipment Card with Info Button

struct EquipmentCard: View {
    let title: String
    let isSelected: Bool
    let onSelect: () -> Void
    let onInfo: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack {
                Text(title)
                    .font(.trainBodyMedium)
                    .foregroundColor(isSelected ? .white : .trainTextPrimary)

                Spacer()

                Button(action: {
                    onInfo()
                }) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 20))
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .trainTextSecondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(Spacing.md)
            .background(isSelected ? Color.trainPrimary : .clear)
            .glassCard(cornerRadius: CornerRadius.md)
            .shadow(color: isSelected ? Color.trainPrimary.opacity(0.4) : .clear, radius: 16, x: 0, y: 0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Equipment Info Modal

struct EquipmentInfoModal: View {
    let equipmentType: String
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }

            // Modal card
            VStack(spacing: 0) {
                // Image placeholder (top 40%)
                ZStack {
                    Color.trainTextSecondary.opacity(0.1)

                    Image(systemName: equipmentIcon)
                        .font(.system(size: 80))
                        .foregroundColor(.trainPrimary)
                }
                .frame(height: 200)

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
                .padding(Spacing.lg)
            }
            .frame(width: 320, height: 480)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(radius: 20)
            .overlay(
                // Close button
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.trainTextPrimary)
                        .frame(width: 32, height: 32)
                        .background(Color.trainBackground)
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

    let dayOptions = [2, 3, 4, 5]

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

            HStack(spacing: Spacing.md) {
                ForEach(dayOptions, id: \.self) { days in
                    Button(action: { trainingDays = days }) {
                        VStack(spacing: Spacing.sm) {
                            Text("\(days)")
                                .font(.trainMediumNumber)  // Using new rounded number font
                                .foregroundColor(trainingDays == days ? .white : .trainPrimary)

                            Text("days")
                                .font(.trainBody)
                                .foregroundColor(trainingDays == days ? .white : .trainTextSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.lg)
                        .background(trainingDays == days ? Color.trainPrimary : .clear)
                        .glassCard()
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }

            Spacer()
        }
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
            VStack(alignment: .center, spacing: Spacing.sm) {
                Text("Do you have any current injuries or limitations?")
                    .font(.trainTitle2)
                    .foregroundColor(.trainTextPrimary)
                    .multilineTextAlignment(.center)

                Text("Select any that may impact your training")
                    .font(.trainSubtitle)
                    .foregroundColor(.trainTextSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)

            VStack(spacing: Spacing.md) {
                // Two column grid for injury options
                let columns = [GridItem(.flexible()), GridItem(.flexible())]
                LazyVGrid(columns: columns, spacing: Spacing.md) {
                    ForEach(injuryOptions, id: \.self) { injury in
                        MultiSelectCard(
                            title: injury,
                            isSelected: injuries.contains(injury),
                            isCompact: true,
                            action: { toggleInjury(injury) }
                        )
                    }
                }

                // None option - spans full width
                Button(action: { injuries = [] }) {
                    HStack {
                        Image(systemName: injuries.isEmpty ? "checkmark.circle.fill" : "circle")
                            .font(.title3)
                            .foregroundColor(injuries.isEmpty ? .white : .trainTextSecondary)

                        Text("No injuries or limitations")
                            .font(.trainBodyMedium)
                            .foregroundColor(injuries.isEmpty ? .white : .trainTextPrimary)

                        Spacer()
                    }
                    .padding(Spacing.md)
                    .background(injuries.isEmpty ? Color.trainPrimary : .clear)
                    .glassCard(cornerRadius: CornerRadius.md)
                    .shadow(color: injuries.isEmpty ? Color.trainPrimary.opacity(0.4) : .clear, radius: 16, x: 0, y: 0)
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
