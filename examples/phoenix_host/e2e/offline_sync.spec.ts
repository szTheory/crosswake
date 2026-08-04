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

  async function waitForInactiveLifecycle(page) {
    await expect.poll(() => page.locator('#crosswake-study-status').textContent()).toContain('Your saved answers remain on this iPhone.');
  }

  test.beforeEach(async ({ page }, testInfo) => {
    const session = await page.request.post('/_e2e/replay-session', {
      data: { action: 'establish' },
    });
    expect(session.status()).toBe(201);

    if (testInfo.title.includes('quarantined') || testInfo.title.includes('legacy') || testInfo.title.includes('online activation')) return;
    // D-01: delete IndexedDB BEFORE page scripts open it (addInitScript runs first)
    // keep in sync with offline_study.js:3 (DB_NAME = 'crosswake_offline_study')
    await resetOfflineStudyDatabase(page);
  });

  test('fully authorized scoped Study event reaches the host atomically and preserves another partition', async ({ page, context }) => {
    // Step 1: Navigate to the offline island
    await page.goto('/offline');
    await waitForInactiveLifecycle(page);
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
      data: { scope_ref: alphaScope, events: [{ client_mutation_id: capturedId, card_id, rating }] }
    });
    expect(dupRes.ok()).toBe(true);
    const dupBody = await dupRes.json();
    expect(dupBody.data.accepted_records).toEqual([{ client_mutation_id: capturedId, outcome: 'accepted' }]);

    await expect.poll(async () => {
      const res = await page.request.get(`/_e2e/sync-state/${capturedId}`);
      return res.ok() ? res.json() : { count: -1 };
    }, { timeout: 5000 }).toMatchObject({ count: 1 }); // still exactly one row
  });

  test('anonymous, logged-out, switched, and revoked replay sessions deny before persistence', async ({ page }) => {
    const denied = async (action: 'clear' | 'switch' | 'revoke', suffix: string) => {
      const session = await page.request.post('/_e2e/replay-session', { data: { action } });
      expect(session.ok()).toBe(true);

      const mutationId = `authority-denial-${suffix}`;
      const response = await page.request.post('/study/sync', {
        data: {
          scope_ref: alphaScope,
          events: [{ client_mutation_id: mutationId, card_id: 1, rating: 'good' }],
        },
      });

      expect(response.status()).toBe(403);
      expect(await response.json()).toMatchObject({ error: { class: expect.any(String) } });

      const state = await page.request.get(`/_e2e/sync-state/${mutationId}`);
      expect(await state.json()).toMatchObject({ count: 0 });
    };

    await denied('clear', 'anonymous');
    await page.request.post('/_e2e/replay-session', { data: { action: 'establish' } });
    await denied('clear', 'logout');
    await page.request.post('/_e2e/replay-session', { data: { action: 'establish' } });
    await denied('switch', 'switch');
    await page.request.post('/_e2e/replay-session', { data: { action: 'establish' } });
    await denied('revoke', 'revoked');
  });

  test('exact scope storage leaves a retained second partition untouched', async ({ page, context }) => {
    const betaScope = 'v1.scope_fixture_bravo_01';

    await page.goto('/offline');
    await waitForInactiveLifecycle(page);
    await page.evaluate(scopeRef => window.crosswakeOfflineStudy.activateScope(scopeRef), alphaScope);

    const betaBefore = await page.evaluate(async scopeRef => {
      const db = await new Promise<IDBDatabase>((resolve, reject) => {
        const request = indexedDB.open('crosswake_offline_study', 4);
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
    await expect(page.locator('#crosswake-study-status')).not.toContainText(alphaScope);
    await expect(page.locator('#crosswake-study-status')).not.toContainText(betaScope);
  });

  test('inactive relaunch keeps retained work unavailable until host activation', async ({ page }) => {
    await page.goto('/offline');
    await waitForInactiveLifecycle(page);

    await expect.poll(async () => page.evaluate(async () => {
      const db = await new Promise<IDBDatabase>((resolve, reject) => {
        const request = indexedDB.open('crosswake_offline_study', 4);
        request.onsuccess = () => resolve(request.result);
        request.onerror = () => reject(request.error);
      });
      return await new Promise<any>((resolve, reject) => {
        const tx = db.transaction('scope_lifecycle', 'readonly');
        const request = tx.objectStore('scope_lifecycle').get('active');
        request.onsuccess = () => resolve(request.result);
        request.onerror = () => reject(request.error);
      });
    })).toMatchObject({ state: 'inactive', scope_ref: null });

    await expect(page.locator('#crosswake-study-status')).toContainText('Your saved answers remain on this iPhone.');
  });

  test('rapid ratings queue one mutation for one card', async ({ page, context }) => {
    const pageErrors: string[] = [];
    page.on('pageerror', error => pageErrors.push(error.message));

    await page.goto('/offline');
    await waitForInactiveLifecycle(page);
    await page.evaluate(scopeRef => window.crosswakeOfflineStudy.activateScope(scopeRef), alphaScope);
    await context.setOffline(true);
    await page.click('#btn-flip');

    await page.evaluate(() => {
      document.getElementById('btn-good')?.click();
      document.getElementById('btn-hard')?.click();
    });

    await expect.poll(async () => (await readQueuedOfflineMutations(page, { scopeRef: alphaScope })).length).toBe(1);
    expect(await readQueuedOfflineMutations(page, { scopeRef: alphaScope })).toMatchObject([{ card_id: 1, rating: 'good' }]);
    await expect(page.locator('#flashcard-container')).toContainText('Phoenix');
    expect(pageErrors).toEqual([]);
  });

  test('online activation replays retained exact-scope work', async ({ page, context }) => {
    const pageErrors: string[] = [];
    const consoleOutput: string[] = [];

    await page.goto('/');
    await page.evaluate(() => new Promise<void>((resolve, reject) => {
      const request = indexedDB.deleteDatabase('crosswake_offline_study');
      request.onsuccess = () => resolve();
      request.onerror = () => reject(request.error);
      request.onblocked = () => reject(new Error('database reset blocked'));
    }));
    await page.goto('/offline');
    await waitForInactiveLifecycle(page);
    await page.evaluate(scopeRef => window.crosswakeOfflineStudy.activateScope(scopeRef), alphaScope);
    await context.setOffline(true);
    await page.click('#btn-flip');
    await page.click('#btn-good');
    expect(await readQueuedOfflineMutations(page, { scopeRef: alphaScope })).toHaveLength(1);
    await page.evaluate(() => window.crosswakeOfflineStudy.fenceScope());
    await context.setOffline(false);
    await page.reload();
    await waitForInactiveLifecycle(page);
    page.on('pageerror', error => pageErrors.push(error.message));
    page.on('console', message => consoleOutput.push(message.text()));

    await page.evaluate(() => {
      (window as any).__activationReplayRequests = 0;
      window.fetch = async (_input, init) => {
        (window as any).__activationReplayRequests += 1;
        const body = JSON.parse(String(init?.body));
        return new Response(JSON.stringify({ data: {
          accepted_records: body.events.map((event: { client_mutation_id: string }) => ({
            client_mutation_id: event.client_mutation_id,
          })),
          rejected: [],
        } }), { status: 200, headers: { 'Content-Type': 'application/json' } });
      };
    });

    await page.evaluate(scopeRef => window.crosswakeOfflineStudy.activateScope(scopeRef), alphaScope);
    await expect.poll(async () => (await readQueuedOfflineMutations(page, { scopeRef: alphaScope })).length).toBe(0);
    expect(await page.evaluate(() => (window as any).__activationReplayRequests)).toBe(1);
    expect(pageErrors).toEqual([]);
    expect(consoleOutput).toEqual([]);
    await expect(page.locator('body')).not.toContainText(alphaScope);
  });

  test('inactive online replay is inert after launch and fence', async ({ page }) => {
    const pageErrors: string[] = [];
    const consoleOutput: string[] = [];
    page.on('pageerror', error => pageErrors.push(error.message));
    page.on('console', message => consoleOutput.push(message.text()));

    await page.goto('/offline');
    await waitForInactiveLifecycle(page);
    await page.evaluate(() => {
      (window as any).__inactiveOnlineReplay = { fetches: 0, rejections: 0 };
      window.fetch = () => {
        (window as any).__inactiveOnlineReplay.fetches += 1;
        return Promise.reject(new Error('unexpected replay request'));
      };
      window.addEventListener('unhandledrejection', event => {
        (window as any).__inactiveOnlineReplay.rejections += 1;
        event.preventDefault();
      });
    });

    const inactiveStatus = await page.locator('#crosswake-study-status').textContent();
    await page.evaluate(() => window.dispatchEvent(new Event('online')));
    await page.waitForTimeout(50);

    expect(await page.evaluate(() => (window as any).__inactiveOnlineReplay)).toEqual({ fetches: 0, rejections: 0 });
    expect(await page.locator('#crosswake-study-status').textContent()).toBe(inactiveStatus);
    expect(pageErrors).toEqual([]);
    expect(consoleOutput).toEqual([]);

    await page.evaluate(async scopeRef => {
      await window.crosswakeOfflineStudy.activateScope(scopeRef);
      await window.crosswakeOfflineStudy.fenceScope();
    }, alphaScope);
    const fencedStatus = await page.locator('#crosswake-study-status').textContent();
    await page.evaluate(() => window.dispatchEvent(new Event('online')));
    await page.waitForTimeout(50);

    expect(await page.evaluate(() => (window as any).__inactiveOnlineReplay)).toEqual({ fetches: 0, rejections: 0 });
    expect(await page.locator('#crosswake-study-status').textContent()).toBe(fencedStatus);
    expect(pageErrors).toEqual([]);
    expect(consoleOutput).toEqual([]);
  });

  test('active online replay catches unexpected failures without stale status effects', async ({ page }) => {
    const pageErrors: string[] = [];
    const consoleOutput: string[] = [];
    page.on('pageerror', error => pageErrors.push(error.message));
    page.on('console', message => consoleOutput.push(message.text()));

    await page.goto('/offline');
    await waitForInactiveLifecycle(page);
    await page.evaluate(scopeRef => window.crosswakeOfflineStudy.activateScope(scopeRef), alphaScope);
    await page.evaluate(() => {
      (window as any).__activeOnlineReplay = { rejections: 0 };
      const transaction = IDBDatabase.prototype.transaction;
      IDBDatabase.prototype.transaction = function (...args) {
        if (args[0] === 'scoped_mutations') throw new Error('unexpected storage failure');
        return transaction.apply(this, args as any);
      };
      window.addEventListener('unhandledrejection', event => {
        (window as any).__activeOnlineReplay.rejections += 1;
        event.preventDefault();
      });
    });

    await page.evaluate(() => window.dispatchEvent(new Event('online')));
    await expect(page.locator('#crosswake-study-status')).toContainText('Your saved answers remain on this iPhone.');
    expect(await page.evaluate(() => (window as any).__activeOnlineReplay)).toEqual({ rejections: 0 });
    expect(pageErrors).toEqual([]);
    expect(consoleOutput).toEqual([]);

    await page.evaluate(async () => window.crosswakeOfflineStudy.fenceScope());
    const fencedStatus = await page.locator('#crosswake-study-status').textContent();
    await page.evaluate(() => window.dispatchEvent(new Event('online')));
    await page.waitForTimeout(50);
    expect(await page.locator('#crosswake-study-status').textContent()).toBe(fencedStatus);
  });

  test('immediate online submit failure retains queued work without an unhandled rejection', async ({ page }) => {
    const pageErrors: string[] = [];
    const consoleOutput: string[] = [];
    page.on('pageerror', error => pageErrors.push(error.message));
    page.on('console', message => consoleOutput.push(message.text()));

    await page.goto('/offline');
    await waitForInactiveLifecycle(page);
    await page.evaluate(scopeRef => window.crosswakeOfflineStudy.activateScope(scopeRef), alphaScope);
    await page.evaluate(() => {
      (window as any).__immediateOnlineFailure = { readonlyCalls: 0, storageFailures: 0, rejections: 0 };
      const transaction = IDBDatabase.prototype.transaction;
      IDBDatabase.prototype.transaction = function (stores, mode, options) {
        if (stores === 'scoped_mutations' && mode === 'readonly') {
          const failure = (window as any).__immediateOnlineFailure;
          failure.readonlyCalls += 1;
          if (failure.readonlyCalls === 2) {
            failure.storageFailures += 1;
            throw new Error('worker storage failure');
          }
        }
        return transaction.call(this, stores, mode, options);
      };
      window.addEventListener('unhandledrejection', event => {
        (window as any).__immediateOnlineFailure.rejections += 1;
        event.preventDefault();
      });
    });

    await page.click('#btn-flip');
    await page.click('#btn-good');

    await expect(page.locator('#crosswake-study-status')).toContainText('Your saved answers remain on this iPhone.');
    expect(await readQueuedOfflineMutations(page, { scopeRef: alphaScope })).toHaveLength(1);
    expect(await page.evaluate(() => (window as any).__immediateOnlineFailure.storageFailures)).toBe(1);
    expect(pageErrors).toEqual([]);
    expect(consoleOutput).toEqual([]);

    await page.evaluate(async () => window.crosswakeOfflineStudy.fenceScope());
    await page.waitForTimeout(50);
    expect(await page.evaluate(() => (window as any).__immediateOnlineFailure.storageFailures)).toBe(1);
    expect(await readQueuedOfflineMutations(page, { scopeRef: alphaScope })).toHaveLength(1);
  });

  test('switch before send keeps the old scope queue retained', async ({ page, context }) => {
    const betaScope = 'v1.scope_fixture_bravo_01';
    await page.goto('/offline');
    await waitForInactiveLifecycle(page);
    await page.evaluate(scopeRef => window.crosswakeOfflineStudy.activateScope(scopeRef), alphaScope);
    await context.setOffline(true);
    await page.click('#btn-flip');
    await page.click('#btn-good');

    await page.evaluate(async scopeRef => {
      await window.crosswakeOfflineStudy.fenceScope();
      await window.crosswakeOfflineStudy.activateScope(scopeRef);
    }, betaScope);
    await context.setOffline(false);
    await page.evaluate(() => window.dispatchEvent(new Event('online')));

    expect(await readQueuedOfflineMutations(page, { scopeRef: alphaScope })).toHaveLength(1);
    expect(await readQueuedOfflineMutations(page, { scopeRef: betaScope })).toHaveLength(0);
  });

  test('switch in flight keeps an old completion from deleting or updating the new scope', async ({ page, context }) => {
    const betaScope = 'v1.scope_fixture_bravo_01';
    await page.goto('/offline');
    await waitForInactiveLifecycle(page);
    await page.evaluate(scopeRef => window.crosswakeOfflineStudy.activateScope(scopeRef), alphaScope);
    await context.setOffline(true);
    await page.click('#btn-flip');
    await page.click('#btn-good');
    const [queued] = await readQueuedOfflineMutations(page, { scopeRef: alphaScope });

    let fulfill!: () => Promise<void>;
    await page.route('**/study/sync', async route => {
      await new Promise<void>(resolve => { fulfill = async () => { await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({ data: { accepted_records: [{ client_mutation_id: queued.client_mutation_id }], rejected: [] } }),
      }); resolve(); }; });
    });

    await context.setOffline(false);
    await page.evaluate(() => window.dispatchEvent(new Event('online')));
    await expect.poll(() => Boolean(fulfill)).toBe(true);
    await page.evaluate(async scopeRef => {
      await window.crosswakeOfflineStudy.fenceScope();
      await window.crosswakeOfflineStudy.activateScope(scopeRef);
    }, betaScope);
    await fulfill();

    await expect.poll(async () => (await readQueuedOfflineMutations(page, { scopeRef: alphaScope })).length).toBe(1);
    expect(await readQueuedOfflineMutations(page, { scopeRef: betaScope })).toHaveLength(0);
    await expect(page.locator('#crosswake-study-status')).not.toContainText(alphaScope);
  });

  test('post-response fence blocks old success side effects', async ({ page, context }) => {
    const betaScope = 'v1.scope_fixture_bravo_01';
    await page.goto('/offline');
    await waitForInactiveLifecycle(page);
    await page.evaluate(scopeRef => window.crosswakeOfflineStudy.activateScope(scopeRef), alphaScope);
    await context.setOffline(true);
    await page.click('#btn-flip');
    await page.click('#btn-good');
    const [queued] = await readQueuedOfflineMutations(page, { scopeRef: alphaScope });

    await page.evaluate(() => {
      window.fetch = () => new Promise(resolve => {
        (window as any).__releaseScopedReplay = () => resolve(new Response(JSON.stringify({
          data: { accepted_records: [{ client_mutation_id: 'pending' }], rejected: [] },
        }), { status: 200, headers: { 'Content-Type': 'application/json' } }));
      });
    });

    await context.setOffline(false);
    await page.evaluate(() => window.dispatchEvent(new Event('online')));
    await expect.poll(() => page.evaluate(() => Boolean((window as any).__releaseScopedReplay))).toBe(true);

    const fence = page.evaluate(() => window.crosswakeOfflineStudy.fenceScope());
    expect(await Promise.race([
      fence.then(() => 'settled'),
      page.waitForTimeout(50).then(() => 'pending'),
    ])).toBe('pending');
    await page.evaluate(() => (window as any).__releaseScopedReplay());
    await fence;
    await page.evaluate(scopeRef => window.crosswakeOfflineStudy.activateScope(scopeRef), betaScope);

    expect(await readQueuedOfflineMutations(page, { scopeRef: alphaScope })).toHaveLength(1);
    expect(await readQueuedOfflineMutations(page, { scopeRef: betaScope })).toHaveLength(0);
    await expect(page.locator('#crosswake-study-status')).toContainText('Your saved answers remain on this iPhone.');
  });

  test('post-response fence blocks old denial status', async ({ page, context }) => {
    const betaScope = 'v1.scope_fixture_bravo_01';
    await page.goto('/offline');
    await waitForInactiveLifecycle(page);
    await page.evaluate(scopeRef => window.crosswakeOfflineStudy.activateScope(scopeRef), alphaScope);
    await context.setOffline(true);
    await page.click('#btn-flip');
    await page.click('#btn-good');

    let releaseResponse!: () => Promise<void>;
    await page.route('**/study/sync', async route => {
      await new Promise<void>(resolve => {
        releaseResponse = async () => {
          await route.fulfill({ status: 403, contentType: 'application/json', body: JSON.stringify({ error: { class: 'feature_disabled' } }) });
          resolve();
        };
      });
    });

    await context.setOffline(false);
    await page.evaluate(() => window.dispatchEvent(new Event('online')));
    await expect.poll(() => Boolean(releaseResponse)).toBe(true);

    const fence = page.evaluate(() => window.crosswakeOfflineStudy.fenceScope());
    await releaseResponse();
    await fence;
    await page.evaluate(scopeRef => window.crosswakeOfflineStudy.activateScope(scopeRef), betaScope);

    expect(await readQueuedOfflineMutations(page, { scopeRef: alphaScope })).toHaveLength(1);
    await expect(page.locator('#crosswake-study-status')).toContainText('Your saved answers remain on this iPhone.');
  });

  test('mid-batch disablement retains halted suffix', async ({ page, context }) => {
    await page.goto('/offline');
    await waitForInactiveLifecycle(page);
    await page.evaluate(scopeRef => window.crosswakeOfflineStudy.activateScope(scopeRef), alphaScope);
    await context.setOffline(true);
    await page.click('#btn-flip');
    await page.click('#btn-good');
    await page.click('#btn-flip');
    await page.click('#btn-hard');
    const queued = await readQueuedOfflineMutations(page, { scopeRef: alphaScope });
    expect(queued).toHaveLength(2);

    let requests = 0;
    await page.route('**/study/sync', async route => {
      requests += 1;
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({ data: {
          accepted_records: [{ client_mutation_id: queued[0].client_mutation_id }],
          rejected: [],
          halted: 'feature_disabled',
        } }),
      });
    });

    await context.setOffline(false);
    await page.evaluate(() => window.dispatchEvent(new Event('online')));
    await expect.poll(async () => (await readQueuedOfflineMutations(page, { scopeRef: alphaScope })).length).toBe(1);
    expect((await readQueuedOfflineMutations(page, { scopeRef: alphaScope }))[0].client_mutation_id).toBe(queued[1].client_mutation_id);
    await expect(page.locator('#crosswake-study-status')).toContainText('Your saved answers remain on this iPhone.');
    expect(requests).toBe(1);
  });

  test('malformed halted response fails closed', async ({ page, context }) => {
    await page.goto('/offline');
    await waitForInactiveLifecycle(page);
    await page.evaluate(scopeRef => window.crosswakeOfflineStudy.activateScope(scopeRef), alphaScope);
    await context.setOffline(true);
    await page.click('#btn-flip');
    await page.click('#btn-good');

    await page.route('**/study/sync', async route => {
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({ data: { accepted_records: 'not-an-array', rejected: [], halted: 'feature_disabled' } }),
      });
    });

    await context.setOffline(false);
    await page.evaluate(() => window.dispatchEvent(new Event('online')));
    await expect.poll(async () => (await readQueuedOfflineMutations(page, { scopeRef: alphaScope })).length).toBe(1);
    await expect(page.locator('#crosswake-study-status')).toContainText('Your saved answers remain on this iPhone.');
  });

  test('truncated successful acknowledgement fails closed', async ({ page, context }) => {
    await page.goto('/offline');
    await waitForInactiveLifecycle(page);
    await page.evaluate(scopeRef => window.crosswakeOfflineStudy.activateScope(scopeRef), alphaScope);
    await context.setOffline(true);
    await page.click('#btn-flip');
    await page.click('#btn-good');
    await page.click('#btn-flip');
    await page.click('#btn-hard');
    const queued = await readQueuedOfflineMutations(page, { scopeRef: alphaScope });
    expect(queued).toHaveLength(2);

    let requests = 0;
    await page.route('**/study/sync', async route => {
      requests += 1;
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({ data: {
          accepted_records: [{ client_mutation_id: queued[0].client_mutation_id }],
          rejected: [],
        } }),
      });
    });

    await context.setOffline(false);
    await page.evaluate(() => window.dispatchEvent(new Event('online')));
    await expect.poll(async () => (await readQueuedOfflineMutations(page, { scopeRef: alphaScope })).length).toBe(2);
    await expect(page.locator('#crosswake-study-status')).toContainText('Your saved answers remain on this iPhone.');
    expect(requests).toBe(1);
  });

  test('legacy upgrade quarantines unscoped work', async ({ page }) => {
    await page.goto('/');
    await page.evaluate(async () => {
      await new Promise<void>((resolve, reject) => {
        const request = indexedDB.open('crosswake_offline_study', 1);
        request.onupgradeneeded = () => {
          request.result.createObjectStore('mutations', { keyPath: 'client_mutation_id' });
        };
        request.onsuccess = () => {
          const tx = request.result.transaction('mutations', 'readwrite');
          tx.objectStore('mutations').add({
            client_mutation_id: 'legacy-mutation',
            card_id: 1,
            rating: 'good',
          });
          tx.oncomplete = () => {
            request.result.close();
            resolve();
          };
          tx.onerror = () => reject(tx.error);
        };
        request.onerror = () => reject(request.error);
      });
    });

    await page.goto('/offline');
    await expect(page.locator('#crosswake-study-status')).toContainText('Some saved answers need review.');

    const stores = await page.evaluate(async () => {
      const database = await new Promise<IDBDatabase>((resolve, reject) => {
        const request = indexedDB.open('crosswake_offline_study');
        request.onsuccess = () => resolve(request.result);
        request.onerror = () => reject(request.error);
      });
      const tx = database.transaction(['mutations', 'legacy_mutations_quarantine', 'scoped_mutations'], 'readonly');
      const counts = await Promise.all([
        new Promise<number>((resolve, reject) => {
          const request = tx.objectStore('mutations').count();
          request.onsuccess = () => resolve(request.result);
          request.onerror = () => reject(request.error);
        }),
        new Promise<number>((resolve, reject) => {
          const request = tx.objectStore('legacy_mutations_quarantine').count();
          request.onsuccess = () => resolve(request.result);
          request.onerror = () => reject(request.error);
        }),
        new Promise<number>((resolve, reject) => {
          const request = tx.objectStore('scoped_mutations').count();
          request.onsuccess = () => resolve(request.result);
          request.onerror = () => reject(request.error);
        }),
      ]);
      database.close();
      return counts;
    });

    expect(stores).toEqual([0, 1, 0]);
    await expect(page.locator('#crosswake-study-status')).toContainText('Some saved answers need review.');
    await expect(page.locator('body')).not.toContainText('legacy-mutation');

    await page.reload();
    await expect(page.locator('#crosswake-study-status')).toContainText('Some saved answers need review.');
    await page.evaluate(scopeRef => window.crosswakeOfflineStudy.activateScope(scopeRef), 'v1.scope_fixture_bravo_01');
    await expect(page.locator('#crosswake-study-status')).not.toContainText('scope_fixture_bravo_01');

    const afterRelaunch = await page.evaluate(async () => {
      const database = await new Promise<IDBDatabase>((resolve, reject) => {
        const request = indexedDB.open('crosswake_offline_study');
        request.onsuccess = () => resolve(request.result);
        request.onerror = () => reject(request.error);
      });
      const tx = database.transaction(['legacy_mutations_quarantine', 'scoped_mutations'], 'readonly');
      const counts = await Promise.all(['legacy_mutations_quarantine', 'scoped_mutations'].map(storeName =>
        new Promise<number>((resolve, reject) => {
          const request = tx.objectStore(storeName).count();
          request.onsuccess = () => resolve(request.result);
          request.onerror = () => reject(request.error);
        }),
      ));
      database.close();
      return counts;
    });
    expect(afterRelaunch).toEqual([1, 0]);
  });

  test('unscoped legacy work remains recovery-required across account switch', async ({ page }) => {
    await page.goto('/');
    await page.evaluate(async () => {
      await new Promise<void>((resolve, reject) => {
        const request = indexedDB.open('crosswake_offline_study', 1);
        request.onupgradeneeded = () => request.result.createObjectStore('mutations', { keyPath: 'client_mutation_id' });
        request.onsuccess = () => {
          const tx = request.result.transaction('mutations', 'readwrite');
          tx.objectStore('mutations').add({
            client_mutation_id: '00000000-0000-4000-8000-000000000004',
            card_id: 1,
            rating: 'good',
          });
          tx.oncomplete = () => { request.result.close(); resolve(); };
          tx.onerror = () => reject(tx.error);
        };
        request.onerror = () => reject(request.error);
      });
    });

    await page.goto('/offline');
    await expect(page.locator('#crosswake-study-status')).toContainText('Some saved answers need review.');
    const requests: string[] = [];
    page.on('request', request => {
      if (request.url().includes('/study/sync')) requests.push(request.url());
    });

    await page.evaluate(scopeRef => window.crosswakeOfflineStudy.activateScope(scopeRef), alphaScope);

    const betaScope = 'v1.scope_fixture_bravo_01';
    await expect(page.evaluate(scopeRef => window.crosswakeOfflineStudy.recoverLegacyMutations(scopeRef), alphaScope))
      .resolves.toBe('recovery_required');
    await page.evaluate(() => window.crosswakeOfflineStudy.fenceScope());
    await page.evaluate(scopeRef => window.crosswakeOfflineStudy.activateScope(scopeRef), betaScope);
    await expect(page.evaluate(scopeRef => window.crosswakeOfflineStudy.recoverLegacyMutations(scopeRef), betaScope))
      .resolves.toBe('recovery_required');

    const partitions = await page.evaluate(async ({ alphaScope, betaScope }) => {
      const database = await new Promise<IDBDatabase>((resolve, reject) => {
        const request = indexedDB.open('crosswake_offline_study');
        request.onsuccess = () => resolve(request.result);
        request.onerror = () => reject(request.error);
      });
      const tx = database.transaction(['legacy_mutations_quarantine', 'scoped_mutations'], 'readonly');
      const quarantine = await new Promise<number>((resolve, reject) => {
        const request = tx.objectStore('legacy_mutations_quarantine').count();
        request.onsuccess = () => resolve(request.result);
        request.onerror = () => reject(request.error);
      });
      const scoped = await Promise.all([alphaScope, betaScope].map(candidate => new Promise<number>((resolve, reject) => {
        const request = tx.objectStore('scoped_mutations').index('by_scope').count(candidate);
        request.onsuccess = () => resolve(request.result);
        request.onerror = () => reject(request.error);
      })));
      database.close();
      return [quarantine, scoped];
    }, { alphaScope, betaScope });
    expect(partitions).toEqual([1, [0, 0]]);
    expect(requests).toEqual([]);
  });

  test('study status presents saved locally work without exposing replay mechanics', async ({ page, context }) => {
    await page.goto('/offline');
    await waitForInactiveLifecycle(page);
    await page.evaluate(scopeRef => window.crosswakeOfflineStudy.activateScope(scopeRef), alphaScope);
    await context.setOffline(true);
    await page.click('#btn-flip');
    await page.click('#btn-good');

    const status = page.locator('#crosswake-study-status');
    await expect(status).toContainText('Saved on this iPhone.');
    await expect(status).toContainText('It will sync when you’re back online.');
    await expect(status).toHaveAttribute('role', 'status');
    await expect(page.locator('#crosswake-review-saved-answers')).toHaveCount(0);
    await expect(status).not.toContainText(alphaScope);
    await expect(status).not.toContainText('Queued for replay');
  });

  test('study status shows active syncing only during replay and preserves answer focus', async ({ page, context }) => {
    await page.goto('/offline');
    await waitForInactiveLifecycle(page);
    await page.evaluate(scopeRef => window.crosswakeOfflineStudy.activateScope(scopeRef), alphaScope);
    await page.evaluate(async scopeRef => {
      const database = await new Promise<IDBDatabase>((resolve, reject) => {
        const request = indexedDB.open('crosswake_offline_study');
        request.onsuccess = () => resolve(request.result);
        request.onerror = () => reject(request.error);
      });
      await new Promise<void>((resolve, reject) => {
        const transaction = database.transaction('scoped_mutations', 'readwrite');
        transaction.objectStore('scoped_mutations').add({
          scope_ref: scopeRef,
          local_ref: '00000000-0000-4000-8000-000000000005',
          client_mutation_id: '00000000-0000-4000-8000-000000000005',
          card_id: 1,
          rating: 'good',
        });
        transaction.oncomplete = () => { database.close(); resolve(); };
        transaction.onerror = () => reject(transaction.error);
      });
    }, alphaScope);
    await page.click('#btn-flip');
    await page.locator('#btn-good').focus();

    await page.evaluate(() => {
      window.fetch = () => new Promise(() => {});
      document.getElementById('btn-good')?.focus();
      window.dispatchEvent(new Event('online'));
    });

    await expect(page.locator('#crosswake-study-status')).toContainText('Syncing saved answers…');
    await expect(page.locator('#crosswake-study-status-indicator')).toHaveAttribute('aria-label', 'Syncing saved answers');
    await expect(page.locator('#btn-good')).toBeFocused();
  });

  test('study status retains rejected work and exposes recovery only through a validated host destination', async ({ page, context }) => {
    await page.goto('/offline');
    await waitForInactiveLifecycle(page);
    await page.evaluate(scopeRef => window.crosswakeOfflineStudy.activateScope(scopeRef), alphaScope);
    await context.setOffline(true);
    await page.click('#btn-flip');
    await page.click('#btn-good');
    await context.setOffline(false);
    await page.evaluate(() => {
      window.fetch = async () => new Response(JSON.stringify({ data: {
        accepted_records: [], rejected: [{ class: 'sigra_denied' }], halted: 'sigra_denied',
      } }), { status: 200, headers: { 'Content-Type': 'application/json' } });
      window.dispatchEvent(new Event('online'));
    });

    await expect(page.locator('#crosswake-study-status')).toContainText('Some saved answers need review.');
    expect(await readQueuedOfflineMutations(page, { scopeRef: alphaScope })).toHaveLength(1);
    await expect(page.locator('#crosswake-review-saved-answers')).toHaveCount(0);

    await page.locator('body').evaluate(body => { body.dataset.recoveryDestination = '/saved-answers'; });
    await page.evaluate(() => window.crosswakeOfflineStudy.refreshStudyStatus());
    const review = page.locator('#crosswake-review-saved-answers');
    await expect(review).toHaveText('Review saved answers');
    await expect(review).toBeVisible();
    await expect(review).toBeEnabled();
  });

  test('study status pauses fenced and disabled work without retry or destructive actions', async ({ page, context }) => {
    await page.goto('/offline');
    await waitForInactiveLifecycle(page);
    await page.evaluate(scopeRef => window.crosswakeOfflineStudy.activateScope(scopeRef), alphaScope);
    await context.setOffline(true);
    await page.click('#btn-flip');
    await page.click('#btn-good');
    await page.evaluate(() => window.crosswakeOfflineStudy.fenceScope());

    await expect(page.locator('#crosswake-study-status')).toContainText('Your saved answers remain on this iPhone.');
    await expect(page.locator('#crosswake-study-status')).not.toContainText('retry');
    await expect(page.locator('#crosswake-study-status')).not.toContainText('account');
    await expect(page.locator('#crosswake-study-status')).not.toContainText('scope');
    await expect(page.locator('#crosswake-review-saved-answers')).toHaveCount(0);
  });
});
