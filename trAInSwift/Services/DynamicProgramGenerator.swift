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
            complexityRules: complexityRules,
            daysPerWeek: questionnaireData.trainingDaysPerWeek
        )

        // CRITICAL VALIDATION: Check for empty sessions
        print("🔍 Validating generated sessions...")
        for (index, session) in sessions.enumerated() {
            print("   Session \(index): \(session.dayName) - \(session.exercises.count) exercises")
            if session.exercises.isEmpty {
                print("   ❌ CRITICAL: Session '\(session.dayName)' has 0 exercises!")
                print("      This will cause the workout logger to fail!")
                print("      Equipment: \(availableEquipment)")
                print("      Injuries: \(questionnaireData.injuries)")
                print("      Experience: \(experienceLevel)")
            }
        }

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
        complexityRules: DBUserExperienceComplexity,
        daysPerWeek: Int
    ) throws -> [ProgramSession] {

        let templates = getSessionTemplates(splitType: splitType, duration: sessionDuration, daysPerWeek: daysPerWeek)
        var generatedSessions: [ProgramSession] = []
        var usedExerciseIds = Set<String>()

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
        usedExerciseIds: inout Set<String>
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
            print("🔍 Selecting exercises for: \(muscleGroup.muscle) (need \(targetCount))")
            print("   Equipment: \(availableEquipment)")
            print("   Injuries: \(userInjuries)")
            print("   Already used: \(usedExerciseIds.count) exercises")

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

            print("   ✅ Found \(dbExercises.count) exercises for \(muscleGroup.muscle)")
            if dbExercises.isEmpty {
                print("   ❌ WARNING: NO EXERCISES FOUND for \(muscleGroup.muscle)!")
                print("      This will create an empty session!")
            }

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
                if dbExercise.numericComplexity == 4 {
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
            equipmentType: dbExercise.equipmentName ?? "Unknown"
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
        // Need to handle 5-day specially since it's a hybrid
        if daysPerWeek == 5 {
            return get5DayTemplates(duration: duration)
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
