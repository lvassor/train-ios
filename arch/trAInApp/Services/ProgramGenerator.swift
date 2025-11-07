//
//  ProgramGenerator.swift
//  trAInApp
//
//  Core program generation engine using rule-based logic
//

import Foundation

class ProgramGenerator {
    private let exerciseDB = ExerciseDatabaseService.shared

    // MARK: - Main Generation Function

    func generateProgram(from questionnaireData: QuestionnaireData) -> Program {
        print("Generating program from questionnaire data...")

        // 1. Determine split type
        let splitType = determineSplitType(
            days: questionnaireData.trainingDaysPerWeek,
            duration: questionnaireData.sessionDuration
        )

        // 2. Get session templates
        let templates = getSessionTemplates(
            splitType: splitType,
            duration: questionnaireData.sessionDuration
        )

        // 3. Map questionnaire equipment to database equipment types
        let equipmentTypes = mapEquipment(questionnaireData.equipmentAvailable)

        // 4. Determine experience level
        let experienceLevel = mapExperienceLevel(questionnaireData.experienceLevel)

        // 5. Get target muscles from questionnaire
        let targetMuscles = questionnaireData.targetMuscleGroups

        // 6. Generate sessions
        var programSessions: [ProgramSession] = []

        for template in templates {
            let exercises = generateExercisesForSession(
                template: template,
                equipmentTypes: equipmentTypes,
                experienceLevel: experienceLevel,
                targetMuscles: targetMuscles,
                splitType: splitType,
                injuries: questionnaireData.injuries
            )

            let session = ProgramSession(
                dayName: template.dayName,
                exercises: exercises
            )
            programSessions.append(session)
        }

        // 7. Map duration string to enum
        let sessionDuration = mapSessionDuration(questionnaireData.sessionDuration)

        // 8. Create program
        let program = Program(
            type: splitType,
            daysPerWeek: questionnaireData.trainingDaysPerWeek,
            sessionDuration: sessionDuration,
            sessions: programSessions,
            totalWeeks: 8
        )

        print("Program generated: \(splitType.description), \(questionnaireData.trainingDaysPerWeek) days/week")
        return program
    }

    // MARK: - Split Type Determination

    private func determineSplitType(days: Int, duration: String) -> ProgramType {
        switch days {
        case 2:
            return duration == "30-45 min" ? .fullBody : .upperLower
        case 3:
            return .pushPullLegs
        case 4:
            return .upperLower
        case 5:
            return .pushPullLegs
        default:
            return .pushPullLegs
        }
    }

    // MARK: - Session Templates

    private struct SessionTemplate {
        let dayName: String
        let muscleGroups: [(muscle: String, count: Int)]
    }

    private func getSessionTemplates(splitType: ProgramType, duration: String) -> [SessionTemplate] {
        switch splitType {
        case .fullBody:
            return getFullBodyTemplates(duration: duration)
        case .upperLower:
            return getUpperLowerTemplates(duration: duration)
        case .pushPullLegs:
            return getPushPullLegsTemplates(duration: duration)
        }
    }

    private func getFullBodyTemplates(duration: String) -> [SessionTemplate] {
        let exerciseCounts = duration == "30-45 min" ?
            [(muscle: "Chest", count: 1), (muscle: "Back", count: 1), (muscle: "Shoulders", count: 1),
             (muscle: "Quads", count: 1), (muscle: "Hamstrings", count: 1)] :
            [(muscle: "Chest", count: 2), (muscle: "Back", count: 2), (muscle: "Shoulders", count: 1),
             (muscle: "Quads", count: 1), (muscle: "Hamstrings", count: 1), (muscle: "Biceps", count: 1), (muscle: "Triceps", count: 1)]

        return [
            SessionTemplate(dayName: "Full Body A", muscleGroups: exerciseCounts),
            SessionTemplate(dayName: "Full Body B", muscleGroups: exerciseCounts)
        ]
    }

    private func getUpperLowerTemplates(duration: String) -> [SessionTemplate] {
        if duration == "30-45 min" {
            return [
                SessionTemplate(dayName: "Upper", muscleGroups: [
                    (muscle: "Chest", count: 2), (muscle: "Back", count: 2), (muscle: "Shoulders", count: 1)
                ]),
                SessionTemplate(dayName: "Lower", muscleGroups: [
                    (muscle: "Quads", count: 2), (muscle: "Hamstrings", count: 2), (muscle: "Glutes", count: 1)
                ])
            ]
        } else {
            return [
                SessionTemplate(dayName: "Upper", muscleGroups: [
                    (muscle: "Chest", count: 2), (muscle: "Back", count: 2), (muscle: "Shoulders", count: 2),
                    (muscle: "Biceps", count: 1), (muscle: "Triceps", count: 1)
                ]),
                SessionTemplate(dayName: "Lower", muscleGroups: [
                    (muscle: "Quads", count: 2), (muscle: "Hamstrings", count: 2), (muscle: "Glutes", count: 2),
                    (muscle: "Calves", count: 1)
                ])
            ]
        }
    }

    private func getPushPullLegsTemplates(duration: String) -> [SessionTemplate] {
        if duration == "30-45 min" {
            return [
                SessionTemplate(dayName: "Push", muscleGroups: [
                    (muscle: "Chest", count: 2), (muscle: "Shoulders", count: 2), (muscle: "Triceps", count: 1)
                ]),
                SessionTemplate(dayName: "Pull", muscleGroups: [
                    (muscle: "Back", count: 3), (muscle: "Biceps", count: 2)
                ]),
                SessionTemplate(dayName: "Legs", muscleGroups: [
                    (muscle: "Quads", count: 2), (muscle: "Hamstrings", count: 2), (muscle: "Calves", count: 1)
                ])
            ]
        } else {
            return [
                SessionTemplate(dayName: "Push", muscleGroups: [
                    (muscle: "Chest", count: 3), (muscle: "Shoulders", count: 2), (muscle: "Triceps", count: 2)
                ]),
                SessionTemplate(dayName: "Pull", muscleGroups: [
                    (muscle: "Back", count: 4), (muscle: "Biceps", count: 2)
                ]),
                SessionTemplate(dayName: "Legs", muscleGroups: [
                    (muscle: "Quads", count: 2), (muscle: "Hamstrings", count: 2), (muscle: "Glutes", count: 1),
                    (muscle: "Calves", count: 1)
                ])
            ]
        }
    }

    // MARK: - Exercise Selection

    private func generateExercisesForSession(
        template: SessionTemplate,
        equipmentTypes: [String],
        experienceLevel: ExerciseDBEntry.ExperienceLevel,
        targetMuscles: [String],
        splitType: ProgramType,
        injuries: [String]
    ) -> [ProgramExercise] {
        var selectedExercises: [ProgramExercise] = []
        var usedExerciseIds = Set<String>()

        for muscleGroup in template.muscleGroups {
            var count = muscleGroup.count

            // Apply target muscle priority rule
            if targetMuscles.contains(muscleGroup.muscle) {
                count += getPriorityBonus(splitType: splitType)
            }

            // Create filter
            let filter = ExerciseFilter(
                primaryMuscle: muscleGroup.muscle,
                equipmentTypes: equipmentTypes,
                maxExperienceLevel: experienceLevel,
                excludedInjuries: injuries,
                excludedExerciseIds: usedExerciseIds
            )

            // Select exercises
            let exercises = exerciseDB.selectExercises(count: count, filter: filter)

            for exercise in exercises {
                let programExercise = createProgramExercise(
                    from: exercise,
                    experienceLevel: experienceLevel
                )
                selectedExercises.append(programExercise)
                usedExerciseIds.insert(exercise.id)
            }
        }

        return selectedExercises
    }

    private func getPriorityBonus(splitType: ProgramType) -> Int {
        switch splitType {
        case .fullBody:
            return 2
        case .pushPullLegs:
            return 1
        case .upperLower:
            return 1
        }
    }

    private func createProgramExercise(
        from exercise: ExerciseDBEntry,
        experienceLevel: ExerciseDBEntry.ExperienceLevel
    ) -> ProgramExercise {
        // Determine sets and reps based on experience
        let (sets, repRange, rest) = getSetsRepsRest(
            experienceLevel: experienceLevel,
            exerciseType: exercise.movementPattern
        )

        return ProgramExercise(
            exerciseId: exercise.id,
            exerciseName: exercise.exerciseName,
            sets: sets,
            repRange: repRange,
            restSeconds: rest,
            primaryMuscle: exercise.primaryMuscle,
            equipmentType: exercise.equipmentType
        )
    }

    private func getSetsRepsRest(
        experienceLevel: ExerciseDBEntry.ExperienceLevel,
        exerciseType: String
    ) -> (sets: Int, repRange: String, rest: Int) {
        // Default sets
        let sets = 3

        // Determine rep range based on experience and exercise type
        let repRange: String
        let rest: Int

        // Heavy compound movements get lower reps, more rest
        let compoundMovements = ["Squat", "Hinge", "Push", "Pull"]
        let isCompound = compoundMovements.contains(exerciseType)

        switch experienceLevel {
        case .beginner:
            repRange = isCompound ? "8-12" : "10-15"
            rest = isCompound ? 120 : 60
        case .intermediate:
            repRange = isCompound ? "6-10" : "8-12"
            rest = isCompound ? 150 : 90
        case .advanced:
            repRange = isCompound ? "5-8" : "8-12"
            rest = isCompound ? 180 : 90
        }

        return (sets, repRange, rest)
    }

    // MARK: - Helper Functions

    private func mapEquipment(_ questionnaireEquipment: [String]) -> [String] {
        var dbEquipment: [String] = []

        for item in questionnaireEquipment {
            switch item {
            case "bodyweight":
                dbEquipment.append("Bodyweight")
            case "dumbbells":
                dbEquipment.append("Dumbbell")
            case "barbells":
                dbEquipment.append("Barbell")
            case "cable_machines":
                dbEquipment.append("Cable")
            case "pin_loaded", "plate_loaded":
                dbEquipment.append("Machine")
            case "kettlebells":
                dbEquipment.append("Kettlebell")
            default:
                break
            }
        }

        // If no equipment selected, default to all
        if dbEquipment.isEmpty {
            dbEquipment = ["Barbell", "Dumbbell", "Cable", "Machine", "Kettlebell", "Bodyweight"]
        }

        return dbEquipment
    }

    private func mapExperienceLevel(_ questionnaireLevel: String) -> ExerciseDBEntry.ExperienceLevel {
        switch questionnaireLevel {
        case "0_months", "0_6_months":
            return .beginner
        case "6_months_2_years":
            return .intermediate
        case "2_plus_years":
            return .advanced
        default:
            return .beginner
        }
    }

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
