![trAIn Logo](Assets/app-logo-primary.png)

# trAIn - Complete App Documentation

**Version:** 1.0 (MVP)
**Platform:** iOS
**Founders:** Brody Bastiman & Luke Vassor

---

## Table of Contents

1. [App Overview](#1-app-overview)
2. [Welcome & Authentication](#2-welcome--authentication)
3. [Questionnaire](#3-questionnaire)
4. [Program Generation](#4-program-generation)
5. [Dashboard](#5-dashboard)
6. [Workout Session](#6-workout-session)
7. [Exercise Logger](#7-exercise-logger)
8. [Profile & Account](#8-profile--account)
9. [Library & Resources](#9-library--resources)
10. [Navigation Flow](#10-navigation-flow)
11. [Data Models](#11-data-models)
12. [Design System](#12-design-system)

---

## 1. App Overview

trAIn is an AI-powered fitness training app that generates personalized workout programs based on user questionnaire responses. The app guides users through a structured onboarding flow, creates a tailored training program, and provides workout logging with performance tracking.

### Core Features
- 12-question personalized questionnaire
- AI-generated training programs (Full Body, Upper/Lower, Push/Pull/Legs)
- Per-set workout logging with rest timers
- Exercise swap functionality during workouts
- Progress tracking and workout history
- Exercise library with demos

---

## 2. Welcome & Authentication

### 2.1 Welcome Screen
**File:** `WelcomeView.swift`

**Display:**
- App title: "train." (64pt bold, orange primary color)
- Tagline: "built for you"
- Dark gradient background

**Interactions:**
| Element | Action | Navigation |
|---------|--------|------------|
| "Get Started" button | Tap | → Questionnaire (Section 1 Cover) |
| "log in" link | Tap | → Login Screen |

---

### 2.2 Login Screen
**File:** `LoginView.swift`

**Display:**
- Header: "trAIn" (48pt)
- Tagline: "Your AI-Powered Training Partner"
- Email input field
- Password input field
- Password hint: "Must be at least 6 characters"
- Error message area (when validation fails)

**Input Fields:**
| Field | Type | Validation |
|-------|------|------------|
| Email | Text | Must contain "@" and "." |
| Password | Secure | Minimum 6 characters |

**Interactions:**
| Element | Action | Result |
|---------|--------|--------|
| "Log In" button | Tap (valid form) | Authenticates user → Dashboard |
| "Log In" button | Tap (invalid) | Shows error message |
| "Sign Up" link | Tap | Opens Sign Up sheet |
| "Forgot Password?" | Tap | (Disabled in MVP) |

**Button States:**
- Disabled: When email or password fields are empty
- Enabled: When both fields have content

---

### 2.3 Sign Up Screen (Standalone)
**File:** `SignupView.swift`

**Display:**
- Title: "Create Account"
- Tagline: "Start your fitness journey today"
- X close button (top-right)
- Email input field
- Password input field with "6+ characters" hint
- Confirm Password input field

**Input Fields:**
| Field | Validation |
|-------|------------|
| Email | Must contain "@" and "." |
| Password | Minimum 6 characters |
| Confirm Password | Must match Password |

**Interactions:**
| Element | Action | Result |
|---------|--------|--------|
| "Create Account" button | Tap (valid) | Creates account → Closes sheet |
| X button | Tap | Closes sheet |

---

## 3. Questionnaire

**File:** `QuestionnaireView.swift`, `QuestionnaireSteps.swift`

The questionnaire consists of 12 questions across 2 sections, with section cover pages introducing each section.

### 3.0 Questionnaire Structure

**Progress Tracking:**
- Progress bar appears only on question pages (not covers)
- Progress calculated: `currentStep / totalStepsInSection`

**Navigation:**
- Back button (chevron left) at top-left of every page
- "Continue" button advances to next step
- Final question shows "Generate Your Program" button

---

### 3.1 Section 1 Cover: Availability
**Display:**
- Section number: "Section 1"
- Title: "Availability"
- Description: Overview of what Section 1 covers

**Interactions:**
| Element | Action | Navigation |
|---------|--------|------------|
| "Continue" button | Tap | → Question 1 (Goals) |
| Back button | Tap | → Welcome Screen |

---

### 3.2 Question 1: Primary Goals
**File:** `GoalsStepView`

**Display:**
- Title: "What are your primary goals?"
- Subtitle: "Let's customise your training programme"

**Options (Single Select):**
| Option | Description |
|--------|-------------|
| "Get Stronger" | "Build maximum strength & power" |
| "Build Muscle Mass" | "Both size and definition" |
| "Tone Up" | "Lose fat while building muscle" |

**Interactions:**
- Tap option card to select (radio button behavior)
- Only one option can be selected at a time
- Previously selected option deselects when new option chosen

**Validation:** Must select one option to continue

**Data Stored:** `questionnaireData.primaryGoal` → `"get_stronger"`, `"build_muscle"`, or `"tone_up"`

---

### 3.3 Question 2: Target Muscle Groups
**File:** `MuscleGroupsStepView`

**Display:**
- Title: "Any muscle groups you want to prioritise?"
- Subtitle: "Optional - tap on the body to select up to 3"
- Interactive body diagram (CompactMuscleSelector)
- Selected muscles shown as tags below diagram
- Selection count: "Selected: X of 3"

**Options (Multi-Select, Max 3):**
Available muscle groups displayed on interactive body:
- Chest, Back, Shoulders
- Biceps, Triceps, Forearms
- Abs, Obliques
- Quads, Hamstrings, Glutes, Calves

**Interactions:**
| Element | Action | Result |
|---------|--------|--------|
| Body region | Tap | Toggles muscle selection (if under limit) |
| Selected muscle tag | Tap | Deselects that muscle |
| Front/Back toggle | Tap | Switches body view |

**Validation:** Optional - can proceed with 0-3 selections

**Data Stored:** `questionnaireData.targetMuscleGroups` → `["chest", "back", ...]`

---

### 3.4 Question 3: Experience Level
**File:** `ExperienceStepView`

**Display:**
- Title: "How confident do you feel in the gym?"
- Subtitle: "This helps us match exercises to your comfort level"

**Options (Single Select):**
| Option | Description | Maps To |
|--------|-------------|---------|
| "Just Starting Out" | "New to the gym or never tried strength training..." | `0_months` |
| "Finding My Feet" | "You've tried a few things but still figuring it out..." | `0_6_months` |
| "Getting Comfortable" | "You know your way around the gym and feel fairly confident..." | `6_months_2_years` |
| "Confident & Consistent" | "You train regularly and feel confident..." | `2_plus_years` |

**Interactions:**
- Tap option card to select
- Single selection only

**Validation:** Must select one option

**Data Stored:** `questionnaireData.experienceLevel`

---

### 3.5 Question 4: Equipment Available
**File:** `EquipmentStepView`

**Display:**
- Title: "What equipment do you have available?"
- Subtitle: "Select all that apply"

**Simple Equipment (Multi-Select):**
| Equipment | Icon |
|-----------|------|
| Dumbbells | Dumbbell icon |
| Kettlebells | Kettlebell icon |
| Cable Machines | Cable icon |

**Expandable Equipment (Multi-Select with Sub-Items):**

| Category | Sub-Items | Info Modal |
|----------|-----------|------------|
| Barbells | Squat Rack, Flat Bench, Incline Bench, Decline Bench | Shows barbell equipment description |
| Pin-loaded Machines | Leg Press, Leg Extension, Lying Leg Curl, Seated Leg Curl, Standing Calf Raise, Seated Calf Raise, Hip Abduction, Hip Adduction, Lat Pulldown, Seated Row, Chest Press, Pec Deck | Shows machine description |
| Plate-loaded Machines | Leg Press, Hack Squat, Leg Extension, Lying Leg Curl, Standing Calf Raise, T-Bar Row, Chest Supported Row | Shows machine description |

**Interactions:**
| Element | Action | Result |
|---------|--------|--------|
| Simple equipment card | Tap | Toggles selection |
| Expandable category | Tap | Expands/collapses sub-items |
| Sub-item | Tap | Toggles sub-item selection |
| Info icon (ⓘ) | Tap | Opens equipment info modal |
| Category checkbox | Tap | Selects/deselects all sub-items |

**Equipment Info Modals:**
- Show equipment icon, name, and detailed description
- "Close" button dismisses modal

**Visual States:**
- Unselected: Grey outline
- Selected: Orange fill/highlight
- Mixed (some sub-items selected): Partial indicator

**Validation:** Must select at least 1 equipment category

**Data Stored:**
- `questionnaireData.equipmentAvailable` → `["dumbbells", "barbells", ...]`
- `questionnaireData.detailedEquipment` → `{"barbells": ["squat_rack", "flat_bench"], ...}`

---

### 3.6 Question 5: Injuries/Limitations
**File:** `InjuriesStepView`

**Display:**
- Title: "Do you have any current injuries that might impact your training?"
- Subtitle: "These can be updated at a later date"

**Options (Multi-Select Grid + Special Option):**

| Row 1 | Row 2 |
|-------|-------|
| Chest | Shoulders |
| Back | Triceps |
| Biceps | Abs |
| Quads | Hamstrings |
| Glutes | Calves |

| Full Width Option |
|-------------------|
| "No injuries or limitations" |

**Interactions:**
| Element | Action | Result |
|---------|--------|--------|
| Body part card | Tap | Toggles selection |
| "No injuries" button | Tap | Clears all selections, selects "none" |
| Any body part (if "none" selected) | Tap | Deselects "none", selects body part |

**Validation:** Optional - can proceed with any selection state

**Data Stored:** `questionnaireData.injuries` → `["chest", "back", ...]` or `[]`

---

### 3.7 Question 6: Training Days
**File:** `TrainingDaysStepView`

**Display:**
- Title: "How many days per week would you like to commit to strength training?"
- Subtitle: "Be realistic with your commitment"
- Large number display: "X days per week" (56pt)
- Horizontal slider (1-6 range)
- "Recommended" bracket based on experience level

**Recommended Ranges:**
| Experience Level | Recommended Days |
|------------------|------------------|
| Just Starting Out | 2-4 days |
| Finding My Feet | 2-4 days |
| Getting Comfortable | 3-5 days |
| Confident & Consistent | 3-5 days |

**Interactions:**
| Element | Action | Result |
|---------|--------|--------|
| Slider | Drag | Changes day count |
| Slider track | Tap | Jumps to tapped position |

**Validation:** Must select 2-6 days (minimum 2 required)

**Data Stored:** `questionnaireData.trainingDaysPerWeek` → `2-6`

---

### 3.8 Question 7: Session Duration
**File:** `SessionDurationStepView`

**Display:**
- Title: "How long can you spend per session?"
- Subtitle: "This affects the number of exercises in your programme"

**Options (Single Select):**
| Option | Description |
|--------|-------------|
| "30-45 minutes" | "Quick and efficient" |
| "45-60 minutes" | "Balanced approach" |
| "60-90 minutes" | "Maximum volume" |

**Interactions:**
- Tap option card to select
- Single selection only

**Validation:** Must select one option

**Data Stored:** `questionnaireData.sessionDuration` → `"30-45 min"`, `"45-60 min"`, or `"60-90 min"`

---

### 3.9 Question 8: Motivation
**File:** `MotivationStepView`

**Display:**
- Title: "Why have you considered using this app?"
- Subtitle: "Select all that apply"

**Options (Multi-Select):**
| Option |
|--------|
| "I lack structure in my workouts" |
| "I need more guidance" |
| "I lack confidence when I exercise" |
| "I need motivation" |
| "I need accountability" |
| "Other" → reveals text field |

**Interactions:**
| Element | Action | Result |
|---------|--------|--------|
| Option card | Tap | Toggles selection (checkbox behavior) |
| "Other" option | Tap | Reveals text input field |
| Other text field | Type | Captures custom motivation |

**Validation:**
- At least 1 option must be selected
- If "Other" is selected, text field must have content

**Data Stored:**
- `questionnaireData.motivations` → `["structure", "guidance", ...]`
- `questionnaireData.motivationOther` → custom text (if provided)

---

### 3.10 Section 2 Cover: About You
**Display:**
- Section number: "Section 2"
- Title: "About You"
- Description: Overview of what Section 2 covers

**Interactions:**
| Element | Action | Navigation |
|---------|--------|------------|
| "Continue" button | Tap | → Question 9 (Gender) |
| Back button | Tap | → Question 8 |

---

### 3.11 Question 9: Gender
**File:** `GenderStepView`

**Display:**
- Title: "Gender"
- Subtitle: "We may require this for exercise prescription"

**Options (Single Select with Icons):**
| Option | Icon |
|--------|------|
| Male | Male symbol |
| Female | Female symbol |
| Other/Prefer not to say | Neutral symbol |

**Interactions:**
- Tap option card to select
- Single selection only

**Validation:** Must select one option

**Data Stored:** `questionnaireData.gender` → `"male"`, `"female"`, or `"other"`

---

### 3.12 Question 10: Date of Birth
**File:** `AgeStepView`

**Display:**
- Title: "Date of Birth"
- Subtitle: "This helps us tailor your training intensity"
- Calculated age display: "XX years old" (56pt number)
- Wheel-style DatePicker

**Interactions:**
| Element | Action | Result |
|---------|--------|--------|
| DatePicker wheel | Scroll | Changes date, updates age display |

**Validation:**
- Must be 18+ years old
- Error message shown if under 18: "You must be at least 18 years old"
- Maximum age: 100 years

**Data Stored:** `questionnaireData.dateOfBirth` → Date object

---

### 3.13 Question 11: Height
**File:** `HeightStepView`

**Display:**
- Title: "Height"
- Subtitle: "This helps us calculate your body metrics"
- Unit toggle: "cm" | "ft·in"
- SlidingRuler input
- Height display in selected unit

**Unit Modes:**
| Unit | Range | Display Format |
|------|-------|----------------|
| Centimeters | 120-220 cm | "170 cm" |
| Feet/Inches | 3-8 ft | "5 ft 7 in" |

**Interactions:**
| Element | Action | Result |
|---------|--------|--------|
| Unit toggle | Tap | Switches between cm and ft/in |
| SlidingRuler | Drag | Changes height value |

**Default Values:**
- Centimeters: 170 cm
- Feet/Inches: 5 ft 7 in

**Validation:** Height must be within valid range for selected unit

**Data Stored:**
- `questionnaireData.heightCm` → Double
- `questionnaireData.heightFt` → Int
- `questionnaireData.heightIn` → Int
- `questionnaireData.heightUnit` → `.cm` or `.ftIn`

---

### 3.14 Question 12: Weight
**File:** `WeightStepView`

**Display:**
- Title: "Weight"
- Subtitle: "This helps us calculate your body metrics"
- Unit toggle: "kg" | "lbs"
- SlidingRuler input
- Weight display in selected unit

**Unit Modes:**
| Unit | Range | Display Format |
|------|-------|----------------|
| Kilograms | 30-200 kg | "70 kg" |
| Pounds | 60-440 lbs | "154 lbs" |

**Interactions:**
| Element | Action | Result |
|---------|--------|--------|
| Unit toggle | Tap | Switches between kg and lbs |
| SlidingRuler | Drag | Changes weight value |

**Default Values:**
- Kilograms: 70 kg
- Pounds: 154 lbs

**Validation:** Weight must be within valid range for selected unit

**Data Stored:**
- `questionnaireData.weightKg` → Double
- `questionnaireData.weightLbs` → Double
- `questionnaireData.weightUnit` → `.kg` or `.lbs`

---

### 3.15 Final Step: Generate Program

After Question 12, the "Continue" button changes to "Generate Your Program"

**Interactions:**
| Element | Action | Navigation |
|---------|--------|------------|
| "Generate Your Program" button | Tap | → Program Loading Screen |

---

## 4. Program Generation

### 4.1 Program Loading Screen
**File:** `ProgramLoadingView.swift`

**Display:**
- Rotating spinner (ProgressView, 1.5x scale)
- Title: "Building Your Program"
- Progress percentage: "0%" → "100%"
- Horizontal progress bar with orange gradient fill
- Animated checklist:

**Checklist Stages:**
| Stage | Text | Triggers At |
|-------|------|-------------|
| 1 | "Analysing your goals" | 0% (starts immediately) |
| 2 | "Selecting exercises" | 33% |
| 3 | "Structuring your program" | 66% |

**Stage States:**
- Pending: Grey text, empty circle
- In Progress: White text, spinner
- Completed: White text, green checkmark

**Animation:**
- Progress increments 1% every 50ms
- Total duration: ~5 seconds
- Stages animate in sequence

**On Completion:** Automatically navigates to Program Ready Screen

---

### 4.2 Program Ready Screen
**File:** `ProgramReadyView.swift`

**Display:**
- Success checkmark icon (80pt, in orange circle)
- Title: "Programme Ready!"
- Subtitle: "Your personalised plan is complete"
- Confetti animation overlay (colored particles)

**Program Info Cards (4 cards):**
| Card | Content |
|------|---------|
| Workout Split | Program type (e.g., "Push/Pull/Legs") |
| Prioritised Muscle Groups | Selected muscles or "Full body" |
| Frequency | "X days per week" |
| Session Length | Duration (e.g., "45-60 minutes") |

**Interactions:**
| Element | Action | Navigation |
|---------|--------|------------|
| "Start Training Now!" button | Tap | → Post-Questionnaire Sign Up |

---

### 4.3 Post-Questionnaire Sign Up
**File:** `PostQuestionnaireSignupView.swift`

**Display:**
- Title: "Create Your Account"
- Subtitle: "Start your training journey"
- Full Name input field
- Email input field
- Password input field
- Password hint: "Must be at least 6 characters"
- Terms checkbox: "I accept the Terms and Conditions"
- Error message area

**Input Fields:**
| Field | Validation |
|-------|------------|
| Full Name | Required (non-empty) |
| Email | Must contain "@" and "." |
| Password | Minimum 6 characters |
| Terms | Checkbox must be checked |

**Interactions:**
| Element | Action | Result |
|---------|--------|--------|
| "Sign Up" button | Tap (valid) | Saves questionnaire + program → Account Loading |
| "Sign Up" button | Tap (invalid) | Shows validation error |

**Critical Data Flow:**
On successful signup:
1. User account created in Core Data
2. Questionnaire data saved immediately
3. Generated program saved immediately
4. Navigates to Account Creation Loading

---

### 4.4 Account Creation Loading
**File:** `AccountCreationLoadingView.swift`

**Display:**
- Loading spinner
- Status text

**On Completion:**
- MVP: Skips paywall → Dashboard
- Production: → Paywall View → Dashboard

---

### 4.5 Program Generation Logic
**File:** `DynamicProgramGenerator.swift`

**Split Type Determination:**
| Days | Duration | Split Type |
|------|----------|------------|
| 2 | 30-45 min | Upper/Lower |
| 2 | 45-90 min | Full Body |
| 3 | Any | Push/Pull/Legs |
| 4 | Any | Upper/Lower |
| 5 | Any | Hybrid (PPL + Upper/Lower) |
| 6 | Any | Push/Pull/Legs x2 |

**Exercise Selection Considers:**
- User experience level (complexity filtering)
- Available equipment
- Injury contraindications
- Target muscle group priorities
- Session duration (exercise count)

---

## 5. Dashboard

**File:** `DashboardView.swift`

### 5.1 Header Section
**Display:**
- Greeting: "Hey, [FirstName]"
- Motivational message: "You're killing it this week!"
- (Streak counter - disabled in MVP)

---

### 5.2 Weekly Calendar
**Component:** `WeeklyCalendarView`

**Display:**
- 7-day week overview
- Day abbreviations (M, T, W, T, F, S, S)
- Session indicators for scheduled workout days
- Completed sessions highlighted in orange

---

### 5.3 Weekly Sessions Card
**Display:**
- Title: "Your Weekly Sessions"
- Progress: "X/Y complete"

**Session Selector Buttons:**
| State | Display |
|-------|---------|
| Collapsed | Abbreviations (P, Pu, L, U, Lo, FB) |
| Expanded | Full names ("Push Day", "Pull Day", etc.) |

**Session Abbreviations:**
| Abbreviation | Full Name |
|--------------|-----------|
| P | Push Day |
| Pu | Pull Day |
| L | Legs Day |
| U | Upper Body |
| Lo | Lower Body |
| FB | Full Body |

**Interactions:**
| Element | Action | Result |
|---------|--------|--------|
| Session button (incomplete) | Tap | Selects session, shows exercise list |
| Session button (complete) | Tap | Selects session, shows completion summary |
| Session selector area | Tap | Expands/collapses session names |

---

### 5.4 Exercise List (Incomplete Session)
**Display:**
- Vertical timeline format with orange nodes
- Connecting lines between nodes
- Each exercise shows:
  - Exercise name
  - Set × Rep prescription (e.g., "3 × 8-12")
  - Equipment badge (e.g., "Barbell")

**Interactions:**
| Element | Action | Navigation |
|---------|--------|------------|
| "Start Workout" button | Tap | → Workout Overview |

---

### 5.5 Completion Summary (Completed Session)
**Display:**
- "Workout Complete" badge with checkmark
- Completion date
- Duration
- Extra reps achieved
- Extra load achieved

**Interactions:**
| Element | Action | Navigation |
|---------|--------|------------|
| "View Completed Workout" button | Tap | → Session Log View |

---

### 5.6 Floating Toolbar
**Component:** `FloatingToolbar.swift`, `GlassTabBar.swift`

**Display:**
- Bottom floating pill-shaped bar
- Glass material effect with subtle border
- Sliding lens indicator (Apple Phone app style)

**Navigation Tabs:**
| Tab | Icon | Destination |
|-----|------|-------------|
| Dashboard | House | DashboardView |
| Milestones | Trophy | MilestonesView (sheet) |
| Library | Books | CombinedLibraryView (sheet) |
| Account | Person circle | ProfileView (sheet) |

**Interactions:**
| Element | Action | Result |
|---------|--------|--------|
| Tab button | Tap | Switches view / Opens sheet |
| Lens indicator | Animates | Slides to selected tab |

---

### 5.7 No Program State
**Display (if no program exists):**
- Warning icon
- Message: "No program found"
- "Log Out and Retry" button

---

## 6. Workout Session

### 6.1 Workout Overview
**File:** `WorkoutOverviewView.swift`

**Header:**
- X close button (cancel workout)
- Session name (e.g., "Push Day")
- Timer: "MM:SS" or "H:MM:SS" (elapsed time)

---

### 6.2 Warm-Up Card
**Display:**
- Label: "Suggested Warm-Up"
- Content: "Upper body mobility" (video placeholder)
- Duration: "5 min"

**Interactions:**
| Element | Action | Result |
|---------|--------|--------|
| "Begin" button | Tap | Starts 5-minute countdown timer |
| "Skip" button | Tap | Dismisses warm-up card |
| Timer (running) | Display | Shows countdown M:SS |
| Timer (complete) | Display | Shows "Complete" badge |

---

### 6.3 Exercise Overview Cards
**Display (per exercise):**
- Completion indicator (circle or checkmark)
- Exercise name
- Set × Rep prescription (e.g., "3 × 8-12")
- Equipment badge
- Swap button (arrow icon)
- Chevron right indicator

**Visual States:**
| State | Indicator | Name Style |
|-------|-----------|------------|
| Incomplete | Hollow circle | Normal text |
| Completed | Green checkmark | Strikethrough text |

**Interactions:**
| Element | Action | Result |
|---------|--------|--------|
| Exercise card | Tap | → Exercise Logger |
| Swap button | Tap | Opens Exercise Swap Carousel |

---

### 6.4 Exercise Swap Carousel
**Component:** `ExerciseSwapCarousel.swift`

**Display:**
- Horizontal scrolling carousel
- Alternative exercises for current exercise
- Each card shows exercise name and equipment

**Interactions:**
| Element | Action | Result |
|---------|--------|--------|
| Alternative exercise card | Tap | Replaces current exercise |
| Carousel | Swipe | Scrolls through alternatives |

---

### 6.5 Injury Warning Modal
**Display (when exercise targets injured muscle):**
- Warning icon
- Message: "This exercise targets [muscle], which may affect your [injury]. Proceed with caution or consider swapping."

**Interactions:**
| Element | Action | Result |
|---------|--------|--------|
| "Go Back" button | Tap | Returns to exercise list |
| "Continue" button | Tap | Opens Exercise Logger |

---

### 6.6 Complete Workout Button
**Display:**
- Bottom floating button
- Text: "Complete Workout"

**States:**
| State | Condition |
|-------|-----------|
| Disabled | 0 exercises completed |
| Enabled | 1+ exercises logged |

**Interactions:**
| Element | Action | Navigation |
|---------|--------|------------|
| "Complete Workout" button | Tap | → Workout Summary sheet |

---

### 6.7 Cancel Workout
**Interactions:**
| Element | Action | Result |
|---------|--------|--------|
| X button | Tap | Shows confirmation dialog |
| "Discard Workout" | Tap | Discards progress → Dashboard |
| "Continue Workout" | Tap | Dismisses dialog |

---

## 7. Exercise Logger

**File:** `ExerciseLoggerView.swift`

### 7.1 Header
**Display:**
- "Back" button with chevron
- Exercise position: "Exercise X/Y"
- Progress bar showing position in session

---

### 7.2 Tab Toggle
**Display:**
- Capsule-style toggle
- Two tabs with icons and labels

| Tab | Icon | Purpose |
|-----|------|---------|
| Logger | List icon | Log sets/reps/weights |
| Demo | Play icon | View exercise details |

---

### 7.3 Logger Tab

**Exercise Info Card:**
- Exercise name (24pt title)
- Equipment badge (icon + name)
- Target prescription: "X sets × Y-Z reps"

**Weight Unit Toggle:**
- Options: "kg" | "lbs"
- Persists selection across sets

**Set Logging Table:**

| Column | Content |
|--------|---------|
| Set | Set number (1, 2, 3...) |
| Reps | Numeric input field |
| Weight | Decimal input field |
| ✓ | Completion checkbox |

**Set Row States:**
| State | Appearance |
|-------|------------|
| Incomplete | Grey row |
| Completed | Orange highlighted row, checkmark |

**Interactions:**
| Element | Action | Result |
|---------|--------|--------|
| Reps field | Tap | Opens numeric keyboard |
| Weight field | Tap | Opens decimal keyboard |
| Completion checkbox | Tap | Marks set complete, triggers rest timer |
| Unit toggle | Tap | Switches kg/lbs |

---

### 7.4 Rest Timer
**Component:** `RestTimerView.swift`

**Display (inline at top of logging area):**
- Circular progress indicator
- Time remaining: "M:SS"
- "Rest" label
- X dismiss button

**Behavior:**
- Auto-triggers when set marked complete (if rest seconds configured)
- Countdown with circular progress animation
- Non-blocking (user can continue logging)

**Interactions:**
| Element | Action | Result |
|---------|--------|--------|
| X dismiss button | Tap | Stops timer early |
| Timer (natural completion) | - | Hides automatically |

---

### 7.5 Demo Tab
**Display:**
- Exercise name
- Exercise description
- Form cues / instructions
- Video placeholder (if available)
- Equipment required
- Primary/secondary muscles targeted

---

### 7.6 Submit Exercise Button
**Display:**
- Bottom floating button
- Text: "Submit Exercise"

**States:**
| State | Condition |
|-------|-----------|
| Disabled | 0 sets completed |
| Enabled | 1+ sets completed |

---

### 7.7 Feedback Modal
**Component:** `FeedbackModalOverlay`

**Display:**
- Title (varies by performance)
- Performance feedback message
- Color-coded background

**Title Variants:**
| Performance | Title |
|-------------|-------|
| Exceeded target | "Great Work!" |
| Met target | "Good Session" |
| Below target | "Keep Pushing" |

**Interactions:**
| Element | Action | Result |
|---------|--------|--------|
| "Edit" button | Tap | Returns to logger (edit sets) |
| "Continue" button | Tap | Marks complete → Workout Overview |

---

## 8. Profile & Account

**File:** `ProfileView.swift`

### 8.1 Profile Header
**Display:**
- Avatar (80pt circle with person icon)
- Email address (headline text)
- Member since date: "Member since [Month Year]"

---

### 8.2 Your Programme Card (Expandable)

**Collapsed State:**
- Title: "Your Programme"
- Split type and frequency preview

**Expanded State:**
- Split type with icon
- Session duration with icon
- Frequency with icon
- Priority muscles (visual muscle tags)

**Interactions:**
| Element | Action | Result |
|---------|--------|--------|
| Card header | Tap | Expands/collapses details |
| "Retake Quiz" button | Tap | Shows confirmation dialog |

**Retake Quiz Confirmation:**
- Message: "This will log you out and restart the questionnaire. Your current program will be replaced."
- "Cancel" → Dismisses dialog
- "Retake Quiz" → Logs out → Welcome Screen

---

### 8.3 Your Plan Card
**Display:**
- Title: "Your Plan"
- Plan type: "Annual Plan £99.99/year"
- Next billing date

**Interactions:**
| Element | Action | Result |
|---------|--------|--------|
| "Manage Subscription" button | Tap | Opens iOS App Store subscription settings |

---

### 8.4 Menu Items
| Item | State | Action |
|------|-------|--------|
| "Edit Profile" | Disabled (MVP) | - |
| "Log Out" | Enabled | Shows confirmation dialog |
| "Delete Account" | Disabled (MVP) | - |

**Log Out Confirmation:**
- Message: "Are you sure you want to log out?"
- "Cancel" → Dismisses dialog
- "Log Out" → Clears session → Welcome Screen

---

## 9. Library & Resources

### 9.1 Combined Library View
**File:** `CombinedLibraryView.swift`

**Display:**
- Sheet presentation (2/3 height)
- Drag indicator at top
- Tab toggle: "Exercises" | "Education"
- Search bar
- Glass lens effect on toolbar

**Interactions:**
| Element | Action | Result |
|---------|--------|--------|
| Tab toggle | Tap | Switches content type |
| Search bar | Type | Filters displayed items |
| Exercise item | Tap | → Exercise Detail View |
| Education item | Tap | → Video/Article View |
| Drag indicator | Drag down | Dismisses sheet |

---

### 9.2 Milestones View
**File:** `MilestonesView.swift`

**Display:**
- Sheet presentation
- Achievement cards
- Progress indicators

---

### 9.3 Session Log View
**File:** `SessionLogView.swift`

**Display:**
- Workout date
- Total duration
- List of exercises performed
- Sets, reps, weights for each exercise

---

## 10. Navigation Flow

### 10.1 New User Flow
```
Welcome Screen
    ↓ "Get Started"
Questionnaire Section 1 Cover
    ↓ "Continue"
Q1: Goals → Q2: Muscle Groups → Q3: Experience → Q4: Equipment
    → Q5: Injuries → Q6: Training Days → Q7: Session Duration → Q8: Motivation
    ↓ "Continue"
Questionnaire Section 2 Cover
    ↓ "Continue"
Q9: Gender → Q10: Date of Birth → Q11: Height → Q12: Weight
    ↓ "Generate Your Program"
Program Loading Screen (5 sec)
    ↓ (auto)
Program Ready Screen
    ↓ "Start Training Now!"
Post-Questionnaire Sign Up
    ↓ "Sign Up" (saves data)
Account Creation Loading
    ↓ (auto)
Dashboard
```

### 10.2 Returning User Flow
```
Welcome Screen
    ↓ "log in"
Login Screen
    ↓ "Log In"
Dashboard
```

### 10.3 Workout Flow
```
Dashboard
    ↓ "Start Workout"
Workout Overview
    ├─ Warm-up Card (optional)
    └─ Exercise Cards
        ↓ Tap exercise
    Exercise Logger
        ├─ Logger Tab (log sets)
        └─ Demo Tab (view form)
        ↓ "Submit Exercise"
    Feedback Modal
        ↓ "Continue"
    Workout Overview (updated)
        ↓ "Complete Workout"
    Workout Summary
        ↓ "Done"
Dashboard (session marked complete)
```

---

## 11. Data Models

### 11.1 QuestionnaireData
| Field | Type | Description |
|-------|------|-------------|
| `name` | String | User's full name |
| `email` | String | User's email |
| `gender` | String | "male", "female", "other" |
| `dateOfBirth` | Date | User's DOB |
| `heightCm` | Double | Height in centimeters |
| `heightFt` | Int | Height feet component |
| `heightIn` | Int | Height inches component |
| `heightUnit` | HeightUnit | .cm or .ftIn |
| `weightKg` | Double | Weight in kilograms |
| `weightLbs` | Double | Weight in pounds |
| `weightUnit` | WeightUnit | .kg or .lbs |
| `primaryGoal` | String | Selected fitness goal |
| `targetMuscleGroups` | [String] | 0-3 muscle groups |
| `experienceLevel` | String | Gym confidence level |
| `motivations` | [String] | Reasons for using app |
| `motivationOther` | String | Custom motivation text |
| `equipmentAvailable` | [String] | Equipment categories |
| `detailedEquipment` | [String: Set<String>] | Category → specific items |
| `trainingDaysPerWeek` | Int | 2-6 days |
| `sessionDuration` | String | Duration range |
| `injuries` | [String] | Current injuries |

### 11.2 Program
| Field | Type | Description |
|-------|------|-------------|
| `id` | String | Unique identifier |
| `type` | ProgramType | fullBody, upperLower, pushPullLegs |
| `daysPerWeek` | Int | Training frequency |
| `sessionDuration` | SessionDuration | short, medium, long |
| `sessions` | [ProgramSession] | Workout sessions |
| `totalWeeks` | Int | Program length (8) |
| `createdDate` | Date | Generation timestamp |

### 11.3 ProgramSession
| Field | Type | Description |
|-------|------|-------------|
| `id` | String | Unique identifier |
| `dayName` | String | "Push", "Pull", "Legs", etc. |
| `exercises` | [ProgramExercise] | Exercises in session |

### 11.4 ProgramExercise
| Field | Type | Description |
|-------|------|-------------|
| `id` | String | Unique identifier |
| `exerciseId` | String | Database exercise ID |
| `exerciseName` | String | Display name |
| `sets` | Int | Number of sets |
| `repRange` | String | Rep range (e.g., "8-12") |
| `restSeconds` | Int | Rest between sets |
| `primaryMuscle` | String | Target muscle |
| `equipmentType` | String | Required equipment |

### 11.5 LoggedSet
| Field | Type | Description |
|-------|------|-------------|
| `reps` | Int | Reps performed |
| `weight` | Double | Weight used (kg) |
| `completed` | Bool | Set completion status |

---

## 12. Design System

### 12.1 Colors
| Name | Usage |
|------|-------|
| trainPrimary | Orange - interactive elements, highlights |
| trainDark | Dark grey - backgrounds |
| trainLight | Light grey - secondary backgrounds |
| White | Primary text |
| White (60%) | Secondary text |

### 12.2 Typography
| Style | Size | Weight | Usage |
|-------|------|--------|-------|
| trainTitle | 28pt | Semibold | Screen titles |
| trainTitle2 | 24pt | Semibold | Section headers |
| trainHeadline | 20pt | Semibold | Card titles |
| trainSubtitle | 16pt | Regular | Subtitles |
| trainBody | 16pt | Regular | Body text |
| trainCaption | 14pt | Regular | Small labels |
| trainLargeNumber | 72pt | Bold | Hero numbers |
| trainMediumNumber | 48pt | Semibold | Age, stats |

### 12.3 Spacing
| Token | Value | Usage |
|-------|-------|-------|
| xs | 4pt | Small gaps |
| sm | 8pt | Compact padding |
| md | 16pt | Standard spacing |
| lg | 24pt | Card padding |
| xl | 32pt | Section spacing |
| xxl | 48pt | Major breaks |

### 12.4 Corner Radius
| Token | Value | Usage |
|-------|-------|-------|
| sm | 12pt | Small elements |
| md | 20pt | Standard cards |
| lg | 20pt | Large cards |
| xl | 40pt | Main containers |

### 12.5 Card Styles
| Style | Material | Usage |
|-------|----------|-------|
| glassCard | regularMaterial | Standard cards |
| warmGlassCard | ultraThinMaterial | Warm overlay cards |
| glassPremiumCard | thinMaterial | Premium content |
| glassButton | thinMaterial | Button backgrounds |

---

*Document generated for trAIn iOS App v1.0 (MVP)*
*Last updated: December 2024*
