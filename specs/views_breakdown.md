# Views Breakdown

## Core Navigation & Flow

### ContentView
**Purpose**: Main app coordinator managing authentication state and app flow
**Content**: Launch animation transition, navigation between authenticated/unauthenticated states
**Behavior**: Shows LaunchScreenView → OnboardingFlowView (unauthenticated) or DashboardView (authenticated)

### LaunchScreenView
**Purpose**: App launch animation and branding
**Content**: Logo, brand elements, loading animation
**Behavior**: 3.5 second animation, fades to main app flow

## Authentication & Onboarding

### WelcomeView
**Purpose**: Initial welcome screen for new users
**Content**: App introduction, value proposition, CTA buttons
**Behavior**: Entry point to questionnaire or login flow

### OnboardingFlowView
**Purpose**: Coordinates pre-authentication user journey
**Content**: Manages flow between welcome, questionnaire, signup, and paywall
**Behavior**: Orchestrates multi-step onboarding process

### LoginView
**Purpose**: User authentication for returning users
**Content**: Email/password fields, forgot password link
**Behavior**: Validates credentials, transitions to dashboard on success

### SignupView
**Purpose**: Account creation for new users
**Content**: Registration form with email, password, name fields
**Behavior**: Creates new user account, transitions to post-signup flow

### PostQuestionnaireSignupView
**Purpose**: Account creation after completing questionnaire
**Content**: Minimal signup form pre-filled with questionnaire data
**Behavior**: Quick account creation with program data preserved

### PostSignupFlowView
**Purpose**: Onboarding steps after account creation
**Content**: Notification permissions, referral tracking, app tour
**Behavior**: Multi-step post-registration onboarding

## Password Recovery

### PasswordResetRequestView
**Purpose**: Initiate password reset process
**Content**: Email input field, request reset button
**Behavior**: Sends password reset email

### PasswordResetCodeView
**Purpose**: Verify password reset code
**Content**: Code input field, verification button
**Behavior**: Validates reset code from email

### PasswordResetNewPasswordView
**Purpose**: Set new password after verification
**Content**: New password fields, confirmation
**Behavior**: Updates user password, returns to login

## Questionnaire System

### QuestionnaireView
**Purpose**: Main questionnaire orchestrator (14-step assessment)
**Content**: Progress bar, step navigation, question content
**Behavior**: Collects user preferences, generates personalized program

### QuestionnaireSteps
**Purpose**: Individual questionnaire step definitions
**Content**: Question-specific UI components and logic
**Behavior**: Handles user input validation and data collection

### HealthProfileStepView
**Purpose**: Collect health and fitness background information
**Content**: Health questionnaires, fitness experience, limitations
**Behavior**: Captures medical and fitness history for program customization

### HeightWeightStepView
**Purpose**: Collect physical measurements
**Content**: Height/weight inputs, unit selection
**Behavior**: Records biometric data for program calculations

### ReferralStepView
**Purpose**: Track user acquisition source
**Content**: Referral source selection, referral codes
**Behavior**: Records marketing attribution data

## Payment & Subscription

### PaywallView
**Purpose**: Premium subscription conversion
**Content**: Pricing tiers, feature comparison, subscription CTAs
**Behavior**: Manages subscription purchase flow

## Program Management

### ProgramLoadingView
**Purpose**: Show program generation progress
**Content**: Loading animation, progress indicators
**Behavior**: Displays while AI generates personalized workout program

### ProgramReadyView
**Purpose**: Present completed program to user
**Content**: Program summary, key features, start button
**Behavior**: Transitions user from questionnaire to program usage

### ProgramOverviewView
**Purpose**: Detailed program information and management
**Content**: Program structure, workout schedule, equipment requirements
**Behavior**: Allows program review and modification

## Main Dashboard

### DashboardView
**Purpose**: Primary app interface for authenticated users
**Content**: Program progress, upcoming workouts, achievement highlights
**Behavior**: Central hub with navigation to all major features

### DashboardCarouselView
**Purpose**: Rotating content cards on dashboard
**Content**: Workout recommendations, tips, progress updates
**Behavior**: Horizontal scrolling carousel with dynamic content

## Workout Management

### WorkoutOverviewView
**Purpose**: Pre-workout session preparation
**Content**: Exercise list, equipment check, workout summary
**Behavior**: Prepares user for workout session, starts workout

### ExerciseLoggerView
**Purpose**: Active workout session interface
**Content**: Exercise instructions, set/rep logging, timer
**Behavior**: Guides user through workout, records performance data

### SessionLogView
**Purpose**: Individual workout session recording
**Content**: Exercise performance tracking, notes, completion status
**Behavior**: Captures detailed workout metrics

### SessionDetailView
**Purpose**: Review completed workout session
**Content**: Session summary, performance metrics, notes
**Behavior**: Historical workout data visualization

### SessionEditView
**Purpose**: Modify recorded workout data
**Content**: Editable session fields, save/cancel actions
**Behavior**: Allows post-workout data corrections

### WorkoutSummaryView
**Purpose**: Post-workout completion summary
**Content**: Session achievements, progress updates, next workout preview
**Behavior**: Celebrates completion, motivates continued engagement

## Exercise Library & Reference

### ExerciseLibraryView
**Purpose**: Browse available exercises
**Content**: Exercise database, search/filter, demonstrations
**Behavior**: Educational reference for exercise techniques

### CombinedLibraryView
**Purpose**: Unified library interface
**Content**: Exercises and equipment information
**Behavior**: Single access point to all reference material

### ExerciseHistoryView
**Purpose**: Personal exercise performance history
**Content**: Exercise-specific progress charts, personal records
**Behavior**: Tracks individual exercise improvement over time

### ExerciseDemoHistoryView
**Purpose**: Previously viewed exercise demonstrations
**Content**: History of accessed exercise videos/instructions
**Behavior**: Quick access to recently viewed exercises

## Calendar & Scheduling

### CalendarView
**Purpose**: Workout schedule visualization
**Content**: Monthly/weekly calendar, workout sessions, rest days
**Behavior**: Schedule management and workout planning

### WeeklyCalendarView
**Purpose**: Week-focused schedule view
**Content**: 7-day workout overview, daily session details
**Behavior**: Detailed weekly planning and navigation

## User Management

### ProfileView
**Purpose**: User account settings and preferences
**Content**: Personal info, app settings, account management
**Behavior**: Profile editing, app configuration, logout/deletion

### MilestonesView
**Purpose**: Achievement and progress tracking (placeholder)
**Content**: Coming soon message, achievement placeholders
**Behavior**: Future feature for milestone celebration

## Loading & Transition States

### AccountCreationLoadingView
**Purpose**: Show account creation progress
**Content**: Loading animation, account setup messages
**Behavior**: Displays during user registration process

### VideoInterstitialView
**Purpose**: Transitional content between questionnaire steps
**Content**: Motivational videos, app feature highlights
**Behavior**: Engages user during questionnaire flow

### NotificationPermissionView
**Purpose**: Request notification permissions
**Content**: Permission rationale, enable/skip options
**Behavior**: Handles push notification setup

### ReferralPageView
**Purpose**: Referral program information
**Content**: Referral benefits, sharing options
**Behavior**: Manages user referral flow

## Dashboard Cards

### CarouselCardView
**Purpose**: Generic carousel card component
**Content**: Flexible card layout for dashboard content
**Behavior**: Standardized card presentation in carousel

### LearningRecommendationCard
**Purpose**: Educational content suggestions
**Content**: Learning tips, technique videos, articles
**Behavior**: Promotes user education and engagement

### EngagementPromptCard
**Purpose**: User engagement and motivation
**Content**: Motivational messages, challenge prompts
**Behavior**: Encourages continued app usage

### WeeklyProgressCard
**Purpose**: Weekly performance summary
**Content**: Week's workout completion, progress metrics
**Behavior**: Visual progress tracking and motivation

### DashboardExerciseCard
**Purpose**: Exercise-specific dashboard information
**Content**: Exercise highlights, personal records, tips
**Behavior**: Exercise-focused engagement on dashboard

## Utility Components

### SplashScreen
**Purpose**: Alternative launch screen implementation
**Content**: App branding, loading states
**Behavior**: Initial app launch presentation

### VideoBackgroundView
**Purpose**: Video background component
**Content**: Looping video backgrounds for enhanced UI
**Behavior**: Provides dynamic visual backgrounds

### WeeklyCalendarView
**Purpose**: Reusable weekly calendar component
**Content**: 7-day calendar interface
**Behavior**: Standardized weekly view across features

### StaticMuscleView
**Purpose**: Anatomical muscle diagram display
**Content**: Interactive muscle group visualization
**Behavior**: Educational muscle targeting reference

### ExerciseMediaPlayer
**Purpose**: Exercise video/media playback
**Content**: Video controls, exercise demonstrations
**Behavior**: Manages exercise instruction media

### FloatingToolbar
**Purpose**: Context-sensitive action toolbar
**Content**: Floating action buttons, quick access tools
**Behavior**: Provides contextual user actions

### ExerciseSwapCarousel
**Purpose**: Alternative exercise selection
**Content**: Exercise alternatives, swap functionality
**Behavior**: Allows exercise substitution in workouts