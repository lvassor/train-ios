//
//  SessionOverviewView.swift
//  trAInApp
//
//  Created by Claude Code on 2025-10-06.
//

import SwiftUI

struct SessionOverviewView: View {
    @EnvironmentObject var viewModel: WorkoutViewModel
    @Environment(\.dismiss) var dismiss
    let weekNumber: Int
    let sessionKey: String

    @State private var selectedExerciseIndex: Int?
    @State private var showingCompletionAlert = false

    var session: Session? {
        viewModel.currentProgramme?.days[sessionKey]
    }

    var allExercisesCompleted: Bool {
        guard let sessionLog = viewModel.currentSessionLog else { return false }
        return sessionLog.exercises.allSatisfy { $0.completed }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    if let session = session {
                        Text(session.name)
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Week \(weekNumber)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 20)

                // Smart Summary
                VStack(alignment: .leading, spacing: 8) {
                    Text("Today's Focus")
                        .font(.headline)

                    if let session = session {
                        Text("Complete \(session.exercises.count) exercises targeting \(getTargetMuscles(session.exercises))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(hex: "ABCF78").opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)

                // Warm-up section
                WarmupSection()
                    .padding(.horizontal)

                // Exercise bubbles
                VStack(alignment: .leading, spacing: 12) {
                    Text("Exercises")
                        .font(.headline)
                        .padding(.horizontal)

                    if let session = session {
                        ForEach(Array(session.exercises.enumerated()), id: \.element.id) { index, exercise in
                            ExerciseBubble(
                                exercise: exercise,
                                isCompleted: viewModel.currentSessionLog?.exercises[index].completed ?? false,
                                onTap: {
                                    selectedExerciseIndex = index
                                }
                            )
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
        .navigationDestination(item: $selectedExerciseIndex) { index in
            if let session = session {
                ExerciseDetailView(
                    exerciseIndex: index,
                    exercise: session.exercises[index]
                )
                .environmentObject(viewModel)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if allExercisesCompleted {
                    Button("Complete Workout") {
                        showingCompletionAlert = true
                    }
                    .foregroundColor(Color(hex: "3C825E"))
                    .fontWeight(.semibold)
                }
            }
        }
        .alert("Complete Workout?", isPresented: $showingCompletionAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Yes") {
                viewModel.completeSession()
                dismiss()
            }
        } message: {
            Text("All exercises complete. Mark this workout as done?")
        }
        .onAppear {
            if viewModel.currentSessionLog == nil {
                viewModel.startSession(weekNumber: weekNumber, sessionKey: sessionKey)
            }
        }
    }

    private func getTargetMuscles(_ exercises: [Exercise]) -> String {
        let targets = Set(exercises.map { $0.target })
        return targets.prefix(3).joined(separator: ", ")
    }
}

struct ExerciseBubble: View {
    let exercise: Exercise
    let isCompleted: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Icon
                Text(exercise.icon)
                    .font(.title)

                // Exercise info
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name)
                        .font(.headline)
                        .foregroundColor(.primary)

                    HStack(spacing: 12) {
                        Label("\(exercise.sets) sets", systemImage: "number")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Label("\(exercise.repsMin)-\(exercise.repsMax) reps", systemImage: "repeat")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Completion indicator
                if isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color(hex: "3C825E"))
                        .font(.title2)
                } else {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isCompleted ? Color(hex: "ABCF78").opacity(0.2) : Color.white)
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isCompleted ? Color(hex: "3C825E") : Color.clear, lineWidth: 2)
            )
        }
    }
}

struct WarmupSection: View {
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: {
                withAnimation {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text("Warm-up")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                }
            }

            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    WarmupItem(text: "5 minutes light cardio")
                    WarmupItem(text: "Dynamic stretching")
                    WarmupItem(text: "Light warm-up sets for first exercise")
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct WarmupItem: View {
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "circle.fill")
                .font(.system(size: 6))
                .foregroundColor(.secondary)

            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}
