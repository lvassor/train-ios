//
//  ExerciseHistoryView.swift
//  TrainSwift
//
//  Exercise-specific history with progress tracking and charts (Redesigned)
//

import SwiftUI
import Charts

struct ExerciseHistoryView: View {
    @Environment(\.dismiss) var dismiss
    let exercise: DBExercise
    @State private var historyEntries: [WorkoutHistoryEntry] = []
    @State private var bestSet: ExerciseSet?
    @State private var startWeight: Double = 0.0
    @State private var selectedMetric: ChartMetric = .totalVolume
    @State private var isInProgram: Bool = true

    enum ChartMetric: String, CaseIterable {
        case totalVolume = "Total Volume"
        case maxWeight = "Max Weight"

        var icon: String {
            switch self {
            case .totalVolume: return "chart.bar.fill"
            case .maxWeight: return "scalemass.fill"
            }
        }
    }

    struct WorkoutHistoryEntry: Identifiable {
        let id = UUID()
        let date: Date
        let sets: [ExerciseSet]
        let totalVolume: Double
        let maxWeight: Double
        let hadProgression: Bool
    }

    struct ExerciseSet: Identifiable {
        let id = UUID()
        let weight: Double
        let reps: Int
        let increased: Bool
    }

    var body: some View {
        ScrollView {
            if !isInProgram {
                // No data message for exercises not in any program
                VStack(spacing: Spacing.lg) {
                    Spacer()

                    VStack(spacing: Spacing.md) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: IconSize.xl))
                            .foregroundColor(.trainTextSecondary)

                        Text("No history yet")
                            .font(.trainBodyMedium)
                            .foregroundColor(.trainTextPrimary)

                        Text("You haven't logged this exercise in any workout session yet.")
                            .font(.trainBody)
                            .foregroundColor(.trainTextSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Spacing.xl)
                    }

                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: 0) {
                    // Exercise Info Header (same as Logger/Demo - centered, no container)
                    VStack(spacing: Spacing.xs) {
                        Text(exercise.displayName)
                            .font(.trainHeadline).fontWeight(.medium)
                            .foregroundColor(.trainTextPrimary)
                            .multilineTextAlignment(.center)

                        // Equipment tag
                        Text(exercise.equipmentCategory)
                            .font(.trainBody).fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, Spacing.lg)
                            .padding(.vertical, Spacing.sm)
                            .background(Color.trainTag)
                            .clipShape(Capsule())
                            .padding(.top, Spacing.xs)
                    }
                    .padding(.top, Spacing.lg)

                    // Stats Cards - side by side with border stroke
                    HStack(spacing: Spacing.lg) {
                        HistoryStatCard(
                            title: "Best Set",
                            value: bestSet.map { "\(Int($0.weight)) kg • \($0.reps) reps" } ?? "--"
                        )
                        HistoryStatCard(
                            title: "Start Weight",
                            value: startWeight > 0 ? "\(Int(startWeight)) kg" : "--"
                        )
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.top, Spacing.md)

                    // Progress Chart - simplified with area gradient
                    if !historyEntries.isEmpty {
                        HistoryProgressChart(
                            entries: historyEntries,
                            selectedMetric: selectedMetric
                        )
                        .frame(height: ElementHeight.chart)
                        .padding(.top, Spacing.sm)
                    }

                    // History Entries
                    VStack(spacing: Spacing.lg) {
                        ForEach(historyEntries) { entry in
                            HistorySessionCard(entry: entry)
                        }
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.top, Spacing.lg)
                    .padding(.bottom, 100)
                }
            }
        }
        .onAppear {
            loadHistory()
        }
    }

    private func loadHistory() {
        let exerciseName = exercise.displayName

        // Fetch all workout sessions for the current user from Core Data
        let allSessions = AuthService.shared.getWorkoutHistory()

        // Build history entries from sessions that contain this exercise
        // Sort sessions by date ascending (oldest first) so we can compute progression
        var matchingEntries: [(date: Date, sets: [LoggedSet])] = []

        for session in allSessions {
            guard let completedDate = session.completedAt else { continue }
            let loggedExercises = session.getLoggedExercises()

            // Find exercises matching by display name
            for loggedExercise in loggedExercises {
                if loggedExercise.exerciseName == exerciseName {
                    let completedSets = loggedExercise.sets.filter { $0.completed }
                    guard !completedSets.isEmpty else { continue }
                    matchingEntries.append((date: completedDate, sets: completedSets))
                }
            }
        }

        // Sort by date ascending (oldest first) for progression comparison
        matchingEntries.sort { $0.date < $1.date }

        // Determine visibility: show data if exercise is in program OR has history
        let hasHistory = !matchingEntries.isEmpty
        isInProgram = exercise.isInProgramme || hasHistory
        guard isInProgram else { return }

        // Convert to WorkoutHistoryEntry with progression tracking
        var previousMaxWeight: Double? = nil
        var entries: [WorkoutHistoryEntry] = []

        for match in matchingEntries {
            let sets = match.sets.map { loggedSet in
                ExerciseSet(
                    weight: loggedSet.weight,
                    reps: loggedSet.reps,
                    increased: false // Will be unused; progression is per-entry
                )
            }

            let totalVolume = match.sets.reduce(0.0) { $0 + $1.weight * Double($1.reps) }
            let maxWeight = match.sets.map(\.weight).max() ?? 0.0

            // Progression: maxWeight increased compared to previous entry
            let hadProgression: Bool
            if let prevMax = previousMaxWeight {
                hadProgression = maxWeight > prevMax
            } else {
                hadProgression = false
            }
            previousMaxWeight = maxWeight

            entries.append(WorkoutHistoryEntry(
                date: match.date,
                sets: sets,
                totalVolume: totalVolume,
                maxWeight: maxWeight,
                hadProgression: hadProgression
            ))
        }

        historyEntries = entries

        // Calculate best set (highest weight x reps product) across all history
        var maxProduct = 0.0
        for entry in historyEntries {
            for set in entry.sets {
                let product = set.weight * Double(set.reps)
                if product > maxProduct {
                    maxProduct = product
                    bestSet = set
                }
            }
        }

        // Start weight is the max weight from the earliest entry
        if let firstEntry = historyEntries.first {
            startWeight = firstEntry.maxWeight
        }
    }
}

// MARK: - History Stat Card (Redesigned)

struct HistoryStatCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: Spacing.sm) {
            Text(title)
                .font(.trainBody)
                .foregroundColor(.trainTextSecondary)
            Text(value)
                .font(.trainBody).fontWeight(.medium)
                .foregroundColor(.trainTextPrimary)
        }
        .frame(width: 160, height: 60)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                .stroke(Color.trainBorderSubtle.opacity(0.5), lineWidth: 1)
        )
    }
}

// MARK: - History Progress Chart (Redesigned)

struct HistoryProgressChart: View {
    let entries: [ExerciseHistoryView.WorkoutHistoryEntry]
    let selectedMetric: ExerciseHistoryView.ChartMetric

    var body: some View {
        Chart(entries) { entry in
            let yValue = selectedMetric == .totalVolume ? entry.totalVolume : entry.maxWeight

            // Area fill with gradient
            AreaMark(
                x: .value("Date", entry.date),
                y: .value(selectedMetric.rawValue, yValue)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [
                        Color.trainTextMuted.opacity(0.3),
                        Color.trainTextMuted.opacity(0.1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .interpolationMethod(.catmullRom)

            // Line on top
            LineMark(
                x: .value("Date", entry.date),
                y: .value(selectedMetric.rawValue, yValue)
            )
            .foregroundStyle(Color.trainTextPrimary)
            .lineStyle(StrokeStyle(lineWidth: 2))
            .interpolationMethod(.catmullRom)
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .padding(.horizontal, Spacing.md)
    }
}

// MARK: - History Session Card (Redesigned)

struct HistorySessionCard: View {
    let entry: ExerciseHistoryView.WorkoutHistoryEntry

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yy"
        return formatter.string(from: entry.date)
    }

    private var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: entry.date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Header with date and badge
            HStack {
                HStack(spacing: 0) {
                    Text(formattedDate)
                        .font(.trainBody).fontWeight(.medium)
                        .foregroundColor(.trainTextPrimary)
                    Text(" - \(dayOfWeek)")
                        .font(.trainBody)
                        .foregroundColor(.trainTextSecondary)
                }
                Spacer()
                if entry.hadProgression {
                    Image(systemName: "medal")
                        .font(.system(size: IconSize.lg))
                        .foregroundColor(Color.trainPrimary)
                }
            }

            // Set details
            VStack(alignment: .leading, spacing: Spacing.xs) {
                ForEach(Array(entry.sets.enumerated()), id: \.element.id) { index, set in
                    Text("Set \(index + 1): \(Int(set.weight)) kg • \(set.reps) reps")
                        .font(.trainBody).fontWeight(index == 0 ? .medium : .regular)
                        .foregroundColor(.trainTextPrimary)
                }
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                .stroke(Color.trainBorderSubtle.opacity(0.5), lineWidth: 1)
        )
    }
}

// MARK: - Legacy History Entry Card (kept for backward compatibility)

struct HistoryEntryCard: View {
    let entry: ExerciseHistoryView.WorkoutHistoryEntry

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text(entry.date, style: .date)
                    .font(.trainBodyMedium)
                    .foregroundColor(.trainTextPrimary)

                Spacer()

                if entry.hadProgression {
                    Image(systemName: "rosette.fill")
                        .font(.system(size: IconSize.md))
                        .foregroundColor(.trainPrimary)
                }
            }

            VStack(alignment: .leading, spacing: Spacing.xs) {
                ForEach(Array(entry.sets.enumerated()), id: \.element.id) { index, set in
                    HStack {
                        Text("Set \(index + 1):")
                            .font(.trainBody)
                            .foregroundColor(.trainTextSecondary)

                        Text("\(set.weight, specifier: "%.1f") kg • \(set.reps) reps")
                            .font(.trainBody)
                            .foregroundColor(.trainTextPrimary)

                        if set.increased {
                            Text("+1")
                                .font(.trainCaption)
                                .foregroundColor(.trainSuccess)
                                .padding(.horizontal, Spacing.sm)
                                .padding(.vertical, Spacing.xxs)
                                .background(Color.trainSuccess.opacity(0.1))
                                .cornerRadius(CornerRadius.xxs)
                        }
                    }
                }
            }
        }
        .padding(Spacing.md)
        .appCard()
        .cornerRadius(CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(entry.hadProgression ? Color.trainPrimary : Color.clear, lineWidth: entry.hadProgression ? 2 : 1)
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
        "complexity_level": 3,
        "primary_muscle": "Chest",
        "secondary_muscle": "Triceps",
        "is_active": 1
    }
    """.data(using: .utf8)!)

    return NavigationStack {
        ExerciseHistoryView(exercise: mockExercise)
    }
}
