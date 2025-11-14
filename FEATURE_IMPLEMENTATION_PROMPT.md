# Implementation Prompt: Rep Counter & Progression Prompts for iOS

## Overview
Implement two critical UX features from the web app into the iOS SwiftUI workout logger:

1. **Rep Counter Badge** - Shows "+X reps" when user exceeds previous session performance
2. **Progression Prompts** - Shows contextual feedback (Regression/Consistency/Progression) after completing all sets

These features significantly improve user engagement and provide intelligent feedback during workouts.

---

## Feature 1: Rep Counter Badge

### What It Does (Web App Reference)
**File**: `/Users/lukevassor/Documents/trAIn-web/frontend/js/logger.js` (lines 364-409)

The rep counter compares the current session's reps against the previous session's data **on a set-by-set basis** and displays the total excess reps as a green badge with animation.

### Business Logic (from BUSINESS_RULES.md)

```
FOR each exercise:
  excess_reps = 0

  FOR each set (1, 2, 3):
    current_reps = current session's reps for this set
    previous_reps = previous session's reps for this set (from database)

    IF current_reps > previous_reps:
      excess_reps += (current_reps - previous_reps)

  IF excess_reps > 0:
    SHOW green badge with "+{excess_reps} reps"
    ANIMATE with pop effect
  ELSE:
    HIDE badge
```

### Example Calculations

**Example 1: Improvement**
- Previous: Set 1: 10 reps, Set 2: 9 reps, Set 3: 8 reps
- Current: Set 1: 12 reps, Set 2: 10 reps, Set 3: 9 reps
- Calculation: (12-10) + (10-9) + (9-8) = +4 reps
- **Display**: "+4 reps" badge

**Example 2: No Improvement**
- Previous: Set 1: 10, Set 2: 10, Set 3: 10
- Current: Set 1: 10, Set 2: 10, Set 3: 10
- Calculation: 0 + 0 + 0 = 0
- **Display**: Hidden

**Example 3: Mixed Results**
- Previous: Set 1: 10, Set 2: 10, Set 3: 10
- Current: Set 1: 12, Set 2: 9, Set 3: 11
- Calculation: (12-10) + 0 + (11-10) = +3 reps (ignores the decline in Set 2)
- **Display**: "+3 reps" badge

### iOS Implementation Requirements

#### 1. Data Model Changes
**File**: `trAInSwift/Models/WorkoutSession.swift`

Add to `WorkoutSession` struct:
```swift
struct WorkoutSession: Codable, Identifiable {
    // ... existing fields ...

    // NEW: Store previous session data for comparison
    var previousSessionData: [String: [LoggedSet]]? // Key: exerciseName
}
```

#### 2. Fetch Previous Session Data
**New Function in AuthService** (`trAInSwift/Services/AuthService.swift`):

```swift
func getPreviousSessionData(
    programId: String,
    sessionIndex: Int,
    exerciseName: String
) -> [LoggedSet]? {
    // Fetch from Core Data: CDWorkoutSession
    // WHERE programId matches
    //   AND sessionIndex matches
    //   AND completedAt < current date
    // ORDER BY completedAt DESC
    // LIMIT 1
    //
    // Return the logged exercise's sets for the matching exerciseName
}
```

#### 3. UI Component - Rep Counter Badge
**New View Component**:

```swift
struct RepCounterBadge: View {
    let excessReps: Int
    @State private var showAnimation = false

    var body: some View {
        if excessReps > 0 {
            HStack(spacing: 4) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 12))
                Text("+\(excessReps)")
                    .font(.trainCaption)
                    .fontWeight(.bold)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.green)
            .cornerRadius(12)
            .scaleEffect(showAnimation ? 1.1 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: showAnimation)
            .onAppear {
                showAnimation = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showAnimation = false
                }
            }
        }
    }
}
```

#### 4. Integration into WorkoutLoggerView
**File**: `trAInSwift/Views/WorkoutLoggerView.swift`

Add to `ExerciseInfoCard`:
```swift
struct ExerciseInfoCard: View {
    let exercise: ProgramExercise
    let excessReps: Int // NEW parameter

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.exerciseName)
                        .font(.trainTitle)
                        .foregroundColor(.trainTextPrimary)

                    Text(exercise.repRange)
                        .font(.trainBody)
                        .foregroundColor(.trainTextSecondary)
                }

                Spacer()

                // NEW: Rep Counter Badge
                RepCounterBadge(excessReps: excessReps)
            }

            // ... rest of card ...
        }
    }
}
```

#### 5. Calculation Logic
**Add to WorkoutLoggerView**:

```swift
// Calculate excess reps for current exercise
func calculateExcessReps() -> Int {
    guard let session = session,
          currentExerciseIndex < session.exercises.count,
          currentExerciseIndex < loggedExercises.count else {
        return 0
    }

    let currentExercise = loggedExercises[currentExerciseIndex]
    let exerciseName = currentExercise.exerciseName

    // Fetch previous session data
    guard let previousSets = authService.getPreviousSessionData(
        programId: userProgram?.id ?? "",
        sessionIndex: sessionIndex,
        exerciseName: exerciseName
    ) else {
        return 0
    }

    var excessReps = 0

    // Compare set by set
    for (index, currentSet) in currentExercise.sets.enumerated() {
        guard index < previousSets.count else { break }

        let currentReps = currentSet.reps
        let previousReps = previousSets[index].reps

        if currentReps > previousReps {
            excessReps += (currentReps - previousReps)
        }
    }

    return excessReps
}
```

#### 6. Update in Real-Time
Use `.onChange` modifier on `loggedExercises`:

```swift
.onChange(of: loggedExercises[currentExerciseIndex].sets) { _, _ in
    // Recalculate excess reps (with debounce to avoid excessive recalculations)
}
```

---

## Feature 2: Progression Prompts (Regression/Consistency/Progression)

### What It Does (Web App Reference)
**File**: `/Users/lukevassor/Documents/trAIn-web/frontend/js/logger.js` (lines 470-521)

After completing all 3 sets of an exercise, the app analyzes performance and shows one of three prompts:
- 🔴 **Regression** - First 2 sets below target range (reduce weight)
- 🟡 **Consistency** - Good performance, maintain current weight
- 🟢 **Progression** - First 2 sets at/above max, ready to increase weight

### Business Logic (from BUSINESS_RULES.md)

```
WHEN all 3 sets completed:
  GET Set 1 reps, Set 2 reps, Set 3 reps
  GET target rep range (repsMin, repsMax)

  // 🔴 REGRESSION (Highest Priority)
  IF Set 1 < repsMin OR Set 2 < repsMin:
    SHOW regression prompt
    MESSAGE: "Great effort! Try a lighter weight next time"
    STOP

  // 🟢 PROGRESSION (Medium Priority)
  IF Set 1 >= repsMax AND Set 2 >= repsMax AND Set 3 >= repsMin:
    SHOW progression prompt
    MESSAGE: "Excellent! Time to increase weight"
    STOP

  // 🟡 CONSISTENCY (Special Case)
  IF Set 1 >= repsMax AND Set 2 >= repsMax AND Set 3 < repsMin:
    SHOW consistency prompt (strong start, weak finish)
    MESSAGE: "Great start! Push harder on the last set"
    STOP

  // 🟡 CONSISTENCY (Default)
  ELSE:
    SHOW consistency prompt
    MESSAGE: "You're doing great! Keep it up"
```

### Key Rules
1. **Prompts only show when ALL 3 sets completed** (reps > 0)
2. **Focus on first 2 sets** - Set 3 is expected to be harder due to fatigue
3. **Regression always wins** - Safety first
4. **500ms debounce** - Wait for user to finish typing before evaluating

### iOS Implementation Requirements

#### 1. Prompt Type Enum
**Add to WorkoutLoggerView**:

```swift
enum PromptType {
    case regression
    case consistency
    case progression

    var color: Color {
        switch self {
        case .regression: return .red
        case .consistency: return .orange
        case .progression: return .green
        }
    }

    var icon: String {
        switch self {
        case .regression: return "💪"
        case .consistency: return "🎯"
        case .progression: return "🎉"
        }
    }

    var title: String {
        switch self {
        case .regression: return "Great effort today!"
        case .consistency: return "You're doing great!"
        case .progression: return "Excellent work!"
        }
    }

    var subtitle: String {
        switch self {
        case .regression: return "Try choosing a weight that allows you to hit the target range for all sets"
        case .consistency: return "Try to hit the top end of the range or exceed it for all sets"
        case .progression: return "You hit or exceeded the top end for your first two sets! Time to increase weight next session"
        }
    }
}
```

#### 2. Evaluation Logic
**Add to WorkoutLoggerView**:

```swift
func evaluatePrompt(
    for exercise: LoggedExercise,
    targetMin: Int,
    targetMax: Int
) -> PromptType? {
    // Only show prompt when all 3 sets completed
    let completedSets = exercise.sets.filter { $0.reps > 0 }
    guard completedSets.count == 3 else {
        return nil
    }

    let set1Reps = completedSets[0].reps
    let set2Reps = completedSets[1].reps
    let set3Reps = completedSets[2].reps

    // 🔴 REGRESSION: First 2 sets below minimum
    if set1Reps < targetMin || set2Reps < targetMin {
        return .regression
    }

    // 🟢 PROGRESSION: First 2 at/above max, 3rd in range
    if set1Reps >= targetMax && set2Reps >= targetMax && set3Reps >= targetMin {
        return .progression
    }

    // 🟡 CONSISTENCY: Strong start, weak finish
    if set1Reps >= targetMax && set2Reps >= targetMax && set3Reps < targetMin {
        return .consistency
    }

    // 🟡 CONSISTENCY: Default
    return .consistency
}
```

#### 3. UI Component - Prompt Card
**New View Component**:

```swift
struct ProgressionPromptCard: View {
    let promptType: PromptType
    @State private var showAnimation = false

    var body: some View {
        HStack(spacing: Spacing.md) {
            Text(promptType.icon)
                .font(.system(size: 32))

            VStack(alignment: .leading, spacing: 4) {
                Text(promptType.title)
                    .font(.trainBodyMedium)
                    .fontWeight(.bold)
                    .foregroundColor(.trainTextPrimary)

                Text(promptType.subtitle)
                    .font(.trainCaption)
                    .foregroundColor(.trainTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(Spacing.md)
        .background(promptType.color.opacity(0.1))
        .cornerRadius(CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(promptType.color, lineWidth: 2)
        )
        .scaleEffect(showAnimation ? 1.0 : 0.95)
        .opacity(showAnimation ? 1.0 : 0.0)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showAnimation)
        .onAppear {
            showAnimation = true
        }
    }
}
```

#### 4. Integration into SetLoggingView
**File**: `trAInSwift/Views/WorkoutLoggerView.swift`

Add state variable:
```swift
@State private var currentPrompt: PromptType? = nil
@State private var debounceTimer: Timer? = nil
```

Add to `SetLoggingView` body (after set rows):
```swift
// Progression prompt (after all sets)
if let prompt = currentPrompt {
    ProgressionPromptCard(promptType: prompt)
        .padding(.top, Spacing.md)
}
```

Add evaluation logic with debounce:
```swift
.onChange(of: loggedExercise.sets) { _, _ in
    // Cancel existing timer
    debounceTimer?.invalidate()

    // Create new debounced evaluation (500ms)
    debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
        evaluateAndShowPrompt()
    }
}

private func evaluateAndShowPrompt() {
    // Parse rep range to get min/max
    let repRange = programExercise.repRange // e.g., "8-12"
    let components = repRange.split(separator: "-")
    guard components.count == 2,
          let targetMin = Int(components[0]),
          let targetMax = Int(components[1]) else {
        return
    }

    // Evaluate
    currentPrompt = evaluatePrompt(
        for: loggedExercise,
        targetMin: targetMin,
        targetMax: targetMax
    )
}
```

---

## Implementation Checklist

### Phase 1: Rep Counter (2-3 hours)
- [ ] Add `previousSessionData` field to `WorkoutSession` model
- [ ] Implement `getPreviousSessionData()` in AuthService
- [ ] Create `RepCounterBadge` SwiftUI component
- [ ] Add `calculateExcessReps()` function to WorkoutLoggerView
- [ ] Integrate badge into `ExerciseInfoCard`
- [ ] Add `.onChange` to update counter in real-time
- [ ] Test with mock previous session data
- [ ] Test with no previous session (should hide badge)

### Phase 2: Progression Prompts (2-3 hours)
- [ ] Create `PromptType` enum with colors, icons, messages
- [ ] Implement `evaluatePrompt()` logic with all 4 cases
- [ ] Create `ProgressionPromptCard` SwiftUI component
- [ ] Add state variables (`currentPrompt`, `debounceTimer`)
- [ ] Integrate prompt card into `SetLoggingView`
- [ ] Add `.onChange` with 500ms debounce
- [ ] Test regression case (set 1 or 2 below min)
- [ ] Test progression case (sets 1-2 at max, set 3 in range)
- [ ] Test consistency cases (both variants)
- [ ] Verify prompts only show when all 3 sets completed

### Phase 3: Integration & Testing (1-2 hours)
- [ ] Test both features together
- [ ] Test on simulator with various rep scenarios
- [ ] Test animation smoothness (60fps)
- [ ] Test with rapid input (debounce working)
- [ ] Test edge cases:
  - [ ] First workout (no previous data)
  - [ ] Incomplete sets (should hide prompt)
  - [ ] Zero reps entered
  - [ ] Switching between exercises
- [ ] Code cleanup (remove debug logs)
- [ ] Add AppLogger statements for debugging

---

## Technical Notes

### Core Data Query for Previous Session
```swift
let fetchRequest: NSFetchRequest<CDWorkoutSession> = CDWorkoutSession.fetchRequest()
fetchRequest.predicate = NSPredicate(
    format: "programId == %@ AND sessionIndex == %d AND completedAt < %@",
    programId, sessionIndex, Date() as CVarArg
)
fetchRequest.sortDescriptors = [NSSortDescriptor(key: "completedAt", ascending: false)]
fetchRequest.fetchLimit = 1

do {
    let results = try viewContext.fetch(fetchRequest)
    if let previousSession = results.first,
       let loggedExercises = previousSession.loggedExercises {
        // Find matching exercise by name
        // Return its sets
    }
} catch {
    AppLogger.logApp("Failed to fetch previous session: \(error)", level: .error)
}
```

### Performance Considerations
- **Debouncing**: Use 500ms timer to avoid excessive recalculations during typing
- **Caching**: Store previous session data in memory to avoid repeated Core Data queries
- **Animation**: Use `.animation()` modifier sparingly - only on scale/opacity changes
- **Core Data**: Use `fetchLimit: 1` to avoid loading unnecessary data

### Accessibility
- Add `.accessibilityLabel()` to badges and prompts
- Ensure color is not the only indicator (use icons too)
- Test with VoiceOver enabled

---

## Expected User Experience

### Rep Counter
1. User starts logging exercise
2. As they enter reps for each set, badge appears/updates if beating previous session
3. Badge animates with subtle "pop" effect when count increases
4. Badge shows cumulative excess reps across all sets
5. If no improvement, badge stays hidden (not demotivating)

### Progression Prompts
1. User completes all 3 sets (enters reps for each)
2. After 500ms pause, prompt card fades in with animation
3. Prompt color and message match performance (red/orange/green)
4. User can immediately see if they should increase/maintain/decrease weight
5. Moving to next exercise clears the prompt

### Combined Effect
- **Motivating**: Green badge shows improvement, green prompt confirms progression
- **Instructive**: Red prompt guides user to reduce weight if struggling
- **Engaging**: Immediate visual feedback makes logging feel interactive
- **Data-driven**: Decisions based on actual performance vs previous session

---

## Code Quality Standards

### Before Submitting PR:
1. ✅ No force unwraps in new code (use guard/if let)
2. ✅ All functions have doc comments explaining purpose
3. ✅ Use AppLogger for any debug/error logging
4. ✅ Follow existing code style (spacing, naming conventions)
5. ✅ Test on iOS 17+ (minimum supported version)
6. ✅ Verify no memory leaks (use Instruments if needed)
7. ✅ Ensure animations run at 60fps
8. ✅ Add unit tests for `evaluatePrompt()` logic

---

## Priority for MVP

**BOTH features are HIGH PRIORITY for MVP launch.**

Why?
- **Rep Counter**: Core engagement feature - users want to see progress
- **Progression Prompts**: Critical UX - guides users on when to increase/decrease weight
- **Competitive Advantage**: Web app has these, iOS must match or exceed
- **User Retention**: These features make users want to come back and beat their previous performance

**Estimated Total Effort**: 5-7 hours for complete implementation + testing

---

## Testing Scenarios

### Rep Counter Test Cases
```swift
// Test 1: First workout (no previous data)
previous: nil
current: [10, 10, 10]
expected: badge hidden

// Test 2: All sets improved
previous: [8, 8, 8]
current: [10, 10, 10]
expected: "+6 reps"

// Test 3: Mixed performance
previous: [10, 10, 10]
current: [12, 9, 11]
expected: "+3 reps" (only counts improvements)

// Test 4: No improvement
previous: [10, 10, 10]
current: [10, 10, 10]
expected: badge hidden

// Test 5: Worse performance
previous: [12, 12, 12]
current: [10, 10, 10]
expected: badge hidden (no negative numbers)
```

### Progression Prompt Test Cases
```swift
// Test 1: Regression (set 1 below min)
target: 8-12 reps
sets: [7, 10, 10]
expected: regression prompt (🔴)

// Test 2: Regression (set 2 below min)
target: 8-12 reps
sets: [10, 6, 10]
expected: regression prompt (🔴)

// Test 3: Progression
target: 8-12 reps
sets: [12, 12, 10]
expected: progression prompt (🟢)

// Test 4: Consistency (strong start, weak finish)
target: 8-12 reps
sets: [12, 12, 7]
expected: consistency prompt (🟡)

// Test 5: Consistency (all in range)
target: 8-12 reps
sets: [10, 9, 8]
expected: consistency prompt (🟡)

// Test 6: Incomplete sets
target: 8-12 reps
sets: [10, 0, 0]
expected: no prompt (nil)
```

---

## Files to Modify/Create

### Existing Files to Modify
1. `trAInSwift/Models/WorkoutSession.swift` - Add previousSessionData field
2. `trAInSwift/Services/AuthService.swift` - Add getPreviousSessionData()
3. `trAInSwift/Views/WorkoutLoggerView.swift` - Integrate both features

### New Files to Create
1. `trAInSwift/Components/RepCounterBadge.swift` - Standalone badge component
2. `trAInSwift/Components/ProgressionPromptCard.swift` - Standalone prompt component

Or add as nested structs in WorkoutLoggerView if you prefer single-file organization.

---

## Success Criteria

### Feature is complete when:
- [x] Rep counter appears when user beats previous session
- [x] Rep counter shows correct calculation (set-by-set comparison)
- [x] Rep counter animates smoothly on appearance/update
- [x] Rep counter hides when no improvement
- [x] Progression prompt appears only after all 3 sets completed
- [x] Prompt shows correct type based on performance (regression/consistency/progression)
- [x] Prompt animates smoothly with proper timing
- [x] Debounce prevents excessive recalculation (500ms)
- [x] Works on first workout (no previous session)
- [x] Works offline (no network required)
- [x] No crashes or force unwraps
- [x] Passes all test scenarios above

---

**Ready to implement? Start with Phase 1 (Rep Counter) as it's simpler and builds the foundation for fetching previous session data needed by both features.**
