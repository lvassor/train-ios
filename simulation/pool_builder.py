"""
pool_builder.py - Pool filtering logic mirroring Swift implementation
"""

from typing import List, Optional, Dict, Any
from scoring import Exercise


def build_user_pool(
    all_exercises: List[Exercise],
    primary_muscle: Optional[str],
    available_equipment: List[str],
    max_complexity: int,
    excluded_exercise_ids: set
) -> List[Exercise]:
    """
    Build the pool of available exercises based on user's equipment and experience level.

    User Pool = exercises WHERE:
      - equipment_category IN user's selected equipment
      - complexity_level <= max_complexity (from user_experience_complexity table)
      - is_in_programme = 1

    NOTE: Injuries do NOT filter exercises - they're for UI warnings only
    """
    pool = []

    for exercise in all_exercises:
        # Skip if not in programme
        if not exercise.is_in_programme:
            continue

        # Filter by equipment
        if exercise.equipment_category not in available_equipment:
            continue

        # Filter by complexity
        if exercise.complexity_level > max_complexity:
            continue

        # Filter by muscle (if specified)
        if primary_muscle and exercise.primary_muscle != primary_muscle:
            continue

        # Filter out excluded exercises
        if exercise.exercise_id in excluded_exercise_ids:
            continue

        pool.append(exercise)

    return pool


def get_max_complexity(experience_level: str, complexity_rules: Dict[str, Any]) -> int:
    """Get max complexity from complexity rules dictionary"""
    if experience_level in complexity_rules:
        return complexity_rules[experience_level]['max_complexity']
    return 1  # Default to most restrictive


def get_complexity_4_rules(experience_level: str, complexity_rules: Dict[str, Any]) -> tuple:
    """Get complexity-4 specific rules (max_per_session, must_be_first)"""
    if experience_level in complexity_rules:
        rules = complexity_rules[experience_level]
        return (
            rules.get('max_complexity_4_per_session', 0),
            rules.get('complexity_4_must_be_first', False)
        )
    return (0, False)
