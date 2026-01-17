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

            Spacer().frame(height: 60)

            // Headlines with attributed text - closer to Gravl styling
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Programs Built by ")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    +
                    Text("Coaches.")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.trainPrimary)

                    Spacer()
                }

                HStack {
                    Text("Tracked by You.")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)

                    Spacer()
                }
            }
            .padding(.horizontal, 24)

            // Subtitle
            Text("Train uses AI-powered programs created by personal trainers to build personalized workouts based on your goals, experience, and available equipment.")
                .font(.system(size: 16))
                .foregroundColor(.gray)
                .multilineTextAlignment(.leading)
                .padding(.horizontal, 24)
                .padding(.top, 16)

            // Screenshot carousel - swipeable through all 4 screenshots - enhanced for visibility
            Group {
                if #available(iOS 17.0, *) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 20) {
                            ForEach(Array(screenshots.enumerated()), id: \.offset) { index, screenshot in
                                Image(screenshot)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: UIScreen.main.bounds.width * 0.43)  // Shows ~2.3 images at once
                                    .frame(height: 400) // Fixed height for consistency
                                    .clipShape(RoundedRectangle(cornerRadius: 20))
                                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                            }
                        }
                        .padding(.horizontal, 20)
                        .scrollTargetLayout()
                    }
                    .scrollTargetBehavior(.viewAligned)
                    .scrollIndicators(.hidden)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 20) {
                            ForEach(Array(screenshots.enumerated()), id: \.offset) { index, screenshot in
                                Image(screenshot)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: UIScreen.main.bounds.width * 0.43)  // Shows ~2.3 images at once
                                    .frame(height: 400) // Fixed height for consistency
                                    .clipShape(RoundedRectangle(cornerRadius: 20))
                                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .scrollIndicators(.hidden)
                }
            }
            .frame(height: 440)
            .padding(.top, 32)
            .onAppear {
                print("🎠 [WELCOME] Swipeable screenshot carousel loaded with \(screenshots.count) images")
                print("🎠 [WELCOME] Users can swipe left/right through: \(screenshots.joined(separator: ", "))")
                print("🎠 [WELCOME] WelcomeView appeared - carousel should be visible")
            }

            Spacer()

            // Bottom section
            VStack(spacing: 16) {
                // Get Started button
                Button(action: onContinue) {
                    Text("Get Started")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 28))
                }
                .padding(.horizontal, 24)
                .onTapGesture {
                    print("🚀 [WELCOME] Get Started button tapped - navigating to questionnaire")
                }

                // Caption
                Text("Join Train to get personalized workouts and hit your goals faster.")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            .padding(.bottom, 50)
        }
        .onAppear {
            print("🎯 [WELCOME] WelcomeView appeared - ready for user interaction")
        }
        .charcoalGradientBackground()
    }
}