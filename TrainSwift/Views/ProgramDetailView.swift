//
//  ProgramDetailView.swift
//  TrainSwift
//
//  Program detail page showing full program information
//  Accessed by tapping the ProgramSummaryCard on the Dashboard
//

import SwiftUI

struct ProgramDetailView: View {
    @ObservedObject private var authService = AuthService.shared
    @State private var showRetakeConfirmation = false
    @State private var shouldRestartQuestionnaire = false

    private var program: Program? {
        authService.getCurrentProgram()?.getProgram()
    }

    private var questionnaireData: QuestionnaireData? {
        authService.currentUser?.getQuestionnaireData()
    }

    private var userName: String {
        if let name = authService.currentUser?.name, !name.isEmpty {
            let firstName = name.components(separatedBy: " ").first ?? name
            return firstName.prefix(1).uppercased() + firstName.dropFirst().lowercased()
        }
        return "Your"
    }

    private var experienceLevelLabel: String {
        guard let qData = questionnaireData, !qData.experienceLevel.isEmpty else {
            return "N/A"
        }
        switch qData.experienceLevel.lowercased() {
        case "0_months", "no_experience":
            return "Beginner"
        case "0_6_months", "beginner":
            return "Beginner"
        case "6_months_2_years", "intermediate":
            return "Intermediate"
        case "2_plus_years", "advanced":
            return "Advanced"
        default:
            return qData.experienceLevel.capitalized
        }
    }

    private var sessionDurationLabel: String {
        if let qData = questionnaireData, !qData.sessionDuration.isEmpty {
            return qData.sessionDuration
        }
        return program?.sessionDuration.rawValue ?? "N/A"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                if let program = program {
                    // Experience Level Card
                    DetailInfoCard(label: "Experience Level", value: experienceLevelLabel)

                    // Split Card
                    DetailInfoCard(label: "Split", value: program.type.description)

                    // Duration + Frequency side by side
                    HStack(spacing: Spacing.md) {
                        DetailInfoCard(label: "Duration", value: sessionDurationLabel)
                        DetailInfoCard(label: "Frequency", value: "\(program.daysPerWeek) days/week")
                    }

                    // Priority Muscle Groups
                    PriorityMuscleGroupsSection(
                        muscleGroups: getPriorityMuscleGroups(),
                        gender: getUserGender()
                    )

                    // Generate New Programme button
                    Button(action: {
                        showRetakeConfirmation = true
                    }) {
                        Text("Generate New Programme")
                            .font(.trainBodyMedium)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.sm)
                            .background(Color.trainPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm, style: .continuous))
                    }
                    .accessibilityHint("Retake the questionnaire to generate a new program")
                } else {
                    Text("No program found")
                        .font(.trainBody)
                        .foregroundColor(.trainTextSecondary)
                        .padding(.top, Spacing.xxl)
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.lg)
        }
        .scrollContentBackground(.hidden)
        .charcoalGradientBackground()
        .navigationTitle("\(userName)'s Program")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Generate New Programme", isPresented: $showRetakeConfirmation, titleVisibility: .visible) {
            Button("Save & Retake") {
                retakeDebugLog("RETAKE", "confirmation.saveAndRetake", [
                    "action": "Saving current program and starting retake flow"
                ])
                WorkoutViewModel.shared.questionnaireData = QuestionnaireData()
                shouldRestartQuestionnaire = true
            }
            Button("Discard & Retake", role: .destructive) {
                retakeDebugLog("RETAKE", "confirmation.discardAndRetake", [
                    "action": "Discarding current program and starting retake flow"
                ])
                if let currentProgram = authService.getCurrentProgram() {
                    let context = PersistenceController.shared.container.viewContext
                    context.delete(currentProgram)
                    try? context.save()
                }
                WorkoutViewModel.shared.questionnaireData = QuestionnaireData()
                shouldRestartQuestionnaire = true
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Would you like to save your current program? You can switch back to it later in 'Switch Programs'.")
        }
        .fullScreenCover(isPresented: $shouldRestartQuestionnaire) {
            OnboardingFlowView(isRetake: true)
                .environmentObject(WorkoutViewModel.shared)
                .onDisappear {
                    shouldRestartQuestionnaire = false
                }
        }
    }

    // MARK: - Helper Methods

    private func getPriorityMuscleGroups() -> [String] {
        guard let user = authService.currentUser,
              let priorityArray = user.priorityMuscles as? [String],
              !priorityArray.isEmpty else {
            return ["Chest", "Quads", "Shoulders"]
        }
        return priorityArray.prefix(3).map { muscle in
            muscle.trimmingCharacters(in: CharacterSet.whitespaces)
        }
    }

    private func getUserGender() -> MuscleSelector.BodyGender {
        guard let qData = questionnaireData else { return .male }
        switch qData.gender.lowercased() {
        case "female":
            return .female
        default:
            return .male
        }
    }

    private func retakeDebugLog(_ category: String, _ action: String, _ params: [String: String]) {
        var message = "[PROGRAM-DETAIL-\(category)] \(action)"
        if !params.isEmpty {
            let paramString = params.map { "\($0.key)=\($0.value)" }.sorted().joined(separator: " | ")
            message += " | \(paramString)"
        }
        AppLogger.logUI(message)
    }
}

// MARK: - Detail Info Card

private struct DetailInfoCard: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .center, spacing: Spacing.sm) {
            Text(label)
                .font(.trainCaption)
                .foregroundColor(.trainTextSecondary)
            Text(value)
                .font(.trainBodyMedium)
                .foregroundColor(.trainTextPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.md)
        .appCard(cornerRadius: CornerRadius.md)
    }
}

// MARK: - Priority Muscle Groups Section

private struct PriorityMuscleGroupsSection: View {
    let muscleGroups: [String]
    let gender: MuscleSelector.BodyGender

    var body: some View {
        VStack(spacing: Spacing.md) {
            Text("Priority Muscle Groups")
                .font(.trainCaption)
                .foregroundColor(.trainTextSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: Spacing.lg) {
                ForEach(muscleGroups, id: \.self) { muscleGroup in
                    VStack(spacing: Spacing.sm) {
                        StaticMuscleView(
                            muscleGroup: muscleGroup,
                            gender: gender,
                            size: 90,
                            useUniformBaseColor: true
                        )
                        .frame(width: 90, height: 90)

                        Text(muscleGroup)
                            .font(.trainCaption)
                            .foregroundColor(.trainTextSecondary)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(Spacing.md)
        .appCard(cornerRadius: CornerRadius.md)
    }
}

#Preview {
    NavigationStack {
        ProgramDetailView()
    }
}
