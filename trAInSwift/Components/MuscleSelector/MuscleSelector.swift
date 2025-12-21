//
//  MuscleSelector.swift
//  trAInSwift
//
//  Interactive body diagram for selecting muscle groups
//

import SwiftUI

// MARK: - Muscle Selector View

struct MuscleSelector: View {
    @Binding var selectedMuscles: [String]
    let maxSelections: Int

    @State private var side: BodySide = .front
    @State private var gender: BodyGender = .male

    enum BodySide: String, CaseIterable {
        case front = "Front"
        case back = "Back"
    }

    enum BodyGender: String, CaseIterable {
        case male = "Male"
        case female = "Female"
    }

    // Standard canvas dimensions for aspect ratio (matching transformed data viewBox)
    private let svgWidth: CGFloat = 650
    private let svgHeight: CGFloat = 1450

    init(selectedMuscles: Binding<[String]>, maxSelections: Int = 3) {
        self._selectedMuscles = selectedMuscles
        self.maxSelections = maxSelections
    }

    var body: some View {
        VStack(spacing: Spacing.md) {
            // Toggle row with Gender and Side toggles
            HStack(spacing: Spacing.md) {
                // Gender toggle
                HStack(spacing: 0) {
                    ForEach(BodyGender.allCases, id: \.self) { bodyGender in
                        Button(action: {
                            // Instant switch - no animation to avoid shape mixing
                            gender = bodyGender
                        }) {
                            Image(systemName: bodyGender == .male ? "figure.stand" : "figure.stand.dress")
                                .font(.system(size: 16))
                                .foregroundColor(gender == bodyGender ? .white : .trainTextPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, Spacing.sm)
                                .background(gender == bodyGender ? Color.trainPrimary : Color.clear)
                        }
                    }
                }
                .background(Color.trainTextSecondary.opacity(0.1))
                .cornerRadius(CornerRadius.md)
                .frame(width: 100)

                // Side toggle
                HStack(spacing: 0) {
                    ForEach(BodySide.allCases, id: \.self) { bodySide in
                        Button(action: {
                            // Instant switch - no animation to avoid shape mixing
                            side = bodySide
                        }) {
                            Text(bodySide.rawValue)
                                .font(.trainBody)
                                .foregroundColor(side == bodySide ? .white : .trainTextPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, Spacing.sm)
                                .background(side == bodySide ? Color.trainPrimary : Color.clear)
                        }
                    }
                }
                .background(Color.trainTextSecondary.opacity(0.1))
                .cornerRadius(CornerRadius.md)
            }
            .padding(.horizontal, Spacing.lg)

            // Body diagram with fixed space for labels below
            ZStack(alignment: .bottom) {
                // Body diagram - takes all available space
                GeometryReader { geometry in
                    let scale = min(geometry.size.width / svgWidth, geometry.size.height / svgHeight)

                    ZStack {
                        bodyDiagram
                            .frame(width: svgWidth, height: svgHeight)
                            .scaleEffect(scale, anchor: .center)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                }
                .aspectRatio(svgWidth / svgHeight, contentMode: .fit)

                // Labels overlay - positioned absolutely at bottom, doesn't affect diagram size
                VStack(spacing: Spacing.xs) {
                    // Selected muscles display
                    if !selectedMuscles.isEmpty {
                        HStack(spacing: Spacing.sm) {
                            ForEach(selectedMuscles, id: \.self) { muscle in
                                HStack(spacing: 4) {
                                    Text(muscle)
                                        .font(.trainCaption)
                                        .foregroundColor(.white)

                                    Button(action: { removeMuscle(muscle) }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(.white.opacity(0.8))
                                    }
                                }
                                .padding(.horizontal, Spacing.sm)
                                .padding(.vertical, 4)
                                .background(Color.trainPrimary)
                                .cornerRadius(CornerRadius.sm)
                            }
                        }
                    }

                    // Selection count
                    Text("\(selectedMuscles.count) of \(maxSelections) selected")
                        .font(.trainCaption)
                        .foregroundColor(.trainTextSecondary)
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.sm)
            }
        }
    }

    @ViewBuilder
    private var bodyDiagram: some View {
        let bodyParts = getBodyParts()

        ZStack {
            // Render all body parts
            ForEach(bodyParts, id: \.slug) { part in
                // Triceps and trapezius are only selectable on back view
                let isSelectableOnCurrentView = part.slug.isSelectable && isSelectableOnSide(part.slug)
                let groupName = part.slug.questionnaireGroupName ?? part.slug.displayName
                let isSelected = selectedMuscles.contains(groupName)

                MusclePathView(
                    paths: part.paths.allPaths,
                    fillColor: getFillColor(for: part, isSelected: isSelected, isSelectable: isSelectableOnCurrentView),
                    isSelected: isSelected,
                    onTap: {
                        if isSelectableOnCurrentView {
                            toggleMuscle(groupName)
                        }
                    }
                )
                .allowsHitTesting(isSelectableOnCurrentView)
            }
        }
    }

    // Triceps and trapezius are only selectable on back view
    private func isSelectableOnSide(_ slug: MuscleSlug) -> Bool {
        if side == .front && (slug == .triceps || slug == .trapezius) {
            return false
        }
        return true
    }

    private func getBodyParts() -> [MusclePart] {
        switch (gender, side) {
        case (.male, .front):
            return BodyDataProvider.maleFront
        case (.male, .back):
            return BodyDataProvider.maleBack
        case (.female, .front):
            return BodyDataProvider.femaleFront
        case (.female, .back):
            return BodyDataProvider.femaleBack
        }
    }

    private func getFillColor(for part: MusclePart, isSelected: Bool, isSelectable: Bool = true) -> Color {
        if isSelected {
            return Color.trainPrimary
        }

        if !part.slug.isSelectable || !isSelectable {
            return Color(hex: part.defaultColor) ?? .gray
        }

        return Color(hex: "#3f3f3f") ?? .gray
    }

    private func toggleMuscle(_ muscle: String) {
        if selectedMuscles.contains(muscle) {
            selectedMuscles.removeAll { $0 == muscle }
        } else if selectedMuscles.count < maxSelections {
            selectedMuscles.append(muscle)
        }
    }

    private func removeMuscle(_ muscle: String) {
        selectedMuscles.removeAll { $0 == muscle }
    }
}

// MARK: - Compact Muscle Selector (for questionnaire) - Side by Side Front/Back

struct CompactMuscleSelector: View {
    @Binding var selectedMuscles: [String]
    let maxSelections: Int

    @State private var gender: MuscleSelector.BodyGender = .male

    // Standard canvas dimensions for aspect ratio (matching transformed data viewBox)
    private let svgWidth: CGFloat = 650
    private let svgHeight: CGFloat = 1450

    init(selectedMuscles: Binding<[String]>, maxSelections: Int = 3) {
        self._selectedMuscles = selectedMuscles
        self.maxSelections = maxSelections
    }

    var body: some View {
        VStack(spacing: Spacing.sm) {
            // Gender toggle only (no front/back toggle - both shown)
            HStack(spacing: 0) {
                ForEach(MuscleSelector.BodyGender.allCases, id: \.self) { bodyGender in
                    Button(action: {
                        gender = bodyGender
                    }) {
                        Image(systemName: bodyGender == .male ? "figure.stand" : "figure.stand.dress")
                            .font(.system(size: 14))
                            .foregroundColor(gender == bodyGender ? .white : .trainTextPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.xs)
                            .background(gender == bodyGender ? Color.trainPrimary : Color.clear)
                    }
                }
            }
            .background(Color.trainTextSecondary.opacity(0.1))
            .cornerRadius(CornerRadius.sm)
            .frame(width: 80)

            // Side by side body diagrams - front and back
            HStack(spacing: Spacing.sm) {
                // Front view
                VStack(spacing: 4) {
                    Text("Front")
                        .font(.trainCaption)
                        .foregroundColor(.trainTextSecondary)

                    bodyDiagram(side: .front)
                }

                // Back view
                VStack(spacing: 4) {
                    Text("Back")
                        .font(.trainCaption)
                        .foregroundColor(.trainTextSecondary)

                    bodyDiagram(side: .back)
                }
            }
        }
    }

    @ViewBuilder
    private func bodyDiagram(side: MuscleSelector.BodySide) -> some View {
        let bodyParts = getBodyParts(side: side)

        GeometryReader { geometry in
            let scale = min(geometry.size.width / svgWidth, geometry.size.height / svgHeight)

            ZStack {
                ForEach(bodyParts, id: \.slug) { part in
                    // Triceps and trapezius are only selectable on back view
                    let isSelectableOnCurrentView = part.slug.isSelectable && isSelectableOnSide(part.slug, side: side)
                    let groupName = part.slug.questionnaireGroupName ?? part.slug.displayName
                    let isSelected = selectedMuscles.contains(groupName)

                    MusclePathView(
                        paths: part.paths.allPaths,
                        fillColor: getFillColor(for: part, isSelected: isSelected, isSelectable: isSelectableOnCurrentView),
                        isSelected: isSelected,
                        onTap: {
                            if isSelectableOnCurrentView {
                                toggleMuscle(groupName)
                            }
                        }
                    )
                    .allowsHitTesting(isSelectableOnCurrentView)
                }
            }
            .frame(width: svgWidth, height: svgHeight)
            .scaleEffect(scale, anchor: .center)
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .aspectRatio(svgWidth / svgHeight, contentMode: .fit)
    }

    // Triceps and trapezius are only selectable on back view
    private func isSelectableOnSide(_ slug: MuscleSlug, side: MuscleSelector.BodySide) -> Bool {
        if side == .front && (slug == .triceps || slug == .trapezius) {
            return false
        }
        return true
    }

    private func getBodyParts(side: MuscleSelector.BodySide) -> [MusclePart] {
        switch (gender, side) {
        case (.male, .front):
            return BodyDataProvider.maleFront
        case (.male, .back):
            return BodyDataProvider.maleBack
        case (.female, .front):
            return BodyDataProvider.femaleFront
        case (.female, .back):
            return BodyDataProvider.femaleBack
        }
    }

    private func getFillColor(for part: MusclePart, isSelected: Bool, isSelectable: Bool = true) -> Color {
        if isSelected {
            return Color.trainPrimary
        }
        if !part.slug.isSelectable || !isSelectable {
            return Color(hex: part.defaultColor) ?? .gray
        }
        return Color(hex: "#3f3f3f") ?? .gray
    }

    private func toggleMuscle(_ muscle: String) {
        if selectedMuscles.contains(muscle) {
            selectedMuscles.removeAll { $0 == muscle }
        } else if selectedMuscles.count < maxSelections {
            selectedMuscles.append(muscle)
        }
    }
}

// MARK: - Flow Layout

struct FlowLayout<Content: View>: View {
    let spacing: CGFloat
    let content: () -> Content

    init(spacing: CGFloat = 8, @ViewBuilder content: @escaping () -> Content) {
        self.spacing = spacing
        self.content = content
    }

    var body: some View {
        HStack(spacing: spacing) {
            content()
        }
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State private var selected: [String] = []

        var body: some View {
            VStack {
                CompactMuscleSelector(selectedMuscles: $selected, maxSelections: 3)
                    .frame(height: 400)
                    .padding()

                Text("Selected: \(selected.joined(separator: ", "))")
                    .font(.caption)
            }
        }
    }

    return PreviewWrapper()
}
