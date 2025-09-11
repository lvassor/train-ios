const { body, validationResult } = require('express-validator');

// Validation rules for questionnaire submission
const questionnaireValidation = [
    body('email')
        .isEmail()
        .normalizeEmail()
        .withMessage('Please provide a valid email address'),
    
    body('firstName')
        .trim()
        .isLength({ min: 1, max: 100 })
        .withMessage('First name is required and must be less than 100 characters'),
    
    body('lastName')
        .trim()
        .isLength({ min: 1, max: 100 })
        .withMessage('Last name is required and must be less than 100 characters'),
    
    body('experience')
        .isIn(['0_months', '0_6_months', '6_months_2_years', '2_plus_years'])
        .withMessage('Please select a valid experience level'),
    
    body('whyUsingApp')
        .isArray({ min: 1 })
        .withMessage('Please select at least one reason for using the app'),
    
    body('whyUsingApp.*')
        .isIn(['lack_structure', 'lack_confidence', 'lack_knowledge', 'want_guidance'])
        .withMessage('Invalid reason selected'),
    
    body('equipmentAvailable')
        .isArray({ min: 1 })
        .withMessage('Please select at least one piece of equipment'),
    
    body('equipmentAvailable.*')
        .isIn(['dumbbells', 'barbells', 'pin_loaded_machines', 'cable_machines'])
        .withMessage('Invalid equipment selected'),
    
    body('equipmentConfidence')
        .isObject()
        .withMessage('Equipment confidence must be provided'),
    
    body('trainingDays')
        .isInt({ min: 2, max: 5 })
        .withMessage('Training days must be between 2 and 5'),
    
    body('additionalInfo')
        .optional()
        .isLength({ max: 1000 })
        .withMessage('Additional info must be less than 1000 characters')
];

// Middleware to handle validation errors
const handleValidationErrors = (req, res, next) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
        return res.status(400).json({
            success: false,
            message: 'Validation errors',
            errors: errors.array()
        });
    }
    next();
};

module.exports = {
    questionnaireValidation,
    handleValidationErrors
};