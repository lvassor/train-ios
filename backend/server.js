const express = require('express');
const cors = require('cors');
const path = require('path');
const { initializeDatabase, dbHelpers } = require('./database/db');

const app = express();
const PORT = 3001;

// Middleware
app.use(cors());
app.use(express.json());

// Serve static files from frontend directory
app.use(express.static(path.join(__dirname, '../frontend')));

// API routes
app.get('/api/health', (req, res) => {
    res.json({ message: 'Server is working!' });
});

app.post('/api/questionnaire/submit', async (req, res) => {
    try {
        console.log('Received data:', req.body);
        
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
        console.error('Error:', error);
        res.status(500).json({
            success: false,
            message: 'Server error: ' + error.message
        });
    }
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
        });
    } catch (error) {
        console.error('Failed to start server:', error);
    }
}

startServer();