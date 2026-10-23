---
phase: 178-clean-checkout-and-final-ci
plan: "03"
subsystem: testing
tags: [github-actions, ci-evidence, checkout-provenance, required-checks]
requires:
  - phase: 178-01
    provides: immutable renewed source candidate and safe public candidate identity
provides:
  - Tested fixed-route GitHub CI evidence collector with per-job checkout provenance
  - Source-bound CI graph and live required-check policy contract
affects: [178-04, 178-05]
actuals:
  tokens: 32123
  tasks: 2
  commits: 0
tech-stack:
  added: []
  patterns: [paginated-gh-api-shape-validation, private-subprocess-capture, exact-checkout-oid-binding]
key-files:
  created:
    - .planning/workstreams/quality-ratchet-release/phases/178-clean-checkout-and-final-ci/178-evidence/ci_evidence.mjs
    - .planning/workstreams/quality-ratchet-release/phases/178-clean-checkout-and-final-ci/178-evidence/ci_evidence.test.mjs
    - .planning/workstreams/quality-ratchet-release/phases/178-clean-checkout-and-final-ci/178-evidence/ci-contract.json
    - .planning/workstreams/quality-ratchet-release/phases/178-clean-checkout-and-final-ci/178-03-SUMMARY.md
  modified: []
key-decisions:
  - "Only an exact observed per-job checkout OID can establish runner source identity; run and suite head SHAs do not substitute."
  - "Keep MAINT-08 pending until a current hosted run is joined to complete policy, job, check, and checkout evidence."
patterns-established:
  - "Capture raw GitHub pages and job logs in an owner-private directory; public artifacts contain only bounded source, graph, policy, and outcome facts."
  - "A successful complete empty effective-rules response is distinct from inaccessible or malformed policy evidence."
requirements-completed: []
coverage:
  - id: D1
    description: "The collector validates complete paginated run/check data and exact per-job checkout identity, with head-only release proof separated from merge-checkout proof."
    requirement: MAINT-08
    verification:
      - kind: unit
        ref: ".planning/workstreams/quality-ratchet-release/phases/178-clean-checkout-and-final-ci/178-evidence/ci_evidence.test.mjs"
        status: pass
      - kind: other
        ref: "node .planning/workstreams/quality-ratchet-release/phases/178-clean-checkout-and-final-ci/178-evidence/ci_evidence.mjs --self-test"
        status: pass
    human_judgment: false
  - id: D2
    description: "The renewed candidate's 46-leaf graph and current required-check policy are recorded in a public-safe source contract with a disjoint private raw-response binding."
    requirement: MAINT-08
    verification:
      - kind: other
        ref: "node .planning/workstreams/quality-ratchet-release/phases/178-clean-checkout-and-final-ci/178-evidence/ci_evidence.mjs --contract"
        status: pass
      - kind: other
        ref: "Selected-source manifest self-test invoked by --contract; private policy-binding identity and mode check"
        status: pass
    human_judgment: false
duration: 35min
completed: 2026-10-12
status: complete
---

# Phase 178 Plan 03: Clean Checkout and Final CI Summary

The read-only CI collector now binds complete run/check pages and actual per-job checkout logs to a specific attempt, retains invocation-specific private captures, and records the renewed eight-path candidate's source graph, workflow blob identity, and current required-check policy. It can persist a public allowlisted hosted proof with the validated run URL and governed merge OID after a current run passes; no hosted candidate run exists yet, so MAINT-08 remains pending.

## Performance

- **Duration:** approximately 35 minutes
- **Completed:** 2026-10-12
- **Tasks:** 2
- **Files produced:** 4, including this summary

## Accomplishments

- Added a standard-library Node collector for fixed GitHub GET routes, `--self-test`, `--contract`, and `--collect`. It validates paginated `--paginate --slurp` shapes, unique IDs/counts, exact job-to-check `check_run_url` relationships, suite/run/attempt provenance, required policy contexts, and per-job checkout logs. It rechecks the PR, completed run attempt, canonical base, and policy immediately before acceptance, distinguishes merge checkout from head-only release proof, requires all governed merge checkouts to identify one OID, and ignores failures from unrelated advisory jobs.
- Bound skip decisions to the selected classifier result, manifest skip reasons, and exact workflow `if` expressions. The source classifier reports full proof and no irrelevant leaves. The hosted job log does not reveal the computed release-candidate scope value; collection therefore requires the head-only release proof job to succeed and blocks if it is skipped.
- Exercised GitHub adapter return shapes against retained real subprocess stdout, stderr, and exit statuses, including the complete production `--collect` control flow in a temporary fixture. That flow uses actual candidate Git reads and subprocess calls to a local `gh` adapter returning fixed GET responses and job logs; it reaches private/public artifact persistence, then a final-attempt drift blocks and preserves the previous public bytes. Contract and collection calls use separate private capture directories; repeated labels and policy-binding refreshes retain previous bytes. Proof output requires the validated GitHub run URL, workflow source version/blob OID, and one governed merge OID. Each governed job is bound to its own checkout action pin because this workflow uses two distinct pinned revisions. The historical run remains shape/provenance-only and cannot count as candidate acceptance.
- Generated the contract from the renewed candidate clone: eight selected paths, 46 proof leaves, `classify-change` control, `merge-blocking-crosswake-ci` umbrella, and the live `Crosswake CI` required context bound to app 15368. Effective rules were read successfully and returned an empty complete result. The local credential's successful reads do not establish hosted workflow credential access.
- Wrote the separate owner-private `ci-policy-binding.json` with candidate identity and raw-response pointers. The renewed private binding filename was selected exactly and crosschecked against the public candidate identity.

## Verification

- `node --check .../ci_evidence.mjs` — passed.
- `node --test .../ci_evidence.test.mjs` — 14 passed, 0 failed.
- `node .../ci_evidence.mjs --self-test` — passed.
- `node .../ci_evidence.mjs --contract` — passed; 46 leaves, one required policy context, successful-empty effective rules.
- Public contract privacy, graph, and candidate-identity assertions — passed.
- Owner-private binding mode, exact renewed-binding filename, unique raw subprocess capture pointers/hash checks, candidate identity, and selected-path count assertions — passed.
- Temporary proof persistence test confirms private captures are revalidated before public output and that a failed integrity check leaves the prior public artifact untouched.

## Task Commits

No commits were created. The execution scope explicitly prohibited staging and commits in this shared checkout; root retains execution-state bookkeeping.

## Decisions Made

- An actual checkout OID and ref from the pinned checkout action's job log are required. Run head, check-suite head, and mutable PR merge association never stand in for runner HEAD.
- The candidate's source classifier is `full_proof`; its workflow conditions require all 46 leaves, and the collector blocks a skip unless the source-declared classifier/workflow conditions and manifest all agree. The release-candidate scope is treated as unknown until the head-only job succeeds.
- MAINT-08 remains pending until a current hosted candidate run, complete attempt pages, exact job checkout OIDs, and refreshed policy are joined by the collector. No hosted run is available yet, and workflow credential access remains unproven.

## Deviations from Plan

### Correctness and scope adjustments

1. Added current PR, run-attempt, canonical base, and policy rereads immediately before acceptance, rejecting drift before interpreting proof.
2. Corrected the private raw-response pointers to reference actual production subprocess captures and added retained-byte/status verification before normalized policy facts or proof artifacts are accepted.
3. Added a durable allowlisted `hosted-ci-proof.json` and separate owner-private per-run binding; neither is generated until proof validation passes. No such proof exists yet because no current hosted candidate run is available.
4. Added unique capture directories for candidate, contract, and each run/attempt, and archives the prior private policy binding before refreshing the current binding so raw response pointers remain immutable.
5. Added final-run completion, validated run-URL, pinned workflow blob/version, and single governed merge-OID requirements to proof acceptance.
6. Corrected the final snapshot join to validate the freshly reread pull request object before the last policy and artifact checks.
7. Bound each required job to its observed checkout-action pin after the full collect fixture exposed two distinct pins in the selected workflow.
8. The generic executor commit/state-update steps were withheld per the explicit shared-checkout ownership boundary: root owns STATE/ROADMAP/requirements and this worker is prohibited from staging or committing.

## Issues Encountered

- Historical run metadata and retained checkout logs did not identify the same PR merge ref. The regression test records this as evidence that historical fixtures are unsuitable for acceptance and that current collection must correlate the actual current PR and observed checkout ref. The fixture remains shape-only.
- The current candidate has no hosted run to collect. This is the planned later gate, not a green result or a policy pass for hosted workflow credentials.

## Next Phase Readiness

The source/policy contract and collector are ready for the Plan04/Plan05 evidence join. Plan05 must collect one current hosted run and keep MAINT-08 pending if any route, page, check, job, app identity, attempt, skip, or checkout OID is missing or inconsistent. Plan02's local proof remains independently owned.

## Self-Check: PASSED

All four Plan03 artifacts exist. The public contract candidate commit/tree/path set matches both the private policy binding and public candidate source record.

---
*Phase: 178-clean-checkout-and-final-ci*
*Completed: 2026-10-12*
