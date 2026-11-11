---
phase: 199-release-0-2-12
verified: 2026-11-10T07:30:00Z
status: human_needed
score: 5/6 must-haves verified
covered_files:
  - .planning/workstreams/quality-ratchet-release/phases/199-release-0-2-12/199-01-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/199-release-0-2-12/199-01-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/199-release-0-2-12/199-02-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/199-release-0-2-12/199-02-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/199-release-0-2-12/199-03-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/199-release-0-2-12/199-03-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/199-release-0-2-12/199-04-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/199-release-0-2-12/199-04-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/199-release-0-2-12/199-05-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/199-release-0-2-12/199-05-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/199-release-0-2-12/199-06-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/199-release-0-2-12/199-06-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/199-release-0-2-12/199-07-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/199-release-0-2-12/199-07-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/199-release-0-2-12/199-08-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/199-release-0-2-12/199-08-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/199-release-0-2-12/199-09-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/199-release-0-2-12/199-09-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/199-release-0-2-12/199-10-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/199-release-0-2-12/199-10-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/199-release-0-2-12/199-11-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/199-release-0-2-12/199-11-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/199-release-0-2-12/199-12-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/199-release-0-2-12/199-12-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/199-release-0-2-12/199-13-BLOCKED.md
  - .planning/workstreams/quality-ratchet-release/phases/199-release-0-2-12/199-13-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/199-release-0-2-12/199-14-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/199-release-0-2-12/199-15-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/199-release-0-2-12/199-15-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/199-release-0-2-12/199-16-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/199-release-0-2-12/199-16-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/199-release-0-2-12/199-17-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/199-release-0-2-12/199-17-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/199-release-0-2-12/199-18-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/199-release-0-2-12/199-18-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/199-release-0-2-12/199-19-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/199-release-0-2-12/199-19-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/199-release-0-2-12/199-20-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/199-release-0-2-12/199-20-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/199-release-0-2-12/199-CONTEXT.md
  - .planning/workstreams/quality-ratchet-release/phases/199-release-0-2-12/199-DECISIONS.md
  - .planning/workstreams/quality-ratchet-release/phases/199-release-0-2-12/199-REVIEW-DISPOSITION.md
  - .planning/workstreams/quality-ratchet-release/phases/199-release-0-2-12/199-REVIEW.md
covered_digest: "v4:sha256:4d984ce90ebbba58207c894acc5d3b0e126e9bae9b4866ecd12c714df9515fbe"
behavior_unverified: 0
overrides_applied: 0
advisory:
  - finding: "Code review 199-REVIEW.md (0 critical, 1 warning, 4 info) is deferred in full to TODO-015: the rewritten changelog guard encodes a point-in-time fact (WR-01), the deleted unreleased_claim_qualifier_test leaves three hand-authored guides without a version check (IN-01), two test groups lean on refute or lack a positive control (IN-02, IN-03), and the guides say 'from 0.2.12 on' without naming 0.2.12's default iOS generation defect (IN-04)"
    category: other
    reason: "Advisory, recorded in 199-REVIEW-DISPOSITION.md; none of the findings falsifies a Success Criterion as amended"
    evidence_status: "recorded in 199-REVIEW.md and TODO-015"
coincidental_reliance_items: []
human_verification:
  - test: "Allow the local deletion of five branches (git branch -D chore/codex-model-profile chore/v27-milestone-close ci/199-release-gates docs/195-closeout fix/spec-structure-ratchet), each already preserved on origin as preserve/<name> with an equal tip; decide redact-and-squash or delete for docs/196-uat and docs/197-public-docs-truth; land the local docs/199-planning-closeout branch (the 199-20 summary, the SC4 annotation, the state and this report) by PR; then re-run bash script/bearings-report"
    expected: "script/bearings-report exits 0 with no UNVERIFIED line (SC4). At verification time it exits 1 (ATTENTION) in the main checkout and nothing here can change that without the user's allow and decision"
    why_human: "The permission system refused git branch -D for the five branches and the agent must not work around that; the two kept branches carry privacy-class hits in their history and need the user's redact-or-delete decision; both are trust actions, not checks an agent can run to green"
---

# Phase 199: Release 0.2.12 - Verification Report

**Phase Goal:** Users can install the next release from Hex, Maven and the iOS mirror, published core-first, with every irreversible step individually approved and verified after the fact. Amended by user decisions in `199-DECISIONS.md`: D-27 (SC5, SC6 and REL-07 target 0.2.14), D-29 (`land_and_retire`), D-30 (CI timeout fix forward once), D-31 (threadline 0.1.1 deferred; plans 199-13 and 199-14 superseded, never run), D-32 (REL-07 ticks on the core release alone with the deferral recorded).
**Verified:** 2026-11-10T07:30:00Z
**Status:** human_needed
**Re-verification:** No - initial verification

Code pin: the implementation and guides live on origin/main at merge commit 323227b5 (PR 293, CI green on exact head 2c722930). The main checkout is on the local branch `docs/199-planning-closeout` (two commits ahead of origin/main, unpushed), which holds the planning outputs. `covered_digest` covers this phase's planning files only; code was read with `git show origin/main:<path>` and run in a scratch worktree at 323227b5 (then removed by the caller, so the clean-room re-run used a copy of the script taken from origin/main). SUMMARY claims were not used as evidence.

## Verdict in one paragraph

Five of six Success Criteria hold against live state, judged as amended. SC4 (`script/bearings-report` exits 0 with no UNVERIFIED line at milestone close) is literally unmet today: I re-ran the report and it exits 1. It is not a code gap and not an accepted override. The shortfall is entirely a pending user allow (five local branch deletions the permission system refused) and a pending user decision (two branches kept for privacy hits), plus landing the local planning branch. So the status is `human_needed`, not `gaps_found` (a gap-closure plan cannot change it) and not `passed` (SC4's own check is red). REL-07 is correctly Complete in REQUIREMENTS.md on the amended basis.

## Goal Achievement

### Observable Truths

SC1 to SC6 from ROADMAP.md with every dated annotation, judged as amended.

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | SC1 (amended): the release-please PR is green on its exact head with zero hand edits and is merged under the recorded approvals; companion publish deferred (D-31) | VERIFIED | PR 283 is MERGED (merge commit dc6a8ed3, 2026-11-09T22:33:55Z) with exactly one commit, `chore: release main` (head 40739816). Crosswake CI run 42703531929 is `success` on headSha 40739816 (the exact head). `201-EVIDENCE/gates-201.txt` has a PASS `standing-rules` precheck, then one PASS `core-merge` precheck and exactly one `standing: core-merge ... merge_commit=dc6a8ed3 head=40739816` line; the Maven fire drill has one `decision: ... allow` and one `applied: ... validated_then_dropped`, all bound to head 40739816. The companion step is deferred by D-31 (`199-DECISIONS.md`) and restated in the ROADMAP SC1 annotation. |
| 2 | SC2 (amended): publishing runs core first, then Maven, then the iOS mirror, each tag and publish under its own recorded approval; versions visible on Hex and Maven; companion step deferred (D-31) | VERIFIED | Job timestamps of Release Please run 42713010358 (`Release Please` workflow, conclusion success, headSha dc6a8ed3): tag approval 22:36:26, Release Please 22:36:33, Publish to Hex 22:43:29 to 22:54:28, Publish Android core to Maven Central 22:55:51 to 22:59:01, Mirror iOS 23:09:25 to 23:11:31; the five companion publish jobs are `skipped`. `gates-201.txt` has one `standing:` line each for core-merge, core-tags, core-hex, core-maven and core-ios with one run id. Live: Hex API lists crosswake 0.2.14 first; Maven Central POM for `io.github.sztheory:crosswake-shell-core-android:0.2.14` returns HTTP 200. `gates-199.txt` has no `companion-` standing line. |
| 3 | SC3: a post-publish check asserts the iOS mirror tag equals the release version and fails on a mismatch | VERIFIED | `script/check_ios_mirror_release_tag.sh` at origin/main is wired at `.github/workflows/release-please.yml:1126` (job `release: ios mirror tag check`, success in the 0.2.14 run) and pinned by `script/check_release_workflow_integrity.exs:2028`. Live positive: `--version 0.2.14` printed `verdict=PASS` (mirror tag v0.2.14, mirror_tree equal to source_tree 75dcd5039028, newest v0.2.14). Live negative control: `--version 0.2.13` printed `verdict=FAIL reason=newer_mirror_tag`. `mix test test/crosswake/release_candidate/mirror_release_tag_test.exs`: 11 tests, 0 failures. |
| 4 | SC4: `script/bearings-report` exits 0 with no UNVERIFIED line at milestone close | NOT MET AT PHASE CLOSE, routed to human (see below) | Re-ran in the main checkout: rc 1, `BEARINGS: ATTENTION (3)`: `sync: ahead 1` (2 now, after the review commit), `ci: CI has not run on HEAD`, `local: worktrees 2, stashes 0, unlanded branches 8`. No UNVERIFIED line. The 199-20 record (`199-EVIDENCE/closeout-final-199.txt`) shows rc 1 with one item and 7 branches. `git branch --no-merged origin/main` lists exactly the seven named in the annotation plus `docs/199-planning-closeout` (the current branch). Each of the five preserved branches equals its `origin/preserve/<name>` tip (`git ls-remote` checked: MATCH for all five). |
| 5 | SC5 (amended): the REL-06 clean-room command reads README.md and guides/install.md from the 0.2.14 Hex tarball and its docs leg passes with `deferred=none`, executing the `:ios_host` step | VERIFIED | I re-ran `script/verify_published_cleanroom.sh 0.2.14` (script from origin/main) live: `leg hex PASS`, `leg maven PASS`, `leg ios PASS ... tag_commit 095267ea23c9`, `leg docs PASS 0.2.14 executed=20 not_applicable=0 deferred=none clone=4 shown=4 source=tarball`, `result PASS`, rc 0. An earlier attempt in the same session failed only the ios leg with `resolve_failed` (the `git ls-remote` of the mirror, a transient network read); a direct `git ls-remote` of `refs/tags/v0.2.14` then succeeded and the full re-run passed. The 0.2.14 tarball's `guides/install.md` carries `<!-- cleanroom:apply id=ios-host ... since=0.2.12 -->` at line 226 and the `:ios_host` config block. Recorded runs match: `cleanroom-0.2.14-199.txt`, `cleanroom-0.2.14-run1-199.txt`. |
| 6 | SC6 (amended): the D-26 "not in a published release yet" qualifiers on seven guides and the qualifier test are removed or reworded in the human PR that records 0.2.14 as published, with the two generated guides changed through their renderers | VERIFIED | PR 293 (MERGED, merge commit 323227b5, second parent equals CI head 2c722930) changes the seven guides, `lib/crosswake/capability_map/renderer.ex`, `lib/crosswake/support_matrix/renderer.ex` and `lib/crosswake/parity_ledger/renderer.ex`. At 323227b5: `test/crosswake/guides/unreleased_claim_qualifier_test.exs` is absent; a grep for "published release yet", "not yet published", "unpublished" and "not published" over `guides/`, the two renderers and README.md returns nothing; each reworded sentence names a release (for example `guides/support_matrix.md:47`, `guides/parity_ledger.md:12`, `guides/capability_map.md:10`: "from 0.2.12 on; 0.2.11 and earlier ..."), and the renderer sources carry the same sentences. `199-EVIDENCE/cleanroom-reader-audit-199.txt` shows the readers present in 0.2.12 and absent in 0.2.11. `mix crosswake.docs.sync --check` passed; `mix test test/crosswake/guides`: 242 tests, 0 failures (5 excluded). |

**Score:** 5/6 truths verified (SC4 routed to human verification; it is not FAILED because the shortfall is a withheld allow, and not VERIFIED because its check is red).

### SC4: gap, annotation or human_needed?

Precisely:

- **Literally unmet.** The criterion's own check, `bash script/bearings-report`, exits 1 today. A reader must not take the ROADMAP annotation as having met it.
- **Not a gap in the delivered work.** The criterion is scoped "at milestone close", and the milestone has not closed; no later phase in the roadmap (200 and 201 are done) schedules this, so Step 9b deferral does not apply either. No code or plan the agent can write turns it green: the five `git branch -D` calls were refused by the permission system (199-20 deviation 2, and the agent correctly did not route around it), and the two kept branches need a user decision.
- **A documented annotation, but not an accepted override.** The ROADMAP SC4 annotation (on the local branch only; origin/main does not have it yet) states the cause, the seven branches and the receiver. Its wording was drafted by the planner; the user has not accepted the deviation, so it cannot be recorded as `PASSED (override)` and `overrides_applied` stays 0.
- **human_needed.** The remaining actions are trust actions: the user's allow for five deletions, the user's redact-or-delete decision for `docs/196-uat` and `docs/197-public-docs-truth`. Then the agent re-runs the report.
- **One thing the annotation does not say.** In the live main checkout the report shows eight unlanded branches and `ahead 1` / `CI has not run on HEAD`, because `docs/199-planning-closeout` (the 199-20 summary, the SC4 annotation, the state, the review record and this report) is itself unpushed. Exit 0 therefore also needs that branch landed by PR (under the standing merge exception, CI green on the exact head), or the report is read from a main that contains it. 199-20's own record read ATTENTION (1) because it ran on main with the planning files uncommitted; the committed branch changes the count.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| REL-07 | 199-01 to 199-12, 199-15 to 199-20 (13 and 14 superseded under D-31) | A release (core first, then companions, Maven, iOS mirror) completes with a separate `allow` per merge, publish and tag; a post-publish check asserts the mirror tag equals the release version; amended for 0.2.14, the standing exceptions and the D-31 companion deferral | SATISFIED, on the amended basis | `REQUIREMENTS.md` line 32 is `[x]`, traceability line 104 reads `REL-07 | Phase 199 | Complete`, both on origin/main (PR 293) and on the local branch; the original sentence is unchanged and the amendments (D-04, D-02, 2026-11-09 and 2026-11-10 annotations, D-27, D-31 deferral, "Completed 2026-11-10") are appended. The live facts the amendment names hold: run 42713010358 is COMPLETE (every non-companion job success, exact-public proof success, linked release rollup success), mirror tag v0.2.14 equals the release version, REL-06 passes against the 0.2.14 tarball. REL-07 needs the companion deferral recorded, not performed, under D-32. REL-08 and REL-09 belong to Phase 200 and are Complete there; no orphaned REL requirement is mapped to Phase 199. |

### Plan Accounting

| Item | Status | Evidence |
|------|--------|----------|
| Plans 199-01 to 199-12, 199-15 to 199-20 (18) | executed | 18 SUMMARY files; statuses `complete` except 199-20 `complete_with_open_items`, which matches the SC4 finding |
| Plans 199-13, 199-14 | superseded, never run | Both PLAN frontmatters read `status: superseded`, `deferred_by: D-31`; 199-13 left `199-13-BLOCKED.md` (not a SUMMARY, so it does not read as done); no 199-13 or 199-14 SUMMARY exists; PR 290 (the one D-30 fix forward, merge 00f39995) is kept |
| D-29 land_and_retire | applied | Local `docs/199-release-0-2-12` no longer exists; `closeout-final-199.txt`: `equivalence: authored=267 equal=157 redacted_equal=38 raw_equal=72 gaps=0`, `docs_branch: action=deleted` |

### Required Artifacts and Key Links

| Artifact or link | Status | Details |
|------------------|--------|---------|
| `script/check_ios_mirror_release_tag.sh` called by `.github/workflows/release-please.yml:1126` | WIRED | job ran and passed in run 42713010358; also asserted by `check_release_workflow_integrity.exs` and `phase199_release_gates_test.exs` |
| `guides/*` rewordings to `lib/crosswake/{capability_map,support_matrix,parity_ledger}/renderer.ex` | WIRED | `mix crosswake.docs.sync --check` passed at 323227b5, so the generated guides equal their renderers |
| `script/verify_published_cleanroom.sh` `DOCS_IOS_HOST_SINCE="0.2.12"` and `DOCS_EXECUTED_FLOOR=18` | WIRED | live run executed 20 blocks with `deferred=none` |
| Closeout PR 293 to origin/main | WIRED | MERGED as 323227b5; `git rev-parse origin/main` equals 323227b5 at verification time |

### Data-Flow Trace (Level 4)

Not applicable: this phase renders no dynamic data. The release facts come from live registries, GitHub run records and the mirror, all read directly above.

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Mirror tag equals release version | `bash script/check_ios_mirror_release_tag.sh --version 0.2.14` | `verdict=PASS` | PASS |
| Mismatch is detected | same with `--version 0.2.13` | `verdict=FAIL reason=newer_mirror_tag` | PASS (negative control) |
| Mirror-tag tests | `mix test test/crosswake/release_candidate/mirror_release_tag_test.exs` | 11 tests, 0 failures | PASS |
| Guide tests | `mix test test/crosswake/guides` | 242 tests, 0 failures | PASS |
| Generated guides in sync | `mix crosswake.docs.sync --check` | passed | PASS |
| REL-06 clean-room against 0.2.14 | `CLEANROOM_ELIXIR_VERSION=1.19.5-otp-27 CLEANROOM_ERLANG_VERSION=27.3 bash script/verify_published_cleanroom.sh 0.2.14` | `result PASS`, docs `deferred=none`, rc 0 (one earlier run: ios leg transient `resolve_failed` on the mirror read, not reproduced) | PASS |
| Bearings | `bash script/bearings-report` (main checkout) | rc 1, ATTENTION (3), no UNVERIFIED | NOT MET (SC4) |

### Probe Execution

No `probe-*.sh` is declared for this phase. Skipped.

### Anti-Patterns Found

None blocking. The phase's changed files are planning records, evidence, guides, renderers and tests merged by PR 293; no TBD, FIXME or XXX scan finding was raised in the evidence records and the review (`199-REVIEW.md`) found 0 critical issues. Advisory items are in the frontmatter (TODO-015).

### Human Verification Required

#### 1. Clear SC4: branch cleanup and landing

**Test:** (a) Allow `git branch -D chore/codex-model-profile chore/v27-milestone-close ci/199-release-gates docs/195-closeout fix/spec-structure-ratchet` (each tip equals its `origin/preserve/<name>` ref). (b) Decide redact-and-squash or delete for `docs/196-uat` and `docs/197-public-docs-truth`; their history, not their final files, has privacy-class hits and neither was pushed as `preserve/`. (c) Land `docs/199-planning-closeout` by PR so main carries the SC4 annotation, the 199-20 summary and this report. (d) Re-run `bash script/bearings-report`.
**Expected:** exit 0, no UNVERIFIED line. If it still exits 1, the annotation's "checked again once each item is landed, preserved or removed" applies.
**Why human:** the permission system refused the five deletions and the agent must not bypass it; the two privacy branches need the user's redact-or-delete choice; neither is a check an agent can make pass.

Not asked of the human: the release itself (done), REL-06 (re-run green), SC3 (re-run green).

### Other Notes for the Caller (not gaps)

- Threadline 0.1.1 stays deferred under D-31; its reopening condition is Release Please recreating the threadline release PR from a main that includes the 30-minute CI bound (PR 290) with CI green on its exact head, then a new plan. Closed PR 262 is not a failure of this phase.
- Thirty-odd remote branches remain (listed in `closeout-final-199.txt`, `remote_branch_left:`), each needing the user's own allow to delete; the bearings report does not count them.
- 0.2.12 and 0.2.13 are permanent, recorded as published and superseded (PARTIAL and FAILURE runs); the guides name 0.2.12 as the first release carrying the claims, which is true of the tarballs but not of 0.2.12's default iOS generation (review IN-04, advisory).

### Gaps Summary

No gaps. One criterion (SC4) is open and waits on the user: see Human Verification Required.

---

_Verified: 2026-11-10T07:30:00Z_
_Verifier: Claude (gsd-verifier)_
