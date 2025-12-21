#!/usr/bin/env python3
"""
Exercise Database Generator
============================
This script creates a SQLite database (exercises.db) from your CSV files.

Usage:
    python create_database.py

Requirements:
    - pandas (install with: pip install pandas)
    - exercises_new_schema.csv
    - exercise_contraindications.csv
    - user_experience_complexity.csv

Output:
    - exercises.db (SQLite database file ready for Xcode)
"""

import sqlite3
import pandas as pd
import os
import sys
import shutil

def create_database():
    """Create SQLite database from CSV files."""

    # Check if CSV files exist
    required_files = [
        'exercises_new_schema.csv',
        'exercise_contraindications.csv',
        'user_experience_complexity.csv'
    ]
    
    for file in required_files:
        if not os.path.exists(file):
            print(f"❌ Error: {file} not found!")
            print(f"   Please make sure all CSV files are in the same directory as this script.")
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
    
    # Exercises table
    cursor.execute('''
    CREATE TABLE exercises (
        exercise_id INTEGER PRIMARY KEY,
        canonical_name TEXT NOT NULL,
        display_name TEXT NOT NULL,
        movement_pattern TEXT NOT NULL,
        equipment_type TEXT NOT NULL,
        complexity_level INTEGER NOT NULL CHECK(complexity_level BETWEEN 1 AND 4),
        primary_muscle TEXT NOT NULL,
        secondary_muscle TEXT,
        instructions TEXT,
        is_active INTEGER NOT NULL DEFAULT 1
    )
    ''')
    
    # Contraindications table
    cursor.execute('''
    CREATE TABLE exercise_contraindications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        exercise_id INTEGER NOT NULL,
        injury_type TEXT NOT NULL,
        FOREIGN KEY (exercise_id) REFERENCES exercises(exercise_id) ON DELETE CASCADE,
        UNIQUE(exercise_id, injury_type)
    )
    ''')
    
    # User experience complexity table
    cursor.execute('''
    CREATE TABLE user_experience_complexity (
        experience_level TEXT PRIMARY KEY,
        display_name TEXT NOT NULL,
        max_complexity INTEGER NOT NULL,
        max_complexity_4_per_session INTEGER NOT NULL,
        complexity_4_must_be_first INTEGER NOT NULL
    )
    ''')
    
    # ============================================
    # CREATE INDEXES
    # ============================================
    
    print("🔍 Creating indexes...")
    
    cursor.execute('CREATE INDEX idx_exercises_pattern ON exercises(movement_pattern)')
    cursor.execute('CREATE INDEX idx_exercises_equipment ON exercises(equipment_type)')
    cursor.execute('CREATE INDEX idx_exercises_complexity ON exercises(complexity_level)')
    cursor.execute('CREATE INDEX idx_exercises_active ON exercises(is_active)')
    cursor.execute('CREATE INDEX idx_contraindications_exercise ON exercise_contraindications(exercise_id)')
    cursor.execute('CREATE INDEX idx_contraindications_injury ON exercise_contraindications(injury_type)')
    
    # ============================================
    # IMPORT DATA
    # ============================================
    
    print("📥 Importing data...")
    
    # Import exercises
    df_exercises = pd.read_csv('exercises_new_schema.csv')
    
    # Convert exercise_id from EXNNN format to integer (if it has EX prefix)
    if df_exercises['exercise_id'].dtype == 'object':
        df_exercises['exercise_id'] = df_exercises['exercise_id'].str.replace('EX', '').astype(int)
    
    # Convert is_active boolean to integer (SQLite doesn't have boolean type)
    if df_exercises['is_active'].dtype == 'bool':
        df_exercises['is_active'] = df_exercises['is_active'].astype(int)
    
    df_exercises.to_sql('exercises', conn, if_exists='append', index=False)
    print(f"   ✅ {len(df_exercises)} exercises imported")
    
    # Import contraindications
    df_contra = pd.read_csv('exercise_contraindications.csv')
    
    # Convert exercise_id from EXNNN format to integer (if it has EX prefix)
    if df_contra['exercise_id'].dtype == 'object':
        df_contra['exercise_id'] = df_contra['exercise_id'].str.replace('EX', '').astype(int)
    
    # Drop the id column if it exists (let SQLite auto-generate)
    if 'id' in df_contra.columns:
        df_contra = df_contra.drop('id', axis=1)
    
    df_contra.to_sql('exercise_contraindications', conn, if_exists='append', index=False)
    print(f"   ✅ {len(df_contra)} contraindications imported")
    
    # Import experience complexity
    df_exp = pd.read_csv('user_experience_complexity.csv')
    
    # Convert boolean to integer
    if df_exp['complexity_4_must_be_first'].dtype == 'bool':
        df_exp['complexity_4_must_be_first'] = df_exp['complexity_4_must_be_first'].astype(int)
    
    df_exp.to_sql('user_experience_complexity', conn, if_exists='append', index=False)
    print(f"   ✅ {len(df_exp)} experience levels imported")
    
    # ============================================
    # VERIFY DATA
    # ============================================
    
    print("\n" + "="*70)
    print("DATABASE VERIFICATION")
    print("="*70)
    
    cursor.execute("SELECT COUNT(*) FROM exercises")
    exercises_count = cursor.fetchone()[0]
    print(f"Total exercises: {exercises_count}")
    
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
    
    # Show movement pattern distribution (top 10)
    print("\nTop Movement Patterns:")
    cursor.execute("""
        SELECT movement_pattern, COUNT(*) as count
        FROM exercises
        GROUP BY movement_pattern
        ORDER BY count DESC
        LIMIT 10
    """)
    for row in cursor.fetchall():
        print(f"  {row[0]}: {row[1]} exercises")
    
    # Sample query to verify everything works
    print("\n" + "="*70)
    print("SAMPLE QUERY: Squat exercises for Intermediate user")
    print("="*70)
    cursor.execute("""
        SELECT exercise_id, display_name, equipment_type, complexity_level
        FROM exercises
        WHERE movement_pattern = 'Squat'
          AND complexity_level <= 3
          AND is_active = 1
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
    # Script is in: database-management/
    # Target is: ../trAInSwift/Resources/
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
        sys.exit(1)
