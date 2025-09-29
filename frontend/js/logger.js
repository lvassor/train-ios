// Workout Logger JavaScript - Complete Program Support with Enhanced Prompts

// State
let currentProgram = null;
let currentDay = null;
let workoutData = {};
let programs = {};
let dummyLogData = {};
let isDevMode = false;
let promptTimers = {}; // Store debounce timers for each exercise
let counterTimers = {}; // Store debounce timers for rep counters

// Initialize
document.addEventListener('DOMContentLoaded', init);

async function init() {
    await loadWorkoutTemplates();
    await loadDummyLogData();
    detectDevMode();
    detectUserProgram();
    attachEventListeners();

    if (isDevMode) {
        showProgramSelection();
    } else {
        showDaySelection();
    }
}

async function loadWorkoutTemplates() {
    try {
        const response = await fetch('/api/programs');
        programs = await response.json();
    } catch (error) {
        console.error('Could not load workout templates:', error);
        programs = {};
    }
}

async function loadDummyLogData() {
    try {
        const response = await fetch('/api/dummy-logs');
        dummyLogData = await response.json();
    } catch (error) {
        console.warn('Could not load dummy log data:', error);
        dummyLogData = {};
    }
}

function detectDevMode() {
    const urlParams = new URLSearchParams(window.location.search);
    isDevMode = urlParams.get('dev') === 'true' || window.location.pathname.includes('/dev/');
}

function detectUserProgram() {
    if (isDevMode) return;
    
    // Try sessionStorage first
    const storedProgram = JSON.parse(sessionStorage.getItem('userProgram') || 'null');
    if (storedProgram?.id) {
        currentProgram = storedProgram.id;
        return;
    }
    
    // Try URL params
    const urlParams = new URLSearchParams(window.location.search);
    const programFromUrl = urlParams.get('program');
    if (programFromUrl && programs[programFromUrl]) {
        currentProgram = programFromUrl;
        return;
    }
    
    // Fallback
    currentProgram = 'beginner-2day';
}

function attachEventListeners() {
    // Program selection (dev mode only)
    document.addEventListener('click', function(e) {
        if (e.target.matches('[data-program]')) {
            selectProgram(e.target.dataset.program);
        }
        if (e.target.matches('[data-day]')) {
            selectDay(e.target.dataset.day);
        }
    });

    // Navigation buttons
    document.getElementById('select-program-btn')?.addEventListener('click', showDaySelection);
    document.getElementById('back-to-programs')?.addEventListener('click', showProgramSelection);
    document.getElementById('start-workout-btn')?.addEventListener('click', startWorkout);
    document.getElementById('back-to-days')?.addEventListener('click', showDaySelection);
    document.getElementById('complete-workout-btn')?.addEventListener('click', completeWorkout);
    document.getElementById('log-another')?.addEventListener('click', () => {
        if (isDevMode) {
            showProgramSelection();
        } else {
            showDaySelection();
        }
    });

    // Summary button
    document.getElementById('continue-to-summary')?.addEventListener('click', showWorkoutSummary);
}

function selectProgram(programKey) {
    currentProgram = programKey;
    
    // Update UI
    document.querySelectorAll('[data-program]').forEach(btn => btn.classList.remove('selected'));
    document.querySelector(`[data-program="${programKey}"]`)?.classList.add('selected');
    document.getElementById('select-program-btn').disabled = false;
}

function showProgramSelection() {
    if (!isDevMode) return;
    
    hideAllSteps();
    document.getElementById('program-selection').classList.remove('hidden');
    
    // Populate program options if not already done
    const container = document.querySelector('#program-selection .options-container');
    if (container && container.children.length === 0) {
        Object.keys(programs).forEach(programKey => {
            const program = programs[programKey];
            const button = document.createElement('button');
            button.className = 'option-button';
            button.dataset.program = programKey;
            button.innerHTML = `<span class="option-text">${program.name}</span>`;
            container.appendChild(button);
        });
    }
}

function showDaySelection() {
    hideAllSteps();
    document.getElementById('day-selection').classList.remove('hidden');
    
    if (!currentProgram || !programs[currentProgram]) {
        console.error('No valid program selected');
        return;
    }
    
    const program = programs[currentProgram];
    const dayOptions = document.getElementById('day-options');
    dayOptions.innerHTML = '';
    
    Object.keys(program.days).forEach(dayKey => {
        const day = program.days[dayKey];
        const button = document.createElement('button');
        button.className = 'option-button';
        button.dataset.day = dayKey;
        button.innerHTML = `<span class="option-text">Day ${dayKey}: ${day.name}</span>`;
        button.addEventListener('click', () => selectDay(dayKey));
        dayOptions.appendChild(button);
    });
}

function selectDay(dayKey) {
    currentDay = dayKey;
    
    document.querySelectorAll('[data-day]').forEach(btn => btn.classList.remove('selected'));
    document.querySelector(`[data-day="${dayKey}"]`)?.classList.add('selected');
    document.getElementById('start-workout-btn').disabled = false;
}

function startWorkout() {
    hideAllSteps();
    document.getElementById('workout-logging').classList.remove('hidden');
    
    const program = programs[currentProgram];
    const day = program.days[currentDay];
    
    // Update header
    document.getElementById('workout-date').textContent = new Date().toLocaleDateString();
    document.getElementById('workout-title').textContent = `${program.name} - Day ${currentDay}`;
    document.getElementById('workout-subtitle').textContent = day.name;
    
    // Generate exercise interface
    generateExerciseInterface(day.exercises);
}

function generateExerciseInterface(exercises) {
    const container = document.getElementById('exercises-container');
    container.innerHTML = '';

    // Initialize workout data
    workoutData = { exercises: exercises.map(() => ({ sets: [], notes: '' })) };

    exercises.forEach((exercise, exerciseIndex) => {
        const exerciseCard = document.createElement('div');
        exerciseCard.className = 'exercise-card';
        
        let setsHTML = '';
        for (let setNum = 1; setNum <= exercise.sets; setNum++) {
            const previousData = getPreviousSetData(exerciseIndex, setNum - 1);
            const weightPlaceholder = previousData?.weight || 0;
            const repsPlaceholder = previousData?.reps || 0;
            
            setsHTML += `
                <div class="set-row">
                    <div class="set-number">Set ${setNum}</div>
                    <div class="input-group">
                        <label class="input-label">Weight (lbs)</label>
                        <input type="number" class="set-input" 
                               data-exercise="${exerciseIndex}" 
                               data-set="${setNum}" 
                               data-type="weight" 
                               placeholder="${weightPlaceholder}" 
                               min="0" step="2.5">
                    </div>
                    <div class="input-group">
                        <label class="input-label">Reps</label>
                        <input type="number" class="set-input" 
                               data-exercise="${exerciseIndex}" 
                               data-set="${setNum}" 
                               data-type="reps" 
                               placeholder="${repsPlaceholder}" 
                               min="0">
                    </div>
                    <div class="set-complete">
                        <input type="checkbox" class="complete-checkbox">
                    </div>
                </div>
            `;
        }
        
        const previousNotes = getPreviousExerciseNotes(exerciseIndex);
        
        exerciseCard.innerHTML = `
            <div class="exercise-header">
                <span class="exercise-icon">${exercise.icon}</span>
                <div class="exercise-name">${exercise.name}</div>
                <div class="exercise-target">${exercise.target}</div>
                <div class="rep-counter-badge hidden" id="rep-counter-${exerciseIndex}">
                    +<span class="counter-value">0</span>
                </div>
            </div>
            
            <!-- Regression Prompt (Red) -->
            <div class="regression-prompt hidden" id="regression-prompt-${exerciseIndex}">
                <div class="progression-prompt-icon">⚠️</div>
                <div class="progression-prompt-text">
                    <div class="progression-prompt-title">Lower the weight</div>
                    <div class="progression-prompt-subtitle">You're struggling too early in the exercise</div>
                </div>
            </div>
            
            <!-- Consistency Prompt (Amber) -->
            <div class="progression-prompt hidden" id="consistency-prompt-${exerciseIndex}">
                <div class="progression-prompt-icon">🎯</div>
                <div class="progression-prompt-text">
                    <div class="progression-prompt-title">Keep up the good work</div>
                    <div class="progression-prompt-subtitle">Stay at this weight until you can complete all sets in the target range</div>
                </div>
            </div>
            
            <!-- Progression Prompt (Green) -->
            <div class="progression-success hidden" id="progression-prompt-${exerciseIndex}">
                <div class="progression-prompt-icon">💪</div>
                <div class="progression-prompt-text">
                    <div class="progression-prompt-title">Great work! Time to increase the weight</div>
                    <div class="progression-prompt-subtitle">You've mastered this weight - level up!</div>
                </div>
            </div>
            
            <div class="exercise-target" style="margin-bottom: 1rem; text-align: center;">
                Target: ${exercise.sets} sets × ${exercise.repsMin}-${exercise.repsMax} reps
            </div>
            <div class="sets-container">
                ${setsHTML}
            </div>
            <div class="exercise-notes">
                <textarea class="notes-textarea" placeholder="${previousNotes || 'Exercise notes (optional)'}" 
                          data-exercise="${exerciseIndex}"></textarea>
            </div>
        `;
        
        container.appendChild(exerciseCard);
    });
    
    // Add single event listener to container
    container.addEventListener('input', handleInput);
}

function getPreviousSetData(exerciseIndex, setIndex) {
    return dummyLogData[currentProgram]?.[currentDay]?.[exerciseIndex]?.sets?.[setIndex];
}

function getPreviousExerciseNotes(exerciseIndex) {
    return dummyLogData[currentProgram]?.[currentDay]?.[exerciseIndex]?.notes;
}

function handleInput(event) {
    const target = event.target;
    
    if (!target.classList.contains('set-input') && !target.classList.contains('notes-textarea')) {
        return;
    }
    
    const exerciseIndex = parseInt(target.dataset.exercise);
    
    if (target.classList.contains('notes-textarea')) {
        workoutData.exercises[exerciseIndex].notes = target.value;
        return;
    }
    
    const setIndex = parseInt(target.dataset.set) - 1;
    const type = target.dataset.type;
    const value = parseFloat(target.value) || 0;
    
    // Ensure data structure exists
    if (!workoutData.exercises[exerciseIndex].sets[setIndex]) {
        workoutData.exercises[exerciseIndex].sets[setIndex] = {};
    }
    
    workoutData.exercises[exerciseIndex].sets[setIndex][type] = value;
    
    // Update counters and prompts if reps changed
    if (type === 'reps') {
        // Clear existing counter timer for this exercise
        if (counterTimers[exerciseIndex]) {
            clearTimeout(counterTimers[exerciseIndex]);
        }

        // Set new debounced timer for counter evaluation
        counterTimers[exerciseIndex] = setTimeout(() => {
            updateCountersWithAnimation(exerciseIndex);
            delete counterTimers[exerciseIndex];
        }, 500); // 500ms debounce delay

        // Clear existing timer for this exercise
        if (promptTimers[exerciseIndex]) {
            clearTimeout(promptTimers[exerciseIndex]);
        }

        // Set new debounced timer for prompt evaluation
        promptTimers[exerciseIndex] = setTimeout(() => {
            updateExercisePrompts(exerciseIndex);
            delete promptTimers[exerciseIndex];
        }, 500); // 500ms debounce delay
    }
}

// Updated function to compare against previous session data with animation
function updateCountersWithAnimation(exerciseIndex) {
    const exerciseData = workoutData.exercises[exerciseIndex];

    // Calculate excess reps compared to previous session
    let excessReps = 0;

    exerciseData.sets.forEach((currentSet, setIndex) => {
        if (currentSet && currentSet.reps) {
            const previousSetData = getPreviousSetData(exerciseIndex, setIndex);
            const previousReps = previousSetData?.reps || 0;

            if (currentSet.reps > previousReps) {
                excessReps += (currentSet.reps - previousReps);
            }
        }
    });

    // Update rep counter display
    const repCounter = document.getElementById(`rep-counter-${exerciseIndex}`);
    const counterValue = repCounter.querySelector('.counter-value');
    const previousValue = counterValue.textContent;

    if (excessReps > 0) {
        counterValue.textContent = excessReps;
        repCounter.classList.remove('hidden');

        // Trigger animation only if the value changed
        if (previousValue !== excessReps.toString()) {
            // Remove existing animation class
            repCounter.classList.remove('rep-counter-pop');

            // Force reflow to restart animation
            repCounter.offsetHeight;

            // Add animation class
            repCounter.classList.add('rep-counter-pop');

            // Remove animation class after completion
            setTimeout(() => {
                repCounter.classList.remove('rep-counter-pop');
            }, 300);
        }
    } else {
        repCounter.classList.add('hidden');
    }
}

// Legacy function for compatibility - now just calls the animated version
function updateCounters(exerciseIndex) {
    updateCountersWithAnimation(exerciseIndex);
}

// New function to handle exercise completion prompts
function updateExercisePrompts(exerciseIndex) {
    console.log(`=== PROMPT DEBUG START ===`);
    console.log('currentProgram:', currentProgram);
    console.log('currentDay:', currentDay, '(type:', typeof currentDay, ')');

    const program = programs[currentProgram];
    console.log('program found:', !!program);
    console.log('program.days:', program ? Object.keys(program.days) : 'N/A');

    const day = program.days[currentDay];
    console.log('day found:', !!day);
    console.log('day name:', day ? day.name : 'N/A');

    const exercise = day.exercises[exerciseIndex];
    console.log('exercise found:', !!exercise);
    console.log('exercise name:', exercise ? exercise.name : 'N/A');
    console.log('exercise repsMin/Max:', exercise ? `${exercise.repsMin}-${exercise.repsMax}` : 'N/A');

    const exerciseData = workoutData.exercises[exerciseIndex];
    
    console.log(`=== WORKOUT DATA DEBUG ===`);
    console.log('Exercise data sets:', exerciseData.sets);
    
    // Let's see what each set looks like
    exerciseData.sets.forEach((set, index) => {
        console.log(`Set ${index}:`, set);
        if (set) {
            console.log(`  Weight: ${set.weight} (type: ${typeof set.weight})`);
            console.log(`  Reps: ${set.reps} (type: ${typeof set.reps})`);
            console.log(`  Weight > 0: ${set.weight > 0}`);
            console.log(`  Reps > 0: ${set.reps > 0}`);
        }
    });
    
    // Check if all sets are completed (have both weight and reps)
    const expectedSets = exercise.sets;
    const completedSets = exerciseData.sets.filter(set =>
        set && set.reps && set.reps > 0
    ).length;
    
    console.log('Expected sets:', expectedSets);
    console.log('Completed sets:', completedSets);
    
    // Only show prompts when exercise is fully completed
    if (completedSets !== expectedSets) {
        console.log('Not all sets completed, hiding prompts');
        hideAllPrompts(exerciseIndex);
        return;
    }
    
    // Evaluate prompt tier based on completed sets
    const promptTier = evaluatePromptTier(exerciseIndex, exercise, exerciseData);
    showPrompt(exerciseIndex, promptTier);
}

function evaluatePromptTier(exerciseIndex, exercise, exerciseData) {
    const completedSets = exerciseData.sets.filter(set =>
        set && set.reps && set.reps > 0
    );

    console.log(`=== DEBUG Exercise ${exerciseIndex}: ${exercise.name} ===`);
    console.log('Completed sets:', completedSets);
    console.log('Target range:', exercise.repsMin, '-', exercise.repsMax);

    // Extract reps from completed sets
    const reps = completedSets.map(set => set.reps);
    const lowerBound = exercise.repsMin;
    const upperBound = exercise.repsMax;

    console.log('Reps array:', reps);

    if (reps.length === 0) {
        console.log('RETURNING: consistency (no completed sets)');
        return 'consistency';
    }

    // Get first set, second set, and all other sets
    const firstSet = reps[0];
    const secondSet = reps.length > 1 ? reps[1] : null;
    const allOtherSets = reps.slice(2); // third, fourth, etc.

    console.log('First set reps:', firstSet);
    console.log('Second set reps:', secondSet);
    console.log('All other sets:', allOtherSets);

    // Check first two sets
    if (firstSet < lowerBound || (secondSet !== null && secondSet < lowerBound)) {
        console.log('RETURNING: regression (first two sets struggling)');
        return 'regression';
    }

    // Check if all sets hit upper bound or above
    const allSetsAtOrAboveUpper = reps.every(repCount => repCount >= upperBound);
    if (allSetsAtOrAboveUpper) {
        console.log('RETURNING: progression (all sets hit upper bound+)');
        return 'progression';
    }

    // Check if first two are on/above target but later sets drop below
    if (firstSet >= lowerBound &&
        (secondSet === null || secondSet >= lowerBound) &&
        allOtherSets.length > 0 &&
        allOtherSets.some(repCount => repCount < lowerBound)) {
        console.log('RETURNING: consistency (later sets dropped below target)');
        return 'consistency';
    }

    // Default case: everything is within range
    console.log('RETURNING: consistency (default - everything within range)');
    return 'consistency';
}

function showPrompt(exerciseIndex, promptType) {
    console.log(`=== SHOWING PROMPT ===`);
    console.log(`Exercise: ${exerciseIndex}, Type: ${promptType}`);
    
    // Hide all prompts first
    hideAllPrompts(exerciseIndex);
    
    // Show the appropriate prompt
    const promptElement = document.getElementById(`${promptType}-prompt-${exerciseIndex}`);
    console.log('Looking for element ID:', `${promptType}-prompt-${exerciseIndex}`);
    console.log('Element found:', promptElement);
    
    if (promptElement) {
        console.log('Removing hidden class...');
        promptElement.classList.remove('hidden');
        console.log('Element classes after:', promptElement.className);
    } else {
        console.error('ELEMENT NOT FOUND!');
    }
}

function hideAllPrompts(exerciseIndex) {
    const promptTypes = ['regression', 'progression', 'consistency'];
    promptTypes.forEach(type => {
        const promptElement = document.getElementById(`${type}-prompt-${exerciseIndex}`);
        if (promptElement) {
            promptElement.classList.add('hidden');
        }
    });
}

function completeWorkout() {
    // Show award screen first
    showAwardScreen();
    
    // Generate summary data but don't show yet
    generateSummaryData();
}

function hideAllSteps() {
    document.querySelectorAll('.card').forEach(card => {
        card.classList.add('hidden');
    });
}

function calculateImprovements(exercises) {
    const improvements = [];
    
    exercises.forEach((exercise, exerciseIndex) => {
        const currentData = workoutData.exercises[exerciseIndex];
        const previousData = dummyLogData[currentProgram]?.[currentDay]?.[exerciseIndex];
        
        if (!previousData || !currentData) return;
        
        // Calculate current totals
        const currentWeights = currentData.sets.map(set => set.weight || 0).filter(w => w > 0);
        const currentTotalReps = currentData.sets.reduce((sum, set) => sum + (set.reps || 0), 0);
        
        // Calculate previous totals
        const previousWeights = previousData.sets.map(set => set.weight || 0).filter(w => w > 0);
        const previousTotalReps = previousData.sets.reduce((sum, set) => sum + (set.reps || 0), 0);
        
        // Check for improvements
        const maxCurrentWeight = Math.max(...currentWeights, 0);
        const maxPreviousWeight = Math.max(...previousWeights, 0);
        
        const weightImproved = maxCurrentWeight > maxPreviousWeight;
        const repsImproved = currentTotalReps > previousTotalReps;
        
        if (weightImproved || repsImproved) {
            improvements.push({
                exercise,
                exerciseIndex,
                weightImproved,
                repsImproved,
                weightIncrease: maxCurrentWeight - maxPreviousWeight,
                repsIncrease: currentTotalReps - previousTotalReps
            });
        }
    });
    
    return improvements;
}

function generateAwardScreen(exercises) {
    const improvements = calculateImprovements(exercises);
    const improvementsList = document.getElementById('improvements-list');
    
    if (improvements.length === 0) {
        // Check if it's regression or just no change
        const hasRegression = checkForRegression(exercises);
        
        if (hasRegression) {
            // Show regression encouragement message
            improvementsList.innerHTML = `
                <div style="background: linear-gradient(135deg, #fef2f2, #fee2e2); padding: 1.5rem; border-radius: 1rem; border: 2px solid #fca5a5; text-align: center;">
                    <div style="font-size: 2rem; margin-bottom: 1rem;">💪</div>
                    <div style="font-size: 1.125rem; font-weight: 600; color: #dc2626; margin-bottom: 0.5rem;">
                        Every workout counts!
                    </div>
                    <div style="color: #7f1d1d;">
                        Not every session will be your best - that's completely normal! Recovery, sleep, and nutrition all play a role. You showed up, and that's what matters most.
                    </div>
                </div>
            `;
        } else {
            // Show consistency message (matched previous session)
            improvementsList.innerHTML = `
                <div style="background: linear-gradient(135deg, #fef3c7, #fde68a); padding: 1.5rem; border-radius: 1rem; border: 2px solid #f59e0b; text-align: center;">
                    <div style="font-size: 2rem; margin-bottom: 1rem;">🔥</div>
                    <div style="font-size: 1.125rem; font-weight: 600; color: #92400e; margin-bottom: 0.5rem;">
                        Consistency is key!
                    </div>
                    <div style="color: #a16207;">
                        You matched your previous session perfectly. Maintaining your performance is still progress - you're building the habit!
                    </div>
                </div>
            `;
        }
        return;
    }
    
    // Show ALL improvements (however many there are)
    const improvementsHTML = improvements.map(improvement => {
        const { exercise, weightImproved, repsImproved, weightIncrease, repsIncrease } = improvement;
        
        let message = `${exercise.icon} Congratulations! You `;
        
        if (weightImproved && repsImproved) {
            message += `lifted ${Math.abs(weightIncrease)}kg more and did ${Math.abs(repsIncrease)} more reps on ${exercise.name} versus last session`;
        } else if (repsImproved) {
            message += `did ${Math.abs(repsIncrease)} more reps on ${exercise.name} versus last session`;
        } else if (weightImproved) {
            message += `lifted ${Math.abs(weightIncrease)}kg more on ${exercise.name} versus last session`;
        }
        
        return `
            <div style="background: linear-gradient(135deg, #f0fdf4, #dcfce7); padding: 1.5rem; border-radius: 1rem; border: 2px solid #bbf7d0; margin-bottom: 1rem;">
                <div style="font-size: 1.125rem; font-weight: 600; color: #166534;">
                    ${message}
                </div>
            </div>
        `;
    }).join('');
    
    improvementsList.innerHTML = improvementsHTML;
}

function checkForRegression(exercises) {
    let hasRegression = false;
    
    exercises.forEach((exercise, exerciseIndex) => {
        const currentData = workoutData.exercises[exerciseIndex];
        const previousData = dummyLogData[currentProgram]?.[currentDay]?.[exerciseIndex];
        
        if (!previousData || !currentData) return;
        
        // Calculate current totals
        const currentWeights = currentData.sets.map(set => set.weight || 0).filter(w => w > 0);
        const currentTotalReps = currentData.sets.reduce((sum, set) => sum + (set.reps || 0), 0);
        
        // Calculate previous totals
        const previousWeights = previousData.sets.map(set => set.weight || 0).filter(w => w > 0);
        const previousTotalReps = previousData.sets.reduce((sum, set) => sum + (set.reps || 0), 0);
        
        // Check for regression
        const maxCurrentWeight = Math.max(...currentWeights, 0);
        const maxPreviousWeight = Math.max(...previousWeights, 0);
        
        if (maxCurrentWeight < maxPreviousWeight || currentTotalReps < previousTotalReps) {
            hasRegression = true;
        }
    });
    
    return hasRegression;
}

function generateSummaryData() {
    const program = programs[currentProgram];
    const day = program.days[currentDay];
    
    let totalSets = 0;
    let completedSets = 0;
    let totalVolume = 0;
    let totalExcessReps = 0;
    let exercisesReadyToProgress = 0;
    
    workoutData.exercises.forEach((exerciseData, index) => {
        const exercise = day.exercises[index];
        totalSets += exercise.sets;
        
        exerciseData.sets.forEach(set => {
            if (set.weight && set.reps) {
                completedSets++;
                totalVolume += (set.weight * set.reps);
            }
        });
        
        // Calculate excess reps vs previous session for summary
        exerciseData.sets.forEach((currentSet, setIndex) => {
            if (currentSet && currentSet.reps) {
                const previousSetData = getPreviousSetData(index, setIndex);
                const previousReps = previousSetData?.reps || 0;
                if (currentSet.reps > previousReps) {
                    totalExcessReps += (currentSet.reps - previousReps);
                }
            }
        });
        
        // Check if exercise is ready to progress
        const completedSetsForExercise = exerciseData.sets.filter(set =>
            set && set.reps && set.reps > 0
        );
        const setsExceedingRange = completedSetsForExercise.filter(set => 
            set.reps >= exercise.repsMax
        ).length;
        
        if (setsExceedingRange >= 2) {
            exercisesReadyToProgress++;
        }
    });
    
    const completionRate = Math.round((completedSets / totalSets) * 100);

    document.getElementById('summary-stats').innerHTML = `
        <div class="summary-stat workout-description" style="grid-column: 1 / -1; background: linear-gradient(135deg, #f3f4f6, #e5e7eb); border: 1px solid #d1d5db; padding: 1.5rem;">
            <div class="stat-value" style="font-size: 1.25rem; color: #374151; margin-bottom: 0.5rem;">${day.name}</div>
            <div class="stat-label" style="color: #6b7280; font-size: 0.875rem;">
                ${program.name} • Day ${currentDay + 1} • ${day.exercises.length} exercises completed
            </div>
        </div>
        <div class="summary-stat">
            <div class="stat-value">${completedSets}</div>
            <div class="stat-label">Sets Completed</div>
        </div>
        <div class="summary-stat">
            <div class="stat-value">${completionRate}%</div>
            <div class="stat-label">Completion Rate</div>
        </div>
        <div class="summary-stat">
            <div class="stat-value">${Math.round(totalVolume)}</div>
            <div class="stat-label">Total Volume (lbs)</div>
        </div>
        <div class="summary-stat">
            <div class="stat-value">${totalExcessReps}</div>
            <div class="stat-label">Excess Reps vs Last</div>
        </div>
        <div class="summary-stat">
            <div class="stat-value">${exercisesReadyToProgress}</div>
            <div class="stat-label">Ready to Progress</div>
        </div>
    `;
    
    console.log('Workout completed:', workoutData);
}

function showAwardScreen() {
    const program = programs[currentProgram];
    const day = program.days[currentDay];

    hideAllSteps();
    document.getElementById('workout-award').classList.remove('hidden');

    generateAwardScreen(day.exercises);
}

function showWorkoutSummary() {
    const program = programs[currentProgram];
    const day = program.days[currentDay];

    hideAllSteps();
    document.getElementById('workout-summary').classList.remove('hidden');

    generateWorkoutSummary(day.exercises);
}

function generateWorkoutSummary(exercises) {
    const summaryStats = document.getElementById('summary-stats');
    const program = programs[currentProgram];
    const day = program.days[currentDay];

    // Calculate workout statistics
    let totalSets = 0;
    let totalReps = 0;
    let totalWeight = 0;
    let exerciseCount = exercises.length;

    exercises.forEach((exercise, exerciseIndex) => {
        const currentData = workoutData.exercises[exerciseIndex];
        if (currentData) {
            totalSets += currentData.sets.length;
            currentData.sets.forEach(set => {
                totalReps += set.reps || 0;
                totalWeight += (set.weight || 0) * (set.reps || 0);
            });
        }
    });

    const summaryHTML = `
        <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 1.5rem; margin-bottom: 2rem;">
            <div style="background: linear-gradient(135deg, #f3f4f6, #e5e7eb); padding: 1.5rem; border-radius: 1rem; border: 2px solid #d1d5db; text-align: center;">
                <div style="font-size: 2rem; margin-bottom: 0.5rem;">📋</div>
                <div style="font-size: 1.5rem; font-weight: 700; color: #374151;">${day.name}</div>
                <div style="font-size: 0.875rem; color: #6b7280;">${program.name}</div>
            </div>
            <div style="background: linear-gradient(135deg, #f0fdf4, #dcfce7); padding: 1.5rem; border-radius: 1rem; border: 2px solid #bbf7d0; text-align: center;">
                <div style="font-size: 2rem; margin-bottom: 0.5rem;">💪</div>
                <div style="font-size: 1.5rem; font-weight: 700; color: #166534;">${exerciseCount}</div>
                <div style="font-size: 0.875rem; color: #15803d;">Exercises</div>
            </div>
            <div style="background: linear-gradient(135deg, #eff6ff, #dbeafe); padding: 1.5rem; border-radius: 1rem; border: 2px solid #93c5fd; text-align: center;">
                <div style="font-size: 2rem; margin-bottom: 0.5rem;">🔢</div>
                <div style="font-size: 1.5rem; font-weight: 700; color: #1e40af;">${totalSets}</div>
                <div style="font-size: 0.875rem; color: #1d4ed8;">Total Sets</div>
            </div>
            <div style="background: linear-gradient(135deg, #fef3c7, #fde68a); padding: 1.5rem; border-radius: 1rem; border: 2px solid #f59e0b; text-align: center;">
                <div style="font-size: 2rem; margin-bottom: 0.5rem;">🔥</div>
                <div style="font-size: 1.5rem; font-weight: 700; color: #92400e;">${totalReps}</div>
                <div style="font-size: 0.875rem; color: #a16207;">Total Reps</div>
            </div>
            <div style="background: linear-gradient(135deg, #fdf2f8, #fce7f3); padding: 1.5rem; border-radius: 1rem; border: 2px solid #f9a8d4; text-align: center;">
                <div style="font-size: 2rem; margin-bottom: 0.5rem;">⚖️</div>
                <div style="font-size: 1.5rem; font-weight: 700; color: #be185d;">${Math.round(totalWeight)}kg</div>
                <div style="font-size: 0.875rem; color: #be185d;">Volume Load</div>
            </div>
        </div>
    `;

    summaryStats.innerHTML = summaryHTML;
}