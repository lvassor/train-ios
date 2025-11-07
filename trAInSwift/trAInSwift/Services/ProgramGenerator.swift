//
//  ProgramGenerator.swift
//  trAInApp
//
//  Core program generation engine using database-driven logic
//

import Foundation

class ProgramGenerator {
    private let dynamicGenerator = DynamicProgramGenerator()

    init() {
        print("🔧 ProgramGenerator initialized - using DATABASE version")
        print("🔧 DynamicProgramGenerator created")
    }

    // MARK: - Main Generation Function

    func generateProgram(from questionnaireData: QuestionnaireData) -> Program {
        print("🎯 Generating personalized program from questionnaire data...")
        print("   Days per week: \(questionnaireData.trainingDaysPerWeek)")
        print("   Session duration: \(questionnaireData.sessionDuration)")
        print("   Experience: \(questionnaireData.experienceLevel)")
        print("   Goal: \(questionnaireData.primaryGoal)")

        do {
            // Use dynamic database-driven program generation
            let program = try dynamicGenerator.generateProgram(from: questionnaireData)

            print("✅ Program generated: \(program.type.description)")
            print("✅ Days per week: \(program.daysPerWeek)")
            print("✅ Sessions: \(program.sessions.map { $0.dayName }.joined(separator: ", "))")
            print("✅ Total exercises: \(program.sessions.reduce(0) { $0 + $1.exercises.count })")

            return program

        } catch {
            print("⚠️ Error generating dynamic program: \(error.localizedDescription)")
            print("⚠️ Falling back to hardcoded program...")

            // Fallback to hardcoded programs if database fails
            let fallbackProgram = HardcodedPrograms.getProgram(
                days: questionnaireData.trainingDaysPerWeek,
                duration: questionnaireData.sessionDuration
            )

            print("✅ Fallback program loaded: \(fallbackProgram.type.description)")
            return fallbackProgram
        }
    }

}
