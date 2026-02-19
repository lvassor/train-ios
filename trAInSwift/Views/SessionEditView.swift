//
//  SessionEditView.swift
//  trAInSwift
//
//  Session editing view allowing users to modify exercises, sets, and reps
//  Per Figma redesign specs
//

import SwiftUI

struct SessionEditView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var authService = AuthService.shared

    let sessionIndex: Int
    @Binding var sessionExercises: [ProgramExercise]

    @State private var editingExercises: [ProgramExercise] = []
    @State private var hasChanges = false
    @State private var exerciseToSwap: ProgramExercise? = nil
    @State private var showDiscardConfirmation = false
    @State private var showExercisePicker = false
    @State private var hasAddedExercise = false

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Header
                SessionEditHeader(
                    onCancel: {
                        if hasChanges {
                            showDiscardConfirmation = true
                        } else {
                            dismiss()
                        }
                    },
                    onSave: saveChanges
                )

                ScrollView {
                    VStack(spacing: 16) {
                        // Section header
                        HStack {
                            Text("Exercises")
                                .font(.system(size: 14, weight: .light))
                                .foregroundColor(.trainTextSecondary)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)

                        // Exercise list
                        VStack(spacing: 12) {
                            ForEach(Array(editingExercises.enumerated()), id: \.element.id) { index, exercise in
                                EditableExerciseCard(
                                    exercise: $editingExercises[index],
                                    exerciseNumber: index + 1,
                                    onSwap: {
                                        exerciseToSwap = exercise
                                    },
                                    onDelete: {
                                        deleteExercise(at: index)
                                    },
                                    onChange: {
                                        hasChanges = true
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 20)

                        // Add exercise button (limited to 1 addition per session)
                        Button(action: {
                            showExercisePicker = true
                        }) {
                            HStack {
                                Image(systemName: "plus")
                                    .font(.system(size: 16))
                                Text("Add Exercise")
                                    .font(.system(size: 16, weight: .medium))
                            }
                            .foregroundColor(hasAddedExercise ? .trainTextSecondary : .trainPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(hasAddedExercise ? Color.trainDisabled.opacity(0.3) : Color.trainPrimary.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .disabled(hasAddedExercise)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)
                    }
                }
            }
            .charcoalGradientBackground()

            // Exercise swap carousel
            if let exercise = exerciseToSwap {
                ExerciseSwapCarousel(
                    currentExercise: exercise,
                    onSelect: { newExercise in
                        if let index = editingExercises.firstIndex(where: { $0.id == exercise.id }) {
                            editingExercises[index] = newExercise
                            hasChanges = true
                        }
                        exerciseToSwap = nil
                    },
                    onDismiss: {
                        exerciseToSwap = nil
                    }
                )
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            editingExercises = sessionExercises
        }
        .confirmationDialog("Discard Changes", isPresented: $showDiscardConfirmation, titleVisibility: .visible) {
            Button("Discard Changes", role: .destructive) {
                dismiss()
            }
            Button("Keep Editing", role: .cancel) {}
        } message: {
            Text("You have unsaved changes. Are you sure you want to discard them?")
        }
        .sheet(isPresented: $showExercisePicker) {
            ExercisePickerView(
                sessionMuscleGroups: extractMuscleGroups(),
                existingExerciseIds: Set(editingExercises.map { $0.exerciseId }),
                onSelect: { newExercise in
                    // Insert at correct position based on complexity (compounds first)
                    let insertIndex = editingExercises.firstIndex(where: {
                        $0.complexityLevel < newExercise.complexityLevel
                    }) ?? editingExercises.endIndex
                    editingExercises.insert(newExercise, at: insertIndex)
                    hasAddedExercise = true
                    hasChanges = true
                }
            )
        }
    }

    /// Extract unique muscle groups from the session's exercises
    private func extractMuscleGroups() -> [String] {
        let muscles = Set(editingExercises.map { $0.primaryMuscle })
        return Array(muscles).sorted()
    }

    private func saveChanges() {
        sessionExercises = editingExercises
        dismiss()
    }

    private func deleteExercise(at index: Int) {
        editingExercises.remove(at: index)
        hasChanges = true
    }
}

// MARK: - Session Edit Header

struct SessionEditHeader: View {
    let onCancel: () -> Void
    let onSave: () -> Void

    var body: some View {
        HStack {
            // Cancel button
            Button(action: onCancel) {
                Text("Cancel")
                    .font(.system(size: 16, weight: .light))
                    .foregroundColor(.trainTextSecondary)
            }

            Spacer()

            // Title
            Text("Edit Session")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.trainTextPrimary)

            Spacer()

            // Save button
            Button(action: onSave) {
                Text("Save")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.trainPrimary)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
    }
}

// MARK: - Editable Exercise Card

struct EditableExerciseCard: View {
    @Binding var exercise: ProgramExercise
    let exerciseNumber: Int
    let onSwap: () -> Void
    let onDelete: () -> Void
    let onChange: () -> Void

    @State private var showSetsPicker = false
    @State private var showRepsPicker = false

    // Get video thumbnail URL
    private var thumbnailURL: URL? {
        guard let media = ExerciseMediaMapping.media(for: exercise.exerciseId),
              let guid = media.guid else { return nil }
        return BunnyConfig.videoThumbnailURL(for: guid)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Number indicator
            ZStack {
                Circle()
                    .fill(Color.trainSurface)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Circle()
                            .stroke(Color.trainTextSecondary.opacity(0.3), lineWidth: 1)
                    )

                Text("\(exerciseNumber)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.trainTextPrimary)
            }

            // Exercise card
            VStack(spacing: 0) {
                HStack(spacing: 16) {
                    // Thumbnail
                    if let url = thumbnailURL {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 80, height: 64)
                                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            default:
                                thumbnailPlaceholder
                            }
                        }
                    } else {
                        thumbnailPlaceholder
                    }

                    // Exercise info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(exercise.exerciseName)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.trainTextPrimary)
                            .lineLimit(2)

                        // Editable sets and reps
                        HStack(spacing: 12) {
                            // Sets button
                            Button(action: { showSetsPicker = true }) {
                                HStack(spacing: 4) {
                                    Text("\(exercise.sets) sets")
                                        .font(.system(size: 14, weight: .light))
                                        .foregroundColor(.trainTextSecondary)
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 10))
                                        .foregroundColor(.trainTextSecondary)
                                }
                            }

                            Text("•")
                                .font(.system(size: 14))
                                .foregroundColor(.trainTextSecondary)

                            // Reps button
                            Button(action: { showRepsPicker = true }) {
                                HStack(spacing: 4) {
                                    Text("\(exercise.repRange) reps")
                                        .font(.system(size: 14, weight: .light))
                                        .foregroundColor(.trainTextSecondary)
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 10))
                                        .foregroundColor(.trainTextSecondary)
                                }
                            }
                        }
                    }

                    Spacer()

                    // Action buttons
                    VStack(spacing: 8) {
                        Button(action: onSwap) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 16))
                                .foregroundColor(.trainTextSecondary)
                        }

                        Button(action: onDelete) {
                            Image(systemName: "trash")
                                .font(.system(size: 16))
                                .foregroundColor(.red.opacity(0.7))
                        }
                    }
                }
                .padding(16)
            }
            .background(Color.trainSurface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.1), radius: 0, x: 0, y: 1)
        }
        .sheet(isPresented: $showSetsPicker) {
            SetsPicker(selectedSets: Binding(
                get: { exercise.sets },
                set: {
                    exercise = ProgramExercise(
                        exerciseId: exercise.exerciseId,
                        exerciseName: exercise.exerciseName,
                        sets: $0,
                        repRange: exercise.repRange,
                        restSeconds: exercise.restSeconds,
                        primaryMuscle: exercise.primaryMuscle,
                        equipmentType: exercise.equipmentType,
                        complexityLevel: exercise.complexityLevel
                    )
                    onChange()
                }
            ))
            .presentationDetents([.height(250)])
        }
        .sheet(isPresented: $showRepsPicker) {
            RepsPicker(selectedRepRange: Binding(
                get: { exercise.repRange },
                set: {
                    exercise = ProgramExercise(
                        exerciseId: exercise.exerciseId,
                        exerciseName: exercise.exerciseName,
                        sets: exercise.sets,
                        repRange: $0,
                        restSeconds: exercise.restSeconds,
                        primaryMuscle: exercise.primaryMuscle,
                        equipmentType: exercise.equipmentType,
                        complexityLevel: exercise.complexityLevel
                    )
                    onChange()
                }
            ))
            .presentationDetents([.height(250)])
        }
    }

    private var thumbnailPlaceholder: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(Color.trainTextSecondary.opacity(0.2))
            .frame(width: 80, height: 64)
            .overlay {
                Image(systemName: "photo")
                    .font(.system(size: 20))
                    .foregroundColor(.trainTextSecondary.opacity(0.5))
            }
    }
}

// MARK: - Sets Picker

struct SetsPicker: View {
    @Binding var selectedSets: Int
    @Environment(\.dismiss) var dismiss

    let setOptions = [1, 2, 3, 4, 5, 6]

    var body: some View {
        VStack(spacing: 20) {
            Text("Number of Sets")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.trainTextPrimary)

            Picker("Sets", selection: $selectedSets) {
                ForEach(setOptions, id: \.self) { sets in
                    Text("\(sets)").tag(sets)
                }
            }
            .pickerStyle(.wheel)

            Button("Done") {
                dismiss()
            }
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.trainPrimary)
        }
        .padding()
    }
}

// MARK: - Reps Picker

struct RepsPicker: View {
    @Binding var selectedRepRange: String
    @Environment(\.dismiss) var dismiss

    let repOptions = ["3-5", "5-8", "6-8", "8-10", "8-12", "10-12", "12-15", "15-20"]

    var body: some View {
        VStack(spacing: 20) {
            Text("Rep Range")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.trainTextPrimary)

            Picker("Reps", selection: $selectedRepRange) {
                ForEach(repOptions, id: \.self) { range in
                    Text(range).tag(range)
                }
            }
            .pickerStyle(.wheel)

            Button("Done") {
                dismiss()
            }
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.trainPrimary)
        }
        .padding()
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var exercises = [
        ProgramExercise(
            exerciseId: "EX022",
            exerciseName: "Barbell Bench Press",
            sets: 4,
            repRange: "8-12",
            restSeconds: 120,
            primaryMuscle: "Chest",
            equipmentType: "Barbell",
            complexityLevel: 1
        ),
        ProgramExercise(
            exerciseId: "EX004",
            exerciseName: "Incline Dumbbell Press",
            sets: 3,
            repRange: "10-12",
            restSeconds: 90,
            primaryMuscle: "Chest",
            equipmentType: "Dumbbells",
            complexityLevel: 1
        )
    ]

    NavigationStack {
        SessionEditView(sessionIndex: 0, sessionExercises: $exercises)
    }
}
