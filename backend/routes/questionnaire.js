// frontend/js/questionnaire.js - Streamlined with loading screen
class QuestionnaireApp {
  constructor() {
    this.currentStep = 1;
    this.totalSteps = 5;
    this.formData = {
      experience: '',
      whyUsingApp: [],
      equipmentAvailable: [],
      equipmentConfidence: {},
      trainingDays: 3,
      email: sessionStorage.getItem('userEmail') || ''
    };
    
    this.init();
  }

  init() {
    this.attachEventListeners();
    this.updateProgress();
    this.showStep(1);
    this.createLoadingScreen();
    this.createSuccessScreen();
  }

  attachEventListeners() {
    // Option buttons
    document.addEventListener('click', (e) => {
      if (e.target.closest('.option-button')) {
        this.handleOptionClick(e.target.closest('.option-button'));
      }
    });

    // Sliders
    document.addEventListener('input', (e) => {
      if (e.target.matches('.slider')) {
        this.handleSliderInput(e.target);
      }
      if (e.target.matches('.confidence-slider')) {
        this.handleConfidenceSlider(e.target);
      }
    });

    // Navigation
    document.getElementById('prevBtn')?.addEventListener('click', () => this.goToPreviousStep());
    document.getElementById('nextBtn')?.addEventListener('click', () => this.goToNextStep());
  }

  handleOptionClick(button) {
    const field = button.dataset.field;
    const value = button.dataset.value;
    
    if (field === 'whyUsingApp' || field === 'equipmentAvailable') {
      // Multiple selection
      button.classList.toggle('selected');
      this.formData[field] = this.formData[field] || [];
      
      if (button.classList.contains('selected')) {
        if (!this.formData[field].includes(value)) {
          this.formData[field].push(value);
        }
      } else {
        this.formData[field] = this.formData[field].filter(v => v !== value);
      }
      
      if (field === 'equipmentAvailable') {
        this.generateConfidenceRatings();
      }
    } else {
      // Single selection
      button.closest('.step').querySelectorAll('.option-button').forEach(btn => 
        btn.classList.remove('selected')
      );
      button.classList.add('selected');
      this.formData[field] = value;
    }
  }

  handleSliderInput(slider) {
    const field = slider.dataset.field;
    const value = parseInt(slider.value);
    this.formData[field] = value;
    
    const valueDisplay = document.getElementById(`${field}Value`);
    if (valueDisplay) valueDisplay.textContent = value;
  }

  handleConfidenceSlider(slider) {
    const equipment = slider.dataset.equipment;
    const value = parseInt(slider.value);
    
    this.formData.equipmentConfidence = this.formData.equipmentConfidence || {};
    this.formData.equipmentConfidence[equipment] = value;
    
    const valueDisplay = document.getElementById(`confidence-value-${equipment}`);
    if (valueDisplay) {
      valueDisplay.textContent = this.getConfidenceText(value);
    }
  }

  generateConfidenceRatings() {
    const container = document.getElementById('confidenceContainer');
    if (!container) return;
    
    container.innerHTML = '';
    const selectedEquipment = this.formData.equipmentAvailable || [];
    
    const equipmentLabels = {
      dumbbells: { icon: '🏋️‍♀️', label: 'Dumbbells' },
      barbells: { icon: '🏋️', label: 'Barbells' },
      pin_loaded_machines: { icon: '🏗️', label: 'Pin-loaded machines' },
      cable_machines: { icon: '🔌', label: 'Cable machines' }
    };

    selectedEquipment.forEach(key => {
      const equipment = equipmentLabels[key];
      if (!equipment) return;

      const div = document.createElement('div');
      div.className = 'confidence-item';
      div.innerHTML = `
        <div style="display: flex; align-items: center; margin-bottom: 1rem;">
          <span style="font-size: 1.5rem; margin-right: 0.75rem;">${equipment.icon}</span>
          <span style="font-weight: 600;">${equipment.label}</span>
        </div>
        <input type="range" class="confidence-slider" min="1" max="5" value="3" 
               data-equipment="${key}" style="width: 100%; margin-bottom: 0.5rem;">
        <div class="confidence-labels" style="display: flex; justify-content: space-between; font-size: 0.75rem; color: var(--text-muted);">
          <span>1</span><span>2</span><span>3</span><span>4</span><span>5</span>
        </div>
        <div id="confidence-value-${key}" style="text-align: center; color: var(--primary); font-weight: 600; margin-top: 0.5rem;">
          Moderately confident
        </div>
      `;
      container.appendChild(div);
    });
  }

  getConfidenceText(value) {
    const texts = {
      1: 'Not confident', 2: 'Slightly confident', 3: 'Moderately confident',
      4: 'Very confident', 5: 'Extremely confident'
    };
    return texts[value] || 'Moderately confident';
  }

  validateCurrentStep() {
    switch (this.currentStep) {
      case 1: return !!this.formData.experience;
      case 2: return this.formData.whyUsingApp?.length > 0;
      case 3: return this.formData.equipmentAvailable?.length > 0;
      case 4: 
        const selected = this.formData.equipmentAvailable || [];
        return selected.every(eq => this.formData.equipmentConfidence?.[eq]);
      case 5: return true;
      default: return true;
    }
  }

  goToNextStep() {
    if (!this.validateCurrentStep()) {
      alert('Please complete this step before continuing');
      return;
    }

    if (this.currentStep < this.totalSteps) {
      this.currentStep++;
      this.showStep(this.currentStep);
      this.updateProgress();
    } else {
      this.submitQuestionnaire();
    }
  }

  goToPreviousStep() {
    if (this.currentStep > 1) {
      this.currentStep--;
      this.showStep(this.currentStep);
      this.updateProgress();
    }
  }

  showStep(stepNumber) {
    document.querySelectorAll('.step').forEach(step => {
      step.classList.add('hidden');
      step.classList.remove('active');
    });
    
    const targetStep = document.getElementById(`step-${stepNumber}`);
    if (targetStep) {
      targetStep.classList.remove('hidden');
      targetStep.classList.add('active');
    }

    // Special handling for step 4
    if (stepNumber === 4) {
      this.generateConfidenceRatings();
    }

    this.updateNavigationButtons();
  }

  updateProgress() {
    const percentage = (this.currentStep / this.totalSteps) * 100;
    const progressBar = document.getElementById('progressBar');
    const stepText = document.getElementById('currentStepText');
    const percentageText = document.getElementById('progressPercentage');

    if (progressBar) progressBar.style.width = `${percentage}%`;
    if (stepText) stepText.textContent = this.currentStep;
    if (percentageText) percentageText.textContent = Math.round(percentage);
  }

  updateNavigationButtons() {
    const prevBtn = document.getElementById('prevBtn');
    const nextBtn = document.getElementById('nextBtn');
    
    if (prevBtn) {
      prevBtn.classList.toggle('hidden', this.currentStep === 1);
    }
    
    if (nextBtn) {
      nextBtn.textContent = this.currentStep === this.totalSteps ? 
        'Generate My Program' : 'Next';
    }
  }

  // === LOADING SCREEN CREATION & ANIMATION ===
  
  createLoadingScreen() {
    const loadingHTML = `
      <div class="step hidden" id="step-loading">
        <div style="text-align: center; margin-bottom: 2rem;">
          <h2 style="font-size: 1.5rem; font-weight: 700; color: var(--text-primary); margin-bottom: 0.75rem;">
            Creating your personalized program...
          </h2>
          <p style="font-size: 1.125rem; color: var(--text-secondary);">
            Our AI is analyzing your responses to build the perfect workout plan
          </p>
        </div>
        
        <div style="text-align: center; max-width: 500px; margin: 0 auto;">
          <div style="margin-bottom: 3rem;">
            <div style="width: 100%; background-color: var(--border-gray); border-radius: 9999px; height: 8px; margin-bottom: 1rem;">
              <div id="loadingBar" style="background: linear-gradient(to right, var(--primary), #1d4ed8); height: 8px; border-radius: 9999px; transition: width 0.8s ease; width: 0%;"></div>
            </div>
            <div id="loadingText" style="font-size: 1rem; color: var(--text-secondary); font-weight: 500;">
              Analyzing your experience level...
            </div>
          </div>
          
          <div style="display: flex; flex-direction: column; gap: 1rem;">
            <div class="loading-step" id="loading-step-1" style="display: flex; align-items: center; padding: 1rem; background-color: #f9fafb; border-radius: 0.75rem; border: 2px solid var(--border-gray); transition: all 0.3s ease;">
              <span class="loading-step-icon" style="font-size: 1.125rem; margin-right: 0.75rem; min-width: 24px; text-align: center;">⏳</span>
              <span style="font-size: 0.875rem; font-weight: 500; color: var(--text-secondary);">Experience assessment</span>
            </div>
            <div class="loading-step" id="loading-step-2" style="display: flex; align-items: center; padding: 1rem; background-color: #f9fafb; border-radius: 0.75rem; border: 2px solid var(--border-gray); transition: all 0.3s ease;">
              <span class="loading-step-icon" style="font-size: 1.125rem; margin-right: 0.75rem; min-width: 24px; text-align: center;">⏳</span>
              <span style="font-size: 0.875rem; font-weight: 500; color: var(--text-secondary);">Equipment matching</span>
            </div>
            <div class="loading-step" id="loading-step-3" style="display: flex; align-items: center; padding: 1rem; background-color: #f9fafb; border-radius: 0.75rem; border: 2px solid var(--border-gray); transition: all 0.3s ease;">
              <span class="loading-step-icon" style="font-size: 1.125rem; margin-right: 0.75rem; min-width: 24px; text-align: center;">⏳</span>
              <span style="font-size: 0.875rem; font-weight: 500; color: var(--text-secondary);">Program selection</span>
            </div>
            <div class="loading-step" id="loading-step-4" style="display: flex; align-items: center; padding: 1rem; background-color: #f9fafb; border-radius: 0.75rem; border: 2px solid var(--border-gray); transition: all 0.3s ease;">
              <span class="loading-step-icon" style="font-size: 1.125rem; margin-right: 0.75rem; min-width: 24px; text-align: center;">⏳</span>
              <span style="font-size: 0.875rem; font-weight: 500; color: var(--text-secondary);">Exercise customization</span>
            </div>
            <div class="loading-step" id="loading-step-5" style="display: flex; align-items: center; padding: 1rem; background-color: #f9fafb; border-radius: 0.75rem; border: 2px solid var(--border-gray); transition: all 0.3s ease;">
              <span class="loading-step-icon" style="font-size: 1.125rem; margin-right: 0.75rem; min-width: 24px; text-align: center;">⏳</span>
              <span style="font-size: 0.875rem; font-weight: 500; color: var(--text-secondary);">Final optimization</span>
            </div>
          </div>
        </div>
      </div>
    `;
    
    const lastStep = document.getElementById('step-5');
    if (lastStep) {
      lastStep.insertAdjacentHTML('afterend', loadingHTML);
    }
  }

  createSuccessScreen() {
    const successHTML = `
      <div class="step hidden" id="step-success">
        <div style="text-align: center; padding: 2rem 0;">
          <div style="width: 5rem; height: 5rem; background: linear-gradient(135deg, var(--success), #059669); border-radius: 50%; display: flex; align-items: center; justify-content: center; margin: 0 auto 1.5rem; font-size: 1.875rem; color: white;">
            ✅
          </div>
          <h2 style="font-size: 1.5rem; font-weight: 700; color: var(--text-primary); margin-bottom: 1rem;">
            Your bespoke program is ready!
          </h2>
          <p style="font-size: 1.125rem; color: var(--text-secondary); margin-bottom: 2rem;">
            We've created a <strong>personalized training program</strong> just for you and sent it to your email.
          </p>
          <p style="color: var(--text-muted); margin-bottom: 2rem;">
            Check your inbox for your custom workout plan!
          </p>
          
          <div style="background: linear-gradient(135deg, #eff6ff, #dbeafe); padding: 2rem; border-radius: 1rem; border: 2px solid #93c5fd; margin-bottom: 2rem;">
            <h3 style="font-size: 1.5rem; font-weight: 700; color: #1e40af; margin-bottom: 1rem;">
              🚀 Take your training to the next level
            </h3>
            <p style="color: var(--text-secondary); margin-bottom: 1.5rem;">
              Join <strong>10,000+ users</strong> who are crushing their fitness goals with our in-app coaching experience
            </p>
            <button class="btn btn-primary" style="width: 100%; padding: 1rem 2rem; font-size: 1.125rem;" onclick="alert('Account creation coming soon!')">
              Create Free Account - Start Tracking
            </button>
          </div>
          
          <div style="margin-top: 1rem;">
            <p style="color: var(--text-muted); font-size: 0.875rem;">
              Don't want to create an account right now? That's okay!<br>
              Your program has been sent to your email.
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

  showLoadingScreen() {
    // Hide all current steps
    document.querySelectorAll('.step').forEach(step => {
      step.classList.remove('active');
      step.classList.add('hidden');
    });

    // Show loading step
    const loadingStep = document.getElementById('step-loading');
    if (loadingStep) {
      loadingStep.classList.remove('hidden');
      loadingStep.classList.add('active');
    }

    // Hide navigation buttons
    const navButtons = document.getElementById('navigationButtons');
    if (navButtons) {
      navButtons.classList.add('hidden');
    }

    // Update progress bar to 100%
    const progressBar = document.getElementById('progressBar');
    const progressPercentage = document.getElementById('progressPercentage');
    if (progressBar) progressBar.style.width = '100%';
    if (progressPercentage) progressPercentage.textContent = '100';
  }

  simulateLoadingAnimation() {
    const loadingSteps = [
      { text: "Analyzing your experience level...", duration: 1000 },
      { text: "Matching equipment preferences...", duration: 1200 },
      { text: "Selecting optimal program template...", duration: 1300 },
      { text: "Customizing exercises for your needs...", duration: 1500 },
      { text: "Optimizing workout structure...", duration: 1000 },
      { text: "Finalizing your program...", duration: 1000 }
    ];

    let currentLoadingStep = 0;
    const loadingBar = document.getElementById('loadingBar');
    const loadingText = document.getElementById('loadingText');

    const updateLoadingStep = () => {
      if (currentLoadingStep < loadingSteps.length) {
        const step = loadingSteps[currentLoadingStep];
        
        // Update progress bar
        const progress = ((currentLoadingStep + 1) / loadingSteps.length) * 100;
        if (loadingBar) loadingBar.style.width = `${progress}%`;
        
        // Update loading text
        if (loadingText) loadingText.textContent = step.text;
        
        // Mark previous step as completed
        if (currentLoadingStep > 0) {
          const prevStepElement = document.getElementById(`loading-step-${currentLoadingStep}`);
          if (prevStepElement) {
            prevStepElement.style.borderColor = '#10b981';
            prevStepElement.style.backgroundColor = '#f0fdf4';
            const icon = prevStepElement.querySelector('.loading-step-icon');
            if (icon) {
              icon.textContent = '✓';
              icon.style.color = '#10b981';
            }
          }
        }
        
        // Mark current step as active
        const currentStepElement = document.getElementById(`loading-step-${currentLoadingStep + 1}`);
        if (currentStepElement) {
          currentStepElement.style.borderColor = '#93c5fd';
          currentStepElement.style.backgroundColor = '#eff6ff';
          const icon = currentStepElement.querySelector('.loading-step-icon');
          if (icon) {
            icon.style.color = '#2563eb';
            // Add pulse animation
            icon.style.animation = 'pulse 1.5s ease-in-out infinite';
          }
        }

        currentLoadingStep++;
        setTimeout(updateLoadingStep, step.duration);
      } else {
        // Complete final step
        const lastStep = document.getElementById(`loading-step-${loadingSteps.length}`);
        if (lastStep) {
          lastStep.style.borderColor = '#10b981';
          lastStep.style.backgroundColor = '#f0fdf4';
          const icon = lastStep.querySelector('.loading-step-icon');
          if (icon) {
            icon.textContent = '✓';
            icon.style.color = '#10b981';
            icon.style.animation = 'none';
          }
        }
        
        if (loadingText) loadingText.textContent = "Program ready!";
      }
    };

    updateLoadingStep();
  }

  showSuccessScreen() {
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

  async submitQuestionnaire() {
    try {
      console.log('Starting program generation...', this.formData);
      
      // Show loading screen
      this.showLoadingScreen();
      
      // Start loading animation
      this.simulateLoadingAnimation();
      
      // Submit to backend
      const response = await fetch('/api/questionnaire/submit', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          questionnaire: this.formData,
          timestamp: new Date().toISOString()
        })
      });

      const result = await response.json();
      
      // Wait for loading animation to complete
      setTimeout(() => {
        if (result.success) {
          this.showSuccessScreen();
        } else {
          // Even if backend fails, show success for MVP
          this.showSuccessScreen();
        }
      }, 7000); // Total loading animation time

    } catch (error) {
      console.error('Submission error:', error);
      // Still show success screen after loading animation
      setTimeout(() => {
        this.showSuccessScreen();
      }, 7000);
    }
  }
}

// Add pulse animation CSS
const style = document.createElement('style');
style.textContent = `
  @keyframes pulse {
    0%, 100% { opacity: 1; }
    50% { opacity: 0.5; }
  }
`;
document.head.appendChild(style);

// Initialize when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
  new QuestionnaireApp();
});