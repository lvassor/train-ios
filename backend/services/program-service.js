/**
 * Program Service - Handles program generation and database operations
 * 
 * Extracted from server.js to separate business logic from route handling
 */

const path = require('path');
const fs = require('fs');

// Load program templates from JSON file
let PROGRAM_TEMPLATES = null;

/**
 * Load program templates from data file
 * Lazy loads the templates to avoid blocking server startup
 */
function loadProgramTemplates() {
    if (!PROGRAM_TEMPLATES) {
        try {
            const templatesPath = path.join(__dirname, '../../data/programs.json');
            const templatesData = fs.readFileSync(templatesPath, 'utf8');
            PROGRAM_TEMPLATES = JSON.parse(templatesData);
            console.log('Program templates loaded successfully');
        } catch (error) {
            console.error('Error loading program templates:', error);
            // Fallback to empty templates if file doesn't exist yet
            PROGRAM_TEMPLATES = { programs: [] };
        }
    }
    return PROGRAM_TEMPLATES;
}

/**
 * Generate a personalized program based on user's questionnaire responses
 * Uses the program templates and user preferences to create a custom plan
 * 
 * @param {Object} formData - User's questionnaire responses
 * @returns {Object} - Generated program object
 */
function generateProgram(formData) {
    console.log('Generating program for user data:', formData);
    
    // Load templates if not already loaded
    const templates = loadProgramTemplates();
    
    // Map experience levels to program categories
    const experienceMapping = {
        '0_months': 'beginner',
        '0_6_months': 'beginner', 
        '6_months_2_years': 'beginner',
        '2_plus_years': 'advanced'
    };

    const level = experienceMapping[formData.experience] || 'beginner';
    const days = formData.trainingDays;

    console.log(`Looking for ${level} program with ${days} days`);

    // Find the best matching program template
    const templateKey = `${level}_${days}_day`;
    
    let selectedTemplate = templates.programs.find(p => p.id === templateKey);
    
    // Fallback logic if exact match not found
    if (!selectedTemplate) {
        console.warn(`Exact template not found for ${templateKey}, searching for alternatives...`);
        
        // Try to find template that matches experience and frequency
        selectedTemplate = templates.programs.find(p => 
            p.target_experience.includes(formData.experience) && 
            p.frequency.includes(days)
        );
        
        // Final fallback - find template with matching experience
        if (!selectedTemplate) {
            selectedTemplate = templates.programs.find(p => 
                p.target_experience.includes(formData.experience)
            );
        }
        
        // Ultimate fallback - use first template
        if (!selectedTemplate) {
            console.warn('No matching template found, using default template');
            selectedTemplate = templates.programs[0];
        }
    }

    if (!selectedTemplate) {
        throw new Error('No program templates available');
    }

    console.log('Selected template:', selectedTemplate.name);

    // Create personalized program object
    const program = {
        id: `custom_${Date.now()}`,
        name: selectedTemplate.name,
        description: selectedTemplate.description,
        duration_weeks: selectedTemplate.duration_weeks,
        frequency: days,
        user: {
            email: formData.email,
            experience: formData.experience,
            trainingDays: formData.trainingDays,
            whyUsingApp: formData.whyUsingApp,
            equipmentAvailable: formData.equipmentAvailable,
            equipmentConfidence: formData.equipmentConfidence
        },
        // Take only the number of workouts that match requested frequency
        workouts: selectedTemplate.workouts.slice(0, days),
        created_at: new Date().toISOString(),
        template_used: selectedTemplate.id
    };

    return program;
}

/**
 * Save program to database
 * Currently returns a mock ID - implement database save as needed
 * @param {Object} program - Generated program object
 * @param {string} userEmail - User's email address
 * @returns {Promise<string>} - Program ID
 */
async function saveProgramToDatabase(program, userEmail) {
    try {
        console.log('Saving program to database:', {
            userEmail,
            programName: program.name,
            templateId: program.template_used,
            createdAt: program.created_at
        });
        
        // TODO: Implement actual database save
        // For now, return a mock program ID
        return `prog_${Date.now()}`;
        
        // In a real implementation, you might do:
        // const { dbHelpers } = require('../database/db');
        // const programId = await dbHelpers.insertProgram({
        //     userEmail,
        //     templateId: program.template_used,
        //     programData: JSON.stringify(program),
        //     createdAt: program.created_at
        // });
        // return programId;
        
    } catch (error) {
        console.error('Error saving program to database:', error);
        throw error;
    }
}

/**
 * Get program templates (for API endpoints that need to list available programs)
 * @returns {Object} - Program templates object
 */
function getProgramTemplates() {
    return loadProgramTemplates();
}

/**
 * Get a specific program template by ID
 * @param {string} templateId - Template ID to find
 * @returns {Object|null} - Template object or null if not found
 */
function getProgramTemplate(templateId) {
    const templates = loadProgramTemplates();
    return templates.programs.find(p => p.id === templateId) || null;
}

/**
 * Get programs that match specific criteria
 * @param {Object} criteria - Search criteria
 * @param {string} criteria.experience - Experience level
 * @param {number} criteria.frequency - Training days per week
 * @param {Array} criteria.equipment - Available equipment
 * @returns {Array} - Array of matching program templates
 */
function findMatchingPrograms(criteria) {
    const templates = loadProgramTemplates();
    
    return templates.programs.filter(program => {
        // Check experience level
        if (criteria.experience && !program.target_experience.includes(criteria.experience)) {
            return false;
        }
        
        // Check frequency
        if (criteria.frequency && !program.frequency.includes(criteria.frequency)) {
            return false;
        }
        
        // Additional filtering can be added here based on equipment, etc.
        
        return true;
    });
}

module.exports = {
    generateProgram,
    saveProgramToDatabase,
    getProgramTemplates,
    getProgramTemplate,
    findMatchingPrograms,
    loadProgramTemplates
};