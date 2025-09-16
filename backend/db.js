/**
 * trAIn MVP Database
 * Simple SQLite operations for email storage and program generation
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

    // Create simple users table
    db.run(`
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT UNIQUE NOT NULL,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )
    `, (err) => {
        if (err) {
            console.error('Table creation failed:', err.message);
        } else {
            console.log('Database initialized');
        }
    });
}

// Save user email
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

// Generate program based on questionnaire responses
function generateProgram(questionnaire) {
    const { experience, trainingDays } = questionnaire;
    
    // Simple program matching logic
    let programName, programId;
    
    if (experience === '0_months' || experience === '0_6_months') {
        if (trainingDays <= 2) {
            programName = 'Beginner Full Body Foundation';
            programId = 'beginner_2_day';
        } else if (trainingDays === 3) {
            programName = 'Beginner Full Body Builder';
            programId = 'beginner_3_day';
        } else {
            programName = 'Beginner Upper/Lower Split';
            programId = 'beginner_4_day';
        }
    } else if (experience === '6_months_2_years') {
        if (trainingDays <= 3) {
            programName = 'Intermediate Full Body';
            programId = 'intermediate_3_day';
        } else {
            programName = 'Intermediate Upper/Lower';
            programId = 'intermediate_4_day';
        }
    } else {
        if (trainingDays <= 3) {
            programName = 'Advanced Push/Pull/Legs';
            programId = 'advanced_3_day';
        } else {
            programName = 'Advanced Upper/Lower Power';
            programId = 'advanced_4_day';
        }
    }

    return {
        id: `custom_${Date.now()}`,
        name: programName,
        templateId: programId,
        frequency: trainingDays,
        duration: 8,
        createdAt: new Date().toISOString(),
        user: {
            email: questionnaire.email,
            experience: experience
        }
    };
}

module.exports = {
    initDB,
    saveUser,
    generateProgram
};