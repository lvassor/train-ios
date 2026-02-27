#!/usr/bin/env python3
"""Generate database_schema.pdf — ER diagram for exercises.db (4 tables)."""

import subprocess, os

DOT = r"""
digraph database_schema {
    rankdir=LR;
    graph [fontname="Helvetica", fontsize=12, bgcolor="white", pad=0.5];
    node  [fontname="Helvetica", fontsize=10, shape=plaintext];
    edge  [fontname="Helvetica", fontsize=9];

    equipment [label=<
        <TABLE BORDER="1" CELLBORDER="0" CELLSPACING="0" CELLPADDING="6" BGCOLOR="#E8F4FD">
            <TR><TD COLSPAN="3" BGCOLOR="#2196F3"><FONT COLOR="white"><B>equipment</B></FONT></TD></TR>
            <TR><TD ALIGN="LEFT"><B>equipment_id</B></TD><TD>TEXT</TD><TD>PK</TD></TR>
            <TR><TD ALIGN="LEFT">category</TD><TD>TEXT</TD><TD>NOT NULL</TD></TR>
            <TR><TD ALIGN="LEFT">name</TD><TD>TEXT</TD><TD>NOT NULL</TD></TR>
            <TR><TD ALIGN="LEFT">image_filename</TD><TD>TEXT</TD><TD></TD></TR>
        </TABLE>
    >];

    exercises [label=<
        <TABLE BORDER="1" CELLBORDER="0" CELLSPACING="0" CELLPADDING="6" BGCOLOR="#FFF3E0">
            <TR><TD COLSPAN="3" BGCOLOR="#FF9800"><FONT COLOR="white"><B>exercises</B></FONT></TD></TR>
            <TR><TD ALIGN="LEFT"><B>exercise_id</B></TD><TD>TEXT</TD><TD>PK</TD></TR>
            <TR><TD ALIGN="LEFT">canonical_name</TD><TD>TEXT</TD><TD>NOT NULL</TD></TR>
            <TR><TD ALIGN="LEFT">display_name</TD><TD>TEXT</TD><TD>NOT NULL</TD></TR>
            <TR><TD ALIGN="LEFT"><I>equipment_id_1</I></TD><TD>TEXT</TD><TD>FK NOT NULL</TD></TR>
            <TR><TD ALIGN="LEFT"><I>equipment_id_2</I></TD><TD>TEXT</TD><TD>FK nullable</TD></TR>
            <TR><TD ALIGN="LEFT">complexity_level</TD><TD>TEXT</TD><TD>All/1/2</TD></TR>
            <TR><TD ALIGN="LEFT">canonical_rating</TD><TD>INT</TD><TD>0-100</TD></TR>
            <TR><TD ALIGN="LEFT">primary_muscle</TD><TD>TEXT</TD><TD>NOT NULL</TD></TR>
            <TR><TD ALIGN="LEFT">secondary_muscle</TD><TD>TEXT</TD><TD></TD></TR>
            <TR><TD ALIGN="LEFT">instructions</TD><TD>TEXT</TD><TD></TD></TR>
            <TR><TD ALIGN="LEFT">is_in_programme</TD><TD>INT</TD><TD>0/1</TD></TR>
            <TR><TD ALIGN="LEFT">progression_id</TD><TD>TEXT</TD><TD></TD></TR>
            <TR><TD ALIGN="LEFT">regression_id</TD><TD>TEXT</TD><TD></TD></TR>
        </TABLE>
    >];

    exercise_videos [label=<
        <TABLE BORDER="1" CELLBORDER="0" CELLSPACING="0" CELLPADDING="6" BGCOLOR="#E8F5E9">
            <TR><TD COLSPAN="3" BGCOLOR="#4CAF50"><FONT COLOR="white"><B>exercise_videos</B></FONT></TD></TR>
            <TR><TD ALIGN="LEFT"><B>id</B></TD><TD>INT</TD><TD>PK AUTO</TD></TR>
            <TR><TD ALIGN="LEFT"><I>exercise_id</I></TD><TD>TEXT</TD><TD>FK UNIQUE NOT NULL</TD></TR>
            <TR><TD ALIGN="LEFT">supplier_id</TD><TD>TEXT</TD><TD></TD></TR>
            <TR><TD ALIGN="LEFT">filename</TD><TD>TEXT</TD><TD>NOT NULL</TD></TR>
            <TR><TD ALIGN="LEFT">bunny_guid</TD><TD>TEXT</TD><TD>NOT NULL</TD></TR>
        </TABLE>
    >];

    exercise_contraindications [label=<
        <TABLE BORDER="1" CELLBORDER="0" CELLSPACING="0" CELLPADDING="6" BGCOLOR="#FCE4EC">
            <TR><TD COLSPAN="3" BGCOLOR="#E91E63"><FONT COLOR="white"><B>exercise_contraindications</B></FONT></TD></TR>
            <TR><TD ALIGN="LEFT"><B>id</B></TD><TD>INT</TD><TD>PK AUTO</TD></TR>
            <TR><TD ALIGN="LEFT">canonical_name</TD><TD>TEXT</TD><TD>NOT NULL</TD></TR>
            <TR><TD ALIGN="LEFT">injury_type</TD><TD>TEXT</TD><TD>NOT NULL</TD></TR>
            <TR><TD COLSPAN="3"><FONT POINT-SIZE="8">UNIQUE(canonical_name, injury_type)</FONT></TD></TR>
        </TABLE>
    >];

    // FK relationships
    exercises -> equipment [label="equipment_id_1\n(N:1, required)", style=bold, color="#2196F3"];
    exercises -> equipment [label="equipment_id_2\n(N:1, nullable)", style=dashed, color="#2196F3"];
    exercise_videos -> exercises [label="exercise_id\n(1:1, UNIQUE)", color="#4CAF50"];
    exercise_contraindications -> exercises [label="canonical_name\n(logical join)", style=dotted, color="#E91E63"];
}
"""

def main():
    out_dir = os.path.dirname(os.path.abspath(__file__))
    dot_path = os.path.join(out_dir, "_tmp_database_schema.dot")
    pdf_path = os.path.join(out_dir, "database_schema.pdf")

    with open(dot_path, "w") as f:
        f.write(DOT)

    subprocess.run(["dot", "-Tpdf", dot_path, "-o", pdf_path], check=True)
    os.remove(dot_path)
    print(f"Generated {pdf_path}")


if __name__ == "__main__":
    main()
