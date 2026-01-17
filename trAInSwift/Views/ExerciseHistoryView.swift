//
//  ExerciseHistoryView.swift
//  trAInSwift
//
//  Exercise-specific history with progress tracking and charts
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
                            .font(.system(size: 48))
                            .foregroundColor(.trainTextSecondary)

                        Text("No data - not in any program")
                            .font(.trainBodyMedium)
                            .foregroundColor(.trainTextPrimary)

                        Text("This exercise hasn't been completed in any of your training programs yet.")
                            .font(.trainBody)
                            .foregroundColor(.trainTextSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Spacing.xl)
                    }

                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: Spacing.lg) {
                    // Summary cards
                    HStack(spacing: Spacing.md) {
                        // Best Set card
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Best Set")
                                .font(.trainBodyMedium)
                                .foregroundColor(.trainTextSecondary)

                            if let best = bestSet {
                                Text("\(best.weight, specifier: "%.1f") kg • \(best.reps) reps")
                                    .font(.trainTitle)
                                    .foregroundColor(.trainTextPrimary)
                            } else {
                                Text("--")
                                    .font(.trainTitle)
                                    .foregroundColor(.trainTextSecondary)
                            }
                        }
                        .padding(Spacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white)
                        .cornerRadius(15)
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(Color.trainBorder, lineWidth: 1)
                        )

                        // Start Weight card
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Start Weight")
                                .font(.trainBodyMedium)
                                .foregroundColor(.trainTextSecondary)

                            if startWeight > 0 {
                                Text("\(Int(startWeight)) kg")
                                    .font(.trainTitle)
                                    .foregroundColor(.trainTextPrimary)
                            } else {
                                Text("--")
                                    .font(.trainTitle)
                                    .foregroundColor(.trainTextSecondary)
                            }
                        }
                        .padding(Spacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .appCard()
                        .cornerRadius(15)
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.top, Spacing.md)

                    // Progress chart
                    if !historyEntries.isEmpty {
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            // Chart header with toggle
                            HStack {
                                Text("Progress")
                                    .font(.trainBodyMedium)
                                    .foregroundColor(.trainTextPrimary)

                                Spacer()

                                // Metric toggle
                                HStack(spacing: 0) {
                                    ForEach(ChartMetric.allCases, id: \.self) { metric in
                                        Button(action: { selectedMetric = metric }) {
                                            HStack(spacing: 4) {
                                                Image(systemName: metric.icon)
                                                    .font(.caption)
                                                Text(metric.rawValue)
                                                    .font(.trainCaption)
                                            }
                                            .fontWeight(.medium)
                                            .foregroundColor(selectedMetric == metric ? .white : .trainTextSecondary)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(selectedMetric == metric ? Color.trainPrimary : Color.clear)
                                        }
                                    }
                                }
                                .glassCompactCard(cornerRadius: CornerRadius.sm)
                                .overlay(
                                    RoundedRectangle(cornerRadius: CornerRadius.sm, style: .continuous)
                                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                )
                            }
                            .padding(.horizontal, Spacing.lg)

                            Chart(historyEntries) { entry in
                                let yValue = selectedMetric == .totalVolume ? entry.totalVolume : entry.maxWeight

                                LineMark(
                                    x: .value("Date", entry.date),
                                    y: .value(selectedMetric.rawValue, yValue)
                                )
                                .foregroundStyle(Color.trainPrimary)
                                .interpolationMethod(.catmullRom)

                                AreaMark(
                                    x: .value("Date", entry.date),
                                    y: .value(selectedMetric.rawValue, yValue)
                                )
                                .foregroundStyle(Color.trainPrimary.opacity(0.1))
                                .interpolationMethod(.catmullRom)
                            }
                            .frame(height: 200)
                            .padding(.horizontal, Spacing.lg)
                            .animation(.easeInOut(duration: 0.3), value: selectedMetric)
                        }
                        .padding(.vertical, Spacing.md)
                        .appCard()
                        .cornerRadius(15)
                        .padding(.horizontal, Spacing.lg)
                    }

                    // History entries
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Text("History")
                            .font(.trainBodyMedium)
                            .foregroundColor(.trainTextPrimary)
                            .padding(.horizontal, Spacing.lg)

                        if historyEntries.isEmpty {
                            VStack(spacing: Spacing.md) {
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
                            VStack(spacing: Spacing.md) {
                                ForEach(historyEntries) { entry in
                                    HistoryEntryCard(entry: entry)
                                }
                            }
                            .padding(.horizontal, Spacing.lg)
                        }
                    }

                    Spacer()
                        .frame(height: Spacing.lg)
                }
            }
        }
        .navigationTitle(exercise.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadHistory()
        }
    }

    private func loadHistory() {
        // Check if exercise is in user's program
        isInProgram = exercise.isInProgramme

        // If not in program, don't load sample data
        guard isInProgram else { return }

        // Sample data for demonstration
        let calendar = Calendar.current
        let now = Date()

        historyEntries = [
            WorkoutHistoryEntry(
                date: calendar.date(byAdding: .day, value: -14, to: now)!,
                sets: [
                    ExerciseSet(weight: 60, reps: 12, increased: false),
                    ExerciseSet(weight: 60, reps: 10, increased: false),
                    ExerciseSet(weight: 60, reps: 8, increased: false)
                ],
                totalVolume: 1800,
                maxWeight: 60,
                hadProgression: false
            ),
            WorkoutHistoryEntry(
                date: calendar.date(byAdding: .day, value: -10, to: now)!,
                sets: [
                    ExerciseSet(weight: 65, reps: 12, increased: true),
                    ExerciseSet(weight: 65, reps: 11, increased: true),
                    ExerciseSet(weight: 65, reps: 9, increased: true)
                ],
                totalVolume: 2080,
                maxWeight: 65,
                hadProgression: true
            ),
            WorkoutHistoryEntry(
                date: calendar.date(byAdding: .day, value: -7, to: now)!,
                sets: [
                    ExerciseSet(weight: 65, reps: 12, increased: false),
                    ExerciseSet(weight: 65, reps: 12, increased: true),
                    ExerciseSet(weight: 65, reps: 10, increased: true)
                ],
                totalVolume: 2210,
                maxWeight: 65,
                hadProgression: true
            ),
            WorkoutHistoryEntry(
                date: calendar.date(byAdding: .day, value: -3, to: now)!,
                sets: [
                    ExerciseSet(weight: 70, reps: 12, increased: true),
                    ExerciseSet(weight: 70, reps: 10, increased: false),
                    ExerciseSet(weight: 70, reps: 9, increased: false)
                ],
                totalVolume: 2170,
                maxWeight: 70,
                hadProgression: true
            )
        ]

        // Calculate best set and start weight
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

        if let firstEntry = historyEntries.first, let firstSet = firstEntry.sets.first {
            startWeight = firstSet.weight
        }
    }
}

// MARK: - History Entry Card

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
                        .font(.system(size: 20))
                        .foregroundColor(.trainPrimary)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
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
                                .foregroundColor(.green)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(4)
                        }
                    }
                }
            }
        }
        .padding(Spacing.md)
        .appCard()
        .cornerRadius(15)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
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
