import { test, expect, type BrowserContext, type Page } from '@playwright/test';
import { mkdirSync, readFileSync } from 'node:fs';
import path from 'node:path';
import {
  assertAppGeneratedMutation,
  expectOutboxEmpty,
  expectSyncedReview,
  proveLearnLoopRoute,
  readQueuedOfflineMutations,
  resetOfflineStudyDatabase,
} from './support/offline_route_proof';
import { writeRouteTourEvidenceManifest } from './support/evidence_manifest';

const screenshotDir = path.join(process.cwd(), 'playwright-artifacts', 'route-tour');
const routeTourScreenshotDir = path.join(screenshotDir, 'screenshots');
const routerPath = path.join(process.cwd(), 'lib', 'crosswake_example', 'router.ex');
const routeTourCommand = 'npx playwright test e2e/route_tour.spec.ts';

// Read from the library's own contract rather than hardcoded, so a protocol version
// bump can never leave this spec asserting a stale number the way the deleted
// hand-built envelope did.
const contractPath = path.join(process.cwd(), '..', '..', 'lib', 'crosswake', 'bridge', 'contract.ex');
const BRIDGE_PROTOCOL_VERSION = /@version\s+"([^"]+)"/.exec(readFileSync(contractPath, 'utf8'))![1];

const bridgeReplySelector = '#crosswake-bridge-reply';

type AdminPilotFlowOptions = {
  captureScreenshots?: boolean;
};

test.describe('Crosswake route-owner browser tour', () => {
  test.beforeEach(async ({ page }) => {
    await resetOfflineStudyDatabase(page);
  });

  test('@learnloop proves LiveView, bounded bridge, offline island, LearnLoop, and native-owned fallback route semantics before screenshots', async ({ page, context }) => {
    mkdirSync(routeTourScreenshotDir, { recursive: true });

    await proveShowcaseHub(page);
    await captureRouteScreenshot(page, 'showcase-hub.png');

    await proveSaasRoute(page);
    await proveAdminPilotApprovalFlow(page);
    await proveFieldservRoute(page);
    await proveLearnLoopRoute(page, context, { screenshotDir: routeTourScreenshotDir });

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

  test('@learnloop keeps the showcase hub readable in mobile dark reduced-motion mode', async ({ page, context }) => {
    mkdirSync(routeTourScreenshotDir, { recursive: true });

    await page.setViewportSize({ width: 390, height: 844 });
    await page.emulateMedia({ colorScheme: 'dark', reducedMotion: 'reduce' });
    await proveShowcaseHub(page);
    await expectNoHorizontalOverflow(page, 'showcase-hub');

    await proveAdminPilotApprovalFlow(page, { captureScreenshots: false });
    await expectNoHorizontalOverflow(page, 'saas-approval');

    await page.keyboard.press('Tab');
    await expectVisibleFocus(page, 'saas-approval');

    await proveFieldservRoute(page, { captureScreenshots: false });
    await expectNoHorizontalOverflow(page, 'fieldserv-jobs');

    await proveLearnLoopRoute(page, context, { captureScreenshots: false });
    await expectNoHorizontalOverflow(page, 'learnloop-dashboard');

    await captureRouteScreenshot(page, 'showcase-mobile-dark-reduced.png');
  });
});

/*
 * D-38's three browser-only cases for the typed control-contract seam. No simulator
 * and no device is involved, honoring the COLL-01 wall — a desktop browser is a real,
 * shipped runtime for this seam, not a stand-in for one.
 *
 * Each case asserts POSITIVELY that a reply arrived, then which reply it was. The
 * third case is the one that earns its keep: without it the server-armed wiring
 * deadline is untested infrastructure, and an adopter who registers the hooks map but
 * omits the element from a route's tree would discover that only in production.
 */
test.describe('Crosswake bounded bridge — shell absent, shell present, hook unwired', () => {
  test('@bridge renders a typed denial when the browser has no shell at all', async ({ page }) => {
    await page.goto('/bridge-proof');
    await expectLiveViewConnected(page, 'bridge-proof');

    const reply = await shareAndAwaitReply(page);

    await expect(reply, ownerMessage('bridge-proof', 'no-shell denial')).toHaveAttribute('data-cw-reply-status', 'deny');
    await expect(reply, ownerMessage('bridge-proof', 'no-shell denial reason')).toContainText('shell_unreachable');
    await expect(reply, ownerMessage('bridge-proof', 'no-shell denial names the transport fact')).toContainText(
      'could not reach a native transport',
    );
  });

  test('@bridge renders an ok reply when a shell is injected at document start', async ({ page }) => {
    // page.addInitScript runs at document start — the exact injection point both real
    // shells use for window.crosswakeBridge — so this is a faithful stand-in for a
    // shell rather than a hand-wave. The reply is deferred by one macrotask because
    // the hook records the correlation id only AFTER postMessage returns; answering
    // synchronously would be dropped by the hook's own in-flight gate, correctly.
    await page.addInitScript(() => {
      const shell: Record<string, unknown> = {
        postMessage(raw: string) {
          const request = JSON.parse(raw);
          setTimeout(() => {
            (shell.__reply as (reply: unknown) => void)({
              protocol: request.protocol,
              version: request.version,
              status: 'ok',
              command: request.command,
              route_id: request.route_id,
              correlation_id: request.correlation_id,
              payload: {},
            });
          }, 0);
        },
      };

      (window as unknown as Record<string, unknown>).crosswakeBridge = shell;
    });

    await page.goto('/bridge-proof');
    await expectLiveViewConnected(page, 'bridge-proof');

    const reply = await shareAndAwaitReply(page);

    await expect(reply, ownerMessage('bridge-proof', 'simulated-shell ok reply')).toHaveAttribute('data-cw-reply-status', 'ok');
    await expect(reply, ownerMessage('bridge-proof', 'simulated-shell ok copy')).toContainText('Shell accepted');
  });

  test('@bridge renders the server-side wiring-deadline denial when the hook is deliberately unwired', async ({ page }) => {
    // Serve an inert module in place of the real hook: the layout still registers a
    // hook named CrosswakeBridge and the element still mounts, but nothing ever
    // acknowledges the dispatch. This is the adopter-misconfiguration shape the
    // server-armed deadline exists to catch, and it is what makes that deadline a
    // tested safety net rather than untested infrastructure (D-36, D-38).
    await page.route('**/crosswake/crosswake.esm.js', (route) =>
      route.fulfill({
        status: 200,
        contentType: 'text/javascript',
        body: 'export const CrosswakeBridge = {};\nexport default CrosswakeBridge;\n',
      }),
    );

    await page.goto('/bridge-proof');
    await expectLiveViewConnected(page, 'bridge-proof');

    const reply = await shareAndAwaitReply(page);

    await expect(reply, ownerMessage('bridge-proof', 'unwired-hook denial')).toHaveAttribute('data-cw-reply-status', 'deny');
    await expect(reply, ownerMessage('bridge-proof', 'unwired-hook denial reason')).toContainText('shell_unreachable');
    await expect(reply, ownerMessage('bridge-proof', 'server-armed wiring deadline, not a transport fact')).toContainText(
      'before the wiring deadline',
    );
  });
});

async function proveShowcaseHub(page: Page) {
  await page.goto('/');

  await expect(page, ownerMessage('showcase-hub', 'browser title')).toHaveTitle('Showcase · Crosswake');
  await expectLiveViewConnected(page, 'showcase-hub');

  await expect(
    page.getByRole('heading', { name: /Phoenix routes, native where it matters\./ }),
    ownerMessage('showcase-hub', 'live_view showcase'),
  ).toBeVisible();

  const logo = page.getByRole('img', { name: 'Crosswake' });
  await expect(logo, ownerMessage('showcase-hub', 'crosswake logo')).toBeVisible();
  const logoLoaded = await logo.evaluate((element) => {
    const image = element as HTMLImageElement;
    return image.complete && image.naturalWidth > 0 && image.naturalHeight > 0;
  });
  expect(logoLoaded, ownerMessage('showcase-hub', 'crosswake logo asset loaded')).toBe(true);

  await expect(page.getByRole('heading', { name: 'AdminPilot' }), ownerMessage('showcase-hub', 'saas lane brand')).toBeVisible();
  await expect(page.getByRole('heading', { name: 'Fieldserv' }), ownerMessage('showcase-hub', 'field-service lane brand')).toBeVisible();
  await expect(page.getByRole('heading', { name: 'LearnLoop' }), ownerMessage('showcase-hub', 'learning lane brand')).toBeVisible();
  await expect(page.getByText('Crosswake example host'), ownerMessage('showcase-hub', 'legacy root copy removed')).toHaveCount(0);

  const brandCards = page.locator('.showcase-lane-card');
  await expect(brandCards, ownerMessage('showcase-hub', 'three brand cards')).toHaveCount(3);
  const brandStyles = await brandCards.evaluateAll((cards) =>
    cards.map((card) => ({
      brand: card.getAttribute('data-brand'),
      style: card.getAttribute('data-style'),
      accent: window.getComputedStyle(card).getPropertyValue('--app-accent').trim(),
    })),
  );
  expect(brandStyles.map(({ brand }) => brand), ownerMessage('showcase-hub', 'brand card order')).toEqual([
    'AdminPilot',
    'Fieldserv',
    'LearnLoop',
  ]);
  expect(new Set(brandStyles.map(({ style }) => style)).size, ownerMessage('showcase-hub', 'distinct style identifiers')).toBe(3);
  expect(new Set(brandStyles.map(({ accent }) => accent)).size, ownerMessage('showcase-hub', 'distinct brand accents')).toBe(3);

  const body = page.locator('body');
  await expect(body, ownerMessage('showcase-hub', 'parent brand copy')).toContainText('Crosswake Showcase');
  await expect(body, ownerMessage('showcase-hub', 'powered by Crosswake copy')).toContainText('Demo apps powered by Crosswake');
  await expect(body, ownerMessage('showcase-hub', 'admin fixture preview')).toContainText('Northwind Workspace');
  await expect(body, ownerMessage('showcase-hub', 'field fixture preview')).toContainText('Ridgeway Mutual Field Ops');
  await expect(body, ownerMessage('showcase-hub', 'learning fixture preview')).toContainText('Brightpath Academy');
  await expect(body, ownerMessage('showcase-hub', 'domain label visible')).toContainText('SaaS/Admin');
  await expect(body, ownerMessage('showcase-hub', 'domain label visible')).toContainText('Field Service');
  await expect(body, ownerMessage('showcase-hub', 'domain label visible')).toContainText('Learning/Training');
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

async function proveSaasRoute(page: Page) {
  await page.goto('/saas/dashboard');

  await expect(page, ownerMessage('saas-dashboard', 'browser title')).toHaveTitle('Dashboard · AdminPilot · Crosswake');
  await expect(page.getByRole('heading', { name: 'Northwind mobile approvals' }), ownerMessage('saas-dashboard', 'live_view')).toBeVisible();

  const router = readFileSync(routerPath, 'utf8');
  expect(router, ownerMessage('saas-dashboard', 'live_view')).toContain('id: "saas-dashboard"');
  expect(router, ownerMessage('saas-dashboard', 'live_view')).toContain('live("/dashboard"');
}

async function proveAdminPilotApprovalFlow(page: Page, options: AdminPilotFlowOptions = {}) {
  const captureScreenshots = options.captureScreenshots ?? true;

  // D-01/D-02/D-36: AdminPilot proof is a focused approvals path, not a screenshot-first admin console.
  const reset = await page.request.post('/_e2e/showcase-reset');
  expect(reset.ok(), ownerMessage('showcase-reset', 'deterministic showcase reset')).toBe(true);

  // D-18/T-149-02: session setup stays behind a planned compile-time-gated e2e helper.
  const session = await page.request.post('/_e2e/saas-session', {
    data: { user_id: 'approver-1' },
  });
  expect(session.ok(), ownerMessage('saas-dashboard', 'approver-1 e2e session helper')).toBe(true);

  const router = readFileSync(routerPath, 'utf8');
  expect(router, ownerMessage('saas-dashboard', 'live_view')).toContain('id: "saas-dashboard"');
  expect(router, ownerMessage('saas-approvals', 'live_view')).toContain('id: "saas-approvals"');
  expect(router, ownerMessage('saas-approval', 'live_view + bounded haptics')).toContain('id: "saas-approval"');
  expect(router, ownerMessage('saas-approval', 'bounded haptics capability')).toContain('capabilities: ["haptics"]');

  await page.goto('/saas/dashboard');
  await expect(page, ownerMessage('saas-dashboard', 'browser title')).toHaveTitle('Dashboard · AdminPilot · Crosswake');
  await expect(page.getByRole('heading', { name: /Northwind mobile approvals/i }), ownerMessage('saas-dashboard', 'live_view')).toBeVisible();
  await expect(page.getByText(/LiveView route/i).first(), ownerMessage('saas-dashboard', 'route ownership label')).toBeVisible();
  await expect(page.getByText(/Cached read-only/i).first(), ownerMessage('saas-dashboard', 'cached read-only support truth')).toBeVisible();
  await expect(page.getByText(/Server authority/i).first(), ownerMessage('saas-dashboard', 'Phoenix server authority')).toBeVisible();
  if (captureScreenshots) {
    await captureRouteScreenshot(page, 'adminpilot-dashboard.png');
  }

  await page.getByRole('link', { name: /Approvals|Review queue/i }).first().click();
  await expect(page, ownerMessage('saas-approvals', 'queue route')).toHaveURL(/\/saas\/approvals$/);
  await expect(page.getByRole('heading', { name: /Approvals/i }), ownerMessage('saas-approvals', 'approval queue')).toBeVisible();
  await expect(page.locator('body'), ownerMessage('saas-approvals', 'approval-1 visible')).toContainText('Quarterly spend increase');
  if (captureScreenshots) {
    await captureRouteScreenshot(page, 'adminpilot-approvals.png');
  }

  await page.getByRole('link', { name: /Quarterly spend increase|approval-1/i }).click();
  await expect(page, ownerMessage('saas-approval', 'detail route')).toHaveURL(/\/saas\/approvals\/approval-1$/);
  await expectLiveViewConnected(page, 'saas-approval');
  await page.getByRole('button', { name: 'Approve request' }).click();

  const status = page.getByRole('status').first();
  await expect(status, ownerMessage('saas-approval', 'Phoenix/server approval status')).toContainText(/Phoenix|server authority/i);
  const hapticsPayload = await approvalHapticsPayload(page);
  expect(hapticsPayload.command, ownerMessage('saas-approval', 'post-success haptics command')).toBe('haptics.impact');
  expect(hapticsPayload.capability, ownerMessage('saas-approval', 'post-success haptics capability')).toBe('haptics.impact');
  expect(hapticsPayload.route_id, ownerMessage('saas-approval', 'post-success haptics route')).toBe('saas-approval');
  expect(hapticsPayload.active_route_id, ownerMessage('saas-approval', 'post-success haptics active route')).toBe('saas-approval');
  expect(hapticsPayload.protocol, ownerMessage('saas-approval', 'post-success haptics protocol')).toBe('crosswake.bridge');
  await expect(page.locator('body'), ownerMessage('saas-approval', 'haptics degradable support truth')).toContainText(/Optional haptics|secondary|degradable/i);
  if (captureScreenshots) {
    await captureRouteScreenshot(page, 'adminpilot-approval-approved.png');
  }

  await page.locator('.adminpilot-diagnostics summary').first().click();
  const body = page.locator('body');
  await expect(body, ownerMessage('saas-approval', 'AdminPilot diagnostics panel')).toContainText('Route policy diagnostics');
  await expect(body, ownerMessage('saas-approval', 'AdminPilot diagnostics scope')).toContainText('AdminPilot routes only');
  await expect(body, ownerMessage('saas-dashboard', 'diagnostics row')).toContainText('saas-dashboard');
  await expect(body, ownerMessage('saas-approvals', 'diagnostics row')).toContainText('saas-approvals');
  await expect(body, ownerMessage('saas-approval', 'diagnostics row')).toContainText('saas-approval');
  await expect(body, ownerMessage('saas-approval', 'diagnostics support truth')).toContainText(/Support truth|Proof-backed example|Demo pressure/i);
  if (captureScreenshots) {
    await captureRouteScreenshot(page, 'adminpilot-diagnostics.png');
  }
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
  await expectLiveViewConnected(page, 'bridge-proof');
  await shareAndAwaitReply(page);
  await expect(page.locator('#crosswake-bridge-payload'), ownerMessage('bridge-proof', 'bounded bridge')).not.toHaveAttribute('hidden', '');

  // The raw dump is now the envelope Crosswake.Bridge.push/3 actually built, not a
  // hand-assembled copy of it — so these assertions read the wire truth directly
  // (D-67, D-70). The hand-built envelope this replaces claimed protocol version
  // "1.0.0" while the shipped contract had already moved to "1.1.0": exactly the
  // drift that made a second, hand-maintained envelope worth deleting.
  const payload = await bridgePayload(page);
  expect(payload.command, ownerMessage('bridge-proof', 'bounded bridge')).toBe('share.invoke');
  expect(payload.capability, ownerMessage('bridge-proof', 'bounded bridge')).toBe('share');
  expect(payload.route_id, ownerMessage('bridge-proof', 'bounded bridge')).toBe('bridge-proof');
  expect(payload.active_route_id, ownerMessage('bridge-proof', 'bounded bridge')).toBe('bridge-proof');
  expect(payload.protocol, ownerMessage('bridge-proof', 'bounded bridge')).toBe('crosswake.bridge');
  expect(payload.version, ownerMessage('bridge-proof', 'bounded bridge')).toBe(BRIDGE_PROTOCOL_VERSION);
  expect(payload.origin, ownerMessage('bridge-proof', 'bounded bridge')).toBe('https://example.crosswake.invalid');
  expect(payload.correlation_id, ownerMessage('bridge-proof', 'library-minted correlation id')).toMatch(/^cwbridge-e\d+-/);
}

async function proveOfflineRoute(page: Page, context: BrowserContext) {
  await page.goto('/offline');

  await expect(page, ownerMessage('offline-study', 'browser title')).toHaveTitle('Offline Study · LearnLoop · Crosswake');
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

async function proveFieldservRoute(page: Page, options: AdminPilotFlowOptions = {}) {
  const captureScreenshots = options.captureScreenshots ?? true;
  const reset = await page.request.post('/_e2e/showcase-reset');
  expect(reset.ok(), ownerMessage('showcase-reset', 'deterministic Fieldserv reset')).toBe(true);

  const router = readFileSync(routerPath, 'utf8');
  expect(router, ownerMessage('fieldserv-jobs', 'live_view route')).toContain('id: "fieldserv-jobs"');
  expect(router, ownerMessage('fieldserv-job', 'live_view route')).toContain('id: "fieldserv-job"');
  expect(router, ownerMessage('fieldserv-inspection', 'live_view route')).toContain('id: "fieldserv-inspection"');
  expect(router, ownerMessage('fieldserv-job-capture', 'native_screen route')).toContain('id: "fieldserv-job-capture"');
  expect(router, ownerMessage('fieldserv-job-capture', 'native_screen route')).toContain('runtime: :native_screen');
  expect(router, ownerMessage('fieldserv-job-capture', 'camera capability')).toContain('capabilities: [:camera]');
  expect(router, ownerMessage('fieldserv-job-capture', 'upload transfer metadata')).toContain('source: :native_capture');
  expect(router, ownerMessage('fieldserv-evidence-review', 'backend review route')).toContain('id: "fieldserv-evidence-review"');

  await page.goto('/fieldserv/jobs');
  await expect(page, ownerMessage('fieldserv-jobs', 'browser title')).toHaveTitle(/Fieldserv|Crosswake/);
  await expectLiveViewConnected(page, 'fieldserv-jobs');
  await expect(page.getByRole('heading', { name: /Ridgeway|Fieldserv|job queue/i }), ownerMessage('fieldserv-jobs', 'product lane')).toBeVisible();
  await expect(page.locator('body'), ownerMessage('fieldserv-jobs', 'field-service fixture')).toContainText('Broken windshield');
  await expect(page.locator('body'), ownerMessage('fieldserv-jobs', 'route support truth')).toContainText(/LiveView route|Cached read-only/);
  await expectNoHorizontalOverflow(page, 'fieldserv-jobs');
  if (captureScreenshots) {
    await captureRouteScreenshot(page, 'fieldserv-jobs.png');
  }

  await page.getByRole('link', { name: /Broken windshield|job-1|Open job/i }).first().click();
  await expect(page, ownerMessage('fieldserv-job', 'job detail route')).toHaveURL(/\/fieldserv\/jobs\/job-1$/);
  await expectLiveViewConnected(page, 'fieldserv-job');
  await expect(page.locator('body'), ownerMessage('fieldserv-job', 'asset context')).toContainText(/Asset|Windshield/i);
  await expect(page.locator('body'), ownerMessage('fieldserv-job', 'cached read-only posture')).toContainText('Cached read-only');
  await expect(page.locator('body'), ownerMessage('fieldserv-job', 'backend evidence authority')).toContainText(/Backend verification pending|Device evidence/i);
  if (captureScreenshots) {
    await captureRouteScreenshot(page, 'fieldserv-job-detail.png');
  }

  await page.getByRole('link', { name: /Inspection|Open inspection/i }).first().click();
  await expect(page, ownerMessage('fieldserv-inspection', 'inspection route')).toHaveURL(/\/fieldserv\/jobs\/job-1\/inspection$/);
  await expect(page.locator('body'), ownerMessage('fieldserv-inspection', 'offline honesty')).toContainText('Future offline island candidate');
  await expect(page.locator('body'), ownerMessage('fieldserv-inspection', 'offline requirements')).toContainText(/local draft storage|journal\/outbox|reconciliation proof/i);
  await expect(page.locator('body'), ownerMessage('fieldserv-inspection', 'no shipped local mutation')).not.toContainText(/saved locally|queued for sync/i);
  await page.keyboard.press('Tab');
  await expectVisibleFocus(page, 'fieldserv-inspection');
  if (captureScreenshots) {
    await captureRouteScreenshot(page, 'fieldserv-inspection.png');
  }

  await page.getByRole('link', { name: /Capture|Native capture/i }).first().click();
  await expect(page, ownerMessage('fieldserv-job-capture', 'capture route')).toHaveURL(/\/fieldserv\/jobs\/job-1\/capture$/);
  await expect(page.locator('body'), ownerMessage('fieldserv-job-capture', 'native runtime')).toContainText('Camera capture requires the native app runtime.');
  await expect(page.locator('body'), ownerMessage('fieldserv-job-capture', 'scanner future gap')).toContainText('Scanner support is a future native-control candidate.');
  await expect(page.locator('body'), ownerMessage('fieldserv-job-capture', 'permission pressure')).toContainText('Permission needed');
  await expect(page.locator('body'), ownerMessage('fieldserv-job-capture', 'backend authority')).toContainText('Device evidence is pending backend verification.');
  await expect(page.locator('body'), ownerMessage('fieldserv-job-capture', 'no web capture fallback')).not.toContainText(/Use browser camera|Scan document now/i);
  if (captureScreenshots) {
    await captureRouteScreenshot(page, 'fieldserv-capture-handoff.png');
  }

  await page.getByRole('link', { name: /Evidence review|Review evidence/i }).first().click();
  await expect(page, ownerMessage('fieldserv-evidence-review', 'evidence review route')).toHaveURL(/\/fieldserv\/jobs\/job-1\/evidence\/evidence-1\/review$/);
  await expect(page.locator('body'), ownerMessage('fieldserv-evidence-review', 'device evidence state')).toContainText('Device evidence recorded');
  await expect(page.locator('body'), ownerMessage('fieldserv-evidence-review', 'backend pending state')).toContainText('Backend verification pending');
  await expect(page.locator('body'), ownerMessage('fieldserv-evidence-review', 'backend verified state')).toContainText('Backend verified');
  await expect(page.locator('body'), ownerMessage('fieldserv-evidence-review', 'backend rejected state')).toContainText('Backend rejected');
  await expect(page.locator('body'), ownerMessage('fieldserv-evidence-review', 'availability authority')).not.toContainText(/uploaded successfully|available after device capture/i);

  await page.locator('.fieldserv-diagnostics summary').first().click();
  await expect(page.locator('body'), ownerMessage('fieldserv-evidence-review', 'diagnostics panel')).toContainText('Route policy diagnostics');
  await expect(page.locator('body'), ownerMessage('fieldserv-job-capture', 'diagnostics route row')).toContainText('fieldserv-job-capture');
  await expect(page.locator('body'), ownerMessage('fieldserv-job-capture', 'diagnostics native owner')).toContainText(/Native screen|Requires native runtime/i);
  await expect(page.locator('body'), ownerMessage('fieldserv-job-capture', 'diagnostics cached posture')).toContainText('Cached read-only');
  if (captureScreenshots) {
    await captureRouteScreenshot(page, 'fieldserv-evidence-review.png');
  }
}

async function proveNativeOwnedRoute(page: Page) {
  const claimId = await createNativeRouteTourClaim(page);
  await page.goto(`/native/claims/${claimId}/capture`);

  await expect(page, ownerMessage('selective-native-claim-capture', 'browser title')).toHaveTitle('Capture Evidence · Fieldserv · Crosswake');
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

async function expectVisibleFocus(page: Page, routeId: string, expectedText?: string | RegExp) {
  const focus = await page.evaluate(() => {
    const active = document.activeElement;
    const style = window.getComputedStyle(active!);

    return {
      text: active?.textContent?.trim(),
      outlineStyle: style.outlineStyle,
      outlineWidth: Number.parseFloat(style.outlineWidth),
    };
  });

  if (expectedText instanceof RegExp) {
    expect(focus.text, ownerMessage(routeId, 'keyboard focus target')).toMatch(expectedText);
  } else if (expectedText) {
    expect(focus.text, ownerMessage(routeId, 'keyboard focus target')).toContain(expectedText);
  } else {
    expect(focus.text, ownerMessage(routeId, 'keyboard focus target')).toBeTruthy();
  }

  expect(focus.outlineStyle, ownerMessage(routeId, 'keyboard focus outline')).not.toBe('none');
  expect(focus.outlineWidth, ownerMessage(routeId, 'keyboard focus outline')).toBeGreaterThan(0);
}

async function expectLiveViewConnected(page: Page, routeId: string) {
  await expect(
    page.locator('[data-phx-main]').first(),
    ownerMessage(routeId, 'LiveView connected before server event'),
  ).toHaveClass(/phx-connected/);
}

/*
 * Presses Share and waits for a reply to ARRIVE (D-75).
 *
 * The wait is on the verdict attribute leaving "pending", never on the absence of an
 * error: a socket that never connected, or a hook that was never registered, leaves
 * this panel sitting in a waiting state that looks entirely plausible on a screenshot
 * and would pass a careless assertion. A denial counts as arrival — the point of
 * CTRL-02 is that there is no configuration in which a push resolves to silence.
 */
async function shareAndAwaitReply(page: Page) {
  await page.getByRole('button', { name: 'Share' }).click();

  const reply = page.locator(bridgeReplySelector);
  await expect(reply, ownerMessage('bridge-proof', 'a reply always arrives — deny counts')).not.toHaveAttribute(
    'data-cw-reply-status',
    'pending',
    { timeout: 20000 },
  );

  return reply;
}

async function bridgePayload(page: Page) {
  const payload = page.locator('#crosswake-bridge-payload');
  await expect(payload, ownerMessage('bridge-proof', 'bounded bridge')).toHaveCount(1);
  const text = await payload.textContent();
  expect(text, ownerMessage('bridge-proof', 'bounded bridge')).toBeTruthy();
  return JSON.parse(text!);
}

async function approvalHapticsPayload(page: Page) {
  const script = page.locator('#crosswake-approval-haptics');
  await expect(script, ownerMessage('saas-approval', 'post-success haptics script')).toHaveCount(1);
  const source = await script.evaluate((element) => element.innerHTML);
  const match = source.match(/const payload = ("(?:\\.|[^"\\])*");/);
  expect(match?.[1], ownerMessage('saas-approval', 'post-success haptics payload source')).toBeTruthy();
  return JSON.parse(JSON.parse(match![1]));
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
