//
//  WorkoutShareCardGenerator.swift
//  TrainSwift
//
//  Generates a branded 1080x1920 workout share card image (Instagram Story size)
//

import SwiftUI
import UIKit

// MARK: - Share Card Generator

struct WorkoutShareCardGenerator {

    struct ShareData {
        let sessionName: String
        let date: Date
        let durationMinutes: Int
        let exercises: [LoggedExercise]
        let pbs: [(exerciseName: String, previousWeight: Double, newWeight: Double)]
        let streakCount: Int
    }

    @MainActor
    static func generateImage(from data: ShareData) -> UIImage? {
        let cardView = WorkoutShareCardView(data: data)
        let renderer = ImageRenderer(content: cardView.frame(width: 1080, height: 1920))
        renderer.scale = 1.0
        return renderer.uiImage
    }
}

// MARK: - Share Card View

private struct WorkoutShareCardView: View {
    let data: WorkoutShareCardGenerator.ShareData

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: data.date)
    }

    private var formattedDuration: String {
        let hours = data.durationMinutes / 60
        let mins = data.durationMinutes % 60
        if hours > 0 {
            return "\(hours)h \(mins)m"
        }
        return "\(mins) min"
    }

    var body: some View {
        ZStack {
            // Background gradient matching app theme
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(.trainGradientLight),
                    Color(.trainGradientMid),
                    Color(.trainGradientDark)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 0) {
                // Logo watermark
                headerSection
                    .padding(.top, 80)

                Spacer().frame(height: 60)

                // Session title and metadata
                titleSection

                Spacer().frame(height: 48)

                // Personal bests section (if any)
                if !data.pbs.isEmpty {
                    pbSection
                    Spacer().frame(height: 48)
                }

                // Exercise list
                exerciseListSection

                Spacer()

                // Streak footer
                if data.streakCount > 0 {
                    streakSection
                }

                Spacer().frame(height: 80)
            }
            .padding(.horizontal, 64)
        }
        .environment(\.colorScheme, .dark)
    }

    // MARK: - Header

    private var headerSection: some View {
        Image("TrainLogoWithText")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(height: 40)
            .opacity(0.3)
    }

    // MARK: - Title

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(data.sessionName)
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .foregroundColor(Color(.trainTextPrimary))
                .lineLimit(2)

            Text("\(formattedDate)  \u{2022}  \(formattedDuration)")
                .font(.system(size: 32, weight: .medium, design: .rounded))
                .foregroundColor(Color(.trainTextSecondary))
        }
    }

    // MARK: - Personal Bests

    private var pbSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 12) {
                Text("\u{1F3C6}")
                    .font(.system(size: 36))
                Text("Personal Best")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(Color(.trainPrimary))
            }

            ForEach(Array(data.pbs.enumerated()), id: \.offset) { _, pb in
                HStack(spacing: 8) {
                    Text(pb.exerciseName)
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(.trainTextPrimary))

                    Spacer()

                    Text(formatWeight(pb.previousWeight))
                        .font(.system(size: 28, weight: .medium, design: .rounded))
                        .foregroundColor(Color(.trainTextSecondary))

                    Image(systemName: "arrow.right")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(Color(.trainPrimary))

                    Text(formatWeight(pb.newWeight))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(Color(.trainPrimary))
                }
            }
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(.trainTextPrimary).opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(Color(.trainPrimary).opacity(0.3), lineWidth: 2)
                )
        )
    }

    // MARK: - Exercise List

    private var exerciseListSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            ForEach(Array(data.exercises.enumerated()), id: \.offset) { _, exercise in
                exerciseRow(exercise)
            }
        }
    }

    private func exerciseRow(_ exercise: LoggedExercise) -> some View {
        let completedSets = exercise.sets.filter { $0.completed }
        guard !completedSets.isEmpty else {
            return AnyView(EmptyView())
        }

        let summary = formatExerciseSummary(completedSets)

        return AnyView(
            VStack(alignment: .leading, spacing: 6) {
                Text(exercise.exerciseName)
                    .font(.system(size: 30, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(.trainTextPrimary))
                    .lineLimit(1)

                Text(summary)
                    .font(.system(size: 26, weight: .regular, design: .rounded))
                    .foregroundColor(Color(.trainTextSecondary))
            }
        )
    }

    // MARK: - Streak

    private var streakSection: some View {
        HStack {
            Spacer()
            Text("\u{1F525} \(data.streakCount) day streak")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(Color(.trainTextPrimary))
            Spacer()
        }
        .padding(.vertical, 28)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.trainTextPrimary).opacity(0.06))
        )
    }

    // MARK: - Formatting Helpers

    /// Format an exercise's completed sets into a concise summary.
    /// Groups identical sets (e.g. 3x10 @ 80kg) or lists each set individually.
    private func formatExerciseSummary(_ sets: [LoggedSet]) -> String {
        // Check if all sets share the same reps and weight
        let allSameReps = Set(sets.map { $0.reps }).count == 1
        let allSameWeight = Set(sets.map { $0.weight }).count == 1

        if allSameReps && allSameWeight {
            let weight = sets[0].weight
            let reps = sets[0].reps
            if weight > 0 {
                return "\(sets.count)\u{00D7}\(reps) @ \(formatWeight(weight))"
            } else {
                return "\(sets.count)\u{00D7}\(reps) (bodyweight)"
            }
        }

        // Mixed sets -- list each one
        return sets.map { set in
            if set.weight > 0 {
                return "\(set.reps)\u{00D7}\(formatWeight(set.weight))"
            } else {
                return "\(set.reps) reps"
            }
        }.joined(separator: ", ")
    }

    /// Formats weight: shows integer when whole, one decimal otherwise.
    private func formatWeight(_ weight: Double) -> String {
        if weight == weight.rounded() {
            return "\(Int(weight))kg"
        }
        return String(format: "%.1fkg", weight)
    }
}
