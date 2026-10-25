---
phase: 172-per-package-proof-scope
plan: 03
subsystem: release-candidate-proof
tags: [elixir, cleanroom, proof-scope, candidate_ref, non-vacuity, mutation-testing]

# Dependency graph
requires:
  - phase: 172-per-package-proof-scope
    provides: "172-01's per-package candidate_ref threaded end-to-end and 172-02's graded-claim
      classifier (reachable_and_compatible / unproven / fully_proven) plus the ATTESTED
      aggregate bucket, both already landed on this branch"
provides:
  - "Crosswake.Proof.Phase172PerPackageRefTest: a structural + reachability proof module that
    fails if the per-package ref collapse returns by any route (shell jq collapse, Artifact's
    family-level input, or a silently-dropped classifier branch)"
  - "A byte-exact regression anchor in artifact_test.exs that mutates real tarball-content
    bytes, recomputes the digest via Artifact.inspect_family!/1, and carries it into a full
    Cleanroom.evaluate_public!/1 verdict — pinning the proof floor below the digest-string layer"
  - "172-NON-VACUITY.md: the measured mutation/count record the phase-close verifier needs to
    populate 172-VERIFICATION.md's vacuity_taxonomy field"
affects: []

# Actuals (#2632)
actuals:
  tokens: 11430
  tasks: 3
  commits: 4
  plan_head_before: 0aff422b

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Structural + reachability pairing: every 'construct X is gone' assertion over source
      text is paired with a 'construct Y is there instead' assertion in the same test, and
      every claim string a classifier can emit is proven reachable by driving the public
      evaluator end-to-end rather than grepping for the literal alone"
    - "Byte-level regression anchor: mutate one real byte inside a package's unpacked root,
      recompute the digest through the real producer (Artifact.inspect_family!/1), then carry
      that recomputed digest into the consumer (Cleanroom.evaluate_public!/1) for a verdict —
      pins correctness one layer below a digest-string comparison"
    - "Cardinality-pinning a collection assertion inline via a named module attribute
      (@package_count length(Artifact.packages())) rather than a literal, satisfying both the
      repo's collection-assertion governance ledger and the no-bare-literal-package-count rule
      in the same line"

key-files:
  created:
    - test/crosswake/proof/phase172_per_package_ref_test.exs
    - .planning/workstreams/quality-ratchet-release/phases/172-per-package-proof-scope/172-NON-VACUITY.md
  modified:
    - test/crosswake/release_candidate/artifact_test.exs
    - test/crosswake/proof/phase170_vacuous_assertion_ledger_test.exs
    - script/collection_assertion_ledger.json

key-decisions:
  - "The proof module derives its package roster from Artifact.packages/0 and its group-width
    constant from a named @artifact_field_count module attribute, never a bare literal — so a
    future package addition or field-width change updates one place, not a re-audit."
  - "The byte-exact regression anchor lives in artifact_test.exs (not a new file) because it
    needs both Artifact.inspect_family!/1 (the real producer) and Cleanroom.evaluate_public!/1
    (the real consumer) in the same test, and artifact_test.exs already owns the fixture-mutation
    idiom (mutate_artifact/3, by_package/2) this test reuses."
  - "172-NON-VACUITY.md records only the 10 checks across the three plans that carry an
    actually-executed, observed-red, reverted mutation as full rows; the other 30 named checks
    are listed with a decidable reason (redundant coverage, a Phase-171-proved invariant this
    phase did not touch, a self-mutating test, or a measured git-diff/grep count) rather than
    silently omitted or force-fit with a fabricated mutation."
  - "A new Enum.all?/2 assertion this plan added (the fully-proven-claim reachability test) was
    flagged needs-fix by the repo's collection-assertion governance script; fixed inline with a
    named @package_count cardinality pin before landing, rather than deferring it to a future
    remediation pass — this milestone's own discipline applied to its own new test."

requirements-completed: [XPUB-02, XPUB-03]

coverage:
  - id: D1
    description: "A structural proof test fails if any expression anywhere in the tree
      re-collapses the six approved refs to one shared value, independent of the unit fixtures"
    requirement: "XPUB-02"
    verification:
      - kind: unit
        ref: "test/crosswake/proof/phase172_per_package_ref_test.exs#no jq expression collapses the approved manifest's refs to one scalar, and a per-package lookup is there instead"
        status: pass
      - kind: unit
        ref: "test/crosswake/proof/phase172_per_package_ref_test.exs#the observed ref is assigned exactly once, from a repository head resolution, never from the approved manifest"
        status: pass
      - kind: unit
        ref: "test/crosswake/proof/phase172_per_package_ref_test.exs#neither shell script passes a ref as the first positional into Artifact.inspect_cli!/1, and the root/manifest positionals are there instead"
        status: pass
      - kind: unit
        ref: "test/crosswake/proof/phase172_per_package_ref_test.exs#Artifact's family-level input keys omit candidate_ref, and the per-artifact keys carry it instead"
        status: pass
      - kind: unit
        ref: "test/crosswake/proof/phase172_per_package_ref_test.exs#the candidate-local artifact keys omit candidate_ref, and the approved/public keys carry it instead"
        status: pass
    human_judgment: false
  - id: D2
    description: "Both shell scripts group artifact positionals in sevens, and neither passes
      a ref as the leading positional to the producer CLI"
    requirement: "XPUB-02"
    verification:
      - kind: unit
        ref: "test/crosswake/proof/phase172_per_package_ref_test.exs#verify_companion_cleanroom.sh's artifact_args append carries exactly the named field count"
        status: pass
      - kind: unit
        ref: "test/crosswake/proof/phase172_per_package_ref_test.exs#hex_artifacts.sh's ARTIFACT_ARGS append carries exactly the named field count"
        status: pass
    human_judgment: false
  - id: D3
    description: "All three graded-claim strings (fully_proven, reachable_and_compatible,
      unproven) are reachable through Cleanroom.evaluate_public!/1 itself, mutually exclusive,
      and the claim entry count equals the package count"
    requirement: "XPUB-03"
    verification:
      - kind: unit
        ref: "test/crosswake/proof/phase172_per_package_ref_test.exs#the two new reason strings and all three claim strings are typed in the classifier source"
        status: pass
      - kind: unit
        ref: "test/crosswake/proof/phase172_per_package_ref_test.exs#a fully-proven family reaches the fully_proven claim for every package"
        status: pass
      - kind: unit
        ref: "test/crosswake/proof/phase172_per_package_ref_test.exs#a drifted-but-byte-identical package reaches the reachable_and_compatible claim through the evaluator"
        status: pass
      - kind: unit
        ref: "test/crosswake/proof/phase172_per_package_ref_test.exs#a drifted package whose bytes also differ reaches the unproven claim, never fully_proven, through the evaluator"
        status: pass
      - kind: unit
        ref: "test/crosswake/proof/phase172_per_package_ref_test.exs#the claim entry count equals the package count and no package carries two claims, for a fully-proven run"
        status: pass
      - kind: unit
        ref: "test/crosswake/proof/phase172_per_package_ref_test.exs#the claim entry count equals the package count and no package carries two claims, for a mixed-claim run"
        status: pass
    human_judgment: false
  - id: D4
    description: "A non-drifted package still requires a byte-for-byte tarball match: flipping
      a single byte of real tarball content makes the proof fail at the tarball layer, not only
      at the digest-string layer; drift cannot launder a real byte change into a weaker claim"
    requirement: "XPUB-02"
    verification:
      - kind: unit
        ref: "test/crosswake/release_candidate/artifact_test.exs#byte-exact regression anchor: a single real byte flip still fails the proof -- silent weakening would show as fully_proven/COMPLETE"
        status: pass
      - kind: unit
        ref: "test/crosswake/release_candidate/artifact_test.exs#drift cannot launder a byte change: same mutation plus a drifted ref reports unproven, never reachable_and_compatible or fully_proven"
        status: pass
    human_judgment: false
  - id: D5
    description: "Every check this phase landed has a recorded mutation that was run, observed
      red, and reverted, with its output captured, or a decidable reason why not — the phase
      leaves measured facts, never a bare tick"
    requirement: null
    verification:
      - kind: other
        ref: "172-NON-VACUITY.md: 10 mutation-backed rows + 30 named no-mutation checks = 40, matching the 8+17+15 checks named across 172-01/172-02/172-03's SUMMARY.md coverage lists"
        status: pass
    human_judgment: false

# Metrics
duration: 50min
completed: 2026-09-17
status: complete
---

# Phase 172 Plan 03: Per-Package Proof Scope — Non-Vacuity Proof Summary

**Landed a structural + reachability proof module that fails if the per-package ref collapse returns by any route, a byte-level regression anchor that pins the proof floor below the digest-string layer, and a measured non-vacuity record naming every check this phase landed with its mutation evidence or a decidable reason why none was run.**

## Performance

- **Duration:** 50 min
- **Started:** 2026-09-17T20:40:00Z (approx, first Read)
- **Completed:** 2026-09-17T21:30:00Z
- **Tasks:** 3 completed
- **Files modified:** 2 created, 3 modified (1 plan-scoped + 2 for a bundled Rule 3 deviation)

## Accomplishments

- `test/crosswake/proof/phase172_per_package_ref_test.exs` proves the collapse this phase
  removed cannot silently return: no jq expression in `verify_companion_cleanroom.sh` collapses
  the six approved refs to one scalar (and a per-package `select(.package == $package) |
  .candidate_ref` lookup is there instead); `MATRIX_PUBLIC_REF` is assigned exactly once, from
  `git rev-parse HEAD`, never from the approved manifest; neither shell script's producer CLI
  call passes a ref as the first positional; both scripts group artifact positionals in exactly
  seven fields (a named `@artifact_field_count` attribute, not a bare literal); `candidate_ref`
  sits on `Artifact`'s per-artifact keys (not the family-level input) and on `Cleanroom`'s
  approved/public keys (not the candidate-local ones); and all three graded-claim strings
  (`fully_proven`, `reachable_and_compatible`, `unproven`) are proven reachable by driving
  `Cleanroom.evaluate_public!/1` end-to-end, with the claim-entry-count-equals-package-count and
  mutual-exclusivity properties asserted directly.
- Two new tests in `artifact_test.exs` mutate one real byte inside a package's unpacked root,
  recompute the payload digest through `Artifact.inspect_family!/1` (the real producer, not a
  hand-written digest string), and carry that recomputed digest into a full
  `Cleanroom.evaluate_public!/1` verdict: the byte-exact regression anchor reports
  `digest_mismatch` and a `BLOCKED` state for a non-drifted package; the companion case proves a
  simultaneously drifted ref cannot launder the same byte change into the weaker
  `reachable_and_compatible` claim — it still reports `unproven`, never a completion state.
- `172-NON-VACUITY.md` records the measured facts the phase-close verifier needs: 40 checks are
  named across the three plans' `SUMMARY.md` coverage lists, 10 carry an actually-run,
  observed-red, reverted mutation (full row: check identity, mutation, quoted output, commit),
  and the remaining 30 are individually named with a decidable reason — never silently omitted,
  never a bare tick.
- Two mutations were run against this plan's own new proof module and observed red: reintroducing
  the deleted `unique | length == 1` jq reduction into `verify_companion_cleanroom.sh`, and
  deleting the `reachable_and_compatible` reason-string literal from `cleanroom.ex`'s drift
  branch. A third mutation was run against the new byte-exact regression anchor: replacing the
  guarded `payload_digest !=` comparison with a literal `false`. All three were reverted; `git
  diff --stat` confirmed a clean revert before each commit.
- One new `Enum.all?/2` assertion this plan added was flagged `needs-fix` by the repository's
  own collection-assertion governance script (`script/inventory_collection_assertions.exs`) —
  fixed inline with a named `@package_count` cardinality pin rather than shipped unfixed, and the
  Phase 170 governance ledger and its three pinned literals were regenerated and updated to match.

## Task Commits

Each task was committed atomically:

1. **Task 1: Structural proof module — the collapse cannot return by any route** - `a431f21a` (test)
2. **Task 2: Byte-level regression — a non-drifted package still requires a byte-for-byte tarball match** - `1100c8b4` (test)
3. **Task 3: Measured non-vacuity record for the phase-close verifier** - `5d9cbcfd` (docs)

**Deviation fix:** `4d4fbc2c` (fix — bundled Rule 3, see Deviations)

**Plan metadata:** commit pending (this SUMMARY + STATE/ROADMAP/REQUIREMENTS update)

## Files Created/Modified

- `test/crosswake/proof/phase172_per_package_ref_test.exs` — new structural + reachability
  proof module (13 tests)
- `test/crosswake/release_candidate/artifact_test.exs` — 2 new byte-exact regression tests
- `.planning/workstreams/quality-ratchet-release/phases/172-per-package-proof-scope/172-NON-VACUITY.md` — measured non-vacuity record
- `test/crosswake/proof/phase170_vacuous_assertion_ledger_test.exs` — pinned literals updated
  for one new legitimate collection-assertion site (deviation, see below)
- `script/collection_assertion_ledger.json` — regenerated snapshot adding the same row

## Decisions Made

- The proof module derives its package roster from `Artifact.packages/0` and names its
  group-width constant (`@artifact_field_count`), never a bare literal, so a future package or
  field-width change updates one place instead of triggering a re-audit.
- The byte-exact regression anchor lives in `artifact_test.exs`, not a new file, because it
  needs both the real producer (`Artifact.inspect_family!/1`) and the real consumer
  (`Cleanroom.evaluate_public!/1`) in the same test, and `artifact_test.exs` already owns the
  fixture-mutation idiom (`mutate_artifact/3`, `by_package/2`) this test reuses.
- `172-NON-VACUITY.md` records only the 10 checks with an actually-executed mutation as full
  rows; the other 30 are named with a decidable reason rather than silently omitted or given a
  fabricated mutation just to fill the row shape.
- The new `Enum.all?/2` reachability assertion was fixed with a named cardinality pin
  (`@package_count length(Artifact.packages())`) immediately, in-line with this milestone's own
  non-vacuity discipline, rather than deferred as a future remediation item.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Regenerated the Phase 170 collection-assertion ledger for one new pinned row**
- **Found during:** post-Task-1 full-tree verification (`mix test test/crosswake/proof`)
- **Issue:** The new "a fully-proven family reaches the fully_proven claim for every package"
  test's `assert Enum.all?(result.package_claims, &(&1.claim == "fully_proven"))` is a genuinely
  new collection-assertion site the Phase 170 governance ledger did not yet know about.
  `test/crosswake/proof/phase170_vacuous_assertion_ledger_test.exs` failed with an unclassified
  row and, after the fix, three literal-count mismatches — a direct, mechanical consequence of
  this task's own new test, not a pre-existing or out-of-scope failure, and one this milestone's
  own discipline should not tolerate landing unfixed.
- **Fix:** Added a named `@package_count length(Artifact.packages())` module attribute and an
  `assert length(result.package_claims) == @package_count` cardinality pin immediately before the
  flagged line, reclassifying the site to `safe-cardinality-pinned` on rescan. Regenerated the
  ledger snapshot, confirmed via diff that exactly one row was added with no existing row's key or
  bucket changed, and updated the three pinned literals: `@audited_site_count` 226→227,
  `@shape_counts["assert_all"]` 45→46, `@bucket_counts["safe-cardinality-pinned"]` 29→30.
- **Files modified:** `test/crosswake/proof/phase170_vacuous_assertion_ledger_test.exs`,
  `script/collection_assertion_ledger.json`
- **Verification:** `mix test test/crosswake/proof/phase170_vacuous_assertion_ledger_test.exs
  --max-cases 1` — 19 tests, 0 failures (was 4 failures before the fix). Full proof directory:
  690 tests, 0 failures. Full project suite `mix test --exclude requires_example_host`: 1861
  tests, 0 failures.
- **Committed in:** `4d4fbc2c`

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Necessary to keep an unrelated governance test green and to avoid landing a
`needs-fix`-classified assertion inside the very phase whose purpose is closing that defect
class; no scope creep — the fix is a single cardinality pin plus the ledger's mechanical update.

## Mutation Proofs (non-vacuity, per VERIFICATION-CONVENTIONS.md)

Full detail, quoted output, and commit-by-commit attribution for every mutation run across all
three plans in this phase (172-01, 172-02, 172-03) is recorded in
[`172-NON-VACUITY.md`](./172-NON-VACUITY.md). Summary of the three mutations run in this plan:

1. **Reintroduced the deleted `unique | length == 1` jq reduction** into
   `verify_companion_cleanroom.sh`. Observed: `test/crosswake/proof/phase172_per_package_ref_test.exs`
   — `13 tests, 1 failure` on the "no jq expression collapses..." test. Reverted; suite green
   again (13 tests, 0 failures).
2. **Deleted the `reachable_and_compatible` reason-string literal** from `cleanroom.ex`'s drift
   branch (replaced its return value with `"digest_mismatch"`). Observed: `13 tests, 1 failure`
   on the "a drifted-but-byte-identical package reaches the reachable_and_compatible claim..."
   test — the classifier's own `public_artifact_claim/1` catch-all mapped the mutated reason to
   `"unproven"`, and the reachability test caught it exactly as designed. Reverted; suite green
   again.
3. **Replaced the guarded `payload_digest !=` comparison with `false`** in `cleanroom.ex`.
   Observed: `test/crosswake/release_candidate/artifact_test.exs` — `7 tests, 1 failure` on the
   byte-exact regression anchor (`left: []`, `right: [%{package: "crosswake", reason:
   "digest_mismatch"}]`). Reverted; `git diff --stat` confirmed zero residual change, full
   plan-scoped suite (38 tests, 0 failures) green again before the commit.

## Issues Encountered

None beyond the ledger-snapshot deviation documented above.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- This is the last plan in Phase 172. All four ROADMAP success criteria for this phase are now
  proven, not merely asserted: SC#1 (the collapse cannot return, structurally proven), SC#2
  (the two-different-refs fixture is proven end-to-end, landed in 172-01/172-02 and reachability-
  proven here), SC#3 (byte-exact floor pinned at the tarball-content layer with a recorded
  mutation), and SC#4 (the three result types proven reachable and mutually exclusive through the
  public evaluator).
- Requirements XPUB-02 and XPUB-03 (this plan's frontmatter `requirements`) are marked complete,
  confirmed ready by `requirements ready-ids` against this plan before marking (no blocked IDs).
  XPUB-01 was already complete from 172-01 and is unaffected.
- Per `<atomicity_constraint>`: this plan is NOT separately mergeable. Per the plan's `<output>`
  instruction, this is the last plan in the phase — after this SUMMARY and its metadata commit,
  ONE pull request covering 172-01, 172-02, and 172-03 together should be opened against `main`.
  No PR has been opened by this executor.

---
*Phase: 172-per-package-proof-scope*
*Plan: 03*
*Completed: 2026-09-17*

## Self-Check: PASSED

- All 6 plan-scoped/deviation files confirmed present on disk via `[ -f ]`: the new proof
  module, the modified `artifact_test.exs`, `172-NON-VACUITY.md`, this SUMMARY.md, the modified
  `phase170_vacuous_assertion_ledger_test.exs`, and the regenerated `collection_assertion_ledger.json`.
- All 5 task/deviation/SUMMARY commit hashes (`a431f21a`, `1100c8b4`, `4d4fbc2c`, `5d9cbcfd`,
  `b053d244`) confirmed present via `git log --oneline --all`.
- All plan-level `<verification>` commands re-run and passing: `mix format --check-formatted`
  (0), `mix test test/crosswake/proof --max-cases 1` (690 tests, 0 failures), `bash -n
  script/verify_companion_cleanroom.sh script/release_candidate/hex_artifacts.sh` (0),
  `test -f 172-NON-VACUITY.md && grep -cv '^#' 172-NON-VACUITY.md` (118, non-zero), `grep -c
  '\[ \]\|\[x\]\|☑' 172-NON-VACUITY.md` (0, no checkbox marks).
- Full project suite `mix test --exclude requires_example_host` re-run after the ledger-snapshot
  fix: 1861 tests, 0 failures.
