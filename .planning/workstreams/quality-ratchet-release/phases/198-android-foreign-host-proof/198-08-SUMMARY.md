---
phase: 198-android-foreign-host-proof
plan: 08
subsystem: support-truth
tags: [android-ceiling, claim-ceiling-test, overclaim-scanner, unreleased-qualifier, roadmap-amendment]
status: complete

requires:
  - phase: 198-android-foreign-host-proof
    provides: "Plan 06 typed Android evidence ceiling and android_boundary/0; Plan 07 generated parity ledger"
provides:
  - "Crosswake.Guides.AndroidClaimCeilingTest: header-driven ceiling check over the capability map, parity ledger and support matrix, with floor and controls"
  - "Two Android overclaim patterns in the prose scanner, now also scanning the capability map and the ledger"
  - "Support matrix legend line rendering the Android ceiling from android_boundary/0 and linking the ledger"
  - "Ledger guide pinned in unreleased_claim_qualifier @claims; CHANGELOG [Unreleased] names the ledger"
  - "Recorded AND-01 / SC1 corpus-wording amendment and Phase 199 SC6 ledger addition"
affects: [198-09, 198-12, 199]

actuals:
  tokens: 7300
  tasks: 3
  commits: 4
plan_head_before: 7d37e5fe1be41707754f53c3f21e79a7f1fe2276
plan_head_after: f0a8592ae20e746f89ebfa36b8f9a1a275e9b89a

tech-stack:
  added: []
  patterns: ["allowed label set derived from the typed ceiling, not a literal list", "measure scanner findings before making a new pattern merge-blocking"]

key-files:
  created:
    - test/crosswake/guides/android_claim_ceiling_test.exs
    - .planning/workstreams/quality-ratchet-release/phases/198-android-foreign-host-proof/deferred-items.md
  modified:
    - test/crosswake/guides/native_evidence_drift_test.exs
    - test/crosswake/guides/unreleased_claim_qualifier_test.exs
    - lib/crosswake/support_matrix/renderer.ex
    - lib/crosswake/support_matrix/support_matrix.ex
    - guides/support_matrix.md
    - CHANGELOG.md
    - script/collection_assertion_ledger.json
    - test/crosswake/proof/phase170_vacuous_assertion_ledger_test.exs
    - .planning/workstreams/quality-ratchet-release/ROADMAP.md
    - .planning/workstreams/quality-ratchet-release/REQUIREMENTS.md
    - .planning/workstreams/quality-ratchet-release/STATE.md
    - .planning/workstreams/quality-ratchet-release/phases/198-android-foreign-host-proof/198-DECISIONS.md

key-decisions:
  - "Ceiling test allowed set = labels of every level up to android_evidence_ceiling/0 plus the ledger's plain cells; raising the ceiling stays an ADR amendment"
  - "Source lines with true unsuppressed hits were reworded (comment, rule title, evidence text of shell.android.device_verified); the rule id and every regex stay unchanged"
  - "The support-matrix non-claims bullet was left as is: it is a negated statement of the boundary and carries no hit after suppression"

requirements-completed: []

coverage:
  - id: D1
    description: "No Android column in the capability map, ledger or support matrix can show evidence above JVM hermetic proof"
    requirement: AND-01
    verification:
      - kind: unit
        ref: "test/crosswake/guides/android_claim_ceiling_test.exs: 8 tests, 0 violations on the real guides, floor, four control kinds"
        status: pass
    human_judgment: false
  - id: D2
    description: "Prose backstop covers the capability map and ledger with measured zero-finding Android patterns and a red control"
    verification:
      - kind: unit
        ref: "NativeEvidenceDriftTest in the documentation-contracts set (292 ran, 0 failures)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Ledger unreleased qualifier is mandatory; wording amendments are recorded"
    requirement: AND-01
    verification:
      - kind: unit
        ref: "UnreleasedClaimQualifierTest plus awk checks on ROADMAP Phase 198 SC1, Phase 199 SC6 and REQUIREMENTS (303 ran, 0 failures)"
        status: pass
    human_judgment: false
---

# Phase 198 Plan 08: Android claim ceiling and recorded amendments Summary

A header-driven table test now fails if any Android column in the capability map, the parity ledger or the support matrix names evidence above JVM hermetic proof, a measured prose backstop covers the same claim in running text, and the ledger's "not released" status and the AND-01 corpus wording are enforced and recorded.

## What was checked and what happened

- **Task 1 (tracer).** `AndroidClaimCeilingTest` parses every table outside code fences by header and checks each body cell of an `Android evidence` or `Android` column. First run: 0 violations on `guides/capability_map.md`, 0 on `guides/parity_ledger.md`, 0 on `guides/support_matrix.md` (which has no Android-headed column, so its check is a standing guard). The floor requires a real `Android evidence` column in the map, an Android column in the ledger, `JVM hermetic proof` at least once, and map rows equal to `Enum.count(CapabilityMap.canonical(), &(&1.android_evidence == :jvm_hermetic))`. Controls: fabricated emulator and device cells, a required table missing its column, one mutated cell in a copy of the real map (with the "control did not change the copy" raise), and `validate_android_evidence!` raising for `:emulator` and `:device`. 8 tests, all green.
- **Task 2.** The D-24 measurement was written to `198-DECISIONS.md` before any edit. Pre-edit hits (without / with suppression): support matrix guide 2 / 0, capability map 0 / 0, parity ledger 0 / 0, native shell guide 0 / 0, renderer source 1 / 0, `support_matrix.ex` source 3 / 3. The three unsuppressed hits were real source phrasing for the `shell.android.device_verified` rule and were reworded in place; no regex was loosened. After rewording, unsuppressed hits are 0 everywhere. The two patterns were added with `:device_support_overclaim`, both guides joined `@scanned_paths` (so they are also scanned under every existing line rule, which found nothing), and the negative control gained one line per pattern asserting the detail text of the new pattern. The support matrix legend now renders `Android ceiling: <android_boundary/0>` and a pointer to the parity ledger, regenerated through `mix crosswake.docs.sync`.
- **Task 3.** `{"guides/parity_ledger.md", "vector-set hash"}` joined `@claims`; the CHANGELOG `[Unreleased]` "Unpublished support claims" list names the generated ledger with "not released"; ROADMAP Phase 198 SC1 and REQUIREMENTS AND-01 name `test/fixtures/bridge_contract_vectors.json` plus its two native copies and carry an `Amended 2026-11-05, CONTEXT D-01` note; ROADMAP Phase 199 SC6 lists `guides/parity_ledger.md`; STATE Roadmap Evolution has the matching line. The diff of the planning files touches only those four places.

## Floors (I-5)

The planning-time baselines were stale because Plan 07 added tests. Re-measured on the branch before the first task: documentation-contracts set ran 284 (planning said 248). Floors used: Task 2 `--min 292` (284 + 8), Task 3 `--min 294` (292 + 2 generated qualifier tests); the Task 3 run includes `hex_page_test.exs` and ran 303, 0 failures.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Phase 170 collection-assertion ledger red after this branch's test edits**
- **Found during:** Task 2 broader verification (`test/crosswake/proof`, beyond the plan's CI set)
- **Issue:** `script/collection_assertion_ledger.json` no longer matched the tree: 4 unclassified any-sites (2 in the new ceiling test, 1 in the drift control, 1 left by Plan 07 in `parity_ledger_test.exs`) and moved rows in the drift test and `phase166_repository_quality_test.exs` (shifted by Plans 05 and 07). Six Phase 170 tests failed (ledger completeness, byte equality under two locales, raw-versus-ledger reconciliation, guard expression match, `--check`).
- **Fix:** Regenerated the ledger with the script itself (`--emit-snapshot`); all 4 new rows classified `safe-by-construction` by the script. Updated the pinned `@audited_site_count` 286 to 290 and the `assert_any` and `safe-by-construction` counts 143 to 147, with a comment. Phase 170 ledger and guard tests: 26 ran, 0 failures.
- **Files modified:** `script/collection_assertion_ledger.json`, `test/crosswake/proof/phase170_vacuous_assertion_ledger_test.exs`
- **Commit:** ec3a38b8

### Deferred Issues

Logged in `deferred-items.md`, not fixed: `phase52_operator_truth_test.exs:101` (publish-readiness JSON fixture differs; fails identically with this plan's edits reverted) and its wrapper in `Phase135CiOpsProofTest`; two `Phase175LinkedAuthorizationTest` tests that fail only when `test/crosswake/proof` is run without the release-candidate directory.

## Notes for later plans

- Plans 09 to 12 should run `test/crosswake/proof` (or at least the Phase 170 ledger tests) after any test-file edit on this branch; the documentation-contracts set does not include them and root-proof does. Any further edit to `android_claim_ceiling_test.exs` or `native_evidence_drift_test.exs` shifts ledger display lines and needs `elixir script/inventory_collection_assertions.exs --emit-snapshot` again.
- The negation suppression in the prose scanner skips lines containing ` not `, ` never `, ` without ` and similar (blind spot H5); the table test is the primary gate.
- AND-01 was already marked complete by Plan 07 on its floor; this plan adds the recorded wording amendment. CI evidence on the PR is still owed by Plan 12 and was not observed here.

## Known Stubs

None.

## Threat Flags

None. The only new surface is a test and rendered legend text.

## Self-Check: PASSED

- FOUND: test/crosswake/guides/android_claim_ceiling_test.exs, deferred-items.md, this SUMMARY
- FOUND commits: f46600b4, 2ae99fd8, ec3a38b8, f0a8592a (all ancestors of HEAD)
