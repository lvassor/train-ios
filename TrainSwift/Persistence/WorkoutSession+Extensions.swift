//
//  CDWorkoutSession+Extensions.swift
//  TrainSwift
//
//  Core Data entity extensions for CDWorkoutSession
//

import CoreData
import Foundation

extension CDWorkoutSession {

    // MARK: - Fetch Methods

    static func fetchAll(forUserId userId: UUID, context: NSManagedObjectContext) -> [CDWorkoutSession] {
        let request = CDWorkoutSession.fetchRequest()
        request.predicate = NSPredicate(format: "userId == %@", userId as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(key: "completedAt", ascending: false)]

        do {
            return try context.fetch(request)
        } catch {
            print("❌ Failed to fetch workout sessions: \(error)")
            return []
        }
    }

    static func fetchRecent(forUserId userId: UUID, limit: Int = 10, context: NSManagedObjectContext) -> [CDWorkoutSession] {
        let request = CDWorkoutSession.fetchRequest()
        request.predicate = NSPredicate(format: "userId == %@", userId as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(key: "completedAt", ascending: false)]
        request.fetchLimit = limit

        do {
            return try context.fetch(request)
        } catch {
            print("❌ Failed to fetch recent workout sessions: \(error)")
            return []
        }
    }

    // MARK: - Create Method

    static func create(
        userId: UUID,
        programId: UUID?,
        sessionName: String,
        weekNumber: Int,
        exercises: [LoggedExercise],
        durationMinutes: Int,
        context: NSManagedObjectContext
    ) -> CDWorkoutSession {
        let session = CDWorkoutSession(context: context)
        session.id = UUID()
        session.userId = userId
        session.programId = programId
        session.sessionName = sessionName
        session.weekNumber = Int16(weekNumber)
        session.completedAt = Date()
        session.durationSeconds = Int32(durationMinutes * 60)

        // Store exercises as JSON
        if let encoded = try? JSONEncoder().encode(exercises) {
            session.exercisesData = encoded
        }

        return session
    }

    // MARK: - Helper Methods

    func getLoggedExercises() -> [LoggedExercise] {
        guard let data = exercisesData,
              let exercises = try? JSONDecoder().decode([LoggedExercise].self, from: data) else {
            return []
        }
        return exercises
    }

    var durationMinutes: Int {
        return Int(durationSeconds) / 60
    }

    var formattedDate: String {
        guard let date = completedAt else { return "" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    var formattedDuration: String {
        let minutes = durationMinutes
        if minutes < 60 {
            return "\(minutes) min"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            return "\(hours)h \(mins)m"
        }
    }
}
