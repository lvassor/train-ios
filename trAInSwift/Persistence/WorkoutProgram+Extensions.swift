//
//  WorkoutProgram+Extensions.swift
//  trAInSwift
//
//  Core Data entity extensions for WorkoutProgram
//

import CoreData
import Foundation

// MARK: - Program Cache

/// Cache for decoded Program objects to avoid repeated JSON parsing
/// Key: WorkoutProgram objectID hash, Value: decoded Program
private var programCache = NSCache<NSNumber, ProgramWrapper>()

/// Wrapper class for Program since NSCache requires reference types
private class ProgramWrapper {
    let program: Program
    init(_ program: Program) {
        self.program = program
    }
}

extension WorkoutProgram {

    // MARK: - Cache Key

    private var cacheKey: NSNumber {
        NSNumber(value: objectID.hash)
    }

    // MARK: - Fetch Methods

    static func fetchCurrent(forUserId userId: UUID, context: NSManagedObjectContext) -> WorkoutProgram? {
        let request = WorkoutProgram.fetchRequest()
        request.predicate = NSPredicate(format: "userId == %@ AND isActive == YES", userId as CVarArg)
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

    static func fetchAll(forUserId userId: UUID, context: NSManagedObjectContext) -> [WorkoutProgram] {
        let request = WorkoutProgram.fetchRequest()
        request.predicate = NSPredicate(format: "userId == %@", userId as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

        do {
            return try context.fetch(request)
        } catch {
            print("❌ Failed to fetch all programs: \(error)")
            return []
        }
    }

    static func fetchInactive(forUserId userId: UUID, context: NSManagedObjectContext) -> [WorkoutProgram] {
        let request = WorkoutProgram.fetchRequest()
        request.predicate = NSPredicate(format: "userId == %@ AND isActive == NO", userId as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

        do {
            return try context.fetch(request)
        } catch {
            print("❌ Failed to fetch inactive programs: \(error)")
            return []
        }
    }

    // MARK: - Create Method

    static func create(userId: UUID, program: Program, context: NSManagedObjectContext) -> WorkoutProgram {
        // Deactivate all existing programs for this user
        let existingPrograms = fetchAll(forUserId: userId, context: context)
        for existingProgram in existingPrograms {
            existingProgram.isActive = false
        }

        // Enforce 2 program limit - delete oldest if we already have 2
        if existingPrograms.count >= 2 {
            // Sort by creation date and remove oldest
            let sortedPrograms = existingPrograms.sorted { $0.createdAt ?? Date.distantPast < $1.createdAt ?? Date.distantPast }
            if let oldestProgram = sortedPrograms.first {
                context.delete(oldestProgram)
                print("🗑️ Deleted oldest program to maintain 2 program limit")
            }
        }

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
        workoutProgram.isActive = true

        // Store exercises as JSON
        if let encoded = try? JSONEncoder().encode(program.sessions) {
            workoutProgram.exercisesData = encoded
        }

        return workoutProgram
    }

    // MARK: - Activation Methods

    func activate(context: NSManagedObjectContext) {
        // Deactivate all other programs for this user
        let allPrograms = WorkoutProgram.fetchAll(forUserId: userId, context: context)
        for program in allPrograms where program != self {
            program.isActive = false
        }

        // Activate this program
        isActive = true
        print("✅ Activated program: \(name ?? "Unknown")")
    }

    // MARK: - Helper Methods

    /// Returns the decoded Program, using cache to avoid repeated JSON parsing
    func getProgram() -> Program? {
        // Check cache first
        if let cached = programCache.object(forKey: cacheKey) {
            return cached.program
        }

        guard let data = exercisesData else {
            #if DEBUG
            print("❌ getProgram() failed: exercisesData is nil")
            #endif
            return nil
        }

        guard let sessions = try? JSONDecoder().decode([ProgramSession].self, from: data) else {
            #if DEBUG
            print("❌ getProgram() failed: Could not decode sessions from JSON")
            #endif
            return nil
        }

        let programType: ProgramType
        switch split {
        case "Full Body": programType = .fullBody
        case "Upper/Lower": programType = .upperLower
        case "Push/Pull/Legs": programType = .pushPullLegs
        default:
            programType = .fullBody
        }

        let duration: SessionDuration
        switch sessionDuration {
        case "30-45 min": duration = .short
        case "45-60 min": duration = .medium
        case "60-90 min": duration = .long
        default:
            duration = .medium
        }

        let program = Program(
            type: programType,
            daysPerWeek: Int(daysPerWeek),
            sessionDuration: duration,
            sessions: sessions,
            totalWeeks: Int(totalWeeks)
        )

        // Cache the result
        programCache.setObject(ProgramWrapper(program), forKey: cacheKey)

        #if DEBUG
        print("✅ getProgram() decoded and cached: \(programType.description), \(sessions.count) sessions")
        #endif

        return program
    }

    /// Invalidates the cached program (call when exercisesData changes)
    func invalidateProgramCache() {
        programCache.removeObject(forKey: cacheKey)
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
