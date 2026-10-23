# Phase 178 planning audit

Planning only, 2026-10-12. Five executable plans, eleven tasks, four waves. No source/build/remote operation was performed. The selected source analog is the attested read-only independent clone at `/private/tmp/crosswake-177-source/crosswake`; execution creates new independent delivery and proof clones. Research and Phase178 discussion were reused; no new ecosystem research or dependency was selected.

## Artifacts this phase produces

| Producer | Created symbol, flag or file | Consumer |
|---|---|---|
| 178-01 T1 | `prepare_candidate.mjs` `--self-test`, `--prepare`, `--check`; `CROSSWAKE_178_PRIVATE_HANDOFF_ROOT`, `CROSSWAKE_178_DELIVERY_ROOT`, `CROSSWAKE_178_PROOF_ROOT` | 178-01 T2 and 178-02 |
| 178-01 T2 | `candidate-source.json`; immutable owner-private `candidate-binding.json` with exact local commit/tree | 178-02, 178-03, 178-04, 178-05 |
| 178-02 T1 | `local_proof.mjs` `--self-test`, `--collect`; `CROSSWAKE_178_PROOF_KIND=preliminary|final` | 178-02 T2, 178-05 T2 |
| 178-02 T2 | `preliminary-local-proof.json`; atomic owner-private `local-proof-binding.json` with retained run root | 178-04, 178-05 |
| 178-03 T1 | `ci_evidence.mjs` `--self-test`, `--contract`, `--collect` | 178-03 T2, 178-05 T1 |
| 178-03 T2 | `ci-contract.json`; atomic owner-private `ci-policy-binding.json` with branch-protection and effective-rules pointers | 178-04 and 178-05 |
| 178-04 T1 | `proposal_delivery.mjs` `--self-test`, `--prepare`, `--deliver`; `maintenance-proposal.json`; private `delivery-binding.json` | 178-04 T2 and 178-05 |
| 178-04 T2 | `delivery-observation.json` or one exact authority checkpoint | 178-05 |
| 178-05 T1/T2 | `hosted-ci-proof.json`, `final-local-proof.json`; private raw job/run logs | 178-05 T3 |
| 178-05 T3 | `join_proof.mjs` `--self-test`, `--check`; `final-acceptance.json` | independent phase verification and workstream handoff |

All phase-local programs use the standard library. Their publicly committed JSON outputs contain only allowlisted IDs, commands, versions, counts, outcomes, safe causes and next actions. Absolute private roots, bundle material, raw subprocess output, NUL status paths and sensitive digests travel only through the owner-private 0700/0600 handoff. Plan01 writes immutable candidate-binding.json. Same-wave Plans02/03 read it and atomically write disjoint local-proof-binding.json/ci-policy-binding.json; neither writes shared mutable state. Plan04 joins all three after Wave 2, rechecks public commit/tree identities, then writes its own delivery-binding.json. Plan05 reads these pointers and checks them against the live source/run. No pointer is inferred from a summary.

## Dependency graph and reachability

`178-01 -> {178-02, 178-03} -> 178-04 -> 178-05`. Plans 02 and 03 have disjoint public and private files and may execute in the same wave. The Plan01 tracer uses actual Git subprocesses to replay a one-path bundle into a local commit and clean clone; its expansion requires all six production paths. Plan02's full facade is the user entry point for MAINT-07. Plan04's exact non-release proposal is the entry to hosted CI. Plan05 observes its run, fetches the actual runner-tested immutable commit and repeats the same full local command. No source artifact is unreachable from a maintainer action or fixed read/write route.

## Multi-source coverage audit

| Source | Item | Plan | Status |
|---|---|---|---|
| GOAL | Reproduce final-source verification without dirty recovery checkout | 01, 02, 05 | COVERED |
| REQ | MAINT-07 complete existing verifier, exact clean commit, before/after Git state | 01, 02, 05 | COVERED |
| REQ | MAINT-08 green hosted CI on final exact runner-tested commit | 03, 04, 05 | COVERED |
| RESEARCH | Phase177 private bundle/replay, six-file selection, base renewal | 01 | COVERED |
| RESEARCH | Exact manifest versions, lock-bound setup, nine result lines/eight executed-stage logs, generated/ignored outputs, retained private logs and nonmutating supplemental snapshots | 02, 05 | COVERED |
| RESEARCH | Existing classifier/46 leaves/control/umbrella, branch protection plus effective applicable repository/inherited rulesets, job checkout provenance, complete pagination | 03, 05 | COVERED |
| RESEARCH | Concrete proposal, authority boundary, bounded repair and source rerun | 04, 05 | COVERED |
| CONTEXT | D-01 delegated coherent recommendation; no questionnaire | 01 | COVERED |
| CONTEXT | D-02 six Phase177 outputs | 01, 04 | COVERED |
| CONTEXT | D-03 protected recovery checkout | 01, 04 | COVERED |
| CONTEXT | D-04 source binding and base renewal | 01 | COVERED |
| CONTEXT | D-05 independent full clones | 01, 05 | COVERED |
| CONTEXT | D-06 reversible local candidate commit | 01 | COVERED |
| CONTEXT | D-07 119 rows/private archive/historical readers | 01, 05 | COVERED |
| CONTEXT | D-08 complete nine-stage --all | 02, 05 | COVERED |
| CONTEXT | D-09 exact tool preflight | 02, 05 | COVERED |
| CONTEXT | D-10 lock-bound dependencies | 02, 05 | COVERED |
| CONTEXT | D-11 private retained logs | 02, 05 | COVERED |
| CONTEXT | D-12 HEAD/tree/index/NUL status/ignored outputs | 02, 05 | COVERED |
| CONTEXT | D-13 generated contracts and owned-output cleanup | 02, 05 | COVERED |
| CONTEXT | D-14 current Mix/Phoenix/Swift/Android proof owners | 02, 05 | COVERED |
| CONTEXT | D-15 existing CI graph only | 03, 05 | COVERED |
| CONTEXT | D-16 actual runner checkout | 03, 05 | COVERED |
| CONTEXT | D-17 exact unmerged synthetic merge candidate | 05 | COVERED |
| CONTEXT | D-18 head-only job distinction | 03, 05 | COVERED |
| CONTEXT | D-19 complete run/attempt/paginated metadata | 03, 05 | COVERED |
| CONTEXT | D-20 policy/graph/classifier/authorized skips | 03, 05 | COVERED |
| CONTEXT | D-21 bounded repair and rerun | 02, 03, 05 | COVERED |
| CONTEXT | D-22 local preparation then scoped proposal authority | 04 | COVERED |
| CONTEXT | D-23 changed synthetic merge rerun/uncertain delivery | 04, 05 | COVERED |
| CONTEXT | D-24 plain status/handoff and historical boundaries | 05 | COVERED |
| CONTEXT | D-25 source-joined completion, no automatic release/archive | 05 | COVERED |

Deferred release, merge, publication, private archive retirement, broader platform/UI work and a replacement CI lane are excluded by the phase context. No required source item is omitted.

## SPEC-less probe fallback

No Phase178 SPEC supplies Edge Coverage or Prohibitions. The installed deterministic edge probe ran on the exact MAINT-07/08 requirement text and returned three unresolved items: MAINT-07 `unclassified`, MAINT-08 `boundary`, MAINT-08 `precision`. They remain flagged execution assumptions until the named acceptance gates pass; no probe verdict is silently reclassified. MAINT-07 unclassified maps to 178-01 T2 source selection, 178-02 T1 real full-run parser fixture/T2 preliminary proof and 178-05 T2 exact runner-tested commit's complete nine-result --all with unchanged snapshots. MAINT-08 boundary maps to 178-03 T1 zero/one/multiple pages and missing/latest attempt negatives and 178-05 T1 actual bound run plus source-drift rejection. MAINT-08 precision maps to 178-03 T2 combined policy context/app contract and 178-05 T1/T3 exact 40-hex OID equality, unique job/check identities and complete counts. Any failed gate leaves its assumption flagged and requirements pending; no numeric rounding contract was invented.

## Checker revision disposition

The five plans now each carry their own producer/consumer table. Plan02's positive parser fixture runs the selected source's exported full `runVerification({selection: "all"})` path with supported injection and actual retained files; `--self-test` is separately recognized as one line. Supplemental Git snapshots in Plans02/05 set `GIT_OPTIONAL_LOCKS=0`. Plan03 reads branch protection and GitHub's effective active rules for the target base; that endpoint includes applicable repository and inherited organization rulesets, while inaccessible/malformed policy blocks. Research questions now specify execution procedures and remain honest about unobserved commit, policy and credential facts. The Plan01 file-count warning is accepted with an explicit bounded rationale: six atomic Phase177 source paths plus three small evidence files, two tasks and 21,000 projected tokens; splitting the fixed-six candidate across plans would undermine the source selection. The Wave-2 private writer race is removed by immutable shared input and disjoint atomic per-plan files.

Adversarial prohibition recall for MAINT-07/08 surfaced private proof leakage, false green on another commit, inherited release write authority and misleading release/device promotion. Routine parser correctness and generic canon security were excluded from the value/safety list. The surviving bespoke prohibitions are authored under each plan's `must_haves.prohibitions` via the `projectProhibitions` flat projection shape as descriptor-less `status: unresolved` items. The installed serializer/disposition contract returns `{status: unverified, flagged: true}` for each without wired evidence; no `check_*` descriptor or green enforcement claim was fabricated. These flags remain visible to independent verification.

## Contribution and gate decisions

The plan:pre registry exposed API coverage, assumption-delta, schema-push and security contributions. The API coverage detector examined the Phase178 roadmap section and five plan bodies and returned `detected:false`: fixed read-only GitHub metadata routes are evidence glue for an existing workflow, not a new external API integration. The assumption-delta query returned `detected:false`; exact commit identity remains the primary key. No ORM schema paths are touched, so no schema push task is applicable. Security is enabled at ASVS level 1 with high severity blocking; every plan has a unique T-178-NN register and the reserved T-178-SC package gate row. No new package is proposed, so the research package-legitimacy install gate is not triggered.

`estimate-calibration` returned factor 1, sample_count 0, confidence low; plan estimates use that factor and label. GSD frontmatter and plan-structure validation must pass before checker handoff. The explicit protected-checkout instruction prohibits a planning commit, so these planning files remain unstaged.
