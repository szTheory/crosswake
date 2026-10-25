import { test, expect } from '@playwright/test';
import {
  assertAppGeneratedMutation,
  expectOutboxEmpty,
  expectSyncedReview,
  readQueuedOfflineMutations,
  resetOfflineStudyDatabase,
} from './support/offline_route_proof';

// D-21: no screenshot, video or trace capture, ever, for this corpus.
test.use({ screenshot: 'off', video: 'off', trace: 'off' });

test.describe('Crosswake offline island: card rating queues in IndexedDB, reconnect flushes via app code, Ecto confirms exactly one review row', () => {
  const alphaScope = 'v1.scope_fixture_alpha_01';

  async function waitForInactiveLifecycle(page) {
    await expect.poll(() => page.locator('#crosswake-study-status').textContent()).toContain('Your saved answers remain on this iPhone.');
    // The server markup already carries the paused copy with a placeholder icon; wait for the script's render.
    await expect(page.locator('#crosswake-study-status-icon')).toHaveText('Ⅱ');
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
    const syncResponse = page.waitForResponse(r => r.url().includes('/study/sync') && r.status() === 200);
    // page.dispatchEvent cannot target window — use page.evaluate exclusively (E2E-03c)
    await page.evaluate(() => window.dispatchEvent(new Event('online'))); // OBSERVATION_ONLY (env simulation)
    // D-03b: deterministic reconnect assertion — confirm app reacted before polling Ecto
    await syncResponse;

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
    await page.evaluate(() => {
      (window as any).__immediateOnlineFailure = { readonlyCalls: 0, storageFailures: 0, rejections: 0 };
      const transaction = IDBDatabase.prototype.transaction;
      IDBDatabase.prototype.transaction = function (...args) {
        if (args[0] === 'scoped_mutations' && args[1] === 'readonly') {
          const failure = (window as any).__immediateOnlineFailure;
          failure.readonlyCalls += 1;
          if (failure.readonlyCalls === 2) {
            failure.storageFailures += 1;
            throw new Error('worker storage failure');
          }
        }
        return transaction.apply(this, args as any);
      };
      window.addEventListener('unhandledrejection', event => {
        (window as any).__immediateOnlineFailure.rejections += 1;
        event.preventDefault();
      });
    });
    await page.evaluate(scopeRef => window.crosswakeOfflineStudy.activateScope(scopeRef), alphaScope);

    // Scope activation performs the first, empty outbox read. Wait for it so the
    // injected second read belongs to the replay triggered by this mutation,
    // rather than to this test's later observation of IndexedDB.
    await expect.poll(async () => page.evaluate(() => (window as any).__immediateOnlineFailure.readonlyCalls)).toBe(1);

    await page.click('#btn-flip');
    await page.click('#btn-good');

    await expect(page.locator('#crosswake-study-status')).toContainText('Your saved answers remain on this iPhone.');
    await expect.poll(async () => page.evaluate(() => (window as any).__immediateOnlineFailure.storageFailures)).toBe(1);
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

  test('study status retains rejected work and exposes recovery only through a server-approved route capability', async ({ page, context }) => {
    await page.goto('/offline');
    await waitForInactiveLifecycle(page);
    await page.evaluate(scopeRef => window.crosswakeOfflineStudy.activateScope(scopeRef), alphaScope);
    await context.setOffline(true);
    await page.click('#btn-flip');
    await page.click('#btn-good');
    await expect.poll(async () => (
      await readQueuedOfflineMutations(page, { scopeRef: alphaScope })
    ).length).toBe(1);
    await page.evaluate(() => {
      window.fetch = async () => new Response(JSON.stringify({ data: {
        accepted_records: [], rejected: [{ class: 'sigra_denied' }], halted: 'sigra_denied',
      } }), { status: 200, headers: { 'Content-Type': 'application/json' } });
    });
    await context.setOffline(false);
    await page.evaluate(() => window.dispatchEvent(new Event('online')));

    await expect(page.locator('#crosswake-study-status')).toContainText('Some saved answers need review.');
    expect(await readQueuedOfflineMutations(page, { scopeRef: alphaScope })).toHaveLength(1);
    await expect(page.locator('#crosswake-review-saved-answers')).toHaveCount(0);

    for (const destination of [
      '/saved-answers',
      'https://example.test/saved-answers',
      '//example.test/saved-answers',
      '://malformed',
      '/offline',
    ]) {
      await page.locator('body').evaluate((body, value) => { body.dataset.recoveryDestination = value; }, destination);
      await page.evaluate(() => window.crosswakeOfflineStudy.refreshStudyStatus());
      await expect(page.locator('#crosswake-review-saved-answers')).toHaveCount(0);
    }

    expect(await readQueuedOfflineMutations(page, { scopeRef: alphaScope })).toHaveLength(1);
    await expect(page.locator('#crosswake-study-status')).toContainText('Some saved answers need review.');
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

  test('study status emits one combined announcement for each changed lifecycle state', async ({ page, context }) => {
    await page.goto('/offline');
    await waitForInactiveLifecycle(page);
    await page.evaluate(scopeRef => window.crosswakeOfflineStudy.activateScope(scopeRef), alphaScope);
    await page.evaluate(() => {
      (window as any).__studyStatusEffects = [];
      document.addEventListener('crosswake:study-status-announcement', (event: Event) => {
        const detail = (event as CustomEvent).detail;
        (window as any).__studyStatusEffects.push({ state: detail.state, preserveFocus: detail.preserveFocus });
      });
    });
    await context.setOffline(true);
    await page.click('#btn-flip');
    await page.click('#btn-good');
    await expect.poll(() => page.evaluate(() => (window as any).__studyStatusEffects.length)).toBe(1);
    const effects = await page.evaluate(() => (window as any).__studyStatusEffects);

    expect(effects).toEqual([{ state: 'saved_locally', preserveFocus: true }]);
  });

  // ---- Phase 180 plan 04: free-form entry, audio action and durable-state copy (D-10, D-23) ----

  async function readOnlyQueuedId(page): Promise<string> {
    return page.evaluate(() => new Promise<string>((resolve, reject) => {
      const open = indexedDB.open('crosswake_offline_study');
      open.onsuccess = () => {
        const database = open.result;
        const request = database.transaction('scoped_mutations', 'readonly').objectStore('scoped_mutations').getAll();
        request.onsuccess = () => { database.close(); resolve(request.result[0].client_mutation_id); };
        request.onerror = () => reject(request.error);
      };
      open.onerror = () => reject(open.error);
    }));
  }

  test('free-form answer commits to the same outbox and reports saved on this device', async ({ page, context }) => {
    await page.goto('/offline');
    await waitForInactiveLifecycle(page);
    await page.evaluate(scopeRef => window.crosswakeOfflineStudy.activateScope(scopeRef), alphaScope);
    await context.setOffline(true);

    await page.getByRole('textbox', { name: 'Your answer' }).fill('synthetic free-form answer');
    await page.getByRole('button', { name: 'Save answer' }).click();

    const status = page.locator('#crosswake-study-status');
    await expect(status).toContainText('Saved on this device');
    await expect(status).toHaveAttribute('data-island-state', 'saved_local');
    await expect(page.getByRole('textbox', { name: 'Your answer' })).toHaveValue('');
    expect(await page.evaluate(() => (window as any).crosswakeIsland.outboxCounts())).toEqual({
      selected: 0,
      free_form: 1,
      active_scope_total: 1,
      retained_total: 1,
    });
    const queued = await readQueuedOfflineMutations(page);
    expect(queued).toHaveLength(1);
    assertAppGeneratedMutation(queued[0]);
  });

  test('free-form answer copy follows durable state through waiting, sending and saved to account', async ({ page, context }) => {
    await page.goto('/offline');
    await waitForInactiveLifecycle(page);
    await page.evaluate(scopeRef => window.crosswakeOfflineStudy.activateScope(scopeRef), alphaScope);
    await context.setOffline(true);
    await page.getByRole('textbox', { name: 'Your answer' }).fill('synthetic replay answer');
    await page.getByRole('button', { name: 'Save answer' }).click();
    const status = page.locator('#crosswake-study-status');
    await expect(status).toHaveAttribute('data-island-state', 'saved_local');

    // Waiting to send: queued work with no connection, reported after the offline signal.
    await page.evaluate(() => window.dispatchEvent(new Event('offline')));
    await expect(status).toHaveAttribute('data-island-state', 'waiting');
    await expect(status).toContainText('Waiting to send');

    const capturedId = await readOnlyQueuedId(page);
    await page.evaluate(() => {
      (window as any).__islandStates = [];
      new MutationObserver(() => {
        (window as any).__islandStates.push(document.getElementById('crosswake-study-status')?.dataset.islandState);
      }).observe(document.getElementById('crosswake-study-status')!, { attributes: true, attributeFilter: ['data-island-state'] });
    });
    await context.setOffline(false);
    const syncResponse = page.waitForResponse(r => r.url().includes('/study/sync') && r.status() === 200);
    await page.evaluate(() => window.dispatchEvent(new Event('online')));
    await syncResponse;

    await expectSyncedReview(page.request, capturedId);
    await expect(status).toHaveAttribute('data-island-state', 'saved_account');
    await expect(status).toContainText('Saved to your account');
    const states = await page.evaluate(() => (window as any).__islandStates as string[]);
    expect(states).toContain('sending');
    expect(states.indexOf('sending')).toBeLessThan(states.lastIndexOf('saved_account'));
    await expectOutboxEmpty(page);
    expect(await page.evaluate(() => (window as any).crosswakeIsland.outboxCounts())).toMatchObject({ active_scope_total: 0 });
  });

  test('empty or oversized free-form answers are not queued and the island exposes only closed state values', async ({ page, context }) => {
    await page.goto('/offline');
    await waitForInactiveLifecycle(page);
    await page.evaluate(scopeRef => window.crosswakeOfflineStudy.activateScope(scopeRef), alphaScope);
    await context.setOffline(true);

    await page.getByRole('button', { name: 'Save answer' }).click();
    await expect(page.locator('#study-answer-message')).toHaveText('Type your answer first.');
    await page.getByRole('textbox', { name: 'Your answer' }).fill('é'.repeat(2100));
    await page.getByRole('button', { name: 'Save answer' }).click();
    await expect(page.locator('#study-answer-message')).toHaveText('That answer is too long to save.');
    expect(await page.evaluate(() => (window as any).crosswakeIsland.outboxCounts())).toMatchObject({ active_scope_total: 0 });

    const closed = ['saved_local', 'waiting', 'sending', 'saved_account', 'needs_review', 'unavailable', 'audio_unavailable', 'fenced', 'entry_disabled'];
    expect(closed).toContain(await page.locator('#crosswake-study-status').getAttribute('data-island-state'));
    const counts = await page.evaluate(() => (window as any).crosswakeIsland.outboxCounts());
    expect(Object.values(counts).every(value => Number.isInteger(value))).toBe(true);
    expect(Object.keys(counts).sort()).toEqual(['active_scope_total', 'free_form', 'retained_total', 'selected']);
  });

  test('play pronunciation is unavailable without a bridge and sends nothing', async ({ page }) => {
    await page.goto('/offline');
    await waitForInactiveLifecycle(page);
    const button = page.getByRole('button', { name: 'Play pronunciation' });
    await expect(button).toHaveAttribute('aria-disabled', 'true');
    await expect(page.locator('#study-audio-state')).toHaveText('Audio unavailable');
    // Playwright treats aria-disabled as not actionable; force the click to prove it is inert.
    await button.click({ force: true });
    await expect(page.locator('#study-audio-state')).toHaveText('Audio unavailable');
  });

  test('play pronunciation sends one typed request only when advertised and maps replies to learner copy', async ({ page }) => {
    await page.addInitScript(() => {
      const requests: unknown[] = [];
      (window as any).__audioRequests = requests;
      (window as any).crosswakeBridge = {
        capabilities: { 'host.study.audio.play': '1.0.0' },
        postMessage(raw: string) { requests.push(JSON.parse(raw)); },
      };
    });
    await page.goto('/offline');
    await waitForInactiveLifecycle(page);
    const button = page.getByRole('button', { name: 'Play pronunciation' });
    await expect(button).toHaveAttribute('aria-disabled', 'false');

    await button.click();
    const requests = await page.evaluate(() => (window as any).__audioRequests as any[]);
    expect(requests).toHaveLength(1);
    expect(requests[0].command).toBe('host.study.audio.play');
    expect(requests[0].capability).toBe('host.study.audio.play');
    expect(Object.keys(requests[0].payload).sort()).toEqual(['asset_key', 'correlation_id']);
    expect(requests[0].payload.correlation_id).toBe(requests[0].correlation_id);
    expect(JSON.stringify(requests[0].payload)).not.toMatch(/https?:|file:|\.aiff|\//);

    // A reply for a different correlation id is ignored.
    await page.evaluate(() => (window as any).crosswakeBridge.__reply({ correlation_id: 'other', status: 'ok' }));
    await expect(page.locator('#study-audio-state')).toHaveText('Starting pronunciation');

    await page.evaluate(id => (window as any).crosswakeBridge.__reply({ correlation_id: id, status: 'ok' }), requests[0].correlation_id);
    await expect(page.locator('#study-audio-state')).toHaveText('Playing pronunciation');

    await button.click();
    const second = await page.evaluate(() => (window as any).__audioRequests as any[]);
    expect(second).toHaveLength(2);
    await page.evaluate(id => (window as any).crosswakeBridge.__reply({ correlation_id: id, status: 'deny' }), second[1].correlation_id);
    await expect(page.locator('#study-audio-state')).toHaveText('Audio unavailable');
    await expect(page.locator('#crosswake-study-status')).toHaveAttribute('data-island-state', 'audio_unavailable');
  });

  test('saving a free-form answer keeps focus on the control the learner used', async ({ page, context }) => {
    await page.goto('/offline');
    await waitForInactiveLifecycle(page);
    await page.evaluate(scopeRef => window.crosswakeOfflineStudy.activateScope(scopeRef), alphaScope);
    await context.setOffline(true);
    await page.getByRole('textbox', { name: 'Your answer' }).fill('synthetic focus answer');
    await page.getByRole('button', { name: 'Save answer' }).focus();
    await page.keyboard.press('Enter');
    await expect(page.locator('#crosswake-study-status')).toContainText('Saved on this device');
    await expect(page.getByRole('button', { name: 'Save answer' })).toBeFocused();
  });
});
