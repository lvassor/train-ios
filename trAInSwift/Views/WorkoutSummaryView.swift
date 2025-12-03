//
//  WorkoutSummaryView.swift
//  trAInSwift
//
//  Post-workout summary with duration, rep scores, and PB indicators
//

import SwiftUI

struct WorkoutSummaryView: View {
    let sessionName: String
    let duration: Int // in minutes
    let completedExercises: Int
    let totalExercises: Int
    let loggedExercises: [LoggedExercise]
    let onDone: () -> Void
    let onEdit: () -> Void

    @ObservedObject var authService = AuthService.shared

    // Computed properties
    private var totalReps: Int {
        loggedExercises.reduce(0) { total, exercise in
            total + exercise.sets.filter { $0.completed }.reduce(0) { $0 + $1.reps }
        }
    }

    private var totalSets: Int {
        loggedExercises.reduce(0) { total, exercise in
            total + exercise.sets.filter { $0.completed }.count
        }
    }

    private var durationFormatted: String {
        let hours = duration / 60
        let minutes = duration % 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes) min"
        }
    }

    var body: some View {
        ZStack {
            // Background
            Color.trainBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // Success icon
                    ZStack {
                        Circle()
                            .fill(Color.trainPrimary)
                            .frame(width: 100, height: 100)

                        Image(systemName: "checkmark")
                            .font(.system(size: 50, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.top, Spacing.xl)

                    // Title
                    VStack(spacing: Spacing.sm) {
                        Text("Workout Complete!")
                            .font(.trainTitle)
                            .foregroundColor(.trainTextPrimary)

                        Text(sessionName)
                            .font(.trainBody)
                            .foregroundColor(.trainTextSecondary)
                    }

                    // Stats row
                    HStack(spacing: Spacing.xl) {
                        StatItem(value: durationFormatted, label: "Duration")
                        StatItem(value: "\(totalSets)", label: "Sets")
                        StatItem(value: "\(totalReps)", label: "Reps")
                    }
                    .padding(Spacing.lg)
                    .appCard()
                    .padding(.horizontal, Spacing.lg)

                    // Exercise results
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        HStack {
                            Text("Exercise Results")
                                .font(.trainHeadline)
                                .foregroundColor(.trainTextPrimary)

                            Spacer()

                            Button(action: onEdit) {
                                HStack(spacing: 4) {
                                    Image(systemName: "pencil")
                                        .font(.system(size: 14))
                                    Text("Edit")
                                        .font(.trainCaption)
                                }
                                .foregroundColor(.trainPrimary)
                            }
                        }

                        ForEach(loggedExercises, id: \.exerciseName) { exercise in
                            ExerciseResultRow(
                                exercise: exercise,
                                isPB: checkForPB(exercise)
                            )
                        }
                    }
                    .padding(Spacing.lg)
                    .appCard()
                    .padding(.horizontal, Spacing.lg)

                }
                .padding(.bottom, 100) // Room for floating button
            }

            // Done button - floating overlay
            VStack {
                Spacer()

                Button(action: onDone) {
                    Text("Done")
                        .font(.trainBodyMedium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: ButtonHeight.standard)
                        .background(Color.trainPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous))
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.lg)
            }
        }
    }

    private func checkForPB(_ exercise: LoggedExercise) -> Bool {
        // Check if this is a personal best for any set
        guard let previousData = authService.getPreviousSessionData(
            programId: authService.getCurrentProgram()?.id?.uuidString ?? "",
            exerciseName: exercise.exerciseName
        ) else {
            return false // No previous data - can't be a PB yet
        }

        // Check if any current set beats previous sets
        for (index, currentSet) in exercise.sets.enumerated() {
            guard index < previousData.count else { continue }
            let previousSet = previousData[index]

            // PB if either higher reps at same/higher weight OR higher weight at same/higher reps
            if currentSet.completed {
                if currentSet.weight > previousSet.weight && currentSet.reps >= previousSet.reps {
                    return true
                }
                if currentSet.reps > previousSet.reps && currentSet.weight >= previousSet.weight {
                    return true
                }
            }
        }

        return false
    }
}

// MARK: - Stat Item

struct StatItem: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.trainTitle2)
                .foregroundColor(.trainPrimary)

            Text(label)
                .font(.trainCaption)
                .foregroundColor(.trainTextSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Exercise Result Row

struct ExerciseResultRow: View {
    let exercise: LoggedExercise
    let isPB: Bool

    private var completedSets: Int {
        exercise.sets.filter { $0.completed }.count
    }

    private var totalReps: Int {
        exercise.sets.filter { $0.completed }.reduce(0) { $0 + $1.reps }
    }

    private var avgWeight: Double {
        let completedSets = exercise.sets.filter { $0.completed && $0.weight > 0 }
        guard !completedSets.isEmpty else { return 0 }
        return completedSets.reduce(0) { $0 + $1.weight } / Double(completedSets.count)
    }

    var body: some View {
        HStack(spacing: Spacing.md) {
            // PB rosette
            if isPB {
                ZStack {
                    Circle()
                        .fill(Color.trainPrimary)
                        .frame(width: 32, height: 32)

                    Image(systemName: "rosette")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                }
            } else {
                Circle()
                    .stroke(Color.trainTextSecondary.opacity(0.3), lineWidth: 2)
                    .frame(width: 32, height: 32)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(exercise.exerciseName)
                        .font(.trainBodyMedium)
                        .foregroundColor(.trainTextPrimary)

                    if isPB {
                        Text("PB!")
                            .font(.trainCaption)
                            .fontWeight(.bold)
                            .foregroundColor(.trainPrimary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.trainPrimary.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }

                HStack(spacing: Spacing.md) {
                    Text("\(completedSets) sets")
                        .font(.trainCaption)
                        .foregroundColor(.trainTextSecondary)

                    Text("\(totalReps) reps")
                        .font(.trainCaption)
                        .foregroundColor(.trainTextSecondary)

                    if avgWeight > 0 {
                        Text(String(format: "%.1f kg avg", avgWeight))
                            .font(.trainCaption)
                            .foregroundColor(.trainTextSecondary)
                    }
                }
            }

            Spacer()
        }
        .padding(Spacing.md)
        .background(isPB ? Color.trainPrimary.opacity(0.05) : Color.clear)
        .cornerRadius(CornerRadius.sm)
    }
}

// MARK: - Preview

#Preview {
    WorkoutSummaryView(
        sessionName: "Push Day",
        duration: 45,
        completedExercises: 5,
        totalExercises: 5,
        loggedExercises: [
            LoggedExercise(
                exerciseName: "Bench Press",
                sets: [
                    LoggedSet(reps: 10, weight: 80, completed: true),
                    LoggedSet(reps: 9, weight: 80, completed: true),
                    LoggedSet(reps: 8, weight: 80, completed: true)
                ],
                notes: ""
            ),
            LoggedExercise(
                exerciseName: "Shoulder Press",
                sets: [
                    LoggedSet(reps: 12, weight: 40, completed: true),
                    LoggedSet(reps: 10, weight: 40, completed: true),
                    LoggedSet(reps: 10, weight: 40, completed: true)
                ],
                notes: ""
            )
        ],
        onDone: {},
        onEdit: {}
    )
}
