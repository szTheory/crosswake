---
phase: 178-clean-checkout-and-final-ci
plan: "01"
subsystem: testing
tags: [git, nodejs, source-qualification]
requires:
  - phase: 177-maintenance-and-queue-reconciliation
    provides: qualified six-file source bundle and semantic reconciliation
provides:
  - tested Phase 177 bundle replay and candidate qualification tool
  - local six-file candidate commit with a clean detached exact-commit proof clone
  - sanitized candidate source identity for later Phase 178 plans
affects: [178-02, 178-03, 178-04, 178-05]
actuals:
  tokens: 10256
  tasks: 2
  commits: 1
tech-stack:
  added: []
  patterns: [real Git replay fixtures, private immutable candidate binding, allowlisted public projection]
key-files:
  created:
    - .planning/workstreams/quality-ratchet-release/phases/178-clean-checkout-and-final-ci/178-evidence/prepare_candidate.mjs
    - .planning/workstreams/quality-ratchet-release/phases/178-clean-checkout-and-final-ci/178-evidence/prepare_candidate.test.mjs
    - .planning/workstreams/quality-ratchet-release/phases/178-clean-checkout-and-final-ci/178-evidence/candidate-source.json
  modified: []
key-decisions:
  - "Keep MAINT-07 and MAINT-08 pending until the full local verifier and hosted CI evidence are complete."
  - "Create the source candidate only in a separate delivery clone; preserve the recovery checkout's Git and source state."
patterns-established:
  - "Validate the recorded bundle bytes and patch digest before replaying the combined patch exactly once."
  - "Keep candidate roots and raw bundle binding private while publishing only commit, tree, path count and safe status."
requirements-completed: []
coverage:
  - id: D1
    description: "Phase-local qualifier replays and verifies source through a real commit and independent clean clone."
    verification:
      - kind: unit
        ref: "178-evidence/prepare_candidate.test.mjs"
        status: pass
      - kind: integration
        ref: "prepare_candidate.mjs --check"
        status: pass
    human_judgment: false
  - id: D2
    description: "The exact Phase 177 six-file source candidate is bound for later complete local and hosted verification."
    verification:
      - kind: integration
        ref: "candidate-source.json and private candidate-binding.json"
        status: pass
    human_judgment: false
duration: 11m
completed: 2026-10-12
status: complete
---

# Phase 178 Plan 01: Clean Checkout and Final CI Summary

**A digest-checked Phase 177 bundle now produces one six-file local candidate commit and a clean detached clone at the exact same commit and tree.**

## Performance

- **Duration:** 11 minutes
- **Started:** 2026-10-12T19:27:27Z
- **Completed:** 2026-10-12T19:38:14Z
- **Tasks:** 2
- **Files modified:** 4, including this summary

## Accomplishments

- Added a stdlib Node qualifier with `--self-test`, `--prepare`, and `--check` modes. It validates the Phase 177 base and tree, canonical GitHub `main`, private bundle digest and byte count, exact six-path selection, combined patch replay, and exact candidate tree.
- The private Phase 177 bundle produced candidate commit `5923a679ffbe1b587d97165aab772986b65cbd18` with tree `cf6ad7a134e7f8d7d54c33d3a40d0178ef5bb113`. A separate `--no-local` proof clone is detached at that commit with matching tree, index tree, and clean status.
- Added seven tests covering a real tracked edit and byte-bearing untracked file, wrong base, altered patch, path-set mismatch, symlink escape, tampered Git input, proof drift, and public-output privacy. All 119 captured rows remain accounted for; both historical reader comparisons remain unproven.
- Wrote a public allowlisted candidate projection and retained the immutable owner-only binding and handoff pointer for subsequent plans. No remote ref was written.

## Task Commits

1. **Task 1: Trace private bundle replay through Git commit and clean clone** — qualifier and tests remain uncommitted in the protected recovery checkout per its execution restriction.
2. **Task 2: Assemble and bind the six-file local candidate** — `5923a67` (`chore(178-01): qualify maintenance candidate`), created only in the separate delivery clone.

## Verification

- `node --check .planning/workstreams/quality-ratchet-release/phases/178-clean-checkout-and-final-ci/178-evidence/prepare_candidate.mjs` — passed.
- `node --test .planning/workstreams/quality-ratchet-release/phases/178-clean-checkout-and-final-ci/178-evidence/prepare_candidate.test.mjs` — 7 passed.
- `node .planning/workstreams/quality-ratchet-release/phases/178-clean-checkout-and-final-ci/178-evidence/prepare_candidate.mjs --self-test` — passed.
- `CROSSWAKE_178_PRIVATE_HANDOFF_ROOT=<private handoff> node .../prepare_candidate.mjs --check` — passed; candidate commit/tree and clean detached proof clone agree.
- Rechecked recovery protections against the retained snapshot: HEAD, branch, raw index digest, index entries, worktree identity, and all 1,263 non-planning tracked source files match. No staging or commit occurred in the recovery checkout.

## Decisions Made

- MAINT-07 and MAINT-08 remain pending until Plans 02–05 establish the complete local verifier and same-source hosted CI result.
- The six approved source files are one atomic candidate. The recovery checkout remains the protected planning/evidence workspace; the candidate commit lives in its independent delivery clone.

## Deviations from Plan

**1. Execution checkout restrictions kept planning artifacts uncommitted.**
- **Found during:** Task 1
- **Issue:** The recovery checkout explicitly prohibits staging and commits; only the candidate commit is allowed in a separate full clone.
- **Adjustment:** Kept qualifier, tests, public projection, and this summary in the recovery checkout without staging; created the approved source candidate only in the delivery clone.
- **Impact:** No effect on the source candidate or proof clone. Root-owned STATE.md and ROADMAP.md updates remain with the orchestrator.

## Deferred Issues

- MAINT-07 full nine-stage local verification and MAINT-08 hosted CI remain open for later Phase 178 plans.
- The two historical reader comparisons remain unproven and retain their prior status.

## Self-Check: PASSED

- Qualifier, tests, public candidate projection, and summary exist.
- Candidate commit is present in the independent delivery clone; its detached proof clone has the same commit and tree and a clean status.
- Public candidate evidence contains only the allowlisted commit/tree/path/count/status data; private roots and bundle digests remain owner-only.
