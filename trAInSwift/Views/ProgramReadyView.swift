//
//  ProgramReadyView.swift
//  trAInApp
//
//  Final screen showing program summary
//

import SwiftUI

struct ProgramReadyView: View {
    @ObservedObject var viewModel = WorkoutViewModel.shared  // Add WorkoutViewModel for safe navigation
    let program: Program
    let onStart: () -> Void
    let onSignupStart: (() -> Void)?  // Called when signup begins to prevent race conditions
    let onSignupCancel: (() -> Void)?  // Called when signup is cancelled to reset protection flags
    let selectedMuscleGroups: [String]  // Added for muscle groups display
    @State private var showSignup = false
    @State private var showLoading = false
    @State private var showPaywall = false
    @State private var showConfetti = false
    @State private var showPostSignupFlow = false  // New state for steps 18-19

    // MARK: - Feature Flags
    // Set to true to skip paywall for MVP/TestFlight
    // Set to false to enable paywall for production
    private let skipPaywallForMVP = true

    var body: some View {
        ZStack {
            // Show different screens based on state
            if showPostSignupFlow {
                PostSignupFlowView(
                    onComplete: {
                        print("🎯 [PROGRAM READY] PostSignupFlowView completed (steps 18-19)")
                        print("🎯 [PROGRAM READY] 🚀 All onboarding steps finished - calling onStart()")
                        onStart()
                    }
                )
                .onAppear {
                    print("🎯 [PROGRAM READY] VIEW STATE: Showing PostSignupFlowView (steps 18-19)")
                }
            } else if showPaywall {
                PaywallView(onComplete: {
                    print("🎯 [PROGRAM READY] PaywallView completed")
                    // After paywall, complete the whole flow
                    onStart()
                })
                .onAppear {
                    print("🎯 [PROGRAM READY] VIEW STATE: Showing PaywallView")
                }
            } else if showLoading {
                AccountCreationLoadingView(onComplete: {
                    print("🎯 [PROGRAM READY] AccountCreationLoadingView completed")
                    withAnimation {
                        if skipPaywallForMVP {
                            // MVP: Skip paywall and go straight to dashboard
                            print("🎯 [PROGRAM READY] 🚀 MVP Mode: Skipping paywall, calling onStart()")
                            onStart()
                        } else {
                            // Production: Show paywall
                            print("🎯 [PROGRAM READY] Production mode: Setting showPaywall = true")
                            showPaywall = true
                        }
                    }
                })
                .onAppear {
                    print("🎯 [PROGRAM READY] VIEW STATE: Showing AccountCreationLoadingView")
                }
            } else if showSignup {
                PostQuestionnaireSignupView(
                    onSignupSuccess: {
                        print("🎯 [PROGRAM READY] PostQuestionnaireSignupView onSignupSuccess called")
                        print("🎯 [PROGRAM READY] 🚀 Signup successful - proceeding to post-signup flow (steps 18-19)")

                        // Direct navigation without safeNavigate to avoid conflicts
                        print("🎯 [PROGRAM READY] 🎯 Directly transitioning to PostSignupFlowView")
                        showSignup = false  // Hide signup screen immediately
                        showPostSignupFlow = true  // Show steps 18-19 immediately
                    },
                    onSignupCancel: {
                        print("🎯 [PROGRAM READY] 🚫 Signup cancelled - returning to Program Ready screen")
                        print("🎯 [PROGRAM READY] 🔄 Resetting signup protection flag via onSignupCancel callback")
                        showSignup = false
                        // Reset the protection flag by calling onSignupCancel to clear it
                        onSignupCancel?()
                    }
                )
                .onAppear {
                    print("🎯 [PROGRAM READY] VIEW STATE: Showing PostQuestionnaireSignupView")
                }
            } else {
                // Original Program Ready View with confetti overlay
                programReadyContent
                    .overlay {
                        if showConfetti {
                            ConfettiView()
                                .allowsHitTesting(false)
                        }
                    }
                    .onAppear {
                        print("🎯 [PROGRAM READY] VIEW STATE: Showing Program Ready content with confetti")
                        print("🎯 [PROGRAM READY] Program Ready content appeared, triggering confetti")
                        // Trigger confetti animation when view appears
                        withAnimation {
                            showConfetti = true
                        }
                    }
            }
        }
    }

    private var programReadyContent: some View {
        ZStack {
            // Gradient base layer - uses centralized AppGradient
            AppGradient.background
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Success icon
                ZStack {
                    Circle()
                        .fill(Color.trainPrimary)
                        .frame(width: 80, height: 80)

                    Image(systemName: "checkmark")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.white)
                }

                // Title
                VStack(spacing: 8) {
                    Text("Program Ready!")
                        .font(.trainTitle)
                        .foregroundColor(.trainTextPrimary)

                    Text("Your personalised plan is complete")
                        .font(.trainSubtitle)
                        .foregroundColor(.trainTextSecondary)
                }

                // Program details - reordered as requested
                VStack(spacing: 12) {
                    ProgramInfoCard(
                        label: "Workout Split",
                        value: program.type.description
                    )

                    ProgramInfoCard(
                        label: "Prioritised Muscle Groups",
                        value: selectedMuscleGroups.isEmpty ? "Full body" : selectedMuscleGroups.joined(separator: ", ")
                    )

                    ProgramInfoCard(
                        label: "Frequency",
                        value: "\(program.daysPerWeek) days per week"
                    )

                    ProgramInfoCard(
                        label: "Session Length",
                        value: program.sessionDuration.rawValue
                    )
                }
                .padding(.horizontal, 24)

                Spacer()

                // Start button
                CustomButton(
                    title: "Start Training Now!",
                    action: {
                        print("🎯 [PROGRAM READY] 'Start Training Now!' button tapped")

                        // CRITICAL: Call onSignupStart IMMEDIATELY to prevent race conditions
                        print("🎯 [PROGRAM READY] 🚨 CALLING onSignupStart() to set protection flag BEFORE showing signup sheet")
                        onSignupStart?()
                        print("🎯 [PROGRAM READY] ✅ Protection flag set - QuestionnaireView is now immune to state changes")

                        withAnimation {
                            print("🎯 [PROGRAM READY] Setting showSignup = true")
                            showSignup = true
                        }
                    }
                )
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
    }
}

struct ProgramInfoCard: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: Spacing.sm) {
            Text(label)
                .font(.trainCaption)
                .foregroundColor(.trainTextSecondary)

            Text(value)
                .font(.trainBodyMedium)
                .foregroundColor(.trainTextPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.lg)
        .appCard()
    }
}

// MARK: - Confetti View

struct ConfettiView: View {
    @State private var confettiPieces: [ConfettiPiece] = []
    private let confettiColors: [Color] = [
        .red, .orange, .yellow, .green, .blue, .purple, .pink,
        Color(hex: "#FF6B6B") ?? .red,
        Color(hex: "#4ECDC4") ?? .teal,
        Color(hex: "#FFE66D") ?? .yellow,
        Color(hex: "#95E1D3") ?? .mint,
        Color(hex: "#F38181") ?? .pink
    ]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(confettiPieces) { piece in
                    ConfettiPieceView(piece: piece, screenHeight: geometry.size.height)
                }
            }
            .onAppear {
                generateConfetti(in: geometry.size)
            }
        }
        .ignoresSafeArea()
    }

    private func generateConfetti(in size: CGSize) {
        // Generate multiple waves of confetti
        for wave in 0..<3 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(wave) * 0.3) {
                let newPieces = (0..<40).map { _ in
                    ConfettiPiece(
                        id: UUID(),
                        x: CGFloat.random(in: 0...size.width),
                        color: confettiColors.randomElement() ?? .orange,
                        size: CGFloat.random(in: 8...14),
                        rotation: Double.random(in: 0...360),
                        delay: Double.random(in: 0...0.5),
                        duration: Double.random(in: 2.5...4.0),
                        horizontalMovement: CGFloat.random(in: -80...80),
                        shape: ConfettiShape.allCases.randomElement() ?? .rectangle
                    )
                }
                confettiPieces.append(contentsOf: newPieces)
            }
        }
    }
}

struct ConfettiPiece: Identifiable {
    let id: UUID
    let x: CGFloat
    let color: Color
    let size: CGFloat
    let rotation: Double
    let delay: Double
    let duration: Double
    let horizontalMovement: CGFloat
    let shape: ConfettiShape
}

enum ConfettiShape: CaseIterable {
    case rectangle
    case circle
    case triangle
}

struct ConfettiPieceView: View {
    let piece: ConfettiPiece
    let screenHeight: CGFloat
    @State private var yOffset: CGFloat = -50
    @State private var xOffset: CGFloat = 0
    @State private var rotationAngle: Double = 0
    @State private var opacity: Double = 1.0

    var body: some View {
        Group {
            switch piece.shape {
            case .rectangle:
                Rectangle()
                    .fill(piece.color)
                    .frame(width: piece.size, height: piece.size * 0.6)
            case .circle:
                Circle()
                    .fill(piece.color)
                    .frame(width: piece.size * 0.8, height: piece.size * 0.8)
            case .triangle:
                Triangle()
                    .fill(piece.color)
                    .frame(width: piece.size, height: piece.size)
            }
        }
        .rotationEffect(.degrees(rotationAngle))
        .rotation3DEffect(.degrees(rotationAngle * 0.5), axis: (x: 1, y: 0, z: 0))
        .position(x: piece.x + xOffset, y: yOffset)
        .opacity(opacity)
        .onAppear {
            withAnimation(
                Animation.easeOut(duration: piece.duration)
                    .delay(piece.delay)
            ) {
                yOffset = screenHeight + 100
                xOffset = piece.horizontalMovement
                rotationAngle = piece.rotation + Double.random(in: 720...1440)
            }

            // Fade out near the end
            withAnimation(
                Animation.easeIn(duration: 0.5)
                    .delay(piece.delay + piece.duration - 0.5)
            ) {
                opacity = 0
            }
        }
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
