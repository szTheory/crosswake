import { test, expect, type BrowserContext, type Page } from '@playwright/test';
import { mkdirSync, readFileSync } from 'node:fs';
import path from 'node:path';
import {
  assertAppGeneratedMutation,
  expectOutboxEmpty,
  expectSyncedReview,
  readQueuedOfflineMutations,
  resetOfflineStudyDatabase,
} from './support/offline_route_proof';
import { writeRouteTourEvidenceManifest } from './support/evidence_manifest';

const screenshotDir = path.join(process.cwd(), 'playwright-artifacts', 'route-tour');
const routeTourScreenshotDir = path.join(screenshotDir, 'screenshots');
const routerPath = path.join(process.cwd(), 'lib', 'crosswake_example', 'router.ex');
const routeTourCommand = 'npx playwright test e2e/route_tour.spec.ts';

test.describe('Crosswake route-owner browser tour', () => {
  test.beforeEach(async ({ page }) => {
    await resetOfflineStudyDatabase(page);
  });

  test('proves LiveView, bounded bridge, offline island, and native-owned fallback route semantics before screenshots', async ({ page, context }) => {
    mkdirSync(routeTourScreenshotDir, { recursive: true });

    await proveShowcaseHub(page);

    await proveLibraryRoute(page);
    await captureRouteScreenshot(page, 'library.png');

    await proveBridgeRoute(page);
    await captureRouteScreenshot(page, 'bridge-proof.png');

    await proveOfflineRoute(page, context);
    await captureRouteScreenshot(page, 'offline-study-replayed.png');

    await proveNativeOwnedRoute(page);
    await captureRouteScreenshot(page, 'selective-native-claim-capture-unavailable.png');

    writeRouteTourEvidenceManifest(screenshotDir, routeTourCommand);
  });

  test('keeps the showcase hub readable in mobile dark reduced-motion mode', async ({ page }) => {
    mkdirSync(routeTourScreenshotDir, { recursive: true });

    await page.setViewportSize({ width: 390, height: 844 });
    await page.emulateMedia({ colorScheme: 'dark', reducedMotion: 'reduce' });
    await proveShowcaseHub(page);
    await expectNoHorizontalOverflow(page, 'showcase-hub');

    await page.keyboard.press('Tab');
    await expectVisibleFocus(page, 'showcase-hub');

    await captureRouteScreenshot(page, 'showcase-mobile-dark-reduced.png');
  });
});

async function proveShowcaseHub(page: Page) {
  await page.goto('/');

  await expect(
    page.getByRole('heading', { name: /Phoenix routes, native where it matters\./ }),
    ownerMessage('showcase-hub', 'live_view showcase'),
  ).toBeVisible();

  await expect(page.getByRole('heading', { name: 'SaaS/Admin' }), ownerMessage('showcase-hub', 'saas lane')).toBeVisible();
  await expect(page.getByRole('heading', { name: 'Field Service' }), ownerMessage('showcase-hub', 'field-service lane')).toBeVisible();
  await expect(page.getByRole('heading', { name: 'Learning/Training' }), ownerMessage('showcase-hub', 'learning lane')).toBeVisible();

  const body = page.locator('body');
  await expect(body, ownerMessage('showcase-hub', 'cached read-only support label')).toContainText('Cached read-only');
  await expect(body, ownerMessage('showcase-hub', 'demo pressure support label')).toContainText('Demo pressure');
  await expect(body, ownerMessage('showcase-hub', 'future native-control support label')).toContainText('Future native-control candidate');
  await expect(body, ownerMessage('showcase-hub', 'proof routes secondary')).toContainText('Proof routes stay one click deeper');
  await expect(body, ownerMessage('showcase-hub', 'route-owner semantics before screenshots')).toContainText('route-owner semantics');
  await expect(body, ownerMessage('showcase-hub', 'showcase before proof')).toContainText('after the showcase explains the product shape');

  const router = readFileSync(routerPath, 'utf8');
  expect(router, ownerMessage('showcase-hub', 'root live_view route')).toContain('id: "showcase-hub"');
  expect(router, ownerMessage('showcase-hub', 'root live_view route')).toContain('live("/", CrosswakeExample.Showcase.HubLive');
}

async function proveLibraryRoute(page: Page) {
  await page.goto('/library');

  await expect(page.locator('body'), ownerMessage('library', 'live_view')).toContainText('lesson library');

  const router = readFileSync(routerPath, 'utf8');
  expect(router, ownerMessage('library', 'live_view')).toContain('id: "library"');
  expect(router, ownerMessage('library', 'live_view')).toContain('live("/library"');
  expect(routeTourCommand).toContain('route_tour.spec.ts');
}

async function proveBridgeRoute(page: Page) {
  await page.goto('/bridge-proof');

  await expect(page.getByRole('heading', { name: 'Bridge Proof' }), ownerMessage('bridge-proof', 'live_view + bounded bridge')).toBeVisible();
  await page.getByRole('button', { name: 'Share' }).click();
  await expect(page.locator('#crosswake-bridge-payload'), ownerMessage('bridge-proof', 'bounded bridge')).not.toHaveAttribute('hidden', '');

  const payload = await bridgePayload(page);
  expect(payload.command, ownerMessage('bridge-proof', 'bounded bridge')).toBe('share.invoke');
  expect(payload.capability, ownerMessage('bridge-proof', 'bounded bridge')).toBe('share');
  expect(payload.route_id, ownerMessage('bridge-proof', 'bounded bridge')).toBe('bridge-proof');
  expect(payload.active_route_id, ownerMessage('bridge-proof', 'bounded bridge')).toBe('bridge-proof');
  expect(payload.protocol, ownerMessage('bridge-proof', 'bounded bridge')).toBe('crosswake.bridge');
  expect(payload.version, ownerMessage('bridge-proof', 'bounded bridge')).toBe('1.0.0');
  expect(payload.origin, ownerMessage('bridge-proof', 'bounded bridge')).toBe('https://example.crosswake.invalid');
  expect(payload.correlation_id, ownerMessage('bridge-proof', 'bounded bridge')).toMatch(/^share-\d+$/);
}

async function proveOfflineRoute(page: Page, context: BrowserContext) {
  await page.goto('/offline');

  expect(await page.evaluate(() => !!window.liveSocket), ownerMessage('offline-study', 'offline_island')).toBe(false);
  await expect(page.locator('#flashcard-container'), ownerMessage('offline-study', 'offline_island')).toContainText('Elixir');

  await context.setOffline(true);
  await page.click('#btn-flip');
  await page.click('#btn-good');

  const mutations = await readQueuedOfflineMutations(page);
  expect(mutations, ownerMessage('offline-study', 'offline_island')).toHaveLength(1);
  assertAppGeneratedMutation(mutations[0]);
  expect(mutations[0].rating, ownerMessage('offline-study', 'offline_island')).toBe('good');

  await context.setOffline(false);
  await page.evaluate(() => window.dispatchEvent(new Event('online')));
  await page.waitForResponse(response => response.url().includes('/study/sync') && response.status() === 200);

  await expectSyncedReview(page.request, mutations[0].client_mutation_id);
  await expectOutboxEmpty(page);

  const duplicate = await page.request.post('/study/sync', {
    data: {
      events: [{
        client_mutation_id: mutations[0].client_mutation_id,
        card_id: mutations[0].card_id,
        rating: mutations[0].rating,
      }],
    },
  });
  expect(duplicate.ok(), ownerMessage('offline-study', 'offline_island')).toBe(true);
  const body = await duplicate.json();
  expect(body.data.accepted_count, ownerMessage('offline-study', 'offline_island')).toBe(0);
  await expectSyncedReview(page.request, mutations[0].client_mutation_id);
}

async function proveNativeOwnedRoute(page: Page) {
  const claimId = await createNativeRouteTourClaim(page);
  await page.goto(`/native/claims/${claimId}/capture`);

  await expect(page.getByRole('heading', { name: /Capture Evidence for Route Tour Claim/ }), ownerMessage('selective-native-claim-capture', 'native_screen')).toBeVisible();
  await expect(page.locator('.native-capture-fallback'), ownerMessage('selective-native-claim-capture', 'native_screen')).toContainText('Please use the native mobile application to capture media.');

  const router = readFileSync(routerPath, 'utf8');
  expect(router, ownerMessage('selective-native-claim-capture', 'native_screen')).toContain('id: "selective-native-claim-capture"');
  expect(router, ownerMessage('selective-native-claim-capture', 'native_screen')).toContain('runtime: :native_screen');
  expect(router, ownerMessage('selective-native-claim-capture', 'native_screen')).toContain('capabilities: [:camera]');
}

async function captureRouteScreenshot(page: Page, filename: string) {
  await page.screenshot({ path: path.join(routeTourScreenshotDir, filename), fullPage: true });
}

async function expectNoHorizontalOverflow(page: Page, routeId: string) {
  const metrics = await page.evaluate(() => ({
    clientWidth: document.documentElement.clientWidth,
    scrollWidth: document.documentElement.scrollWidth,
    bodyScrollWidth: document.body.scrollWidth,
  }));
  expect(
    Math.max(metrics.scrollWidth, metrics.bodyScrollWidth),
    ownerMessage(routeId, 'mobile viewport containment'),
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

  expect(focus.text, ownerMessage(routeId, 'keyboard focus target')).toContain('Explore Showcase');
  expect(focus.outlineStyle, ownerMessage(routeId, 'keyboard focus outline')).not.toBe('none');
  expect(focus.outlineWidth, ownerMessage(routeId, 'keyboard focus outline')).toBeGreaterThan(0);
}

async function bridgePayload(page: Page) {
  const payload = page.locator('#crosswake-bridge-payload');
  await expect(payload, ownerMessage('bridge-proof', 'bounded bridge')).toHaveCount(1);
  const text = await payload.textContent();
  expect(text, ownerMessage('bridge-proof', 'bounded bridge')).toBeTruthy();
  return JSON.parse(text!);
}

async function createNativeRouteTourClaim(page: Page) {
  const response = await page.request.post('/_e2e/native-claim', {
    data: { title: 'Route Tour Claim', status: 'pending' },
  });
  expect(response.ok(), ownerMessage('selective-native-claim-capture', 'native_screen')).toBe(true);
  const body = await response.json();
  if (!body.id) {
    throw new Error(`route-tour native fixture did not return a claim id: ${JSON.stringify(body)}`);
  }
  return body.id;
}

function ownerMessage(routeId: string, owner: string) {
  return `route-tour semantic assertion failed for route id ${routeId} (${owner}); screenshots are collateral after this assertion passes`;
}
