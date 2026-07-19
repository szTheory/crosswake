import { test, expect } from '@playwright/test';
import path from 'node:path';
import {
  assertAppGeneratedMutation,
  expectOutboxEmpty,
  expectSyncedReview,
  proveLearnLoopRoute,
  readQueuedOfflineMutations,
  resetOfflineStudyDatabase,
} from './support/offline_route_proof';

const screenshotDir = path.join(process.cwd(), 'playwright-artifacts', 'route-tour', 'screenshots');

test.describe('LearnLoop route tour: product shell to socketless offline study and backend projection', () => {
  test.beforeEach(async ({ page }) => {
    await resetOfflineStudyDatabase(page);
  });

  test('@learnloop-offline proves LearnLoop socketless study island queues, syncs, and deduplicates review events', async ({ page, context }) => {
    const reset = await page.request.post('/_e2e/showcase-reset');
    expect(reset.ok(), learnloopMessage('showcase-reset', 'server-owned learning reset')).toBe(true);
    const resetBody = await reset.json();
    expect(resetBody.browser_state_reset, learnloopMessage('showcase-reset', 'browser-owned IndexedDB is not server-reset')).toBe(false);

    await page.goto('/learnloop/study/session');

    expect(await page.evaluate(() => !!window.liveSocket), learnloopMessage('learnloop-study-session', 'socketless island')).toBe(false);
    await expect(page.locator('body'), learnloopMessage('learnloop-study-session', 'LearnLoop route metadata')).toHaveAttribute('data-route-id', 'learnloop-study-session');
    await expect(page.locator('body'), learnloopMessage('learnloop-study-session', 'configured sync endpoint')).toHaveAttribute('data-sync-endpoint', '/learnloop/sync');
    await expect(page.locator('body'), learnloopMessage('learnloop-study-session', 'browser state owner')).toHaveAttribute('data-browser-state-owner', 'device');
    await expect(page.locator('#flashcard-container'), learnloopMessage('learnloop-study-session', 'study island cards')).toContainText(/Elixir|Loading flashcards/i);
    await expect(page.locator('body'), learnloopMessage('learnloop-study-session', 'reset honesty copy')).toContainText("Server reset does not clear this device's offline state");

    await context.setOffline(true);
    await page.click('#btn-flip');
    await page.click('#btn-good');
    await expect(page.locator('#status'), learnloopMessage('learnloop-study-session', 'queued status copy')).toContainText(/Saved locally|Queued for replay/i);

    const mutations = await readQueuedOfflineMutations(page);
    expect(mutations, learnloopMessage('learnloop-study-session', 'one queued review event')).toHaveLength(1);
    const { client_mutation_id: capturedId, card_id, rating } = mutations[0];
    assertAppGeneratedMutation(mutations[0]);

    await context.setOffline(false);
    await page.evaluate(() => window.dispatchEvent(new Event('online')));
    await page.waitForResponse(response =>
      response.url().includes('/learnloop/sync') &&
      response.status() === 200,
    );

    await expect(page.locator('#status'), learnloopMessage('learnloop-study-session', 'synced status copy')).toContainText(/Synced \d+ - queued 0/i);
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
    await expectOutboxEmpty(page);
  });

  test('@learnloop proves LearnLoop route ownership, offline island sync, entitlement copy, and support truth before screenshots', async ({ page, context }) => {
    await proveLearnLoopRoute(page, context, { screenshotDir });
  });
});

function learnloopMessage(routeId: string, assertion: string) {
  return `LearnLoop route-tour semantic assertion failed for route id ${routeId} (${assertion}); screenshots are collateral after this assertion passes`;
}
