//
//  StaticMuscleView.swift
//  trAInSwift
//
//  Static, non-interactive body diagram view for displaying highlighted muscles
//  Used in ProfileView to show priority muscle groups as mini diagrams
//

import SwiftUI

// MARK: - Static Muscle View

/// A compact, non-interactive body diagram that highlights a specific muscle group
/// Automatically determines front/back view based on muscle location
struct StaticMuscleView: View {
    let muscleGroup: String
    let gender: MuscleSelector.BodyGender
    let size: CGFloat

    // Standard canvas dimensions for aspect ratio (matching transformed data viewBox)
    private let svgWidth: CGFloat = 650
    private let svgHeight: CGFloat = 1450

    init(muscleGroup: String, gender: MuscleSelector.BodyGender = .male, size: CGFloat = 60) {
        self.muscleGroup = muscleGroup
        self.gender = gender
        self.size = size
    }

    /// Determines whether a muscle group should show front or back view
    private var bodySide: MuscleSelector.BodySide {
        switch muscleGroup.lowercased() {
        // Front muscles
        case "chest", "abs", "biceps", "quads":
            return .front
        // Back muscles
        case "back", "glutes", "hamstrings", "triceps", "calves":
            return .back
        // Shoulders visible from front (deltoids wrap around)
        case "shoulders":
            return .front
        default:
            return .front
        }
    }

    var body: some View {
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
        .frame(width: size * (svgWidth / svgHeight), height: size)
    }

    @ViewBuilder
    private var bodyDiagram: some View {
        let bodyParts = getBodyParts()

        ZStack {
            ForEach(bodyParts, id: \.slug) { part in
                let groupName = part.slug.questionnaireGroupName ?? part.slug.displayName
                let isHighlighted = groupName.lowercased() == muscleGroup.lowercased()

                StaticMusclePathView(
                    paths: part.paths.allPaths,
                    fillColor: getFillColor(for: part, isHighlighted: isHighlighted),
                    isHighlighted: isHighlighted
                )
            }
        }
    }

    private func getBodyParts() -> [MusclePart] {
        switch (gender, bodySide) {
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

    private func getFillColor(for part: MusclePart, isHighlighted: Bool) -> Color {
        if isHighlighted {
            return Color.trainPrimary
        }

        if !part.slug.isSelectable {
            return Color(hex: part.defaultColor) ?? .gray
        }

        return Color(hex: "#3f3f3f") ?? .gray
    }
}

// MARK: - Static Muscle Path View (Non-interactive)

/// Non-interactive version of MusclePathView - no tap gestures
struct StaticMusclePathView: View {
    let paths: [String]
    let fillColor: Color
    let isHighlighted: Bool

    var body: some View {
        ZStack {
            ForEach(paths.indices, id: \.self) { index in
                SVGPath(svgPath: paths[index])
                    .fill(isHighlighted ? Color.trainPrimary : fillColor)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        HStack(spacing: 20) {
            VStack {
                StaticMuscleView(muscleGroup: "Chest", gender: .male)
                Text("Chest")
                    .font(.caption)
            }
            VStack {
                StaticMuscleView(muscleGroup: "Back", gender: .male)
                Text("Back")
                    .font(.caption)
            }
            VStack {
                StaticMuscleView(muscleGroup: "Shoulders", gender: .male)
                Text("Shoulders")
                    .font(.caption)
            }
        }
        HStack(spacing: 20) {
            VStack {
                StaticMuscleView(muscleGroup: "Quads", gender: .female)
                Text("Quads")
                    .font(.caption)
            }
            VStack {
                StaticMuscleView(muscleGroup: "Glutes", gender: .female)
                Text("Glutes")
                    .font(.caption)
            }
            VStack {
                StaticMuscleView(muscleGroup: "Hamstrings", gender: .female)
                Text("Hamstrings")
                    .font(.caption)
            }
        }
    }
    .padding()
    .background(Color.black)
}
