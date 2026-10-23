# Roadmap: Quality Ratchet & Release

## Milestones

- **v23.0 Release Pipeline Repair & Proof-Lane Truth** — phases 169–175, archived with exceptions 2026-10-11; 42/43 requirements; REL-10 breached. [Archive](milestones/v23.0-ROADMAP.md).
- **v22.0 Quality Ratchet & Release Readiness** — phases 164–168, archived with overrides 2026-09-15. [Archive](milestones/v22.0-ROADMAP.md).

## v24.0 Repository Cleanup & Maintenance

**Status:** All three phases complete; 8/8 requirements verified. Milestone audit complete with six retained debt items and no blockers; scoped closeout review next.
**Goal:** Leave a maintainable repository with explicit dispositions for leftover work and open GitHub items, then prove the final source from a clean checkout.
**Scope:** Eight requirements, SEED-012 included, ecosystem research skipped. Numbering continues after archived Phase 175.

- [x] **Phase 176: Local Work and Artifact Disposition** — classify leftover changes and preserve unique work.
- [x] **Phase 177: Maintenance and Queue Reconciliation** — retire proven obsolete code, correct instructions and give open items concrete next actions. (completed 2026-10-12)
- [x] **Phase 178: Clean Checkout and Final CI** — verify the final source using existing repository and CI gates. (completed 2026-10-12)

## Phase Details

### Phase 176: Local Work and Artifact Disposition

**Goal:** Maintainer can account for every leftover change and recover unique work before cleanup.
**Depends on:** v23.0 archive; no release rerun.
**Requirements:** MAINT-01, MAINT-02, MAINT-04
**Success criteria:**
1. A dated inventory covers all tracked modifications and non-ignored untracked files, identifies the inspected checkout and compared merged commits, and explicitly reports any unreadable or unclassified path.
2. Every inventory row has a disposition: retain, already merged, ship as bounded maintenance, preserve outside the working source, or remove as proven transient. Unique bytes are recoverable before removal; retained historical records keep their verdicts.
3. Generated contracts name their canonical source and regeneration command, while temporary residue follows the existing artifact policy. No blanket deletion or unexplained local change is used to obtain a clean status.

**Plans:** 2 plans across 2 sequential waves; independent checker passed. Execution progress is recorded below.
**Wave 1**
- [x] 176-01-PLAN.md — Prove byte-safe capture, private restoration and sanitized evidence with real Git fixtures.

**Wave 2** *(Wave 1 complete; private storage qualified)*
- [x] 176-02-PLAN.md — Inventory the live checkout, verify recovery, compare merged source and record dispositions and generated-contract ownership.

**Context:** `phases/176-local-work-and-artifact-disposition/176-CONTEXT.md` — complete inventory and disposition, durable private recovery with restore evidence, existing artifact policy; recovery-checkout deletion is not required. No execution or requirement completion is claimed.

**Planning result:** Implementation research, pattern map and draft validation strategy support six tasks. All 23 locked decisions and MAINT-01/02/04 are covered. Durable private storage remains an execution-time precondition; temporary copies cannot satisfy recovery. The final audit follows all scoped GSD writers, accepts passing automated UAT results, and protects historical bytes in state and roadmap updates. No source cleanup or Git mutation is planned in the recovery checkout.

### Phase 177: Maintenance and Queue Reconciliation

**Goal:** Supported maintenance paths remain usable, and the maintainer has a concrete action for each open GitHub item.
**Depends on:** Phase 176
**Requirements:** MAINT-03, MAINT-05, MAINT-06
**Success criteria:**
1. Each retired release path has documented replacement and caller checks, including dynamic entry points where relevant; uncertain candidates remain retained with a stated reason. Supported release behavior and fail-closed guards remain covered by existing proof.
2. A dated GitHub inventory accounts for every open PR and issue with one disposition and next action. Release proposals are identified explicitly; no publication is triggered by queue cleanup.
3. Active maintenance instructions resolve to supported commands and paths. Historical phase artifacts, failed release attempts and the REL-10 breach remain unchanged in meaning.

**Plans:** 8/8 plans complete, 16 tasks across 6 waves; independent verification passed 27/27.
**Wave 1**
- [x] 177-01-PLAN.md
- [x] 177-04-PLAN.md
- [x] 177-06-PLAN.md

**Wave 2** *(blocked on Wave 1 completion)*
- [x] 177-08-PLAN.md

**Wave 3** *(blocked on Wave 2 completion)*
- [x] 177-02-PLAN.md

**Wave 4** *(complete)*
- [x] 177-03-PLAN.md

**Wave 5** *(blocked on Wave 4 completion)*
- [x] 177-05-PLAN.md

**Wave 6** *(blocked on Wave 5 completion)*
- [x] 177-07-PLAN.md

### Phase 178: Clean Checkout and Final CI

**Goal:** Maintainer can reproduce verification of the final source without relying on the dirty recovery checkout.
**Depends on:** Phase 177
**Requirements:** MAINT-07, MAINT-08
**Success criteria:**
1. The existing complete repository verification command runs from an exact clean source commit with prerequisites, stage results and before/after Git status recorded. Missing required tooling or skipped required stages cannot count as a pass.
2. The approved final source commit has green CI, with its commit identity, run and required check results recorded. No older green run is substituted for the final commit.
3. Local verification and hosted CI agree on the source under review; every failure is fixed or explicitly blocks completion. One-time reconciliation remains phase evidence rather than a new permanent workflow lane.

**Plans:** 5/5 plans complete across 4 waves; independent verification passed 18/18, with 25/25 locked decisions honored.

**Wave 1**
- [x] 178-01-PLAN.md — exact eight-file local candidate under the execution refinement and independent clean proof clone.

**Wave 2** *(blocked on Wave 1 completion)*
- [x] 178-02-PLAN.md — complete retained preliminary local verifier proof.
- [x] 178-03-PLAN.md — current CI graph/policy and checkout evidence collector.

**Wave 3** *(blocked on Wave 2 completion)*
- [x] 178-04-PLAN.md — concrete non-release proposal and scoped delivery authority.

**Wave 4** *(complete)*
- [x] 178-05-PLAN.md — observed runner commit, full local rerun and final source join.

**Execution refinement:** Final delta is eight files: six maintenance edits and two derived assertion snapshots; original planning intent/history remains retained.

**Cross-cutting constraints:** Preserve recovery source/index/HEAD/branch/worktrees and all 119 captured rows/private material. Use immutable candidate binding and disjoint private Wave-2 handoffs. Complete existing nine-result verifier and current governed CI must agree on the exact observed commit; head-only proof remains separate. No merge, release, publication, archive retirement or adopter promotion is selected.

**Context:** `phases/178-clean-checkout-and-final-ci/178-CONTEXT.md` — decisions carried into five independently checked plans. MAINT-07/08 are complete: local 9/9 and current hosted 48 required checks agree on f2d8875ee52d9679157c73b4a701b510ee612cb8.

## Progress

| Phase | Plans Complete | Status | Completed |
|---|---|---|---|
| 176. Local Work and Artifact Disposition | 2/2 | Complete    | 2026-10-11 |
| 177. Maintenance and Queue Reconciliation | 8/8 | Complete    | 2026-10-12 |
| 178. Clean Checkout and Final CI | 5/5 | Complete    | 2026-10-12 |

**Coverage:** 8/8 requirements mapped exactly once; no unmapped requirements.

## Exact Next Action

`$gsd-complete-milestone v24.0 --ws quality-ratchet-release`

Last completed phase 178: 5/5 plans and 18/18 verification. The [v24.0 audit](v24.0-MILESTONE-AUDIT.md) covers 8/8 requirements, 3/3 phases, 6/6 integration connections and 5/5 flows. No critical gap remains; six retained debt items need a disposition during closeout. The current audit queue accounts for 20 issues and 4 PRs. PR #238 remains open and unmerged, and its delivery binding is consumed. All original phase artifacts, recovery source/index/HEAD/branch/worktrees and historical records remain preserved.

Prepare scoped milestone closeout under the existing recovery-checkout restriction: no staging, commits, branches/worktrees or tags here. The audit has not authorized archive movement, retirement, remote merge or publication. Do not repeat Phase178 or the completed audit and do not redeliver the consumed proposal. The adopter workstream remains parked on its recorded external gate.
