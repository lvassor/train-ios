/**
 * trAIn Beta Landing Page JavaScript
 * Handles landing page redirect and UAT feedback functionality
 */

// ============================================================================
// INITIALIZATION
// ============================================================================
document.addEventListener('DOMContentLoaded', init);

function init() {
    attachEventListeners();
    setupPage();
}

function setupPage() {
    // Check if we're on the feedback page
    if (window.location.pathname.includes('feedback')) {
        setupFeedbackPage();
    }
}

function attachEventListeners() {
    // Landing page start button
    const startBtn = document.getElementById('startBtn');
    if (startBtn) {
        startBtn.addEventListener('click', handleStartClick);
    }

    // Logger summary feedback button
    const feedbackBtn = document.getElementById('give-feedback');
    if (feedbackBtn) {
        feedbackBtn.addEventListener('click', handleFeedbackClick);
    }

    // UAT Feedback form elements
    setupFeedbackFormListeners();
}

function handleStartClick() {
    // Direct redirect to questionnaire
    window.location.href = '/questionnaire';
}

function handleFeedbackClick() {
    // Redirect to feedback form
    window.location.href = '/feedback';
}

// ============================================================================
// UAT FEEDBACK FUNCTIONALITY
// ============================================================================
function setupFeedbackPage() {
    // Character counters
    setupCharacterCounters();
    // Star rating
    setupStarRating();
}

function setupFeedbackFormListeners() {
    // Feedback form submission
    const feedbackForm = document.getElementById('feedbackForm');
    if (feedbackForm) {
        feedbackForm.addEventListener('submit', handleFeedbackSubmit);
    }
}

function setupCharacterCounters() {
    const fields = [
        { id: 'lovedMost', countId: 'lovedMostCount' },
        { id: 'improvements', countId: 'improvementsCount' },
        { id: 'currentApp', countId: 'currentAppCount' },
        { id: 'missingFeatures', countId: 'missingFeaturesCount' }
    ];

    fields.forEach(({ id, countId }) => {
        const field = document.getElementById(id);
        const counter = document.getElementById(countId);
        if (field && counter) {
            field.addEventListener('input', () => {
                counter.textContent = field.value.length;
            });
        }
    });
}


function setupStarRating() {
    const stars = document.querySelectorAll('.rating-star');
    const ratingInput = document.getElementById('overallRating');
    const ratingText = document.getElementById('ratingText');

    const ratingTexts = {
        1: "Needs work",
        2: "Could be better",
        3: "Good experience",
        4: "Really good!",
        5: "Amazing! 🎉"
    };

    stars.forEach((star, index) => {
        star.addEventListener('click', () => {
            const rating = parseInt(star.dataset.rating);

            // Update visual state with immediate color change
            stars.forEach((s, i) => {
                // Set color immediately before changing content
                const isDark = document.documentElement.getAttribute('data-theme') === 'dark';
                const color = isDark ? '#ffffff' : '#2563eb';
                s.style.color = color + ' !important';

                s.style.transition = 'transform 0.1s ease';
                if (i < rating) {
                    s.classList.add('filled');
                    s.textContent = '★'; // Filled star
                    s.style.transform = 'scale(1.1)';
                    setTimeout(() => s.style.transform = 'scale(1)', 100);
                } else {
                    s.classList.remove('filled');
                    s.textContent = '☆'; // Outline star
                    s.style.transform = 'scale(1)';
                }
            });

            // Update form data
            ratingInput.value = rating;
            ratingText.textContent = ratingTexts[rating];
        });

        // Hover effects
        star.addEventListener('mouseenter', () => {
            const rating = parseInt(star.dataset.rating);
            const isDark = document.documentElement.getAttribute('data-theme') === 'dark';
            const hoverColor = isDark ? '#ffffff' : '#2563eb';
            const defaultColor = isDark ? '#6b7280' : '#d1d5db';

            stars.forEach((s, i) => {
                s.style.transition = 'color 0.15s ease';
                if (i < rating) {
                    s.style.color = hoverColor;
                } else {
                    s.style.color = defaultColor;
                }
            });
        });
    });

    // Reset to current rating on mouse leave
    const ratingContainer = document.querySelector('.rating-container');
    if (ratingContainer) {
        ratingContainer.addEventListener('mouseleave', () => {
            const currentRating = parseInt(ratingInput.value) || 0;
            const isDark = document.documentElement.getAttribute('data-theme') === 'dark';
            const activeColor = isDark ? '#ffffff' : '#2563eb';
            const defaultColor = isDark ? '#6b7280' : '#d1d5db';

            stars.forEach((s, i) => {
                s.style.transition = 'color 0.2s ease';
                if (i < currentRating) {
                    s.style.color = activeColor;
                } else {
                    s.style.color = defaultColor;
                }
            });
        });
    }
}

async function handleFeedbackSubmit(event) {
    event.preventDefault();

    const userEmail = sessionStorage.getItem('userEmail') || 'anonymous@feedback.com';
    const betaUser = JSON.parse(sessionStorage.getItem('betaUser') || '{}');
    const userProgram = JSON.parse(sessionStorage.getItem('userProgram') || '{}');

    const formData = {
        firstName: betaUser.firstName || null,
        lastName: betaUser.lastName || null,
        email: userEmail,
        programId: userProgram.id || null,
        overallRating: parseInt(document.getElementById('overallRating').value) || 0,
        lovedMost: document.getElementById('lovedMost').value.trim() || '',
        improvements: document.getElementById('improvements').value.trim() || '',
        currentApp: document.getElementById('currentApp').value.trim() || '',
        missingFeatures: document.getElementById('missingFeatures').value.trim() || '',
        timestamp: new Date().toISOString()
    };

    // Basic validation
    if (!formData.overallRating) {
        showFeedbackError('Please rate your overall experience');
        return;
    }


    // Show loading state
    setFeedbackLoadingState(true);

    try {
        // Submit to backend
        const response = await fetch('/api/uat-feedback', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify(formData)
        });

        const result = await response.json();

        if (response.ok) {
            // Show thank you section
            showThankYouSection();
        } else {
            throw new Error(result.message || 'Feedback submission failed');
        }

    } catch (error) {
        console.error('Feedback submission error:', error);

        // For beta version, assume "Unable to submit feedback" = duplicate email issue
        if (error.message && error.message.includes('Unable to submit feedback. Please try again.')) {
            handleDuplicateEmail();
        } else {
            // For MVP/development: Still show success if backend fails
            if (window.location.hostname === 'localhost' || window.location.hostname.includes('127.0.0.1')) {
                console.log('Dev mode: Simulating successful feedback submission');
                showThankYouSection();
            } else {
                showFeedbackError('Something went wrong. Please try again.');
            }
        }
    } finally {
        setFeedbackLoadingState(false);
    }
}

function handleDuplicateEmail() {
    const currentEmail = sessionStorage.getItem('userEmail') || 'your email';

    const newEmail = prompt(
        `It looks like ${currentEmail} has already been used to submit feedback.\n\n` +
        `Each person can only submit feedback once. If you'd like to submit feedback ` +
        `with a different email address, please enter it below:`,
        ''
    );

    if (newEmail && newEmail.trim() && isValidEmailFormat(newEmail.trim())) {
        // Update session storage with new email
        sessionStorage.setItem('userEmail', newEmail.trim());

        // Update betaUser object if it exists
        const betaUser = JSON.parse(sessionStorage.getItem('betaUser') || '{}');
        if (betaUser.email) {
            betaUser.email = newEmail.trim();
            sessionStorage.setItem('betaUser', JSON.stringify(betaUser));
        }

        // Show success message
        showFeedbackError(`Email updated to ${newEmail.trim()}. Please click "Submit Feedback" again.`);

        // Clear the error after a few seconds
        setTimeout(() => {
            const errorElement = document.getElementById('feedbackError');
            if (errorElement) {
                errorElement.style.display = 'none';
            }
        }, 5000);

    } else if (newEmail !== null) { // User didn't cancel but entered invalid email
        showFeedbackError('Please enter a valid email address.');
    } else {
        // User cancelled
        showFeedbackError('Feedback submission cancelled. This email has already been used.');
    }
}

function isValidEmailFormat(email) {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
}

function showFeedbackError(message) {
    const errorElement = document.getElementById('feedbackError');
    if (errorElement) {
        errorElement.textContent = message;
        errorElement.style.display = 'block';
    }
}

function clearFeedbackError() {
    const errorElement = document.getElementById('feedbackError');
    if (errorElement) {
        errorElement.textContent = '';
        errorElement.style.display = 'none';
    }
}

function setFeedbackLoadingState(loading) {
    const submitBtn = document.getElementById('submitFeedback');
    if (!submitBtn) return;

    if (loading) {
        submitBtn.disabled = true;
        submitBtn.innerHTML = '<div class="loading-spinner" style="display: inline-block; width: 16px; height: 16px; border: 2px solid #ffffff; border-radius: 50%; border-top-color: transparent; animation: spin 1s ease-in-out infinite; margin-right: 0.5rem;"></div>Submitting...';
    } else {
        submitBtn.disabled = false;
        submitBtn.innerHTML = 'Submit Feedback';
    }
}

function showThankYouSection() {
    // Hide the main feedback form
    const mainSection = document.querySelector('section');
    if (mainSection) {
        mainSection.style.display = 'none';
    }

    // Show thank you section
    const thankYouSection = document.getElementById('thankYouSection');
    if (thankYouSection) {
        thankYouSection.classList.remove('hidden');

        // Scroll to top smoothly
        window.scrollTo({
            top: 0,
            behavior: 'smooth'
        });
    }
}