//
//  WorkoutProgram+Extensions.swift
//  trAInSwift
//
//  Core Data entity extensions for WorkoutProgram
//

import CoreData
import Foundation

extension WorkoutProgram {

    // MARK: - Fetch Methods

    static func fetchCurrent(forUserId userId: UUID, context: NSManagedObjectContext) -> WorkoutProgram? {
        let request = WorkoutProgram.fetchRequest()
        request.predicate = NSPredicate(format: "userId == %@", userId as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        request.fetchLimit = 1

        do {
            return try context.fetch(request).first
        } catch {
            print("❌ Failed to fetch current program: \(error)")
            return nil
        }
    }

    static func fetch(byId id: UUID, context: NSManagedObjectContext) -> WorkoutProgram? {
        let request = WorkoutProgram.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1

        do {
            return try context.fetch(request).first
        } catch {
            print("❌ Failed to fetch program by ID: \(error)")
            return nil
        }
    }

    // MARK: - Create Method

    static func create(userId: UUID, program: Program, context: NSManagedObjectContext) -> WorkoutProgram {
        let workoutProgram = WorkoutProgram(context: context)
        workoutProgram.id = UUID()
        workoutProgram.userId = userId
        workoutProgram.name = program.type.rawValue
        workoutProgram.split = program.type.rawValue
        workoutProgram.daysPerWeek = Int16(program.daysPerWeek)
        workoutProgram.sessionDuration = program.sessionDuration.rawValue
        workoutProgram.totalWeeks = Int16(program.totalWeeks)
        workoutProgram.createdAt = Date()
        workoutProgram.currentWeek = 1
        workoutProgram.currentSessionIndex = 0
        workoutProgram.completedSessionsData = Data()

        // Store exercises as JSON
        if let encoded = try? JSONEncoder().encode(program.sessions) {
            workoutProgram.exercisesData = encoded
        }

        return workoutProgram
    }

    // MARK: - Helper Methods

    func getProgram() -> Program? {
        guard let data = exercisesData else {
            print("❌ getProgram() failed: exercisesData is nil")
            return nil
        }

        print("✅ exercisesData exists: \(data.count) bytes")

        guard let sessions = try? JSONDecoder().decode([ProgramSession].self, from: data) else {
            print("❌ getProgram() failed: Could not decode sessions from JSON")
            if let jsonString = String(data: data, encoding: .utf8) {
                print("   JSON data: \(jsonString.prefix(200))...")
            }
            return nil
        }

        print("✅ Successfully decoded \(sessions.count) sessions")
        for (index, session) in sessions.enumerated() {
            print("   Session \(index): \(session.dayName) - \(session.exercises.count) exercises")
        }

        let programType: ProgramType
        switch split {
        case "Full Body": programType = .fullBody
        case "Upper/Lower": programType = .upperLower
        case "Push/Pull/Legs": programType = .pushPullLegs
        default:
            print("⚠️ Unknown split type: \(split ?? "nil"), defaulting to Full Body")
            programType = .fullBody
        }

        let duration: SessionDuration
        switch sessionDuration {
        case "30-45 min": duration = .short
        case "45-60 min": duration = .medium
        case "60-90 min": duration = .long
        default:
            print("⚠️ Unknown session duration: \(sessionDuration ?? "nil"), defaulting to medium")
            duration = .medium
        }

        let program = Program(
            type: programType,
            daysPerWeek: Int(daysPerWeek),
            sessionDuration: duration,
            sessions: sessions,
            totalWeeks: Int(totalWeeks)
        )

        print("✅ getProgram() successful: \(programType.description), \(sessions.count) sessions")
        return program
    }

    var completedSessionsSet: Set<String> {
        get {
            guard let data = completedSessionsData,
                  let set = try? JSONDecoder().decode(Set<String>.self, from: data) else {
                return []
            }
            return set
        }
        set {
            willChangeValue(forKey: "completedSessionsData")
            if let encoded = try? JSONEncoder().encode(newValue) {
                completedSessionsData = encoded
            }
            didChangeValue(forKey: "completedSessionsData")
        }
    }

    func completeSession() {
        var completed = completedSessionsSet
        let sessionId = "week\(currentWeek)-session\(currentSessionIndex)"
        completed.insert(sessionId)
        completedSessionsSet = completed

        // Move to next session
        currentSessionIndex += 1

        // If we've completed all sessions in the week, move to next week
        if currentSessionIndex >= daysPerWeek {
            currentWeek += 1
            currentSessionIndex = 0
        }
    }
}
