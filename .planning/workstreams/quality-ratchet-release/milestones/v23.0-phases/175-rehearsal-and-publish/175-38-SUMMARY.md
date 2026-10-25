---
phase: 175-rehearsal-and-publish
plan: 38
subsystem: release
tags: [rel17, release-please, gate-2, partial-release]
requires:
  - phase: 175-37
    provides: exact 0.2.6 candidate, rehearsals, and canonical receipt
provides:
  - Consumed single-use Gate 2 evidence bound to the exact candidate and protected merge
  - Passing actual post-merge REL-17 envelope and direct post-run registry observations
  - Durable PARTIAL outcome with the failed guard and skipped publishers recorded
affects: [175-39, quality-ratchet-release]
actuals:
  tasks: 3
  commits: 2
  outcome: PARTIAL
tech-stack:
  added: []
  patterns: [single-use release authorization, post-merge capture, no-retry partial recording]
key-files:
  created:
    - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence/175-next-successor-postmerge.json
    - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence/175-next-successor-core-run.json
    - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence/175-next-successor-core-registry.json
    - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence/175-next-successor-hex-response-postmerge.json
    - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence/175-next-successor-postmerge-sources/
  modified:
    - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-NEXT-SUCCESSOR-GATE-2.md
    - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence/175-next-successor-gate-2.json
key-decisions:
  - "The exact authorization was consumed for one normal protected merge and one ordinary run; no retry or recovery is allowed under this token."
  - "A passing post-merge capture does not override the ordinary Release Please guard failure or skipped publishers."
requirements-completed: []
coverage:
  - id: D-07/D-45
    description: Exact authorization and protected merge are post-merge bound
    requirement: REL-17
    verification:
      - kind: integration
        ref: "PR #215 merged as 998742856a37a97ae7247f6c532f9c154ea20885; parents and tree matched; admin bypass false"
        status: pass
      - kind: other
        ref: "Post-merge REL-17 capture passed; runbook ancestry passed at base, head, and merge"
        status: pass
    human_judgment: false
  - id: D-40/D-48
    description: One ordinary run publishes all coordinates or records PARTIAL and stops
    requirement: REL-13
    verification:
      - kind: integration
        ref: "Release Please run 36352732061 failed at approved-candidate merge guard; Hex, iOS, Maven and exact-public publishers were skipped"
        status: partial
      - kind: other
        ref: "Independent post-run direct checks found Hex/Maven HTTP 404 and no iOS v0.2.6 tag; no retry or recovery occurred"
        status: partial
    human_judgment: false
duration: 23min
completed: 2026-09-27
status: complete
---

# Phase 175 Plan 38: Exact Successor Gate 2 Summary

**Outcome: PARTIAL.** The one authorized merge occurred, but its sole ordinary Release Please run failed
before release creation. All three publisher jobs were skipped and all three public coordinates remain absent.

## Accomplishments

- Re-fetched exact-head CI, strict `Crosswake CI` policy, one live 13-check receipt, all three rehearsal runs/artifacts, runbook ancestry, and all three target absences at the pre-merge boundary.
- Recorded the exact user authorization and consumed it for one normal protected merge of PR #215. Merge `998742856a37a97ae7247f6c532f9c154ea20885` has exact parents `b5608a3dc0b013d83ac2b25768f1907873739b20` and `0968fea84dc758c05b9b0161db2f221c9e778c3b`, and the authorized candidate tree.
- Fresh post-merge REL-17 capture passed with consumed authorization and runbook ancestry at base/head/merge.
- Observed the one ordinary Release Please run [36352732061](https://github.com/szTheory/crosswake/actions/runs/36352732061). Its approved-candidate merge guard failed at “Require approved head parentage, identical tree, and exact receipt”; Release Please, Hex, iOS mirror, Maven, and exact-public jobs were skipped. The linked rollup artifact says `NOT_APPLICABLE`.
- Direct post-run queries found Hex HTTP 404, no iOS `v0.2.6` tag, and Maven HTTP 404. Automatic failure alert opened issue [#217](https://github.com/szTheory/crosswake/issues/217).
- No retry, recovery, or other publication action was performed. Gate 2 is consumed and `PARTIAL`.

## Verification

- Fresh live pre-merge capture: `REL-17 PASS` at 2026-09-27T21:35:43Z.
- Post-merge capture: `REL-17 PASS` at 2026-09-27T21:45:47Z.
- Exact-head CI run `36346477576`: success. Rehearsal runs `36348273088`, `36348273033`, `36348273114`: success; artifacts live at final recheck.
- Post-run registry observations: Hex 404, iOS tag absent, Maven 404.
- Ordinary run `36352732061`: failure; zero publisher jobs ran.

## Blocker and next GSD step

The hosted guard step exits 1 after reporting runbook ancestry PASS for base, head, and merge; it emitted no specific REL-17 reason. The independent local post-merge capture passes, so the hosted guard failure still needs diagnosis. Plan 175-39 is ineligible because its precondition requires successful three-coordinate publication in this same run.

Next command: `$gsd-debug --diagnose "quality-ratchet-release: Release Please run 36352732061 failed in approved-candidate merge guard before publishers; local post-merge REL-17 capture passes; diagnose without retrying publication"`
