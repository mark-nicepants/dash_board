import { test as base, expect } from '@playwright/test';
import { DashboardPage } from '../pages/dashboard.page';
import { LoginPage } from '../pages/login.page';
import { ResourcePage } from '../pages/resource.page';
import { config } from './config';

/**
 * Custom test fixtures for Dash E2E tests.
 * 
 * Provides pre-configured page objects and helpers for common operations.
 */

// Extend the base test with our custom fixtures
export const test = base.extend<{
  loginPage: LoginPage;
  dashboardPage: DashboardPage;
  resourcePage: ResourcePage;
}>({
  loginPage: async ({ page }, use) => {
    await use(new LoginPage(page));
  },
  
  dashboardPage: async ({ page }, use) => {
    await use(new DashboardPage(page));
  },
  
  resourcePage: async ({ page }, use) => {
    await use(new ResourcePage(page));
  },
});

// Re-export expect for convenience
export { expect };

// Export config for easy access in tests
    export { config };

/**
 * Test helpers for common operations
 */
export const helpers = {
  /**
   * Generate a unique identifier for test data
   */
  uniqueId: () => config.testData.uniqueId(),
  
  /**
   * Wait for network to be idle (useful after form submissions)
   */
  waitForNetworkIdle: async (page: any, timeout = 5000) => {
    await page.waitForLoadState('networkidle', { timeout });
  },
  
  /**
   * Get a toast notification text
   */
  getToastMessage: async (page: any) => {
    const toast = page.locator('[data-toast], [role="alert"], .notification, .toast');
    await toast.waitFor({ state: 'visible', timeout: 5000 });
    return toast.textContent();
  },
  
  /**
   * Wait for a success notification
   */
  waitForSuccessNotification: async (page: any) => {
    // Common success notification patterns
    const success = page.locator('.bg-success, .text-success, [data-success], .notification-success, .toast-success');
    try {
      await success.waitFor({ state: 'visible', timeout: 5000 });
      return true;
    } catch {
      return false;
    }
  },
  
  /**
   * Take a screenshot with a descriptive name
   */
  screenshot: async (page: any, name: string) => {
    await page.screenshot({ 
      path: `test-results/screenshots/${name}-${Date.now()}.png`,
      fullPage: true 
    });
  },
};
