# Pitfalls Research

**Domain:** Programmatic Brand System & Visual Identity — OSS Library (v9.0)
**Researched:** 2026-06-11
**Confidence:** HIGH (GitHub SVG sanitization, WCAG thresholds, Hex exclusion), MEDIUM (optical design, typemark), LOW where only community pattern evidence

---

## Critical Pitfalls

### Pitfall 1: Generic Programmatic Marks — The Statistical-Average Logo

**What goes wrong:**
A programmatically-assisted mark (AI-generated or script-driven) looks like the visual centroid of every devtools brand that went before it. The result is unintentionally recognizable as a type — "a tech startup logo" — rather than as Crosswake. Rectangular container backgrounds are a strong symptom: the generator fills empty space with a box because the mark has no inherent optical gravity.

**Why it happens:**
Generative tools fill under-specified briefs with statistical averages. Without strong shape constraints and a concept locked before generation, the output gravitates toward the most common form in training data.

**How to avoid:**
Define the shape vocabulary before running any generator: stroke-based mark, closed contour vs. open path, aspect ratio budget, what the mark must NOT resemble (hexagon, nodes-and-edges graph, circuit trace). The v9.0 plan correctly constrains this to "4 logomark concepts" — lock a concept per candidate before any SVG is drawn, not after. Explicit anti-requirements ("no enclosing rectangle") must be written down and checked at the tournament gate.

**Warning signs:**
- Draft mark fits neatly into a square or rounded-rectangle bounding box with no awkward negative space
- More than two paths have pure 90° or perfect circle geometry
- Removing the background makes the mark look unanchored

**Phase to address:**
Phase 103 (Tournament Gallery) — enforce no-rectangular-background rule at candidate submission. The mandatory user-selection checkpoint is the natural gate.

---

### Pitfall 2: Stroke-Based SVG That Collapses at Small Sizes

**What goes wrong:**
Logomarks authored as stroke paths look refined at 200px but become muddy blobs or invisible hairlines at 16px (favicon) and 32px (GitHub avatar). Stroke weights do not scale with the viewport unless `vector-effect: non-scaling-stroke` is set, and even then the chosen weight may be wrong for the small-size context.

**Why it happens:**
Stroke widths are specified in local coordinate space. When a 200×200 SVG viewport is scaled to 16px display, a 2px stroke in local coords renders as a ~0.16px stroke — sub-pixel and invisible. Conversely, if the artboard is small and scaled up, strokes become disproportionately fat.

**How to avoid:**
- Design the mark at a native small canvas (32×32 or 24×24 local units) and derive large sizes by uniform scale — not the reverse.
- Evaluate every candidate at three sizes: 200px (lockup), 32px (README badge), 16px (favicon). If stroke weight collapses, either outline the stroke paths for production files or create a separate simplified favicon variant.
- For the committed production SVG: outline all strokes to filled paths before finalizing (`Object → Expand` in Inkscape; `Path → Stroke to Path`). Outlined paths render predictably in all environments including GitHub's camo proxy. Keep the live-stroke source in `brandbook/src/` for editability.

**Warning signs:**
- Favicon renders as an indistinct smudge in a browser tab
- Mark was designed at 512px and "scaled down" to test
- `stroke-width` is greater than 1.5 local units on a 24-unit canvas

**Phase to address:**
Phase 104 (Refinement) — 16px and 32px render tests are a required checklist item before finalizing the production suite. Phase 103 should include small-size preview in the tournament gallery HTML.

---

### Pitfall 3: Mark Does Not Survive Monochrome

**What goes wrong:**
The logomark relies on color contrast (e.g., a two-tone mark where one shape reads only because it is a different hue) to convey its structure. On embossed goods, single-ink print, or GitHub's rendered-PNG version, it becomes illegible or looks like a different mark entirely.

**Why it happens:**
Designers evaluate marks on-screen in full color and neglect to flatten to grayscale. Stroke-on-dark-background concepts are especially vulnerable — the fill disappears and only strokes survive.

**How to avoid:**
Require a monochrome version as a mandatory tournament deliverable: positive (black on white), reversed (white on black), and single-color at each of the brand primary hues. If any version fails legibility, the concept fails the tournament. State this explicitly in the gallery brief.

**Warning signs:**
- Logomark uses two shapes that are only distinguishable by fill hue (e.g., two greens)
- Mark lacks readable silhouette when filled solid black
- Reversed version shows only a filled blob with no interior shape distinction

**Phase to address:**
Phase 103 (Tournament Gallery) — monochrome tests must appear alongside full-color renders in the candidate HTML. Phase 106 (Collateral) — commit the monochrome SVGs as part of the production suite.

---

### Pitfall 4: Broken Kerning and Letterform Cuts After Path Conversion

**What goes wrong:**
After converting the Space Grotesk wordmark to outlines via opentype.js, default font kerning tables no longer apply. The letter spacing that looked correct as a live text element becomes subtly wrong — pairs like `ro`, `wa`, `ke` have gaps that look correct at body-copy size but are obviously wrong at logo scale (100×+ larger than paragraph text).

**Why it happens:**
Font kerning tables are designed for paragraph-scale reading. At logo scale, the visual gaps between letters are magnified and the optical illusion of even spacing breaks. opentype.js does support GPOS and kern-table kerning at render time, but once paths are exported as static SVG, no dynamic kerning adjustments apply. Additionally, the Y-axis coordinate system in fonts (cartesian, bottom-up) must be explicitly inverted for SVG (top-down); opentype.js's `getPath()` requires calculating the correct Y-flip from `font.ascender` — missing this produces a vertically mirrored glyph.

**How to avoid:**
- When calling `font.getPath(text, x, y, size)`, pass `y = font.ascender * (size / font.unitsPerEm)` to set the correct baseline.
- After path generation, load the SVG at 400%+ zoom and manually inspect every adjacent glyph pair. Hand-adjust path positions for optically bad pairs (`rk`, `os`, `aw`, `ke`). The path-converted wordmark is the starting point for hand-curation, not the finished artifact.
- Never attempt cutout subpath fills (e.g., letters like `e`, `o`, `a` with counters) without verifying fill-rule: opentype.js TTF outlines rely on path direction for cutouts, while SVG uses `fill-rule="evenodd"` or `nonzero`. Set `fill-rule="evenodd"` on the wordmark path group to match font rendering conventions.

**Warning signs:**
- The exported wordmark SVG has vertically flipped letterforms
- The `e` and `o` counters appear filled (solid black) instead of hollow
- Spacing looks correct at thumbnail size but reveals gaps at 4× zoom

**Phase to address:**
Phase 102 (Audit/Tokens) — establish the opentype.js generation pipeline and validate output. Phase 104 (Refinement) — hand-curation checkpoint explicitly required before production sign-off.

---

### Pitfall 5: Raw-Color-Only Tokens Without a Semantic Layer

**What goes wrong:**
The token file contains only primitives — `color.blue.500: #2563eb`, `color.gray.200: #e5e7eb` — with no semantic aliases. Components then reference raw primitives directly (`background: var(--color-blue-500)`) making theming, dark-mode adaptation, and any future palette shift require hunting every component individually.

**Why it happens:**
Primitive tokens are fast to generate and feel "done." The semantic layer requires design intent that isn't obvious until something needs to change.

**How to avoid:**
The DTCG three-tier architecture is mandatory for v9.0:
- **Tier 1 (primitive):** `color.brand.teal.500`, `color.neutral.800`
- **Tier 2 (semantic):** `color.surface.default`, `color.text.muted`, `color.accent.primary`, `color.feedback.error`
- **Tier 3 (component, optional):** `badge.background`, `button.primary.hover`

Components must reference only Tier 2 tokens. Tier 1 tokens are for the token file internals only. Document this rule in `tokens.css` with a comment header. The DTCG `$value` references between tiers make this explicit in `crosswake.tokens.json`.

**Warning signs:**
- The CSS file contains `var(--color-blue-500)` in component rules rather than `var(--color-accent-primary)`
- Dark mode theme requires touching more than 5-10 token overrides
- Adding a new brand color requires grep-replacing raw hex values across component CSS

**Phase to address:**
Phase 102 (Audit/Tokens) — the semantic layer design is the critical deliverable, more important than the primitive palette. Structure tokens.css with explicit tier-separation comments.

---

### Pitfall 6: GitHub SVG Sanitization Stripping Layout-Critical Attributes

**What goes wrong:**
The SVG committed to `brandbook/` or referenced in `README.md` renders correctly locally and in Figma but looks wrong on GitHub's rendered preview because GitHub's sanitizer strips certain SVG attributes.

**Confirmed stripped by GitHub (via Camo proxy):**
- `dominant-baseline` on `<text>` elements — causes text misalignment
- `<foreignObject>` — entirely removed (no HTML in SVG on GitHub)
- `<script>` — removed (XSS vector)
- Event handlers (`onload`, `onclick`, `onerror`, etc.) — removed
- External `href` and `xlink:href` pointing to remote URLs — blocked
- `<animate>`, `<animateTransform>`, `<set>`, `<animateMotion>` — historically unreliable; treated as blocked

**Why it happens:**
GitHub routes all SVG assets through the Camo anonymizing proxy which applies an allowlist-based sanitizer. The list is conservative and security-focused, not rendering-quality-focused.

**How to avoid:**
- **Never use `<text>` elements in committed production SVGs.** The v9.0 plan already mandates this (wordmarks as path-only). This is the correct call.
- Avoid any positioning technique that relies on `dominant-baseline`, `text-anchor`, or `alignment-baseline`.
- Use only inline CSS or presentation attributes for styling (no `<style>` blocks referencing external sheets; GitHub strips external refs).
- Dark mode in GitHub README: use GitHub's native picture element approach for `prefers-color-scheme` in Markdown:
  ```markdown
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="brandbook/logo-dark.svg">
    <img src="brandbook/logo-light.svg" alt="Crosswake">
  </picture>
  ```
  Do NOT rely on `@media (prefers-color-scheme: dark)` inside the SVG — it works in Chrome/Firefox but fails in Safari and does not respect GitHub's user-configured theme setting.
- `currentColor` in SVGs referenced via `<img>` tags does not inherit from the parent DOM. Only works for inline SVGs, which GitHub does not render.

**Warning signs:**
- SVG has `<text>` elements with `dominant-baseline` or `alignment-baseline`
- SVG uses `@media (prefers-color-scheme: dark)` for theming and is referenced via `<img>`
- SVG uses `xlink:href` pointing to external URLs

**Phase to address:**
Phase 105 (HTML Brand Book) — the brand book itself is not GitHub-rendered, so more SVG features are available there. Phase 106 (Collateral/README) — apply strict sanitization-safe rules for README header SVGs.

---

### Pitfall 7: Brand Assets Leaking Into Published Hex Package

**What goes wrong:**
`brandbook/` ships inside the published Hex package, bloating every downstream `deps/crosswake` installation with SVGs, the HTML brand book, and token artifacts that adopters have zero use for.

**Why it happens:**
The Hex `:files` default is path-based allowlisting, not denylisting. If `brandbook/` is added to the repo without explicitly excluding it, and the default `:files` list includes wildcards or the directory happens to fall under an included path, it gets packaged.

**Concrete Hex mechanism:**
The default `:files` list is `["lib", "priv", ".formatter.exs", "mix.exs", "README*", ...]`. A `brandbook/` directory at repo root is NOT in the default list, so it would be excluded by default — BUT only if `:files` is left as the default. If the project's `mix.exs` has customized `:files` to include `"*"` or a broad wildcard, `brandbook/` would be swept in.

**How to avoid:**
Add an explicit `:exclude_patterns` entry in `mix.exs` as a belt-and-suspenders guard regardless of `:files` configuration:

```elixir
defp package do
  [
    files: ["lib", "priv", ".formatter.exs", "mix.exs", "README.md", "LICENSE*", "CHANGELOG*"],
    exclude_patterns: ["brandbook", "brandbook/*", ".planning", ".planning/**/*"]
  ]
end
```

Verify with `mix hex.build` and inspect the generated `.tar` to confirm `brandbook/` is absent before any release.

**Warning signs:**
- `mix hex.build` tarball size increases by more than ~50KB after brand assets are committed
- `tar -tf crosswake-X.Y.Z.tar` output lists any `brandbook/` paths

**Phase to address:**
Phase 106 (Collateral/Integration) — verify exclusion as part of the pre-release size-budget verification step. This is a one-time `mix.exs` configuration fix.

---

## Moderate Pitfalls

### Pitfall 8: Optical Centering vs. Geometric Centering in Lockups

**What goes wrong:**
The logomark or typemark is mathematically centered in its bounding box but visually reads as sitting too low or too high. This is especially acute for marks with heavy visual weight at the top (uppercase-heavy wordmarks) or marks with prominent descenders.

**Why it happens:**
The human eye perceives the optical center of a shape as slightly above the geometric midpoint. Round and pointed shapes (like `o`, `c`, triangular marks) appear to sit above the baseline unless given a small overshoot downward. This is the same principle behind font overshoots.

**How to avoid:**
After geometric positioning, step back and evaluate whether the mark "feels" centered. For type-heavy lockups: nudge the wordmark 2-4% upward from geometric center. For logomark-plus-wordmark: the mark's visual weight should feel equal, not its bounding boxes equal. Reference how Google's Product Sans uses 2% over-sized circles for optical correctness.

**Warning signs:**
- Lockup looks correct in the vector editor at 100% zoom but slightly top-heavy when viewed as a thumbnail
- The wordmark was placed using "align center to artboard" without visual review afterward

**Phase to address:**
Phase 104 (Refinement) — optical correction review is part of the post-selection polish pass.

---

### Pitfall 9: Token Naming Convention Churn and Premature Explosion

**What goes wrong:**
Token names are not settled before implementation begins. Mid-implementation someone renames `--cw-color-accent` to `--cw-accent-primary` to `--cw-color-primary-action`. Components reference stale token names, CSS variables produce silent failures (returns `initial`), and the token file has orphaned entries.

**Why it happens:**
Naming tokens is the most contentious part of a token system. Without documented conventions and a committed tier structure, names evolve organically and diverge across files. The DTCG spec's `$value` referencing between tiers means a rename ripples through the entire file.

**How to avoid:**
Decide and document the naming convention in Phase 102 before writing a single token:
- Namespace: `crosswake.*` or `cw.*` (choose one, never mix)
- Case: kebab-case throughout (the spec is case-sensitive and does not normalize)
- Pattern: `[namespace].[tier].[category].[variant].[property]` — only include levels that add clarity
- Semantic tier is the public contract; primitive tier is internal; no component token references a primitive directly

Cap token count at v1.0: aim for ~30 semantic tokens and ~20 state tokens (hover, active, disabled, focus). Resist adding component-level tokens until a concrete reuse case exists.

**Warning signs:**
- Token file has more than 100 entries before any component has shipped
- CSS file mixes `--color-blue-500` and `--color-accent-primary` for the same property
- Token names include color values in the name (e.g., `--cw-warm-taupe-bg`)

**Phase to address:**
Phase 102 (Audit/Tokens) — naming decisions are the primary Phase 102 deliverable. Lock names before generating `tokens.css`.

---

### Pitfall 10: WCAG Contrast Failures With Muted Palettes

**What goes wrong:**
Muted, warm, or desaturated brand palettes concentrate tokens in the mid-tone range (relative luminance 0.15–0.55) where contrast failures cluster. A `#9e9e9e` neutral on white (#ffffff) produces a 2.85:1 ratio — failing the 4.5:1 AA requirement for normal text. Badge backgrounds using a pastel brand color with dark text frequently fail 3:1 non-text contrast.

**Specific WCAG thresholds to build into the audit matrix (WCAG 2.1 AA):**
- Normal text (< 18pt / < 14pt bold): **4.5:1 minimum**
- Large text (≥ 18pt or ≥ 14pt bold): **3:1 minimum**
- Non-text UI (icons, borders, badges conveying state, chart elements): **3:1 minimum**
- Logotype/brand marks: **exempt from 1.4.3** but UI badges/status marks are NOT exempt
- AAA text enhancement: 7:1 normal, 4.5:1 large

**Why it happens:**
Designers evaluate palette aesthetics on calibrated displays that may not surface the failure. Warm neutrals "feel" accessible because they read as visible, but the luminance math reveals failures. Mid-tone text (muted gray) on off-white backgrounds is the most common failure point.

**How to avoid:**
The Phase 102 audit requires a scripted WCAG contrast matrix of every palette pairing — this is the correct prevention. Build the script to use the WCAG 2.1 relative luminance formula (not approximate contrast tools). Flag every pairing below 4.5:1 for normal text use and below 3:1 for UI components. Establish approved token pairs (`text.muted on surface.default` passes at X:1) and document them in `BRAND-SPEC.md`.

Specific guidance for muted palettes: secondary/muted text tokens must resolve to luminance values that produce at least 4.5:1 against the primary surface token. If the muted tone fails, darken it until it passes — preserve the hue, shift lightness.

**Warning signs:**
- Brand palette has several mid-range neutral tones without explicit approved-use pairings
- The audit matrix script has not been run (don't defer this to Phase 105)
- Badge colors use the same pastel hue for both background and border

**Phase to address:**
Phase 102 (Audit/Tokens) — scripted contrast matrix is a required deliverable. Phase 105 (HTML Brand Book) — the brand book must render each color swatch with its contrast ratio against default surface.

---

### Pitfall 11: x-Height / Cap-Height Mismatch in Lockups

**What goes wrong:**
The logomark height is sized to match the wordmark's cap-height but is optically oversized or undersized because the two shapes have different visual weight distributions. A square logomark aligned to cap-height will read as taller than the text because its visual mass extends to both extremes of the bounding box; a round mark aligned the same way reads as smaller.

**Why it happens:**
Different shape classes have different optical size relationships to cap-height. Text typographers solve this with overshoots; logo designers must apply the same logic manually.

**How to avoid:**
Size the logomark so that its visual midline matches the wordmark's visual midline, not their bounding boxes. For a round mark, this typically means sizing it to cap-height minus 8-12%. For a compact geometric mark, it may mean sizing to x-height plus optical padding. Test by squinting at the lockup — the mark and wordmark should feel the same visual weight.

**Warning signs:**
- Lockup was composed by aligning top edges of mark and wordmark bounding boxes
- Different lockup sizes produce different apparent mark-to-wordmark weight relationships

**Phase to address:**
Phase 104 (Refinement) — lockup assembly is the Phase 104 deliverable. Check multiple scale sizes.

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|------------------|----------------|-----------------|
| Keep `<text>` elements in SVG (skip path conversion) | Faster authoring, easy edits | Breaks when font missing; GitHub sanitizer strips alignment attributes; text re-flows at unexpected sizes | Never for committed production SVGs |
| Reference raw primitive tokens in components | Faster CSS authoring | Dark mode requires touching every component; palette shift causes global grep-replace | Never — always route through semantic tier |
| Single lockup SVG without light/dark variants | One file to maintain | Looks wrong on GitHub dark-mode; invisible reversed on dark README | Never for README header |
| Use stroke paths without outlining for production SVGs | Preserves editability | Inconsistent rendering across environments; weight collapses at small sizes | Acceptable for source files in `brandbook/src/` only; outlined versions are the production commits |
| Skip monochrome versions at tournament stage | Faster tournament iteration | Winning concept may not survive monochrome; expensive to discover at Phase 104 | Never — require monochrome in Phase 103 |
| Omit `:exclude_patterns` from mix.exs (relying on default `:files`) | Less mix.exs ceremony | One future `:files` edit could silently include `brandbook/`; no explicit audit trail | Never — be explicit |

---

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|-----------------|
| opentype.js Y-axis | Passing `y=0` to `font.getPath()` — produces glyphs below the origin, renders invisible or at wrong baseline | Compute `y = font.ascender * (fontSize / font.unitsPerEm)` — matches the SVG coordinate origin |
| opentype.js fill-rule | Exporting letterform paths and expecting CSS default `fill-rule="nonzero"` to render counters (e, o, a) correctly — produces solid filled letters | Set `fill-rule="evenodd"` on the path group; TTF outline winding direction expects evenodd semantics in SVG |
| GitHub picture/source dark mode | Using `@media (prefers-color-scheme: dark)` inside an `<img>`-referenced SVG | Use GitHub's `<picture><source media="(prefers-color-scheme: dark)" srcset="...">` Markdown extension |
| SVGO id removal | Running SVGO with `cleanupIds: true` on shared SVGs that use `<defs>` with referenced IDs | Set `cleanupIds: false` or use prefixed IDs; removing IDs breaks `url(#clip)` references |
| Hex `:files` wildcard | Adding `"*"` or a broad directory pattern to `:files` in mix.exs to catch README, LICENSE etc. | List files explicitly; add `:exclude_patterns: ["brandbook", ".planning"]` as a guard |

---

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Unoptimized SVG coordinate bloat | Brand book HTML loads slowly; SVG files are 50–300KB when they should be 2–10KB | Run SVGO with `floatPrecision: 2`, `multipass: true`, `removeViewBox: false`; verify output still renders correctly | Day 1 if generation pipeline has no SVGO step |
| High-precision generative paths | opentype.js `getPath()` outputs 6-decimal coordinates; 1000-glyph wordmark produces 100KB+ path data | Round path coordinates to 2 decimal places post-generation; verify no visual regression at 4× zoom | Brand book HTML page feels sluggish |
| Binary asset churn in git history | Repo clone time grows; contributors notice slow checkout | Keep `brandbook/src/` source files text-only (SVG); never commit rasterized PNGs >100KB; generate PNGs from SVG in CI if needed | After 3-4 rounds of tournament candidate replacement |

---

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| Committing font binary to repo | Possible OFL license edge-case for embedded binaries; repo size bloat | Space Grotesk is SIL OFL 1.1 — embedding is permitted; but prefer referencing opentype.js at build time and NOT committing the `.ttf`/`.woff2` binary to the repo; add to `.gitignore` |
| SVG with inline `<script>` or event handlers | XSS vector if SVG ever rendered inline in a web context; GitHub strips them anyway | Path-only SVGs have no scripts — this pitfall is avoided by the design constraint |
| External URL references in SVG `href` | GitHub Camo blocks them; also a privacy leak (third-party can track viewers) | All assets must be self-contained; no external font loads, no remote image refs |

---

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| Brand book over-specification | Nobody reads or maintains it; guidelines become stale and contradicted by actual product | Scope the HTML brand book to: color system, type scale, logo usage, spacing tokens, one-page voice guide with examples — not exhaustive rule catalogues |
| Voice guide that lists adjectives without examples | "Be direct, be human, be curious" means nothing actionable to a contributor writing docs or error messages | Provide 3-4 before/after copy examples for each voice principle; skip adjectives that have no example |
| Devtools brand clichés: hexagons, abstract nodes, circuit traces, gradient meshes | Brand reads as generic "tech startup from 2015"; loses memorability; undermines Crosswake's route-boundary differentiation story | The visual language should reflect what Crosswake actually does: explicit boundaries, clean separation, route ownership — think edges, gates, thresholds, not connectivity metaphors |
| Subtitle text in the main lockup | Taglines in lockups become outdated, reduce mark versatility, and look amateur on small surfaces | No subtitle in the primary lockup; tagline lives in brand copy, not in the SVG mark |
| README header too wide / too tall | On mobile GitHub views, an oversized header forces scroll before any project description | Cap SVG viewport to 400px wide, 80-100px tall for the primary README lockup |

---

## "Looks Done But Isn't" Checklist

- [ ] **Wordmark path conversion:** Rendered at 400% zoom and kerning pairs hand-reviewed — not just exported from opentype.js
- [ ] **Token semantic layer:** `tokens.css` uses only semantic tier (`--cw-color-accent-primary`) in component rules — not `--cw-color-blue-500`
- [ ] **Monochrome versions:** All production mark variants have positive, reversed, and single-color versions tested
- [ ] **16px favicon:** Tested in an actual browser tab, not just in a vector editor at small zoom
- [ ] **GitHub rendering:** README SVG renders correctly on `github.com` (not just local preview) — both light and dark themes
- [ ] **WCAG matrix:** All text-on-surface token pairs confirmed passing; matrix script run, not eyeballed
- [ ] **Hex exclusion:** `mix hex.build` tarball inspected — no `brandbook/` paths present
- [ ] **SVG no-text check:** `grep -r '<text' brandbook/*.svg` returns empty
- [ ] **No rectangular background:** All committed logomarks have no enclosing rectangle or square container element
- [ ] **Stroke outlines:** Production SVGs have strokes converted to filled paths; source files with live strokes are in `brandbook/src/` only
- [ ] **Size budget:** `du -sh brandbook/` is under 1MB as specified in v9.0 constraints

---

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Generic marks discovered post-tournament | HIGH — requires re-running tournament | Return to Phase 103 concept brief; add explicit anti-requirements for the replacement candidates |
| `<text>` elements found in committed SVGs | LOW | Run opentype.js conversion pass; re-export paths; re-commit; no release impact |
| Token naming churn mid-implementation | MEDIUM | Enumerate all usages with `grep -r`; bulk rename in one commit; add comment header enforcing the naming contract |
| `brandbook/` found in published package | LOW | Add `:exclude_patterns` to mix.exs; publish patch release; no user-facing behavior change |
| WCAG failures discovered post-brand-book ship | MEDIUM | Update semantic token values only (primitives may not need to change); regenerate `tokens.css`; update brand book swatches |
| Stroke-weight collapse at 16px found post-selection | MEDIUM | Outline strokes for production files; optionally create a simplified favicon-specific mark variant; no tournament re-run needed |
| opentype.js Y-axis flip in path data | LOW | Fix `y` argument in generation script; regenerate paths; hand-review kerning again |

---

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|-----------------|--------------|
| Generic marks / rectangular containers | Phase 103 | Anti-requirements checklist reviewed at candidate submission |
| Stroke collapse at 16px | Phase 103 (gallery preview) + Phase 104 | Render test at 16px and 32px before finalizing |
| Mark fails monochrome | Phase 103 | Monochrome render required alongside color in gallery |
| Broken kerning / Y-axis flip after path conversion | Phase 102 (pipeline) + Phase 104 | 400% zoom review; fill-rule check; counters visually hollow |
| Raw-color tokens without semantic layer | Phase 102 | `tokens.css` tier-separation audit; no primitive refs in component rules |
| GitHub SVG sanitization (`<text>`, `dominant-baseline`) | Phase 105/106 | `grep '<text'` on committed SVGs; README render check on github.com |
| Hex package brand asset leak | Phase 106 | `mix hex.build` tarball inspection before release |
| WCAG contrast failures | Phase 102 | Scripted contrast matrix; all text pairs confirmed ≥ 4.5:1 |
| Token naming churn | Phase 102 | Convention documented and frozen before `tokens.css` generated |
| Optical centering errors | Phase 104 | Lockup review at multiple scales (thumbnail to large) |
| x-height mismatch in lockup | Phase 104 | Squint test + multiple scale check |
| Over-specified brand book | Phase 105 | Scope gate: brand book is limited to color, type, logo, spacing, voice-with-examples only |
| Devtools clichés in mark design | Phase 103 | Concept brief must name explicitly forbidden shape families before generation |

---

## Sources

- GitHub SVG sanitization — `dominant-baseline` removal confirmed: [SVG sanitizer is affecting SVG layout · github/markup#1160](https://github.com/github/markup/issues/1160)
- GitHub dark mode SVG for READMEs: [Investigating dark mode for SVGs in GitHub READMEs — Dries Vints](https://driesvints.com/blog/investigating-dark-mode-for-svgs-in-github-readmes)
- GitHub native dark-mode picture element approach: [HOWTO: Dark Mode README Logo on GitHub](https://paul.af/github-readme-dark-mode)
- SVG `currentColor` limitations in `<img>`-referenced files: [SVGs in dark mode — Jeremy Keith](https://adactio.medium.com/svgs-in-dark-mode-565ec64004db)
- WCAG 2.1 contrast thresholds (4.5:1 normal, 3:1 large text, 3:1 non-text): [Understanding SC 1.4.3: Contrast (Minimum) — W3C](https://www.w3.org/WAI/WCAG21/Understanding/contrast-minimum.html)
- WCAG 1.4.11 non-text contrast (3:1 UI components, graphical objects): [1.4.11 Non-Text Contrast — Deque University](https://dequeuniversity.com/resources/wcag2.1/1.4.11-non-text-contrast)
- DTCG three-tier token architecture and naming pitfalls: [W3C DTCG design tokens: a practical guide — Taste Profile](https://tasteprofile.io/blog/w3c-dtcg-design-tokens-practical-guide)
- Token naming conventions: [Design Token Naming Conventions — Always Twisted](https://www.alwaystwisted.com/articles/design-token-naming-conventions)
- opentype.js Y-axis / kerning issues: [getPath kerning support · opentypejs/opentype.js#187](https://github.com/opentypejs/opentype.js/issues/187); [SVG y-Axis conversion · opentypejs/opentype.js#724](https://github.com/opentypejs/opentype.js/issues/724)
- opentype.js cutout fill-rule: [Cutout subpaths · opentypejs/opentype.js#347](https://github.com/opentypejs/opentype.js/issues/347)
- Hex package `:files` and `:exclude_patterns`: [mix hex.build — Hex docs](https://hex.hexdocs.pm/Mix.Tasks.Hex.Build.html)
- SVG stroke vs outlined paths scaling: [Fills and strokes — MDN](https://developer.mozilla.org/en-US/docs/Web/SVG/Tutorial/Fills_and_Strokes)
- SVGO precision and viewBox pitfalls: [SVG Optimization for Web Performance — Vectosolve](https://vectosolve.com/blog/svg-optimization-web-performance-2025)
- Optical corrections in logo design: [The Designer's Secret: Optical Adjustments in Logo Design — Logodesign.net](https://www.logodesign.net/blog/optical-adjustments-in-logo-design/)
- Monochrome logo testing: [Logo Lab — data-driven logo testing](https://logolab.app/)
- Devtools brand clichés (hexagons, gradients, nodes): [AI Branding: Sparkles, Gradients, Hexagons — Jason Pryslak / Medium](https://medium.com/@jpriceless/ai-branding-sparkles-gradients-hexagons-and-other-emerging-ai-logo-mark-patterns-12b4fd252709)
- Space Grotesk license (SIL OFL 1.1, commercial embedding permitted): [Space Grotesk — Font Squirrel](https://www.fontsquirrel.com/license/spacegrotesk); [GitHub — floriankarsten/space-grotesk](https://github.com/floriankarsten/space-grotesk)
- Mid-tone contrast failure patterns: [WebAIM Contrast and Color Accessibility](https://webaim.org/articles/contrast/)

---
*Pitfalls research for: v9.0 Brand System & Visual Identity — programmatic SVG logo generation, design tokens, WCAG, repo hygiene, brand book*
*Researched: 2026-06-11*
