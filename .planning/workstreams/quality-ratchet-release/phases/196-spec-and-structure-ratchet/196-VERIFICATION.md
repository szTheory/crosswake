---
phase: 196-spec-and-structure-ratchet
verified: 2026-10-29T14:00:00Z
status: passed
score: 5/5 must-haves verified
covered_files:
  - ".planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/196-01-PLAN.md"
  - ".planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/196-01-SUMMARY.md"
  - ".planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/196-02-PLAN.md"
  - ".planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/196-02-SUMMARY.md"
  - ".planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/196-03-PLAN.md"
  - ".planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/196-03-SUMMARY.md"
  - ".planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/196-04-PLAN.md"
  - ".planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/196-04-SUMMARY.md"
  - ".planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/196-05-PLAN.md"
  - ".planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/196-05-SUMMARY.md"
  - ".planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/196-06-PLAN.md"
  - ".planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/196-06-SUMMARY.md"
  - ".planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/196-07-PLAN.md"
  - ".planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/196-07-SUMMARY.md"
  - ".planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/196-08-PLAN.md"
  - ".planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/196-08-SUMMARY.md"
  - ".planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/196-09-PLAN.md"
  - ".planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/196-09-SUMMARY.md"
  - ".planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/196-10-PLAN.md"
  - ".planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/196-10-SUMMARY.md"
  - ".planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/196-11-PLAN.md"
  - ".planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/196-11-SUMMARY.md"
  - ".planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/196-12-PLAN.md"
  - ".planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/196-12-SUMMARY.md"
  - ".planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/196-13-PLAN.md"
  - ".planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/196-13-SUMMARY.md"
  - ".planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/196-14-PLAN.md"
  - ".planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/196-14-SUMMARY.md"
  - ".planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/196-15-PLAN.md"
  - ".planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/196-15-SUMMARY.md"
  - ".planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/196-16-PLAN.md"
  - ".planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/196-16-SUMMARY.md"
  - ".planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/196-17-PLAN.md"
  - ".planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/196-17-SUMMARY.md"
  - "lib/crosswake/bridge.ex"
  - "lib/crosswake/bridge/protocol_version.ex"
  - "lib/crosswake/policy/compiler.ex"
  - "packages/crosswake_threadline/test/crosswake/proof/phase139_threadline_cleanroom_test.exs"
  - "script/absence_collection_ast.exs"
  - "script/check_absence_is_not_success.exs"
  - "script/check_compile_structure.exs"
  - "script/check_rescue_boundaries.exs"
  - "script/check_runtime_dependencies.exs"
  - "script/evaluate_runtime_dependencies.exs"
  - "test/crosswake/guides/evidence_manifest_test.exs"
  - "test/crosswake/offline/journal_test.exs"
  - "test/crosswake/offline/safe_observation_test.exs"
  - "test/crosswake/policy/finite_product_test.exs"
  - "test/js/ci_secret_masking.test.mjs"
covered_digest: "v4:sha256:540393fc2b77e6ee574ac5c2c1592b2a3099949b6abed01553a753281f182e92"
behavior_unverified: 0
overrides_applied: 0
deferred:
  - truth: "A Muex pilot record covers SafeObservation, Journal, Policy.Compiler/Route and Bridge.Contract with non-zero mutants, baseline scores, survivors and a written adopt/drop decision (ROADMAP success criterion 3 / SPEC-04)"
    addressed_in: "v29.0"
    evidence: "ROADMAP Phase 196 'Moved' line and REQUIREMENTS.md traceability row 'SPEC-04 | v29.0 | Moved (criteria intact)'; recorded roadmap change 2026-10-27 under the overrun cut order (D-03/D-24). Recorded as moved, not as passed or failed."
coincidental_reliance_items: []
---

# Phase 196: Spec and Structure Ratchet Verification Report

**Phase Goal:** The offline, policy and bridge specs that Android and later parity work consume cannot pass by asserting nothing, and the module structure has ratchets that fail on regressions.
**Verified:** 2026-10-29
**Status:** passed
**Re-verification:** No, initial verification
**Subject:** `docs/196-uat` is `origin/main` 97ec5f7b plus two docs-only commits (`git diff --stat origin/main HEAD` shows only `196-UAT.md` and `196-SECURITY.md`), so the code tree verified here is the code tree on main.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | SC1: `evidence_manifest_test.exs` and `phase139_threadline_cleanroom_test.exs` no longer pass vacuously; Elixir, Swift and Kotlin vector consumers pin counts and fail on a missing vector; the delta-only absence guard rejects new unproved collection assertions, glob loops without cardinality and literal `assert true`, with negative controls and the known sites fixed | VERIFIED | `test/crosswake/guides/evidence_manifest_test.exs` has a strict generated-manifest consumer (empty or missing routes, zero captured routes, empty artifact lists all fail with named diagnostics) and the optional lane is visibly excluded, not silently green. Threadline cleanroom test asserts `length(event_names) == 3`, `byte_size == 64`, and exact excluded and executed counts in the consumer output. No `assert true` remains in either file. Elixir vector test pins `15` loaded, unique IDs, and `9` completed (`bridge_behavioral_vector_test.exs:83-84,:123`). Swift pins `15`/`14` (`BridgeConformanceTests.swift:220,256`), reply `2`/`2` (`BridgeReplyLegTests.swift:52,105`), topology `5` loaded / `1` selected / `1` completed (`NavigationCoordinatorTests.swift:42-57`), each with a `CW-VECTOR-MISSING` failure. Kotlin pins `15`/`14` (`BridgeConformanceTest.kt:160,233`) and reply `2`/`2` (`BridgeReplyLegTest.kt:37,109`). I ran `elixir script/check_absence_is_not_success.exs` and got exit 0 with `findings=84 delta=0`, and `absence_is_not_success_test.exs` plus the Phase 170 ledger test pass (see Spot-Checks). Swift and Kotlin runs were not re-executed by me; they are credited from `landed.json` children `vector-swift-*` and `vector-kotlin-*` (all `pass`, non-null test counts, 0 failures). |
| 2 | SC2: Boundary specs for `Journal.scope_ref!/1` (15/16/128/129, newline injection, input never echoed) and `SafeObservation.new/1` (0, 1_000_000, 1_000_001, adversarial strings); the finite route-policy product enumerated against a hand-written verdict table; compiler errors pin `{key, route_id}`; `validation_key` never nil | VERIFIED | `journal_test.exs:6-70` carries the suffix 15/16/128/129 table and a closed value-free diagnostic contract. `safe_observation_test.exs:135-140` covers `0`, `1_000_000`, `1_000_001`, negative and float rejections. `finite_product_test.exs` asserts `length(cases) == 108`, uniqueness, and a literal 9-cell `@runtime_offline_keys` table independent of production code; the loop counts `completed == 108`. `compiler_test.exs:31-32` pins `{key, route_id}` pairs and `is_atom(key) and not is_nil(key)`. `Compiler.validation_key/1` is a private `defp` (`compiler.ex:182-186`): it returns a non-nil atom or raises `ArgumentError`, so it can never return nil. |
| 3 | SC4: A test fails on any compile-label xref cycle and on all-cycles above the committed baseline; the `bridge/contract`-`bridge/denial`-`manifest/types`-`shell/denial` compile cycle is broken; an AST test fails on bare `rescue _ ->` in the six module families and the three `bridge.ex` rescues return explicit results; a test fails when a package's runtime direct deps differ from the committed list with one-line justifications; each ratchet has a negative control | VERIFIED | ARCH-01: `lib/crosswake/bridge/protocol_version.ex` is a dependency-free leaf; `contract.ex:10,106` and `manifest/types.ex:772` take their version from it. Running `elixir script/check_compile_structure.exs --mode enforce` gives exit 0, `compile_cycles 0`, `compile_connected 0`, `all_cycles 4` against the committed cap `4` (`script/fixtures/compile_cycle_baseline.exs`). `compile_structure_ratchet_test.exs` has controls for mixed edges, cap exact versus cap+1, empty discovery, missing manifest, and compile failure. ARCH-02: `bridge.ex:699,716,743` now `rescue _error in [named classes] -> {:error, :atom}`; there is no bare `rescue _ ->`. `check_rescue_boundaries.exs` gives exit 0 with `rescues=9 exceptions=2 findings=0`; `rescue_boundary_ratchet_test.exs` has about 20 negative controls. ARCH-03: `script/fixtures/runtime_dependency_baseline.exs` lists the six projects with a one-line purpose per dependency; `check_runtime_dependencies.exs` gives exit 0 over 12 isolated executions (both release branches), 32 dependencies, 0 findings; `runtime_dependency_ratchet_test.exs` covers added, removed, reclassified and release-only drift. |
| 4 | GR-06 (carried from Phase 195): bounded secret-masking workflow grammar closure, with every candidate supported, denied or unknown and zero live denied or unknown | VERIFIED | `node --test test/js/ci_secret_masking.test.mjs` gives 207 tests, 207 pass, 0 fail. The standalone census (`--phase196-census-root .`) gives 28 workflows, 97 references, 13 candidates equal to 13 supported plus 0 denied plus 0 unknown, 0 findings. |
| 5 | SPEC-04 is recorded as moved intact to v29.0, not as passed or failed | VERIFIED | `REQUIREMENTS.md:44` marks SPEC-04 moved with its criteria intact, and the traceability row 107 reads `SPEC-04 | v29.0 | Moved (criteria intact)`. `ROADMAP.md` Phase 196 carries a `Moved` line and marks criterion 3 as not a v28 gate. `mix.exs`, `mix.lock` and `packages/*/mix.exs|mix.lock` contain no Muex. `196-EVIDENCE/MUEX-DECISION.md` records the pilot as `pending` with no adopt/drop verdict. `landed.json` carries `spec04.disposition: moved_to_v29`. |

**Score:** 5/5 truths verified (0 behavior-unverified). Roadmap success criterion 3 is carried in Deferred Items, not in the score.

### Prohibitions (plan 196-01 `must_haves.prohibitions`, status unresolved in plan)

| Statement | Resolution |
|-----------|------------|
| MUST NOT promote hermetic/JVM vector evidence into device, adopter or new native capability claims | Resolved by inspection. `landed.json` sets `native_claim_ceiling: jvm_hermetic_and_swift_package_only_never_device`. The phase touches only existing vector readers and adds no emulator, device or feature claim. This is a judgment-tier item, so it is a non-authoritative verdict and no standing approval is implied. |
| MUST NOT satisfy SPEC-04 by calling an incomplete or zero-target pilot a drop | Resolved by inspection. `MUEX-DECISION.md` records `pending`, no adopt/drop. The requirement was moved by a recorded roadmap change, not dropped. |

### Deferred Items

| # | Item | Addressed In | Evidence |
|---|------|--------------|----------|
| 1 | SPEC-04 Muex pilot (ROADMAP criterion 3) | v29.0 | REQUIREMENTS.md line 44 and traceability row 107; ROADMAP Phase 196 `Moved` line. Both attempts and 5/5 accepted controls are preserved in `196-EVIDENCE`. |

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `script/absence_collection_ast.exs`, `script/check_absence_is_not_success.exs`, `script/fixtures/absence_collection_baseline.exs` | Delta-only AST absence guard with reviewed residual multiset | VERIFIED | Runs enforce mode with delta 0. 84 residual entries are reviewed debt keyed by file, context and expression digest. |
| `lib/crosswake/bridge/protocol_version.ex` | Dependency-free protocol leaf | VERIFIED | Wired from `Bridge.Contract` and `Manifest.Types`. |
| `script/check_compile_structure.exs`, `script/fixtures/compile_cycle_baseline.exs` | Compile-label and all-cycle ratchet | VERIFIED | Exit 0 in enforce mode. |
| `script/check_rescue_boundaries.exs`, `script/fixtures/rescue_boundary_exceptions.exs` | AST bare-rescue ratchet with two reviewed exceptions | VERIFIED | Exit 0, 0 findings. |
| `script/check_runtime_dependencies.exs`, `script/evaluate_runtime_dependencies.exs`, `script/fixtures/runtime_dependency_baseline.exs` | Per-package runtime dependency list | VERIFIED | Exit 0 over 12 executions. |
| `test/crosswake/offline/{journal,safe_observation}_test.exs`, `test/crosswake/policy/{finite_product,compiler}_test.exs` | Boundary and exhaustive specs | VERIFIED | Pass in the focused run. |
| `196-EVIDENCE/landed.json` | Actual-main landed proof | VERIFIED | `verdict: pass`, 40 children, `failing: []`, `base_drift_at_write: false`, merge `51a1885c`. |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `Bridge.Contract.version/0` and `Manifest.Types` | `Bridge.ProtocolVersion` | `defdelegate` and compile-time attribute | WIRED | `contract.ex:10,106`, `types.ex:772`. |
| `check_absence_is_not_success.exs` | `absence_collection_ast.exs` and baseline | exact scope and delta compare | WIRED | Enforce run reports `files=317 findings=84 delta=0`. |
| Ratchet scripts | root `mix test` | `test/crosswake/proof/*_ratchet_test.exs` | WIRED | Included in the default suite (focused run executed them; `landed.json` `root-core-suite` 2920 tests). |
| Guards | CI / landed proof | `landed.json` `requirement_map` | WIRED | All eight IDs (`SPEC-01/02/03/05`, `ARCH-01/02/03`, `GR-06`) map to passing children. |

### Data-Flow Trace (Level 4)

Not applicable. The phase delivers tests, scripts and a protocol leaf, with no rendered dynamic data.

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Compile structure enforce | `elixir script/check_compile_structure.exs --mode enforce` | exit 0; cycles 0/0; all 4 vs cap 4 | PASS |
| Absence guard enforce | `elixir script/check_absence_is_not_success.exs` | exit 0; findings 84, delta 0 | PASS |
| Rescue boundaries | `elixir script/check_rescue_boundaries.exs` | exit 0; findings 0 | PASS |
| Runtime dependencies | `elixir script/check_runtime_dependencies.exs` | exit 0; findings 0 | PASS |
| Focused ExUnit (offline, finite_product, compiler, bridge, evidence_manifest, 4 ratchet tests, phase170 ledger) | one `mix test` run with the listed paths | 339 tests, 0 failures, 1 excluded | PASS |
| Secret masking and GR-06 census | `node --test test/js/ci_secret_masking.test.mjs` and `--phase196-census-root .` | 207/207; 13 = 13 supported + 0 + 0 | PASS |

### Probe Execution

No `probe-*.sh` is declared or implied by this phase. Skipped.

### Requirements Coverage

The workstream `REQUIREMENTS.md` was read directly, because the gap-analysis gate reads the root file. Plan frontmatter IDs, which are the union of `SPEC-01/02/03/04/05` and `ARCH-01/02/03`, all appear there.

| Requirement | Source Plans | Description | Status | Evidence |
|-------------|--------------|-------------|--------|----------|
| SPEC-01 | 196-01..05, 15-17 | Vacuous manifest and cleanroom tests fixed; vector counts pinned (Elixir, Swift, Kotlin) | SATISFIED | Truth 1. |
| SPEC-02 | 196-01, 06, 12, 15-17 | Delta-only absence guard with negative controls; known sites fixed | SATISFIED | Truth 1. |
| SPEC-03 | 196-07, 15-17 | `scope_ref!/1` and `SafeObservation.new/1` boundary specs | SATISFIED | Truth 2. |
| SPEC-04 | 196-13, 196-14 | Muex pilot | MOVED to v29.0 (criteria intact); not passed, not failed | Truth 5. Plan 196-14 is retired, not executed to completion. |
| SPEC-05 | 196-08, 15-17 | Exhaustive route-policy product; `{key, route_id}` pins; `validation_key` never nil | SATISFIED | Truth 2. |
| ARCH-01 | 196-01, 09, 15-17 | Compile cycle broken; cycle and cap ratchet | SATISFIED | Truth 3. |
| ARCH-02 | 196-01, 10, 15-17 | Explicit results for the three `bridge.ex` rescues; AST bare-rescue test | SATISFIED | Truth 3. |
| ARCH-03 | 196-01, 11, 15-17 | Runtime dependency list with justification | SATISFIED | Truth 3. |
| GR-06 | 196-12 (carried from Phase 195) | Bounded workflow grammar closure | SATISFIED | Truth 4. It is a carried debt and has no row in the workstream `REQUIREMENTS.md`; it is defined in the Phase 195 review and in `196-CONTEXT.md`. |

No orphaned IDs: every Phase 196 row in the REQUIREMENTS traceability table (SPEC-01..05, ARCH-01..03) is claimed by at least one plan. `REQUIREMENTS.md` checkboxes and status cells still read `Pending` for the seven in-scope IDs. That is a bookkeeping step for the orchestrator after this verification, not a code gap.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| (phase-modified scripts and tests) | n/a | `TBD`/`FIXME`/`XXX` scan | None found | n/a |
| `script/fixtures/absence_collection_baseline.exs` | n/a | 84 baselined residual collection assertions (82 universal predicates, 2 historical glob inventories) | Info | The guard is delta-only by requirement. The residuals are reviewed debt, not new guarantees, and the file header says so. No new occurrence can be added without failing the guard. |

### Advisory Notes (non-blocking; none change the status)

1. Plan 196-16 recorded two unexplained single-child failures (`example-host-proof`; `root-core-suite` 1 of 2920) that passed when re-run alone. The landed proof on `51a1885c` passed all 40 children, and my focused run of the same suites passed. This is not currently evidenced as a defect, but a flaky-test watch is reasonable.
2. PR 265 commit `94d2d788` changed `test/js/ci_secret_masking.test.mjs` after the grammar receipt (blob `e0891db6` to `10944c82`, a timing bound only). The snapshot tools (`phase-evidence` self-test `stale_measured_blob`, `measure-main verify-source` `main_ref_mismatch`) therefore refuse at HEAD. Both fail closed by design. The test itself passes 207/207 and the census is unchanged. I did not run `measure-main.mjs self-test`, which rewrites a tracked file.
3. `196-EVIDENCE/MUEX-DECISION.md` is a point-in-time record that says the roadmap deferral was proposed and not yet applied. The deferral has since been applied (ROADMAP and REQUIREMENTS). The file is not stale in a harmful way, but a reader should take the ROADMAP line as authoritative.
4. Native evidence (Swift package, Kotlin JVM) is credited from `landed.json` and was not re-executed by me. Claims stay at JVM-hermetic and Swift-package level, with no device or emulator claim.

### Human Verification Required

None. The project's zero-human rule applies, and every claim above was checked by a command or artifact inspection.

### Gaps Summary

No gaps. All in-scope v28 requirements (SPEC-01, SPEC-02, SPEC-03, SPEC-05, ARCH-01, ARCH-02, ARCH-03) and the carried GR-06 are implemented, wired and passing on the code that is on main. SPEC-04 is recorded as moved to v29.0 with its criteria intact.

---

_Verified: 2026-10-29_
_Verifier: Claude (gsd-verifier)_
