# Phase 175: Rehearsal and Publish - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-18; discussions appended through 2026-10-05
**Phase:** 175-rehearsal-and-publish
**Areas discussed:** Fire-drill companion pick, Human checkpoints on the one-way doors, Runbook + failure-table shape, Wave 0 triage depth, failed release-guard recovery, REL-17 evidence/freshness/operator path, post-175-42 current-state refresh, Plan 175-52 stdout classification, stderr interpretation, receipt/privacy and maintainer DX, Plan 175-54 source readiness and diagnosis, Plan 175-55 unknown attempt disposition and next-step boundary, missing v0.2.6 mirror tag and fresh-plan boundary, Plan78 scanner input and follow-up, REL-13/14/15 phase-goal coverage path

**Mode:** advisor (USER-PROFILE.md present), calibration tier `minimal_decisive`
(`vendor_philosophy: opinionated`). `NON_TECHNICAL_OWNER = false` — `technical_background: true`
overrides inferred signals, so technical framing was retained. Four `gsd-advisor-researcher`
subagents ran in parallel, each instructed to stay coherent with the other three and flag coupling
rather than optimize its own area.

---

## Fire-drill companion pick

| Option | Description | Selected |
|--------|-------------|----------|
| #147 `crosswake_rulestead` | 75 all-time Hex downloads vs chimeway's 106; no reverse dependents found for either. Record the justification as a planning decision since download count is an imperfect proxy and the GitHub dependents graph was never queried. | ✓ |
| #115 `crosswake_chimeway` | Larger code surface (7 modules/1291 lines vs 1/202) would exercise more package code — but the drill tests the publish pipeline, not package code, and both companion jobs are structurally identical. Higher download count. | |

**User's choice:** #147 `crosswake_rulestead`

**Notes:** The research pass's most useful contribution was separating two properties the ROADMAP's
phrasing conflates — blast radius (impact if wrong) versus representativeness (how much of the lane
the drill exercises). Since both companion publish jobs are structurally identical, representativeness
does not differentiate them and the decision rests on blast radius alone.

One strand of the researcher's argument was discounted before presenting: it cited "already sequenced
this way in STATE.md and 175-RESEARCH.md" as supporting evidence, which is circular — those documents
cite the same download count. The pick rests on download count alone, which is thin but is the only
signal actually available.

The most consequential finding was incidental to the pick itself: companion publish jobs are Hex-only
and never touch the iOS mirror or Maven, making Waves 2 and 4 materially lower-stakes than Wave 3.
This fed directly into the checkpoint decision.

---

## Human checkpoints on the one-way doors

| Option | Description | Selected |
|--------|-------------|----------|
| Three gates, weighted by leg | `checkpoint:decision` before each irreversible leg, each requiring a different typed-back value from that leg's evidence. Gates 1 and 3 light (single Hex publish, retire-forward recoverable); gate 2 heavy (three registries, Maven permanent at PUBLISHED). Phase cannot run unattended. | ✓ |
| One gate before the whole sequence | Single go/no-go after Wave 1's rehearsal evidence is collected, then legs 2-4 run through. Fewer interruptions, but authorizes the Maven upload on evidence already stale by the time that leg fires, and gives no chance to react to what the core 0.2.2 proof lane showed. | |

**User's choice:** Three gates, weighted by leg

**Notes:** The researcher's recommendation was accepted but its stated basis was corrected before
presenting. It argued leg 3 depends on leg 2 via the prior milestone's core-first lesson; that lesson
does not apply to 0.2.2, because both companions declare `{:crosswake, "~> 0.2"}` and `0.2.1` is
already live, so the version floor is satisfied independently of `0.2.2`. The conclusion survives on
different grounds: leg 3's safety depends on leg 2's proof lane having actually executed, not on
leg 2's version existing.

The two reports were reconciled rather than one overriding the other. The companion-pick research
established that Waves 2 and 4 are single-registry, which argues against three identically-weighted
gates; the checkpoint research had already proposed a visibly heavier gate 2. Weighting the gates
asymmetrically satisfies both.

The typed-back-value design is the specific mitigation for approval fatigue — three near-identical
prompts train an operator to click through, so each gate demands a different named field from a
different artifact.

---

## Runbook + failure-table shape

| Option | Description | Selected |
|--------|-------------|----------|
| One new incident doc + runbook fixes | New `docs/RELEASE-INCIDENT-RESPONSE.md` holds REL-10 and REL-16, table-first, irreversibility summary above the fold. DOC-04's deletion and DOC-06's `git subtree split` docs land in `COMPANION-PUBLISH-RUNBOOK.md` as a separate commit. Add the version-literal CI grep. | ✓ |
| Extend the existing runbook in place | Add Retire/Backfill and Partial-Failure sections to `COMPANION-PUBLISH-RUNBOOK.md`, no new file. Single file, no cross-link to sync — but the mid-incident reader scrolls past 279 lines of pre-flight prose to reach the table. | |

**User's choice:** One new incident doc + runbook fixes

**Notes:** REL-10 and REL-16 are different jobs (post-hoc correction vs mid-flight triage) but share
one reader at one moment, so they belong in the same new file — splitting them further would force a
cross-file jump mid-incident. They do not belong inside the existing runbook, which is pre-flight
prose written for someone preparing a release rather than someone already mid-failure.

The highest-value output was the drift mechanism rather than the file layout: a CI grep failing on
bare version literals outside code fences, making DOC-04's defect class structurally hard to repeat
rather than something to remember. Two heavier mechanisms — generating version-specific content from
`RELEASE-LEDGER.jsonl`, and a docs test asserting claims against live registry state — were
deliberately deferred as disproportionate to this phase's docs scope.

Also surfaced: the iOS mirror's left-pad analogue is currently documented nowhere — re-pointing a
mirror tag does not un-resolve consumers who already fetched the old commit through SwiftPM's
resolved-package cache.

---

## Wave 0 triage depth

| Option | Description | Selected |
|--------|-------------|----------|
| Fix discovery + gate + pin all 31 | Lands as its own PR, fully green, merged before any Wave 1 task starts, keeping the 31 pin edits outside the publish waves' blast radius. Closes the `required-checks-audit.yml` secret path. Dependabot already maintains pinned SHAs. | ✓ |
| Fix discovery + cardinality gate only | Smallest footprint before the one-way door; defer pinning to a fast-follow after 0.2.2 ships. But leaves the newly-honest check reporting `mutable_refs=31` as Phase 175 opens — so either Wave 1 blocks anyway or a red check is waived during the milestone's only irreversible operations. | |

**User's choice:** Fix discovery + gate + pin all 31

**Notes:** The researcher re-derived the figures rather than trusting STATE.md, and they held exactly:
default invocation scans 3 files reporting `actions=114 mutable_refs=0`; full scope is 27 files
reporting `actions=252 mutable_refs=31` across 10 workflows. The 4 publishing workflows are genuinely
clean.

Two findings moved this off "hygiene nit". First, `required-checks-audit.yml:67` reads
`secrets.BRANCH_PROTECTION_READ_TOKEN` in a job with a mutable third-party `uses:` — a live, narrow
credential-exfiltration path rather than a hypothetical one. Second, Dependabot is already configured
for `github-actions` weekly, removing the standard objection that pinning trades a mutable-ref risk
for an unpatched-action one.

The researcher also checked the PR #173 guard directly and found it would not have caught this:
#173's family is "the assertion is a no-op on the value it looked at", whereas this is "the assertion
is correct but the scan was truncated" — same pathology, structurally different failure mode. That
argues for a separate narrow check rather than extending `check_absence_is_not_success.exs`.

Its proposed exit criterion includes exercising the new cardinality gate against a deliberate
regression before trusting it, which matches the project's own recorded rule about measuring a
check's findings before making it blocking.

---

## Claude's Discretion

- Final file naming and internal section ordering within `docs/RELEASE-INCIDENT-RESPONSE.md`, beyond
  the structural constraints recorded in CONTEXT.md.
- Exact wording of the three checkpoint prompts, subject to the evidence-field and
  recovery-cost constraints.
- Implementation shape of the `assertFullScope` helper and the version-literal CI check.
- Wave decomposition and task granularity within the recorded structure.

## Deferred Ideas

- Generating version-specific doc content from `RELEASE-LEDGER.jsonl`.
- A docs freshness test asserting claims against live registry state.
- Auditing whether the SHAs pinned in Wave 0 are themselves correct, latest, or uncompromised.
- Extending the scope-cardinality gate beyond `scripts/ci_monitor.cjs`.
- Querying the GitHub dependents graph to retire Assumption A1 on companion blast radius.

---

## Failed release-guard recovery

| Option | Description | Selected |
|--------|-------------|----------|
| Reconstruct `0.2.2` authority | Attempt to attest the already-merged candidate under its historic base. | |
| Fresh versioned candidate | Establish a new exact candidate/receipt boundary before a later merge. | ✓ |

**User's choice:** Autonomous recommendation accepted: proceed until an irreversible action or other
genuine decision is required.

**Notes:** The failed `release: approved-candidate merge guard` occurred before all registry jobs.
The canonical attestation requires `origin/main` to equal the candidate base, which is impossible for
the already-merged candidate. A fresh candidate preserves the fail-closed authority model.

---

## Non-mutating rehearsal boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Reuse the current fire-drill shape | Continue a run that can advance Release Please housekeeping and invalidate evidence. | |
| Decouple fire drill and housekeeping | Make the fire drill preserve the exact candidate PR identity and prove it. | ✓ |

**User's choice:** Autonomous recommendation accepted.

**Notes:** The correction must block any rehearsal shape that advances the release candidate and must
prove that missing-receipt and stale-identity cases fail closed.

---

## 0.2.4 recovery outcome (2026-09-24)

| Option | Description | Selected |
|--------|-------------|----------|
| Keep 0.2.4 PARTIAL; use a fresh candidate for complete proof | Leave Hex as the only published coordinate and preserve the skipped same-run proof as a historical gap. | ✓ |
| Recover iOS and Maven for 0.2.4, then use a fresh candidate for proof | Add separate registry writes, while still requiring a fresh candidate for the phase proof. | |
| Recover 0.2.4 and revise the phase proof requirement | Treat recovery as sufficient to revise the current phase's proof boundary. | |

**User's choice:** Keep 0.2.4 permanently recorded PARTIAL; use a fresh candidate for complete proof. Do not reopen the missing coordinates after a successor ships.
**Notes:** The 0.2.3 partial and historical REL-10 breach remain separate records.

---

## Same-run proof and phase exit (2026-09-24)

| Option | Description | Selected |
|--------|-------------|----------|
| Require one fully successful ordinary run for a fresh candidate | That run publishes all three core coordinates and executes/passes exact-public proof. | ✓ |
| Allow recovery jobs to contribute to completion, but keep exact-public proof in the ordinary run | Combine core publication evidence across an ordinary run and separate recovery runs. | |
| Revise the phase exit requirement to accept a published partial | Change the phase exit to accept less than the current same-run proof contract. | |

**User's choice:** Require one fully successful ordinary run for a fresh candidate.
**Notes:** Carry forward the six-child COMPLETE linked-rollup requirement from the same run. The companion publish remains a separate fact and gate.

---

## Recovery authorization boundary (2026-09-24)

No new authorization was requested or granted. The user chose not to recover 0.2.4. Existing Phase 175 decisions require distinct, candidate-specific gates and prohibit reusing consumed authorization; the 0.2.4 Gate 2 authorization remains consumed.

---

## Workflow handling (2026-09-24)

- Existing context: **Update it**.
- Existing plan artifacts: **Continue and replan after** context capture.
- Gray areas: **All three** selected; the authorization boundary was pre-answered by D-07, D-08, D-38 and the decision to leave 0.2.4 permanently partial.
- Final review: **Ready for context**.

---

## REL-17 evidence, freshness, and operator path (2026-09-26)

This follow-on discussion scoped the new hard release hold against the existing Phase 175 decisions.
Three advisor researchers compared the evidence contract, live-state freshness, and operator/release
surface together; recommendations were reconciled into one design rather than allowing each area to
invent a separate gate. The user selected the recommended set, asked to update the existing context,
and chose to replan affected plans afterward.

### Candidate evidence contract

| Option | Pros / cons / tradeoffs | Selected |
|--------|-------------------------|----------|
| One shared, immutable per-operation envelope bound to the canonical receipt digest and exact candidate/leg | Gives linked release, recovery, and companion publication one auditable contract; prevents identity drift and path-specific omissions. Requires explicit schema and evidence digests, and a post-merge envelope because merge OID does not exist at pre-merge authorization. | ✓ |
| Keep checks in separate workflow branches and trust logs or independently shaped files | Smaller first patch and local flexibility, but every path can omit a field or interpret evidence differently; logs are hard to bind to the exact operation and difficult to mutation-test as a single authorization. | |

**User's choice:** Use one shared, fail-closed evidence contract consumed by every release-side-effect
path. The pre-merge record authorizes only the exact reviewed merge; a later post-merge envelope
binds the actual merge OID and is required by the publisher guard.

**Notes:** The evidence should bind operation (`linked_release`, `recovery`, or `companion_publish`),
canonical receipt digest, exact candidate identity, leg-specific run ID, and six REL-17 conditions.
Retain raw registry response bytes alongside a checked nonempty parse and the matching response-table
row. SLSA provenance and GitHub artifact attestations are useful precedents because they bind
evidence to a subject digest rather than relying on a filename or workflow log alone
([SLSA provenance](https://slsa.dev/spec/v1.2/provenance), [GitHub artifact attestations](https://docs.github.com/en/actions/concepts/security/artifact-attestations)).

### Freshness and authorization boundary

| Option | Pros / cons / tradeoffs | Selected |
|--------|-------------------------|----------|
| Re-fetch mutable facts at existing authorization and immediately before each side effect; check exact merge OID after merge | Adds API round trips and some latency, but catches changed base/head/readiness, CI, branch policy, and stale registry evidence at the point of use. Fail closed on API, parse, pagination, identity, policy, or bypass uncertainty. | ✓ |
| Approve once from a snapshot or treat an approval TTL as freshness | Simpler and fewer calls, but an unexpired snapshot can still be stale after a force-push, policy change, or newly failed check. A TTL proves age, not truth. | |

**User's choice:** Use staged live revalidation and retain the current distinct human decision gates;
do not add more prompts. Recheck the live base/head, merge-readiness, CI, and policy immediately
before authorization; require normal protected merge and reject administrative bypass. The
post-merge guard checks the actual merge OID before any publisher can act.

**Notes:** GitHub rules/rulesets and required-check policy are mutable remote inputs; exhaustive
pagination matters when policy or check listings can span pages ([rulesets](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets), [REST rules](https://docs.github.com/en/rest/repos/rules), [REST pagination](https://docs.github.com/en/rest/using-the-rest-api/using-pagination-in-the-rest-api)). Capture raw registry bytes before parsing and check parse cardinality; otherwise a command that emits empty or truncated JSON can quietly turn absence into success. The existing anti-pattern controls also require direct exit-code capture or `pipefail` for shell pipelines.

### API coverage and identity generalization

The plan-pre hooks detected a bounded GitHub/Hex/Maven API surface and a singular-to-plural
identity-model transition. The selected decisions are recorded in CONTEXT D-43/D-44 and
`COVERAGE.md`:

- Integrate the repository, policy, check, workflow-run/artifact, package-state, and release
  operations required by the exact release flow; explicitly opt out of unrelated account,
  organization, administrative, and generic API capabilities.
- Promote operation-bound evidence as the primary identity. The immutable authorization key is
  `(receipt_digest, operation, leg_run_id)`; candidate OIDs remain the artifact subject. A
  candidate-only key cannot safely distinguish linked release, recovery, and companion authority.

### Elixir architecture and evidence tests

| Option | Pros / cons / tradeoffs | Selected |
|--------|-------------------------|----------|
| Pure Elixir validator plus thin GitHub/registry/workflow adapters, a Mix task, and ExUnit mutation tests | Keeps domain rules deterministic and easy to test across positive and negative evidence, while keeping remote I/O at the boundary. Fits current release tooling and avoids storing state that already belongs to signed/retained evidence artifacts. | ✓ |
| Add Ecto-backed authorization records and a Plug/Phoenix dashboard | Could help a durable multi-operator service with concurrent workflows and a real account model, but this repository currently has no such product surface; it adds database lifecycle, web security, state synchronization, and a second permission path to an infrequent release utility. | |
| Implement the entire gate in shell/workflow expressions | Stays close to GitHub Actions, but mixes parsing, policy, and side effects; difficult to share across workflows and more fragile to mutation-test than a pure validator. | |

**User's choice:** Keep this Mix-first and Elixir-native: one pure contract, adapters for live I/O,
ExUnit positive cases and per-condition mutations, plus workflow-integrity checks proving each path
consumes it. No Ecto, Plug, or Phoenix work without a durable application requirement.

**Notes:** `Mix.Task` is the conventional Mix extension point for repository operator commands
([Mix.Task docs](https://hexdocs.pm/mix/Mix.Task.html)). Popular release systems reinforce related
patterns: Cargo's explicit dry-run boundary is useful for practice but cannot replace fresh
authorization ([Cargo publishing](https://doc.rust-lang.org/cargo/reference/publishing.html)); Go
module versioning makes published identities durable and emphasizes verification instead of
rewriting releases ([Go Modules Reference](https://go.dev/ref/mod)); Kubernetes release roles make
ownership and handoffs explicit ([Kubernetes Release Team](https://github.com/kubernetes/sig-release/blob/master/release-team/README.md)). npm's unpublish rules are a reminder to treat deletion/rollback promises as ecosystem-specific, not a reusable assumption ([npm unpublish policy](https://docs.npmjs.com/policies/unpublish/)).

### Operator experience and scope

| Option | Pros / cons / tradeoffs | Selected |
|--------|-------------------------|----------|
| Read-only, text-first release status until fresh evidence and a new exact-candidate authorization exist | Gives the maintainer a clear current state, named missing condition, and safe next action without creating another authority surface. Keep `BLOCKED`, `PARTIAL`, and `COMPLETE` meaningful; `READY FOR APPROVAL` is evidence status only. | ✓ |
| Add dashboard buttons or generic retry/resume/recover suggestions | Could appear friendlier, but hides which one-way action is being authorized, can encourage replay of a consumed token, and requires new app state and access control. | |

**User's choice:** Keep the existing operator surface; while REL-17 is open, report BLOCKED and do
not recommend retry, recovery, or resume by default. Preserve historical PARTIAL records. Give a
concise condition/reason and safe next step, keep raw payloads out of doctor output/logs, and use
text in addition to any status color.

**Notes:** The JTBD is for the release maintainer to decide whether this exact candidate/leg may
proceed, collect the evidence required to make that decision, and understand why the guard blocks.
Inputs are the canonical receipt, current remote GitHub facts, registry evidence, workflow run IDs,
and runbook ancestry; output is a clear status plus missing conditions and the permitted next step.
This is a low-frequency infrastructure task rather than a customer UI, so accessibility and UX live
in readable CLI/CI wording and exit behavior, not a new Phoenix surface. Brandbook voice is calm,
precise, status-oriented, and does not dramatize failures.

The 0.2.5 run also updates which repair plan is current: D-42's missing Mix and recovery-pin
symptoms describe the prior 0.2.4 failure, while the 0.2.5 evidence records a Maven artifact-roster
extra file and an iOS clean-room Jason API failure. Preserve D-42 as history and plan from the
normalized latest run evidence.

### GSD bookkeeping observation

| Option | Pros / cons / tradeoffs | Selected |
|--------|-------------------------|----------|
| Record stale `.continue-here.md` and missing `.planning/HANDOFF.json` as separate workflow housekeeping | Keeps REL-17 and the one-way release hold as the phase scope; uses current workstream `STATE.md` and phase `continue.md` for this resume. | ✓ |
| Add resume-state repair to Phase 175 | Might make one handoff file consistent, but widens a release-evidence plan and would repeat GSD bookkeeping work unrelated to the release gate. | |

**User's choice:** Note the discrepancy; do not expand this release phase into GSD repair.

**Notes:** This is a bookkeeping symptom to capture and route separately, not evidence that the
REL-17 technical recommendations need another research cycle. The user explicitly asked to avoid
wheel-spinning and authorized affected-plan replanning after the context update.

### Addendum — scoped replan review (2026-09-26)

The eight additive plans 175-34..41 received typed GSD plan review. The first review caught a real
scope mismatch in Plan 175-40: SC-7 names held PR #115, so allowing a replacement PR would have
changed the user goal. The plan now blocks if #115 cannot be made exact and carries PR #115 plus its
actual protected merge through the Gate 3, post-merge, run, and direct Hex evidence. Focused recheck:
zero blockers. Plan 175-36's 11-file aggregate is one warning only; its three sequential tasks cover
5/3/5 files and each has a clear release/recovery/companion boundary, so it stays one cohesive plan.

The phase-wide legacy failure-direction scan still reports 27 missing directions in older plans;
the new Plans 175-34..41 pass their targeted checks. Those legacy/historical plans are preserved,
not rewritten as a side effect of this gap closure. The phase progress counter now reads 59 plans /
51 summaries (86%); it is not verification status. A copied pattern archive initially matched the
plan-file heuristic because its filename contained `PLAN`; renaming it to
`PATTERNS-REL17-ARCHIVE-2026-09-26.md` removed that warning without changing its contents. The
remaining phase-index wave mismatches belong to historical Plans 175-11..14 and 175-20; the new
175-34..41 dependency chain indexes correctly. Next action is the explicit `--gaps-only` execution
route recorded in STATE and `continue.md`, not another discussion or planning pass.

The final context-drift check now flags only `175-RESEARCH.md` by timestamp. Its 2026-09-26 REL-17
addendum already covers the current technical decisions, alternatives, ecosystem lessons, and
validation design. The later CONTEXT addition records the completed plan-review outcome and the
PR #115 scope correction, not a new research question. Keep this as a nonblocking chronology warning;
do not restart the external research cycle for a timestamp-only delta. Refresh evidence at the
future live gate because candidate, policy, workflow, and registry facts can change.

## Follow-on discretion

- Exact JSON field names and adapter boundaries, provided the evidence contract and two-stage
  identity binding remain intact.
- How to exhaust GitHub pagination and preserve raw API response bytes in the current CI environment.
- Mutation-test organization, provided all six conditions and each irreversible workflow wiring
  are exercised.
- Concise user-facing wording for specific missing evidence, following the current brand book.

## Deferred Ideas

- [Resolved 2026-09-26; see addendum below] Reconcile stale `.continue-here.md` resume metadata and
  the missing root `.planning/HANDOFF.json` as workstream-scoped GSD bookkeeping.
- Do not add general release dashboards, workflow retry controls, a generic release database, or
  new product UI for this low-frequency authorization operation.

### Addendum — resume bookkeeping synchronized (2026-09-26)

After the user confirmed the recommended context update and asked for a safe context reset, the
stale Phase 175 `.continue-here.md` and the quality workstream `STATE.md` Session Continuity entry
were updated to agree with `continue.md`: Phase 174 is complete, Phase 175's REL-17 discussion and
replan are complete, and the next command is `$gsd-execute-phase 175 --gaps-only --ws
quality-ratchet-release`. This repairs handoff metadata only; it does not add release scope or
change any locked Phase 175 decisions. The handoff remains workstream-scoped rather than creating
a root-level one-shot `.planning/HANDOFF.json` that could conflict with another active workstream.

### Addendum — post-Plan-42 context refresh (2026-09-27)

The user selected **Update it** for the existing context and **Continue, then replan** for the
existing plans. The current phase context, active workstream state, roadmap, Plan 42 summary, and
release-guard diagnosis already settle the remaining implementation choices. No new gray areas
were presented, and no new technical preference was elicited.

Carried forward the recorded outcome: the `0.2.6` run was PARTIAL before publishers; its Gate 2
token is consumed; its trailer named the iOS run instead of the source-bound Hex `leg_run_id`; Plan
175-42 fixes that future selector binding but does not close REL-17; Plans 175-39..41 remain
superseded. The context refresh directs the next planning pass to start from current evidence and
explicitly grants no merge, release, recovery, or publication authority.

### Addendum — next-command handoff (2026-09-27)

The user chose to continue with the current Phase 175 context and then replan. Discussion/context
gathering is complete. The next command is `$gsd-plan-phase 175 --ws quality-ratchet-release`;
there is no runnable gap-only plan. Do not repeat discussion, Plan 175-42, or superseded Plans
175-39..41. This route creates a new plan from current evidence and does not authorize release-side
effects.

### Addendum — blocked preflight context refresh (2026-09-28)

The user asked for a recommendation and selected **Update it**. The active workstream state,
`continue.md`, `.continue-here.md`, and the halted Plans 175-49/50 already settle the behavior
boundaries, so no new implementation gray areas were presented. The context now records that a
zero exit alone is not proof of exactly one accepted tag ref; ambiguous evidence remains
`BLOCKED_PREFLIGHT` with zero writes and no decision. A new plan and digest are required, and the
exact one-way decision remains separate. No tag, CI rerun, merge, Gate 2, or publish action was
authorized.

### Addendum — Plan 175-52 output-classification contract (2026-09-29)

Three `gsd-advisor-researcher` agents independently researched stdout grammar, stderr treatment,
and receipt/DX design, then their recommendations were reconciled as one interface. Research
compared Git's porcelain contract and upstream examples with provenance and error-classification
guidance. The user asked to research all three areas and then approved the recommendations with
“lock it.”

## Stdout grammar

| Option | Description | Selected |
|--------|-------------|----------|
| Closed grammar for the known remote banner plus exactly one expected porcelain tuple | Accept zero or one exact `To https://github.com/szTheory/crosswake-shell-core-ios.git` framing line and exactly one tab-separated `*` row binding the fresh split OID to `refs/tags/v0.2.6` as `[new tag]`. Reject all unknown, duplicate, malformed, incomplete, truncated, or over-limit output. A valid tuple cannot hide ambiguous surrounding output. Git-version/output drift blocks safely but is diagnosable from bounded metadata. | ✓ |
| Check only exit status and grep for the expected tuple | Easy to implement, but extra rows, unrelated output, malformed framing, or partial output can coexist with a match and still be misreported as a single-ref result. Repeats the ambiguity that halted Plan 175-52. | |
| Reject every line other than the status tuple, including all banners | Simplest grammar, but rejects Git's known porcelain framing when emitted and confuses benign protocol framing with an unexpected ref result. | |

**User's choice:** Closed grammar for the known banner and exactly one expected status row.

**Notes:** The banner is framing only and optional for compatibility; the tuple and complete-stream
classification establish the ref result. Use a bounded parser with no generic acceptance of
unrecognized lines. Any future output drift blocks without retry.

## Stderr interpretation

| Option | Description | Selected |
|--------|-------------|----------|
| Capture streams separately; stdout plus exit code decide; persist only stderr presence state | Keeps verdict tied to porcelain and process status while retaining enough sanitized context to explain that stderr was present. Nonzero exit blocks. Stderr is never parsed, printed, excerpted, or stored; its stable state is `EMPTY` or `NONEMPTY_UNINTERPRETED`. | ✓ |
| Merge stderr into stdout and parse the combined stream | Avoids losing process output, but puts progress/diagnostic text into the verdict grammar, permits false ambiguity, and risks persisting credential-helper or remote detail. | |
| Treat any nonempty stderr as failure | Easy fail-closed rule, but harmless progress/diagnostic output can accompany a successful porcelain result; presence alone does not establish a ref failure. | |

**User's choice:** Keep stderr diagnostic-only and persist no raw stderr.

**Notes:** Preserve exit-status authority: any nonzero exit blocks regardless of stream contents.
With exit 0 and complete valid stdout, stderr presence alone neither proves nor denies the result.

## Receipt shape and operator experience

| Option | Description | Selected |
|--------|-------------|----------|
| Bounded, versioned, sanitized classification metadata plus the accepted tuple | Retain Git/parser versions, row/banner counts, unexpected/malformed stdout counts, truncation/limit state, stderr state, existing invocation/exit facts, and fixed low-cardinality block reason. Hash only the sanitized canonical receipt. Maintainers get a repeatable reason without storing sensitive process output. | ✓ |
| Persist raw stdout/stderr or snippets for forensic convenience | Makes future debugging easier, but output may contain sensitive paths, remote details, or credential/helper material; conflicts with the evidence privacy boundary and makes receipts an accidental log sink. | |
| Keep only pass/fail and the target tuple | Smallest receipt, but cannot distinguish expected framing, unknown output, malformed rows, or truncation; repeats the diagnostic gap that produced this hold. | |
| Add a dashboard, generic release API, retry surface, or permanent CI lane | Could add visibility or automation, but this is a rare maintainer-only one-time evidence path. A new authority-bearing surface would add state and policy beyond the task. | |

**User's choice:** Use bounded sanitized evidence in the existing maintainer-facing text/JSON flow.

**Notes:** The implementation should follow Crosswake's existing functional-core /
imperative-shell seam: collect bounded process facts at the shell boundary and classify explicit
data with a pure function where useful. No Phoenix, Plug, or Ecto surface is warranted. Show stable
reason codes and plain-language status; color must not carry meaning by itself. Do not add CI
coverage for this one-time parser unless a recurring contract is later demonstrated.

**Research references:** [Git push porcelain and dry-run semantics](https://git-scm.com/docs/git-push),
[Git transport framing](https://github.com/git/git/blob/master/transport.c),
[Git porcelain examples](https://github.com/git/git/blob/master/t/t5411/test-0001-standard-git-push--porcelain.sh),
[SLSA provenance](https://slsa.dev/spec/v1.2/build-provenance), and
[OpenTelemetry error recording](https://opentelemetry.io/docs/specs/semconv/general/recording-errors/).

### Follow-up research — Plan 175-53 source-boundary failure (2026-09-29)

Three parallel agents compared source-failure handling, stop conditions, and safe evidence. Their
coherent recommendation is recorded in the matching addendum in `175-CONTEXT.md`: preserve the
`SOURCE`/`FULL_CLONE_SPLIT_FAILED` terminal reason; use one isolated full-clone diagnostic attempt;
allow only a single evidence-supported local setup correction; otherwise stop for a reviewed
source/path/policy plan. If the split passes, require a new complete preflight and digest, durable
reservation, and no more than one authenticated dry-run after all gates pass. Capture bounded,
sanitized reason metadata only. Do not retry, change the split mechanism, or authorize a tag write.

This is a research recommendation, not yet recorded as a user choice. The next discussion should
lock or adjust it without repeating the research. The exact next command remains
`$gsd-discuss-phase 175 --ws quality-ratchet-release`.

### Addendum — Plan 175-53 source-boundary decision (2026-09-29)

The user selected **use the recommendations as written**, then explicitly asked to proceed to the
next GSD step automatically. Three `gsd-advisor-researcher` agents had already compared source
recovery policy, failure receipt design, and the post-split boundary. Their reconciled choice is
locked in `175-CONTEXT.md` as D-57 through D-61. This updates the previously pending research
status above; the earlier note remains as an accurate record of the state before user approval.

## Source-failure classification

| Option | Tradeoffs | Selected |
|---|---|---|
| Preserve `SOURCE` / `FULL_CLONE_SPLIT_FAILED` and classify only bounded facts (invocation failure, nonzero exit, invalid or missing OID, exit status if available, and explicit history/commit checks). | Actionable enough to distinguish source setup from split outcome; unknown stays unknown. Requires a small fixed classifier and gives up raw forensic detail. | ✓ |
| Collapse every failure to one generic split-failed code. | Simpler receipt, but hides whether the command could not start, exited unsuccessfully, or produced no usable OID; risks repeating unhelpful attempts. | |
| Persist command output or infer the cause from the last log line. | More apparent diagnostic detail, but unbounded, privacy-sensitive, brittle across Git versions, and unsafe when output is partial or ambiguous. | |

**User's choice:** Use the recommendations as written.
**Notes:** The terminal boundary and original receipt remain immutable; do not recast this as a dry-run failure.

## Recovery and stop rule

| Option | Tradeoffs | Selected |
|---|---|---|
| One newly planned isolated full-clone attempt, with at most one local setup correction only when bounded evidence proves a clone or invocation defect; otherwise stop for reviewed source/path/policy correction. | Keeps a proven local fix efficient while preserving attribution and a hard stop when evidence is inconclusive. | ✓ |
| Automatic or repeated retries, or change the subtree split algorithm until it works. | May mask transient issues, make results hard to attribute, expand scope, and consume stale evidence without a new review boundary. | |
| Stop after any first failure, including a proven local clone setup defect. | Maximally conservative, but needlessly turns a bounded setup repair into a separate full policy cycle. | |

**User's choice:** Use the recommendations as written.
**Notes:** No algorithm change, auto-retry, replay of Plans 175-49 through 175-53, or receipt/digest reuse.

## Conditional post-split boundary

| Option | Tradeoffs | Selected |
|---|---|---|
| If source split passes, continue in one separately planned evidence chain: complete fresh read-only preflight, new digest, durable reservation, at most one authenticated dry-run if all gates pass, then planned observations and independent audit. | Repeats mutable preflight reads, but keeps the result coherent and auditable without reusing stale identity. The dry-run remains evidence only. | ✓ |
| Stop after source diagnosis and require another plan before any preflight. | Adds an approval/planning boundary, but creates a separate cycle without a demonstrated new authority boundary between split evidence and non-publishing preflight. | |
| Reuse the previous preflight/digest or continue to tag creation after a successful dry-run. | Faster on paper, but violates freshness and one-way-door separation; explicitly prohibited by D-53 through D-56. | |

**User's choice:** Use the recommendations as written.
**Notes:** No tag write, merge, Gate 2, recovery, or publication follows from a successful dry-run.

## Receipt privacy and maintainer diagnosis

| Option | Tradeoffs | Selected |
|---|---|---|
| Fixed, versioned, low-cardinality fields with nullable exit status and bounded boolean/count checks; preserve unknown separately from false; show a stable reason code and one safe next action in existing text/JSON output. | Delivers useful, stable maintainer guidance with a small privacy-safe record; intentionally sacrifices raw forensic detail. | ✓ |
| One generic failure code and no next step. | Smallest surface, but operators cannot distinguish a recoverable setup defect from a reviewed policy/source problem. | |
| Persist or print stdout/stderr, raw arguments, paths, remotes, environment, or output hashes; add a dashboard or release API. | More apparent observability, but creates a durable log/privacy risk and a new state/authority surface for a rare maintainer operation. | |

**User's choice:** Use the recommendations as written.
**Notes:** Use the existing Mix-oriented CLI; no Phoenix/Plug/Ecto UI, retry UI, dashboard, generic release API, or permanent CI lane without later evidence of a recurring contract. Follow `brandbook/BRAND-SPEC.md` for calm, specific, actionable terminal wording. This release-tool task has no graphical interface or applicable UI component system.

## Research and design rationale

- Git's documented porcelain interface supports machine classification, while the observed Bash
  grep approach and Plan 175-52's extra unclassified stdout demonstrate why matching one expected
  row is insufficient.
- Full history must be checked in the actual isolated clone; shallow checkout defaults are a known
  setup trap. Keep command execution at the Mix/shell edge and classification pure and deterministic.
- Bounded provenance and low-cardinality error conventions support retaining normalized evidence
  rather than raw streams. The UX is for maintainers diagnosing a rare one-way-door workflow: concise
  status, a stable reason, one safe next action, and no color-only meaning.
- No adopter identity, release permission, registry write, tag push, merge, Gate 2, or publication
  authority was discussed or granted.

### Addendum — Plan 175-54 source readiness and diagnosis (2026-09-30)

The Plan 175-54 receipt records a started full-clone split process, full history and selected source
commit as available, exit status 1, and zero parsed OIDs. The bounded receipt does not establish
whether the package-prefix tree was present. Raw process output was not retained, so the cause is
unknown. No preflight, dry-run, write, publication, or release decision followed. Three
`gsd-advisor-researcher` agents compared source-boundary, diagnosis, and maintainer-DX decisions as
one coherent set; the user accepted the recommendations.

## Source readiness and failure handling

| Option | Pros | Cons / tradeoffs | Selected |
|---|---|---|---|
| Keep result-only `NONZERO_EXIT` | Smallest and avoids false interpretation. | Leaves checkable setup facts absent and diagnosis opaque. | Fallback only |
| Parse stderr or human-readable output | More specific if the exact message matches. | Git prose varies by version and environment, can be partial, and can reveal local paths or credential context. | |
| Check bounded preconditions before reservation; preserve opaque failure for everything else | Records direct facts, blocks early on false or unknown requirements, and preserves truthful failure classification. | Adds a few checks but cannot guarantee split success. | ✓ |

**User's choice:** Accept the recommendations.

**Notes:** In a separately reviewed follow-up, check `git subtree` availability, full history,
selected source commit availability, and the package-prefix tree at that commit. Record tri-state
facts; unknown and false block before reservation. If checks pass, preserve the existing split
arguments and algorithm and invoke it no more than once. Do not retry or parse human-readable
diagnostics. A failed process without a bounded direct explanation stays `NONZERO_EXIT`, cause
unknown.

## Maintainer explanation and architecture

| Option | Pros | Cons / tradeoffs | Selected |
|---|---|---|---|
| Root reason and action only | Minimal and stable. | Hides the known stage, source result, and exit status. | |
| Add a second public failure taxonomy | Can expose more distinctions. | Duplicates canonical reason codes and risks drift or implying a known cause. | |
| Render validated receipt facts in existing text and JSON | Gives maintainers known/unknown facts and one safe action in familiar surfaces. | Less forensic detail; deeper investigation needs a separate reviewed step. | ✓ |
| Generalized Git/release API, dashboard, or permanent CI | Could help if repeated workflows establish a product contract. | Adds abstraction, state, or maintenance cost without evidence of recurrence. | |

**User's choice:** Accept the recommendations.

**Notes:** The maintainer's job is to learn which facts are known, what remains unknown, and the
next safe review step. Show stable reason, stage, source result, observed exit status, explicit
cause-unknown wording, and one `REVIEW_SOURCE_SETUP` action. Use the existing Mix/shell process
boundary and pure classification; if code changes are warranted, keep the process seam private and
testable. Keep output calm, specific, and aligned with `brandbook/BRAND-SPEC.md`. Phoenix, Plug,
Ecto, and graphical UI are not applicable. Do not add a public taxonomy, raw output, or CI lane
without evidence of recurring use.

**Cross-ecosystem lessons:** GitHub Actions checkout commonly defaults to shallow history, so the
relevant history must be made explicit at the actual source boundary. Prefer stable Git object and
history checks over parsing localized or human text. Elixir's argv-based `System.cmd/3` and the
functional-core / imperative-shell split fit this boundary: command facts are collected at the
edge, and a pure classifier can preserve unknowns deterministically.

**Research references:** [Git subtree](https://github.com/git/git/blob/master/contrib/subtree/git-subtree.adoc),
[Git `rev-parse`](https://git-scm.com/docs/git-rev-parse),
[Git `cat-file`](https://git-scm.com/docs/git-cat-file),
[actions/checkout full-history guidance](https://github.com/actions/checkout#fetch-all-history-for-all-tags-and-branches),
[Elixir `System.cmd/3`](https://hexdocs.pm/elixir/System.html#cmd/3), and
[Mix process shell](https://hexdocs.pm/mix/Mix.Shell.Process.html).

No registry action, source retry, tag push, merge, Gate 2, recovery, or publication authority was
granted.

### D-64 clarification — machine protocol versus diagnostics (2026-09-30)

The user approved a narrow clarification after research found that the literal ban on all stdout
parsing contradicted D-54 and D-59: D-54 requires a complete porcelain parse, and Git's documented
successful `git subtree split` result is one commit ID printed to stdout. The unchanged invocation
has no documented output-free way to obtain that object ID.

| Option | Pros | Cons / tradeoffs | Selected |
|---|---|---|---|
| Permit only strict transient parsing of the successful split OID and exact D-54 porcelain; discard all raw bytes; keep human diagnostics and stderr opaque. | Preserves the required fresh evidence chain while keeping failures private and non-inferential. | Introduces two tiny protocol parsers whose complete-input behavior must be tested; ambiguous bytes still block. | ✓ |
| Keep a literal ban on parsing any stdout. | Strongest reading of the original privacy wording. | Makes the split OID unavailable and prevents D-59's required preflight and dry-run continuation after success. | |
| Parse Git error prose for a root cause. | Might appear more explanatory for one version. | Unstable, potentially sensitive, and explicitly rejected by D-64's privacy purpose. | |

The selected wording amends D-64 only for those exact protocols. D-56's required normalized
`git --version` metadata remains diagnostic-only and cannot decide the dry-run verdict. D-62
preconditions should use filesystem facts or exit statuses; their stdout is not parsed or persisted.
Any extra, malformed, truncated, or invalidly decoded outcome bytes are discarded and fail closed.
The bounded validated fields remain the only durable evidence. No tag, merge, Gate 2, recovery, or
publication action was authorized.

---

## Plan 175-55 unknown attempt disposition and next-step boundary

Three focused research perspectives covered architecture, release safety, and developer experience.
The architecture and release-safety reviews recommended a local-only reconciliation step. The DX
review preferred combining it with a source attempt only if a hard local gate could prove the prior
attempt did not occur. Because Task 3's status is unknown and the absent receipt does not prove the
source operation was never invoked, the synthesized recommendation chose local-only reconciliation.

| Option | Description | Selected |
|--------|-------------|----------|
| Local-only reconciliation | Read-only inspection of the preserved commits, working tree, and available local artifacts; no Plan 175-55 replay, source invocation, push dry-run, network access, implementation edits, tests, formatting, or release side effects. If the attempt boundary remains unknown, stop and preserve that uncertainty. | ✓ |
| Reconcile and make a new source attempt in the same plan | Could reduce handoffs if prior execution were conclusively ruled out by local evidence. Current evidence does not establish that, so it risks duplicating or misattributing a one-shot operation. | |

**User's choice:** Option 1, local-only reconciliation.
**Notes:** The immediate follow-up does not close REL-13 or REL-17. Any later source invocation needs a separately reviewed decision after the local reconciliation. Keep the existing Mix text/JSON surface, bounded privacy-safe classifications, and unknown-versus-false distinction. Phoenix, Plug, Ecto, a dashboard, and graphical UI are not relevant to this maintainer-only release evidence path.

The ecosystem research found useful explicit boundaries in Hex's `mix hex.publish --dry-run`,
Cargo's `cargo publish --dry-run`, and Git's `git push --dry-run --porcelain`: rehearsal commands
can prepare and validate artifacts while avoiding a publication or ref update, and porcelain output
is designed for machine parsing. Their semantics are command-specific; a dry-run cannot establish
what happened in another interrupted invocation. Elixir's Mix task and argv-based `System.cmd/3`
remain the idiomatic shell integration here; no new provider-facing API or persistence layer is
needed.

Research references: [Mix tasks](https://mix.hexdocs.pm/main/Mix.Task.html),
[Elixir `System.cmd/3`](https://hexdocs.pm/elixir/System.html#cmd/3),
[Hex publish dry-run](https://hex.hexdocs.pm/Mix.Tasks.Hex.Publish.html),
[Cargo publishing](https://doc.rust-lang.org/cargo/reference/publishing.html), and
[Git push `--dry-run` / `--porcelain`](https://git-scm.com/docs/git-push).

---

## Post-reconciliation recovery sequence (2026-10-01)

Three read-only reviews after Plan 175-56 agreed on a narrow recovery sequence. The interrupted
Plan 175-55 boundary is still UNKNOWN. Its missing receipt is not proof that the one-shot action did
not begin. The source operation must not be replayed.

The recovery audit found two local defects worth removing before another evidence attempt:

1. The Node collector emits an oversized-input error but does not return before checking for a
   newline and dispatching the child process. Add an early abort and a fake-child assertion that
   proves an over-limit request cannot launch a child.
2. The iOS mirror parity failure message documents `version`, `release_ref`, and `apply=true`, but
   the current workflow uses a different `operation` contract and has no historical v0.2.6 repair
   operation. Replace the unsupported command with non-mutating blocked guidance and cover the
   guidance/workflow contract so drift fails locally.

**User's choice:** Autonomous recommendation accepted: plan and proceed with these local safeguards;
keep fresh remote evidence and every source/tag/release operation for separate reviewed plans.

Fresh read-only observations confirmed source tag `ios-core-v0.2.6` at
`998742856a37a97ae7247f6c532f9c154ea20885`, mirror tag `v0.2.5` at
`424ab96ede1b92f2b751b54bce04c6e607f0f3c8`, no mirror tag `v0.2.6`, and open PR #219 at head
`696a27a3be1fcd56efe70923dc0ce286a1c41c6d`. The only failing required check remains
`ios-mirror-parity-proof` in its recorded run; there is no fresh CI run yet. Re-read these facts
before any later operation. Matching `v0.2.5` content is not proof of the expected `v0.2.6` split
identity.

---

## Future source-attempt lifecycle evidence (2026-10-01)

The local forensic review found no task/process start or exit journal for the interrupted Plan
175-55 attempt. It cannot resolve whether Task 3 began. The parallel boundary review recommended a
new, durable supervisor lifecycle record before any new source attempt.

| Option | Description | Selected |
|--------|-------------|----------|
| New lifecycle journal and staged exact authorization | Add locally testable, bounded task-entry/reservation/dispatch-intent/process-start/exit events; refresh read-only source/mirror/candidate facts; stop for an operation-specific decision before a no-write source split or conditional push dry-run. Keep tag creation behind a second exact-OID decision. | ✓ |
| Run the existing one-shot path without lifecycle changes | Less local work, but another interrupted invocation could leave the same ambiguity. | |
| Stop all further release work | Avoids another operation but leaves the concrete missing-mirror blocker unaddressed. | |

**User's choice:** Autonomous recommendation accepted through the exact operation-specific approval
boundary. Prepare the reviewed plan and local automation. The approval checkpoint itself remains
mandatory; no source operation, push dry-run, or tag write is authorized by this selection.

The decisions are recorded as D-73 and D-74 in `175-CONTEXT.md`. Any interrupted new attempt after
dispatch intent is MAY_HAVE_STARTED/UNKNOWN and terminal; no replay. The old Plan 175-55 boundary
stays UNKNOWN regardless of future evidence.

## Follow-up — Plan 175-58 Preflight Blocker (2026-10-01)

**Finding:** Plan 175-58's fresh artifact is BLOCKED because aggregate required CI is FAILURE and
branch policy is UNKNOWN. A further read-only check found the sole failed job is
`ios-mirror-parity-proof` (the gate depending on the absent mirror tag); all other jobs in that run
passed. The mirror repository has an active tag ruleset with non-fast-forward and deletion rules,
no creation rule, and affirmative read-only push permission. The branch-protection endpoint and
required-check observation do not fully reconcile, so branch merge policy stays UNKNOWN.

**Recommendation:** Separate no-write repair-attempt eligibility from candidate release readiness.
Require the fresh exact-head check to prove that parity is the sole failure, that every other job
passes, and that source/PR/ref/permission facts are current. Show the unresolved branch-policy fact
at the exact operation decision; do not treat it as proof of release readiness. Plan 175-58's
BLOCKED artifact remains immutable and is not reusable. A fresh reviewed plan needs a new opaque
attempt ID. The source split and conditional dry-run still require the user's exact operation
authorization; tag creation requires a separate later exact-OID authorization.

**Decision:** Adopt D-75 in `175-CONTEXT.md` as the recovery-plan boundary. Continue autonomous
planning and local/read-only automation up to the exact operation-specific approval. Keep
REL-13/REL-17 OPEN and the release hold ACTIVE.

## Follow-up — Plan 175-59 CLI Transport and Stale CI (2026-10-01)

**Finding:** Plan 175-59's new artifact is BLOCKED at attempt
`715ae99fb28ef5b4aff7a5077bc3fb50`. The collector appended `--jq .` to paginated, slurped
`gh api` calls; GitHub CLI rejects `--jq` with `--slurp`. That made the run, freshness, and tag
ruleset observations UNKNOWN. Independent read-only inspection found that the sole existing
exact-head run `36438452825` completed on 2026-09-28 and was stale on 2026-10-01. Its full
job roster contains two failures: the independent `ios-mirror-parity-proof` leaf and the terminal
`Crosswake CI` aggregate, which fails when a required leaf fails. All other jobs passed. Active
mirror tag ruleset `17668056` applies to `refs/tags/**/*` with non-fast-forward and deletion
rules. None of these diagnostic reads modifies Plan 175-59's immutable artifact or grants source
authority.

**Recommendation:** Fix and fake-adapter test the CLI argv construction; obtain complete pages
for runs, exact-attempt jobs, and parent-inclusive tag rulesets with full conditions and rules.
Classify the aggregate as a derived failure only when the exact run, attempt, PR head/base, and
workflow dependency graph prove it is caused solely by the parity leaf. A stale run may trigger
one guarded failed-jobs CI rerun, with a durable intent record, followed by completed-attempt
inspection and a new immutable preflight. Unknown rerun outcome cannot be retried. Stop at an
unselected, exact-operation decision before any source split or push dry-run.

**Decision:** Adopt D-76 in `175-CONTEXT.md`; automate local correction and ordinary CI
verification through the source-operation decision boundary. Keep Plan 175-59's attempt and
artifact immutable, Plan 175-55 UNKNOWN, REL-13/REL-17 OPEN, and the release hold ACTIVE.

### D-76 required-check proof clarification

The Plan 175-60 review found that `gh pr checks --required --json name,state` alone does not
prove an exhaustive required-check roster or bind each check to the exact PR head and workflow
attempt. Use the read-only GraphQL head commit `statusCheckRollup.contexts` connection as the
authoritative observed-check roster. Fetch all cursor pages through `hasNextPage=false`, reconcile
`totalCount`, evaluate `isRequired(pullRequestNumber: 219)` on every `CheckRun` and
`StatusContext`, and cross-check PR number/head/base and each required check's commit and, for
workflow checks, run ID/attempt. Because an observed rollup cannot reveal a required context
that never reported, independently fetch the exact base branch's active effective rules through
`GET /repos/{owner}/{repo}/rules/branches/{branch}` and its traditional GraphQL
`branchProtectionRule`; reconcile their required-context declarations with the observed required
nodes. A missing page or declaration, duplicate, mixed identity, inaccessible source, mismatch, or
unrelated failed/pending required check blocks. `gh pr checks --required` is corroboration only;
this PR-specific classification does not resolve independent branch merge policy. This tightens
D-76's evidence gate without expanding source or release authority.

## Exact-head evidence scope and implementation shape (2026-10-02)

**User's direction:** The user asked for a single coherent recommendation, delegated the choice, and
asked to keep moving forward. Three specialist research agents compared evidence scope, Elixir and
Mix architecture, and successful release automation patterns. The active Phase 175 STATE and
ROADMAP, not the older resume prose in `.continue-here.md`, define the current boundary.

### 1. What should happen next?

| Option | Pros | Cons / risks | Decision |
|---|---|---|---|
| Stop at local evidence | No remote or permission risk; preserves the release hold cleanly. | Leaves the known exact-head workflow-byte and effective required-check policy gaps unresolved, so repair eligibility cannot be assessed. | Not selected as the next step. |
| Fresh read-only exact-head collection | Resolves the precise Plan66 gap; binds workflow bytes, the exact run attempt, complete check roster, and effective required-context declarations; needs read-only access only. | Pagination, exact identity binding, stale runs, and policy-source disagreement must fail closed; a partial response is not useful authorization evidence. | **Selected.** This is the narrowest step that resolves the next known blocker. |
| Add one guarded failed-job rerun | Could produce fresh CI if the complete old roster proves D76's exact predicate and no newer or active same-head run exists. | Requires Actions write authority; reruns can execute jobs with original trigger context; an uncertain dispatch cannot safely be retried; fresh green CI still would not resolve separate release holds. | Excluded from this collection. Consider only in a separate reviewed plan after complete facts satisfy D76. |

### 2. What evidence makes the collection trustworthy?

Bind PR number, head/base OIDs, workflow path and exact-head bytes, run ID and attempt, complete job
roster, required check results, and effective required-context declarations. Exhaust each API
connection's cursors, reconcile declared totals, reject duplicates, and cross-check the identities
all the way back to the PR head. Reconcile observed required contexts with effective branch
requirements so a context that never reported cannot silently disappear. Verify the aggregate graph
from workflow bytes at that same head. Preserve `UNKNOWN` separately from `FALSE`; incomplete,
stale, pending, inaccessible, mismatched, or ambiguous observations block. The failed terminal
aggregate is derived only under D76's closed predicate: exact identity, proven aggregate dependency,
parity is the only independent failure, all other independent jobs pass, and no unrelated required
failure exists.

A new immutable attempt ID, schema, artifact, and write-ahead lifecycle prevent stale evidence from
being mistaken for current authorization. No past artifact, digest, or run is reused. A complete
read-only artifact supports only a later repair-eligibility decision; it is not release readiness.

### 3. How should the Elixir boundary feel to a maintainer?

| Approach | Pros | Cons / tradeoffs | Recommendation |
|---|---|---|---|
| Existing release evidence modules plus a private, plan-scoped Mix entrypoint | Idiomatic for this repository's existing `Mix.Task` status commands and functional-core/imperative-shell design; local fake runner can exercise response shapes; one classifier owns text/JSON semantics. | A new command and evidence schema are maintenance cost; keep them private and attempt-scoped so this does not become an accidental stable public API. | **Preferred if implementation is needed.** Inject `gh` execution, keep argv/shell use at the edge, classify only decoded bounded facts. |
| A standalone Python or Node one-off collector | Quick to discard and separate from the Mix product surface. | Duplicates transport/classification logic, language/runtime assumptions, and makes existing Elixir evidence validators less authoritative. | Use only if it emits a receipt that the existing Elixir validator strictly accepts; no independent policy logic. |
| Widen public `mix crosswake.release.status` with `--live`/preflight switches | Familiar single command. | Turns a stable status surface into a network side effect with hidden latency, permissions, stale-data semantics, and rerun-adjacent confusion. | Reject for this task. Keep network collection explicit and separately named. |
| Add Plug/Phoenix endpoint or LiveView | Useful for an actual hosted, multi-user request or operator workflow. | Adds HTTP routing/auth/UI lifecycles to a local release evidence command; no current user journey calls for it. | Not applicable. |
| Add Ecto persistence | Useful where durable transactional domain state or queryable shared records are required. | Current attempt artifacts and lifecycle records already provide the required audit trail; a database would duplicate authority and complicate recovery. | Not applicable. |

Use explicit argv, bounded output and time/size handling, injected process/API functions, a pure
deterministic classifier, and sanitized persisted facts. Keep raw responses, stdout/stderr, tokens,
environment, credentials, and local paths outside artifact and output. A failed transport or
unsupported response is `UNKNOWN/BLOCKED`, never a guessed domain result.

### 4. What do successful release tools teach here?

| Ecosystem example | What it does well | Footgun to avoid | Application to Crosswake |
|---|---|---|---|
| GitHub Actions | Supports least-authority jobs and immutable artifact digests; gives an exact run/attempt model for evidence. | A run ID is not an attempt identity; reruns keep the original commit/ref and trigger privileges, so rerun dispatch is not a harmless read. | Persist head + run ID + attempt + artifact digest; separate `contents: read` evidence collection from any Actions write job. |
| Release Please | Prepares a version/changelog in a reviewable release PR, then creates a release at a reviewed commit; publishing can be a separate workflow. | Lifecycle labels can drift when a release PR is closed/reopened and require manual recovery. | Keep preparation, verification, and publication as distinct states; never treat labels as evidence. |
| Changesets | Separates version/changelog preparation from `publish`; version changes can be reviewed before publication. | Publishing assumes commit identity does not drift; pre-release mode removes guardrails. | Bind publication evidence to the reviewed version commit and model each registry target's result independently. |
| GoReleaser | Snapshot mode with publish skipped rehearses local release configuration without opening a publish door. | Snapshot success proves packaging/configuration only; it says nothing about current remote refs, permissions, run identity, or registry state. | Preserve the rehearsal/read-only boundary and state exactly what evidence does and does not prove. |

### 5. Operator job and output contract

The maintainer's job is to judge one named repair-evidence attempt without parsing GitHub internals
or raw command output. The input is an explicit candidate/head; the system reads only the facts
needed to classify that attempt; the result is an identity-bound artifact plus a short text or JSON
status, stable reason, completeness/currentness, and one safe next action. Keep API queries, command
argv, raw payloads, and backend implementation out of user-facing text. Plain status words, stable
field names, text/JSON parity, explicit unknown-versus-false, bounded output, and no color-only
meaning support accessibility and reliable automation. Follow `brandbook/BRAND-SPEC.md`, the newer
ratified brand specification, for calm, specific maintainer wording. Browser UI, adopter persona
flows, graphic direction, and visual system work do not apply to this CLI-only decision.

The other relevant quality lenses are correctness and provenance; fail-closed safety; least
privilege; privacy; completeness; retry/idempotency boundaries; rate-limit and latency cost;
reproducibility; recoverability; observability; compatibility; maintainability; and actionable
operator experience. The exact-head read plan should resolve each at the smallest needed contract;
it must not introduce an unproven permanent CI lane or generic release framework.

**Selected recommendation:** Update `175-CONTEXT.md` with D77-D82, then prepare a new reviewed,
read-only exact-head evidence plan using the existing Elixir evidence seam if code is needed. The
plan may include local deterministic fake-response checks where it changes classification, but this
discussion did not run tests or perform remote reads. No rerun, source split, push dry-run, tag,
merge, Gate 2, recovery, registry write, or publication is authorized. Plan55 remains UNKNOWN;
REL-13/REL-17 stay OPEN; candidate readiness stays BLOCKED; the release hold stays ACTIVE.

### Research references

- GitHub: [secure use](https://docs.github.com/en/actions/reference/security/secure-use),
  [artifact attest/digest guidance](https://docs.github.com/en/actions/tutorials/store-and-share-data),
  and [workflow reruns](https://docs.github.com/en/actions/how-tos/manage-workflow-runs/re-run-workflows-and-jobs).
- Release Please: [design](https://github.com/googleapis/release-please/blob/main/docs/design.md)
  and [troubleshooting](https://github.com/googleapis/release-please/blob/main/docs/troubleshooting.md).
- Changesets: [command-line behavior](https://github.com/changesets/changesets/blob/main/docs/command-line-options.md).
- GoReleaser: [snapshot / skip-publish CI example](https://www.goreleaser.com/customization/ci/rwx/).
- Elixir ecosystem: [Mix.Task](https://mix.hexdocs.pm/main/Mix.Task.html),
  [System.cmd/3](https://hexdocs.pm/elixir/System.html#cmd/3),
  [Plug.Router](https://hexdocs.pm/plug/Plug.Router.html), and
  [Ecto.Repo](https://hexdocs.pm/ecto/Ecto.Repo.html).

### Assumption-delta — evidence identity anchor

The GSD assumption-delta scan matched historical roadmap terms such as “second” and “additional.”
The substantive question is whether adding exact workflow-content and paginated status/policy sources
changes what identifies one evidence attempt.

**Decision:** It does not. D-83 keeps the immutable identity tuple as the selected PR, exact head/base
OIDs, workflow path/content digest at that head, and exact run ID/attempt. API pages corroborate the
identity; branch policy is a separate fact. Workflow content is parsed transiently and only its
digest plus bounded derived facts are retained. No new alternate identity or general GitHub client is
introduced.

### API coverage delta

The existing `COVERAGE.md` already covers PR/head identity, exact CI/check results, and effective
branch policy. Added one explicit INTEGRATE row for reading workflow definition bytes at the
immutable PR head. It is required to prove aggregate behavior from the workflow that corresponds to
the selected evidence. Its output is transiently parsed and represented by digest and bounded facts;
all CI rerun and mutating capabilities remain outside the chosen plan.

## Follow-up — Plan68 UNKNOWN triage and next evidence boundary (2026-10-02)

Plan68's only reviewed collection ended UNKNOWN and retained zero run/job/check facts, no workflow
digest, and no source-specific failure. Inspection of the collector showed why: any later-stage
error is collapsed into an all-UNKNOWN fact set, losing earlier successful observations. The
terminal artifact and lifecycle are immutable and will not be retried or reinterpreted.

| Option | Pros | Cons / tradeoffs | Decision |
|---|---|---|---|
| Stop with the current aggregate UNKNOWN | No additional collection or schema work; the release hold remains clear. | Leaves no way to tell which source was incomplete or whether earlier sources succeeded, so the maintainer cannot select a useful next action. | Rejected as the immediate next step. |
| Preserve bounded status/counts per source, fake-test locally, then use one fresh reviewed read-only attempt | Keeps successful normalized observations, shows which source was unavailable or not attempted, improves maintainer triage, and preserves fail-closed classification. | Adds a closed evidence shape, schema/version, validator and fake cases; a fresh read remains subject to permissions and may still end UNKNOWN. | **Selected.** |
| Persist raw provider errors or response excerpts | Could make debugging faster in a local terminal. | Risks credentials, paths, provider internals, and unbounded data entering artifacts or logs; conflicts with privacy and stable DX. | Rejected. |

The Elixir shape stays idiomatic to this repository: the private imperative adapter returns tagged,
bounded source outcomes; the pure classifier composes them without throwing away valid earlier
facts; a closed schema validates text/JSON parity. No Plug/Phoenix route, Ecto persistence, generic
provider client, hidden network behavior in `mix crosswake.release.status`, or UI is useful for this
single maintainer task. Source states must be finite and safe, unavailable counts stay UNKNOWN, and
one overall UNKNOWN result never authorizes the next operation.

**Decision:** Adopt D-84–D-86 in `175-CONTEXT.md`. Plan one local implementation/verification slice
followed, only after a fresh plan review, by at most one read-only exact-head collection using a new
attempt ID, schema, artifact, and lifecycle. Capture no raw error or provider data. Stop after any
uncertainty. Do not rerun CI, retry Plan68, perform source operations, tag, merge, consume Gate 2,
recover, or publish. Keep Plan55 UNKNOWN, REL-13/REL-17 OPEN, candidate readiness BLOCKED, merge
policy UNKNOWN, and the release hold ACTIVE.

## Plan69 failure disposition and fresh-attempt boundary — 2026-10-02

The user asked that all relevant areas be considered and that the recommended direction be carried
forward. All phase-relevant choices were evaluated; the context already fixes the high-level release
and authority boundaries. The recommendations below apply to the new Plan69 review findings and
any separately reviewed follow-up. They do not authorize a remote read from this discussion.

### Consumed attempt and path isolation

| Option | Pros | Cons | Selection |
|---|---|---|---|
| Retry/repair Plan69 | Lowest code setup | Mutates or repeats an uncertain attempt; violates immutable one-shot evidence | Rejected |
| Stop permanently after local fixes | No additional remote observation | Leaves exact-head sources unknown | Rejected as the next step; remains the fallback if a fresh plan cannot pass review |
| New plan, identity, schema, artifact path, and lifecycle path | Preserves old evidence; one new observation can produce attributable outcomes | Requires a small plan-scoped code/task and may still finish UNKNOWN | **Recommended; applied as the next-plan boundary** |

### Failure classification and lifecycle closure

| Option | Pros | Cons | Selection |
|---|---|---|---|
| Convert request exceptions at the injected source boundary | Retains earlier normalized sources; marks the failed and dependent sources precisely | Requires bounded per-source reason mapping | **Recommended; implemented** |
| Top-level catch-all only | Less code | Loses source attribution and can strand the attempt | Rejected |
| Generic GitHub provider abstraction | Could be reused by many future tools | Expands API/maintenance surface without a second consumer | Rejected |
| On artifact-write failure, append a terminal sanitized lifecycle event if writable | Closes the attempt without claiming an artifact or leaking errors | Cannot guarantee closure if the lifecycle filesystem also fails | **Recommended; implemented and fake-tested** |
| Retry persistence or leave only intent | Might recover a write or use less code | A retry hides uncertainty; intent-only gives no terminal disposition | Rejected |

### Proof semantics and operator output

| Option | Pros | Cons | Selection |
|---|---|---|---|
| Require OPEN at both PR reads | Keeps proof tied to the current candidate | A closed but internally consistent PR remains UNKNOWN | **Recommended; implemented** |
| Permit a matching CLOSED snapshot | Preserves historical completeness | Can label evidence for a no-longer-active candidate PROVEN | Rejected |
| Shared validated text and JSON projection | Same states/reasons for maintainer and automation; usable CLI output | Maintains two renderings over one small projection | **Recommended; implemented** |
| JSON only or new dashboard | Simpler output surface / richer presentation respectively | JSON alone is less legible; dashboard exceeds scope and adds UI support | Rejected |

**[auto] Recommendation applied:** use a new separately reviewed plan for at most one read-only exact-
head attempt after local checks pass. Stop on any uncertainty. No retry, CI rerun, source split,
push dry-run, tag, merge, Gate 2, recovery, registry write, or publication. The prior live attempt
and its incomplete lifecycle remain unchanged.

**Verification:** the local review fixes are in place, formatting completed, and the focused runner
and evidence suites pass (91 tests, 0 failures). There are no remaining product, adopter, or visual
design decisions in this follow-up; it is a maintainer CLI evidence task and introduces no
Plug/Phoenix, Ecto, dashboard, or brand/graphic work.

## Plan70 outcome, local diagnosis, and follow-up boundary — 2026-10-02

The user requested recommendation-led research across all decision points relevant to this phase,
with idiomatic Elixir/Mix guidance, privacy and SRE review, useful examples, and DX/UX considered
where applicable. Two read-only `gsd-advisor-researcher` agents reviewed local evidence and official
Elixir, GitHub, and Terraform references. They did not inspect Git history, invoke a collector,
access a remote service, run tests, or modify code.

### Plan70 terminal failure and diagnosis path

| Option | Description | Selected |
|--------|-------------|----------|
| Stop at terminal `UNKNOWN` | Preserve the attempt and do no more work; accurate and privacy-safe, but skips a useful local review of possible failure boundaries. | |
| Local-only diagnosis first | Inspect the retained Plan70 summary/lifecycle and local runner, validator, request boundary, and existing fake coverage. This may map possible paths but cannot recover Plan70's source outcome, request count, or cause. | ✓ |
| Plan a fresh read immediately | Might return current source facts, but could fail again, may fan out into paginated GitHub requests, and needs a new independent plan/review and authority. | |

**User's choice:** Local-only diagnosis first.

**Planning handoff:** Use `$gsd-plan-phase 175 --ws quality-ratchet-release`. Since this phase has
existing plans, choose “Add more plans” at the planner's existing-plans prompt; preserve the
existing plan history and do not replan from scratch.

**Notes:** Plan70's invocation exited 1; the four-event lifecycle ends in `collection-failed`, the
artifact is absent, and source outcome/request count/cause remain unknown. The current broad rescue
boundary can explain how attribution could be lost, but cannot identify what happened in the
consumed attempt. The working tree already contained changes to shared runner/evidence files, and
the temporary task entrypoint is gone; current source cannot establish the exact execution-time
path. The local diagnosis is read-only and has no network, test/formatter, code-change, CI, source,
or release action.

### Gate for any later remote observation

| Option | Description | Selected |
|--------|-------------|----------|
| Stop permanently with current unknowns | Simplest; leaves fresh source facts unavailable. | |
| Revisit after local diagnosis through a separate discussion, plan, and independent review | Preserves a path to needed current evidence without treating the consumed attempt as authority. | ✓ |
| Plan another read now | Could collect fresh facts sooner, but the user selected local diagnosis first; no new read is authorized by this context. | |

**Decision carried into CONTEXT.md:** No new remote observation is planned now. If it remains
necessary after local review, it requires a new discussion, plan, independent review, unique attempt
ID/schema/artifact/lifecycle paths, endpoint-minimum permissions, bounded pagination, and its own
authority. One collector invocation may perform multiple API requests. Any uncertainty ends that
future plan; no read authorizes a release side effect.

**Research synthesis:** GitHub CLI exit 1 is a generic error and cannot name the failed source.
REST/GraphQL pagination means a shell invocation is not a request count. Terraform's diagnostic
summary/detail structure is a useful maintainer-tool precedent, while this project's privacy rules
exclude raw provider errors. The current Mix text/JSON surface, explicit `UNKNOWN`, and one safe next
action remain the coherent boundary. General SRE guidance favors low-cardinality signals for
recurring operations; this one-shot maintainer command does not justify adding Logger/Telemetry
instrumentation. No Plug/Phoenix/Ecto surface, UI/graphic-design work, new error taxonomy, generic
provider, or permanent CI lane was justified; D-89 and D-91 remain in force. The current [Crosswake
brand specification](<home>/projects/crosswake/brandbook/BRAND-SPEC.md) governs wording.

**Research sources:** [Mix.Task](https://mix.hexdocs.pm/Mix.Task.html), [GitHub CLI exit
codes](https://cli.github.com/manual/gh_help_exit-codes), [REST pagination](https://docs.github.com/en/rest/using-the-rest-api/using-pagination-in-the-rest-api),
[REST rate limits](https://docs.github.com/en/rest/using-the-rest-api/rate-limits-for-the-rest-api),
[GraphQL rate limits](https://docs.github.com/en/graphql/overview/rate-limits-and-query-limits-for-the-graphql-api),
[Terraform diagnostics](https://developer.hashicorp.com/terraform/plugin/framework/diagnostics),
[Elixir Logger](https://logger.hexdocs.pm/Logger.html), [Telemetry](https://telemetry.hexdocs.pm/),
and [Google SRE monitoring guidance](https://sre.google/sre-book/monitoring-distributed-systems/).

## the agent's Discretion

All phase-relevant engineering lenses were considered as requested. The next local plan should
follow D-93 through D-95 and the existing D-89/D-91 boundaries; no UI/UX or app/API capability area
applies to this maintainer-only release diagnosis.

## Deferred Ideas

None — discussion stayed within Phase 175 scope.

## Missing v0.2.6 mirror tag and fresh-plan boundary — 2026-10-02

| Option | Description | Selected |
|---|---|---|
| Keep the release held; add no plan | Preserves the current release boundary with no additional provider or write uncertainty, while PR #219 and Plans 175-45 through 175-48 remain blocked. | |
| Add a fresh read-only reconciliation plan first | Refreshes facts only if a decision-relevant ref or policy may have changed; can otherwise repeat already recorded evidence and end UNKNOWN. | |
| Add a fresh, narrowly scoped mirror-tag repair plan | Plans around the exact missing `v0.2.6` target, a new preflight/evidence identity, one exact operation behind distinct review and authority, and parity re-evaluation. | ✓ |

**Research:** Two parallel `gsd-advisor-researcher` agents assessed release/supply-chain risk and Elixir/Mix maintainer ergonomics. Both recommended skipping another standalone diagnostic cycle unless a specific decision-relevant fact is missing or may have changed. Git subtree behavior depends on identical history/settings; remote rules and hooks can reject a push, and a new tag can trigger downstream automation. Release Please and Changesets are useful precedents for making tag/release/publish lifecycle boundaries explicit, but they do not supply authority for this operation. Their sources included [Git subtree](https://github.com/git/git/blob/master/contrib/subtree/git-subtree.adoc), [git-push](https://git-scm.com/docs/git-push), [GitHub rulesets](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets), [Mix.Task](https://hexdocs.pm/mix/Mix.Task.html), [System.cmd/3](https://hexdocs.pm/elixir/System.html#cmd/3), [Release Please](https://github.com/googleapis/release-please/blob/main/README.md), and [Changesets tag command](https://github.com/changesets/changesets/blob/main/docs/command-line-options.md).

**User's choice:** Add a fresh, narrowly scoped mirror-tag repair plan.

**Notes:** This choice authorizes planning only. It does not authorize remote observation, a tag write, CI rerun, Gate 2, merge, recovery, registry action, or publication. Keep Plan70's cause and request occurrence/count UNKNOWN, Plan55 UNKNOWN, REL-13/REL-17 OPEN, candidate readiness BLOCKED, merge-policy UNKNOWN, and the release hold ACTIVE. The current brand specification governs wording; no consumer UI or visual-design work applies.

## Post-Plan 175-77 next-work scope

| Option | Description | Selected |
|---|---|---|
| Stop all Phase 175 work at the safe stop | Preserves uncertainty and adds no further access or maintenance surface, but leaves the explicit REL-17 blocker without a next step. | |
| Read remotely again to diagnose Plan76 | Can collect current facts, but cannot establish Plan76's cause; requires new authorization and may again end UNKNOWN. | |
| Add more Plan76-specific logging or a new taxonomy | Could help a demonstrated defect or recurring need; Plan77 found neither, so the change would be speculative and could expand disclosure. | |
| Plan local REL-17 condition-by-path coverage and gap closure | Uses deterministic local proof to advance the explicit blocker without remote authority; requires path-level tests as shared-validator tests alone cannot exclude bypasses. | ✓ |

**User's choice:** The user requested all relevant areas be researched and asked the assistant to make one coherent recommendation to avoid additional decision burden. Recommended and recorded: plan local REL-17 coverage/gap closure next; preserve Plan76 as terminal and do not make another read to recover its historical cause.

**Research:** Three gsd-advisor-researcher agents examined the next-step options, REL-17 contract shape, and proof strategy. The implementation contract shape was already decided in D-43–D-46 and was carried forward. The recommended test strategy combines valid positive controls, one-condition/identity mutations, fake side-effect sinks at each protected path, and workflow guard presence/order mutations. Existing recurring checks may remain in CI; the exhaustive cross-path matrix is one-time sanitized phase evidence. Sources include [GitHub secure use](https://docs.github.com/en/actions/reference/security/secure-use), [GitHub reusable workflows](https://docs.github.com/en/actions/reference/workflows-and-actions/reusing-workflow-configurations), [Mix.Task](https://hexdocs.pm/mix/Mix.Task.html), [Elixir defstruct](https://hexdocs.pm/elixir/Kernel.SpecialForms.html#defstruct/1), [ExUnit](https://hexdocs.pm/ex_unit/ExUnit.Case.html), and [Release Please](https://github.com/googleapis/release-please-action).

**Notes:** This is a planning recommendation only. Plan76 stays UNKNOWN_UNVERIFIABLE; its authorization remains consumed. Plan77 does not establish the historical cause and reproduced no separate production defect. REL-13/REL-17 stay OPEN, candidate readiness BLOCKED, merge-policy UNKNOWN, release hold ACTIVE, and Plans45–48 held. No remote read or write, CI rerun, merge, Gate 2, recovery, registry action, or publication was authorized. CLI text/JSON remains the operator surface; Phoenix, Plug, Ecto, consumer UI, and graphic design do not apply. If CLI wording changes in later work, use the current brandbook rather than the older prompt seed.

## Plan78 scanner input and follow-up

| Option | Description | Selected |
|---|---|---|
| Stop with scanner and matrix unknowns unchanged | Safe, but leaves Plan78's named verification blocker without a bounded next step. | |
| Add a fresh local plan to validate and track the existing receipt-artifact helper, then rerun the blocked scanner-dependent checks | Addresses the recorded blocker with the smallest source boundary; only passing checks can refresh claims. | ✓ |
| Broaden into changing publisher workflows, final guards, or the scanner | Exceeds the demonstrated blocker without a named failing condition. | |

**Auto-selection:** The user asked the assistant to decide. Selected the recommended narrow local plan. The helper exists in the workspace but is untracked; its presence is not verification and it was left unchanged.

**Notes:** Plan78 remains halted until the blocked workflow-integrity checks are rerun. Keep unsupported response-row, material-binding, workflow-order, and final-guard claims UNKNOWN. REL-13/REL-17 remain OPEN, readiness BLOCKED, merge policy UNKNOWN, release hold ACTIVE, Plans175-45–175-48 HELD, and Phase175 INCOMPLETE. No network, CI, registry, tag, merge, or publication action is included.

## Plan79 matrix narrative wrapping contract — 2026-10-04

| Option | Description | Selected |
|---|---|---|
| Keep the raw-source single-line assertion | Strict about source layout, but a harmless Markdown soft break can fail despite unchanged prose. | |
| Normalize whitespace only in the explanatory prose assertion, then compare the full expected sentence | Preserves exact wording and punctuation while allowing presentation wrapping; no new dependency or parser. | ✓ |
| Parse or normalize the full matrix | Models broader Markdown structure but adds scope and can blur structured evidence boundaries. | |
| Force one-line prose | Avoids changing the assertion but makes source formatting serve the brittle test. | |

**User's choice:** The user asked for an exhaustive, recommendation-led consideration with useful subagent fan-out, then selected the coherent recommended option. The specific prose assertion may collapse whitespace within its bounded paragraph and compare the complete expected sentence; structured table values and evidence identifiers remain exact.

**Research:** Three independent read-only GSD advisor reviews covered assertion design, Elixir/CommonMark and maintainer DX, and release-evidence boundaries. They converged on a local whitespace-aware prose check. CommonMark permits a soft line break within a paragraph to render as a line ending or space, while GitHub renders ordinary paragraph line breaks continuously. Standard Elixir `Regex`/`String` functions and ExUnit assertions support a dependency-free implementation. A Markdown dependency, sidecar data format, global normalization, and UI work have no demonstrated payoff here. References: [CommonMark](https://spec.commonmark.org/0.31.2/#soft-line-breaks), [GitHub Markdown](https://docs.github.com/en/get-started/writing-on-github/getting-started-with-writing-and-formatting-on-github/basic-writing-and-formatting-syntax), [Elixir String](https://hexdocs.pm/elixir/String.html#replace/4), [Elixir Regex](https://hexdocs.pm/elixir/Regex.html), and [ExUnit assertions](https://hexdocs.pm/ex_unit/ExUnit.Assertions.html#assert/1).

**Planning handoff:** The user chose to update the existing CONTEXT.md and continue through replanning after this discussion. Plan79 remains halted and immutable. The next command is `$gsd-plan-phase 175 --ws quality-ratchet-release`; add a narrow follow-up and preserve completed evidence.

**Notes:** The post-update suite halted with 40 tests and 1 failure at the wrapped-prose assertion; the edits were restored. Do not change table statuses, row/column identity, scanner IDs, evidence references, or dispositions. Reapply only the restored Task 3 matrix/test edit. Rerun the exact post-update suite. Promote `workflow_presence_order` only when its named scanner checks and matching mutation/order assertions pass; update WINDOWS.md entry 36 only after the suite and dynamic ledger-count assertion pass. Otherwise keep entry 36 open and affected claims UNKNOWN. `final_guard_execution`, response-row and unsupported material/identity claims stay UNKNOWN; REL-13/REL-17 OPEN, readiness BLOCKED, merge-policy UNKNOWN, release hold ACTIVE, Plans45–48 held, and Phase175 incomplete. This discussion authorizes no remote/provider access, CI rerun, merge, Gate 2, recovery, registry action, or publication. No deferred ideas; no consumer UI, Phoenix/Plug endpoint, Ecto model, accessibility, or graphic-design work applies.

## REL-13/14/15 phase-goal coverage path — 2026-10-05

| Option | Description | Selected |
|---|---|---|
| Plan one fresh, bounded read-only readiness observation for the exact held core candidate | Determines whether current prerequisites have changed without rerunning CI or crossing a release boundary; still requires a fresh reviewed plan and exact read authorization. | ✓ |
| Stay local-only and leave the phase-goal coverage gap open | Avoids new observation work; the held live requirements remain without a current readiness refresh. | |

**User's choice:** Selected option 1. Plan a single fresh read-only readiness observation for the exact held core candidate (PR #219), subject to a separate reviewed plan, fresh exact read authorization, new attempt identity, and separate evidence paths.

**Notes:** This is planning scope only. If a required fact is blocked, mismatched, or unknown, stop without retry or candidate substitution. A ready snapshot does not satisfy REL-13/14/15 or authorize CI rerun, Gate 2, merge, recovery, registry action, tag write, or publication. Keep REL-13/14/15/17 OPEN, readiness BLOCKED, merge-policy UNKNOWN, release hold ACTIVE, Plans45–48 held, and Phase175 incomplete. Next command: `$gsd-plan-phase 175 --ws quality-ratchet-release`.

## Post-Plan82 terminal observation — 2026-10-05

**Area discussed:** Whether to act again after the exact-candidate anonymous observation ended `UNKNOWN/HTTP_UNAVAILABLE`.

| Option | Description | Selected |
|---|---|---|
| Wait for independent evidence | Keep the release held; resume only when a genuinely new, independently produced signal supplies current, decision-relevant facts for the same exact candidate. | ✓ |

**User's choice:** Wait for independent evidence.

**Notes:** Plan82's one-use attempt is terminal and must not be replayed. Its artifact contains no current CI/readiness snapshot; the unavailable result does not establish candidate readiness. Plan81's credential-unavailable stop is terminal; no credential setup or rotation is needed. The user-requested planning retry returned `PLANNING INCONCLUSIVE`; no Plan83 artifact was created and no provider, network, or CI call was made. Do not create another provider attempt solely to recover the unavailable response, substitute a candidate, or add a recurring CI lane for this one-time reconciliation. REL-13/14/15/17 remain OPEN, candidate readiness BLOCKED, merge-policy UNKNOWN, release hold ACTIVE, Plans45–48 held, and Phase175 incomplete. No CI rerun, Gate 2, merge, recovery, registry action, tag write, or publication is authorized. Any future provider observation requires a distinct discussion if a new decision is needed, a fresh reviewed plan, exact authorization, and unique attempt/evidence identity. No human UAT remains; checks and evidence evaluation stay automated.

## D-107 operational trigger research — 2026-10-05

| Path | Benefits | Tradeoffs | Recommendation |
|---|---|---|---|
| Replay Plan82, rotate credentials, or make another same-scope read | Could appear to resume quickly. | Reuses a consumed one-use boundary and produces no independent fact; credential fallback was not required by the anonymous read. | Reject. |
| Wait for a fresh exact-candidate receipt from existing `Crosswake CI` | Uses the recurring release-candidate proof already in CI; binds evidence to source identity and a complete run. | Current artifact retention is seven days; receipt is only a planning trigger, and other live release facts remain unobserved. | **Recommend under D-107.** Trigger only on a post-Plan82 natural run for the same PR #219 version/base/head/tree, with matching receipt run ID/attempt and passing complete roster, including iOS parity and aggregate. |
| Add a poller, new CI job, or scheduled workflow | Could seek provider state without a person checking in. | This is a one-time reconciliation; polling creates recurring noise and does not make ambiguous provider responses authoritative. A new job duplicates existing CI and can expand token permissions. | Reject; reconsider only if a recurring supported contract is demonstrated. |
| Add Mix status output, failure taxonomy, or telemetry | Could improve maintainers' local diagnosis. | Local state cannot establish current GitHub candidate facts; another status surface duplicates the canonical STATE/CONTEXT handoff. Plan82 intentionally retained no raw response details. | Reject for this incident; use closed allowlisted causes only if a recurring collector is later supported. |
| Ask for manual UAT or user credential setup | Could provide a direct human observation. | The relevant checks are machine-verifiable; no credential or behavior judgment is outstanding. | Reject; no user action is pending. |

**Decision status:** This operationalizes the user's existing D-107 selection; it does not replace it or authorize provider access. A qualifying receipt starts `$gsd-plan-phase 175 --ws quality-ratchet-release`; a fresh plan and exact authorization are still required before any remote read. No current qualifying receipt was found in local phase evidence. The old run `36438452825` failed iOS mirror parity and is stale. The seven-day artifact retention is a real maintainability tradeoff, but no evidence shows expiry caused this UNKNOWN result; defer retention changes to a separately scoped recurring-contract review. UI/consumer API/Elixir runtime design lenses do not apply to this maintainer-only release gate. See D-107 operational trigger in `175-CONTEXT.md`.

## D-107 resume signal observed — 2026-10-06

**Fresh signal:** In response to the user's instruction to keep Phase175 moving, an anonymous read of the public PR and checks pages plus exact public Git refs supplied current facts for the same candidate. The PR is open at the pinned head; its checks page references only run `36438452825`. Source tag `ios-core-v0.2.6` is present at the expected source OID. Mirror `main` and `v0.2.5` remain at the expected split, while the exact mirror `v0.2.6` query returns no ref. Sanitized evidence: `evidence/175-public-candidate-signal-20261006.json`.

**Decision status:** D-107's condition to resume planning is met by this independent tag/ref observation; a fresh passing CI receipt was not the only qualifying signal. This is not release readiness: current PR base, full check roster, CI receipt, and merge policy are still unverified. Preserve the release hold and do not retry Plan82, rerun CI, or write the tag before the reviewed plan's final authorization. The next GSD command is `$gsd-plan-phase 175 --ws quality-ratchet-release`; do not discuss Phase175 again. Research, patterns, and validation have been reconciled with the fresh observation.

## Post-Plan83 exact-candidate scope confirmation — 2026-10-06

Area: Current PR/base/head/tree scope. This was a fact refresh; prior implementation and release
decisions already cover every relevant ambiguity, so no new user choice was needed.

User's instruction: “evidence isnt going to exist itself. do it”

Finding: Two anonymous public GitHub REST reads confirmed PR #219 remains open with the pinned
base e51698528dc667ef89beb951e4eb1ec91da74981, head
696a27a3be1fcd56efe70923dc0ce286a1c41c6d, and tree
5279cae1daa1fbff3437b673df8ca231fb07c91f. The head commit's parent is the pinned base.
Evidence is recorded at evidence/175-public-candidate-scope-20261006.json.

Decision status: D-107's evidence trigger is satisfied for a fresh planning cycle only. The
release remains held; current checks, artifact, merge policy, tag policy, permissions and dry-run
remain unverified. No Plan83 replay or remote release action is authorized.

## Plan84 planning complete — exact next action (2026-10-06)

Plan84 provides a distinct mirror-tag repair path in GSD's effective Wave4. Independent review found no blockers; the
single authenticated dry-run is recorded in Task2 and is not repeated later. The plan requires an
already configured fixed-host helper, disables prompting, and stops UNKNOWN if authority is
unavailable. Missing or redirected Actions artifact evidence stays UNKNOWN/CI_BLOCKED. Automated
command-path, failure-direction, decision-coverage, and post-planning coverage checks pass. Plan84
is the sole incomplete, ready plan in effective Wave4; the other plans there have historical summaries. Plan45 is assigned effective Wave5 and depends on Plans74 and 84.

Exact next GSD command: `$gsd-execute-phase 175 --ws quality-ratchet-release --wave 4`. Last
completed phase: 174. Phase175 remains incomplete; REL-13/14/15/17 OPEN, readiness BLOCKED,
merge-policy UNKNOWN, release hold ACTIVE, and Plans45–48 HELD. No CI rerun, Gate2, merge, recovery,
registry mutation, or publication is authorized. Do not reopen discussion or repeat planning
unless new decision-changing evidence appears.
