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
        HStack(spacing: Spacing.xs) {  // 4px gap from Figma
            ForEach(1...totalSteps, id: \.self) { step in
                Capsule()  // Rounded pill shape for progress segments
                    .fill(step <= currentStep ? Color(hex: "#666666") : Color(hex: "#E0E0E0"))  // Colors from Figma
                    .frame(height: ElementHeight.progressBar)  // 4px from Figma
            }
        }
        .frame(height: ElementHeight.progressBar)
        .animation(.easeInOut(duration: 0.3), value: currentStep)
    }
}
