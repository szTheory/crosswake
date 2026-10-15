import { test, expect, type Locator, type Page } from '@playwright/test';
import { resetOfflineStudyDatabase } from './support/offline_route_proof';

// D-21: no screenshot, video or trace capture, ever, for this corpus.
test.use({ screenshot: 'off', video: 'off', trace: 'off' });

// D-24: named accessibility checks for the new learner controls. brandbook/BRAND-SPEC.md
// is the authority for tokens; these assertions read computed styles, never pixels.
const alphaScope = 'v1.scope_fixture_alpha_01';
const SYNTHETIC_ANSWER = 'synthetic accessibility answer';

async function openIsland(page: Page) {
  await page.goto('/offline');
  await expect.poll(() => page.locator('#crosswake-study-status').textContent()).toContain('Your saved answers remain on this iPhone.');
  await page.evaluate(scopeRef => (window as any).crosswakeOfflineStudy.activateScope(scopeRef), alphaScope);
}

function controls(page: Page) {
  return {
    input: page.getByRole('textbox', { name: 'Your answer' }),
    save: page.getByRole('button', { name: 'Save answer' }),
    play: page.getByRole('button', { name: 'Play pronunciation' }),
  };
}

async function activeId(page: Page) {
  return page.evaluate(() => document.activeElement?.id ?? '');
}

// Computed WCAG contrast, compositing the full ancestor background stack
// (same method as evidence_panel.spec.ts; no new dependency).
async function contrastRatios(page: Page, selectors: string[]) {
  return page.evaluate((list: string[]) => {
    const parseRGBA = (value: string): [number, number, number, number] | null => {
      const m = /rgba?\(([^)]+)\)/.exec(value);
      if (!m) return null;
      const p = m[1].split(',').map(x => parseFloat(x.trim()));
      return [p[0], p[1], p[2], p.length > 3 ? p[3] : 1];
    };
    const effectiveBackground = (el: Element): [number, number, number] => {
      const stack: Array<[number, number, number, number] | null> = [];
      let node: Element | null = el;
      while (node) {
        stack.push(parseRGBA(getComputedStyle(node).backgroundColor));
        node = node.parentElement;
      }
      stack.push([255, 255, 255, 1]);
      let out: [number, number, number] | null = null;
      for (let i = stack.length - 1; i >= 0; i--) {
        const c = stack[i];
        if (!c) continue;
        if (out === null) {
          out = [c[0], c[1], c[2]];
          continue;
        }
        const a = c[3];
        out = [c[0] * a + out[0] * (1 - a), c[1] * a + out[1] * (1 - a), c[2] * a + out[2] * (1 - a)];
      }
      return out ?? [255, 255, 255];
    };
    const luminance = (rgb: [number, number, number]) => {
      const [r, g, b] = rgb.map(v => {
        const s = v / 255;
        return s <= 0.03928 ? s / 12.92 : Math.pow((s + 0.055) / 1.055, 2.4);
      });
      return 0.2126 * r + 0.7152 * g + 0.0722 * b;
    };
    return list.map(selector => {
      const el = document.querySelector(selector)!;
      const bg = effectiveBackground(el);
      const rawFg = parseRGBA(getComputedStyle(el).color)!;
      const fg: [number, number, number] = rawFg[3] < 1
        ? [0, 1, 2].map(i => rawFg[i] * rawFg[3] + bg[i] * (1 - rawFg[3])) as [number, number, number]
        : [rawFg[0], rawFg[1], rawFg[2]];
      const l1 = luminance(fg);
      const l2 = luminance(bg);
      const [hi, lo] = l1 > l2 ? [l1, l2] : [l2, l1];
      return { selector, ratio: (hi + 0.05) / (lo + 0.05) };
    });
  }, selectors);
}

async function insideViewport(locator: Locator, viewport: { width: number; height: number }) {
  const box = await locator.boundingBox();
  expect(box, 'control has a layout box').not.toBeNull();
  return box!.x >= 0 && box!.y >= 0 && box!.x + box!.width <= viewport.width && box!.y + box!.height <= viewport.height;
}

test.describe('Offline study island accessibility (D-24)', () => {
  test.beforeEach(async ({ page }) => {
    const session = await page.request.post('/_e2e/replay-session', { data: { action: 'establish' } });
    expect(session.status()).toBe(201);
    await resetOfflineStudyDatabase(page);
  });

  test('D-24 accessible name: each new control resolves to exactly one visible element', async ({ page }) => {
    await openIsland(page);
    const { input, save, play } = controls(page);
    for (const control of [input, save, play]) {
      await expect(control).toHaveCount(1);
      await expect(control).toBeVisible();
    }
  });

  test('D-24 status announcement: polite status changes without moving focus', async ({ page, context }) => {
    await openIsland(page);
    await context.setOffline(true);
    const { input, save } = controls(page);
    await input.focus();
    await page.keyboard.type(SYNTHETIC_ANSWER);
    await page.keyboard.press('Tab');
    expect(await activeId(page)).toBe('btn-save-answer');

    const status = page.getByRole('status');
    await expect(status).toHaveAttribute('aria-live', 'polite');
    await page.keyboard.press('Enter');
    await expect(status).toContainText('Saved on this device');
    expect(await activeId(page)).toBe('btn-save-answer');
    await expect(save).toBeFocused();
    expect(await page.evaluate(() => document.getElementById('crosswake-study-status')?.contains(document.activeElement))).toBe(false);
  });

  test('D-24 targets: every new control is at least 44x44 CSS px', async ({ page }) => {
    await openIsland(page);
    const { input, save, play } = controls(page);
    for (const control of [input, save, play]) {
      const box = await control.boundingBox();
      expect(box!.width).toBeGreaterThanOrEqual(44);
      expect(box!.height).toBeGreaterThanOrEqual(44);
    }
  });

  test('D-24 focus: keyboard focus is visibly indicated on every new control', async ({ page }) => {
    await openIsland(page);
    const targets = ['study-free-form', 'btn-save-answer', 'btn-play-audio'];
    const seen = new Set<string>();
    for (let press = 0; press < 12 && seen.size < targets.length; press += 1) {
      await page.keyboard.press('Tab');
      const id = await activeId(page);
      if (!targets.includes(id) || seen.has(id)) continue;
      seen.add(id);
      const indicator = await page.evaluate(() => {
        const el = document.activeElement as HTMLElement;
        const style = getComputedStyle(el);
        return {
          focusVisible: el.matches(':focus-visible'),
          outlineStyle: style.outlineStyle,
          outlineWidth: parseFloat(style.outlineWidth),
          boxShadow: style.boxShadow,
        };
      });
      expect(indicator.focusVisible, `${id} matches :focus-visible`).toBe(true);
      const visible = (indicator.outlineStyle !== 'none' && indicator.outlineWidth > 0) || indicator.boxShadow !== 'none';
      expect(visible, `${id} shows a non-none outline or box-shadow`).toBe(true);
    }
    expect([...seen].sort()).toEqual([...targets].sort());
  });

  test('D-24 contrast: text meets 4.5:1 in light, dark and no-preference schemes', async ({ page, context }) => {
    await openIsland(page);
    await context.setOffline(true);
    const { input, save } = controls(page);
    await input.fill(SYNTHETIC_ANSWER);
    await save.click();
    await expect(page.locator('#study-durable-copy')).toHaveText('Saved on this device');

    const selectors = [
      'label[for="study-free-form"]',
      '#study-free-form',
      '#btn-save-answer',
      '#btn-play-audio',
      '#study-audio-state',
      '#study-answer-message',
      '#study-durable-copy',
    ];
    for (const scheme of ['light', 'dark', 'no-preference'] as const) {
      await page.emulateMedia({ colorScheme: scheme });
      const dark = await page.evaluate(() => matchMedia('(prefers-color-scheme: dark)').matches);
      expect(dark, `scheme emulation took effect for ${scheme}`).toBe(scheme === 'dark');
      for (const { selector, ratio } of await contrastRatios(page, selectors)) {
        expect(ratio, `${selector} contrast in ${scheme} (${ratio.toFixed(2)}:1)`).toBeGreaterThanOrEqual(4.5);
      }
    }
  });

  test('D-24 reflow: no horizontal overflow at 320 CSS px with 200% root text', async ({ page }) => {
    await page.setViewportSize({ width: 320, height: 568 });
    await openIsland(page);
    await page.evaluate(() => { document.documentElement.style.fontSize = '200%'; });
    const overflow = await page.evaluate(() => ({
      root: document.documentElement.scrollWidth - document.documentElement.clientWidth,
      body: document.body.scrollWidth - document.body.clientWidth,
    }));
    expect(overflow.root).toBeLessThanOrEqual(0);
    expect(overflow.body).toBeLessThanOrEqual(0);
  });

  test('D-24 input visible: the answer input stays visible after focus in a 320x568 viewport', async ({ page }) => {
    await page.setViewportSize({ width: 320, height: 568 });
    await openIsland(page);
    const { input } = controls(page);
    await input.focus();
    await expect(input).toBeFocused();
    expect(await insideViewport(input, { width: 320, height: 568 })).toBe(true);
  });

  test('D-24 safe-area: controls stay reachable and unobscured with simulated 47px top and 34px bottom insets', async ({ page }) => {
    await page.setViewportSize({ width: 320, height: 568 });
    await openIsland(page);
    // Playwright cannot emulate env(safe-area-inset-*); body padding stands in for the inset.
    await page.addStyleTag({ content: 'body { padding-top: 47px !important; padding-bottom: 34px !important; }' });
    const { input, save, play } = controls(page);
    for (const control of [input, save, play]) {
      await control.scrollIntoViewIfNeeded();
      const box = (await control.boundingBox())!;
      expect(await insideViewport(control, { width: 320, height: 568 })).toBe(true);
      const hit = await control.evaluate((el, point) => {
        const top = document.elementFromPoint(point.x, point.y);
        return top === el || el.contains(top);
      }, { x: box.x + box.width / 2, y: box.y + box.height / 2 });
      expect(hit, 'nothing covers the control center').toBe(true);
    }
  });

  test('D-24 keyboard: Tab order, Enter and Space activation, and visibility with a shortened viewport', async ({ page, context }) => {
    await page.setViewportSize({ width: 320, height: 568 });
    await openIsland(page);
    await context.setOffline(true);

    let reached = false;
    for (let press = 0; press < 12 && !reached; press += 1) {
      await page.keyboard.press('Tab');
      reached = (await activeId(page)) === 'study-free-form';
    }
    expect(reached, 'Tab reaches the free-form input').toBe(true);
    await page.keyboard.type('synthetic keyboard answer one');
    await page.keyboard.press('Tab');
    expect(await activeId(page)).toBe('btn-save-answer');
    await page.keyboard.press('Enter');
    await expect.poll(() => page.evaluate(() => (window as any).crosswakeIsland.outboxCounts())).toMatchObject({ free_form: 1 });

    await page.keyboard.press('Tab');
    expect(await activeId(page)).toBe('btn-play-audio');

    const { input, save } = controls(page);
    await input.focus();
    await page.keyboard.type('synthetic keyboard answer two');
    await page.keyboard.press('Tab');
    await page.keyboard.press('Space');
    await expect.poll(() => page.evaluate(() => (window as any).crosswakeIsland.outboxCounts())).toMatchObject({ free_form: 2 });

    // The shortened viewport stands in for the on-screen keyboard.
    await input.focus();
    await page.setViewportSize({ width: 320, height: 308 });
    for (const control of [input, save]) {
      await control.scrollIntoViewIfNeeded();
      const box = (await control.boundingBox())!;
      expect(box.y + box.height).toBeGreaterThan(0);
      expect(box.y).toBeLessThan(308);
    }
  });

  test('D-24 reduced motion: new controls add no transition or animation', async ({ page, context }) => {
    await page.emulateMedia({ reducedMotion: 'reduce' });
    await openIsland(page);
    await context.setOffline(true);
    await controls(page).input.fill(SYNTHETIC_ANSWER);
    await controls(page).save.click();
    for (const selector of ['#study-free-form', '#btn-save-answer', '#btn-play-audio', '#study-durable-copy']) {
      const motion = await page.locator(selector).evaluate(el => {
        const style = getComputedStyle(el);
        return { animationName: style.animationName, transitionDuration: style.transitionDuration };
      });
      expect(motion.animationName, `${selector} animation`).toBe('none');
      expect(motion.transitionDuration.split(',').every(part => parseFloat(part) === 0), `${selector} transition`).toBe(true);
    }
  });

  test('D-24 status meaning: state is carried by text, not color alone', async ({ page, context }) => {
    await openIsland(page);
    await context.setOffline(true);
    const line = page.locator('#study-durable-copy');
    await controls(page).input.fill(SYNTHETIC_ANSWER);
    await controls(page).save.click();
    await expect(line).toHaveText('Saved on this device');
    const savedLocal = await page.locator('#crosswake-study-status').innerText();

    await page.evaluate(() => window.dispatchEvent(new Event('offline')));
    await expect(line).toHaveText('Waiting to send');
    const waiting = await page.locator('#crosswake-study-status').innerText();
    expect(waiting).not.toBe(savedLocal);

    // Each state names itself in words and carries a non-color glyph.
    expect((await page.locator('#crosswake-study-status-icon').textContent())?.trim().length).toBeGreaterThan(0);
    await expect(page.locator('#study-audio-state')).toHaveText('Audio unavailable');
  });
});
