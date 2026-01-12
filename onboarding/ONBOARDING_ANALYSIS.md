# trAIn Onboarding Analysis: Expert UX/UI Review

## Your Current Flow (15 screens)

```
WelcomeView → Section 1 Cover → 8 Questions → Section 2 Cover → 5 Questions →
ProgramLoadingView → ProgramReadyView → PostQuestionnaireSignupView → [Paywall]
```

**Section 1 "Availability" (8 questions):**
1. Goals (3 options)
2. Experience (4 levels)
3. Muscle Priority (body diagram, 0-3)
4. Equipment (expandable categories)
5. Injuries (body part grid)
6. Training Days (1-6 slider)
7. Session Duration (3 options)
8. Motivation (multi-select, optional)

**Section 2 "About You" (5 questions):**
1. Name
2. Date of Birth
3. Gender
4. Height
5. Weight

---

## Critical Issues

### 1. NO SKIP OPTION
**Both competitors have Skip on EVERY screen.** You have zero skip functionality. This is a major friction point - users who want to explore the app quickly bounce when forced through 13 mandatory questions.

**Impact:** High drop-off rate, especially for curious users who aren't committed yet.

### 2. NO PROGRESS INDICATOR ON WELCOME
Your WelcomeView shows nothing about what's coming. Gravl and Fitbod both preview app functionality with screenshots/mockups on the landing page. Users have no idea what they're signing up for.

### 3. SECTION COVERS ARE WASTED SCREENS
You have 2 cover pages ("Availability" and "About You") that add clicks without value. Neither competitor does this. They go straight into questions with clear headers.

**Recommendation:** Remove section covers entirely, or use them as value-reinforcement interstitials like Gravl does.

### 4. QUESTION ORDER IS BACKWARDS
You ask **personal details LAST** (name, age, gender, height, weight). Both competitors ask these **EARLY** because:
- It feels like personalisation is starting immediately
- Users are more engaged at the start
- Apple Health sync can auto-fill these (you don't offer this)
- Creates the "sunk cost" effect earlier

**Gravl order:** Reason → Body Stats → Experience → Goals → Frequency → Split → Muscles → Equipment → Notifications

**Fitbod order:** Goal → Habit → Experience → Equipment → Schedule → Body Stats → Referral

### 5. NO APPLE HEALTH INTEGRATION IN ONBOARDING
Both competitors prominently offer **Apple Health sync** to auto-fill body stats. You have no HealthKit integration during onboarding - users must manually enter everything.

**Impact:** Adds friction, feels less "smart", misses easy personalization win.

### 6. NO INTERSTITIALS / VALUE REINFORCEMENT
Gravl strategically places **3-4 interstitial screens** throughout their flow:
- Full-screen video of trainer working out
- Photo grid showing exercise variety
- Progress tracking preview with stats
- Personalized projection ("38% stronger in 3 months")

These break up the questionnaire monotony and remind users WHY they're answering questions.

**You have zero interstitials.** Just question after question.

### 7. MISSING "WHY" CONTEXT ON QUESTIONS
Gravl explains the purpose: *"This will help us recommend the right exercises and weights for you"*

Your subtitles are vague: *"Let's customise your training programme"* - doesn't explain HOW this question affects their program.

### 8. NO SMART RECOMMENDATIONS
Gravl shows: *"Based on your experience, we recommend 2-3 days per week"*

Your TrainingDaysStepView has a "Recommended" bracket but it's based on outdated experience level mapping (`0_months`, `0_6_months`) that doesn't match your actual experience options.

### 9. EQUIPMENT UX IS CONFUSING
Your expandable equipment cards with partial selection states (orange tint vs full accent) are complex. Users see:
- Full accent = all selected
- Orange tint = partial
- No visual indicator of how many sub-items are selected

**Fitbod approach:** Pick location → Pre-select equipment → Review/edit. Much cleaner.

**Gravl approach:** Pick gym type → Detailed equipment grid with images and search.

### 10. NO EQUIPMENT IMAGES
Both competitors show **images of equipment** in their selection screens. You use only text labels. Users who don't know the difference between "Pin-Loaded" and "Plate-Loaded" machines have no visual reference.

### 11. PROGRAM LOADING HAS NO SOCIAL PROOF
Gravl's loading screen shows:
- "Trusted by 100,000+ users"
- Real user testimonial with avatar and date
- Multi-step progress with percentages

Yours shows only a spinner with "Building Your Program" and 3 generic checklist items.

### 12. NO PERSONALIZED PROJECTION
Gravl shows **personalized results**: *"38% Stronger - for 3,921 users similar to you"* with a projected 1RM increase.

This is powerful psychological anchoring. Users see tangible expected outcomes BEFORE signing up.

### 13. SIGNUP COMES TOO LATE
Your flow: 13 questions → Loading → Program Ready → THEN signup

Both competitors show the program is "ready" and THEN ask for signup. But Fitbod's program summary screen is tappable/editable and lets users review before committing.

### 14. NO REFERRAL TRACKING
Both competitors ask "How did you hear about us?" with modern options (TikTok, Instagram, ChatGPT, Influencer). This is essential for marketing attribution.

### 15. MOTIVATION QUESTION IS LOW VALUE
Your MotivationStepView asks "Why have you considered using this app?" with options like "I lack structure" and "I need guidance". This doesn't affect program generation - it's purely analytics.

**Move to end as optional, or remove entirely.**

---

## What You're Missing (Feature Gaps)

| Feature | Gravl | Fitbod | trAIn |
|---------|-------|--------|-------|
| Skip on every screen | Yes | Yes | **No** |
| Apple Health sync | Yes | Yes | **No** |
| Interstitial value screens | 4+ | 0 | **0** |
| Smart recommendations | Yes | No | **Partial** |
| Equipment images | Yes | Yes | **No** |
| Equipment search | Yes | Yes | **No** |
| Social proof in flow | Yes | Yes | **No** |
| Personalized projection | Yes | No | **No** |
| Referral tracking | Yes | Yes | **No** |
| "Specific Days" scheduling | No | Yes | **No** |
| Consistency/habit question | No | Yes | **No** |
| Gym location presets | Yes | Yes | **No** |
| Program summary review | Yes | Yes | **Partial** |

---

## What You're Doing Well

1. **Interactive body diagram** for muscle selection - better than Gravl's static grid
2. **Sliding ruler inputs** for height/weight - nice tactile feel
3. **Split suggestion info card** - shows users what they'll get based on days
4. **Equipment sub-item selection** - more granular than competitors
5. **Confetti celebration** - delightful moment on program ready
6. **Clean visual hierarchy** - consistent card styling
7. **Progress bar per section** - clear step tracking (within sections)

---

## Recommended Redesign

### New Flow (14 screens, streamlined)

```
1. Welcome (with app preview mockups)
2. Goal (single select)
3. Body Stats (Apple Health OR manual - gender, age, height, weight combined)
4. Experience (4 levels with descriptions)
5. [INTERSTITIAL] - AI value prop with trainer video
6. Training Frequency (with smart recommendation)
7. Session Duration
8. Gym Type (Large/Small/Home/Bodyweight)
9. Equipment Review (pre-selected based on gym type, with images)
10. [INTERSTITIAL] - Progress tracking preview
11. Muscle Priority (body diagram, optional)
12. Injuries (optional, skip if none)
13. [LOADING] - with social proof + testimonial
14. Program Ready (with personalized projection)
15. Signup (Apple/Email)
16. Notifications
17. Referral (optional)
```

### Key Changes

1. **Add Skip to every question** - respect user autonomy
2. **Combine body stats into one screen** with Apple Health option
3. **Add 2-3 interstitial screens** with video/imagery
4. **Gym type → Equipment cascade** - smart pre-selection
5. **Add equipment images** and search functionality
6. **Add personalized projection** ("Users like you get X% stronger")
7. **Add social proof to loading** - testimonials, user count
8. **Add referral tracking** at the end
9. **Remove section covers** - they add friction without value
10. **Reorder questions** - personal info earlier, optional stuff later

---

## Priority Actions (Impact vs Effort)

### High Impact, Low Effort
1. Add Skip button to all questions
2. Remove section cover pages
3. Add referral question at end
4. Reorder questions (body stats earlier)
5. Add "why this matters" context to each question

### High Impact, Medium Effort
6. Add Apple Health integration for body stats
7. Add gym type presets with equipment pre-selection
8. Add equipment images
9. Add personalized projection screen
10. Add social proof to loading screen

### High Impact, High Effort
11. Add interstitial video/imagery screens
12. Implement equipment search functionality
13. Add "Specific Days" scheduling option (pick Mon/Wed/Fri)

---

## Copy Improvements

| Current | Recommended |
|---------|-------------|
| "What are your primary goals?" | "What's your #1 fitness goal?" |
| "Let's customise your training programme" | "This shapes your rep ranges and exercise selection" |
| "How confident do you feel in the gym?" | "How much lifting experience do you have?" |
| "This helps us match exercises to your comfort level" | "We'll pick exercises that match your skill level" |
| "Be realistic with your commitment" | "Based on your experience, we recommend X days" |
| "Building Your Program" | "Your AI coach is building your program..." |

---

## Summary

Your onboarding is **functional but forgettable**. It collects the right data but doesn't create excitement or demonstrate value. The competitors make users feel like they're already getting personalized coaching from screen 1.

**The killer onboarding formula:**
1. **Show value early** (app previews, AI messaging)
2. **Make it feel personal** (use their name, show smart recommendations)
3. **Break up the monotony** (interstitials with imagery)
4. **Reduce friction** (skip options, smart defaults, Apple Health)
5. **Create anticipation** (personalized projections, social proof)
6. **Celebrate the moment** (confetti, "program ready" fanfare)

You have #6. You need 1-5.
