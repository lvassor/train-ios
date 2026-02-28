//
//  ExerciseLibraryView.swift
//  TrainSwift
//
//  Browse all exercises with muscle group and equipment filtering
//

import SwiftUI

struct ExerciseLibraryView: View {
    @Environment(\.dismiss) var dismiss
    @State private var exercises: [DBExercise] = []
    @State private var filteredExercises: [DBExercise] = []
    @State private var searchText: String = ""
    @State private var showMuscleFilter: Bool = false
    @State private var showEquipmentFilter: Bool = false
    @State private var selectedMuscles: Set<String> = []
    @State private var selectedEquipment: Set<String> = []
    @State private var isLoading: Bool = true

    let muscleGroups = ["Chest", "Back", "Shoulders", "Arms", "Legs", "Core"]
    let equipmentTypes = ["Barbell", "Dumbbell", "Cable", "Machine", "Kettlebell", "Bodyweight"]

    var body: some View {
        ZStack {
            // Gradient base layer - uses centralized AppGradient
            AppGradient.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.trainTextSecondary)

                    TextField("Search exercises", text: $searchText)
                        .autocorrectionDisabled()
                        .onChange(of: searchText) { _, _ in
                            applyFilters()
                        }

                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.trainTextSecondary)
                        }
                    }
                }
                .padding(Spacing.md)
                .appCard()
                .cornerRadius(CornerRadius.sm)
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.md)

                // Filter buttons
                HStack(spacing: Spacing.sm) {
                    Text("Filter:")
                        .font(.trainBodyMedium)
                        .foregroundColor(.trainTextPrimary)
                        .fixedSize()

                    Button(action: { showMuscleFilter = true }) {
                        HStack(spacing: Spacing.xs) {
                            Text("Muscle")
                                .font(.trainBody)
                            if !selectedMuscles.isEmpty {
                                Text("(\(selectedMuscles.count))")
                                    .font(.trainCaption)
                            }
                            Image(systemName: "chevron.down")
                                .font(.trainMicro)
                        }
                        .foregroundColor(selectedMuscles.isEmpty ? .trainTextPrimary : .trainPrimary)
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.sm)
                        .background(selectedMuscles.isEmpty ? Color.clear : Color.trainPrimary.opacity(0.1))
                        .appCard()
                        .cornerRadius(CornerRadius.sm)
                    }
                    .fixedSize()

                    Button(action: { showEquipmentFilter = true }) {
                        HStack(spacing: Spacing.xs) {
                            Text("Equipment")
                                .font(.trainBody)
                            if !selectedEquipment.isEmpty {
                                Text("(\(selectedEquipment.count))")
                                    .font(.trainCaption)
                            }
                            Image(systemName: "chevron.down")
                                .font(.trainMicro)
                        }
                        .foregroundColor(selectedEquipment.isEmpty ? .trainTextPrimary : .trainPrimary)
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.sm)
                        .background(selectedEquipment.isEmpty ? Color.clear : Color.trainPrimary.opacity(0.1))
                        .appCard()
                        .cornerRadius(CornerRadius.sm)
                    }
                    .fixedSize()

                    Spacer()
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.md)

                // Exercise count
                HStack {
                    Text("\(filteredExercises.count) exercises")
                        .font(.trainCaption)
                        .foregroundColor(.trainTextSecondary)

                    Spacer()

                    if !selectedMuscles.isEmpty || !selectedEquipment.isEmpty || !searchText.isEmpty {
                        Button(action: clearFilters) {
                            Text("Clear filters")
                                .font(.trainCaption)
                                .foregroundColor(.trainPrimary)
                        }
                    }
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.sm)

                // Exercise list
                if isLoading {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.5)
                    Spacer()
                } else if filteredExercises.isEmpty {
                    Spacer()
                    VStack(spacing: Spacing.md) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: IconSize.xl))
                            .foregroundColor(.trainTextSecondary)

                        Text("No exercises found")
                            .font(.trainBody)
                            .foregroundColor(.trainTextSecondary)

                        Text("Try adjusting your filters")
                            .font(.trainCaption)
                            .foregroundColor(.trainTextSecondary)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: Spacing.md) {
                            ForEach(filteredExercises) { exercise in
                                NavigationLink(destination: ExerciseDemoHistoryView(exercise: exercise)) {
                                    ExerciseLibraryCard(exercise: exercise)
                                }
                            }
                        }
                        .padding(.horizontal, Spacing.lg)
                        .padding(.vertical, Spacing.sm)
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .navigationTitle("Exercise Library")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showMuscleFilter) {
            FilterSheet(
                title: "Filter by Muscle Group",
                options: muscleGroups,
                selected: $selectedMuscles,
                onApply: applyFilters
            )
        }
        .sheet(isPresented: $showEquipmentFilter) {
            FilterSheet(
                title: "Filter by Equipment",
                options: equipmentTypes,
                selected: $selectedEquipment,
                onApply: applyFilters
            )
        }
        .onAppear {
            loadExercises()
        }
    }

    private func loadExercises() {
        isLoading = true

        Task.detached(priority: .userInitiated) {
            do {
                let dbManager = ExerciseDatabaseManager.shared
                let filter = ExerciseDatabaseFilter()
                let allExercises = try dbManager.fetchExercises(filter: filter)

                await MainActor.run {
                    self.exercises = allExercises
                    self.filteredExercises = allExercises
                    self.isLoading = false
                }
            } catch {
                AppLogger.logDatabase("Error loading exercises: \(error)", level: .error)
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }

    private func applyFilters() {
        var filtered = exercises

        // Apply muscle group filter
        if !selectedMuscles.isEmpty {
            filtered = filtered.filter { exercise in
                selectedMuscles.contains(exercise.primaryMuscle) ||
                (exercise.secondaryMuscle.map { selectedMuscles.contains($0) } ?? false)
            }
        }

        // Apply equipment filter
        if !selectedEquipment.isEmpty {
            filtered = filtered.filter { exercise in
                selectedEquipment.contains(exercise.equipmentType)
            }
        }

        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { exercise in
                exercise.displayName.localizedCaseInsensitiveContains(searchText) ||
                exercise.primaryMuscle.localizedCaseInsensitiveContains(searchText)
            }
        }

        filteredExercises = filtered
    }

    private func clearFilters() {
        searchText = ""
        selectedMuscles.removeAll()
        selectedEquipment.removeAll()
        applyFilters()
    }
}

// MARK: - Exercise Library Card

struct ExerciseLibraryCard: View {
    let exercise: DBExercise

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Thumbnail with AsyncImage from Bunny CDN
            ZStack(alignment: .bottomLeading) {
                if let url = ExerciseMediaMapping.thumbnailURL(for: exercise.exerciseId) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 80, height: 64)
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
            }
            .frame(width: 80, height: 64)

            // Exercise info
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(exercise.displayName)
                    .font(.trainBodyMedium)
                    .foregroundColor(.trainTextPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                // Subtitle showing muscle + equipment
                HStack(spacing: Spacing.xs) {
                    Text(exercise.primaryMuscle)
                        .font(.trainCaption)
                        .foregroundColor(.trainPrimary)

                    Text("\u{2022}")
                        .foregroundColor(.trainTextSecondary)

                    Text(exercise.equipmentCategory)
                        .font(.trainCaption)
                        .foregroundColor(.trainTextSecondary)

                    if let attachment = exercise.attachmentSpecific, !attachment.isEmpty {
                        Text("\u{2022}")
                            .foregroundColor(.trainTextSecondary)
                        Text(attachment)
                            .font(.trainCaption)
                            .foregroundColor(.trainTextSecondary)
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.trainCaption)
                .foregroundColor(.trainTextSecondary)
        }
        .padding(Spacing.md)
        .appCard()
        .cornerRadius(CornerRadius.md)
    }

    private var thumbnailPlaceholder: some View {
        RoundedRectangle(cornerRadius: CornerRadius.xs, style: .continuous)
            .fill(Color.trainTextSecondary.opacity(0.2))
            .frame(width: 80, height: 64)
            .overlay {
                Image(systemName: "photo")
                    .font(.system(size: IconSize.md))
                    .foregroundColor(.trainTextSecondary.opacity(0.5))
            }
    }
}

// MARK: - Filter Sheet

struct FilterSheet: View {
    @Environment(\.dismiss) var dismiss
    let title: String
    let options: [String]
    @Binding var selected: Set<String>
    let onApply: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                    VStack(spacing: Spacing.sm) {
                        ForEach(options, id: \.self) { option in
                            Button(action: {
                                if selected.contains(option) {
                                    selected.remove(option)
                                } else {
                                    selected.insert(option)
                                }
                            }) {
                                HStack {
                                    Text(option)
                                        .font(.trainBody)
                                        .foregroundColor(.trainTextPrimary)

                                    Spacer()

                                    if selected.contains(option) {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.trainPrimary)
                                    }
                                }
                                .padding(Spacing.md)
                                .appCard()
                                .cornerRadius(CornerRadius.sm)
                                .overlay(
                                    RoundedRectangle(cornerRadius: CornerRadius.sm)
                                        .stroke(selected.contains(option) ? Color.trainPrimary : Color.clear, lineWidth: selected.contains(option) ? 2 : 1)
                                )
                            }
                        }
                    }
                    .padding(Spacing.lg)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Clear") {
                        selected.removeAll()
                    }
                    .foregroundColor(.trainTextSecondary)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        onApply()
                        dismiss()
                    }
                    .foregroundColor(.trainPrimary)
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ExerciseLibraryView()
    }
}
