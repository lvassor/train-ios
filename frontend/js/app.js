// trAIn Questionnaire App - Complete JavaScript

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

// Submit form
function submitForm() {
    console.log('Form submission data:', formData);

    fetch('http://localhost:3001/api/questionnaire/submit', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify(formData)
    })
    showSuccessPage();
}

// Show success page
function showSuccessPage() {
    // Hide all steps
    const allSteps = document.querySelectorAll('.step');
    allSteps.forEach(step => {
        step.classList.remove('active');
        step.classList.add('hidden');
    });

    // Show success step
    const successStep = document.getElementById('step-success');
    if (successStep) {
        successStep.classList.remove('hidden');
        successStep.classList.add('active');
    }

    // Hide navigation buttons
    elements.navigationButtons.classList.add('hidden');

    // Update progress bar to 100%
    if (elements.progressBar) {
        elements.progressBar.style.width = '100%';
    }

    if (elements.progressPercentage) {
        elements.progressPercentage.textContent = '100';
    }
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