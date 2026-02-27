#!/usr/bin/env python3
"""Generate program_generation_flowchart.pdf — questionnaire -> programme output."""

import subprocess, os

DOT = r"""
digraph program_generation {
    rankdir=TB;
    graph [fontname="Helvetica", fontsize=11, bgcolor="white", pad=0.5, nodesep=0.3, ranksep=0.45];
    node  [fontname="Helvetica", fontsize=10, style=filled, shape=box, color="#333333"];
    edge  [fontname="Helvetica", fontsize=9, color="#666666"];

    // --- Input ---
    subgraph cluster_input {
        label="Input: QuestionnaireData";
        style=rounded; color="#9C27B0"; fontcolor="#9C27B0";

        equipment_ids [label="selectedEquipmentIds\nSet<String>", fillcolor="#F3E5F5"];
        goals [label="primaryGoals\nget_stronger / build_muscle\n/ tone_up", fillcolor="#F3E5F5"];
        experience [label="experienceLevel\n→ complexityRules\n(maxComplexity: 1 or 2)", fillcolor="#F3E5F5"];
        injuries [label="injuries\n→ contraindication\nexclusions", fillcolor="#F3E5F5"];
        schedule [label="trainingDaysPerWeek (1-6)\nselectedSplit\nsessionDuration", fillcolor="#F3E5F5"];
        target_muscles [label="targetMuscleGroups\n(up to 3, boost +1\nexercise per slot)", fillcolor="#F3E5F5"];
    }

    // --- Split determination ---
    subgraph cluster_split {
        label="Split Type Determination";
        style=rounded; color="#FF9800"; fontcolor="#FF9800";

        split_logic [label=<
            <TABLE BORDER="0" CELLPADDING="3">
                <TR><TD><B>determineSplitType(days, duration)</B></TD></TR>
                <TR><TD ALIGN="LEFT">1 day &#8594; Full Body</TD></TR>
                <TR><TD ALIGN="LEFT">2 days + short &#8594; Upper/Lower</TD></TR>
                <TR><TD ALIGN="LEFT">2 days + med/long &#8594; Full Body</TD></TR>
                <TR><TD ALIGN="LEFT">3 days &#8594; Push/Pull/Legs</TD></TR>
                <TR><TD ALIGN="LEFT">4 days &#8594; Upper/Lower</TD></TR>
                <TR><TD ALIGN="LEFT">5 days &#8594; PPL hybrid</TD></TR>
                <TR><TD ALIGN="LEFT">6 days &#8594; PPL x2</TD></TR>
            </TABLE>
        >, fillcolor="#FFF3E0"];

        session_templates [label="SessionTemplate[]\nEach defines:\n- dayName (Push/Pull/Legs/...)\n- muscleGroups:\n  [(muscle, count, pattern?)]", fillcolor="#FFF3E0"];
    }

    // --- Filter + query ---
    build_filter [label="Build ExerciseDatabaseFilter\n- allowedEquipmentIds\n- maxComplexity (from experience)\n- excludeInjuries\n- onlyProgrammeExercises = true", fillcolor="#E1BEE7"];

    exercise_pool [label="Filtered Exercise Pool\n(fetchExercises via GRDB)", fillcolor="#BBDEFB", shape=ellipse];

    // --- Per-session selection ---
    subgraph cluster_selection {
        label="Per-Session Exercise Selection";
        style=rounded; color="#4CAF50"; fontcolor="#4CAF50";

        select [label="ExerciseRepository\n.selectExercisesWithWarnings()\n- For each muscle slot:\n  pick N exercises\n  weighted by canonical_rating\n- Exclude used IDs across sessions\n- Exclude same canonical_name\n  within a session", fillcolor="#E8F5E9"];
        retry [label="Retry with relaxed\nconstraints if pool empty:\n- Drop movement pattern\n- Beginner complexity\n- Basic equipment only", fillcolor="#E8F5E9"];
        emergency [label="Emergency fallback:\nBodyweight exercises\n(Push-ups, Pull-ups,\nSquats) if still empty", fillcolor="#FFCDD2"];
    }

    // --- Parameterisation ---
    subgraph cluster_params {
        label="Exercise Parameterisation";
        style=rounded; color="#00897B"; fontcolor="#00897B";

        rep_range [label=<
            <TABLE BORDER="0" CELLPADDING="3">
                <TR><TD><B>Rep range (goal + rating)</B></TD></TR>
                <TR><TD ALIGN="LEFT">get_stronger + high rating: 5-8</TD></TR>
                <TR><TD ALIGN="LEFT">get_stronger + low rating: 6-10</TD></TR>
                <TR><TD ALIGN="LEFT">build_muscle + high: 8-12</TD></TR>
                <TR><TD ALIGN="LEFT">tone_up: 10-14</TD></TR>
            </TABLE>
        >, fillcolor="#E0F2F1"];
        rest [label="Rest seconds (from rating):\nrating > 80: 120s\nrating 50-80: 90s\nrating < 50: 60s", fillcolor="#E0F2F1"];
        sets [label="Sets: 3\n(fixed)", fillcolor="#E0F2F1"];
    }

    // --- Warnings ---
    subgraph cluster_warnings {
        label="Warning Detection";
        style=dashed; color="#F44336"; fontcolor="#F44336";

        warnings [label="ProgramGenerationResult\n- lowFillWarning: any session\n  < 75% expected exercises\n- repeatWarning: duplicate\n  exercises detected\n- attachmentWarning: cables\n  selected but no attachments", fillcolor="#FFEBEE"];
    }

    // --- Output ---
    output [label="Program\n- type: ProgramType\n- sessions: [ProgramSession]\n- daysPerWeek: Int\n- totalWeeks: 8\n\nEach ProgramSession:\n- dayName, exercises:\n  [ProgramExercise]", fillcolor="#C8E6C9", shape=doubleoctagon];

    // --- Fallback ---
    hardcoded [label="HardcodedPrograms\n.getProgram()\n(fallback if DB fails\nor 0 exercises)", fillcolor="#FFCDD2", shape=note];

    // --- Edges ---
    schedule -> split_logic;
    split_logic -> session_templates;

    equipment_ids -> build_filter;
    experience -> build_filter;
    injuries -> build_filter;
    build_filter -> exercise_pool;

    goals -> rep_range;
    target_muscles -> select;

    exercise_pool -> select;
    session_templates -> select;
    select -> retry [style=dashed, label="pool empty"];
    retry -> emergency [style=dashed, label="still empty"];
    select -> rep_range;
    select -> rest;
    select -> sets;

    rep_range -> output;
    rest -> output;
    sets -> output;

    select -> warnings [style=dotted];
    warnings -> output [style=dotted];

    exercise_pool -> hardcoded [style=dashed, label="0 exercises\nor DB error"];
    hardcoded -> output [style=dashed];
}
"""

def main():
    out_dir = os.path.dirname(os.path.abspath(__file__))
    dot_path = os.path.join(out_dir, "_tmp_program_generation.dot")
    pdf_path = os.path.join(out_dir, "program_generation_flowchart.pdf")

    with open(dot_path, "w") as f:
        f.write(DOT)

    subprocess.run(["dot", "-Tpdf", dot_path, "-o", pdf_path], check=True)
    os.remove(dot_path)
    print(f"Generated {pdf_path}")


if __name__ == "__main__":
    main()
