// Workout Logger JavaScript - Complete Program Support

// State
let currentProgram = null;
let currentDay = null;
let workoutData = {};
let programs = {};
let dummyLogData = {};
let isDevMode = false;

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
        const response = await fetch('/backend/workout-templates.json');
        programs = await response.json();
    } catch (error) {
        console.error('Could not load workout templates:', error);
        programs = {};
    }
}

async function loadDummyLogData() {
    try {
        const response = await fetch('/backend/dummy_log_data.json');
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
            <div class="progression-prompt hidden" id="progression-prompt-${exerciseIndex}">
                <div class="progression-prompt-icon">💪</div>
                <div class="progression-prompt-text">
                    <div class="progression-prompt-title">Ready to progress!</div>
                    <div class="progression-prompt-subtitle">Consider increasing weight next time</div>
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
    
    // Update counters if reps changed
    if (type === 'reps') {
        updateCounters(exerciseIndex);
    }
}

function updateCounters(exerciseIndex) {
    const program = programs[currentProgram];
    const day = program.days[currentDay];
    const exercise = day.exercises[exerciseIndex];
    const exerciseData = workoutData.exercises[exerciseIndex];
    
    // Calculate excess reps
    let excessReps = 0;
    let setsExceedingRange = 0;
    
    exerciseData.sets.forEach(set => {
        if (set && set.reps && set.reps > exercise.repsMax) {
            excessReps += (set.reps - exercise.repsMax);
            setsExceedingRange++;
        }
    });
    
    // Update rep counter
    const repCounter = document.getElementById(`rep-counter-${exerciseIndex}`);
    const counterValue = repCounter.querySelector('.counter-value');
    
    if (excessReps > 0) {
        counterValue.textContent = excessReps;
        repCounter.classList.remove('hidden');
    } else {
        repCounter.classList.add('hidden');
    }
    
    // Update progression prompt
    const progressionPrompt = document.getElementById(`progression-prompt-${exerciseIndex}`);
    
    if (setsExceedingRange >= 2) {
        progressionPrompt.classList.remove('hidden');
    } else {
        progressionPrompt.classList.add('hidden');
    }
}

function completeWorkout() {
    hideAllSteps();
    document.getElementById('workout-summary').classList.remove('hidden');
    
    // Generate summary
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
            if (set.reps > exercise.repsMax) {
                totalExcessReps += (set.reps - exercise.repsMax);
            }
        });
        
        const setsExceedingRange = exerciseData.sets.filter(set => 
            set && set.reps && set.reps > exercise.repsMax
        ).length;
        
        if (setsExceedingRange >= 2) {
            exercisesReadyToProgress++;
        }
    });
    
    const completionRate = Math.round((completedSets / totalSets) * 100);
    
    document.getElementById('summary-stats').innerHTML = `
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
            <div class="stat-label">Excess Reps</div>
        </div>
        <div class="summary-stat">
            <div class="stat-value">${exercisesReadyToProgress}</div>
            <div class="stat-label">Ready to Progress</div>
        </div>
    `;
    
    console.log('Workout completed:', workoutData);
}

function hideAllSteps() {
    document.querySelectorAll('.card').forEach(card => {
        card.classList.add('hidden');
    });
}