---
phase: "178"
slug: clean-checkout-and-final-ci
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-10-12"
---

# Phase 178 — Validation Strategy

Execution coverage audited after all five plans completed. The five behavioral evidence suites passed 82/82, and the final live acceptance joined nine local stages with all 48 required CI checks. Reuses discussion research and existing source owners. Exact-source proof and the authorized ordinary push/PR delivery are retained; requirement completion remains owned by the phase verifier and workstream owner. Five plans contain eleven tasks in four waves: 178-01; 178-02 and 178-03; 178-04; 178-05. The private Phase177 handoff root is passed through immutable candidate-binding.json and disjoint atomic local-proof-binding.json/ci-policy-binding.json, then joined by Plan04; no pointer is a public artifact.

## Test Infrastructure

Use Node's built-in node:test for phase-local evidence parsing/joins. Existing ExUnit, Playwright, SwiftPM and hermetic Android checks remain owned by the selected source's nine-stage manifest. No framework or dependency installation is selected.

- Quick contract check: `node --test test/js/repository_verification.test.mjs` in the qualified independent source.
- Full source gate: `script/verify_repository.sh --all` from a fresh exact-commit checkout with the existing private retained run-root mechanism.
- CI structure: `python3 script/check_ci_leaf_manifest.py --self-test` plus the selected workflow's existing production graph check.
- Local parser positive fixture: spawn the selected source's actual exported `runVerification({selection: "all"})` through a temporary Node harness with supported injection, capture the real subprocess output/exit and its nine result lines, eight executed-stage logs, preflight summary and two NUL status files. The isolated format fixture sets `enforceArtifactPolicy:false`; the production `script/verify_repository.sh --all` keeps its complete artifact policy.
- Policy contract: read target-base branch protection required checks and effective active branch rules, including applicable repository and inherited organization rulesets; a successful empty effective-rule response is explicit evidence of no applicable rules at that observation. Missing or inaccessible routes block.
- Final join: `178-evidence/join_proof.mjs --check` consumes actual retained verifier outputs and complete observed CI metadata, never a hand-authored passed flag. Plan 178-05 Task 3 creates it.

## Sampling Rate

Run focused evidence regressions after each evidence implementation task. Before each expensive complete run, probe manifest prerequisites and exact versions. Never overlap runs sharing host databases/build/output roots. Focused stage runs diagnose faults; one fresh complete invocation is the MAINT-07 gate. Any source repair invalidates final proof and requires another complete invocation on the new binding. Runtime for full verification is environment-dependent; use existing per-stage timeouts, with short parser/unit checks between tasks. No watch mode.

## Per-Task Verification Map

Commands below identify the completed producing tasks and their retained evidence. Consumed preparation/delivery operations are historical and must never be replayed. An invocation of `script/verify_repository.sh --all` runs with cwd set to the independent exact-commit proof clone and the facade's `CROSSWAKE_REPOSITORY_RUN_ROOT`/`CROSSWAKE_REPOSITORY_CAPTURE_ROOT` set to its validated private roots. Phase-local commands run from the workstream checkout with `CROSSWAKE_178_PRIVATE_HANDOFF_ROOT` exported. Every supplemental Git status, index-hash and ignored-path command in Plans02/05 uses `GIT_OPTIONAL_LOCKS=0` so measuring the index cannot refresh it. The final accepted invocation preserved actual raw index bytes, staged entries, HEAD/tree and NUL status.

| Task | Requirement | Automated command | Fails when | Status |
|---|---|---|---|---|
| 178-01 T1 | MAINT-07 | `node --test .planning/workstreams/quality-ratchet-release/phases/178-clean-checkout-and-final-ci/178-evidence/prepare_candidate.test.mjs` | Nonzero or real Git fixture accepts wrong base, altered bundle, missing/extra path or dirty clone | Passed; see producing plan SUMMARY and retained evidence |
| 178-01 T2 | MAINT-07/08 | `node .planning/workstreams/quality-ratchet-release/phases/178-clean-checkout-and-final-ci/178-evidence/prepare_candidate.mjs --prepare` | Nonzero, eight-file byte mismatch under the execution refinement, wrong base/tree or unclean independent proof clone | Passed; see producing plan SUMMARY and retained evidence |
| 178-01 T2 | MAINT-07/08 | `node .planning/workstreams/quality-ratchet-release/phases/178-clean-checkout-and-final-ci/178-evidence/prepare_candidate.mjs --check` | Nonzero or private/public candidate identity mismatch | Passed; see producing plan SUMMARY and retained evidence |
| 178-02 T1 | MAINT-07 | `node --test .planning/workstreams/quality-ratchet-release/phases/178-clean-checkout-and-final-ci/178-evidence/local_proof.test.mjs` | Nonzero or parser accepts self-test as full run, fabricated summary, missing one of eight stage logs, changed source/status, mutating supplemental snapshot or raw-data leak | Passed; see producing plan SUMMARY and retained evidence |
| 178-02 T2 | MAINT-07 | `script/verify_repository.sh --all` | Nonzero, absent/wrong-version prerequisite, missing/blocked stage, drift or mutation | Passed; see producing plan SUMMARY and retained evidence |
| 178-02 T2 | MAINT-07 | `node .planning/workstreams/quality-ratchet-release/phases/178-clean-checkout-and-final-ci/178-evidence/local_proof.mjs --collect` | Nonzero or retained logs/status/source identity incomplete | Passed; see producing plan SUMMARY and retained evidence |
| 178-03 T1 | MAINT-08 | `node --test .planning/workstreams/quality-ratchet-release/phases/178-clean-checkout-and-final-ci/178-evidence/ci_evidence.test.mjs` | Nonzero or wrong-attempt, missing-page/leaf, wrong checkout, unauthorized skip, branch-protection/effective-rules read failure or wrong context/integration accepted | Passed; see producing plan SUMMARY and retained evidence |
| 178-03 T2 | MAINT-08 | `python3 script/check_ci_leaf_manifest.py --self-test` | Nonzero or selected-source graph validator fails | Passed; see producing plan SUMMARY and retained evidence |
| 178-03 T2 | MAINT-08 | `node .planning/workstreams/quality-ratchet-release/phases/178-clean-checkout-and-final-ci/178-evidence/ci_evidence.mjs --contract` | Nonzero or either policy source, workflow, app/integration/context data incomplete; failed rules read mistaken for none | Passed; see producing plan SUMMARY and retained evidence |
| 178-04 T1 | MAINT-08 | `node --test .planning/workstreams/quality-ratchet-release/phases/178-clean-checkout-and-final-ci/178-evidence/proposal_delivery.test.mjs` | Nonzero or local production-adapter fixture accepts drift, duplicate delivery or private leak | Passed; see producing plan SUMMARY and retained evidence |
| 178-04 T1 | MAINT-08 | `node .planning/workstreams/quality-ratchet-release/phases/178-clean-checkout-and-final-ci/178-evidence/proposal_delivery.mjs --prepare` | Nonzero or exact concrete card absent | Passed; see producing plan SUMMARY and retained evidence |
| 178-04 T2 | MAINT-08 | `node .planning/workstreams/quality-ratchet-release/phases/178-clean-checkout-and-final-ci/178-evidence/proposal_delivery.mjs --deliver` | Missing scoped authority/credential, nonzero, drift or uncertain delivery without read reconciliation | Passed; see producing plan SUMMARY and retained evidence |
| 178-05 T1 | MAINT-08 | `node .planning/workstreams/quality-ratchet-release/phases/178-clean-checkout-and-final-ci/178-evidence/ci_evidence.mjs --collect` | Nonzero, incomplete attempt/job/check pages, absent observed checkout, unauthorized skip or stale branch-protection/effective-rules policy | Passed; see producing plan SUMMARY and retained evidence |
| 178-05 T2 | MAINT-07/08 | `script/verify_repository.sh --all` | Nonzero, missing/blocked stage, drift, mutation or wrong runner-tested OID | Passed; see producing plan SUMMARY and retained evidence |
| 178-05 T2 | MAINT-07/08 | `node .planning/workstreams/quality-ratchet-release/phases/178-clean-checkout-and-final-ci/178-evidence/local_proof.mjs --collect` | Nonzero or final retained proof cannot bind to observed merge OID, lacks eight executed-stage logs/preflight summary or changes index through supplemental reads | Passed; see producing plan SUMMARY and retained evidence |
| 178-05 T3 | MAINT-07/08 | `node --test .planning/workstreams/quality-ratchet-release/phases/178-clean-checkout-and-final-ci/178-evidence/join_proof.test.mjs` | Nonzero or tree-equal/SHA-different, old-attempt, missing-output or private leak accepted | Passed; see producing plan SUMMARY and retained evidence |
| 178-05 T3 | MAINT-07/08 | `node .planning/workstreams/quality-ratchet-release/phases/178-clean-checkout-and-final-ci/178-evidence/join_proof.mjs --check` | Nonzero or final local/hosted commit, run/attempt, graph or live policy disagrees | Passed; see producing plan SUMMARY and retained evidence |

## Wave 0 Requirements

- Implement only necessary small phase-local evidence scripts/tests in the named producing tasks; later plans depend on them.
- Ground parser and collector fixtures in dependency return shapes and actual temporary subprocess outputs before any remote write proposal.
- Tests must exercise behavior and wrong-source/false-green cases, not merely check strings or mirror implementation.
- The three planned coverage flags are resolved by the accepted final local collector, complete CI graph/attempt negative controls, and exact-OID/current-policy join. All82 behavioral tests and the actual same-source live join passed; no coverage gap remains. Any later source, attempt or policy drift invalidates acceptance.

## Manual-Only Verifications

All acceptance assertions and UAT are automated. A concrete remote maintenance proposal may need separately scoped approval or unavoidable credentials. This is authority for delivery, not proof of verification. Complete independent local work first; accept plain-language allow/hold only for the displayed operation and do not replay uncertain delivery. No merge, release, publication or archive removal is selected.

## Validation Sign-Off

- [x] Every task has an automated verification command with observable failing direction and a named producing task where needed.
- [x] No three consecutive tasks lack automated feedback.
- [x] All future command targets have a named producing task or already exist in the attested source.
- [x] Both requirements and all 25 decisions have executable coverage in the five completed plans; fresh negative fixtures and actual retained proof passed.
- [x] Independent plan checker passed; all five evidence suites and final source join passed.

Approval: validated 2026-10-13. No missing or partial automated coverage found. The exact local run is final-17805-all-20261013T012626120Z at f2d8875ee52d9679157c73b4a701b510ee612cb8; hosted run 38322827152 attempt 1. Earlier failed attempts remain history, including assertions whose raw output was not retained. No tests were disabled or assertions relaxed. No Git staging or commit was made under the recovery-checkout restriction.

## Validation Audit 2026-10-13

| Metric | Count |
|---|---|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |
