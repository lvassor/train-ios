//
//  AppViewModel.swift
//  trAInApp
//
//  Main view model coordinating authentication, program generation, and workout tracking
//

import Foundation
import SwiftUI
import Combine

class AppViewModel: ObservableObject {
    @Published var authService = AuthService.shared
    @Published var questionnaireData = QuestionnaireData()
    @Published var isGeneratingProgram = false

    private let programGenerator = ProgramGenerator()

    init() {
        // Load exercise database on init
        _ = ExerciseDatabaseService.shared
    }

    // MARK: - Questionnaire Completion

    func completeQuestionnaire() {
        guard let user = authService.currentUser else { return }

        isGeneratingProgram = true

        // Save questionnaire data to user
        authService.updateQuestionnaireData(questionnaireData)

        // Generate program based on questionnaire
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            let program = self.programGenerator.generateProgram(from: self.questionnaireData)
            let userProgram = UserProgram(program: program)

            DispatchQueue.main.async {
                self.authService.updateProgram(userProgram)
                self.isGeneratingProgram = false
            }
        }
    }

    // MARK: - Program Management

    func retakeQuestionnaire() {
        questionnaireData = QuestionnaireData()
    }

    // MARK: - User State

    var hasActiveProgram: Bool {
        authService.currentUser?.currentProgram != nil
    }

    var needsQuestionnaire: Bool {
        authService.currentUser?.questionnaireData == nil
    }
}
