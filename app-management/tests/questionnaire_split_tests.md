# Questionnaire and Split Selection Tests

## Overview
This document contains comprehensive tests for the 2-part questionnaire system, split selection logic, and programme generation based on user preferences. These tests ensure users get appropriate programme recommendations based on their inputs.

## Test Categories

1. [Questionnaire Flow Tests](#1-questionnaire-flow-tests)
2. [Split Selection Logic Tests](#2-split-selection-logic-tests)
3. [Equipment Selection Tests](#3-equipment-selection-tests)
4. [Experience Level Tests](#4-experience-level-tests)
5. [Goal and Priority Muscle Tests](#5-goal-and-priority-muscle-tests)
6. [Integration Tests](#6-integration-tests)

---

## 1. Questionnaire Flow Tests

### 1.1 Two-Part Questionnaire Structure Tests
**Purpose**: Verify questionnaire follows correct flow and structure

```swift
// Test questionnaire has two distinct parts
func testTwoPartQuestionnaireStructure() {
    let questionnaire = QuestionnaireController()

    XCTAssertEqual(questionnaire.numberOfParts, 2)

    // Part 1: Training preferences
    let part1Steps = questionnaire.getStepsForPart(1)
    let expectedPart1Steps = [
        "TrainingDays", "SessionDuration", "Equipment", "EquipmentSpecific",
        "Experience", "Goals", "PriorityMuscles", "Injuries", "SplitSelection"
    ]

    XCTAssertEqual(part1Steps.map { $0.identifier }, expectedPart1Steps)

    // Part 2: Personal stats
    let part2Steps = questionnaire.getStepsForPart(2)
    let expectedPart2Steps = ["Age", "Weight", "Height", "Gender"]

    XCTAssertEqual(part2Steps.map { $0.identifier }, expectedPart2Steps)
}

// Test questionnaire step progression
func testQuestionnaireStepProgression() {
    let questionnaire = QuestionnaireController()

    // Should start at first step
    XCTAssertEqual(questionnaire.currentStep, 0)
    XCTAssertEqual(questionnaire.currentStepIdentifier, "TrainingDays")

    // Should progress through steps correctly
    questionnaire.answerCurrentStep(answer: "3")
    questionnaire.nextStep()

    XCTAssertEqual(questionnaire.currentStep, 1)
    XCTAssertEqual(questionnaire.currentStepIdentifier, "SessionDuration")

    // Should be able to go back
    questionnaire.previousStep()
    XCTAssertEqual(questionnaire.currentStep, 0)
    XCTAssertEqual(questionnaire.currentStepIdentifier, "TrainingDays")
}

// Test questionnaire validation
func testQuestionnaireValidation() {
    let questionnaire = QuestionnaireController()

    // Should not proceed without answering
    XCTAssertFalse(questionnaire.canProceed)

    // Should validate answers appropriately
    XCTAssertFalse(questionnaire.isValidAnswer(for: "TrainingDays", answer: "0"))
    XCTAssertFalse(questionnaire.isValidAnswer(for: "TrainingDays", answer: "8"))
    XCTAssertTrue(questionnaire.isValidAnswer(for: "TrainingDays", answer: "3"))

    questionnaire.answerCurrentStep(answer: "3")
    XCTAssertTrue(questionnaire.canProceed)
}
```

### 1.2 Answer Persistence Tests
**Purpose**: Test answers are saved and can be retrieved

```swift
// Test answers are persisted between steps
func testAnswerPersistence() {
    let questionnaire = QuestionnaireController()

    // Answer multiple steps
    questionnaire.answerStep("TrainingDays", answer: "3")
    questionnaire.answerStep("SessionDuration", answer: "60")
    questionnaire.answerStep("Experience", answer: "intermediate")

    // Should retain all answers
    XCTAssertEqual(questionnaire.getAnswer(for: "TrainingDays"), "3")
    XCTAssertEqual(questionnaire.getAnswer(for: "SessionDuration"), "60")
    XCTAssertEqual(questionnaire.getAnswer(for: "Experience"), "intermediate")
}

// Test questionnaire can be resumed
func testQuestionnaireResume() {
    let questionnaire1 = QuestionnaireController()

    // Answer some questions
    questionnaire1.answerStep("TrainingDays", answer: "3")
    questionnaire1.answerStep("SessionDuration", answer: "60")

    // Save state
    let savedState = questionnaire1.saveState()

    // Create new questionnaire instance and restore
    let questionnaire2 = QuestionnaireController()
    questionnaire2.restoreState(savedState)

    // Should have same answers
    XCTAssertEqual(questionnaire2.getAnswer(for: "TrainingDays"), "3")
    XCTAssertEqual(questionnaire2.getAnswer(for: "SessionDuration"), "60")
}
```

---

## 2. Split Selection Logic Tests

### 2.1 Split Availability Tests
**Purpose**: Test correct splits are available based on training days

```swift
// Test splits available for 2-day training
func testTwoDayTrainingSplits() {
    let splitSelector = SplitSelector()
    let availableSplits = splitSelector.getAvailableSplits(for: 2)

    let expectedSplits = ["Full Body x2", "Upper Lower"]
    XCTAssertEqual(availableSplits.map { $0.name }.sorted(), expectedSplits.sorted())
}

// Test splits available for 3-day training
func testThreeDayTrainingSplits() {
    let splitSelector = SplitSelector()
    let availableSplits = splitSelector.getAvailableSplits(for: 3)

    let expectedSplits = ["Push Pull Legs", "Full Body x3", "2 Upper 1 Lower", "1 Upper 2 Lower"]
    XCTAssertEqual(availableSplits.map { $0.name }.sorted(), expectedSplits.sorted())
}

// Test splits available for 6-day training
func testSixDayTrainingSplits() {
    let splitSelector = SplitSelector()
    let availableSplits = splitSelector.getAvailableSplits(for: 6)

    let expectedSplits = ["PPL x2"]
    XCTAssertEqual(availableSplits.map { $0.name }, expectedSplits)
}
```

### 2.2 Split Recommendation Logic Tests
**Purpose**: Test split recommendations based on experience and priority muscles

```swift
// Test beginner recommendations for 2-day training
func testBeginnerTwoDayRecommendation() {
    let userProfile = createMockUserProfile(
        trainingDays: 2,
        experienceLevel: .beginner
    )

    let splitSelector = SplitSelector()
    let recommendations = splitSelector.getRecommendedSplits(for: userProfile)

    XCTAssertEqual(recommendations.first?.name, "Full Body x2")
    XCTAssertTrue(recommendations.first?.isRecommended == true)
}

// Test intermediate recommendations for 3-day training with leg priority
func testIntermediateThreeDayLegPriority() {
    let userProfile = createMockUserProfile(
        trainingDays: 3,
        experienceLevel: .intermediate,
        priorityMuscles: ["Quads", "Hamstrings", "Glutes"] // 3 leg muscles
    )

    let splitSelector = SplitSelector()
    let recommendations = splitSelector.getRecommendedSplits(for: userProfile)

    // Should recommend "1 Upper 2 Lower" for leg priority
    XCTAssertTrue(recommendations.contains { $0.name == "1 Upper 2 Lower" && $0.isRecommended })
}

// Test intermediate recommendations for 3-day training with upper priority
func testIntermediateThreeDayUpperPriority() {
    let userProfile = createMockUserProfile(
        trainingDays: 3,
        experienceLevel: .intermediate,
        priorityMuscles: ["Chest", "Shoulders", "Back"] // 3 upper muscles
    )

    let splitSelector = SplitSelector()
    let recommendations = splitSelector.getRecommendedSplits(for: userProfile)

    // Should recommend "2 Upper 1 Lower" for upper priority
    XCTAssertTrue(recommendations.contains { $0.name == "2 Upper 1 Lower" && $0.isRecommended })
}

// Test default intermediate 3-day recommendation
func testIntermediateThreeDayDefault() {
    let userProfile = createMockUserProfile(
        trainingDays: 3,
        experienceLevel: .intermediate,
        priorityMuscles: ["Chest"] // Only 1 priority muscle
    )

    let splitSelector = SplitSelector()
    let recommendations = splitSelector.getRecommendedSplits(for: userProfile)

    // Should recommend "Push Pull Legs" as default
    XCTAssertTrue(recommendations.contains { $0.name == "Push Pull Legs" && $0.isRecommended })
}
```

### 2.3 Priority Muscle Categorization Tests
**Purpose**: Test muscle group categorization for recommendations

```swift
// Test upper muscle categorization
func testUpperMuscleCategorization() {
    let upperMuscles = ["Chest", "Shoulders", "Back", "Biceps", "Triceps", "Traps"]

    for muscle in upperMuscles {
        XCTAssertTrue(MuscleGroupCategorizer.isUpperMuscle(muscle),
                     "\(muscle) should be categorized as upper muscle")
        XCTAssertFalse(MuscleGroupCategorizer.isLowerMuscle(muscle),
                      "\(muscle) should not be categorized as lower muscle")
    }
}

// Test lower muscle categorization
func testLowerMuscleCategorization() {
    let lowerMuscles = ["Quads", "Hamstrings", "Glutes", "Calves", "Abductors", "Adductors"]

    for muscle in lowerMuscles {
        XCTAssertTrue(MuscleGroupCategorizer.isLowerMuscle(muscle),
                     "\(muscle) should be categorized as lower muscle")
        XCTAssertFalse(MuscleGroupCategorizer.isUpperMuscle(muscle),
                      "\(muscle) should not be categorized as upper muscle")
    }
}

// Test priority muscle counting
func testPriorityMuscleCount() {
    let mixedMuscles = ["Chest", "Shoulders", "Quads", "Hamstrings"] // 2 upper, 2 lower

    let upperCount = MuscleGroupCategorizer.countUpperMuscles(mixedMuscles)
    let lowerCount = MuscleGroupCategorizer.countLowerMuscles(mixedMuscles)

    XCTAssertEqual(upperCount, 2)
    XCTAssertEqual(lowerCount, 2)
}
```

### 2.4 Split Explanation Tests
**Purpose**: Test split explanations are correct and informative

```swift
// Test split explanations are provided
func testSplitExplanations() {
    let splits = SplitTemplateLoader.loadAllSplits()

    for split in splits {
        XCTAssertFalse(split.explanation.isEmpty,
                      "Split \(split.name) missing explanation")
        XCTAssertGreaterThan(split.explanation.count, 20,
                            "Split \(split.name) explanation too short")
    }
}

// Test specific split explanations
func testSpecificSplitExplanations() {
    let splits = SplitTemplateLoader.loadAllSplits()

    let pplSplit = splits.first { $0.name == "Push Pull Legs" }!
    XCTAssertTrue(pplSplit.explanation.contains("movement pattern"),
                 "PPL explanation should mention movement patterns")

    let fullBodySplit = splits.first { $0.name == "Full Body" }!
    XCTAssertTrue(fullBodySplit.explanation.contains("every muscle"),
                 "Full body explanation should mention training every muscle")
}
```

---

## 3. Equipment Selection Tests

### 3.1 Equipment Hierarchy Tests
**Purpose**: Test expandable equipment categories work correctly

```swift
// Test expandable equipment categories
func testExpandableEquipmentCategories() {
    let equipmentSelector = EquipmentSelector()

    // Test barbells expand to specific items
    let barbellItems = equipmentSelector.getSpecificItems(for: "barbells")
    let expectedBarbellItems = [
        "Squat Rack", "Flat Bench Press", "Incline Bench Press",
        "Decline Bench Press", "Landmine Attachment", "Hip Thrust Bench"
    ]

    XCTAssertEqual(barbellItems.sorted(), expectedBarbellItems.sorted())

    // Test non-expandable categories
    let dumbellItems = equipmentSelector.getSpecificItems(for: "dumbbells")
    XCTAssertTrue(dumbellItems.isEmpty, "Dumbbells should not have specific items")
}

// Test equipment mapping from questionnaire to database
func testEquipmentQuestionnaireMapping() {
    let questionnaireEquipment = ["dumbbells", "barbells", "cable_machines"]
    let databaseEquipment = ExerciseDatabaseFilter.mapEquipmentFromQuestionnaire(questionnaireEquipment)

    let expectedDatabaseEquipment = ["Dumbbells", "Barbells", "Cables"]
    XCTAssertEqual(databaseEquipment.sorted(), expectedDatabaseEquipment.sorted())
}

// Test equipment validation
func testEquipmentValidation() {
    let equipmentSelector = EquipmentSelector()

    // Should require at least one equipment type
    XCTAssertFalse(equipmentSelector.isValidSelection([]))

    // Should accept valid equipment
    XCTAssertTrue(equipmentSelector.isValidSelection(["dumbbells"]))
    XCTAssertTrue(equipmentSelector.isValidSelection(["dumbbells", "barbells"]))
}
```

### 3.2 Equipment Specific Selection Tests
**Purpose**: Test specific equipment selection within categories

```swift
// Test specific equipment selection
func testSpecificEquipmentSelection() {
    let userProfile = createMockUserProfile()

    // Select barbells category
    userProfile.selectEquipment("barbells")

    // Should show specific barbell options
    let specificOptions = userProfile.getSpecificEquipmentOptions()
    XCTAssertTrue(specificOptions.contains("Squat Rack"))
    XCTAssertTrue(specificOptions.contains("Flat Bench Press"))

    // Select specific items
    userProfile.selectSpecificEquipment(["Squat Rack", "Flat Bench Press"])

    // Should be reflected in final equipment list
    let finalEquipment = userProfile.getFinalEquipmentSelection()
    XCTAssertTrue(finalEquipment.contains("Squat Rack"))
    XCTAssertTrue(finalEquipment.contains("Flat Bench Press"))
}

// Test equipment affects available exercises
func testEquipmentAffectsExercisePool() {
    let userProfile1 = createMockUserProfile(equipment: ["Dumbbells"])
    let userProfile2 = createMockUserProfile(equipment: ["Dumbbells", "Barbells"])

    let exerciseRepository = ExerciseRepository()

    let exercises1 = exerciseRepository.getAvailableExercises(for: userProfile1)
    let exercises2 = exerciseRepository.getAvailableExercises(for: userProfile2)

    // User with more equipment should have more exercise options
    XCTAssertGreaterThan(exercises2.count, exercises1.count)

    // User 1 should only have dumbbell exercises
    for exercise in exercises1 {
        XCTAssert(exercise.equipmentCategory == "Dumbbells" ||
                 exercise.equipmentCategory == "Other",
                 "User with only dumbbells got non-dumbbell exercise")
    }
}
```

---

## 4. Experience Level Tests

### 4.1 Experience Level Mapping Tests
**Purpose**: Test experience level mapping and validation

```swift
// Test experience level mapping from questionnaire
func testExperienceLevelMapping() {
    // Current UI values
    XCTAssertEqual(ExperienceLevel.fromQuestionnaire("no_experience"), .noExperience)
    XCTAssertEqual(ExperienceLevel.fromQuestionnaire("beginner"), .beginner)
    XCTAssertEqual(ExperienceLevel.fromQuestionnaire("intermediate"), .intermediate)
    XCTAssertEqual(ExperienceLevel.fromQuestionnaire("advanced"), .advanced)

    // Legacy values (backward compatibility)
    XCTAssertEqual(ExperienceLevel.fromQuestionnaire("0_months"), .noExperience)
    XCTAssertEqual(ExperienceLevel.fromQuestionnaire("0_6_months"), .beginner)
    XCTAssertEqual(ExperienceLevel.fromQuestionnaire("6_months_2_years"), .intermediate)
    XCTAssertEqual(ExperienceLevel.fromQuestionnaire("2_plus_years"), .advanced)

    // Invalid values should default to no experience
    XCTAssertEqual(ExperienceLevel.fromQuestionnaire("invalid"), .noExperience)
}

// Test experience level display names
func testExperienceLevelDisplayNames() {
    XCTAssertEqual(ExperienceLevel.noExperience.displayName, "Just Starting Out")
    XCTAssertEqual(ExperienceLevel.beginner.displayName, "Finding My Feet")
    XCTAssertEqual(ExperienceLevel.intermediate.displayName, "Getting Comfortable")
    XCTAssertEqual(ExperienceLevel.advanced.displayName, "Confident & Consistent")
}

// Test experience level subtitles are informative
func testExperienceLevelSubtitles() {
    for level in ExperienceLevel.allCases {
        XCTAssertFalse(level.subtitle.isEmpty,
                      "Experience level \(level) missing subtitle")
        XCTAssertGreaterThan(level.subtitle.count, 50,
                            "Experience level \(level) subtitle too short")
    }
}
```

### 4.2 Complexity Rules Tests
**Purpose**: Test complexity rules based on experience level

```swift
// Test no experience complexity rules
func testNoExperienceComplexityRules() {
    let rules = ExperienceLevel.noExperience.complexityRules

    XCTAssertEqual(rules.maxComplexity, 1)
    XCTAssertEqual(rules.maxComplexity4PerSession, 0)
    XCTAssertFalse(rules.complexity4MustBeFirst)
}

// Test beginner complexity rules
func testBeginnerComplexityRules() {
    let rules = ExperienceLevel.beginner.complexityRules

    XCTAssertEqual(rules.maxComplexity, 2)
    XCTAssertEqual(rules.maxComplexity4PerSession, 0)
    XCTAssertFalse(rules.complexity4MustBeFirst)
}

// Test intermediate complexity rules
func testIntermediateComplexityRules() {
    let rules = ExperienceLevel.intermediate.complexityRules

    XCTAssertEqual(rules.maxComplexity, 3)
    XCTAssertEqual(rules.maxComplexity4PerSession, 0)
    XCTAssertFalse(rules.complexity4MustBeFirst)
}

// Test advanced complexity rules
func testAdvancedComplexityRules() {
    let rules = ExperienceLevel.advanced.complexityRules

    XCTAssertEqual(rules.maxComplexity, 4)
    XCTAssertEqual(rules.maxComplexity4PerSession, 1)
    XCTAssertTrue(rules.complexity4MustBeFirst)
}
```

---

## 5. Goal and Priority Muscle Tests

### 5.1 Goal Selection Tests
**Purpose**: Test fitness goal selection and validation

```swift
// Test valid goal combinations
func testValidGoalCombinations() {
    let goalValidator = GoalValidator()

    // Single goals should be valid
    XCTAssertTrue(goalValidator.isValidCombination(["Get Stronger"]))
    XCTAssertTrue(goalValidator.isValidCombination(["Increase Muscle"]))
    XCTAssertTrue(goalValidator.isValidCombination(["Fat Loss"]))

    // Multiple goals should be valid
    XCTAssertTrue(goalValidator.isValidCombination(["Get Stronger", "Increase Muscle"]))
    XCTAssertTrue(goalValidator.isValidCombination(["Increase Muscle", "Fat Loss"]))
    XCTAssertTrue(goalValidator.isValidCombination(["Get Stronger", "Fat Loss"]))

    // All goals should be valid
    XCTAssertTrue(goalValidator.isValidCombination(["Get Stronger", "Increase Muscle", "Fat Loss"]))

    // Empty selection should be invalid
    XCTAssertFalse(goalValidator.isValidCombination([]))
}

// Test goal affects rep range selection
func testGoalAffectsRepRanges() {
    let strengthProfile = createMockUserProfile(goals: ["Get Stronger"])
    let hypertrophyProfile = createMockUserProfile(goals: ["Increase Muscle"])
    let fatLossProfile = createMockUserProfile(goals: ["Fat Loss"])

    let programGenerator = ProgramGenerator()

    let strengthProgram = programGenerator.generateProgram(for: strengthProfile)
    let hypertrophyProgram = programGenerator.generateProgram(for: hypertrophyProfile)
    let fatLossProgram = programGenerator.generateProgram(for: fatLossProfile)

    // Check rep ranges are appropriate for goals
    for session in strengthProgram.sessions {
        for exercise in session.exercises {
            if exercise.canonicalRating > 75 {
                XCTAssert(exercise.repRangeMin >= 5 && exercise.repRangeMax <= 10,
                         "Strength goal should get 5-10 rep range for high-rated exercises")
            }
        }
    }

    for session in hypertrophyProgram.sessions {
        for exercise in session.exercises {
            XCTAssert(exercise.repRangeMin >= 6 && exercise.repRangeMax <= 12,
                     "Hypertrophy goal should get 6-12 rep range")
        }
    }

    for session in fatLossProgram.sessions {
        for exercise in session.exercises {
            XCTAssert(exercise.repRangeMin >= 8 && exercise.repRangeMax <= 14,
                     "Fat loss goal should get 8-14 rep range")
        }
    }
}
```

### 5.2 Priority Muscle Selection Tests
**Purpose**: Test priority muscle selection and validation

```swift
// Test priority muscle selection affects programme
func testPriorityMuscleAffectsProgramme() {
    let profileWithChestPriority = createMockUserProfile(
        split: "Push/Pull/Legs",
        priorityMuscles: ["Chest"]
    )

    let profileWithoutPriority = createMockUserProfile(
        split: "Push/Pull/Legs",
        priorityMuscles: []
    )

    let programGenerator = ProgramGenerator()

    let programWithPriority = programGenerator.generateProgram(for: profileWithChestPriority)
    let programWithoutPriority = programGenerator.generateProgram(for: profileWithoutPriority)

    // Find push sessions
    let pushSessionWithPriority = programWithPriority.sessions.first { $0.name == "Push" }!
    let pushSessionWithoutPriority = programWithoutPriority.sessions.first { $0.name == "Push" }!

    let chestExercisesWithPriority = pushSessionWithPriority.exercises.filter { $0.primaryMuscle == "Chest" }
    let chestExercisesWithoutPriority = pushSessionWithoutPriority.exercises.filter { $0.primaryMuscle == "Chest" }

    // Should have more chest exercises when chest is priority
    XCTAssertGreaterThan(chestExercisesWithPriority.count, chestExercisesWithoutPriority.count)
}

// Test priority muscle validation
func testPriorityMuscleValidation() {
    let muscleValidator = PriorityMuscleValidator()

    // Should allow valid muscle groups
    XCTAssertTrue(muscleValidator.isValidMuscle("Chest"))
    XCTAssertTrue(muscleValidator.isValidMuscle("Back"))
    XCTAssertTrue(muscleValidator.isValidMuscle("Legs"))

    // Should reject invalid muscle groups
    XCTAssertFalse(muscleValidator.isValidMuscle("Invalid Muscle"))
    XCTAssertFalse(muscleValidator.isValidMuscle(""))

    // Should allow reasonable number of priorities
    XCTAssertTrue(muscleValidator.isValidSelection(["Chest"]))
    XCTAssertTrue(muscleValidator.isValidSelection(["Chest", "Back", "Legs"]))
    XCTAssertFalse(muscleValidator.isValidSelection(Array(repeating: "Chest", count: 10)))
}
```

---

## 6. Integration Tests

### 6.1 End-to-End Questionnaire Tests
**Purpose**: Test complete questionnaire to programme generation flow

```swift
// Test complete questionnaire flow
func testCompleteQuestionnaireFlow() {
    let questionnaire = QuestionnaireController()

    // Complete part 1
    questionnaire.answerStep("TrainingDays", answer: "3")
    questionnaire.answerStep("SessionDuration", answer: "60")
    questionnaire.answerStep("Equipment", answer: ["dumbbells", "barbells"])
    questionnaire.answerStep("Experience", answer: "intermediate")
    questionnaire.answerStep("Goals", answer: ["Increase Muscle"])
    questionnaire.answerStep("PriorityMuscles", answer: ["Chest"])
    questionnaire.answerStep("Injuries", answer: [])

    // Should trigger split selection
    XCTAssertTrue(questionnaire.shouldShowSplitSelection)

    let availableSplits = questionnaire.getAvailableSplits()
    XCTAssertTrue(availableSplits.contains { $0.name == "Push Pull Legs" })

    questionnaire.answerStep("SplitSelection", answer: "Push Pull Legs")

    // Complete part 2
    questionnaire.answerStep("Age", answer: "25")
    questionnaire.answerStep("Weight", answer: "70")
    questionnaire.answerStep("Height", answer: "175")
    questionnaire.answerStep("Gender", answer: "male")

    // Should be complete
    XCTAssertTrue(questionnaire.isComplete)

    // Should generate valid user profile
    let userProfile = questionnaire.generateUserProfile()
    XCTAssertNotNil(userProfile)
    XCTAssertEqual(userProfile.trainingDaysPerWeek, 3)
    XCTAssertEqual(userProfile.selectedSplit, "Push Pull Legs")
    XCTAssertTrue(userProfile.priorityMuscleGroups.contains("Chest"))
}

// Test programme generation from questionnaire
func testProgrammeGenerationFromQuestionnaire() {
    let userProfile = createCompleteUserProfile()
    let programGenerator = ProgramGenerator()

    let programme = programGenerator.generateProgram(for: userProfile)

    XCTAssertEqual(programme.sessions.count, 3)
    XCTAssertTrue(programme.sessions.allSatisfy { !$0.exercises.isEmpty })

    // Should respect user constraints
    for session in programme.sessions {
        for exercise in session.exercises {
            // Should only use available equipment
            XCTAssert(userProfile.availableEquipment.contains(exercise.equipmentCategory) ||
                     exercise.equipmentCategory == "Other")

            // Should respect experience level
            XCTAssert(exercise.complexityLevel == "all" ||
                     exercise.numericComplexity <= userProfile.experienceLevel.complexityRules.maxComplexity)
        }
    }
}
```

### 6.2 Data Persistence Integration Tests
**Purpose**: Test questionnaire data persistence and retrieval

```swift
// Test questionnaire data saves to user profile
func testQuestionnaireDataPersistence() {
    let questionnaire = QuestionnaireController()

    // Complete questionnaire
    completeFullQuestionnaire(questionnaire)

    // Generate and save user profile
    let userProfile = questionnaire.generateUserProfile()
    UserProfileManager.saveProfile(userProfile)

    // Should be able to retrieve saved profile
    let retrievedProfile = UserProfileManager.loadProfile()

    XCTAssertNotNil(retrievedProfile)
    XCTAssertEqual(retrievedProfile?.trainingDaysPerWeek, userProfile.trainingDaysPerWeek)
    XCTAssertEqual(retrievedProfile?.selectedSplit, userProfile.selectedSplit)
    XCTAssertEqual(retrievedProfile?.experienceLevel, userProfile.experienceLevel)
}

// Test questionnaire can be retaken
func testQuestionnaireRetake() {
    // Create initial profile
    let initialProfile = createCompleteUserProfile(
        trainingDays: 3,
        split: "Push Pull Legs"
    )
    UserProfileManager.saveProfile(initialProfile)

    // Retake questionnaire with different answers
    let questionnaire = QuestionnaireController()
    questionnaire.answerStep("TrainingDays", answer: "5")
    questionnaire.answerStep("SplitSelection", answer: "PPL Upper Lower")

    let newProfile = questionnaire.generateUserProfile()
    UserProfileManager.saveProfile(newProfile)

    // Should replace old profile
    let currentProfile = UserProfileManager.loadProfile()
    XCTAssertEqual(currentProfile?.trainingDaysPerWeek, 5)
    XCTAssertEqual(currentProfile?.selectedSplit, "PPL Upper Lower")
}
```

---

## Helper Functions

### Mock Data Creation

```swift
// Create complete user profile for testing
func createCompleteUserProfile(
    trainingDays: Int = 3,
    sessionDuration: Int = 60,
    equipment: [String] = ["Dumbbells", "Barbells"],
    experienceLevel: ExperienceLevel = .intermediate,
    goals: [String] = ["Increase Muscle"],
    priorityMuscles: [String] = ["Chest"],
    split: String = "Push Pull Legs",
    age: Int = 25,
    weight: Double = 70.0,
    height: Double = 175.0,
    gender: String = "male"
) -> UserProfile {
    return UserProfile(
        trainingDaysPerWeek: trainingDays,
        sessionDurationMinutes: sessionDuration,
        availableEquipment: equipment,
        experienceLevel: experienceLevel,
        fitnessGoals: goals,
        priorityMuscleGroups: priorityMuscles,
        injuryHistory: [],
        selectedSplit: split,
        age: age,
        weight: weight,
        height: height,
        gender: gender
    )
}

// Complete full questionnaire with default answers
func completeFullQuestionnaire(_ questionnaire: QuestionnaireController) {
    questionnaire.answerStep("TrainingDays", answer: "3")
    questionnaire.answerStep("SessionDuration", answer: "60")
    questionnaire.answerStep("Equipment", answer: ["dumbbells", "barbells"])
    questionnaire.answerStep("Experience", answer: "intermediate")
    questionnaire.answerStep("Goals", answer: ["Increase Muscle"])
    questionnaire.answerStep("PriorityMuscles", answer: ["Chest"])
    questionnaire.answerStep("Injuries", answer: [])
    questionnaire.answerStep("SplitSelection", answer: "Push Pull Legs")
    questionnaire.answerStep("Age", answer: "25")
    questionnaire.answerStep("Weight", answer: "70")
    questionnaire.answerStep("Height", answer: "175")
    questionnaire.answerStep("Gender", answer: "male")
}
```

### Validation Helpers

```swift
// Validate split recommendations
func validateSplitRecommendations(
    _ recommendations: [SplitRecommendation],
    expectedRecommended: String,
    totalCount: Int
) {
    XCTAssertEqual(recommendations.count, totalCount)

    let recommended = recommendations.filter { $0.isRecommended }
    XCTAssertEqual(recommended.count, 1)
    XCTAssertEqual(recommended.first?.name, expectedRecommended)

    // Recommended should be first
    XCTAssertTrue(recommendations.first?.isRecommended == true)
}

// Validate user profile completeness
func validateUserProfileCompleteness(_ profile: UserProfile) {
    XCTAssertGreaterThan(profile.trainingDaysPerWeek, 0)
    XCTAssertGreaterThan(profile.sessionDurationMinutes, 0)
    XCTAssertFalse(profile.availableEquipment.isEmpty)
    XCTAssertFalse(profile.fitnessGoals.isEmpty)
    XCTAssertFalse(profile.selectedSplit.isEmpty)
    XCTAssertGreaterThan(profile.age, 0)
    XCTAssertGreaterThan(profile.weight, 0)
    XCTAssertGreaterThan(profile.height, 0)
    XCTAssertFalse(profile.gender.isEmpty)
}
```

---

## Performance Tests

### Questionnaire Performance Benchmarks

```swift
// Test questionnaire loads quickly
func testQuestionnaireLoadPerformance() {
    measure {
        let questionnaire = QuestionnaireController()
        _ = questionnaire.currentStepView
    }
    // Should load within 0.1 seconds
}

// Test split recommendation calculation performance
func testSplitRecommendationPerformance() {
    let userProfile = createCompleteUserProfile()

    measure {
        let splitSelector = SplitSelector()
        _ = splitSelector.getRecommendedSplits(for: userProfile)
    }
    // Should calculate within 0.05 seconds
}

// Test programme generation performance
func testProgrammeGenerationPerformance() {
    let userProfile = createCompleteUserProfile()

    measure {
        let programGenerator = ProgramGenerator()
        _ = programGenerator.generateProgram(for: userProfile)
    }
    // Should generate within 1 second
}
```

---

**Document Version**: 1.0
**Created**: January 10, 2026
**Author**: Claude Code
**Applies to**: trAIn iOS Questionnaire and Split Selection System