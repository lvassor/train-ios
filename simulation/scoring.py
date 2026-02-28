"""
scoring.py - Exercise scoring logic mirroring Swift implementation

Updated for normalised equipment schema (equipment_id_1/equipment_id_2).
"""

from dataclasses import dataclass
from typing import List, Optional, Tuple
import random


@dataclass
class Exercise:
    """Represents an exercise from the database (normalised equipment schema)"""
    exercise_id: str
    canonical_name: str
    display_name: str
    equipment_id_1: str          # FK to equipment table (required)
    equipment_id_2: Optional[str]  # FK to equipment table (nullable)
    complexity_level: int  # Converted from TEXT ("All"=0, "1"=1, "2"=2)
    canonical_rating: int  # 0-100 score for MCV heuristic
    primary_muscle: str
    secondary_muscle: Optional[str]
    is_in_programme: bool

    @property
    def is_isolation(self) -> bool:
        """Derived property: exercises with rating < 40 are typically isolation"""
        return self.canonical_rating < 40

    @property
    def is_compound(self) -> bool:
        """Derived property: exercises with rating >= 40 are typically compound"""
        return self.canonical_rating >= 40


@dataclass
class ScoredExercise:
    """Exercise with calculated score"""
    exercise: Exercise
    score: int
    is_compound: bool


def calculate_score(exercise: Exercise, experience_level: str) -> int:
    """
    Calculate score for an exercise.
    Uses canonical_rating directly as the scoring mechanism (matching Swift).
    Higher canonical_rating = more important/compound exercises get higher scores.
    """
    return exercise.canonical_rating


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


def mcv_select_exercises(
    candidates: List[ScoredExercise],
    count: int,
    excluded_canonical_names: set = None,
    excluded_display_names: set = None,
    allow_display_name_repeats: bool = False
) -> Tuple[List[ScoredExercise], bool]:
    """
    MCV Heuristic selection matching Swift implementation exactly.

    Returns (selected_exercises, was_relaxed)
    """
    excluded_canonical_names = excluded_canonical_names or set()
    excluded_display_names = excluded_display_names or set()

    # Hard constraints: filter by canonical names (within session)
    available_pool = [c for c in candidates if c.exercise.canonical_name not in excluded_canonical_names]

    # Soft constraint: filter by display names (across programme) unless relaxed
    if not allow_display_name_repeats:
        available_pool = [c for c in available_pool if c.exercise.display_name not in excluded_display_names]

    # Sort by canonical_rating (descending) with tie-breaker by display_name (ascending) for determinism
    sorted_pool = sorted(available_pool, key=lambda c: (-c.exercise.canonical_rating, c.exercise.display_name))

    selected_exercises = []
    used_canonical_names = set()
    relaxation_used = allow_display_name_repeats and excluded_display_names

    for candidate in sorted_pool:
        if len(selected_exercises) >= count:
            break

        # Skip if canonical name already used in this selection
        if candidate.exercise.canonical_name in used_canonical_names:
            continue

        selected_exercises.append(candidate)
        used_canonical_names.add(candidate.exercise.canonical_name)

    return selected_exercises, relaxation_used


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
