//
//  WorkoutWidget.swift
//  WorkoutWidget
//
//  Main workout Live Activity widget implementation
//

import ActivityKit
import WidgetKit
import SwiftUI

struct WorkoutWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            WorkoutLockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here
                DynamicIslandExpandedContent(context: context)
            } compactLeading: {
                // Compact leading view
                TrainIconView(size: 16)
            } compactTrailing: {
                // Time elapsed
                Text(timeFormatted(context.state.elapsedTime))
                    .font(.caption2)
                    .fontWeight(.semibold)
            } minimal: {
                // Minimal view
                TrainIconView(size: 12)
            }
        }
    }
}

// MARK: - Lock Screen View

struct WorkoutLockScreenView: View {
    let context: ActivityViewContext<WorkoutWidgetAttributes>

    var body: some View {
        VStack(spacing: 8) {
            // Header with Train logo and title
            HStack {
                TrainIconView(size: 20)

                Text("Train")
                    .font(.headline)
                    .fontWeight(.bold)

                Spacer()

                // Elapsed time
                Text(timeFormatted(context.state.elapsedTime))
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }

            // Workout name
            HStack {
                Text(context.attributes.workoutName)
                    .font(.title3)
                    .fontWeight(.medium)
                Spacer()
            }

            // Current exercise info
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(context.state.currentExerciseName)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    if context.state.isResting {
                        if let restTime = context.state.restTimeRemaining {
                            Text("Rest: \(restTime)s remaining")
                                .font(.caption)
                                .foregroundColor(.orange)
                        } else {
                            Text("Resting")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    } else {
                        Text("Set \(context.state.currentSet) of \(context.state.totalSets)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Exercise progress indicator
                Circle()
                    .fill(context.state.isResting ? Color.orange : Color.green)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(16)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Dynamic Island Expanded Content

struct DynamicIslandExpandedContent: DynamicIslandExpandedContent {
    let context: ActivityViewContext<WorkoutWidgetAttributes>

    var body: some DynamicIslandExpandedContent {
        DynamicIslandExpandedRegion(.leading) {
            HStack {
                TrainIconView(size: 24)

                VStack(alignment: .leading) {
                    Text("Train")
                        .font(.caption)
                        .fontWeight(.bold)
                    Text(context.attributes.workoutName)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }

        DynamicIslandExpandedRegion(.trailing) {
            VStack(alignment: .trailing) {
                Text(timeFormatted(context.state.elapsedTime))
                    .font(.caption)
                    .fontWeight(.semibold)

                if context.state.isResting, let restTime = context.state.restTimeRemaining {
                    Text("Rest: \(restTime)s")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
            }
        }

        DynamicIslandExpandedRegion(.bottom) {
            VStack(spacing: 4) {
                Text(context.state.currentExerciseName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                if !context.state.isResting {
                    Text("Set \(context.state.currentSet) of \(context.state.totalSets)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Progress bar
                ProgressView(
                    value: Double(context.attributes.currentExerciseIndex + 1),
                    total: Double(context.attributes.totalExercises)
                )
                .tint(.blue)
            }
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - Helper Functions

private func timeFormatted(_ timeInterval: TimeInterval) -> String {
    let totalSeconds = Int(timeInterval)
    let minutes = totalSeconds / 60
    let seconds = totalSeconds % 60
    return String(format: "%d:%02d", minutes, seconds)
}