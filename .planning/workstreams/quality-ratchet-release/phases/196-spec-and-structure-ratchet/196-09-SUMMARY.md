---
phase: 196-spec-and-structure-ratchet
plan: "09"
subsystem: testing
tags: [elixir, mix, xref, compile-graph, source-coverage, actual-main]
requires:
  - phase: 196-08
    provides: Completed policy slice and shared actual-main capture contract
provides:
  - Dependency-free bridge protocol version leaf preserving existing 1.1.0 wire contracts
  - Fresh compilation and exact source/manifest coverage before native Mix zero/cap gates
  - Final-capsule actual-main findings and real Mix fixture controls
affects: [196-15, ARCH-01, phase-verification]
tech-stack:
  added: []
  patterns: [pinned Mix manifest adapter, native threshold exit measurement, closed operational diagnostics]
key-files:
  created:
    - lib/crosswake/bridge/protocol_version.ex
    - script/check_compile_structure.exs
    - script/fixtures/compile_cycle_baseline.exs
    - test/crosswake/proof/compile_structure_ratchet_test.exs
    - .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/scripts/compile-tracer.mjs
    - .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/196-EVIDENCE/main-compile.json
  modified: [lib/crosswake/bridge/contract.ex, lib/crosswake/manifest/types.ex]
key-decisions:
  - "The public Contract API delegates to the leaf; compile-time defaults share its existing 1.1.0 value without moving denial structs or serializers."
  - "Mix 1.19.5 native threshold exits measure the repaired all-cycle cap of4; zero compile and compile-connected thresholds remain separate gates."
  - "Missing, malformed, source-incomplete, digest-stale or BEAM-incomplete compilation evidence fails before xref; xref uses no-compile after a successful force compile."
requirements-completed: []
requirements-addressed: [ARCH-01]
coverage:
  - id: protocol-leaf
    description: Public version and exact existing wire/vector/drift behavior after cycle repair
    verification:
      - kind: integration
        ref: mix test test/crosswake/bridge/contract_test.exs test/crosswake/bridge/bridge_behavioral_vector_test.exs test/crosswake/contract/contract_drift_test.exs
        status: pass
      - kind: integration
        ref: node --test .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/scripts/compile-tracer.mjs
        status: pass
    human_judgment: false
  - id: native-compile-ratchet
    description: Real Mix graph gates and compilation coverage controls
    requirement: ARCH-01
    verification:
      - kind: integration
        ref: mix test test/crosswake/proof/compile_structure_ratchet_test.exs
        status: pass
      - kind: other
        ref: elixir script/check_compile_structure.exs --mode enforce
        status: pass
    human_judgment: false
  - id: actual-main-compile
    description: Final committed capsule measured on actual origin/main before root enforcement
    verification:
      - kind: other
        ref: 196-EVIDENCE/main-compile.json
        status: pass
    human_judgment: false
actuals:
  tokens: 12639
  tasks: 3
  commits: 5
plan_head_before: ebcb5832db91f6749a9905dc01231d0a17d03883
plan_head_after: 796a1536799a354b5cfe3be04f075c70de1bd0e7
duration: 8min
completed: 2026-10-27
status: complete
---

# Phase 196 Plan 09: Native Mix compile-cycle ratchet Summary

One dependency-free protocol-version leaf removes the denial-family compile cycle while real Mix thresholds enforce zero compile cycles, zero compile-connected cycles and a measured four-cycle residual cap.

## Accomplishments

- `ProtocolVersion.version/0` returns the existing1.1.0 value. `Contract.version/0` delegates, Contract's existing default attribute uses the same leaf, and Manifest.Types takes its compile-time default from the leaf. Denial structs, serializers and existing wire assertions remain in their original owners. Only three production files changed.
- The standalone guard accepts explicit root and report/enforce mode. Every collection starts with successful `MIX_ENV=test mix compile --force --warnings-as-errors`, compares source hashes before/after, checks the real compiled manifest, then invokes three separate native graph thresholds. Graph commands use `--no-compile` so they cannot repair a missing/stale manifest behind the coverage barrier. Report mode preserves findings with exit1; operational refusal is exit2 with a closed reason and no accepted report.
- The pinned1.19.5 internal adapter reads real module/source maps. It requires nonempty modules/sources, exact nonempty lib coverage independently compared between recursive walking and wildcard discovery, normalized root-relative paths, source-record/module-record cross references, current content digests/sizes and present BEAM files. It verifies coverage and hashes again after graph collection. Unsupported versions fail closed. Source digests follow the inspected pinned compiler's Blake2 algorithm; no invented manifest fixtures or graph implementation is used.
- Counts come from native integer threshold exits using a successful source-count upper bound and binary search. The repaired all-cycle count is4: separately observed thresholds0,1,2,3 exit1 and4 exits0. This agrees numerically with research but was measured after repair. Remaining cycles are router/scope-defaults, evidence/native-promotion, builder/support-matrix and Contract/Denial; the last now contains export edges only. No `only-direct`, SCC implementation or human-output count parser was introduced.
- The guard's actual-main receipt was committed before the enforcing root test was created. Findings are aggregate graph counts anchored to the first source in the checked roster for the shared receipt schema; that anchor is not a claim that the cycle originates in that file.

## Task Commits

| Task | Commits | Result |
| --- | --- | --- |
|196-09-01|`457eceee`, `f6ee4fba`|Classified native-graph RED, then minimal leaf repair and GREEN wire/graph verification|
|196-09-02|`7d122baf`, `f402d059`|Exact compilation/threshold guard capsule and actual-main findings before root wiring|
|196-09-03|`796a1536`|15 passing real-Mix fixture and repository tests|

Five commits are measured from the persisted plan ledger through796a1536, excluding the later SUMMARY/lifecycle commit. Tokens12639 are ceiling(50553 realized diff characters/4), including the authored receipt and tests. Eight task files changed. Duration8minutes measures the task-commit span from16:16:37Z to approximately16:24:40Z; initial context loading is excluded.

## Commands and Results

All mutable commands ran sequentially in the one existing feature checkout.

1. Initial `MIX_ENV=test mix compile --force --warnings-as-errors` succeeded. `MIX_ENV=test mix xref graph --format cycles --label compile-connected --fail-above 0` exited1 on the named four-file denial cycle. The phase-only native tracer then failed its intended zero-threshold assertion after successful compilation:1 test,1 failure. The unchanged TAP record was classified `RED_EVIDENCE_OK` by `check tdd-red-evidence`. After the leaf repair, the same tracer passed1/1 with exit0, including a fresh force compile and the exact planned compile-connected command.
2. `mix test test/crosswake/bridge/contract_test.exs test/crosswake/bridge/bridge_behavioral_vector_test.exs test/crosswake/contract/contract_drift_test.exs` — exit0,20 tests/0 failures. Existing exact request/reply/denial map assertions and vector/drift checks remain unchanged.
3. `elixir script/check_compile_structure.exs --mode report` and `--mode enforce` — exit0 on the repaired repository:157 lib sources,325 module records,171 total manifest source records; native counts compile0,compile-connected0,all4; separate threshold exits0/0/0. Final enforcement ran after the fixture suite and performed a new force compile. Explicit separate native commands `mix xref graph --no-compile --format cycles --label compile --fail-above 0`, `--label compile-connected --fail-above 0`, and the all-cycle `--fail-above 4`, each under `MIX_ENV=test`, then independently exited0.
4. `node .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/scripts/measure-main.mjs capture --guard compile --candidate HEAD --output .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/196-EVIDENCE/main-compile.json` — helper exit0, actual-main guard exit1 retained honestly. Candidate7d122baf4c2ea598c62bea8537173133e2a801e7, actual origin/mainb8398c38e7d92c8bb99dcbc87fdb2370a47e6e97;156 subjects,compile1,compile-connected1,all4. The two zero-gate findings remain in the receipt.
5. `mix test test/crosswake/proof/compile_structure_ratchet_test.exs` — final exit0,15 tests/0 failures,50.1seconds. The first run had15 tests/1 failure caused by removing the fixture's sole source: the guard correctly reported scope_empty before source_coverage. Keeping a second real compiled source isolates the intended incomplete-coverage assertion; the unchanged guard passed the final suite.
6. Explicit `mix format` and final `mix format --check-formatted` covered all six touched Elixir production/script/fixture/test paths; final check exit0. Every commit used fresh conditional absolute per-file privacy scans and immediate rescans. Capture privacy-before/after each exited0 over148 changed candidate files.

## Real Dependency Controls

The suite creates tiny real temporary Mix projects with test-owned File.write and compiles them using the pinned dependency. No synthetic xref stdout or manually constructed manifest tuple is accepted as evidence.

- An acyclic project passes all three gates. A quote/non-ASCII source filename round-trips in JSON as a normalized relative path.
- A real compile/runtime mixed cycle has exactly one native cycle: both relevant zero gates exit1; all-cycle threshold0 exits1 and threshold1 exits0. The report retains both intended categories.
- Four independent runtime cycles pass the exact committed cap; five fail it. Each project also proves its own count-minus-one fails and exact count passes through direct native commands. Creating identical files in reversed order produces the same report.
- Each compilation-evidence mutation starts after successful real compilation and positive nonempty coverage. Removing/corrupting the actual manifest, modifying a same-size source, adding/removing a source and deleting a compiled BEAM produce their exact closed failure reasons through the production pre-xref coverage barrier. These barrier tests intentionally do not recompile away the corruption. Empty discovery and compilation without any module record also fail closed.
- A real compilation exception containing a synthetic sentinel is reduced to compile_failed; neither the sentinel, raw host path nor PHASE196_REPORT escapes the operational refusal.

## Final Source and Restoration Evidence

|Tool|Git blob|SHA256|
|---|---|---|
|guard|`2aeb75468094ce447a2bf212d6b56b762cdb666f`|`86f271212707b5774d6a0d5dcde51d2131bde948fce97dfe2f217b9fc5078a6a`|
|baseline|`7440dbda76d08490475eccd242b04f43294a1824`|`e886fe60c81b355f05536e79f675c97aead83968420daafe5da16d235db44e68`|

No capsule code changed after measurement. The final root test independently hashes both current files against the receipt. Capture restored branch fix/spec-structure-ratchet and exact HEAD7d122baf; index SHA25650aef923ddb18f79366aa251a782876719d1d97411a0a85c3fbe97c09b0b10ba,6150 tracked files and0 untracked files matched the saved inventory. Subject/capsule/protected hashes were checked before/after. No candidate worktree was created.

## Deviations and Limits

- [Rule3 - Environment] Initial Git metadata writes were sandbox-denied without source loss. Authorized local Git mutations and the single-checkout actual-main capture succeeded with filesystem escalation. The private raw TAP evidence is locally excluded, with SHA25621a88b2615294ab8ed8fe51d86f221162e9fe7416a7c05b4e40b8176e068a315; no private runner paths were committed.
- [Process deviation] Task1 has validated pre-implementation RED/GREEN evidence. The task2 guard and task3 fixture suite were authored before their new behavior assertions were run, so no additional pre-implementation RED/TDD compliance is claimed. All planned acceptance commands and dependency-output controls were subsequently executed. The fixture-only first-run failure and correction above are not presented as a production bug or substitute RED evidence. Mandatory broken-windows tracking records this as open entry40 in `.planning/WINDOWS.md` for independent review.
- The guard is deliberately tied to Mix1.19.5's internal manifest representation. Toolchain changes require adapting and revalidating this isolated boundary. It measures existing contracts, not generic graph correctness or production runtime dependency authority.
- Scoped lifecycle handlers were invoked with explicit workstream selection. Adding a labeled plan position allowed state.advance-plan to advance9to10. The known SDK progress/decorated-roadmap mismatch returned inconsistent phase percentages and missing_phase_details; compact STATE and ROADMAP were directly reconciled to six milestone phases,39/47 plans(83%) and9/17 active-phase plans. Metrics and decisions live in this SUMMARY while STATE stays within40lines. Requirements remain unchecked.
- No stubs, skipped implementation tests or unrun plan acceptance commands remain. No production endpoint, auth path, schema or package dependency was added; file/process input and sanitized proof output stay within the plan threat model. The existing33-control capture-helper receipt remains unchanged; this plan did not claim a fresh helper self-test.

All eight Phase196 requirements and GR-06 remain pending independent verification. Last completed phase remains195. Phase196 is executing,9/17 plans complete; next eligible command is `$gsd-execute-phase 196 --ws quality-ratchet-release`, resuming at196-10-PLAN.md. Do not repeat plans01-09. No push, PR, merge, publish, tag, remote deletion or approval transfer occurred.

## Self-Check: PASSED

All eight task artifacts exist; all five recorded commits are ancestors of HEAD796a1536. The persisted ledger measures5 commits fromebcb5832 and the realized diff measures50553 characters. Both capsule SHA256 values still equal the actual-main receipt; no tracked file was deleted. The final15/15 fixture suite and post-suite enforcement passed after the final implementation change.
