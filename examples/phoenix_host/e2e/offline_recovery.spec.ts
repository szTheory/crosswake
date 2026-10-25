import { test, expect, type Page } from '@playwright/test';
import { resetOfflineStudyDatabase } from './support/offline_route_proof';

// D-21: no screenshot, video or trace capture, ever, for this corpus.
test.use({ screenshot: 'off', video: 'off', trace: 'off' });

// D-11: rejected or conflicting work stays on the device, shows "Needs review", and the
// learner reaches one host-owned destination (GET /offline/review) where Try again and a
// confirmed Discard are the only actions. Server outcomes below come from the real
// ReplayAdmission/Study path; /_e2e/twin/fault only prepares run-owned state.
const alphaScope = 'v1.scope_fixture_alpha_01';
const SYNTHETIC_ANSWER = 'synthetic recovery answer';

async function prepareFault(page: Page, kind: string) {
  const response = await page.request.post('/_e2e/twin/fault', { data: { kind } });
  expect(response.status()).toBe(204);
}

async function openIsland(page: Page) {
  await page.goto('/offline');
  await expect.poll(() => page.locator('#crosswake-study-status').textContent()).toContain('Your saved answers remain on this iPhone.');
  await page.evaluate(scopeRef => (window as any).crosswakeOfflineStudy.activateScope(scopeRef), alphaScope);
}

async function saveAnswer(page: Page, text = SYNTHETIC_ANSWER) {
  await page.getByRole('textbox', { name: 'Your answer' }).fill(text);
  await page.getByRole('button', { name: 'Save answer' }).click();
}

async function counts(page: Page) {
  return page.evaluate(() => (window as any).crosswakeIsland.outboxCounts());
}

async function queuedMutationIds(page: Page): Promise<string[]> {
  return page.evaluate(() => new Promise<string[]>((resolve, reject) => {
    const open = indexedDB.open('crosswake_offline_study');
    open.onsuccess = () => {
      const database = open.result;
      const request = database.transaction('scoped_mutations', 'readonly').objectStore('scoped_mutations').getAll();
      request.onsuccess = () => { database.close(); resolve(request.result.map((row: any) => row.client_mutation_id)); };
      request.onerror = () => reject(request.error);
    };
    open.onerror = () => reject(open.error);
  }));
}

// Get one answer rejected by the real server path, then follow the learner link to the review page.
async function rejectOneAnswer(page: Page, kind: 'replay_reject' | 'replay_conflict' = 'replay_reject') {
  await prepareFault(page, kind);
  await openIsland(page);
  await saveAnswer(page);
  await expect(page.locator('#crosswake-study-status')).toHaveAttribute('data-island-state', 'needs_review');
}

async function openReview(page: Page) {
  await page.getByRole('link', { name: 'Review saved answers' }).click();
  await expect(page).toHaveURL(/\/offline\/review$/);
  await expect(page.getByRole('heading', { name: 'Review saved answers' })).toBeVisible();
}

test.describe('Offline study recovery destination (D-11)', () => {
  test.beforeEach(async ({ page }) => {
    const session = await page.request.post('/_e2e/replay-session', { data: { action: 'establish' } });
    expect(session.status()).toBe(201);
    await prepareFault(page, 'clear');
    await resetOfflineStudyDatabase(page);
  });

  test.afterEach(async ({ page }) => {
    await prepareFault(page, 'clear');
  });

  test('a server rejection keeps the work, shows needs-review copy and offers the review link', async ({ page }) => {
    await rejectOneAnswer(page);

    const status = page.locator('#crosswake-study-status');
    await expect(status).toContainText('Needs review');
    await expect(status).toContainText('Some saved answers need review.');
    const link = page.getByRole('link', { name: 'Review saved answers' });
    await expect(link).toHaveAttribute('href', /\/offline\/review$/);
    expect(await counts(page)).toMatchObject({ free_form: 1, active_scope_total: 1 });
    await expect(status).not.toContainText('Saved to your account');
  });

  test('a scope conflict keeps the work and offers the same review destination', async ({ page }) => {
    await rejectOneAnswer(page, 'replay_conflict');

    await expect(page.locator('#crosswake-study-status')).toContainText('Needs review');
    await expect(page.getByRole('link', { name: 'Review saved answers' })).toHaveAttribute('href', /\/offline\/review$/);
    expect(await counts(page)).toMatchObject({ free_form: 1, active_scope_total: 1 });
  });

  test('the review page lists card label and state only, with Return to study and Try again', async ({ page }) => {
    await rejectOneAnswer(page);
    const [mutationId] = await queuedMutationIds(page);
    await openReview(page);

    const items = page.locator('#review-list > li');
    await expect(items).toHaveCount(1);
    await expect(items.first()).toContainText('Elixir');
    await expect(items.first()).toContainText('Needs review');
    await expect(page.getByRole('link', { name: 'Return to study' })).toHaveAttribute('href', '/offline');
    await expect(page.getByRole('button', { name: /^Try again/ })).toHaveCount(1);

    const html = await page.content();
    expect(html).not.toContain(SYNTHETIC_ANSWER);
    expect(html).not.toContain(mutationId);
    expect(html).not.toContain(alphaScope);
    expect(html).not.toMatch(/scope_fixture|v1\./);
  });

  test('Try again re-queues the same mutation id through normal replay', async ({ page }) => {
    await rejectOneAnswer(page);
    const [mutationId] = await queuedMutationIds(page);
    await openReview(page);

    const request = page.waitForRequest(candidate => candidate.url().includes('/study/sync'));
    await page.getByRole('button', { name: /^Try again/ }).click();
    const body = (await request).postDataJSON();
    expect(body.events.map((event: any) => event.client_mutation_id)).toEqual([mutationId]);

    // The prepared rejection is still real server state, so the work is held again, not lost.
    await expect(page.locator('#review-list > li')).toHaveCount(1);
    await expect(page.locator('#review-list > li').first()).toContainText('Needs review');
    expect(await queuedMutationIds(page)).toEqual([mutationId]);
  });

  test('Keep answer leaves the item and the outbox count unchanged', async ({ page }) => {
    await rejectOneAnswer(page);
    await openReview(page);
    const before = await counts(page);

    const discard = page.getByRole('button', { name: /^Discard saved answer/ });
    await discard.click();
    await expect(page.getByText('Discard this answer? This cannot be undone.')).toBeVisible();
    await expect(page.getByRole('button', { name: 'Keep answer', exact: true })).toBeFocused();

    await page.getByRole('button', { name: 'Keep answer', exact: true }).click();
    await expect(page.getByText('Discard this answer? This cannot be undone.')).toHaveCount(0);
    await expect(discard).toBeFocused();
    await expect(page.locator('#review-list > li')).toHaveCount(1);
    expect(await counts(page)).toEqual(before);
  });

  test('Discard answer removes exactly one item and nothing else', async ({ page }) => {
    await prepareFault(page, 'replay_reject');
    await openIsland(page);
    await saveAnswer(page, 'synthetic first answer');
    await expect(page.locator('#crosswake-study-status')).toHaveAttribute('data-island-state', 'needs_review');
    await saveAnswer(page, 'synthetic second answer');
    await expect.poll(async () => (await counts(page)).active_scope_total).toBe(2);
    await expect(page.locator('#crosswake-study-status')).toHaveAttribute('data-island-state', 'needs_review');
    await page.getByRole('link', { name: 'Review saved answers' }).click();
    await expect(page.locator('#review-list > li')).toHaveCount(2);

    await page.getByRole('button', { name: /^Discard saved answer/ }).first().click();
    await page.getByRole('button', { name: 'Discard answer', exact: true }).click();

    await expect(page.locator('#review-list > li')).toHaveCount(1);
    await expect(page.locator('#review-message')).toHaveText('Answer discarded.');
    expect(await counts(page)).toMatchObject({ active_scope_total: 1, retained_total: 1 });
  });

  test('retained work survives a reload and a fence; only a confirmed Discard removes it', async ({ page }) => {
    await rejectOneAnswer(page);
    await page.reload();
    await expect.poll(() => page.locator('#crosswake-study-status').textContent()).toContain('Your saved answers remain on this iPhone.');
    await page.evaluate(scopeRef => (window as any).crosswakeOfflineStudy.activateScope(scopeRef), alphaScope);
    expect(await counts(page)).toMatchObject({ active_scope_total: 1 });
    await expect(page.locator('#crosswake-study-status')).toHaveAttribute('data-island-state', 'needs_review');

    await page.evaluate(() => (window as any).crosswakeOfflineStudy.fenceScope());
    await expect(page.locator('#crosswake-study-status')).toHaveAttribute('data-island-state', 'fenced');
    expect((await queuedMutationIds(page)).length).toBe(1);
  });

  test('with replay unavailable the review page says so and offers no Try again', async ({ page }) => {
    await rejectOneAnswer(page);
    await prepareFault(page, 'clear');
    await prepareFault(page, 'replay_disable');
    await saveAnswer(page, 'synthetic second answer');
    await expect(page.locator('#crosswake-study-status')).toHaveAttribute('data-island-state', 'unavailable');
    await expect(page.locator('#study-durable-copy')).toContainText('Temporarily unavailable');

    await page.goto('/offline/review');
    await expect(page.locator('#review-list > li')).toHaveCount(2);
    await expect(page.locator('#study-durable-copy')).toContainText('Temporarily unavailable');
    await expect(page.getByRole('button', { name: /^Try again/ })).toHaveCount(0);
    expect(await counts(page)).toMatchObject({ active_scope_total: 2 });
  });

  test('review page controls meet the named accessibility checks in light, dark and no-preference', async ({ page }) => {
    await rejectOneAnswer(page);
    await openReview(page);
    await page.getByRole('button', { name: /^Discard saved answer/ }).click();

    const controlSelectors = ['#review-return', '.review-item button', '.review-confirm button'];
    // targets
    for (const selector of controlSelectors) {
      for (const handle of await page.locator(selector).all()) {
        const box = await handle.boundingBox();
        expect(box!.width, `${selector} width`).toBeGreaterThanOrEqual(44);
        expect(box!.height, `${selector} height`).toBeGreaterThanOrEqual(44);
      }
    }

    // contrast, computed from the rendered colours
    const textSelectors = ['#review-return', '.review-item-label', '.review-item-state', '.review-confirm p', '.review-confirm button'];
    for (const scheme of ['light', 'dark', 'no-preference'] as const) {
      await page.emulateMedia({ colorScheme: scheme });
      expect(await page.evaluate(() => matchMedia('(prefers-color-scheme: dark)').matches)).toBe(scheme === 'dark');
      const ratios = await page.evaluate((list: string[]) => {
        const parse = (value: string): [number, number, number, number] | null => {
          const m = /rgba?\(([^)]+)\)/.exec(value);
          if (!m) return null;
          const p = m[1].split(',').map(x => parseFloat(x.trim()));
          return [p[0], p[1], p[2], p.length > 3 ? p[3] : 1];
        };
        const background = (el: Element): [number, number, number] => {
          const stack: Array<[number, number, number, number] | null> = [];
          let node: Element | null = el;
          while (node) { stack.push(parse(getComputedStyle(node).backgroundColor)); node = node.parentElement; }
          stack.push([255, 255, 255, 1]);
          let out: [number, number, number] | null = null;
          for (let i = stack.length - 1; i >= 0; i--) {
            const c = stack[i];
            if (!c) continue;
            if (out === null) { out = [c[0], c[1], c[2]]; continue; }
            out = [c[0] * c[3] + out[0] * (1 - c[3]), c[1] * c[3] + out[1] * (1 - c[3]), c[2] * c[3] + out[2] * (1 - c[3])];
          }
          return out ?? [255, 255, 255];
        };
        const lum = (rgb: [number, number, number]) => {
          const [r, g, b] = rgb.map(v => { const s = v / 255; return s <= 0.03928 ? s / 12.92 : Math.pow((s + 0.055) / 1.055, 2.4); });
          return 0.2126 * r + 0.7152 * g + 0.0722 * b;
        };
        return list.map(selector => {
          const el = document.querySelector(selector)!;
          const bg = background(el);
          const raw = parse(getComputedStyle(el).color)!;
          const fg: [number, number, number] = raw[3] < 1
            ? [0, 1, 2].map(i => raw[i] * raw[3] + bg[i] * (1 - raw[3])) as [number, number, number]
            : [raw[0], raw[1], raw[2]];
          const [hi, lo] = lum(fg) > lum(bg) ? [lum(fg), lum(bg)] : [lum(bg), lum(fg)];
          return { selector, ratio: (hi + 0.05) / (lo + 0.05) };
        });
      }, textSelectors);
      for (const { selector, ratio } of ratios) {
        expect(ratio, `${selector} contrast in ${scheme} (${ratio.toFixed(2)}:1)`).toBeGreaterThanOrEqual(4.5);
      }
    }

    // visible keyboard focus on the review controls
    const seen = new Set<string>();
    for (let press = 0; press < 12; press += 1) {
      await page.keyboard.press('Tab');
      const indicator = await page.evaluate(() => {
        const el = document.activeElement as HTMLElement;
        const style = getComputedStyle(el);
        return {
          name: el === document.body || el === document.documentElement ? '' : (el.textContent?.trim() ?? ''),
          focusVisible: el.matches(':focus-visible'),
          outlineVisible: style.outlineStyle !== 'none' && parseFloat(style.outlineWidth) > 0,
          boxShadow: style.boxShadow,
        };
      });
      if (!indicator.name) continue;
      seen.add(indicator.name);
      expect(indicator.focusVisible && (indicator.outlineVisible || indicator.boxShadow !== 'none'), `${indicator.name} shows focus`).toBe(true);
    }
    expect(seen.has('Keep answer')).toBe(true);
    expect(seen.has('Discard answer')).toBe(true);

    // 200% text at 320 CSS px: no horizontal overflow
    await page.setViewportSize({ width: 320, height: 568 });
    await page.evaluate(() => { document.documentElement.style.fontSize = '200%'; });
    const overflow = await page.evaluate(() => document.documentElement.scrollWidth - document.documentElement.clientWidth);
    expect(overflow).toBeLessThanOrEqual(0);
  });
});
