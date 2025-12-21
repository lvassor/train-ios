#!/usr/bin/env python3
"""
Equipment Combination Analysis v2 - With Isolation Bypass Fix
Compares current behavior (broken) vs correct behavior (isolation bypass)
"""

import sqlite3
import itertools
from collections import defaultdict
import matplotlib.pyplot as plt
import numpy as np
from pathlib import Path

# Database path
DB_PATH = Path(__file__).parent.parent / "trAInSwift/Resources/exercises.db"

# Equipment categories
EQUIPMENT_CATEGORIES = [
    "Barbells", "Dumbbells", "Cables", "Kettlebells",
    "Pin-Loaded Machines", "Plate-Loaded Machines", "Other"
]

# Required muscle groups
REQUIRED_MUSCLES = [
    "Chest", "Shoulders", "Back", "Quads", "Hamstrings",
    "Glutes", "Core", "Biceps", "Triceps"
]

# Experience levels
EXPERIENCE_LEVELS = {
    "NO_EXPERIENCE": 1,
    "BEGINNER": 2,
    "INTERMEDIATE": 3,
    "ADVANCED": 4
}

def get_exercise_counts_current(conn, equipment_list, max_complexity):
    """CURRENT (BROKEN): Filters ALL exercises by complexity, including isolations."""
    cursor = conn.cursor()
    muscle_counts = {}

    for muscle in REQUIRED_MUSCLES:
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

def get_exercise_counts_fixed(conn, equipment_list, max_complexity):
    """FIXED: Isolations bypass complexity filter (per BUSINESS_RULES.md)."""
    cursor = conn.cursor()
    muscle_counts = {}

    for muscle in REQUIRED_MUSCLES:
        placeholders = ','.join(['?' for _ in equipment_list])
        # Isolation exercises bypass complexity rules
        query = f"""
            SELECT COUNT(*) FROM exercises
            WHERE equipment_category IN ({placeholders})
            AND (
                is_isolation = 1  -- Isolations always allowed
                OR complexity_level <= ?  -- Compounds follow complexity rules
            )
            AND primary_muscle = ?
            AND is_in_programme = 1
        """
        cursor.execute(query, equipment_list + [max_complexity, muscle])
        muscle_counts[muscle] = cursor.fetchone()[0]

    return muscle_counts

def analyze_both_methods(conn, experience_level, max_complexity):
    """Analyze using both current and fixed methods."""
    results = {
        'current': {'by_equipment_count': defaultdict(list)},
        'fixed': {'by_equipment_count': defaultdict(list)}
    }

    for r in range(1, len(EQUIPMENT_CATEGORIES) + 1):
        for combo in itertools.combinations(EQUIPMENT_CATEGORIES, r):
            equipment_list = list(combo)

            # Current (broken) behavior
            counts_current = get_exercise_counts_current(conn, equipment_list, max_complexity)
            empty_current = [m for m, c in counts_current.items() if c == 0]

            # Fixed behavior
            counts_fixed = get_exercise_counts_fixed(conn, equipment_list, max_complexity)
            empty_fixed = [m for m, c in counts_fixed.items() if c == 0]

            results['current']['by_equipment_count'][r].append({
                'equipment': equipment_list,
                'empty_muscles': empty_current,
                'empty_count': len(empty_current),
                'has_failure': len(empty_current) > 0
            })

            results['fixed']['by_equipment_count'][r].append({
                'equipment': equipment_list,
                'empty_muscles': empty_fixed,
                'empty_count': len(empty_fixed),
                'has_failure': len(empty_fixed) > 0
            })

    return results

def create_comparison_chart(report_data, output_path):
    """Create comparison chart showing current vs fixed behavior."""

    fig, axes = plt.subplots(2, 2, figsize=(16, 12))
    fig.suptitle('Impact of Isolation Bypass Fix on Failure Rates', fontsize=16, fontweight='bold')

    for idx, exp_level in enumerate(["NO_EXPERIENCE", "BEGINNER"]):
        data = report_data[exp_level]
        max_complexity = EXPERIENCE_LEVELS[exp_level]

        # Left column: Failure rates comparison
        ax1 = axes[idx, 0]
        eq_counts = sorted(data['current']['by_equipment_count'].keys())

        current_rates = []
        fixed_rates = []

        for c in eq_counts:
            current_combos = data['current']['by_equipment_count'][c]
            fixed_combos = data['fixed']['by_equipment_count'][c]

            current_rate = sum(1 for x in current_combos if x['has_failure']) / len(current_combos) * 100
            fixed_rate = sum(1 for x in fixed_combos if x['has_failure']) / len(fixed_combos) * 100

            current_rates.append(current_rate)
            fixed_rates.append(fixed_rate)

        x = np.arange(len(eq_counts))
        width = 0.35

        bars1 = ax1.bar(x - width/2, current_rates, width, label='Current (Bug)', color='#ff6b6b', edgecolor='black')
        bars2 = ax1.bar(x + width/2, fixed_rates, width, label='Fixed (Isolation Bypass)', color='#6bcb77', edgecolor='black')

        ax1.set_xlabel('Number of Equipment Categories')
        ax1.set_ylabel('Failure Rate (%)')
        ax1.set_title(f'{exp_level} (max_complexity={max_complexity})\nFailure Rate: Current vs Fixed')
        ax1.set_xticks(x)
        ax1.set_xticklabels(eq_counts)
        ax1.legend()
        ax1.set_ylim(0, 105)

        # Add value labels
        for bar, rate in zip(bars1, current_rates):
            if rate > 0:
                ax1.annotate(f'{rate:.0f}%', xy=(bar.get_x() + bar.get_width()/2, bar.get_height()),
                            xytext=(0, 3), textcoords="offset points", ha='center', va='bottom', fontsize=8, color='#cc0000')

        for bar, rate in zip(bars2, fixed_rates):
            ax1.annotate(f'{rate:.0f}%', xy=(bar.get_x() + bar.get_width()/2, bar.get_height()),
                        xytext=(0, 3), textcoords="offset points", ha='center', va='bottom', fontsize=8, color='#228B22')

        # Right column: Improvement delta
        ax2 = axes[idx, 1]
        improvements = [c - f for c, f in zip(current_rates, fixed_rates)]

        colors = ['#4ecdc4' if imp > 0 else '#ffcccc' for imp in improvements]
        bars = ax2.bar(eq_counts, improvements, color=colors, edgecolor='black')

        ax2.set_xlabel('Number of Equipment Categories')
        ax2.set_ylabel('Improvement (percentage points)')
        ax2.set_title(f'{exp_level}\nFailure Rate Reduction After Fix')
        ax2.axhline(y=0, color='black', linestyle='-', linewidth=0.5)

        for bar, imp in zip(bars, improvements):
            if imp > 0:
                ax2.annotate(f'-{imp:.0f}pp', xy=(bar.get_x() + bar.get_width()/2, bar.get_height()),
                            xytext=(0, 3), textcoords="offset points", ha='center', va='bottom', fontsize=9, fontweight='bold')

    plt.tight_layout()
    plt.savefig(output_path, dpi=150, bbox_inches='tight')
    print(f"✅ Saved comparison chart to: {output_path}")

    return fig

def create_muscle_heatmap_comparison(conn, output_path):
    """Create heatmap comparing exercise availability with and without fix."""

    fig, axes = plt.subplots(2, 2, figsize=(18, 14))
    fig.suptitle('Single Equipment Exercise Availability: Current vs Fixed', fontsize=16, fontweight='bold')

    for idx, (exp_level, max_complexity) in enumerate([("NO_EXPERIENCE", 1), ("BEGINNER", 2)]):
        for col, (method, get_counts, title) in enumerate([
            ("current", lambda eq: get_exercise_counts_current(conn, [eq], max_complexity), "Current (Bug)"),
            ("fixed", lambda eq: get_exercise_counts_fixed(conn, [eq], max_complexity), "Fixed (Isolation Bypass)")
        ]):
            ax = axes[idx, col]

            matrix = np.zeros((len(EQUIPMENT_CATEGORIES), len(REQUIRED_MUSCLES)))

            for i, eq in enumerate(EQUIPMENT_CATEGORIES):
                counts = get_counts(eq)
                for j, muscle in enumerate(REQUIRED_MUSCLES):
                    matrix[i, j] = counts[muscle]

            im = ax.imshow(matrix, cmap='RdYlGn', aspect='auto', vmin=0, vmax=10)

            for i in range(len(EQUIPMENT_CATEGORIES)):
                for j in range(len(REQUIRED_MUSCLES)):
                    value = int(matrix[i, j])
                    color = 'white' if value <= 2 else 'black'
                    ax.text(j, i, str(value), ha='center', va='center', color=color, fontsize=9, fontweight='bold' if value == 0 else 'normal')

            ax.set_xticks(range(len(REQUIRED_MUSCLES)))
            ax.set_xticklabels(REQUIRED_MUSCLES, rotation=45, ha='right')
            ax.set_yticks(range(len(EQUIPMENT_CATEGORIES)))
            ax.set_yticklabels(EQUIPMENT_CATEGORIES)
            ax.set_title(f'{exp_level} - {title}')

            cbar = plt.colorbar(im, ax=ax, shrink=0.8)
            cbar.set_label('Exercise Count')

    plt.tight_layout()
    plt.savefig(output_path, dpi=150, bbox_inches='tight')
    print(f"✅ Saved heatmap comparison to: {output_path}")

    return fig

def print_summary(report_data):
    """Print text summary."""

    print("\n" + "="*80)
    print("ISOLATION BYPASS FIX ANALYSIS")
    print("="*80)
    print("\nBUG: ExerciseDatabaseManager.swift filters ALL exercises by complexity,")
    print("     but BUSINESS_RULES.md says isolations should BYPASS complexity rules.")
    print("="*80)

    for exp_level in ["NO_EXPERIENCE", "BEGINNER"]:
        data = report_data[exp_level]
        max_complexity = EXPERIENCE_LEVELS[exp_level]

        print(f"\n{'─'*40}")
        print(f"Experience Level: {exp_level} (max_complexity={max_complexity})")
        print(f"{'─'*40}")

        print(f"\n{'Equip':<8} {'Current':<15} {'Fixed':<15} {'Improvement':<12}")
        print("-" * 50)

        for eq_count in sorted(data['current']['by_equipment_count'].keys()):
            current_combos = data['current']['by_equipment_count'][eq_count]
            fixed_combos = data['fixed']['by_equipment_count'][eq_count]

            total = len(current_combos)
            current_fails = sum(1 for x in current_combos if x['has_failure'])
            fixed_fails = sum(1 for x in fixed_combos if x['has_failure'])

            current_rate = current_fails / total * 100
            fixed_rate = fixed_fails / total * 100
            improvement = current_rate - fixed_rate

            print(f"{eq_count:<8} {current_rate:>5.1f}% ({current_fails}/{total})   {fixed_rate:>5.1f}% ({fixed_fails}/{total})   {improvement:>+5.1f}pp")

        # Show single-equipment details
        print(f"\n⚠️  Single Equipment Details:")
        for result in data['current']['by_equipment_count'][1]:
            eq = result['equipment'][0]
            current_empty = len(result['empty_muscles'])

            # Find matching fixed result
            fixed_result = next(r for r in data['fixed']['by_equipment_count'][1] if r['equipment'][0] == eq)
            fixed_empty = len(fixed_result['empty_muscles'])

            if current_empty > 0:
                print(f"   • {eq}: {current_empty} → {fixed_empty} empty muscles")
                if fixed_empty < current_empty:
                    saved = set(result['empty_muscles']) - set(fixed_result['empty_muscles'])
                    print(f"     ✅ Fix adds: {', '.join(saved)}")

def main():
    output_dir = Path(__file__).parent
    output_dir.mkdir(exist_ok=True)

    print("🔬 Connecting to database...")
    conn = sqlite3.connect(DB_PATH)

    print("📊 Analyzing equipment combinations...")
    report_data = {}

    for exp_level in ["NO_EXPERIENCE", "BEGINNER"]:
        max_complexity = EXPERIENCE_LEVELS[exp_level]
        report_data[exp_level] = analyze_both_methods(conn, exp_level, max_complexity)

    print_summary(report_data)

    print("\n📈 Generating visualizations...")

    comparison_path = output_dir / "isolation_fix_comparison.png"
    create_comparison_chart(report_data, comparison_path)

    heatmap_path = output_dir / "isolation_fix_heatmap.png"
    create_muscle_heatmap_comparison(conn, heatmap_path)

    conn.close()

    print("\n" + "="*80)
    print("RECOMMENDED FIX:")
    print("="*80)
    print("""
In ExerciseDatabaseManager.swift line 133, change:

    // Filter by max complexity
    query = query.filter(Column("complexity_level") <= filter.maxComplexity)

To:

    // Filter by max complexity (isolations bypass this per BUSINESS_RULES.md)
    query = query.filter(
        Column("is_isolation") == 1 ||
        Column("complexity_level") <= filter.maxComplexity
    )
""")

    print(f"\n✅ Analysis complete!")
    print(f"   Comparison chart: {comparison_path}")
    print(f"   Heatmap: {heatmap_path}")

if __name__ == "__main__":
    main()
