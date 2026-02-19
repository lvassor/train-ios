#!/usr/bin/env python3
"""
Reconcile exercise_video_mapping_prod.csv against complete_exercise_data.csv.

Rules:
- Source of truth: complete_exercise_data.csv
- Only exercises where prod_ready = "y" AND filename is non-empty get entries
- Exercises where prod_ready != "y" are excluded entirely
- The 'note' column is removed from the output
- supplier_id is derived from the filename prefix (digits before first dash)
- media_type is derived from the file extension (.mp4 → vid, .png/.jpg → img)
"""

import csv
import re
import os

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
SOURCE_CSV = os.path.join(SCRIPT_DIR, "complete_exercise_data.csv")
OUTPUT_CSV = os.path.join(SCRIPT_DIR, "exercise_video_mapping_prod.csv")


def derive_supplier_id(filename: str) -> str:
    """Extract supplier ID from filename prefix (leading digits)."""
    match = re.match(r"^(\d+)", filename)
    return match.group(1)[:4] if match else ""


def derive_media_type(filename: str) -> str:
    """Derive media type from file extension."""
    ext = os.path.splitext(filename)[1].lower()
    if ext in (".mp4", ".mov", ".webm"):
        return "vid"
    elif ext in (".png", ".jpg", ".jpeg", ".webp"):
        return "img"
    return "vid"  # default


def main():
    rows = []

    with open(SOURCE_CSV, newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            prod_ready = row.get("prod_ready", "").strip().lower()
            filename = row.get("filename", "").strip()

            # Only include prod_ready=y with a filename
            if prod_ready != "y" or not filename:
                continue

            # Strip leading ./ if present
            if filename.startswith("./"):
                filename = filename[2:]

            exercise_id = row["exercise_id"].strip()
            display_name = row["display_name"].strip()
            supplier_id = derive_supplier_id(filename)
            media_type = derive_media_type(filename)

            rows.append({
                "exercise_id": exercise_id,
                "display_name": display_name,
                "supplier_id": supplier_id,
                "media_type": media_type,
                "filename": filename,
            })

    # Write output (no 'note' column)
    fieldnames = ["exercise_id", "display_name", "supplier_id", "media_type", "filename"]
    with open(OUTPUT_CSV, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)

    print(f"Wrote {len(rows)} entries to {OUTPUT_CSV}")
    print(f"  (from {SOURCE_CSV})")


if __name__ == "__main__":
    main()
