---
phase: 65-diagnostic-export-seam-elixir
plan: 03
subsystem: testing
tags: [elixir, proof-lane, diagnostic-export, fixtures, allowlist, sanitize, support-truth]

# Dependency graph
requires:
  - phase: 65-01
    provides: DiagnosticExport behaviour-only seam with new_envelope!/1, to_map/1, sanitize/1, forbidden_keys/0, allowed_keys/0
  - phase: 65-02
    provides: SupportMatrix.diagnostic_export_support_truth/0 + Doctor diagnostic_export.contract_shipped advisory finding

provides:
  - Six canonical diagnostic envelope fixtures under test/fixtures/diagnostic/ (generated from to_map/1)
  - Merge-blocking hermetic phase-65 proof lane asserting all four DIAG requirements (DIAG-01..04)

affects:
  - phase-67-native-shell (native shells parity-lock fixtures; proof lane must stay green)
  - phase-69-closeout (proof lane is the merge-blocking gate for DIAG requirements)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Fixture generation: run new_envelope!/1 + to_map/1 via mix run, write as JSON — never hand-authored"
    - "Proof lane DIAG structure: @tag :diag_NN groups, ProofAssertions.stable_id_message with posture :merge_blocking"
    - "Hermetic guard: refute @moduletag, refute Crosswake.Example., refute MIX_INCLUDE_ (split form in source)"
    - "Doctor.run hermetic invocation: route_source ManagedRouter + install_manifest_path + cwd"

key-files:
  created:
    - test/fixtures/diagnostic/native_ios_crash.json
    - test/fixtures/diagnostic/native_ios_metrickit_hang.json
    - test/fixtures/diagnostic/native_android_anr.json
    - test/fixtures/diagnostic/native_android_low_memory.json
    - test/fixtures/diagnostic/web_liveview_fault.json
    - test/fixtures/diagnostic/bridge_command_fault.json
    - test/crosswake/proof/phase65_diagnostic_export_seam_test.exs
  modified: []

key-decisions:
  - "Doctor.run hermetic call: use Crosswake.TestSupport.RouterFixtures.ManagedRouter + priv/crosswake/install_manifest.json — same pattern as phase58/phase38 proof lanes"
  - "Hermetic guard: MIX_INCLUDE_ substring must be split as 'MIX_' <> 'INCLUDE_' in source to avoid self-triggering; comment text must not contain the literal substring either"
  - "Forbidden-key sanitize test: use Map.put/3 to inject a dynamic key into a base map (cannot mix atom-key syntax with dynamic => key syntax in a single map literal)"

patterns-established:
  - "Phase65 fixture axis: one JSON file per layer x exit-reason combination, generated from running constructors"
  - "DIAG-01 proof: grep mix.exs source string + module source string for HTTP-client dep references; check behaviour_info(:callbacks)"

requirements-completed: [DIAG-01, DIAG-02, DIAG-03, DIAG-04]

# Metrics
duration: 25min
completed: 2026-06-04
---

# Phase 65 Plan 03: Diagnostic Export Seam Proof Lane Summary

**Six axis fixtures generated from DiagnosticExport.to_map/1 + merge-blocking hermetic proof lane asserting DIAG-01..04 (no-bridge-vocab, no-HTTP-dep, typed envelope, allowlist-by-construction, non-overclaiming support truth)**

## Performance

- **Duration:** 25 min
- **Started:** 2026-06-04T08:30:00Z
- **Completed:** 2026-06-04T08:55:00Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments

- Generated six canonical diagnostic envelope fixtures (native_ios_crash, native_ios_metrickit_hang, native_android_anr, native_android_low_memory, web_liveview_fault, bridge_command_fault) from `DiagnosticExport.new_envelope!/1 + to_map/1` — not hand-authored
- Created `phase65_diagnostic_export_seam_test.exs` with 30 merge-blocking assertions covering all four DIAG requirements plus a hermetic lane guard
- Full phase-65 proof suite passes (30/30); full test suite passes minus 3 pre-existing unrelated failures in `MilestoneTransitionResetTest`

## Task Commits

1. **Task 1: Generate six canonical diagnostic fixtures from to_map/1 output** - `5cce233` (feat)
2. **Task 2: Write the merge-blocking hermetic phase-65 proof lane** - `e86301b` (feat)

## Files Created/Modified

- `test/fixtures/diagnostic/native_ios_crash.json` - Canonical envelope fixture: native iOS crash axis (MetricKit, :crash exit reason)
- `test/fixtures/diagnostic/native_ios_metrickit_hang.json` - Canonical envelope fixture: native iOS hang axis (MetricKit, :hang exit reason)
- `test/fixtures/diagnostic/native_android_anr.json` - Canonical envelope fixture: native Android ANR axis (AppExitInfo, :anr exit reason)
- `test/fixtures/diagnostic/native_android_low_memory.json` - Canonical envelope fixture: native Android low-memory termination axis (AppExitInfo, :low_memory exit reason)
- `test/fixtures/diagnostic/web_liveview_fault.json` - Canonical envelope fixture: web layer fault (no native_diagnostic)
- `test/fixtures/diagnostic/bridge_command_fault.json` - Canonical envelope fixture: bridge layer fault (no native_diagnostic)
- `test/crosswake/proof/phase65_diagnostic_export_seam_test.exs` - Hermetic phase-65 proof lane (30 tests across 4 DIAG groups + hermetic guard)

## Decisions Made

- **Doctor.run invocation:** Used `Crosswake.TestSupport.RouterFixtures.ManagedRouter` + `priv/crosswake/install_manifest.json` for the two DIAG-04 doctor assertions. The `phase_65_diagnostic_export_findings/0` fires unconditionally so any valid router works. Mirrors the phase58/phase38 patterns.
- **Hermetic guard self-avoidance:** The guard checks for literal `"MIX_INCLUDE_"` in the source — the assertion itself uses `"MIX_" <> "INCLUDE_"` (split form) to avoid self-triggering. Comments in the file must also not contain the unsplit literal.
- **Forbidden-key inject test:** Could not use `%{..., key => "injected"}` with atom keys because Elixir prohibits mixing `key: value` shorthand syntax with `key => value` expression syntax in the same map literal. Used `Map.put(base_attrs, key, "injected")` instead.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed syntax error in sanitize forbidden-key inject test**
- **Found during:** Task 2 (proof lane first run)
- **Issue:** Elixir disallows mixing `atom: value` shorthand syntax with `key => "value"` expression in a single map literal (SyntaxError at compile time)
- **Fix:** Extracted base attrs map, then used `Map.put(base_attrs, key, "injected")` to inject the dynamic forbidden key
- **Files modified:** `test/crosswake/proof/phase65_diagnostic_export_seam_test.exs`
- **Verification:** Proof lane compiles and all 30 tests pass
- **Committed in:** e86301b

**2. [Rule 1 - Bug] Fixed hermetic guard self-triggering on comment line**
- **Found during:** Task 2 (proof lane test run)
- **Issue:** A comment line in the hermetic guard section contained the literal `MIX_INCLUDE_` substring, which the guard itself refutes being present in source
- **Fix:** Changed comment to "no env-flag references" without the literal substring
- **Files modified:** `test/crosswake/proof/phase65_diagnostic_export_seam_test.exs`
- **Verification:** Hermetic guard test passes
- **Committed in:** e86301b

**3. [Rule 1 - Bug] Fixed Doctor.run crash on empty opts**
- **Found during:** Task 2 (proof lane test run)
- **Issue:** `Doctor.run([])` crashed with `nil.__routes__()` because no `route_source` was provided; the compiler attempted to call `nil.__routes__/0`
- **Fix:** Passed `route_source: Crosswake.TestSupport.RouterFixtures.ManagedRouter, install_manifest_path: "priv/crosswake/install_manifest.json", cwd: File.cwd!()` to both DIAG-04 Doctor assertions
- **Files modified:** `test/crosswake/proof/phase65_diagnostic_export_seam_test.exs`
- **Verification:** Both DIAG-04 doctor assertions pass
- **Committed in:** e86301b

---

**Total deviations:** 3 auto-fixed (all Rule 1 bugs found during proof lane test run)
**Impact on plan:** All three fixes were necessary for correctness. No scope creep.

## Issues Encountered

- `new_native_diagnostic!/1` does not exist — the module only exposes `new_native_diagnostic/1` (returning `{:ok, _}` or `{:error, _}`). The fixture generation script was adjusted to pattern-match on `{:ok, nd}` before passing `nd` to `new_envelope!/1`.

## Known Stubs

None — all six fixtures contain real to_map/1 output with no placeholder text, all proof assertions exercise real code paths.

## Threat Flags

None — this plan creates only test fixtures and a proof lane test file. No new network endpoints, auth paths, file access patterns, or schema changes at trust boundaries were introduced.

## Pre-existing Test Failures (Out of Scope)

Three tests in `Crosswake.Planning.MilestoneTransitionResetTest` fail because they assert v3.9 milestone state (which was superseded by v4.0). These failures pre-existed before this wave (confirmed against wave-2 final commit `066c2e7`). They are tracked as a deferred item and are NOT caused by this plan.

## Self-Check: PASSED

- `test/fixtures/diagnostic/native_ios_crash.json` — FOUND
- `test/fixtures/diagnostic/native_ios_metrickit_hang.json` — FOUND
- `test/fixtures/diagnostic/native_android_anr.json` — FOUND
- `test/fixtures/diagnostic/native_android_low_memory.json` — FOUND
- `test/fixtures/diagnostic/web_liveview_fault.json` — FOUND
- `test/fixtures/diagnostic/bridge_command_fault.json` — FOUND
- `test/crosswake/proof/phase65_diagnostic_export_seam_test.exs` — FOUND
- Commit `5cce233` — FOUND (feat: generate six canonical diagnostic fixtures)
- Commit `e86301b` — FOUND (feat: add merge-blocking hermetic phase-65 proof lane)

## Next Phase Readiness

- Phase 65 is now complete: all 4 DIAG requirements proven by merge-blocking hermetic tests
- Six fixture files under `test/fixtures/diagnostic/` are the canonical shapes Phase 67 native shells must parity-lock against
- Phase 66 (generator templates + Xcode 26 CI fix) is ready to begin

---
*Phase: 65-diagnostic-export-seam-elixir*
*Completed: 2026-06-04*
