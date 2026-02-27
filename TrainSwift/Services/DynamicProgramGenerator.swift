//
//  DynamicProgramGenerator.swift
//  TrainSwift
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
    let lowFillWarning: Bool    // Programme fill rate below 75%
    let repeatWarning: Bool     // Exercise repeats due to equipment constraints

    var hasWarnings: Bool { !warnings.isEmpty || lowFillWarning || repeatWarning }

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

// MARK: - Program Generation Errors

enum ProgramGenerationError: LocalizedError {
    case emptySelectionPool

    var errorDescription: String? {
        switch self {
        case .emptySelectionPool:
            return "No options available for random selection during program generation."
        }
    }
}

class DynamicProgramGenerator {
    private let exerciseRepo = ExerciseRepository()

    init() {
        AppLogger.logProgram("DynamicProgramGenerator init() called, ExerciseRepository created")
    }

    // MARK: - Main Generation Function

    /// Generate program and return result with any warnings
    func generateProgramWithWarnings(from questionnaireData: QuestionnaireData) throws -> ProgramGenerationResult {
        var allWarnings: [ExerciseSelectionWarning] = []

        AppLogger.logProgram("Generating dynamic program - Days: \(questionnaireData.trainingDaysPerWeek), Experience: \(questionnaireData.experienceLevel), Goals: \(questionnaireData.primaryGoals.joined(separator: ", ")), Equipment: \(questionnaireData.equipmentAvailable), Attachments: \(questionnaireData.detailedEquipment["attachments"] ?? [])")

        // Map questionnaire data to program parameters
        let experienceLevel = ExperienceLevel.fromQuestionnaire(questionnaireData.experienceLevel)
        let availableEquipment = ExerciseDatabaseFilter.mapEquipmentFromQuestionnaire(questionnaireData.equipmentAvailable)
        let availableAttachments = ExerciseDatabaseFilter.mapAttachmentsFromQuestionnaire(questionnaireData.detailedEquipment["attachments"] ?? [])
        let splitType = determineSplitType(
            days: questionnaireData.trainingDaysPerWeek,
            duration: questionnaireData.sessionDuration
        )
        let sessionDuration = mapSessionDuration(questionnaireData.sessionDuration)

        // Check for attachment warning (cables selected but no cable attachments)
        if ConstantsManager.shared.shouldShowCableAttachmentWarning(
            equipment: questionnaireData.equipmentAvailable,
            attachments: availableAttachments
        ) {
            allWarnings.append(.attachmentWarning)
        }

        AppLogger.logProgram("Mapped - Experience: \(experienceLevel), Equipment: \(availableEquipment), Attachments: \(availableAttachments)")

        // Get complexity rules for this user (hardcoded based on experience level)
        let complexityRules = experienceLevel.complexityRules
        AppLogger.logProgram("Complexity rules - Max: \(complexityRules.maxComplexity), Max-4/session: \(complexityRules.maxComplexity4PerSession), 4-must-be-first: \(complexityRules.complexity4MustBeFirst)")

        // Generate sessions based on split type (with warnings)
        let (sessions, sessionWarnings) = try generateSessionsWithWarnings(
            splitType: splitType,
            sessionDuration: sessionDuration,
            experienceLevel: experienceLevel,
            availableEquipment: availableEquipment,
            availableAttachments: availableAttachments,
            userInjuries: questionnaireData.injuries,
            targetMuscles: questionnaireData.targetMuscleGroups,
            fitnessGoal: questionnaireData.primaryGoals.first ?? "build_muscle",
            complexityRules: complexityRules,
            daysPerWeek: questionnaireData.trainingDaysPerWeek
        )
        allWarnings.append(contentsOf: sessionWarnings)

        // ROBUSTNESS: Ensure each session has at least one exercise
        AppLogger.logProgram("Validating generated sessions...")
        var robustSessions: [ProgramSession] = []
        for (index, session) in sessions.enumerated() {
            AppLogger.logProgram("Session \(index): \(session.dayName) - \(session.exercises.count) exercises")
            if session.exercises.isEmpty {
                AppLogger.logProgram("Empty session detected for '\(session.dayName)' - adding emergency fallback exercises", level: .warning)

                // Emergency fallback: add basic bodyweight exercises
                let emergencyExercises = createEmergencyExercises(
                    for: session.dayName,
                    fitnessGoal: questionnaireData.primaryGoals.first ?? "build_muscle",
                    experienceLevel: experienceLevel
                )

                let robustSession = ProgramSession(
                    dayName: session.dayName,
                    exercises: emergencyExercises
                )
                robustSessions.append(robustSession)

                // Add warning for emergency fallback
                allWarnings.append(ExerciseSelectionWarning.equipmentLimitedSelection(muscle: "Emergency Fallback"))
                AppLogger.logProgram("Added \(emergencyExercises.count) emergency exercises to '\(session.dayName)'")
            } else {
                robustSessions.append(session)
            }
        }

        // Calculate fill rates for warning detection
        let templates = getSessionTemplates(splitType: splitType, duration: sessionDuration, daysPerWeek: questionnaireData.trainingDaysPerWeek)
        var sessionFillRates: [Double] = []
        var hasRepeats = false

        for (index, session) in robustSessions.enumerated() {
            if index < templates.count {
                let template = templates[index]
                let expectedCount = template.muscleGroups.reduce(0) { $0 + $1.count }
                let actualCount = session.exercises.count
                let fillRate = Double(actualCount) / Double(expectedCount) * 100.0
                sessionFillRates.append(fillRate)
            }
        }

        // Check for exercise repeats (look for repeat warnings)
        hasRepeats = allWarnings.contains { warning in
            if case .exerciseRepeats = warning {
                return true
            }
            return false
        }

        // Check if any session is below 75% fill rate
        let lowFillWarning = sessionFillRates.contains { $0 < 75.0 }

        let program = Program(
            type: splitType,
            daysPerWeek: questionnaireData.trainingDaysPerWeek,
            sessionDuration: sessionDuration,
            sessions: robustSessions,
            totalWeeks: 8
        )

        AppLogger.logProgram("Dynamic program generated successfully! Program: \(splitType.description), Sessions: \(sessions.count), Total exercises: \(sessions.reduce(0) { $0 + $1.exercises.count }), Fill rates: \(sessionFillRates.map { String(format: "%.1f%%", $0) }.joined(separator: ", ")), Low fill: \(lowFillWarning), Repeats: \(hasRepeats)")
        if !allWarnings.isEmpty {
            AppLogger.logProgram("Warnings: \(allWarnings.count)", level: .warning)
        }

        // Debug: Print full program details
        AppLogger.logProgram("FULL PROGRAM BREAKDOWN:")
        for session in sessions {
            let exerciseList = session.exercises.map { "\($0.exerciseName) (complexity: \($0.complexityLevel), equipment: \($0.equipmentType))" }.joined(separator: ", ")
            AppLogger.logProgram("\(session.dayName): \(exerciseList)")
        }

        return ProgramGenerationResult(
            program: program,
            warnings: allWarnings,
            lowFillWarning: lowFillWarning,
            repeatWarning: hasRepeats
        )
    }

    /// Legacy method for backward compatibility — delegates to the full warnings version
    func generateProgram(from questionnaireData: QuestionnaireData) throws -> Program {
        try generateProgramWithWarnings(from: questionnaireData).program
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
        availableAttachments: [String],
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
                availableAttachments: availableAttachments,
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
        availableAttachments: [String] = [],
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
            availableAttachments: availableAttachments,
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
        availableAttachments: [String],
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
            AppLogger.logProgram("Selecting exercises for: \(muscleGroup.muscle) (need \(targetCount)) - Equipment: \(availableEquipment), Injuries: \(userInjuries), Already used: \(usedExerciseIds.count)")

            AppLogger.logProgram("Session canonical names already used: \(sessionCanonicalNames)")

            // Try to select exercises with full constraints first
            let result: ExerciseSelectionResult
            do {
                result = try exerciseRepo.selectExercisesWithWarnings(
                    count: targetCount,
                    movementPattern: muscleGroup.movementPattern,
                    primaryMuscle: muscleGroup.muscle,
                    experienceLevel: experienceLevel,
                    availableEquipment: availableEquipment,
                    availableAttachments: availableAttachments,
                    userInjuries: userInjuries,
                    excludedExerciseIds: usedExerciseIds,
                    excludedDisplayNames: usedDisplayNames,
                    excludedCanonicalNames: sessionCanonicalNames,  // Session-level: no same movement in one session
                    allowComplexity4: allowComplexity4,
                    requireComplexity4First: requireComplexity4First
                )
            } catch {
                AppLogger.logProgram("Database error for \(muscleGroup.muscle): \(error.localizedDescription) - Attempting fallback with relaxed constraints...", level: .warning)

                // Fallback: Try with relaxed constraints
                do {
                    result = try exerciseRepo.selectExercisesWithWarnings(
                        count: targetCount,
                        movementPattern: nil, // Remove movement pattern constraint
                        primaryMuscle: muscleGroup.muscle,
                        experienceLevel: .beginner, // Use beginner level for broader selection
                        availableEquipment: ["Bodyweight", "Dumbbells", "Barbell"], // Basic equipment
                        availableAttachments: [], // No attachment filtering in fallback
                        userInjuries: [],
                        excludedExerciseIds: Set<String>(), // Clear exclusions
                        excludedDisplayNames: Set<String>(),
                        excludedCanonicalNames: Set<String>(),
                        allowComplexity4: false,
                        requireComplexity4First: false
                    )
                    AppLogger.logProgram("Fallback selection found \(result.exercises.count) exercises for \(muscleGroup.muscle)")
                } catch {
                    AppLogger.logProgram("Fallback also failed for \(muscleGroup.muscle): \(error.localizedDescription)", level: .error)
                    // Last resort: create empty result but program will still continue
                    result = ExerciseSelectionResult(exercises: [], warnings: [
                        ExerciseSelectionWarning.noExercisesForMuscle(muscle: muscleGroup.muscle)
                    ])
                }
            }

            // Collect warnings
            sessionWarnings.append(contentsOf: result.warnings)

            AppLogger.logProgram("Found \(result.exercises.count) exercises for \(muscleGroup.muscle)")
            if result.exercises.isEmpty {
                AppLogger.logProgram("NO EXERCISES FOUND for \(muscleGroup.muscle) - session will skip this muscle group", level: .warning)
            }

            // Convert to ProgramExercise with sets/reps based on goal
            for dbExercise in result.exercises {
                let programExercise = try createProgramExercise(
                    from: dbExercise,
                    fitnessGoal: fitnessGoal,
                    experienceLevel: experienceLevel
                )
                sessionExercises.append(programExercise)
                usedExerciseIds.insert(dbExercise.exerciseId)
                usedDisplayNames.insert(dbExercise.displayName)
                sessionCanonicalNames.insert(dbExercise.canonicalName)  // Session-level dedup
                AppLogger.logProgram("Added: \(dbExercise.displayName) (canonical: \(dbExercise.canonicalName))")

                // Track if we added a complexity-4 exercise
                if dbExercise.numericComplexity == 4 {
                    sessionHasComplexity4 = true
                }
            }
        }

        // Sort entire session: higher complexity first, then by canonical rating (implied from order)
        sessionExercises.sort { lhs, rhs in
            // Higher complexity exercises first
            return lhs.complexityLevel > rhs.complexityLevel
        }

        return (sessionExercises, sessionWarnings)
    }

    // MARK: - ProgramExercise Creation

    private func createProgramExercise(
        from dbExercise: DBExercise,
        fitnessGoal: String,
        experienceLevel: ExperienceLevel
    ) throws -> ProgramExercise {

        // Determine rep range based on fitness goal and canonical rating (NEW BUSINESS RULE)
        let repRange = try getRepRangeForGoalAndRating(fitnessGoal, canonicalRating: dbExercise.canonicalRating)

        // Always 3 sets for all exercises (NEW RULE)
        let sets = 3

        // Determine rest period based on canonical rating (NEW RULE)
        let rest = getRestSecondsFromRating(dbExercise.canonicalRating)

        return ProgramExercise(
            exerciseId: dbExercise.exerciseId,
            exerciseName: dbExercise.displayName,
            sets: sets,
            repRange: repRange,
            restSeconds: rest,
            primaryMuscle: dbExercise.primaryMuscle,
            equipmentType: dbExercise.equipmentName ?? "Unknown",
            complexityLevel: dbExercise.numericComplexity
        )
    }

    // MARK: - Rep Range Rules (NEW BUSINESS LOGIC)

    func getRepRangeForGoalAndRating(_ goalSelection: String, canonicalRating: Int) throws -> String {
        let isHighRating = canonicalRating > 75

        // Define goal combinations
        let hasGetStronger = goalSelection.contains("get_stronger")
        let hasIncreaseMuscle = goalSelection.contains("increase_muscle") || goalSelection.contains("build_muscle")
        let hasFatLoss = goalSelection.contains("fat_loss") || goalSelection.contains("tone_up")

        // Goal combination logic
        if hasGetStronger && !hasIncreaseMuscle && !hasFatLoss {
            // Get Stronger only
            return isHighRating ? try randomChoice(["5-8", "6-10"]) : try randomChoice(["6-10", "8-12"])
        } else if hasGetStronger && hasFatLoss && !hasIncreaseMuscle {
            // Get Stronger + Fat Loss (no Increase Muscle)
            return isHighRating ? try randomChoice(["5-8", "6-10"]) : try randomChoice(["6-10", "8-12"])
        } else if hasGetStronger {
            // Get Stronger (alone or with others except Fat Loss only combo)
            return isHighRating ? try randomChoice(["5-8", "6-10"]) : try randomChoice(["6-10", "8-12"])
        } else if hasIncreaseMuscle && hasFatLoss {
            // Increase Muscle + Fat Loss
            return try randomChoice(["8-12", "10-14"])
        } else if hasFatLoss && !hasIncreaseMuscle && !hasGetStronger {
            // Fat Loss only
            return try randomChoice(["8-12", "10-14"])
        } else if hasIncreaseMuscle && !hasFatLoss {
            // Increase Muscle only
            return try randomChoice(["6-10", "8-12"])
        } else {
            // Default case
            return "8-12"
        }
    }

    private func randomChoice<T>(_ options: [T]) throws -> T {
        guard let choice = options.randomElement() else {
            throw ProgramGenerationError.emptySelectionPool
        }
        return choice
    }

    func getRestSecondsFromRating(_ canonicalRating: Int) -> Int {
        if canonicalRating > 80 {
            return 120 // 2 minutes for highest rated exercises
        } else if canonicalRating >= 50 {
            return 90 // 90 seconds for medium rated exercises
        } else {
            return 60 // 1 minute for lower rated exercises
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

        AppLogger.logProgram("Creating emergency exercises for session: \(sessionName)", level: .warning)

        // For emergency exercises, use simple defaults since we don't have canonical_rating
        let repRange = "8-12" // Default rep range for bodyweight exercises
        let sets = 3 // Always 3 sets

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

        AppLogger.logProgram("Emergency exercises created: \(emergencyExercises.map { $0.exerciseName }.joined(separator: ", "))")
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
            complexityLevel: 1
        )
    }
}
