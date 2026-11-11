---
phase: 200-forward-fix-and-release-0-2-13-default-ios-generation-builds
verified: 2026-11-10T09:00:00Z
status: passed
score: 5/5 must-haves verified
covered_files:
  - .github/workflows/crosswake-ci.yml
  - .planning/workstreams/quality-ratchet-release/phases/200-forward-fix-and-release-0-2-13-default-ios-generation-builds/200-01-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/200-forward-fix-and-release-0-2-13-default-ios-generation-builds/200-01-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/200-forward-fix-and-release-0-2-13-default-ios-generation-builds/200-02-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/200-forward-fix-and-release-0-2-13-default-ios-generation-builds/200-02-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/200-forward-fix-and-release-0-2-13-default-ios-generation-builds/200-03-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/200-forward-fix-and-release-0-2-13-default-ios-generation-builds/200-03-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/200-forward-fix-and-release-0-2-13-default-ios-generation-builds/200-04-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/200-forward-fix-and-release-0-2-13-default-ios-generation-builds/200-04-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/200-forward-fix-and-release-0-2-13-default-ios-generation-builds/200-05-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/200-forward-fix-and-release-0-2-13-default-ios-generation-builds/200-05-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/200-forward-fix-and-release-0-2-13-default-ios-generation-builds/200-06-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/200-forward-fix-and-release-0-2-13-default-ios-generation-builds/200-06-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/200-forward-fix-and-release-0-2-13-default-ios-generation-builds/200-07-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/200-forward-fix-and-release-0-2-13-default-ios-generation-builds/200-07-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/200-forward-fix-and-release-0-2-13-default-ios-generation-builds/200-08-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/200-forward-fix-and-release-0-2-13-default-ios-generation-builds/200-08-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/200-forward-fix-and-release-0-2-13-default-ios-generation-builds/200-09-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/200-forward-fix-and-release-0-2-13-default-ios-generation-builds/200-09-SUMMARY.md
  - lib/crosswake/shell/ios_host_generation.ex
  - lib/mix/tasks/crosswake.gen.shell.ex
  - script/verify_default_ios_generation_build.sh
  - test/crosswake/shell/default_ios_build_script_test.exs
  - test/mix/tasks/crosswake_gen_shell_default_references_test.exs
covered_digest: "v4:sha256:42a67a515dd7774d0a070dea800e6e796c4c2a84d0e8d4de57af0f9aee172b62"
behavior_unverified: 0
overrides_applied: 0
advisory:
  - finding: "Compile warning in the regression test: test/mix/tasks/crosswake_gen_shell_default_references_test.exs:57 compares `args == [\"--local\"]` inside a `for` that unquotes `args`, and the Elixir 1.19 type checker reports 'comparison between distinct types' for the no-flag expansion (empty_list() == non_empty_list(binary())). The test passes and the branch is correct; the comparison is statically always false in the no-flag expansion."
    category: other
    reason: "Surfaced when the file was run on 2026-11-10; the project rule is to fix warnings before landing, but it does not falsify any Success Criterion. Cheap fix: branch on the `form` or a `local?` boolean unquoted from the loop instead of comparing the list."
    evidence_status: "reproduced by `mix test` on the file at origin/main code"
  - finding: "Phase 200's own SC5 line in ROADMAP.md carries no inline annotation for the threadline deferral, and 200-EVIDENCE is silent on it; the recorded deferral lives in 199-DECISIONS.md D-31 and in the Phase 199 SC1 and SC2 annotations. The Phase 201 reconcile record (201-EVIDENCE/reconcile-201.json, 2026-11-09) still shows PR 262 OPEN with an older reopening condition; D-31 (2026-11-10) closed PR 262 and replaced the condition. The receiver is stated as 'a new plan' without a number."
    category: other
    reason: "The deferral is real and user-decided; a later reader following only Phase 200 would find a stale condition. Cross-reference D-31 from the Phase 200 SC5 line when the milestone is archived. PR 292 (the recreated threadline 0.1.1 release PR) is now OPEN, so the reopening condition may be close to met."
    evidence_status: "gh pr view 262 (CLOSED), gh pr list (292 OPEN), 199-DECISIONS.md D-31"
coincidental_reliance_items: []
---

# Phase 200: Forward fix and release 0.2.13: default iOS generation builds - Verification Report

**Phase Goal:** Phase 199 published 0.2.12 to Hex, Maven and the iOS mirror, and its post-publish iOS clean-room proof then failed: the default `mix crosswake.gen.shell ios` (no `:crosswake, :ios_host` configuration) wrote an Xcode project that referenced `CrosswakeHostSettings.xcconfig` but never wrote that file. 0.2.12 is permanent, so the fix ships forward as 0.2.13 and the failure cannot ship again.
**Verified:** 2026-11-10T09:00:00Z
**Status:** passed
**Re-verification:** No - initial verification (the phase had no VERIFICATION.md; written for the milestone audit)

Code pin: the implementation lives on origin/main (5b52db30; the generator fix at merge e8d44c6c, PR 282). The main checkout is on the local branch `docs/199-complete`; `git diff origin/main -- lib priv script test .github` is empty, so tests and the gate were run from the checkout and match origin/main. Code was also read with `git show origin/main:<path>`. `covered_digest` covers this phase's planning files and the implementation files; the Phase 200 evidence directory is inert to the fingerprint. SUMMARY claims were not used as evidence; the one exception is the amended-SC history, taken from ROADMAP.md and REQUIREMENTS.md and cross-checked against live state.

## Verdict in one paragraph

All five Success Criteria hold against live state, judged as amended. The fix, its regression test and the pre-release gate are on origin/main and pass when run today. The release outcome is the one the roadmap amended it to: 0.2.13 published Hex, Maven and the iOS mirror but its run 42639651064 ended FAILURE at the exact-public proof (a defect in the proof, not the release), and the COMPLETE run is 0.2.14 (42713010358) under Phase 201. SC5 is satisfied by a recorded user deferral (D-31) with a named reopening condition. The two advisories above do not change the status.

## Goal Achievement

### Observable Truths

| # | Truth (ROADMAP Success Criterion, as amended) | Status | Evidence |
|---|---|---|---|
| 1 | The default iOS generation path produces a project whose referenced files all exist; a regression test asserts it on the real generator output; the 0.2.12 reproduction (6 references, no file) fails the test before the fix and passes after | VERIFIED | `origin/main:lib/mix/tasks/crosswake.gen.shell.ex:639` writes `CrosswakeHostSettings.xcconfig` via `ensure_file` when `host_outputs` is nil; `IOSHostGeneration.render_default_settings/0` exists. `test/mix/tasks/crosswake_gen_shell_default_references_test.exs` covers both default forms (no-flag remote and `--local`), asserts at least 10 group file references, every referenced file exists, 4 base configuration references resolve to the settings file, and has a negative control that removes the file. Ran today with `mix test` on this file plus the gate's script test: 21 tests, 0 failures. Red-before evidence: `200-EVIDENCE/default-ios-fix-200.txt` shows the same 5 tests failing 5/5 on the 0.2.12 generator (lib and priv equal to hex-v0.2.12, checked) with xcodebuild exit 65, and green after; the 61-test declared-`:ios_host` baseline is unchanged (61 before, 61 after). Note: the project holds 4 `baseConfigurationReference` entries and 6 mentions of the file; the roadmap's "6 references" is the mention count. |
| 2 | A pre-release gate builds the default-generated project with `xcodebuild` before any release; measured before merge-blocking; shown to fail on the 0.2.12 behavior | VERIFIED | `origin/main:script/verify_default_ios_generation_build.sh` exists (negative control: the same build with the file removed must exit 65 or the gate fails `negative_control_passed`). Wired as a plain step in `phase79-ios-proof` in `.github/workflows/crosswake-ci.yml` (lines 1120-1121, no `continue-on-error`), job runs only on `full_proof`, so the release PR is covered. I ran it today on this macOS host: rc 0, `build_rc=0 control_rc=65 control=detected verdict=PASS`, build 19 s. Measured before merge-blocking: `fix-pr-200.json` and run 42554142308 on PR 282 (gate step 32 s, job 122 s vs 104 s baseline, 174 billable min vs about 250 baseline) were read before the merge. Fails on 0.2.12: `default-ios-build-200.txt` `before:` and `remote-rehearsal-before:` lines, rc 1, `build_rc=65`, "Unable to open base configuration reference file". Release-candidate legs: the 0.2.14 candidate's gate line (`201-EVIDENCE/candidate-201.json`, PASS) and the remote form against mirror 0.2.13 (`201-EVIDENCE/candidate-remote-201.txt`, PASS). |
| 3 | The fix is released from Hex, Maven and the iOS mirror, core first, and the release run ends COMPLETE including the iOS clean-room and exact-public proofs. (Amended 2026-11-09, Phase 201: met by 0.2.14 run 42713010358; 0.2.13 run 42639651064 published everything and ended FAILURE at the exact-public proof, superseded and not re-run.) | VERIFIED (as amended) | Live: Hex has 0.2.13 (published 2026-11-09T15:32Z) and 0.2.14 (22:54Z), both with docs, no retirements. Maven Central POM returns 200 for 0.2.13 and 0.2.14. Mirror tags v0.2.12, v0.2.13, v0.2.14 all exist (same mirror commit, same tree, per `mirror-tag-0.2.13-200.txt`). Source tags hex-v, ios-core-v, android-core-v exist for 0.2.13 (at merge 0aa18470) and 0.2.14 (at dc6a8ed3). `gh run view 42713010358`: conclusion success on head dc6a8ed3; every job success or intentionally skipped, including `Clean-room proof - iOS swift build`, `release: ios mirror tag check`, `Native release status rollup`, `exact-public artifact proof` and its ledger record, and `release: linked release rollup`. Run 42639651064 is attempt 1, conclusion failure, never re-run. The 0.2.13 gate order was machine-checked: `gate-order-controls-200.sh` re-run today, 53 cases, 0 wrong, PASS. Core was published first (Hex 15:32Z, Maven 15:48Z, mirror 16:02Z). Disclosure, not a gap: in 0.2.13 the core-maven and core-ios steps were approved under the user's mid-run standing publish statement (`gates-200.txt` notes), not as individually asked one-use allows; the roadmap annotation and the standing exceptions committed by PR 284 account for this, and the amended SC3 is judged on 0.2.14. |
| 4 | The 0.2.12 PARTIAL release is reconciled in writing: run 42494651844, issue 281 and PR 280 dispositioned; retiring 0.2.12 on Hex decided separately; nothing re-run or re-approved under a used allow | VERIFIED | Live reads: run 42494651844 conclusion failure (unchanged, not re-run); issue 281 CLOSED, COMPLETED 2026-11-09T23:31Z; PR 280 MERGED (merge 0aa18470, head 5a6a7521, titled as the 0.2.13 release PR); bot ledger PR 285 CLOSED. `201-EVIDENCE/reconcile-201.json` records each disposition, `hex_retire_0_2_12` as undecided with recommendation "do not retire" and receiver "a new plan with its own displayed one-way gate"; Hex shows zero retirements, so nothing was retired. `approvals_reused: 0` with basis (`gates-199.txt` unchanged since e8dda234; `gates-201.txt` names neither the 0.2.12 nor the 0.2.13 head). |
| 5 | The threadline companion release (0.1.1, PR 262) is either released after 0.2.13 or recorded as deferred with the condition that reopens it | VERIFIED (by recorded deferral) | Not released: PR 262 is CLOSED, and Hex has no companion movement in this phase. The deferral is recorded and says so in the roadmap itself: the Phase 199 SC1 and SC2 annotations in ROADMAP.md state "The threadline 0.1.1 companion publish is deferred by the user on 2026-11-10 (D-31), as Phase 200 SC5 allowed; it reopens when Release Please has recreated the threadline release PR from a main that includes the 30-minute CI bound (PR 290) and Crosswake CI is green on its exact head, and then runs as a new plan." `199-DECISIONS.md` D-31 carries the same condition and the facts, D-32 ties REL-07 to it, and plans 199-13 and 199-14 are marked deferred (`[-]`) in ROADMAP.md. See the second advisory for the stale 2026-11-09 record and the unnumbered receiver. |

**Score:** 5/5 truths verified (0 present, behavior-unverified). Truth 1 and the gate in truth 2 are behavior-dependent; both have a passing behavioral test or run (above), not presence alone.

### Deferred Items

| # | Item | Addressed In | Evidence |
|---|------|-------------|----------|
| 1 | Threadline 0.1.1 companion release | A new plan (reopening condition in D-31); not a numbered later phase | ROADMAP.md Phase 199 SC1/SC2 annotations; 199-DECISIONS.md D-31, D-32. Counted as SC5 satisfied, not as a gap, because SC5 allows a recorded deferral. |
| 2 | Decision whether to retire 0.2.12 on Hex | A new plan with gate `hex-retire-0.2.12` | `201-EVIDENCE/reconcile-201.json`; SC4 requires only that it be decided separately. |

### Required Artifacts

| Artifact | Expected | Status | Details |
| -------- | -------- | ------ | ------- |
| `lib/crosswake/shell/ios_host_generation.ex` | `render_default_settings/0` for the default path | VERIFIED | on origin/main, referenced from the task |
| `lib/mix/tasks/crosswake.gen.shell.ex` | default path writes the settings file once; declared `:ios_host` path unchanged | VERIFIED | line 639 branch gated on `is_nil(host_outputs)`; declared baseline 61 tests unchanged |
| `test/mix/tasks/crosswake_gen_shell_default_references_test.exs` | regression test on real generator output, both forms, negative control | VERIFIED | 5 tests, pass today; one type-checker warning (advisory) |
| `script/verify_default_ios_generation_build.sh` | build gate with in-run negative control | VERIFIED | rc 0 today, control detected |
| `test/crosswake/shell/default_ios_build_script_test.exs` | contract test for the gate | VERIFIED | 16 tests, 0 failures (part of the 21 above) |
| `.github/workflows/crosswake-ci.yml` step | gate wired into the full-proof iOS job | VERIFIED | blocking step in `phase79-ios-proof` |
| `docs/release-ledger/RELEASE-LEDGER.jsonl` lines 45-46 | 0.2.13 failure and 0.2.14 success on main | VERIFIED | line 45 package crosswake 0.2.13 run 42639651064 outcome failure; line 46 0.2.14 run 42713010358 outcome success |
| `scripts/gate-order-200.awk` and controls | phase-local order checker with 53 controls | VERIFIED | controls re-run, 53/53 |
| `200-08-BLOCKED.md` | kept as history | VERIFIED | present, unchanged; plans 200-08 and 200-09 carry `closed_by: 201-08` |

### Key Link Verification

| From | To | Via | Status | Details |
| ---- | -- | --- | ------ | ------- |
| `mix crosswake.gen.shell ios` (default) | `CrosswakeHostSettings.xcconfig` on disk | `ensure_file` with `render_default_settings` | WIRED | proven by the regression test and by xcodebuild exit 0 |
| CI `phase79-ios-proof` | `verify_default_ios_generation_build.sh` | step `run:` line | WIRED | line 1121, no `continue-on-error` |
| Release PR CI | the gate | `full_proof` classification | WIRED | 0.2.14 candidate carries a PASS gate line |
| Release run 0.2.14 | ledger line on main | runner ledger job plus `script/append_release_ledger.sh` in the landing PR | WIRED | line 46 on origin/main |

### Data-Flow Trace (Level 4)

Not applicable: no rendered dynamic data. The generator output is the data, and it is exercised end to end by xcodebuild.

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| -------- | ------- | ------ | ------ |
| Default generation writes every referenced file; gate script contract | `mix test test/mix/tasks/crosswake_gen_shell_default_references_test.exs test/crosswake/shell/default_ios_build_script_test.exs` | 21 tests, 0 failures (one compile warning) | PASS |
| Default `--local` project builds and negative control fails as expected | `bash script/verify_default_ios_generation_build.sh` | rc 0, `build_rc=0 control_rc=65 control=detected verdict=PASS` | PASS |
| Gate-order checker has no false verdicts | `bash <phase>/scripts/gate-order-controls-200.sh` | `cases=53 wrong=0 verdict=PASS` | PASS |

The no-flag remote form needs a network build against the public mirror; it was not re-run here and rests on `200-EVIDENCE/candidate-remote-200.txt` and `201-EVIDENCE/candidate-remote-201.txt` (both PASS with control detected) plus the clean-room job that passed in run 42713010358.

### Probe Execution

No `probe-*.sh` is declared by this phase. Step 7c: SKIPPED (no declared probes).

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| ----------- | ----------- | ----------- | ------ | -------- |
| REL-08 | 200-01, 200-02, 200-03, 200-04, 200-05, 200-08, 200-09 | Default iOS generation (both forms) builds; regression test; byte-identical declared output; CI build gate with in-run negative control, measured before blocking | SATISFIED | Truths 1 and 2; REQUIREMENTS.md marks `[x]` and the traceability table says Complete |
| REL-09 | 200-04 to 200-09 | 0.2.13 released core first; COMPLETE run (as amended, 0.2.14); ledger line on main; 0.2.12 run, issue 281 and PR 280 dispositioned; Hex retire left to its own gate; threadline released or deferred with condition and receiver | SATISFIED (as amended) | Truths 3, 4, 5; the receiver is "a new plan" (see advisory) |

No orphaned requirements: REQUIREMENTS.md maps only REL-08 and REL-09 to Phase 200 and both appear in plans.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| ---- | ---- | ------- | -------- | ------ |
| `test/mix/tasks/crosswake_gen_shell_default_references_test.exs` | 57 | type-checker warning, `args == ["--local"]` | Info (advisory) | Test passes; fix by branching on a boolean |
| `script/verify_default_ios_generation_build.sh` | 184 | `XXXXXX` | None | `mktemp` template, not a debt marker |

No TBD, FIXME, XXX debt markers, no stub or hardcoded-empty returns in the modified implementation files.

### Human Verification Required

None. Everything claimed here was checked by a command or a live read; no privileged action remains open for this phase.

### Gaps Summary

No gaps. The status is `passed`. Two things a reader should know: (1) 0.2.13 itself did not end COMPLETE, and the roadmap and REQUIREMENTS say so openly and rest SC3 and the REL-09 clause on the 0.2.14 run; (2) SC5 and the Hex retire of 0.2.12 are open by decision, each with a named owner path, and neither is a defect.

---

_Verified: 2026-11-10T09:00:00Z_
_Verifier: Claude (gsd-verifier)_
