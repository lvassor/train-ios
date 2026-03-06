//
//  WatchWorkoutView.swift
//  TrainWatch
//
//  Active workout view — scrollable exercise list with current exercise highlighted
//

import SwiftUI

struct WatchWorkoutView: View {
    let workoutState: WatchWorkoutState
    @EnvironmentObject var connectivity: WatchConnectivityService
    @State private var selectedExercise: WatchExercise?

    private var currentExercise: WatchExercise? {
        guard workoutState.currentExerciseIndex < workoutState.exercises.count else { return nil }
        return workoutState.exercises[workoutState.currentExerciseIndex]
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                List {
                    // Workout header
                    WatchWorkoutHeader(
                        workoutName: workoutState.workoutName,
                        weekNumber: workoutState.weekNumber,
                        exerciseCount: workoutState.exercises.count,
                        completedCount: workoutState.exercises.filter(\.isCompleted).count,
                        elapsedTime: workoutState.elapsedTime
                    )
                    .listRowBackground(Color.clear)

                    // Exercise list
                    ForEach(Array(workoutState.exercises.enumerated()), id: \.element.id) { index, exercise in
                        NavigationLink(value: exercise) {
                            WatchExerciseRow(
                                exercise: exercise,
                                index: index,
                                isCurrent: index == workoutState.currentExerciseIndex
                            )
                        }
                        .id(exercise.id)
                        .listRowBackground(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(index == workoutState.currentExerciseIndex
                                      ? Color.orange.opacity(0.15)
                                      : Color.clear)
                        )
                    }
                }
                .navigationDestination(for: WatchExercise.self) { exercise in
                    WatchExerciseDetailView(exercise: exercise)
                }
                .navigationTitle(workoutState.workoutName)
                .navigationBarTitleDisplayMode(.inline)
                .onAppear {
                    if let current = currentExercise {
                        proxy.scrollTo(current.id, anchor: .center)
                    }
                }
            }
        }

        // Rest timer overlay
        if connectivity.restEndDate != nil {
            WatchRestTimerView()
                .environmentObject(connectivity)
        }
    }
}

// MARK: - Workout Header

struct WatchWorkoutHeader: View {
    let workoutName: String
    let weekNumber: Int
    let exerciseCount: Int
    let completedCount: Int
    let elapsedTime: TimeInterval

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text("Week \(weekNumber)")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Spacer()

                Text(timeFormatted(elapsedTime))
                    .font(.system(.caption2, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundColor(.orange)
            }

            // Progress ring
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 4)

                Circle()
                    .trim(from: 0, to: exerciseCount > 0
                          ? CGFloat(completedCount) / CGFloat(exerciseCount)
                          : 0)
                    .stroke(Color.orange, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 0) {
                    Text("\(completedCount)")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                    Text("of \(exerciseCount)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 60, height: 60)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Exercise Row

struct WatchExerciseRow: View {
    let exercise: WatchExercise
    let index: Int
    let isCurrent: Bool

    var body: some View {
        HStack(spacing: 8) {
            // Status indicator
            ZStack {
                Circle()
                    .fill(exercise.isCompleted ? Color.green : (isCurrent ? Color.orange : Color.gray.opacity(0.3)))
                    .frame(width: 22, height: 22)

                if exercise.isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    Text("\(index + 1)")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(isCurrent ? .white : .secondary)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.name)
                    .font(.caption)
                    .fontWeight(isCurrent ? .semibold : .regular)
                    .lineLimit(1)

                Text("\(exercise.sets.count) sets \u{00B7} \(exercise.repRange)")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Helpers

private func timeFormatted(_ interval: TimeInterval) -> String {
    let total = Int(interval)
    let m = total / 60
    let s = total % 60
    return String(format: "%d:%02d", m, s)
}
