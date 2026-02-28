//
//  WorkoutOverviewView.swift
//  TrainSwift
//
//  Workout overview page showing all exercises with warm-up countdown
//  Entry point before logging individual exercises
//

import SwiftUI
import ActivityKit
import UniformTypeIdentifiers

struct WorkoutOverviewView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var authService = AuthService.shared
    @ObservedObject private var workoutState = WorkoutStateManager.shared

    let weekNumber: Int
    let sessionIndex: Int

    var userProgram: WorkoutProgram? {
        authService.getCurrentProgram()
    }

    var programData: Program? {
        userProgram?.getProgram()
    }

    var session: ProgramSession? {
        guard let program = programData else { return nil }
        guard sessionIndex < program.sessions.count else { return nil }
        return program.sessions[sessionIndex]
    }

    // State
    @State private var startTime: Date? = nil  // nil until first exercise opened
    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer?
    @State private var workoutStarted = false  // Track if workout has begun
    @State private var showWarmUpTimer = true
    @State private var warmUpTimeRemaining: TimeInterval = 300 // 5 minutes
    @State private var warmUpTimer: Timer?
    @State private var warmUpStarted = false
    @State private var warmUpComplete = false
    @State private var completedExercises: Set<String> = []
    @State private var loggedExercises: [String: LoggedExercise] = [:]
    @State private var selectedExerciseIndex: Int? = nil
    @State private var showCancelConfirmation = false
    @State private var showCompletionView = false
    @State private var showCelebration = false
    @State private var celebrationData: PBCelebrationOverlay.CelebrationData?
    @State private var showInjuryWarning: String? = nil
    @State private var exerciseToSwap: ProgramExercise? = nil
    @State private var sessionExercises: [ProgramExercise] = [] // Mutable copy for swapping
    @State private var isEditing = false  // Edit mode for reordering, swap, remove
    @State private var exerciseToRemove: ProgramExercise? = nil  // For remove confirmation
    @State private var showExercisePickerInOverview = false
    @State private var hasAddedExerciseInOverview = false

    // Live Activity Manager
    @ObservedObject private var liveActivityManager = WorkoutLiveActivityManager.shared

    // Computed properties
    private var canCompleteWorkout: Bool {
        completedExercises.count >= 1
    }

    /// Get user's gender from questionnaire data for muscle highlight
    private var userGender: MuscleSelector.BodyGender {
        guard let user = authService.currentUser,
              let questionnaireData = user.getQuestionnaireData() else {
            return .male
        }
        return questionnaireData.gender.lowercased() == "female" ? .female : .male
    }

    private var elapsedTimeFormatted: String {
        let hours = Int(elapsedTime) / 3600
        let minutes = (Int(elapsedTime) % 3600) / 60
        let seconds = Int(elapsedTime) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    private var warmUpTimeFormatted: String {
        let minutes = Int(warmUpTimeRemaining) / 60
        let seconds = Int(warmUpTimeRemaining) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var body: some View {
        ZStack {
            // Background gradient - ignores safe area
            AppGradient.background
                .ignoresSafeArea()

            if session == nil {
                // Error state
                VStack(spacing: Spacing.lg) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: IconSize.xxl))
                        .foregroundColor(.trainTextSecondary)
                    Text("Unable to load workout session")
                        .font(.trainHeadline)
                        .foregroundColor(.trainTextPrimary)
                    Button("Go Back") { dismiss() }
                        .buttonStyle(PrimaryButtonStyle())
                        .padding(.horizontal, Spacing.xl)
                }
                .padding(Spacing.xl)
            } else if let validSession = session {
                VStack(spacing: 0) {
                    // Header with Edit/Done pill button (timer commented out per design)
                    WorkoutOverviewHeader(
                        sessionName: validSession.dayName,
                        elapsedTime: elapsedTimeFormatted,
                        isEditing: isEditing,
                        completedCount: completedExercises.count,
                        totalCount: sessionExercises.count,
                        onCancel: { showCancelConfirmation = true },
                        onEditToggle: { isEditing.toggle() }
                    )

                    ScrollView {
                        VStack(spacing: Spacing.lg) {
                            // Warm-up section
                            if !warmUpComplete {
                                WarmUpCard(
                                    timeRemaining: warmUpTimeFormatted,
                                    isStarted: warmUpStarted,
                                    onBegin: startWarmUp,
                                    onSkip: skipWarmUp
                                )
                                .padding(.horizontal, Spacing.lg)
                                .padding(.top, Spacing.md)
                            }

                            // Workout section with vertical connector line
                            WorkoutExerciseList(
                                exercises: $sessionExercises,
                                completedExercises: completedExercises,
                                isEditing: isEditing,
                                getContraindicatedInjury: getContraindicatedInjury,
                                onExerciseTap: { index in
                                    startWorkoutTimerIfNeeded()
                                    selectedExerciseIndex = index
                                },
                                onWarningTap: { exercise in
                                    if let warning = checkInjuryWarning(for: exercise) {
                                        showInjuryWarning = warning
                                    }
                                },
                                onSwap: { exercise in
                                    exerciseToSwap = exercise
                                },
                                onRemove: { exercise in
                                    exerciseToRemove = exercise
                                },
                                gender: userGender
                            )
                            .padding(.horizontal, Spacing.lg)

                            // Add Exercise button - only visible in edit mode
                            if isEditing && !hasAddedExerciseInOverview {
                                Button(action: {
                                    showExercisePickerInOverview = true
                                }) {
                                    HStack {
                                        Image(systemName: "plus")
                                            .font(.system(size: IconSize.sm))
                                        Text("Add Exercise")
                                            .font(.trainBody).fontWeight(.medium)
                                    }
                                    .foregroundColor(.trainPrimary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, Spacing.md)
                                    .background(Color.trainPrimary.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous))
                                }
                                .accessibilityLabel("Add exercise")
                                .accessibilityHint("Add a new exercise to this workout")
                                .padding(.horizontal, Spacing.lg)
                            }
                        }
                        .padding(.bottom, Spacing.lg) // Small padding for scroll content
                    }
                    .scrollContentBackground(.hidden)
                }
                .safeAreaInset(edge: .bottom) {
                    // Complete Workout button with gradient fade
                    ZStack(alignment: .bottom) {
                        // Gradient fade for scrollable content
                        LinearGradient(
                            colors: [.clear, Color.trainGradientMid.opacity(0.8), Color.trainGradientMid],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 100)
                        .allowsHitTesting(false)

                        Button(action: { triggerCelebration() }) {
                            Text("Complete Workout")
                                .font(.trainBodyMedium)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: ButtonHeight.standard)
                                .background(canCompleteWorkout ? Color.trainPrimary : Color.trainDisabled)
                                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous))
                        }
                        .disabled(!canCompleteWorkout)
                        .accessibilityLabel("Complete workout")
                        .accessibilityHint("Saves your workout and shows summary")
                        .padding(.horizontal, Spacing.lg)
                        .padding(.bottom, Spacing.md)
                    }
                }
            }

            // Injury warning alert
            if let warning = showInjuryWarning {
                InjuryWarningOverlay(
                    message: warning,
                    onContinue: {
                        showInjuryWarning = nil
                        // Proceed to exercise anyway
                        if let index = sessionExercises.firstIndex(where: { checkInjuryWarning(for: $0) == warning }) {
                            selectedExerciseIndex = index
                        }
                    },
                    onCancel: {
                        showInjuryWarning = nil
                    }
                )
            }

            // Celebration overlay (shown before workout summary)
            if showCelebration, let celebrationData = celebrationData {
                PBCelebrationOverlay(
                    data: celebrationData,
                    onDismiss: {
                        showCelebration = false
                        self.celebrationData = nil
                        showCompletionView = true
                    }
                )
                .zIndex(100)
            }

            // Exercise swap carousel
            if let exercise = exerciseToSwap {
                ExerciseSwapCarousel(
                    currentExercise: exercise,
                    onSelect: { newExercise in
                        // Replace exercise in sessionExercises
                        if let index = sessionExercises.firstIndex(where: { $0.id == exercise.id }) {
                            sessionExercises[index] = newExercise
                            // Re-initialize logged exercise for the new one
                            loggedExercises[newExercise.id] = LoggedExercise(
                                exerciseName: newExercise.exerciseName,
                                sets: (0..<newExercise.sets).map { _ in LoggedSet() },
                                notes: ""
                            )
                        }
                        exerciseToSwap = nil
                    },
                    onDismiss: {
                        exerciseToSwap = nil
                    }
                )
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationDestination(item: $selectedExerciseIndex) { index in
            if index < sessionExercises.count {
                let exercise = sessionExercises[index]
                let nextName: String? = (index + 1 < sessionExercises.count) ? sessionExercises[index + 1].exerciseName : nil
                ExerciseLoggerView(
                    exercise: exercise,
                    exerciseIndex: index,
                    totalExercises: sessionExercises.count,
                    weekNumber: weekNumber,
                    sessionIndex: sessionIndex,
                    sessionName: session?.dayName ?? "Workout",
                    loggedExercise: bindingForExercise(exercise),
                    onComplete: { logged in
                        completedExercises.insert(exercise.id)
                        loggedExercises[exercise.id] = logged
                        updateLiveActivityForNextExercise(completedIndex: index)
                        selectedExerciseIndex = nil
                    },
                    onCancel: {
                        selectedExerciseIndex = nil
                    },
                    nextExerciseName: nextName
                )
            }
        }
        .sheet(isPresented: $showCompletionView) {
            WorkoutSummaryView(
                sessionName: session?.dayName ?? "",
                duration: Int(elapsedTime / 60),
                completedExercises: completedExercises.count,
                totalExercises: session?.exercises.count ?? 0,
                loggedExercises: Array(loggedExercises.values),
                onDone: {
                    saveWorkout()
                    showCompletionView = false
                    dismiss()
                },
                onEdit: {
                    showCompletionView = false
                }
            )
        }
        .confirmationDialog("Cancel Workout", isPresented: $showCancelConfirmation, titleVisibility: .visible) {
            Button("Discard Workout", role: .destructive) {
                // Cancel workout in global state manager
                workoutState.cancelWorkout()

                // End Live Activity when workout is cancelled
                if #available(iOS 16.1, *) {
                    liveActivityManager.endWorkoutActivity()
                }
                dismiss()
            }
            Button("Continue Workout", role: .cancel) {}
        } message: {
            Text("Are you sure you want to cancel this workout? Your progress will not be saved.")
        }
        .confirmationDialog(
            "Remove Exercise?",
            isPresented: Binding(
                get: { exerciseToRemove != nil },
                set: { if !$0 { exerciseToRemove = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Remove Permanently", role: .destructive) {
                if let exercise = exerciseToRemove {
                    removeExercise(exercise)
                }
                exerciseToRemove = nil
            }
            Button("Cancel", role: .cancel) {
                exerciseToRemove = nil
            }
        } message: {
            if let exercise = exerciseToRemove {
                Text("This will permanently remove \"\(exercise.exerciseName)\" from your programme.\n\nIf you only want to skip it today, complete the sets with empty values instead.")
            }
        }
        .sheet(isPresented: $showExercisePickerInOverview) {
            ExercisePickerView(
                sessionMuscleGroups: Array(Set(sessionExercises.map { $0.primaryMuscle })).sorted(),
                existingExerciseIds: Set(sessionExercises.map { $0.exerciseId }),
                onSelect: { newExercise in
                    // Insert at correct position based on complexity (compounds first)
                    let insertIndex = sessionExercises.firstIndex(where: {
                        $0.complexityLevel < newExercise.complexityLevel
                    }) ?? sessionExercises.endIndex
                    sessionExercises.insert(newExercise, at: insertIndex)
                    // Initialize logged exercise for the new addition
                    loggedExercises[newExercise.id] = LoggedExercise(
                        exerciseName: newExercise.exerciseName,
                        sets: (0..<newExercise.sets).map { _ in LoggedSet() },
                        notes: ""
                    )
                    hasAddedExerciseInOverview = true
                }
            )
        }
        .onAppear {
            initializeSessionExercises()
            initializeLoggedExercises()

            // Check if this is a continuing workout
            if let activeWorkout = workoutState.activeWorkout,
               activeWorkout.sessionIndex == sessionIndex {
                // Restore workout state - calculate elapsed time immediately to prevent 00:00 flash
                workoutStarted = true
                startTime = activeWorkout.startTime
                elapsedTime = Date().timeIntervalSince(activeWorkout.startTime)  // Set immediately
                completedExercises = activeWorkout.completedExercises
                loggedExercises = activeWorkout.loggedExercises
                resumeTimer()
                AppLogger.logWorkout("Resumed active workout: \(activeWorkout.sessionName) - elapsed: \(elapsedTimeFormatted)")
            } else if workoutStarted {
                // Only resume timer if workout was already started (old behavior)
                resumeTimer()
            }
        }
        .onDisappear {
            stopTimers()
            // Update global workout state when leaving the view
            if workoutStarted && workoutState.isWorkoutActive {
                workoutState.updateWorkoutProgress(
                    completedExercises: completedExercises,
                    loggedExercises: loggedExercises,
                    modifiedExercises: sessionExercises
                )
            }
        }
    }

    // MARK: - Timer Functions

    private func startTimer() {
        // Only start timer if not already started
        guard !workoutStarted else { return }
        workoutStarted = true
        startTime = Date()
        resumeTimer()
    }

    private func resumeTimer() {
        // Resume timer from stored startTime
        guard let start = startTime else { return }
        timer?.invalidate()  // Clear any existing timer
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            elapsedTime = Date().timeIntervalSince(start)
        }
    }

    private func startWorkoutTimerIfNeeded() {
        // Start the workout timer when first exercise is opened
        if !workoutStarted {
            startTimer()
            startLiveActivity()

            // Register workout in global state manager
            if let session = session {
                workoutState.startWorkout(
                    sessionName: session.dayName,
                    weekNumber: weekNumber,
                    sessionIndex: sessionIndex,
                    totalExercises: sessionExercises.count
                )
            }
        } else if timer == nil {
            // Timer was invalidated but workout was started - resume it
            resumeTimer()
        }
    }

    private func startLiveActivity() {
        guard let validSession = session,
              let firstExercise = sessionExercises.first,
              let loggedFirstExercise = loggedExercises[firstExercise.id] else { return }

        if #available(iOS 16.1, *) {
            liveActivityManager.startWorkoutActivity(
                workoutName: validSession.dayName,
                totalExercises: sessionExercises.count,
                currentExercise: loggedFirstExercise,
                exerciseIndex: 0
            )
        }
    }

    private func updateLiveActivityForNextExercise(completedIndex: Int) {
        guard #available(iOS 16.1, *) else { return }

        let nextIndex = completedIndex + 1
        if nextIndex < sessionExercises.count {
            // Update to next exercise
            let nextExercise = sessionExercises[nextIndex]
            if let loggedNextExercise = loggedExercises[nextExercise.id] {
                liveActivityManager.updateExercise(
                    currentExercise: loggedNextExercise,
                    exerciseIndex: nextIndex,
                    elapsedTime: elapsedTime
                )
            }
        } else {
            // All exercises completed - end the activity
            liveActivityManager.endWorkoutActivity()
        }
    }

    private func startWarmUp() {
        warmUpStarted = true
        warmUpTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if warmUpTimeRemaining > 0 {
                warmUpTimeRemaining -= 1
            } else {
                warmUpComplete = true
                warmUpTimer?.invalidate()
            }
        }
    }

    private func skipWarmUp() {
        warmUpComplete = true
        warmUpTimer?.invalidate()
    }

    private func stopTimers() {
        timer?.invalidate()
        warmUpTimer?.invalidate()
    }

    // MARK: - Exercise Functions

    private func initializeSessionExercises() {
        guard let validSession = session else { return }
        // Only initialize if empty (prevents overwriting edits when re-appearing from logger)
        if sessionExercises.isEmpty {
            // Check for modified exercises from active workout state first
            if let activeWorkout = workoutState.activeWorkout,
               activeWorkout.sessionIndex == sessionIndex,
               let modified = activeWorkout.modifiedExercises {
                sessionExercises = modified
            } else {
                sessionExercises = validSession.exercises
            }
        }
    }

    private func removeExercise(_ exercise: ProgramExercise) {
        // Remove from session exercises
        sessionExercises.removeAll { $0.id == exercise.id }
        // Also remove from logged exercises if present
        loggedExercises.removeValue(forKey: exercise.id)
        // Remove from completed if it was marked
        completedExercises.remove(exercise.id)
    }

    private func initializeLoggedExercises() {
        let programId = userProgram?.id?.uuidString ?? ""
        for exercise in sessionExercises {
            // Only create logged exercise if one doesn't already exist (prevents overwriting data)
            if loggedExercises[exercise.id] == nil {
                var sets = (0..<exercise.sets).map { _ in LoggedSet() }

                // Pre-populate weight/reps from previous session data
                if let previousSets = authService.getPreviousSessionData(
                    programId: programId,
                    exerciseName: exercise.exerciseName
                ) {
                    for i in 0..<min(sets.count, previousSets.count) {
                        sets[i].weight = previousSets[i].weight
                        sets[i].reps = previousSets[i].reps
                    }
                }

                loggedExercises[exercise.id] = LoggedExercise(
                    exerciseName: exercise.exerciseName,
                    sets: sets,
                    notes: ""
                )
            }
        }
    }

    private func bindingForExercise(_ exercise: ProgramExercise) -> Binding<LoggedExercise> {
        Binding(
            get: {
                loggedExercises[exercise.id] ?? LoggedExercise(
                    exerciseName: exercise.exerciseName,
                    sets: (0..<exercise.sets).map { _ in LoggedSet() },
                    notes: ""
                )
            },
            set: { newValue in
                loggedExercises[exercise.id] = newValue
            }
        )
    }

    private func checkInjuryWarning(for exercise: ProgramExercise) -> String? {
        guard let currentUser = authService.currentUser else { return nil }
        let userInjuries = currentUser.injuriesArray
        guard !userInjuries.isEmpty else { return nil }

        // Query the database for contraindications
        do {
            guard let dbExercise = try ExerciseDatabaseManager.shared.fetchExercise(byId: exercise.exerciseId) else {
                return nil
            }

            // Check if this exercise is contraindicated for any of the user's injuries
            if try ExerciseDatabaseManager.shared.isContraindicated(exercise: dbExercise, forInjuries: userInjuries) {
                let contraindications = try ExerciseDatabaseManager.shared.fetchContraindications(for: dbExercise)
                let matchingInjuries = Set(contraindications).intersection(Set(userInjuries))
                if let firstInjury = matchingInjuries.first {
                    return "This exercise may aggravate your \(firstInjury) injury. Consider swapping for an alternative or proceed with caution."
                }
            }
        } catch {
            AppLogger.logUI("Error checking contraindications: \(error)", level: .error)
        }

        return nil
    }

    /// Check if an exercise has contraindications (for showing warning icon)
    private func hasContraindication(for exercise: ProgramExercise) -> Bool {
        return checkInjuryWarning(for: exercise) != nil
    }

    /// Get the injury type for warning display
    private func getContraindicatedInjury(for exercise: ProgramExercise) -> String? {
        guard let currentUser = authService.currentUser else { return nil }
        let userInjuries = currentUser.injuriesArray
        guard !userInjuries.isEmpty else { return nil }

        do {
            guard let dbExercise = try ExerciseDatabaseManager.shared.fetchExercise(byId: exercise.exerciseId) else {
                return nil
            }

            let contraindications = try ExerciseDatabaseManager.shared.fetchContraindications(for: dbExercise)
            let matchingInjuries = Set(contraindications).intersection(Set(userInjuries))
            return matchingInjuries.first
        } catch {
            return nil
        }
    }

    private func triggerCelebration() {
        // Calculate celebration data from logged exercises vs previous session
        let completedLoggedExercises = Array(loggedExercises.values).filter { logged in
            completedExercises.contains(where: { id in
                sessionExercises.first(where: { $0.id == id })?.exerciseName == logged.exerciseName
            })
        }
        celebrationData = PBCelebrationOverlay.CelebrationData.calculate(
            loggedExercises: completedLoggedExercises,
            authService: authService
        )
        showCelebration = true
    }

    private func saveWorkout() {
        guard authService.currentUser != nil else { return }
        guard let validSession = session else { return }

        let duration = Int(elapsedTime / 60)
        let exercisesToSave = Array(loggedExercises.values).filter { logged in
            completedExercises.contains(where: { id in
                sessionExercises.first(where: { $0.id == id })?.exerciseName == logged.exerciseName
            })
        }

        authService.addWorkoutSession(
            sessionName: validSession.dayName,
            weekNumber: weekNumber,
            exercises: exercisesToSave,
            durationMinutes: duration
        )

        authService.completeCurrentSession()

        // Complete workout in global state manager
        workoutState.completeWorkout()

        // End Live Activity when workout is saved
        if #available(iOS 16.1, *) {
            liveActivityManager.endWorkoutActivity()
        }
    }
}

// MARK: - Header Component (Figma Redesign)

struct WorkoutOverviewHeader: View {
    let sessionName: String
    let elapsedTime: String  // Kept for reference but not displayed per design
    let isEditing: Bool
    let completedCount: Int
    let totalCount: Int
    let onCancel: () -> Void
    let onEditToggle: () -> Void

    var body: some View {
        HStack {
            // Back button
            Button(action: onCancel) {
                Image(systemName: "arrow.left")
                    .font(.system(size: IconSize.md))
                    .foregroundColor(.trainTextPrimary)
            }
            .frame(width: 24, height: 24)
            .accessibilityLabel("Cancel workout")

            Spacer()

            // Title with progress indicator
            VStack(spacing: 2) {
                Text(sessionName)
                    .font(.trainBodyMedium)
                    .foregroundColor(.trainTextPrimary)

                // Progress pill
                Text("\(completedCount)/\(totalCount) exercises")
                    .font(.trainCaptionSmall)
                    .foregroundColor(.trainTextSecondary)
            }

            Spacer()

            // Edit/Done pill button (Apple-style)
            Button(action: onEditToggle) {
                Text(isEditing ? "Done" : "Edit")
                    .font(.trainCaption).fontWeight(.medium)
                    .foregroundColor(isEditing ? .trainPrimary : .trainTextPrimary)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                    .background(
                        Capsule()
                            .stroke(isEditing ? Color.trainPrimary : Color.trainTextSecondary.opacity(0.3), lineWidth: 1)
                    )
            }
            .accessibilityLabel(isEditing ? "Done editing" : "Edit exercises")
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.md)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Warm Up Card (Figma Redesign)

struct WarmUpCard: View {
    let timeRemaining: String
    let isStarted: Bool
    let onBegin: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Section title
            Text("Suggested Warm-Up")
                .font(.trainCaption).fontWeight(.light)
                .foregroundColor(.trainTextSecondary)
                .padding(.top, Spacing.sm)

            // Warm up card - Figma style with thumbnail
            Button(action: onBegin) {
                HStack(spacing: Spacing.md) {
                    // Thumbnail with play button
                    ZStack(alignment: .bottomLeading) {
                        RoundedRectangle(cornerRadius: CornerRadius.xs, style: .continuous)
                            .fill(Color.trainTextSecondary.opacity(0.2))
                            .frame(width: ThumbnailSize.width, height: ThumbnailSize.height)
                            .overlay {
                                Image(systemName: "figure.strengthtraining.traditional")
                                    .font(.system(size: IconSize.md))
                                    .foregroundColor(.trainTextSecondary.opacity(0.5))
                            }

                        // Play button
                        Image(systemName: "play.fill")
                            .font(.trainMicro)
                            .foregroundColor(.white)
                            .padding(Spacing.sm)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                            .offset(x: 4, y: -4)
                    }

                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Upper Body Mobility")
                            .font(.trainBody).fontWeight(.medium)
                            .foregroundColor(.trainTextPrimary)

                        Text("5 exercises • 5 minutes")
                            .font(.trainCaption).fontWeight(.light)
                            .foregroundColor(.trainTextSecondary)
                    }

                    Spacer()

                    // Skip button
                    Button(action: onSkip) {
                        Text("Skip")
                            .font(.trainCaption).fontWeight(.light)
                            .foregroundColor(.trainTextSecondary)
                            .padding(.horizontal, Spacing.smd)
                            .padding(.vertical, Spacing.sm)
                            .background(Color.trainTextSecondary.opacity(0.1))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .accessibilityLabel("Skip warm-up")
                }
                .padding(Spacing.md)
                .background(Color.trainSurface)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous))
                .shadowStyle(.borderLine)
            }
            .buttonStyle(ScaleButtonStyle())
            .accessibilityLabel("Warm-up: Upper Body Mobility, 5 exercises, 5 minutes")
        }
    }
}

// MARK: - Workout Exercise List (with vertical connector line behind cards)

struct WorkoutExerciseList: View {
    @Binding var exercises: [ProgramExercise]
    let completedExercises: Set<String>
    let isEditing: Bool
    let getContraindicatedInjury: (ProgramExercise) -> String?
    let onExerciseTap: (Int) -> Void
    let onWarningTap: (ProgramExercise) -> Void
    let onSwap: (ProgramExercise) -> Void
    let onRemove: (ProgramExercise) -> Void
    var gender: MuscleSelector.BodyGender = .male

    // Drag state
    @State private var draggingExercise: ProgramExercise?
    @State private var draggedOverExercise: ProgramExercise?

    // Thumbnail width is 80, padding is 16, so center of thumbnail is at 16 + 40 = 56
    private let lineXOffset: CGFloat = 56

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Section title
            Text("Workout")
                .font(.trainCaption).fontWeight(.light)
                .foregroundColor(.trainTextSecondary)
                .padding(.top, Spacing.sm)

            // Exercise cards with vertical line behind
            ZStack(alignment: .leading) {
                // Vertical connector line - hidden when editing
                if !isEditing {
                    Rectangle()
                        .fill(Color.trainTextSecondary.opacity(0.2))
                        .frame(width: Spacing.xxs)
                        .padding(.leading, lineXOffset - 1)
                        .padding(.top, Spacing.xxl)
                        .padding(.bottom, Spacing.xxl)
                }

                // Exercise cards
                VStack(spacing: Spacing.smd) {
                    ForEach(Array(exercises.enumerated()), id: \.element.id) { index, exercise in
                        exerciseCardView(for: exercise, at: index)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func exerciseCardView(for exercise: ProgramExercise, at index: Int) -> some View {
        let isDragging = draggingExercise?.id == exercise.id
        let isDraggedOver = draggedOverExercise?.id == exercise.id

        let card = ExerciseOverviewCard(
            exercise: exercise,
            isCompleted: completedExercises.contains(exercise.id),
            isEditing: isEditing,
            contraindicatedInjury: getContraindicatedInjury(exercise),
            onTap: {
                if !isEditing {
                    onExerciseTap(index)
                }
            },
            onWarningTap: {
                onWarningTap(exercise)
            },
            onSwap: {
                onSwap(exercise)
            },
            onRemove: {
                onRemove(exercise)
            },
            gender: gender
        )

        if isEditing {
            // Edit mode: apply drag/drop modifiers
            card
                .scaleEffect(isDragging ? 1.05 : 1.0)
                .shadowStyle(isDragging ? .dragging : .borderLine)
                .opacity(isDragging ? 0.9 : 1.0)
                .zIndex(isDragging ? 100 : 0)
                .background(
                    isDraggedOver && !isDragging ?
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .stroke(Color.trainPrimary, lineWidth: 2)
                            .padding(-4)
                        : nil
                )
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isDragging)
                .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isDraggedOver)
                .onDrag {
                    self.draggingExercise = exercise
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                    return NSItemProvider(object: exercise.id as NSString)
                }
                .onDrop(of: [.text], delegate: ExerciseDropDelegate(
                    exercise: exercise,
                    exercises: $exercises,
                    draggingExercise: $draggingExercise,
                    draggedOverExercise: $draggedOverExercise,
                    isEditing: isEditing
                ))
        } else {
            // Normal mode: no drag/drop, just the card
            card
        }
    }
}

// MARK: - Exercise Drop Delegate

struct ExerciseDropDelegate: DropDelegate {
    let exercise: ProgramExercise
    @Binding var exercises: [ProgramExercise]
    @Binding var draggingExercise: ProgramExercise?
    @Binding var draggedOverExercise: ProgramExercise?
    let isEditing: Bool

    func dropEntered(info: DropInfo) {
        guard isEditing,
              let dragging = draggingExercise,
              dragging.id != exercise.id else { return }

        draggedOverExercise = exercise

        // Haptic feedback when entering a new drop target
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()

        // Find indices and perform swap with animation
        guard let fromIndex = exercises.firstIndex(where: { $0.id == dragging.id }),
              let toIndex = exercises.firstIndex(where: { $0.id == exercise.id }) else { return }

        if fromIndex != toIndex {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                exercises.move(fromOffsets: IndexSet(integer: fromIndex), toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex)
            }
        }
    }

    func dropExited(info: DropInfo) {
        if draggedOverExercise?.id == exercise.id {
            draggedOverExercise = nil
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: isEditing ? .move : .cancel)
    }

    func performDrop(info: DropInfo) -> Bool {
        // Haptic feedback on drop
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()

        draggingExercise = nil
        draggedOverExercise = nil
        return true
    }
}

// MARK: - Exercise Overview Card (Figma Redesign - Full Width)

struct ExerciseOverviewCard: View {
    let exercise: ProgramExercise
    let isCompleted: Bool
    let isEditing: Bool
    var contraindicatedInjury: String? = nil
    let onTap: () -> Void
    var onWarningTap: (() -> Void)? = nil
    let onSwap: () -> Void
    let onRemove: () -> Void
    var gender: MuscleSelector.BodyGender = .male

    // Drag state for visual feedback
    @State private var isDragHandlePressed = false

    private var thumbnailURL: URL? {
        ExerciseMediaMapping.thumbnailURL(for: exercise.exerciseId)
    }

    private var hasVideo: Bool {
        ExerciseMediaMapping.videoGuid(for: exercise.exerciseId) != nil
    }

    var body: some View {
        VStack(spacing: 0) {
            // Drag handle - only visible in edit mode
            if isEditing {
                dragHandle
            }

            Button(action: onTap) {
                HStack(spacing: Spacing.md) {
                    // Thumbnail with play button - fixed 80x64 dimensions
                    ZStack(alignment: .bottomLeading) {
                        if let url = thumbnailURL {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: ThumbnailSize.width, height: ThumbnailSize.height)
                                        .clipped()
                                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.xs, style: .continuous))
                                case .failure, .empty:
                                    thumbnailPlaceholder
                                @unknown default:
                                    thumbnailPlaceholder
                                }
                            }
                        } else {
                            thumbnailPlaceholder
                        }

                        // Play button (only for videos)
                        if hasVideo {
                            Image(systemName: "play.fill")
                                .font(.trainMicro)
                                .foregroundColor(.white)
                                .padding(Spacing.sm)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                                .offset(x: 4, y: -4)
                        }
                    }
                    .frame(width: ThumbnailSize.width, height: ThumbnailSize.height)

                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        HStack(spacing: Spacing.xs) {
                            Text(exercise.exerciseName)
                                .font(.trainBody).fontWeight(.medium)
                                .foregroundColor(isCompleted ? .trainTextSecondary : .trainTextPrimary)
                                .strikethrough(isCompleted)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)

                            // Warning icon
                            if contraindicatedInjury != nil {
                                Button(action: { onWarningTap?() }) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.trainCaption)
                                        .foregroundColor(.trainWarning)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }

                        Text("\(exercise.sets) sets • \(exercise.repRange) reps")
                            .font(.trainCaption).fontWeight(.light)
                            .foregroundColor(.trainTextSecondary)
                    }

                    Spacer()

                    // Muscle highlight (replaces swap icon in normal mode)
                    CompactMuscleHighlight(
                        primaryMuscle: exercise.primaryMuscle,
                        secondaryMuscle: nil,
                        gender: gender
                    )
                    .frame(height: 64)
                }
                .padding(Spacing.md)
                .contentShape(Rectangle()) // Make entire card area tappable
                .padding(.top, isEditing ? 0 : 0) // No extra padding needed, drag handle has its own
            }
            .buttonStyle(ScaleButtonStyle())
            .disabled(isEditing) // Disable tap when editing

            // Swap and Remove buttons - only visible in edit mode
            if isEditing {
                editActionButtons
            }
        }
        .background(
            contraindicatedInjury != nil
                ? Color.gray.opacity(0.15)
                : (isEditing
                    ? Color.trainPrimary.opacity(0.08)
                    : (isCompleted
                        ? Color.trainPrimary.opacity(0.08)
                        : Color.trainSurface))
        )
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous))
        .shadowStyle(.borderLine)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                .stroke(isEditing ? Color.trainPrimary.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(exercise.exerciseName), \(exercise.sets) sets of \(exercise.repRange) reps")
        .accessibilityValue(isCompleted ? "Completed" : "Not started")
    }

    // MARK: - Drag Handle (Double Line Indicator)

    private var dragHandle: some View {
        // Double horizontal line drag indicator - centered
        VStack(spacing: Spacing.xxs) {
            RoundedRectangle(cornerRadius: 1)
                .fill(isDragHandlePressed ? Color.trainPrimary : Color.trainTextSecondary.opacity(0.4))
                .frame(width: 36, height: 3)
            RoundedRectangle(cornerRadius: 1)
                .fill(isDragHandlePressed ? Color.trainPrimary : Color.trainTextSecondary.opacity(0.4))
                .frame(width: 36, height: 3)
        }
        .scaleEffect(isDragHandlePressed ? 1.1 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isDragHandlePressed)
        .padding(.vertical, Spacing.sm)
    }

    // MARK: - Edit Action Buttons

    private var editActionButtons: some View {
        HStack(spacing: Spacing.smd) {
            // Swap button
            Button(action: onSwap) {
                Text("Swap")
                    .font(.trainCaption).fontWeight(.medium)
                    .foregroundColor(.trainTextPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.trainPrimary.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm, style: .continuous))
            }

            // Remove button
            Button(action: onRemove) {
                Text("Remove")
                    .font(.trainCaption).fontWeight(.medium)
                    .foregroundColor(.trainError.opacity(0.8))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.trainError.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm, style: .continuous))
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.bottom, Spacing.md)
    }

    private var thumbnailPlaceholder: some View {
        RoundedRectangle(cornerRadius: CornerRadius.xs, style: .continuous)
            .fill(Color.trainTextSecondary.opacity(0.2))
            .frame(width: ThumbnailSize.width, height: ThumbnailSize.height)
            .overlay {
                Image(systemName: "photo")
                    .font(.system(size: IconSize.md))
                    .foregroundColor(.trainTextSecondary.opacity(0.5))
            }
    }
}

// MARK: - Injury Warning Overlay

struct InjuryWarningOverlay: View {
    let message: String
    let onContinue: () -> Void
    let onCancel: () -> Void

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0)
                .ignoresSafeArea()

            // Modal card - liquid glass effect
            VStack(spacing: Spacing.lg) {
                // Warning icon
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: IconSize.xl))
                    .foregroundColor(.trainWarning)

                // Title
                Text("Injury Warning")
                    .font(.trainHeadline)
                    .foregroundColor(.trainTextPrimary)
                    .multilineTextAlignment(.center)

                // Message
                Text(message)
                    .font(.trainBody)
                    .foregroundColor(.trainTextSecondary)
                    .multilineTextAlignment(.center)

                // Buttons
                HStack(spacing: Spacing.md) {
                    // Secondary button
                    Button(action: onCancel) {
                        Text("Go Back")
                            .font(.trainBodyMedium)
                            .foregroundColor(.trainTextPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: ElementHeight.button)
                            .background(Color.trainSurface.opacity(0.5))
                            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.pill, style: .continuous))
                    }

                    // Primary button (accent color)
                    Button(action: onContinue) {
                        Text("Continue")
                            .font(.trainBodyMedium)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: ElementHeight.button)
                            .background(Color.trainPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.pill, style: .continuous))
                    }
                }
            }
            .padding(Spacing.xl)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.modal, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.modal, style: .continuous)
                    .stroke(Color.trainBorderSubtle.opacity(0.3), lineWidth: 1)
            )
            .padding(.horizontal, Spacing.xl)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        WorkoutOverviewView(weekNumber: 1, sessionIndex: 0)
    }
}
