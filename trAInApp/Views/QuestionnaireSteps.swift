//
//  QuestionnaireSteps.swift
//  trAInApp
//
//  Individual questionnaire step views (Q1-Q10)
//

import SwiftUI

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

                                Image(systemName: "person.fill")
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

                                Image(systemName: "person.fill")
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

    @State private var ageText: String = ""
    @FocusState private var isFocused: Bool

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

            // Large centered age display
            HStack(spacing: Spacing.sm) {
                TextField("", text: $ageText)
                    .font(.trainLargeNumber)
                    .foregroundColor(.trainPrimary)
                    .multilineTextAlignment(.center)
                    .keyboardType(.numberPad)
                    .focused($isFocused)
                    .onChange(of: ageText) { _, newValue in
                        if let value = Int(newValue) {
                            age = value
                        } else if newValue.isEmpty {
                            age = 0
                        }
                    }

                Text("years")
                    .font(.trainTitle)
                    .foregroundColor(.trainTextSecondary)
            }
            .padding(Spacing.xl)
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .cornerRadius(CornerRadius.md)
            .onAppear {
                if age > 0 {
                    ageText = "\(age)"
                }
                isFocused = true
            }

            if age > 0 && age < 18 {
                Text("You must be at least 18 years old")
                    .font(.trainCaption)
                    .foregroundColor(.red)
            }

            Spacer()
        }
        .padding(.horizontal, Spacing.lg)
    }
}

// MARK: - Q3: Height
struct HeightStepView: View {
    @Binding var heightCm: Double
    @Binding var heightFt: Int
    @Binding var heightIn: Int
    @Binding var unit: QuestionnaireData.HeightUnit

    @State private var cmText: String = ""
    @State private var ftText: String = ""
    @State private var inText: String = ""

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

            // Unit toggle - center aligned with spacing
            HStack(spacing: Spacing.sm) {
                Button(action: { unit = .cm }) {
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

                Button(action: { unit = .ftIn }) {
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

            // Input
            if unit == .ftIn {
                HStack(alignment: .center, spacing: Spacing.lg) {
                    HStack(spacing: Spacing.sm) {
                        TextField("", text: $ftText)
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.trainPrimary)
                            .multilineTextAlignment(.center)
                            .keyboardType(.numberPad)
                            .frame(width: 80)
                            .onChange(of: ftText) { _, newValue in
                                if let value = Int(newValue) {
                                    heightFt = value
                                }
                            }

                        Text("ft")
                            .font(.trainHeadline)
                            .foregroundColor(.trainTextSecondary)
                    }

                    HStack(spacing: Spacing.sm) {
                        TextField("", text: $inText)
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.trainPrimary)
                            .multilineTextAlignment(.center)
                            .keyboardType(.numberPad)
                            .frame(width: 80)
                            .onChange(of: inText) { _, newValue in
                                if let value = Int(newValue) {
                                    heightIn = value
                                }
                            }

                        Text("in")
                            .font(.trainHeadline)
                            .foregroundColor(.trainTextSecondary)
                    }
                }
                .padding(Spacing.xl)
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .cornerRadius(CornerRadius.md)
            } else {
                HStack(spacing: Spacing.sm) {
                    TextField("", text: $cmText)
                        .font(.trainLargeNumber)
                        .foregroundColor(.trainPrimary)
                        .multilineTextAlignment(.center)
                        .keyboardType(.decimalPad)
                        .onChange(of: cmText) { _, newValue in
                            if let value = Double(newValue) {
                                heightCm = value
                            }
                        }

                    Text("cm")
                        .font(.trainTitle)
                        .foregroundColor(.trainTextSecondary)
                }
                .padding(Spacing.xl)
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .cornerRadius(CornerRadius.md)
            }

            Spacer()
        }
        .padding(.horizontal, Spacing.lg)
        .onAppear {
            if heightCm > 0 {
                cmText = String(format: "%.0f", heightCm)
            }
            if heightFt > 0 {
                ftText = "\(heightFt)"
            }
            if heightIn > 0 {
                inText = "\(heightIn)"
            }
        }
    }
}

// MARK: - Q4: Weight
struct WeightStepView: View {
    @Binding var weightKg: Double
    @Binding var weightLbs: Double
    @Binding var unit: QuestionnaireData.WeightUnit

    @State private var kgText: String = ""
    @State private var lbsText: String = ""

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

            // Unit toggle - center aligned with spacing
            HStack(spacing: Spacing.sm) {
                Button(action: { unit = .kg }) {
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

                Button(action: { unit = .lbs }) {
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

            // Input
            HStack(spacing: Spacing.sm) {
                TextField("", text: unit == .kg ? $kgText : $lbsText)
                    .font(.trainLargeNumber)
                    .foregroundColor(.trainPrimary)
                    .multilineTextAlignment(.center)
                    .keyboardType(.decimalPad)
                    .onChange(of: kgText) { _, newValue in
                        if let value = Double(newValue) {
                            weightKg = value
                        }
                    }
                    .onChange(of: lbsText) { _, newValue in
                        if let value = Double(newValue) {
                            weightLbs = value
                        }
                    }

                Text(unit == .kg ? "kg" : "lbs")
                    .font(.trainTitle)
                    .foregroundColor(.trainTextSecondary)
            }
            .padding(Spacing.xl)
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .cornerRadius(CornerRadius.md)

            Spacer()
        }
        .padding(.horizontal, Spacing.lg)
        .onAppear {
            if weightKg > 0 {
                kgText = String(format: "%.0f", weightKg)
            }
            if weightLbs > 0 {
                lbsText = String(format: "%.0f", weightLbs)
            }
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
