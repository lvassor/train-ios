#!/usr/bin/env python3
"""
Generate Programme Generation Flowchart (Horizontal Layout)
Uses UML-style shapes: diamonds for decisions, rectangles for actions
Left-to-right layout for better horizontal viewing
"""

from graphviz import Digraph
import os

def create_flowchart():
    # Create directed graph with LEFT-TO-RIGHT layout
    dot = Digraph(comment='Programme Generation Flowchart')
    dot.attr(rankdir='LR', splines='ortho', nodesep='0.4', ranksep='0.8')
    dot.attr('node', fontname='Helvetica', fontsize='10')
    dot.attr('edge', fontname='Helvetica', fontsize='9')

    # Define node styles
    start_style = {'shape': 'oval', 'style': 'filled', 'fillcolor': '#90EE90'}
    end_style = {'shape': 'oval', 'style': 'filled', 'fillcolor': '#FFB6C1'}
    process_style = {'shape': 'box', 'style': 'filled', 'fillcolor': '#87CEEB'}
    decision_style = {'shape': 'diamond', 'style': 'filled', 'fillcolor': '#FFD700', 'width': '1.5', 'height': '1'}
    data_style = {'shape': 'parallelogram', 'style': 'filled', 'fillcolor': '#DDA0DD'}
    subprocess_style = {'shape': 'box3d', 'style': 'filled', 'fillcolor': '#98FB98'}

    # === BASELINE SETUP ===
    dot.node('start', 'START', **start_style)

    dot.node('input1', 'User Questionnaire\nEquipment, Attachments\nExperience Level', **data_style)

    dot.node('input2', 'User Preferences\nDays/Week, Duration\nPriority Muscles', **data_style)

    dot.node('build_pool', 'Build Baseline Pool\nFilter by Equipment\n+ Attachments\n+ Complexity', **process_style)

    dot.node('get_templates', 'Get Split Templates\nBased on Days/\nDuration/Priorities', **process_style)

    dot.node('assess', 'PHASE 0:\nInitial Assessment\nCount slots/muscle\nIdentify shortfalls', **subprocess_style)

    # === PHASE 1: NORMAL FILL ===
    dot.node('phase1', 'PHASE 1:\nMCV Algorithm\nFill Normal\nConstraints', **subprocess_style)

    dot.node('check1', 'All slots\nfilled?', **decision_style)

    # === PHASE 2: PRIORITY DECREMENT ===
    dot.node('check_priority', 'Unfilled\nis priority?', **decision_style)

    dot.node('phase2', 'PHASE 2:\nDecrement Priority\nMuscle Slots', **process_style)

    dot.node('retry2', 'Retry\nMCV Fill', **process_style)

    dot.node('check2', 'Filled?', **decision_style)

    # === PHASE 3: COMPLEXITY RELAXATION ===
    dot.node('phase3', 'PHASE 3:\nRelax Complexity\nper-slot', **process_style)

    dot.node('retry3', 'Retry\nFill', **process_style)

    dot.node('check3', 'Filled?', **decision_style)

    # === PHASE 4: CANONICAL RELAXATION ===
    dot.node('phase4', 'PHASE 4:\nAllow Canonical\nRepeats', **process_style)

    dot.node('retry4', 'Retry\nFill', **process_style)

    dot.node('check4', 'Filled?', **decision_style)

    # === PHASE 5: MUSCLE REASSIGNMENT ===
    dot.node('phase5', 'PHASE 5:\nReassign to\nAlt Muscle', **process_style)

    dot.node('fill5', 'Fill with\nAlternative', **process_style)

    # === WARNING & END ===
    dot.node('check_relaxed', 'Constraint\nrelaxed?', **decision_style)

    dot.node('add_warning', 'Add Warning\nMessage', **process_style)

    dot.node('next_slot', 'Next\nUnfilled\nSlot', **process_style)

    dot.node('more_slots', 'More\nslots?', **decision_style)

    dot.node('assign_sets', 'Assign Sets/\nReps/Rest\n(Goal-based)', **process_style)

    dot.node('output', 'Programme\n+ Warnings', **data_style)

    dot.node('end', 'END', **end_style)

    # === EDGES ===
    # Use subgraphs to control ranking/positioning
    with dot.subgraph() as s:
        s.attr(rank='same')
        s.node('input1')
        s.node('input2')

    # Baseline setup flow
    dot.edge('start', 'input1')
    dot.edge('start', 'input2')
    dot.edge('input1', 'build_pool')
    dot.edge('input2', 'get_templates')
    dot.edge('build_pool', 'assess')
    dot.edge('get_templates', 'assess')
    dot.edge('assess', 'phase1')

    # Phase 1 flow
    dot.edge('phase1', 'check1')
    dot.edge('check1', 'check_relaxed', label='Yes')
    dot.edge('check1', 'check_priority', label='No')

    # Phase 2 flow
    dot.edge('check_priority', 'phase2', label='Yes')
    dot.edge('phase2', 'retry2')
    dot.edge('retry2', 'check2')
    dot.edge('check2', 'next_slot', label='Yes')
    dot.edge('check2', 'phase3', label='No')

    # Non-priority goes straight to Phase 3
    dot.edge('check_priority', 'phase3', label='No')

    # Phase 3 flow
    dot.edge('phase3', 'retry3')
    dot.edge('retry3', 'check3')
    dot.edge('check3', 'next_slot', label='Yes')
    dot.edge('check3', 'phase4', label='No')

    # Phase 4 flow
    dot.edge('phase4', 'retry4')
    dot.edge('retry4', 'check4')
    dot.edge('check4', 'next_slot', label='Yes')
    dot.edge('check4', 'phase5', label='No')

    # Phase 5 flow
    dot.edge('phase5', 'fill5')
    dot.edge('fill5', 'next_slot')

    # Loop back for more slots
    dot.edge('next_slot', 'more_slots')
    dot.edge('more_slots', 'check_priority', label='Yes')
    dot.edge('more_slots', 'check_relaxed', label='No')

    # Warning and end
    dot.edge('check_relaxed', 'add_warning', label='Yes')
    dot.edge('check_relaxed', 'assign_sets', label='No')
    dot.edge('add_warning', 'assign_sets')
    dot.edge('assign_sets', 'output')
    dot.edge('output', 'end')

    return dot

if __name__ == '__main__':
    flowchart = create_flowchart()

    # Get directory of this script
    script_dir = os.path.dirname(os.path.abspath(__file__))
    flows_dir = os.path.join(script_dir, '..', 'flows')

    # Ensure flows directory exists
    os.makedirs(flows_dir, exist_ok=True)

    output_path = os.path.join(flows_dir, 'program_generation_flowchart')
    flowchart.render(output_path, format='pdf', cleanup=True)

    print(f"✅ Programme Generation Flowchart saved to {output_path}.pdf")
