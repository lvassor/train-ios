# Train App Documentation
## App Mission

- Train is a strength training app that has one mission: become the best training app on the market.
- It is created by two personal trainers (PTs) from the UK: Luke Vassor and Brody Bastiman
- The value proposition of the app is that it helps anyone to become experienced in weight lifting without the exorbitant costs of a personal trainer and targets the complete to novice to intermediate group
- The app is not targeting bodybuilders or powerlifters (although it can generate programmes within this space if needed). Instead the app seeks to serve the general population.
- The USP of the app is gamification: encouraging users through active feedback mechanisms (counters, prompts, milestones, notifications (See [App Rules](app_rules.md))) to progressively overload their exercises, as we would encourage them to do so in a 1-on-1 PT setting.

## Core Features - Overall View
1. **2-part questionnaire:** 1. user availability for training (days per week and session duration), equipment availability, proficiency, goals, priority muscles, injuries 2. personal stats (age, weight, height, gender)
2. **Programme generation:** Based on the user's answers to the up-front questionnaire, the app uses a proprietary algorithm to generate a bespoke programme suited to the user which is structured around a training "split" i.e. a rotation of different days within a programme e.g. a 3-day programme could be Push/Pull/Legs involving Push movements, Pull movements and Leg movements, respectively.
3. **Dashboard:** a central dashboard that shows the user's programme and allows the user to toggle between days in their training split. From here the user can browse previously logged workouts or commence a new workout (4.). The dashboard also has a tool bar allowing the user to navigate to one of 4 areas: back to the dashboard (3.), browse a milestones section (6.), browse an exercise library (7.) or view their account settings (8.).
4. **New Workout:** In the dashboard a user can start a new workout. This opens a view of their overall workout for that particular day of their split, listing the exercises for the day. Workouts user a hub view rather than a wizard view, so that users aren't constrained to the specific order of the programme if equipment in their gym/training environment is not available in the order of the programme. However, the algorithm still orders the programme in a specific way. See [App Rules](app_rules.md). Clicking a specific exercise opens the workout logger (5.).
5. **Workout Logger:** The workout logger provides an environment for the user to log the details of the exercise, including sets/reps/load. Users can complete sets, open timers at the end of each set. The logger contains a toolbar to switch view to a "Demo" tab which allows the user to view a demonstration of the exercise, including a video (streamed from bunny.net) and other information around the exercise like target muscle group and instructions. Currently, these demonstration videos were purchased from a digital design supplier and depict an anatomically accurate model performing the exercise, however the longer term plan is for Luke and Brody to record and edit HQ videos of themselves in the gym.
6. **Milestones section:** currently a placeholder, the goal is to allow the user to view their milestones, such as personal best weights (absolute and relative to body weight), reps and streaks.
7. **Exercise Library:** this displays, and allows the user to navigate, all exercises in the app's exercise database (9.). Features of the database allow the user to filter by muscle groups and equipment. When clicking an exercise in the library, the user is presented with the same demonstration information that they would get in the `Demo` tab of the `Workout Logger`.
8. **Account Settings:** Displayed as a floating icon detached from the toolbar on the dashboard view (3.), this allows the user to view information about their account, including their username, the programme they currently have and high level information about the programme, their price plan (currently the app is MVP in TestFlight so there are no active payments). From here the user can also retake the initial questionnaire to generate a new programme. However there is no mechanism for storing multiple programmes against a user's account. Currently following this flow will simply replace the user's programme.
9. **Exercise Database:** The exercises available for programme generation are stored in a database (see [Exercise Database](exercise_database.md)). At source, this is a xlsx file stored on Google Sheets that allows the founders to add/edit exercises. It contains lookup sheets for data validation and columns for information about the exericses, such as muscle groups, equipment required, display names and canonical names. For example, an exercise with display name "Barbell Incline Bench Press" has a canonical name of "Bench Press". This allows the programme generation algorithm to filter and group exercises efficiently.

---

## Glossary

**Set**: A group of repetitions (e.g., "3 sets of 10 reps" means do 10 reps, rest, do 10 reps, rest, do 10 reps)

**Rep (Repetition)**: One complete movement of an exercise

**Rep Range**: The target number of reps (e.g., "8-12" means aim for 8-12 reps per set)

**Complexity Level**: How technically difficult an exercise is (1 = easy, 4 = very hard)

**Split**: How you divide muscle groups across different training days

**Full Body**: Training all major muscle groups in one session

**Upper/Lower**: One day for upper body muscles, one day for lower body muscles

**Push/Pull/Legs (PPL)**: Push muscles (chest, shoulders, triceps), Pull muscles (back, biceps), Legs (quads, hamstrings, glutes)

**Canonical Name**: The underlying movement pattern of an exercise (e.g., "Bench Press" is the canonical name for Flat Bench Press, Incline Bench Press, etc.)

**Compound Exercise**: An exercise that works multiple muscle groups (e.g., squat, bench press)

**Isolation Exercise**: An exercise that targets a single muscle group (e.g., bicep curl, leg extension)

**Weighted Random Selection**: A selection method where items with higher scores have proportionally higher chances of being picked

**Progression**: When you're ready to increase weight

**Regression**: When you need to decrease weight

**Consistency**: When you should maintain current weight

**Debounce**: A small delay to prevent flickering/rapid changes (like waiting 500ms before showing a prompt)