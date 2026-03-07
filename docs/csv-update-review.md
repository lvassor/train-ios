# CSV Update Review — Commit 5bf6c56

**Date:** 2026-03-06
**Commit:** `5bf6c566` — "Implement 33 CSV updates: UI consistency, content, data layer, dashboard redesign"
**Files changed:** 19 (+492 / -224)

---

## 1. Spelling — British to US English

| Location | Old | New |
|---|---|---|
| DashboardCarouselView.swift | "prioritised" | "prioritized" |
| ProgramGenerator.swift | "Generating personalised program" | "Generating personalized program" |
| ProgramReadyView.swift | "Your personalised plan is complete" | "Your personalized plan is complete" |
| ProgramReadyView.swift | "Prioritised Muscle Groups" | "Prioritized Muscle Groups" |
| QuestionnaireSteps.swift | "Any muscle groups you want to prioritise?" | "Any muscle groups you want to prioritize?" |
| HealthProfileStepView.swift | "most accurate personalised workouts" | "most accurate personalized workouts" |

---

## 2. Typography — Question Titles Bumped

All questionnaire step titles changed from `.trainTitle2` (~22pt) to `.trainTitle` (~28pt).

| Step | Title Text |
|---|---|
| NameStepView | "What shall we call you?" |
| GenderStepView | "Gender" |
| AgeStepView | "Date of Birth" |
| HeightStepView | "Height" |
| WeightStepView | "Weight" |
| GoalsStepView | "What are your primary goals?" |
| MuscleGroupsStepView | "Any muscle groups you want to prioritize?" |
| ExperienceStepView | "How confident do you feel in the gym?" |
| MotivationStepView | "Why have you considered using this app?" |
| TrainingPlaceStepView | "Where do you exercise?" |
| EquipmentStepView | "What equipment do you have available?" |
| TrainingDaysStepView | "How many days per week..." |
| SplitSelectionStepView | "Choose your training split" |
| SessionDurationStepView | "How long can you spend training?" |
| InjuriesStepView | "Do you have any injuries?" |
| HealthProfileStepView | "Body Stats" |
| HeightWeightStepView | "Height & Weight" |

---

## 3. Shimmer Animation

| Property | Old | New |
|---|---|---|
| Duration | 2.5s | 4.2s |
| Repeat | `.repeatForever(autoreverses: false)` | Plays once (no repeat) |

---

## 4. Welcome View Changes

| Element | Old | New |
|---|---|---|
| Subtitle copy | "Train uses programming and training principles from professional personal trainers..." | "Train uses training principles from professional personal trainers..." |
| Carousel caption | Positioned above carousel | Moved below carousel |
| Carousel card width | `containerWidth * 0.45` | `containerWidth * 0.40` (more peek of adjacent cards) |
| Carousel top padding | 22pt | 16pt |
| Sign-in button style | Plain white text | Peach border pill (`trainHover` stroke, `CornerRadius.pill`) |

---

## 5. Welcome Interstitial (New)

| Property | Value |
|---|---|
| Trigger | After name step (step 1), before advancing to step 2 |
| Content | "Welcome aboard, {name}" with radial glow pulse |
| Glow animation | Scale 0.3 -> 2.5, opacity 0.0 -> 0.6 over 1.2s ease-out |
| Auto-dismiss | After 2.5 seconds |
| Manual dismiss | Tap anywhere |
| Replaced | Inline "Nice to meet you, {name}!" text on step 2 (removed) |

---

## 6. Selection Card Tick Consistency

All selection cards now use a **top-right `checkmark.circle.fill` overlay** instead of inline checkmarks.

| Component | Old | New |
|---|---|---|
| MultiSelectCard | Inline `checkmark.square.fill` / `square` icon in HStack (left side) | Top-right overlay `checkmark.circle.fill` with `trainPrimary` circle background, offset (-8, 8) |
| TrainingPlaceStepView | Inline `checkmark.circle.fill` in HStack (right side, `.title2`) | Top-right overlay `checkmark.circle.fill` (20pt) with primary circle, offset (-8, 8) |
| InjuriesStepView | No checkmark indicator | Top-right overlay `checkmark.circle.fill` (16pt) with primary circle, offset (-6, 6) |
| EquipmentGroupSection | Partial select icon: `minus` | Partial select icon: `ellipsis` |

---

## 7. Gym Type Descriptions

| Gym Type | Old Description | New Description |
|---|---|---|
| Large Gym | "Full commercial gym with all equipment" | "Full commercial gym with all equipment (barbells, cables, machines, dumbbells)" |
| Small Gym | "Smaller gym with essential equipment" | "Smaller gym with essential equipment (dumbbells, barbells, some machines)" |
| Garage Gym | "Home/garage gym with basic equipment" | "Home/garage gym with basic equipment (dumbbells, kettlebells, bodyweight)" |

---

## 8. Equipment Data Layer — Exercise Counts from DB

| Property | Old | New |
|---|---|---|
| Exercise count labels | Hardcoded strings ("Unlocks 30+ exercises", etc.) | Dynamic DB query via `ExerciseDatabaseManager.exerciseCount(forCategories:)` |
| New methods | — | `exerciseCount(forCategory:)` and `exerciseCount(forCategories:)` on `ExerciseDatabaseManager` |

---

## 9. Equipment Description Column

| Layer | Old | New |
|---|---|---|
| `equipment_prod.csv` | 4 columns: `equipment_id,category,name,image_filename` | 5 columns: `equipment_id,category,name,image_filename,description` |
| `create_database_prod.py` | No `description` column in DDL or INSERT | `description TEXT` column added, inserted from CSV |
| `DBEquipment` model | No `description` property | `let description: String?` added |
| `exercises.db` | 241,664 bytes | 245,760 bytes |

All 61 equipment items now have human-readable descriptions (e.g. "A long steel bar (typically 20kg/45lbs) loaded with weight plates...").

---

## 10. Equipment Info Button & Attachment Naming

| Property | Old | New |
|---|---|---|
| `EquipmentCard` | No info button | Optional `onInfoTapped` closure; shows `info.circle` icon next to name |
| `EquipmentInfoModal` | Uses hardcoded `equipmentName` / `equipmentDescription` | Accepts optional `dbDescription` and `dbName` overrides from DB |
| Attachment items display name | Raw DB name (e.g. "Straight Bar") | Appended " attachment" suffix (e.g. "Straight Bar attachment") |

---

## 11. Muscle Groups Spacing & Transition Fix

| Element | Old | New |
|---|---|---|
| MuscleSelector outer VStack spacing | `Spacing.md` (16pt) | `Spacing.sm` (8pt) |
| CompactMuscleSelector front/back VStack spacing | `Spacing.xs` (4pt) | `Spacing.xxs` (2pt) |
| CompactMuscleSelector | No `.drawingGroup()` | `.drawingGroup()` added (fixes transition glitches) |

---

## 12. Training Days Spacing & Recovery Wording

| Element | Old | New |
|---|---|---|
| Outer VStack spacing | `Spacing.xl` (32pt) | 22pt (custom) |
| Slider vertical padding | `Spacing.md` (16pt) | `Spacing.smd` (12pt) |
| Warning message | "...in order for your brain to learn new movements and for your body to recover properly" | "...to allow sufficient recovery." |

---

## 13. Auth Buttons — Peach Border Pill Style

All login/signup buttons unified to peach border pill style:

| Button | Old Style | New Style |
|---|---|---|
| Log in with Apple | White fill, black text, `CornerRadius.md` | Clear fill, `trainHover` text, `CornerRadius.pill` border stroke |
| Log in with Google | White fill, black text, `CornerRadius.md` | Clear fill, `trainHover` text, `CornerRadius.pill` border stroke |
| Continue with Email | `trainPrimary` fill, white text, `CornerRadius.md` | Clear fill, `trainHover` text, `CornerRadius.pill` border stroke, envelope icon added |
| Create an Account | `trainPrimary` stroke, `CornerRadius.md` | `trainHover` stroke, `CornerRadius.pill` |
| Sign up with Apple | White fill, black text | `trainHover` border pill |
| Sign up with Google | White fill, black text | `trainHover` border pill |
| Sign up with Email | `trainPrimary` fill, white text | `trainHover` border pill |
| Email sheet cancel button | Text "Cancel" | Circular `xmark` icon with `ultraThinMaterial` background |

---

## 14. Unit Toggles — Peach Border Style

Height and weight unit toggles (cm/ft, kg/lbs):

| State | Old | New |
|---|---|---|
| Selected | `trainPrimary` background, white text | `trainPrimary` background, white text (unchanged) |
| Unselected | `trainTextSecondary.opacity(0.15)` background, secondary text | Clear background, `trainHover` text, `trainHover` capsule stroke (1.5pt) |

---

## 15. Apple Health Button & Injuries Wording

| Element | Old | New |
|---|---|---|
| Apple Health button width | `.frame(maxWidth: .infinity)` (full width) | `.padding(.horizontal, Spacing.lg)` (intrinsic width with padding) |
| Simulator hint text | "(Limited in simulator)" caption shown conditionally | Removed |
| Simulator background color | `trainTextSecondary.opacity(0.3)` when simulator | Always `trainHover` |
| Injuries subtitle | "We'll avoid exercises that might aggravate these areas" | "We will flag any exercises that might aggravate these areas" |

---

## 16. Content Copy Changes

| Location | Old | New |
|---|---|---|
| GoalsStepView "Build Muscle Mass" subtitle | "Both size and definition" | "Develop size and definition" |
| SessionDurationStepView title | "How long can you spend per session?" | "How long can you spend training?" |
| ProgramReadyView "Full body" fallback | "Full body" | "Full Body" (title case) |

---

## 17. Legal — Auto-Dated T&C / Privacy, PAR-Q, Professional Indemnity

### Privacy Policy
| Property | Old | New |
|---|---|---|
| Last Updated | "December 2024" (hardcoded) | Dynamic: `Date().formatted(.dateTime.month(.wide).year())` |
| Section 1 | Generic collection statement | Expanded: lists specific data types collected |
| Section 2 | Generic usage statement | Added: "We do not use your data for advertising purposes" |
| Section 3 | Generic sharing statement | Added: "or as required by law" |
| Section 4 | Generic security statement | Added: "All data is encrypted in transit and at rest" |
| New Section 5 | — | "Data Retention" section added |
| Section 6 (was 5) | Generic privacy rights | Added GDPR rights (portability, restrict processing) |
| Sections 7-9 | Numbered 6-8 | Renumbered to accommodate new section |

### Terms & Conditions
| Property | Old | New |
|---|---|---|
| Last Updated | "December 2024" (hardcoded) | Dynamic: `Date().formatted(.dateTime.month(.wide).year())` |
| Section 2 | Generic service description | Added: "designed by qualified personal trainers; however, it does not replace individual assessment" |
| New Section 4 | — | "Physical Activity Readiness" (PAR-Q guidelines): heart condition, dizziness, bone/joint problems, medication, pregnancy |
| Section 5 (was 4) | Basic health disclaimer | Expanded: lists specific risks (muscle strains, joint injuries, cardiovascular events); injury flag advisory |
| New Section 6 | — | "Professional Indemnity": no trainer-client relationship, exercises at own risk, no liability accepted |
| Sections 7-14 | Numbered 5-12 | Renumbered to accommodate new sections |

---

## 18. Dashboard Changes

| Element | Old | New |
|---|---|---|
| Top header | `TopHeaderView()` rendered at top of scroll content | Removed from scroll content (marked as Legacy) |
| Program summary card | Not present | New `ProgramSummaryCard` view: shows program type, days/week, total weeks with chevron tap-to-navigate |
| Profile access | Via `TopHeaderView` (if any) | Toolbar trailing `person.circle` button opening `ProfileView` sheet |

---

## 19. Program Ready View — Personalized Subtitle

| Property | Old | New |
|---|---|---|
| Subtitle text | "Your personalised plan is complete" (always) | If name provided: "Your program is ready to use, {name}!"; if empty: "Your personalized plan is complete" |

---

## 20. Questionnaire View — Scroll & Fade Adjustments

| Property | Old | New |
|---|---|---|
| Content top padding | `Spacing.md` (16pt) | `Spacing.sm` (8pt) |
| Top edge fade | 16pt | 8pt |
