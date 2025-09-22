/**
 * trAIn MVP Backend Server
 * Streamlined single-file backend for email capture and program generation
 */

const express = require('express');
const cors = require('cors');
const path = require('path');
const { initDB, saveUser, generateProgram } = require('./database/db.js');

const app = express();
const PORT = process.env.PORT || 3001;

// Middleware
app.use(cors());
app.use(express.json());

// Serve backend JSON files FIRST
app.use('/backend', express.static(path.join(__dirname)));

// Serve frontend static files
app.use(express.static(path.join(__dirname, '../frontend')));

// Initialize database
initDB();

// API Routes
app.get('/api/health', (req, res) => {
    res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Email capture endpoint (landing page)
app.post('/api/email-capture', async (req, res) => {
    try {
        const { email } = req.body;

        // Validate email
        if (!email || !isValidEmail(email)) {
            return res.status(400).json({
                success: false,
                message: 'Valid email required'
            });
        }

        // Save user email
        await saveUser(email);
        console.log('User email captured:', email);

        res.json({
            success: true,
            message: 'Email captured successfully'
        });

    } catch (error) {
        console.error('Error capturing email:', error);
        res.status(500).json({
            success: false,
            message: 'Server error'
        });
    }
});

// Questionnaire submission endpoint
app.post('/api/submit-questionnaire', async (req, res) => {
    try {
        const { questionnaire, program } = req.body;
        const { email } = questionnaire;

        // Validate email
        if (!email || !isValidEmail(email)) {
            return res.status(400).json({
                success: false,
                message: 'Valid email required'
            });
        }

        // Save user email
        await saveUser(email);
        console.log('User saved:', email);

        // Generate program based on questionnaire (fallback if not provided)
        const generatedProgram = program || generateProgram(questionnaire);
        console.log('Program generated for:', email, generatedProgram.name);

        // In production, you'd send email here
        console.log('Program would be emailed to:', email);

        res.json({
            success: true,
            message: 'Program generated and sent to email',
            program: {
                id: generatedProgram.id,
                name: generatedProgram.name,
                frequency: generatedProgram.frequency
            }
        });

    } catch (error) {
        console.error('Error processing questionnaire:', error);
        res.status(500).json({
            success: false,
            message: 'Server error'
        });
    }
});

// Serve frontend for all other routes
app.get('*', (req, res) => {
    if (req.path.startsWith('/api/')) {
        return res.status(404).json({ success: false, message: 'API endpoint not found' });
    }
    res.sendFile(path.join(__dirname, '../frontend/index.html'));
});

// Utility functions
function isValidEmail(email) {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
}

// Start server
app.listen(PORT, () => {
    console.log('🚀 trAIn MVP Server Started');
    console.log(`📱 Frontend: http://localhost:${PORT}`);
    console.log(`🔧 API: http://localhost:${PORT}/api`);
    console.log('✅ Database: SQLite ready');
});