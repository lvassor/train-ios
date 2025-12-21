#!/usr/bin/env python3
"""
Fuzzy match exercise names from our database to Gym-Visual video IDs.
Uses difflib for string similarity matching.
"""

import csv
import pandas as pd
from difflib import SequenceMatcher
import re

def normalize_name(name):
    """Normalize exercise name for better matching."""
    name = name.lower()
    # Remove parenthetical content for matching
    name = re.sub(r'\([^)]*\)', '', name)
    # Remove common variations
    name = name.replace('-', ' ')
    name = name.replace('  ', ' ')
    name = name.strip()
    return name

def similarity(a, b):
    """Calculate similarity ratio between two strings."""
    return SequenceMatcher(None, normalize_name(a), normalize_name(b)).ratio()

def find_best_match(exercise_name, video_list, top_n=3):
    """Find the best matching video(s) for an exercise name."""
    scores = []
    for video in video_list:
        video_name = video['Name']
        score = similarity(exercise_name, video_name)
        scores.append((score, video))

    # Sort by score descending
    scores.sort(key=lambda x: x[0], reverse=True)
    return scores[:top_n]

def main():
    # Load our exercises from Excel
    excel_path = 'train_exercise_database_prod.xlsx'
    df = pd.read_excel(excel_path)
    our_exercises = df['display_name'].tolist()

    print(f"Loaded {len(our_exercises)} exercises from Excel")

    # Load Gym-Visual videos
    csv_path = 'Gym-Visual-EXERCISES-list.xlsx - Videos.csv'
    videos = []
    with open(csv_path, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            videos.append(row)

    print(f"Loaded {len(videos)} videos from Gym-Visual")
    print()

    # Match each exercise
    results = []
    for exercise in our_exercises:
        matches = find_best_match(exercise, videos, top_n=1)
        best_score, best_match = matches[0]

        results.append({
            'display_name': exercise,
            'gym_visual_name': best_match['Name'],
            'gym_visual_id': best_match['ID'],
            'match_score': round(best_score, 3)
        })

        # Print progress
        status = "✓" if best_score >= 0.6 else "?" if best_score >= 0.4 else "✗"
        print(f"{status} [{best_score:.2f}] {exercise}")
        print(f"       → {best_match['Name']} (ID: {best_match['ID']})")

    # Save results
    output_path = 'exercise_video_matches.csv'
    with open(output_path, 'w', newline='', encoding='utf-8') as f:
        fieldnames = ['display_name', 'gym_visual_name', 'gym_visual_id', 'match_score']
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(results)

    print()
    print(f"Results saved to: {output_path}")

    # Summary stats
    high_confidence = len([r for r in results if r['match_score'] >= 0.6])
    medium_confidence = len([r for r in results if 0.4 <= r['match_score'] < 0.6])
    low_confidence = len([r for r in results if r['match_score'] < 0.4])

    print()
    print("=== SUMMARY ===")
    print(f"High confidence (≥0.6):   {high_confidence}")
    print(f"Medium confidence (0.4-0.6): {medium_confidence}")
    print(f"Low confidence (<0.4):    {low_confidence}")

if __name__ == '__main__':
    main()
