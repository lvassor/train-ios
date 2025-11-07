# Exercise Database Integration Guide

## Overview

This document explains the SQLite database integration for dynamic workout program generation in the trAInSwift app.

## Architecture

### Data Layer
- **DatabaseModels.swift** - GRDB models matching SQLite schema
- **ExerciseDatabaseManager.swift** - Low-level database operations
- **ExerciseRepository.swift** - High-level business logic layer

### Business Logic
- **DynamicProgramGenerator.swift** - Dynamic program generation with business rules
- **ProgramGenerator.swift** - Main entry point with fallback to hardcoded programs

### Database Location
- **Bundled**: `trAInSwift/Resources/exercises.db` (read-only)
- **Runtime**: `~/Documents/exercises.db` (copied on first launch)

## Database Schema

### exercises
| Column | Type | Description |
|--------|------|-------------|
| exercise_id | INTEGER | Primary key |
| canonical_name | TEXT | Base exercise name (e.g., "Back Squat") |
| display_name | TEXT | User-facing name (e.g., "Barbell Back Squat") |
| movement_pattern | TEXT | Squat, Hinge, Horizontal Push, etc. |
| equipment_type | TEXT | Barbell, Dumbbell, Cable, Machine, Kettlebell, Bodyweight |
| complexity_level | INTEGER | 1-4 (beginner to advanced) |
| primary_muscle | TEXT | Main muscle targeted |
| secondary_muscle | TEXT | Secondary muscle (optional) |
| instructions | TEXT | Exercise instructions (optional) |
| is_active | INTEGER | 1 = active, 0 = disabled |

### exercise_contraindications
| Column | Type | Description |
|--------|------|-------------|
| id | INTEGER | Primary key (auto-increment) |
| exercise_id | INTEGER | Foreign key to exercises |
| injury_type | TEXT | Injury name (e.g., "Knee", "Lower Back") |

### user_experience_complexity
| Column | Type | Description |
|--------|------|-------------|
| experience_level | TEXT | BEGINNER, INTERMEDIATE, ADVANCED (primary key) |
| display_name | TEXT | User-facing name |
| max_complexity | INTEGER | Maximum complexity allowed (2, 3, or 4) |
| max_complexity_4_per_session | INTEGER | Max level-4 exercises per session |
| complexity_4_must_be_first | INTEGER | 1 if level-4 must be first, 0 otherwise |

## Business Rules Implementation

### 1. Experience-Based Complexity Limits
```swift
// BEGINNER: max complexity 2
// INTERMEDIATE: max complexity 3
// ADVANCED: max complexity 4
let complexityRules = try exerciseRepo.getComplexityRules(for: experienceLevel)
```

### 2. Complexity-4 Exercise Rules
- Maximum 1 complexity-4 exercise per session (for ADVANCED only)
- Must be the first exercise in the session
- Implemented in `ExerciseRepository.selectExercises()`

### 3. No Duplicate Exercises Across Program
```swift
var usedExerciseIds = Set<Int>()
// Track and exclude used IDs across all sessions
```

### 4. Exercise Filtering
Exercises are filtered by:
- Movement pattern (e.g., Squat, Hinge)
- User's max complexity level
- Available equipment
- Contraindicated injuries

### 5. Alternative Exercise Lookup
```swift
let alternatives = try exerciseRepo.findAlternatives(
    for: exercise,
    experienceLevel: experienceLevel,
    availableEquipment: equipment,
    userInjuries: injuries,
    excludedExerciseIds: usedIds
)
```

### 6. Rep Ranges by Fitness Goal
Defined in `DynamicProgramGenerator.getRepRangeForGoal()`:
- **Get Strong**: 5-8 reps
- **Build Muscle**: 8-12 reps
- **Tone Up**: 10-15 reps

## Questionnaire Data Mapping

### Experience Level
```swift
ExperienceLevel.fromQuestionnaire(questionnaireData.experienceLevel)
// Maps: "0_months", "0_6_months" → BEGINNER
//       "6_months_2_years" → INTERMEDIATE
//       "2_plus_years" → ADVANCED
```

### Equipment
```swift
ExerciseDatabaseFilter.mapEquipmentFromQuestionnaire(questionnaireData.equipmentAvailable)
// Maps: "bodyweight" → "Bodyweight"
//       "dumbbells" → "Dumbbell"
//       "barbells" → "Barbell"
//       "cable_machines" → "Cable"
//       "pin_loaded", "plate_loaded" → "Machine"
//       "kettlebells" → "Kettlebell"
```

### Split Type Determination
```swift
// 2 days: Upper/Lower or Full Body (based on duration)
// 3 days: Push/Pull/Legs
// 4 days: Upper/Lower (with A/B variants)
// 5+ days: Push/Pull/Legs (with additional upper/lower days)
```

## Installation Steps

### 1. Install GRDB via Swift Package Manager

In Xcode:
1. Go to **File > Add Package Dependencies...**
2. Enter URL: `https://github.com/groue/GRDB.swift`
3. Select version: **Up to Next Major Version** (6.0.0+)
4. Click **Add Package**

### 2. Add Database to Xcode Project

1. In Xcode, right-click on the `trAInSwift` folder
2. Select **Add Files to "trAInSwift"...**
3. Navigate to `trAInSwift/Resources/exercises.db`
4. **Check** "Copy items if needed"
5. **Check** your app target
6. Click **Add**

### 3. Verify File Structure

```
trAInSwift/
├── Resources/
│   └── exercises.db          ← Added to Xcode project
├── Models/
│   ├── DatabaseModels.swift  ← New file
│   └── ...
├── Services/
│   ├── ExerciseDatabaseManager.swift      ← New file
│   ├── ExerciseRepository.swift           ← New file
│   ├── DynamicProgramGenerator.swift      ← New file
│   ├── ProgramGenerator.swift             ← Modified
│   └── ...
└── ...

database-management/          ← Outside Xcode project
├── README.md
├── create_database.py
├── exercises_new_schema.csv
├── exercise_contraindications.csv
├── user_experience_complexity.csv
└── exercises.db
```

## Usage Example

```swift
let questionnaireData = QuestionnaireData(
    experienceLevel: "6_months_2_years",  // INTERMEDIATE
    primaryGoal: "build_muscle",           // 8-12 rep range
    equipmentAvailable: ["barbells", "dumbbells", "cable_machines"],
    trainingDaysPerWeek: 3,                // Push/Pull/Legs
    sessionDuration: "45-60 min",
    injuries: ["Knee"]                     // Exclude knee-contraindicated exercises
)

let generator = ProgramGenerator()
let program = generator.generateProgram(from: questionnaireData)

// Program now contains:
// - Personalized exercises from database
// - Filtered by equipment and injuries
// - No exercises repeating across sessions
// - Proper complexity for intermediate level
// - 8-12 rep ranges (build muscle goal)
```

## Error Handling & Fallback

The system includes robust error handling:

1. **Primary**: Dynamic database-driven generation
2. **Fallback**: Hardcoded programs (if database fails)
3. **Logging**: Detailed console output for debugging

```swift
do {
    let program = try dynamicGenerator.generateProgram(from: questionnaireData)
    // Use dynamic program
} catch {
    print("⚠️ Falling back to hardcoded program")
    let program = HardcodedPrograms.getProgram(days: 3, duration: "45-60 min")
    // Use fallback program
}
```

## Updating Exercise Data

See [`database-management/README.md`](database-management/README.md) for instructions on:
- Editing CSV files
- Regenerating the database
- Copying updated database to Xcode

## Testing

### Manual Testing Checklist

- [ ] Database loads on first launch
- [ ] Database copied to Documents directory
- [ ] Exercises filtered by experience level
- [ ] Complexity-4 exercises placed first (ADVANCED only)
- [ ] No duplicate exercises across sessions
- [ ] Exercises filtered by available equipment
- [ ] Contraindicated exercises excluded
- [ ] Correct rep ranges based on fitness goal
- [ ] Fallback works if database is missing/corrupted

### Database Verification Queries

```swift
// Check total exercises
let count = try dbManager.fetchExercises(filter: ExerciseDatabaseFilter()).count

// Check available movement patterns
let patterns = try exerciseRepo.getAvailableMovementPatterns()

// Check complexity distribution
let exercises = try dbManager.fetchExercises(filter: ExerciseDatabaseFilter())
let complexity4Count = exercises.filter { $0.complexityLevel == 4 }.count
```

## Performance Considerations

- **Database Size**: ~60KB (100 exercises)
- **First Launch**: Database copied once (~10ms)
- **Query Performance**: Indexed queries (<1ms per query)
- **Memory Usage**: Minimal (queries use fetchAll, not in-memory caching)

## Future Enhancements

1. **Progressive Overload**: Track weight/reps over time
2. **Exercise Variations**: Rotate exercises every 4-8 weeks
3. **Deload Weeks**: Reduce volume periodically
4. **Exercise Videos**: Add video URLs to database
5. **Custom Exercises**: Allow users to add custom exercises
6. **Exercise History**: Track which exercises user has performed
7. **Smart Substitutions**: Suggest alternatives if equipment unavailable

## Troubleshooting

### Database Not Found
```
❌ exercises.db not found in app bundle
```
**Solution**: Ensure `exercises.db` is added to Xcode project with "Copy items if needed" checked.

### Empty Database
```
❌ Database is empty or corrupted
```
**Solution**: Regenerate database using `python3 create_database.py` and re-add to Xcode.

### GRDB Not Found
```
❌ No such module 'GRDB'
```
**Solution**: Add GRDB package via Swift Package Manager.

### No Exercises Match Criteria
```
⚠️ No exercises found matching filter
```
**Solution**: Check that equipment types and injury filters aren't too restrictive.

## Questions or Issues?

If you encounter any issues with the database integration:

1. Check console logs for detailed error messages
2. Verify database exists at bundle path
3. Ensure GRDB package is installed correctly
4. Test with hardcoded fallback programs first
5. Review questionnaire data mapping

## Summary

The database integration provides:
- ✅ Dynamic, personalized workout programs
- ✅ Respects user constraints (equipment, injuries, experience)
- ✅ Applies all business rules (complexity-4, no duplicates, etc.)
- ✅ Proper separation of concerns (data, business logic, views)
- ✅ Robust error handling with fallback
- ✅ Easy exercise data management via CSV + Python script
