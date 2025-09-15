const express = require('express');
const cors = require('cors');
const path = require('path');
const { initializeDatabase, dbHelpers } = require('./database/db');

const app = express();
const PORT = 3001;

// Program Templates - same as frontend
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

// Middleware
app.use(cors());
app.use(express.json());

// Serve static files from frontend directory
app.use(express.static(path.join(__dirname, '../frontend')));

// API routes
app.get('/api/health', (req, res) => {
    res.json({ message: 'Server is working!' });
});

// Original questionnaire submission endpoint
app.post('/api/questionnaire/submit', async (req, res) => {
    try {
        console.log('Received questionnaire data:', req.body);
        
        const {
            email, firstName, lastName, experience, whyUsingApp,
            equipmentAvailable, equipmentConfidence, trainingDays, additionalInfo
        } = req.body;

        // Create user
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

        console.log('Response saved with ID:', responseId);

        res.json({
            success: true,
            message: 'Questionnaire submitted successfully!',
            responseId
        });

    } catch (error) {
        console.error('Error submitting questionnaire:', error);
        res.status(500).json({
            success: false,
            message: 'Server error: ' + error.message
        });
    }
});

// New program generation endpoint
app.post('/api/programs/generate', async (req, res) => {
    try {
        console.log('Generating program for:', req.body);
        
        const formData = req.body;
        
        // Generate program using the same logic as frontend
        const program = generateProgram(formData);
        
        // Save program to database (optional)
        try {
            const programId = await saveProgramToDatabase(program, formData.email);
            program.id = programId;
            console.log('Program saved to database with ID:', programId);
        } catch (dbError) {
            console.warn('Could not save program to database:', dbError.message);
            // Continue without database save
        }

        res.json(program);

    } catch (error) {
        console.error('Error generating program:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to generate program: ' + error.message
        });
    }
});

// Program generation logic (same as frontend)
function generateProgram(formData) {
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
        created_at: new Date().toISOString(),
        template_id: selectedTemplate.id
    };

    return program;
}

// Save program to database (optional - requires database setup)
async function saveProgramToDatabase(program, userEmail) {
    try {
        // This would require additional database tables for programs
        // For now, we'll just log it and return a mock ID
        console.log('Saving program to database:', {
            userEmail,
            programName: program.name,
            templateId: program.template_id,
            createdAt: program.created_at
        });
        
        // Return a mock program ID
        return `prog_${Date.now()}`;
        
        // In a real implementation, you'd do something like:
        // const programId = await dbHelpers.insertProgram({
        //     userEmail,
        //     templateId: program.template_id,
        //     programData: JSON.stringify(program),
        //     createdAt: program.created_at
        // });
        // return programId;
        
    } catch (error) {
        console.error('Error saving program to database:', error);
        throw error;
    }
}

// Get user's programs endpoint (for future use)
app.get('/api/programs/user/:email', async (req, res) => {
    try {
        const email = req.params.email;
        
        // This would retrieve programs from database
        // For now, return empty array
        res.json({
            success: true,
            programs: []
        });
        
    } catch (error) {
        console.error('Error fetching user programs:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch programs: ' + error.message
        });
    }
});

// Program templates endpoint (optional)
app.get('/api/programs/templates', (req, res) => {
    res.json(PROGRAM_TEMPLATES);
});

// Serve frontend for any non-API routes
app.get('*', (req, res) => {
    res.sendFile(path.join(__dirname, '../frontend/index.html'));
});

// Start server
async function startServer() {
    try {
        await initializeDatabase();
        
        app.listen(PORT, () => {
            console.log(`Server running on http://localhost:${PORT}`);
            console.log('Database connected and ready');
            console.log('Frontend served at http://localhost:${PORT}');
            console.log('Program generation API ready');
        });
    } catch (error) {
        console.error('Failed to start server:', error);
    }
}

startServer();