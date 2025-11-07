//
//  ExerciseDetailView.swift
//  trAInApp
//
//  Created by Claude Code on 2025-10-06.
//

import SwiftUI

struct ExerciseDetailView: View {
    @EnvironmentObject var viewModel: WorkoutViewModel
    @Environment(\.dismiss) var dismiss
    let exerciseIndex: Int
    let exercise: Exercise

    @State private var selectedTab = 0
    @State private var showingTimer = false
    @State private var activeSetIndex: Int?
    @State private var showingCompletionModal = false
    @State private var completionFeedback: PromptFeedback?

    var exerciseLog: ExerciseLog? {
        viewModel.currentSessionLog?.exercises[exerciseIndex]
    }

    var allSetsCompleted: Bool {
        guard let log = exerciseLog else { return false }
        return log.sets.allSatisfy { $0.completed }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Tab selector
            Picker("Tab", selection: $selectedTab) {
                Text("Logger").tag(0)
                Text("Demo").tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()

            // Tab content
            TabView(selection: $selectedTab) {
                LoggerTab(
                    exercise: exercise,
                    exerciseIndex: exerciseIndex,
                    exerciseLog: exerciseLog,
                    showingTimer: $showingTimer,
                    activeSetIndex: $activeSetIndex,
                    onSetCompleted: handleSetCompleted,
                    onNotesChanged: handleNotesChanged
                )
                .tag(0)

                DemoTab(exercise: exercise)
                    .tag(1)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 2) {
                    Text(exercise.name)
                        .font(.headline)
                    Text(exercise.target)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                if allSetsCompleted {
                    Button("Complete") {
                        handleCompleteExercise()
                    }
                    .foregroundColor(Color(hex: "3C825E"))
                    .fontWeight(.semibold)
                }
            }
        }
        .overlay {
            if showingTimer, let setIndex = activeSetIndex {
                CircularTimerView(duration: 60, isShowing: $showingTimer)
            }
        }
        .overlay {
            if showingCompletionModal, let feedback = completionFeedback {
                CompletionModal(
                    feedback: feedback,
                    onHide: {
                        showingCompletionModal = false
                    },
                    onComplete: {
                        showingCompletionModal = false
                        dismiss()
                    }
                )
            }
        }
    }

    private func handleSetCompleted(setIndex: Int) {
        viewModel.markSetCompleted(exerciseIndex: exerciseIndex, setIndex: setIndex)
        activeSetIndex = setIndex
        showingTimer = true
    }

    private func handleNotesChanged(notes: String) {
        viewModel.updateExerciseNotes(exerciseIndex: exerciseIndex, notes: notes)
    }

    private func handleCompleteExercise() {
        if let feedback = viewModel.completeExercise(exerciseIndex: exerciseIndex) {
            completionFeedback = feedback
            showingCompletionModal = true
        } else {
            dismiss()
        }
    }
}

struct LoggerTab: View {
    @EnvironmentObject var viewModel: WorkoutViewModel
    let exercise: Exercise
    let exerciseIndex: Int
    let exerciseLog: ExerciseLog?
    @Binding var showingTimer: Bool
    @Binding var activeSetIndex: Int?
    let onSetCompleted: (Int) -> Void
    let onNotesChanged: (String) -> Void

    @State private var notes: String = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Target info
                VStack(alignment: .center, spacing: 8) {
                    Text("Target: \(exercise.sets) sets × \(exercise.repsMin)-\(exercise.repsMax) reps")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
                .padding()
                .background(Color(hex: "ABCF78").opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
                .padding(.top)

                // Sets tracker
                VStack(alignment: .leading, spacing: 12) {
                    Text("Sets")
                        .font(.headline)
                        .padding(.horizontal)

                    VStack(spacing: 8) {
                        ForEach(0..<exercise.sets, id: \.self) { setIndex in
                            SetRow(
                                setNumber: setIndex + 1,
                                setLog: exerciseLog?.sets[setIndex],
                                onWeightChanged: { weight in
                                    handleWeightChanged(setIndex: setIndex, weight: weight)
                                },
                                onRepsChanged: { reps in
                                    handleRepsChanged(setIndex: setIndex, reps: reps)
                                },
                                onCompleted: {
                                    onSetCompleted(setIndex)
                                }
                            )
                            .padding(.horizontal)
                        }
                    }
                }

                // Notes section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notes")
                        .font(.headline)
                        .padding(.horizontal)

                    TextEditor(text: $notes)
                        .frame(height: 100)
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal)
                        .onChange(of: notes) { oldValue, newValue in
                            onNotesChanged(newValue)
                        }
                }
                .padding(.top, 8)
            }
        }
        .onAppear {
            notes = exerciseLog?.notes ?? ""
        }
    }

    private func handleWeightChanged(setIndex: Int, weight: Double) {
        let reps = exerciseLog?.sets[setIndex].reps ?? 0
        viewModel.updateSet(exerciseIndex: exerciseIndex, setIndex: setIndex, weight: weight, reps: reps)
    }

    private func handleRepsChanged(setIndex: Int, reps: Int) {
        let weight = exerciseLog?.sets[setIndex].weight ?? 0
        viewModel.updateSet(exerciseIndex: exerciseIndex, setIndex: setIndex, weight: weight, reps: reps)
    }
}

struct SetRow: View {
    let setNumber: Int
    let setLog: SetLog?
    let onWeightChanged: (Double) -> Void
    let onRepsChanged: (Int) -> Void
    let onCompleted: () -> Void

    @State private var weightText: String = ""
    @State private var repsText: String = ""
    @State private var isCompleted: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            // Set number
            Text("\(setNumber)")
                .font(.headline)
                .foregroundColor(.secondary)
                .frame(width: 30)

            // Weight input
            VStack(alignment: .leading, spacing: 4) {
                Text("Weight (lbs)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                TextField("0", text: $weightText)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onChange(of: weightText) { oldValue, newValue in
                        if let weight = Double(newValue) {
                            onWeightChanged(weight)
                        }
                    }
            }

            // Reps input
            VStack(alignment: .leading, spacing: 4) {
                Text("Reps")
                    .font(.caption)
                    .foregroundColor(.secondary)

                TextField("0", text: $repsText)
                    .keyboardType(.numberPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onChange(of: repsText) { oldValue, newValue in
                        if let reps = Int(newValue) {
                            onRepsChanged(reps)
                        }
                    }
            }

            // Completion checkbox
            Button(action: {
                if !isCompleted && !weightText.isEmpty && !repsText.isEmpty {
                    isCompleted = true
                    onCompleted()
                }
            }) {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isCompleted ? Color(hex: "3C825E") : .secondary)
            }
        }
        .padding()
        .background(isCompleted ? Color(hex: "ABCF78").opacity(0.1) : Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .onAppear {
            if let setLog = setLog {
                weightText = setLog.weight > 0 ? String(format: "%.1f", setLog.weight) : ""
                repsText = setLog.reps > 0 ? "\(setLog.reps)" : ""
                isCompleted = setLog.completed
            }
        }
    }
}

struct DemoTab: View {
    let exercise: Exercise

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Video placeholder
                ZStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .aspectRatio(16/9, contentMode: .fit)
                        .cornerRadius(12)

                    VStack(spacing: 12) {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.white)

                        Text("Video Coming Soon")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                }
                .padding()

                // Exercise instructions
                VStack(alignment: .leading, spacing: 12) {
                    Text("How to perform \(exercise.name)")
                        .font(.headline)

                    Text("Proper form and technique instructions will be available here. Focus on controlled movements and maintaining good posture throughout the exercise.")
                        .font(.body)
                        .foregroundColor(.secondary)

                    Divider()

                    Text("Tips:")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    VStack(alignment: .leading, spacing: 8) {
                        TipItem(text: "Maintain proper form throughout")
                        TipItem(text: "Control the weight on both the concentric and eccentric portions")
                        TipItem(text: "Breathe consistently - exhale on exertion")
                        TipItem(text: "Use a full range of motion")
                    }
                }
                .padding()
            }
        }
    }
}

struct TipItem: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "lightbulb.fill")
                .font(.caption)
                .foregroundColor(Color(hex: "ABCF78"))

            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}
