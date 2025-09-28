/**
 * Shared Dark Mode Functionality
 * Handles theme switching and persistence across all pages
 */

// ============================================================================
// DARK MODE FUNCTIONALITY
// ============================================================================

function initDarkMode() {
    // Load saved theme preference or default to light
    const savedTheme = localStorage.getItem('darkMode');
    const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;

    // Apply initial theme
    const isDark = savedTheme === 'true' || (savedTheme === null && prefersDark);
    applyTheme(isDark);

    // Setup toggle button if it exists
    const toggleBtn = document.getElementById('darkModeToggle');
    if (toggleBtn) {
        toggleBtn.addEventListener('click', toggleDarkMode);
    }

    // Listen for system theme changes
    window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', (e) => {
        if (localStorage.getItem('darkMode') === null) {
            applyTheme(e.matches);
        }
    });
}

function toggleDarkMode() {
    const currentTheme = document.documentElement.getAttribute('data-theme');
    const newTheme = currentTheme === 'dark' ? 'light' : 'dark';
    const isDark = newTheme === 'dark';

    // Apply theme
    applyTheme(isDark);

    // Save preference
    localStorage.setItem('darkMode', isDark.toString());
}

function applyTheme(isDark) {
    const root = document.documentElement;
    const toggleBtn = document.getElementById('darkModeToggle');

    if (isDark) {
        root.setAttribute('data-theme', 'dark');
        if (toggleBtn) {
            const icon = toggleBtn.querySelector('.toggle-icon');
            const text = toggleBtn.querySelector('.toggle-text');
            if (icon) icon.textContent = '☀️';
            if (text) text.textContent = 'Light';
        }
    } else {
        root.setAttribute('data-theme', 'light');
        if (toggleBtn) {
            const icon = toggleBtn.querySelector('.toggle-icon');
            const text = toggleBtn.querySelector('.toggle-text');
            if (icon) icon.textContent = '🌙';
            if (text) text.textContent = 'Dark';
        }
    }
}


// Auto-initialize dark mode when DOM is ready
document.addEventListener('DOMContentLoaded', initDarkMode);