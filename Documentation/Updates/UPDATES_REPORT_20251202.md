# trAIn iOS App - Updates Report
## December 2, 2025

---

## Color Palette Comparison

### Old Palette (Train Dark Mode - Gold)
| Role | Color | Hex |
|------|-------|-----|
| Primary | <span style="display:inline-block;width:16px;height:16px;background:#f1bc50;border-radius:3px;vertical-align:middle;"></span> Gold | `#f1bc50` |
| Primary Light | <span style="display:inline-block;width:16px;height:16px;background:#F5CD73;border-radius:3px;vertical-align:middle;"></span> Light Gold | `#F5CD73` |
| Primary Hover | <span style="display:inline-block;width:16px;height:16px;background:#F7D78F;border-radius:3px;vertical-align:middle;"></span> Very Light Gold | `#F7D78F` |
| Secondary/Text Secondary | <span style="display:inline-block;width:16px;height:16px;background:#f5c4a1;border-radius:3px;vertical-align:middle;"></span> Peach | `#f5c4a1` |

### New Palette (Train Dark Mode - Orange)
| Role | Color | Hex |
|------|-------|-----|
| Primary | <span style="display:inline-block;width:16px;height:16px;background:#f0aa3e;border-radius:3px;vertical-align:middle;"></span> Orange | `#f0aa3e` |
| Primary Light | <span style="display:inline-block;width:16px;height:16px;background:#f5c06a;border-radius:3px;vertical-align:middle;"></span> Light Orange | `#f5c06a` |
| Primary Hover | <span style="display:inline-block;width:16px;height:16px;background:#f8d08c;border-radius:3px;vertical-align:middle;"></span> Very Light Orange | `#f8d08c` |
| Secondary/Text Secondary | <span style="display:inline-block;width:16px;height:16px;background:#fce4be;border-radius:3px;vertical-align:middle;"></span> Cream | `#fce4be` |

---

## Implemented Changes

### 1. Color Palette Update
**Previous State:** App used a gold-toned accent color (<span style="display:inline-block;width:12px;height:12px;background:#f1bc50;border-radius:2px;vertical-align:middle;"></span> `#f1bc50`) with peach secondary text (<span style="display:inline-block;width:12px;height:12px;background:#f5c4a1;border-radius:2px;vertical-align:middle;"></span> `#f5c4a1`).

**New State:** App uses an orange-toned accent color (<span style="display:inline-block;width:12px;height:12px;background:#f0aa3e;border-radius:2px;vertical-align:middle;"></span> `#f0aa3e`) with cream secondary text (<span style="display:inline-block;width:12px;height:12px;background:#fce4be;border-radius:2px;vertical-align:middle;"></span> `#fce4be`). Theme can be toggled via `activeTheme` variable in ColorPalette.swift.

**Implementation:**
- Added new "Train Dark Mode Orange" palette to [ColorPalettes.json](../../trAInSwift/Components/ColorPalettes.json)
- Modified [ColorPalette.swift](../../trAInSwift/Components/ColorPalette.swift) with theme switching capability
- Primary, primaryLight, primaryHover, and textSecondary colors now dynamically switch based on `activeTheme`

---

### 2. Glow Effect Removal
**Previous State:** Selected buttons, option cards, and primary buttons had a gold glow/shadow effect (`shadow(color: Color.trainPrimary.opacity(0.4), radius: 16)`).

**New State:** All glow effects removed for a cleaner, more modern appearance.

**Implementation:** Removed shadow modifiers from:
- [ButtonStyles.swift](../../trAInSwift/Components/ButtonStyles.swift)
- [OptionCard.swift](../../trAInSwift/Components/OptionCard.swift)
- [MultiSelectCard.swift](../../trAInSwift/Components/MultiSelectCard.swift)
- [CustomButton.swift](../../trAInSwift/Components/CustomButton.swift)
- [QuestionnaireSteps.swift](../../trAInSwift/Views/QuestionnaireSteps.swift) (MuscleGroupButton, EquipmentCard, InjuriesStepView)
- [DashboardView.swift](../../trAInSwift/Views/DashboardView.swift) (Start Workout button, session bubbles)

---

### 3. Muscle Selector Animation Fix
**Previous State:** Switching between Male/Female or Front/Back views had a 0.2s fade animation that caused shapes to blend awkwardly during transition.

**New State:** Instant switching with no animation, providing cleaner visual feedback.

**Implementation:** Removed `withAnimation(.easeInOut(duration: 0.2))` wrappers in [MuscleSelector.swift](../../trAInSwift/Components/MuscleSelector/MuscleSelector.swift) for both MuscleSelector and CompactMuscleSelector views.

---

### 4. Muscle Selector Dynamic Sizing
**Previous State:** Muscle selector had fixed height of 550px, potentially overlapping with Continue button on smaller screens.

**New State:** Muscle selector uses GeometryReader to fill available space dynamically.

**Implementation:** Modified [QuestionnaireSteps.swift](../../trAInSwift/Views/QuestionnaireSteps.swift) MuscleGroupsStepView to use GeometryReader instead of fixed frame height.

---

### 5. Training Days Text Color
**Previous State:** "days" and "per week" text used secondary peach color.

**New State:** Both texts now use white color for better contrast.

**Implementation:** Changed `.foregroundColor(.trainTextSecondary)` to `.foregroundColor(.white)` in TrainingDaysStepView within [QuestionnaireSteps.swift](../../trAInSwift/Views/QuestionnaireSteps.swift).

---

### 6. Date of Birth Text Color
**Previous State:** "years old" text used secondary peach color.

**New State:** Uses white color for consistency with other labels.

**Implementation:** Changed `.foregroundColor(.trainTextSecondary)` to `.foregroundColor(.white)` in AgeStepView within [QuestionnaireSteps.swift](../../trAInSwift/Views/QuestionnaireSteps.swift).

---

### 7. Height/Weight Ruler Tint
**Previous State:** Ruler used `.trainPrimary` tint which was gold (<span style="display:inline-block;width:12px;height:12px;background:#f1bc50;border-radius:2px;vertical-align:middle;"></span>).

**New State:** Ruler tint automatically uses new orange color (<span style="display:inline-block;width:12px;height:12px;background:#f0aa3e;border-radius:2px;vertical-align:middle;"></span> `#f0aa3e`, RGB 240, 170, 62) as it references `.trainPrimary`.

**Implementation:** No code change needed - SlidingRuler already uses `.tint(.trainPrimary)` which dynamically resolves to the new orange color.

---

### 8. Dashboard Exercise Connector Line
**Previous State:** Timeline connector line used `Color.trainTimelineLine.opacity(0.3)`.

**New State:** Uses `Color.gray.opacity(0.3)` for a neutral light grey appearance.

**Implementation:** Updated timelineColor constant in ExerciseListView within [DashboardView.swift](../../trAInSwift/Views/DashboardView.swift).

---

### 9. Workout Logger Unit Toggle Border
**Previous State:** Unit toggle (kg/lbs) had no visible border.

**New State:** Unit toggle has a subtle white border (15% opacity) matching other toggle buttons.

**Implementation:** Added `.overlay(RoundedRectangle(...).stroke(Color.white.opacity(0.15), lineWidth: 1))` to unitToggle in [WorkoutLoggerView.swift](../../trAInSwift/Views/WorkoutLoggerView.swift).

---

### 10. Workout Overview Page (New Feature)
**Previous State:** Tapping "Start Workout" went directly to exercise-by-exercise logger.

**New State:** New workout overview page shows:
- Workout timer (MM:SS / HH:MM:SS format)
- Warm-up countdown section (5:00 with Begin/Skip buttons)
- All exercises in vertical scroll with completion indicators
- Equipment badges on each exercise card
- Swap button for each exercise
- Complete Workout button (enabled after 1+ exercise completed)

**Implementation:** Created new [WorkoutOverviewView.swift](../../trAInSwift/Views/WorkoutOverviewView.swift) with components:
- WorkoutOverviewHeader
- WarmUpCard
- ExerciseOverviewCard

---

### 11. Exercise Logger View (New Feature)
**Previous State:** Previous WorkoutLoggerView handled all exercises in sequence.

**New State:** New exercise-specific logger with:
- Logger/Demo tab toggle
- Set logging grid with weight unit toggle
- Rest timer overlay
- Submit Exercise button with Apple-style push notification feedback

**Implementation:** Created new [ExerciseLoggerView.swift](../../trAInSwift/Views/ExerciseLoggerView.swift) with components:
- ExerciseLoggerHeader
- ExerciseLoggerInfoCard
- SetLoggingSection
- SetInputRow
- RestTimerOverlay
- FeedbackModalOverlay

---

### 12. Injury Warnings
**Previous State:** No warning when user attempts exercise that may affect declared injuries.

**New State:** Central modal overlay warning appears when tapping exercise that targets muscle groups related to user's declared injuries. White card with:
- Bold title ("Injury Warning")
- Grey description text
- Two buttons side-by-side: grey "Go Back" button and orange "Continue" button

**Implementation:** Added InjuryWarningOverlay component and checkInjuryWarning() logic in [WorkoutOverviewView.swift](../../trAInSwift/Views/WorkoutOverviewView.swift). Modal styled as white card centered on screen with dimmed background.

---

### 13. Workout Timer
**Previous State:** Timer placeholder showed static "00:00".

**New State:** Live timer in MM:SS format, switching to HH:MM:SS after 60 minutes.

**Implementation:** Added timer logic with formatters in [WorkoutOverviewView.swift](../../trAInSwift/Views/WorkoutOverviewView.swift).

---

### 14. Central Modal Feedback Notification
**Previous State:** Traffic light colored prompts for workout feedback.

**New State:** Central modal overlay appears after submitting exercise with:
- White card background centered on screen
- Bold title (e.g., "Great Work!", "Good Session", "Keep Pushing")
- Grey description text with encouragement
- Two buttons side-by-side: grey "Edit" button and accent-colored "Continue" button
- Accent color matches feedback type (green for success, orange for warning, blue for info)

**Implementation:** Created FeedbackModalOverlay component in [ExerciseLoggerView.swift](../../trAInSwift/Views/ExerciseLoggerView.swift) with FeedbackType enum for color-coded responses.

---

### 15. Exercise Completion Behaviors
**Previous State:** All exercises shown the same way regardless of completion status.

**New State:**
- Completed exercises show: checkmark indicator, greyed/strikethrough text, subtle highlight background
- Uncompleted exercises show: hollow circle indicator, normal text, chevron for navigation

**Implementation:** Conditional styling in ExerciseOverviewCard within [WorkoutOverviewView.swift](../../trAInSwift/Views/WorkoutOverviewView.swift).

---

### 16. Workout Summary Page (New Feature)
**Previous State:** Simple "Workout Complete!" modal after finishing.

**New State:** Comprehensive summary showing:
- Duration, total sets, total reps stats
- Exercise-by-exercise results
- PB (Personal Best) rosette indicators
- Edit button to return and modify
- Done button to save and exit

**Implementation:** Created new [WorkoutSummaryView.swift](../../trAInSwift/Views/WorkoutSummaryView.swift) with components:
- StatItem
- ExerciseResultRow (with PB detection logic)

---

### 17. Bottom Navigation Toolbar Updates
**Previous State:**
- Glass card styling with `.warmGlassCard()`
- Icons: dumbbell (exercises), rosette (milestones), play (videos), person (account)

**New State:**
- Liquid glass effect using `.ultraThinMaterial` for more translucent scrolling effect
- Icons swapped: house (dashboard), rosette (milestones), dumbbell (exercise library), person (account)
- Subtle border overlay for definition

**Implementation:** Updated [FloatingToolbar.swift](../../trAInSwift/Components/FloatingToolbar.swift):
- Changed background from `.warmGlassCard()` to `.ultraThinMaterial`
- Updated ToolbarTab enum with new icons and labels
- Renamed callback parameters to match new functionality

---

## Files Modified

### Components
- `ColorPalette.swift` - Theme switching system
- `ColorPalettes.json` - New orange palette definition
- `ButtonStyles.swift` - Glow removal
- `OptionCard.swift` - Glow removal
- `MultiSelectCard.swift` - Glow removal
- `CustomButton.swift` - Glow removal
- `FloatingToolbar.swift` - Liquid glass + icon changes
- `MuscleSelector/MuscleSelector.swift` - Animation fix

### Views
- `QuestionnaireSteps.swift` - Color fixes, glow removal, dynamic sizing
- `DashboardView.swift` - Line color, glow removal, navigation updates
- `WorkoutLoggerView.swift` - Unit toggle border

### New Files
- `WorkoutOverviewView.swift` - New workout entry point
- `ExerciseLoggerView.swift` - New exercise logging UI
- `WorkoutSummaryView.swift` - New completion summary

---

### 18. Dashboard Calendar Updates
**Previous State:** Calendar circles were always empty (muted fill or orange ring for today).

**New State:**
- Day letters (M, T, W, T, F, S, S) displayed above circles (unchanged layout)
- Empty circles remain muted gray fill by default
- When a workout is logged for a date, the circle fills with accent color (<span style="display:inline-block;width:12px;height:12px;background:#f0aa3e;border-radius:2px;vertical-align:middle;"></span>) and displays session letter (P, Pu, L, etc.) in dark text
- Today (without workout) shows hollow orange ring
- Session letters: P=Push, Pu=Pull, L=Legs, U=Upper, Lo=Lower, FB=Full Body

**Implementation:** Updated [WeeklyCalendarView.swift](../../trAInSwift/Components/WeeklyCalendarView.swift):
- getWorkoutLetter() fetches completed sessions from Core Data by date
- Filled circles use dark text color for contrast on orange background
- Layout preserved: day letter above, circle below

---

### 19. Exercise Swap Carousel (New Feature)
**Previous State:** No ability to swap exercises during workout.

**New State:** Tap swap button on exercise card → carousel popup shows alternative exercises:
- PageTabViewStyle carousel
- Each card shows exercise name, muscle target, equipment
- "Select" button to confirm swap
- "Keep Current" to dismiss

**Implementation:** Created new [ExerciseSwapCarousel.swift](../../trAInSwift/Views/ExerciseSwapCarousel.swift):
- ExerciseSwapCarousel container view
- SwapOptionCard for each alternative
- Integrated into WorkoutOverviewView

---

### 20. Combined Exercise/Education Library (New Feature)
**Previous State:** Separate Exercise Library and Video Library views accessed via different navigation.

**New State:** Single combined library view with compact pill-style toolbar:
- Compact pill toolbar with search icon and tab toggle
- Search icon (magnifying glass) in circular button - tap to reveal search bar
- Two tabs: "Exercises" (dumbbell icon) and "Education" (book icon)
- Selected tab has transparent orange tint background
- Unselected tab has no background
- Tab container has subtle transparent pill background
- Exercise tab: Collapsible search bar, muscle/equipment filters, exercise list
- Education tab: Coming soon placeholder with book icon

**Implementation:** Created new [CombinedLibraryView.swift](../../trAInSwift/Views/CombinedLibraryView.swift):
- LibraryTab enum (exercises, education)
- Compact pill toolbar with search button and tab pills
- ExerciseLibraryContent with collapsible search bar
- EducationLibraryContent (placeholder)
- ExerciseRowCard, LibraryFilterSheet components

---

### 21. Bottom Nav Peek Behavior
**Previous State:** Tapping Library or Milestones pushed full navigation views.

**New State:** Library and Milestones open as sheets with peek behavior:
- Medium detent (half screen) by default
- Draggable to large (full screen)
- Background interaction enabled at medium detent
- Drag indicator visible

**Implementation:** Updated [DashboardView.swift](../../trAInSwift/Views/DashboardView.swift):
- Changed from navigationDestination to sheet presentation
- Added `.presentationDetents([.medium, .large])`
- Added `.presentationBackgroundInteraction(.enabled(upThrough: .medium))`
- Added `.presentationDragIndicator(.visible)`

---

## Files Modified

### Components
- `ColorPalette.swift` - Theme switching system
- `ColorPalettes.json` - New orange palette definition
- `ButtonStyles.swift` - Glow removal
- `OptionCard.swift` - Glow removal
- `MultiSelectCard.swift` - Glow removal
- `CustomButton.swift` - Glow removal
- `FloatingToolbar.swift` - Liquid glass + icon changes
- `MuscleSelector/MuscleSelector.swift` - Animation fix
- `WeeklyCalendarView.swift` - Collapsed day letters, workout population

### Views
- `QuestionnaireSteps.swift` - Color fixes, glow removal, dynamic sizing
- `DashboardView.swift` - Line color, glow removal, navigation updates, peek behavior
- `WorkoutLoggerView.swift` - Unit toggle border

### New Files
- `WorkoutOverviewView.swift` - New workout entry point
- `ExerciseLoggerView.swift` - New exercise logging UI
- `WorkoutSummaryView.swift` - New completion summary
- `ExerciseSwapCarousel.swift` - Exercise swap carousel popup
- `CombinedLibraryView.swift` - Combined library with toggle

---

## Summary

All 21 updates from the December 2, 2025 requirements have been implemented:

| # | Update | Status |
|---|--------|--------|
| 1 | Color palette (gold → orange) | ✅ |
| 2 | Glow effect removal | ✅ |
| 3 | Muscle selector animation fix | ✅ |
| 4 | Muscle selector dynamic sizing | ✅ |
| 5 | Training days text color | ✅ |
| 6 | Date of birth text color | ✅ |
| 7 | Height/weight ruler tint | ✅ |
| 8 | Dashboard connector line | ✅ |
| 9 | Unit toggle border | ✅ |
| 10 | Workout overview page | ✅ |
| 11 | Exercise logger view | ✅ |
| 12 | Injury warnings | ✅ |
| 13 | Workout timer | ✅ |
| 14 | Apple-style notifications | ✅ |
| 15 | Exercise completion behaviors | ✅ |
| 16 | Workout summary page | ✅ |
| 17 | Bottom nav toolbar updates | ✅ |
| 18 | Dashboard calendar updates | ✅ |
| 19 | Exercise swap carousel | ✅ |
| 20 | Combined library view | ✅ |
| 21 | Bottom nav peek behavior | ✅ |
| 22 | Library toolbar redesign | ✅ |
| 23 | Bottom nav toolbar enhancements | ✅ |
| 24 | UI polish fixes batch | ✅ |

---

### 22. Library Toolbar Redesign
**Previous State:** Full-width toggle bar with Exercises/Videos tabs, search bar always visible below.

**New State:** Compact pill-style toolbar inspired by modern iOS design:
- Search icon as separate circular button on the left
- Tab pills ("Exercises" and "Education") in a compact capsule container
- Tapping search icon expands inline search bar (replaces toolbar area)
- Search bar has circular X dismiss button on the right
- Tabs renamed from "Videos" to "Education" with book icon
- Selected tab shows transparent orange tint, unselected is clear
- Overall more compact and modern appearance

**Implementation:** Updated [CombinedLibraryView.swift](../../trAInSwift/Views/CombinedLibraryView.swift):
- Redesigned toolbar layout with HStack containing search button and tab pills
- Search bar expands inline replacing toolbar when search icon tapped
- Circular X button to dismiss search and return to tabs
- Renamed VideoLibraryContent to EducationLibraryContent
- Updated tab icons (book.fill for Education)

---

### 23. Bottom Navigation Toolbar Enhancements
**Previous State:** Toolbar icons had simple color change when selected (white to orange). Content was cut off above toolbar with dark region behind it.

**New State:**
- Selected icon has transparent orange tint background (capsule shape)
- Unselected icons are slightly muted white
- Content scrolls all the way to bottom of screen
- Toolbar floats over content with liquid glass distortion effect visible
- Toolbar shape changed from rounded rectangle to capsule for consistency

**Implementation:** Updated [FloatingToolbar.swift](../../trAInSwift/Components/FloatingToolbar.swift) and [DashboardView.swift](../../trAInSwift/Views/DashboardView.swift):
- Added capsule background with 15% orange tint for selected tab
- Changed toolbar container to capsule shape
- Moved toolbar to ZStack overlay so content scrolls behind
- Removed content cutoff spacer, replaced with bottom padding
- Content now visible through ultraThinMaterial glass effect

---

### 24. UI Polish Fixes Batch
**Multiple UI improvements and fixes applied:**

**1. Content Scrolling Behind Buttons**
- WorkoutSummaryView, WorkoutOverviewView, and WorkoutLoggerView now have content that scrolls all the way to the bottom
- Action buttons float over the content instead of creating a hard cutoff
- Content has padding at bottom for the floating button overlay

**2. Sheet Heights and Drag Indicators**
- All sheet presentations (Library, Milestones, Profile, Calendar) now open at 2/3 screen height
- All sheets have visible drag indicators (the little grey horizontal line)
- Sheets can be expanded to full screen by dragging up

**3. Account Settings Cleanup**
- Removed redundant "Done" button from the navigation toolbar
- Sheet can be dismissed by swiping down instead

**4. Warm-Up Card Redesign**
- Matches the exercise card design with video placeholder icon
- Shows "Suggested Warm-Up" section title above
- Displays "Upper body mobility • 5 min" with play icon
- Simplified Skip button on the right
- Removed countdown timer and Begin/Skip button row

**5. Workout Logger Toggle Style**
- Tab toggle (Logger/Demo) now matches library toolbar style
- Uses transparent orange tint for selected state
- Includes icons (clipboard for Logger, play for Demo)
- Pill-shaped capsule container with subtle background

**6. Liquid Glass Modals**
- Injury Warning overlay now uses ultraThinMaterial (liquid glass) instead of solid white
- Progression Prompt cards use liquid glass background
- Consistent with app's glassmorphic design language

**7. Priority Muscle Groups Styling**
- Heading changed to "Priority Muscles" with caption style
- Content is now center-aligned
- Body diagrams use uniform light grey base color for all non-selected muscles
- Selected muscle remains in accent (orange) color

**8. Questionnaire Muscle Selector Fix**
- Reverted GeometryReader implementation that was breaking layout
- Uses fixed height (400pt) for consistent display
- Selected muscles now display below the body diagram in a horizontal row
- Cleaner layout without coordinate-based positioning

**Implementation:** Updated multiple files:
- [WorkoutSummaryView.swift](../../trAInSwift/Views/WorkoutSummaryView.swift)
- [WorkoutOverviewView.swift](../../trAInSwift/Views/WorkoutOverviewView.swift)
- [WorkoutLoggerView.swift](../../trAInSwift/Views/WorkoutLoggerView.swift)
- [DashboardView.swift](../../trAInSwift/Views/DashboardView.swift)
- [ProfileView.swift](../../trAInSwift/Views/ProfileView.swift)
- [QuestionnaireSteps.swift](../../trAInSwift/Views/QuestionnaireSteps.swift)
- [StaticMuscleView.swift](../../trAInSwift/Components/MuscleSelector/StaticMuscleView.swift)

---

## Build Fixes Applied

The following fixes were applied to resolve compilation errors and ensure the new features work correctly with the existing codebase:

### Exercise Swap Carousel Fixes
The swap carousel needed updates to work with the exercise database:
- **Finding alternatives**: Now uses the proper database search method with muscle group filtering
- **Exercise names**: Displays the user-friendly exercise name instead of internal identifiers
- **Secondary muscles**: Shows additional targeted muscles when available (e.g., "Also targets: Triceps")
- **Creating swapped exercises**: Properly creates replacement exercises with all required details

### Combined Library View Fixes
The combined exercise/video library needed adjustments:
- **Loading exercises**: Uses the correct database query to fetch all available exercises
- **Search functionality**: Searches by the display name users see, not internal codes
- **Renamed filter component**: Avoided conflict with existing filter in the app

### Injury Warning Fix
The injury warning system needed a small update:
- **Reading user injuries**: Now correctly accesses the user's declared injuries from their profile to check against exercise muscle targets

### Exercise Logger Preview Fix
The preview (used during development) was updated:
- **Sample data**: Uses the correct format for creating sample exercises

---

### 25. Programme Generated Confetti Animation
**Previous State:** The "Programme Ready!" screen appeared without any celebratory visual feedback.

**New State:** Multi-colored confetti animation plays over the entire screen when the programme is generated.

**Implementation:** Added ConfettiView overlay to [ProgramReadyView.swift](../../trAInSwift/Views/ProgramReadyView.swift):
- 3 waves of confetti particles (40 pieces each) spawn with staggered timing
- Particles include rectangles, circles, and triangles in various colors
- Each piece has randomized: starting position, color, size, rotation, fall duration, horizontal drift
- Confetti falls from top to bottom with natural tumbling animation
- Fades out near the end of fall for smooth disappearance
- Non-interactive overlay (taps pass through to buttons below)

---

### 26. Content Scroll-to-Bottom Fix (Revised)
**Previous State:** Floating action buttons created a hard margin that cut off content halfway up the screen in some views.

**New State:** Content flows all the way to the bottom of the iPhone screen in all views. Buttons float over scrollable content with proper spacing.

**Implementation:** Applied ZStack overlay pattern (matching DashboardView) to:
- [WorkoutOverviewView.swift](../../trAInSwift/Views/WorkoutOverviewView.swift): Complete Workout button now floats over exercise list
- [WorkoutLoggerView.swift](../../trAInSwift/Views/WorkoutLoggerView.swift): Next Exercise/Finish Workout buttons float over set logging

Pattern used:
```swift
ZStack {
    VStack {
        // Header
        ScrollView {
            // Content
            .padding(.bottom, 90) // Space for button
        }
        .scrollContentBackground(.hidden)
    }

    // Floating button overlay
    VStack {
        Spacer()
        Button(...)
    }
}
```

---

### 27. Exercise Logger Toggle Style Fix
**Previous State:** The Logger/Demo toggle in ExerciseLoggerView (individual exercise logging screen) used a solid orange segmented control style that didn't match the app's design language.

**New State:** Toggle now matches the CombinedLibraryView toolbar styling exactly - pill shape, icon+text format, transparent tint selection highlighting.

**Implementation:** Updated toggle in [ExerciseLoggerView.swift](../../trAInSwift/Views/ExerciseLoggerView.swift) and [ExerciseDetailView.swift](../../trAInSwift/Views/ExerciseDetailView.swift):
- Replaced solid orange segmented control with capsule pill toggle
- Icon (clipboard/play.circle.fill) + Text ("Logger"/"Demo") in each pill
- Selected state: orange icon color, primary text color, 15% orange tint background
- Unselected state: secondary colors, transparent background
- Smooth 0.2s animation on selection change
- Outer capsule container with subtle white background (8% opacity)
- Matches CombinedLibraryView toolbar exactly (minus search button)

---

*Report generated: December 2, 2025*
