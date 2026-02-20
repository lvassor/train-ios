//
//  WorkoutStateManager.swift
//  TrainSwift
//
//  Manages active workout state globally across app navigation
//  Tracks workout timer, session data, and provides Continue Workout functionality
//

import Foundation
import Combine

@MainActor
class WorkoutStateManager: ObservableObject {
    static let shared = WorkoutStateManager()

    @Published var activeWorkout: ActiveWorkoutSession? = nil
    @Published var isWorkoutActive: Bool = false

    private init() {}

    // MARK: - Active Workout Session

    struct ActiveWorkoutSession {
        let sessionName: String
        let weekNumber: Int
        let sessionIndex: Int
        let startTime: Date
        var elapsedTime: TimeInterval = 0
        var completedExercises: Set<String> = []
        var loggedExercises: [String: LoggedExercise] = [:]
        let totalExercises: Int
        var modifiedExercises: [ProgramExercise]? = nil
    }

    // MARK: - Workout State Management

    func startWorkout(sessionName: String, weekNumber: Int, sessionIndex: Int, totalExercises: Int) {
        activeWorkout = ActiveWorkoutSession(
            sessionName: sessionName,
            weekNumber: weekNumber,
            sessionIndex: sessionIndex,
            startTime: Date(),
            totalExercises: totalExercises
        )
        isWorkoutActive = true
        AppLogger.logWorkout("Started active workout: \(sessionName)")
    }

    func updateWorkoutProgress(completedExercises: Set<String>, loggedExercises: [String: LoggedExercise], modifiedExercises: [ProgramExercise]? = nil) {
        guard var workout = activeWorkout else { return }
        workout.completedExercises = completedExercises
        workout.loggedExercises = loggedExercises
        workout.elapsedTime = Date().timeIntervalSince(workout.startTime)
        if let modified = modifiedExercises {
            workout.modifiedExercises = modified
        }
        activeWorkout = workout
    }

    func completeWorkout() {
        activeWorkout = nil
        isWorkoutActive = false
        AppLogger.logWorkout("Completed active workout")
    }

    func cancelWorkout() {
        activeWorkout = nil
        isWorkoutActive = false
        AppLogger.logWorkout("Cancelled active workout")
    }

    // MARK: - Computed Properties

    var workoutDuration: String {
        guard let workout = activeWorkout else { return "00:00" }
        let elapsed = Date().timeIntervalSince(workout.startTime)
        let hours = Int(elapsed) / 3600
        let minutes = (Int(elapsed) % 3600) / 60
        let seconds = Int(elapsed) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    var workoutProgress: String {
        guard let workout = activeWorkout else { return "" }
        return "\(workout.completedExercises.count)/\(workout.totalExercises) exercises"
    }

    var canContinueWorkout: Bool {
        return activeWorkout != nil
    }

    var shouldShowContinueButton: Bool {
        return isWorkoutActive && activeWorkout != nil
    }
}