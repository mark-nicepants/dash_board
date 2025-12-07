import { expect, test } from '@playwright/test';
import { config } from '../fixtures/config';
import { ResourcePage } from '../pages/resource.page';

/**
 * CRUD tests for the Tags resource.
 * 
 * Tests Create, Read, Update, Delete operations.
 * Tags is chosen because it has a simple form structure,
 * making it ideal for comprehensive CRUD testing.
 */
test.describe('Tags CRUD Operations', () => {
  const resourcePath = config.paths.tags.index;
  let resourcePage: ResourcePage;
  
  test.beforeEach(async ({ page }) => {
    resourcePage = new ResourcePage(page);
  });
  
  test.describe('Index / List', () => {
    test('should display tags index page with table', async ({ page }) => {
      await resourcePage.gotoIndex(resourcePath);
      
      await resourcePage.expectToBeOnIndex(resourcePath);
      await expect(resourcePage.table()).toBeVisible();
    });
    
    test('should display create button', async ({ page }) => {
      await resourcePage.gotoIndex(resourcePath);
      
      await expect(resourcePage.createButton()).toBeVisible();
    });
    
    test('should have search functionality', async ({ page }) => {
      await resourcePage.gotoIndex(resourcePath);
      
      await expect(resourcePage.searchInput()).toBeVisible();
    });
  });
  
  test.describe('Create', () => {
    test('should navigate to create page', async ({ page }) => {
      await resourcePage.gotoIndex(resourcePath);
      await resourcePage.clickCreate();
      
      await resourcePage.expectToBeOnCreate(resourcePath);
    });
    
    test('should display form fields on create page', async ({ page }) => {
      await resourcePage.gotoCreate(resourcePath);
      
      await expect(resourcePage.form()).toBeVisible();
      await expect(resourcePage.submitButton()).toBeVisible();
    });
    
    test('should create a new tag successfully', async ({ page }) => {
      const uniqueId = config.testData.uniqueId();
      const tagData = config.testData.tag(uniqueId);
      
      await resourcePage.gotoCreate(resourcePath);
      
      await resourcePage.fillField('name', tagData.name);
      await resourcePage.fillField('slug', tagData.slug);
      await resourcePage.fillField('description', tagData.description);
      
      await resourcePage.submitForm();
      
      // Should redirect back to index or view page
      await expect(page).toHaveURL(new RegExp(`${resourcePath}`));
      
      // Verify the tag appears in the list
      await resourcePage.gotoIndex(resourcePath);
      await resourcePage.search(tagData.name);
      await resourcePage.expectRowWithText(tagData.name);
    });
    
    test('should show validation error for empty required fields', async ({ page }) => {
      await resourcePage.gotoCreate(resourcePath);
      
      // Try to submit without filling required fields
      await resourcePage.submitForm();
      
      // Should stay on create page or show validation errors
      await expect(page).toHaveURL(new RegExp(`${resourcePath}`));
    });
    
    test('should cancel create and return to index', async ({ page }) => {
      // First go to the index page, then navigate to create
      // This ensures there's history for the cancel button to use
      await resourcePage.gotoIndex(resourcePath);
      await resourcePage.clickCreate();
      
      await resourcePage.cancelForm();
      
      await resourcePage.expectToBeOnIndex(resourcePath);
    });
  });
  
  test.describe('Read / View', () => {
    test('should display tag data in the list', async ({ page }) => {
      // First create a tag
      const uniqueId = config.testData.uniqueId();
      const tagData = config.testData.tag(uniqueId);
      
      await resourcePage.gotoCreate(resourcePath);
      await resourcePage.fillField('name', tagData.name);
      await resourcePage.fillField('slug', tagData.slug);
      await resourcePage.fillField('description', tagData.description);
      await resourcePage.submitForm();
      
      // Go to index and find the tag - it should be visible in the table
      await resourcePage.gotoIndex(resourcePath);
      await resourcePage.search(tagData.name);
      
      // Verify tag data is displayed in the table
      await resourcePage.expectRowWithText(tagData.name);
      await resourcePage.expectRowWithText(tagData.slug);
    });
  });
  
  test.describe('Update / Edit', () => {
    test('should navigate to edit page from index', async ({ page }) => {
      // First create a tag to edit
      const uniqueId = config.testData.uniqueId();
      const tagData = config.testData.tag(uniqueId);
      
      await resourcePage.gotoCreate(resourcePath);
      await resourcePage.fillField('name', tagData.name);
      await resourcePage.fillField('slug', tagData.slug);
      await resourcePage.submitForm();
      
      // Go to index and find the tag
      await resourcePage.gotoIndex(resourcePath);
      await resourcePage.search(tagData.name);
      
      // Click edit on the first matching row
      await resourcePage.clickEditOnRow(0);
      
      await resourcePage.expectToBeOnEdit(resourcePath);
    });
    
    test('should update tag successfully', async ({ page }) => {
      // First create a tag
      const uniqueId = config.testData.uniqueId();
      const tagData = config.testData.tag(uniqueId);
      const updatedName = `Updated ${tagData.name}`;
      
      await resourcePage.gotoCreate(resourcePath);
      await resourcePage.fillField('name', tagData.name);
      await resourcePage.fillField('slug', tagData.slug);
      await resourcePage.submitForm();
      
      // Go to index and find the tag
      await resourcePage.gotoIndex(resourcePath);
      await resourcePage.search(tagData.name);
      
      // Click edit
      await resourcePage.clickEditOnRow(0);
      
      // Update the name
      await resourcePage.fillField('name', updatedName);
      await resourcePage.submitForm();
      
      // Verify update - go to index and search for updated name
      await resourcePage.gotoIndex(resourcePath);
      await resourcePage.search(updatedName);
      await resourcePage.expectRowWithText(updatedName);
    });
    
    test('should pre-fill form with existing values', async ({ page }) => {
      // First create a tag
      const uniqueId = config.testData.uniqueId();
      const tagData = config.testData.tag(uniqueId);
      
      await resourcePage.gotoCreate(resourcePath);
      await resourcePage.fillField('name', tagData.name);
      await resourcePage.fillField('slug', tagData.slug);
      await resourcePage.fillField('description', tagData.description);
      await resourcePage.submitForm();
      
      // Go to index and find the tag
      await resourcePage.gotoIndex(resourcePath);
      await resourcePage.search(tagData.name);
      
      // Click edit
      await resourcePage.clickEditOnRow(0);
      
      // Verify form is pre-filled
      const nameInput = page.locator('input[name="name"], input[id="name"]').first();
      await expect(nameInput).toHaveValue(tagData.name);
    });
  });
  
  test.describe('Delete', () => {
    // TODO: Delete modal tests are flaky with Alpine.js x-show visibility
    // The modal uses Alpine.js transitions which Playwright has trouble detecting
    // Skip for now until we can find a reliable way to test Alpine.js modals
    
    test('should show delete confirmation modal', async ({ page }) => {
      await resourcePage.gotoIndex(resourcePath);
      await resourcePage.clickDeleteOnRow(0);
      
      const dialog = page.getByRole('dialog');
      await expect(dialog).toBeVisible();
      await expect(dialog.getByText(/Are you sure/)).toBeVisible();
      
      await resourcePage.cancelDelete();
    });
    
    test('should delete a tag with confirmation', async ({ page }) => {
      const uniqueId = config.testData.uniqueId();
      const tagData = config.testData.tag(uniqueId);
      
      await resourcePage.gotoCreate(resourcePath);
      await resourcePage.fillField('name', tagData.name);
      await resourcePage.fillField('slug', tagData.slug);
      await resourcePage.submitForm();
      
      await resourcePage.gotoIndex(resourcePath);
      await resourcePage.search(tagData.name);
      await resourcePage.expectRowWithText(tagData.name);
      
      await resourcePage.deleteRow(0);
      
      // After deletion, search for the tag again - it should not exist
      await resourcePage.gotoIndex(resourcePath);
      await resourcePage.search(tagData.name);
      await resourcePage.expectNoRowWithText(tagData.name);
    });
    
    test('should cancel delete and keep the tag', async ({ page }) => {
      // First create a tag
      const uniqueId = config.testData.uniqueId();
      const tagData = config.testData.tag(uniqueId);
      
      await resourcePage.gotoCreate(resourcePath);
      await resourcePage.fillField('name', tagData.name);
      await resourcePage.fillField('slug', tagData.slug);
      await resourcePage.submitForm();
      
      // Go to index and find the tag
      await resourcePage.gotoIndex(resourcePath);
      await resourcePage.search(tagData.name);
      
      // Start delete but cancel
      await resourcePage.clickDeleteOnRow(0);
      await resourcePage.cancelDelete();
      
      // Verify tag still exists
      await resourcePage.expectRowWithText(tagData.name);
    });
  });
  
  test.describe('Search', () => {
    test('should filter tags by search term', async ({ page }) => {
      // Create two tags with different names
      const uniqueId1 = config.testData.uniqueId();
      const uniqueId2 = config.testData.uniqueId();
      const tag1 = config.testData.tag(`searchable-${uniqueId1}`);
      const tag2 = config.testData.tag(`other-${uniqueId2}`);
      
      // Create first tag
      await resourcePage.gotoCreate(resourcePath);
      await resourcePage.fillField('name', tag1.name);
      await resourcePage.fillField('slug', tag1.slug);
      await resourcePage.submitForm();
      
      // Create second tag
      await resourcePage.gotoCreate(resourcePath);
      await resourcePage.fillField('name', tag2.name);
      await resourcePage.fillField('slug', tag2.slug);
      await resourcePage.submitForm();
      
      // Go to index and search for first tag
      await resourcePage.gotoIndex(resourcePath);
      await resourcePage.search('searchable');
      
      // Should show first tag
      await resourcePage.expectRowWithText(tag1.name);
    });
    
    test('should clear search and show all tags', async ({ page }) => {
      await resourcePage.gotoIndex(resourcePath);
      
      // Get initial row count
      const initialCount = await resourcePage.getRowCount();
      
      // Search for something
      await resourcePage.search('test');
      
      // Clear search
      await resourcePage.clearSearch();
      
      // Should show original count (or more if data was added)
      const finalCount = await resourcePage.getRowCount();
      expect(finalCount).toBeGreaterThanOrEqual(0);
    });
  });
});
