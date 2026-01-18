#!/usr/bin/env python3
"""
Exercise Database Generator v3
==============================
This script creates a SQLite database directly in trAInSwift/Resources/ from:
- train_exercise_database_prod.xlsx (master sheet)
- train_exercise_contraindications_prod.xlsx (data sheet)
- exercise_video_mapping.csv (video URLs)
- constants.json (centralized mappings)

Usage:
    python create_database_prod.py

Requirements:
    - pandas (install with: pip install pandas openpyxl)

Output:
    - trAInSwift/Resources/exercises.db (SQLite database ready for iOS)
    - Swift constants file for perfect sync
"""

import sqlite3
import pandas as pd
import os
import sys
import shutil
import json

def load_constants():
    """Load constants from JSON file."""
    try:
        with open('constants.json', 'r') as f:
            return json.load(f)
    except FileNotFoundError:
        print("❌ Error: constants.json not found!")
        print("   Please create constants.json with equipment mappings.")
        sys.exit(1)
    except json.JSONDecodeError as e:
        print(f"❌ Error: Invalid JSON in constants.json: {e}")
        sys.exit(1)

def create_database():
    """Create SQLite database directly in Swift Resources from Excel files."""

    # Load constants
    constants = load_constants()
    print("✅ Loaded constants from constants.json")

    # Check if required files exist
    required_files = [
        'train_exercise_database_prod.xlsx',
        'train_exercise_contraindications_prod.xlsx',
        'exercise_video_mapping.csv'
    ]

    for file in required_files:
        if not os.path.exists(file):
            print(f"❌ Error: {file} not found!")
            print(f"   Please make sure all files are in the same directory as this script.")
            sys.exit(1)

    # Determine final database path (directly in Swift Resources)
    script_dir = os.path.dirname(os.path.abspath(__file__))
    # Check if we're in database-management subdirectory or root
    if os.path.basename(script_dir) == 'database-management':
        resources_dir = os.path.join(script_dir, '..', 'trAInSwift', 'Resources')
    else:
        resources_dir = os.path.join(script_dir, 'trAInSwift', 'Resources')
    final_db_path = os.path.join(resources_dir, 'exercises.db')

    # Create Resources directory if it doesn't exist
    if not os.path.exists(resources_dir):
        os.makedirs(resources_dir)
        print(f"📁 Created Resources directory: {resources_dir}")

    # Delete old database if it exists
    if os.path.exists(final_db_path):
        os.remove(final_db_path)
        print("🗑️  Removed old database")

    # Create new database directly at final location
    print(f"📊 Creating new database at: {final_db_path}")
    conn = sqlite3.connect(final_db_path)
    cursor = conn.cursor()

    # ============================================
    # CREATE TABLES
    # ============================================

    print("📋 Creating tables...")

    # Exercises table - NEW SCHEMA with MCV heuristic support
    cursor.execute('''
    CREATE TABLE exercises (
        exercise_id TEXT PRIMARY KEY,
        canonical_name TEXT NOT NULL,
        display_name TEXT NOT NULL,
        equipment_category TEXT NOT NULL,
        equipment_specific TEXT,
        complexity_level TEXT NOT NULL CHECK(complexity_level IN ('all', '1', '2')),
        primary_muscle TEXT NOT NULL,
        secondary_muscle TEXT,
        instructions TEXT,
        is_in_programme INTEGER NOT NULL DEFAULT 1,
        canonical_rating INTEGER NOT NULL DEFAULT 50 CHECK(canonical_rating BETWEEN 0 AND 100),
        progression_id TEXT,
        regression_id TEXT
    )
    ''')

    # Contraindications table - now links to canonical_name
    cursor.execute('''
    CREATE TABLE exercise_contraindications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        canonical_name TEXT NOT NULL,
        injury_type TEXT NOT NULL,
        UNIQUE(canonical_name, injury_type)
    )
    ''')

    # Exercise videos table - for bunny.net integration
    cursor.execute('''
    CREATE TABLE exercise_videos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        exercise_id TEXT NOT NULL,
        supplier_id TEXT,
        media_type TEXT NOT NULL CHECK(media_type IN ('vid', 'img')),
        filename TEXT NOT NULL,
        bunny_url TEXT NOT NULL,
        note TEXT,
        FOREIGN KEY (exercise_id) REFERENCES exercises(exercise_id)
    )
    ''')


    # ============================================
    # CREATE INDEXES
    # ============================================

    print("🔍 Creating indexes...")

    cursor.execute('CREATE INDEX idx_exercises_canonical ON exercises(canonical_name)')
    cursor.execute('CREATE INDEX idx_exercises_category ON exercises(equipment_category)')
    cursor.execute('CREATE INDEX idx_exercises_specific ON exercises(equipment_specific)')
    cursor.execute('CREATE INDEX idx_exercises_complexity ON exercises(complexity_level)')
    cursor.execute('CREATE INDEX idx_exercises_muscle ON exercises(primary_muscle)')
    cursor.execute('CREATE INDEX idx_exercises_programme ON exercises(is_in_programme)')
    cursor.execute('CREATE INDEX idx_exercises_rating ON exercises(canonical_rating)')
    cursor.execute('CREATE INDEX idx_exercises_progression ON exercises(progression_id)')
    cursor.execute('CREATE INDEX idx_exercises_regression ON exercises(regression_id)')
    cursor.execute('CREATE INDEX idx_contraindications_canonical ON exercise_contraindications(canonical_name)')
    cursor.execute('CREATE INDEX idx_contraindications_injury ON exercise_contraindications(injury_type)')
    cursor.execute('CREATE INDEX idx_videos_exercise_id ON exercise_videos(exercise_id)')
    cursor.execute('CREATE INDEX idx_videos_media_type ON exercise_videos(media_type)')

    # ============================================
    # IMPORT DATA
    # ============================================

    print("📥 Importing data...")

    # Import exercises from Excel
    df_exercises = pd.read_excel('train_exercise_database_prod.xlsx', sheet_name='master')

    # Rename column if needed (is_in_programme vs programme_inclusion)
    if 'is_in_programme' in df_exercises.columns:
        pass  # Already correct name
    elif 'programme_inclusion' in df_exercises.columns:
        df_exercises = df_exercises.rename(columns={'programme_inclusion': 'is_in_programme'})

    # Handle new complexity level format (convert Excel format to database format)
    if 'complexity_level' in df_exercises.columns:
        # Convert Excel complexity values to database string format
        def normalize_complexity(x):
            if pd.isna(x):
                return 'all'
            if isinstance(x, str):
                x_clean = x.strip().lower()
                if x_clean == 'all':
                    return 'all'
                elif x_clean == '1':
                    return '1'
                elif x_clean == '2':
                    return '2'
                else:
                    raise ValueError(f"Invalid complexity_level value: '{x}'. Expected 'All', '1', or '2'")
            else:
                # Numeric value
                if x == 0 or pd.isna(x):
                    return 'all'
                elif x == 1:
                    return '1'
                elif x == 2:
                    return '2'
                else:
                    raise ValueError(f"Invalid complexity_level value: {x}. Expected 0, 1, or 2")

        df_exercises['complexity_level'] = df_exercises['complexity_level'].apply(normalize_complexity)

    # Ensure new columns exist - no defaults, fail explicitly if missing
    required_columns = ['canonical_rating', 'progression_id', 'regression_id']
    for col in required_columns:
        if col not in df_exercises.columns:
            raise ValueError(f"Missing required column '{col}' in exercise database. "
                           f"Please update the Excel file to include this column.")
        if col == 'canonical_rating' and df_exercises[col].isnull().any():
            raise ValueError(f"Column '{col}' contains null values. All exercises must have a canonical_rating.")

    # For optional columns, convert NaN to None for nullable fields
    df_exercises['progression_id'] = df_exercises['progression_id'].apply(
        lambda x: None if pd.isna(x) else x)
    df_exercises['regression_id'] = df_exercises['regression_id'].apply(
        lambda x: None if pd.isna(x) else x)

    # Ensure correct column names match our schema (removed is_isolation)
    df_exercises = df_exercises[['exercise_id', 'canonical_name', 'display_name', 'equipment_category',
                                  'equipment_specific', 'complexity_level',
                                  'primary_muscle', 'secondary_muscle', 'instructions', 'is_in_programme',
                                  'canonical_rating', 'progression_id', 'regression_id']]

    # Insert exercises
    for _, row in df_exercises.iterrows():
        cursor.execute('''
            INSERT INTO exercises (exercise_id, canonical_name, display_name, equipment_category,
                                   equipment_specific, complexity_level, primary_muscle,
                                   secondary_muscle, instructions, is_in_programme, canonical_rating,
                                   progression_id, regression_id)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''', (
            row['exercise_id'],
            row['canonical_name'],
            row['display_name'],
            row['equipment_category'],
            row['equipment_specific'] if pd.notna(row['equipment_specific']) else None,
            row['complexity_level'],
            row['primary_muscle'],
            row['secondary_muscle'] if pd.notna(row['secondary_muscle']) else None,
            row['instructions'] if pd.notna(row['instructions']) else None,
            int(row['is_in_programme']),
            int(row['canonical_rating']),
            row['progression_id'] if pd.notna(row['progression_id']) else None,
            row['regression_id'] if pd.notna(row['regression_id']) else None
        ))

    print(f"   ✅ {len(df_exercises)} exercises imported")

    # Import contraindications from Excel (updated sheet name)
    df_contra = pd.read_excel('train_exercise_contraindications_prod.xlsx', sheet_name='data')

    # Only import records with non-null injury_type
    df_contra_valid = df_contra[df_contra['injury_type'].notna()]

    for _, row in df_contra_valid.iterrows():
        cursor.execute('''
            INSERT OR IGNORE INTO exercise_contraindications (canonical_name, injury_type)
            VALUES (?, ?)
        ''', (row['canonical_name'], row['injury_type']))

    print(f"   ✅ {len(df_contra_valid)} contraindications imported (from {len(df_contra)} total records)")

    # Import video mappings from CSV
    df_videos = pd.read_csv('exercise_video_mapping.csv')
    bunny_base_url = constants['video_config']['bunny_base_url']

    video_imported_count = 0
    for _, row in df_videos.iterrows():
        # Skip rows with missing required fields
        if pd.isna(row['media_type']) or pd.isna(row['filename']) or pd.isna(row['exercise_id']):
            continue

        bunny_url = f"{bunny_base_url}{row['filename']}"
        cursor.execute('''
            INSERT INTO exercise_videos (exercise_id, supplier_id, media_type, filename, bunny_url, note)
            VALUES (?, ?, ?, ?, ?, ?)
        ''', (
            row['exercise_id'],
            row['supplier_id'] if pd.notna(row['supplier_id']) else None,
            row['media_type'],
            row['filename'],
            bunny_url,
            row['note'] if pd.notna(row['note']) else None
        ))
        video_imported_count += 1

    print(f"   ✅ {video_imported_count} video mappings imported (from {len(df_videos)} total records)")

    # ============================================
    # VERIFY DATA
    # ============================================

    print("\n" + "="*70)
    print("DATABASE VERIFICATION")
    print("="*70)

    cursor.execute("SELECT COUNT(*) FROM exercises")
    exercises_count = cursor.fetchone()[0]
    print(f"Total exercises: {exercises_count}")

    cursor.execute("SELECT COUNT(*) FROM exercises WHERE is_in_programme = 1")
    programme_count = cursor.fetchone()[0]
    print(f"Exercises in programme: {programme_count}")

    cursor.execute("SELECT COUNT(*) FROM exercise_contraindications")
    contra_count = cursor.fetchone()[0]
    print(f"Total contraindications: {contra_count}")

    cursor.execute("SELECT COUNT(*) FROM exercise_videos")
    video_count = cursor.fetchone()[0]
    print(f"Total video mappings: {video_count}")

    # Show complexity distribution
    print("\nComplexity Distribution:")
    cursor.execute("""
        SELECT complexity_level, COUNT(*) as count
        FROM exercises
        GROUP BY complexity_level
        ORDER BY complexity_level
    """)
    for row in cursor.fetchall():
        print(f"  Level {row[0]}: {row[1]} exercises")

    # Show equipment categories
    print("\nEquipment Categories:")
    cursor.execute("""
        SELECT equipment_category, COUNT(*) as count
        FROM exercises
        GROUP BY equipment_category
        ORDER BY count DESC
    """)
    for row in cursor.fetchall():
        print(f"  {row[0]}: {row[1]} exercises")

    # Show equipment hierarchy (category -> specific)
    print("\nEquipment Hierarchy (for expandable questionnaire):")
    cursor.execute("""
        SELECT equipment_category, equipment_specific, COUNT(*) as count
        FROM exercises
        WHERE equipment_specific IS NOT NULL
        GROUP BY equipment_category, equipment_specific
        ORDER BY equipment_category, equipment_specific
    """)
    current_cat = None
    for row in cursor.fetchall():
        if row[0] != current_cat:
            current_cat = row[0]
            print(f"\n  {current_cat}:")
        print(f"    - {row[1]} ({row[2]} exercises)")

    # Show injury types
    print("\n\nUnique Injury Types (for questionnaire):")
    cursor.execute("""
        SELECT DISTINCT injury_type
        FROM exercise_contraindications
        ORDER BY injury_type
    """)
    injuries = [row[0] for row in cursor.fetchall()]
    print(f"  {injuries}")

    # Sample query to verify everything works
    print("\n" + "="*70)
    print("SAMPLE QUERY: Squat exercises for Intermediate user")
    print("="*70)
    cursor.execute("""
        SELECT exercise_id, display_name, equipment_category, complexity_level
        FROM exercises
        WHERE canonical_name = 'Squat'
          AND complexity_level <= 3
          AND is_in_programme = 1
        ORDER BY complexity_level DESC
        LIMIT 5
    """)
    results = cursor.fetchall()
    if results:
        for row in results:
            print(f"  [{row[0]}] {row[1]} ({row[2]}) - Complexity {row[3]}")
    else:
        print("  (No squat exercises found)")

    # Commit and close
    conn.commit()
    conn.close()

    print("\n" + "="*70)
    print("✅ SUCCESS!")
    print("="*70)
    print(f"📁 Database created at: {final_db_path}")
    print(f"📊 Total exercises: {exercises_count}")
    print(f"📊 Exercises for programme generation: {programme_count}")
    print(f"🎥 Video mappings: {video_count}")
    print(f"⚠️  Contraindications: {contra_count}")
    print(f"📦 Database size: {os.path.getsize(final_db_path)} bytes")
    print(f"\n🎯 Next steps:")
    print("   1. Database is already in the correct location for Xcode")
    print("   2. If not visible in Project Navigator, add exercises.db to project")
    print("   3. Build and run your app (⌘R)")
    print("   4. Video URLs will use bunny.net with base: " + constants['video_config']['bunny_base_url'])
    print("="*70)

if __name__ == "__main__":
    try:
        create_database()
    except Exception as e:
        print(f"\n❌ Error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
