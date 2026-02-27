#!/usr/bin/env python3
"""
Exercise Database Generator v6
==============================
Creates a SQLite database in TrainSwift/Resources/ from:
- equipment_prod.csv              (equipment lookup table)
- exercise_database_prod.csv (exercises with FK equipment IDs)
- exercise_instructions_prod.csv   (instructions joined by exercise_id)
- exercise_contraindications_prod.csv (injury contraindications)
- exercise_video_mapping_prod.csv  (Bunny Stream video GUIDs)

Schema: 4 tables (equipment, exercises, exercise_contraindications, exercise_videos)

Usage:
    python create_database_prod.py

Requirements:
    - pandas (pip install pandas)

Output:
    - TrainSwift/Resources/exercises.db
"""

import sqlite3
import pandas as pd
import os
import sys


def create_database():
    """Create SQLite database from CSV source files."""

    # Check required files
    required_files = [
        "equipment_prod.csv",
        "exercise_database_prod.csv",
        "exercise_instructions_prod.csv",
        "exercise_contraindications_prod.csv",
        "exercise_video_mapping_prod.csv",
    ]
    for f in required_files:
        if not os.path.exists(f):
            print(f"Error: {f} not found!")
            sys.exit(1)

    # Determine output path
    script_dir = os.path.dirname(os.path.abspath(__file__))
    if os.path.basename(script_dir) == "database-management":
        resources_dir = os.path.join(script_dir, "..", "TrainSwift", "Resources")
    else:
        resources_dir = os.path.join(script_dir, "TrainSwift", "Resources")
    final_db_path = os.path.join(resources_dir, "exercises.db")

    os.makedirs(resources_dir, exist_ok=True)

    if os.path.exists(final_db_path):
        os.remove(final_db_path)
        print("Removed old database")

    print(f"Creating database at: {final_db_path}")
    conn = sqlite3.connect(final_db_path)
    conn.execute("PRAGMA foreign_keys = ON")
    cursor = conn.cursor()

    # ============================================
    # CREATE TABLES
    # ============================================

    print("Creating tables...")

    # Equipment table (NEW in v6)
    cursor.execute("""
    CREATE TABLE equipment (
        equipment_id TEXT PRIMARY KEY,
        category TEXT NOT NULL,
        name TEXT NOT NULL,
        image_filename TEXT
    )
    """)

    # Exercises table (equipment_id_1/id_2 replace text columns)
    cursor.execute("""
    CREATE TABLE exercises (
        exercise_id TEXT PRIMARY KEY,
        canonical_name TEXT NOT NULL,
        display_name TEXT NOT NULL,
        equipment_id_1 TEXT NOT NULL REFERENCES equipment(equipment_id),
        equipment_id_2 TEXT REFERENCES equipment(equipment_id),
        complexity_level TEXT NOT NULL CHECK(complexity_level IN ('All', '1', '2')),
        canonical_rating INTEGER NOT NULL DEFAULT 50 CHECK(canonical_rating BETWEEN 0 AND 100),
        primary_muscle TEXT NOT NULL,
        secondary_muscle TEXT,
        instructions TEXT,
        is_in_programme INTEGER NOT NULL DEFAULT 1,
        progression_id TEXT,
        regression_id TEXT
    )
    """)

    # Contraindications table
    cursor.execute("""
    CREATE TABLE exercise_contraindications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        canonical_name TEXT NOT NULL,
        injury_type TEXT NOT NULL,
        UNIQUE(canonical_name, injury_type)
    )
    """)

    # Exercise videos table
    cursor.execute("""
    CREATE TABLE exercise_videos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        exercise_id TEXT NOT NULL UNIQUE REFERENCES exercises(exercise_id),
        supplier_id TEXT,
        filename TEXT NOT NULL,
        bunny_guid TEXT NOT NULL
    )
    """)

    # ============================================
    # CREATE INDEXES
    # ============================================

    print("Creating indexes...")

    cursor.execute("CREATE INDEX idx_equipment_category ON equipment(category)")
    cursor.execute("CREATE INDEX idx_exercises_canonical ON exercises(canonical_name)")
    cursor.execute("CREATE INDEX idx_exercises_equip1 ON exercises(equipment_id_1)")
    cursor.execute("CREATE INDEX idx_exercises_equip2 ON exercises(equipment_id_2)")
    cursor.execute("CREATE INDEX idx_exercises_complexity ON exercises(complexity_level)")
    cursor.execute("CREATE INDEX idx_exercises_muscle ON exercises(primary_muscle)")
    cursor.execute("CREATE INDEX idx_exercises_programme ON exercises(is_in_programme)")
    cursor.execute("CREATE INDEX idx_exercises_rating ON exercises(canonical_rating)")
    cursor.execute("CREATE INDEX idx_contraindications_canonical ON exercise_contraindications(canonical_name)")
    cursor.execute("CREATE INDEX idx_contraindications_injury ON exercise_contraindications(injury_type)")
    cursor.execute("CREATE INDEX idx_videos_exercise_id ON exercise_videos(exercise_id)")
    cursor.execute("CREATE INDEX idx_videos_bunny_guid ON exercise_videos(bunny_guid)")

    # ============================================
    # IMPORT EQUIPMENT
    # ============================================

    print("Importing equipment...")

    df_equipment = pd.read_csv("equipment_prod.csv")

    # Validate: no duplicate equipment_id
    dup_ids = df_equipment[df_equipment.duplicated(subset=["equipment_id"], keep=False)]
    if len(dup_ids) > 0:
        print(f"Error: Duplicate equipment_id values found:")
        for _, row in dup_ids.iterrows():
            print(f"  {row['equipment_id']}: {row['category']}/{row['name']}")
        sys.exit(1)

    # Validate: no duplicate (category, name) pairs
    dup_pairs = df_equipment[df_equipment.duplicated(subset=["category", "name"], keep=False)]
    if len(dup_pairs) > 0:
        print(f"Error: Duplicate (category, name) pairs found:")
        for _, row in dup_pairs.iterrows():
            print(f"  {row['equipment_id']}: {row['category']}/{row['name']}")
        sys.exit(1)

    equipment_ids = set()
    for _, row in df_equipment.iterrows():
        eid = row["equipment_id"].strip()
        equipment_ids.add(eid)
        cursor.execute(
            "INSERT INTO equipment (equipment_id, category, name, image_filename) VALUES (?, ?, ?, ?)",
            (
                eid,
                row["category"].strip(),
                row["name"].strip(),
                row["image_filename"].strip() if pd.notna(row["image_filename"]) else None,
            ),
        )

    print(f"  {len(equipment_ids)} equipment entries imported")

    # ============================================
    # IMPORT EXERCISES
    # ============================================

    print("Importing exercises...")

    df_exercises = pd.read_csv("exercise_database_prod.csv")

    # Join instructions
    df_instructions = pd.read_csv("exercise_instructions_prod.csv")
    print(f"  Loaded {len(df_instructions)} instructions")

    if "instructions" in df_exercises.columns:
        df_exercises = df_exercises.drop(columns=["instructions"])

    df_exercises = df_exercises.merge(
        df_instructions[["exercise_id", "instructions"]],
        on="exercise_id",
        how="left",
    )

    # Report missing instructions
    missing_instr = df_exercises[df_exercises["instructions"].isna()]
    if len(missing_instr) > 0:
        print(f"  Warning: {len(missing_instr)} exercises missing instructions")

    # Normalise complexity_level
    def normalize_complexity(x):
        if pd.isna(x):
            return "All"
        s = str(x).strip()
        if s.lower() == "all":
            return "All"
        elif s in ("1", "2"):
            return s
        else:
            raise ValueError(f"Invalid complexity_level: '{x}'")

    df_exercises["complexity_level"] = df_exercises["complexity_level"].apply(normalize_complexity)

    # Validate required columns
    for col in ["canonical_rating", "equipment_id_1"]:
        if col not in df_exercises.columns:
            raise ValueError(f"Missing required column: {col}")
        if df_exercises[col].isnull().any():
            raise ValueError(f"Column '{col}' contains null values")

    # FK integrity: equipment_id_1 and equipment_id_2 must exist in equipment table
    print("Validating equipment FK integrity...")
    fk_errors = []
    for _, row in df_exercises.iterrows():
        eid1 = str(row["equipment_id_1"]).strip() if pd.notna(row["equipment_id_1"]) else None
        eid2 = str(row["equipment_id_2"]).strip() if pd.notna(row["equipment_id_2"]) else None

        if eid1 and eid1 not in equipment_ids:
            fk_errors.append(f"  {row['exercise_id']}: equipment_id_1={eid1} not in equipment table")
        if eid2 and eid2 not in equipment_ids:
            fk_errors.append(f"  {row['exercise_id']}: equipment_id_2={eid2} not in equipment table")

    if fk_errors:
        print(f"Error: FK integrity failures ({len(fk_errors)}):")
        for e in fk_errors:
            print(e)
        sys.exit(1)
    else:
        print("  All equipment FK references valid")

    # Handle nullable columns
    for col in ["progression_id", "regression_id", "secondary_muscle", "equipment_id_2"]:
        if col in df_exercises.columns:
            df_exercises[col] = df_exercises[col].apply(lambda x: None if pd.isna(x) else str(x).strip())

    # Insert exercises
    for _, row in df_exercises.iterrows():
        cursor.execute(
            """INSERT INTO exercises (exercise_id, canonical_name, display_name,
               equipment_id_1, equipment_id_2, complexity_level, canonical_rating,
               primary_muscle, secondary_muscle, instructions, is_in_programme,
               progression_id, regression_id)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
            (
                row["exercise_id"].strip(),
                row["canonical_name"].strip(),
                row["display_name"].strip(),
                str(row["equipment_id_1"]).strip(),
                row["equipment_id_2"],
                row["complexity_level"],
                int(row["canonical_rating"]),
                row["primary_muscle"].strip(),
                row["secondary_muscle"],
                row["instructions"] if pd.notna(row["instructions"]) else None,
                int(row["is_in_programme"]),
                row["progression_id"],
                row["regression_id"],
            ),
        )

    print(f"  {len(df_exercises)} exercises imported")

    # ============================================
    # IMPORT CONTRAINDICATIONS
    # ============================================

    print("Importing contraindications...")

    df_contra = pd.read_csv("exercise_contraindications_prod.csv")
    df_contra_valid = df_contra[df_contra["injury_type"].notna()]

    for _, row in df_contra_valid.iterrows():
        cursor.execute(
            "INSERT OR IGNORE INTO exercise_contraindications (canonical_name, injury_type) VALUES (?, ?)",
            (row["canonical_name"].strip(), row["injury_type"].strip()),
        )

    print(f"  {len(df_contra_valid)} contraindications imported")

    # ============================================
    # IMPORT VIDEO MAPPINGS
    # ============================================

    print("Importing video mappings...")

    df_videos = pd.read_csv("exercise_video_mapping_prod.csv")

    video_count = 0
    for _, row in df_videos.iterrows():
        if pd.isna(row.get("exercise_id")) or pd.isna(row.get("filename")) or pd.isna(row.get("bunny_guid")):
            continue
        if not str(row["filename"]).strip() or not str(row["bunny_guid"]).strip():
            continue

        cursor.execute(
            """INSERT INTO exercise_videos (exercise_id, supplier_id, filename, bunny_guid)
            VALUES (?, ?, ?, ?)""",
            (
                row["exercise_id"].strip(),
                str(row["supplier_id"]).strip() if pd.notna(row["supplier_id"]) else None,
                row["filename"].strip(),
                row["bunny_guid"].strip(),
            ),
        )
        video_count += 1

    print(f"  {video_count} video mappings imported")

    # ============================================
    # VERIFY
    # ============================================

    print("\n" + "=" * 60)
    print("DATABASE VERIFICATION")
    print("=" * 60)

    cursor.execute("SELECT COUNT(*) FROM equipment")
    eq_count = cursor.fetchone()[0]
    print(f"Equipment entries: {eq_count}")

    cursor.execute("SELECT COUNT(*) FROM exercises")
    ex_count = cursor.fetchone()[0]
    print(f"Total exercises: {ex_count}")

    cursor.execute("SELECT COUNT(*) FROM exercises WHERE is_in_programme = 1")
    prog_count = cursor.fetchone()[0]
    print(f"Exercises in programme: {prog_count}")

    cursor.execute("SELECT COUNT(*) FROM exercise_contraindications")
    contra_count = cursor.fetchone()[0]
    print(f"Contraindications: {contra_count}")

    cursor.execute("SELECT COUNT(*) FROM exercise_videos")
    vid_count = cursor.fetchone()[0]
    print(f"Video mappings: {vid_count}")

    # Equipment by category
    print("\nEquipment by category:")
    cursor.execute("""
        SELECT category, COUNT(*) as cnt
        FROM equipment
        GROUP BY category
        ORDER BY cnt DESC
    """)
    for row in cursor.fetchall():
        print(f"  {row[0]}: {row[1]}")

    # Complexity distribution
    print("\nComplexity distribution:")
    cursor.execute("""
        SELECT complexity_level, COUNT(*) as cnt
        FROM exercises
        GROUP BY complexity_level
        ORDER BY complexity_level
    """)
    for row in cursor.fetchall():
        print(f"  Level {row[0]}: {row[1]} exercises")

    # Equipment usage
    print("\nExercises with equipment_id_2:")
    cursor.execute("SELECT COUNT(*) FROM exercises WHERE equipment_id_2 IS NOT NULL")
    with_id2 = cursor.fetchone()[0]
    cursor.execute("SELECT COUNT(*) FROM exercises WHERE equipment_id_2 IS NULL")
    without_id2 = cursor.fetchone()[0]
    print(f"  With id_2: {with_id2}")
    print(f"  Without id_2 (single equipment): {without_id2}")

    # FK integrity check
    print("\nFK integrity:")
    cursor.execute("""
        SELECT COUNT(*) FROM exercises
        WHERE equipment_id_1 NOT IN (SELECT equipment_id FROM equipment)
    """)
    bad_fk1 = cursor.fetchone()[0]
    cursor.execute("""
        SELECT COUNT(*) FROM exercises
        WHERE equipment_id_2 IS NOT NULL
        AND equipment_id_2 NOT IN (SELECT equipment_id FROM equipment)
    """)
    bad_fk2 = cursor.fetchone()[0]
    print(f"  Bad equipment_id_1 refs: {bad_fk1}")
    print(f"  Bad equipment_id_2 refs: {bad_fk2}")

    if bad_fk1 > 0 or bad_fk2 > 0:
        print("ERROR: FK integrity failures detected!")
        sys.exit(1)

    # Sample query
    print("\nSample: Barbell exercises (equipment_id_1 = EP001):")
    cursor.execute("""
        SELECT e.exercise_id, e.display_name, eq1.name, eq2.name
        FROM exercises e
        JOIN equipment eq1 ON e.equipment_id_1 = eq1.equipment_id
        LEFT JOIN equipment eq2 ON e.equipment_id_2 = eq2.equipment_id
        WHERE e.equipment_id_1 = 'EP001'
        AND e.is_in_programme = 1
        LIMIT 5
    """)
    for row in cursor.fetchall():
        eq2_name = f" + {row[3]}" if row[3] else ""
        print(f"  [{row[0]}] {row[1]} ({row[2]}{eq2_name})")

    # Commit and close
    conn.commit()
    conn.close()

    print("\n" + "=" * 60)
    print("SUCCESS!")
    print("=" * 60)
    print(f"Database: {final_db_path}")
    print(f"Size: {os.path.getsize(final_db_path)} bytes")
    print(f"Equipment: {eq_count} | Exercises: {ex_count} | Videos: {vid_count} | Contraindications: {contra_count}")


if __name__ == "__main__":
    try:
        create_database()
    except Exception as e:
        print(f"\nError: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
