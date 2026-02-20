//
//  LearningRecommendationCard.swift
//  TrainSwift
//
//  Learning recommendation carousel card with video thumbnail and content
//

import SwiftUI

struct LearningRecommendationCard: View {
    let data: LearningRecommendationData
    @State private var showVideoPlayer = false

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Video thumbnail with play overlay - tappable to play video
            // Video thumbnail with play overlay - matches exercise card dimensions (80x64, 8pt radius)
            ZStack(alignment: .bottomLeading) {
                AsyncImage(url: data.thumbnailURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 80, height: 64)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
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

                // Play button overlay (bottom-left, matching exercise cards)
                if data.videoGuid != nil {
                    Button(action: {
                        showVideoPlayer = true
                    }) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.white)
                            .padding(6)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    .offset(x: 4, y: -4)
                }
            }
            .frame(width: 80, height: 64)

            // Content
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Recommended Learning")
                    .font(.trainCaption)
                    .foregroundColor(.trainTextSecondary)

                Text(data.title)
                    .font(.trainBodyMedium)
                    .foregroundColor(.trainTextPrimary)
                    .lineLimit(1)

                Text(data.description)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.trainTextSecondary)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .fullScreenCover(isPresented: $showVideoPlayer) {
            if let guid = data.videoGuid {
                FullscreenVideoPlayer(videoGuid: guid)
            }
        }
    }

    private var thumbnailPlaceholder: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(Color.trainPlaceholder)
            .frame(width: 80, height: 64)
            .overlay {
                Image(systemName: "photo")
                    .font(.system(size: 20))
                    .foregroundColor(.trainTextSecondary.opacity(0.5))
            }
    }
}

// MARK: - Preview

#Preview {
    let sampleGuid = "60ef27d7-5909-429a-a2c1-305cca4eaaf3"
    let sampleData = LearningRecommendationData(
        title: "Learn Barbell Bench Press",
        description: "Master proper form and technique for this key exercise",
        exerciseId: "EX007",
        videoGuid: sampleGuid,
        thumbnailURL: BunnyConfig.videoThumbnailURL(for: sampleGuid)
    )

    return ZStack {
        AppGradient.background
            .ignoresSafeArea()

        LearningRecommendationCard(data: sampleData)
            .appCard()
            .padding()
    }
}