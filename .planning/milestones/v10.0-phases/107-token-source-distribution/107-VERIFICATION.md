---
phase: 107-token-source-distribution
verified: 2026-06-13T00:00:00Z
status: passed
score: 13/13 must-haves verified
overrides_applied: 0
deferred:
  - truth: "No hand-edited font stacks exist anywhere outside tokens.css (SC1 full coverage)"
    addressed_in: "Phase 108"
    evidence: "NORM-01 (Phase 108): 'no duplicated flat palette and no inline font stacks' in examples/phoenix_host/assets/css/app.css. Phase 107 scope fence explicitly excludes app.css normalization."
  - truth: "Stale Tailwind config advice in gen.offline_ui.ex has correct brand hex values"
    addressed_in: "Phase 108"
    evidence: "NORM-02 (Phase 108) explicitly covers 'the stale hardcoded Tailwind color theme emitted by lib/mix/tasks/crosswake.gen.offline_ui.ex (legacy blue #699cc9 / amber #e1b982, ~lines 68-90)'. Pre-dates phase 107 (introduced in feat(101-02))."
  - truth: "Example host LiveView stylesheet links are in <head> not <body>"
    addressed_in: "Phase 108"
    evidence: "Pre-existing structure from feat(87-01). Phase 107 scope fence required matching the example host's existing plain-href convention. Phase 108 rewires consumers."
---

# Phase 107: Token Source & Distribution Verification Report

**Phase Goal:** `tokens.css` covers everything its consumers need — font families, type scale, spacing, radius — all generated from `crosswake.tokens.json`, and one documented distribution path connects that file to every consumer.
**Verified:** 2026-06-13T00:00:00Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Running `node brandbook/tools/compile-tokens.js` emits `--cw-font-display`, `--cw-font-body`, `--cw-font-mono` into tokens.css | VERIFIED | Lines 130-132 of brandbook/tokens/tokens.css; live run exits 0 and logs "brandbook/tokens/tokens.css written" |
| 2 | All dimension tokens emitted (type scale, display scale, radius, line-height, spacing, focus, tracking) | VERIFIED | 23 dimension tokens at lines 126-151 of brandbook/tokens/tokens.css; all named token groups confirmed present |
| 3 | Font families serialize as comma-joined stacks with multi-word names quoted (not raw arrays) | VERIFIED | `--cw-font-display: "Space Grotesk", ui-sans-serif, ...`; `grep -c "object Array" tokens.css` = 0 |
| 4 | Dimension tokens emit raw `$value` strings (e.g. `16px`, `-0.02em`) | VERIFIED | `--cw-text-scale-md: 16px`, `--cw-tracking-tight: -0.02em` in brandbook/tokens/tokens.css |
| 5 | priv/static/crosswake/tokens.css is byte-identical to brandbook/tokens/tokens.css | VERIFIED | `diff brandbook/tokens/tokens.css priv/static/crosswake/tokens.css` exits 0 |
| 6 | One generator run produces both copies from one JSON source; no palette hand-declared | VERIFIED | compile-tokens.js reads JSON_PATH, writes CSS_PATH then PRIV_CSS_PATH with same `out` string |
| 7 | mix crosswake.gen.offline_ui copies packaged tokens.css into host static dir using no-clobber | VERIFIED | ensure_file(tokens_css_dest, ...) in run/1; test asserts "reused" on second run |
| 8 | Generated offline_root.html.heex links tokens.css before app.css | VERIFIED | Line 10: `~p"/assets/tokens.css"`, Line 11: `~p"/assets/app.css"` in offline_root.html.heex.eex |
| 9 | Example host vendors a byte-identical copy of priv/static/crosswake/tokens.css | VERIFIED | `diff priv/static/crosswake/tokens.css examples/phoenix_host/priv/static/css/tokens.css` exits 0 |
| 10 | Example host LiveViews link /css/tokens.css before /css/app.css | VERIFIED | Line 15: `/css/tokens.css`, Line 16: `/css/app.css` in both index.ex and show.ex |
| 11 | One vendor-by-copy + link mechanism used for BOTH consumers | VERIFIED | Generator: ensure_file copy + phx-track-static link; Example host: manual verbatim copy + plain href link; no other mechanism |
| 12 | A single distribution guide documents the one mechanism end-to-end | VERIFIED | guides/tokens.md (102 lines); covers source JSON, generate command, two outputs, both consumer paths, contract |
| 13 | guides/tokens.md is registered in mix.exs extras so it ships in the Hex package | VERIFIED | mix.exs line 102: `"guides/tokens.md"` after `"guides/offline.md"` in extras list |

**Score:** 13/13 truths verified

### Deferred Items

Items not yet met but explicitly addressed in later milestone phases.

| # | Item | Addressed In | Evidence |
|---|------|-------------|----------|
| 1 | app.css re-declares `--cw-font-*` custom properties by hand (pre-phase-107 debt, not removed by phase 107 per scope fence) | Phase 108 | NORM-01: "no duplicated flat palette and no inline font stacks" in examples/phoenix_host/assets/css/app.css |
| 2 | gen.offline_ui.ex prints Tailwind config advice with wrong brand hex values (pre-phase-101 defect, CR-01 in REVIEW.md) | Phase 108 | NORM-02 explicitly covers "stale hardcoded Tailwind color theme emitted by lib/mix/tasks/crosswake.gen.offline_ui.ex (legacy blue #699cc9 / amber #e1b982, ~lines 68-90)" |
| 3 | Example host `<link>` tags land in `<body>` not `<head>` (pre-phase-87 structure, WR-02 in REVIEW.md) | Phase 108 | NORM-01/NORM-02 rewire consumers; Phase 107 scope fence required matching existing example host convention |

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `brandbook/tools/compile-tokens.js` | Non-color token emit + second writeFileSync | VERIFIED | Contains `serializeNonColor`, `NON_COLOR_GROUPS`, `PRIV_CSS_PATH`, `mkdirSync recursive` at expected lines |
| `brandbook/tokens/tokens.css` | Full token set including font + dimension block | VERIFIED | 124 custom properties; `/* ─── Fonts & dimensions ─── */` block at line 124; 26 non-color properties |
| `priv/static/crosswake/tokens.css` | Packaged distributable mirror | VERIFIED | Exists; byte-identical to brandbook copy; GENERATED header on line 1 |
| `brandbook/tools/compile-tokens.test.mjs` | Node tests for font/dimension emit + priv mirror parity | VERIFIED | 27 tests (25 + 2 extra); includes `byte-identical` assertion at line 222 |
| `lib/mix/tasks/crosswake.gen.offline_ui.ex` | get_tokens_css_path/0 + ensure_file copy | VERIFIED | get_tokens_css_path at line 113; tokens_css_dest + ensure_file at lines 50/56 |
| `priv/templates/crosswake/offline_ui/offline_root.html.heex.eex` | tokens.css link before app.css | VERIFIED | Line 10 tokens.css, Line 11 app.css; phx-track-static on both |
| `examples/phoenix_host/priv/static/css/tokens.css` | Example host vendored token copy | VERIFIED | Exists; byte-identical to priv/static/crosswake/tokens.css |
| `test/mix/tasks/crosswake.gen.offline_ui_test.exs` | Assertions for tokens.css copy + link order + no-clobber | VERIFIED | 5 tests including copy-exists, font-display assertion, link-before-app.css, no-clobber/reused |
| `guides/tokens.md` | Single distribution mechanism documented | VERIFIED | 102 lines; contains generate command, both consumer paths, no-hand-edit contract, diff parity statement |
| `mix.exs` | ExDoc extras registration for guides/tokens.md | VERIFIED | Line 102 in extras list, after guides/offline.md |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `compile-tokens.js` | `priv/static/crosswake/tokens.css` | second `writeFileSync` after `mkdirSync recursive` | WIRED | Line 97: `mkdirSync`, Line 98: `writeFileSync(PRIV_CSS_PATH, out, 'utf8')` |
| `compile-tokens.js` fontFamily tokens | `serializeNonColor` | non-color emit path bypassing `resolveAlias` | WIRED | Line 45: `if (token['$type'] === 'fontFamily')`; `resolveAlias` never called for non-color tokens |
| `crosswake.gen.offline_ui.ex run/1` | `priv/static/crosswake/tokens.css` | `get_tokens_css_path` + `ensure_file` no-clobber copy | WIRED | Lines 50-56; `Application.app_dir` + `File.cwd!` fallback pattern |
| `offline_root.html.heex.eex` | `/assets/tokens.css` | `phx-track-static` link before `app.css` | WIRED | Line 10 tokens, Line 11 app; confirmed by `mix test` (5/5 pass) |
| Example `deck_live` LiveViews | `/css/tokens.css` | plain href link before `/css/app.css` | WIRED | index.ex line 15 tokens / line 16 app; show.ex same |
| `mix.exs extras` | `guides/tokens.md` | extras list entry | WIRED | Line 102 of mix.exs |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| `brandbook/tokens/tokens.css` | CSS custom properties | `crosswake.tokens.json` via `flattenTokens()` | Yes — `JSON_PATH = path.join(ROOT, 'brandbook/tokens/crosswake.tokens.json')` read at runtime | FLOWING |
| `priv/static/crosswake/tokens.css` | CSS custom properties | Same `out` string as brandbook copy | Yes — byte-identical by construction (same buffer) | FLOWING |
| `examples/phoenix_host/priv/static/css/tokens.css` | CSS custom properties | Verbatim copy of priv/static/crosswake/tokens.css | Yes — diff exits 0 | FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| compile-tokens.js generates both files and exits 0 | `node brandbook/tools/compile-tokens.js` | "brandbook/tokens/tokens.css written" + "priv/static/crosswake/tokens.css written", exit 0 | PASS |
| All 25 Node tests green | `node --test brandbook/tools/compile-tokens.test.mjs` | `# pass 25` / `# fail 0` | PASS |
| Both tokens.css files byte-identical | `diff brandbook/tokens/tokens.css priv/static/crosswake/tokens.css` | No output, exit 0 | PASS |
| --cw-font-display has quoted Space Grotesk stack | `grep "cw-font-display" brandbook/tokens/tokens.css` | `--cw-font-display: "Space Grotesk", ui-sans-serif, ...` | PASS |
| Dimension value --cw-text-scale-md is 16px | `grep "cw-text-scale-md" brandbook/tokens/tokens.css` | `--cw-text-scale-md: 16px` | PASS |
| No `[object Array]` in tokens.css | `grep -c "object Array" brandbook/tokens/tokens.css` | 0 | PASS |
| All 5 mix tests green | `mix test test/mix/tasks/crosswake.gen.offline_ui_test.exs` | `5 tests, 0 failures` | PASS |
| Example host copy byte-identical | `diff priv/static/crosswake/tokens.css examples/phoenix_host/priv/static/css/tokens.css` | No output, exit 0 | PASS |

### Probe Execution

No explicit probe scripts declared for phase 107. Behavioral spot-checks above cover the same ground.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| TOKN-04 | 107-01-PLAN.md | compile-tokens.js emits font.* family tokens into tokens.css | SATISFIED | `--cw-font-display`, `--cw-font-body`, `--cw-font-mono` present in tokens.css; 25/25 Node tests pass |
| TOKN-05 | 107-01-PLAN.md | compile-tokens.js emits dimension.* tokens consumers reference | SATISFIED | 23 dimension tokens (text-scale, display-scale, radius, line-height, spacing, focus, tracking) all present |
| NORM-03 | 107-02-PLAN.md, 107-03-PLAN.md | tokens.css reaches both consumers through one explicit documented mechanism | SATISFIED | One mechanism (vendor-by-copy + link) documented in guides/tokens.md, implemented in generator ensure_file + template + example host vendored copy |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `lib/mix/tasks/crosswake.gen.offline_ui.ex` | 65-96 | Tailwind config advice with wrong brand hex values (pre-existing from feat(101-02)) | Pre-existing / deferred | Misleads adopters — addressed by NORM-02 in Phase 108 |
| `examples/phoenix_host/lib/.../deck_live/index.ex` | 15-16 | `<link>` in `render()` body (pre-existing from feat(87-01)) | Pre-existing / deferred | Example teaches wrong HTML placement — addressed by Phase 108 consumer rewire |
| `brandbook/tools/compile-tokens.test.mjs` | 109-113 | `tokens.css exists` test does not run the script (pre-existing) | Info | Precondition assertion; passes because file is committed |

No TBD, FIXME, or XXX markers found in any phase-107-modified file.
No new debt markers introduced by this phase.

### Human Verification Required

None. All success criteria are mechanically verifiable and confirmed passing.

### Gaps Summary

No gaps. All 13 must-have truths are verified. All three required requirements (TOKN-04, TOKN-05, NORM-03) are satisfied by codebase evidence.

Three items from the code review (REVIEW.md) are pre-existing technical debt explicitly deferred to Phase 108 via the plan's scope fence and roadmap requirements (NORM-01, NORM-02). They do not block phase 107's goal.

**Dimension token count note:** The RESEARCH.md and plan spec state "24 dimension tokens" but the actual `crosswake.tokens.json` source contains 23 dimension tokens (3+23=26 non-color total). The generator faithfully emits all tokens from the source — this is a spec overcount, not a missing token. All token groups named in TOKN-05 (text-scale, display-scale, radius, line-height, spacing, focus-ring-width, tracking-tight) are present in the generated CSS.

---

_Verified: 2026-06-13T00:00:00Z_
_Verifier: Claude (gsd-verifier)_
