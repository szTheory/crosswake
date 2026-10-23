---
phase: 178-clean-checkout-and-final-ci
plan: "05"
subsystem: release-quality
tags: [final-ci, exact-source, local-proof, privacy, evidence-join]
requires:
  - phase: 178-clean-checkout-and-final-ci
    provides: exact candidate identity, current CI collection contract, and delivered open PR
provides:
  - Exact-merge-OID final local --all proof with retained private logs and index snapshots
  - Current hosted run and strict same-OID acceptance join
affects: [quality-ratchet-release]
actuals:
  tokens: 16798
  tasks: 3
  commits: 0
tech-stack:
  added: []
  patterns: [private run capture, exact OID joins, policy-scoped artifact cleanup]
key-files:
  created:
    - .planning/workstreams/quality-ratchet-release/phases/178-clean-checkout-and-final-ci/178-05-SUMMARY.md
    - .planning/workstreams/quality-ratchet-release/phases/178-clean-checkout-and-final-ci/178-evidence/final-acceptance.json
  modified:
    - .planning/workstreams/quality-ratchet-release/phases/178-clean-checkout-and-final-ci/178-evidence/hosted-ci-proof.json
    - .planning/workstreams/quality-ratchet-release/phases/178-clean-checkout-and-final-ci/178-evidence/final-local-proof.json
    - .planning/workstreams/quality-ratchet-release/phases/178-clean-checkout-and-final-ci/178-evidence/join_proof.mjs
    - .planning/workstreams/quality-ratchet-release/phases/178-clean-checkout-and-final-ci/178-evidence/join_proof.test.mjs
key-decisions:
  - "Require exactly the contract-declared advisory rows in addition to the required graph, and keep advisory outcomes separate from required gates."
  - "Use the latest successful exact-source local run and preserve earlier failed or blocked attempts privately with their causes and unknowns."
patterns-established:
  - "Join hosted totals to required and declared advisory rows reconstructed from complete private job/check pages."
requirements-completed: []
duration: not reliably recorded
completed: 2026-10-13
status: complete
---

# Phase 178 Plan 05: Final CI and Exact-Source Proof Summary

**Hosted run 38322827152 attempt 1 and a complete local `--all` run both prove the same unmerged governed merge object, `f2d8875ee52d9679157c73b4a701b510ee612cb8`.**

## Accomplishments

- Collected the current hosted attempt with complete run, job, check, workflow, checkout-log, PR, base, and policy reads. All 48 required rows are successful. The complete graph contains 49 job/check rows because the contract also declares one advisory row (`brand-visual`); the join reconstructs and reports it separately. The required checks include the `Crosswake CI` app identity, and the governed merge checkout OID matches the local run.
- Completed `script/verify_repository.sh --all` in the independent private proof clone at exact commit `f2d8875ee52d9679157c73b4a701b510ee612cb8`, tree `27f4073039b4dd976492127549603a76ce22499b`. All nine ordered stages passed and all eight executed-stage logs ended successfully. Before/after HEAD, tree, index-entry digest, raw index bytes, and NUL status matched; the raw index SHA-256 is `041d1976a07d491eae6a49885ba41ec9cd23e50aea0455373ee8fab1bacd054d`.
- The final local projection reports 15,824 pre-existing ignored entries and 20 newly created, policy-classified local-tooling files. The 22 browser artifacts generated during the successful verifier run were verified as new, regular, current-user-owned files under the exact policy category; their exact bytes and hashes and the original post-run snapshot are retained privately. The policy's invocation-created browser-output remediation was applied, and a distinct post-remediation snapshot was collected without changing source or index bytes.
- The strict join now requires all 48 required job/check rows and the exact advisory set declared by the CI contract. It verifies advisory names, attempt, terminal status, job/check identities, and check-suite linkage from private raw pages; advisory outcomes remain separate from required gates. `final-acceptance.json` records 49 total rows, 48 required rows, one advisory row, 46 governed merge checkouts, one head-only proof, nine local stages, and an open, unmerged candidate.
- The exact same-OID local and hosted evidence is ready for the workstream verifier. This summary does not mark MAINT-07 or MAINT-08 complete; the workstream owner records those requirements after verification. No merge, tag, publication, or release action was taken.

## Live Join Hardening

- The production live reader pins every GitHub API call to `github.com`, validates the canonical repository on the PR head and base, and reads `refs/pull/238/merge` from the fixed canonical Git URL. It requires the PR `merge_commit_sha`, that Git ref OID, the hosted governed merge OID, and the local proof commit to match exactly.
- It retains stdout, stderr, exit status, byte counts, and SHA-256 digests for all 10 GitHub GETs and both Git ref reads in a new mode-0600 binding beneath the owner-private directory. The acceptance projection contains no capture paths or raw output. Earlier bindings remain untouched.
- The join compares canonical fingerprints of the complete live branch-protection and effective-rules pages with the final policy pages retained for the hosted run. It also repeats run, PR, base, merge-ref, and policy reads after policy collection; the first and final snapshots must agree and still identify the selected attempt and source.
- D-20 derives success from the required governed graph. A failed workflow-level conclusion is accepted only when the required graph remains green and a contract-declared advisory row has a failure; neutral, cancelled, skipped, incomplete, or failed required work remains blocked.

## Important Execution Evidence

- Earlier full-run attempts are preserved as history. One 2,140-test run recorded one failure, but its retained output omitted the assertion block, so its cause remains unknown. Separate non-elevated attempts exposed actual macOS Chromium MachPort `SIGTRAP` and SwiftPM `sandbox_apply: Operation not permitted` failures. These were recorded as environment denials, not as source fixes. A later elevated complete run passed all nine stages.
- An earlier successful full run could not be collected because four pre-existing ignored Python bytecode files in the task-owned clone were not classified by the repository artifact policy. Their provenance was not inferred. Before the final accepted run, the four exact untracked regular files were archived privately, their paths and hashes were verified, and only those files were removed from the disposable proof clone. `PYTHONDONTWRITEBYTECODE=1` prevented their recreation. The final run's initial ignored inventory then had no unclassified paths.
- A one-megabyte Node subprocess buffer first stopped a collector preflight before the verifier ran (`ENOBUFS`). The private runner adapter was boundedly increased to 128 MiB; this did not change verifier, source, manifest, flags, or test coverage.
- The first live join exposed a stale private invocation pointer that still referenced a failed attempt. The prior binding bytes were archived privately, then the binding was renewed to the successful final invocation. The next join exposed the 49-total/48-required advisory-count mismatch; red-first tests reproduced it before the join correction.

## Verification

- `node --test .../local_proof.test.mjs` — 13 passed, 0 failed.
- `node --test .../join_proof.test.mjs` — 23 passed, 0 failed. Red-first cases cover unchanged PR parents with a changed merge ref, same-count full-policy drift, mid-read attempt drift, noncanonical repository data, a stale private proof projection, advisory-only run failure, and private subprocess capture modes. All five Plan05 evidence test files pass: 82 passed, 0 failed.
- `local_proof.mjs --self-test`, `ci_evidence.mjs --self-test`, and `join_proof.mjs --self-test` — passed.
- The actual `join_proof.mjs --check` passed after the new live reads — `hosted=49/49; local=9/9; requirements=MAINT-07,MAINT-08`. It read the current open PR and run 38322827152 attempt 1, confirmed 48 required rows plus one declared advisory row, and retained 12 fresh private subprocess captures in a unique binding.
- The fresh historical protection check confirmed all 1,677 protected historical files unchanged. This execution made no source, index, stage, commit, branch, worktree, merge, or publication changes in the shared checkout.

## Task Commits

None. This execution was explicitly limited to private clones and owned planning evidence; no recovery-checkout or remote Git mutation was permitted.

## Deviations from Plan

The final proof required a policy-bounded cleanup of invocation-created ignored artifacts, a correction to the join's treatment of the contract-declared advisory job, and live join guards for canonical merge identity and full policy snapshots. The local verifier, CI manifest, required test matrix, and source were not changed. Earlier failure causes are retained as unknown where raw assertion output was unavailable; no cause or repair is inferred.

## Next Action

Submit this evidence to the Phase 178 verifier and workstream owner for their final state/roadmap reconciliation. The PR remains open and unmerged; the acceptance result does not imply merge or release.

## Self-Check: PASSED

The summary and all five owned evidence artifacts exist. The exact-source local proof and current hosted proof pass the strict join; the five test files report 82/82, the join self-test passes, and the actual live read retained all 12 private subprocess captures. The fresh 1,677-file history check passed. No commit is expected for this isolated evidence execution.

---
*Phase: 178-clean-checkout-and-final-ci*
*Completed: 2026-10-13*
