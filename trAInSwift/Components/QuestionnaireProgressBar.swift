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

    private var progress: CGFloat {
        guard totalSteps > 0 else { return 0 }
        return CGFloat(currentStep) / CGFloat(totalSteps)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                Capsule()
                    .fill(Color(hex: "#E0E0E0"))
                    .frame(height: ElementHeight.progressBar)

                // Progress fill - continuous bar matching button color
                Capsule()
                    .fill(Color.trainPrimary)
                    .frame(width: geometry.size.width * progress, height: ElementHeight.progressBar)
            }
        }
        .frame(height: ElementHeight.progressBar)
        .animation(.easeInOut(duration: 0.3), value: currentStep)
    }
}
