//
//  WorkoutWidgetAttributes.swift
//  WorkoutWidget
//
//  Defines the structure of data for the workout Live Activity
//

import ActivityKit
import Foundation

struct WorkoutWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic content that changes during the workout
        var currentExerciseName: String
        var currentSet: Int
        var totalSets: Int
        var elapsedTime: TimeInterval
        var isResting: Bool
        var restTimeRemaining: Int?
    }

    // Static content that doesn't change during the workout
    var workoutName: String
    var totalExercises: Int
    var currentExerciseIndex: Int
}