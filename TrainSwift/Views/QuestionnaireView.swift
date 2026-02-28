//
//  QuestionnaireView.swift
//  TrainSwift
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

    /// Unique ID for this instance to track in logs
    private let instanceId = UUID().uuidString.prefix(8)

    // Total steps: Main questionnaire flow (referral moved to post-signup)
    var totalSteps: Int {
        return 14  // Steps 0-13: Goal → Name → HealthProfile → [HeightWeight] → Experience → [Interstitial1] → Days → Split → Duration → TrainingPlace → Equipment → [Interstitial2] → Muscles → Injuries
        // Referral tracking happens after signup in the post-questionnaire flow
    }

    var body: some View {
        ZStack {
            if (showingProgramReady || isSignupInProgress), let program = viewModel.generatedProgram {
                ProgramReadyView(
                    program: program,
                    onStart: {
                        questionnaireDebugLog("READY", "ProgramReadyView.onStart", [
                            "instanceId": String(instanceId),
                            "action": "Completing questionnaire"
                        ])
                        let hasWarnings = viewModel.completeQuestionnaire()
                        if hasWarnings {
                            questionnaireDebugLog("READY", "warnings.shown", [
                                "instanceId": String(instanceId),
                                "action": "Waiting for user decision on warnings"
                            ])
                            // Don't call onComplete() - wait for user to choose Amend or Proceed
                        } else {
                            questionnaireDebugLog("READY", "noWarnings.proceeding", [
                                "instanceId": String(instanceId),
                                "action": "No warnings - proceeding to dashboard"
                            ])
                            onComplete()
                        }
                    },
                    onSignupStart: {
                        questionnaireDebugLog("SIGNUP", "signupProcess.started", [
                            "instanceId": String(instanceId),
                            "previousIsSignupInProgress": "\(isSignupInProgress)"
                        ])
                        isSignupInProgress = true
                        // Clear any pending warnings - user proceeding to signup means they accept the program
                        viewModel.proceedAfterWarning()
                    },
                    onSignupCancel: {
                        questionnaireDebugLog("SIGNUP", "signupProcess.cancelled", [
                            "instanceId": String(instanceId)
                        ])
                        isSignupInProgress = false
                    },
                    selectedMuscleGroups: viewModel.questionnaireData.targetMuscleGroups
                )
                .onAppear {
                    questionnaireDebugLog("READY", "ProgramReadyView.onAppear", [
                        "instanceId": String(instanceId),
                        "programType": program.type.rawValue
                    ])
                }
            } else if showingProgramLoading {
                if isSignupInProgress {
                    // This is the key fix - we DON'T show ProgramLoadingView during signup
                    EmptyView()
                        .onAppear {
                            questionnaireDebugLog("LOADING", "ProgramLoadingView.blocked", [
                                "instanceId": String(instanceId),
                                "reason": "isSignupInProgress = true"
                            ])
                        }
                } else {
                    ProgramLoadingView(onComplete: {

                        // Guard against race conditions during signup
                        guard !isSignupInProgress else {
                            questionnaireDebugLog("LOADING", "ProgramLoadingView.completion.blocked", [
                                "instanceId": String(instanceId),
                                "reason": "isSignupInProgress = true"
                            ])
                            return
                        }

                        // Only generate program if not already generated
                        if viewModel.generatedProgram == nil {
                            questionnaireDebugLog("PROGRAM", "generateProgram.starting", [
                                "instanceId": String(instanceId)
                            ])
                            viewModel.generateProgram()
                        } else {
                            questionnaireDebugLog("PROGRAM", "generateProgram.skipped", [
                                "instanceId": String(instanceId),
                                "reason": "Program already exists"
                            ])
                        }

                        // Removed animation for instant transition
                        showingProgramReady = true
                    })
                    .onAppear {
                        questionnaireDebugLog("LOADING", "ProgramLoadingView.onAppear", [
                            "instanceId": String(instanceId),
                            "currentStep": "\(currentStep)"
                        ])
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
                        .padding(Spacing.md)

                        QuestionnaireProgressBar(currentStep: currentStep + 1, totalSteps: totalSteps)
                            .padding(.horizontal, Spacing.md)
                            .padding(.bottom, Spacing.md)
                    }

                    // Content + Button in ZStack so content scrolls behind button
                    ZStack(alignment: .bottom) {
                        // Content area - fills available space
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: Spacing.xl) {
                                currentStepView
                            }
                            .padding(.horizontal, Spacing.md)
                            .padding(.top, Spacing.md)
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
                        .padding(.horizontal, Spacing.md)
                        .padding(.bottom, Spacing.md)
                    }
                }
            }
        }
        .charcoalGradientBackground()
        .onAppear {
            questionnaireDebugLog("VIEW", "QuestionnaireView.onAppear", [
                "instanceId": String(instanceId),
                "currentStep": "\(currentStep)",
                "stepName": stepName(for: currentStep),
                "showingProgramLoading": "\(showingProgramLoading)",
                "showingProgramReady": "\(showingProgramReady)",
                "isSignupInProgress": "\(isSignupInProgress)",
                "status": "✅ QUESTIONNAIRE IS VISIBLE (Step 0 = Goal)"
            ])
        }
        .alert(viewModel.warningAlertTitle, isPresented: $viewModel.showWarningAlert) {
            Button("Amend Equipment") {
                questionnaireDebugLog("WARNING", "amendEquipment.selected", [
                    "instanceId": String(instanceId),
                    "action": "Navigating back to equipment step"
                ])
                viewModel.dismissWarningAlert()
                // Navigate back to equipment step
                navigateToEquipmentStep()
            }
            Button("Proceed Anyway", role: .destructive) {
                questionnaireDebugLog("WARNING", "proceedAnyway.selected", [
                    "instanceId": String(instanceId),
                    "action": "Completing questionnaire with limited exercises"
                ])
                viewModel.dismissWarningAlert()
                // Complete the questionnaire and go to dashboard
                viewModel.proceedAfterWarning()
                onComplete()
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
        if currentStep == 13 { // Injuries step (final step)
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
        case 8: // Session Duration OR Training Place
            if !skipHeightWeight {
                SessionDurationStepView(sessionDuration: $viewModel.questionnaireData.sessionDuration)
            } else {
                TrainingPlaceStepView(selectedTrainingPlace: $viewModel.questionnaireData.trainingPlace)
            }
        case 9: // Training Place OR Equipment
            if !skipHeightWeight {
                TrainingPlaceStepView(selectedTrainingPlace: $viewModel.questionnaireData.trainingPlace)
            } else {
                EquipmentStepView(
                    selectedEquipment: $viewModel.questionnaireData.equipmentAvailable,
                    selectedDetailedEquipment: $viewModel.questionnaireData.detailedEquipment
                )
            }
        case 10: // Equipment OR Second Video Interstitial
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
        case 11: // Second Video Interstitial OR Muscle Groups
            if !skipHeightWeight {
                SecondVideoInterstitialView(
                    onComplete: proceedToNextStep,
                    onBack: previousStep,
                    currentStep: currentStep + 1,
                    totalSteps: totalSteps
                )
            } else {
                MuscleGroupsStepView(selectedGroups: $viewModel.questionnaireData.targetMuscleGroups, gender: viewModel.questionnaireData.gender)
            }
        case 12: // Muscle Groups OR Injuries
            if !skipHeightWeight {
                MuscleGroupsStepView(selectedGroups: $viewModel.questionnaireData.targetMuscleGroups, gender: viewModel.questionnaireData.gender)
            } else {
                InjuriesStepView(injuries: $viewModel.questionnaireData.injuries)
            }
        case 13: // Injuries (final step)
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
        case 8: // Session Duration OR Training Place
            if !skipHeightWeight {
                return !viewModel.questionnaireData.sessionDuration.isEmpty
            } else {
                return !viewModel.questionnaireData.trainingPlace.isEmpty
            }
        case 9: // Training Place OR Equipment
            if !skipHeightWeight {
                return !viewModel.questionnaireData.trainingPlace.isEmpty
            } else {
                return !viewModel.questionnaireData.equipmentAvailable.isEmpty
            }
        case 10: // Equipment OR Second Video Interstitial
            if !skipHeightWeight {
                return !viewModel.questionnaireData.equipmentAvailable.isEmpty
            } else {
                return true // Video interstitial always valid
            }
        case 11: // Second Video Interstitial OR Muscle Groups
            if !skipHeightWeight {
                return true // Video interstitial always valid
            } else {
                let count = viewModel.questionnaireData.targetMuscleGroups.count
                return count >= 0 && count <= 3
            }
        case 12: // Muscle Groups OR Injuries
            if !skipHeightWeight {
                let count = viewModel.questionnaireData.targetMuscleGroups.count
                return count >= 0 && count <= 3
            } else {
                return true // Injuries optional
            }
        case 13: // Injuries (final step)
            return true // Injuries optional
        default:
            return true
        }
    }

    // Enable scrolling only for pages that need it (equipment step has expandable content)
    private func shouldDisableScrollForCurrentStep() -> Bool {
        let skipHeightWeight = viewModel.questionnaireData.skipHeightWeight

        // Equipment step needs scrolling for expandable categories
        if (!skipHeightWeight && currentStep == 10) || (skipHeightWeight && currentStep == 9) {
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

        questionnaireDebugLog("NAV", "nextStep.called", [
            "instanceId": String(instanceId),
            "currentStep": "\(currentStep)",
            "skipHeightWeight": "\(skipHeightWeight)",
            "stepName": stepName(for: currentStep)
        ])

        // Apply gym type preset when leaving Training Place step (before entering Equipment step)
        if (!skipHeightWeight && currentStep == 9) || (skipHeightWeight && currentStep == 8) {
            applyGymTypePreset()
        }

        // Check if leaving equipment step with limited equipment selection
        if (!skipHeightWeight && currentStep == 10) || (skipHeightWeight && currentStep == 9) {
            let equipmentCount = viewModel.questionnaireData.equipmentAvailable.count
            let equipmentList = viewModel.questionnaireData.equipmentAvailable

            questionnaireDebugLog("EQUIPMENT", "validation.triggered", [
                "instanceId": String(instanceId),
                "equipmentCount": "\(equipmentCount)",
                "equipmentList": "\(equipmentList)",
                "hasSeenWarning": "\(hasSeenEquipmentWarning)"
            ])

            if equipmentCount <= 2 && !hasSeenEquipmentWarning {
                questionnaireDebugLog("EQUIPMENT", "warning.showing", [
                    "instanceId": String(instanceId),
                    "equipmentCount": "\(equipmentCount)"
                ])
                showingEquipmentWarning = true
                return
            }
        }

        proceedToNextStep()
    }

    private func proceedFromEquipmentStep() {
        questionnaireDebugLog("EQUIPMENT", "warning.dismissed", [
            "instanceId": String(instanceId),
            "action": "Proceeding with limited equipment"
        ])
        hasSeenEquipmentWarning = true
        proceedToNextStep()
    }

    private func proceedToNextStep() {
        questionnaireDebugLog("NAV", "proceedToNextStep", [
            "instanceId": String(instanceId),
            "fromStep": "\(currentStep)",
            "toStep": currentStep == 13 ? "LOADING" : "\(currentStep + 1)",
            "isSignupInProgress": "\(isSignupInProgress)"
        ])

        // Guard against race conditions during signup
        guard !isSignupInProgress else {
            questionnaireDebugLog("NAV", "proceedToNextStep.blocked", [
                "instanceId": String(instanceId),
                "reason": "isSignupInProgress = true"
            ])
            return
        }

        // Removed withAnimation for instant, smooth transitions especially for video interstitials
        if currentStep == 13 {
            questionnaireDebugLog("NAV", "finalStep.reached", [
                "instanceId": String(instanceId),
                "action": "Starting program loading"
            ])
            showingProgramLoading = true
        } else {
            currentStep += 1
            questionnaireDebugLog("NAV", "step.advanced", [
                "instanceId": String(instanceId),
                "newStep": "\(currentStep)",
                "stepName": stepName(for: currentStep)
            ])
        }
    }

    /// Get human-readable step name for debugging
    private func stepName(for step: Int) -> String {
        let skipHeightWeight = viewModel.questionnaireData.skipHeightWeight
        let names: [String]
        if skipHeightWeight {
            names = ["Goal", "Name", "HealthProfile", "Experience", "Interstitial1", "Days", "Split", "Duration", "TrainingPlace", "Equipment", "Interstitial2", "Muscles", "Injuries", "FINAL"]
        } else {
            names = ["Goal", "Name", "HealthProfile", "HeightWeight", "Experience", "Interstitial1", "Days", "Split", "Duration", "TrainingPlace", "Equipment", "Interstitial2", "Muscles", "Injuries"]
        }
        return step < names.count ? names[step] : "Unknown(\(step))"
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
            return currentStep == 5 || currentStep == 11  // First and Second interstitial
        } else {
            return currentStep == 4 || currentStep == 10
        }
    }

    /// Apply gym type preset to pre-select equipment based on training place
    private func applyGymTypePreset() {
        let gymType = viewModel.questionnaireData.trainingPlace
        guard !gymType.isEmpty else {
            questionnaireDebugLog("PRESET", "applyGymTypePreset.skipped", [
                "instanceId": String(instanceId),
                "reason": "No training place selected"
            ])
            return
        }

        guard let preset = ConstantsManager.shared.getEquipmentForGymType(gymType) else {
            questionnaireDebugLog("PRESET", "applyGymTypePreset.failed", [
                "instanceId": String(instanceId),
                "gymType": gymType,
                "reason": "Unknown gym type"
            ])
            return
        }

        questionnaireDebugLog("PRESET", "applyGymTypePreset.applying", [
            "instanceId": String(instanceId),
            "gymType": gymType,
            "categories": "\(preset.categories.count)",
            "attachments": "\(preset.attachments.count)"
        ])

        // Update equipment categories
        viewModel.questionnaireData.equipmentAvailable = preset.categories

        // Update detailed equipment (specific items)
        viewModel.questionnaireData.detailedEquipment = preset.specific

        // Update attachments if present
        if !preset.attachments.isEmpty {
            viewModel.questionnaireData.detailedEquipment["attachments"] = preset.attachments
        }

        questionnaireDebugLog("PRESET", "applyGymTypePreset.complete", [
            "instanceId": String(instanceId),
            "equipmentCount": "\(viewModel.questionnaireData.equipmentAvailable.count)"
        ])
    }

    /// Navigate back to equipment step from warning modal
    private func navigateToEquipmentStep() {
        let skipHeightWeight = viewModel.questionnaireData.skipHeightWeight
        let equipmentStep = skipHeightWeight ? 9 : 10

        questionnaireDebugLog("NAV", "navigateToEquipmentStep", [
            "instanceId": String(instanceId),
            "fromStep": "\(currentStep)",
            "toStep": "\(equipmentStep)",
            "skipHeightWeight": "\(skipHeightWeight)"
        ])

        // Reset program generation state
        showingProgramLoading = false
        showingProgramReady = false
        isSignupInProgress = false

        // Reset warning seen flag so they can proceed after adding equipment
        hasSeenEquipmentWarning = false

        // Navigate to equipment step
        currentStep = equipmentStep
    }
}

// MARK: - Debug Logging Helper

private func questionnaireDebugLog(_ category: String, _ action: String, _ params: [String: String] = [:]) {
    var message = "[QUESTIONNAIRE-\(category)] \(action)"
    if !params.isEmpty {
        let paramString = params.map { "\($0.key)=\($0.value)" }.sorted().joined(separator: " | ")
        message += " | \(paramString)"
    }
    AppLogger.logUI(message)
}

