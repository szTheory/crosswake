# Phase 175: Rehearsal and Publish - Context

**Gathered:** 2026-09-18; decisions updated through 2026-10-05
**Status:** Updated after Plan82 and the post-observation discussion. Plan80 completed its narrow D-104/D-105 matrix and ledger follow-up; entry 36 is fixed after the exact suite and dynamic count gates. Plan79 remains halted and immutable. D-101–D-105 remain in force. D-106's single anonymous readiness observation for PR #219 was consumed and ended UNKNOWN/HTTP_UNAVAILABLE; D-107 keeps the release held until genuinely new independent evidence supplies current, decision-relevant facts for the same exact candidate. Do not retry Plan82, rotate or supply credentials, or substitute a candidate. There is no GSD action until that new signal exists; then replan without repeating this discussion. No CI rerun, merge, Gate 2, recovery, registry action, tag write, or publication is authorized. REL-13/14/15/17 remain OPEN; candidate readiness is BLOCKED; merge-policy is UNKNOWN; the release hold is ACTIVE; Plans 175-45 through 175-48 remain held; Phase 175 remains incomplete.

<domain>
## Phase Boundary

Close the historical release-evidence gap with one fail-closed REL-17 gate shared by linked
release, recovery, and companion-publication paths. Preserve the already-recorded releases and
their evidence. Only after REL-17 is implemented and its exact-candidate evidence passes may a
fresh successor candidate receive a new candidate-specific authorization. The remaining release
bar stays fixed: one ordinary successor run publishes all three core coordinates, passes
exact-public proof, and reports all six core children COMPLETE in that same run; the second held
companion remains a separate authorization and registry fact.

Scope is fixed by ROADMAP.md Phase 175: REL-10 through REL-17, DOC-04, and DOC-06. REL-17 is an
additional release hold over every future linked release, recovery, and companion publication;
the already-merged and published historical events cannot be made compliant retroactively.

**Not in scope:** generic sync/recovery infrastructure, new publication surfaces, or a dashboard.
Keep the existing candidate rehearsal mechanisms and Mix-oriented release status surface. REL-17
adds only the evidence and authorization contract needed to protect the release paths already in
scope. No registry action is authorized by this discussion or context update.

**Current release disposition (2026-10-01):** Preserve the historical `0.2.3`, `0.2.4`, `0.2.5`,
and `0.2.6` outcomes unchanged. The 0.2.6 Gate 2 token is consumed. Plan 175-44 Task 2 halted
because candidate PR #219's required CI failed on missing iOS mirror tag `v0.2.6`; Plans 175-45
through 175-48 remain blocked. Plan 175-49's fresh checkpoint dry-run failed, and later
dry-run-only diagnostics did not refresh its full preflight or digest. Plan 175-50 recorded fresh
source, split, mirror, and PR facts, but its dry-run exit 0 did not prove exactly one accepted
target ref. Its receipt remains `BLOCKED_PREFLIGHT` with zero writes; no tag decision, CI rerun,
merge, Gate 2, or publisher action occurred. Do not resume Plans 175-49/50/51/52, repeat their
ambiguous drivers, reuse any receipt or digest, or rerun Wave 14. Any later tag attempt requires a
newly planned full preflight and fresh digest. REL-17 remains OPEN, the phase exit is unmet, and no
release-side effect is authorized by this context update.

Plan 175-53 then stopped before reservation because the fresh full-clone subtree split did not
produce a usable split OID. Its digest-checked receipt records `BLOCKED_PREFLIGHT` /
`FULL_CLONE_SPLIT_FAILED` at `SOURCE`, successful initial receipt write/readback, zero reserved
dry-run invocations, zero writes, and a null decision. Task 2 was ineligible and the proven
artifact is absent. Do not retry Plan 175-53 or reuse its receipt/digest. The user-approved
source-boundary decisions below guide only a distinct follow-up plan.

Plan 175-54 then made one separately reserved full-clone split attempt and stopped at `SOURCE` with
`NONZERO_EXIT` / `FULL_CLONE_SPLIT_FAILED`, exit status 1, and zero parsed OIDs. Its bounded receipt
records full history, selected source-commit availability, and process start as `TRUE`; its private
command output was not retained, so the underlying cause remains unknown. No preflight, dry-run,
tag write, publication, or release decision followed. Preserve its receipt and summary; do not
replay Plan 175-54 or treat its result as proof of a specific setup, path, or policy defect. The
user-approved D-62 through D-65 below guide only a separately reviewed follow-up and do not
authorize another source invocation.

Plan 175-55 was then interrupted during Task 2 and is terminal as a halted partial attempt. Its
two commits and remaining local edits are preserved. No task verification result, test/format result,
or Plan 175-55 evidence receipt was returned; whether Task 3 began remains unconfirmed. The missing
receipt does not establish that no source operation occurred. Do not replay Plan 175-55, infer a
source result, or reuse any partial state as accepted evidence. The next plan is restricted to
local read-only reconciliation of the preserved commits, working-tree changes, and available local
artifacts. It must not invoke the source operation, a push dry-run, network access, or any release
side effect. If local evidence cannot resolve the attempt boundary, preserve the unknown and stop
for a separately reviewed decision. REL-13 and REL-17 remain open and the release hold remains.

Plan 175-51's single preflight invocation returned only `RECEIPT_WRITE_FAILED`; its transient state
does not establish whether the mandatory dry-run ran. Its separate receipt records
`BLOCKED_PREFLIGHT`, reason `DRY_RUN_FAILED_OR_AMBIGUOUS`, boundary `NONE`, zero writes, and no
decision. Do not retry Plan 175-51's driver or reuse its digest. Any further attempt requires a new
bounded preflight plan and fresh evidence. No tag write, CI rerun, merge, Gate 2, or registry action
occurred.

Plan 175-52's sole reserved dry-run exited 0 and yielded one expected tab-separated new-tag tuple,
but unclassified stdout prevented a complete parse. The digest-bound receipt remains
`BLOCKED_PREFLIGHT` / `DRY_RUN_FAILED_OR_AMBIGUOUS` at boundary `DRY_RUN`, with zero writes, no
decision, and no proven artifact. Do not replay Plan 175-52, repeat its invocation, or reuse its
receipt or digest. The next plan may use the parser and sanitized-receipt contract in D-54 through
D-56 to make a fresh attempt reproducible; it must still gather a complete fresh preflight, reserve
the one permitted invocation durably, and fail closed on any ambiguity. Even a proven dry-run only
permits the separately specified post-observations and independent audit; it does not authorize a
tag write or any other release side effect.

Plan 175-70 then made exactly one authorized read-only collector invocation and exited 1. The local
inspector validates a terminal four-event lifecycle ending in `collection-failed`; the evidence
artifact is absent. This proves the attempt ended, but does not establish which source was reached,
whether any GitHub request occurred, how many requests ran, or why the invocation failed. Do not
retry, repair, or reinterpret the consumed attempt. The next plan is a local-only read of the retained
summary/lifecycle and current runner/evidence code to map possible failure boundaries without
attributing one to Plan70. Because the shared runner/evidence files were already dirty and the
temporary task entrypoint was removed, current source cannot by itself prove the exact code that ran.
No test/formatter run, network access, collector invocation, code change, CI rerun, source operation,
or release action is in this scope. Any later remote observation requires a separate discussion,
plan, independent review, and fresh authority.

</domain>

<decisions>
## Implementation Decisions

### Publish ordering and the fire-drill pick

- **D-01:** PR #147 (`crosswake_rulestead` 0.1.1) is the lower-blast-radius companion and publishes
  FIRST as the fire drill for the repaired clean-room lane. PR #115 (`crosswake_chimeway` 0.1.1) is
  the second companion and publishes LAST, after core `0.2.2`.
  — **Reversibility:** one-way — a Hex publish cannot be withdrawn. `mix hex.retire` sets an advisory
  flag and does not remove the package or version; existing lockfiles continue to resolve it.
  Recovery is retire-forward only.

- **D-02:** "Blast radius" for this pick means impact-if-the-publish-is-wrong, NOT how much of the
  pipeline the drill exercises. Those are separate properties and must not be conflated. The decisive
  signal is Hex download count: `crosswake_rulestead` 75 all-time / 8 this week versus
  `crosswake_chimeway` 106 all-time / 6 this week (checked live 2026-09-18 via
  `curl https://hex.pm/api/packages/<pkg>`). No in-repo reverse dependency exists for either package;
  `crosswake_chimeway`'s `crosswake_sigra` edge is a test-only `path` dep in the opposite direction
  and is irrelevant to chimeway's own blast radius.

- **D-03:** The justification for D-01 must be RECORDED as a planning decision, not treated as
  self-evident. Download count is an acknowledged imperfect proxy: the GitHub dependents graph was
  not queried in any research pass, and Hex's `depends:` search operator returned empty for both
  packages with low confidence in that operator's reliability. Treat "no reverse dependents" as
  "no signal found", not "definitively zero".

- **D-04:** `crosswake_chimeway`'s larger code surface (7 modules / 1291 lines versus rulestead's
  1 module / 202 lines) is explicitly NOT a reason to publish it first. Both companion publish jobs
  are structurally identical — same trigger, same `needs:` graph, Hex-only — so the fire drill
  exercises the publish pipeline, not the package's own code.

- **D-05:** The ROADMAP's ascending-blast-radius ordering is safe exactly as written and needs no
  core-first adjustment. Both companions declare `{:crosswake, "~> 0.2"}` and `crosswake 0.2.1` is
  already live on Hex, so the version floor is already satisfied and neither companion depends on
  `0.2.2` existing first. The prior milestone's core-first lesson (companions failing against an
  UNPUBLISHED core bump) does not apply to this release.

### Blast-radius asymmetry across the three publish waves

- **D-06:** The companion publish jobs are Hex-only. Neither `publish-hex-rulestead` nor
  `publish-hex-chimeway` touches the iOS mirror or Maven, and neither passes through
  `approved-release-guard`. Waves 2 and 4 are therefore single-registry and retire-forward
  recoverable; Wave 3 (core `0.2.2`) is the only leg that opens all three one-way doors at once.
  Planning must NOT apply a uniform risk posture across the three publish waves.

### Human checkpoints on the one-way doors

- **D-07:** Three `checkpoint:decision` gates, one immediately before each irreversible leg — not a
  single gate before the whole publish sequence. A single up-front gate would authorize the Maven
  upload using rehearsal evidence that is stale by the time that leg fires, and would give the
  operator no opportunity to react to what the core `0.2.2` proof lane actually showed.
  — **Reversibility:** one-way — each gate authorizes a registry mutation that cannot be withdrawn.
  Maven Central coordinates are permanent once `PUBLISHED`; Hex versions cannot be removed; an iOS
  mirror tag can be re-pointed but consumers who already resolved it are unaffected by the re-point.

- **D-08:** Each gate requires the operator to type back a DIFFERENT named value read from that leg's
  own evidence — not a shared yes/no confirm. Gate 1 takes the Hex candidate-rehearsal run ID; gate 2
  takes the iOS candidate-rehearsal run ID; gate 3 takes the live `exact-public-proof` run ID. The
  values are deliberately non-fungible so a tired operator cannot satisfy gate 3 from what they typed
  at gate 1. This is the specific mitigation for approval fatigue across near-identical prompts.

- **D-09:** The three gates carry deliberately asymmetric weight, following D-06. Gates 1 and 3 guard
  a single Hex publish with a real retire-forward recovery path and stay light. Gate 2 guards three
  registries simultaneously and carries the full evidence block plus the three-registry
  irreversibility statement.

- **D-10:** Each gate's prompt must state THAT LEG's actual recovery cost in that leg's own terms —
  Hex retire-does-not-remove; Maven free to `DROP` from `VALIDATED` but permanent at `PUBLISHED`;
  iOS tag re-pointable but already-resolved consumers unaffected. The recovery language must be
  generated from, or linked to, the REL-16 response table rather than independently re-derived, so
  the two cannot drift apart.

- **D-11:** Gate evidence must be non-vacuous and named by field, so the checkpoint itself cannot
  become another instance of this milestone's "absence scored as success" defect. Required fields:
  Hex `rehearsal.json` `package_count` reads 6 and `external_state_changed` reads false; iOS
  `mirror.json` `state` reads PASS, `authorization_result` reads PROVEN, `external_state_changed`
  reads false; Maven fire-drill deployment reached `VALIDATED` and was `DROP`ped. Gate 2 additionally
  displays the REL-10 runbook's recorded commit SHA.

- **D-12:** Because three human gates are required, this phase CANNOT run unattended.
  `--no-reversibility-gates` must not be used when planning or executing Phase 175.

### Incident-response documentation

- **D-13:** REL-10 (retire/backfill runbook) and REL-16 (multi-registry partial-failure response
  table) go in ONE new document, `docs/RELEASE-INCIDENT-RESPONSE.md`. They are different jobs but
  share one reader at one moment — "a publish just went wrong, what do I do right now" — and
  splitting them would force a cross-file jump mid-incident.

- **D-14:** That document does NOT go inside `docs/COMPANION-PUBLISH-RUNBOOK.md`. That file is 279
  lines of pre-flight prose (Candidate authority, the seven-step operator sequence, Five states and
  one correction) written for someone preparing a release, not someone already mid-failure. This is
  consistent with how `docs/` already separates standalone topic docs.

- **D-15:** Structure `docs/RELEASE-INCIDENT-RESPONSE.md` table-first with an irreversibility summary
  table above the fold, then `## Mid-sequence partial failure` (REL-16) and
  `## Retire / backfill after a bad publish` (REL-10). No narrative prose sections. Cells cap at one
  line; multi-line commands go in fenced snippets beneath the row they belong to. Heading text must
  stay stable because checkpoint prompts cite GitHub-generated anchors derived from it.

- **D-16:** REL-16's matrix is organized as row-groups BY REGISTRY (Hex, iOS mirror, Maven), each
  carrying the same failure-mode rows, so the asymmetric reversibility is visually block-separated
  rather than interleaved. Failure-mode rows: auth/credential failure before any write; partial
  upload or job failure after partial state change; published successfully but found broken post-hoc;
  version already taken / duplicate-publish attempt; `exact-public-proof` failed after the underlying
  publish succeeded. Columns: Detect | Decide | Command | Irreversibility. The Irreversibility column
  is never omitted, even when the answer is "reversible", and never hedges.

- **D-17:** DOC-04 and DOC-06 both land in `docs/COMPANION-PUBLISH-RUNBOOK.md` as a separate
  "make the doc match live reality" change. DOC-04 deletes the "this pipeline only publishes 0.2.1"
  section outright — deleted, not softened. DOC-06 adds `git subtree split` documentation to that
  file's ordinary-publication and iOS-mirror sections. Per prior research the `splitsh-lite` removal
  is already complete in live code and only the documentation gap remains.

- **D-18:** Archived `.planning/` history must NOT be rewritten to remove residual `splitsh-lite`
  references. DOC-06 covers live documentation only.

- **D-19:** Add a CI check that fails on bare version literals (`0\.\d+\.\d+`) appearing in
  `docs/COMPANION-PUBLISH-RUNBOOK.md` or `docs/RELEASE-INCIDENT-RESPONSE.md` outside code fences, and
  state the invariant "This document makes no version-specific claims" at the top of both. DOC-04
  exists precisely because a version literal was written as though permanent; this makes the
  recurrence structurally hard rather than a thing to remember.

- **D-20:** The iOS mirror's own left-pad lesson is currently documented NOWHERE and must be stated
  explicitly in the new document: re-pointing a mirror tag does not un-resolve consumers who already
  fetched the old commit through SwiftPM's resolved-package cache.

### Wave 0 broken-windows triage

- **D-21:** Wave 0 does the full job: fix `scripts/ci_monitor.cjs` `checkActions()` path discovery,
  add the scope-cardinality gate, AND SHA-pin all 31 mutable action refs. Not discovery-and-gate
  alone with pinning deferred.

- **D-22:** Wave 0 lands as its OWN pull request, merged and fully green, before any Wave 1 task
  begins. This sequencing is what contains the option's only real risk: a bad pin breaks a
  non-publish proof workflow well outside the blast radius of the publish waves.

- **D-23:** The deciding factor is not tidiness. `required-checks-audit.yml:67` reads
  `secrets.BRANCH_PROTECTION_READ_TOKEN` in a job whose `uses:` includes a mutable third-party ref —
  a live, narrow credential-exfiltration path. "These are all just proof and advisory workflows"
  undersells the actual exposure.

- **D-24:** Pinning does not create orphaned pins here. `.github/dependabot.yml` already configures
  `package-ecosystem: "github-actions"` weekly, and bump PRs are already flowing (recent
  `actions/upload-artifact` bumps). A pin without an update path would be a different defect; that
  path exists.

- **D-25:** The scope-cardinality guard is written as a small REUSABLE helper in
  `scripts/ci_monitor.cjs`, not inlined into `checkActions()` alone, so checks added later inherit it
  by construction. `checkActions()` is currently the only function in that file with a
  hardcoded-default-path shape, so there is nothing to reconcile today — the helper is about the next
  one, not this one.

- **D-26:** This stays a separate, narrower check rather than being folded into the PR #173 guard
  (`check_absence_is_not_success.exs`). Verified: PR #173 added `absence.mutation_control_asserts_change`
  and `absence.open_finding_citation_resolves`, neither of which inspects scan scope, and it would NOT
  have caught this defect. #173's family is "the assertion is a no-op on the value it looked at";
  this is "the assertion is correct but the set of things it looked at was truncated". Same
  pathology, structurally different failure mode.

- **D-27:** `checkActions()`'s output line must additionally print the file count it scanned
  (e.g. `files=27`) so scope is visible in every CI log rather than inferable.

- **D-28:** Wave 0's exit criterion, all five independently checkable:
  1. Default no-args `node scripts/ci_monitor.cjs check-actions` reports a scanned-file count equal
     to a freshly-globbed `.github/workflows/*.yml` + `.github/actions/**/action.yml` count — derived,
     never hardcoded.
  2. That same default invocation reports `mutable_refs=0` against the full scope.
  3. The cardinality assertion has itself been exercised against a deliberate regression (narrow the
     glob, assert the check fails) — otherwise the gate is vulnerable to the very defect it guards.
  4. Changes confined to `scripts/ci_monitor.cjs` and the 10 workflow files carrying mutable refs.
     No edits to the 4 already-pinned publish workflows. No CI redesign.
  5. Landed as its own PR, CI fully green, merged before any Wave 1 task begins.

- **D-29:** Anything beyond D-28 is out of Wave 0's scope and belongs in a SEED — specifically,
  auditing whether the pinned SHAs are themselves correct, latest, or uncompromised, and extending
  the cardinality gate to scripts beyond `ci_monitor.cjs`.

### Evidence discipline (applies phase-wide)

- **D-30:** Every success criterion is confirmed by run evidence or a live registry response, never
  by re-reading a workflow definition. This is the milestone's named recurring defect and the reason
  SC6 is worded as it is.

- **D-31:** Success Criterion 7 is TWO independent facts stated together, not one gate the companion
  publish triggers. `exact-public-proof` only ever runs for `package: crosswake` and
  `linked-release-rollup`'s `COMPLETE` has no companion inputs at all. Verify `COMPLETE` once from
  `0.2.2`'s own run, and treat the second companion's Hex registry check as SC7's independent
  confirmation. Do NOT add companion states to the rollup — that would silently widen a check's
  meaning without a requirement behind it.

- **D-32:** REL-11 requires a FRESH rehearsal against the actual `0.2.2` candidate ref. A rehearsal
  that ran for `0.2.1` during Phase 168 does not satisfy REL-11, and the existence of working
  rehearsal mechanisms is not a reason to skip dispatching them.

- **D-33:** Both companion PRs report `mergeStateStatus: BEHIND`. A core candidate rehearsal is
  evidence that the shared release infrastructure is ready; it is not, and cannot be, provenance for
  either independently-versioned companion PR. Before either companion gate, require its current
  `headRefOid`, base SHA, `mergeable`/`mergeStateStatus`, and a successful `Crosswake CI` workflow for
  that head. Record the configured required-check result separately: if `gh pr checks --required`
  reports none, it is policy evidence, not a vacuous passing test. A `BEHIND` PR must be updated with
  its base and have `Crosswake CI` rerun before it can pass the gate. Re-confirm the exact companion
  head and non-`BEHIND` state immediately before merging; record the merge commit separately. Never
  compare a companion head to the core rehearsal head.

### Core-release recovery after the failed closed guard

- **D-34:** Treat the merged but unpublished `0.2.2` intent as failed release preparation, not as a
  partially published release. Do not retry its failed push workflow or any individual registry job:
  the independent checks recorded Hex, iOS, and Maven all absent. — **Reversibility:** one-way — the
  historic merge cannot regain the pre-merge candidate/base relationship required by the authority
  model, and no registry state exists to roll back.

- **D-35:** Create a fresh versioned release candidate rather than reconstructing a canonical receipt
  for the already-merged `0.2.2` candidate. The new candidate must establish its canonical
  Phase-168-style receipt/attestation before merge, bind all rehearsal evidence to its exact remote
  base, head, tree, receipt digest, and workflow identity, and reach the ordinary publish graph only
  after that evidence is fresh. This preserves the fail-closed boundary that found the defect.

- **D-36:** Separate the disposable Maven fire drill from Release Please housekeeping. A rehearsal
  invocation must not advance or replace the candidate pull request; if it can change a release PR,
  it is not safe rehearsal evidence. Enforce this with a regression proof that observes the exact
  candidate PR head before and after the fire drill, plus a structural guard against coupling the
  fire-drill path to mutating Release Please work.

- **D-37:** The existing release gate remains fail-closed: absence of the exact canonical receipt is
  a correct block, never a condition to bypass. The repair must demonstrate a seeded missing-receipt
  failure and a fresh matching-receipt pass before a new Gate 2 is presented.

- **D-38:** Any replacement Gate 2 is a new one-way decision. It must show fresh three-leg evidence
  for the new candidate, the exact remote OIDs and runbook ancestry results, canonical-receipt
  provenance, and independent registry absence. The historical `publish core 35554774599` approval
  is consumed by its failed closed attempt and cannot authorize a new candidate.

### 0.2.4 partial and fresh-successor proof boundary (2026-09-24)

- **D-39:** Keep core `0.2.4` permanently recorded as PARTIAL, with Hex as its only published
  coordinate. Do not recover its missing iOS or Maven coordinates, even after a successor release
  succeeds. The 0.2.4 run skipped exact-public proof, and later recovery cannot make that historical
  ordinary run satisfy the same-run proof contract.

- **D-40:** Retarget corrective planning and the replacement for Plan 175-21 to a fresh successor
  candidate. That candidate's own ordinary release run must publish all three core coordinates and
  execute and pass exact-public proof. Separate recovery jobs cannot contribute to those same-run
  facts. Preserve the six-child COMPLETE linked-rollup requirement from the same run; the later
  companion publish remains an independent fact and gate.

- **D-41:** This context update authorizes no registry action. The 0.2.4 Gate 2 authorization is
  consumed and cannot be reused. Keep the existing distinct, candidate-specific one-way gates and
  their exact-evidence requirements for any fresh successor publication.

- **D-42:** Before a new publication gate is presented, corrective planning must address the two
  observed ordinary-lane failures: the iOS job lacked Mix, and the Maven publication script rejected
  the ordinary 0.2.4 identity against its Phase 168 recovery pin. Prove the repaired paths with
  automated non-publishing checks and safe rehearsals before preparing fresh candidate-specific
  authorization evidence.

### REL-17 evidence, freshness, and operator path (2026-09-26)

- **D-43:** Represent REL-17 with one immutable, per-operation evidence envelope that references
  the canonical candidate-receipt digest and binds the operation (`linked_release`, `recovery`, or
  `companion_publish`), exact candidate identity, and leg-specific run identity. Include all six
  conditions and digests/locations for their source evidence; retain the raw registry response
  beside its explicitly nonempty parsed result. The primary evidence identity is the tuple
  `(receipt_digest, operation, leg_run_id)`, with candidate OIDs as subject data: promote operation-
  bound evidence over a candidate-only key because linked release, recovery, and companion work
  have distinct proofs and authority.
  Keep the pre-merge authorization record separate
  from the post-merge publication envelope: the latter binds the actual merge OID, which cannot
  exist at the earlier decision point. Every irreversible path consumes the same validator and
  evidence contract.
  — **Tradeoff:** this adds a small evidence schema and a second stage of binding, but it prevents
  unrelated logs, stale fields, or path-specific conventions from being mistaken for one complete
  candidate authorization. This follows the subject-digest/provenance model used by
  [SLSA provenance](https://slsa.dev/spec/v1.2/provenance) and
  [GitHub artifact attestations](https://docs.github.com/en/actions/concepts/security/artifact-attestations).

- **D-44:** Re-fetch mutable remote facts at the existing authorization boundary and immediately
  before each side effect; a TTL or a previously green snapshot is not freshness. Immediately before
  authorization, bind the live base/head, merge-readiness, CI result, and required-check policy to
  the candidate. After merge, bind the actual merge OID and verify normal protected-path evidence,
  administrative-bypass rejection, and exact runbook ancestry across the base, approved head, and
  merge before any publisher proceeds. Also require the candidate-bound Hex run and matching
  response-table row. Preserve registry response bytes before parsing, require a nonempty parse,
  and treat API errors, missing fields, pagination gaps, stale identities, policy changes, parse
  failures, or bypass evidence as BLOCKED.
  — **Tradeoff:** an extra live read costs latency and API quota, but avoids stale approval and
  time-window races. GitHub's ruleset and REST interfaces are mutable policy surfaces; pagination
  must be exhausted rather than treating a partial response as complete ([rulesets](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets), [REST rules](https://docs.github.com/en/rest/repos/rules), [REST pagination](https://docs.github.com/en/rest/using-the-rest-api/using-pagination-in-the-rest-api)).

- **D-45:** Keep the existing distinct, candidate-specific one-way authorization decisions. The
  pre-merge decision authorizes only the exact reviewed merge; it does not directly authorize a
  later publisher. The post-merge guard must verify the actual merge OID and full REL-17 envelope
  immediately before Release Please or any recovery/companion publisher can perform an irreversible
  action. A failure produces a fresh blocked result and requires new evidence and authorization;
  no generic retry/resume control or additional human prompt is added.
  — **Tradeoff:** a staged check has more steps than a single green/red gate, but separates facts
  available before merge from facts that only exist after merge without weakening the authority
  boundary or adding approval fatigue.

- **D-46:** Implement the validator as a pure Elixir domain function over explicit evidence data,
  with thin GitHub/registry/workflow adapters and ExUnit positive plus per-field mutation cases.
  Wire the same contract into every release, recovery, and companion path and into the existing
  workflow-integrity check. Keep this operational utility Mix-first; do not add Ecto persistence,
  Plug endpoints, or a Phoenix dashboard without a durable product requirement. Elixir's `Mix.Task`
  is the established interface for this repository's operator commands ([Mix.Task](https://hexdocs.pm/mix/Mix.Task.html)).
  — **Tradeoff:** a pure validator is easy to exercise with complete and deliberately damaged
  evidence, while thin adapters keep remote I/O and YAML details out of the domain rules. Do not
  make shell text parsing the authority; shell helpers must fail on pipeline errors and parsers
  must reject empty/truncated results.

- **D-47:** Until REL-17 closes, the operator surface is read-only and states `BLOCKED` with concise
  missing condition/reason and the safe next step: gather fresh evidence and request a new gate.
  Preserve `PARTIAL` as a historical transaction outcome and `COMPLETE` as the full same-run proof
  state. `READY FOR APPROVAL` is descriptive evidence status, never release permission. Do not
  recommend retry, recovery, or resume by default; do not expose raw registry payloads or sensitive
  candidate material in doctor output, logs, or summaries. Use textual state and accessible
  messages; color may reinforce status but cannot carry it alone. Keep microcopy calm, direct, and
  consistent with the current brand book.

- **D-48:** The phase exit and ordering remain unchanged by REL-17: first close the gate, then
  establish a fresh candidate and authorization, then satisfy the successor ordinary-run and
  second-companion evidence bars in their already-settled separate boundaries. Keep all prior
  `0.2.4` and `0.2.5` PARTIAL records immutable. The consumed `0.2.5` token is not reusable, and
  this context authorizes no external action.

- **D-49:** D-42 records the observed 0.2.4-specific failures; do not carry those exact symptoms
  forward as the current repair list. The 0.2.5 run showed that the iOS publication leg and Maven
  identity path ran, but Maven rejected an extra `candidate-receipt.md` in the artifact roster and
  the iOS clean-room proof failed at `Jason.encode_to_iodata!/2`; Android and exact-public proof were
  skipped. Replan the next safe repair from the normalized 0.2.5 outcome, retaining the same
  non-publishing verification and rehearsal bar before any new authorization.

### Post-175-42 current disposition (2026-09-27)

- **D-50:** The linked-release authorization phrase is derived only from the retained source
  envelope's `identity.leg_run_id` and checked against the same source bytes, result projection,
  pending Gate 2 record, candidate identity, and proposed trailer. The read-only helper
  `script/release_candidate/linked_release_authorization.sh` may render or check that binding; it
  does not authorize, merge, recover, or publish. Plan 175-42 proves the real workflow predicate,
  context loader, and integrity check reject a different rehearsal leg before publisher context is
  emitted.
- **D-51:** The immutable `0.2.6` PARTIAL result and consumed authorization remain historical facts.
  Its trailer named the iOS rehearsal run (`36348273033`), while the operation-bound Hex
  `leg_run_id` was `36348273088`. The passing post-merge capture did not evaluate the raw trailer
  phrase, so it does not convert the failed workflow guard into a pass. Preserve all incident
  evidence and occupied evidence paths; do not retry, recover, rerun, or reuse that token. Any later
  authorization is a separate decision, gated by REL-17 and fresh candidate evidence.
- **D-52:** Plan 175-42 closes only the selector-binding gap. REL-17 and Phase 175 remain open until
  the shared contract, fresh evidence, and fail-closed controls satisfy their existing criteria.
  Replan the next task against the current workstream state and Phase 175 requirements. Do not
  repeat Plan 175-42 or execute superseded Plans 175-39..41. Context capture and planning grant no
  release, merge, recovery, or publication authority.

### Replacement preflight after Plans 175-49/50 (2026-09-28)

- **D-53:** Plans 175-49 and 175-50 remain blocked historical attempts. Do not resume them, repeat
  either attempt's dry-run, or reuse either receipt digest. A replacement plan must gather a new
  complete preflight and calculate a new digest. The direct-Git dry-run passes only when its result
  proves exactly one accepted new `refs/tags/v0.2.6` ref; exit status 0 by itself is insufficient.
  Failed, incomplete, changed, or ambiguous evidence remains `BLOCKED_PREFLIGHT`, records zero
  writes, and exposes no `create_exact_tag` or `hold` choice. Any future one-way action requires a
  separate exact decision bound to the fresh ref, object, and digest. Context and planning grant no
  tag, release, merge, recovery, or publication authority.

### Fresh preflight output contract after Plan 175-52 (2026-09-29)

- **D-54:** Classify stdout with a closed, bounded grammar. Permit zero or one exact
  `To https://github.com/szTheory/crosswake-shell-core-ios.git` line as framing only. Require
  exactly one tab-separated porcelain status row with flag `*`, the fresh expected split object,
  destination `refs/tags/v0.2.6`, and `[new tag]`. Reject every other line, extra or malformed
  status row, nonterminal blank line, invalid/truncated decoding, and output-limit overflow. A zero
  exit code or a matching tuple surrounded by unknown output is not a pass. Do not retry an
  ambiguous invocation.
- **D-55:** Capture stdout and stderr separately. Exit status and complete stdout determine the
  dry-run verdict; nonzero exit always blocks. Stderr is diagnostic-only and is never parsed,
  echoed, excerpted, or persisted: retain only `EMPTY` or `NONEMPTY_UNINTERPRETED`. Nonempty stderr
  alone neither proves nor denies the target-ref result.
- **D-56:** Keep the receipt small, bounded, versioned, and privacy-safe. Record the Git version as
  diagnostic metadata, never as authority; also record parser schema version, expected-banner and
  status-row counts, unexpected/malformed stdout counts,
  truncation/limit state, and the two-state stderr classification, alongside the accepted tuple and
  existing invocation/exit facts. Use fixed low-cardinality block reasons and digest only the
  sanitized canonical receipt. Never persist raw output, snippets, raw command/environment,
  credentials/helper configuration, or hashes of raw output. Keep this a maintainer-facing text/
  JSON evidence path; no Phoenix/Plug/Ecto surface, dashboard, generic release API, retry UI, or new
  permanent CI lane is required. Use explicit words and stable reason codes so status never depends
  on color alone.

These decisions constrain a newly planned evidence-only preflight; they do not modify prior plans,
promote Plan 175-52's receipt, close REL-17, or grant dry-run or release authority.

### REL-17 Planning Outcome — 2026-09-26

The scoped discussion produced eight additive gap-closure plans, 175-34..41, while preserving
Plans 175-01..33 and all release evidence. Scoped GSD review found zero blockers and one nonblocking
scope warning: Plan 175-36 has 11 files overall, divided into three sequential task boundaries of
5/3/5 files. Keep the cohesive cross-path guard in one plan; do not split it solely to satisfy the
warning.

The execution order is: implement the pure contract and fresh evidence adapters (175-34/35); wire
and mutation-prove every existing side-effect path before preparing a new candidate (175-36); gather
fresh candidate/rehearsal evidence (175-37); request one exact core decision, then observe one normal
run (175-38); verify exact-public and all six core children in that same run (175-39); handle only
held PR #115 behind its distinct Gate 3 (175-40); and reconcile the result to the nine-criterion
roadmap (175-41). If held PR #115 cannot be made exact, leave SC-7 open instead of substituting a
new PR. The older 4/8 verification is a dated snapshot of the former eight-criterion roadmap, not a
current score; SC-1 remains the non-closable historical limit and the maximum is 8/9 while it stays
open. Planning and this context grant no external-action authority.

### Current resume after Plans 175-49/50 (2026-09-28)

Plan 175-42's selector repair remains complete but does not close REL-17 or change the historical
`0.2.6` PARTIAL outcome. Plan 175-44 Task 2 halted on candidate PR #219's failed required CI
because the SwiftPM mirror lacks `v0.2.6`; Plans 175-45..48 remain blocked. Plans 175-49 and 175-50
both stopped at a blocked preflight with zero writes. Plan 49's later dry-run diagnostics did not
refresh its full receipt, and Plan 50's exit-0 result did not prove exactly one accepted target ref.
Do not resume either plan, repeat their dry-runs, reuse their digests, or execute Wave 14. The
current workstream `STATE.md` and phase `continue.md` govern position; after this context update,
plan a fresh bounded preflight from current requirements and evidence.

### Claude's Discretion

- Final file naming and internal section ordering within `docs/RELEASE-INCIDENT-RESPONSE.md`, beyond
  the structural constraints in D-15 and D-16.
- Exact wording of the three checkpoint prompts, subject to D-08 through D-11.
- Implementation shape of the `assertFullScope` helper and the version-literal CI check.
- Wave decomposition and task granularity within the structure recorded here.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase inputs
- `.planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/COVERAGE.md` —
  bounded GitHub, Hex, and Maven integration surface with explicit out-of-scope capabilities.
- `.planning/workstreams/quality-ratchet-release/ROADMAP.md` — Phase 175 section: goal, dependency
  bar, one-way-door note, and nine success criteria; it marks the historical Gate 1 breach and
  REL-17 release hold.
- `.planning/workstreams/quality-ratchet-release/REQUIREMENTS.md` §67-79 — exact wording of REL-10
  through REL-17, DOC-04, and DOC-06.
- `.planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-RESEARCH.md` —
  the full research pass. Recommended Wave Structure, Anti-Patterns to Avoid, all 6 Common Pitfalls,
  and the runnable verification commands under Code Examples.
- `.planning/workstreams/quality-ratchet-release/STATE.md` — the active REL-17 release hold and
  current workstream position.
- `.planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/continue.md` —
  current post-Plan-50 handoff and explicit replacement-preflight route.
- `.planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/.continue-here.md` —
  historical no-retry/no-stale-digest boundaries; its Plan59 next-step details are superseded by
  the current Plan70 disposition in STATE.md and ROADMAP.md.
- `.planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-53-PLAN.md`,
  `175-53-SUMMARY.md`, and `evidence/175-ios-tag-026-plan53.json` — the halted attempt's exact
  source boundary, recorded failure class, and immutable no-reservation/no-write outcome.
- `.planning/workstreams/first-b2c-adopter-readiness/STATE.md` — parked adopter lane, external
  blocker, and resume conditions; Phase 175 does not supersede it.
- `.planning/ADR-FIRST-B2C-ADOPTER.md`,
  `.planning/FIRST-B2C-ADOPTER-ADOPTION-BRIEF.md`,
  `.planning/FIRST-B2C-ADOPTER-ROUTE-POLICY-MAP.md`, and `.planning/PROJECT.md` — governing
  infrastructure scope, privacy boundaries, adopter route ownership, and project thesis.

### Release pipeline
- `.github/workflows/release-please.yml` — the release graph. `exact-public-proof` dispatch condition
  (`package: crosswake` only); the `android-publish-fire-drill` job performing a real signed Central
  Portal upload through `VALIDATED` then `DROP`.
- `lib/crosswake/release_candidate/evidence_input.ex` — evidence-input boundary and candidate
  receipt integration precedent.
- `script/check_release_workflow_integrity.exs` — existing fail-closed workflow contract guard.
- `test/crosswake/proof/phase175_runbook_ancestry_test.exs` — exact-object ancestry guard tests and
  mutation-test precedent.
- `.github/workflows/hex-publish.yml` — the `candidate-rehearsal` operation producing
  `candidate-rehearsal-hex`.
- `.github/workflows/ios-mirror-backfill.yml` — the `candidate-rehearsal` operation performing
  `git subtree split` with no push, producing `candidate-rehearsal-ios`.
- `.planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-PUBLISH-LEG-2.md`
  — authoritative Gate 2/failed-guard record: exact merged candidate, failed receipt guard, and
  independent proof that no registry publish occurred.
- `.planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-38-SUMMARY.md`
  — immutable `0.2.6` PARTIAL outcome and consumed Gate 2 record.
- `.planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-42-SUMMARY.md`
  — exact selector-binding repair, read-only boundary, and focused verification.
- `.planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-44-SUMMARY.md` —
  authoritative halt at candidate PR #219's failed required iOS mirror parity check.
- `.planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-49-PLAN.md` and
  `.planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-49-SUMMARY.md`
  — blocked preflight and non-authoritative diagnostic retries; do not resume.
- `.planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence/175-ios-tag-026-repair.json`
  — Plan 49's blocked receipt; its digest is not reusable.
- `.planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-50-PLAN.md`
  and `.planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-50-SUMMARY.md`
  — blocked fresh preflight where exit 0 did not prove the exact one-ref result; historical
  constraints only, not an executable plan or authorization.
- `.planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence/175-ios-tag-026-plan50.json`
  — Plan 50's blocked receipt and non-authoritative digest.
- `.planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-51-PLAN.md`,
  `175-51-SUMMARY.md`, `175-52-PLAN.md`, and `175-52-SUMMARY.md` — halted attempts whose invocation
  evidence and no-replay boundaries constrain any replacement plan.
- `.planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence/175-ios-tag-026-plan51.json`
  and `evidence/175-ios-tag-026-plan52.json` — canonical blocked receipts; neither receipt or
  digest is reusable.
- `.planning/debug/release-please-guard-36352732061.md` — diagnosis of the first failing workflow
  predicate and why the separate post-merge capture did not test the authorization phrase.
- `.planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-REL17-CLOSURE.md`
  — implemented local validator/path-control coverage; read alongside the still-open blocker.
- `.planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-KNOWN-RELEASE-BLOCKER.md`
  — authoritative release hold and REL-17 closure evidence.
- `.planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-RECOVERY-DECISION-DRAFT-0.2.4.md`
  — read-only diagnosis, observed 0.2.4 registry state, proven iOS/Maven failure causes, and bounded
  corrective-planning recommendation; explicitly grants no publish authorization.
- `.planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-SECURITY.md`
  — threat mapping and accepted-historical-exception disposition.
- `.planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-VERIFICATION.md`
  — dated verification snapshot; its 4/8 score and `0.2.5` evidence predate the current `0.2.6`
  outcome and nine-criterion roadmap.
- `.planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-VALIDATION.md`
  — validation contracts, historical plan map, and REL-17 mutation/evidence requirements.
- `.planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-SUCCESSOR-CORE-RUN.md`
  and `175-SUCCESSOR-GATE-2.md` — consumed 0.2.5 token and exact PARTIAL outcome.
- `.planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence/175-fresh-core-release-run-0.2.4.json`
  — normalized identity and outcome for the one authorized ordinary 0.2.4 graph.
- `.planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-21-PLAN.md`
  — the existing version-specific exact-public and six-child rollup plan; replan it for a fresh
  candidate without rewriting the historical 0.2.4 execution record.
- `.planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/.continue-here.md`
  — historical resume note, not the current Plan70 position. Use the active workstream `STATE.md`
  and current `ROADMAP.md` next-action line for the resume position.
- `.github/workflows/exact-public-proof.yml` — the proof lane REL-14 requires to have executed.
- `script/release_candidate/ios_mirror.sh` — mirror evaluator and publish guard; its CLI result
  projection invokes Mix. Its broad shell grep is not an exact porcelain parser and must not be
  treated as proof of one ref; the future parser needs bounded input and a closed grammar.
- `lib/crosswake/release_candidate/mirror.ex` and
  `test/crosswake/release_candidate/mirror_test.exs` — pure Elixir evaluator and fail-closed
  vocabulary precedent; follow the existing functional-core / imperative-shell boundary where it
  fits the isolated dry-run classifier.
- `script/release_candidate/android_publication.sh` — Maven publication/recovery identity checks;
  keep recovery authority distinct from ordinary candidate identity.
- `lib/crosswake/release_candidate/workflow.ex` — `linked-release-rollup`'s six children and the
  `COMPLETE` state definition.
- `script/release_candidate/hex_artifacts.sh` — the `hex.publish --dry-run` and `hex.build` calls.
- `docs/release-ledger/RELEASE-LEDGER.jsonl` — recorded release evidence schema.

### Documentation targets
- `docs/COMPANION-PUBLISH-RUNBOOK.md` — 279 lines. Carries DOC-04's deletion target and DOC-06's
  `git subtree split` gap. Its existing structure is the main constraint on D-13/D-14.
- `docs/RELEASE-INCIDENT-RESPONSE.md` — incident-response authority for REL-10 and REL-16.

### Wave 0
- `scripts/ci_monitor.cjs` — `checkActions()` at ~lines 269-302, the hardcoded three-path default
  that is the subject of D-21 through D-28.
- `.github/dependabot.yml` — the existing `github-actions` weekly config that makes pinning
  maintainable.

### Project standards
- `brandbook/BRAND-SPEC.md` — current brand/voice reference; it supersedes older brandbook content.
- `prompts/crosswake-elixir-oss-dna.md` — OSS citizenship and release standards.
- `prompts/crosswake-research-synthesis.md` — research quality, source evaluation, and coherent
  recommendation standards.
- `prompts/crosswake-gsd-project-brief.md` — project vision and engineering standards.
- `prompts/crosswake-integrations-and-companions.md` and `prompts/new elixir oss lib prompt.txt` —
  ecosystem integration, package ergonomics, and Elixir library expectations considered during
  the discussion.

### Plan 175-54 source-boundary diagnosis
- `.planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-54-SUMMARY.md` — Plan 175-54's terminal `NONZERO_EXIT` result and exact stop boundary.
- `.planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence/175-ios-tag-026-plan54.json` — canonical sanitized receipt; source cause remains unknown.
- `script/release_candidate/ios_mirror.sh` — existing Git/Mix adapter boundary and unchanged subtree split contract.
- `lib/crosswake/release_candidate/ios_tag_source_evidence.ex` and `test/crosswake/release_candidate/ios_tag_source_evidence_test.exs` — pure bounded classifier, receipt validator, and synthetic fixture pattern.
- `lib/mix/tasks/crosswake.release.status.ex` — current Mix text/JSON and exit behavior for read-only release status.
- `brandbook/BRAND-SPEC.md` — ratified current voice and error-copy rules; supersedes `prompts/crosswake-brand-book.md`.

### Plan 175-69 review and follow-up
- `.planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-69-PLAN.md` — local v2 source-outcome contract and its one-attempt boundary.
- `.planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-69-SUMMARY.md` — immutable record of the consumed attempt and post-review local remediation; no cause or request count is inferred.
- `.planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-REVIEW.md` and `175-68-REVIEW.md` — current resolved Plan69 findings and the preserved prior Plan68 review.
- `lib/crosswake/release_candidate/ios_tag_source_runner.ex`, `lib/crosswake/release_candidate/ios_tag_source_evidence.ex`, and their focused ExUnit files under `test/crosswake/release_candidate/` — injected request boundary, closed evidence classifier, lifecycle validator, and regression coverage.
- `prompts/new elixir oss lib prompt.txt` — maintainer's OSS and DX priorities; use only where they agree with current project decisions and the newer `brandbook/BRAND-SPEC.md`.

### Plan 175-70 collection outcome and local diagnosis
- `.planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-70-SUMMARY.md` — terminal disposition of the single Plan70 invocation; exit 1, no artifact, no source outcome/request count/cause inference, and active release hold.
- `.planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence/175-plan70-source-outcomes.lifecycle.jsonl` — validated four-event lifecycle ending in `collection-failed`; it is the only Plan70 machine evidence.
- `lib/crosswake/release_candidate/ios_tag_source_runner.ex` — current Plan70 collector, catch boundary, local disposition inspector, and text/JSON projection; current worktree contents do not prove which execution-time path fired.
- `lib/crosswake/release_candidate/ios_tag_source_evidence.ex` — bounded Plan70 outcome schema, validator, and output projection.
- `script/release_candidate/ios_tag_source_collector.mjs` — injected GitHub CLI request boundary used by the collector.
- `test/crosswake/release_candidate/ios_tag_source_runner_test.exs` and `test/crosswake/release_candidate/ios_tag_source_evidence_test.exs` — existing fake-source and terminal lifecycle coverage; inspect without running in the local-diagnosis scope.

### External protocol references
- `https://git-scm.com/docs/git-push` — documented porcelain status contract, push exit status,
  and `--dry-run` semantics.
- `https://github.com/git/git/blob/master/transport.c` and
  `https://github.com/git/git/blob/master/t/t5411/test-0001-standard-git-push--porcelain.sh` —
  Git's porcelain framing and upstream output-format examples.
- `https://git-scm.com/docs/gitprotocol-pack` — protocol progress/error channel context used to
  keep stderr separate from verdict-bearing stdout.
- `https://github.com/git/git/blob/master/contrib/subtree/git-subtree.adoc` — `git subtree split` contract and success output; it defines no machine-readable failure taxonomy.
- `https://git-scm.com/docs/git-cat-file` and `https://git-scm.com/docs/git-rev-parse` — local object/tree and repository-state checks for a read-only readiness gate.
- `https://hexdocs.pm/elixir/System.html#cmd/3` — argument-list process invocation and exit-status boundary for Elixir.
- `https://hexdocs.pm/mix/Mix.Shell.html` — separate human information/error output at Mix task boundaries.
- `https://mix.hexdocs.pm/Mix.Task.html` — Mix task lifecycle and maintainer-command boundary.
- `https://cli.github.com/manual/gh_help_exit-codes` — GitHub CLI's bounded exit-code vocabulary; exit 1 is a generic error, not source attribution.
- `https://docs.github.com/en/rest/using-the-rest-api/using-pagination-in-the-rest-api` — paginated reads; one CLI invocation can entail multiple API requests.
- `https://docs.github.com/en/rest/using-the-rest-api/rate-limits-for-the-rest-api` and `https://docs.github.com/en/graphql/overview/rate-limits-and-query-limits-for-the-graphql-api` — REST and GraphQL request budgets for any separately planned future read.
- `https://docs.github.com/en/rest/actions/workflow-runs` and `https://docs.github.com/en/rest/branches/branch-protection` — endpoint-specific permission boundaries for any future read plan.
- `https://developer.hashicorp.com/terraform/plugin/framework/diagnostics` — a successful maintainer-tool precedent for concise diagnostic summaries and details; apply only the task-focused shape, not raw provider output.
- `https://logger.hexdocs.pm/Logger.html` and `https://telemetry.hexdocs.pm/` — Elixir logging and instrumentation surfaces; neither is justified for this one-off collector without a recurring contract.
- `https://sre.google/sre-book/monitoring-distributed-systems/` — operational signal design; useful for recurring low-cardinality signals, not a reason to add monitoring to a bounded maintainer command.
- `https://github.com/actions/checkout` — widely used CI checkout behavior; full history is an explicit `fetch-depth: 0` setting.
- `https://github.com/hexpm/hex/blob/main/CHANGELOG.md` — machine-readable output convention: warnings stay off JSON stdout.
- `https://slsa.dev/spec/v1.2/build-provenance` and
  `https://opentelemetry.io/docs/specs/semconv/general/recording-errors/` — bounded provenance and
  low-cardinality error-classification guidance informing the sanitized receipt shape.
- `https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets` — GitHub's available tag rules, relevant to a fresh tag-operation preflight.
- `https://github.com/googleapis/release-please/blob/main/README.md` and
  `https://github.com/changesets/changesets/blob/main/docs/command-line-options.md` — established
  release tooling keeps tag/release lifecycle steps explicit; neither supplies authority for this
  repository's mirror operation.

### Plan 175-78 scanner blocker and follow-up
- .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-78-SUMMARY.md — Plan78 halted after the scanner stopped at a missing input; local process/matrix checks and remaining unknowns are recorded here.
- .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-78-REL17-PATH-MATRIX.md — sanitized per-publisher proof states; UNKNOWN cells are not promoted by local file presence.
- .planning/WINDOWS.md — open entry 36 records the unrun workflow-integrity verification.
- script/release_candidate/assert_candidate_receipt_artifact.sh — currently present but untracked; treat as a candidate input, not tracked project truth.
- script/check_release_workflow_integrity.exs — reads the helper before its REL-17 checks and checks the exact receipt roster/order.
- test/crosswake/proof/phase175_release_recovery_test.exs — existing exact-roster, missing/extra/nested-file, and symlink rejection cases.
- test/crosswake/release_candidate/workflow_test.exs and .github/workflows/release-please.yml — existing caller contract and receipt validation before publication credentials.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `script/release_candidate/linked_release_authorization.sh` — read-only renderer/checker that binds
  the Gate 2 phrase to exact retained envelope bytes and the source-bound Hex leg ID.
- `Crosswake.ReleaseCandidate.EvidenceGate` and `EvidenceLive` — shared operation-bound validator
  and live evidence adapter; reuse their current contracts rather than adding a second authority
  model.
- `test/crosswake/proof/phase175_linked_authorization_test.exs` and the existing REL-17 wiring,
  recovery-path, and publish-path tests — exercise real consumers and mutation guards.
- `Crosswake.ReleaseCandidate.Mirror.evaluate!/1` with `script/release_candidate/ios_mirror.sh` and
  `test/crosswake/release_candidate/mirror_test.exs` — reuse the closed mirror-state vocabulary and
  fail-closed regression patterns. The existing publish adapter rehearses a two-ref atomic update;
  it does not prove the one-ref historical tag-repair dry-run.

- script/release_candidate/assert_candidate_receipt_artifact.sh — an untracked workspace candidate
  that enforces the three-file receipt roster and rejects symlinked members; the existing test and
  scanner define its expected call boundary, but it has not been verified in this discussion.

### Established Patterns
- Bind authorization to immutable operation evidence and re-fetch mutable GitHub/registry facts at
  the existing authorization and immediately before each side effect.
- Prove workflow contracts with actual predicates plus per-path guard-removal mutations; synthetic
  evidence tests do not authorize live release actions.
- Keep pre-merge authorization evidence separate from post-merge evidence that binds the actual
  merge OID. Preserve BLOCKED/PARTIAL/COMPLETE as distinct states.

### Integration Points
- `.github/workflows/release-please.yml` validates the protected merge trailer's exact linked-release
  phrase against `leg_run_id` before the REL-17 context handoff and any publisher.
- `script/check_release_workflow_integrity.exs` verifies gate wiring and ordering across linked
  release, recovery, and companion publishers; Plan 175-42 raised the exact roster to 98 checks.
- The shared validator is wired to existing release, recovery, companion, and final script mutation
  boundaries. Read `175-REL17-CLOSURE.md` together with the current workstream state: local controls
  do not by themselves close the fresh exact-candidate release hold.
- `.planning/workstreams/quality-ratchet-release/STATE.md` and phase `continue.md` are the current
  route for next steps; generic progress currently points to stale Phase 169 verification data.

### Current failure evidence
- PR #215 / `0.2.6` merged at `998742856a37a97ae7247f6c532f9c154ea20885`; its only Release Please
  run `36352732061` failed at the linked authorization phrase guard before publishers. Direct
  observations found Hex and Maven HTTP 404 and no iOS `v0.2.6` tag. The Gate 2 token is consumed;
  preserve the PARTIAL result and do not retry, recover, rerun, or reuse its authority.
- The failed trailer named iOS rehearsal run `36348273033`, but the source-bound Hex `leg_run_id` was
  `36348273088`. The separate post-merge REL-17 capture passed without checking the raw phrase.
  Plan 175-42 now checks exact phrase derivation and same-leg equality before workflow context is
  emitted; it did not change the historical outcome.
- Plan 175-42's local verification passed: 18 focused ExUnit cases, shell syntax, actual workflow
  predicate and loader checks, and the 98/98 workflow-integrity scan. No candidate, authorization,
  merge, recovery, or publication was created.
- Plans 175-49 through 175-52 stopped before public writes. Plan 49's fresh dry-run failed; later
  diagnostics did not refresh the full preflight. Plans 175-50 and 175-52 exited 0 without proving
  that the complete stdout was exactly one accepted target-ref result. Plan 175-51 returned
  `RECEIPT_WRITE_FAILED`, leaving the transient dry-run state unknown. All receipts are blocked, no
  tag decision was offered, and any replacement attempt needs a new plan, complete fresh preflight,
  and new digest.
- Plan 175-52 established the concrete parse failure: its one expected tuple was not enough while
  additional stdout remained unclassified. The accepted grammar, stderr policy, and bounded receipt
  fields are D-54 through D-56. Raw streams remain absent from durable evidence.
- Plan 175-54 independently stopped at `SOURCE` with `NONZERO_EXIT`, exit status 1, and zero parsed
  OIDs after a process-started full-clone split attempt. Its bounded receipt confirms full history
  and selected-commit availability, but not the package-prefix tree; private output was not retained,
  so the cause remains unknown. No follow-on preflight or side effect ran. Preserve this result and
  do not replay it; D-62 through D-65 govern only a separately reviewed follow-up.
- Plan 175-70's single collector invocation exited 1. Its four-event lifecycle ends with the generic
  `collection_failed` reason and its artifact is absent, so source outcomes, request count, and cause
  remain unknown. The current runner has broad rescue/catch boundaries that can produce that same
  terminal classification; this explains a possible loss-of-attribution path, not what happened in
  the consumed invocation. The shared runner/evidence files were already dirty during Plan70, so do
  not infer execution-time behavior from today's worktree alone.

### REL-17 implementation boundary
- `175-KNOWN-RELEASE-BLOCKER.md` defines the six-condition fresh exact-candidate release hold.
  Plans 175-34..36 and 175-42 added the shared contract, live/path guards, mutation coverage, and
  authorization-selector repair; REL-17 remains explicitly OPEN in the active workstream state.
- Do not infer closure from the local validator, a passing synthetic case, or the Plan 175-42
  selector test. Plan 175-54 adds a separate source-boundary diagnosis task before any future
  replacement preflight. That follow-up requires its own review and plan; this discussion does not
  authorize another split invocation, tag operation, or release action. Keep every action behind
  its own evidence and authorization boundary.
- The existing release-status/Mix surface is sufficient. There is no user-facing Phoenix, Plug, or
  Ecto requirement in this release-authorization task. The dry-run classifier is a low-frequency
  maintainer tool: prefer direct, stable text/JSON diagnostics and explicit fail-closed codes over
  a new product surface.

</code_context>

<specifics>
## Specific Ideas

- Keep the three checkpoint prompts visibly leg-specific rather than three renderings of a
  template — leg 1 states Hex retirability, leg 2 states three-registry exposure with Maven
  permanence called out, and the final core leg states the exact fresh successor identity and
  independently observed registry status with timestamps. These are display constraints for any
  future authorized run, not current permission to publish.
- The Irreversibility column's register: short declarative sentences, bold on the fact that must not
  be missed, and no hedging words ("may", "should consider") ever.
- Borrow PEP 592 / crates.io yank phrasing as the plain-English gloss for Hex retirement — "not
  selected by default resolution, but existing lockfiles still work."

</specifics>

<deferred>
## Deferred Ideas

- [Resolved 2026-09-26; see addendum below] Reconcile stale `.continue-here.md` resume metadata and
  the missing root `.planning/HANDOFF.json` as workstream-scoped GSD bookkeeping. This does not
  widen Phase 175 or change its release hold.

- Generating the version-specific parts of the release docs from `RELEASE-LEDGER.jsonl` — the ledger
  already has the right shape, but this is a codegen investment disproportionate to Phase 175's docs
  scope. Backlog.
- A docs freshness test asserting documentation claims against live registry state — catches semantic
  drift rather than just literal version numbers, but needs scheduled network calls in CI. Belongs in
  a future docs-freshness phase, not in the one-way-door phase.
- Auditing whether the SHAs pinned in Wave 0 are themselves correct, latest, or uncompromised — a
  separate audit step, SEED candidate per D-29.
- Extending the scope-cardinality gate beyond `scripts/ci_monitor.cjs` to other checks in the repo —
  SEED candidate per D-29.
- Querying the GitHub dependents graph to put the companion blast-radius comparison on a firmer
  footing than Hex download counts — would retire Assumption A1 but requires scraping; not needed to
  proceed.

</deferred>

### Addendum — Plan 175-53 source-boundary decisions (2026-09-29)

Three `gsd-advisor-researcher` agents examined source-failure handling, the stop boundary, and safe
failure evidence. The user approved this coherent recommendation set as written. The decisions are
additive to D-53 through D-56 and guide a new plan; they do not reopen or promote historical plans
or receipts, close REL-13/REL-17, or grant tag-write, merge, Gate 2, recovery, or publication
authority.

| Decision area | Selected direction | Main tradeoff |
|---|---|---|
| Source failure handling | Keep the terminal outcome at boundary `SOURCE` with `FULL_CLONE_SPLIT_FAILED`. Classify from bounded facts: invocation failure versus nonzero exit versus invalid/missing OID, plus exit status when available and explicit full-history/commit-availability checks. | More structured classification work, in exchange for actionable diagnosis without mislabeling a source failure as a dry-run failure. |
| Repair and stop rule | Use one new isolated full-clone attempt. Permit at most one narrowly scoped local correction only when facts prove a clone or invocation setup defect; otherwise stop and plan a reviewed source/path/policy correction. Do not add automatic retries or alter the split algorithm. | May require another planned evidence cycle, but each result remains attributable and cannot silently cross a one-way boundary. |
| If the source split passes | Start a fresh, complete read-only preflight with a new digest. Reserve durably before at most one authenticated `git push --dry-run --porcelain`, and only if every gate passes; then collect planned post-observations and audit. No retry, tag write, merge, Gate 2, or publication authority follows. | Repeats mutable preflight reads, but gives the result one coherent evidence chain rather than promoting stale diagnostics. |
| Failure evidence and privacy | Persist only fixed low-cardinality classifications, exit status, normalized Git version, and bounded boolean/count checks. Never persist or print raw stdout/stderr, arguments, environment, local paths, remote details, credentials, or raw-output hashes. | Less forensic detail in one receipt; safer, stable diagnostics that cannot become an accidental log sink. |
| Maintainer experience | Report a stable reason code and one safe next action in the existing text/JSON surface. Treat this as release CLI/evidence work, not a Phoenix, Plug, Ecto, dashboard, or product-UI feature. | Keeps this rare release task simple and avoids creating another authority or state surface. |

The ecosystem guidance supports checking the actual isolated clone: `actions/checkout` defaults to
shallow history unless configured for full history, and Git subtree split derives its commit from
the selected history and options. Keep command execution at the Mix shell boundary and make any
classification pure and deterministic. No permanent CI lane is recommended unless later evidence
shows a recurring defect.

Research references: [actions/checkout full-history option](https://github.com/actions/checkout#fetch-all-history-for-all-tags-and-branches),
[Git subtree](https://github.com/git/git/blob/master/contrib/subtree/git-subtree.adoc),
[Elixir `System.cmd/3`](https://hexdocs.pm/elixir/System.html#cmd/3), and
[Mix shell process](https://hexdocs.pm/mix/Mix.Shell.Process.html).

- **D-57 — Preserve and classify the source-boundary failure.** Keep the Plan 175-53 outcome at
  `SOURCE` / `FULL_CLONE_SPLIT_FAILED`. A new diagnostic attempt may distinguish invocation
  failure, nonzero exit, and invalid or missing split OID using bounded fields, with exit status
  when available and explicit full-history and commit-availability checks. Unknown facts remain
  unknown; do not reinterpret this as a dry-run failure.
- **D-58 — Bound recovery to one isolated attempt.** Plan one new isolated full-clone attempt. Allow
  at most one narrowly scoped local correction only if the bounded evidence proves a clone or
  invocation setup defect. Otherwise stop and require a reviewed source, path, or policy correction.
  No automatic retry, repeated driver invocation, or split-algorithm change.
- **D-59 — Require a fresh evidence chain before any dry-run.** If the split succeeds, the new plan
  must begin a complete fresh read-only preflight and calculate a new digest. Persist the durable
  reservation before no more than one authenticated `git push --dry-run --porcelain`, and invoke it
  only after every preflight gate passes. Then perform the plan's post-observations and independent
  audit. A passing dry-run grants no tag-write, merge, Gate 2, recovery, or publication authority.
- **D-60 — Keep the failure receipt bounded and private.** Persist only fixed low-cardinality
  classifications, nullable exit status, normalized Git version, and bounded boolean/count facts
  for history, source commit, OID, and split availability. Preserve unknown separately from false.
  Never print or persist raw stdout/stderr, command arguments, environment, local paths, remote
  details, credentials, helper configuration, or hashes of raw output. Keep the receipt versioned
  and digest only its sanitized canonical representation.
- **D-61 — Keep maintainer diagnostics user-centered and proportionate.** Use the existing
  maintainer text/JSON surface to show a stable reason code and one safe next action. Keep command
  execution at the Mix/shell boundary and classification pure and deterministic where applicable.
  This does not warrant Phoenix, Plug, Ecto, a dashboard, generic release API, retry UI, or permanent
  CI lane absent evidence of a recurring contract. Use explicit wording; never rely on color alone.

### Addendum — Plan 175-54 source diagnosis (2026-09-30)

Three `gsd-advisor-researcher` agents compared source-boundary preconditions, failure diagnostics,
and maintainer-facing output. The user approved their reconciled recommendation. These decisions
guide only a separately reviewed follow-up plan; Plans 175-49 through 175-54 remain terminal and
excluded from replay. This discussion does not authorize another split invocation, tag operation,
merge, Gate 2, recovery, or publication.

**Maintainer job:** When one release-evidence source operation fails, the maintainer needs to know
which bounded preconditions were actually established, what process result was observed, what remains
unknown, and the single safe next review step. Inputs are local Git capability/history/object checks
and the existing sanitized receipt. Output is a stable explanation, not raw backend details or an
inferred root cause.

| Approach | Pros | Cons / failure modes | Decision |
|---|---|---|---|
| Keep result-only `NONZERO_EXIT` classification | Smallest and already truthful; avoids interpreting output. | Leaves even directly checkable setup conditions unrecorded, so predictable problems can remain opaque. | Preserve as the fallback when bounded evidence cannot explain more. |
| Parse allowlisted Git stderr or the last human-readable line | Can appear more specific for known versions and messages. | Git prose is not a stable protocol; version/localization changes, partial output, and unrelated stderr can misclassify. Output can expose local paths, remote details, or credential-helper context. | Reject. Never infer cause from raw Git text. |
| Run bounded pre-reservation readiness checks, then preserve an opaque result if split still fails | Records direct facts independently of Git's prose; blocks before reservation if required facts are false or unknown; keeps uncertainty honest. | Adds a few checks and still cannot guarantee `git subtree split` will succeed. | Select. |
| Project one fixed explanation from the canonical sanitized receipt | Keeps text and JSON consistent, actionable, and user-centered. | Cannot provide raw forensic detail; maintainers may need a separately authorized diagnostic investigation. | Select. |
| Add a second taxonomy, generalized Git abstraction, dashboard, or permanent CI lane | Could scale if this becomes a recurring product contract. | Adds public concepts, authority/state surfaces, or maintenance cost without evidence of recurring use. | Defer unless recurrence is demonstrated. |

- **D-62 — Check required source facts before reservation.** In the separate follow-up plan,
  verify the `git subtree` command is available, the isolated clone has full history, the selected
  source commit is available, and the package-prefix tree exists at that commit. Record each check
  as true, false, or unknown. False or unknown blocks before reservation; passing checks do not
  guarantee that the split will succeed.
- **D-63 — Preserve the one-shot source operation and its attribution.** If all required checks
  pass in that reviewed plan, retain the existing subtree split algorithm, arguments, selected
  source, and stop rule; invoke it no more than once. Keep command execution at the Elixir Mix/shell
  boundary with explicit arguments and working directory. If code changes are justified, use a
  private process seam and pure classifier rather than a public Git abstraction. No retry, algorithm
  change, or continuation into a release side effect follows from this discussion.
- **D-64 — Never infer a cause from Git's human output.** Do not parse or retain human-readable
  diagnostics, and never display or persist raw stdout/stderr. Permit only the narrow, transient
  parsers clarified below for the documented successful split OID and D-54 porcelain protocol; keep
  stderr opaque. A nonzero exit without a direct bounded explanation remains `NONZERO_EXIT` with
  cause unknown. Preserve unknown separately from false, and do not expose arguments, paths,
  environment, remotes, credentials, or raw-output hashes in durable evidence or operator output.
- **D-65 — Explain the known facts and one safe next step.** Project the existing validated receipt
  into the existing text and JSON surfaces: stable reason and stage, source result, exit status when
  observed, explicit cause-unknown wording when applicable, and one next action (`REVIEW_SOURCE_SETUP`).
  Keep the wording calm, specific, and aligned to `brandbook/BRAND-SPEC.md`; color must not carry
  meaning alone. Add no UI, new taxonomy, or permanent CI lane without a recurring contract.

**D-64 clarification approved by the user (2026-09-30):** the earlier blanket wording was broader
than the machine evidence chain requires. The sole outcome-bearing exceptions are transient, strict
parsing of (1) a successful `git subtree split` result as exactly one documented full object-ID token
(with only its terminal line ending) after exit status zero, and (2) the complete D-54
`git push --dry-run --porcelain` grammar. Any extra, malformed, truncated, or invalidly decoded
bytes block and are discarded; stderr is never parsed. The already-required D-56 normalized
`git --version` diagnostic field may use only its exact bounded version grammar and cannot decide
the dry-run verdict. D-62 preconditions use filesystem facts or exit statuses; do not parse their
stdout or retain probe output. Reduce accepted values immediately to validated fields; raw streams
never enter a receipt, digest, log, or operator output. This clarification creates no additional
release authority.

The ecosystem lesson is to validate the environment directly at the boundary where the operation
runs: common Actions checkouts are shallow by default unless configured for full history, while
`git subtree split` needs the relevant history and prefix at the selected commit. Elixir's
`System.cmd/3` provides an argv-based process boundary; the established functional-core /
imperative-shell pattern keeps classification deterministic and easy to exercise. Parse only the
strict machine result needed to bind the next step; discard bytes immediately and never infer a
cause from human prose. This is maintainer CLI/evidence work, so Phoenix, Plug, Ecto, and graphical
UI design do not apply.

Research references: [Git subtree documentation](https://github.com/git/git/blob/master/contrib/subtree/git-subtree.adoc),
[Git `rev-parse`](https://git-scm.com/docs/git-rev-parse),
[Git `cat-file`](https://git-scm.com/docs/git-cat-file),
[actions/checkout full-history guidance](https://github.com/actions/checkout#fetch-all-history-for-all-tags-and-branches),
[Elixir `System.cmd/3`](https://hexdocs.pm/elixir/System.html#cmd/3), and
[Mix process shell](https://hexdocs.pm/mix/Mix.Shell.Process.html).

### Addendum — Plan 175-55 disposition and next-step boundary (2026-10-01)

The user selected the local-only follow-up after parallel architecture, release-safety, and
developer-experience research. This decision narrows the immediate next step; it does not reopen
terminal plans, resolve the unknown Task 3 boundary, close REL-13/REL-17, or grant a source or
release operation.

- **D-66 — Preserve Plan 175-55 as an unknown partial attempt.** Keep its two commits, remaining
  working-tree changes, and halted summary intact. No verification or formatting result and no
  evidence receipt were returned. Whether Task 3 began remains unknown; absence of a receipt is not
  evidence that the source operation did not run. Never replay Plan 175-55 or infer an outcome.
- **D-67 — Make the immediate follow-up local and read-only.** The next plan may reconcile the
  preserved commits, current working-tree state, and available local artifacts. It must not edit
  implementation files, run tests or formatters, invoke a source operation or `git push --dry-run`,
  access the network, or perform a release-side effect. Preserve unrelated dirty workspace state.
- **D-68 — Stop if evidence cannot resolve the boundary.** If local artifacts do not establish what
  happened in the interrupted attempt, keep that fact unknown and stop. Any later source invocation
  requires a separate review after this reconciliation; prior D-62 through D-65 constraints do not
  authorize an invocation from this local-only plan.
- **D-69 — Keep release truth unchanged.** REL-13 and REL-17 remain open, the release hold remains,
  and no source retry, dry-run, tag write, merge, Gate 2, recovery, registry action, or publication
  is authorized.

The cross-ecosystem release-tool lesson supports this boundary: Hex and Cargo expose publish
dry-runs that validate package preparation without publishing, while Git documents that
`git push --dry-run` does not send updates and `--porcelain` provides a machine-readable status.
Those are useful explicit gates when their invocation is authorized, but they cannot resolve
whether a different interrupted invocation already occurred. Do not infer success from exit status
alone or treat the words “dry run” as a universal guarantee; use each command's documented contract.

For implementation choices, keep the established Mix-oriented text/JSON surface. Elixir's
`System.cmd/3` is the existing argv-based shell boundary, with domain classification kept separate
from process invocation. No new Phoenix, Plug, Ecto, dashboard, generic release API, or UI is
warranted. Maintainer-facing output should preserve bounded facts, distinguish unknown from false,
and give one safe next action without exposing raw process output. Graphic design is not applicable
to this CLI/evidence-only phase; the current `brandbook/BRAND-SPEC.md` remains the voice reference.

Research references: [Mix tasks](https://mix.hexdocs.pm/main/Mix.Task.html),
[Elixir `System.cmd/3`](https://hexdocs.pm/elixir/System.html#cmd/3),
[Hex publish dry-run](https://hex.hexdocs.pm/Mix.Tasks.Hex.Publish.html),
[Cargo publishing](https://doc.rust-lang.org/cargo/reference/publishing.html), and
[Git push `--dry-run` / `--porcelain`](https://git-scm.com/docs/git-push).

### Addendum — Post-reconciliation recovery review (2026-10-01)

After Plan 175-56, parallel architecture, boundary, and recovery-automation reviews confirmed
that Plan 175-55 Task 3 remains UNKNOWN: no local artifact establishes whether its one-shot source
evidence action began. Preserve the partial work and do not replay Plans 175-49 through 175-55.

Fresh read-only observations on 2026-10-01 confirm the source tag
`ios-core-v0.2.6` still resolves to `998742856a37a97ae7247f6c532f9c154ea20885`; the iOS mirror
has `v0.2.5` at `424ab96ede1b92f2b751b54bce04c6e607f0f3c8` and still has no `v0.2.6`. PR #219
remains open at head `696a27a3be1fcd56efe70923dc0ce286a1c41c6d`; its only failing required check
is `ios-mirror-parity-proof` in the previously recorded run. These observations are point-in-time
and must be refreshed before any later decision or action. The parity script proves tag existence,
not split-SHA identity.

- **D-70 — Harden the local source and operator paths first.** A new local-only plan may fix the
  collector's oversized-input path so it rejects before child dispatch, with a fake-child
  regression check; and replace the parity script's unsupported `ios-mirror-backfill.yml` command
  with safe blocked guidance, with a contract check against the workflow's actual dispatch inputs.
  Keep changes narrow and preserve all pre-existing dirty work.
- **D-71 — Keep remote and irreversible steps separate.** The local-hardening plan must not replay
  Plan 175-55, invoke the source collector, run a push dry-run, access the network, create or move a
  tag, merge a PR, consume a gate, or publish. A later read-only evidence plan may refresh source,
  mirror, candidate, and CI facts. Any source operation or tag creation requires a newly reviewed
  plan and exact operation-specific authorization.
- **D-72 — Preserve release truth and the review boundary.** REL-13 and REL-17 remain OPEN; the
  release hold remains ACTIVE; no prior receipt, digest, candidate authorization, or CI run is
  reusable as fresh evidence. A missing local receipt does not resolve the Plan 175-55 boundary.

This recovery choice follows the review recommendation: close local fail-closed defects before
collecting new evidence, then stop at the existing authorization boundary. It does not grant source
or release authority.

### Addendum — Future attempt lifecycle evidence (2026-10-01)

The Plan 175-55 forensic review found no GSD activity/journal record with task or process start/exit
events. This leaves the old boundary UNKNOWN and unchanged. For a future attempt, the review
recommends making the execution lifecycle durable before another one-shot source action is
considered.

- **D-73 — Add durable lifecycle evidence before a new source attempt.** A new plan may add a
  supervisor journal with separately persisted and readback-verified task-entry, reservation,
  dispatch-intent, process-start, and exit-observed events. Store only bounded status facts; no raw
  streams, command lines, environment, remote details, credentials, or private paths. If execution
  stops after dispatch-intent without authoritative start/exit evidence, record MAY_HAVE_STARTED /
  UNKNOWN, prohibit replay, and stop for separate review.
- **D-74 — Keep future source authority exact and staged.** A newly reviewed plan may collect fresh
  read-only source, mirror, PR, policy, and CI facts, then present an operation-specific decision
  before any full-clone source split or conditional push dry-run. That decision may authorize only
  the named no-write evidence attempt; it cannot authorize creating or moving the mirror tag. Tag
  creation, if later proposed, requires its own exact-ref and exact-OID decision. No new plan or
  context update clears the Plan 175-55 UNKNOWN boundary or changes the REL-13/REL-17 release hold.

### Addendum — Separate Repair Evidence from Release Readiness (2026-10-01)

Plan 175-58's lifecycle tests and fresh artifact passed their checks, but its preflight classified
the attempt as BLOCKED because the candidate's required CI was FAILURE and branch policy was
UNKNOWN. A fresh read-only inspection confirmed that `Crosswake CI` remains the only required
check; within that run `ios-mirror-parity-proof` is the only failing job and the other jobs passed.
The mirror repository exposes an active tag ruleset targeting `refs/tags/**/*` with non-fast-forward
and deletion rules and no creation rule. The current API permission observation is affirmative.
The direct default-branch protection endpoint reports no branch protection, while the PR still
reports its workflow check as required; because those observations do not fully explain the merge
policy, branch-policy truth remains UNKNOWN. These facts are fresh observations for diagnosis only;
they do not change Plan 175-58's immutable BLOCKED artifact or authorize an operation.

- **D-75 — Keep repair-attempt eligibility distinct from release CI readiness.** A future preflight
  for a no-write source split and conditional exact-ref push dry-run must record candidate CI state
  and its normalized failure class, but must not require the candidate's aggregate CI to be green
  when that green result depends on the missing mirror tag being repaired. It may present the
  operation-specific decision only when a fresh exact-head run proves `ios-mirror-parity-proof` is
  the sole failed job, every other required job passes, the exact mirror target is absent, source
  and PR identities are current, and read-only push permission is affirmative. Other, pending, or
  unclassified check failures keep the hold. Query tag rulesets for the target tag separately from
  branch merge policy; surface unresolved merge-policy facts without claiming release readiness.
  Any affirmative decision remains limited to one named source split and conditional no-write
  dry-run; tag creation/movement and all release actions still need separate authority. Because
  Plan 175-58's fixed artifact is BLOCKED and immutable, a new reviewed plan must create a new
  attempt ID and artifact. Never reuse the Plan 175-58 ID or reinterpret its BLOCKED result.

### Addendum — Plan 175-59 transport and aggregate correction (2026-10-01)

Plan 175-59 produced a new immutable BLOCKED preflight at attempt
`715ae99fb28ef5b4aff7a5077bc3fb50`. Its `gh_json/1` transport appended `--jq .` to every
invocation, including `gh api --paginate --slurp` calls. GitHub CLI rejects that flag combination,
so the run roster, run freshness, and tag-policy fields became UNKNOWN. Independent read-only
inspection identified run `36438452825`, attempt 1, as the current PR head's completed run; it
completed on 2026-09-28 and is stale for the 2026-10-01 preflight. Its complete job roster shows
the failed `ios-mirror-parity-proof` leaf and the failed terminal `Crosswake CI` aggregate, whose
workflow definition depends on all required leaves and exits nonzero for an unaccepted result.
All other jobs passed. The mirror's active tag ruleset has id `17668056`, targets tag refs with
`refs/tags/**/*`, and lists non-fast-forward and deletion rules. These are diagnostic observations,
not reusable authorization evidence.

- **D-76 — Repair the transport and classify the derived aggregate exactly.** A new reviewed plan
  may correct the GitHub CLI JSON argv seam, collect all pages and the exact run attempt, and
  normalize full ruleset details including parent rulesets and ref conditions. A no-write source
  evidence decision may treat the failed terminal `Crosswake CI` job as derived from the parity
  leaf only when the exact PR/run/attempt identity matches, the workflow dependency/aggregate
  behavior is verified from workflow bytes fetched at that exact head, `ios-mirror-parity-proof`
  is the only failed independent job, every other
  independent job succeeds, and no unrelated required check fails. Any incomplete, pending,
  unknown, stale, or changed observation blocks. If the existing exact-head run is stale, the
  plan may request at most one `gh run rerun <exact-id> --failed` as ordinary CI verification only
  after the old complete roster proves that exact failure shape and no newer or active same-head
  run exists. It must wait for that attempt and make a fresh preflight; it must not retry an
  uncertain rerun. The plan creates a new schema, artifact, lifecycle, and opaque attempt ID;
  Plans 175-58/59 remain immutable. It stops at the exact source split and conditional push
  dry-run authorization boundary. No tag creation/movement, merge, Gate 2, recovery, registry
  write, or publication is authorized. Branch merge policy remains separately UNKNOWN until
  independently established. REL-13/REL-17 remain OPEN and the release hold remains ACTIVE.

  Required-check completeness for this decision must come from the PR head commit's GraphQL
  `statusCheckRollup.contexts` connection, with `CheckRun.isRequired(pullRequestNumber: 219)` and
  `StatusContext.isRequired(pullRequestNumber: 219)` evaluated for every context. Exhaust the
  cursor connection, reconcile `totalCount`, and bind the returned commit OID to the live PR head.
  Also obtain the effective required-context declarations for the PR base branch from GitHub's
  read-only `GET /repos/{owner}/{repo}/rules/branches/{branch}` endpoint, which includes active
  repository and parent rules, and the base ref's GraphQL `branchProtectionRule`. Reconcile that
  complete declared set against the observed `isRequired` connection so a required context missing
  from the commit rollup cannot silently disappear. For each required workflow check, bind its
  check suite's workflow run ID and attempt to the corresponding exact attempt; bind a required
  status context to the same head commit. A matching `gh pr checks --required` result may
  corroborate but cannot substitute for the complete declaration and observation sources.
  Missing pages or declarations, duplicate or ambiguous contexts, mixed SHA/run/attempt identity,
  inaccessible GraphQL or effective-rule data, disagreement between sources, or any unrelated
  failed/pending required check block the no-write decision.
  These PR-specific required-check facts do not establish the independent branch merge policy.

---

*Phase: 175-rehearsal-and-publish*
*Context gathered: 2026-10-01*

### Addendum — Exact-head evidence plan recommendation (2026-10-02)

Plan 175-67 corrected the local aggregate evaluator and its local-workflow regression. That result
still does not prove that the workflow bytes on PR #219's immutable head match the current local
workflow: Plan66 decoded its remote content but did not retain those bytes. The active STATE and
ROADMAP remain authoritative: Plan55 is UNKNOWN, REL-13/REL-17 are OPEN, readiness is BLOCKED, the
release hold is ACTIVE, and Plans 175-45 through 175-48 remain blocked behind halted Plan44.

The user delegated the recommendation and asked to continue planning. Three specialist research
passes compared evidence scope, Elixir architecture and DX, and release-automation lessons across
GitHub Actions, Release Please, Changesets, and GoReleaser. The recommended next step is one fresh,
bounded, read-only collection of exact-head workflow, run, required-check, and applicable policy
evidence. It closes the specific identity/completeness gap while keeping Actions write permission,
source operations, and release authority out of scope. Planning this collection does not itself
authorize a remote read; the resulting plan must state its exact read boundary and be reviewed before
execution.

- **D-77 — Collect the missing facts in one read-only exact-head evidence plan.** Bind the PR number,
  head and base OIDs, workflow path and bytes at that head, run ID and attempt, complete job roster,
  required-check observations, and effective required-context declarations into a new attempt. Do
  not include CI rerun, source split, push dry-run, tag, merge, Gate 2, recovery, registry, or
  publication operations in this plan. Keep any unresolved merge-policy question separately UNKNOWN.
- **D-78 — Require exhaustive, identity-matched observations.** Follow every required pagination
  cursor to completion; reconcile page totals and duplicate identities; bind checks to the exact PR
  head and workflow checks to the exact run attempt; reconcile observed required contexts against
  effective branch declarations. Verify aggregate dependencies against workflow bytes fetched at
  that same head. A stale, incomplete, pending, inaccessible, mismatched, duplicate, or ambiguous
  observation blocks as UNKNOWN/BLOCKED. Preserve D-76's closed exception: a failed terminal
  aggregate can be considered derived only when the complete exact-attempt evidence proves the
  parity leaf is the sole independent failure and all other independent checks pass.
- **D-79 — Keep reruns outside this first collection.** Although D-76 permits one guarded failed-job
  rerun if all of its preconditions are proven, this recommendation selects no rerun in the next
  plan. A rerun needs Actions write authority, can re-execute workflow work with the original
  trigger context, and creates a new attempt that must be independently observed. If complete fresh
  evidence later shows a rerun is necessary and every D-76 predicate passes, propose it in a separate
  reviewed plan; never retry an uncertain dispatch.
- **D-80 — Use the existing Elixir evidence boundary.** If a code change is needed, keep GitHub
  process execution in a narrow, private adapter at the Mix/shell boundary, inject the runner for
  deterministic local fakes, and send decoded bounded facts to the existing pure evidence
  classifier. Reuse the established status vocabulary and sanitized artifact/lifecycle conventions.
  Do not widen `mix crosswake.release.status` into a hidden-network command or add Plug, Phoenix,
  Ecto, a database, dashboard, or generic provider abstraction: this is a maintainer evidence task,
  not an application request flow or persistent domain store.
- **D-81 — Shape output around the maintainer's job.** The operator needs to know which exact
  candidate/run was examined, whether the evidence is complete and current, what is proven, what is
  UNKNOWN, and one safe next action. Present the same bounded classification in human-readable and
  JSON forms. Keep provider calls, argv, raw response bodies, credentials, environment, local paths,
  and raw stdout/stderr out of output and durable receipts. Use stable reason codes, plain status
  words, explicit unknown-vs-false distinctions, no color-only meaning, and calm actionable wording
  consistent with `brandbook/BRAND-SPEC.md` (which supersedes the historical prompt seed). Visual
  design is not applicable to this CLI-only phase.
- **D-82 — Keep the evidence lifecycle immutable and authority-specific.** Give the plan a new opaque
  attempt ID, schema, artifact, and write-ahead/readback-verified lifecycle. Do not replay old plans,
  reuse artifacts/digests, or infer a remote result from local workflow checks. A complete read-only
  result can inform a later repair-eligibility decision only; it cannot clear release readiness,
  REL-13, REL-17, or the release hold.

The maintainer JTBD is to decide whether a specific repair-evidence attempt is eligible for its
separately authorized next boundary without having to interpret GitHub internals or raw command
output. The operator supplies the selected PR/head and runs one explicit diagnostic; the collector
reads bounded remote facts; the artifact records provenance and completeness; the CLI returns a
clear status, reason, and next step. Accessibility, reliability, security/privacy, correctness,
rate-limit cost, and maintainability apply to this command and its artifact. Consumer UI, adopter
journeys, graphic motifs, and browser interaction do not apply here.

Research references: [GitHub Actions secure use](https://docs.github.com/en/actions/reference/security/secure-use),
[GitHub Actions artifacts](https://docs.github.com/en/actions/tutorials/store-and-share-data),
[GitHub workflow rerun behavior](https://docs.github.com/en/actions/how-tos/manage-workflow-runs/re-run-workflows-and-jobs),
[Release Please design](https://github.com/googleapis/release-please/blob/main/docs/design.md),
[Release Please troubleshooting](https://github.com/googleapis/release-please/blob/main/docs/troubleshooting.md),
[Changesets CLI options](https://github.com/changesets/changesets/blob/main/docs/command-line-options.md),
[GoReleaser snapshot CI example](https://www.goreleaser.com/customization/ci/rwx/),
[Mix tasks](https://mix.hexdocs.pm/main/Mix.Task.html),
[Elixir `System.cmd/3`](https://hexdocs.pm/elixir/System.html#cmd/3),
[Plug Router](https://hexdocs.pm/plug/Plug.Router.html), and
[Ecto.Repo](https://hexdocs.pm/ecto/Ecto.Repo.html).

- **D-83 — Keep one immutable evidence identity as the anchor.** The collection's identity is the
  selected PR number, immutable head/base OIDs, workflow path plus SHA-256 of the exact workflow
  bytes transiently fetched at that head, and the exact run ID and attempt. API pages and policy
  declarations corroborate those identities; branch policy remains a separate policy fact, not an
  alternate candidate identity. Decode and inspect workflow bytes in memory, persist only the digest
  and bounded parser-derived facts, and never persist the raw provider response. This preserves the
  existing exact-head/run-attempt model as the observation set grows.

### Addendum — Preserve bounded partial observations after Plan68 UNKNOWN (2026-10-02)

Plan 175-68 made exactly one reviewed read-only collection attempt and ended UNKNOWN. Its artifact
retained no run, job, or check observations and no workflow digest. Code inspection confirmed that
the collector converts any downstream source error into one all-UNKNOWN fact set, discarding
earlier successful observations. The precise source failure and underlying request count therefore
cannot be recovered from this terminal attempt. Its artifact and lifecycle remain immutable; do not
retry or reinterpret them.

The next step is a local evidence-shape improvement followed by a separately reviewed plan. It may
make one fresh exact-head read-only collection only after local tests and plan review pass. It must
use a new attempt identity, artifact, lifecycle, and schema, and may not reuse Plan68 facts as fresh
evidence. No rerun, write, release action, or operation-specific source authorization is in scope.

- **D-84 — Preserve bounded source outcomes independently.** Record a closed, low-cardinality
  observation state for each required source (PR identity, run roster, selected attempt jobs,
  required-check rollup, REST declarations, GraphQL declarations, workflow bytes, and final PR
  identity). Preserve only successfully normalized bounded facts, source completion state, and safe
  counts. If a source is not reached because a prerequisite is unavailable, represent it explicitly
  as not attempted; do not collapse earlier evidence into a generic all-UNKNOWN shape. The aggregate
  result remains UNKNOWN/BLOCKED unless every required source is complete, fresh, and identity
  matched.
- **D-85 — Keep failure diagnostics private and actionable.** Translate transport and decode
  failures into stable allowlisted reason codes and bounded source states. Never retain or render raw
  provider bodies, error messages, argv, endpoints, credentials, environment, local paths, or
  stdout/stderr. Text and JSON must show the same safe source completeness and one next action; an
  unavailable count remains UNKNOWN rather than zero. This is a maintainer CLI contract, with no
  Plug/Phoenix route, Ecto persistence, UI, or provider abstraction.
- **D-86 — Permit one fresh reviewed evidence attempt only.** After the local change is fake-tested
  and a new plan is independently reviewed, allow that plan to make at most one bounded
  read-only exact-head collection using a new attempt and immutable artifact/lifecycle pair. On any
  uncertainty, persist a sanitized UNKNOWN result and stop; no retry, rerun, source operation, tag,
  merge, Gate 2, recovery, registry write, or publication follows.

The maintainer's job remains to assess one exact repair-evidence attempt without decoding provider
internals. The improved result should identify which evidence source is complete or unavailable,
what safe facts were observed, and why the overall observation remains UNKNOWN, while preserving the
same fail-closed release disposition. This trades a small schema and classifier increase for useful
triage while keeping privacy, request authority, rate limits, and compatibility boundaries explicit.
No UI/graphic design decisions apply. Use existing Elixir tagged-result and pure-classifier seams;
keep process/API calls at the imperative edge and make incomplete sources ordinary bounded data,
not exception text.

### Addendum — Plan 175-69 review resolution and next attempt boundary (2026-10-02)

The user asked for all relevant decisions to be considered, a coherent recommendation, and for the
recommended direction to be carried forward. The Plan69 code review supplied three concrete
engineering decisions; the remediation and focused checks are complete. This addendum does not
reinterpret the consumed Plan69 attempt or clear the release hold.

**Trade-off analysis for a fresh read:** Reusing the Plan69 paths or appending another attempt to its
partial lifecycle would blur the consumed identity and violate exclusive, immutable evidence. A
general GitHub-provider framework would reduce some duplication but add a public-looking abstraction
and scope the project does not need. Stopping after local fixes avoids another remote observation
but leaves the exact-head evidence gap unresolved. The recommended path is one new plan-scoped,
read-only attempt with a new opaque ID, schema, artifact path, and lifecycle path. It costs a small
amount of plan-specific code and may still end UNKNOWN; in exchange it preserves old evidence and
gives this new attempt a terminal, attributable result. It performs no CI rerun or release action.

- **D-87 — Keep the consumed Plan69 attempt immutable.** `[auto; recommended]` Do not retry it, repair its three-event
  lifecycle, or infer which request ran. A later read must use a new attempt identity, schema, and
  exclusive artifact/lifecycle paths. This honors the exact attempt boundary and avoids collision
  with the occupied Plan69 lifecycle path.
- **D-88 — Turn request exceptions into source outcomes at the adapter edge.** `[auto; recommended]` Use the existing
  injected request function and translate raised/thrown failures into a bounded unavailable result.
  Preserve earlier complete sources and mark dependent later sources not attempted. Keep raw
  exception text out of the artifact, lifecycle, logs, and CLI. This matches the existing
  functional-core / imperative-shell pattern; it avoids a broad provider abstraction and keeps
  failure attribution close to the source that failed.
- **D-89 — Close artifact-persistence failures with a terminal lifecycle outcome.** `[auto; recommended]` If the result
  cannot be written after durable intent and the lifecycle remains writable, remove an incomplete
  artifact path when possible and append `collection-failed` with only the allowlisted
  `collection_failed` reason. Do not claim source facts were persisted, retry the write, or invent
  an underlying cause. If the lifecycle itself cannot be written, retain UNKNOWN and stop; do not
  make a second collection attempt to compensate.
- **D-90 — Require an open PR at both identity reads before proof.** `[auto; recommended]` A closed initial or final PR
  snapshot yields UNKNOWN with the existing safe `identity_mismatch` reason. The fact that a closed
  snapshot is internally consistent does not make it current evidence for the active candidate.
- **D-91 — Keep the maintainer interface plain and task-focused.** `[auto; recommended]` Text and JSON derive from the
  same validated projection, with explicit UNKNOWN versus false, safe counts, actual line breaks,
  and one actionable next step. Use calm, specific wording from the current `brandbook/BRAND-SPEC.md`.
  This task has no consumer UI, Phoenix route, Plug handler, Ecto persistence, dashboard, or visual
  design scope.
- **D-92 — The next attempt has one read and a hard stop.** `[auto; recommended]` A separately planned and independently
  reviewed plan may invoke the fresh exact-head collector at most once after its local fake suites
  and validators pass. Any uncertain result ends that plan. No retry, CI rerun, source split,
  conditional push dry-run, tag, merge, Gate 2, recovery, registry write, or publication follows.
  The observation can inform later planning only; Plan55 remains UNKNOWN, REL-13/REL-17 remain OPEN,
  candidate readiness remains BLOCKED, merge-policy remains UNKNOWN, and the release hold remains
  ACTIVE.

The source-completeness, privacy, and operator-output choices above are implemented and covered by
91 focused tests. They reuse Elixir tagged outcomes, explicit `case`/`with` boundaries, the Mix
adapter, and a pure classifier; no new dependency or recurring CI lane is justified for this
one-time reconciliation. `brandbook/BRAND-SPEC.md` is newer than the prompt seed and governs wording.

### Addendum — Plan 175-70 disposition and local-diagnosis boundary (2026-10-02)

The user requested expert research and one coherent, recommendation-led decision across the
phase-relevant areas. Two read-only advisor agents reviewed local evidence and official Elixir,
GitHub, Terraform, and SRE references. This update preserves all prior decisions, including D-89
and D-91; it does not add a diagnostic taxonomy or authorize another remote observation.

**Trade-off:** Stopping with `UNKNOWN` preserves the evidence and costs nothing, but skips a useful
local review of the implementation's terminal paths. A fresh exact-head read could supply current
source facts, but might fail again, would perform multiple paginated API requests under one command
invocation, and cannot be justified by Plan70's generic exit. Local-only diagnosis gives the safest
next signal without pretending it can recover Plan70's source result or cause. The selected order is
local diagnosis first; only a later, separate discussion and reviewed plan can propose a new read if
the exact-head evidence remains necessary.

- **D-93 — Preserve Plan70 as a terminal UNKNOWN attempt.** Its one collector invocation exited 1;
  the local inspector validates `task-entry`, `reservation`, `collection-intent`, and
  `collection-failed`, and the artifact is absent. Do not infer a source outcome, request count,
  request occurrence, or cause; do not retry, repair, or reuse the attempt's identity or lifecycle.
  Keep Plan55 UNKNOWN, REL-13/REL-17 OPEN, candidate readiness BLOCKED, merge-policy status UNKNOWN,
  the release hold ACTIVE, and Plans 175-45 through 175-48 blocked.
- **D-94 — Make the immediate follow-up a local-only diagnosis.** Inspect the retained Plan70 summary
  and lifecycle plus the current runner, evidence validator, request boundary, and existing fake
  coverage. Separate recorded facts from possible exception paths. Do not attribute a current-code
  branch to Plan70 when the execution-time entrypoint was temporary and the shared source files were
  already dirty. No remote/network read, collector invocation, test/formatter run, source edit, CI
  rerun, subtree/tag operation, merge, Gate 2, recovery, registry write, or publication is included.
  Append this scoped work through `$gsd-plan-phase 175 --ws quality-ratchet-release`; when prompted
  about existing plans, choose “Add more plans” so earlier phase history is preserved.
  If local evidence does not establish a concrete diagnosis, preserve UNKNOWN and stop.
- **D-95 — Require a later separate decision before any new remote observation.** The local-diagnosis
  plan creates no permission to collect GitHub facts. If an exact-head read remains necessary after
  local review, it needs a new discussion, fresh plan and independent review; a unique attempt ID,
  versioned schema, and exclusive artifact/lifecycle paths; endpoint-minimum permissions and bounded
  pagination; and at most one collector invocation with the existing fail-closed result contract.
  One invocation is not one API request. Any uncertainty ends that plan. No observation authorizes a
  CI rerun or release side effect.

D-91 remains controlling for maintainer DX: retain the existing Mix text/JSON projection, stable
`UNKNOWN` wording, safe counts, and one task-focused next action. No Logger/Telemetry surface,
failure-code taxonomy, Phoenix/Plug API, Ecto persistence, dashboard, or consumer UI is justified
without a demonstrated recurring contract. The current `brandbook/BRAND-SPEC.md` governs wording.

### Addendum — Fresh plan for the missing `v0.2.6` mirror tag (2026-10-02)

Plan 175-44's halted successor candidate is PR #219 / `0.2.7`. Its required iOS parity check
failed because source tag `ios-core-v0.2.6` exists while the SwiftPM mirror lacks `v0.2.6`.
Plan 175-71 completed its separate local diagnosis of Plan70; Plan70's cause and request
occurrence/count remain UNKNOWN. Keep all prior plan attempts and artifacts immutable.

Two advisor researchers compared three routes using the current phase evidence, Crosswake's OSS
and release prompts, Elixir/Mix conventions, and official Git/GitHub/release-tool references:

| Route | Trade-off | Disposition |
|---|---|---|
| Keep the release held with no new plan | Adds no uncertainty or operational surface; leaves PR #219 and Plans 175-45 through 175-48 blocked. | Viable if the release owner chooses to stop pursuing this candidate. |
| Add a read-only reconciliation plan first | Refreshes exact refs or policy if they may have changed; the recorded CI failure already identifies the missing tag, so another diagnostic-only cycle adds little unless a specific changed fact would alter the repair decision. | Not selected. |
| Add a fresh, narrowly scoped mirror-tag repair plan | Directly targets the known dependency while preserving fresh evidence and a separate write boundary; may still stop as UNKNOWN/BLOCKED. | **Selected by the user.** |

- **D-96 — Plan a fresh repair for exactly the missing `v0.2.6` mirror tag and candidate parity.** Use
  `$gsd-plan-phase 175 --ws quality-ratchet-release` to append the next plan while preserving all
  existing plan history. Do not add another standalone diagnostic collector without identifying a
  decision-relevant fact that is missing or could have changed.
- **D-97 — Keep observation, tag-write authority, and release authority distinct.** The new plan must
  use fresh source/mirror/candidate identities and current applicable tag-policy evidence; assign a
  new attempt identity/schema and exclusive evidence paths; validate locally with deterministic
  fakes before any authorized remote boundary; and stop on every mismatch, unavailable fact, or
  ambiguity. Git subtree output is reproducible only for identical history and settings, while the
  remote can reject a push under its rules or hooks and a new tag may trigger downstream automation;
  bind the proposed object and exact ref and surface the actual bounded result. A tag operation, if
  separately reviewed and explicitly authorized, is limited to the exact `refs/tags/v0.2.6` target
  and may be attempted at most once. This discussion and the act of planning authorize no remote
  read or write. The consumed Gate 2 token and prior receipts/digests are not reusable.
- **D-98 — Tag parity is only a prerequisite for renewed candidate evaluation.** Even a successful
  exact tag repair does not authorize a CI rerun, Gate 2, merge, recovery, registry action, or
  publication. Require fresh passing required-CI evidence for the exact PR #219 head and a distinct
  candidate-specific authorization before any later release step. Keep REL-13/REL-17 OPEN,
  candidate readiness BLOCKED, merge-policy UNKNOWN, the release hold ACTIVE, and Plans 175-45
  through 175-48 blocked until their actual prerequisites pass.
- **D-99 — Reuse the maintainer-facing Mix boundary and existing evidence model.** The maintainer's
  job is to resolve one exact mirror-parity blocker and receive what is proven, what remains
  UNKNOWN, and one safe next action. Keep subprocess execution at the narrow Mix/process edge with
  explicit arguments and bounded results; reuse the existing validated text/JSON projection and
  pure evidence classifier where they fit. Do not add a Phoenix/Plug route, Ecto persistence,
  dashboard, generic provider abstraction, new telemetry taxonomy, or consumer UI. Use plain
  accessible text and JSON with no color-only meaning or raw command/provider output; the current
  `brandbook/BRAND-SPEC.md` governs wording and supersedes the historical prompt seed.

The useful release-tool precedent is lifecycle separation: Release Please uses a merged release
proposal to drive release creation, while Changesets exposes tag creation separately from package
publishing. Reuse that clarity of boundaries, not those tools' authority model; a tag action here
must still be bound to the exact mirror ref and independently authorized. A second read-only
collector adds cost and ambiguity without changing the recorded failure unless it refreshes a
specific decision-relevant fact. A host-facing Mix task, explicit `System.cmd/3` arguments, tagged
bounded outcomes, and a pure classifier keep the operator path idiomatic and testable without
introducing Phoenix, Plug, Ecto, telemetry, or a dashboard.

The decision was evaluated against correctness, security and least privilege, privacy, reliability,
operational cost, maintainability, developer ergonomics, and clear operator feedback. Accessibility
and visual-system work are limited to legible, color-independent CLI output: there is no consumer
screen, browser flow, graphic motif, Plug/Phoenix request path, or Ecto data model in this task.

**Research references:** [Git subtree](https://github.com/git/git/blob/master/contrib/subtree/git-subtree.adoc),
[git-push](https://git-scm.com/docs/git-push), [GitHub rulesets](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets),
[Mix.Task](https://hexdocs.pm/mix/Mix.Task.html), [Elixir System.cmd/3](https://hexdocs.pm/elixir/System.html#cmd/3),
[Release Please](https://github.com/googleapis/release-please/blob/main/README.md), and
[Changesets tag command](https://github.com/changesets/changesets/blob/main/docs/command-line-options.md).

### Addendum — Plan 175-73 in-place correction (2026-10-02)

- **D-100 — Revise only the existing `175-73-PLAN.md` for the local adapter and evidence-contract
  gaps found in `175-73-LOCAL-READINESS.md`; preserve every other Phase 175 plan file.** This direct
  planning instruction supersedes D-96's earlier append-next-plan route for this run. Keep the
  already-granted one-read scope unchanged, remove the now-redundant Read checkpoint, require the
  exact `CROSSWAKE_PLAN73_READ_TOKEN` before any remote request, and retain Plan74's separate
  digest/object/ref-bound tag-write authorization.

### Addendum — Post-Plan 175-77 next-work decision (2026-10-03)

Plan76's one authorized read ended UNKNOWN_UNVERIFIABLE. Its lifecycle is terminal, the preflight
path contains only a reservation marker, and the retained evidence does not establish a cause.
Plan77's injected-callback reproduction found no separate production defect and does not explain
Plan76. Preserve both outcomes exactly; REL-13 and REL-17 remain OPEN, candidate readiness BLOCKED,
merge-policy UNKNOWN, the release hold ACTIVE, and Plans45–48 held.

Three advisor researchers compared the next-step boundary, the already-locked REL-17 contract
shape, and the smallest persuasive proof strategy. They considered the current phase state and
requirements, the current Mix/Elixir release boundary, Crosswake's OSS and delivery prompts, and
official Elixir, GitHub Actions, and release-automation references.

| Option | Benefits | Costs and risks | Recommendation |
|---|---|---|---|
| Stop all Phase 175 work at the safe stop | Adds no external access, evidence surface, or maintenance cost; preserves UNKNOWN honestly. | Leaves the known REL-17 release blocker without a scoped next step. | Safe if the release owner no longer wants this milestone to progress. |
| Make another remote read to recover Plan76's cause | Could gather fresh current facts for a later decision. | Cannot reconstruct Plan76's historical cause; could end UNKNOWN again; consumes new access and requires new scope, review, and authority. | Do not use as a Plan76 diagnosis. Consider only when one named current fact can change a distinct release decision. |
| Add more Plan76-specific logging or a new error taxonomy | Could help if a distinct current-code defect or recurring operator need were demonstrated. | Plan77 reproduced the safe-stop path without a separate defect; additional logging cannot recover Plan76's cause and risks leaking details or adding an unnecessary interface. | Not recommended absent a demonstrated defect or recurring contract. |
| Plan local REL-17 coverage and gap closure across the protected publisher paths | Advances the explicit hard blocker using deterministic, credential-free evidence; can prove the shared gate cannot be bypassed without changing release truth. | May find existing coverage already sufficient; the proof must exercise every distinct path to avoid shared-helper-only confidence. | Recommended next bounded work item. |

- **D-101 — Keep Plan76 terminal and do not spend new authority trying to explain its historical
  cause.** Preserve its reservation marker and lifecycle; do not replay, repair, or infer missing
  facts. A future remote read is eligible for separate discussion only when a named current fact
  would change a concrete release decision. Any such read needs fresh scope, review, permissions,
  attempt identity, and evidence paths; it cannot grant write or publication authority.
- **D-102 — Scope the next plan to local REL-17 coverage and gap closure.** Map the six locked
  conditions across every distinct linked-release, recovery, and companion publisher path. Use
  existing valid fixtures and independently mutate one condition or identity binding at a time;
  exercise each real entry point through fake adapters and prove invalid or UNKNOWN evidence reaches
  no side-effect sink while a valid control reaches only its expected sink. Mutate workflow guard
  presence and order as structural backstops. This plan grants no remote read/write, CI rerun, merge,
  Gate 2, registry action, recovery, or publication authority. If the matrix demonstrates that an
  existing surface already meets a condition, preserve that proof rather than adding duplicate code.

REL-17's existing architecture decisions remain controlling: one exact-key closed JSON evidence
contract, one pure shared validator, fresh mutable-fact checks at authorization and immediately
before each side effect, and thin path adapters. A typed internal representation may follow strict
wire validation, but neither a struct nor a shared-helper unit test proves caller validation or
freshness on its own. Path-specific duplicate validators, workflow ordering/concurrency as a
substitute for evidence authority, and a new release framework are not recommended.

The proof plan should keep its valid positive control and each changed-fact case decision-specific;
test each publisher entry point, actual no-side-effect behavior, post-merge OID binding, retained
registry response and nonempty parse, matching response-table row, protected-path/no-bypass behavior,
and runbook ancestry. Existing stable unit, entry-point, and workflow-integrity checks may remain
merge-blocking in CI where they protect recurring contracts. Record the complete path/condition
matrix once as sanitized phase evidence; do not add live provider checks to routine CI. Preserve the
existing Mix text/JSON projection, explicit UNKNOWN versus FALSE wording, and one safe next action.
Use a Mix task, pure Elixir classifier, and narrow process/API adapters. This workflow has a
maintainer/operator persona and no consumer UI, browser flow, Phoenix/Plug endpoint, Ecto model,
dashboard, or graphic-design task. If copy changes later, the current brandbook/BRAND-SPEC.md
supersedes the older prompt seed; color must not carry meaning alone.

Cross-ecosystem lessons applied: digest-bound evidence and distinct tag/publish stages are useful
patterns in release automation; workflow dependencies and concurrency do not replace operation
authorization or just-in-time evidence refresh; struct construction does not validate untrusted
JSON; shared-validator coverage alone can miss a path bypass; and structural workflow checks do not
prove runtime semantics. Keep operator feedback concise, deterministic, and actionable.

**Research references:** [GitHub secure use](https://docs.github.com/en/actions/reference/security/secure-use),
[GitHub reusable workflows](https://docs.github.com/en/actions/reference/workflows-and-actions/reusing-workflow-configurations),
[Mix.Task](https://hexdocs.pm/mix/Mix.Task.html), [Elixir defstruct](https://hexdocs.pm/elixir/Kernel.SpecialForms.html#defstruct/1),
[ExUnit](https://hexdocs.pm/ex_unit/ExUnit.Case.html), [Release Please](https://github.com/googleapis/release-please-action),
[Crosswake Elixir OSS DNA](../../../../../prompts/crosswake-elixir-oss-dna.md), and
[Crosswake delivery brief](../../../../../prompts/crosswake-gsd-project-brief.md).

### Canonical references for the post-Plan77 decision

- .planning/workstreams/quality-ratchet-release/ROADMAP.md and
  .planning/workstreams/quality-ratchet-release/REQUIREMENTS.md — Phase 175 goal and the unchanged
  REL-17 hard stop.
- .planning/workstreams/quality-ratchet-release/STATE.md — active position, Plan77 result, and
  release posture.
- .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-76-SUMMARY.md
  — immutable UNKNOWN_UNVERIFIABLE Plan76 result and consumed read authorization.
- .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-77-SUMMARY.md
  and 175-77-LOCAL-DIAGNOSIS.md — current local reproduction, safe-stop projection, and
  no-production-defect result.
- lib/crosswake/release_candidate/evidence_gate.ex,
  lib/crosswake/release_candidate/evidence_live.ex,
  test/crosswake/proof/phase175_rel17_publish_paths_test.exs,
  test/crosswake/proof/phase175_release_recovery_test.exs, and
  script/check_release_workflow_integrity.exs — existing shared gate, live evidence boundary,
  cross-path tests, recovery tests, and structural workflow checks.
- prompts/crosswake-elixir-oss-dna.md,
  prompts/crosswake-gsd-project-brief.md, and prompts/new elixir oss lib prompt.txt — project-specific
  Elixir OSS, delivery, release, and maintainer-DX expectations.
- brandbook/BRAND-SPEC.md — current wording source if CLI copy changes; no UI or visual-system
  work is in scope.

### Addendum — Post-Plan 175-78 scanner-blocker disposition (2026-10-04)

Plan78 ran and halted because the workflow-integrity scanner reads
script/release_candidate/assert_candidate_receipt_artifact.sh, which was absent during that run.
The scanner stopped before its REL-17 checks; the combined Task 3 proof reported 14 failures at
that missing input. The process-gate suite and sanitized matrix check passed, but response-row
independence, some per-row identity bindings, workflow presence/order, and final-guard execution
remain UNKNOWN. The helper now exists in the workspace as an untracked file. Its current text
matches the visible exact-roster contract, but it is not part of the tracked checkout and no
verification was run during this discussion.

One follow-up route was selected automatically at the user's request to make the decision:

| Option | Disposition |
|---|---|
| Stop with the scanner and matrix unknowns unchanged | Safe, but leaves Plan78's named verification blocker without a bounded next step. |
| Add a fresh local plan to validate and track the existing helper, then rerun only the blocked scanner-dependent checks | **Selected (recommended).** It addresses the recorded blocker with the smallest source boundary and can refresh only claims backed by passing checks. |
| Broaden into changing publisher workflows, final guards, or the scanner | Rejected without a named failing condition; Plan78 did not establish such a defect. |

- **D-103 — Scope the immediate follow-up to the missing scanner input.** Preserve the currently
  untracked helper unchanged during this discussion. The next plan should review it against the
  scanner and existing exact-roster regression cases, add the helper as a tracked source file
  without behavior changes if it satisfies that contract, and rerun the workflow-integrity scanner
  plus the previously blocked local scanner-dependent suite. Update entry 36 and matrix cells only
  from the resulting evidence. If the helper or another dependency fails, keep the affected claims
  UNKNOWN and stop for a separately scoped decision; do not edit publisher YAML or final guards
  without a named failing assertion.
- Keep Plan78's other unsupported matrix cells UNKNOWN until a named executed assertion proves them.
  REL-13 and REL-17 stay OPEN; candidate readiness stays BLOCKED; merge-policy stays UNKNOWN; the
  release hold stays ACTIVE; Plans 175-45 through 175-48 stay held; Phase175 stays incomplete.
  This plan grants no remote read/write, CI rerun, merge, Gate 2, recovery, registry action, or
  publication.

### Canonical references for the post-Plan78 decision

- .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-78-PLAN.md and 175-78-SUMMARY.md — intended cross-path proof and its halted verification boundary.
- .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-78-REL17-PATH-MATRIX.md — exact proven/unknown claims to preserve.
- .planning/WINDOWS.md — scanner blocker entry 36.
- script/release_candidate/assert_candidate_receipt_artifact.sh — untracked candidate input requiring validation and tracking.
- script/check_release_workflow_integrity.exs — scanner dependency and receipt-order assertion.
- test/crosswake/proof/phase175_release_recovery_test.exs, test/crosswake/release_candidate/workflow_test.exs, and .github/workflows/release-please.yml — existing helper contract, caller checks, and use site.

### Addendum — Post-Plan79 matrix assertion wrap contract (2026-10-04)

Plan79's helper review, exact-roster regression, scanner, and pre-update dependent suite completed:
the helper matched its contract, all five helper cases passed, the scanner reported 98/98, and the
dependent suite passed 40 tests with 0 failures. After the matrix and test edits were reapplied,
the post-update suite halted at 40 tests with 1 failure: a prose assertion expected its sentence
to remain on one physical Markdown source line, but the paragraph wrapped. The matrix/test edits
were restored; Plan79 remains halted and immutable, its summary and incremental review are clean,
and WINDOWS.md entry 36 remains open. No production defect was demonstrated. This supersedes the
earlier D-103 statement that the helper was still untracked: Plan79 validated and tracked it.

| Option | Tradeoff | Disposition |
|---|---|---|
| Keep requiring one physical source line | Preserves a raw-source check, but rejects a valid CommonMark soft line break and makes harmless reflow fail the proof. | Rejected |
| Normalize whitespace only inside the bounded explanatory-prose assertion, then compare the complete expected sentence including punctuation | Ignores presentation wrapping while keeping the intended prose exact and the change local. | **Selected** |
| Parse or normalize the whole Markdown file/matrix | Could model more Markdown structure, but adds parser or transformation scope and risks blurring meaningful evidence boundaries without a demonstrated need. | Rejected |
| Reformat the prose to one source line | Avoids changing the test but makes the test dictate document wrapping and leaves the brittle contract in place. | Rejected |

- **D-104 — Treat source wrapping as presentation only for the specific narrative assertion.** In the
  follow-up, bound the check to the explanatory prose paragraph, collapse whitespace within that
  captured prose, and compare the full expected sentence exactly after normalization. Do not
  normalize the entire matrix or relax expected words, punctuation, table status values, row or
  column identity, scanner IDs, evidence references, or dispositions. A prose mismatch must still
  fail.
- **D-105 — Replan only the halted matrix-and-claim refresh.** Keep Plan79's completed Tasks 1 and 2
  results and its immutable halt record. Add a narrow follow-up plan that reapplies only the restored
  Task 3 matrix/test change with D-104's assertion contract, then runs the exact post-update suite.
  Do not repeat the helper digest/regression, 98/98 scanner, or pre-update suite unless changed
  inputs invalidate that evidence. Promote `workflow_presence_order` only for publisher rows whose
  named scanner checks and corresponding mutation/order assertions pass. Then update WINDOWS.md
  entry 36 only if that suite and the dynamic ledger-count assertion both pass. If either fails,
  leave entry 36 open, keep affected claims UNKNOWN, and stop for a new decision.
- Preserve `final_guard_execution`, response-row, and unsupported material/identity cells as
  UNKNOWN. REL-13 and REL-17 remain OPEN; candidate readiness remains BLOCKED; merge-policy remains
  UNKNOWN; the release hold remains ACTIVE; Plans 175-45 through 175-48 remain held; Phase 175
  remains incomplete. This discussion authorizes no remote/provider access, CI rerun, merge, Gate 2,
  recovery, registry action, or publication.
- **Research synthesis:** Three independent read-only GSD advisor reviews covered assertion
  contracts, idiomatic Elixir/CommonMark behavior and maintainer DX, and release-evidence boundaries.
  They converged on the bounded normalization above. CommonMark defines a soft line break inside a
  paragraph as renderable as a line ending or a space, and GitHub renders normal paragraph line
  breaks continuously. Elixir's standard `Regex`/`String` APIs and ExUnit assertions are sufficient
  for a local, dependency-free check. Broad Markdown parsing, a sidecar schema, global normalization,
  and forcing one-line prose add cost without strengthening the structured matrix proof.
- This is maintainer test/documentation ergonomics only. There is no consumer UI, browser flow,
  Phoenix/Plug endpoint, Ecto model, or graphic-design task. Keep feedback concise and precise; if
  wording changes later, `brandbook/BRAND-SPEC.md` is the current source and supersedes older prompt
  guidance. Accessibility and visual-system work do not materially apply here.
- **Historical next GSD action after D-106 (superseded by D-107):** `$gsd-plan-phase 175 --ws quality-ratchet-release`. The user-requested retry under D-107 returned PLANNING INCONCLUSIVE and created no Plan83 artifact; wait for independent evidence as D-107 directs.
  Plan one fresh, bounded read-only readiness observation for the exact held core candidate; do not
  restart Phase 175, reopen D-104/D-105, or execute halted Plan79 or held Plans45–48.

**Research references:** [CommonMark soft line breaks](https://spec.commonmark.org/0.31.2/#soft-line-breaks),
[GitHub Markdown line breaks](https://docs.github.com/en/get-started/writing-on-github/getting-started-with-writing-and-formatting-on-github/basic-writing-and-formatting-syntax),
[Elixir `String.replace/4`](https://hexdocs.pm/elixir/String.html#replace/4),
[Elixir `Regex`](https://hexdocs.pm/elixir/Regex.html), and
[ExUnit assertions](https://hexdocs.pm/ex_unit/ExUnit.Assertions.html#assert/1).

### Canonical references for the post-Plan79 decision

- `.planning/ADR-FIRST-B2C-ADOPTER.md`, `.planning/FIRST-B2C-ADOPTER-ADOPTION-BRIEF.md`,
  `.planning/FIRST-B2C-ADOPTER-ROUTE-POLICY-MAP.md`, and `.planning/PROJECT.md` — governing project
  thesis, privacy boundary, route policy, adopter scope, and non-goals.
- `.planning/workstreams/quality-ratchet-release/REQUIREMENTS.md`,
  `.planning/workstreams/quality-ratchet-release/ROADMAP.md`,
  `.planning/workstreams/quality-ratchet-release/STATE.md`, and
  `.planning/workstreams/first-b2c-adopter-readiness/STATE.md` — active phase requirements,
  ordering, quality-lane handoff, and parked adopter-lane gate.
- `.planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-79-PLAN.md`,
  `175-79-SUMMARY.md`, and `175-REVIEW.md` — immutable Plan79 scope, observed halt, completed
  evidence, and review result.
- `.planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-78-REL17-PATH-MATRIX.md`
  and `.planning/WINDOWS.md` entry 36 — structured evidence claims and the open scanner blocker.
- `test/crosswake/proof/phase175_rel17_condition_paths_test.exs`,
  `script/check_release_workflow_integrity.exs`, and
  `script/release_candidate/assert_candidate_receipt_artifact.sh` — the narrow assertion, scanner,
  and helper contract being continued.
- `prompts/new elixir oss lib prompt.txt`, `prompts/crosswake-elixir-oss-dna.md`,
  `prompts/crosswake-gsd-project-brief.md`, `prompts/crosswake-integrations-and-companions.md`,
  and `prompts/crosswake-research-synthesis.md` — applicable project engineering and maintainer-DX
  guidance.
- `brandbook/BRAND-SPEC.md` — current brand and wording reference if future maintainer copy changes.

## Post-Plan80 phase-goal coverage decision — 2026-10-05

Plan80 closed the local matrix-and-ledger follow-up but did not provide a currently runnable path
to the phase-goal outcomes in REL-13/14/15. Existing local workflow and rollup tests establish
contract behavior; they do not establish a real ordinary release run, its three public coordinates,
same-run exact-public proof and six-child COMPLETE rollup, or the separate second-companion
publication.

- **D-106 — Plan one fresh read-only readiness observation for the exact held core candidate.**
  Scope the next plan to a single current-state observation of the existing core candidate (PR #219)
  to determine whether its real prerequisites have changed enough for the existing release path to
  be considered again. This discussion authorizes planning only. Execution requires a fresh reviewed
  plan, exact read-only authorization, new attempt identity, and separate evidence paths. Do not
  reuse Plan76's consumed authorization, identity, or artifacts. If any required fact is blocked,
  mismatched, or unknown, stop without retry or candidate substitution. A ready snapshot is
  preparatory evidence only: it does not satisfy REL-13/14/15, authorize Gate 2 or Gate 3, or permit
  a CI rerun, merge, recovery, registry action, tag write, or publication. Those requirements stay
  OPEN until their exact live outcomes are independently evidenced. Keep Plans45–48 held until
  their actual prerequisites pass; do not weaken their same-run evidence or separate companion
  authorization boundaries.

### Additional canonical references for D-106

- `.planning/workstreams/quality-ratchet-release/STATE.md` and
  `.planning/workstreams/quality-ratchet-release/ROADMAP.md` — current Phase175 position, held
  plans, and the explicit phase-goal coverage blocker.
- `.planning/workstreams/quality-ratchet-release/REQUIREMENTS.md` §§72–74 — live evidence required
  by REL-13, REL-14, and REL-15.
- `.planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-80-PLAN-CHECK.md`
  and `175-80-SUMMARY.md` — retained executable-coverage finding and Plan80's bounded outcome.
- `.planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-45-PLAN.md`
  through `175-48-PLAN.md` — existing exact-candidate, same-run proof, companion, and phase-closeout
  sequence; these plans remain held.
- `.planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/.continue-here.md`
  — historical resume note still points to a pre-Plan80 wave; the active workstream STATE.md and
  ROADMAP.md supersede it for current routing.
- `.github/workflows/release-please.yml` and `.github/workflows/exact-public-proof.yml` — ordinary
  release, same-run proof, and linked rollup integration points.
- `lib/crosswake/release_candidate/workflow.ex`,
  `test/crosswake/release_candidate/workflow_test.exs`, and
  `test/crosswake/release_candidate/publication_record_test.exs` — local rollup and artifact
  contract tests; their synthetic inputs do not prove any live REL-13/14/15 outcome.

### Existing code insights for D-106

- `Crosswake.ReleaseCandidate.Workflow.rollup!/1` validates six child states and produces
  COMPLETE/PARTIAL/BLOCKED from supplied observations. Its local tests prove evaluator behavior,
  not the status of an actual Release Please run.
- The ordinary workflow calls the exact-public reusable workflow and then the linked release
  rollup. Plans45–48 already bind their live proof to the same ordinary run and retain the second
  companion as a separate, later authorization.
- The new observation must not promote source structure, local fixtures, or a readiness snapshot
  into satisfaction of the live publication requirements.

The phase `.continue-here.md` remains unmodified because it contains existing workspace edits.
Use the quality workstream's current STATE.md and ROADMAP.md for the active next action.

## Post-Plan82 terminal observation — 2026-10-05

Plan82 consumed its one authorized anonymous observation of the exact held candidate and ended
`UNKNOWN/HTTP_UNAVAILABLE` after four requests. The retained artifact has no CI run, check roster,
or current readiness snapshot, so the observation does not establish that the candidate is ready
or that any release prerequisite changed. Plan82 is terminal; its attempt and authorization must
not be replayed. Plan81's missing-credential stop is also terminal, and no credential setup or
rotation is needed.

- **D-107 — Wait for independent evidence; keep the release held.** Do not create another plan or
  provider attempt solely to recover from Plan82's unavailable response. Re-enter Phase 175 only
  when a genuinely new, independently produced, machine-verifiable signal supplies current,
  decision-relevant facts for the same exact candidate. At that point, use a fresh plan and
  preserve the existing review, authorization, attempt, and evidence boundaries. A new signal does
  not itself satisfy REL-13/14/15/17 or authorize a CI rerun, Gate 2, merge, recovery, registry
  action, tag write, or publication. Do not substitute a candidate. No recurring CI lane is added
  for this one-time readiness reconciliation.

**Current posture:** Phase 174 is the last completed phase; Phase 175 remains incomplete. Keep
REL-13/14/15/17 OPEN, candidate readiness BLOCKED, merge-policy UNKNOWN, release hold ACTIVE, and
Plans 175-45 through 175-48 held. No human UAT is pending; evidence evaluation remains automated.
The user-requested planning retry returned PLANNING INCONCLUSIVE: no Plan83 artifact was created,
and no provider, network, or CI call was made. It found no new independent candidate evidence, so
D-107 remains the active decision.

### Canonical references for D-107

- `175-82-SUMMARY.md` and `evidence/175-plan82-pr219-readiness.json` — consumed attempt result,
  missing current CI/readiness fields, and preserved release posture.
- `175-81-SUMMARY.md` — terminal zero-request credential-unavailable result; no credential action
  is required.
- `.planning/workstreams/quality-ratchet-release/STATE.md`, `ROADMAP.md`, and `REQUIREMENTS.md`
  §§72–74 — current handoff, phase ordering, and live REL-13/14/15 evidence requirements.
- `.planning/PROJECT.md` — settled zero-human verification, shift-left, no-loop, and recurring-CI
  decision.

## D-107 operational trigger — maintainer and CI recommendation — 2026-10-05

D-107 remains the decision: hold the release and wait. This review only makes its resume condition
concrete. A read-only local evidence search found no post-Plan82 exact-candidate CI receipt; no
provider or CI query was made.

**Recommended trigger:** a newly completed, naturally triggered run of the existing `Crosswake CI`
workflow for PR #219 that still binds all of these candidate identities: version `0.2.7`, base
`e51698528dc667ef89beb951e4eb1ec91da74981`, head
`696a27a3be1fcd56efe70923dc0ce286a1c41c6d`, and tree
`5279cae1daa1fbff3437b673df8ca231fb07c91f`. Its `phase168-candidate-ci-<head>` receipt must match
the run ID and attempt, and the completed run/check roster must include passing `ios-mirror-parity-proof`
and `Crosswake CI` aggregate checks. Capture the artifact while its current seven-day retention
window is open. A different head, base, or tree is a different candidate and needs fresh scope
resolution.

That signal authorizes **planning only**: run `$gsd-plan-phase 175 --ws quality-ratchet-release`
without repeating discussion, then require fresh exact-scope review and authorization before any
provider read. The plan must still establish current PR state, tag targets, and merge policy. A green
CI artifact does not close REL-13/14/15/17, clear the release hold, or authorize rerun, Gate 2, merge,
recovery, tag write, registry action, or publication.

The recorded run `36438452825` is historical and failed iOS mirror parity because the mirror lacked
`v0.2.6`; it is not a trigger. Plan82's UNKNOWN response, restored API availability by itself,
elapsed time, local test results, an unrelated green check, and a credential change also do not
qualify. Do not replay Plan82, add polling or another CI lane, or add a Mix status/telemetry surface:
those cannot create the missing current external fact. No new user-facing UI or API design applies;
this is maintainer release evidence. No human UAT or credential action is pending. If artifact expiry
repeatedly blocks release work, evaluate retention as a separate recurring-contract improvement;
there is not enough evidence to change it in this one-time reconciliation.

Three read-only reviews converged on this path: release-gate sequencing, CI/SRE recurring-value and
permission scope, and Elixir maintainer DX. GitHub's existing artifact mechanism already transfers
job evidence, while workflow permissions should remain least-privilege. References: [workflow
artifacts](https://docs.github.com/en/actions/concepts/workflows-and-actions/workflow-artifacts),
[pull request workflow events](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows),
and [GITHUB_TOKEN permissions](https://docs.github.com/en/actions/tutorials/authenticate-with-github_token).

## Resume after fresh exact-candidate evidence — 2026-10-06

After D-107, the user asked to keep Phase175 moving. A fresh anonymous public observation now
supplies a decision-relevant fact for the same exact candidate, so the D-107 wait condition is met
and planning resumes. This broadens the prior operational note: a new passing CI receipt is a
sufficient trigger, but a newly verified exact-candidate ref change or discrepancy can also trigger
planning. Neither trigger proves readiness.

- PR #219's public page reports state `OPEN` and exact head
  `696a27a3be1fcd56efe70923dc0ce286a1c41c6d`; the checks page still references only historical run
  `36438452825`.
- An anonymous exact-ref `git ls-remote` read reports source tag `ios-core-v0.2.6` at
  `998742856a37a97ae7247f6c532f9c154ea20885`. The mirror has `main` and `v0.2.5` at
  `424ab96ede1b92f2b751b54bce04c6e607f0f3c8`, while the exact `v0.2.6` ref query returned no ref.
- These observations independently confirm the historically known mirror-tag gap is still present.
  The current PR base OID, full job/check roster, artifact receipt, and merge policy remain
  unverified. Preserve the hold.

Sanitized details are recorded in
`evidence/175-public-candidate-signal-20261006.json`. No credential, CI rerun, tag write, merge,
registry action, or publication occurred. The exact next command is
`$gsd-plan-phase 175 --ws quality-ratchet-release --research`; research and patterns are stale
against the latest context, so refresh them and plan the safe tag-repair path. Execute only after the
plan passes review. Prepare all local verification and the create-only tag preflight first; the sole
human step, if still needed, is the final explicit authorization for that exact one-way tag write.

## Post-Plan83 exact-candidate scope confirmation — 2026-10-06

After Plan83 ended UNKNOWN/OBSERVATION_UNAVAILABLE, the user directed us to obtain the missing
current scope facts instead of waiting passively. Two anonymous, read-only GitHub REST GETs verified
the current PR #219 metadata and its exact head commit. Sanitized fields and source URLs are in
evidence/175-public-candidate-scope-20261006.json.

- PR #219 currently reports OPEN, not merged and not draft; base main is
  e51698528dc667ef89beb951e4eb1ec91da74981, and head
  696a27a3be1fcd56efe70923dc0ce286a1c41c6d matches the pinned candidate.
- The head commit's tree is 5279cae1daa1fbff3437b673df8ca231fb07c91f; its sole listed parent is
  the same pinned base. Base, head and tree therefore match Plan83's candidate scope.
- GitHub reports mergeable=true with mergeable_state=unstable; these metadata fields do not
  establish branch protection, required checks or merge-policy truth. The PR updated_at remains
  2026-09-28T14:46:02Z, although the public endpoints were read on 2026-10-06.

This independent scope observation satisfies the recorded trigger to resume Phase 175 discussion
and planning. It grants planning only. The full current CI roster, candidate artifact receipt,
effective merge policy/permissions, tag targets/policy and dry-run remain unverified. Plan83 and
Plans81/82 remain terminal and must never be replayed. Do not infer readiness or authorize a CI
rerun, tag write, Gate 2, merge, recovery, registry action or publication. REL-13/14/15/17 remain
OPEN; candidate readiness BLOCKED; merge-policy UNKNOWN; release hold ACTIVE; Plans45–48 HELD.

No new implementation decision is needed: carry forward D-107 and the existing fail-closed
operation boundaries. This is a fresh fact for a distinct plan, not a retry of a consumed attempt.

### Additional canonical reference for this scope refresh

- evidence/175-public-candidate-scope-20261006.json — anonymous current PR and commit identity
  fields that establish the exact base/head/tree scope for planning only.

## Post-Plan84 local twin decision — 2026-10-06

The user clarified that the missing "external observation" does not mean waiting for the First B2C
Adopter. It means a current live GitHub observation for release facts. Plan84's only live preflight
is terminal `UNKNOWN/OBSERVATION_UNAVAILABLE`; its actual provider request count remains unknown.
Do not retry Plan84, reuse its digest, access or rotate credentials, or infer zero requests.

The distinct next task is the local-only Plan85 process-boundary twin described in
`175-85-INTENT.md`. It must invoke the real Elixir coordinator and Node collector child process
against loopback fixtures, distinguish safe process/transport failure classes, and assert no
dry-run, decision, tag, or CI side effect. Keep production routing fixed to GitHub and expose no
general-purpose host or credential override. The twin grants no live GitHub or release evidence;
REL-13/14/15/17, the release hold, and Plans45–48 are unchanged. No adopter, credentials, human UAT,
or external request is needed for this local task.

The planning command `$gsd-plan-phase 175 --ws quality-ratchet-release --skip-research` completed with research skipped. `175-85-PLAN.md` is one integrated autonomous Wave 1 plan with two sequential tasks and no dependencies; `175-85-PLAN-CHECK.md` returned VERIFICATION PASSED. The scoped pattern and validation addenda ground this local contract in current source. The execution index selects only Plan85 in Wave 1. Do not repeat discussion or planning. The next command at that planning handoff was `$gsd-execute-phase 175 --ws quality-ratchet-release --wave 1`; the execution result below supersedes that command. Planning did not itself execute the twin or reopen the live acquisition/release gate.

## Plan85 local execution handoff — 2026-10-06

Phase174 is the last completed phase. Plan85 completed both local-only Wave 1 tasks: the real
Mix/Elixir coordinator, bounded Port runner and Node child reached one fixed-route loopback GET.
Closed process/HTTP diagnostics, strict envelopes, exact limits and bounded cleanup passed. The
focused Plan85 ExUnit and Node suites each passed 21 tests; Plan84 regressions passed 46. The
broader release fixture and collection-ratchet bundle passed 388 tests, zero failures. The final
full offline Mix gate passed 2,275 tests, zero failures/invalid tests (74 excluded). Five scoped
source/test commits are recorded in `175-85-SUMMARY.md`. Plan85 made no provider or release operation.

Plan84 remains terminal `UNKNOWN/OBSERVATION_UNAVAILABLE`; its one provider request intent,
zero confirmed requests and unknown actual request count/cause are unchanged. Its plan, summary,
receipt and lifecycle fingerprints still match. Never replay that attempt or reuse its digest.
The local twin diagnoses current process behavior; it does not establish the historical cause.

**No next GSD command is eligible.** Fresh, independently verifiable current candidate facts, or new evidence supporting a materially distinct bounded observation path, must support a separately scoped plan and its required authorization before work reopens.
The generic progress resolver may propose Phase175 execution from held summary gaps; the workstream index has no runnable plan. Do not use `$gsd-progress --next` to bypass this handoff.
Do not repeat completed discussion, planning or execution, or start another acquisition attempt
without that new evidence. Plans46–48 remain the only incomplete indexed plans and are blocked.
No credentials, adopter observation or human UAT are pending for this local task.
REL-13/14/15/17 remain OPEN; candidate readiness BLOCKED; merge policy UNKNOWN; release hold ACTIVE; Plans45–48 HELD; Phase175 INCOMPLETE.

## Post-Plan86 exact-head check-run observation — 2026-10-06

The user asked to keep Phase175 moving after Plan86. A bounded anonymous read of the complete
GitHub check-run roster for the same exact candidate (PR #219, base
`e51698528dc667ef89beb951e4eb1ec91da74981`, head
`696a27a3be1fcd56efe70923dc0ce286a1c41c6d`) returned 49/49 terminal checks: 47 success and two
failures (`Crosswake CI` and `ios-mirror-parity-proof`). The newest completion is
`2026-09-28T15:09:49Z`; the parity job's failing step is `Check iOS SwiftPM mirror parity`.
This fills the previously unknown complete roster but confirms it is stale and failing; it does
not create a passing CI receipt or readiness.

Sanitized check-run data and canonical digests are in
`evidence/175-public-candidate-check-runs-20261006.json`. The new independent exact-head facts
reopen **planning only**, without repeating discussion. Plan the safe, separately authorized
mirror-parity repair path from this exact evidence. No CI rerun, tag write, Gate 2, merge, recovery,
registry action, or publication is authorized; Plan84 and earlier consumed attempts remain
terminal and immutable. Keep REL-13/14/15/17 OPEN, readiness BLOCKED, merge policy UNKNOWN, the
release hold ACTIVE, and Plans45–48 HELD until their exact prerequisites are satisfied.

## Current handoff after Plan116 — 2026-10-09

Plan115 used its exact one-time approval, then stopped before it saved a complete current-state
snapshot. Its result says the status is UNKNOWN, the public-request and Git-operation totals are
unknown, no tag dry run or tag attempt occurred, and the diagnostic is absent. We do not know which
step failed. Its approval and attempt are spent; never replay either or claim that we recovered the
historical cause.

Plan116 is complete local-only work. It now records a future failure as a closed safe step and keeps
the API and Git counts separate when they are known. Fake tests prove that local behavior only; they
do not tell us today's release facts or make the release ready.

The active `quality-ratchet-release/STATE.md` and `ROADMAP.md` handoff supersede older "wait" notes
in this file: the next step is to plan one distinct, bounded check of current facts for the same held
candidate. Planning is allowed now. The plan must explain in plain language how this check differs
from Plan115 beyond simply making a new attempt. If it cannot show a meaningful difference that
uses Plan116's repaired diagnostics and count tracking, stop without preparing a scope or asking for
another approval.

This planning step performs no credential lookup, provider request, remote Git operation, CI query,
tag write, merge, registry action, or publication. Plan115's approval cannot be reused. Any later
read needs a new attempt, a displayed exact scope, and a separate user ALLOW for that exact scope.
The user has already completed Git Credential Manager setup; do not ask for setup or credential
rotation again. Never request or record secrets. Even a complete fresh read would not authorize a
tag write or release action: Plan106 remains held until the exact preflight and a separate tag
decision are satisfied, and REL-13/14/15/17 and the release hold remain unchanged.

## Current handoff after Plan117 — 2026-10-09

Plan117's local checks passed: 54 fake collector tests and 20 focused ExUnit tests. Its one explicitly approved read ended `UNKNOWN / OBSERVATION_UNAVAILABLE` at `SUBTREE_SPLIT / PROCESS / PROCESS_EXIT_NONZERO`. The independently inspected receipt records 7 exact public requests, 11 exact Git operations, one credential-helper check, two permission checks, zero dry runs, and zero tag attempts. It established no current candidate, permission, or policy facts. The attempt and its ALLOW are spent; do not retry them. Plan115's old receipt and its unknown cause remain unchanged.

The failure stage has a concrete local lead. `plan105_mirror_tag_collector.mjs` clones with `--no-checkout` and then invokes `git subtree split`. Plan98/99 reproduced and fixed this same sequence in the sibling Plan87 collector by checking out the exact source commit first. Plan a local-only Plan105 repair from this new result; do not make another live read until the repair is planned and verified. The exact next GSD command is `$gsd-plan-phase 175 --ws quality-ratchet-release --skip-research`.

Last completed phase: 174. Phase175 remains incomplete. Plan106 remains held until a later fresh read yields a complete, independently inspected `PREFLIGHT_READY` result and the tag action has its own exact decision. REL-13/14/15/17 remain open; readiness is blocked; write permission is unknown; tag authority is none; merge policy is unknown; release hold is active.

## Plan121 local stderr diagnosis — 2026-10-09

Plan121's one-use ALLOW and live attempt are spent and immutable. Its sanitized terminal result was
`UNKNOWN / OBSERVATION_UNAVAILABLE` at `SUBTREE_SPLIT / PROCESS / PROCESS_STDERR_NONEMPTY`; counts
were 7 public requests, 12 Git operations, 1 helper check, 2 permission checks, and zero dry-run or
tag attempts. It established no current release facts.

A separate no-network reproduction against the pinned source commit ran the exact
`git subtree split --prefix=packages/crosswake-shell-core-ios 998742856a37a97ae7247f6c532f9c154ea20885`
command. It exited 0, printed the expected split OID `424ab96ede1b92f2b751b54bce04c6e607f0f3c8`,
and wrote 3,804 sequential Git subtree progress records to stderr. The collector rejects any stderr
bytes even when the process succeeded. The raw stream was classified in memory and not retained.
Evidence: `evidence/175-plan121-subtree-stderr-reproduction.json`.

The distinct repair boundary is local and narrow: accept only fully recognized Git subtree progress
for a successful `SUBTREE_SPLIT`, while rejecting arbitrary stderr, nonzero exit, timeout,
truncation, split-OID mismatch, and tree mismatch. Prove both allowed and rejected cases with
offline tests before planning a fresh read. This does not authorize another remote read or any
release action. A future read requires a new scope and its own exact ALLOW. Plan106 remains held;
REL-13/14/15/17 remain OPEN; readiness remains BLOCKED; release hold remains ACTIVE.

## Plan122 repair complete — 2026-10-09

Plan122 completed the local repair. The fake-only Node suite passed 90 tests, the pinned Plan121
artifact fingerprints remained unchanged, the active release-hold assertions passed, and the
scoped planning diff check passed. The collector now accepts only a complete bounded subtree
progress stream on successful `SUBTREE_SPLIT`, while retaining exact split stdout and both tree
identity checks. See `175-122-SUMMARY.md` and
`evidence/175-plan122-subtree-progress-shape.json`.

This closes the local process-output blocker and permits planning one distinct, bounded observation
with a fresh scope. It establishes no current source, mirror, pull-request, permission, or policy
facts. Plan121's exact ALLOW and attempt remain spent; never retry or reuse them. Any later read
requires its own exact ALLOW after the new scope is displayed. Planning itself performs no remote
access. Plan106 remains held; REL-13/14/15/17 remain OPEN; readiness BLOCKED; write permission
UNKNOWN; tag authority NONE; merge policy UNKNOWN; release hold ACTIVE.

## Resume after Plan126 wrapper repair — 2026-10-10

The user directed a local repair and checks after Plan126's read ended UNKNOWN without a retained
failure detail. The repair is now complete and fake-tested: the Elixir wrapper preserves only a
safe allowlisted failure code for collector errors, invalid output, and exceptions, while uncertain
counts remain UNKNOWN and raw failure text is discarded. The focused ExUnit suite passed 31 tests;
warnings-as-errors compilation, formatting, and scoped diff checks passed.

This is the distinct local repair needed to resume planning; it does not explain which lower-level
failure happened during Plan126 and it supplies no current release facts. Plan one fresh bounded
read only if current facts are still needed. Planning has no external access. The new plan must
display a new exact scope and stop for a new ALLOW or HOLD before any provider, credential/helper,
or remote-Git operation. Plan126's attempt and approval remain spent; preserve the release holds.

## User instruction superseding repetitive conversational checkpoints — 2026-10-11

The user explicitly authorizes/allows the remaining OpenGSD Phase175 release workflow. See workstream PHASE175-STANDING-AUTHORIZATION.md. Older decisions requiring another typed human reply at each card/leg are superseded prospectively for this scope. Bind each concrete operation internally; do not replay consumed bindings, broaden scope, bypass policy or retry uncertain delivery. Current facts, exact candidate identity, same-run proof, registry checks, privacy and all fail-closed automated gates remain mandatory. This changes approval orchestration, not publication claims or acceptance criteria.
