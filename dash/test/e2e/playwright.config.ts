import { defineConfig, devices } from '@playwright/test';

/**
 * Playwright configuration for Dash E2E tests.
 * 
 * Run tests:
 *   npm test                 # Run all tests
 *   npm run test:ui          # Open interactive UI mode
 *   npm run test:debug       # Debug mode with browser visible
 *   npm run test:headed      # Run with browser visible
 * 
 * CI: Tests can be run in CI pipeline with `npm test` - headless by default.
 */
export default defineConfig({
  testDir: './tests',
  
  // Run tests in parallel
  fullyParallel: true,
  
  // Fail the build on CI if you accidentally left test.only in the source code
  forbidOnly: !!process.env.CI,
  
  // Retry failed tests on CI
  retries: process.env.CI ? 2 : 0,
  
  // Limit workers on CI for stability
  workers: process.env.CI ? 1 : undefined,
  
  // Reporter configuration
  reporter: process.env.CI 
    ? [['github'], ['html', { outputFolder: 'test-results/html' }]]
    : [['html', { outputFolder: 'test-results/html', open: 'never' }]],
  
  // Shared settings for all projects
  use: {
    // Base URL for the Dash example app
    baseURL: process.env.BASE_URL || 'http://localhost:8080',
    
    // Collect trace on first retry
    trace: 'on-first-retry',
    
    // Take screenshot on failure
    screenshot: 'only-on-failure',
    
    // Record video on retry
    video: 'on-first-retry',
    
    // Default timeout for actions
    actionTimeout: 10000,
    
    // Default navigation timeout
    navigationTimeout: 30000,
  },

  // Test timeout
  timeout: 60000,
  
  // Expect timeout
  expect: {
    timeout: 10000,
  },

  // Configure projects for different browsers
  projects: [
    // Setup project - runs before all tests to prepare authenticated state
    {
      name: 'setup',
      testMatch: /.*\.setup\.ts/,
    },
    
    // Desktop Chrome - primary test browser
    {
      name: 'chromium',
      use: { 
        ...devices['Desktop Chrome'],
        // Use authenticated state from setup
        storageState: 'test-results/.auth/user.json',
      },
      dependencies: ['setup'],
    },
  ],

  // Local development server configuration
  // Uncomment if you want Playwright to start the server automatically
  webServer: {
    command: 'cd ../../example && dart run lib/main.dart',
    url: 'http://localhost:8080',
    reuseExistingServer: !process.env.CI,
    timeout: 120000,
    env: {
      DASH_TEST_MODE: 'true',
    },
  },
  
  // Output folders
  outputDir: 'test-results/artifacts',
});
