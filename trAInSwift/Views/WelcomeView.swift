//
//  WelcomeView.swift
//  trAInSwift
//
//  Enhanced welcome screen with screenshot carousel
//

import SwiftUI

struct WelcomeView: View {
    let onContinue: () -> Void
    let onLogin: () -> Void

    @State private var currentIndex = 0

    private let screenshots = ["screenshot_1", "screenshot_2", "screenshot_3", "screenshot_4"]

    var body: some View {
        VStack(spacing: 0) {
            // Header with logo and sign in
            HStack {
                // App logo
                Image("TrainLogoWithText")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 40)

                Spacer()

                // Sign In button
                Button(action: onLogin) {
                    Text("Sign In")
                        .font(.trainBody)
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)

            // Headlines with attributed text
            VStack(spacing: 8) {
                HStack {
                    Text("Programs Built by ")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    +
                    Text("Coaches")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.trainPrimary)

                    Spacer()
                }

                HStack {
                    Text("Tracked by You.")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)

                    Spacer()
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 32)

            // Subtitle
            Text("Designed by two PTs with hundreds of hours of real gym floor experience. Not some algorithm—real coaching, backed by science.")
                .font(.trainBody)
                .foregroundColor(.gray)
                .multilineTextAlignment(.leading)
                .padding(.horizontal, 24)
                .padding(.top, 16)

            // Screenshot carousel
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(screenshots.enumerated()), id: \.offset) { index, screenshot in
                            Image(screenshot)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: getImageWidth(for: index))
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
                                .scaleEffect(index == currentIndex ? 1.0 : 0.95)
                                .animation(.easeInOut(duration: 0.3), value: currentIndex)
                                .id(index)
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.5)) {
                                        currentIndex = index
                                    }
                                }
                        }
                    }
                    .scrollTargetLayout()
                    .padding(.horizontal, 24)
                }
                .scrollTargetBehavior(.viewAligned)
                .onChange(of: currentIndex) { _, newValue in
                    withAnimation(.easeInOut(duration: 0.5)) {
                        proxy.scrollTo(newValue, anchor: .center)
                    }
                }
            }
            .padding(.top, 32)
            .frame(height: 400)

            Spacer()

            // Bottom section
            VStack(spacing: 12) {
                // Get Started button
                Button(action: onContinue) {
                    Text("Get Started")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 24)

                // Caption
                Text("Train smarter with programs built by real trainers.")
                    .font(.trainCaption)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            .padding(.bottom, 40)
        }
        .onAppear {
            // Auto-advance carousel
            startCarouselTimer()
        }
        .charcoalGradientBackground()
    }

    private func getImageWidth(for index: Int) -> CGFloat {
        if index == currentIndex {
            return UIScreen.main.bounds.width * 0.6 // Hero image
        } else {
            return UIScreen.main.bounds.width * 0.35 // Partially visible
        }
    }

    private func startCarouselTimer() {
        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                currentIndex = (currentIndex + 1) % screenshots.count
            }
        }
    }
}