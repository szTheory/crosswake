import { test, expect } from '@playwright/test';

// Expected brand-book structure. Magic numbers live here so a deliberate brand
// edit is a one-line test update, not a scavenger hunt (lesson: stale-test churn).
const SECTION_IDS = [
  'hero',
  'essence',
  'logo-system',
  'color',
  'typography',
  'tokens',
  'motifs',
  'voice',
  'ui-specimens',
  'asset-index',
];
const COPY_HEX_BUTTONS = 16;
const CONTRAST_BADGES = 22;
const LOGO_IMAGES = 12;

test.describe('@structural brand book', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
  });

  test('renders all 10 sections, nav parity, and zero leftover placeholders', async ({ page }) => {
    const ids = await page.locator('section[id]').evaluateAll((els) => els.map((e) => e.id));
    expect(ids).toEqual(SECTION_IDS);

    const navHrefs = await page
      .locator('.book-nav a[href^="#"]')
      .evaluateAll((els) => els.map((e) => (e as HTMLAnchorElement).getAttribute('href')!.slice(1)));
    expect([...navHrefs].sort()).toEqual([...SECTION_IDS].sort());

    await expect(page.locator('.section-placeholder')).toHaveCount(0);
  });

  test('every logo <img> actually loads (no broken assets)', async ({ page }) => {
    const imgs = page.locator('img');
    await expect(imgs).toHaveCount(LOGO_IMAGES);
    const widths = await imgs.evaluateAll((els) => els.map((i) => (i as HTMLImageElement).naturalWidth));
    expect(widths.every((w) => w > 0), `all ${LOGO_IMAGES} images decoded: ${JSON.stringify(widths)}`).toBe(true);
  });

  test('copy-hex buttons are well-formed and labelled', async ({ page }) => {
    const btns = page.locator('[data-copy-hex]');
    await expect(btns).toHaveCount(COPY_HEX_BUTTONS);
    const pairs = await btns.evaluateAll((els) =>
      els.map((b) => ({ hex: b.getAttribute('data-copy-hex'), label: b.getAttribute('aria-label') })),
    );
    for (const { hex, label } of pairs) {
      expect(hex).toMatch(/^#[0-9A-F]{6}$/i);
      expect(label).toBe(`Copy ${hex}`);
    }
  });

  test('clicking a copy-hex button reports success (clipboard write resolved)', async ({ page }) => {
    const btn = page.locator('.copy-btn').first();
    await btn.click();
    await expect(btn).toHaveText('Copied!');
  });

  test('live WCAG contrast badges are computed for all swatches/pairings', async ({ page }) => {
    const badges = page.locator('[data-fg][data-bg] .badge');
    await expect(badges).toHaveCount(CONTRAST_BADGES);
    // JS runs on DOMContentLoaded; first badge having a verdict means injection ran.
    await expect(badges.first()).toHaveText(/^\d+\.\d{2}:1 (PASS|FAIL)$/);
    const texts = await badges.allTextContents();
    for (const t of texts) expect(t).toMatch(/^\d+\.\d{2}:1 (PASS|FAIL)$/);
    // Every badge gets exactly one verdict class.
    const classed = await badges.evaluateAll((els) =>
      els.map((e) => e.classList.contains('badge--pass') !== e.classList.contains('badge--fail')),
    );
    expect(classed.every(Boolean)).toBe(true);
  });

  test('scroll-spy highlights the section in view', async ({ page }) => {
    await page.evaluate(() => document.querySelector('#color')!.scrollIntoView({ block: 'center' }));
    await expect(page.locator('.book-nav a[href="#color"]')).toHaveClass(/active/);
  });

  test('mobile viewport has no horizontal overflow', async ({ page }) => {
    await page.setViewportSize({ width: 390, height: 844 });
    await page.goto('/');
    const overflow = await page.evaluate(
      () => document.documentElement.scrollWidth - document.documentElement.clientWidth,
    );
    expect(overflow, `documentElement overflow px`).toBeLessThanOrEqual(1);
  });
});
