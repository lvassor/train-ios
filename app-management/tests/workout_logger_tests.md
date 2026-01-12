# Workout Logger and Progression System Tests

## Overview
This document contains comprehensive tests for the workout logger, progression/regression prompts, rep counter system, and all gamification features that make the trAIn app engaging for users.

## Test Categories

1. [Progression/Regression Prompt Tests](#1-progressionregression-prompt-tests)
2. [Rep Counter Tests](#2-rep-counter-tests)
3. [Workout Logger UI Tests](#3-workout-logger-ui-tests)
4. [Timer Integration Tests](#4-timer-integration-tests)
5. [Exercise Demo Integration Tests](#5-exercise-demo-integration-tests)
6. [Data Persistence Tests](#6-data-persistence-tests)

---

## 1. Progression/Regression Prompt Tests

### 1.1 Traffic Light System Logic Tests
**Purpose**: Test the core logic of progression/regression prompts

```swift
// Test regression takes priority (RED LIGHT)
func testRegressionPromptPriority() {
    let sets = [
        WorkoutSet(reps: 4, weight: 20.0, completed: true), // Below min (5)
        WorkoutSet(reps: 8, weight: 20.0, completed: true), // In range
        WorkoutSet(reps: 10, weight: 20.0, completed: true) // Above max
    ]
    let targetRange = RepRange(min: 5, max: 8)

    let prompt = ProgressionPromptCalculator.calculatePrompt(
        sets: sets,
        targetRange: targetRange
    )

    XCTAssertEqual(prompt.type, .regression)
    XCTAssertEqual(prompt.message, "⚠️ Form check needed - reduce weight")
    XCTAssertEqual(prompt.explanation, "Your first 2 sets fell below the target range")
}

// Test progression prompt (GREEN LIGHT)
func testProgressionPrompt() {
    let sets = [
        WorkoutSet(reps: 9, weight: 20.0, completed: true), // Above max (8)
        WorkoutSet(reps: 8, weight: 20.0, completed: true), // At max
        WorkoutSet(reps: 6, weight: 20.0, completed: true)  // In range
    ]
    let targetRange = RepRange(min: 5, max: 8)

    let prompt = ProgressionPromptCalculator.calculatePrompt(
        sets: sets,
        targetRange: targetRange
    )

    XCTAssertEqual(prompt.type, .progression)
    XCTAssertEqual(prompt.message, "💪 Ready to progress - increase weight next session")
    XCTAssertEqual(prompt.explanation, "First 2 sets at/above max, 3rd set in range")
}

// Test special consistency case (AMBER LIGHT)
func testSpecialConsistencyPrompt() {
    let sets = [
        WorkoutSet(reps: 9, weight: 20.0, completed: true), // Above max
        WorkoutSet(reps: 8, weight: 20.0, completed: true), // At max
        WorkoutSet(reps: 3, weight: 20.0, completed: true)  // Below min
    ]
    let targetRange = RepRange(min: 5, max: 8)

    let prompt = ProgressionPromptCalculator.calculatePrompt(
        sets: sets,
        targetRange: targetRange
    )

    XCTAssertEqual(prompt.type, .consistency)
    XCTAssertEqual(prompt.message, "🎯 Great consistency - maintain and push on 3rd set")
    XCTAssertEqual(prompt.explanation, "Strong start but 3rd set fell short")
}

// Test default consistency case
func testDefaultConsistencyPrompt() {
    let sets = [
        WorkoutSet(reps: 6, weight: 20.0, completed: true), // In range
        WorkoutSet(reps: 7, weight: 20.0, completed: true), // In range
        WorkoutSet(reps: 5, weight: 20.0, completed: true)  // In range
    ]
    let targetRange = RepRange(min: 5, max: 8)

    let prompt = ProgressionPromptCalculator.calculatePrompt(
        sets: sets,
        targetRange: targetRange
    )

    XCTAssertEqual(prompt.type, .consistency)
    XCTAssertEqual(prompt.message, "🎯 Great work - maintain this weight")
    XCTAssertEqual(prompt.explanation, "Everything within target range or mixed results")
}
```

### 1.2 Prompt Display Timing Tests
**Purpose**: Test prompt only shows when all 3 sets completed

```swift
// Test prompt doesn't show until all sets completed
func testPromptOnlyShowsWhenAllSetsCompleted() {
    let exercise = createMockExercise()
    let workoutLogger = WorkoutLoggerView(exercise: exercise)

    // Complete only 2 sets
    workoutLogger.completeSets([
        WorkoutSet(reps: 8, weight: 20.0, completed: true),
        WorkoutSet(reps: 8, weight: 20.0, completed: true),
        WorkoutSet(reps: 0, weight: 20.0, completed: false)
    ])

    XCTAssertFalse(workoutLogger.showsProgressionPrompt)

    // Complete all 3 sets
    workoutLogger.completeSets([
        WorkoutSet(reps: 8, weight: 20.0, completed: true),
        WorkoutSet(reps: 8, weight: 20.0, completed: true),
        WorkoutSet(reps: 6, weight: 20.0, completed: true)
    ])

    XCTAssertTrue(workoutLogger.showsProgressionPrompt)
}

// Test 500ms debounce delay
func testPromptDebounceDelay() {
    let exercise = createMockExercise()
    let workoutLogger = WorkoutLoggerView(exercise: exercise)

    // Complete all sets
    workoutLogger.completeSets([
        WorkoutSet(reps: 8, weight: 20.0, completed: true),
        WorkoutSet(reps: 8, weight: 20.0, completed: true),
        WorkoutSet(reps: 6, weight: 20.0, completed: true)
    ])

    // Should not show immediately
    XCTAssertFalse(workoutLogger.showsProgressionPrompt)

    // Wait for debounce delay
    let expectation = XCTestExpectation(description: "Debounce delay")
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
        XCTAssertTrue(workoutLogger.showsProgressionPrompt)
        expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
}
```

---

## 2. Rep Counter Tests

### 2.1 Rep Counter Logic Tests
**Purpose**: Test excess rep calculation and display

```swift
// Test rep counter calculates excess reps correctly
func testRepCounterCalculation() {
    let previousSets = [
        WorkoutSet(reps: 8, weight: 20.0, completed: true),
        WorkoutSet(reps: 7, weight: 20.0, completed: true),
        WorkoutSet(reps: 6, weight: 20.0, completed: true)
    ]

    let currentSets = [
        WorkoutSet(reps: 10, weight: 20.0, completed: true), // +2 from set 1
        WorkoutSet(reps: 8, weight: 20.0, completed: true),  // +1 from set 2
        WorkoutSet(reps: 6, weight: 20.0, completed: true)   // +0 from set 3
    ]

    let excessReps = RepCounterCalculator.calculateExcessReps(
        currentSets: currentSets,
        previousSets: previousSets
    )

    XCTAssertEqual(excessReps, 3) // 2 + 1 + 0 = 3
}

// Test rep counter only shows positive improvements
func testRepCounterOnlyShowsImprovements() {
    let previousSets = [
        WorkoutSet(reps: 10, weight: 20.0, completed: true),
        WorkoutSet(reps: 8, weight: 20.0, completed: true),
        WorkoutSet(reps: 6, weight: 20.0, completed: true)
    ]

    let currentSets = [
        WorkoutSet(reps: 8, weight: 20.0, completed: true),  // -2 from set 1
        WorkoutSet(reps: 6, weight: 20.0, completed: true),  // -2 from set 2
        WorkoutSet(reps: 8, weight: 20.0, completed: true)   // +2 from set 3
    ]

    let excessReps = RepCounterCalculator.calculateExcessReps(
        currentSets: currentSets,
        previousSets: previousSets
    )

    XCTAssertEqual(excessReps, 2) // Only counts the +2 from set 3
}

// Test rep counter with no previous session
func testRepCounterWithNoPreviousSession() {
    let currentSets = [
        WorkoutSet(reps: 8, weight: 20.0, completed: true),
        WorkoutSet(reps: 7, weight: 20.0, completed: true),
        WorkoutSet(reps: 6, weight: 20.0, completed: true)
    ]

    let excessReps = RepCounterCalculator.calculateExcessReps(
        currentSets: currentSets,
        previousSets: []
    )

    XCTAssertEqual(excessReps, 0) // No comparison available
}
```

### 2.2 Rep Counter UI Tests
**Purpose**: Test rep counter display and animation

```swift
// Test rep counter badge display
func testRepCounterBadgeDisplay() {
    let workoutLogger = WorkoutLoggerView(exercise: createMockExercise())

    // Set up scenario with excess reps
    workoutLogger.setExcessReps(5)

    XCTAssertTrue(workoutLogger.showsRepCounterBadge)
    XCTAssertEqual(workoutLogger.repCounterText, "+5 reps")
    XCTAssertEqual(workoutLogger.repCounterBadgeColor, .green)
}

// Test rep counter hides when no excess reps
func testRepCounterHidesWhenNoExcess() {
    let workoutLogger = WorkoutLoggerView(exercise: createMockExercise())

    workoutLogger.setExcessReps(0)

    XCTAssertFalse(workoutLogger.showsRepCounterBadge)
}

// Test rep counter animation
func testRepCounterAnimation() {
    let workoutLogger = WorkoutLoggerView(exercise: createMockExercise())

    // Initially no excess reps
    workoutLogger.setExcessReps(0)
    XCTAssertFalse(workoutLogger.repCounterBadgeIsAnimating)

    // Add excess reps - should trigger animation
    workoutLogger.setExcessReps(3)
    XCTAssertTrue(workoutLogger.repCounterBadgeIsAnimating)

    // Animation should complete after 300ms
    let expectation = XCTestExpectation(description: "Animation completion")
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
        XCTAssertFalse(workoutLogger.repCounterBadgeIsAnimating)
        expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
}
```

### 2.3 Real-time Update Tests
**Purpose**: Test rep counter updates in real-time with debounce

```swift
// Test rep counter updates in real-time
func testRepCounterRealTimeUpdates() {
    let workoutLogger = WorkoutLoggerView(exercise: createMockExercise())

    // Set previous session data
    workoutLogger.setPreviousSession([
        WorkoutSet(reps: 8, weight: 20.0, completed: true),
        WorkoutSet(reps: 7, weight: 20.0, completed: true),
        WorkoutSet(reps: 6, weight: 20.0, completed: true)
    ])

    // Update current sets gradually
    workoutLogger.updateCurrentSet(setIndex: 0, reps: 10) // +2
    XCTAssertEqual(workoutLogger.currentExcessReps, 2)

    workoutLogger.updateCurrentSet(setIndex: 1, reps: 9) // +2 total
    XCTAssertEqual(workoutLogger.currentExcessReps, 4)

    workoutLogger.updateCurrentSet(setIndex: 2, reps: 8) // +2 total
    XCTAssertEqual(workoutLogger.currentExcessReps, 6)
}

// Test 500ms debounce for real-time updates
func testRepCounterDebounce() {
    let workoutLogger = WorkoutLoggerView(exercise: createMockExercise())

    // Rapidly update reps
    workoutLogger.updateCurrentSet(setIndex: 0, reps: 10)
    workoutLogger.updateCurrentSet(setIndex: 0, reps: 11)
    workoutLogger.updateCurrentSet(setIndex: 0, reps: 12)

    // Should only process final value after debounce
    let expectation = XCTestExpectation(description: "Debounce completion")
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
        // Should reflect final value (12), not intermediate values
        XCTAssertEqual(workoutLogger.displayedReps, 12)
        expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
}
```

---

## 3. Workout Logger UI Tests

### 3.1 Exercise Display Tests
**Purpose**: Test exercise information display

```swift
// Test exercise display shows all required information
func testExerciseDisplayInformation() {
    let exercise = createMockExercise(
        displayName: "Barbell Bench Press",
        primaryMuscle: "Chest",
        repRangeMin: 6,
        repRangeMax: 10,
        sets: 3,
        restSeconds: 90
    )

    let workoutLogger = WorkoutLoggerView(exercise: exercise)

    XCTAssertEqual(workoutLogger.exerciseName, "Barbell Bench Press")
    XCTAssertEqual(workoutLogger.primaryMuscle, "Chest")
    XCTAssertEqual(workoutLogger.targetRepRange, "6-10")
    XCTAssertEqual(workoutLogger.numberOfSets, 3)
    XCTAssertEqual(workoutLogger.restDuration, 90)
}

// Test exercise ordering in session view
func testExerciseOrderingInSession() {
    let session = createMockSession(exercises: [
        createMockExercise(canonicalRating: 70),
        createMockExercise(canonicalRating: 90),
        createMockExercise(canonicalRating: 80)
    ])

    let sessionView = WorkoutSessionView(session: session)

    let displayedExercises = sessionView.orderedExercises

    // Should be ordered by canonical rating descending
    XCTAssertEqual(displayedExercises[0].canonicalRating, 90)
    XCTAssertEqual(displayedExercises[1].canonicalRating, 80)
    XCTAssertEqual(displayedExercises[2].canonicalRating, 70)
}
```

### 3.2 Set Input Interface Tests
**Purpose**: Test set/rep/weight input interface

```swift
// Test set completion interface
func testSetCompletionInterface() {
    let workoutLogger = WorkoutLoggerView(exercise: createMockExercise())

    // Complete first set
    workoutLogger.completeSet(
        setIndex: 0,
        reps: 10,
        weight: 20.0
    )

    XCTAssertTrue(workoutLogger.isSetCompleted(0))
    XCTAssertEqual(workoutLogger.getSetReps(0), 10)
    XCTAssertEqual(workoutLogger.getSetWeight(0), 20.0)

    // Should enable timer for this set
    XCTAssertTrue(workoutLogger.canStartTimer(for: 0))
}

// Test input validation
func testSetInputValidation() {
    let workoutLogger = WorkoutLoggerView(exercise: createMockExercise())

    // Test invalid rep input
    XCTAssertFalse(workoutLogger.isValidReps(-1))
    XCTAssertFalse(workoutLogger.isValidReps(0))
    XCTAssertTrue(workoutLogger.isValidReps(1))
    XCTAssertTrue(workoutLogger.isValidReps(50))

    // Test invalid weight input
    XCTAssertFalse(workoutLogger.isValidWeight(-5.0))
    XCTAssertTrue(workoutLogger.isValidWeight(0.0))
    XCTAssertTrue(workoutLogger.isValidWeight(100.0))
}

// Test hub-style navigation (non-linear)
func testHubStyleNavigation() {
    let session = createMockSession()
    let sessionView = WorkoutSessionView(session: session)

    // Should be able to jump to any exercise
    XCTAssertTrue(sessionView.canNavigateToExercise(0))
    XCTAssertTrue(sessionView.canNavigateToExercise(2))

    // Should maintain progress when switching
    sessionView.completeSetForExercise(0, setIndex: 0, reps: 10, weight: 20.0)
    sessionView.navigateToExercise(2)
    sessionView.navigateToExercise(0)

    XCTAssertTrue(sessionView.isSetCompletedForExercise(0, setIndex: 0))
}
```

---

## 4. Timer Integration Tests

### 4.1 Rest Timer Tests
**Purpose**: Test rest timer functionality

```swift
// Test timer starts after set completion
func testTimerStartsAfterSetCompletion() {
    let workoutLogger = WorkoutLoggerView(exercise: createMockExercise(restSeconds: 90))

    // Complete a set
    workoutLogger.completeSet(setIndex: 0, reps: 10, weight: 20.0)

    // Timer should be available to start
    XCTAssertTrue(workoutLogger.canStartTimer(for: 0))

    workoutLogger.startTimer(for: 0)

    XCTAssertTrue(workoutLogger.isTimerRunning)
    XCTAssertEqual(workoutLogger.timerDuration, 90)
}

// Test timer customization (+/- 15 seconds)
func testTimerCustomization() {
    let workoutLogger = WorkoutLoggerView(exercise: createMockExercise(restSeconds: 90))

    workoutLogger.completeSet(setIndex: 0, reps: 10, weight: 20.0)

    // Add 15 seconds
    workoutLogger.adjustTimer(by: 15)
    XCTAssertEqual(workoutLogger.adjustedTimerDuration, 105)

    // Subtract 15 seconds
    workoutLogger.adjustTimer(by: -15)
    XCTAssertEqual(workoutLogger.adjustedTimerDuration, 75)
}

// Test timer completion notification
func testTimerCompletionNotification() {
    let workoutLogger = WorkoutLoggerView(exercise: createMockExercise(restSeconds: 1))

    workoutLogger.completeSet(setIndex: 0, reps: 10, weight: 20.0)
    workoutLogger.startTimer(for: 0)

    let expectation = XCTestExpectation(description: "Timer completion")

    workoutLogger.onTimerCompletion = {
        XCTAssertFalse(workoutLogger.isTimerRunning)
        expectation.fulfill()
    }

    wait(for: [expectation], timeout: 2.0)
}
```

### 4.2 Timer UI Tests
**Purpose**: Test timer display and controls

```swift
// Test timer display format
func testTimerDisplayFormat() {
    let workoutLogger = WorkoutLoggerView(exercise: createMockExercise(restSeconds: 125))

    workoutLogger.completeSet(setIndex: 0, reps: 10, weight: 20.0)
    workoutLogger.startTimer(for: 0)

    // Should display as MM:SS format
    XCTAssertEqual(workoutLogger.timerDisplayText, "2:05")
}

// Test timer controls accessibility
func testTimerControlsAccessibility() {
    let workoutLogger = WorkoutLoggerView(exercise: createMockExercise())

    workoutLogger.completeSet(setIndex: 0, reps: 10, weight: 20.0)

    // Timer controls should have proper accessibility labels
    XCTAssertEqual(workoutLogger.startTimerButton.accessibilityLabel, "Start rest timer")
    XCTAssertEqual(workoutLogger.pauseTimerButton.accessibilityLabel, "Pause rest timer")
    XCTAssertEqual(workoutLogger.resetTimerButton.accessibilityLabel, "Reset rest timer")
}
```

---

## 5. Exercise Demo Integration Tests

### 5.1 Demo Tab Tests
**Purpose**: Test exercise demonstration functionality

```swift
// Test demo tab displays exercise information
func testDemoTabDisplaysExerciseInfo() {
    let exercise = createMockExercise(
        displayName: "Barbell Bench Press",
        primaryMuscle: "Chest",
        instructions: "Step 1: Lie on bench\nStep 2: Grip bar"
    )

    let demoView = ExerciseDemoView(exercise: exercise)

    XCTAssertEqual(demoView.exerciseName, "Barbell Bench Press")
    XCTAssertEqual(demoView.targetMuscle, "Chest")
    XCTAssertEqual(demoView.instructionSteps.count, 2)
    XCTAssertEqual(demoView.instructionSteps[0], "Step 1: Lie on bench")
    XCTAssertEqual(demoView.instructionSteps[1], "Step 2: Grip bar")
}

// Test video player integration
func testVideoPlayerIntegration() {
    let exercise = createMockExercise(videoUrl: "https://bunny.net/exercise123.mp4")
    let demoView = ExerciseDemoView(exercise: exercise)

    XCTAssertNotNil(demoView.videoPlayer)
    XCTAssertEqual(demoView.videoURL?.absoluteString, "https://bunny.net/exercise123.mp4")
}

// Test demo tab switching
func testDemoTabSwitching() {
    let workoutLogger = WorkoutLoggerView(exercise: createMockExercise())

    // Start in logger tab
    XCTAssertEqual(workoutLogger.selectedTab, .logger)

    // Switch to demo tab
    workoutLogger.selectTab(.demo)
    XCTAssertEqual(workoutLogger.selectedTab, .demo)

    // Should preserve logger state when switching back
    workoutLogger.completeSet(setIndex: 0, reps: 10, weight: 20.0)
    workoutLogger.selectTab(.demo)
    workoutLogger.selectTab(.logger)

    XCTAssertTrue(workoutLogger.isSetCompleted(0))
}
```

---

## 6. Data Persistence Tests

### 6.1 Workout Data Persistence Tests
**Purpose**: Test workout data is properly saved and loaded

```swift
// Test workout progress is saved automatically
func testWorkoutProgressAutoSave() {
    let workoutLogger = WorkoutLoggerView(exercise: createMockExercise())

    workoutLogger.completeSet(setIndex: 0, reps: 10, weight: 20.0)
    workoutLogger.completeSet(setIndex: 1, reps: 9, weight: 20.0)

    // Should trigger auto-save
    XCTAssertTrue(workoutLogger.hasUnsavedChanges == false)

    // Verify data is saved to database
    let savedWorkout = workoutLogger.getCurrentWorkout()
    XCTAssertEqual(savedWorkout.sets.count, 2)
    XCTAssertEqual(savedWorkout.sets[0].reps, 10)
    XCTAssertEqual(savedWorkout.sets[1].reps, 9)
}

// Test workout can be resumed after app restart
func testWorkoutResumeAfterRestart() {
    let exercise = createMockExercise()
    let workoutLogger1 = WorkoutLoggerView(exercise: exercise)

    // Complete some sets
    workoutLogger1.completeSet(setIndex: 0, reps: 10, weight: 20.0)
    workoutLogger1.completeSet(setIndex: 1, reps: 9, weight: 20.0)

    // Simulate app restart - create new logger instance
    let workoutLogger2 = WorkoutLoggerView(exercise: exercise)

    // Should restore previous state
    XCTAssertTrue(workoutLogger2.isSetCompleted(0))
    XCTAssertTrue(workoutLogger2.isSetCompleted(1))
    XCTAssertFalse(workoutLogger2.isSetCompleted(2))

    XCTAssertEqual(workoutLogger2.getSetReps(0), 10)
    XCTAssertEqual(workoutLogger2.getSetReps(1), 9)
}

// Test historical data for rep counter
func testHistoricalDataForRepCounter() {
    let exercise = createMockExercise()

    // Create historical workout
    let historicalWorkout = createMockWorkout(
        exercise: exercise,
        sets: [
            WorkoutSet(reps: 8, weight: 20.0, completed: true),
            WorkoutSet(reps: 7, weight: 20.0, completed: true),
            WorkoutSet(reps: 6, weight: 20.0, completed: true)
        ]
    )

    workoutDataManager.saveWorkout(historicalWorkout)

    // Create new workout logger
    let workoutLogger = WorkoutLoggerView(exercise: exercise)

    // Should load historical data for comparison
    XCTAssertNotNil(workoutLogger.previousSessionData)
    XCTAssertEqual(workoutLogger.previousSessionData?.sets.count, 3)
    XCTAssertEqual(workoutLogger.previousSessionData?.sets[0].reps, 8)
}
```

### 6.2 Data Migration Tests
**Purpose**: Test data migration between app versions

```swift
// Test migration from old database schema
func testDatabaseSchemaMigration() {
    // Create old-style workout data
    let oldWorkout = createLegacyWorkout()

    // Run migration
    DatabaseMigrator.migrateTo(version: "2.0")

    // Verify old data is accessible with new schema
    let migratedWorkout = try! dbQueue.read { db in
        try Workout.fetchOne(db, key: oldWorkout.id)
    }

    XCTAssertNotNil(migratedWorkout)
    XCTAssertEqual(migratedWorkout?.exerciseId, oldWorkout.exerciseId)
}

// Test backwards compatibility
func testBackwardsCompatibility() {
    // Newer app should handle data created by older versions
    let oldFormatData = createOldFormatWorkoutData()

    let workoutLogger = WorkoutLoggerView(exercise: createMockExercise())

    // Should not crash when loading old format data
    XCTAssertNoThrow(try workoutLogger.loadWorkoutData(oldFormatData))
}
```

---

## Helper Functions

### Mock Data Creation

```swift
// Create mock exercise for testing
func createMockExercise(
    displayName: String = "Test Exercise",
    primaryMuscle: String = "Chest",
    repRangeMin: Int = 6,
    repRangeMax: Int = 10,
    sets: Int = 3,
    restSeconds: Int = 90,
    canonicalRating: Int = 80,
    videoUrl: String? = nil
) -> Exercise {
    return Exercise(
        exerciseId: "EX001",
        displayName: displayName,
        primaryMuscle: primaryMuscle,
        repRangeMin: repRangeMin,
        repRangeMax: repRangeMax,
        sets: sets,
        restSeconds: restSeconds,
        canonicalRating: canonicalRating,
        videoUrl: videoUrl,
        instructions: "Test instructions"
    )
}

// Create mock workout session
func createMockSession(exercises: [Exercise]? = nil) -> WorkoutSession {
    let defaultExercises = exercises ?? [
        createMockExercise(canonicalRating: 90),
        createMockExercise(canonicalRating: 80),
        createMockExercise(canonicalRating: 70)
    ]

    return WorkoutSession(
        sessionId: UUID().uuidString,
        name: "Test Session",
        exercises: defaultExercises
    )
}

// Create mock workout with completed sets
func createMockWorkout(exercise: Exercise, sets: [WorkoutSet]) -> Workout {
    return Workout(
        workoutId: UUID().uuidString,
        exerciseId: exercise.exerciseId,
        date: Date(),
        sets: sets,
        completed: sets.allSatisfy { $0.completed }
    )
}
```

### Test Execution Framework

```swift
// Base test class for workout logger tests
class WorkoutLoggerTestCase: XCTestCase {
    var testDatabase: DatabaseQueue!
    var workoutDataManager: WorkoutDataManager!

    override func setUp() {
        super.setUp()
        testDatabase = createInMemoryDatabase()
        workoutDataManager = WorkoutDataManager(database: testDatabase)
    }

    override func tearDown() {
        testDatabase = nil
        workoutDataManager = nil
        super.tearDown()
    }

    func createInMemoryDatabase() -> DatabaseQueue {
        let dbQueue = DatabaseQueue()
        try! dbQueue.write { db in
            try createTestTables(db)
        }
        return dbQueue
    }
}
```

---

## Performance Benchmarks

### Expected Performance Metrics

```swift
// Test workout logger loads within acceptable time
func testWorkoutLoggerLoadTime() {
    measure {
        let workoutLogger = WorkoutLoggerView(exercise: createMockExercise())
        _ = workoutLogger.view // Force view loading
    }

    // Should load within 0.1 seconds
}

// Test rep counter calculations are fast
func testRepCounterPerformance() {
    let largePreviousSession = createMockWorkout(
        exercise: createMockExercise(),
        sets: Array(0..<100).map { _ in WorkoutSet(reps: 10, weight: 20.0, completed: true) }
    )

    measure {
        _ = RepCounterCalculator.calculateExcessReps(
            currentSets: largePreviousSession.sets,
            previousSets: largePreviousSession.sets
        )
    }

    // Should calculate within 0.01 seconds even with large datasets
}
```

---

**Document Version**: 1.0
**Created**: January 10, 2026
**Author**: Claude Code
**Applies to**: trAIn iOS Workout Logger and Progression System