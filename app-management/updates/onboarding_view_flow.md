# trAIn iOS App View Flow - Welcome to Questionnaire

This document outlines the complete view flow from app launch to questionnaire completion, including file names and key code snippets.

---

## 1. App Entry Point - ContentView.swift

**File:** `trAInSwift/ContentView.swift`

The main app coordinator that determines whether to show the dashboard (authenticated) or onboarding flow (unauthenticated).

```swift
struct ContentView: View {
    @ObservedObject private var workoutViewModel = WorkoutViewModel.shared
    @ObservedObject private var authService = AuthService.shared

    var body: some View {
        NavigationView {
            if authService.isAuthenticated {
                DashboardView()
                    .environmentObject(workoutViewModel)
            } else {
                OnboardingFlowView()
                    .environmentObject(workoutViewModel)
                    .sheet(isPresented: $showLogin) {
                        LoginView()
                    }
            }
        }
    }
}
```

**Flow Logic:**
- ✅ Authenticated → `DashboardView`
- ❌ Not authenticated → `OnboardingFlowView`

---

## 2. Onboarding Flow Coordinator - OnboardingFlowView.swift

**File:** `trAInSwift/Views/OnboardingFlowView.swift`

Unified onboarding flow that handles Welcome → Questionnaire navigation using NavigationStack instead of sheet presentation.

```swift
struct OnboardingFlowView: View {
    @EnvironmentObject var workoutViewModel: WorkoutViewModel
    @State private var showQuestionnaire = false
    @State private var showLogin = false

    var body: some View {
        NavigationStack {
            if !showQuestionnaire {
                WelcomeView(
                    onContinue: {
                        print("🚀 [ONBOARDING] WelcomeView onContinue - navigating to questionnaire")
                        showQuestionnaire = true
                    },
                    onLogin: {
                        print("🔐 [ONBOARDING] WelcomeView onLogin triggered - showing login")
                        showLogin = true
                    }
                )
                .sheet(isPresented: $showLogin) {
                    LoginView()
                }
            } else {
                QuestionnaireView(
                    onComplete: {
                        print("✅ [ONBOARDING] Questionnaire completed")
                        // QuestionnaireView handles authentication internally
                        // Once complete, ContentView will automatically show Dashboard
                    },
                    onBack: {
                        print("⬅️ [ONBOARDING] Going back to WelcomeView")
                        showQuestionnaire = false
                    }
                )
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
```

**Key Features:**
- Uses `NavigationStack` for proper view-to-view navigation
- Eliminates sheet overlay issues from previous implementation
- Handles both login and questionnaire flows

---

## 3. Welcome Screen - WelcomeView.swift

**File:** `trAInSwift/Views/WelcomeView.swift`

The initial welcome screen with app branding, screenshots, and primary CTAs.

```swift
struct WelcomeView: View {
    let onContinue: () -> Void
    let onLogin: () -> Void

    private let screenshots = ["screenshot_1", "screenshot_2", "screenshot_3", "screenshot_4"]

    var body: some View {
        VStack(spacing: 0) {
            // Header with logo and sign in
            HStack {
                Image("TrainLogoWithText")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 24)

                Spacer()

                Button(action: onLogin) {
                    Text("Sign In")
                        .font(.trainBody)
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 24)

            // Headlines with attributed text
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Programs Built by ")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    +
                    Text("Coaches.")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.trainPrimary)
                    Spacer()
                }

                HStack {
                    Text("Tracked by You.")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                }
            }
            .padding(.horizontal, 24)

            // Screenshot carousel - swipeable through all 4 screenshots
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(Array(screenshots.enumerated()), id: \.offset) { index, screenshot in
                        Image(screenshot)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: UIScreen.main.bounds.width * 0.43)
                            .frame(height: 400)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                }
                .padding(.horizontal, 20)
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)

            // Get Started button
            Button(action: onContinue) {
                Text("Get Started")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 28))
            }
            .padding(.horizontal, 24)
        }
        .charcoalGradientBackground()
    }
}
```

**Key Features:**
- Swipeable screenshot carousel showing app features
- "Get Started" triggers questionnaire flow
- "Sign In" shows login sheet for returning users

---

## 4. Questionnaire Flow - QuestionnaireView.swift

**File:** `trAInSwift/Views/QuestionnaireView.swift`

The main questionnaire coordinator that manages all questionnaire steps and handles the flow to signup.

```swift
struct QuestionnaireView: View {
    @ObservedObject var viewModel = WorkoutViewModel.shared
    @State private var currentStep = 0
    @State private var showingProgramLoading = false
    @State private var showingProgramReady = false

    let onComplete: () -> Void
    var onBack: (() -> Void)? = nil

    // Total steps: Main questionnaire flow (referral moved to post-signup)
    var totalSteps: Int {
        return 13  // Steps 0-12: Goal → Name → HealthProfile → [HeightWeight] → Experience → [Interstitial1] → Days → Split → Duration → Equipment → [Interstitial2] → Muscles → Injuries
    }

    var body: some View {
        ZStack {
            if (showingProgramReady || isSignupInProgress), let program = viewModel.generatedProgram {
                ProgramReadyView(
                    program: program,
                    onStart: {
                        viewModel.completeQuestionnaire()
                        onComplete()
                    },
                    onSignupStart: {
                        isSignupInProgress = true
                    },
                    onSignupCancel: {
                        isSignupInProgress = false
                    },
                    selectedMuscleGroups: viewModel.questionnaireData.targetMuscleGroups
                )
            } else if showingProgramLoading {
                ProgramLoadingView(onComplete: {
                    if viewModel.generatedProgram == nil {
                        viewModel.generateProgram()
                    }
                    showingProgramReady = true
                })
            } else {
                // Main questionnaire steps with back button and progress bar
                VStack(spacing: 0) {
                    HStack {
                        Button(action: previousStep) {
                            Image(systemName: "arrow.left")
                                .font(.title3)
                                .foregroundColor(.white)
                        }
                        Spacer()
                    }
                    .padding(16)

                    QuestionnaireProgressBar(currentStep: currentStep + 1, totalSteps: totalSteps)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)

                    // Current step content
                    currentStepView
                }
            }
        }
    }
}
```

### Questionnaire Step Order:

1. **Goal Selection** (`GoalStepView`)
2. **Name Input** (`NameStepView`)
3. **Health Profile** (`HealthProfileStepView`)
4. **Height/Weight** (`HeightWeightStepView`) - conditional
5. **Experience Level** (`ExperienceStepView`)
6. **First Video Interstitial** (`FirstVideoInterstitialView`)
7. **Training Days** (`TrainingDaysStepView`)
8. **Split Selection** (`SplitSelectionStepView`)
9. **Duration** (`DurationStepView`)
10. **Equipment** (`EquipmentStepView`)
11. **Second Video Interstitial** (`SecondVideoInterstitialView`)
12. **Muscle Groups** (`MuscleGroupsStepView`)
13. **Injuries** (`InjuriesStepView`)

---

## 5. Video Interstitials - VideoInterstitialView.swift

**File:** `trAInSwift/Views/Onboarding/VideoInterstitialView.swift`

Full-screen video background views that appear during the questionnaire to engage users.

```swift
struct FirstVideoInterstitialView: View {
    let onComplete: () -> Void
    let onBack: (() -> Void)?
    let currentStep: Int
    let totalSteps: Int

    var body: some View {
        InterstitialScreen(
            videoName: "onboarding_first",
            subtitle: "You're in the right place",
            headline: "Real trainers and science-backed programs to hit your goals.",
            onNext: onComplete,
            onBack: onBack,
            currentStep: currentStep,
            totalSteps: totalSteps
        )
    }
}

private struct InterstitialScreen: View {
    var body: some View {
        ZStack {
            // Fallback gradient background to prevent flash during video load
            LinearGradient(
                colors: [Color.black, Color(red: 0.1, green: 0.1, blue: 0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea(.all)

            // Video background
            GeometryReader { geo in
                VideoBackgroundView(name: videoName)
                    .frame(width: geo.size.width, height: geo.size.height)
            }
            .ignoresSafeArea(.all)

            // UI overlay with progress bar and content
            VStack(spacing: 0) {
                // Back button + progress bar
                VStack(spacing: 0) {
                    HStack {
                        Button(action: { onBack?() }) {
                            Image(systemName: "arrow.left")
                                .font(.title3)
                                .foregroundColor(.white)
                        }
                        Spacer()
                    }
                    .padding(16)

                    QuestionnaireProgressBar(currentStep: currentStep, totalSteps: totalSteps)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                }

                Spacer()

                // Content text
                VStack(spacing: 16) {
                    Text(subtitle)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))

                    Text(headline)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)

                // Continue button
                CustomButton(title: "Continue", action: onNext, isEnabled: true)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 40)
            }
        }
    }
}
```

---

## 6. Program Loading - ProgramLoadingView.swift

**File:** `trAInSwift/Views/ProgramLoadingView.swift`

Animated loading screen that appears while the user's personalized program is being generated.

```swift
struct ProgramLoadingView: View {
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            // Animated loading indicator
            VStack(spacing: Spacing.lg) {
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle(tint: .trainPrimary))

                Text("Building Your Program")
                    .font(.trainTitle)
                    .foregroundColor(.trainTextPrimary)

                Text("Creating a personalized workout plan based on your preferences...")
                    .font(.trainBody)
                    .foregroundColor(.trainTextSecondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
        .padding(.horizontal, Spacing.xl)
        .charcoalGradientBackground()
        .onAppear {
            // Simulate program generation time
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                onComplete()
            }
        }
    }
}
```

---

## 7. Program Ready - ProgramReadyView.swift

**File:** `trAInSwift/Views/ProgramReadyView.swift`

Displays the generated program details and provides signup options before accessing the main app.

```swift
struct ProgramReadyView: View {
    let program: Program
    let onStart: () -> Void
    let onSignupStart: (() -> Void)?
    let onSignupCancel: (() -> Void)?
    let selectedMuscleGroups: [String]

    var body: some View {
        VStack(spacing: Spacing.xl) {
            // Program overview
            VStack(spacing: Spacing.lg) {
                Text("Your Program is Ready!")
                    .font(.trainTitle)
                    .foregroundColor(.trainTextPrimary)

                // Program details card
                VStack(alignment: .leading, spacing: Spacing.md) {
                    Text(program.type.description)
                        .font(.trainTitle2)
                        .foregroundColor(.trainTextPrimary)

                    HStack {
                        Text("\(program.daysPerWeek) days/week")
                        Spacer()
                        Text("\(program.totalWeeks) weeks")
                    }
                    .font(.trainBody)
                    .foregroundColor(.trainTextSecondary)
                }
                .padding(Spacing.lg)
                .appCard()
            }

            Spacer()

            // Signup CTA
            Button("Create Account to Start Training") {
                onSignupStart?()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.horizontal, Spacing.xl)
        .charcoalGradientBackground()
        .sheet(isPresented: .constant(showSignup)) {
            PostQuestionnaireSignupView(
                onSignupSuccess: onStart,
                onSignupCancel: onSignupCancel
            )
        }
    }
}
```

---

## 8. Account Creation - PostQuestionnaireSignupView.swift

**File:** `trAInSwift/Views/PostQuestionnaireSignupView.swift`

Final signup screen with Apple Sign-In, Google Sign-Up, and email signup options.

```swift
struct PostQuestionnaireSignupView: View {
    @ObservedObject var authService = AuthService.shared
    @ObservedObject var viewModel = WorkoutViewModel.shared

    let onSignupSuccess: () -> Void
    let onSignupCancel: (() -> Void)?

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                // Header
                VStack(spacing: Spacing.sm) {
                    Text("Create Your Account")
                        .font(.trainTitle)
                        .foregroundColor(.trainTextPrimary)

                    Text("Save your program and start training")
                        .font(.trainSubtitle)
                        .foregroundColor(.trainTextSecondary)
                }

                // Sign up options
                VStack(spacing: Spacing.md) {
                    // Apple Sign-In
                    SignInWithAppleButton(.signUp) { request in
                        // Handle Apple Sign-In
                    } onCompletion: { result in
                        handleAppleSignIn()
                    }
                    .frame(height: ButtonHeight.standard)

                    // Email signup
                    Button("Sign up with Email") {
                        viewModel.showEmailSignup = true
                    }
                    .buttonStyle(.borderedProminent)

                    // Google Sign-Up (with comprehensive setup instructions)
                    Button("Continue with Google") {
                        handleGoogleSignUp()
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .background(Color.trainBackground.ignoresSafeArea())
        .sheet(isPresented: $viewModel.showEmailSignup) {
            EmailSignupSheet(
                onSignupSuccess: {
                    viewModel.showEmailSignup = false
                    viewModel.safeNavigate {
                        onSignupSuccess()
                    }
                },
                questionnaireData: viewModel.questionnaireData,
                generatedProgram: viewModel.generatedProgram
            )
        }
    }
}
```

---

## 9. Post-Signup Flow (Future Enhancement)

After successful account creation, users will go through:

1. **Notification Permissions** (`NotificationPermissionView.swift`)
2. **Referral Tracking** (`ReferralPageView.swift`)
3. **Final Onboarding** (`PostSignupFlowView.swift`)

These views exist but are not yet integrated into the main flow.

---

## Complete Flow Summary

```
ContentView
    ↓ (not authenticated)
OnboardingFlowView
    ↓ (showQuestionnaire = false)
WelcomeView
    ↓ ("Get Started" tapped)
QuestionnaireView
    ↓ (13 steps completed)
ProgramLoadingView
    ↓ (generation complete)
ProgramReadyView
    ↓ ("Create Account" tapped)
PostQuestionnaireSignupView
    ↓ (signup successful)
ContentView
    ↓ (now authenticated)
DashboardView
```

**Key Files in Order:**
1. `ContentView.swift` - App entry point
2. `OnboardingFlowView.swift` - Onboarding coordinator
3. `WelcomeView.swift` - Welcome screen
4. `QuestionnaireView.swift` - Questionnaire coordinator
5. `VideoInterstitialView.swift` - Video interstitials
6. `ProgramLoadingView.swift` - Loading screen
7. `ProgramReadyView.swift` - Program preview
8. `PostQuestionnaireSignupView.swift` - Account creation
9. `DashboardView.swift` - Main app (authenticated)

**Navigation Pattern:**
- Uses `NavigationStack` for proper view-to-view transitions
- Eliminates problematic sheet overlays from previous implementation
- Maintains questionnaire progress with back button support
- Handles authentication state changes automatically