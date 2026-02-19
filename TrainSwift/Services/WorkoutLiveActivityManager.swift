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
class WorkoutLiveActivityManager: ObservableObject {
    static let shared = WorkoutLiveActivityManager()

    @Published var currentActivity: Activity<WorkoutWidgetAttributes>?
    @Published var isLiveActivityActive = false

    private init() {}

    // MARK: - Start Live Activity

    func startWorkoutActivity(
        workoutName: String,
        totalExercises: Int,
        currentExercise: LoggedExercise,
        exerciseIndex: Int
    ) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("❌ Live Activities are not enabled")
            return
        }

        // End any existing activity first
        endWorkoutActivity()

        let attributes = WorkoutWidgetAttributes(
            workoutName: workoutName,
            totalExercises: totalExercises,
            currentExerciseIndex: exerciseIndex
        )

        let initialState = WorkoutWidgetAttributes.ContentState(
            currentExerciseName: currentExercise.exerciseName,
            currentSet: 1,
            totalSets: currentExercise.sets.count,
            elapsedTime: 0,
            isResting: false,
            restTimeRemaining: nil
        )

        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil),
                pushType: nil
            )

            currentActivity = activity
            isLiveActivityActive = true

            print("✅ Started Live Activity for workout: \(workoutName)")
        } catch {
            print("❌ Error starting Live Activity: \(error)")
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
            print("❌ No active Live Activity to update")
            return
        }

        let newState = WorkoutWidgetAttributes.ContentState(
            currentExerciseName: currentExercise.exerciseName,
            currentSet: currentSet,
            totalSets: currentExercise.sets.count,
            elapsedTime: elapsedTime,
            isResting: isResting,
            restTimeRemaining: restTimeRemaining
        )

        Task {
            let content = ActivityContent(state: newState, staleDate: nil)
            await activity.update(content)
            print("✅ Updated Live Activity: \(currentExercise.exerciseName), Set \(currentSet)")
        }
    }

    func updateExercise(
        currentExercise: LoggedExercise,
        exerciseIndex: Int,
        elapsedTime: TimeInterval
    ) {
        guard let activity = currentActivity else {
            print("❌ No active Live Activity to update")
            return
        }

        // Update attributes for new exercise
        let newAttributes = WorkoutWidgetAttributes(
            workoutName: activity.attributes.workoutName,
            totalExercises: activity.attributes.totalExercises,
            currentExerciseIndex: exerciseIndex
        )

        let newState = WorkoutWidgetAttributes.ContentState(
            currentExerciseName: currentExercise.exerciseName,
            currentSet: 1,
            totalSets: currentExercise.sets.count,
            elapsedTime: elapsedTime,
            isResting: false,
            restTimeRemaining: nil
        )

        // End current activity and start new one with updated attributes
        Task {
            await activity.end(nil, dismissalPolicy: .immediate)

            do {
                let newActivity = try Activity.request(
                    attributes: newAttributes,
                    content: .init(state: newState, staleDate: nil),
                    pushType: nil
                )

                await MainActor.run {
                    currentActivity = newActivity
                }

                print("✅ Updated Live Activity for new exercise: \(currentExercise.exerciseName)")
            } catch {
                print("❌ Error updating Live Activity for new exercise: \(error)")
            }
        }
    }

    func startRestTimer(seconds: Int, elapsedTime: TimeInterval) {
        guard let activity = currentActivity else { return }

        let currentState = activity.content.state
        let newState = WorkoutWidgetAttributes.ContentState(
            currentExerciseName: currentState.currentExerciseName,
            currentSet: currentState.currentSet,
            totalSets: currentState.totalSets,
            elapsedTime: elapsedTime,
            isResting: true,
            restTimeRemaining: seconds
        )

        Task {
            let content = ActivityContent(state: newState, staleDate: nil)
            await activity.update(content)

            // Start countdown timer
            for i in (1...seconds).reversed() {
                try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second

                guard let currentActivity = currentActivity else { break }

                let updatedState = WorkoutWidgetAttributes.ContentState(
                    currentExerciseName: currentState.currentExerciseName,
                    currentSet: currentState.currentSet,
                    totalSets: currentState.totalSets,
                    elapsedTime: elapsedTime + Double(seconds - i + 1),
                    isResting: i > 1,
                    restTimeRemaining: i > 1 ? i - 1 : nil
                )

                let content = ActivityContent(state: updatedState, staleDate: nil)
                await currentActivity.update(content)
            }

            print("✅ Rest timer completed")
        }
    }

    // MARK: - End Live Activity

    func endWorkoutActivity() {
        guard let activity = currentActivity else { return }

        Task {
            await activity.end(nil, dismissalPolicy: .default)

            await MainActor.run {
                currentActivity = nil
                isLiveActivityActive = false
            }

            print("✅ Ended Live Activity")
        }
    }

    // MARK: - Activity Status

    var isActivitySupported: Bool {
        return ActivityAuthorizationInfo().areActivitiesEnabled
    }
}