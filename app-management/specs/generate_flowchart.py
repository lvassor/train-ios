#!/usr/bin/env python3
"""
Generate Programme Generation Flowchart with Fallback Logic
Uses UML-style shapes: diamonds for decisions, rectangles for actions
"""

from graphviz import Digraph

def create_flowchart():
    # Create directed graph with top-to-bottom layout
    dot = Digraph(comment='Programme Generation Flowchart')
    dot.attr(rankdir='TB', splines='ortho', nodesep='0.5', ranksep='0.7')
    dot.attr('node', fontname='Helvetica', fontsize='10')
    dot.attr('edge', fontname='Helvetica', fontsize='9')

    # Define node styles
    # Start/End: rounded rectangle (oval)
    start_style = {'shape': 'oval', 'style': 'filled', 'fillcolor': '#90EE90'}
    end_style = {'shape': 'oval', 'style': 'filled', 'fillcolor': '#FFB6C1'}

    # Process: rectangle
    process_style = {'shape': 'box', 'style': 'filled', 'fillcolor': '#87CEEB'}

    # Decision: diamond
    decision_style = {'shape': 'diamond', 'style': 'filled', 'fillcolor': '#FFD700', 'width': '2', 'height': '1'}

    # Data/Input: parallelogram
    data_style = {'shape': 'parallelogram', 'style': 'filled', 'fillcolor': '#DDA0DD'}

    # Subprocess: rectangle with double lines (using box3d as approximation)
    subprocess_style = {'shape': 'box3d', 'style': 'filled', 'fillcolor': '#98FB98'}

    # === BASELINE SETUP ===
    dot.node('start', 'START', **start_style)

    dot.node('input1', 'User Questionnaire Data:\nEquipment, Attachments,\nExperience Level', **data_style)

    dot.node('input2', 'User Preferences:\nDays/Week, Session Duration,\nPriority Muscles', **data_style)

    dot.node('build_pool', 'Build Baseline Exercise Pool\n(Filter by Equipment +\nAttachments + Complexity)', **process_style)

    dot.node('get_templates', 'Get Split Templates\n(Based on Days/Duration/\nPriority Muscles)', **process_style)

    dot.node('assess', 'PHASE 0: Initial Assessment\nCount slots per muscle\nCount candidates per muscle\nIdentify shortfalls', **subprocess_style)

    # === PHASE 1: NORMAL FILL ===
    dot.node('phase1', 'PHASE 1: Fill with\nNormal Constraints\n(MCV Algorithm)', **subprocess_style)

    dot.node('check1', 'All slots\nfilled?', **decision_style)

    # === PHASE 2: PRIORITY DECREMENT ===
    dot.node('check_priority', 'Unfilled muscle\nis priority?', **decision_style)

    dot.node('phase2', 'PHASE 2: Decrement\nPriority Muscle Slots\n(by shortfall amount)', **process_style)

    dot.node('retry2', 'Retry MCV Fill', **process_style)

    dot.node('check2', 'Slot filled?', **decision_style)

    # === PHASE 3: COMPLEXITY RELAXATION ===
    dot.node('phase3', 'PHASE 3: Relax Complexity\n(per-slot)\nBeg: all,1 → all,1,2\nInt/Adv: all,2 → all,1,2', **process_style)

    dot.node('retry3', 'Retry Fill\n(this slot only)', **process_style)

    dot.node('check3', 'Slot filled?', **decision_style)

    # === PHASE 4: CANONICAL RELAXATION ===
    dot.node('phase4', 'PHASE 4: Allow Canonical\nRepeats Across Programme\n(per-slot)', **process_style)

    dot.node('retry4', 'Retry Fill\n(this slot only)', **process_style)

    dot.node('check4', 'Slot filled?', **decision_style)

    # === PHASE 5: MUSCLE REASSIGNMENT ===
    dot.node('phase5', 'PHASE 5: Reassign Slot\nto Alternative Muscle\n(same session, has excess)', **process_style)

    dot.node('fill5', 'Fill with Alternative\nMuscle Exercise', **process_style)

    # === WARNING & END ===
    dot.node('check_relaxed', 'Any soft\nconstraint\nrelaxed?', **decision_style)

    dot.node('add_warning', 'Add Warning:\n"We\'ve adjusted a few\nrules to create the best\nprogramme for you"', **process_style)

    dot.node('next_slot', 'Move to\nNext Unfilled Slot', **process_style)

    dot.node('more_slots', 'More unfilled\nslots?', **decision_style)

    dot.node('output', 'Output:\nGenerated Programme\n+ Warnings', **data_style)

    dot.node('end', 'END', **end_style)

    # === EDGES ===
    # Baseline setup flow
    dot.edge('start', 'input1')
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
    dot.edge('check_relaxed', 'output', label='No')
    dot.edge('add_warning', 'output')
    dot.edge('output', 'end')

    return dot

if __name__ == '__main__':
    flowchart = create_flowchart()

    # Save as PDF
    output_path = '/Users/lukevassor/Documents/trAIn-ios/app-management/specs/fallback_flowchart'
    flowchart.render(output_path, format='pdf', cleanup=True)

    print(f"✅ Flowchart saved to {output_path}.pdf")
