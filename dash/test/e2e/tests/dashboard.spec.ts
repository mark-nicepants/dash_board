import { expect, test } from '@playwright/test';
import { config } from '../fixtures/config';
import { DashboardPage } from '../pages/dashboard.page';

/**
 * Dashboard tests - testing the main dashboard page and navigation.
 */
test.describe('Dashboard', () => {
  let dashboardPage: DashboardPage;
  
  test.beforeEach(async ({ page }) => {
    dashboardPage = new DashboardPage(page);
  });
  
  test('should display dashboard after login', async ({ page }) => {
    await dashboardPage.goto();
    
    await dashboardPage.expectToBeOnDashboard();
  });
  
  test('should display sidebar navigation', async ({ page }) => {
    await dashboardPage.goto();
    
    const sidebarVisible = await dashboardPage.isSidebarVisible();
    expect(sidebarVisible).toBe(true);
  });
  
  test('should navigate to Users resource', async ({ page }) => {
    await dashboardPage.goto();
    await dashboardPage.navigateToUsers();
    
    await expect(page).toHaveURL(new RegExp(config.paths.users.index));
  });
  
  test('should navigate to Posts resource', async ({ page }) => {
    await dashboardPage.goto();
    await dashboardPage.navigateToPosts();
    
    await expect(page).toHaveURL(new RegExp(config.paths.posts.index));
  });
  
  test('should navigate to Tags resource', async ({ page }) => {
    await dashboardPage.goto();
    await dashboardPage.navigateToTags();
    
    await expect(page).toHaveURL(new RegExp(config.paths.tags.index));
  });
});
