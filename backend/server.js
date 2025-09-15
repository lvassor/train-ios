/**
 * trAIn Backend Server
 * 
 * Handles:
 * - Email capture from landing page
 * - Questionnaire submission and processing
 * - Static file serving for frontend
 * 
 * @author trAIn Team
 * @version 2.0
 */

const express = require('express');
const cors = require('cors');
const path = require('path');
const { initializeDatabase, dbHelpers } = require('./database/db');

// Import services
const ProgramService = require('./services/program-service');
const EmailService = require('./services/email-service');

const app = express();
const PORT = 3001;

// ============================================================================
// MIDDLEWARE SETUP
// ============================================================================

app.use(cors());
app.use(express.json());

// Serve static files from frontend directory
app.use(express.static(path.join(__dirname, '../frontend')));

// ============================================================================
// UTILITY FUNCTIONS
// ============================================================================

/**
 * Validate email format
 * @param {string} email - Email address to validate
 * @returns {boolean} - True if email format is valid
 */
function isValidEmail(email) {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
}

// ============================================================================
// API ENDPOINTS
// ============================================================================

/**
 * Health check endpoint
 */
app.get('/api/health', (req, res) => {
    res.json({ 
        message: 'Server is working!',
        timestamp: new Date().toISOString(),
        version: '2.0'
    });
});

/**
 * Email capture endpoint
 * Called from the landing page when user enters their email
 */
app.post('/api/email-capture', async (req, res) => {
    try {
        const { email } = req.body;
        
        if (!email || !isValidEmail(email)) {
            return res.status(400).json({
                success: false,
                message: 'Valid email address is required'
            });
        }

        console.log('Email captured:', email);

        // Store email capture in database
        const userId = await dbHelpers.createOrUpdateUser(email);
        console.log('User created/updated with ID:', userId);

        res.json({
            success: true,
            message: 'Email captured successfully',
            userId
        });

    } catch (error) {
        console.error('Error capturing email:', error);
        res.status(500).json({
            success: false,
            message: 'Server error: ' + error.message
        });
    }
});

/**
 * Complete questionnaire submission and program generation endpoint
 * This is the main endpoint called by the frontend after questionnaire completion
 */
app.post('/api/questionnaire/submit', async (req, res) => {
    try {
        console.log('Received complete submission:', req.body);
        
        const {
            questionnaire,
            program,
            timestamp
        } = req.body;

        // Extract questionnaire data (supporting both old and new formats)
        const questionnaireData = questionnaire || req.body;
        const userEmail = questionnaireData.email;

        if (!userEmail || !isValidEmail(userEmail)) {
            return res.status(400).json({
                success: false,
                message: 'Valid email address is required'
            });
        }

        // Create or update user
        const userId = await dbHelpers.createOrUpdateUser(userEmail);
        console.log('User found/created with ID:', userId);

        // Save questionnaire response
        const responseId = await dbHelpers.insertResponse({
            userId,
            experience: questionnaireData.experience,
            whyUsingApp: questionnaireData.whyUsingApp,
            equipmentAvailable: questionnaireData.equipmentAvailable,
            equipmentConfidence: questionnaireData.equipmentConfidence,
            trainingDays: questionnaireData.trainingDays,
            additionalInfo: questionnaireData.additionalInfo,
            ipAddress: req.ip,
            userAgent: req.get('User-Agent')
        });

        console.log('Questionnaire response saved with ID:', responseId);

        // Generate program if not provided
        let programToSave = program;
        if (!programToSave) {
            console.log('No program provided, generating new program');
            programToSave = ProgramService.generateProgram(questionnaireData);
        }

        // Save program to database
        const programId = await ProgramService.saveProgramToDatabase(programToSave, userEmail);
        programToSave.id = programId;

        // Send program via email
        try {
            await EmailService.sendProgramEmail(userEmail, programToSave);
            console.log('Program email sent successfully');
        } catch (emailError) {
            console.warn('Failed to send program email:', emailError.message);
            // Continue without failing the entire request
        }

        res.json({
            success: true,
            message: 'Questionnaire submitted and program generated successfully',
            data: {
                responseId,
                programId,
                program: programToSave
            }
        });

    } catch (error) {
        console.error('Error in questionnaire submission:', error);
        res.status(500).json({
            success: false,
            message: 'Server error: ' + error.message
        });
    }
});

/**
 * Legacy questionnaire submission endpoint
 * Maintained for backwards compatibility
 */
app.post('/api/questionnaire/submit-legacy', async (req, res) => {
    try {
        console.log('Received legacy questionnaire data:', req.body);
        
        const {
            email, firstName, lastName, experience, whyUsingApp,
            equipmentAvailable, equipmentConfidence, trainingDays, additionalInfo
        } = req.body;

        if (!email || !isValidEmail(email)) {
            return res.status(400).json({
                success: false,
                message: 'Valid email address is required'
            });
        }

        // Create user (firstName and lastName optional)
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

        console.log('Legacy response saved with ID:', responseId);

        res.json({
            success: true,
            message: 'Questionnaire submitted successfully!',
            responseId
        });

    } catch (error) {
        console.error('Error submitting legacy questionnaire:', error);
        res.status(500).json({
            success: false,
            message: 'Server error: ' + error.message
        });
    }
});

/**
 * Program generation endpoint
 * Can be called independently to generate programs
 */
app.post('/api/programs/generate', async (req, res) => {
    try {
        console.log('Generating program for:', req.body);
        
        const formData = req.body;
        
        if (!formData.email || !isValidEmail(formData.email)) {
            return res.status(400).json({
                success: false,
                message: 'Valid email address is required'
            });
        }

        // Generate program using the service
        const program = ProgramService.generateProgram(formData);
        
        // Save program to database
        try {
            const programId = await ProgramService.saveProgramToDatabase(program, formData.email);
            program.id = programId;
            console.log('Program saved to database with ID:', programId);
        } catch (dbError) {
            console.warn('Could not save program to database:', dbError.message);
            // Continue without database save
        }

        // Optionally send email
        if (formData.sendEmail !== false) {
            try {
                await EmailService.sendProgramEmail(formData.email, program);
                console.log('Program email sent');
            } catch (emailError) {
                console.warn('Failed to send program email:', emailError.message);
            }
        }

        res.json({
            success: true,
            message: 'Program generated successfully',
            program
        });

    } catch (error) {
        console.error('Error generating program:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to generate program: ' + error.message
        });
    }
});

/**
 * Get user's programs endpoint
 * Retrieve all programs for a specific user
 */
app.get('/api/programs/user/:email', async (req, res) => {
    try {
        const email = req.params.email;
        
        if (!email || !isValidEmail(email)) {
            return res.status(400).json({
                success: false,
                message: 'Valid email address is required'
            });
        }
        
        // TODO: Implement database retrieval
        // For now, return empty array
        res.json({
            success: true,
            programs: [],
            message: 'No programs found (database retrieval not yet implemented)'
        });
        
    } catch (error) {
        console.error('Error fetching user programs:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch programs: ' + error.message
        });
    }
});

/**
 * Get specific program by ID
 */
app.get('/api/programs/:programId', async (req, res) => {
    try {
        const programId = req.params.programId;
        
        // TODO: Implement database retrieval
        // For now, return not found
        res.status(404).json({
            success: false,
            message: 'Program not found (database retrieval not yet implemented)'
        });
        
    } catch (error) {
        console.error('Error fetching program:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch program: ' + error.message
        });
    }
});

/**
 * Program templates endpoint
 * Returns all available program templates
 */
app.get('/api/programs/templates', (req, res) => {
    try {
        const templates = ProgramService.getProgramTemplates();
        res.json({
            success: true,
            templates
        });
    } catch (error) {
        console.error('Error fetching templates:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch templates: ' + error.message
        });
    }
});

/**
 * Get specific template by ID
 */
app.get('/api/programs/templates/:templateId', (req, res) => {
    try {
        const templateId = req.params.templateId;
        const template = ProgramService.getProgramTemplate(templateId);
        
        if (template) {
            res.json({
                success: true,
                template
            });
        } else {
            res.status(404).json({
                success: false,
                message: 'Template not found'
            });
        }
    } catch (error) {
        console.error('Error fetching template:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch template: ' + error.message
        });
    }
});

/**
 * Analytics endpoint for tracking user events
 * Can be used to log user interactions and program generation metrics
 */
app.post('/api/analytics/track', async (req, res) => {
    try {
        const { event, data, timestamp } = req.body;
        
        console.log('Analytics event:', {
            event,
            data,
            timestamp: timestamp || new Date().toISOString(),
            ip: req.ip,
            userAgent: req.get('User-Agent')
        });
        
        // TODO: Implement analytics storage
        // For now, just log the event
        
        res.json({
            success: true,
            message: 'Event tracked successfully'
        });
        
    } catch (error) {
        console.error('Error tracking analytics event:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to track event: ' + error.message
        });
    }
});

/**
 * Contact/feedback endpoint
 * For user inquiries or feedback submission
 */
app.post('/api/contact', async (req, res) => {
    try {
        const { email, name, message, type } = req.body;
        
        if (!email || !message) {
            return res.status(400).json({
                success: false,
                message: 'Email and message are required'
            });
        }
        
        console.log('Contact form submission:', {
            email,
            name,
            message,
            type: type || 'general',
            timestamp: new Date().toISOString()
        });
        
        // TODO: Implement contact form handling
        // Could save to database and/or send notification email
        
        res.json({
            success: true,
            message: 'Message received successfully'
        });
        
    } catch (error) {
        console.error('Error processing contact form:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to process message: ' + error.message
        });
    }
});

// ============================================================================
// STATIC FILE SERVING AND FALLBACK ROUTES
// ============================================================================

/**
 * Serve frontend for any non-API routes
 * This enables client-side routing for the single-page application
 */
app.get('*', (req, res) => {
    // Don't serve HTML for API routes that weren't found
    if (req.path.startsWith('/api/')) {
        return res.status(404).json({
            success: false,
            message: 'API endpoint not found'
        });
    }
    
    // Serve the main HTML file for all other routes
    res.sendFile(path.join(__dirname, '../frontend/index.html'));
});

// ============================================================================
// ERROR HANDLING MIDDLEWARE
// ============================================================================

/**
 * Global error handler
 * Catches any unhandled errors and returns appropriate responses
 */
app.use((err, req, res, next) => {
    console.error('Unhandled error:', err);
    
    res.status(500).json({
        success: false,
        message: 'Internal server error',
        ...(process.env.NODE_ENV === 'development' && { error: err.message })
    });
});

/**
 * 404 handler for API routes
 */
app.use('/api/*', (req, res) => {
    res.status(404).json({
        success: false,
        message: 'API endpoint not found'
    });
});

// ============================================================================
// SERVER INITIALIZATION
// ============================================================================

/**
 * Start the server with proper error handling and database initialization
 */
async function startServer() {
    try {
        // Initialize database connection
        await initializeDatabase();
        console.log('Database initialized successfully');
        
        // Start the HTTP server
        app.listen(PORT, () => {
            console.log('='.repeat(50));
            console.log('🚀 trAIn Backend Server Started');
            console.log('='.repeat(50));
            console.log(`🌐 Server running on: http://localhost:${PORT}`);
            console.log(`📱 Frontend available at: http://localhost:${PORT}`);
            console.log(`🔧 API base URL: http://localhost:${PORT}/api`);
            console.log(`📊 Health check: http://localhost:${PORT}/api/health`);
            console.log('='.repeat(50));
            console.log('✅ Database: Connected and ready');
            console.log('✅ Program generation: Ready');
            console.log('✅ Email capture: Ready');
            console.log('✅ Static files: Serving from frontend directory');
            console.log('='.repeat(50));
            
            // Log available endpoints
            console.log('📋 Available API Endpoints:');
            console.log('   POST /api/email-capture');
            console.log('   POST /api/questionnaire/submit');
            console.log('   POST /api/programs/generate');
            console.log('   GET  /api/programs/templates');
            console.log('   GET  /api/programs/user/:email');
            console.log('   POST /api/analytics/track');
            console.log('   POST /api/contact');
            console.log('   GET  /api/health');
            console.log('='.repeat(50));
        });
        
    } catch (error) {
        console.error('❌ Failed to start server:', error);
        console.error('Please check your database configuration and try again.');
        process.exit(1);
    }
}

// Handle graceful shutdown
process.on('SIGTERM', () => {
    console.log('SIGTERM received, shutting down gracefully');
    process.exit(0);
});

process.on('SIGINT', () => {
    console.log('SIGINT received, shutting down gracefully');
    process.exit(0);
});

// Start the server
startServer();