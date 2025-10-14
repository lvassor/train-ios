//
//  ContentView.swift
//  trAInApp
//
//  Main app navigation
//

import SwiftUI

enum AppScreen {
    case welcome
    case questionnaire
    case programme
}

struct ContentView: View {
    @EnvironmentObject var viewModel: WorkoutViewModel
    @State private var currentScreen: AppScreen = .welcome

    var body: some View {
        ZStack {
            switch currentScreen {
            case .welcome:
                WelcomeView(onContinue: {
                    withAnimation {
                        currentScreen = .questionnaire
                    }
                })
                .transition(.opacity)

            case .questionnaire:
                QuestionnaireView(onComplete: {
                    withAnimation {
                        currentScreen = .programme
                    }
                })
                .environmentObject(viewModel)
                .transition(.move(edge: .trailing))

            case .programme:
                ProgrammeOverviewView()
                    .environmentObject(viewModel)
                    .transition(.opacity)
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(WorkoutViewModel())
}
