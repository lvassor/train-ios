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
        guard let program = programData else {
            AppLogger.logWorkout("Cannot get session: programData is nil", level: .error)
            AppLogger.logWorkout("userProgram exists: \(userProgram != nil)", level: .error)
            if let up = userProgram {
                AppLogger.logWorkout("exercisesData exists: \(up.exercisesData != nil)", level: .error)
                AppLogger.logWorkout("exercisesData size: \(up.exercisesData?.count ?? 0) bytes", level: .error)
            }
            return nil
        }

        guard sessionIndex < program.sessions.count else {
            AppLogger.logWorkout("Cannot get session: sessionIndex \(sessionIndex) >= sessions.count \(program.sessions.count)", level: .error)
            return nil
        }

        AppLogger.logWorkout("Successfully loaded session \(sessionIndex): \(program.sessions[sessionIndex].dayName)")
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
                        }
                        .background(selectedTab == .logger ? Color.white : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                        Button(action: {
                            selectedTab = .demo
                            loadExerciseDetails()
                        }) {
                            Text("Demo")
                                .font(.trainBodyMedium)
                                .foregroundColor(selectedTab == .demo ? .trainTextPrimary : .trainTextSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, Spacing.md)
                        }
                        .background(selectedTab == .demo ? Color.white : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    }
                    .glassCompactCard()
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.sm)

                    // Current Exercise
                    if currentExerciseIndex < validSession.exercises.count && currentExerciseIndex < loggedExercises.count {
                        let programExercise = validSession.exercises[currentExerciseIndex]

                        if selectedTab == .logger {
                            ScrollView {
                                VStack(spacing: Spacing.lg) {
                                    // Exercise Info
                                    ExerciseInfoCard(
                                        exercise: programExercise,
                                        excessReps: calculateExcessReps(for: currentExerciseIndex)
                                    )
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
                                            .whiteCard()
                                            .padding(.horizontal, Spacing.lg)
                                        } else {
                                            Text("Instructions coming soon")
                                                .font(.trainBody)
                                                .foregroundColor(.trainTextSecondary)
                                                .padding(Spacing.lg)
                                                .frame(maxWidth: .infinity)
                                                .whiteCard()
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
                                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous))
                                        .accentGlow()
                                }
                            } else {
                                Button(action: { showCompletionModal = true }) {
                                    Text("Finish Workout")
                                        .font(.trainBodyMedium)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: ButtonHeight.standard)
                                        .background(Color.trainPrimary)
                                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous))
                                        .accentGlow()
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

    // MARK: - Rep Counter Logic

    /// Calculate excess reps compared to previous session
    private func calculateExcessReps(for exerciseIndex: Int) -> Int {
        guard exerciseIndex < loggedExercises.count else { return 0 }

        let currentExercise = loggedExercises[exerciseIndex]
        let exerciseName = currentExercise.exerciseName

        // Fetch previous session data (searches across all previous sessions for this exercise)
        guard let previousSets = authService.getPreviousSessionData(
            programId: userProgram?.id?.uuidString ?? "",
            exerciseName: exerciseName
        ) else {
            return 0  // No previous data - hide badge (Week 1 or always skipped)
        }

        var excessReps = 0

        // Compare set by set
        for (index, currentSet) in currentExercise.sets.enumerated() {
            guard index < previousSets.count else { break }

            let currentReps = currentSet.reps
            let previousReps = previousSets[index].reps

            if currentReps > previousReps {
                excessReps += (currentReps - previousReps)
            }
        }

        return excessReps
    }

    // MARK: - Progression Prompt Logic

    /// Evaluate prompt type based on completed sets vs target range
    private func evaluatePrompt(
        for exercise: LoggedExercise,
        targetMin: Int,
        targetMax: Int
    ) -> PromptType? {
        // Only show prompt when all sets completed (reps > 0)
        let completedSets = exercise.sets.filter { $0.reps > 0 }
        guard completedSets.count >= 3 else {
            return nil
        }

        let set1Reps = completedSets[0].reps
        let set2Reps = completedSets[1].reps
        let set3Reps = completedSets[2].reps

        // 🔴 REGRESSION: First 2 sets below minimum
        if set1Reps < targetMin || set2Reps < targetMin {
            return .regression
        }

        // 🟢 PROGRESSION: First 2 at/above max, 3rd in range
        if set1Reps >= targetMax && set2Reps >= targetMax && set3Reps >= targetMin {
            return .progression
        }

        // 🟡 CONSISTENCY: Strong start, weak finish
        if set1Reps >= targetMax && set2Reps >= targetMax && set3Reps < targetMin {
            return .consistency
        }

        // 🟡 CONSISTENCY: Default
        return .consistency
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
    let excessReps: Int

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.exerciseName)
                        .font(.trainTitle2)
                        .foregroundColor(.trainTextPrimary)
                }

                Spacer()

                // Rep Counter Badge
                RepCounterBadge(excessReps: excessReps)
            }

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
        .whiteCard()
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
        .glassCompactCard(cornerRadius: CornerRadius.sm)
    }
}

// MARK: - Set Logging View

struct SetLoggingView: View {
    let programExercise: ProgramExercise
    @Binding var loggedExercise: LoggedExercise
    @State private var weightUnit: WeightUnit = .kg
    @State private var currentPrompt: PromptType? = nil
    @State private var debounceTimer: Timer? = nil

    enum WeightUnit: String, CaseIterable {
        case kg = "kg"
        case lbs = "lbs"
    }

    private var unitToggle: some View {
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
        .glassCompactCard(cornerRadius: CornerRadius.sm)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Header with title and unit toggle
            HStack {
                Text("Log Sets")
                    .font(.trainHeadline)
                    .foregroundColor(.trainTextPrimary)

                Spacer()

                unitToggle
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

            // Progression Prompt (shown when all sets completed)
            if let prompt = currentPrompt {
                ProgressionPromptCard(promptType: prompt)
                    .padding(.top, Spacing.md)
            }
        }
        .padding(Spacing.md)
        .whiteCard()
        .onChange(of: loggedExercise.sets) { _, _ in
            evaluateAndShowPrompt()
        }
    }

    private func binding(for index: Int) -> Binding<LoggedSet> {
        Binding(
            get: { loggedExercise.sets[index] },
            set: { loggedExercise.sets[index] = $0 }
        )
    }

    /// Evaluate and show progression prompt with 500ms debounce
    private func evaluateAndShowPrompt() {
        // Cancel existing timer
        debounceTimer?.invalidate()

        // Create new timer with 500ms delay
        debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
            // Parse rep range (e.g., "8-12" -> min: 8, max: 12)
            let repComponents = programExercise.repRange.split(separator: "-").compactMap { Int($0) }
            guard repComponents.count == 2 else {
                currentPrompt = nil
                return
            }

            let targetMin = repComponents[0]
            let targetMax = repComponents[1]

            // Evaluate prompt based on completed sets
            currentPrompt = evaluatePromptForExercise(
                exercise: loggedExercise,
                targetMin: targetMin,
                targetMax: targetMax
            )
        }
    }

    /// Helper to evaluate prompt (calls parent's evaluatePrompt logic)
    private func evaluatePromptForExercise(
        exercise: LoggedExercise,
        targetMin: Int,
        targetMax: Int
    ) -> PromptType? {
        // Only show prompt when all sets completed (reps > 0)
        let completedSets = exercise.sets.filter { $0.reps > 0 }
        guard completedSets.count >= 3 else {
            return nil
        }

        let set1Reps = completedSets[0].reps
        let set2Reps = completedSets[1].reps
        let set3Reps = completedSets[2].reps

        // 🔴 REGRESSION: First 2 sets below minimum
        if set1Reps < targetMin || set2Reps < targetMin {
            return .regression
        }

        // 🟢 PROGRESSION: First 2 at/above max, 3rd in range
        if set1Reps >= targetMax && set2Reps >= targetMax && set3Reps >= targetMin {
            return .progression
        }

        // 🟡 CONSISTENCY: Strong start, weak finish
        if set1Reps >= targetMax && set2Reps >= targetMax && set3Reps < targetMin {
            return .consistency
        }

        // 🟡 CONSISTENCY: Default
        return .consistency
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

// MARK: - Rep Counter Badge

struct RepCounterBadge: View {
    let excessReps: Int
    @State private var showAnimation = false

    var body: some View {
        if excessReps > 0 {
            HStack(spacing: 4) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 12))
                Text("+\(excessReps)")
                    .font(.trainCaption)
                    .fontWeight(.bold)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.green)
            .cornerRadius(12)
            .scaleEffect(showAnimation ? 1.1 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: showAnimation)
            .onAppear {
                showAnimation = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showAnimation = false
                }
            }
            .onChange(of: excessReps) { _, _ in
                // Re-trigger animation when value changes
                showAnimation = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showAnimation = false
                }
            }
        }
    }
}

// MARK: - Progression Prompt Components

enum PromptType {
    case regression
    case consistency
    case progression

    var color: Color {
        switch self {
        case .regression: return .red
        case .consistency: return .orange
        case .progression: return .green
        }
    }

    var icon: String {
        switch self {
        case .regression: return "💪"
        case .consistency: return "🎯"
        case .progression: return "🎉"
        }
    }

    var title: String {
        switch self {
        case .regression: return "Great effort today!"
        case .consistency: return "You're doing great!"
        case .progression: return "Excellent work!"
        }
    }

    var subtitle: String {
        switch self {
        case .regression: return "Try choosing a weight that allows you to hit the target range for all sets"
        case .consistency: return "Try to hit the top end of the range or exceed it for all sets"
        case .progression: return "You hit or exceeded the top end for your first two sets! Time to increase weight next session"
        }
    }
}

struct ProgressionPromptCard: View {
    let promptType: PromptType
    @State private var showAnimation = false

    var body: some View {
        HStack(spacing: Spacing.md) {
            Text(promptType.icon)
                .font(.system(size: 32))

            VStack(alignment: .leading, spacing: 4) {
                Text(promptType.title)
                    .font(.trainBodyMedium)
                    .fontWeight(.bold)
                    .foregroundColor(.trainTextPrimary)

                Text(promptType.subtitle)
                    .font(.trainCaption)
                    .foregroundColor(.trainTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(Spacing.md)
        .background(promptType.color.opacity(0.1))
        .cornerRadius(CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(promptType.color, lineWidth: 2)
        )
        .scaleEffect(showAnimation ? 1.0 : 0.95)
        .opacity(showAnimation ? 1.0 : 0.0)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showAnimation)
        .onAppear {
            showAnimation = true
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
