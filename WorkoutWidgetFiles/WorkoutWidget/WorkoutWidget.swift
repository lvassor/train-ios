//
//  WorkoutWidget.swift
//  WorkoutWidget
//
//  Main workout Live Activity widget implementation
//

import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - Widget Color Constants
// Widget extensions can't access the main app's theme, so define locally
private enum WidgetColors {
    static let accent = Color.orange
    static let activeIndicator = Color.green
    static let progressTint = Color.blue
}

private let widgetPadding: CGFloat = 16

struct WorkoutWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutWidgetAttributes.self) { context in
            WorkoutLockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack {
                        WidgetTrainIcon(size: 24)

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
                                .foregroundColor(WidgetColors.accent)
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

                        ProgressView(
                            value: Double(context.attributes.currentExerciseIndex + 1),
                            total: Double(context.attributes.totalExercises)
                        )
                        .tint(WidgetColors.progressTint)
                    }
                    .padding(.horizontal, widgetPadding)
                }
            } compactLeading: {
                WidgetTrainIcon(size: 16)
            } compactTrailing: {
                Text(timeFormatted(context.state.elapsedTime))
                    .font(.caption2)
                    .fontWeight(.semibold)
            } minimal: {
                WidgetTrainIcon(size: 12)
            }
        }
    }
}

// MARK: - Lock Screen View

struct WorkoutLockScreenView: View {
    let context: ActivityViewContext<WorkoutWidgetAttributes>

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                WidgetTrainIcon(size: 20)

                Text("Train")
                    .font(.headline)
                    .fontWeight(.bold)

                Spacer()

                Text(timeFormatted(context.state.elapsedTime))
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }

            HStack {
                Text(context.attributes.workoutName)
                    .font(.title3)
                    .fontWeight(.medium)
                Spacer()
            }

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(context.state.currentExerciseName)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    if context.state.isResting {
                        if let restTime = context.state.restTimeRemaining {
                            Text("Rest: \(restTime)s remaining")
                                .font(.caption)
                                .foregroundColor(WidgetColors.accent)
                        } else {
                            Text("Resting")
                                .font(.caption)
                                .foregroundColor(WidgetColors.accent)
                        }
                    } else {
                        Text("Set \(context.state.currentSet) of \(context.state.totalSets)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Circle()
                    .fill(context.state.isResting ? WidgetColors.accent : WidgetColors.activeIndicator)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(widgetPadding)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Widget Train Icon (self-contained, no dependency on main app)

private struct WidgetTrainIcon: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(LinearGradient(
                    gradient: Gradient(colors: [WidgetColors.accent, WidgetColors.accent.opacity(0.7)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: size, height: size)

            Text("T")
                .font(.system(size: size * 0.6, weight: .bold, design: .rounded))
                .foregroundColor(.white)
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
