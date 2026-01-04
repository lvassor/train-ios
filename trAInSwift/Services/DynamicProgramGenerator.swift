//
//  DynamicProgramGenerator.swift
//  trAInSwift
//
//  Dynamic program generation using SQLite database and questionnaire answers
//  Updated with scoring-based exercise selection and validation warnings
//

import Foundation

// MARK: - Program Generation Result

/// Result of program generation including any warnings
struct ProgramGenerationResult {
    let program: Program
    let warnings: [ExerciseSelectionWarning]

    var hasWarnings: Bool { !warnings.isEmpty }

    /// Get unique warnings (de-duplicated)
    var uniqueWarnings: [ExerciseSelectionWarning] {
        var seen = Set<String>()
        return warnings.filter { warning in
            let key = warning.message
            if seen.contains(key) {
                return false
            }
            seen.insert(key)
            return true
        }
    }
}

class DynamicProgramGenerator {
    private let exerciseRepo = ExerciseRepository()

    init() {
        print("🔧 DynamicProgramGenerator init() called")
        print("🔧 ExerciseRepository created")
    }

    // MARK: - Main Generation Function

    /// Generate program and return result with any warnings
    func generateProgramWithWarnings(from questionnaireData: QuestionnaireData) throws -> ProgramGenerationResult {
        var allWarnings: [ExerciseSelectionWarning] = []

        print("🏋️ Generating dynamic program from questionnaire data...")
        print("   Days per week: \(questionnaireData.trainingDaysPerWeek)")
        print("   Experience (raw): \(questionnaireData.experienceLevel)")
        print("   Goal: \(questionnaireData.primaryGoal)")
        print("   📦 Equipment from questionnaire: \(questionnaireData.equipmentAvailable)")

        // Map questionnaire data to program parameters
        let experienceLevel = ExperienceLevel.fromQuestionnaire(questionnaireData.experienceLevel)
        let availableEquipment = ExerciseDatabaseFilter.mapEquipmentFromQuestionnaire(questionnaireData.equipmentAvailable)
        let splitType = determineSplitType(
            days: questionnaireData.trainingDaysPerWeek,
            duration: questionnaireData.sessionDuration
        )
        let sessionDuration = mapSessionDuration(questionnaireData.sessionDuration)

        print("   🔄 Experience mapped to: \(experienceLevel)")
        print("   🔄 Equipment mapped to DB values: \(availableEquipment)")

        // Get complexity rules for this user (hardcoded based on experience level)
        let complexityRules = experienceLevel.complexityRules
        print("   Max complexity: \(complexityRules.maxComplexity)")
        print("   Max complexity-4 per session: \(complexityRules.maxComplexity4PerSession)")
        print("   Complexity-4 must be first: \(complexityRules.complexity4MustBeFirst)")

        // Generate sessions based on split type (with warnings)
        let (sessions, sessionWarnings) = try generateSessionsWithWarnings(
            splitType: splitType,
            sessionDuration: sessionDuration,
            experienceLevel: experienceLevel,
            availableEquipment: availableEquipment,
            userInjuries: questionnaireData.injuries,
            targetMuscles: questionnaireData.targetMuscleGroups,
            fitnessGoal: questionnaireData.primaryGoal,
            complexityRules: complexityRules,
            daysPerWeek: questionnaireData.trainingDaysPerWeek
        )
        allWarnings.append(contentsOf: sessionWarnings)

        // ROBUSTNESS: Ensure each session has at least one exercise
        print("🔍 Validating generated sessions...")
        var robustSessions: [ProgramSession] = []
        for (index, session) in sessions.enumerated() {
            print("   Session \(index): \(session.dayName) - \(session.exercises.count) exercises")
            if session.exercises.isEmpty {
                print("   🔄 Empty session detected for '\(session.dayName)' - adding emergency fallback exercises")

                // Emergency fallback: add basic bodyweight exercises
                let emergencyExercises = createEmergencyExercises(
                    for: session.dayName,
                    fitnessGoal: questionnaireData.primaryGoal,
                    experienceLevel: experienceLevel
                )

                let robustSession = ProgramSession(
                    dayName: session.dayName,
                    exercises: emergencyExercises
                )
                robustSessions.append(robustSession)

                // Add warning for emergency fallback
                allWarnings.append(ExerciseSelectionWarning.equipmentLimitedSelection(muscle: "Emergency Fallback"))
                print("   ✅ Added \(emergencyExercises.count) emergency exercises to '\(session.dayName)'")
            } else {
                robustSessions.append(session)
            }
        }

        let program = Program(
            type: splitType,
            daysPerWeek: questionnaireData.trainingDaysPerWeek,
            sessionDuration: sessionDuration,
            sessions: robustSessions,
            totalWeeks: 8
        )

        print("✅ Dynamic program generated successfully!")
        print("   Program: \(splitType.description)")
        print("   Sessions: \(sessions.count)")
        print("   Total exercises: \(sessions.reduce(0) { $0 + $1.exercises.count })")
        if !allWarnings.isEmpty {
            print("⚠️ Warnings: \(allWarnings.count)")
        }

        // Debug: Print full program details
        print("\n📋 FULL PROGRAM BREAKDOWN:")
        for session in sessions {
            print("   \(session.dayName):")
            for exercise in session.exercises {
                print("      - \(exercise.exerciseName) (complexity: \(exercise.complexityLevel), isolation: \(exercise.isIsolation), equipment: \(exercise.equipmentType))")
            }
        }
        print("")

        return ProgramGenerationResult(program: program, warnings: allWarnings)
    }

    /// Legacy method for backward compatibility
    func generateProgram(from questionnaireData: QuestionnaireData) throws -> Program {
        print("🏋️ Generating dynamic program from questionnaire data...")
        print("   Days per week: \(questionnaireData.trainingDaysPerWeek)")
        print("   Experience: \(questionnaireData.experienceLevel)")
        print("   Goal: \(questionnaireData.primaryGoal)")

        // Map questionnaire data to program parameters
        let experienceLevel = ExperienceLevel.fromQuestionnaire(questionnaireData.experienceLevel)
        let availableEquipment = ExerciseDatabaseFilter.mapEquipmentFromQuestionnaire(questionnaireData.equipmentAvailable)
        let splitType = determineSplitType(
            days: questionnaireData.trainingDaysPerWeek,
            duration: questionnaireData.sessionDuration
        )
        let sessionDuration = mapSessionDuration(questionnaireData.sessionDuration)

        // Get complexity rules for this user (hardcoded based on experience level)
        let complexityRules = experienceLevel.complexityRules
        print("   Max complexity: \(complexityRules.maxComplexity)")

        // Generate sessions based on split type
        let sessions = try generateSessions(
            splitType: splitType,
            sessionDuration: sessionDuration,
            experienceLevel: experienceLevel,
            availableEquipment: availableEquipment,
            userInjuries: questionnaireData.injuries,
            targetMuscles: questionnaireData.targetMuscleGroups,
            fitnessGoal: questionnaireData.primaryGoal,
            complexityRules: complexityRules,
            daysPerWeek: questionnaireData.trainingDaysPerWeek
        )

        // ROBUSTNESS: Ensure each session has at least one exercise (legacy method)
        print("🔍 Validating generated sessions...")
        var robustSessions: [ProgramSession] = []
        for (index, session) in sessions.enumerated() {
            print("   Session \(index): \(session.dayName) - \(session.exercises.count) exercises")
            if session.exercises.isEmpty {
                print("   🔄 Empty session detected for '\(session.dayName)' - adding emergency fallback exercises")

                // Emergency fallback: add basic bodyweight exercises
                let emergencyExercises = createEmergencyExercises(
                    for: session.dayName,
                    fitnessGoal: questionnaireData.primaryGoal,
                    experienceLevel: experienceLevel
                )

                let robustSession = ProgramSession(
                    dayName: session.dayName,
                    exercises: emergencyExercises
                )
                robustSessions.append(robustSession)
                print("   ✅ Added \(emergencyExercises.count) emergency exercises to '\(session.dayName)'")
            } else {
                robustSessions.append(session)
            }
        }

        let program = Program(
            type: splitType,
            daysPerWeek: questionnaireData.trainingDaysPerWeek,
            sessionDuration: sessionDuration,
            sessions: robustSessions,
            totalWeeks: 8
        )

        print("✅ Dynamic program generated successfully!")
        print("   Program: \(splitType.description)")
        print("   Sessions: \(sessions.count)")
        print("   Total exercises: \(sessions.reduce(0) { $0 + $1.exercises.count })")

        return program
    }

    // MARK: - Split Type Determination

    private func determineSplitType(days: Int, duration: String) -> ProgramType {
        switch days {
        case 1:
            // 1-day: Always Full Body
            return .fullBody
        case 2:
            // 2-day: 30-45min = Upper/Lower, 45-90min = Full Body
            return duration == "30-45 min" ? .upperLower : .fullBody
        case 3:
            // 3-day: Always Push/Pull/Legs
            return .pushPullLegs
        case 4:
            // 4-day: Always Upper/Lower
            return .upperLower
        case 5:
            // 5-day: Hybrid - sessions will be Push/Pull/Legs/Upper/Lower
            // Return pushPullLegs as the "type" but sessions will include Upper/Lower too
            return .pushPullLegs
        case 6:
            // 6-day: PPL x 2 (same template as 3-day, repeated twice)
            return .pushPullLegs
        default:
            return .fullBody
        }
    }

    // MARK: - Session Generation

    /// Generate sessions with warning collection
    private func generateSessionsWithWarnings(
        splitType: ProgramType,
        sessionDuration: SessionDuration,
        experienceLevel: ExperienceLevel,
        availableEquipment: [String],
        userInjuries: [String],
        targetMuscles: [String],
        fitnessGoal: String,
        complexityRules: ExperienceComplexityRules,
        daysPerWeek: Int
    ) throws -> ([ProgramSession], [ExerciseSelectionWarning]) {

        let templates = getSessionTemplates(splitType: splitType, duration: sessionDuration, daysPerWeek: daysPerWeek)
        var generatedSessions: [ProgramSession] = []
        var allWarnings: [ExerciseSelectionWarning] = []
        var usedExerciseIds = Set<String>()
        var usedDisplayNames = Set<String>()

        for template in templates {
            let (exercises, warnings) = try generateExercisesForSessionWithWarnings(
                template: template,
                experienceLevel: experienceLevel,
                availableEquipment: availableEquipment,
                userInjuries: userInjuries,
                targetMuscles: targetMuscles,
                fitnessGoal: fitnessGoal,
                complexityRules: complexityRules,
                usedExerciseIds: &usedExerciseIds,
                usedDisplayNames: &usedDisplayNames
            )

            allWarnings.append(contentsOf: warnings)

            let session = ProgramSession(
                dayName: template.dayName,
                exercises: exercises
            )
            generatedSessions.append(session)
        }

        return (generatedSessions, allWarnings)
    }

    /// Legacy method for backward compatibility
    private func generateSessions(
        splitType: ProgramType,
        sessionDuration: SessionDuration,
        experienceLevel: ExperienceLevel,
        availableEquipment: [String],
        userInjuries: [String],
        targetMuscles: [String],
        fitnessGoal: String,
        complexityRules: ExperienceComplexityRules,
        daysPerWeek: Int
    ) throws -> [ProgramSession] {

        let (sessions, _) = try generateSessionsWithWarnings(
            splitType: splitType,
            sessionDuration: sessionDuration,
            experienceLevel: experienceLevel,
            availableEquipment: availableEquipment,
            userInjuries: userInjuries,
            targetMuscles: targetMuscles,
            fitnessGoal: fitnessGoal,
            complexityRules: complexityRules,
            daysPerWeek: daysPerWeek
        )
        return sessions
    }

    // MARK: - Exercise Selection for Session

    /// Generate exercises for a session with warning collection
    private func generateExercisesForSessionWithWarnings(
        template: SessionTemplate,
        experienceLevel: ExperienceLevel,
        availableEquipment: [String],
        userInjuries: [String],
        targetMuscles: [String],
        fitnessGoal: String,
        complexityRules: ExperienceComplexityRules,
        usedExerciseIds: inout Set<String>,
        usedDisplayNames: inout Set<String>
    ) throws -> ([ProgramExercise], [ExerciseSelectionWarning]) {

        var sessionExercises: [ProgramExercise] = []
        var sessionWarnings: [ExerciseSelectionWarning] = []
        var sessionHasComplexity4 = false

        // Session-level canonical name tracking (reset per session)
        // This prevents variations like "Bench Press", "Incline Bench Press", "Decline Bench Press" in same session
        var sessionCanonicalNames = Set<String>()

        // Process each muscle group in the template
        for (index, muscleGroup) in template.muscleGroups.enumerated() {
            var targetCount = muscleGroup.count

            // Apply target muscle priority boost
            if targetMuscles.contains(muscleGroup.muscle) {
                targetCount += 1
            }

            // Determine if complexity-4 is allowed for this exercise slot
            let isFirstExercise = (index == 0)
            let allowComplexity4 = isFirstExercise &&
                !sessionHasComplexity4 &&
                complexityRules.maxComplexity4PerSession > 0
            let requireComplexity4First = complexityRules.complexity4MustBeFirst

            // Select exercises from database using new scoring system
            print("🔍 Selecting exercises for: \(muscleGroup.muscle) (need \(targetCount))")
            print("   Equipment: \(availableEquipment)")
            print("   Injuries: \(userInjuries)")
            print("   Already used: \(usedExerciseIds.count) exercises")

            print("   🚫 Session canonical names already used: \(sessionCanonicalNames)")

            // Try to select exercises with full constraints first
            let result: ExerciseSelectionResult
            do {
                result = try exerciseRepo.selectExercisesWithWarnings(
                    count: targetCount,
                    movementPattern: muscleGroup.movementPattern,
                    primaryMuscle: muscleGroup.muscle,
                    experienceLevel: experienceLevel,
                    availableEquipment: availableEquipment,
                    userInjuries: userInjuries,
                    excludedExerciseIds: usedExerciseIds,
                    excludedDisplayNames: usedDisplayNames,
                    excludedCanonicalNames: sessionCanonicalNames,  // Session-level: no same movement in one session
                    allowComplexity4: allowComplexity4,
                    requireComplexity4First: requireComplexity4First
                )
            } catch {
                print("   🔄 Database error for \(muscleGroup.muscle): \(error.localizedDescription)")
                print("   🔄 Attempting fallback selection with relaxed constraints...")

                // Fallback: Try with relaxed constraints
                do {
                    result = try exerciseRepo.selectExercisesWithWarnings(
                        count: targetCount,
                        movementPattern: nil, // Remove movement pattern constraint
                        primaryMuscle: muscleGroup.muscle,
                        experienceLevel: .beginner, // Use beginner level for broader selection
                        availableEquipment: ["Bodyweight", "Dumbbells", "Barbell"], // Basic equipment
                        userInjuries: [],
                        excludedExerciseIds: Set<String>(), // Clear exclusions
                        excludedDisplayNames: Set<String>(),
                        excludedCanonicalNames: Set<String>(),
                        allowComplexity4: false,
                        requireComplexity4First: false
                    )
                    print("   ✅ Fallback selection found \(result.exercises.count) exercises for \(muscleGroup.muscle)")
                } catch {
                    print("   ❌ Fallback also failed for \(muscleGroup.muscle): \(error.localizedDescription)")
                    // Last resort: create empty result but program will still continue
                    result = ExerciseSelectionResult(exercises: [], warnings: [
                        ExerciseSelectionWarning.noExercisesForMuscle(muscle: muscleGroup.muscle)
                    ])
                }
            }

            // Collect warnings
            sessionWarnings.append(contentsOf: result.warnings)

            print("   ✅ Found \(result.exercises.count) exercises for \(muscleGroup.muscle)")
            if result.exercises.isEmpty {
                print("   ⚠️  NO EXERCISES FOUND for \(muscleGroup.muscle) - session will skip this muscle group")
            }

            // Convert to ProgramExercise with sets/reps based on goal
            for dbExercise in result.exercises {
                let programExercise = createProgramExercise(
                    from: dbExercise,
                    fitnessGoal: fitnessGoal,
                    experienceLevel: experienceLevel
                )
                sessionExercises.append(programExercise)
                usedExerciseIds.insert(dbExercise.exerciseId)
                usedDisplayNames.insert(dbExercise.displayName)
                sessionCanonicalNames.insert(dbExercise.canonicalName)  // Session-level dedup
                print("      ➕ Added: \(dbExercise.displayName) (canonical: \(dbExercise.canonicalName))")

                // Track if we added a complexity-4 exercise
                if dbExercise.numericComplexity == 4 {
                    sessionHasComplexity4 = true
                }
            }
        }

        // Sort entire session: compounds first (by complexity descending), then isolations (by complexity descending)
        sessionExercises.sort { lhs, rhs in
            // First: compounds before isolations
            if lhs.isIsolation != rhs.isIsolation {
                return !lhs.isIsolation  // compounds (false) come before isolations (true)
            }
            // Second: higher complexity first
            return lhs.complexityLevel > rhs.complexityLevel
        }

        return (sessionExercises, sessionWarnings)
    }

    /// Legacy method for backward compatibility
    private func generateExercisesForSession(
        template: SessionTemplate,
        experienceLevel: ExperienceLevel,
        availableEquipment: [String],
        userInjuries: [String],
        targetMuscles: [String],
        fitnessGoal: String,
        complexityRules: ExperienceComplexityRules,
        usedExerciseIds: inout Set<String>,
        usedDisplayNames: inout Set<String>
    ) throws -> [ProgramExercise] {

        let (exercises, _) = try generateExercisesForSessionWithWarnings(
            template: template,
            experienceLevel: experienceLevel,
            availableEquipment: availableEquipment,
            userInjuries: userInjuries,
            targetMuscles: targetMuscles,
            fitnessGoal: fitnessGoal,
            complexityRules: complexityRules,
            usedExerciseIds: &usedExerciseIds,
            usedDisplayNames: &usedDisplayNames
        )
        return exercises
    }

    // MARK: - ProgramExercise Creation

    private func createProgramExercise(
        from dbExercise: DBExercise,
        fitnessGoal: String,
        experienceLevel: ExperienceLevel
    ) -> ProgramExercise {

        // Determine rep range based on fitness goal (BUSINESS RULE)
        let repRange = getRepRangeForGoal(fitnessGoal)

        // Determine sets based on experience level
        let sets = getSetsForExperience(experienceLevel)

        // Determine rest period based on complexity and rep range
        let rest = getRestSeconds(
            complexityLevel: dbExercise.numericComplexity,
            repRange: repRange
        )

        return ProgramExercise(
            exerciseId: dbExercise.exerciseId,
            exerciseName: dbExercise.displayName,
            sets: sets,
            repRange: repRange,
            restSeconds: rest,
            primaryMuscle: dbExercise.primaryMuscle,
            equipmentType: dbExercise.equipmentName ?? "Unknown",
            complexityLevel: dbExercise.complexityLevel,
            isIsolation: dbExercise.isIsolation
        )
    }

    // MARK: - Rep Range Rules (BUSINESS LOGIC)

    private func getRepRangeForGoal(_ goal: String) -> String {
        switch goal {
        case "get_stronger":
            return "5-8"
        case "build_muscle":
            return "8-12"
        case "tone_up":
            return "10-15"
        default:
            return "8-12" // Default to hypertrophy
        }
    }

    private func getSetsForExperience(_ experience: ExperienceLevel) -> Int {
        switch experience {
        case .noExperience:
            return 3
        case .beginner:
            return 3
        case .intermediate:
            return 3
        case .advanced:
            return 4
        }
    }

    private func getRestSeconds(complexityLevel: Int, repRange: String) -> Int {
        let isLowReps = repRange.starts(with: "5") || repRange.starts(with: "6")
        let isHighComplexity = complexityLevel >= 3

        if isHighComplexity && isLowReps {
            return 180 // 3 minutes for heavy compounds
        } else if isHighComplexity {
            return 120 // 2 minutes for complex exercises
        } else if isLowReps {
            return 150 // 2.5 minutes for heavy work
        } else {
            return 90 // 90 seconds for isolation/accessories
        }
    }

    // MARK: - Session Templates

    private struct SessionTemplate {
        let dayName: String
        let muscleGroups: [(muscle: String, count: Int, movementPattern: String?)]
    }

    private func getSessionTemplates(
        splitType: ProgramType,
        duration: SessionDuration,
        daysPerWeek: Int
    ) -> [SessionTemplate] {
        // Handle special cases first
        if daysPerWeek == 1 {
            return get1DayTemplates(duration: duration)
        }
        if daysPerWeek == 5 {
            return get5DayTemplates(duration: duration)
        }
        if daysPerWeek == 6 {
            return get6DayTemplates(duration: duration)
        }

        switch splitType {
        case .fullBody:
            return getFullBodyTemplates(duration: duration)
        case .upperLower:
            return getUpperLowerTemplates(duration: duration, daysPerWeek: daysPerWeek)
        case .pushPullLegs:
            return getPushPullLegsTemplates(duration: duration)
        }
    }

    private func getFullBodyTemplates(duration: SessionDuration) -> [SessionTemplate] {
        // Based on split_templates.json
        // 45-60 min: ["1 Chest", "1 Shoulder", "1 Back", "1 Quad", "1 Hamstring", "1 Glute", "1 Core"]
        // 60-90 min: ["1 Chest", "1 Shoulder", "1 Back", "1 Bicep", "1 Tricep", "1 Quad", "1 Hamstring", "1 Glute", "1 Core"]

        switch duration {
        case .medium:
            // 45-60 min: 2 Full Body sessions
            return [
                SessionTemplate(dayName: "Full Body", muscleGroups: [
                    (muscle: "Chest", count: 1, movementPattern: nil),
                    (muscle: "Shoulders", count: 1, movementPattern: nil),
                    (muscle: "Back", count: 1, movementPattern: nil),
                    (muscle: "Quads", count: 1, movementPattern: nil),
                    (muscle: "Hamstrings", count: 1, movementPattern: nil),
                    (muscle: "Glutes", count: 1, movementPattern: nil),
                    (muscle: "Core", count: 1, movementPattern: nil)
                ]),
                SessionTemplate(dayName: "Full Body", muscleGroups: [
                    (muscle: "Chest", count: 1, movementPattern: nil),
                    (muscle: "Shoulders", count: 1, movementPattern: nil),
                    (muscle: "Back", count: 1, movementPattern: nil),
                    (muscle: "Quads", count: 1, movementPattern: nil),
                    (muscle: "Hamstrings", count: 1, movementPattern: nil),
                    (muscle: "Glutes", count: 1, movementPattern: nil),
                    (muscle: "Core", count: 1, movementPattern: nil)
                ])
            ]
        case .long:
            // 60-90 min: 2 Full Body sessions
            return [
                SessionTemplate(dayName: "Full Body", muscleGroups: [
                    (muscle: "Chest", count: 1, movementPattern: nil),
                    (muscle: "Shoulders", count: 1, movementPattern: nil),
                    (muscle: "Back", count: 1, movementPattern: nil),
                    (muscle: "Biceps", count: 1, movementPattern: nil),
                    (muscle: "Triceps", count: 1, movementPattern: nil),
                    (muscle: "Quads", count: 1, movementPattern: nil),
                    (muscle: "Hamstrings", count: 1, movementPattern: nil),
                    (muscle: "Glutes", count: 1, movementPattern: nil),
                    (muscle: "Core", count: 1, movementPattern: nil)
                ]),
                SessionTemplate(dayName: "Full Body", muscleGroups: [
                    (muscle: "Chest", count: 1, movementPattern: nil),
                    (muscle: "Shoulders", count: 1, movementPattern: nil),
                    (muscle: "Back", count: 1, movementPattern: nil),
                    (muscle: "Biceps", count: 1, movementPattern: nil),
                    (muscle: "Triceps", count: 1, movementPattern: nil),
                    (muscle: "Quads", count: 1, movementPattern: nil),
                    (muscle: "Hamstrings", count: 1, movementPattern: nil),
                    (muscle: "Glutes", count: 1, movementPattern: nil),
                    (muscle: "Core", count: 1, movementPattern: nil)
                ])
            ]
        default:
            return []
        }
    }

    private func getUpperLowerTemplates(duration: SessionDuration, daysPerWeek: Int) -> [SessionTemplate] {
        // Based on split_templates.json
        // 2-day 30-45min: Upper ["1 Chest", "1 Shoulder", "1 Back"], Lower ["1 Quad", "1 Quad", "1 Hamstring", "1 Glute", "1 Core"]
        // 4-day 30-45min: 2x Upper, 2x Lower
        // 4-day 45-60min: Upper ["2 Chest", "2 Shoulder", "2 Back"], Lower ["2 Quad", "2 Hamstring", "1 Glute", "1 Core"]
        // 4-day 60-90min: Upper ["2 Chest", "2 Shoulder", "2 Back", "1 Tricep", "1 Bicep"], Lower ["2 Quad", "2 Hamstring", "1 Glute", "1 Core"]

        switch (daysPerWeek, duration) {
        case (2, .short):
            // 2-day, 30-45 min
            return [
                SessionTemplate(dayName: "Upper", muscleGroups: [
                    (muscle: "Chest", count: 1, movementPattern: nil),
                    (muscle: "Shoulders", count: 1, movementPattern: nil),
                    (muscle: "Back", count: 1, movementPattern: nil)
                ]),
                SessionTemplate(dayName: "Lower", muscleGroups: [
                    (muscle: "Quads", count: 2, movementPattern: nil),
                    (muscle: "Hamstrings", count: 1, movementPattern: nil),
                    (muscle: "Glutes", count: 1, movementPattern: nil),
                    (muscle: "Core", count: 1, movementPattern: nil)
                ])
            ]
        case (4, .short):
            // 4-day, 30-45 min
            return [
                SessionTemplate(dayName: "Upper", muscleGroups: [
                    (muscle: "Chest", count: 1, movementPattern: nil),
                    (muscle: "Shoulders", count: 1, movementPattern: nil),
                    (muscle: "Back", count: 1, movementPattern: nil)
                ]),
                SessionTemplate(dayName: "Lower", muscleGroups: [
                    (muscle: "Quads", count: 1, movementPattern: nil),
                    (muscle: "Hamstrings", count: 1, movementPattern: nil),
                    (muscle: "Glutes", count: 1, movementPattern: nil),
                    (muscle: "Core", count: 1, movementPattern: nil)
                ]),
                SessionTemplate(dayName: "Upper", muscleGroups: [
                    (muscle: "Chest", count: 1, movementPattern: nil),
                    (muscle: "Shoulders", count: 1, movementPattern: nil),
                    (muscle: "Back", count: 1, movementPattern: nil)
                ]),
                SessionTemplate(dayName: "Lower", muscleGroups: [
                    (muscle: "Quads", count: 1, movementPattern: nil),
                    (muscle: "Hamstrings", count: 1, movementPattern: nil),
                    (muscle: "Glutes", count: 1, movementPattern: nil),
                    (muscle: "Core", count: 1, movementPattern: nil)
                ])
            ]
        case (4, .medium):
            // 4-day, 45-60 min
            return [
                SessionTemplate(dayName: "Upper", muscleGroups: [
                    (muscle: "Chest", count: 2, movementPattern: nil),
                    (muscle: "Shoulders", count: 2, movementPattern: nil),
                    (muscle: "Back", count: 2, movementPattern: nil)
                ]),
                SessionTemplate(dayName: "Lower", muscleGroups: [
                    (muscle: "Quads", count: 2, movementPattern: nil),
                    (muscle: "Hamstrings", count: 2, movementPattern: nil),
                    (muscle: "Glutes", count: 1, movementPattern: nil),
                    (muscle: "Core", count: 1, movementPattern: nil)
                ]),
                SessionTemplate(dayName: "Upper", muscleGroups: [
                    (muscle: "Chest", count: 2, movementPattern: nil),
                    (muscle: "Shoulders", count: 2, movementPattern: nil),
                    (muscle: "Back", count: 2, movementPattern: nil)
                ]),
                SessionTemplate(dayName: "Lower", muscleGroups: [
                    (muscle: "Quads", count: 2, movementPattern: nil),
                    (muscle: "Hamstrings", count: 2, movementPattern: nil),
                    (muscle: "Glutes", count: 1, movementPattern: nil),
                    (muscle: "Core", count: 1, movementPattern: nil)
                ])
            ]
        case (4, .long):
            // 4-day, 60-90 min
            return [
                SessionTemplate(dayName: "Upper", muscleGroups: [
                    (muscle: "Chest", count: 2, movementPattern: nil),
                    (muscle: "Shoulders", count: 2, movementPattern: nil),
                    (muscle: "Back", count: 2, movementPattern: nil),
                    (muscle: "Triceps", count: 1, movementPattern: nil),
                    (muscle: "Biceps", count: 1, movementPattern: nil)
                ]),
                SessionTemplate(dayName: "Lower", muscleGroups: [
                    (muscle: "Quads", count: 2, movementPattern: nil),
                    (muscle: "Hamstrings", count: 2, movementPattern: nil),
                    (muscle: "Glutes", count: 1, movementPattern: nil),
                    (muscle: "Core", count: 1, movementPattern: nil)
                ]),
                SessionTemplate(dayName: "Upper", muscleGroups: [
                    (muscle: "Chest", count: 2, movementPattern: nil),
                    (muscle: "Shoulders", count: 2, movementPattern: nil),
                    (muscle: "Back", count: 2, movementPattern: nil),
                    (muscle: "Triceps", count: 1, movementPattern: nil),
                    (muscle: "Biceps", count: 1, movementPattern: nil)
                ]),
                SessionTemplate(dayName: "Lower", muscleGroups: [
                    (muscle: "Quads", count: 2, movementPattern: nil),
                    (muscle: "Hamstrings", count: 2, movementPattern: nil),
                    (muscle: "Glutes", count: 1, movementPattern: nil),
                    (muscle: "Core", count: 1, movementPattern: nil)
                ])
            ]
        default:
            return []
        }
    }

    private func getPushPullLegsTemplates(duration: SessionDuration) -> [SessionTemplate] {
        // Based on split_templates.json
        // 3-day 30-45min: Push ["1 Chest", "2 Shoulder", "1 Tricep"], Pull ["2 Back", "2 Bicep"], Legs ["1 Quad", "1 Hamstring", "1 Glute", "1 Core"]
        // 3-day 45-60min: Push ["2 Chest", "2 Shoulder", "1 Tricep"], Pull ["3 Back", "2 Bicep"], Legs ["2 Quad", "2 Hamstring", "1 Glute", "1 Core"]
        // 3-day 60-90min: Push ["3 Chest", "3 Shoulder", "2 Tricep"], Pull ["3 Back", "3 Bicep"], Legs ["2 Quad", "2 Hamstring", "1 Glute", "1 Core"]

        switch duration {
        case .short:
            // 30-45 min
            return [
                SessionTemplate(dayName: "Push", muscleGroups: [
                    (muscle: "Chest", count: 1, movementPattern: nil),
                    (muscle: "Shoulders", count: 2, movementPattern: nil),
                    (muscle: "Triceps", count: 1, movementPattern: nil)
                ]),
                SessionTemplate(dayName: "Pull", muscleGroups: [
                    (muscle: "Back", count: 2, movementPattern: nil),
                    (muscle: "Biceps", count: 2, movementPattern: nil)
                ]),
                SessionTemplate(dayName: "Legs", muscleGroups: [
                    (muscle: "Quads", count: 1, movementPattern: nil),
                    (muscle: "Hamstrings", count: 1, movementPattern: nil),
                    (muscle: "Glutes", count: 1, movementPattern: nil),
                    (muscle: "Core", count: 1, movementPattern: nil)
                ])
            ]
        case .medium:
            // 45-60 min
            return [
                SessionTemplate(dayName: "Push", muscleGroups: [
                    (muscle: "Chest", count: 2, movementPattern: nil),
                    (muscle: "Shoulders", count: 2, movementPattern: nil),
                    (muscle: "Triceps", count: 1, movementPattern: nil)
                ]),
                SessionTemplate(dayName: "Pull", muscleGroups: [
                    (muscle: "Back", count: 3, movementPattern: nil),
                    (muscle: "Biceps", count: 2, movementPattern: nil)
                ]),
                SessionTemplate(dayName: "Legs", muscleGroups: [
                    (muscle: "Quads", count: 2, movementPattern: nil),
                    (muscle: "Hamstrings", count: 2, movementPattern: nil),
                    (muscle: "Glutes", count: 1, movementPattern: nil),
                    (muscle: "Core", count: 1, movementPattern: nil)
                ])
            ]
        case .long:
            // 60-90 min
            return [
                SessionTemplate(dayName: "Push", muscleGroups: [
                    (muscle: "Chest", count: 3, movementPattern: nil),
                    (muscle: "Shoulders", count: 3, movementPattern: nil),
                    (muscle: "Triceps", count: 2, movementPattern: nil)
                ]),
                SessionTemplate(dayName: "Pull", muscleGroups: [
                    (muscle: "Back", count: 3, movementPattern: nil),
                    (muscle: "Biceps", count: 3, movementPattern: nil)
                ]),
                SessionTemplate(dayName: "Legs", muscleGroups: [
                    (muscle: "Quads", count: 2, movementPattern: nil),
                    (muscle: "Hamstrings", count: 2, movementPattern: nil),
                    (muscle: "Glutes", count: 1, movementPattern: nil),
                    (muscle: "Core", count: 1, movementPattern: nil)
                ])
            ]
        }
    }

    private func get5DayTemplates(duration: SessionDuration) -> [SessionTemplate] {
        // Based on split_templates.json
        // 5-day is hybrid: Push/Pull/Legs/Upper/Lower
        // 5-day 30-45min: Push ["1 Chest", "2 Shoulder", "1 Tricep"], Pull ["2 Back", "2 Bicep"], Legs ["1 Quad", "1 Hamstring", "1 Glute", "1 Core"], Upper ["1 Chest", "1 Shoulder", "1 Back"], Lower ["1 Quad", "1 Hamstring", "1 Glute", "1 Core"]
        // 5-day 45-60min: Push ["2 Chest", "2 Shoulder", "1 Tricep"], Pull ["3 Back", "2 Bicep"], Legs ["2 Quad", "2 Hamstring", "1 Glute", "1 Core"], Upper ["2 Chest", "2 Shoulder", "2 Back"], Lower ["2 Quad", "2 Hamstring", "1 Glute", "1 Core"]
        // 5-day 60-90min: Push ["3 Chest", "3 Shoulder", "2 Tricep"], Pull ["3 Back", "3 Bicep"], Legs ["2 Quad", "2 Hamstring", "1 Glute", "1 Core"], Upper ["2 Chest", "2 Shoulder", "2 Back", "1 Tricep", "1 Bicep"], Lower ["2 Quad", "2 Hamstring", "1 Glute", "1 Core"]

        switch duration {
        case .short:
            // 30-45 min
            return [
                SessionTemplate(dayName: "Push", muscleGroups: [
                    (muscle: "Chest", count: 1, movementPattern: nil),
                    (muscle: "Shoulders", count: 2, movementPattern: nil),
                    (muscle: "Triceps", count: 1, movementPattern: nil)
                ]),
                SessionTemplate(dayName: "Pull", muscleGroups: [
                    (muscle: "Back", count: 2, movementPattern: nil),
                    (muscle: "Biceps", count: 2, movementPattern: nil)
                ]),
                SessionTemplate(dayName: "Legs", muscleGroups: [
                    (muscle: "Quads", count: 1, movementPattern: nil),
                    (muscle: "Hamstrings", count: 1, movementPattern: nil),
                    (muscle: "Glutes", count: 1, movementPattern: nil),
                    (muscle: "Core", count: 1, movementPattern: nil)
                ]),
                SessionTemplate(dayName: "Upper", muscleGroups: [
                    (muscle: "Chest", count: 1, movementPattern: nil),
                    (muscle: "Shoulders", count: 1, movementPattern: nil),
                    (muscle: "Back", count: 1, movementPattern: nil)
                ]),
                SessionTemplate(dayName: "Lower", muscleGroups: [
                    (muscle: "Quads", count: 1, movementPattern: nil),
                    (muscle: "Hamstrings", count: 1, movementPattern: nil),
                    (muscle: "Glutes", count: 1, movementPattern: nil),
                    (muscle: "Core", count: 1, movementPattern: nil)
                ])
            ]
        case .medium:
            // 45-60 min
            return [
                SessionTemplate(dayName: "Push", muscleGroups: [
                    (muscle: "Chest", count: 2, movementPattern: nil),
                    (muscle: "Shoulders", count: 2, movementPattern: nil),
                    (muscle: "Triceps", count: 1, movementPattern: nil)
                ]),
                SessionTemplate(dayName: "Pull", muscleGroups: [
                    (muscle: "Back", count: 3, movementPattern: nil),
                    (muscle: "Biceps", count: 2, movementPattern: nil)
                ]),
                SessionTemplate(dayName: "Legs", muscleGroups: [
                    (muscle: "Quads", count: 2, movementPattern: nil),
                    (muscle: "Hamstrings", count: 2, movementPattern: nil),
                    (muscle: "Glutes", count: 1, movementPattern: nil),
                    (muscle: "Core", count: 1, movementPattern: nil)
                ]),
                SessionTemplate(dayName: "Upper", muscleGroups: [
                    (muscle: "Chest", count: 2, movementPattern: nil),
                    (muscle: "Shoulders", count: 2, movementPattern: nil),
                    (muscle: "Back", count: 2, movementPattern: nil)
                ]),
                SessionTemplate(dayName: "Lower", muscleGroups: [
                    (muscle: "Quads", count: 2, movementPattern: nil),
                    (muscle: "Hamstrings", count: 2, movementPattern: nil),
                    (muscle: "Glutes", count: 1, movementPattern: nil),
                    (muscle: "Core", count: 1, movementPattern: nil)
                ])
            ]
        case .long:
            // 60-90 min
            return [
                SessionTemplate(dayName: "Push", muscleGroups: [
                    (muscle: "Chest", count: 3, movementPattern: nil),
                    (muscle: "Shoulders", count: 3, movementPattern: nil),
                    (muscle: "Triceps", count: 2, movementPattern: nil)
                ]),
                SessionTemplate(dayName: "Pull", muscleGroups: [
                    (muscle: "Back", count: 3, movementPattern: nil),
                    (muscle: "Biceps", count: 3, movementPattern: nil)
                ]),
                SessionTemplate(dayName: "Legs", muscleGroups: [
                    (muscle: "Quads", count: 2, movementPattern: nil),
                    (muscle: "Hamstrings", count: 2, movementPattern: nil),
                    (muscle: "Glutes", count: 1, movementPattern: nil),
                    (muscle: "Core", count: 1, movementPattern: nil)
                ]),
                SessionTemplate(dayName: "Upper", muscleGroups: [
                    (muscle: "Chest", count: 2, movementPattern: nil),
                    (muscle: "Shoulders", count: 2, movementPattern: nil),
                    (muscle: "Back", count: 2, movementPattern: nil),
                    (muscle: "Triceps", count: 1, movementPattern: nil),
                    (muscle: "Biceps", count: 1, movementPattern: nil)
                ]),
                SessionTemplate(dayName: "Lower", muscleGroups: [
                    (muscle: "Quads", count: 2, movementPattern: nil),
                    (muscle: "Hamstrings", count: 2, movementPattern: nil),
                    (muscle: "Glutes", count: 1, movementPattern: nil),
                    (muscle: "Core", count: 1, movementPattern: nil)
                ])
            ]
        }
    }

    private func get1DayTemplates(duration: SessionDuration) -> [SessionTemplate] {
        // 1-day: Single Full Body session hitting all major muscle groups
        // Focus on compound movements to maximize efficiency
        switch duration {
        case .short:
            // 30-45 min: Abbreviated full body
            return [
                SessionTemplate(dayName: "Full Body", muscleGroups: [
                    (muscle: "Chest", count: 1, movementPattern: nil),
                    (muscle: "Back", count: 1, movementPattern: nil),
                    (muscle: "Shoulders", count: 1, movementPattern: nil),
                    (muscle: "Quads", count: 1, movementPattern: nil),
                    (muscle: "Hamstrings", count: 1, movementPattern: nil),
                    (muscle: "Core", count: 1, movementPattern: nil)
                ])
            ]
        case .medium:
            // 45-60 min: Standard full body
            return [
                SessionTemplate(dayName: "Full Body", muscleGroups: [
                    (muscle: "Chest", count: 1, movementPattern: nil),
                    (muscle: "Back", count: 2, movementPattern: nil),
                    (muscle: "Shoulders", count: 1, movementPattern: nil),
                    (muscle: "Quads", count: 1, movementPattern: nil),
                    (muscle: "Hamstrings", count: 1, movementPattern: nil),
                    (muscle: "Glutes", count: 1, movementPattern: nil),
                    (muscle: "Core", count: 1, movementPattern: nil)
                ])
            ]
        case .long:
            // 60-90 min: Extended full body with arm work
            return [
                SessionTemplate(dayName: "Full Body", muscleGroups: [
                    (muscle: "Chest", count: 2, movementPattern: nil),
                    (muscle: "Back", count: 2, movementPattern: nil),
                    (muscle: "Shoulders", count: 1, movementPattern: nil),
                    (muscle: "Biceps", count: 1, movementPattern: nil),
                    (muscle: "Triceps", count: 1, movementPattern: nil),
                    (muscle: "Quads", count: 1, movementPattern: nil),
                    (muscle: "Hamstrings", count: 1, movementPattern: nil),
                    (muscle: "Glutes", count: 1, movementPattern: nil),
                    (muscle: "Core", count: 1, movementPattern: nil)
                ])
            ]
        }
    }

    private func get6DayTemplates(duration: SessionDuration) -> [SessionTemplate] {
        // 6-day: PPL x 2 (Push/Pull/Legs repeated twice)
        // Each muscle group gets hit twice per week for optimal hypertrophy
        switch duration {
        case .short:
            // 30-45 min
            return [
                SessionTemplate(dayName: "Push", muscleGroups: [
                    (muscle: "Chest", count: 1, movementPattern: nil),
                    (muscle: "Shoulders", count: 2, movementPattern: nil),
                    (muscle: "Triceps", count: 1, movementPattern: nil)
                ]),
                SessionTemplate(dayName: "Pull", muscleGroups: [
                    (muscle: "Back", count: 2, movementPattern: nil),
                    (muscle: "Biceps", count: 2, movementPattern: nil)
                ]),
                SessionTemplate(dayName: "Legs", muscleGroups: [
                    (muscle: "Quads", count: 1, movementPattern: nil),
                    (muscle: "Hamstrings", count: 1, movementPattern: nil),
                    (muscle: "Glutes", count: 1, movementPattern: nil),
                    (muscle: "Core", count: 1, movementPattern: nil)
                ]),
                SessionTemplate(dayName: "Push", muscleGroups: [
                    (muscle: "Chest", count: 1, movementPattern: nil),
                    (muscle: "Shoulders", count: 2, movementPattern: nil),
                    (muscle: "Triceps", count: 1, movementPattern: nil)
                ]),
                SessionTemplate(dayName: "Pull", muscleGroups: [
                    (muscle: "Back", count: 2, movementPattern: nil),
                    (muscle: "Biceps", count: 2, movementPattern: nil)
                ]),
                SessionTemplate(dayName: "Legs", muscleGroups: [
                    (muscle: "Quads", count: 1, movementPattern: nil),
                    (muscle: "Hamstrings", count: 1, movementPattern: nil),
                    (muscle: "Glutes", count: 1, movementPattern: nil),
                    (muscle: "Core", count: 1, movementPattern: nil)
                ])
            ]
        case .medium:
            // 45-60 min
            return [
                SessionTemplate(dayName: "Push", muscleGroups: [
                    (muscle: "Chest", count: 2, movementPattern: nil),
                    (muscle: "Shoulders", count: 2, movementPattern: nil),
                    (muscle: "Triceps", count: 1, movementPattern: nil)
                ]),
                SessionTemplate(dayName: "Pull", muscleGroups: [
                    (muscle: "Back", count: 3, movementPattern: nil),
                    (muscle: "Biceps", count: 2, movementPattern: nil)
                ]),
                SessionTemplate(dayName: "Legs", muscleGroups: [
                    (muscle: "Quads", count: 2, movementPattern: nil),
                    (muscle: "Hamstrings", count: 2, movementPattern: nil),
                    (muscle: "Glutes", count: 1, movementPattern: nil),
                    (muscle: "Core", count: 1, movementPattern: nil)
                ]),
                SessionTemplate(dayName: "Push", muscleGroups: [
                    (muscle: "Chest", count: 2, movementPattern: nil),
                    (muscle: "Shoulders", count: 2, movementPattern: nil),
                    (muscle: "Triceps", count: 1, movementPattern: nil)
                ]),
                SessionTemplate(dayName: "Pull", muscleGroups: [
                    (muscle: "Back", count: 3, movementPattern: nil),
                    (muscle: "Biceps", count: 2, movementPattern: nil)
                ]),
                SessionTemplate(dayName: "Legs", muscleGroups: [
                    (muscle: "Quads", count: 2, movementPattern: nil),
                    (muscle: "Hamstrings", count: 2, movementPattern: nil),
                    (muscle: "Glutes", count: 1, movementPattern: nil),
                    (muscle: "Core", count: 1, movementPattern: nil)
                ])
            ]
        case .long:
            // 60-90 min
            return [
                SessionTemplate(dayName: "Push", muscleGroups: [
                    (muscle: "Chest", count: 3, movementPattern: nil),
                    (muscle: "Shoulders", count: 3, movementPattern: nil),
                    (muscle: "Triceps", count: 2, movementPattern: nil)
                ]),
                SessionTemplate(dayName: "Pull", muscleGroups: [
                    (muscle: "Back", count: 3, movementPattern: nil),
                    (muscle: "Biceps", count: 3, movementPattern: nil)
                ]),
                SessionTemplate(dayName: "Legs", muscleGroups: [
                    (muscle: "Quads", count: 2, movementPattern: nil),
                    (muscle: "Hamstrings", count: 2, movementPattern: nil),
                    (muscle: "Glutes", count: 1, movementPattern: nil),
                    (muscle: "Core", count: 1, movementPattern: nil)
                ]),
                SessionTemplate(dayName: "Push", muscleGroups: [
                    (muscle: "Chest", count: 3, movementPattern: nil),
                    (muscle: "Shoulders", count: 3, movementPattern: nil),
                    (muscle: "Triceps", count: 2, movementPattern: nil)
                ]),
                SessionTemplate(dayName: "Pull", muscleGroups: [
                    (muscle: "Back", count: 3, movementPattern: nil),
                    (muscle: "Biceps", count: 3, movementPattern: nil)
                ]),
                SessionTemplate(dayName: "Legs", muscleGroups: [
                    (muscle: "Quads", count: 2, movementPattern: nil),
                    (muscle: "Hamstrings", count: 2, movementPattern: nil),
                    (muscle: "Glutes", count: 1, movementPattern: nil),
                    (muscle: "Core", count: 1, movementPattern: nil)
                ])
            ]
        }
    }

    // MARK: - Utility

    private func mapSessionDuration(_ durationString: String) -> SessionDuration {
        switch durationString {
        case "30-45 min":
            return .short
        case "45-60 min":
            return .medium
        case "60-90 min":
            return .long
        default:
            return .medium
        }
    }

    // MARK: - Emergency Fallback Exercises

    /// Create emergency fallback exercises when database fails to populate a session
    /// These are minimal bodyweight exercises to ensure program always has content
    private func createEmergencyExercises(
        for sessionName: String,
        fitnessGoal: String,
        experienceLevel: ExperienceLevel
    ) -> [ProgramExercise] {

        print("🚨 Creating emergency exercises for session: \(sessionName)")

        let repRange = getRepRangeForGoal(fitnessGoal)
        let sets = getSetsForExperience(experienceLevel)

        // Basic emergency exercises that require no equipment
        var emergencyExercises: [ProgramExercise] = []

        // Determine exercises based on session type
        switch sessionName.lowercased() {
        case let name where name.contains("push"):
            emergencyExercises = [
                createEmergencyExercise(name: "Push-ups", muscle: "Chest", sets: sets, repRange: repRange),
                createEmergencyExercise(name: "Pike Push-ups", muscle: "Shoulders", sets: sets, repRange: repRange)
            ]
        case let name where name.contains("pull"):
            emergencyExercises = [
                createEmergencyExercise(name: "Pull-ups (or Assisted)", muscle: "Back", sets: sets, repRange: repRange),
                createEmergencyExercise(name: "Inverted Rows", muscle: "Back", sets: sets, repRange: repRange)
            ]
        case let name where name.contains("leg"):
            emergencyExercises = [
                createEmergencyExercise(name: "Bodyweight Squats", muscle: "Quads", sets: sets, repRange: repRange),
                createEmergencyExercise(name: "Lunges", muscle: "Quads", sets: sets, repRange: repRange)
            ]
        case let name where name.contains("upper"):
            emergencyExercises = [
                createEmergencyExercise(name: "Push-ups", muscle: "Chest", sets: sets, repRange: repRange),
                createEmergencyExercise(name: "Pike Push-ups", muscle: "Shoulders", sets: sets, repRange: repRange),
                createEmergencyExercise(name: "Pull-ups (or Assisted)", muscle: "Back", sets: sets, repRange: repRange)
            ]
        case let name where name.contains("lower"):
            emergencyExercises = [
                createEmergencyExercise(name: "Bodyweight Squats", muscle: "Quads", sets: sets, repRange: repRange),
                createEmergencyExercise(name: "Lunges", muscle: "Quads", sets: sets, repRange: repRange),
                createEmergencyExercise(name: "Glute Bridges", muscle: "Glutes", sets: sets, repRange: repRange)
            ]
        default:
            // Full body fallback
            emergencyExercises = [
                createEmergencyExercise(name: "Push-ups", muscle: "Chest", sets: sets, repRange: repRange),
                createEmergencyExercise(name: "Bodyweight Squats", muscle: "Quads", sets: sets, repRange: repRange),
                createEmergencyExercise(name: "Plank", muscle: "Core", sets: sets, repRange: "30-60 sec")
            ]
        }

        print("   🚨 Emergency exercises created: \(emergencyExercises.map { $0.exerciseName }.joined(separator: ", "))")
        return emergencyExercises
    }

    /// Create a single emergency exercise
    private func createEmergencyExercise(
        name: String,
        muscle: String,
        sets: Int,
        repRange: String
    ) -> ProgramExercise {
        return ProgramExercise(
            exerciseId: "emergency_\(name.replacingOccurrences(of: " ", with: "_").lowercased())",
            exerciseName: name,
            sets: sets,
            repRange: repRange,
            restSeconds: 90,
            primaryMuscle: muscle,
            equipmentType: "Bodyweight",
            complexityLevel: 1,
            isIsolation: false
        )
    }
}
