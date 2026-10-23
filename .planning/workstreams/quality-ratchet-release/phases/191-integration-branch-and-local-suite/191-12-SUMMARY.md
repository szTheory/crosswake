---
phase: 191-integration-branch-and-local-suite
plan: 12
subsystem: integration-branch
tags: [land-01, land-02, finalize, privacy-scan, phase-gate, handoff]
requirements: [LAND-01, LAND-02]
status: complete
commits: 1
plan_head_before: 7075a441b4ed05a9497491cd01f686a2644a506a
plan_head_after: 98e0d3902b305089b9fe032f3036b716c2100e3e
actuals:
  tasks: 3
  commits: 1
key-files:
  created:
    - scripts/finalize-191.sh
    - 191-EVIDENCE/sync-191.txt
    - 191-EVIDENCE/suite-root-SYNC.txt
    - 191-EVIDENCE/suite-SYNC.txt
    - 191-EVIDENCE/scan-191.txt
    - 191-EVIDENCE/recovery-after-191.txt
    - 191-EVIDENCE/phase-gate-191.txt
    - 191-EVIDENCE/land01-dispositions-191.md
    - 191-EVIDENCE/recovery-tree-after-191.txt
    - 191-EVIDENCE/recovery-tree-check-191.txt
  modified:
    - scripts/carry-191.sh
    - scripts/selftest-carry-191.sh
    - 191-EVIDENCE/selftest-carry-191.out
    - 191-EVIDENCE/heads-191.txt
    - 191-EVIDENCE/scan-triage-191.tsv
    - STATE.md, ROADMAP.md, .continue-here.md (workstream handoff)
---

# Phase 191 Plan 12: Finalize, HEAD-bound privacy scan, phase gate and handoff Summary

## In plain words

The records written after the cut (37 files: the Plan 10 and 11 summaries, evidence, the edited scripts and the new finalize command) are now on the integration branch as one sync commit, `98e0d390`, on top of the FIXTURE commit `7075a441`. The branch is 112 commits ahead of `main` (`d0dbdf7b`). After the sync, the full carry was verified against `main` again (exact content, independent count floor 2527 added and 141 removed, both equal to the manifest), the root suite passed (2660 tests, 0 failures, floor 2660), the planning subset passed (951 tests, 0 failures), and the four planning checks (Phase 167 JS test, adoption scan, release workflow integrity script, collection-assertion ledger check) each exited 0. Only `.planning/` changed since FIXTURE.

The privacy scan of the whole change (112 commits, `main` to the sync head, preserved head = the candidate head) is clean: `blocking_final 0`, `gitleaks_findings 0` (gitleaks 8.30.1, 222 rules), `history_sensitive 0`. The adopter-term check was skipped by the user's decision (A-14): the scan used the built-in classes only (emails, home and temp paths, the account name, secrets) and says `adopter_check skipped_by_user`. `finalize-191.sh --check-binding` prints `binding pass` for this exact head.

The recovery checkout's git state equals the snapshot taken before Phase 191, and the working-tree compare (A-11) passes: every file outside the ten named records and the volatile list is byte-identical, and the named records that had to change did (7 changed, 3 allowed-to-change unchanged). The durable candidate is still at `2faf15a2` with a clean status. Nothing was pushed, no remote branch exists for `land/v25-v27`, and no upstream is set.

## How criterion 2 is met

The scan covered every blob, path and added line that is new in the range from `main` to HEAD, and every commit message and identity in that range. Within that range there are zero home paths, temp paths, usernames, emails that are not noreply or reserved test addresses, secrets or credential patterns in HEAD's tree and in every carried record and fix commit. Occurrences that exist only inside the preserved candidate history are accepted under D-20 rung 3 and counted: home path 1, temp path 0, username 1, because `main` already publishes the same username in 364 files and a rewrite would break LAND-01's preserved-history clause. This is not a claim about the whole final tree: 367 same-path records from `main`, outside the scanned range, still hold a pattern. They are `main`'s existing blobs, unchanged by this change, and are deferred to the hygiene seed. The best-effort cleanup the user asked for (A-14) was the PRIVACY commit earlier in the chain.

## History gate (LAND-01)

`phase-gate-191.txt` records: `main` is an ancestor of HEAD; the candidate head and `a53fbef` are ancestors; 94 candidate commits with the same SHAs as in the durable candidate; 0 merge commits; first-parent count equals the total; commit order after the candidate head equals `heads-191.txt` exactly; the 4 Phase 190 FIX commits are present; code commits touch no `.planning/` path; carry and sync commits touch only `.planning/`; `result pass`.

## Runtime files left out (A-2)

The workstream-level `config.json` and `state.json` are not carried. The Phase 167 validator and its JS test require them to stay untracked; updating that pin was rejected because they are local runtime state rewritten by every GSD session. Both are listed as explicit A-2 LAND-01 exemptions in `land01-dispositions-191.md`, which also lists the other exclusions and the criterion 2 reading.

## Next command

`$gsd-verify-work 191 --ws quality-ratchet-release`. Discussing Phase 192 comes only after that verification passes.

## What lands in Phase 192 (A-9)

This SUMMARY, the scan record, the phase-gate records, the handoff edits and VERIFICATION.md were written after the scan, so they cannot be inside the HEAD they describe. Phase 192 starts by running `finalize-191.sh`, which lands them as a second sync commit, re-checks and rescans. The push must refuse unless `finalize-191.sh --check-binding` passes for the push HEAD (D-22). The merge must be a merge commit, never squash or rebase (D-03). Phase 193 inputs (CLEAN-04, no CI lane for the full example-host suite, R-PL-14..16 obsolete copies, planning half of R-BR-047 landed, keep the clone and its trial branches until cleanup) are recorded in STATE.md. Commit skipped in the recovery checkout per D-23.

## Deviations from Plan

1. **[Rule 3 - numbering] Self-test control number.** The plan expected the new `ALL` bucket control to be S24; S24 and S25 already existed (Plan 10), so it is S26. The self-test now reports 26 of 26 as expected, with the S24 line passing.
2. **[A-14] Denylist clauses dropped.** The denylist precondition, the term and hash lines in `scan-191.txt` and the hash checks were skipped; `scan-191.txt` records `terms 0` and `adopter_check skipped_by_user_decision A-14` instead.
3. **[A-15] Base for the planning-only check.** `non_planning_paths 0` is measured from the FIXTURE commit (the last non-sync head), not from CARRY-v27.0, because FIXTURE is a code commit by design.
4. **[Rule 3 - ordering] Evidence written after the sync commit.** The record `heads-191.txt` is itself a carried file, so `finalize-191.sh` appends the `SYNC` line after the full verify, and the suites run after that. A re-run of finalize therefore always finds a small new delta (the A-9 behaviour); a `--scan-only` mode was added so the scan can be repeated without a second sync. `FINALIZE_STOP_BEFORE_SCAN=1` provides the Task 1 stop before the scan.
5. **[Rule 1 - benign scan hits] Five scan hits in this plan's own new records**, all in one line of the Plan 10 summary that quotes public API URLs (which the case-insensitive home-path class reads) and fabricated test emails: two email and three home_path hits. Each was checked and got a triage row with a reason (`C12-191-12`) in `scan-triage-191.tsv`; no value was changed. The triage rows reach the branch through the Phase 192 sync.
6. **[Plan check adapted] No-push check.** The clone was made from GitHub, so it holds many `refs/remotes/origin/*` refs; the check was changed from "only origin/main" to: no remote ref outside `origin`, none under `origin/land/`, `origin/main` equals `main`'s SHA, and no upstream for `land/v25-v27`.
7. **[Placement] Phase-gate script.** The gate and the criterion 2 measurements ran from a run-folder script (not carried), not from `finalize-191.sh`; their results are in `phase-gate-191.txt`.
8. Trailer on the sync commit uses the model name given by the current session (Claude Sonnet 5.5).

## Leftovers for Phase 193

Trial branches `carry-trial`, `carry-trial-2` (and `carry-trial-3`, equal to the pre-FIXTURE head) remain in the integration clone, as does `candidate-src`; they are not reused or removed.

## Known Stubs

None.

## Self-Check: PASSED

Sync SHA `98e0d390` is an ancestor of the clone HEAD and equals it; every evidence file named above exists; `--check-binding` passes; recovery snapshot equals the before-snapshot; tree compare passes; STATE, ROADMAP and `.continue-here.md` name one next command and contain no absolute path or account name.
