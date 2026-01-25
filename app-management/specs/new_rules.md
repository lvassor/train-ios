# Train App Documentation - Rules

## Table of Contents

1. [Workout Logger - Progression/Regression Prompts](#1-workout-logger---progressionregression-prompts)
2. [Workout Logger - Rep Counter](#2-workout-logger---rep-counter)
3. [Questionnaire - Split Selection](#3-questionnaire---split-selection)
4. [Programme Generation](#4-programme-generation)
5. [App Warnings & Modal Overlays](#5-app-warnings--modal-overlays)

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

## 3. Questionnaire - Split Selection

The questionnaire includes a Split Selection step that appears after the user selects their training days per week. This step presents split options based on their selected day count, with recommendations based on experience level and muscle group priorities.

### 3.1 Split Selection Step

**When it appears:**
- After Training Days per Week question
- Shows splits available for the selected day count
- Reads from `trAInSwift/resources/split_templates.json` to get available splits

**Display order:**
1. Recommended splits first (with "Recommended" label)
2. Non-recommended splits after

### 3.2 Recommendation Logic

**For 2-day training:**
- **Beginners/No experience:** Full Body recommended
- **Intermediate/Advanced:** Upper/Lower recommended

**For 3-day training:**
- **Beginners/No experience:** Full Body recommended
- **Intermediate/Advanced with 2+ leg priority muscles:** 1 Upper 2 Lower recommended
- **Intermediate/Advanced with 2+ upper priority muscles:** 2 Upper 1 Lower recommended
- **Intermediate/Advanced (default):** Push/Pull/Legs recommended

**Priority muscle categorization:**
- **Upper muscles:** Chest, Shoulders, Back, Biceps, Triceps, Traps
- **Lower muscles:** Quads, Hamstrings, Glutes, Calves, Abductors, Adductors

### 3.3 Split Explanations
Split explanations are displayed within the split cards of the recommended splits, which have their own page after all the user requirements have been input during the onboarding questions. Split name forms the title and the split explanation forms the subtitle description text as in other answer options of the questionnaire.

# Programme Splits

| Split | Name | Message |
|-------|------|---------|
| 1 Day | Full Body | Hit every muscle group in one efficient session. Perfect for maintaining strength and fitness with a busy schedule. |
| 2 Day | Full Body x2 | Train your whole body twice per week for balanced development. Great for building a foundation or fitting fitness around a packed schedule. |
| 2 Day | Upper Lower | Dedicate one day to upper body, one to lower. Allows more focus on each area while keeping things simple. |
| 3 Day | Push Pull Legs | Organise training by movement pattern: pushing, pulling, and legs. Lets you train harder on each muscle with more recovery time between sessions. |
| 3 Day | Full Body x3 | Hit every muscle group three times per week. Higher frequency means faster skill development and consistent progress. |
| 3 Day | 2 Upper 1 Lower | Two upper body sessions and one lower. Ideal if building your upper body is a priority right now. |
| 3 Day | 1 Upper 2 Lower | One upper body session and two lower. Perfect if you're focusing on building stronger legs and glutes. |
| 4 Day | Upper Lower x2 | Train upper and lower body twice each per week. A proven split that balances volume, intensity, and recovery. |
| 5 Day | PPL Upper Lower | Combines Push/Pull/Legs with an Upper/Lower split. Gives you the best of both approaches with optimal training frequency. |
| 6 Day | PPL x2 | Push/Pull/Legs twice per week for maximum volume. Best suited for experienced lifters ready to commit to serious training. |

---

## 4. Programme Generation
When a user completes the questionnaire, the app generates a personalised workout programme. This section details the rules governing that generation.
**Hierarchy/Definitions**
```
Program
|-Session/Day
|--Exercise
```
A program's structure is determined by the split. e.g. a 3-day program could have a "Push Pull Legs" split or a "Full Body x 3" split.
Each day within that split (or program) represents a session, made up of exercises.


### 4.1 Exercise Candidates
Each exercise in a program is linked to a muscle group.
Each exercise can have several candidates as the program is being generated, since there are many exercises that can train a specific muscle group.

The programme uses a joint scoring system to 1. select exercises and 2. order exercises, as follows:
- Exercise Selection: exercises are selected according to complexity_score of the exercises. The user's experience level determines what complexity level they can be assigned:
- All - everyone
1 - complete beginner only i.e. complexity <= 1 AND All
2- beginner only i.e. complexity <= 2 AND All
3 - intermediate and advanced only i.e. complexity <= 3 AND All
- Exercise Ordering: Exercises are given a canonical_rating score out of 100. On

### 4.1 Split Type Selection

Based on training days per week and session duration, the app selects a workout split. Splits follow the [Split Templates](trAInSwift/resources/split_templates.json) file - this file governs which spl

**Deduplication Rules:**
- Exercise display names do not repeat ANYWHERE within a programme
- Exercise canonical names do not repeat WITHIN a session (but may repeat between sessions)
- If a muscle is in the user's "target muscle groups", it gets +1 exercise, i.e. the json template may show {"Chest": 2} which then gets increased to {"Chest": 3} if the user selected chest as a priority muscle group.

**Selection**

- Start with full exercise database
- Filter by complexity: keep exercises where user level ≥ exercise minimum level
- Filter by equipment: keep exercises where user has the required equipment
- For each slot in the template, build a candidate list from this filtered pool where muscle group matches
- Use MCV: find the slot with the fewest candidates, fill it first
- When selecting from candidates, pick the highest canonical rating
- After each fill, remove that canonical from other slots' candidate lists (within session) and remove that display_name from future sessions
- Repeat until all slots filled or stuck


**Ordering**
- Once a session is filled, sort all exercises by canonical rating descending. Highest first, lowest last. Compounds before isolations.

**Hard constraints (never break)**

- Equipment: user must have it
- Complexity: user level must meet or exceed exercise minimum
- No canonical repeat within a session (no two types of bench press on same day)
- No display_name repeat within a programme (same exact exercise can't appear on Day 1 and Day 3)


**Soft constraints (relax if no valid candidates)**
| Relaxation | Trigger flag |
|------------|--------------|
| Allow display_name repeat across sessions | `repeatWarning = true` |

**User warnings**
After generation, check flag and display appropriate modal:
If `repeatWarning`:

> "Your programme includes some repeated exercises across days due to limited equipment. Would you like to go back and add more equipment, or proceed?"
> [Add equipment] [Proceed anyway]

If slot unfillable (no candidates even after relaxation)
Don't generate. Show blocker modal:

> "We don't have enough exercises for your current equipment and experience level. Please add more equipment to continue."
> [Add equipment]

### 4.5 Sets, Reps, and Rest Assignment

**Rep Ranges (based on goal):**

Selected based on user’s goals. Available rep ranges (assigned randomly)
Get Stronger: 5-8 and 6-10 for exercises >75 canonical_rating. 
Increase Muscle: 6-10 and 8-12 for all exercises. 
Fat Loss: 8-12 and 10-14
Offers variance across exercises and workouts to keep user engaged.
Additional note - allow user to select more than one goal, as a result it offers
bigger variance in rap ranges selected (and reduces potential friction with the
user not being able to select all of their desired goals).

1. If "Get Stronger" is the only goal, then exercises >75 in rating get either 5-8 or 6-10 rep ranges, exercises <= 75 get 6-10 or 8-12. This would also apply if "Get Stronger" and "Increase Muscle" were both selected or all 3.
2. Fat Loss rep ranges are used if Fat Loss is the only goal selected or if "Increaase Muscle" and "Fat Loss" are selected.
3. If "Fat Loss" and "Get Stronger" are selected then default to option 1 rep ranges.

**Number of sets:**
Always 3, for all exercises of all levels.

**Rest Periods:**
Decided based on Canonical Rating. Again, movement pattern typically dictates
the difficulty of an exercise. The higher the rating, the harder the exercise.
Suggested rest periods:
>80 rating → 120 seconds
50-80 rating → 90 seconds
<50 rating → 60 seconds
User can add or remove 15 seconds if they wish, as the timer is active during
the session.

### 3.6 Exercise Display Order
In descending order of canonical rating.


**Note on injuries**: User-reported injuries do NOT filter exercises from the programme. Instead, contraindicated exercises are included but display a warning icon in the Workout Overview UI.

---

---

## 5. App Warnings & Modal Overlays

This section documents all warning modals and confirmation dialogs presented to users throughout the app.

### 5.1 Questionnaire Warnings

#### Limited Equipment Warning (Pre-Generation)
**Trigger Point:** Equipment Step → User clicks "Continue" with ≤2 equipment categories selected
**Title:** "Limited Equipment"
**Message:** "Selecting only one equipment type may limit your exercise variety and program effectiveness. For the best results, we recommend adding at least one more equipment category."
**Actions:**
- **"Add More Equipment"** (Cancel) → Returns to equipment selection step
- **"Continue Anyway"** (Destructive) → Proceeds to next questionnaire step

#### Program Generation Warning (Post-Generation)
**Trigger Point:** Program Ready → User clicks "Start Training Now!" → After program is saved
**Title:** "Program Generation Notice" (dynamic)
**Message:** Dynamic message based on exercise selection warnings (e.g., repeated exercises due to limited equipment)
**Actions:**
- **"Amend Equipment"** → Navigates back to equipment selection step (resets program generation state)
- **"Proceed Anyway"** (Destructive) → Continues to dashboard with current program

### 5.2 Profile & Account Warnings

#### Log Out Confirmation
**Trigger Point:** Profile View → User taps "Log Out" button
**Title:** "Log Out"
**Message:** "Are you sure you want to log out?"
**Actions:**
- **"Log Out"** (Destructive) → Logs user out and returns to login screen
- **"Cancel"** (Cancel) → Dismisses dialog, stays on profile

#### Retake Quiz Confirmation
**Trigger Point:** Profile View → User taps "Retake Quiz" button
**Title:** "Retake Quiz"
**Message:** "Would you like to save your current program? You can switch back to it later in 'Switch Programs'."
**Actions:**
- **"Save & Retake"** → Saves current program as inactive, resets questionnaire data, opens questionnaire flow
- **"Discard & Retake"** (Destructive) → Deletes current program, resets questionnaire data, opens questionnaire flow
- **"Cancel"** (Cancel) → Dismisses dialog, stays on profile

**Program Storage Behavior:**
- When "Save & Retake" is chosen, old programs are **preserved** (stored as inactive)
- When "Discard & Retake" is chosen, current program is **deleted** before creating new one
- Maximum of **2 programs** stored per user
- If user already has 2 programs, the oldest is deleted when creating a 3rd
- Previous programs can be viewed and reactivated via "Switch Programs" in account settings

#### Switch Program Confirmation
**Trigger Point:** Account Settings → Switch Programs → User taps on a previous program
**Title:** "Switch Program"
**Message:** "Switch to '{program name}'? Your current program will be saved and you can switch back later."
**Actions:**
- **"Switch Program"** → Activates the selected program, deactivates current program, dismisses sheet
- **"Cancel"** (Cancel) → Dismisses dialog, stays on program selector

#### Delete Account Confirmation
**Trigger Point:** Account Settings → User taps "Delete Account" button
**Title:** "Delete Account"
**Message:** "This will permanently delete your account, workout history, and all associated data. This action cannot be undone."
**Actions:**
- **"Delete Account"** (Destructive) → Deletes user profile, all programs, workout sessions, and keychain credentials; navigates to splash screen
- **"Cancel"** (Cancel) → Dismisses dialog, stays on settings

### 5.3 Workout Session Warnings

#### Cancel Workout Confirmation
**Trigger Point:** Workout Overview → User taps "Cancel Workout" / back navigation during active workout
**Title:** "Cancel Workout"
**Message:** "Are you sure you want to cancel this workout? Your progress will be lost."
**Actions:**
- **"Discard Workout"** (Destructive) → Cancels workout, ends Live Activity, returns to dashboard
- **"Continue Workout"** (Cancel) → Dismisses dialog, continues workout

#### Remove Exercise Confirmation
**Trigger Point:** Workout Overview → User swipe-deletes an exercise or taps delete
**Title:** "Remove Exercise?"
**Message:** "This will remove {exercise name} from today's workout."
**Actions:**
- **"Remove Permanently"** (Destructive) → Removes exercise from session
- **"Cancel"** (Cancel) → Dismisses dialog, keeps exercise

### 5.4 Session Edit Warnings

#### Discard Changes Confirmation
**Trigger Point:** Session Edit View → User taps back/dismiss with unsaved changes
**Title:** "Discard Changes"
**Message:** "You have unsaved changes. Are you sure you want to discard them?"
**Actions:**
- **"Discard Changes"** (Destructive) → Dismisses without saving
- **"Keep Editing"** (Cancel) → Returns to edit view

### 5.5 Authentication Error Displays

These are inline error messages (not modal dialogs) shown on authentication screens:

| Screen | Error Conditions | Display |
|--------|------------------|---------|
| Login | Invalid credentials, network error | Red text below form: "{error message}" |
| Signup | Invalid email, password too short, email exists | Red text below form: "{error message}" |
| Password Reset Request | Invalid email format, email not found | Red text below form: "{error message}" |
| Password Reset Code | Invalid/expired code | Red text below code field: "{error message}" |
| Password Reset New Password | Passwords don't match, too short | Red text below form: "{error message}" |

---

**Document Version**: 4.3<br>
**Created**: December 5, 2025<br>
**Updated**: January 25, 2026<br>
**Authors**: Luke Vassor & Brody Bastiman<br>
**Applies to**: trAIn iOS (Swift)
