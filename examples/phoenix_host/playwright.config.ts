import { defineConfig, devices } from '@playwright/test';

const EVIDENCE_PANEL_SPEC = 'evidence_panel.spec.ts';

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
      // The evidence-panel spec is scheme-parameterised and runs in the two
      // projects below instead. Ignoring it here keeps it from running a third
      // time under whatever scheme the runner happens to default to.
      testIgnore: EVIDENCE_PANEL_SPEC,
    },
    // Phase 154 Plan 08 Task 2 check E: the panel is asserted under BOTH schemes,
    // including a computed WCAG AA contrast ratio, because "toggle your OS theme
    // and look" was one of the human judgements this suite replaces.
    //
    // Deliberately scoped with testMatch rather than made global (D-47's spirit):
    // running the whole e2e suite three times would triple a merge-blocking lane's
    // wall clock to prove one panel's theming. This adds no new CI check name and
    // no new workflow — `npx playwright test` in the existing offline-sync-e2e
    // gate picks both projects up, and the route-tour lane's explicit
    // `e2e/route_tour.spec.ts` filter is unaffected.
    {
      name: 'chromium-light',
      use: { ...devices['Desktop Chrome'], colorScheme: 'light' },
      testMatch: EVIDENCE_PANEL_SPEC,
    },
    {
      name: 'chromium-dark',
      use: { ...devices['Desktop Chrome'], colorScheme: 'dark' },
      testMatch: EVIDENCE_PANEL_SPEC,
    },
  ],
  webServer: {
    command: 'MIX_ENV=test mix do ecto.drop --quiet + ecto.create --quiet + ecto.migrate --quiet + phx.server',
    port: 4700,
    reuseExistingServer: !process.env.CI,
  },
});
