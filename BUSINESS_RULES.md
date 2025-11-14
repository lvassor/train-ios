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

---

## 1. Workout Logger - Progression/Regression Prompts (Web App)

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

## 2. Workout Logger - Rep Counter (Web App)

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
Based on how many days per week you can train and how long each session is, the app picks the best workout split for you.

### The Rules

```
GET user's training days per week (2, 3, 4, 5, or 6)
GET user's session duration ("30-45 min", "45-60 min", or "60-90 min")

CHOOSE split type:

  IF days = 2:
    IF duration = "30-45 min":
      ASSIGN "Upper/Lower Split"
      REASON: Short sessions need focused splits
    ELSE:
      ASSIGN "Full Body"
      REASON: Longer sessions can handle full body

  IF days = 3:
    ASSIGN "Push/Pull/Legs"
    REASON: Perfect for 3-day split

  IF days = 4:
    ASSIGN "Upper/Lower Split"
    REASON: Best for 4 days (Upper/Lower/Upper/Lower)

  IF days = 5 OR days = 6:
    ASSIGN "Push/Pull/Legs"
    REASON: Can repeat the cycle (Push/Pull/Legs/Push/Pull/Legs)

  IF days = anything else:
    ASSIGN "Full Body" (fallback)
    REASON: Safe default
```

### What Each Split Means

**Full Body**
- Train all muscle groups each session
- 2 different workouts (A and B) that alternate
- Best for: 2-3 days/week with longer sessions

**Upper/Lower Split**
- One day for upper body, one day for lower body
- Repeat the pattern (Upper/Lower/Upper/Lower)
- Best for: 2 or 4 days/week

**Push/Pull/Legs (PPL)**
- Push day: Chest, Shoulders, Triceps
- Pull day: Back, Biceps
- Legs day: Quads, Hamstrings, Glutes, Calves
- Best for: 3, 5, or 6 days/week

### Examples

**Example 1**: 2 days/week, 30-45 min sessions
- **Result**: Upper/Lower Split

**Example 2**: 2 days/week, 60-90 min sessions
- **Result**: Full Body

**Example 3**: 3 days/week (any duration)
- **Result**: Push/Pull/Legs

**Example 4**: 4 days/week (any duration)
- **Result**: Upper/Lower Split

**Example 5**: 5 days/week (any duration)
- **Result**: Push/Pull/Legs

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
GET user's experience level

ASSIGN number of sets:

  IF experience = "Beginner":
    sets = 3
    REASON: Build foundation without overtraining

  IF experience = "Intermediate":
    sets = 3
    REASON: Balanced volume for continued progress

  IF experience = "Advanced":
    sets = 4
    REASON: More volume needed to progress
```

### Examples

**Example 1**: Beginner, wants to get stronger
- **Sets**: 3
- **Reps**: 5-8
- **Workout**: 3 sets of 5-8 reps (heavy weight)

**Example 2**: Intermediate, wants to build muscle
- **Sets**: 3
- **Reps**: 8-12
- **Workout**: 3 sets of 8-12 reps (moderate weight)

**Example 3**: Advanced, wants to tone up
- **Sets**: 4
- **Reps**: 10-15
- **Workout**: 4 sets of 10-15 reps (lighter weight)

**Example 4**: Beginner, wants to tone up
- **Sets**: 3
- **Reps**: 10-15
- **Workout**: 3 sets of 10-15 reps

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

| Goal | Rep Range | Experience | Sets |
|------|-----------|------------|------|
| Get Stronger | 5-8 | Beginner | 3 |
| Get Stronger | 5-8 | Intermediate | 3 |
| Get Stronger | 5-8 | Advanced | 4 |
| Build Muscle | 8-12 | Beginner | 3 |
| Build Muscle | 8-12 | Intermediate | 3 |
| Build Muscle | 8-12 | Advanced | 4 |
| Tone Up | 10-15 | Beginner | 3 |
| Tone Up | 10-15 | Intermediate | 3 |
| Tone Up | 10-15 | Advanced | 4 |

### iOS App - Rest Periods

| Complexity | Rep Range | Rest Time | Use Case |
|------------|-----------|-----------|----------|
| High (3-4) | Low (5-8) | 3 min | Heavy squats, deadlifts |
| High (3-4) | Normal (8-15) | 2 min | Moderate compound lifts |
| Low (1-2) | Low (5-8) | 2.5 min | Heavy dumbbells |
| Low (1-2) | Normal (8-15) | 1.5 min | Isolation exercises |

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

**Document Version**: 1.0
**Created**: November 14, 2024
**Authors**: Luke Vassor & Brody Bastiman
**Applies to**: trAIn Web (JavaScript) & trAIn iOS (Swift)
