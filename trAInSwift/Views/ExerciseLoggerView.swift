//
//  ExerciseLoggerView.swift
//  trAInSwift
//
//  Individual exercise logging view with set tracking
//  Shows demo video tab and Submit Exercise button
//

import SwiftUI

struct ExerciseLoggerView: View {
    @Environment(\.dismiss) var dismiss

    let exercise: ProgramExercise
    let exerciseIndex: Int
    let totalExercises: Int
    let weekNumber: Int
    let sessionIndex: Int
    @Binding var loggedExercise: LoggedExercise
    let onComplete: (LoggedExercise) -> Void
    let onCancel: () -> Void

    @State private var selectedTab: LoggerTab = .logger
    @State private var showRestTimer = false
    @State private var activeSetIndex: Int? = nil
    @State private var weightUnit: WeightUnit = .kg
    @State private var selectedDBExercise: DBExercise?
    @State private var showFeedbackNotification = false
    @State private var feedbackTitle: String = ""
    @State private var feedbackMessage: String = ""
    @State private var feedbackType: FeedbackType = .success

    enum LoggerTab {
        case logger, demo
    }

    enum WeightUnit: String, CaseIterable {
        case kg = "kg"
        case lbs = "lbs"
    }

    enum FeedbackType {
        case success, warning, info

        var color: Color {
            switch self {
            case .success: return .green
            case .warning: return .orange
            case .info: return .trainPrimary
            }
        }

        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .info: return "info.circle.fill"
            }
        }
    }

    private var allSetsCompleted: Bool {
        loggedExercise.sets.allSatisfy { $0.completed }
    }

    private var atLeastOneSetCompleted: Bool {
        loggedExercise.sets.contains { $0.completed }
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Header
                ExerciseLoggerHeader(
                    exerciseName: exercise.exerciseName,
                    exerciseNumber: exerciseIndex + 1,
                    totalExercises: totalExercises,
                    onBack: onCancel
                )

                // Tab toggle - matches CombinedLibraryView toolbar style
                HStack(spacing: 4) {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = .logger
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "list.bullet.clipboard")
                                .font(.system(size: 14))
                                .foregroundColor(selectedTab == .logger ? .trainPrimary : .trainTextSecondary)
                            Text("Logger")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(selectedTab == .logger ? .trainTextPrimary : .trainTextSecondary)
                        }
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, 10)
                        .background(selectedTab == .logger ? Color.trainPrimary.opacity(0.15) : Color.clear)
                        .clipShape(Capsule())
                    }

                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = .demo
                            loadExerciseDetails()
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(selectedTab == .demo ? .trainPrimary : .trainTextSecondary)
                            Text("Demo")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(selectedTab == .demo ? .trainTextPrimary : .trainTextSecondary)
                        }
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, 10)
                        .background(selectedTab == .demo ? Color.trainPrimary.opacity(0.15) : Color.clear)
                        .clipShape(Capsule())
                    }
                }
                .padding(4)
                .background(Color.white.opacity(0.08))
                .clipShape(Capsule())
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.md)

                // Content
                if selectedTab == .logger {
                    ScrollView {
                        VStack(spacing: Spacing.lg) {
                            // Exercise info
                            ExerciseLoggerInfoCard(exercise: exercise)
                                .padding(.horizontal, Spacing.lg)
                                .padding(.top, Spacing.md)

                            // Set logging
                            SetLoggingSection(
                                exercise: exercise,
                                loggedExercise: $loggedExercise,
                                weightUnit: $weightUnit,
                                showRestTimer: $showRestTimer,
                                activeSetIndex: $activeSetIndex
                            )
                            .padding(.horizontal, Spacing.lg)

                            Spacer().frame(height: 100)
                        }
                    }
                } else {
                    // Demo view
                    if let dbExercise = selectedDBExercise {
                        ExerciseDemoTab(exercise: dbExercise)
                    } else {
                        VStack {
                            ProgressView("Loading exercise...")
                                .foregroundColor(.trainTextPrimary)
                        }
                        .frame(maxHeight: .infinity)
                    }
                }

                // Submit Exercise button
                VStack {
                    Button(action: submitExercise) {
                        Text("Submit Exercise")
                            .font(.trainBodyMedium)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: ButtonHeight.standard)
                            .background(atLeastOneSetCompleted ? Color.trainPrimary : Color.trainDisabled)
                            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous))
                    }
                    .disabled(!atLeastOneSetCompleted)
                    .padding(Spacing.lg)
                }
            }

            // Rest timer overlay
            if showRestTimer {
                RestTimerOverlay(
                    totalSeconds: exercise.restSeconds,
                    onDismiss: {
                        showRestTimer = false
                        activeSetIndex = nil
                    }
                )
            }

            // Feedback notification (central modal overlay)
            if showFeedbackNotification {
                FeedbackModalOverlay(
                    title: feedbackTitle,
                    message: feedbackMessage,
                    type: feedbackType,
                    onPrimaryAction: {
                        withAnimation {
                            showFeedbackNotification = false
                        }
                        onComplete(loggedExercise)
                    },
                    onSecondaryAction: {
                        withAnimation {
                            showFeedbackNotification = false
                        }
                        // Stay on page to edit
                    }
                )
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.2), value: showFeedbackNotification)
            }
        }
        .warmDarkGradientBackground()
        .navigationBarBackButtonHidden(true)
    }

    private func loadExerciseDetails() {
        guard let id = Int(exercise.exerciseId) else { return }

        Task {
            do {
                let dbExercise = try ExerciseDatabaseManager.shared.fetchExercise(byId: id)
                if let dbExercise = dbExercise {
                    await MainActor.run {
                        selectedDBExercise = dbExercise
                    }
                }
            } catch {
                print("❌ Error loading exercise details: \(error)")
            }
        }
    }

    private func submitExercise() {
        // Evaluate performance and show feedback
        let completedSets = loggedExercise.sets.filter { $0.completed }
        let totalReps = completedSets.reduce(0) { $0 + $1.reps }

        // Parse target reps
        let repComponents = exercise.repRange.split(separator: "-").compactMap { Int($0) }
        let targetMin = repComponents.first ?? 8
        let targetMax = repComponents.last ?? 12
        let targetTotal = exercise.sets * targetMax

        // Generate feedback with title and message
        if totalReps >= targetTotal {
            feedbackTitle = "Great Work!"
            feedbackMessage = "You hit your target reps. Keep up the momentum!"
            feedbackType = .success
        } else if totalReps >= exercise.sets * targetMin {
            feedbackTitle = "Good Session"
            feedbackMessage = "You're within your target range. Solid effort!"
            feedbackType = .info
        } else {
            feedbackTitle = "Keep Pushing"
            feedbackMessage = "Try to increase reps next time. You've got this!"
            feedbackType = .warning
        }

        // Show modal overlay (user dismisses manually)
        withAnimation {
            showFeedbackNotification = true
        }
    }
}

// MARK: - Header

struct ExerciseLoggerHeader: View {
    let exerciseName: String
    let exerciseNumber: Int
    let totalExercises: Int
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: onBack) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Back")
                            .font(.trainBody)
                    }
                    .foregroundColor(.trainTextPrimary)
                }

                Spacer()

                Text("Exercise \(exerciseNumber)/\(totalExercises)")
                    .font(.trainCaption)
                    .foregroundColor(.trainTextSecondary)
            }
            .padding(Spacing.lg)

            // Progress bar
            ProgressView(value: Double(exerciseNumber), total: Double(totalExercises))
                .tint(Color.trainPrimary)
        }
        .appCard()
    }
}

// MARK: - Info Card

struct ExerciseLoggerInfoCard: View {
    let exercise: ProgramExercise

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(exercise.exerciseName)
                .font(.trainTitle2)
                .foregroundColor(.trainTextPrimary)

            HStack(spacing: Spacing.md) {
                // Equipment badge
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "dumbbell")
                        .font(.caption)
                    Text(exercise.equipmentType)
                        .font(.trainCaption)
                }
                .foregroundColor(.trainTextSecondary)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xs)
                .glassCompactCard(cornerRadius: CornerRadius.sm)
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
        .appCard()
    }
}

// MARK: - Set Logging Section

struct SetLoggingSection: View {
    let exercise: ProgramExercise
    @Binding var loggedExercise: LoggedExercise
    @Binding var weightUnit: ExerciseLoggerView.WeightUnit
    @Binding var showRestTimer: Bool
    @Binding var activeSetIndex: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Header with unit toggle
            HStack {
                Text("Log Sets")
                    .font(.trainHeadline)
                    .foregroundColor(.trainTextPrimary)

                Spacer()

                // Unit toggle
                HStack(spacing: 0) {
                    ForEach(ExerciseLoggerView.WeightUnit.allCases, id: \.self) { unit in
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
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.sm, style: .continuous)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
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
                    SetInputRow(
                        setNumber: setIndex + 1,
                        set: bindingForSet(setIndex),
                        weightUnit: weightUnit,
                        onComplete: {
                            if exercise.restSeconds > 0 {
                                activeSetIndex = setIndex
                                showRestTimer = true
                            }
                        }
                    )
                }
            }
        }
        .padding(Spacing.md)
        .appCard()
    }

    private func bindingForSet(_ index: Int) -> Binding<LoggedSet> {
        Binding(
            get: { loggedExercise.sets[index] },
            set: { loggedExercise.sets[index] = $0 }
        )
    }
}

// MARK: - Set Input Row

struct SetInputRow: View {
    let setNumber: Int
    @Binding var set: LoggedSet
    let weightUnit: ExerciseLoggerView.WeightUnit
    let onComplete: () -> Void

    @State private var repsText: String = ""
    @State private var weightText: String = ""

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Set number
            Text("\(setNumber)")
                .font(.trainBodyMedium)
                .fontWeight(.bold)
                .foregroundColor(.trainTextPrimary)
                .frame(width: 32)

            // Reps input
            TextField("0", text: $repsText)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .font(.trainBody)
                .foregroundColor(.trainTextPrimary)
                .padding(Spacing.sm)
                .frame(width: 60)
                .appCard()
                .cornerRadius(CornerRadius.sm)
                .onChange(of: repsText) { _, newValue in
                    if let reps = Int(newValue) {
                        set.reps = reps
                    }
                }

            // Weight input
            TextField("0", text: $weightText)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)
                .font(.trainBody)
                .foregroundColor(.trainTextPrimary)
                .padding(Spacing.sm)
                .frame(width: 80)
                .appCard()
                .cornerRadius(CornerRadius.sm)
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
        .onAppear {
            if set.reps > 0 { repsText = "\(set.reps)" }
            if set.weight > 0 {
                let displayWeight = weightUnit == .kg ? set.weight : set.weight * 2.20462
                weightText = String(format: "%.1f", displayWeight)
            }
        }
        .onChange(of: weightUnit) { _, newUnit in
            if set.weight > 0 {
                let displayWeight = newUnit == .kg ? set.weight : set.weight * 2.20462
                weightText = String(format: "%.1f", displayWeight)
            }
        }
    }

    private func toggleCompletion() {
        let wasCompleted = set.completed
        set.completed.toggle()

        if !wasCompleted && set.completed {
            onComplete()
        }
    }
}

// MARK: - Rest Timer Overlay

struct RestTimerOverlay: View {
    let totalSeconds: Int
    let onDismiss: () -> Void

    @State private var timeRemaining: Int
    @State private var timer: Timer?

    init(totalSeconds: Int, onDismiss: @escaping () -> Void) {
        self.totalSeconds = totalSeconds
        self.onDismiss = onDismiss
        _timeRemaining = State(initialValue: totalSeconds)
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()

            VStack(spacing: Spacing.xl) {
                Text("Rest")
                    .font(.trainHeadline)
                    .foregroundColor(.trainTextSecondary)

                Text(timeFormatted)
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundColor(.trainPrimary)
                    .monospacedDigit()

                // Progress ring
                ZStack {
                    Circle()
                        .stroke(Color.trainTextSecondary.opacity(0.2), lineWidth: 8)
                        .frame(width: 120, height: 120)

                    Circle()
                        .trim(from: 0, to: CGFloat(timeRemaining) / CGFloat(totalSeconds))
                        .stroke(Color.trainPrimary, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: timeRemaining)
                }

                Button(action: onDismiss) {
                    Text("Skip Rest")
                        .font(.trainBodyMedium)
                        .foregroundColor(.trainTextSecondary)
                }
            }
        }
        .onAppear { startTimer() }
        .onDisappear { timer?.invalidate() }
    }

    private var timeFormatted: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                timer?.invalidate()
                onDismiss()
            }
        }
    }
}

// MARK: - Feedback Modal Overlay (Central Popup Style with Liquid Glass)

struct FeedbackModalOverlay: View {
    let title: String
    let message: String
    let type: ExerciseLoggerView.FeedbackType
    let onPrimaryAction: () -> Void
    let onSecondaryAction: () -> Void

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0)
                .ignoresSafeArea()

            // Modal card with liquid glass effect
            VStack(spacing: Spacing.lg) {
                // Title
                Text(title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.trainTextPrimary)
                    .multilineTextAlignment(.center)

                // Message
                Text(message)
                    .font(.system(size: 16))
                    .foregroundColor(.trainTextSecondary)
                    .multilineTextAlignment(.center)

                // Buttons
                HStack(spacing: Spacing.md) {
                    // Secondary button (translucent)
                    Button(action: onSecondaryAction) {
                        Text("Edit")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.trainTextPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.white.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
                    }

                    // Primary button (accent color)
                    Button(action: onPrimaryAction) {
                        Text("Continue")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(type.color)
                            .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
                    }
                }
            }
            .padding(Spacing.xl)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.25), radius: 30, x: 0, y: 10)
            .padding(.horizontal, Spacing.xl)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ExerciseLoggerView(
            exercise: ProgramExercise(
                exerciseId: "1",
                exerciseName: "Bench Press",
                sets: 3,
                repRange: "8-12",
                restSeconds: 90,
                primaryMuscle: "Chest",
                equipmentType: "Barbell"
            ),
            exerciseIndex: 0,
            totalExercises: 5,
            weekNumber: 1,
            sessionIndex: 0,
            loggedExercise: .constant(LoggedExercise(
                exerciseName: "Bench Press",
                sets: [LoggedSet(), LoggedSet(), LoggedSet()],
                notes: ""
            )),
            onComplete: { _ in },
            onCancel: {}
        )
    }
}
