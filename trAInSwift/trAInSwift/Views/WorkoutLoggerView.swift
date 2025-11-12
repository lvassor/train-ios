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

    let weekNumber: Int
    let sessionIndex: Int

    var userProgram: WorkoutProgram? {
        authService.getCurrentProgram()
    }

    var programData: Program? {
        userProgram?.getProgram()
    }

    @State private var currentExerciseIndex = 0
    @State private var loggedExercises: [LoggedExercise] = []
    @State private var startTime = Date()
    @State private var showCancelConfirmation = false
    @State private var showCompletionModal = false
    @State private var selectedTab: WorkoutTab = .logger
    @State private var selectedDBExercise: DBExercise?

    enum WorkoutTab {
        case logger, demo
    }

    var session: ProgramSession? {
        guard let program = programData,
              sessionIndex < program.sessions.count else {
            return nil
        }
        return program.sessions[sessionIndex]
    }

    var body: some View {
        ZStack {
            Color.trainBackground.ignoresSafeArea()

            if session == nil {
                // Error state - no valid session
                VStack(spacing: Spacing.lg) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(.trainTextSecondary)
                    Text("Unable to load workout session")
                        .font(.trainHeadline)
                        .foregroundColor(.trainTextPrimary)
                    Text("Please return to dashboard and try again")
                        .font(.trainBody)
                        .foregroundColor(.trainTextSecondary)
                        .multilineTextAlignment(.center)
                    Button("Go Back") {
                        dismiss()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.horizontal, Spacing.xl)
                }
                .padding(Spacing.xl)
            } else if loggedExercises.isEmpty {
                // Loading state
                ProgressView("Loading workout...")
                    .foregroundColor(.trainTextPrimary)
            } else if let validSession = session {
                VStack(spacing: 0) {
                    // Header
                    WorkoutHeader(
                        sessionName: validSession.dayName,
                        exerciseNumber: currentExerciseIndex + 1,
                        totalExercises: validSession.exercises.count,
                        onCancel: { showCancelConfirmation = true }
                    )

                    // Tab toggle
                    HStack(spacing: 0) {
                        Button(action: { selectedTab = .logger }) {
                            Text("Logger")
                                .font(.trainBodyMedium)
                                .foregroundColor(selectedTab == .logger ? .trainTextPrimary : .trainTextSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, Spacing.md)
                                .background(selectedTab == .logger ? Color.white : Color.clear)
                                .cornerRadius(20, corners: [.topLeft, .bottomLeft])
                        }

                        Button(action: {
                            selectedTab = .demo
                            loadExerciseDetails()
                        }) {
                            Text("Demo")
                                .font(.trainBodyMedium)
                                .foregroundColor(selectedTab == .demo ? .trainTextPrimary : .trainTextSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, Spacing.md)
                                .background(selectedTab == .demo ? Color.white : Color.clear)
                                .cornerRadius(20, corners: [.topRight, .bottomRight])
                        }
                    }
                    .background(Color.trainTextSecondary.opacity(0.1))
                    .cornerRadius(20)
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.sm)

                    // Current Exercise
                    if currentExerciseIndex < validSession.exercises.count && currentExerciseIndex < loggedExercises.count {
                        let programExercise = validSession.exercises[currentExerciseIndex]

                        if selectedTab == .logger {
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
                        } else {
                            // Demo view
                            if let dbExercise = selectedDBExercise {
                                ScrollView {
                                    VStack(spacing: Spacing.lg) {
                                        // Video placeholder
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 15)
                                                .fill(Color.trainTextSecondary.opacity(0.1))
                                                .frame(height: 220)

                                            VStack(spacing: Spacing.md) {
                                                Image(systemName: "play.circle.fill")
                                                    .font(.system(size: 60))
                                                    .foregroundColor(.trainPrimary)

                                                Text("Video coming soon")
                                                    .font(.trainCaption)
                                                    .foregroundColor(.trainTextSecondary)
                                            }
                                        }
                                        .padding(.horizontal, Spacing.lg)
                                        .padding(.top, Spacing.md)

                                        // Exercise name
                                        Text(dbExercise.displayName)
                                            .font(.trainTitle2)
                                            .foregroundColor(.trainTextPrimary)
                                            .padding(.horizontal, Spacing.lg)

                                        // Instructions
                                        if let instructions = dbExercise.instructions, !instructions.isEmpty {
                                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                                let steps = instructions.split(separator: "\n")
                                                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                                                    HStack(alignment: .top, spacing: Spacing.sm) {
                                                        Text("\(index + 1).")
                                                            .font(.trainBodyMedium)
                                                            .foregroundColor(.trainPrimary)

                                                        Text(String(step))
                                                            .font(.trainBody)
                                                            .foregroundColor(.trainTextPrimary)
                                                    }
                                                }
                                            }
                                            .padding(Spacing.md)
                                            .background(Color.white)
                                            .cornerRadius(15)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 15)
                                                    .stroke(Color.trainBorder, lineWidth: 1)
                                            )
                                            .padding(.horizontal, Spacing.lg)
                                        } else {
                                            Text("Instructions coming soon")
                                                .font(.trainBody)
                                                .foregroundColor(.trainTextSecondary)
                                                .padding(Spacing.lg)
                                                .frame(maxWidth: .infinity)
                                                .background(Color.white)
                                                .cornerRadius(15)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 15)
                                                        .stroke(Color.trainBorder, lineWidth: 1)
                                                )
                                                .padding(.horizontal, Spacing.lg)
                                        }

                                        Spacer()
                                            .frame(height: 100)
                                    }
                                }
                            } else {
                                ProgressView("Loading exercise...")
                                    .foregroundColor(.trainTextPrimary)
                            }
                        }

                        // Bottom Actions
                        VStack(spacing: Spacing.md) {
                            if currentExerciseIndex < validSession.exercises.count - 1 {
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
        guard let validSession = session else {
            AppLogger.logWorkout("Cannot initialize exercises: no valid session", level: .error)
            return
        }
        loggedExercises = validSession.exercises.map { exercise in
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
            selectedTab = .logger
            selectedDBExercise = nil
        }
    }

    private func loadExerciseDetails() {
        guard let validSession = session,
              currentExerciseIndex < validSession.exercises.count else { return }
        let programExercise = validSession.exercises[currentExerciseIndex]
        guard let id = Int(programExercise.exerciseId) else { return }

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

    private func saveWorkout() {
        guard authService.currentUser != nil else {
            AppLogger.logWorkout("Cannot save workout: no current user", level: .error)
            return
        }

        guard let validSession = session else {
            AppLogger.logWorkout("Cannot save workout: no valid session", level: .error)
            return
        }

        // Calculate duration
        let duration = Int(Date().timeIntervalSince(startTime) / 60)

        // Save workout session to Core Data
        authService.addWorkoutSession(
            sessionName: validSession.dayName,
            weekNumber: weekNumber,
            exercises: loggedExercises,
            durationMinutes: duration
        )

        // Mark session as completed and progress to next
        authService.completeCurrentSession()

        print("✅ Workout saved: Week \(weekNumber), Session \(sessionIndex)")
        print("✅ Session marked as complete in Core Data")
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

    @State private var showRestTimer: Bool = false
    @State private var repsText: String = ""
    @State private var weightText: String = ""

    var body: some View {
        VStack(spacing: Spacing.sm) {
            HStack(spacing: Spacing.md) {
                // Set number
                Text("\(setNumber)")
                    .font(.trainBodyMedium)
                    .fontWeight(.bold)
                    .foregroundColor(.trainTextPrimary)
                    .frame(width: 32)

                // Reps text input
                TextField("0", text: $repsText)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .font(.trainBody)
                    .foregroundColor(.trainTextPrimary)
                    .padding(Spacing.sm)
                    .frame(width: 60)
                    .background(Color.white)
                    .cornerRadius(CornerRadius.sm)
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.sm)
                            .stroke(Color.trainBorder, lineWidth: 1)
                    )
                    .onChange(of: repsText) { _, newValue in
                        if let reps = Int(newValue) {
                            set.reps = reps
                        }
                    }

                // Weight text input
                TextField("0", text: $weightText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .font(.trainBody)
                    .foregroundColor(.trainTextPrimary)
                    .padding(Spacing.sm)
                    .frame(width: 80)
                    .background(Color.white)
                    .cornerRadius(CornerRadius.sm)
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.sm)
                            .stroke(Color.trainBorder, lineWidth: 1)
                    )
                    .onChange(of: weightText) { _, newValue in
                        if let weight = Double(newValue) {
                            set.weight = weightUnit == .kg ? weight : weight / 2.20462
                        }
                    }

                Spacer()

                // Completion toggle
                Button(action: toggleCompletion) {
                    Image(systemName: set.completed ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(set.completed ? .trainPrimary : .trainTextSecondary)
                }
            }
            .padding(Spacing.sm)
            .background(set.completed ? Color.trainPrimary.opacity(0.05) : Color.trainBackground)
            .cornerRadius(CornerRadius.sm)

            // Rest timer (appears after completing a set)
            if showRestTimer {
                RestTimerView(totalSeconds: restSeconds) {
                    showRestTimer = false
                }
            }
        }
        .onAppear {
            // Initialize text fields with existing values
            if set.reps > 0 {
                repsText = "\(set.reps)"
            }
            if set.weight > 0 {
                let displayWeight = weightUnit == .kg ? set.weight : set.weight * 2.20462
                weightText = String(format: "%.1f", displayWeight)
            }
        }
        .onChange(of: weightUnit) { _, newUnit in
            // Update weight display when unit changes
            if set.weight > 0 {
                let displayWeight = newUnit == .kg ? set.weight : set.weight * 2.20462
                weightText = String(format: "%.1f", displayWeight)
            }
        }
    }

    private func toggleCompletion() {
        let wasCompleted = set.completed
        set.completed.toggle()

        // Show rest timer when completing a set (not when un-completing)
        if !wasCompleted && set.completed && restSeconds > 0 {
            showRestTimer = true
        }
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
            weekNumber: 1,
            sessionIndex: 0
        )
    }
}
