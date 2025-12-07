import { type Locator, type Page, expect } from '@playwright/test';
import { BasePage } from './base.page';

/**
 * Page object for resource listing and CRUD operations.
 * Works with any Dash resource (users, posts, tags, etc.)
 */
export class ResourcePage extends BasePage {
  // Table locators
  readonly table = () => this.page.locator('table, [data-table]');
  readonly tableRows = () => this.page.locator('table tbody tr, [data-table-row]');
  readonly tableHeaders = () => this.page.locator('table thead th, [data-table-header]');
  readonly emptyState = () => this.page.locator('[data-empty-state], .empty-state, .no-results');
  
  // Action button locators
  readonly createButton = () => this.page.locator('a:has-text("Create"), a:has-text("New"), button:has-text("Create"), button:has-text("New"), [data-create-button]');
  readonly searchInput = () => this.page.locator('input[type="search"], input[placeholder*="Search"], [data-search]');
  
  // Pagination locators
  readonly pagination = () => this.page.locator('[data-pagination], .pagination, nav[aria-label*="pagination"]');
  readonly nextPageButton = () => this.page.locator('[data-next-page], .pagination-next, a:has-text("Next")');
  readonly prevPageButton = () => this.page.locator('[data-prev-page], .pagination-prev, a:has-text("Previous")');
  
  // Form locators
  readonly form = () => this.page.locator('form');
  readonly submitButton = () => this.page.locator('button:has-text("Save"), button:has-text("Create"), button:has-text("Update"), button[type="submit"]').first();
  readonly cancelButton = () => this.page.locator('button:has-text("Cancel"), a:has-text("Cancel")').first();
  
  // Delete confirmation modal - using role=dialog for Alpine.js modals
  readonly deleteModal = () => this.page.locator('[role="dialog"][aria-modal="true"]');
  readonly deleteConfirmButton = () => this.page.locator('[role="dialog"] button:has-text("Delete")');
  readonly deleteCancelButton = () => this.page.locator('[role="dialog"] button:has-text("Cancel")');
  
  constructor(page: Page) {
    super(page);
  }
  
  /**
   * Navigate to a resource index page
   */
  async gotoIndex(resourcePath: string) {
    await super.goto(resourcePath);
    await this.waitForPageLoad();
  }
  
  /**
   * Navigate to create page
   */
  async gotoCreate(resourcePath: string) {
    await super.goto(`${resourcePath}/create`);
    await this.waitForPageLoad();
  }
  
  /**
   * Navigate to edit page for a specific record
   */
  async gotoEdit(resourcePath: string, id: number | string) {
    await super.goto(`${resourcePath}/${id}/edit`);
    await this.waitForPageLoad();
  }
  
  /**
   * Navigate to view page for a specific record
   */
  async gotoView(resourcePath: string, id: number | string) {
    await super.goto(`${resourcePath}/${id}`);
    await this.waitForPageLoad();
  }
  
  // ==================== Table Operations ====================
  
  /**
   * Get the number of rows in the table
   */
  async getRowCount(): Promise<number> {
    return this.tableRows().count();
  }
  
  /**
   * Check if table is empty
   */
  async isTableEmpty(): Promise<boolean> {
    const rowCount = await this.getRowCount();
    return rowCount === 0 || await this.emptyState().isVisible();
  }
  
  /**
   * Get a specific row by index (0-based)
   */
  getRow(index: number): Locator {
    return this.tableRows().nth(index);
  }
  
  /**
   * Get cell value from a row
   */
  async getCellValue(rowIndex: number, columnIndex: number): Promise<string | null> {
    const row = this.getRow(rowIndex);
    const cell = row.locator('td').nth(columnIndex);
    return cell.textContent();
  }
  
  /**
   * Find a row containing specific text
   */
  findRowWithText(text: string): Locator {
    return this.tableRows().filter({ hasText: text }).first();
  }
  
  /**
   * Check if a row with specific text exists
   */
  async rowWithTextExists(text: string): Promise<boolean> {
    return this.findRowWithText(text).isVisible();
  }
  
  /**
   * Search in the table
   */
  async search(query: string) {
    await this.searchInput().fill(query);
    // Wait for search to trigger and table to update
    // Use domcontentloaded instead of networkidle since SSE keeps connection open
    await this.page.waitForTimeout(500);
    await this.page.waitForLoadState('domcontentloaded');
  }
  
  /**
   * Clear search
   */
  async clearSearch() {
    await this.searchInput().clear();
    await this.page.waitForTimeout(500);
    await this.page.waitForLoadState('domcontentloaded');
  }
  
  // ==================== Row Actions ====================
  
  /**
   * Click view action on a row (if available)
   */
  async clickViewOnRow(rowIndex: number) {
    const row = this.getRow(rowIndex);
    const viewButton = row.locator('a:has-text("View"), a[href*="/view"], [data-action="view"], a[title*="View"]').first();
    if (await viewButton.isVisible()) {
      await viewButton.click();
      await this.waitForPageLoad();
    } else {
      // If no view button, click the row or first link
      const firstCell = row.locator('td').first();
      await firstCell.click();
      await this.waitForPageLoad();
    }
  }
  
  /**
   * Click edit action on a row
   */
  async clickEditOnRow(rowIndex: number) {
    // Wait for any toast notifications to disappear first
    const toastContainer = this.page.locator('#dash-toast-container');
    try {
      await toastContainer.locator('div').first().waitFor({ state: 'detached', timeout: 5000 });
    } catch {
      // No toast or already gone, continue
    }
    
    const row = this.getRow(rowIndex);
    const editButton = row.locator('a:has-text("Edit"), a[href*="/edit"], [data-action="edit"]').first();
    await editButton.click();
    await this.waitForPageLoad();
  }
  
  /**
   * Click delete action on a row
   */
  async clickDeleteOnRow(rowIndex: number) {
    // Wait for any toast notifications to disappear first
    const toastContainer = this.page.locator('#dash-toast-container');
    try {
      await toastContainer.locator('div').first().waitFor({ state: 'detached', timeout: 5000 });
    } catch {
      // No toast or already gone, continue
    }
    
    const row = this.getRow(rowIndex);
    const deleteButton = row.locator('button:has-text("Delete"), [data-action="delete"]').first();
    await deleteButton.click();
  }
  
  /**
   * Click an action button on a row by text
   */
  async clickRowAction(rowIndex: number, actionText: string) {
    const row = this.getRow(rowIndex);
    
    // First try to find a dropdown menu button (usually "..." or similar)
    const menuButton = row.locator('[data-actions-menu], button:has-text("⋮"), button:has-text("..."), [aria-label*="action"]').first();
    if (await menuButton.isVisible()) {
      await menuButton.click();
      await this.page.waitForTimeout(200);
    }
    
    // Click the action
    const actionButton = row.locator(`a:has-text("${actionText}"), button:has-text("${actionText}")`).first();
    await actionButton.click();
  }
  
  // ==================== Create/Edit Form Operations ====================
  
  /**
   * Click create button to go to create page
   */
  async clickCreate() {
    await this.createButton().click();
    await this.waitForPageLoad();
  }
  
  /**
   * Fill a text input field by name or label
   */
  async fillField(fieldName: string, value: string) {
    // Try various selector patterns
    const input = this.page.locator(
      `input[name="${fieldName}"], ` +
      `input[id="${fieldName}"], ` +
      `textarea[name="${fieldName}"], ` +
      `textarea[id="${fieldName}"], ` +
      `label:has-text("${fieldName}") + input, ` +
      `label:has-text("${fieldName}") + textarea, ` +
      `[data-field="${fieldName}"] input, ` +
      `[data-field="${fieldName}"] textarea`
    ).first();
    
    await input.fill(value);
  }
  
  /**
   * Select an option from a select field
   */
  async selectOption(fieldName: string, value: string) {
    const select = this.page.locator(
      `select[name="${fieldName}"], ` +
      `select[id="${fieldName}"], ` +
      `[data-field="${fieldName}"] select`
    ).first();
    
    await select.selectOption(value);
  }
  
  /**
   * Toggle a checkbox or toggle field
   */
  async toggleCheckbox(fieldName: string, checked: boolean = true) {
    const checkbox = this.page.locator(
      `input[type="checkbox"][name="${fieldName}"], ` +
      `input[type="checkbox"][id="${fieldName}"], ` +
      `[data-field="${fieldName}"] input[type="checkbox"]`
    ).first();
    
    if (checked) {
      await checkbox.check();
    } else {
      await checkbox.uncheck();
    }
  }
  
  /**
   * Select a relationship from a searchable dropdown.
   * This handles the RelationshipSelect and similar searchable select fields.
   * @param fieldLabel The label of the field (e.g., "Author")
   * @param optionText The text of the option to select (e.g., "Admin User")
   */
  async selectRelationship(fieldLabel: string, optionText: string) {
    // Click on the searchable input to open the dropdown
    const input = this.page.getByRole('textbox', { name: new RegExp(fieldLabel, 'i') });
    await input.click();
    
    // Wait for dropdown to appear
    await this.page.waitForTimeout(300);
    
    // Click the option - options appear as buttons in a list
    const option = this.page.getByRole('button', { name: optionText });
    await option.waitFor({ state: 'visible', timeout: 5000 });
    await option.click();
    
    // Wait for selection to register
    await this.page.waitForTimeout(200);
  }
  
  /**
   * Select multiple tags from a HasManySelect dropdown.
   * @param fieldLabel The label of the field (e.g., "Tags")
   * @param optionTexts The text of the options to select
   */
  async selectMultipleOptions(fieldLabel: string, optionTexts: string[]) {
    for (const optionText of optionTexts) {
      // Click on the searchable input to open the dropdown
      const input = this.page.getByRole('textbox', { name: new RegExp(fieldLabel, 'i') });
      await input.click();
      
      // Wait for dropdown to appear
      await this.page.waitForTimeout(300);
      
      // Click the option
      const option = this.page.getByRole('button', { name: optionText });
      await option.waitFor({ state: 'visible', timeout: 5000 });
      await option.click();
      
      // Wait for selection to register
      await this.page.waitForTimeout(200);
    }
  }

  /**
   * Submit the form
   */
  async submitForm() {
    await this.submitButton().click();
    await this.waitForPageLoad();
  }
  
  /**
   * Cancel and go back
   */
  async cancelForm() {
    await this.cancelButton().click();
    await this.waitForPageLoad();
  }
  
  /**
   * Fill multiple fields at once
   */
  async fillFields(fields: Record<string, string>) {
    for (const [name, value] of Object.entries(fields)) {
      await this.fillField(name, value);
    }
  }
  
  // ==================== Delete Operations ====================
  
  /**
   * Confirm delete in modal
   */
  async confirmDelete() {
    // Wait for modal to be fully visible
    await this.page.waitForTimeout(500);
    
    // Click the Delete button in the modal - use getByRole for better reliability
    const confirmButton = this.page.getByRole('dialog').getByRole('button', { name: 'Delete' });
    await confirmButton.waitFor({ state: 'visible', timeout: 5000 });
    await confirmButton.click();
    await this.waitForPageLoad();
  }
  
  /**
   * Cancel delete in modal
   */
  async cancelDelete() {
    // Wait for modal to be fully visible
    await this.page.waitForTimeout(500);
    
    // Click the Cancel button in the modal
    const cancelButton = this.page.getByRole('dialog').getByRole('button', { name: 'Cancel' });
    await cancelButton.click();
    
    // Wait for modal to close
    await this.page.waitForTimeout(300);
  }
  
  /**
   * Delete a row and confirm
   */
  async deleteRow(rowIndex: number) {
    await this.clickDeleteOnRow(rowIndex);
    await this.confirmDelete();
  }
  
  // ==================== Pagination ====================
  
  /**
   * Go to next page
   */
  async goToNextPage() {
    await this.nextPageButton().click();
    await this.waitForPageLoad();
  }
  
  /**
   * Go to previous page
   */
  async goToPreviousPage() {
    await this.prevPageButton().click();
    await this.waitForPageLoad();
  }
  
  /**
   * Check if pagination is visible
   */
  async hasPagination(): Promise<boolean> {
    return this.pagination().isVisible();
  }
  
  // ==================== Assertions ====================
  
  /**
   * Expect to be on a resource index page
   */
  async expectToBeOnIndex(resourcePath: string) {
    await expect(this.page).toHaveURL(new RegExp(`${resourcePath}$`));
    await expect(this.table()).toBeVisible();
  }
  
  /**
   * Expect to be on create page
   */
  async expectToBeOnCreate(resourcePath: string) {
    await expect(this.page).toHaveURL(new RegExp(`${resourcePath}/create`));
    await expect(this.form()).toBeVisible();
  }
  
  /**
   * Expect to be on edit page
   */
  async expectToBeOnEdit(resourcePath: string, id?: number | string) {
    if (id) {
      await expect(this.page).toHaveURL(new RegExp(`${resourcePath}/${id}/edit`));
    } else {
      await expect(this.page).toHaveURL(new RegExp(`${resourcePath}/\\d+/edit`));
    }
    await expect(this.form()).toBeVisible();
  }
  
  /**
   * Expect to be on view page
   */
  async expectToBeOnView(resourcePath: string, id?: number | string) {
    if (id) {
      await expect(this.page).toHaveURL(new RegExp(`${resourcePath}/${id}$`));
    } else {
      await expect(this.page).toHaveURL(new RegExp(`${resourcePath}/\\d+$`));
    }
  }
  
  /**
   * Expect table to have at least N rows
   */
  async expectMinimumRows(count: number) {
    await expect(this.tableRows()).toHaveCount(count, { timeout: 10000 });
  }
  
  /**
   * Expect row with text to exist
   */
  async expectRowWithText(text: string) {
    await expect(this.findRowWithText(text)).toBeVisible();
  }
  
  /**
   * Expect row with text to not exist
   */
  async expectNoRowWithText(text: string) {
    await expect(this.findRowWithText(text)).not.toBeVisible();
  }
}
