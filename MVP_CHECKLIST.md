# trAIn iOS - MVP Launch Checklist

**Target**: Aggressive MVP for user testing
**Status**: 🟡 85% Complete - Need 1.5-2 Days Work
**Architecture**: ✅ Offline-First (Core Data + Keychain) - NO cloud sync for MVP

---

## 🎯 MVP Scope

**What Users Can Do:**
- ✅ Create account (email/password)
- ✅ Complete 10-step questionnaire
- ✅ Get personalized workout program (AI-generated from 500+ exercise database)
- ✅ Log workouts offline (sets, reps, weight)
- ✅ Track progress
- ✅ View program details
- ✅ Browse exercise library

**What's Intentionally NOT in MVP:**
- ❌ Cloud sync (all data local only)
- ❌ Exercise videos (text instructions only)
- ❌ Social features
- ❌ Body measurements
- ❌ Nutrition tracking

---

## 🔴 CRITICAL BLOCKERS (Must Fix - 8-10 hours)

### 1. Rep Counter Query Logic is Broken ⚠️ **BLOCKING** (2-3 hours)
**Problem**: Rep Counter and Progression Prompts try to query by `sessionIndex` which doesn't exist in Core Data schema. This breaks the core value proposition of the app.

**Files**:
- `trAInSwift/Services/AuthService.swift` (lines 254-286)
- `trAInSwift/Views/WorkoutLoggerView.swift` (lines 339-342)

**Business Requirement**:
- Programs never repeat exercises across session types (Bench Press only in Push, not Pull)
- Rep Counter should find **most recent log of specific exercise** across ALL previous sessions
- Handle edge cases:
  - Week 1: No previous data → Hide badge ✅
  - Skipped exercise: No previous data → Hide badge ✅
  - Skipped weeks: Find most recent, however far back ✅
  - Always-skipped exercise: Return nil gracefully ✅

**Example Scenario**:
```
Week 1 Push: Bench Press (10, 9, 8 reps)
Week 2 Push: SKIPPED
Week 3 Push: Bench Press (logging now) → Should compare to Week 1 ✅
```

**Fix Required**:

**Step 1 - Update AuthService.swift (lines 254-262)**:
```swift
// Change function signature - remove sessionIndex parameter
func getPreviousSessionData(
    programId: String,
    exerciseName: String  // Only 2 parameters needed
) -> [LoggedSet]? {
    let fetchRequest: NSFetchRequest<CDWorkoutSession> = CDWorkoutSession.fetchRequest()

    // Query by program and date only (no session type filter)
    fetchRequest.predicate = NSPredicate(
        format: "programId == %@ AND completedAt < %@",
        programId, Date() as CVarArg
    )
    fetchRequest.sortDescriptors = [NSSortDescriptor(key: "completedAt", ascending: false)]

    do {
        let results = try context.fetch(fetchRequest)

        // Iterate through sessions to find first one with this exercise
        for session in results {
            guard let loggedExercisesData = session.loggedExercises,
                  let loggedExercises = try? JSONDecoder().decode([LoggedExercise].self, from: loggedExercisesData) else {
                continue
            }

            if let matchingExercise = loggedExercises.first(where: { $0.exerciseName == exerciseName }) {
                AppLogger.logWorkout("Found previous data for \(exerciseName): \(matchingExercise.sets.count) sets")
                return matchingExercise.sets
            }
        }

        AppLogger.logWorkout("No previous data found for \(exerciseName)")
        return nil  // Exercise never logged before (Week 1 or always skipped)
    } catch {
        AppLogger.logApp("Failed to fetch previous session: \(error)", level: .error)
        return nil
    }
}
```

**Step 2 - Update WorkoutLoggerView.swift (lines 339-342)**:
```swift
// Remove sessionIndex parameter from call
guard let previousSets = authService.getPreviousSessionData(
    programId: userProgram?.id?.uuidString ?? "",
    exerciseName: exerciseName  // Only pass exercise name
) else {
    return 0  // No previous data - hide badge
}
```

**Testing Checklist**:
- [ ] Week 1 workout: Badge hidden (no previous data)
- [ ] Week 2 same exercise: Badge shows "+X reps"
- [ ] Skipped week: Compares to most recent (however far back)
- [ ] Skipped exercise: Badge hidden for that exercise only
- [ ] Always-skipped exercise: Graceful null handling
- [ ] Progression prompts work alongside rep counter

**PRIORITY**: Fix this FIRST - it unblocks your core differentiating features.

---

### 2. Password Reset is Broken ⚠️ **BLOCKING** (2-3 hours)
**Problem**: Password reset generates code and prints to console but doesn't actually reset password

**Files**:
- `trAInSwift/Views/PasswordResetRequestView.swift`
- `trAInSwift/Views/PasswordResetCodeView.swift`
- `trAInSwift/Services/AuthService.swift`

**Solution Options:**

**Option A - Quick Fix (30 mins)**: Disable "Forgot Password" for MVP
```swift
// In LoginView.swift, comment out:
// Button("Forgot password?") { ... }
```

**Option B - Proper Fix (2-3 hours)**: Implement local password reset
```swift
// In AuthService.swift, add:
func resetPassword(email: String, newPassword: String, resetCode: String) -> Bool {
    // 1. Verify reset code matches stored code
    // 2. Update password in Keychain
    // 3. Return success
}
```

**DECISION NEEDED**: Which approach? Option A gets you live faster.

---

### 3. App Crashes if Core Data Fails ⚠️ **BLOCKING** (1 hour)
**Problem**: Uses `fatalError()` instead of graceful degradation

**File**: `trAInSwift/Persistence/PersistenceController.swift:27`

**Current Code**:
```swift
if let error = error {
    fatalError("❌ Core Data failed to load: \(error.localizedDescription)")
}
```

**Fix**:
```swift
if let error = error {
    AppLogger.logApp("❌ Core Data failed: \(error)", level: .critical)
    // Show error state in UI instead of crashing
    self.container = NSPersistentContainer(name: "TrainSwift")
    // Create in-memory store as fallback
    let description = NSPersistentStoreDescription()
    description.type = NSInMemoryStoreType
    container.persistentStoreDescriptions = [description]
    container.loadPersistentStores { _, _ in }
}
```

**Add to ContentView.swift**: Error banner if Core Data in fallback mode

---

### 4. Config File is Misleading ⚠️ **BLOCKING** (30 mins)
**Problem**: `Config.swift.example` references Supabase but app doesn't use it

**File**: `trAInSwift/Services/Config.swift.example`

**Fix**: Update to remove confusion
```swift
// Config.swift.example
import Foundation

struct Config {
    // MARK: - App Configuration
    static let appName = "trAIn"
    static let appVersion = "1.0.0"

    // MARK: - Feature Flags
    static let enableTestAccounts = false // Set to true for DEBUG builds only

    // MARK: - Subscription Product IDs
    // ⚠️ UPDATE THESE to match your App Store Connect products
    static let monthlySubscriptionID = "com.train.subscription.monthly"
    static let annualSubscriptionID = "com.train.subscription.annual"

    // MARK: - Future Cloud Sync (Not Implemented)
    // Reserved for post-MVP cloud sync feature
    // static let cloudSyncEnabled = false
}
```

**Also add to .gitignore**:
```
trAInSwift/Services/Config.swift
```

---

### 5. Verify Exercise Database in Bundle ⚠️ **CRITICAL** (5 mins)
**Problem**: App won't work if database isn't bundled

**File**: `trAInSwift/Resources/exercises.db`

**To Verify**:
1. Open `trAInSwift.xcodeproj` in Xcode
2. Select target "trAInSwift"
3. Go to "Build Phases" tab
4. Expand "Copy Bundle Resources"
5. Ensure `exercises.db` is listed
6. If not, click "+" and add it

**Test**: Run app in simulator and check logs for database init

---

### 6. Update Paywall Product IDs ⚠️ **CRITICAL** (15 mins)
**Problem**: Hardcoded placeholder IDs won't match App Store Connect

**File**: `trAInSwift/Views/PaywallView.swift:163-166`

**Current**:
```swift
let productIDs = [
    "com.train.subscription.annual",
    "com.train.subscription.monthly"
]
```

**Fix**: Update to match your actual App Store Connect product IDs (or use Config.swift)

---

### 7. Fix Crash Risk in Dashboard ⚠️ **HIGH** (1 hour)
**Problem**: Force unwrap can crash if program data corrupted

**File**: `trAInSwift/Views/DashboardView.swift:476`

**Current**:
```swift
var session: ProgramSession {
    userProgram.getProgram()!.sessions[sessionIndex]
}
```

**Fix**:
```swift
var session: ProgramSession? {
    guard let program = userProgram.getProgram(),
          sessionIndex < program.sessions.count else {
        return nil
    }
    return program.sessions[sessionIndex]
}

// Update UI to handle nil:
if let session = session {
    // Show session
} else {
    Text("Session data unavailable")
}
```

---

## 🟡 HIGH PRIORITY (Should Fix - 5-6 hours)

### 8. Add Logout Button (30 mins)
**Problem**: Users can login but can't logout (except by deleting app)

**File**: `trAInSwift/Views/ProfileView.swift`

**Fix**: Add button in ProfileView:
```swift
Button(action: {
    appViewModel.logout()
    // Navigate to login
}) {
    Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
}
.foregroundColor(.red)
```

The logout function already exists in AuthService!

---

### 9. Connect Workout History to Calendar (4-5 hours)
**Problem**: Workout data saves but Calendar/History views show placeholders

**Files**:
- `trAInSwift/Views/CalendarView.swift` (TODOs at lines 33, 68)
- `trAInSwift/Views/ExerciseHistoryView.swift`

**Fix**: Fetch from Core Data
```swift
@FetchRequest(
    sortDescriptors: [NSSortDescriptor(keyPath: \CDWorkoutSession.completedAt, ascending: false)],
    animation: .default)
private var workoutSessions: FetchedResults<CDWorkoutSession>

// Then map to UI models
```

---

### 10. Implement Streak Counter (1 hour)
**Problem**: Dashboard always shows 0 days streak

**File**: `trAInSwift/Views/DashboardView.swift:60`

**Fix**: Calculate from CDWorkoutSession dates
```swift
func calculateStreak() -> Int {
    let sessions = // Fetch from Core Data, sorted by date
    var streak = 0
    var currentDate = Date()

    for session in sessions {
        if Calendar.current.isDate(session.completedAt, inSameDayAs: currentDate) {
            streak += 1
            currentDate = Calendar.current.date(byAdding: .day, value: -1, to: currentDate)!
        } else {
            break
        }
    }
    return streak
}
```

---

## 🟢 NICE TO HAVE (Can Ship Without - 3-4 hours)

### 11. Add Workout Duration Timer (1 hour)
**Problem**: Timer shows "00:00" instead of elapsed time

**File**: `trAInSwift/Views/WorkoutLoggerView.swift:388`

**Fix**: Add Timer publisher
```swift
@State private var workoutStartTime = Date()
@State private var elapsedSeconds = 0

// In body:
.onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
    elapsedSeconds = Int(Date().timeIntervalSince(workoutStartTime))
}
```

---

### 12. Show Dynamic Priority Muscles (1 hour)
**Problem**: Dashboard shows hardcoded "Chest, Quads, Shoulders"

**File**: `trAInSwift/Views/DashboardView.swift:248-295`

**Fix**: Read from `userProgram.priorityMusclesArray`

---

### 13. Implement Questionnaire Restart (1 hour)
**Problem**: TODO in ProfileView for re-taking questionnaire

**File**: `trAInSwift/Views/ProfileView.swift:261`

**Fix**: Clear current program and navigate to questionnaire

---

## 📋 PRE-LAUNCH VERIFICATION

### Code Review
- [ ] Search codebase for `TODO`, `FIXME`, `HACK` - resolve or document
- [ ] Search for `fatalError()` - replace with error handling
- [ ] Search for force unwraps (`!`) in critical paths - add guards
- [ ] Review all `print()` statements - replace with AppLogger

### Testing Checklist
- [ ] **Fresh Install Flow**
  - [ ] Signup with new account works
  - [ ] Questionnaire completion works
  - [ ] Program generates successfully
  - [ ] Program saves to Core Data
  - [ ] Can navigate to dashboard

- [ ] **Workout Logging**
  - [ ] Can start workout session
  - [ ] Can log sets/reps/weight
  - [ ] Rest timer works
  - [ ] Session saves on completion
  - [ ] Can view completed sessions

- [ ] **Offline Functionality**
  - [ ] Turn on Airplane Mode
  - [ ] Log workout (should work)
  - [ ] Navigate between views (should work)
  - [ ] No crashes or errors

- [ ] **Data Persistence**
  - [ ] Force quit app
  - [ ] Relaunch
  - [ ] User still logged in
  - [ ] Program still available
  - [ ] Workout history persists

- [ ] **Edge Cases**
  - [ ] Login with wrong password
  - [ ] Signup with existing email
  - [ ] Complete workout with 0 reps (should prevent)
  - [ ] Delete app and reinstall (fresh state)

### Build Configuration
- [ ] Set to Release build configuration
- [ ] Update version number (1.0.0 for MVP)
- [ ] Update build number
- [ ] Verify signing certificate
- [ ] Test on physical device (not just simulator)
- [ ] Check app size (should be < 50MB)

### App Store Connect Setup
- [ ] Create app listing
- [ ] Set up In-App Purchases (subscription products)
- [ ] Add app icon (1024x1024)
- [ ] Add screenshots (6.7", 6.5", 5.5")
- [ ] Write app description
- [ ] Set privacy policy URL
- [ ] Configure TestFlight for beta testing

---

## 🚀 DEPLOYMENT STRATEGY

### Phase 1: Internal Testing (Week 1)
- [ ] Fix all CRITICAL blockers
- [ ] TestFlight to team only
- [ ] Test core flows end-to-end
- [ ] Fix any showstopper bugs

### Phase 2: Limited Beta (Week 2)
- [ ] Fix HIGH priority items
- [ ] TestFlight to 10-20 external beta testers
- [ ] Collect feedback
- [ ] Monitor crash reports

### Phase 3: Public Launch (Week 3-4)
- [ ] Address beta feedback
- [ ] Fix NICE TO HAVE items (optional)
- [ ] Submit to App Store
- [ ] Soft launch (no marketing)
- [ ] Monitor reviews and crashes

---

## 📊 ESTIMATED TIMELINE

### Critical Path to MVP (Must Do)
| Task | Effort | Priority |
|------|--------|----------|
| **Rep Counter query fix** | **2-3h** | **CRITICAL** |
| Password reset fix | 2-3h | CRITICAL |
| Core Data error handling | 1h | CRITICAL |
| Config cleanup | 30m | CRITICAL |
| Bundle verification | 5m | CRITICAL |
| Paywall product IDs | 15m | CRITICAL |
| Force unwrap fixes | 1-2h | HIGH |
| **TOTAL** | **7-10 hours** | - |

### High Value Additions (Should Do)
| Task | Effort | Priority |
|------|--------|----------|
| Logout button | 30m | HIGH |
| Workout history UI | 4-5h | HIGH |
| Streak counter | 1h | HIGH |
| **TOTAL** | **5.5-6.5 hours** | - |

### Polish Items (Nice to Have)
| Task | Effort | Priority |
|------|--------|----------|
| Workout timer | 1h | MEDIUM |
| Dynamic muscles | 1h | MEDIUM |
| Questionnaire restart | 1h | MEDIUM |
| **TOTAL** | **3 hours** | - |

### **GRAND TOTAL TO SHIPPABLE MVP: 12-16 hours** (1.5-2 days)

---

## ⚠️ KNOWN LIMITATIONS FOR MVP

**These are INTENTIONALLY not included - add post-MVP:**

1. **No Cloud Sync** - All data local only
   - Users can't switch devices
   - Data lost if app deleted
   - Post-MVP: Add iCloud/Supabase sync

2. **No Exercise Videos** - Text instructions only
   - Less engaging than videos
   - Post-MVP: Add video library

3. **No Social Features** - Solo experience only
   - No sharing workouts
   - No friends/leaderboards
   - Post-MVP: Add social layer

4. **No Password Recovery Email** - Can't reset via email
   - Users must remember password
   - Post-MVP: Add email service

5. **No Body Measurements** - Workout tracking only
   - Can't track weight/body fat
   - Post-MVP: Add measurement tracking

6. **No Progressive Overload Suggestions** - Manual progression
   - App doesn't auto-increase weight
   - Post-MVP: Add AI progression recommendations

---

## 🎯 SUCCESS METRICS

**For MVP to be considered successful:**

- [ ] App doesn't crash during normal use
- [ ] Users can complete onboarding → questionnaire → program
- [ ] Users can log at least 3 workouts successfully
- [ ] < 5% of users report data loss
- [ ] App Store rating ≥ 4.0 stars
- [ ] TestFlight crash rate < 1%

---

## 📝 NEXT STEPS

1. **TODAY**: Fix Rep Counter query logic (item 1) - **PRIORITY #1** - This unblocks core features
2. **TODAY**: Fix remaining critical blockers (items 2-7)
3. **TOMORROW**: Add high priority features (items 8-10)
4. **DAY 3**: Internal testing + bug fixes
5. **DAY 4**: TestFlight beta to 10 users
6. **WEEK 2**: Iterate based on feedback
7. **WEEK 3**: Submit to App Store

---

## 🔍 FINAL ASSESSMENT

**Current State**: App is architecturally sound and 85% feature-complete

**What Works Great**:
- ✅ Offline-first architecture (smart for MVP)
- ✅ Dynamic program generation from 500+ exercise database
- ✅ Clean MVVM architecture
- ✅ Proper Core Data setup
- ✅ Complete workout logging flow
- ✅ Real StoreKit 2 subscription implementation

**What Needs Work**:
- 🔴 **1 CRITICAL blocker: Rep Counter query logic (breaks core value prop)**
- 🔴 6 other critical bugs (password reset, error handling, config, etc.)
- 🟡 3 high-priority UX gaps (logout, history, streak)
- 🟢 3 nice-to-have polish items

**Bottom Line**: **Fix Rep Counter FIRST (2-3 hours), then remaining critical items (5-7 hours).** Total 7-10 hours to shippable MVP. The rest can be added post-launch based on user feedback.

The codebase quality is high - this is production-ready code that just needs the rough edges smoothed out. Ship fast, iterate based on real user feedback.

---

**Created**: November 14, 2024
**Last Updated**: November 14, 2024
**Document Owner**: Luke Vassor & Brody Bastiman
