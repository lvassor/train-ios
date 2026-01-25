#!/usr/bin/env python3
"""
Generate Questionnaire Flow Flowchart (Horizontal Layout)
Shows the complete onboarding flow from welcome to dashboard
"""

from graphviz import Digraph
import os

def create_flowchart():
    # Create directed graph with LEFT-TO-RIGHT layout
    dot = Digraph(comment='Questionnaire Flow')
    dot.attr(rankdir='LR', splines='ortho', nodesep='0.4', ranksep='0.6')
    dot.attr('node', fontname='Helvetica', fontsize='10')
    dot.attr('edge', fontname='Helvetica', fontsize='9')

    # Define node styles
    start_style = {'shape': 'oval', 'style': 'filled', 'fillcolor': '#90EE90'}
    end_style = {'shape': 'oval', 'style': 'filled', 'fillcolor': '#FFB6C1'}
    screen_style = {'shape': 'box', 'style': 'filled,rounded', 'fillcolor': '#87CEEB'}
    conditional_style = {'shape': 'box', 'style': 'filled,rounded', 'fillcolor': '#E0FFE0'}
    decision_style = {'shape': 'diamond', 'style': 'filled', 'fillcolor': '#FFD700', 'width': '1.3'}
    interstitial_style = {'shape': 'box', 'style': 'filled,rounded', 'fillcolor': '#FFB347'}
    special_style = {'shape': 'box', 'style': 'filled,rounded', 'fillcolor': '#DDA0DD'}
    data_style = {'shape': 'parallelogram', 'style': 'filled', 'fillcolor': '#E6E6FA'}

    # === APP LAUNCH ===
    dot.node('start', 'App\nLaunch', **start_style)
    dot.node('check_user', 'Existing\nUser?', **decision_style)

    # === ONBOARDING SCREENS ===
    dot.node('s1_welcome', '1. Welcome\n(App Preview)', **screen_style)
    dot.node('s2_goal', '2. Goal\nSelection', **screen_style)
    dot.node('s3_name', '3. Name\n"What should\nwe call you?"', **screen_style)
    dot.node('s4_body', '4. Body Stats\n(HealthKit or\nManual)', **screen_style)

    # Conditional screen
    dot.node('check_health', 'HealthKit\nhas H/W?', **decision_style)
    dot.node('s5_hw', '5. Height/Weight\n(Manual Entry)', **conditional_style)

    dot.node('s6_exp', '6. Experience\n(4 levels)', **screen_style)

    # First interstitial
    dot.node('i1', '[Interstitial]\nPersonal Training\nValue Prop', **interstitial_style)

    dot.node('s8_freq', '8. Training\nFrequency', **screen_style)
    dot.node('s9_split', '9. Training\nSplit Choice', **screen_style)
    dot.node('s10_dur', '10. Session\nDuration', **screen_style)

    # Training Place (gym type) - pre-populates equipment
    dot.node('s11_place', '11. Training Place\n(Gym Type)\nPre-selects equipment', **screen_style)
    dot.node('s12_equip', '12. Equipment\nAvailability\n(Expandable Cards)', **screen_style)

    # Second interstitial
    dot.node('i2', '[Interstitial]\nPerfect Workout\nMessage', **interstitial_style)

    dot.node('s14_muscle', '14. Muscle\nPriority\n(Optional, ≤3)', **screen_style)
    dot.node('s15_injury', '15. Injuries\n(Optional)', **screen_style)

    # Loading & Generation
    dot.node('s16_loading', '16. Loading\n"Building Your\nProgram"', **special_style)
    dot.node('generate', 'DynamicProgram\nGenerator', **data_style)

    dot.node('s17_ready', '17. Program\nReady! 🎉', **special_style)

    # Auth & Final
    dot.node('s18_signup', '18. Signup\n(Apple/Google/\nEmail)', **screen_style)
    dot.node('s19_notif', '19. Notifications\nPermission', **screen_style)
    dot.node('s20_ref', '20. Referral\n(Optional)', **screen_style)

    # === DASHBOARD ===
    dot.node('dashboard', 'Dashboard', **end_style)

    # === EDGES ===

    # App launch flow
    dot.edge('start', 'check_user')
    dot.edge('check_user', 'dashboard', label='Yes')
    dot.edge('check_user', 's1_welcome', label='No')

    # Main onboarding flow
    dot.edge('s1_welcome', 's2_goal')
    dot.edge('s2_goal', 's3_name')
    dot.edge('s3_name', 's4_body')
    dot.edge('s4_body', 'check_health')

    # Conditional height/weight
    dot.edge('check_health', 's6_exp', label='Yes')
    dot.edge('check_health', 's5_hw', label='No')
    dot.edge('s5_hw', 's6_exp')

    # Experience to interstitial
    dot.edge('s6_exp', 'i1')
    dot.edge('i1', 's8_freq')

    # Training preferences
    dot.edge('s8_freq', 's9_split')
    dot.edge('s9_split', 's10_dur')
    dot.edge('s10_dur', 's11_place')
    dot.edge('s11_place', 's12_equip', label='Pre-populates')
    dot.edge('s12_equip', 'i2')

    # Second section
    dot.edge('i2', 's14_muscle')
    dot.edge('s14_muscle', 's15_injury')

    # Program generation
    dot.edge('s15_injury', 's16_loading')
    dot.edge('s16_loading', 'generate')
    dot.edge('generate', 's17_ready')

    # Final steps
    dot.edge('s17_ready', 's18_signup')
    dot.edge('s18_signup', 's19_notif')
    dot.edge('s19_notif', 's20_ref')
    dot.edge('s20_ref', 'dashboard')

    return dot

if __name__ == '__main__':
    flowchart = create_flowchart()

    # Get directory of this script
    script_dir = os.path.dirname(os.path.abspath(__file__))
    flows_dir = os.path.join(script_dir, '..', 'flows')

    # Ensure flows directory exists
    os.makedirs(flows_dir, exist_ok=True)

    output_path = os.path.join(flows_dir, 'questionnaire_flowchart')
    flowchart.render(output_path, format='pdf', cleanup=True)

    print(f"✅ Questionnaire Flow saved to {output_path}.pdf")
