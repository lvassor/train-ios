//
//  TestDataSeeder.swift
//  TrainSwift
//
//  Seeds test accounts with pre-populated workout data for TestFlight testing.
//  Entire file is compile-gated — compiles to nothing when SEED_TEST_DATA flag is absent.
//

#if SEED_TEST_DATA

import Foundation
import CoreData

/// Seeds two test accounts with 3 weeks of realistic workout history.
/// Triggered once on first launch via UserDefaults guard.
class TestDataSeeder {

    private static let seededKey = "train_test_data_seeded"

    // MARK: - Public Entry Point

    static func seedIfNeeded(context: NSManagedObjectContext) {
        guard !UserDefaults.standard.bool(forKey: seededKey) else {
            return
        }

        do {
            try seedAccount(
                email: "test-ppl@train.com",
                password: "Train123!",
                name: "Test PPL",
                questionnaire: makePPLQuestionnaire(),
                daysPerWeek: 3,
                durationRange: 48...58,
                context: context
            )

            try seedAccount(
                email: "test-ul@train.com",
                password: "Train123!",
                name: "Test UL",
                questionnaire: makeULQuestionnaire(),
                daysPerWeek: 4,
                durationRange: 62...85,
                context: context
            )

            UserDefaults.standard.set(true, forKey: seededKey)
            print("[TestDataSeeder] Seeded test accounts successfully")
        } catch {
            print("[TestDataSeeder] Failed to seed: \(error)")
        }
    }

    // MARK: - Account Seeding

    private static func seedAccount(
        email: String,
        password: String,
        name: String,
        questionnaire: QuestionnaireData,
        daysPerWeek: Int,
        durationRange: ClosedRange<Int>,
        context: NSManagedObjectContext
    ) throws {
        // Idempotent — skip if account already exists
        if UserProfile.fetch(byEmail: email, context: context) != nil {
            print("[TestDataSeeder] \(email) already exists, skipping")
            return
        }

        // 1. Create user profile
        let user = UserProfile.create(email: email, context: context)
        user.name = name
        user.isAppleUser = false
        user.isGoogleUser = false
        user.setQuestionnaireData(questionnaire)
        user.age = Int16(questionnaire.age)
        user.weight = questionnaire.weightKg
        user.height = questionnaire.heightCm
        user.experience = questionnaire.experienceLevel
        user.equipmentArray = questionnaire.equipmentAvailable
        user.injuriesArray = questionnaire.injuries
        user.priorityMusclesArray = questionnaire.targetMuscleGroups

        try context.save()

        guard let userId = user.id else { return }

        // 2. Store password in Keychain
        try KeychainService.shared.savePassword(password, for: email)

        // 3. Generate programme using the real generator
        let generator = DynamicProgramGenerator()
        let program = try generator.generateProgram(from: questionnaire)
        let workoutProgram = WorkoutProgram.create(userId: userId, program: program, context: context)
        try context.save()

        guard let programId = workoutProgram.id else { return }

        // 4. Generate 3 weeks of workout sessions
        let weekDates = sessionDates(daysPerWeek: daysPerWeek, weeksBack: 3)

        for (weekIndex, dates) in weekDates.enumerated() {
            let weekNumber = weekIndex + 1
            for (dayIndex, date) in dates.enumerated() {
                let sessionIndex = dayIndex % program.sessions.count
                let programSession = program.sessions[sessionIndex]

                let loggedExercises = generateLoggedExercises(
                    from: programSession.exercises,
                    weekNumber: weekNumber
                )

                let session = CDWorkoutSession(context: context)
                session.id = UUID()
                session.userId = userId
                session.programId = programId
                session.sessionName = programSession.dayName
                session.weekNumber = Int16(weekNumber)
                session.completedAt = date
                session.durationSeconds = Int32(Int.random(in: durationRange) * 60)

                if let encoded = try? JSONEncoder().encode(loggedExercises) {
                    session.exercisesData = encoded
                }
            }
        }

        // 5. Update programme state to week 4
        var completedSet = Set<String>()
        for week in 1...3 {
            for session in 0..<daysPerWeek {
                completedSet.insert("week\(week)-session\(session)")
            }
        }
        workoutProgram.completedSessionsSet = completedSet
        workoutProgram.currentWeek = 4
        workoutProgram.currentSessionIndex = 0

        try context.save()
        print("[TestDataSeeder] \(email): created \(weekDates.flatMap { $0 }.count) sessions across 3 weeks")
    }

    // MARK: - Questionnaire Configs

    private static func makePPLQuestionnaire() -> QuestionnaireData {
        var q = QuestionnaireData()
        q.name = "Test PPL"
        q.email = "test-ppl@train.com"
        q.gender = "male"
        q.dateOfBirth = Calendar.current.date(byAdding: .year, value: -28, to: Date()) ?? Date()
        q.heightCm = 180.0
        q.heightUnit = .cm
        q.weightKg = 82.0
        q.weightUnit = .kg
        q.primaryGoals = ["build_muscle", "get_stronger"]
        q.targetMuscleGroups = ["Chest", "Back", "Quads"]
        q.experienceLevel = "2_plus_years"
        q.trainingPlace = "large_gym"
        q.equipmentAvailable = ["barbells", "dumbbells", "kettlebells", "cable_machines", "pin_loaded", "plate_loaded", "other"]
        q.trainingDaysPerWeek = 3
        q.selectedSplit = "Push Pull Legs"
        q.sessionDuration = "45-60 min"
        q.injuries = []
        return q
    }

    private static func makeULQuestionnaire() -> QuestionnaireData {
        var q = QuestionnaireData()
        q.name = "Test UL"
        q.email = "test-ul@train.com"
        q.gender = "female"
        q.dateOfBirth = Calendar.current.date(byAdding: .year, value: -25, to: Date()) ?? Date()
        q.heightCm = 168.0
        q.heightUnit = .cm
        q.weightKg = 65.0
        q.weightUnit = .kg
        q.primaryGoals = ["build_muscle", "tone_up"]
        q.targetMuscleGroups = ["Glutes", "Shoulders", "Back"]
        q.experienceLevel = "6_months_2_years"
        q.trainingPlace = "large_gym"
        q.equipmentAvailable = ["barbells", "dumbbells", "kettlebells", "cable_machines", "pin_loaded", "plate_loaded", "other"]
        q.trainingDaysPerWeek = 4
        q.selectedSplit = "Upper Lower"
        q.sessionDuration = "60-90 min"
        q.injuries = []
        return q
    }

    // MARK: - Date Scheduling

    /// Returns arrays of session dates for each week, going back `weeksBack` weeks from today.
    private static func sessionDates(daysPerWeek: Int, weeksBack: Int) -> [[Date]] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Find most recent Monday
        let weekday = calendar.component(.weekday, from: today)
        let daysFromMonday = (weekday == 1) ? 6 : weekday - 2
        let thisMonday = calendar.date(byAdding: .day, value: -daysFromMonday, to: today)!

        var allWeeks: [[Date]] = []

        for weekOffset in (1...weeksBack).reversed() {
            let weekMonday = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: thisMonday)!

            // Mon/Wed/Fri for 3-day, Mon/Tue/Thu/Fri for 4-day
            let dayOffsets: [Int]
            switch daysPerWeek {
            case 3: dayOffsets = [0, 2, 4]
            case 4: dayOffsets = [0, 1, 3, 4]
            default: dayOffsets = Array(0..<daysPerWeek)
            }

            let dates = dayOffsets.map { offset -> Date in
                var date = calendar.date(byAdding: .day, value: offset, to: weekMonday)!
                date = calendar.date(bySettingHour: 7, minute: 30, second: 0, of: date)!
                return date
            }
            allWeeks.append(dates)
        }

        return allWeeks
    }

    // MARK: - Exercise Data Generation

    /// Convert programme exercises to logged exercises with progressive weights.
    private static func generateLoggedExercises(
        from programExercises: [ProgramExercise],
        weekNumber: Int
    ) -> [LoggedExercise] {
        return programExercises.map { exercise in
            let weight = baseWeight(for: exercise.exerciseName, weekNumber: weekNumber)
            let targetReps = exercise.repsMax

            let sets = (0..<exercise.sets).map { setIndex -> LoggedSet in
                // Natural fatigue: set 1 strong, later sets slightly fewer reps
                let repVariation: Int
                switch setIndex {
                case 0: repVariation = 0
                case 1: repVariation = Int.random(in: -1...0)
                default: repVariation = Int.random(in: -2...0)
                }

                let reps = max(exercise.repsMin, targetReps + repVariation)

                return LoggedSet(
                    reps: reps,
                    weight: weight,
                    completed: true
                )
            }

            return LoggedExercise(
                exerciseName: exercise.exerciseName,
                sets: sets
            )
        }
    }

    /// Base weight by exercise type with progressive overload per week.
    private static func baseWeight(for exerciseName: String, weekNumber: Int) -> Double {
        let name = exerciseName.lowercased()
        let base: Double

        if name.contains("bench press") || name.contains("chest press") {
            base = 60.0
        } else if name.contains("squat") {
            base = 80.0
        } else if name.contains("deadlift") || name.contains("hip thrust") {
            base = 90.0
        } else if name.contains("row") || name.contains("pull") || name.contains("lat") {
            base = 50.0
        } else if name.contains("shoulder press") || name.contains("overhead") {
            base = 35.0
        } else if name.contains("curl") || name.contains("bicep") {
            base = 15.0
        } else if name.contains("tricep") || name.contains("extension") || name.contains("pushdown") {
            base = 20.0
        } else if name.contains("leg press") {
            base = 120.0
        } else if name.contains("leg curl") || name.contains("leg extension") {
            base = 35.0
        } else if name.contains("calf") {
            base = 40.0
        } else if name.contains("lateral raise") || name.contains("face pull") {
            base = 10.0
        } else {
            base = 25.0
        }

        // +2.5kg/week for compounds, +1.25kg/week for isolations
        let increment: Double = base >= 40 ? 2.5 : 1.25
        return base + (Double(weekNumber - 1) * increment)
    }
}

#endif
