//
//  WorkoutOverviewView.swift
//  trAInSwift
//
//  Workout overview page showing all exercises with warm-up countdown
//  Entry point before logging individual exercises
//

import SwiftUI
import ActivityKit

struct WorkoutOverviewView: View {
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
    @State private var showInjuryWarning: String? = nil
    @State private var exerciseToSwap: ProgramExercise? = nil
    @State private var sessionExercises: [ProgramExercise] = [] // Mutable copy for swapping

    // Live Activity Manager
    @ObservedObject private var liveActivityManager = WorkoutLiveActivityManager.shared

    // Computed properties
    private var canCompleteWorkout: Bool {
        completedExercises.count >= 1
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
            if session == nil {
                // Error state
                VStack(spacing: Spacing.lg) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
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
                ZStack {
                    VStack(spacing: 0) {
                        // Header with timer and cancel
                        WorkoutOverviewHeader(
                            sessionName: validSession.dayName,
                            elapsedTime: elapsedTimeFormatted,
                            onCancel: { showCancelConfirmation = true }
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

                                // Exercise list - uses mutable sessionExercises for swapping
                                VStack(spacing: Spacing.md) {
                                    ForEach(Array(sessionExercises.enumerated()), id: \.element.id) { index, exercise in
                                        ExerciseOverviewCard(
                                            exercise: exercise,
                                            isCompleted: completedExercises.contains(exercise.id),
                                            contraindicatedInjury: getContraindicatedInjury(for: exercise),
                                            onTap: {
                                                startWorkoutTimerIfNeeded()  // Start timer on first exercise tap
                                                selectedExerciseIndex = index
                                            },
                                            onWarningTap: {
                                                if let warning = checkInjuryWarning(for: exercise) {
                                                    showInjuryWarning = warning
                                                }
                                            },
                                            onSwap: {
                                                exerciseToSwap = exercise
                                            }
                                        )
                                    }
                                }
                                .padding(.horizontal, Spacing.lg)
                            }
                            .padding(.bottom, 90) // Space for floating button
                        }
                        .scrollContentBackground(.hidden)
                    }

                    // Complete Workout button - floating overlay at bottom
                    VStack {
                        Spacer()
                        Button(action: { showCompletionView = true }) {
                            Text("Complete Workout")
                                .font(.trainBodyMedium)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: ButtonHeight.standard)
                                .background(canCompleteWorkout ? Color.trainPrimary : Color.trainDisabled)
                                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous))
                        }
                        .disabled(!canCompleteWorkout)
                        .padding(.horizontal, Spacing.lg)
                        .padding(.bottom, Spacing.lg)
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
        .charcoalGradientBackground()
        .navigationBarBackButtonHidden(true)
        .navigationDestination(item: $selectedExerciseIndex) { index in
            if index < sessionExercises.count {
                let exercise = sessionExercises[index]
                ExerciseLoggerView(
                    exercise: exercise,
                    exerciseIndex: index,
                    totalExercises: sessionExercises.count,
                    weekNumber: weekNumber,
                    sessionIndex: sessionIndex,
                    loggedExercise: bindingForExercise(exercise),
                    onComplete: { logged in
                        completedExercises.insert(exercise.id)
                        loggedExercises[exercise.id] = logged
                        updateLiveActivityForNextExercise(completedIndex: index)
                        selectedExerciseIndex = nil
                    },
                    onCancel: {
                        selectedExerciseIndex = nil
                    }
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
        .onAppear {
            // Only resume timer if workout was already started
            if workoutStarted {
                resumeTimer()
            }
            initializeSessionExercises()
            initializeLoggedExercises()
        }
        .onDisappear {
            stopTimers()
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
        // Create mutable copy of exercises for swapping
        sessionExercises = validSession.exercises
    }

    private func initializeLoggedExercises() {
        for exercise in sessionExercises {
            loggedExercises[exercise.id] = LoggedExercise(
                exerciseName: exercise.exerciseName,
                sets: (0..<exercise.sets).map { _ in LoggedSet() },
                notes: ""
            )
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
            print("❌ Error checking contraindications: \(error)")
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

    private func saveWorkout() {
        guard authService.currentUser != nil else { return }
        guard let validSession = session else { return }

        let duration = Int(elapsedTime / 60)
        let exercisesToSave = Array(loggedExercises.values).filter { logged in
            completedExercises.contains(where: { id in
                validSession.exercises.first(where: { $0.id == id })?.exerciseName == logged.exerciseName
            })
        }

        authService.addWorkoutSession(
            sessionName: validSession.dayName,
            weekNumber: weekNumber,
            exercises: exercisesToSave,
            durationMinutes: duration
        )

        authService.completeCurrentSession()

        // End Live Activity when workout is saved
        if #available(iOS 16.1, *) {
            liveActivityManager.endWorkoutActivity()
        }
    }
}

// MARK: - Header Component

struct WorkoutOverviewHeader: View {
    let sessionName: String
    let elapsedTime: String
    let onCancel: () -> Void

    var body: some View {
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
            }

            Spacer()

            // Timer display
            Text(elapsedTime)
                .font(.trainBodyMedium)
                .foregroundColor(.trainPrimary)
                .monospacedDigit()
        }
        .padding(Spacing.lg)
        .appCard()
    }
}

// MARK: - Warm Up Card

struct WarmUpCard: View {
    let timeRemaining: String
    let isStarted: Bool
    let onBegin: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Section title
            Text("Suggested Warm-Up")
                .font(.trainCaption)
                .foregroundColor(.trainTextSecondary)
                .padding(.leading, 4)

            // Warm up card - matches exercise card style
            Button(action: onBegin) {
                HStack(spacing: Spacing.md) {
                    // Video placeholder icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color.trainTextSecondary.opacity(0.3), lineWidth: 1)
                            .frame(width: 56, height: 56)

                        Image(systemName: "play.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.trainTextSecondary.opacity(0.5))
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Upper body mobility")
                            .font(.trainBodyMedium)
                            .foregroundColor(.trainTextPrimary)

                        Text("5 min")
                            .font(.trainCaption)
                            .foregroundColor(.trainTextSecondary)
                    }

                    Spacer()

                    // Skip button
                    Button(action: onSkip) {
                        Text("Skip")
                            .font(.trainCaption)
                            .foregroundColor(.trainTextSecondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(Spacing.md)
                .appCard()
            }
            .buttonStyle(ScaleButtonStyle())
        }
    }
}

// MARK: - Exercise Overview Card

struct ExerciseOverviewCard: View {
    let exercise: ProgramExercise
    let isCompleted: Bool
    var contraindicatedInjury: String? = nil
    let onTap: () -> Void
    var onWarningTap: (() -> Void)? = nil
    let onSwap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .center, spacing: Spacing.md) {
                // Completion indicator
                ZStack {
                    Circle()
                        .stroke(isCompleted ? Color.trainPrimary : Color.trainTextSecondary.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.trainPrimary)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: Spacing.xs) {
                        Text(exercise.exerciseName)
                            .font(.trainBodyMedium)
                            .foregroundColor(isCompleted ? .trainTextSecondary : .trainTextPrimary)
                            .strikethrough(isCompleted)

                        // Contraindication warning icon
                        if contraindicatedInjury != nil {
                            Button(action: { onWarningTap?() }) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.orange)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }

                    HStack(spacing: Spacing.sm) {
                        Text("\(exercise.sets) × \(exercise.repRange)")
                            .font(.trainCaption)
                            .foregroundColor(.trainTextSecondary)

                        // Equipment badge
                        Text(exercise.equipmentType)
                            .font(.trainCaption)
                            .foregroundColor(.trainTextSecondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.trainTextSecondary.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }

                Spacer()

                // Swap button
                Button(action: onSwap) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 16))
                        .foregroundColor(.trainTextSecondary)
                }
                .buttonStyle(PlainButtonStyle())

                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.trainTextSecondary)
            }
            .padding(Spacing.md)
            .background(
                contraindicatedInjury != nil
                    ? Color.gray.opacity(0.15)
                    : (isCompleted ? Color.trainPrimary.opacity(0.05) : Color.clear)
            )
            .appCard()
        }
        .buttonStyle(ScaleButtonStyle())
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
                    .font(.system(size: 40))
                    .foregroundColor(.orange)

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
                            .frame(height: 50)
                            .background(Color.white.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
                    }

                    // Primary button (accent color)
                    Button(action: onContinue) {
                        Text("Continue")
                            .font(.trainBodyMedium)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.trainPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
                    }
                }
            }
            .padding(Spacing.xl)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
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
