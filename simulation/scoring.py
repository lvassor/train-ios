"""
scoring.py - Exercise scoring logic mirroring Swift implementation
"""

from dataclasses import dataclass
from typing import List, Optional
import random


@dataclass
class Exercise:
    """Represents an exercise from the database"""
    exercise_id: str
    canonical_name: str
    display_name: str
    equipment_category: str
    equipment_specific: Optional[str]
    complexity_level: int
    is_isolation: bool
    primary_muscle: str
    secondary_muscle: Optional[str]
    is_in_programme: bool


@dataclass
class ScoredExercise:
    """Exercise with calculated score"""
    exercise: Exercise
    score: int
    is_compound: bool


def calculate_score(exercise: Exercise, experience_level: str) -> int:
    """
    Calculate score for an exercise based on business rules.

    Compounds (is_isolation = False):
        - Level 4 = 20
        - Level 3 = 15
        - Level 2 = 10
        - Level 1 = 5

    Isolations (is_isolation = True):
        - Advanced: 8
        - Intermediate: 6
        - Beginner/No Experience: 4
    """
    if exercise.is_isolation:
        # Isolation scoring based on experience level
        if experience_level == 'ADVANCED':
            return 8
        elif experience_level == 'INTERMEDIATE':
            return 6
        else:  # BEGINNER, NO_EXPERIENCE
            return 4
    else:
        # Compound scoring based on complexity
        complexity_scores = {4: 20, 3: 15, 2: 10, 1: 5}
        return complexity_scores.get(exercise.complexity_level, 5)


def weighted_random_select(candidates: List[ScoredExercise]) -> Optional[ScoredExercise]:
    """
    Weighted random selection - higher scores have higher probability.
    probability(exercise) = exercise.score / sum(all_scores)
    """
    if not candidates:
        return None

    total_score = sum(c.score for c in candidates)
    if total_score == 0:
        return candidates[0] if candidates else None

    random_value = random.randint(0, total_score - 1)
    cumulative = 0

    for candidate in candidates:
        cumulative += candidate.score
        if random_value < cumulative:
            return candidate

    return candidates[-1]


def score_and_select_exercises(
    pool: List[Exercise],
    count: int,
    experience_level: str,
    excluded_exercise_ids: set,
    allow_complexity_4: bool,
    require_complexity_4_first: bool,
    max_complexity: int
) -> List[ScoredExercise]:
    """
    Score exercises and select based on weighted random selection.
    """
    if not pool:
        return []

    # Filter out excluded exercises
    available_pool = [e for e in pool if e.exercise_id not in excluded_exercise_ids]
    selected_exercises = []
    used_canonical_names = set()

    # Score all exercises
    scored_pool = [
        ScoredExercise(
            exercise=e,
            score=calculate_score(e, experience_level),
            is_compound=not e.is_isolation
        )
        for e in available_pool
    ]

    # BUSINESS RULE: If complexity-4 required first, select one first
    if require_complexity_4_first and allow_complexity_4:
        complexity_4_candidates = [
            s for s in scored_pool
            if s.exercise.complexity_level == 4 and s.is_compound
        ]

        if complexity_4_candidates:
            selected = weighted_random_select(complexity_4_candidates)
            if selected:
                selected_exercises.append(selected)
                used_canonical_names.add(selected.exercise.canonical_name)
                scored_pool = [s for s in scored_pool if s.exercise.exercise_id != selected.exercise.exercise_id]

    # Select remaining exercises with weighted random selection
    while len(selected_exercises) < count and scored_pool:
        # Prefer exercises with different canonical names for variety
        preferred_candidates = [s for s in scored_pool if s.exercise.canonical_name not in used_canonical_names]
        candidates = preferred_candidates if preferred_candidates else scored_pool

        # Apply complexity cap if we already have a complexity-4
        has_complexity_4 = any(s.exercise.complexity_level == 4 for s in selected_exercises)
        if has_complexity_4:
            # Only allow up to complexity 3 for remaining (unless isolation)
            filtered_candidates = [
                s for s in candidates
                if s.exercise.complexity_level <= 3 or s.exercise.is_isolation
            ]
            candidates = filtered_candidates if filtered_candidates else candidates

        selected = weighted_random_select(candidates)
        if not selected:
            break

        selected_exercises.append(selected)
        used_canonical_names.add(selected.exercise.canonical_name)
        scored_pool = [s for s in scored_pool if s.exercise.exercise_id != selected.exercise.exercise_id]

    return selected_exercises


def sort_for_display(exercises: List[ScoredExercise]) -> List[Exercise]:
    """
    Sort exercises for display: compounds first, then by complexity (descending)
    """
    sorted_exercises = sorted(
        exercises,
        key=lambda s: (
            0 if s.is_compound else 1,  # Compounds first
            -s.exercise.complexity_level  # Higher complexity first
        )
    )
    return [s.exercise for s in sorted_exercises]
