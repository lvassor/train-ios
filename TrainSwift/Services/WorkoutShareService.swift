//
//  WorkoutShareService.swift
//  TrainSwift
//
//  Handles assembling workout share data and presenting the share sheet
//

import UIKit
import SwiftUI

struct WorkoutShareService {

    // MARK: - Build Share Data

    /// Assemble share data from workout summary information.
    static func buildShareData(
        sessionName: String,
        durationMinutes: Int,
        exercises: [LoggedExercise],
        pbs: [(exerciseName: String, previousWeight: Double, newWeight: Double)]
    ) -> WorkoutShareCardGenerator.ShareData {
        let streakCount = SessionCompletionHelper.calculateStreak(
            userId: AuthService.shared.currentUser?.id ?? UUID()
        )

        return WorkoutShareCardGenerator.ShareData(
            sessionName: sessionName,
            date: Date(),
            durationMinutes: durationMinutes,
            exercises: exercises,
            pbs: pbs,
            streakCount: streakCount
        )
    }

    // MARK: - Build Share Text

    /// Build a formatted plain-text payload for sharing.
    static func buildShareText(from data: WorkoutShareCardGenerator.ShareData) -> String {
        var lines: [String] = []

        // Header
        let durationFormatted = formatDuration(data.durationMinutes)
        lines.append("\u{1F4AA} \(data.sessionName) \u{2014} \(durationFormatted)")
        lines.append("")

        // PBs
        if !data.pbs.isEmpty {
            lines.append("\u{1F3C6} PBs:")
            for pb in data.pbs {
                lines.append("\u{2022} \(pb.exerciseName): \(formatWeight(pb.previousWeight)) \u{2192} \(formatWeight(pb.newWeight))")
            }
            lines.append("")
        }

        // Exercises
        lines.append("\u{1F4CB} Exercises:")
        for exercise in data.exercises {
            let completedSets = exercise.sets.filter { $0.completed }
            guard !completedSets.isEmpty else { continue }

            let summary = formatExerciseText(exercise.exerciseName, sets: completedSets)
            lines.append("\u{2022} \(summary)")
        }
        lines.append("")

        // Streak
        if data.streakCount > 0 {
            lines.append("\u{1F525} \(data.streakCount) day streak")
            lines.append("")
        }

        // Footer
        lines.append("Tracked with train.")

        return lines.joined(separator: "\n")
    }

    // MARK: - Present Share Sheet

    /// Generate the share card image and present a UIActivityViewController.
    @MainActor
    static func presentShareSheet(data: WorkoutShareCardGenerator.ShareData) {
        let shareText = buildShareText(from: data)

        var items: [Any] = [shareText]

        // Generate branded share card image
        if let image = WorkoutShareCardGenerator.generateImage(from: data) {
            items.insert(image, at: 0)
        }

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootVC = window.rootViewController else {
            return
        }

        let activityVC = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )

        // iPad popover support
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = rootVC.view
            popover.sourceRect = CGRect(
                x: rootVC.view.bounds.midX,
                y: rootVC.view.bounds.maxY - 100,
                width: 0,
                height: 0
            )
        }

        rootVC.present(activityVC, animated: true)

        // Attempt Instagram Stories deep link if available
        if let url = URL(string: "instagram-stories://share"),
           UIApplication.shared.canOpenURL(url),
           let image = WorkoutShareCardGenerator.generateImage(from: data),
           let imageData = image.pngData() {
            let pasteboardItems: [[String: Any]] = [
                [
                    "com.instagram.sharedSticker.backgroundImage": imageData
                ]
            ]
            UIPasteboard.general.setItems(
                pasteboardItems,
                options: [.expirationDate: Date().addingTimeInterval(300)]
            )
        }
    }

    // MARK: - Private Helpers

    private static func formatDuration(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 {
            return "\(hours)h \(mins)m"
        }
        return "\(mins) min"
    }

    private static func formatWeight(_ weight: Double) -> String {
        if weight == weight.rounded() {
            return "\(Int(weight))kg"
        }
        return String(format: "%.1fkg", weight)
    }

    private static func formatExerciseText(_ name: String, sets: [LoggedSet]) -> String {
        let allSameReps = Set(sets.map { $0.reps }).count == 1
        let allSameWeight = Set(sets.map { $0.weight }).count == 1

        if allSameReps && allSameWeight {
            let weight = sets[0].weight
            let reps = sets[0].reps
            if weight > 0 {
                return "\(name): \(sets.count)\u{00D7}\(reps) @ \(formatWeight(weight))"
            } else {
                return "\(name): \(sets.count)\u{00D7}\(reps) (bodyweight)"
            }
        }

        // Mixed sets
        let setsStr = sets.map { set in
            if set.weight > 0 {
                return "\(set.reps)\u{00D7}\(formatWeight(set.weight))"
            } else {
                return "\(set.reps) reps"
            }
        }.joined(separator: ", ")

        return "\(name): \(setsStr)"
    }
}
