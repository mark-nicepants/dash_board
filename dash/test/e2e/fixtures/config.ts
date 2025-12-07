/**
 * Test configuration constants for Dash E2E tests.
 */

export const config = {
  // Test credentials - matches the seeded admin user in the example app
  credentials: {
    email: 'admin@example.com',
    password: 'password',
  },
  
  // URL paths
  paths: {
    login: '/admin/login',
    dashboard: '/admin',
    logout: '/admin/logout',
    
    // Resource paths
    users: {
      index: '/admin/resources/user',
      create: '/admin/resources/user/create',
      view: (id: number | string) => `/admin/resources/user/${id}`,
      edit: (id: number | string) => `/admin/resources/user/${id}/edit`,
    },
    posts: {
      index: '/admin/resources/post',
      create: '/admin/resources/post/create',
      view: (id: number | string) => `/admin/resources/post/${id}`,
      edit: (id: number | string) => `/admin/resources/post/${id}/edit`,
    },
    tags: {
      index: '/admin/resources/tag',
      create: '/admin/resources/tag/create',
      view: (id: number | string) => `/admin/resources/tag/${id}`,
      edit: (id: number | string) => `/admin/resources/tag/${id}/edit`,
    },
  },
  
  // Timeouts (in milliseconds)
  timeouts: {
    short: 5000,
    medium: 10000,
    long: 30000,
    navigation: 15000,
  },
  
  // Test data generators
  testData: {
    uniqueId: () => Date.now().toString(36) + Math.random().toString(36).substr(2, 5),
    
    tag: (suffix?: string) => ({
      name: `Test Tag ${suffix || Date.now()}`,
      slug: `test-tag-${suffix || Date.now()}`,
      description: `A test tag created for E2E testing ${suffix || ''}`,
    }),
    
    post: (authorId: number, suffix?: string) => ({
      title: `Test Post ${suffix || Date.now()}`,
      slug: `test-post-${suffix || Date.now()}`,
      content: `This is test content for E2E testing. Created at ${new Date().toISOString()}`,
      authorId,
      isPublished: false,
    }),
    
    user: (suffix?: string) => ({
      name: `Test User ${suffix || Date.now()}`,
      email: `test-${suffix || Date.now()}@example.com`,
      password: 'testpassword123',
      role: 'user',
      isActive: true,
    }),
  },
} as const;

export type Config = typeof config;
