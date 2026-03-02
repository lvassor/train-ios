<p align="center">
  <img src="../assets/train-logo-with-text_isolate_cropped_dark.svg" alt="train" width="280">
</p>

<p align="center">
  <em>Onboarding flow — questionnaire screens and user journey</em>
</p>

<p align="center">
  <strong>Created by</strong>: Brody Bastiman & Luke Vassor
</p>

---

# Onboarding Flow

The train app begins with an onboarding questionnaire that gathers information about the user — personal details, anthropometric metrics (height, weight), gym equipment availability, and training preferences. Two interstitial videos break up the questionnaire flow. After programme generation, the user creates an account and enters the main app.

## Complete User Journey (22 screens)

```
WelcomeView
    ↓
QuestionnaireView (15 steps, or 14 if Apple Health provides height/weight)
    ↓
ProgramLoadingView → ProgramReadyView
    ↓
PostQuestionnaireSignupView → AccountCreationLoadingView
    ↓
PostSignupFlowView
  ├─ NotificationPermissionView
  └─ ReferralPageView
    ↓
DashboardView
```

---

## Screen-by-Screen Flow

### 1. WelcomeView
App introduction with preview mockups (using `screenshot*.PNG` files in the `onboarding` folder), value proposition carousel, and CTA to begin the questionnaire or log in.

### Questionnaire (Steps 0–14)

The questionnaire is managed by `QuestionnaireView` with `totalSteps = 15`. A conditional `skipHeightWeight` flag (set when Apple Health provides height and weight data) shifts all subsequent steps forward by one position, reducing the flow to 14 steps.

| Step | Default Path | If skipHeightWeight | Purpose |
|------|-------------|---------------------|---------|
| 0 | GoalsStepView | GoalsStepView | Single or multi-select fitness goals |
| 1 | NameStepView | NameStepView | "What should we call you?" |
| 2 | HealthProfileStepView | HealthProfileStepView | Gender, age, Apple Health sync |
| 3 | HeightWeightStepView | ExperienceStepView | Height/weight (manual entry) |
| 4 | ExperienceStepView | FirstVideoInterstitialView | 4 experience levels with descriptions |
| 5 | FirstVideoInterstitialView | TrainingDaysStepView | Personal training value prop video |
| 6 | TrainingDaysStepView | SplitSelectionStepView | Training frequency with smart recommendation |
| 7 | SplitSelectionStepView | SessionDurationStepView | Training split choice |
| 8 | SessionDurationStepView | TrainingPlaceStepView | Session duration (20–90 min) |
| 9 | TrainingPlaceStepView | EquipmentStepView | Gym type — pre-populates equipment |
| 10 | EquipmentStepView | SecondVideoInterstitialView | Expandable cards with specific equipment items |
| 11 | SecondVideoInterstitialView | MuscleGroupsStepView | "train creates your perfect workout" video |
| 12 | MuscleGroupsStepView | InjuriesStepView | Body diagram, optional, select up to 3 |
| 13 | InjuriesStepView | ReviewSummaryStepView | Optional injury selection. CTA: "Generate Your Program" |
| 14 | ReviewSummaryStepView | — | Editable summary of all choices |

When `skipHeightWeight = true`, step 14 is unused and the final step becomes 13 (`ReviewSummaryStepView`). The CTA on the final step reads "Generate Your Program".

### Post-Questionnaire Screens

**15. ProgramLoadingView**
"Building Your Program" with animated progress bar. Calls `generateProgram()` and transitions automatically when complete.

**16. ProgramReadyView**
Displays generated programme summary with confetti animation. Shows workout split, muscle groups, frequency, and session length. CTA: "Create Your Account".

**17. PostQuestionnaireSignupView**
Account creation via Apple Sign-In, Google Sign-In, or email. Programme data is preserved through the signup flow.

**18. AccountCreationLoadingView**
Loading animation during account registration and programme persistence.

**19. NotificationPermissionView**
Push notification opt-in. If accepted, triggers the native Apple notification permission modal.

**20. ReferralPageView**
Optional — "How did you hear about us?" attribution tracking.

**21. PaywallView**
Premium subscription conversion (currently skipped for MVP via `skipPaywallForMVP` flag).

**22. DashboardView**
Main app interface. `ContentView` detects `authService.isAuthenticated = true` and shows the dashboard.

---

## Key Implementation Details

- **State Persistence**: `QuestionnaireStateManager` saves progress so users can resume if they leave mid-flow
- **Video Interstitials**: Rendered full-screen at the root level, outside the scrollable questionnaire content
- **Final Step Detection**: `let finalStep = skipHeightWeight ? 13 : 14` determines when to show "Generate Your Program" CTA
- **Returning Users**: Authenticated users retaking the questionnaire skip `PostQuestionnaireSignupView` and `AccountCreationLoadingView`

## Key Files

| File | Purpose |
|------|---------|
| `Views/QuestionnaireView.swift` | Questionnaire orchestrator (step routing, totalSteps=15) |
| `Views/QuestionnaireSteps.swift` | All step view definitions |
| `Views/Steps/HealthProfileStepView.swift` | Apple Health sync, skipHeightWeight flag |
| `Views/Steps/HeightWeightStepView.swift` | Manual height/weight entry |
| `Views/Steps/ReviewSummaryStepView.swift` | Editable review of all questionnaire choices |
| `Views/Onboarding/OnboardingFlowView.swift` | Welcome → Questionnaire router |
| `Views/Onboarding/PostSignupFlowView.swift` | Post-account-creation steps |
| `Views/Onboarding/NotificationPermissionView.swift` | Push notification opt-in |
| `Views/Onboarding/ReferralPageView.swift` | Attribution tracking |
| `Views/ProgramLoadingView.swift` | Programme generation progress |
| `Views/ProgramReadyView.swift` | Programme summary with confetti |

---

Made with ❤️ by Brody Bastiman & Luke Vassor
