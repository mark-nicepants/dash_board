# Dash E2E Tests

End-to-end tests for the Dash admin panel using [Playwright](https://playwright.dev/).

## Overview

These tests verify the functionality of the Dash admin panel by interacting with a running instance of the example app. Tests cover:

- **Authentication**: Login, logout, and session management
- **CRUD Operations**: Create, Read, Update, Delete for all resources
- **Navigation**: Dashboard and sidebar navigation
- **Search**: Table search and filtering

## Prerequisites

1. **Node.js** (v18 or later)
2. **Dart SDK** (for running the example server)
3. **Dash example app** running on `http://localhost:8080`

## Setup

```bash
# Navigate to the e2e test directory
cd test/e2e

# Install dependencies
npm install

# Install Playwright browsers
npm run install-browsers
```

## Running Tests

### Start the Server First

Before running tests, start the Dash example server:

```bash
# From the dash/example directory
cd ../../example
dart run lib/main.dart
```

Or use the VS Code task: `Start Dash Example Server`

### Run Tests

```bash
# Run all tests (headless)
npm test

# Run tests for a specific browser
npm run test:chromium
npm run test:firefox
npm run test:webkit

# Run tests with UI mode (interactive)
npm run test:ui

# Run tests in debug mode (see browser)
npm run test:debug

# Run tests with browser visible
npm run test:headed

# View HTML report
npm run test:report
```

### CI Mode

```bash
# Run tests in CI mode (single worker, retries)
npm run test:ci

# Or with environment variable
CI=true npm test
```

## Project Structure

```
test/e2e/
├── fixtures/
│   ├── config.ts          # Test configuration and data generators
│   └── test.fixture.ts    # Custom Playwright fixtures
├── pages/
│   ├── base.page.ts       # Base page object with common methods
│   ├── login.page.ts      # Login page interactions
│   ├── dashboard.page.ts  # Dashboard and navigation
│   └── resource.page.ts   # Generic resource CRUD operations
├── tests/
│   ├── auth.setup.ts      # Authentication setup (runs first)
│   ├── auth.spec.ts       # Authentication tests
│   ├── dashboard.spec.ts  # Dashboard navigation tests
│   ├── tags.crud.spec.ts  # Tags CRUD tests
│   ├── users.crud.spec.ts # Users CRUD tests
│   └── posts.crud.spec.ts # Posts CRUD tests
├── playwright.config.ts   # Playwright configuration
├── package.json           # Dependencies and scripts
└── tsconfig.json          # TypeScript configuration
```

## Writing New Tests

### Using Page Objects

```typescript
import { test, expect } from '@playwright/test';
import { ResourcePage } from '../pages/resource.page';
import { config } from '../fixtures/config';

test.describe('My Resource Tests', () => {
  test('should create a new item', async ({ page }) => {
    const resourcePage = new ResourcePage(page);
    
    await resourcePage.gotoCreate('/admin/my-resource');
    await resourcePage.fillField('name', 'Test Name');
    await resourcePage.submitForm();
    
    // Verify
    await resourcePage.expectRowWithText('Test Name');
  });
});
```

### Generating Test Data

```typescript
// Use unique IDs to avoid conflicts
const uniqueId = config.testData.uniqueId();
const tagData = config.testData.tag(uniqueId);

// Creates: { name: 'Test Tag xyz123', slug: 'test-tag-xyz123', ... }
```

## Configuration

### Environment Variables

- `BASE_URL` - Override the base URL (default: `http://localhost:8080`)
- `CI` - Enable CI mode (affects retries, workers, reporters)

### Browser Projects

Tests run on:
- **Chromium** (default, desktop)
- **Firefox** (desktop)
- **WebKit/Safari** (desktop)

## Troubleshooting

### Tests timeout waiting for server

Ensure the Dash example server is running before starting tests.

### Authentication issues

The setup test creates authenticated state. If login fails:
1. Verify credentials in `fixtures/config.ts`
2. Check the server has the seeded admin user
3. Clear `test-results/.auth/` and retry

### Flaky tests

- Increase timeouts in `playwright.config.ts`
- Add explicit waits where needed
- Use network idle waits after form submissions

## CI Integration

Example GitHub Actions workflow:

```yaml
name: E2E Tests

on: [push, pull_request]

jobs:
  e2e:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Dart
        uses: dart-lang/setup-dart@v1
        
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
      
      - name: Install Dart dependencies
        run: |
          cd example
          dart pub get
      
      - name: Start server
        run: |
          cd example
          dart run lib/main.dart &
          sleep 10
      
      - name: Install Playwright
        run: |
          cd test/e2e
          npm ci
          npx playwright install --with-deps chromium
      
      - name: Run E2E tests
        run: |
          cd test/e2e
          npm run test:ci
      
      - name: Upload test results
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: playwright-report
          path: test/e2e/test-results/
```
