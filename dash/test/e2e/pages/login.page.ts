import { type Page, expect } from '@playwright/test';
import { config } from '../fixtures/config';
import { BasePage } from './base.page';

/**
 * Page object for the login page.
 */
export class LoginPage extends BasePage {
  // Locators
  readonly emailInput = () => this.page.locator('input[name="email"], input[type="email"], #email');
  readonly passwordInput = () => this.page.locator('input[name="password"], input[type="password"], #password');
  readonly submitButton = () => this.page.locator('button[type="submit"], input[type="submit"]');
  readonly errorMessage = () => this.page.locator('.error, .alert-error, [data-error], .text-red-500, .text-danger');
  readonly rememberMeCheckbox = () => this.page.locator('input[name="remember"], #remember');
  
  constructor(page: Page) {
    super(page);
  }
  
  /**
   * Navigate to the login page
   */
  async goto() {
    await super.goto(config.paths.login);
  }
  
  /**
   * Fill in the email field
   */
  async fillEmail(email: string) {
    await this.emailInput().fill(email);
  }
  
  /**
   * Fill in the password field
   */
  async fillPassword(password: string) {
    await this.passwordInput().fill(password);
  }
  
  /**
   * Check the remember me checkbox
   */
  async checkRememberMe() {
    await this.rememberMeCheckbox().check();
  }
  
  /**
   * Click the submit button
   */
  async submit() {
    await this.submitButton().click();
  }
  
  /**
   * Perform a full login with credentials
   */
  async login(email: string = config.credentials.email, password: string = config.credentials.password) {
    await this.fillEmail(email);
    await this.fillPassword(password);
    await this.submit();
  }
  
  /**
   * Login and wait for redirect to dashboard
   */
  async loginAndWaitForDashboard(email?: string, password?: string) {
    await this.login(email, password);
    await this.waitForUrl(new RegExp(`${config.paths.dashboard}$`));
    await this.waitForPageLoad();
  }
  
  /**
   * Get error message text
   * Checks both visible error elements and URL error parameters
   */
  async getErrorMessage(): Promise<string | null> {
    // First check for URL-based error (Dash uses ?error=invalid_credentials)
    const url = this.page.url();
    if (url.includes('error=')) {
      const urlParams = new URL(url).searchParams;
      const errorParam = urlParams.get('error');
      if (errorParam) {
        return errorParam;
      }
    }
    
    // Then check for visible error elements
    try {
      await this.errorMessage().waitFor({ state: 'visible', timeout: 3000 });
      return this.errorMessage().textContent();
    } catch {
      return null;
    }
  }
  
  /**
   * Check if login form is displayed
   */
  async isLoginFormVisible(): Promise<boolean> {
    return this.emailInput().isVisible() && this.passwordInput().isVisible();
  }
  
  /**
   * Verify we're on the login page
   */
  async expectToBeOnLoginPage() {
    await expect(this.page).toHaveURL(new RegExp(config.paths.login));
    await expect(this.emailInput()).toBeVisible();
    await expect(this.passwordInput()).toBeVisible();
  }
}
