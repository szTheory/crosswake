---
phase: 173-recovery-path-proof-convergence
plan: 01
subsystem: release-candidate-proof
tags: [bash, jq, elixir, github-actions, workflow_call, hex-publish, publication-record]
status: complete

# Dependency graph
requires:
  - phase: 172-per-package-proof-scope
    provides: per-package proof scope with digest equality intact
provides:
  - "script/write_publication_record.sh — the single post-publish record emitter, called by both Hex lanes"
  - "script/assert_publication_record.sh — the record-presence decision over the full {package, version, approved_head} triple"
  - ".github/workflows/exact-public-proof.yml — the only copy of the exact-public proof body, entered via workflow_call"
  - "recovery-exact-public-proof in hex-publish.yml — the recovery lane reaching the same proof body by a character-identical uses: path"
  - "workflow_test.exs assertion requiring every caller of the reusable proof to grant actions: read at job level"
affects: [173-02, 173-03, 173-04]

# Actuals (#2632)
actuals:
  tokens: 13023
  tasks: 3
  commits: 3
plan_head_before: 2cc7d9431d3806cb4d3bf09fc55fe7e3b250f5b6

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Reusable-workflow extraction where the caller RETAINS its job-level `permissions:` block: a
      called workflow's `permissions:` can only narrow the caller's token, never widen it, so a
      permission the shared body needs must be granted by every caller."
    - "Two-tier applicability inside a shared proof body (approved-release-guard's shape): exactly one
      legitimate not-applicable branch writes a marker and exits zero; every other condition is a bare
      assertion under `set -euo pipefail`."
    - "Expected-value provenance rule: the triple a record is checked against comes from the verifying
      workflow's own trusted inputs, never from the artifact under verification (SEED-019)."
    - "Four result tokens, not three: `unreadable` is kept distinct from `missing` because the two call
      for different operator actions."

key-files:
  created:
    - script/write_publication_record.sh
    - script/assert_publication_record.sh
    - .github/workflows/exact-public-proof.yml
    - test/crosswake/release_candidate/publication_record_test.exs
  modified:
    - .github/workflows/release-please.yml
    - .github/workflows/hex-publish.yml
    - test/crosswake/release_candidate/workflow_test.exs

decisions:
  - "A fourth result token (PUBLICATION_RECORD_UNREADABLE) was added alongside the three the plan named. The plan requires that an unreadable record must not produce the missing token; with only three tokens that requirement is unsatisfiable."
  - "The checkout at the merge oid was reordered to sit immediately after the applicability step, before the record assertion, because the assertion is a repository script and cannot run before a checkout. It performs no proof work, so the record decision remains the proof's first substantive act."
  - "A new `candidate_receipt_run_id` workflow_dispatch input was added to hex-publish.yml. The recovery lane had no way to name the trusted run that uploaded the approved candidate receipt, and the shared proof body requires it; the reusable workflow hard-fails when it is empty for an applicable call."

metrics:
  duration: ~75 min
  completed: 2026-09-17
---

# Phase 173 Plan 01: Recovery-Path Proof Convergence (tracer) Summary

One publication-record signal now runs end to end on a single path: one emitter script called
identically by both Hex lanes, one assertion script that compares the whole
`{package, version, approved_head}` triple, one reusable workflow holding the only copy of the
exact-public proof body, and both lanes reaching it through a character-identical `uses:` path —
with the assertion's refusal proven by mutation rather than asserted.

## Commits

| Task | Commit | What |
|---|---|---|
| 1 | `9293f6f2` | `script/write_publication_record.sh`, `script/assert_publication_record.sh`, `test/crosswake/release_candidate/publication_record_test.exs` |
| 2 | `b4e46338` | `.github/workflows/exact-public-proof.yml`; `exact-public-proof` becomes a call; moved assertions re-pointed |
| 3 | `64fe2b7e` | both lanes emit the record; `recovery-exact-public-proof` added; native recovery left untouched |

## Measured counts (the numbers the plan demands, measured not estimated)

### Clean-room proof-body invocation (`--source-mode exact-public`)

| File | Before (`2cc7d943`) | After |
|---|---|---|
| `.github/workflows/release-please.yml` | 1 | **0** |
| `.github/workflows/hex-publish.yml` | 0 | **0** |
| `.github/workflows/exact-public-proof.yml` | — (did not exist) | **1** |
| **Across the two lane files** (Task 3 acceptance) | 1 | **0** |
| **Across the tree** (Task 2 acceptance) | 1 | **1** |

Exactly one copy of the proof body exists, and neither lane workflow carries it. Measured with
`grep -c -- '--source-mode exact-public'` per file.

### Assertions over the candidate-receipt download (Task 2d)

| | Count |
|---|---|
| **Before** — assertions reading the candidate-receipt download out of the `exact-public-proof` job block | **2** |
| **After** — assertions over the same subject in its new location plus caller companions | **7** |

Before (both on the `exact_public` job block): `=~ "candidate_receipt_run_id"` and
`=~ "phase168-candidate-receipt-${{ needs.approved-release-guard.outputs.approved_head }}"`.

After — none deleted, each re-pointed and each given a companion covering the caller's input:

1. `proof_workflow =~ gh run download "$RUN_ID" --name "phase168-candidate-receipt-${{ inputs.approved_head }}"`
2. `proof_workflow =~ "RUN_ID: ${{ inputs.candidate_receipt_run_id }}"`
3. `proof_workflow =~ "artifacts.json"`
4. `exact_public =~ "candidate_receipt_run_id"`
5. `exact_public =~ "candidate_receipt_run_id: ${{ needs.approved-release-guard.outputs.candidate_receipt_run_id }}"`
6. `exact_public =~ "approved_head: ${{ needs.approved-release-guard.outputs.approved_head }}"`
7. `refute exact_public =~ "phase168-candidate-receipt-"` (the subject really did move, it was not duplicated)

The count over this subject rose from 2 to 7. It did not fall.

### Emitter invocations

`grep -v '^[[:space:]]*#' .github/workflows/hex-publish.yml | grep -c 'script/write_publication_record.sh'` → **1**
(the Task 3 `<verify>` requirement). The same measurement on `release-please.yml` → **1**.

## Why the caller `permissions:` block is asserted rather than linted

`release-please.yml` and `hex-publish.yml` both declare a top-level `permissions:` key, so every
scope they do not list — `actions` among them — is `none` at workflow level. `actions: read` exists
only as job-level grants. A called workflow's own `permissions:` can only **narrow** the token the
caller hands it, never widen it, so declaring `actions: read` inside `exact-public-proof.yml` does
not grant it to either caller. Dropping a caller's block produces a **runtime 403** on the artifact
reads inside the shared body — at release time, on a real release.

This is a runtime-authorization property, not a syntax property: `actionlint` cannot decide it.
Measured directly — with the caller's `permissions:` block removed, `actionlint` still exited **0**
while `workflow_test.exs` failed with
`.github/workflows/release-please.yml job exact-public-proof declares no job-level permissions block`.
That is why the property is asserted in the test suite rather than delegated to the linter
(T-173-15).

## Non-vacuity — four recorded mutations

Every mutation was applied locally, observed, and reverted. Post-revert state re-verified green each
time.

**Mutation 1 — assertion script compares only the package field** (plan-required).
Both single-field comparisons neutered to `if false`. Observed:

```
17 tests, 4 failures
  1) test assert_publication_record.sh reports mismatch when only the version differs
     Assertion with != failed, both sides are exactly equal
     code: assert code != 0
     left: 0
  2) test assert_publication_record.sh reports mismatch when only the approved head differs
     Assertion with != failed, both sides are exactly equal
```
(plus the distinct-exit-code test and the emitter round-trip mismatch test). Reverted → 17/0.

**Mutation 2 — missing-record branch exits zero** (plan-required). `exit 4` → `exit 0`. Observed:

```
17 tests, 2 failures
  1) test assert_publication_record.sh reports record-missing when no record file exists at all
     Assertion with != failed, both sides are exactly equal
     code: assert code != 0
     left: 0
```
Reverted → 17/0.

**Mutation 3 — caller's `permissions:` block dropped.** `actionlint` exit **0**;
`workflow_test.exs` failed with
`.github/workflows/release-please.yml job exact-public-proof declares no job-level permissions block`.
Reverted → green.

**Mutation 4 — emitter flag order swapped in the recovery lane** (`--lane` before `--ref`).
`actionlint` exit **0**; `workflow_test.exs` failed on the flag-order assertion in
`both publish lanes emit one publication record through the one shared emitter`. Reverted → green.

### A vacuity defect found in this plan's own new check

The first draft of the caller-permission assertion matched the **YAML comment prose** beside the
caller job — the comment explaining why the block is load-bearing itself contains the strings
`permissions:` and `actions: read`. Mutation 3 exposed it: with the real block deleted, the first
two assertions still passed and only `contents: read` (a string absent from the comment) failed.
Fixed by stripping full-line comments before asserting, mirroring
`check_release_workflow_integrity.exs`'s own `strip_full_line_comments/1`, then re-running
mutation 3 — which now fails at the first assertion, naming the missing block. This is recorded
rather than quietly fixed: the check nearly shipped as a passing assertion about a comment.

## TDD (Task 1)

RED first, against absent scripts: `17 tests, 17 failures`, every failure
`bash: script/write_publication_record.sh: No such file or directory` — an intentional RED, failing
for the stated reason (the behavior does not exist), not for a setup error. GREEN after the two
scripts landed: `17 tests, 0 failures`. No production code was written before the failing test.

## Tracer gate (Task 1, `type="tracer"`)

Auto mode active → the Task 1 `<verify>` block was re-run end to end after the mutations were
reverted and before any expansion task began. `mix test .../publication_record_test.exs` → 17/0;
`shellcheck` on both scripts → exit 0. Verified end-to-end, then expanded.

## Deviations from Plan

### [Rule 2 — missing critical functionality] A fourth result token

The plan names three result tokens *and* requires that an unreadable or key-missing record must not
produce the missing token ("'we could not read it' and 'it was not there' must not produce the same
result token"). Those two requirements cannot both hold with three tokens. Added
`PUBLICATION_RECORD_UNREADABLE` (exit 6) alongside `VERIFIED` (0), `MISSING` (4) and `MISMATCH` (5).
The plan's acceptance criterion — "three distinct result tokens across the verified, missing and
mismatch outcomes" — still holds exactly. Covered by two tests (bad JSON, and each of the eight
required keys removed in turn) plus a distinct-exit-code test.

### [Rule 3 — blocking issue] Checkout reordered ahead of the record assertion

`script/assert_publication_record.sh` is a repository file, so it cannot run before a checkout. The
`actions/checkout` at the merge oid was moved to sit immediately after the applicability step and
before the record download/assertion, rather than staying where it sat in the old job body. It runs
no proof step, so the record decision is still the proof's first substantive act — asserted in the
test suite by `:binary.match` ordering: `bash script/assert_publication_record.sh` precedes
`--source-mode exact-public` in the file.

### [Rule 3 — blocking issue] New `candidate_receipt_run_id` dispatch input

`hex-publish.yml` exposed no way to name the trusted run that uploaded the approved candidate
receipt, which the shared proof body needs. Added as an optional `workflow_dispatch` string input
and mapped onto the caller's `with:`. It is not silently optional at runtime: the reusable
workflow's applicability step asserts `[ -n "$CANDIDATE_RECEIPT_RUN_ID" ]` for any applicable call,
so an operator who omits it gets a hard failure, never a skipped proof.

### Step-level `if:` on the record-assertion step — stated explicitly

The record-assertion step carries `if: ${{ steps.applicability.outputs.applicable == 'true' }}`. The
plan's acceptance criterion is that *the job* carries no condition that can prevent it — the job's
own `if:` is `always()`, and the applicability step that produces the marker itself carries no
condition and always runs. The marker is `false` only for the one legitimate case the plan sanctions
(a call carrying neither an approved head nor a merge oid, i.e. not a linked release at all); every
other condition in that step is a bare assertion that fails the job. Both callers' own `if:` clauses
already establish applicability, so in both real lanes the record assertion runs and hard-fails on a
missing record. Flagged here so a reviewer judges the shape deliberately rather than discovering it.

## Threat mitigations applied

| Threat | Where |
|---|---|
| T-173-01 (replayed/forged record) | The assertion's expected triple comes from the calling workflow's own inputs; asserted by `proof_workflow =~ "PACKAGE: ${{ inputs.package }}"` et al. |
| T-173-02 (secret inheritance) | `exact-public-proof.yml` declares no `secrets:` key; asserted by `refute proof_workflow =~ ~r/^\s*secrets:/m` and `refute block =~ "secrets: inherit"` per caller. |
| T-173-03 (two drifting proof copies) | Measured: zero `--source-mode exact-public` occurrences across both lane files; both callers' `uses:` lines proven character-identical. |
| T-173-04 (failure silently downgraded) | No `\|\| true`, no default-on-error branch in the assertion script; proven by mutation 2. |
| T-173-05 (silently widening to native) | `recover-android-core` verified **byte-identical** (3270 bytes, both sides) to its pre-plan state; a test asserts it references neither the shared proof nor the emitter. |
| T-173-15 (caller drops `actions: read`) | Both callers declare the block; asserted for *every* caller found by scanning `.github/workflows/*.yml`, with a non-empty-collection guard so zero callers cannot pass vacuously. Proven by mutation 3. |
| T-173-SC (package installs) | Not applicable — this plan adds no package-manager install step. |

## Untouched by design

- `recover-android-core` — byte-identical (verified by block extraction and byte comparison).
- `approved-release-guard` — byte-identical to the phase base `2cc7d943`.
- `linked-release-rollup` / `native-release-rollup` — byte-identical; the rollup still lists
  `exact-public-proof` in `needs:` and still reads `.result`.
- The `phase168-candidate-receipt-*` schema and every `jq` assertion in `approved-release-guard` —
  unchanged. The publication record is a separate artifact under its own
  `publication-record-<package>-<approved_head>` name prefix.
- Every action SHA pin — carried across verbatim; this was a move, not an upgrade.

## Verification

| Check | Result |
|---|---|
| `actionlint` over all three workflow files | exit 0 |
| `elixir script/check_release_workflow_integrity.exs` | exit 0 — `DONE: 69 of 69 roster checks emitted; 0 failed.` |
| `mix test test/crosswake/release_candidate --max-cases 1` | 103 tests, 0 failures |
| `mix test` phase171 + phase142 + phase172 proof suites | 81 tests, 0 failures |
| `shellcheck` on both new scripts | exit 0, no findings |
| `bash -n` on both new scripts | exit 0 |
| `mix format --check-formatted` | exit 0 |
| `grep -c script/write_publication_record.sh` (hex-publish.yml, comments stripped) | 1 |

## Known Stubs

None. No stub, skipped test, or unrun `<verify>` was left behind by this plan; every `<verify>`
block in the plan was run as written and its actual output is recorded above.

## Threat Flags

None. No file changed by this plan introduces network, auth, file-access or schema surface outside
the plan's `<threat_model>`.

## Not done here (by the plan's own constraints)

No pull request was opened. Phase 173 lands as ONE PR opened at the end of plan 173-04, and the
fire-drill observation in 173-04 is taken against this branch. A proof job that hard-fails on a
missing publication record must not reach `main` ahead of the emitter that writes that record.

## Self-Check: PASSED

All four created files exist on disk; all three commit hashes (`9293f6f2`, `b4e46338`, `64fe2b7e`)
resolve in `git log`.
