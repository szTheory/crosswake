# v24.0 cross-phase integration audit

The integration checker traced six connections and five maintenance flows. All are wired after the root resolved the two follow-up observations below. No application API or rendered UI was added in this milestone.

| Connection | Consumer and evidence | Verdict | Requirements |
|---|---|---|---|
| Capture, restore and rendering → downstream inventory review | `176-evidence.mjs` capture/verify/audit/render (302/463/812/1144); `check_maintenance_review.mjs:450` reads the actual Phase176 inventory; `check_phase_acceptance.mjs:286` reads its consumers. 119 rows, 170 restored units. | WIRED | MAINT-01/02/04 |
| Retained rows → source reconciliation → exact candidate | Phase177 preserves 70 source and 49 outside-source rows, 30 conflicts and three owner bundles. `prepare_candidate.mjs:327` validates Phase177 binding/semantic selection before the eight-path candidate. | WIRED | MAINT-01/02/03/04/07 |
| Dated queue → per-object accountability → acceptance | `check_phase_acceptance.mjs:10/118/291` imports, calls and reads the queue validator; actual double-read collector exhausts issues and PRs separately. Audit supplement now covers 20 issues and 4 PRs. | WIRED | MAINT-05 |
| Supported release entries → public guidance → existing verifier | Actual status/candidate/receipt/gate positive/denied task tests and guide tests; all 78 legacy selectors deny before effects, with all modes retained. | WIRED | MAINT-03/06/07 |
| Candidate → private local proof + hosted checkout/policy → exact OID acceptance | `local_proof.mjs:86`, `ci_evidence.mjs:473`, `proposal_delivery.mjs:203`, and `join_proof.mjs:8` consume the same bound candidate; join calls the local collector, validates hosted graph and current read barrier. | WIRED | MAINT-07/08 |
| Preservation and historical verdicts → successive workstream handoffs | Phase176 post-writer private audit passed after its final sign-off. Phase177/178 protections preserve recovery/history. STATE, ROADMAP and state.json expose one current action; adopter remains parked and REL-10 breached. | WIRED | MAINT-01/02/04/06 |

| End-to-end maintenance flow | Result |
|---|---|
| Capture changed units → private materialized restore → row dispositions → preserved downstream selection | Complete |
| Supported command → documented inputs → positive/denied proof → complete repository verifier | Complete |
| Exhausted remote roster → dated actionable local inventory → refresh including new maintenance PR | Complete |
| Eight-path candidate → scoped delivery → runner merge OID → local full command → exact hosted/local join | Complete |
| Phase completion → protected original records → coherent current scoped handoff | Complete |

## Findings and root reconciliation

1. The checker initially could not locate the mandatory Phase176 post-signoff audit in public records. Root inspected the existing private sidecar: pass at **2026-10-12T03:24:38.324Z**, after the 03:20:42 validation sign-off and every Phase176 file's modification time. Active capture/source match, 14 owned writer deltas, and immutable manifest/proof attestations validate. All 1,677 historical files remain byte-identical. This finding is **resolved**, not waived. See `phase176-audit-resolution.json`. The old audit is phase-closeout evidence, not a promise that its Phase176-only writer ledger accepts future phases; no sidecar was overwritten.
2. The Phase177 dated queue predates PR #238. A fresh audit double-read found exactly one addition, PR #238, with no removals or changes to the prior 23 objects. The supplement records a current maintainer action: review the maintenance diff/audit and retain the PR until a separately scoped merge decision and fresh candidate checks. This coverage finding is **resolved**. Original queue and delivery snapshots are unchanged.
3. Phase177 Plan03 says MAINT-03 remains pending for historical-reader comparison; later phase verification/closeout satisfies the conditional requirement by proving supported paths and retaining every uncertain mode. Two comparisons remain unproven. This chronology is recorded as debt, with no equivalence or retirement claim.
4. The six-file Phase177 fixture suite returned **51/55** today. Four failures are in the historical guidance fixtures that require Phase178 awaiting discussion; current STATE correctly reports Phase178 complete. The other five Phase177 suites passed **47/47**. The fixtures and old acceptance are one-time evidence for their original epoch; they are not a permanent current-state gate. This is retained artifact debt, not a broken current handoff.

## Fresh checks and evidence limits

The checker ran Phase176 35/35, Phase177 51/55 (four stale-epoch failures), and Phase178 82/82. Across all three raw suites that is 168/172; excluding the entire eight-case historical guidance file gives 164/164 applicable fixtures. Do not describe the complete historical Phase177 suite as passing today. Phase178's earlier 90/90 prior-phase regression ran all seven files against an explicitly reconstructed original handoff fixture; it is dated evidence, not a current-state claim.

The audit inspected retained source-bound repository proof and the accepted live join; it did not rerun `script/verify_repository.sh --all` or the live policy join. Final retained proof is local 9/9 and hosted 48 required successes: 46 merge checkouts, one head-only proof and one source-less umbrella, plus one declared advisory row. Governed merge OID is `f2d8875ee52d9679157c73b4a701b510ee612cb8`, head is `3e8a4b2601b542323edfd6053f25e56c67873b47`, tree is `27f4073039b4dd976492127549603a76ce22499b`, run 38322827152 attempt 1. A current audit queue read matched the unchanged head and check metadata.

Proof is warm-cache in an independent clone. Two earlier full-run failures remain undiagnosed because assertion text was not retained. No merge, tag, publication, archive movement, capture retirement or delivery replay occurred.

## Requirement integration map

MAINT-01/02/04 connect inventory/recovery/policy to downstream source selection and preservation. MAINT-03 connects retained mode decisions and supported entries to guidance/proof. MAINT-05 connects the collector, dispositions and audit refresh. MAINT-06 connects commands/history to current handoffs. MAINT-07/08 connect the exact candidate, complete local command, hosted runner and final join. All eight have integration touchpoints; none is orphaned or unwired.
