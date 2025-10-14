//
//  QuestionnaireView.swift
//  trAInApp
//
//  Updated with new 10-step questionnaire
//

import SwiftUI

struct QuestionnaireView: View {
    @EnvironmentObject var viewModel: WorkoutViewModel
    @State private var currentStep = 1
    @State private var showingProgrammeLoading = false
    @State private var showingProgrammeReady = false

    let onComplete: () -> Void
    let totalSteps = 10

    var body: some View {
        ZStack {
            if showingProgrammeReady {
                ProgrammeReadyView(onStart: {
                    viewModel.completeQuestionnaire()
                    onComplete()
                })
            } else if showingProgrammeLoading {
                ProgrammeLoadingView(onComplete: {
                    withAnimation {
                        showingProgrammeReady = true
                    }
                })
            } else {
                VStack(spacing: 0) {
                    // Back button and progress bar
                    VStack(spacing: 0) {
                        HStack {
                            if currentStep > 1 {
                                Button(action: previousStep) {
                                    Image(systemName: "arrow.left")
                                        .font(.title3)
                                        .foregroundColor(.trainTextPrimary)
                                }
                            }
                            Spacer()
                        }
                        .padding(16)

                        QuestionnaireProgressBar(currentStep: currentStep, totalSteps: totalSteps)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 16)
                    }

                    // Current step content
                    ScrollView {
                        VStack(spacing: 32) {
                            currentStepView
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                    }

                    // Continue button
                    VStack {
                        CustomButton(
                            title: currentStep == totalSteps ? "Complete" : "Continue",
                            action: nextStep,
                            isEnabled: isCurrentStepValid
                        )
                        .padding(16)
                    }
                    .background(Color.white)
                }
                .background(Color.trainBackground)
            }
        }
    }

    @ViewBuilder
    private var currentStepView: some View {
        switch currentStep {
        case 1:
            GenderStepView(selectedGender: $viewModel.questionnaireData.gender)
        case 2:
            AgeStepView(age: $viewModel.questionnaireData.age)
        case 3:
            HeightStepView(
                heightCm: $viewModel.questionnaireData.heightCm,
                heightFt: $viewModel.questionnaireData.heightFt,
                heightIn: $viewModel.questionnaireData.heightIn,
                unit: $viewModel.questionnaireData.heightUnit
            )
        case 4:
            WeightStepView(
                weightKg: $viewModel.questionnaireData.weightKg,
                weightLbs: $viewModel.questionnaireData.weightLbs,
                unit: $viewModel.questionnaireData.weightUnit
            )
        case 5:
            GoalsStepView(selectedGoal: $viewModel.questionnaireData.primaryGoal)
        case 6:
            MuscleGroupsStepView(selectedGroups: $viewModel.questionnaireData.targetMuscleGroups)
        case 7:
            ExperienceStepView(experience: $viewModel.questionnaireData.experienceLevel)
        case 8:
            MotivationStepView(
                selectedMotivations: $viewModel.questionnaireData.motivations,
                otherText: $viewModel.questionnaireData.motivationOther
            )
        case 9:
            EquipmentStepView(selectedEquipment: $viewModel.questionnaireData.equipmentAvailable)
        case 10:
            TrainingDaysStepView(trainingDays: $viewModel.questionnaireData.trainingDaysPerWeek)
        default:
            EmptyView()
        }
    }

    private var isCurrentStepValid: Bool {
        switch currentStep {
        case 1:
            return !viewModel.questionnaireData.gender.isEmpty
        case 2:
            return viewModel.questionnaireData.age >= 18
        case 3:
            if viewModel.questionnaireData.heightUnit == .cm {
                return viewModel.questionnaireData.heightCm >= 100 && viewModel.questionnaireData.heightCm <= 250
            } else {
                return viewModel.questionnaireData.heightFt >= 3 && viewModel.questionnaireData.heightFt <= 8
            }
        case 4:
            if viewModel.questionnaireData.weightUnit == .kg {
                return viewModel.questionnaireData.weightKg >= 30 && viewModel.questionnaireData.weightKg <= 200
            } else {
                return viewModel.questionnaireData.weightLbs >= 65 && viewModel.questionnaireData.weightLbs <= 440
            }
        case 5:
            return !viewModel.questionnaireData.primaryGoal.isEmpty
        case 6:
            let count = viewModel.questionnaireData.targetMuscleGroups.count
            return count >= 1 && count <= 3
        case 7:
            return !viewModel.questionnaireData.experienceLevel.isEmpty
        case 8:
            if viewModel.questionnaireData.motivations.contains("other") {
                return !viewModel.questionnaireData.motivationOther.isEmpty
            }
            return !viewModel.questionnaireData.motivations.isEmpty
        case 9:
            return !viewModel.questionnaireData.equipmentAvailable.isEmpty
        case 10:
            return viewModel.questionnaireData.trainingDaysPerWeek >= 2
        default:
            return true
        }
    }

    private func nextStep() {
        if currentStep < totalSteps {
            withAnimation {
                currentStep += 1
            }
        } else {
            // Complete questionnaire
            withAnimation {
                showingProgrammeLoading = true
            }
        }
    }

    private func previousStep() {
        if currentStep > 1 {
            withAnimation {
                currentStep -= 1
            }
        }
    }
}
