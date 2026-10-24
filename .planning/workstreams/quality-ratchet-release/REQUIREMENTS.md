# Requirements: v27.0 Land and Clean Up (Phases 189–193) — in progress

**Defined:** 2026-10-16
**Workstream:** quality-ratchet-release
**Core value:** one real Phoenix application on one physical iPhone, with explicit route ownership and one honest offline mutation island.

**Scope.** On 2026-10-16 the user chose to land the v25 and v26 work on mainline, get `main` CI green, and clean up the local repository so no milestone of code can be lost. Their decisions:
- The recommended scope, with SEED-012 (repository hygiene closeout).
- The recovery-checkout protection lifts at cleanup, once everything in that checkout is accounted for and backed up.
- 186 WR-01 is resolved as "refuse".
- Outside research is skipped; Phase 189's inventory replaces it.

See [v27.0-SCOPE.md](v27.0-SCOPE.md). The v26 requirements are archived in [milestones/v26.0-REQUIREMENTS.md](milestones/v26.0-REQUIREMENTS.md).

**Starting facts (2026-10-16).**
- The candidate `/private/tmp/crosswake-phase180-impl` is at `a53fbef` (tree `f7c4d7dc`): 90 commits ahead of GitHub `main` `d0dbdf7` and 0 behind.
- A verified git bundle of the candidate is kept outside `/private/tmp`.
- `main` CI is green at `d0dbdf7`.
- The recovery checkout is at `d0f3e2f1` and holds:
  - 58 modified and 62 untracked paths, including 73 outside `.planning/`;
  - 4 stashes and 56 local branches.
- Two extra worktrees exist.

## v27.0 Requirements

### INV: account for every copy of the work

- [x] **INV-01:** One inventory lists every place that holds work not on GitHub `main`, and classifies each item as *on main*, *to land*, *obsolete* or *unclassified* (backed up; the user decides it before anything is removed, per D-06), with a reason. Classification compares content with `main`, not names. The places covered:
  - the candidate's commits;
  - the recovery checkout's uncommitted code and planning files;
  - stashes, extra worktrees and local branches;
  - the other `/private/tmp` clones.
- [x] **INV-02:** Before anything is removed, every item classified *to land*, or not yet classified, has a backup outside `/private/tmp`. A restore test shows that each backup reproduces the item exactly.
- [x] **INV-03:** Each open PR has a recorded disposition: merge, close, redo after landing, or hold (release PR #236, per D-13). The PRs are #238, the release PR #236, and the dependabot PRs #210, #211 and #239–#241.

### FIX: warnings fixed before landing

- [ ] **FIX-01:** A privacy scan whose scope contains no files fails with a scope error instead of passing (188 WR-01).
- [ ] **FIX-02:** Every gate label has at least one self-test case that makes it fail (188 WR-08).
- [ ] **FIX-03:** The run gate's shell git helper uses the same pinned configuration as the shared Elixir git funnel.
- [ ] **FIX-04:** A registry read timeout is reported as a timeout. Stopping all children never stops a registry that is still alive (185 WR-02).
- [ ] **FIX-05:** For a nested host folder with no `.git` of its own, provenance never reports the enclosing repository's commit (187 WR-02).
- [ ] **FIX-06:** The guard's minimum test-file count equals the real count at landing.
- [ ] **FIX-07:** The physical-iPhone preflight refuses with a clear reason when `Info.plist` is unreadable or `route_activation.json` is malformed (186 WR-01; owner decision: refuse).

### LAND: get it onto main

- [x] **LAND-01:** An integration branch cut from current GitHub `main` carries:
  - the candidate's commits, with history preserved;
  - the FIX commits;
  - the v24–v27 planning records.

  A privacy scan of the change finds no home paths, usernames, secrets or adopter identity.
- [x] **LAND-02:** The full local suite passes on the integration branch. Each known pre-existing failure is either fixed or listed with a reason; none is excluded silently. The known failures are Swift G4 and example-host G2/G6.
- [x] **LAND-03:** A PR to `main` is open and every required CI check passes.
- [x] **LAND-04:** The merge happens only after the user answers `allow` for the displayed PR and head commit. After the merge, CI on `main` is green for the merge commit.

### CLEAN: leave a clean local setup

- [ ] **CLEAN-01:** After landing, the recovery checkout is retired and replaced by a clean `main` checkout. This happens only after its *to land* work is on `main` and everything else is backed up.
- [ ] **CLEAN-02:** Landed or obsolete stashes, extra worktrees and local branches are removed after backup. Anything that remains has a stated reason.
- [ ] **CLEAN-03:** A final check shows all of the following:
  - the `main` checkout's `git status` is clean;
  - `main` CI is green;
  - every open PR has a disposition;
  - no `/private/tmp` folder is the only copy of anything.
- [ ] **CLEAN-04:** AGENTS.md and the workstream STATE replace the "candidate in `/private/tmp`, frozen recovery checkout" rules with the normal flow: branch from `main`, then open a PR.

## Future Requirements

- Validate the Nyquist status of phases 184–188 (all VALIDATION.md files are still drafts).
- Address the remaining open review findings in the v26 debt disposition that FIX does not cover.

## Out of Scope

| Item | Reason |
|------|--------|
| New product features | This milestone lands and cleans; it adds nothing new |
| A twin-06 run | None of the FIX items needs a twin run; a run is a separate decision |
| Physical-iPhone run and adopter lane | These remain external gates |
| Android | Frozen by the governing ADR |
| Package release or Hex publish | Release PR #236 only gets a disposition; merging it is a separate decision |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| INV-01 | Phase 189 | Complete |
| INV-02 | Phase 189 | Complete |
| INV-03 | Phase 189 | Complete |
| FIX-01 | Phase 190 | Complete |
| FIX-02 | Phase 190 | Complete |
| FIX-03 | Phase 190 | Complete |
| FIX-04 | Phase 190 | Complete |
| FIX-05 | Phase 190 | Complete |
| FIX-06 | Phase 190 | Complete |
| FIX-07 | Phase 190 | Complete |
| LAND-01 | Phase 191 | Complete |
| LAND-02 | Phase 191 | Complete |
| LAND-03 | Phase 192 | Complete |
| LAND-04 | Phase 192 | Complete |
| CLEAN-01 | Phase 193 | Pending |
| CLEAN-02 | Phase 193 | Pending |
| CLEAN-03 | Phase 193 | Pending |
| CLEAN-04 | Phase 193 | Pending |

**Coverage:** 18/18 v1 requirements mapped to phases 189–193; no orphans, no duplicates.

---
*Requirements defined: 2026-10-16*
*Traceability filled: 2026-10-16 (v27.0 roadmap created)*
