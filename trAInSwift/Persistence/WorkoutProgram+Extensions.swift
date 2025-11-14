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
        guard let data = exercisesData,
              let sessions = try? JSONDecoder().decode([ProgramSession].self, from: data) else {
            return nil
        }

        let programType: ProgramType
        switch split {
        case "Full Body": programType = .fullBody
        case "Upper/Lower": programType = .upperLower
        case "Push/Pull/Legs": programType = .pushPullLegs
        default: programType = .fullBody
        }

        let duration: SessionDuration
        switch sessionDuration {
        case "30-45 min": duration = .short
        case "45-60 min": duration = .medium
        case "60-90 min": duration = .long
        default: duration = .medium
        }

        return Program(
            type: programType,
            daysPerWeek: Int(daysPerWeek),
            sessionDuration: duration,
            sessions: sessions,
            totalWeeks: Int(totalWeeks)
        )
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
            if let encoded = try? JSONEncoder().encode(newValue) {
                completedSessionsData = encoded
            }
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
