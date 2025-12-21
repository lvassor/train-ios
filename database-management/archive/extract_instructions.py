#!/usr/bin/env python3
"""
Extract exercise instructions from database and trim to single sentences per step.
"""

import pandas as pd
import re

def trim_instruction_step(step_text):
    """Trim a step to its first sentence only."""
    # Remove the "Step N:" prefix for processing
    match = re.match(r'^(Step \d+:)\s*(.+)$', step_text.strip())
    if not match:
        return step_text.strip()

    prefix = match.group(1)
    content = match.group(2)

    # Get first sentence - split on period followed by space and capital letter
    # This handles cases like "45-degree" not being split
    sentences = re.split(r'(?<=[.!?])\s+(?=[A-Z])', content)
    first_sentence = sentences[0].strip()

    # Ensure it ends with a period
    if not first_sentence.endswith(('.', '!', '?')):
        first_sentence += '.'

    return f"{prefix} {first_sentence}"


def trim_instructions(full_instructions):
    """Trim all steps in the instructions to single sentences."""
    if pd.isna(full_instructions) or not full_instructions:
        return ""

    # Split by newline to get individual steps
    steps = full_instructions.split('\n')

    # Trim each step
    trimmed_steps = [trim_instruction_step(step) for step in steps if step.strip()]

    return '\n'.join(trimmed_steps)


def main():
    # Load the Excel file
    excel_path = 'train_exercise_database_prod.xlsx'
    df = pd.read_excel(excel_path)

    print(f"Loaded {len(df)} exercises")

    # Extract required columns and trim instructions
    output_df = pd.DataFrame({
        'exercise_id': df['exercise_id'],
        'display_name': df['display_name'],
        'instructions_trimmed': df['instructions'].apply(trim_instructions)
    })

    # Save to CSV
    output_path = 'exercise_instructions_trimmed.csv'
    output_df.to_csv(output_path, index=False)

    print(f"Saved to: {output_path}")

    # Show a sample
    print("\n=== SAMPLE (first 3 exercises) ===\n")
    for i in range(min(3, len(output_df))):
        print(f"ID: {output_df.iloc[i]['exercise_id']}")
        print(f"Name: {output_df.iloc[i]['display_name']}")
        print(f"Instructions:\n{output_df.iloc[i]['instructions_trimmed']}")
        print("-" * 50)


if __name__ == '__main__':
    main()
