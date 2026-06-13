import { test, expect } from '@playwright/test';
import { readFileSync, existsSync } from 'node:fs';
import { resolve } from 'node:path';

// Playwright runs from the config directory (brandbook/e2e), both locally and in
// CI (working-directory: brandbook/e2e). Repo root is two levels up.
const REPO = resolve(process.cwd(), '../../') + '/';

const read = (rel: string) => readFileSync(REPO + rel, 'utf8');

// PNG dimensions from the IHDR chunk (no image library needed):
// 8-byte signature, then chunk len(4)+type(4); width@16, height@20 (big-endian).
function pngSize(rel: string): { width: number; height: number; bytes: number } {
  const buf = readFileSync(REPO + rel);
  expect(buf.subarray(0, 8).toString('hex'), `${rel} is a PNG`).toBe('89504e470d0a1a0a');
  return { width: buf.readUInt32BE(16), height: buf.readUInt32BE(20), bytes: buf.length };
}

const COLLATERAL = [
  'brandbook/collateral/readme-header.svg',
  'brandbook/collateral/readme-header-dark.svg',
  'brandbook/collateral/social-card.svg',
  'brandbook/collateral/social-card.png',
  'brandbook/collateral/favicon-32.png',
  'brandbook/collateral/apple-touch-icon.png',
];

const LOGO_SVGS = [
  'crosswake-lockup-horizontal.svg',
  'crosswake-lockup-horizontal-dark.svg',
  'crosswake-lockup-stacked.svg',
  'crosswake-lockup-subtitle.svg',
  'crosswake-mark.svg',
  'crosswake-mark-mono.svg',
  'crosswake-typemark.svg',
  'favicon.svg',
].map((f) => `brandbook/logo/${f}`);

test.describe('@structural brand source assertions', () => {
  test('README header <picture> wires both light + dark raw URLs', () => {
    const readme = read('README.md');
    expect(readme).toContain('<picture>');
    // Dark source.
    expect(readme).toMatch(
      /<source\s+media="\(prefers-color-scheme: dark\)"\s+srcset="https:\/\/raw\.githubusercontent\.com\/szTheory\/crosswake\/main\/brandbook\/collateral\/readme-header-dark\.svg">/,
    );
    // Light default <img>.
    expect(readme).toMatch(
      /<img\s+src="https:\/\/raw\.githubusercontent\.com\/szTheory\/crosswake\/main\/brandbook\/collateral\/readme-header\.svg"\s+alt="Crosswake">/,
    );
  });

  test('mix.exs sets the ExDoc logo and excludes brandbook from the hex package', () => {
    const mix = read('mix.exs');
    expect(mix).toContain('logo: "brandbook/logo/crosswake-mark.svg"');
    expect(mix).toMatch(/exclude_patterns:\s*\[\s*"brandbook"\s*\]/);
    // brandbook must NOT be in the :files allowlist line.
    const filesLine = mix.split('\n').find((l) => l.includes('files:')) ?? '';
    expect(filesLine).not.toContain('brandbook');
  });

  test('all collateral + logo files exist', () => {
    for (const rel of [...COLLATERAL, ...LOGO_SVGS]) {
      expect(existsSync(REPO + rel), `${rel} exists`).toBe(true);
    }
  });

  test('collateral PNGs have exact target dimensions and budget', () => {
    expect(pngSize('brandbook/collateral/social-card.png')).toMatchObject({ width: 1200, height: 630 });
    expect(pngSize('brandbook/collateral/social-card.png').bytes).toBeLessThan(150 * 1024);
    expect(pngSize('brandbook/collateral/favicon-32.png')).toMatchObject({ width: 32, height: 32 });
    expect(pngSize('brandbook/collateral/apple-touch-icon.png')).toMatchObject({ width: 180, height: 180 });
  });

  test('README header SVGs are path-only at the correct viewBox', () => {
    for (const rel of ['brandbook/collateral/readme-header.svg', 'brandbook/collateral/readme-header-dark.svg']) {
      const svg = read(rel);
      expect(svg, `${rel} viewBox`).toMatch(/viewBox="0 0 1280 320"/);
      expect(svg, `${rel} is path-only (no <text>)`).not.toMatch(/<text[\s>]/);
    }
  });

  test('social-card.svg is the 1200x630 OG canvas with a tagline', () => {
    const svg = read('brandbook/collateral/social-card.svg');
    expect(svg).toMatch(/viewBox="0 0 1200 630"/);
    expect(svg).toMatch(/<text[\s>]/); // tagline lives here (PNG-export source only)
    expect(svg).toContain('Declare the crossing.');
  });
});
