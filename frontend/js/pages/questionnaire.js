/**
 * trAIn Questionnaire App - Complete JavaScript Application
 * 
 * This application handles the multi-step questionnaire process for generating
 * personalized training programs. It includes:
 * - Multi-step form navigation
 * - Form validation and data collection
 * - Program generation based on user responses
 * - Loading animations and user feedback
 * - API integration for data submission
 * 
 * Flow: Email Capture -> Questionnaire -> Loading -> Success Page -> Account Creation CTA
 * 
 * @author trAIn Team
 * @version 2.0
 */

// ============================================================================
// PROGRAM TEMPLATES - Pre-defined workout programs based on experience/frequency
// ============================================================================

/**
 * Program templates used for generating personalized workout plans.
 * Each template includes:
 * - Target experience levels
 * - Training frequency options
 * - Duration in weeks
 * - Structured workouts with exercises, sets, reps, and guidance
 */
const PROGRAM_TEMPLATES = {
  "programs": [
    {
      "id": "beginner_2_day",
      "name": "Beginner Full Body Foundation",
      "target_experience": ["0_months", "0_6_months"],
      "frequency": [2],
      "duration_weeks": 8,
      "description": "A simple 2-day full body routine focusing on fundamental movement patterns",
      "workouts": [
        {
          "name": "Full Body A",
          "exercises": [
            { "name": "Bodyweight Squat", "sets": 3, "reps": "10-12", "rest": "60-90 seconds", "notes": "Focus on proper form and full range of motion" },
            { "name": "Push-up (Modified if needed)", "sets": 3, "reps": "5-10", "rest": "60-90 seconds", "notes": "Use knee push-ups if needed" },
            { "name": "Bent Over Row (Bodyweight)", "sets": 3, "reps": "8-12", "rest": "60-90 seconds", "notes": "Use table or bar for support" },
            { "name": "Glute Bridge", "sets": 3, "reps": "12-15", "rest": "45-60 seconds", "notes": "Squeeze glutes at the top" },
            { "name": "Plank", "sets": 3, "reps": "20-30 seconds", "rest": "45-60 seconds", "notes": "Maintain straight line from head to heels" }
          ]
        },
        {
          "name": "Full Body B",
          "exercises": [
            { "name": "Wall Sit", "sets": 3, "reps": "20-30 seconds", "rest": "60-90 seconds", "notes": "Keep back flat against wall" },
            { "name": "Pike Push-up", "sets": 3, "reps": "5-8", "rest": "60-90 seconds", "notes": "Targets shoulders, modify angle as needed" },
            { "name": "Superman", "sets": 3, "reps": "10-12", "rest": "45-60 seconds", "notes": "Lift chest and legs simultaneously" },
            { "name": "Reverse Lunge", "sets": 3, "reps": "8-10 each leg", "rest": "60-90 seconds", "notes": "Step back, keep front knee over ankle" },
            { "name": "Dead Bug", "sets": 3, "reps": "8-10 each side", "rest": "45-60 seconds", "notes": "Keep lower back pressed to floor" }
          ]
        }
      ]
    },
    {
      "id": "beginner_3_day",
      "name": "Beginner Full Body Builder",
      "target_experience": ["0_6_months", "6_months_2_years"],
      "frequency": [3],
      "duration_weeks": 8,
      "description": "A 3-day full body routine with progressive overload",
      "workouts": [
        {
          "name": "Full Body A",
          "exercises": [
            { "name": "Goblet Squat", "sets": 3, "reps": "10-12", "rest": "90 seconds", "notes": "Hold weight close to chest" },
            { "name": "Push-up", "sets": 3, "reps": "8-12", "rest": "90 seconds", "notes": "Full range of motion" },
            { "name": "Bent Over Row", "sets": 3, "reps": "10-12", "rest": "90 seconds", "notes": "Squeeze shoulder blades together" },
            { "name": "Romanian Deadlift", "sets": 3, "reps": "10-12", "rest": "90 seconds", "notes": "Keep bar close to body" },
            { "name": "Plank", "sets": 3, "reps": "30-45 seconds", "rest": "60 seconds", "notes": "Progress by adding time" }
          ]
        },
        {
          "name": "Full Body B",
          "exercises": [
            { "name": "Reverse Lunge", "sets": 3, "reps": "10-12 each leg", "rest": "90 seconds", "notes": "Control the descent" },
            { "name": "Overhead Press", "sets": 3, "reps": "8-10", "rest": "90 seconds", "notes": "Keep core tight" },
            { "name": "Lat Pulldown", "sets": 3, "reps": "10-12", "rest": "90 seconds", "notes": "Pull to upper chest" },
            { "name": "Hip Thrust", "sets": 3, "reps": "12-15", "rest": "90 seconds", "notes": "Drive through heels" },
            { "name": "Side Plank", "sets": 2, "reps": "20-30 seconds each side", "rest": "60 seconds", "notes": "Keep body in straight line" }
          ]
        },
        {
          "name": "Full Body C",
          "exercises": [
            { "name": "Step-up", "sets": 3, "reps": "10-12 each leg", "rest": "90 seconds", "notes": "Use full foot on platform" },
            { "name": "Incline Push-up", "sets": 3, "reps": "10-15", "rest": "90 seconds", "notes": "Hands elevated on bench/step" },
            { "name": "Seated Row", "sets": 3, "reps": "10-12", "rest": "90 seconds", "notes": "Pull elbows back" },
            { "name": "Glute Bridge", "sets": 3, "reps": "15-20", "rest": "90 seconds", "notes": "Pause at top" },
            { "name": "Mountain Climbers", "sets": 3, "reps": "20-30 total", "rest": "60 seconds", "notes": "Keep hips level" }
          ]
        }
      ]
    },
    {
      "id": "beginner_4_day",
      "name": "Beginner Upper/Lower Split",
      "target_experience": ["6_months_2_years"],
      "frequency": [4],
      "duration_weeks": 8,
      "description": "A 4-day upper/lower split for building strength and muscle",
      "workouts": [
        {
          "name": "Upper Body A",
          "exercises": [
            { "name": "Bench Press", "sets": 4, "reps": "8-10", "rest": "2-3 minutes", "notes": "Control the weight, full range of motion" },
            { "name": "Bent Over Row", "sets": 4, "reps": "8-10", "rest": "2-3 minutes", "notes": "Keep back straight" },
            { "name": "Overhead Press", "sets": 3, "reps": "8-10", "rest": "2 minutes", "notes": "Press straight up" },
            { "name": "Lat Pulldown", "sets": 3, "reps": "10-12", "rest": "2 minutes", "notes": "Lean back slightly" },
            { "name": "Dumbbell Curl", "sets": 3, "reps": "10-12", "rest": "90 seconds", "notes": "Control the negative" }
          ]
        },
        {
          "name": "Lower Body A",
          "exercises": [
            { "name": "Squat", "sets": 4, "reps": "8-10", "rest": "2-3 minutes", "notes": "Depth to parallel or below" },
            { "name": "Romanian Deadlift", "sets": 4, "reps": "8-10", "rest": "2-3 minutes", "notes": "Feel stretch in hamstrings" },
            { "name": "Bulgarian Split Squat", "sets": 3, "reps": "10-12 each leg", "rest": "2 minutes", "notes": "Most weight on front leg" },
            { "name": "Leg Curl", "sets": 3, "reps": "12-15", "rest": "90 seconds", "notes": "Squeeze at the top" },
            { "name": "Calf Raise", "sets": 3, "reps": "15-20", "rest": "60 seconds", "notes": "Full range of motion" }
          ]
        },
        {
          "name": "Upper Body B",
          "exercises": [
            { "name": "Incline Dumbbell Press", "sets": 4, "reps": "8-10", "rest": "2-3 minutes", "notes": "45-degree incline" },
            { "name": "Seated Cable Row", "sets": 4, "reps": "8-10", "rest": "2-3 minutes", "notes": "Pull to lower chest" },
            { "name": "Dumbbell Shoulder Press", "sets": 3, "reps": "10-12", "rest": "2 minutes", "notes": "Full range of motion" },
            { "name": "Pull-up/Assisted Pull-up", "sets": 3, "reps": "5-8", "rest": "2 minutes", "notes": "Use assistance if needed" },
            { "name": "Tricep Dip", "sets": 3, "reps": "8-12", "rest": "90 seconds", "notes": "Keep body upright" }
          ]
        },
        {
          "name": "Lower Body B",
          "exercises": [
            { "name": "Leg Press", "sets": 4, "reps": "10-12", "rest": "2-3 minutes", "notes": "Feet shoulder-width apart" },
            { "name": "Stiff Leg Deadlift", "sets": 4, "reps": "10-12", "rest": "2-3 minutes", "notes": "Keep legs relatively straight" },
            { "name": "Walking Lunge", "sets": 3, "reps": "12-15 each leg", "rest": "2 minutes", "notes": "Step far enough forward" },
            { "name": "Leg Extension", "sets": 3, "reps": "12-15", "rest": "90 seconds", "notes": "Pause at the top" },
            { "name": "Seated Calf Raise", "sets": 3, "reps": "15-20", "rest": "60 seconds", "notes": "Hold the stretch at bottom" }
          ]
        }
      ]
    },
    {
      "id": "advanced_2_day",
      "name": "Advanced Full Body Power",
      "target_experience": ["2_plus_years"],
      "frequency": [2],
      "duration_weeks": 8,
      "description": "High-intensity 2-day full body routine for experienced lifters",
      "workouts": [
        {
          "name": "Power Day A",
          "exercises": [
            { "name": "Squat", "sets": 5, "reps": "3-5", "rest": "3-4 minutes", "notes": "Heavy weight, focus on power" },
            { "name": "Bench Press", "sets": 5, "reps": "3-5", "rest": "3-4 minutes", "notes": "Explosive concentric" },
            { "name": "Bent Over Row", "sets": 4, "reps": "5-6", "rest": "3 minutes", "notes": "Heavy, strict form" },
            { "name": "Deadlift", "sets": 4, "reps": "3-5", "rest": "3-4 minutes", "notes": "Focus on hip drive" },
            { "name": "Weighted Plank", "sets": 3, "reps": "30-45 seconds", "rest": "2 minutes", "notes": "Add weight as able" }
          ]
        },
        {
          "name": "Power Day B",
          "exercises": [
            { "name": "Front Squat", "sets": 5, "reps": "4-6", "rest": "3-4 minutes", "notes": "Upright torso, explosive up" },
            { "name": "Overhead Press", "sets": 5, "reps": "3-5", "rest": "3 minutes", "notes": "Drive from legs" },
            { "name": "Pull-up", "sets": 4, "reps": "6-8", "rest": "3 minutes", "notes": "Add weight if possible" },
            { "name": "Romanian Deadlift", "sets": 4, "reps": "5-6", "rest": "3 minutes", "notes": "Heavy, feel the stretch" },
            { "name": "L-Sit", "sets": 3, "reps": "15-30 seconds", "rest": "2 minutes", "notes": "Progress to full L-sit" }
          ]
        }
      ]
    },
    {
      "id": "advanced_3_day",
      "name": "Advanced Push/Pull/Legs",
      "target_experience": ["2_plus_years"],
      "frequency": [3],
      "duration_weeks": 8,
      "description": "Classic push/pull/legs split for advanced strength and hypertrophy",
      "workouts": [
        {
          "name": "Push (Chest, Shoulders, Triceps)",
          "exercises": [
            { "name": "Bench Press", "sets": 4, "reps": "6-8", "rest": "3 minutes", "notes": "Heavy compound movement" },
            { "name": "Overhead Press", "sets": 4, "reps": "6-8", "rest": "3 minutes", "notes": "Strict form, no leg drive" },
            { "name": "Incline Dumbbell Press", "sets": 3, "reps": "8-10", "rest": "2 minutes", "notes": "Focus on upper chest" },
            { "name": "Dumbbell Lateral Raise", "sets": 3, "reps": "12-15", "rest": "90 seconds", "notes": "Control the negative" },
            { "name": "Close Grip Bench Press", "sets": 3, "reps": "8-10", "rest": "2 minutes", "notes": "Hands closer than shoulder width" },
            { "name": "Overhead Tricep Extension", "sets": 3, "reps": "10-12", "rest": "90 seconds", "notes": "Keep elbows stationary" }
          ]
        },
        {
          "name": "Pull (Back, Biceps)",
          "exercises": [
            { "name": "Deadlift", "sets": 4, "reps": "5-6", "rest": "3-4 minutes", "notes": "Focus on hip hinge pattern" },
            { "name": "Pull-up", "sets": 4, "reps": "6-10", "rest": "3 minutes", "notes": "Add weight if doing 10+ reps" },
            { "name": "Bent Over Row", "sets": 4, "reps": "8-10", "rest": "2-3 minutes", "notes": "Barbell or dumbbell" },
            { "name": "Seated Cable Row", "sets": 3, "reps": "10-12", "rest": "2 minutes", "notes": "Squeeze shoulder blades" },
            { "name": "Barbell Curl", "sets": 3, "reps": "8-10", "rest": "2 minutes", "notes": "No momentum" },
            { "name": "Hammer Curl", "sets": 3, "reps": "10-12", "rest": "90 seconds", "notes": "Neutral grip" }
          ]
        },
        {
          "name": "Legs (Quads, Hamstrings, Glutes, Calves)",
          "exercises": [
            { "name": "Squat", "sets": 4, "reps": "6-8", "rest": "3-4 minutes", "notes": "Go as low as mobility allows" },
            { "name": "Romanian Deadlift", "sets": 4, "reps": "8-10", "rest": "3 minutes", "notes": "Feel stretch in hamstrings" },
            { "name": "Bulgarian Split Squat", "sets": 3, "reps": "10-12 each leg", "rest": "2 minutes", "notes": "Add weight for progression" },
            { "name": "Leg Curl", "sets": 3, "reps": "12-15", "rest": "90 seconds", "notes": "Lying or seated" },
            { "name": "Leg Extension", "sets": 3, "reps": "12-15", "rest": "90 seconds", "notes": "Full range of motion" },
            { "name": "Standing Calf Raise", "sets": 4, "reps": "15-20", "rest": "90 seconds", "notes": "Pause at top and bottom" }
          ]
        }
      ]
    },
    {
      "id": "advanced_4_day",
      "name": "Advanced Upper/Lower Power",
      "target_experience": ["2_plus_years"],
      "frequency": [4],
      "duration_weeks": 8,
      "description": "4-day upper/lower split combining strength and hypertrophy",
      "workouts": [
        {
          "name": "Upper Power",
          "exercises": [
            { "name": "Bench Press", "sets": 5, "reps": "3-5", "rest": "3-4 minutes", "notes": "Heavy, explosive concentric" },
            { "name": "Bent Over Row", "sets": 5, "reps": "3-5", "rest": "3-4 minutes", "notes": "Match bench press intensity" },
            { "name": "Overhead Press", "sets": 4, "reps": "5-6", "rest": "3 minutes", "notes": "No leg assistance" },
            { "name": "Weighted Pull-up", "sets": 4, "reps": "5-8", "rest": "3 minutes", "notes": "Add weight if doing 8+" },
            { "name": "Close Grip Bench Press", "sets": 3, "reps": "6-8", "rest": "2 minutes", "notes": "Heavy tricep focus" }
          ]
        },
        {
          "name": "Lower Power",
          "exercises": [
            { "name": "Squat", "sets": 5, "reps": "3-5", "rest": "3-4 minutes", "notes": "Heavy, explosive up" },
            { "name": "Deadlift", "sets": 4, "reps": "3-5", "rest": "3-4 minutes", "notes": "Focus on speed off floor" },
            { "name": "Front Squat", "sets": 3, "reps": "5-6", "rest": "3 minutes", "notes": "Upright torso" },
            { "name": "Romanian Deadlift", "sets": 3, "reps": "6-8", "rest": "2-3 minutes", "notes": "Feel the stretch" },
            { "name": "Walking Lunge", "sets": 3, "reps": "8-10 each leg", "rest": "2 minutes", "notes": "Add weight for intensity" }
          ]
        },
        {
          "name": "Upper Hypertrophy",
          "exercises": [
            { "name": "Incline Dumbbell Press", "sets": 4, "reps": "8-10", "rest": "2-3 minutes", "notes": "Focus on muscle contraction" },
            { "name": "Seated Cable Row", "sets": 4, "reps": "8-10", "rest": "2-3 minutes", "notes": "Squeeze at the end" },
            { "name": "Dumbbell Shoulder Press", "sets": 3, "reps": "10-12", "rest": "2 minutes", "notes": "Full range of motion" },
            { "name": "Lat Pulldown", "sets": 3, "reps": "10-12", "rest": "2 minutes", "notes": "Pull to upper chest" },
            { "name": "Barbell Curl", "sets": 3, "reps": "10-12", "rest": "90 seconds", "notes": "Control the negative" },
            { "name": "Tricep Dip", "sets": 3, "reps": "10-15", "rest": "90 seconds", "notes": "Add weight if needed" }
          ]
        },
        {
          "name": "Lower Hypertrophy",
          "exercises": [
            { "name": "Leg Press", "sets": 4, "reps": "10-12", "rest": "2-3 minutes", "notes": "Focus on time under tension" },
            { "name": "Stiff Leg Deadlift", "sets": 4, "reps": "10-12", "rest": "2-3 minutes", "notes": "Feel the hamstring stretch" },
            { "name": "Bulgarian Split Squat", "sets": 3, "reps": "12-15 each leg", "rest": "2 minutes", "notes": "Focus on the working leg" },
            { "name": "Leg Curl", "sets": 3, "reps": "12-15", "rest": "90 seconds", "notes": "Squeeze at the contraction" },
            { "name": "Leg Extension", "sets": 3, "reps": "12-15", "rest": "90 seconds", "notes": "Pause at the top" },
            { "name": "Calf Raise", "sets": 4, "reps": "15-20", "rest": "90 seconds", "notes": "Full range, pause at top" }
          ]
        }
      ]
    }
  ]
};

// ============================================================================
// GLOBAL STATE MANAGEMENT
// ============================================================================

/**
 * Current step in the questionnaire process
 * Steps: 1-5 (questionnaire) -> loading -> success
 */
let currentStep = 1;

/**
 * Total number of questionnaire steps (excluding loading and success pages)
 */
const totalSteps = 5;

/**
 * Form data object that stores all user responses
 * This object gets populated as the user progresses through the questionnaire
 */
const formData = {
    experience: '',                    // User's training experience level
    whyUsingApp: [],                  // Reasons for using the app (multiple choice)
    equipmentAvailable: [],           // Available equipment (multiple choice)
    equipmentConfidence: {},          // Confidence ratings for each equipment type
    trainingDays: 3,                  // Number of training days per week (slider)
    firstName: '',                    // User's first name
    lastName: '',                     // User's last name
    email: '',                        // User's email address
    additionalInfo: ''                // Any additional information from user
};

/**
 * Equipment mapping for confidence ratings
 * Maps equipment IDs to display information including icons and labels
 */
const equipmentLabels = {
    dumbbells: {
        icon: '🏋️‍♀️',
        label: 'Dumbbells'
    },
    barbells: {
        icon: '🏋️',
        label: 'Barbells'
    },
    pin_loaded_machines: {
        icon: '🗿',
        label: 'Pin-loaded machines'
    },
    cable_machines: {
        icon: '🔌',
        label: 'Cable machines'
    }
};

/**
 * Fields that allow multiple selections
 * Used to determine whether to handle single or multiple selection logic
 */
const multipleChoiceFields = ['whyUsingApp', 'equipmentAvailable'];

/**
 * DOM elements cache for better performance
 * Avoids repeated DOM queries by storing references
 */
const elements = {
    progressBar: null,
    currentStepText: null,
    progressPercentage: null,
    prevBtn: null,
    nextBtn: null,
    navigationButtons: null
};

// ============================================================================
// INITIALIZATION AND SETUP
// ============================================================================

/**
 * Initialize the application when DOM is loaded
 * This is the main entry point for the questionnaire
 */
document.addEventListener('DOMContentLoaded', function () {
    init();
});

/**
 * Main initialization function
 * Sets up the questionnaire interface and prepares all necessary components
 */
function init() {
    // Cache DOM elements for better performance
    cacheElements();
    
    // Set up initial progress display
    updateProgress();
    
    // Attach all event listeners
    attachEventListeners();
    
    // Create dynamic pages that aren't in the HTML
    createLoadingScreen();
    createSuccessScreen();
    
    // Get user email from previous page if available
    retrieveUserEmail();
    
    // Initialize the first step
    showStep(currentStep);
    
    console.log('trAIn Questionnaire App initialized successfully');
}

/**
 * Cache frequently accessed DOM elements to improve performance
 * Prevents repeated querySelector calls throughout the application
 */
function cacheElements() {
    elements.progressBar = document.getElementById('progressBar');
    elements.currentStepText = document.getElementById('currentStepText');
    elements.progressPercentage = document.getElementById('progressPercentage');
    elements.prevBtn = document.getElementById('prevBtn');
    elements.nextBtn = document.getElementById('nextBtn');
    elements.navigationButtons = document.getElementById('navigationButtons');
    
    // Log any missing elements for debugging
    Object.keys(elements).forEach(key => {
        if (!elements[key]) {
            console.warn(`Element not found: ${key}`);
        }
    });
}

/**
 * Retrieve user email from sessionStorage (set on landing page)
 * This email will be used for program delivery
 */
function retrieveUserEmail() {
    const userEmail = sessionStorage.getItem('userEmail');
    if (userEmail) {
        formData.email = userEmail;
        console.log('Retrieved user email from session:', userEmail);
    } else {
        console.warn('No user email found in session storage');
    }
}

// ============================================================================
// DYNAMIC SCREEN CREATION
// ============================================================================

/**
 * Create the loading screen that appears during program generation
 * This screen shows animated progress and realistic loading steps
 */
function createLoadingScreen() {
    const loadingHTML = `
        <div class="step hidden" id="step-loading">
            <div class="question-container">
                <h2 class="question-title">Creating your personalized program...</h2>
                <p class="question-subtitle">Our AI is analyzing your responses to build the perfect workout plan</p>
            </div>
            
            <div class="loading-container">
                <div class="loading-progress">
                    <div class="loading-bar-bg">
                        <div class="loading-bar-fill" id="loadingBar"></div>
                    </div>
                    <div class="loading-text" id="loadingText">Analyzing your experience level...</div>
                </div>
                
                <div class="loading-steps">
                    <div class="loading-step" id="loading-step-1">
                        <span class="loading-step-icon">⏳</span>
                        <span class="loading-step-text">Experience assessment</span>
                    </div>
                    <div class="loading-step" id="loading-step-2">
                        <span class="loading-step-icon">⏳</span>
                        <span class="loading-step-text">Equipment matching</span>
                    </div>
                    <div class="loading-step" id="loading-step-3">
                        <span class="loading-step-icon">⏳</span>
                        <span class="loading-step-text">Program selection</span>
                    </div>
                    <div class="loading-step" id="loading-step-4">
                        <span class="loading-step-icon">⏳</span>
                        <span class="loading-step-text">Exercise customization</span>
                    </div>
                    <div class="loading-step" id="loading-step-5">
                        <span class="loading-step-icon">⏳</span>
                        <span class="loading-step-text">Final optimization</span>
                    </div>
                </div>
            </div>
        </div>
    `;
    
    // Insert loading screen after the last questionnaire step
    const lastStep = document.getElementById('step-5');
    if (lastStep) {
        lastStep.insertAdjacentHTML('afterend', loadingHTML);
    } else {
        console.error('Could not find step-5 to insert loading screen');
    }
}

/**
 * Create the success screen that appears after program generation
 * This screen informs users their program is ready and includes CTA for account creation
 */
function createSuccessScreen() {
    const successHTML = `
        <div class="step hidden" id="step-success">
            <div class="success-container">
                <div class="success-icon">✅</div>
                <h2 class="question-title">Your bespoke program is ready!</h2>
                <p class="question-subtitle" style="margin-bottom: 2rem;">
                    We've created a <strong>personalized training program</strong> just for you and sent it to your email.
                </p>
                <p style="color: #6b7280; margin-bottom: 2rem;">
                    Check your inbox for your custom workout plan!
                </p>
                
                <!-- Account Creation CTA -->
                <div style="background: linear-gradient(135deg, #eff6ff, #dbeafe); padding: 2rem; border-radius: 1rem; border: 2px solid #93c5fd; margin-bottom: 2rem;">
                    <h3 style="font-size: 1.5rem; font-weight: 700; color: #1e40af; margin-bottom: 1rem; text-align: center;">
                        🚀 Take your training to the next level
                    </h3>
                    <p style="color: #4b5563; text-align: center; margin-bottom: 1.5rem;">
                        Join <strong>10,000+ users</strong> who are crushing their fitness goals with our in-app coaching experience
                    </p>
                    <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 1rem; margin-bottom: 1.5rem; text-align: center;">
                        <div>
                            <div style="font-size: 1.5rem; margin-bottom: 0.5rem;">📊</div>
                            <div style="font-weight: 600; color: #374151;">Track Progress</div>
                            <div style="font-size: 0.875rem; color: #6b7280;">See your strength gains</div>
                        </div>
                        <div>
                            <div style="font-size: 1.5rem; margin-bottom: 0.5rem;">⚡</div>
                            <div style="font-weight: 600; color: #374151;">Log Workouts</div>
                            <div style="font-size: 0.875rem; color: #6b7280;">Quick & easy logging</div>
                        </div>
                        <div>
                            <div style="font-size: 1.5rem; margin-bottom: 0.5rem;">🤖</div>
                            <div style="font-weight: 600; color: #374151;">AI Coaching</div>
                            <div style="font-size: 0.875rem; color: #6b7280;">Personalized tips</div>
                        </div>
                    </div>
                    <button class="btn btn-primary" style="width: 100%; padding: 1rem 2rem; font-size: 1.125rem;" id="create-account-btn">
                        Create Free Account - Start Tracking
                    </button>
                </div>
                
                <!-- Secondary actions -->
                <div style="text-align: center; margin-top: 1rem;">
                    <p style="color: #6b7280; font-size: 0.875rem;">
                        Don't want to create an account right now? That's okay!<br>
                        Your program has been sent to your email.
                    </p>
                </div>
            </div>
        </div>
    `;
    
    // Insert success screen after loading screen
    const loadingStep = document.getElementById('step-loading');
    if (loadingStep) {
        loadingStep.insertAdjacentHTML('afterend', successHTML);
    } else {
        // If loading screen doesn't exist yet, try inserting after step-5
        const lastStep = document.getElementById('step-5');
        if (lastStep) {
            lastStep.insertAdjacentHTML('afterend', successHTML);
        } else {
            console.error('Could not find insertion point for success screen');
        }
    }
}

// ============================================================================
// EVENT HANDLING AND USER INTERACTIONS
// ============================================================================

/**
 * Attach all event listeners for the application
 * This centralizes all event handling logic for better organization
 */
function attachEventListeners() {
    // Option button clicks (for questionnaire selections)
    document.addEventListener('click', function (e) {
        if (e.target.closest('.option-button')) {
            handleOptionClick(e.target.closest('.option-button'));
        }
        
        // Handle create account button click
        if (e.target.id === 'create-account-btn') {
            handleCreateAccountClick();
        }
    });

    // Form input changes (text inputs, etc.)
    document.addEventListener('input', function (e) {
        if (e.target.matches('.form-input')) {
            handleFormInput(e.target);
        }

        // Handle slider inputs (training days)
        if (e.target.matches('.slider')) {
            handleSliderInput(e.target);
        }

        // Handle confidence rating sliders
        if (e.target.matches('.confidence-slider')) {
            handleConfidenceSlider(e.target);
        }
    });

    // Navigation buttons
    if (elements.prevBtn) {
        elements.prevBtn.addEventListener('click', goToPreviousStep);
    }
    if (elements.nextBtn) {
        elements.nextBtn.addEventListener('click', goToNextStep);
    }
}

/**
 * Handle option button clicks (single or multiple selection)
 * Determines whether this is a single or multiple choice field and handles accordingly
 * 
 * @param {HTMLElement} button - The clicked option button
 */
function handleOptionClick(button) {
    const field = button.dataset.field;
    const value = button.dataset.value;

    if (!field || !value) {
        console.error('Button missing data attributes:', button);
        return;
    }

    // Clear any existing errors for this field
    clearError(field);

    if (multipleChoiceFields.includes(field)) {
        // Handle multiple selection (checkboxes-like behavior)
        handleMultipleSelection(button, field, value);
    } else {
        // Handle single selection (radio button-like behavior)
        handleSingleSelection(button, field, value);
    }
    
    console.log(`Selection updated - ${field}: ${formData[field]}`);
}

/**
 * Handle single selection fields (radio button behavior)
 * Only one option can be selected at a time
 * 
 * @param {HTMLElement} button - The clicked button
 * @param {string} field - The form field name
 * @param {string} value - The selected value
 */
function handleSingleSelection(button, field, value) {
    // Remove selected class from all buttons in this step
    const stepButtons = button.closest('.step').querySelectorAll('.option-button');
    stepButtons.forEach(btn => btn.classList.remove('selected'));

    // Add selected class to clicked button
    button.classList.add('selected');

    // Update form data
    formData[field] = value;
}

/**
 * Handle multiple selection fields (checkbox behavior)
 * Multiple options can be selected simultaneously
 * 
 * @param {HTMLElement} button - The clicked button
 * @param {string} field - The form field name
 * @param {string} value - The selected value
 */
function handleMultipleSelection(button, field, value) {
    // Toggle selected state
    button.classList.toggle('selected');

    // Initialize array if it doesn't exist
    if (!Array.isArray(formData[field])) {
        formData[field] = [];
    }

    if (button.classList.contains('selected')) {
        // Add to array if not already present
        if (!formData[field].includes(value)) {
            formData[field].push(value);
        }
    } else {
        // Remove from array
        formData[field] = formData[field].filter(item => item !== value);
    }

    // Special handling for equipment selection - update confidence step
    if (field === 'equipmentAvailable') {
        generateConfidenceRatings();
    }
}

/**
 * Handle text input changes
 * Updates form data and clears validation errors
 * 
 * @param {HTMLElement} input - The input element
 */
function handleFormInput(input) {
    const field = input.id;
    formData[field] = input.value;
    clearError(field);
}

/**
 * Handle slider input changes (training days selection)
 * Updates both form data and display value
 * 
 * @param {HTMLElement} slider - The slider element
 */
function handleSliderInput(slider) {
    const field = slider.dataset.field;
    const value = parseInt(slider.value);
    formData[field] = value;

    // Update display value
    if (field === 'trainingDays') {
        const valueDisplay = document.getElementById('trainingDaysValue');
        if (valueDisplay) {
            valueDisplay.textContent = value;
        }
    }
}

/**
 * Handle equipment confidence slider changes
 * Updates confidence ratings and display text
 * 
 * @param {HTMLElement} slider - The confidence slider element
 */
function handleConfidenceSlider(slider) {
    const equipment = slider.dataset.equipment;
    const value = parseInt(slider.value);

    // Initialize confidence object if it doesn't exist
    if (!formData.equipmentConfidence) {
        formData.equipmentConfidence = {};
    }

    // Store confidence rating
    formData.equipmentConfidence[equipment] = value;

    // Update display value
    const valueDisplay = document.getElementById(`confidence-value-${equipment}`);
    if (valueDisplay) {
        valueDisplay.textContent = getConfidenceText(value);
    }
}

/**
 * Handle create account button click
 * This would typically redirect to account creation or trigger signup flow
 */
function handleCreateAccountClick() {
    console.log('Create account clicked');
    
    // For now, show an alert - in production this would redirect to signup
    alert('Account creation would redirect to signup page. For demo purposes, this shows an alert.');
    
    // In production, you might do:
    // window.location.href = '/signup?email=' + encodeURIComponent(formData.email);
    // or trigger a modal signup form
}

// ============================================================================
// DYNAMIC CONTENT GENERATION
// ============================================================================

/**
 * Generate confidence rating sliders based on selected equipment
 * This function creates sliders dynamically based on what equipment the user selected
 */
function generateConfidenceRatings() {
    const container = document.getElementById('confidenceContainer');
    if (!container) {
        console.error('Confidence container not found');
        return;
    }

    // Clear existing content
    container.innerHTML = '';

    // Get selected equipment from form data
    const selectedEquipment = formData.equipmentAvailable || [];

    if (selectedEquipment.length === 0) {
        container.innerHTML = '<p class="text-gray-500 text-center">Please select equipment in the previous step first.</p>';
        return;
    }

    console.log('Generating confidence ratings for:', selectedEquipment);

    // Create confidence sliders for each selected equipment type
    selectedEquipment.forEach(equipmentKey => {
        const equipment = equipmentLabels[equipmentKey];
        if (!equipment) {
            console.warn(`Equipment label not found for: ${equipmentKey}`);
            return;
        }

        const confidenceItem = document.createElement('div');
        confidenceItem.className = 'confidence-item';
        confidenceItem.innerHTML = `
            <div class="confidence-header">
                <span class="confidence-icon">${equipment.icon}</span>
                <span class="confidence-label">${equipment.label}</span>
            </div>
            <div class="confidence-slider-wrapper">
                <input type="range" 
                       class="confidence-slider" 
                       min="1" 
                       max="5" 
                       value="${formData.equipmentConfidence[equipmentKey] || 3}"
                       data-equipment="${equipmentKey}">
                <div class="confidence-labels">
                    <span>1</span>
                    <span>2</span>
                    <span>3</span>
                    <span>4</span>
                    <span>5</span>
                </div>
                <div class="confidence-value" id="confidence-value-${equipmentKey}">
                    ${getConfidenceText(formData.equipmentConfidence[equipmentKey] || 3)}
                </div>
            </div>
        `;
        container.appendChild(confidenceItem);

        // Initialize the confidence value if not set
        if (!formData.equipmentConfidence[equipmentKey]) {
            formData.equipmentConfidence[equipmentKey] = 3;
        }
    });
}

/**
 * Convert confidence rating number to descriptive text
 * 
 * @param {number} value - Confidence rating (1-5)
 * @returns {string} - Descriptive text for the rating
 */
function getConfidenceText(value) {
    const confidenceTexts = {
        1: 'Not confident',
        2: 'Slightly confident', 
        3: 'Moderately confident',
        4: 'Very confident',
        5: 'Extremely confident'
    };
    return confidenceTexts[value] || 'Moderately confident';
}

// ============================================================================
// FORM VALIDATION
// ============================================================================

/**
 * Validate the current step before allowing progression
 * Each step has specific validation requirements
 * 
 * @returns {boolean} - True if current step is valid, false otherwise
 */
function validateCurrentStep() {
    // Clear any existing errors
    clearAllErrors();

    switch (currentStep) {
        case 1:
            return validateField('experience', 'Please select your experience level');
        case 2:
            return validateArrayField('whyUsingApp', 'Please select at least one reason');
        case 3:
            return validateArrayField('equipmentAvailable', 'Please select at least one piece of equipment');
        case 4:
            return validateEquipmentConfidence();
        case 5:
            return true; // Slider always has a value, so no validation needed
        default:
            return true;
    }
}

/**
 * Validate equipment confidence ratings
 * Ensures all selected equipment has confidence ratings
 * 
 * @returns {boolean} - True if all confidence ratings are provided
 */
function validateEquipmentConfidence() {
    const selectedEquipment = formData.equipmentAvailable || [];

    if (selectedEquipment.length === 0) {
        showError('equipmentConfidence', 'Please select equipment in the previous step first');
        return false;
    }

    // Check if all selected equipment has confidence ratings
    for (const equipment of selectedEquipment) {
        if (!formData.equipmentConfidence[equipment]) {
            showError('equipmentConfidence', 'Please rate your confidence for all selected equipment');
            return false;
        }
    }

    return true;
}

/**
 * Validate a single required field
 * 
 * @param {string} fieldName - Name of the field to validate
 * @param {string} errorMessage - Error message to show if validation fails
 * @returns {boolean} - True if field is valid
 */
function validateField(fieldName, errorMessage) {
    if (!formData[fieldName]) {
        showError(fieldName, errorMessage);
        return false;
    }
    return true;
}

/**
 * Validate an array field (multiple selections)
 * 
 * @param {string} fieldName - Name of the array field to validate
 * @param {string} errorMessage - Error message to show if validation fails
 * @returns {boolean} - True if field has at least one selection
 */
function validateArrayField(fieldName, errorMessage) {
    if (!formData[fieldName] || formData[fieldName].length === 0) {
        showError(fieldName, errorMessage);
        return false;
    }
    return true;
}

/**
 * Show error message for a specific field
 * 
 * @param {string} fieldName - Name of the field with error
 * @param {string} message - Error message to display
 */
function showError(fieldName, message) {
    const errorElement = document.getElementById(`${fieldName}-error`);
    const inputElement = document.getElementById(fieldName);

    if (errorElement) {
        errorElement.textContent = message;
        errorElement.style.display = 'block';
    }

    if (inputElement) {
        inputElement.classList.add('error');
    }
    
    console.warn(`Validation error for ${fieldName}: ${message}`);
}

/**
 * Clear error message for a specific field
 * 
 * @param {string} fieldName - Name of the field to clear error for
 */
function clearError(fieldName) {
    const errorElement = document.getElementById(`${fieldName}-error`);
    const inputElement = document.getElementById(fieldName);

    if (errorElement) {
        errorElement.textContent = '';
        errorElement.style.display = 'none';
    }

    if (inputElement) {
        inputElement.classList.remove('error');
    }
}

/**
 * Clear all error messages and styling
 * Used before running validation to start with a clean slate
 */
function clearAllErrors() {
    const errorElements = document.querySelectorAll('.form-error');
    const inputElements = document.querySelectorAll('.form-input');

    errorElements.forEach(element => {
        element.textContent = '';
        element.style.display = 'none';
    });

    inputElements.forEach(element => {
        element.classList.remove('error');
    });
}

// ============================================================================
// NAVIGATION AND STEP MANAGEMENT
// ============================================================================

/**
 * Navigate to the next step in the questionnaire
 * Validates current step before proceeding
 */
function goToNextStep() {
    if (validateCurrentStep()) {
        if (currentStep < totalSteps) {
            currentStep++;
            showStep(currentStep);
            updateProgress();
            console.log(`Advanced to step ${currentStep}`);
        } else {
            // Final step - submit questionnaire and generate program
            console.log('Questionnaire complete, generating program...');
            submitQuestionnaireAndGenerateProgram();
        }
    } else {
        console.log(`Validation failed for step ${currentStep}`);
    }
}

/**
 * Navigate to the previous step in the questionnaire
 * No validation required when going backwards
 */
function goToPreviousStep() {
    if (currentStep > 1) {
        currentStep--;
        showStep(currentStep);
        updateProgress();
        console.log(`Returned to step ${currentStep}`);
    }
}

/**
 * Display a specific step and hide all others
 * Also handles special step-specific logic
 * 
 * @param {number} stepNumber - The step number to display
 */
function showStep(stepNumber) {
    // Hide all steps
    const allSteps = document.querySelectorAll('.step');
    allSteps.forEach(step => {
        step.classList.remove('active');
        step.classList.add('hidden');
    });

    // Show target step
    const targetStep = document.getElementById(`step-${stepNumber}`);
    if (targetStep) {
        targetStep.classList.remove('hidden');
        targetStep.classList.add('active');
    } else {
        console.error(`Step ${stepNumber} not found`);
        return;
    }

    // Special handling for step 4 (confidence ratings)
    if (stepNumber === 4) {
        generateConfidenceRatings();
    }

    // Update navigation buttons
    updateNavigationButtons();
    
    console.log(`Displaying step ${stepNumber}`);
}

/**
 * Update navigation button visibility and text
 * Adapts button appearance based on current step
 */
function updateNavigationButtons() {
    const isFirstStep = currentStep === 1;
    const isLastStep = currentStep === totalSteps;

    // Show/hide previous button
    if (isFirstStep) {
        elements.prevBtn.classList.add('hidden');
    } else {
        elements.prevBtn.classList.remove('hidden');
    }

    // Update next button text
    if (isLastStep) {
        elements.nextBtn.textContent = 'Generate My Program';
    } else {
        elements.nextBtn.textContent = 'Next';
    }
}

/**
 * Update progress bar and percentage display
 * Shows user how far through the questionnaire they are
 */
function updateProgress() {
    const percentage = (currentStep / totalSteps) * 100;

    if (elements.progressBar) {
        elements.progressBar.style.width = `${percentage}%`;
    }

    if (elements.currentStepText) {
        elements.currentStepText.textContent = currentStep;
    }

    if (elements.progressPercentage) {
        elements.progressPercentage.textContent = Math.round(percentage);
    }
}

// ============================================================================
// PROGRAM GENERATION AND SUBMISSION
// ============================================================================

/**
 * Submit questionnaire data and initiate program generation
 * This is called when user completes the final questionnaire step
 */
async function submitQuestionnaireAndGenerateProgram() {
    try {
        console.log('Starting program generation process...');
        console.log('Form data:', formData);
        
        // Show loading screen
        showLoadingScreen();
        
        // Start loading animation
        simulateProgramGeneration();
        
        // Generate the program based on form data
        const generatedProgram = generateProgramFromFormData(formData);
        console.log('Generated program:', generatedProgram);
        
        // Submit questionnaire and program to backend
        const submissionResult = await submitToBackend(formData, generatedProgram);
        
        // Wait for loading animation to complete, then show success
        setTimeout(() => {
            showSuccessScreen();
            console.log('Program generation completed successfully');
        }, 6500); // Total loading animation time

    } catch (error) {
        console.error('Error during program generation:', error);
        
        // Still show success screen after loading, but log the error
        setTimeout(() => {
            showSuccessScreen();
            console.warn('Program generation completed with errors, but proceeding to success screen');
        }, 6500);
    }
}

/**
 * Generate a personalized program based on user's questionnaire responses
 * Uses the program templates and user preferences to create a custom plan
 * 
 * @param {Object} formData - User's questionnaire responses
 * @returns {Object} - Generated program object
 */
function generateProgramFromFormData(formData) {
    console.log('Generating program for user data:', formData);
    
    // Map experience levels to program categories
    const experienceMapping = {
        '0_months': 'beginner',
        '0_6_months': 'beginner', 
        '6_months_2_years': 'beginner',
        '2_plus_years': 'advanced'
    };

    const level = experienceMapping[formData.experience] || 'beginner';
    const days = formData.trainingDays;

    console.log(`Looking for ${level} program with ${days} days`);

    // Find the best matching program template
    const templateKey = `${level}_${days}_day`;
    
    let selectedTemplate = PROGRAM_TEMPLATES.programs.find(p => p.id === templateKey);
    
    // Fallback logic if exact match not found
    if (!selectedTemplate) {
        console.warn(`Exact template not found for ${templateKey}, searching for alternatives...`);
        
        // Try to find template that matches experience and frequency
        selectedTemplate = PROGRAM_TEMPLATES.programs.find(p => 
            p.target_experience.includes(formData.experience) && 
            p.frequency.includes(days)
        );
        
        // Final fallback - find template with matching experience
        if (!selectedTemplate) {
            selectedTemplate = PROGRAM_TEMPLATES.programs.find(p => 
                p.target_experience.includes(formData.experience)
            );
        }
        
        // Ultimate fallback - use first template
        if (!selectedTemplate) {
            console.warn('No matching template found, using default template');
            selectedTemplate = PROGRAM_TEMPLATES.programs[0];
        }
    }

    console.log('Selected template:', selectedTemplate.name);

    // Create personalized program object
    const program = {
        id: `custom_${Date.now()}`,
        name: selectedTemplate.name,
        description: selectedTemplate.description,
        duration_weeks: selectedTemplate.duration_weeks,
        frequency: days,
        user: {
            email: formData.email,
            experience: formData.experience,
            trainingDays: formData.trainingDays,
            whyUsingApp: formData.whyUsingApp,
            equipmentAvailable: formData.equipmentAvailable,
            equipmentConfidence: formData.equipmentConfidence
        },
        // Take only the number of workouts that match requested frequency
        workouts: selectedTemplate.workouts.slice(0, days),
        created_at: new Date().toISOString(),
        template_used: selectedTemplate.id
    };

    return program;
}

/**
 * Submit questionnaire data and generated program to backend
 * This would send the data to your server for processing and email delivery
 * 
 * @param {Object} formData - User's questionnaire responses
 * @param {Object} program - Generated workout program
 * @returns {Promise<Object>} - Server response
 */
async function submitToBackend(formData, program) {
    // In a real application, this would submit to your backend
    // For now, we'll simulate the API call
    
    const submissionData = {
        questionnaire: formData,
        program: program,
        timestamp: new Date().toISOString()
    };
    
    console.log('Simulating backend submission:', submissionData);
    
    // Simulate API call delay
    await new Promise(resolve => setTimeout(resolve, 1000));
    
    // In production, this would be:
    // const response = await fetch('/api/questionnaire/submit', {
    //     method: 'POST',
    //     headers: {
    //         'Content-Type': 'application/json',
    //     },
    //     body: JSON.stringify(submissionData)
    // });
    // return response.json();
    
    return {
        success: true,
        message: 'Program generated and sent to email',
        programId: program.id
    };
}

// ============================================================================
// LOADING SCREEN AND ANIMATIONS
// ============================================================================

/**
 * Show the loading screen and hide other elements
 * Transitions from questionnaire to loading state
 */
function showLoadingScreen() {
    // Hide all current steps
    const allSteps = document.querySelectorAll('.step');
    allSteps.forEach(step => {
        step.classList.remove('active');
        step.classList.add('hidden');
    });

    // Show loading step
    const loadingStep = document.getElementById('step-loading');
    if (loadingStep) {
        loadingStep.classList.remove('hidden');
        loadingStep.classList.add('active');
    } else {
        console.error('Loading step not found');
        return;
    }

    // Hide navigation buttons during loading
    if (elements.navigationButtons) {
        elements.navigationButtons.classList.add('hidden');
    }

    // Update main progress bar to 100%
    if (elements.progressBar) {
        elements.progressBar.style.width = '100%';
    }
    if (elements.progressPercentage) {
        elements.progressPercentage.textContent = '100';
    }
    
    console.log('Loading screen displayed');
}

/**
 * Simulate realistic program generation with animated progress
 * Creates engaging loading experience with multiple steps
 */
function simulateProgramGeneration() {
    // Define loading steps with realistic timing
    const loadingSteps = [
        { text: "Analyzing your experience level...", duration: 800 },
        { text: "Matching equipment preferences...", duration: 1000 },
        { text: "Selecting optimal program template...", duration: 1200 },
        { text: "Customizing exercises for your needs...", duration: 1500 },
        { text: "Optimizing workout structure...", duration: 1000 },
        { text: "Finalizing your program...", duration: 1000 }
    ];

    let currentLoadingStep = 0;
    const loadingBar = document.getElementById('loadingBar');
    const loadingText = document.getElementById('loadingText');

    if (!loadingBar || !loadingText) {
        console.error('Loading animation elements not found');
        return;
    }

    /**
     * Update the current loading step and progress
     * Recursively called to create smooth progression
     */
    function updateLoadingStep() {
        if (currentLoadingStep < loadingSteps.length) {
            const step = loadingSteps[currentLoadingStep];
            
            // Update progress bar
            const progress = ((currentLoadingStep + 1) / loadingSteps.length) * 100;
            loadingBar.style.width = `${progress}%`;
            
            // Update loading text
            loadingText.textContent = step.text;
            
            // Update step indicators - mark previous step as completed
            if (currentLoadingStep > 0) {
                const prevStepElement = document.getElementById(`loading-step-${currentLoadingStep}`);
                if (prevStepElement) {
                    prevStepElement.classList.add('completed');
                    const icon = prevStepElement.querySelector('.loading-step-icon');
                    if (icon) icon.textContent = '✓';
                }
            }
            
            // Mark current step as active
            const currentStepElement = document.getElementById(`loading-step-${currentLoadingStep + 1}`);
            if (currentStepElement) {
                currentStepElement.classList.add('active');
                const icon = currentStepElement.querySelector('.loading-step-icon');
                if (icon) icon.textContent = '⏳';
            }

            currentLoadingStep++;
            setTimeout(updateLoadingStep, step.duration);
        } else {
            // Complete final step
            const lastStep = document.getElementById(`loading-step-${loadingSteps.length}`);
            if (lastStep) {
                lastStep.classList.add('completed');
                lastStep.classList.remove('active');
                const icon = lastStep.querySelector('.loading-step-icon');
                if (icon) icon.textContent = '✓';
            }
            
            loadingText.textContent = "Program ready!";
            console.log('Loading animation completed');
        }
    }

    updateLoadingStep();
}

/**
 * Show the success screen after program generation
 * Displays completion message and account creation CTA
 */
function showSuccessScreen() {
    // Hide loading screen
    const loadingStep = document.getElementById('step-loading');
    if (loadingStep) {
        loadingStep.classList.add('hidden');
        loadingStep.classList.remove('active');
    }

    // Show success step
    const successStep = document.getElementById('step-success');
    if (successStep) {
        successStep.classList.remove('hidden');
        successStep.classList.add('active');
        console.log('Success screen displayed');
    } else {
        console.error('Success step not found');
    }

    // Keep navigation buttons hidden on success screen
    if (elements.navigationButtons) {
        elements.navigationButtons.classList.add('hidden');
    }
}

// ============================================================================
// UTILITY FUNCTIONS AND HELPERS
// ============================================================================

/**
 * Save form data to localStorage for persistence
 * Allows users to refresh page without losing progress
 */
function saveFormData() {
    try {
        localStorage.setItem('trAIn_questionnaire_data', JSON.stringify(formData));
        localStorage.setItem('trAIn_questionnaire_step', currentStep.toString());
        console.log('Form data saved to localStorage');
    } catch (error) {
        console.warn('Could not save form data to localStorage:', error);
    }
}

/**
 * Load form data from localStorage if available
 * Restores user progress on page reload
 */
function loadFormData() {
    try {
        const savedData = localStorage.getItem('trAIn_questionnaire_data');
        const savedStep = localStorage.getItem('trAIn_questionnaire_step');

        if (savedData) {
            const parsedData = JSON.parse(savedData);
            Object.assign(formData, parsedData);
            console.log('Form data loaded from localStorage');
        }

        if (savedStep) {
            const stepNumber = parseInt(savedStep, 10);
            if (stepNumber >= 1 && stepNumber <= totalSteps) {
                currentStep = stepNumber;
                console.log(`Restored to step ${currentStep}`);
            }
        }

        // Restore form visual state
        restoreFormState();
    } catch (error) {
        console.warn('Could not load form data from localStorage:', error);
    }
}

/**
 * Restore visual form state from saved data
 * Re-selects buttons and fills inputs based on saved form data
 */
function restoreFormState() {
    // Restore button selections
    Object.keys(formData).forEach(field => {
        if (Array.isArray(formData[field])) {
            // Multiple selection fields - restore all selected options
            formData[field].forEach(value => {
                const button = document.querySelector(`[data-field="${field}"][data-value="${value}"]`);
                if (button) {
                    button.classList.add('selected');
                }
            });
        } else if (formData[field]) {
            // Single selection fields - restore selected option
            const button = document.querySelector(`[data-field="${field}"][data-value="${formData[field]}"]`);
            if (button) {
                button.classList.add('selected');
            }

            // Input fields - restore values
            const input = document.getElementById(field);
            if (input) {
                input.value = formData[field];
            }
        }
    });

    // Restore slider values
    const trainingDaysSlider = document.getElementById('trainingDays');
    if (trainingDaysSlider && formData.trainingDays) {
        trainingDaysSlider.value = formData.trainingDays;
        const valueDisplay = document.getElementById('trainingDaysValue');
        if (valueDisplay) {
            valueDisplay.textContent = formData.trainingDays;
        }
    }

    // Restore confidence ratings if equipment is selected
    if (formData.equipmentAvailable && formData.equipmentAvailable.length > 0) {
        // Regenerate confidence sliders for restored equipment
        generateConfidenceRatings();
    }
}

/**
 * Clear saved data from localStorage
 * Called after successful form submission
 */
function clearSavedData() {
    try {
        localStorage.removeItem('trAIn_questionnaire_data');
        localStorage.removeItem('trAIn_questionnaire_step');
        console.log('Saved form data cleared');
    } catch (error) {
        console.warn('Could not clear saved data:', error);
    }
}

/**
 * Enable auto-save functionality
 * Automatically saves form data when user makes changes
 * Uncomment the call at the bottom to enable this feature
 */
function enableAutoSave() {
    // Save data whenever form changes
    document.addEventListener('change', saveFormData);
    document.addEventListener('input', saveFormData);
    
    // Also save when user makes selections
    document.addEventListener('click', function(e) {
        if (e.target.closest('.option-button')) {
            // Delay save slightly to ensure form data is updated first
            setTimeout(saveFormData, 100);
        }
    });
    
    console.log('Auto-save enabled');
}

/**
 * Validate email format
 * Helper function for email validation
 * 
 * @param {string} email - Email address to validate
 * @returns {boolean} - True if email format is valid
 */
function isValidEmail(email) {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
}

/**
 * Format date for display
 * Helper function to format dates consistently
 * 
 * @param {Date} date - Date object to format
 * @returns {string} - Formatted date string
 */
function formatDate(date) {
    return new Intl.DateTimeFormat('en-US', {
        year: 'numeric',
        month: 'long',
        day: 'numeric'
    }).format(date);
}

/**
 * Debug function to log current form state
 * Useful for development and troubleshooting
 */
function debugFormState() {
    console.group('Current Form State');
    console.log('Current Step:', currentStep);
    console.log('Form Data:', JSON.stringify(formData, null, 2));
    console.log('Validation Status:', validateCurrentStep());
    console.groupEnd();
}

/**
 * Get program difficulty text based on experience level
 * Helper function for program customization
 * 
 * @param {string} experience - User's experience level
 * @returns {string} - Human-readable difficulty level
 */
function getProgramDifficulty(experience) {
    const difficultyMap = {
        '0_months': 'Beginner',
        '0_6_months': 'Beginner',
        '6_months_2_years': 'Intermediate',
        '2_plus_years': 'Advanced'
    };
    return difficultyMap[experience] || 'Beginner';
}

/**
 * Get equipment priority score for program selection
 * Helps determine which exercises to prioritize based on user confidence
 * 
 * @param {string} equipmentType - Type of equipment
 * @param {Object} confidenceRatings - User's confidence ratings
 * @returns {number} - Priority score (higher = more confident)
 */
function getEquipmentPriorityScore(equipmentType, confidenceRatings) {
    const confidence = confidenceRatings[equipmentType] || 1;
    const baseScores = {
        'dumbbells': 4,
        'barbells': 5,
        'pin_loaded_machines': 3,
        'cable_machines': 3
    };
    
    return (baseScores[equipmentType] || 2) * confidence;
}

// ============================================================================
// INITIALIZATION OPTIONS AND FEATURES
// ============================================================================

/**
 * Configuration object for optional features
 * Developers can enable/disable features by modifying these flags
 */
const appConfig = {
    autoSave: false,           // Auto-save form data to localStorage
    debugMode: false,          // Enable debug logging
    restoreProgress: false,    // Restore progress from localStorage on page load
    animationSpeed: 'normal',  // 'fast', 'normal', 'slow'
    validateOnChange: true     // Validate fields as user types/selects
};

/**
 * Apply configuration settings
 * Called during initialization to set up optional features
 */
function applyConfiguration() {
    if (appConfig.autoSave) {
        enableAutoSave();
        console.log('Auto-save feature enabled');
    }
    
    if (appConfig.restoreProgress) {
        loadFormData();
        console.log('Progress restoration enabled');
    }
    
    if (appConfig.debugMode) {
        // Add debug information to console
        window.debugFormState = debugFormState;
        window.formData = formData;
        console.log('Debug mode enabled. Use debugFormState() to inspect form state.');
    }
    
    if (appConfig.animationSpeed === 'fast') {
        // Reduce animation timings for faster experience
        document.documentElement.style.setProperty('--animation-speed', '0.5');
    } else if (appConfig.animationSpeed === 'slow') {
        // Increase animation timings for accessibility
        document.documentElement.style.setProperty('--animation-speed', '2');
    }
}

// ============================================================================
// ERROR HANDLING AND FALLBACKS
// ============================================================================

/**
 * Global error handler for uncaught exceptions
 * Provides graceful error handling and user feedback
 */
window.addEventListener('error', function(event) {
    console.error('Global error caught:', event.error);
    
    // In production, you might want to send this to an error tracking service
    // Example: sendErrorToTracking(event.error);
    
    // Show user-friendly error message
    const errorMessage = 'Something went wrong. Please refresh the page and try again.';
    alert(errorMessage);
});

/**
 * Handle API errors gracefully
 * Provides fallback behavior when backend requests fail
 * 
 * @param {Error} error - The error that occurred
 * @param {string} context - Context where the error occurred
 */
function handleApiError(error, context) {
    console.error(`API Error in ${context}:`, error);
    
    // Provide user feedback
    const userMessage = `We're having trouble connecting to our servers. Your progress has been saved locally.`;
    
    // In a real app, you might show a toast notification instead of alert
    // showToastNotification(userMessage, 'error');
    console.warn(userMessage);
    
    // Save current progress in case of reload
    if (appConfig.autoSave) {
        saveFormData();
    }
}

/**
 * Validate browser compatibility
 * Ensures the app works on older browsers
 */
function validateBrowserCompatibility() {
    const requiredFeatures = [
        'localStorage' in window,
        'JSON' in window,
        'addEventListener' in document,
        'querySelector' in document
    ];
    
    const isCompatible = requiredFeatures.every(feature => feature);
    
    if (!isCompatible) {
        alert('Your browser is not supported. Please use a modern browser like Chrome, Firefox, Safari, or Edge.');
        return false;
    }
    
    return true;
}

// ============================================================================
// ANALYTICS AND TRACKING (OPTIONAL)
// ============================================================================

/**
 * Track user progression through questionnaire
 * This would typically integrate with analytics services
 * 
 * @param {string} event - Event name
 * @param {Object} data - Event data
 */
function trackUserEvent(event, data = {}) {
    if (appConfig.debugMode) {
        console.log('Analytics Event:', event, data);
    }
    
    // In production, this would send to your analytics service
    // Example integrations:
    // gtag('event', event, data);                    // Google Analytics
    // analytics.track(event, data);                  // Segment
    // mixpanel.track(event, data);                   // Mixpanel
    // amplitude.getInstance().logEvent(event, data); // Amplitude
}

/**
 * Track step completion
 * Called whenever user completes a questionnaire step
 * 
 * @param {number} stepNumber - Completed step number
 */
function trackStepCompletion(stepNumber) {
    trackUserEvent('questionnaire_step_completed', {
        step: stepNumber,
        totalSteps: totalSteps,
        timestamp: new Date().toISOString()
    });
}

/**
 * Track program generation
 * Called when user's program is successfully generated
 * 
 * @param {Object} program - Generated program data
 */
function trackProgramGeneration(program) {
    trackUserEvent('program_generated', {
        programId: program.id,
        templateUsed: program.template_used,
        trainingDays: program.frequency,
        userExperience: program.user.experience,
        timestamp: new Date().toISOString()
    });
}

// ============================================================================
// ENHANCED INITIALIZATION
// ============================================================================

/**
 * Enhanced initialization that includes all optional features
 * This replaces the simple init() function for production use
 */
function initializeApp() {
    // Check browser compatibility first
    if (!validateBrowserCompatibility()) {
        return;
    }
    
    try {
        // Apply configuration settings
        applyConfiguration();
        
        // Cache DOM elements
        cacheElements();
        
        // Set up initial progress display
        updateProgress();
        
        // Attach all event listeners
        attachEventListeners();
        
        // Create dynamic pages
        createLoadingScreen();
        createSuccessScreen();
        
        // Get user email from previous page
        retrieveUserEmail();
        
        // Initialize the first step
        showStep(currentStep);
        
        // Track app initialization
        trackUserEvent('questionnaire_started', {
            timestamp: new Date().toISOString(),
            userAgent: navigator.userAgent
        });
        
        console.log('trAIn Questionnaire App initialized successfully');
        
    } catch (error) {
        console.error('Failed to initialize app:', error);
        handleApiError(error, 'initialization');
    }
}

// ============================================================================
// FINAL SETUP AND EXPORTS
// ============================================================================

// Optional: Enable auto-save (uncomment to activate)
// enableAutoSave();

// Optional: Enable progress restoration (uncomment to activate)
// loadFormData();

// Make certain functions available globally for debugging (development only)
if (appConfig.debugMode) {
    window.trAInDebug = {
        formData,
        debugFormState,
        generateProgramFromFormData,
        validateCurrentStep,
        saveFormData,
        loadFormData,
        clearSavedData
    };
}

/**
 * Performance monitoring (optional)
 * Tracks how long it takes users to complete the questionnaire
 */
const performanceMetrics = {
    startTime: Date.now(),
    stepTimes: {},
    
    recordStepTime(stepNumber) {
        this.stepTimes[stepNumber] = Date.now() - this.startTime;
    },
    
    getCompletionTime() {
        return Date.now() - this.startTime;
    }
};

// Start performance tracking
if (appConfig.debugMode) {
    window.performance = performanceMetrics;
}

/**
 * Accessibility enhancements
 * Improves experience for users with disabilities
 */
function enhanceAccessibility() {
    // Add ARIA labels to progress bar
    if (elements.progressBar) {
        elements.progressBar.setAttribute('role', 'progressbar');
        elements.progressBar.setAttribute('aria-valuenow', '20');
        elements.progressBar.setAttribute('aria-valuemin', '0');
        elements.progressBar.setAttribute('aria-valuemax', '100');
    }
    
    // Add keyboard navigation support
    document.addEventListener('keydown', function(event) {
        // Allow navigation with arrow keys
        if (event.key === 'ArrowRight' && !event.ctrlKey && !event.metaKey) {
            const nextBtn = elements.nextBtn;
            if (nextBtn && !nextBtn.disabled && document.activeElement.tagName !== 'INPUT') {
                nextBtn.click();
                event.preventDefault();
            }
        } else if (event.key === 'ArrowLeft' && !event.ctrlKey && !event.metaKey) {
            const prevBtn = elements.prevBtn;
            if (prevBtn && !prevBtn.classList.contains('hidden') && document.activeElement.tagName !== 'INPUT') {
                prevBtn.click();
                event.preventDefault();
            }
        }
    });
}

// Apply accessibility enhancements
document.addEventListener('DOMContentLoaded', enhanceAccessibility);

console.log('trAIn Questionnaire App loaded - ready for initialization');