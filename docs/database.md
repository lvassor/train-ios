<p align="center">
  <img src="../assets/train-logo-with-text_isolate_cropped_dark.svg" alt="train" width="280">
</p>

<p align="center">
  <em>Exercise database — source files, generation pipeline, and data model</em>
</p>

<p align="center">
  <strong>Created by</strong>: Brody Bastiman & Luke Vassor
</p>

---

# Exercise Database

## Overview

The exercise database is the foundation of train's programme generation system. It is a normalised SQLite database (`exercises.db`, 236 KB) generated from CSV source files via a Python pipeline. The database contains 229 exercises, 60 equipment items, 39 injury contraindications, and 229 video mappings.

---

## Data Model

<p align="center">
  <img src="flows/database_schema.png" alt="Database schema — entity relationship diagram showing the 4 tables (equipment, exercises, exercise_videos, exercise_contraindications) and their foreign key relationships" width="100%">
</p>

<p align="center">
  <em>Figure 1: Entity relationship diagram for exercises.db — 4 tables with foreign key relationships. Exercises reference equipment via equipment_id_1 (required) and equipment_id_2 (optional). Videos map 1:1 to exercises. Contraindications join on canonical_name.</em>
</p>

---

## Source Files

All source files live in the `database-management/` directory.

| File | Size | Rows | Purpose |
|------|------|------|---------|
| `equipment_prod.csv` | 4.9 KB | 60 | Equipment lookup table (categories, names, image filenames) |
| `exercise_database_prod.csv` | 17.8 KB | 229 | Main exercise catalog (equipment links, muscles, complexity, ratings) |
| `exercise_instructions_prod.csv` | 76.9 KB | 919 | Step-by-step instructions for each exercise |
| `exercise_contraindications_prod.csv` | 782 B | 39 | Injury-to-exercise safety mappings |
| `exercise_video_mapping_prod.csv` | 28.7 KB | 229 | Bunny Stream CDN video GUIDs |
| `split_templates_prod.csv` | 6.9 KB | 118 | Programme split templates (not imported into exercises.db) |
| `create_database_prod.py` | 16 KB | 439 lines | Python pipeline script |
| `clear_accounts.sh` | 1.0 KB | 32 lines | Simulator data cleanup utility |

---

## Database Schema

### equipment

Primary lookup table for all gym equipment.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `equipment_id` | TEXT | PRIMARY KEY | Unique ID (e.g., "EP001") |
| `category` | TEXT | NOT NULL | High-level category (e.g., "Barbells", "Cables") |
| `name` | TEXT | NOT NULL | Display name (e.g., "Squat Rack") |
| `image_filename` | TEXT | | Asset reference for equipment images |

### exercises

Main exercise table — 229 entries with equipment foreign keys.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `exercise_id` | TEXT | PRIMARY KEY | Unique ID (e.g., "EX001") |
| `canonical_name` | TEXT | NOT NULL | Movement pattern grouping (e.g., "Bench Press") |
| `display_name` | TEXT | NOT NULL | User-facing name (e.g., "Barbell Flat Bench Press") |
| `equipment_id_1` | TEXT | FK NOT NULL | Primary equipment (required, references equipment) |
| `equipment_id_2` | TEXT | FK nullable | Secondary equipment (optional, e.g., bench + barbell) |
| `complexity_level` | TEXT | CHECK('All','1','2') | Exercise difficulty tier |
| `canonical_rating` | INTEGER | 0-100 | MCV ordering score (compounds high, isolations low) |
| `primary_muscle` | TEXT | NOT NULL | Main muscle targeted |
| `secondary_muscle` | TEXT | nullable | Secondary muscle |
| `instructions` | TEXT | nullable | Step-by-step instructions (joined from instructions CSV) |
| `is_in_programme` | INTEGER | 0/1 | Include in programme generation |
| `progression_id` | TEXT | nullable | FK to harder exercise variant |
| `regression_id` | TEXT | nullable | FK to easier exercise variant |

### exercise_contraindications

Injury safety table — maps exercises to contraindicated conditions.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | INTEGER | PK AUTOINCREMENT | Row ID |
| `canonical_name` | TEXT | NOT NULL | Links to exercises.canonical_name |
| `injury_type` | TEXT | NOT NULL | Injury type (e.g., "Back", "Shoulders") |

UNIQUE constraint on `(canonical_name, injury_type)`.

### exercise_videos

Bunny Stream CDN video mappings — 1:1 with exercises.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | INTEGER | PK AUTOINCREMENT | Row ID |
| `exercise_id` | TEXT | FK UNIQUE NOT NULL | Links to exercises.exercise_id |
| `supplier_id` | TEXT | nullable | Video supplier vendor ID |
| `filename` | TEXT | NOT NULL | Original filename |
| `bunny_guid` | TEXT | NOT NULL | Bunny Stream CDN GUID for playback |

---

## Generation Pipeline

```
CSV SOURCE FILES                    PYTHON PROCESSOR                   OUTPUT
────────────────                    ────────────────                   ──────

equipment_prod.csv            ┐
exercise_database_prod.csv    │     create_database_prod.py
exercise_instructions_prod.csv├────────────────────────────────► exercises.db (236 KB)
exercise_contraindications    │     1. Read & validate CSVs           → TrainSwift/Resources/
  _prod.csv                   │     2. Check FK integrity
exercise_video_mapping        │     3. Normalise complexity levels
  _prod.csv                   ┘     4. Create tables & indexes
                                    5. Insert data
                                    6. Verify & report

split_templates_prod.csv ──────────► (NOT imported into exercises.db)
                                     Used directly by programme generation
```

### Running the Generator

```bash
cd database-management
python3 create_database_prod.py
```

The script outputs `exercises.db` directly to `TrainSwift/Resources/`. No manual file copying needed.

### Validation Steps

The pipeline performs the following checks during generation:

1. All required CSV files exist
2. No duplicate `equipment_id` values in equipment table
3. No duplicate `(category, name)` pairs in equipment
4. All `equipment_id_1` values in exercises exist in equipment table
5. All `equipment_id_2` values (when not NULL) exist in equipment table
6. `complexity_level` normalised to valid values ('All', '1', '2')
7. `canonical_rating` within 0-100 range
8. Video rows with empty `filename` or `bunny_guid` are skipped
9. Final foreign key integrity check on loaded database

### Verification Report

After generation, the script prints a summary:

- Equipment entries count (60)
- Total exercises count (229)
- Exercises in programme count (~220)
- Contraindications count (39)
- Video mappings count (229)
- Equipment breakdown by category
- Complexity distribution (All/1/2)
- Exercises with secondary equipment
- FK integrity validation results

---

## Indexes

```sql
-- Equipment
idx_equipment_category ON equipment(category)

-- Exercises
idx_exercises_canonical ON exercises(canonical_name)
idx_exercises_equip1 ON exercises(equipment_id_1)
idx_exercises_equip2 ON exercises(equipment_id_2)
idx_exercises_complexity ON exercises(complexity_level)
idx_exercises_muscle ON exercises(primary_muscle)
idx_exercises_programme ON exercises(is_in_programme)
idx_exercises_rating ON exercises(canonical_rating)

-- Contraindications
idx_contraindications_canonical ON exercise_contraindications(canonical_name)
idx_contraindications_injury ON exercise_contraindications(injury_type)

-- Videos
idx_videos_exercise_id ON exercise_videos(exercise_id)
idx_videos_bunny_guid ON exercise_videos(bunny_guid)
```

---

## Key Relationships

- **exercises → equipment**: Foreign keys on `equipment_id_1` (required) and `equipment_id_2` (optional). An exercise needs at least one piece of equipment; some need two (e.g., barbell + bench).
- **exercises → exercises**: Self-references via `progression_id` and `regression_id` for exercise difficulty chains (e.g., Bodyweight Back Extension → Dumbbell Back Extension).
- **exercise_contraindications → exercises**: Joined on `canonical_name` for injury filtering during questionnaire and workout overview warnings.
- **exercise_videos → exercises**: 1:1 mapping via `exercise_id` for Bunny Stream CDN video playback and thumbnail loading.

---

## Utility Scripts

### clear_accounts.sh

Test utility for clearing simulator data during development:

```bash
./clear_accounts.sh
```

Clears all rows from `ZUSERPROFILE`, `ZWORKOUTPROGRAM`, `ZCDWORKOUTSESSION`, and `ZQUESTIONNAIRERESPONSE` tables in the iOS Simulator's Core Data SQLite store.

---

## Flowchart Diagrams

Additional reference diagrams are available in `docs/flows/`:

| Diagram | File | Description |
|---------|------|-------------|
| Database Schema | `database_schema.pdf` / `.png` | Entity relationship diagram (Figure 1 above) |
| Database Generation | `database_generation_flowchart.pdf` | CSV → Python → SQLite pipeline flow |
| Equipment Filter | `equipment_filter_flowchart.pdf` | Equipment filtering decision tree |
| Programme Generation | `program_generation_flowchart.pdf` | MCV algorithm and session creation flow |
| Dashboard Navigation | `dashboard_navigation_map.pdf` | App navigation paths and screen transitions |
| Questionnaire Flow | `questionnaire_flowchart.pdf` | Onboarding questionnaire screen flow |

Diagrams can be regenerated via:
```bash
cd docs/flows
python3 generate_all.py
```

---

Made with ❤️ by Brody Bastiman & Luke Vassor
