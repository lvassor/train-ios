//
//  ExerciseDetailView.swift
//  trAInSwift
//
//  Exercise detail with Demo and Logger tabs
//

import SwiftUI

struct ExerciseDetailView: View {
    @Environment(\.dismiss) var dismiss
    let exercise: DBExercise
    let showLoggerTab: Bool
    @State private var selectedTab: ExerciseDetailTab = .demo

    enum ExerciseDetailTab {
        case logger, demo
    }

    init(exercise: DBExercise, showLoggerTab: Bool = true) {
        self.exercise = exercise
        self.showLoggerTab = showLoggerTab
        _selectedTab = State(initialValue: showLoggerTab ? .demo : .demo)
    }

    var body: some View {
        VStack(spacing: 0) {
                // Tab toggle - matches CombinedLibraryView toolbar style
                if showLoggerTab {
                    HStack(spacing: 4) {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedTab = .logger
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "list.bullet.clipboard")
                                    .font(.system(size: 14))
                                    .foregroundColor(selectedTab == .logger ? .trainPrimary : .trainTextSecondary)
                                Text("Logger")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(selectedTab == .logger ? .trainTextPrimary : .trainTextSecondary)
                            }
                            .padding(.horizontal, Spacing.md)
                            .padding(.vertical, 10)
                            .background(selectedTab == .logger ? Color.trainPrimary.opacity(0.15) : Color.clear)
                            .clipShape(Capsule())
                        }

                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedTab = .demo
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "play.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(selectedTab == .demo ? .trainPrimary : .trainTextSecondary)
                                Text("Demo")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(selectedTab == .demo ? .trainTextPrimary : .trainTextSecondary)
                            }
                            .padding(.horizontal, Spacing.md)
                            .padding(.vertical, 10)
                            .background(selectedTab == .demo ? Color.trainPrimary.opacity(0.15) : Color.clear)
                            .clipShape(Capsule())
                        }
                    }
                    .padding(4)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Capsule())
                    .padding(.horizontal, Spacing.lg)
                    .padding(.top, Spacing.md)
                }

                // Content
                if selectedTab == .demo || !showLoggerTab {
                    ExerciseDemoTab(exercise: exercise)
                } else {
                    ExerciseLoggerTab(exercise: exercise)
                }
        }
        .warmDarkGradientBackground()
        .scrollContentBackground(.hidden)
        .navigationTitle(exercise.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Demo Tab

struct ExerciseDemoTab: View {
    let exercise: DBExercise

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Video placeholder
                ZStack {
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.trainTextSecondary.opacity(0.1))
                        .frame(height: 220)

                    VStack(spacing: Spacing.md) {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.trainPrimary)

                        Text("Video coming soon")
                            .font(.trainCaption)
                            .foregroundColor(.trainTextSecondary)
                    }
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.md)

                // Equipment section
                VStack(spacing: Spacing.md) {
                    Text("Equipment")
                        .font(.trainTitle)
                        .foregroundColor(.trainTextPrimary)

                    HStack(spacing: Spacing.md) {
                        ForEach([exercise.equipmentType], id: \.self) { equipment in
                            VStack(spacing: Spacing.sm) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.clear)
                                        .appCard()
                                        .frame(width: 80, height: 80)

                                    Image(systemName: equipmentIcon(for: equipment))
                                        .font(.system(size: 32))
                                        .foregroundColor(.trainPrimary)
                                }

                                Text(equipment)
                                    .font(.trainCaption)
                                    .foregroundColor(.trainTextSecondary)
                            }
                        }
                    }
                }

                // Active Muscle Groups
                VStack(spacing: Spacing.md) {
                    Text("Active Muscle Groups")
                        .font(.trainTitle)
                        .foregroundColor(.trainTextPrimary)

                    HStack(spacing: Spacing.md) {
                        ForEach([exercise.primaryMuscle] + (exercise.secondaryMuscle.map { [$0] } ?? []), id: \.self) { muscle in
                            VStack(spacing: Spacing.sm) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.trainPrimary.opacity(0.1))
                                        .frame(width: 80, height: 80)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.trainPrimary.opacity(0.3), lineWidth: 1)
                                        )

                                    Image(systemName: muscleIcon(for: muscle))
                                        .font(.system(size: 32))
                                        .foregroundColor(.trainPrimary)
                                }

                                Text(muscle)
                                    .font(.trainCaption)
                                    .foregroundColor(.trainTextSecondary)
                            }
                        }
                    }
                }

                // Instructions
                if let instructions = exercise.instructions, !instructions.isEmpty {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Text("Instructions")
                            .font(.trainTitle)
                            .foregroundColor(.trainTextPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            let steps = instructions.split(separator: "\n")
                            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                                HStack(alignment: .top, spacing: Spacing.sm) {
                                    Text("\(index + 1).")
                                        .font(.trainBodyMedium)
                                        .foregroundColor(.trainPrimary)

                                    Text(String(step))
                                        .font(.trainBody)
                                        .foregroundColor(.trainTextPrimary)
                                }
                            }
                        }
                        .padding(Spacing.md)
                        .appCard()
                        .cornerRadius(15)
                    }
                    .padding(.horizontal, Spacing.lg)
                } else {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Text("Instructions")
                            .font(.trainTitle)
                            .foregroundColor(.trainTextPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text("Instructions coming soon")
                            .font(.trainBody)
                            .foregroundColor(.trainTextSecondary)
                            .padding(Spacing.lg)
                            .frame(maxWidth: .infinity)
                            .appCard()
                            .cornerRadius(15)
                    }
                    .padding(.horizontal, Spacing.lg)
                }

                // View Exercise History button
                NavigationLink(destination: ExerciseHistoryView(exercise: exercise)) {
                    Text("View Exercise History")
                        .font(.trainBodyMedium)
                        .foregroundColor(.trainPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.md)
                        .appCard()
                        .cornerRadius(15)
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(Color.trainPrimary, lineWidth: 2)
                        )
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.lg)
            }
        }
    }

    private func equipmentIcon(for equipment: String) -> String {
        switch equipment.lowercased() {
        case "barbell": return "figure.strengthtraining.traditional"
        case "dumbbell": return "dumbbell.fill"
        case "cable": return "cable.connector"
        case "machine": return "gearshape.2.fill"
        case "kettlebell": return "figure.strengthtraining.functional"
        case "bodyweight": return "figure.walk"
        default: return "figure.strengthtraining.traditional"
        }
    }

    private func muscleIcon(for muscle: String) -> String {
        switch muscle.lowercased() {
        case "chest": return "heart.fill"
        case "back": return "arrow.left.arrow.right"
        case "shoulders": return "arrow.up"
        case "arms", "biceps", "triceps": return "bolt.fill"
        case "legs", "quads", "hamstrings": return "figure.walk"
        case "core", "abs": return "circle.grid.cross.fill"
        default: return "figure.strengthtraining.traditional"
        }
    }
}

// MARK: - Logger Tab

struct ExerciseLoggerTab: View {
    let exercise: DBExercise
    @State private var sets: [ExerciseSet] = []
    @State private var useKg: Bool = true

    struct ExerciseSet: Identifiable {
        let id = UUID()
        var weight: String = ""
        var reps: String = ""
        var isCompleted: Bool = false
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Exercise info card
                HStack(spacing: Spacing.md) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.trainPrimary.opacity(0.1))
                            .frame(width: 80, height: 80)

                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.system(size: 32))
                            .foregroundColor(.trainPrimary)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(exercise.displayName)
                            .font(.trainBodyMedium)
                            .foregroundColor(.trainTextPrimary)

                        Text("\(sets.filter { $0.isCompleted }.count) sets completed")
                            .font(.trainCaption)
                            .foregroundColor(.trainTextSecondary)
                    }

                    Spacer()
                }
                .padding(Spacing.md)
                .background(Color.trainPrimary.opacity(0.05))
                .cornerRadius(15)
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.md)

                // Unit toggle
                HStack {
                    Spacer()

                    HStack(spacing: 0) {
                        Button(action: { useKg = true }) {
                            Text("kg")
                                .font(.trainBody)
                                .foregroundColor(useKg ? .white : .trainTextPrimary)
                                .padding(.horizontal, Spacing.md)
                                .padding(.vertical, Spacing.sm)
                                .background(useKg ? Color.trainPrimary : Color.clear)
                                .cornerRadius(20, corners: [.topLeft, .bottomLeft])
                        }

                        Button(action: { useKg = false }) {
                            Text("lbs")
                                .font(.trainBody)
                                .foregroundColor(!useKg ? .white : .trainTextPrimary)
                                .padding(.horizontal, Spacing.md)
                                .padding(.vertical, Spacing.sm)
                                .background(!useKg ? Color.trainPrimary : Color.clear)
                                .cornerRadius(20, corners: [.topRight, .bottomRight])
                        }
                    }
                    .background(Color.trainTextSecondary.opacity(0.1))
                    .cornerRadius(20)
                }
                .padding(.horizontal, Spacing.lg)

                // Set tracker
                VStack(spacing: Spacing.sm) {
                    ForEach(Array(sets.enumerated()), id: \.element.id) { index, set in
                        HStack(spacing: Spacing.md) {
                            Text("\(index + 1)")
                                .font(.trainBodyMedium)
                                .foregroundColor(.trainTextPrimary)
                                .frame(width: 30)

                            TextField("kg", text: Binding(
                                get: { sets[index].weight },
                                set: { sets[index].weight = $0 }
                            ))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.center)
                            .padding(Spacing.sm)
                            .frame(width: 80)
                            .appCard()
                            .cornerRadius(10)

                            TextField("reps", text: Binding(
                                get: { sets[index].reps },
                                set: { sets[index].reps = $0 }
                            ))
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                            .padding(Spacing.sm)
                            .frame(width: 80)
                            .appCard()
                            .cornerRadius(10)

                            Button(action: {
                                sets[index].isCompleted.toggle()
                            }) {
                                Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 24))
                                    .foregroundColor(set.isCompleted ? .green : .trainTextSecondary)
                            }
                        }
                    }
                }
                .padding(.horizontal, Spacing.lg)

                // Add set button
                Button(action: addSet) {
                    Text("Add Set")
                        .font(.trainBodyMedium)
                        .foregroundColor(.trainPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.md)
                        .appCard()
                        .cornerRadius(15)
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(Color.trainPrimary, lineWidth: 2)
                                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [5]))
                        )
                }
                .padding(.horizontal, Spacing.lg)

                Spacer()
                    .frame(height: 40)

                // Submit button
                Button(action: submitExercise) {
                    Text("Submit Exercise")
                        .font(.trainBodyMedium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.md)
                        .background(Color.trainPrimary)
                        .cornerRadius(30)
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.lg)
            }
        }
        .onAppear {
            if sets.isEmpty {
                sets = [ExerciseSet(), ExerciseSet(), ExerciseSet()]
            }
        }
    }

    private func addSet() {
        sets.append(ExerciseSet())
    }

    private func submitExercise() {
        // Save exercise log
        print("✅ Exercise logged: \(exercise.displayName)")
        print("   Sets: \(sets.filter { $0.isCompleted }.count)")
    }
}

#Preview {
    // Using a mock exercise for preview via JSON decoding
    let mockExercise = try! JSONDecoder().decode(DBExercise.self, from: """
    {
        "exercise_id": 1,
        "canonical_name": "barbell_bench_press",
        "display_name": "Barbell Bench Press",
        "movement_pattern": "horizontal_push",
        "equipment_type": "Barbell",
        "complexity_level": 3,
        "primary_muscle": "Chest",
        "secondary_muscle": "Triceps",
        "instructions": "Lie on bench\\nGrip barbell\\nLower to chest\\nPress up",
        "is_active": 1
    }
    """.data(using: .utf8)!)

    return NavigationStack {
        ExerciseDetailView(exercise: mockExercise)
    }
}
