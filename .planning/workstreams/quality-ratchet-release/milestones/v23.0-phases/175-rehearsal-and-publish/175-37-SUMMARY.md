---
phase: 175-rehearsal-and-publish
plan: 37
subsystem: release
tags: [rel17, release-please, candidate-rehearsal, evidence]
requires:
  - phase: 175-36
    provides: REL-17 publication guards and candidate release contract
provides:
  - Fresh exact-head successor candidate evidence for version 0.2.6
  - Safe Hex, iOS, and Maven rehearsal evidence plus canonical receipt
  - Passing live pre-merge REL-17 envelope with authority pending
affects: [175-38, quality-ratchet-release]
actuals:
  tokens: 175622
  tasks: 3
  commits: 1
tech-stack:
  added: []
  patterns: [exact-head candidate receipts, non-publishing rehearsal evidence]
key-files:
  created:
    - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-NEXT-SUCCESSOR-CANDIDATE.md
    - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence/175-next-successor-candidate.json
    - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence/175-next-successor-rehearsals.json
    - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence/175-next-successor-receipt.json
    - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence/175-next-successor-canonical-receipt.json
    - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence/175-next-successor-premerge.json
    - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence/175-next-successor-hex-response.json
    - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence/175-next-successor-premerge-sources/
  modified: []
key-decisions:
  - "Bind the three rehearsals to the SHA-256 of the exact candidate CI receipt artifact."
  - "Keep the successor authority PENDING; a READY receipt and passing pre-merge envelope do not authorize the candidate merge or publication."
patterns-established:
  - "Dispatch candidate rehearsals only after exact-head CI and target absence pass."
  - "Retain live adapter source bytes and hashes beside the pre-merge envelope."
requirements-completed: [REL-10, REL-11, REL-13, REL-17]
coverage:
  - id: D1
    description: Fresh, unused successor candidate with repaired lineage and exact-head CI
    requirement: REL-10
    verification:
      - kind: integration
        ref: "Crosswake CI run 36346477576; 49/49 checks passed on candidate head 0968fea84dc758c05b9b0161db2f221c9e778c3b"
        status: pass
      - kind: other
        ref: "jq candidate evidence verification; target absence, required-check policy, and runbook ancestry checks"
        status: pass
    human_judgment: false
  - id: D2
    description: Exact-candidate Hex, iOS, and Maven rehearsals with one unexpired 13-check receipt
    requirement: REL-11
    verification:
      - kind: integration
        ref: "Runs 36348273088, 36348273033, 36348273114, and attestation run 36348696331; all completed successfully"
        status: pass
      - kind: other
        ref: "jq rehearsal and receipt acceptance predicates; all passed"
        status: pass
    human_judgment: false
  - id: D3
    description: Fresh live pre-merge REL-17 evidence bound to the retained public Hex response
    requirement: REL-17
    verification:
      - kind: integration
        ref: "mix crosswake.release.gate --capture-live --operation linked_release --stage pre_merge; REL-17 PASS"
        status: pass
      - kind: other
        ref: "jq pre-merge identity, PENDING authorization, response digest, and source-row verification; passed"
        status: pass
    human_judgment: false
duration: 57min
completed: 2026-09-27
status: complete
---

# Phase 175 Plan 37: Successor Candidate Summary

**Repair PR #216 merged; version 0.2.6 now has exact-head CI, three safe rehearsals, a 13-check receipt, and passing pre-merge REL-17 evidence.**

## Performance

- **Duration:** 57 min
- **Started:** 2026-09-27T19:53:43Z
- **Completed:** 2026-09-27T20:50:51Z
- **Tasks:** 3
- **Files modified:** 30 evidence and candidate documentation files, including 23 retained adapter source files

## Accomplishments

- Merged the protected repair PR #216 at `b5608a3dc0b013d83ac2b25768f1907873739b20` after exact-head CI passed all 49 required checks. The repair binds `candidate.cleanroom` in the canonical receipt and moves slow temporary Phoenix Mix-host router tests into the bounded host-isolation lane.
- Refreshed Release Please PR #215 to base `b5608a3dc0b013d83ac2b25768f1907873739b20`, head `0968fea84dc758c05b9b0161db2f221c9e778c3b`, tree `0199c0bee29dbcf76bc1a12d241c0ed140a244bd`. Exact-head CI run `36346477576` passed 49/49. Repair lineage and runbook ancestry passed; Hex, iOS mirror, and Maven targets were absent before and after rehearsals.
- Completed Hex run `36348273088` (six packages), iOS run `36348273033` (PASS/PROVEN), and Maven run `36348273114` (VALIDATED then DROP). All were bound to the same candidate and caused no external state change. Receipt attestation run `36348696331` produced unexpired artifact `10941079991` with all 13 checks passing and publication `NONE`.
- Captured live pre-merge REL-17 evidence for the exact Hex rehearsal. Pagination, current candidate readiness, required-check policy, runbook ancestry, and the matching response-table row passed. The exact public Hex response is retained and its digest is bound in the pre-merge evidence.

## Task Commits

- Repair PR #216 merge: `b5608a3dc0b013d83ac2b25768f1907873739b20`.
- Candidate, rehearsal, receipt, and pre-merge evidence: `7129e8c5`.

## Files Created/Modified

- `175-NEXT-SUCCESSOR-CANDIDATE.md` — candidate identity and safe next-step status.
- `evidence/175-next-successor-candidate.json` — exact candidate OIDs, CI, lineage, policy, and target absence.
- `evidence/175-next-successor-rehearsals.json` — exact run IDs, results, digests, artifact expiry, and post-rehearsal absence.
- `evidence/175-next-successor-receipt.json` and `evidence/175-next-successor-canonical-receipt.json` — attestation summary and byte-exact canonical artifact.
- `evidence/175-next-successor-premerge.json`, `evidence/175-next-successor-hex-response.json`, and `evidence/175-next-successor-premerge-sources/` — live REL-17 envelope, retained Hex response, and source facts/bytes.

## Decisions Made

- The rehearsal correlation digest is the SHA-256 of the exact candidate CI receipt artifact, `e8523fde68919b4d4c79bb7fdce999665e5c7855e420246660d218ea609d972a`.
- Keep the candidate authorization `PENDING`, `authorized=false`, with `merge_oid=null`. Gate 2 remains a separate human decision.

## Deviations from Plan

None. The repair was landed through the protected repair PR and the planned evidence remains non-publishing.

## Issues Encountered

- The first post-merge Release Please run left the prior candidate CI stale. Release Please refreshed PR #215 to the new base; the fresh exact-head run passed all 49 checks before any rehearsal was dispatched.
- The bounded example-host CI lane took about 27 minutes and passed before its timeout.
- No unresolved issues.

## User Setup Required

None.

## Next Phase Readiness

Plan 175-37 is complete. Phase 175 remains active with Plans 175-38 through 175-41 outstanding. Plan 175-38 is next and prepares the Gate 2 decision. PR #215 remains open and unmerged; no registry, iOS mirror, or Maven publication occurred. The retained `READY FOR APPROVAL` receipt is evidence only and does not authorize a merge.

---
*Phase: 175-rehearsal-and-publish*
*Completed: 2026-09-27*
