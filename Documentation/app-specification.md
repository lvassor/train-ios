Complete Fitness App Development Specification for Claude Code
You are working on a Swift-based iOS fitness app called "Train". An MVP version already exists with some pages implemented. Your task is to:

Audit existing pages against the specifications below
Update existing pages to match all requirements (add missing elements, fix styling, implement missing functionality)
Create any missing pages from scratch
Connect all navigation flows according to the functional requirements
Ensure consistency across the entire app using the design system specifications
DESIGN SYSTEM - APPLY TO ALL SCREENS
Border Radius Standards
Large CTA buttons: 30px
Cards/major containers: 15px
Input fields: 10px
Pills/tags/toggles: 20px
Small UI elements: 5-8px
Modal corners: 20px
Icon containers: 15px
Spacing Standards
Screen edge padding: 20-40px
Card internal padding: 15-20px
Between cards/sections: 12-15px
Between major sections: 20-30px
List item spacing: 10-15px
Button bottom margin: 40px from screen edge
Typography Hierarchy
Page titles: Large, bold
Section titles: Medium-large, bold
Subtitles/descriptions: Medium, regular weight
Body text: Regular size
Labels: Small-medium, bold or regular
Button text: Medium-large, bold
Input placeholders: Regular, medium size
Border Standards
Card borders: 1-2px
Input field borders: 1-2px
Button borders (outlined): 2px
Dashed borders: 2px dashed
Modal borders: 2px
Common Interactive States
Selected tabs: Filled background within container
Unselected tabs: Transparent/no fill
Selected cards: Emphasized border or fill
Completed items: Checkmarks filled/darker
In-progress items: Checkmarks lighter/outlined
Inactive items: Reduced opacity or lighter appearance
Progress Bars
Horizontal bars with rounded ends
Filled portion indicates completion
Unfilled portion lighter/muted
Typically 5-8px height
Full or partial width depending on context
APP FLOW & NAVIGATION STRUCTURE
First Time User Journey
Splash Screen
Questionnaire (8 screens with dedicated progress bar)
About Yourself (4 screens with dedicated progress bar)
Building Programme (loading)
Programme Ready (summary)
Account Creation
Creating Account (loading)
Paywall
Home Page
Returning User Journey
Welcome Back (Login) - NOT splash screen
Home Page
Alternative Flows
Password Reset Flow (3 screens)
Exercise Library (from home toolbar)
Account Settings (from home toolbar)
Workout Logging Flow
Exercise History View
SCREEN-BY-SCREEN SPECIFICATIONS
1. SPLASH SCREEN
Visual Layout:

Full screen white background
Train logo centered vertically and horizontally (large size, mountain/landscape icon placeholder)
Bottom section:
"Get Started" button: Large rounded rectangle (border-radius: 30px), spans full width with side padding 20px, centered, bottom margin 40px
Text below button: "If you already have an account, log in" - centered
"log in" is a hyperlink/tappable text
Functional Requirements:

On app first launch: Show this screen
"Get Started" button → Navigate to Questionnaire Screen 1 (Primary Goals)
"log in" link → Navigate to Welcome Back (Login) screen
CRITICAL: On subsequent app opens for users who have logged in before, skip this screen and show Welcome Back screen instead
Non-Functional Requirements:

Button should have tap feedback (slight scale or opacity change)
Smooth transitions between screens
2. QUESTIONNAIRE SECTION (8 Screens)
Common Elements for ALL Questionnaire Screens:

Back arrow (←) in top-left corner → Navigate to previous screen
Progress bar below header: 8 segments, fill progressively (Screen 1: 12.5%, Screen 2: 25%, Screen 3: 37.5%, Screen 4: 50%, Screen 5: 62.5%, Screen 6: 75%, Screen 7: 87.5%, Screen 8: 100%)
Progress bar styling: Horizontal, rounded ends (border-radius: 10px), height ~6px
"Continue" button at bottom: Rounded rectangle (border-radius: 30px), full width with side padding, bottom margin 40px, centered text
All screens vertically scrollable if content exceeds viewport
Screen 1: Primary Goals
Visual Layout:

Title: "What are your primary goals?" - large, bold, centered
Subtitle: "Let's customise your training programme" - medium text, centered
Three full-width cards (border-radius: 15px, white background, border 2px):
Get stronger: Bold title, "Build maximum strength and power" subtitle
Build Muscle Mass: Bold title, "Both size and definition" subtitle
Tone Up: Bold title, "Lose fat while building muscle" subtitle
Cards vertically stacked with 15px spacing
Functional Requirements:

Cards are tappable/selectable (single selection)
Selected card: Show visual highlight (border color change or background fill)
Continue button: Only enabled when a selection is made
Store selection in user profile data
Continue → Navigate to Screen 2 (Current Experience)
Screen 2: Current Experience
Visual Layout:

Title: "What is your current experience with strength training?" - bold, large
Subtitle: "This helps us set the right intensity"
Four full-width cards (border-radius: 15px):
0 months: "Complete beginner" subtitle
0 - 6 months: "Learning the basics" subtitle
6 months - 2 years: "Starting to find your feet" subtitle
2+ years: "Feeling confident" subtitle
Functional Requirements:

Single selection
Visual highlight on selection
Store experience level
Continue → Navigate to Screen 3 (Muscle Groups)
Screen 3: Muscle Group Priority
Visual Layout:

Title: "What muscle groups do you want to prioritise?" - bold
Subtitle: "Select up to 3 muscle groups"
Grid layout: 2 columns
Pills/buttons (border-radius: 20px, white background, border 2px):
Row 1: Shoulders | Chest
Row 2: Back | Abs
Row 3: Triceps | Biceps
Row 4: Glutes | Quads
Row 5: Hamstrings | Calves
15px spacing between buttons horizontally and vertically
Functional Requirements:

Multi-select (maximum 3)
Selected buttons: Visual highlight
If user tries to select 4th: Show brief error message or disable other options
Store selected muscle groups array
Continue → Navigate to Screen 4 (Equipment)
Screen 4: Equipment Availability
Visual Layout:

Title: "What equipment do you have at your availability?" - bold
Subtitle: "Select all that apply"
Six full-width cards (border-radius: 15px, vertical stack, 12px spacing):
Dumbbells - with info icon (⊕ or ⓘ) on right inside border
Barbell - with info icon
Kettlebells - with info icon
Cable Machines - with info icon
Pin-loaded Machines - with info icon
Plate-loaded Machines - with info icon
Each card: Text left-aligned, icon right-aligned within border
Functional Requirements:

Multi-select (unlimited)
Selected cards: Visual highlight
Info icon tap: Open equipment popup modal (see Equipment Popup spec below)
Store equipment array
Continue → Navigate to Screen 5 (Injuries)
Equipment Popup Modal:

Visual Layout:
Modal overlay (semi-transparent background)
Rounded rectangle card (border-radius: 20px), centered
Top 40%: High-resolution image placeholder of equipment
Bottom 60%:
Equipment name as heading (bold)
Text description area (currently placeholder text)
Close button (X) in top-right corner of modal
Functional Requirements:
Tap outside modal or X button → Close modal, return to Screen 4
Modal should slide up with animation
Screen 5: Injuries/Limitations
Visual Layout:

Title: "Do you have any current injuries or limitations?" - bold
Subtitle: "Select any that may impact your training"
Grid layout: 2 columns (same as Screen 3)
Pills (border-radius: 20px):
Row 1: Shoulders | Chest
Row 2: Back | Abs
Row 3: Triceps | Biceps
Row 4: Glutes | Quads
Row 5: Hamstrings | Calves
Functional Requirements:

Multi-select (unlimited)
Visual highlight on selection
Store injuries array (can be empty)
Continue → Navigate to Screen 6 (Training Frequency)
Screen 6: Training Frequency
Visual Layout:

Title: "How many days per week would you like to commit to strength training?" - bold
Subtitle: "Be realistic with your commitment"
Four rounded squares in horizontal row (border-radius: 20px, border 2px):
2 | 3 | 4 | 5
Large, bold, centered numbers
Equal spacing (10px between)
Square/slightly rectangular aspect ratio
Functional Requirements:

Single selection
Visual highlight on selection
Store training frequency (2-5 days)
Continue → Navigate to Screen 7 (Session Duration)
Screen 7: Session Duration
Visual Layout:

Title: "How long would you like each session to be?" - bold
Subtitle: "Let's customise your training programme"
Three full-width cards (border-radius: 15px, 15px spacing):
30-45 minutes: "Quick and effective" subtitle
45-60 minutes: "Balanced approach" subtitle
60-90 minutes: "Maximum volume" subtitle
Functional Requirements:

Single selection
Visual highlight
Store session duration
Continue → Navigate to Screen 8 (Motivation)
Screen 8: Motivation/Reasons
Visual Layout:

Title: "Why have you considered using this app?" - bold
Subtitle: "Select all that apply"
Six full-width cards (border-radius: 15px, 12px spacing):
"I lack structure in my workouts"
"I need more guidance"
"I lack confidence when I exercise"
"I need motivation"
"I need accountability"
"Other: user can type here" - with editable text field appearance
Functional Requirements:

Multi-select (unlimited)
Card 6: Tapping activates text input field for custom reason
Visual highlight on selection
Store motivations array
Continue → Navigate to About Yourself Screen 1 (Age)
3. ABOUT YOURSELF SECTION (4 Screens)
Common Elements:

Back arrow (←) top-left → Previous screen
New progress bar: 4 segments (separate from questionnaire)
Progress: Screen 1: 25%, Screen 2: 50%, Screen 3: 75%, Screen 4: 100%
Continue button (except Screen 4 which says "Generate your programme!")
Screen 1: Age
Visual Layout:

Title: "Age" - large, bold, centered
Subtitle: "The helps us tailor your intensity" - centered
Large rounded rectangle container (border-radius: 20px), centered, white background
Contains age number in large, bold text
Full-width with 20px side padding
Functional Requirements:

Native Swift vertical scroll picker for age input
Age range: 16-100
Default: 28
Store age value
Continue → Navigate to Screen 2 (Gender)
Screen 2: Gender
Visual Layout:

Title: "Gender" - large, bold, centered
Subtitle: "We may require this for exercise prescription"
Three options:
Male card: Rounded rectangle (border-radius: 15px), border 2px
Simple line icon of person with short hair (centered top)
"Male" text below (bold, centered)
Female card: Same styling, right of Male
Line icon with longer hair
"Female" text
Other/Prefer not to say: Full-width card below
Text centered
Male/Female in 2-column grid, 15px spacing
15px spacing between top row and bottom card
Functional Requirements:

Single selection
Visual highlight on selection
Store gender value
Continue → Navigate to Screen 3 (Height)
Screen 3: Height
Visual Layout:

Title: "Height" - large, bold, centered
Subtitle: "This helps us calculate your body metrics"
Unit toggle: Two pill buttons (border-radius: 20px), connected
"cm" (left, default selected)
"ft/in" (right)
Vertical sliding ruler (border-radius: 25px, white background, border, ~60% screen width, centered):
Values shown: 190, 185, 180, 175, 170 (vertically stacked)
Major ticks every 10 units (bold numbers)
Minor ticks every 1 unit
Selected value (default 180) larger and bold
Horizontal indicator line at selected value
Scrollable vertically
Functional Requirements:

Toggle between cm and ft/in
Use vertical sliding ruler library for smooth scrolling
cm mode:
Range: 140-220 cm
Default: 180 cm
Increments of 1 cm
ft/in mode:
Range: 4'7" - 7'2"
Default: 5'10"
Increments of 1 inch
Store height value with unit
Selected value dynamically updates as user scrolls
Continue → Navigate to Screen 4 (Weight)
Screen 4: Weight
Visual Layout:

Title: "Weight" - large, bold, centered
Subtitle: "This helps us calculate your body metrics"
Unit toggle: "kg" (left, default selected) | "lbs" (right)
Horizontal sliding ruler (border-radius: 15px, full-width with 20px side padding):
Current value "80" displayed large and bold above slider, centered
Scale shows: 70, 75, 80, 85, 90 (horizontally)
Major ticks every 5 units
Minor ticks between
Vertical indicator line at current selection
Button text: "Generate your programme!" (instead of "Continue")
Functional Requirements:

Toggle between kg and lbs
Use horizontal sliding ruler library (same as height but horizontal orientation)
kg mode:
Range: 40-200 kg
Default: 80 kg
Increments of 1 kg
lbs mode:
Range: 88-440 lbs
Default: 176 lbs (converted from 80kg)
Increments of 1 lb
Store weight value with unit
"Generate your programme!" button → Navigate to Building Programme screen
4. BUILDING PROGRAMME (Loading Screen)
Visual Layout:

Full screen white background
Train logo (large, centered at top third of screen)
"Building Your Programme" - large, bold, centered below logo
Progress bar: Horizontal, ~80% screen width, centered, approximately 70% filled, rounded ends (border-radius: 10px)
Checklist (vertically stacked, left-aligned as group, centered horizontally):
"Analysing your goals" - Checkmark (✓) icon left, completed state (darker)
"Selecting exercises" - Checkmark icon left, completed state
"Finalising programme" - Checkmark icon left, in-progress state (lighter)
20px vertical spacing between checklist items
Functional Requirements:

Animation: Checklist items fade in from bottom sequentially
Simulate loading: 3-5 seconds total
Progress bar fills from 0% to 100% smoothly
Checklist items complete one by one:
Item 1 completes at ~33%
Item 2 completes at ~66%
Item 3 completes at ~100%
On completion → Navigate to Programme Ready screen
Backend: This is when the app should generate the user's programme based on all questionnaire answers
5. PROGRAMME READY (Summary Screen)
Visual Layout:

Title: "Programme Ready!" - large, bold, centered
Confetti animation overlaying title area (celebrate moment)
Subtitle: "Your personalised plan is complete" - centered
Four summary cards (border-radius: 15px, white background, border, 15px spacing):
Workout Split:
"Workout Split" label (smaller text, top)
"[Split Type]" value (large, bold) - e.g., "Push Pull Legs"
Prioritised Muscle Groups:
"Prioritised Muscle Groups" label
"[Muscle 1], [Muscle 2], [Muscle 3]" (bold) - from questionnaire
Frequency:
"Frequency" label
"X days per week" (bold) - from questionnaire
Session Length:
"Session Length" label
"[Duration]" (bold) - from questionnaire (e.g., "45-60 minutes")
"Start training now!" button at bottom (border-radius: 30px, full width, 40px bottom margin)
Functional Requirements:

Confetti animation plays once on screen load
Display actual user data from questionnaire in summary cards
Programme generation logic:
2-3 days → Full Body split
4 days → Upper/Lower split
5 days → Push/Pull/Legs split
Prioritize selected muscle groups in exercise selection
Filter exercises by available equipment
Avoid exercises targeting injured body parts
Adjust volume based on experience level
"Start training now!" → Navigate to Account Creation screen
6. ACCOUNT CREATION
Visual Layout:

Train logo at top, large, centered
Title: "Create Account" - bold, centered (below logo)
Three input fields (border-radius: 10px, light background, full-width with 20px side padding, left-aligned text):
"Full Name" - text input
"Email" - email input
"Password" - secure text input with eye icon (👁) on right
Terms acceptance: Checkbox with text "I accept the terms and conditions" - centered, below inputs
Text at bottom: "If you already have an account, log in" - centered
"log in" is hyperlink
"Create account" button at bottom (border-radius: 30px, full width)
Functional Requirements:

All fields required
Email validation: Must contain @ and domain (e.g., .com, .co.uk)
Password requirements: Minimum 8 characters
Eye icon: Toggle password visibility (show/hide characters)
Terms checkbox: Must be checked to enable button
Button states:
Disabled (grayed out): Until all fields valid + terms accepted
Enabled (colored): When all requirements met
"log in" link → Navigate to Welcome Back (Login) screen
"Create account" button (when enabled) → Navigate to Creating Account loading screen
Backend: Create user account in database with all collected data
Validation Messages:

Show inline error messages for invalid inputs
Email: "Please enter a valid email address"
Password: "Password must be at least 8 characters"
7. CREATING ACCOUNT (Loading Screen)
Visual Layout:

Train logo at top, large, centered
Loading spinner below logo (standard iOS circular spinner)
"Creating Your Account" text below spinner - centered, medium-large font
All elements vertically centered as group
Functional Requirements:

Show spinner animation
Simulate account creation: 2-3 seconds
Backend:
Save all user data to database
Create user authentication credentials
Generate initial workout programme
On completion → Navigate to Paywall screen
8. PAYWALL
Visual Layout:

Full screen
Train logo at top, large, centered
Title: "Free 7 Day Trial" - large, bold, centered
Subtitle: "Your programme is ready to go" - centered
Description: "Train with structure, guidance and progress in mind." - centered
Two subscription cards (border-radius: 15px, white background, border 2px, 15px spacing):
Annual Plan:
"Most Popular" badge (top right, border-radius: 15px, colored background)
"Annual Plan" (bold, left-aligned)
"£8.33/mo" (bold, right-aligned, same line as title)
"7 days free, then £99.99/year" (smaller text, left-aligned)
Monthly Plan:
"Monthly Plan" (bold, left-aligned)
"£13.99/mo" (bold, right-aligned)
"7 days free." (smaller text, left-aligned)
"Cancel anytime." text - centered, between cards and button
"Start free trial!" button at bottom (border-radius: 30px, full width, 40px bottom margin)
Functional Requirements:

Single selection (either Annual or Monthly)
Selected card: Visual highlight
Default selection: Annual Plan
"Start free trial!" → Trigger native iOS App Store subscription flow
Native App Store Modal:
Full screen overlay with dark background
"Double Click to Subscribe" text with icon (top right)
App Store modal (rounded top, border-radius: 20px):
"App Store" title (top left)
X close button (top right)
Train app icon (centered, border-radius: 15px)
Subscription details:
"1-week free trial"
"Starting today"
"£99.99 per year" (or £13.99/month)
"Starting on [Date]"
Terms text (multiple lines, small font):
"No commitment. Cancel at any time in Settings >"
"Apple Account at least one day before each renewal date."
"Plan automatically renews until cancelled."
Account email display
Confirm button (circular, centered, fingerprint/Touch ID icon)
"Confirm with Side Button" text
After subscription confirmed → Navigate to Home Page
Backend:
Integrate with Apple's StoreKit/RevenueCat
Handle subscription status
Grant access to app features
9. HOME PAGE
Visual Layout:

Header Section:
"Hey, [UserName]" - bold, large, left-aligned at top
"You're killing it this week" - medium text, left-aligned below name
🔥 Flame icon with "0" badge - top right corner, aligned with name
Programme Progress Card (border-radius: 15px, white background, border, full-width):
"Programme Progress" label with dropdown chevron (˅) on right
"Week X of Y" - large, bold below label
Progress bar below (rounded ends, dynamically filled based on week)
Collapsed state by default
Your Weekly Sessions Section:
"Your Weekly Sessions" - bold, left-aligned
"X/Y complete" - medium text, left-aligned below
Session bubbles (border-radius: 25px, full-width, 10px spacing):
Completed sessions: Checkmark icon (✓) on right, highlighted/filled style
Incomplete sessions: No checkmark, default style
Examples: "Upper Body", "Lower Body", "Push", "Pull", "Legs"
Next Workout Card (border-radius: 15px, white background, border):
"Next Workout" label (bold, left-aligned)
"[WorkoutType] • X exercises" (e.g., "Push • 6 exercises")
"Log this workout" button inside card (border-radius: 10px, border, full-width within card padding)
Upcoming Workouts (similar cards, no internal button):
"Pull • 7 exercises"
"Legs • 5 exercises"
etc.
Bottom Navigation Bar (fixed at bottom, 4 icons evenly spaced):
🏋️ Dumbbell icon (Exercise Library)
🏆 Rosette/Medal icon (Milestones)
▶️ Play icon (Video Library)
👤 Person icon (Account Settings)
Functional Requirements:

Dynamic user greeting: Pull user's first name from profile
Streak counter:
Track consecutive days of completed workouts
Update flame icon badge number
Reset to 0 if user misses a day
Programme Progress dropdown:
Collapsed (default): Show chevron pointing down (˅)
Tap to expand: Chevron rotates up (^), reveal expanded content (see Expanded Programme Progress spec)
Tap again to collapse: Return to collapsed state
Weekly Sessions:
Calculate completion: Count completed workouts / total weekly workouts
Display sessions based on user's split (Full Body, Upper/Lower, PPL)
Tapping completed session → Navigate to Workout History page (see spec)
Update checkmarks as workouts are completed
Reset weekly: Every Monday at 00:00, reset all sessions to incomplete
Next Workout:
Display the next uncompleted workout in the weekly schedule
Show exercise count from programme
"Log this workout" button → Navigate to Workout Session page (see spec)
Bottom Navigation:
Dumbbell icon → Navigate to Exercise Library page (see spec)
Rosette icon → Navigate to Milestones page (placeholder for now)
Play icon → Navigate to Video Library page (placeholder for now)
Person icon → Navigate to Account Settings page (see spec)
Active state: Highlight current page icon
Refresh on return: When user returns to home from other pages, refresh data (completed workouts, streak, etc.)
Expanded Programme Progress (Dropdown Content)
Visual Layout (revealed when dropdown expanded):

Below progress bar, within same card:
Split section:
"Split" label (small text)
"[Split Type]" in rounded rectangle (border-radius: 10px, light fill) - e.g., "Upper/ Lower/ Push/ Pull/ Legs"
Duration & Frequency (two-column row):
Left: "Duration" label above, "[Duration]" in rounded rectangle (e.g., "45-60 min")
Right: "Frequency" label above, "X days" in rounded rectangle
Priority Muscle Groups:
"Priority Muscle Groups" title
Three body diagram icons in horizontal row:
Icon 1: Front torso with highlighted muscle group (e.g., chest highlighted in yellow)
Icon 2: Body part with highlighted muscle group (e.g., legs with quads highlighted)
Icon 3: Body part with highlighted muscle group (e.g., upper body with shoulders highlighted)
Labels below each: "[Muscle1]", "[Muscle2]", "[Muscle3]"
Functional Requirements:

Display actual user data from profile/programme
Body diagrams should accurately highlight selected muscle groups from questionnaire
Muscle group colors should match app theme
10. WELCOME BACK (LOGIN)
Visual Layout:

Train logo at top, large, centered
Title: "Welcome Back" - large, bold, centered
Two input fields (border-radius: 10px, light background, left-aligned):
"Email" - email input
"Password" - secure text input with eye icon (👁) on right
"Forgot Password?" link - right-aligned below password field
Large vertical spacing
"Log In" button at bottom (border-radius: 30px, full width, 40px bottom margin)
Functional Requirements:

Email and password required
Eye icon: Toggle password visibility
"Forgot Password?" → Navigate to Reset Password flow (Screen 1)
"Log In" button:
Validate credentials against database
If correct → Navigate to Home Page
If incorrect → Show error message "Invalid email or password"
Remember device: Implement auto-login for returning users
Important: This screen should be shown instead of Splash Screen for returning users
11. PASSWORD RESET FLOW (3 Screens)
Screen 1: Reset Password - Enter Email
Visual Layout:

Back arrow (←) top left → Return to Login screen
Train logo, centered
Title: "Reset Password" - bold, centered
"Email" input field (border-radius: 10px, light background, full-width)
"Enter your email and we'll send you a reset code" - centered below input
Large vertical spacing
"Remember your password? Log In" text at bottom - centered ("Log In" is link)
"Continue" button at very bottom (border-radius: 30px, full width, 40px bottom margin)
Functional Requirements:

Email validation required
"Continue" button:
Verify email exists in database
Send 6-digit code to email
Navigate to Screen 2
"Log In" link → Navigate to Welcome Back screen
Backend: Generate random 6-digit code, store with expiration (10 minutes), send via email service
Screen 2: Reset Password - Enter Code
Visual Layout:

Modal overlay (semi-transparent background)
Rounded rectangle card (border-radius: 20px), centered, white background, border 2px
Mail/envelope icon with person indicator (centered at top)
Title: "Reset Email Sent" - bold, centered
Subtitle: "Enter the 6 digit code" - centered
Warning text: "Check your junk inbox if you do not receive your code" - centered, smaller
Six square input boxes (border-radius: 8px, border 2px, equal size, horizontally centered):
One digit per box
Auto-focus and advance to next box
iOS keyboard visible at bottom with suggestions bar
Functional Requirements:

Six separate single-digit input fields
Auto-advance to next field on digit entry
Auto-submit when 6th digit entered
Validate code against database:
If correct → Navigate to Screen 3
If incorrect → Show error "Invalid code. Please try again."
Code expires after 10 minutes
"Resend code" option if user doesn't receive (not shown in wireframe but recommended)
Tap outside modal or X button (if added) → Return to Screen 1
Screen 3: Create New Password
Visual Layout:

Train logo, large, centered at top
Title: "Create New Password" - bold, centered
Two input fields (border-radius: 10px, light background):
"New password" - secure text with eye icon (👁)
"Confirm new password" - secure text with eye icon
Large vertical spacing
"Continue" button at bottom (border-radius: 30px, full width, 40px bottom margin)
Functional Requirements:

Both fields required
Password requirements: Minimum 8 characters
Eye icons: Toggle password visibility independently
Validation:
Passwords must match
If don't match → Show error "Passwords do not match"
"Continue" button:
Update password in database
Show success message "Password updated successfully"
Navigate to Welcome Back (Login) screen
Backend: Hash password before storing
12. EXERCISE LIBRARY (from Home toolbar)
Visual Layout:

Header: "Exercise Library" - bold, centered
Back arrow (←) top left → Return to Home
Filter section at top:
"Filter by:" label
Two dropdown/filter buttons (border-radius: 10px):
"Muscle Group" - opens muscle group filter
"Equipment" - opens equipment filter
Exercise cards (vertically scrollable, full-width):
Each card (border-radius: 15px, border, 12px spacing):
Exercise thumbnail (left side, square with rounded corners)
Exercise name (bold, large)
Muscle group tags (small pills below name)
Equipment needed (small text/icons)
Functional Requirements:

Display all exercises from database
Vertical scrolling with smooth performance
Filter by Muscle Group:
Tap opens modal/sheet with muscle group checkboxes
Multi-select
Apply filter → Show only exercises targeting selected groups
Filter by Equipment:
Tap opens modal/sheet with equipment checkboxes
Multi-select
Apply filter → Show only exercises using selected equipment
Combined filters: Show exercises matching ALL active filters (AND logic)
Tap exercise card → Navigate to Exercise Detail page (Demo tab)
Search bar (optional but recommended): Free text search by exercise name
Bottom navigation bar visible
13. ACCOUNT SETTINGS (from Home toolbar)
Visual Layout:

Header: "Account Settings" - bold, centered
Back arrow (←) top left → Return to Home
Profile section (card at top):
User name (large, bold)
Email (smaller text)
Profile picture placeholder
Settings sections (vertically stacked cards):
Subscription card:
"Your Plan" heading
Plan name (e.g., "Annual - £99.99/year")
Next billing date
"Manage Subscription" button → Opens iOS subscription management
Programme card:
"Your Programme" heading
Current split (e.g., "Push Pull Legs")
"Retake Quiz" button → Confirm dialog, then restart questionnaire
Account actions:
"Log Out" button (border-radius: 10px, full-width)
"Delete Account" button (red text, below logout)
Functional Requirements:

Display user's actual profile data
Manage Subscription → Opens native iOS subscription settings (StoreKit)
Retake Quiz:
Show confirmation dialog: "This will reset your programme. Continue?"
If confirmed → Clear current programme, navigate to Questionnaire Screen 1
Preserve account but allow re-answering all questions
Log Out:
Show confirmation dialog
Clear session/auth token
Navigate to Welcome Back (Login) screen
Ensure user must log in again
Delete Account:
Show strong confirmation: "This will permanently delete your account and all data. This cannot be undone."
Require password re-entry for security
If confirmed → Delete all user data from database, cancel subscription, navigate to Splash Screen
Bottom navigation bar visible
14. WORKOUT LOGGING FLOW
Screen 1: Workout Session Overview
Visual Layout:

Header:
Back arrow (←) left → Return to Home
"[WorkoutType] Workout" centered (e.g., "Push Workout")
Timer "00:00" right (elapsed time, starts at 0)
Exercise cards (vertically scrollable, full-width, border-radius: 15px):
Each card:
Exercise thumbnail (left, square, rounded corners)
Exercise name (bold, next to thumbnail)
"X sets • Y-Z reps" (rep range)
Completed state: Entire card highlighted/filled when exercise submitted
Cards stack vertically with 12px spacing
Functional Requirements:

Display all exercises for this workout from user's programme
Elapsed timer:
Starts at 00:00 when user opens screen
Counts up continuously (MM:SS format)
Persists even if user navigates away and returns
Stops when all exercises completed
Tap exercise card → Navigate to Exercise Detail page (Logger tab)
Completed exercises:
Highlight card (different background/border)
Show checkmark or other completion indicator
Move completed exercises to bottom (optional)
Exit behavior:
If workout incomplete: Show dialog "Save progress?" → Yes (save partial), No (discard), Cancel (stay)
If workout complete: Auto-save and show completion screen (optional celebration)
Bottom toolbar: Hide or minimize during workout
Keep screen awake: Prevent auto-lock during active workout
Screen 2: Exercise Detail - Logger Tab
Visual Layout:

Header:
Back arrow (←) left → Return to Workout Session Overview
Exercise name centered (e.g., "Barbell Bench Press")
Timer "00:00" right (same elapsed timer from overview, continues)
Tab toggle (border-radius: 20px, light fill container):
"Logger" tab (left, SELECTED by default, white fill)
"Demo" tab (right, unselected, no fill)
Logger Content:
Exercise info card (border-radius: 15px, light fill, full-width):
Exercise thumbnail (left, square, rounded corners)
Exercise name (bold)
"X sets • Y-Z reps" (rep range)
Live rep counter (top right, large text):
Shows "+N" in green when user exceeds previous session
Only appears after first set exceeds previous
Dynamically updates as more sets completed
Rest timer button (appears only after completing a set):
Rounded rectangle (border-radius: 10px, light fill)
"02:00" (2 minutes default) centered, medium-large font
Width ~50% of screen, centered horizontally
Below exercise info card, above suggested warm-up
Suggested warm-up set (text):
"Suggested warm-up set" label
"X kg (50-70%) • 10 reps" - smaller text, left-aligned
Set tracker grid:
Enumerated list (1, 2, 3...) on left
Each row:
Set number (left, bold)
Weight input: "[X] kg" (rounded rectangle, border-radius: 10px, white background, tappable)
Reps input: "[X]" (rounded rectangle, border-radius: 10px, white background, tappable)
Checkmark circle (right)
Rows 1-N based on prescribed sets
10px spacing between rows
Unit toggle (kg/lbs):
Small toggle within this section
Switches all weight displays
"Add Set" button (border-radius: 15px, dashed border 2px):
"Add Set" text centered
Full-width with side padding
Action buttons (right side, vertically stacked):
Notes/clipboard icon (circular, outlined)
Refresh/repeat icon (circular, outlined)
"Submit exercise" button at bottom (border-radius: 30px, light fill, full-width, 20px above screen edge)
Functional Requirements:

Tab switching:
Logger tab active by default
Tap "Demo" → Show demo content (see Demo Tab spec)
Maintain data when switching tabs
Live rep counter:
Compare current workout sets to last workout of same type
Track total additional reps across all sets
Show "+N" in green (top right) when user exceeds previous total
Update dynamically as each set completed
If user hasn't exceeded yet, don't show counter
Set completion workflow:
User taps weight input → Number pad keyboard opens, enter weight
User taps reps input → Number pad opens, enter reps
User taps checkmark → Set marked complete:
Checkmark fills/darkens
Rest timer button appears below exercise card
Input fields lock (can't edit)
User taps rest timer button → Timer starts countdown:
Show countdown animation (2:00 → 1:59 → ... → 0:00)
Play sound/haptic when timer ends
Timer button disappears, next set row becomes active
Repeat for each set
Rest timer:
Default: 2 minutes (120 seconds)
User can customize rest time in settings (future feature)
Countdown from set time to 0:00
Visual/audio/haptic notification when complete
Can be skipped (X button or tap outside)
Timer disappears after completion or skip
Add Set button:
Adds new row to set tracker
Increments set number
Pre-fills weight with last completed set
Allows for drop sets, additional volume, etc.
Action buttons:
Notes icon → Opens text field to add notes for this set/exercise
Refresh icon → Repeats the last set data (copy weight/reps to new row)
Unit toggle (kg/lbs):
Switches all weight inputs and displays
Performs conversion (1 kg = 2.205 lbs)
Saves user preference
Submit exercise:
Validation: At least one set must be completed
If incomplete sets: Show dialog "You have incomplete sets. Submit anyway?"
Save exercise data to workout log:
Exercise ID
Each set: weight, reps, completed timestamp
Total volume calculation (weight × reps × sets)
Exercise completion timestamp
Calculate progression vs last workout:
Total reps comparison
Total volume comparison
Best set comparison (highest weight × reps product)
Return to Workout Session Overview
Mark exercise as completed on overview
Data persistence:
Auto-save set data as user enters it (don't lose on app close)
Link to workout session ID
Store in local DB and sync to cloud
Screen 3: Exercise Detail - Demo Tab
Visual Layout:

Same header and tab toggle as Logger
Demo tab SELECTED (white fill)
Demo Content:
Video player (border-radius: 15px, ~1/3 viewport height):
Placeholder image/thumbnail
Play button overlay (triangle icon, centered)
Light background
Full-width with side padding
Equipment section:
"Equipment" heading (center-aligned, bold)
Icons in horizontal row (3 icons, evenly spaced):
Equipment image placeholders (square, rounded corners, border)
Active Muscle Groups:
"Active Muscle Groups" heading (center-aligned, bold)
Body diagram icons in horizontal row (3 icons):
Same styling as equipment icons
Instructions box (border-radius: 15px, white background, border):
"Instructions" heading (bold, left-aligned)
Enumerated list (1, 2, 3...):
"Instructions in here"
"More instructions"
"Even more"
Left-aligned list items with padding
"View Exercise History" button (border-radius: 15px, white background, border):
Full-width with side padding
Text centered
Above bottom of scrollable content
Functional Requirements:

Video player:
Placeholder video URL from database
Tap play → Full-screen video playback
Standard iOS video controls (play/pause, scrub, volume, full-screen)
Video should loop
If no video available: Show "Video coming soon" message
Equipment icons:
Display actual equipment needed for this exercise
Images from equipment database
Tap icon → Show equipment info popup (reuse from questionnaire)
Active Muscle Groups:
Display body diagrams with highlighted muscle groups
Show primary and secondary muscles worked
Tap icon → Show muscle group name and description (optional)
Instructions:
Pull from exercise database
Display as numbered list
Clear, concise step-by-step guide
Vertically scrollable if long
"View Exercise History" button:
Navigate to Exercise History page (see spec)
Pass exercise ID to load correct history
Tab toggle functionality:
User can switch back to Logger tab anytime
Demo content loads once and caches
15. WORKOUT HISTORY (Completed Session)
Visual Layout:

Header:
Back arrow (←) left → Return to Home
"[WorkoutType] Workout" centered (e.g., "Upper Body Workout")
Total completion time right (e.g., "01:10")
Summary section (top):
Date of workout (left-aligned): "DD/MM/YY - date"
"Total increased reps: X" (left-aligned below date)
"Total increased load: X" (left-aligned below reps)
Exercise history cards (vertically scrollable):
Each card (border-radius: 15px, white background, border, 15px spacing):
Date "XX/XX/XX - date" (top left)
Rosette/award icon (top right) - IF this exercise had progression
Set list:
"Set 1: 12kg • 12 reps" with "+1" on right (if increased)
"Set 2: X kg • X reps" with "+1" (if increased)
"Set 3: X kg • X reps"
Spacing between set entries
Cards stack vertically with consistent spacing
Functional Requirements:

Display completed workout data from database
Total completion time: Calculate from workout start to last exercise submission
Date: Show date workout was completed
Progression calculations:
Compare to previous workout of same type (e.g., previous Upper Body)
Total increased reps: Sum of all additional reps across all exercises
Total increased load: Sum of all additional volume (weight × reps)
If no previous workout: Show "First time completing this workout!"
Exercise cards:
Display all exercises from that completed workout
Show all completed sets with actual weight and reps
Rosette icon: Only appears on exercises where user increased reps/weight vs previous
"+N" indicators: Show on individual sets that exceeded previous
Navigation:
Tap exercise card → Navigate to Exercise History page for that exercise
Back arrow → Return to Home page
Data source: Pull from workout_logs table linked to user and session
16. EXERCISE HISTORY (Individual Exercise)
Visual Layout:

Header:
Back arrow (←) left → Return to previous screen
Exercise name centered (e.g., "Barbell Bench Press")
Timer display right (e.g., "00:28") - shows last session duration
Summary cards row (two cards, side-by-side, 10px spacing):
Best Set (border-radius: 15px, white background, border):
"Best Set" label (bold, left-aligned)
"X kg • X reps" value (bold below)
Start Weight (same styling):
"Start Weight" label
"X kg" value
Progress graph (full-width, moderate height):
Area chart with filled area under line
Line showing progress trend over time
Data points marked (some with dots at peaks)
Light background
Smooth curves
X-axis: Time/date (most recent on right)
Y-axis: Total volume (weight × reps × sets)
History entries (vertically scrollable):
Multiple cards (border-radius: 15px, white background, border, 15px spacing)
Each card:
Date "XX/XX/XX - date" (top left)
Award ribbon icon (top right) - IF progression occurred
Set breakdown:
"Set 1: 12kg • 12 reps" with "+1" (if increased)
"Set 2: X kg • X reps" with "+1" (if increased)
"Set 3: X kg • X reps"
Functional Requirements:

Display all historical data for this specific exercise
Best Set:
Calculate from all recorded sets ever
Use product formula: weight × reps
Show the single best set (highest product)
Format: "[weight] kg • [reps] reps"
Start Weight:
Show weight used in very first set ever recorded for this exercise
Reference point to show long-term progress
Progress graph:
X-axis: Chronological (dates of workouts)
Y-axis: Total volume per session (sum of all sets: weight × reps × sets)
Plot data points for each completed session
Connect with smooth line
Fill area under line with light color
Tap data point (optional) → Show tooltip with exact values
Show trend line (optional) → Helps visualize overall progress
History entries:
Display in reverse chronological order (most recent at top)
Each card represents one workout session
Show date of session
List all sets performed in that session
Progression indicators:
Award icon: Session had progression vs previous session
"+N": Individual sets that increased vs previous
Tap card (optional) → Expand to show more details
Data calculations:
Pull from exercise_logs table filtered by exercise_id and user_id
Join with workout_sessions for date info
Calculate volume: ∑(weight × reps) for each session
Identify PRs (personal records) and highlight
Empty state:
If no history: Show "No history yet. Complete your first set!"
17. MILESTONES PAGE (Placeholder)
Visual Layout:

Header: "Milestones" - bold, centered
Back arrow (←) → Return to Home
Placeholder content:
Large icon (trophy/medal)
"Coming Soon" text
"Track your achievements and milestones here"
Bottom navigation bar visible
Functional Requirements:

Static page for now
No interactivity beyond navigation
Future features (do not implement yet):
Total workouts completed
Total weight lifted
Longest streak
PRs achieved
Badges earned
18. VIDEO LIBRARY PAGE (Placeholder)
Visual Layout:

Header: "Video Library" - bold, centered
Back arrow (←) → Return to Home
Placeholder content:
Large play icon
"Coming Soon" text
"Access workout tutorials and form guides here"
Bottom navigation bar visible
Functional Requirements:

Static page for now
No interactivity beyond navigation
Future features (do not implement yet):
Categorized workout videos
Form tutorial videos
Programme overview videos
ADDITIONAL COMPONENTS & UTILITIES
Reusable Vertical Sliding Ruler Component
Specifications:

Library: Use native Swift UIPickerView or custom implementation
Orientation: Vertical
Visual elements:
Major ticks every 10 units (bold numbers, larger font)
Minor ticks every 1 unit (smaller, lighter)
Selected value centered, larger font, bold
Horizontal indicator line at selected value
Smooth scrolling with momentum
Rounded container (border-radius: 25px)
Light background, bordered
Takes ~60% screen width, significant height
Functional Requirements:

Smooth, native iOS scrolling behavior
Snap to integer values
Dynamic range (configurable min/max)
Value change callback for parent component
Initial value settable programmatically
Usage:

Height selection (cm mode): 140-220 cm, default 180
Height selection (ft/in mode): 4'7"-7'2", default 5'10"
Reusable Horizontal Sliding Ruler Component
Specifications:

Same as vertical but oriented horizontally
Major ticks every 5 units
Selected value displayed ABOVE ruler (large, bold)
Vertical indicator line at selected value
Full-width with side padding
Functional Requirements:

Same scrolling behavior as vertical
Snap to integer values
Value change callback
Usage:

Weight selection: 40-200 kg (or 88-440 lbs), default 80 kg
Rest Timer Component
Specifications:

Rounded rectangle (border-radius: 10px)
Light background fill
Time display: "MM:SS" format, centered
Width: ~50% of parent container
Moderate height
Functional Requirements:

Countdown timer from set duration (default 2:00)
Visual countdown animation
Audio/haptic notification on completion (optional)
Skippable (X button or tap outside)
Automatically dismisses when time reaches 0:00
Callback to parent when dismissed
Usage:

Exercise Logger: Appears after set completion, helps enforce rest periods
Equipment Info Popup Modal
Specifications:

Modal overlay: Semi-transparent dark background
Card: Rounded rectangle (border-radius: 20px), centered, white background, border
Top 40%: Image area (high-res equipment photo)
Bottom 60%: Content area
Equipment name (heading, bold, centered)
Description text (scrollable if needed)
Close button: X icon (top-right corner of card)
Slide-up animation on open
Functional Requirements:

Triggered by info icon tap on equipment selection screen
Display equipment name and description from database
Image loaded from URL or asset
Tap X or outside modal → Dismiss with slide-down animation
Return to parent screen state preserved
DATA MODEL & BACKEND REQUIREMENTS
User Profile Data Structure
json
{
  "user_id": "unique_id",
  "full_name": "string",
  "email": "string",
  "password_hash": "string",
  "created_at": "timestamp",
  "subscription_status": "active|trial|expired",
  "subscription_plan": "monthly|annual",
  "subscription_end_date": "timestamp",
  
  "profile": {
    "age": "integer",
    "gender": "male|female|other",
    "height": {"value": "float", "unit": "cm|ft"},
    "weight": {"value": "float", "unit": "kg|lbs"}
  },
  
  "questionnaire_data": {
    "primary_goals": ["get_stronger|build_muscle|tone_up"],
    "experience_level": "0|0-6|6-24|24+",
    "priority_muscles": ["array of muscle groups"],
    "available_equipment": ["array of equipment"],
    "injuries": ["array of body parts"],
    "training_frequency": "2|3|4|5",
    "session_duration": "30-45|45-60|60-90",
    "motivations": ["array of reasons"]
  },
  
  "programme": {
    "split_type": "full_body|upper_lower|ppl",
    "workouts": [
      {
        "workout_id": "unique_id",
        "workout_name": "Push|Pull|Legs|Upper|Lower|Full Body",
        "exercises": [
          {
            "exercise_id": "unique_id",
            "exercise_name": "string",
            "sets": "integer",
            "rep_range": "string (e.g., '8-12')",
            "order": "integer"
          }
        ]
      }
    ]
  },
  
  "streak": {
    "current_streak": "integer",
    "last_workout_date": "date"
  }
}
Exercise Database Structure
json
{
  "exercise_id": "unique_id",
  "exercise_name": "string",
  "video_url": "string (URL)",
  "thumbnail_url": "string (URL)",
  "primary_muscles": ["array of muscle groups"],
  "secondary_muscles": ["array of muscle groups"],
  "equipment_needed": ["array of equipment"],
  "instructions": ["array of strings"],
  "difficulty": "beginner|intermediate|advanced"
}
Workout Session Log Structure
json
{
  "session_id": "unique_id",
  "user_id": "string",
  "workout_id": "string",
  "workout_name": "string",
  "date": "timestamp",
  "start_time": "timestamp",
  "end_time": "timestamp",
  "total_duration": "integer (seconds)",
  "completed": "boolean",
  
  "exercises": [
    {
      "exercise_id": "string",
      "exercise_name": "string",
      "sets": [
        {
          "set_number": "integer",
          "weight": "float",
          "weight_unit": "kg|lbs",
          "reps": "integer",
          "completed": "boolean",
          "timestamp": "timestamp"
        }
      ],
      "notes": "string (optional)",
      "total_volume": "float (calculated: sum of weight × reps)",
      "progression_vs_last": {
        "reps_increased": "integer",
        "volume_increased": "float"
      }
    }
  ]
}
```

### Backend API Endpoints Needed

**Authentication:**
- POST `/api/auth/register` - Create new user account
- POST `/api/auth/login` - Authenticate user
- POST `/api/auth/logout` - End session
- POST `/api/auth/reset-password` - Initiate password reset
- POST `/api/auth/verify-reset-code` - Verify reset code
- POST `/api/auth/update-password` - Set new password

**User Profile:**
- GET `/api/user/profile` - Get user data
- PUT `/api/user/profile` - Update user data
- DELETE `/api/user/account` - Delete user account

**Programme Generation:**
- POST `/api/programme/generate` - Generate workout programme based on questionnaire
- GET `/api/programme/{user_id}` - Get user's current programme

**Exercises:**
- GET `/api/exercises` - Get all exercises (with filters)
- GET `/api/exercises/{exercise_id}` - Get specific exercise details
- GET `/api/exercises/history/{exercise_id}` - Get history for specific exercise

**Workout Logging:**
- POST `/api/workouts/start` - Start new workout session
- PUT `/api/workouts/{session_id}/exercise` - Save exercise set data
- POST `/api/workouts/{session_id}/complete` - Complete workout session
- GET `/api/workouts/history` - Get user's workout history
- GET `/api/workouts/{session_id}` - Get specific workout details

**Subscription:**
- GET `/api/subscription/status` - Get subscription status
- POST `/api/subscription/subscribe` - Process subscription (integrate with Apple)
- POST `/api/subscription/cancel` - Cancel subscription

---

## PROGRESSION LOGIC & ALGORITHMS

### Programme Generation Algorithm

Based on user questionnaire data:

**Split Selection:**
```
IF training_frequency == 2 OR training_frequency == 3:
  split = "Full Body"
  workouts = ["Full Body A", "Full Body B", "Full Body C"]
  
ELSE IF training_frequency == 4:
  split = "Upper/Lower"
  workouts = ["Upper Body", "Lower Body", "Upper Body", "Lower Body"]
  
ELSE IF training_frequency == 5:
  split = "Push/Pull/Legs"
  workouts = ["Push", "Pull", "Legs", "Push", "Pull"]
```

**Exercise Selection:**
1. Filter exercise database by:
   - Available equipment (user must have all required equipment)
   - Exclude exercises targeting injured body parts
   
2. Prioritize exercises that target user's priority muscle groups
   
3. Balance exercise variety:
   - Include compound movements (e.g., squats, deadlifts, bench press)
   - Include isolation movements for priority muscles
   - Vary movement patterns (push, pull, squat, hinge)

4. Set volume based on experience level:
   - Beginner (0 months): 3 sets per exercise
   - Novice (0-6 months): 3-4 sets per exercise
   - Intermediate (6-24 months): 4-5 sets per exercise
   - Advanced (24+ months): 4-6 sets per exercise

5. Rep ranges based on goals:
   - Get stronger: 4-6 reps (strength focus)
   - Build muscle: 8-12 reps (hypertrophy focus)
   - Tone up: 12-15 reps (endurance/definition focus)

**Example Output** (5-day PPL split, build muscle goal):
- Push: Bench Press (4×8-12), Shoulder Press (3×8-12), Tricep Pushdown (3×10-15), Lateral Raise (3×12-15)
- Pull: Deadlift (4×6-10), Pull-ups (3×8-12), Barbell Row (3×8-12), Bicep Curl (3×10-15)
- Legs: Squat (4×8-12), Leg Press (3×10-15), Leg Curl (3×10-15), Calf Raise (4×12-20)

### Progressive Overload Tracking

**On each workout session:**
1. Retrieve user's last session of same workout type
2. For each exercise, compare current sets to previous:
   - Count total reps: ∑(reps across all sets)
   - Calculate total volume: ∑(weight × reps across all sets)
   
3. Determine if progression occurred:
```
   IF current_total_reps > previous_total_reps:
     progression_type = "reps"
     progression_amount = current_total_reps - previous_total_reps
     
   ELSE IF current_total_volume > previous_total_volume:
     progression_type = "weight"
     progression_amount = current_total_volume - previous_total_volume
```

4. Mark exercises with progression (show rosette icon)
5. Update live rep counter during workout (+1, +2, etc.)

**Suggested weight increases** (future feature):
- If user completed all sets at top of rep range → Suggest +2.5kg increase
- Track percentage increases over time
- Show recommendations in logger

### Streak Calculation

**Daily streak logic:**
```
On each workout completion:
  last_workout = user.last_workout_date
  today = current_date
  
  IF last_workout == today:
    // Already worked out today, no change to streak
    RETURN
    
  ELSE IF last_workout == yesterday:
    // Consecutive day, increase streak
    user.streak += 1
    
  ELSE:
    // Gap in workouts, reset streak
    user.streak = 1
  
  user.last_workout_date = today
  UPDATE database
Display streak counter in flame icon badge on home page.

VALIDATION & ERROR HANDLING
Input Validation Rules
Email:

Must contain @ symbol
Must have domain (e.g., .com, .co.uk, .net)
Standard regex: /^[^\s@]+@[^\s@]+\.[^\s@]+$/
Error message: "Please enter a valid email address"
Password:

Minimum 8 characters
Recommended: At least 1 uppercase, 1 lowercase, 1 number (not enforced in MVP)
Error message: "Password must be at least 8 characters"
Confirm password must match
Age:

Range: 16-100
Integer only
Error message: "Please enter a valid age"
Weight/Height:

Positive numbers only
Reasonable ranges (see component specs)
Error message: "Please enter a valid [height/weight]"
Set Logging:

Weight: Positive number, max 500 kg (1100 lbs)
Reps: Positive integer, max 100
Error message: "Please enter valid weight and reps"
Error States & Messages
Network Errors:

Connection failed → "Unable to connect. Please check your internet connection."
Timeout → "Request timed out. Please try again."
Server error (5xx) → "Something went wrong. Please try again later."
Authentication Errors:

Invalid credentials → "Invalid email or password"
Email already exists → "An account with this email already exists"
Password reset code expired → "This code has expired. Please request a new one."
Invalid reset code → "Invalid code. Please try again."
Subscription Errors:

Payment failed → "Payment failed. Please update your payment method."
Subscription inactive → "Your subscription has expired. Please renew to continue."
Data Errors:

Failed to save workout → "Unable to save workout. Your data has been saved locally and will sync when connection is restored."
Failed to load programme → "Unable to load your programme. Please try again."
Loading States
Full-screen loaders:

Splash screen (on initial load)
Building Programme (after questionnaire)
Creating Account (after sign-up)
Inline loaders:

Submitting forms (spinner on button)
Loading exercise history (skeleton screens)
Loading workout data (skeleton cards)
Skeleton Screens: Use for loading lists/content:

Show layout with pulsing grey rectangles
Maintain spacing and card structure
Replace with real content when loaded
PERFORMANCE REQUIREMENTS
App Launch:

Cold start: < 3 seconds to splash/login screen
Warm start: < 1 second
Navigation:

Screen transitions: < 300ms
No janky animations (maintain 60 FPS)
Data Loading:

Exercise library: Load in background, show within 1 second
Workout history: Load within 2 seconds or show skeleton
Offline Functionality:

Allow workout logging offline
Queue data to sync when connection restored
Show offline indicator in UI
Database:

Local SQLite database for offline access
Sync with cloud backend periodically
Conflict resolution: Server wins (but warn user if conflict)
ACCESSIBILITY REQUIREMENTS
VoiceOver Support:

All buttons have descriptive labels
Input fields have labels and hints
Images have alt text descriptions
Dynamic Type:

Support iOS Dynamic Type
Text scales with user preferences
Color Contrast:

Maintain WCAG AA contrast ratios (4.5:1 for normal text)
Don't rely solely on color for information
Touch Targets:

Minimum 44×44 pt tap targets
Adequate spacing between interactive elements
TESTING CHECKLIST
Before considering implementation complete, verify:

Authentication Flow:
 New user can complete full sign-up flow
 Returning user sees login screen (not splash)
 Password reset flow works end-to-end
 Invalid credentials show error
 Session persists between app launches
Questionnaire:
 All 8 questions navigate correctly
 Progress bar updates accurately
 Back navigation works on all screens
 Equipment popup opens and closes
 All selections save correctly
Programme Generation:
 Programme generates based on frequency (2/3/4/5 days)
 Exercises filtered by equipment
 Injured muscle groups excluded
 Priority muscles emphasized
Home Page:
 User name displays correctly
 Weekly sessions show correct split
 Completed workouts marked with checkmarks
 Programme dropdown expands/collapses
 Bottom navigation works to all pages
Workout Logging:
 Timer starts when workout opened
 Exercise detail loads correctly
 Logger/Demo tabs switch
 Set completion marks checkmark
 Rest timer appears and counts down
 Live rep counter updates correctly
 Submit exercise saves data and returns to overview
Exercise History:
 History loads for specific exercise
 Graph displays volume over time
 Best set calculated correctly
 Progression indicators (rosettes, +N) show appropriately
Data Persistence:
 All user inputs save to database
 Workout logs persist
 App state survives app close/reopen
 Offline workout logging queues for sync
IMPLEMENTATION NOTES FOR CLAUDE CODE
Audit First:

Scan existing codebase for implemented screens
Create checklist of existing vs missing screens
Identify incomplete implementations
Update Existing:

Compare existing screens to specs above
Add missing UI elements
Implement missing functionality
Fix styling inconsistencies
Test navigation flows
Build Missing:

Create new screens from scratch
Implement all specified functionality
Connect navigation
Add to routing/navigation system
Navigation Structure:

Use UINavigationController for primary stack
Modal presentations for popups/overlays
Tab bar for bottom navigation on home page
Ensure back navigation works throughout
State Management:

Use UserDefaults for simple preferences
Core Data or SQLite for workout logs and user data
Consider using Combine or SwiftUI @State for reactive updates
Styling Consistency:

Create reusable UI components (buttons, cards, inputs)
Define color palette as constants
Use spacing constants (8pt grid system)
Apply border radius consistently across app
Code Quality:

Modularize reusable components
Separate concerns (UI, business logic, data)
Comment complex algorithms
Use meaningful variable names
Testing as You Go:

Test each screen after implementation
Verify navigation flows
Test with sample data
Check edge cases (empty states, errors)
FINAL DELIVERABLES
When implementation is complete, the app should:

✅ Have all 18+ screens fully functional
✅ Navigate seamlessly between all screens
✅ Store user data persistently
✅ Log workouts and track progression
✅ Display history and analytics accurately
✅ Match visual specifications exactly
✅ Handle errors gracefully
✅ Perform well (smooth, no lag)
✅ Work offline (with sync when online)
✅ Be ready for App Store submission (pending Apple subscription integration)
This specification is comprehensive and detailed. Follow it systematically, and you'll build a complete, polished fitness app. Good luck! 🚀

you can ignore anything regarding API routes and data models for now - this is just a MVP and I want to prove all the pages work. Also for the rulers, continute to use the sliding ruler library.