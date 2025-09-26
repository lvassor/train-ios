/**
 * trAIn UAT Database
 * SQLite operations for beta users, questionnaires, and UAT feedback
 */

const sqlite3 = require('sqlite3').verbose();
const path = require('path');

const DB_PATH = path.join(__dirname, 'train.db');
let db;

// Initialize database
function initDB() {
    db = new sqlite3.Database(DB_PATH, (err) => {
        if (err) {
            console.error('Database connection failed:', err.message);
            process.exit(1);
        }
        console.log('Connected to SQLite database');
    });

    // Create tables in sequence
    createTables();
}

function createTables() {
    // Legacy users table (for backwards compatibility)
    db.run(`
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT UNIQUE NOT NULL,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )
    `, (err) => {
        if (err) {
            console.error('Users table creation failed:', err.message);
        }
    });

    // Beta users table (for UAT participants)
    db.run(`
        CREATE TABLE IF NOT EXISTS beta_users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            first_name TEXT NOT NULL,
            last_name TEXT NOT NULL,
            email TEXT UNIQUE NOT NULL,
            signup_type TEXT DEFAULT 'beta',
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )
    `, (err) => {
        if (err) {
            console.error('Beta users table creation failed:', err.message);
        }
    });

    // Questionnaires table (stores responses and generated programs)
    db.run(`
        CREATE TABLE IF NOT EXISTS questionnaires (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT NOT NULL,
            experience TEXT,
            goals TEXT, -- JSON array of whyUsingApp
            equipment TEXT, -- JSON array of equipmentAvailable
            equipment_confidence TEXT, -- JSON object of confidence ratings
            training_days INTEGER,
            session_duration INTEGER,
            program_id TEXT,
            program_name TEXT,
            email_opt_out BOOLEAN DEFAULT 0,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (email) REFERENCES beta_users (email)
        )
    `, (err) => {
        if (err) {
            console.error('Questionnaires table creation failed:', err.message);
        }
    });

    // UAT feedback table
    db.run(`
        CREATE TABLE IF NOT EXISTS uat_feedback (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            first_name TEXT,
            last_name TEXT,
            email TEXT NOT NULL,
            program_id TEXT,
            overall_rating INTEGER,
            loved_most TEXT,
            improvements TEXT,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (email) REFERENCES beta_users (email)
        )
    `, (err) => {
        if (err) {
            console.error('UAT feedback table creation failed:', err.message);
        } else {
            console.log('Database tables initialized');
            // Create indexes for better query performance
            createIndexes();
        }
    });
}

function createIndexes() {
    // Index on questionnaires.email for faster lookups
    db.run('CREATE INDEX IF NOT EXISTS idx_questionnaires_email ON questionnaires(email)', (err) => {
        if (err) console.error('Index creation failed:', err.message);
    });

    // Index on uat_feedback.email for faster lookups
    db.run('CREATE INDEX IF NOT EXISTS idx_uat_feedback_email ON uat_feedback(email)', (err) => {
        if (err) console.error('Index creation failed:', err.message);
    });

    // Index on created_at fields for time-based queries
    db.run('CREATE INDEX IF NOT EXISTS idx_beta_users_created_at ON beta_users(created_at)', (err) => {
        if (err) console.error('Index creation failed:', err.message);
    });
}

// Save user email (legacy function)
function saveUser(email) {
    return new Promise((resolve, reject) => {
        db.run(
            'INSERT OR IGNORE INTO users (email) VALUES (?)',
            [email],
            function(err) {
                if (err) {
                    reject(err);
                } else {
                    resolve(this.lastID);
                }
            }
        );
    });
}

// Save beta user (for UAT)
function saveBetaUser(userData) {
    const { firstName, lastName, email, signupType, timestamp } = userData;
    
    return new Promise((resolve, reject) => {
        db.run(
            `INSERT INTO beta_users (first_name, last_name, email, signup_type, created_at) 
             VALUES (?, ?, ?, ?, ?)`,
            [firstName, lastName, email, signupType, timestamp],
            function(err) {
                if (err) {
                    reject(err);
                } else {
                    resolve({
                        id: this.lastID,
                        firstName,
                        lastName,
                        email,
                        signupType
                    });
                }
            }
        );
    });
}

// Save questionnaire responses and generated program
function saveQuestionnaire(questionnaireData) {
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

    return new Promise((resolve, reject) => {
        db.run(
            `INSERT INTO questionnaires
             (email, experience, goals, equipment, equipment_confidence, training_days, session_duration, program_id, program_name, email_opt_out, created_at)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
            [
                email,
                experience,
                JSON.stringify(whyUsingApp || []),
                JSON.stringify(equipmentAvailable || []),
                JSON.stringify(equipmentConfidence || {}),
                trainingDays,
                sessionDuration,
                program.id,
                program.name,
                emailOptOut ? 1 : 0,
                new Date().toISOString()
            ],
            function(err) {
                if (err) {
                    reject(err);
                } else {
                    resolve({
                        id: this.lastID,
                        email,
                        program: program
                    });
                }
            }
        );
    });
}

// Save UAT feedback
function saveUATFeedback(feedbackData) {
    const {
        firstName,
        lastName,
        email,
        programId,
        overallRating,
        lovedMost,
        improvements,
        timestamp
    } = feedbackData;

    return new Promise((resolve, reject) => {
        db.run(
            `INSERT INTO uat_feedback
             (first_name, last_name, email, program_id, overall_rating, loved_most, improvements, created_at)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
            [firstName, lastName, email, programId, overallRating, lovedMost, improvements, timestamp],
            function(err) {
                if (err) {
                    reject(err);
                } else {
                    resolve({
                        id: this.lastID,
                        email,
                        feedbackReceived: true
                    });
                }
            }
        );
    });
}

// Get beta user by email
function getBetaUser(email) {
    return new Promise((resolve, reject) => {
        db.get(
            'SELECT * FROM beta_users WHERE email = ?',
            [email],
            (err, row) => {
                if (err) {
                    reject(err);
                } else {
                    resolve(row);
                }
            }
        );
    });
}

// Get questionnaire by email
function getQuestionnaire(email) {
    return new Promise((resolve, reject) => {
        db.get(
            'SELECT * FROM questionnaires WHERE email = ?',
            [email],
            (err, row) => {
                if (err) {
                    reject(err);
                } else {
                    if (row) {
                        // Parse JSON fields
                        row.goals = JSON.parse(row.goals || '[]');
                        row.equipment = JSON.parse(row.equipment || '[]');
                        row.equipment_confidence = JSON.parse(row.equipment_confidence || '{}');
                    }
                    resolve(row);
                }
            }
        );
    });
}

// Get all UAT feedback (for analysis)
function getAllUATFeedback() {
    return new Promise((resolve, reject) => {
        db.all(
            `SELECT 
                f.*,
                b.first_name as beta_first_name,
                b.last_name as beta_last_name,
                b.signup_type,
                b.created_at as signup_date
             FROM uat_feedback f
             LEFT JOIN beta_users b ON f.email = b.email
             ORDER BY f.created_at DESC`,
            [],
            (err, rows) => {
                if (err) {
                    reject(err);
                } else {
                    resolve(rows);
                }
            }
        );
    });
}

// Get UAT stats
function getUATStats() {
    return new Promise((resolve, reject) => {
        const stats = {};

        // Get beta user count
        db.get('SELECT COUNT(*) as count FROM beta_users', (err, row) => {
            if (err) return reject(err);
            stats.betaUsers = row.count;

            // Get questionnaire completion count
            db.get('SELECT COUNT(*) as count FROM questionnaires', (err, row) => {
                if (err) return reject(err);
                stats.questionnaireCompletions = row.count;

                // Get feedback count
                db.get('SELECT COUNT(*) as count FROM uat_feedback', (err, row) => {
                    if (err) return reject(err);
                    stats.feedbackSubmissions = row.count;

                    // Get program breakdown
                    db.all('SELECT program_id, program_name, COUNT(*) as count FROM questionnaires GROUP BY program_id ORDER BY count DESC', (err, programs) => {
                        if (err) return reject(err);
                        stats.programBreakdown = programs;

                        // Calculate completion rates
                        stats.questionnaireRate = stats.betaUsers > 0 ?
                            Math.round((stats.questionnaireCompletions / stats.betaUsers) * 100) : 0;
                        stats.feedbackRate = stats.questionnaireCompletions > 0 ?
                            Math.round((stats.feedbackSubmissions / stats.questionnaireCompletions) * 100) : 0;
                        stats.overallCompletionRate = stats.betaUsers > 0 ?
                            Math.round((stats.feedbackSubmissions / stats.betaUsers) * 100) : 0;

                        resolve(stats);
                    });
                });
            });
        });
    });
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

// Close database connection
function closeDB() {
    if (db) {
        db.close((err) => {
            if (err) {
                console.error('Error closing database:', err.message);
            } else {
                console.log('Database connection closed');
            }
        });
    }
}

// Handle graceful shutdown
process.on('SIGINT', () => {
    console.log('Shutting down gracefully...');
    closeDB();
    process.exit(0);
});

module.exports = {
    initDB,
    saveUser,
    saveBetaUser,
    saveQuestionnaire,
    saveUATFeedback,
    getBetaUser,
    getQuestionnaire,
    getAllUATFeedback,
    getUATStats,
    generateProgram,
    closeDB
};