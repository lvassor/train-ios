//
//  DynamicProgramGenerator.swift
//  trAInSwift
//
//  Dynamic program generation using SQLite database and questionnaire answers
//

import Foundation

class DynamicProgramGenerator {
    private let exerciseRepo = ExerciseRepository()

    init() {
        print("🔧 DynamicProgramGenerator init() called")
        print("🔧 ExerciseRepository created")
    }

    // MARK: - Main Generation Function

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

        // Get complexity rules for this user
        let complexityRules = try exerciseRepo.getComplexityRules(for: experienceLevel)
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
            complexityRules: complexityRules
        )

        let program = Program(
            type: splitType,
            daysPerWeek: questionnaireData.trainingDaysPerWeek,
            sessionDuration: sessionDuration,
            sessions: sessions,
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
        case 2:
            return duration == "30-45 min" ? .upperLower : .fullBody
        case 3:
            return .pushPullLegs
        case 4:
            return .upperLower
        case 5, 6:
            return .pushPullLegs
        default:
            return .fullBody
        }
    }

    // MARK: - Session Generation

    private func generateSessions(
        splitType: ProgramType,
        sessionDuration: SessionDuration,
        experienceLevel: ExperienceLevel,
        availableEquipment: [String],
        userInjuries: [String],
        targetMuscles: [String],
        fitnessGoal: String,
        complexityRules: DBUserExperienceComplexity
    ) throws -> [ProgramSession] {

        let templates = getSessionTemplates(splitType: splitType, duration: sessionDuration)
        var generatedSessions: [ProgramSession] = []
        var usedExerciseIds = Set<Int>()

        for template in templates {
            let exercises = try generateExercisesForSession(
                template: template,
                experienceLevel: experienceLevel,
                availableEquipment: availableEquipment,
                userInjuries: userInjuries,
                targetMuscles: targetMuscles,
                fitnessGoal: fitnessGoal,
                complexityRules: complexityRules,
                usedExerciseIds: &usedExerciseIds
            )

            let session = ProgramSession(
                dayName: template.dayName,
                exercises: exercises
            )
            generatedSessions.append(session)
        }

        return generatedSessions
    }

    // MARK: - Exercise Selection for Session

    private func generateExercisesForSession(
        template: SessionTemplate,
        experienceLevel: ExperienceLevel,
        availableEquipment: [String],
        userInjuries: [String],
        targetMuscles: [String],
        fitnessGoal: String,
        complexityRules: DBUserExperienceComplexity,
        usedExerciseIds: inout Set<Int>
    ) throws -> [ProgramExercise] {

        var sessionExercises: [ProgramExercise] = []
        var sessionHasComplexity4 = false

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

            // Select exercises from database
            let dbExercises = try exerciseRepo.selectExercises(
                count: targetCount,
                movementPattern: muscleGroup.movementPattern,
                primaryMuscle: muscleGroup.muscle,
                experienceLevel: experienceLevel,
                availableEquipment: availableEquipment,
                userInjuries: userInjuries,
                excludedExerciseIds: usedExerciseIds,
                allowComplexity4: allowComplexity4,
                requireComplexity4First: requireComplexity4First
            )

            // Convert to ProgramExercise with sets/reps based on goal
            for dbExercise in dbExercises {
                let programExercise = createProgramExercise(
                    from: dbExercise,
                    fitnessGoal: fitnessGoal,
                    experienceLevel: experienceLevel
                )
                sessionExercises.append(programExercise)
                usedExerciseIds.insert(dbExercise.exerciseId)

                // Track if we added a complexity-4 exercise
                if dbExercise.complexityLevel == 4 {
                    sessionHasComplexity4 = true
                }
            }
        }

        return sessionExercises
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
            complexityLevel: dbExercise.complexityLevel,
            repRange: repRange
        )

        return ProgramExercise(
            exerciseId: String(dbExercise.exerciseId),
            exerciseName: dbExercise.displayName,
            sets: sets,
            repRange: repRange,
            restSeconds: rest,
            primaryMuscle: dbExercise.primaryMuscle,
            equipmentType: dbExercise.equipmentType
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
        duration: SessionDuration
    ) -> [SessionTemplate] {
        switch splitType {
        case .fullBody:
            return getFullBodyTemplates(duration: duration)
        case .upperLower:
            return getUpperLowerTemplates(duration: duration)
        case .pushPullLegs:
            return getPushPullLegsTemplates(duration: duration)
        }
    }

    private func getFullBodyTemplates(duration: SessionDuration) -> [SessionTemplate] {
        let isShort = duration == .short

        return [
            SessionTemplate(dayName: "Full Body A", muscleGroups: [
                (muscle: "Quads", count: isShort ? 1 : 2, movementPattern: "Squat"),
                (muscle: "Chest", count: isShort ? 1 : 2, movementPattern: "Horizontal Push"),
                (muscle: "Back", count: isShort ? 1 : 2, movementPattern: "Horizontal Pull"),
                (muscle: "Shoulders", count: 1, movementPattern: "Vertical Push"),
                (muscle: "Hamstrings", count: 1, movementPattern: "Hinge")
            ]),
            SessionTemplate(dayName: "Full Body B", muscleGroups: [
                (muscle: "Hamstrings", count: 1, movementPattern: "Hinge"),
                (muscle: "Chest", count: isShort ? 1 : 2, movementPattern: "Horizontal Push"),
                (muscle: "Back", count: isShort ? 1 : 2, movementPattern: "Vertical Pull"),
                (muscle: "Quads", count: 1, movementPattern: "Squat"),
                (muscle: "Shoulders", count: 1, movementPattern: "Isolation")
            ])
        ]
    }

    private func getUpperLowerTemplates(duration: SessionDuration) -> [SessionTemplate] {
        let isShort = duration == .short

        return [
            SessionTemplate(dayName: "Upper", muscleGroups: [
                (muscle: "Chest", count: 2, movementPattern: "Horizontal Push"),
                (muscle: "Back", count: 2, movementPattern: "Horizontal Pull"),
                (muscle: "Shoulders", count: isShort ? 1 : 2, movementPattern: "Vertical Push"),
                (muscle: "Biceps", count: isShort ? 1 : 2, movementPattern: "Isolation"),
                (muscle: "Triceps", count: isShort ? 1 : 2, movementPattern: "Isolation")
            ]),
            SessionTemplate(dayName: "Lower", muscleGroups: [
                (muscle: "Quads", count: 2, movementPattern: "Squat"),
                (muscle: "Hamstrings", count: 2, movementPattern: "Hinge"),
                (muscle: "Glutes", count: isShort ? 1 : 2, movementPattern: "Hip Extension"),
                (muscle: "Calves", count: 1, movementPattern: "Isolation")
            ])
        ]
    }

    private func getPushPullLegsTemplates(duration: SessionDuration) -> [SessionTemplate] {
        let isShort = duration == .short

        return [
            SessionTemplate(dayName: "Push", muscleGroups: [
                (muscle: "Chest", count: isShort ? 2 : 3, movementPattern: "Horizontal Push"),
                (muscle: "Shoulders", count: 2, movementPattern: "Vertical Push"),
                (muscle: "Triceps", count: isShort ? 1 : 2, movementPattern: "Isolation")
            ]),
            SessionTemplate(dayName: "Pull", muscleGroups: [
                (muscle: "Back", count: isShort ? 2 : 3, movementPattern: "Horizontal Pull"),
                (muscle: "Back", count: 1, movementPattern: "Vertical Pull"),
                (muscle: "Biceps", count: 2, movementPattern: "Isolation")
            ]),
            SessionTemplate(dayName: "Legs", muscleGroups: [
                (muscle: "Quads", count: 2, movementPattern: "Squat"),
                (muscle: "Hamstrings", count: 2, movementPattern: "Hinge"),
                (muscle: "Glutes", count: 1, movementPattern: "Hip Extension"),
                (muscle: "Calves", count: 1, movementPattern: "Isolation")
            ])
        ]
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
}
