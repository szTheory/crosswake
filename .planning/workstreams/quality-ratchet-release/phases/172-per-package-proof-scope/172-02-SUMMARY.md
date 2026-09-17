---
phase: 172-per-package-proof-scope
plan: 02
subsystem: release-candidate-proof
tags: [elixir, cleanroom, proof-scope, candidate_ref, graded-claim]

# Dependency graph
requires:
  - phase: 172-per-package-proof-scope
    provides: "172-01's per-package candidate_ref threaded end-to-end (Artifact producer, both
      shell transports, Cleanroom approved/public schemas) with the observed ref resolved
      independently from git rev-parse HEAD"
provides:
  - "public_artifact_reason/3 grades drift honestly: reachable_and_compatible (drift, bytes
    match) and unproven (drift, bytes differ) as two new named branches, ordered so a real
    defect always outranks a drift diagnosis, with the pre-existing digest_mismatch comparison
    left textually unchanged (only a ref-equality conjunct added)"
  - "evaluate_public!/1 gains a fourth disjoint bucket (attested) and an ATTESTED state, ordered
    after blocked/missing/live-status and before the fully-proven fallthrough"
  - "public_artifact_claim/1 maps every known reason string to a positively-named claim
    (fully_proven / reachable_and_compatible / unproven) via an explicit case with a catch-all"
  - "Result document gains attested_packages and package_claims (six entries, canonical order)
    without redefining any existing key's meaning"
  - "The exact-public terminal gate (verify_companion_cleanroom.sh's completion-string
    comparison) is proven byte-identical and semantically un-weakened by an attested run"
affects: [172-03-non-vacuity-proof-test]

# Actuals (#2632)
actuals:
  tokens: 5522
  tasks: 3
  commits: 4
  plan_head_before: bd14220a

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Guard-scoped drift resolution: ref!/1 is called only inside cond guards positioned after
      every harder pre-drift predicate, so a malformed observed ref only ever raises for an
      otherwise-healthy package and never masks a status/source/path-lock/source-root failure"
    - "Branch ordering as the correctness mechanism in a cond-based classifier: placing
      digest_mismatch (guarded by an added ref-equality conjunct) between the two new drift
      branches is what makes each mutation test falsify the RIGHT clause, not just any clause"
    - "Case-with-catch-all claim vocabulary: public_artifact_claim/1 enumerates every known
      reason string explicitly so a future reason added to public_artifact_reason/3 without a
      matching claim clause still resolves safely (falls to unproven) rather than crashing"

key-files:
  created: []
  modified:
    - lib/crosswake/release_candidate/cleanroom.ex
    - test/crosswake/release_candidate/cleanroom_test.exs
    - test/crosswake/proof/phase170_vacuous_assertion_ledger_test.exs
    - script/collection_assertion_ledger.json

key-decisions:
  - "Branch order in public_artifact_reason/3 is: reachable_and_compatible, then
    digest_mismatch (with the added ref-equality conjunct), then unproven, then the untouched
    nil fallthrough. This ordering — not just 'add two branches before the fallthrough' — is
    what makes mutation 2 (deleting the ref-equality conjunct) reroute the drift+digest-change
    case into digest_mismatch instead of unproven, exactly as the plan's acceptance criteria
    require. Placing unproven before digest_mismatch would make mutation 2 a no-op."
  - "ref!/1 is called from within the drift branches' own guards, not resolved once via a
    pre-cond let-binding — cond guards short-circuit, so a shared resolution point would have to
    sit before the registry-missing/status/source/path-lock/source-root clauses, which would
    raise ArgumentError for a registry-missing package's nil observed ref before that package's
    real classification (registry_missing) ever gets a chance to fire."
  - "public_artifact_claim/1 is a case over every known reason string (not just a two-clause
    function-head match on nil/reachable_and_compatible) per the plan's explicit instruction, so
    a reason string added later without a matching case clause still resolves to the catch-all
    unproven claim rather than crashing."
  - "failed_packages is unchanged: it still includes reachable_and_compatible-reason packages
    (any non-nil reason), since the plan forbids redefining existing result keys. The new
    attested_packages/package_claims keys are the mechanism for surfacing the distinction, not a
    change to failed_packages' existing semantics."

requirements-completed: [XPUB-01, XPUB-02, XPUB-03]

coverage:
  - id: D1
    description: "A package whose observed ref drifts past its approved ref while digests still
      match byte-for-byte reports reachable_and_compatible, never a fully-proven nil result"
    requirement: "XPUB-03"
    verification:
      - kind: unit
        ref: "test/crosswake/release_candidate/cleanroom_test.exs#a package whose observed ref drifts but keeps matching bytes reports reachable_and_compatible"
        status: pass
    human_judgment: false
  - id: D2
    description: "A package whose observed ref drifts AND whose digests differ reports unproven,
      not the digest-mismatch diagnostic"
    requirement: "XPUB-03"
    verification:
      - kind: unit
        ref: "test/crosswake/release_candidate/cleanroom_test.exs#a package whose observed ref drifts AND whose digests differ reports unproven, not digest_mismatch"
        status: pass
    human_judgment: false
  - id: D3
    description: "Byte-exact digest equality is unchanged in strength for a non-drifted package
      (SC#3 regression anchor), proven separately for the metadata_digest and payload_digest
      halves of the OR-clause"
    requirement: "XPUB-02"
    verification:
      - kind: unit
        ref: "test/crosswake/release_candidate/cleanroom_test.exs#SC#3 regression anchor: a payload_digest change with no ref drift still reports digest_mismatch"
        status: pass
      - kind: unit
        ref: "test/crosswake/release_candidate/cleanroom_test.exs#SC#3 regression anchor: a metadata_digest change with no ref drift still reports digest_mismatch"
        status: pass
      - kind: other
        ref: "git diff bd14220a..HEAD -- lib/crosswake/release_candidate/cleanroom.ex shows the two digest-comparison lines appear only as unedited context/move, never as an edit"
        status: pass
    human_judgment: false
  - id: D4
    description: "Drift is never allowed to mask a harder pre-drift failure (bad status,
      non-registry source, path lock, bad source root, registry-missing)"
    requirement: "XPUB-03"
    verification:
      - kind: unit
        ref: "test/crosswake/release_candidate/cleanroom_test.exs#drift never masks a harder pre-drift failure"
        status: pass
      - kind: unit
        ref: "test/crosswake/release_candidate/cleanroom_test.exs#a registry-missing package still reports registry_missing even with a drifted approved ref"
        status: pass
    human_judgment: false
  - id: D5
    description: "A malformed observed candidate_ref on an otherwise-healthy package raises
      ArgumentError"
    requirement: null
    verification:
      - kind: unit
        ref: "test/crosswake/release_candidate/cleanroom_test.exs#a malformed observed candidate_ref on an otherwise-healthy package raises ArgumentError"
        status: pass
    human_judgment: false
  - id: D6
    description: "The six package outcomes are never averaged into one verdict: a fourth
      disjoint aggregate bucket (attested) exists, a real defect or missing package always
      outranks an attestation, and succeeded_packages/package_count keep meaning
      fully-proven-only"
    requirement: "XPUB-03"
    verification:
      - kind: unit
        ref: "test/crosswake/release_candidate/cleanroom_test.exs#one attested package with five fully-proven packages reports ATTESTED, not COMPLETE"
        status: pass
      - kind: unit
        ref: "test/crosswake/release_candidate/cleanroom_test.exs#a blocked package outranks an attested package - the run still reports BLOCKED"
        status: pass
      - kind: unit
        ref: "test/crosswake/release_candidate/cleanroom_test.exs#a registry-missing package still reports PARTIAL even alongside an attested package"
        status: pass
      - kind: unit
        ref: "test/crosswake/release_candidate/cleanroom_test.exs#the four public-artifact buckets are disjoint and sum to six"
        status: pass
    human_judgment: false
  - id: D7
    description: "package_claims carries exactly six entries per run in canonical order, agrees
    with succeeded_packages on which packages are fully proven, and every entry has a
    non-empty claim string"
    requirement: "XPUB-03"
    verification:
      - kind: unit
        ref: "test/crosswake/release_candidate/cleanroom_test.exs#package_claims and succeeded_packages agree on which packages are fully proven"
        status: pass
      - kind: unit
        ref: "test/crosswake/release_candidate/cleanroom_test.exs#package_claims always carries exactly six non-empty claims in canonical order"
        status: pass
    human_judgment: false
  - id: D8
    description: "The exact-public lane's terminal gate (verify_companion_cleanroom.sh's
      completion-string comparison) is proven unweakened at both the shell-text and
      evaluator-semantic layer"
    requirement: "XPUB-03"
    verification:
      - kind: unit
        ref: "test/crosswake/release_candidate/cleanroom_test.exs#the exact-public terminal gate still requires the completion state, not the attested state"
        status: pass
      - kind: unit
        ref: "test/crosswake/release_candidate/cleanroom_test.exs#an attested run's state is never the completion string (semantic anchor for the terminal gate)"
        status: pass
      - kind: other
        ref: "git diff bd14220a..HEAD -- script/verify_companion_cleanroom.sh shows zero changed lines around the terminal state comparison"
        status: pass
    human_judgment: false

# Metrics
duration: 70min
completed: 2026-09-17
status: complete
---

# Phase 172 Plan 02: Per-Package Proof Scope — Graded-Claim Classifier Summary

**Split `public_artifact_reason/3`'s digest-mismatch clause on a ref-equality conjunct and added two ordered drift branches (`reachable_and_compatible`, `unproven`) plus a fourth `ATTESTED` aggregate bucket with positively-named per-package claims, all without weakening the terminal gate or the byte-exact digest comparison.**

## Performance

- **Duration:** 70 min
- **Started:** 2026-09-17T19:25:00Z (approx, first Read)
- **Completed:** 2026-09-17T20:35:00Z
- **Tasks:** 3 completed
- **Files modified:** 3 plan-scoped files + 2 files for a bundled Rule 3 deviation (governance ledger regeneration)

## Accomplishments

- `public_artifact_reason/3` now grades a drifted-ref package honestly instead of folding it
  into the byte-exact fallthrough: drift with matching bytes reports `"reachable_and_compatible"`,
  drift with differing bytes reports `"unproven"`. The observed ref is resolved via `ref!/1`
  only inside the drift branches' own guards — placed after every harder pre-drift predicate
  (registry-missing, status, source, path-lock, source-root) — so a drifted ref never masks a
  real defect and a malformed ref only raises for an otherwise-healthy package.
- The pre-existing digest-mismatch clause survives with both comparisons textually unchanged;
  the only edit is an added `ref!(artifact.candidate_ref) == expected.candidate_ref` conjunct.
  Confirmed by `git diff bd14220a..HEAD` showing the two comparison lines as unedited
  context/move.
- Branch order is load-bearing, not incidental: `reachable_and_compatible`, then
  `digest_mismatch` (now guarded), then `unproven`, then the untouched `nil` fallthrough. This
  specific order is what makes each of the three Task 1 mutations falsify the exact test the
  plan pairs it with (see Mutation Proofs below) — reordering `digest_mismatch` after `unproven`
  would have made mutation 2 a no-op.
- `evaluate_public!/1` gained a fourth disjoint bucket (`attested`), narrowed out of `blocked` so
  an attested package is never double-counted or forced to `"BLOCKED"`. Its state clause
  (`"ATTESTED"`) sits after blocked/missing/live-status and before the fully-proven fallthrough,
  so a real defect, a missing package, or a failing live status always outranks an attestation.
- A new `public_artifact_claim/1` maps every known reason string to a positively-named claim
  (`fully_proven` / `reachable_and_compatible` / `unproven`) via an explicit `case` with a
  catch-all, so a reason added later without a matching clause still resolves safely.
- Result document gained `attested_packages` (canonical-order package names) and
  `package_claims` (six entries, canonical order, package + claim) without redefining
  `succeeded_packages`, `package_count`, or `failed_packages`.
- The exact-public lane's terminal gate (`verify_companion_cleanroom.sh`'s
  `[ "$(jq -r '.state' "$MATRIX_RESULT")" = "COMPLETE" ] || matrix_fail`) is confirmed
  byte-identical since the phase's base commit, and a new evaluator-level test pins that an
  attested run's `state` is never `"COMPLETE"` — proven falsifiable by a recorded mutation.

## Task Commits

Each task was committed atomically:

1. **Task 1: Graded claim in the classifier — drift is named, byte-exactness is not weakened** - `bfc2ea23` (feat)
2. **Task 2: Third aggregate bucket and positively-named per-package claims** - `3371b297` (feat)
3. **Task 3: Prove the lane's terminal gate did not weaken** - `db182d30` (test)

**Deviation fix:** `ca912cc0` (fix — bundled Rule 3, see Deviations)

**Plan metadata:** commit pending (this SUMMARY + STATE/ROADMAP/REQUIREMENTS update)

## Files Created/Modified

- `lib/crosswake/release_candidate/cleanroom.ex` — graded drift branches in
  `public_artifact_reason/3`, new `public_artifact_claim/1`, `attested`/`ATTESTED` bucket in
  `evaluate_public!/1`, `attested_packages`/`package_claims` result keys
- `test/crosswake/release_candidate/cleanroom_test.exs` — 12 new tests covering drift grading,
  the SC#3 regression anchor (both digest halves), drift-never-masks-a-harder-failure, the
  malformed-ref raise, the attested bucket/state, bucket disjointness, claim/succeeded
  cross-consistency, and the terminal-gate text/semantic pins
- `test/crosswake/proof/phase170_vacuous_assertion_ledger_test.exs` — pinned literals updated
  for two new legitimate collection-assertion sites (deviation, see below)
- `script/collection_assertion_ledger.json` — regenerated snapshot adding the same two rows

## Decisions Made

- Branch order `reachable_and_compatible` → `digest_mismatch` (guarded) → `unproven` → `nil`,
  chosen specifically because it makes the plan's three prescribed mutations falsify exactly the
  test each is paired with (see Mutation Proofs).
- `ref!/1` called from within each drift branch's own guard rather than bound once before the
  `cond` — a shared pre-`cond` binding would raise on a registry-missing package's nil observed
  ref before that package's own classification gets a chance to fire.
- `public_artifact_claim/1` written as an explicit `case` over every known reason string (not a
  two-clause function-head match), per the plan's instruction that a future reason string must
  not slip through unnamed.
- `failed_packages` left semantically unchanged (still includes `reachable_and_compatible`-reason
  packages) since the plan forbids redefining existing result keys; `attested_packages` and
  `package_claims` are the new surfaces for the positive distinction.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Regenerated the Phase 170 collection-assertion ledger and its pinned literals**
- **Found during:** post-task full-suite verification (`mix test --exclude requires_example_host`)
- **Issue:** The two new cardinality-pinned assertions added in Task 2's tests
  (`assert Enum.map(result.package_claims, & &1.package) == @packages` and
  `assert length(result.package_claims) == 6`) are genuinely new collection-assertion sites the
  Phase 170 governance ledger (`script/collection_assertion_ledger.json`) did not yet know about.
  `test/crosswake/proof/phase170_vacuous_assertion_ledger_test.exs` failed with an unclassified-row
  mismatch and three literal-count mismatches (`@audited_site_count`, `@shape_counts["assert_all"]`,
  `@bucket_counts["safe-cardinality-pinned"]`) — a direct, mechanical consequence of this plan's
  own test additions, not a pre-existing or out-of-scope failure.
- **Fix:** Ran `elixir script/inventory_collection_assertions.exs --emit-snapshot`, diffed against
  the committed ledger (confirmed only two new rows added, no existing row's `key` or `bucket`
  changed), copied the regenerated snapshot over `script/collection_assertion_ledger.json`, and
  updated the three pinned literals: `@audited_site_count` 224→226, `@shape_counts["assert_all"]`
  43→45, `@bucket_counts["safe-cardinality-pinned"]` 27→29.
- **Files modified:** `script/collection_assertion_ledger.json`,
  `test/crosswake/proof/phase170_vacuous_assertion_ledger_test.exs`
- **Verification:** `mix test test/crosswake/proof/phase170_vacuous_assertion_ledger_test.exs
  --max-cases 1` — 19 tests, 0 failures (was 4 failures before the fix). Full project suite
  `mix test --exclude requires_example_host` — 1846 tests, 0 failures.
- **Committed in:** `ca912cc0`

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Necessary to keep an unrelated governance test green; no scope creep — the
ledger addition reflects exactly the two new pinned assertions this plan's own tests introduced,
nothing else.

## Mutation Proofs (non-vacuity, per VERIFICATION-CONVENTIONS.md)

All five recorded mutations were run against the working tree, observed red against the test
each is paired with, and reverted (confirmed via `git diff --stat` showing zero residual change
before each commit).

### Task 1 mutations

**Mutation 1 — swap the two drift branches' order.** Swapped `reachable_and_compatible` and
`unproven` (keeping `digest_mismatch` between them in absolute position). Observed failure:

```
1) test a package whose observed ref drifts but keeps matching bytes reports reachable_and_compatible (Crosswake.ReleaseCandidate.CleanroomTest)
   test/crosswake/release_candidate/cleanroom_test.exs:215
   Assertion with == failed
   code:  assert result.failed_packages == [%{package: "crosswake_sigra", reason: "reachable_and_compatible"}]
   left:  [%{reason: "unproven", package: "crosswake_sigra"}]
   right: [%{reason: "reachable_and_compatible", package: "crosswake_sigra"}]
17 tests, 1 failure (6 excluded)
```
Reverted; suite green again (17 tests, 0 failures).

**Mutation 2 — delete the ref-equality conjunct from the digest clause.** Changed
`ref!(artifact.candidate_ref) == expected.candidate_ref and (artifact.metadata_digest != ... or
artifact.payload_digest != ...)` back to the plain OR-clause. Observed failure:

```
1) test a package whose observed ref drifts AND whose digests differ reports unproven, not digest_mismatch (Crosswake.ReleaseCandidate.CleanroomTest)
   test/crosswake/release_candidate/cleanroom_test.exs:236
   Assertion with == failed
   code:  assert result.failed_packages == [%{package: "crosswake_sigra", reason: "unproven"}]
   left:  [%{reason: "digest_mismatch", package: "crosswake_sigra"}]
   right: [%{reason: "unproven", package: "crosswake_sigra"}]
17 tests, 1 failure (6 excluded)
```
The SC#3 no-drift regression tests stayed green under this mutation, exactly as the plan
predicts (an always-true conjunct's removal cannot flip a no-drift case). Reverted; suite green
again.

**Mutation 3 — replace the payload-digest `!=` comparison with an always-false expression.**
Changed `artifact.payload_digest != expected.payload_digest` to `false` inside the guarded
digest clause. Observed failure (SC#3 regression anchor goes red, as required; reverted
immediately since this mutation touches the comparison Task 1b otherwise forbids editing):

```
1) test SC#3 regression anchor: a payload_digest change with no ref drift still reports digest_mismatch (Crosswake.ReleaseCandidate.CleanroomTest)
   test/crosswake/release_candidate/cleanroom_test.exs:256
   Assertion with == failed
   code:  assert result.failed_packages == [%{package: "crosswake_sigra", reason: "digest_mismatch"}]
   left:  []
   right: [%{reason: "digest_mismatch", package: "crosswake_sigra"}]

2) test exact-public proof blocks path, cache, digest, lock-source, and live-status ambiguity (Crosswake.ReleaseCandidate.CleanroomTest)
   test/crosswake/release_candidate/cleanroom_test.exs:190
   digest_mismatch passed
17 tests, 2 failures (6 excluded)
```
Reverted; `mix compile --warnings-as-errors` and `mix test test/crosswake/release_candidate/cleanroom_test.exs --max-cases 1` (23 tests, 0 failures) confirmed the clean revert.

### Task 2 mutation

**Widen the narrowed blocked filter back to catch `reachable_and_compatible`.** Reverted the
`blocked` filter's third exclusion, restoring `&(&1.reason not in [nil, "registry_missing"])`.
Observed failure:

```
1) test one attested package with five fully-proven packages reports ATTESTED, not COMPLETE (Crosswake.ReleaseCandidate.CleanroomTest)
   test/crosswake/release_candidate/cleanroom_test.exs:163
   Assertion with == failed
   code:  assert result.state == "ATTESTED"
   left:  "BLOCKED"
   right: "ATTESTED"

2) test a registry-missing package still reports PARTIAL even alongside an attested package (Crosswake.ReleaseCandidate.CleanroomTest)
   test/crosswake/release_candidate/cleanroom_test.exs:207
   ** (ArgumentError) candidate clean-room input is invalid
     (crosswake 0.2.1) lib/crosswake/release_candidate/cleanroom.ex:489: Crosswake.ReleaseCandidate.Cleanroom.invalid!/0
     (crosswake 0.2.1) lib/crosswake/release_candidate/cleanroom.ex:364: Crosswake.ReleaseCandidate.Cleanroom.validate_complete_public_proof/3
23 tests, 2 failures (6 excluded)
```
Reverted; suite green again (29 tests, 0 failures).

### Task 3 mutation

**Change the attested state clause to produce `"COMPLETE"` locally.** Replaced
`{"ATTESTED", validate_complete_public_proof(...)}` with `{"COMPLETE", validate_complete_public_proof(...)}`
in the `attested != []` branch. Observed failure (the 3c semantic anchor goes red exactly as
required):

```
1) test one attested package with five fully-proven packages reports ATTESTED, not COMPLETE (Crosswake.ReleaseCandidate.CleanroomTest)
   test/crosswake/release_candidate/cleanroom_test.exs:163
   Assertion with == failed
   code:  assert result.state == "ATTESTED"
   left:  "COMPLETE"
   right: "ATTESTED"

2) test an attested run's state is never the completion string (semantic anchor for the terminal gate) (Crosswake.ReleaseCandidate.CleanroomTest)
   test/crosswake/release_candidate/cleanroom_test.exs:666
   Assertion with == failed
   code:  assert result.state == "ATTESTED"
   left:  "COMPLETE"
   right: "ATTESTED"
25 tests, 2 failures (6 excluded)
```
Reverted; `git diff --stat lib/crosswake/release_candidate/cleanroom.ex` against `HEAD` showed
zero residual change, confirmed by re-running the full plan-scoped suite (31 tests, 0 failures)
before committing Task 3's test-only commit.

## Issues Encountered

None beyond the ledger-snapshot deviation documented above.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- The graded-claim classifier, the fourth `ATTESTED` bucket, and the terminal-gate proofs are
  all in place. 172-03 (non-vacuity proof test) can build directly on `evaluate_public!/1`'s
  final shape — no further schema or classifier changes are anticipated from this plan's side.
- Per `<atomicity_constraint>`: this plan is NOT separately mergeable. No PR was opened. 172-01,
  172-02, and 172-03 land together in one PR against `main`.
- Requirements XPUB-01, XPUB-02, and XPUB-03 (this plan's frontmatter `requirements`) are all
  satisfied at the evaluator layer as of this plan; XPUB-01's schema/transport work landed in
  172-01, and XPUB-02/XPUB-03's classifier/aggregate work lands here.

---
*Phase: 172-per-package-proof-scope*
*Plan: 02*
*Completed: 2026-09-17*

## Self-Check: PASSED

- All 4 plan-scoped/deviation files confirmed present and modified on disk via `git diff --stat`.
- All 4 task/deviation commit hashes (`bfc2ea23`, `3371b297`, `db182d30`, `ca912cc0`) confirmed
  present via `git log --oneline bd14220a..HEAD`.
- All plan-level `<verification>` commands re-run and passing: `mix format --check-formatted`
  (0), `mix compile --warnings-as-errors` (0 warnings), `mix test test/crosswake/release_candidate
  test/mix/tasks/crosswake_release_candidate_test.exs --max-cases 1` (86 tests, 0 failures),
  `bash -n script/verify_companion_cleanroom.sh` (0).
- Full project suite `mix test --exclude requires_example_host` re-run after the ledger-snapshot
  fix: 1846 tests, 0 failures.
