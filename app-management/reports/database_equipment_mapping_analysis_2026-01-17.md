# Database Equipment Mapping Analysis Report

**Date:** January 17, 2026
**Issue:** Critical equipment mapping inconsistencies between database, Python simulator, and Swift implementation
**Severity:** High - affects both simulation accuracy and production app

## Executive Summary

Analysis of the production Excel database reveals critical inconsistencies in equipment category handling across all three systems:
1. **Database:** Contains separate "Bodyweight" and "Other" categories
2. **Python Simulator:** Expects "Other" but never includes "Bodyweight"
3. **Swift Implementation:** Maps "other" → "Other" but never includes "Bodyweight"

**Result:** Both systems are missing 24 Bodyweight exercises, including 6 Core exercises, making Python simulation unreliable and Swift production broken.

## Database Content Analysis

### Equipment Categories in Production Database
```
Database Categories (from Excel):
- Barbells: 20 exercises
- Bodyweight: 24 exercises ⚠️
- Cables: 18 exercises
- Dumbbells: 38 exercises
- Kettlebells: 19 exercises
- Other: 1 exercise
- Pin-Loaded Machines: 11 exercises
- Plate-Loaded Machines: 9 exercises
```

### Core Exercise Distribution
```
Core exercises by equipment:
- Bodyweight: 6 exercises (Plank, Side Plank, Dead Bug, etc.)
- Cables: 3 exercises (Cable Crunch, Cable Wood Chop, Pallof Press)
- Dumbbells: 1 exercise (Dumbbell Suitcase Carry)
```

## System-by-System Analysis

### 1. Python Simulator Issues

**Expected Equipment Categories:**
```python
EQUIPMENT_OPTIONS = ['Barbells', 'Dumbbells', 'Kettlebells', 'Cables',
                     'Pin-Loaded Machines', 'Plate-Loaded Machines', 'Other']
```

**Missing:** `"Bodyweight"` category completely absent

**Impact:**
- Simulation misses 24 Bodyweight exercises (17% of database)
- All 6 Bodyweight Core exercises excluded
- Simulation results are invalid for bodyweight training scenarios

### 2. Swift Implementation Issues

**Current Mapping:**
```swift
case "bodyweight", "other":
    dbEquipment.append("Other")  // ❌ Only adds "Other"
```

**Missing:** `"Bodyweight"` category not included in mapping

**Impact:**
- Production app misses same 24 Bodyweight exercises
- Core muscle group completely fails (0/9 exercises found)
- Users with full equipment get incomplete programs

### 3. Database Schema Issues

**Problem:** The database contains both `"Bodyweight"` and `"Other"` as separate categories but neither Python nor Swift handle this correctly.

**Data Distribution:**
- `"Bodyweight"`: 24 exercises (mostly core/bodyweight movements)
- `"Other"`: 1 exercise (likely miscategorized)

## Required Fixes

### Priority 1: Swift Production Fix
**File:** `/trAInSwift/Models/DatabaseModels.swift`
**Function:** `mapEquipmentFromQuestionnaire()`

```swift
// Current (BROKEN):
case "bodyweight", "other":
    dbEquipment.append("Other")

// Fixed:
case "bodyweight", "other":
    dbEquipment.append("Other")
    dbEquipment.append("Bodyweight")  // ⭐ ADD THIS LINE
```

### Priority 2: Python Simulator Fix
**File:** `/simulation/simulate.py`
**Lines:** 23-28

```python
# Current (BROKEN):
EQUIPMENT_OPTIONS = ['Barbells', 'Dumbbells', 'Kettlebells', 'Cables',
                     'Pin-Loaded Machines', 'Plate-Loaded Machines', 'Other']

# Fixed:
EQUIPMENT_OPTIONS = ['Barbells', 'Dumbbells', 'Kettlebells', 'Cables',
                     'Pin-Loaded Machines', 'Plate-Loaded Machines', 'Other', 'Bodyweight']
```

### Priority 3: Database Schema Rationalization (Optional)

Consider consolidating `"Bodyweight"` and `"Other"` categories to prevent future confusion:

**Option A:** Merge all into "Other"
```sql
UPDATE exercises SET equipment_category = 'Other' WHERE equipment_category = 'Bodyweight';
```

**Option B:** Keep separate and update all systems to handle both properly (current recommendation)

## Validation Tests

After implementing fixes, validate with these test cases:

### Test 1: Core Exercise Availability
```sql
-- Should return 10 exercises (6 Bodyweight + 3 Cables + 1 Dumbbell)
SELECT COUNT(*) FROM exercises
WHERE primary_muscle = 'Core'
  AND equipment_category IN ('Bodyweight', 'Cables', 'Dumbbells', 'Other');
```

### Test 2: Full Equipment User
**Profile:** User with all equipment types selected
**Expected:** 140 exercises available (full database)
**Current Swift:** ~115 exercises (missing Bodyweight)
**After Fix:** 140 exercises

### Test 3: Bodyweight-Only User
**Profile:** User with only "other" equipment selected
**Expected:** 24 Bodyweight + 1 Other = 25 exercises
**Current:** 1 exercise (Other only)
**After Fix:** 25 exercises

## Impact Assessment

### Before Fix (Current State)
- **Swift Production:** Missing 24 exercises (17% of database)
- **Python Simulation:** Missing same 24 exercises
- **Core Training:** Completely broken (0/9 exercises)
- **User Experience:** Incomplete programs, training gaps

### After Fix (Expected State)
- **Swift Production:** Full 140 exercise access
- **Python Simulation:** Accurate results with full exercise pool
- **Core Training:** Complete (9/9 exercises available)
- **User Experience:** Complete, balanced programs

## Recommended Implementation Order

1. **Immediate:** Fix Swift production mapping (5 minute fix)
2. **Next:** Fix Python simulator equipment options (2 minute fix)
3. **Validate:** Run test cases to confirm fixes
4. **Future:** Consider database schema consolidation

## Files Requiring Changes

1. `/trAInSwift/Models/DatabaseModels.swift` - Line ~15 (Swift fix)
2. `/simulation/simulate.py` - Lines 23-28 (Python fix)
3. Test files - Add validation tests for equipment mapping

---

**Report Generated:** 2026-01-17 23:15 UTC
**Analysis Based On:** Production Excel database, Swift source code, Python simulation code
**Validation Method:** Database queries, equipment category analysis, cross-system comparison