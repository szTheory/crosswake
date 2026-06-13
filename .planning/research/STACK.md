# Technology Stack

**Project:** Crosswake (v9.0 Brand System & Visual Identity)
**Researched:** 2026-06-11
**Confidence:** HIGH (all key claims verified via npm registry, Google Fonts, W3C spec, official OFL FAQ)

---

## Scope

This file covers only the NEW tooling required for the `brandbook/` brand system. The existing Elixir/Phoenix library, its CI, and `mix.exs` deps are out of scope and must not be touched. All brand tooling lives under `brandbook/tools/` and `brandbook/node_modules/` (gitignored). A `brandbook/package.json` isolates the npm surface entirely.

---

## 1. Font-to-Path SVG Wordmark Generation

### Recommended: opentype.js 2.0.0

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| `opentype.js` | `2.0.0` (npm, published May 2026) | Convert Space Grotesk glyphs to SVG path data for the wordmark | Actively maintained, 568 dependents, ships ESM + CJS, zero native deps, runs in Node.js without a headless browser |

**Verified:** `npm publish 2.0.0 to latest` workflow completed successfully. GitHub release dated May 6, 2026. The prior npm release was 1.3.4 (2021); 2.0.0 closes that gap.

**Core API pattern for wordmark generation:**

```javascript
import opentype from 'opentype.js';

const font = await opentype.load('brandbook/fonts/SpaceGrotesk-SemiBold.ttf');

// getPath(text, x, y, fontSize, options)
// kerning defaults to true — GPOS and kern tables are both honoured
const path = font.getPath('Crosswake', 0, 0, 72, {
  kerning: true,        // default; explicit for documentation
  features: { liga: true, rlig: true },
});

// toPathData(options)
const d = path.toPathData({
  decimalPlaces: 3,     // precision for committed SVG
  optimize: true,       // merge redundant commands
  flipY: true,          // SVG Y-axis grows down; font Y grows up
});
```

The resulting `d` string is pasted into a `<path>` element in the committed SVG — no `<text>` or `font-face` in the output.

**What to NOT use:**

| Avoid | Reason |
|-------|--------|
| `text-to-svg` (npm) | Wrapper around opentype.js, last published 7 years ago, inactive — use opentype.js directly |
| Python `fonttools` SVGPathPen | Valid alternative but adds a Python toolchain to a Node-first brand workspace; Y-axis flip is a manual step; reserve for font modification workflows, not wordmark scripting |
| `svg-text-to-path` (npm) | Processes existing SVG `<text>` nodes; designed for a different workflow (SVG post-processing) rather than programmatic wordmark generation from scratch |

---

## 2. Font Availability and Weights

### Atkinson Hyperlegible Next — CONFIRMED on Google Fonts

**Finding:** `Atkinson Hyperlegible Next` (the 2024 "Next" version) **is available on Google Fonts** at `fonts.google.com/specimen/Atkinson+Hyperlegible+Next`. It is a distinct, improved successor to the classic `Atkinson Hyperlegible`.

| Font | Weights | Italics | Variable | Source |
|------|---------|---------|----------|--------|
| Atkinson Hyperlegible Next | 200 ExtraLight, 300 Light, **400 Regular**, **500 Medium**, **600 SemiBold**, **700 Bold**, 800 ExtraBold | Yes, all weights | Yes | Google Fonts + Fontsource |
| Space Grotesk | 300 Light, 400 Regular, **500 Medium**, **600 SemiBold**, **700 Bold** | No italics | Yes (wght axis) | Google Fonts |
| JetBrains Mono | 100–800 (8 weights) including **400 Regular**, **500 Medium** | Yes, all weights | Yes (wght axis) | Google Fonts |

**Classic vs. Next:** The original `Atkinson Hyperlegible` has only Regular and Bold (400/700). The `Next` variant adds 5 additional weights, improved kerning, and expanded character set. Use the `Next` variant — it is what the brand spec calls for and is already confirmed on Google Fonts.

**Seed spec check:** All three weights specified in `prompts/crosswake-brand-book.md` are available:
- Space Grotesk: 500, 600, 700 — all present
- Atkinson Hyperlegible Next: 400, 500, 600 — all present
- JetBrains Mono: 400, 500 — all present

**Google Fonts CSS import (brand book HTML):**

```html
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Space+Grotesk:wght@500;600;700&family=Atkinson+Hyperlegible+Next:ital,wght@0,400;0,500;0,600;1,400&family=JetBrains+Mono:wght@400;500&display=swap" rel="stylesheet">
```

**Fontsource self-hosted alternative** (for standalone HTML that must work offline):

```bash
npm install @fontsource-variable/space-grotesk
npm install @fontsource/atkinson-hyperlegible-next
npm install @fontsource-variable/jetbrains-mono
```

The brand book `index.html` should use Google Fonts CDN import (no build step, simple, no committed font binaries). The wordmark generation script downloads the `.ttf` at build time and gitignores the binary.

---

## 3. OFL License — Committing Font Outlines as Logo Artwork

**Verdict: Permitted. No special action required.**

**Sources:** Official OFL FAQ at `openfontlicense.org/ofl-faq/`

All three fonts (Space Grotesk, Atkinson Hyperlegible Next, JetBrains Mono) are released under SIL Open Font License 1.1.

**What the OFL FAQ says explicitly:**

1. **Using font outlines in logos or SVG artwork is unconditionally allowed.** The FAQ states you are "very welcome" to use OFL fonts "to create logos or other graphics." No acknowledgement is required.

2. **The resulting logo artwork is NOT itself OFL-licensed.** Quote: "Referencing or embedding an OFL font in any document does not change the license of the document itself. The requirement for fonts to remain under the OFL does not apply to any document created using the fonts." The committed SVG logo files remain yours (Crosswake project copyright).

3. **Committing path-converted artwork to a public repo is fine.** The OFL's redistribution requirement only applies when you redistribute *the font software itself* (`.ttf`, `.otf`, `.woff`). Path data extracted and embedded into an SVG is the *output of using* the font, not the font software — it is not governed by the OFL.

4. **Reserved Font Names:** Check the OFL.txt bundled with each font download. If RFNs are declared, they only apply if you modify and redistribute the font *as a font* under a new name. They do not apply to SVG path output. For wordmark purposes this is irrelevant.

**Key implication for v9.0:** Download `.ttf` files for generation → run the wordmark script → commit the path-only `.svg` output. Gitignore the `.ttf` files. No font binaries, no OFL compliance issues.

---

## 4. W3C DTCG JSON Format

**Spec status:** First stable version `2025.10` published October 28, 2025. Tooling adoption: Style Dictionary, Tokens Studio, Figma.

**Recommended file extension:** `.tokens.json` (media type `application/design-tokens+json`)

### Token Syntax

All spec-defined properties use a `$` prefix. An object with a `$value` property is a design token.

```json
{
  "color": {
    "$type": "color",
    "current-950": {
      "$value": {
        "colorSpace": "srgb",
        "components": [0.035, 0.078, 0.102],
        "hex": "#09141A"
      },
      "$description": "Primary dark — logo ink, hero background"
    },
    "wake-700": {
      "$value": {
        "colorSpace": "srgb",
        "components": [0.169, 0.459, 0.416],
        "hex": "#2B756A"
      },
      "$description": "Primary action color on light surfaces"
    }
  },
  "spacing": {
    "$type": "dimension",
    "base": {
      "$value": { "value": 4, "unit": "px" },
      "$description": "4px base grid unit"
    }
  },
  "typography": {
    "display-lg": {
      "$type": "typography",
      "$value": {
        "fontFamily": ["Space Grotesk", "ui-sans-serif", "system-ui"],
        "fontSize": { "value": 56, "unit": "px" },
        "fontWeight": 600,
        "lineHeight": 1.14
      },
      "$description": "Hero headline"
    }
  }
}
```

**Defined types in 2025.10 spec:**
`color`, `dimension`, `fontFamily`, `fontWeight`, `duration`, `cubicBezier`, `number`, `strokeStyle`, `border`, `transition`, `shadow`, `gradient`, `typography`

**`$type` inheritance:** A `$type` declared on a group applies to all children that don't override it, reducing repetition.

**For `crosswake.tokens.json`:** Use hex shorthand in `$value` (the `hex` field) for tooling compatibility. The `components` array with `colorSpace: "srgb"` is the canonical form per spec; many tools accept the `hex` shorthand too.

---

## 5. WCAG 2.x Contrast — Dependency-Free Formula

**For the scripted WCAG contrast matrix in the brand audit, implement this directly in Node.js or Elixir — no library needed.**

### Algorithm (WCAG 2.2, updated threshold)

**Step 1 — Convert 8-bit hex channel to linear light:**

```
sRGB = channel_8bit / 255

if sRGB <= 0.04045:
    linear = sRGB / 12.92
else:
    linear = ((sRGB + 0.055) / 1.055) ^ 2.4
```

Note: The spec originally used `0.03928`; corrected to `0.04045` in May 2021. For 8-bit inputs the numerical difference is negligible (max ratio change of 1.00000005), but use `0.04045` for correctness.

**Step 2 — Relative luminance:**

```
L = 0.2126 * R_linear + 0.7152 * G_linear + 0.0722 * B_linear
```

**Step 3 — Contrast ratio (L1 is the lighter of the two):**

```
contrast = (L1 + 0.05) / (L2 + 0.05)
```

Range: 1:1 (identical) to 21:1 (black on white).

**WCAG thresholds:**
- AA normal text (< 18pt / < 14pt bold): **4.5:1**
- AA large text (≥ 18pt / ≥ 14pt bold): **3:1**
- AAA normal text: **7:1**
- AA UI components and graphical objects: **3:1**

**Node.js implementation (no deps):**

```javascript
function linearize(c) {
  const s = c / 255;
  return s <= 0.04045 ? s / 12.92 : Math.pow((s + 0.055) / 1.055, 2.4);
}

function luminance(r, g, b) {
  return 0.2126 * linearize(r) + 0.7152 * linearize(g) + 0.0722 * linearize(b);
}

function hexToRgb(hex) {
  const n = parseInt(hex.replace('#', ''), 16);
  return [(n >> 16) & 255, (n >> 8) & 255, n & 255];
}

function contrast(hex1, hex2) {
  const l1 = luminance(...hexToRgb(hex1));
  const l2 = luminance(...hexToRgb(hex2));
  const [lighter, darker] = l1 > l2 ? [l1, l2] : [l2, l1];
  return (lighter + 0.05) / (darker + 0.05);
}
```

This script can consume `crosswake.tokens.json` directly and emit a markdown contrast matrix as part of the brand audit. No npm dependencies required.

---

## 6. SVG Favicon — Dark Mode and Fallbacks

### Browser Support (verified via caniuse + search, 2025)

| Browser | SVG favicon | `prefers-color-scheme` in SVG | Notes |
|---------|-------------|-------------------------------|-------|
| Chrome 80+ | Yes | Yes | Full support |
| Edge 80+ | Yes | Yes | Full support |
| Firefox 41+ | Yes | Yes | Not for macOS dock pinned tabs |
| Safari < 26 | No | No | Must have PNG fallback |
| Safari 26+ (macOS/iOS) | Yes | Yes | Fixed in Safari 26 |

**SVG favicon with dark mode (embed CSS inside the SVG):**

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32">
  <style>
    .mark { fill: #09141A; }
    @media (prefers-color-scheme: dark) {
      .mark { fill: #F7F1E6; }
    }
  </style>
  <path class="mark" d="...wake mark path data..."/>
</svg>
```

### Required Favicon Set

| File | Size | Use |
|------|------|-----|
| `favicon.svg` | Vector | Modern browsers (Chrome, Firefox, Edge, Safari 26+); dark mode via embedded CSS |
| `favicon-32x32.png` | 32×32 | Browser tab fallback for Safari < 26; general fallback |
| `apple-touch-icon.png` | 180×180 | iOS/iPadOS home screen icon (Safari requires this) |
| `favicon-192x192.png` | 192×192 | Android home screen / PWA manifest |
| `favicon-512x512.png` | 512×512 | PWA splash screen / install dialog |
| `site.webmanifest` | JSON | References 192 and 512 PNG entries |

**Minimal HTML `<head>` block:**

```html
<link rel="icon" href="favicon.svg" type="image/svg+xml">
<link rel="icon" href="favicon-32x32.png" type="image/png" sizes="32x32">
<link rel="apple-touch-icon" href="apple-touch-icon.png">
<link rel="manifest" href="site.webmanifest">
```

**`site.webmanifest`:**

```json
{
  "name": "Crosswake",
  "icons": [
    { "src": "favicon-192x192.png", "sizes": "192x192", "type": "image/png" },
    { "src": "favicon-512x512.png", "sizes": "512x512", "type": "image/png" }
  ]
}
```

A `favicon.ico` (16×16 + 32×32 multi-size) is optional for the brand book's standalone HTML but unnecessary for a project that targets modern browsers. Include it only if the README header or Hex.pm listing needs it.

---

## 7. OG / Social Card Image Requirements

**Raster required — SVG is not supported by any major social platform's crawler.**

| Property | Value | Reason |
|----------|-------|--------|
| Format | PNG or JPEG | JPEG for photographic cards; PNG for clean logos/text (use PNG for Crosswake) |
| Dimensions | **1200×630 px** | Universal across Facebook, X/Twitter large card, LinkedIn, Slack, Discord |
| Safe zone | 1080×600 px inner area | Keep wordmark and tagline inside this; edges may be cropped on mobile |
| Minimum viable size | 600×315 px | Below this, platforms show thumbnail instead of large card |
| File size | Under 300 KB ideally; hard limit 8 MB (Facebook) | Crawler timeout is the real constraint |
| Color space | sRGB | Not CMYK |
| Meta tag | `<meta property="og:image" content="...">` | Absolute URL required |

**For Crosswake's social card:** Generate `brandbook/social/og-card.png` at 1200×630 via the PNG export script (see section 8). Background: `#09141A` (Current 950). Mark + wordmark in Foam 50.

---

## 8. PNG Export from SVG on macOS

### Recommended: `rsvg-convert` via Homebrew

```bash
brew install librsvg   # installs rsvg-convert
```

**Why rsvg-convert over alternatives:**

| Tool | Verdict | Reason |
|------|---------|--------|
| `rsvg-convert` (librsvg) | **Recommended** | Correct SVG renderer (same engine as GNOME), handles viewBox and transforms faithfully, precise `-w` / `-h` flags, scriptable in a shell loop, deterministic output |
| macOS `sips` | Avoid for brand assets | Built-in and zero-install, but struggles with complex SVGs (transforms, filters, embedded CSS); produces distortion at small sizes |
| `qlmanage` | Avoid | Crops incorrectly — renders to full-page screenshot geometry instead of the SVG's own viewport |
| ImageMagick | Acceptable fallback | Larger install (~50 MB), uses its own SVG renderer (not libsvg); less accurate for complex path SVGs; use only if librsvg unavailable |
| Inkscape | Overkill | Excellent accuracy but heavyweight GUI app (~400 MB); not worth it for a brand script |

**Generation script pattern (`brandbook/tools/export-pngs.sh`):**

```bash
#!/usr/bin/env bash
set -euo pipefail
SVG="brandbook/logo/crosswake-logo-horizontal.svg"
OUT="brandbook/dist"
mkdir -p "$OUT"

for SIZE in 32 180 192 512; do
  rsvg-convert -w "$SIZE" -h "$SIZE" "$SVG" > "$OUT/favicon-${SIZE}x${SIZE}.png"
done

# OG card (1200x630 is not square — use the social-card SVG at fixed dimensions)
rsvg-convert -w 1200 -h 630 "brandbook/social/og-card.svg" > "$OUT/og-card.png"
```

**Homebrew availability:** `librsvg` is a standard Homebrew formula, no tap required. It is already present on macOS CI runners that have Homebrew (e.g., GitHub Actions `macos-latest`).

---

## Core Dependencies Summary

### `brandbook/package.json` (isolated from `mix.exs`)

```json
{
  "name": "crosswake-brandbook",
  "private": true,
  "type": "module",
  "scripts": {
    "gen:wordmark": "node tools/gen-wordmark.mjs",
    "gen:tokens-css": "node tools/gen-tokens-css.mjs",
    "gen:contrast-matrix": "node tools/gen-contrast-matrix.mjs",
    "export:pngs": "bash tools/export-pngs.sh"
  },
  "dependencies": {
    "opentype.js": "^2.0.0"
  }
}
```

No build tool, no bundler, no transpiler. Pure ESM scripts consuming a single npm package.

### System Tools (macOS, installed once via Homebrew)

```bash
brew install librsvg   # rsvg-convert for PNG export
```

### What NOT to Add

| Avoid | Reason |
|-------|--------|
| Any Hex package / mix.exs change | Brand tooling must not touch the Elixir library |
| Webpack / Vite / esbuild | No bundling needed — scripts run in Node.js directly |
| Puppeteer / Playwright for PNG export | Headless-browser PNG export is 100× heavier than rsvg-convert; use only if SVG uses WebKit-specific CSS |
| `canvas` npm package | Native bindings, fragile on macOS arm64; rsvg-convert is the right tool for this |
| `svg2png` / `sharp` | These wrap libvips or canvas; more complexity than librsvg for pure SVG rasterisation |
| `text-to-svg` npm | Inactive (7-year-old release); use opentype.js directly |

---

## Alternatives Considered

| Category | Recommended | Alternative | When to Use Alternative |
|----------|-------------|-------------|-------------------------|
| Font-to-path | `opentype.js` 2.0.0 | Python `fonttools` + `svgPathPen` | If you need to modify the font itself (subsetting, glyph editing) — not for wordmark generation |
| PNG export | `rsvg-convert` | `sips` (built-in macOS) | Only for trivially simple path-only SVGs where accuracy is unimportant; never for favicons with embedded CSS |
| Token format | DTCG `2025.10` JSON | Legacy Style Dictionary format | Only for projects locked to Style Dictionary v3 without a migration path |
| Font hosting | Google Fonts CDN | Fontsource self-hosted | Self-host if the brand book HTML must work fully offline or if CDN policy is a concern |

---

## Sources

- `github.com/opentypejs/opentype.js/releases` — v2.0.0 release notes (May 2026), HIGH confidence
- `github.com/opentypejs/opentype.js/actions/workflows/release.yml` — npm publish confirmed, HIGH confidence
- `fonts.google.com/specimen/Atkinson+Hyperlegible+Next` — confirmed available, HIGH confidence
- `fontsource.org/fonts/atkinson-hyperlegible-next` — weights 200–800 confirmed, HIGH confidence
- `github.com/googlefonts/atkinson-hyperlegible-next/blob/main/README.md` — six weights upright + italic, HIGH confidence
- `openfontlicense.org/ofl-faq/` — logo artwork not OFL-licensed, font outlines permitted, HIGH confidence
- `www.designtokens.org/TR/drafts/format/` — DTCG 2025.10 $value/$type/$description syntax, HIGH confidence
- `www.w3.org/community/design-tokens/2025/10/28/design-tokens-specification-reaches-first-stable-version/` — stable spec confirmed Oct 2025, HIGH confidence
- `www.w3.org/TR/WCAG21/relative-luminance.html` — authoritative luminance formula with 0.04045 threshold, HIGH confidence
- `caniuse.com/link-icon-svg` — SVG favicon browser support matrix, HIGH confidence
- Search results corroborated by `blog.tomayac.com`, `browserux.com`, `premiumfavicon.com` — favicon fallback set, MEDIUM confidence
- OG image requirements: `myog.social/articles/og-image-size-guide`, `krumzi.com` 2026 guide — 1200×630 universal, HIGH confidence
- `rsvg-convert` recommendation: `alexadam.medium.com` + `mausic.me/blog/generate-icons-assets-for-website` + search corpus — MEDIUM confidence (empirical, no official "recommendation" document)

---

*Stack research for: Crosswake v9.0 Brand System & Visual Identity*
*Researched: 2026-06-11*
