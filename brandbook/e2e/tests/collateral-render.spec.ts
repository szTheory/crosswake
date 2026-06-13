import { test, expect, Page } from '@playwright/test';

// Visual tier (advisory). No committed screenshot baselines — instead we render
// each asset headless and pixel-sample art/background regions. This catches
// blank / broken / wrong-colour renders while staying font-independent (we never
// sample text glyphs), so it survives Linux-CI vs macOS font differences.

type Sample = {
  w: number;
  h: number;
  corner: [number, number, number, number]; // RGBA at (2,2)
  opaque: number; // pixels with alpha > 200
  total: number;
  mean: [number, number, number]; // mean RGB of opaque pixels
  light: number; // opaque pixels with luminance > 180
  dark: number; // opaque pixels with luminance < 60
};

// Runs in-page on the localhost origin: fetch (same-origin) → Blob URL → <img> →
// canvas. Blob URLs are same-origin so getImageData is not tainted. For SVGs we
// inject width/height from the viewBox so the rasterised size is deterministic.
async function sample(page: Page, url: string, w: number, h: number): Promise<Sample> {
  return page.evaluate(
    async ({ url, w, h }) => {
      const res = await fetch(url);
      let blob: Blob;
      if (url.endsWith('.svg')) {
        let svg = await res.text();
        if (!/<svg[^>]*\bwidth=/.test(svg)) {
          const vb = svg.match(/viewBox="0 0 (\d+(?:\.\d+)?) (\d+(?:\.\d+)?)"/);
          if (vb) svg = svg.replace('<svg', `<svg width="${vb[1]}" height="${vb[2]}"`);
        }
        blob = new Blob([svg], { type: 'image/svg+xml' });
      } else {
        blob = await res.blob();
      }
      const burl = URL.createObjectURL(blob);
      const img = new Image();
      await new Promise<void>((ok, no) => {
        img.onload = () => ok();
        img.onerror = () => no(new Error(`image failed to load: ${url}`));
        img.src = burl;
      });
      const c = document.createElement('canvas');
      c.width = w;
      c.height = h;
      const ctx = c.getContext('2d', { willReadFrequently: true })!;
      ctx.clearRect(0, 0, w, h);
      ctx.drawImage(img, 0, 0, w, h);
      const px = ctx.getImageData(0, 0, w, h).data;
      const ci = (2 * w + 2) * 4;
      let opaque = 0;
      let rs = 0;
      let gs = 0;
      let bs = 0;
      let light = 0;
      let dark = 0;
      for (let i = 0; i < px.length; i += 4) {
        if (px[i + 3] > 200) {
          opaque++;
          rs += px[i];
          gs += px[i + 1];
          bs += px[i + 2];
          const lum = 0.2126 * px[i] + 0.7152 * px[i + 1] + 0.0722 * px[i + 2];
          if (lum > 180) light++;
          else if (lum < 60) dark++;
        }
      }
      const mean: [number, number, number] = opaque
        ? [Math.round(rs / opaque), Math.round(gs / opaque), Math.round(bs / opaque)]
        : [0, 0, 0];
      return {
        w,
        h,
        corner: [px[ci], px[ci + 1], px[ci + 2], px[ci + 3]] as [number, number, number, number],
        opaque,
        total: w * h,
        mean,
        light,
        dark,
      };
    },
    { url, w, h },
  );
}

const lum = ([r, g, b]: [number, number, number]) => 0.2126 * r + 0.7152 * g + 0.0722 * b;

test.describe('@visual collateral renders', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/'); // establish the localhost origin for same-origin fetch
  });

  test('README header (light) renders dark ink on transparency', async ({ page }) => {
    const s = await sample(page, '/collateral/readme-header.svg', 1280, 320);
    expect(s.corner[3], 'transparent background corner').toBeLessThan(20);
    expect(s.opaque, 'ink pixels present').toBeGreaterThan(500);
    expect(lum(s.mean), 'ink is dark (Current 950)').toBeLessThan(100);
  });

  test('README header (dark) renders light ink on transparency', async ({ page }) => {
    const s = await sample(page, '/collateral/readme-header-dark.svg', 1280, 320);
    expect(s.corner[3], 'transparent background corner').toBeLessThan(20);
    expect(s.opaque, 'ink pixels present').toBeGreaterThan(500);
    expect(lum(s.mean), 'ink is light (Foam 50)').toBeGreaterThan(150);
  });

  test('social card renders a light lockup on a dark canvas', async ({ page }) => {
    const s = await sample(page, '/collateral/social-card.svg', 1200, 630);
    const [r, g, b] = s.corner;
    expect(r < 60 && g < 60 && b < 60, `dark background corner: ${s.corner}`).toBe(true);
    expect(s.light, 'light lockup/tagline ink present on dark bg').toBeGreaterThan(200);
  });

  test('favicon raster is non-blank', async ({ page }) => {
    const s = await sample(page, '/collateral/favicon-32.png', 32, 32);
    expect(s.opaque, 'mark ink present at 32px').toBeGreaterThan(20);
  });

  test('apple-touch-icon raster shows a dark mark on opaque ground', async ({ page }) => {
    const s = await sample(page, '/collateral/apple-touch-icon.png', 180, 180);
    expect(s.opaque, 'opaque background fills the icon').toBeGreaterThan(180 * 180 * 0.8);
    expect(s.dark, 'dark mark present').toBeGreaterThan(50);
  });

  test('brand book hero paints a dark cover', async ({ page }) => {
    const bg = await page.locator('#hero').evaluate((el) => getComputedStyle(el).backgroundColor);
    const m = bg.match(/\d+/g)!.map(Number);
    expect(lum([m[0], m[1], m[2]]), `hero background ${bg} is dark`).toBeLessThan(80);
  });
});
