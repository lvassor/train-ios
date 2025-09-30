/**
 * trAIn UAT Database - PostgreSQL for Vercel
 * PostgreSQL operations for UAT users (questionnaires + feedback)
 */

const { neon } = require('@neondatabase/serverless');

let sql;
let isInitialized = false;

// Initialize database connection
async function initDB() {
    // Use Vercel's DATABASE_URL or fallback to local development
    const connectionString = process.env.DATABASE_URL || process.env.POSTGRES_URL;


    if (!connectionString) {
        throw new Error('❌ No database connection string found. Please set DATABASE_URL or POSTGRES_URL environment variable.');
    }

    // Create Neon connection
    sql = neon(connectionString);

    try {
        // Test connection and create table
        await createTable();
    } catch (error) {
        console.error('❌ Database initialization failed:', error);
        throw error;
    }
}

async function createTable() {
    try {
        // Create consolidated UAT users table
        await sql`
            CREATE TABLE IF NOT EXISTS uat_users (
                id SERIAL PRIMARY KEY,
                -- Basic Info
                first_name TEXT,
                last_name TEXT,
                email TEXT UNIQUE NOT NULL,
                email_opt_out INTEGER DEFAULT 0,

                -- Questionnaire Data
                experience TEXT,
                goals JSONB, -- JSON array
                equipment JSONB, -- JSON array
                equipment_confidence JSONB, -- JSON object
                training_days INTEGER,
                session_duration INTEGER,
                program_id TEXT,
                program_name TEXT,

                -- Feedback Data
                overall_rating INTEGER,
                loved_most TEXT,
                improvements TEXT,
                current_app TEXT,
                missing_features TEXT,

                -- Timestamps
                questionnaire_completed_at TIMESTAMPTZ,
                feedback_completed_at TIMESTAMPTZ,
                created_at TIMESTAMPTZ DEFAULT NOW()
            )
        `;

        // Create indexes for better performance
        await sql`CREATE INDEX IF NOT EXISTS idx_uat_users_email ON uat_users(email)`;
        await sql`CREATE INDEX IF NOT EXISTS idx_uat_users_created_at ON uat_users(created_at)`;

    } catch (error) {
        console.error('❌ Error creating database table:', error);
        throw error;
    }
}

// Save or update questionnaire responses and generated program
async function saveQuestionnaire(questionnaireData) {
    const {
        email,
        firstName,
        lastName,
        emailOptOut,
        experience,
        whyUsingApp,
        equipmentAvailable,
        equipmentConfidence,
        trainingDays,
        sessionDuration,
        program
    } = questionnaireData;

    try {
        const result = await sql`
            INSERT INTO uat_users
            (first_name, last_name, email, email_opt_out, experience, goals, equipment, equipment_confidence,
             training_days, session_duration, program_id, program_name, questionnaire_completed_at, created_at)
            VALUES (${firstName}, ${lastName}, ${email}, ${emailOptOut ? 1 : 0}, ${experience},
                    ${JSON.stringify(whyUsingApp || [])}, ${JSON.stringify(equipmentAvailable || [])},
                    ${JSON.stringify(equipmentConfidence || {})}, ${trainingDays}, ${sessionDuration},
                    ${program.id}, ${program.name}, ${new Date().toISOString()}, ${new Date().toISOString()})
            ON CONFLICT (email) DO UPDATE SET
            first_name = EXCLUDED.first_name,
            last_name = EXCLUDED.last_name,
            email_opt_out = EXCLUDED.email_opt_out,
            experience = EXCLUDED.experience,
            goals = EXCLUDED.goals,
            equipment = EXCLUDED.equipment,
            equipment_confidence = EXCLUDED.equipment_confidence,
            training_days = EXCLUDED.training_days,
            session_duration = EXCLUDED.session_duration,
            program_id = EXCLUDED.program_id,
            program_name = EXCLUDED.program_name,
            questionnaire_completed_at = EXCLUDED.questionnaire_completed_at
            RETURNING id, email
        `;

        return {
            id: result[0].id,
            email: result[0].email,
            program: program
        };
    } catch (error) {
        console.error('❌ Error saving questionnaire:', error);
        throw error;
    }
}

// Ensure database is initialized before operations
async function ensureInitialized() {
    if (!isInitialized && !sql) {
        await initDB();
        isInitialized = true;
    }
}

// Save UAT feedback
async function saveUATFeedback(feedbackData) {
    await ensureInitialized();
    const {
        firstName,
        lastName,
        email,
        overallRating,
        lovedMost,
        improvements,
        currentApp,
        missingFeatures,
        timestamp
    } = feedbackData;

    try {
        console.log('💽 Database: Inserting feedback for:', email);
        console.log('💽 Database: lovedMost =', lovedMost);
        console.log('💽 Database: improvements =', improvements);
        console.log('💽 Database: currentApp =', currentApp);
        console.log('💽 Database: missingFeatures =', missingFeatures);

        // Use UPSERT to handle both existing and new users
        const result = await sql`
            INSERT INTO uat_users
            (first_name, last_name, email, overall_rating, loved_most, improvements,
             current_app, missing_features, feedback_completed_at, created_at)
            VALUES (${firstName || null}, ${lastName || null}, ${email}, ${overallRating},
                    ${lovedMost || null}, ${improvements || null},
                    ${currentApp || null}, ${missingFeatures || null},
                    ${timestamp}, ${new Date().toISOString()})
            ON CONFLICT (email) DO UPDATE SET
            overall_rating = EXCLUDED.overall_rating,
            loved_most = EXCLUDED.loved_most,
            improvements = EXCLUDED.improvements,
            current_app = EXCLUDED.current_app,
            missing_features = EXCLUDED.missing_features,
            feedback_completed_at = EXCLUDED.feedback_completed_at
            RETURNING email, loved_most, improvements, current_app, missing_features
        `;

        console.log('✅ Database: Feedback saved successfully');
        console.log('✅ Database: Returned values:', result[0]);

        return {
            email,
            feedbackReceived: true
        };
    } catch (error) {
        console.error('❌ Database error saving feedback:', error);
        throw error;
    }
}

// Get user by email
async function getUATUser(email) {
    await ensureInitialized();
    try {
        const result = await sql`SELECT * FROM uat_users WHERE email = ${email}`;

        if (result.length > 0) {
            const row = result[0];
            // Parse JSON fields (PostgreSQL JSONB automatically parses)
            return {
                ...row,
                goals: row.goals || [],
                equipment: row.equipment || [],
                equipment_confidence: row.equipment_confidence || {}
            };
        }

        return null;
    } catch (error) {
        console.error('❌ Error getting UAT user:', error);
        throw error;
    }
}

// Get questionnaire by email (for backward compatibility)
function getQuestionnaire(email) {
    return getUATUser(email);
}

// Get all UAT users (for analysis)
async function getAllUATUsers() {
    try {
        const result = await sql`SELECT * FROM uat_users ORDER BY created_at DESC`;

        return result.map(row => ({
            ...row,
            goals: row.goals || [],
            equipment: row.equipment || [],
            equipment_confidence: row.equipment_confidence || {}
        }));
    } catch (error) {
        console.error('❌ Error getting all UAT users:', error);
        throw error;
    }
}

// Get all UAT feedback (for backward compatibility)
async function getAllUATFeedback() {
    try {
        const result = await sql`
            SELECT * FROM uat_users
            WHERE overall_rating IS NOT NULL
            ORDER BY feedback_completed_at DESC
        `;

        return result;
    } catch (error) {
        console.error('❌ Error getting UAT feedback:', error);
        throw error;
    }
}

// Get UAT stats
async function getUATStats() {
    try {
        const stats = {};

        // Get total user count
        const totalResult = await sql`SELECT COUNT(*) as count FROM uat_users`;
        stats.totalUsers = parseInt(totalResult[0].count);

        // Get questionnaire completion count
        const questionnaireResult = await sql`SELECT COUNT(*) as count FROM uat_users WHERE questionnaire_completed_at IS NOT NULL`;
        stats.questionnaireCompletions = parseInt(questionnaireResult[0].count);

        // Get feedback count
        const feedbackResult = await sql`SELECT COUNT(*) as count FROM uat_users WHERE overall_rating IS NOT NULL`;
        stats.feedbackSubmissions = parseInt(feedbackResult[0].count);

        // Get program breakdown
        const programsResult = await sql`SELECT program_id, program_name, COUNT(*) as count FROM uat_users WHERE program_id IS NOT NULL GROUP BY program_id, program_name ORDER BY count DESC`;
        stats.programBreakdown = programsResult.map(row => ({
            ...row,
            count: parseInt(row.count)
        }));

        // Calculate completion rates
        stats.questionnaireRate = stats.totalUsers > 0 ?
            Math.round((stats.questionnaireCompletions / stats.totalUsers) * 100) : 0;
        stats.feedbackRate = stats.questionnaireCompletions > 0 ?
            Math.round((stats.feedbackSubmissions / stats.questionnaireCompletions) * 100) : 0;
        stats.overallCompletionRate = stats.totalUsers > 0 ?
            Math.round((stats.feedbackSubmissions / stats.totalUsers) * 100) : 0;

        return stats;
    } catch (error) {
        console.error('❌ Error getting UAT stats:', error);
        throw error;
    }
}

// Generate program based on questionnaire responses
function generateProgram(questionnaire) {
    const { experience, trainingDays } = questionnaire;

    // Simple program matching logic
    let programName, programId;

    if (experience === '0_months' || experience === '0_6_months') {
        if (trainingDays <= 2) {
            programName = 'Beginner Full Body Foundation';
            programId = 'beginner-2day';
        } else if (trainingDays === 3) {
            programName = 'Beginner Full Body Builder';
            programId = 'beginner-3day';
        } else {
            programName = 'Beginner Upper/Lower Split';
            programId = 'beginner-4day';
        }
    } else if (experience === '6_months_2_years') {
        if (trainingDays <= 3) {
            programName = 'Intermediate Push/Pull/Legs';
            programId = 'intermediate-3day';
        } else {
            programName = 'Intermediate Upper/Lower Power';
            programId = 'intermediate-4day';
        }
    } else {
        if (trainingDays <= 3) {
            programName = 'Advanced Push/Pull/Legs';
            programId = 'advanced-3day';
        } else {
            programName = 'Advanced Upper/Lower Power';
            programId = 'advanced-4day';
        }
    }

    return {
        id: programId,
        name: programName,
        frequency: trainingDays,
        duration: questionnaire.sessionDuration || 60,
        experience: experience,
        createdAt: new Date().toISOString(),
        user: {
            email: questionnaire.email,
            experience: experience
        }
    };
}

// Legacy functions for backward compatibility
async function saveUser(email) {
    try {
        const result = await sql`
            INSERT INTO uat_users (email)
            VALUES (${email})
            ON CONFLICT (email) DO NOTHING
            RETURNING id
        `;

        return result[0]?.id || null;
    } catch (error) {
        console.error('❌ Error saving user:', error);
        throw error;
    }
}

async function saveBetaUser(userData) {
    const { firstName, lastName, email } = userData;

    try {
        const result = await sql`
            INSERT INTO uat_users (first_name, last_name, email)
            VALUES (${firstName}, ${lastName}, ${email})
            ON CONFLICT (email) DO UPDATE SET
            first_name = EXCLUDED.first_name,
            last_name = EXCLUDED.last_name
            RETURNING id
        `;

        return {
            id: result[0].id,
            firstName,
            lastName,
            email
        };
    } catch (error) {
        console.error('❌ Error saving beta user:', error);
        throw error;
    }
}

function getBetaUser(email) {
    return getUATUser(email);
}

// Close database connection (Neon serverless doesn't need explicit cleanup)
async function closeDB() {
    // Neon serverless connections are automatically managed
    console.log('✅ Database connection closed (auto-managed by Neon)');
}

module.exports = {
    initDB,
    saveUser,
    saveBetaUser,
    saveQuestionnaire,
    saveUATFeedback,
    getBetaUser,
    getUATUser,
    getQuestionnaire,
    getAllUATUsers,
    getAllUATFeedback,
    getUATStats,
    generateProgram,
    closeDB
};