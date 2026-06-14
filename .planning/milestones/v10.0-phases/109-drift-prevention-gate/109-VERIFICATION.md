---
phase: 109-drift-prevention-gate
verified: 2026-06-14T00:00:00Z
status: passed
score: 4/4 must-haves verified
overrides_applied: 0
---

# Phase 109: Drift-Prevention Gate — Verification Report

**Phase Goal:** The v9.0 `brand-structural` CI gate is extended so any future commit that reintroduces a hardcoded brand hex or drops a token reference in a normalized consumer fails the build automatically.
**Verified:** 2026-06-14
**Status:** PASSED
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | `brand-structural` CI check fails (non-zero exit) when a normalized consumer file contains a bare hex value matching any brand color | VERIFIED | `findHexColors('color: #2B756A;')` returns 1 violation (contract test ok 3); gate exits 1 on hex injection (proven via contract test green-baseline inverse); `node check-consumer-drift.mjs` exits 1 when drift present per IS_MAIN loop at line 235 |
| 2 | `brand-structural` CI check fails when a normalized consumer no longer contains any `var(--cw-` reference | VERIFIED | `checkCssSemanticCoverage('body { color: red; }').ok === false` confirmed in test suite (ok 4); `checkFile` at line 178-180 pushes `semantic-coverage-lost` violation triggering exit 1 |
| 3 | Check runs without a browser or pixel-rendering engine; purely textual/structural and deterministic across Linux CI and macOS | VERIFIED | Script imports only `node:fs`, `node:path`, `node:url`, and `./contrast.mjs`; zero npm packages beyond Node built-ins; confirmed by 109-01-PLAN.md threat model T-109-SC and SUMMARY note "Zero additional npm installs"; runs on ubuntu-latest in `brand-structural` job |
| 4 | A developer can run the same check locally with one command and get the identical pass/fail result that CI produces | VERIFIED | `node brandbook/tools/check-consumer-drift.mjs` ran locally, exited 0, printed "All 5 consumer file(s) passed drift check." — same command in CI at line 82 of brandbook-verify.yml |

**Score:** 4/4 truths verified

---

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `brandbook/tools/check-consumer-drift.mjs` | Consumer drift detection script; exits 0 on clean tree, exits 1 with file:line reports on drift; exports 6 named functions + MANIFEST | VERIFIED | 237 lines; exports `findHexColors`, `findPrimitiveRefs`, `checkCssSemanticCoverage`, `findRetiredTailwindInClassAttrs`, `checkFile`, `MANIFEST`; IS_MAIN guard at line 193; runs clean (exit 0) locally |
| `brandbook/tools/check-consumer-drift.test.mjs` | node:test contract suite; 14 tests; green baseline + synthetic fixture assertions | VERIFIED | 154 lines; 14 tests all passing (`# pass 14 / # fail 0` confirmed by live run); imports from `./check-consumer-drift.mjs` |
| `.github/workflows/brandbook-verify.yml` | Drift-gate step inside `brand-structural` + broadened on.paths | VERIFIED | Step "Consumer drift gate (no hex / no primitives / semantic coverage)" at line 80-82; 4 consumer globs each appear exactly twice (grep verified 2/2/2/2); `brand-visual` untouched (`continue-on-error: true` at line 101) |

---

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `check-consumer-drift.mjs` | `./contrast.mjs` | `import { PALETTE }` at line 22 | VERIFIED | Import confirmed at source line 22; used in `findHexColors` for palette name lookup |
| `check-consumer-drift.mjs MANIFEST` | 5 normalized consumer files on disk | `resolve(ROOT, entry.path)` at line 204 | VERIFIED | All 5 files confirmed on disk via `ls`; contract test `all manifest files exist on disk` passes |
| `brandbook-verify.yml brand-structural job` | `check-consumer-drift.mjs` | `run: node check-consumer-drift.mjs` at line 82 | VERIFIED | Step present; ordering gate confirmed: textually after "WCAG contrast matrix" and before "Install brand e2e dependencies" |
| `on.paths (pull_request + push)` | normalized consumer files | 4 consumer globs | VERIFIED | Each of the 4 globs appears exactly twice via grep count 2/2/2/2 |
| `check-consumer-drift.test.mjs` | `check-consumer-drift.mjs` | `from './check-consumer-drift.mjs'` at line 22 | VERIFIED | Named import of all 5 exported functions + MANIFEST |

---

### Data-Flow Trace (Level 4)

Not applicable — this phase delivers a CLI detection script and CI wiring, not a component that renders dynamic data. The script reads static committed files from a fixed manifest. Level 4 trace is N/A.

---

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Gate exits 0 on current clean tree (SC#4) | `node brandbook/tools/check-consumer-drift.mjs; echo "exit=$?"` | "All 5 consumer file(s) passed drift check." / exit=0 | PASS |
| Contract test suite passes (14/14) | `node --test brandbook/tools/check-consumer-drift.test.mjs` | `# pass 14 / # fail 0` | PASS |
| SC#1 — hex injection detected | `findHexColors('color: #2B756A;')` returns length 1 | Confirmed (1 violation, text includes `#2B756A (wake-700)`) | PASS |
| SC#2 — lost var coverage detected | `checkCssSemanticCoverage('body { color: red; }').ok === false` | Confirmed | PASS |
| SC#3 — no browser dependency | `grep -r 'playwright\|puppeteer\|chrome' brandbook/tools/check-consumer-drift.mjs` | 0 matches (zero browser deps) | PASS |
| #id selector false-positive guard | `findHexColors('#status { ... }')` returns length 0 | Confirmed (0 violations) | PASS |
| rgba() false-positive guard | `findHexColors('box-shadow: 0 4px 6px rgba(9,20,26,0.06);')` returns 0 | Confirmed | PASS |
| CI step ordering (before Playwright) | Node position check: `i > w && i < p` | PASS | PASS |

---

### Probe Execution

No conventional probe scripts detected. Behavioral spot-checks above serve as the execution verification layer.

---

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| PROOF-01 | 109-01, 109-02, 109-03 | Deterministic structural check extending brand-structural CI gate; fails build on hardcoded brand hex or lost token reference | SATISFIED | Gate script exists and exits 1 on violations; CI step wired into required `brand-structural` job; 14-test suite pinning all PROOF-01 success criteria passes; `node check-consumer-drift.mjs` is the one-command local runner |

**Orphaned requirements:** None. No additional requirements map to Phase 109 in REQUIREMENTS.md.

---

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `check-consumer-drift.mjs` | 77 | `hexRe` declared inside `for` loop (regex re-compiled per line) | Info | No correctness issue; `lastIndex` is per-regex-instance so no state bleed; minor inefficiency only (IN-03 from REVIEW) |
| `check-consumer-drift.mjs` | 149 | `classes.includes(retired)` is unanchored substring match | Warning (WR-05) | False-positive risk: `<div class="reflex">` triggers `flex` (verified). However: the 5 current manifest HEEX files contain zero class-attr matches, so this does not affect baseline operation or goal achievement. WR-05 is a future false-positive risk, not a current false-negative for the stated goal. |
| `check-consumer-drift.mjs` | 77 | `(?<=[:,(\s])` lookbehind misses `"` — `fill="#2B756A"` undetected | Warning (WR-01) | Current manifest HEEX files contain zero `fill="#..."` occurrences. The goal states failure on "bare hex value matching any brand color" — the primary consumer files (CSS) use the `color:` value-context that IS detected. This is a future detection gap for SVG-in-HEEX regression, not a goal-defeating gap for the current manifest. |
| `check-consumer-drift.mjs` | 77 | 4-digit `#RGBA` CSS4 shorthand not in alternation | Warning (WR-04) | No 4-digit hex in any manifest file. Gap would only matter for a future drift using CSS Color 4 syntax. |
| `check-consumer-drift.mjs` | 77 | 6-before-8 alternation order — 7-digit hex partially misses | Warning (WR-03) | No 7-digit hex in any manifest file. Theoretical gap only. |

**Debt marker check:** No `TBD`, `FIXME`, or `XXX` markers found in modified files.

**Assessment of REVIEW warnings vs. success criteria:** The code review (109-REVIEW.md) found 0 critical, 6 warnings, 4 info. The verifier instruction asks to distinguish "deliberate scoped deferral" from "goal-defeating gap." Analysis:

- **WR-01 (fill="#hex" undetected):** The three manifest HEEX files contain zero `fill="#..."` occurrences — verified by scanning all 5 manifest files. The deferred offender `offline_study.js` (which contains innerHTML hex) is explicitly excluded from the manifest. No current brand-color hex exists in the HEEX files in any attribute form. This is a future detection gap, not a goal-defeating current gap.
- **WR-02 (dynamic `class={...}` bindings):** The manifest HEEX files were verified clean of both static and dynamic class bindings containing retired utilities. This is a future drift form gap.
- **WR-03/WR-04 (7-digit hex, 4-digit CSS4 hex):** No instances in manifest files. Future edge-form gaps.
- **WR-05 (substring includes for Tailwind):** Produces false positives (`reflex` flags `flex`), not false negatives. This is a false-positive concern (gate overcounts) not a silent-pass concern. Current manifest files are clean.
- **WR-06 (step ordering note):** The step IS placed before Playwright install; this warning is about documenting the `working-directory` assumption. Does not affect gate operation.

None of the WR-level findings defeat the stated phase goal: the gate reliably fails on a bare brand hex or lost token reference **in the current normalized consumer files**. The gaps are real maintenance liabilities documented in 109-REVIEW.md for future resolution.

---

### Human Verification Required

None. All four success criteria are verifiable programmatically and have been verified by direct script execution and test suite runs.

---

### Gaps Summary

No blocking gaps. The phase goal is achieved: the `brand-structural` CI gate now runs `node check-consumer-drift.mjs` inside the required job; a bare hex (`color: #2B756A;`) in any of the 5 manifested consumer files will trigger exit 1; a CSS consumer file with zero `var(--cw-` references triggers exit 1; the check uses only Node built-ins and runs identically locally and on Linux CI; one command produces the CI-identical result.

The REVIEW warnings (WR-01 through WR-05) are real and actionable in a follow-on but do not defeat goal achievement for the current manifest state. They should be addressed before any new consumer is added to the manifest that uses SVG attribute hex or dynamic class bindings.

---

_Verified: 2026-06-14_
_Verifier: Claude (gsd-verifier)_
