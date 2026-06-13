import { defineConfig, devices } from '@playwright/test';

// Self-contained brand-verification config. No coupling to examples/phoenix_host:
// the webServer is a dependency-free static server over the brandbook/ directory,
// so this suite runs without Elixir/Phoenix on any runner with Node + Chromium.
const PORT = Number(process.env.PORT) || 5099;

export default defineConfig({
  testDir: './tests',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 1 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: process.env.CI ? [['github'], ['html', { open: 'never' }]] : 'list',
  use: {
    baseURL: `http://localhost:${PORT}`,
    trace: 'on-first-retry',
    // Grant clipboard so the copy-hex success path (button → "Copied!") can run.
    permissions: ['clipboard-read', 'clipboard-write'],
  },
  projects: [{ name: 'chromium', use: { ...devices['Desktop Chrome'] } }],
  webServer: {
    command: 'node static-server.mjs',
    port: PORT,
    reuseExistingServer: !process.env.CI,
    env: { PORT: String(PORT) },
  },
});
