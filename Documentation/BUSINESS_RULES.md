# trAIn Business Rules & Logic

> **Purpose**: This document explains all the key business rules and logic across both the web and iOS apps in simple pseudocode that anyone can understand.

**Last Updated**: November 14, 2024
**Applies to**: trAIn Web & trAIn iOS

---

## Table of Contents

1. [Workout Logger - Progression/Regression Prompts (Web App)](#1-workout-logger---progressionregression-prompts-web-app)
2. [Workout Logger - Rep Counter (Web App)](#2-workout-logger---rep-counter-web-app)
3. [Program Generation - Split Selection (iOS App)](#3-program-generation---split-selection-ios-app)
4. [Program Generation - Sets & Reps (iOS App)](#4-program-generation---sets--reps-ios-app)
5. [Program Generation - Rest Periods (iOS App)](#5-program-generation---rest-periods-ios-app)
6. [Program Generation - Exercise Selection by Experience Level (iOS App)](#6-program-generation---exercise-selection-by-experience-level-ios-app)
7. [Exercise Scoring System (iOS App)](#7-exercise-scoring-system-ios-app)

---

## 1. Workout Logger - Progression/Regression Prompts

### What This Does
After you complete all 3 sets of an exercise, the app shows you feedback on whether you should increase weight (progression), decrease weight (regression), or keep doing what you're doing (consistency).

### The Rules (Traffic Light System)

```
WHEN all 3 sets are completed for an exercise:

  GET Set 1 reps, Set 2 reps, Set 3 reps
  GET target rep range (min and max)

  // 🔴 RED LIGHT - Regression (Highest Priority)
  IF Set 1 reps < minimum target OR Set 2 reps < minimum target:
    SHOW regression prompt
    MESSAGE: "⚠️ Form check needed - reduce weight"
    EXPLANATION: "Your first 2 sets fell below the target range"
    STOP (don't check other conditions)

  // 🟢 GREEN LIGHT - Progression (Medium Priority)
  IF Set 1 reps >= maximum target
     AND Set 2 reps >= maximum target
     AND Set 3 reps >= minimum target:
    SHOW progression prompt
    MESSAGE: "💪 Ready to progress - increase weight next session"
    EXPLANATION: "First 2 sets at/above max, 3rd set in range"
    STOP

  // 🟡 AMBER LIGHT - Consistency (Special Case)
  IF Set 1 reps >= maximum target
     AND Set 2 reps >= maximum target
     AND Set 3 reps < minimum target:
    SHOW consistency prompt
    MESSAGE: "🎯 Great consistency - maintain and push on 3rd set"
    EXPLANATION: "Strong start but 3rd set fell short"
    STOP

  // 🟡 AMBER LIGHT - Consistency (Default)
  ELSE:
    SHOW consistency prompt
    MESSAGE: "🎯 Great work - maintain this weight"
    EXPLANATION: "Everything within target range or mixed results"
```

### Examples

**Example 1: Regression**
- Target: 8-12 reps
- Set 1: 7 reps, Set 2: 6 reps, Set 3: 5 reps
- **Result**: 🔴 Regression (Sets 1 & 2 below minimum of 8)

**Example 2: Progression**
- Target: 8-12 reps
- Set 1: 12 reps, Set 2: 12 reps, Set 3: 10 reps
- **Result**: 🟢 Progression (Sets 1 & 2 at max, Set 3 in range)

**Example 3: Consistency (Special)**
- Target: 8-12 reps
- Set 1: 12 reps, Set 2: 13 reps, Set 3: 7 reps
- **Result**: 🟡 Consistency (Strong start but 3rd set failed)

**Example 4: Consistency (Default)**
- Target: 8-12 reps
- Set 1: 10 reps, Set 2: 9 reps, Set 3: 8 reps
- **Result**: 🟡 Consistency (All in range)

### Important Notes
- Prompts only show when **all 3 sets** are completed
- There's a 500ms delay (debounce) to prevent flickering while typing
- Regression **always wins** if any of first 2 sets are below minimum
- We focus on first 2 sets because set 3 is expected to be harder (fatigue)

---

## 2. Workout Logger - Rep Counter

### What This Does
Shows you how many extra reps you did compared to your last session for that same exercise. Displays as a green badge with "+X reps".

### The Rules

```
FOR each exercise:

  FOR each set (1, 2, 3):
    GET current session reps for this set
    GET previous session reps for this set (from database)

    IF current reps > previous reps:
      excess reps = excess reps + (current reps - previous reps)

  IF excess reps > 0:
    SHOW green badge with "+{excess reps} reps"
    ANIMATE with pop effect (300ms)
  ELSE:
    HIDE the badge
```

### Examples

**Example 1: Improvement**
- Previous Session: Set 1: 10 reps, Set 2: 9 reps, Set 3: 8 reps
- Current Session: Set 1: 12 reps, Set 2: 10 reps, Set 3: 9 reps
- Calculation: (12-10) + (10-9) + (9-8) = 2 + 1 + 1 = +4 reps
- **Result**: Show "+4 reps" badge

**Example 2: Same Performance**
- Previous Session: Set 1: 10 reps, Set 2: 10 reps, Set 3: 10 reps
- Current Session: Set 1: 10 reps, Set 2: 10 reps, Set 3: 10 reps
- Calculation: 0 + 0 + 0 = 0 reps
- **Result**: Hide badge (no improvement)

**Example 3: Worse Performance**
- Previous Session: Set 1: 12 reps, Set 2: 11 reps, Set 3: 10 reps
- Current Session: Set 1: 10 reps, Set 2: 9 reps, Set 3: 8 reps
- Calculation: All sets are lower, so 0 excess reps
- **Result**: Hide badge

**Example 4: Mixed Results**
- Previous Session: Set 1: 10 reps, Set 2: 10 reps, Set 3: 10 reps
- Current Session: Set 1: 12 reps, Set 2: 9 reps, Set 3: 11 reps
- Calculation: (12-10) + 0 + (11-10) = 2 + 0 + 1 = +3 reps
- **Result**: Show "+3 reps" badge

### Important Notes
- Compares **set by set**, not total reps
- Only counts improvements (never shows negative)
- Updates in real-time as you type (with 500ms debounce)
- Badge has a "pop" animation when the number increases

---

## 3. Program Generation - Split Selection (iOS App)

### What This Does
Based on how many days per week you can train and how long each session is, the app picks the best workout split for you and determines the exact exercise composition for each session.

### The Rules

```
GET user's training days per week (2, 3, 4, or 5)
GET user's session duration ("30-45 min", "45-60 min", or "60-90 min")

CHOOSE split type and session structure:

  IF days = 2:
    IF duration = "30-45 min":
      ASSIGN "Upper/Lower Split"
      SESSIONS:
        - Upper: 1 Chest, 1 Shoulder, 1 Back
        - Lower: 2 Quads, 1 Hamstring, 1 Glute, 1 Core

    IF duration = "45-60 min":
      ASSIGN "Full Body"
      SESSIONS (2x):
        - Full Body: 1 Chest, 1 Shoulder, 1 Back, 1 Quad, 1 Hamstring, 1 Glute, 1 Core

    IF duration = "60-90 min":
      ASSIGN "Full Body"
      SESSIONS (2x):
        - Full Body: 1 Chest, 1 Shoulder, 1 Back, 1 Bicep, 1 Tricep, 1 Quad, 1 Hamstring, 1 Glute, 1 Core

  IF days = 3:
    ASSIGN "Push/Pull/Legs" (all durations)

    IF duration = "30-45 min":
      SESSIONS:
        - Push: 1 Chest, 2 Shoulders, 1 Tricep
        - Pull: 2 Back, 2 Biceps
        - Legs: 1 Quad, 1 Hamstring, 1 Glute, 1 Core

    IF duration = "45-60 min":
      SESSIONS:
        - Push: 2 Chest, 2 Shoulders, 1 Tricep
        - Pull: 3 Back, 2 Biceps
        - Legs: 2 Quads, 2 Hamstrings, 1 Glute, 1 Core

    IF duration = "60-90 min":
      SESSIONS:
        - Push: 3 Chest, 3 Shoulders, 2 Triceps
        - Pull: 3 Back, 3 Biceps
        - Legs: 2 Quads, 2 Hamstrings, 1 Glute, 1 Core

  IF days = 4:
    ASSIGN "Upper/Lower Split" (all durations)

    IF duration = "30-45 min":
      SESSIONS (2x Upper, 2x Lower):
        - Upper: 1 Chest, 1 Shoulder, 1 Back
        - Lower: 1 Quad, 1 Hamstring, 1 Glute, 1 Core

    IF duration = "45-60 min":
      SESSIONS (2x Upper, 2x Lower):
        - Upper: 2 Chest, 2 Shoulders, 2 Back
        - Lower: 2 Quads, 2 Hamstrings, 1 Glute, 1 Core

    IF duration = "60-90 min":
      SESSIONS (2x Upper, 2x Lower):
        - Upper: 2 Chest, 2 Shoulders, 2 Back, 1 Tricep, 1 Bicep
        - Lower: 2 Quads, 2 Hamstrings, 1 Glute, 1 Core

  IF days = 5:
    ASSIGN "Hybrid Split" (Push/Pull/Legs + Upper/Lower)

    IF duration = "30-45 min":
      SESSIONS:
        - Push: 1 Chest, 2 Shoulders, 1 Tricep
        - Pull: 2 Back, 2 Biceps
        - Legs: 1 Quad, 1 Hamstring, 1 Glute, 1 Core
        - Upper: 1 Chest, 1 Shoulder, 1 Back
        - Lower: 1 Quad, 1 Hamstring, 1 Glute, 1 Core

    IF duration = "45-60 min":
      SESSIONS:
        - Push: 2 Chest, 2 Shoulders, 1 Tricep
        - Pull: 3 Back, 2 Biceps
        - Legs: 2 Quads, 2 Hamstrings, 1 Glute, 1 Core
        - Upper: 2 Chest, 2 Shoulders, 2 Back
        - Lower: 2 Quads, 2 Hamstrings, 1 Glute, 1 Core

    IF duration = "60-90 min":
      SESSIONS:
        - Push: 3 Chest, 3 Shoulders, 2 Triceps
        - Pull: 3 Back, 3 Biceps
        - Legs: 2 Quads, 2 Hamstrings, 1 Glute, 1 Core
        - Upper: 2 Chest, 2 Shoulders, 2 Back, 1 Tricep, 1 Bicep
        - Lower: 2 Quads, 2 Hamstrings, 1 Glute, 1 Core

  IF days = anything else:
    ASSIGN "Full Body" (fallback)
```

### Important Notes
- Exercise counts (e.g., "1 Chest", "2 Back") represent the number of different exercises for that muscle group
- Exercises NEVER repeat across different session types within the same program
- For example: Bench Press might appear in "Push" day, but will never appear in "Upper" day of the same program
- Session order in the arrays determines the order exercises appear in the workout

### What Each Split Means

**Full Body**
- Train all muscle groups each session
- 2 identical sessions per week
- Best for: 2 days/week with 45-90 min sessions

**Upper/Lower Split**
- One day for upper body, one day for lower body
- Repeat the pattern (Upper/Lower/Upper/Lower for 4-day)
- Best for: 2 days/week (30-45 min) or 4 days/week (all durations)

**Push/Pull/Legs (PPL)**
- Push day: Chest, Shoulders, Triceps
- Pull day: Back, Biceps
- Legs day: Quads, Hamstrings, Glutes, Core
- Best for: 3 days/week (all durations)

**Hybrid Split (5-day)**
- Combines Push/Pull/Legs with Upper/Lower
- Provides variety and higher training frequency
- Best for: 5 days/week (all durations)

### Examples

**Example 1**: 2 days/week, 30-45 min sessions
- **Result**: Upper/Lower Split
- **Upper**: 3 exercises (Chest, Shoulder, Back)
- **Lower**: 5 exercises (2 Quad, Hamstring, Glute, Core)

**Example 2**: 2 days/week, 60-90 min sessions
- **Result**: Full Body
- **Each session**: 9 exercises (all major muscle groups + arms)

**Example 3**: 3 days/week, 45-60 min
- **Result**: Push/Pull/Legs
- **Push**: 5 exercises (2 Chest, 2 Shoulder, Tricep)
- **Pull**: 5 exercises (3 Back, 2 Bicep)
- **Legs**: 6 exercises (2 Quad, 2 Hamstring, Glute, Core)

**Example 4**: 4 days/week, 60-90 min
- **Result**: Upper/Lower Split (2x each)
- **Upper**: 8 exercises (includes arm isolation)
- **Lower**: 6 exercises (comprehensive leg training)

**Example 5**: 5 days/week, 60-90 min
- **Result**: Hybrid Split
- **Total**: 5 different sessions combining PPL and Upper/Lower patterns

---

## 4. Program Generation - Sets & Reps (iOS App)

### What This Does
Based on your fitness goal and experience level, the app assigns how many sets and reps you should do for each exercise.

### The Rules - Rep Ranges

```
GET user's fitness goal

ASSIGN rep range:

  IF goal = "Get Stronger":
    rep range = "5-8 reps"
    REASON: Lower reps with heavier weight builds strength

  IF goal = "Build Muscle":
    rep range = "8-12 reps"
    REASON: Classic hypertrophy range

  IF goal = "Tone Up":
    rep range = "10-15 reps"
    REASON: Higher reps, lighter weight for endurance

  IF goal = anything else:
    rep range = "8-12 reps" (default)
    REASON: Most versatile range
```

### The Rules - Number of Sets

```
ASSIGN number of sets:

  sets = 3 (always)
  REASON: Consistent volume across all experience levels and exercise types
```

### Examples

**Example 1**: Any experience level, wants to get stronger
- **Sets**: 3
- **Reps**: 5-8
- **Workout**: 3 sets of 5-8 reps (heavy weight)

**Example 2**: Any experience level, wants to build muscle
- **Sets**: 3
- **Reps**: 8-12
- **Workout**: 3 sets of 8-12 reps (moderate weight)

**Example 3**: Any experience level, wants to tone up
- **Sets**: 3
- **Reps**: 10-15
- **Workout**: 3 sets of 10-15 reps (lighter weight)

---

## 5. Program Generation - Rest Periods (iOS App)

### What This Does
Determines how long you should rest between sets based on the exercise complexity and how many reps you're doing.

### The Rules

```
GET exercise complexity level (1-4)
  1 = Simple isolation (bicep curl)
  2 = Moderate (dumbbell press)
  3 = Complex (barbell bench press)
  4 = Very complex (squat, deadlift)

GET rep range (from fitness goal)

CALCULATE if low reps:
  low reps = TRUE if rep range starts with "5" or "6"

CALCULATE if high complexity:
  high complexity = TRUE if complexity >= 3

ASSIGN rest time:

  IF high complexity AND low reps:
    rest = 180 seconds (3 minutes)
    REASON: Heavy compound lifts need full recovery
    EXAMPLE: 3 sets of 5 reps back squat

  IF high complexity AND NOT low reps:
    rest = 120 seconds (2 minutes)
    REASON: Complex exercises need good recovery
    EXAMPLE: 3 sets of 10 reps barbell bench press

  IF low reps AND NOT high complexity:
    rest = 150 seconds (2.5 minutes)
    REASON: Heavy work needs recovery even if simpler
    EXAMPLE: 3 sets of 6 reps dumbbell press

  ELSE (normal complexity, normal reps):
    rest = 90 seconds (1.5 minutes)
    REASON: Standard rest for isolation/accessory work
    EXAMPLE: 3 sets of 12 reps bicep curls
```

### Examples

**Example 1**: Back Squat (complexity 4), 5-8 reps
- High complexity: YES
- Low reps: YES
- **Rest**: 180 seconds (3 minutes)

**Example 2**: Barbell Bench Press (complexity 3), 8-12 reps
- High complexity: YES
- Low reps: NO
- **Rest**: 120 seconds (2 minutes)

**Example 3**: Dumbbell Shoulder Press (complexity 2), 5-8 reps
- High complexity: NO
- Low reps: YES
- **Rest**: 150 seconds (2.5 minutes)

**Example 4**: Bicep Curls (complexity 1), 10-15 reps
- High complexity: NO
- Low reps: NO
- **Rest**: 90 seconds (1.5 minutes)

**Example 5**: Deadlift (complexity 4), 8-12 reps
- High complexity: YES
- Low reps: NO
- **Rest**: 120 seconds (2 minutes)

---

## Quick Reference Table

### Web App - Prompt System

| Condition | First 2 Sets | Third Set | Prompt | Color |
|-----------|--------------|-----------|--------|-------|
| Any set below min | < min | Any | Regression | 🔴 Red |
| Strong throughout | ≥ max | ≥ min | Progression | 🟢 Green |
| Strong start, weak finish | ≥ max | < min | Consistency | 🟡 Amber |
| Everything else | Mixed | Mixed | Consistency | 🟡 Amber |

### iOS App - Program Selection

| Days/Week | Session Length | Split Type |
|-----------|---------------|------------|
| 2 | 30-45 min | Upper/Lower |
| 2 | 45-90 min | Full Body |
| 3 | Any | Push/Pull/Legs |
| 4 | Any | Upper/Lower |
| 5-6 | Any | Push/Pull/Legs |

### iOS App - Sets & Reps

| Goal | Rep Range | Sets |
|------|-----------|------|
| Get Stronger | 5-8 | 3 |
| Build Muscle | 8-12 | 3 |
| Tone Up | 10-15 | 3 |

*Note: All experience levels use 3 sets.*

### iOS App - Rest Periods

| Complexity | Rep Range | Rest Time | Use Case |
|------------|-----------|-----------|----------|
| High (3-4) | Low (5-8) | 3 min | Heavy squats, deadlifts |
| High (3-4) | Normal (8-15) | 2 min | Moderate compound lifts |
| Low (1-2) | Low (5-8) | 2.5 min | Heavy dumbbells |
| Low (1-2) | Normal (8-15) | 1.5 min | Isolation exercises |

---

## 6. Program Generation - Exercise Selection by Experience Level (iOS App)

### What This Does
Based on user's experience level, the app determines which exercises are eligible for their program and in what priority order they should be selected.

### Experience Levels
- **No Experience**: Brand new to resistance training
- **Beginner**: 0-6 months experience
- **Intermediate**: 6 months - 2 years experience
- **Advanced**: 2+ years experience

### The Rules

```
FOR each exercise slot in a session:

  GET user's experience level
  GET complexity constraints from database

  // Isolation exercises bypass complexity rules
  IF exercise.is_isolation = 1:
    ALWAYS eligible (any experience level)

  // Compound exercises follow complexity rules
  ELSE:
    SELECT exercises WHERE complexity_level <= max_complexity
    PRIORITIZE in descending order (highest allowed first, fall back to lower)

  // Special rule for Advanced users
  IF experience = ADVANCED AND exercise.complexity_level = 4:
    ONLY allow as first exercise of session
    LIMIT to 1 per session
```

### Priority Order by Experience Level

| Experience | Allowed Complexity | Selection Priority | Notes |
|------------|-------------------|-------------------|-------|
| No Experience | 1 only | 1 | Isolations always allowed |
| Beginner | 1-2 | 2 → 1 | Isolations always allowed |
| Intermediate | 1-3 | 3 → 2 → 1 | Isolations always allowed |
| Advanced | 1-4 | 4 → 3 → 2 → 1 | Max 1× complexity 4, must be first exercise |

### Database Schema

```sql
CREATE TABLE user_experience_complexity (
    experience_level TEXT PRIMARY KEY,  -- NO_EXPERIENCE, BEGINNER, INTERMEDIATE, ADVANCED
    display_name TEXT NOT NULL,
    max_complexity INTEGER NOT NULL,
    allow_complexity_4 INTEGER NOT NULL DEFAULT 0,
    complexity_4_limit INTEGER NOT NULL DEFAULT 0,
    complexity_4_must_be_first INTEGER NOT NULL DEFAULT 0
);

INSERT INTO user_experience_complexity VALUES
    ('NO_EXPERIENCE', 'No Experience', 1, 0, 0, 0),
    ('BEGINNER', 'Beginner', 2, 0, 0, 0),
    ('INTERMEDIATE', 'Intermediate', 3, 0, 0, 0),
    ('ADVANCED', 'Advanced', 4, 1, 1, 1);
```

### Swift Implementation

```swift
func selectExercise(for slot: ProgramSlot, userLevel: ExperienceLevel) -> Exercise? {
    let constraints = getConstraints(for: userLevel)

    // Build priority list based on level (descending from max)
    var priorityLevels = Array((1...constraints.maxComplexity).reversed())

    // For complexity 4: check limit and position
    if constraints.allowComplexity4 {
        if slot.position != 1 || session.complexity4Count >= constraints.complexity4Limit {
            priorityLevels.removeAll { $0 == 4 }
        }
    }

    // Try each priority level
    for complexity in priorityLevels {
        if let exercise = findExercise(complexity: complexity, slot: slot) {
            return exercise
        }
    }

    return nil
}

func getEligibleExercises(userLevel: ExperienceLevel, slot: ProgramSlot) -> [Exercise] {
    let constraints = getConstraints(for: userLevel)

    return exercises.filter { exercise in
        // Isolations always allowed for any level
        if exercise.isIsolation { return true }

        // Compounds must meet complexity constraint
        return exercise.complexityLevel <= constraints.maxComplexity
    }
}
```

### Examples

**Example 1**: No Experience user, Chest slot
- Eligible: Complexity 1 compounds + all isolations
- Selected: Push Up (complexity 1) or Cable Chest Fly (isolation)

**Example 2**: Beginner user, Quad slot
- Eligible: Complexity 1-2 compounds + all isolations
- Priority: Try complexity 2 first → Goblet Squat
- Fallback: If no complexity 2 available → complexity 1

**Example 3**: Intermediate user, Back slot
- Eligible: Complexity 1-3 compounds + all isolations
- Priority: Try complexity 3 first → Barbell Bent Over Row
- Fallback: complexity 2 → complexity 1

**Example 4**: Advanced user, first exercise of Leg day
- Eligible: Complexity 1-4 compounds + all isolations
- Priority: Try complexity 4 first → Barbell Back Squat
- Note: Only ONE complexity 4 exercise per session, MUST be first

**Example 5**: Advanced user, second exercise of Leg day
- Eligible: Complexity 1-3 only (complexity 4 already used or not first)
- Priority: 3 → 2 → 1

### Important Notes
- `is_isolation` flag in database bypasses all complexity rules
- Complexity constraints stored in database, priority logic in code
- Advanced users get complexity 4 exercises but with strict limits
- Selection always tries highest allowed complexity first, falls back to lower

---

## Glossary

**Set**: A group of repetitions (e.g., "3 sets of 10 reps" means do 10 reps, rest, do 10 reps, rest, do 10 reps)

**Rep (Repetition)**: One complete movement of an exercise

**Rep Range**: The target number of reps (e.g., "8-12" means aim for 8-12 reps per set)

**Complexity Level**: How technically difficult an exercise is (1 = easy, 4 = very hard)

**Split**: How you divide muscle groups across different training days

**Full Body**: Training all major muscle groups in one session

**Upper/Lower**: One day for upper body muscles, one day for lower body muscles

**Push/Pull/Legs (PPL)**: Push muscles (chest, shoulders, triceps), Pull muscles (back, biceps), Legs (quads, hamstrings, glutes)

**Progression**: When you're ready to increase weight

**Regression**: When you need to decrease weight

**Consistency**: When you should maintain current weight

**Debounce**: A small delay to prevent flickering/rapid changes (like waiting 500ms before showing a prompt)

---

## 7. Exercise Scoring System (iOS App)

### What This Does
The scoring system is a weighted random selection algorithm that determines which exercises to include in a user's program. Higher-scored exercises have a greater probability of being selected, but randomization ensures variety across generated programs.

### Stage 1: Build User Pool

Before scoring, the app builds a pool of available exercises:

```
User Pool = exercises WHERE:
  - equipment_category IN user's selected equipment
  - complexity_level <= max_complexity (from user_experience_complexity table)
  - is_in_programme = 1
```

**Important**:
- Max complexity is read from the database, NOT hardcoded.
- Injuries do NOT filter exercises - they only display warning icons in the Workout Overview UI.

| Experience Level | Max Complexity from DB |
|-----------------|------------------------|
| NO_EXPERIENCE   | 2                      |
| BEGINNER        | 3                      |
| INTERMEDIATE    | 3                      |
| ADVANCED        | 4                      |

### Stage 2: Scoring Rules

#### Compound Exercises (is_isolation = false)

| Complexity Level | Score (Points) | Selection Probability |
|------------------|----------------|----------------------|
| 4                | 20             | Highest              |
| 3                | 15             | High                 |
| 2                | 10             | Medium               |
| 1                | 5              | Low                  |

#### Isolation Exercises (is_isolation = true)

| Experience Level | Score (Points) |
|------------------|----------------|
| Advanced         | 8              |
| Intermediate     | 6              |
| Beginner/NoExp   | 4              |

### The Selection Algorithm

```
1. Build User Pool (filtered by equipment + complexity)
2. Score all exercises in pool

3. IF experience allows complexity 4 AND must be first:
   - Select one complexity-4 compound using weighted random
   - Mark as first exercise

4. FOR each remaining exercise slot:
   - IF complexity-4 already selected:
     - Cap remaining candidates at complexity 3
   - Prefer exercises with different canonical_names (variety)
   - Use weighted random selection:
     probability(exercise) = exercise.score / sum(all_scores)

5. SORT final list for display:
   - Compounds first, then isolations
   - Within each group: higher complexity first
```

### Weighted Random Selection Example

Given a pool with these scores:
- Barbell Squat: 20 points
- Romanian Deadlift: 15 points
- Leg Press: 10 points
- Leg Extension: 6 points

Total = 51 points

Selection probabilities:
- Barbell Squat: 20/51 = 39.2%
- Romanian Deadlift: 15/51 = 29.4%
- Leg Press: 10/51 = 19.6%
- Leg Extension: 6/51 = 11.8%

### Stage 3: Sort for Display

Final exercise order in the workout:

```
1. Compounds (is_isolation = false)
   - Ordered by complexity: 4 → 3 → 2 → 1

2. Isolations (is_isolation = true)
   - Ordered by complexity: 4 → 3 → 2 → 1
```

**Rationale**: Perform demanding exercises when fresh, then move to targeted isolation work.

### Stage 4: Error Handling

The system generates warnings for UI display:

| Warning Type | Trigger Condition | User Message |
|-------------|-------------------|--------------|
| `noExercisesForMuscle` | Empty pool after filtering | "No exercises available for {muscle}. Check your equipment selection." |
| `insufficientExercises` | Found fewer than requested | "Only found {found} of {requested} exercises for {muscle}." |
| `equipmentLimitedSelection` | Very few options available | "Limited exercise variety for {muscle} with selected equipment." |

Warnings are displayed via native iOS alert after program generation completes.

**Note**: Injuries do NOT generate warnings during selection - contraindicated exercises are included in the program but display a warning icon in the Workout Overview UI.

### Key Implementation Files

- `ExerciseRepository.swift` - Core scoring and selection logic
- `DynamicProgramGenerator.swift` - Session generation orchestration
- `WorkoutViewModel.swift` - Warning alert state management
- `QuestionnaireView.swift` - Alert presentation

---

**Document Version**: 3.0
**Created**: December 5, 2025
**Updated**: December 9, 2025
**Authors**: Luke Vassor & Brody Bastiman
**Applies to**: trAIn Web (JavaScript) & trAIn iOS (Swift)
