"""
report.py - Summary report generation for simulation results
"""

from typing import List, Dict, Any
from collections import Counter


def generate_summary_report(results: List[Dict[str, Any]]) -> str:
    """
    Generate a summary report from simulation results.

    Results format:
    [
        {
            'simulation_id': int,
            'experience_level': str,
            'equipment_list': str,
            'days_per_week': int,
            'session_duration': str,
            'goal': str,
            'focus_muscle': str,
            'excluded_muscles': str,
            'status': str,
            'error_details': str,
            'total_slots_required': int,
            'total_slots_filled': int,
            'fill_rate_pct': float,
            'sessions_generated': str,
            'exercises_selected': str
        },
        ...
    ]
    """
    total = len(results)
    if total == 0:
        return "No simulations to report."

    # Count statuses
    status_counts = Counter(r['status'] for r in results)

    # Calculate percentages
    success_count = status_counts.get('SUCCESS', 0)
    success_pct = (success_count / total) * 100

    # Find failure patterns
    failures = [r for r in results if r['status'] != 'SUCCESS']

    # Equipment failure patterns
    equipment_failures = Counter()
    for r in failures:
        equipment_failures[r['equipment_list']] += 1

    # Muscle failure patterns (from error details)
    muscle_failures = Counter()
    for r in failures:
        if r['error_details']:
            # Extract muscle names from error details
            details = r['error_details']
            if 'No exercises for:' in details:
                muscles = details.split('No exercises for:')[1].strip()
                for muscle in muscles.split(','):
                    muscle_failures[muscle.strip()] += 1

    # Experience level failures
    exp_failures = Counter()
    for r in failures:
        exp_failures[r['experience_level']] += 1

    # Build report
    lines = [
        "=" * 50,
        "SIMULATION REPORT",
        "=" * 50,
        "",
        f"Total simulations: {total}",
        f"Successful: {success_count} ({success_pct:.1f}%)",
        "",
        "Errors:"
    ]

    for status, count in sorted(status_counts.items()):
        if status != 'SUCCESS':
            pct = (count / total) * 100
            lines.append(f"  {status}: {count} ({pct:.1f}%)")

    if failures:
        lines.extend([
            "",
            "Most common failure equipment combinations:"
        ])
        for equip, count in equipment_failures.most_common(5):
            lines.append(f"  [{equip}]: {count} failures")

        if muscle_failures:
            lines.extend([
                "",
                "Most common failure muscles:"
            ])
            for muscle, count in muscle_failures.most_common(5):
                lines.append(f"  {muscle}: {count} failures")

        lines.extend([
            "",
            "Failures by experience level:"
        ])
        for exp, count in exp_failures.most_common():
            lines.append(f"  {exp}: {count} failures")

    lines.append("")
    lines.append("=" * 50)

    return "\n".join(lines)


def print_sample_results(results: List[Dict[str, Any]], n: int = 5):
    """Print a sample of results for manual verification"""
    print("\n" + "=" * 50)
    print(f"SAMPLE RESULTS (first {n})")
    print("=" * 50)

    for i, r in enumerate(results[:n]):
        print(f"\nSimulation {r['simulation_id']}:")
        print(f"  Experience: {r['experience_level']}")
        print(f"  Equipment: {r['equipment_list']}")
        print(f"  Days/week: {r['days_per_week']}")
        print(f"  Duration: {r['session_duration']}")
        print(f"  Status: {r['status']}")
        if r['error_details']:
            print(f"  Error: {r['error_details']}")
        print(f"  Fill rate: {r['fill_rate_pct']:.1f}%")
        print(f"  Sessions: {r['sessions_generated']}")
