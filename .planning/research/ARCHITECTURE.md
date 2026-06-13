# Architecture Research

**Domain:** Brandbook directory integration into an existing Elixir/Phoenix hex.pm library
**Researched:** 2026-06-11
**Confidence:** HIGH (grounded in actual repo inspection)

---

## Standard Architecture

### System Overview

```
crosswake/ (repo root)
├── lib/                          # Elixir source — included in hex package
├── priv/                         # Elixir priv — included in hex package
│   └── templates/crosswake/
│       └── offline_ui/           # Generator templates (brand tokens hardcoded here)
├── test/                         # Tests — included in hex package (mix.exs :files)
├── guides/                       # ExDoc extras — included in hex package
├── examples/phoenix_host/        # Demo app — NOT in hex package (:files allowlist)
│   └── assets/css/app.css        # v8.0 brand token CSS (CSS custom properties)
│
├── brandbook/                    # NEW — NOT in hex package (excluded by allowlist)
│   ├── README.md                 # Overview of the brand system
│   ├── AUDIT.md                  # 14-section brand audit (phase 102)
│   ├── BRAND-SPEC.md             # v1.0 spec, successor to prompts/ draft (phase 106)
│   ├── index.html                # Standalone HTML brand book, no build step (phase 105)
│   ├── assets/                   # Static assets for index.html
│   ├── tokens/
│   │   ├── crosswake.tokens.json # W3C DTCG design tokens (phase 103)
│   │   └── tokens.css            # CSS custom properties derived from JSON (phase 103)
│   ├── logo/                     # Production logo suite — path-only SVGs (phase 104)
│   │   └── tournament/           # 7-candidate tournament gallery HTML (phase 104)
│   ├── collateral/               # README header SVG, social card, favicons (phase 106)
│   └── tools/                    # Node scripts for token generation, WCAG audit
│       ├── package.json          # Node tooling manifest
│       ├── node_modules/         # gitignored
│       └── fonts/                # gitignored (opentype.js processing only)
│
├── mix.exs                       # :files allowlist controls hex exclusion
├── README.md                     # Gets a header image wired in (phase 106)
└── .gitignore                    # Needs brandbook/tools/node_modules + fonts additions
```

### Component Responsibilities

| Component | Responsibility | Notes |
|-----------|----------------|-------|
| `mix.exs :files` allowlist | Declares exactly what ships in the hex tarball | Current value: `~w(lib priv mix.exs README.md LICENSE CHANGELOG.md guides)` — brandbook/ is absent, so it is automatically excluded |
| `brandbook/tokens/tokens.css` | Canonical source of CSS custom properties for the brand system | v8.0 surfaces hardcode their own copies today; this milestone ships the canonical source but does not yet wire dependents |
| `brandbook/tokens/crosswake.tokens.json` | W3C DTCG JSON token tree | Source of truth that `tokens.css` is derived from via a Node script |
| `examples/phoenix_host/assets/css/app.css` | v8.0 runtime brand CSS (16 custom properties + font stacks) | Currently hand-authored, not generated from tokens; remains independent this milestone |
| `priv/templates/crosswake/offline_ui/*.eex` | Generator templates with hardcoded brand Tailwind classes | Uses `cw-foam-50`, `cw-current-950`, `cw-wake-700`, `cw-brass-500` classes; decoupled this milestone |
| `mix.exs docs()` | ExDoc configuration — controls hexdocs branding | Supports `:logo` (PNG/SVG, shown in 48x48px area); no logo key present today |
| `brandbook/tools/` | Node scripts: WCAG contrast matrix, token compilation, SVG validation | node_modules and fonts are gitignored; tools run locally or in advisory CI |

---

## Integration Point Analysis

### (1) Hex Package Exclusion — How It Works Today

The `package/0` function in `mix.exs` uses an **allowlist** (not a denylist):

```elixir
files: ~w(lib priv mix.exs README.md LICENSE CHANGELOG.md guides)
```

This is definitive: only the six listed paths are included in the hex tarball. `brandbook/` does not appear in the list, so it is **automatically excluded** from the hex package without any additional configuration. No `:files` change is required for phases 102–106.

If `brandbook/README.md` is desired on hexdocs as an extra guide page, it would need to be added to `docs() :extras`. This milestone does not require that — `brandbook/` is intentionally self-contained and not part of the public API surface.

### (2) Brand Token Usage Today — Decoupling Decision

Two surfaces currently hardcode brand tokens:

**Surface A — `examples/phoenix_host/assets/css/app.css`** (v8.0, ships with the demo app)
Uses CSS custom properties directly:
```css
:root {
  --cw-current-950: #09141A;
  --cw-wake-700: #2B756A;
  --cw-brass-500: #C98A2E;
  --cw-foam-50: #F7F1E6;
  /* ... 13 more variables, 3 font-family stacks */
}
```
The complete palette: `--cw-current-950/900/800`, `--cw-harbor-700`, `--cw-wake-700/500`, `--cw-kelp-800`, `--cw-brass-500/700`, `--cw-foam-50/100`, `--cw-mist-200`, `--cw-stone-500`, `--cw-rust-600`, `--cw-plum-700`, `--cw-white`.

**Surface B — `priv/templates/crosswake/offline_ui/*.eex`** (v8.0, generator output)
Uses Tailwind utility classes that require host tailwind.config.js registration:
- `offline_root.html.heex.eex`: `bg-cw-foam-50 text-cw-current-950`
- `offline_page.html.heex.eex`: `border-cw-wake-700`, `text-cw-current-950`, `bg-cw-foam-50`, `border-cw-brass-500`, `text-cw-brass-500`

The generator task (`crosswake.gen.offline_ui.ex`) also hard-emits a `tailwind.config.js` snippet defining `cw-wake` (9-stop blue scale) and `cw-brass` (9-stop amber scale). Note: these are a **different palette** from the CSS custom properties — the generator uses blue/amber while app.css uses the teal/warm nautical palette from the actual brand book.

**Recommendation for this milestone:** Keep `brandbook/tokens/tokens.css` and both v8.0 surfaces **decoupled** this milestone. The tokens file becomes the canonical written source, but wiring `examples/phoenix_host/assets/css/app.css` to import from `brandbook/tokens/tokens.css` would create a cross-directory coupling inside the repo that makes the example app harder to reason about in isolation. The generator template Tailwind mismatch (blue vs teal) is a known inconsistency to flag in AUDIT.md but not fix until the token wiring phase after the brand audit verdict is locked.

### (3) README Header Image — URL Convention

**Finding:** Hex docs renders README.md images correctly from absolute `https://raw.githubusercontent.com/...` URLs. Relative paths work on GitHub but break on hexdocs.pm because the rendered page is served from `hexdocs.pm/crosswake/readme.html`, not from a path-relative context.

**Correct pattern** (confirmed by hex package ecosystem inspection):
```markdown
![Crosswake](https://raw.githubusercontent.com/szTheory/crosswake/main/brandbook/collateral/readme-header.svg)
```

**Why not relative:** The file `README.md` is in the repo root. On GitHub, a relative `brandbook/collateral/readme-header.svg` resolves. On hexdocs.pm, ExDoc processes README.md into `doc/readme.html` and relative image paths are not rewritten to absolute URLs — the image 404s.

**Why not `?raw=true`:** The `?raw=true` query parameter works for non-raw GitHub URLs (e.g., blob viewer URLs). `raw.githubusercontent.com` already serves the raw file directly; no query parameter is needed.

**SVG header images:** SVG renders correctly via `raw.githubusercontent.com` on both GitHub and hexdocs.pm for `<img>` tag equivalents in Markdown. GitHub sanitizes `<script>` in SVGs at render time. ExDoc passes image tags through without sanitization concerns for static SVGs.

### (4) ExDoc Logo Option

ExDoc `~> 0.38` (already in deps as `{:ex_doc, "~> 0.38", only: :dev, runtime: false}`) supports the `:logo` option. From current ExDoc documentation:

- Accepts: PNG, JPEG, or SVG
- Behavior: The file is copied to `doc/assets/logo.{ext}` and displayed in a 48x48px area in the hexdocs sidebar header
- Path: relative to the mix project root

To add logo branding to hexdocs, add to `docs/0` in `mix.exs`:

```elixir
logo: "brandbook/logo/crosswake-mark.svg"
```

This is a modification to `mix.exs` (existing file, new key in `docs/0`). The logo file lives in `brandbook/logo/` but the path is valid because `mix docs` runs from the project root. The logo file does **not** need to be in the `:files` allowlist because `mix docs` reads it at doc-generation time, not at hex-publish time.

Current `docs/0` has no `:logo` key — this is a new addition in phase 106.

### (5) .gitignore Additions Required

Current `.gitignore` entries for reference:
```
/_build/
/deps/
/.elixir_ls/
/.mix/
*.beam
.DS_Store
/doc/
/crosswake-*/
/*.tar
erl_crash.dump
/**/_build/
/**/deps/
/**/DerivedData/
/**/build/
/**/.gradle/
/**/local.properties
/.claude/
/.gsd/
/.bg-shell/
```

Required additions for `brandbook/`:
```
# brandbook tooling (Node processing — not committed)
/brandbook/tools/node_modules/
/brandbook/tools/fonts/
```

The `/**/_build/` and `/**/deps/` glob patterns do NOT cover `node_modules` (different name). The existing `/**/_build/` glob catches deeply nested build artifacts but node_modules needs an explicit entry. Two lines added to `.gitignore` is the only modification needed.

### (6) CI Lint/Verify Lane Assessment

**Recommendation: Yes, add a lightweight advisory lane for brandbook verification.** Not overkill given the project's proof-posture philosophy. However, it should be advisory (non-merge-blocking) this milestone and structured to run only when `brandbook/` changes.

Justified checks:
- **Size budget check**: `du -sh brandbook/` with a 1 MB ceiling. Trivial bash, no dependencies. Catches accidental binary commits.
- **SVG validity check**: `xmllint --noout brandbook/logo/**/*.svg` — xmllint ships with macOS and most Linux CI images. Catches malformed path-only SVGs before they silently break in browsers.
- **Token JSON validity**: `node -e "JSON.parse(require('fs').readFileSync('brandbook/tokens/crosswake.tokens.json'))"` — zero-dep Node one-liner. Catches JSON syntax errors in the token file.

Deferred checks (not this milestone):
- WCAG contrast ratio assertions against the final palette — these require the audit verdict to be locked first
- HTML brand book validation — deferred to phase 105 when index.html exists

Pattern: follow the existing hermetic/advisory split (see `phase96-proof-advisory.yml`). New workflow file named `brandbook-verify.yml`, advisory only, triggered on `paths: ['brandbook/**']`.

### (7) Build Order Across Phases 102–106

Dependencies drive the ordering:

```
Phase 102: AUDIT.md
  └── Verdict locks palette (KEEP/TIGHTEN/REWORK) before tokens can be finalized
      └── Phase 103: Tokens (crosswake.tokens.json + tokens.css)
              └── Token values are settled — logos can be rendered with correct palette
                  └── Phase 104: Logo Tournament + Production Logo Suite
                          └── Logo selected — brand book can reference canonical mark
                              └── Phase 105: Standalone HTML Brand Book (index.html)
                                      └── All assets exist — collateral can reference them
                                          └── Phase 106: Collateral + README wiring + ExDoc logo
```

**Rationale:**
- Phase 102 (Audit) must come first because it determines which color values survive and which get REWORK verdicts. Building tokens before the audit locks palette values risks a rebuild.
- Phase 103 (Tokens) must precede logos because logos reference brand colors via CSS variables or hardcoded palette values; those values are not stable until the audit is done.
- Phase 104 (Logos) must precede the HTML brand book because `brandbook/index.html` will display the selected logo mark.
- Phase 105 (HTML brand book) can be built once tokens and logos are settled. It references both.
- Phase 106 (Collateral + wiring) is last — it assembles the final README header from the settled logo, wires the ExDoc `:logo` key, and commits the collateral. Size budget CI can also be added here since the full set of committed assets is known.

**Dependency table:**

| Phase | Input Dependency | Blocking Output |
|-------|-----------------|-----------------|
| 102 — Audit | Existing prompts/ brand draft, v8.0 palette in app.css | Palette verdicts that unlock token values |
| 103 — Tokens | Phase 102 verdict | `tokens.css`, `crosswake.tokens.json` — stable palette |
| 104 — Logos | Phase 103 palette values | Selected production logomark SVG |
| 105 — HTML brand book | Phase 103 tokens, Phase 104 logo | `brandbook/index.html` complete |
| 106 — Collateral + wiring | Phase 104 logo, Phase 105 book | README header, ExDoc logo, BRAND-SPEC.md, `.gitignore`, `mix.exs` `:logo` |

---

## Recommended Project Structure (brandbook/)

```
brandbook/
├── README.md                     # What the brand system is and how to use it
├── AUDIT.md                      # 14-section audit; KEEP/TIGHTEN/REWORK/ADD/REMOVE verdicts
├── BRAND-SPEC.md                 # v1.0 written brand specification
├── index.html                    # Standalone HTML brand book (no build step)
├── assets/
│   ├── brand-book.css            # Styles for index.html only
│   └── brand-book.js             # Minimal interactivity for index.html (if any)
├── tokens/
│   ├── crosswake.tokens.json     # W3C DTCG source of truth
│   └── tokens.css                # Compiled CSS custom properties
├── logo/
│   ├── crosswake-mark.svg        # Production logomark (path-only, no <text>)
│   ├── crosswake-lockup.svg      # Wordmark + mark lockup
│   ├── crosswake-mark-dark.svg   # Dark-background variant
│   └── tournament/
│       ├── index.html            # Gallery of 7 candidates
│       └── candidates/           # Individual candidate SVGs
├── collateral/
│   ├── readme-header.svg         # README hero image
│   ├── social-card.svg           # OG/Twitter card (1200x630)
│   └── favicon.svg               # SVG favicon
└── tools/
    ├── package.json              # Node tooling deps
    ├── node_modules/             # gitignored
    ├── fonts/                    # gitignored (opentype.js processing)
    ├── compile-tokens.js         # tokens.json → tokens.css
    ├── wcag-contrast.js          # Contrast matrix audit script
    └── validate-svgs.sh          # xmllint wrapper
```

---

## New vs Modified Files

### New files (do not exist today)
- `brandbook/` — entire directory is new
- `.github/workflows/brandbook-verify.yml` — advisory CI lane

### Modified files (exist today, need changes)
- `.gitignore` — add `brandbook/tools/node_modules/` and `brandbook/tools/fonts/`
- `mix.exs` — add `logo: "brandbook/logo/crosswake-mark.svg"` to `docs/0` (phase 106 only)
- `README.md` — add header image using `raw.githubusercontent.com` URL (phase 106 only)

### Files that stay unchanged this milestone (by design)
- `mix.exs :files` allowlist — no change needed; brandbook/ excluded automatically
- `examples/phoenix_host/assets/css/app.css` — remains decoupled; brand token values stay hand-authored
- `priv/templates/crosswake/offline_ui/*.eex` — Tailwind class mismatch is flagged in AUDIT.md but not fixed until after palette is locked

---

## Data Flow: Tokens as Source of Truth

```
brandbook/tokens/crosswake.tokens.json   (W3C DTCG — phase 103)
    ↓ (tools/compile-tokens.js)
brandbook/tokens/tokens.css             (CSS custom properties — phase 103)
    ↓ (manual adoption, future milestone)
examples/phoenix_host/assets/css/app.css  (currently hand-authored, decoupled this milestone)
priv/templates/.../offline_root.html.heex.eex  (Tailwind classes, decoupled this milestone)
```

This milestone ships `tokens.css` as the canonical written source but does not wire existing consumers to import from it. Decoupling is the right call here: the audit may change color values (e.g., if `--cw-wake-700` gets a REWORK verdict), and wiring dependents before those verdicts are locked would require a second update pass. The token file becomes authoritative on paper in v9.0; the wiring becomes a v10.0 concern.

---

## Anti-Patterns to Avoid

### Anti-Pattern 1: Denylist instead of relying on the existing allowlist

**What people do:** Add `brandbook/` to a `:excluded_files` or `.hexignore` list.
**Why it's wrong:** The `package()` `:files` list in `mix.exs` is already an **allowlist**. Anything not listed is excluded. Adding a denylist entry is redundant and creates confusion about which mechanism is authoritative.
**Do this instead:** Do nothing. The allowlist `~w(lib priv mix.exs README.md LICENSE CHANGELOG.md guides)` already excludes `brandbook/`.

### Anti-Pattern 2: Committing fonts or node_modules into brandbook/tools/

**What people do:** Commit `node_modules/` or font binary files to avoid a local setup step.
**Why it's wrong:** Font binaries are large, cannot be diffed, and violate the `<1 MB committed` constraint. `node_modules/` would add megabytes and drift from lockfile.
**Do this instead:** `.gitignore` both. The `tools/package.json` lockfile is committed; fonts are processed locally by `opentype.js` and discarded.

### Anti-Pattern 3: Using `<text>` elements in committed SVGs

**What people do:** Generate SVGs with `<text>` for the wordmark during development.
**Why it's wrong:** `<text>` requires the font to be present at render time. If the font isn't embedded or loaded, the glyph fallbacks to the system font, breaking the wordmark.
**Do this instead:** Use `opentype.js` to trace glyphs to path data locally, then commit only the path-based SVG. No font loading required at render time.

### Anti-Pattern 4: Relative image paths in README.md

**What people do:** Write `![header](brandbook/collateral/readme-header.svg)` using a repo-relative path.
**Why it's wrong:** Hexdocs.pm renders README.md at `hexdocs.pm/crosswake/readme.html` and does not rewrite relative image paths. The image 404s in hex docs.
**Do this instead:** Use `https://raw.githubusercontent.com/szTheory/crosswake/main/brandbook/collateral/readme-header.svg` as an absolute URL. This works on both GitHub and hexdocs.pm.

---

## Integration Points Summary

| Integration | Mechanism | Action Required | Phase |
|-------------|-----------|-----------------|-------|
| Hex package exclusion | `:files` allowlist in `mix.exs` | None — automatic | — |
| gitignore for node_modules | `.gitignore` | Add 2 lines | 102 (setup) |
| gitignore for fonts | `.gitignore` | Add 1 line | 102 (setup) |
| ExDoc logo branding | `logo:` key in `docs/0` | Add 1 line to `mix.exs` | 106 |
| README header image | `raw.githubusercontent.com` absolute URL | Modify `README.md` | 106 |
| Token consumers (decoupled) | CSS custom properties | No wiring this milestone | Future v10.0 |
| Advisory CI lane | New workflow YAML | Create `brandbook-verify.yml` | 106 |

---

## Sources

- `mix.exs` (actual repo, inspected 2026-06-11) — `:files` allowlist confirmed as `~w(lib priv mix.exs README.md LICENSE CHANGELOG.md guides)`
- `mix.exs docs/0` — current `:logo` key absent, `:ex_doc ~> 0.38` in deps
- `priv/templates/crosswake/offline_ui/offline_page.html.heex.eex` and `offline_root.html.heex.eex` — brand Tailwind classes confirmed
- `examples/phoenix_host/assets/css/app.css` — 16 CSS custom properties + 3 font-family variables confirmed
- `lib/mix/tasks/crosswake.gen.offline_ui.ex` — Tailwind color definition snippet (cw-wake, cw-brass) confirmed
- `.gitignore` — current entries inspected; no node_modules entry present
- ExDoc `~> 0.38` documentation (hexdocs.pm/ex_doc, fetched 2026-06-11) — `:logo` option confirmed, supports PNG/JPEG/SVG, 48x48px, copied to `doc/assets/logo.{ext}`
- Hex ecosystem inspection (elixir_auth_github preview.hex.pm) — absolute `raw.githubusercontent.com` URLs confirmed as working pattern for hex README images

---
*Architecture research for: v9.0 Brand System & Visual Identity — brandbook/ integration*
*Researched: 2026-06-11*
