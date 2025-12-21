# trAIn iOS App - Update Report
## December 9, 2025

This document summarizes all 17 tasks implemented from the updates_20251209.xlsx specification.

---

## Task 1: Fix 1-Day/6-Day Slider Validation
**File:** `trAInSwift/Views/QuestionnaireView.swift`

**Change:** Updated the training days validation to allow 1-6 days instead of the previous 2-5 day restriction.

```swift
// Before
case 5: return viewModel.questionnaireData.trainingDaysPerWeek >= 2

// After
case 5: return viewModel.questionnaireData.trainingDaysPerWeek >= 1 && viewModel.questionnaireData.trainingDaysPerWeek <= 6
```

---

## Task 2: Add 1-Day and 6-Day Programme Templates
**File:** `trAInSwift/Services/DynamicProgramGenerator.swift`

**Changes:**
- Added `get1DayTemplates()` method for full-body single-day workouts
- Added `get6DayTemplates()` method for Push/Pull/Legs twice per week
- Updated `determineSplitType()` to handle 1 and 6 day selections
- Updated `getSessionTemplates()` to route to new template methods

**1-Day Template:** Full Body session targeting all major muscle groups
**6-Day Template:** Push/Pull/Legs split repeated twice (Push A, Pull A, Legs A, Push B, Pull B, Legs B)

---

## Task 3: Update Exercise Selection Algorithm
**File:** `trAInSwift/Services/DynamicProgramGenerator.swift`

**Change:** Exercise selection algorithm updated as part of Task 2 to support the new 1-day and 6-day templates with appropriate exercise counts and muscle group targeting.

---

## Task 4: Programme Generation Logic Review
**Status:** Investigated - no issues found

The programme generation logic was reviewed and found to be functioning correctly with the new templates.

---

## Task 5: Replace Metal Shader Tab Bars with Native iOS Segmented Pickers
**Files Modified:**
- `trAInSwift/Components/FloatingToolbar.swift`
- `trAInSwift/Views/ExerciseLoggerView.swift`
- `trAInSwift/Views/CombinedLibraryView.swift`

**Files Deleted:**
- `trAInSwift/Components/Shaders/GlassLens.metal`
- `trAInSwift/Components/GlassTabBar.swift`

**Change:** Replaced custom Metal shader-based glass tab bars with native SwiftUI `Picker` using `.pickerStyle(.segmented)` for better performance and iOS compatibility.

---

## Task 6: Fix Equipment Card Click Area
**File:** `trAInSwift/Views/QuestionnaireSteps.swift`

**Change:** Made entire equipment card clickable instead of just the text/icon area by adding `.contentShape(Rectangle()).onTapGesture { onToggleCategory() }` to the card container.

---

## Task 7: Default All Equipment to Selected
**File:** `trAInSwift/Models/QuestionnaireData.swift`

**Change:** Updated default values for `equipmentAvailable` and `detailedEquipment` to include all equipment options pre-selected:

```swift
var equipmentAvailable: [String] = [
    "barbells", "dumbbells", "kettlebells", "cable_machines", "pin_loaded", "plate_loaded", "other"
]
var detailedEquipment: [String: Set<String>] = [
    "barbells": ["Squat Rack", "Flat Bench Press", ...],
    "cable_machines": ["Single Adjustable Cable Machine", ...],
    // ... all items pre-selected
]
```

---

## Task 8: Add Split Suggestions for Training Days
**File:** `trAInSwift/Views/QuestionnaireSteps.swift` (TrainingDaysStepView)

**Change:** Added informational text showing recommended split type based on selected training days:
- 1-2 days: Full Body
- 3 days: Full Body or Push/Pull/Legs
- 4 days: Upper/Lower
- 5-6 days: Push/Pull/Legs

---

## Task 9: Triceps/Trapezius Only Selectable on Back View
**File:** `trAInSwift/Components/MuscleSelector/MuscleSelector.swift`

**Change:** Added `isSelectableOnSide()` function to both `MuscleSelector` and `CompactMuscleSelector` to prevent triceps and trapezius from being selectable on the front view while keeping their visual appearance intact.

```swift
private func isSelectableOnSide(_ slug: MuscleSlug, side: MuscleSelector.BodySide) -> Bool {
    if side == .front && (slug == .triceps || slug == .trapezius) {
        return false
    }
    return true
}
```

---

## Task 10: Stack Front/Back Body Views Side by Side
**File:** `trAInSwift/Components/MuscleSelector/MuscleSelector.swift`

**Change:** Rewrote `CompactMuscleSelector` to display front and back body diagrams side by side instead of using a toggle. Users can now see both views simultaneously for easier muscle selection.

---

## Task 11: Combine Subtitle and Selection Note in Muscle Groups Step
**File:** `trAInSwift/Views/QuestionnaireSteps.swift` (MuscleGroupsStepView)

**Change:** Combined the subtitle text and selection instruction into a single, cleaner UI element.

---

## Task 12: Remove Default for Session Duration
**File:** `trAInSwift/Models/QuestionnaireData.swift`

**Change:** Removed the default value for session duration to force users to make an explicit selection:

```swift
// Before
var sessionDuration: String = "45-60 min"

// After
var sessionDuration: String = ""
```

---

## Task 13: Fix Continue Button Alignment
**File:** `trAInSwift/Views/QuestionnaireView.swift`

**Change:** Fixed the continue button padding to prevent horizontal overflow:

```swift
// Before
.padding(16)

// After
.padding(.horizontal, 16)
.padding(.bottom, 16)
```

---

## Task 14: Add Terms and Conditions Popup
**File:** `trAInSwift/Views/PostQuestionnaireSignupView.swift`

**Changes:**
- Made "Terms and Conditions" text tappable with underline styling
- Added `@State private var showTermsAndConditions: Bool = false`
- Created `TermsAndConditionsSheet` view with 12 standard legal sections:
  1. Acceptance of Terms
  2. Description of Service
  3. User Accounts
  4. Health and Safety Disclaimer
  5. User Content
  6. Prohibited Conduct
  7. Intellectual Property
  8. Subscription and Payments
  9. Termination
  10. Limitation of Liability
  11. Changes to Terms
  12. Contact

---

## Task 15: Implement Edit Profile Functionality
**File:** `trAInSwift/Views/ProfileView.swift`

**Changes:**
- Added `EditProfileView` with editable name field and read-only email display
- Connected "Edit Profile" menu item to show the edit sheet
- Updated profile header to display user's name (with email below if name exists)
- Added save/cancel functionality with change detection

---

## Task 16: Revert Injuries to Muscles and Update Contraindications DB
**Files Modified:**
- `trAInSwift/Views/QuestionnaireSteps.swift` (InjuriesStepView)
- `trAInSwift/Models/DatabaseModels.swift` (InjuryType enum)
- `trAInSwift/Resources/exercises.db` (exercise_contraindications table)

**Changes:**
- Changed injury options from body parts (Ankles, Knees, etc.) to muscle groups (Chest, Back, Shoulders, Triceps, Biceps, Quads, Hamstrings, Glutes, Calves, Core)
- Updated `InjuryType` enum to match new muscle-based system
- Regenerated `exercise_contraindications` table to map canonical exercise names to their primary muscle groups

**New Injury Options:**
```swift
let injuryOptions = [
    ["Chest", "Back"],
    ["Shoulders", "Triceps"],
    ["Biceps", "Quads"],
    ["Hamstrings", "Glutes"],
    ["Calves", "Core"]
]
```

---

## Task 17: Fix Equipment Filtering in Exercise Library
**File:** `trAInSwift/Views/CombinedLibraryView.swift`

**Changes:**
- Updated `muscleGroups` array to include all available muscle groups from database
- Updated `equipmentTypes` array to match actual database `equipment_category` values

```swift
// Before
let muscleGroups = ["Chest", "Back", "Shoulders", "Arms", "Legs", "Core"]
let equipmentTypes = ["Barbell", "Dumbbell", "Cable", "Machine", "Kettlebell", "Bodyweight"]

// After
let muscleGroups = ["Chest", "Back", "Shoulders", "Biceps", "Triceps", "Quads", "Hamstrings", "Glutes", "Calves", "Core"]
let equipmentTypes = ["Barbells", "Dumbbells", "Cables", "Kettlebells", "Pin-Loaded Machines", "Plate-Loaded Machines", "Other"]
```

---

## Summary

| Task | Description | Status |
|------|-------------|--------|
| 1 | Fix 1-day/6-day slider validation | Complete |
| 2 | Add 1-day and 6-day programme templates | Complete |
| 3 | Update exercise selection algorithm | Complete |
| 4 | Programme generation logic review | Complete |
| 5 | Replace Metal shaders with native pickers | Complete |
| 6 | Fix equipment card click area | Complete |
| 7 | Default all equipment to selected | Complete |
| 8 | Add split suggestions | Complete |
| 9 | Triceps/trapezius back-view only selection | Complete |
| 10 | Stack front/back body views side by side | Complete |
| 11 | Combine subtitle and selection note | Complete |
| 12 | Remove session duration default | Complete |
| 13 | Fix continue button alignment | Complete |
| 14 | Add Terms and Conditions popup | Complete |
| 15 | Implement Edit Profile functionality | Complete |
| 16 | Revert injuries to muscles | Complete |
| 17 | Fix equipment filtering | Complete |

**All 17 tasks completed successfully.**
