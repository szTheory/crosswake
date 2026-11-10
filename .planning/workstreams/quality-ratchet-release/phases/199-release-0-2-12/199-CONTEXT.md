# Phase 199: Release 0.2.12 - Context

**Gathered:** 2026-11-09 (autonomous mode; two scope decisions asked of the user, the rest carried from 199-DECISIONS.md)
**Status:** Ready for replanning of plans 13-19

<domain>
Phase 199 originally released 0.2.12 core-first behind per-step approvals, then proved and documented it.
Plans 01-12 executed. Plan 12 halted: 0.2.12 published but its iOS clean-room proof failed, so 0.2.13 (Phase 200)
and 0.2.14 (Phase 201) followed. 0.2.14 is the COMPLETE release (release run 42713010358; Hex, Maven, iOS mirror
v0.2.14; exact-public proof fully_proven for all six packages). Plans 13-19 still name 0.2.12 facts and must be
revised for current facts before they run.
</domain>

<decisions>
## Implementation Decisions

- **D-27 (user decision, 2026-11-09): SC5 and SC6 target 0.2.14.** Annotate SC5, SC6 and REL-07 so the REL-06 clean-room
  proof runs against the 0.2.14 Hex tarball (docs leg `deferred=none`, executing the `:ios_host` step), and the D-26
  "not in a published release yet" qualifiers are removed or reworded in the human PR that records 0.2.14 as published.
  The original sentences stay byte-identical as history; the annotation follows the REL-09 pattern. Wording is drafted
  by the planner and says so.
- **D-28 (user decision, 2026-11-09): release threadline 0.1.1 now.** Plans 13-14 are revised, not dropped: re-read
  PR 262's live head and CI first (its head moved after the plan was written), run the candidate preflight, merge
  with a merge commit pinned to the exact green head under the standing exception, then the companion tags and the
  Hex publish. Stop and report if the head is not green, the candidate preflight fails, or anything differs from the plan.
- **Standing approvals apply (AGENTS.md, BEARINGS invariant 4, committed by PR 284):** release-PR merge, release tags
  and Hex/Maven/iOS publishes need no per-step allow; each GitHub environment approval covers one step of one run. NOT
  covered, each needs its own user allow: any Maven fire-drill dispatch and any remote-branch deletion.
- All earlier decisions in 199-DECISIONS.md (D-01..D-26) stand unless a decision above supersedes them; gate-protocol
  decisions are replaced for post-0.2.13 releases by the standing approvals.
- Privacy: run the privacy scan before any push and rescan after any new commit. Planning evidence reaches main only
  by the 201-08 route (Route B, home-prefix redaction on landing copies). The docs branch `docs/199-release-0-2-12` is
  never pushed; trailing docs commits (including 201-08's, TODO-013 and TODO-014, and the Phase 201 verification) land
  with the Phase 199 closeout PR.

## Folded-in follow-ups to consider (planner decides placement, user not needed)
- TODO-013 (record-ledger drops its line when another ledger PR is open): a threadline-only release run is not a linked
  release, so `exact-public-proof` and its `record-ledger` job do not run and no ledger line is expected (corrected
  2026-11-09 at plan revision; the earlier wording assumed a record step in the companion run). Plan 14 records the open
  ledger PR count before the merge and the ledger outcome after the run, and carries any line a ledger job did produce to
  the 199-19 closeout PR.
- TODO-014 (Phase 201 review hardening) is independent and may stay out of this phase.
</decisions>

<canonical_refs>
- .planning/workstreams/quality-ratchet-release/phases/199-release-0-2-12/199-DECISIONS.md
- .planning/workstreams/quality-ratchet-release/phases/201-fix-the-exact-public-companion-digest-proof-so-a-release-run/201-08-SUMMARY.md
- .planning/workstreams/quality-ratchet-release/phases/201-fix-the-exact-public-companion-digest-proof-so-a-release-run/201-VERIFICATION.md
- .planning/workstreams/quality-ratchet-release/STATE.md (Exact Next Action, open items)
- .planning/workstreams/quality-ratchet-release/ROADMAP.md (Phase 199, SC1-SC6 with the 2026-11-09 annotations)
- AGENTS.md, .planning/BEARINGS.md
</canonical_refs>

<deferred>
Hex retire of 0.2.12 (undecided, not recommended); PR 262 is the only companion release in scope; PR 279 (collateral refresh) and release PR 288 are out of scope.
</deferred>
