# Feature Landscape: v9.0 Brand System & Visual Identity

**Domain:** OSS/devtools brand system — design tokens, logo suite, HTML brand book, collateral
**Researched:** 2026-06-11
**Confidence:** HIGH (grounded in public brand pages from Tailwind, Astro, Vercel/Geist, GitHub, Bun; DTCG spec; WCAG tooling; Evil Martians favicon guide; logo presentation research)

---

## Context: What Already Exists

The brand book draft at `prompts/crosswake-brand-book.md` is a 25-section text document covering: palette (16 named tokens with hex values), typography (Space Grotesk / Atkinson Hyperlegible Next / JetBrains Mono), "Wake Mark" logo direction, voice/tone, motifs, component specs, and a do/don't summary. NO visual assets exist yet.

v9.0 deliverables must convert that text specification into audited, implemented, shipped artifacts: an `AUDIT.md` verdict pass, a W3C DTCG token file + CSS, a user-selected logo suite (path-only SVGs), a standalone HTML brand book, and collateral (README header, social card, favicons).

---

## Deliverable 1: Brand Audit (`brandbook/AUDIT.md`)

### Table Stakes

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Verdict per section (KEEP / TIGHTEN / REWORK / ADD / REMOVE) | Any audit without actionable verdicts is just a description | LOW | Every brand book section from `prompts/crosswake-brand-book.md` must get a verdict |
| WCAG contrast matrix for every palette pairing | Non-negotiable for a tool claiming accessibility standards; brand-book draft cites WCAG AA as required | MEDIUM | 16 named tokens = up to 240 pairs; script-generated; flag AA/AAA pass/fail; [palettd.com contrast grid approach](https://palettd.com/tools/contrast-grid) |
| Identified conflicts with competitor visuals | Brand book already names React Native, Hotwire, Phoenix, Capacitor as confusion vectors; audit must verify each | LOW | Cross-check palette, marks, and metaphors against the named competitors |
| Color usage verdict | Checks whether approved pairings actually meet contrast thresholds | LOW | Dependencies: contrast matrix results |
| Typography verdict | Confirms Space Grotesk / Atkinson / JetBrains Mono are still the right choices | LOW | Verify licenses; confirm web-font availability; check fallback stacks |
| Logo direction verdict | Confirms "Wake Mark" concept before investing in 7-candidate tournament | LOW | Flag if concept is too close to existing marks |

### Differentiators

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Rationale-per-verdict prose | Each KEEP/REWORK verdict explains the reasoning, not just the outcome — makes the audit usable as a decision record | LOW | Two–three sentences per verdict; enables future maintainers to understand why |
| Contrast failures with suggested fixes | Rather than just listing failures, audit proposes a corrected token value that passes | MEDIUM | Especially useful for the `--cw-stone-500 / --cw-foam-50` pair which is likely to fail |
| Competitor color distance quantification | Delta-E or simple HSL distance from the four named competitors provides objective guardrails | MEDIUM | Flags where a palette color is dangerously close to React Native cyan or Phoenix flame |

### Anti-Features

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Full rebranding recommendations | Audit scope is the existing brand book, not a strategic rebrand; full rebrand creates scope explosion | Only flag where the existing choices are technically broken (contrast failure, trademark proximity) |
| Subjective design taste verdicts without grounding | "This color feels wrong" is noise | Ground every verdict in a contrast ratio, trademark conflict, or explicit brand-book inconsistency |
| Competitor teardown beyond the named four | Scope creep; Crosswake already has clear guardrails | Stay within the four named competitors: React Native, Hotwire, Phoenix/LiveView Native, Capacitor |

---

## Deliverable 2: Design Tokens (`brandbook/crosswake.tokens.json` + `brandbook/tokens.css`)

### Table Stakes

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| W3C DTCG JSON format with `$value`, `$type`, `$description` | The DTCG spec reached v1 stable in 2025-10; tools expect this format; [DTCG spec](https://www.designtokens.org/); [Style Dictionary DTCG docs](https://styledictionary.com/info/dtcg/) | LOW | Each token needs `$type: "color"` or `"dimension"` etc.; alias tokens use `{token.path}` syntax |
| Three-tier hierarchy: primitives → semantic → state | Industry standard since Tailwind, Material, Atlassian, GitLab Pajamas all use this pattern; [goodpractices.design](https://goodpractices.design/articles/design-tokens); [penpot guide](https://penpot.app/blog/the-developers-guide-to-design-tokens-and-css-variables/) | LOW | Primitives = raw palette; semantic = roles (`background.primary`, `text.accent`); state = interactive variants |
| CSS custom properties output (`tokens.css`) | Developers consuming the brand book need `var(--cw-*)` immediately usable; the brand book draft already uses `--cw-*` naming | LOW | Flat `var()` output; semantic tokens reference primitive tokens; light/dark via `@media (prefers-color-scheme)` or class |
| All 16 palette primitives from the brand book draft | Exact hex values from §8 of the brand book; audit may adjust some based on contrast results | LOW | Current-950 through White; any audit-driven adjustments get logged in AUDIT.md |
| Semantic color roles matching brand-book §8 table | `interactive.primary`, `surface.default`, `text.primary`, `feedback.danger`, `runtime.liveview`, etc. | LOW | Maps "Primary CTA on light → Wake 700 with white text" into tokens |
| Full state tokens for interactive elements | Hover, active, focus, disabled — not just default | MEDIUM | Focus must use Brass 500 ring per brand book §13 button specs; disabled must avoid color-only reliance per §21 |
| Dimension/spacing tokens | Radius (`radius-sm` through `radius-xl`) and spacing scale from §13 layout section | LOW | Already specified in brand book; transcribe into DTCG format |
| Typography tokens | Font family stacks, weight scale, size scale from §9 | LOW | `$type: "fontFamily"`, `$type: "fontWeight"`, `$type: "dimension"` for sizes |
| Light and dark theme variants | Brand book defines both Current 950 dark and Foam 50 light contexts | MEDIUM | Semantic tokens that swap via `prefers-color-scheme` or `.cw-dark` class |

### Differentiators

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| `$description` on every semantic token | Self-documenting token file; AI/LLM consumers can use token purpose without reading the brand book | LOW | One sentence per token: "Primary action color on light backgrounds; requires white foreground text for AA" |
| Runtime-semantic tokens | Crosswake's unique vocabulary: `runtime.liveview`, `runtime.offline`, `runtime.native`, `runtime.sensitive` — these map to the capability ladder | LOW | Differentiates Crosswake's token file from generic design system tokens; directly feeds the demo app and offline UI |
| Explicit forbidden pairings as comment block | `/* DO NOT USE: --cw-stone-500 on --cw-foam-50 — fails AA */` embedded in tokens.css | LOW | Actionable at development time |

### Anti-Features

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Component-level tokens (button.primary.hover.background) | For a library with no UI framework dependency, component tokens add maintenance overhead with zero adoption benefit; [goodpractices.design](https://goodpractices.design/articles/design-tokens) warns against over-creating component-specific tokens | Stop at semantic tokens; component tokens can be derived by adopters |
| Motion/animation tokens | The brand book mentions timing values but they are non-essential for a code library; adds token file complexity | Document timing values as prose in the brand book spec; don't tokenize them in the JSON |
| Figma variable format | Crosswake has no Figma design source; generating Figma-specific tokens without a Figma file creates dead weight | Output DTCG JSON only; tools like Style Dictionary can transform to Figma format if ever needed |
| Token file split into multiple files | For this scale (16 palette + ~30 semantic tokens), a single `crosswake.tokens.json` is simpler to maintain | One file unless the audit phase reveals a compelling split reason |

---

## Deliverable 3: Logo Tournament + Final Logo Suite

### 3a: Tournament Gallery (`brandbook/tournament/index.html`)

#### Table Stakes

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| 7 candidates displayed (4 logomark concepts + 3 typemarks) | Milestone spec; enough variety to make a real selection | HIGH | Each is a path-only SVG created via opentype.js for wordmarks; [opentype.js README](https://github.com/opentypejs/opentype.js/blob/master/README.md) |
| Each candidate shown on light background, dark background, and monochrome | Industry standard for logo presentation; [Astro press page](https://astro.build/press/) provides this for all 6 logo types; Studio Function guide recommends light/dark/mono contexts | MEDIUM | 3 backgrounds × 7 candidates = 21 renderings minimum |
| Each candidate shown at small scale (24–32px) alongside full size | Tests legibility at favicon scale — this is where many marks break | LOW | Inline in the gallery HTML; no separate files needed |
| Annotation with concept name and design rationale | Stakeholders cannot evaluate without understanding intent; [Studio Function guide](https://medium.com/studio-function/logo-design-guide-4-of-5-notes-on-presenting-e1c130974dd0) recommends annotated multi-page PDFs with written rationales | LOW | One paragraph per candidate |
| Mandatory user-selection checkpoint (radio buttons + confirmation) | Milestone requirement; prevents proceeding to production suite without sign-off | LOW | Simple HTML form; no server; stores selection in `localStorage` or produces a visible SELECTED badge |

#### Differentiators

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| In-situ context mocks (browser tab, GitHub repo card, hex.pm listing) | Shows how each candidate actually appears in the real contexts where Crosswake will live; [logo design mockup research](https://digicorns.com/present-logo-designs-mockups/) confirms in-situ mocks are the most persuasive presentation format | MEDIUM | Inline SVG browser-tab mock + GitHub card template per candidate; static HTML, no external assets |
| Side-by-side competitor diff panel | Shows the 4 named competitors (React Native, Hotwire, Phoenix, Capacitor) alongside each candidate to verify no confusion | LOW | High value for OSS where you can't afford to look like a competitor |

#### Anti-Features

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Animated logo presentations | Adds no selection value; breaks focus | Static presentation only |
| More than 7 candidates | Choice overload paralyzes selection; [Studio Function guide](https://medium.com/studio-function/logo-design-guide-4-of-5-notes-on-presenting-e1c130974dd0) recommends 3 concepts minimum, not unlimited options | Cap at 7; 4 logomark + 3 typemark covers the conceptual space |
| External image hosting or CDN dependencies | Tournament gallery must be self-contained | Inline SVGs only; no `<img src="https://...">` |

### 3b: Final Logo Suite (`brandbook/logo/`)

#### Table Stakes

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Primary horizontal lockup (mark + wordmark) | Standard for README, docs header, press mentions; [Astro's press page](https://astro.build/press/) provides this as the first variant; [Tailwind brand page](https://tailwindcss.com/brand) shows logotype as primary | LOW | Light variant + dark variant; path-only SVG |
| Stacked lockup (mark above wordmark) | Social/README hero usage; brand book §10 specifies this | LOW | Light + dark |
| Mark-only (icon without wordmark) | Required for favicon source, app icon, small-space usage; Astro provides "logomark" separately from "logo" | LOW | Works in one color at 16px per brand book spec |
| Monochrome variants (single-color black, single-color white) | Required for print, embossing, contexts with color restrictions; [Astro](https://astro.build/press/) provides explicit "logo on dark" mono variant | LOW | 2 files: black ink, white ink |
| Path-only SVG (no `<text>` element, no font reference) | Milestone requirement; ensures the file renders identically everywhere without font loading; [opentype.js](https://github.com/opentypejs/opentype.js/blob/master/README.md) converts text to `<path>` | HIGH | opentype.js script converts Space Grotesk wordmark to paths; then hand-curate |
| Clear space specification embedded as comment | Consumers need the clear space rule in the SVG file itself; brand book §10 specifies "x-height of wordmark on all sides" | LOW | SVG viewBox with visible clear-space guidelines as removable layer |
| Minimum size specification in file comments | Brand book §10 specifies 128px horizontal, 24px icon, 16px favicon | LOW | Comment in each SVG |

#### Differentiators

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Signal colorway variant (Brass 500 mark on Current 950) | Brand book §10 defines this specific colorway; used for native-screen emphasis; gives collateral and READMEs a distinct visual mode | LOW | One additional SVG file |
| Misuse sheet (6 don't examples) | Prevents corruption in community use; [logo usage guidelines research](https://brandyhq.com/blog/logo-usage-guidelines/) recommends minimum 6 misuse examples | LOW | Can live as a section in the HTML brand book, not a separate file |

#### Anti-Features

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| PNG raster exports in the committed suite | Adds binary weight to the repo; SVGs are infinitely scalable | Export PNGs only for collateral targets (favicon.ico, apple-touch-icon.png, social card); keep SVG as source |
| Logo on colored/gradient rectangular background | Milestone explicitly forbids "rectangular backgrounds"; backgrounds belong to the usage context | Path-only SVGs on transparent backgrounds only |
| Subtitle/tagline on the main lockup | Milestone explicitly forbids "subtitle on the main lockup"; clutters the mark at small sizes | Keep lockup to mark + wordmark only; tagline is a separate typographic element |
| Animated SVG logo files | Complicates downstream use; not needed for a code library | Static only |

---

## Deliverable 4: Standalone HTML Brand Book (`brandbook/index.html`)

### Table Stakes

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| No build step; single HTML file | Milestone requirement; ensures anyone can open it without Node/npm/Webpack; mirrors [devbridge Styleguide](https://devbridge.github.io/Styleguide/) client-side-only approach | MEDIUM | Inline `<style>` and `<script>`; fonts loaded via `@font-face` or Google Fonts CDN link only |
| Live color swatches with copy-to-clipboard hex | Industry standard for brand books used by developers; cited in every "living styleguide" pattern | LOW | One `<button>` per swatch that calls `navigator.clipboard.writeText(hex)` |
| Contrast badges on each swatch pair | WCAG result (AA pass / AA fail / AAA pass) displayed inline; directly addresses the audit matrix requirement | MEDIUM | Badge computed from luminance formula in inline `<script>`; no external library needed |
| Token name displayed with each swatch | Developers copy `--cw-wake-700` not `#2B756A` | LOW | Show both CSS variable name and hex value |
| Type specimens (all three typefaces, all scale steps) | Standard in every brand book; missing this = incomplete identity reference | MEDIUM | Display each weight, size, and use case from brand book §9 |
| Voice do/don't table | Brand book §6 and §23 provide extensive source material; this is table stakes for any copywriter or contributor using the brand book | LOW | Simple two-column table; source is `prompts/crosswake-brand-book.md` §6 and §23 |
| Logo suite display with download links | All logo variants visible inline with `<a href="logo/...svg" download>` | LOW | No ZIP required; individual SVG file links |
| Downloadable asset index | Developers expect to find `brandbook/` paths clearly listed | LOW | A `<table>` or `<dl>` listing every file, its purpose, and its variant |
| Approved color pairings section | Brand book §8 defines 8 explicit approved pairings; these must be visible as rendered examples, not just listed | LOW | Render each pairing as a sample card with foreground text on background color |
| Component specimens (route card, badge, button, code block) | Brand book §13/§19 defines these; the brand book is incomplete if the components are only described in prose | HIGH | The route card and runtime badge are Crosswake's signature visual components; showing them in the brand book is a strong differentiator |
| Sections for all brand pillars (color, type, logo, voice, motif, accessibility, component) | Standard structure seen across GitHub brand toolkit, Astro press page, GitLab Pajamas | MEDIUM | Nav-linked sections in a single-page document |

### Differentiators

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Runtime-semantic color section | Unique to Crosswake; shows `runtime.liveview`, `runtime.offline`, `runtime.native`, `runtime.sensitive` tokens as badge specimens | LOW | No other devtools brand book has a "runtime ownership" color section |
| Inline WCAG contrast checker (two-swatch picker) | Let brand book visitors verify arbitrary pairs interactively | MEDIUM | Two `<select>` elements populated from token list; JS computes ratio; shows AA/AAA result |
| Microcopy library section | Brand book §15 has 30+ ready-to-use strings; expose them as copyable examples | LOW | Expands the brand book from style guide to actual content resource |
| Code block specimen with syntax theme | Shows the exact `Current 900` background, `Foam 50` text, `Wake 500` keywords, `Brass 500` strings syntax theme | LOW | Crosswake's code theme is distinctive; displaying it in the brand book demonstrates the full language |

### Anti-Features

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| External JavaScript framework (React, Vue, Alpine) | Contradicts "no build step, standalone" requirement; adds loading dependency | Vanilla JS only; the swatch copier and contrast checker are < 50 LOC each |
| Figma embed or external design tool iframe | Breaks offline viewing; creates external dependency; not useful for code library consumers | Static HTML specimens only |
| Animation-heavy hero | Brand book §18 specifically limits hero animation to 600–900ms once; a brand book is a reference document, not a landing page | Subtle fade-in at most; content-first |
| Full component library with interactive states | This is a brand book, not a UI kit; interactive forms and full component demos go in a separate package | Show static component specimens; link to example host for interactive demos |
| Hosting on an external CDN without a local copy | Single-file deliverable must work offline | All styles, scripts, and font fallbacks must work without network |

---

## Deliverable 5: Collateral

### 5a: README Header (`brandbook/collateral/readme-header.svg`)

#### Table Stakes

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Horizontal lockup variant appropriate for GitHub README `<img>` | Standard for OSS projects; GitHub renders SVGs in READMEs | LOW | 760px–1200px wide; path-only SVG; light and dark variants |
| One-liner tagline below or beside wordmark | "Route policy for Phoenix apps that go mobile" — identifies the library immediately | LOW | Tagline as path from opentype.js; same constraint as logo |

#### Anti-Features

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Animated GIF header | Common on GitHub but adds visual noise; inconsistent with "calm, technical" brand voice | Static SVG |
| Badge-heavy header (CI, coverage, version) | Badges belong in the README body, not the header art | Wire README badges separately from the header SVG |

### 5b: Social Card (`brandbook/collateral/social-card.png`)

#### Table Stakes

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| 1280×640px PNG (GitHub's recommended size) | [GitHub docs](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/customizing-your-repositorys-social-media-preview): minimum 640×320, recommended 1280×640; safe zone 1080×540 | LOW | Static PNG; brand mark + tagline + package name |
| Dark Current 950 background with Foam 50 text | Uses primary dark colorway per brand book §7; maximizes contrast | LOW | |
| Wake Mark visible at meaningful size | The mark must be recognizable at social card scale | LOW | |
| Package name `crosswake` in JetBrains Mono | Identifies the hex.pm package | LOW | |

#### Differentiators

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Tagline + platform context (Elixir / Phoenix) | "Route policy for Phoenix apps that go mobile" tells the audience immediately what the library is | LOW | |

### 5c: Favicon Suite (`brandbook/collateral/favicons/`)

#### Table Stakes

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| `favicon.ico` (16/32/48px) | Legacy browser support; required | LOW | Derived from mark-only SVG |
| `favicon.svg` | Modern browsers; supports `prefers-color-scheme` dark mode switching; [Evil Martians guide](https://evilmartians.com/chronicles/how-to-favicon-in-2021-six-files-that-fit-most-needs) recommends this as the primary modern favicon | LOW | SVG with embedded `@media (prefers-color-scheme: dark)` |
| `apple-touch-icon.png` (180×180) | iOS home screen; required for any project that might be bookmarked | LOW | |
| `icon-192.png` and `icon-512.png` | Android home screen + PWA splash; [Evil Martians 2026 guide](https://evilmartians.com/chronicles/how-to-favicon-in-2021-six-files-that-fit-most-needs) | LOW | |

#### Anti-Features

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| PNG at every intermediate size (48, 64, 96, 128, 256) | favicon.ico packs 16/32/48; SVG covers the rest; additional PNGs add weight without benefit | Minimal set: ico + svg + apple-touch-icon + 192 + 512 |
| Favicon generated from full horizontal lockup | The wordmark is unreadable at 16px; favicon must use the simplified mark-only | Use the "tiny mark" variant specified in brand book §10 |

---

## Feature Dependencies

```
Brand Audit (AUDIT.md)
    └──may adjust──> Palette primitives in tokens.json
                         └──feeds──> tokens.css (CSS custom properties)
                         └──feeds──> Logo colorways
                         └──feeds──> Social card color choices

Logo Tournament (7 candidates)
    └──requires──> Brand Audit verdict on logo direction
    └──requires──> opentype.js wordmark path generation for typemark candidates
    └──produces (user selection)──> Final Logo Suite

Final Logo Suite
    └──feeds──> README header (horizontal lockup)
    └──feeds──> Social card (mark visible at card scale)
    └──feeds──> Favicon suite (mark-only → favicon.ico, favicon.svg)
    └──feeds──> HTML brand book logo section (display + download links)

tokens.css
    └──feeds──> HTML brand book (live swatches, contrast badges, type specimens)
    └──feeds──> Offline UI in examples/ (existing BRND-01/02 requirement)

HTML brand book (index.html)
    └──includes──> Logo suite (display + downloads)
    └──includes──> Token-driven live swatches
    └──includes──> Type specimens
    └──includes──> Component specimens (route card, badge, button, code block)
    └──includes──> Voice do/don't table
    └──includes──> Downloadable asset index
```

---

## MVP Definition

### Launch With (v9.0)

These are the deliverables specified in the milestone. All are required; none can be deferred.

- [ ] `brandbook/AUDIT.md` — 14-section verdict pass with WCAG contrast matrix
- [ ] `brandbook/crosswake.tokens.json` — W3C DTCG format, three-tier hierarchy, all 16 palette primitives + semantic roles + state tokens + light/dark
- [ ] `brandbook/tokens.css` — CSS custom properties derived from token file
- [ ] `brandbook/tournament/index.html` — 7-candidate gallery, 3-background presentation per candidate, in-situ mocks (browser tab, GitHub card), mandatory user-selection checkpoint
- [ ] `brandbook/logo/` — User-selected candidate refined into production suite: horizontal lockup (light + dark), stacked (light + dark), mark-only (light + dark + monochrome), path-only SVGs, no rectangular backgrounds, no subtitle on main lockup
- [ ] `brandbook/index.html` — Standalone HTML brand book: live swatches, contrast badges, type specimens, voice do/don't table, logo display + download links, asset index, component specimens
- [ ] `brandbook/collateral/readme-header.svg` — Static, path-only, light + dark variants; wired into README
- [ ] `brandbook/collateral/social-card.png` — 1280×640px; wired into GitHub repo settings
- [ ] `brandbook/collateral/favicons/` — favicon.ico + favicon.svg + apple-touch-icon.png + icon-192.png + icon-512.png
- [ ] Size budget verification — entire `brandbook/` directory < 1 MB committed
- [ ] Hex package exclusion — `brandbook/` excluded from `.hex` package to avoid bloating the library download

### Defer to Post-v9.0

- [ ] Animated logo variants — no current use case for a code library
- [ ] Figma source files — no Figma-based workflow exists
- [ ] Print-ready CMYK PDF brand book — no print use case
- [ ] Dark/light mode toggle in HTML brand book — nice to have; `prefers-color-scheme` CSS handles auto-switching without a toggle

---

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Brand audit with WCAG matrix | HIGH | MEDIUM | P1 |
| DTCG token file + CSS | HIGH | LOW | P1 |
| Logo tournament gallery | HIGH | HIGH | P1 |
| Final logo suite (path-only SVGs) | HIGH | HIGH | P1 |
| HTML brand book (live swatches, contrast badges) | HIGH | MEDIUM | P1 |
| HTML brand book (type specimens, voice table) | HIGH | LOW | P1 |
| HTML brand book (component specimens) | HIGH | MEDIUM | P1 |
| README header SVG | MEDIUM | LOW | P1 |
| Social card PNG (1280×640) | MEDIUM | LOW | P1 |
| Favicon suite (5 files) | MEDIUM | LOW | P1 |
| Size budget check + hex exclusion | MEDIUM | LOW | P1 |
| Runtime-semantic tokens in token file | HIGH | LOW | P2 |
| In-situ mock (browser tab + GitHub card) in tournament | HIGH | MEDIUM | P2 |
| Competitor diff panel in tournament | MEDIUM | LOW | P2 |
| Inline contrast checker in brand book | MEDIUM | MEDIUM | P2 |
| Misuse sheet in brand book | MEDIUM | LOW | P2 |
| Microcopy library section in brand book | MEDIUM | LOW | P2 |

**Priority key:**
- P1: Required for v9.0 milestone gate
- P2: High-value additions within milestone scope; include if within complexity budget
- P3: Defer to post-v9.0

---

## Reference Examples

| Project | Brand Asset URL | Key Takeaway |
|---------|----------------|--------------|
| Tailwind CSS | https://tailwindcss.com/brand | Mark + logotype (light/dark) only; trademark rules prominently; minimal set |
| Astro | https://astro.build/press/ | 6 logo types × PNG/SVG; minimum 24px; "Download all" ZIP; permitted/prohibited rules |
| Vercel/Geist | https://examples.vercel.com/geist/brands | Symbol for icon-only contexts; per-product (Next.js, Turbo, v0) variants |
| GitHub | https://brand.github.com/ | Full foundation coverage: logo, type, color, iconography, mascot, motion, in-action |
| Bun | https://bun.com/press-kit | Logo + wordmark + icon in SVG; press kit ZIP; minimal |
| DTCG Spec | https://www.designtokens.org/ | `$value`/`$type`/`$description`; primitives → semantic → alias hierarchy |
| Evil Martians Favicon Guide | https://evilmartians.com/chronicles/how-to-favicon-in-2021-six-files-that-fit-most-needs | Minimal set: favicon.ico + favicon.svg + apple-touch-icon + 192 + 512 |
| Studio Function Logo Presentation | https://medium.com/studio-function/logo-design-guide-4-of-5-notes-on-presenting-e1c130974dd0 | At least 3 concepts; annotated rationale; in-context mockups; size reductions |

---

## Sources

- [Tailwind CSS Brand Page](https://tailwindcss.com/brand) — HIGH confidence; official page; trademark rules + logo variants
- [Astro Press Page](https://astro.build/press/) — HIGH confidence; official page; 6 logo type system, min size, download ZIP
- [Vercel/Geist Brand Guidelines](https://examples.vercel.com/geist/brands) — HIGH confidence; official page; symbol vs wordmark guidance
- [GitHub Brand Toolkit](https://brand.github.com/) — HIGH confidence; official page; foundation sections + in-action categories
- [Bun Press Kit](https://bun.com/press-kit) — HIGH confidence; official page; logo + wordmark + icon SVG set
- [DTCG Design Tokens Spec](https://www.designtokens.org/) — HIGH confidence; W3C community group; v1 stable 2025-10
- [DTCG Practical Guide](https://tasteprofile.io/blog/w3c-dtcg-design-tokens-practical-guide) — MEDIUM confidence; verified against spec; three-tier hierarchy, `$value`/`$type`/`$description`
- [Evil Martians Favicon Guide](https://evilmartians.com/chronicles/how-to-favicon-in-2021-six-files-that-fit-most-needs) — HIGH confidence; widely cited; favicon.ico + SVG + apple-touch-icon + 192 + 512 minimal set
- [GitHub Social Preview Docs](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/customizing-your-repositorys-social-media-preview) — HIGH confidence; official GitHub docs; 1280×640 recommended, 640×320 minimum
- [Studio Function Logo Presentation Guide](https://medium.com/studio-function/logo-design-guide-4-of-5-notes-on-presenting-e1c130974dd0) — MEDIUM confidence; professional studio guide; ≥3 concepts, annotated rationale, in-context mocks
- [Design Tokens Good Practices](https://goodpractices.design/articles/design-tokens) — MEDIUM confidence; verified against DTCG; three-tier structure, avoid over-creating component tokens
- [Palettd Contrast Grid](https://palettd.com/tools/contrast-grid) — MEDIUM confidence; reference for scripted WCAG matrix approach
- [opentype.js README](https://github.com/opentypejs/opentype.js/blob/master/README.md) — HIGH confidence; official repo; text → SVG path generation for wordmarks

---

*Feature landscape for: v9.0 Brand System & Visual Identity*
*Researched: 2026-06-11*
