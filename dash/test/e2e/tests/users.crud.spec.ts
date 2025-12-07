import { expect, test } from '@playwright/test';
import { config } from '../fixtures/config';
import { ResourcePage } from '../pages/resource.page';

/**
 * CRUD tests for the Users resource.
 * 
 * Users have a more complex form with relationships, toggles, etc.
 */
test.describe('Users CRUD Operations', () => {
  const resourcePath = config.paths.users.index;
  let resourcePage: ResourcePage;
  
  test.beforeEach(async ({ page }) => {
    resourcePage = new ResourcePage(page);
  });
  
  test.describe('Index / List', () => {
    test('should display users index page with table', async ({ page }) => {
      await resourcePage.gotoIndex(resourcePath);
      
      await resourcePage.expectToBeOnIndex(resourcePath);
      await expect(resourcePage.table()).toBeVisible();
    });
    
    test('should display user columns', async ({ page }) => {
      await resourcePage.gotoIndex(resourcePath);
      
      // Check for expected column headers
      await expect(page.locator('th, [data-table-header]').filter({ hasText: /name/i })).toBeVisible();
      await expect(page.locator('th, [data-table-header]').filter({ hasText: /email/i })).toBeVisible();
    });
    
    test('should display admin user in the list', async ({ page }) => {
      await resourcePage.gotoIndex(resourcePath);
      
      // The seeded admin user should be visible
      await resourcePage.expectRowWithText(config.credentials.email);
    });
  });
  
  test.describe('Create', () => {
    test('should create a new user', async ({ page }) => {
      const uniqueId = config.testData.uniqueId();
      const userData = config.testData.user(uniqueId);
      
      await resourcePage.gotoCreate(resourcePath);
      
      // Fill required fields
      await resourcePage.fillField('name', userData.name);
      await resourcePage.fillField('email', userData.email);
      await resourcePage.fillField('password', userData.password);
      
      await resourcePage.submitForm();
      
      // Verify user was created
      await resourcePage.gotoIndex(resourcePath);
      await resourcePage.search(userData.email);
      await resourcePage.expectRowWithText(userData.name);
    });
  });
  
  test.describe('Read / View', () => {
    test('should view user details', async ({ page }) => {
      await resourcePage.gotoIndex(resourcePath);
      
      // View the first user
      await resourcePage.clickViewOnRow(0);
      
      await resourcePage.expectToBeOnView(resourcePath);
    });
  });
  
  test.describe('Update / Edit', () => {
    test('should edit user and update name', async ({ page }) => {
      // Create a user first
      const uniqueId = config.testData.uniqueId();
      const userData = config.testData.user(uniqueId);
      const updatedName = `Updated User ${uniqueId}`;
      
      await resourcePage.gotoCreate(resourcePath);
      await resourcePage.fillField('name', userData.name);
      await resourcePage.fillField('email', userData.email);
      await resourcePage.fillField('password', userData.password);
      await resourcePage.submitForm();
      
      // Find and edit the user
      await resourcePage.gotoIndex(resourcePath);
      await resourcePage.search(userData.email);
      await resourcePage.clickEditOnRow(0);
      
      // Update name
      await resourcePage.fillField('name', updatedName);
      await resourcePage.submitForm();
      
      // Verify update
      await resourcePage.gotoIndex(resourcePath);
      await resourcePage.search(updatedName);
      await resourcePage.expectRowWithText(updatedName);
    });
  });
  
  test.describe('Search', () => {
    test('should search users by name', async ({ page }) => {
      await resourcePage.gotoIndex(resourcePath);
      
      // Search for admin
      await resourcePage.search('admin');
      
      // Should find the admin user
      const rowCount = await resourcePage.getRowCount();
      expect(rowCount).toBeGreaterThan(0);
    });
    
    test('should search users by email', async ({ page }) => {
      await resourcePage.gotoIndex(resourcePath);
      
      // Search for admin email
      await resourcePage.search('admin@example');
      
      // Should find the admin user
      await resourcePage.expectRowWithText(config.credentials.email);
    });
  });
});
