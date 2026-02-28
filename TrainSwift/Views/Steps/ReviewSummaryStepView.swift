//
//  ReviewSummaryStepView.swift
//  TrainSwift
//
//  Summary step shown before program generation so users can review their choices
//

import SwiftUI

struct ReviewSummaryStepView: View {
    let questionnaireData: QuestionnaireData
    let onEdit: (Int) -> Void  // Step number to navigate to

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            VStack(alignment: .center, spacing: Spacing.sm) {
                Text("Review Your Choices")
                    .font(.trainTitle2)
                    .foregroundColor(.trainTextPrimary)

                Text("Make sure everything looks right")
                    .font(.trainSubtitle)
                    .foregroundColor(.trainTextSecondary)
            }
            .frame(maxWidth: .infinity)

            VStack(spacing: Spacing.sm) {
                reviewRow(title: "Goals", value: questionnaireData.primaryGoals.joined(separator: ", "), editStep: 0)
                reviewRow(title: "Experience", value: questionnaireData.experienceLevel.replacingOccurrences(of: "_", with: " ").capitalized, editStep: questionnaireData.skipHeightWeight ? 3 : 4)
                reviewRow(title: "Training Days", value: "\(questionnaireData.trainingDaysPerWeek) days/week", editStep: questionnaireData.skipHeightWeight ? 5 : 6)
                reviewRow(title: "Split", value: questionnaireData.selectedSplit, editStep: questionnaireData.skipHeightWeight ? 6 : 7)
                reviewRow(title: "Duration", value: questionnaireData.sessionDuration, editStep: questionnaireData.skipHeightWeight ? 7 : 8)
                reviewRow(title: "Equipment", value: "\(questionnaireData.equipmentAvailable.count) categories", editStep: questionnaireData.skipHeightWeight ? 9 : 10)
            }

            Spacer()
        }
    }

    @ViewBuilder
    private func reviewRow(title: String, value: String, editStep: Int) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(title)
                    .font(.trainCaption)
                    .foregroundColor(.trainTextSecondary)
                Text(value.isEmpty ? "Not set" : value)
                    .font(.trainBodyMedium)
                    .foregroundColor(.trainTextPrimary)
            }

            Spacer()

            Button(action: { onEdit(editStep) }) {
                Text("Edit")
                    .font(.trainCaption)
                    .foregroundColor(.trainPrimary)
            }
        }
        .padding(Spacing.md)
        .appCard()
    }
}
