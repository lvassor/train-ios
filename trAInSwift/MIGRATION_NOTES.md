# Migration from CSV to SQLite Database

## What Changed

### Old System (CSV-based)
- `CSVParser.swift` - Parsed CSV files in Bundle
- `ExerciseDatabaseService.swift` - In-memory exercise database from CSV
- `ExerciseDatabase.csv` - Exercise data in Bundle
- Hardcoded programs in `HardcodedPrograms.swift`

### New System (SQLite-based)
- `ExerciseDatabaseManager.swift` - GRDB database manager
- `ExerciseRepository.swift` - High-level query service
- `DatabaseModels.swift` - GRDB models
- `DynamicProgramGenerator.swift` - Database-driven program generation
- `exercises.db` in `Resources/` - SQLite database
- `database-management/` folder - CSV source files + Python script

## Files to Keep or Remove

### ✅ KEEP (Used by Fallback System)
- `Services/CSVParser.swift` - Used by ExerciseDatabaseService (fallback)
- `Services/ExerciseDatabaseService.swift` - Fallback if SQLite fails
- `Services/HardcodedPrograms.swift` - Ultimate fallback
- `Models/ExerciseDatabase.swift` - Old CSV-based model (used by CSVParser)

**Why?** These provide a fallback if the SQLite database fails to load. The new ProgramGenerator uses try/catch with fallback.

### ❌ REMOVE (If Needed Later)
- Any old `ExerciseDatabase.csv` files in the main project (should be in `database-management/` only)

### ✅ NEW FILES (Core System)
- `Services/ExerciseDatabaseManager.swift` - Primary database manager
- `Services/ExerciseRepository.swift` - Business logic layer
- `Services/DynamicProgramGenerator.swift` - Dynamic program generation
- `Models/DatabaseModels.swift` - SQLite models with GRDB
- `Resources/exercises.db` - SQLite database (added to Xcode)
- `database-management/` - CSV source files (NOT in Xcode project)

## Architecture Decision: Keep Both Systems

**Recommendation: KEEP BOTH SYSTEMS**

The new implementation uses a **layered fallback approach**:

1. **Primary**: SQLite database-driven generation (DynamicProgramGenerator)
2. **Secondary**: CSV-based in-memory database (ExerciseDatabaseService) - Currently not used but available
3. **Tertiary**: Hardcoded programs (HardcodedPrograms)

This provides maximum reliability while you transition to the SQLite system.

## How the Fallback Works

```swift
// ProgramGenerator.swift
do {
    // Try dynamic SQLite-based generation
    let program = try dynamicGenerator.generateProgram(from: questionnaireData)
    return program
} catch {
    print("⚠️ Error generating dynamic program: \(error)")
    print("⚠️ Falling back to hardcoded program...")

    // Fallback to hardcoded programs
    let fallbackProgram = HardcodedPrograms.getProgram(
        days: questionnaireData.trainingDaysPerWeek,
        duration: questionnaireData.sessionDuration
    )
    return fallbackProgram
}
```

## Optional: Remove Old CSV System (After Testing)

Once you've thoroughly tested the SQLite system and confirmed it works reliably, you can optionally remove the old CSV-based system:

### Files to Remove (After Testing)
```bash
# Remove CSV-based exercise system
rm trAInSwift/Services/CSVParser.swift
rm trAInSwift/Services/ExerciseDatabaseService.swift
rm trAInSwift/Models/ExerciseDatabase.swift

# Remove any old CSV files from main project (keep in database-management/)
find trAInSwift -name "ExerciseDatabase.csv" -delete
```

### Update ProgramGenerator Fallback
After removing CSV system, update the fallback to go directly to HardcodedPrograms:

```swift
do {
    let program = try dynamicGenerator.generateProgram(from: questionnaireData)
    return program
} catch {
    // Direct fallback to hardcoded programs (no CSV layer)
    return HardcodedPrograms.getProgram(
        days: questionnaireData.trainingDaysPerWeek,
        duration: questionnaireData.sessionDuration
    )
}
```

## Testing Checklist Before Removing Old System

- [ ] SQLite database loads successfully on first launch
- [ ] Database copied to Documents directory correctly
- [ ] Dynamic program generation works for all split types
- [ ] All business rules correctly implemented
- [ ] Error handling works (test with missing database)
- [ ] App tested on multiple devices/simulators
- [ ] Tested with various questionnaire combinations
- [ ] No crashes or data corruption

## Current Status

**Status: Both systems present, SQLite is primary**

- ✅ SQLite system fully implemented
- ✅ CSV system still present as secondary fallback
- ✅ Hardcoded programs as ultimate fallback
- ⏳ Recommend thorough testing before removing CSV system

## Recommendation

**Keep both systems for now** (at least through initial release). After 2-3 app versions with no SQLite issues reported, you can safely remove the CSV-based system to reduce code complexity.

The added complexity is minimal, and the redundancy provides peace of mind during the transition period.
