---
phase: "177"
slug: maintenance-and-queue-reconciliation
status: verified
threats_open: 0
asvs_level: 1
block_on: high
created: "2026-10-12"
---

# Phase 177 security review

The independent audit found twelve controls closed, five blocking proof gaps and two medium reader comparisons without available historical verdict evidence. Scoped repairs now close the selector-resolution and source-privacy/fetch gaps; the independent recheck verified the interim handoff. The parent published and checked the final registered Phase178 handoff after independent goal verification passed; two medium historical-reader comparisons remain open. No risk has been accepted. Phase177 is complete and Phase178 final-source proof remains pending.

| Threat | Severity | Status | Evidence or required correction |
|---|---|---|---|
| T-177-01 | high | closed | Maintenance checker rejects private and sensitive fields. |
| T-177-02 | high | closed | Retirement needs terminal, caller, replacement, preservation and verification evidence. No new retirement is claimed. |
| T-177-03 | high | closed | All four preserved candidate-reader selectors hit absent Mix task/alias lookup and raise Mix.NoTaskError before option parsing or effects; no router restored. Historical reader comparison remains unproven. |
| T-177-04 | medium | open, nonblocking | No preserved Plan93 artifact verdict is available. Keep comparison unproven; obtain the exact artifact if archive inspection is needed. |
| T-177-05 | high | closed | All 74 preserved mirror selectors hit absent Mix task/alias lookup and raise Mix.NoTaskError before option parsing or effects; no router, tombstone, or writer restored. Historical reader comparison remains unproven. |
| T-177-06 | medium | open, nonblocking | Preserved mirror receipts do not establish an inspector verdict. Keep their original result and obtain original inspector evidence before comparison. |
| T-177-07 | high | closed | Separate paginated rosters, cursor/count checks and final double read. |
| T-177-08 | high | closed | Queue collects only selected metadata; body and log content is excluded. |
| T-177-09 | high | closed | Fixed read-only GraphQL invocation. |
| T-177-10 | high | closed | Archived 8/9 and REL-10 breach checks plus exact-argument committed-base ancestry. |
| T-177-11 | medium | closed | Public command arguments match supported task options; guide and sync checks pass. |
| T-177-12 | high | closed | Active guidance checks preserve historical verdicts. |
| T-177-13 | medium | closed | Explicit workstream command and duplicate-command checks. |
| T-177-14 | high | closed | Cross-stream acceptance now uses full decision metadata, strict queue validation, digest and row checks, and exact private replay. Fourteen adverse fixtures pass. |
| T-177-15 | high | closed | Independent goal verification passed; registered completion and installed STATE/ROADMAP/state-contract writers published the final discussion178 action. Real-format fixtures, strict state validation, command equality, requirement-surface consistency and protected-source preservation passed. |
| T-177-16 | high | closed | Attestation, partition, row, base-tree and reviewed-selection checks; verified overlay reversal. |
| T-177-17 | high | closed | Probe validates installed GSD paths internally but projects only runtime identity and safe metadata; errors expose program/stage and bounded exit/signal/error class, with raw stderr, exception text, arguments, absolute paths and payloads excluded. Sentinel tests pass. |
| T-177-18 | high | closed | Fixed canonical HTTPS URL fetches the proof-listed exact SHA without updating refs/FETCH_HEAD; real Git fixtures pass success, nonzero, mismatched tree, spawn-error and signal cases, and preserve checkout/index/worktree. |
| T-177-SC | high | closed | Dependency graph and lockfile unchanged; existing cached locked package was audited against inner and outer checksums. |

No accepted risks. The medium comparisons remain open and explicitly retained; they are not equivalent-reader or retirement claims.

## Audit trail

| Date | Total | Closed | Open | Blocking | Result |
|---|---|---|---|---|---|
| 2026-10-12 | 19 | 12 | 7 | 5 | Independent ASVS1 audit; repair required. |
| 2026-10-12 | 19 | 16 | 3 | 1 | Scoped repair checks closed T-177-03/05/17/18. T-177-15 remains pending final publication recheck; T-177-04/06 remain unproven medium comparisons. |

## Interim publication

The installed locked STATE writer and platform ROADMAP writer were exercised in a temporary fixture, including wrong and duplicate anchor rejection, before publication. Current handoffs and the installed state-contract projection agree on resuming Phase177 execution for remaining verification. The prior text is retained in workstream history/phase177-verification-handoff-20261012.md. The recovery source, HEAD, branch, index bytes and all eighteen frozen Phase176 files match the execution baseline. No requirement or phase completion is claimed by this interim publication.

## Independent security recheck

The independent auditor verified all five repaired high controls against actual implementation and proof. Seventeen of nineteen controls are closed; two medium historical-reader comparisons remain open without risk acceptance or equivalence claims. The configured high threshold has zero blocking threats. Final handoff equality and protected-source preservation must be checked again after independent goal verification and the phase transition.

| 2026-10-12 | 19 | 17 | 2 | 0 | Targeted independent ASVS1 recheck passed the blocking gate. |

## Final handoff publication

After independent verification passed, the registered phase completion writer advanced to Phase178. Final installed-writer fixtures rejected wrong and duplicate anchors and wrong phase; the prior active wording was preserved verbatim in workstream history. STATE, ROADMAP and the installed state-contract projection agree on discussion178. Last completed phase is177; MAINT-03/05/06 checkboxes and traceability agree, while MAINT-07/08 remain pending. Strict state validation passed with zero warnings. The recovery HEAD, branch, index, all1296 nonplanning source paths and all18 frozen Phase176 files match the execution baseline, including the complete path roster. Final independent report refresh will inspect this publication.
