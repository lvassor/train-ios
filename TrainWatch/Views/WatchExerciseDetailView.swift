//
//  WatchExerciseDetailView.swift
//  TrainWatch
//
//  Exercise detail showing sets with inline editing via Digital Crown
//

import SwiftUI

struct WatchExerciseDetailView: View {
    let exercise: WatchExercise
    @EnvironmentObject var connectivity: WatchConnectivityService
    @State private var editingSetIndex: Int?

    var body: some View {
        List {
            // Exercise header
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    Label(exercise.repRange, systemImage: "arrow.up.arrow.down")
                    Label("\(exercise.restSeconds)s", systemImage: "timer")
                }
                .font(.caption2)
                .foregroundColor(.secondary)
            }
            .listRowBackground(Color.clear)

            // Sets
            ForEach(Array(exercise.sets.enumerated()), id: \.element.id) { index, set in
                WatchSetRow(
                    setNumber: index + 1,
                    set: set,
                    isEditing: editingSetIndex == index,
                    onTap: {
                        if editingSetIndex == index {
                            // Complete this set
                            completeSet(index: index, set: set)
                        } else {
                            editingSetIndex = index
                        }
                    },
                    onWeightChanged: { newWeight in
                        sendUpdate(index: index, reps: set.reps, weight: newWeight)
                    },
                    onRepsChanged: { newReps in
                        sendUpdate(index: index, reps: newReps, weight: set.weight)
                    }
                )
                .listRowBackground(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(set.completed ? Color.green.opacity(0.1) : Color.clear)
                )
            }
        }
        .navigationTitle("Sets")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func completeSet(index: Int, set: WatchSet) {
        let update = WatchSetUpdate(
            exerciseId: exercise.id,
            setIndex: index,
            reps: set.reps > 0 ? set.reps : Int(exercise.repRange.split(separator: "-").last ?? "0") ?? 0,
            weight: set.weight,
            action: .completeSet
        )
        connectivity.sendSetUpdate(update)
        editingSetIndex = nil
    }

    private func sendUpdate(index: Int, reps: Int, weight: Double) {
        let update = WatchSetUpdate(
            exerciseId: exercise.id,
            setIndex: index,
            reps: reps,
            weight: weight,
            action: .updateSet
        )
        connectivity.sendSetUpdate(update)
    }
}

// MARK: - Set Row

struct WatchSetRow: View {
    let setNumber: Int
    let set: WatchSet
    let isEditing: Bool
    let onTap: () -> Void
    let onWeightChanged: (Double) -> Void
    let onRepsChanged: (Int) -> Void

    @State private var editWeight: Double = 0
    @State private var editReps: Int = 0

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                HStack {
                    Text("Set \(setNumber)")
                        .font(.caption)
                        .fontWeight(.semibold)

                    Spacer()

                    if set.completed {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                }

                if isEditing {
                    // Editable mode
                    VStack(spacing: 8) {
                        WatchValueAdjuster(
                            label: "kg",
                            value: $editWeight,
                            step: 2.5,
                            format: "%.1f"
                        )

                        WatchValueAdjuster(
                            label: "reps",
                            value: Binding(
                                get: { Double(editReps) },
                                set: { editReps = Int($0) }
                            ),
                            step: 1,
                            format: "%.0f"
                        )

                        Text("Tap to complete")
                            .font(.system(size: 10))
                            .foregroundColor(.orange)
                    }
                    .onChange(of: editWeight) { _, newValue in
                        onWeightChanged(newValue)
                    }
                    .onChange(of: editReps) { _, newValue in
                        onRepsChanged(newValue)
                    }
                } else {
                    // Summary mode
                    HStack {
                        // Current/logged values
                        if set.weight > 0 || set.reps > 0 {
                            Text("\(set.weight, specifier: "%.1f") kg")
                                .font(.system(.caption, design: .rounded))
                                .fontWeight(.medium)
                            Text("\u{00D7} \(set.reps)")
                                .font(.system(.caption, design: .rounded))
                        }

                        Spacer()

                        // Previous values
                        if set.previousWeight > 0 {
                            Text("\(set.previousWeight, specifier: "%.1f") \u{00D7} \(set.previousReps)")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .onAppear {
            editWeight = set.weight > 0 ? set.weight : set.previousWeight
            editReps = set.reps > 0 ? set.reps : set.previousReps
        }
    }
}

// MARK: - Value Adjuster (crown-friendly stepper)

struct WatchValueAdjuster: View {
    let label: String
    @Binding var value: Double
    let step: Double
    let format: String

    var body: some View {
        HStack {
            Button {
                value = max(0, value - step)
            } label: {
                Image(systemName: "minus.circle.fill")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)

            VStack(spacing: 0) {
                Text(String(format: format, value))
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.semibold)
                    .focusable()
                    .digitalCrownRotation(
                        $value,
                        from: 0,
                        through: label == "kg" ? 300 : 50,
                        by: step,
                        sensitivity: .medium,
                        isContinuous: false,
                        isHapticFeedbackEnabled: true
                    )
                Text(label)
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)

            Button {
                value += step
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                    .foregroundColor(.orange)
            }
            .buttonStyle(.plain)
        }
    }
}
