//
//  ProgramGenerator.swift
//  TrainSwift
//
//  Core program generation engine using database-driven logic
//  Provides fallback to hardcoded programs if database fails
//

import Foundation

class ProgramGenerator {
    private let dynamicGenerator = DynamicProgramGenerator()

    init() {
        AppLogger.logProgram("ProgramGenerator initialized - using database version")
    }

    // MARK: - Main Generation Function

    /// Generate program and return any warnings for UI display
    func generateProgramWithWarnings(from questionnaireData: QuestionnaireData) -> ProgramGenerationResult {
        AppLogger.logProgram("Generating personalised program: \(questionnaireData.trainingDaysPerWeek) days/week, \(questionnaireData.sessionDuration)")

        do {
            // Use dynamic database-driven program generation with warnings
            // NOTE: The DynamicProgramGenerator now handles individual exercise failures internally
            // and creates emergency fallback exercises when needed, so it should rarely fail completely
            let result = try dynamicGenerator.generateProgramWithWarnings(from: questionnaireData)

            AppLogger.logProgram("Program generated: \(result.program.type.description), \(result.program.sessions.count) sessions, \(result.program.sessions.reduce(0) { $0 + $1.exercises.count }) exercises")

            if result.hasWarnings {
                AppLogger.logProgram("Generation warnings: \(result.uniqueWarnings.count)", level: .warning)
            }

            // Validate that we have at least one exercise across all sessions
            let totalExercises = result.program.sessions.reduce(0) { $0 + $1.exercises.count }
            if totalExercises == 0 {
                AppLogger.logProgram("Critical: Generated program has no exercises, using hardcoded fallback", level: .error)

                // Last resort fallback to hardcoded programs
                let fallbackProgram = HardcodedPrograms.getProgram(
                    days: questionnaireData.trainingDaysPerWeek,
                    duration: questionnaireData.sessionDuration
                )

                AppLogger.logProgram("Hardcoded fallback program loaded: \(fallbackProgram.type.description)")
                return ProgramGenerationResult(program: fallbackProgram, warnings: result.warnings, lowFillWarning: false, repeatWarning: false)
            }

            return result

        } catch {
            AppLogger.logProgram("Error generating dynamic program: \(error.localizedDescription), falling back to hardcoded", level: .warning)

            // Fallback to hardcoded programs if database completely fails
            let fallbackProgram = HardcodedPrograms.getProgram(
                days: questionnaireData.trainingDaysPerWeek,
                duration: questionnaireData.sessionDuration
            )

            AppLogger.logProgram("Fallback program loaded: \(fallbackProgram.type.description)")
            return ProgramGenerationResult(program: fallbackProgram, warnings: [], lowFillWarning: false, repeatWarning: false)
        }
    }

    /// Legacy method for backward compatibility
    func generateProgram(from questionnaireData: QuestionnaireData) -> Program {
        return generateProgramWithWarnings(from: questionnaireData).program
    }

}
