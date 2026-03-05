#!/usr/bin/env python3
"""Generate dashboard_navigation_map.pdf — app navigation from ContentView."""

import subprocess, os

DOT = r"""
digraph dashboard_nav {
    rankdir=TB;
    graph [fontname="Helvetica", fontsize=11, bgcolor="white", pad=0.5, nodesep=0.4, ranksep=0.5];
    node  [fontname="Helvetica", fontsize=10, style=filled, shape=box, color="#333333"];
    edge  [fontname="Helvetica", fontsize=9, color="#666666"];

    // --- App entry ---
    launch [label="LaunchScreenView\n(3.5s splash)", fillcolor="#E8F4FD", shape=ellipse];

    // --- Auth branch ---
    auth_check [label="isAuthenticated?", fillcolor="#FFE0B2", shape=diamond];

    // --- Onboarding ---
    subgraph cluster_onboarding {
        label="Onboarding (unauthenticated)";
        style=rounded; color="#9C27B0"; fontcolor="#9C27B0";

        welcome [label="WelcomeView", fillcolor="#F3E5F5"];
        login [label="LoginView\n(sheet)", fillcolor="#F3E5F5"];
        questionnaire [label="QuestionnaireView\n(14 steps)", fillcolor="#F3E5F5"];
    }

    // --- Main tab bar ---
    subgraph cluster_tabs {
        label="MainTabView (authenticated)";
        style=rounded; color="#2196F3"; fontcolor="#2196F3";

        tab_home [label="Home tab\n(house.fill)", fillcolor="#E8F4FD", shape=tab];
        tab_milestones [label="Milestones tab\n(rosette)", fillcolor="#E8F4FD", shape=tab];
        tab_library [label="Library tab\n(dumbbell.fill)", fillcolor="#E8F4FD", shape=tab];
        tab_account [label="Account tab\n(person.circle.fill)", fillcolor="#E8F4FD", shape=tab];
    }

    // --- Home tab content ---
    subgraph cluster_home {
        label="Home Tab (NavigationStack)";
        style=rounded; color="#FF9800"; fontcolor="#FF9800";

        dashboard [label="DashboardContent\n- TopHeaderView\n- ActiveWorkoutTimerView\n- DashboardCarouselView\n- WeeklySessionsSection", fillcolor="#FFF3E0"];
        workout_overview [label="WorkoutOverviewView\n(exercise cards +\nStart Workout)", fillcolor="#FFF3E0"];
        session_log [label="SessionLogView\n(completed session\nhistory)", fillcolor="#FFF3E0"];
        exercise_demo [label="ExerciseDemoHistoryView\n(video player +\nset history)", fillcolor="#FFF3E0"];
        exercise_logger [label="ExerciseLoggerView\n(active workout\nlogging)", fillcolor="#FFF3E0"];
        workout_summary [label="WorkoutSummaryView\n(post-workout stats)", fillcolor="#FFF3E0"];
        program_overview [label="ProgramOverviewView\n(full programme\ndetail)", fillcolor="#FFF3E0"];
    }

    // --- Library tab ---
    subgraph cluster_library {
        label="Library Tab";
        style=rounded; color="#4CAF50"; fontcolor="#4CAF50";

        combined_library [label="CombinedLibraryView\n(exercise browser +\nmuscle group filter)", fillcolor="#E8F5E9"];
        exercise_detail [label="ExerciseDemoHistoryView\n(video + history)", fillcolor="#E8F5E9"];
    }

    // --- Account tab ---
    subgraph cluster_account {
        label="Account Tab";
        style=rounded; color="#E91E63"; fontcolor="#E91E63";

        profile [label="ProfileView\n(settings, stats,\nlogout)", fillcolor="#FCE4EC"];
        calendar [label="CalendarView\n(workout history\ncalendar)", fillcolor="#FCE4EC"];
    }

    // --- Milestones tab ---
    milestones [label="MilestonesView\n(badges, records,\nachievements)", fillcolor="#E8F4FD"];

    // --- Workout flow modals ---
    subgraph cluster_modals {
        label="Workout Modals";
        style=dashed; color="#9E9E9E"; fontcolor="#9E9E9E";

        swap_carousel [label="ExerciseSwapCarousel\n(alternative exercises\noverlay)", fillcolor="#F5F5F5"];
        rest_timer [label="InlineRestTimer\n(countdown between\nsets)", fillcolor="#F5F5F5"];
    }

    // --- Edges ---
    launch -> auth_check;
    auth_check -> welcome [label="false"];
    auth_check -> tab_home [label="true"];

    welcome -> login [label="Login"];
    welcome -> questionnaire [label="Continue"];
    login -> tab_home [label="success"];
    questionnaire -> tab_home [label="complete"];

    tab_home -> dashboard;
    tab_milestones -> milestones;
    tab_library -> combined_library;
    tab_account -> profile;

    dashboard -> workout_overview [label="Start/Continue\nWorkout"];
    dashboard -> session_log [label="View completed\nsession"];
    dashboard -> exercise_demo [label="Tap exercise\ncard"];
    dashboard -> program_overview [label="View programme"];

    workout_overview -> exercise_logger [label="Start Workout"];
    workout_overview -> exercise_demo [label="Tap exercise"];
    exercise_logger -> workout_summary [label="Complete\nWorkout"];
    exercise_logger -> swap_carousel [label="Swap exercise"];
    exercise_logger -> rest_timer [label="Complete set"];

    combined_library -> exercise_detail [label="Tap exercise"];
    profile -> calendar [label="View history"];
}
"""

def main():
    out_dir = os.path.dirname(os.path.abspath(__file__))
    dot_path = os.path.join(out_dir, "_tmp_dashboard_nav.dot")
    pdf_path = os.path.join(out_dir, "dashboard_navigation_map.pdf")

    with open(dot_path, "w") as f:
        f.write(DOT)

    subprocess.run(["dot", "-Tpdf", dot_path, "-o", pdf_path], check=True)
    os.remove(dot_path)
    print(f"Generated {pdf_path}")


if __name__ == "__main__":
    main()
