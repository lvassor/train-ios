//
//  QuestionnaireView.swift
//  trAInApp
//
//  Updated with new 10-step questionnaire
//

import SwiftUI

struct QuestionnaireView: View {
    @ObservedObject var viewModel = WorkoutViewModel.shared
    // Simplified flow: single sequence of questions (no sections/covers)
    @State private var currentStep = 0
    @State private var showingProgramLoading = false
    @State private var showingProgramReady = false
    @State private var showingEquipmentWarning = false
    @State private var hasSeenEquipmentWarning = false
    @State private var isSignupInProgress = false  // Safeguard to prevent state conflicts during signup

    let onComplete: () -> Void
    var onBack: (() -> Void)? = nil

    // Total steps: Main questionnaire flow (referral moved to post-signup)
    var totalSteps: Int {
        return 13  // Steps 0-12: Goal → Name → HealthProfile → [HeightWeight] → Experience → [Interstitial1] → Days → Split → Duration → Equipment → [Interstitial2] → Muscles → Injuries
        // Referral tracking happens after signup in the post-questionnaire flow
    }

    var body: some View {
        ZStack {
            if (showingProgramReady || isSignupInProgress), let program = viewModel.generatedProgram {
                ProgramReadyView(
                    program: program,
                    onStart: {
                        print("📝 [QUESTIONNAIRE] ProgramReadyView onStart called - completing questionnaire")
                        viewModel.completeQuestionnaire()
                        onComplete()
                    },
                    onSignupStart: {
                        print("📝 [QUESTIONNAIRE] 🚨🚨🚨 SIGNUP STARTING - Setting isSignupInProgress = true to prevent race conditions 🚨🚨🚨")
                        isSignupInProgress = true
                        print("📝 [QUESTIONNAIRE] ✅ isSignupInProgress flag is now: \(isSignupInProgress)")
                        print("📝 [QUESTIONNAIRE] 🛡️ QuestionnaireView is now PROTECTED from state changes during signup")
                    },
                    onSignupCancel: {
                        print("📝 [QUESTIONNAIRE] 🚫 SIGNUP CANCELLED - Resetting isSignupInProgress = false to remove protection")
                        isSignupInProgress = false
                        print("📝 [QUESTIONNAIRE] ✅ isSignupInProgress flag is now: \(isSignupInProgress)")
                        print("📝 [QUESTIONNAIRE] 🔓 QuestionnaireView protection removed - normal operation restored")
                    },
                    selectedMuscleGroups: viewModel.questionnaireData.targetMuscleGroups
                )
                .onAppear {
                    print("📝 [QUESTIONNAIRE] VIEW STATE: Showing ProgramReadyView (showingProgramReady: \(showingProgramReady), isSignupInProgress: \(isSignupInProgress))")
                }
            } else if showingProgramLoading {
                if isSignupInProgress {
                    // This is the key fix - we DON'T show ProgramLoadingView during signup
                    EmptyView()
                        .onAppear {
                            print("📝 [QUESTIONNAIRE] 🛡️🛡️🛡️ showingProgramLoading=true BUT isSignupInProgress=true - BLOCKING ProgramLoadingView! 🛡️🛡️🛡️")
                            print("📝 [QUESTIONNAIRE] 🚨 This prevents the race condition bug from happening!")
                        }
                } else {
                    ProgramLoadingView(onComplete: {
                        print("📝 [QUESTIONNAIRE] ProgramLoadingView completed")

                        // Guard against race conditions during signup
                        guard !isSignupInProgress else {
                            print("📝 [QUESTIONNAIRE] 🛡️🛡️🛡️ RACE CONDITION BLOCKED! Signup in progress - ignoring ProgramLoadingView completion 🛡️🛡️🛡️")
                            print("📝 [QUESTIONNAIRE] 🚨 This would have caused the bug - program regeneration prevented!")
                            return
                        }

                        // Only generate program if not already generated
                        if viewModel.generatedProgram == nil {
                            print("📝 [QUESTIONNAIRE] Generating program...")
                            viewModel.generateProgram()
                        } else {
                            print("📝 [QUESTIONNAIRE] Program already exists")
                        }

                        // Removed animation for instant transition
                        print("📝 [QUESTIONNAIRE] Setting showingProgramReady = true")
                        showingProgramReady = true
                    })
                    .onAppear {
                        print("📝 [QUESTIONNAIRE] VIEW STATE: Showing ProgramLoadingView")
                    }
                }
            } else if isVideoInterstitialStep {
                // Video interstitials rendered at ROOT level - full screen
                currentStepView
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
        if currentStep == 12 { // Injuries step (final step)
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
                FirstVideoInterstitialView(
                    onComplete: proceedToNextStep,
                    onBack: previousStep,
                    currentStep: currentStep + 1,
                    totalSteps: totalSteps
                )
            }
        case 5: // First Video Interstitial OR Training Days
            if !skipHeightWeight {
                FirstVideoInterstitialView(
                    onComplete: proceedToNextStep,
                    onBack: previousStep,
                    currentStep: currentStep + 1,
                    totalSteps: totalSteps
                )
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
                SecondVideoInterstitialView(
                    onComplete: proceedToNextStep,
                    onBack: previousStep,
                    currentStep: currentStep + 1,
                    totalSteps: totalSteps
                )
            }
        case 10: // Second Video Interstitial OR Muscle Groups
            if !skipHeightWeight {
                SecondVideoInterstitialView(
                    onComplete: proceedToNextStep,
                    onBack: previousStep,
                    currentStep: currentStep + 1,
                    totalSteps: totalSteps
                )
            } else {
                MuscleGroupsStepView(selectedGroups: $viewModel.questionnaireData.targetMuscleGroups)
            }
        case 11: // Muscle Groups OR Injuries
            if !skipHeightWeight {
                MuscleGroupsStepView(selectedGroups: $viewModel.questionnaireData.targetMuscleGroups)
            } else {
                InjuriesStepView(injuries: $viewModel.questionnaireData.injuries)
            }
        case 12: // Injuries (final step)
            InjuriesStepView(injuries: $viewModel.questionnaireData.injuries)
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
        case 12: // Injuries (final step)
            return true // Injuries optional
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
        print("📝 [QUESTIONNAIRE] proceedToNextStep called, currentStep: \(currentStep), isSignupInProgress: \(isSignupInProgress)")

        // Guard against race conditions during signup
        guard !isSignupInProgress else {
            print("📝 [QUESTIONNAIRE] 🛡️🛡️🛡️ RACE CONDITION BLOCKED! Signup in progress - ignoring proceedToNextStep 🛡️🛡️🛡️")
            print("📝 [QUESTIONNAIRE] 🚨 This would have caused the bug - navigation prevented during signup!")
            return
        }

        // Removed withAnimation for instant, smooth transitions especially for video interstitials
        if currentStep == 12 {
            print("📝 [QUESTIONNAIRE] Final step reached (12) - triggering program loading")
            // After injuries step (12), complete questionnaire and show program loading
            // The flow should be: Injuries → Loading → Program Ready → Signup → Notifications → Referral → Dashboard
            showingProgramLoading = true
        } else {
            print("📝 [QUESTIONNAIRE] Moving to next step: \(currentStep + 1)")
            // Continue through regular questionnaire steps (0-11)
            currentStep += 1
        }
    }

    private func previousStep() {
        // Removed withAnimation for instant, smooth transitions
        if currentStep > 0 {
            currentStep -= 1
        } else {
            // Go back to home screen
            onBack?()
        }
    }

    // Check if current step is a video interstitial
    private var isVideoInterstitialStep: Bool {
        let skipHeightWeight = viewModel.questionnaireData.skipHeightWeight
        if !skipHeightWeight {
            return currentStep == 5 || currentStep == 10  // First and Second interstitial
        } else {
            return currentStep == 4 || currentStep == 9
        }
    }
}

