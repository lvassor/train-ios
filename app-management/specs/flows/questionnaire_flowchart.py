#!/usr/bin/env python3
"""Generate questionnaire_flowchart.pdf — 14-step onboarding questionnaire."""

import subprocess, os

DOT = r"""
digraph questionnaire {
    rankdir=TB;
    graph [fontname="Helvetica", fontsize=11, bgcolor="white", pad=0.5, nodesep=0.3, ranksep=0.45];
    node  [fontname="Helvetica", fontsize=10, style=filled, shape=box, color="#333333"];
    edge  [fontname="Helvetica", fontsize=9, color="#666666"];

    // --- Welcome ---
    welcome [label="WelcomeView\n(logo + Get Started)", fillcolor="#E8F4FD", shape=ellipse];

    // --- Steps ---
    subgraph cluster_steps {
        label="QuestionnaireView (14 steps, 0-indexed)";
        style=rounded; color="#9C27B0"; fontcolor="#9C27B0";

        s0 [label="Step 0: GoalsStepView\nprimaryGoals: [String]\nget_stronger / build_muscle / tone_up", fillcolor="#F3E5F5"];
        s1 [label="Step 1: NameStepView\nname: String", fillcolor="#F3E5F5"];
        s2 [label="Step 2: HealthProfileStepView\ngender, dateOfBirth\n+ optional HealthKit sync", fillcolor="#F3E5F5"];

        // Branch point
        branch [label="HealthKit provided\nheight/weight?", fillcolor="#FFE0B2", shape=diamond];

        s3a [label="Step 3: HeightWeightStepView\nheightCm/Ft/In, weightKg/Lbs\nskipHeightWeight = false", fillcolor="#FFF3E0"];
        s4a [label="Step 4: ExperienceStepView", fillcolor="#F3E5F5"];
        s5a [label="Step 5: VideoInterstitialView 1\n(full-screen video)", fillcolor="#E8F5E9"];
        s6a [label="Step 6: TrainingDaysStepView\ntrainingDaysPerWeek: 1-6", fillcolor="#F3E5F5"];
        s7a [label="Step 7: SplitSelectionStepView\nselectedSplit (from split_templates.json)", fillcolor="#F3E5F5"];
        s8a [label="Step 8: SessionDurationStepView\n30-45 / 45-60 / 60-90 min", fillcolor="#F3E5F5"];
        s9a [label="Step 9: TrainingPlaceStepView\nlarge_gym / small_gym / garage_gym\n-> applyGymTypePreset()", fillcolor="#F3E5F5"];
        s10a [label="Step 10: EquipmentStepView\ncategories + specific items\n+ cable attachments", fillcolor="#F3E5F5"];
        s11a [label="Step 11: VideoInterstitialView 2\n(full-screen video)", fillcolor="#E8F5E9"];
        s12a [label="Step 12: MuscleGroupsStepView\ntargetMuscleGroups (up to 3)", fillcolor="#F3E5F5"];
        s13a [label="Step 13: InjuriesStepView\ninjuries: [String]", fillcolor="#F3E5F5"];

        // Skip path labels (same steps but shifted by 1)
        s3b [label="Step 3: ExperienceStepView\nskipHeightWeight = true", fillcolor="#FFF3E0"];
    }

    // --- Post-questionnaire ---
    subgraph cluster_post {
        label="Post-Questionnaire";
        style=rounded; color="#4CAF50"; fontcolor="#4CAF50";

        loading [label="ProgramLoadingView\n(generateProgram())", fillcolor="#E8F5E9"];
        ready [label="ProgramReadyView\n(preview sessions)", fillcolor="#E8F5E9"];
        signup [label="PostQuestionnaireSignupView\n(email/Apple/Google)", fillcolor="#E8F5E9"];
        dashboard [label="DashboardView", fillcolor="#C8E6C9", shape=doubleoctagon];
    }

    // --- Equipment warning ---
    equip_warn [label="Equipment Warning Alert\n(if <= 2 categories selected)\nAdd More / Continue Anyway", fillcolor="#FFCDD2", shape=note];

    // --- Edges ---
    welcome -> s0;
    s0 -> s1 -> s2 -> branch;

    // Normal path (no HealthKit height/weight)
    branch -> s3a [label="No"];
    s3a -> s4a -> s5a -> s6a -> s7a -> s8a -> s9a -> s10a -> s11a -> s12a -> s13a;

    // Skip path (HealthKit provided height/weight)
    branch -> s3b [label="Yes"];
    s3b -> s5a [style=dashed, label="steps shift\nby -1"];

    // Equipment warning branch
    s10a -> equip_warn [style=dotted, label="<= 2 categories"];
    equip_warn -> s10a [style=dotted, label="Add More"];
    equip_warn -> s11a [style=dotted, label="Continue"];

    // Post flow
    s13a -> loading;
    loading -> ready;
    ready -> signup;
    signup -> dashboard;
}
"""

def main():
    out_dir = os.path.dirname(os.path.abspath(__file__))
    dot_path = os.path.join(out_dir, "_tmp_questionnaire.dot")
    pdf_path = os.path.join(out_dir, "questionnaire_flowchart.pdf")

    with open(dot_path, "w") as f:
        f.write(DOT)

    subprocess.run(["dot", "-Tpdf", dot_path, "-o", pdf_path], check=True)
    os.remove(dot_path)
    print(f"Generated {pdf_path}")


if __name__ == "__main__":
    main()
