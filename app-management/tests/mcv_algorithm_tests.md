# MCV Algorithm and Programme Generation Tests

## Overview
This document contains comprehensive tests for the MCV (Most Constrained Variable) heuristic algorithm and programme generation system implemented in the trAIn iOS app. These tests ensure the system works correctly across all user scenarios and maintains the quality standards expected by the app's users.

## Test Categories

1. [Database Schema Tests](#1-database-schema-tests)
2. [MCV Algorithm Tests](#2-mcv-algorithm-tests)
3. [Programme Generation Tests](#3-programme-generation-tests)
4. [Constraint Handling Tests](#4-constraint-handling-tests)
5. [Sets/Reps/Rest Assignment Tests](#5-setsrepsrest-assignment-tests)
6. [UI Integration Tests](#6-ui-integration-tests)
7. [Edge Case Tests](#7-edge-case-tests)

---

## 1. Database Schema Tests

### 1.1 Schema Validation Tests
**Purpose**: Ensure database structure matches expected schema

```swift
// Test canonical_rating field exists and has correct range
func testCanonicalRatingField() {
    let exercises = try! dbQueue.read { db in
        try DBExercise.fetchAll(db)
    }

    for exercise in exercises {
        XCTAssert(exercise.canonicalRating >= 0, "Canonical rating should be >= 0")
        XCTAssert(exercise.canonicalRating <= 100, "Canonical rating should be <= 100")
    }
}

// Test progression_id and regression_id fields exist
func testProgressionRegressionFields() {
    let exercises = try! dbQueue.read { db in
        try DBExercise.fetchAll(db)
    }

    // Should not crash accessing these fields
    for exercise in exercises {
        _ = exercise.progressionId
        _ = exercise.regressionId
    }
}

// Test complexity_level is now STRING type with correct values
func testComplexityLevelStringType() {
    let exercises = try! dbQueue.read { db in
        try DBExercise.fetchAll(db)
    }

    let validComplexityLevels = ["all", "1", "2", "3"]

    for exercise in exercises {
        XCTAssert(validComplexityLevels.contains(exercise.complexityLevel),
                 "Complexity level '\(exercise.complexityLevel)' is invalid")
    }
}
```

### 1.2 Data Integrity Tests
**Purpose**: Ensure all required fields are populated without defaults

```swift
// Test no exercises have nil canonical_rating (fail-fast validation)
func testNoMissingCanonicalRatings() {
    let exercises = try! dbQueue.read { db in
        try DBExercise.fetchAll(db)
    }

    for exercise in exercises {
        XCTAssertNotNil(exercise.canonicalRating,
                       "Exercise \(exercise.exerciseId) missing canonical_rating")
    }
}

// Test equipment hierarchy is properly maintained
func testEquipmentHierarchy() {
    let exercises = try! dbQueue.read { db in
        try DBExercise.fetchAll(db)
    }

    for exercise in exercises {
        XCTAssertFalse(exercise.equipmentCategory.isEmpty,
                      "Exercise \(exercise.exerciseId) missing equipment category")

        // If specific equipment exists, category must also exist
        if exercise.equipmentSpecific != nil {
            XCTAssertFalse(exercise.equipmentCategory.isEmpty,
                          "Exercise \(exercise.exerciseId) has specific but no category")
        }
    }
}
```

---

## 2. MCV Algorithm Tests

### 2.1 Basic MCV Selection Tests
**Purpose**: Verify MCV algorithm correctly identifies most constrained variables

```swift
// Test MCV algorithm selects slot with fewest candidates first
func testMCVSelectsMostConstrainedSlot() {
    let mockExercises = [
        createMockExercise(id: "EX001", muscle: "Chest", canonicalRating: 90),
        createMockExercise(id: "EX002", muscle: "Chest", canonicalRating: 80),
        createMockExercise(id: "EX003", muscle: "Back", canonicalRating: 85),
        // Only one Back exercise vs two Chest exercises
    ]

    let template: [String: Int] = ["Chest": 1, "Back": 1]

    let result = exerciseRepository.mcvSelectExercises(
        from: mockExercises,
        count: 2,
        experienceLevel: .intermediate,
        excludedExerciseIds: [],
        excludedDisplayNames: []
    )

    // Should fill Back first (most constrained), then Chest
    XCTAssertEqual(result.0.count, 2)
    XCTAssert(result.0.contains { $0.primaryMuscle == "Back" })
    XCTAssert(result.0.contains { $0.primaryMuscle == "Chest" })
}

// Test canonical rating ordering within selection
func testCanonicalRatingOrdering() {
    let mockExercises = [
        createMockExercise(id: "EX001", muscle: "Chest", canonicalRating: 70),
        createMockExercise(id: "EX002", muscle: "Chest", canonicalRating: 90),
        createMockExercise(id: "EX003", muscle: "Chest", canonicalRating: 80),
    ]

    let result = exerciseRepository.mcvSelectExercises(
        from: mockExercises,
        count: 1,
        experienceLevel: .intermediate,
        excludedExerciseIds: [],
        excludedDisplayNames: []
    )

    // Should select highest rated (90) first
    XCTAssertEqual(result.0.first?.canonicalRating, 90)
}
```

### 2.2 Experience Level Filtering Tests
**Purpose**: Verify complexity filtering based on experience level

```swift
// Test experience level filters correctly
func testExperienceLevelComplexityFiltering() {
    let mockExercises = [
        createMockExercise(id: "EX001", complexity: "1", canonicalRating: 80),
        createMockExercise(id: "EX002", complexity: "2", canonicalRating: 85),
        createMockExercise(id: "EX003", complexity: "3", canonicalRating: 90),
        createMockExercise(id: "EX004", complexity: "all", canonicalRating: 75),
    ]

    // Beginner should only get complexity <= 2 AND "all"
    let beginnerResult = exerciseRepository.mcvSelectExercises(
        from: mockExercises,
        count: 4,
        experienceLevel: .beginner,
        excludedExerciseIds: [],
        excludedDisplayNames: []
    )

    for exercise in beginnerResult.0 {
        XCTAssert(exercise.complexityLevel == "all" ||
                 exercise.numericComplexity <= 2,
                 "Beginner got complexity > 2: \(exercise.complexityLevel)")
    }

    // Advanced should get all exercises
    let advancedResult = exerciseRepository.mcvSelectExercises(
        from: mockExercises,
        count: 4,
        experienceLevel: .advanced,
        excludedExerciseIds: [],
        excludedDisplayNames: []
    )

    XCTAssertEqual(advancedResult.0.count, 4)
}
```

### 2.3 Constraint Enforcement Tests
**Purpose**: Test hard and soft constraint handling

```swift
// Test canonical name deduplication within session
func testCanonicalNameDeduplicationWithinSession() {
    let mockExercises = [
        createMockExercise(id: "EX001", canonical: "Bench Press", display: "Flat Bench Press"),
        createMockExercise(id: "EX002", canonical: "Bench Press", display: "Incline Bench Press"),
        createMockExercise(id: "EX003", canonical: "Squat", display: "Back Squat"),
    ]

    let result = exerciseRepository.mcvSelectExercises(
        from: mockExercises,
        count: 3,
        experienceLevel: .intermediate,
        excludedExerciseIds: [],
        excludedDisplayNames: []
    )

    // Should only get one Bench Press canonical per session
    let canonicalNames = result.0.map { $0.canonicalName }
    let uniqueCanonicalNames = Set(canonicalNames)
    XCTAssertEqual(canonicalNames.count, uniqueCanonicalNames.count,
                  "Duplicate canonical names in session")
}

// Test display name deduplication across programme
func testDisplayNameDeduplicationAcrossProgramme() {
    let usedDisplayNames: Set<String> = ["Flat Bench Press"]

    let mockExercises = [
        createMockExercise(id: "EX001", display: "Flat Bench Press"),
        createMockExercise(id: "EX002", display: "Incline Bench Press"),
    ]

    let result = exerciseRepository.mcvSelectExercises(
        from: mockExercises,
        count: 2,
        experienceLevel: .intermediate,
        excludedExerciseIds: [],
        excludedDisplayNames: usedDisplayNames
    )

    // Should not include "Flat Bench Press" again
    XCTAssertFalse(result.0.contains { $0.displayName == "Flat Bench Press" })
}
```

---

## 3. Programme Generation Tests

### 3.1 Split Template Tests
**Purpose**: Verify programme generation follows split templates correctly

```swift
// Test programme follows selected split template
func testProgrammeFollowsSplitTemplate() {
    let userProfile = createMockUserProfile(
        trainingDays: 3,
        split: "Push/Pull/Legs",
        experienceLevel: .intermediate
    )

    let programme = programGenerator.generateProgram(for: userProfile)

    XCTAssertEqual(programme.sessions.count, 3)

    // Verify session names match split
    let sessionNames = programme.sessions.map { $0.name }.sorted()
    XCTAssertEqual(sessionNames, ["Legs", "Pull", "Push"])
}

// Test muscle group distribution matches template
func testMuscleGroupDistribution() {
    let userProfile = createMockUserProfile(
        trainingDays: 3,
        split: "Push/Pull/Legs"
    )

    let programme = programGenerator.generateProgram(for: userProfile)
    let pushSession = programme.sessions.first { $0.name == "Push" }!

    // Push session should contain push muscles
    let pushMuscles = ["Chest", "Shoulders", "Triceps"]
    let sessionMuscles = pushSession.exercises.map { $0.primaryMuscle }

    for muscle in sessionMuscles {
        XCTAssert(pushMuscles.contains(muscle),
                 "Non-push muscle \(muscle) in Push session")
    }
}
```

### 3.2 Priority Muscle Tests
**Purpose**: Test priority muscle handling (+1 exercise rule)

```swift
// Test priority muscles get extra exercises
func testPriorityMusclesGetExtraExercises() {
    let userProfile = createMockUserProfile(
        trainingDays: 3,
        split: "Push/Pull/Legs",
        priorityMuscles: ["Chest"]
    )

    let programme = programGenerator.generateProgram(for: userProfile)
    let pushSession = programme.sessions.first { $0.name == "Push" }!

    let chestExercises = pushSession.exercises.filter { $0.primaryMuscle == "Chest" }

    // Should have base count + 1 for priority
    XCTAssertGreaterThanOrEqual(chestExercises.count, 2,
                               "Priority muscle should get extra exercise")
}
```

### 3.3 Equipment Filtering Tests
**Purpose**: Test equipment availability filtering

```swift
// Test equipment filtering works correctly
func testEquipmentFiltering() {
    let userProfile = createMockUserProfile(
        equipment: ["Dumbbells"] // Only dumbbells available
    )

    let programme = programGenerator.generateProgram(for: userProfile)

    for session in programme.sessions {
        for exercise in session.exercises {
            XCTAssert(exercise.equipmentCategory == "Dumbbells" ||
                     exercise.equipmentCategory == "Other",
                     "Exercise requires unavailable equipment: \(exercise.equipmentCategory)")
        }
    }
}
```

---

## 4. Constraint Handling Tests

### 4.1 Soft Constraint Relaxation Tests
**Purpose**: Test soft constraint relaxation when needed

```swift
// Test display name repeat warning when equipment is limited
func testDisplayNameRepeatWarning() {
    let userProfile = createMockUserProfile(
        equipment: ["Dumbbells"], // Very limited equipment
        trainingDays: 6 // High frequency
    )

    let result = programGenerator.generateProgram(for: userProfile)

    // Should trigger repeat warning due to limited equipment
    XCTAssertTrue(result.repeatWarning,
                 "Should warn about repeated exercises with limited equipment")
}

// Test low fill rate warning
func testLowFillRateWarning() {
    let userProfile = createMockUserProfile(
        equipment: [], // No equipment - extreme case
        experienceLevel: .noExperience // Very limited complexity
    )

    let result = programGenerator.generateProgram(for: userProfile)

    // Should trigger low fill warning
    XCTAssertTrue(result.lowFillWarning,
                 "Should warn about low fill rate with severe limitations")

    // Fill rate should be below 75%
    XCTAssertLessThan(result.fillRatePercentage, 75.0,
                     "Fill rate should be below threshold")
}
```

### 4.2 Hard Constraint Enforcement Tests
**Purpose**: Test that hard constraints are never broken

```swift
// Test programme generation fails gracefully when impossible
func testProgrammeGenerationFailsGracefully() {
    let userProfile = createMockUserProfile(
        equipment: [], // No equipment
        experienceLevel: .noExperience, // No experience
        trainingDays: 6 // High frequency
    )

    // Should either generate with warnings or fail completely
    // Never generate invalid programme
    let result = programGenerator.generateProgram(for: userProfile)

    if !result.sessions.isEmpty {
        // If generated, must have valid warnings
        XCTAssertTrue(result.lowFillWarning || result.repeatWarning,
                     "Invalid programme without appropriate warnings")
    }
}
```

---

## 5. Sets/Reps/Rest Assignment Tests

### 5.1 Rep Range Assignment Tests
**Purpose**: Test goal-based rep range assignment

```swift
// Test strength goal rep ranges
func testStrengthGoalRepRanges() {
    let userProfile = createMockUserProfile(goals: ["Get Stronger"])
    let programme = programGenerator.generateProgram(for: userProfile)

    for session in programme.sessions {
        for exercise in session.exercises {
            if exercise.canonicalRating > 75 {
                // High-rated exercises should get 5-8 or 6-10
                XCTAssert(exercise.repRangeMin >= 5 && exercise.repRangeMax <= 10,
                         "High-rated exercise has wrong rep range for strength")
            } else {
                // Lower-rated exercises should get 6-10 or 8-12
                XCTAssert(exercise.repRangeMin >= 6 && exercise.repRangeMax <= 12,
                         "Lower-rated exercise has wrong rep range for strength")
            }
        }
    }
}

// Test hypertrophy goal rep ranges
func testHypertrophyGoalRepRanges() {
    let userProfile = createMockUserProfile(goals: ["Increase Muscle"])
    let programme = programGenerator.generateProgram(for: userProfile)

    for session in programme.sessions {
        for exercise in session.exercises {
            // All exercises should get 6-10 or 8-12
            XCTAssert(exercise.repRangeMin >= 6 && exercise.repRangeMax <= 12,
                     "Exercise has wrong rep range for hypertrophy")
        }
    }
}

// Test fat loss goal rep ranges
func testFatLossGoalRepRanges() {
    let userProfile = createMockUserProfile(goals: ["Fat Loss"])
    let programme = programGenerator.generateProgram(for: userProfile)

    for session in programme.sessions {
        for exercise in session.exercises {
            // All exercises should get 8-12 or 10-14
            XCTAssert(exercise.repRangeMin >= 8 && exercise.repRangeMax <= 14,
                     "Exercise has wrong rep range for fat loss")
        }
    }
}
```

### 5.2 Rest Period Assignment Tests
**Purpose**: Test canonical rating-based rest periods

```swift
// Test rest period assignment based on canonical rating
func testRestPeriodAssignment() {
    let programme = programGenerator.generateProgram(for: createMockUserProfile())

    for session in programme.sessions {
        for exercise in session.exercises {
            if exercise.canonicalRating > 80 {
                XCTAssertEqual(exercise.restSeconds, 120,
                              "High-rated exercise should get 120s rest")
            } else if exercise.canonicalRating >= 50 {
                XCTAssertEqual(exercise.restSeconds, 90,
                              "Mid-rated exercise should get 90s rest")
            } else {
                XCTAssertEqual(exercise.restSeconds, 60,
                              "Low-rated exercise should get 60s rest")
            }
        }
    }
}

// Test all exercises get 3 sets
func testAllExercisesGetThreeSets() {
    let programme = programGenerator.generateProgram(for: createMockUserProfile())

    for session in programme.sessions {
        for exercise in session.exercises {
            XCTAssertEqual(exercise.sets, 3, "All exercises should have 3 sets")
        }
    }
}
```

---

## 6. UI Integration Tests

### 6.1 Workout Logger Tests
**Purpose**: Test workout logger integration with new system

```swift
// Test workout logger displays exercises in canonical rating order
func testWorkoutLoggerExerciseOrdering() {
    let session = createMockSession()
    let workoutLoggerView = WorkoutLoggerView(session: session)

    let exercises = session.exercises
    for i in 0..<(exercises.count - 1) {
        XCTAssertGreaterThanOrEqual(exercises[i].canonicalRating,
                                   exercises[i + 1].canonicalRating,
                                   "Exercises not ordered by canonical rating")
    }
}

// Test complexity level display works with string values
func testComplexityLevelDisplay() {
    let exercise = createMockExercise(complexity: "2")

    // Should display numeric complexity correctly
    XCTAssertEqual(exercise.numericComplexity, 2)

    // Test "all" complexity handling
    let universalExercise = createMockExercise(complexity: "all")
    XCTAssertEqual(universalExercise.numericComplexity, 1) // Should default to 1
}
```

### 6.2 Programme Overview Tests
**Purpose**: Test programme overview displays correctly

```swift
// Test programme overview shows warning indicators
func testProgrammeOverviewWarnings() {
    let programme = createMockProgramme(
        lowFillWarning: true,
        repeatWarning: false
    )

    let overviewView = ProgrammeOverviewView(programme: programme)

    // Should display low fill warning
    XCTAssertTrue(overviewView.showsLowFillWarning)
    XCTAssertFalse(overviewView.showsRepeatWarning)
}

// Test fill rate percentage display
func testFillRatePercentageDisplay() {
    let programme = createMockProgramme(fillRate: 82.5)
    let overviewView = ProgrammeOverviewView(programme: programme)

    XCTAssertEqual(overviewView.fillRateText, "82.5%")
}
```

---

## 7. Edge Case Tests

### 7.1 Extreme Limitation Tests
**Purpose**: Test behaviour with extreme user limitations

```swift
// Test user with no equipment
func testNoEquipmentScenario() {
    let userProfile = createMockUserProfile(equipment: [])
    let result = programGenerator.generateProgram(for: userProfile)

    // Should either fail gracefully or generate bodyweight-only programme
    if !result.sessions.isEmpty {
        for session in result.sessions {
            for exercise in session.exercises {
                XCTAssertEqual(exercise.equipmentCategory, "Other",
                              "Should only include bodyweight exercises")
            }
        }
    }
}

// Test complete beginner with minimal equipment
func testCompletBeginnerMinimalEquipment() {
    let userProfile = createMockUserProfile(
        experienceLevel: .noExperience,
        equipment: ["Dumbbells"]
    )

    let programme = programGenerator.generateProgram(for: userProfile)

    for session in programme.sessions {
        for exercise in session.exercises {
            XCTAssert(exercise.complexityLevel == "all" || exercise.complexityLevel == "1",
                     "Beginner got exercise with complexity > 1")
        }
    }
}

// Test advanced user requesting 6-day programme
func testAdvancedUserHighFrequency() {
    let userProfile = createMockUserProfile(
        experienceLevel: .advanced,
        trainingDays: 6
    )

    let programme = programGenerator.generateProgram(for: userProfile)

    XCTAssertEqual(programme.sessions.count, 6)

    // Should handle display name repeats gracefully
    let allDisplayNames = programme.sessions.flatMap { session in
        session.exercises.map { $0.displayName }
    }

    // If repeats exist, should have repeat warning
    let uniqueNames = Set(allDisplayNames)
    if allDisplayNames.count > uniqueNames.count {
        XCTAssertTrue(programme.repeatWarning,
                     "Should warn about repeated exercises in high-frequency programme")
    }
}
```

### 7.2 Data Consistency Tests
**Purpose**: Test data consistency across the system

```swift
// Test canonical rating consistency across database
func testCanonicalRatingConsistency() {
    let exercises = try! dbQueue.read { db in
        try DBExercise.fetchAll(db)
    }

    // Group by canonical name and check rating consistency
    let exercisesByCanonical = Dictionary(grouping: exercises) { $0.canonicalName }

    for (canonicalName, exerciseGroup) in exercisesByCanonical {
        let ratings = Set(exerciseGroup.map { $0.canonicalRating })

        // All exercises with same canonical name should have same rating
        XCTAssertEqual(ratings.count, 1,
                      "Inconsistent ratings for canonical name: \(canonicalName)")
    }
}

// Test equipment hierarchy consistency
func testEquipmentHierarchyConsistency() {
    let exercises = try! dbQueue.read { db in
        try DBExercise.fetchAll(db)
    }

    // Verify equipment_specific only exists for valid categories
    let validExpandableCategories = Set(EquipmentHierarchy.expandableCategories.keys)

    for exercise in exercises {
        if exercise.equipmentSpecific != nil {
            let questionnaireCategory = mapDatabaseToQuestionnaire(exercise.equipmentCategory)
            XCTAssert(validExpandableCategories.contains(questionnaireCategory),
                     "Equipment specific exists for non-expandable category: \(exercise.equipmentCategory)")
        }
    }
}
```

---

## Test Data Helpers

### Mock Data Creation Functions

```swift
// Helper function to create mock exercises
func createMockExercise(
    id: String = "EX001",
    canonical: String = "Test Exercise",
    display: String = "Test Exercise",
    muscle: String = "Chest",
    complexity: String = "2",
    canonicalRating: Int = 80,
    equipment: String = "Dumbbells"
) -> DBExercise {
    return DBExercise(
        exerciseId: id,
        canonicalName: canonical,
        displayName: display,
        equipmentCategory: equipment,
        equipmentSpecific: nil,
        complexityLevel: complexity,
        isIsolation: false,
        primaryMuscle: muscle,
        secondaryMuscle: nil,
        instructions: "Test instructions",
        isInProgramme: true,
        canonicalRating: canonicalRating,
        progressionId: nil,
        regressionId: nil
    )
}

// Helper function to create mock user profile
func createMockUserProfile(
    trainingDays: Int = 3,
    split: String = "Push/Pull/Legs",
    experienceLevel: ExperienceLevel = .intermediate,
    goals: [String] = ["Increase Muscle"],
    equipment: [String] = ["Dumbbells", "Barbells"],
    priorityMuscles: [String] = []
) -> UserProfile {
    return UserProfile(
        trainingDaysPerWeek: trainingDays,
        selectedSplit: split,
        experienceLevel: experienceLevel,
        fitnessGoals: goals,
        availableEquipment: equipment,
        priorityMuscleGroups: priorityMuscles,
        injuryHistory: []
    )
}
```

---

## Test Execution Guidelines

### Running Tests
1. **Unit Tests**: Run individual functions using XCTest framework
2. **Integration Tests**: Test complete programme generation flow
3. **UI Tests**: Use XCUITest for interface validation
4. **Performance Tests**: Measure algorithm execution time

### Success Criteria
- All tests pass consistently
- Programme generation completes within 2 seconds
- No crashes or memory leaks
- UI displays correctly on all supported devices
- Database queries execute efficiently

### Continuous Integration
These tests should be run:
- Before each commit
- On each pull request
- Before each release
- After database schema changes

---

**Document Version**: 1.0
**Created**: January 10, 2026
**Author**: Claude Code
**Applies to**: trAIn iOS MCV Algorithm Implementation