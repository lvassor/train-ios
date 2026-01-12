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
            // Video background
            VideoBackgroundView(name: videoName)
                .ignoresSafeArea()

            // Gradient overlay
            LinearGradient(
                colors: [.clear, .black.opacity(0.85)],
                startPoint: .center,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Content overlay
            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: Spacing.lg) {
                    // Subtitle in gray
                    Text(subtitle)
                        .font(.trainBody)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)

                    // Main headline in white bold
                    Text(headline)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)

                    // NEXT button with accent color
                    Button(action: onNext) {
                        Text("NEXT")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color.trainPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.top, Spacing.xl)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 60)
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