-- trAIn Database Schema
-- Updated to support email capture flow where names are optional

-- Create users table
CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    email TEXT UNIQUE NOT NULL,
    first_name TEXT,  -- Removed NOT NULL - names are optional during email capture
    last_name TEXT,   -- Removed NOT NULL - names are optional during email capture
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

-- Create programs table to store generated workout programs
CREATE TABLE IF NOT EXISTS programs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER,
    program_id TEXT UNIQUE, -- Custom program ID like "prog_1234567890"
    template_id TEXT NOT NULL, -- Reference to template used (e.g., "beginner_3_day")
    program_name TEXT NOT NULL,
    program_data TEXT NOT NULL, -- JSON string of complete program object
    frequency INTEGER NOT NULL, -- Training days per week
    duration_weeks INTEGER NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users (id)
);

-- Create email_captures table to track initial email signups
CREATE TABLE IF NOT EXISTS email_captures (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    email TEXT NOT NULL,
    user_id INTEGER,
    captured_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    ip_address TEXT,
    user_agent TEXT,
    completed_questionnaire BOOLEAN DEFAULT FALSE, -- Track if they completed the flow
    FOREIGN KEY (user_id) REFERENCES users (id)
);

-- Create analytics_events table for tracking user interactions
CREATE TABLE IF NOT EXISTS analytics_events (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    event_name TEXT NOT NULL,
    user_email TEXT,
    event_data TEXT, -- JSON string of event properties
    session_id TEXT,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    ip_address TEXT,
    user_agent TEXT
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_responses_user_id ON questionnaire_responses(user_id);
CREATE INDEX IF NOT EXISTS idx_responses_submitted_at ON questionnaire_responses(submitted_at);
CREATE INDEX IF NOT EXISTS idx_programs_user_id ON programs(user_id);
CREATE INDEX IF NOT EXISTS idx_programs_program_id ON programs(program_id);
CREATE INDEX IF NOT EXISTS idx_programs_created_at ON programs(created_at);
CREATE INDEX IF NOT EXISTS idx_email_captures_email ON email_captures(email);
CREATE INDEX IF NOT EXISTS idx_email_captures_captured_at ON email_captures(captured_at);
CREATE INDEX IF NOT EXISTS idx_analytics_events_timestamp ON analytics_events(timestamp);
CREATE INDEX IF NOT EXISTS idx_analytics_events_user_email ON analytics_events(user_email);

-- Create view for analytics (updated to handle nullable names)
CREATE VIEW IF NOT EXISTS response_analytics AS
SELECT 
    qr.id,
    u.email,
    COALESCE(u.first_name, '') as first_name,  -- Handle null names gracefully
    COALESCE(u.last_name, '') as last_name,   -- Handle null names gracefully
    qr.experience,
    qr.why_using_app,
    qr.equipment_available,
    qr.equipment_confidence,
    qr.training_days,
    qr.additional_info,
    qr.submitted_at
FROM questionnaire_responses qr
LEFT JOIN users u ON qr.user_id = u.id;

-- Create view for user program summary
CREATE VIEW IF NOT EXISTS user_program_summary AS
SELECT 
    u.email,
    u.first_name,
    u.last_name,
    p.program_id,
    p.program_name,
    p.template_id,
    p.frequency,
    p.duration_weeks,
    p.created_at as program_created_at,
    qr.experience,
    qr.training_days as requested_days
FROM users u
LEFT JOIN programs p ON u.id = p.user_id
LEFT JOIN questionnaire_responses qr ON u.id = qr.user_id
ORDER BY p.created_at DESC;

-- Create view for email capture funnel analysis
CREATE VIEW IF NOT EXISTS email_funnel_analytics AS
SELECT 
    ec.email,
    ec.captured_at,
    ec.completed_questionnaire,
    u.first_name,
    u.last_name,
    qr.submitted_at as questionnaire_completed_at,
    p.created_at as program_generated_at,
    CASE 
        WHEN p.id IS NOT NULL THEN 'Program Generated'
        WHEN qr.id IS NOT NULL THEN 'Questionnaire Completed'
        WHEN u.id IS NOT NULL THEN 'Email Captured'
        ELSE 'Unknown'
    END as funnel_stage
FROM email_captures ec
LEFT JOIN users u ON ec.user_id = u.id
LEFT JOIN questionnaire_responses qr ON u.id = qr.user_id
LEFT JOIN programs p ON u.id = p.user_id
ORDER BY ec.captured_at DESC;