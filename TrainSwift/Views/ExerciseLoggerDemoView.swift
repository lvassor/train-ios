//
//  ExerciseLoggerDemoView.swift
//  TrainSwift
//
//  Demo tab components for the exercise logger
//

import SwiftUI

// MARK: - Exercise Demo Tab (Redesigned)

struct ExerciseDemoTab: View {
    let exercise: DBExercise
    @Environment(\.colorScheme) var colorScheme

    private static let stepPrefixRegex = try? NSRegularExpression(pattern: "^Step\\s*\\d+\\s*:\\s*", options: .caseInsensitive)

    // Get the list of equipment items from the exercise
    private var equipmentItems: [String] {
        // Parse equipment from category and specific fields
        var items: [String] = []
        if !exercise.equipmentCategory.isEmpty {
            items.append(exercise.equipmentCategory)
        }
        if let specific = exercise.equipmentSpecific, !specific.isEmpty {
            // Split by comma if multiple items
            let specificItems = specific.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
            items.append(contentsOf: specificItems)
        }
        return items.isEmpty ? ["Equipment"] : items
    }

    // Get active muscle groups
    private var muscleGroups: [String] {
        var groups: [String] = [exercise.primaryMuscle]
        if let secondary = exercise.secondaryMuscle {
            groups.append(secondary)
        }
        return groups
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Exercise Info (same as Logger tab - centered, no container)
                VStack(spacing: 4) {
                    Text(exercise.displayName)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.trainTextPrimary)
                        .multilineTextAlignment(.center)

                    // Equipment tag
                    Text(exercise.equipmentCategory)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 6)
                        .background(Color.gray)
                        .clipShape(Capsule())
                        .padding(.top, 4)
                }
                .padding(.top, 20)

                // Video Player Card
                DemoVideoPlayerCard(exerciseId: exercise.exerciseId)
                    .padding(.horizontal, 18)
                    .padding(.top, 24)

                // Equipment Section - horizontal row of placeholder tiles
                DemoInfoSection(
                    title: "Equipment",
                    items: equipmentItems,
                    sectionType: .equipment
                )
                .padding(.top, 24)

                // Active Muscle Groups Section - with body diagrams
                DemoMuscleGroupsSection(
                    title: "Active Muscle Groups",
                    muscleGroups: muscleGroups
                )
                .padding(.top, 16)

                // Instructions Card
                DemoInstructionsCard(instructions: exercise.instructionSteps)
                    .padding(.horizontal, 18)
                    .padding(.top, 16)
                    .padding(.bottom, 100)
            }
        }
    }
}

// MARK: - Demo Video Player Card

struct DemoVideoPlayerCard: View {
    let exerciseId: String
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            // Use existing ExerciseMediaPlayer
            ExerciseMediaPlayer(exerciseId: exerciseId)
                .frame(height: 192)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(colorScheme == .dark ? Color.white.opacity(0.3) : Color.black, lineWidth: 1)
                )
        }
    }
}

// MARK: - Demo Info Section (Equipment)

enum DemoSectionType {
    case equipment
    case muscles
}

struct DemoInfoSection: View {
    let title: String
    let items: [String]
    let sectionType: DemoSectionType
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.trainTextPrimary)
                .padding(.horizontal, 50)

            HStack(spacing: 35) {
                ForEach(items.prefix(4), id: \.self) { item in
                    DemoPlaceholderTile(label: item, iconName: equipmentIcon(for: item))
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func equipmentIcon(for item: String) -> String {
        let lowercased = item.lowercased()
        if lowercased.contains("barbell") { return "figure.strengthtraining.traditional" }
        if lowercased.contains("dumbbell") { return "dumbbell.fill" }
        if lowercased.contains("cable") { return "cable.coaxial" }
        if lowercased.contains("machine") { return "gearshape.fill" }
        if lowercased.contains("bench") { return "bed.double.fill" }
        if lowercased.contains("plate") { return "circle.fill" }
        if lowercased.contains("bodyweight") { return "figure.stand" }
        return "photo"
    }
}

// MARK: - Demo Placeholder Tile

struct DemoPlaceholderTile: View {
    let label: String
    let iconName: String
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.white)
                    .frame(width: 70, height: 70)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .stroke(colorScheme == .dark ? Color.white.opacity(0.2) : Color.black.opacity(0.1), lineWidth: 1)
                    )

                Image(systemName: iconName)
                    .font(.system(size: 24))
                    .foregroundColor(.trainTextPrimary)
            }

            Text(label)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.trainTextSecondary)
                .lineLimit(1)
        }
    }
}

// MARK: - Demo Muscle Groups Section (with Body Diagrams)

struct DemoMuscleGroupsSection: View {
    let title: String
    let muscleGroups: [String]
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.trainTextPrimary)
                .padding(.horizontal, 50)

            HStack(spacing: Spacing.lg) {
                ForEach(muscleGroups.prefix(3), id: \.self) { muscleGroup in
                    VStack(spacing: Spacing.sm) {
                        StaticMuscleView(
                            muscleGroup: muscleGroup,
                            gender: .male,  // Default to male, could be made configurable
                            size: 90,
                            useUniformBaseColor: true
                        )
                        .frame(width: 90, height: 90)

                        Text(muscleGroup)
                            .font(.trainCaption)
                            .foregroundColor(.trainTextSecondary)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Demo Instructions Card

struct DemoInstructionsCard: View {
    let instructions: [String]
    @Environment(\.colorScheme) var colorScheme

    private static let stepPrefixRegex = try? NSRegularExpression(pattern: "^Step\\s*\\d+\\s*:\\s*", options: .caseInsensitive)

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Instructions")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.trainTextPrimary)

            if instructions.isEmpty {
                Text("Instructions coming soon")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.trainTextSecondary)
                    .opacity(0.8)
                    .padding(.top, 4)
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(Array(instructions.enumerated()), id: \.offset) { index, instruction in
                        HStack(alignment: .top, spacing: 8) {
                            Text("\(index + 1).")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.trainTextPrimary)
                                .opacity(0.8)
                            Text(cleanStepText(instruction))
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.trainTextPrimary)
                                .opacity(0.8)
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(colorScheme == .dark ? Color.white.opacity(0.3) : Color.black, lineWidth: 1)
        )
    }

    // Clean up step text by removing "Step X:" prefix
    private func cleanStepText(_ step: String) -> String {
        guard let regex = Self.stepPrefixRegex else { return step }
        let range = NSRange(step.startIndex..., in: step)
        return regex.stringByReplacingMatches(in: step, options: [], range: range, withTemplate: "")
    }
}
