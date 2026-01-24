//
//  ExerciseLibraryView.swift
//  trAInSwift
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
                .cornerRadius(10)
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.md)

                // Filter buttons
                HStack(spacing: Spacing.sm) {
                    Text("Filter:")
                        .font(.trainBodyMedium)
                        .foregroundColor(.trainTextPrimary)
                        .fixedSize()

                    Button(action: { showMuscleFilter = true }) {
                        HStack(spacing: 4) {
                            Text("Muscle")
                                .font(.trainBody)
                            if !selectedMuscles.isEmpty {
                                Text("(\(selectedMuscles.count))")
                                    .font(.trainCaption)
                            }
                            Image(systemName: "chevron.down")
                                .font(.system(size: 10))
                        }
                        .foregroundColor(selectedMuscles.isEmpty ? .trainTextPrimary : .trainPrimary)
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.sm)
                        .background(selectedMuscles.isEmpty ? Color.clear : Color.trainPrimary.opacity(0.1))
                        .appCard()
                        .cornerRadius(10)
                    }
                    .fixedSize()

                    Button(action: { showEquipmentFilter = true }) {
                        HStack(spacing: 4) {
                            Text("Equipment")
                                .font(.trainBody)
                            if !selectedEquipment.isEmpty {
                                Text("(\(selectedEquipment.count))")
                                    .font(.trainCaption)
                            }
                            Image(systemName: "chevron.down")
                                .font(.system(size: 10))
                        }
                        .foregroundColor(selectedEquipment.isEmpty ? .trainTextPrimary : .trainPrimary)
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.sm)
                        .background(selectedEquipment.isEmpty ? Color.clear : Color.trainPrimary.opacity(0.1))
                        .appCard()
                        .cornerRadius(10)
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
                            .font(.system(size: 48))
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

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let dbManager = ExerciseDatabaseManager.shared
                let filter = ExerciseDatabaseFilter()
                let allExercises = try dbManager.fetchExercises(filter: filter)

                DispatchQueue.main.async {
                    self.exercises = allExercises
                    self.filteredExercises = allExercises
                    self.isLoading = false
                }
            } catch {
                print("❌ Error loading exercises: \(error)")
                DispatchQueue.main.async {
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
            // Thumbnail placeholder
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.trainPrimary.opacity(0.1))
                    .frame(width: 80, height: 80)

                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 32))
                    .foregroundColor(.trainPrimary)
            }

            // Exercise info
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.displayName)
                    .font(.trainBodyMedium)
                    .foregroundColor(.trainTextPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 6) {
                    // Muscle tag
                    Text(exercise.primaryMuscle)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.trainPrimary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.trainPrimary.opacity(0.1))
                        .cornerRadius(20)

                    // Equipment tag
                    Text(exercise.equipmentType)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.trainTextSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.trainTextSecondary.opacity(0.1))
                        .cornerRadius(20)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(.trainTextSecondary)
        }
        .padding(Spacing.md)
        .appCard()
        .cornerRadius(15)
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
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
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
