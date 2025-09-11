const express = require('express');
const { dbHelpers } = require('../database/db');
const { questionnaireValidation, handleValidationErrors } = require('../middleware/validation');
const { v4: uuidv4 } = require('crypto');

const router = express.Router();

// Submit questionnaire
router.post('/submit', questionnaireValidation, handleValidationErrors, async (req, res) => {
    try {
        const {
            email, firstName, lastName, experience, whyUsingApp,
            equipmentAvailable, equipmentConfidence, trainingDays, additionalInfo
        } = req.body;

        // Get client IP and user agent
        const ipAddress = req.ip || req.connection.remoteAddress;
        const userAgent = req.get('User-Agent') || '';
        const sessionId = uuidv4();

        // Create or update user
        const userId = await dbHelpers.createOrUpdateUser(email, firstName, lastName);

        // Insert questionnaire response
        const responseId = await dbHelpers.insertResponse({
            userId,
            sessionId,
            experience,
            whyUsingApp,
            equipmentAvailable,
            equipmentConfidence,
            trainingDays,
            additionalInfo,
            ipAddress,
            userAgent
        });

        res.json({
            success: true,
            message: 'Questionnaire submitted successfully',
            responseId,
            sessionId
        });

        // Log success for monitoring
        console.log(`New questionnaire submission: User ${userId}, Response ${responseId}`);

    } catch (error) {
        console.error('Error submitting questionnaire:', error);
        res.status(500).json({
            success: false,
            message: 'Internal server error. Please try again.'
        });
    }
});

// Get analytics data (protected endpoint)
router.get('/analytics', async (req, res) => {
    try {
        // In production, add authentication middleware here
        const responses = await dbHelpers.getAllResponses();
        
        // Basic analytics
        const analytics = {
            totalResponses: responses.length,
            experienceDistribution: {},
            equipmentPopularity: {},
            averageTrainingDays: 0,
            submissionsByDate: {}
        };

        // Calculate analytics
        responses.forEach(response => {
            // Experience distribution
            analytics.experienceDistribution[response.experience] = 
                (analytics.experienceDistribution[response.experience] || 0) + 1;

            // Equipment popularity
            if (response.equipment_available) {
                const equipment = JSON.parse(response.equipment_available);
                equipment.forEach(item => {
                    analytics.equipmentPopularity[item] = 
                        (analytics.equipmentPopularity[item] || 0) + 1;
                });
            }

            // Average training days
            analytics.averageTrainingDays += response.training_days;

            // Submissions by date
            const date = response.submitted_at.split(' ')[0];
            analytics.submissionsByDate[date] = 
                (analytics.submissionsByDate[date] || 0) + 1;
        });

        analytics.averageTrainingDays = 
            analytics.averageTrainingDays / responses.length || 0;

        res.json({
            success: true,
            analytics,
            responses: responses.slice(0, 100) // Limit to recent 100
        });

    } catch (error) {
        console.error('Error fetching analytics:', error);
        res.status(500).json({
            success: false,
            message: 'Error fetching analytics data'
        });
    }
});

module.exports = router;