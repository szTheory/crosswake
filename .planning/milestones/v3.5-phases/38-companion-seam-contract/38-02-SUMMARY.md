---
phase: 38-companion-seam-contract
plan: 02
subsystem: companion
tags: [elixir, behaviour, telemetry, doctor, hermetic-proof, test-support]

requires:
  - phase: 38-01
    provides: Crosswake.Companion behaviour (6 callbacks), Crosswake.Companion.State struct, telemetry dep

provides:
  - phase_38_companion_seam_findings/0 in doctor.ex emitting fail-closed :error finding (D-04, COMP-02)
  - :telemetry.span wrapping validate_dependency/0 call with companion_id metadata (D-11b, COMP-03)
  - Crosswake.TestSupport.StubCompanion + BrokenCompanion test-support fixtures (D-13, SC#1)
  - Hermetic phase38 proof test proving SC#1/SC#2/SC#4 in merge-blocking lane (D-13)

affects:
  - 38-03 and beyond (companions guide, advisory lane, support-matrix truth)
  - 39-rulestead-gating-seam (can now satisfy @behaviour Crosswake.Companion and be verified by doctor)
  - 42-rulestead-companion (real companion implementation follows this pattern)

tech-stack:
  added: []
  patterns:
    - Application.get_env(:crosswake, :companions, []) runtime registry read in doctor (not compile_env — intentional for testability)
    - Per-companion config map read as Application.get_env(:crosswake, companion_id, %{}) (D-03 choice, see Decisions Made)
    - :telemetry.span/3 first use site in lib/ — emits :start/:stop/:exception events synchronously (D-11c)
    - Test fixture companion: @behaviour + @impl true per callback, no use macro, test/support/ auto-compiled
    - async: true proof test using Application.put_env + on_exit cleanup for hermetic isolation

key-files:
  created:
    - test/support/stub_companion.ex
    - test/crosswake/proof/phase38_companion_contract_test.exs
  modified:
    - lib/crosswake/doctor/doctor.ex

decisions:
  - "Runtime Application.get_env(:crosswake, :companions, []) rather than compile_env in phase_38_companion_seam_findings/0 — the doctor is a runtime Mix task not a compiled macro; runtime read lets the proof test register fixtures via put_env without a compile cycle. The trade-off is that host apps must have companions configured at runtime, not compile time only; acceptable since companion registration is a startup-time config pattern."
  - "Per-companion config map key (D-03): Application.get_env(:crosswake, companion_id, %{}) — uses the companion's own atom ID as the key under :crosswake. Mirrors FunWithFlags-style per-scope config isolation. The companion receives only its own config subtree, not the full :crosswake app env. Alternative (not chosen): pass nil or a fixed :companion key — rejected because different companions would need to share a key namespace or each know the full app config shape."
  - "Companion alias not added to doctor.ex alias block — the alias Crosswake.Companion would be unused (companion calls are on dynamic module variables, not the behaviour module itself) and --warnings-as-errors would reject it. The behaviour module is referenced only in companion.ex and the test fixture, not in the doctor."
  - "advisor finding for disabled+present companion (D-09 mapping): emits :advisory code companion.disabled_dependency_present. No :error, no silent skip — visible in doctor output but does not escalate report status."

metrics:
  duration: 4min
  completed: 2026-05-30
---

# Phase 38 Plan 02: Companion Seam — Doctor Wiring + Hermetic Proof Summary

**Doctor wiring + test-support fixtures + hermetic proof: fail-closed `companion.dependency_missing` `:error` finding (D-04/COMP-02) + `:validate_dependency` telemetry span (D-11b/COMP-03) + SC#1/SC#2/SC#4 proved in merge-blocking lane with no new CI file**

## Performance

- **Duration:** 4 min
- **Started:** 2026-05-30T01:21:30Z
- **Completed:** 2026-05-30T01:25:52Z
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments

- Created `test/support/stub_companion.ex` with two fixtures: `Crosswake.TestSupport.StubCompanion` (happy-path, all 6 callbacks, `validate_dependency/0` returns `:ok`) and `Crosswake.TestSupport.BrokenCompanion` (fail-closed path, `validate_dependency/0` returns `{:error, [Crosswake.TestSupport.DeliberatelyAbsentLib]}`). Both compile under `MIX_ENV=test --warnings-as-errors` with no "callback not implemented" warnings — SC#1 proved.
- Added `phase_38_companion_seam_findings/0` to `lib/crosswake/doctor/doctor.ex`: reads `Application.get_env(:crosswake, :companions, [])` at runtime, iterates companions, wraps `validate_dependency/0` in `:telemetry.span([:crosswake, :companion, :validate_dependency], ...)` synchronously (D-11c), emits `:error` finding `companion.dependency_missing` when enabled + `{:error, mods}` (D-04), `:advisory` finding when disabled + `:ok` (D-09). Result wired into `run/1` findings concatenation; `Report.status` auto-escalates — fail-open structurally impossible.
- Created `test/crosswake/proof/phase38_companion_contract_test.exs` with 4 tests: hermeticity self-assertion, SC#1 (StubCompanion all-callbacks check), SC#2 (BrokenCompanion → doctor `companion.dependency_missing` `:error` + `report.status == :error`), SC#4 (telemetry `:stop` event received with `companion_id: :stub_companion, result: :ok`). All 4 pass; full hermetic lane (318 tests, 0 failures, 38 excluded) stays green.
- `lib/crosswake/commerce.ex` byte-for-byte unchanged (D-12). No new `.github/workflows/` file (D-13). No `lib/crosswake/companions/` directory created (D-14).

## Task Commits

1. **Task 1: Create StubCompanion + BrokenCompanion test-support fixtures** - `89b8ff1` (feat)
2. **Task 2: Wire phase_38_companion_seam_findings/0 + validate_dependency telemetry span** - `6b4afb0` (feat)
3. **Task 3: Hermetic phase38 proof test — SC#1, SC#2, SC#4** - `87a9430` (feat)

## Files Created/Modified

- `test/support/stub_companion.ex` — `Crosswake.TestSupport.StubCompanion` + `Crosswake.TestSupport.BrokenCompanion`; both implement all 6 `@behaviour Crosswake.Companion` callbacks with `@impl true`; `Crosswake.TestSupport.DeliberatelyAbsentLib` is deliberately undefined
- `lib/crosswake/doctor/doctor.ex` — added `phase_38_companion_seam_findings/0` private function (70 lines) + wired `phase_38_findings` into `run/1` findings concatenation; no alias added (unused alias rejected by `--warnings-as-errors`)
- `test/crosswake/proof/phase38_companion_contract_test.exs` — `Crosswake.Proof.Phase38CompanionContractTest`; untagged, `async: true`, hermetic; inline `MinimalRouter` fixture; `setup` with temp install manifest; 4 tests

## Decisions Made

- **Runtime `get_env` not `compile_env`:** `phase_38_companion_seam_findings/0` reads the companion registry at runtime via `Application.get_env(:crosswake, :companions, [])`. The doctor is a runtime Mix task, not a compiled macro; runtime read lets the proof test register fixtures via `put_env` without recompiling. Documented in test module `@moduledoc`. See Decisions in frontmatter for trade-off analysis.
- **Per-companion config map key (D-03):** `Application.get_env(:crosswake, companion_id, %{})` — companion's own atom ID is the key under `:crosswake`. The companion receives only its own config subtree, not the full app env. See frontmatter decisions for alternatives considered.
- **No `alias Crosswake.Companion` in doctor.ex:** The `--warnings-as-errors` constraint rejected the alias as unused. Companion callbacks are invoked on dynamic module variables (`companion.enabled?/1` etc.), not on the behaviour module itself. The plan suggested adding the alias but the compiler correctly flags it as unused in this context.
- **Inline `MinimalRouter` in proof test:** Doctor.run requires a route source to compile the manifest. A minimal in-file router provides this without depending on the example host, preserving hermetic-lane discipline.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] route_source required for Doctor.run — added inline MinimalRouter**
- **Found during:** Task 3 — SC#2 and SC#4 tests failed with `UndefinedFunctionError: nil.__routes__/0`
- **Issue:** `Doctor.run/1` calls `Crosswake.Policy.Compiler.compile/2` which calls `module.__routes__/0` on the `route_source` option. Without `route_source:`, it receives `nil` and crashes.
- **Fix:** Added an inline `defmodule MinimalRouter` using `Crosswake.Router` with a single live route; passed `route_source: MinimalRouter` to `Doctor.run/1` in SC#2 and SC#4 tests.
- **Files modified:** `test/crosswake/proof/phase38_companion_contract_test.exs`
- **Commit:** 87a9430

**2. [Rule 1 - Bug] Unused alias rejected by --warnings-as-errors — removed `alias Crosswake.Companion`**
- **Found during:** Task 2 — compile failed with `warning: unused alias Companion`
- **Issue:** The plan requested adding `alias Crosswake.Companion` to the doctor.ex alias block. However, the implementation calls companion callbacks on dynamic module variables (`companion.enabled?/1`, not `Companion.enabled?/1`), so the alias is never referenced and `--warnings-as-errors` rejects it.
- **Fix:** Did not add the alias. The Companion behaviour is accessible through the dynamic variable without an alias.
- **Files modified:** `lib/crosswake/doctor/doctor.ex`
- **Commit:** 6b4afb0

## Issues Encountered

None beyond the two auto-fixed deviations above.

## Known Stubs

None — all callbacks return real values. `Crosswake.TestSupport.DeliberatelyAbsentLib` is deliberately absent (it is the missing-dep fixture, not a stub).

## Threat Surface Scan

**T-38-04 (Tampering/Repudiation — fail-closed path):** Mitigated. `phase_38_companion_seam_findings/0` emits `severity: :error` when an enabled companion's dependency is absent. `Report.status` line 137 derives `:error` from `Enum.any?(findings, &(&1.severity == :error))`. SC#2 proof test asserts both the finding and `report.status == :error` — silent fail-open is structurally impossible.

**T-38-05 (DoS — companion callback invocation):** `:telemetry.span/3` emits `:exception` event on raise; a crashing companion surfaces via the span rather than a silent skip. Full crash-isolation of the registry loop is accepted-as-is for Phase 38 (registry is host-controlled).

**T-38-06 (Information disclosure — span metadata):** Span metadata restricted to `%{companion_id: atom(), route_id: nil, result: :ok | {:error, [module()]}}` — no host config map, no secrets. SC#4 test asserts exact metadata shape.

No new network endpoints, auth paths, file access patterns, or schema changes at trust boundaries introduced beyond the registered surface.

## Next Phase Readiness

- COMP-02 satisfied: `mix crosswake.doctor` emits `:error` finding naming the missing dependency when an enabled companion's optional library is absent; never silent, never a crash.
- COMP-03 (emit-side half) satisfied: `[:crosswake, :companion, :validate_dependency]` span fires for real with `companion_id` metadata in `:stop` event.
- Phase 39 (rulestead gating seam) can now declare `@behaviour Crosswake.Companion` and be verified by the doctor pipeline.
- Phase 42 (rulestead companion implementation) has a copy-able fixture pattern in `test/support/stub_companion.ex`.
- Hermetic lane discipline: 318 tests pass, 38 excluded (`requires_example_host`), 0 failures.

---
*Phase: 38-companion-seam-contract*
*Completed: 2026-05-30*
