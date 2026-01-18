#!/usr/bin/env python3
"""
Update Launch Screen with Correct Logo Paths
Extracts actual logo paths and updates the LaunchScreenView.swift file
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
    d_attr = re.sub(r',', ' ', d_attr)  # Replace commas with spaces
    d_attr = re.sub(r'([MmLlHhVvCcSsQqTtAaZz])', r' \1 ', d_attr)  # Add spaces around commands
    d_attr = re.sub(r'\s+', ' ', d_attr)  # Normalize multiple spaces
    d_attr = d_attr.strip()

    # Split by command letters
    commands = re.findall(r'[MmLlHhVvCcSsQqTtAaZz][^MmLlHhVvCcSsQqTtAaZz]*', d_attr)

    current_x, current_y = 0.0, 0.0

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
                    if command_type == 'm' and i > 0:
                        current_x += x
                        current_y += y
                    elif command_type == 'm':
                        current_x, current_y = x, y
                    else:
                        current_x, current_y = x, y

                    if i == 0:
                        swiftui_commands.append(f"path.move(to: CGPoint(x: {current_x}, y: {current_y}))")
                    else:
                        swiftui_commands.append(f"path.addLine(to: CGPoint(x: {current_x}, y: {current_y}))")

        elif command_type in ['L', 'l']:  # Line to
            for i in range(0, len(params), 2):
                if i + 1 < len(params):
                    x, y = params[i], params[i + 1]
                    if command_type == 'l':
                        current_x += x
                        current_y += y
                    else:
                        current_x, current_y = x, y
                    swiftui_commands.append(f"path.addLine(to: CGPoint(x: {current_x}, y: {current_y}))")

        elif command_type in ['C', 'c']:  # Cubic Bezier curve
            for i in range(0, len(params), 6):
                if i + 5 < len(params):
                    x1, y1, x2, y2, x, y = params[i:i+6]
                    if command_type == 'c':
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
                if command_type == 'h':
                    current_x += param
                else:
                    current_x = param
                swiftui_commands.append(f"path.addLine(to: CGPoint(x: {current_x}, y: {current_y}))")

        elif command_type in ['V', 'v']:  # Vertical line
            for param in params:
                if command_type == 'v':
                    current_y += param
                else:
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
        tree = ET.parse(svg_file_path)
        root = tree.getroot()
        namespaces = {'svg': 'http://www.w3.org/2000/svg'}

        # Find all path elements
        for path in root.findall('.//svg:path', namespaces):
            d_attr = path.get('d')
            fill_attr = path.get('fill', '')

            if not d_attr:
                continue

            swiftui_commands = parse_svg_path_to_swiftui(d_attr)

            if fill_attr in ['#f9faf8', '#ffffff']:
                text_paths.extend(swiftui_commands)
            elif fill_attr == '#f0aa3e':
                dumbbell_paths.extend(swiftui_commands)

        # Also look for groups with fill attributes
        for group in root.findall('.//svg:g[@fill]', namespaces):
            fill_attr = group.get('fill', '')

            for path in group.findall('.//svg:path', namespaces):
                d_attr = path.get('d')
                if not d_attr:
                    continue

                swiftui_commands = parse_svg_path_to_swiftui(d_attr)

                if fill_attr in ['#f9faf8', '#ffffff']:
                    text_paths.extend(swiftui_commands)
                elif fill_attr == '#f0aa3e':
                    dumbbell_paths.extend(swiftui_commands)

    except Exception as e:
        print(f"Error parsing SVG: {e}")

    return {
        'text_paths': text_paths,
        'dumbbell_paths': dumbbell_paths
    }

def update_launch_screen(paths_data: Dict[str, List[str]], swift_file_path: str):
    """Update the LaunchScreenView.swift file with correct paths"""

    with open(swift_file_path, 'r') as f:
        content = f.read()

    # Generate the new path code
    text_path_code = "\n        ".join(paths_data['text_paths'])
    dumbbell_path_code = "\n        ".join(paths_data['dumbbell_paths'])

    # Find and replace the DumbbellShape implementation
    dumbbell_pattern = r'(struct DumbbellShape: Shape \{[\s\S]*?func path\(in rect: CGRect\) -> Path \{[\s\S]*?var path = Path\(\)[\s\S]*?)(return path\.applying.*?\}[\s\S]*?\})'

    def dumbbell_replacer(match):
        return (match.group(1).split('var path = Path()')[0] +
                'var path = Path()\n        // Extracted from actual logo SVG\n        ' +
                dumbbell_path_code + '\n\n        ' +
                match.group(2))

    content = re.sub(dumbbell_pattern, dumbbell_replacer, content, flags=re.DOTALL)

    # Find and replace the TrainLogoTextShape implementation
    text_pattern = r'(struct TrainLogoTextShape: Shape \{[\s\S]*?func path\(in rect: CGRect\) -> Path \{[\s\S]*?var path = Path\(\)[\s\S]*?)(return path\.applying.*?\}[\s\S]*?\})'

    def text_replacer(match):
        return (match.group(1).split('var path = Path()')[0] +
                'var path = Path()\n        // Extracted from actual logo SVG\n        ' +
                text_path_code + '\n\n        ' +
                match.group(2))

    content = re.sub(text_pattern, text_replacer, content, flags=re.DOTALL)

    # Write the updated content back
    with open(swift_file_path, 'w') as f:
        f.write(content)

    print(f"Successfully updated {swift_file_path}")

def main():
    svg_file = "/Users/lukevassor/Documents/trAIn-ios/assets/train-logo-with-text_isolate.svg"
    swift_file = "/Users/lukevassor/Documents/trAIn-ios/trAInSwift/Views/LaunchScreenView.swift"

    print("Extracting paths from isolated SVG...")
    paths_data = extract_logo_paths(svg_file)

    print(f"Found {len(paths_data['text_paths'])} text path commands")
    print(f"Found {len(paths_data['dumbbell_paths'])} dumbbell path commands")

    print("Updating LaunchScreenView.swift...")
    update_launch_screen(paths_data, swift_file)

    print("Launch screen updated with correct logo paths!")

if __name__ == "__main__":
    main()