/**
 * trAIn UAT Server - Complete Flow
 * Handles: Beta Landing → Questionnaire → Logger → Feedback
 * Flow: beta-landing.html → questionnaire.html → workout-logger.html → uat-feedback.html
 */

// Load environment variables
require('dotenv').config({ path: require('path').join(__dirname, '../.env') });

const express = require('express');
const cors = require('cors');
const path = require('path');
const rateLimit = require('express-rate-limit');
const helmet = require('helmet');
const { body, validationResult } = require('express-validator');

// Only import database functions if we have a DATABASE_URL
let db = {};
if (process.env.DATABASE_URL || process.env.POSTGRES_URL) {
    try {
        db = require('./database/db.js');
    } catch (error) {
        console.warn('Database module not available:', error.message);
        // Provide mock functions for development
        db = {
            initDB: async () => console.log('Mock database initialized'),
            saveUser: async () => ({ id: 'mock' }),
            saveBetaUser: async () => ({ id: 'mock' }),
            saveQuestionnaire: async () => ({ id: 'mock' }),
            saveUATFeedback: async () => ({ id: 'mock' }),
            getBetaUser: async () => null,
            getQuestionnaire: async () => null,
            getUATUser: async () => null,
            getAllUATFeedback: async () => [],
            getUATStats: async () => ({}),
            generateProgram: () => ({ id: 'mock', name: 'Mock Program' })
        };
    }
}

const app = express();
const PORT = process.env.PORT || 3001;

// Security middleware
app.use(helmet({
    contentSecurityPolicy: {
        directives: {
            defaultSrc: ["'self'"],
            styleSrc: ["'self'", "'unsafe-inline'"],
            scriptSrc: ["'self'", "'unsafe-inline'"],
            imgSrc: ["'self'", "data:", "https:"],
        },
    },
}));

// CORS with proper origin restrictions
const corsOptions = {
    origin: process.env.NODE_ENV === 'production'
        ? [process.env.ALLOWED_ORIGIN || 'https://your-app.vercel.app']
        : true,
    credentials: true
};
app.use(cors(corsOptions));

// Rate limiting with enhanced DDoS protection
const generalLimiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: process.env.NODE_ENV === 'production' ? 50 : 100, // Stricter in production
    message: {
        success: false,
        message: 'Too many requests from this IP, please try again later.'
    },
    standardHeaders: true,
    legacyHeaders: false,
    // Skip successful requests to prevent legitimate usage from being penalized
    skip: (req, res) => res.statusCode < 400,
    // More aggressive rate limiting for suspected attacks
    handler: (req, res) => {
        console.warn(`⚠️ Rate limit exceeded from IP: ${req.ip} - ${req.path}`);
        res.status(429).json({
            success: false,
            message: 'Too many requests from this IP, please try again later.',
            retryAfter: Math.round(15 * 60) // 15 minutes in seconds
        });
    }
});

const formLimiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: process.env.NODE_ENV === 'production' ? 5 : 10, // Stricter for forms in production
    message: {
        success: false,
        message: 'Too many form submissions, please try again later.'
    },
    // Progressive delay for repeat offenders
    handler: (req, res) => {
        console.warn(`🚨 Form spam detected from IP: ${req.ip} - ${req.path}`);
        res.status(429).json({
            success: false,
            message: 'Too many form submissions. Please wait before trying again.',
            retryAfter: Math.round(15 * 60)
        });
    }
});

app.use('/api/', generalLimiter);

// HTTPS enforcement in production
if (process.env.NODE_ENV === 'production') {
    app.use((req, res, next) => {
        if (req.header('x-forwarded-proto') !== 'https') {
            res.redirect(`https://${req.header('host')}${req.url}`);
        } else {
            next();
        }
    });
}

// Body parsing middleware
app.use(express.json({ limit: '1mb' })); // Reduced from 10mb
app.use(express.urlencoded({ extended: true, limit: '1mb' }));

// Serve backend JSON files (workout templates, dummy data)
app.use('/backend', express.static(path.join(__dirname)));

// Serve frontend static assets
app.use('/assets', express.static(path.join(__dirname, '../frontend/assets')));
app.use('/css', express.static(path.join(__dirname, '../frontend/css')));
app.use('/js', express.static(path.join(__dirname, '../frontend/js')));

// Initialize database on startup (async for PostgreSQL)
async function startServer() {
    try {
        await db.initDB();
        console.log('✅ Database connected and initialized');
    } catch (error) {
        console.error('❌ Failed to initialize database:', error);
        // Don't exit in serverless environment
        if (process.env.NODE_ENV !== 'production') {
            process.exit(1);
        }
    }
}

// Start the database initialization
startServer();

// ============================================================================
// API ROUTES
// ============================================================================

// Health check
app.get('/api/health', (req, res) => {
    res.json({ 
        status: 'ok', 
        timestamp: new Date().toISOString(),
        version: '2.0.0-uat'
    });
});

// Input validation middleware
const validateBetaSignup = [
    body('firstName').trim().isLength({ min: 1, max: 50 }).escape(),
    body('lastName').trim().isLength({ min: 1, max: 50 }).escape(),
    body('email').isEmail().normalizeEmail(),
    body('signupType').optional().isIn(['beta', 'waitlist']).escape()
];

const validateQuestionnaire = [
    body('questionnaire.firstName').trim().isLength({ min: 1, max: 50 }).escape(),
    body('questionnaire.lastName').trim().isLength({ min: 1, max: 50 }).escape(),
    body('questionnaire.email').isEmail().normalizeEmail(),
    body('questionnaire.experience').isIn(['0_months', '0_6_months', '6_months_2_years', '2_years_plus']),
    body('questionnaire.trainingDays').isInt({ min: 1, max: 7 }),
    body('questionnaire.sessionDuration').isInt({ min: 15, max: 180 })
];

const validateFeedback = [
    body('email').optional().isEmail().normalizeEmail(),
    body('overallRating').isInt({ min: 1, max: 5 }),
    body('lovedMost').optional().trim().isLength({ max: 500 }).escape(),
    body('improvements').optional().trim().isLength({ max: 500 }).escape(),
    body('currentApp').optional().trim().isLength({ max: 100 }).escape(),
    body('missingFeatures').optional().trim().isLength({ max: 500 }).escape()
];

// Beta signup (Step 1: Landing page form submission)
app.post('/api/beta-signup', formLimiter, validateBetaSignup, async (req, res) => {
    // Check validation results
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
        return res.status(400).json({
            success: false,
            message: 'Invalid input data',
            errors: errors.array()
        });
    }
    try {
        const { firstName, lastName, email, signupType, timestamp } = req.body;

        // Save beta user
        const userData = {
            firstName: firstName.trim(),
            lastName: lastName.trim(),
            email: email.trim().toLowerCase(),
            signupType: signupType || 'beta',
            timestamp: timestamp || new Date().toISOString()
        };

        await db.saveBetaUser(userData);

        res.json({
            success: true,
            message: 'Successfully joined beta program',
            user: {
                firstName: userData.firstName,
                lastName: userData.lastName,
                email: userData.email
            }
        });

    } catch (error) {
        console.error('❌ Beta signup error:', error);

        // Handle duplicate email
        if (error.message?.includes('UNIQUE constraint failed')) {
            return res.status(409).json({
                success: false,
                message: 'This email is already registered for the beta'
            });
        }

        res.status(500).json({
            success: false,
            message: 'Unable to process signup. Please try again.'
        });
    }
});

// Questionnaire submission (Step 2: Generate program)
app.post('/api/submit-questionnaire', formLimiter, validateQuestionnaire, async (req, res) => {
    // Check validation results
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
        return res.status(400).json({
            success: false,
            message: 'Invalid questionnaire data',
            errors: errors.array()
        });
    }
    try {
        const { questionnaire, program } = req.body;
        const { email } = questionnaire;

        if (!email || !isValidEmail(email)) {
            return res.status(400).json({
                success: false,
                message: 'Valid email required'
            });
        }

        // Generate program based on questionnaire
        const generatedProgram = program || db.generateProgram(questionnaire);

        // Save questionnaire and program data
        const questionnaireData = {
            ...questionnaire,
            program: generatedProgram
        };
        await db.saveQuestionnaire(questionnaireData);

        // Save user for legacy compatibility
        await db.saveUser(email);

        res.json({
            success: true,
            message: 'Program generated successfully',
            program: {
                id: generatedProgram.id,
                name: generatedProgram.name,
                frequency: generatedProgram.frequency,
                duration: generatedProgram.duration
            }
        });

    } catch (error) {
        console.error('❌ Questionnaire error:', error);
        res.status(500).json({
            success: false,
            message: 'Unable to generate program. Please try again.'
        });
    }
});

// Check feedback status for email
app.get('/api/feedback-status/:email', async (req, res) => {
    try {
        const { email } = req.params;

        if (!email || !isValidEmail(email)) {
            return res.status(400).json({
                success: false,
                message: 'Valid email required'
            });
        }

        const user = await db.getUATUser(email);
        const hasSubmittedFeedback = user && user.feedback_completed_at;

        res.json({
            success: true,
            hasSubmittedFeedback: !!hasSubmittedFeedback,
            userExists: !!user
        });

    } catch (error) {
        console.error('❌ Feedback status check error:', error);
        res.status(500).json({
            success: false,
            message: 'Unable to check feedback status'
        });
    }
});

// UAT feedback submission (Step 4: Final feedback)
app.post('/api/uat-feedback', formLimiter, validateFeedback, async (req, res) => {
    // Check validation results
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
        return res.status(400).json({
            success: false,
            message: 'Invalid feedback data',
            errors: errors.array()
        });
    }
    try {
        const {
            firstName,
            lastName,
            email,
            programId,
            overallRating,
            lovedMost,
            improvements,
            currentApp,
            missingFeatures
        } = req.body;

        // Rating is required
        if (!overallRating || overallRating < 1 || overallRating > 5) {
            return res.status(400).json({
                success: false,
                message: 'Please provide a rating between 1 and 5 stars'
            });
        }

        // Try to get user info if not provided
        let userFirstName = firstName;
        let userLastName = lastName;
        let userEmail = email || 'anonymous@feedback.com';

        // Allow anonymous feedback - no email requirement for MVP

        // Get user details from beta_users if name not provided
        if (!userFirstName || !userLastName) {
            try {
                const betaUser = await db.getBetaUser(userEmail);
                if (betaUser) {
                    userFirstName = userFirstName || betaUser.first_name;
                    userLastName = userLastName || betaUser.last_name;
                }
            } catch (error) {
                console.log('Could not fetch user details:', error.message);
            }
        }

        // Get program ID from questionnaire if not provided
        let feedbackProgramId = programId;
        if (!feedbackProgramId) {
            try {
                const questionnaire = await db.getQuestionnaire(userEmail);
                if (questionnaire) {
                    feedbackProgramId = questionnaire.program_id;
                }
            } catch (error) {
                console.log('Could not fetch program ID:', error.message);
            }
        }

        // Save feedback
        const feedbackData = {
            firstName: userFirstName?.trim() || null,
            lastName: userLastName?.trim() || null,
            email: userEmail.trim().toLowerCase(),
            programId: feedbackProgramId?.trim() || null,
            overallRating: parseInt(overallRating),
            lovedMost: lovedMost?.trim() || null,
            improvements: improvements?.trim() || null,
            currentApp: currentApp?.trim() || null,
            missingFeatures: missingFeatures?.trim() || null,
            timestamp: new Date().toISOString()
        };

        await db.saveUATFeedback(feedbackData);

        res.json({
            success: true,
            message: 'Thank you for your feedback! Your input helps us improve trAIn.',
            feedbackId: `fb_${Date.now()}`
        });

    } catch (error) {
        console.error('❌ Feedback submission error:', error);
        res.status(500).json({
            success: false,
            message: 'Unable to submit feedback. Please try again.'
        });
    }
});

// Workout data API endpoints (for serverless compatibility)
app.get('/api/programs', (req, res) => {
    try {
        const workoutTemplates = require(path.join(__dirname, 'workout-templates.json'));
        res.json(workoutTemplates);
    } catch (error) {
        console.error('❌ Error loading workout templates:', error);
        res.status(500).json({
            success: false,
            message: 'Unable to load workout programs'
        });
    }
});

app.get('/api/dummy-logs', (req, res) => {
    try {
        const dummyLogs = require(path.join(__dirname, 'dummy_log_data.json'));
        res.json(dummyLogs);
    } catch (error) {
        console.error('❌ Error loading dummy log data:', error);
        res.status(500).json({
            success: false,
            message: 'Unable to load dummy log data'
        });
    }
});

// Legacy email capture (backwards compatibility)
app.post('/api/email-capture', async (req, res) => {
    try {
        const { email } = req.body;

        if (!email || !isValidEmail(email)) {
            return res.status(400).json({
                success: false,
                message: 'Valid email required'
            });
        }

        await db.saveUser(email);

        res.json({
            success: true,
            message: 'Email captured successfully'
        });

    } catch (error) {
        console.error('❌ Email capture error:', error);
        res.status(500).json({
            success: false,
            message: 'Server error'
        });
    }
});

// ============================================================================
// FRONTEND ROUTES
// ============================================================================

// Specific page routes
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, '../frontend/beta-landing.html'));
});

app.get('/questionnaire', (req, res) => {
    res.sendFile(path.join(__dirname, '../frontend/questionnaire.html'));
});

app.get('/logger', (req, res) => {
    res.sendFile(path.join(__dirname, '../frontend/logger.html'));
});

app.get('/feedback', (req, res) => {
    res.sendFile(path.join(__dirname, '../frontend/uat-feedback.html'));
});

// Dev mode routes
app.get('/dev/logger', (req, res) => {
    res.redirect('/logger?dev=true');
});

// Catch-all for unmatched routes
app.get('*', (req, res) => {
    // API routes that don't exist
    if (req.path.startsWith('/api/')) {
        return res.status(404).json({ 
            success: false, 
            message: 'API endpoint not found' 
        });
    }
    
    // Redirect unknown paths to landing page
    res.redirect('/');
});

// ============================================================================
// UTILITY FUNCTIONS
// ============================================================================

function isValidEmail(email) {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
}

// ============================================================================
// ERROR HANDLING & MIDDLEWARE
// ============================================================================

// Global error handler
app.use((err, req, res, next) => {
    console.error('🚨 Unhandled error:', err);
    
    res.status(500).json({
        success: false,
        message: 'Internal server error',
        ...(process.env.NODE_ENV === 'development' && { error: err.message })
    });
});

// ============================================================================
// SERVER STARTUP (only in development)
// ============================================================================

// Only start server if not in Vercel
if (process.env.NODE_ENV !== 'production') {
    app.listen(PORT, () => {
        console.log(`trAIn UAT Server running on port ${PORT}`);
    });
}

// Graceful shutdown
process.on('SIGTERM', () => {
    process.exit(0);
});

process.on('SIGINT', () => {
    process.exit(0);
});

// Export app for Vercel
module.exports = app;