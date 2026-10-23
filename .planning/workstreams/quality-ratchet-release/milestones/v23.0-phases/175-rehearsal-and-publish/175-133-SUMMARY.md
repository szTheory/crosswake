---
phase: 175-rehearsal-and-publish
plan: 133
subsystem: release-candidate-policy
tags: [javascript, github-rulesets, injected-tests]
requires:
  - phase: 175-rehearsal-and-publish
    provides: Plan131 authenticated policy-read collector seam
provides:
  - Exact-target known-inapplicability ordering for supported tag rulesets
  - Injected red/green and adversarial policy regression evidence
affects: [175-106, 175-46, 175-47, 175-48, 175-89]
actuals:
  tokens: 4938
  tasks: 2
  commits: 0
tech-stack:
  added: []
  patterns:
    - Validate supported policy envelopes before classifying exact-target inapplicability
key-files:
  created:
    - evidence/175-plan133-local-regression.json
    - 175-133-SUMMARY.md
  modified:
    - script/release_candidate/plan105_mirror_tag_collector.mjs
    - script/release_candidate/plan105_mirror_tag_collector.test.mjs
key-decisions:
  - "Only validated disabled or exact-ref-excluded tag rulesets can be known inapplicable; active applicable nonempty rule effects stay UNKNOWN."
  - "An empty conditions object remains a supported unrestricted envelope for compatibility; active targeting still fails closed."
patterns-established:
  - "Exact destination applicability is resolved before the active nonempty rule-effects UNKNOWN guard."
requirements-completed: []
coverage:
  - id: D1
    description: Exact-destination tag policy classification stays fail closed under malformed and applicable ruleset metadata.
    requirement: REL-13
    verification:
      - kind: unit
        ref: node --test script/release_candidate/plan105_mirror_tag_collector.test.mjs
        status: pass
      - kind: integration
        ref: HEX_OFFLINE=1 MIX_ENV=test mix test test/crosswake/release_candidate/plan105_mirror_tag_test.exs --max-cases 1
        status: pass
    human_judgment: false
duration: 18min
completed: 2026-10-10
status: complete
---

# Phase 175 Plan 133: Exact-Tag Policy Applicability Summary

**Disabled and exact-ref-excluded tag rulesets now resolve as inapplicable after supported-shape checks, while active applicable effects and malformed metadata remain UNKNOWN.**

## Performance

- **Duration:** 18 min
- **Started:** 2026-10-10T17:08:49Z
- **Completed:** 2026-10-10T17:26:00Z
- **Tasks:** 2
- **Files modified or created:** 4

## Accomplishments

- Added two named production-seam regressions. Both failed on the unchanged collector at the `policy.complete` assertion, then passed after the ordering repair.
- Validated policy envelope, target, enforcement, conditions, rules-array, and bypass-array shape before using a known-inapplicable result. Active applicable nonempty effects, malformed data, and mixed known/unknown rulesets remain incomplete; ADMIN does not change that result.
- Preserved legacy anonymous ruleset reads, existing fixed routes, authentication prerequisites, and operation limits. All tests used injected fetch, credential, and process dependencies.
- Recorded aggregate-only local evidence. All 418 pre-existing Phase 175 plan, summary, and evidence artifacts retained their original fingerprints.

## Task Commits

None. `phase_commit_docs.175=false` governs this plan; no files were staged, committed, or otherwise changed through Git operations.

## Files Created/Modified

- `script/release_candidate/plan105_mirror_tag_collector.mjs` — validates supported tag-rule metadata and resolves known inapplicability before the active nonempty-effects guard.
- `script/release_candidate/plan105_mirror_tag_collector.test.mjs` — adds red/green target cases and malformed, applicable, ADMIN, and mixed-ruleset regressions.
- `evidence/175-plan133-local-regression.json` — closed-key aggregate for local red/green and historical-integrity results.
- `175-133-SUMMARY.md` — records local test results and retained release holds.

## Verification

- RED on original collector: both named tests failed because the known-inapplicable policy was incomplete.
- GREEN after repair: both named tests passed through `runCurrentFactsRead` with injected adapters; the fake recorded only the fixed GET routes.
- Adversarial Node collector suite: 117 tests, 0 failures, 0 skipped.
- Focused ExUnit coordinator suite: 37 tests, 0 failures.
- Both Node syntax checks and scoped `git diff --check` passed.
- Historical integrity: 418/418 pre-existing phase plan, summary, and evidence artifacts unchanged.
- Evidence schema check: exactly seven required keys, correct red/green counts, positive historical count, and no live-cause or network promotion.

## Decisions Made

- Kept `ruleApplies` semantics unchanged and moved only the active nonempty-effects guard after validated exact-target applicability.
- Kept empty conditions as a supported unrestricted envelope for compatibility. For active rules, missing targeting detail still produces UNKNOWN.

## Deviations from Plan

None. The empty-conditions compatibility case was retained because the existing coordinator suite exercises it as a supported disabled-ruleset envelope.

## Issues Encountered

The first ExUnit run exposed that the existing injected coordinator fixture relies on a disabled ruleset with empty conditions. The metadata validator now accepts that established envelope while keeping active rules without targeting conditions fail closed; the rerun passed all 37 cases.

## Known Stubs

None.

## Release Posture

Plan106 HELD; Plans46-48/89 HELD; REL-13/14/15/17 OPEN; readiness BLOCKED; effective write permission UNKNOWN; tag authority NONE; merge policy UNKNOWN; release hold ACTIVE; candidate version UNKNOWN.

This local repair adds no live observation or authorization. The consumed Plan132 read and its original safe stop remain historical; any future read requires fresh scope/card/collector binding and a fresh one-use allow/hold. No real provider, credential helper, remote Git, dry run, tag, CI, merge, registry, publication, or network action occurred. Phase 175 remains incomplete.

## Self-Check: PASSED

Both declared output artifacts exist, the evidence has the exact closed key set and required values, the historical artifact comparison passed, and all focused automated checks passed. No commit was created because the phase configuration forbids staging and commits.

---
*Phase: 175-rehearsal-and-publish*
*Completed: 2026-10-10*
