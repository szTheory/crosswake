import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './e2e',
  fullyParallel: false,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: 1, // Ensure tests run sequentially and avoid database locks
  reporter: 'html',
  use: {
    baseURL: 'http://localhost:4700',
    trace: 'on-first-retry',
    serviceWorkers: 'block', // Prevent service worker caching from masking test results
  },
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
  ],
  webServer: {
    command: 'MIX_ENV=test mix do ecto.drop --quiet + ecto.create --quiet + ecto.migrate --quiet + phx.server',
    port: 4700,
    reuseExistingServer: !process.env.CI,
  },
});
