#!/usr/bin/env python3
"""
Equipment Combination Analysis for Program Generation
Analyzes failure rates for NO_EXPERIENCE and BEGINNER users
with different equipment combinations.
"""

import sqlite3
import itertools
from collections import defaultdict
import matplotlib.pyplot as plt
import numpy as np
from pathlib import Path

# Database path
DB_PATH = Path(__file__).parent.parent / "trAInSwift/Resources/exercises.db"

# Equipment categories (matching the app)
EQUIPMENT_CATEGORIES = [
    "Barbells",
    "Dumbbells",
    "Cables",
    "Kettlebells",
    "Pin-Loaded Machines",
    "Plate-Loaded Machines",
    "Other"
]

# Muscle groups required by session templates
# These are the muscles that MUST have at least 1 exercise available
REQUIRED_MUSCLES = [
    "Chest",
    "Shoulders",
    "Back",
    "Quads",
    "Hamstrings",
    "Glutes",
    "Core",
    "Biceps",
    "Triceps"
]

# Experience levels and their max complexity
EXPERIENCE_LEVELS = {
    "NO_EXPERIENCE": 1,
    "BEGINNER": 2,
    "INTERMEDIATE": 3,
    "ADVANCED": 4
}

def get_exercise_counts(conn, equipment_list, max_complexity):
    """
    Get count of available exercises per muscle group for given equipment and complexity.
    """
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
        count = cursor.fetchone()[0]
        muscle_counts[muscle] = count

    return muscle_counts

def analyze_equipment_combinations(conn, experience_level, max_complexity):
    """
    Analyze all possible equipment combinations for a given experience level.
    Returns statistics about empty muscle groups.
    """
    results = {
        'by_equipment_count': defaultdict(list),  # num_equipment -> list of (combo, empty_muscles)
        'all_combinations': []
    }

    # Generate all possible non-empty subsets of equipment
    for r in range(1, len(EQUIPMENT_CATEGORIES) + 1):
        for combo in itertools.combinations(EQUIPMENT_CATEGORIES, r):
            equipment_list = list(combo)
            muscle_counts = get_exercise_counts(conn, equipment_list, max_complexity)

            # Count muscles with 0 exercises
            empty_muscles = [m for m, c in muscle_counts.items() if c == 0]
            insufficient_muscles = [m for m, c in muscle_counts.items() if 0 < c < 2]

            result = {
                'equipment': equipment_list,
                'equipment_count': len(equipment_list),
                'muscle_counts': muscle_counts,
                'empty_muscles': empty_muscles,
                'insufficient_muscles': insufficient_muscles,
                'empty_count': len(empty_muscles),
                'has_failure': len(empty_muscles) > 0
            }

            results['by_equipment_count'][r].append(result)
            results['all_combinations'].append(result)

    return results

def generate_analysis_report(conn):
    """Generate full analysis for NO_EXPERIENCE and BEGINNER."""

    report_data = {}

    for exp_level in ["NO_EXPERIENCE", "BEGINNER"]:
        max_complexity = EXPERIENCE_LEVELS[exp_level]
        results = analyze_equipment_combinations(conn, exp_level, max_complexity)

        # Calculate statistics
        stats = {
            'experience_level': exp_level,
            'max_complexity': max_complexity,
            'by_equipment_count': {}
        }

        for eq_count, combos in results['by_equipment_count'].items():
            total = len(combos)
            failures = sum(1 for c in combos if c['has_failure'])
            failure_rate = failures / total * 100 if total > 0 else 0

            # Distribution of empty muscle counts
            empty_distribution = defaultdict(int)
            for c in combos:
                empty_distribution[c['empty_count']] += 1

            stats['by_equipment_count'][eq_count] = {
                'total_combinations': total,
                'failures': failures,
                'failure_rate': failure_rate,
                'empty_distribution': dict(empty_distribution),
                'worst_combos': sorted(combos, key=lambda x: -x['empty_count'])[:5]
            }

        report_data[exp_level] = {
            'stats': stats,
            'raw_results': results
        }

    return report_data

def create_histogram(report_data, output_path):
    """Create histogram visualization."""

    fig, axes = plt.subplots(2, 2, figsize=(14, 10))
    fig.suptitle('Equipment Combination Analysis: Empty Muscle Groups by Experience Level',
                 fontsize=14, fontweight='bold')

    for idx, exp_level in enumerate(["NO_EXPERIENCE", "BEGINNER"]):
        data = report_data[exp_level]
        stats = data['stats']

        # Left plot: Failure rate by equipment count
        ax1 = axes[idx, 0]
        eq_counts = sorted(stats['by_equipment_count'].keys())
        failure_rates = [stats['by_equipment_count'][c]['failure_rate'] for c in eq_counts]

        colors = ['#ff6b6b' if r > 50 else '#ffd93d' if r > 20 else '#6bcb77' for r in failure_rates]
        bars = ax1.bar(eq_counts, failure_rates, color=colors, edgecolor='black', linewidth=0.5)

        ax1.set_xlabel('Number of Equipment Categories Selected')
        ax1.set_ylabel('Failure Rate (%)')
        ax1.set_title(f'{exp_level} (max complexity={stats["max_complexity"]})\nFailure Rate by Equipment Count')
        ax1.set_ylim(0, 105)
        ax1.set_xticks(eq_counts)

        # Add value labels on bars
        for bar, rate in zip(bars, failure_rates):
            height = bar.get_height()
            ax1.annotate(f'{rate:.1f}%',
                        xy=(bar.get_x() + bar.get_width() / 2, height),
                        xytext=(0, 3),
                        textcoords="offset points",
                        ha='center', va='bottom', fontsize=8)

        # Right plot: Distribution of empty muscle counts for 1-equipment scenarios
        ax2 = axes[idx, 1]

        # Collect data for all equipment counts
        all_empty_counts = []
        labels = []

        for eq_count in [1, 2, 3]:
            if eq_count in stats['by_equipment_count']:
                combos = data['raw_results']['by_equipment_count'][eq_count]
                empty_counts = [c['empty_count'] for c in combos]
                all_empty_counts.append(empty_counts)
                labels.append(f'{eq_count} equip')

        if all_empty_counts:
            # Create violin plot or box plot
            positions = range(1, len(all_empty_counts) + 1)
            parts = ax2.violinplot(all_empty_counts, positions=positions, showmeans=True, showmedians=True)

            # Color the violin plots
            for pc in parts['bodies']:
                pc.set_facecolor('#4ecdc4')
                pc.set_alpha(0.7)

            ax2.set_xticks(positions)
            ax2.set_xticklabels(labels)
            ax2.set_xlabel('Equipment Count')
            ax2.set_ylabel('Number of Empty Muscle Groups')
            ax2.set_title(f'{exp_level}\nDistribution of Empty Muscles (1-3 Equipment)')
            ax2.set_ylim(-0.5, 10)

    plt.tight_layout()
    plt.savefig(output_path, dpi=150, bbox_inches='tight')
    print(f"✅ Saved histogram to: {output_path}")

    return fig

def create_detailed_heatmap(report_data, output_path):
    """Create heatmap showing which muscles fail for each single-equipment scenario."""

    fig, axes = plt.subplots(1, 2, figsize=(16, 8))
    fig.suptitle('Single Equipment Analysis: Exercise Availability per Muscle Group',
                 fontsize=14, fontweight='bold')

    for idx, exp_level in enumerate(["NO_EXPERIENCE", "BEGINNER"]):
        ax = axes[idx]
        data = report_data[exp_level]

        # Get single-equipment results
        single_eq_results = data['raw_results']['by_equipment_count'][1]

        # Create matrix: equipment x muscle
        matrix = np.zeros((len(EQUIPMENT_CATEGORIES), len(REQUIRED_MUSCLES)))

        for i, eq in enumerate(EQUIPMENT_CATEGORIES):
            # Find the result for this equipment
            for result in single_eq_results:
                if result['equipment'] == [eq]:
                    for j, muscle in enumerate(REQUIRED_MUSCLES):
                        matrix[i, j] = result['muscle_counts'][muscle]
                    break

        # Create heatmap
        im = ax.imshow(matrix, cmap='RdYlGn', aspect='auto', vmin=0, vmax=10)

        # Add text annotations
        for i in range(len(EQUIPMENT_CATEGORIES)):
            for j in range(len(REQUIRED_MUSCLES)):
                value = int(matrix[i, j])
                color = 'white' if value <= 2 else 'black'
                ax.text(j, i, str(value), ha='center', va='center', color=color, fontsize=9)

        ax.set_xticks(range(len(REQUIRED_MUSCLES)))
        ax.set_xticklabels(REQUIRED_MUSCLES, rotation=45, ha='right')
        ax.set_yticks(range(len(EQUIPMENT_CATEGORIES)))
        ax.set_yticklabels(EQUIPMENT_CATEGORIES)
        ax.set_title(f'{exp_level} (max complexity={EXPERIENCE_LEVELS[exp_level]})')

        # Add colorbar
        cbar = plt.colorbar(im, ax=ax, shrink=0.8)
        cbar.set_label('Exercise Count')

    plt.tight_layout()
    plt.savefig(output_path, dpi=150, bbox_inches='tight')
    print(f"✅ Saved heatmap to: {output_path}")

    return fig

def print_summary_report(report_data):
    """Print text summary of the analysis."""

    print("\n" + "="*80)
    print("EQUIPMENT COMBINATION ANALYSIS SUMMARY")
    print("="*80)

    for exp_level in ["NO_EXPERIENCE", "BEGINNER"]:
        data = report_data[exp_level]
        stats = data['stats']

        print(f"\n{'─'*40}")
        print(f"Experience Level: {exp_level}")
        print(f"Max Complexity: {stats['max_complexity']}")
        print(f"{'─'*40}")

        print("\nFailure Rate by Equipment Count:")
        print(f"{'Equip Count':<12} {'Combinations':<14} {'Failures':<10} {'Rate':<10}")
        print("-" * 46)

        for eq_count in sorted(stats['by_equipment_count'].keys()):
            s = stats['by_equipment_count'][eq_count]
            print(f"{eq_count:<12} {s['total_combinations']:<14} {s['failures']:<10} {s['failure_rate']:.1f}%")

        # Show worst single-equipment combinations
        if 1 in stats['by_equipment_count']:
            print(f"\n⚠️  Single Equipment Analysis (Worst Cases):")
            worst = stats['by_equipment_count'][1]['worst_combos']
            for combo in worst[:7]:
                eq_name = combo['equipment'][0]
                empty = combo['empty_muscles']
                print(f"   • {eq_name}: {len(empty)} empty muscles: {', '.join(empty)}")

def main():
    """Main entry point."""

    # Create output directory
    output_dir = Path(__file__).parent
    output_dir.mkdir(exist_ok=True)

    print("🔬 Connecting to exercise database...")
    conn = sqlite3.connect(DB_PATH)

    print("📊 Analyzing equipment combinations...")
    report_data = generate_analysis_report(conn)

    # Print text summary
    print_summary_report(report_data)

    # Create visualizations
    print("\n📈 Generating visualizations...")

    histogram_path = output_dir / "equipment_failure_histogram.png"
    create_histogram(report_data, histogram_path)

    heatmap_path = output_dir / "equipment_muscle_heatmap.png"
    create_detailed_heatmap(report_data, heatmap_path)

    conn.close()

    print("\n✅ Analysis complete!")
    print(f"   Histogram: {histogram_path}")
    print(f"   Heatmap: {heatmap_path}")

if __name__ == "__main__":
    main()
