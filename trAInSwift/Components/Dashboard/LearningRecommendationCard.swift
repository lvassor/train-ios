//
//  LearningRecommendationCard.swift
//  trAInSwift
//
//  Learning recommendation carousel card with video thumbnail and content
//

import SwiftUI

struct LearningRecommendationCard: View {
    let data: LearningRecommendationData

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Video thumbnail with play overlay
            ZStack {
                AsyncImage(url: data.thumbnailURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.trainGradientEdge.opacity(0.3))
                }

                // Play button overlay
                Circle()
                    .fill(Color.black.opacity(0.6))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: "play.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                    )
            }
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))

            // Content
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Recommended Learning")
                    .font(.trainCaption)
                    .foregroundColor(.trainTextSecondary)

                Text(data.title)
                    .font(.trainBodyMedium)
                    .foregroundColor(.trainTextPrimary)
                    .lineLimit(2)

                Text(data.description)
                    .font(.trainCaption)
                    .foregroundColor(.trainTextSecondary)
                    .lineLimit(2)

                Spacer()

                // Muscle group highlights
                if let muscleGroup = extractMuscleGroup(from: data.title) {
                    HStack(spacing: Spacing.xs) {
                        StaticMuscleView(
                            muscleGroup: muscleGroup,
                            gender: .male,
                            size: 24,
                            useUniformBaseColor: true
                        )
                        .frame(width: 24, height: 24)

                        Text(muscleGroup)
                            .font(.trainCaption)
                            .foregroundColor(.trainPrimary)
                    }
                } else {
                    // Fallback play button
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.trainPrimary)

                        Text("Watch")
                            .font(.trainCaption)
                            .foregroundColor(.trainPrimary)
                    }
                }
            }

            Spacer()
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .onTapGesture {
            // TODO: Navigate to video player
            print("Tapped learning recommendation: \(data.title)")
        }
    }

    private func extractMuscleGroup(from title: String) -> String? {
        let lowercaseTitle = title.lowercased()

        if lowercaseTitle.contains("chest") {
            return "Chest"
        } else if lowercaseTitle.contains("shoulder") {
            return "Shoulders"
        } else if lowercaseTitle.contains("bicep") {
            return "Biceps"
        } else if lowercaseTitle.contains("tricep") {
            return "Triceps"
        } else if lowercaseTitle.contains("quad") {
            return "Quads"
        } else if lowercaseTitle.contains("glute") {
            return "Glutes"
        } else if lowercaseTitle.contains("back") {
            return "Back"
        } else if lowercaseTitle.contains("calves") {
            return "Calves"
        }
        return nil
    }
}

// MARK: - Preview

#Preview {
    let sampleData = LearningRecommendationData(
        title: "Barbell Setup",
        description: "Learn proper barbell positioning and safety",
        videoGuid: "sample-guid",
        thumbnailURL: BunnyConfig.videoThumbnailURL(for: "sample-guid")
    )

    return ZStack {
        AppGradient.background
            .ignoresSafeArea()

        LearningRecommendationCard(data: sampleData)
            .appCard()
            .padding()
    }
}