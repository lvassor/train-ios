//
//  WatchWorkoutModels.swift
//  Shared
//
//  Lightweight models for iPhone <-> Watch communication.
//  Both targets include this file directly (no framework needed).
//

import Foundation

// MARK: - Watch Workout State

/// Full workout state synced from iPhone to Watch
struct WatchWorkoutState: Codable {
    let workoutName: String          // "Push", "Pull", "Full Body"
    let weekNumber: Int
    let exercises: [WatchExercise]
    let currentExerciseIndex: Int
    let elapsedTime: TimeInterval
    let isActive: Bool
}

/// Minimal exercise representation for Watch display
struct WatchExercise: Codable, Identifiable {
    let id: String
    let name: String
    let sets: [WatchSet]
    let repRange: String             // "8-12"
    let restSeconds: Int
    let primaryMuscle: String
    let isCompleted: Bool
}

/// Minimal set representation for Watch display and logging
struct WatchSet: Codable, Identifiable {
    let id: String
    var reps: Int
    var weight: Double
    var completed: Bool
    let previousReps: Int
    let previousWeight: Double
}

// MARK: - Watch -> iPhone Actions

/// Actions the Watch can send to the iPhone
enum WatchAction: String, Codable {
    case completeSet
    case updateSet
    case skipExercise
    case startRest
    case endRest
    case requestSync
}

/// Payload for Watch -> iPhone set updates
struct WatchSetUpdate: Codable {
    let exerciseId: String
    let setIndex: Int
    let reps: Int
    let weight: Double
    let action: WatchAction
}

// MARK: - Message Keys

enum WatchMessageKey {
    static let workoutState = "workoutState"
    static let setUpdate = "setUpdate"
    static let action = "action"
    static let restStarted = "restStarted"
    static let restSeconds = "restSeconds"
    static let workoutEnded = "workoutEnded"
}
