# Train App - Rule Examples

This document provides worked examples of the rules defined in [App Rules](app_rules.md).

---

## 1. Workout Logger Examples

### 1.1 Progression/Regression Prompt Examples

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

### 1.2 Rep Counter Examples

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

---

## 2. Programme Generation Examples

### 2.1 Sets & Reps Examples

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

**Example 4**: Advanced user, any goal
- **Sets**: 4
- **Reps**: Based on goal (see above)
- **Workout**: 4 sets (Advanced users get extra volume)

### 2.2 Rest Period Examples

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

### 2.3 Exercise Selection Example (Weighted Random)

**Scenario**: Selecting a Quad exercise for an Intermediate user

Pool after filtering:
- Leg Press (complexity 2): 20 points
- Goblet Squat (complexity 2): 20 points
- Leg Extension (isolation): 6 points

Total = 46 points

Selection probabilities:
- Leg Press: 20/46 = 43.5%
- Goblet Squat: 20/46 = 43.5%
- Leg Extension: 6/46 = 13%

### 2.4 Complete Programme Example

**User Profile:**
- Experience: Intermediate
- Days per week: 3
- Duration: 45-60 min
- Goal: Build Muscle
- Equipment: Dumbbells, Cables, Pin-Loaded Machines

**Generated Programme:**

**Push Day:**
1. Dumbbell Bench Press (complexity 2) — 3 sets × 8-12 reps, 120s rest
2. Dumbbell Shoulder Press (complexity 2) — 3 sets × 8-12 reps, 120s rest
3. Cable Chest Fly (isolation) — 3 sets × 8-12 reps, 90s rest
4. Cable Lateral Raise (isolation) — 3 sets × 8-12 reps, 90s rest
5. Cable Tricep Pushdown (isolation) — 3 sets × 8-12 reps, 90s rest

**Pull Day:**
1. Cable Lat Pulldown (complexity 2) — 3 sets × 8-12 reps, 120s rest
2. Cable Seated Row (complexity 2) — 3 sets × 8-12 reps, 120s rest
3. Dumbbell Row (complexity 2) — 3 sets × 8-12 reps, 120s rest
4. Dumbbell Bicep Curl (isolation) — 3 sets × 8-12 reps, 90s rest
5. Cable Hammer Curl (isolation) — 3 sets × 8-12 reps, 90s rest

**Legs Day:**
1. Leg Press (complexity 2) — 3 sets × 8-12 reps, 120s rest
2. Dumbbell Romanian Deadlift (complexity 2) — 3 sets × 8-12 reps, 120s rest
3. Leg Extension (isolation) — 3 sets × 8-12 reps, 90s rest
4. Lying Leg Curl (isolation) — 3 sets × 8-12 reps, 90s rest
5. Cable Hip Abduction (isolation) — 3 sets × 8-12 reps, 90s rest
6. Cable Crunch (isolation) — 3 sets × 8-12 reps, 90s rest

---

**Document Version**: 2.0<br>
**Created**: December 5, 2025<br>
**Updated**: January 3, 2026<br>
**Authors**: Luke Vassor & Brody Bastiman<br>
**Applies to**: trAIn iOS (Swift)
