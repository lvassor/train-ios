//
//  QuestionnaireView.swift
//  trAInApp
//
//  Updated with new 10-step questionnaire
//

import SwiftUI

struct QuestionnaireView: View {
    @EnvironmentObject var viewModel: WorkoutViewModel
    // Simplified flow: single sequence of questions (no sections/covers)
    @State private var currentStep = 0
    @State private var showingProgramLoading = false
    @State private var showingProgramReady = false
    @State private var showingEquipmentWarning = false
    @State private var hasSeenEquipmentWarning = false

    let onComplete: () -> Void
    var onBack: (() -> Void)?

    // Total steps: Dynamic based on health sync + 2 video interstitials + separate name step (referral moved to end, not counted in progress)
    var totalSteps: Int {
        return viewModel.questionnaireData.skipHeightWeight ? 15 : 16
        // Goal → Name → HealthProfile → [HeightWeight] → Experience → [Interstitial1] → Days → Split → Duration → Equipment → [Interstitial2] → Muscles → Injuries → Referral (not counted)
    }

    var body: some View {
        ZStack {
            if showingProgramReady, let program = viewModel.generatedProgram {
                ProgramReadyView(
                    program: program,
                    onStart: {
                        viewModel.completeQuestionnaire()
                        onComplete()
                    },
                    selectedMuscleGroups: viewModel.questionnaireData.targetMuscleGroups
                )
            } else if showingProgramLoading {
                ProgramLoadingView(onComplete: {
                    // Generate program when loading completes
                    viewModel.generateProgram()

                    withAnimation {
                        showingProgramReady = true
                    }
                })
            } else {
                VStack(spacing: 0) {
                    // Back button and progress bar at top
                    VStack(spacing: 0) {
                        HStack {
                            Button(action: previousStep) {
                                Image(systemName: "arrow.left")
                                    .font(.title3)
                                    .foregroundColor(.trainTextPrimary)
                            }
                            Spacer()
                        }
                        .padding(16)

                        QuestionnaireProgressBar(currentStep: currentStep + 1, totalSteps: totalSteps)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 16)
                    }

                    // Content + Button in ZStack so content scrolls behind button
                    ZStack(alignment: .bottom) {
                        // Content area - fills available space
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 32) {
                                currentStepView
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                            .padding(.bottom, 100)
                        }
                        .scrollDisabled(shouldDisableScrollForCurrentStep())
                        .edgeFadeMask(topFade: 16, bottomFade: 60)

                        // Continue button floating on top - NO background
                        CustomButton(
                            title: buttonTitle,
                            action: nextStep,
                            isEnabled: isCurrentStepValid
                        )
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                    }
                }
            }
        }
        .charcoalGradientBackground()
        .alert(viewModel.warningAlertTitle, isPresented: $viewModel.showWarningAlert) {
            Button("OK", role: .cancel) {
                viewModel.dismissWarningAlert()
            }
        } message: {
            Text(viewModel.warningAlertMessage)
        }
        .alert("Limited Equipment", isPresented: $showingEquipmentWarning) {
            Button("Continue Anyway", role: .destructive) {
                showingEquipmentWarning = false
                hasSeenEquipmentWarning = true
                proceedFromEquipmentStep()
            }
            Button("Add More Equipment", role: .cancel) {
                showingEquipmentWarning = false
            }
        } message: {
            Text("Selecting only one equipment type may limit your exercise variety and program effectiveness. For the best results, we recommend adding at least one more equipment category.")
        }
    }

    private var buttonTitle: String {
        if currentStep == 13 { // Referral step (final step)
            return "Generate Your Program"
        }
        return "Continue"
    }

    @ViewBuilder
    private var currentStepView: some View {
        // New order with conditional height/weight: Goal → Name → HealthProfile → [HeightWeight] → Experience → Days → Split → Duration → Equipment → Muscles → Injuries → Referral (final, not counted)
        let skipHeightWeight = viewModel.questionnaireData.skipHeightWeight

        switch currentStep {
        case 0: // Goal
            GoalsStepView(selectedGoals: $viewModel.questionnaireData.primaryGoals)
        case 1: // Name
            NameStepView(name: $viewModel.questionnaireData.name)
        case 2: // Health Profile (age/gender + Apple Health)
            HealthProfileStepView(
                dateOfBirth: $viewModel.questionnaireData.dateOfBirth,
                selectedGender: $viewModel.questionnaireData.gender,
                skipHeightWeight: $viewModel.questionnaireData.skipHeightWeight,
                healthKitSynced: $viewModel.questionnaireData.healthKitSynced
            )
        case 3: // Height/Weight (conditional) OR Experience (if height/weight skipped)
            if !skipHeightWeight {
                HeightWeightStepView(
                    heightCm: $viewModel.questionnaireData.heightCm,
                    heightFt: $viewModel.questionnaireData.heightFt,
                    heightIn: $viewModel.questionnaireData.heightIn,
                    heightUnit: $viewModel.questionnaireData.heightUnit,
                    weightKg: $viewModel.questionnaireData.weightKg,
                    weightLbs: $viewModel.questionnaireData.weightLbs,
                    weightUnit: $viewModel.questionnaireData.weightUnit
                )
            } else {
                // If height/weight skipped, step 3 becomes Experience
                ExperienceStepView(experience: $viewModel.questionnaireData.experienceLevel)
            }
        case 4: // Experience OR First Video Interstitial
            if !skipHeightWeight {
                ExperienceStepView(experience: $viewModel.questionnaireData.experienceLevel)
            } else {
                FirstVideoInterstitialView(onComplete: proceedToNextStep)
            }
        case 5: // First Video Interstitial OR Training Days
            if !skipHeightWeight {
                FirstVideoInterstitialView(onComplete: proceedToNextStep)
            } else {
                TrainingDaysStepView(trainingDays: $viewModel.questionnaireData.trainingDaysPerWeek, experienceLevel: $viewModel.questionnaireData.experienceLevel)
            }
        case 6: // Training Days OR Split Selection
            if !skipHeightWeight {
                TrainingDaysStepView(trainingDays: $viewModel.questionnaireData.trainingDaysPerWeek, experienceLevel: $viewModel.questionnaireData.experienceLevel)
            } else {
                SplitSelectionStepView(
                    selectedSplit: $viewModel.questionnaireData.selectedSplit,
                    trainingDays: $viewModel.questionnaireData.trainingDaysPerWeek,
                    experience: $viewModel.questionnaireData.experienceLevel,
                    targetMuscleGroups: $viewModel.questionnaireData.targetMuscleGroups
                )
            }
        case 7: // Split Selection OR Session Duration
            if !skipHeightWeight {
                SplitSelectionStepView(
                    selectedSplit: $viewModel.questionnaireData.selectedSplit,
                    trainingDays: $viewModel.questionnaireData.trainingDaysPerWeek,
                    experience: $viewModel.questionnaireData.experienceLevel,
                    targetMuscleGroups: $viewModel.questionnaireData.targetMuscleGroups
                )
            } else {
                SessionDurationStepView(sessionDuration: $viewModel.questionnaireData.sessionDuration)
            }
        case 8: // Session Duration OR Equipment
            if !skipHeightWeight {
                SessionDurationStepView(sessionDuration: $viewModel.questionnaireData.sessionDuration)
            } else {
                EquipmentStepView(
                    selectedEquipment: $viewModel.questionnaireData.equipmentAvailable,
                    selectedDetailedEquipment: $viewModel.questionnaireData.detailedEquipment
                )
            }
        case 9: // Equipment OR Second Video Interstitial
            if !skipHeightWeight {
                EquipmentStepView(
                    selectedEquipment: $viewModel.questionnaireData.equipmentAvailable,
                    selectedDetailedEquipment: $viewModel.questionnaireData.detailedEquipment
                )
            } else {
                SecondVideoInterstitialView(onComplete: proceedToNextStep)
            }
        case 10: // Second Video Interstitial OR Muscle Groups
            if !skipHeightWeight {
                SecondVideoInterstitialView(onComplete: proceedToNextStep)
            } else {
                MuscleGroupsStepView(selectedGroups: $viewModel.questionnaireData.targetMuscleGroups)
            }
        case 11: // Muscle Groups OR Injuries
            if !skipHeightWeight {
                MuscleGroupsStepView(selectedGroups: $viewModel.questionnaireData.targetMuscleGroups)
            } else {
                InjuriesStepView(injuries: $viewModel.questionnaireData.injuries)
            }
        case 12: // Injuries (final counted step)
            InjuriesStepView(injuries: $viewModel.questionnaireData.injuries)
        case 13: // Referral tracking (final step, not counted in progress)
            ReferralStepView(selectedReferral: $viewModel.questionnaireData.selectedReferral)
        default:
            EmptyView()
        }
    }

    private var isCurrentStepValid: Bool {
        let skipHeightWeight = viewModel.questionnaireData.skipHeightWeight

        switch currentStep {
        case 0: // Goal
            return !viewModel.questionnaireData.primaryGoals.isEmpty
        case 1: // Name
            let sanitizedName = viewModel.questionnaireData.name.trimmingCharacters(in: .whitespacesAndNewlines)
            return sanitizedName.count >= 2 && sanitizedName.count <= 30
        case 2: // Health Profile (age + gender)
            let ageValid = viewModel.questionnaireData.age >= 18
            let genderValid = !viewModel.questionnaireData.gender.isEmpty
            return ageValid && genderValid
        case 3: // Height/Weight OR Experience
            if !skipHeightWeight {
                // Validate height/weight
                let heightValid: Bool
                if viewModel.questionnaireData.heightUnit == .cm {
                    heightValid = viewModel.questionnaireData.heightCm >= 100 && viewModel.questionnaireData.heightCm <= 250
                } else {
                    heightValid = viewModel.questionnaireData.heightFt >= 3 && viewModel.questionnaireData.heightFt <= 8
                }

                let weightValid: Bool
                if viewModel.questionnaireData.weightUnit == .kg {
                    weightValid = viewModel.questionnaireData.weightKg >= 30 && viewModel.questionnaireData.weightKg <= 200
                } else {
                    weightValid = viewModel.questionnaireData.weightLbs >= 65 && viewModel.questionnaireData.weightLbs <= 440
                }

                return heightValid && weightValid
            } else {
                return !viewModel.questionnaireData.experienceLevel.isEmpty
            }
        case 4: // Experience OR First Video Interstitial
            if !skipHeightWeight {
                return !viewModel.questionnaireData.experienceLevel.isEmpty
            } else {
                return true // Video interstitial always valid
            }
        case 5: // First Video Interstitial OR Training Days
            if !skipHeightWeight {
                return true // Video interstitial always valid
            } else {
                return viewModel.questionnaireData.trainingDaysPerWeek >= 1 && viewModel.questionnaireData.trainingDaysPerWeek <= 6
            }
        case 6: // Training Days OR Split Selection
            if !skipHeightWeight {
                return viewModel.questionnaireData.trainingDaysPerWeek >= 1 && viewModel.questionnaireData.trainingDaysPerWeek <= 6
            } else {
                return !viewModel.questionnaireData.selectedSplit.isEmpty
            }
        case 7: // Split Selection OR Session Duration
            if !skipHeightWeight {
                return !viewModel.questionnaireData.selectedSplit.isEmpty
            } else {
                return !viewModel.questionnaireData.sessionDuration.isEmpty
            }
        case 8: // Session Duration OR Equipment
            if !skipHeightWeight {
                return !viewModel.questionnaireData.sessionDuration.isEmpty
            } else {
                return !viewModel.questionnaireData.equipmentAvailable.isEmpty
            }
        case 9: // Equipment OR Second Video Interstitial
            if !skipHeightWeight {
                return !viewModel.questionnaireData.equipmentAvailable.isEmpty
            } else {
                return true // Video interstitial always valid
            }
        case 10: // Second Video Interstitial OR Muscle Groups
            if !skipHeightWeight {
                return true // Video interstitial always valid
            } else {
                let count = viewModel.questionnaireData.targetMuscleGroups.count
                return count >= 0 && count <= 3
            }
        case 11: // Muscle Groups OR Injuries
            if !skipHeightWeight {
                let count = viewModel.questionnaireData.targetMuscleGroups.count
                return count >= 0 && count <= 3
            } else {
                return true // Injuries optional
            }
        case 12: // Injuries (final counted step)
            return true // Injuries optional
        case 13: // Referral tracking (optional)
            return true // Referral selection is optional
        default:
            return true
        }
    }

    // Enable scrolling only for pages that need it (equipment step has expandable content)
    private func shouldDisableScrollForCurrentStep() -> Bool {
        let skipHeightWeight = viewModel.questionnaireData.skipHeightWeight

        // Equipment step needs scrolling for expandable categories
        if (!skipHeightWeight && currentStep == 9) || (skipHeightWeight && currentStep == 8) {
            return false  // Enable scrolling for equipment
        }

        // Health profile step (step 2) may need scrolling for Apple Health UI
        if currentStep == 2 {
            return false  // Enable scrolling for health profile
        }

        return true  // All other pages are non-scrollable
    }

    private func nextStep() {
        let skipHeightWeight = viewModel.questionnaireData.skipHeightWeight

        // Check if leaving equipment step with limited equipment selection
        if (!skipHeightWeight && currentStep == 9) || (skipHeightWeight && currentStep == 8) {
            let equipmentCount = viewModel.questionnaireData.equipmentAvailable.count
            if equipmentCount == 1 && !hasSeenEquipmentWarning {
                // Show warning modal for single equipment selection
                showingEquipmentWarning = true
                return
            }
        }

        proceedToNextStep()
    }

    private func proceedFromEquipmentStep() {
        // Called after user dismisses the equipment warning
        proceedToNextStep()
    }

    private func proceedToNextStep() {
        withAnimation(.easeInOut(duration: 0.15)) {
            if currentStep < totalSteps - 1 {
                // Continue through regular questionnaire steps
                currentStep += 1
            } else if currentStep == totalSteps - 1 {
                // After last counted step (injuries), go to referral step
                currentStep = 13 // Referral step
            } else {
                // After referral step (13), complete questionnaire
                showingProgramLoading = true
            }
        }
    }

    private func previousStep() {
        withAnimation(.easeInOut(duration: 0.15)) {
            if currentStep == 13 {
                // From referral step, go back to last counted step (injuries)
                currentStep = totalSteps - 1
            } else if currentStep > 0 {
                currentStep -= 1
            } else {
                // Go back to home screen
                onBack?()
            }
        }
    }
}

