---
phase: 171-version-authority-split
verified: 2026-09-17T18:22:33Z
status: passed
score: 7/7 must-haves verified
covered_files:
  - .planning/workstreams/quality-ratchet-release/phases/171-version-authority-split/171-01-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/171-version-authority-split/171-01-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/171-version-authority-split/171-02-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/171-version-authority-split/171-02-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/171-version-authority-split/171-03-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/171-version-authority-split/171-03-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/171-version-authority-split/171-04-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/171-version-authority-split/171-04-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/171-version-authority-split/171-05-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/171-version-authority-split/171-05-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/171-version-authority-split/171-WELD-INVENTORY.md
  - .planning/workstreams/quality-ratchet-release/phases/171-version-authority-split/171-CHECK-DISPOSITIONS.md
  - .planning/workstreams/quality-ratchet-release/phases/171-version-authority-split/171-PATTERNS.md
  - .planning/workstreams/quality-ratchet-release/phases/171-version-authority-split/171-RESEARCH.md
  - .planning/workstreams/quality-ratchet-release/phases/171-version-authority-split/171-VALIDATION.md
  - .planning/workstreams/quality-ratchet-release/phases/171-version-authority-split/COVERAGE.md
  - .github/workflows/release-please.yml
  - .github/workflows/hex-publish.yml
  - .github/workflows/ios-mirror-backfill.yml
  - script/check_release_workflow_integrity.exs
  - script/guarded_hex_publish.sh
  - script/release_candidate/android_publication.sh
  - script/release_candidate/ios_mirror.sh
  - script/verify_ios_mirror_backfill.sh
  - script/check_release_version_truth.exs
  - lib/crosswake/release_candidate/workflow.ex
  - lib/crosswake/release_candidate/cleanroom.ex
  - lib/crosswake/release_candidate.ex
  - lib/crosswake/release_candidate/identity.ex
  - lib/crosswake/release_candidate/mirror.ex
  - lib/crosswake/release_status.ex
  - lib/crosswake/release_candidate/coordinate.ex
  - lib/mix/tasks/crosswake.release.candidate.ex
  - test/crosswake/proof/phase171_no_bare_version_literal_test.exs
  - test/crosswake/proof/phase171_approved_version_output_test.exs
  - test/crosswake/release_candidate/workflow_test.exs
  - test/crosswake/release_candidate/cleanroom_test.exs
  - test/crosswake/release_candidate/identity_test.exs
covered_digest: "v1:sha256:658b78b5187beaab7228acd3fec96edb341e8479361549cbb99f2a942cd481fd"
behavior_unverified: 0
overrides_applied: 0
vacuity_taxonomy:
  - check_id: "release.publish_gate.no_bare_version_literal"
    shape: D
    non_vacuity_evidence: "Independently re-run by this verifier (not inherited from SUMMARY):
      `mix test test/crosswake/proof/phase171_no_bare_version_literal_test.exs
      test/crosswake/proof/phase171_approved_version_output_test.exs --exclude
      requires_example_host` -> 21 tests, 0 failures. The check emits OK against the real,
      fixed `release-please.yml`, and FAILs independently for each of the four version-gated
      jobs (`publish-hex`, `publish-ios-core`, `publish-android-core`, `exact-public-proof`)
      when a pre-repair fixture reintroduces a bare `outputs.version == '<semver>'` literal
      into that job's `if:` clause alone — a named, reproducible mutation, not an assertion
      that the check 'looks correct'. `elixir script/check_release_workflow_integrity.exs`
      exits 0 with the check present in the roster (69 of 69 checks emitted, 0 failed,
      confirmed by this verifier's own run, not copied from a SUMMARY)."
---

# Phase 171: Version/Authority Split Verification Report

**Phase Goal:** Any semver version can run the full publish -> proof -> rollup graph with no
workflow edit, while an unapproved merge still cannot publish at any version — and the check
that would have caught the original `0.2.1` weld lands in the same change that removes it.

**Verified:** 2026-09-17T18:22:33Z
**Status:** passed
**Re-verification:** No — initial verification (retroactive; phase merged as PR #178 /
commit `501e4410` before this report was written, per the two-executor-loss interruption
documented in 171-03-SUMMARY.md and 171-05-SUMMARY.md)

## Provenance note

This is a retroactive, goal-backward verification against the MERGED tree at `main` HEAD
`501e4410`. No production code was modified or re-executed to produce this report. All
"confirmed" statements below were re-run by this verifier directly against the checked-out
worktree; none are inherited from SUMMARY.md prose without independent re-execution.

## Goal Achievement

### Observable Truths

| # | Truth (ROADMAP success criterion) | Status | Evidence |
|---|---|---|---|
| 1 | `release.publish_gate.no_bare_version_literal` runs against a pre-repair fixture and fails, proving non-vacuity | VERIFIED | Re-ran `mix test test/crosswake/proof/phase171_no_bare_version_literal_test.exs test/crosswake/proof/phase171_approved_version_output_test.exs --exclude requires_example_host`: 21 tests, 0 failures. Test file constructs a pre-repair fixture per gated job (raise-if-no-op mutation guard) and asserts FAIL independently for each of `publish-hex`/`publish-ios-core`/`publish-android-core`/`exact-public-proof`. |
| 2 | `approved-release-guard`'s receipt carries an `approved_version` field alongside head/tree/base | VERIFIED | `grep -n "approved_version"` in `.github/workflows/release-please.yml` shows the job `outputs:` map declares `approved_version: ${{ steps.guard.outputs.approved_version }}` (line 46) and the guard step emits it via `emit_output "approved_version=$manifest_version"` (line 155), derived from `manifest_version=$(jq -er '."."' .release-please-manifest.json)` (line 74) cross-checked against `mix.exs` and the Android `build.gradle.kts`. |
| 3 | Zero bare `0.2.1` (or any literal) inside any publish-gating `if:` clause across the four gated jobs; each compares against `approved_version` | VERIFIED | Independently re-grepped: `grep -c "outputs.version == '" .github/workflows/release-please.yml` returns `0`. `grep -n "outputs.version =="` shows all four `if:` clauses (lines 228, 531, 577, 734) compare `needs.release-please.outputs.version == needs.approved-release-guard.outputs.approved_version`. |
| 4 | `Crosswake.ReleaseCandidate.Workflow`'s coordinate/dependency derivation is a function of an input version, not a frozen module attribute | VERIFIED | `grep -n "@coordinates"` in `workflow.ex` returns nothing; `rollup!/1` requires `:version` in its input map and calls a private `coordinates(version)` function. `mix test test/crosswake/release_candidate/workflow_test.exs` (part of the 744-test run below) asserts two different versions (`0.2.2`/`9.9.9`) yield two different `successful_coordinates` lists with identical pass/fail topology. |
| 5 | `cleanroom.ex:236`'s `== "0.2.1"` comparison is gone; the weld inventory (18 files) is committed with every "live gate" row resolved | VERIFIED | `grep -n '0\.2\.1' lib/crosswake/release_candidate/cleanroom.ex` returns nothing. `171-WELD-INVENTORY.md` exists (49 data rows across `lib/`, scripts, workflows) and its own closing count states 0 unresolved `live gate*` rows — independently spot-checked several rows against current source (see "Independent sweep" below) and found the classifications accurate, including one genuine miss (`release-please.yml:568,603` `--version 0.2.1` passed literally to the two publish `run:` blocks) that the inventory itself documents finding and fixing rather than omitting. |
| 6 | `release.version_weld.gates_match_declared_version` tripwire file/check is deleted (not disabled) in the same commit that lands the successor | VERIFIED | `grep -n "release.version_weld.gates_match_declared_version" script/check_release_workflow_integrity.exs` returns nothing; `test/crosswake/proof/phase168_release_version_weld_test.exs` does not exist in the tree; `test/crosswake/proof/phase171_no_bare_version_literal_test.exs` exists as its replacement, landed in the same phase/PR. |
| 7 | A rehearsed unapproved-merge attempt still cannot publish at any version — identity gate (head/tree/base) stays exact after the version comparison generalizes | VERIFIED | `test/crosswake/proof/phase171_approved_version_output_test.exs` asserts, as six separate named predicates, that `approved_head="$second_parent"`, the `merge_tree=$(git rev-parse` derivation, the tree-identity comparison, the receipt identity binding, and both CI-run cross-checks are all still present in the guard step, and confirms the same set of predicates is found regardless of which version the release manifest declares (version-independence). Re-run as part of the 21-test pass above. `guarded_hex_publish.sh`'s `verify_approved_identity()` independently re-read: the `$VERSION != "0.2.1"` half of the refusal is gone; a caller-supplied `--expected-version` is now required and fails closed (non-empty + exact match) before any of the pre-existing head/tree/merge-OID/receipt checks run. |

**Score:** 7/7 truths verified (0 present-but-behavior-unverified)

### Independent Sweep (ROADMAP success criterion #5, second half)

Re-run directly by this verifier, not copied from `171-05-SUMMARY.md`:

```
grep -rl '0\.2\.1' lib/ script/ .github/workflows/
  -> script/check_release_workflow_integrity.exs
  -> script/check_release_version_truth.exs
  -> script/collection_assertion_ledger.json
  -> .github/workflows/release-please.yml

grep -rn '0\.2\.1' lib/ script/ .github/workflows/ | wc -l
  -> 5
```

| Occurrence | Independently confirmed classification |
|---|---|
| `.github/workflows/release-please.yml:65` | Comment narrating the phase-168 merge; not inside any `if:`/`run:` gate |
| `script/check_release_workflow_integrity.exs:1210` | Comment documenting the 171-04 generalization (`recovery.ios.exact_identity_gate`); the check's actual needle no longer contains the literal |
| `script/check_release_workflow_integrity.exs:1293` | Comment documenting the `${VERSION}` interpolation (`release.partial.phase168_recovery_routes`); needle itself is parametric |
| `script/check_release_version_truth.exs:8` | Comment narrating the historical PR #158 incident; the script's own `@components` logic is unchanged and was never a weld |
| `script/collection_assertion_ledger.json:185` | `rationale`/`display` text describing a test name (`coordinate_test.exs`'s "accepts a fully self-consistent input at any well-formed semver, not just 0.2.1"); a generated ledger field, gates nothing |

This independently reproduces the claimed count exactly (4 files, 5 occurrences, all non-executable
comment/docstring/ledger text). No occurrence sits inside an `if:`, `run:` version comparison, or a
scanner needle that would still match the literal at runtime.

### Minor discrepancy found (non-blocking)

`171-04-SUMMARY.md` and `171-WELD-INVENTORY.md` both describe the `ios-mirror-backfill.yml`
`attest-candidate-receipt` negative controls as "six" occurrences ("git tag absence, Hex 404,
Maven POM 404 across both path segments, iOS mirror tag absence"). Re-counted directly against
the current file (lines 291-296 in the merged tree): there are **4 `test` assertion lines**
containing **5** `${CANDIDATE_VERSION}` interpolations (git tag=1, Hex 404=1, Maven POM 404=2 path
segments on one line, iOS mirror tag=1) — not six of either. This is an off-by-one miscount in the
SUMMARY/inventory prose, not a functional gap: all four assertions are confirmed parameterized on
`CANDIDATE_VERSION`, polarity is unchanged (all remain `test -z ...`/`test "$(...)" = 404` negative
checks, no `continue-on-error` in the job), and the path is genuinely satisfiable again for a fresh
candidate. Recorded here per the instruction to report gaps the plans/summaries did not already
catch, rather than silently inheriting the "six" figure.

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `.github/workflows/release-please.yml` | `approved_version` output + 4 version-parametric gates | VERIFIED | Confirmed above |
| `script/check_release_workflow_integrity.exs` | New check, tripwire deleted, roster coherent | VERIFIED | 69/69 roster checks emitted, 0 failed, `release.scanner.roster_exact` passes |
| `script/guarded_hex_publish.sh` | Fail-closed `--expected-version`, no `!= 0.2.1` early return | VERIFIED | Confirmed above |
| `.github/workflows/ios-mirror-backfill.yml` | `CANDIDATE_VERSION`-parameterized negative controls | VERIFIED (see discrepancy note) | Confirmed above |
| `171-WELD-INVENTORY.md` | 18-file, occurrence-level classification, 0 unresolved live gates | VERIFIED | 49 data rows; spot-checked; one late-caught miss (`release-please.yml:568,603`) documented and fixed within the same phase, not silently omitted |
| `lib/crosswake/release_candidate/workflow.ex` | Version-parametric `coordinates/1` | VERIFIED | `@coordinates` gone; `rollup!/1` requires `:version` |
| `lib/crosswake/release_candidate/cleanroom.ex` | `validate_approved_artifacts!/1` version conjunct removed | VERIFIED | `grep '0\.2\.1'` on file returns nothing |

### Requirements Coverage

| Requirement | Status | Evidence |
|---|---|---|
| MSG-04 | SATISFIED | `release.publish_gate.no_bare_version_literal` registered, merge-blocking via scanner-in-CI |
| MSG-05 | SATISFIED | Non-vacuity proof re-run, 21/21 tests pass |
| WELD-01 | SATISFIED | `171-WELD-INVENTORY.md` committed, 49 rows, 0 unresolved live gates |
| WELD-02 | SATISFIED | `approved_version` output confirmed |
| WELD-03 | SATISFIED | 4 gates confirmed parametric |
| WELD-04 | SATISFIED | `Workflow.coordinates/1` confirmed |
| WELD-05 | SATISFIED | `cleanroom.ex` conjunct confirmed deleted |
| WELD-06 | SATISFIED | Shell scripts + dispatch workflows confirmed generalized (spot-checked `guarded_hex_publish.sh`, `ios-mirror-backfill.yml`) |
| WELD-07 | SATISFIED | Tripwire + its test confirmed absent |
| WELD-08 | SATISFIED | Identity-predicate test confirmed present and passing |
| DOC-05 | SATISFIED (scope-limited) | New/changed prose in this phase's files uses "release manifest"; pre-existing unrelated "manifest" prose elsewhere in `release-please.yml` was out of this phase's stated scope (only new/changed text) |

All eleven requirement IDs are marked Complete in `REQUIREMENTS.md`; no orphaned requirement IDs
found mapped to Phase 171 beyond this list.

### Anti-Patterns Found

`grep`'d for `TBD|FIXME|XXX|TODO|HACK|PLACEHOLDER` across all files this phase modified
(`lib/`, `script/`, `.github/workflows/`, and the two new proof test files): zero debt markers.
The only `XXX` matches are `mktemp` placeholder templates (`crosswake-hex-release-XXXXXX.json`
etc. in `guarded_hex_publish.sh` and `ios_mirror.sh`) — a shell idiom for a random suffix, not a
debt marker. No blockers.

### Behavioral Spot-Checks / Probe Execution

| Check | Command | Result | Status |
|---|---|---|---|
| Scanner exits clean | `elixir script/check_release_workflow_integrity.exs` | `DONE: 69 of 69 roster checks emitted; 0 failed.` | PASS |
| New check's non-vacuity proof | `mix test test/crosswake/proof/phase171_no_bare_version_literal_test.exs test/crosswake/proof/phase171_approved_version_output_test.exs --exclude requires_example_host` | 21 tests, 0 failures | PASS |
| Full proof + release-candidate regression | `mix test test/crosswake/proof test/crosswake/release_candidate test/mix/tasks/crosswake_release_candidate_test.exs --exclude requires_example_host --max-cases 4` | 744 tests, 0 failures (67 excluded) | PASS |
| PR #178 merge state and CI | `gh pr view 178 --json state,mergedAt,statusCheckRollup` | `MERGED`, 2026-09-17T18:03:50Z, 0 non-success checks | PASS |

No probes (`scripts/*/tests/probe-*.sh`) apply to this phase — it is an Elixir/GitHub-Actions
scanner-and-workflow phase, not a migration/tooling-probe phase.

### Human Verification Required

None. Every ROADMAP success criterion resolved to a re-executed, measured VERIFIED with no
behavior-dependent truth left unexercised.

## Vacuity Taxonomy

Phase 171 landed exactly one new scanner check ID:
`release.publish_gate.no_bare_version_literal` (the successor to the deleted interim tripwire
`release.version_weld.gates_match_declared_version`, which is not itself a "new check" — it was
retired, not landed). No other new roster-registered check ID was introduced; 171-04's edits to
`recovery.ios.exact_identity_gate` and `release.partial.phase168_recovery_routes` updated
existing checks' self-referential needle text in lockstep with the fix, they did not add new
check IDs. The roster count is unchanged at 69 across the whole phase (one deletion, one
addition), independently confirmed by this verifier's own scanner run above.

| Check ID | Shape | Non-vacuity evidence (measured) |
|---|---|---|
| `release.publish_gate.no_bare_version_literal` | D | Re-run by this verifier: 21/21 tests pass in `phase171_no_bare_version_literal_test.exs` + `phase171_approved_version_output_test.exs`. The check is OK against the real, fixed workflow, and independently FAILs for each of the four version-gated jobs (`publish-hex`, `publish-ios-core`, `publish-android-core`, `exact-public-proof`) when a pre-repair fixture reintroduces a bare `outputs.version == '<semver>'` literal into that job's `if:` clause alone, with a raise-guard proving the mutation actually changed the text. `elixir script/check_release_workflow_integrity.exs` — 69/69, 0 failed, confirmed independently. This is the textbook Shape-D fix (TODO-009/PITFALLS.md's own worked example): a hardcoded `if: needs.X.outputs.version == '0.2.1'` that would silently never match for any future version is replaced by a dynamic `needs.X.outputs.approved_version` comparison, with a merge-blocking check that fails loudly if the literal reappears. |

This phase did **not** land zero new checks — the one entry above is complete and exhaustive,
confirmed against all five `171-0{1..5}-SUMMARY.md` files' `key-files`/`coverage` sections and
against the emitter source (`script/check_release_workflow_integrity.exs`'s `@roster_ids`).

## Gaps Summary

No gaps found. This phase's five plans (171-01 through 171-05), despite two mid-run executor
losses (171-03's `ENOTFOUND` API death after Task 1, and 171-05's stream-watchdog termination
after two of three commits), were both recovered by the orchestrator without reverting or
re-doing completed work, and both recoveries are transparently documented in their own SUMMARY.md
files rather than smoothed over. Independent re-verification of the merged tree at `main` HEAD
`501e4410` confirms every ROADMAP success criterion, all eleven requirement IDs, the committed
weld inventory's closing count (0 unresolved live gates), and the measured sweep (5 occurrences /
4 files, all non-executable). The only finding is the minor "six vs. five/four" counting
discrepancy in `171-04-SUMMARY.md`/`171-WELD-INVENTORY.md`'s prose (documented above), which does
not affect functional correctness and requires no code change — recorded so it does not
propagate uncorrected into a future phase's inherited assumptions.

---

_Verified: 2026-09-17T18:22:33Z_
_Verifier: Claude (gsd-verifier)_
