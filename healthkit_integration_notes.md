# HealthKit Integration Setup

## Required Changes for Project

### 1. Add HealthKit Capability
- In Xcode project settings, add HealthKit capability
- This will automatically add HealthKit.framework

### 2. Info.plist Permissions
Add the following keys to Info.plist (or project settings):

```xml
<key>NSHealthUpdateUsageDescription</key>
<string>trAIn needs permission to save your workout data to Apple Health for better calorie tracking and progress monitoring.</string>
<key>NSHealthShareUsageDescription</key>
<string>trAIn would like to access your health data to automatically fill in your body stats and provide personalized workout recommendations.</string>
```

### 3. Implementation Details

#### Files Created:
- `HealthKitManager.swift` - Handles all HealthKit operations
- `HealthProfileStepView.swift` - Combined Apple Health + manual entry screen
- `HeightWeightStepView.swift` - Conditional height/weight input

#### Changes Made:
- `QuestionnaireData.swift` - Added health sync tracking properties
- `QuestionnaireView.swift` - Updated flow to support conditional steps

#### Flow Logic:
1. User sees combined health profile screen with Apple Health option
2. If Apple Health sync succeeds and has height/weight data → skip height/weight screen
3. If Apple Health sync fails or no height/weight data → show height/weight screen
4. Progress tracking adapts: 12 steps (if skipped) or 13 steps (if not skipped)

#### Calorie Syncing:
- Workout sessions saved as `HKWorkout` with `traditionalStrengthTraining` type
- Calories burned calculated and synced to Apple Health
- Can read user's baseline activity data for better calorie calculations

### 4. Test Cases
- HealthKit not available (older devices) → fallback to manual entry
- HealthKit permission denied → fallback to manual entry
- HealthKit permission granted but no data → show manual height/weight
- HealthKit permission granted with full data → skip height/weight step
- Progress bar shows correct step count (12 or 13)
- Back navigation works correctly with dynamic steps