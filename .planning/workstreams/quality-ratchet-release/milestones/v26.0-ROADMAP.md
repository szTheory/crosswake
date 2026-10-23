# Roadmap: Quality Ratchet & Release

## Milestones

- **v26.0 Harden Before Trust** — phases 184–188; in progress (roadmap created 2026-10-15); 18 requirements. Removes every v25 check that can pass while checking nothing, then runs the reference twin once more as twin-05 against the hardened commit. Product work happens in the `/private/tmp/crosswake-phase180-impl` candidate from `50fcd57`. [Requirements](REQUIREMENTS.md), [research](../../research/v26/SUMMARY.md).
- **v25.0 iOS Host Setup & Digital Twin Proof** — phases 179–183; planning closeout complete 2026-10-15; 20/20 requirements, 32 plans, 78 tasks; re-audit `tech_debt` with no blocker. Product code stays in the `/private/tmp` candidate pending a separately authorized delivery. [Archive](milestones/v25.0-ROADMAP.md).
- **v24.0 Repository Cleanup & Maintenance** — phases 176–178; planning closeout complete 2026-10-12; 8/8 requirements, 15 plans, 28 tasks; six retained debt records. [Archive](milestones/v24.0-ROADMAP.md).
- **v23.0 Release Pipeline Repair & Proof-Lane Truth** — phases 169–175, archived with exceptions 2026-10-11; 42/43 requirements; REL-10 breached. [Archive](milestones/v23.0-ROADMAP.md).
- **v22.0 Quality Ratchet & Release Readiness** — phases 164–168, archived with overrides 2026-09-15. [Archive](milestones/v22.0-ROADMAP.md).

## Phases

<details>
<summary>v25.0 iOS Host Setup & Digital Twin Proof (Phases 179–183) — planning closeout 2026-10-15</summary>

- [x] Phase 179: iOS Host Setup Without Hand Patches (4/4 plans) — completed 2026-10-13
- [x] Phase 180: Bounded Digital Twin Demonstration (7/7 plans) — completed 2026-10-15
- [x] Phase 181: Core Host-Command Seam (10/10 plans) — completed 2026-10-14
- [x] Phase 182: Loopback Origin for Local iOS Host (6/6 plans) — completed 2026-10-14
- [x] Phase 183: Close gap: twin source binding fails closed on uncommitted code (5/5 plans) — completed 2026-10-15

</details>

### v26.0 Harden Before Trust (Phases 184–188) — in progress

- [x] **Phase 184: Twin probe and safe preflight** - The twin's clean-tree check cannot be fooled by git index flags or config, and a read-only preflight can never consume a run root (completed 2026-10-16; 15/15 plans; fix(184-14) b898e110; verification passed 4/4 after four gap rounds)
- [x] **Phase 185: Checks that cannot pass empty** - The absence checker, v25 test loops and twin runtime helpers fail when they examine nothing (completed 2026-10-16)
- [x] **Phase 186: Host seam and harness honesty** - The legacy host-command path denies instead of granting everything, doctor stops passing on unreadable input, paths are redacted, and the loopback harness reports its own failures (completed 2026-10-16)
- [x] **Phase 187: Doctor and proof fidelity** - Doctor findings carry actionable details, the offline-island misconfiguration is flagged, proof provenance is real, and the A/D deferrals are recorded (completed 2026-10-16)
- [x] **Phase 188: Freeze and twin-05** - One frozen candidate commit, a scripted go/no-go, and exactly one twin-05 run with its result copied into planning (completed 2026-10-16)

## Phase Details

### Phase 184: Twin probe and safe preflight

**Goal**: The twin refuses any candidate whose tracked files differ from HEAD, however git is configured to hide the difference, and a maintainer can ask whether a run would be allowed without spending a run root.
**Depends on**: Nothing in v26 (continues from Phase 183; defines the gate the later phases and twin-05 rely on)
**Requirements**: PROBE-01, PROBE-02, PROBE-03, PROBE-04
**Success Criteria** (what must be TRUE):
  1. In real temporary git repos, an edit hidden by each of assume-unchanged, skip-worktree, `core.ignoreStat`, `core.checkStat=minimal`, `core.trustctime=false` and `core.filemode=false` (repo-local or global) produces a `source_dirty` block; untracked-file and exclude-rule fixtures also block; an untouched control passes; zero tracked entries or an unknown `ls-files -v` tag fails closed.
  2. `freeze`, `checked_identities` and `observe_identities` all run git through one shared configuration (filemode pinned, no global or system config, global excludes off, fsmonitor off, caller `GIT_*` variables scrubbed), proven by a test that fails if any call site bypasses it; a git failure, including a rejected argv, yields an `unavailable` cause whose message contains no path.
  3. The `source_dirty` message reports the flagged-entry count and the modified-file count separately and correctly, and a recorded mutation control shows each probe guard is load-bearing (reverting it makes a named test fail; a citation that runs 0 tests fails).
  4. Running the read-only twin preflight reports allowed or blocked with a cause, and afterwards no `receipt.json` exists, no run root was created or consumed, and a refused root leaves nothing behind, checked by directory listing before and after.

**Plans**: 12/15 plans complete (sequential waves 1-12; one working tree; feat(184-06) 1f5d18ee, fix(184-08) 3786de95, fix(184-10) b5399e51 and fix(184-12) e4344ca5 committed in the candidate); gap round 3 executed; gap round 4 planned (waves 13-15)

Plans:
**Wave 1**
- [x] 184-01-PLAN.md — baselines, then the fresh-index probe with flagged/exclude counts, one git builder and a contained temp index (stat-cache, flag, mode and attribute fixture matrix)

**Wave 2** *(blocked on Wave 1 completion)*
- [x] 184-02-PLAN.md — hiding-config refusals (worktree redirect, filters, info/attributes) and fail-closed git parsing, version floor and path-free spawn failures

**Wave 3** *(blocked on Wave 2 completion)*
- [x] 184-03-PLAN.md — every twin git call on the builder (source_gate/3 split), separate counts in plain language, M+F+X measure in verify_twin

**Wave 4** *(blocked on Wave 3 completion)*
- [x] 184-04-PLAN.md — TwinRuntime check/1 + commit/1 split, run-root owner check, bind-and-release origin probe, same-causes table

**Wave 5** *(blocked on Wave 4 completion)*
- [x] 184-05-PLAN.md — read-only `mix crosswake.proof_lane.twin_preflight` task and TwinPreflight module, leaves-nothing listings, guide paragraph

**Wave 6** *(blocked on Wave 5 completion)*
- [x] 184-06-PLAN.md — full gates vs baseline, twenty-seven recorded mutation controls, single feat(184-06) candidate commit, real-candidate probe check

**Wave 7** *(gap closure for 184-REVIEW.md; blocked on Wave 6 completion)*
- [x] 184-07-PLAN.md — close review gaps in the working tree: core.hooksPath=/dev/null on every pinned git call (CR-01), uncommitted ignore-all .gitignore counted (WR-01), no raise in source gate or preflight task (WR-02), precise temp-index/port wording (WR-03), root removal only of what was created (WR-04), WR-05 kept preflight-only per D-31, non-vacuous source test (IN-01), GIT_* prefix scrub and total spawn body (IN-02; orphan git on timeout deferred)

**Wave 8** *(blocked on Wave 7 completion)*
- [x] 184-08-PLAN.md — full gates vs baseline, thirteen recorded mutation controls, single fix(184-08) candidate commit on 1f5d18ee, full-copy and real-candidate probe checks

**Wave 9** *(gap closure round 2 for 184-REVIEW-GAPS.md; blocked on Wave 8 completion)*
- [x] 184-09-PLAN.md — exact ignore-rule parsing and trust (D-35): check-ignore -z via a private stdin file, NUL-only records bound to their paths, trust only the exact info/exclude git path or an exact tracked .gitignore, no folder collapsing; spoof tests proven red on 3786de95; guide sentence corrected; IN-02 dispositions (D-36)

**Wave 10** *(blocked on Wave 9 completion)*
- [x] 184-10-PLAN.md — full gates vs baseline, eleven recorded mutation controls (old code, plus each D-35 guard on its own), single fix(184-10) candidate commit on 3786de95, full-copy and real-candidate probe checks, gitlink evidence for D-36

**Wave 11** *(gap closure round 3 for 184-REVIEW-GAPS-2.md; blocked on Wave 10 completion)*
- [x] 184-11-PLAN.md — literal check-ignore paths (D-37): send ./ plus each entry and bind every answer to that exact text, so :deps, :(top)deps and : folders cannot borrow a committed rule; info/exclude counted, never trusted, with lines read as git reads them (D-38); 0600 input file; corrected docs and guide; real-git tests proven red on b5399e51

**Wave 12** *(blocked on Wave 11 completion)*
- [x] 184-12-PLAN.md — full gates vs baseline (full suite without MIX_BUILD_PATH), eighteen recorded mutation controls (earlier eleven, the b5399e51 code, each D-37/D-38 guard), single fix(184-12) candidate commit on b5399e51, full-copy and real-candidate probe checks, gitlink evidence

**Wave 13** *(gap closure round 4 for 184-REVIEW-GAPS-3.md; blocked on Wave 12 completion)*
- [x] 184-13-PLAN.md — (executed uncommitted 2026-10-15; run 1 blocked on a stale stderr test, plan amended with Step B2) any git stderr fails the call, so a folder git cannot open blocks instead of hiding files (D-39, GAP3-CR-01); git text files and settings read exactly as git reads them: ASCII-only trimming of info/attributes lines, LF-only splitting, git's own spellings of safe config values (D-40, GAP3-CR-02, GAP3-IN-01); real-git tests proven red on e4344ca5

**Wave 14** *(blocked on Wave 13 completion)*
- [x] 184-15-PLAN.md — (executed uncommitted 2026-10-15; TMPDIR case-insensitive; real-candidate tripwire clean) every git call pins core.ignorecase=false rather than refusing it, because macOS sets it to true (D-41, GAP3-WR-01); real-candidate tripwire; recorded TMPDIR case-sensitivity; guide wording pinned by a guide test (D-42, GAP3-IN-02); D-39..D-42 and GAP3 disposition rows recorded

**Wave 15** *(blocked on Wave 14 completion)*
- [x] 184-14-PLAN.md — (fix(184-14) b898e110 on e4344ca5; 27 mutation controls; full suite matches baseline) full gates vs baseline (full suite without MIX_BUILD_PATH), twenty-six recorded mutation controls plus control 0, single fix(184-14) candidate commit on e4344ca5, full-copy and real-candidate probe checks, GAP3 rows closed with the SHA

### Phase 185: Checks that cannot pass empty

**Goal**: Every v25-era check that iterates or scans fails loudly when its input is missing or empty, so a green result always means something was examined.
**Depends on**: Phase 184
**Requirements**: GUARD-01, GUARD-02, GUARD-03
**Success Criteria** (what must be TRUE):
  1. `script/check_absence_is_not_success.exs` exits non-zero for a nonexistent root, an empty derived scope and a scope below its pinned expected count; on success its OK lines print the counts scanned; red and green self-tests cover each case, using an Elixir copy of `assertFullScope` with no shared module or new dependency.
  2. The `twin_receipt_test.exs` loop (and every other v25 loop not covered by the ledger) asserts a non-empty collection before iterating, and a mutation control emptying the collection makes the test fail.
  3. A report-mode measurement table lists each v25 loop site and its disposition; no new repo-wide blocking rule is added unless that table shows zero findings.
  4. `TwinRuntime.stop_children/1` returns an error when its registry is already gone, and `lock_digests/1` fails closed unless both expected lockfiles are digested, each proven by a test that fails when the fix is reverted.

**Plans**: 5/5 plans complete (waves 1-3; one shared working tree; one candidate commit at the end)

Plans:
**Wave 1**
- [x] 185-01-PLAN.md — absence checker: strict invocation (exit 2), pinned @scopes with two independent derivations and an Elixir assertFullScope copy, counts in the OK lines, red/green subprocess self-tests, SEED-023 note (GUARD-01)
- [x] 185-02-PLAN.md — `stop_children`/`stop_all` report `registry_gone` without a race; callers' discard pinned by a source test and a verdict test (GUARD-03)
- [x] 185-03-PLAN.md — one-off AST scan of the 45 v25 test files, floors on every runtime-derived needs-fix loop (incl. `twin_receipt_test:289` roster count), report-mode `185-LOOP-MEASUREMENT.md` (GUARD-02)

**Wave 2**
- [x] 185-04-PLAN.md — all three lockfile sites require both lockfiles (`identity_unknown`), fixture fallout, `verify_twin_test` :582/:640 floors (GUARD-03, GUARD-02)

**Wave 3**
- [x] 185-05-PLAN.md — gates against the 184 baseline, display-only ledger drift, control 0 plus 19 numbered controls (17 mutation, 2 negative; 20 log lines), HEAD-copy probe, the single `fix(185)` candidate commit

### Phase 186: Host seam and harness honesty

**Goal**: The host-command seam denies rather than silently grants, doctor reports instead of passing when it cannot read its inputs, no output leaks a home path, and the loopback harness cannot report a pass after its own failure.
**Depends on**: Phase 184 (lands its `doctor.ex` edits before Phase 187)
**Requirements**: SEAM-07, SEAM-08, SEAM-09, LOOP-06, LOOP-07
**Success Criteria** (what must be TRUE):
  1. A legacy-shaped manifest fixture (route with no `host_commands` key) makes the native session deny each registered `host.*` command with the existing `not_registered` or `version_unsupported` reason; doctor reports the legacy manifest with a repair hint, the guide explains it, and manifest schema 1.2.0 and the public API are unchanged.
  2. Doctor's `host_commands_stale` reports an error for an unreadable fixture, a malformed fixture, and a router route declaring host commands that is missing from the manifest, while an absent fixture is still reported as skipped.
  3. A sentinel-directory test shows doctor output, gate messages, raised exception text and evidence files carry only project-relative paths (no absolute home path or username), through one copied redaction helper; the guide's version wording matches the code's floor semantics.
  4. Broken-state shims make `script/verify_loopback_origin_simulator.sh` exit non-zero when its hash check does not cover the swapped file, when evidence writing fails, and when uninstall or device restore fails; the harness is documented as manually run phase evidence, not a required CI lane.
  5. A regression test proves physical-iPhone proof preparation refuses a host generated in local loopback mode; preflight code is added only if that test shows the existing generator refusal does not cover it.

**Plans**: 5/5 plans complete (sequential, waves 1-5)

Plans:
**Wave 1**
- [x] 186-01-PLAN.md — doctor stale/legacy/skipped findings, ShellPackage.display_location/2 and the sentinel redaction suite (all Phase 186 doctor.ex edits)

**Wave 2** *(blocked on Wave 1 completion)*
- [x] 186-02-PLAN.md — Swift legacy-route denial, Phase 180 G3 rewrite, upgrade/compatibility guides and CHANGELOG line

**Wave 3** *(blocked on Wave 2 completion)*
- [x] 186-03-PLAN.md — loopback harness: cleanup, full-tree hash and evidence checks proven by PATH shims; manual-evidence guide paragraph

**Wave 4** *(blocked on Wave 3 completion)*
- [x] 186-04-PLAN.md — LOOP-07 regression test in all three modes (red first), preflight origin check only if red

**Wave 5** *(blocked on Wave 4 completion)*
- [x] 186-05-PLAN.md — full gates vs the Phase 185 baseline, 27 mutation controls, the single fix(186) commit, probe/preflight and home-path scan

### Phase 187: Doctor and proof fidelity

**Goal**: Doctor and proof evidence tell a maintainer exactly what is wrong and where it came from, and the deferred adopter requests are recorded so they are not re-argued.
**Depends on**: Phase 184, Phase 186 (`doctor.ex` edit order)
**Requirements**: DOCTOR-01, DOCTOR-02, DOCTOR-03, DOCTOR-04
**Success Criteria** (what must be TRUE):
  1. `mix crosswake.doctor --format json` emits the unmanaged route paths and router as structured `details` on the `unmanaged_routes` finding, asserted by a test on the JSON output.
  2. Doctor flags every `:offline_island` route declared `offline: :local_first` without an `island_contract` (no longer filtered out before the check), and reports "not claimed" when no route claims offline behavior; the compile-time rule is recorded as deferred with its reopen trigger.
  3. The `verify_navigation_shell` provenance header carries the real crosswake version, generated template version, `git rev-parse HEAD` and device class, with explicit sentinels for unknown values; the evidence validator rejects an all-zero commit reference, proven by a negative fixture.
  4. The CW-REQ-A and CW-REQ-D deferrals are recorded with evidence and reopen triggers, and CW-REQ-A records both readings of its pipeline trigger.

**Plans**: 7/7 plans complete (6 waves; candidate plans run one at a time because they share one compiled tree)

Plans:
**Wave 1**
- [x] 187-01-PLAN.md — doctor: unmanaged_routes details, the offline-island filter hole as an error, not_claimed advisory, CHANGELOG and guide lines (all Phase 187 doctor.ex edits)
- [x] 187-04-PLAN.md — 187-DEFERRALS.md (CW-REQ-A both readings, CW-REQ-D, compile-time rule, D-09 gaps) with SEED-014 and REQUIREMENTS pointers (planning files only)

**Wave 2** *(blocked on 187-01)*
- [x] 187-02-PLAN.md — evidence validator: all-zero commit rejected, exact sentinels, provenance_known?/1, physical and promotion blocks

**Wave 3** *(blocked on 187-02)*
- [x] 187-03-PLAN.md — Provenance reader (git, app version, host manifest template version) wired into verify_navigation_shell

**Wave 4** *(blocked on 187-03)*
- [x] 187-05-PLAN.md — loopback harness refuses an empty or bare --evidence (186 WR-03, recorded deviation before Phase 188)

**Wave 5** *(blocked on all)*
- [x] 187-06-PLAN.md — full gates vs the Phase 186 baseline and 25 mutation controls on the uncommitted tree (evidence only, no commit)

**Wave 6** *(blocked on 187-06)*
- [x] 187-07-PLAN.md — the single fix(187) commit on bd294007, post-commit probe, history manifest 87 OK, home-path/username scan and validation statuses

### Phase 188: Freeze and twin-05

**Goal**: The hardened code is frozen in one candidate commit and proven by exactly one twin-05 run whose result, pass or fail, is preserved honestly.
**Depends on**: Phase 184, Phase 185, Phase 186, Phase 187
**Requirements**: TWIN-07, TWIN-08
**Success Criteria** (what must be TRUE):
  1. All v26 code changes sit in one frozen candidate commit; a scripted refresh updates the seam and loopback handoff records; no later commit changes twin-attested source, and twin-01 through twin-04 records remain byte-unchanged.
  2. Immediately before the run, the read-only preflight and a scripted go/no-go both pass: frozen HEAD, clean probe, matching digests, and a 0700 `twin-05` root with no `receipt.json`.
  3. twin-05 is run exactly once and exits 0 with all ten groups and all seven identity joins passing; its result is byte-copied into planning and lists the disclosed fidelity limits (edit-and-revert during a run, ignored files not counted, Phase 179 identity join deferred).
  4. If twin-05 fails, a privacy-safe cause is recorded and no retry to green occurs; any further run is recorded as a new decision.

**Plans**: 5/5 plans complete

Plans:
**Wave 1**
- [x] 188-01-PLAN.md — run-once-05.sh (go/no-go with a 45-minute self-stop, read-only preflight, noclobber sentinel, one verify_twin with MIX_BUILD_PATH/DATABASE_PATH unset; a no-go is re-gatable, the sentinel is the one-way door) and its 31-control selftest; tracer first
- [x] 188-02-PLAN.md — freeze-check-188.sh, make-identity-188.sh and refresh-handoffs-188.sh with 18 refusal/idempotency controls (throwaway repos only)
- [x] 188-03-PLAN.md — assert-twin-05.sh (10 groups, 7 joins, 49 unique observations, 5 limits, receipt digest) and scan-privacy-188.sh with 37 controls

**Wave 2** *(blocked on 188-01, 188-02, 188-03)*
- [x] 188-04-PLAN.md — freeze at a53fbef (D-02 record), prepared record, identity, handoff refresh between two 87-OK manifest checks, script copies with sha256, early privacy scan

**Wave 3** *(blocked on 188-04)*
- [x] 188-05-PLAN.md — pre-create the 0700 root, run twin-05 exactly once, assert and byte-copy the result, limits sidecar, planning-bound privacy scan, and the handoff (SUMMARY on pass, BLOCKED on a gate no-go or any non-pass)

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 184. Twin probe and safe preflight | 15/15 | Complete (verification passed 4/4; fix(184-14) b898e110) | 2026-10-16 |
| 185. Checks that cannot pass empty | 5/5 | Complete    | 2026-10-16 |
| 186. Host seam and harness honesty | 5/5 | Complete    | 2026-10-16 |
| 187. Doctor and proof fidelity | 7/7 | Complete    | 2026-10-16 |
| 188. Freeze and twin-05 | 5/5 | Complete    | 2026-10-16 |

## Exact Next Action

Next: `$gsd-complete-milestone v26.0 --ws quality-ratchet-release`. The milestone audit ran on 2026-10-16: status tech_debt, 18/18 requirements, no blocker ([report](../../v26.0-MILESTONE-AUDIT.md)).

Phase 188 executed 2026-10-16: twin-05 ran once behind a gate whose 30 labels all passed, and it exited 0. All ten observation groups and all seven identity joins passed, and `assert-twin-05.sh` printed `assert: ok`. The result is byte-copied into [188-TWIN-RESULT.json](phases/188-freeze-and-twin-05/188-TWIN-RESULT.json), and the limits and open warnings are in [188-TWIN-RECORD.md](phases/188-freeze-and-twin-05/188-TWIN-RECORD.md). The candidate is unchanged at `a53fbef`. The candidate delivery gate stays open.

All product work happens in the `/private/tmp/crosswake-phase180-impl` candidate from `50fcd57`. Delivering candidate commits into the authoritative tree needs separate authorization. Recovery-checkout staging, commits, tags and branch/worktree changes remain prohibited. Adopter work stays parked on its recorded external gate.
