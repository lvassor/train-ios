#!/usr/bin/env python3
"""
Master script to generate all flowcharts for the trAIn app documentation.
Outputs PDFs to the ../flows/ directory.

Requirements:
    pip install graphviz

Usage:
    python generate_all_flowcharts.py
"""

import subprocess
import sys
import os

def main():
    print("=" * 60)
    print("trAIn App Flowchart Generator")
    print("=" * 60)

    # Get directory of this script
    script_dir = os.path.dirname(os.path.abspath(__file__))
    flows_dir = os.path.join(script_dir, '..', 'flows')

    # Ensure flows directory exists
    os.makedirs(flows_dir, exist_ok=True)
    print(f"\n📁 Output directory: {flows_dir}")

    # Scripts to run
    scripts = [
        ('generate_program_flowchart.py', 'Programme Generation Flowchart'),
        ('generate_database_flowchart.py', 'Database Generation Flowchart'),
        ('generate_questionnaire_flowchart.py', 'Questionnaire Flow'),
        ('generate_dashboard_navigation.py', 'Dashboard Navigation Map'),
    ]

    success_count = 0
    failed = []

    print("\n🔧 Generating flowcharts...\n")

    for script_name, description in scripts:
        script_path = os.path.join(script_dir, script_name)
        print(f"  → {description}...")

        try:
            result = subprocess.run(
                [sys.executable, script_path],
                capture_output=True,
                text=True,
                cwd=script_dir
            )

            if result.returncode == 0:
                print(f"    ✅ Success")
                success_count += 1
            else:
                print(f"    ❌ Failed: {result.stderr.strip()}")
                failed.append((description, result.stderr))

        except Exception as e:
            print(f"    ❌ Error: {e}")
            failed.append((description, str(e)))

    print("\n" + "=" * 60)
    print(f"SUMMARY: {success_count}/{len(scripts)} flowcharts generated")
    print("=" * 60)

    if failed:
        print("\n❌ Failed flowcharts:")
        for name, error in failed:
            print(f"  - {name}: {error[:100]}")

    print(f"\n📄 Output files in: {flows_dir}")
    print("   - program_generation_flowchart.pdf")
    print("   - database_generation_flowchart.pdf")
    print("   - database_schema.pdf")
    print("   - questionnaire_flowchart.pdf")
    print("   - dashboard_navigation_map.pdf")
    print()

if __name__ == '__main__':
    main()
