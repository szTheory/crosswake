---
phase: 128-collateral-see-it-run-guide
verified: 2026-06-22T21:30:00Z
status: human_needed
score: 5/7 must-haves verified
behavior_unverified: 0
overrides_applied: 0
human_verification:
  - test: "Run bin/see-it-run.sh --build, then bin/capture-collateral.sh, then capture iOS Simulator and Android Emulator screenshots + three-runtime-montage.png composite + see-it-run.gif recording using the printed xcrun/adb/ImageMagick/gifsicle commands, then commit all seven binaries under brandbook/collateral/see-it-run/"
    expected: "brandbook/collateral/see-it-run/ contains web-home.png, web-offline.png, web-bridge-proof.png (automated), ios-simulator.png, android-emulator.png, three-runtime-montage.png, see-it-run.gif (human-captured); COLL-01 and COLL-02 are met"
    why_human: "iOS simulator and Android emulator captures require macOS + Xcode + Android SDK + Phase-126 Dev build on the maintainer's Mac. Cannot be automated in CI. Explicitly scoped as a user_setup manual gate in 128-03-PLAN.md (D-03/D-19 discipline)."
  - test: "Verify guides/see_it_run.md renders correctly in ExDoc and that the raw.githubusercontent.com image URLs resolve once the binaries are committed (run mix docs, open doc/see_it_run.html)"
    expected: "The guide renders with the montage PNG and GIF inline; no broken-image icons in local ExDoc output after binaries land"
    why_human: "mix docs exits 0 already (verified); image URL resolution depends on the binaries being committed and pushed to main — cannot verify programmatically without the actual files on origin."
---

# Phase 128: Collateral + See It Run Guide — Verification Report

**Phase Goal:** A prospective adopter can see all three runtimes running against one shared backend in committed screenshots and a screen recording, and can follow a reader-empathy guide from README through Docker boot to first native comparison.
**Verified:** 2026-06-22T21:30:00Z
**Status:** human_needed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths (ROADMAP Success Criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| SC1 | Repo contains committed screenshots of web, iOS simulator, Android emulator views — each honestly labeled as advisory native evidence | PARTIAL | Harness (`bin/capture-collateral.sh`) is ready; `brandbook/collateral/see-it-run/README.md` has the seven-row honest-label table. No binary PNG files committed yet — blocked by the user_setup manual gate (D-03/D-19). The capture script, label table, and guide embed URLs are all in place. |
| SC2 | Short screen recording captured, committed or linked from docs, referenced in README | PARTIAL | `guides/see_it_run.md` embeds the GIF URL via raw.githubusercontent.com (satisfies "linked from docs"). README references only the montage PNG, not the recording directly. The GIF binary is not committed. |
| SC3 | `guides/see_it_run.md` exists with gameplan summary, JTBD sections, links to (not duplicating) QUICK_START; listed in ExDoc Start group after README | VERIFIED | 141-line guide exists. Gameplan blockquote with `bin/see-it-run.sh` at top (lines 3-13). 7 JTBD `##` sections in D-08 order (SUMMARY: plan's "8" counted the H1). QUICK_START linked in 6 places, never duplicated. `mix.exs`: `guides/see_it_run.md` is item 2 in both `extras:` (line 92, after README) and `Start:` group (line 124, after README). No README.md back-link in guide. |
| SC4 | README and QUICK_START both route readers to `guides/see_it_run.md` and one-command Docker path without native overclaim | VERIFIED | README: `## See it run` section at line 45 (between `## What this is not` line 34 and `## Choose your path` line 74). Contains `bin/see-it-run.sh`, `guides/see_it_run.md` link, `examples/QUICK_START.md` link, `emulator evidence` (3×), `support_matrix.md#support-truth-label-legend` (2×). No "works on device" or "cross-platform" claim. QUICK_START: `> **New here?**` pointer at line 3, `### Option A: One Command (Docker)` heading, `bin/see-it-run.sh` as primary, `docker compose up` demoted to fallback. Honest labels preserved (`## What This Does Not Prove` intact). |
| SC5 | Guide truth guarded by source-derived `see_it_run_test.exs` test — consistent with guide-test culture | VERIFIED | `test/crosswake/guides/see_it_run_test.exs` (336 lines, module `Crosswake.Guides.SeeItRunTest`) passes 5/5 tests (readability, no-drift, wrong_port, missing_route, missing_native_label). Port derived from `runtime.exs` via `System.get_env("PORT")` regex — never hardcoded. No binary `File.exists?` assertions on human-captured PNGs/GIF (D-19). No banner-string literal overlap (D-18 confirmed: no `-scheme Dev`, `installDevDebug`, `JAVA_HOME=`, `proven native build` in test). |

**Score:** 3/5 roadmap truths fully verified; 2/5 partial (human gate pending)

### Plan Must-Have Truths (all three plans)

| # | Must-Have | Status | Evidence |
|---|-----------|--------|----------|
| 1 | Gameplan blockquote with hero command `bin/see-it-run.sh` at top of guide | VERIFIED | Lines 3-13 of guides/see_it_run.md |
| 2 | Guide has 8 D-08 sections in order (plan counted H1 + 7 `##` sections) | VERIFIED | 7 `##` sections confirmed in order: What You'll See, Run It Now, Browse the Route Owners, Compare All Three Runtimes, Wire a Native Runtime, What This Proves, Go Deeper |
| 3 | Guide appears as item 2 in extras list and Start group in mix.exs | VERIFIED | Lines 92 and 124 of mix.exs; `exclude_patterns: ["brandbook"]` untouched (line 79) |
| 4 | `mix test test/crosswake/guides/see_it_run_test.exs` passes green | VERIFIED | 5 tests, 0 failures (run confirmed) |
| 5 | Drift test derives port from runtime.exs, no binary `File.exists?` assertions, no banner-literal overlap | VERIFIED | D-19: no PNGs/GIF in test file. D-18: no `-scheme Dev` etc. Port: `System.get_env("PORT")` present (1 occurrence). |
| 6 | README `## See it run` between `## What this is not` and `## Choose your path` | VERIFIED | Line 45 (between line 34 and line 74) |
| 7 | QUICK_START `> New here?` pointer + Option A renamed + hero command leads | VERIFIED | Line 3: pointer. Line 24: `### Option A: One Command (Docker)`. Line 29: `bin/see-it-run.sh`. Old heading: 0 occurrences. |
| 8 | `bin/capture-collateral.sh` executable, `set -euo pipefail`, `--web-only`, xcrun/adb commands printed, 7 filenames, emulator evidence label | VERIFIED | Executable (`-rwxr-xr-x`). Syntax valid (`bash -n` exits 0). `set -euo pipefail` (1×). `--web-only` (5×). `xcrun simctl io booted screenshot` (1×). `adb exec-out screencap -p` (1×). All 7 filenames (30 matches). `emulator evidence` (8×). Drives `route_tour.spec.ts` via Playwright. |
| 9 | `brandbook/collateral/see-it-run/README.md` seven-row honest-label table; web=proof, native=emulator evidence; raw.githubusercontent.com URL; capture-collateral.sh documented | VERIFIED | 116 lines. All 7 filenames present. `emulator evidence` (4×). `raw.githubusercontent.com/szTheory/crosswake/main/brandbook/collateral/see-it-run` (1×). `capture-collateral.sh` (4×). |
| 10 | No proof fixture / bin/see-it-run.sh / native dev wiring / Docker backend modified | VERIFIED | Phase commits touch only: guides/see_it_run.md, test/crosswake/guides/see_it_run_test.exs, mix.exs, README.md, examples/QUICK_START.md, bin/capture-collateral.sh, brandbook/collateral/see-it-run/README.md |
| 11 | Committed binaries (PNG/GIF) for all 7 collateral assets | PARTIAL — human gate | Only `brandbook/collateral/see-it-run/README.md` is committed. The 7 asset files are not committed. This is intentional per D-03/D-19: the harness ships first; binaries require the maintainer to run the capture workflow on a Mac with Xcode + Android SDK. |

**Score (plan must-haves):** 10/11 verified; 1 pending human gate

### Required Artifacts

| Artifact | Status | Details |
|----------|--------|---------|
| `guides/see_it_run.md` | VERIFIED | 141 lines; gameplan blockquote; 7 `##` sections; port 4700; routes /offline, /bridge-proof; hero command; emulator evidence; forward links to QUICK_START; no README backlink |
| `test/crosswake/guides/see_it_run_test.exs` | VERIFIED | 336 lines; module `Crosswake.Guides.SeeItRunTest`; 5 tests pass; D-18/D-19 compliant; port derived |
| `mix.exs` (ExDoc registration) | VERIFIED | 2 occurrences of `guides/see_it_run.md`; item 2 in extras and Start group; `exclude_patterns: ["brandbook"]` preserved |
| `bin/capture-collateral.sh` | VERIFIED | Executable; syntax valid; `set -euo pipefail`; `--web-only`; xcrun/adb printed; 7 filenames; emulator evidence; Playwright route_tour integration |
| `brandbook/collateral/see-it-run/README.md` | VERIFIED | 116 lines; 7-row honest-label table; raw.githubusercontent.com URL; capture-collateral.sh referenced |
| README.md (`## See it run` section) | VERIFIED | Line 45; between the two required sections; hero command; route owners; advisory blockquote; forward links |
| `examples/QUICK_START.md` (pointer + rename) | VERIFIED | `> New here?` at line 3; `### Option A: One Command (Docker)` at line 24; `bin/see-it-run.sh` leads; docker compose fallback retained; honest labels intact |
| Committed PNG/GIF binaries (7 assets) | PARTIAL — human gate | Not committed. Per D-03/D-19: requires maintainer Mac with Xcode + Android SDK. Manual gate documented in 128-03-PLAN.md user_setup and brandbook/collateral/see-it-run/README.md. |

### Key Link Verification

| From | To | Via | Status |
|------|----|-----|--------|
| `test/crosswake/guides/see_it_run_test.exs` | `examples/phoenix_host/config/runtime.exs` | PORT regex derivation | VERIFIED — `System.get_env("PORT")` in test |
| `test/crosswake/guides/see_it_run_test.exs` | `guides/see_it_run.md` | `@target_path` reads the guide | VERIFIED — `guides/see_it_run.md` present in test (line 7) |
| `mix.exs` | `guides/see_it_run.md` | extras + Start group item 2 | VERIFIED — lines 92, 124 |
| `README.md` | `guides/see_it_run.md` | `## See it run` forward link | VERIFIED — line 71 |
| `examples/QUICK_START.md` | `guides/see_it_run.md` | `> New here?` pointer | VERIFIED — line 3 |
| `README.md` | `guides/support_matrix.md#support-truth-label-legend` | Advisory blockquote emulator-evidence legend link | VERIFIED — line 69 |
| `bin/capture-collateral.sh` | `examples/phoenix_host/e2e/route_tour.spec.ts` | Playwright route_tour mechanism | VERIFIED — lines 65, 118-140 |
| `brandbook/collateral/see-it-run/README.md` | `bin/capture-collateral.sh` | Capturing/Regenerating section | VERIFIED — 4 occurrences |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Drift test green | `mix test test/crosswake/guides/see_it_run_test.exs` | 5 tests, 0 failures | PASS |
| QUICK_START drift test (regression) | `mix test test/crosswake/guides/quick_start_adoption_drift_test.exs` | 5 tests, 0 failures | PASS |
| Banner test (no overlap regression) | `mix test test/crosswake/guides/see_it_run_banner_test.exs` | 5 tests, 0 failures | PASS |
| Capture script syntax valid | `bash -n bin/capture-collateral.sh` | exit 0 | PASS |
| Capture script executable | `test -x bin/capture-collateral.sh` | exit 0 | PASS |

### D-18 / D-19 Discipline Check

| Check | Result |
|-------|--------|
| D-19: No binary File.exists? in test for ios-simulator.png / android-emulator.png / three-runtime-montage.png / see-it-run.gif | VERIFIED — grep returns 0 matches |
| D-18: No banner-string literals in test (-scheme Dev / installDevDebug / JAVA_HOME= / proven native build) | VERIFIED — grep returns 0 matches |
| Port is source-derived (not hardcoded 4700) | VERIFIED — `System.get_env("PORT")` in test (1 match); phoenix_host_port/0 helper derives at runtime |

### Requirements Coverage

| Requirement | Plan | Description | Status | Evidence |
|-------------|------|-------------|--------|----------|
| DOCS-01 | 128-01 | `guides/see_it_run.md` with gameplan + JTBD sections in ExDoc Start group | MET | Guide exists, 7 sections, Start-group item 2 |
| DOCS-02 | 128-02 | README + QUICK_START route readers to guide + one-command path, honest labels | MET | `## See it run` in README; pointer + Option A rename in QUICK_START |
| DOCS-03 | 128-01 | Source-derived guide drift test, green, consistent with culture | MET | 5/5 tests pass; D-18/D-19 compliant |
| COLL-01 | 128-03 | Committed screenshots of all three runtimes, honestly labeled | PARTIAL | Harness + label table delivered. Actual PNG binaries pending manual gate. |
| COLL-02 | 128-03 | Screen recording captured and linked from docs/README | PARTIAL | GIF URL embedded in `guides/see_it_run.md` (doc link present). Recording binary not committed. README references montage PNG only, not the GIF. |

### Anti-Patterns Found

No blockers detected.

| File | Pattern | Severity | Notes |
|------|---------|----------|-------|
| `guides/see_it_run.md` | `JTBD-A:` label in body text (line 40) | Info | Intentional — JTBD is a product framework acronym used in the CONTEXT.md design vocabulary, not a debt marker |
| All phase files | No TBD/FIXME/XXX debt markers | — | Clean |

### Human Verification Required

#### 1. Commit the Seven Collateral Asset Binaries (COLL-01 / COLL-02)

**Test:** On the maintainer's Mac (Xcode + Android SDK + Phase-126 Dev build):
1. Run `bin/see-it-run.sh --build` to boot the shared backend
2. Run `bin/capture-collateral.sh` — captures `web-home.png`, `web-offline.png`, `web-bridge-proof.png` automatically via Playwright
3. With iOS Simulator booted and dev-wired: `xcrun simctl io booted screenshot brandbook/collateral/see-it-run/ios-simulator.png`
4. With Android Emulator booted and dev-wired: `adb exec-out screencap -p > brandbook/collateral/see-it-run/android-emulator.png`
5. Compose montage: `convert +append web-home.png ios-simulator.png android-emulator.png three-runtime-montage.png` (or hand-made)
6. Record `see-it-run.gif` (~900px, 12fps, 10-15s, `gifsicle -O3`, < 8MB)
7. Commit all 7 files under `brandbook/collateral/see-it-run/`

**Expected:** `git ls-files brandbook/collateral/see-it-run/` lists all 7 files; each native file's commit message or associated README confirms it carries the `emulator evidence` label.

**Why human:** iOS Simulator capture requires macOS + Xcode. Android Emulator capture requires Android SDK + the Phase-126 Dev build. Web capture via Playwright requires a running Docker backend at localhost:4700. These cannot be automated in CI. This is the D-03 manual gate per 128-CONTEXT.md: "the maintainer must run ... commit, before the phase can close."

#### 2. ExDoc Rendering with Collateral Images

**Test:** After binaries are committed and pushed to main, run `mix docs` and open `doc/see_it_run.html` in a browser.

**Expected:** The montage PNG and GIF render inline. The `doc/guides/support_matrix.html#support-truth-label-legend` anchor link resolves. No broken-image icons.

**Why human:** Image URLs use `raw.githubusercontent.com/szTheory/crosswake/main/...` which only resolves once files are committed and pushed to the `main` branch. Cannot verify programmatically before the binaries land.

### Per-Requirement Verdict

| Requirement | Verdict | Condition |
|-------------|---------|-----------|
| DOCS-01 | MET | guides/see_it_run.md exists, 7 JTBD sections, ExDoc Start group item 2 |
| DOCS-02 | MET | README `## See it run` + QUICK_START pointer + Option A rename, honest labels |
| DOCS-03 | MET | 5/5 drift tests pass, D-18/D-19 compliant, source-derived |
| COLL-01 | PARTIAL — human gate | Harness + label table committed. PNG binaries pending D-03 manual capture. |
| COLL-02 | PARTIAL — human gate | GIF URL present in guide (docs link). GIF binary not committed. |

### Gaps Summary

No code gaps. All three plans executed correctly — the only outstanding items are the intentional human-gated collateral binaries explicitly called out in the plan's `user_setup` block and the CONTEXT.md D-03/D-19 discipline:

- **COLL-01/COLL-02 binaries:** The 7 PNG/GIF files under `brandbook/collateral/see-it-run/` are the human-gated deliverable. The capture harness, honest-label README, and all in-guide URL references are in place. The maintainer must run the capture workflow on a Mac with Xcode + Android SDK before these requirements close.

All test-verifiable deliverables (DOCS-01, DOCS-02, DOCS-03, capture harness, label table, ExDoc registration) are fully implemented and confirmed green.

---

_Verified: 2026-06-22T21:30:00Z_
_Verifier: Claude (gsd-verifier)_
