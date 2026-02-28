<p align="center">
  <img src="assets/train-logo-with-text_isolate_cropped.svg" alt="trAIn" width="280">
</p>

<p align="center">
  <em>Native iOS app for the trAIn fitness platform — AI-powered personalised workout programming</em>
</p>

<p align="center">
  <strong>Created by</strong>: Luke Vassor & Brody Bastiman
</p>

---

## Overview

SwiftUI-based iOS app that generates personalised multi-week workout programmes based on a 60-second questionnaire. Features real-time workout logging with progression feedback, exercise video demos via Bunny Stream CDN, milestone tracking, and personal best detection.

## Features

- **60-Second Questionnaire** — progressive onboarding: experience, goals, equipment, split, duration
- **AI Programme Generation** — scored exercise selection from 230-exercise SQLite database
- **Workout Logger** — track sets, reps, weight with rest timers and haptic feedback
- **Traffic Light Prompts** — regression / consistency / progression feedback per exercise
- **Exercise Demos** — Bunny Stream CDN video playback with thumbnail previews
- **Personal Bests** — automatic PB detection with celebration overlay and share cards
- **Milestones** — 20+ achievements across progression, output, and streak categories
- **Exercise Library** — full searchable database with muscle group filtering
- **Live Activity Widget** — lock screen workout tracking
- **Dark Mode** — full dark theme with glass morphism UI

## Tech Stack

- **SwiftUI** — declarative UI framework
- **Core Data** — local persistence (UserProfile, WorkoutProgram, CDWorkoutSession)
- **GRDB / SQLite** — embedded exercise database (230 exercises, equipment, contraindications, videos)
- **StoreKit 2** — subscription paywall
- **Lottie** — animated illustrations (streak flame, onboarding)
- **Bunny Stream CDN** — exercise video hosting and thumbnails
- **Google Sign-In** — OAuth authentication
- **Sign in with Apple** — native Apple authentication
- **Spotlight** — exercise indexing and Siri shortcuts

## Project Structure

```
train-ios/
├── TrainSwift/
│   ├── Views/              # 44 SwiftUI views
│   ├── Components/         # 27 reusable UI components
│   ├── Services/           # 21 services (auth, program gen, media, milestones)
│   ├── Models/             # Data models (Program, WorkoutSession, QuestionnaireData)
│   ├── Persistence/        # Core Data extensions (UserProfile, WorkoutProgram, CDWorkoutSession)
│   ├── Resources/          # exercises.db, Lottie JSON, equipment images, constants
│   └── Assets.xcassets/    # App icon, colours, images
├── database-management/    # Python scripts + CSV sources for exercises.db
├── app-management/         # Specs, checklists, change logs
├── WorkoutWidgetFiles/     # Live Activity widget
└── TrainSwiftTests/        # Unit tests
```

## Getting Started

### Prerequisites
- Xcode 16+
- iOS 17+ deployment target
- Dependencies resolved via Swift Package Manager

### Build & Run
```bash
git clone https://github.com/lvassor/train-ios.git
cd train-ios
open TrainSwift.xcodeproj
# Build and run on simulator (Cmd+R)
```

### Regenerate Exercise Database
```bash
cd database-management
python3 create_database_prod.py
# Output: TrainSwift/Resources/exercises.db
```

---

## TestFlight Test Accounts

Pre-populated test accounts with 3 weeks of workout data for testing milestones, PBs, progression prompts, and history.

### Credentials

| Account | Email | Password | Split | Days |
|---------|-------|----------|-------|------|
| PPL | test-ppl@train.com | Train123! | Push/Pull/Legs | 3/week |
| UL | test-ul@train.com | Train123! | Upper/Lower | 4/week |

### Enabling Test Data for TestFlight

1. Open `TrainSwift.xcodeproj` in Xcode
2. Select the **TrainSwift** target in the sidebar
3. Go to the **Build Settings** tab
4. Search for `Active Compilation Conditions`
5. Expand the disclosure triangle to see **Debug** and **Release** rows
6. Double-click the **Release** row
7. Click **+** and type `SEED_TEST_DATA`
8. Press Enter to confirm
9. **Product → Archive** to build for TestFlight
10. Upload to App Store Connect and distribute via TestFlight

On first launch, the app seeds both test accounts automatically and lands on the login screen.

### Disabling for Production

1. Go to **Build Settings → Active Compilation Conditions → Release**
2. Select `SEED_TEST_DATA` and press **Delete**
3. Archive and upload — the seeder code compiles to nothing

### Re-seeding (same device)

Delete the app from the device/simulator and reinstall. Seeding runs fresh on next launch.

---

## Related Projects

- **[trAIn Web](https://github.com/lvassor/trAIn-web)** — Web application (Express.js / PostgreSQL)

## License

Private and proprietary.

---

Made with ❤️ by Luke Vassor & Brody Bastiman
