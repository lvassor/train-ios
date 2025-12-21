#!/usr/bin/env python3
"""
Equipment Combination Analysis v3 - Coverage-Based Failure Definition
Failure = less than 50% of required exercise slots can be filled
Uses actual split templates to calculate realistic coverage.
"""

import sqlite3
import itertools
import json
from collections import defaultdict
import matplotlib.pyplot as plt
import numpy as np
from pathlib import Path

# Paths
DB_PATH = Path(__file__).parent.parent / "trAInSwift/Resources/exercises.db"
TEMPLATES_PATH = Path(__file__).parent.parent / "database-management/split_templates.json"

# Equipment categories
EQUIPMENT_CATEGORIES = [
    "Barbells", "Dumbbells", "Cables", "Kettlebells",
    "Pin-Loaded Machines", "Plate-Loaded Machines", "Other"
]

# Experience levels
EXPERIENCE_LEVELS = {
    "NO_EXPERIENCE": 1,
    "BEGINNER": 2,
    "INTERMEDIATE": 3,
    "ADVANCED": 4
}

def load_templates():
    """Load and parse split templates."""
    with open(TEMPLATES_PATH) as f:
        return json.load(f)

def parse_template_requirements(templates):
    """
    Parse templates to get muscle requirements.
    Returns dict of (duration, days) -> list of (muscle, count) tuples
    """
    requirements = {}

    for duration, day_configs in templates.items():
        for day_count, sessions in day_configs.items():
            total_requirements = defaultdict(int)

            for session_name, exercises in sessions.items():
                for exercise_spec in exercises:
                    # Parse "2 Back" -> (2, "Back")
                    parts = exercise_spec.split(" ", 1)
                    count = int(parts[0])
                    muscle = parts[1]

                    # Normalize muscle names
                    muscle_map = {
                        "Quad": "Quads",
                        "Hamstring": "Hamstrings",
                        "Glute": "Glutes",
                        "Tricep": "Triceps",
                        "Bicep": "Biceps"
                    }
                    muscle = muscle_map.get(muscle, muscle)
                    total_requirements[muscle] += count

            requirements[(duration, day_count)] = dict(total_requirements)

    return requirements

def get_exercise_counts(conn, equipment_list, max_complexity):
    """Get count of available exercises per muscle group."""
    cursor = conn.cursor()

    muscles = ["Chest", "Shoulders", "Back", "Quads", "Hamstrings",
               "Glutes", "Core", "Biceps", "Triceps"]

    muscle_counts = {}
    for muscle in muscles:
        placeholders = ','.join(['?' for _ in equipment_list])
        query = f"""
            SELECT COUNT(*) FROM exercises
            WHERE equipment_category IN ({placeholders})
            AND complexity_level <= ?
            AND primary_muscle = ?
            AND is_in_programme = 1
        """
        cursor.execute(query, equipment_list + [max_complexity, muscle])
        muscle_counts[muscle] = cursor.fetchone()[0]

    return muscle_counts

def calculate_coverage(muscle_counts, template_requirements):
    """
    Calculate what percentage of a template can be filled.
    Returns (slots_fillable, total_slots, coverage_pct)
    """
    total_slots = 0
    fillable_slots = 0

    for muscle, required in template_requirements.items():
        total_slots += required
        available = muscle_counts.get(muscle, 0)
        # Can fill up to min(required, available) slots
        fillable_slots += min(required, available)

    coverage_pct = (fillable_slots / total_slots * 100) if total_slots > 0 else 0
    return fillable_slots, total_slots, coverage_pct

def analyze_with_coverage(conn, templates):
    """Analyze equipment combinations using coverage-based failure."""

    template_reqs = parse_template_requirements(templates)

    # Use a representative template: 3-day, 45-60 min (common scenario)
    # Push: 2 Chest, 2 Shoulder, 1 Tricep
    # Pull: 3 Back, 2 Bicep
    # Legs: 2 Quad, 2 Hamstring, 1 Glute, 1 Core
    # Total: 16 exercises across 9 muscles
    representative_template = template_reqs[("45-60 minutes", "3-day")]

    results = {}

    for exp_level, max_complexity in [("NO_EXPERIENCE", 1), ("BEGINNER", 2)]:
        exp_results = {
            'by_equipment_count': defaultdict(list),
            'coverage_distribution': []
        }

        for r in range(1, len(EQUIPMENT_CATEGORIES) + 1):
            for combo in itertools.combinations(EQUIPMENT_CATEGORIES, r):
                equipment_list = list(combo)
                muscle_counts = get_exercise_counts(conn, equipment_list, max_complexity)

                fillable, total, coverage_pct = calculate_coverage(
                    muscle_counts, representative_template
                )

                exp_results['by_equipment_count'][r].append({
                    'equipment': equipment_list,
                    'muscle_counts': muscle_counts,
                    'fillable_slots': fillable,
                    'total_slots': total,
                    'coverage_pct': coverage_pct,
                    'is_failure': coverage_pct < 50  # New definition!
                })

                exp_results['coverage_distribution'].append(coverage_pct)

        results[exp_level] = exp_results

    return results, representative_template

def create_coverage_charts(results, template, output_dir):
    """Create visualization charts for coverage analysis."""

    fig, axes = plt.subplots(2, 3, figsize=(18, 12))
    fig.suptitle('Equipment Analysis: Coverage-Based Failure (< 50% = Failure)\n'
                 f'Template: 3-day PPL, 45-60 min ({sum(template.values())} total slots)',
                 fontsize=14, fontweight='bold')

    for idx, exp_level in enumerate(["NO_EXPERIENCE", "BEGINNER"]):
        data = results[exp_level]
        max_complexity = EXPERIENCE_LEVELS[exp_level]

        # Chart 1: Failure rate by equipment count
        ax1 = axes[idx, 0]
        eq_counts = sorted(data['by_equipment_count'].keys())

        failure_rates = []
        for c in eq_counts:
            combos = data['by_equipment_count'][c]
            fail_rate = sum(1 for x in combos if x['is_failure']) / len(combos) * 100
            failure_rates.append(fail_rate)

        colors = ['#ff6b6b' if r > 50 else '#ffd93d' if r > 20 else '#6bcb77' for r in failure_rates]
        bars = ax1.bar(eq_counts, failure_rates, color=colors, edgecolor='black')

        ax1.set_xlabel('Number of Equipment Categories')
        ax1.set_ylabel('Failure Rate (%)')
        ax1.set_title(f'{exp_level} (max_complexity={max_complexity})\nFailure Rate (<50% coverage)')
        ax1.set_ylim(0, 105)
        ax1.set_xticks(eq_counts)
        ax1.axhline(y=50, color='red', linestyle='--', alpha=0.5, label='50% threshold')

        for bar, rate in zip(bars, failure_rates):
            ax1.annotate(f'{rate:.0f}%', xy=(bar.get_x() + bar.get_width()/2, bar.get_height()),
                        xytext=(0, 3), textcoords="offset points", ha='center', fontsize=9)

        # Chart 2: Coverage distribution histogram
        ax2 = axes[idx, 1]
        coverages = data['coverage_distribution']

        ax2.hist(coverages, bins=20, range=(0, 100), color='#4ecdc4', edgecolor='black', alpha=0.7)
        ax2.axvline(x=50, color='red', linestyle='--', linewidth=2, label='Failure threshold')
        ax2.set_xlabel('Coverage (%)')
        ax2.set_ylabel('Number of Combinations')
        ax2.set_title(f'{exp_level}\nCoverage Distribution (all combinations)')
        ax2.legend()

        # Add stats
        mean_cov = np.mean(coverages)
        median_cov = np.median(coverages)
        ax2.axvline(x=mean_cov, color='blue', linestyle='-', alpha=0.5)
        ax2.text(mean_cov + 2, ax2.get_ylim()[1] * 0.9, f'Mean: {mean_cov:.0f}%', fontsize=9, color='blue')

        # Chart 3: Average coverage by equipment count
        ax3 = axes[idx, 2]

        avg_coverages = []
        min_coverages = []
        max_coverages = []

        for c in eq_counts:
            combos = data['by_equipment_count'][c]
            covs = [x['coverage_pct'] for x in combos]
            avg_coverages.append(np.mean(covs))
            min_coverages.append(np.min(covs))
            max_coverages.append(np.max(covs))

        ax3.fill_between(eq_counts, min_coverages, max_coverages, alpha=0.3, color='#4ecdc4')
        ax3.plot(eq_counts, avg_coverages, 'o-', color='#2d6a4f', linewidth=2, markersize=8, label='Average')
        ax3.plot(eq_counts, min_coverages, 's--', color='#ff6b6b', alpha=0.7, label='Minimum')
        ax3.plot(eq_counts, max_coverages, '^--', color='#6bcb77', alpha=0.7, label='Maximum')

        ax3.axhline(y=50, color='red', linestyle='--', alpha=0.5, label='Failure threshold')
        ax3.set_xlabel('Number of Equipment Categories')
        ax3.set_ylabel('Coverage (%)')
        ax3.set_title(f'{exp_level}\nCoverage Range by Equipment Count')
        ax3.set_ylim(0, 105)
        ax3.set_xticks(eq_counts)
        ax3.legend(loc='lower right', fontsize=8)

        for i, (avg, mn, mx) in enumerate(zip(avg_coverages, min_coverages, max_coverages)):
            ax3.annotate(f'{avg:.0f}%', xy=(eq_counts[i], avg), xytext=(5, 0),
                        textcoords="offset points", fontsize=8, color='#2d6a4f')

    plt.tight_layout()
    output_path = output_dir / "coverage_analysis.png"
    plt.savefig(output_path, dpi=150, bbox_inches='tight')
    print(f"✅ Saved coverage analysis to: {output_path}")

    return fig

def print_summary(results, template):
    """Print text summary."""

    print("\n" + "="*80)
    print("COVERAGE-BASED FAILURE ANALYSIS")
    print("="*80)
    print(f"\nTemplate: 3-day PPL, 45-60 minutes")
    print(f"Required exercises: {sum(template.values())} total")
    print(f"Muscles needed: {template}")
    print(f"\nFAILURE DEFINITION: Coverage < 50%")
    print("="*80)

    for exp_level in ["NO_EXPERIENCE", "BEGINNER"]:
        data = results[exp_level]
        max_complexity = EXPERIENCE_LEVELS[exp_level]

        print(f"\n{'─'*40}")
        print(f"Experience Level: {exp_level} (max_complexity={max_complexity})")
        print(f"{'─'*40}")

        print(f"\n{'Equip':<8} {'Fail Rate':<12} {'Avg Coverage':<15} {'Min-Max':<15}")
        print("-" * 50)

        for eq_count in sorted(data['by_equipment_count'].keys()):
            combos = data['by_equipment_count'][eq_count]
            total = len(combos)
            failures = sum(1 for x in combos if x['is_failure'])
            fail_rate = failures / total * 100

            coverages = [x['coverage_pct'] for x in combos]
            avg_cov = np.mean(coverages)
            min_cov = np.min(coverages)
            max_cov = np.max(coverages)

            print(f"{eq_count:<8} {fail_rate:>5.1f}% ({failures}/{total})  {avg_cov:>5.1f}%          {min_cov:.0f}%-{max_cov:.0f}%")

        # Show best single equipment options
        print(f"\n📊 Single Equipment Rankings:")
        single_combos = data['by_equipment_count'][1]
        sorted_combos = sorted(single_combos, key=lambda x: -x['coverage_pct'])

        for combo in sorted_combos:
            eq = combo['equipment'][0]
            cov = combo['coverage_pct']
            status = "✅" if cov >= 50 else "❌"
            print(f"   {status} {eq}: {cov:.0f}% coverage ({combo['fillable_slots']}/{combo['total_slots']} slots)")

def main():
    output_dir = Path(__file__).parent

    print("🔬 Loading templates and connecting to database...")
    templates = load_templates()
    conn = sqlite3.connect(DB_PATH)

    print("📊 Analyzing equipment combinations with coverage-based failure...")
    results, template = analyze_with_coverage(conn, templates)

    print_summary(results, template)

    print("\n📈 Generating visualizations...")
    create_coverage_charts(results, template, output_dir)

    conn.close()
    print("\n✅ Analysis complete!")

if __name__ == "__main__":
    main()
