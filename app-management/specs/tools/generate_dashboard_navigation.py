#!/usr/bin/env python3
"""
Generate Dashboard Navigation Map (Horizontal Layout)
Shows all navigation paths from the dashboard using GraphViz
"""

from graphviz import Digraph
import os

def create_flowchart():
    # Create directed graph with LEFT-TO-RIGHT layout
    dot = Digraph(comment='Dashboard Navigation Map')
    dot.attr(rankdir='LR', splines='ortho', nodesep='0.5', ranksep='0.8')
    dot.attr('node', fontname='Helvetica', fontsize='10')
    dot.attr('edge', fontname='Helvetica', fontsize='9')

    # Define node styles
    dashboard_style = {'shape': 'box', 'style': 'filled,bold', 'fillcolor': '#90EE90', 'width': '1.5'}
    tab_style = {'shape': 'folder', 'style': 'filled', 'fillcolor': '#87CEEB'}
    screen_style = {'shape': 'box', 'style': 'filled,rounded', 'fillcolor': '#FFF8DC'}
    sheet_style = {'shape': 'note', 'style': 'filled', 'fillcolor': '#E6E6FA'}
    modal_style = {'shape': 'box', 'style': 'filled,rounded', 'fillcolor': '#FFB6C1'}
    action_style = {'shape': 'box', 'style': 'filled,rounded', 'fillcolor': '#FFDAB9'}
    subscreen_style = {'shape': 'box', 'style': 'filled,rounded', 'fillcolor': '#E0FFE0'}

    # === MAIN DASHBOARD ===
    dot.node('dashboard', 'Dashboard\n(Main View)', **dashboard_style)

    # === TAB BAR (MainTabView) ===
    dot.node('tab_home', 'Home Tab\n(Dashboard)', **tab_style)
    dot.node('tab_milestones', 'Milestones\nTab', **tab_style)
    dot.node('tab_library', 'Library\nTab', **tab_style)
    dot.node('tab_account', 'Account\nTab', **tab_style)

    # === DASHBOARD SECTIONS ===
    dot.node('header', 'Top Header\n(Streak + Logo)', **screen_style)
    dot.node('active_timer', 'Active Workout\nTimer', **screen_style)
    dot.node('carousel', 'Carousel\n(Weekly Progress)', **screen_style)
    dot.node('sessions', 'Weekly Sessions\nSection', **screen_style)

    # === FROM DASHBOARD - SESSION FLOWS ===
    dot.node('session_selector', 'Session\nSelector\n(Day Pills)', **screen_style)
    dot.node('workout_overview', 'Workout\nOverview', **screen_style)
    dot.node('session_log', 'Session Log\n(View Completed)', **screen_style)

    # === WORKOUT FLOW ===
    dot.node('exercise_logger', 'Exercise\nLogger', **action_style)
    dot.node('set_logging', 'Set Logging\n(Weight/Reps)', **action_style)
    dot.node('rest_timer', 'Rest Timer\nModal', **modal_style)
    dot.node('workout_complete', 'Workout\nCompletion', **modal_style)

    # === EXERCISE DETAIL ===
    dot.node('exercise_demo', 'Exercise Demo\n& History View', **screen_style)
    dot.node('video_player', 'Video Player', **subscreen_style)
    dot.node('exercise_history', 'Exercise\nHistory', **subscreen_style)
    dot.node('progression', 'Progression/\nRegression', **subscreen_style)

    # === SHEET VIEWS ===
    dot.node('milestones_view', 'Milestones\nView', **sheet_style)
    dot.node('library_view', 'Combined\nLibrary View', **sheet_style)
    dot.node('profile_view', 'Profile\nView', **sheet_style)

    # === LIBRARY SUB-VIEWS ===
    dot.node('exercise_library', 'Exercise\nLibrary', **subscreen_style)
    dot.node('muscle_filter', 'Muscle\nFilter', **subscreen_style)
    dot.node('equipment_filter', 'Equipment\nFilter', **subscreen_style)

    # === PROFILE SUB-VIEWS ===
    dot.node('edit_profile', 'Edit Profile', **subscreen_style)
    dot.node('settings', 'Settings', **subscreen_style)
    dot.node('logout', 'Logout', **modal_style)
    dot.node('retake_quiz', 'Retake Quiz', **modal_style)

    # === PROGRAM OVERVIEW ===
    dot.node('program_overview', 'Program\nOverview', **screen_style)

    # === EDGES ===

    # Dashboard contains sections
    dot.edge('dashboard', 'header', style='dashed', label='contains')
    dot.edge('dashboard', 'active_timer', style='dashed')
    dot.edge('dashboard', 'carousel', style='dashed')
    dot.edge('dashboard', 'sessions', style='dashed')

    # Tab navigation (from dashboard)
    dot.edge('dashboard', 'tab_home', label='stays on')
    dot.edge('dashboard', 'tab_milestones', label='opens sheet')
    dot.edge('dashboard', 'tab_library', label='opens sheet')
    dot.edge('dashboard', 'tab_account', label='opens sheet')

    # Tab destinations
    dot.edge('tab_milestones', 'milestones_view')
    dot.edge('tab_library', 'library_view')
    dot.edge('tab_account', 'profile_view')

    # Session flow
    dot.edge('sessions', 'session_selector')
    dot.edge('session_selector', 'workout_overview', label='Start Workout')
    dot.edge('session_selector', 'session_log', label='View Completed')

    # Workout flow
    dot.edge('workout_overview', 'exercise_logger', label='Start Exercise')
    dot.edge('exercise_logger', 'set_logging')
    dot.edge('set_logging', 'rest_timer', label='Complete Set')
    dot.edge('rest_timer', 'set_logging', label='Next Set')
    dot.edge('exercise_logger', 'workout_complete', label='All Exercises Done')
    dot.edge('workout_complete', 'dashboard', label='Finish')

    # Exercise detail navigation
    dot.edge('workout_overview', 'exercise_demo', label='Tap Exercise')
    dot.edge('exercise_demo', 'video_player')
    dot.edge('exercise_demo', 'exercise_history')
    dot.edge('exercise_demo', 'progression')

    # Library sub-navigation
    dot.edge('library_view', 'exercise_library')
    dot.edge('exercise_library', 'muscle_filter')
    dot.edge('exercise_library', 'equipment_filter')
    dot.edge('exercise_library', 'exercise_demo', label='Select Exercise')

    # Profile sub-navigation
    dot.edge('profile_view', 'edit_profile')
    dot.edge('profile_view', 'settings')
    dot.edge('profile_view', 'logout')
    dot.edge('profile_view', 'retake_quiz')

    # Carousel to program overview
    dot.edge('carousel', 'program_overview', label='Tap')

    # Active timer continuation
    dot.edge('active_timer', 'workout_overview', label='Continue')

    return dot

if __name__ == '__main__':
    flowchart = create_flowchart()

    # Get directory of this script
    script_dir = os.path.dirname(os.path.abspath(__file__))
    flows_dir = os.path.join(script_dir, '..', 'flows')

    # Ensure flows directory exists
    os.makedirs(flows_dir, exist_ok=True)

    output_path = os.path.join(flows_dir, 'dashboard_navigation_map')
    flowchart.render(output_path, format='pdf', cleanup=True)

    print(f"✅ Dashboard Navigation Map saved to {output_path}.pdf")
