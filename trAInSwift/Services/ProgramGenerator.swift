//
//  ProgramGenerator.swift
//  trAInApp
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
            let result = try dynamicGenerator.generateProgramWithWarnings(from: questionnaireData)

            AppLogger.logProgram("Program generated: \(result.program.type.description), \(result.program.sessions.count) sessions, \(result.program.sessions.reduce(0) { $0 + $1.exercises.count }) exercises")

            if result.hasWarnings {
                AppLogger.logProgram("Generation warnings: \(result.uniqueWarnings.count)", level: .warning)
            }

            return result

        } catch {
            AppLogger.logProgram("Error generating dynamic program: \(error.localizedDescription), falling back to hardcoded", level: .warning)

            // Fallback to hardcoded programs if database fails
            let fallbackProgram = HardcodedPrograms.getProgram(
                days: questionnaireData.trainingDaysPerWeek,
                duration: questionnaireData.sessionDuration
            )

            AppLogger.logProgram("Fallback program loaded: \(fallbackProgram.type.description)")
            return ProgramGenerationResult(program: fallbackProgram, warnings: [])
        }
    }

    /// Legacy method for backward compatibility
    func generateProgram(from questionnaireData: QuestionnaireData) -> Program {
        return generateProgramWithWarnings(from: questionnaireData).program
    }

}
