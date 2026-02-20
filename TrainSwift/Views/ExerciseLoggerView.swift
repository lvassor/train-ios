//
//  ExerciseLoggerView.swift
//  TrainSwift
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
    @Environment(\.colorScheme) var colorScheme

    let exercise: ProgramExercise
    let exerciseIndex: Int
    let totalExercises: Int
    let weekNumber: Int
    let sessionIndex: Int
    let sessionName: String  // e.g., "Full Body", "Push", "Pull", "Legs"
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
            // Background gradient
            AppGradient.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header - new simplified design (respects top safe area)
                ExerciseLoggerHeader(
                    sessionName: sessionName,
                    exerciseNumber: exerciseIndex + 1,
                    totalExercises: totalExercises,
                    onBack: onCancel
                )

                // Tab selector - full width with custom styling
                LoggerTabSelector(selectedTab: $selectedTab)
                    .padding(.top, Spacing.md)
                    .onChange(of: selectedTab) { _, newTab in
                        if newTab == .demo || newTab == .history {
                            loadExerciseDetails()
                        }
                    }

                // Inline rest timer - persists across tab switches
                InlineRestTimer(
                    totalSeconds: restTimerController.restSeconds,
                    isActive: $restTimerController.isActive
                )
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.sm)

                // Content - fills remaining space
                Group {
                    if selectedTab == .logger {
                        ScrollView {
                            VStack(spacing: Spacing.lg) {
                                // Exercise info - centered text layout (no container)
                                ExerciseLoggerInfoSection(exercise: exercise)
                                    .padding(.top, Spacing.lg)

                                // Set logging - redesigned with warm-up suggestion
                                SetLoggingCard(
                                    exercise: exercise,
                                    loggedExercise: $loggedExercise,
                                    weightUnit: $weightUnit,
                                    restTimerController: restTimerController,
                                    liveActivityManager: liveActivityManager,
                                    onSetCompleted: updateLiveActivityProgress
                                )
                                .padding(.horizontal, Spacing.lg)

                                Spacer().frame(height: 120)
                            }
                        }
                        .scrollDismissesKeyboard(.interactively)
                    } else if selectedTab == .demo {
                        // Demo view - no overlapping title
                        if let dbExercise = selectedDBExercise {
                            ExerciseDemoTab(exercise: dbExercise)
                        } else {
                            VStack {
                                ProgressView("Loading exercise...")
                                    .foregroundColor(.trainTextPrimary)
                            }
                            .frame(maxHeight: .infinity)
                        }
                    } else if selectedTab == .history {
                        // History view - no overlapping title, ensure proper layout
                        if let dbExercise = selectedDBExercise {
                            ExerciseHistoryView(exercise: dbExercise)
                                .padding(.top, Spacing.sm)
                        } else {
                            VStack {
                                ProgressView("Loading exercise...")
                                    .foregroundColor(.trainTextPrimary)
                            }
                            .frame(maxHeight: .infinity)
                        }
                    }
                }
                .frame(maxHeight: .infinity)
            }
            .safeAreaInset(edge: .bottom) {
                // Complete Exercise button with gradient fade behind
                ZStack(alignment: .bottom) {
                    // Gradient fade for scrollable content
                    LinearGradient(
                        colors: [.clear, Color.trainGradientMid.opacity(0.8), Color.trainGradientMid],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 100)
                    .allowsHitTesting(false)

                    Button(action: submitExercise) {
                        Text("Complete Exercise")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(atLeastOneSetCompleted ? Color.trainPrimary : Color.trainDisabled)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .disabled(!atLeastOneSetCompleted)
                    .padding(.horizontal, 18)
                    .padding(.bottom, Spacing.md)
                }
            }
            .toolbar(.hidden, for: .tabBar)

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
                AppLogger.logUI("Error loading exercise details: \(error)", level: .error)
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

// MARK: - Header (Redesigned)

struct ExerciseLoggerHeader: View {
    let sessionName: String  // e.g., "Full Body", "Push", "Pull"
    let exerciseNumber: Int
    let totalExercises: Int
    let onBack: () -> Void

    var body: some View {
        HStack {
            // Back button (just chevron)
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.trainTextPrimary)
            }

            Spacer()

            // Session name centered
            Text(sessionName)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.trainTextPrimary)

            Spacer()

            // Exercise counter (e.g., "1/5")
            Text("\(exerciseNumber)/\(totalExercises)")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.trainTextPrimary)
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
    }
}

// MARK: - Tab Selector (Full Width with Custom Styling)

struct LoggerTabSelector: View {
    @Binding var selectedTab: LoggerTabOption
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            // Background pill
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(colorScheme == .dark
                    ? Color.white.opacity(0.1)
                    : Color.trainTabBackground)
                .frame(height: 40)

            HStack(spacing: 0) {
                ForEach(LoggerTabOption.allCases, id: \.self) { tab in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = tab
                        }
                    }) {
                        Text(tab.rawValue)
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.trainTextPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .background(
                                selectedTab == tab ?
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(colorScheme == .dark
                                            ? Color.white.opacity(0.15)
                                            : Color.white)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                .stroke(colorScheme == .dark
                                                    ? Color.white.opacity(0.3)
                                                    : Color.black.opacity(0.47), lineWidth: 1)
                                        )
                                : nil
                            )
                    }
                }
            }
        }
        .frame(height: 40)
        .padding(.horizontal, 18)
    }
}

// MARK: - Exercise Info Section (Centered, No Container)

struct ExerciseLoggerInfoSection: View {
    let exercise: ProgramExercise
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 4) {
            // Exercise name
            Text(exercise.exerciseName)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.trainTextPrimary)
                .multilineTextAlignment(.center)

            // Target sets and reps
            Text("Target: \(exercise.sets) sets • \(exercise.repRange) reps")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.trainTextPrimary)

            // Equipment tag
            Text(exercise.equipmentType)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 6)
                .background(Color.trainTag)
                .clipShape(Capsule())
                .padding(.top, 4)
        }
    }
}

// MARK: - Legacy Info Card (kept for backward compatibility)

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

// MARK: - Set Logging Card (Redesigned with Warm-up Suggestion)

struct SetLoggingCard: View {
    let exercise: ProgramExercise
    @Binding var loggedExercise: LoggedExercise
    @Binding var weightUnit: ExerciseLoggerView.WeightUnit
    @ObservedObject var restTimerController: RestTimerController
    @ObservedObject var liveActivityManager: WorkoutLiveActivityManager
    let onSetCompleted: () -> Void
    @Environment(\.colorScheme) var colorScheme

    // Calculate progressive overload rep difference
    private var totalRepsDifference: Int? {
        let completedSets = loggedExercise.sets.filter { $0.completed && $0.reps > 0 }
        guard !completedSets.isEmpty else { return nil }
        // This would compare to previous session - for now show if any reps logged
        let totalReps = completedSets.reduce(0) { $0 + $1.reps }
        return totalReps > 0 ? totalReps : nil
    }

    // Calculate suggested warm-up weight (50-70% of expected working weight)
    private var suggestedWarmupWeight: Double {
        // Use first set's weight if available, otherwise estimate
        if let firstSetWeight = loggedExercise.sets.first?.weight, firstSetWeight > 0 {
            return firstSetWeight * 0.6  // 60% of working weight
        }
        return 20.0  // Default placeholder
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Warm-up suggestion header with rep counter
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Suggested warm-up set")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.trainTextSecondary)
                        .opacity(0.8)
                    Text("\(Int(suggestedWarmupWeight)) \(weightUnit.rawValue) (50-70%) • 10 reps")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.trainTextPrimary)
                        .opacity(0.8)
                }

                Spacer()

                // Progressive overload indicator (green +X)
                if let diff = totalRepsDifference, diff > 0 {
                    Text("+ \(diff)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Color.trainSuccess)
                }
            }
            .padding(.bottom, 8)

            // Set rows (no headers - simplified design)
            ForEach(0..<loggedExercise.sets.count, id: \.self) { setIndex in
                SimplifiedSetRow(
                    setNumber: setIndex + 1,
                    set: bindingForSet(setIndex),
                    weightUnit: weightUnit,
                    onComplete: {
                        if exercise.restSeconds > 0 {
                            restTimerController.triggerRest(seconds: exercise.restSeconds)
                            if #available(iOS 16.1, *) {
                                liveActivityManager.startRestTimer(seconds: exercise.restSeconds, elapsedTime: 0)
                            }
                        }
                        onSetCompleted()
                    }
                )
            }

            // Add Set button (dashed border)
            Button(action: addSet) {
                Text("Add Set")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.trainTextPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .frame(height: 40)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(style: StrokeStyle(lineWidth: 1, dash: [5]))
                            .foregroundColor(colorScheme == .dark ? .white.opacity(0.5) : .black)
                    )
            }
        }
        .padding(24)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(colorScheme == .dark ? Color.white.opacity(0.3) : Color.black, lineWidth: 1)
        )
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: restTimerController.isActive)
    }

    private func bindingForSet(_ index: Int) -> Binding<LoggedSet> {
        Binding(
            get: { loggedExercise.sets[index] },
            set: { loggedExercise.sets[index] = $0 }
        )
    }

    private func addSet() {
        loggedExercise.sets.append(LoggedSet())
    }
}

// MARK: - Simplified Set Row (No Headers)

struct SimplifiedSetRow: View {
    let setNumber: Int
    @Binding var set: LoggedSet
    let weightUnit: ExerciseLoggerView.WeightUnit
    let onComplete: () -> Void
    @Environment(\.colorScheme) var colorScheme

    @State private var repsText: String = ""
    @State private var weightText: String = ""
    @FocusState private var isRepsFieldFocused: Bool
    @FocusState private var isWeightFieldFocused: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Set number
            Text("\(setNumber)")
                .font(.system(size: 20, weight: .regular))
                .foregroundColor(.trainTextPrimary)
                .frame(width: 20)

            // Weight input
            TextField(weightUnit.rawValue, text: $weightText)
                .keyboardType(.decimalPad)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(weightText.isEmpty ? .trainTextSecondary.opacity(0.4) : .trainTextPrimary)
                .multilineTextAlignment(.center)
                .frame(width: 98, height: 35)
                .focused($isWeightFieldFocused)
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(colorScheme == .dark ? Color.white.opacity(0.5) : Color.black, lineWidth: 1)
                )
                .onChange(of: weightText) { _, newValue in
                    if let weight = Double(newValue) {
                        set.weight = weightUnit == .kg ? weight : weight / 2.20462
                    }
                }

            // Reps input
            TextField("reps", text: $repsText)
                .keyboardType(.numberPad)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(repsText.isEmpty ? .trainTextSecondary.opacity(0.4) : .trainTextPrimary)
                .multilineTextAlignment(.center)
                .frame(width: 98, height: 35)
                .focused($isRepsFieldFocused)
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(colorScheme == .dark ? Color.white.opacity(0.5) : Color.black, lineWidth: 1)
                )
                .onChange(of: repsText) { _, newValue in
                    if let reps = Int(newValue) {
                        set.reps = reps
                    }
                }

            Spacer()

            // Checkmark circle
            Button(action: toggleCompletion) {
                Circle()
                    .fill(set.completed ? Color.trainPrimary : Color.gray.opacity(0.4))
                    .frame(width: 30, height: 30)
                    .overlay(
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                    )
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
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button {
                    isWeightFieldFocused = false
                    isRepsFieldFocused = false
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.trainTextPrimary)
                }
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

// MARK: - Legacy Set Logging Section (kept for backward compatibility)

struct SetLoggingSection: View {
    let exercise: ProgramExercise
    @Binding var loggedExercise: LoggedExercise
    @Binding var weightUnit: ExerciseLoggerView.WeightUnit
    @ObservedObject var restTimerController: RestTimerController
    @ObservedObject var liveActivityManager: WorkoutLiveActivityManager
    let onSetCompleted: () -> Void

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
                                restTimerController.triggerRest(seconds: exercise.restSeconds)
                                // Update Live Activity with rest timer
                                if #available(iOS 16.1, *) {
                                    liveActivityManager.startRestTimer(seconds: exercise.restSeconds, elapsedTime: 0)
                                }
                            }
                            onSetCompleted()
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
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button {
                    isWeightFieldFocused = false
                    isRepsFieldFocused = false
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.trainTextPrimary)
                }
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

// Components extracted to:
// - Components/InlineRestTimer.swift (InlineRestTimer, RestTimerController)
// - Views/ExerciseLoggerFeedback.swift (FeedbackModalOverlay)
// - Views/ExerciseLoggerDemoView.swift (ExerciseDemoTab, DemoVideoPlayerCard, DemoInfoSection, etc.)

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
            sessionName: "Full Body",
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
