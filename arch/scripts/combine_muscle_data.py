#!/usr/bin/env python3
"""
Combine the 4 generated Swift body data files into a single MuscleData.swift file.

This script reads the pre-converted Swift arrays from:
  - generated_swift/maleFront.swift
  - generated_swift/maleBack.swift
  - generated_swift/femaleFront.swift
  - generated_swift/femaleBack.swift

And combines them into a complete MuscleData.swift with all necessary enums, structs,
and the BodyDataProvider containing all 4 body data arrays.

Usage:
    python combine_muscle_data.py
"""

import os
from pathlib import Path

# Get the script directory
SCRIPT_DIR = Path(__file__).parent
GENERATED_DIR = SCRIPT_DIR / "generated_swift"
OUTPUT_DIR = SCRIPT_DIR.parent / "trAInSwift" / "Components" / "MuscleSelector"

# Header for the Swift file
SWIFT_HEADER = '''//
//  MuscleData.swift
//  trAInSwift
//
//  SVG path data for body muscle groups, converted from react-native-body-highlighter
//

import Foundation

// MARK: - Muscle Slug

enum MuscleSlug: String, CaseIterable, Identifiable {
    case chest
    case abs
    case biceps
    case triceps
    case deltoids
    case quadriceps
    case hamstring
    case calves
    case gluteal
    case trapezius
    case upperBack = "upper-back"
    case lowerBack = "lower-back"
    case obliques
    case neck
    case forearm
    case adductors
    case knees
    case tibialis
    case ankles
    case feet
    case hands
    case head
    case hair

    var id: String { rawValue }

    // User-friendly display name
    var displayName: String {
        switch self {
        case .chest: return "Chest"
        case .abs: return "Abs"
        case .biceps: return "Biceps"
        case .triceps: return "Triceps"
        case .deltoids: return "Shoulders"
        case .quadriceps: return "Quads"
        case .hamstring: return "Hamstrings"
        case .calves: return "Calves"
        case .gluteal: return "Glutes"
        case .trapezius: return "Trapezius"
        case .upperBack: return "Upper Back"
        case .lowerBack: return "Lower Back"
        case .obliques: return "Obliques"
        case .neck: return "Neck"
        case .forearm: return "Forearms"
        case .adductors: return "Adductors"
        case .knees: return "Knees"
        case .tibialis: return "Tibialis"
        case .ankles: return "Ankles"
        case .feet: return "Feet"
        case .hands: return "Hands"
        case .head: return "Head"
        case .hair: return "Hair"
        }
    }

    // Whether this muscle is selectable by users
    var isSelectable: Bool {
        switch self {
        case .chest, .abs, .biceps, .triceps, .deltoids, .quadriceps,
             .hamstring, .calves, .gluteal, .trapezius, .upperBack,
             .lowerBack, .obliques, .forearm:
            return true
        default:
            return false
        }
    }

    // Map to questionnaire muscle group names
    var questionnaireGroupName: String? {
        switch self {
        case .chest: return "Chest"
        case .deltoids: return "Shoulders"
        case .upperBack, .lowerBack, .trapezius: return "Back"
        case .triceps: return "Triceps"
        case .biceps: return "Biceps"
        case .abs, .obliques: return "Abs"
        case .quadriceps: return "Quads"
        case .hamstring: return "Hamstrings"
        case .gluteal: return "Glutes"
        case .calves: return "Calves"
        default: return nil
        }
    }
}

// MARK: - Muscle Part

struct MusclePart: Identifiable {
    let id = UUID()
    let slug: MuscleSlug
    let paths: MusclePaths
    let defaultColor: String

    init(slug: MuscleSlug, paths: MusclePaths, defaultColor: String = "#3f3f3f") {
        self.slug = slug
        self.paths = paths
        self.defaultColor = defaultColor
    }
}

struct MusclePaths {
    var common: [String]
    var left: [String]
    var right: [String]

    init(common: [String] = [], left: [String] = [], right: [String] = []) {
        self.common = common
        self.left = left
        self.right = right
    }

    var allPaths: [String] {
        common + left + right
    }
}

// MARK: - Body Data Provider

struct BodyDataProvider {

    // MARK: - Male Front Body

'''

# Footer after all body data
SWIFT_FOOTER = '''
}
'''


def read_component_file(filename: str) -> str:
    """Read a generated Swift component file and return its content."""
    filepath = GENERATED_DIR / filename
    if not filepath.exists():
        raise FileNotFoundError(f"Component file not found: {filepath}")

    with open(filepath, 'r') as f:
        content = f.read()

    # Remove any trailing comments (the "// Converted X body parts:" section)
    lines = content.split('\n')
    clean_lines = []
    for line in lines:
        if line.strip().startswith('// Converted'):
            break
        clean_lines.append(line)

    return '\n'.join(clean_lines).rstrip()


def add_section_comment(section_name: str) -> str:
    """Add a section comment for a body data array."""
    return f"\n    // MARK: - {section_name}\n\n"


def main():
    print("Combining muscle data files...")

    # Read all 4 component files
    print("  Reading maleFront.swift...")
    male_front = read_component_file("maleFront.swift")

    print("  Reading maleBack.swift...")
    male_back = read_component_file("maleBack.swift")

    print("  Reading femaleFront.swift...")
    female_front = read_component_file("femaleFront.swift")

    print("  Reading femaleBack.swift...")
    female_back = read_component_file("femaleBack.swift")

    # Combine into the final Swift file
    output = SWIFT_HEADER

    # Add male front (already has the correct variable declaration)
    output += male_front
    output += "\n"

    # Add male back section
    output += add_section_comment("Male Back Body")
    output += male_back
    output += "\n"

    # Add female front section
    output += add_section_comment("Female Front Body")
    output += female_front
    output += "\n"

    # Add female back section
    output += add_section_comment("Female Back Body")
    output += female_back

    # Add footer
    output += SWIFT_FOOTER

    # Write the output file
    output_path = OUTPUT_DIR / "MuscleData.swift"
    print(f"\nWriting combined file to: {output_path}")

    # Ensure output directory exists
    output_path.parent.mkdir(parents=True, exist_ok=True)

    with open(output_path, 'w') as f:
        f.write(output)

    print("Done!")

    # Print summary
    print("\nGenerated MuscleData.swift with:")
    print("  - MuscleSlug enum (23 cases)")
    print("  - MusclePart struct")
    print("  - MusclePaths struct")
    print("  - BodyDataProvider with 4 body data arrays:")
    print("    - maleFront")
    print("    - maleBack")
    print("    - femaleFront")
    print("    - femaleBack")


if __name__ == "__main__":
    main()
