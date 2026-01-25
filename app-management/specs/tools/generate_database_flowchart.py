#!/usr/bin/env python3
"""
Generate Database Generation Flowchart (Horizontal Layout)
Shows end-to-end database generation process, table joins, and configurations
"""

from graphviz import Digraph
import os

def create_flowchart():
    # Create directed graph with LEFT-TO-RIGHT layout
    dot = Digraph(comment='Database Generation Flowchart')
    dot.attr(rankdir='LR', splines='ortho', nodesep='0.5', ranksep='1.0')
    dot.attr('node', fontname='Helvetica', fontsize='10')
    dot.attr('edge', fontname='Helvetica', fontsize='9')

    # Define node styles
    start_style = {'shape': 'oval', 'style': 'filled', 'fillcolor': '#90EE90'}
    end_style = {'shape': 'oval', 'style': 'filled', 'fillcolor': '#FFB6C1'}
    file_style = {'shape': 'note', 'style': 'filled', 'fillcolor': '#FFF8DC'}
    process_style = {'shape': 'box', 'style': 'filled', 'fillcolor': '#87CEEB'}
    table_style = {'shape': 'cylinder', 'style': 'filled', 'fillcolor': '#E6E6FA'}
    config_style = {'shape': 'component', 'style': 'filled', 'fillcolor': '#FFDAB9'}
    decision_style = {'shape': 'diamond', 'style': 'filled', 'fillcolor': '#FFD700', 'width': '1.5'}

    # === SOURCE FILES ===
    dot.node('start', 'START', **start_style)

    # CSV Source Files
    dot.node('csv_exercises', 'train_exercise_\ndatabase_prod.csv\n(220 exercises)', **file_style)
    dot.node('csv_contra', 'train_exercise_\ncontraindications_\nprod.csv', **file_style)
    dot.node('csv_videos', 'exercise_video_\nmapping.csv', **file_style)
    dot.node('csv_instructions', 'exercise_\ninstructions_\ncomplete.csv', **file_style)

    # Config file
    dot.node('constants', 'constants.json\n(Single Source\nof Truth)', **config_style)

    # === PYTHON GENERATOR ===
    dot.node('python_script', 'create_database_prod.py\n(Python Generator)', **process_style)

    # Load & Validate
    dot.node('load_constants', 'Load Constants\nfrom JSON', **process_style)
    dot.node('validate', 'Validate Equipment\n& Attachments', **process_style)

    # Join operations
    dot.node('join_instructions', 'JOIN\nexercise_id', **process_style)
    dot.node('join_videos', 'JOIN\nexercise_id', **process_style)

    # === DATABASE CREATION ===
    dot.node('create_db', 'Create SQLite\nDatabase', **process_style)

    # Tables
    dot.node('table_exercises', 'exercises\nTable\n(14 columns)', **table_style)
    dot.node('table_contra', 'exercise_\ncontraindications\nTable', **table_style)
    dot.node('table_videos', 'exercise_\nvideos\nTable', **table_style)

    # Indexes
    dot.node('create_indexes', 'Create Indexes\n(14 indexes)', **process_style)

    # === OUTPUT ===
    dot.node('db_file', 'exercises.db\n(trAInSwift/\nResources/)', **file_style)

    # === SWIFT APP LOADING ===
    dot.node('swift_load', 'Swift App\n(GRDB)', **process_style)
    dot.node('constants_mgr', 'Constants\nManager', **config_style)
    dot.node('db_manager', 'Exercise\nDatabase\nManager', **process_style)
    dot.node('exercise_repo', 'Exercise\nRepository', **process_style)

    # === BASELINE POOL ===
    dot.node('filter', 'Apply Filters:\n• Equipment\n• Attachments\n• Complexity', **process_style)
    dot.node('baseline_pool', 'Baseline\nExercise Pool\nfor User', **end_style)

    # === EDGES ===

    # Source files to Python script
    dot.edge('start', 'csv_exercises')
    dot.edge('start', 'csv_contra')
    dot.edge('start', 'csv_videos')
    dot.edge('start', 'csv_instructions')
    dot.edge('start', 'constants')

    # Python loading
    dot.edge('csv_exercises', 'python_script')
    dot.edge('csv_contra', 'python_script')
    dot.edge('csv_videos', 'python_script')
    dot.edge('csv_instructions', 'python_script')
    dot.edge('constants', 'load_constants')
    dot.edge('load_constants', 'python_script')

    # Validation
    dot.edge('python_script', 'validate')

    # Joins
    dot.edge('validate', 'join_instructions', label='exercises +\ninstructions')
    dot.edge('join_instructions', 'join_videos', label='+ videos')

    # Database creation
    dot.edge('join_videos', 'create_db')
    dot.edge('create_db', 'table_exercises')
    dot.edge('create_db', 'table_contra')
    dot.edge('create_db', 'table_videos')

    # Indexes and output
    dot.edge('table_exercises', 'create_indexes')
    dot.edge('table_contra', 'create_indexes')
    dot.edge('table_videos', 'create_indexes')
    dot.edge('create_indexes', 'db_file')

    # Swift loading
    dot.edge('db_file', 'swift_load')
    dot.edge('constants', 'constants_mgr', style='dashed', label='copy to\nResources/')
    dot.edge('swift_load', 'db_manager')
    dot.edge('constants_mgr', 'db_manager')
    dot.edge('db_manager', 'exercise_repo')

    # Filtering to baseline
    dot.edge('exercise_repo', 'filter')
    dot.edge('filter', 'baseline_pool')

    return dot

def create_schema_diagram():
    """Create a separate diagram showing table schemas, source CSVs, and relationships"""
    dot = Digraph(comment='Database Schema')
    dot.attr(rankdir='LR', splines='ortho', nodesep='0.6', ranksep='1.2')
    dot.attr('node', fontname='Helvetica', fontsize='9')
    dot.attr('edge', fontname='Helvetica', fontsize='8')

    # Source CSV styles
    csv_style = {'shape': 'note', 'style': 'filled', 'fillcolor': '#FFF8DC'}

    # Source CSVs
    dot.node('csv_exercises', 'train_exercise_\ndatabase_prod.csv', **csv_style)
    dot.node('csv_instructions', 'exercise_instructions_\ncomplete.csv', **csv_style)
    dot.node('csv_contra', 'train_exercise_\ncontraindications_prod.csv', **csv_style)
    dot.node('csv_videos', 'exercise_video_\nmapping.csv', **csv_style)

    # Join indicator
    dot.node('join_ex_instr', 'JOIN on\nexercise_id', shape='ellipse', style='filled', fillcolor='#98FB98')

    # Table styles using HTML-like labels
    exercises_label = '''<<TABLE BORDER="0" CELLBORDER="1" CELLSPACING="0" CELLPADDING="4">
        <TR><TD BGCOLOR="#E6E6FA" COLSPAN="2"><B>exercises</B></TD></TR>
        <TR><TD>exercise_id</TD><TD>TEXT PK</TD></TR>
        <TR><TD>canonical_name</TD><TD>TEXT</TD></TR>
        <TR><TD>display_name</TD><TD>TEXT</TD></TR>
        <TR><TD>equipment_category</TD><TD>TEXT</TD></TR>
        <TR><TD>equipment_specific</TD><TD>TEXT</TD></TR>
        <TR><TD>attachment_specific</TD><TD>TEXT</TD></TR>
        <TR><TD>complexity_level</TD><TD>TEXT</TD></TR>
        <TR><TD>primary_muscle</TD><TD>TEXT</TD></TR>
        <TR><TD>secondary_muscle</TD><TD>TEXT</TD></TR>
        <TR><TD BGCOLOR="#E0FFE0">instructions</TD><TD BGCOLOR="#E0FFE0">TEXT (joined)</TD></TR>
        <TR><TD>is_in_programme</TD><TD>INTEGER</TD></TR>
        <TR><TD>canonical_rating</TD><TD>INTEGER</TD></TR>
        <TR><TD>progression_id</TD><TD>TEXT</TD></TR>
        <TR><TD>regression_id</TD><TD>TEXT</TD></TR>
    </TABLE>>'''

    contra_label = '''<<TABLE BORDER="0" CELLBORDER="1" CELLSPACING="0" CELLPADDING="4">
        <TR><TD BGCOLOR="#E6E6FA" COLSPAN="2"><B>exercise_contraindications</B></TD></TR>
        <TR><TD>id</TD><TD>INTEGER PK</TD></TR>
        <TR><TD>canonical_name</TD><TD>TEXT FK</TD></TR>
        <TR><TD>injury_type</TD><TD>TEXT</TD></TR>
    </TABLE>>'''

    videos_label = '''<<TABLE BORDER="0" CELLBORDER="1" CELLSPACING="0" CELLPADDING="4">
        <TR><TD BGCOLOR="#E6E6FA" COLSPAN="2"><B>exercise_videos</B></TD></TR>
        <TR><TD>id</TD><TD>INTEGER PK</TD></TR>
        <TR><TD>exercise_id</TD><TD>TEXT FK</TD></TR>
        <TR><TD>supplier_id</TD><TD>TEXT</TD></TR>
        <TR><TD>media_type</TD><TD>TEXT</TD></TR>
        <TR><TD>filename</TD><TD>TEXT</TD></TR>
        <TR><TD>bunny_url</TD><TD>TEXT</TD></TR>
        <TR><TD>note</TD><TD>TEXT</TD></TR>
    </TABLE>>'''

    dot.node('exercises', exercises_label, shape='none')
    dot.node('contra', contra_label, shape='none')
    dot.node('videos', videos_label, shape='none')

    # Source to join relationships
    dot.edge('csv_exercises', 'join_ex_instr')
    dot.edge('csv_instructions', 'join_ex_instr')
    dot.edge('join_ex_instr', 'exercises')

    # Direct source to table relationships
    dot.edge('csv_contra', 'contra')
    dot.edge('csv_videos', 'videos')

    # Table relationships
    dot.edge('exercises', 'contra', label='canonical_name', style='dashed')
    dot.edge('exercises', 'videos', label='exercise_id', style='dashed')

    return dot

if __name__ == '__main__':
    # Get directory of this script
    script_dir = os.path.dirname(os.path.abspath(__file__))
    flows_dir = os.path.join(script_dir, '..', 'flows')

    # Ensure flows directory exists
    os.makedirs(flows_dir, exist_ok=True)

    # Generate main flowchart
    flowchart = create_flowchart()
    output_path = os.path.join(flows_dir, 'database_generation_flowchart')
    flowchart.render(output_path, format='pdf', cleanup=True)
    print(f"✅ Database Generation Flowchart saved to {output_path}.pdf")

    # Generate schema diagram
    schema = create_schema_diagram()
    schema_path = os.path.join(flows_dir, 'database_schema')
    schema.render(schema_path, format='pdf', cleanup=True)
    print(f"✅ Database Schema saved to {schema_path}.pdf")
