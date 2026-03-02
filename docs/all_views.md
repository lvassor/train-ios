<p align="center">
  <img src="../assets/train-logo-with-text_isolate_cropped_dark.svg" alt="train" width="280">
</p>

<p align="center">
  <em>Views breakdown — complete reference of all SwiftUI views</em>
</p>

<p align="center">
  <strong>Created by</strong>: Luke Vassor & Brody Bastiman
</p>

---

# Views Breakdown

Complete inventory of all SwiftUI View structs in the train iOS app. **183 views** grouped by feature area.

---

## Core Application (7 views)

### ContentView
**Purpose**: Main app coordinator managing authentication state and app flow
**File**: `ContentView.swift`
**Behavior**: Shows LaunchScreenView → OnboardingFlowView (unauthenticated) or DashboardView (authenticated)

### LaunchScreenView
**Purpose**: App launch animation and branding
**File**: `Views/LaunchScreenView.swift`
**Behavior**: 3.5 second animation, fades to main app flow

### SplashScreen
**Purpose**: Alternative launch screen implementation
**File**: `Views/SplashScreen.swift`

### TrainLogoIcon
**Purpose**: Animated train logo icon component
**File**: `Views/SplashScreen.swift`

### WelcomeView
**Purpose**: Initial welcome screen with carousel and CTA
**File**: `Views/WelcomeView.swift`
**Behavior**: Entry point to questionnaire or login flow

### DashboardView
**Purpose**: Primary app interface for authenticated users
**File**: `Views/DashboardView.swift`
**Behavior**: Central hub with navigation to all major features

### DashboardContent
**Purpose**: Dashboard content body, separated for navigation
**File**: `Views/DashboardView.swift`

---

## Authentication & Login (6 views)

| View | File | Purpose |
|------|------|---------|
| LoginView | `Views/LoginView.swift` | User login screen |
| EmailLoginSheet | `Views/LoginView.swift` | Email/password login modal |
| SignupView | `Views/SignupView.swift` | User registration form |
| PasswordResetRequestView | `Views/PasswordResetRequestView.swift` | Initiate password reset |
| PasswordResetCodeView | `Views/PasswordResetCodeView.swift` | Verify reset code |
| PasswordResetNewPasswordView | `Views/PasswordResetNewPasswordView.swift` | Set new password |

---

## Onboarding Flow (7 views)

| View | File | Purpose |
|------|------|---------|
| OnboardingFlowView | `Views/OnboardingFlowView.swift` | Welcome → questionnaire router |
| AccountCreationLoadingView | `Views/AccountCreationLoadingView.swift` | Loading during account creation |
| PostSignupFlowView | `Views/Onboarding/PostSignupFlowView.swift` | Post-registration steps |
| NotificationPermissionView | `Views/Onboarding/NotificationPermissionView.swift` | Push notification opt-in |
| FirstVideoInterstitialView | `Views/Onboarding/VideoInterstitialView.swift` | First questionnaire interstitial video |
| SecondVideoInterstitialView | `Views/Onboarding/VideoInterstitialView.swift` | Second questionnaire interstitial video |
| InterstitialScreen | `Views/Onboarding/VideoInterstitialView.swift` | Reusable interstitial screen component |
| ReferralPageView | `Views/Onboarding/ReferralPageView.swift` | Attribution tracking |
| OnboardingFlowExample | `Views/Onboarding/OnboardingFlowExample.swift` | Example/demo onboarding flow |

---

## Questionnaire System (25 views)

### QuestionnaireView
**Purpose**: Main questionnaire orchestrator (15-step assessment)
**File**: `Views/QuestionnaireView.swift`
**Behavior**: Collects user preferences, generates personalised programme

### Step Views

| View | File | Purpose |
|------|------|---------|
| GoalsStepView | `Views/QuestionnaireSteps.swift` | Fitness goals selection |
| NameStepView | `Views/QuestionnaireSteps.swift` | Name input |
| GenderStepView | `Views/QuestionnaireSteps.swift` | Gender selection |
| AgeStepView | `Views/QuestionnaireSteps.swift` | Age/DOB input |
| HeightStepView | `Views/QuestionnaireSteps.swift` | Height input |
| WeightStepView | `Views/QuestionnaireSteps.swift` | Weight input |
| ExperienceStepView | `Views/QuestionnaireSteps.swift` | Training experience level |
| MotivationStepView | `Views/QuestionnaireSteps.swift` | Motivation assessment |
| MuscleGroupsStepView | `Views/QuestionnaireSteps.swift` | Muscle group priority selection |
| TrainingPlaceStepView | `Views/QuestionnaireSteps.swift` | Training location/gym type |
| EquipmentStepView | `Views/QuestionnaireSteps.swift` | Equipment availability |
| TrainingDaysStepView | `Views/QuestionnaireSteps.swift` | Training frequency |
| SplitSelectionStepView | `Views/QuestionnaireSteps.swift` | Training split choice |
| SessionDurationStepView | `Views/QuestionnaireSteps.swift` | Session duration preference |
| InjuriesStepView | `Views/QuestionnaireSteps.swift` | Injury history |
| HealthProfileStepView | `Views/Steps/HealthProfileStepView.swift` | Apple Health sync + age/gender |
| HeightWeightStepView | `Views/Steps/HeightWeightStepView.swift` | Manual height/weight entry |
| ReviewSummaryStepView | `Views/Steps/ReviewSummaryStepView.swift` | Editable review of all choices |
| ReferralStepView | `Views/Steps/ReferralStepView.swift` | Referral bonus step |

### Questionnaire Helper Components

| View | File | Purpose |
|------|------|---------|
| MuscleGroupButton | `Views/QuestionnaireSteps.swift` | Individual muscle group button |
| EquipmentCard | `Views/QuestionnaireSteps.swift` | Equipment selection card |
| EquipmentGroupSection | `Views/QuestionnaireSteps.swift` | Grouped equipment section |
| EquipmentCategorySheet | `Views/QuestionnaireSteps.swift` | Equipment category modal |
| SimpleEquipmentToggleCard | `Views/QuestionnaireSteps.swift` | Simplified equipment toggle |
| EquipmentInfoModal | `Views/QuestionnaireSteps.swift` | Equipment information modal |
| SplitOptionCard | `Views/QuestionnaireSteps.swift` | Individual split option card |

---

## Post-Questionnaire & Signup (4 views)

| View | File | Purpose |
|------|------|---------|
| PostQuestionnaireSignupView | `Views/PostQuestionnaireSignupView.swift` | Account creation after questionnaire |
| EmailSignupSheet | `Views/PostQuestionnaireSignupView.swift` | Email signup modal |
| PrivacyPolicySheet | `Views/PostQuestionnaireSignupView.swift` | Privacy policy display |
| TermsAndConditionsSheet | `Views/PostQuestionnaireSignupView.swift` | Terms & conditions display |

---

## Programme Generation & Paywall (10 views)

| View | File | Purpose |
|------|------|---------|
| ProgramLoadingView | `Views/ProgramLoadingView.swift` | Programme generation progress |
| ChecklistItem | `Views/ProgramLoadingView.swift` | Animated checklist item |
| ProgramReadyView | `Views/ProgramReadyView.swift` | Programme summary with confetti |
| ProgramInfoCard | `Views/ProgramReadyView.swift` | Programme detail card |
| ConfettiView | `Views/ProgramReadyView.swift` | Confetti animation container |
| ConfettiPieceView | `Views/ProgramReadyView.swift` | Individual confetti piece |
| ProgramOverviewView | `Views/ProgramOverviewView.swift` | Detailed programme information |
| WeekSection | `Views/ProgramOverviewView.swift` | Weekly programme section |
| SessionRow | `Views/ProgramOverviewView.swift` | Individual session row |
| PaywallView | `Views/PaywallView.swift` | Premium subscription conversion |
| PricingTierCard | `Views/PaywallView.swift` | Pricing tier display |

---

## Dashboard Components (23 views)

### Top-Level Dashboard

| View | File | Purpose |
|------|------|---------|
| TopHeaderView | `Views/DashboardView.swift` | Top header/title bar |
| ProgramProgressCard | `Views/DashboardView.swift` | Programme progress indicator |
| WeeklySessionsSection | `Views/DashboardView.swift` | Weekly sessions container |
| HorizontalDayButtonsRow | `Views/DashboardView.swift` | Day button row |
| SessionActionButton | `Views/DashboardView.swift` | Start/continue session button |
| ExerciseListView | `Views/DashboardView.swift` | Exercise list display |
| NextWorkoutCard | `Views/DashboardView.swift` | Upcoming workout card |
| UpcomingWorkoutsSection | `Views/DashboardView.swift` | Upcoming workouts section |
| UpcomingWorkoutCard | `Views/DashboardView.swift` | Individual upcoming workout card |
| ActiveWorkoutTimerView | `Views/DashboardView.swift` | Active workout timer |
| BottomNavigationBar | `Views/DashboardView.swift` | Bottom navigation bar |
| BottomNavItem | `Views/DashboardView.swift` | Navigation bar item |

### Session Summaries

| View | File | Purpose |
|------|------|---------|
| CompletedSessionSummaryCard | `Views/DashboardView.swift` | Completed session summary |
| SummaryStatItem | `Views/DashboardView.swift` | Summary statistic item |
| SessionBubble | `Views/DashboardView.swift` | Session bubble indicator |
| ExpandedSessionBubble | `Views/DashboardView.swift` | Expanded session details |

### Dashboard Carousel Cards

| View | File | Purpose |
|------|------|---------|
| DashboardCarouselView | `Components/Dashboard/DashboardCarouselView.swift` | Carousel container |
| CarouselCardView | `Components/Dashboard/CarouselCardView.swift` | Generic carousel card |
| WeeklyProgressCard | `Components/Dashboard/WeeklyProgressCard.swift` | Weekly progress indicator |
| DashboardExerciseCard | `Components/Dashboard/DashboardExerciseCard.swift` | Exercise highlight card |
| CompactMuscleHighlight | `Components/Dashboard/DashboardExerciseCard.swift` | Muscle highlight component |
| DashboardExerciseCardDarkMode | `Components/Dashboard/DashboardExerciseCard.swift` | Dark mode variant |
| LearningRecommendationCard | `Components/Dashboard/LearningRecommendationCard.swift` | Learning recommendation |
| EngagementPromptCard | `Components/Dashboard/EngagementPromptCard.swift` | Engagement prompt |

---

## Workout Flow (8 views)

### WorkoutOverviewView
**Purpose**: Pre-workout session preparation with exercise list
**File**: `Views/WorkoutOverviewView.swift`
**Behavior**: Prepares user for workout, tracks completed exercises

| View | File | Purpose |
|------|------|---------|
| WorkoutOverviewHeader | `Views/WorkoutOverviewView.swift` | Workout header section |
| WarmUpCard | `Views/WorkoutOverviewView.swift` | Warm-up exercises card |
| WorkoutExerciseList | `Views/WorkoutOverviewView.swift` | Main exercise list |
| ExerciseOverviewCard | `Views/WorkoutOverviewView.swift` | Exercise detail card |
| InjuryWarningOverlay | `Views/WorkoutOverviewView.swift` | Injury warning notification |
| WorkoutSummaryView | `Views/WorkoutSummaryView.swift` | Post-workout summary and PBs |
| PBCardView | `Views/WorkoutSummaryView.swift` | Personal best achievement card |
| PBCelebrationOverlay | `Views/PBCelebrationOverlay.swift` | PB celebration modal |
| CelebrationConfettiView | `Views/PBCelebrationOverlay.swift` | Celebration confetti animation |

---

## Exercise Logging (18 views)

### ExerciseLoggerView
**Purpose**: Active workout session interface with set/rep logging
**File**: `Views/ExerciseLoggerView.swift`
**Behavior**: Guides user through exercise, records performance data

| View | File | Purpose |
|------|------|---------|
| ExerciseLoggerHeader | `Views/ExerciseLoggerView.swift` | Logger header/title |
| LoggerTabSelector | `Views/ExerciseLoggerView.swift` | Floating pill tab selector |
| ExerciseLoggerInfoSection | `Views/ExerciseLoggerView.swift` | Exercise information display |
| ExerciseLoggerInfoCard | `Views/ExerciseLoggerView.swift` | Individual info card |
| SetLoggingCard | `Views/ExerciseLoggerView.swift` | Set input card |
| SimplifiedSetRow | `Views/ExerciseLoggerView.swift` | Simplified set row |
| SetLoggingSection | `Views/ExerciseLoggerView.swift` | Set logging container |
| SetInputRow | `Views/ExerciseLoggerView.swift` | Individual set input row |
| InlineHighlightCard | `Views/ExerciseLoggerView.swift` | Highlighted inline feedback card |

### Demo Tab

| View | File | Purpose |
|------|------|---------|
| ExerciseDemoTab | `Views/ExerciseLoggerDemoView.swift` | Demo tab component |
| DemoVideoPlayerCard | `Views/ExerciseLoggerDemoView.swift` | Demo video player |
| DemoInfoSection | `Views/ExerciseLoggerDemoView.swift` | Demo info display |
| DemoPlaceholderTile | `Views/ExerciseLoggerDemoView.swift` | Placeholder tile |
| DemoMuscleGroupsSection | `Views/ExerciseLoggerDemoView.swift` | Muscle groups display |
| DemoInstructionsCard | `Views/ExerciseLoggerDemoView.swift` | Instructions card |

### Feedback

| View | File | Purpose |
|------|------|---------|
| FeedbackModalOverlay | `Views/ExerciseLoggerFeedback.swift` | Regression feedback modal |

---

## Session Management (13 views)

### SessionLogView
**Purpose**: Individual workout session recording and review
**File**: `Views/SessionLogView.swift`

| View | File | Purpose |
|------|------|---------|
| SessionSummaryHeader | `Views/SessionLogView.swift` | Session summary header |
| ExerciseLogCardsSection | `Views/SessionLogView.swift` | Exercise cards container |
| ExerciseLogCard | `Views/SessionLogView.swift` | Individual exercise log card |
| EmptySessionView | `Views/SessionLogView.swift` | Empty session state |
| EditSessionView | `Views/SessionLogView.swift` | Session editing interface |

### SessionDetailView
**Purpose**: Review completed workout session
**File**: `Views/SessionDetailView.swift`

| View | File | Purpose |
|------|------|---------|
| InfoRow | `Views/SessionDetailView.swift` | Information row display |
| ExerciseCard | `Views/SessionDetailView.swift` | Exercise detail card |

### SessionEditView
**Purpose**: Modify recorded workout data
**File**: `Views/SessionEditView.swift`

| View | File | Purpose |
|------|------|---------|
| SessionEditHeader | `Views/SessionEditView.swift` | Edit view header |
| EditableExerciseCard | `Views/SessionEditView.swift` | Editable exercise card |
| SetsPicker | `Views/SessionEditView.swift` | Sets number picker |
| RepsPicker | `Views/SessionEditView.swift` | Reps number picker |

---

## Exercise Library & History (17 views)

### CombinedLibraryView
**Purpose**: Unified library interface for exercises and education
**File**: `Views/CombinedLibraryView.swift`

| View | File | Purpose |
|------|------|---------|
| ExerciseLibraryContent | `Views/CombinedLibraryView.swift` | Exercise library content |
| EducationLibraryContent | `Views/CombinedLibraryView.swift` | Education library content |
| ExerciseRowCard | `Views/CombinedLibraryView.swift` | Exercise row display |
| LibraryFilterSheet | `Views/CombinedLibraryView.swift` | Library filter modal |

### ExerciseLibraryView
**Purpose**: Full exercise library with search and filter
**File**: `Views/ExerciseLibraryView.swift`

| View | File | Purpose |
|------|------|---------|
| ExerciseLibraryCard | `Views/ExerciseLibraryView.swift` | Exercise card component |
| FilterSheet | `Views/ExerciseLibraryView.swift` | Exercise filter modal |

### ExerciseHistoryView
**Purpose**: Personal exercise performance history
**File**: `Views/ExerciseHistoryView.swift`

| View | File | Purpose |
|------|------|---------|
| HistoryStatCard | `Views/ExerciseHistoryView.swift` | History statistics card |
| HistoryProgressChart | `Views/ExerciseHistoryView.swift` | Progress chart visualisation |
| HistorySessionCard | `Views/ExerciseHistoryView.swift` | Session history card |
| HistoryEntryCard | `Views/ExerciseHistoryView.swift` | Individual entry card |

### Other Library Views

| View | File | Purpose |
|------|------|---------|
| ExerciseDemoHistoryView | `Views/ExerciseDemoHistoryView.swift` | Demo history view |
| DemoHistoryHeader | `Views/ExerciseDemoHistoryView.swift` | History header |
| DemoHistoryTabSelector | `Views/ExerciseDemoHistoryView.swift` | Tab selector |
| ExercisePickerView | `Views/ExercisePickerView.swift` | Exercise selection picker |
| FilterChip | `Views/ExercisePickerView.swift` | Filter chip component |
| ExercisePickerCard | `Views/ExercisePickerView.swift` | Picker card display |

---

## Calendar & Milestones (13 views)

### CalendarView
**Purpose**: Workout schedule visualisation
**File**: `Views/CalendarView.swift`

| View | File | Purpose |
|------|------|---------|
| MonthNavigationView | `Views/CalendarView.swift` | Month navigation |
| CalendarGridView | `Views/CalendarView.swift` | Calendar grid |
| CalendarDayView | `Views/CalendarView.swift` | Individual day cell |
| WorkoutsForDateView | `Views/CalendarView.swift` | Workouts for selected date |
| WorkoutHistoryCard | `Views/CalendarView.swift` | Workout history card |

### MilestonesView
**Purpose**: Achievement and progress tracking
**File**: `Views/MilestonesView.swift`

| View | File | Purpose |
|------|------|---------|
| StatBox | `Views/MilestonesView.swift` | Statistics box |
| StreakStatBox | `Views/MilestonesView.swift` | Streak statistics box |
| MilestoneCard | `Views/MilestonesView.swift` | Individual milestone card |
| RecentPBCard | `Views/MilestonesView.swift` | Recent personal best card |
| StreakMilestoneCard | `Views/MilestonesView.swift` | Streak milestone card |

### Weekly Calendar

| View | File | Purpose |
|------|------|---------|
| WeeklyCalendarView | `Components/WeeklyCalendarView.swift` | Reusable weekly calendar component |

---

## Profile & Settings (12 views)

### ProfileView
**Purpose**: User account settings and preferences
**File**: `Views/ProfileView.swift`

| View | File | Purpose |
|------|------|---------|
| EditProfileView | `Views/ProfileView.swift` | Edit profile form |
| ProfileMenuItem | `Views/ProfileView.swift` | Menu item component |
| SubscriptionInfoCard | `Views/ProfileView.swift` | Subscription info display |
| ProgramCard | `Views/ProfileView.swift` | Programme information card |
| ProgramSelectorView | `Views/ProfileView.swift` | Programme selector interface |
| ProgramSelectionCard | `Views/ProfileView.swift` | Programme selection card |
| ThemeToggleRow | `Views/ProfileView.swift` | Theme toggle control |

---

## Shared Components (17 views)

### UI Components

| View | File | Purpose |
|------|------|---------|
| CustomButton | `Components/CustomButton.swift` | Reusable styled button |
| OptionCard | `Components/OptionCard.swift` | Option selection card |
| MultiSelectCard | `Components/MultiSelectCard.swift` | Multi-select card |
| QuestionnaireProgressBar | `Components/QuestionnaireProgressBar.swift` | Progress indicator |
| FloatingToolbar | `Components/FloatingToolbar.swift` | Main tab bar / floating toolbar |
| InlineRestTimer | `Components/InlineRestTimer.swift` | Rest timer between sets |
| ProgressionBannerView | `Components/ProgressionBannerView.swift` | Weight increase prompt banner |

### Exercise Components

| View | File | Purpose |
|------|------|---------|
| ExerciseSwapCarousel | `Components/ExerciseSwapCarousel.swift` | Exercise swap carousel |
| AlternativeExerciseCard | `Components/ExerciseSwapCarousel.swift` | Alternative exercise card |
| ExerciseMediaPlayer | `Components/ExerciseMediaPlayer.swift` | Exercise video player |
| BunnyVideoPlayer | `Components/ExerciseMediaPlayer.swift` | Bunny CDN video player |
| FullscreenVideoPlayer | `Components/ExerciseMediaPlayer.swift` | Fullscreen video player |
| WorkoutShareCardGenerator | `Components/WorkoutShareCardGenerator.swift` | Workout share card generator |
| WorkoutShareCardView | `Components/WorkoutShareCardGenerator.swift` | Share card display |

### Muscle Selector

| View | File | Purpose |
|------|------|---------|
| MuscleSelector | `Components/MuscleSelector/MuscleSelector.swift` | Interactive muscle selection |
| CompactMuscleSelector | `Components/MuscleSelector/MuscleSelector.swift` | Compact muscle selector |
| StaticMuscleView | `Components/MuscleSelector/StaticMuscleView.swift` | Static muscle diagram |
| StaticMusclePathView | `Components/MuscleSelector/StaticMuscleView.swift` | Muscle path SVG |
| MusclePathView | `Components/MuscleSelector/MuscleShape.swift` | Muscle path component |

---

## Icons & Branding (2 views)

| View | File | Purpose |
|------|------|---------|
| TrainIconView | `Assets/train-icon.swift` | Train logo icon |

---

Made with ❤️ by Luke Vassor & Brody Bastiman
