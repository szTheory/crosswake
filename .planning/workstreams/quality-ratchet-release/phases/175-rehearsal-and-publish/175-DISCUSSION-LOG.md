# Phase 175: Rehearsal and Publish - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-18
**Phase:** 175-rehearsal-and-publish
**Areas discussed:** Fire-drill companion pick, Human checkpoints on the one-way doors, Runbook + failure-table shape, Wave 0 triage depth

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
