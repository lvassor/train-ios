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
        // Total PBs (increments of 5 to 100)
        MilestoneDefinition(id: "first_pb", title: "First PB", category: .progression, threshold: 1, unit: "PBs"),
        MilestoneDefinition(id: "3_pbs", title: "3 Total PBs", category: .progression, threshold: 3, unit: "PBs"),
        MilestoneDefinition(id: "5_pbs", title: "5 Total PBs", category: .progression, threshold: 5, unit: "PBs"),
        MilestoneDefinition(id: "10_pbs", title: "10 Total PBs", category: .progression, threshold: 10, unit: "PBs"),
        MilestoneDefinition(id: "15_pbs", title: "15 Total PBs", category: .progression, threshold: 15, unit: "PBs"),
        MilestoneDefinition(id: "20_pbs", title: "20 Total PBs", category: .progression, threshold: 20, unit: "PBs"),
        MilestoneDefinition(id: "25_pbs", title: "25 Total PBs", category: .progression, threshold: 25, unit: "PBs"),
        MilestoneDefinition(id: "30_pbs", title: "30 Total PBs", category: .progression, threshold: 30, unit: "PBs"),
        MilestoneDefinition(id: "35_pbs", title: "35 Total PBs", category: .progression, threshold: 35, unit: "PBs"),
        MilestoneDefinition(id: "40_pbs", title: "40 Total PBs", category: .progression, threshold: 40, unit: "PBs"),
        MilestoneDefinition(id: "45_pbs", title: "45 Total PBs", category: .progression, threshold: 45, unit: "PBs"),
        MilestoneDefinition(id: "50_pbs", title: "50 Total PBs", category: .progression, threshold: 50, unit: "PBs"),
        MilestoneDefinition(id: "55_pbs", title: "55 Total PBs", category: .progression, threshold: 55, unit: "PBs"),
        MilestoneDefinition(id: "60_pbs", title: "60 Total PBs", category: .progression, threshold: 60, unit: "PBs"),
        MilestoneDefinition(id: "65_pbs", title: "65 Total PBs", category: .progression, threshold: 65, unit: "PBs"),
        MilestoneDefinition(id: "70_pbs", title: "70 Total PBs", category: .progression, threshold: 70, unit: "PBs"),
        MilestoneDefinition(id: "75_pbs", title: "75 Total PBs", category: .progression, threshold: 75, unit: "PBs"),
        MilestoneDefinition(id: "80_pbs", title: "80 Total PBs", category: .progression, threshold: 80, unit: "PBs"),
        MilestoneDefinition(id: "85_pbs", title: "85 Total PBs", category: .progression, threshold: 85, unit: "PBs"),
        MilestoneDefinition(id: "90_pbs", title: "90 Total PBs", category: .progression, threshold: 90, unit: "PBs"),
        MilestoneDefinition(id: "95_pbs", title: "95 Total PBs", category: .progression, threshold: 95, unit: "PBs"),
        MilestoneDefinition(id: "100_pbs", title: "100 Total PBs", category: .progression, threshold: 100, unit: "PBs"),

        // PBs in different lifts (increments of 5 to 50)
        MilestoneDefinition(id: "pbs_3_lifts", title: "PBs in 3 Lifts", category: .progression, threshold: 3, unit: "lifts"),
        MilestoneDefinition(id: "pbs_5_lifts", title: "PBs in 5 Lifts", category: .progression, threshold: 5, unit: "lifts"),
        MilestoneDefinition(id: "pbs_10_lifts", title: "PBs in 10 Lifts", category: .progression, threshold: 10, unit: "lifts"),
        MilestoneDefinition(id: "pbs_15_lifts", title: "PBs in 15 Lifts", category: .progression, threshold: 15, unit: "lifts"),
        MilestoneDefinition(id: "pbs_20_lifts", title: "PBs in 20 Lifts", category: .progression, threshold: 20, unit: "lifts"),
        MilestoneDefinition(id: "pbs_25_lifts", title: "PBs in 25 Lifts", category: .progression, threshold: 25, unit: "lifts"),
        MilestoneDefinition(id: "pbs_30_lifts", title: "PBs in 30 Lifts", category: .progression, threshold: 30, unit: "lifts"),
        MilestoneDefinition(id: "pbs_35_lifts", title: "PBs in 35 Lifts", category: .progression, threshold: 35, unit: "lifts"),
        MilestoneDefinition(id: "pbs_40_lifts", title: "PBs in 40 Lifts", category: .progression, threshold: 40, unit: "lifts"),
        MilestoneDefinition(id: "pbs_45_lifts", title: "PBs in 45 Lifts", category: .progression, threshold: 45, unit: "lifts"),
        MilestoneDefinition(id: "pbs_50_lifts", title: "PBs in 50 Lifts", category: .progression, threshold: 50, unit: "lifts"),

        // PBs in same exercise
        MilestoneDefinition(id: "2_pbs_same_exercise", title: "2 PBs Same Exercise", category: .progression, threshold: 2, unit: "PBs"),
        MilestoneDefinition(id: "3_pbs_same_exercise", title: "3 PBs Same Exercise", category: .progression, threshold: 3, unit: "PBs"),
        MilestoneDefinition(id: "5_pbs_same_exercise", title: "5 PBs Same Exercise", category: .progression, threshold: 5, unit: "PBs"),
        MilestoneDefinition(id: "10_pbs_same_exercise", title: "10 PBs Same Exercise", category: .progression, threshold: 10, unit: "PBs"),
        MilestoneDefinition(id: "15_pbs_same_exercise", title: "15 PBs Same Exercise", category: .progression, threshold: 15, unit: "PBs"),
        MilestoneDefinition(id: "20_pbs_same_exercise", title: "20 PBs Same Exercise", category: .progression, threshold: 20, unit: "PBs"),

        // Load increase milestones
        MilestoneDefinition(id: "first_2_5kg_increase", title: "First 2.5kg Increase", category: .progression, threshold: 1, unit: "increases"),
        MilestoneDefinition(id: "first_5kg_increase", title: "First 5kg Increase", category: .progression, threshold: 1, unit: "increases"),
        MilestoneDefinition(id: "first_10kg_increase", title: "First 10kg Increase", category: .progression, threshold: 1, unit: "increases"),
        MilestoneDefinition(id: "first_20kg_increase", title: "First 20kg Increase", category: .progression, threshold: 1, unit: "increases"),
        MilestoneDefinition(id: "first_double_digit_increase", title: "First Double-Digit Increase", category: .progression, threshold: 1, unit: "increases"),

        // Bodyweight lift milestones
        MilestoneDefinition(id: "first_50kg_lift", title: "First 50kg+ Lift", category: .progression, threshold: 50, unit: "kg"),
        MilestoneDefinition(id: "first_75kg_lift", title: "First 75kg+ Lift", category: .progression, threshold: 75, unit: "kg"),
        MilestoneDefinition(id: "first_100kg_lift", title: "First 100kg+ Lift", category: .progression, threshold: 100, unit: "kg"),
        MilestoneDefinition(id: "first_bodyweight_lift", title: "First Bodyweight Lift", category: .progression, threshold: 1, unit: "lifts"),

        // Weeks/months of training
        MilestoneDefinition(id: "5_weeks_training", title: "5 Weeks of Training", category: .progression, threshold: 5, unit: "weeks"),
        MilestoneDefinition(id: "10_weeks_training", title: "10 Weeks of Training", category: .progression, threshold: 10, unit: "weeks"),
        MilestoneDefinition(id: "15_weeks_training", title: "15 Weeks of Training", category: .progression, threshold: 15, unit: "weeks"),
        MilestoneDefinition(id: "20_weeks_training", title: "20 Weeks of Training", category: .progression, threshold: 20, unit: "weeks"),
        MilestoneDefinition(id: "6_months_training", title: "6 Months of Training", category: .progression, threshold: 26, unit: "weeks"),
        MilestoneDefinition(id: "9_months_training", title: "9 Months of Training", category: .progression, threshold: 39, unit: "weeks"),
        MilestoneDefinition(id: "1_year_training", title: "1 Year of Training", category: .progression, threshold: 52, unit: "weeks"),
    ]

    // MARK: Output Milestones (Green)

    static let output: [MilestoneDefinition] = [
        // Reps logged (100, 250, 500, 1000, 2500, 5000, then increments of 10,000 to 100,000)
        MilestoneDefinition(id: "first_100_reps", title: "First 100 Reps", category: .output, threshold: 100, unit: "reps"),
        MilestoneDefinition(id: "250_reps", title: "250 Reps Logged", category: .output, threshold: 250, unit: "reps"),
        MilestoneDefinition(id: "500_reps", title: "500 Reps Logged", category: .output, threshold: 500, unit: "reps"),
        MilestoneDefinition(id: "1000_reps", title: "1,000 Reps Logged", category: .output, threshold: 1000, unit: "reps"),
        MilestoneDefinition(id: "2500_reps", title: "2,500 Reps Logged", category: .output, threshold: 2500, unit: "reps"),
        MilestoneDefinition(id: "5000_reps", title: "5,000 Reps Logged", category: .output, threshold: 5000, unit: "reps"),
        MilestoneDefinition(id: "10000_reps", title: "10,000 Reps Logged", category: .output, threshold: 10000, unit: "reps"),
        MilestoneDefinition(id: "20000_reps", title: "20,000 Reps Logged", category: .output, threshold: 20000, unit: "reps"),
        MilestoneDefinition(id: "30000_reps", title: "30,000 Reps Logged", category: .output, threshold: 30000, unit: "reps"),
        MilestoneDefinition(id: "40000_reps", title: "40,000 Reps Logged", category: .output, threshold: 40000, unit: "reps"),
        MilestoneDefinition(id: "50000_reps", title: "50,000 Reps Logged", category: .output, threshold: 50000, unit: "reps"),
        MilestoneDefinition(id: "60000_reps", title: "60,000 Reps Logged", category: .output, threshold: 60000, unit: "reps"),
        MilestoneDefinition(id: "70000_reps", title: "70,000 Reps Logged", category: .output, threshold: 70000, unit: "reps"),
        MilestoneDefinition(id: "80000_reps", title: "80,000 Reps Logged", category: .output, threshold: 80000, unit: "reps"),
        MilestoneDefinition(id: "90000_reps", title: "90,000 Reps Logged", category: .output, threshold: 90000, unit: "reps"),
        MilestoneDefinition(id: "100000_reps", title: "100,000 Reps Logged", category: .output, threshold: 100000, unit: "reps"),

        // Sets logged (25, 50, 100, 200, then increments of 100 to 2500)
        MilestoneDefinition(id: "first_25_sets", title: "First 25 Sets", category: .output, threshold: 25, unit: "sets"),
        MilestoneDefinition(id: "50_sets", title: "50 Sets Logged", category: .output, threshold: 50, unit: "sets"),
        MilestoneDefinition(id: "100_sets", title: "100 Sets Logged", category: .output, threshold: 100, unit: "sets"),
        MilestoneDefinition(id: "200_sets", title: "200 Sets Logged", category: .output, threshold: 200, unit: "sets"),
        MilestoneDefinition(id: "300_sets", title: "300 Sets Logged", category: .output, threshold: 300, unit: "sets"),
        MilestoneDefinition(id: "400_sets", title: "400 Sets Logged", category: .output, threshold: 400, unit: "sets"),
        MilestoneDefinition(id: "500_sets", title: "500 Sets Logged", category: .output, threshold: 500, unit: "sets"),
        MilestoneDefinition(id: "600_sets", title: "600 Sets Logged", category: .output, threshold: 600, unit: "sets"),
        MilestoneDefinition(id: "700_sets", title: "700 Sets Logged", category: .output, threshold: 700, unit: "sets"),
        MilestoneDefinition(id: "800_sets", title: "800 Sets Logged", category: .output, threshold: 800, unit: "sets"),
        MilestoneDefinition(id: "900_sets", title: "900 Sets Logged", category: .output, threshold: 900, unit: "sets"),
        MilestoneDefinition(id: "1000_sets", title: "1,000 Sets Logged", category: .output, threshold: 1000, unit: "sets"),
        MilestoneDefinition(id: "1100_sets", title: "1,100 Sets Logged", category: .output, threshold: 1100, unit: "sets"),
        MilestoneDefinition(id: "1200_sets", title: "1,200 Sets Logged", category: .output, threshold: 1200, unit: "sets"),
        MilestoneDefinition(id: "1300_sets", title: "1,300 Sets Logged", category: .output, threshold: 1300, unit: "sets"),
        MilestoneDefinition(id: "1400_sets", title: "1,400 Sets Logged", category: .output, threshold: 1400, unit: "sets"),
        MilestoneDefinition(id: "1500_sets", title: "1,500 Sets Logged", category: .output, threshold: 1500, unit: "sets"),
        MilestoneDefinition(id: "1600_sets", title: "1,600 Sets Logged", category: .output, threshold: 1600, unit: "sets"),
        MilestoneDefinition(id: "1700_sets", title: "1,700 Sets Logged", category: .output, threshold: 1700, unit: "sets"),
        MilestoneDefinition(id: "1800_sets", title: "1,800 Sets Logged", category: .output, threshold: 1800, unit: "sets"),
        MilestoneDefinition(id: "1900_sets", title: "1,900 Sets Logged", category: .output, threshold: 1900, unit: "sets"),
        MilestoneDefinition(id: "2000_sets", title: "2,000 Sets Logged", category: .output, threshold: 2000, unit: "sets"),
        MilestoneDefinition(id: "2100_sets", title: "2,100 Sets Logged", category: .output, threshold: 2100, unit: "sets"),
        MilestoneDefinition(id: "2200_sets", title: "2,200 Sets Logged", category: .output, threshold: 2200, unit: "sets"),
        MilestoneDefinition(id: "2300_sets", title: "2,300 Sets Logged", category: .output, threshold: 2300, unit: "sets"),
        MilestoneDefinition(id: "2400_sets", title: "2,400 Sets Logged", category: .output, threshold: 2400, unit: "sets"),
        MilestoneDefinition(id: "2500_sets", title: "2,500 Sets Logged", category: .output, threshold: 2500, unit: "sets"),

        // Workouts completed (1, 5, 10, 15, 20, then increments of 10 to 250)
        MilestoneDefinition(id: "first_workout", title: "First Workout", category: .output, threshold: 1, unit: "workouts"),
        MilestoneDefinition(id: "5_workouts", title: "5 Workouts", category: .output, threshold: 5, unit: "workouts"),
        MilestoneDefinition(id: "10_workouts", title: "10 Workouts", category: .output, threshold: 10, unit: "workouts"),
        MilestoneDefinition(id: "15_workouts", title: "15 Workouts", category: .output, threshold: 15, unit: "workouts"),
        MilestoneDefinition(id: "20_workouts", title: "20 Workouts", category: .output, threshold: 20, unit: "workouts"),
        MilestoneDefinition(id: "30_workouts", title: "30 Workouts", category: .output, threshold: 30, unit: "workouts"),
        MilestoneDefinition(id: "40_workouts", title: "40 Workouts", category: .output, threshold: 40, unit: "workouts"),
        MilestoneDefinition(id: "50_workouts", title: "50 Workouts", category: .output, threshold: 50, unit: "workouts"),
        MilestoneDefinition(id: "60_workouts", title: "60 Workouts", category: .output, threshold: 60, unit: "workouts"),
        MilestoneDefinition(id: "70_workouts", title: "70 Workouts", category: .output, threshold: 70, unit: "workouts"),
        MilestoneDefinition(id: "80_workouts", title: "80 Workouts", category: .output, threshold: 80, unit: "workouts"),
        MilestoneDefinition(id: "90_workouts", title: "90 Workouts", category: .output, threshold: 90, unit: "workouts"),
        MilestoneDefinition(id: "100_workouts", title: "100 Workouts", category: .output, threshold: 100, unit: "workouts"),
        MilestoneDefinition(id: "110_workouts", title: "110 Workouts", category: .output, threshold: 110, unit: "workouts"),
        MilestoneDefinition(id: "120_workouts", title: "120 Workouts", category: .output, threshold: 120, unit: "workouts"),
        MilestoneDefinition(id: "130_workouts", title: "130 Workouts", category: .output, threshold: 130, unit: "workouts"),
        MilestoneDefinition(id: "140_workouts", title: "140 Workouts", category: .output, threshold: 140, unit: "workouts"),
        MilestoneDefinition(id: "150_workouts", title: "150 Workouts", category: .output, threshold: 150, unit: "workouts"),
        MilestoneDefinition(id: "160_workouts", title: "160 Workouts", category: .output, threshold: 160, unit: "workouts"),
        MilestoneDefinition(id: "170_workouts", title: "170 Workouts", category: .output, threshold: 170, unit: "workouts"),
        MilestoneDefinition(id: "180_workouts", title: "180 Workouts", category: .output, threshold: 180, unit: "workouts"),
        MilestoneDefinition(id: "190_workouts", title: "190 Workouts", category: .output, threshold: 190, unit: "workouts"),
        MilestoneDefinition(id: "200_workouts", title: "200 Workouts", category: .output, threshold: 200, unit: "workouts"),
        MilestoneDefinition(id: "210_workouts", title: "210 Workouts", category: .output, threshold: 210, unit: "workouts"),
        MilestoneDefinition(id: "220_workouts", title: "220 Workouts", category: .output, threshold: 220, unit: "workouts"),
        MilestoneDefinition(id: "230_workouts", title: "230 Workouts", category: .output, threshold: 230, unit: "workouts"),
        MilestoneDefinition(id: "240_workouts", title: "240 Workouts", category: .output, threshold: 240, unit: "workouts"),
        MilestoneDefinition(id: "250_workouts", title: "250 Workouts", category: .output, threshold: 250, unit: "workouts"),

        // Lifetime volume (10k, 25k, 50k, 100k, then increments of 100k to 2,500k)
        MilestoneDefinition(id: "10000kg", title: "10,000 kg Lifted", category: .output, threshold: 10000, unit: "kg"),
        MilestoneDefinition(id: "25000kg", title: "25,000 kg Lifted", category: .output, threshold: 25000, unit: "kg"),
        MilestoneDefinition(id: "50000kg", title: "50,000 kg Lifted", category: .output, threshold: 50000, unit: "kg"),
        MilestoneDefinition(id: "100000kg", title: "100,000 kg Lifted", category: .output, threshold: 100000, unit: "kg"),
        MilestoneDefinition(id: "200000kg", title: "200,000 kg Lifted", category: .output, threshold: 200000, unit: "kg"),
        MilestoneDefinition(id: "300000kg", title: "300,000 kg Lifted", category: .output, threshold: 300000, unit: "kg"),
        MilestoneDefinition(id: "400000kg", title: "400,000 kg Lifted", category: .output, threshold: 400000, unit: "kg"),
        MilestoneDefinition(id: "500000kg", title: "500,000 kg Lifted", category: .output, threshold: 500000, unit: "kg"),
        MilestoneDefinition(id: "600000kg", title: "600,000 kg Lifted", category: .output, threshold: 600000, unit: "kg"),
        MilestoneDefinition(id: "700000kg", title: "700,000 kg Lifted", category: .output, threshold: 700000, unit: "kg"),
        MilestoneDefinition(id: "800000kg", title: "800,000 kg Lifted", category: .output, threshold: 800000, unit: "kg"),
        MilestoneDefinition(id: "900000kg", title: "900,000 kg Lifted", category: .output, threshold: 900000, unit: "kg"),
        MilestoneDefinition(id: "1000000kg", title: "1,000,000 kg Lifted", category: .output, threshold: 1000000, unit: "kg"),
        MilestoneDefinition(id: "1100000kg", title: "1,100,000 kg Lifted", category: .output, threshold: 1100000, unit: "kg"),
        MilestoneDefinition(id: "1200000kg", title: "1,200,000 kg Lifted", category: .output, threshold: 1200000, unit: "kg"),
        MilestoneDefinition(id: "1300000kg", title: "1,300,000 kg Lifted", category: .output, threshold: 1300000, unit: "kg"),
        MilestoneDefinition(id: "1400000kg", title: "1,400,000 kg Lifted", category: .output, threshold: 1400000, unit: "kg"),
        MilestoneDefinition(id: "1500000kg", title: "1,500,000 kg Lifted", category: .output, threshold: 1500000, unit: "kg"),
        MilestoneDefinition(id: "1600000kg", title: "1,600,000 kg Lifted", category: .output, threshold: 1600000, unit: "kg"),
        MilestoneDefinition(id: "1700000kg", title: "1,700,000 kg Lifted", category: .output, threshold: 1700000, unit: "kg"),
        MilestoneDefinition(id: "1800000kg", title: "1,800,000 kg Lifted", category: .output, threshold: 1800000, unit: "kg"),
        MilestoneDefinition(id: "1900000kg", title: "1,900,000 kg Lifted", category: .output, threshold: 1900000, unit: "kg"),
        MilestoneDefinition(id: "2000000kg", title: "2,000,000 kg Lifted", category: .output, threshold: 2000000, unit: "kg"),
        MilestoneDefinition(id: "2100000kg", title: "2,100,000 kg Lifted", category: .output, threshold: 2100000, unit: "kg"),
        MilestoneDefinition(id: "2200000kg", title: "2,200,000 kg Lifted", category: .output, threshold: 2200000, unit: "kg"),
        MilestoneDefinition(id: "2300000kg", title: "2,300,000 kg Lifted", category: .output, threshold: 2300000, unit: "kg"),
        MilestoneDefinition(id: "2400000kg", title: "2,400,000 kg Lifted", category: .output, threshold: 2400000, unit: "kg"),
        MilestoneDefinition(id: "2500000kg", title: "2,500,000 kg Lifted", category: .output, threshold: 2500000, unit: "kg"),
    ]

    // MARK: Streak / Consistency Milestones (Orange)

    static let streak: [MilestoneDefinition] = [
        // Progress streak (5, 10, 15, 20, then increments of 10 to 250)
        MilestoneDefinition(id: "5_progress_streak", title: "5 Progress Streak", category: .streak, threshold: 5, unit: "days"),
        MilestoneDefinition(id: "10_progress_streak", title: "10 Progress Streak", category: .streak, threshold: 10, unit: "days"),
        MilestoneDefinition(id: "15_progress_streak", title: "15 Progress Streak", category: .streak, threshold: 15, unit: "days"),
        MilestoneDefinition(id: "20_progress_streak", title: "20 Progress Streak", category: .streak, threshold: 20, unit: "days"),
        MilestoneDefinition(id: "30_progress_streak", title: "30 Progress Streak", category: .streak, threshold: 30, unit: "days"),
        MilestoneDefinition(id: "40_progress_streak", title: "40 Progress Streak", category: .streak, threshold: 40, unit: "days"),
        MilestoneDefinition(id: "50_progress_streak", title: "50 Progress Streak", category: .streak, threshold: 50, unit: "days"),
        MilestoneDefinition(id: "60_progress_streak", title: "60 Progress Streak", category: .streak, threshold: 60, unit: "days"),
        MilestoneDefinition(id: "70_progress_streak", title: "70 Progress Streak", category: .streak, threshold: 70, unit: "days"),
        MilestoneDefinition(id: "80_progress_streak", title: "80 Progress Streak", category: .streak, threshold: 80, unit: "days"),
        MilestoneDefinition(id: "90_progress_streak", title: "90 Progress Streak", category: .streak, threshold: 90, unit: "days"),
        MilestoneDefinition(id: "100_progress_streak", title: "100 Progress Streak", category: .streak, threshold: 100, unit: "days"),
        MilestoneDefinition(id: "110_progress_streak", title: "110 Progress Streak", category: .streak, threshold: 110, unit: "days"),
        MilestoneDefinition(id: "120_progress_streak", title: "120 Progress Streak", category: .streak, threshold: 120, unit: "days"),
        MilestoneDefinition(id: "130_progress_streak", title: "130 Progress Streak", category: .streak, threshold: 130, unit: "days"),
        MilestoneDefinition(id: "140_progress_streak", title: "140 Progress Streak", category: .streak, threshold: 140, unit: "days"),
        MilestoneDefinition(id: "150_progress_streak", title: "150 Progress Streak", category: .streak, threshold: 150, unit: "days"),
        MilestoneDefinition(id: "160_progress_streak", title: "160 Progress Streak", category: .streak, threshold: 160, unit: "days"),
        MilestoneDefinition(id: "170_progress_streak", title: "170 Progress Streak", category: .streak, threshold: 170, unit: "days"),
        MilestoneDefinition(id: "180_progress_streak", title: "180 Progress Streak", category: .streak, threshold: 180, unit: "days"),
        MilestoneDefinition(id: "190_progress_streak", title: "190 Progress Streak", category: .streak, threshold: 190, unit: "days"),
        MilestoneDefinition(id: "200_progress_streak", title: "200 Progress Streak", category: .streak, threshold: 200, unit: "days"),
        MilestoneDefinition(id: "210_progress_streak", title: "210 Progress Streak", category: .streak, threshold: 210, unit: "days"),
        MilestoneDefinition(id: "220_progress_streak", title: "220 Progress Streak", category: .streak, threshold: 220, unit: "days"),
        MilestoneDefinition(id: "230_progress_streak", title: "230 Progress Streak", category: .streak, threshold: 230, unit: "days"),
        MilestoneDefinition(id: "240_progress_streak", title: "240 Progress Streak", category: .streak, threshold: 240, unit: "days"),
        MilestoneDefinition(id: "250_progress_streak", title: "250 Progress Streak", category: .streak, threshold: 250, unit: "days"),

        // Consecutive full weeks (1, 2, 3, 4, 6, 8, 10, then increments of 5 to 100)
        MilestoneDefinition(id: "first_full_week", title: "First Full Week", category: .streak, threshold: 1, unit: "weeks"),
        MilestoneDefinition(id: "2_consecutive_full_weeks", title: "2 Consecutive Full Weeks", category: .streak, threshold: 2, unit: "weeks"),
        MilestoneDefinition(id: "3_consecutive_full_weeks", title: "3 Consecutive Full Weeks", category: .streak, threshold: 3, unit: "weeks"),
        MilestoneDefinition(id: "4_consecutive_full_weeks", title: "4 Consecutive Full Weeks", category: .streak, threshold: 4, unit: "weeks"),
        MilestoneDefinition(id: "6_consecutive_full_weeks", title: "6 Consecutive Full Weeks", category: .streak, threshold: 6, unit: "weeks"),
        MilestoneDefinition(id: "8_consecutive_full_weeks", title: "8 Consecutive Full Weeks", category: .streak, threshold: 8, unit: "weeks"),
        MilestoneDefinition(id: "10_consecutive_full_weeks", title: "10 Consecutive Full Weeks", category: .streak, threshold: 10, unit: "weeks"),
        MilestoneDefinition(id: "15_consecutive_full_weeks", title: "15 Consecutive Full Weeks", category: .streak, threshold: 15, unit: "weeks"),
        MilestoneDefinition(id: "20_consecutive_full_weeks", title: "20 Consecutive Full Weeks", category: .streak, threshold: 20, unit: "weeks"),
        MilestoneDefinition(id: "25_consecutive_full_weeks", title: "25 Consecutive Full Weeks", category: .streak, threshold: 25, unit: "weeks"),
        MilestoneDefinition(id: "30_consecutive_full_weeks", title: "30 Consecutive Full Weeks", category: .streak, threshold: 30, unit: "weeks"),
        MilestoneDefinition(id: "35_consecutive_full_weeks", title: "35 Consecutive Full Weeks", category: .streak, threshold: 35, unit: "weeks"),
        MilestoneDefinition(id: "40_consecutive_full_weeks", title: "40 Consecutive Full Weeks", category: .streak, threshold: 40, unit: "weeks"),
        MilestoneDefinition(id: "45_consecutive_full_weeks", title: "45 Consecutive Full Weeks", category: .streak, threshold: 45, unit: "weeks"),
        MilestoneDefinition(id: "50_consecutive_full_weeks", title: "50 Consecutive Full Weeks", category: .streak, threshold: 50, unit: "weeks"),
        MilestoneDefinition(id: "55_consecutive_full_weeks", title: "55 Consecutive Full Weeks", category: .streak, threshold: 55, unit: "weeks"),
        MilestoneDefinition(id: "60_consecutive_full_weeks", title: "60 Consecutive Full Weeks", category: .streak, threshold: 60, unit: "weeks"),
        MilestoneDefinition(id: "65_consecutive_full_weeks", title: "65 Consecutive Full Weeks", category: .streak, threshold: 65, unit: "weeks"),
        MilestoneDefinition(id: "70_consecutive_full_weeks", title: "70 Consecutive Full Weeks", category: .streak, threshold: 70, unit: "weeks"),
        MilestoneDefinition(id: "75_consecutive_full_weeks", title: "75 Consecutive Full Weeks", category: .streak, threshold: 75, unit: "weeks"),
        MilestoneDefinition(id: "80_consecutive_full_weeks", title: "80 Consecutive Full Weeks", category: .streak, threshold: 80, unit: "weeks"),
        MilestoneDefinition(id: "85_consecutive_full_weeks", title: "85 Consecutive Full Weeks", category: .streak, threshold: 85, unit: "weeks"),
        MilestoneDefinition(id: "90_consecutive_full_weeks", title: "90 Consecutive Full Weeks", category: .streak, threshold: 90, unit: "weeks"),
        MilestoneDefinition(id: "95_consecutive_full_weeks", title: "95 Consecutive Full Weeks", category: .streak, threshold: 95, unit: "weeks"),
        MilestoneDefinition(id: "100_consecutive_full_weeks", title: "100 Consecutive Full Weeks", category: .streak, threshold: 100, unit: "weeks"),
    ]

    static var all: [MilestoneDefinition] {
        progression + output + streak
    }
}
