import { test, expect } from '@playwright/test';
import {
  assertAppGeneratedMutation,
  expectOutboxEmpty,
  expectSyncedReview,
  readQueuedOfflineMutations,
  resetOfflineStudyDatabase,
} from './support/offline_route_proof';

test.describe('Crosswake offline island: card rating queues in IndexedDB, reconnect flushes via app code, Ecto confirms exactly one review row', () => {
  const alphaScope = 'v1.scope_fixture_alpha_01';

  test.beforeEach(async ({ page }) => {
    // D-01: delete IndexedDB BEFORE page scripts open it (addInitScript runs first)
    // keep in sync with offline_study.js:3 (DB_NAME = 'crosswake_offline_study')
    await resetOfflineStudyDatabase(page);
  });

  test('offline rating queues in IndexedDB, reconnect via app flush, Ecto confirms one row, duplicate is idempotent', async ({ page, context }) => {
    // Step 1: Navigate to the offline island
    await page.goto('/offline');
    await page.evaluate(scopeRef => window.crosswakeOfflineStudy.activateScope(scopeRef), alphaScope);

    // Proves /offline is a socketless island (no LiveView WebSocket dependency)
    expect(await page.evaluate(() => !!window.liveSocket)).toBe(false); // OBSERVATION_ONLY

    // Step 2: Go offline at the network layer
    await context.setOffline(true);

    // Step 3: Queue a mutation via real UI (drives handleReview('good') → queueMutation)
    await page.click('#btn-flip');
    await page.click('#btn-good');

    // Step 4: Observe the queued record from IndexedDB (OBSERVATION_ONLY — no app state written)
    const mutations = await readQueuedOfflineMutations(page); // OBSERVATION_ONLY
    expect(mutations).toHaveLength(1);
    const { client_mutation_id: capturedId, card_id, rating } = mutations[0];
    assertAppGeneratedMutation(mutations[0]); // app-generated UUID (E2E-03b)
    expect(rating).toBe('good');

    // Step 5: Reconnect — two-step: CDP transport + explicit 'online' event
    // setOffline(false) does NOT fire the browser 'online' event (CDP toggles transport only).
    // The app's flushOutbox listener (offline_study.js:280) only fires on the window 'online' event.
    await context.setOffline(false);
    // page.dispatchEvent cannot target window — use page.evaluate exclusively (E2E-03c)
    await page.evaluate(() => window.dispatchEvent(new Event('online'))); // OBSERVATION_ONLY (env simulation)
    // D-03b: deterministic reconnect assertion — confirm app reacted before polling Ecto
    await page.waitForResponse(r => r.url().includes('/study/sync') && r.status() === 200);

    // Step 6: Server confirms exactly one row (E2E-03d)
    await expectSyncedReview(page.request, capturedId);

    // Step 7: Assert outbox is empty — app deleted the accepted record (E2E-03e)
    await expectOutboxEmpty(page);

    // Step 8: Duplicate flush — same client_mutation_id — assert exactly one Ecto row (E2E-03f)
    // page.request.post is APIRequestContext; unaffected by context.setOffline; :api pipeline has no CSRF
    // Sequence is load-bearing: original flush must be confirmed (synced: true, Step 6) BEFORE duplicate fires
    const dupRes = await page.request.post('/study/sync', {
      data: { events: [{ client_mutation_id: capturedId, card_id, rating }] }
    });
    expect(dupRes.ok()).toBe(true);
    const dupBody = await dupRes.json();
    // accepted_count is nested under .data (Phoenix JSON wrapper — not top-level)
    expect(dupBody.data.accepted_count).toBe(0); // on_conflict: :nothing held

    await expect.poll(async () => {
      const res = await page.request.get(`/_e2e/sync-state/${capturedId}`);
      return res.ok() ? res.json() : { count: -1 };
    }, { timeout: 5000 }).toMatchObject({ count: 1 }); // still exactly one row
  });

  test('exact scope storage leaves a retained second partition untouched', async ({ page, context }) => {
    const betaScope = 'v1.scope_fixture_bravo_01';

    await page.goto('/offline');
    await page.evaluate(scopeRef => window.crosswakeOfflineStudy.activateScope(scopeRef), alphaScope);

    const betaBefore = await page.evaluate(async scopeRef => {
      const db = await new Promise<IDBDatabase>((resolve, reject) => {
        const request = indexedDB.open('crosswake_offline_study', 2);
        request.onsuccess = () => resolve(request.result);
        request.onerror = () => reject(request.error);
      });

      await new Promise<void>((resolve, reject) => {
        const tx = db.transaction('scoped_mutations', 'readwrite');
        tx.objectStore('scoped_mutations').add({
          scope_ref: scopeRef,
          local_ref: 'retained-beta-entry',
          client_mutation_id: 'retained-beta-entry',
          card_id: 99,
          rating: 'hard',
        });
        tx.oncomplete = () => resolve();
        tx.onerror = () => reject(tx.error);
      });

      return [{ client_mutation_id: 'retained-beta-entry', card_id: 99, rating: 'hard' }];
    }, betaScope);

    await context.setOffline(true);
    await page.click('#btn-flip');
    await page.click('#btn-good');

    const alphaRecords = await readQueuedOfflineMutations(page, { scopeRef: alphaScope });
    const betaAfter = await readQueuedOfflineMutations(page, { scopeRef: betaScope });

    expect(alphaRecords).toHaveLength(1);
    expect(betaAfter).toEqual(betaBefore);
    await expect(page.locator('#status')).not.toContainText(alphaScope);
    await expect(page.locator('#status')).not.toContainText(betaScope);
  });
});
