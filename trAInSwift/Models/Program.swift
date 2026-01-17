//
//  Program.swift
//  trAInApp
//
//  Enhanced program data model for multi-week programs with exercise database integration
//

import Foundation

// Represents a multi-week training program
struct Program: Codable, Identifiable {
    let id: String
    let type: ProgramType
    let daysPerWeek: Int
    let sessionDuration: SessionDuration
    let sessions: [ProgramSession] // The repeating pattern of sessions
    let totalWeeks: Int
    let createdDate: Date

    init(id: String = UUID().uuidString,
         type: ProgramType,
         daysPerWeek: Int,
         sessionDuration: SessionDuration,
         sessions: [ProgramSession],
         totalWeeks: Int = 8) {
        self.id = id
        self.type = type
        self.daysPerWeek = daysPerWeek
        self.sessionDuration = sessionDuration
        self.sessions = sessions
        self.totalWeeks = totalWeeks
        self.createdDate = Date()
    }
}

enum ProgramType: String, Codable {
    case fullBody = "Full Body"
    case upperLower = "Upper/Lower"
    case pushPullLegs = "Push/Pull/Legs"

    var description: String {
        switch self {
        case .fullBody:
            return "Full Body"
        case .upperLower:
            return "Upper/Lower Split"
        case .pushPullLegs:
            return "Push/Pull/Legs Split"
        }
    }
}

enum SessionDuration: String, Codable {
    case short = "30-45 min"
    case medium = "45-60 min"
    case long = "60-90 min"

    var minutes: ClosedRange<Int> {
        switch self {
        case .short: return 30...45
        case .medium: return 45...60
        case .long: return 60...90
        }
    }
}

// A single session in the program (e.g., "Push Day" or "Upper Day")
struct ProgramSession: Codable, Identifiable {
    let id: String
    let dayName: String // "Push", "Pull", "Legs", "Upper", "Lower", "Full Body"
    let exercises: [ProgramExercise]

    init(id: String = UUID().uuidString, dayName: String, exercises: [ProgramExercise]) {
        self.id = id
        self.dayName = dayName
        self.exercises = exercises
    }
}

// An exercise in the program with sets/reps prescription
struct ProgramExercise: Codable, Identifiable {
    let id: String
    let exerciseId: String // Links to ExerciseDatabase
    let exerciseName: String
    let sets: Int
    let repRange: String // e.g., "8-12"
    let restSeconds: Int
    let primaryMuscle: String
    let equipmentType: String
    let complexityLevel: Int  // 0-2, used for sorting exercises in session

    init(exerciseId: String,
         exerciseName: String,
         sets: Int,
         repRange: String,
         restSeconds: Int,
         primaryMuscle: String,
         equipmentType: String,
         complexityLevel: Int = 2) {
        self.id = UUID().uuidString
        self.exerciseId = exerciseId
        self.exerciseName = exerciseName
        self.sets = sets
        self.repRange = repRange
        self.restSeconds = restSeconds
        self.primaryMuscle = primaryMuscle
        self.equipmentType = equipmentType
        self.complexityLevel = complexityLevel
    }

    var repsMin: Int {
        let components = repRange.split(separator: "-")
        return Int(components.first ?? "0") ?? 0
    }

    var repsMax: Int {
        let components = repRange.split(separator: "-")
        return Int(components.last ?? "0") ?? 0
    }
}
