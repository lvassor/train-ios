# Implementation Plan: UI/UX Fixes and Improvements

## Overview
Six issues to address across the app, spanning safe area handling, questionnaire flow, and UI styling.

---

## Issue 1: WorkoutOverviewView & ExerciseLoggerView Safe Area Issues

**Problem:** Back button and Edit/Done buttons are behind the Apple battery icon; "Complete Workout" button shifted too far down.

**Root Cause:**
- `WorkoutOverviewView` uses `.charcoalGradientBackground()` with a floating button in a `VStack { Spacer() ... }` pattern
- This doesn't properly account for safe areas at top or bottom
- `ExerciseLoggerView` was recently updated to use the correct pattern with `safeAreaInset`

**Files to Modify:**
- `trAInSwift/Views/WorkoutOverviewView.swift`

**Changes:**
1. Remove `.charcoalGradientBackground()` modifier
2. Add explicit `AppGradient.background.ignoresSafeArea()` as first layer in ZStack
3. Replace floating button `VStack { Spacer() ... }` with `.safeAreaInset(edge: .bottom)` on the main VStack
4. Add top safe area padding to `WorkoutOverviewHeader` (currently only has `.padding(.vertical, 16)`)

---

## Issue 2: Priority Muscle Group - Remove Gender Toggle

**Problem:** Gender toggle toolbar is redundant since we already capture gender in the Health Profile step.

**Files to Modify:**
- `trAInSwift/Components/MuscleSelector/MuscleSelector.swift`
- `trAInSwift/Views/QuestionnaireSteps.swift`

**Changes:**
1. Add `gender` parameter to `CompactMuscleSelector` initializer (default to `.male`)
2. Remove the HStack gender toggle UI (lines 227-244 in MuscleSelector.swift)
3. Increase body diagram height by ~44pt (the height we're reclaiming from removed toggle) - change `.frame(height: 400)` to `.frame(height: 444)` or similar
4. In `MuscleGroupsStepView`, pass the user's gender from `WorkoutViewModel.shared.questionnaireData.gender`
5. Convert gender string to `MuscleSelector.BodyGender` enum

---

## Issue 3: Referral Cards - Grid Tile Styling

**Problem:** Long horizontal cards look awful; should be square tiles like exercise cards.

**Files to Modify:**
- `trAInSwift/Views/Steps/ReferralStepView.swift`

**Changes:**
1. Change grid to 3 columns (8 items fits 3x3 grid with one empty or 4x2 if 2 cols)
2. Make tiles square with equal aspect ratio
3. Update styling to match exercise card palette:
   - Use `.ultraThinMaterial` background (matching `warmGlassCard`)
   - Use `strokeBorder` with `trainTextSecondary.opacity(0.3)`
   - Remove shadow on icon circle
   - Use consistent 16pt corner radius
4. Reduce icon circle size and adjust padding for square tiles
5. Selected state: orange background fill + brighter border

---

## Issue 4: "Proceed Anyway" Equipment Modal Bug

**Problem:** After clicking "Proceed Anyway" on limited equipment warning, the flow gets stuck at the referral question and "Start Training" does nothing.

**Root Cause Investigation:**
- `proceedFromEquipmentStep()` at line 510-517 sets `hasSeenEquipmentWarning = true` and calls `proceedToNextStep()`
- The flow goes: Equipment (step 10/9) -> Interstitial2 -> Muscles -> Injuries -> Program Loading
- But the referral step appears in `PostSignupFlowView`, which is post-program-ready
- The bug is likely in state management between `QuestionnaireView` and `ProgramReadyView`

**Files to Investigate Further:**
- `trAInSwift/Views/QuestionnaireView.swift`
- `trAInSwift/Views/ProgramReadyView.swift`
- `trAInSwift/Views/Onboarding/PostSignupFlowView.swift`

**Likely Fix:**
- Check if `isSignupInProgress` flag is incorrectly blocking navigation
- Check if `showPostSignupFlow` state is not being triggered correctly
- Check if `onStart()` callback chain is broken somewhere

---

## Issue 5: Questionnaire Retake - Skip Login for Already Authenticated Users

**Problem:** When user retakes questionnaire from Profile, they're already logged in but still see login flow, causing friction.

**Files to Modify:**
- `trAInSwift/Views/OnboardingFlowView.swift`
- `trAInSwift/Views/ProgramReadyView.swift` (maybe)

**Current Flow:**
1. ProfileView shows "Retake Quiz" button
2. User confirms via dialog
3. `fullScreenCover` presents `OnboardingFlowView`
4. OnboardingFlowView shows WelcomeView (with login option)
5. User goes through questionnaire
6. At ProgramReadyView, user must sign up again (but they're already authenticated!)

**Changes:**
1. Add parameter to `OnboardingFlowView`: `isRetake: Bool = false`
2. When `isRetake = true`, skip `WelcomeView` and go directly to `QuestionnaireView`
3. In `ProgramReadyView`, check `AuthService.shared.isAuthenticated`:
   - If already authenticated, skip `PostQuestionnaireSignupView`
   - Go directly to `PostSignupFlowView` (notifications + referral) or skip that too
4. Update ProfileView to pass `isRetake: true` when presenting OnboardingFlowView

---

## Issue 6: (Related cleanup) Ensure Consistent Safe Area Handling

**Files to Check:**
- All views using `.charcoalGradientBackground()` should be checked for proper safe area handling
- Views with floating bottom buttons should use `.safeAreaInset(edge: .bottom)`

---

## Implementation Order

1. **Issue 1** - Fix safe areas (most visible user-facing bug)
2. **Issue 4** - Fix "Proceed Anyway" bug (blocks user flow)
3. **Issue 5** - Skip login on retake (UX friction)
4. **Issue 2** - Remove gender toggle (simple change)
5. **Issue 3** - Referral card styling (visual improvement)

---

## Permissions Needed

- Bash: run build commands to verify compilation
