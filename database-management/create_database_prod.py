#!/usr/bin/env python3
"""
Exercise Database Generator v2
==============================
This script creates a SQLite database (exercises.db) from the Excel files:
- train_exercise_database_prod.xlsx (master sheet)
- train_exercise_contraindications_prod.xlsx (data sheet)

Usage:
    python create_database_v2.py

Requirements:
    - pandas (install with: pip install pandas openpyxl)

Output:
    - exercises.db (SQLite database file ready for Xcode)
"""

import sqlite3
import pandas as pd
import os
import sys
import shutil

def create_database():
    """Create SQLite database from Excel files."""

    # Check if Excel files exist
    required_files = [
        'train_exercise_database_prod.xlsx',
        'train_exercise_contraindications_prod.xlsx'
    ]

    for file in required_files:
        if not os.path.exists(file):
            print(f"❌ Error: {file} not found!")
            print(f"   Please make sure all Excel files are in the same directory as this script.")
            sys.exit(1)

    # Delete old database if it exists
    if os.path.exists('exercises.db'):
        os.remove('exercises.db')
        print("🗑️  Removed old database")

    # Create new database
    print("📊 Creating new database...")
    conn = sqlite3.connect('exercises.db')
    cursor = conn.cursor()

    # ============================================
    # CREATE TABLES
    # ============================================

    print("📋 Creating tables...")

    # Exercises table - NEW SCHEMA matching Excel structure
    cursor.execute('''
    CREATE TABLE exercises (
        exercise_id TEXT PRIMARY KEY,
        canonical_name TEXT NOT NULL,
        display_name TEXT NOT NULL,
        equipment_category TEXT NOT NULL,
        equipment_specific TEXT,
        complexity_level INTEGER NOT NULL CHECK(complexity_level BETWEEN 1 AND 4),
        is_isolation INTEGER NOT NULL DEFAULT 0,
        primary_muscle TEXT NOT NULL,
        secondary_muscle TEXT,
        instructions TEXT,
        is_in_programme INTEGER NOT NULL DEFAULT 1
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


    # ============================================
    # CREATE INDEXES
    # ============================================

    print("🔍 Creating indexes...")

    cursor.execute('CREATE INDEX idx_exercises_canonical ON exercises(canonical_name)')
    cursor.execute('CREATE INDEX idx_exercises_category ON exercises(equipment_category)')
    cursor.execute('CREATE INDEX idx_exercises_specific ON exercises(equipment_specific)')
    cursor.execute('CREATE INDEX idx_exercises_complexity ON exercises(complexity_level)')
    cursor.execute('CREATE INDEX idx_exercises_muscle ON exercises(primary_muscle)')
    cursor.execute('CREATE INDEX idx_exercises_isolation ON exercises(is_isolation)')
    cursor.execute('CREATE INDEX idx_exercises_programme ON exercises(is_in_programme)')
    cursor.execute('CREATE INDEX idx_contraindications_canonical ON exercise_contraindications(canonical_name)')
    cursor.execute('CREATE INDEX idx_contraindications_injury ON exercise_contraindications(injury_type)')

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

    # Ensure correct column names match our schema
    df_exercises = df_exercises[['exercise_id', 'canonical_name', 'display_name', 'equipment_category',
                                  'equipment_specific', 'complexity_level', 'is_isolation',
                                  'primary_muscle', 'secondary_muscle', 'instructions', 'is_in_programme']]

    # Insert exercises
    for _, row in df_exercises.iterrows():
        cursor.execute('''
            INSERT INTO exercises (exercise_id, canonical_name, display_name, equipment_category,
                                   equipment_specific, complexity_level, is_isolation, primary_muscle,
                                   secondary_muscle, instructions, is_in_programme)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''', (
            row['exercise_id'],
            row['canonical_name'],
            row['display_name'],
            row['equipment_category'],
            row['equipment_specific'] if pd.notna(row['equipment_specific']) else None,
            int(row['complexity_level']),
            int(row['is_isolation']),
            row['primary_muscle'],
            row['secondary_muscle'] if pd.notna(row['secondary_muscle']) else None,
            row['instructions'] if pd.notna(row['instructions']) else None,
            int(row['is_in_programme'])
        ))

    print(f"   ✅ {len(df_exercises)} exercises imported")

    # Import contraindications from Excel
    df_contra = pd.read_excel('train_exercise_contraindications_prod.xlsx', sheet_name='Sheet1')

    for _, row in df_contra.iterrows():
        cursor.execute('''
            INSERT OR IGNORE INTO exercise_contraindications (canonical_name, injury_type)
            VALUES (?, ?)
        ''', (row['canonical_name'], row['injury_type']))

    print(f"   ✅ {len(df_contra)} contraindications imported")

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

    cursor.execute("SELECT COUNT(*) FROM user_experience_complexity")
    exp_count = cursor.fetchone()[0]
    print(f"Total experience levels: {exp_count}")

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

    # ============================================
    # COPY DATABASE TO XCODE RESOURCES
    # ============================================

    print("\n" + "="*70)
    print("COPYING DATABASE TO XCODE PROJECT")
    print("="*70)

    # Determine the Resources folder path
    script_dir = os.path.dirname(os.path.abspath(__file__))
    resources_dir = os.path.join(script_dir, '..', 'trAInSwift', 'Resources')
    source_db = os.path.join(script_dir, 'exercises.db')
    target_db = os.path.join(resources_dir, 'exercises.db')

    # Create Resources directory if it doesn't exist
    if not os.path.exists(resources_dir):
        os.makedirs(resources_dir)
        print(f"📁 Created Resources directory: {resources_dir}")

    # Copy database to Resources folder
    try:
        shutil.copy2(source_db, target_db)
        print(f"✅ Database copied to: {target_db}")
        print(f"📦 Size: {os.path.getsize(target_db)} bytes")
    except Exception as e:
        print(f"⚠️  Warning: Could not copy database to Resources folder")
        print(f"   Error: {e}")
        print(f"   You'll need to manually copy exercises.db to trAInSwift/Resources/")

    print("\n" + "="*70)
    print("✅ SUCCESS!")
    print("="*70)
    print(f"📁 Database created: {source_db}")
    print(f"📁 Database copied to: {target_db}")
    print(f"📊 Total exercises: {exercises_count}")
    print(f"📊 Exercises for programme generation: {programme_count}")
    print(f"\n🎯 Next steps:")
    print("   1. Open Xcode (if not already open)")
    print("   2. If exercises.db is not visible in Xcode Project Navigator:")
    print("      - Right-click trAInSwift folder")
    print("      - Select 'Add Files to trAInSwift...'")
    print("      - Navigate to Resources/exercises.db")
    print("      - ✅ Check 'Copy items if needed'")
    print("      - Click 'Add'")
    print("   3. Build and run your app (⌘R)")
    print("="*70)

if __name__ == "__main__":
    try:
        create_database()
    except Exception as e:
        print(f"\n❌ Error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
