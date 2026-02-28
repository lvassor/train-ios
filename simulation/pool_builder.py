"""
pool_builder.py - Pool filtering logic mirroring Swift implementation

Updated for normalised equipment schema (equipment_id_1/equipment_id_2).
"""

from typing import List, Optional, Dict, Any
from scoring import Exercise


# Auto-include rules (mirroring Swift EquipmentAutoInclude logic):
# Selecting any child in a category auto-adds the parent equipment.
AUTO_INCLUDE_RULES = {
    # Any Barbells child (EP002-EP009) auto-includes EP001 (Barbells)
    'EP002': 'EP001', 'EP003': 'EP001', 'EP004': 'EP001', 'EP005': 'EP001',
    'EP006': 'EP001', 'EP007': 'EP001', 'EP008': 'EP001', 'EP009': 'EP001',
    # Any Dumbbells child (EP011) auto-includes EP010 (Dumbbells)
    'EP011': 'EP010',
    # Kettlebells has no children currently, but rule stands
}

# Bodyweight is always in the user's set
BODYWEIGHT_ID = 'EP043'


def apply_auto_includes(user_equipment_ids: set) -> set:
    """
    Apply auto-include rules to the user's equipment set.
    - Bodyweight (EP043) is always included.
    - Selecting any child equipment auto-adds its parent.
    """
    expanded = set(user_equipment_ids)
    expanded.add(BODYWEIGHT_ID)

    for child_id, parent_id in AUTO_INCLUDE_RULES.items():
        if child_id in expanded:
            expanded.add(parent_id)

    return expanded


def build_user_pool(
    all_exercises: List[Exercise],
    primary_muscle: Optional[str],
    user_equipment_ids: set,
    max_complexity: int,
    excluded_exercise_ids: set
) -> List[Exercise]:
    """
    Build the pool of available exercises based on user's equipment and experience level.

    User Pool = exercises WHERE:
      - equipment_id_1 IN user's equipment set
      - (equipment_id_2 IS NULL OR equipment_id_2 IN user's equipment set)
      - complexity_level <= max_complexity
      - is_in_programme = 1

    NOTE: Auto-include rules should be applied to user_equipment_ids BEFORE
    calling this function (see apply_auto_includes).
    NOTE: Injuries do NOT filter exercises — they're for UI warnings only.
    """
    pool = []

    for exercise in all_exercises:
        # Skip if not in programme
        if not exercise.is_in_programme:
            continue

        # Filter by equipment (2-FK logic)
        if exercise.equipment_id_1 not in user_equipment_ids:
            continue
        if exercise.equipment_id_2 and exercise.equipment_id_2 not in user_equipment_ids:
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
