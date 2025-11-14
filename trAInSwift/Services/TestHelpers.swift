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
    /// Creates a hardcoded Upper/Lower program for test users (4 days per week)
    static func createTestProgram() -> UserProgram {
        let upperSession1 = ProgramSession(
            dayName: "Upper",
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
                    exerciseName: "Barbell Rows",
                    sets: 4,
                    repRange: "8-12",
                    restSeconds: 120,
                    primaryMuscle: "Back",
                    equipmentType: "Barbell"
                ),
                ProgramExercise(
                    exerciseId: "3",
                    exerciseName: "Overhead Press",
                    sets: 3,
                    repRange: "8-12",
                    restSeconds: 90,
                    primaryMuscle: "Shoulders",
                    equipmentType: "Barbell"
                ),
                ProgramExercise(
                    exerciseId: "4",
                    exerciseName: "Pull-ups",
                    sets: 3,
                    repRange: "8-12",
                    restSeconds: 90,
                    primaryMuscle: "Back",
                    equipmentType: "Bodyweight"
                ),
                ProgramExercise(
                    exerciseId: "5",
                    exerciseName: "Tricep Dips",
                    sets: 3,
                    repRange: "10-15",
                    restSeconds: 60,
                    primaryMuscle: "Triceps",
                    equipmentType: "Bodyweight"
                )
            ]
        )

        let lowerSession1 = ProgramSession(
            dayName: "Lower",
            exercises: [
                ProgramExercise(
                    exerciseId: "6",
                    exerciseName: "Squats",
                    sets: 4,
                    repRange: "8-12",
                    restSeconds: 150,
                    primaryMuscle: "Quads",
                    equipmentType: "Barbell"
                ),
                ProgramExercise(
                    exerciseId: "7",
                    exerciseName: "Romanian Deadlifts",
                    sets: 3,
                    repRange: "10-12",
                    restSeconds: 120,
                    primaryMuscle: "Hamstrings",
                    equipmentType: "Barbell"
                ),
                ProgramExercise(
                    exerciseId: "8",
                    exerciseName: "Leg Press",
                    sets: 3,
                    repRange: "12-15",
                    restSeconds: 90,
                    primaryMuscle: "Quads",
                    equipmentType: "Machine"
                ),
                ProgramExercise(
                    exerciseId: "9",
                    exerciseName: "Leg Curls",
                    sets: 3,
                    repRange: "12-15",
                    restSeconds: 90,
                    primaryMuscle: "Hamstrings",
                    equipmentType: "Machine"
                ),
                ProgramExercise(
                    exerciseId: "10",
                    exerciseName: "Calf Raises",
                    sets: 4,
                    repRange: "15-20",
                    restSeconds: 60,
                    primaryMuscle: "Calves",
                    equipmentType: "Machine"
                )
            ]
        )

        let upperSession2 = ProgramSession(
            dayName: "Upper",
            exercises: [
                ProgramExercise(
                    exerciseId: "11",
                    exerciseName: "Incline Dumbbell Press",
                    sets: 4,
                    repRange: "10-15",
                    restSeconds: 90,
                    primaryMuscle: "Chest",
                    equipmentType: "Dumbbell"
                ),
                ProgramExercise(
                    exerciseId: "12",
                    exerciseName: "Lat Pulldowns",
                    sets: 3,
                    repRange: "10-15",
                    restSeconds: 90,
                    primaryMuscle: "Back",
                    equipmentType: "Cable"
                ),
                ProgramExercise(
                    exerciseId: "13",
                    exerciseName: "Lateral Raises",
                    sets: 3,
                    repRange: "12-15",
                    restSeconds: 60,
                    primaryMuscle: "Shoulders",
                    equipmentType: "Dumbbell"
                ),
                ProgramExercise(
                    exerciseId: "14",
                    exerciseName: "Cable Rows",
                    sets: 3,
                    repRange: "12-15",
                    restSeconds: 90,
                    primaryMuscle: "Back",
                    equipmentType: "Cable"
                ),
                ProgramExercise(
                    exerciseId: "15",
                    exerciseName: "Bicep Curls",
                    sets: 3,
                    repRange: "10-15",
                    restSeconds: 60,
                    primaryMuscle: "Biceps",
                    equipmentType: "Dumbbell"
                )
            ]
        )

        let lowerSession2 = ProgramSession(
            dayName: "Lower",
            exercises: [
                ProgramExercise(
                    exerciseId: "16",
                    exerciseName: "Deadlifts",
                    sets: 4,
                    repRange: "6-10",
                    restSeconds: 180,
                    primaryMuscle: "Back",
                    equipmentType: "Barbell"
                ),
                ProgramExercise(
                    exerciseId: "17",
                    exerciseName: "Front Squats",
                    sets: 3,
                    repRange: "8-12",
                    restSeconds: 120,
                    primaryMuscle: "Quads",
                    equipmentType: "Barbell"
                ),
                ProgramExercise(
                    exerciseId: "18",
                    exerciseName: "Walking Lunges",
                    sets: 3,
                    repRange: "10-12 each",
                    restSeconds: 90,
                    primaryMuscle: "Quads",
                    equipmentType: "Dumbbell"
                ),
                ProgramExercise(
                    exerciseId: "19",
                    exerciseName: "Hamstring Curls",
                    sets: 3,
                    repRange: "12-15",
                    restSeconds: 90,
                    primaryMuscle: "Hamstrings",
                    equipmentType: "Machine"
                ),
                ProgramExercise(
                    exerciseId: "20",
                    exerciseName: "Seated Calf Raises",
                    sets: 4,
                    repRange: "15-20",
                    restSeconds: 60,
                    primaryMuscle: "Calves",
                    equipmentType: "Machine"
                )
            ]
        )

        let program = Program(
            type: .upperLower,
            daysPerWeek: 4,
            sessionDuration: .medium,
            sessions: [upperSession1, lowerSession1, upperSession2, lowerSession2],
            totalWeeks: 8
        )

        return UserProgram(program: program)
    }

    /// Creates a hardcoded PPL program (kept for reference)
    static func createPPLProgram() -> UserProgram {
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
