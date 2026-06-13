---
phase: 106-collateral-integration-closeout
verified: 2026-06-13T06:34:00Z
status: verified
score: 4/4
overrides_applied: 0
human_verification_resolved:
  - test: "View README.md header on GitHub in both light and dark themes (browser)"
    expected: "Light theme: dark-ink lockup visible against white; Dark theme: foam-white lockup visible against dark background"
    why_human: "GitHub renders the <picture> + raw.githubusercontent.com URLs remotely; local grep can verify URLs are correct but cannot confirm actual browser rendering"
    resolution: "Shifted left into automation (COLL-05). 106-UAT.md tests 1-2 pass; brand-visual renders both readme-header SVGs headless (dark-ink-on-transparent + light-ink-on-transparent verified via pixel-sample); check-readme-urls.mjs confirms both raw GitHub URLs serve byte-identical committed bytes (200). User also visually confirmed the dark header renders on GitHub."
---

# Phase 106: Collateral, Integration & Closeout — Verification Report

**Phase Goal:** Ship derivative collateral (brandbook/collateral/), wire brand into README / ExDoc / hex, add advisory CI lane, verify size budget (COLL-01..04).
**Verified:** 2026-06-12T22:30:00Z
**Status:** human_needed (all automated truths VERIFIED; one remote-render human check required)
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Full collateral set ships in brandbook/collateral/ | VERIFIED | 7 files: README.md, apple-touch-icon.png (180x180), favicon-32.png (32x32), readme-header.svg, readme-header-dark.svg, social-card.png (1200x630, 33KB < 150KB), social-card.svg |
| 2 | README uses absolute raw.githubusercontent URL with `<picture>` dark-mode; ExDoc logo points to production mark | VERIFIED | `<picture>` block at top of README.md with `prefers-color-scheme: dark` source + both absolute `raw.githubusercontent.com/szTheory/crosswake/main/brandbook/collateral/` URLs; mix.exs `logo: "brandbook/logo/crosswake-mark.svg"` confirmed |
| 3 | mix hex.build tarball contains no brandbook/ files; exclude_patterns in place | VERIFIED | `mix hex.build` exit 0; `tar -xOf crosswake-0.1.2.tar contents.tar.gz \| tar -tzf - \| grep -c brandbook` = 0; mix.exs package() has both `:files` allowlist AND `exclude_patterns: ["brandbook"]`; `mix compile` exit 0 |
| 4 | brandbook/ committed size < 1MB; advisory brandbook-verify.yml CI lane exists | VERIFIED | Committed size: 677,056 bytes (677KB / 1,048,576 limit = 64% used); .github/workflows/brandbook-verify.yml present, advisory framing comment, `permissions: contents: read`, `paths: brandbook/**`, SHA-pinned actions (checkout@de0fac2e, setup-node@49933ea5), runs size-budget + check-production.mjs + check-candidates.mjs + node --test token round-trip |

**Score:** 4/4 truths verified

---

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `brandbook/collateral/readme-header.svg` | Light hero, #09141A, no @media/style/external | VERIFIED | Contains #09141A; grep gate: CLEAN (no @media, no style, no currentColor, no external href) |
| `brandbook/collateral/readme-header-dark.svg` | Dark hero, #F7F1E6, no @media/style/external | VERIFIED | Contains #F7F1E6; grep gate: CLEAN |
| `brandbook/collateral/social-card.svg` | 1200x630 viewBox, literal hex fills | VERIFIED | viewBox="0 0 1200 630" present |
| `brandbook/collateral/social-card.png` | 1200x630, < 150KB (153600 bytes) | VERIFIED | Dimensions: 1200x630 via magick identify; size: 33,136 bytes |
| `brandbook/collateral/favicon-32.png` | 32x32 | VERIFIED | Dimensions: 32x32 via magick identify |
| `brandbook/collateral/apple-touch-icon.png` | 180x180 opaque | VERIFIED | Dimensions: 180x180 via magick identify |
| `brandbook/collateral/README.md` | Documents social preview manual upload | VERIFIED | Documents Settings → General → Social preview manual upload step |
| `brandbook/tools/export-raster.mjs` | Playwright clip exporter | VERIFIED | File present, used to produce all PNGs |
| `README.md` | picture header, absolute raw URLs, existing content intact | VERIFIED | `<picture>` block with both URLs; `# Crosswake` H1 and full body preserved below |
| `mix.exs` | logo: + exclude_patterns | VERIFIED | `logo: "brandbook/logo/crosswake-mark.svg"` line 85; `exclude_patterns: ["brandbook"]` line 79 |
| `.github/workflows/brandbook-verify.yml` | Advisory, paths: brandbook/**, SHA-pinned | VERIFIED | All present; advisory-only framing comment; contents: read; paths filter; SHA-pinned actions |

---

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| README.md | brandbook/collateral/readme-header.svg | absolute raw.githubusercontent.com `<img>` | VERIFIED | `raw.githubusercontent.com/szTheory/crosswake/main/brandbook/collateral/readme-header.svg` present |
| README.md | brandbook/collateral/readme-header-dark.svg | absolute raw.githubusercontent.com `<source>` | VERIFIED | `raw.githubusercontent.com/szTheory/crosswake/main/brandbook/collateral/readme-header-dark.svg` with `prefers-color-scheme: dark` |
| mix.exs docs() | brandbook/logo/crosswake-mark.svg | logo: key | VERIFIED | `logo: "brandbook/logo/crosswake-mark.svg"` line 85 |
| .github/workflows/brandbook-verify.yml | brandbook/tools/check-production.mjs | node step | VERIFIED | `run: node check-production.mjs` present |

---

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| PNG dimensions correct | `magick identify -format "%wx%h"` on 3 PNGs | 1200x630, 32x32, 180x180 | PASS |
| social-card.png < 153600 bytes | `stat -f%z social-card.png` | 33,136 bytes | PASS |
| README has picture block + dark URL | `head -30 README.md` | `<picture>` + both absolute URLs + prefers-color-scheme present | PASS |
| mix.exs logo + exclude_patterns | `grep logo:\|exclude_patterns` | Both present | PASS |
| mix compile | `mix compile` | exit 0 | PASS |
| hex tarball brandbook count | `tar -xOf ... \| tar -tzf - \| grep -c brandbook` | 0 | PASS |
| Committed brandbook size | `git ls-files brandbook \| xargs stat -f%z \| awk sum` | 677,056 bytes (PASS <= 1,048,576) | PASS |
| brandbook-verify.yml advisory properties | grep checks | advisory comment, contents: read, paths: brandbook/**, SHA-pinned actions | PASS |
| SVG grep gates (no @media/style/currentColor/external) | grep -qi on both header SVGs | CLEAN on both | PASS |
| node --test brandbook/tools/*.test.mjs | `node --test` | 23 pass, 0 fail | PASS |

---

### Requirements Coverage

| Requirement | Source Plan | Status | Evidence |
|-------------|------------|--------|----------|
| COLL-01 | 106-01 | SATISFIED | All 6 collateral files present at correct dimensions/sizes |
| COLL-02 | 106-02 | SATISFIED | README picture header with absolute raw URLs and dark-mode source |
| COLL-03 | 106-02 | SATISFIED | ExDoc logo: configured; hex tarball has 0 brandbook paths; exclude_patterns belt-and-suspenders |
| COLL-04 | 106-02 | SATISFIED | advisory brandbook-verify.yml present; committed size 677KB < 1MB |

---

### mix test Note

`mix test` reports 28 failures (1057 tests, 4 excluded). **None are related to phase 106 changes.** Verified: no test files appear in any of the 6 phase-106 commits (a2451c8, 21ca9c8, da698cc, a211838, d29480b, 770b0f3). Failing tests are pre-existing (CloseoutVerifier, MilestoneArc, ManifestTest, phase proof parity tests) and predate this phase. mix compile and mix hex.build exit 0.

---

### Anti-Patterns Found

None found. No TBD/FIXME/XXX markers in phase-modified files. No stub implementations.

---

### Human Verification Required

#### 1. README header renders correctly on GitHub in both themes

**Test:** Push the branch to GitHub origin (or view the PR), then open the repository README in a browser — once with OS/browser in light mode, once in dark mode.
**Expected:** Light mode: dark-ink Current 950 lockup with subtle wake seams visible on white GitHub background. Dark mode: foam-white Foam 50 lockup visible on GitHub's dark background. Both should be centered, legible, and understated (not a billboard).
**Why human:** The `<picture>` block + raw.githubusercontent.com URLs are fetched and composited by GitHub's renderer remotely after push. Local grep confirms the URLs are structurally correct but cannot confirm visual render output.

---

### Gaps Summary

No blocking gaps. All 4 success criteria are VERIFIED by automated checks. One human visual check required before full milestone sign-off (README dark-mode render on GitHub).

---

*Verified: 2026-06-12T22:30:00Z*
*Verifier: Claude (gsd-verifier)*
