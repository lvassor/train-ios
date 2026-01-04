//
//  train-icon.swift
//  trAInSwift
//
//  Simple Train icon for widget display
//

import SwiftUI

struct TrainIconView: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(LinearGradient(
                    gradient: Gradient(colors: [Color.trainPrimary, Color.trainSecondary]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: size, height: size)

            // T letter
            Text("T")
                .font(.system(size: size * 0.6, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
    }
}

// For backward compatibility with Image("train-icon")
extension Image {
    static var trainIcon: some View {
        TrainIconView(size: 24)
    }
}