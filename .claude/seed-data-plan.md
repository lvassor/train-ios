# Seed Data Plan: Realistic Workout History Generator

## Goal
Create a `SeedDataManager.swift` gated behind `#if DEBUG` that populates the app with ~6-8 weeks of realistic workout history for the current user, so all data-driven views (dashboard, calendar, streaks, exercise history, milestones, workout summary) display genuine-looking data instead of hardcoded mocks.

---

## Architecture

### File: `TrainSwift/Debug/SeedDataManager.swift`

Wrapped entirely in `#if DEBUG ... #endif`.

### Entry Point
A static method callable from a debug menu or SwiftUI preview:
```swift
static func seedWorkoutHistory(for user: UserProfile, context: NSManagedObjectContext)
```

### Trigger
Add a hidden debug button in `ProfileView` (or a shake gesture) — only compiled in DEBUG builds.

---

## Data Generation Strategy

### Step 1: Read the User's Active Program
- Fetch `WorkoutProgram.fetchCurrent(forUserId:context:)` for the logged-in user
- Decode `exercisesData` into `[ProgramSession]` via `getProgram()`
- This gives us the real exercise names, IDs, sets, rep ranges — consistent with what the user sees in the app

### Step 2: Generate Historical Sessions
- **Scope**: 6 weeks of completed history + current week partially complete
- **Frequency**: Match the program's `daysPerWeek` (e.g., 3x/week for PPL)
- **Dates**: Work backwards from today, spacing sessions ~2-3 days apart with realistic variance (skip a day here and there, no sessions on some weeks to simulate real life)
- **Session names**: Cycle through the program's `ProgramSession.dayName` values in order (Push → Pull → Legs → Push → ...)

### Step 3: Generate Realistic Exercise Data per Session
For each session, iterate through its `ProgramExercise` list and create `LoggedExercise` entries:

#### Weight Progression Model
| Exercise Type | Starting Weight (kg) | Weekly Increment |
|---|---|---|
| Squat/Deadlift (canonical_rating > 80, lower body) | 60-80 | +2.5 kg/week |
| Bench/Row/OHP (canonical_rating > 60, upper compound) | 40-60 | +2.5 kg/week |
| Isolation (canonical_rating <= 40) | 8-15 | +1.0 kg/week |
| Bodyweight (EP043) | 0 (bodyweight) | +1 rep/week |

Base weights randomized within range, then increment linearly per week with ±1kg jitter.

#### Rep Generation
- Parse `repRange` (e.g., "8-12") → target the middle (10)
- Set 1: target reps (e.g., 10)
- Set 2: target reps or target - 1 (fatigue)
- Set 3: target - 1 or target - 2 (more fatigue)
- Occasional "bad day": all reps drop by 2 (~15% chance per session)

#### Set Completion
- 95% of sets marked `completed: true`
- 5% chance a set is incomplete (reps = 2-4, completed = false) — simulates failure

#### Notes
- 80% of exercises have empty notes
- 20% get a random note from a pool: "Felt strong", "Grip slipping", "Increase next time", "Lower back tight", "Form check needed"

### Step 4: Generate CDWorkoutSession Records
For each generated session:
```swift
CDWorkoutSession.create(
    userId: user.id,
    programId: program.id,
    sessionName: dayName,        // "Push", "Pull", etc.
    weekNumber: weekNum,         // 1-8
    exercises: loggedExercises,  // [LoggedExercise]
    durationMinutes: duration,   // 35-75, varies
    context: context
)
```

Then manually override `completedAt` to the historical date (since `.create()` sets it to `Date()`).

#### Duration Generation
- Base duration from program's `sessionDuration`:
  - "30-45 min" → random 30-45
  - "45-60 min" → random 42-62
  - "60-90 min" → random 55-80
- ±5 min jitter

### Step 5: Update Program Completion State
- Populate `completedSessionsData` with `Set<String>` of `"week1-session0"`, `"week1-session1"`, etc. for all generated weeks
- Set `currentWeek` and `currentSessionIndex` to match (e.g., week 7, session 1 if 6 weeks fully done + 1 session into week 7)

### Step 6: Save Context
Single `context.save()` at the end.

---

## Sample Generated Timeline (3-day PPL program)

| Date | Session | Week |
|---|---|---|
| 6 weeks ago, Mon | Push (Week 1) | 1 |
| 6 weeks ago, Wed | Pull (Week 1) | 1 |
| 6 weeks ago, Fri | Legs (Week 1) | 1 |
| 5 weeks ago, Mon | Push (Week 2) | 2 |
| ... | ... | ... |
| This week, Mon | Push (Week 7) | 7 |
| This week, Wed | Pull (Week 7) | 7 |
| *(next session upcoming)* | Legs (Week 7) | — |

---

## Reset Function
```swift
static func clearSeedData(for user: UserProfile, context: NSManagedObjectContext)
```
Deletes all `CDWorkoutSession` for the user and resets the program's `completedSessionsData`, `currentWeek`, and `currentSessionIndex`.

---

## Exercise-Specific Weight Tables (Realistic Defaults)

These are starting weights for week 1, based on an intermediate male user. The seed function should scale these by a factor (0.5x for beginners, 1.0x for intermediate, 1.2x for advanced) read from `user.experience`.

| Exercise Display Name | Start Weight (kg) | Category |
|---|---|---|
| Barbell Back Squat | 70 | Heavy compound |
| Barbell Front Squat | 55 | Heavy compound |
| Barbell Deadlift | 80 | Heavy compound |
| Barbell Romanian Deadlift | 60 | Heavy compound |
| Barbell Bench Press | 60 | Upper compound |
| Incline Barbell Bench Press | 50 | Upper compound |
| Barbell Overhead Press | 35 | Upper compound |
| Barbell Bent Over Row | 55 | Upper compound |
| Pull Up | 0 (BW) | Bodyweight |
| Dips | 0 (BW) | Bodyweight |
| Dumbbell Bench Press | 22 | Dumbbell compound |
| Dumbbell Goblet Squat | 20 | Dumbbell compound |
| Dumbbell Romanian Deadlift | 20 | Dumbbell compound |
| Seated Dumbbell Overhead Press | 16 | Dumbbell compound |
| Dumbbell Lateral Raise | 8 | Isolation |
| Dumbbell Curl | 10 | Isolation |
| Dumbbell Hammer Curl | 10 | Isolation |
| Barbell Curl | 20 | Isolation |
| Straight Bar Pushdown | 20 | Isolation (cable) |
| Leg Press | 100 | Machine compound |
| Leg Extension | 40 | Machine isolation |
| Lying Leg Curl | 30 | Machine isolation |
| Cable Chest Fly | 10 | Cable isolation |
| Lat Pulldown | 45 | Cable compound |

For any exercise not in this table, estimate from:
- `primaryMuscle` (legs heavier than arms)
- `canonical_rating` (higher = heavier load typically)
- `equipmentType` (barbell > dumbbell > cable > bodyweight)

---

## Dependencies
- `PersistenceController.shared.container.viewContext`
- `AuthService.shared.currentUser`
- `WorkoutProgram.fetchCurrent(forUserId:context:)`
- `CDWorkoutSession.create(...)`
- `LoggedExercise` / `LoggedSet` models
- No dependency on `ExerciseDatabaseManager` (we read exercises from the program itself)

---

## Safety
- Entire file wrapped in `#if DEBUG`
- Debug trigger only in DEBUG builds
- `clearSeedData()` available to reset
- Does NOT modify the program's `exercisesData` (only completion tracking)
- Does NOT create new users or programs — works with existing data only
