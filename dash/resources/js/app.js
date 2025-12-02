/**
 * Dash Admin Panel - Main Application Bundle
 * This file imports and initializes all JavaScript modules.
 */
import collapse from '@alpinejs/collapse';
import Alpine from 'alpinejs';

// Import DashWire interactive component system (must be first - provides utilities)
import { initDashWire } from './dash-wire.js';

// Import column toggle functionality (uses DashWire storage)
import { initColumnToggle } from './column-toggle.js';

// Import file upload functionality
import { initFileUpload } from './file-upload.js';

// Make Alpine available globally
window.Alpine = Alpine;

// Initialize all features BEFORE Alpine.start()
// These register alpine:init listeners that must be in place before Alpine starts
initDashWire();
initColumnToggle();
initFileUpload();

// Register Alpine plugins
Alpine.plugin(collapse);

// Start Alpine AFTER all components are registered
Alpine.start();

// Add more imports and initialization here as needed
// import { initAnotherFeature } from './another-feature.js';
// initAnotherFeature();

// Global initialization
console.log('Dash Admin Panel initialized');
