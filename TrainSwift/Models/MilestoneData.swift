//
//  MilestoneData.swift
//  TrainSwift
//
//  Data models for milestone tracking and achievement system
//

import SwiftUI

// MARK: - Milestone Category

enum MilestoneCategory: String, CaseIterable, Codable {
    case progression = "Progression"
    case output = "Output"
    case streak = "Streak"

    var color: Color {
        switch self {
        case .progression: return Color(red: 241/255, green: 188/255, blue: 80/255)  // Gold
        case .output: return Color(red: 122/255, green: 221/255, blue: 143/255)       // Green
        case .streak: return Color(red: 239/255, green: 143/255, blue: 102/255)       // Orange
        }
    }

    var icon: String {
        switch self {
        case .progression: return "chart.line.uptrend.xyaxis"
        case .output: return "dumbbell.fill"
        case .streak: return "flame.fill"
        }
    }
}

// MARK: - Milestone Definition

struct MilestoneDefinition: Identifiable {
    let id: String
    let title: String
    let category: MilestoneCategory
    let threshold: Double
    let unit: String

    /// Returns a description like "5 / 10 PBs"
    func progressDescription(current: Double) -> String {
        let currentInt = Int(current)
        let thresholdInt = Int(threshold)
        return "\(currentInt) / \(thresholdInt) \(unit)"
    }
}

// MARK: - Milestone Progress

struct MilestoneProgress: Identifiable {
    let id: String
    let definition: MilestoneDefinition
    let currentValue: Double
    let achievedDate: Date?

    var progress: Double {
        min(currentValue / definition.threshold, 1.0)
    }

    var isCompleted: Bool {
        currentValue >= definition.threshold
    }

    var title: String { definition.title }
    var category: MilestoneCategory { definition.category }
}

// MARK: - Recent PB

struct RecentPB: Identifiable {
    let id = UUID()
    let exerciseName: String
    let previousWeight: Double
    let newWeight: Double
    let date: Date
}

// MARK: - Top Stats

struct MilestoneTopStats {
    let pbsAchieved: Int
    let workoutsCompleted: Int
    let progressionStreak: Int
}

// MARK: - All Milestone Definitions

struct MilestoneDefinitions {

    // MARK: Progression Milestones (Gold)

    static let progression: [MilestoneDefinition] = [
        MilestoneDefinition(id: "first_pb", title: "First PB", category: .progression, threshold: 1, unit: "PBs"),
        MilestoneDefinition(id: "5_pbs", title: "5 Total PBs", category: .progression, threshold: 5, unit: "PBs"),
        MilestoneDefinition(id: "10_pbs", title: "10 Total PBs", category: .progression, threshold: 10, unit: "PBs"),
        MilestoneDefinition(id: "25_pbs", title: "25 Total PBs", category: .progression, threshold: 25, unit: "PBs"),
        MilestoneDefinition(id: "50_pbs", title: "50 Total PBs", category: .progression, threshold: 50, unit: "PBs"),
        MilestoneDefinition(id: "pbs_3_lifts", title: "PBs in 3 Lifts", category: .progression, threshold: 3, unit: "lifts"),
        MilestoneDefinition(id: "pbs_5_lifts", title: "PBs in 5 Lifts", category: .progression, threshold: 5, unit: "lifts"),
        MilestoneDefinition(id: "pbs_10_lifts", title: "PBs in 10 Lifts", category: .progression, threshold: 10, unit: "lifts"),
        MilestoneDefinition(id: "first_cycle", title: "First Program Cycle", category: .progression, threshold: 1, unit: "cycles"),
        MilestoneDefinition(id: "second_cycle", title: "Second Program Cycle", category: .progression, threshold: 2, unit: "cycles"),
        MilestoneDefinition(id: "4_weeks_logged", title: "4 Weeks Logged", category: .progression, threshold: 4, unit: "weeks"),
        MilestoneDefinition(id: "8_weeks_logged", title: "8 Weeks Logged", category: .progression, threshold: 8, unit: "weeks"),
        MilestoneDefinition(id: "12_weeks_logged", title: "12 Weeks Logged", category: .progression, threshold: 12, unit: "weeks"),
    ]

    // MARK: Output Milestones (Green)

    static let output: [MilestoneDefinition] = [
        MilestoneDefinition(id: "first_100_reps", title: "First 100 Reps", category: .output, threshold: 100, unit: "reps"),
        MilestoneDefinition(id: "1000_reps", title: "1,000 Total Reps", category: .output, threshold: 1000, unit: "reps"),
        MilestoneDefinition(id: "5000_reps", title: "5,000 Total Reps", category: .output, threshold: 5000, unit: "reps"),
        MilestoneDefinition(id: "10000_reps", title: "10,000 Total Reps", category: .output, threshold: 10000, unit: "reps"),
        MilestoneDefinition(id: "first_50_sets", title: "First 50 Sets", category: .output, threshold: 50, unit: "sets"),
        MilestoneDefinition(id: "500_sets", title: "500 Total Sets", category: .output, threshold: 500, unit: "sets"),
        MilestoneDefinition(id: "1000_sets", title: "1,000 Total Sets", category: .output, threshold: 1000, unit: "sets"),
        MilestoneDefinition(id: "first_workout", title: "First Workout", category: .output, threshold: 1, unit: "workouts"),
        MilestoneDefinition(id: "10_workouts", title: "10 Workouts", category: .output, threshold: 10, unit: "workouts"),
        MilestoneDefinition(id: "25_workouts", title: "25 Workouts", category: .output, threshold: 25, unit: "workouts"),
        MilestoneDefinition(id: "50_workouts", title: "50 Workouts", category: .output, threshold: 50, unit: "workouts"),
        MilestoneDefinition(id: "100_workouts", title: "100 Workouts", category: .output, threshold: 100, unit: "workouts"),
        MilestoneDefinition(id: "first_1000kg", title: "1,000 kg Lifted", category: .output, threshold: 1000, unit: "kg"),
        MilestoneDefinition(id: "10000kg", title: "10,000 kg Lifted", category: .output, threshold: 10000, unit: "kg"),
        MilestoneDefinition(id: "50000kg", title: "50,000 kg Lifted", category: .output, threshold: 50000, unit: "kg"),
        MilestoneDefinition(id: "100000kg", title: "100,000 kg Lifted", category: .output, threshold: 100000, unit: "kg"),
    ]

    // MARK: Streak / Consistency Milestones (Orange)

    static let streak: [MilestoneDefinition] = [
        MilestoneDefinition(id: "2_week_streak", title: "2-Week Streak", category: .streak, threshold: 2, unit: "weeks"),
        MilestoneDefinition(id: "4_week_streak", title: "4-Week Streak", category: .streak, threshold: 4, unit: "weeks"),
        MilestoneDefinition(id: "8_week_streak", title: "8-Week Streak", category: .streak, threshold: 8, unit: "weeks"),
        MilestoneDefinition(id: "12_week_streak", title: "12-Week Streak", category: .streak, threshold: 12, unit: "weeks"),
        MilestoneDefinition(id: "first_full_week", title: "First Full Week", category: .streak, threshold: 1, unit: "weeks"),
        MilestoneDefinition(id: "4_full_weeks", title: "4 Full Weeks", category: .streak, threshold: 4, unit: "weeks"),
        MilestoneDefinition(id: "8_full_weeks", title: "8 Full Weeks", category: .streak, threshold: 8, unit: "weeks"),
        MilestoneDefinition(id: "4_consistent_weeks", title: "4 Consistent Weeks", category: .streak, threshold: 4, unit: "weeks"),
        MilestoneDefinition(id: "8_consistent_weeks", title: "8 Consistent Weeks", category: .streak, threshold: 8, unit: "weeks"),
        MilestoneDefinition(id: "12_consistent_weeks", title: "12 Consistent Weeks", category: .streak, threshold: 12, unit: "weeks"),
    ]

    static var all: [MilestoneDefinition] {
        progression + output + streak
    }
}
