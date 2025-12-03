//
//  SessionDetailView.swift
//  trAInSwift
//
//  Shows exercises for a specific session with Start Workout button
//

import SwiftUI
import CoreData

struct SessionDetailView: View {
    let userProgram: WorkoutProgram
    let weekNumber: Int
    let sessionIndex: Int

    @State private var startWorkout = false
    @State private var selectedExercise: ProgramExercise?
    @State private var selectedDBExercise: DBExercise?

    var session: ProgramSession? {
        guard let program = userProgram.getProgram(),
              sessionIndex < program.sessions.count else {
            return nil
        }
        return program.sessions[sessionIndex]
    }

    var sessionId: String {
        "week\(weekNumber)-session\(sessionIndex)"
    }

    var isCompleted: Bool {
        userProgram.completedSessionsSet.contains(sessionId)
    }

    var estimatedDuration: String {
        guard let validSession = session else { return "N/A" }
        let minutes = validSession.exercises.count * 3 * 2 // exercises × sets × minutes per set
        return "\(minutes)-\(minutes + 10) min"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                if let validSession = session {
                    // Header
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text(validSession.dayName)
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
                        InfoRow(icon: "figure.strengthtraining.traditional", text: "\(validSession.exercises.count) exercises")
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

                        ForEach(Array(validSession.exercises.enumerated()), id: \.element.id) { index, exercise in
                        ExerciseCard(exercise: exercise, index: index + 1)
                            .padding(.horizontal, Spacing.lg)
                            .onTapGesture {
                                selectedExercise = exercise
                                loadExerciseDetails(exerciseId: exercise.exerciseId)
                            }
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
                } else {
                    // Error state
                    VStack(spacing: Spacing.lg) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.trainTextSecondary)
                        Text("Unable to load session")
                            .font(.trainHeadline)
                            .foregroundColor(.trainTextPrimary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(Spacing.xl)
                }
            }
        }
        .warmDarkGradientBackground()
        .scrollContentBackground(.hidden)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $startWorkout) {
            WorkoutOverviewView(
                weekNumber: weekNumber,
                sessionIndex: sessionIndex
            )
        }
        .sheet(item: $selectedDBExercise) { exercise in
            NavigationStack {
                ExerciseDetailView(exercise: exercise, showLoggerTab: true)
            }
        }
    }

    private func getTargetMuscles() -> String {
        guard let validSession = session else { return "N/A" }
        let muscles = Set(validSession.exercises.map { $0.primaryMuscle })
        return muscles.sorted().joined(separator: ", ")
    }

    private func loadExerciseDetails(exerciseId: String) {
        // Convert exerciseId string to Int and fetch from database
        guard let id = Int(exerciseId) else { return }

        Task {
            do {
                let exercise = try ExerciseDatabaseManager.shared.fetchExercise(byId: id)

                if let exercise = exercise {
                    await MainActor.run {
                        selectedDBExercise = exercise
                    }
                }
            } catch {
                print("❌ Error loading exercise details: \(error)")
            }
        }
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
        HStack(alignment: .top, spacing: Spacing.md) {
            // Exercise number - aligned to top
            Text("\(index)")
                .font(.trainBodyMedium)
                .fontWeight(.bold)
                .foregroundColor(.trainPrimary)
                .frame(width: 32, height: 32)
                .background(Color.trainPrimary.opacity(0.1))
                .clipShape(Circle())

            // Exercise info - exercise name aligns with top of orange node
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
        .appCard()
        .cornerRadius(CornerRadius.md)
    }
}

// MARK: - Preview

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let program = Program(
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
    let workoutProgram = WorkoutProgram.create(userId: UUID(), program: program, context: context)

    return NavigationStack {
        SessionDetailView(
            userProgram: workoutProgram,
            weekNumber: 1,
            sessionIndex: 0
        )
    }
}
