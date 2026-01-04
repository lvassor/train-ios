# Train App Documentation - Rules

## Table of Contents

1. [Workout Logger - Progression/Regression Prompts](#1-workout-logger---progressionregression-prompts)
2. [Workout Logger - Rep Counter](#2-workout-logger---rep-counter)
3. [Programme Generation](#3-programme-generation)

---

## 1. Workout Logger - Progression/Regression Prompts

After a user completes all 3 sets of an exercise, the app shows feedback on whether they should increase weight (progression), decrease weight (regression), or keep doing what you're doing (consistency).

### Rules (Traffic Light System)

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

### Important Notes
- Prompts only show when **all 3 sets** are completed
- There's a 500ms delay (debounce) to prevent flickering while typing
- Regression **always wins** if any of first 2 sets are below minimum
- We focus on first 2 sets because set 3 is expected to be harder (fatigue)

---

## 2. Workout Logger - Rep Counter

Shows the user how many extra reps they did compared to their last session for that same exercise. Displays as a green badge with "+X reps".

### Rules

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

### Important Notes
- Compares **set by set**, not total reps
- Only counts improvements (never shows negative)
- Updates in real-time as you type (with 500ms debounce)
- Badge has a "pop" animation when the number increases

---

## 3. Programme Generation

When a user completes the questionnaire, the app generates a personalised workout programme. This section details the rules governing that generation.

### 3.1 Split Type Selection

Based on training days per week and session duration, the app selects a workout split. Splits follow the [Split Templates](split_templates.json) file.

**Deduplication Rules:**
- Exercise display names do not repeat ANYWHERE within a programme
- Exercise canonical names do not repeat WITHIN a session (but may repeat between sessions)
- If a muscle is in the user's "target muscle groups", it gets +1 exercise

### 3.2 Experience-Based Complexity Rules

| Experience Level | Max Complexity | Complexity-4 Rules |
|------------------|----------------|-------------------|
| No Experience | 1 | Not allowed |
| Beginner | 2 | Not allowed |
| Intermediate | 3 | Not allowed |
| Advanced | 4 | Max 1 per session, must be first exercise |

### 3.3 Exercise Pool Construction

```
FOR each muscle group in the session template:

  BUILD exercise pool WHERE:
    - equipment_category matches user's available equipment
    - complexity_level <= user's max complexity
    - is_in_programme = 1 (flagged for inclusion)
    - exercise_id NOT already used in this programme
    - display_name NOT already used in this programme
    - canonical_name NOT already used in this SESSION
```

### 3.4 Exercise Scoring & Selection

**Compound Exercise Scores:**

| Complexity | Score |
|------------|-------|
| 4 | 100 points |
| 3 | 50 points |
| 2 | 20 points |
| 1 | 5 points |

**Isolation Exercise Scores:**

| Experience | Score |
|------------|-------|
| Advanced | 10 points |
| Intermediate | 6 points |
| Beginner / No Experience | 5 points |

**Selection Algorithm:**

```
FOR each exercise slot needed:

  IF this is the first slot AND user is Advanced AND complexity-4 allowed:
    SELECT from complexity-4 exercises only (weighted random)
    REMOVE all exercises with same canonical_name from pool

  ELSE:
    IF session already has a complexity-4 exercise:
      FILTER pool to complexity ≤ 3

    CALCULATE probability for each exercise:
      probability = exercise_score / total_pool_score

    SELECT one exercise using weighted random
    REMOVE all exercises with same canonical_name from pool
```

### 3.5 Sets, Reps, and Rest Assignment

**Rep Ranges (based on goal):**

| Goal | Rep Range |
|------|-----------|
| Get Stronger | 5-8 reps |
| Build Muscle | 8-12 reps |
| Tone Up | 10-15 reps |

**Number of Sets (based on experience):**

| Experience | Sets |
|------------|------|
| No Experience / Beginner / Intermediate | 3 sets |
| Advanced | 4 sets |

**Rest Periods:**

```
IF high complexity (≥3) AND low reps (5-6):
  rest = 180 seconds (3 minutes)

IF high complexity (≥3) AND normal reps:
  rest = 120 seconds (2 minutes)

IF low reps AND lower complexity:
  rest = 150 seconds (2.5 minutes)

ELSE:
  rest = 90 seconds (1.5 minutes)
```

### 3.6 Exercise Display Order

```
1. Compound exercises first (sorted by complexity: highest → lowest)
2. Isolation exercises second (sorted by complexity: highest → lowest)
```

### 3.7 Warning Handling

| Situation | Warning Shown |
|-----------|---------------|
| No exercises found for a muscle | "No exercises available for {muscle}. Check your equipment selection." |
| Fewer exercises than requested | "Only found {X} of {Y} exercises for {muscle}." |

**Note on injuries**: User-reported injuries do NOT filter exercises from the programme. Instead, contraindicated exercises are included but display a warning icon in the Workout Overview UI.

---

**Document Version**: 4.1<br>
**Created**: December 5, 2025<br>
**Updated**: January 3, 2026<br>
**Authors**: Luke Vassor & Brody Bastiman<br>
**Applies to**: trAIn iOS (Swift)
