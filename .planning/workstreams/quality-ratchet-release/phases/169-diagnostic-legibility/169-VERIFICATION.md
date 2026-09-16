---
phase: 169-diagnostic-legibility
verified: 2026-09-16T16:10:00Z
status: passed
score: 4/4 must-haves verified
covered_files:
  - .github/workflows/phase70-proof.yml
  - .github/workflows/release-please.yml
  - .planning/workstreams/quality-ratchet-release/REQUIREMENTS.md
  - .planning/workstreams/quality-ratchet-release/phases/169-diagnostic-legibility/169-01-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/169-diagnostic-legibility/169-01-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/169-diagnostic-legibility/169-02-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/169-diagnostic-legibility/169-02-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/169-diagnostic-legibility/169-03-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/169-diagnostic-legibility/169-03-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/169-diagnostic-legibility/169-04-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/169-diagnostic-legibility/169-04-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/169-diagnostic-legibility/169-REVIEW.md
  - .planning/workstreams/quality-ratchet-release/phases/169-diagnostic-legibility/deferred-items.md
  - docs/COMPANION-PUBLISH-RUNBOOK.md
  - lib/crosswake/release_status.ex
  - lib/mix/tasks/crosswake.release.status.ex
  - script/check_release_workflow_integrity.exs
  - script/check_required_checks_registered.sh
  - script/list_merge_blocking_checks.py
  - test/crosswake/proof/phase169_check_name_uniqueness_test.exs
  - test/crosswake/proof/phase169_diagnostic_legibility_test.exs
  - test/crosswake/proof/phase169_exit_contract_guard_test.exs
covered_digest: "v1:sha256:c34f65e1702c63c12ddb98d215d12ea9d8c395b6108fbb8249fe17e700aebc70"
revalidated: 2026-09-16T20:51:03Z
revalidation_note: |
  Digest refreshed by /gsd-verify-work 169 (see 169-UAT.md). The prior digest
  (v1:sha256:43ecc49f...) went stale because phase 170 edited the SHARED
  .planning/workstreams/quality-ratchet-release/REQUIREMENTS.md, which is listed in
  covered_files. Every covered file that phase 169 is actually about — release_status.ex,
  crosswake.release.status.ex, check_release_workflow_integrity.exs,
  check_required_checks_registered.sh, list_merge_blocking_checks.py, release-please.yml,
  phase70-proof.yml, and the three phase-169 test files — is byte-unchanged since the original
  verification. All four success criteria were RE-EXECUTED, not re-read: 53 proof tests pass,
  list_merge_blocking_checks.py --producers exits 0 with 103 records / 0 version-literal / 0
  duplicate names, mix crosswake.release.status exits 0 with no FAIL/UNVERIFIED lines, and
  required_check_policy.json diffs empty. Verdict unchanged: passed, 4/4.
behavior_unverified: 0
overrides_applied: 0
deferred:
  - truth: "REQUIREMENTS.md header names the active v23.0 milestone"
    addressed_in: "unscheduled (project-state bookkeeping, not a phase)"
    evidence: "deferred-items.md records this as pre-existing, out of scope for 169-02; independently confirmed pre-existing against commit 5ded8f90 (the last pre-phase-169 commit), where the same milestone-name assertion already failed on a different sub-check (PROJECT.md active marker) for the identical root cause."
---

# Phase 169: Diagnostic Legibility Verification Report

**Phase Goal:** A maintainer reading any release or verification check failure sees that check's own
message, and the system never reports "missing" when the true state is "failing" or "never ran."
**Verified:** 2026-09-16T16:10:00Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth (Roadmap SC) | Status | Evidence |
|---|---------|--------|----------|
| 1 | A deliberately failing release check surfaces its own verbatim `detail` message in `Crosswake.ReleaseStatus`'s output — not a generic "missing check IDs" list — confirmed by a test asserting the exact string appears. | ✓ VERIFIED | `test/crosswake/proof/phase169_diagnostic_legibility_test.exs` builds a real drifted-manifest fixture (PR #164 reproduction), runs the scanner directly, extracts its verbatim `[crosswake] FAIL:` detail, then asserts `check.message =~ detail` and `rendered =~ detail` (lines 48-53). Ran `mix test` on this file: 53 tests, 0 failures. The `release.workflow_integrity` owner check (`lib/crosswake/release_status.ex`) always emits and carries the verbatim scanner `detail`, confirmed by reading the source (`workflow_integrity_owner_check/1`) and by a live clean-tree run (`mix crosswake.release.status`, exit 0, no FAIL/UNVERIFIED lines). |
| 2 | A scanner run that terminates early is reported distinctly from a check ID that was never defined, with a message naming how many checks after the last observed failure never ran — confirmed by a test exercising both cases and asserting different, correctly-labeled output. | ✓ VERIFIED | Three distinctly-worded, distinctly-tested paths confirmed in `phase169_diagnostic_legibility_test.exs`: (a) crash-before-ROSTER → `"scanner did not start: no roster line emitted (exit "` (line 379); (b) ROSTER-then-crash → `"scanner terminated early: 0 of "` + `" roster checks ran (exit "` (lines 402-404); (c) a required ID absent from the roster → `"never defined by scanner: #{missing_id}"` + `"not in the scanner's 69-check roster"` (lines 317-319). All three are asserted as different, non-overlapping substrings in the same test suite, which passed. |
| 3 | The three release check display names carrying `0.2.1` are renamed to version-neutral names, and a uniqueness assertion over required-check names fails when two names collide — confirmed by a test that introduces a duplicate and watches the assertion fail. | ✓ VERIFIED (see WR-01 caveat below) | Live-tree measurement: `python3 script/list_merge_blocking_checks.py --producers` exits 0 with 103 records, 0 version-literal names, 0 duplicate display names post-fix (independently re-derived, matching the plan's claimed 0/0 post-fix counts). All six renamed strings independently confirmed present via `git grep`. `script/required_check_policy.json` has an empty diff across all of phase 169's commits (confirmed against commit `5442b9ac`, the last commit that touched it, which predates phase 169). The widened scan + all six renames landed in a single commit (`ae9b6651`, confirmed via `git show --stat`). Duplicate-collision detection is fully proven live: I independently reproduced the code review's WR-01 fixture (two workflow files sharing a display name) and confirmed the Python-level check fires and exits non-zero. |
| 4 | A verification command exercised twice — once finding a real defect, once unable to run at all — exits with two different, documented statuses, confirmed by running both cases and diffing the exit codes. | ✓ VERIFIED | `phase169_diagnostic_legibility_test.exs` runs `mix crosswake.release.status` (or the `mix run -e` equivalent) as a real OS subprocess three times and asserts exact `exit_status` integers: clean → `0`, drifted-manifest (real defect) → `1`, crash fixture (could not run) → `3` (lines 627-665). `Crosswake.ReleaseStatus.exit_code/1` carries `:unverifiable -> 3` textually above the `_ -> 0` catch-all (confirmed by reading `lib/crosswake/release_status.ex`), and `aggregate_status/1` places `:unverifiable` between `:error` and `:warning`. Independently ran `mix crosswake.release.status` on the live clean tree: exit 0, confirmed. |

**Score:** 4/4 truths verified

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `script/check_required_checks_registered.sh` | 92-102 | Dead code + a proof test that passes for the wrong reason (a vacuous-assertion shape) | ⚠️ Warning | Independently reproduced (see below). Does not block SC #3 — the equivalent guarantee is enforced globally and unconditionally by `list_merge_blocking_checks.py`'s `inventory()` (this same phase's change) — but the specific shell-level block this plan's Task 2 explicitly asked for ("stated at the shell entry point and not only inferred from the Python exit code") is unreachable for any real duplicate, and the accompanying test's own docstring ("proves the same guarantee independent of the Python exit code") is false. This is exactly the "checks that stay green while asserting nothing" defect class this workstream exists to eliminate — occurring inside a phase built to eliminate it. Recommend a follow-up fix per the REVIEW.md WR-01 remediation options (delete the dead block, or make it reachable and rewrite the test to actually falsify its claim). |
| `.github/workflows/phase70-proof.yml` | 17 | Renamed job display name (`advisory provider device proof (play billing)`) now omits "storekit", but the job's steps still run the StoreKit advisory checks unchanged | ℹ️ Info | Does not affect any of the four success criteria (mechanical uniqueness is satisfied — the name is unique). It is a semantic-accuracy regression that cuts against the phase's own diagnostic-legibility spirit. Non-blocking; already recorded in REVIEW.md IN-01. |

**Independent confirmation of WR-01:** I built the exact two-workflow-file fixture the code review describes (`.github/workflows/{a,b}.yml`, both defining a job named `shell-level shared display name`) and ran `bash script/check_required_checks_registered.sh --local-only` against it:

```
[crosswake] FAIL: duplicate-producer/duplicate-display-name - .github/workflows/a.yml (alpha), .github/workflows/b.yml (beta): literal context 'shell-level shared display name' has 2 producers
[crosswake]   What to do next: rename the later producer so every display name has exactly one producer.
[crosswake] FAIL: local producer inventory failed.
exit:1
```

This confirms the shell script exits at line 38 (`local producer inventory failed`, triggered because `list_merge_blocking_checks.py`'s `inventory()` now runs the duplicate scan unconditionally regardless of `--producers`/`--emitters` mode) before it can ever reach the dedicated duplicate-loop at lines 92-102. Reading `script/list_merge_blocking_checks.py`'s `main()` confirms `inventory()` (and its embedded duplicate/version-literal scans) executes before mode selection, and `return 1 if errors else 0` fires regardless of mode. WR-01 is accurate.

**Disposition:** This does not fail SC #3 as worded — a uniqueness assertion (the Python-level one) does fail when two names collide, and a test does watch it fail — but it is a real, verified quality defect that the phase's own charter is built to catch. Classified as a non-blocking Warning rather than a gap because the observable behavior the roadmap SC describes is genuinely true and independently reproduced; the defect is in an intended second layer of defense being unreachable, not in the goal's core guarantee failing.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|---|---|---|---|---|
| MSG-01 | 169-01 | Maintainer sees the failing check's own verbatim message, not an ID list | ✓ SATISFIED | Truth 1 above; `test/crosswake/proof/phase169_diagnostic_legibility_test.exs` passing |
| MSG-02 | 169-02 | Terminated-early scanner distinguished from never-defined ID | ✓ SATISFIED | Truth 2 above |
| MSG-03 | 169-01 | `missing` never shadows `failing`; both composed in one message | ✓ SATISFIED | `scanner_ids_result/2`'s `:failed` clause scoped to `required_ids`; both-buckets composed message asserted at lines 291-296 (`failing_part` before `missing_part`, joined) |
| MSG-06 | 169-03 | `0.2.1`-carrying names renamed; uniqueness assertion fails on collision | ✓ SATISFIED (WR-01 caveat) | Truth 3 above |
| FID-02 | 169-02, 169-04 | Ran-and-found-a-defect exits differently from could-not-run | ✓ SATISFIED | Truth 4 above; `phase169_exit_contract_guard_test.exs` additionally pins the literal exit-value sets for 6 entry points and passed (53 combined tests, 0 failures across the three phase-169 test files) |

**Cross-reference against REQUIREMENTS.md:** All five requirement IDs (MSG-01, MSG-02, MSG-03, MSG-06, FID-02) appear in `.planning/workstreams/quality-ratchet-release/REQUIREMENTS.md` marked `[x]` and mapped to "Phase 169 / Complete" in its traceability table (lines 17-19, 22, 57, 121-149). No orphaned requirements found for this phase.

### Test Execution Evidence

| Command | Result |
|---|---|
| `mix test test/crosswake/proof/phase169_diagnostic_legibility_test.exs test/crosswake/proof/phase169_check_name_uniqueness_test.exs test/crosswake/proof/phase169_exit_contract_guard_test.exs` | 53 tests, 0 failures |
| `mix test test/mix/tasks/crosswake_release_status_test.exs test/crosswake/proof/phase142_release_integrity_test.exs test/crosswake/proof/phase153_ios_mirror_unblock_test.exs test/crosswake/proof_lane/ios_verifier_test.exs test/crosswake/proof/phase153_1_gate_integrity_test.exs test/crosswake/proof/phase135_ci_ops_proof_test.exs test/crosswake/proof/phase165_ci_policy_test.exs test/crosswake/proof/phase164_dependency_security_and_gate_authority_test.exs test/crosswake/proof/phase168_version_truth_test.exs` | 157 tests, 1 failure (pre-existing, see below) |
| `mix test` (full suite) | 1758 tests, 2 failures (74 excluded) — both failures are the same pre-existing root cause, see below |
| `python3 script/list_merge_blocking_checks.py --producers` | exit 0, 103 records, 0 version-literal names, 0 duplicate names |
| `mix crosswake.release.status` (live clean tree) | exit 0, no `FAIL (exit` or `UNVERIFIED (exit` lines |
| `git diff --stat 5ded8f90..HEAD -- script/required_check_policy.json` | empty (byte-unchanged across all of phase 169) |

**Pre-existing full-suite failures (independently confirmed, not caused by phase 169):** Both `test/crosswake/planning/milestone_transition_reset_test.exs` ("live operational surfaces all name the milestone from STATE frontmatter") and its dependent `test/crosswake/proof/phase135_ci_ops_proof_test.exs` ("deferred core-hermetic failures are now green: milestone_transition_reset") fail because `.planning/workstreams/quality-ratchet-release/REQUIREMENTS.md`'s header text (`"Crosswake v23.0 — Release Pipeline Repair & Proof-Lane Truth"`, em-dash separated) does not literally contain the exact label the test derives from `STATE.md` frontmatter (`"v23.0 Release Pipeline Repair & Proof-Lane Truth"`, space-separated). I confirmed this is pre-existing and unrelated to any file phase 169 touched: I checked out the test file and REQUIREMENTS.md at commit `5ded8f90` (the last commit before phase 169's first commit) and ran the test in isolation — it already failed at the same root cause (a different assertion in the same test, the `PROJECT.md` active-marker check, which fails for the identical milestone-header-naming reason). `deferred-items.md`'s characterization of this as pre-existing, out-of-scope project-state bookkeeping is accurate.

### Data-Flow / Key Link Verification

| From | To | Via | Status | Details |
|------|-----|-----|--------|---------|
| scanner subprocess stdout | `parse_workflow_integrity_output/1` | `OK\|FAIL` anchored regex | ✓ WIRED, unchanged | Confirmed byte-identical regex literal referenced across plans; not independently re-diffed against pre-phase source but no plan claims it changed and all consumer tests (`phase142`, `phase153_ios_mirror_unblock`) pass unmodified |
| `parse_workflow_integrity_output/1` | `workflow_integrity_owner_check/1` → `render/1` | `detail` string threaded through `order:`-keyed map | ✓ WIRED, VERIFIED | Confirmed by the passing tracer test (Truth 1) — the exact fixture-generated detail string round-trips to `render/1`'s output |
| `aggregate_status/1` | `exit_code/1` | shared `:unverifiable` atom | ✓ WIRED, VERIFIED | Confirmed by reading source: `exit_code(:unverifiable), do: 3` is textually above `exit_code(_status), do: 0`; confirmed live via subprocess exit-status tests |
| `exit_code/1` | OS exit status via Mix task | `case`/`exit({:shutdown, 3})` | ✓ WIRED, VERIFIED | Confirmed via real `System.cmd` subprocess assertions in the test suite and my own live `mix crosswake.release.status` run |
| `list_merge_blocking_checks.py --producers` non-zero exit | `check_required_checks_registered.sh`'s `|| exit 1` guard | shell pipeline | ✓ WIRED, VERIFIED (but see WR-01) | Confirmed live with fixture reproduction — the guarantee IS enforced, just not by the specific new shell-level block Task 2 described |

### Human Verification Required

None. All four success criteria are mechanically verifiable and were verified by direct test execution and live command runs, not by trusting SUMMARY claims.

### Gaps Summary

No blocking gaps. All four roadmap success criteria are observably true in the codebase, backed by passing, non-vacuous tests I executed directly (not merely read). All five requirement IDs (MSG-01, MSG-02, MSG-03, MSG-06, FID-02) are satisfied and correctly cross-referenced in REQUIREMENTS.md.

One independently-confirmed Warning (WR-01) is carried forward from the code review: the shell-level global-uniqueness block added to `script/check_required_checks_registered.sh` is dead code for any real duplicate (the Python-level check in the same phase's change fires first and exits non-zero before the shell block is reached), and its accompanying proof test's docstring makes a false "independent of the Python exit code" claim. This does not block SC #3 — the underlying guarantee (a uniqueness assertion fails on collision) genuinely holds via the Python layer — but it is a real, verified instance of exactly the "checks that stay green while asserting nothing" defect class this quality-ratchet workstream targets, occurring inside the phase built to eliminate that class. Recommend a follow-up fix (delete the dead shell block, or make it reachable and correct the test's claim) before this pattern is copied elsewhere.

One Info-level finding (IN-01) is carried forward: `phase70-proof.yml`'s renamed job display name now omits "storekit" despite the job still running StoreKit checks — a minor semantic-accuracy regression, non-blocking.

The full-suite's two pre-existing failures (both rooted in `REQUIREMENTS.md`'s milestone-header wording, unrelated to any file this phase modified) were independently confirmed pre-existing by checking out the affected test and REQUIREMENTS.md at the last pre-phase-169 commit and observing the same root-cause failure there. `deferred-items.md`'s characterization is accurate.

---

_Verified: 2026-09-16T16:10:00Z_
_Verifier: Claude (gsd-verifier)_
