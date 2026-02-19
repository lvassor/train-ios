//
//  MilestoneService.swift
//  trAInSwift
//
//  Computes milestone progress from workout history
//

import Foundation
import CoreData

class MilestoneService {
    private let authService = AuthService.shared

    // MARK: - Public API

    /// Compute all milestone progress from workout history
    func computeAllMilestones() -> [MilestoneProgress] {
        let sessions = authService.getWorkoutHistory()
        let stats = computeStats(from: sessions)

        return MilestoneDefinitions.all.map { definition in
            let currentValue = currentValue(for: definition, stats: stats)
            let achievedDate = stats.achievedDate(for: definition.id, current: currentValue)
            return MilestoneProgress(
                id: definition.id,
                definition: definition,
                currentValue: currentValue,
                achievedDate: achievedDate
            )
        }
    }

    /// Get top stats for the header
    func computeTopStats() -> MilestoneTopStats {
        let sessions = authService.getWorkoutHistory()
        let stats = computeStats(from: sessions)
        return MilestoneTopStats(
            pbsAchieved: stats.totalPBs,
            workoutsCompleted: stats.totalWorkouts,
            progressionStreak: stats.currentProgressionStreak
        )
    }

    /// Get recent PBs across all exercises
    func computeRecentPBs() -> [RecentPB] {
        let sessions = authService.getWorkoutHistory()
        guard sessions.count >= 2 else { return [] }

        var recentPBs: [RecentPB] = []

        // Track all-time max weight per exercise
        var exerciseMaxWeights: [String: Double] = [:]

        // Process sessions chronologically (oldest first)
        let chronological = sessions.reversed()

        for session in chronological {
            let exercises = session.getLoggedExercises()
            let sessionDate = session.completedAt ?? Date()

            for exercise in exercises {
                let maxWeight = exercise.sets
                    .filter { $0.completed }
                    .map { $0.weight }
                    .max() ?? 0

                guard maxWeight > 0 else { continue }

                if let previousMax = exerciseMaxWeights[exercise.exerciseName], maxWeight > previousMax {
                    recentPBs.append(RecentPB(
                        exerciseName: exercise.exerciseName,
                        previousWeight: previousMax,
                        newWeight: maxWeight,
                        date: sessionDate
                    ))
                }

                // Update max
                exerciseMaxWeights[exercise.exerciseName] = max(
                    exerciseMaxWeights[exercise.exerciseName] ?? 0,
                    maxWeight
                )
            }
        }

        // Return most recent first, limit to 10
        return Array(recentPBs.reversed().prefix(10))
    }

    // MARK: - Stats Computation

    private struct WorkoutStats {
        var totalWorkouts: Int = 0
        var totalReps: Int = 0
        var totalSets: Int = 0
        var totalVolume: Double = 0  // kg
        var totalPBs: Int = 0
        var uniquePBExercises: Set<String> = []
        var weeksWithWorkouts: Set<Int> = []  // week numbers from calendar
        var fullTrainingWeeks: Int = 0
        var consistentWeeks: Int = 0
        var currentProgressionStreak: Int = 0
        var programCycles: Int = 0
        var weekNumbersLogged: Set<Int> = []  // program week numbers
        var sessionDates: [Date] = []
        var daysPerWeekTarget: Int = 3

        func achievedDate(for milestoneId: String, current: Double) -> Date? {
            // Simplified: if completed, use most recent session date
            guard let lastDate = sessionDates.first else { return nil }
            let definition = MilestoneDefinitions.all.first { $0.id == milestoneId }
            guard let threshold = definition?.threshold, current >= threshold else { return nil }
            return lastDate
        }
    }

    private func computeStats(from sessions: [CDWorkoutSession]) -> WorkoutStats {
        var stats = WorkoutStats()
        stats.totalWorkouts = sessions.count
        stats.sessionDates = sessions.compactMap { $0.completedAt }

        // Get program info for cycles and target days
        if let program = authService.getCurrentProgram() {
            stats.daysPerWeekTarget = Int(program.daysPerWeek)
            let totalWeeks = Int(program.totalWeeks)
            let currentWeek = Int(program.currentWeek)
            if totalWeeks > 0 {
                stats.programCycles = max(0, (currentWeek - 1) / totalWeeks)
            }
        }

        // Track per-exercise max weights for PB detection
        var exerciseMaxWeights: [String: Double] = [:]

        // Process chronologically (oldest first)
        let chronological = Array(sessions.reversed())

        for session in chronological {
            let exercises = session.getLoggedExercises()

            for exercise in exercises {
                let completedSets = exercise.sets.filter { $0.completed }
                stats.totalSets += completedSets.count
                stats.totalReps += completedSets.reduce(0) { $0 + $1.reps }
                stats.totalVolume += completedSets.reduce(0) { $0 + ($1.weight * Double($1.reps)) }

                // PB detection
                let maxWeight = completedSets.map { $0.weight }.max() ?? 0
                if maxWeight > 0 {
                    if let previousMax = exerciseMaxWeights[exercise.exerciseName], maxWeight > previousMax {
                        stats.totalPBs += 1
                        stats.uniquePBExercises.insert(exercise.exerciseName)
                    }
                    exerciseMaxWeights[exercise.exerciseName] = max(
                        exerciseMaxWeights[exercise.exerciseName] ?? 0,
                        maxWeight
                    )
                }
            }

            // Track program week numbers
            stats.weekNumbersLogged.insert(Int(session.weekNumber))
        }

        // Compute week-based stats
        computeWeeklyStats(sessions: sessions, stats: &stats)

        return stats
    }

    private func computeWeeklyStats(sessions: [CDWorkoutSession], stats: inout WorkoutStats) {
        let calendar = Calendar.current

        // Group sessions by calendar week
        var weekSessions: [Int: [CDWorkoutSession]] = [:]
        for session in sessions {
            guard let date = session.completedAt else { continue }
            let weekOfYear = calendar.component(.weekOfYear, from: date)
            let year = calendar.component(.year, from: date)
            let weekKey = year * 100 + weekOfYear
            weekSessions[weekKey, default: []].append(session)
        }

        // Count full training weeks (met target days)
        let target = max(1, stats.daysPerWeekTarget)
        stats.fullTrainingWeeks = weekSessions.values.filter { $0.count >= target }.count

        // Count consistent weeks (at least 1 session)
        let sortedWeekKeys = weekSessions.keys.sorted()
        var consecutiveWeeks = 0
        var maxConsecutive = 0

        for i in 0..<sortedWeekKeys.count {
            if i == 0 {
                consecutiveWeeks = 1
            } else {
                let prevKey = sortedWeekKeys[i - 1]
                let currKey = sortedWeekKeys[i]
                // Check if weeks are consecutive (handle year boundaries approximately)
                if currKey - prevKey <= 1 || (prevKey % 100 >= 52 && currKey % 100 == 1) {
                    consecutiveWeeks += 1
                } else {
                    consecutiveWeeks = 1
                }
            }
            maxConsecutive = max(maxConsecutive, consecutiveWeeks)
        }
        stats.consistentWeeks = maxConsecutive

        // Current progression streak (consecutive weeks from current week going back)
        let currentWeekKey: Int = {
            let now = Date()
            let week = calendar.component(.weekOfYear, from: now)
            let year = calendar.component(.year, from: now)
            return year * 100 + week
        }()

        var streakCount = 0
        var checkKey = currentWeekKey
        while weekSessions[checkKey] != nil {
            streakCount += 1
            // Go to previous week
            let weekNum = checkKey % 100
            let yearNum = checkKey / 100
            if weekNum <= 1 {
                checkKey = (yearNum - 1) * 100 + 52
            } else {
                checkKey = yearNum * 100 + (weekNum - 1)
            }
        }
        stats.currentProgressionStreak = streakCount
    }

    // MARK: - Value Mapping

    private func currentValue(for definition: MilestoneDefinition, stats: WorkoutStats) -> Double {
        switch definition.id {
        // Progression
        case "first_pb", "5_pbs", "10_pbs", "25_pbs", "50_pbs":
            return Double(stats.totalPBs)
        case "pbs_3_lifts", "pbs_5_lifts", "pbs_10_lifts":
            return Double(stats.uniquePBExercises.count)
        case "first_cycle", "second_cycle":
            return Double(stats.programCycles)
        case "4_weeks_logged", "8_weeks_logged", "12_weeks_logged":
            return Double(stats.weekNumbersLogged.count)

        // Output
        case "first_100_reps", "1000_reps", "5000_reps", "10000_reps":
            return Double(stats.totalReps)
        case "first_50_sets", "500_sets", "1000_sets":
            return Double(stats.totalSets)
        case "first_workout", "10_workouts", "25_workouts", "50_workouts", "100_workouts":
            return Double(stats.totalWorkouts)
        case "first_1000kg", "10000kg", "50000kg", "100000kg":
            return stats.totalVolume

        // Streak
        case "2_week_streak", "4_week_streak", "8_week_streak", "12_week_streak":
            return Double(stats.currentProgressionStreak)
        case "first_full_week", "4_full_weeks", "8_full_weeks":
            return Double(stats.fullTrainingWeeks)
        case "4_consistent_weeks", "8_consistent_weeks", "12_consistent_weeks":
            return Double(stats.consistentWeeks)

        default:
            return 0
        }
    }
}
