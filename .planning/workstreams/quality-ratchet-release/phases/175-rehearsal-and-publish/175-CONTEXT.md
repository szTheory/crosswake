# Phase 175: Rehearsal and Publish - Context

**Gathered:** 2026-09-18
**Status:** Ready for planning

<domain>
## Phase Boundary

Execute the milestone's only irreversible registry mutations. Commit the incident-response
documentation, rehearse all three publish legs against the real `0.2.2` candidate, then publish in
ascending blast-radius order — held companion, core `crosswake 0.2.2`, second held companion — with
independent registry evidence confirming each leg.

Scope is fixed by ROADMAP.md Phase 175: REL-10 through REL-16, DOC-04, DOC-06. The phase opens with
a broken-windows triage wave (Wave 0) that gates every publish task, per STATE.md's recorded
planning guidance of 2026-09-18.

**Not in scope:** building new rehearsal, retirement, or partial-failure tooling. Prior research
established that working dispatch-only rehearsal mechanisms already exist for all three registries
and that this phase dispatches and records them rather than designing replacements.

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

- **D-33:** Both companion PRs report `mergeStateStatus: BEHIND`. Each publish wave must re-confirm
  the PR head SHA immediately before dispatching its rehearsal AND again immediately before merging,
  so the rehearsed ref is the ref that actually merges.

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
- `.planning/workstreams/quality-ratchet-release/ROADMAP.md` — Phase 175 section: goal, dependency
  bar, the one-way-door note, and all 8 success criteria. Lines ~107-108 record that unaudited
  vacuous checks must be resolved before the publish phase opens.
- `.planning/workstreams/quality-ratchet-release/REQUIREMENTS.md` §67-79 — exact wording of REL-10
  through REL-16, DOC-04, DOC-06.
- `.planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-RESEARCH.md` —
  the full research pass. Recommended Wave Structure, Anti-Patterns to Avoid, all 6 Common Pitfalls,
  and the runnable verification commands under Code Examples.
- `.planning/workstreams/quality-ratchet-release/STATE.md` — the open-release-PR triage table and the
  2026-09-18 planning guidance placing the broken-windows triage inside Phase 175 as Wave 0.

### Release pipeline
- `.github/workflows/release-please.yml` — the release graph. `exact-public-proof` dispatch condition
  (`package: crosswake` only); the `android-publish-fire-drill` job performing a real signed Central
  Portal upload through `VALIDATED` then `DROP`.
- `.github/workflows/hex-publish.yml` — the `candidate-rehearsal` operation producing
  `candidate-rehearsal-hex`.
- `.github/workflows/ios-mirror-backfill.yml` — the `candidate-rehearsal` operation performing
  `git subtree split` with no push, producing `candidate-rehearsal-ios`.
- `.github/workflows/exact-public-proof.yml` — the proof lane REL-14 requires to have executed.
- `lib/crosswake/release_candidate/workflow.ex` — `linked-release-rollup`'s six children and the
  `COMPLETE` state definition.
- `script/release_candidate/hex_artifacts.sh` — the `hex.publish --dry-run` and `hex.build` calls.
- `docs/release-ledger/RELEASE-LEDGER.jsonl` — recorded release evidence schema.

### Documentation targets
- `docs/COMPANION-PUBLISH-RUNBOOK.md` — 279 lines. Carries DOC-04's deletion target and DOC-06's
  `git subtree split` gap. Its existing structure is the main constraint on D-13/D-14.
- `docs/RELEASE-INCIDENT-RESPONSE.md` — to be created by this phase (REL-10 + REL-16).

### Wave 0
- `scripts/ci_monitor.cjs` — `checkActions()` at ~lines 269-302, the hardcoded three-path default
  that is the subject of D-21 through D-28.
- `.github/dependabot.yml` — the existing `github-actions` weekly config that makes pinning
  maintainable.

### Project standards
- `prompts/crosswake-brand-book.md` — documentation voice. Supersedes older voice references.
- `prompts/crosswake-elixir-oss-dna.md` — OSS citizenship and release standards.
- `prompts/crosswake-gsd-project-brief.md` — project vision and engineering standards.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- Three working dispatch-only rehearsal mechanisms already exist and are NOT dormant scaffolding:
  `hex-publish.yml`'s `candidate-rehearsal`, `ios-mirror-backfill.yml`'s `candidate-rehearsal`, and
  `release-please.yml`'s `android-publish-fire-drill`. `candidate-rehearsal-hex` and
  `candidate-rehearsal-ios` are the exact artifacts `attest-candidate-receipt` already consumed for
  the canonical `0.2.1` candidate receipt.
- `.github/dependabot.yml`'s `github-actions` ecosystem already maintains pinned action SHAs.
- `script/check_release_workflow_integrity.exs` establishes the repo's fail-closed CI-hygiene
  pattern — the natural precedent for D-19's version-literal check.

### Established Patterns
- Maven Central's `VALIDATED` → `DROP` path makes a full-fidelity Maven rehearsal possible without
  reaching the `PUBLISHED` immutability boundary. The fire drill uploads a real signed bundle.
- The four publishing workflows are already fully SHA-pinned. Wave 0 does not change the safety of
  the publish path; it changes whether the pin audit's green result means anything.
- Companion Hex publishes bypass `approved-release-guard` entirely (`needs: release-please` only).

### Integration Points
- Checkpoint prompts cite `docs/RELEASE-INCIDENT-RESPONSE.md` anchors, so the document must exist
  and its headings must be stable before the checkpoints are authored.
- The REL-10 runbook's commit SHA is displayed at gate 2 and recorded for SC1.

</code_context>

<specifics>
## Specific Ideas

- The three checkpoint prompts should read as visibly different documents, not three renderings of a
  template — leg 1 of 3 states Hex retirability, leg 2 states three-registry exposure with Maven
  permanence called out, leg 3 states the confirmed-live status of `0.2.2` across all three
  registries with timestamps.
- The Irreversibility column's register: short declarative sentences, bold on the fact that must not
  be missed, and no hedging words ("may", "should consider") ever.
- Borrow PEP 592 / crates.io yank phrasing as the plain-English gloss for Hex retirement — "not
  selected by default resolution, but existing lockfiles still work."

</specifics>

<deferred>
## Deferred Ideas

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

---

*Phase: 175-rehearsal-and-publish*
*Context gathered: 2026-09-18*
