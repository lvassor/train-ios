//
//  DashboardExerciseCard.swift
//  TrainSwift
//
//  Exercise card component for the dashboard showing video thumbnail and muscle visualization
//  Per Figma redesign specs
//

import SwiftUI

// MARK: - Dashboard Exercise Card

struct DashboardExerciseCard: View {
    let exercise: ProgramExercise
    var secondaryMuscle: String? = nil
    var onTap: () -> Void = {}
    var onVideoTap: () -> Void = {}

    @State private var showVideoPlayer = false
    @ObservedObject private var authService = AuthService.shared

    /// Get user's gender from questionnaire data
    private var userGender: MuscleSelector.BodyGender {
        guard let user = authService.currentUser,
              let questionnaireData = user.getQuestionnaireData() else {
            return .male
        }
        return questionnaireData.gender.lowercased() == "female" ? .female : .male
    }

    private var thumbnailURL: URL? {
        ExerciseMediaMapping.thumbnailURL(for: exercise.exerciseId)
    }

    private var hasVideo: Bool {
        ExerciseMediaMapping.videoGuid(for: exercise.exerciseId) != nil
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.md) {
                // Video thumbnail with play button
                ZStack(alignment: .bottomLeading) {
                    // Thumbnail image - fixed 80x64 dimensions
                    if let url = thumbnailURL {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: ThumbnailSize.width, height: ThumbnailSize.height)
                                    .clipped()
                                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.xs, style: .continuous))
                            case .failure:
                                thumbnailPlaceholder
                            case .empty:
                                thumbnailPlaceholder
                                    .overlay {
                                        ProgressView()
                                            .tint(.trainTextSecondary)
                                            .scaleEffect(0.7)
                                    }
                            @unknown default:
                                thumbnailPlaceholder
                            }
                        }
                    } else {
                        thumbnailPlaceholder
                    }

                    // Play button overlay (only for videos)
                    if hasVideo {
                        Button(action: {
                            showVideoPlayer = true
                            onVideoTap()
                        }) {
                            Image(systemName: "play.fill")
                                .font(.trainMicro)
                                .foregroundColor(.white)
                                .padding(Spacing.sm)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                        .offset(x: 4, y: -4)
                    }
                }
                .frame(width: ThumbnailSize.width, height: ThumbnailSize.height)

                // Exercise info
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(exercise.exerciseName)
                        .font(.trainBody).fontWeight(.medium)
                        .foregroundColor(.trainTextPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    Text("\(exercise.sets) sets • \(exercise.repRange) reps")
                        .font(.trainCaption).fontWeight(.light)
                        .foregroundColor(.trainTextSecondary)
                }

                Spacer()

                // Muscle visualization - matches thumbnail height (64pt)
                CompactMuscleHighlight(
                    primaryMuscle: exercise.primaryMuscle,
                    secondaryMuscle: secondaryMuscle,
                    gender: userGender
                )
                .frame(height: 64)
            }
            .padding(Spacing.md)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                    .stroke(Color.trainTextSecondary.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .fullScreenCover(isPresented: $showVideoPlayer) {
            if let guid = ExerciseMediaMapping.videoGuid(for: exercise.exerciseId) {
                FullscreenVideoPlayer(videoGuid: guid)
            }
        }
    }

    private var thumbnailPlaceholder: some View {
        RoundedRectangle(cornerRadius: CornerRadius.xs, style: .continuous)
            .fill(Color.trainPlaceholder)
            .frame(width: ThumbnailSize.width, height: ThumbnailSize.height)
            .overlay {
                Image(systemName: "photo")
                    .font(.system(size: IconSize.md))
                    .foregroundColor(.trainTextSecondary.opacity(0.5))
            }
    }
}

// MARK: - Compact Muscle Highlight (for exercise cards)

/// A compact, non-interactive body diagram that highlights primary/secondary muscles
/// Uses the same rendering approach as StaticMuscleView - no cropping, proper aspect ratio
struct CompactMuscleHighlight: View {
    let primaryMuscle: String
    var secondaryMuscle: String?
    var gender: MuscleSelector.BodyGender = .male

    // Standard canvas dimensions for aspect ratio (matching transformed data viewBox)
    private let svgWidth: CGFloat = 650
    private let svgHeight: CGFloat = 1450

    /// Determines body side based on primary muscle location
    private var bodySide: MuscleSelector.BodySide {
        guard let primarySlug = muscleNameToSlug(primaryMuscle) else {
            return .front
        }

        switch primarySlug {
        // Back muscles
        case .upperback, .lowerback, .trapezius, .gluteal, .hamstring, .calves:
            return .back
        // Triceps are more visible from back
        case .triceps:
            return .back
        // Front muscles
        case .chest, .abs, .biceps, .quadriceps, .deltoids, .obliques, .forearm:
            return .front
        default:
            return .front
        }
    }

    /// Get the appropriate body parts data based on gender and side
    private var bodyParts: [MusclePart] {
        switch (gender, bodySide) {
        case (.male, .front):
            return BodyDataProvider.maleFront
        case (.male, .back):
            return BodyDataProvider.maleBack
        case (.female, .front):
            return BodyDataProvider.femaleFront
        case (.female, .back):
            return BodyDataProvider.femaleBack
        }
    }

    var body: some View {
        GeometryReader { geometry in
            let scale = min(geometry.size.width / svgWidth, geometry.size.height / svgHeight)

            ZStack {
                bodyDiagram
                    .frame(width: svgWidth, height: svgHeight)
                    .scaleEffect(scale, anchor: .center)
                    .frame(width: geometry.size.width, height: geometry.size.height)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .aspectRatio(svgWidth / svgHeight, contentMode: .fit)
    }

    @ViewBuilder
    private var bodyDiagram: some View {
        ZStack {
            ForEach(bodyParts, id: \.slug) { part in
                let highlightType = getHighlightType(for: part.slug)

                StaticMusclePathView(
                    paths: part.paths.allPaths,
                    fillColor: getFillColor(for: part, highlightType: highlightType),
                    isHighlighted: highlightType != .none
                )
            }
        }
    }

    private enum HighlightType {
        case primary
        case secondary
        case none
    }

    private func getHighlightType(for slug: MuscleSlug) -> HighlightType {
        // Check primary muscle
        let primarySlug = muscleNameToSlug(primaryMuscle)
        if slug == primarySlug { return .primary }

        // Check secondary muscle if provided
        if let secondary = secondaryMuscle {
            let secondarySlug = muscleNameToSlug(secondary)
            if slug == secondarySlug { return .secondary }
        }

        return .none
    }

    private func muscleNameToSlug(_ name: String) -> MuscleSlug? {
        let lowercased = name.lowercased()

        // Direct mappings from database muscle names to MuscleSlug
        // Database values: Adductors, Back, Biceps, Calves, Chest, Core, Forearms, Glutes, Hamstrings, Quads, Rear Delts, Shoulders, Traps, Triceps
        if lowercased.contains("chest") || lowercased.contains("pectorals") { return .chest }
        if lowercased.contains("shoulder") || lowercased.contains("deltoid") || lowercased == "rear delts" { return .deltoids }
        if lowercased.contains("bicep") { return .biceps }
        if lowercased.contains("tricep") { return .triceps }
        if lowercased.contains("quad") || lowercased == "adductors" { return .quadriceps }
        if lowercased.contains("hamstring") { return .hamstring }
        if lowercased.contains("glute") { return .gluteal }
        if lowercased.contains("calf") || lowercased.contains("calves") { return .calves }
        if lowercased.contains("abs") || lowercased.contains("abdominal") || lowercased == "core" { return .abs }
        if lowercased.contains("oblique") { return .obliques }
        if lowercased.contains("lat") || lowercased.contains("upper back") || lowercased == "back" { return .upperback }
        if lowercased.contains("lower back") || lowercased.contains("erector") { return .lowerback }
        if lowercased.contains("trap") { return .trapezius }
        if lowercased.contains("forearm") { return .forearm }

        return nil
    }

    private func getFillColor(for part: MusclePart, highlightType: HighlightType) -> Color {
        switch highlightType {
        case .primary, .secondary:
            return Color.trainPrimary
        case .none:
            // Non-highlighted parts use uniform grey matching Demo tab style
            return Color.trainMuscleInactive
        }
    }
}

// MARK: - Dark Mode Compatible Exercise Card

struct DashboardExerciseCardDarkMode: View {
    let exercise: ProgramExercise
    var secondaryMuscle: String? = nil
    var onTap: () -> Void = {}
    var onVideoTap: () -> Void = {}

    @State private var showVideoPlayer = false
    @ObservedObject private var authService = AuthService.shared

    /// Get user's gender from questionnaire data
    private var userGender: MuscleSelector.BodyGender {
        guard let user = authService.currentUser,
              let questionnaireData = user.getQuestionnaireData() else {
            return .male
        }
        return questionnaireData.gender.lowercased() == "female" ? .female : .male
    }

    private var thumbnailURL: URL? {
        ExerciseMediaMapping.thumbnailURL(for: exercise.exerciseId)
    }

    private var hasVideo: Bool {
        ExerciseMediaMapping.videoGuid(for: exercise.exerciseId) != nil
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.md) {
                // Video thumbnail with play button
                ZStack(alignment: .bottomLeading) {
                    // Thumbnail image - fixed 80x64 dimensions
                    if let url = thumbnailURL {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: ThumbnailSize.width, height: ThumbnailSize.height)
                                    .clipped()
                                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.xs, style: .continuous))
                            case .failure:
                                thumbnailPlaceholder
                            case .empty:
                                thumbnailPlaceholder
                                    .overlay {
                                        ProgressView()
                                            .tint(.trainTextSecondary)
                                            .scaleEffect(0.7)
                                    }
                            @unknown default:
                                thumbnailPlaceholder
                            }
                        }
                    } else {
                        thumbnailPlaceholder
                    }

                    // Play button overlay (only for videos)
                    if hasVideo {
                        Button(action: {
                            showVideoPlayer = true
                            onVideoTap()
                        }) {
                            Image(systemName: "play.fill")
                                .font(.trainMicro)
                                .foregroundColor(.white)
                                .padding(Spacing.sm)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                        .offset(x: 4, y: -4)
                    }
                }
                .frame(width: ThumbnailSize.width, height: ThumbnailSize.height)

                // Exercise info
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(exercise.exerciseName)
                        .font(.trainBody).fontWeight(.medium)
                        .foregroundColor(.trainTextPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    Text("\(exercise.sets) sets • \(exercise.repRange) reps")
                        .font(.trainCaption).fontWeight(.light)
                        .foregroundColor(.trainTextSecondary)
                }

                Spacer()

                // Muscle visualization - matches thumbnail height (64pt)
                CompactMuscleHighlight(
                    primaryMuscle: exercise.primaryMuscle,
                    secondaryMuscle: secondaryMuscle,
                    gender: userGender
                )
                .frame(height: 64)
            }
            .padding(Spacing.md)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                    .stroke(Color.trainTextSecondary.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .fullScreenCover(isPresented: $showVideoPlayer) {
            if let guid = ExerciseMediaMapping.videoGuid(for: exercise.exerciseId) {
                FullscreenVideoPlayer(videoGuid: guid)
            }
        }
    }

    private var thumbnailPlaceholder: some View {
        RoundedRectangle(cornerRadius: CornerRadius.xs, style: .continuous)
            .fill(Color.trainTextSecondary.opacity(0.2))
            .frame(width: ThumbnailSize.width, height: ThumbnailSize.height)
            .overlay {
                Image(systemName: "photo")
                    .font(.system(size: IconSize.md))
                    .foregroundColor(.trainTextSecondary.opacity(0.5))
            }
    }
}

// MARK: - Preview

#Preview {
    let exercise = ProgramExercise(
        exerciseId: "EX022",
        exerciseName: "Barbell Bench Press",
        sets: 4,
        repRange: "8-12",
        restSeconds: 120,
        primaryMuscle: "Chest",
        equipmentType: "Barbell",
        complexityLevel: 1
    )

    VStack(spacing: Spacing.md) {
        // Light mode style
        DashboardExerciseCard(exercise: exercise)
            .padding(.horizontal)

        // Dark mode style
        ZStack {
            AppGradient.background
                .ignoresSafeArea()

            DashboardExerciseCardDarkMode(exercise: exercise)
                .padding(.horizontal)
        }
        .frame(height: 120)
    }
}
