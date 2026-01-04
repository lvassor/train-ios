//
//  ExerciseLoggerView.swift
//  trAInSwift
//
//  Individual exercise logging view with set tracking
//  Shows demo video tab and Submit Exercise button
//

import SwiftUI
import Combine
import ActivityKit

// MARK: - Logger Tab Options

enum LoggerTabOption: String, CaseIterable, Hashable {
    case logger = "Logger"
    case demo = "Demo"
    case history = "History"

    var icon: String {
        switch self {
        case .logger: return "list.bullet.clipboard"
        case .demo: return "play.circle.fill"
        case .history: return "chart.xyaxis.line"
        }
    }
}

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

    @State private var selectedTab: LoggerTabOption = .logger
    @State private var weightUnit: WeightUnit = .kg
    @State private var selectedDBExercise: DBExercise?
    @State private var showFeedbackNotification = false
    @State private var feedbackTitle: String = ""
    @State private var feedbackMessage: String = ""
    @State private var feedbackType: FeedbackType = .success
    @StateObject private var restTimerController = RestTimerController()

    // Live Activity Manager
    @ObservedObject private var liveActivityManager = WorkoutLiveActivityManager.shared

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

                // Tab toggle with native segmented picker
                Picker("View", selection: $selectedTab) {
                    ForEach(LoggerTabOption.allCases, id: \.self) { tab in
                        Label(tab.rawValue, systemImage: tab.icon)
                            .tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 280)
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.md)
                .onChange(of: selectedTab) { _, newTab in
                    if newTab == .demo || newTab == .history {
                        loadExerciseDetails()
                    }
                }

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
                                restTimerController: restTimerController
                            )
                            .padding(.horizontal, Spacing.lg)

                            Spacer().frame(height: 100)
                        }
                    }
                    .scrollDismissesKeyboard(.interactively)
                } else if selectedTab == .demo {
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
                } else {
                    // History view
                    if let dbExercise = selectedDBExercise {
                        ExerciseHistoryView(exercise: dbExercise)
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
        .charcoalGradientBackground()
        .navigationBarBackButtonHidden(true)
    }

    private func loadExerciseDetails() {
        Task {
            do {
                let dbExercise = try ExerciseDatabaseManager.shared.fetchExercise(byId: exercise.exerciseId)
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
        let averageRepsPerSet = completedSets.isEmpty ? 0 : totalReps / completedSets.count

        // Generate feedback with progressive overload suggestions
        if totalReps >= targetTotal {
            // Hit max reps - suggest weight increase
            feedbackTitle = "Time to Progress!"
            feedbackMessage = "You've hit \(targetMax) reps consistently. Consider increasing the weight by 2.5-5kg next session."
            feedbackType = .success
        } else if averageRepsPerSet >= targetMax {
            // Averaging at top of range
            feedbackTitle = "Strong Performance!"
            feedbackMessage = "You're ready to increase the weight. Add 2.5kg and aim for \(targetMin) reps."
            feedbackType = .success
        } else if totalReps >= exercise.sets * targetMin {
            // Within target range - stay the course
            feedbackTitle = "On Track"
            feedbackMessage = "Keep this weight until you can hit \(targetMax) reps on all sets, then increase."
            feedbackType = .info
        } else {
            // Below target - maintain or slightly reduce
            feedbackTitle = "Building Strength"
            feedbackMessage = "Focus on hitting \(targetMin)-\(targetMax) reps before increasing weight. You've got this!"
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
    @ObservedObject var restTimerController: RestTimerController

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Inline rest timer (appears at top when active)
            InlineRestTimer(
                totalSeconds: restTimerController.restSeconds,
                isActive: $restTimerController.isActive
            )

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
                                restTimerController.triggerRest(seconds: exercise.restSeconds)
                                // Update Live Activity with rest timer
                                if #available(iOS 16.1, *) {
                                    liveActivityManager.startRestTimer(seconds: exercise.restSeconds, elapsedTime: 0)
                                }
                            }
                            updateLiveActivityProgress()
                        }
                    )
                }
            }
        }
        .padding(Spacing.md)
        .appCard()
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: restTimerController.isActive)
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
    var previousSessionReps: Int? = nil  // For progressive overload comparison
    var previousSessionWeight: Double? = nil

    @State private var repsText: String = ""
    @State private var weightText: String = ""
    @FocusState private var isRepsFieldFocused: Bool
    @FocusState private var isWeightFieldFocused: Bool

    // Calculate rep difference from previous session
    private var repsDifference: Int? {
        guard let prevReps = previousSessionReps, set.reps > 0 else { return nil }
        let diff = set.reps - prevReps
        return diff != 0 ? diff : nil
    }

    // Check if weight increased
    private var weightIncreased: Bool {
        guard let prevWeight = previousSessionWeight, set.weight > 0 else { return false }
        return set.weight > prevWeight
    }

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Set number
            Text("\(setNumber)")
                .font(.trainBodyMedium)
                .fontWeight(.bold)
                .foregroundColor(.trainTextPrimary)
                .frame(width: 32)

            // Reps input with progressive overload indicator
            ZStack(alignment: .trailing) {
                TextField("0", text: $repsText)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .font(.trainBody)
                    .foregroundColor(.trainTextPrimary)
                    .padding(Spacing.sm)
                    .frame(width: 60)
                    .appCard()
                    .cornerRadius(CornerRadius.sm)
                    .focused($isRepsFieldFocused)
                    .onChange(of: repsText) { _, newValue in
                        if let reps = Int(newValue) {
                            set.reps = reps
                        }
                    }

                // Progressive overload indicator (green +X)
                if let diff = repsDifference, diff > 0 {
                    Text("+\(diff)")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.green)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.15))
                        .clipShape(Capsule())
                        .offset(x: 20, y: -12)
                }
            }

            // Weight input with increase indicator
            ZStack(alignment: .trailing) {
                TextField("0", text: $weightText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .font(.trainBody)
                    .foregroundColor(.trainTextPrimary)
                    .padding(Spacing.sm)
                    .frame(width: 80)
                    .appCard()
                    .cornerRadius(CornerRadius.sm)
                    .focused($isWeightFieldFocused)
                    .onChange(of: weightText) { _, newValue in
                        if let weight = Double(newValue) {
                            set.weight = weightUnit == .kg ? weight : weight / 2.20462
                        }
                    }

                // Weight increase indicator
                if weightIncreased {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.green)
                        .offset(x: 20, y: -12)
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
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    isRepsFieldFocused = false
                    isWeightFieldFocused = false
                }
                .foregroundColor(.trainPrimary)
            }
        }
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

// MARK: - Inline Rest Timer (Non-blocking)

struct InlineRestTimer: View {
    let totalSeconds: Int
    @Binding var isActive: Bool

    @State private var timeRemaining: Int = 0
    @State private var timer: Timer?

    var body: some View {
        if isActive {
            HStack(spacing: Spacing.md) {
                // Circular progress indicator
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 3)
                        .frame(width: 28, height: 28)

                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(Color.white, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .frame(width: 28, height: 28)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.5), value: timeRemaining)
                }

                // Time remaining
                Text(timeFormatted)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .monospacedDigit()

                Text("Rest")
                    .font(.trainCaption)
                    .foregroundColor(.white.opacity(0.7))

                Spacer()

                // Dismiss button
                Button(action: dismissTimer) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))
                        .frame(width: 24, height: 24)
                        .background(Color.white.opacity(0.15))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(Color.trainPrimary.opacity(0.9))
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm, style: .continuous))
            .transition(.asymmetric(
                insertion: .scale(scale: 0.8).combined(with: .opacity),
                removal: .scale(scale: 0.8).combined(with: .opacity)
            ))
            .onAppear { startTimer() }
            .onDisappear { stopTimer() }
            .onChange(of: isActive) { _, newValue in
                if newValue {
                    resetAndStartTimer()
                } else {
                    stopTimer()
                }
            }
        }
    }

    private var progress: CGFloat {
        guard totalSeconds > 0 else { return 0 }
        return CGFloat(timeRemaining) / CGFloat(totalSeconds)
    }

    private var timeFormatted: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private func startTimer() {
        timeRemaining = totalSeconds
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                withAnimation(.easeOut(duration: 0.3)) {
                    isActive = false
                }
                stopTimer()
            }
        }
    }

    private func resetAndStartTimer() {
        stopTimer()
        startTimer()
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func dismissTimer() {
        withAnimation(.easeOut(duration: 0.3)) {
            isActive = false
        }
        stopTimer()
    }
}

// MARK: - Rest Timer Controller (manages timer state and reset logic)

class RestTimerController: ObservableObject {
    @Published var isActive: Bool = false
    @Published var restSeconds: Int = 0

    func triggerRest(seconds: Int) {
        restSeconds = seconds
        // If timer is already active, this will cause it to reset via onChange
        if isActive {
            // Briefly deactivate to trigger reset
            isActive = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                self.isActive = true
            }
        } else {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isActive = true
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

// MARK: - Exercise Demo Tab

struct ExerciseDemoTab: View {
    let exercise: DBExercise

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                // Exercise title
                Text(exercise.displayName)
                    .font(.trainTitle2)
                    .foregroundColor(.trainTextPrimary)
                    .padding(.horizontal, Spacing.lg)
                    .padding(.top, Spacing.md)

                // Video/Image Demo Player
                ExerciseMediaPlayer(exerciseId: exercise.exerciseId)
                    .padding(.horizontal, Spacing.lg)

                // Muscles & Equipment cards (side by side)
                HStack(alignment: .top, spacing: Spacing.sm) {
                    // Muscles card (left)
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Muscles")
                            .font(.trainHeadline)
                            .foregroundColor(.trainTextPrimary)

                        HStack(spacing: Spacing.xs) {
                            // Primary muscle
                            Text(exercise.primaryMuscle)
                                .font(.trainCaption)
                                .foregroundColor(.trainPrimary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.trainPrimary.opacity(0.1))
                                .clipShape(Capsule())

                            // Secondary muscle (if any)
                            if let secondary = exercise.secondaryMuscle {
                                Text(secondary)
                                    .font(.trainCaption)
                                    .foregroundColor(.trainTextSecondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.trainTextSecondary.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(Spacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .appCard()

                    // Equipment card (right)
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Equipment")
                            .font(.trainHeadline)
                            .foregroundColor(.trainTextPrimary)

                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "dumbbell")
                                .font(.caption)
                            Text(exercise.equipmentCategory)
                                .font(.trainCaption)
                        }
                        .foregroundColor(.trainTextSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.trainTextSecondary.opacity(0.1))
                        .clipShape(Capsule())
                    }
                    .padding(Spacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .appCard()
                }
                .padding(.horizontal, Spacing.lg)

                // Instructions
                if let instructions = exercise.instructions, !instructions.isEmpty {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Text("How to Perform")
                            .font(.trainHeadline)
                            .foregroundColor(.trainTextPrimary)

                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            ForEach(Array(exercise.instructionSteps.enumerated()), id: \.offset) { index, step in
                                HStack(alignment: .top, spacing: Spacing.md) {
                                    // Step number circle
                                    Text("\(index + 1)")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(width: 24, height: 24)
                                        .background(Color.trainPrimary)
                                        .clipShape(Circle())

                                    // Instruction text - remove "Step X:" prefix if present
                                    let cleanedStep = cleanStepText(step)
                                    Text(cleanedStep)
                                        .font(.trainBody)
                                        .foregroundColor(.trainTextSecondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    }
                    .padding(Spacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .appCard()
                    .padding(.horizontal, Spacing.lg)
                } else {
                    // Placeholder when no instructions
                    VStack(spacing: Spacing.md) {
                        Image(systemName: "text.justify.leading")
                            .font(.system(size: 32))
                            .foregroundColor(.trainTextSecondary.opacity(0.5))

                        Text("Instructions coming soon")
                            .font(.trainBody)
                            .foregroundColor(.trainTextSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(Spacing.xl)
                    .appCard()
                    .padding(.horizontal, Spacing.lg)
                }

                // Complexity indicator
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Exercise Complexity")
                        .font(.trainHeadline)
                        .foregroundColor(.trainTextPrimary)

                    HStack(spacing: Spacing.xs) {
                        ForEach(1...4, id: \.self) { level in
                            Circle()
                                .fill(level <= exercise.complexityLevel ? Color.trainPrimary : Color.trainTextSecondary.opacity(0.3))
                                .frame(width: 12, height: 12)
                        }

                        Text(complexityLabel)
                            .font(.trainCaption)
                            .foregroundColor(.trainTextSecondary)
                            .padding(.leading, Spacing.sm)
                    }
                }
                .padding(Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .appCard()
                .padding(.horizontal, Spacing.lg)

                Spacer().frame(height: 100)
            }
        }
        .edgeFadeMask(topFade: 12, bottomFade: 50)
    }

    private var complexityLabel: String {
        switch exercise.complexityLevel {
        case 1: return "Beginner Friendly"
        case 2: return "Some Experience"
        case 3: return "Intermediate"
        case 4: return "Advanced"
        default: return "Standard"
        }
    }

    // Clean up step text by removing "Step X:" prefix
    private func cleanStepText(_ step: String) -> String {
        // Remove "Step 1:", "Step 2:", etc. prefixes
        let pattern = "^Step\\s*\\d+\\s*:\\s*"
        if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
            let range = NSRange(step.startIndex..., in: step)
            return regex.stringByReplacingMatches(in: step, options: [], range: range, withTemplate: "")
        }
        return step
    }

    private func updateLiveActivityProgress() {
        guard #available(iOS 16.1, *) else { return }

        let completedSetsCount = loggedExercise.sets.filter { $0.completed }.count
        let currentSet = min(completedSetsCount + 1, loggedExercise.sets.count)

        liveActivityManager.updateWorkoutProgress(
            currentExercise: loggedExercise,
            currentSet: currentSet,
            elapsedTime: 0, // Will be managed by the main workout view
            isResting: false
        )
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
