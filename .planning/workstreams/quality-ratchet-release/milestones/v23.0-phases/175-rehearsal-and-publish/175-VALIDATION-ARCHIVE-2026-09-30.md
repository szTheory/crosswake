---
phase: 175
slug: rehearsal-and-publish
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: validated
nyquist_compliant: true
wave_0_complete: false
created: 2026-09-18
---

# Phase 175 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

This is an execution and evidence phase. The active successor contract is the section immediately
below. The older 175-01..10 map later in this file is retained as historical validation context;
`175-VALIDATION-ARCHIVE-2026-09-18.md` remains untouched. Live run, artifact and registry responses
are required for publication claims. A workflow definition alone cannot establish them.

## Plan 175-53 source-boundary follow-up — validation contract (2026-09-29)

Use D-57 through D-61 in `175-CONTEXT.md` for the approved behavior. Preserve Plan 175-53's
`SOURCE` / `FULL_CLONE_SPLIT_FAILED` receipt as historical evidence; all follow-up evidence must
use a new plan and fresh receipt identity.

| Gate | Automated evidence required | Fail-closed result |
|---|---|---|
| Isolated source attempt | One full-history clone attempt; bounded status for command invocation, exit status, source commit availability, history completeness, and split OID validity. Do not print or retain raw stdout/stderr. | Missing or unknown source facts stay unknown; split failure remains at `SOURCE` / `FULL_CLONE_SPLIT_FAILED`. No retry. |
| Local correction allowance | A correction can occur only once, only within the isolated attempt, and only when bounded evidence proves an invocation or clone setup defect. | If cause is unproven or requires source/path/policy changes, stop and require a reviewed correction plan. Do not change split algorithm. |
| Conditional fresh preflight | If source split succeeds, re-read all required source/mirror/PR/policy facts and compute a new digest. Assert the write-ahead receipt/reservation is durable and read-back verified before any authenticated dry-run. | Any missing, changed, failed, or ambiguous predicate blocks before dry-run; old receipts/digests are never accepted. |
| Single dry-run and audit | At most one authenticated `git push --dry-run --porcelain`, only after every gate passes. Apply D-54's complete bounded stdout grammar and D-55's separate stderr handling; then capture planned post-observations and an independent audit. | Ambiguity is terminal for that invocation. No retry or automatic continuation to tag creation. |
| Receipt privacy and operator guidance | Validate the versioned sanitized receipt against D-60; preserve unknown separately from false. Text/JSON output shows a stable reason and one safe next step. | Reject raw output, excerpts, arguments, environment, paths, remote details, credentials/helper configuration, and raw-output hashes. No release, merge, Gate 2, recovery, or publication authority is implied. |

**Sampling boundary:** Do not run tests or the authenticated dry-run during planning. During any
later authorized execution, evaluate only the plan's bounded local assertions and freshly gathered
evidence. No registry mutation, tag write, CI dispatch, merge, or publisher is part of this
follow-up's authorization.

## Historical successor validation — plans 175-26..29 and repairs in 175-33

This section records the consumed 0.2.5 successor attempt. Plans 175-30..32 are superseded and are
not an active execution sequence; Plan 175-33 records the bounded receipt-roster and iOS host-proof
repairs. Plan dispositions and immutable outcomes are recorded in `175-DISPOSITIONS.md` and the
plan summaries. Both 0.2.4 and 0.2.5 remain PARTIAL historical releases; neither supplies evidence
or authorization for a future candidate.

## Current REL-17 gap-closure validation

The current planning scope is the shared REL-17 gate across linked release, recovery, and companion
publication. Plans 175-34..37 are complete; Plan 175-38's 0.2.6 transaction is PARTIAL before
publishers, with its token consumed and all three coordinates absent. Plan 175-42 is the local
authorization-selector and exact source-envelope binding repair; its independent plan check found
no actionable issues. Plans 175-39..41 are superseded
because their 0.2.6 publication/proof prerequisites are false; create fresh proof, companion and
closeout plans against a later candidate. Do not execute release, recovery, merge, or registry
mutations during this guard repair. Tests, workflow mutations, evidence shape checks, and command
output checks are automated; any future publication decision remains separate and candidate-specific.

| Task | Requirement | Automated gate / evidence | Result |
|---|---|---|---|
| 175-26-01 | REL-13 | `elixir script/check_release_workflow_integrity.exs` and focused Phase 175 ExUnit | PASS: ordinary iOS setup is ordered before publish; missing/late setup seeds fail. |
| 175-26-02 | REL-13 | `actionlint .github/workflows/release-please.yml` plus focused ExUnit | PASS: workflow syntax and candidate evaluator contract. |
| 175-27-01 | REL-13 | Focused Phase 175 ExUnit against local merge/receipt fixtures | PASS: exact candidate accepted; wrong merge/head/tree/base/version/source/receipt and recovery identity rejected. |
| 175-27-02 | REL-13 | Integrity scanner, focused ExUnit and `actionlint` | PASS: receipt download/digest chain and separate recovery pin are seed-red guarded. |
| 175-28-01 | REL-10/11/13 | `jq` gate on `175-successor-candidate.json`; exact fetched PR/CI and direct target queries | PASS: successor version and lineage verified; runbook ancestry passed; targets were absent before Gate 2. |
| 175-28-02 | REL-11/13 | Rehearsal and receipt JSON gates; exact run/artifact downloads | PASS after using the actual receipt schema: `.artifact.sha256` and `.artifact.id`. Hex, iOS and Maven rehearsal evidence was exact and no-mutation. |
| 175-29-01 | REL-10/13 | Pending Gate 2 JSON and fresh remote rechecks | PASS at decision time. This absence/pending assertion is intentionally stale now that the authorized 0.2.5 run published; never replay it. |
| 175-29-02 | REL-13 | Exact-token gate for the irreversible decision | PASS: one fresh authorization was consumed by one protected merge and ordinary run. |
| 175-29-03 | REL-13 | Same-run job evidence and three independent registry queries | PARTIAL: Hex and iOS published; Maven did not. No retry or recovery was authorized. See 175-29-SUMMARY.md. |
| 175-33-01 | REL-13 | `MIX_ENV=test mix test test/crosswake/proof/phase175_release_recovery_test.exs test/crosswake/release_candidate/workflow_test.exs --max-cases 1` | PASS: exact receipt roster accepted; missing, extra, nested, and symlinked members rejected (31 tests, 0 failures). |
| 175-33-02 | REL-13 | `elixir script/check_release_workflow_integrity.exs`, `actionlint`, focused ExUnit | PASS: receipt artifact validation and iOS manifest generation guard remain wired and fail closed. |
| 175-33-03 | REL-13 | Exact Gate 2 evidence predicate and registry/run records | PASS: consumed token and 0.2.5 PARTIAL state are preserved; no re-publication or recovery was attempted. |

**Current checkpoint policy:** zero human verification or UAT for machine-checkable claims. The
175-29 exact one-way core publication decision was consumed once; its outcome is PARTIAL. Plans
175-30 through 175-32 were superseded by Plan 175-33. Plan 175-38's separate 0.2.6 Gate 2 was also
consumed once and ended PARTIAL before publishers; Plan 175-42 creates no replacement authority.
No retry, recovery or publication is authorized by either consumed token. No human UAT remains for
this phase.

**Current sampling:** run each plan's focused automated command after its code/evidence task;
run actionlint and the integrity scanner after workflow changes; requery live run/artifact/registry
facts immediately before each gate and at closeout. Persist identifiers, digests, closed outcomes
and timestamps only. Exclude credentials, raw responses, logs, signing data, payloads, transcripts,
account IDs and stable device IDs.

---

## Plan 175-50 — historical iOS tag and current-base PR CI

Plan 175-50 replaces only Plan 175-49's blocked preflight path. It uses a new receipt and digest;
the old receipt, failed dry-run, later diagnostics, consumed Gate 2, and 0.2.6 PARTIAL evidence keep
their recorded meanings. The only human checkpoint is the exact tag create-or-hold decision. The
machine-verifiable ref, CI, artifact, and job claims remain automated. A VERIFIED result proves the
historical mirror prerequisite and current PR #219 CI only; it does not authorize a successor merge,
Gate 2, release, recovery, or publisher.

| Plan/task | Requirement | Automated gate / evidence | Result boundary |
|---|---|---|---|
| 175-50-01 | REL-13/REL-17 | Full isolated source clone, independent subtree split, complete non-peeled source/mirror refs, current PR identity, exact HTTPS helper/push permission, single-ref Git dry-run, and canonical Plan 50 digest in `evidence/175-ios-tag-026-plan50.json`; Task 1 `jq` predicate | PASS permits only the fresh checkpoint; any missing, changed, failed, or ambiguous fact records `BLOCKED_PREFLIGHT` with zero writes. |
| 175-50-02 | REL-17 | Repeat the full read-only preflight and digest immediately before the authenticated GSD decision; Task 2 receipt predicate | PASS permits only the exact `create_exact_tag` choice or hold for the displayed digest; stale Plan 49 authority cannot pass. |
| 175-50-03 | REL-13/REL-17 | Durable `ATTEMPT_RECORDED`, one empty-target-lease tag write at most, independent live ref reconciliation, then one post-tag current-base PR #219 run/attempt and matching candidate-CI artifact; complete job pagination, successful parity leaf, successful Crosswake CI aggregate check, and final unchanged PR/ref reads; Task 3 receipt predicates | PASS records `VERIFIED`; every ambiguous write/CI/API/artifact/pagination/ref outcome stays held without retry. A held decision makes zero writes and launches no CI run. |

**Plan 175-50 sampling rule:** do not execute during planning. During later execution, evaluate each
receipt predicate against the newly written artifact, and retain only sanitized public OIDs, run and
attempt IDs, artifact identity, job/check IDs, verdicts, and timestamps. Never persist credentials
or raw authentication output. No release test suite or publication workflow is part of this plan.

---

## Historical validation map (175-01..10)

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.19.5-otp-27 / Erlang 27.3, pinned in `.tool-versions`), plus Node CLI checks (`scripts/ci_monitor.cjs`) and Elixir CI-hygiene scripts (`script/check_*.exs`) |
| **Config file** | `mix.exs` (root); companion packages carry their own `mix.exs` |
| **Quick run command** | `mix test test/crosswake/release_candidate --max-cases 1` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~45 s quick, several minutes full |

---

## Sampling Rate

- **After every task commit:** run that task's `<automated>` commands, plus
  `node scripts/ci_monitor.cjs check-actions` from Wave 2 onward and
  `elixir script/check_release_doc_version_literals.exs` from Wave 5 onward.
- **After every plan wave:** `mix test test/crosswake/release_candidate --max-cases 1`.
- **Before `/gsd-verify-work`:** `mix test` green, both hygiene checks exit 0, and every registry
  confirmation re-run live.
- **Max feedback latency:** 60 s for script and unit checks; a CI dispatch leg is bounded by its own run
  duration and is watched rather than polled blindly.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 175-01-01 | 01 | 1 | VAC-03 | T-175-01 / T-175-02 | A truncated audit scope cannot exit 0 | unit (CLI) | `node scripts/ci_monitor.cjs check-actions` + fresh-glob parity comparison | ✅ | ⬜ pending |
| 175-01-02 | 01 | 1 | VAC-03 | T-175-03 | The scope gate is proven fail-first | unit (CLI self-test) | `node scripts/ci_monitor.cjs test-check-actions-scope` | ❌ W1 creates it | ⬜ pending |
| 175-02-01 | 02 | 2 | VAC-03 | T-175-05 / T-175-06 / T-175-09 | Token-reading job loads no mutable third-party ref | config scan | `node scripts/ci_monitor.cjs check-actions <5 files>` | ✅ | ⬜ pending |
| 175-02-02 | 02 | 2 | VAC-03 | T-175-06 / T-175-08 | Zero mutable refs repo-wide, single SHA per tag | config scan | `node scripts/ci_monitor.cjs check-actions` (no args) | ✅ | ⬜ pending |
| 175-03-01 | 03 | 3 | VAC-03 | T-175-11 / T-175-12 | Five exit verdicts, none blank, scope parity freshly computed | structural | `test -s .../175-WAVE0-EXIT.md` + `check-actions` + `test-check-actions-scope` | ❌ W3 creates it | ⬜ pending |
| 175-03-02 | 03 | 3 | VAC-03 | T-175-13 / T-175-14 | Wave 0 merged green through the protected path | manual (human gate) | none — `checkpoint:human-verify`, see Manual-Only Verifications | N/A | ⬜ pending |
| 175-04-01 | 04 | 4 | REL-16 | T-175-17 / T-175-18 / T-175-19 | Matrix rows detect from registry evidence; no blank irreversibility cell | structural | invariant-sentence grep, outside-fence literal count, heading count, 15-row count | ❌ W4 creates it | ⬜ pending |
| 175-04-02 | 04 | 4 | REL-10 | T-175-16 | Recovery language matches real tool semantics | structural | heading grep, `unretire` grep, `un-resolve` grep, literal count | ✅ after 175-04-01 | ⬜ pending |
| 175-04-03 | 04 | 4 | REL-10 | T-175-20 / T-175-21 | Runbook SHA is a real ancestor of the exact remote publish graph, not divergent local state | structural (git) | fetch and match live PR base/head OIDs; `script/check_release_runbook_ancestry.sh <sha> <exact-oid>`; audit exact merge OID | ❌ W4 creates it | ❌ Gate 1 breach recorded 2026-09-19; local `HEAD` check passed while PR #147 base/head/merge excluded the runbook |
| 175-05-01 | 05 | 5 | DOC-04 | T-175-22 / T-175-23 | False section removed, not softened | structural | deletion-witness grep, invariant grep, literal count, heading-set count | ✅ | ⬜ pending |
| 175-05-02 | 05 | 5 | DOC-06 | T-175-28 | Durable split mechanism named; archived history untouched | structural | `git subtree split` count ≥ 3, literal count, `git status --porcelain` on archived milestones | ✅ | ⬜ pending |
| 175-05-03 | 05 | 5 | DOC-04, DOC-06 | T-175-24 / T-175-25 / T-175-26 / T-175-27 | Check proven red on an injected literal before being trusted | unit (script) + CI wiring | `elixir script/check_release_doc_version_literals.exs`, recorded fail-first log, CI step grep, `check_release_workflow_integrity.exs` | ❌ W5 creates it | ⬜ pending |
| 175-06-01 | 06 | 6 | REL-11 | T-175-29 / T-175-30 / T-175-32 | Hex rehearsal runs against the real candidate; fields asserted by value | CI run evidence | `gh run view <id> --json conclusion` + field greps on the evidence index | ❌ W6 creates it | ⬜ pending |
| 175-06-02 | 06 | 6 | REL-11 | T-175-31 / T-175-32 | iOS split computed, push dry-run, tag independently absent | CI run + live remote | `git ls-remote --tags` reachability + non-empty, PROVEN grep, 4× SHA count | ✅ after 175-06-01 | ⬜ pending |
| 175-06-03 | 06 | 6 | REL-11 | T-175-33 / T-175-34 | Maven coordinate validated then dropped, still free | CI run + live registry | live POM `curl` status capture + three-row verdict count | ✅ after 175-06-01 | ⬜ pending |
| 175-07-01 | 07 | 7 | REL-12 | T-175-35 | Gate 1 satisfied only by the Hex rehearsal run identifier | manual (human gate) | none — `checkpoint:decision`, see Manual-Only Verifications | N/A | ⬜ pending |
| 175-07-02 | 07 | 7 | REL-12 | T-175-36 / T-175-38 / T-175-39 / T-175-40b | Published tree equals rehearsed tree and exact remote ancestry is non-vacuous | CI run evidence | `gh run view <id> --json conclusion` + exact PR base/head/merge OIDs through `script/check_release_runbook_ancestry.sh` | ❌ W7 creates it | ❌ publish occurred, but runbook ancestry failed against merge `096371e3`; Gate 1 is noncompliant |
| 175-07-03 | 07 | 7 | REL-12 | T-175-37 / T-175-40 | Live registry confirms, empty release list fails | live registry | captured Hex JSON non-empty + `python3` parse asserting a non-empty release list | ❌ W7 creates it | ⬜ pending |
| 175-08-01 | 08 | 8 | REL-13 | T-175-42 / T-175-43 / T-175-47 | Gate 2 carries three separate irreversibility statements and the ancestor check | manual (human gate) | none — `checkpoint:decision`, see Manual-Only Verifications | N/A | ⬜ pending |
| 175-08-02 | 08 | 8 | REL-13 | T-175-41 / T-175-45 / T-175-46 / T-175-47 | Per-job conclusions recorded; tag lands on the rehearsed split SHA; runbook is reachable from exact remote base/head/merge OIDs | CI run + live remote | explicit-OID runbook guard, leg record non-empty, `git ls-remote` reachability | ❌ W8 creates it | ⬜ pending |
| 175-08-03 | 08 | 8 | REL-13 | T-175-44 / T-175-48 | Three registries confirmed independently, raw bodies captured | live registry | Hex JSON parse, mirror tag capture, Maven status capture — all non-empty | ❌ W8 creates it | ⬜ pending |
| 175-09-01 | 09 | 9 | REL-14 | T-175-49 / T-175-50 / T-175-51 / T-175-52 | Skipped ≠ passed; status and conclusion recorded separately | CI run evidence | `gh run view <id> --json jobs` + `python3` assertion on status and conclusion; ledger non-empty | ❌ W9 creates it | ⬜ pending |
| 175-09-02 | 09 | 9 | REL-14 | T-175-53 / T-175-54 | Rollup unmodified; six children enumerated | unit + structural | `git status --porcelain` on the rollup source, section-heading count, `mix test test/crosswake/release_candidate` | ✅ | ⬜ pending |
| 175-10-01 | 10 | 10 | REL-15 | T-175-55 | Gate 3 satisfied only by the live proof run identifier | manual (human gate) | none — `checkpoint:decision`, see Manual-Only Verifications | N/A | ⬜ pending |
| 175-10-02 | 10 | 10 | REL-15 | T-175-56 / T-175-57 | SC7 recorded as two independently evidenced facts; rollup untouched | live registry + structural | captured Hex JSON parse, `git status --porcelain` on the rollup source, `git cat-file -e <merge-sha>` | ❌ W10 creates it | ⬜ pending |
| 175-10-03 | 10 | 10 | REL-10..REL-16, DOC-04, DOC-06 | T-175-58 / T-175-59 / T-175-60 | Nine verdicts, no blanks, no reworded requirement; hygiene still green at close | structural + regression | requirement-id count ≥ 9, `REQUIREMENTS.md` text-diff guard, version-literal check, `check-actions` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Wave 0 here is plan `175-01` — the broken-windows triage that gates every publish task (D-22, D-28). It
creates the two verification instruments the rest of the phase leans on:

- [ ] `node scripts/ci_monitor.cjs test-check-actions-scope` — the scope-cardinality self-test, proving
      the gate red on a narrowed scope and green on an equal-scope control (`175-01` Task 2).
- [ ] `.../evidence/175-scope-gate-regression.log` — the recorded demonstration of that red.
- [ ] `.../evidence/` — the phase evidence directory every later plan writes into.

No new ExUnit suite is required. The existing `test/crosswake/release_candidate` and
`test/crosswake/proof` suites already cover the *shape* of rehearsal and proof correctness; this phase's
job is to produce real-world evidence, not new unit coverage. `script/check_release_doc_version_literals.exs`
(`175-05`) is a new check and carries its own fail-first demonstration rather than an ExUnit wrapper,
following the convention of `script/check_absence_is_not_success.exs`.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Wave 0 pull request merged green before Wave 1 opens | VAC-03 (D-22) | Merging into protected `main` is a human act in this repository; admin-bypass is refused | `175-03` Task 2: confirm the diff contains only the ten workflow files, `scripts/ci_monitor.cjs`, the evidence logs and the exit record; confirm every required check green, especially the six proof lanes whose refs changed; merge; re-run `check-actions` on `main`; record the merge commit SHA |
| Authorization of the first companion Hex publish | REL-12 (D-07, D-08) | A one-way registry mutation; no automated check may authorize it | `175-07` Task 1: reply `publish leg 1 <hex-rehearsal-run-id>` with the identifier read from `175-REHEARSAL-EVIDENCE.md` |
| Authorization of the three-registry core publish | REL-13 (D-07 through D-11) | Opens three one-way doors at once, one of them permanently (Maven) | `175-08` Task 1: reply `publish core <ios-rehearsal-run-id>` with the identifier read from `175-REHEARSAL-EVIDENCE.md` |
| Authorization of the second companion Hex publish | REL-15 (D-07, D-08, D-09) | A one-way registry mutation | `175-10` Task 1: reply `publish leg 3 <exact-public-proof-run-id>` with the identifier read from `175-PROOF-EVIDENCE.md` |

Each gate's typed-back value is a different named field, read from that leg's own evidence, so a gate
cannot be satisfied with what was typed at an earlier one (D-08). None of the three is auto-approvable;
`--no-reversibility-gates` must not be used for this phase (D-12).

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or a recorded Manual-Only entry
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60 s for script and unit checks
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending

## Validation Audit 2026-09-25

| Metric | Count |
|---|---:|
| Gaps found | 1 |
| Resolved | 1 |
| Escalated | 0 |

Resolved the symlinked receipt-member coverage gap with a real-filesystem regression test. Updated
the active-plan map to exclude superseded Plans 175-30..32 and include Plan 175-33. Corrected the
receipt JSON path in the validation description and marked Plan 175-29's pending/absence predicate
as historical because the later authorized run published 0.2.5.

The receipt-integrity audit found that the canonical builder did not hash the actual clean-room
artifact, the exact roster omitted it, and provenance did not bind it. The builder now requires the
eight-file roster, reads and hashes `ci/cleanroom.json`, compares its digest with the CI claim, and
emits a `candidate.cleanroom` proof. The attestation workflow checks the downloaded file and proof
digest. A mismatch regression case was added. Focused receipt and workflow tests: 35 tests, 0
failures. Workflow integrity: 79/79 checks; `actionlint` passed for the updated workflow. Full
configured regression: 1,975 tests, 0 failures, 74 excluded. Assertion inventory: 230 classified
sites, exact match. `git diff --check` passed. Security audit: three current findings closed; six
historical high-severity threats remain open and block phase advancement, with twelve
lower-severity findings still open pending a maintainer decision.

## REL-17 Validation Addendum (2026-09-26)

This section governs new planning after the REL-17 scope update. The 0.2.4 and 0.2.5 publication
records remain immutable PARTIAL outcomes. No verification command in this addendum authorizes a
merge, publish, recovery, retirement, or mirror mutation.

| Contract | Positive proof | Required negative controls | Boundary |
|---|---|---|---|
| Per-operation identity | Shared validator accepts an immutable envelope bound to the canonical receipt digest, operation, exact candidate, leg, and matching run ID. | Omit or alter each identity/digest/run field; use a different leg's run. | Pure Elixir fixture; no live release. |
| Live freshness | Immediately before authorization, fetched base/head/readiness, CI, and current required-check policy match the candidate; final publisher evidence binds the actual post-merge OID. | Stale base/head, changed policy, failed/missing CI, empty/truncated page, API error, omitted field. | Mocked/API-fixture tests plus workflow wiring checks. |
| Registry evidence | Exact raw registry response is retained; parse is nonempty and the matching Hex response-table row is bound to the leg run. | Empty body/collection, invalid JSON, wrong row/run, absent raw response, parse failure. | Evidence artifact retains allowed public response; CLI/log output excludes raw body. |
| Protected path and ancestry | Post-merge guard verifies normal protected merge, no admin bypass, and the runbook ancestor of fetched base, approved head, and actual merge. | Bypass marker, missing/wrong Git object, non-ancestor, wrong merge OID. | Seeded Git fixtures; no merge/push. |
| Every side-effect path | Structural guard plus behavior fixtures prove linked release, recovery, and companion paths consume the same validator immediately before mutation. | Remove or bypass each individual call-site guard and prove no publisher reaches its mutation command. | Workflow/shell mutation tests; no dispatch. |
| Operator status | Read-only Mix status explains BLOCKED with missing conditions and safe next step; PARTIAL and COMPLETE remain stable. | `READY FOR APPROVAL` alone cannot authorize; BLOCKED never suggests retry/recovery and prints no raw payload. | CLI output assertions; text status must not depend on color. |
| Final successor completion | One fresh ordinary run independently proves all three core coordinates, successful exact-public proof, and six-child COMPLETE; second companion evidence remains separate. | A recovery run cannot contribute; skipped/failed child stays PARTIAL; companion cannot enter core rollup. | Live facts only after REL-17 and a new exact-candidate decision gate. |

### Additive plan/task validation map

| Plan/task | Validation focus | Planned automated evidence |
|---|---|---|
| 175-34-01..02 | Pure shared contract; per-field and stage mutations | `evidence_gate_test.exs` positive and mutation cases |
| 175-34-03 | Package-scoped companion receipt | `companion_receipt_test.exs` rejects wrong package and stale source |
| 175-35-01..02 | Complete fresh pre-merge and actual post-merge remote evidence | `evidence_live_test.exs` and `evidence_gate_test.exs` API fixtures, pagination, response-byte, row/run and ancestry mutations |
| 175-35-03 | Read-only operator status and safe copy | `crosswake_release_status_test.exs` proves BLOCKED reason and no response bytes in output |
| 175-36-01 | Release creation and ordinary Hex/iOS/Maven paths | `phase175_rel17_publish_paths_test.exs` independent guard-removal mutations |
| 175-36-02 | Hex/Maven/iOS recovery paths | `phase175_rel17_recovery_paths_test.exs` wrong-operation, stale-policy and removed-guard mutations |
| 175-36-03 | Five companion jobs and complete path roster | Existing integrity scanner, `phase175_rel17_wiring_test.exs`, `actionlint`, nonempty closure record |
| 175-37-01..03 | Fresh candidate, safe three-leg rehearsals, canonical receipt and pending linked pre-merge envelope | Exact candidate/receipt/rehearsal JSON predicates; no publish authority |
| 175-38-01,03 | Fresh Gate 2 facts; then protected merge, actual merge binding, one ordinary run and three registry observations | Pending/null authorization predicate before checkpoint; post-merge/run/registry JSON predicates after a separate exact decision |
| 175-39-01..02 | Exact-public executes and passes in the core run; all six core children succeed in that same run | Exact artifact/run binding and six-child `COMPLETE` predicate |
| 175-40-01,03 | Exact held PR #115, followed by its separate Gate 3, guarded publication and direct Hex proof | Candidate/gate/post-merge/run/registry predicates carry PR #115; one separate exact decision |
| 175-41-01..02 | Reconcile evidence and durable status to current nine-criterion roadmap | Focused integrity check, same-run/core and direct Hex evidence predicates, and `git diff --check` |
| 175-42-01..02 | Render and check future Gate 2 from the exact retained source envelope; keep the workflow and loader's Hex `leg_run_id` equality before publishers | Focused synthetic positive/negative ExUnit cases (including source/result/Gate 2 binding mutations), `bash -n`, real workflow/loader predicate, and integrity-scan mutation |

Plan 175-40 cannot substitute a new companion PR for SC-7. If held PR #115 cannot obtain exact
current CI and merge readiness, leave the Gate 3 unpresented and record SC-7 as still open.

**Sampling rule:** run local validator mutations, workflow-integrity checks, and artifact-shape checks
before safe rehearsal; re-fetch mutable GitHub/registry facts at the eventual authorization and
immediately before each side effect. Keep CI feedback actionable and preserve direct exit codes or
`pipefail`. Machine-checkable claims remain zero-human-verification; unavoidable one-way registry
decisions remain candidate-specific human checkpoints. Do not use a generic retry control or a
Phoenix/Plug UI for this operational release gate.
