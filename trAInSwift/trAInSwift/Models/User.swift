//
//  User.swift
//  trAInApp
//
//  User authentication and profile data model
//

import Foundation

struct User: Codable, Identifiable {
    let id: String
    let email: String
    var password: String // Stored as plain text for MVP (offline only)
    var questionnaireData: QuestionnaireData?
    var currentProgram: UserProgram?
    var workoutHistory: [WorkoutSession]
    var createdAt: Date
    var lastLoginAt: Date

    init(id: String = UUID().uuidString, email: String, password: String) {
        self.id = id
        self.email = email
        self.password = password
        self.questionnaireData = nil
        self.currentProgram = nil
        self.workoutHistory = []
        self.createdAt = Date()
        self.lastLoginAt = Date()
    }
}

// Wrapper for program with user-specific tracking
struct UserProgram: Codable {
    let id: String
    let program: Program
    let startDate: Date
    var currentWeek: Int
    var currentSessionIndex: Int // Which session in the rotation is next
    var completedSessions: Set<String> // "week1-session0", "week1-session1", etc.

    init(program: Program, startDate: Date = Date()) {
        self.id = UUID().uuidString
        self.program = program
        self.startDate = startDate
        self.currentWeek = 1
        self.currentSessionIndex = 0
        self.completedSessions = []
    }

    var nextSessionType: String {
        guard currentSessionIndex < program.sessions.count else {
            return program.sessions.first?.dayName ?? "Session"
        }
        return program.sessions[currentSessionIndex].dayName
    }

    var totalWorkoutsCompleted: Int {
        completedSessions.count
    }

    mutating func completeSession() {
        let sessionId = "week\(currentWeek)-session\(currentSessionIndex)"
        completedSessions.insert(sessionId)

        // Move to next session
        currentSessionIndex += 1

        // If we've completed all sessions in the week, move to next week
        if currentSessionIndex >= program.sessions.count {
            currentWeek += 1
            currentSessionIndex = 0
        }
    }
}
