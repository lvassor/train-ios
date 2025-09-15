// trAIn Questionnaire App - Complete JavaScript with Program Generation

// Load program templates from external file or use embedded data
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

// State management
let currentStep = 1;
const totalSteps = 6; // Updated to 6 steps
const formData = {
    experience: '',
    whyUsingApp: [], // Multiple choice
    equipmentAvailable: [], // Multiple choice
    equipmentConfidence: {}, // Object to store confidence ratings
    trainingDays: 3, // Slider value
    firstName: '',
    lastName: '',
    email: '',
    additionalInfo: ''
};

// Equipment mapping for confidence ratings
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
        icon: '🏗️',
        label: 'Pin-loaded machines'
    },
    cable_machines: {
        icon: '🔌',
        label: 'Cable machines'
    }
};

// Multiple choice fields
const multipleChoiceFields = ['whyUsingApp', 'equipmentAvailable'];

// DOM elements cache
const elements = {
    progressBar: null,
    currentStepText: null,
    progressPercentage: null,
    prevBtn: null,
    nextBtn: null,
    navigationButtons: null
};

// Initialize the form when DOM is loaded
document.addEventListener('DOMContentLoaded', function () {
    init();
});

// Initialize the form
function init() {
    cacheElements();
    updateProgress();
    attachEventListeners();
    createLoadingScreen();
    createProgramDisplayScreen();
}

// Cache DOM elements for better performance
function cacheElements() {
    elements.progressBar = document.getElementById('progressBar');
    elements.currentStepText = document.getElementById('currentStepText');
    elements.progressPercentage = document.getElementById('progressPercentage');
    elements.prevBtn = document.getElementById('prevBtn');
    elements.nextBtn = document.getElementById('nextBtn');
    elements.navigationButtons = document.getElementById('navigationButtons');
}

// Create loading screen
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
                    <div class="loading-step completed" id="loading-step-1">
                        <span class="loading-step-icon">✓</span>
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
    
    // Insert loading screen after the last step
    const lastStep = document.getElementById('step-6');
    lastStep.insertAdjacentHTML('afterend', loadingHTML);
}

// Create program display screen
function createProgramDisplayScreen() {
    const programHTML = `
        <div class="step hidden" id="step-program">
            <div class="question-container">
                <h2 class="question-title" id="programTitle">Your Personalized Training Program</h2>
                <p class="question-subtitle" id="programDescription">Here's your custom workout plan based on your responses</p>
            </div>
            
            <div class="program-overview" id="programOverview">
                <!-- Program summary will be populated here -->
            </div>
            
            <div class="program-workouts" id="programWorkouts">
                <!-- Workout cards will be populated here -->
            </div>
            
            <div class="program-actions">
                <button class="btn btn-primary" onclick="downloadProgram()">Download PDF</button>
                <button class="btn btn-secondary" onclick="emailProgram()">Email Program</button>
            </div>
        </div>
    `;
    
    // Insert program screen after loading screen
    const loadingStep = document.getElementById('step-loading');
    loadingStep.insertAdjacentHTML('afterend', programHTML);
}

// Event listeners
function attachEventListeners() {
    // Option button clicks
    document.addEventListener('click', function (e) {
        if (e.target.closest('.option-button')) {
            handleOptionClick(e.target.closest('.option-button'));
        }
    });

    // Form input changes
    document.addEventListener('input', function (e) {
        if (e.target.matches('.form-input')) {
            handleFormInput(e.target);
        }

        // Handle slider inputs
        if (e.target.matches('.slider')) {
            handleSliderInput(e.target);
        }

        // Handle confidence sliders
        if (e.target.matches('.confidence-slider')) {
            handleConfidenceSlider(e.target);
        }
    });

    // Navigation buttons
    elements.prevBtn.addEventListener('click', goToPreviousStep);
    elements.nextBtn.addEventListener('click', goToNextStep);
}

// Handle option selection
function handleOptionClick(button) {
    const field = button.dataset.field;
    const value = button.dataset.value;

    // Clear errors
    clearError(field);

    if (multipleChoiceFields.includes(field)) {
        // Multiple selection
        handleMultipleSelection(button, field, value);
    } else {
        // Single selection
        handleSingleSelection(button, field, value);
    }
}

// Handle single selection
function handleSingleSelection(button, field, value) {
    // Remove selected class from all buttons in this step
    const stepButtons = button.closest('.step').querySelectorAll('.option-button');
    stepButtons.forEach(btn => btn.classList.remove('selected'));

    // Add selected class to clicked button
    button.classList.add('selected');

    // Update form data
    formData[field] = value;
}

// Handle multiple selection
function handleMultipleSelection(button, field, value) {
    button.classList.toggle('selected');

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

// Handle form input
function handleFormInput(input) {
    const field = input.id;
    formData[field] = input.value;
    clearError(field);
}

// Handle slider input
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

// Handle confidence slider
function handleConfidenceSlider(slider) {
    const equipment = slider.dataset.equipment;
    const value = parseInt(slider.value);

    // Store confidence rating
    formData.equipmentConfidence[equipment] = value;

    // Update display value
    const valueDisplay = document.getElementById(`confidence-value-${equipment}`);
    if (valueDisplay) {
        const confidenceTexts = ['', 'Not confident', 'Slightly confident', 'Moderately confident', 'Very confident', 'Extremely confident'];
        valueDisplay.textContent = confidenceTexts[value];
    }
}

// Generate confidence rating sliders based on selected equipment
function generateConfidenceRatings() {
    const container = document.getElementById('confidenceContainer');
    if (!container) return;

    // Clear existing content
    container.innerHTML = '';

    // Get selected equipment
    const selectedEquipment = formData.equipmentAvailable || [];

    if (selectedEquipment.length === 0) {
        container.innerHTML = '<p class="text-gray-500 text-center">Please select equipment in the previous step first.</p>';
        return;
    }

    // Create confidence sliders for each selected equipment
    selectedEquipment.forEach(equipmentKey => {
        const equipment = equipmentLabels[equipmentKey];
        if (!equipment) return;

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

// Get confidence text based on value
function getConfidenceText(value) {
    const confidenceTexts = ['', 'Not confident', 'Slightly confident', 'Moderately confident', 'Very confident', 'Extremely confident'];
    return confidenceTexts[value] || 'Moderately confident';
}

// Validation
function validateCurrentStep() {
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
            return true; // Slider always has a value
        case 6:
            return validateContactForm();
        default:
            return true;
    }
}

// Validate equipment confidence ratings
function validateEquipmentConfidence() {
    const selectedEquipment = formData.equipmentAvailable || [];

    if (selectedEquipment.length === 0) {
        showError('equipmentConfidence', 'Please rate your confidence for each piece of equipment');
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

// Validate single field
function validateField(fieldName, errorMessage) {
    if (!formData[fieldName]) {
        showError(fieldName, errorMessage);
        return false;
    }
    return true;
}

// Validate array field (multiple selections)
function validateArrayField(fieldName, errorMessage) {
    if (!formData[fieldName] || formData[fieldName].length === 0) {
        showError(fieldName, errorMessage);
        return false;
    }
    return true;
}

// Validate contact form
function validateContactForm() {
    let isValid = true;

    // First name validation
    if (!formData.firstName || formData.firstName.trim() === '') {
        showError('firstName', 'First name is required');
        isValid = false;
    }

    // Last name validation
    if (!formData.lastName || formData.lastName.trim() === '') {
        showError('lastName', 'Last name is required');
        isValid = false;
    }

    // Email validation
    if (!formData.email || formData.email.trim() === '') {
        showError('email', 'Email address is required');
        isValid = false;
    } else if (!isValidEmail(formData.email)) {
        showError('email', 'Please enter a valid email address');
        isValid = false;
    }

    return isValid;
}

// Email validation helper
function isValidEmail(email) {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
}

// Show error message
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
}

// Clear specific error
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

// Clear all errors
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

// Navigation functions
function goToNextStep() {
    if (validateCurrentStep()) {
        if (currentStep < totalSteps) {
            currentStep++;
            showStep(currentStep);
            updateProgress();
        } else {
            // Final step - submit form
            submitForm();
        }
    }
}

function goToPreviousStep() {
    if (currentStep > 1) {
        currentStep--;
        showStep(currentStep);
        updateProgress();
    }
}

// Show specific step
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
    }

    // Special handling for step 4 (confidence ratings)
    if (stepNumber === 4) {
        generateConfidenceRatings();
    }

    // Update navigation buttons
    updateNavigationButtons();
}

// Update navigation button text
function updateNavigationButtons() {
    const isFirstStep = currentStep === 1;
    const isLastStep = currentStep === totalSteps;

    // Previous button
    if (isFirstStep) {
        elements.prevBtn.classList.add('hidden');
    } else {
        elements.prevBtn.classList.remove('hidden');
    }

    // Next button text
    if (isLastStep) {
        elements.nextBtn.textContent = 'Generate My Program';
    } else {
        elements.nextBtn.textContent = 'Next';
    }
}

// Update progress bar
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

// Enhanced submit form with loading and program generation
function submitForm() {
    console.log('Form submission data:', formData);
    
    // Show loading screen
    showLoadingScreen();
    
    // Submit questionnaire to backend and generate program
    submitQuestionnaireAndGenerateProgram();
}

// Show loading screen with animated progress
function showLoadingScreen() {
    // Hide current step
    const allSteps = document.querySelectorAll('.step');
    allSteps.forEach(step => {
        step.classList.remove('active');
        step.classList.add('hidden');
    });

    // Show loading step
    const loadingStep = document.getElementById('step-loading');
    loadingStep.classList.remove('hidden');
    loadingStep.classList.add('active');

    // Hide navigation buttons
    elements.navigationButtons.classList.add('hidden');

    // Update main progress bar to 100%
    if (elements.progressBar) {
        elements.progressBar.style.width = '100%';
    }
    if (elements.progressPercentage) {
        elements.progressPercentage.textContent = '100';
    }
}

// Submit questionnaire and generate program
async function submitQuestionnaireAndGenerateProgram() {
    try {
        // Start loading animation
        simulateProgramGeneration();
        
        // Submit questionnaire to backend
        const response = await fetch('http://localhost:3001/api/questionnaire/submit', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify(formData)
        });

        if (!response.ok) {
            throw new Error('Failed to submit questionnaire');
        }

        const result = await response.json();
        console.log('Questionnaire submitted:', result);

        // Generate program using backend API
        const programResponse = await fetch('http://localhost:3001/api/programs/generate', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify(formData)
        });

        if (!programResponse.ok) {
            throw new Error('Failed to generate program');
        }

        const program = await programResponse.json();
        console.log('Generated program:', program);

        // Wait for loading animation to complete, then show program
        setTimeout(() => {
            showProgramResults(program);
        }, 6500); // Total loading time

    } catch (error) {
        console.error('Error:', error);
        // Fallback to client-side program generation
        setTimeout(() => {
            const fallbackProgram = generateProgramClientSide(formData);
            showProgramResults(fallbackProgram);
        }, 6500);
    }
}

// Simulate program generation with realistic progress
function simulateProgramGeneration() {
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

    function updateLoadingStep() {
        if (currentLoadingStep < loadingSteps.length) {
            const step = loadingSteps[currentLoadingStep];
            
            // Update progress bar
            const progress = ((currentLoadingStep + 1) / loadingSteps.length) * 100;
            loadingBar.style.width = `${progress}%`;
            
            // Update text
            loadingText.textContent = step.text;
            
            // Update step indicators
            if (currentLoadingStep > 0) {
                const prevStepElement = document.getElementById(`loading-step-${currentLoadingStep}`);
                if (prevStepElement) {
                    prevStepElement.classList.add('completed');
                    prevStepElement.querySelector('.loading-step-icon').textContent = '✓';
                }
            }
            
            const currentStepElement = document.getElementById(`loading-step-${currentLoadingStep + 1}`);
            if (currentStepElement) {
                currentStepElement.classList.add('active');
                currentStepElement.querySelector('.loading-step-icon').textContent = '⏳';
            }

            currentLoadingStep++;
            setTimeout(updateLoadingStep, step.duration);
        } else {
            // Complete all steps
            const lastStep = document.getElementById(`loading-step-${loadingSteps.length}`);
            if (lastStep) {
                lastStep.classList.add('completed');
                lastStep.querySelector('.loading-step-icon').textContent = '✓';
            }
        }
    }

    updateLoadingStep();
}

// Client-side program generation (fallback)
function generateProgramClientSide(formData) {
    // Determine experience level for program selection
    const experienceMapping = {
        '0_months': 'beginner',
        '0_6_months': 'beginner', 
        '6_months_2_years': 'beginner',
        '2_plus_years': 'advanced'
    };

    const level = experienceMapping[formData.experience] || 'beginner';
    const days = formData.trainingDays;

    // Select appropriate program template
    let selectedTemplate;
    const templateKey = `${level}_${days}_day`;
    
    // Find matching template or fallback
    selectedTemplate = PROGRAM_TEMPLATES.programs.find(p => p.id === templateKey) ||
                     PROGRAM_TEMPLATES.programs.find(p => 
                         p.target_experience.includes(formData.experience) && 
                         p.frequency.includes(days)
                     ) ||
                     PROGRAM_TEMPLATES.programs[0]; // fallback

    // Create personalized program
    const program = {
        id: `custom_${Date.now()}`,
        name: selectedTemplate.name,
        description: selectedTemplate.description,
        duration_weeks: selectedTemplate.duration_weeks,
        frequency: days,
        user: {
            name: `${formData.firstName} ${formData.lastName}`,
            email: formData.email,
            experience: formData.experience,
            trainingDays: formData.trainingDays
        },
        workouts: selectedTemplate.workouts.slice(0, days), // Take only the number of days requested
        created_at: new Date().toISOString()
    };

    return program;
}

// Show program results
function showProgramResults(program) {
    // Hide loading screen
    const loadingStep = document.getElementById('step-loading');
    loadingStep.classList.add('hidden');
    loadingStep.classList.remove('active');

    // Show program step
    const programStep = document.getElementById('step-program');
    programStep.classList.remove('hidden');
    programStep.classList.add('active');

    // Populate program content
    populateProgramDisplay(program);
}

// Populate program display with workout cards
function populateProgramDisplay(program) {
    // Update title and description
    document.getElementById('programTitle').textContent = program.name;
    document.getElementById('programDescription').textContent = program.description;

    // Create program overview
    const overview = document.getElementById('programOverview');
    overview.innerHTML = `
        <div class="program-summary">
            <div class="summary-item">
                <span class="summary-label">Duration:</span>
                <span class="summary-value">${program.duration_weeks} weeks</span>
            </div>
            <div class="summary-item">
                <span class="summary-label">Frequency:</span>
                <span class="summary-value">${program.frequency} days per week</span>
            </div>
            <div class="summary-item">
                <span class="summary-label">Total Workouts:</span>
                <span class="summary-value">${program.workouts.length} different workouts</span>
            </div>
        </div>
    `;

    // Create workout cards
    const workoutsContainer = document.getElementById('programWorkouts');
    const columnClass = `workout-columns-${program.workouts.length}`;
    workoutsContainer.className = `program-workouts ${columnClass}`;

    workoutsContainer.innerHTML = program.workouts.map((workout, index) => `
        <div class="workout-card">
            <div class="workout-header">
                <h3 class="workout-title">${workout.name}</h3>
                <span class="workout-day">Day ${index + 1}</span>
            </div>
            <div class="workout-exercises">
                ${workout.exercises.map((exercise, exerciseIndex) => `
                    <div class="exercise-card">
                        <div class="exercise-header">
                            <span class="exercise-number">${exerciseIndex + 1}</span>
                            <span class="exercise-name">${exercise.name}</span>
                        </div>
                        <div class="exercise-details">
                            <div class="exercise-sets-reps">
                                <span class="sets">${exercise.sets} sets</span>
                                <span class="reps">${exercise.reps} reps</span>
                            </div>
                            <div class="exercise-rest">Rest: ${exercise.rest}</div>
                        </div>
                        ${exercise.notes ? `<div class="exercise-notes">${exercise.notes}</div>` : ''}
                    </div>
                `).join('')}
            </div>
        </div>
    `).join('');
}

// Download program function (placeholder)
function downloadProgram() {
    alert('Download functionality would be implemented here - generating PDF of your program');
}

// Email program function (placeholder)
function emailProgram() {
    alert('Email functionality would be implemented here - sending program to your email');
}

// Utility function to save form data to localStorage (optional)
function saveFormData() {
    try {
        localStorage.setItem('trAIn_questionnaire_data', JSON.stringify(formData));
        localStorage.setItem('trAIn_questionnaire_step', currentStep.toString());
    } catch (error) {
        console.warn('Could not save form data to localStorage:', error);
    }
}

// Utility function to load form data from localStorage (optional)
function loadFormData() {
    try {
        const savedData = localStorage.getItem('trAIn_questionnaire_data');
        const savedStep = localStorage.getItem('trAIn_questionnaire_step');

        if (savedData) {
            const parsedData = JSON.parse(savedData);
            Object.assign(formData, parsedData);
        }

        if (savedStep) {
            currentStep = parseInt(savedStep, 10) || 1;
        }

        // Restore form state
        restoreFormState();
    } catch (error) {
        console.warn('Could not load form data from localStorage:', error);
    }
}

// Restore form state from saved data
function restoreFormState() {
    // Restore button selections
    Object.keys(formData).forEach(field => {
        if (Array.isArray(formData[field])) {
            // Multiple selection fields
            formData[field].forEach(value => {
                const button = document.querySelector(`[data-field="${field}"][data-value="${value}"]`);
                if (button) {
                    button.classList.add('selected');
                }
            });
        } else if (formData[field]) {
            // Single selection fields
            const button = document.querySelector(`[data-field="${field}"][data-value="${formData[field]}"]`);
            if (button) {
                button.classList.add('selected');
            }

            // Input fields
            const input = document.getElementById(field);
            if (input) {
                input.value = formData[field];
            }
        }
    });
}

// Clear saved data (call this after successful submission)
function clearSavedData() {
    try {
        localStorage.removeItem('trAIn_questionnaire_data');
        localStorage.removeItem('trAIn_questionnaire_step');
    } catch (error) {
        console.warn('Could not clear saved data:', error);
    }
}

// Auto-save form data on changes (optional feature)
function enableAutoSave() {
    // Save data whenever form changes
    document.addEventListener('change', saveFormData);
    document.addEventListener('input', saveFormData);
}

// Initialize auto-save on load (uncomment if needed)
// enableAutoSave();

// Load saved data on initialization (uncomment if needed)
// loadFormData();