//
//  CombinedLibraryView.swift
//  trAInSwift
//
//  Combined Exercise and Video Library with toggle toolbar
//  Unified view for browsing exercises and demo videos
//

import SwiftUI

struct CombinedLibraryView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedTab: LibraryTab = .exercises
    @State private var showSearch: Bool = false
    @State private var searchText: String = ""

    enum LibraryTab: String, CaseIterable, Hashable {
        case exercises = "Exercises"
        case education = "Education"

        var icon: String {
            switch self {
            case .exercises: return "dumbbell.fill"
            case .education: return "book.fill"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
                // Toolbar area - switches between tabs and search
                if showSearch {
                    // Inline search bar (replaces toolbar)
                    HStack(spacing: Spacing.sm) {
                        // Search field
                        HStack(spacing: Spacing.sm) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 16))
                                .foregroundColor(.trainTextSecondary)

                            TextField("Search", text: $searchText)
                                .font(.system(size: 16))
                                .foregroundColor(.trainTextPrimary)
                                .autocorrectionDisabled()
                        }
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Capsule())

                        // Dismiss button
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showSearch = false
                                searchText = ""
                            }
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.trainTextSecondary)
                                .frame(width: 36, height: 36)
                                .background(Color.white.opacity(0.08))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.top, Spacing.md)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                } else {
                    // Compact toolbar with native segmented picker
                    HStack(spacing: Spacing.sm) {
                        // Search button
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showSearch = true
                            }
                        }) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.trainTextSecondary)
                                .frame(width: 40, height: 40)
                                .background(Color.white.opacity(0.08))
                                .clipShape(Circle())
                        }

                        // Tab picker with native segmented control
                        Picker("Library", selection: $selectedTab) {
                            ForEach(LibraryTab.allCases, id: \.self) { tab in
                                Label(tab.rawValue, systemImage: tab.icon)
                                    .tag(tab)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 200)
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.top, Spacing.md)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }

            // Content
            if selectedTab == .exercises {
                ExerciseLibraryContent(showSearch: showSearch, searchText: $searchText)
            } else {
                EducationLibraryContent()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
        .navigationTitle("Library")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Exercise Library Content (extracted from ExerciseLibraryView)

struct ExerciseLibraryContent: View {
    let showSearch: Bool
    @Binding var searchText: String
    @State private var exercises: [DBExercise] = []
    @State private var filteredExercises: [DBExercise] = []
    @State private var showMuscleFilter: Bool = false
    @State private var showEquipmentFilter: Bool = false
    @State private var selectedMuscles: Set<String> = []
    @State private var selectedEquipment: Set<String> = []
    @State private var isLoading: Bool = true

    let muscleGroups = ["Chest", "Back", "Shoulders", "Biceps", "Triceps", "Quads", "Hamstrings", "Glutes", "Calves", "Core"]
    let equipmentTypes = ["Barbells", "Dumbbells", "Cables", "Kettlebells", "Pin-Loaded Machines", "Plate-Loaded Machines", "Other"]

    var body: some View {
        VStack(spacing: 0) {
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
            .padding(.top, Spacing.md)

            // Exercise list
            if isLoading {
                Spacer()
                ProgressView()
                    .tint(.trainPrimary)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: Spacing.md) {
                        ForEach(filteredExercises) { exercise in
                            NavigationLink(destination: ExerciseDetailView(exercise: exercise, showLoggerTab: false)) {
                                ExerciseRowCard(exercise: exercise)
                            }
                        }
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.top, Spacing.md)
                    .padding(.bottom, 100)
                }
            }
        }
        .onAppear { loadExercises() }
        .onChange(of: searchText) { _, _ in
            applyFilters()
        }
        .sheet(isPresented: $showMuscleFilter) {
            LibraryFilterSheet(
                title: "Muscle Groups",
                options: muscleGroups,
                selected: $selectedMuscles,
                onApply: { applyFilters() }
            )
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showEquipmentFilter) {
            LibraryFilterSheet(
                title: "Equipment",
                options: equipmentTypes,
                selected: $selectedEquipment,
                onApply: { applyFilters() }
            )
            .presentationDetents([.medium])
        }
    }

    private func loadExercises() {
        Task {
            do {
                let filter = ExerciseDatabaseFilter()
                let allExercises = try ExerciseDatabaseManager.shared.fetchExercises(filter: filter)
                await MainActor.run {
                    exercises = allExercises
                    filteredExercises = allExercises
                    isLoading = false
                }
            } catch {
                print("Error loading exercises: \(error)")
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }

    private func applyFilters() {
        filteredExercises = exercises.filter { exercise in
            let matchesSearch = searchText.isEmpty ||
                exercise.displayName.localizedCaseInsensitiveContains(searchText) ||
                exercise.primaryMuscle.localizedCaseInsensitiveContains(searchText)

            let matchesMuscle = selectedMuscles.isEmpty ||
                selectedMuscles.contains(exercise.primaryMuscle)

            let matchesEquipment = selectedEquipment.isEmpty ||
                selectedEquipment.contains(exercise.equipmentType)

            return matchesSearch && matchesMuscle && matchesEquipment
        }
    }
}

// MARK: - Education Library Content

struct EducationLibraryContent: View {
    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            // Book icon
            ZStack {
                Circle()
                    .fill(Color.trainPrimary.opacity(0.1))
                    .frame(width: 120, height: 120)

                Image(systemName: "book.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.trainPrimary)
            }

            // Text content
            VStack(spacing: Spacing.md) {
                Text("Coming Soon")
                    .font(.trainTitle)
                    .foregroundColor(.trainTextPrimary)

                Text("Access workout tutorials, form guides, and training tips here")
                    .font(.trainBody)
                    .foregroundColor(.trainTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xl)
            }

            Spacer()
        }
    }
}

// MARK: - Exercise Row Card

struct ExerciseRowCard: View {
    let exercise: DBExercise

    var body: some View {
        HStack(spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.displayName)
                    .font(.trainBodyMedium)
                    .foregroundColor(.trainTextPrimary)
                    .lineLimit(1)

                HStack(spacing: Spacing.sm) {
                    Text(exercise.primaryMuscle)
                        .font(.trainCaption)
                        .foregroundColor(.trainPrimary)

                    Text("•")
                        .foregroundColor(.trainTextSecondary)

                    Text(exercise.equipmentType)
                        .font(.trainCaption)
                        .foregroundColor(.trainTextSecondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(.trainTextSecondary)
        }
        .padding(Spacing.md)
        .appCard()
    }
}

// MARK: - Filter Sheet

struct LibraryFilterSheet: View {
    let title: String
    let options: [String]
    @Binding var selected: Set<String>
    let onApply: () -> Void
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            List {
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
                                .foregroundColor(.trainTextPrimary)

                            Spacer()

                            if selected.contains(option) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.trainPrimary)
                            }
                        }
                    }
                }
            }
            .listStyle(.plain)
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
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        CombinedLibraryView()
    }
}
