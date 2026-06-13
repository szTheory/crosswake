# Crosswake Collateral Assets

Derivative assets for repository surfaces and social distribution.

## Assets

| File | Dimensions | Description |
|------|-----------|-------------|
| `readme-header.svg` | wide hero | README header lockup (light mode, transparent background, Foam 50 art) |
| `readme-header-dark.svg` | wide hero | README header lockup (dark mode, transparent background, Current 950 art) |
| `social-card.svg` | 1200×630 source | GitHub/OG social preview source (dark background, lockup + tagline) |
| `social-card.png` | 1200×630 | PNG export of social-card.svg (< 150KB target, sRGB) |
| `favicon-32.png` | 32×32 | Favicon PNG exported from `brandbook/logo/favicon.svg` |
| `apple-touch-icon.png` | 180×180 | iOS home screen icon (opaque Foam 50 background) |

## Social Preview

The GitHub repository social preview (shown in link previews on social media) requires a **manual upload step** that cannot be automated from the repository:

1. Navigate to the GitHub repository: `https://github.com/szTheory/crosswake`
2. Go to **Settings** → **General** → scroll to **Social preview**
3. Click **Edit** → **Upload an image**
4. Upload `brandbook/collateral/social-card.png`
5. Click **Save changes**

GitHub renders this PNG in link previews (Twitter/X, Slack, etc.) at 1200×630. The file must be under 8MB; our target is < 150KB.

## Regenerating Assets

All assets are generated from SVG sources in `brandbook/collateral/` and `brandbook/logo/`:

- SVG edits: update the source file and re-export via `brandbook/tools/render-verify.mjs`
- Token changes: run `node brandbook/tools/compile-tokens.js` then re-export affected SVGs
- Validate SVG structure: `node brandbook/tools/check-production.mjs`
