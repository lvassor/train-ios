//
//  User.swift
//  trAInSwift
//
//  Legacy User model - DEPRECATED
//  Now using Core Data UserProfile entity instead
//  Kept for backward compatibility during migration
//

import Foundation

// DEPRECATED: Use Core Data UserProfile entity instead
// This struct is kept only for compatibility with existing code
// that hasn't been migrated yet
struct User: Codable, Identifiable {
    let id: String
    let email: String
    // Password removed - now stored in Keychain
    var questionnaireData: QuestionnaireData?
    var currentProgram: UserProgram?
    var workoutHistory: [WorkoutSession]
    var createdAt: Date
    var lastLoginAt: Date

    init(id: String = UUID().uuidString, email: String) {
        self.id = id
        self.email = email
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
