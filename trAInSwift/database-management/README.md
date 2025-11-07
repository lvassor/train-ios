# Exercise Database Management

This folder contains the source data and tools for managing the exercise database used in the trAInSwift app.

## Files

- `exercises_new_schema.csv` - Main exercise data
- `exercise_contraindications.csv` - Exercise injury contraindications
- `user_experience_complexity.csv` - Experience level complexity rules
- `create_database.py` - Python script to generate SQLite database
- `exercises.db` - Generated SQLite database (copied to app Resources)

## Database Schema

### exercises table
- `exercise_id` (INTEGER PRIMARY KEY)
- `canonical_name` (TEXT) - Base exercise name
- `display_name` (TEXT) - Name shown to users
- `movement_pattern` (TEXT) - e.g., Squat, Hinge, Horizontal Push
- `equipment_type` (TEXT) - Barbell, Dumbbell, Cable, Machine, Kettlebell, Bodyweight
- `complexity_level` (INTEGER 1-4) - Exercise difficulty
- `primary_muscle` (TEXT) - Main muscle targeted
- `secondary_muscle` (TEXT) - Secondary muscle targeted
- `instructions` (TEXT) - Exercise instructions (optional)
- `is_active` (INTEGER) - 1 if active, 0 if disabled

### exercise_contraindications table
- `id` (INTEGER PRIMARY KEY AUTOINCREMENT)
- `exercise_id` (INTEGER) - Foreign key to exercises
- `injury_type` (TEXT) - Injury that contraindicates this exercise

### user_experience_complexity table
- `experience_level` (TEXT PRIMARY KEY) - BEGINNER, INTERMEDIATE, ADVANCED
- `display_name` (TEXT) - Display name
- `max_complexity` (INTEGER) - Maximum complexity level allowed
- `max_complexity_4_per_session` (INTEGER) - Max level-4 exercises per session
- `complexity_4_must_be_first` (INTEGER) - Whether level-4 must be first

## How to Update Exercise Data

### Prerequisites
```bash
pip install pandas
```

### Steps

1. **Edit CSV files** with your changes:
   - Add/modify exercises in `exercises_new_schema.csv`
   - Add/modify contraindications in `exercise_contraindications.csv`
   - Modify experience rules in `user_experience_complexity.csv`

2. **Run the database creation script:**
   ```bash
   cd database-management
   python3 create_database.py
   ```

   The script will automatically:
   - Generate `exercises.db` in `database-management/`
   - Copy it to `../trAInSwift/Resources/exercises.db`
   - Display verification stats

3. **Rebuild app** in Xcode (⌘B)

4. **Test changes** - Delete app from simulator and reinstall to get fresh database

## CSV Format Guidelines

### exercises_new_schema.csv
- `exercise_id`: Use format EX001, EX002, etc. (converted to integer in database)
- `complexity_level`: Must be 1, 2, 3, or 4
- `is_active`: True or False (converted to 1/0 in database)

### exercise_contraindications.csv
- `exercise_id`: Must match an exercise_id from exercises_new_schema.csv
- `injury_type`: Use consistent naming (e.g., "Knee", "Lower Back", "Shoulder", "Hip")

### user_experience_complexity.csv
- `experience_level`: BEGINNER, INTERMEDIATE, or ADVANCED
- `complexity_4_must_be_first`: True or False (converted to 1/0 in database)

## Current Database Stats

- **Total exercises**: 100
- **Complexity distribution**:
  - Level 1: 26 exercises
  - Level 2: 42 exercises
  - Level 3: 23 exercises
  - Level 4: 9 exercises
- **Total contraindications**: 144
- **Experience levels**: 3

## Notes

- The Python script automatically converts EX### IDs to integers
- Boolean values (True/False) are converted to integers (1/0) for SQLite
- Indexes are automatically created for fast querying
- The script validates data integrity before generating the database
