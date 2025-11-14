//
//  WorkoutSession.swift
//  trAInApp
//
//  Workout session logging and tracking
//

import Foundation

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
struct LoggedSet: Codable, Identifiable {
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
