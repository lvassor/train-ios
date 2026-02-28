#!/usr/bin/env python3
"""
simulate.py - Monte Carlo simulation for programme generation

Updated for normalised equipment schema (equipment_id_1/equipment_id_2).
Equipment categories and IDs are now loaded from the equipment table in the DB,
replacing the constants.json dependency for equipment data.

Usage:
    python simulate.py --runs 1000 --seed 42 --db ./exercises.db --output ./results.csv
"""

import argparse
import csv
import matplotlib.pyplot as plt
import numpy as np
import os
import pandas as pd
import random
import seaborn as sns
import sqlite3
from pathlib import Path
from typing import List, Dict, Any, Optional, Tuple, Set

from scoring import Exercise, score_and_select_exercises, sort_for_display
from pool_builder import build_user_pool, get_max_complexity, get_complexity_4_rules, apply_auto_includes
from validators import validate_programme, SUCCESS
from templates import get_session_templates
from report import generate_summary_report, print_sample_results


# Hardcoded constants (not equipment-dependent)
EXPERIENCE_LEVELS = ['NO_EXPERIENCE', 'BEGINNER', 'INTERMEDIATE', 'ADVANCED']
DAYS_OPTIONS = [1, 2, 3, 4, 5, 6]
DURATION_OPTIONS = ['30-45 min', '45-60 min', '60-90 min']
GOAL_OPTIONS = ['Muscle Growth', 'Strength', 'General Fitness']


def load_equipment_from_db(db_path: str) -> Dict[str, List[Dict[str, str]]]:
    """
    Load equipment data from the equipment table in the DB.

    Returns dict keyed by category, each value is a list of
    {'equipment_id': str, 'name': str} dicts.
    """
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    cursor.execute("""
        SELECT equipment_id, category, name
        FROM equipment
        ORDER BY category, equipment_id
    """)

    equipment_by_category: Dict[str, List[Dict[str, str]]] = {}
    for row in cursor.fetchall():
        eid, category, name = row
        if category not in equipment_by_category:
            equipment_by_category[category] = []
        equipment_by_category[category].append({
            'equipment_id': eid,
            'name': name
        })

    conn.close()
    return equipment_by_category


def get_all_equipment_ids(equipment_by_category: Dict[str, List[Dict[str, str]]]) -> List[str]:
    """Get flat list of all equipment IDs (excluding Bodyweight and Attachments)."""
    ids = []
    for category, items in equipment_by_category.items():
        if category in ('Bodyweight', 'Attachment'):
            continue  # Bodyweight is auto-included; attachments are selected implicitly
        for item in items:
            ids.append(item['equipment_id'])
    return ids


def get_attachment_ids(equipment_by_category: Dict[str, List[Dict[str, str]]]) -> List[str]:
    """Get list of attachment equipment IDs."""
    return [
        item['equipment_id']
        for item in equipment_by_category.get('Attachment', [])
    ]


def create_analysis_plots(results_df: pd.DataFrame, output_dir: str = "."):
    """Create heatmap visualizations for equipment vs days analysis"""

    # Add equipment count column
    results_df['equipment_count'] = results_df['equipment_list'].apply(
        lambda x: len(x.split(', ')) if x.strip() and x.strip() != '[]' else 0
    )

    # Add failure flag
    results_df['failed'] = (results_df['status'] != 'SUCCESS').astype(int)

    # Create pivot tables for heatmaps
    failure_pivot = results_df.groupby(['equipment_count', 'days_per_week'])['failed'].agg(['mean', 'count']).reset_index()
    failure_pivot['failure_rate'] = failure_pivot['mean'] * 100

    # Only show combinations with at least 2 users for reliability
    failure_pivot = failure_pivot[failure_pivot['count'] >= 2]

    # Create heatmap data
    heatmap_failure = failure_pivot.pivot(index='equipment_count', columns='days_per_week', values='failure_rate')
    heatmap_count = failure_pivot.pivot(index='equipment_count', columns='days_per_week', values='count')

    # Guard: skip heatmaps if insufficient data
    if heatmap_failure.empty or heatmap_failure.size == 0:
        print("⚠️  Not enough data for heatmaps (need more runs)")
        return failure_pivot, results_df[results_df['status'] == 'SUCCESS'].copy()

    # Plot 1: Failure Rate Heatmap
    plt.figure(figsize=(12, 8))
    sns.heatmap(heatmap_failure,
                annot=True,
                fmt='.1f',
                cmap='Reds',
                cbar_kws={'label': 'Failure Rate (%)'},
                vmin=0,
                vmax=100)
    plt.title('Program Generation Failure Rate by Equipment Count vs Training Days', fontsize=14, fontweight='bold')
    plt.xlabel('Training Days per Week', fontsize=12)
    plt.ylabel('Number of Equipment Items Selected', fontsize=12)
    plt.tight_layout()
    plt.savefig(f'{output_dir}/failure_rate_heatmap.png', dpi=300, bbox_inches='tight')
    plt.close()

    # Plot 2: Sample Count Heatmap (to show data reliability)
    if not heatmap_count.empty and heatmap_count.size > 0:
        plt.figure(figsize=(12, 8))
        sns.heatmap(heatmap_count,
                    annot=True,
                    fmt='.0f',
                    cmap='Blues',
                    cbar_kws={'label': 'Number of Users'})
        plt.title('Sample Size by Equipment Count vs Training Days', fontsize=14, fontweight='bold')
        plt.xlabel('Training Days per Week', fontsize=12)
        plt.ylabel('Number of Equipment Items Selected', fontsize=12)
        plt.tight_layout()
        plt.savefig(f'{output_dir}/sample_count_heatmap.png', dpi=300, bbox_inches='tight')
        plt.close()

    # Plot 3: Average Program Day Size (for successful programs only)
    successful_programs = results_df[results_df['status'] == 'SUCCESS'].copy()
    if len(successful_programs) > 0:
        # Count total exercises (split by comma and count)
        successful_programs['total_exercises'] = successful_programs['exercises_selected'].str.split(', ').str.len()
        # Calculate average exercises per day (total exercises / days per week)
        successful_programs['avg_exercises_per_day'] = successful_programs['total_exercises'] / successful_programs['days_per_week']

        day_size_pivot = successful_programs.groupby(['equipment_count', 'days_per_week'])['avg_exercises_per_day'].agg(['mean', 'count']).reset_index()
        day_size_pivot = day_size_pivot[day_size_pivot['count'] >= 2]  # At least 2 successful cases

        if len(day_size_pivot) > 0:
            heatmap_day_size = day_size_pivot.pivot(index='equipment_count', columns='days_per_week', values='mean')

            if not heatmap_day_size.empty and heatmap_day_size.size > 0:
                plt.figure(figsize=(12, 8))
                sns.heatmap(heatmap_day_size,
                            annot=True,
                            fmt='.1f',
                            cmap='viridis',
                            cbar_kws={'label': 'Avg Exercises per Day'})
                plt.title('Average Program Day Size (Exercises per Day) for Successful Programs', fontsize=14, fontweight='bold')
                plt.xlabel('Training Days per Week', fontsize=12)
                plt.ylabel('Number of Equipment Items Selected', fontsize=12)
                plt.tight_layout()
                plt.savefig(f'{output_dir}/program_day_size_heatmap.png', dpi=300, bbox_inches='tight')
                plt.close()
            else:
                print("⚠️  Not enough data for day-size heatmap")
        else:
            print("⚠️  Not enough successful programs for day-size heatmap (need >=2 per cell)")

    # Print worst combinations
    print("\n🚨 WORST EQUIPMENT-DAYS COMBINATIONS:")
    worst_combinations = failure_pivot.nlargest(10, 'failure_rate')
    for _, row in worst_combinations.iterrows():
        print(f"  {int(row['equipment_count'])} equipment items, {int(row['days_per_week'])} days/week: "
              f"{row['failure_rate']:.1f}% failure rate ({int(row['count'])} users)")

    return failure_pivot, successful_programs


def load_exercises_from_db(db_path: str) -> List[Exercise]:
    """Load all exercises from the SQLite database (normalised equipment schema)."""
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    cursor.execute("""
        SELECT exercise_id, canonical_name, display_name, equipment_id_1,
               equipment_id_2, complexity_level, canonical_rating, primary_muscle,
               secondary_muscle, is_in_programme
        FROM exercises
        WHERE is_in_programme = 1
    """)

    exercises = []
    for row in cursor.fetchall():
        # Convert complexity_level from TEXT to INT
        complexity_text = str(row[5]).strip()
        if complexity_text.lower() == "all":
            complexity_int = 0
        elif complexity_text == "1":
            complexity_int = 1
        elif complexity_text == "2":
            complexity_int = 2
        else:
            complexity_int = 0  # Default fallback

        exercises.append(Exercise(
            exercise_id=row[0],
            canonical_name=row[1],
            display_name=row[2],
            equipment_id_1=row[3],
            equipment_id_2=row[4] if row[4] else None,
            complexity_level=complexity_int,
            canonical_rating=row[6],
            primary_muscle=row[7],
            secondary_muscle=row[8],
            is_in_programme=bool(row[9])
        ))

    conn.close()
    return exercises


def get_complexity_rules(experience_level: str) -> Dict[str, Any]:
    """Get experience complexity rules (hardcoded to match Swift ExperienceLevel.complexityRules)"""
    # Mirror Swift ExperienceLevel enum complexity rules exactly
    rules_map = {
        'NO_EXPERIENCE': {
            'max_complexity': 1,  # Only "all" and "1" exercises
            'max_complexity_4_per_session': 0,  # No complexity-4 support
            'complexity_4_must_be_first': False
        },
        'BEGINNER': {
            'max_complexity': 1,  # Only "all" and "1" exercises
            'max_complexity_4_per_session': 0,  # No complexity-4 support
            'complexity_4_must_be_first': False
        },
        'INTERMEDIATE': {
            'max_complexity': 2,  # Up to "2" exercises (all levels)
            'max_complexity_4_per_session': 0,  # No complexity-4 support
            'complexity_4_must_be_first': False
        },
        'ADVANCED': {
            'max_complexity': 2,  # Up to "2" exercises (all levels)
            'max_complexity_4_per_session': 0,  # No complexity-4 support
            'complexity_4_must_be_first': False
        }
    }

    return rules_map.get(experience_level, rules_map['NO_EXPERIENCE'])


def get_available_muscles(exercises: List[Exercise]) -> List[str]:
    """Get unique primary muscles from exercises"""
    return list(set(e.primary_muscle for e in exercises))


def generate_random_user_profile(
    available_muscles: List[str],
    selectable_equipment_ids: List[str],
    attachment_ids: List[str]
) -> Dict[str, Any]:
    """
    Generate a random user profile for simulation.

    Simulates the questionnaire flow:
    1. User picks a random subset of main equipment (1 to N items)
    2. If user has cable machines, randomly add some attachments
    3. Auto-include rules expand the set (Bodyweight always added, parent IDs added)
    """
    # Random experience level
    experience_level = random.choice(EXPERIENCE_LEVELS)

    # Random equipment subset (at least 1 from selectable items)
    num_equipment = random.randint(1, min(len(selectable_equipment_ids), 15))
    raw_selection = set(random.sample(selectable_equipment_ids, num_equipment))

    # If user selected any cable machines (EP013-EP016), randomly add some attachments
    cable_ids = {'EP013', 'EP014', 'EP015', 'EP016'}
    if raw_selection & cable_ids:
        # Add 1-4 random attachments
        num_attachments = random.randint(1, min(len(attachment_ids), 4))
        raw_selection.update(random.sample(attachment_ids, num_attachments))

    # Apply auto-include rules (adds Bodyweight, parent equipment)
    user_equipment_ids = apply_auto_includes(raw_selection)

    # Random days per week
    days_per_week = random.choice(DAYS_OPTIONS)

    # Random session duration
    session_duration = random.choice(DURATION_OPTIONS)

    # Random goal
    goal = random.choice(GOAL_OPTIONS)

    # Optional focus muscle (30% chance)
    focus_muscle = None
    if random.random() < 0.3:
        focus_muscle = random.choice(available_muscles)

    # Optional excluded muscles (0-2, 20% chance per exclusion)
    excluded_muscles = []
    if random.random() < 0.2:
        num_exclusions = random.randint(1, 2)
        excluded_muscles = random.sample(available_muscles, min(num_exclusions, len(available_muscles)))

    return {
        'experience_level': experience_level,
        'user_equipment_ids': user_equipment_ids,
        'days_per_week': days_per_week,
        'session_duration': session_duration,
        'goal': goal,
        'focus_muscle': focus_muscle,
        'excluded_muscles': excluded_muscles
    }


def run_simulation(
    simulation_id: int,
    user_profile: Dict[str, Any],
    all_exercises: List[Exercise]
) -> Dict[str, Any]:
    """
    Run a single programme generation simulation.
    Returns result dictionary with all metrics.
    """
    experience_level = user_profile['experience_level']
    user_equipment_ids = user_profile['user_equipment_ids']
    days_per_week = user_profile['days_per_week']
    session_duration = user_profile['session_duration']

    # Get complexity rules for this user (hardcoded to match Swift)
    complexity_rules = get_complexity_rules(experience_level)
    max_complexity = complexity_rules['max_complexity']
    max_c4_per_session = complexity_rules['max_complexity_4_per_session']
    c4_must_be_first = complexity_rules['complexity_4_must_be_first']

    # Get session templates
    templates = get_session_templates(days_per_week, session_duration)

    # Track all used exercise IDs across sessions (no repeats)
    used_exercise_ids = set()

    # Generate each session
    sessions = []
    all_pool_counts = {}
    all_selected_exercises = []

    for template in templates:
        session_name = template['name']
        muscle_groups = template['muscle_groups']

        session_exercises = {}
        pool_counts = {}

        for muscle, count in muscle_groups:
            # Build pool for this muscle
            pool = build_user_pool(
                all_exercises=all_exercises,
                primary_muscle=muscle,
                user_equipment_ids=user_equipment_ids,
                max_complexity=max_complexity,
                excluded_exercise_ids=used_exercise_ids
            )

            pool_counts[muscle] = len(pool)

            # Determine complexity-4 rules (only for first muscle group in first exercise)
            is_first_slot = len(session_exercises) == 0
            allow_c4 = is_first_slot and max_c4_per_session > 0
            require_c4_first = c4_must_be_first and allow_c4

            # Score and select
            scored = score_and_select_exercises(
                pool=pool,
                count=count,
                experience_level=experience_level,
                excluded_exercise_ids=used_exercise_ids,
                allow_complexity_4=allow_c4,
                require_complexity_4_first=require_c4_first,
                max_complexity=max_complexity
            )

            # Sort and convert to exercises
            selected = sort_for_display(scored)

            session_exercises[muscle] = selected
            all_selected_exercises.extend(selected)

            # Mark as used
            for ex in selected:
                used_exercise_ids.add(ex.exercise_id)

        sessions.append({
            'name': session_name,
            'muscle_groups': muscle_groups,
            'exercises': session_exercises
        })
        all_pool_counts[session_name] = pool_counts

    # Validate the programme
    validation = validate_programme(sessions, all_pool_counts)

    # Build result
    return {
        'simulation_id': simulation_id,
        'experience_level': experience_level,
        'equipment_list': ', '.join(sorted(user_equipment_ids)),
        'equipment_count': len(user_equipment_ids),
        'days_per_week': days_per_week,
        'session_duration': session_duration,
        'goal': user_profile['goal'],
        'focus_muscle': user_profile['focus_muscle'] or '',
        'excluded_muscles': ', '.join(user_profile['excluded_muscles']),
        'status': validation.status,
        'error_details': validation.error_details,
        'total_slots_required': validation.total_slots_required,
        'total_slots_filled': validation.total_slots_filled,
        'fill_rate_pct': round(validation.fill_rate_pct, 1),
        'sessions_generated': ', '.join(t['name'] for t in templates),
        'exercises_selected': ', '.join(e.display_name for e in all_selected_exercises)
    }


def write_csv_results(results: List[Dict[str, Any]], output_path: str):
    """Write results to CSV file"""
    if not results:
        return

    fieldnames = [
        'simulation_id', 'experience_level', 'equipment_list', 'equipment_count',
        'days_per_week', 'session_duration', 'goal', 'focus_muscle', 'excluded_muscles',
        'status', 'error_details', 'total_slots_required', 'total_slots_filled',
        'fill_rate_pct', 'sessions_generated', 'exercises_selected'
    ]

    with open(output_path, 'w', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(results)


def main():
    parser = argparse.ArgumentParser(description='Monte Carlo simulation for programme generation')
    parser.add_argument('--runs', type=int, default=100, help='Number of simulations to run')
    parser.add_argument('--seed', type=int, help='Random seed for reproducibility')
    parser.add_argument('--db', type=str, default='../TrainSwift/Resources/exercises.db',
                        help='Path to exercises database')
    parser.add_argument('--output', type=str, default='simulation_results.csv',
                        help='Output CSV file path')
    parser.add_argument('--verbose', '-v', action='store_true', help='Verbose output')

    args = parser.parse_args()

    # Set random seed if provided
    if args.seed is not None:
        random.seed(args.seed)
        print(f"Using random seed: {args.seed}")

    # Resolve database path
    db_path = Path(args.db)
    if not db_path.is_absolute():
        db_path = Path(__file__).parent / args.db

    if not db_path.exists():
        print(f"Error: Database not found at {db_path}")
        return 1

    print(f"Loading exercises from: {db_path}")

    # Load equipment data from DB (replaces constants.json dependency)
    equipment_by_category = load_equipment_from_db(str(db_path))
    selectable_equipment_ids = get_all_equipment_ids(equipment_by_category)
    attachment_ids = get_attachment_ids(equipment_by_category)

    print(f"Equipment categories: {list(equipment_by_category.keys())}")
    print(f"Selectable equipment items: {len(selectable_equipment_ids)}")
    print(f"Attachment items: {len(attachment_ids)}")

    # Load exercises
    all_exercises = load_exercises_from_db(str(db_path))
    available_muscles = get_available_muscles(all_exercises)

    print(f"Loaded {len(all_exercises)} exercises")
    print(f"Available muscles: {', '.join(sorted(available_muscles))}")
    print(f"Running {args.runs} simulations...")
    print()

    # Run simulations
    results = []
    for i in range(args.runs):
        user_profile = generate_random_user_profile(
            available_muscles, selectable_equipment_ids, attachment_ids
        )
        result = run_simulation(i + 1, user_profile, all_exercises)
        results.append(result)

        if args.verbose and (i + 1) % 100 == 0:
            print(f"  Completed {i + 1}/{args.runs}")

    # Write CSV
    output_path = Path(args.output)
    write_csv_results(results, str(output_path))
    print(f"Output saved to: {output_path}")

    # Print summary report
    print()
    print(generate_summary_report(results))

    # Print sample results
    if args.verbose:
        print_sample_results(results)

    # Generate analysis plots
    print("\n📊 Generating analysis plots...")
    results_df = pd.DataFrame(results)
    failure_pivot, successful_programs = create_analysis_plots(results_df, output_dir=".")
    print("✅ Plots saved to current directory")

    return 0


if __name__ == '__main__':
    exit(main())
