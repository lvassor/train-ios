#!/usr/bin/env python3
"""
Correct SVG Logo Path Extractor
Extracts actual logo paths from the isolated SVG file
"""

import re
import xml.etree.ElementTree as ET
from typing import List, Dict

def parse_svg_path_to_swiftui(d_attr: str) -> List[str]:
    """Convert SVG path commands to SwiftUI equivalents"""
    swiftui_commands = []

    # Clean up the path data
    d_attr = d_attr.strip()

    # Split path data into command segments, handling both space and comma separators
    # First normalize the path data
    d_attr = re.sub(r',', ' ', d_attr)  # Replace commas with spaces
    d_attr = re.sub(r'([MmLlHhVvCcSsQqTtAaZz])', r' \1 ', d_attr)  # Add spaces around commands
    d_attr = re.sub(r'\s+', ' ', d_attr)  # Normalize multiple spaces
    d_attr = d_attr.strip()

    # Split by command letters
    commands = re.findall(r'[MmLlHhVvCcSsQqTtAaZz][^MmLlHhVvCcSsQqTtAaZz]*', d_attr)

    current_x, current_y = 0.0, 0.0  # Track current position for relative commands

    for cmd in commands:
        cmd = cmd.strip()
        if not cmd:
            continue

        command_type = cmd[0]
        params_str = cmd[1:].strip()

        if not params_str:
            if command_type.upper() == 'Z':
                swiftui_commands.append("path.closeSubpath()")
            continue

        # Extract numeric parameters
        params = re.findall(r'-?\d*\.?\d+', params_str)
        params = [float(p) for p in params]

        if command_type in ['M', 'm']:  # Move to
            for i in range(0, len(params), 2):
                if i + 1 < len(params):
                    x, y = params[i], params[i + 1]
                    if command_type == 'm' and i > 0:  # Relative move (after first)
                        current_x += x
                        current_y += y
                    elif command_type == 'm':  # First relative move is absolute
                        current_x, current_y = x, y
                    else:  # Absolute move
                        current_x, current_y = x, y

                    if i == 0:  # First coordinate pair is move
                        swiftui_commands.append(f"path.move(to: CGPoint(x: {current_x}, y: {current_y}))")
                    else:  # Subsequent pairs are implicit line commands
                        swiftui_commands.append(f"path.addLine(to: CGPoint(x: {current_x}, y: {current_y}))")

        elif command_type in ['L', 'l']:  # Line to
            for i in range(0, len(params), 2):
                if i + 1 < len(params):
                    x, y = params[i], params[i + 1]
                    if command_type == 'l':  # Relative
                        current_x += x
                        current_y += y
                    else:  # Absolute
                        current_x, current_y = x, y
                    swiftui_commands.append(f"path.addLine(to: CGPoint(x: {current_x}, y: {current_y}))")

        elif command_type in ['C', 'c']:  # Cubic Bezier curve
            for i in range(0, len(params), 6):
                if i + 5 < len(params):
                    x1, y1, x2, y2, x, y = params[i:i+6]
                    if command_type == 'c':  # Relative
                        x1 += current_x
                        y1 += current_y
                        x2 += current_x
                        y2 += current_y
                        x += current_x
                        y += current_y
                    current_x, current_y = x, y
                    swiftui_commands.append(f"path.addCurve(to: CGPoint(x: {x}, y: {y}), control1: CGPoint(x: {x1}, y: {y1}), control2: CGPoint(x: {x2}, y: {y2}))")

        elif command_type in ['H', 'h']:  # Horizontal line
            for param in params:
                if command_type == 'h':  # Relative
                    current_x += param
                else:  # Absolute
                    current_x = param
                swiftui_commands.append(f"path.addLine(to: CGPoint(x: {current_x}, y: {current_y}))")

        elif command_type in ['V', 'v']:  # Vertical line
            for param in params:
                if command_type == 'v':  # Relative
                    current_y += param
                else:  # Absolute
                    current_y = param
                swiftui_commands.append(f"path.addLine(to: CGPoint(x: {current_x}, y: {current_y}))")

        elif command_type in ['Z', 'z']:  # Close path
            swiftui_commands.append("path.closeSubpath()")

    return swiftui_commands

def extract_logo_paths(svg_file_path: str) -> Dict[str, List[str]]:
    """Extract logo paths from the isolated SVG file"""

    text_paths = []
    dumbbell_paths = []

    try:
        # Parse the XML
        tree = ET.parse(svg_file_path)
        root = tree.getroot()

        # Define namespaces
        namespaces = {'svg': 'http://www.w3.org/2000/svg'}

        print("=== ANALYZING SVG STRUCTURE ===")

        # Find all path elements
        for path in root.findall('.//svg:path', namespaces):
            d_attr = path.get('d')
            fill_attr = path.get('fill', '')

            if not d_attr:
                continue

            print(f"Found path with fill='{fill_attr}'")
            print(f"Path data: {d_attr[:100]}...")

            # Convert to SwiftUI commands
            swiftui_commands = parse_svg_path_to_swiftui(d_attr)

            if fill_attr in ['#f9faf8', '#ffffff']:  # White/text paths
                text_paths.extend(swiftui_commands)
                print(f"Added {len(swiftui_commands)} commands to TEXT paths")
            elif fill_attr == '#f0aa3e':  # Orange/dumbbell paths
                dumbbell_paths.extend(swiftui_commands)
                print(f"Added {len(swiftui_commands)} commands to DUMBBELL paths")

            print("---")

        # Also look for groups with fill attributes
        for group in root.findall('.//svg:g[@fill]', namespaces):
            fill_attr = group.get('fill', '')
            print(f"Found group with fill='{fill_attr}'")

            for path in group.findall('.//svg:path', namespaces):
                d_attr = path.get('d')
                if not d_attr:
                    continue

                print(f"Group path data: {d_attr[:100]}...")

                swiftui_commands = parse_svg_path_to_swiftui(d_attr)

                if fill_attr in ['#f9faf8', '#ffffff']:
                    text_paths.extend(swiftui_commands)
                    print(f"Added {len(swiftui_commands)} group commands to TEXT paths")
                elif fill_attr == '#f0aa3e':
                    dumbbell_paths.extend(swiftui_commands)
                    print(f"Added {len(swiftui_commands)} group commands to DUMBBELL paths")

                print("---")

    except Exception as e:
        print(f"Error parsing SVG: {e}")
        import traceback
        traceback.print_exc()

    return {
        'text_paths': text_paths,
        'dumbbell_paths': dumbbell_paths
    }

def generate_swiftui_shapes(paths_data: Dict[str, List[str]]) -> Dict[str, str]:
    """Generate SwiftUI shape code"""

    # Generate text shape code
    text_code = "\n        ".join(paths_data['text_paths']) if paths_data['text_paths'] else "// No text paths found"

    # Generate dumbbell shape code
    dumbbell_code = "\n        ".join(paths_data['dumbbell_paths']) if paths_data['dumbbell_paths'] else "// No dumbbell paths found"

    return {
        'text_shape': text_code,
        'dumbbell_shape': dumbbell_code
    }

def main():
    svg_file = "/Users/lukevassor/Documents/trAIn-ios/assets/train-logo-with-text_isolate.svg"

    print("Extracting paths from isolated SVG...")
    paths_data = extract_logo_paths(svg_file)

    print(f"\n=== EXTRACTION RESULTS ===")
    print(f"Text paths found: {len(paths_data['text_paths'])}")
    print(f"Dumbbell paths found: {len(paths_data['dumbbell_paths'])}")

    if paths_data['text_paths']:
        print(f"\n=== TEXT PATH PREVIEW ===")
        for i, cmd in enumerate(paths_data['text_paths'][:10]):
            print(f"{i+1}. {cmd}")

    if paths_data['dumbbell_paths']:
        print(f"\n=== DUMBBELL PATH PREVIEW ===")
        for i, cmd in enumerate(paths_data['dumbbell_paths'][:10]):
            print(f"{i+1}. {cmd}")

    # Generate SwiftUI code
    shape_code = generate_swiftui_shapes(paths_data)

    print(f"\n=== GENERATED SWIFT CODE ===")
    print("TrainLogoTextShape paths:")
    print(shape_code['text_shape'][:500] + "..." if len(shape_code['text_shape']) > 500 else shape_code['text_shape'])

    print("\nDumbbellShape paths:")
    print(shape_code['dumbbell_shape'][:500] + "..." if len(shape_code['dumbbell_shape']) > 500 else shape_code['dumbbell_shape'])

    return shape_code

if __name__ == "__main__":
    main()