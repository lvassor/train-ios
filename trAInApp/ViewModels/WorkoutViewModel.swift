//
//  WorkoutViewModel.swift
//  trAInApp
//
//  Created by Claude Code on 2025-10-06.
//

import Foundation
import SwiftUI

class WorkoutViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var questionnaireData = QuestionnaireData()
    @Published var currentProgramme: Programme?
    @Published var programmeProgress = ProgrammeProgress()
    @Published var currentSessionLog: SessionLog?
    @Published var showingCompletionModal = false
    @Published var completionMessage: PromptFeedback?

    // MARK: - Hardcoded Programme Data
    private let hardcodedProgrammeJSON = """
    {
      "name": "Intermediate Push/Pull/Legs",
      "days": {
        "1": {
          "name": "Push (Chest, Shoulders, Triceps)",
          "exercises": [
            { "name": "Bench Press", "icon": "🏋️", "target": "Chest, Triceps", "sets": 3, "repsMin": 6, "repsMax": 8 },
            { "name": "Overhead Press", "icon": "🏋️‍♀️", "target": "Shoulders", "sets": 3, "repsMin": 6, "repsMax": 8 },
            { "name": "Incline Dumbbell Press", "icon": "📐", "target": "Upper Chest", "sets": 3, "repsMin": 8, "repsMax": 10 },
            { "name": "Dumbbell Lateral Raise", "icon": "🤲", "target": "Side Delts", "sets": 3, "repsMin": 12, "repsMax": 15 },
            { "name": "Close Grip Bench Press", "icon": "🏋️", "target": "Triceps", "sets": 3, "repsMin": 8, "repsMax": 10 },
            { "name": "Overhead Tricep Extension", "icon": "💪", "target": "Triceps", "sets": 3, "repsMin": 10, "repsMax": 12 }
          ]
        },
        "2": {
          "name": "Pull (Back, Biceps)",
          "exercises": [
            { "name": "Deadlift", "icon": "🏋️", "target": "Back, Hamstrings", "sets": 3, "repsMin": 5, "repsMax": 6 },
            { "name": "Pull-up", "icon": "⬆️", "target": "Back, Biceps", "sets": 3, "repsMin": 6, "repsMax": 10 },
            { "name": "Bent Over Row", "icon": "🚣", "target": "Back, Biceps", "sets": 3, "repsMin": 8, "repsMax": 10 },
            { "name": "Seated Cable Row", "icon": "🪑", "target": "Back, Biceps", "sets": 3, "repsMin": 10, "repsMax": 12 },
            { "name": "Barbell Curl", "icon": "💪", "target": "Biceps", "sets": 3, "repsMin": 8, "repsMax": 10 },
            { "name": "Hammer Curl", "icon": "🔨", "target": "Biceps", "sets": 3, "repsMin": 10, "repsMax": 12 }
          ]
        },
        "3": {
          "name": "Legs (Quads, Hamstrings, Glutes, Calves)",
          "exercises": [
            { "name": "Squat", "icon": "🦵", "target": "Legs, Glutes", "sets": 3, "repsMin": 6, "repsMax": 8 },
            { "name": "Romanian Deadlift", "icon": "🏋️", "target": "Hamstrings, Glutes", "sets": 3, "repsMin": 8, "repsMax": 10 },
            { "name": "Bulgarian Split Squat", "icon": "🚶", "target": "Legs, Glutes", "sets": 3, "repsMin": 10, "repsMax": 12 },
            { "name": "Leg Curl", "icon": "🦵", "target": "Hamstrings", "sets": 3, "repsMin": 12, "repsMax": 15 },
            { "name": "Leg Extension", "icon": "🦵", "target": "Quadriceps", "sets": 3, "repsMin": 12, "repsMax": 15 },
            { "name": "Standing Calf Raise", "icon": "👠", "target": "Calves", "sets": 3, "repsMin": 15, "repsMax": 20 }
          ]
        }
      }
    }
    """

    // MARK: - Initialization
    init() {
        loadProgramme()
        loadProgress()
    }

    // MARK: - Programme Management
    func loadProgramme() {
        let decoder = JSONDecoder()
        guard let data = hardcodedProgrammeJSON.data(using: .utf8),
              let programme = try? decoder.decode(Programme.self, from: data) else {
            print("Failed to load programme")
            return
        }
        currentProgramme = programme
    }

    func completeQuestionnaire() {
        // For MVP, always return intermediate-3day programme
        loadProgramme()
    }

    // MARK: - Session Management
    func startSession(weekNumber: Int, sessionKey: String) {
        guard let programme = currentProgramme,
              let session = programme.days[sessionKey] else { return }

        let exercises = session.exercises.map { exercise in
            let sets = (0..<exercise.sets).map { _ in
                SetLog(weight: 0, reps: 0, completed: false)
            }
            return ExerciseLog(sets: sets, notes: "", completed: false)
        }

        currentSessionLog = SessionLog(
            sessionId: sessionKey,
            weekNumber: weekNumber,
            exercises: exercises,
            completed: false,
            timestamp: Date()
        )
    }

    func updateSet(exerciseIndex: Int, setIndex: Int, weight: Double, reps: Int) {
        guard var sessionLog = currentSessionLog else { return }
        sessionLog.exercises[exerciseIndex].sets[setIndex].weight = weight
        sessionLog.exercises[exerciseIndex].sets[setIndex].reps = reps
        currentSessionLog = sessionLog
    }

    func markSetCompleted(exerciseIndex: Int, setIndex: Int) {
        guard var sessionLog = currentSessionLog else { return }
        sessionLog.exercises[exerciseIndex].sets[setIndex].completed = true
        currentSessionLog = sessionLog
    }

    func updateExerciseNotes(exerciseIndex: Int, notes: String) {
        guard var sessionLog = currentSessionLog else { return }
        sessionLog.exercises[exerciseIndex].notes = notes
        currentSessionLog = sessionLog
    }

    func completeExercise(exerciseIndex: Int) -> PromptFeedback? {
        guard var sessionLog = currentSessionLog,
              let programme = currentProgramme,
              let session = programme.days[sessionLog.sessionId] else { return nil }

        let exercise = session.exercises[exerciseIndex]
        let exerciseLog = sessionLog.exercises[exerciseIndex]

        sessionLog.exercises[exerciseIndex].completed = true
        currentSessionLog = sessionLog

        return evaluatePromptTier(exercise: exercise, exerciseLog: exerciseLog)
    }

    func completeSession() {
        guard var sessionLog = currentSessionLog else { return }
        sessionLog.completed = true

        let sessionIdentifier = "week\(sessionLog.weekNumber)-session\(sessionLog.sessionId)"
        programmeProgress.completedSessions.insert(sessionIdentifier)
        programmeProgress.sessionLogs.append(sessionLog)

        saveProgress()
        currentSessionLog = nil
    }

    // MARK: - Progression Feedback Logic
    func evaluatePromptTier(exercise: Exercise, exerciseLog: ExerciseLog) -> PromptFeedback {
        let completedSets = exerciseLog.sets.filter { $0.reps > 0 }

        guard completedSets.count >= 3 else {
            return PromptFeedback(type: .consistency, title: "Keep it up!", message: "Complete all sets to see your progress")
        }

        let set1Reps = completedSets[0].reps
        let set2Reps = completedSets[1].reps
        let set3Reps = completedSets[2].reps

        // REGRESS: Either of first 2 sets fall below range
        if set1Reps < exercise.repsMin || set2Reps < exercise.repsMin {
            return PromptFeedback(
                type: .regression,
                title: "Great effort today!",
                message: "Try choosing a weight that allows you to hit the target range for all sets"
            )
        }

        // PROGRESS: First 2 sets at or above max, 3rd set in range
        if set1Reps >= exercise.repsMax && set2Reps >= exercise.repsMax && set3Reps >= exercise.repsMin {
            return PromptFeedback(
                type: .progression,
                title: "Excellent! You hit or exceeded the top end for your first two sets!",
                message: "Time to increase the weight next session"
            )
        }

        // CONSISTENCY: Everything else
        return PromptFeedback(
            type: .consistency,
            title: "You're doing great!",
            message: "Try to hit the top end of the range or exceed it for all sets"
        )
    }

    // MARK: - Progress Persistence
    func saveProgress() {
        if let encoded = try? JSONEncoder().encode(programmeProgress) {
            UserDefaults.standard.set(encoded, forKey: "programmeProgress")
        }
    }

    func loadProgress() {
        if let data = UserDefaults.standard.data(forKey: "programmeProgress"),
           let decoded = try? JSONDecoder().decode(ProgrammeProgress.self, from: data) {
            programmeProgress = decoded
        }
    }

    func isSessionCompleted(weekNumber: Int, sessionKey: String) -> Bool {
        let identifier = "week\(weekNumber)-session\(sessionKey)"
        return programmeProgress.completedSessions.contains(identifier)
    }
}

// MARK: - Supporting Types
struct PromptFeedback {
    enum FeedbackType {
        case regression, consistency, progression
    }

    let type: FeedbackType
    let title: String
    let message: String
}
