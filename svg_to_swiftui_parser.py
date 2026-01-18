#!/usr/bin/env python3
"""
SVG to SwiftUI Path Converter
Extracts path data from SVG and converts to SwiftUI Path commands
"""

import re
import xml.etree.ElementTree as ET
from typing import List, Tuple, Dict

def parse_path_data(d_attr: str) -> List[str]:
    """Convert SVG path commands to SwiftUI equivalents"""
    swiftui_commands = []

    # Split path data into command segments
    commands = re.findall(r'[MmLlHhVvCcSsQqTtAaZz][^MmLlHhVvCcSsQqTtAaZz]*', d_attr)

    for cmd in commands:
        cmd = cmd.strip()
        if not cmd:
            continue

        command_type = cmd[0]
        params = re.findall(r'-?\d*\.?\d+', cmd[1:])
        params = [float(p) for p in params]

        if command_type in ['M', 'm']:  # Move to
            if len(params) >= 2:
                swiftui_commands.append(f"path.move(to: CGPoint(x: {params[0]}, y: {params[1]}))")
                # Handle subsequent coordinate pairs as line commands
                for i in range(2, len(params), 2):
                    if i + 1 < len(params):
                        if command_type == 'M':  # Absolute
                            swiftui_commands.append(f"path.addLine(to: CGPoint(x: {params[i]}, y: {params[i+1]}))")
                        else:  # Relative - would need current position tracking for full implementation
                            swiftui_commands.append(f"// Relative move: {params[i]}, {params[i+1]}")

        elif command_type in ['L', 'l']:  # Line to
            for i in range(0, len(params), 2):
                if i + 1 < len(params):
                    swiftui_commands.append(f"path.addLine(to: CGPoint(x: {params[i]}, y: {params[i+1]}))")

        elif command_type in ['C', 'c']:  # Cubic Bezier curve
            for i in range(0, len(params), 6):
                if i + 5 < len(params):
                    x1, y1, x2, y2, x, y = params[i:i+6]
                    swiftui_commands.append(f"path.addCurve(to: CGPoint(x: {x}, y: {y}), control1: CGPoint(x: {x1}, y: {y1}), control2: CGPoint(x: {x2}, y: {y2}))")

        elif command_type in ['Q', 'q']:  # Quadratic Bezier curve
            for i in range(0, len(params), 4):
                if i + 3 < len(params):
                    x1, y1, x, y = params[i:i+4]
                    swiftui_commands.append(f"path.addQuadCurve(to: CGPoint(x: {x}, y: {y}), control: CGPoint(x: {x1}, y: {y1}))")

        elif command_type in ['A', 'a']:  # Arc
            # Arcs are complex - for now add a comment
            swiftui_commands.append(f"// Arc command needs manual conversion: {cmd}")

        elif command_type in ['H', 'h']:  # Horizontal line
            for param in params:
                swiftui_commands.append(f"// Horizontal line to x: {param}")

        elif command_type in ['V', 'v']:  # Vertical line
            for param in params:
                swiftui_commands.append(f"// Vertical line to y: {param}")

        elif command_type in ['Z', 'z']:  # Close path
            swiftui_commands.append("path.closeSubpath()")

    return swiftui_commands

def extract_svg_paths(svg_file_path: str) -> Dict[str, List[str]]:
    """Extract path data from SVG file and categorize by fill color or context"""

    text_paths = []
    dumbbell_paths = []
    other_paths = []

    try:
        # Read file and use regex to find path elements since the XML might be complex
        with open(svg_file_path, 'r', encoding='utf-8') as f:
            content = f.read()

        # Look for multiple pattern types to catch all path variations
        patterns = [
            r'<path[^>]*d="([^"]+)"[^>]*fill="([^"]*)"[^>]*>',
            r'<path[^>]*fill="([^"]*)"[^>]*d="([^"]+)"[^>]*>',
            r'<path[^>]*d="([^"]+)"[^>]*>'
        ]

        all_paths = []
        for pattern in patterns:
            if 'fill=' in pattern:
                matches = re.findall(pattern, content, re.IGNORECASE)
                for match in matches:
                    if len(match) == 2:
                        # Check which order - d then fill or fill then d
                        if 'd=' in pattern.split('fill=')[0]:
                            all_paths.append((match[0], match[1]))  # d, fill
                        else:
                            all_paths.append((match[1], match[0]))  # d, fill
            else:
                matches = re.findall(pattern, content, re.IGNORECASE)
                for match in matches:
                    all_paths.append((match, ''))  # d, empty fill

        print(f"Found {len(all_paths)} path elements total")

        # Also search for fill colors in surrounding elements
        fill_searches = [
            (r'fill="#ffffff".*?<path[^>]*d="([^"]+)"', 'text'),
            (r'fill="#f0aa3e".*?<path[^>]*d="([^"]+)"', 'dumbbell'),
            (r'<g[^>]*fill="#ffffff"[^>]*>.*?<path[^>]*d="([^"]+)"', 'text'),
            (r'<g[^>]*fill="#f0aa3e"[^>]*>.*?<path[^>]*d="([^"]+)"', 'dumbbell')
        ]

        for pattern, category in fill_searches:
            matches = re.findall(pattern, content, re.DOTALL | re.IGNORECASE)
            print(f"Found {len(matches)} paths for {category} via pattern matching")
            for d_attr in matches:
                swiftui_commands = parse_path_data(d_attr)
                if category == 'text':
                    text_paths.extend(swiftui_commands)
                else:
                    dumbbell_paths.extend(swiftui_commands)

        # Process the direct path matches
        for d_attr, fill_attr in all_paths:
            if not d_attr:
                continue

            # Convert path data to SwiftUI commands
            swiftui_commands = parse_path_data(d_attr)

            # Categorize based on fill color
            if fill_attr == '#ffffff' or 'ffffff' in fill_attr:
                text_paths.extend(swiftui_commands)
                print(f"Added {len(swiftui_commands)} commands to text_paths (fill: {fill_attr})")
            elif fill_attr == '#f0aa3e' or 'f0aa3e' in fill_attr:
                dumbbell_paths.extend(swiftui_commands)
                print(f"Added {len(swiftui_commands)} commands to dumbbell_paths (fill: {fill_attr})")
            else:
                # Skip clipPath and simple geometric paths, focus on complex ones
                if len(swiftui_commands) > 10 and any('curve' in cmd.lower() for cmd in swiftui_commands):
                    other_paths.extend(swiftui_commands)
                    print(f"Added {len(swiftui_commands)} complex commands to other_paths")

        # Also try XML parsing as fallback
        try:
            root = ET.fromstring(content)
            xml_paths = root.findall('.//{http://www.w3.org/2000/svg}path')
            print(f"XML parser found {len(xml_paths)} additional paths")

            for path in xml_paths:
                d_attr = path.get('d')
                fill_attr = path.get('fill', '')

                if not d_attr:
                    continue

                swiftui_commands = parse_path_data(d_attr)

                if fill_attr == '#ffffff':
                    text_paths.extend(swiftui_commands)
                elif fill_attr == '#f0aa3e':
                    dumbbell_paths.extend(swiftui_commands)
                else:
                    other_paths.extend(swiftui_commands)

        except ET.ParseError:
            print("XML parsing failed, using regex results only")

    except Exception as e:
        print(f"Error parsing SVG: {e}")
        return {"text_paths": [], "dumbbell_paths": [], "other_paths": []}

    return {
        "text_paths": text_paths,
        "dumbbell_paths": dumbbell_paths,
        "other_paths": other_paths
    }

def generate_swiftui_shapes(paths_data: Dict[str, List[str]], template_file: str) -> str:
    """Generate SwiftUI shape code with extracted path data"""

    # Read the template file
    with open(template_file, 'r') as f:
        content = f.read()

    # Generate TrainTextShape path code
    text_shape_code = "\n        ".join(paths_data["text_paths"])
    if not text_shape_code:
        text_shape_code = "// No specific text paths found"

    # Generate DumbbellShape path code
    dumbbell_shape_code = "\n        ".join(paths_data["dumbbell_paths"])
    if not dumbbell_shape_code:
        dumbbell_shape_code = "// No specific dumbbell paths found"

    # Find and replace the TrainLogoTextShape path implementation
    train_text_pattern = r'(struct TrainLogoTextShape: Shape \{[\s\S]*?func path\(in rect: CGRect\) -> Path \{[\s\S]*?var path = Path\(\)[\s\S]*?)(return path\.applying.*?\})'

    train_text_replacement = r'\1' + text_shape_code + '\n\n        ' + r'\2'
    content = re.sub(train_text_pattern, train_text_replacement, content)

    # Find and replace the DumbbellShape path implementation
    dumbbell_pattern = r'(struct DumbbellShape: Shape \{[\s\S]*?func path\(in rect: CGRect\) -> Path \{[\s\S]*?var path = Path\(\)[\s\S]*?)(return path\.applying.*?\})'

    dumbbell_replacement = r'\1' + dumbbell_shape_code + '\n\n        ' + r'\2'
    content = re.sub(dumbbell_pattern, dumbbell_replacement, content)

    return content

def main():
    svg_file = "/Users/lukevassor/Documents/trAIn-ios/assets/train-logo-with-text.txt"
    template_file = "/Users/lukevassor/Documents/trAIn-ios/trAInSwift/Views/LaunchScreenView.swift"
    output_file = "/Users/lukevassor/Documents/trAIn-ios/trAInSwift/Views/LaunchScreenView.swift"

    print("Extracting SVG path data...")
    paths_data = extract_svg_paths(svg_file)

    print(f"Found {len(paths_data['text_paths'])} text path commands")
    print(f"Found {len(paths_data['dumbbell_paths'])} dumbbell path commands")
    print(f"Found {len(paths_data['other_paths'])} other path commands")

    print("Generating SwiftUI code...")
    updated_content = generate_swiftui_shapes(paths_data, template_file)

    # Write updated file
    with open(output_file, 'w') as f:
        f.write(updated_content)

    print(f"Updated LaunchScreenView.swift with extracted path data")

    # Also output the raw path data for inspection
    print("\n=== TEXT PATHS ===")
    for cmd in paths_data['text_paths'][:10]:  # First 10 for preview
        print(cmd)

    print("\n=== DUMBBELL PATHS ===")
    for cmd in paths_data['dumbbell_paths'][:10]:  # First 10 for preview
        print(cmd)

    if paths_data['other_paths']:
        print(f"\n=== OTHER PATHS ({len(paths_data['other_paths'])}) ===")
        for cmd in paths_data['other_paths'][:5]:  # First 5 for preview
            print(cmd)

if __name__ == "__main__":
    main()