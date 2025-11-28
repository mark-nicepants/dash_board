/**
 * Dash Admin Panel - Main Application Bundle
 * This file imports and initializes all JavaScript modules.
 */

// Import column toggle functionality
import { initColumnToggle } from './column-toggle.js';

// Import file upload functionality
import { initFileUpload } from './file-upload.js';

// Initialize all features
initColumnToggle();
initFileUpload();

// Add more imports and initialization here as needed
// import { initAnotherFeature } from './another-feature.js';
// initAnotherFeature();

// Global initialization
console.log('Dash Admin Panel initialized');
