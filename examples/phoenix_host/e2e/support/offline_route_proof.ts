import { expect, type APIRequestContext, type BrowserContext, type Page } from '@playwright/test';
import { mkdirSync, readFileSync } from 'node:fs';
import path from 'node:path';

const DEFAULT_OFFLINE_STUDY_DB = 'crosswake_offline_study';
const ROUTER_PATH = path.join(process.cwd(), 'lib', 'crosswake_example', 'router.ex');
const OPAQUE_MUTATION_ID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/;
const MUTATION_ID_ERROR = 'PL-BROWSER-MUTATION-ID';

export type OfflineMutationRecord = {
  id?: number;
  client_mutation_id: string;
  card_id: number;
  rating: string;
};

export type OfflineRouteProofOptions = {
  databaseName?: string;
  scopeRef?: string;
};

export type LearnLoopRouteProofOptions = OfflineRouteProofOptions & {
  captureScreenshots?: boolean;
  screenshotDir?: string;
};

export type OfflineIslandProofConfig = {
  databaseName: string;
  storeName: string;
  mutationIdPath: string;
};

export type OfflineIslandProofAdapter = {
  navigate(): Promise<void>;
  performMutation(): Promise<void>;
  readQueuedRecord(): Promise<unknown>;
  reconnect(): Promise<void>;
  assertBackendConfirmation(mutationId: string): Promise<void>;
  assertOutboxEmpty(): Promise<void>;
  assertDuplicateIdempotency(mutationId: string, record: unknown): Promise<void>;
};

export async function runOfflineIslandProof(
  _page: Page,
  context: BrowserContext,
  adapter: OfflineIslandProofAdapter,
  config: OfflineIslandProofConfig,
): Promise<string> {
  await adapter.navigate();
  await context.setOffline(true);
  let record: unknown;
  let mutationId: string;

  try {
    await adapter.performMutation();
    record = await adapter.readQueuedRecord();
    mutationId = extractMutationId(record, config.mutationIdPath);
  } finally {
    await context.setOffline(false);
  }

  await adapter.reconnect();
  await adapter.assertBackendConfirmation(mutationId!);
  await adapter.assertOutboxEmpty();
  await adapter.assertDuplicateIdempotency(mutationId!, record!);
  return mutationId!;
}

export function extractMutationId(record: unknown, fieldPath: string): string {
  const value = fieldPath.split('.').reduce<unknown>((current, field) => {
    if (current && typeof current === 'object' && field in current) {
      return (current as Record<string, unknown>)[field];
    }

    return undefined;
  }, record);

  if (typeof value !== 'string' || !OPAQUE_MUTATION_ID.test(value)) {
    throw new Error(MUTATION_ID_ERROR);
  }

  return value;
}

export async function proveLearnLoopRoute(
  page: Page,
  context: BrowserContext,
  options: LearnLoopRouteProofOptions = {},
) {
  const captureScreenshots = options.captureScreenshots ?? true;

  await resetOfflineStudyDatabase(page, options);

  const reset = await page.request.post('/_e2e/showcase-reset');
  expect(reset.ok(), learnloopProofMessage('showcase-reset', 'deterministic LearnLoop reset')).toBe(true);
  const resetBody = await reset.json();
  expect(
    resetBody.browser_state_reset,
    learnloopProofMessage('showcase-reset', 'browser-owned IndexedDB is not server-reset'),
  ).toBe(false);

  const router = readFileSync(ROUTER_PATH, 'utf8');
  expect(router, learnloopProofMessage('learnloop-dashboard', 'live_view route')).toContain('id: "learnloop-dashboard"');
  expect(router, learnloopProofMessage('learnloop-course', 'live_view route')).toContain('id: "learnloop-course"');
  expect(router, learnloopProofMessage('learnloop-pack', 'live_view route')).toContain('id: "learnloop-pack"');
  expect(router, learnloopProofMessage('learnloop-study-session', 'offline_island route')).toContain('id: "learnloop-study-session"');
  expect(router, learnloopProofMessage('learnloop-study-session', 'offline_island route')).toContain('runtime: :offline_island');
  expect(router, learnloopProofMessage('learnloop-study-session', 'content pack')).toContain('learnloop_daily_pack');
  expect(router, learnloopProofMessage('learnloop-history', 'live_view route')).toContain('id: "learnloop-history"');
  expect(router, learnloopProofMessage('learnloop-subscription', 'live_view route')).toContain('id: "learnloop-subscription"');

  await page.goto('/learnloop');
  await expect(page, learnloopProofMessage('learnloop-dashboard', 'browser title')).toHaveTitle(/LearnLoop|Crosswake/);
  await expectLiveViewConnected(page, 'learnloop-dashboard');
  await expect(
    page.getByRole('heading', { name: /Iris learner path/i }),
    learnloopProofMessage('learnloop-dashboard', 'product-first page heading'),
  ).toBeVisible();
  await expect(
    page.getByRole('heading', { name: 'Iris Learner', exact: true }),
    learnloopProofMessage('learnloop-dashboard', 'learner momentum first'),
  ).toBeVisible();
  await expect(page.locator('body'), learnloopProofMessage('learnloop-dashboard', 'learner-first product shell')).toContainText(
    /Brightpath Academy|course-elixir-routing|learnloop_daily_pack|course progress/i,
  );
  await expect(page.locator('body'), learnloopProofMessage('learnloop-dashboard', 'route support labels')).toContainText(
    /LiveView route|Cached read-only|Offline island|Local-first outbox/i,
  );
  await expect(page.locator('body'), learnloopProofMessage('learnloop-dashboard', 'entitlement and commerce pressure')).toContainText(
    /Backend projection|Mocked storefront evidence/i,
  );
  await expectNoUnsupportedLearnLoopClaims(page, 'learnloop-dashboard');
  await expectNoHorizontalOverflow(page, 'learnloop-dashboard');
  await page.keyboard.press('Tab');
  await expectVisibleFocus(page, 'learnloop-dashboard');
  await captureLearnLoopScreenshot(page, options, captureScreenshots, 'learnloop-dashboard.png');

  await page.getByRole('link', { name: /Open course/i }).first().click();
  await expect(page, learnloopProofMessage('learnloop-course', 'course detail route')).toHaveURL(
    /\/learnloop\/courses\/course-elixir-routing$/,
  );
  await expectLiveViewConnected(page, 'learnloop-course');
  await expect(page.locator('body'), learnloopProofMessage('learnloop-course', 'gated lesson pressure')).toContainText(
    'Backend projection required',
  );
  await expect(page.locator('body'), learnloopProofMessage('learnloop-course', 'fail-closed access')).toContainText(
    'Access stays closed until backend projection refreshes',
  );
  await expectNoUnsupportedLearnLoopClaims(page, 'learnloop-course');
  await captureLearnLoopScreenshot(page, options, captureScreenshots, 'learnloop-course.png');

  await page.getByRole('link', { name: /Review access/i }).first().click();
  await expect(page, learnloopProofMessage('learnloop-subscription', 'subscription route')).toHaveURL(
    /\/learnloop\/subscription$/,
  );
  await expectLiveViewConnected(page, 'learnloop-subscription');
  await expect(page.locator('body'), learnloopProofMessage('learnloop-subscription', 'backend entitlement projection')).toContainText(
    'Backend projection required',
  );
  await expect(page.locator('body'), learnloopProofMessage('learnloop-subscription', 'mock storefront evidence')).toContainText(
    'Mock storefront evidence received',
  );
  await expect(page.locator('body'), learnloopProofMessage('learnloop-subscription', 'no live provider disclaimer')).toContainText(
    'No live StoreKit, Play Billing, or RevenueCat adapter in this demo',
  );
  await expect(page.locator('body'), learnloopProofMessage('learnloop-subscription', 'commerce pressure remains diagnostic')).toContainText(
    /deeper commerce|device or storefront evidence\s+never grants access/i,
  );
  await expectNoUnsupportedLearnLoopClaims(page, 'learnloop-subscription');
  await captureLearnLoopScreenshot(page, options, captureScreenshots, 'learnloop-subscription.png');

  await page.getByRole('link', { name: /^Pack$/ }).click();
  await expect(page, learnloopProofMessage('learnloop-pack', 'pack detail route')).toHaveURL(
    /\/learnloop\/packs\/learnloop_daily_pack$/,
  );
  await expectLiveViewConnected(page, 'learnloop-pack');
  await expect(page.locator('body'), learnloopProofMessage('learnloop-pack', 'content pack metadata')).toContainText(
    /learnloop_daily_pack|Daily Elixir Pack|Content pack/i,
  );
  await expect(page.locator('body'), learnloopProofMessage('learnloop-pack', 'offline handoff labels')).toContainText(
    /Offline island|Local-first outbox|Queued for replay/i,
  );
  await expect(page.locator('body'), learnloopProofMessage('learnloop-pack', 'native-storage pressure remains future')).toContainText(
    'native storage remains future capability-map pressure',
  );
  await expectNoUnsupportedLearnLoopClaims(page, 'learnloop-pack');
  await captureLearnLoopScreenshot(page, options, captureScreenshots, 'learnloop-pack.png');

  await page.getByRole('link', { name: /Start offline study/i }).first().click();
  await expect(page, learnloopProofMessage('learnloop-study-session', 'study route')).toHaveURL(
    /\/learnloop\/study\/session$/,
  );
  expect(await page.evaluate(() => !!window.liveSocket), learnloopProofMessage('learnloop-study-session', 'socketless island')).toBe(false);
  await expect(page.locator('[data-phx-main]'), learnloopProofMessage('learnloop-study-session', 'no LiveView root')).toHaveCount(0);
  await expect(page.locator('body'), learnloopProofMessage('learnloop-study-session', 'route id')).toHaveAttribute(
    'data-route-id',
    'learnloop-study-session',
  );
  await expect(page.locator('body'), learnloopProofMessage('learnloop-study-session', 'configured sync endpoint')).toHaveAttribute(
    'data-sync-endpoint',
    '/learnloop/sync',
  );
  await expect(page.locator('body'), learnloopProofMessage('learnloop-study-session', 'browser state owner')).toHaveAttribute(
    'data-browser-state-owner',
    'device',
  );
  await expect(page.locator('#flashcard-container'), learnloopProofMessage('learnloop-study-session', 'study cards')).toContainText(
    /Elixir|Loading flashcards/i,
  );
  await expect(page.locator('body'), learnloopProofMessage('learnloop-study-session', 'reset honesty')).toContainText(
    "Server reset does not clear this device's offline state",
  );

  const capturedId = await runOfflineIslandProof(page, context, {
    navigate: async () => undefined,
    performMutation: async () => {
      await page.click('#btn-flip');
      await page.click('#btn-good');
      await expect(page.locator('#status'), learnloopProofMessage('learnloop-study-session', 'queued status copy')).toContainText(
        /Saved locally|Queued for replay/i,
      );
    },
    readQueuedRecord: async () => {
      const mutations = await readQueuedOfflineMutations(page, options);
      expect(mutations, learnloopProofMessage('learnloop-study-session', 'one queued IndexedDB mutation')).toHaveLength(1);
      assertAppGeneratedMutation(mutations[0]);
      return mutations[0];
    },
    reconnect: async () => {
      const syncResponse = page.waitForResponse(response => response.url().includes('/learnloop/sync') && response.status() === 200);
      await page.evaluate(() => window.dispatchEvent(new Event('online')));
      await syncResponse;
      await expect(page.locator('#status'), learnloopProofMessage('learnloop-study-session', 'synced status copy')).toContainText(/Synced \d+ - queued 0/i);
    },
    assertBackendConfirmation: mutationId => expectSyncedReview(page.request, mutationId, 1),
    assertOutboxEmpty: () => expectOutboxEmpty(page, options),
    assertDuplicateIdempotency: async (mutationId, record) => {
      const mutation = record as OfflineMutationRecord;
      const duplicate = await page.request.post('/learnloop/sync', { data: { events: [{ client_mutation_id: mutationId, card_id: mutation.card_id, rating: mutation.rating }] } });
      expect(duplicate.ok(), learnloopProofMessage('learnloop-study-session', 'duplicate replay accepted as idempotent request')).toBe(true);
      const duplicateBody = await duplicate.json();
      expect(duplicateBody.data.accepted_count, learnloopProofMessage('learnloop-study-session', 'duplicate replay creates no second row')).toBe(0);
      await expectSyncedReview(page.request, mutationId, 1);
      await expectOutboxEmpty(page, options);
    },
  }, {
    databaseName: options.databaseName ?? DEFAULT_OFFLINE_STUDY_DB,
    storeName: 'mutations',
    mutationIdPath: 'client_mutation_id',
  });

  await page.goto('/learnloop/history');
  await expectLiveViewConnected(page, 'learnloop-history');
  await expect(page.locator('body'), learnloopProofMessage('learnloop-history', 'server-confirmed progress')).toContainText(
    /server-confirmed|Cached read-only|Synced/i,
  );
  await expect(page.locator('body'), learnloopProofMessage('learnloop-history', 'exact persisted row visible')).toContainText(capturedId);

  await openLearnLoopDiagnostics(page);
  await expect(page.locator('body'), learnloopProofMessage('learnloop-diagnostics', 'support truth')).toContainText(
    /Route policy diagnostics|learnloop-study-session|Support truth/i,
  );
  await expect(page.locator('body'), learnloopProofMessage('learnloop-diagnostics', 'capability-family guide visible')).toContainText(
    'Capability families',
  );
  await expectNoUnsupportedLearnLoopClaims(page, 'learnloop-diagnostics');
  await expectNoHorizontalOverflow(page, 'learnloop-history');
  await captureLearnLoopScreenshot(page, options, captureScreenshots, 'learnloop-history-diagnostics.png');
  await captureLearnLoopScreenshot(page, options, captureScreenshots, 'learnloop-route-tour.png');
}

export async function resetOfflineStudyDatabase(page: Page, options: OfflineRouteProofOptions = {}) {
  const databaseName = options.databaseName ?? DEFAULT_OFFLINE_STUDY_DB;

  await page.addInitScript((dbName: string) => {
    indexedDB.deleteDatabase(dbName);
  }, databaseName);
}

export async function readQueuedOfflineMutations(
  page: Page,
  options: OfflineRouteProofOptions = {},
): Promise<OfflineMutationRecord[]> {
  const databaseName = options.databaseName ?? DEFAULT_OFFLINE_STUDY_DB;
  const scopeRef = options.scopeRef ?? 'v1.scope_fixture_alpha_01';

  return page.evaluate(([dbName, expectedScope]: [string, string]) => {
    return new Promise((resolve, reject) => {
      const req = indexedDB.open(dbName, 3);
      req.onsuccess = () => {
        const db = req.result;
        const tx = db.transaction('mutations', 'readonly');
        const store = tx.objectStore('scoped_mutations');
        const getAll = store.index('by_scope').getAll(expectedScope);
        getAll.onsuccess = () => resolve(getAll.result);
        getAll.onerror = () => reject(getAll.error);
      };
      req.onerror = () => reject(req.error);
    });
  }, [databaseName, scopeRef]);
}

export async function expectSyncedReview(request: APIRequestContext, clientMutationId: string, expectedCount = 1) {
  await expect.poll(async () => {
    const res = await request.get(`/_e2e/sync-state/${clientMutationId}`);
    return res.ok() ? res.json() : { synced: false, count: -1 };
  }, {
    timeout: 8000,
    message: `offline-study Ecto row should reflect app-flushed mutation ${clientMutationId}`,
  }).toMatchObject({ synced: true, count: expectedCount });
}

export async function expectOutboxEmpty(page: Page, options: OfflineRouteProofOptions = {}) {
  const remaining = await readQueuedOfflineMutations(page, options);
  expect(remaining).toHaveLength(0);
}

export function assertAppGeneratedMutation(record: OfflineMutationRecord) {
  expect(typeof record.client_mutation_id).toBe('string');
  expect(record.client_mutation_id).toMatch(OPAQUE_MUTATION_ID);
  expect(record.rating).toMatch(/^(good|hard)$/);
}

async function openLearnLoopDiagnostics(page: Page) {
  const summary = page.locator('.learnloop-diagnostics summary').first();
  if (await summary.count()) {
    await summary.click();
  }
}

async function captureLearnLoopScreenshot(
  page: Page,
  options: LearnLoopRouteProofOptions,
  captureScreenshots: boolean,
  filename: string,
) {
  if (!captureScreenshots || !options.screenshotDir) {
    return;
  }

  mkdirSync(options.screenshotDir, { recursive: true });
  await page.screenshot({ path: path.join(options.screenshotDir, filename), fullPage: true });
}

async function expectLiveViewConnected(page: Page, routeId: string) {
  await expect(
    page.locator('[data-phx-main]').first(),
    learnloopProofMessage(routeId, 'LiveView connected before server event'),
  ).toHaveClass(/phx-connected/);
}

async function expectNoHorizontalOverflow(page: Page, routeId: string) {
  const metrics = await page.evaluate(() => ({
    clientWidth: document.documentElement.clientWidth,
    scrollWidth: document.documentElement.scrollWidth,
    bodyScrollWidth: document.body.scrollWidth,
  }));
  expect(
    Math.max(metrics.scrollWidth, metrics.bodyScrollWidth),
    learnloopProofMessage(routeId, 'viewport containment'),
  ).toBeLessThanOrEqual(metrics.clientWidth + 1);
}

async function expectVisibleFocus(page: Page, routeId: string) {
  const focus = await page.evaluate(() => {
    const active = document.activeElement;
    const style = window.getComputedStyle(active!);

    return {
      text: active?.textContent?.trim(),
      outlineStyle: style.outlineStyle,
      outlineWidth: Number.parseFloat(style.outlineWidth),
    };
  });

  expect(focus.text, learnloopProofMessage(routeId, 'keyboard focus target')).toBeTruthy();
  expect(focus.outlineStyle, learnloopProofMessage(routeId, 'keyboard focus outline')).not.toBe('none');
  expect(focus.outlineWidth, learnloopProofMessage(routeId, 'keyboard focus outline')).toBeGreaterThan(0);
}

async function expectNoUnsupportedLearnLoopClaims(page: Page, routeId: string) {
  await expect(
    page.locator('body'),
    learnloopProofMessage(routeId, 'unsupported claims absent'),
  ).not.toContainText(
    /LiveView works offline|background sync|server reset cleared offline state|native storage shipped|native storage support|generic sync engine|generic sync helper|live storefront support|StoreKit support shipped|Play Billing support shipped|RevenueCat support shipped|purchase succeeded|subscription verified on device|storefront support shipped|device-local entitlement authority/i,
  );
}

function learnloopProofMessage(routeId: string, assertion: string) {
  return `LearnLoop route-tour semantic assertion failed for route id ${routeId} (${assertion}); screenshots are collateral after this assertion passes`;
}
