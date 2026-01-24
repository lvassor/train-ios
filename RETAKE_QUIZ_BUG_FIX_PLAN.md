# Retake Quiz Bug Fix Plan

## Problem Analysis

### Current Broken Flow
1. User clicks "Retake Quiz" in ProfileView (line 497)
2. `NotificationCenter.resetToSplash` is posted, triggering splash screen
3. `OnboardingFlowView()` is shown in fullScreenCover
4. But user is still authenticated (`authService.isAuthenticated = true`)
5. ContentView redirects back to DashboardView instead of showing questionnaire
6. User must manually log out to access questionnaire again

### Root Causes
1. **ProfileView.swift:497** - Unnecessary splash screen trigger for retake quiz
2. **ProfileView.swift:504** - Shows OnboardingFlowView but user remains authenticated
3. **AppViewModel.swift:73-79** - `retakeQuestionnaire()` completely clears session when it should preserve user
4. **Missing Logic** - No proper program deactivation for retake scenarios

## Detailed Fix Plan

### 1. Fix AppViewModel.swift (Lines 73-79)

**Current Code:**
```swift
func retakeQuestionnaire() {
    questionnaireData = QuestionnaireData()
    // Clear authentication to return to onboarding flow
    authService.clearSession()
    // Trigger splash screen to restart the flow properly
    NotificationCenter.default.post(name: .resetToSplash, object: nil, userInfo: nil)
}
```

**New Implementation:**
```swift
func retakeQuestionnaire() {
    questionnaireData = QuestionnaireData()
    // Clear authentication to return to onboarding flow
    authService.clearSession()
    // Trigger splash screen to restart the flow properly
    NotificationCenter.default.post(name: .resetToSplash, object: nil, userInfo: nil)
}

// NEW METHOD: Retake questionnaire while preserving authentication
func retakeQuestionnaireKeepingAuth() {
    guard let user = authService.currentUser else { return }

    // Deactivate current program (moves it to inactive list)
    authService.deactivateCurrentProgram()

    // Reset questionnaire data for new program generation
    questionnaireData = QuestionnaireData()

    // Keep user authenticated - no session clearing
    // No splash screen trigger needed
}
```

### 2. Fix ProfileView.swift (Lines 492-513)

**Current Code:**
```swift
.confirmationDialog("Retake Quiz", isPresented: $showRetakeConfirmation, titleVisibility: .visible) {
    Button("Retake Quiz") {
        // Navigate to questionnaire while keeping current program as inactive
        shouldRestartQuestionnaire = true
        // Trigger splash screen when retaking questionnaire
        NotificationCenter.default.post(name: .resetToSplash, object: nil, userInfo: nil)
    }
    Button("Cancel", role: .cancel) {}
}
```

**Updated Code:**
```swift
.confirmationDialog("Retake Quiz", isPresented: $showRetakeConfirmation, titleVisibility: .visible) {
    Button("Retake Quiz") {
        // Use new method that preserves authentication and deactivates current program
        AppViewModel().retakeQuestionnaireKeepingAuth()
        shouldRestartQuestionnaire = true
        // NO splash screen trigger needed
    }
    Button("Cancel", role: .cancel) {}
}
```

**Updated fullScreenCover:**
```swift
.fullScreenCover(isPresented: $shouldRestartQuestionnaire) {
    QuestionnaireView(
        isRetakeFlow: true,  // NEW PARAMETER
        onComplete: {
            shouldRestartQuestionnaire = false
            // User stays on dashboard, no additional navigation needed
        },
        onBack: {
            shouldRestartQuestionnaire = false
        }
    )
    .environmentObject(WorkoutViewModel.shared)
    .onAppear {
        print("🔄 [PROFILE] Starting retake questionnaire with preserved authentication")
    }
    .onDisappear {
        shouldRestartQuestionnaire = false
        print("🔄 [PROFILE] Retake questionnaire flow completed")
    }
}
```

### 3. Update QuestionnaireView.swift

**Add new parameter and logic:**
```swift
struct QuestionnaireView: View {
    @ObservedObject var viewModel = WorkoutViewModel.shared

    // NEW: Flag to indicate this is a retake flow (skip account creation)
    var isRetakeFlow: Bool = false

    let onComplete: () -> Void
    var onBack: (() -> Void)? = nil

    // ... existing code ...

    // Update ProgramReadyView to handle retake flow
    if (showingProgramReady || isSignupInProgress), let program = viewModel.generatedProgram {
        ProgramReadyView(
            program: program,
            onStart: {
                viewModel.completeQuestionnaire()

                // NEW: Skip signup flow for retake
                if isRetakeFlow {
                    // Directly complete without showing signup
                    onComplete()
                } else {
                    // Normal flow - show signup process
                    onComplete()
                }
            },
            skipSignup: isRetakeFlow,  // NEW PARAMETER to ProgramReadyView
            selectedMuscleGroups: viewModel.questionnaireData.targetMuscleGroups
        )
    }
}
```

### 4. Enhance AuthService.swift

**Add new method:**
```swift
// MARK: - Program Management for Retake

func deactivateCurrentProgram() {
    guard let currentProgram = getCurrentProgram() else {
        AppLogger.logProgram("No current program to deactivate")
        return
    }

    // Mark current program as inactive
    currentProgram.isActive = false
    currentProgram.deactivatedAt = Date()

    saveSession()
    AppLogger.logProgram("Current program deactivated for retake: \(currentProgram.name ?? "Unknown")")
}

func getInactivePrograms() -> [WorkoutProgram] {
    guard let user = currentUser, let userId = user.id else { return [] }

    // Include recently deactivated programs from retake flow
    let allPrograms = WorkoutProgram.fetchAll(forUserId: userId, context: context)
    return allPrograms.filter { !($0.isActive) }
}
```

### 5. Update ProgramReadyView.swift

**Add skip signup parameter:**
```swift
struct ProgramReadyView: View {
    let program: Program
    let onStart: () -> Void
    var onSignupStart: (() -> Void)? = nil
    var onSignupCancel: (() -> Void)? = nil
    var skipSignup: Bool = false  // NEW PARAMETER
    let selectedMuscleGroups: [String]

    // ... existing code ...

    // Update the start button logic
    private func handleStart() {
        if skipSignup {
            // Retake flow - directly complete
            onStart()
        } else {
            // Normal flow - check if user needs account creation
            if AuthService.shared.isAuthenticated {
                onStart()
            } else {
                onSignupStart?()
            }
        }
    }
}
```

### 6. Test Cases

**Scenario 1: Retake Quiz (Logged In User)**
1. User clicks "Retake Quiz" → Should go directly to questionnaire
2. Complete questionnaire → Should generate new program
3. Click "Start Program" → Should go directly to dashboard (skip signup)
4. Check "Switch Program" → Previous program should be available

**Scenario 2: Program Storage Verification**
1. User has "Push/Pull/Legs" program active
2. Retakes quiz, gets "Upper/Lower Split" program
3. "Switch Program" should show "Push/Pull/Legs" as previous option
4. NOT placeholders like current implementation

**Scenario 3: Logout Flow (Should Still Work)**
1. User clicks "Log Out" → Should clear session and show splash screen
2. Go through welcome → questionnaire → signup flow
3. Previous programs should not be accessible (fresh start)

## Implementation Priority

1. **High Priority**: Fix AppViewModel and ProfileView (core retake logic)
2. **Medium Priority**: Update QuestionnaireView and ProgramReadyView (flow control)
3. **Low Priority**: Enhance AuthService (program management)
4. **Testing**: Verify all scenarios work correctly

## Expected Outcome

- ✅ "Retake Quiz" works without logout requirement
- ✅ Previous programs stored and accessible via "Switch Program"
- ✅ No splash screen during retake flow
- ✅ Authentication preserved throughout retake process
- ✅ Clean separation between retake and logout flows