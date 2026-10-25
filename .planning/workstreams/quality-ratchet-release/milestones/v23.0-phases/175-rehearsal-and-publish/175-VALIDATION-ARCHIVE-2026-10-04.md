---
phase: 175
slug: rehearsal-and-publish
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-09-30
---

# Phase 175 — Validation Strategy

> Current validation contract for the D-84–D-86 bounded-source evidence plan is appended at the
> end. The earlier exact-head, source-boundary and local-reconciliation material remains historical
> to those plans. Prior validation history is preserved in `175-VALIDATION-ARCHIVE-2026-09-30.md`.

The Plan 175-55 and Plan 175-56 material below is historical and does not define the next plan.
Use the exact-head evidence addendum at the end for current scope. None of the historical plans or
artifacts may be replayed or reused.

## Scope and safety boundary

Plan 175-55 is evidence-only. It may run one unchanged source split after all four source
preconditions are `TRUE`. If that split passes, it may continue only through a complete fresh
read-only preflight, new canonical digest, durable reservation/readback, at most one authenticated
`git push --dry-run --porcelain`, post-observations, and an independent audit. It must stop before
any tag write, merge, Gate 2, recovery, publication, or release decision. False or unknown required
facts block before reservation; ambiguous execution is terminal and never retried.

Do not run these checks or the authenticated dry-run while planning. Later execution must use new
receipt identity and freshly gathered facts; Plans 175-49 through 175-54 and their digests are
historical evidence and cannot be replayed.

## Discussion-decision alignment

Validation follows D-62 through D-65 in `175-CONTEXT.md`. The four source-readiness facts remain
tri-state and must all be `TRUE` before the one reserved split. D-64 permits transient strict
parsing only of the successful split's single documented OID and the exact D-54 porcelain stream;
all human diagnostics and stderr remain opaque, and raw streams are never displayed or persisted.
Any incomplete or malformed machine output blocks. Status uses the existing Mix text/JSON surface
and one safe next action; the release hold and zero-write boundary remain unchanged.

## Test infrastructure

| Property | Value |
|---|---|
| **Framework** | ExUnit |
| **Config file** | `test/test_helper.exs`, `mix.exs` |
| **Quick run command** | `MIX_ENV=test mix test test/crosswake/release_candidate/ios_tag_source_evidence_test.exs test/crosswake/release_candidate/ios_tag_source_runner_test.exs test/mix/tasks/crosswake_release_status_test.exs --max-cases 1` |
| **Full suite command** | `MIX_ENV=test mix test --max-cases 1` |
| **Estimated runtime** | Focused checks target under 60 seconds; not measured in this planning turn. |

## Sampling rate

- After each implementation task, run its focused ExUnit file(s) with `--max-cases 1`.
- After the final implementation task, run the quick command and the full configured repository
  verification required by the plan. Keep registry or release mutations out of the command set.
- Max feedback latency target for focused checks: 60 seconds.

## Per-task verification map

Plan 175-55 contains three sequential tasks within DAG wave 13. Task IDs below map to task order.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure behavior | Test type | Automated command / evidence | File exists | Status |
|---|---|---:|---|---|---|---|---|---|---|
| 175-55-01 | 175-55 | 13 | REL-13 / REL-17 | T-175-55-01, T-175-55-02, T-175-55-03, T-175-55-06 | Four source facts retain TRUE/FALSE/UNKNOWN, including exact source-tag identity; false/unknown blocks before reservation; the exact split runs at most once after four TRUE facts; raw process output is not retained or surfaced. | ExUnit fake-process seam + format/Node syntax checks | `MIX_ENV=test mix test test/crosswake/release_candidate/ios_tag_source_evidence_test.exs test/crosswake/release_candidate/ios_tag_source_runner_test.exs --max-cases 1`<br>`mix format --check-formatted lib/crosswake/release_candidate/ios_tag_source_evidence.ex lib/crosswake/release_candidate/ios_tag_source_runner.ex test/crosswake/release_candidate/ios_tag_source_evidence_test.exs test/crosswake/release_candidate/ios_tag_source_runner_test.exs`<br>`node --check script/release_candidate/ios_tag_source_collector.mjs` | ⬜ runner test target is new | ⬜ pending |
| 175-55-02 | 175-55 | 13 | REL-13 / REL-17 | T-175-55-02, T-175-55-03, T-175-55-04, T-175-55-05, T-175-55-06 | Fresh conditional preflight, exact porcelain parsing, one durable reservation, post-observations and independent audit fail closed; status projects only validated bounded values and grants no write authority. | ExUnit parser/state/durability tests + Mix status tests | `MIX_ENV=test mix test test/crosswake/release_candidate/ios_tag_source_evidence_test.exs test/crosswake/release_candidate/ios_tag_source_runner_test.exs test/mix/tasks/crosswake_release_status_test.exs --max-cases 1`<br>`mix format --check-formatted lib/crosswake/release_candidate/ios_tag_source_evidence.ex lib/crosswake/release_candidate/ios_tag_source_runner.ex lib/mix/tasks/crosswake.release.status.ex test/crosswake/release_candidate/ios_tag_source_evidence_test.exs test/crosswake/release_candidate/ios_tag_source_runner_test.exs test/mix/tasks/crosswake_release_status_test.exs`<br>`node --check script/release_candidate/ios_tag_source_collector.mjs` | ⬜ runner test target is new | ⬜ pending |
| 175-55-03 | 175-55 | 13 | REL-13 / REL-17 | T-175-55-01, T-175-55-02, T-175-55-03, T-175-55-04, T-175-55-05, T-175-55-06 | One fresh source attempt and its conditional dry-run/audit end in a digest-valid v4 receipt or a bounded terminal block; zero writes, null decision and release hold remain invariant. | Focused ExUnit suite + receipt digest/schema check + read-only plan-index assertion | Canonical SHA-256 and Mix validator/invariants plus the executable plan-index assertion are specified in Plan 175-55 Task 3 `<verify>`; each fails closed on an absent/invalid receipt or changed terminal/runnable graph. | ⬜ new receipt is absent until execution | ⬜ pending |

## Wave 0 requirements

Existing ExUnit infrastructure covers these contracts. Node 22 is already a repository-required
verification runtime for the separate-pipe collector. No framework, dependency, workflow, or CI
lane is needed. Task 1 supplies the private fake-process seam. The known GSD TDD evidence parser
does not currently recognize native ExUnit RED output; preserve actual failing-test evidence and
record `INVALID_RED/zero_tests_discovered` if that tooling gap remains.

## Manual-only verifications

None. Do not create a human UAT checkpoint for machine-verifiable assertions. If the exact
authenticated dry-run cannot be safely performed with already available credentials or a required
precondition is unknown, record a bounded blocked result and stop; do not solicit credentials in
logs, receipts, or output.

## Validation sign-off

- [ ] Every final plan task has an automated verification or an explicit Wave 0 dependency.
- [ ] No three consecutive tasks lack automated verification.
- [ ] Wave 0 covers all missing test references.
- [ ] No watch-mode flags are used.
- [ ] Focused feedback latency is below 60 seconds or the measured exception is documented.
- [ ] Set `nyquist_compliant: true` only after the plan's verification map is complete and reviewed.

**Approval:** pending

## Addendum — Plan 175-56 local reconciliation (2026-10-01)

The Plan 175-55 strategy and per-task table above are retained as historical planning evidence.
Plan 175-55 halted without returned task verification, formatting result, or evidence receipt;
those pending rows are not promoted to passed. D-66 through D-69 replace source execution with a
single local artifact reconciliation. REL-13 and REL-17 remain open and the release hold remains.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure behavior | Verification type | Automated command / evidence | Status |
|---|---|---:|---|---|---|---|---|---|
| 175-56-01 | 175-56 | 1 | REL-13 / REL-17 (open) | T-175-56-01..05 | Reconcile only the two preserved commit metadata records, current local worktree metadata, and named local phase artifacts. Preserve UNKNOWN absent proof; RESOLVED requires a named positive phase artifact and established fact. Preserve privacy, all dirty files, and the release hold. | Local read-only Git metadata plus report artifact assertion | Use the `175-56-PLAN.md` Task 1 `<automated>` command to require the report sections, exact preserved-commit IDs, exactly one UNKNOWN or RESOLVED boundary, a positive local artifact citation and fact for RESOLVED, OPEN/ACTIVE release truth, and the separate-review/no-authority step in both branches. Compare local pre/post status metadata in the execution context; any unexplained change outside the new report fails the task. | ⬜ pending |

Plan 175-56 has no test, formatter, Mix, application, source-operation, push dry-run, network, CI,
or release command. Its artifact assertion fails on a missing or incomplete report or a prohibited
claim. A missing Plan 55 receipt remains an observation about local evidence, not proof that Task 3
did not run. If no positive local artifact resolves the boundary, the report records UNKNOWN. A
RESOLVED report must cite the artifact and bounded fact that positively establish the boundary.
Either branch stops for separate review with no operation authority. No human UAT checkpoint is
needed for these assertions.

## Addendum — Exact-head evidence collection (2026-10-02)

This addendum supersedes the earlier Plan 175-55/56 scope for the next plan. It aligns with D-77
through D-82 in `175-CONTEXT.md` and the current exact-head findings in `175-RESEARCH.md`.
Planning did not run tests, make GitHub reads, dispatch CI, or perform a release operation.

### Scope and safety

The plan may implement a bounded, read-only exact-head collection for workflow bytes, the exact run
and attempt, complete job roster, required-check observations, and effective required-context
declarations. It may write a new local evidence artifact and lifecycle journal after its own
preflight and exclusive identity checks. It may not rerun CI, invoke a source split or push
dry-run, create or move a tag, merge, consume Gate 2, recover, mutate registries, or publish.
Plan55 remains UNKNOWN; REL-13/REL-17 remain OPEN; candidate readiness remains BLOCKED; the release
hold remains ACTIVE. Remote evidence can be stale or incomplete; this validation contract does not
authorize collection until the plan is separately reviewed.

### Validation strategy for implementation changes

If the plan changes the collector or evidence classifier, use the repository's existing injected
Elixir runner and deterministic fake responses. Validate these properties locally before any
separate live read:

| Contract | Required local evidence | Failure signal |
|---|---|---|
| Exact identity | Mismatched PR, head/base OID, workflow path/ref, run ID, attempt, or status commit is rejected. | Any mismatched identity yields a non-blocking/pass classification. |
| Complete pagination | All pages are followed to `hasNextPage=false`; cursor progress, page count, total count, and unique IDs reconcile. | Missing/repeated cursor, absent page, duplicate node, or total disagreement is accepted as complete. |
| Required check set | `CheckRun` and `StatusContext` required flags and effective branch declarations reconcile; each workflow status binds to the selected attempt. | A missing declaration, unknown required flag, unrelated failed/pending context, or disagreement is ignored. |
| Same-head workflow contract | Workflow content is fetched at the selected immutable head, decoded under strict size/encoding bounds, and its aggregate `needs` graph is checked against the complete observed roster. Persist only digest and parser-derived facts, not raw provider body. | Invalid/oversized content, head mismatch, roster gap, or advisory exception expansion can classify as proven. |
| Aggregate exception | The terminal aggregate can be treated as derived only under every D-76 condition; all independent required jobs pass and parity is the only independent failure. | Any missing, pending, stale, changed, or independent failure is treated as derived. |
| Receipt/lifecycle privacy | New opaque attempt/schema; exact allowed keys; bounded fields; exclusive artifact creation; write/readback validation; ordered lifecycle. | Unknown fields or raw body, argv, token, env, path, stdout/stderr enters durable evidence. |
| Maintainer output | Text and JSON project the same validated classification; status, stable reason, completeness, explicit UNKNOWN, and one safe action; color is optional. | Text and JSON disagree, output depends on color, or a raw provider/process value is displayed. |

Use only bounded values to classify results. Unknown, pending, stale, inaccessible, malformed, or
ambiguous observations remain `UNKNOWN/BLOCKED`; never retry a possibly mutating dispatch. No manual
UAT is needed for machine-verifiable assertions. The execution plan should attach `<fails_when>`
to every automated verification command and should avoid test or formatter execution during this
discussion/planning turn.

### Live evidence checks (only after separate plan review)

At execution, compare the persisted attempt to the live PR head, fetch exact-head workflow bytes,
exhaust run/job and GraphQL check pages, reconcile `totalCount`, and fetch the effective branch
requirements. Bind observed statuses to exact commit/run/attempt identity. A changed PR head or any
incomplete source stops the attempt. Write only a sanitized artifact and lifecycle facts; do not
persist raw API bodies. A successful read proves only the collected repair-evidence predicates at
that observation time. It does not prove release readiness or clear any phase hold.

## Addendum — Plan 175-69 bounded source outcomes (2026-10-02)

This addendum supersedes the D-77–D-83 validation addendum above for the new Plan69 attempt only.
It does not alter the immutable Plan68 v1 artifact, lifecycle, result, or validation history. No
tests or live collection have been run for this follow-up.

### Local contract checks before any new read

| Contract | Required automated assertion | Failure signal |
|---|---|---|
| Eight-source accumulator | Inject a source failure at each fixed stage. Earlier complete facts/counts survive; the failed source is `UNAVAILABLE`; dependent later sources are `NOT_ATTEMPTED`; the request trace stops at the failure. | Any earlier fact is discarded, any dependent request continues, or an unattempted source is reported as complete. |
| Complete source boundary | Complete pages, counts, uniqueness, cursor completion, response shape, exact identities and caps are required before recording normalized facts. | A partial REST/GraphQL response, incomplete page set, duplicate, malformed response, or oversize response is recorded as `COMPLETE`. |
| Closed v2 schema | Exact keys/order and cross-field invariants tie each source state to its safe facts/counts/reason; unknown counts remain `UNKNOWN`. | Extra/raw fields, fabricated zero, invalid reason/state combination, or impossible state ordering validates. |
| Privacy and projection | Canary provider bodies/error text/argv/environment/local path never appear in artifact, lifecycle, text, or JSON; text/JSON are derived from the same validated projection. | Any private canary is persisted or emitted, or the two projections disagree. |
| Fail-closed eligibility | Any `UNAVAILABLE`, `NOT_ATTEMPTED`, stale/changed identity, pending check, mismatch, or ambiguous result keeps the aggregate `UNKNOWN`, candidate BLOCKED, hold ACTIVE, and merge policy UNKNOWN. | Incomplete evidence promotes to a proven/eligible result or changes release disposition. |
| Historical compatibility | The Plan68 v1 artifact and lifecycle still validate with the same digest and the narrow legacy unknown-shape rule. New v2 validation does not accept v1 as v2. | Existing digest changes, v1 validation regresses, or an old artifact can satisfy the new attempt. |
| Lifecycle and one-shot paths | New opaque attempt reservation is durably read back before requests; artifact/lifecycle paths are exclusive and distinct; occupied paths cause zero requests. | A second invocation reuses an attempt/path, or any request precedes verified reservation. |

Run the existing focused runner/evidence ExUnit files and `mix format --check-formatted` on the
changed files. Run the local v2 artifact/lifecycle validator once after collection without calling
the collection task again. Planning must not run those tests or make remote reads. The collection
itself is eligible only after the independent plan review, and is limited to one fresh read-only
attempt under D-86; any uncertain outcome is terminal. No human UAT is needed for these
machine-verifiable contracts.

## Addendum — Plan 175-73 bounded adapter and one-read gate (2026-10-02)

This is the current validation contract for Plan73, revised in place under D-100. It retains the
already-granted read scope for the source, mirror, PR #219, and applicable tag-policy surfaces. No
implementation tests, credential checks, or remote observations ran during planning. The Plan74
tag-write authorization remains a separate later gate.

### Local contract checks before any read

| Contract | Required automated assertion | Failure signal |
|---|---|---|
| Credential boundary | Deterministic fakes prove that absent `CROSSWAKE_PLAN73_READ_TOKEN` causes zero child/API calls and no reservation; alternate token variables and stored login never become fallbacks. | Any external call or lifecycle reservation occurs without the dedicated token, or a token/canary reaches argv, logs, evidence, or output. |
| Bounded production adapter | The fixed source/mirror/PR/tag-policy allowlist, operation/route bounds, output caps, deadlines, page progression, and sanitized outcomes are exercised without a remote call. A required-CI FAILURE remains recorded while tag-prerequisite sources continue. | An unlisted operation, incomplete/repeated page, timeout/overflow, missing fact, or CI observation silently becomes ready/proven. |
| Identity and evidence contract | Fake complete/incomplete/drifted cases cover start/end source, split/tree, mirror refs, PR base/head/tree/version, CI, and complete tag policy; exact Plan73 schema/path/digest/lifecycle validation is checked against Plan74's unchanged validator. | Any identity drift, missing policy, wrong path/schema, occupied pair, persistence ambiguity, or extra/raw key can pass as PREFLIGHT_READY. |
| Inspector and Plan74 compatibility | Fake evidence proves text/JSON parity; lifecycle-only inspection reports outer `TERMINAL_SAFE_STOP` with inner `UNKNOWN_UNVERIFIABLE`; positional `inspect` and `--mode inspect` work; `--require-ready` rejects non-ready evidence. | Either CLI form fails, the status/projection is inconsistent, unsafe data appears, or Plan74's existing command cannot consume the exact valid pair. |
| Syntax and formatting | Run the focused ExUnit file, `mix format --check-formatted` on the owned files, and `node --check` on the collector as listed in Plan73 Task 1. | Any command fails or an owned diff changes unrelated dirty hunks. |

### One-read gate and evidence outcomes

Task 2 checks only token presence before choosing its branch. With no dedicated token, both exact
evidence paths remain absent and the summary records `BLOCKED_CREDENTIAL_UNAVAILABLE`. With the
token present, the executor confirms both paths are absent, creates a short-lived non-secret
Plan72-schema READ authorization record bound to one opaque attempt ID, and invokes the Mix task
once. The coordinator alone validates that record and reserves/readbacks the lifecycle before
external requests; the executor must not reserve separately. Validate the resulting preflight and
lifecycle offline without rerunning the collector. A complete, digest-valid pair may describe only
the tag prerequisite; a persistence or observation failure stays BLOCKED/UNKNOWN, never a release
pass. Preserve REL-13/REL-17 OPEN, candidate readiness BLOCKED, merge-policy UNKNOWN, and the ACTIVE
release hold in every branch. No retry, tag write, CI rerun, merge, recovery, registry operation,
publication, or human UAT checkpoint follows from this plan.
