/**
 * trAIn Backend Server
 * 
 * Handles:
 * - Email capture from landing page
 * - Questionnaire submission and processing
 * - Program generation based on user responses
 * - Database operations for users, responses, and programs
 * - Static file serving for frontend
 * 
 * @author trAIn Team
 * @version 2.0
 */

const express = require('express');
const cors = require('cors');
const path = require('path');
const { initializeDatabase, dbHelpers } = require('./database/db');

const app = express();
const PORT = 3001;

// ============================================================================
// PROGRAM TEMPLATES - Same as frontend for consistency
// ============================================================================

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
// MIDDLEWARE SETUP
// ============================================================================

app.use(cors());
app.use(express.json());

// Serve static files from frontend directory
app.use(express.static(path.join(__dirname, '../frontend')));

// ============================================================================
// UTILITY FUNCTIONS
// ============================================================================

/**
 * Validate email format
 * @param {string} email - Email address to validate
 * @returns {boolean} - True if email format is valid
 */
function isValidEmail(email) {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
}

/**
 * Generate program based on user questionnaire responses
 * Uses the same logic as the frontend for consistency
 * @param {Object} formData - User's questionnaire responses
 * @returns {Object} - Generated program object
 */
function generateProgram(formData) {
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
 * Save program to database
 * Currently returns a mock ID - implement database save as needed
 * @param {Object} program - Generated program object
 * @param {string} userEmail - User's email address
 * @returns {Promise<string>} - Program ID
 */
async function saveProgramToDatabase(program, userEmail) {
    try {
        console.log('Saving program to database:', {
            userEmail,
            programName: program.name,
            templateId: program.template_used,
            createdAt: program.created_at
        });
        
        // TODO: Implement actual database save
        // For now, return a mock program ID
        return `prog_${Date.now()}`;
        
        // In a real implementation, you might do:
        // const programId = await dbHelpers.insertProgram({
        //     userEmail,
        //     templateId: program.template_used,
        //     programData: JSON.stringify(program),
        //     createdAt: program.created_at
        // });
        // return programId;
        
    } catch (error) {
        console.error('Error saving program to database:', error);
        throw error;
    }
}

/**
 * Send program via email (placeholder for email service integration)
 * This is where you would integrate with your email service to send the PDF
 * @param {string} userEmail - User's email address
 * @param {Object} program - Generated program object
 * @returns {Promise<boolean>} - Success status
 */
async function sendProgramEmail(userEmail, program) {
    try {
        console.log(`Sending program "${program.name}" to ${userEmail}`);
        
        // TODO: Implement email sending with PDF generation
        // Example integration points:
        // 1. Generate PDF from program data
        // 2. Send via email service (SendGrid, Mailgun, etc.)
        
        // For now, just log the action
        console.log('Email sent successfully (mock)');
        return true;
        
    } catch (error) {
        console.error('Error sending program email:', error);
        throw error;
    }
}

// ============================================================================
// API ENDPOINTS
// ============================================================================

/**
 * Health check endpoint
 */
app.get('/api/health', (req, res) => {
    res.json({ 
        message: 'Server is working!',
        timestamp: new Date().toISOString(),
        version: '2.0'
    });
});

/**
 * Email capture endpoint
 * Called from the landing page when user enters their email
 */
app.post('/api/email-capture', async (req, res) => {
    try {
        const { email } = req.body;
        
        if (!email || !isValidEmail(email)) {
            return res.status(400).json({
                success: false,
                message: 'Valid email address is required'
            });
        }

        console.log('Email captured:', email);

        // Store email capture in database
        const userId = await dbHelpers.createOrUpdateUser(email);
        console.log('User created/updated with ID:', userId);

        res.json({
            success: true,
            message: 'Email captured successfully',
            userId
        });

    } catch (error) {
        console.error('Error capturing email:', error);
        res.status(500).json({
            success: false,
            message: 'Server error: ' + error.message
        });
    }
});

/**
 * Complete questionnaire submission and program generation endpoint
 * This is the main endpoint called by the frontend after questionnaire completion
 */
app.post('/api/questionnaire/submit', async (req, res) => {
    try {
        console.log('Received complete submission:', req.body);
        
        const {
            questionnaire,
            program,
            timestamp
        } = req.body;

        // Extract questionnaire data (supporting both old and new formats)
        const questionnaireData = questionnaire || req.body;
        const userEmail = questionnaireData.email;

        if (!userEmail || !isValidEmail(userEmail)) {
            return res.status(400).json({
                success: false,
                message: 'Valid email address is required'
            });
        }

        // Create or update user
        const userId = await dbHelpers.createOrUpdateUser(userEmail);
        console.log('User found/created with ID:', userId);

        // Save questionnaire response
        const responseId = await dbHelpers.insertResponse({
            userId,
            experience: questionnaireData.experience,
            whyUsingApp: questionnaireData.whyUsingApp,
            equipmentAvailable: questionnaireData.equipmentAvailable,
            equipmentConfidence: questionnaireData.equipmentConfidence,
            trainingDays: questionnaireData.trainingDays,
            additionalInfo: questionnaireData.additionalInfo,
            ipAddress: req.ip,
            userAgent: req.get('User-Agent')
        });

        console.log('Questionnaire response saved with ID:', responseId);

        // Generate program if not provided
        let programToSave = program;
        if (!programToSave) {
            console.log('No program provided, generating new program');
            programToSave = generateProgram(questionnaireData);
        }

        // Save program to database
        const programId = await saveProgramToDatabase(programToSave, userEmail);
        programToSave.id = programId;

        // Send program via email
        try {
            await sendProgramEmail(userEmail, programToSave);
            console.log('Program email sent successfully');
        } catch (emailError) {
            console.warn('Failed to send program email:', emailError.message);
            // Continue without failing the entire request
        }

        res.json({
            success: true,
            message: 'Questionnaire submitted and program generated successfully',
            data: {
                responseId,
                programId,
                program: programToSave
            }
        });

    } catch (error) {
        console.error('Error in questionnaire submission:', error);
        res.status(500).json({
            success: false,
            message: 'Server error: ' + error.message
        });
    }
});

/**
 * Legacy questionnaire submission endpoint
 * Maintained for backwards compatibility
 */
app.post('/api/questionnaire/submit-legacy', async (req, res) => {
    try {
        console.log('Received legacy questionnaire data:', req.body);
        
        const {
            email, firstName, lastName, experience, whyUsingApp,
            equipmentAvailable, equipmentConfidence, trainingDays, additionalInfo
        } = req.body;

        if (!email || !isValidEmail(email)) {
            return res.status(400).json({
                success: false,
                message: 'Valid email address is required'
            });
        }

        // Create user (firstName and lastName optional)
        const userId = await dbHelpers.createOrUpdateUser(email, firstName, lastName);
        console.log('User created/updated with ID:', userId);

        // Save response
        const responseId = await dbHelpers.insertResponse({
            userId,
            experience,
            whyUsingApp,
            equipmentAvailable,
            equipmentConfidence,
            trainingDays,
            additionalInfo,
            ipAddress: req.ip,
            userAgent: req.get('User-Agent')
        });

        console.log('Legacy response saved with ID:', responseId);

        res.json({
            success: true,
            message: 'Questionnaire submitted successfully!',
            responseId
        });

    } catch (error) {
        console.error('Error submitting legacy questionnaire:', error);
        res.status(500).json({
            success: false,
            message: 'Server error: ' + error.message
        });
    }
});

/**
 * Program generation endpoint
 * Can be called independently to generate programs
 */
app.post('/api/programs/generate', async (req, res) => {
    try {
        console.log('Generating program for:', req.body);
        
        const formData = req.body;
        
        if (!formData.email || !isValidEmail(formData.email)) {
            return res.status(400).json({
                success: false,
                message: 'Valid email address is required'
            });
        }

        // Generate program using the same logic as frontend
        const program = generateProgram(formData);
        
        // Save program to database
        try {
            const programId = await saveProgramToDatabase(program, formData.email);
            program.id = programId;
            console.log('Program saved to database with ID:', programId);
        } catch (dbError) {
            console.warn('Could not save program to database:', dbError.message);
            // Continue without database save
        }

        // Optionally send email
        if (formData.sendEmail !== false) {
            try {
                await sendProgramEmail(formData.email, program);
                console.log('Program email sent');
            } catch (emailError) {
                console.warn('Failed to send program email:', emailError.message);
            }
        }

        res.json({
            success: true,
            message: 'Program generated successfully',
            program
        });

    } catch (error) {
        console.error('Error generating program:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to generate program: ' + error.message
        });
    }
});

/**
 * Get user's programs endpoint
 * Retrieve all programs for a specific user
 */
app.get('/api/programs/user/:email', async (req, res) => {
    try {
        const email = req.params.email;
        
        if (!email || !isValidEmail(email)) {
            return res.status(400).json({
                success: false,
                message: 'Valid email address is required'
            });
        }
        
        // TODO: Implement database retrieval
        // For now, return empty array
        res.json({
            success: true,
            programs: [],
            message: 'No programs found (database retrieval not yet implemented)'
        });
        
        // In a real implementation:
        // const programs = await dbHelpers.getUserPrograms(email);
        // res.json({
        //     success: true,
        //     programs
        // });
        
    } catch (error) {
        console.error('Error fetching user programs:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch programs: ' + error.message
        });
    }
});

/**
 * Get specific program by ID
 */
app.get('/api/programs/:programId', async (req, res) => {
    try {
        const programId = req.params.programId;
        
        // TODO: Implement database retrieval
        // For now, return not found
        res.status(404).json({
            success: false,
            message: 'Program not found (database retrieval not yet implemented)'
        });
        
        // In a real implementation:
        // const program = await dbHelpers.getProgramById(programId);
        // if (program) {
        //     res.json({
        //         success: true,
        //         program
        //     });
        // } else {
        //     res.status(404).json({
        //         success: false,
        //         message: 'Program not found'
        //     });
        // }
        
    } catch (error) {
        console.error('Error fetching program:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch program: ' + error.message
        });
    }
});

/**
 * Program templates endpoint
 * Returns all available program templates
 */
app.get('/api/programs/templates', (req, res) => {
    res.json({
        success: true,
        templates: PROGRAM_TEMPLATES
    });
});

/**
 * Get specific template by ID
 */
app.get('/api/programs/templates/:templateId', (req, res) => {
    try {
        const templateId = req.params.templateId;
        const template = PROGRAM_TEMPLATES.programs.find(p => p.id === templateId);
        
        if (template) {
            res.json({
                success: true,
                template
            });
        } else {
            res.status(404).json({
                success: false,
                message: 'Template not found'
            });
        }
    } catch (error) {
        console.error('Error fetching template:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch template: ' + error.message
        });
    }
});

/**
 * Analytics endpoint for tracking user events
 * Can be used to log user interactions and program generation metrics
 */
app.post('/api/analytics/track', async (req, res) => {
    try {
        const { event, data, timestamp } = req.body;
        
        console.log('Analytics event:', {
            event,
            data,
            timestamp: timestamp || new Date().toISOString(),
            ip: req.ip,
            userAgent: req.get('User-Agent')
        });
        
        // TODO: Implement analytics storage
        // For now, just log the event
        
        res.json({
            success: true,
            message: 'Event tracked successfully'
        });
        
    } catch (error) {
        console.error('Error tracking analytics event:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to track event: ' + error.message
        });
    }
});

/**
 * Contact/feedback endpoint
 * For user inquiries or feedback submission
 */
app.post('/api/contact', async (req, res) => {
    try {
        const { email, name, message, type } = req.body;
        
        if (!email || !message) {
            return res.status(400).json({
                success: false,
                message: 'Email and message are required'
            });
        }
        
        console.log('Contact form submission:', {
            email,
            name,
            message,
            type: type || 'general',
            timestamp: new Date().toISOString()
        });
        
        // TODO: Implement contact form handling
        // Could save to database and/or send notification email
        
        res.json({
            success: true,
            message: 'Message received successfully'
        });
        
    } catch (error) {
        console.error('Error processing contact form:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to process message: ' + error.message
        });
    }
});

// ============================================================================
// STATIC FILE SERVING AND FALLBACK ROUTES
// ============================================================================

/**
 * Serve frontend for any non-API routes
 * This enables client-side routing for the single-page application
 */
app.get('*', (req, res) => {
    // Don't serve HTML for API routes that weren't found
    if (req.path.startsWith('/api/')) {
        return res.status(404).json({
            success: false,
            message: 'API endpoint not found'
        });
    }
    
    // Serve the main HTML file for all other routes
    res.sendFile(path.join(__dirname, '../frontend/index.html'));
});

// ============================================================================
// ERROR HANDLING MIDDLEWARE
// ============================================================================

/**
 * Global error handler
 * Catches any unhandled errors and returns appropriate responses
 */
app.use((err, req, res, next) => {
    console.error('Unhandled error:', err);
    
    res.status(500).json({
        success: false,
        message: 'Internal server error',
        ...(process.env.NODE_ENV === 'development' && { error: err.message })
    });
});

/**
 * 404 handler for API routes
 */
app.use('/api/*', (req, res) => {
    res.status(404).json({
        success: false,
        message: 'API endpoint not found'
    });
});

// ============================================================================
// SERVER INITIALIZATION
// ============================================================================

/**
 * Start the server with proper error handling and database initialization
 */
async function startServer() {
    try {
        // Initialize database connection
        await initializeDatabase();
        console.log('Database initialized successfully');
        
        // Start the HTTP server
        app.listen(PORT, () => {
            console.log('='.repeat(50));
            console.log('🚀 trAIn Backend Server Started');
            console.log('='.repeat(50));
            console.log(`🌐 Server running on: http://localhost:${PORT}`);
            console.log(`📱 Frontend available at: http://localhost:${PORT}`);
            console.log(`🔧 API base URL: http://localhost:${PORT}/api`);
            console.log(`📊 Health check: http://localhost:${PORT}/api/health`);
            console.log('='.repeat(50));
            console.log('✅ Database: Connected and ready');
            console.log('✅ Program generation: Ready');
            console.log('✅ Email capture: Ready');
            console.log('✅ Static files: Serving from frontend directory');
            console.log('='.repeat(50));
            
            // Log available endpoints
            console.log('📋 Available API Endpoints:');
            console.log('   POST /api/email-capture');
            console.log('   POST /api/questionnaire/submit');
            console.log('   POST /api/programs/generate');
            console.log('   GET  /api/programs/templates');
            console.log('   GET  /api/programs/user/:email');
            console.log('   POST /api/analytics/track');
            console.log('   POST /api/contact');
            console.log('   GET  /api/health');
            console.log('='.repeat(50));
        });
        
    } catch (error) {
        console.error('❌ Failed to start server:', error);
        console.error('Please check your database configuration and try again.');
        process.exit(1);
    }
}

// Handle graceful shutdown
process.on('SIGTERM', () => {
    console.log('SIGTERM received, shutting down gracefully');
    process.exit(0);
});

process.on('SIGINT', () => {
    console.log('SIGINT received, shutting down gracefully');
    process.exit(0);
});

// Start the server
startServer();