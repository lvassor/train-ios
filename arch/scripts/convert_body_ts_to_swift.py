#!/usr/bin/env python3
"""
Convert react-native-body-highlighter TypeScript body data to Swift format.

Usage:
    python convert_body_ts_to_swift.py <input_ts_file> <output_variable_name>

Example:
    python convert_body_ts_to_swift.py bodyFront.ts maleFront
    python convert_body_ts_to_swift.py bodyFemaleFront.ts femaleFront
"""

import re
import sys
import json
from pathlib import Path


def extract_body_parts(ts_content: str) -> list[dict]:
    """Extract body parts from TypeScript file content."""
    body_parts = []

    # Find the array content between the first [ and last ]
    array_match = re.search(r':\s*BodyPart\[\]\s*=\s*\[(.*)\];?\s*$', ts_content, re.DOTALL)
    if not array_match:
        raise ValueError("Could not find BodyPart array in file")

    array_content = array_match.group(1)

    # Parse each body part object
    # Split by closing brace followed by comma and opening brace pattern for objects
    # We need to handle nested braces properly

    current_part = ""
    brace_count = 0
    in_object = False

    for char in array_content:
        if char == '{':
            brace_count += 1
            in_object = True
            current_part += char
        elif char == '}':
            brace_count -= 1
            current_part += char
            if brace_count == 0 and in_object:
                # End of a body part object
                body_parts.append(parse_body_part(current_part.strip()))
                current_part = ""
                in_object = False
        elif in_object:
            current_part += char

    return body_parts


def parse_body_part(obj_str: str) -> dict:
    """Parse a single body part object string."""
    result = {
        'slug': '',
        'color': '#3f3f3f',
        'paths': {
            'common': [],
            'left': [],
            'right': []
        }
    }

    # Extract slug
    slug_match = re.search(r'slug:\s*["\']([^"\']+)["\']', obj_str)
    if slug_match:
        result['slug'] = slug_match.group(1)

    # Extract color
    color_match = re.search(r'color:\s*["\']([^"\']+)["\']', obj_str)
    if color_match:
        result['color'] = color_match.group(1)

    # Extract path object
    path_match = re.search(r'path:\s*\{([^}]*(?:\{[^}]*\}[^}]*)*)\}', obj_str, re.DOTALL)
    if path_match:
        path_content = path_match.group(1)

        # Extract common paths
        common_paths = extract_path_array(path_content, 'common')
        if common_paths:
            result['paths']['common'] = common_paths

        # Extract left paths
        left_paths = extract_path_array(path_content, 'left')
        if left_paths:
            result['paths']['left'] = left_paths

        # Extract right paths
        right_paths = extract_path_array(path_content, 'right')
        if right_paths:
            result['paths']['right'] = right_paths

    return result


def extract_path_array(path_content: str, key: str) -> list[str]:
    """Extract an array of path strings for a given key (common, left, right)."""
    paths = []

    # Find the array for this key
    pattern = rf'{key}:\s*\[(.*?)\]'
    match = re.search(pattern, path_content, re.DOTALL)

    if match:
        array_content = match.group(1)
        # Extract all quoted strings (handling both single and double quotes)
        # SVG paths can contain quotes so we need to be careful
        string_pattern = r'["\']([^"\']+)["\']'
        paths = re.findall(string_pattern, array_content)

    return paths


def slug_to_swift_case(slug: str) -> str:
    """Convert a slug to Swift enum case name."""
    # Handle hyphenated slugs
    if '-' in slug:
        parts = slug.split('-')
        # Convert to camelCase
        return parts[0] + ''.join(p.capitalize() for p in parts[1:])
    return slug


def generate_swift_output(body_parts: list[dict], variable_name: str) -> str:
    """Generate Swift code from parsed body parts."""
    lines = []
    lines.append(f"    static let {variable_name}: [MusclePart] = [")

    for i, part in enumerate(body_parts):
        slug = part['slug']
        swift_slug = slug_to_swift_case(slug)
        color = part['color']
        paths = part['paths']

        lines.append(f"        // {slug.replace('-', ' ').title()}")
        lines.append("        MusclePart(")
        lines.append(f"            slug: .{swift_slug},")
        lines.append("            paths: MusclePaths(")

        # Build paths parameters
        path_params = []

        if paths['common']:
            common_strs = ',\n                    '.join(f'"{p}"' for p in paths['common'])
            path_params.append(f"                common: [\n                    {common_strs}\n                ]")

        if paths['left']:
            left_strs = ',\n                    '.join(f'"{p}"' for p in paths['left'])
            path_params.append(f"                left: [\n                    {left_strs}\n                ]")

        if paths['right']:
            right_strs = ',\n                    '.join(f'"{p}"' for p in paths['right'])
            path_params.append(f"                right: [\n                    {right_strs}\n                ]")

        lines.append(',\n'.join(path_params))
        lines.append("            )")

        # Add color if not default
        if color != "#3f3f3f":
            lines[-1] = lines[-1].rstrip() + ","
            lines.append(f'            defaultColor: "{color}"')

        # Close MusclePart
        if i < len(body_parts) - 1:
            lines.append("        ),\n")
        else:
            lines.append("        )")

    lines.append("    ]")

    return '\n'.join(lines)


def compare_slugs(ts_file: Path, swift_parts: list[dict] = None) -> dict:
    """Compare slugs between TypeScript and existing Swift data."""
    with open(ts_file, 'r') as f:
        content = f.read()

    body_parts = extract_body_parts(content)
    ts_slugs = {p['slug'] for p in body_parts}

    return {
        'file': ts_file.name,
        'slugs': sorted(ts_slugs),
        'count': len(ts_slugs)
    }


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        print("\nAvailable commands:")
        print("  convert <input_ts_file> <output_variable_name>  - Convert TS to Swift")
        print("  list <input_ts_file>                            - List all slugs in file")
        print("  compare <ts_file1> <ts_file2>                   - Compare slugs between files")
        sys.exit(1)

    command = sys.argv[1]

    if command == "list":
        if len(sys.argv) < 3:
            print("Usage: python convert_body_ts_to_swift.py list <input_ts_file>")
            sys.exit(1)

        ts_file = Path(sys.argv[2])
        if not ts_file.exists():
            print(f"Error: File not found: {ts_file}")
            sys.exit(1)

        result = compare_slugs(ts_file)
        print(f"\nSlugs in {result['file']} ({result['count']} total):")
        for slug in result['slugs']:
            print(f"  - {slug}")

    elif command == "compare":
        if len(sys.argv) < 4:
            print("Usage: python convert_body_ts_to_swift.py compare <ts_file1> <ts_file2>")
            sys.exit(1)

        file1 = Path(sys.argv[2])
        file2 = Path(sys.argv[3])

        result1 = compare_slugs(file1)
        result2 = compare_slugs(file2)

        slugs1 = set(result1['slugs'])
        slugs2 = set(result2['slugs'])

        common = slugs1 & slugs2
        only_in_1 = slugs1 - slugs2
        only_in_2 = slugs2 - slugs1

        print(f"\n{result1['file']}: {result1['count']} slugs")
        print(f"{result2['file']}: {result2['count']} slugs")
        print(f"\nCommon ({len(common)}): {sorted(common)}")
        print(f"Only in {result1['file']} ({len(only_in_1)}): {sorted(only_in_1)}")
        print(f"Only in {result2['file']} ({len(only_in_2)}): {sorted(only_in_2)}")

    elif command == "convert":
        if len(sys.argv) < 4:
            print("Usage: python convert_body_ts_to_swift.py convert <input_ts_file> <output_variable_name>")
            sys.exit(1)

        ts_file = Path(sys.argv[2])
        variable_name = sys.argv[3]

        if not ts_file.exists():
            print(f"Error: File not found: {ts_file}")
            sys.exit(1)

        with open(ts_file, 'r') as f:
            content = f.read()

        body_parts = extract_body_parts(content)
        swift_code = generate_swift_output(body_parts, variable_name)

        print(swift_code)

        # Also print slug summary
        print(f"\n// Converted {len(body_parts)} body parts:")
        for part in body_parts:
            print(f"//   - {part['slug']}")

    else:
        # Default: treat first arg as file, second as variable name (legacy behavior)
        ts_file = Path(sys.argv[1])
        variable_name = sys.argv[2] if len(sys.argv) > 2 else "bodyData"

        if not ts_file.exists():
            print(f"Error: File not found: {ts_file}")
            sys.exit(1)

        with open(ts_file, 'r') as f:
            content = f.read()

        body_parts = extract_body_parts(content)
        swift_code = generate_swift_output(body_parts, variable_name)

        print(swift_code)


if __name__ == "__main__":
    main()
