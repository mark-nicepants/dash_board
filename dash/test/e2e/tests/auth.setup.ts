import { expect, test as setup } from '@playwright/test';
import { config } from '../fixtures/config';

const authFile = 'test-results/.auth/user.json';

/**
 * Authentication setup that runs before all tests.
 * Logs in and saves the authentication state for reuse.
 */
setup('authenticate', async ({ page }) => {
  // Navigate to login page
  await page.goto(config.paths.login);
  
  // Fill in credentials
  await page.locator('input[name="email"], input[type="email"], #email').fill(config.credentials.email);
  await page.locator('input[name="password"], input[type="password"], #password').fill(config.credentials.password);
  
  // Submit login form
  await page.locator('button[type="submit"], input[type="submit"]').click();
  
  // Wait for redirect to dashboard
  await page.waitForURL(new RegExp(`${config.paths.dashboard}`), { timeout: 30000 });
  
  // Verify we're logged in
  await expect(page).toHaveURL(new RegExp(config.paths.dashboard));
  
  // Save authentication state
  await page.context().storageState({ path: authFile });
});
