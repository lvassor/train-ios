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

    // Total steps: Dynamic based on health sync + 2 video interstitials
    var totalSteps: Int {
        return viewModel.questionnaireData.skipHeightWeight ? 14 : 15
        // Goal → HealthProfile → [HeightWeight] → Experience → [Interstitial1] → Days → Split → Duration → Equipment → [Interstitial2] → Muscles → Injuries
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
        if currentStep == totalSteps - 1 {
            return "Generate Your Program"
        }
        return "Continue"
    }

    @ViewBuilder
    private var currentStepView: some View {
        // New order with conditional height/weight: Goal → HealthProfile → [HeightWeight] → Experience → Days → Split → Duration → Equipment → Muscles → Injuries
        let skipHeightWeight = viewModel.questionnaireData.skipHeightWeight

        switch currentStep {
        case 0: // Goal
            GoalsStepView(selectedGoal: $viewModel.questionnaireData.primaryGoal)
        case 1: // Health Profile (combined name/age/gender + Apple Health)
            HealthProfileStepView(
                name: $viewModel.questionnaireData.name,
                dateOfBirth: $viewModel.questionnaireData.dateOfBirth,
                selectedGender: $viewModel.questionnaireData.gender,
                skipHeightWeight: $viewModel.questionnaireData.skipHeightWeight,
                healthKitSynced: $viewModel.questionnaireData.healthKitSynced
            )
        case 2: // Height/Weight (conditional)
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
                // If skipped, this case shouldn't be reached, but show experience as fallback
                ExperienceStepView(experience: $viewModel.questionnaireData.experienceLevel)
            }
        default:
            // Adjust step numbers based on whether height/weight was skipped
            let adjustedStep = skipHeightWeight ? currentStep + 1 : currentStep

            switch adjustedStep {
            case 3: // Experience
                ExperienceStepView(experience: $viewModel.questionnaireData.experienceLevel)
            case 4: // First Video Interstitial (after experience)
                FirstVideoInterstitialView(onComplete: proceedToNextStep)
            case 5: // Training Days
                TrainingDaysStepView(trainingDays: $viewModel.questionnaireData.trainingDaysPerWeek, experienceLevel: $viewModel.questionnaireData.experienceLevel)
            case 6: // Split Selection
                SplitSelectionStepView(
                    selectedSplit: $viewModel.questionnaireData.selectedSplit,
                    trainingDays: $viewModel.questionnaireData.trainingDaysPerWeek,
                    experience: $viewModel.questionnaireData.experienceLevel,
                    targetMuscleGroups: $viewModel.questionnaireData.targetMuscleGroups
                )
            case 7: // Session Duration
                SessionDurationStepView(sessionDuration: $viewModel.questionnaireData.sessionDuration)
            case 8: // Equipment
                EquipmentStepView(
                    selectedEquipment: $viewModel.questionnaireData.equipmentAvailable,
                    selectedDetailedEquipment: $viewModel.questionnaireData.detailedEquipment
                )
            case 9: // Second Video Interstitial (after equipment)
                SecondVideoInterstitialView(onComplete: proceedToNextStep)
            case 10: // Muscle Groups
                MuscleGroupsStepView(selectedGroups: $viewModel.questionnaireData.targetMuscleGroups)
            case 11: // Injuries
                InjuriesStepView(injuries: $viewModel.questionnaireData.injuries)
            default:
                EmptyView()
            }
        }
    }

    private var isCurrentStepValid: Bool {
        // New order with conditional height/weight: Goal → HealthProfile → [HeightWeight] → Experience → Days → Split → Duration → Equipment → Muscles → Injuries
        let skipHeightWeight = viewModel.questionnaireData.skipHeightWeight

        switch currentStep {
        case 0: // Goal
            return !viewModel.questionnaireData.primaryGoal.isEmpty
        case 1: // Health Profile (name + age + gender)
            let sanitizedName = viewModel.questionnaireData.name.trimmingCharacters(in: .whitespacesAndNewlines)
            let nameValid = sanitizedName.count >= 2 && sanitizedName.count <= 30
            let ageValid = viewModel.questionnaireData.age >= 18
            let genderValid = !viewModel.questionnaireData.gender.isEmpty
            return nameValid && ageValid && genderValid
        case 2: // Height/Weight (conditional)
            if skipHeightWeight {
                // If height/weight is skipped, this should be the experience step
                return !viewModel.questionnaireData.experienceLevel.isEmpty
            } else {
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
            }
        default:
            // Adjust step numbers based on whether height/weight was skipped
            let adjustedStep = skipHeightWeight ? currentStep + 1 : currentStep

            switch adjustedStep {
            case 3: // Experience
                return !viewModel.questionnaireData.experienceLevel.isEmpty
            case 4: // First Video Interstitial (always valid)
                return true
            case 5: // Training Days
                return viewModel.questionnaireData.trainingDaysPerWeek >= 1 && viewModel.questionnaireData.trainingDaysPerWeek <= 6
            case 6: // Split Selection
                return !viewModel.questionnaireData.selectedSplit.isEmpty
            case 7: // Session Duration
                return !viewModel.questionnaireData.sessionDuration.isEmpty
            case 8: // Equipment
                return !viewModel.questionnaireData.equipmentAvailable.isEmpty
            case 9: // Second Video Interstitial (always valid)
                return true
            case 10: // Muscle Groups (optional, 0-3)
                let count = viewModel.questionnaireData.targetMuscleGroups.count
                return count >= 0 && count <= 3
            case 11: // Injuries (optional)
                return true
            default:
                return true
            }
        }
    }

    // Enable scrolling only for pages that need it (equipment step has expandable content)
    private func shouldDisableScrollForCurrentStep() -> Bool {
        let skipHeightWeight = viewModel.questionnaireData.skipHeightWeight

        // Equipment step needs scrolling for expandable categories
        let adjustedStep = skipHeightWeight ? currentStep + 1 : currentStep
        if adjustedStep == 8 { // Equipment step (now step 8 due to interstitials)
            return false  // Enable scrolling for equipment
        }

        // Health profile step (step 1) may need scrolling for Apple Health UI
        if currentStep == 1 {
            return false  // Enable scrolling for health profile
        }

        return true  // All other pages are non-scrollable
    }

    private func nextStep() {
        let skipHeightWeight = viewModel.questionnaireData.skipHeightWeight

        // Check if leaving equipment step with limited equipment selection
        let adjustedStep = skipHeightWeight ? currentStep + 1 : currentStep
        if adjustedStep == 8 { // Equipment step (now step 8 due to interstitials)
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
                currentStep += 1
            } else {
                // Complete questionnaire
                showingProgramLoading = true
            }
        }
    }

    private func previousStep() {
        withAnimation(.easeInOut(duration: 0.15)) {
            if currentStep > 0 {
                currentStep -= 1
            } else {
                // Go back to home screen
                onBack?()
            }
        }
    }
}

