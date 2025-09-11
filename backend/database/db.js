const sqlite3 = require('sqlite3').verbose();
const fs = require('fs');
const path = require('path');

const DB_PATH = path.join(__dirname, 'train.db');

// Create database connection
const db = new sqlite3.Database(DB_PATH, (err) => {
    if (err) {
        console.error('Error opening database:', err.message);
        process.exit(1);
    }
    console.log('Connected to SQLite database');
});

// Initialize database with schema
function initializeDatabase() {
    const schemaPath = path.join(__dirname, 'schema.sql');
    const schema = fs.readFileSync(schemaPath, 'utf8');
    
    // Split schema into individual statements
    const statements = schema.split(';').filter(stmt => stmt.trim());
    
    return new Promise((resolve, reject) => {
        db.serialize(() => {
            statements.forEach((statement, index) => {
                if (statement.trim()) {
                    db.run(statement, (err) => {
                        if (err) {
                            console.error(`Error executing statement ${index + 1}:`, err.message);
                            reject(err);
                        }
                    });
                }
            });
            
            console.log('Database initialized successfully');
            resolve();
        });
    });
}

// Database helper functions
const dbHelpers = {
    // Get user by email
    getUserByEmail: (email) => {
        return new Promise((resolve, reject) => {
            db.get(
                'SELECT * FROM users WHERE email = ?',
                [email],
                (err, row) => {
                    if (err) reject(err);
                    else resolve(row);
                }
            );
        });
    },

    // Create or update user
    createOrUpdateUser: (email, firstName, lastName) => {
        return new Promise((resolve, reject) => {
            db.run(
                `INSERT INTO users (email, first_name, last_name) 
                 VALUES (?, ?, ?) 
                 ON CONFLICT(email) DO UPDATE SET
                    first_name = excluded.first_name,
                    last_name = excluded.last_name,
                    updated_at = CURRENT_TIMESTAMP`,
                [email, firstName, lastName],
                function(err) {
                    if (err) {
                        reject(err);
                    } else {
                        // Get the user ID
                        db.get(
                            'SELECT id FROM users WHERE email = ?',
                            [email],
                            (err, row) => {
                                if (err) reject(err);
                                else resolve(row.id);
                            }
                        );
                    }
                }
            );
        });
    },

    // Insert questionnaire response
    insertResponse: (responseData) => {
        return new Promise((resolve, reject) => {
            const {
                userId, experience, whyUsingApp, equipmentAvailable,
                equipmentConfidence, trainingDays, additionalInfo,
                ipAddress, userAgent, sessionId
            } = responseData;

            db.run(
                `INSERT INTO questionnaire_responses (
                    user_id, session_id, experience, why_using_app, 
                    equipment_available, equipment_confidence, training_days, 
                    additional_info, ip_address, user_agent
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
                [
                    userId, sessionId, experience,
                    JSON.stringify(whyUsingApp),
                    JSON.stringify(equipmentAvailable),
                    JSON.stringify(equipmentConfidence),
                    trainingDays, additionalInfo, ipAddress, userAgent
                ],
                function(err) {
                    if (err) {
                        reject(err);
                    } else {
                        resolve(this.lastID);
                    }
                }
            );
        });
    },

    // Get all responses for analytics
    getAllResponses: () => {
        return new Promise((resolve, reject) => {
            db.all('SELECT * FROM response_analytics ORDER BY submitted_at DESC', (err, rows) => {
                if (err) reject(err);
                else resolve(rows);
            });
        });
    }
};

// Initialize database if this file is run directly
if (require.main === module) {
    initializeDatabase()
        .then(() => {
            console.log('Database setup complete');
            db.close();
        })
        .catch((err) => {
            console.error('Database setup failed:', err);
            process.exit(1);
        });
}

module.exports = { db, initializeDatabase, dbHelpers };