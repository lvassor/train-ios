/**
 * trAIn UAT Server - Complete Flow
 * Handles: Beta Landing → Questionnaire → Logger → Feedback
 * Flow: beta-landing.html → questionnaire.html → workout-logger.html → uat-feedback.html
 */

const express = require('express');
const cors = require('cors');
const path = require('path');
const {
    initDB,
    saveUser,
    saveBetaUser,
    saveQuestionnaire,
    saveUATFeedback,
    getBetaUser,
    getQuestionnaire,
    getAllUATFeedback,
    getUATStats,
    generateProgram
} = require('./database/db.js');

const app = express();
const PORT = process.env.PORT || 3001;

// Middleware
app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Serve backend JSON files (workout templates, dummy data)
app.use('/backend', express.static(path.join(__dirname)));

// Serve frontend static assets
app.use('/assets', express.static(path.join(__dirname, '../frontend/assets')));
app.use('/css', express.static(path.join(__dirname, '../frontend/css')));
app.use('/js', express.static(path.join(__dirname, '../frontend/js')));

// Initialize database on startup
initDB();

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

// Beta signup (Step 1: Landing page form submission)
app.post('/api/beta-signup', async (req, res) => {
    try {
        const { firstName, lastName, email, signupType, timestamp } = req.body;

        // Validate required fields
        if (!firstName?.trim() || !lastName?.trim() || !email?.trim()) {
            return res.status(400).json({
                success: false,
                message: 'First name, last name, and email are required'
            });
        }

        // Validate email format
        if (!isValidEmail(email.trim())) {
            return res.status(400).json({
                success: false,
                message: 'Please enter a valid email address'
            });
        }

        // Save beta user
        const userData = {
            firstName: firstName.trim(),
            lastName: lastName.trim(),
            email: email.trim().toLowerCase(),
            signupType: signupType || 'beta',
            timestamp: timestamp || new Date().toISOString()
        };

        await saveBetaUser(userData);
        console.log(`✅ Beta user registered: ${userData.firstName} ${userData.lastName} (${userData.email})`);

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
app.post('/api/submit-questionnaire', async (req, res) => {
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
        const generatedProgram = program || generateProgram(questionnaire);

        // Save questionnaire and program data
        const questionnaireData = {
            ...questionnaire,
            program: generatedProgram
        };
        await saveQuestionnaire(questionnaireData);

        // Log questionnaire completion
        console.log(`📝 Questionnaire completed: ${email} → ${generatedProgram.name}`);
        console.log(`   Experience: ${questionnaire.experience}, Days: ${questionnaire.trainingDays}, Duration: ${questionnaire.sessionDuration}min`);

        // Save user for legacy compatibility
        await saveUser(email);

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

// UAT feedback submission (Step 4: Final feedback)
app.post('/api/uat-feedback', async (req, res) => {
    try {
        const {
            firstName,
            lastName,
            email,
            programId,
            overallRating,
            lovedMost,
            improvements
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
        let userEmail = email;

        if (!userEmail) {
            // Try to get from session or require it
            return res.status(400).json({
                success: false,
                message: 'Email is required to submit feedback'
            });
        }

        // Get user details from beta_users if name not provided
        if (!userFirstName || !userLastName) {
            try {
                const betaUser = await getBetaUser(userEmail);
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
                const questionnaire = await getQuestionnaire(userEmail);
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
            timestamp: new Date().toISOString()
        };

        await saveUATFeedback(feedbackData);

        console.log(`💬 UAT feedback received from: ${userEmail}`);
        console.log(`   Rating: ${overallRating}/5 | Program: ${feedbackProgramId || 'Unknown'}`);
        console.log(`   Loved: ${lovedMost ? 'Yes' : 'No'} | Improvements: ${improvements ? 'Yes' : 'No'}`);

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

// Get UAT statistics (Internal monitoring)
app.get('/api/admin/uat-stats', async (req, res) => {
    try {
        const stats = await getUATStats();
        const allFeedback = await getAllUATFeedback();
        
        res.json({
            success: true,
            stats: {
                ...stats,
                lastUpdated: new Date().toISOString()
            },
            recentFeedback: allFeedback.slice(0, 5) // Last 5 feedback entries
        });
    } catch (error) {
        console.error('❌ Stats error:', error);
        res.status(500).json({
            success: false,
            message: 'Unable to fetch statistics'
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

        await saveUser(email);
        console.log(`📧 Legacy email captured: ${email}`);

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

// Admin interface (simple stats page)
app.get('/admin', (req, res) => {
    res.send(`
        <html>
            <head><title>trAIn UAT Admin</title></head>
            <body style="font-family: Arial; padding: 2rem;">
                <h1>trAIn UAT Dashboard</h1>
                <p>Monitor beta testing progress and feedback.</p>
                <div>
                    <a href="/api/admin/uat-stats" target="_blank">View UAT Statistics</a>
                </div>
                <script>
                    fetch('/api/admin/uat-stats')
                        .then(r => r.json())
                        .then(data => {
                            if (data.success) {
                                const programsHtml = data.stats.programBreakdown ?
                                    data.stats.programBreakdown.map(p => \`<li>\${p.program_name}: \${p.count} users</li>\`).join('') :
                                    '<li>No programs generated yet</li>';

                                document.body.innerHTML += \`
                                    <h2>UAT Progress Stats</h2>
                                    <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 2rem; margin: 1rem 0;">
                                        <div>
                                            <h3>User Journey</h3>
                                            <p>👤 Beta Signups: <strong>\${data.stats.betaUsers}</strong></p>
                                            <p>📝 Questionnaires: <strong>\${data.stats.questionnaireCompletions}</strong> (\${data.stats.questionnaireRate}%)</p>
                                            <p>💬 Feedback: <strong>\${data.stats.feedbackSubmissions}</strong> (\${data.stats.feedbackRate}%)</p>
                                            <p>🎯 Overall Completion: <strong>\${data.stats.overallCompletionRate}%</strong></p>
                                        </div>
                                        <div>
                                            <h3>Program Breakdown</h3>
                                            <ul>\${programsHtml}</ul>
                                        </div>
                                    </div>
                                    <p><em>Data refreshes on page reload</em></p>
                                \`;
                            }
                        });
                </script>
            </body>
        </html>
    `);
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

// This catch-all is redundant - the app.get('*') above already handles this

// ============================================================================
// SERVER STARTUP
// ============================================================================

app.listen(PORT, () => {
    console.log('');
    console.log('🚀 trAIn UAT Server Started');
    console.log('================================');
    console.log(`📱 Frontend: http://localhost:${PORT}`);
    console.log(`🔧 API: http://localhost:${PORT}/api`);
    console.log(`👨‍💼 Admin: http://localhost:${PORT}/admin`);
    console.log('✅ Database: SQLite initialized');
    console.log('');
    console.log('📋 UAT Flow:');
    console.log('   1. Landing Page → Beta Signup');
    console.log('   2. Questionnaire → Program Generation');
    console.log('   3. Workout Logger → Exercise Tracking');
    console.log('   4. Feedback Form → UAT Collection');
    console.log('');
    console.log('🎯 Ready for gym client testing!');
    console.log('================================');
});

// Graceful shutdown
process.on('SIGTERM', () => {
    console.log('🔄 Received SIGTERM, shutting down gracefully...');
    process.exit(0);
});

process.on('SIGINT', () => {
    console.log('🔄 Received SIGINT, shutting down gracefully...');
    process.exit(0);
});