//
//  WorkoutSession.swift
//  trAInApp
//
//  Workout session logging and tracking
//

import Foundation
import SwiftUI

// A completed workout session
struct WorkoutSession: Codable, Identifiable {
    let id: String
    let userId: String
    let date: Date
    let sessionType: String // "Push", "Pull", "Legs", "Upper", "Lower", "Full Body"
    let weekNumber: Int
    let exercises: [LoggedExercise]
    let durationMinutes: Int
    let completed: Bool

    init(id: String = UUID().uuidString,
         userId: String,
         date: Date = Date(),
         sessionType: String,
         weekNumber: Int,
         exercises: [LoggedExercise],
         durationMinutes: Int,
         completed: Bool = false) {
        self.id = id
        self.userId = userId
        self.date = date
        self.sessionType = sessionType
        self.weekNumber = weekNumber
        self.exercises = exercises
        self.durationMinutes = durationMinutes
        self.completed = completed
    }

    var totalSets: Int {
        exercises.reduce(0) { $0 + $1.sets.count }
    }

    var completedSets: Int {
        exercises.reduce(0) { total, exercise in
            total + exercise.sets.filter { $0.reps > 0 }.count
        }
    }
}

// A logged exercise within a session
struct LoggedExercise: Codable, Identifiable {
    let id: String
    let exerciseName: String
    var sets: [LoggedSet]
    var notes: String

    init(id: String = UUID().uuidString,
         exerciseName: String,
         sets: [LoggedSet],
         notes: String = "") {
        self.id = id
        self.exerciseName = exerciseName
        self.sets = sets
        self.notes = notes
    }
}

// A single logged set
struct LoggedSet: Codable, Identifiable, Equatable {
    let id: String
    var reps: Int
    var weight: Double // in kg or lbs
    var completed: Bool

    init(id: String = UUID().uuidString,
         reps: Int = 0,
         weight: Double = 0,
         completed: Bool = false) {
        self.id = id
        self.reps = reps
        self.weight = weight
        self.completed = completed
    }
}

// MARK: - Progression Prompt Evaluation

/// Prompt types for workout progression feedback
enum PromptType {
    case regression
    case consistency
    case progression

    var color: Color {
        switch self {
        case .regression: return .red
        case .consistency: return .orange
        case .progression: return .green
        }
    }

    var icon: String {
        switch self {
        case .regression: return "💪"
        case .consistency: return "🎯"
        case .progression: return "🎉"
        }
    }

    var title: String {
        switch self {
        case .regression: return "Great effort today!"
        case .consistency: return "You're doing great!"
        case .progression: return "Excellent work!"
        }
    }

    var subtitle: String {
        switch self {
        case .regression: return "Try choosing a weight that allows you to hit the target range for all sets"
        case .consistency: return "Try to hit the top end of the range or exceed it for all sets"
        case .progression: return "You hit or exceeded the top end for your first two sets! Time to increase weight next session"
        }
    }
}

extension LoggedExercise {
    /// Evaluate progression prompt based on completed sets vs target range
    /// - Parameters:
    ///   - targetMin: Minimum reps in target range (e.g., 8 in "8-12")
    ///   - targetMax: Maximum reps in target range (e.g., 12 in "8-12")
    /// - Returns: PromptType if all sets completed, nil otherwise
    func evaluatePrompt(targetMin: Int, targetMax: Int) -> PromptType? {
        // Only show prompt when at least 3 sets completed (reps > 0)
        let completedSets = sets.filter { $0.reps > 0 }
        guard completedSets.count >= 3 else {
            return nil
        }

        let set1Reps = completedSets[0].reps
        let set2Reps = completedSets[1].reps
        let set3Reps = completedSets[2].reps

        // REGRESSION: First 2 sets below minimum
        if set1Reps < targetMin || set2Reps < targetMin {
            return .regression
        }

        // PROGRESSION: First 2 at/above max, 3rd in range
        if set1Reps >= targetMax && set2Reps >= targetMax && set3Reps >= targetMin {
            return .progression
        }

        // CONSISTENCY: Strong start, weak finish OR default
        return .consistency
    }
}
