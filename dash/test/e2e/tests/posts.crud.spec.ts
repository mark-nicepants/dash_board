import { expect, test } from '@playwright/test';
import { config } from '../fixtures/config';
import { ResourcePage } from '../pages/resource.page';

/**
 * CRUD tests for the Posts resource.
 * 
 * Posts have complex forms with relationships (author), 
 * date fields, toggles, and text areas.
 */
test.describe('Posts CRUD Operations', () => {
  const resourcePath = config.paths.posts.index;
  let resourcePage: ResourcePage;
  
  test.beforeEach(async ({ page }) => {
    resourcePage = new ResourcePage(page);
  });
  
  test.describe('Index / List', () => {
    test('should display posts index page with table', async ({ page }) => {
      await resourcePage.gotoIndex(resourcePath);
      
      await resourcePage.expectToBeOnIndex(resourcePath);
      await expect(resourcePage.table()).toBeVisible();
    });
    
    test('should display post columns', async ({ page }) => {
      await resourcePage.gotoIndex(resourcePath);
      
      // Check for expected column headers
      await expect(page.locator('th, [data-table-header]').filter({ hasText: /title/i })).toBeVisible();
    });
  });
  
  test.describe('Create', () => {
    test('should navigate to create page', async ({ page }) => {
      await resourcePage.gotoIndex(resourcePath);
      await resourcePage.clickCreate();
      
      await resourcePage.expectToBeOnCreate(resourcePath);
    });
    
  });
  
  test.describe('Update / Edit', () => {
    test('should update post title', async ({ page }) => {
      // First create a post
      const uniqueId = config.testData.uniqueId();
      const postData = config.testData.post(1, uniqueId);
      const updatedTitle = `Updated Post ${uniqueId}`;
      
      await resourcePage.gotoCreate(resourcePath);
      await resourcePage.fillField('title', postData.title);
      await resourcePage.fillField('slug', postData.slug);
      await resourcePage.selectRelationship('Author', 'Admin User');
      await resourcePage.submitForm();
      
      // Find and edit the post
      await resourcePage.gotoIndex(resourcePath);
      await resourcePage.search(postData.title);
      await resourcePage.clickEditOnRow(0);
      
      // Update title
      await resourcePage.fillField('title', updatedTitle);
      await resourcePage.submitForm();
      
      // Verify update
      await resourcePage.gotoIndex(resourcePath);
      await resourcePage.search(updatedTitle);
      await resourcePage.expectRowWithText(updatedTitle);
    });
  });
  
  test.describe('Delete', () => {
    test('should delete a post', async ({ page }) => {
      // First create a post to delete
      const uniqueId = config.testData.uniqueId();
      const postData = config.testData.post(1, uniqueId);
      
      await resourcePage.gotoCreate(resourcePath);
      await resourcePage.fillField('title', postData.title);
      await resourcePage.fillField('slug', postData.slug);
      await resourcePage.selectRelationship('Author', 'Admin User');
      await resourcePage.submitForm();
      
      // Find and delete the post
      await resourcePage.gotoIndex(resourcePath);
      await resourcePage.search(postData.title);
      await resourcePage.expectRowWithText(postData.title);
      
      await resourcePage.deleteRow(0);
      
      // Verify deletion - post should no longer appear
      await resourcePage.gotoIndex(resourcePath);
      await resourcePage.search(postData.title);
      await resourcePage.expectNoRowWithText(postData.title);
    });
  });
  
  test.describe('Search', () => {
    test('should search posts by title', async ({ page }) => {
      // Create a post first
      const uniqueId = config.testData.uniqueId();
      const postData = config.testData.post(1, `searchtest-${uniqueId}`);
      
      await resourcePage.gotoCreate(resourcePath);
      await resourcePage.fillField('title', postData.title);
      await resourcePage.fillField('slug', postData.slug);
      await resourcePage.selectRelationship('Author', 'Admin User');
      await resourcePage.submitForm();
      
      // Search for it
      await resourcePage.gotoIndex(resourcePath);
      await resourcePage.search('searchtest');
      
      await resourcePage.expectRowWithText(postData.title);
    });
  });
});
