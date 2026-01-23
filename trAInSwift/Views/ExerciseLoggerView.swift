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
            VStack(spacing: 0) {
                // Header - new simplified design
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

                // Content
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
                            .padding(.top, Spacing.sm) // Add small top padding to prevent overlap
                    } else {
                        VStack {
                            ProgressView("Loading exercise...")
                                .foregroundColor(.trainTextPrimary)
                        }
                        .frame(maxHeight: .infinity)
                    }
                }

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
                            .foregroundColor(colorScheme == .dark ? .black : .white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(atLeastOneSetCompleted ? Color.trainPrimary : Color.trainDisabled)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .disabled(!atLeastOneSetCompleted)
                    .padding(.horizontal, 18)
                    .padding(.bottom, 20)
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
        .padding(.top, 12)
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
                    : Color(hex: "E2E3E4"))
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
                .background(Color.gray)
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
            // Inline rest timer (appears at top when active)
            InlineRestTimer(
                totalSeconds: restTimerController.restSeconds,
                isActive: $restTimerController.isActive
            )

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
                        .foregroundColor(Color(hex: "4DCA73"))
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

// MARK: - Exercise Demo Tab (Redesigned)

struct ExerciseDemoTab: View {
    let exercise: DBExercise
    @Environment(\.colorScheme) var colorScheme

    // Get the list of equipment items from the exercise
    private var equipmentItems: [String] {
        // Parse equipment from category and specific fields
        var items: [String] = []
        if !exercise.equipmentCategory.isEmpty {
            items.append(exercise.equipmentCategory)
        }
        if let specific = exercise.equipmentSpecific, !specific.isEmpty {
            // Split by comma if multiple items
            let specificItems = specific.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
            items.append(contentsOf: specificItems)
        }
        return items.isEmpty ? ["Equipment"] : items
    }

    // Get active muscle groups
    private var muscleGroups: [String] {
        var groups: [String] = [exercise.primaryMuscle]
        if let secondary = exercise.secondaryMuscle {
            groups.append(secondary)
        }
        return groups
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Exercise Info (same as Logger tab - centered, no container)
                VStack(spacing: 4) {
                    Text(exercise.displayName)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.trainTextPrimary)
                        .multilineTextAlignment(.center)

                    // Equipment tag
                    Text(exercise.equipmentCategory)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 6)
                        .background(Color.gray)
                        .clipShape(Capsule())
                        .padding(.top, 4)
                }
                .padding(.top, 20)

                // Video Player Card
                DemoVideoPlayerCard(exerciseId: exercise.exerciseId)
                    .padding(.horizontal, 18)
                    .padding(.top, 24)

                // Equipment Section - horizontal row of placeholder tiles
                DemoInfoSection(
                    title: "Equipment",
                    items: equipmentItems,
                    sectionType: .equipment
                )
                .padding(.top, 24)

                // Active Muscle Groups Section - with body diagrams
                DemoMuscleGroupsSection(
                    title: "Active Muscle Groups",
                    muscleGroups: muscleGroups
                )
                .padding(.top, 16)

                // Instructions Card
                DemoInstructionsCard(instructions: exercise.instructionSteps)
                    .padding(.horizontal, 18)
                    .padding(.top, 16)
                    .padding(.bottom, 100)
            }
        }
    }
}

// MARK: - Demo Video Player Card

struct DemoVideoPlayerCard: View {
    let exerciseId: String
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            // Use existing ExerciseMediaPlayer
            ExerciseMediaPlayer(exerciseId: exerciseId)
                .frame(height: 192)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(colorScheme == .dark ? Color.white.opacity(0.3) : Color.black, lineWidth: 1)
                )
        }
    }
}

// MARK: - Demo Info Section (Equipment)

enum DemoSectionType {
    case equipment
    case muscles
}

struct DemoInfoSection: View {
    let title: String
    let items: [String]
    let sectionType: DemoSectionType
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.trainTextPrimary)
                .padding(.horizontal, 50)

            HStack(spacing: 35) {
                ForEach(items.prefix(4), id: \.self) { item in
                    DemoPlaceholderTile(label: item, iconName: equipmentIcon(for: item))
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func equipmentIcon(for item: String) -> String {
        let lowercased = item.lowercased()
        if lowercased.contains("barbell") { return "figure.strengthtraining.traditional" }
        if lowercased.contains("dumbbell") { return "dumbbell.fill" }
        if lowercased.contains("cable") { return "cable.coaxial" }
        if lowercased.contains("machine") { return "gearshape.fill" }
        if lowercased.contains("bench") { return "bed.double.fill" }
        if lowercased.contains("plate") { return "circle.fill" }
        if lowercased.contains("bodyweight") { return "figure.stand" }
        return "photo"
    }
}

// MARK: - Demo Placeholder Tile

struct DemoPlaceholderTile: View {
    let label: String
    let iconName: String
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.white)
                    .frame(width: 70, height: 70)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .stroke(colorScheme == .dark ? Color.white.opacity(0.2) : Color.black.opacity(0.1), lineWidth: 1)
                    )

                Image(systemName: iconName)
                    .font(.system(size: 24))
                    .foregroundColor(.trainTextPrimary)
            }

            Text(label)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.trainTextSecondary)
                .lineLimit(1)
        }
    }
}

// MARK: - Demo Muscle Groups Section (with Body Diagrams)

struct DemoMuscleGroupsSection: View {
    let title: String
    let muscleGroups: [String]
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.trainTextPrimary)
                .padding(.horizontal, 50)

            HStack(spacing: Spacing.lg) {
                ForEach(muscleGroups.prefix(3), id: \.self) { muscleGroup in
                    VStack(spacing: Spacing.sm) {
                        StaticMuscleView(
                            muscleGroup: muscleGroup,
                            gender: .male,  // Default to male, could be made configurable
                            size: 90,
                            useUniformBaseColor: true
                        )
                        .frame(width: 90, height: 90)

                        Text(muscleGroup)
                            .font(.trainCaption)
                            .foregroundColor(.trainTextSecondary)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Demo Instructions Card

struct DemoInstructionsCard: View {
    let instructions: [String]
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Instructions")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.trainTextPrimary)

            if instructions.isEmpty {
                Text("Instructions coming soon")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.trainTextSecondary)
                    .opacity(0.8)
                    .padding(.top, 4)
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(Array(instructions.enumerated()), id: \.offset) { index, instruction in
                        HStack(alignment: .top, spacing: 8) {
                            Text("\(index + 1).")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.trainTextPrimary)
                                .opacity(0.8)
                            Text(cleanStepText(instruction))
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.trainTextPrimary)
                                .opacity(0.8)
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(colorScheme == .dark ? Color.white.opacity(0.3) : Color.black, lineWidth: 1)
        )
    }

    // Clean up step text by removing "Step X:" prefix
    private func cleanStepText(_ step: String) -> String {
        let pattern = "^Step\\s*\\d+\\s*:\\s*"
        if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
            let range = NSRange(step.startIndex..., in: step)
            return regex.stringByReplacingMatches(in: step, options: [], range: range, withTemplate: "")
        }
        return step
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
