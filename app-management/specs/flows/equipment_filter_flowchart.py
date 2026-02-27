#!/usr/bin/env python3
"""Generate equipment_filter_flowchart.pdf — user equipment -> exercise pool."""

import subprocess, os

DOT = r"""
digraph equipment_filter {
    rankdir=TB;
    graph [fontname="Helvetica", fontsize=11, bgcolor="white", pad=0.5, nodesep=0.4, ranksep=0.6];
    node  [fontname="Helvetica", fontsize=10, style=filled, shape=box, color="#333333"];
    edge  [fontname="Helvetica", fontsize=9, color="#666666"];

    // --- Questionnaire input ---
    subgraph cluster_questionnaire {
        label="Questionnaire UI (EquipmentStepView)";
        style=rounded; color="#2196F3"; fontcolor="#2196F3";

        q_categories [label="User selects equipment\ncategories (checkboxes)\ne.g. Barbells, Dumbbells,\nCable Machines", fillcolor="#E8F4FD"];
        q_specific [label="User selects specific items\nwithin each category\ne.g. Squat Rack, Flat Bench Press,\nSingle Adjustable Cable Machine", fillcolor="#E8F4FD"];
        q_attachments [label="User selects cable\nattachments (if cables ticked)\ne.g. Rope, D-Handles, EZ-Bar Cable", fillcolor="#E8F4FD"];
    }

    // --- ID resolution ---
    subgraph cluster_resolve {
        label="Equipment ID Resolution (ExerciseDatabaseManager)";
        style=rounded; color="#FF9800"; fontcolor="#FF9800";

        resolve [label="resolveEquipmentIds(\n  categories: [String],\n  specificNames: [String],\n  attachmentNames: [String]\n)", fillcolor="#FFF3E0"];
        auto_include [label="Auto-include rules:\n1. Bodyweight (EP043) always present\n2. Category base IDs added\n   when any child selected\n   e.g. EP001 for Barbells\n   EP010 for Dumbbells\n   EP012 for Kettlebells", fillcolor="#FFF3E0"];
        final_set [label="allowedEquipmentIds: Set<String>\ne.g. {EP001, EP002, EP003,\nEP010, EP013, EP043, EP052}", fillcolor="#FFE0B2", shape=ellipse];
    }

    // --- Filter construction ---
    subgraph cluster_filter {
        label="ExerciseDatabaseFilter";
        style=rounded; color="#9C27B0"; fontcolor="#9C27B0";

        filter [label=<
            <TABLE BORDER="0" CELLPADDING="4">
                <TR><TD><B>Filter fields:</B></TD></TR>
                <TR><TD ALIGN="LEFT">allowedEquipmentIds: Set&lt;String&gt;</TD></TR>
                <TR><TD ALIGN="LEFT">maxComplexity: Int (from experience)</TD></TR>
                <TR><TD ALIGN="LEFT">excludeInjuries: [String]</TD></TR>
                <TR><TD ALIGN="LEFT">onlyProgrammeExercises: true</TD></TR>
                <TR><TD ALIGN="LEFT">primaryMuscle: String? (optional)</TD></TR>
            </TABLE>
        >, fillcolor="#F3E5F5"];
    }

    // --- SQL query ---
    subgraph cluster_sql {
        label="GRDB Query (fetchExercises)";
        style=rounded; color="#4CAF50"; fontcolor="#4CAF50";

        query [label=<
            <TABLE BORDER="0" CELLPADDING="4">
                <TR><TD><B>WHERE clauses:</B></TD></TR>
                <TR><TD ALIGN="LEFT">1. is_in_programme = 1</TD></TR>
                <TR><TD ALIGN="LEFT">2. equipment_id_1 IN (ids)</TD></TR>
                <TR><TD ALIGN="LEFT">3. equipment_id_2 IS NULL</TD></TR>
                <TR><TD ALIGN="LEFT">   OR equipment_id_2 IN (ids)</TD></TR>
                <TR><TD ALIGN="LEFT">4. complexity_level IN ('All','1')</TD></TR>
                <TR><TD ALIGN="LEFT">   or IN ('All','1','2')</TD></TR>
                <TR><TD ALIGN="LEFT">5. primary_muscle = ? (if set)</TD></TR>
            </TABLE>
        >, fillcolor="#E8F5E9"];

        injury_exclude [label="Post-query exclusion:\nSELECT DISTINCT canonical_name\nFROM exercise_contraindications\nWHERE injury_type IN (...)\n-> remove matching exercises", fillcolor="#E8F5E9"];
    }

    // --- Output ---
    result [label="Filtered exercise pool\nSorted by complexity DESC\n(~50-150 exercises)", fillcolor="#C8E6C9", shape=doubleoctagon];

    // --- Example ---
    subgraph cluster_example {
        label="Example";
        style=dashed; color="#9E9E9E"; fontcolor="#9E9E9E";

        example [label=<
            <TABLE BORDER="0" CELLPADDING="4">
                <TR><TD><B>User has: Barbells + Squat Rack + Flat Bench</B></TD></TR>
                <TR><TD>IDs: {EP001, EP002, EP003, EP043}</TD></TR>
                <TR><TD ALIGN="LEFT">Barbell Curl (EP001, NULL) = INCLUDED</TD></TR>
                <TR><TD ALIGN="LEFT">Barbell Bench Press (EP001, EP003) = INCLUDED</TD></TR>
                <TR><TD ALIGN="LEFT">Barbell Incline Press (EP001, EP004) = EXCLUDED</TD></TR>
                <TR><TD ALIGN="LEFT">(EP004 Incline Bench not in set)</TD></TR>
            </TABLE>
        >, fillcolor="#F5F5F5", shape=note];
    }

    // --- Edges ---
    q_categories -> q_specific;
    q_specific -> q_attachments;
    q_attachments -> resolve;
    resolve -> auto_include;
    auto_include -> final_set;
    final_set -> filter;
    filter -> query;
    query -> injury_exclude;
    injury_exclude -> result;
}
"""

def main():
    out_dir = os.path.dirname(os.path.abspath(__file__))
    dot_path = os.path.join(out_dir, "_tmp_equipment_filter.dot")
    pdf_path = os.path.join(out_dir, "equipment_filter_flowchart.pdf")

    with open(dot_path, "w") as f:
        f.write(DOT)

    subprocess.run(["dot", "-Tpdf", dot_path, "-o", pdf_path], check=True)
    os.remove(dot_path)
    print(f"Generated {pdf_path}")


if __name__ == "__main__":
    main()
