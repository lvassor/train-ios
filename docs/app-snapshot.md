# App Snapshot — train. iOS

> Generated 2026-03-03 from codebase analysis of `feature/calendar-tab` branch.
> Intended for competitive market analysis hand-off to Claude Chat.

---

## 1. Product & Identity

| Field | Value |
|---|---|
| App name | **train.** (lowercase with period) |
| Bundle ID | [redacted] |
| Marketing version | 5 |
| Build number | 2 |
| Deployment target | iOS 26.0 |
| Supported devices | iPhone & iPad (`TARGETED_DEVICE_FAMILY = "1,2"`) |
| Swift version | 5.0 |
| UI framework | SwiftUI (no UIKit screens) |
| Architecture | MVVM + Services layer |
| Development team | [redacted] |

---

## 2. Complete Feature Inventory

### 2.1 Screens (47 views)

| Area | Screen | Key capabilities |
|---|---|---|
| **Launch** | `LaunchScreenView` | 3.5 s splash with loading animation |
| **Welcome** | `WelcomeView` | Carousel screenshots, "Expert Programs. Built Around You.", Sign In / Continue CTAs |
| **Auth** | `LoginView` | Apple Sign-In, Google Sign-In, Email/Password login |
| | `SignupView` | Email/password registration (6-char min) |
| | `PasswordResetRequestView` | Email-based reset request |
| | `PasswordResetCodeView` | 6-digit verification code entry |
| | `PasswordResetNewPasswordView` | New password form |
| **Questionnaire** | `QuestionnaireView` | 15-step coordinator with progress bar |
| | `QuestionnaireSteps` | Individual step views (see §3 Onboarding) |
| | `HealthProfileStepView` | Gender, DOB, Apple Health sync |
| | `HeightWeightStepView` | Height (cm / ft-in), Weight (kg / lbs) |
| | `VideoInterstitialView` | Educational value-prop video between steps |
| | `ReviewSummaryStepView` | Editable summary before program generation |
| | `NotificationPermissionView` | Push notification opt-in |
| | `ReferralStepView` | "How did you hear about us?" attribution |
| | `PostQuestionnaireSignupView` | Signup gate after questionnaire |
| | `PostSignupFlowView` | Post-signup flow (notifications + referral) |
| **Program gen** | `ProgramLoadingView` | Animated progress during generation |
| | `ProgramReadyView` | "Your Program is Ready" with confetti |
| **Dashboard** | `DashboardView` | Next session card, weekly progress, streak flame, carousel |
| | `DashboardCarouselView` | Recent workouts, PBs, learning recs, engagement prompts |
| | `WeeklyProgressCard` | X/Y sessions this week with day abbreviations |
| | `CarouselCardView` | Reusable carousel card component |
| | `EngagementPromptCard` | Share progress / rate app / review (TODO stubs) |
| | `LearningRecommendationCard` | Tip of the day / learning content |
| **Calendar** | `CalendarTabView` | Month grid, day-by-day completion, session names on dates |
| | `CalendarSessionDetailView` | Session detail when tapping a calendar date |
| **Milestones** | `MilestonesView` | Top stats, recently achieved, upcoming, streaks, recent PBs |
| **Library** | `CombinedLibraryView` | Unified exercise browser |
| | `ExerciseLibraryView` | Search + muscle/equipment filter, 229 exercises |
| | `ExerciseHistoryView` | Per-exercise chart (total volume vs max weight), best set |
| | `ExerciseDemoHistoryView` | Tabbed demo video + history |
| **Profile** | `ProfileView` | Name, join date, current program, subscription card, theme toggle, logout, delete account |
| **Paywall** | `PaywallView` | 3-tier StoreKit 2 subscription wall |
| **Workout** | `ProgramOverviewView` | All weeks & sessions in program |
| | `SessionDetailView` | Session preview: exercises, sets/reps/rest, "Start Workout" |
| | `WorkoutOverviewView` | Warm-up timer (5 min), exercise list, edit mode, elapsed timer |
| | `SessionEditView` | Add/remove/swap/reorder exercises in a session |
| | `ExercisePickerView` | Add exercise from full database |
| | `ExerciseLoggerView` | 3-tab logger (Log / Demo / History), set-by-set input |
| | `ExerciseLoggerDemoView` | Bunny Stream video playback |
| | `ExerciseLoggerFeedback` | Real-time set performance feedback |
| | `InlineRestTimer` | Non-blocking countdown, haptic + local notification on complete |
| | `ProgressionBannerView` | "Time to increase weight" / "Great consistency" banner |
| **Post-workout** | `WorkoutSummaryView` | Celebration, stats card, PBs carousel, milestones, share |
| | `SessionLogView` | Completed session review with volume/duration/PBs |
| | `PBCelebrationOverlay` | Confetti overlay for weight PBs / rep records |
| **Sharing** | `WorkoutShareCardGenerator` | 1080×1920 image card for Instagram Stories |

### 2.2 Core User Flows

```
ONBOARDING → ACTIVATION → RETENTION LOOP → MONETIZATION

1. Onboarding (first launch):
   Welcome → 15-step Questionnaire → Program Generation → Signup
   → Notification Permission → Referral Attribution → Dashboard

2. Activation (first workout):
   Dashboard "Next Workout" → Session Preview → Start Workout
   → Warm-up Timer (5 min, skippable) → Exercise Logger (per exercise)
   → Set logging (weight + reps × 3 sets) → Rest Timer → Next Exercise
   → Workout Summary (PBs, milestones, share card) → Dashboard

3. Retention loop (daily/weekly):
   Dashboard streak flame → Next session card → Log workout
   → PB celebrations → Milestone unlocks → Share card
   → Calendar fills up → Weekly progress bar → Repeat

4. Monetization:
   Post-signup → PaywallView (currently bypassed with skipPaywallForMVP = true)
   → Monthly / Quarterly / Annual subscription
```

### 2.3 Strength Training Capabilities

| Capability | Status | Details |
|---|---|---|
| Exercise library | **229 exercises** | SQLite DB, each with: display name, canonical name, primary/secondary muscle, equipment, complexity (1–2), MCV rating (0–100), instructions, demo video |
| Equipment database | **60 items** across 8 categories | Barbells, Dumbbells, Kettlebells, Cables, Pin-Loaded, Plate-Loaded, Other, Attachments |
| Exercise videos | **229 videos** | 1:1 mapping, Bunny Stream CDN (library `[redacted]`), HLS streaming |
| Progression model | Auto-detect | If first 2 sets hit/exceed rep-range ceiling → "Time to increase weight" banner |
| Regression model | Auto-detect | If first 2 sets below rep-range floor → encouragement + regression suggestion |
| Progression/regression chains | Per exercise | `progressionId` → harder variants, `regressionId` → easier variants (comma-separated IDs) |
| Rest timers | Inline non-blocking | Rating ≥ 80 → 120 s, 50–79 → 90 s, < 50 → 60 s; haptic + local notification on complete |
| Personal bests | Automatic | Weight PBs detected per exercise across all sessions; celebrated with confetti overlay |
| Program generation | Database-driven | Questionnaire → equipment filter → injury contraindications → MCV scoring → exercise selection |
| Program templates | Hardcoded fallback | `HardcodedPrograms` for when DB generation fails |
| Program types | 3 splits | Full Body, Upper/Lower, Push/Pull/Legs (+ hybrid variants: 2U1L, 1U2L, PPL+UL) |
| Program length | 8 weeks fixed | `ProgramConstants.totalWeeks = 8` |
| Sets per exercise | 3 (default) | `ProgramConstants.defaultSetsPerExercise = 3` |
| Rep range | 8–12 (default) | `ProgramConstants.defaultRepRange = "8-12"` |
| Training frequency | 1–6 days/week | User-configurable in questionnaire |
| Session duration | 3 tiers | 30–45 min, 45–60 min, 60–90 min |
| Injury contraindications | 39 rules | `exercise_contraindications` table: canonical_name × injury_type |
| Exercise swap | In-session | Carousel of alternatives sharing same `canonicalName` |
| Exercise reorder | In-session | Drag-and-drop in `SessionEditView` |
| Warm-up timer | 5 min default | Skippable countdown before workout |
| Weight units | kg / lbs | User toggle, persisted |
| Height units | cm / ft-in | User toggle during onboarding |
| Plate calculator | **Not present** | — |
| 1RM estimation | **Not present** | — |
| RPE / RIR tracking | **Not present** | — |
| Periodization (deloads, waves) | **Not present** | Linear 8-week block only |
| Superset / circuit grouping | **Not present** | — |
| Custom program builder | **Not present** | Questionnaire-driven only |
| Body measurement tracking | **Not present** | Height/weight at signup only |
| Nutrition logging | **Not present** | — |
| Barbell loading / plate math | **Not present** | — |

---

## 3. Onboarding & Personalization

### 3.1 Questionnaire Steps (15 total)

| Step | Question | Input type | Options / Range |
|---|---|---|---|
| 0 | Primary goals | Multi-select | Get Stronger, Build Muscle, Tone Up |
| 1 | Name | Text field | Free text |
| 2 | Health profile | Gender + DOB | Male / Female / Other; date picker (18+ enforced) |
| 3 | Height & Weight | Numeric + unit toggle | cm or ft/in; kg or lbs; optional Apple Health sync |
| 4 | Experience level | Single-select | 0 months, 0–6 months, 6 months–2 years, 2+ years |
| 5 | Video interstitial #1 | Passive | Value prop video (local .mp4) |
| 6 | Training frequency | Slider / picker | 1–6 days per week (with recommendation based on experience) |
| 7 | Training split | Single-select | Full Body, Upper/Lower, Push/Pull/Legs, 2U1L, 1U2L, PPL+UL |
| 8 | Session duration | Single-select | 30–45 min, 45–60 min, 60–90 min |
| 9 | Training place | Single-select | Large gym, Small gym, Garage/home gym |
| 10 | Equipment available | Expandable multi-select | 8 categories with specific items per category (see constants.json) |
| 11 | Video interstitial #2 | Passive | "train creates your perfect workout" |
| 12 | Target muscle groups | Multi-select (max 3) | Chest, Back, Shoulders, Arms, Legs, Core |
| 13 | Injuries/limitations | Multi-select (optional) | Back, Biceps, Calves, Chest, Core, Forearms, Glutes, Hamstrings, Quads, Shoulders, Traps, Triceps |
| 14 | Review summary | Editable review | User can go back and change any answer before "Generate Your Program" |

### 3.2 How Questionnaire Data Drives the App

- **Equipment filter**: Only exercises matching user's available equipment are considered
- **Experience → complexity**: 0–6 months → complexity 1 only; 6 months+ → complexity 1 & 2
- **Injury contraindications**: 39 canonical_name × injury_type rules exclude unsafe movements
- **Target muscles**: Priority muscle groups get more exercise slots
- **MCV scoring**: Exercises ranked by `canonical_rating` (0–100); compounds scored higher
- **Session duration → exercise count**: Short (3–5), Medium (5–7), Long (7–10) exercises per session
- **Training frequency + split → session structure**: Maps days/week to appropriate split type

### 3.3 Gym Type Presets

| Gym type | Equipment categories | Specific items |
|---|---|---|
| Large gym | All 7 categories | Full commercial set (8 barbell stations, 13 pin-loaded, 9 plate-loaded, 4 cable, 5 other, 7 attachments) |
| Small gym | 6 categories (no plate-loaded) | Essential set (3 barbell, 5 pin-loaded, 4 cable, 3 other, 4 attachments) |
| Garage gym | 4 categories (barbells, dumbbells, kettlebells, other) | Basic set (2 barbell, 4 other, 1 attachment) |

---

## 4. Monetization

### 4.1 Subscription Tiers (StoreKit 2)

| Tier | Product ID | Price (GBP fallback) | Per week | Badge | Trial |
|---|---|---|---|---|---|
| Monthly | [redacted] | £4.99 | £1.25 | "Most popular" | None in code |
| Quarterly | [redacted] | £14.99 | £1.15 | — | 7-day free trial (per pre-deployment checklist) |
| Annual | [redacted] | £59.99 | £1.15 | "Best value" | None in code |

### 4.2 Paywall Placement

- **Trigger**: After account creation, before reaching Dashboard
- **Current state**: **Bypassed** — `skipPaywallForMVP = true` in `ProgramReadyView.swift:27`
- **Fallback bug**: If StoreKit product fetch fails, `onComplete()` fires → user bypasses paywall entirely (revenue leak)
- **Promo codes**: Apple's native `SKPaymentQueue.presentCodeRedemptionSheet()` (iOS 16+)
- **Restore purchases**: Button in PaywallView top bar

### 4.3 Free vs Paid Split

| | Free | Paid |
|---|---|---|
| Questionnaire & program preview | Yes | Yes |
| Full app access (logging, library, milestones, history) | **No** (when paywall enabled) | Yes |
| Referral/promo code bypass | Possible via Apple codes | — |

- **No freemium model** — binary paywall gates all core features
- **No consumable IAPs** — subscriptions only
- **No server-side receipt validation** — client-side StoreKit 2 `Transaction.currentEntitlements` only

### 4.4 Referral / Attribution

- `ReferralStepView`: TikTok, Instagram, ChatGPT, Google, Friend, Influencer, App Store, Other
- Marketing attribution only — no referral reward program

---

## 5. Tech Stack & Dependencies

### 5.1 SPM Dependencies (5 packages)

| Package | Version | Purpose |
|---|---|---|
| **GRDB.swift** | `master` branch | SQLite wrapper — exercise database (exercises.db, 236 KB) |
| **SlidingRuler** | ≥ 0.2.0, < 1.0.0 | Height/weight ruler UI in questionnaire |
| **Lottie** (lottie-spm) | ≥ 4.4.0, < 5.0.0 | JSON animations (streak flame, onboarding) |
| **GoogleSignIn-iOS** | ≥ 8.0.0, < 9.0.0 | Google OAuth authentication |
| **GoogleSignInSwift** | ≥ 8.0.0, < 9.0.0 | SwiftUI wrapper for GoogleSignIn |

No Podfile, no Cartfile, no Tuist.

### 5.2 Apple Frameworks Used

| Framework | Usage |
|---|---|
| SwiftUI | All UI |
| CoreData | User profiles, programs, workout sessions |
| HealthKit | Read bio data (height, weight, DOB, sex), write workouts |
| StoreKit 2 | Subscriptions |
| ActivityKit | Live Activities (Dynamic Island + Lock Screen widget) |
| WidgetKit | Workout widget extension |
| CoreSpotlight | Searchable workout indexing |
| AuthenticationServices | Sign in with Apple |
| AVFoundation | Local video playback (onboarding backgrounds) |
| WebKit | Bunny Stream video player (iframe embed) |
| UserNotifications | Rest timer alerts |
| Combine | Reactive state management |
| Charts | Exercise history graphs (SwiftUI Charts) |
| OSLog | Structured logging |

### 5.3 External Services

| Service | Usage | Config |
|---|---|---|
| Bunny Stream CDN | Exercise demo videos (HLS) | Library ID: `[redacted]`, CDN: `[redacted]` |
| Google Sign-In | OAuth authentication | Client ID: `[redacted]` |
| Apple Sign-In | Native authentication | Entitlement enabled |

**No backend API** — fully offline-first, all computation is on-device.

### 5.4 Data Persistence Stack

| Layer | Technology | Purpose |
|---|---|---|
| CoreData (`TrainSwift.xcdatamodeld`) | NSPersistentContainer | User profiles, programs, workout sessions, questionnaire responses |
| GRDB/SQLite (`exercises.db`) | DatabaseQueue | Read-only exercise database (229 exercises, 60 equipment, 39 contraindications, 229 videos) |
| Keychain | Security framework | Passwords (PBKDF2, 600K iterations), API keys |
| UserDefaults | Standard KV store | Session persistence, feature flags |

---

## 6. Data Model

### 6.1 Core Data Entities

**UserProfile**

| Property | Type | Notes |
|---|---|---|
| `id` | UUID | PK |
| `email` | String | Unique |
| `name` | String? | Display name |
| `age` | Int16? | From DOB |
| `height` | Double? | cm |
| `weight` | Double? | kg |
| `experience` | String? | Experience level string |
| `equipment` | Transformable [String]? | Available equipment |
| `injuries` | Transformable [String]? | Current injuries |
| `healedInjuries` | Transformable [String]? | Past injuries |
| `priorityMuscles` | Transformable [String]? | Target muscle groups |
| `questionnaireData` | Binary? | JSON-encoded QuestionnaireData |
| `createdAt` | Date? | Account creation |
| `lastLoginAt` | Date? | Last login |
| `isAppleUser` | Bool? | Sign in with Apple flag |
| `appleUserIdentifier` | String? | Apple user ID |
| `isGoogleUser` | Bool? | Google Sign-In flag |
| `googleUserIdentifier` | String? | Google user ID |
| → `programs` | 1:many → WorkoutProgram | Cascade delete |
| → `sessions` | 1:many → CDWorkoutSession | Cascade delete |

**WorkoutProgram**

| Property | Type | Notes |
|---|---|---|
| `id` | UUID | PK |
| `userId` | UUID | FK → UserProfile |
| `name` | String? | E.g. "Push/Pull/Legs" |
| `split` | String? | Split type |
| `daysPerWeek` | Int16? | 1–6 |
| `sessionDuration` | String? | "30-45 min" / "45-60 min" / "60-90 min" |
| `totalWeeks` | Int16? | Default 8 |
| `currentWeek` | Int16? | Progress tracker |
| `currentSessionIndex` | Int16? | Progress tracker |
| `exercisesData` | Binary? | JSON: `[ProgramSession]` |
| `completedSessionsData` | Binary? | JSON: `Set<String>` |
| `isActive` | Bool? | Active program flag |
| `createdAt` | Date? | Creation timestamp |

**CDWorkoutSession**

| Property | Type | Notes |
|---|---|---|
| `id` | UUID | PK |
| `userId` | UUID | FK → UserProfile |
| `programId` | UUID? | FK → WorkoutProgram |
| `sessionName` | String? | "Push", "Pull", "Legs", "Upper", "Lower", "Full Body" |
| `weekNumber` | Int16? | Week in program |
| `exercisesData` | Binary? | JSON: `[LoggedExercise]` |
| `completedAt` | Date? | Completion timestamp |
| `durationSeconds` | Int32? | Total duration |

### 6.2 SQLite Schema (exercises.db)

**exercises** — 229 rows

| Column | Type | Notes |
|---|---|---|
| `exercise_id` | TEXT PK | E.g. "EX001" |
| `canonical_name` | TEXT NOT NULL | Movement pattern grouping (for swaps) |
| `display_name` | TEXT NOT NULL | User-facing name |
| `equipment_id_1` | TEXT FK NOT NULL | Primary equipment |
| `equipment_id_2` | TEXT FK | Secondary equipment (optional) |
| `complexity_level` | TEXT | "All", "1", "2" |
| `canonical_rating` | INTEGER | 0–100 MCV score |
| `primary_muscle` | TEXT NOT NULL | Main muscle group |
| `secondary_muscle` | TEXT | Optional |
| `instructions` | TEXT | Step-by-step form cues |
| `is_in_programme` | INTEGER | 0/1 |
| `progression_id` | TEXT | Comma-separated harder variants |
| `regression_id` | TEXT | Comma-separated easier variants |

**equipment** — 60 rows, 8 categories

**exercise_videos** — 229 rows, 1:1 with exercises (Bunny Stream GUIDs)

**exercise_contraindications** — 39 rows (canonical_name × injury_type)

### 6.3 In-Memory Structs

- `LoggedExercise` { id, exerciseName, sets: [LoggedSet], notes }
- `LoggedSet` { id, reps: Int, weight: Double, completed: Bool }
- `ProgramSession` { id, dayName, exercises: [ProgramExercise] }
- `ProgramExercise` { id, exerciseId, exerciseName, sets, repRange, restSeconds, primaryMuscle, complexityLevel }

---

## 7. Platform Integrations

| Integration | Status | Details |
|---|---|---|
| **HealthKit** | ✅ Full | Read: height, weight, DOB, biological sex. Write: HKWorkout (strength training + calories) |
| **Live Activities** | ✅ Full | `WorkoutLiveActivityManager` — Dynamic Island + Lock Screen: current exercise, set progress, elapsed time, rest countdown |
| **WidgetKit** | ✅ Full | `WorkoutWidget` extension for live workout state |
| **CoreSpotlight** | ✅ Full | Indexes completed workouts; 6-month expiry |
| **Siri Shortcuts** | ⚠️ Partial | NSUserActivity-based "Start my workout" only; no full AppIntents |
| **Apple Watch** | ❌ | No WatchKit or WatchConnectivity |
| **CloudKit / iCloud Sync** | ❌ | No cloud sync — local Core Data only |
| **AI / ML** | ❌ | No CoreML models, no API calls to AI services |
| **App Clips** | ❌ | Not present |
| **Location** | ❌ | Not used |
| **Camera / Photos** | ❌ | Not used (video playback only) |
| **Background Tasks** | ❌ | Not implemented |
| **Deep Linking** | ⚠️ Minimal | Google OAuth URL scheme callback only |

### Haptic Feedback

Extensive throughout: set completion (medium impact), rest timer done (success notification), option selections (light impact), errors (error notification). Files: `ExerciseLoggerView`, `WorkoutOverviewView`, `InlineRestTimer`, `OptionCard`, `MultiSelectCard`, `QuestionnaireView`, `ProgramReadyView`.

---

## 8. UX & Retention

### 8.1 Gamification — Milestones (39 total)

**Progression (Gold, 13 milestones)**

| Milestone | Threshold |
|---|---|
| First PB | 1 PB |
| 5 / 10 / 25 / 50 Total PBs | 5 / 10 / 25 / 50 |
| PBs in 3 / 5 / 10 Lifts | Unique exercises with PBs |
| First / Second Program Cycle | Complete 8-week program |
| 4 / 8 / 12 Weeks Logged | Calendar weeks with workouts |

**Output (Green, 16 milestones)**

| Milestone | Threshold |
|---|---|
| First 100 / 1K / 5K / 10K Reps | Total reps |
| First 50 / 500 / 1K Sets | Total sets |
| 1 / 10 / 25 / 50 / 100 Workouts | Completed sessions |
| 1K / 10K / 50K / 100K kg Lifted | Total volume |

**Streak (Orange, 10 milestones)**

| Milestone | Threshold |
|---|---|
| 2 / 4 / 8 / 12-Week Streak | Consecutive weeks |
| First Full Week / 4 / 8 Full Weeks | Weeks hitting target days |
| 4 / 8 / 12 Consistent Weeks | Weeks at ≥ target frequency |

### 8.2 Celebration System

| Event | Animation | Duration |
|---|---|---|
| Weight PB | Trophy emoji 🏆 + 40-particle confetti + weight before → after | 3 s auto-dismiss |
| Rep record | Bicep emoji 💪 + 25-particle confetti + rep increase | 3 s auto-dismiss |
| Workout complete (no PB) | Book emoji 📖 + "That's workout #N" | 3 s auto-dismiss |
| Streak flame | Lottie `Fire.json` animation | Continuous in dashboard |

### 8.3 Data Visualization

| Chart | Framework | Metrics |
|---|---|---|
| Exercise history | SwiftUI Charts | Toggle: Total Volume (kg) vs Max Weight per session over time |
| Weekly progress | Custom calendar | Completed sessions per day, X/Y sessions target |
| Monthly calendar | Custom grid | Day-by-day workout completion with session names |
| Milestone progress | Progress bars | Current value / threshold per milestone |

### 8.4 Notifications

| Type | Status | Implementation |
|---|---|---|
| Rest timer complete | ✅ Implemented | `UNTimeIntervalNotificationTrigger` + haptic + vibration |
| Workout reminders | ❌ Mentioned in UI, not implemented | — |
| Streak updates | ❌ Mentioned in UI, not implemented | — |
| Weekly summaries | ❌ Not present | — |

### 8.5 Sharing

- **Text share**: Session name, duration, exercises with sets/reps/weight, PBs, streak count
- **Image share**: `WorkoutShareCardGenerator` produces 1080×1920 px card (Instagram Story size)
- **Share methods**: Native iOS share sheet (Messages, Twitter/X, WhatsApp, Instagram, etc.)
- **No social features**: No followers, feed, leaderboard, challenges

---

## 9. Content & Brand

### 9.1 App Store Metadata

| Field | Value |
|---|---|
| App name | train. |
| Tagline (in-app) | "Expert Programs. Built Around You." |
| Screenshots | 4 assets (`screenshot_1` – `screenshot_4`) in asset catalog |
| Terms of Service URL | [redacted] |
| Privacy Policy URL | [redacted] |
| Fastlane / automation | **Not configured** — manual App Store Connect |
| Privacy manifest (`PrivacyInfo.xcprivacy`) | **Missing** — required for iOS 17.1+ |

### 9.2 Localization

| Language | Status |
|---|---|
| English (en) | ✅ Source language — 1,533 strings in `Localizable.xcstrings` |
| All other languages | ❌ Not translated |

String coverage includes: onboarding, workout logging, milestones, errors, settings, format strings with plural handling.

### 9.3 Brand Design

**Color palette** (18 named colors):
- Primary: Golden-orange (#C48200 light / #F0AA3E dark)
- Background: White / near-black
- Surface: Elevated card backgrounds
- Text: Primary / Secondary / Muted hierarchy
- Gradient: Light → Mid → Dark for animations
- Accent colors for milestones: Gold (progression), Green (output), Orange (streak)

**Visual design**: Glass morphism cards, dark-mode-first, rounded corners, Lottie animations, haptic feedback throughout.

**Logo**: SVG with light/dark variants (`train-logo-with-text_isolate_cropped.svg` + `_dark.svg`).

### 9.4 Target User Persona

**Primary**: Gym-goers seeking structured strength training programs without complex programming knowledge.

| Dimension | Inference |
|---|---|
| Experience range | Complete beginners to advanced lifters (4-tier system) |
| Training style | Hypertrophy-focused (8–12 default rep range, 3 sets) |
| Environment | Commercial gym users primarily (large/small gym presets dominate) |
| Goals | Build muscle, get stronger, tone up (no cardio, endurance, or sport-specific) |
| Pain points | "Lack structure", "Need guidance", "Lack confidence" (from motivation options) |
| Age | 18+ (DOB validation), likely 18–35 based on app design and marketing |
| Gender | Inclusive (Male / Female / Other options) |
| Tech comfort | High — iOS 26 target, modern design patterns |
| Monetization tolerance | Subscription-ready audience (£5–60/yr price range) |

---

## 10. Gaps & Observations

### 10.1 TODOs & Incomplete Features

| Location | TODO | Impact |
|---|---|---|
| `DashboardCarouselView.swift:364` | "Implement progress sharing" | Engagement prompt button is dead |
| `DashboardCarouselView.swift:367` | "Implement in-app rating" | Rating prompt button is dead |
| `DashboardCarouselView.swift:375` | "Implement App Store review request" | Review prompt button is dead |
| `ExerciseHistoryView.swift:352` | "Remove in a future cleanup pass" | Deprecated `HistoryEntryCard` |
| `ExerciseLoggerView.swift:527` | "Remove in a future cleanup pass" | Deprecated `ExerciseLoggerInfoCard` |
| `ExerciseLoggerView.swift:820` | "Remove in a future cleanup pass" | Deprecated `SetLoggingSection` |

### 10.2 Feature Flags

| Flag | Scope | Effect |
|---|---|---|
| `skipPaywallForMVP = true` | `ProgramReadyView.swift:27` | Bypasses paywall entirely — all users get free access |
| `#if SEED_TEST_DATA` | `TestDataSeeder.swift` | Seeds 2 test accounts for TestFlight (emails: `[redacted]`, password: `[redacted]`) |
| `#if DEBUG` | ~20+ locations | Debug logging throughout |
| `#if targetEnvironment(simulator)` | `HealthKitManager` | Graceful HealthKit fallback on simulator |

### 10.3 Dead Code

| Item | Location | Notes |
|---|---|---|
| `HistoryEntryCard` | `ExerciseHistoryView.swift` | Marked DEPRECATED, not referenced |
| `ExerciseLoggerInfoCard` | `ExerciseLoggerView.swift` | Marked DEPRECATED, not referenced |
| `SetLoggingSection` | `ExerciseLoggerView.swift` | Marked DEPRECATED, not referenced |

### 10.4 Technical Debt

| Issue | Severity | Location | Notes |
|---|---|---|---|
| Paywall bypass on product fetch failure | **Critical** | `PaywallView.swift:186-188` | Fallback `onComplete()` lets users through for free |
| 17 force unwraps in calendar date math | **High** | `CalendarTabView.swift:193-313` | Crash risk on edge-case Calendar API failures |
| Hardcoded test credentials in source | **Medium** | `TestDataSeeder.swift` | Password visible in source; mitigated by compile flag |
| No `PrivacyInfo.xcprivacy` | **Medium** | Missing file | Required for App Store submission (iOS 17.1+) |
| 5 large files > 1,000 LOC | **Medium** | `QuestionnaireSteps` (2,017), `WorkoutOverviewView` (1,290), `DashboardView` (1,286), `ExerciseLoggerView` (1,150), `DynamicProgramGenerator` (1,141) |
| No server-side receipt validation | **Medium** | StoreKit 2 client-only | Jailbreak/piracy vulnerability |
| 20+ silent `try?` failures | **Low** | Various services | Makes debugging harder |
| `print()` instead of `AppLogger` | **Low** | `TestDataSeeder.swift` | 5 print statements |
| `precondition(length > 0)` | **Low** | `AppleSignInService.swift:68` | Crashes in release builds on bad input |
| Workout reminders promised but unbuilt | **Low** | `NotificationPermissionView` | UI promises "workout reminders" & "streak updates" that don't exist |

### 10.5 Missing Competitive Features

Features commonly found in top strength training apps that are **absent** here:

- 1RM calculator / estimation (Epley, Brzycki)
- RPE / RIR tracking
- Plate loading calculator
- Deload weeks / periodization cycling
- Body measurements (arms, chest, waist, etc.)
- Progress photos
- Superset / circuit / dropset / rest-pause support
- Custom program builder (beyond questionnaire)
- Social feed / followers / leaderboards
- Apple Watch companion app
- CloudKit / cross-device sync
- Nutrition logging
- AI coaching (despite "trAIn" branding suggesting AI)
- Export to CSV/PDF
- Workout templates (user-created)
- Timer-based HIIT/EMOM/AMRAP modes

---

## 11. File Inventory

### 11.1 Swift Files by Category

| Category | Count | Key files |
|---|---|---|
| Views | 37 | See §2.1 screen list |
| Components | 27 | Dashboard (6), MuscleSelector (4), general (17) |
| Services | 22 | AuthService, ProgramGenerator, DynamicProgramGenerator, ExerciseDatabaseManager, MilestoneService, HealthKitManager, WorkoutLiveActivityManager, SpotlightIndexer, etc. |
| Models | 7 | DatabaseModels, Program, QuestionnaireData, WorkoutSession, WorkoutLog, MilestoneData, WorkoutWidgetAttributes |
| Persistence | 4 | PersistenceController, UserProfile+Ext, WorkoutProgram+Ext, WorkoutSession+Ext |
| ViewModels | 2 | — |
| Utilities | 2 | AppLogger, SessionNameFormatter |
| Protocols | 1 | — |
| Entry point | 2 | TrainSwiftApp, ContentView |
| **Total** | **~114** | — |

### 11.2 Bundled Resources

| File | Size | Purpose |
|---|---|---|
| `exercises.db` | 236 KB | SQLite exercise database |
| `constants.json` | 7.7 KB | Equipment mappings, experience levels, DB schema |
| `split_templates.json` | 9.2 KB | Workout split templates |
| `bunny_video_library.json` | 112 KB | Video metadata (229 entries) |
| `Fire.json` | 24 KB | Lottie streak flame animation |
| `Localizable.xcstrings` | 23.6 KB | 1,533 localization strings |
| Equipment images (166 PNGs) | ~584 MB total | Exercise equipment photos |
| Onboarding videos (2 .mp4) | — | Value prop videos |
| App icon | 1024×1024 PNG | Light/dark/tinted variants |
| Screenshots (4) | — | App Store screenshots |

---

## 12. Summary for Competitive Analysis

**What train. is**: A questionnaire-driven, offline-first iOS strength training app that generates personalized 8-week programs from a 229-exercise database. It emphasizes automated progression detection (PBs), gamification (39 milestones, streak tracking), and low-friction workout logging with rest timers and demo videos.

**Strongest differentiators**:
1. Deep equipment-aware program generation (60 equipment items × user availability)
2. Injury contraindication system (39 rules auto-exclude unsafe exercises)
3. Exercise progression/regression chains (each exercise links to harder/easier variants)
4. 229 exercises with 1:1 video mapping via CDN streaming
5. Live Activity support (Dynamic Island workout tracking)

**Biggest competitive gaps**:
1. No Apple Watch companion
2. No cloud sync / cross-device
3. No social features
4. No 1RM/RPE/periodization (common in powerlifting apps)
5. No custom program builder
6. No AI coaching despite brand name suggesting it ("trAIn")
7. Single language (English only)
8. Paywall currently bypassed — no revenue

**Current monetization state**: Infrastructure ready (StoreKit 2, 3 tiers) but disabled for MVP. No active revenue stream.
