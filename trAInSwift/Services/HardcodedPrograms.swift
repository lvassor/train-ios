//
//  HardcodedPrograms.swift
//  trAInSwift
//
//  Hardcoded workout programs for MVP testing
//

import Foundation

class HardcodedPrograms {

    // MARK: - Main Generator

    static func getProgram(days: Int, duration: String) -> Program {
        let key = "\(days)day-\(duration)"

        switch key {
        // 2 DAYS
        case "2day-30-45 min":
            return upperLower2Day_Short()
        case "2day-45-60 min", "2day-60-90 min":
            return fullBody2Day_Medium()

        // 3 DAYS
        case "3day-30-45 min", "3day-45-60 min", "3day-60-90 min":
            return pushPullLegs3Day()

        // 4 DAYS
        case "4day-30-45 min", "4day-45-60 min", "4day-60-90 min":
            return upperLower4Day()

        // 5 DAYS (using PPL for now)
        case "5day-30-45 min", "5day-45-60 min", "5day-60-90 min":
            return pushPullLegs5Day()

        default:
            return pushPullLegs3Day() // Default fallback
        }
    }

    // MARK: - 2 Day Programs

    static func upperLower2Day_Short() -> Program {
        let sessions = [
            ProgramSession(dayName: "Upper Body", exercises: [
                ProgramExercise(exerciseId: "1", exerciseName: "Bench Press", sets: 3, repRange: "8-10", restSeconds: 120, primaryMuscle: "Chest", equipmentType: "Barbell"),
                ProgramExercise(exerciseId: "2", exerciseName: "Bent Over Row", sets: 3, repRange: "8-10", restSeconds: 120, primaryMuscle: "Back", equipmentType: "Barbell"),
                ProgramExercise(exerciseId: "3", exerciseName: "Overhead Press", sets: 3, repRange: "8-10", restSeconds: 90, primaryMuscle: "Shoulders", equipmentType: "Dumbbell"),
                ProgramExercise(exerciseId: "4", exerciseName: "Dumbbell Curl", sets: 3, repRange: "10-12", restSeconds: 60, primaryMuscle: "Biceps", equipmentType: "Dumbbell"),
                ProgramExercise(exerciseId: "5", exerciseName: "Tricep Dip", sets: 3, repRange: "8-12", restSeconds: 60, primaryMuscle: "Triceps", equipmentType: "Bodyweight")
            ]),
            ProgramSession(dayName: "Lower Body", exercises: [
                ProgramExercise(exerciseId: "6", exerciseName: "Squat", sets: 3, repRange: "8-10", restSeconds: 150, primaryMuscle: "Quads", equipmentType: "Barbell"),
                ProgramExercise(exerciseId: "7", exerciseName: "Romanian Deadlift", sets: 3, repRange: "8-10", restSeconds: 120, primaryMuscle: "Hamstrings", equipmentType: "Barbell"),
                ProgramExercise(exerciseId: "8", exerciseName: "Bulgarian Split Squat", sets: 3, repRange: "10-12", restSeconds: 90, primaryMuscle: "Quads", equipmentType: "Dumbbell"),
                ProgramExercise(exerciseId: "9", exerciseName: "Leg Curl", sets: 3, repRange: "12-15", restSeconds: 60, primaryMuscle: "Hamstrings", equipmentType: "Machine"),
                ProgramExercise(exerciseId: "10", exerciseName: "Calf Raise", sets: 3, repRange: "15-20", restSeconds: 60, primaryMuscle: "Calves", equipmentType: "Machine")
            ])
        ]

        return Program(
            type: .upperLower,
            daysPerWeek: 2,
            sessionDuration: .short,
            sessions: sessions,
            totalWeeks: 8
        )
    }

    static func fullBody2Day_Medium() -> Program {
        let sessions = [
            ProgramSession(dayName: "Full Body A", exercises: [
                ProgramExercise(exerciseId: "1", exerciseName: "Squat", sets: 3, repRange: "8-10", restSeconds: 150, primaryMuscle: "Quads", equipmentType: "Barbell"),
                ProgramExercise(exerciseId: "2", exerciseName: "Bench Press", sets: 3, repRange: "8-10", restSeconds: 120, primaryMuscle: "Chest", equipmentType: "Barbell"),
                ProgramExercise(exerciseId: "3", exerciseName: "Bent Over Row", sets: 3, repRange: "8-10", restSeconds: 120, primaryMuscle: "Back", equipmentType: "Barbell"),
                ProgramExercise(exerciseId: "4", exerciseName: "Overhead Press", sets: 3, repRange: "8-10", restSeconds: 90, primaryMuscle: "Shoulders", equipmentType: "Dumbbell"),
                ProgramExercise(exerciseId: "5", exerciseName: "Romanian Deadlift", sets: 3, repRange: "10-12", restSeconds: 120, primaryMuscle: "Hamstrings", equipmentType: "Barbell"),
                ProgramExercise(exerciseId: "6", exerciseName: "Dumbbell Curl", sets: 3, repRange: "10-12", restSeconds: 60, primaryMuscle: "Biceps", equipmentType: "Dumbbell"),
                ProgramExercise(exerciseId: "7", exerciseName: "Tricep Extension", sets: 3, repRange: "10-12", restSeconds: 60, primaryMuscle: "Triceps", equipmentType: "Cable")
            ]),
            ProgramSession(dayName: "Full Body B", exercises: [
                ProgramExercise(exerciseId: "8", exerciseName: "Deadlift", sets: 3, repRange: "6-8", restSeconds: 180, primaryMuscle: "Back", equipmentType: "Barbell"),
                ProgramExercise(exerciseId: "9", exerciseName: "Incline Dumbbell Press", sets: 3, repRange: "8-10", restSeconds: 120, primaryMuscle: "Chest", equipmentType: "Dumbbell"),
                ProgramExercise(exerciseId: "10", exerciseName: "Lat Pulldown", sets: 3, repRange: "10-12", restSeconds: 90, primaryMuscle: "Back", equipmentType: "Cable"),
                ProgramExercise(exerciseId: "11", exerciseName: "Leg Press", sets: 3, repRange: "10-12", restSeconds: 120, primaryMuscle: "Quads", equipmentType: "Machine"),
                ProgramExercise(exerciseId: "12", exerciseName: "Leg Curl", sets: 3, repRange: "10-12", restSeconds: 90, primaryMuscle: "Hamstrings", equipmentType: "Machine"),
                ProgramExercise(exerciseId: "13", exerciseName: "Lateral Raise", sets: 3, repRange: "12-15", restSeconds: 60, primaryMuscle: "Shoulders", equipmentType: "Dumbbell"),
                ProgramExercise(exerciseId: "14", exerciseName: "Face Pull", sets: 3, repRange: "15-20", restSeconds: 60, primaryMuscle: "Shoulders", equipmentType: "Cable")
            ])
        ]

        return Program(
            type: .fullBody,
            daysPerWeek: 2,
            sessionDuration: .medium,
            sessions: sessions,
            totalWeeks: 8
        )
    }

    // MARK: - 3 Day Push/Pull/Legs

    static func pushPullLegs3Day() -> Program {
        let sessions = [
            ProgramSession(dayName: "Push", exercises: [
                ProgramExercise(exerciseId: "1", exerciseName: "Bench Press", sets: 3, repRange: "8-10", restSeconds: 120, primaryMuscle: "Chest", equipmentType: "Barbell"),
                ProgramExercise(exerciseId: "2", exerciseName: "Incline Dumbbell Press", sets: 3, repRange: "8-10", restSeconds: 120, primaryMuscle: "Chest", equipmentType: "Dumbbell"),
                ProgramExercise(exerciseId: "3", exerciseName: "Overhead Press", sets: 3, repRange: "8-10", restSeconds: 90, primaryMuscle: "Shoulders", equipmentType: "Barbell"),
                ProgramExercise(exerciseId: "4", exerciseName: "Lateral Raise", sets: 3, repRange: "12-15", restSeconds: 60, primaryMuscle: "Shoulders", equipmentType: "Dumbbell"),
                ProgramExercise(exerciseId: "5", exerciseName: "Tricep Dip", sets: 3, repRange: "8-12", restSeconds: 90, primaryMuscle: "Triceps", equipmentType: "Bodyweight"),
                ProgramExercise(exerciseId: "6", exerciseName: "Tricep Extension", sets: 3, repRange: "10-12", restSeconds: 60, primaryMuscle: "Triceps", equipmentType: "Cable")
            ]),
            ProgramSession(dayName: "Pull", exercises: [
                ProgramExercise(exerciseId: "7", exerciseName: "Deadlift", sets: 3, repRange: "6-8", restSeconds: 180, primaryMuscle: "Back", equipmentType: "Barbell"),
                ProgramExercise(exerciseId: "8", exerciseName: "Pull-up", sets: 3, repRange: "6-10", restSeconds: 120, primaryMuscle: "Back", equipmentType: "Bodyweight"),
                ProgramExercise(exerciseId: "9", exerciseName: "Bent Over Row", sets: 3, repRange: "8-10", restSeconds: 120, primaryMuscle: "Back", equipmentType: "Barbell"),
                ProgramExercise(exerciseId: "10", exerciseName: "Lat Pulldown", sets: 3, repRange: "10-12", restSeconds: 90, primaryMuscle: "Back", equipmentType: "Cable"),
                ProgramExercise(exerciseId: "11", exerciseName: "Barbell Curl", sets: 3, repRange: "8-10", restSeconds: 60, primaryMuscle: "Biceps", equipmentType: "Barbell"),
                ProgramExercise(exerciseId: "12", exerciseName: "Hammer Curl", sets: 3, repRange: "10-12", restSeconds: 60, primaryMuscle: "Biceps", equipmentType: "Dumbbell")
            ]),
            ProgramSession(dayName: "Legs", exercises: [
                ProgramExercise(exerciseId: "13", exerciseName: "Squat", sets: 3, repRange: "8-10", restSeconds: 150, primaryMuscle: "Quads", equipmentType: "Barbell"),
                ProgramExercise(exerciseId: "14", exerciseName: "Romanian Deadlift", sets: 3, repRange: "8-10", restSeconds: 120, primaryMuscle: "Hamstrings", equipmentType: "Barbell"),
                ProgramExercise(exerciseId: "15", exerciseName: "Leg Press", sets: 3, repRange: "10-12", restSeconds: 120, primaryMuscle: "Quads", equipmentType: "Machine"),
                ProgramExercise(exerciseId: "16", exerciseName: "Leg Curl", sets: 3, repRange: "10-12", restSeconds: 90, primaryMuscle: "Hamstrings", equipmentType: "Machine"),
                ProgramExercise(exerciseId: "17", exerciseName: "Bulgarian Split Squat", sets: 3, repRange: "10-12", restSeconds: 90, primaryMuscle: "Quads", equipmentType: "Dumbbell"),
                ProgramExercise(exerciseId: "18", exerciseName: "Calf Raise", sets: 3, repRange: "15-20", restSeconds: 60, primaryMuscle: "Calves", equipmentType: "Machine")
            ])
        ]

        return Program(
            type: .pushPullLegs,
            daysPerWeek: 3,
            sessionDuration: .medium,
            sessions: sessions,
            totalWeeks: 8
        )
    }

    // MARK: - 4 Day Upper/Lower

    static func upperLower4Day() -> Program {
        let sessions = [
            ProgramSession(dayName: "Upper A", exercises: [
                ProgramExercise(exerciseId: "1", exerciseName: "Bench Press", sets: 3, repRange: "8-10", restSeconds: 120, primaryMuscle: "Chest", equipmentType: "Barbell"),
                ProgramExercise(exerciseId: "2", exerciseName: "Bent Over Row", sets: 3, repRange: "8-10", restSeconds: 120, primaryMuscle: "Back", equipmentType: "Barbell"),
                ProgramExercise(exerciseId: "3", exerciseName: "Overhead Press", sets: 3, repRange: "8-10", restSeconds: 90, primaryMuscle: "Shoulders", equipmentType: "Dumbbell"),
                ProgramExercise(exerciseId: "4", exerciseName: "Lat Pulldown", sets: 3, repRange: "10-12", restSeconds: 90, primaryMuscle: "Back", equipmentType: "Cable"),
                ProgramExercise(exerciseId: "5", exerciseName: "Dumbbell Curl", sets: 3, repRange: "10-12", restSeconds: 60, primaryMuscle: "Biceps", equipmentType: "Dumbbell")
            ]),
            ProgramSession(dayName: "Lower A", exercises: [
                ProgramExercise(exerciseId: "6", exerciseName: "Squat", sets: 3, repRange: "8-10", restSeconds: 150, primaryMuscle: "Quads", equipmentType: "Barbell"),
                ProgramExercise(exerciseId: "7", exerciseName: "Romanian Deadlift", sets: 3, repRange: "8-10", restSeconds: 120, primaryMuscle: "Hamstrings", equipmentType: "Barbell"),
                ProgramExercise(exerciseId: "8", exerciseName: "Leg Press", sets: 3, repRange: "10-12", restSeconds: 120, primaryMuscle: "Quads", equipmentType: "Machine"),
                ProgramExercise(exerciseId: "9", exerciseName: "Leg Curl", sets: 3, repRange: "12-15", restSeconds: 90, primaryMuscle: "Hamstrings", equipmentType: "Machine"),
                ProgramExercise(exerciseId: "10", exerciseName: "Calf Raise", sets: 3, repRange: "15-20", restSeconds: 60, primaryMuscle: "Calves", equipmentType: "Machine")
            ]),
            ProgramSession(dayName: "Upper B", exercises: [
                ProgramExercise(exerciseId: "11", exerciseName: "Incline Dumbbell Press", sets: 3, repRange: "8-10", restSeconds: 120, primaryMuscle: "Chest", equipmentType: "Dumbbell"),
                ProgramExercise(exerciseId: "12", exerciseName: "Pull-up", sets: 3, repRange: "6-10", restSeconds: 120, primaryMuscle: "Back", equipmentType: "Bodyweight"),
                ProgramExercise(exerciseId: "13", exerciseName: "Dumbbell Shoulder Press", sets: 3, repRange: "10-12", restSeconds: 90, primaryMuscle: "Shoulders", equipmentType: "Dumbbell"),
                ProgramExercise(exerciseId: "14", exerciseName: "Cable Row", sets: 3, repRange: "10-12", restSeconds: 90, primaryMuscle: "Back", equipmentType: "Cable"),
                ProgramExercise(exerciseId: "15", exerciseName: "Tricep Extension", sets: 3, repRange: "10-12", restSeconds: 60, primaryMuscle: "Triceps", equipmentType: "Cable")
            ]),
            ProgramSession(dayName: "Lower B", exercises: [
                ProgramExercise(exerciseId: "16", exerciseName: "Front Squat", sets: 3, repRange: "8-10", restSeconds: 150, primaryMuscle: "Quads", equipmentType: "Barbell"),
                ProgramExercise(exerciseId: "17", exerciseName: "Stiff Leg Deadlift", sets: 3, repRange: "10-12", restSeconds: 120, primaryMuscle: "Hamstrings", equipmentType: "Barbell"),
                ProgramExercise(exerciseId: "18", exerciseName: "Bulgarian Split Squat", sets: 3, repRange: "10-12", restSeconds: 90, primaryMuscle: "Quads", equipmentType: "Dumbbell"),
                ProgramExercise(exerciseId: "19", exerciseName: "Glute Bridge", sets: 3, repRange: "12-15", restSeconds: 90, primaryMuscle: "Glutes", equipmentType: "Barbell"),
                ProgramExercise(exerciseId: "20", exerciseName: "Leg Extension", sets: 3, repRange: "12-15", restSeconds: 60, primaryMuscle: "Quads", equipmentType: "Machine")
            ])
        ]

        return Program(
            type: .upperLower,
            daysPerWeek: 4,
            sessionDuration: .medium,
            sessions: sessions,
            totalWeeks: 8
        )
    }

    // MARK: - 5 Day Push/Pull/Legs

    static func pushPullLegs5Day() -> Program {
        let sessions = [
            ProgramSession(dayName: "Push", exercises: [
                ProgramExercise(exerciseId: "1", exerciseName: "Bench Press", sets: 3, repRange: "8-10", restSeconds: 120, primaryMuscle: "Chest", equipmentType: "Barbell"),
                ProgramExercise(exerciseId: "2", exerciseName: "Incline Dumbbell Press", sets: 3, repRange: "8-10", restSeconds: 120, primaryMuscle: "Chest", equipmentType: "Dumbbell"),
                ProgramExercise(exerciseId: "3", exerciseName: "Overhead Press", sets: 3, repRange: "8-10", restSeconds: 90, primaryMuscle: "Shoulders", equipmentType: "Barbell"),
                ProgramExercise(exerciseId: "4", exerciseName: "Lateral Raise", sets: 3, repRange: "12-15", restSeconds: 60, primaryMuscle: "Shoulders", equipmentType: "Dumbbell"),
                ProgramExercise(exerciseId: "5", exerciseName: "Tricep Dip", sets: 3, repRange: "8-12", restSeconds: 90, primaryMuscle: "Triceps", equipmentType: "Bodyweight")
            ]),
            ProgramSession(dayName: "Pull", exercises: [
                ProgramExercise(exerciseId: "6", exerciseName: "Deadlift", sets: 3, repRange: "6-8", restSeconds: 180, primaryMuscle: "Back", equipmentType: "Barbell"),
                ProgramExercise(exerciseId: "7", exerciseName: "Pull-up", sets: 3, repRange: "6-10", restSeconds: 120, primaryMuscle: "Back", equipmentType: "Bodyweight"),
                ProgramExercise(exerciseId: "8", exerciseName: "Bent Over Row", sets: 3, repRange: "8-10", restSeconds: 120, primaryMuscle: "Back", equipmentType: "Barbell"),
                ProgramExercise(exerciseId: "9", exerciseName: "Face Pull", sets: 3, repRange: "15-20", restSeconds: 60, primaryMuscle: "Shoulders", equipmentType: "Cable"),
                ProgramExercise(exerciseId: "10", exerciseName: "Barbell Curl", sets: 3, repRange: "8-10", restSeconds: 60, primaryMuscle: "Biceps", equipmentType: "Barbell")
            ]),
            ProgramSession(dayName: "Legs", exercises: [
                ProgramExercise(exerciseId: "11", exerciseName: "Squat", sets: 3, repRange: "8-10", restSeconds: 150, primaryMuscle: "Quads", equipmentType: "Barbell"),
                ProgramExercise(exerciseId: "12", exerciseName: "Romanian Deadlift", sets: 3, repRange: "8-10", restSeconds: 120, primaryMuscle: "Hamstrings", equipmentType: "Barbell"),
                ProgramExercise(exerciseId: "13", exerciseName: "Leg Press", sets: 3, repRange: "10-12", restSeconds: 120, primaryMuscle: "Quads", equipmentType: "Machine"),
                ProgramExercise(exerciseId: "14", exerciseName: "Leg Curl", sets: 3, repRange: "10-12", restSeconds: 90, primaryMuscle: "Hamstrings", equipmentType: "Machine"),
                ProgramExercise(exerciseId: "15", exerciseName: "Calf Raise", sets: 3, repRange: "15-20", restSeconds: 60, primaryMuscle: "Calves", equipmentType: "Machine")
            ]),
            ProgramSession(dayName: "Upper", exercises: [
                ProgramExercise(exerciseId: "16", exerciseName: "Incline Bench Press", sets: 3, repRange: "8-10", restSeconds: 120, primaryMuscle: "Chest", equipmentType: "Barbell"),
                ProgramExercise(exerciseId: "17", exerciseName: "Cable Row", sets: 3, repRange: "10-12", restSeconds: 90, primaryMuscle: "Back", equipmentType: "Cable"),
                ProgramExercise(exerciseId: "18", exerciseName: "Dumbbell Shoulder Press", sets: 3, repRange: "10-12", restSeconds: 90, primaryMuscle: "Shoulders", equipmentType: "Dumbbell"),
                ProgramExercise(exerciseId: "19", exerciseName: "Hammer Curl", sets: 3, repRange: "10-12", restSeconds: 60, primaryMuscle: "Biceps", equipmentType: "Dumbbell"),
                ProgramExercise(exerciseId: "20", exerciseName: "Tricep Extension", sets: 3, repRange: "10-12", restSeconds: 60, primaryMuscle: "Triceps", equipmentType: "Cable")
            ]),
            ProgramSession(dayName: "Lower", exercises: [
                ProgramExercise(exerciseId: "21", exerciseName: "Front Squat", sets: 3, repRange: "8-10", restSeconds: 150, primaryMuscle: "Quads", equipmentType: "Barbell"),
                ProgramExercise(exerciseId: "22", exerciseName: "Stiff Leg Deadlift", sets: 3, repRange: "10-12", restSeconds: 120, primaryMuscle: "Hamstrings", equipmentType: "Barbell"),
                ProgramExercise(exerciseId: "23", exerciseName: "Bulgarian Split Squat", sets: 3, repRange: "10-12", restSeconds: 90, primaryMuscle: "Quads", equipmentType: "Dumbbell"),
                ProgramExercise(exerciseId: "24", exerciseName: "Glute Bridge", sets: 3, repRange: "12-15", restSeconds: 90, primaryMuscle: "Glutes", equipmentType: "Barbell"),
                ProgramExercise(exerciseId: "25", exerciseName: "Seated Calf Raise", sets: 3, repRange: "15-20", restSeconds: 60, primaryMuscle: "Calves", equipmentType: "Machine")
            ])
        ]

        return Program(
            type: .pushPullLegs,
            daysPerWeek: 5,
            sessionDuration: .medium,
            sessions: sessions,
            totalWeeks: 8
        )
    }
}
