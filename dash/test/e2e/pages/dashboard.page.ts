import { type Page, expect } from '@playwright/test';
import { config } from '../fixtures/config';
import { BasePage } from './base.page';

/**
 * Page object for the dashboard/home page.
 */
export class DashboardPage extends BasePage {
  // Locators
  readonly pageHeader = () => this.page.locator('h1, [data-page-title]').first();
  readonly sidebar = () => this.page.locator('[data-sidebar], nav, aside').first();
  readonly userMenu = () => this.page.locator('[data-user-menu], .user-menu, .dropdown');
  readonly logoutButton = () => this.page.locator('a[href*="logout"], button:has-text("Logout"), button:has-text("Sign out")');
  
  constructor(page: Page) {
    super(page);
  }
  
  /**
   * Navigate to the dashboard
   */
  async goto() {
    await super.goto(config.paths.dashboard);
  }
  
  /**
   * Verify we're on the dashboard
   */
  async expectToBeOnDashboard() {
    await expect(this.page).toHaveURL(new RegExp(`${config.paths.dashboard}$`));
  }
  
  /**
   * Get the page header text
   */
  async getHeaderText(): Promise<string | null> {
    return this.pageHeader().textContent();
  }
  
  /**
   * Check if sidebar is visible
   */
  async isSidebarVisible(): Promise<boolean> {
    return this.sidebar().isVisible();
  }
  
  /**
   * Navigate to a resource via sidebar
   */
  async navigateToResource(resourceName: string) {
    // Click on the resource link in the sidebar
    const link = this.page.locator(`a:has-text("${resourceName}")`).first();
    await link.click();
    await this.waitForPageLoad();
  }
  
  /**
   * Navigate to users resource
   */
  async navigateToUsers() {
    await this.navigateToResource('Users');
    await this.waitForUrl(new RegExp(config.paths.users.index));
  }
  
  /**
   * Navigate to posts resource
   */
  async navigateToPosts() {
    await this.navigateToResource('Posts');
    await this.waitForUrl(new RegExp(config.paths.posts.index));
  }
  
  /**
   * Navigate to tags resource
   */
  async navigateToTags() {
    await this.navigateToResource('Tags');
    await this.waitForUrl(new RegExp(config.paths.tags.index));
  }
  
  /**
   * Open user menu dropdown
   */
  async openUserMenu() {
    await this.userMenu().click();
  }
  
  /**
   * Logout via user menu
   */
  async logout() {
    // Try different logout patterns
    try {
      await this.openUserMenu();
      await this.logoutButton().click();
    } catch {
      // Direct navigation fallback
      await this.goto();
      await this.page.goto(config.paths.logout);
    }
    await this.waitForUrl(new RegExp(config.paths.login));
  }
  
  /**
   * Check if user is logged in (dashboard accessible)
   */
  async isLoggedIn(): Promise<boolean> {
    try {
      await this.page.goto(config.paths.dashboard);
      await this.page.waitForURL(new RegExp(config.paths.dashboard), { timeout: 5000 });
      return true;
    } catch {
      return false;
    }
  }
}
