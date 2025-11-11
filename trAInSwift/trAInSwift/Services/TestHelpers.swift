//
//  TestHelpers.swift
//  trAInSwift
//
//  Test data and helpers for development/debug builds
//

import Foundation

#if DEBUG

// MARK: - Test Accounts

struct TestAccounts {
    static let accounts = [
        ("test@test.com", "password123"),
        ("demo@train.com", "demo123"),
        ("user@example.com", "user123")
    ]

    static func isTestAccount(email: String) -> Bool {
        return accounts.contains { $0.0 == email.lowercased() }
    }

    static func getPassword(for email: String) -> String? {
        return accounts.first { $0.0 == email.lowercased() }?.1
    }
}

// MARK: - Test Program Generator

struct TestProgramHelper {
    /// Creates a hardcoded PPL program for test users
    static func createTestProgram() -> UserProgram {
        let pushSession = ProgramSession(
            dayName: "Push",
            exercises: [
                ProgramExercise(
                    exerciseId: "1",
                    exerciseName: "Bench Press",
                    sets: 4,
                    repRange: "8-12",
                    restSeconds: 120,
                    primaryMuscle: "Chest",
                    equipmentType: "Barbell"
                ),
                ProgramExercise(
                    exerciseId: "2",
                    exerciseName: "Overhead Press",
                    sets: 3,
                    repRange: "8-12",
                    restSeconds: 90,
                    primaryMuscle: "Shoulders",
                    equipmentType: "Barbell"
                ),
                ProgramExercise(
                    exerciseId: "3",
                    exerciseName: "Incline Dumbbell Press",
                    sets: 3,
                    repRange: "10-15",
                    restSeconds: 90,
                    primaryMuscle: "Chest",
                    equipmentType: "Dumbbell"
                ),
                ProgramExercise(
                    exerciseId: "4",
                    exerciseName: "Lateral Raises",
                    sets: 3,
                    repRange: "12-15",
                    restSeconds: 60,
                    primaryMuscle: "Shoulders",
                    equipmentType: "Dumbbell"
                ),
                ProgramExercise(
                    exerciseId: "5",
                    exerciseName: "Tricep Pushdowns",
                    sets: 3,
                    repRange: "12-15",
                    restSeconds: 60,
                    primaryMuscle: "Triceps",
                    equipmentType: "Cable"
                )
            ]
        )

        let pullSession = ProgramSession(
            dayName: "Pull",
            exercises: [
                ProgramExercise(
                    exerciseId: "6",
                    exerciseName: "Deadlift",
                    sets: 4,
                    repRange: "6-10",
                    restSeconds: 180,
                    primaryMuscle: "Back",
                    equipmentType: "Barbell"
                ),
                ProgramExercise(
                    exerciseId: "7",
                    exerciseName: "Pull-ups",
                    sets: 3,
                    repRange: "8-12",
                    restSeconds: 90,
                    primaryMuscle: "Back",
                    equipmentType: "Bodyweight"
                ),
                ProgramExercise(
                    exerciseId: "8",
                    exerciseName: "Barbell Rows",
                    sets: 3,
                    repRange: "8-12",
                    restSeconds: 90,
                    primaryMuscle: "Back",
                    equipmentType: "Barbell"
                ),
                ProgramExercise(
                    exerciseId: "9",
                    exerciseName: "Face Pulls",
                    sets: 3,
                    repRange: "15-20",
                    restSeconds: 60,
                    primaryMuscle: "Shoulders",
                    equipmentType: "Cable"
                ),
                ProgramExercise(
                    exerciseId: "10",
                    exerciseName: "Bicep Curls",
                    sets: 3,
                    repRange: "10-15",
                    restSeconds: 60,
                    primaryMuscle: "Biceps",
                    equipmentType: "Dumbbell"
                )
            ]
        )

        let legsSession = ProgramSession(
            dayName: "Legs",
            exercises: [
                ProgramExercise(
                    exerciseId: "11",
                    exerciseName: "Squats",
                    sets: 4,
                    repRange: "8-12",
                    restSeconds: 150,
                    primaryMuscle: "Quads",
                    equipmentType: "Barbell"
                ),
                ProgramExercise(
                    exerciseId: "12",
                    exerciseName: "Romanian Deadlifts",
                    sets: 3,
                    repRange: "10-12",
                    restSeconds: 120,
                    primaryMuscle: "Hamstrings",
                    equipmentType: "Barbell"
                ),
                ProgramExercise(
                    exerciseId: "13",
                    exerciseName: "Leg Press",
                    sets: 3,
                    repRange: "12-15",
                    restSeconds: 90,
                    primaryMuscle: "Quads",
                    equipmentType: "Machine"
                ),
                ProgramExercise(
                    exerciseId: "14",
                    exerciseName: "Leg Curls",
                    sets: 3,
                    repRange: "12-15",
                    restSeconds: 90,
                    primaryMuscle: "Hamstrings",
                    equipmentType: "Machine"
                ),
                ProgramExercise(
                    exerciseId: "15",
                    exerciseName: "Calf Raises",
                    sets: 4,
                    repRange: "15-20",
                    restSeconds: 60,
                    primaryMuscle: "Calves",
                    equipmentType: "Machine"
                )
            ]
        )

        let program = Program(
            type: .pushPullLegs,
            daysPerWeek: 3,
            sessionDuration: .medium,
            sessions: [pushSession, pullSession, legsSession],
            totalWeeks: 12
        )

        return UserProgram(program: program)
    }
}

#endif
