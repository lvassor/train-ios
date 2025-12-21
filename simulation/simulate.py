#!/usr/bin/env python3
"""
simulate.py - Monte Carlo simulation for programme generation

Usage:
    python simulate.py --runs 1000 --seed 42 --db ./exercises.db --output ./results.csv
"""

import argparse
import csv
import random
import sqlite3
from pathlib import Path
from typing import List, Dict, Any, Optional, Tuple

from scoring import Exercise, score_and_select_exercises, sort_for_display
from pool_builder import build_user_pool, get_max_complexity, get_complexity_4_rules
from validators import validate_programme, SUCCESS
from templates import get_session_templates
from report import generate_summary_report, print_sample_results


# Constants - MUST match Swift mapEquipmentFromQuestionnaire() exactly
# Swift maps: dumbbells->Dumbbells, barbells->Barbells, cable_machines->Cables,
#             kettlebells->Kettlebells, pin_loaded->Pin-Loaded Machines,
#             plate_loaded->Plate-Loaded Machines, bodyweight/other->Other
EXPERIENCE_LEVELS = ['NO_EXPERIENCE', 'BEGINNER', 'INTERMEDIATE', 'ADVANCED']
EQUIPMENT_OPTIONS = ['Barbells', 'Dumbbells', 'Kettlebells', 'Cables', 'Pin-Loaded Machines', 'Plate-Loaded Machines', 'Other']
DAYS_OPTIONS = [1, 2, 3, 4, 5, 6]
DURATION_OPTIONS = ['30-45 min', '45-60 min', '60-90 min']
GOAL_OPTIONS = ['Muscle Growth', 'Strength', 'General Fitness']


def load_exercises_from_db(db_path: str) -> List[Exercise]:
    """Load all exercises from the SQLite database"""
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    cursor.execute("""
        SELECT exercise_id, canonical_name, display_name, equipment_category,
               equipment_specific, complexity_level, is_isolation, primary_muscle,
               secondary_muscle, is_in_programme
        FROM exercises
        WHERE is_in_programme = 1
    """)

    exercises = []
    for row in cursor.fetchall():
        exercises.append(Exercise(
            exercise_id=row[0],
            canonical_name=row[1],
            display_name=row[2],
            equipment_category=row[3],
            equipment_specific=row[4],
            complexity_level=row[5],
            is_isolation=bool(row[6]),
            primary_muscle=row[7],
            secondary_muscle=row[8],
            is_in_programme=bool(row[9])
        ))

    conn.close()
    return exercises


def load_complexity_rules(db_path: str) -> Dict[str, Dict[str, Any]]:
    """Load experience complexity rules from database"""
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    cursor.execute("""
        SELECT experience_level, max_complexity, max_complexity_4_per_session, complexity_4_must_be_first
        FROM user_experience_complexity
    """)

    rules = {}
    for row in cursor.fetchall():
        rules[row[0]] = {
            'max_complexity': row[1],
            'max_complexity_4_per_session': row[2],
            'complexity_4_must_be_first': bool(row[3])
        }

    conn.close()
    return rules


def get_available_muscles(exercises: List[Exercise]) -> List[str]:
    """Get unique primary muscles from exercises"""
    return list(set(e.primary_muscle for e in exercises))


def generate_random_user_profile(available_muscles: List[str]) -> Dict[str, Any]:
    """Generate a random user profile for simulation"""
    # Random experience level
    experience_level = random.choice(EXPERIENCE_LEVELS)

    # Random equipment subset (at least 1)
    num_equipment = random.randint(1, len(EQUIPMENT_OPTIONS))
    equipment = random.sample(EQUIPMENT_OPTIONS, num_equipment)

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
        'equipment': equipment,
        'days_per_week': days_per_week,
        'session_duration': session_duration,
        'goal': goal,
        'focus_muscle': focus_muscle,
        'excluded_muscles': excluded_muscles
    }


def run_simulation(
    simulation_id: int,
    user_profile: Dict[str, Any],
    all_exercises: List[Exercise],
    complexity_rules: Dict[str, Dict[str, Any]]
) -> Dict[str, Any]:
    """
    Run a single programme generation simulation.
    Returns result dictionary with all metrics.
    """
    experience_level = user_profile['experience_level']
    equipment = user_profile['equipment']
    days_per_week = user_profile['days_per_week']
    session_duration = user_profile['session_duration']

    # Get complexity rules for this user
    max_complexity = get_max_complexity(experience_level, complexity_rules)
    max_c4_per_session, c4_must_be_first = get_complexity_4_rules(experience_level, complexity_rules)

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
                available_equipment=equipment,
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
        'equipment_list': ', '.join(sorted(equipment)),
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
        'simulation_id', 'experience_level', 'equipment_list', 'days_per_week',
        'session_duration', 'goal', 'focus_muscle', 'excluded_muscles',
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
    parser.add_argument('--db', type=str, default='../trAInSwift/Resources/exercises.db',
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

    # Load data
    all_exercises = load_exercises_from_db(str(db_path))
    complexity_rules = load_complexity_rules(str(db_path))
    available_muscles = get_available_muscles(all_exercises)

    print(f"Loaded {len(all_exercises)} exercises")
    print(f"Available muscles: {', '.join(sorted(available_muscles))}")
    print(f"Running {args.runs} simulations...")
    print()

    # Run simulations
    results = []
    for i in range(args.runs):
        user_profile = generate_random_user_profile(available_muscles)
        result = run_simulation(i + 1, user_profile, all_exercises, complexity_rules)
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

    return 0


if __name__ == '__main__':
    exit(main())
