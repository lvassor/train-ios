//
//  QuestionnaireView.swift
//  trAInApp
//
//  Updated with new 10-step questionnaire
//

import SwiftUI

struct QuestionnaireView: View {
    @EnvironmentObject var viewModel: WorkoutViewModel
    @State private var currentSection = 0 // 0 = Section 1 cover, 1 = Section 1 questions, 2 = Section 2 cover, 3 = Section 2 questions
    @State private var currentStepInSection = 0 // Step within current section
    @State private var showingProgramLoading = false
    @State private var showingProgramReady = false
    @State private var showingEquipmentWarning = false
    @State private var hasSeenEquipmentWarning = false

    let onComplete: () -> Void
    var onBack: (() -> Void)?

    // Section 1: Availability (8 questions)
    let section1TotalSteps = 8
    // Section 2: About You (4 questions)
    let section2TotalSteps = 4

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

                        if currentSection == 1 {
                            QuestionnaireProgressBar(currentStep: currentStepInSection + 1, totalSteps: section1TotalSteps)
                                .padding(.horizontal, 16)
                                .padding(.bottom, 16)
                        } else if currentSection == 3 {
                            QuestionnaireProgressBar(currentStep: currentStepInSection + 1, totalSteps: section2TotalSteps)
                                .padding(.horizontal, 16)
                                .padding(.bottom, 16)
                        }
                    }

                    // Content + Button in ZStack so content scrolls behind button
                    ZStack(alignment: .bottom) {
                        // Content area - fills available space
                        if currentSection == 0 || currentSection == 2 {
                            currentStepView
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
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
                        }

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
        if currentSection == 3 && currentStepInSection == section2TotalSteps - 1 {
            return "Generate Your Program"
        }
        return "Continue"
    }

    @ViewBuilder
    private var currentStepView: some View {
        switch currentSection {
        case 0:
            // Section 1 Cover Page
            SectionCoverView(
                title: "Availability",
                subtitle: "Let's understand your training preferences and available resources",
                iconName: "figure.strengthtraining.traditional"
            )
        case 1:
            // Section 1 Questions (1-8)
            switch currentStepInSection {
            case 0:
                GoalsStepView(selectedGoal: $viewModel.questionnaireData.primaryGoal)
            case 1:
                ExperienceStepView(experience: $viewModel.questionnaireData.experienceLevel)
            case 2:
                MuscleGroupsStepView(selectedGroups: $viewModel.questionnaireData.targetMuscleGroups)
            case 3:
                EquipmentStepView(
                    selectedEquipment: $viewModel.questionnaireData.equipmentAvailable,
                    selectedDetailedEquipment: $viewModel.questionnaireData.detailedEquipment
                )
            case 4:
                InjuriesStepView(injuries: $viewModel.questionnaireData.injuries)
            case 5:
                TrainingDaysStepView(trainingDays: $viewModel.questionnaireData.trainingDaysPerWeek, experienceLevel: $viewModel.questionnaireData.experienceLevel)
            case 6:
                SessionDurationStepView(sessionDuration: $viewModel.questionnaireData.sessionDuration)
            case 7:
                MotivationStepView(
                    selectedMotivations: $viewModel.questionnaireData.motivations,
                    otherText: $viewModel.questionnaireData.motivationOther
                )
            default:
                EmptyView()
            }
        case 2:
            // Section 2 Cover Page
            SectionCoverView(
                title: "About You",
                subtitle: "Help us personalise your training with some basic information",
                iconName: "person.fill"
            )
        case 3:
            // Section 2 Questions (9-12)
            switch currentStepInSection {
            case 0:
                AgeStepView(dateOfBirth: $viewModel.questionnaireData.dateOfBirth)
            case 1:
                GenderStepView(selectedGender: $viewModel.questionnaireData.gender)
            case 2:
                HeightStepView(
                    heightCm: $viewModel.questionnaireData.heightCm,
                    heightFt: $viewModel.questionnaireData.heightFt,
                    heightIn: $viewModel.questionnaireData.heightIn,
                    unit: $viewModel.questionnaireData.heightUnit
                )
            case 3:
                WeightStepView(
                    weightKg: $viewModel.questionnaireData.weightKg,
                    weightLbs: $viewModel.questionnaireData.weightLbs,
                    unit: $viewModel.questionnaireData.weightUnit
                )
            default:
                EmptyView()
            }
        default:
            EmptyView()
        }
    }

    private var isCurrentStepValid: Bool {
        // Cover pages are always valid
        if currentSection == 0 || currentSection == 2 {
            return true
        }

        if currentSection == 1 {
            // Section 1 questions
            switch currentStepInSection {
            case 0: // Goals
                return !viewModel.questionnaireData.primaryGoal.isEmpty
            case 1: // Experience
                return !viewModel.questionnaireData.experienceLevel.isEmpty
            case 2: // Muscle Groups (optional, 0-3)
                let count = viewModel.questionnaireData.targetMuscleGroups.count
                return count >= 0 && count <= 3
            case 3: // Equipment
                return !viewModel.questionnaireData.equipmentAvailable.isEmpty
            case 4: // Injuries
                return true // Injuries are optional
            case 5: // Training Days
                return viewModel.questionnaireData.trainingDaysPerWeek >= 1 && viewModel.questionnaireData.trainingDaysPerWeek <= 6
            case 6: // Session Duration
                return !viewModel.questionnaireData.sessionDuration.isEmpty
            case 7: // Motivation (optional - users can proceed without selecting)
                return true
            default:
                return true
            }
        } else if currentSection == 3 {
            // Section 2 questions
            switch currentStepInSection {
            case 0: // Age
                return viewModel.questionnaireData.age >= 18
            case 1: // Gender
                return !viewModel.questionnaireData.gender.isEmpty
            case 2: // Height
                if viewModel.questionnaireData.heightUnit == .cm {
                    return viewModel.questionnaireData.heightCm >= 100 && viewModel.questionnaireData.heightCm <= 250
                } else {
                    return viewModel.questionnaireData.heightFt >= 3 && viewModel.questionnaireData.heightFt <= 8
                }
            case 3: // Weight
                if viewModel.questionnaireData.weightUnit == .kg {
                    return viewModel.questionnaireData.weightKg >= 30 && viewModel.questionnaireData.weightKg <= 200
                } else {
                    return viewModel.questionnaireData.weightLbs >= 65 && viewModel.questionnaireData.weightLbs <= 440
                }
            default:
                return true
            }
        }

        return true
    }

    // Enable scrolling only for pages that need it (equipment step has expandable content)
    private func shouldDisableScrollForCurrentStep() -> Bool {
        // Equipment step (section 1, step 3) needs scrolling for expandable categories
        if currentSection == 1 && currentStepInSection == 3 {
            return false  // Enable scrolling for equipment
        }
        return true  // All other pages are non-scrollable
    }

    private func nextStep() {
        // Check if leaving equipment step with limited equipment selection
        if currentSection == 1 && currentStepInSection == 3 {
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
        withAnimation(.easeInOut(duration: 0.15)) {  // Doubled speed (was ~0.35s default, now 0.15s)
            if currentSection == 0 {
                // Move from Section 1 cover to first question
                currentSection = 1
                currentStepInSection = 0
            } else if currentSection == 1 {
                // In Section 1 questions
                if currentStepInSection < section1TotalSteps - 1 {
                    currentStepInSection += 1
                } else {
                    // Move to Section 2 cover
                    currentSection = 2
                    currentStepInSection = 0
                }
            } else if currentSection == 2 {
                // Move from Section 2 cover to first question
                currentSection = 3
                currentStepInSection = 0
            } else if currentSection == 3 {
                // In Section 2 questions
                if currentStepInSection < section2TotalSteps - 1 {
                    currentStepInSection += 1
                } else {
                    // Complete questionnaire
                    showingProgramLoading = true
                }
            }
        }
    }

    private func previousStep() {
        withAnimation(.easeInOut(duration: 0.15)) {  // Doubled speed (was ~0.35s default, now 0.15s)
            if currentSection == 0 {
                // On Section 1 cover (Availability), go back to previous screen
                onBack?()
            } else if currentSection == 1 {
                // In Section 1 questions
                if currentStepInSection > 0 {
                    currentStepInSection -= 1
                } else {
                    // Go back to Section 1 cover
                    currentSection = 0
                }
            } else if currentSection == 3 {
                // In Section 2 questions
                if currentStepInSection > 0 {
                    currentStepInSection -= 1
                } else {
                    // Go back to Section 2 cover
                    currentSection = 2
                }
            } else if currentSection == 2 {
                // On Section 2 cover, go back to last question of Section 1
                currentSection = 1
                currentStepInSection = section1TotalSteps - 1
            }
        }
    }
}

// MARK: - Section Cover View

struct SectionCoverView: View {
    let title: String
    let subtitle: String
    let iconName: String

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            VStack(spacing: Spacing.xl) {
                // Icon - doubled in size from 48 to 96
                ZStack {
                    Circle()
                        .fill(Color.trainPrimary.opacity(0.1))
                        .frame(width: 200, height: 200)

                    Image(systemName: iconName)
                        .font(.system(size: 96))
                        .foregroundColor(.trainPrimary)
                }

                // Title - one size larger (from trainTitle 28pt to 34pt)
                Text(title)
                    .font(.system(size: 34, weight: .semibold, design: .rounded))
                    .foregroundColor(.trainTextPrimary)
                    .multilineTextAlignment(.center)

                // Subtitle - one size larger (from trainBody 16pt to 18pt)
                Text(subtitle)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(.trainTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xl)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(Spacing.lg)
    }
}

