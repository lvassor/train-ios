-- Create users table
CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    email TEXT UNIQUE NOT NULL,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Create questionnaire_responses table
CREATE TABLE IF NOT EXISTS questionnaire_responses (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER,
    session_id TEXT,
    experience TEXT NOT NULL,
    why_using_app TEXT, -- JSON string of array
    equipment_available TEXT, -- JSON string of array
    equipment_confidence TEXT, -- JSON string of object
    training_days INTEGER NOT NULL,
    additional_info TEXT,
    submitted_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    ip_address TEXT,
    user_agent TEXT,
    FOREIGN KEY (user_id) REFERENCES users (id)
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_responses_user_id ON questionnaire_responses(user_id);
CREATE INDEX IF NOT EXISTS idx_responses_submitted_at ON questionnaire_responses(submitted_at);

-- Create view for analytics
CREATE VIEW IF NOT EXISTS response_analytics AS
SELECT 
    qr.id,
    u.email,
    u.first_name,
    u.last_name,
    qr.experience,
    qr.why_using_app,
    qr.equipment_available,
    qr.equipment_confidence,
    qr.training_days,
    qr.additional_info,
    qr.submitted_at
FROM questionnaire_responses qr
LEFT JOIN users u ON qr.user_id = u.id;