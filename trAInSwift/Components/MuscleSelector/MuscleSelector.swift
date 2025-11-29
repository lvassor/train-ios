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

    // Viewbox dimensions from the original SVG (matching react-native-body-highlighter)
    // Male: viewBox="0 0 724 1448" for front, viewBox="724 0 724 1448" for back
    // Female: viewBox="0 0 640 1448" for front, viewBox="640 0 640 1448" for back
    // Normalize to use male width for both so they occupy the same space
    private let svgWidth: CGFloat = 724
    private let svgHeight: CGFloat = 1448
    private var actualSvgWidth: CGFloat {
        gender == .male ? 724 : 640
    }
    private var backViewXOffset: CGFloat {
        gender == .male ? 724 : 1000  // Female back paths start around x=1000
    }

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
                            withAnimation(.easeInOut(duration: 0.2)) {
                                gender = bodyGender
                            }
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
                            withAnimation(.easeInOut(duration: 0.2)) {
                                side = bodySide
                            }
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

            // Body diagram
            GeometryReader { geometry in
                // Use consistent scale for both male and female, but enlarge by using 1.0 instead of 0.95
                let scale = min(geometry.size.width / svgWidth, geometry.size.height / svgHeight) * 1.0
                let centerOffsetX = (geometry.size.width - svgWidth * scale) / 2
                // For back view, translate the SVG coordinate system to bring back paths into view
                let viewBoxOffsetX = side == .back ? -backViewXOffset * scale : 0
                // Additional offset for female to center within normalized width
                // For front view, shift right to center. For back view, no additional shift needed
                let genderCenterOffset = gender == .female && side == .front ? (svgWidth - actualSvgWidth) * scale / 2 : 0

                ZStack {
                    // Body parts
                    bodyDiagram
                        .scaleEffect(scale, anchor: .topLeading)
                        .offset(x: centerOffsetX + viewBoxOffsetX + genderCenterOffset, y: 0)
                        .animation(.none, value: selectedMuscles) // Prevent size change on muscle selection
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
            .aspectRatio(svgWidth / svgHeight, contentMode: .fit)
            .animation(.easeInOut(duration: 0.2), value: gender)
            .animation(.easeInOut(duration: 0.2), value: side)

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
                .padding(.horizontal, Spacing.lg)
            }

            // Selection count
            Text("\(selectedMuscles.count) of \(maxSelections) selected")
                .font(.trainCaption)
                .foregroundColor(.trainTextSecondary)
        }
    }

    @ViewBuilder
    private var bodyDiagram: some View {
        let bodyParts = getBodyParts()

        ZStack {
            // Render all body parts
            ForEach(bodyParts, id: \.slug) { part in
                let isSelectable = part.slug.isSelectable
                let groupName = part.slug.questionnaireGroupName ?? part.slug.displayName
                let isSelected = selectedMuscles.contains(groupName)

                MusclePathView(
                    paths: part.paths.allPaths,
                    fillColor: getFillColor(for: part, isSelected: isSelected),
                    isSelected: isSelected,
                    onTap: {
                        if isSelectable {
                            toggleMuscle(groupName)
                        }
                    }
                )
                .allowsHitTesting(isSelectable)
            }
        }
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

    private func getFillColor(for part: MusclePart, isSelected: Bool) -> Color {
        if isSelected {
            return Color.trainPrimary
        }

        if !part.slug.isSelectable {
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

// MARK: - Compact Muscle Selector (for questionnaire)

struct CompactMuscleSelector: View {
    @Binding var selectedMuscles: [String]
    let maxSelections: Int

    @State private var side: MuscleSelector.BodySide = .front
    @State private var gender: MuscleSelector.BodyGender = .male

    // Viewbox dimensions from the original SVG (matching react-native-body-highlighter)
    // Male: viewBox="0 0 724 1448" for front, viewBox="724 0 724 1448" for back
    // Female: viewBox="0 0 640 1448" for front, viewBox="640 0 640 1448" for back
    // Normalize to use male width for both so they occupy the same space
    private let svgWidth: CGFloat = 724
    private let svgHeight: CGFloat = 1448
    private var actualSvgWidth: CGFloat {
        gender == .male ? 724 : 640
    }
    private var backViewXOffset: CGFloat {
        gender == .male ? 724 : 1000  // Female back paths start around x=1000
    }

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
                    ForEach(MuscleSelector.BodyGender.allCases, id: \.self) { bodyGender in
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                gender = bodyGender
                            }
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

                // Side toggle
                HStack(spacing: 0) {
                    ForEach(MuscleSelector.BodySide.allCases, id: \.self) { bodySide in
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                side = bodySide
                            }
                        }) {
                            Text(bodySide.rawValue)
                                .font(.trainCaption)
                                .foregroundColor(side == bodySide ? .white : .trainTextPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, Spacing.xs)
                                .background(side == bodySide ? Color.trainPrimary : Color.clear)
                        }
                    }
                }
                .background(Color.trainTextSecondary.opacity(0.1))
                .cornerRadius(CornerRadius.sm)
            }

            // Body diagram
            GeometryReader { geometry in
                // Use consistent scale for both male and female, but enlarge by using 1.0 instead of 0.95
                let scale = min(geometry.size.width / svgWidth, geometry.size.height / svgHeight) * 1.0
                let centerOffsetX = (geometry.size.width - svgWidth * scale) / 2
                // For back view, translate the SVG coordinate system to bring back paths into view
                let viewBoxOffsetX = side == .back ? -backViewXOffset * scale : 0
                // Additional offset for female to center within normalized width
                // For front view, shift right to center. For back view, no additional shift needed
                let genderCenterOffset = gender == .female && side == .front ? (svgWidth - actualSvgWidth) * scale / 2 : 0

                ZStack {
                    // Fixed frame wrapper to prevent shrinking
                    Color.clear
                        .frame(width: svgWidth * scale, height: svgHeight * scale)

                    bodyDiagram
                        .scaleEffect(scale, anchor: .topLeading)
                        .offset(x: centerOffsetX + viewBoxOffsetX + genderCenterOffset, y: 0)
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .animation(.none, value: selectedMuscles) // Prevent size change on muscle selection
            }
            .aspectRatio(svgWidth / svgHeight, contentMode: .fit)
            .animation(.easeInOut(duration: 0.2), value: gender)
            .animation(.easeInOut(duration: 0.2), value: side)

            // Selected muscles chips
            if !selectedMuscles.isEmpty {
                FlowLayout(spacing: Spacing.xs) {
                    ForEach(selectedMuscles, id: \.self) { muscle in
                        HStack(spacing: 2) {
                            Text(muscle)
                                .font(.trainCaption)
                                .foregroundColor(.white)

                            Button(action: { removeMuscle(muscle) }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                        .padding(.horizontal, Spacing.xs)
                        .padding(.vertical, 2)
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
    }

    @ViewBuilder
    private var bodyDiagram: some View {
        let bodyParts = getBodyParts()

        ZStack {
            ForEach(bodyParts, id: \.slug) { part in
                let isSelectable = part.slug.isSelectable
                let groupName = part.slug.questionnaireGroupName ?? part.slug.displayName
                let isSelected = selectedMuscles.contains(groupName)

                MusclePathView(
                    paths: part.paths.allPaths,
                    fillColor: getFillColor(for: part, isSelected: isSelected),
                    isSelected: isSelected,
                    onTap: {
                        if isSelectable {
                            toggleMuscle(groupName)
                        }
                    }
                )
                .allowsHitTesting(isSelectable)
            }
        }
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

    private func getFillColor(for part: MusclePart, isSelected: Bool) -> Color {
        if isSelected {
            return Color.trainPrimary
        }
        if !part.slug.isSelectable {
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
