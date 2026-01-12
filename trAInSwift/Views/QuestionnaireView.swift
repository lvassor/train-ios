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

    // Total steps: Goal → Name → Age → Gender → Height → Weight → Experience → Days → Split → Duration → Equipment → Muscles → Injuries
    let totalSteps = 13

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
        // New order: Goal → Name → Age → Gender → Height → Weight → Experience → Days → Split → Duration → Equipment → Muscles → Injuries
        switch currentStep {
        case 0: // Goal
            GoalsStepView(selectedGoal: $viewModel.questionnaireData.primaryGoal)
        case 1: // Name
            NameStepView(name: $viewModel.questionnaireData.name)
        case 2: // Age
            AgeStepView(dateOfBirth: $viewModel.questionnaireData.dateOfBirth)
        case 3: // Gender
            GenderStepView(selectedGender: $viewModel.questionnaireData.gender)
        case 4: // Height
            HeightStepView(
                heightCm: $viewModel.questionnaireData.heightCm,
                heightFt: $viewModel.questionnaireData.heightFt,
                heightIn: $viewModel.questionnaireData.heightIn,
                unit: $viewModel.questionnaireData.heightUnit
            )
        case 5: // Weight
            WeightStepView(
                weightKg: $viewModel.questionnaireData.weightKg,
                weightLbs: $viewModel.questionnaireData.weightLbs,
                unit: $viewModel.questionnaireData.weightUnit
            )
        case 6: // Experience
            ExperienceStepView(experience: $viewModel.questionnaireData.experienceLevel)
        case 7: // Training Days
            TrainingDaysStepView(trainingDays: $viewModel.questionnaireData.trainingDaysPerWeek, experienceLevel: $viewModel.questionnaireData.experienceLevel)
        case 8: // Split Selection
            SplitSelectionStepView(
                selectedSplit: $viewModel.questionnaireData.selectedSplit,
                trainingDays: $viewModel.questionnaireData.trainingDaysPerWeek,
                experience: $viewModel.questionnaireData.experienceLevel,
                targetMuscleGroups: $viewModel.questionnaireData.targetMuscleGroups
            )
        case 9: // Session Duration
            SessionDurationStepView(sessionDuration: $viewModel.questionnaireData.sessionDuration)
        case 10: // Equipment
            EquipmentStepView(
                selectedEquipment: $viewModel.questionnaireData.equipmentAvailable,
                selectedDetailedEquipment: $viewModel.questionnaireData.detailedEquipment
            )
        case 11: // Muscle Groups
            MuscleGroupsStepView(selectedGroups: $viewModel.questionnaireData.targetMuscleGroups)
        case 12: // Injuries
            InjuriesStepView(injuries: $viewModel.questionnaireData.injuries)
        default:
            EmptyView()
        }
    }

    private var isCurrentStepValid: Bool {
        // New order: Goal → Name → Age → Gender → Height → Weight → Experience → Days → Split → Duration → Equipment → Muscles → Injuries
        switch currentStep {
        case 0: // Goal
            return !viewModel.questionnaireData.primaryGoal.isEmpty
        case 1: // Name
            let sanitizedName = viewModel.questionnaireData.name.trimmingCharacters(in: .whitespacesAndNewlines)
            return sanitizedName.count >= 2 && sanitizedName.count <= 30
        case 2: // Age
            return viewModel.questionnaireData.age >= 18
        case 3: // Gender
            return !viewModel.questionnaireData.gender.isEmpty
        case 4: // Height
            if viewModel.questionnaireData.heightUnit == .cm {
                return viewModel.questionnaireData.heightCm >= 100 && viewModel.questionnaireData.heightCm <= 250
            } else {
                return viewModel.questionnaireData.heightFt >= 3 && viewModel.questionnaireData.heightFt <= 8
            }
        case 5: // Weight
            if viewModel.questionnaireData.weightUnit == .kg {
                return viewModel.questionnaireData.weightKg >= 30 && viewModel.questionnaireData.weightKg <= 200
            } else {
                return viewModel.questionnaireData.weightLbs >= 65 && viewModel.questionnaireData.weightLbs <= 440
            }
        case 6: // Experience
            return !viewModel.questionnaireData.experienceLevel.isEmpty
        case 7: // Training Days
            return viewModel.questionnaireData.trainingDaysPerWeek >= 1 && viewModel.questionnaireData.trainingDaysPerWeek <= 6
        case 8: // Split Selection
            return !viewModel.questionnaireData.selectedSplit.isEmpty
        case 9: // Session Duration
            return !viewModel.questionnaireData.sessionDuration.isEmpty
        case 10: // Equipment
            return !viewModel.questionnaireData.equipmentAvailable.isEmpty
        case 11: // Muscle Groups (optional, 0-3)
            let count = viewModel.questionnaireData.targetMuscleGroups.count
            return count >= 0 && count <= 3
        case 12: // Injuries (optional)
            return true
        default:
            return true
        }
    }

    // Enable scrolling only for pages that need it (equipment step has expandable content)
    private func shouldDisableScrollForCurrentStep() -> Bool {
        // Equipment step (step 10) needs scrolling for expandable categories
        if currentStep == 10 {
            return false  // Enable scrolling for equipment
        }
        // Name step (step 1) should not scroll - simple input
        if currentStep == 1 {
            return true  // Disable scrolling for name
        }
        return true  // All other pages are non-scrollable
    }

    private func nextStep() {
        // Check if leaving equipment step with limited equipment selection
        if currentStep == 10 {
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

