import { type Page } from '@playwright/test';

/**
 * Base page object with common functionality for all pages.
 */
export class BasePage {
  readonly page: Page;
  
  constructor(page: Page) {
    this.page = page;
  }
  
  /**
   * Navigate to a URL path
   */
  async goto(path: string) {
    await this.page.goto(path);
    await this.waitForPageLoad();
  }
  
  /**
   * Wait for page to be fully loaded
   */
  async waitForPageLoad() {
    await this.page.waitForLoadState('domcontentloaded');
  }
  
  /**
   * Wait for network to be idle
   */
  async waitForNetworkIdle() {
    await this.page.waitForLoadState('networkidle');
  }
  
  /**
   * Get current URL
   */
  getCurrentUrl(): string {
    return this.page.url();
  }
  
  /**
   * Get page title
   */
  async getPageTitle(): Promise<string> {
    return this.page.title();
  }
  
  /**
   * Check if element is visible
   */
  async isVisible(selector: string): Promise<boolean> {
    return this.page.locator(selector).isVisible();
  }
  
  /**
   * Click an element
   */
  async click(selector: string) {
    await this.page.locator(selector).click();
  }
  
  /**
   * Fill a text input
   */
  async fill(selector: string, value: string) {
    await this.page.locator(selector).fill(value);
  }
  
  /**
   * Get text content of an element
   */
  async getText(selector: string): Promise<string | null> {
    return this.page.locator(selector).textContent();
  }
  
  /**
   * Wait for a specific URL pattern
   */
  async waitForUrl(pattern: string | RegExp) {
    await this.page.waitForURL(pattern);
  }
  
  /**
   * Take a screenshot
   */
  async screenshot(name: string) {
    await this.page.screenshot({ 
      path: `test-results/screenshots/${name}.png`,
      fullPage: true 
    });
  }
  
  /**
   * Get notification/toast message if present
   */
  async getNotification(): Promise<string | null> {
    const notification = this.page.locator('[data-notification], .notification, .toast, [role="alert"]').first();
    try {
      await notification.waitFor({ state: 'visible', timeout: 3000 });
      return notification.textContent();
    } catch {
      return null;
    }
  }
  
  /**
   * Close any visible notification
   */
  async closeNotification() {
    const closeButton = this.page.locator('[data-notification] button, .notification button, .toast button').first();
    if (await closeButton.isVisible()) {
      await closeButton.click();
    }
  }
}
