//
//  HealthProfileStepView.swift
//  trAInSwift
//
//  Combined Apple Health integration with manual age/gender entry
//

import SwiftUI
import HealthKit

struct HealthProfileStepView: View {
    @Binding var dateOfBirth: Date
    @Binding var selectedGender: String
    @Binding var skipHeightWeight: Bool
    @Binding var healthKitSynced: Bool
    @StateObject private var healthKitManager = HealthKitManager()
    @State private var showingHealthSync = false
    @State private var healthSyncAttempted = false
    @State private var healthDataSynced = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            // Header
            VStack(alignment: .center, spacing: Spacing.sm) {
                Text("Body Stats")
                    .font(.trainTitle2)
                    .foregroundColor(.trainTextPrimary)

                Text("Sync with Train for the best experience")
                    .font(.trainSubtitle)
                    .foregroundColor(.trainTextSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)

            if healthKitManager.isAvailable && !healthDataSynced {
                // Apple Health Sync Section
                VStack(spacing: Spacing.lg) {
                    VStack(spacing: Spacing.md) {
                        Text("Sync Train with Apple Health for the best experience.")
                            .font(.trainBodyMedium)
                            .foregroundColor(.trainTextPrimary)
                            .multilineTextAlignment(.leading)

                        Text("To personalize workouts and calculate calories burned, sync your Apple health profile. Your data is never shared with third parties.")
                            .font(.trainBody)
                            .foregroundColor(.trainTextSecondary)
                            .multilineTextAlignment(.leading)
                    }

                    // Sync with Apple Health Button
                    Button(action: syncWithAppleHealth) {
                        HStack(spacing: Spacing.sm) {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.red)
                                .font(.title3)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Sync with Apple Health")
                                    .font(.trainBodyMedium)
                                    .foregroundColor(.white)

                                if healthKitManager.isSimulator {
                                    Text("(Limited in simulator)")
                                        .font(.trainCaption)
                                        .foregroundColor(.trainTextSecondary)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.md)
                        .background(healthKitManager.isSimulator ? Color.trainTextSecondary.opacity(0.3) : Color.trainHover)
                        .appCard(cornerRadius: CornerRadius.md)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .disabled(showingHealthSync)

                    // "OR" divider
                    HStack {
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(.trainTextSecondary.opacity(0.3))

                        Text("OR")
                            .font(.trainCaption)
                            .foregroundColor(.trainTextSecondary)
                            .padding(.horizontal, Spacing.md)

                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(.trainTextSecondary.opacity(0.3))
                    }
                }
            }

            // Manual Entry Section
            VStack(spacing: Spacing.lg) {
                if !healthDataSynced {
                    VStack(spacing: Spacing.sm) {
                        Text("Enter your health profile manually")
                            .font(.trainBodyMedium)
                            .foregroundColor(.trainTextPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text("We use gender and age to provide you with the most accurate personalised workouts.")
                            .font(.trainBody)
                            .foregroundColor(.trainTextSecondary)
                            .multilineTextAlignment(.leading)
                    }
                }


                // Gender Selection
                VStack(alignment: .leading, spacing: Spacing.md) {
                    Text("Gender")
                        .font(.trainBodyMedium)
                        .foregroundColor(.trainTextPrimary)

                    HStack(spacing: Spacing.md) {
                        // Male, Female, and Other as equal-sized cards horizontally stacked
                        ForEach(["Male", "Female", "Other"], id: \.self) { gender in
                            Button(action: {
                                selectedGender = gender == "Other" ? "Other / Prefer not to say" : gender
                            }) {
                                VStack(spacing: Spacing.sm) {
                                    ZStack {
                                        Circle()
                                            .fill((selectedGender == gender || (gender == "Other" && selectedGender == "Other / Prefer not to say")) ? Color.white.opacity(0.3) : Color.trainHover)
                                            .frame(width: 40, height: 40)

                                        Image(systemName: gender == "Male" ? "figure.stand" : gender == "Female" ? "figure.stand.dress" : "person.fill")
                                            .font(.title2)
                                            .foregroundColor((selectedGender == gender || (gender == "Other" && selectedGender == "Other / Prefer not to say")) ? .white : .trainPrimary)
                                    }

                                    Text(gender)
                                        .font(.trainCaption)
                                        .foregroundColor((selectedGender == gender || (gender == "Other" && selectedGender == "Other / Prefer not to say")) ? .white : .trainTextPrimary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, Spacing.md)
                                .background((selectedGender == gender || (gender == "Other" && selectedGender == "Other / Prefer not to say")) ? Color.trainPrimary : .clear)
                                .appCard()
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                    }
                }

                // Date of Birth Selection
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Date of Birth")
                        .font(.trainBodyMedium)
                        .foregroundColor(.trainTextPrimary)

                    HStack {
                        Spacer()
                        DatePicker(
                            "",
                            selection: $dateOfBirth,
                            in: Calendar.current.date(byAdding: .year, value: -100, to: Date())!...Calendar.current.date(byAdding: .year, value: -18, to: Date())!,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .frame(height: 120)
                        Spacer()
                    }
                    .appCard()
                }
            }

            if healthDataSynced {
                // Success message
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Data synced from Apple Health")
                        .font(.trainCaption)
                        .foregroundColor(.trainTextSecondary)
                }
                .padding(.top, Spacing.sm)
            }

            Spacer()
        }
        .onAppear {
            // Check if HealthKit is available
            if !healthKitManager.isAvailable {
                print("HealthKit not available on this device")
            }
        }
    }

    private func syncWithAppleHealth() {
        showingHealthSync = true
        healthSyncAttempted = true

        Task {
            let success = await healthKitManager.requestPermission()

            await MainActor.run {
                showingHealthSync = false

                if success, let healthData = healthKitManager.healthData {
                    // Sync data from HealthKit
                    if let healthAge = healthData.age, let healthGender = healthData.gender {
                        if let dob = healthData.dateOfBirth {
                            dateOfBirth = dob
                        }
                        selectedGender = healthKitManager.biologicalSexToString(healthGender)
                        healthDataSynced = true
                        healthKitSynced = true

                        // Check if we can skip height/weight
                        if healthKitManager.canSkipHeightWeight() {
                            skipHeightWeight = true
                        }
                    }
                }
            }
        }
    }

}

#Preview {
    HealthProfileStepView(
        dateOfBirth: .constant(Calendar.current.date(byAdding: .year, value: -25, to: Date())!),
        selectedGender: .constant(""),
        skipHeightWeight: .constant(false),
        healthKitSynced: .constant(false)
    )
    .charcoalGradientBackground()
}