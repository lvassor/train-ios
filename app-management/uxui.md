# UX/UI Improvement Log

Each line documents a single UX/UI change made during the overhaul.

## Phase 1: Design System Foundation
- Added `trainTextOnPrimary` color token (#1a1a2e) for dark text on orange backgrounds — WCAG AA compliant
- Added `trainMuscleDefault` (#3f3f3f) and `trainMuscleInactive` (#8a8a8a) tokens for muscle diagram colors
- Added `trainConfetti` color array for celebration confetti — 5 decorative colors centralised
- Added `trainInputBorder` and `trainInputBorderSubtle` adaptive tokens for input field borders
- Added `ShadowStyle` token system with 9 elevation levels (none/borderLine/subtle/card/elevated/modal/media/iconOverlay/dragging/navBar)
- Added `BorderWidth` tokens (hairline/standard/emphasis/heavy)
- Added `OpacityLevel` tokens (disabled/secondary/primary/full)
- Added `AnimationDuration` tokens (quick/standard/slow/celebration)
- Replaced 16 hardcoded `Color(hex:)` calls across 7 files with semantic tokens
- Replaced 10 raw `Color.green` / `.foregroundColor(.green)` with `.trainSuccess` across 5 files
- Replaced 10 raw `Color.orange` / `.foregroundColor(.orange)` with `.trainWarning` across 4 files
- Replaced 11 raw `Color.red` / `.foregroundColor(.red)` with `.trainError` across 9 files (kept Apple Health heart icon red)
- Replaced 15 ad-hoc `.shadow()` calls with `.shadowStyle()` tokens across 9 files
- Fixed 4 hardcoded `cornerRadius` values to use `CornerRadius` tokens across 3 files
- Eliminated 17 `@Environment(\.colorScheme)` manual branching declarations across 4 files
- Replaced 11 conditional color expressions with adaptive Asset Catalog tokens

## Phase 2: P0 Ship-Blockers
- Replaced `Int.random()` streak/session counts in WorkoutSummaryView with real Core Data queries via `SessionCompletionHelper`
- Replaced `completedSets * 2` fake reps calculation with actual set-by-set comparison using `getPreviousSessionData()`
- Made `generateCelebrationContent()` deterministic based on PBs/streak/completion instead of `randomElement()`
- Implemented `shareWorkout()` with `UIActivityViewController` — builds text payload with exercises, sets, PB callouts
- Replaced hardcoded "47:20" / "12 reps" / "25.0kg" in DashboardView `CompletedSessionSummaryCard` with real `CDWorkoutSession` data
- Replaced mock exercise history entries in ExerciseHistoryView with real Core Data fetch across all `CDWorkoutSession` records
- Changed warm-up card in WorkoutOverviewView to show actual exercise count and duration estimate
- Fixed CalendarView `NSPredicate(value: true)` → `NSPredicate(format: "userId == %@", userId)` to scope to current user only
- Removed `UINavigationBar.appearance()` global mutation from ProgramOverviewView `.onAppear` — uses app-level config instead
- Rewrote PaywallView with 3 pricing tiers (Monthly/Quarterly/Annual), dismiss X, Restore, promo code, ToS/Privacy links
- Added `com.train.subscription.quarterly` product ID to PaywallView alongside existing monthly/annual
- Added error message display to LoginView for failed auth attempts
- Uncommented "Forgot Password?" button and wired to `PasswordResetRequestView` in LoginView
- Promoted Sign Up from underlined grey text to full outlined secondary button "Create an Account"
- Rewrote ProfileView `SubscriptionInfoCard` — loads real subscription data from StoreKit `Transaction.currentEntitlements`
- Wired DashboardView settings gear button to open ProfileView via sheet
- Added accessibility labels and hints to 5 key views: DashboardView, WorkoutOverviewView, WorkoutSummaryView, ProfileView, CalendarView
- Converted 11 typography tokens from fixed `Font.system(size:)` to Dynamic Type-scaling built-in text styles
- Applied `.fontDesign(.rounded)` at app root for SF Pro Rounded inheritance across all Dynamic Type tokens
