#!/usr/bin/env python3
"""Generate database_generation_flowchart.pdf — CSV-to-SQLite pipeline."""

import subprocess, os

DOT = r"""
digraph database_generation {
    rankdir=TB;
    graph [fontname="Helvetica", fontsize=11, bgcolor="white", pad=0.5, nodesep=0.4, ranksep=0.5];
    node  [fontname="Helvetica", fontsize=10, style=filled, shape=box, color="#333333"];
    edge  [fontname="Helvetica", fontsize=9, color="#666666"];

    // --- Source CSV files ---
    subgraph cluster_csvs {
        label="Source CSV Files (database-management/)";
        style=rounded; color="#9C27B0"; fontcolor="#9C27B0";

        csv_equip      [label="equipment_prod.csv\nequipment_id, category,\nname, image_filename\n(61 rows)", fillcolor="#F3E5F5"];
        csv_exercises   [label="exercise_database_prod.csv\nexercise_id, canonical_name,\ndisplay_name, equipment_id_1,\nequipment_id_2, complexity_level,\ncanonical_rating, primary_muscle,\nsecondary_muscle, progression_id,\nregression_id, is_in_programme\n(230 rows)", fillcolor="#F3E5F5"];
        csv_instructions[label="exercise_instructions_prod.csv\nexercise_id, display_name,\ninstructions\n(920 rows)", fillcolor="#F3E5F5"];
        csv_contra      [label="exercise_contraindications_prod.csv\ncanonical_name, injury_type\n(40 rows)", fillcolor="#F3E5F5"];
        csv_videos      [label="exercise_video_mapping_prod.csv\nexercise_id, display_name,\nsupplier_id, filename, bunny_guid\n(230 rows)", fillcolor="#F3E5F5"];
    }

    // --- Build script ---
    subgraph cluster_script {
        label="create_database_prod.py";
        style=rounded; color="#FF9800"; fontcolor="#FF9800";

        s1 [label="1. Create tables\n(equipment, exercises,\nexercise_contraindications,\nexercise_videos)", fillcolor="#FFF3E0"];
        s2 [label="2. Create indexes\n(13 indexes on FK,\nmuscle, complexity,\nrating, bunny_guid)", fillcolor="#FFF3E0"];
        s3 [label="3. Import equipment\n- Validate no duplicate IDs\n- Validate no duplicate\n  (category, name) pairs", fillcolor="#FFF3E0"];
        s4 [label="4. Import exercises\n- LEFT JOIN instructions CSV\n- Normalise complexity_level\n- Validate FK integrity\n  (equipment_id_1/2 exist)", fillcolor="#FFF3E0"];
        s5 [label="5. Import contraindications\n- Skip null injury_type\n- INSERT OR IGNORE", fillcolor="#FFF3E0"];
        s6 [label="6. Import video mappings\n- Skip rows with null\n  exercise_id/filename/bunny_guid\n- UNIQUE on exercise_id", fillcolor="#FFF3E0"];
        s7 [label="7. Verify\n- Row counts per table\n- FK integrity check\n- Equipment by category\n- Complexity distribution", fillcolor="#FFE0B2"];
    }

    // --- Output ---
    db [label="exercises.db\nTrainSwift/Resources/\n(bundled in app)", fillcolor="#C8E6C9", shape=doubleoctagon];

    // --- iOS app load ---
    subgraph cluster_app {
        label="iOS App (ExerciseDatabaseManager)";
        style=rounded; color="#2196F3"; fontcolor="#2196F3";

        copy [label="copyDatabaseIfNeeded()\nCopy .db from bundle\nto Documents/", fillcolor="#E8F4FD"];
        open [label="Open via GRDB\n(DatabaseQueue)", fillcolor="#E8F4FD"];
        cache_eq [label="loadEquipmentCache()\nAll equipment -> Dict", fillcolor="#E8F4FD"];
        cache_vid [label="loadVideoGuidCache()\nAll video GUIDs -> Dict\n(exerciseId -> bunnyGuid)", fillcolor="#E8F4FD"];
    }

    // Edges
    csv_equip -> s3;
    csv_exercises -> s4;
    csv_instructions -> s4;
    csv_contra -> s5;
    csv_videos -> s6;

    s1 -> s2 -> s3 -> s4 -> s5 -> s6 -> s7;
    s7 -> db;

    db -> copy;
    copy -> open;
    open -> cache_eq;
    cache_eq -> cache_vid;
}
"""

def main():
    out_dir = os.path.dirname(os.path.abspath(__file__))
    dot_path = os.path.join(out_dir, "_tmp_database_generation.dot")
    pdf_path = os.path.join(out_dir, "database_generation_flowchart.pdf")

    with open(dot_path, "w") as f:
        f.write(DOT)

    subprocess.run(["dot", "-Tpdf", dot_path, "-o", pdf_path], check=True)
    os.remove(dot_path)
    print(f"Generated {pdf_path}")


if __name__ == "__main__":
    main()
