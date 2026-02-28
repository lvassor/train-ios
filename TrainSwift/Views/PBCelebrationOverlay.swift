//
//  PBCelebrationOverlay.swift
//  TrainSwift
//
//  Full-screen Duolingo-style celebration overlay shown after workout completion.
//  Displays weight PBs, rep records, or a clean "another workout" message.
//

import SwiftUI

// MARK: - Celebration Data

struct PBCelebrationOverlay: View {

    /// Describes the type and content of celebration to display
    struct CelebrationData {
        let mode: Mode
        let weightPBs: [WeightPB]
        let repRecords: [RepRecord]
        let sessionNumber: Int

        enum Mode {
            case weightPB
            case repRecord
            case noImprovement
        }

        struct WeightPB {
            let exerciseName: String
            let previousWeight: Double
            let newWeight: Double
        }

        struct RepRecord {
            let exerciseName: String
            let repIncrease: Int
        }
    }

    let data: CelebrationData
    let onDismiss: () -> Void

    // MARK: - Animation State

    @State private var iconScale: CGFloat = 0.3
    @State private var textOpacity: Double = 0
    @State private var detailOpacity: Double = 0
    @State private var overlayOpacity: Double = 0
    @State private var confettiActive = false
    @State private var autoDismissTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            // Dark overlay background
            Color.black.opacity(0.75 * overlayOpacity)
                .ignoresSafeArea()

            // Confetti layer (modes 1 and 2 only)
            if data.mode == .weightPB || data.mode == .repRecord {
                CelebrationConfettiView(
                    isActive: $confettiActive,
                    intensity: data.mode == .weightPB ? .full : .light
                )
                .ignoresSafeArea()
                .allowsHitTesting(false)
            }

            // Content
            VStack(spacing: Spacing.lg) {
                Spacer()

                // Icon
                Text(iconEmoji)
                    .font(.system(size: 80))
                    .scaleEffect(iconScale)

                // Headline
                Text(headline)
                    .font(.trainTitle).fontWeight(.bold)
                    .foregroundColor(.trainTextPrimary)
                    .multilineTextAlignment(.center)
                    .opacity(textOpacity)

                // Detail section
                detailContent
                    .opacity(detailOpacity)

                Spacer()

                // Tap hint
                Text("Tap anywhere to continue")
                    .font(.trainCaption)
                    .foregroundColor(.trainTextSecondary.opacity(0.6))
                    .opacity(detailOpacity)
                    .padding(.bottom, Spacing.xl)
            }
            .padding(.horizontal, Spacing.xl)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            dismissOverlay()
        }
        .onAppear {
            startAnimations()
            scheduleAutoDismiss()
        }
        .onDisappear {
            autoDismissTask?.cancel()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
        .accessibilityAddTraits(.isModal)
    }

    // MARK: - Content Builders

    private var iconEmoji: String {
        switch data.mode {
        case .weightPB: return "\u{1F3C6}"      // trophy
        case .repRecord: return "\u{1F4AA}"      // flexed bicep
        case .noImprovement: return "\u{1F4D6}"  // open book
        }
    }

    private var headline: String {
        switch data.mode {
        case .weightPB: return "You Hit a PB!"
        case .repRecord: return "Rep Record!"
        case .noImprovement: return "Another Workout\nin the Books"
        }
    }

    @ViewBuilder
    private var detailContent: some View {
        switch data.mode {
        case .weightPB:
            VStack(spacing: Spacing.smd) {
                ForEach(data.weightPBs, id: \.exerciseName) { pb in
                    HStack(spacing: Spacing.sm) {
                        Text(pb.exerciseName)
                            .font(.trainBody).fontWeight(.medium)
                            .foregroundColor(.trainTextPrimary)
                        Spacer()
                        Text("\(Int(pb.previousWeight))kg")
                            .font(.trainBody)
                            .foregroundColor(.trainTextSecondary)
                        Image(systemName: "arrow.right")
                            .font(.trainCaption)
                            .foregroundColor(.trainPrimary)
                        Text("\(Int(pb.newWeight))kg")
                            .font(.trainBodyMedium)
                            .foregroundColor(.trainSuccess)
                    }
                    .padding(.vertical, Spacing.sm)
                    .padding(.horizontal, Spacing.md)
                    .background(Color.trainSurface.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm, style: .continuous))
                }
            }
            .padding(.horizontal, Spacing.md)

        case .repRecord:
            VStack(spacing: Spacing.smd) {
                ForEach(data.repRecords, id: \.exerciseName) { record in
                    HStack(spacing: Spacing.sm) {
                        Text(record.exerciseName)
                            .font(.trainBody).fontWeight(.medium)
                            .foregroundColor(.trainTextPrimary)
                        Spacer()
                        Text("+\(record.repIncrease) reps")
                            .font(.trainBodyMedium)
                            .foregroundColor(.trainSuccess)
                    }
                    .padding(.vertical, Spacing.sm)
                    .padding(.horizontal, Spacing.md)
                    .background(Color.trainSurface.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm, style: .continuous))
                }
            }
            .padding(.horizontal, Spacing.md)

        case .noImprovement:
            Text("That's workout #\(data.sessionNumber)")
                .font(.trainHeadline)
                .foregroundColor(.trainTextSecondary)
        }
    }

    // MARK: - Accessibility

    private var accessibilityDescription: String {
        switch data.mode {
        case .weightPB:
            let pbList = data.weightPBs.map {
                "\($0.exerciseName), \(Int($0.previousWeight)) to \(Int($0.newWeight)) kilograms"
            }.joined(separator: ". ")
            return "Personal best! \(pbList). Tap to continue."
        case .repRecord:
            let records = data.repRecords.map {
                "\($0.exerciseName), plus \($0.repIncrease) reps"
            }.joined(separator: ". ")
            return "Rep record! \(records). Tap to continue."
        case .noImprovement:
            return "Another workout in the books. That's workout number \(data.sessionNumber). Tap to continue."
        }
    }

    // MARK: - Animations

    private func startAnimations() {
        // Fade in overlay
        withAnimation(.easeIn(duration: AnimationDuration.standard)) {
            overlayOpacity = 1.0
        }

        // Spring-scale the icon
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            iconScale = 1.0
        }

        // Fade in text after a beat
        withAnimation(.easeIn(duration: AnimationDuration.standard).delay(0.3)) {
            textOpacity = 1.0
        }

        // Fade in details
        withAnimation(.easeIn(duration: AnimationDuration.standard).delay(0.5)) {
            detailOpacity = 1.0
        }

        // Start confetti shortly after icon lands
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            confettiActive = true
        }
    }

    private func scheduleAutoDismiss() {
        autoDismissTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
            guard !Task.isCancelled else { return }
            dismissOverlay()
        }
    }

    private func dismissOverlay() {
        autoDismissTask?.cancel()
        withAnimation(.easeOut(duration: AnimationDuration.standard)) {
            overlayOpacity = 0
            iconScale = 0.3
            textOpacity = 0
            detailOpacity = 0
            confettiActive = false
        }
        // Allow fade-out animation to finish before calling onDismiss
        DispatchQueue.main.asyncAfter(deadline: .now() + AnimationDuration.standard) {
            onDismiss()
        }
    }
}

// MARK: - Celebration Data Factory

extension PBCelebrationOverlay.CelebrationData {

    /// Analyse logged exercises against previous session data to determine celebration mode
    static func calculate(
        loggedExercises: [LoggedExercise],
        authService: AuthService
    ) -> PBCelebrationOverlay.CelebrationData {
        let programId = authService.getCurrentProgram()?.id?.uuidString ?? ""
        let sessionNumber = authService.getWorkoutHistory().count + 1

        var weightPBs: [WeightPB] = []
        var repRecords: [RepRecord] = []

        for exercise in loggedExercises {
            guard let previousSets = authService.getPreviousSessionData(
                programId: programId,
                exerciseName: exercise.exerciseName
            ) else { continue }

            // Weight PB: compare max weight across completed sets
            let currentMaxWeight = exercise.sets
                .filter { $0.completed }
                .map(\.weight)
                .max() ?? 0

            let previousMaxWeight = previousSets
                .map(\.weight)
                .max() ?? 0

            if currentMaxWeight > previousMaxWeight && currentMaxWeight > 0 {
                weightPBs.append(WeightPB(
                    exerciseName: exercise.exerciseName,
                    previousWeight: previousMaxWeight,
                    newWeight: currentMaxWeight
                ))
                continue // Weight PB takes priority over rep record for same exercise
            }

            // Rep record: compare total reps
            let currentTotalReps = exercise.sets
                .filter { $0.completed }
                .reduce(0) { $0 + $1.reps }

            let previousTotalReps = previousSets
                .reduce(0) { $0 + $1.reps }

            if currentTotalReps > previousTotalReps && currentTotalReps > 0 {
                repRecords.append(RepRecord(
                    exerciseName: exercise.exerciseName,
                    repIncrease: currentTotalReps - previousTotalReps
                ))
            }
        }

        // Determine mode
        let mode: Mode
        if !weightPBs.isEmpty {
            mode = .weightPB
        } else if !repRecords.isEmpty {
            mode = .repRecord
        } else {
            mode = .noImprovement
        }

        return Self(
            mode: mode,
            weightPBs: weightPBs,
            repRecords: repRecords,
            sessionNumber: sessionNumber
        )
    }
}

// MARK: - Confetti Particle System

/// Lightweight confetti animation using TimelineView
struct CelebrationConfettiView: View {
    @Binding var isActive: Bool
    let intensity: Intensity

    enum Intensity {
        case full   // weight PB - more particles
        case light  // rep record - fewer particles
    }

    private var particleCount: Int {
        intensity == .full ? 40 : 25
    }

    @State private var particles: [ConfettiParticle] = []
    @State private var startTime: Date = .now

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            Canvas { context, size in
                let elapsed = timeline.date.timeIntervalSince(startTime)
                for particle in particles {
                    let age = elapsed - particle.delay
                    guard age > 0 else { continue }

                    // Position: fall from top with horizontal drift
                    let progress = age / particle.duration
                    guard progress <= 1.2 else { continue } // Allow slight overflow before cleanup

                    let x = particle.startX * size.width + sin(age * particle.wobbleSpeed) * particle.wobbleMagnitude
                    let y = -20 + (size.height + 40) * progress
                    let rotation = Angle.degrees(age * particle.rotationSpeed)
                    let opacity = min(1.0, max(0, 1.0 - (progress - 0.7) / 0.3)) // Fade out last 30%

                    var transform = context.transform
                    transform = transform.translatedBy(x: x, y: y)
                    transform = transform.rotated(by: rotation.radians)

                    var ctx = context
                    ctx.transform = transform
                    ctx.opacity = opacity

                    let rect = CGRect(
                        x: -particle.size / 2,
                        y: -particle.size / 2,
                        width: particle.size,
                        height: particle.size * particle.aspectRatio
                    )

                    if particle.isCircle {
                        ctx.fill(
                            Path(ellipseIn: rect),
                            with: .color(particle.color)
                        )
                    } else {
                        ctx.fill(
                            Path(roundedRect: rect, cornerRadius: 1),
                            with: .color(particle.color)
                        )
                    }
                }
            }
        }
        .onChange(of: isActive) { _, active in
            if active {
                spawnParticles()
                startTime = .now
            } else {
                particles = []
            }
        }
    }

    private func spawnParticles() {
        let confettiColors = Color.trainConfetti
        particles = (0..<particleCount).map { _ in
            ConfettiParticle(
                startX: CGFloat.random(in: 0.05...0.95),
                delay: Double.random(in: 0...0.6),
                duration: Double.random(in: 1.8...3.0),
                size: CGFloat.random(in: 5...10),
                aspectRatio: CGFloat.random(in: 0.4...1.0),
                isCircle: Bool.random(),
                color: confettiColors.randomElement() ?? .trainPrimary,
                rotationSpeed: Double.random(in: 60...360),
                wobbleSpeed: Double.random(in: 1.5...4.0),
                wobbleMagnitude: CGFloat.random(in: 15...40)
            )
        }
    }
}

// MARK: - Confetti Particle Model

private struct ConfettiParticle: Identifiable {
    let id = UUID()
    let startX: CGFloat           // 0...1 normalized start X
    let delay: Double             // seconds before appearing
    let duration: Double          // fall duration
    let size: CGFloat             // base size
    let aspectRatio: CGFloat      // height multiplier (elongated pieces)
    let isCircle: Bool            // circle vs rectangle
    let color: Color
    let rotationSpeed: Double     // degrees per second
    let wobbleSpeed: Double       // horizontal oscillation speed
    let wobbleMagnitude: CGFloat  // horizontal oscillation amplitude
}

// MARK: - Angle Extension for Canvas

private extension CGAffineTransform {
    mutating func rotatedBy(_ angle: Angle) {
        self = self.rotated(by: angle.radians)
    }

    mutating func translatedBy(x: CGFloat, y: CGFloat) {
        self = self.translatedBy(x: x, y: y)
    }
}

// MARK: - Preview

#Preview("Weight PB") {
    ZStack {
        AppGradient.background.ignoresSafeArea()
        PBCelebrationOverlay(
            data: .init(
                mode: .weightPB,
                weightPBs: [
                    .init(exerciseName: "Bench Press", previousWeight: 80, newWeight: 85),
                    .init(exerciseName: "Shoulder Press", previousWeight: 40, newWeight: 42.5)
                ],
                repRecords: [],
                sessionNumber: 42
            ),
            onDismiss: {}
        )
    }
}

#Preview("Rep Record") {
    ZStack {
        AppGradient.background.ignoresSafeArea()
        PBCelebrationOverlay(
            data: .init(
                mode: .repRecord,
                weightPBs: [],
                repRecords: [
                    .init(exerciseName: "Lat Pulldown", repIncrease: 4),
                    .init(exerciseName: "Cable Row", repIncrease: 2)
                ],
                sessionNumber: 15
            ),
            onDismiss: {}
        )
    }
}

#Preview("No Improvement") {
    ZStack {
        AppGradient.background.ignoresSafeArea()
        PBCelebrationOverlay(
            data: .init(
                mode: .noImprovement,
                weightPBs: [],
                repRecords: [],
                sessionNumber: 8
            ),
            onDismiss: {}
        )
    }
}
