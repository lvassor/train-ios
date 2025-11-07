//
//  WorkoutLog.swift
//  trAInApp
//
//  Created by Claude Code on 2025-10-06.
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

struct ProgrammeProgress: Codable {
    var currentWeek: Int = 1
    var completedSessions: Set<String> = []
    var sessionLogs: [SessionLog] = []

    enum CodingKeys: String, CodingKey {
        case currentWeek, completedSessions, sessionLogs
    }
}
