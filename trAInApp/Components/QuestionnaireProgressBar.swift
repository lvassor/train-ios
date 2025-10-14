//
//  QuestionnaireProgressBar.swift
//  trAInApp
//
//  Progress bar for questionnaire screens
//

import SwiftUI

struct QuestionnaireProgressBar: View {
    let currentStep: Int
    let totalSteps: Int

    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...totalSteps, id: \.self) { step in
                Rectangle()
                    .fill(step <= currentStep ? Color.trainPrimary : Color.trainBorder)
                    .frame(height: 4)
                    .cornerRadius(2)
            }
        }
        .frame(height: 4)
        .animation(.easeInOut(duration: 0.3), value: currentStep)
    }
}
