<p align="center">
  <img src="../assets/train-logo-with-text_isolate_cropped_dark.svg" alt="train" width="280">
</p>

<p align="center">
  <em>UX/UI improvement log — design system changes and overhaul phases</em>
</p>

<p align="center">
  <strong>Created by</strong>: Brody Bastiman & Luke Vassor
</p>

---

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

## Phase 3: Core Workout Loop
- Pre-populate weight/reps from previous session in `initializeLoggedExercises()` via `getPreviousSessionData()`
- Added focus chain across set rows — shared `SetField` enum + `@FocusState` in `SetLoggingCard` with "Next"/"Done" keyboard toolbar
- Added `UIImpactFeedbackGenerator(style: .medium)` haptic feedback on set completion checkmark tap
- Redesigned feedback system: regression stays as modal, non-regression shows inline highlight card (auto-dismiss 2.5s)
- Created `ProgressionBannerView` — WHOOP-style banner at top of Logger when previous session exceeded rep range
- Inline highlight card shows contextual messages: "You lifted Xkg more!" / "+X reps!" / "You showed up!"
- Added "Next: [Exercise Name]" button to inline card and regression modal for quick exercise navigation
- Added rest timer completion alert: haptic feedback + system vibration + local notification for backgrounded app
- Pre-fetch exercise details on `ExerciseLoggerView.onAppear` instead of only on tab switch to demo/history
- Added "X/Y exercises" progress indicator subtitle to WorkoutOverviewView header
- Updated `new_rules.md` Section 1 to document new feedback behavior (progression banner, inline card, regression modal)

## Phase 4: Gamification & Celebrations
- Created `PBCelebrationOverlay.swift` — full-screen animated overlay with 3 modes: weight PB (trophy + confetti), rep record (flexed bicep + light confetti), no improvement (book + session count)
- Confetti particle system using `TimelineView` + `Canvas` — 40 particles for PBs, 25 for rep records, sinusoidal drift, opacity fade
- Celebration overlay triggers from "Complete Workout" button before `WorkoutSummaryView` — auto-dismiss 3s or tap
- Created `WorkoutShareCardGenerator.swift` — renders branded 1080×1920 SwiftUI view to `UIImage` via `ImageRenderer` for Instagram Stories / general sharing
- Share card includes: dark gradient background, train. logo watermark, session name, date/duration, PB callouts, full exercise list, streak count
- Created `WorkoutShareService.swift` — assembles share data, builds formatted text payload, presents `UIActivityViewController` with image + text
- Added Instagram Stories deep link support via `instagram-stories://share` URL scheme with pasteboard image handoff
- Replaced `WorkoutSummaryView.shareWorkout()` to use `WorkoutShareService` instead of inline text-only share
- Animated progress bars in `MilestonesView` — `@State animatedProgress` animates from 0 to actual value on `.onAppear`
- Added questionnaire progress encouragement: "Almost there — X% complete" text on steps 8+ in `QuestionnaireView`
- Added personalized greeting after name entry: "Nice to meet you, {name}!" on step 2 (HealthProfileStepView)
- Added estimated time remaining: "~3 min" on step 0, dynamic "~X min remaining" on steps 1–7
- Added X dismiss button to `EngagementPromptCard` with 7-day UserDefaults cooldown in `DashboardCarouselView`
- Added streak celebration milestones (7-day, 30-day, 100-day) with gradient celebration card in `WorkoutSummaryView`
- Added `StreakMilestone` data model and `streakMilestoneReached` computed property for milestone detection
- Added "Streak Milestones" section in `MilestonesView` with animated progress bars matching existing milestone style
- Added "View Your Milestones →" deep link button in `WorkoutSummaryView` when PBs detected — opens `MilestonesView` sheet

## Phase 5: Dashboard & Navigation
- Added `.refreshable` pull-to-refresh on DashboardView ScrollView with `reloadDashboardData()` async method
- Changed WeeklyCalendarView `getMonthData()` to start grid on Monday instead of Sunday — matches `WeeklyProgressCard`
- Changed CalendarView day headers from `["Sun"…"Sat"]` to `["Mon"…"Sun"]` and set `calendar.firstWeekday = 2`
- Changed DashboardView streak to show grey flame (`.opacity(0.3)`) + "-" when no sessions exist instead of "0"
- Changed WorkoutSummaryView streak section to show "Complete a workout to start your streak!" for zero-streak users
- Replaced per-day Core Data fetch in WeeklyCalendarView with single `batchFetchSessions(from:to:)` returning `[Date: String]` dictionary
- Moved two `DateFormatter` instances in ExerciseHistoryView `HistorySessionCard` from computed properties to `static let`
- Fixed ProgramLoadingView timer leak — added `@State var timer`, stored reference, added `.onDisappear { timer?.invalidate() }`
- Replaced `onTapGesture` with `Button(action:)` wrapper on EngagementPromptCard for accessibility and press feedback
- Changed ProgramReadyView CTA from "Start Training Now!" to "Create Your Account" — honest labelling since it leads to signup
- Replaced deprecated `NavigationView` with `NavigationStack` in CalendarView and LoginView `EmailLoginSheet`
- Replaced `UIScreen.main.bounds.width` with `GeometryReader` in WelcomeView for multi-window support
- Hid Education "Coming Soon" tab in CombinedLibraryView — shows only Exercises list until content exists
- Removed "Edit" toolbar button from SessionLogView — hidden until editing is implemented
- Created `SessionNameFormatter.swift` shared utility — extracted `getAbbreviation(for:)` duplicated across 4 files
- Replaced 4 local `getAbbreviation` methods with `SessionNameFormatter.abbreviation(for:)` in WeeklyCalendarView, WeeklyProgressCard, DashboardCarouselView, DashboardView
- Changed "Recommended Learning" label to "Prepare for your next session" in LearningRecommendationCard
- Rewrote `createLearningRecommendationData()` to fetch next incomplete session's exercises, pick lowest-volume exercise instead of random

## Phase 6: Onboarding & Auth
- Created `QuestionnaireStateManager.swift` — persists step index + answers to UserDefaults on each Continue; restores on relaunch; clears on completion
- Added slide transition animation on questionnaire step changes — `.asymmetric` move with `.easeInOut(duration: 0.3)`
- Added `ReviewSummaryStepView` before program generation — shows goals, experience, days, split, duration, equipment with Edit links back to each step
- Increased questionnaire `totalSteps` from 14 to 15 to accommodate review summary step
- Made TrainingDaysStepView day number labels tappable `Button`s + added `.accessibilityAdjustableAction` for VoiceOver
- Fixed InjuriesStepView "No injuries" appearing pre-selected — added `hasExplicitlyChosen` state; requires explicit tap
- Changed EquipmentStepView subtitle to show dynamic count: "We pre-selected X items based on your gym type. Tap to adjust."
- Added checkmark icon overlay on `OptionCard` when selected — colour-blind accessible selection indicator
- Added checkbox icon (empty square / filled square) to `MultiSelectCard` for multi-select affordance
- Changed NameStepView subtitle from "Please enter your username" to "Please enter your name"
- Fixed name sanitization to allow apostrophes and hyphens — O'Brien, Mary-Jane now accepted
- Changed SessionDurationStepView subtitles from biased ("Quick and efficient") to neutral time ranges
- Updated ReferralStepView SF Symbols — TikTok → `music.note`, Friend → `person.2.fill`
- Added "Unlocks X+ exercises" social proof subtitle to each equipment category heading
- Promoted LoginView "Create an Account" button with branded `.trainPrimary` color and 2pt border
- Added password visibility toggle (eye icon) to LoginView and PostQuestionnaireSignupView password fields
- Added inline form validation to PostQuestionnaireSignupView — red border + error text for invalid email/short password
- Fixed PasswordResetCodeView race condition — removed `asyncAfter` delay, moved navigation to `.sheet(onDismiss:)`
- Added `.textContentType(.oneTimeCode)` to password reset code inputs for iMessage auto-fill
- Added notification type bullet list to NotificationPermissionView — rest timer, workout reminders, streak updates
- Added "You can enable notifications anytime in Settings → train." subtitle below Maybe Later button
- Added notification denied state handling — shows "Open Settings" button when permissions previously denied

## Phase 7: Polish & Platform
- Added `.light` haptic feedback on `OptionCard` and `MultiSelectCard` tap in questionnaire
- Added `.medium` haptic feedback on questionnaire Continue button taps
- Added `.success` notification haptic on Generate Program final step
- Added `.success` notification haptic on `ProgramReadyView` confetti trigger
- Added horizontal shake animation (±10pt, 3 cycles) on wrong password reset code entry
- Added green checkmark scale animation on correct password reset code verification
- Added `.transition(.opacity)` with `withAnimation` to LoginView Apple/Google sign-in loading overlay
- Added staggered `.offset(y:)` + `.opacity` entrance animation on PaywallView pricing tier cards (0.1s delay per card)
- Changed ProgramLoadingView to non-linear progress curve — fast 0→30%, slow 30→80%, fast 80→100%
- Extended ProgramLoadingView completion celebration pause from 0.5s to 1.5s
- Wrapped 5 verbose debug `DispatchQueue.main.asyncAfter` chains in `#if DEBUG` in PostQuestionnaireSignupView
- Marked 4 legacy dead code components as deprecated: `ExerciseLoggerInfoCard`, `SetLoggingSection`, `SetInputRow`, `HistoryEntryCard`
- Added "Resend Code" button with 60-second countdown timer to PasswordResetCodeView
- Added `.textContentType(.newPassword)` to all 4 password fields in PasswordResetNewPasswordView for Keychain integration
- Capped WeeklyCalendarView forward navigation at current month — disables forward chevron when viewing current or future month
- Removed plaintext password reset code from `AppLogger.logAuth()` — now logs only email, not the code value
- Replaced weak `email.contains("@")` validation with proper RFC-compliant email regex in PasswordResetRequestView
- Added "Type DELETE to confirm" text input confirmation to ProfileView delete account — prevents accidental single-tap deletion
- Created `SpotlightIndexer.swift` — indexes completed workouts in CoreSpotlight with session name, date, exercise count, duration
- Added Siri Shortcut registration for "Start my workout" via `NSUserActivity` on app launch
- Wired Spotlight indexing into `WorkoutOverviewView` session save flow
- Added `.keyboardShortcut(.defaultAction)` to `CustomButton` primary style for external keyboard support

## Post-Phase 7: Bug Fixes & Polish
- Fixed infinite loading on Demo/History tabs — fallback `DBExercise` from `ProgramExercise` data if DB fetch fails; renders placeholders instead of spinner
- Added navigation error alert when dashboard exercise card tap fails — `ExerciseListView` shows "Exercise Not Found" alert
- Changed `LoggerTabSelector` and `DemoHistoryTabSelector` backgrounds from `Color.trainSurface.opacity(0.5)` to `.ultraThinMaterial` (glass style)
- Restored exercise database — set `is_in_programme = 1` for all 230 exercises (was 102); regenerated `exercises.db` via Python script
- Replaced SF Symbol equipment icons in Demo tab with bundled equipment images via `EquipmentImageMapping.image(for:)` with SF Symbol fallback
- Centered "Equipment" and "Active Muscle Groups" section headings on Demo tab — removed left-alignment and hardcoded padding
- Restructured MilestonesView top stats — Lottie flame now centered between PBs and Workouts cards as decorative element (no card background); fixed FlameView UIKit constraints
- Added video thumbnails to `ExerciseLibraryCard` via `AsyncImage` + Bunny CDN; updated subtitle to show primary muscle + equipment info

---

Made with ❤️ by Brody Bastiman & Luke Vassor
