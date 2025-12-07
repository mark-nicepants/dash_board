import { expect, test } from '@playwright/test';
import { config } from '../fixtures/config';
import { DashboardPage } from '../pages/dashboard.page';
import { LoginPage } from '../pages/login.page';

/**
 * Authentication tests - testing login and logout functionality.
 * 
 * Note: These tests don't use the authenticated state fixture
 * because they test the authentication flow itself.
 */
test.describe('Authentication', () => {
  // Don't use authenticated state for auth tests
  test.use({ storageState: { cookies: [], origins: [] } });
  
  test.describe('Login', () => {
    test('should display login form', async ({ page }) => {
      const loginPage = new LoginPage(page);
      
      await loginPage.goto();
      
      await expect(loginPage.emailInput()).toBeVisible();
      await expect(loginPage.passwordInput()).toBeVisible();
      await expect(loginPage.submitButton()).toBeVisible();
    });
    
    test('should login with valid credentials', async ({ page }) => {
      const loginPage = new LoginPage(page);
      const dashboardPage = new DashboardPage(page);
      
      await loginPage.goto();
      await loginPage.login(config.credentials.email, config.credentials.password);
      
      // Should redirect to dashboard
      await dashboardPage.expectToBeOnDashboard();
    });
    
    test('should show error with invalid credentials', async ({ page }) => {
      const loginPage = new LoginPage(page);
      
      await loginPage.goto();
      await loginPage.login('invalid@example.com', 'wrongpassword');
      
      // Should stay on login page (possibly with error param)
      await expect(page).toHaveURL(new RegExp(config.paths.login));
      
      // Should show error message (via URL param or visible element)
      const errorMessage = await loginPage.getErrorMessage();
      expect(errorMessage).toBeTruthy();
    });
    
    test('should show error with empty credentials', async ({ page }) => {
      const loginPage = new LoginPage(page);
      
      await loginPage.goto();
      await loginPage.submit();
      
      // Should stay on login page (HTML5 validation or server-side)
      await loginPage.expectToBeOnLoginPage();
    });
    
    test('should redirect unauthenticated users to login', async ({ page }) => {
      // Try to access dashboard directly
      await page.goto(config.paths.dashboard);
      
      // Should be redirected to login
      await expect(page).toHaveURL(new RegExp(config.paths.login));
    });
    
    test('should redirect unauthenticated users from resource pages', async ({ page }) => {
      // Try to access users page directly
      await page.goto(config.paths.users.index);
      
      // Should be redirected to login
      await expect(page).toHaveURL(new RegExp(config.paths.login));
    });
  });
  
  test.describe('Logout', () => {
    test('should logout successfully', async ({ page }) => {
      const loginPage = new LoginPage(page);
      const dashboardPage = new DashboardPage(page);
      
      // First login
      await loginPage.goto();
      await loginPage.loginAndWaitForDashboard();
      
      // Then logout
      await dashboardPage.logout();
      
      // Should be back on login page
      await loginPage.expectToBeOnLoginPage();
    });
    
    test('should not access protected pages after logout', async ({ page }) => {
      const loginPage = new LoginPage(page);
      const dashboardPage = new DashboardPage(page);
      
      // Login first
      await loginPage.goto();
      await loginPage.loginAndWaitForDashboard();
      
      // Logout
      await dashboardPage.logout();
      
      // Try to access dashboard
      await page.goto(config.paths.dashboard);
      
      // Should be redirected to login
      await loginPage.expectToBeOnLoginPage();
    });
  });
});
