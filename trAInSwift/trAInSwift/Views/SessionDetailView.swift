//
//  SessionDetailView.swift
//  trAInSwift
//
//  Shows exercises for a specific session with Start Workout button
//

import SwiftUI

struct SessionDetailView: View {
    let userProgram: UserProgram
    let weekNumber: Int
    let sessionIndex: Int

    @State private var startWorkout = false

    var session: ProgramSession {
        userProgram.program.sessions[sessionIndex]
    }

    var sessionId: String {
        "week\(weekNumber)-session\(sessionIndex)"
    }

    var isCompleted: Bool {
        userProgram.completedSessions.contains(sessionId)
    }

    var estimatedDuration: String {
        let minutes = session.exercises.count * 3 * 2 // exercises × sets × minutes per set
        return "\(minutes)-\(minutes + 10) min"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                // Header
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text(session.dayName)
                        .font(.trainTitle)
                        .foregroundColor(.trainTextPrimary)

                    Text("Week \(weekNumber)")
                        .font(.trainSubtitle)
                        .foregroundColor(.trainTextSecondary)

                    if isCompleted {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.trainPrimary)
                            Text("Completed")
                                .font(.trainBodyMedium)
                                .foregroundColor(.trainPrimary)
                        }
                        .padding(.top, Spacing.xs)
                    }
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.md)

                // Session Info Card
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    InfoRow(icon: "figure.strengthtraining.traditional", text: "\(session.exercises.count) exercises")
                    InfoRow(icon: "clock", text: "~\(estimatedDuration)")
                    InfoRow(icon: "target", text: getTargetMuscles())
                }
                .padding(Spacing.md)
                .background(Color.trainPrimary.opacity(0.1))
                .cornerRadius(CornerRadius.md)
                .padding(.horizontal, Spacing.lg)

                // Exercises List
                VStack(alignment: .leading, spacing: Spacing.md) {
                    Text("Exercises")
                        .font(.trainHeadline)
                        .foregroundColor(.trainTextPrimary)
                        .padding(.horizontal, Spacing.lg)

                    ForEach(Array(session.exercises.enumerated()), id: \.element.id) { index, exercise in
                        ExerciseCard(exercise: exercise, index: index + 1)
                            .padding(.horizontal, Spacing.lg)
                    }
                }

                // Start Workout Button
                if !isCompleted {
                    Button(action: { startWorkout = true }) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Start Workout")
                                .font(.trainBodyMedium)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: ButtonHeight.standard)
                        .background(Color.trainPrimary)
                        .cornerRadius(CornerRadius.md)
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.top, Spacing.md)
                }

                Spacer()
                    .frame(height: 40)
            }
        }
        .background(Color.trainBackground.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $startWorkout) {
            WorkoutLoggerView(
                userProgram: userProgram,
                weekNumber: weekNumber,
                sessionIndex: sessionIndex
            )
        }
    }

    private func getTargetMuscles() -> String {
        let muscles = Set(session.exercises.map { $0.primaryMuscle })
        return muscles.sorted().joined(separator: ", ")
    }
}

// MARK: - Info Row

struct InfoRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .foregroundColor(.trainPrimary)
                .frame(width: 20)
            Text(text)
                .font(.trainBody)
                .foregroundColor(.trainTextPrimary)
        }
    }
}

// MARK: - Exercise Card

struct ExerciseCard: View {
    let exercise: ProgramExercise
    let index: Int

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Exercise number
            Text("\(index)")
                .font(.trainBodyMedium)
                .fontWeight(.bold)
                .foregroundColor(.trainPrimary)
                .frame(width: 32, height: 32)
                .background(Color.trainPrimary.opacity(0.1))
                .clipShape(Circle())

            // Exercise info
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.exerciseName)
                    .font(.trainBodyMedium)
                    .foregroundColor(.trainTextPrimary)

                HStack(spacing: Spacing.md) {
                    Text("\(exercise.sets) sets × \(exercise.repRange) reps")
                        .font(.trainCaption)
                        .foregroundColor(.trainTextSecondary)

                    Text("•")
                        .foregroundColor(.trainTextSecondary)

                    Text(exercise.primaryMuscle)
                        .font(.trainCaption)
                        .foregroundColor(.trainTextSecondary)
                }
            }

            Spacer()

            // Rest time
            VStack(spacing: 2) {
                Text("\(exercise.restSeconds)s")
                    .font(.trainCaption)
                    .fontWeight(.medium)
                    .foregroundColor(.trainTextPrimary)
                Text("rest")
                    .font(.system(size: 10))
                    .foregroundColor(.trainTextSecondary)
            }
        }
        .padding(Spacing.md)
        .background(Color.white)
        .cornerRadius(CornerRadius.md)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SessionDetailView(
            userProgram: UserProgram(
                program: Program(
                    type: .pushPullLegs,
                    daysPerWeek: 3,
                    sessionDuration: .medium,
                    sessions: [
                        ProgramSession(
                            dayName: "Push",
                            exercises: [
                                ProgramExercise(
                                    exerciseId: "1",
                                    exerciseName: "Bench Press",
                                    sets: 3,
                                    repRange: "8-12",
                                    restSeconds: 120,
                                    primaryMuscle: "Chest",
                                    equipmentType: "Barbell"
                                ),
                                ProgramExercise(
                                    exerciseId: "2",
                                    exerciseName: "Overhead Press",
                                    sets: 3,
                                    repRange: "8-12",
                                    restSeconds: 120,
                                    primaryMuscle: "Shoulders",
                                    equipmentType: "Barbell"
                                )
                            ]
                        )
                    ],
                    totalWeeks: 8
                )
            ),
            weekNumber: 1,
            sessionIndex: 0
        )
    }
}
