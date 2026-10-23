# Phase 175: Rehearsal and Publish - Research

**Researched:** 2026-09-29 (source-boundary refresh; historical recovery pass retained below)
**Domain:** Full-clone Git subtree source evidence before a bounded iOS mirror tag preflight
**Confidence:** MEDIUM

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

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

### Additive locked decisions D-43 through D-61 (verbatim from current CONTEXT.md)

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

- **D-53:** Plans 175-49 and 175-50 remain blocked historical attempts. Do not resume them, repeat
  either attempt's dry-run, or reuse either receipt digest. A replacement plan must gather a new
  complete preflight and calculate a new digest. The direct-Git dry-run passes only when its result
  proves exactly one accepted new `refs/tags/v0.2.6` ref; exit status 0 by itself is insufficient.
  Failed, incomplete, changed, or ambiguous evidence remains `BLOCKED_PREFLIGHT`, records zero
  writes, and exposes no `create_exact_tag` or `hold` choice. Any future one-way action requires a
  separate exact decision bound to the fresh ref, object, and digest. Context and planning grant no
  tag, release, merge, recovery, or publication authority.

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

### the agent's Discretion

- Final file naming and internal section ordering within `docs/RELEASE-INCIDENT-RESPONSE.md`, beyond
  the structural constraints in D-15 and D-16.
- Exact wording of the three checkpoint prompts, subject to D-08 through D-11.
- Implementation shape of the `assertFullScope` helper and the version-literal CI check.
- Wave decomposition and task granularity within the structure recorded here.

### Deferred Ideas (OUT OF SCOPE)

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
</user_constraints>

<phase_requirements>
## Phase Requirements

These are the current requirement texts and status; this source-boundary follow-up completes none of the open release requirements. [VERIFIED: .planning/workstreams/quality-ratchet-release/REQUIREMENTS.md:67-80] [VERIFIED: .planning/workstreams/quality-ratchet-release/STATE.md:56-89]

| ID | Current requirement excerpt (verbatim) | Research support |
|---|---|---|
| REL-10 | "A retire/backfill runbook covering Hex, the iOS mirror, and Maven is committed before the first publish of this milestone" | Historical Gate 1 breach remains irreversible; exact remote ancestry remains a later gate. [VERIFIED: .planning/workstreams/quality-ratchet-release/REQUIREMENTS.md:67-67] |
| REL-11 | "All three publish legs are rehearsed to the last safe step" | Existing rehearsal outcome is preserved; a source split diagnostic is narrower. [VERIFIED: .planning/workstreams/quality-ratchet-release/REQUIREMENTS.md:68-68] |
| REL-12 | "The lower-blast-radius held companion PR publishes live as the fire-drill for the repaired clean-room lane" | Already complete; preserve its evidence and separate REL-10 breach. [VERIFIED: .planning/workstreams/quality-ratchet-release/REQUIREMENTS.md:69-69] |
| REL-13 | "A fresh successor core candidate publishes through one authorized ordinary version-generalized run to Hex, the iOS mirror, and Maven, each confirmed independently." | OPEN; source diagnosis and any later dry-run are preliminary evidence only. [VERIFIED: .planning/workstreams/quality-ratchet-release/REQUIREMENTS.md:70-70] |
| REL-14 | "`exact-public-proof` executes and passes in that same successor ordinary run" | OPEN; requires a future authorized ordinary run and artifact. [VERIFIED: .planning/workstreams/quality-ratchet-release/REQUIREMENTS.md:71-71] |
| REL-15 | "That successor run's linked release rollup reports `COMPLETE` from all six core children" | OPEN; second companion remains a separate direct Hex fact and gate. [VERIFIED: .planning/workstreams/quality-ratchet-release/REQUIREMENTS.md:72-72] |
| REL-16 | "A multi-registry partial-failure response table exists before the first publish" | Already complete; preserve incident authority. [VERIFIED: .planning/workstreams/quality-ratchet-release/REQUIREMENTS.md:73-73] |
| REL-17 | "Linked release, recovery, and companion publishers share one fail-closed validator over an immutable per-operation evidence envelope" | OPEN; no source or dry-run result alone closes the shared guard or authorizes a release. [VERIFIED: .planning/workstreams/quality-ratchet-release/REQUIREMENTS.md:74-74] |
| DOC-04 | "`docs/COMPANION-PUBLISH-RUNBOOK.md`'s \"this pipeline only publishes 0.2.1\" section is deleted" | Already complete; preserve live documentation. [VERIFIED: .planning/workstreams/quality-ratchet-release/REQUIREMENTS.md:78-78] |
| DOC-06 | "Residual `splitsh-lite` references are removed; `git subtree split` is documented as the durable mirror-split mechanism" | Already complete; current source diagnostic continues to use the documented splitter. [VERIFIED: .planning/workstreams/quality-ratchet-release/REQUIREMENTS.md:80-80] |
</phase_requirements>

## Summary — Current Planning Basis (2026-09-29)

Plan 175-53 is an immutable blocked attempt. Its receipt quotes `"stage": "BLOCKED_PREFLIGHT"`, `"blocked_reason_code": "FULL_CLONE_SPLIT_FAILED"`, `"boundary": "SOURCE"`, `"reserved": false`, `"invocations_reserved": 0`, `"attempts": 0`, and `"decision": null`. The summary says the fresh full-clone split produced no usable OID, and no dry-run or audit followed. The receipt does not capture enough facts to determine whether the failure was process invocation, nonzero exit, missing history, missing commit, or unusable output. That cause is **unknown**, not a diagnosis. [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence/175-ios-tag-026-plan53.json:1-27] [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence/175-ios-tag-026-plan53.json:68-107] [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-53-SUMMARY.md:54-60] [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-53-SUMMARY.md:84-86]

The approved D-57 through D-61 add one source diagnostic boundary: make one fresh isolated full-clone attempt, retain only bounded classifications, permit at most one proven clone/invocation setup correction, and stop on source/path/policy uncertainty. If the split passes, only a distinct fresh preflight and new digest can reach the durable one-invocation dry-run reservation and later independent audit. Every earlier Plan 175-49 through 175-53 receipt/digest remains historical, Plans 175-44 and 175-45..48 remain held, and REL-13/REL-17 remain open. [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-CONTEXT.md:779-803] [VERIFIED: .planning/workstreams/quality-ratchet-release/STATE.md:56-89]

**Primary recommendation:** Plan a new evidence-only source diagnostic with a closed result classifier and durable, sanitized blocked receipt. Make progression to a fresh full preflight conditional on an exact valid split result; stop before reservation on every other result. This is planning guidance, not release authority. [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-CONTEXT.md:779-803]

## Project Constraints (from AGENTS.md) — Current Follow-up

- Keep Crosswake a Phoenix-first route-policy/runtime-contract system with explicit per-route ownership, semantic typed versioned low-frequency bridges, and honest cached-read-only versus local-mutation claims. [VERIFIED: AGENTS.md:29-48]
- Preserve fail-closed denials and machine-readable proof; a missing or ambiguous source result must remain blocked. [VERIFIED: AGENTS.md:44-48] [VERIFIED: AGENTS.md:73-82]
- Treat diagnostic output as product surface, but prefer the existing one-command maintainer path over new label taxonomy, UI, or workflow lane. [VERIFIED: AGENTS.md:44-48] [VERIFIED: AGENTS.md:73-82]
- Keep adopter identity and private mutation content out of durable artifacts and logs; do not infer or search for identifying adopter details. In this release follow-up, D-60 further prohibits raw Git streams, command/environment details, paths, remotes, and credential/helper data in the failure receipt. [VERIFIED: AGENTS.md:52-61] [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-CONTEXT.md:793-798]
- Keep Android frozen at its current generator/Maven/JVM/vector posture; this source diagnostic adds no Android feature or device proof. Do not expand into native controls, companions, generic sync/storage, commerce, dashboard, or showcase breadth. [VERIFIED: AGENTS.md:46-50]
- Resolve the quality workstream explicitly from its own STATE/ROADMAP/REQUIREMENTS; the parked adopter workstream remains separate. Use automated artifact checks for automatable claims, and reserve human action for unavoidable credentials/external approval/irreversible trust actions. [VERIFIED: AGENTS.md:64-82] [VERIFIED: .planning/workstreams/first-b2c-adopter-readiness/STATE.md:1-25]
- Any actual changed decision would require synchronized requirement/roadmap/state/ADR/support/guide updates; this research records no changed decision and edits only the canonical phase research. [VERIFIED: AGENTS.md:83-94]

## Architectural Responsibility Map — Current Follow-up

| Capability | Primary tier | Secondary tier | Rationale |
|---|---|---|---|
| Isolated clone, Git invocation, stream capture | Maintainer Mix/shell adapter | Git process | The adapter owns bounded I/O and preserves process exit separately from parsed output. [CITED: https://hexdocs.pm/elixir/System.html#cmd/3] [VERIFIED: script/release_candidate/ios_mirror.sh:65-70] |
| Full-history, source-commit, and split checks | Git source boundary | Pure classifier | A subtree split consumes selected history and prints one commit ID after success; presence and object type must be checked before use. [CITED: https://github.com/git/git/blob/master/contrib/subtree/git-subtree.adoc] [CITED: https://git-scm.com/docs/git-cat-file] |
| Bounded result and receipt projection | Pure Elixir domain function | Maintainer text/JSON surface | Existing `Mirror.evaluate!/1` accepts an explicit map and returns a bounded state/correction projection; D-60 makes raw streams and environment inadmissible evidence. [VERIFIED: lib/crosswake/release_candidate/mirror.ex:27-80] [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-CONTEXT.md:793-803] |
| Conditional preflight and dry-run | New plan's evidence procedure | GitHub/Git remotes | Source success is only an entry condition for fresh remote/PR/policy evidence and a new durable reservation. [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-CONTEXT.md:788-792] |
| Publication authority | REL-17 shared validator and distinct one-way decisions | Protected workflow | A source split or exact dry-run cannot authorize public writes, Gate 2, or publication. [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-CONTEXT.md:341-383] [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-CONTEXT.md:788-803] |

## Standard Stack — Current Follow-up

| Component | Version / status | Use and provenance |
|---|---|---|
| Git CLI and existing `git subtree` invocation | Local `git version 2.41.0` observed in this research pass; diagnostic only | Use the existing subtree mechanism with the same prefix/ref/options as the source contract; the prefix argument is quoted verbatim as `--prefix=packages/crosswake-shell-core-ios`. [VERIFIED: local `git --version`] [VERIFIED: script/release_candidate/ios_mirror.sh:65-70] [CITED: https://github.com/git/git/blob/master/contrib/subtree/git-subtree.adoc] |
| Elixir/Mix and ExUnit | Local `Mix 1.19.5`, OTP 27 observed in this pass | Keep command effects at the Mix/shell edge and classification deterministic; use existing ExUnit conventions only in the later implementation plan. [VERIFIED: local `mix --version`] [VERIFIED: test/crosswake/release_candidate/mirror_test.exs:1-4] [CITED: https://hexdocs.pm/elixir/System.html#cmd/3] |
| Existing JSON evidence convention | The historical receipt's schema is quoted verbatim as `"crosswake-ios-tag-preflight/v2"`; it is **historical only** | A new plan supplies a new schema/version, path, and digest; do not reuse the Plan 53 artifact identity. [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence/175-ios-tag-026-plan53.json:1-14] [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-CONTEXT.md:779-803] |

**Installation:** None. The follow-up can use existing Git, Elixir/Mix, and repository-owned release code; no new package or package-legitimacy audit is needed. [VERIFIED: script/release_candidate/ios_mirror.sh:1-13] [VERIFIED: lib/crosswake/release_candidate/mirror.ex:1-8]

## Architecture Patterns — Current Follow-up

```text
new plan + exclusive blocked receipt
  -> isolated full clone and exact source selection
  -> full-history / source-commit / split invocation checks
  -> bounded pure classification
       ├─ incomplete, failed, invalid, or unknown -> SOURCE blocked; stop
       └─ exact split OID and commit object -> new complete read-only preflight
             -> fresh digest and all gates pass
             -> durable reservation -> at most one authenticated dry-run
             -> post-observations -> independent audit
             -> evidence only; release hold remains
```

The stop/progression edges above come from D-57 through D-61; no edge leads directly to a tag write. [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-CONTEXT.md:779-803]

### Pattern 1: Classify the source result from bounded facts

The new classifier should distinguish **invocation failure** (process could not be started; exit unavailable), **nonzero exit** (process ran and failed; record bounded exit status), and **invalid/missing OID** (a zero exit without exactly one valid split commit). Treat full-history and selected-source-commit availability as independent tri-state inputs: true, false, or unknown. This category set is the approved D-57 design; exact new reason-code spellings belong to the new plan/schema and are not asserted as existing repository values. [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-CONTEXT.md:779-783]

Check the isolated clone itself, not a different checkout: Git documents that a depth-limited clone truncates history, and `git subtree split` extracts synthetic history from the selected local commit. A successful split prints one commit ID; validate its syntax and that the object is a local commit before moving to mirror evidence. This is a planning inference from Git's documented contracts, not proof that shallow history caused Plan 53. [CITED: https://git-scm.com/docs/git-clone] [CITED: https://github.com/git/git/blob/master/contrib/subtree/git-subtree.adoc] [CITED: https://git-scm.com/docs/git-cat-file] [ASSUMED]

The existing shell adapter quotes the source expression `git -C "$RELEASE_REPO" subtree split` and then pipes it to `tail -1`; the pipeline's final-line result alone does not establish the split process exit. A new procedure should capture that exit explicitly and require complete, bounded output before classifying an OID. This is a code-inspection inference about the current shell shape; it does not identify Plan 53's cause, because that plan used a separate isolated clone and its raw failure was not retained. [VERIFIED: script/release_candidate/ios_mirror.sh:65-70] [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-53-PLAN.md:109-111] [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-53-SUMMARY.md:84-86]

### Pattern 2: One attributable attempt, then stop

Plan exactly one new isolated full-clone attempt. A narrowly scoped local correction is eligible only if bounded facts prove a clone or invocation setup defect; otherwise record the source block and route a source/path/policy correction through review. Do not add automatic retries, change the split algorithm, or repeat a prior driver. If correction would require another ambiguous invocation, make its evidence identity and authorization explicit in a new reviewed plan. [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-CONTEXT.md:784-787]

### Pattern 3: Sanitize before durability

The receipt needs a fixed schema, source-boundary reason, nullable exit status, normalized Git version, and bounded true/false/unknown or count facts for clone history, source commit, OID, and split availability. Retain no raw stdout/stderr, arguments, environment, local paths, remote details, credentials, helper configuration, or raw-output hashes. Compute the digest over only the sanitized canonical representation and read it back before treating the receipt as durable. The Plan 53 receipt's `"readback_ok": true`, `"reservation_readback_ok": false`, and `"invocations_reserved": 0` are historical facts, not reusable fields with live authority. [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-CONTEXT.md:793-803] [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence/175-ios-tag-026-plan53.json:10-14] [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence/175-ios-tag-026-plan53.json:68-72]

### Pattern 4: Conditional fresh dry-run boundary

Only after exact source success, collect the complete fresh source/mirror ref maps, exact Git targets, PR head/base/checks, effective policy, and permission facts; calculate a **new** digest. Reserve durably before a sole authenticated `git push --dry-run --porcelain`; classify its complete stdout by D-54's closed grammar and stderr only as D-55's two-state diagnostic. Then perform the new plan's post-observations and independent audit if eligible. Git documents that `--dry-run` does not send updates and `--porcelain` writes tab-separated per-ref status to stdout, with `*` denoting a new ref. The existing accepted row values quoted verbatim in D-54 are `*`, `refs/tags/v0.2.6`, and `[new tag]`; a zero exit without a complete exact row is still blocked. [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-CONTEXT.md:431-453] [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-CONTEXT.md:788-792] [CITED: https://git-scm.com/docs/git-push]

### Idiomatic Elixir/Mix seam

`System.cmd/3` accepts an executable and argument list and returns output with exit status; arguments are passed as binaries rather than shell-expanded text. Keep command invocation and bounded capture at this edge, then pass a small typed observation map to a pure classifier. The official `Mix.Shell.Process` shell sends messages to the calling process mailbox, which supports deterministic operator-text assertions in later tests without capturing raw command output. `System.cmd/3` does not by itself provide separate retained stdout/stderr; the adapter must explicitly prevent diagnostic stderr from becoming console output or receipt data. [CITED: https://hexdocs.pm/elixir/System.html#cmd/3] [CITED: https://hexdocs.pm/mix/Mix.Shell.Process.html] [ASSUMED]

## Code Examples — Current Follow-up

The following is a **planning sketch**, not an executable release procedure; run it only in the newly planned isolated clone and capture every stream privately. The prefix is quoted verbatim from the existing shell source, while the placeholder commit/OID values are deliberately not repository values. Git documents the history, object, and split checks. [VERIFIED: script/release_candidate/ios_mirror.sh:65-70] [CITED: https://git-scm.com/docs/git-rev-parse] [CITED: https://git-scm.com/docs/git-cat-file] [CITED: https://github.com/git/git/blob/master/contrib/subtree/git-subtree.adoc] [ASSUMED]

```bash
git rev-parse --is-shallow-repository       # require a complete observation of "false"
git cat-file -e '<source-commit>^{commit}' # require local source commit
git subtree split --prefix=packages/crosswake-shell-core-ios '<source-commit>'
git cat-file -e '<split-oid>^{commit}'      # only after a zero-exit, exact single-OID split result
```

An implementation should pass a typed observation to a pure function and let the adapter serialize only the sanitized decision. Exact function names and new reason-code strings remain plan-local design choices. [VERIFIED: lib/crosswake/release_candidate/mirror.ex:27-80] [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-CONTEXT.md:793-803] [ASSUMED]

## Don't Hand-Roll — Current Follow-up

| Problem | Use instead | Reason |
|---|---|---|
| Synthetic subtree-history algorithm | Git's existing `subtree split` | Its output identity is defined by selected history and split options; D-58 forbids algorithm changes in this follow-up. [CITED: https://github.com/git/git/blob/master/contrib/subtree/git-subtree.adoc] [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-CONTEXT.md:784-787] |
| Source success inferred from a shell pipeline's last line | Explicit process status, strict bounded stdout parse, local commit-object check | Git's success contract is a single printed commit ID; exit and object availability are separate facts. [CITED: https://github.com/git/git/blob/master/contrib/subtree/git-subtree.adoc] [CITED: https://git-scm.com/docs/git-cat-file] |
| New publication authority or dashboard | Existing REL-17 guard and maintainer text/JSON | D-61 keeps this rare diagnostic at the current operator seam. [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-CONTEXT.md:799-803] |

## Common Pitfalls — Current Follow-up

1. **Diagnosing from the old receipt.** `FULL_CLONE_SPLIT_FAILED` is the terminal class; the missing exit/output facts cannot distinguish cause. Record unknown explicitly. [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence/175-ios-tag-026-plan53.json:1-27] [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-53-SUMMARY.md:84-86]
2. **Trusting clone intent instead of history facts.** A command described as “full clone” is not evidence that the actual isolated clone has complete history or the selected commit. Check both before splitting. [CITED: https://git-scm.com/docs/git-clone] [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-CONTEXT.md:779-783]
3. **Promoting a matching-looking OID.** A line of 40 hex characters without zero exit, exact stdout cardinality, and a local commit object does not satisfy the documented split success contract. [CITED: https://github.com/git/git/blob/master/contrib/subtree/git-subtree.adoc] [CITED: https://git-scm.com/docs/git-cat-file]
4. **Leaking diagnostics through the operator shell.** Merged stderr, exception text, or debug command echoes can bypass receipt redaction. Keep diagnostics inside bounded private capture and emit only reason code plus one safe next action. [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-CONTEXT.md:793-803] [CITED: https://hexdocs.pm/elixir/System.html#cmd/3]
5. **Treating source success as release readiness.** It permits a new complete preflight; it is neither an accepted one-ref dry-run nor CI revalidation, Gate 2, or a tag decision. [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-CONTEXT.md:788-803] [VERIFIED: .planning/workstreams/quality-ratchet-release/STATE.md:81-89]

## Validation Architecture — Current Follow-up

`workflow.nyquist_validation` is `true`; the new plan should map source-boundary classification to automated checks while leaving release gates open. The repo already uses ExUnit mirror input mutations, and Plan 53 had a local synthetic parser conformance matrix. This research ran no tests. [VERIFIED: .planning/config.json:10-14] [VERIFIED: test/crosswake/release_candidate/mirror_test.exs:28-49] [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-53-PLAN.md:115-119]

| Behavior to prove in new plan | Evidence/check | Stop condition |
|---|---|---|
| Source classifier is total and non-vacuous | Pure cases for invocation failure, nonzero exit, zero-exit invalid/missing OID, wrong object type, incomplete/unknown history or commit, and valid exact split. [ASSUMED] | Any unclassified or unknown input stays at SOURCE. [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-CONTEXT.md:779-783] |
| Source attempt remains one-attempt bounded | Artifact inspection of new receipt, invocation counter, and stop state. [ASSUMED] | No repeat on uncertain result; old Plan 53 receipt remains untouched. [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-CONTEXT.md:784-787] |
| Receipt is private and durable | Closed-key schema, bounded-size and canonical-digest/readback checks; seeded forbidden-field/value cases. [ASSUMED] | Any write/readback failure stops before remote dry-run. [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-CONTEXT.md:793-803] |
| Conditional dry-run cannot promote release authority | Check that only exact split plus complete fresh preflight permits reservation, that one exact porcelain result reaches independent audit, and that all final artifacts still show zero writes/null decision. [ASSUMED] | No tag, CI rerun, merge, Gate 2, recovery, or publisher action in this follow-up. [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-CONTEXT.md:788-803] |

## Environment Availability — Current Follow-up

| Dependency | Required by | Available in research environment | Boundary |
|---|---|---|---|
| Git | New isolated clone and subtree source check | Yes: `git version 2.41.0`. [VERIFIED: local `git --version`] | No live clone or split was run in this research. |
| Elixir/Mix | Existing maintainer command seam | Yes: `Mix 1.19.5`, OTP 27. [VERIFIED: local `mix --version`] | No Mix task or test was run. |
| jq | Historical canonical JSON projection | Yes: `jq-1.7.1-apple`. [VERIFIED: local `jq --version`] | New schema/digest must be chosen by the new plan. |
| GitHub CLI | Conditional fresh PR/policy evidence | Installed (`gh` found). [VERIFIED: local `command -v gh`] | Authentication, permission, and current remote facts were not probed. |
| Context7 | Official library lookup | MCP and CLI unavailable in this session. [VERIFIED: tool inventory and local `command -v ctx7`] | Official Git/Elixir/OWASP pages were read directly. |

## Security Domain — Current Follow-up

Using the ASVS **4.0** chapter numbering in the research template: V2 Authentication and V4 Access Control apply to the authenticated dry-run permission boundary; V5 Validation applies to strict command-result, OID, ref, and receipt validation; V6 Stored Cryptography applies to the existing SHA-256 digest rather than custom cryptography. V3 application sessions are outside this maintainer operation. The practical threats are spoofed source results, stale or ambiguous authorization evidence, and information disclosure through raw diagnostics; the controls are bounded classification, fresh reads, immutable per-attempt receipt identity, and redaction before output. This is an application of ASVS categories to the phase's existing release stack, not a claim that Plan 53 passed those controls. [CITED: https://github.com/OWASP/ASVS/tree/master/4.0/en] [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-CONTEXT.md:341-383] [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-CONTEXT.md:793-803]

## Assumptions and Open Questions — Current Follow-up

| ID | Claim or question | Planning treatment |
|---|---|---|
| A3 | A new pure classifier may fit beside the existing `Mirror.evaluate!/1` without changing its four-mode publication semantics. [ASSUMED] | Let the planner choose the smallest private module/function seam; require no side-effect path changes. |
| A4 | The precise local clone/invocation setup defect is unknown from Plan 53 evidence. [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-53-SUMMARY.md:84-86] | The new attempt must measure bounded facts before any correction; no speculative repair. |
| A5 | A future source pass can be followed by the complete D-59 preflight within one new plan. [ASSUMED] | Make this conditional. If the source step fails, stop without reservation; if it passes, recompute every mutable fact and digest. |

## Sources — Current Follow-up

- Primary repository truth: current `175-CONTEXT.md` D-53..D-61, `175-53-SUMMARY.md`, digest-bound Plan 53 receipt, current workstream `STATE.md`/`ROADMAP.md`/`REQUIREMENTS.md`, and opened shell/Elixir source cited above. [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-CONTEXT.md:420-453] [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-CONTEXT.md:779-803]
- Official technical sources: [Git clone](https://git-scm.com/docs/git-clone), [Git subtree manual](https://github.com/git/git/blob/master/contrib/subtree/git-subtree.adoc), [Git cat-file](https://git-scm.com/docs/git-cat-file), [Git push](https://git-scm.com/docs/git-push), [Elixir System.cmd/3](https://hexdocs.pm/elixir/System.html#cmd/3), [Mix.Shell.Process](https://hexdocs.pm/mix/Mix.Shell.Process.html), [actions/checkout full-history option](https://github.com/actions/checkout#fetch-all-history-for-all-tags-and-branches). Current official pages were accessed in this session; Context7 MCP and `ctx7` CLI were unavailable. [CITED: https://github.com/actions/checkout#fetch-all-history-for-all-tags-and-branches]
- Confidence: HIGH for local stopped state and locked decisions; MEDIUM for the proposed bounded classification and Elixir seam because it remains unimplemented; LOW for Plan 53 root cause, which cannot be reconstructed from sanitized historical evidence. [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-53-SUMMARY.md:84-99] [ASSUMED]

## Historical Recovery Snapshot (2026-09-24; superseded for current planning)

The authorized ordinary Release Please run `36035737504` for the `0.2.4` merge `f3827d0bf4131badd96d04d924f9faca2789d284` succeeded at Hex, failed at the iOS and Maven jobs, and skipped both clean-room jobs and exact-public proof. The normalized run quotes `"run_id": 36035737504`, `"merge_oid": "f3827d0bf4131badd96d04d924f9faca2789d284"`, `"disposition": "PARTIAL"`, and `"retry_or_recovery_performed": false`. The independent registry snapshot quotes `"coordinate": "crosswake@0.2.4", "present": true`, `"coordinate": "refs/tags/v0.2.4", "present": false`, and `"coordinate": "io.github.sztheory:crosswake-shell-core-android:0.2.4", "present": false`. [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence/175-fresh-core-release-run-0.2.4.json:1-135] [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence/175-fresh-core-registry-0.2.4.json:1-28]

The direct iOS fault is that `publish-ios-core` calls `ios_mirror.sh publish`, which reaches `mix run`, without a runtime setup step. The candidate rehearsal does install the repository's Elixir toolchain, so rehearsal success did not cover the ordinary job's environment. The direct Maven fault is the unconditional Phase 168 identity comparisons at the start of `android_publication.sh`, before its otherwise useful merge/head/tree/version checks and before Gradle. [VERIFIED: .github/workflows/release-please.yml:557-637] [VERIFIED: script/release_candidate/ios_mirror.sh:154-180] [VERIFIED: .github/workflows/ios-mirror-backfill.yml:135-169] [VERIFIED: script/release_candidate/android_publication.sh:14-61]

**Primary recommendation:** Keep `0.2.4` PARTIAL permanently. Repair the ordinary iOS runtime and separate ordinary Maven identity authority from the Phase 168 recovery pin; demonstrate each repair with seeded negative controls, non-publishing checks, and fresh safe rehearsals. Then plan a separately versioned successor and its own exact candidate-specific gate. This research grants no registry mutation, dispatch, merge, or publication. [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-CONTEXT.md:265-285]

## Historical Architectural Responsibility Map

| Capability | Primary tier | Secondary tier | Rationale |
|---|---|---|---|
| Ordinary iOS runtime | GitHub Actions job | Shell evaluator | The job supplies Mix before the shell calls the Elixir mirror policy. [VERIFIED: .github/workflows/release-please.yml:557-596] [VERIFIED: script/release_candidate/ios_mirror.sh:154-180] |
| Ordinary Maven authority | Approved release guard + publication script | Git/GitHub artifact identity | Guard outputs bind the candidate; the script checks the checked-out merge, second parent, tree, and Gradle version before upload. [VERIFIED: .github/workflows/release-please.yml:28-45] [VERIFIED: script/release_candidate/android_publication.sh:55-85] |
| Legacy recovery authority | Recovery workflow and script recovery mode | Public registry | Phase 168 pins remain exact and separate; no `0.2.4` recovery is authorized. [VERIFIED: script/check_release_workflow_integrity.exs:1626-1688] [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-CONTEXT.md:265-285] |
| Same-run proof and rollup | Ordinary release workflow | Registry/artifact observations | Exact-public depends on the publication and clean-room jobs; rollup consumes the same run's six results. [VERIFIED: .github/workflows/release-please.yml:753-805] [VERIFIED: lib/crosswake/release_candidate/workflow.ex:4-47] |
| Companion publication | Separate Hex release leg | Registry observation | Its later publish remains independent of core rollup. [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-CONTEXT.md:272-276] |

## Historical Project Constraints (from AGENTS.md)

- Preserve Phoenix-first route policy and explicit runtime ownership; keep the active quality workstream explicit. [VERIFIED: AGENTS.md:29-50] [VERIFIED: AGENTS.md:64-72]
- Keep denials fail-closed and proof based on observed run/artifact and registry evidence. [VERIFIED: AGENTS.md:44-48] [VERIFIED: AGENTS.md:73-82]
- Keep sensitive answers, media, transcripts, credentials, account identifiers, tokens, and stable device identifiers out of release logs and evidence. [VERIFIED: AGENTS.md:52-61]
- Android feature and device breadth is frozen; repairing the existing Maven publication contract is the bounded release work here. [VERIFIED: AGENTS.md:46-50] [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-CONTEXT.md:282-285]
- Use automated verification where possible; human action is reserved for unavoidable external approvals or irreversible trust actions. [VERIFIED: AGENTS.md:72-82]

## Historical Standard Stack

| Component | Exact current value | Use |
|---|---|---|
| Elixir/OTP runtime | `.tool-versions` quotes `erlang 27.3` and `elixir 1.19.5-otp-27`. | Install in ordinary iOS job before `ios_mirror.sh`; use the existing pinned setup action or existing composite cache action without introducing a new dependency. [VERIFIED: .tool-versions:1-3] [VERIFIED: .github/actions/setup-elixir-cache/action.yml:60-71] |
| Release graph | Existing `approved-release-guard`, `publish-ios-core`, `publish-android-core`, `exact-public-proof`, `linked-release-rollup`. | Keep the one ordinary push run as the publication/proof authority. [VERIFIED: .github/workflows/release-please.yml:27-45] [VERIFIED: .github/workflows/release-please.yml:557-637] [VERIFIED: .github/workflows/release-please.yml:753-805] |
| Structural proof | Existing `script/check_release_workflow_integrity.exs`, `ReleaseWorkflowFixtures`, and ExUnit. | Extend declared checks and mutation fixtures for the repaired iOS and Maven boundaries. [VERIFIED: script/check_release_workflow_integrity.exs:1549-1572] [VERIFIED: test/crosswake/proof/phase175_release_recovery_test.exs:1-19] |
| Safe rehearsals | Existing Hex candidate rehearsal, iOS candidate rehearsal, and isolated Maven fire drill. | Refresh all evidence against the exact successor candidate after code repairs; no ordinary publish before an explicit later gate. [VERIFIED: .github/workflows/hex-publish.yml:11-25] [VERIFIED: .github/workflows/ios-mirror-backfill.yml:110-184] [VERIFIED: .github/workflows/maven-publish-fire-drill.yml:1-31] |

**Installation:** None. Use repository-owned actions, scripts, and test harness. No new package is recommended. [VERIFIED: .github/actions/setup-elixir-cache/action.yml:60-71] [VERIFIED: test/crosswake/proof/phase175_release_recovery_test.exs:1-19]

## Historical Architecture Patterns

```text
fresh successor PR -> exact base/head/tree -> CI + Hex/iOS/Maven safe rehearsals
                                          -> canonical receipt attestation
                                          -> new candidate-specific Gate 2 (future)
                                          -> protected merge -> approved-release-guard
                                          -> ordinary Hex + iOS + Maven jobs
                                          -> clean-room jobs -> exact-public proof
                                          -> same-run six-child COMPLETE rollup
                                          -> separate second-companion gate and Hex evidence
```

The graph above is a future plan shape; this research phase ends before any dispatch or publication. The guard exposes `approved_head`, `approved_tree`, `merge_oid`, `candidate_receipt`, and `approved_version` to ordinary jobs; those outputs must remain the source of candidate identity. [VERIFIED: .github/workflows/release-please.yml:28-45]

### Pattern 1: Supply runtime in the ordinary iOS job

Add the already-used Elixir setup mechanism after checkout and before the publish script. The equivalent candidate rehearsal has `uses: ./.github/actions/setup-elixir-cache` with `mix-env: test`; that composite uses pinned `erlef/setup-beam` with `version-file: .tool-versions` and `version-type: strict`. The planner should choose the smallest consistent setup that makes Mix available and resolves locked dependencies before the script's `mix run --no-start`, while retaining the existing SSH/atomic push sequence. GitHub documents a job as a sequence of steps and a composite action as a series of steps used within one job step; the action's official README says `.tool-versions` is a supported `version-file` and requires strict matching. [VERIFIED: .github/workflows/ios-mirror-backfill.yml:135-169] [VERIFIED: .github/actions/setup-elixir-cache/action.yml:60-71] [VERIFIED: script/release_candidate/ios_mirror.sh:154-180] [CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax] [CITED: https://docs.github.com/en/actions/tutorials/create-actions/create-a-composite-action] [CITED: https://github.com/erlef/setup-beam/blob/main/README.md]

### Pattern 2: Separate ordinary Maven authority from historical recovery authority

The ordinary workflow passes all five fields from `approved-release-guard`, but `android_publication.sh` currently compares four identity values to `PHASE168_*` before examining its checked-out source. Move those historical equality checks into the `--recover` path or another recovery-only gate and preserve the source checkout, two-parent merge, second-parent head, tree equality, and Gradle version checks for ordinary `--execute`. Keep recovery's exact historical pin and existing scanner controls intact. A new ordinary-mode check must reject wrong merge, head, tree, receipt binding, version, and checked-out source, not merely check input shape. [VERIFIED: .github/workflows/release-please.yml:623-637] [VERIFIED: script/release_candidate/android_publication.sh:24-61] [VERIFIED: script/check_release_workflow_integrity.exs:1586-1623]

The script presently checks that `CANDIDATE_RECEIPT` has 64 hex characters and equals the fixed Phase 168 digest; without the pin it would have only a shape test. Therefore the planner must explicitly decide how the ordinary script verifies the receipt against guard-provided authority instead of silently deleting the equality. The guard already verifies one unexpired exact-head canonical artifact and computes the receipt digest, so the ordinary job can carry that trusted output with an independent binding check rather than invent a second receipt producer. [VERIFIED: script/release_candidate/android_publication.sh:45-60] [VERIFIED: .github/workflows/release-please.yml:95-120]

### Pattern 3: Preserve run-local proof semantics

`exact-public-proof` names `publish-hex`, `publish-ios-core`, `publish-android-core`, and both clean-room proofs in `needs`. `linked-release-rollup` consumes `HEX_STATE`, `IOS_STATE`, `ANDROID_STATE`, `IOS_PROOF_STATE`, `ANDROID_PROOF_STATE`, and `EXACT_PUBLIC_STATE` from the same workflow run. The code's literal roster is `@children ~w(hex ios_mirror android ios_public_proof android_public_proof exact_public)a`; it returns `"COMPLETE"` only when no child differs from `"success"`, and `"PARTIAL"` when a successful public coordinate survives a failed/skipped child. These values are quoted verbatim from the definition. [VERIFIED: .github/workflows/release-please.yml:753-805] [VERIFIED: .github/workflows/release-please.yml:838-857] [VERIFIED: lib/crosswake/release_candidate/workflow.ex:4-47]

## Historical Don't Hand-Roll

| Problem | Use | Reason |
|---|---|---|
| Elixir installation | Existing pinned setup action or repo composite | Same `.tool-versions` runtime already used in rehearsal and clean-room jobs. [VERIFIED: .github/actions/setup-elixir-cache/action.yml:60-71] [VERIFIED: .github/workflows/release-please.yml:647-658] |
| Canonical candidate receipt | Existing attestation and approved guard | Guard already checks exact artifact count, head/tree/base and digest. [VERIFIED: .github/workflows/release-please.yml:95-120] |
| Maven proof via public write | Existing isolated disposable fire drill | The rehearsal is scoped to a separate workflow and drops its disposable deployment. [VERIFIED: .github/workflows/maven-publish-fire-drill.yml:1-31] |
| Workflow parser/negative controls | Existing scanner and fixture harness | The Phase 175 test file already seeds isolation and receipt-authority failures. [VERIFIED: test/crosswake/proof/phase175_release_recovery_test.exs:1-19] [VERIFIED: test/crosswake/proof/phase175_release_recovery_test.exs:141-194] |

## Historical Common Pitfalls

1. **Treating rehearsal as ordinary-job proof.** The iOS rehearsal provisions Mix; the ordinary iOS job does not. Require a job-scoped structural check and a non-publishing execution of the same evaluator before trusting a later ordinary run. [VERIFIED: .github/workflows/ios-mirror-backfill.yml:135-169] [VERIFIED: .github/workflows/release-please.yml:557-602]
2. **Removing the Phase 168 pin without replacing ordinary authority.** That would leave Maven receipt as a 64-hex shape check and let a wrong candidate reach Gradle. Require negative cases for each identity component and preserve the recovery pin. [VERIFIED: script/release_candidate/android_publication.sh:45-61]
3. **Counting recovery as same-run proof.** Recovery cannot change run `36035737504`'s skipped exact-public job or its failed rollup. Keep `0.2.4` PARTIAL even after a successor completes. [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence/175-fresh-core-release-run-0.2.4.json:1-112] [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-CONTEXT.md:265-276]
4. **Reusing a gate response.** `"consumed": true` is recorded for the `0.2.4` Gate 2. A successor requires a fresh exact candidate and a new one-way authorization after all non-publishing evidence. [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence/175-fresh-core-release-run-0.2.4.json:8-17] [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-CONTEXT.md:278-285]
5. **Turning registry absence into a Portal claim.** The exact POM returned 404 and this script failed before Gradle; independent Maven Portal state remains unobserved by that response. Record only the narrower finding. [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-RECOVERY-DECISION-DRAFT-0.2.4.md:29-33] [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-RECOVERY-DECISION-DRAFT-0.2.4.md:67-69]
6. **Following stale planning prose.** REQUIREMENTS still literally names `0.2.2` for REL-13/14, the old 175-21 plan names `0.2.4`, and STATE's `Next` still asks for recovery diagnosis. Context D-39 to D-42 is the current decision and needs coherent requirement/roadmap/state/plan updates before execution. [VERIFIED: .planning/workstreams/quality-ratchet-release/REQUIREMENTS.md:67-72] [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-21-PLAN.md:40-46] [VERIFIED: .planning/workstreams/quality-ratchet-release/STATE.md:46-60] [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-CONTEXT.md:265-285]

## Historical Code Examples

The existing script quotes `MODE="observe"`, `MODE="publish"`, and `MODE="recovery"` for its modes; the command flags are `--execute` and `--recover`. [VERIFIED: script/release_candidate/android_publication.sh:13-34] The planner should implement the mode split with that shell shape. This is a design sketch, not copy-ready code; the authority binding and negative cases must be specified in the plan. [ASSUMED]

```text
validate version/ref/head/tree/receipt shapes
if mode == recovery: require exact historical Phase 168 identity
require checked-out HEAD == supplied merge ref
require two-parent merge and second parent == approved head
require merge tree == approved tree == head tree
require Gradle version == supplied version
if mode == observe: stop before Gradle/network mutation
if mode == publish: require guard-bound receipt, then invoke existing Gradle publication
```

The sketch deliberately stops before Gradle in `observe` mode, matching the existing script's current non-publishing branch. [VERIFIED: script/release_candidate/android_publication.sh:63-66]

## Historical Research Preserved

- The all-absent `0.2.2` guard failure remains a failed-preparation incident, separate from the later `0.2.3` and `0.2.4` partial releases. The candidate-attestation and exact remote ancestry conclusions from the 2026-09-21 research remain useful; its former recommendation to replace 175-08 through 175-10 was carried out as historical successor planning and is no longer the current plan boundary. [VERIFIED: .planning/workstreams/quality-ratchet-release/STATE.md:46-50] [VERIFIED: .planning/workstreams/quality-ratchet-release/ROADMAP.md:487-505]
- The Maven fire drill is now in a dedicated manual workflow. Its candidate identity and non-mutation proof have existing seeded scanner tests. This satisfies the earlier D-36 research need; the current defect is specifically ordinary publication authority. [VERIFIED: .github/workflows/maven-publish-fire-drill.yml:1-56] [VERIFIED: test/crosswake/proof/phase175_release_recovery_test.exs:21-80]
- The receipt guard remains fail-closed and is already tested for missing artifact and stale head/tree/base. Do not relax it while repairing Maven's distinct script gate. [VERIFIED: .github/workflows/release-please.yml:95-120] [VERIFIED: test/crosswake/proof/phase175_release_recovery_test.exs:141-166]
- Gate 1's REL-10 runbook ancestry breach remains historical and cannot be recast as compliant. [VERIFIED: .planning/workstreams/quality-ratchet-release/REQUIREMENTS.md:67-67]

## Historical Plan-Facing Work Sequence

1. Update active requirement, roadmap, state, and 175-21 planning language to name the fresh successor symbolically, while preserving the `0.2.2` failed preparation, `0.2.3` PARTIAL, `0.2.4` PARTIAL, and REL-10 breach records. Replan 175-21; its precondition and target version currently cannot pass. [VERIFIED: .planning/workstreams/quality-ratchet-release/ROADMAP.md:422-505] [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-21-PLAN.md:40-124]
2. Repair `publish-ios-core` runtime setup before the mirror script and add a scanner check that fails on missing/misordered setup. Add a seeded negative test that proves the check fails if setup is removed. [VERIFIED: .github/workflows/release-please.yml:557-602] [VERIFIED: .github/workflows/ios-mirror-backfill.yml:135-169]
3. Split Maven ordinary `--execute` authority from legacy `--recover` pin. Preserve exact merge/head/tree/version/source and receipt binding; add table-driven accepted current-candidate and rejected mismatch cases, plus scanner mutation controls. [VERIFIED: script/release_candidate/android_publication.sh:24-85] [VERIFIED: script/check_release_workflow_integrity.exs:1586-1623]
4. Run local non-publishing guards and safe candidate-mode rehearsals; collect exact version, base/head/tree, workflow identity, receipt digest, run IDs, false external-state-change flags, and direct target absence for the fresh candidate. Do not dispatch under this research authorization. [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-CONTEXT.md:237-256] [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-CONTEXT.md:282-285]
5. Only after that evidence exists, present a new Gate 2 with candidate-specific one-way costs. A later authorized ordinary run must itself publish all three core coordinates, execute and pass exact-public proof, and produce its own six-success-child `"COMPLETE"` rollup. The second companion remains a separate later gate. [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-CONTEXT.md:272-285] [VERIFIED: lib/crosswake/release_candidate/workflow.ex:4-47]

## Historical Assumptions Log

| # | Claim | Risk if wrong |
|---|---|---|
| A1 | The precise ordinary Maven receipt binding implementation can use the trusted guard output without a second receipt download. [ASSUMED] | A plan could permit a shaped but wrong digest; resolve in code design with negative tests. |
| A2 | The sketch's `observe` mode can be adapted for the positive successor case without external write. [ASSUMED] | If not, use a fixture source and structural check before the future Gate 2. |

## Historical Open Questions (RESOLVED)

1. **What exact successor version and candidate OIDs will be used? RESOLVED:** Do not choose them in planning. Capture the live successor version and base/head/tree/receipt during Plan 175-28 and require all observations to bind to that identity; never guess a literal. [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-CONTEXT.md:272-285] [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-28-PLAN.md]
2. **How will the ordinary Maven script independently bind the passed digest to the approved guard? RESOLVED:** Plan 175-27 requires ordinary mode to compare the invocation digest with the trusted guard output bound to the candidate receipt and exact identity, while preserving the legacy historical pin only for recovery mode. Seeded mismatch controls must fail. The precise implementation is a code task, not an unresolved planning choice. [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-27-PLAN.md] [VERIFIED: script/release_candidate/android_publication.sh:45-60] [VERIFIED: .github/workflows/release-please.yml:95-120]
3. **What is independent Central Portal state? RESOLVED:** No claim about Central Portal deployment state is needed or permitted for 0.2.4; its disposition is permanently PARTIAL with no recovery. For a fresh successor, use the existing safe Maven rehearsal VALIDATED/DROP result and exact candidate binding; do not infer portal state from a public POM 404. [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-CONTEXT.md:265-270] [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-28-PLAN.md]

## Historical Environment Availability

| Dependency | Required by | Available here | Version / boundary |
|---|---|---|---|
| Git | identity and ancestry inspection | yes | `2.41.0` from local command; remote exact OIDs still require future fetch. [VERIFIED: local `git --version`] |
| Elixir/Mix | scanner and shell evaluator | yes locally | `Mix 1.19.5`, OTP 27 locally; missing in the recorded ordinary iOS runner. [VERIFIED: local `mix --version`] [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-RECOVERY-DECISION-DRAFT-0.2.4.md:24-27] |
| GitHub CLI | later read-only run/artifact inspection | yes | `2.101.0` locally; no dispatch performed in research. [VERIFIED: local `gh --version`] |
| Registry/Portal credentials | future gated publication/rehearsal | unprobed | Do not infer availability from local environment. [ASSUMED] |

## Historical Validation Architecture

`workflow.nyquist_validation` is `true` in the project config; the workstream config does not override that key. [VERIFIED: .planning/config.json:8-12] [VERIFIED: .planning/workstreams/quality-ratchet-release/config.json:1-5]

| Req | Verification design | Current coverage | Gap |
|---|---|---|---|
| REL-10, REL-16, DOC-04, DOC-06 | Preserve existing ancestry and documentation checks; inspect historical evidence. | Existing docs and scanner. [VERIFIED: .planning/workstreams/quality-ratchet-release/REQUIREMENTS.md:67-79] | Do not retroactively mark REL-10 compliant. |
| REL-11 | Three fresh candidate-bound safe rehearsal artifacts; Maven reaches validated/drop. | Existing rehearsal workflows. [VERIFIED: .github/workflows/hex-publish.yml:97-109] [VERIFIED: .github/workflows/ios-mirror-backfill.yml:110-184] [VERIFIED: .github/workflows/maven-publish-fire-drill.yml:1-31] | Re-run only after code repair and separate permission. |
| REL-13 | Structural scanner and table-driven shell identity tests, including seed-red missing iOS setup and every Maven mismatch; later direct registry evidence. | Existing release recovery test harness. [VERIFIED: test/crosswake/proof/phase175_release_recovery_test.exs:1-19] | New ordinary iOS/Maven red-green controls. |
| REL-14, REL-15 | Exact ordinary run ID, successful proof artifact, and validated same-run six-child COMPLETE artifact; later independent companion Hex check. | Existing graph and rollup module. [VERIFIED: .github/workflows/release-please.yml:753-865] [VERIFIED: lib/crosswake/release_candidate/workflow.ex:4-47] | Fresh successor evidence only after a future authorized release. |

**Quick local commands for planned implementation:** `elixir script/check_release_workflow_integrity.exs` and `MIX_ENV=test mix test test/crosswake/proof/phase175_release_recovery_test.exs test/crosswake/release_candidate/workflow_test.exs`. The first scanner and test paths are existing source files; these commands are plan suggestions and were not run in this research pass. [VERIFIED: script/check_release_workflow_integrity.exs:1-20] [VERIFIED: test/crosswake/proof/phase175_release_recovery_test.exs:1-19] [VERIFIED: test/crosswake/release_candidate/workflow_test.exs:1-5]

**Sampling:** Run the focused commands after each repair; use existing full CI after merge; before a future Gate 2, require fresh safe rehearsal artifacts, receipt, exact ancestry, direct registry absence, and all seeded negative controls. Do not use a human UAT handoff for automatable checks. [VERIFIED: AGENTS.md:72-82] [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-CONTEXT.md:278-285]

## Historical Security Domain

| ASVS category | Applies | Phase control |
|---|---|---|
| V2 Authentication | yes | Release credentials stay in their scoped jobs and are never written into evidence. [VERIFIED: .github/workflows/release-please.yml:572-585] [VERIFIED: .github/workflows/release-please.yml:623-629] |
| V3 Session Management | no direct application | CI jobs have ephemeral execution; no application session contract changes are in scope. [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-CONTEXT.md:265-285] |
| V4 Access Control | yes | Guarded outputs and the distinct one-way Gate 2 govern publication; manual rehearsal has read-only repository permission. [VERIFIED: .github/workflows/release-please.yml:28-45] [VERIFIED: .github/workflows/maven-publish-fire-drill.yml:26-41] |
| V5 Input Validation | yes | Validate exact version, Git object relationships, checkout, receipt, and target coordinate before Gradle or mirror push. [VERIFIED: script/release_candidate/android_publication.sh:45-85] [VERIFIED: script/release_candidate/ios_mirror.sh:59-79] |
| V6 Cryptography | yes | Reuse SHA-256 receipt and existing signing path; add no custom cryptography. [VERIFIED: .github/workflows/release-please.yml:114-120] [VERIFIED: .github/workflows/maven-publish-fire-drill.yml:107-129] |

| Threat | STRIDE | Mitigation |
|---|---|---|
| Missing runtime creates partial one-way publication | Availability | Install pinned runtime in ordinary iOS job; prove missing-setup mutation fails. [VERIFIED: .github/workflows/release-please.yml:557-602] |
| Wrong Maven candidate reaches Gradle | Tampering | Separate recovery pin, bind ordinary identity to guard output, test each mismatch. [VERIFIED: script/release_candidate/android_publication.sh:45-85] |
| Recovery is misreported as successful same-run proof | Repudiation | Preserve the recorded PARTIAL run and require successor artifacts from one run ID. [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-CONTEXT.md:265-276] |
| Credentials or private payloads enter evidence | Information disclosure | Store normalized identifiers and verdicts only. [VERIFIED: AGENTS.md:52-61] |

## Historical Sources and Confidence

- **Official documentation (MEDIUM):** [GitHub workflow syntax](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax), [composite actions](https://docs.github.com/en/actions/tutorials/create-actions/create-a-composite-action), and [erlef/setup-beam README](https://github.com/erlef/setup-beam/blob/main/README.md) support the iOS setup ordering and version-file recommendation. The research-plan seam selected Context7; no Context7 tool or CLI was available, so official-source web search supplied these references.
- **MEDIUM overall, repository-local authority:** Current workflow, shell scripts, rollup source, fixture tests, context, and normalized run/registry evidence were opened directly for this research. Their line citations above support the observed code paths and historical run facts; no new live remote observation was made.
- **MEDIUM, design recommendation:** The exact ordinary Maven receipt binding and the smallest iOS setup insertion need implementation design and red-green proof. The proposed shape is an inference from the current guard and script contracts, not an already implemented guarantee. [ASSUMED]
- **LOW, external state:** No new remote workflow, registry, or Portal query was made. The research relies on the dated normalized 2026-09-24 evidence snapshot and does not claim state after its observation time. [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence/175-fresh-core-registry-0.2.4.json:1-27]

**Research date:** 2026-09-24. **Refresh before any future one-way gate:** candidate identity and public registry state are time-sensitive. [ASSUMED]

## REL-17 Evidence-Gate Research Addendum (2026-09-26)

This addendum supersedes the pre-REL-17 planning sequence where it conflicts with the current
release hold. It does not rewrite the dated findings or outcomes above. Three independent advisor
passes compared evidence shape, freshness/authorization, and operator experience against the six
conditions in `175-KNOWN-RELEASE-BLOCKER.md`; their choices are reconciled here for planning.

### Recommended contract

Use one immutable, per-operation evidence envelope, shared by linked release, recovery, and
companion publication. Bind it to the canonical candidate receipt digest, exact candidate identity,
operation, leg-specific Hex run ID, and evidence for all six conditions. Store the raw registry
response next to a checked nonempty parse and the matching response-table row. Preserve evidence
digests and exact source identities, not merely filenames or a passing workflow conclusion.

The release crosses two evidence times. Before merge, capture and revalidate the exact live base,
approved head, merge readiness, CI result, required-check policy, rehearsal identity, response row,
registry response, and runbook ancestry on the base/head. The authorization then applies only to
that exact reviewed merge. After merge, construct the final operation envelope with the actual
merge OID; before any publisher runs, verify the merge lineage, normal protected path/no admin
bypass, runbook ancestry on base/head/merge, and the bound pre-merge evidence. Never invent a
pre-merge merge OID or let an approval-time snapshot stand in for the final merge check.

Re-fetch mutable GitHub and registry facts at existing authorization and immediately before each
side effect. A TTL establishes age but not freshness. Exhaust REST pagination, preserve response
bytes before parsing, and make API errors, partial pages, missing fields, empty parses, stale run or
candidate identity, changed policy, and bypass evidence fail closed. Use direct status capture or
`set -o pipefail` so a successful downstream formatter cannot hide a failed API request. The guard
should return a concise `BLOCKED` reason naming the unmet condition and safe next step; do not print
raw API bodies or sensitive candidate material.

### Elixir, workflow, and operator shape

Keep the domain validator pure Elixir over explicit evidence values, with thin adapters around
GitHub, registry, filesystem, and workflow inputs. Reuse Mix tasks for operator status, the existing
workflow-integrity scanner for structural enforcement, and ExUnit positive and per-condition
mutation cases. Require wiring proofs for every side-effect path, not only a unit-tested validator.
Do not add Ecto persistence, Plug endpoints, or a Phoenix dashboard: current users are release
maintainers deciding whether one exact candidate/leg can proceed, and evidence is already retained
as workflow artifacts and phase records. The Mix/CI surface should report the current status,
missing condition, and next permitted operation in text. `READY FOR APPROVAL` is not permission;
preserve historical `PARTIAL` and success-only `COMPLETE` semantics. Color can reinforce status but
must not be its only signal.

This structure adds live calls and a small envelope schema but avoids check drift among YAML and
shell paths. It matches Crosswake's low-frequency release workload, fail-closed posture, and
existing exact-receipt design. No live API calls or publication were made by this research addendum.

### Cross-ecosystem lessons

- SLSA provenance and GitHub artifact attestations bind claims to a subject digest, which is a
  useful defense against evidence copied from a different candidate
  ([SLSA](https://slsa.dev/spec/v1.2/provenance), [GitHub attestations](https://docs.github.com/en/actions/concepts/security/artifact-attestations)).
- GitHub rulesets and required-check state are mutable policy, so read current policy and bind its
  result to the operation; REST pagination must be exhausted
  ([rulesets](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets), [rules API](https://docs.github.com/en/rest/repos/rules), [pagination](https://docs.github.com/en/rest/using-the-rest-api/using-pagination-in-the-rest-api)).
- Cargo's explicit dry-run boundary is a good preflight affordance, but a rehearsal cannot authorize
  a later mutable remote action ([Cargo publishing](https://doc.rust-lang.org/cargo/reference/publishing.html)).
- Go module versioning and Kubernetes release roles illustrate durable artifact identity and
  explicit release ownership ([Go Modules Reference](https://go.dev/ref/mod), [Kubernetes Release Team](https://github.com/kubernetes/sig-release/blob/master/release-team/README.md)).
- npm's unpublish policy is ecosystem-specific; do not copy its deletion model into recovery claims
  for Hex retirement or Maven Central permanence ([npm policy](https://docs.npmjs.com/policies/unpublish/)).
- `Mix.Task` is the idiomatic operator seam here; the absence of application-level durable state
  gives Ecto and Phoenix no role in this phase ([Mix.Task](https://hexdocs.pm/mix/Mix.Task.html)).

### REL-17 verification design

| Requirement | Required proof | Negative controls |
|---|---|---|
| REL-17 identity binding | One exact candidate/operation/leg envelope references the canonical receipt digest and correct leg run. | Alter or omit each identity/digest/run field; supply another leg's run. |
| REL-17 freshness | Live pre-authorization base/head/readiness, CI, and policy agree with the exact candidate; final merge OID is checked after merge before publisher entry. | Stale OID, changed policy, non-success CI, empty/truncated pages, API failure, missing required fields. |
| REL-17 registry evidence | Raw response is retained; parse is nonempty; matching Hex response-table row names the bound run. | Empty body, invalid JSON, empty collection, wrong row, wrong run, omitted raw response. |
| REL-17 privilege and ancestry | Exact merge used normal protected path without admin bypass; runbook commit is ancestor of base, head, and actual merge. | Admin-bypass marker, unprotected path, missing object, wrong parent, non-ancestor mutation. |
| REL-17 cross-path enforcement | Linked release, recovery, and companion publishers consume the same fail-closed contract immediately before side effects. | Remove or bypass each call-site guard independently; assert no path reaches the mutation command. |
| Operator truth | Read-only status says BLOCKED with concise missing-condition guidance; preserves PARTIAL and COMPLETE. | READY-for-approval alone cannot authorize; blocked path emits no retry/recovery permission and no raw payload. |

Keep these as local/mocked or seeded workflow tests and structural checks. Use live reads only when
planning an actual future authorization; no current publication, recovery, or companion action is
permitted. This augments the existing validation architecture without changing its rule that
machine-verifiable claims have no human-UAT handoff.

**Addendum research sources (official/primary):** [SLSA Provenance v1.2](https://slsa.dev/spec/v1.2/provenance), [GitHub artifact attestations](https://docs.github.com/en/actions/concepts/security/artifact-attestations), [GitHub rulesets](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets), [GitHub REST rules](https://docs.github.com/en/rest/repos/rules), [GitHub pagination](https://docs.github.com/en/rest/using-the-rest-api/using-pagination-in-the-rest-api), [Cargo publishing](https://doc.rust-lang.org/cargo/reference/publishing.html), [Go Modules Reference](https://go.dev/ref/mod), [Kubernetes Release Team](https://github.com/kubernetes/sig-release/blob/master/release-team/README.md), [npm unpublish policy](https://docs.npmjs.com/policies/unpublish/), [Mix.Task](https://hexdocs.pm/mix/Mix.Task.html).

**Freshness note:** The new addendum records stable design/architecture guidance. Candidate OIDs,
current policy, run IDs, and registry state remain time-sensitive and must be fetched again at the
future gate.
