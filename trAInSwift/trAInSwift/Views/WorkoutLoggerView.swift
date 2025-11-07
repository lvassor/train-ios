//
//  WorkoutLoggerView.swift
//  trAInApp
//
//  Active workout logging screen
//

import SwiftUI

struct WorkoutLoggerView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var authService = AuthService.shared

    let session: ProgramSession
    let weekNumber: Int
    let onComplete: () -> Void

    @State private var currentExerciseIndex = 0
    @State private var loggedExercises: [LoggedExercise] = []
    @State private var startTime = Date()
    @State private var showCancelConfirmation = false
    @State private var showCompletionModal = false

    var body: some View {
        ZStack {
            Color.trainBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                WorkoutHeader(
                    sessionName: session.dayName,
                    exerciseNumber: currentExerciseIndex + 1,
                    totalExercises: session.exercises.count,
                    onCancel: { showCancelConfirmation = true }
                )

                // Current Exercise
                if currentExerciseIndex < session.exercises.count {
                    let programExercise = session.exercises[currentExerciseIndex]
                    let loggedExercise = getOrCreateLoggedExercise(for: programExercise)

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
        .onAppear {
            initializeLoggedExercises()
        }
        .confirmationDialog("Cancel Workout", isPresented: $showCancelConfirmation, titleVisibility: .visible) {
            Button("Discard Workout", role: .destructive) {
                dismiss()
                onComplete()
            }
            Button("Continue Workout", role: .cancel) {}
        } message: {
            Text("Are you sure you want to cancel this workout? Your progress will not be saved.")
        }
        .sheet(isPresented: $showCompletionModal) {
            WorkoutCompletionView(
                sessionName: session.dayName,
                duration: Int(Date().timeIntervalSince(startTime) / 60),
                onDone: {
                    saveWorkout()
                    showCompletionModal = false
                    dismiss()
                    onComplete()
                }
            )
        }
    }

    private func initializeLoggedExercises() {
        loggedExercises = session.exercises.map { programExercise in
            let sets = (0..<programExercise.sets).map { _ in
                LoggedSet()
            }
            return LoggedExercise(
                exerciseName: programExercise.exerciseName,
                sets: sets
            )
        }
    }

    private func getOrCreateLoggedExercise(for programExercise: ProgramExercise) -> LoggedExercise {
        if let index = loggedExercises.firstIndex(where: { $0.exerciseName == programExercise.exerciseName }) {
            return loggedExercises[index]
        }
        // Fallback
        let sets = (0..<programExercise.sets).map { _ in LoggedSet() }
        return LoggedExercise(exerciseName: programExercise.exerciseName, sets: sets)
    }

    private func binding(for index: Int) -> Binding<LoggedExercise> {
        Binding(
            get: { loggedExercises[index] },
            set: { loggedExercises[index] = $0 }
        )
    }

    private func nextExercise() {
        if currentExerciseIndex < session.exercises.count - 1 {
            currentExerciseIndex += 1
        }
    }

    private func saveWorkout() {
        guard let userId = authService.currentUser?.id else { return }

        let duration = Int(Date().timeIntervalSince(startTime) / 60)

        let workoutSession = WorkoutSession(
            userId: userId,
            sessionType: session.dayName,
            weekNumber: weekNumber,
            exercises: loggedExercises,
            durationMinutes: duration,
            completed: true
        )

        authService.addWorkoutSession(workoutSession)

        // Update program progress
        if var userProgram = authService.currentUser?.currentProgram {
            userProgram.completeSession()
            authService.updateProgram(userProgram)
        }
    }
}

// MARK: - Workout Header

struct WorkoutHeader: View {
    let sessionName: String
    let exerciseNumber: Int
    let totalExercises: Int
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: Spacing.sm) {
            HStack {
                Button(action: onCancel) {
                    Image(systemName: "xmark")
                        .font(.title3)
                        .foregroundColor(.trainTextPrimary)
                }

                Spacer()

                VStack(spacing: 2) {
                    Text(sessionName)
                        .font(.trainHeadline)
                        .foregroundColor(.trainTextPrimary)

                    Text("Exercise \(exerciseNumber) of \(totalExercises)")
                        .font(.trainCaption)
                        .foregroundColor(.trainTextSecondary)
                }

                Spacer()

                // Placeholder for symmetry
                Color.clear
                    .frame(width: 24, height: 24)
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)

            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.trainBorder)
                        .frame(height: 4)

                    Rectangle()
                        .fill(Color.trainPrimary)
                        .frame(width: geometry.size.width * CGFloat(exerciseNumber) / CGFloat(totalExercises), height: 4)
                }
            }
            .frame(height: 4)
        }
        .background(Color.white)
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

            HStack {
                InfoPill(icon: "target", text: exercise.primaryMuscle)
                InfoPill(icon: "dumbbell", text: exercise.equipmentType)
                InfoPill(icon: "clock", text: "\(exercise.restSeconds)s rest")
            }

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

struct InfoPill: View {
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

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Log Sets")
                .font(.trainHeadline)
                .foregroundColor(.trainTextPrimary)

            VStack(spacing: Spacing.sm) {
                ForEach(0..<loggedExercise.sets.count, id: \.self) { setIndex in
                    SetRowView(
                        setNumber: setIndex + 1,
                        set: binding(for: setIndex),
                        restSeconds: programExercise.restSeconds
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

    @State private var weightText = ""
    @State private var repsText = ""
    @State private var showRestTimer = false

    var body: some View {
        VStack(spacing: Spacing.sm) {
            HStack(spacing: Spacing.md) {
                // Set Number
                Text("\(setNumber)")
                    .font(.trainBodyMedium)
                    .foregroundColor(.trainTextPrimary)
                    .frame(width: 30)

                // Weight Input
                HStack(spacing: Spacing.xs) {
                    TextField("0", text: $weightText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.center)
                        .font(.trainBody)
                        .frame(width: 60)
                        .padding(.vertical, Spacing.sm)
                        .background(Color.trainBackground)
                        .cornerRadius(CornerRadius.sm)
                        .onChange(of: weightText) { _, newValue in
                            set.weight = Double(newValue) ?? 0
                        }

                    Text("kg")
                        .font(.trainCaption)
                        .foregroundColor(.trainTextSecondary)
                }

                Text("×")
                    .foregroundColor(.trainTextSecondary)

                // Reps Input
                HStack(spacing: Spacing.xs) {
                    TextField("0", text: $repsText)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .font(.trainBody)
                        .frame(width: 50)
                        .padding(.vertical, Spacing.sm)
                        .background(Color.trainBackground)
                        .cornerRadius(CornerRadius.sm)
                        .onChange(of: repsText) { _, newValue in
                            set.reps = Int(newValue) ?? 0
                        }

                    Text("reps")
                        .font(.trainCaption)
                        .foregroundColor(.trainTextSecondary)
                }

                Spacer()

                // Complete Button
                Button(action: {
                    set.completed = true
                    showRestTimer = true
                }) {
                    Image(systemName: set.completed ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundColor(set.completed ? .trainPrimary : .trainBorder)
                }
            }

            if showRestTimer && setNumber < 3 {
                RestTimerView(seconds: restSeconds, onComplete: {
                    showRestTimer = false
                })
            }
        }
        .onAppear {
            if set.weight > 0 {
                weightText = String(format: "%.1f", set.weight)
            }
            if set.reps > 0 {
                repsText = "\(set.reps)"
            }
        }
    }
}

// MARK: - Rest Timer

struct RestTimerView: View {
    let seconds: Int
    let onComplete: () -> Void

    @State private var timeRemaining: Int
    @State private var timer: Timer?

    init(seconds: Int, onComplete: @escaping () -> Void) {
        self.seconds = seconds
        self.onComplete = onComplete
        self._timeRemaining = State(initialValue: seconds)
    }

    var body: some View {
        HStack {
            Image(systemName: "clock.fill")
                .foregroundColor(.trainPrimary)

            Text("Rest: \(formatTime(timeRemaining))")
                .font(.trainCaption)
                .foregroundColor(.trainTextPrimary)

            Spacer()

            Button(action: skip) {
                Text("Skip")
                    .font(.trainCaption)
                    .foregroundColor(.trainPrimary)
            }
        }
        .padding(Spacing.sm)
        .background(Color.trainPrimary.opacity(0.1))
        .cornerRadius(CornerRadius.sm)
        .onAppear {
            startTimer()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                timer?.invalidate()
                onComplete()
            }
        }
    }

    private func skip() {
        timer?.invalidate()
        onComplete()
    }

    private func formatTime(_ totalSeconds: Int) -> String {
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Workout Completion Modal

struct WorkoutCompletionView: View {
    let sessionName: String
    let duration: Int
    let onDone: () -> Void

    var body: some View {
        ZStack {
            Color.trainPrimary.ignoresSafeArea()

            VStack(spacing: Spacing.xl) {
                Spacer()

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.white)

                VStack(spacing: Spacing.sm) {
                    Text("Workout Complete!")
                        .font(.trainTitle)
                        .foregroundColor(.white)

                    Text(sessionName)
                        .font(.trainHeadline)
                        .foregroundColor(.white.opacity(0.9))

                    Text("\(duration) minutes")
                        .font(.trainBody)
                        .foregroundColor(.white.opacity(0.8))
                }

                Spacer()

                Button(action: onDone) {
                    Text("Done")
                        .font(.trainBodyMedium)
                        .foregroundColor(.trainPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: ButtonHeight.standard)
                        .background(Color.white)
                        .cornerRadius(CornerRadius.md)
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.xl)
            }
        }
    }
}

#Preview {
    let sampleSession = ProgramSession(
        dayName: "Push Day",
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

    WorkoutLoggerView(session: sampleSession, weekNumber: 1, onComplete: {})
}
