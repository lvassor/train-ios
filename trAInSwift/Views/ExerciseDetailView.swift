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
        case logger, demo, history
    }

    init(exercise: DBExercise, showLoggerTab: Bool = true) {
        self.exercise = exercise
        self.showLoggerTab = showLoggerTab
        _selectedTab = State(initialValue: showLoggerTab ? .demo : .demo)
    }

    var body: some View {
        VStack(spacing: 0) {
                // Tab toggle - matches CombinedLibraryView toolbar style
                HStack(spacing: 4) {
                    if showLoggerTab {
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

                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = .history
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "chart.xyaxis.line")
                                .font(.system(size: 14))
                                .foregroundColor(selectedTab == .history ? .trainPrimary : .trainTextSecondary)
                            Text("History")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(selectedTab == .history ? .trainTextPrimary : .trainTextSecondary)
                        }
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, 10)
                        .background(selectedTab == .history ? Color.trainPrimary.opacity(0.15) : Color.clear)
                        .clipShape(Capsule())
                    }
                }
                .padding(4)
                .background(Color.white.opacity(0.08))
                .clipShape(Capsule())
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.md)

                // Content
                if selectedTab == .demo {
                    ExerciseDemoTab(exercise: exercise)
                } else if selectedTab == .logger {
                    ExerciseLoggerTab(exercise: exercise)
                } else {
                    ExerciseHistoryView(exercise: exercise)
                }
        }
        .background {
            // Use gradient background only when showing logger (workout context)
            // Library context uses ultrathin material parent, so no gradient needed
            if showLoggerTab {
                AppGradient.background
                    .ignoresSafeArea()
            }
        }
        .scrollContentBackground(.hidden)
        .navigationTitle(exercise.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Demo Tab
// ExerciseDemoTab is defined in ExerciseLoggerView.swift

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
