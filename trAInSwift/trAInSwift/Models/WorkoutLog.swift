//
//  WorkoutLog.swift
//  trAInApp
//
//  Simplified workout logging structures
//

import Foundation

struct SetLog: Codable, Identifiable {
    var id = UUID()
    var weight: Double
    var reps: Int
    var completed: Bool = false

    enum CodingKeys: String, CodingKey {
        case weight, reps, completed
    }
}

struct ExerciseLog: Codable, Identifiable {
    var id = UUID()
    var sets: [SetLog]
    var notes: String = ""
    var completed: Bool = false

    enum CodingKeys: String, CodingKey {
        case sets, notes, completed
    }
}

struct SessionLog: Codable, Identifiable {
    var id = UUID()
    let sessionId: String
    let weekNumber: Int
    var exercises: [ExerciseLog]
    var completed: Bool = false
    let timestamp: Date

    enum CodingKeys: String, CodingKey {
        case sessionId, weekNumber, exercises, completed, timestamp
    }
}
