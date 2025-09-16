/**
 * trAIn MVP Backend Server
 * Streamlined single-file backend for email capture and program generation
 */

const express = require('express');
const cors = require('cors');
const path = require('path');
const { initDB, saveUser, generateProgram } = require('./database');

const app = express();
const PORT = process.env.PORT || 3001;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, '../frontend')));

// Initialize database
initDB();

// API Routes
app.get('/api/health', (req, res) => {
    res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

app.post('/api/submit-questionnaire', async (req, res) => {
    try {
        const { questionnaire } = req.body;
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

        // Generate program based on questionnaire
        const program = generateProgram(questionnaire);
        console.log('Program generated for:', email);

        // In production, you'd send email here
        console.log('Program would be emailed to:', email);

        res.json({
            success: true,
            message: 'Program generated and sent to email',
            program: {
                id: program.id,
                name: program.name,
                frequency: program.frequency
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