---
phase: "177"
slug: "maintenance-and-queue-reconciliation"
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-10-12"
---

# Phase 177 — Validation Strategy

Validation audit update (2026-10-12): all 16 task behaviors for MAINT-03/05/06 have automated checks recorded, and focused suites were rerun during this audit. The task map below records the current evidence and its limits. Phase177 remains in verification; this map does not mark requirements complete or claim Phase178 final-source/CI proof.

## Test Infrastructure

| Property | Value |
|---|---|
| Framework | Existing ExUnit/Mix, Node built-in tests and stdlib artifact checks |
| Owners | `mix.exs`, `script/repository_verification_stages.json`, phase-local evidence |
| Supported-path focused check | `mix test test/crosswake/release_candidate/plan93_candidate_read_test.exs test/crosswake/release_candidate/companion_receipt_test.exs test/crosswake/release_candidate/evidence_gate_test.exs test/mix/tasks/crosswake_release_candidate_test.exs test/mix/tasks/crosswake_release_status_test.exs` in the qualified clone |
| Doc projection check | `mix crosswake.docs.sync --check` |
| Workflow integrity check | `elixir script/check_release_workflow_integrity.exs` |
| Complete repository verification | Existing `script/verify_repository.sh`, reserved for Phase178's exact clean commit |
| Runtime | Not measured by discussion/research; calibrate during execution rather than invent a duration |

## Sampling Rate

- After each source behavior change: exercise its actual supported and denied entry points, historical-reader fixtures where affected, and before/after source/artifact state.
- After each queue artifact write: validate pagination/count/identity/action coverage and privacy against the same observation; refresh drift before sign-off.
- After active guidance changes: run affected existing docs/workflow/ancestry checks and resolve active commands/paths without invoking spent launches.
- Before Phase177 verification: validate all MAINT-03/05/06 evidence and unchanged historical meaning. The complete final-source/hosted CI gate remains Phase178.

## Requirement Verification Map

New phase-local checkers are created before their first live use: 177-01 Task 1 creates the maintenance checker, 177-08 Task 1 creates the source binder and real-subprocess fixtures, 177-04 Task 1 creates the queue collector/checker, 177-06 Task 1 creates the active-guidance checker, and 177-07 Task 1 creates the final acceptance checker. Their tests require positive and adverse cases through real owner paths; a zero-case pass is invalid. The queue's actual `gh` subprocess return shape and installed GSD workspace init shape are fixture contracts.

| Requirement | Behavior | Test type | Command/assertion | Status |
|---|---|---|---|---|
| MAINT-03 | Every Phase176 row and candidate is classified with caller/replacement/preservation basis | 177-01 Tasks 1–2; T-177-01/02 | `node --test .../177-evidence/check_maintenance_review.test.mjs` then `node .../177-evidence/check_maintenance_review.mjs --complete .../177-evidence/maintenance-review.json`; compare actual Phase176 `rowId` set and nonzero behavior cases | Planned; checker created in 177-01 Task 1 |
| MAINT-03 / MAINT-06 | Qualified source and exact patch delivery | 177-08 Tasks 1–2; T-177-16/17/18 | `node --test .../177-evidence/qualify_source.test.mjs`; per-verb parser fixtures accept exact planned probe/tracer/default-complete/three owner argv and deny duplicate, unknown, wrong-verb and positional input; sealed archive `0400` input read succeeds with bytes/mode/mtime unchanged and broader modes fail; installed `query init.new-workspace` probe; supported GSD clone; canonical remote exact-SHA fetch into clone with attested commit/tree assertion; complete `qualify` with adverse real-Git, partition, conflict and privacy fixtures | Planned; producer created in 177-08 Task 1 before source consumers |
| MAINT-03 | Generic supported tasks stay usable; Plan93/mirror retired modes deny before effects | 177-02/03 Tasks 1–2; T-177-03/05 | In qualified clone, focused `mix test test/crosswake/release_candidate/plan93_candidate_read_test.exs test/crosswake/release_candidate/companion_receipt_test.exs test/crosswake/release_candidate/evidence_gate_test.exs test/mix/tasks/crosswake_release_candidate_test.exs test/mix/tasks/crosswake_release_status_test.exs`, then Plan03 mirror task/focused suite and `elixir script/check_release_workflow_integrity.exs`; status/candidate/receipt/gate actual-entry positive and denied assertions | Planned; Plan08 binding is an executable dependency |
| MAINT-03 | Historic reader preserves receipt schema and original verdict | 177-02/03 Task 1; T-177-04/06 | Exercise actual retained/replacement inspectors against named preserved local artifacts; assert no credential/network/write side effects and compare original verdict | Planned; exact source binding precondition |
| MAINT-05 | Current issues and PRs have separate exhausted pages and one actionable row each | 177-04 Tasks 1–2; T-177-07/08/09 | `node --test .../177-evidence/check_queue_inventory.test.mjs` and `node .../177-evidence/check_queue_inventory.mjs .../177-evidence/queue-inventory.json` after final roster refresh | Planned; checker created in Task 1 |
| MAINT-05 | Access failure, malformed pages, duplicate/colliding identities, null and drift cannot pass | 177-04 Task 1; T-177-07 | Actual fake-`gh` subprocess fixtures exercise status/stdout/stderr and full API result shape; successful exhausted zero/zero is the only complete empty case; kind/number sort stable | Planned; all three MAINT-05 edge probes explicitly covered |
| MAINT-06 | Active PROJECT/continue-here/STATE/ROADMAP and public commands resolve without changing history | 177-05/06/07 Tasks 1–2; T-177-10/11/12/13/15 | `mix crosswake.docs.sync --check`, `elixir script/check_release_workflow_integrity.exs`, named guide tests, runbook ancestry with actual three arguments, `node .../177-evidence/check_active_guidance.mjs --active`, `node .../177-evidence/check_phase_acceptance.mjs --complete .../177-evidence/phase-acceptance.json`, and `gsd-tools state validate --strict --ws=quality-ratchet-release` | Planned; source check isolation and registered handoff required |

## Wave 0 Requirements

- [ ] 177-08 Task 1 probes the installed GSD workspace shape, creates the binder/tests, runs the supported clone workflow and qualifies one live selected row; Task 2 validates every applicable row and exact cumulative private patch handoff before 177-02/03/05.
- [ ] 177-01 Task 1 creates a checked Phase176 row/behavior evidence path; Task 2 validates the full actual rowId set.
- [ ] 177-04 Task 1 creates current-queue collector/checker and actual-subprocess adverse fixtures; Task 2 collects/refreshed live metadata and validates every action row.
- [ ] 177-06 Task 1 creates active-guidance checker and fail-first fixtures independently of source and queue; 177-07 Task 1 creates cross-stream acceptance checker. Parent GSD writer publishes the singular workstream handoff for 177-07 Task 2 final check.
- [ ] Identify/create retirement/inspection fixtures only for actual selected behavior changes; reject zero exercised required cases.

No new framework/dependency, permanent reconciliation CI lane or replacement verification runner is selected.

## Edge and Prohibition Probe Resolution

- MAINT-05 adjacency: `(kind, number)` is the identity. Issue `#N` and PR `#N` are distinct; a duplicate within the same kind is an error. A link between them is relationship metadata, not another roster row. Automated in 177-04 Task 1.
- MAINT-05 empty: zero issues and zero PRs count as complete only after both successful, fully exhausted connections and a consistent final refresh. Null, denied, malformed and incomplete results remain blocked. Automated in 177-04 Task 1.
- MAINT-05 ordering: deterministic kind then numeric number order; equal values across kinds stay separate, and any remaining tie uses node ID. Automated in 177-04 Task 1.
- MAINT-03 and MAINT-06 remain **unclassified edge-probe assumptions** from `177-EDGE-PROBE.json`. They are not silently dismissed: execution must inspect selected mode boundaries and active-pointer variants, record any newly applicable edge and test it before completion. Their current automatable invariants are in the requirement table.
- Canonical must-not boundaries are the CONTEXT/AGENTS prohibitions: no remote queue writes or release authority transfer, no raw adopter/private recovery material in artifacts, no old attempt reactivation, no historical verdict rewrite, and no source/Mix mutation in the recovery checkout. These are wired into 177-01 through 177-08 actions and checks. No new prohibition descriptor or invented test path is asserted.

## Security acceptance

ASVS Level 1 is the floor. High severity controls T-177-01/02/03/05/07/08/09/10/12/14/15/16/17/18 block acceptance if their named adverse fixture or actual-entry check fails; plan task acceptance criteria cite the corresponding identifiers. Medium controls also retain their plan-specific automated checks. `T-177-SC` is the installed GSD reserved shared supply-chain control, repeated by convention but not a distinct threat: no package install is planned, so no install step can bypass an audit. Plan177-07's acceptance checker reads the unique plan control IDs and linked command results, and rejects an untested high-severity mitigation rather than treating a register label as proof.

## Manual-Only Verifications

All phase assertions are automated. Unavoidable credentials, external trust or delivery authority can block an operation; they do not replace assertions with human UAT. No `checkpoint:human-verify` is planned.

## Validation Sign-Off

- [x] All 16 phase tasks mapped to MAINT-03/05/06 and behavioral checks.
- [x] Every task has an automated check or a recorded dependency check.
- [x] No three consecutive tasks lack automated feedback.
- [x] Phase-local checkers and fixtures cover planned targets; no watch-mode commands.
- [x] Read-only queue, private-source, history, and privacy boundaries have automated evidence.
- [x] Plan07 recorded a matched live double-read and validated inventory; this audit did not repeat the remote read.
- [x] Behavioral coverage is validated with the limits above; phase closeout and final-source CI remain separate gates.

**Approval:** Validation coverage reviewed and run 2026-10-12; conditional source-history limits and outstanding Phase178 proof are recorded above.

## Validation Audit 2026-10-12

| Metric | Count |
|---|---|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |
| Tasks audited | 16 |
| Focused behavioral tests passed | 52 |

## Post-completion guidance checks — 2026-10-12

The parent ran all eight updated guidance fixtures and all fourteen acceptance fixtures after final publication;22/22 passed. The live guidance checker resolves Phase178 discussion only after Phase177 completion and its passed27/27 report are present; false completion, missing proof, mismatched/duplicate commands, softened REL-10 and a missing parked gate fail. Strict workstream state validation passed without warnings. STATE, ROADMAP and the installed state-contract projection expose the same next action, and both requirement surfaces agree. The earlier full acceptance and52-test audit remain dated pre-transition evidence; no Phase178 final-source or hosted-CI claim is added.
