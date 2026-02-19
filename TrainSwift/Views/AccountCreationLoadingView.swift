//
//  AccountCreationLoadingView.swift
//  TrainSwift
//
//  Loading screen after account creation
//

import SwiftUI

struct AccountCreationLoadingView: View {
    let onComplete: () -> Void

    @State private var animationProgress: Double = 0.0

    var body: some View {
        ZStack {
            Color.trainBackground
                .ignoresSafeArea()

            VStack(spacing: Spacing.xl) {
                Spacer()

                // Circular progress animation
                ZStack {
                    Circle()
                        .stroke(Color.trainBorder, lineWidth: 8)
                        .frame(width: 100, height: 100)

                    Circle()
                        .trim(from: 0, to: animationProgress)
                        .stroke(
                            LinearGradient(
                                colors: [Color.trainPrimary, Color.trainLight],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 2.0), value: animationProgress)
                }

                // Title
                VStack(spacing: Spacing.sm) {
                    Text("Creating Your Account")
                        .font(.trainTitle)
                        .foregroundColor(.trainTextPrimary)

                    Text("This will only take a moment...")
                        .font(.trainSubtitle)
                        .foregroundColor(.trainTextSecondary)
                }

                Spacer()
            }
        }
        .onAppear {
            // Animate progress
            withAnimation {
                animationProgress = 1.0
            }

            // Auto-dismiss after 2.5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                onComplete()
            }
        }
    }
}

#Preview {
    AccountCreationLoadingView(onComplete: {
        AppLogger.logUI("Account creation complete!")
    })
}
