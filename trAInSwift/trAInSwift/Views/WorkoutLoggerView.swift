//
//  WorkoutLoggerView.swift
//  trAInSwift
//
//  Active workout logging screen with session completion tracking
//

import SwiftUI

struct WorkoutLoggerView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var authService = AuthService.shared

    let userProgram: UserProgram
    let weekNumber: Int
    let sessionIndex: Int

    @State private var currentExerciseIndex = 0
    @State private var loggedExercises: [LoggedExercise] = []
    @State private var startTime = Date()
    @State private var showCancelConfirmation = false
    @State private var showCompletionModal = false

    var session: ProgramSession {
        userProgram.program.sessions[sessionIndex]
    }

    var body: some View {
        ZStack {
            Color.trainBackground.ignoresSafeArea()

            if loggedExercises.isEmpty {
                // Loading state
                ProgressView("Loading workout...")
                    .foregroundColor(.trainTextPrimary)
            } else {
                VStack(spacing: 0) {
                    // Header
                    WorkoutHeader(
                        sessionName: session.dayName,
                        exerciseNumber: currentExerciseIndex + 1,
                        totalExercises: session.exercises.count,
                        onCancel: { showCancelConfirmation = true }
                    )

                    // Current Exercise
                    if currentExerciseIndex < session.exercises.count && currentExerciseIndex < loggedExercises.count {
                        let programExercise = session.exercises[currentExerciseIndex]

                        ScrollView {
                            VStack(spacing: Spacing.lg) {
                                // Exercise Info
                                ExerciseInfoCard(exercise: programExercise)
                                    .padding(.horizontal, Spacing.lg)
                                    .padding(.top, Spacing.md)

                                // Set Logging
                                SetLoggingView(
                                    programExercise: programExercise,
                                    loggedExercise: binding(for: currentExerciseIndex)
                                )
                                .padding(.horizontal, Spacing.lg)

                                Spacer()
                                    .frame(height: 100)
                            }
                        }

                        // Bottom Actions
                        VStack(spacing: Spacing.md) {
                            if currentExerciseIndex < session.exercises.count - 1 {
                                Button(action: nextExercise) {
                                    Text("Next Exercise")
                                        .font(.trainBodyMedium)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: ButtonHeight.standard)
                                        .background(Color.trainPrimary)
                                        .cornerRadius(CornerRadius.md)
                                }
                            } else {
                                Button(action: { showCompletionModal = true }) {
                                    Text("Finish Workout")
                                        .font(.trainBodyMedium)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: ButtonHeight.standard)
                                        .background(Color.trainPrimary)
                                        .cornerRadius(CornerRadius.md)
                                }
                            }
                        }
                        .padding(Spacing.lg)
                        .background(Color.white)
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            initializeLoggedExercises()
        }
        .confirmationDialog("Cancel Workout", isPresented: $showCancelConfirmation, titleVisibility: .visible) {
            Button("Discard Workout", role: .destructive) {
                dismiss()
            }
            Button("Continue Workout", role: .cancel) {}
        } message: {
            Text("Are you sure you want to cancel this workout? Your progress will not be saved.")
        }
        .sheet(isPresented: $showCompletionModal) {
            WorkoutCompletionView(onDone: {
                showCompletionModal = false
                saveWorkout()
                dismiss()
            })
        }
    }

    private func initializeLoggedExercises() {
        loggedExercises = session.exercises.map { exercise in
            LoggedExercise(
                exerciseName: exercise.exerciseName,
                sets: (0..<exercise.sets).map { _ in LoggedSet() },
                notes: ""
            )
        }
    }

    private func binding(for index: Int) -> Binding<LoggedExercise> {
        Binding(
            get: { loggedExercises[index] },
            set: { loggedExercises[index] = $0 }
        )
    }

    private func getOrCreateLoggedExercise(for programExercise: ProgramExercise) -> LoggedExercise {
        if let existing = loggedExercises.first(where: { $0.exerciseName == programExercise.exerciseName }) {
            return existing
        }
        return LoggedExercise(
            exerciseName: programExercise.exerciseName,
            sets: (0..<programExercise.sets).map { _ in LoggedSet() },
            notes: ""
        )
    }

    private func nextExercise() {
        withAnimation {
            currentExerciseIndex += 1
        }
    }

    private func saveWorkout() {
        guard var user = authService.currentUser,
              var program = user.currentProgram else { return }

        // Calculate duration
        let duration = Int(Date().timeIntervalSince(startTime) / 60)

        // Create workout session
        let workoutSession = WorkoutSession(
            userId: user.id,
            date: Date(),
            sessionType: session.dayName,
            weekNumber: weekNumber,
            exercises: loggedExercises,
            durationMinutes: duration,
            completed: true
        )

        // Add to workout history
        user.workoutHistory.append(workoutSession)

        // Mark session as completed and progress
        program.completeSession()
        user.currentProgram = program

        // Save to auth service
        authService.currentUser = user
        authService.saveSession()

        print("✅ Workout saved: Week \(weekNumber), Session \(sessionIndex)")
        print("✅ Next session: Week \(program.currentWeek), Session \(program.currentSessionIndex)")
    }
}

// MARK: - Workout Header

struct WorkoutHeader: View {
    let sessionName: String
    let exerciseNumber: Int
    let totalExercises: Int
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: onCancel) {
                    Image(systemName: "xmark")
                        .font(.title3)
                        .foregroundColor(.trainTextPrimary)
                }

                Spacer()

                VStack(spacing: 4) {
                    Text(sessionName)
                        .font(.trainBodyMedium)
                        .foregroundColor(.trainTextPrimary)

                    Text("Exercise \(exerciseNumber) of \(totalExercises)")
                        .font(.trainCaption)
                        .foregroundColor(.trainTextSecondary)
                }

                Spacer()

                // Timer placeholder
                Text("00:00")
                    .font(.trainBodyMedium)
                    .foregroundColor(.trainTextPrimary)
            }
            .padding(Spacing.lg)
            .background(Color.white)

            ProgressView(value: Double(exerciseNumber), total: Double(totalExercises))
                .tint(Color.trainPrimary)
        }
    }
}

// MARK: - Exercise Info Card

struct ExerciseInfoCard: View {
    let exercise: ProgramExercise

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(exercise.exerciseName)
                .font(.trainTitle2)
                .foregroundColor(.trainTextPrimary)

            // Only show equipment (removed primaryMuscle)
            InfoBadge(icon: "dumbbell", text: exercise.equipmentType)

            Divider()

            HStack {
                Text("Target:")
                    .font(.trainBodyMedium)
                    .foregroundColor(.trainTextSecondary)

                Text("\(exercise.sets) sets × \(exercise.repRange) reps")
                    .font(.trainBodyMedium)
                    .foregroundColor(.trainPrimary)

                Spacer()
            }
        }
        .padding(Spacing.md)
        .background(Color.white)
        .cornerRadius(CornerRadius.md)
    }
}

struct InfoBadge: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: icon)
                .font(.caption)
            Text(text)
                .font(.trainCaption)
        }
        .foregroundColor(.trainTextSecondary)
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(Color.trainBackground)
        .cornerRadius(CornerRadius.sm)
    }
}

// MARK: - Set Logging View

struct SetLoggingView: View {
    let programExercise: ProgramExercise
    @Binding var loggedExercise: LoggedExercise
    @State private var weightUnit: WeightUnit = .kg

    enum WeightUnit: String, CaseIterable {
        case kg = "kg"
        case lbs = "lbs"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Header with title and unit toggle
            HStack {
                Text("Log Sets")
                    .font(.trainHeadline)
                    .foregroundColor(.trainTextPrimary)

                Spacer()

                // Unit toggle
                HStack(spacing: 0) {
                    ForEach(WeightUnit.allCases, id: \.self) { unit in
                        Button(action: { weightUnit = unit }) {
                            Text(unit.rawValue)
                                .font(.trainCaption)
                                .fontWeight(.medium)
                                .foregroundColor(weightUnit == unit ? .white : .trainTextSecondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(weightUnit == unit ? Color.trainPrimary : Color.clear)
                        }
                    }
                }
                .background(Color.trainBackground)
                .cornerRadius(CornerRadius.sm)
            }

            // Grid header
            HStack(spacing: Spacing.md) {
                Text("Set")
                    .font(.trainCaption)
                    .foregroundColor(.trainTextSecondary)
                    .frame(width: 32)

                Text("Reps")
                    .font(.trainCaption)
                    .foregroundColor(.trainTextSecondary)
                    .frame(width: 60)

                Text("Weight")
                    .font(.trainCaption)
                    .foregroundColor(.trainTextSecondary)
                    .frame(width: 80)

                Spacer()
            }
            .padding(.horizontal, Spacing.sm)

            // Set rows
            VStack(spacing: Spacing.sm) {
                ForEach(0..<loggedExercise.sets.count, id: \.self) { setIndex in
                    SetRowView(
                        setNumber: setIndex + 1,
                        set: binding(for: setIndex),
                        restSeconds: programExercise.restSeconds,
                        weightUnit: weightUnit
                    )
                }
            }
        }
        .padding(Spacing.md)
        .background(Color.white)
        .cornerRadius(CornerRadius.md)
    }

    private func binding(for index: Int) -> Binding<LoggedSet> {
        Binding(
            get: { loggedExercise.sets[index] },
            set: { loggedExercise.sets[index] = $0 }
        )
    }
}

struct SetRowView: View {
    let setNumber: Int
    @Binding var set: LoggedSet
    let restSeconds: Int
    let weightUnit: SetLoggingView.WeightUnit

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Set number
            Text("\(setNumber)")
                .font(.trainBodyMedium)
                .fontWeight(.bold)
                .foregroundColor(.trainTextPrimary)
                .frame(width: 32)

            // Reps picker (no label - header has it)
            Picker("", selection: $set.reps) {
                ForEach(0...50, id: \.self) { reps in
                    Text("\(reps)").tag(reps)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 60)
            .background(Color.white)
            .cornerRadius(CornerRadius.sm)

            // Weight picker (no label - header has it)
            Picker("", selection: $set.weight) {
                ForEach(Array(stride(from: 0.0, through: 200.0, by: 2.5)), id: \.self) { weight in
                    Text(String(format: "%.1f", convertWeight(weight))).tag(weight)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 80)
            .background(Color.white)
            .cornerRadius(CornerRadius.sm)

            Spacer()

            // Completion toggle
            Button(action: { set.completed.toggle() }) {
                Image(systemName: set.completed ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(set.completed ? .trainPrimary : .trainTextSecondary)
            }
        }
        .padding(Spacing.sm)
        .background(set.completed ? Color.trainPrimary.opacity(0.05) : Color.trainBackground)
        .cornerRadius(CornerRadius.sm)
    }

    // Convert weight based on selected unit
    private func convertWeight(_ kgWeight: Double) -> Double {
        weightUnit == .kg ? kgWeight : kgWeight * 2.20462
    }
}

// MARK: - Workout Completion View

struct WorkoutCompletionView: View {
    let onDone: () -> Void

    var body: some View {
        ZStack {
            Color.trainBackground.ignoresSafeArea()

            VStack(spacing: Spacing.xl) {
                Spacer()

                // Success icon
                ZStack {
                    Circle()
                        .fill(Color.trainPrimary)
                        .frame(width: 80, height: 80)

                    Image(systemName: "checkmark")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.white)
                }

                // Title
                VStack(spacing: Spacing.sm) {
                    Text("Workout Complete!")
                        .font(.trainTitle)
                        .foregroundColor(.trainTextPrimary)

                    Text("Great work! You've completed this session.")
                        .font(.trainBody)
                        .foregroundColor(.trainTextSecondary)
                        .multilineTextAlignment(.center)
                }

                Spacer()

                // Done button
                Button(action: onDone) {
                    Text("Done")
                        .font(.trainBodyMedium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: ButtonHeight.standard)
                        .background(Color.trainPrimary)
                        .cornerRadius(CornerRadius.md)
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.xl)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        WorkoutLoggerView(
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
