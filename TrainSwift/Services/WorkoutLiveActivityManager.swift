//
//  WorkoutLiveActivityManager.swift
//  TrainSwift
//
//  Manages Live Activities for workout tracking
//

import ActivityKit
import Foundation
import Combine

@available(iOS 16.1, *)
@MainActor
class WorkoutLiveActivityManager: ObservableObject {
    static let shared = WorkoutLiveActivityManager()

    @Published var currentActivity: Activity<WorkoutWidgetAttributes>?
    @Published var isLiveActivityActive = false
    private(set) var workoutStartTime: Date?

    private init() {}

    var currentElapsedTime: TimeInterval {
        guard let start = workoutStartTime else { return 0 }
        return Date().timeIntervalSince(start)
    }

    // MARK: - Start Live Activity

    func startWorkoutActivity(
        workoutName: String,
        totalExercises: Int,
        currentExercise: LoggedExercise,
        exerciseIndex: Int
    ) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            AppLogger.logWorkout("Live Activities are not enabled", level: .error)
            return
        }

        // End any existing activity first
        endWorkoutActivity()

        let attributes = WorkoutWidgetAttributes(
            workoutName: workoutName,
            totalExercises: totalExercises
        )

        let initialState = WorkoutWidgetAttributes.ContentState(
            currentExerciseName: currentExercise.exerciseName,
            currentSet: 1,
            totalSets: currentExercise.sets.count,
            elapsedTime: 0,
            isResting: false,
            restTimeRemaining: nil,
            restEndDate: nil,
            currentExerciseIndex: exerciseIndex
        )

        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil),
                pushType: nil
            )

            currentActivity = activity
            isLiveActivityActive = true
            workoutStartTime = Date()

            AppLogger.logWorkout("Started Live Activity for workout: \(workoutName)")
        } catch {
            AppLogger.logWorkout("Error starting Live Activity: \(error)", level: .error)
        }
    }

    // MARK: - Update Live Activity

    func updateWorkoutProgress(
        currentExercise: LoggedExercise,
        currentSet: Int,
        elapsedTime: TimeInterval,
        isResting: Bool = false,
        restTimeRemaining: Int? = nil
    ) {
        guard let activity = currentActivity else {
            AppLogger.logWorkout("No active Live Activity to update", level: .error)
            return
        }

        let newState = WorkoutWidgetAttributes.ContentState(
            currentExerciseName: currentExercise.exerciseName,
            currentSet: currentSet,
            totalSets: currentExercise.sets.count,
            elapsedTime: elapsedTime,
            isResting: isResting,
            restTimeRemaining: restTimeRemaining,
            restEndDate: nil,
            currentExerciseIndex: activity.content.state.currentExerciseIndex
        )

        Task {
            let content = ActivityContent(state: newState, staleDate: nil)
            await activity.update(content)
            AppLogger.logWorkout("Updated Live Activity: \(currentExercise.exerciseName), Set \(currentSet)")
        }
    }

    func updateExercise(
        currentExercise: LoggedExercise,
        exerciseIndex: Int,
        elapsedTime: TimeInterval
    ) {
        guard let activity = currentActivity else {
            AppLogger.logWorkout("No active Live Activity to update", level: .error)
            return
        }

        let newState = WorkoutWidgetAttributes.ContentState(
            currentExerciseName: currentExercise.exerciseName,
            currentSet: 1,
            totalSets: currentExercise.sets.count,
            elapsedTime: elapsedTime,
            isResting: false,
            restTimeRemaining: nil,
            restEndDate: nil,
            currentExerciseIndex: exerciseIndex
        )

        Task {
            let content = ActivityContent(state: newState, staleDate: nil)
            await activity.update(content)
            AppLogger.logWorkout("Updated Live Activity for new exercise: \(currentExercise.exerciseName)")
        }
    }

    func startRestTimer(seconds: Int, elapsedTime: TimeInterval) {
        guard let activity = currentActivity else { return }

        let currentState = activity.content.state
        let restEnd = Date().addingTimeInterval(Double(seconds))

        let newState = WorkoutWidgetAttributes.ContentState(
            currentExerciseName: currentState.currentExerciseName,
            currentSet: currentState.currentSet,
            totalSets: currentState.totalSets,
            elapsedTime: elapsedTime,
            isResting: true,
            restTimeRemaining: seconds,
            restEndDate: restEnd,
            currentExerciseIndex: currentState.currentExerciseIndex
        )

        Task {
            // Set staleDate so the system knows when the rest state expires
            let content = ActivityContent(state: newState, staleDate: restEnd)
            await activity.update(content)

            AppLogger.logWorkout("Rest timer started: \(seconds)s, ends at \(restEnd)")
        }
    }

    func endRestTimer() {
        guard let activity = currentActivity else { return }

        let currentState = activity.content.state
        let newState = WorkoutWidgetAttributes.ContentState(
            currentExerciseName: currentState.currentExerciseName,
            currentSet: currentState.currentSet,
            totalSets: currentState.totalSets,
            elapsedTime: currentElapsedTime,
            isResting: false,
            restTimeRemaining: nil,
            restEndDate: nil,
            currentExerciseIndex: currentState.currentExerciseIndex
        )

        Task {
            let content = ActivityContent(state: newState, staleDate: nil)
            await activity.update(content)
        }
    }

    // MARK: - End Live Activity

    func endWorkoutActivity() {
        guard let activity = currentActivity else { return }

        Task {
            await activity.end(nil, dismissalPolicy: .default)

            currentActivity = nil
            isLiveActivityActive = false
            workoutStartTime = nil

            AppLogger.logWorkout("Ended Live Activity")
        }
    }

    // MARK: - Activity Status

    var isActivitySupported: Bool {
        return ActivityAuthorizationInfo().areActivitiesEnabled
    }
}