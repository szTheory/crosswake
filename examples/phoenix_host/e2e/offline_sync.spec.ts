import { test, expect } from '@playwright/test';

test.describe('Crosswake offline island: card rating queues in IndexedDB, reconnect flushes via app code, Ecto confirms exactly one review row', () => {
  test.beforeEach(async ({ page }) => {
    // D-01: delete IndexedDB BEFORE page scripts open it (addInitScript runs first)
    // keep in sync with offline_study.js:3 (DB_NAME = 'crosswake_offline_study')
    await page.addInitScript(() => {
      indexedDB.deleteDatabase('crosswake_offline_study');
    });
  });

  test('offline rating queues in IndexedDB, reconnect via app flush, Ecto confirms one row, duplicate is idempotent', async ({ page, context }) => {
    // Step 1: Navigate to the offline island
    await page.goto('/offline');

    // Proves /offline is a socketless island (no LiveView WebSocket dependency)
    expect(await page.evaluate(() => !!window.liveSocket)).toBe(false); // OBSERVATION_ONLY

    // Step 2: Go offline at the network layer
    await context.setOffline(true);

    // Step 3: Queue a mutation via real UI (drives handleReview('good') → queueMutation)
    await page.click('#btn-flip');
    await page.click('#btn-good');

    // Step 4: Observe the queued record from IndexedDB (OBSERVATION_ONLY — no app state written)
    const mutations = await page.evaluate(() => { // OBSERVATION_ONLY
      return new Promise((resolve, reject) => {
        const req = indexedDB.open('crosswake_offline_study', 1);
        req.onsuccess = () => {
          const db = req.result;
          const tx = db.transaction('mutations', 'readonly');
          const store = tx.objectStore('mutations');
          const getAll = store.getAll();
          getAll.onsuccess = () => resolve(getAll.result);
          getAll.onerror = () => reject(getAll.error);
        };
        req.onerror = () => reject(req.error);
      });
    });
    expect(mutations).toHaveLength(1);
    const { client_mutation_id: capturedId, card_id, rating } = (mutations as Array<{ client_mutation_id: string; card_id: number; rating: string }>)[0];
    expect(typeof capturedId).toBe('string');
    expect(capturedId).toMatch(/^[0-9a-f-]{36}$/); // app-generated UUID (E2E-03b)
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
    await expect.poll(async () => {
      const res = await page.request.get(`/_e2e/sync-state/${capturedId}`);
      return res.ok() ? res.json() : { synced: false };
    }, { timeout: 8000, message: 'Ecto row should reflect the flushed mutation' })
      .toMatchObject({ synced: true, count: 1 });

    // Step 7: Assert outbox is empty — app deleted the accepted record (E2E-03e)
    const remaining = await page.evaluate(() => { // OBSERVATION_ONLY
      return new Promise((resolve, reject) => {
        const req = indexedDB.open('crosswake_offline_study', 1);
        req.onsuccess = () => {
          const db = req.result;
          const tx = db.transaction('mutations', 'readonly');
          const store = tx.objectStore('mutations');
          const getAll = store.getAll();
          getAll.onsuccess = () => resolve(getAll.result);
          getAll.onerror = () => reject(getAll.error);
        };
        req.onerror = () => reject(req.error);
      });
    });
    expect(remaining).toHaveLength(0);

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
});
