//
//  ExerciseDetailView.swift
//  trAInSwift
//
//  Enhanced exercise detail with Logger/Demo/History tabs
//

import SwiftUI
import Charts

struct ExerciseDetailView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var themeManager: ThemeManager

    let exercise: DBExercise
    let workoutName: String?
    let exerciseIndex: Int?
    let totalExercises: Int?
    let showLoggerTab: Bool

    @State private var selectedTab: ExerciseTab = .logger

    enum ExerciseTab: String, CaseIterable {
        case logger = "Logger"
        case demo = "Demo"
        case history = "History"
    }

    init(exercise: DBExercise,
         workoutName: String? = nil,
         exerciseIndex: Int? = nil,
         totalExercises: Int? = nil,
         showLoggerTab: Bool = true) {
        self.exercise = exercise
        self.workoutName = workoutName
        self.exerciseIndex = exerciseIndex
        self.totalExercises = totalExercises
        self.showLoggerTab = showLoggerTab
        _selectedTab = State(initialValue: showLoggerTab ? .logger : .demo)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Navigation Header
            if let workoutName = workoutName,
               let exerciseIndex = exerciseIndex,
               let totalExercises = totalExercises {
                ExerciseDetailHeader(
                    workoutName: workoutName,
                    exerciseIndex: exerciseIndex,
                    totalExercises: totalExercises,
                    onBack: { dismiss() }
                )
            }

            // Tab Selector
            HStack(spacing: 0) {
                ForEach(ExerciseTab.allCases, id: \.self) { tab in
                    Button {
                        selectedTab = tab
                    } label: {
                        Text(tab.rawValue)
                            .font(.system(size: 15, weight: .medium))
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(
                                Capsule()
                                    .fill(selectedTab == tab ? Color(.systemGray5) : Color.clear)
                            )
                    }
                    .foregroundColor(.primary)
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.md)

            // Exercise Info Header (Shared)
            ExerciseInfoHeader(exercise: exercise)
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.md)

            // Tab Content
            switch selectedTab {
            case .logger:
                ExerciseLoggerTabView(exercise: exercise)
            case .demo:
                ExerciseDemoTabView(exercise: exercise)
            case .history:
                ExerciseHistoryTabView(exercise: exercise)
            }
        }
        .background {
            if showLoggerTab {
                // Workout context - use gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        .trainGradientLight,
                        .trainGradientMid,
                        .trainGradientDark
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            } else {
                // Library context - use material
                Color(.systemBackground)
                    .ignoresSafeArea()
            }
        }
        .navigationBarHidden(workoutName != nil)
    }
}

// MARK: - Navigation Header

struct ExerciseDetailHeader: View {
    let workoutName: String
    let exerciseIndex: Int
    let totalExercises: Int
    let onBack: () -> Void

    var body: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.trainTextPrimary)
            }

            Spacer()

            Text(workoutName)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.trainTextPrimary)

            Spacer()

            Text("\(exerciseIndex)/\(totalExercises)")
                .font(.system(size: 15))
                .foregroundColor(.trainTextSecondary)
        }
        .padding(Spacing.lg)
        .appCard()
    }
}

// MARK: - Exercise Info Header

struct ExerciseInfoHeader: View {
    let exercise: DBExercise

    private var targetSets: String {
        "3 sets" // Default, could be made configurable
    }

    private var targetReps: String {
        "8-12 reps" // Default, could be made configurable
    }

    var body: some View {
        VStack(spacing: 8) {
            Text(exercise.displayName)
                .font(.system(size: 22, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundColor(.trainTextPrimary)

            Text("Target: \(targetSets) • \(targetReps)")
                .font(.system(size: 15))
                .foregroundColor(.trainTextSecondary)

            Text(exercise.equipmentCategory)
                .font(.system(size: 14, weight: .medium))
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(Color.trainPrimary)
                .foregroundColor(.white)
                .clipShape(Capsule())
        }
    }
}

// MARK: - Logger Tab

struct ExerciseLoggerTabView: View {
    let exercise: DBExercise
    @State private var sets: [SetEntry] = []
    @State private var warmUpSuggestion: WarmUpSuggestion?

    struct SetEntry: Identifiable {
        let id = UUID()
        let setNumber: Int
        var weight: Int?
        var reps: Int?
        var isCompleted: Bool = false
    }

    struct WarmUpSuggestion {
        let percentageRange: String = "50-70%"
        let suggestedWeight: Int
        let suggestedReps: Int = 10
        let weightIncrease: Int?
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Warm-up Suggestion
                if let warmUp = warmUpSuggestion {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Suggested warm-up set")
                                .font(.system(size: 14))
                                .foregroundColor(.trainTextSecondary)
                            Text("\(warmUp.suggestedWeight) kg (\(warmUp.percentageRange)) • \(warmUp.suggestedReps) reps")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.trainTextPrimary)
                        }

                        Spacer()

                        if let increase = warmUp.weightIncrease {
                            Text("+ \(increase)")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(.green)
                        }
                    }
                    .padding(Spacing.md)
                    .appCard()
                    .padding(.horizontal, Spacing.lg)
                }

                // Set Entry Rows
                VStack(spacing: Spacing.md) {
                    ForEach(sets) { set in
                        SetEntryRow(
                            set: bindingForSet(set),
                            onComplete: { markSetCompleted(set.id) }
                        )
                    }

                    // Add Set Button
                    Button {
                        addSet()
                    } label: {
                        HStack {
                            Text("Add Set")
                                .font(.system(size: 15))
                                .foregroundColor(.trainTextSecondary)
                            Spacer()
                        }
                        .padding(Spacing.md)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(style: StrokeStyle(lineWidth: 1, dash: [5]))
                                .foregroundColor(.trainTextSecondary)
                        )
                    }
                }
                .padding(.horizontal, Spacing.lg)

                Spacer().frame(height: 100)

                // Submit Exercise Button
                Button {
                    submitExercise()
                } label: {
                    Text("Submit Exercise")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.trainPrimary)
                        .cornerRadius(12)
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.lg)
            }
        }
        .onAppear {
            loadInitialData()
        }
    }

    private func loadInitialData() {
        // Initialize with 3 sets
        sets = (1...3).map { SetEntry(setNumber: $0) }

        // Create mock warm-up suggestion
        warmUpSuggestion = WarmUpSuggestion(
            suggestedWeight: 45, // Example weight
            weightIncrease: 5 // Example increase
        )
    }

    private func bindingForSet(_ set: SetEntry) -> Binding<SetEntry> {
        guard let index = sets.firstIndex(where: { $0.id == set.id }) else {
            return .constant(set)
        }
        return $sets[index]
    }

    private func addSet() {
        let newSetNumber = sets.count + 1
        sets.append(SetEntry(setNumber: newSetNumber))
    }

    private func markSetCompleted(_ setId: UUID) {
        if let index = sets.firstIndex(where: { $0.id == setId }) {
            sets[index].isCompleted.toggle()
        }
    }

    private func submitExercise() {
        print("✅ Exercise submitted: \(exercise.displayName)")
    }
}

// MARK: - Set Entry Row

struct SetEntryRow: View {
    @Binding var set: ExerciseLoggerTabView.SetEntry
    let onComplete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Text("\(set.setNumber)")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.trainTextPrimary)
                .frame(width: 24)

            TextField("kg", value: $set.weight, format: .number)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
                .frame(width: 70)

            TextField("reps", value: $set.reps, format: .number)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
                .frame(width: 70)

            Button {
                set.isCompleted.toggle()
                onComplete()
            } label: {
                Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "checkmark.circle")
                    .font(.system(size: 24))
                    .foregroundColor(set.isCompleted ? .green : .gray)
            }
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.trainPrimary, lineWidth: 1)
        )
    }
}

// MARK: - Demo Tab

struct ExerciseDemoTabView: View {
    let exercise: DBExercise
    @State private var equipment: [Equipment] = []
    @State private var activeMuscleGroups: [String] = []
    @State private var instructions: [String] = []

    struct Equipment: Identifiable {
        let id = UUID()
        let name: String
        let imageURL: String
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Video Player
                VideoPlayerSection(exercise: exercise)
                    .padding(.horizontal, Spacing.lg)

                // Equipment Section
                EquipmentSection(equipment: equipment)
                    .padding(.horizontal, Spacing.lg)

                // Active Muscle Groups - using ProfileView pattern
                ActiveMuscleGroupsSection(muscleGroups: activeMuscleGroups)
                    .padding(.horizontal, Spacing.lg)

                // Instructions
                InstructionsSection(instructions: instructions)
                    .padding(.horizontal, Spacing.lg)

                Spacer().frame(height: 100)
            }
            .padding(.top, Spacing.md)
        }
        .onAppear {
            loadDemoData()
        }
    }

    private func loadDemoData() {
        // Mock equipment data
        equipment = [
            Equipment(name: "Barbell", imageURL: ""),
            Equipment(name: "Weight Plates", imageURL: "")
        ]

        // Extract muscle groups from exercise
        activeMuscleGroups = [exercise.primaryMuscle, exercise.secondaryMuscle].compactMap { $0 }

        // Parse instructions
        instructions = exercise.instructionSteps
    }
}

// MARK: - Video Player Section

struct VideoPlayerSection: View {
    let exercise: DBExercise

    var body: some View {
        ZStack {
            // Video player or thumbnail
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
                .aspectRatio(16/9, contentMode: .fit)

            // Play button overlay
            Image(systemName: "play.fill")
                .font(.system(size: 32))
                .foregroundColor(.gray)
        }
        .onTapGesture {
            // Play video
            print("Playing video for \(exercise.displayName)")
        }
    }
}

// MARK: - Equipment Section

struct EquipmentSection: View {
    let equipment: [ExerciseDemoTabView.Equipment]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Equipment")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.trainTextPrimary)

            HStack(spacing: 16) {
                ForEach(equipment) { item in
                    VStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray5))
                            .frame(width: 60, height: 60)
                            .overlay(
                                Image(systemName: "dumbbell")
                                    .font(.title2)
                                    .foregroundColor(.trainTextSecondary)
                            )

                        Text(item.name)
                            .font(.trainCaption)
                            .foregroundColor(.trainTextSecondary)
                            .multilineTextAlignment(.center)
                    }
                }
            }
        }
        .padding(Spacing.md)
        .appCard()
    }
}

// MARK: - Active Muscle Groups Section (using ProfileView pattern)

struct ActiveMuscleGroupsSection: View {
    let muscleGroups: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Active Muscle Groups")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.trainTextPrimary)

            HStack(spacing: 16) {
                ForEach(muscleGroups, id: \.self) { group in
                    VStack(spacing: 8) {
                        StaticMuscleView(
                            muscleGroup: group,
                            gender: .male, // Could be made dynamic
                            size: 60,
                            useUniformBaseColor: true
                        )
                        .frame(width: 60, height: 60)

                        Text(group)
                            .font(.trainCaption)
                            .foregroundColor(.trainTextSecondary)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                    }
                }
            }
            .frame(maxWidth: .infinity) // Center the HStack
        }
        .padding(Spacing.md)
        .appCard()
    }
}

// MARK: - Instructions Section

struct InstructionsSection: View {
    let instructions: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Instructions")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.trainTextPrimary)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(instructions.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 8) {
                        Text("\(index + 1).")
                            .font(.system(size: 15))
                            .foregroundColor(.trainTextSecondary)
                        Text(step)
                            .font(.system(size: 15))
                            .foregroundColor(.trainTextPrimary)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
    }
}

// MARK: - History Tab

struct ExerciseHistoryTabView: View {
    let exercise: DBExercise
    @State private var stats: ExerciseStats?
    @State private var progressData: [ProgressDataPoint] = []
    @State private var sessionHistory: [SessionRecord] = []

    struct ExerciseStats {
        let bestSetWeight: Int
        let bestSetReps: Int
        let startWeight: Int
    }

    struct ProgressDataPoint: Identifiable {
        let id = UUID()
        let date: Date
        let weight: Int
    }

    struct SessionRecord: Identifiable {
        let id = UUID()
        let date: Date
        let dayName: String
        let sets: [SetRecord]
        let isPB: Bool
    }

    struct SetRecord: Identifiable {
        let id = UUID()
        let setNumber: Int
        let weight: Int
        let reps: Int
        let isBestSet: Bool
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Stats Summary Cards
                if let stats = stats {
                    HStack(spacing: 12) {
                        StatCard(title: "Best Set", value: "\(stats.bestSetWeight) kg • \(stats.bestSetReps) reps")
                        StatCard(title: "Start Weight", value: "\(stats.startWeight) kg")
                    }
                    .padding(.horizontal, Spacing.lg)
                }

                // Progress Chart
                if !progressData.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Progress")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.trainTextPrimary)
                            .padding(.horizontal, Spacing.lg)

                        Chart(progressData) { point in
                            LineMark(
                                x: .value("Date", point.date),
                                y: .value("Weight", point.weight)
                            )
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(Color.trainPrimary)

                            AreaMark(
                                x: .value("Date", point.date),
                                y: .value("Weight", point.weight)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.trainPrimary.opacity(0.3), Color.clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        }
                        .frame(height: 160)
                        .chartXAxis(.hidden)
                        .chartYAxis(.hidden)
                        .padding(.horizontal, Spacing.lg)
                    }
                    .padding(.vertical, Spacing.md)
                    .appCard()
                    .padding(.horizontal, Spacing.lg)
                }

                // Session History List
                VStack(alignment: .leading, spacing: 12) {
                    Text("History")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.trainTextPrimary)
                        .padding(.horizontal, Spacing.lg)

                    if sessionHistory.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "calendar.badge.exclamationmark")
                                .font(.system(size: 48))
                                .foregroundColor(.trainTextSecondary)

                            Text("No history yet")
                                .font(.trainBody)
                                .foregroundColor(.trainTextSecondary)

                            Text("Complete your first set!")
                                .font(.trainCaption)
                                .foregroundColor(.trainTextSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.xl)
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(sessionHistory) { session in
                                SessionHistoryCard(session: session)
                            }
                        }
                        .padding(.horizontal, Spacing.lg)
                    }
                }

                Spacer().frame(height: 100)
            }
            .padding(.top, Spacing.md)
        }
        .onAppear {
            loadHistoryData()
        }
    }

    private func loadHistoryData() {
        // Mock data
        stats = ExerciseStats(bestSetWeight: 70, bestSetReps: 12, startWeight: 45)

        let calendar = Calendar.current
        let now = Date()

        progressData = [
            ProgressDataPoint(date: calendar.date(byAdding: .day, value: -14, to: now)!, weight: 45),
            ProgressDataPoint(date: calendar.date(byAdding: .day, value: -10, to: now)!, weight: 50),
            ProgressDataPoint(date: calendar.date(byAdding: .day, value: -7, to: now)!, weight: 55),
            ProgressDataPoint(date: calendar.date(byAdding: .day, value: -3, to: now)!, weight: 60)
        ]

        sessionHistory = [
            SessionRecord(
                date: calendar.date(byAdding: .day, value: -3, to: now)!,
                dayName: "Monday",
                sets: [
                    SetRecord(setNumber: 1, weight: 60, reps: 12, isBestSet: true),
                    SetRecord(setNumber: 2, weight: 60, reps: 10, isBestSet: false),
                    SetRecord(setNumber: 3, weight: 60, reps: 8, isBestSet: false)
                ],
                isPB: true
            )
        ]
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 13))
                .foregroundColor(.trainTextSecondary)
            Text(value)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.trainTextPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
    }
}

// MARK: - Session History Card

struct SessionHistoryCard: View {
    let session: ExerciseHistoryTabView.SessionRecord

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                // Date header
                Text("\(session.date.formatted(.dateTime.day().month().year())) - \(session.dayName)")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.trainTextPrimary)

                // Sets
                ForEach(session.sets) { set in
                    Text("Set \(set.setNumber): \(set.weight)kg • \(set.reps) reps")
                        .font(.system(size: 14, weight: set.isBestSet ? .semibold : .regular))
                        .foregroundColor(set.isBestSet ? .trainTextPrimary : .trainTextSecondary)
                }
            }

            Spacer()

            // PB indicator
            if session.isPB {
                Image(systemName: "medal")
                    .font(.system(size: 24))
                    .foregroundColor(.orange)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
    }
}

#Preview {
    let mockExercise = try! JSONDecoder().decode(DBExercise.self, from: """
    {
        "exercise_id": 1,
        "canonical_name": "barbell_bench_press",
        "display_name": "Barbell Bench Press",
        "movement_pattern": "horizontal_push",
        "equipment_type": "Barbell",
        "equipment_category": "Barbell",
        "complexity_level": 3,
        "primary_muscle": "Chest",
        "secondary_muscle": "Triceps",
        "instructions": "Lie on bench\\nGrip barbell\\nLower to chest\\nPress up",
        "is_active": 1,
        "is_in_programme": 1
    }
    """.data(using: .utf8)!)

    return NavigationStack {
        ExerciseDetailView(
            exercise: mockExercise,
            workoutName: "Full Body",
            exerciseIndex: 1,
            totalExercises: 5
        )
    }
    .environmentObject(ThemeManager())
}