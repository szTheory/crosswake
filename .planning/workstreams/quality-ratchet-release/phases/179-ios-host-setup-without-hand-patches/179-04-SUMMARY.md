---
phase: 179-ios-host-setup-without-hand-patches
plan: 04
subsystem: docs
tags: [ios, phoenix, mix, support-matrix, capability-map, xcode]
requires:
  - phase: 179-01
    provides: Declared iOS host configuration and generator command behavior
  - phase: 179-02
    provides: Managed host outputs, recovery, and bounded project migration
  - phase: 179-03
    provides: Generated iOS host settings and effective Xcode observations
provides:
  - Maintainer guide for declared iOS host generation, inspection, recovery, and migration
  - Canonical support and capability guidance with explicit settings and authority limits
  - Passing candidate evidence for IOS-01, IOS-02, and IOS-03
affects: [phase-180, ios-host-setup, capability-map, support-matrix]
actuals:
  tokens: 8522.75
  tasks: 2
  commits: 4
tech-stack:
  added: []
  patterns: [canonical-renderer-backed-guides, owner-maintained-proof-snapshots]
key-files:
  created: []
  modified:
    - guides/native_shell.md
    - guides/native_shell_upgrade.md
    - guides/support_matrix.md
    - guides/capability_map.md
    - lib/crosswake/support_matrix/renderer.ex
    - lib/crosswake/capability_map/renderer.ex
    - test/crosswake/guides/native_shell_upgrade_test.exs
    - test/mix/tasks/crosswake.docs.sync_test.exs
decisions:
  - Keep generated host settings and static activation claims separate from signing, installation, runtime authority, and physical-device support.
  - Preserve all existing collection-ledger keys and the 52 frozen remediation rows while registering the one newly observed assertion through the owner inventory script.
patterns-established:
  - Canonical capability and support text is rendered into guides and checked for deterministic parity.
requirements-completed: [IOS-01, IOS-02, IOS-03]
coverage:
  - id: D1
    description: Maintainer guides explain the implemented host declaration, safe inspect/generate flow, ownership, recovery, and bounded migration.
    requirement: IOS-01
    verification:
      - kind: unit
        ref: test/crosswake/guides/native_shell_upgrade_test.exs#native shell guide documents the implemented host declaration and flags
        status: pass
      - kind: integration
        ref: MIX_ENV=test mix test focused Plan179-04 shell/proof/config/managed/manifest/activation/guide suite (115 tests)
        status: pass
    human_judgment: false
  - id: D2
    description: Canonical support and capability guides state the observed Xcode settings scope and preserve physical-device and runtime-authority limits.
    requirement: IOS-03
    verification:
      - kind: unit
        ref: test/mix/tasks/crosswake.docs.sync_test.exs#canonical iOS host setup guidance states the observed scope and limits
        status: pass
      - kind: integration
        ref: MIX_ENV=test mix crosswake.docs.sync --check
        status: pass
      - kind: integration
        ref: node --test test/crosswake/shell/ios_host_effective_settings_test.mjs (Node 22.14.0; 20 Xcode cells)
        status: pass
    human_judgment: false
  - id: D3
    description: Selected-candidate regression and package gates pass for host generation, repository proofs, and the iOS package.
    requirement: IOS-02
    verification:
      - kind: integration
        ref: script/verify_repository.sh --stage root-proof (Node 22.14.0)
        status: pass
      - kind: integration
        ref: script/verify_repository.sh --stage example-host-proof (Node 22.14.0; six seed/class combinations)
        status: pass
      - kind: integration
        ref: script/verify_repository.sh --stage ios-package-proof (Swift package tests)
        status: pass
    human_judgment: false
duration: "~3h 30m"
completed: 2026-10-13
status: complete
plan_head_before: eac3bd8ff2fc184f80cadf6c3cf899c017b7af2f
plan_head_after: b6594664270ebc7a4434612c0840f6d3b887f805
---

# Phase 179 Plan 04: iOS Host Setup Without Hand Patches Summary

**Maintainers can follow the declared iOS host setup path, and both generated guides now describe only behavior verified on the candidate.**

## Performance

- **Duration:** Approximately 3 hours 30 minutes; exact start time was not retained.
- **Started:** Before 2026-10-13 14:26 EDT (first task commit).
- **Completed:** 2026-10-13 17:48 EDT.
- **Tasks:** 2/2.
- **Files modified:** 13 tracked files.

## Accomplishments

- Documented the exact `:crosswake, :ios_host` declaration, `.tests`/`.uitests` identity derivation, normal `MIX_ENV` selection, retained development path, `--diff`/`--check`, generation, recovery, and opt-in project-settings migration.
- Documented xcconfig-managed identity/signing fields while keeping host Swift, entitlements, and unrelated PBX edits host-owned. The guides state that simulator settings are unsigned, device inspection does not prove signing or installation, and static activation grants no session, account, scope, media, or replay authority.
- Added canonical support-matrix and capability-map sections, regenerated both guides with `mix crosswake.docs.sync`, and added a renderer contract test for parity and claim limits.
- Passed the required combined focused suite (115 tests), Node 22.14.0 effective-settings test (3 tests; all 20 cells observed), formatting check, docs parity check, and all three named verifier leaves.

## Task Commits

1. **Task 1 RED: guide contract test** — `6dbc37a` (`test(179-04): cover declared iOS host guide contracts`).
2. **Task 1: host setup and migration guides** — `de040f0` (`docs(179-04): document declared iOS host setup`).
3. **Task 2 integration repair: maintained proof contracts** — `faccee5` (`fix(179-04): reconcile maintained proof contracts`).
4. **Task 2: canonical support and capability guidance** — `b659466` (`feat(179-04): render declared iOS host guidance`).

**Plan metadata:** Not committed here; the parent executor owns phase state and metadata commits.

## Verification

- `test/crosswake/guides/native_shell_upgrade_test.exs` passed after an initial red run identified missing `entry_route_id` guidance.
- Final focused host/proof/config/managed/manifest/activation/guide suite: **115 tests, 0 failures**.
- `node --test test/crosswake/shell/ios_host_effective_settings_test.mjs` on Node 22.14.0: **3 tests, 0 failures**. It observed all 20 target/configuration/SDK cells, checked the automatic device-signing declaration oracle, and confirmed missing declaration fails before Xcode runs.
- `MIX_ENV=test mix crosswake.docs.sync --check` passed. The final renderer and generated guide outputs match.
- `mix format --check-formatted` passed for all changed Elixir files.
- `root-proof` passed: companion suites had 11, 55, 139, 53, 98, and 3 tests with 0 failures; core had **2,087 tests, 0 failures** (81 excluded).
- `example-host-proof` passed with all six tagged/complete classes across seeds 17, 101, and 1009; the isolation matrix reported no residue.
- `ios-package-proof` passed, including all Swift package test suites.

## Deviations from Plan

### Auto-fixed integration issues

1. **Stale collection-assertion snapshot and frozen-row mappings.** Root-proof exposed one legitimate new safe-by-construction collection assertion and six moved proof-lane row locations. The maintained inventory script regenerated the ledger: all original 230 keys remain, the new assertion is registered, and the closed 52-row remediation manifest is unchanged. The hard-coded measured total and shape/bucket counts now reflect 231 rows. The frozen-guard failure came from stale ledger display locations; the current matching guards were present. The Phase 170 tests pass without weakening their assertions.
2. **Shell template drift.** The template drift test measured live SHA-256 `a6009f2c7ea273c15d241ca4cb397e3fad02fc2ec9945ff77caf0b8b60578183` against the stale checked-in hash. The existing `mix crosswake.bump_template_version` owner task advanced the shell generator epoch from 3 to 4 and updated the golden hash.
3. **Proof-lane version expectations.** Three proof-lane contract assertions expected version 5 while the live generator and manifest emit version 6. The assertions were aligned with the generated contract; the corresponding template contract tests pass.
4. **Candidate planning-copy isolation.** Candidate-local copies of `STATE.md`, `ROADMAP.md`, and `REQUIREMENTS.md` caused an unrelated milestone-transition test to read the wrong state. Per the parent executor's bounded authorization, only those three candidate copies were restored to their exact candidate HEAD bytes. The milestone test then passed. Root planning state was not changed by this executor.

**Total deviations:** 4 bounded integration repairs. All were directly demonstrated by failing repository gates; no CI lane or product feature was added.

## Issues Encountered

- The first example-host named-leaf run exited nonzero after the stage wrapper deleted its temporary logs. Its cause is unknown and is not attributed to a product defect. A later run on the same final source retained a private temporary log, passed the complete six-class matrix, and the raw log was deleted after extracting only safe pass lines.
- An early verifier invocation used a nonexistent Node path and fell through to Node 26.10, so repository-preflight correctly blocked it. The installed pinned Node 22.14.0 was found at `<home>/.asdf/installs/nodejs/22.14.0/bin`; all named final leaves passed with that PATH.
- `mix deps.get` reported an expired Hex authentication session while resolving unchanged locked dependencies. Dependency resolution and compilation succeeded; no package was added or upgraded.

## Source and Commit Identity

- Candidate: `/private/tmp/crosswake-phase179-impl`, branch `agent-phase179-01`.
- Candidate base: `eac3bd8ff2fc184f80cadf6c3cf899c017b7af2f`.
- Pinned clean source: `/private/tmp/crosswake-phase179-source`, commit `d0dbdf7bf196cea167ced3c50cf620bf3cb2452b`, tree `12a0f1bf3c32ecdde0326f4a288b597b11e33b06`.
- Plan commits measured from candidate base: 4; final candidate head `b6594664270ebc7a4434612c0840f6d3b887f805`.
- Realized diff: 34,091 characters, or 8,522.75 `chars/4` estimate tokens.

## Next Phase Readiness

Plan 04 closes the guide and scoped regression gates for IOS-01/02/03. Phase 180 may receive a prepared generated candidate. This work establishes neither a physical-iPhone run nor first-adopter activation, runtime authentication/replay authority, signed installation, or Android expansion. The first-adopter workstream remains parked at its recorded sanitized-route handoff gate.

---
*Phase: 179-ios-host-setup-without-hand-patches*
*Completed: 2026-10-13*
