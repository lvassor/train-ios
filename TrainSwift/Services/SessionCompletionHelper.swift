//
//  SessionCompletionHelper.swift
//  TrainSwift
//
//  Shared helpers for session completion tracking (deduplicated from DashboardView)
//

import Foundation
import CoreData

enum SessionCompletionHelper {

    /// Sessions completed this calendar week (Monday-Sunday)
    /// Weekly logic automatically resets every Monday
    static func sessionsCompletedThisWeek(userId: UUID) -> [CDWorkoutSession] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today)
        let daysFromMonday = (weekday == 1) ? 6 : weekday - 2

        guard let weekStart = calendar.date(byAdding: .day, value: -daysFromMonday, to: today),
              let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) else { return [] }

        let fetchRequest: NSFetchRequest<CDWorkoutSession> = CDWorkoutSession.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "userId == %@ AND completedAt >= %@ AND completedAt < %@",
            userId as CVarArg, weekStart as NSDate, weekEnd as NSDate
        )

        return (try? PersistenceController.shared.container.viewContext.fetch(fetchRequest)) ?? []
    }

    /// Check if a specific session index is completed this week
    /// Accounts for duplicate session names (e.g. two "Push" days)
    static func isSessionCompleted(
        sessionIndex: Int,
        sessions: [ProgramSession],
        completedSessions: [CDWorkoutSession]
    ) -> Bool {
        guard sessionIndex < sessions.count else { return false }

        let sessionName = sessions[sessionIndex].dayName
        let priorCount = sessions.prefix(sessionIndex).filter { $0.dayName == sessionName }.count
        let completedCount = completedSessions.filter { $0.sessionName == sessionName }.count

        return completedCount > priorCount
    }

    /// Calculate consecutive-day workout streak
    static func calculateStreak(userId: UUID) -> Int {
        let fetchRequest: NSFetchRequest<CDWorkoutSession> = CDWorkoutSession.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "userId == %@", userId as CVarArg
        )
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "completedAt", ascending: false)]

        do {
            let sessions = try PersistenceController.shared.container.viewContext.fetch(fetchRequest)

            var streak = 0
            var currentDate = Calendar.current.startOfDay(for: Date())

            for session in sessions {
                guard let sessionDate = session.completedAt else { continue }
                let normalizedSessionDate = Calendar.current.startOfDay(for: sessionDate)

                if Calendar.current.isDate(normalizedSessionDate, inSameDayAs: currentDate) {
                    streak += 1
                    currentDate = Calendar.current.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
                } else if normalizedSessionDate < currentDate {
                    break
                }
            }

            return streak
        } catch {
            AppLogger.logDatabase("Failed to calculate streak: \(error)", level: .error)
            return 0
        }
    }
}
