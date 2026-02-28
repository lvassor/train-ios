//
//  WelcomeView.swift
//  TrainSwift
//
//  Enhanced welcome screen with Cover Flow carousel and updated branding
//

import SwiftUI

struct WelcomeView: View {
    let onContinue: () -> Void
    let onLogin: () -> Void

    private let screenshots = ["screenshot_1", "screenshot_2", "screenshot_3", "screenshot_4"]
    @State private var currentIndex: Int = 0
    @State private var viewDidAppear = false

    /// Unique ID for this instance to track in logs
    private let instanceId = UUID().uuidString.prefix(8)

    var body: some View {
        ZStack(alignment: .bottom) {
            // Content area with ScrollView that scrolls behind the floating button
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Header with centered logo and sign in
                    VStack(spacing: Spacing.md) {
                        HStack {
                            Spacer()

                            // Sign In button
                            Button(action: onLogin) {
                                Text("Sign In")
                                    .font(.trainBody)
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.horizontal, Spacing.lg)
                        .padding(.top, Spacing.smd)

                        // Centered larger logo (cropped SVG) - 75% of original size
                        Image("TrainLogoWithText")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 60)
                    }

                    Spacer().frame(height: 32)

                    // Updated headlines with brand messaging - line break after "Expert Programs."
                    VStack(alignment: .center, spacing: Spacing.xs) {
                        Text("Expert Programs.")
                            .font(.trainTitle).fontWeight(.bold)
                            .foregroundColor(.trainPrimary) // Brand orange highlighting

                        Text("Built Around You.")
                            .font(.trainTitle).fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.lg)

                    // Updated subtitle with proper line breaking
                    Text("Train uses programming and training principles from professional personal trainers to help you master weight lifting and hit your goals.")
                        .font(.trainBody)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, Spacing.lg)
                        .padding(.top, Spacing.md)

                    // Cover Flow carousel with center stage scaling - reduced to 75% size
                    Group {
                        if #available(iOS 17.0, *) {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: Spacing.xs) {
                                    ForEach(Array(screenshots.enumerated()), id: \.offset) { index, screenshot in
                                        GeometryReader { geometry in
                                            let midX = geometry.frame(in: .global).midX
                                            let screenWidth = UIScreen.main.bounds.width
                                            let centerX = screenWidth / 2
                                            let distance = abs(midX - centerX)
                                            let maxDistance = screenWidth * 0.4

                                            let scale = max(0.8, 1.2 - (distance / maxDistance) * 0.4)
                                            let opacity = max(0.6, 1.0 - (distance / maxDistance) * 0.4)

                                            Image(screenshot)
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.modal))
                                                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                                                .scaleEffect(scale)
                                                .opacity(opacity)
                                                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: scale)
                                        }
                                        .frame(width: UIScreen.main.bounds.width * 0.45, height: 300) // Reduced from 60% to 45%
                                    }
                                }
                                .padding(.horizontal, Layout.horizontalPadding)
                                .scrollTargetLayout()
                            }
                            .scrollTargetBehavior(.viewAligned)
                            .scrollIndicators(.hidden)
                        } else {
                            // Fallback for iOS 16 and earlier
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: Spacing.xs) {
                                    ForEach(Array(screenshots.enumerated()), id: \.offset) { index, screenshot in
                                        Image(screenshot)
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: UIScreen.main.bounds.width * 0.45)
                                            .frame(height: 300) // Reduced from 60% to 45%
                                            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.modal))
                                            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                                            .scaleEffect(index == currentIndex ? 1.2 : 0.8)
                                            .opacity(index == currentIndex ? 1.0 : 0.6)
                                    }
                                }
                                .padding(.horizontal, Layout.horizontalPadding)
                            }
                            .scrollIndicators(.hidden)
                        }
                    }
                    .frame(height: 330) // 75% of 440 = 330
                    .padding(.top, 22) // Reduced by 30% (32 * 0.7)

                    // Updated caption moved above the carousel for better layout
                    Text("Join Train to get personalized workouts and hit your goals faster.")
                        .font(.trainBody)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, Spacing.lg)
                        .padding(.top, Spacing.xl)

                    // Add bottom padding so content scrolls behind the floating button
                    Spacer()
                        .frame(height: 150) // Space for floating button area
                }
            }
            .scrollDisabled(false)
            .edgeFadeMask(topFade: 16, bottomFade: 60) // Visual gradients like questionnaire screens

            // Floating CTA button at bottom - matches questionnaire pattern
            VStack(spacing: Spacing.md) {
                // Get Started button - floating and fixed in Z-plane
                Button(action: onContinue) {
                    Text("Get Started")
                        .font(.trainBodyMedium) // Match CustomButton styling
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: ElementHeight.button) // 50px - matches Continue button
                        .background(Color.trainPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)) // 16px - matches Continue button
                }
                .padding(.horizontal, Spacing.md) // Match questionnaire horizontal padding
            }
            .padding(.bottom, Spacing.md) // Match questionnaire bottom padding
        }
        .charcoalGradientBackground()
        .onAppear {
            welcomeDebugLog("VIEW", "WelcomeView.onAppear", [
                "instanceId": String(instanceId),
                "viewDidAppear": "\(viewDidAppear)",
                "screenshotsCount": "\(screenshots.count)",
                "status": "✅ WELCOME CAROUSEL IS RENDERING"
            ])
            viewDidAppear = true
        }
        .onDisappear {
            welcomeDebugLog("VIEW", "WelcomeView.onDisappear", [
                "instanceId": String(instanceId),
                "reason": "User tapped Get Started or navigated away"
            ])
        }
    }
}

// MARK: - Debug Logging Helper

private func welcomeDebugLog(_ category: String, _ action: String, _ params: [String: String] = [:]) {
    var message = "[WELCOME-\(category)] \(action)"
    if !params.isEmpty {
        let paramString = params.map { "\($0.key)=\($0.value)" }.sorted().joined(separator: " | ")
        message += " | \(paramString)"
    }
    AppLogger.logUI(message)
}

#Preview {
    WelcomeView(
        onContinue: {
            AppLogger.logUI("Continue tapped")
        },
        onLogin: {
            AppLogger.logUI("Login tapped")
        }
    )
}