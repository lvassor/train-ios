/**
 * trAIn Questionnaire - Streamlined MVP Version
 * Handles: Email flow -> 6-step questionnaire -> Loading -> Success -> Program generation
 */

// ============================================================================
// STATE MANAGEMENT
// ============================================================================
let currentStep = 1;
const totalSteps = 8;

const formData = {
    firstName: '',
    lastName: '',
    email: '',
    emailOptOut: false,
    experience: '',
    whyUsingApp: [],
    equipmentAvailable: [],
    equipmentConfidence: {},
    trainingDays: 3,
    sessionDuration: 60
};

const equipmentLabels = {
    dumbbells: { icon: '🏋️‍♀️', label: 'Dumbbells' },
    barbells: { icon: '🏋️', label: 'Barbells' },
    pin_loaded_machines: { icon: '🗿', label: 'Pin-loaded machines' },
    cable_machines: { icon: '🔌', label: 'Cable machines' }
};

const multipleChoiceFields = ['whyUsingApp', 'equipmentAvailable'];

// ============================================================================
// INITIALIZATION
// ============================================================================
document.addEventListener('DOMContentLoaded', init);

function init() {
    loadUserData();
    attachEventListeners();
    createLoadingScreen();
    createSuccessScreen();
    updateProgress();
    showStep(currentStep);
}

function loadUserData() {
    // Load data from beta-landing form if it exists
    const betaUser = sessionStorage.getItem('betaUser');
    if (betaUser) {
        const userData = JSON.parse(betaUser);
        formData.firstName = userData.firstName || '';
        formData.lastName = userData.lastName || '';
        formData.email = userData.email || '';
        formData.emailOptOut = userData.emailOptOut || false;

        // Populate the form fields if they exist
        const firstNameField = document.getElementById('firstName');
        const lastNameField = document.getElementById('lastName');
        const emailField = document.getElementById('email');
        const emailOptOutField = document.getElementById('emailOptOut');

        if (firstNameField) firstNameField.value = formData.firstName;
        if (lastNameField) lastNameField.value = formData.lastName;
        if (emailField) emailField.value = formData.email;
        if (emailOptOutField) emailOptOutField.checked = formData.emailOptOut;
    }
}

function attachEventListeners() {
    // Option button clicks
    document.addEventListener('click', function (e) {
        if (e.target.closest('.option-button')) {
            handleOptionClick(e.target.closest('.option-button'));
        }
        if (e.target.id === 'start-logging-btn') {
            window.location.href = '/logger';
        }
    });

    // Form inputs
    document.addEventListener('input', function (e) {
        if (e.target.matches('.slider')) {
            handleSliderInput(e.target);
        }
        if (e.target.matches('.confidence-slider')) {
            handleConfidenceSlider(e.target);
        }
        if (e.target.matches('#firstName, #lastName, #email')) {
            handleTextInput(e.target);
        }
        if (e.target.matches('#emailOptOut')) {
            formData.emailOptOut = e.target.checked;
        }
    });

    // Input validation on blur
    document.addEventListener('blur', function (e) {
        if (e.target.matches('#firstName, #lastName, #email')) {
            validateField(e.target.id);
        }
    }, true);

    // Clear errors on input
    document.addEventListener('input', function (e) {
        if (e.target.matches('#firstName, #lastName, #email')) {
            clearError(e.target.id);
        }
    });

    // Navigation
    document.getElementById('prevBtn')?.addEventListener('click', goToPreviousStep);
    document.getElementById('nextBtn')?.addEventListener('click', goToNextStep);
}

// ============================================================================
// EVENT HANDLERS
// ============================================================================
function handleTextInput(input) {
    const field = input.id;
    const value = input.value.trim();
    formData[field] = value;
}
function handleOptionClick(button) {
    const field = button.dataset.field;
    const value = button.dataset.value;

    if (multipleChoiceFields.includes(field)) {
        // Multiple selection
        button.classList.toggle('selected');
        if (!formData[field]) formData[field] = [];
        
        if (button.classList.contains('selected')) {
            if (!formData[field].includes(value)) {
                formData[field].push(value);
            }
        } else {
            formData[field] = formData[field].filter(v => v !== value);
        }
        
        if (field === 'equipmentAvailable') {
            generateConfidenceRatings();
        }
    } else {
        // Single selection
        button.closest('.step').querySelectorAll('.option-button').forEach(btn => 
            btn.classList.remove('selected')
        );
        button.classList.add('selected');
        formData[field] = value;
    }
}

function handleSliderInput(slider) {
    const field = slider.dataset.field;
    const value = parseInt(slider.value);
    formData[field] = value;
    
    if (field === 'trainingDays') {
        document.getElementById('trainingDaysValue').textContent = value;
    } else if (field === 'sessionDuration') {
        document.getElementById('sessionDurationValue').textContent = value;
    }
}

function handleConfidenceSlider(slider) {
    const equipment = slider.dataset.equipment;
    const value = parseInt(slider.value);
    
    if (!formData.equipmentConfidence) formData.equipmentConfidence = {};
    formData.equipmentConfidence[equipment] = value;
    
    const valueDisplay = document.getElementById(`confidence-value-${equipment}`);
    if (valueDisplay) {
        valueDisplay.textContent = getConfidenceText(value);
    }
}

// ============================================================================
// PROGRAM GENERATION
// ============================================================================
function generateProgramId(questionnaire) {
    const { experience, trainingDays } = questionnaire;
    
    let difficultyLevel = 'beginner';
    if (experience === '6_months_2_years' || experience === '2_plus_years') {
        difficultyLevel = 'intermediate';
    }
    
    return `${difficultyLevel}-${trainingDays}day`;
}

function generateProgramName(programId) {
    const programNames = {
        'beginner-2day': 'Beginner Full Body Foundation',
        'beginner-3day': 'Beginner Full Body Builder', 
        'beginner-4day': 'Beginner Upper/Lower Split',
        'intermediate-2day': 'Intermediate Full Body Power',
        'intermediate-3day': 'Intermediate Push/Pull/Legs',
        'intermediate-4day': 'Intermediate Upper/Lower Power'
    };
    
    return programNames[programId] || 'Custom Program';
}

// ============================================================================
// DYNAMIC CONTENT GENERATION
// ============================================================================
function generateConfidenceRatings() {
    const container = document.getElementById('confidenceContainer');
    if (!container) return;
    
    container.innerHTML = '';
    const selectedEquipment = formData.equipmentAvailable || [];
    
    selectedEquipment.forEach(equipmentKey => {
        const equipment = equipmentLabels[equipmentKey];
        if (!equipment) return;

        const div = document.createElement('div');
        div.className = 'confidence-item';
        div.innerHTML = `
            <div class="confidence-header">
                <span class="confidence-icon">${equipment.icon}</span>
                <span class="confidence-label">${equipment.label}</span>
            </div>
            <div class="confidence-slider-wrapper">
                <input type="range" class="confidence-slider" min="1" max="5" value="3" 
                       data-equipment="${equipmentKey}">
                <div class="confidence-labels">
                    <span>1</span><span>2</span><span>3</span><span>4</span><span>5</span>
                </div>
                <div class="confidence-value" id="confidence-value-${equipmentKey}">
                    Moderately confident
                </div>
            </div>
        `;
        container.appendChild(div);
        
        if (!formData.equipmentConfidence[equipmentKey]) {
            formData.equipmentConfidence[equipmentKey] = 3;
        }
    });
}

function getConfidenceText(value) {
    const texts = {
        1: 'Not confident', 2: 'Slightly confident', 3: 'Moderately confident',
        4: 'Very confident', 5: 'Extremely confident'
    };
    return texts[value] || 'Moderately confident';
}

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
    
    const lastStep = document.getElementById('step-6');
    if (lastStep) {
        lastStep.insertAdjacentHTML('afterend', loadingHTML);
    }
}

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
                
                <div style="background: linear-gradient(135deg, #eff6ff, #dbeafe); padding: 2rem; border-radius: 1rem; border: 2px solid #93c5fd; margin-bottom: 2rem;">
                    <h3 style="font-size: 1.5rem; font-weight: 700; color: #1e40af; margin-bottom: 1rem; text-align: center;">
                        🚀 Start logging your workouts
                    </h3>
                    <p style="color: #4b5563; text-align: center; margin-bottom: 1.5rem;">
                        Track your progress and see your strength gains with our smart logging system
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
                            <div style="font-size: 1.5rem; margin-bottom: 0.5rem;">🏆</div>
                            <div style="font-weight: 600; color: #374151;">Get Rewards</div>
                            <div style="font-size: 0.875rem; color: #6b7280;">Celebrate improvements</div>
                        </div>
                    </div>
                    <button class="btn btn-primary" style="width: 100%; padding: 1rem 2rem; font-size: 1.125rem;" id="start-logging-btn">
                        Start Logging Your Program
                    </button>
                </div>
                
                <div style="text-align: center; margin-top: 1rem;">
                    <p style="color: #6b7280; font-size: 0.875rem;">
                        Your program has been sent to your email and is ready to log!
                    </p>
                </div>
            </div>
        </div>
    `;
    
    const loadingStep = document.getElementById('step-loading');
    if (loadingStep) {
        loadingStep.insertAdjacentHTML('afterend', successHTML);
    }
}

// ============================================================================
// VALIDATION
// ============================================================================
function validateCurrentStep() {
    switch (currentStep) {
        case 1: return validateField('firstName') && validateField('lastName');
        case 2: return validateField('email');
        case 3: return !!formData.experience;
        case 4: return formData.whyUsingApp?.length > 0;
        case 5: return formData.equipmentAvailable?.length > 0;
        case 6:
            const selected = formData.equipmentAvailable || [];
            return selected.every(eq => formData.equipmentConfidence?.[eq]);
        case 7: return true;
        case 8: return true;
        default: return true;
    }
}

function validateField(fieldName) {
    const field = document.getElementById(fieldName);
    if (!field) return true;

    const value = field.value.trim();

    // Clear previous errors
    clearError(fieldName);

    // Validate based on field type
    switch (fieldName) {
        case 'firstName':
        case 'lastName':
            if (!value) {
                showError(fieldName, `${fieldName === 'firstName' ? 'First' : 'Last'} name is required`);
                return false;
            }
            if (value.length < 2) {
                showError(fieldName, 'Name must be at least 2 characters');
                return false;
            }
            if (!/^[a-zA-Z\s'-]+$/.test(value)) {
                showError(fieldName, 'Please enter a valid name');
                return false;
            }
            break;

        case 'email':
            if (!value) {
                showError(fieldName, 'Email is required');
                return false;
            }
            if (!isValidEmail(value)) {
                showError(fieldName, 'Please enter a valid email address');
                return false;
            }
            break;
    }

    return true;
}

function isValidEmail(email) {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
}

function showError(fieldName, message) {
    const errorElement = document.getElementById(`${fieldName}-error`);
    const field = document.getElementById(fieldName);

    if (errorElement) {
        errorElement.textContent = message;
    }

    if (field) {
        field.style.borderColor = '#dc2626';
        field.style.boxShadow = '0 0 0 3px rgba(220, 38, 38, 0.1)';
    }
}

function clearError(fieldName) {
    const errorElement = document.getElementById(`${fieldName}-error`);
    const field = document.getElementById(fieldName);

    if (errorElement) {
        errorElement.textContent = '';
    }

    if (field) {
        field.style.borderColor = '';
        field.style.boxShadow = '';
    }
}

// ============================================================================
// NAVIGATION
// ============================================================================
function goToNextStep() {
    if (!validateCurrentStep()) {
        alert('Please complete this step before continuing');
        return;
    }

    if (currentStep < totalSteps) {
        currentStep++;
        showStep(currentStep);
        updateProgress();
    } else {
        submitQuestionnaire();
    }
}

function goToPreviousStep() {
    if (currentStep > 1) {
        currentStep--;
        showStep(currentStep);
        updateProgress();
    }
}

function showStep(stepNumber) {
    document.querySelectorAll('.step').forEach(step => {
        step.classList.add('hidden');
        step.classList.remove('active');
    });
    
    const targetStep = document.getElementById(`step-${stepNumber}`);
    if (targetStep) {
        targetStep.classList.remove('hidden');
        targetStep.classList.add('active');
    }

    if (stepNumber === 6) {
        generateConfidenceRatings();
    }

    updateNavigationButtons();
}

function updateNavigationButtons() {
    const prevBtn = document.getElementById('prevBtn');
    const nextBtn = document.getElementById('nextBtn');
    
    if (prevBtn) {
        prevBtn.classList.toggle('hidden', currentStep === 1);
    }
    
    if (nextBtn) {
        nextBtn.textContent = currentStep === totalSteps ? 'Generate My Program' : 'Next';
    }
}

function updateProgress() {
    const percentage = (currentStep / totalSteps) * 100;
    const progressBar = document.getElementById('progressBar');
    const stepText = document.getElementById('currentStepText');
    const percentageText = document.getElementById('progressPercentage');

    if (progressBar) progressBar.style.width = `${percentage}%`;
    if (stepText) stepText.textContent = currentStep;
    if (percentageText) percentageText.textContent = Math.round(percentage);
}

// ============================================================================
// PROGRAM SUBMISSION
// ============================================================================
async function submitQuestionnaire() {
    try {
        const programId = generateProgramId(formData);
        const programName = generateProgramName(programId);
        
        const programData = {
            id: programId,
            name: programName,
            frequency: formData.trainingDays,
            duration: formData.sessionDuration,
            experience: formData.experience,
            generatedAt: new Date().toISOString(),
            userEmail: formData.email
        };
        
        sessionStorage.setItem('userProgram', JSON.stringify(programData));

        // Update user data in session
        sessionStorage.setItem('betaUser', JSON.stringify({
            firstName: formData.firstName,
            lastName: formData.lastName,
            email: formData.email,
            emailOptOut: formData.emailOptOut
        }));
        sessionStorage.setItem('userEmail', formData.email);
        sessionStorage.setItem('userName', `${formData.firstName} ${formData.lastName}`);
        
        showLoadingScreen();
        simulateLoadingAnimation();
        
        // Submit to backend
        const response = await fetch('/api/submit-questionnaire', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                questionnaire: formData,
                program: programData,
                timestamp: new Date().toISOString()
            })
        });

        const result = await response.json();
        
        // Show success after loading animation
        setTimeout(() => {
            showSuccessScreen();
        }, 6500);

    } catch (error) {
        console.error('Submission error:', error);
        // Still show success screen for MVP
        setTimeout(() => {
            showSuccessScreen();
        }, 6500);
    }
}

function showLoadingScreen() {
    document.querySelectorAll('.step').forEach(step => {
        step.classList.remove('active');
        step.classList.add('hidden');
    });

    const loadingStep = document.getElementById('step-loading');
    if (loadingStep) {
        loadingStep.classList.remove('hidden');
        loadingStep.classList.add('active');
    }

    document.getElementById('navigationButtons')?.classList.add('hidden');
    
    const progressBar = document.getElementById('progressBar');
    const progressPercentage = document.getElementById('progressPercentage');
    if (progressBar) progressBar.style.width = '100%';
    if (progressPercentage) progressPercentage.textContent = '100';
}

function simulateLoadingAnimation() {
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
            
            const progress = ((currentLoadingStep + 1) / loadingSteps.length) * 100;
            if (loadingBar) loadingBar.style.width = `${progress}%`;
            if (loadingText) loadingText.textContent = step.text;
            
            // Mark previous step as completed
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
            
            if (loadingText) loadingText.textContent = "Program ready!";
        }
    }

    updateLoadingStep();
}

function showSuccessScreen() {
    const loadingStep = document.getElementById('step-loading');
    if (loadingStep) {
        loadingStep.classList.add('hidden');
        loadingStep.classList.remove('active');
    }

    const successStep = document.getElementById('step-success');
    if (successStep) {
        successStep.classList.remove('hidden');
        successStep.classList.add('active');
    }
}