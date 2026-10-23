---
phase: 183-close-gap-twin-source-binding-fails-closed-on-uncommitted-co
verified: 2026-10-15T15:00:00Z
status: passed
score: 6/6 must-haves verified
covered_files:
  - .planning/workstreams/quality-ratchet-release/phases/183-close-gap-twin-source-binding-fails-closed-on-uncommitted-co/183-01-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/183-close-gap-twin-source-binding-fails-closed-on-uncommitted-co/183-01-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/183-close-gap-twin-source-binding-fails-closed-on-uncommitted-co/183-02-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/183-close-gap-twin-source-binding-fails-closed-on-uncommitted-co/183-02-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/183-close-gap-twin-source-binding-fails-closed-on-uncommitted-co/183-03-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/183-close-gap-twin-source-binding-fails-closed-on-uncommitted-co/183-03-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/183-close-gap-twin-source-binding-fails-closed-on-uncommitted-co/183-04-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/183-close-gap-twin-source-binding-fails-closed-on-uncommitted-co/183-04-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/183-close-gap-twin-source-binding-fails-closed-on-uncommitted-co/183-05-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/183-close-gap-twin-source-binding-fails-closed-on-uncommitted-co/183-05-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/183-close-gap-twin-source-binding-fails-closed-on-uncommitted-co/183-IDENTITY.json
  - .planning/workstreams/quality-ratchet-release/phases/183-close-gap-twin-source-binding-fails-closed-on-uncommitted-co/183-TWIN-RESULT.json
covered_digest: "v3:sha256:81e692a8d69ce04b8605932eca12d39b1e77b67081e76d3d1faede7841434714"
behavior_unverified: 0
---

# Phase 183 Verification Report

**Goal:** the twin receipt's source and installed_build joins attest the code that actually ran; a dirty candidate fails closed with a named cause; the Phase 180 code is in the attested tree; the twin ran once into a new run root.
**Status:** passed (no gaps, no human items). The twin was not re-run (D-16); everything was checked from recorded artifacts, candidate git history, and unit tests.

## What was checked, in plain language

I read the candidate's git history and code, the twin-04 run files, the recorded result, and ran the 85 twin unit tests myself. All agree with the claims. The candidate worktree is clean (0 dirty records) and I changed nothing.

## Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Phase 180 code is committed in the candidate as seven ordered commits on da53c54 | VERIFIED | `git log`: 1fbf4d0, b93a21f, 9d2d19b, efd60a9, 451dfa9, 736a7d7, da214c5; file counts re-derived 3/5/13/23/12/3/1 |
| 2 | A dirty or untracked candidate is refused with named cause `source_dirty`, at freeze (before compile) and again after the run | VERIFIED | `freeze/3` calls `clean_tree` after the HEAD/tree checks and before `lock_digests`/`backend_digest`. `observe_identities` probes between two HEAD/tree reads, and `source`/`installed_build` exist only if clean and steady. The journey goes only through `checked_identities/3`. `:source_dirty` is in the receipt's closed causes. Probe uses `core.excludesFile=/dev/null`, a scrubbed git env, `.git/info/exclude` check, and counts only (no paths printed). |
| 3 | Run root inside the candidate is refused; output is plain language | VERIFIED | `outside_candidate/2` in twin_runtime.ex (device/inode compare); the verify_twin task prints "The candidate has N uncommitted or untracked files…" and exits 2; covered by tests |
| 4 | Guard is effective (not vacuous) | VERIFIED | `mutation-183.log`: 8 mutations each fail the suite; unmutated copy passes. I re-ran: 85 tests across producers, receipt, journey and mix-task suites, 0 failures |
| 5 | Twin ran once into new root twin-04 against the fix commit; passed receipt matches delivered source | VERIFIED | Candidate HEAD is 50fcd57 (equals `fix-183.commit`), and the twin-04 prepared record names head 50fcd574 / tree d71bc587. `twin-04.exit` is 0 and stdout says passed with first cause none. `.started` was written once (13:43:32Z). Exactly four twin-NN roots; count before was 3; the candidate was clean after the run. The receipt has all seven joins passed, 10 groups passed, 49 observations. |
| 6 | Result copy and supersede records are faithful | VERIFIED | `cmp twin-04/twin-result.json 183-TWIN-RESULT.json` matches. `receipt_sha256` equals the sha256 of `twin-04/receipt.json` (c726b584…). The twin-01..03 history manifest checks OK. The annotation on 180-TWIN-RESULT.json carries its true sha (79f13923…, matches the file) and points to the 183 result. |

**Score:** 6/6. Every truth here is backed by an existing passing test, or by an artifact checked directly.

## Regression

`baseline-183.failures` and `fix-183.failures` are byte-identical (one known G1 gate failure, `phase180_twin_feasibility_test.exs:30`). The orchestrator's full run at 50fcd57 gave 2399 tests with that 1 failure. The fix commit touched only the 10 intended files (744 insertions, 102 deletions).

## Requirements coverage

| ID | Plans | Status | Evidence |
|----|-------|--------|----------|
| TWIN-01 | 01, 02, 03, 04, 05 | SATISFIED (re-attested) | Source join now bound to a clean fix(183-03) commit; REQUIREMENTS row 59 updated |
| TWIN-05 | 02, 03, 05 | SATISFIED (re-attested) | Closed cause `source_dirty`; receipt source-bound; row 63 |
| TWIN-06 | 01, 03, 04, 05 | SATISFIED (re-attested) | 10 groups, 5 fidelity limits and residual gates in the handoff result; row 64 |

No orphaned requirement IDs. All three IDs appear in REQUIREMENTS.md and match the plan frontmatter.

## Paths that can still degrade silently (WARNING-level notes, not gaps)

1. **Edit made and reverted during a run is not detected.** This is declared as the fifth fidelity limit in the receipt and the guide (D-12), so it is not silent.
2. **The receipt stores join outcomes, not the raw commit ID.** The binding of "passed" to 50fcd57 rests on the prepared record `twin-04-candidate.json` and the candidate history, which I checked. The receipt alone does not name the commit.
3. **Delivery residual.** The eight commits exist only in `/private/tmp/crosswake-phase180-impl`. Moving them into the authoritative tree needs a separately authorized delivery. This is outside this phase's goal and is recorded in the 183-05 SUMMARY.

## Anti-patterns

No unreferenced debt markers were found in the changed lines I read. Test fixtures use real git. No adopter identity was recorded or inferred.

## Human verification

None needed. All checks were automated.

_Verified: 2026-10-15_
_Verifier: Claude (gsd-verifier)_
