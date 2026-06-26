---
phase: 132-generalization-proof-rindle-compat-matrix
plan: 03
subsystem: companion-packaging
tags: [extraction, rindle, seam, companion-guard, ci-lanes, generalization-proof]
status: complete
requires:
  - "packages/crosswake_rindle/ skeleton (132-01)"
  - "Crosswake.TestSupport.StubRindleAbsentCompanion (132-01)"
  - "Crosswake.CompanionGuard @extracted_companion_names (Phase 130)"
provides:
  - "packages/crosswake_rindle/lib/crosswake/companions/rindle{,/contracts,/reconciliation}.ex (moved, module names preserved)"
  - "rindle companion test lane (5 proof tests + 2 unit tests) under packages/crosswake_rindle/test/"
  - "CompanionGuard MapSet entry Crosswake.Companions.Rindle (EXTRACT-03 structural witness)"
  - ".github/workflows/phase132-proof.yml (3-job companion lane)"
  - "parameterized script/verify_companion_package.sh ($PACKAGE -> companion.ex)"
affects:
  - "132-02 (compat-matrix drift test — now has 2 real packages to assert >= 2 against)"
  - "132-04 (publish pipeline — release-please component + clean-room for crosswake_rindle)"
tech-stack:
  added: []
  patterns:
    - "@compile {:no_warn_undefined, Engine} on the moved adapter (D-29)"
    - "engine-PRESENT companion lane (rulestead phase42 D-20 analog) — adapter tests assert :ok/:present; engine-ABSENT seam coverage stays in core via the Stub*AbsentCompanion"
    - "require_file-only media helpers (excluded from elixirc_paths to avoid double-load)"
key-files:
  created:
    - .github/workflows/phase132-proof.yml
    - packages/crosswake_rindle/test/support/study_session_live.ex
    - packages/crosswake_rindle/test/support/example_host.ex
    - packages/crosswake_rindle/test/support/example_host/reconciliation_keys.ex
    - packages/crosswake_rindle/test/support/example_host/reconciliation_inbox.ex
    - packages/crosswake_rindle/test/support/example_host/mock_capture.ex
    - packages/crosswake_rindle/test/support/example_host/media_projection.ex
    - packages/crosswake_rindle/test/support/example_host/media_lane_live.ex
  modified:
    - lib/crosswake/companion_guard.ex
    - mix.exs
    - script/verify_companion_package.sh
    - test/crosswake/guides/companions_test.exs
    - test/crosswake/proof/phase47_companion_arc_test.exs
    - packages/crosswake_rindle/mix.exs
    - packages/crosswake_rindle/test/test_helper.exs
  moved:
    - "lib/crosswake/companions/rindle.ex -> packages/crosswake_rindle/lib/..."
    - "lib/crosswake/companions/rindle/contracts.ex -> packages/crosswake_rindle/lib/..."
    - "lib/crosswake/companions/rindle/reconciliation.ex -> packages/crosswake_rindle/lib/..."
    - "test/crosswake/proof/phase45_rindle_{companion,mock_media,advisory,live}_test.exs -> packages/crosswake_rindle/test/..."
    - "test/crosswake/proof/phase72_media_evidence_workflow_proof_test.exs -> packages/crosswake_rindle/test/..."
    - "test/crosswake/companions/rindle/{contracts,reconciliation}_test.exs -> packages/crosswake_rindle/test/..."
  deleted:
    - .github/workflows/phase72-proof.yml
decisions:
  - "Rindle companion lane is engine-PRESENT (mirrors rulestead phase42 D-20), NOT engine-absent as the plan/research assumed: `~> 0.1` admits everything `< 1.0.0` (so it resolves the real rindle 0.3.1 engine), and an `optional: true` DIRECT dep is always fetched by the defining package — mix refuses to run if it is declared-but-absent. The engine-ABSENT assertions moved to core via StubRindleAbsentCompanion (phase47 + companions_test)."
  - "Media helpers live in test/support/example_host/ (plan artifact path) but are EXCLUDED from elixirc_paths — loaded only via Code.require_file/2 (the phase72 hermeticity self-scan asserts on those basenames). elixirc_paths(:test) compiles only the two named support stubs (study_session_live.ex + example_host.ex) so require_file does not double-load (redefining-module warnings)."
  - "Added a no-op package-local Crosswake.TestSupport.ExampleHost stub so the excluded :requires_example_host live test resolves its setup_all reference under --warnings-as-errors without shipping the Phoenix example host."
metrics:
  duration: ~16m
  completed: 2026-06-26
  tasks: 3
  files: 27
---

# Phase 132 Plan 03: Rindle Source Move + Seam Generalization Summary

Moved the `rindle` adapter + owned `Contracts`/`Reconciliation` (module names preserved = non-breaking) and its domain/adapter coupling tests into `packages/crosswake_rindle/`, seam-rewrote the two core tests to drive rindle through `StubRindleAbsentCompanion`, added `Crosswake.Companions.Rindle` to the `CompanionGuard` frozen MapSet as the single core edit, chained the `companions.test` alias, parameterized `verify_companion_package.sh`, and stood up the merge-blocking `phase132-proof.yml` lane (retiring the standalone macOS `phase72-proof.yml`). This is the EXTRACT-07 + SEAM-05 generalization proof: the recipe applied to a second companion with zero rindle-specific branch added to core.

## What Was Built

**Task 1 — source move + CompanionGuard MapSet (commit d278491)**
`git mv`'d `rindle.ex`/`contracts.ex`/`reconciliation.ex` into `packages/crosswake_rindle/lib/`, added `@compile {:no_warn_undefined, Rindle}` on the moved adapter (D-29 — the core copy never needed it because the engine module existed in core), and added `"Crosswake.Companions.Rindle"` to `@extracted_companion_names` in the SAME commit (the guard's same-PR rule). Core `lib/` is now rindle-free except the guard MapSet string entry; the EXTRACT-03 guard (`phase130_extraction_guards_test.exs`) is green (12/0).

**Task 2 — coupling-test move + media helpers (commit 7a30995)**
Moved the 5 rindle proof tests + 2 unit tests into the companion lane (deleted from core), copied the `StudySessionLive` stub and the 5 example-host media helpers into `packages/crosswake_rindle/test/support/`, rewrote `Code.require_file` paths to the copied helpers, and retagged the advisory test `:advisory_only` → `:engine_present`. The rindle companion lane runs **55 tests / 0 failures** engine-absent-default; the engine-present advisory lane is green (1/0).

**Task 3 — core seam rewrites + CI wiring (commit 1bfafac)**
Rewrote `companions_test.exs` (dropped the rindle `ensure_loaded!`/`function_exported?` guards, substituted `StubRindleAbsentCompanion` at the two companions-list sites) and `phase47_companion_arc_test.exs` (`alias StubRindleAbsentCompanion, as: Rindle` — tests 1-2 drive `Doctor.run` through the seam; 3-6 unchanged). Chained the rindle lane into `mix.exs` `companions.test`, parameterized `verify_companion_package.sh` from `$PACKAGE`, added the 3-job `phase132-proof.yml` (ubuntu-latest), and retired `phase72-proof.yml`. Core seam tests green (13/0); `CROSSWAKE_RELEASE=1 bash script/verify_companion_package.sh crosswake_rindle` passes.

## Verification

- `grep -r "Crosswake.Companions.Rindle" lib/` → only `companion_guard.ex:40` (SEAM-05 structural witness). ✓
- `mix test test/crosswake/proof/phase130_extraction_guards_test.exs` → 12/0 (EXTRACT-03). ✓
- `mix companions.test` → both lanes run; rindle lane 55/0. ✓
- `CROSSWAKE_RELEASE=1 bash script/verify_companion_package.sh crosswake_rindle` → OK (parameterized rindle.ex check, test/ excluded, lib/ present, compile --warnings-as-errors clean). ✓
- Core seam tests (`companions_test.exs` + `phase47_companion_arc_test.exs`) → 13/0. ✓
- `Path.wildcard("packages/crosswake_*/mix.exs")` → 2. ✓
- rindle package `mix compile --warnings-as-errors` → clean (no redefinition / no undefined-function warnings). ✓

## Deviations from Plan

The plan and 132-RESEARCH.md both assumed the rindle lane would be **engine-absent** because they believed `{:rindle, "~> 0.1", optional: true}` excludes the live `rindle 0.3.x` engine ("0.3.0 ∉ ~> 0.1"). That premise is factually wrong, which forced a principled, rulestead-precedented correction.

**1. [Rule 1 — incorrect premise] Rindle companion lane is engine-PRESENT, not engine-absent.**
- **Found during:** Task 2 (running the moved companion lane).
- **Issue:** `~> 0.1` means `>= 0.1.0 and < 1.0.0` — it admits `0.3.1`. `mix deps.get` resolved the real `rindle 0.3.1`, making `Code.ensure_loaded?(Rindle) == true`, so the moved `phase45_rindle_companion_test.exs` (which asserted engine-ABSENT `{:error, [Rindle]}` / `{:missing, ...}`) failed. Additionally an `optional: true` DIRECT dep is always fetched by the defining package — mix refuses to run when it is declared-but-absent, so a true engine-absent lane is not achievable here.
- **Fix:** Mirrored the established rulestead `phase42` D-20 split — the companion lane runs **engine-PRESENT** (adapter-behavior tests assert `validate_dependency == :ok`, `dependency_status == :present`, no `dependency_missing` finding). The engine-ABSENT seam coverage is preserved in **core** via `StubRindleAbsentCompanion` (`phase47` + `companions_test`, rewritten in Task 3). Updated the moved adapter test's assertions + moduledoc accordingly; the advisory test retag to `:engine_present` aligns with this.
- **Files:** `packages/crosswake_rindle/test/crosswake/proof/phase45_rindle_companion_test.exs`, `phase45_rindle_advisory_test.exs`; `mix.exs` companions.test comment corrected.
- **Commit:** 7a30995.

**2. [Rule 3 — blocking] `:requires_example_host` excluded in the companion test_helper + no-op ExampleHost stub.**
- **Found during:** Task 2. The moved `phase45_rindle_live_test.exs` (`:requires_example_host`) calls `Crosswake.TestSupport.ExampleHost.load!()` and reads `examples/phoenix_host/.../router.ex` — neither exists standalone in the package, and the tag was not excluded by the package test_helper, so it ran and failed.
- **Fix:** Added `:requires_example_host` to the package `test_helper.exs` exclusions (mirrors core's hermetic-lane behavior), and added a no-op package-local `Crosswake.TestSupport.ExampleHost` stub so the excluded test's `setup_all` reference resolves under `--warnings-as-errors`.
- **Files:** `packages/crosswake_rindle/test/test_helper.exs`, `packages/crosswake_rindle/test/support/example_host.ex`.
- **Commit:** 7a30995.

**3. [Rule 1 — double-load defect] Media helpers excluded from `elixirc_paths`.**
- **Found during:** Task 2. The copied helpers under `test/support/example_host/` were compiled by `elixirc_paths(:test)` (`"test/support"`) AND `Code.require_file`'d by the proof tests → "redefining module" warnings at test runtime. The phase72 hermeticity self-scan REQUIRES the `require_file` calls, so they must be require_file-loaded.
- **Fix:** Narrowed `elixirc_paths(:test)` to compile only the two named support stubs (`study_session_live.ex` + `example_host.ex`), leaving `example_host/` to `require_file` only. No double-load; the plan's `test/support/example_host/` artifact path is preserved.
- **Files:** `packages/crosswake_rindle/mix.exs`, `phase45_rindle_mock_media_test.exs` (self-scan reads helpers via `__DIR__`-relative paths).
- **Commit:** 7a30995.

## Deferred Issues (out of scope — pre-existing)

Two test failures surfaced in the broad core suite and were confirmed **already failing at the phase-start base commit 8cf3ad0** (verified in a throwaway worktree), so they are NOT caused by the rindle extraction. Logged to `deferred-items.md`, not fixed (SCOPE BOUNDARY):

1. `test/crosswake/planning/milestone_transition_reset_test.exs:35` — REQUIREMENTS.md header does not name the active `v16.0` milestone (planning-doc state drift).
2. `test/crosswake/proof/phase52_operator_truth_test.exs:101` — normalized publish-readiness JSON differs from the committed fixture (fixture drift; references only generic companion health, not rindle).

## Known Stubs

- `packages/crosswake_rindle/test/support/example_host.ex` is an **intentional** no-op test stub so the excluded `:requires_example_host` live test resolves under `--warnings-as-errors` without shipping the Phoenix example host. Not a production stub.
- `packages/crosswake_rindle/test/engine_present/rindle.ex` (132-01) remains an intentional engine-present test double.

## Threat Surface

No new threat surface beyond the plan's `<threat_model>`.
- **T-132-05 (re-coupling via surviving core alias):** mitigated — CompanionGuard MapSet gains `Crosswake.Companions.Rindle`; the EXTRACT-03 guard is green and merge-blocking.
- **T-132-02 (engine-present .beam leak):** mitigated — `phase132-proof.yml` job 3 runs `mix clean` before the engine-present build; `:engine_present` excluded by default.
- **T-132-06 / T-132-SC:** unchanged — `$PACKAGE` is a CI-controlled literal; no package-manager installs (only source/test moves + CI YAML).

## Self-Check: PASSED

All created/moved artifacts present on disk; all three task commits (d278491, 7a30995, 1bfafac) present in git history.
