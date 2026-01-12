//
//  HeightWeightStepView.swift
//  trAInSwift
//
//  Combined height and weight input using scrollable rulers
//

import SwiftUI
import SlidingRuler

struct HeightWeightStepView: View {
    @Binding var heightCm: Double
    @Binding var heightFt: Int
    @Binding var heightIn: Int
    @Binding var heightUnit: QuestionnaireData.HeightUnit
    @Binding var weightKg: Double
    @Binding var weightLbs: Double
    @Binding var weightUnit: QuestionnaireData.WeightUnit

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            // Header
            VStack(alignment: .center, spacing: Spacing.sm) {
                Text("Physical Stats")
                    .font(.trainTitle2)
                    .foregroundColor(.trainTextPrimary)

                Text("Help us personalize your training program")
                    .font(.trainSubtitle)
                    .foregroundColor(.trainTextSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)

            // Height Section
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("Height")
                    .font(.trainBodyMedium)
                    .foregroundColor(.trainTextPrimary)

                // Unit selector
                HStack(spacing: Spacing.sm) {
                    ForEach([QuestionnaireData.HeightUnit.cm, .ftIn], id: \.self) { unit in
                        Button(action: { heightUnit = unit }) {
                            Text(unit == .cm ? "cm" : "ft/in")
                                .font(.trainCaption)
                                .foregroundColor(heightUnit == unit ? .white : .trainTextSecondary)
                                .padding(.horizontal, Spacing.md)
                                .padding(.vertical, Spacing.sm)
                                .background(heightUnit == unit ? Color.trainPrimary : Color.trainHover)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                    Spacer()
                }

                // Height input
                if heightUnit == .cm {
                    SlidingRuler(
                        value: $heightCm,
                        in: 100...250,
                        step: 1,
                        snap: .unit,
                        tick: .none,
                        onEditingChanged: { _ in }
                    )
                    .overlay(
                        Text("\(Int(heightCm)) cm")
                            .font(.trainTitle3)
                            .foregroundColor(.trainTextPrimary)
                    )
                    .frame(height: 80)
                    .appCard()
                } else {
                    VStack(spacing: Spacing.sm) {
                        // Feet
                        SlidingRuler(
                            value: Binding(
                                get: { Double(heightFt) },
                                set: { heightFt = Int($0) }
                            ),
                            in: 3...8,
                            step: 1,
                            snap: .unit,
                            tick: .none,
                            onEditingChanged: { _ in }
                        )
                        .overlay(
                            Text("\(heightFt) ft")
                                .font(.trainBodyMedium)
                                .foregroundColor(.trainTextPrimary)
                        )
                        .frame(height: 60)
                        .appCard()

                        // Inches
                        SlidingRuler(
                            value: Binding(
                                get: { Double(heightIn) },
                                set: { heightIn = Int($0) }
                            ),
                            in: 0...11,
                            step: 1,
                            snap: .unit,
                            tick: .none,
                            onEditingChanged: { _ in }
                        )
                        .overlay(
                            Text("\(heightIn) in")
                                .font(.trainBodyMedium)
                                .foregroundColor(.trainTextPrimary)
                        )
                        .frame(height: 60)
                        .appCard()
                    }
                }
            }

            // Weight Section
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("Weight")
                    .font(.trainBodyMedium)
                    .foregroundColor(.trainTextPrimary)

                // Unit selector
                HStack(spacing: Spacing.sm) {
                    ForEach([QuestionnaireData.WeightUnit.kg, .lbs], id: \.self) { unit in
                        Button(action: {
                            weightUnit = unit
                            // Convert between units when switching
                            if unit == .kg && weightUnit == .lbs {
                                weightKg = weightLbs * 0.453592
                            } else if unit == .lbs && weightUnit == .kg {
                                weightLbs = weightKg * 2.20462
                            }
                        }) {
                            Text(unit == .kg ? "kg" : "lbs")
                                .font(.trainCaption)
                                .foregroundColor(weightUnit == unit ? .white : .trainTextSecondary)
                                .padding(.horizontal, Spacing.md)
                                .padding(.vertical, Spacing.sm)
                                .background(weightUnit == unit ? Color.trainPrimary : Color.trainHover)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                    Spacer()
                }

                // Weight input
                if weightUnit == .kg {
                    SlidingRuler(
                        value: $weightKg,
                        in: 30...200,
                        step: 0.5,
                        snap: .unit,
                        tick: .none,
                        onEditingChanged: { _ in }
                    )
                    .overlay(
                        Text("\(weightKg, specifier: "%.1f") kg")
                            .font(.trainTitle3)
                            .foregroundColor(.trainTextPrimary)
                    )
                    .frame(height: 80)
                    .appCard()
                } else {
                    SlidingRuler(
                        value: $weightLbs,
                        in: 65...440,
                        step: 1,
                        snap: .unit,
                        tick: .none,
                        onEditingChanged: { _ in }
                    )
                    .overlay(
                        Text("\(Int(weightLbs)) lbs")
                            .font(.trainTitle3)
                            .foregroundColor(.trainTextPrimary)
                    )
                    .frame(height: 80)
                    .appCard()
                }
            }

            Spacer()
        }
    }
}

#Preview {
    HeightWeightStepView(
        heightCm: .constant(180.0),
        heightFt: .constant(5),
        heightIn: .constant(11),
        heightUnit: .constant(.cm),
        weightKg: .constant(70.0),
        weightLbs: .constant(154.0),
        weightUnit: .constant(.kg)
    )
    .charcoalGradientBackground()
}