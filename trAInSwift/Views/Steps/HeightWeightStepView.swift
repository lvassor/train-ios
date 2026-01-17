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
                Text("Height & Weight")
                    .font(.trainTitle2)
                    .foregroundColor(.trainTextPrimary)

                Text("This helps us calculate your body metrics for personalized workouts and calorie tracking")
                    .font(.trainSubtitle)
                    .foregroundColor(.trainTextSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)

            // Height Section
            VStack(alignment: .center, spacing: Spacing.md) {
                Text("Height")
                    .font(.trainBodyMedium)
                    .foregroundColor(.trainTextPrimary)
                    .frame(maxWidth: .infinity)

                // Unit selector - toolbar style, center aligned
                HStack(spacing: Spacing.sm) {
                    Spacer()
                    ForEach([QuestionnaireData.HeightUnit.cm, .ftIn], id: \.self) { unit in
                        Button(action: {
                            let oldUnit = heightUnit
                            heightUnit = unit

                            // Convert between units when switching
                            if oldUnit != unit {
                                if unit == .cm && oldUnit == .ftIn {
                                    // Convert ft/in to cm
                                    heightCm = Double(heightFt) * 30.48 + Double(heightIn) * 2.54
                                } else if unit == .ftIn && oldUnit == .cm {
                                    // Convert cm to ft/in
                                    let totalInches = heightCm / 2.54
                                    heightFt = Int(totalInches / 12)
                                    heightIn = Int(totalInches.truncatingRemainder(dividingBy: 12))
                                }
                            }
                        }) {
                            Text(unit == .cm ? "cm" : "ft/in")
                                .font(.trainCaption)
                                .foregroundColor(heightUnit == unit ? .white : .trainTextSecondary)
                                .padding(.horizontal, Spacing.lg)
                                .padding(.vertical, Spacing.sm)
                                .background(heightUnit == unit ? Color.trainPrimary : Color.trainHover)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                    Spacer()
                }

                // Height input - single ruler for both units
                VStack(spacing: Spacing.md) {
                    // Display current value
                    if heightUnit == .cm {
                        Text("\(heightCm, specifier: "%.1f") cm")
                            .font(.trainMediumNumber)
                            .foregroundColor(.trainPrimary)
                            .frame(maxWidth: .infinity)

                        SlidingRuler(
                            value: $heightCm,
                            in: 120...220,
                            step: 10,
                            snap: .none,
                            tick: .unit
                        )
                        .frame(height: 60)
                        .onChange(of: heightCm) { _, newValue in
                            // Update ft/in when cm changes
                            let totalInches = newValue / 2.54
                            heightFt = Int(totalInches / 12)
                            heightIn = Int(totalInches.truncatingRemainder(dividingBy: 12))
                        }
                    } else {
                        Text("\(heightFt)' \(heightIn)\"")
                            .font(.trainMediumNumber)
                            .foregroundColor(.trainPrimary)
                            .frame(maxWidth: .infinity)

                        // Single ruler for ft/in as decimal (e.g., 5.75 ft = 5ft 9in)
                        SlidingRuler(
                            value: Binding(
                                get: { Double(heightFt) + Double(heightIn) / 12.0 },
                                set: { newFeet in
                                    heightFt = Int(newFeet)
                                    heightIn = Int((newFeet - Double(Int(newFeet))) * 12.0)
                                    // Update cm when ft/in changes
                                    heightCm = Double(heightFt) * 30.48 + Double(heightIn) * 2.54
                                }
                            ),
                            in: 3...8,
                            step: 1,
                            snap: .none,
                            tick: .unit
                        )
                        .frame(height: 60)
                    }
                }
                .padding(Spacing.lg)
                .appCard()
            }

            // Weight Section
            VStack(alignment: .center, spacing: Spacing.md) {
                Text("Weight")
                    .font(.trainBodyMedium)
                    .foregroundColor(.trainTextPrimary)
                    .frame(maxWidth: .infinity)

                // Unit selector - toolbar style, center aligned
                HStack(spacing: Spacing.sm) {
                    Spacer()
                    ForEach([QuestionnaireData.WeightUnit.kg, .lbs], id: \.self) { unit in
                        Button(action: {
                            let oldUnit = weightUnit
                            weightUnit = unit

                            // Convert between units when switching
                            if oldUnit != unit {
                                if unit == .kg && oldUnit == .lbs {
                                    weightKg = weightLbs * 0.453592
                                } else if unit == .lbs && oldUnit == .kg {
                                    weightLbs = weightKg * 2.20462
                                }
                            }
                        }) {
                            Text(unit == .kg ? "kg" : "lbs")
                                .font(.trainCaption)
                                .foregroundColor(weightUnit == unit ? .white : .trainTextSecondary)
                                .padding(.horizontal, Spacing.lg)
                                .padding(.vertical, Spacing.sm)
                                .background(weightUnit == unit ? Color.trainPrimary : Color.trainHover)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                    Spacer()
                }

                // Weight input - single ruler with proper conversion
                VStack(spacing: Spacing.md) {
                    if weightUnit == .kg {
                        Text("\(weightKg, specifier: "%.1f") kg")
                            .font(.trainMediumNumber)
                            .foregroundColor(.trainPrimary)
                            .frame(maxWidth: .infinity)

                        SlidingRuler(
                            value: $weightKg,
                            in: 30...200,
                            step: 10,
                            snap: .none,
                            tick: .unit
                        )
                        .frame(height: 60)
                        .onChange(of: weightKg) { _, newValue in
                            // Update lbs when kg changes
                            weightLbs = newValue * 2.20462
                        }
                    } else {
                        Text("\(weightLbs, specifier: "%.1f") lbs")
                            .font(.trainMediumNumber)
                            .foregroundColor(.trainPrimary)
                            .frame(maxWidth: .infinity)

                        SlidingRuler(
                            value: $weightLbs,
                            in: 60...440,
                            step: 20,
                            snap: .none,
                            tick: .unit
                        )
                        .frame(height: 60)
                        .onChange(of: weightLbs) { _, newValue in
                            // Update kg when lbs changes
                            weightKg = newValue * 0.453592
                        }
                    }
                }
                .padding(Spacing.lg)
                .appCard()
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