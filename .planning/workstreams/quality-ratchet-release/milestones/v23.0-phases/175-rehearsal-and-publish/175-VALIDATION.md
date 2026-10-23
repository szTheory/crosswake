---
phase: "175"
slug: "rehearsal-and-publish"
status: validated
nyquist_compliant: false
wave_0_complete: false
updated: "2026-10-11T19:58:54.127798+00:00"
---

# Phase 175 — Validation Results

Plan 148 completed the authorized release sequence and automated reconciliation. This is measured release coverage; an exhaustive Nyquist audit of all 148 historical plans has not run. Earlier validation rows remain in `175-VALIDATION-ARCHIVE-PRE-PLAN148-CLOSEOUT.md`, whose exact hash is recorded with the archived input snapshots.

## Actual Commands and Runs

| Contract | Check or operation | Result / retained file |
|---|---|---|
| Mirror prerequisite | One exact v0.2.6 tag repair and independent readback | TAG_VERIFIED; preserved Plan 148 tag operation/audit. No repeat of the stopped attempts. |
| Core exact candidate CI | PR #232, run 38152560619 | 49/49 successful checks. |
| Core safe rehearsals | Hex 38154895539, iOS 38154903768, Maven 38154909396 | All successful; no external publication; Maven VALIDATED and DROP. `evidence/175-plan148-core0211-rehearsals-verified.json`. |
| Canonical core receipt | Hosted 38155123327, artifact 11708476594 | 13 PASS checks, proof hashes and bound identity match. `evidence/175-plan148-core0211-receipt-verification.json`. |
| Core exact authorization and merge | Fresh pre-merge/final shared capture and one normal protected merge | Exact two parents, tree, trailer and runbook ancestor; binding consumed once. Core0211 final/merge/postmerge files. |
| Core ordinary publication | 38155320492 | Three guarded publishers plus iOS generated-app Xcode build, Android full generated build/debug lint and exact-public passed. Six-child COMPLETE. |
| Public coordinates | Direct Hex/iOS/Maven requests | Three HTTP 200 results and exact 0.2.11 coordinates. Core0211 registry observation. |
| Public package consumers | Same ordinary exact-public artifact | Six package rows, five profiles, two dependency-install passes each and negative controls passed. Core0211 public-proof verification. |
| Shared path mutations | Tracked guard/receipt/path suite; approved workflow scanner | 94 tests, zero failures; 98/98 controls. `evidence/175-plan148-final-forward-controls-verification.json`. |
| Grouped repair #233 | Full tracked suite; focused guide/guard tests; inventory; actionlint/format; revised CI 38163135946 | 2,065 tests/0 failures/78 excluded; 100 focused/0; 230 exact sites; all 49 CI success. V2 source match and local-verification files. |
| Companion checkout negative | Five publisher jobs with missing/1/2 fetch depth, plus real Git shallow/full reproduction | All 15 mutations rejected. Actual depth 1 ancestry fails, unchanged head/full history with 3,825 commits passes. `evidence/175-plan148-companion-history-real-git-proof.json`. |
| Fresh companion exact CI | PR #235, run 38165160468 | All 49 checks passed. Independent six-row CI/Hex artifact equality. Companion-next ci/hex verification. |
| Fresh companion receipt and separate gate | Own hosted receipt; actual approved canonical producer rebuild; six-condition pre/final/postmerge captures | Four source hashes match, separate exact generic companion authorization, one protected merge. Companion-next receipt/gate/merge/postmerge files. |
| Companion ordinary public proof | 38167555514, direct Hex | Guard, publisher and same-run public clean-room doctor success; HTTP 200 parsed 0.1.2. Companion-next publication and registry files. |
| Installer source reconciliation | PR #237, exact CI 38168254714, merge/proposal-only | 49 CI success; ten actual ordered installer/doctor pairs; eight publishers skipped, no new publication. Matrix-installer artifacts. |
| Historical breach accounting | Canonical current verdict and requirement/state consistency assertions | SC-1/REL-10 BREACHED; at most 8/9; Phase 175 active. Reconciliation assertions recorded separately. |

## Plan Contracts and Route Replacement

Plans 43–48 define cross-path controls, rehearsals, protected core merge, same-run proof, separate companion and truthful reconciliation. Their acceptance contracts were applied inside Plan 148. Unused standalone execution routes remain superseded, not counted as executed. PR #115's consumed 0.1.1 attempt is stopped before Hex. Fresh PR 235/0.1.2 uses a new exact generic package gate, with `authorization_run_id: null`, rather than PR #115's special leg3 binding.

## Limits

No recovery publication, uncertain write retry, administrative bypass, root staging/commit/branch switch/worktree, physical device assertion or parked adopter work occurred. Earlier partial releases and all consumed bindings remain preserved. Historical SC-1 cannot be made compliant by later passing runs.
