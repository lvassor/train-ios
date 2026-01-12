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

    var body: some View {
        InterstitialScreen(
            videoName: "onboarding_first",
            subtitle: "You're in the right place",
            headline: "Real trainers and science-backed programs to hit your goals.",
            onNext: onComplete
        )
    }
}

struct SecondVideoInterstitialView: View {
    let onComplete: () -> Void

    var body: some View {
        InterstitialScreen(
            videoName: "onboarding_second",
            subtitle: "We're built for you!",
            headline: "Train creates your perfect workout for your individual needs.",
            onNext: onComplete
        )
    }
}

// MARK: - Shared Interstitial Component

private struct InterstitialScreen: View {
    let videoName: String
    let subtitle: String
    let headline: String
    let onNext: () -> Void

    var body: some View {
        ZStack {
            // Fallback gradient background in case video fails
            LinearGradient(
                colors: [.trainPrimary.opacity(0.8), .black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea(.all, edges: .all)

            // Video background - fills entire viewport (will overlay gradient if successful)
            VideoBackgroundView(name: videoName)
                .ignoresSafeArea(.all, edges: .all)

            // Gradient overlay for better text readability
            LinearGradient(
                colors: [.clear, .black.opacity(0.75)],
                startPoint: .center,
                endPoint: .bottom
            )
            .ignoresSafeArea(.all, edges: .all)

            // Content overlay - positioned at bottom center
            VStack(spacing: 0) {
                Spacer(minLength: 0)

                VStack(spacing: Spacing.lg) {
                    // Subtitle in light gray
                    Text(subtitle)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)

                    // Main headline - larger, bold, better spacing
                    Text(headline)
                        .font(.system(size: 32, weight: .bold, design: .default))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.bottom, 140) // Extra space for Continue button from main questionnaire
            }
        }
        // Fill entire screen
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview("First Interstitial") {
    FirstVideoInterstitialView(onComplete: {})
}

#Preview("Second Interstitial") {
    SecondVideoInterstitialView(onComplete: {})
}