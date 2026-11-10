---
phase: "201"
slug: "fix-the-exact-public-companion-digest-proof-so-a-release-run"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
status: validated
nyquist_compliant: false
wave_0_complete: true
created: "2026-11-09"
---

# Phase 201 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Source: `201-RESEARCH.md` § Validation Architecture.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.19.5) |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/crosswake/release_candidate/artifact_test.exs test/crosswake/release_candidate/cleanroom_test.exs test/crosswake/release_candidate/artifact_real_tarball_test.exs` |
| **Full suite command** | `mix test test/crosswake/release_candidate/ test/crosswake/proof/phase172_per_package_ref_test.exs`, then `mix test --exclude requires_example_host --exclude advisory_only` |
| **Estimated runtime** | ~1 s quick, minutes for the hermetic suite |

Run each command on its own and read the exit status. Never pipe a gate into `tail` or `head`.

---

## Sampling Rate

- **After every task commit:** the quick run command
- **After every plan wave:** `mix test test/crosswake/release_candidate/ test/crosswake/proof/phase172_per_package_ref_test.exs` plus `elixir script/check_absence_is_not_success.exs`, `elixir script/check_exunit_ownership.exs`, `mix test test/crosswake/proof/phase170_vacuous_assertion_ledger_test.exs`
- **Before `/gsd-verify-work`:** hermetic full suite green and PR CI green on the exact head
- **Phase gate:** the 0.2.14 release run ends COMPLETE (the live proof)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 201-01-01 | 01 | 1 | REL-09 | T-201-01 | real pre-2.6 public rulestead and its real Hex 2.6+ rebuild give unequal metadata digests on the unchanged rule (red captured); floors on all three fixtures | unit (real data) | `bash script/mix_test_gate.sh --out <EV>/real-tarball-red-201.txt --min 4 -- test/crosswake/release_candidate/artifact_real_tarball_test.exs` (expected FAIL: `rc=2 ... ran=4 failures=1 ... reason=mix_rc`) | ❌ W0 | ✅ green · red re-run at `55cead25`: `ran=4 failures=1 rc=2 FAIL` as recorded; green on origin/main |
| 201-01-02 | 01 | 1 | REL-09 | T-201-01, T-201-02, T-201-03 | full 19-test file red on the old rule with exactly 9 failures (equality, 6 shape, 2 companion build_env); core, content, unknown-key and floor tests pass | unit (real data) | same file, `--min 19` (expected FAIL: `rc=2 ... ran=19 failures=9 ... reason=mix_rc`) | ❌ W0 | ✅ green · red re-run at `58afa0a8`: `ran=19 failures=9 rc=2 FAIL`, the same nine tests; green on origin/main |
| 201-02-01 | 02 | 1 | REL-09 | T-201-37, T-201-38 | planning record on main first (user decision 2026-11-09): PR from `docs/201-planning-record` cut from origin/main, exactly eleven paths copied from the docs branch with only the `$HOME` prefix redacted to `~` (cmp-verified), ROADMAP additions only (Phase 200 and 201 entries), files, PR body and commit messages privacy-scanned, `docs(201)` commits only, CI green on the exact head within 45 minutes, pinned merge, planning worktree and local branch removed | git/gh reads + PR CI | `jq -e ... planning-record-pr-201.json`; `git show <merge>:<path>` against the redacted source with `cmp`; ROADMAP diff awk; `plan-record:` totals in `privacy-planning-record-201.txt` | evidence | ✅ evidence · planning record PR 286 merged as `665f0b9b`, an ancestor of origin/main |
| 201-02-02 | 02 | 1 | REL-09 | T-201-24, T-201-26, T-201-33 | prior red CI diagnosed per failed job (two failed, one cancelled); in the pre-existing worktree `~/projects/crosswake-agents-wt` (verified clean and at f53c2d21): AGENTS contract test red on PR 284's old head (`rc=2 total=12 ... failures=7 ... reason=mix_rc`), green after BEARINGS invariant 4 (net line count unchanged), the runbook approval sentences (incident runbook's Release Please merge sentence names the standing merge exception; companion runbook's per-step clause and never-standing sentence) and the phrases are amended; files and commit messages scanned before each push; PR body records the off-cadence authority; PR 284 CI green on its exact head within 45 minutes | unit + PR CI | `bash script/mix_test_gate.sh --out <EV>/approvals-contract-green-201.txt --min <counted> -- test/crosswake/planning/agents_contract_test.exs test/crosswake/bearings_report_test.exs test/crosswake/guides/release_boundaries_test.exs test/crosswake/proof/phase175_runbook_ancestry_test.exs`; runbook phrase gates on the AWT head | ✅ (edited) | ✅ green · re-run on origin/main: `total=110 failures=0 PASS` |
| 201-02-03 | 02 | 1 | REL-09 | T-201-25, T-201-27 | PR 284 merged pinned to its green head, after the planning record; `prior_ci` equals the failed jobs of run 42643335000 read live (aggregate excluded), cancelled jobs recorded; main's AGENTS.md, BEARINGS.md and runbooks authorize the standing steps; REL-07 and Phase 199 SC1 and SC2 follow-ups routed to 201-08 Task 2; the pre-existing worktree left clean at the merged head | git/gh reads | `jq -e ... approvals-pr-201.json`, `gh run view 42643335000 --json jobs` against `prior_ci`, `git show origin/main:AGENTS.md` phrase reads, `git worktree list --porcelain` | evidence | ✅ evidence · PR 284 merged as `44e2f69b`; AGENTS, BEARINGS and runbook phrases on main; prior red CI re-read live (run 42643335000 rc 0); worktree clean |
| 201-03-01 | 03 | 2 | REL-09 | T-201-39, T-201-28 | companions-only fix: all 19 real-tarball tests green; the five-name companion list is literal; one `Map.delete` | unit (real data) | `bash script/mix_test_gate.sh --out <EV>/real-tarball-green-201.txt --min 19 -- test/crosswake/release_candidate/artifact_real_tarball_test.exs` | ✅ | ✅ green · re-run on origin/main: `ran=22 failures=0` (floor 19) |
| 201-03-02 | 03 | 2 | REL-09 | T-201-40, T-201-29 | provenance line tests (22 total); six mutations (description, requirement, links, payload-byte, no-validation, core-excluded) each red on its own controls (`rc=2 ... ran=22 failures=<n> ... reason=mix_rc`), then restored | unit + mutation | same file, `--min 22`; `real-tarball-mutation-201.txt` greps | ✅ | ⚠️ green · re-run `ran=22 failures=0`; the six mutations are evidence-only and were not re-run (see Manual-Only) |
| 201-03-03 | 03 | 2 | REL-09 | — | release_candidate suite plus phase172 test at the measured floor (origin/main baseline + new tests); `Cleanroom.evaluate_public!` digest_mismatch anchors unchanged; hermetic suite; three guards | unit/integration | `bash script/mix_test_gate.sh --out <EV>/release-candidate-suite-201.txt --min <B+N> -- test/crosswake/release_candidate/ test/crosswake/proof/phase172_per_package_ref_test.exs` | ✅ | ✅ green · re-run: release_candidate plus phase172 `ran=218 failures=0`; guards PASS; hermetic suite `ran=3201 failures=0` on origin/main |
| 201-03-A1 (audit) | 03 | 2 | REL-09 | T-201-28 | an unlisted package keeps build_env in its digest, and a near-miss of a companion name is not excluded | unit (real data) | proposed, not in repo: `bash script/mix_test_gate.sh --out <EV>/build-env-scope-201.txt --min 2 -- test/crosswake/release_candidate/artifact_build_env_scope_test.exs` (audit probe, 2 tests, green on origin/main) | ❌ W0 | ⬜ manual-only (skip: needs its own PR) |
| 201-04-01 | 04 | 3 | REL-09 | T-201-05, T-201-30 | M2: six public 0.2.13 tarballs equal a fresh Hex 2.7.0 candidate build 6/6 under the fix; 12 provenance lines, only the core digested; manifests retained | measurement (evidence) | `measure-201.txt` greps | evidence only | ✅ recomputed · compare script on retained manifests: m2 6/6 EQUAL; self rc 0, flip rc 1 at 5/6, five-entry rc 2 |
| 201-04-02 | 04 | 3 | REL-09 | T-201-05 | M1 1/6 (core only) under the old rule; M1b equal; M3 Hex 2.5.1: 5/6, crosswake the only difference; M3-old differs; M4 history | measurement (evidence) | `jq -e ... measure-201.json` | evidence only | ✅ recomputed · m1 1/6, m1b 6/6, m3 5/6 (crosswake only), m3-old 0/6, all as recorded |
| 201-04-03 | 04 | 3 | REL-09 | T-201-07, T-201-08 | fixture contents scanned file by file with one disposition per hit; commit messages scanned before each push; fix PR green on its exact head within 45 minutes, pinned merge | PR CI | `jq -e ... fix-pr-201.json` (`ci_waits`), `fixture-scan:` totals in `privacy-201.txt` | evidence | ✅ evidence + live · PR 287 merged as `fdc218f9` (ancestor of origin/main); CI run 42700233686 success on head `57024c87`; privacy totals as recorded |
| 201-05-* | 05 | 4 | REL-08, REL-09 | T-201-09 to T-201-12 | 0.2.14 candidate contains the fix and PR 284 (bounded poll); rehearsals effect-free; drill on its own allow; receipt READY; core candidate built by the captured Hex; four dispatch waits bounded (45, 45, 120, 45 minutes) in `waits-201.txt`, no blind re-dispatch; Hex-release recovery route named | release rehearsal | `jq -e ... candidate-201.json`, `receipt-201.json`, `waits-201.txt` awk | evidence | ✅ evidence + live · 11 of 11 verify blocks pass; candidate CI run 42703531929 success on head `40739816`; receipt artifact unexpired to 2026-11-23 |
| 201-06-* | 06 | 5 | REL-08, REL-09 | T-201-13 to T-201-15 | docs REL-06 and remote iOS form PASS from the captured head; REL-17 pre_merge PASS; one disposition per privacy hit | release rehearsal | `grep`/`jq` on 201-06 evidence | evidence | ✅ evidence · 7 of 7 verify blocks pass (REL-06 docs, remote iOS, REL-17 pre_merge); stateful gates not re-run |
| 201-07-* | 07 | 6 | REL-08, REL-09 | T-201-16 to T-201-19, T-201-31, T-201-32, T-201-34 | committed standing rules checked first; Hex version unchanged at core merge and publish; six bounded waits recorded DONE; 0.2.14 release run ends COMPLETE with exact-public six of six | release run | `gh run view <run-id> --json conclusion`, `jq -e ... run-final-201.json`, `waits-201.txt` awk | — | ❌ BLOCKER (ledger clause) · release run `42713010358` completed/success, six packages fully_proven, six provenance lines live; `ledger_pr` and `ledger_line` are null, so the plan's own `fails_when` fired; ESCALATED |
| 201-08-* | 08 | 7 | REL-08, REL-09 | T-201-20 to T-201-23, T-201-35, T-201-36 | REL-09 amended (direction confirmed by the user, wording drafted by the planner); REL-08's completion cites 200-01-SUMMARY.md and 200-02-SUMMARY.md; REL-07 and Phase 199 SC1 and SC2 annotated; ledger lines and the rest of the planning record (diff plus explicit path list; Phase 201 plans already on main since 201-02 Task 1, planning-record conflicts resolved only by the blob rule) on main via one PR with files and commit messages privacy-scanned | git/gh reads | `git show origin/main:docs/release-ledger/RELEASE-LEDGER.jsonl` adjacency; `landing-privacy-201.txt` counts and `land-messages:` lines; `ledger-pr-201.json` `explicit_paths_missing` | evidence | ❌ BLOCKER (ledger clause, same root cause) · ledger lines adjacent on main (45, 46) ✅; `bot_prs=[285]` and null `ledger_line` fail the verify; P08-02 fails on PR 262 head drift (WARNING) |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `test/crosswake/release_candidate/artifact_real_tarball_test.exs` — real-tarball regression test
- [x] `test/fixtures/hex_tarballs/` — two real rulestead 0.1.1 tarballs (public, Hex 2.6+ rebuild) and the real public core 0.2.13 tarball, with a README recording how each was produced
- [x] a single-artifact `@doc false` entry point in `Crosswake.ReleaseCandidate.Artifact`
- [x] red-before-fix: the new test exits non-zero against the unchanged `artifact.ex` (201-01)
- [x] measured baselines at origin/main for the artifact/cleanroom tests and the release_candidate suite (201-01), used as floors in 201-03

---

## Manual-Only Verifications

All phase behaviors have automated verification. The merge and publish steps run under the standing approvals that PR 284 commits to `AGENTS.md`, BEARINGS invariant 4 and the two release runbooks (201-02). 201-07 checks them as its first action and stops if they are not on `main`. The Maven fire-drill dispatch (201-05) and remote-branch deletion keep their own `allow` gate.

### Audit findings (2026-11-09)

- **BLOCKER (ESCALATED): the release pipeline does not record the ledger line when a ledger PR is already open.** In `.github/workflows/exact-public-proof.yml`, job `record-ledger`, the duplicate guard logs "not opening a duplicate" and calls `exit 0`, so the step and the job summary both report success while the line exists only in the runner workspace. Observed live in release run `42713010358`: the 0.2.14 line was discarded because ledger PR 285 (the 0.2.13 line) was open. The line reached main by a local `script/append_release_ledger.sh` append in the landing PR 289. A later release with an open ledger PR would lose its line the same way. `release.cleanup.deduped` in `script/check_release_workflow_integrity.exs` guards a different job, so no check covers `record-ledger`. Developer action: make the skip path fail or stack a ledger PR, report the outcome in the job summary, and add a check on `record-ledger`. Until a fix lands, confirm each release's ledger line on main by hand.
- **WARNING: the 201-03 threat claim "any unlisted package keeps build_env" had no test.** An audit probe (scratch only, not committed) passed on origin/main: an unlisted name keeps build_env in its digest, and near-miss names of the five companions are not excluded. Repo test is proposed as row 201-03-A1; it needs its own PR, so it is manual-only under the audit gate.
- **WARNING: six mutation controls (201-03-02) are evidence-only.** The recorded verdicts were read and the green run was re-run, but the mutations were not re-run because that needs an edit to `artifact.ex`.
- **WARNING: verify drift, not a product defect.** Six blocks reference the removed fix worktree `crosswake-201-wt` (equivalent checks re-run on origin/main or on the fix branch). P04-04 uses `wc -l` equality, which fails on macOS padding (numeric recheck passes). P08-02 compares PR 262's live head to the reconcile record; the head has moved since (drift).
- **WARNING: STATE.md open item (5) lists 13 excluded raw sources.** The landing record excludes 43 files across phases 199 to 201: 14 from 201 (the 13 listed plus `premerge-result-201.json`), 15 from 200 (including `gate-order-200.awk`) and 14 from 199.
- **Hosted-log evidence observed:** the exact-public job of run `42713010358` carries the six `artifact-provenance` lines, as recorded (only `crosswake` digested).

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [ ] Feedback latency < 60s for the quick run
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** not approved (audit 2026-11-09: BLOCKER open on the ledger path)

## Validation Audit 2026-11-09

| Metric | Count |
|---|---|
| Gaps found | 16 |
| Resolved | 13 |
| Escalated | 2 |
| Skipped (manual-only) | 1 |
