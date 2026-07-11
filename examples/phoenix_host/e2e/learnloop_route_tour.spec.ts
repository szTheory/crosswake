import { test, expect, type Page } from '@playwright/test';
import { mkdirSync } from 'node:fs';
import path from 'node:path';
import {
  assertAppGeneratedMutation,
  expectOutboxEmpty,
  expectSyncedReview,
  readQueuedOfflineMutations,
  resetOfflineStudyDatabase,
} from './support/offline_route_proof';

const screenshotDir = path.join(process.cwd(), 'playwright-artifacts', 'route-tour', 'screenshots');

test.describe('LearnLoop route tour: product shell to socketless offline study and backend projection', () => {
  test.beforeEach(async ({ page }) => {
    await resetOfflineStudyDatabase(page);
  });

  test('@learnloop proves LearnLoop route ownership, offline island sync, entitlement copy, and support truth before screenshots', async ({ page, context }) => {
    mkdirSync(screenshotDir, { recursive: true });

    const reset = await page.request.post('/_e2e/showcase-reset');
    expect(reset.ok(), learnloopMessage('showcase-reset', 'deterministic reset')).toBe(true);
    const resetBody = await reset.json();
    expect(resetBody.browser_state_reset, learnloopMessage('showcase-reset', 'browser-owned IndexedDB remains browser-owned')).toBe(false);

    await page.goto('/learnloop');
    await expect(page, learnloopMessage('learnloop-dashboard', 'browser title')).toHaveTitle(/LearnLoop|Crosswake/);
    await expect(page.getByRole('heading', { name: /LearnLoop|Brightpath|today's path/i }), learnloopMessage('learnloop-dashboard', 'product-first dashboard')).toBeVisible();
    await expect(page.locator('body'), learnloopMessage('learnloop-dashboard', 'learner progress before monetization')).toContainText(/Iris Learner|course|progress/i);
    await expect(page.locator('body'), learnloopMessage('learnloop-dashboard', 'route support labels')).toContainText(/LiveView route|Cached read-only|Offline island|Local-first outbox/i);

    await page.getByRole('link', { name: /course|continue|Elixir/i }).first().click();
    await expect(page, learnloopMessage('learnloop-course', 'course detail route')).toHaveURL(/\/learnloop\/courses\/course-elixir-routing$/);
    await expect(page.locator('body'), learnloopMessage('learnloop-course', 'gated lesson pressure')).toContainText('Backend projection required');
    await expect(page.locator('body'), learnloopMessage('learnloop-course', 'fail-closed copy')).toContainText('Access stays closed until backend projection refreshes');

    await page.getByRole('link', { name: /subscription|access|projection/i }).first().click();
    await expect(page, learnloopMessage('learnloop-subscription', 'subscription route')).toHaveURL(/\/learnloop\/subscription$/);
    await expect(page.locator('body'), learnloopMessage('learnloop-subscription', 'mock storefront evidence')).toContainText('Mock storefront evidence received');
    await expect(page.locator('body'), learnloopMessage('learnloop-subscription', 'no live provider support')).toContainText('No live StoreKit, Play Billing, or RevenueCat adapter in this demo');
    await expect(page.locator('body'), learnloopMessage('learnloop-subscription', 'unsupported provider overclaim')).not.toContainText(/purchase succeeded|subscription verified on device|RevenueCat adapter/i);

    await page.goto('/learnloop/packs/learnloop_daily_pack');
    await expect(page.locator('body'), learnloopMessage('learnloop-pack', 'content pack metadata')).toContainText(/learnloop_daily_pack|Daily Elixir Pack|Content pack/i);
    await expect(page.locator('body'), learnloopMessage('learnloop-pack', 'offline handoff')).toContainText(/Offline island|Local-first outbox|Queued for replay/i);

    await page.goto('/learnloop/study/session');
    expect(await page.evaluate(() => !!window.liveSocket), learnloopMessage('learnloop-study-session', 'socketless island')).toBe(false);
    await expect(page.locator('#flashcard-container'), learnloopMessage('learnloop-study-session', 'study island cards')).toContainText(/Elixir|Loading flashcards/i);

    await context.setOffline(true);
    await page.click('#btn-flip');
    await page.click('#btn-good');

    const mutations = await readQueuedOfflineMutations(page);
    expect(mutations, learnloopMessage('learnloop-study-session', 'one queued review event')).toHaveLength(1);
    const { client_mutation_id: capturedId, card_id, rating } = mutations[0];
    assertAppGeneratedMutation(mutations[0]);

    await context.setOffline(false);
    await page.evaluate(() => window.dispatchEvent(new Event('online')));
    await page.waitForResponse(response =>
      (response.url().includes('/learnloop/sync') || response.url().includes('/study/sync')) &&
      response.status() === 200,
    );

    await expectSyncedReview(page.request, capturedId);
    await expectOutboxEmpty(page);

    const duplicate = await page.request.post('/learnloop/sync', {
      data: {
        events: [{ client_mutation_id: capturedId, card_id, rating }],
      },
    });
    expect(duplicate.ok(), learnloopMessage('learnloop-study-session', 'duplicate replay accepted as idempotent request')).toBe(true);
    const duplicateBody = await duplicate.json();
    expect(duplicateBody.data.accepted_count, learnloopMessage('learnloop-study-session', 'duplicate replay creates no second row')).toBe(0);
    await expectSyncedReview(page.request, capturedId);

    await page.goto('/learnloop/history');
    await expect(page.locator('body'), learnloopMessage('learnloop-history', 'server-confirmed history')).toContainText(/server-confirmed|Cached read-only|Synced/i);

    await openLearnLoopDiagnostics(page);
    await expect(page.locator('body'), learnloopMessage('learnloop-diagnostics', 'support truth')).toContainText(/Route policy diagnostics|learnloop-study-session|Support truth/i);
    await expect(page.locator('body'), learnloopMessage('learnloop-diagnostics', 'unsupported native storage')).not.toContainText(/native storage shipped|generic sync engine|LiveView works offline/i);

    await page.screenshot({ path: path.join(screenshotDir, 'learnloop-route-tour.png'), fullPage: true });
  });
});

async function openLearnLoopDiagnostics(page: Page) {
  const summary = page.locator('.learnloop-diagnostics summary').first();
  if (await summary.count()) {
    await summary.click();
  }
}

function learnloopMessage(routeId: string, assertion: string) {
  return `LearnLoop route-tour semantic assertion failed for route id ${routeId} (${assertion}); screenshots are collateral after this assertion passes`;
}
