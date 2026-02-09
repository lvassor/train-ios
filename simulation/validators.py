"""
validators.py - Error detection logic for programme generation
"""

from typing import List, Dict, Any, Tuple
from dataclasses import dataclass


@dataclass
class ValidationResult:
    """Result of programme validation"""
    status: str
    error_details: str
    total_slots_required: int
    total_slots_filled: int
    fill_rate_pct: float


# Error codes
ERR_ZERO_EXERCISES = "ERR_ZERO_EXERCISES"
ERR_UNDER_50_PCT = "ERR_UNDER_50_PCT"  # 50% threshold - primary failure definition
ERR_LOW_VARIETY = "ERR_LOW_VARIETY"
SUCCESS = "SUCCESS"


def validate_session(
    session_name: str,
    muscle_groups: List[Tuple[str, int]],  # [(muscle, count), ...]
    exercises_by_muscle: Dict[str, List[Any]],
    pool_counts: Dict[str, int]  # pool size per muscle
) -> ValidationResult:
    """
    Validate a single session's exercise selection.

    Returns validation result with status and details.
    """
    total_slots = sum(count for _, count in muscle_groups)
    total_filled = sum(len(exercises_by_muscle.get(muscle, [])) for muscle, _ in muscle_groups)

    # Check for zero exercises for any required muscle
    zero_exercise_muscles = []
    low_variety_muscles = []

    for muscle, required_count in muscle_groups:
        pool_size = pool_counts.get(muscle, 0)
        filled = len(exercises_by_muscle.get(muscle, []))

        if pool_size == 0:
            zero_exercise_muscles.append(muscle)
        elif pool_size < required_count:
            low_variety_muscles.append(f"{muscle} (need {required_count}, pool has {pool_size})")

    fill_rate = (total_filled / total_slots * 100) if total_slots > 0 else 0

    # Determine status
    if zero_exercise_muscles:
        return ValidationResult(
            status=ERR_ZERO_EXERCISES,
            error_details=f"No exercises for: {', '.join(zero_exercise_muscles)}",
            total_slots_required=total_slots,
            total_slots_filled=total_filled,
            fill_rate_pct=fill_rate
        )

    if fill_rate < 50:
        return ValidationResult(
            status=ERR_UNDER_50_PCT,
            error_details=f"Only {fill_rate:.1f}% filled (below 50% threshold)",
            total_slots_required=total_slots,
            total_slots_filled=total_filled,
            fill_rate_pct=fill_rate
        )

    if low_variety_muscles:
        return ValidationResult(
            status=ERR_LOW_VARIETY,
            error_details=f"Low variety: {', '.join(low_variety_muscles)}",
            total_slots_required=total_slots,
            total_slots_filled=total_filled,
            fill_rate_pct=fill_rate
        )

    return ValidationResult(
        status=SUCCESS,
        error_details="",
        total_slots_required=total_slots,
        total_slots_filled=total_filled,
        fill_rate_pct=fill_rate
    )


def validate_programme(
    sessions: List[Dict[str, Any]],
    all_pool_counts: Dict[str, Dict[str, int]]  # session_name -> {muscle -> pool_count}
) -> ValidationResult:
    """
    Validate entire programme across all sessions.

    sessions format:
    [
        {
            'name': 'Push',
            'muscle_groups': [('Chest', 2), ('Shoulders', 2), ('Triceps', 1)],
            'exercises': {'Chest': [ex1, ex2], 'Shoulders': [ex3, ex4], ...}
        },
        ...
    ]
    """
    total_slots = 0
    total_filled = 0
    errors = []

    for session in sessions:
        session_name = session['name']
        muscle_groups = session['muscle_groups']
        exercises = session['exercises']
        pool_counts = all_pool_counts.get(session_name, {})

        result = validate_session(session_name, muscle_groups, exercises, pool_counts)

        total_slots += result.total_slots_required
        total_filled += result.total_slots_filled

        if result.status != SUCCESS:
            errors.append(f"{session_name}: {result.error_details}")

    fill_rate = (total_filled / total_slots * 100) if total_slots > 0 else 0

    # Return first error found, or success
    if errors:
        # Prioritize error types
        for err in errors:
            if ERR_ZERO_EXERCISES in err or "No exercises" in err:
                return ValidationResult(
                    status=ERR_ZERO_EXERCISES,
                    error_details=errors[0],
                    total_slots_required=total_slots,
                    total_slots_filled=total_filled,
                    fill_rate_pct=fill_rate
                )

        if fill_rate < 50:
            return ValidationResult(
                status=ERR_UNDER_50_PCT,
                error_details="; ".join(errors),
                total_slots_required=total_slots,
                total_slots_filled=total_filled,
                fill_rate_pct=fill_rate
            )

        return ValidationResult(
            status=ERR_LOW_VARIETY,
            error_details="; ".join(errors),
            total_slots_required=total_slots,
            total_slots_filled=total_filled,
            fill_rate_pct=fill_rate
        )

    return ValidationResult(
        status=SUCCESS,
        error_details="",
        total_slots_required=total_slots,
        total_slots_filled=total_filled,
        fill_rate_pct=fill_rate
    )
