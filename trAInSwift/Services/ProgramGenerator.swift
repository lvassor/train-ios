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

    func generateProgram(from questionnaireData: QuestionnaireData) -> Program {
        AppLogger.logProgram("Generating personalised program: \(questionnaireData.trainingDaysPerWeek) days/week, \(questionnaireData.sessionDuration)")

        do {
            // Use dynamic database-driven program generation
            let program = try dynamicGenerator.generateProgram(from: questionnaireData)

            AppLogger.logProgram("Program generated: \(program.type.description), \(program.sessions.count) sessions, \(program.sessions.reduce(0) { $0 + $1.exercises.count }) exercises")

            return program

        } catch {
            AppLogger.logProgram("Error generating dynamic program: \(error.localizedDescription), falling back to hardcoded", level: .warning)

            // Fallback to hardcoded programs if database fails
            let fallbackProgram = HardcodedPrograms.getProgram(
                days: questionnaireData.trainingDaysPerWeek,
                duration: questionnaireData.sessionDuration
            )

            AppLogger.logProgram("Fallback program loaded: \(fallbackProgram.type.description)")
            return fallbackProgram
        }
    }

}
