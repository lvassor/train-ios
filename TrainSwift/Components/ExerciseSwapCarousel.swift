//
//  ExerciseSwapCarousel.swift
//  TrainSwift
//
//  Carousel popup for swapping exercises with alternatives
//  Shows similar exercises targeting same muscle group
//

import SwiftUI

struct ExerciseSwapCarousel: View {
    let currentExercise: ProgramExercise
    let onSelect: (ProgramExercise) -> Void
    let onDismiss: () -> Void

    @State private var alternatives: [DBExercise] = []
    @State private var selectedIndex: Int = 0
    @State private var isLoading = true

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            // Carousel card
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Swap Exercise")
                        .font(.trainHeadline)
                        .foregroundColor(.trainTextPrimary)

                    Spacer()

                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.trainTextSecondary)
                            .frame(width: 32, height: 32)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                }
                .padding(Spacing.lg)

                // Current exercise info
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Current:")
                        .font(.trainCaption)
                        .foregroundColor(.trainTextSecondary)

                    Text(currentExercise.exerciseName)
                        .font(.trainBodyMedium)
                        .foregroundColor(.trainTextPrimary)

                    HStack(spacing: Spacing.sm) {
                        Text(currentExercise.primaryMuscle)
                            .font(.trainCaption)
                            .foregroundColor(.trainTextSecondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.trainTextSecondary.opacity(0.1))
                            .clipShape(Capsule())

                        Text(currentExercise.equipmentType)
                            .font(.trainCaption)
                            .foregroundColor(.trainTextSecondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.trainTextSecondary.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.md)

                Divider()
                    .background(Color.trainTextSecondary.opacity(0.2))
                    .padding(.horizontal, Spacing.lg)

                // Alternatives carousel
                if isLoading {
                    VStack {
                        ProgressView()
                            .tint(.trainPrimary)
                        Text("Finding alternatives...")
                            .font(.trainCaption)
                            .foregroundColor(.trainTextSecondary)
                    }
                    .frame(height: 250)
                } else if alternatives.isEmpty {
                    VStack(spacing: Spacing.md) {
                        Image(systemName: "exclamationmark.circle")
                            .font(.system(size: 40))
                            .foregroundColor(.trainTextSecondary)
                        Text("No alternatives available")
                            .font(.trainBody)
                            .foregroundColor(.trainTextSecondary)
                    }
                    .frame(height: 250)
                } else {
                    VStack(spacing: Spacing.md) {
                        Text("Alternatives (\(alternatives.count))")
                            .font(.trainCaption)
                            .foregroundColor(.trainTextSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, Spacing.lg)
                            .padding(.top, Spacing.md)

                        // Horizontal scroll carousel
                        TabView(selection: $selectedIndex) {
                            ForEach(Array(alternatives.enumerated()), id: \.element.id) { index, exercise in
                                AlternativeExerciseCard(exercise: exercise)
                                    .tag(index)
                            }
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))
                        .frame(height: 180)

                        // Page indicators
                        HStack(spacing: 6) {
                            ForEach(0..<alternatives.count, id: \.self) { index in
                                Circle()
                                    .fill(index == selectedIndex ? Color.trainPrimary : Color.trainTextSecondary.opacity(0.3))
                                    .frame(width: 8, height: 8)
                            }
                        }
                        .padding(.bottom, Spacing.sm)
                    }
                }

                // Swap button
                Button(action: swapExercise) {
                    Text("Swap to This Exercise")
                        .font(.trainBodyMedium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: ButtonHeight.standard)
                        .background(!alternatives.isEmpty ? Color.trainPrimary : Color.trainDisabled)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous))
                }
                .disabled(alternatives.isEmpty)
                .padding(Spacing.lg)
            }
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous))
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, 60)
        }
        .onAppear { loadAlternatives() }
    }

    private func loadAlternatives() {
        Task {
            do {
                // Fetch exercises targeting the same primary muscle using filter
                let filter = ExerciseDatabaseFilter(primaryMuscle: currentExercise.primaryMuscle)
                let exercises = try ExerciseDatabaseManager.shared.fetchExercises(filter: filter)

                // Filter out current exercise and prefer same equipment type
                let filtered = exercises.filter { $0.displayName != currentExercise.exerciseName }

                // Sort: same equipment first, then by name
                let sorted = filtered.sorted { ex1, ex2 in
                    let ex1SameEquip = ex1.equipmentType == currentExercise.equipmentType
                    let ex2SameEquip = ex2.equipmentType == currentExercise.equipmentType
                    if ex1SameEquip != ex2SameEquip {
                        return ex1SameEquip
                    }
                    return ex1.displayName < ex2.displayName
                }

                await MainActor.run {
                    alternatives = Array(sorted.prefix(5))
                    isLoading = false

                    // Debug: Log thumbnail URLs for all alternatives
                    print("🔄 Carousel loaded for: \(currentExercise.exerciseName)")
                    print("   Found \(alternatives.count) alternatives:")
                    for alt in alternatives {
                        let media = ExerciseMediaMapping.media(for: alt.exerciseId)
                        if let media = media {
                            if media.mediaType == .video, let guid = media.guid {
                                let url = BunnyConfig.videoThumbnailURL(for: guid)
                                print("   ✅ \(alt.exerciseId) (\(alt.displayName)): \(url?.absoluteString ?? "nil")")
                            } else if media.mediaType == .image, let filename = media.imageFilename {
                                let url = BunnyConfig.imageURL(for: filename)
                                print("   🖼️ \(alt.exerciseId) (\(alt.displayName)): \(url?.absoluteString ?? "nil")")
                            }
                        } else {
                            print("   ❌ \(alt.exerciseId) (\(alt.displayName)): NO MAPPING FOUND")
                        }
                    }
                }
            } catch {
                print("Error loading alternatives: \(error)")
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }

    private func swapExercise() {
        guard selectedIndex < alternatives.count else { return }
        let selected = alternatives[selectedIndex]

        // Create new ProgramExercise from the selected DBExercise
        let newExercise = ProgramExercise(
            exerciseId: String(selected.id),
            exerciseName: selected.displayName,
            sets: currentExercise.sets,
            repRange: currentExercise.repRange,
            restSeconds: currentExercise.restSeconds,
            primaryMuscle: selected.primaryMuscle,
            equipmentType: selected.equipmentType
        )

        onSelect(newExercise)
    }
}

// MARK: - Alternative Exercise Card

struct AlternativeExerciseCard: View {
    let exercise: DBExercise

    // Get media info for this exercise
    private var exerciseMedia: ExerciseMedia? {
        ExerciseMediaMapping.media(for: exercise.exerciseId)
    }

    // Get thumbnail URL based on media type
    private var thumbnailURL: URL? {
        guard let media = exerciseMedia else {
            print("⚠️ No media mapping for exercise: \(exercise.exerciseId)")
            return nil
        }

        if media.mediaType == .video, let guid = media.guid {
            // Video thumbnail from Bunny Stream
            let url = BunnyConfig.videoThumbnailURL(for: guid)
            print("🎬 Thumbnail URL for \(exercise.exerciseId): \(url?.absoluteString ?? "nil")")
            return url
        } else if media.mediaType == .image, let filename = media.imageFilename {
            // Static image from storage
            let url = BunnyConfig.imageURL(for: filename)
            print("🖼️ Image URL for \(exercise.exerciseId): \(url?.absoluteString ?? "nil")")
            return url
        }
        return nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Thumbnail
            ZStack {
                if let url = thumbnailURL {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            thumbnailPlaceholder
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure:
                            thumbnailPlaceholder
                        @unknown default:
                            thumbnailPlaceholder
                        }
                    }
                } else {
                    thumbnailPlaceholder
                }

                // Play icon overlay for videos
                if exerciseMedia?.mediaType == .video {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.white.opacity(0.9))
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                }
            }
            .frame(height: 80)
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm, style: .continuous))

            // Exercise name
            Text(exercise.displayName)
                .font(.trainBodyMedium)
                .foregroundColor(.trainTextPrimary)
                .lineLimit(2)

            // Badges
            HStack(spacing: Spacing.xs) {
                // Equipment
                HStack(spacing: 2) {
                    Image(systemName: "dumbbell")
                        .font(.system(size: 10))
                    Text(exercise.equipmentType)
                        .font(.system(size: 11))
                }
                .foregroundColor(.trainTextSecondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.trainTextSecondary.opacity(0.1))
                .clipShape(Capsule())

                // Primary muscle
                Text(exercise.primaryMuscle)
                    .font(.system(size: 11))
                    .foregroundColor(.trainPrimary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.trainPrimary.opacity(0.1))
                    .clipShape(Capsule())
            }
        }
        .padding(Spacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.trainBackground.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                .stroke(Color.trainPrimary.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal, Spacing.lg)
    }

    private var thumbnailPlaceholder: some View {
        ZStack {
            Color.trainTextSecondary.opacity(0.1)
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 24))
                .foregroundColor(.trainTextSecondary.opacity(0.5))
        }
    }
}

// MARK: - Preview

#Preview {
    ExerciseSwapCarousel(
        currentExercise: ProgramExercise(
            exerciseId: "1",
            exerciseName: "Bench Press",
            sets: 3,
            repRange: "8-12",
            restSeconds: 90,
            primaryMuscle: "Chest",
            equipmentType: "Barbell"
        ),
        onSelect: { _ in },
        onDismiss: {}
    )
}
