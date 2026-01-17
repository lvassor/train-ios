//
//  VideoInterstitialView.swift
//  trAInSwift
//
//  Individual video interstitial screens for strategic placement in onboarding flow
//

import SwiftUI

// MARK: - Individual Interstitial Screens

struct FirstVideoInterstitialView: View {
    let onComplete: () -> Void
    let onBack: (() -> Void)?
    let currentStep: Int
    let totalSteps: Int

    init(onComplete: @escaping () -> Void, onBack: (() -> Void)? = nil, currentStep: Int = 0, totalSteps: Int = 1) {
        self.onComplete = onComplete
        self.onBack = onBack
        self.currentStep = currentStep
        self.totalSteps = totalSteps
    }

    var body: some View {
        InterstitialScreen(
            videoName: "onboarding_first",
            subtitle: "You're in the right place",
            headline: "Real trainers and science-backed programs to hit your goals.",
            onNext: onComplete,
            onBack: onBack,
            currentStep: currentStep,
            totalSteps: totalSteps
        )
    }
}

struct SecondVideoInterstitialView: View {
    let onComplete: () -> Void
    let onBack: (() -> Void)?
    let currentStep: Int
    let totalSteps: Int

    init(onComplete: @escaping () -> Void, onBack: (() -> Void)? = nil, currentStep: Int = 0, totalSteps: Int = 1) {
        self.onComplete = onComplete
        self.onBack = onBack
        self.currentStep = currentStep
        self.totalSteps = totalSteps
    }

    var body: some View {
        InterstitialScreen(
            videoName: "onboarding_second",
            subtitle: "We're built for you!",
            headline: "Train creates your perfect workout for your individual needs.",
            onNext: onComplete,
            onBack: onBack,
            currentStep: currentStep,
            totalSteps: totalSteps
        )
    }
}

// MARK: - Shared Interstitial Component

private struct InterstitialScreen: View {
    let videoName: String
    let subtitle: String
    let headline: String
    let onNext: () -> Void
    let onBack: (() -> Void)?
    let currentStep: Int
    let totalSteps: Int

    var body: some View {
        ZStack {
            // Fallback gradient background to prevent flash during video load
            LinearGradient(
                colors: [Color.black, Color(red: 0.1, green: 0.1, blue: 0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea(.all)

            // Video background - now truly full screen
            GeometryReader { geo in
                VideoBackgroundView(name: videoName)
                    .frame(width: geo.size.width, height: geo.size.height)
            }
            .ignoresSafeArea(.all)

            // Gradient overlay - starts from 33% from bottom
            LinearGradient(
                colors: [.clear, .black.opacity(0.3), .black.opacity(0.8)],
                startPoint: .init(x: 0.5, y: 0.67),  // Start at 67% from top (33% from bottom)
                endPoint: .bottom
            )
            .ignoresSafeArea(.all)

            // All UI overlaid on video
            VStack(spacing: 0) {
                // Back button + progress bar at top
                VStack(spacing: 0) {
                    HStack {
                        Button(action: { onBack?() }) {
                            Image(systemName: "arrow.left")
                                .font(.title3)
                                .foregroundColor(.white)
                        }
                        Spacer()
                    }
                    .padding(16)

                    QuestionnaireProgressBar(currentStep: currentStep, totalSteps: totalSteps)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                }

                Spacer()

                // Text content positioned above Continue button
                VStack(spacing: 16) {
                    Text(subtitle)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)

                    Text(headline)
                        .font(.system(size: 28, weight: .bold, design: .default))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)  // Space between text and button

                // Continue button
                CustomButton(title: "Continue", action: onNext, isEnabled: true)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 40)
            }
        }
    }
}

#Preview("First Interstitial") {
    FirstVideoInterstitialView(onComplete: {})
}

#Preview("Second Interstitial") {
    SecondVideoInterstitialView(onComplete: {})
}