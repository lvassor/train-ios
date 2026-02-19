//
//  ExercisePickerView.swift
//  trAInSwift
//
//  Exercise picker for adding exercises to a session
//  Filters by session muscle groups with search and equipment filtering
//

import SwiftUI

struct ExercisePickerView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var authService = AuthService.shared

    let sessionMuscleGroups: [String]
    let existingExerciseIds: Set<String>
    let onSelect: (ProgramExercise) -> Void

    @State private var searchText = ""
    @State private var exercises: [DBExercise] = []
    @State private var isLoading = true
    @State private var selectedMuscleFilter: String? = nil

    /// Get user's experience level for complexity warnings
    private var userComplexity: Int {
        guard let user = authService.currentUser,
              let data = user.getQuestionnaireData() else { return 2 }
        switch data.experienceLevel {
        case "0_months": return 1
        case "0_6_months": return 1
        case "6_months_2_years": return 2
        default: return 2
        }
    }

    private var filteredExercises: [DBExercise] {
        var result = exercises

        if let muscle = selectedMuscleFilter {
            result = result.filter { $0.primaryMuscle == muscle }
        }

        if !searchText.isEmpty {
            result = result.filter {
                $0.displayName.localizedCaseInsensitiveContains(searchText)
            }
        }

        return result
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Warning banner
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.trainPrimary)
                    Text("Adding an exercise may increase session duration. Consider swapping instead.")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.trainTextSecondary)
                }
                .padding(Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.trainPrimary.opacity(0.08))

                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.trainTextSecondary)
                    TextField("Search exercises", text: $searchText)
                        .font(.trainBody)
                        .foregroundColor(.trainTextPrimary)
                }
                .padding(Spacing.sm)
                .background(Color.trainSurface)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm, style: .continuous))
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.sm)

                // Muscle group filter chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.sm) {
                        FilterChip(
                            label: "All",
                            isSelected: selectedMuscleFilter == nil,
                            onTap: { selectedMuscleFilter = nil }
                        )
                        ForEach(sessionMuscleGroups, id: \.self) { muscle in
                            FilterChip(
                                label: muscle,
                                isSelected: selectedMuscleFilter == muscle,
                                onTap: { selectedMuscleFilter = muscle }
                            )
                        }
                    }
                    .padding(.horizontal, Spacing.lg)
                }
                .padding(.vertical, Spacing.xs)

                // Exercise list
                if isLoading {
                    Spacer()
                    ProgressView("Loading exercises...")
                        .foregroundColor(.trainTextPrimary)
                    Spacer()
                } else if filteredExercises.isEmpty {
                    Spacer()
                    VStack(spacing: Spacing.md) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(.trainTextSecondary)
                        Text("No exercises found")
                            .font(.trainBodyMedium)
                            .foregroundColor(.trainTextSecondary)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: Spacing.sm) {
                            ForEach(filteredExercises) { exercise in
                                ExercisePickerCard(
                                    exercise: exercise,
                                    isAboveUserLevel: exercise.numericComplexity > userComplexity,
                                    onSelect: { selectExercise(exercise) }
                                )
                            }
                        }
                        .padding(.horizontal, Spacing.lg)
                        .padding(.top, Spacing.sm)
                        .padding(.bottom, Spacing.xl)
                    }
                }
            }
            .charcoalGradientBackground()
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.trainTextSecondary)
                }
            }
        }
        .onAppear { loadExercises() }
    }

    private func loadExercises() {
        Task {
            do {
                // Query exercises matching the session's muscle groups (no equipment filter)
                var allExercises: [DBExercise] = []

                for muscle in sessionMuscleGroups {
                    let filter = ExerciseDatabaseFilter(
                        primaryMuscle: muscle,
                        excludeExerciseIds: existingExerciseIds
                    )
                    let results = try ExerciseDatabaseManager.shared.fetchExercises(filter: filter)
                    allExercises.append(contentsOf: results)
                }

                // Deduplicate by exercise ID
                var seen = Set<String>()
                allExercises = allExercises.filter { seen.insert($0.exerciseId).inserted }

                // Sort by canonical rating (higher = more fundamental compound exercises first)
                allExercises.sort { $0.canonicalRating > $1.canonicalRating }

                await MainActor.run {
                    exercises = allExercises
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }

    private func selectExercise(_ dbExercise: DBExercise) {
        let newExercise = ProgramExercise(
            exerciseId: dbExercise.exerciseId,
            exerciseName: dbExercise.displayName,
            sets: 3,
            repRange: "8-12",
            restSeconds: 90,
            primaryMuscle: dbExercise.primaryMuscle,
            equipmentType: dbExercise.equipmentType,
            complexityLevel: dbExercise.numericComplexity
        )
        onSelect(newExercise)
        dismiss()
    }
}

// MARK: - Filter Chip

private struct FilterChip: View {
    let label: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : .trainTextSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? Color.trainPrimary : Color.trainSurface)
                .clipShape(Capsule())
        }
    }
}

// MARK: - Exercise Picker Card

private struct ExercisePickerCard: View {
    let exercise: DBExercise
    let isAboveUserLevel: Bool
    let onSelect: () -> Void

    private var thumbnailURL: URL? {
        guard let media = ExerciseMediaMapping.media(for: exercise.exerciseId),
              let guid = media.guid else { return nil }
        return BunnyConfig.videoThumbnailURL(for: guid)
    }

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Thumbnail
                if let url = thumbnailURL {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 64, height: 52)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        default:
                            thumbnailPlaceholder
                        }
                    }
                } else {
                    thumbnailPlaceholder
                }

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Text(exercise.displayName)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.trainTextPrimary)
                            .lineLimit(2)

                        if isAboveUserLevel {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.orange)
                        }
                    }

                    HStack(spacing: 8) {
                        Text(exercise.primaryMuscle)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.trainTextSecondary)

                        Text("•")
                            .foregroundColor(.trainTextSecondary)

                        Text(exercise.equipmentType)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.trainTextSecondary)
                    }
                }

                Spacer()

                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.trainPrimary)
            }
            .padding(12)
            .background(Color.trainSurface)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var thumbnailPlaceholder: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(Color.trainTextSecondary.opacity(0.15))
            .frame(width: 64, height: 52)
            .overlay {
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.trainTextSecondary.opacity(0.4))
            }
    }
}
