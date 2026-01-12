//
//  VideoInterstitialView.swift
//  trAInSwift
//
//  Video interstitial screens for onboarding flow with swipeable TabView
//

import SwiftUI

struct VideoInterstitialView: View {
    let onComplete: () -> Void

    @State private var currentPage = 0

    private let interstitialData = [
        InterstitialData(
            videoName: "onboarding_first",
            subtitle: "You're in the right place",
            headline: "Real trainers and science-backed programs to hit your goals."
        ),
        InterstitialData(
            videoName: "onboarding_second",
            subtitle: "We're built for you!",
            headline: "Train creates your perfect workout for your individual needs."
        )
    ]

    var body: some View {
        TabView(selection: $currentPage) {
            ForEach(Array(interstitialData.enumerated()), id: \.offset) { index, data in
                InterstitialScreen(
                    videoName: data.videoName,
                    subtitle: data.subtitle,
                    headline: data.headline,
                    isLastScreen: index == interstitialData.count - 1,
                    onNext: {
                        if index < interstitialData.count - 1 {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                currentPage = index + 1
                            }
                        } else {
                            onComplete()
                        }
                    }
                )
                .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never)) // Hide page indicators
        .ignoresSafeArea()
    }
}

private struct InterstitialData {
    let videoName: String
    let subtitle: String
    let headline: String
}

private struct InterstitialScreen: View {
    let videoName: String
    let subtitle: String
    let headline: String
    let isLastScreen: Bool
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

                    // NEXT button
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
        .gesture(
            // Allow swipe to advance
            DragGesture()
                .onEnded { value in
                    if value.translation.x < -50 { // Swipe left
                        onNext()
                    }
                }
        )
    }
}

#Preview {
    VideoInterstitialView(onComplete: {})
}