---
phase: 190-fix-warnings-before-landing
reviewed: 2026-10-19T00:00:00Z
depth: standard
files_reviewed: 21
files_reviewed_list:
  - lib/crosswake/proof_lane/git_pins.ex
  - lib/crosswake/proof_lane/provenance.ex
  - lib/crosswake/proof_lane/twin_producers.ex
  - lib/crosswake/proof_lane/physical_iphone_preflight.ex
  - lib/crosswake/proof_lane/twin_runtime.ex
  - lib/mix/tasks/crosswake.proof_lane.verify_twin.ex
  - script/check_absence_is_not_success.exs
  - test/crosswake/proof_lane/provenance_test.exs
  - test/crosswake/proof_lane/twin_runtime_check_test.exs
  - test/mix/tasks/crosswake.proof_lane.physical_iphone_test.exs
  - test/mix/tasks/crosswake_proof_lane_verify_twin_test.exs
  - .planning/workstreams/quality-ratchet-release/phases/190-fix-warnings-before-landing/scripts/locate-190.sh
  - .planning/workstreams/quality-ratchet-release/phases/190-fix-warnings-before-landing/scripts/ensure-work-190.sh
  - .planning/workstreams/quality-ratchet-release/phases/190-fix-warnings-before-landing/scripts/suite-gate-190.sh
  - .planning/workstreams/quality-ratchet-release/phases/190-fix-warnings-before-landing/scripts/recovery-snap-190.sh
  - .planning/workstreams/quality-ratchet-release/phases/190-fix-warnings-before-landing/scripts/scan-privacy-190.sh
  - .planning/workstreams/quality-ratchet-release/phases/190-fix-warnings-before-landing/scripts/selftest-scan-190.sh
  - .planning/workstreams/quality-ratchet-release/phases/190-fix-warnings-before-landing/scripts/git-pinned-190.sh
  - .planning/workstreams/quality-ratchet-release/phases/190-fix-warnings-before-landing/scripts/run-once-05-190.sh
  - .planning/workstreams/quality-ratchet-release/phases/190-fix-warnings-before-landing/scripts/selftest-190.sh
  - .planning/workstreams/quality-ratchet-release/phases/190-fix-warnings-before-landing/scripts/gitpin-compare-190.sh
findings:
  critical: 0
  warning: 11
  info: 4
  total: 15
status: issues_found
---

# Phase 190: Code Review Report

**Reviewed:** 2026-10-19
**Depth:** standard
**Files Reviewed:** 21 (11 candidate files changed by the four FIX commits, read in the work clone at HEAD 2faf15a2, plus 10 phase scripts; the 10 scripts are counted as 10 files, with the two shell helpers git-pinned-190.sh and gitpin-compare-190.sh both included)

## Summary

The four FIX commits do what the decisions asked, and the shared git environment is consistent: the shell helper, the shared Elixir module, the twin source probe and provenance all unset every inherited GIT_ name and then apply the same scrub list, fixed values and pins. The guard pin (253) matches a separate count of test files at HEAD. No finding rises to BLOCKER: nothing here corrupts data or opens a security hole.

The weaknesses cluster in three places. First, the registry-timeout fix covers only the first registry read, and the new verdict note covers only one of three stop results; the others still degrade silently. Second, several new tests and self-tests can pass without proving the thing they name (no positive control, no wiring test, no per-class control). Third, a few phase scripts can pass while checking nothing (a missing lsof, a mistyped git folder, an unvalidated baseline).

The two known items (the real-mode mix path text comparison, and the unformatted native_shell_upgrade_test.exs) are not repeated.

## Warnings

### WR-01: Only :registry_timeout reaches the verdict; :child_still_alive and :registry_gone still degrade silently, and a kept registry has no later reaper

**File:** `lib/mix/tasks/crosswake.proof_lane.verify_twin.ex:94-100`, `lib/crosswake/proof_lane/twin_runtime.ex:279`, `test/mix/tasks/crosswake_proof_lane_verify_twin_test.exs:752`
**Issue:** `annotate_stop/2` rewrites the verdict only for `{:error, :registry_timeout}`. A child that survives TERM and KILL (`{:error, :child_still_alive}`) or a registry that vanished while it might own children (`{:error, :registry_gone}`) leaves the verdict untouched. The test "every other stop result returns the verdict unchanged" writes that behaviour down as intended. Separately, `stop_all/1` now keeps the registry alive after `:child_still_alive` and `:registry_timeout` "so a later stop_all can reap the children", but the registry is started with `Agent.start` (unlinked, line 97) and `verify_twin` never calls stop_all a second time. In the Mix task the VM exits, so the child is orphaned either way; in any in-VM caller the registry process leaks.
**Failure scenario:** A twin child ignores TERM and KILL (not a process-group leader). stop_all returns `{:error, :child_still_alive}`, the task prints "result: passed (exit 0)" with "first cause: none" and no hint that a process is still running on the proof port. The next run fails on a busy port with no pointer to the cause.
**Fix:** Annotate all three non-ok stop results (distinct note per result), keep the exit code decision explicit, and either retry stop_all once from verify_twin or document that the kept registry is only for in-VM callers. Replace the "unchanged" test with one assertion per result.

### WR-02: Registry timeouts are handled for one read only; later registry calls can still exit uncaught

**File:** `lib/crosswake/proof_lane/twin_runtime.ex:171, 194, 339, 255`, `lib/mix/tasks/crosswake.proof_lane.verify_twin.ex:76-87`
**Issue:** `tracked_children/1` now uses `registry_timeout_ms` and catches a timeout, but `mark_exited/2` (line 339, called from `terminate/2` and line 194) and the registration update (line 171) still use `Agent.update` with the default 5 000 ms and no catch. If the registry answers the first read and then stalls, the exit propagates out of `stop_children/1` and `stop_all/1`, so the origin listener is never closed and the registry is never reported. In `verify_twin`, the `else` branch calls `stop_all` outside the try, so the raise discards the already-computed verdict (the receipt is written, the console gets a stack trace instead of the four-line verdict). In the `catch` branch a raise from `stop_all` replaces the original error.
**Failure scenario:** Registry is busy for 6 s between the read and the first `mark_exited`; the Mix task crashes after writing the receipt and prints no result line.
**Fix:** Route every registry call through one helper that takes the configured timeout and maps a timeout exit to `:registry_timeout`; wrap `stop_all` in the task so a raise still yields a verdict line (and, in the catch branch, preserves the original exception).

### WR-03: Provenance now needs git 2.40 or newer, with no version guard, and one new test passes vacuously on older git

**File:** `lib/crosswake/proof_lane/provenance.ex:60-82`, `lib/crosswake/proof_lane/git_pins.ex:43` (the `--attr-source` pin), `test/crosswake/proof_lane/provenance_test.exs:135-150`
**Issue:** Every provenance git call now carries `--attr-source=<empty tree>`, which older git rejects. The twin funnel has a `{2, 41}` minimum-version check; provenance has none, and every failure maps to the `git-unknown` sentinel. The test "a hostile global git config cannot make a dirty tree read as clean" asserts only `== "git-unknown"` and has no positive control in the same test, so on a machine with an older git (for example the system git shipped with some Xcode command line tools) it passes while proving nothing, and so would any other test that expects the sentinel.
**Failure scenario:** On a developer machine with git 2.39, all real proof headers silently become `git-unknown`; the hostile-config test stays green.
**Fix:** Check the git version once (reuse the funnel's minimum) and return a distinguishable cause, or drop the pin where not needed for status. In the test, add a clean-repo assertion for the same environment (`commit_ref(dir) == "git-" <> head` before dirtying the file) so the sentinel can only come from the dirty detection.

### WR-04: A nested host is indistinguishable from "no git", so monorepo hosts can never carry a commit

**File:** `lib/crosswake/proof_lane/provenance.ex:60-70, 94-101`, caller `lib/mix/tasks/crosswake.proof_lane.verify_navigation_shell.ex:104`
**Issue:** The caller passes `File.cwd!()`. With the new toplevel check, any host whose project folder is a subfolder of the repository (the repo's own example host, or an adopter with the app in a subfolder) always gets `git-unknown`, the same value as "no repository" or "dirty tree". The validator accepts that sentinel only for advisory evidence, so non-advisory evidence from such a host can no longer be produced, and the operator sees no reason.
**Failure scenario:** An adopter keeps the Phoenix app under apps/web; the physical-device evidence run is rejected as advisory-only with a header that looks like a missing git checkout.
**Fix:** Keep the refusal (D-07) but surface a distinct cause string (for example in the command output) when the toplevel differs from the folder, and document the supported layout. If monorepos are in scope, accept the enclosing commit only when the subfolder path is explicitly allowed by the caller.

### WR-05: An existing route_activation.json that parses but has no usable origin still passes the physical-iPhone preflight

**File:** `lib/crosswake/proof_lane/physical_iphone_preflight.ex:186-201`
**Issue:** `activation_refusal/1` only requires that `Jason.decode/1` succeeds. `null`, `[]`, `{}`, `{"origin": 5}` or an origin that does not canonicalize all decode fine, then `IOSHostOriginMode.observe_activation/1` maps them to `:none` (it requires a map with a binary "origin" that canonicalizes). The file therefore counts as "readable" and contributes no loopback signal, which is the same silent pass the FIX-07 decision was meant to close ("cannot be read or parsed").
**Failure scenario:** A hand-edited or truncated-then-repaired activation file holds `{"origin": ["http://127.0.0.1:4790"]}`; the preflight passes and a device proof can start against a host whose origin was never inspected.
**Fix:** Require a map with a binary "origin" that canonicalizes to a scheme and host, else return the unreadable-activation reason. Add a test for a valid-JSON-wrong-shape file.

### WR-06: The new verdict annotation is tested only as a pure function; the wiring in run/1 is untested

**File:** `test/mix/tasks/crosswake_proof_lane_verify_twin_test.exs:716-757`, `lib/mix/tasks/crosswake.proof_lane.verify_twin.ex:76-87`
**Issue:** The three annotate_stop tests call the function directly. Nothing exercises the try/catch/else in `run/1`: not that stop_all is called exactly once on success, not that the catch branch still stops children and re-raises with the original stacktrace, not that a timed-out registry in a real run reaches the printed verdict. Replacing `annotate_stop(result, stop_all(...))` with `result` would leave every new test green. The function also pattern-matches on a four-element list and on the literal text "first cause: none", so a change to `summarize/4` silently turns annotation into a no-op through the catch-all clause.
**Fix:** Add a run/1 test with an injected producer and a suspended registry (the runtime test already shows how), and one for the raise path. Derive the "no cause" check from the summarize helper rather than a repeated string.

### WR-07: scan-privacy-190 self-test has no failing control for most hit classes or for binary files

**File:** `.planning/workstreams/quality-ratchet-release/phases/190-fix-warnings-before-landing/scripts/selftest-scan-190.sh:99-106` (S09), `scan-privacy-190.sh:80-90`
**Issue:** Only the home-path class is planted (S09). The credential, temp, uuid, at-sign, user-name, router and doctor classes, the literal HOME match, the binary-file refusal and the neutralisation exemptions have no control. This is the same defect class as 188 WR-08 (a label with no way to fail), repeated in the successor that was written to fix it. S09's redaction check also tests only that the planted content is not echoed, which is trivially true because the report prints the file path and class, never content.
**Failure scenario:** A later edit breaks the credential pattern (for example a quoting slip in the fragment assembly); every control still passes and the scan reports zero hits on files that contain secrets.
**Fix:** Table-drive one planted fixture per class (assembled from fragments so the self-test does not match itself) and assert the exact "hit:" class label; add a binary-file fixture expecting "scan: binary file refused".

### WR-08: Two gate checks in run-once-05-190.sh can pass while checking nothing

**File:** `.planning/workstreams/quality-ratchet-release/phases/190-fix-warnings-before-landing/scripts/run-once-05-190.sh:208, 73`
**Issue:** (a) `l_port` runs `pl=$(lsof ... 2>/dev/null) || pl=` and passes when the output is empty. A missing lsof (exit 127), a permission failure, or a sandbox that hides other users' sockets all look identical to "port free". The self-test stub exits 1 with no output for "free", so no control separates "lsof failed" from "nothing listening". (b) `probe` computes the dirty count as `g status ... | wc -c`, so the pipeline status is wc's and a failing git status yields a count of 0. The later `rev-parse` call usually fails in the same conditions, but the status check on its own asserts nothing when git errors.
**Failure scenario:** On a host without lsof, port_4790_free passes with the port actually occupied; the run then fails inside the twin run instead of at the gate.
**Fix:** Treat exit 127 or any exit other than 0 and 1 from lsof as a failed check, and assert the lsof binary exists; capture status output to a file and test git's exit code before counting. Add controls for both.

### WR-09: suite-gate-190.sh can accept an empty suite, persists an unvalidated baseline, and ignores untracked files

**File:** `.planning/workstreams/quality-ratchet-release/phases/190-fix-warnings-before-landing/scripts/suite-gate-190.sh:9, 15, 22-24, 35-40`
**Issue:** (1) `MIN` defaults to 0, so a non-baseline call without the second argument has no lower bound on the test count; a run that reports "0 tests, 0 failures" with the baseline's excluded count passes. (2) In baseline mode the baseline files are written first and `NN == FAILS` is checked afterwards; on mismatch the script exits 2 but the files remain, and the "baseline exists" guard then refuses every retry until someone deletes them by hand, while a bad baseline stays on disk. (3) Cleanliness uses `git diff --quiet HEAD`, which ignores untracked files, so a stray test file in the work clone is run and counted. (4) The git calls are not pinned (the same hazard FIX-03 fixed elsewhere): a global fileMode=false setting hides mode changes. (5) Baseline mode never checks that HEAD equals the recorded base commit.
**Fix:** Require MIN (exit 2 when absent or 0); validate before writing and write via a temp file then rename; add an untracked-file check using the shared pinned helper; compare baseline HEAD to the base commit.

### WR-10: recovery-snap-190.sh can compare two empty snapshots, and it cannot see index or object changes

**File:** `.planning/workstreams/quality-ratchet-release/phases/190-fix-warnings-before-landing/scripts/recovery-snap-190.sh:5-17`
**Issue:** `G=${REC_GIT:?}` checks only that the variable is non-empty. If it names a folder that does not exist, the failing redirections and the failed cd print blank digests and the script still exits normally, so a before and an after snapshot taken with a wrong path are identical. Even with a correct path the snapshot covers HEAD, packed-refs, loose refs, the stash log, worktrees and config, but not the index, the HEAD reflog, hooks or the object store, so a staging operation or a gc inside the frozen checkout would not change the digests, which weakens the claim "recovery checkout shows no git change".
**Fix:** Fail when the folder, HEAD or config is missing; add digests of the index file, the HEAD reflog and a file-count of the object store; state in the output which areas are covered.

### WR-11: locate/ensure-work source a code file from a predictable shared temp folder without an ownership check, and ensure-work uses unpinned git

**File:** `.planning/workstreams/quality-ratchet-release/phases/190-fix-warnings-before-landing/scripts/locate-190.sh:5-7, 45`, `ensure-work-190.sh:16`
**Issue:** The env file is written under a fixed folder in the shared temp area and then executed by every other script through the shell's dot command. `--ensure` keeps an existing file without checking that it, or its folder, is owned by the current user or that the mode is private; the folder is created with 0700 only when absent. On a shared machine another user can pre-create the folder and plant the file. ensure-work's "unchanged work clone" test (`git diff --quiet HEAD`, `git diff --cached --quiet`) runs with the caller's global git config and ignores untracked files, which is the hazard the phase's own pinned helper exists to remove, and a recreated clone is not compared to the durable candidate's HEAD afterwards.
**Fix:** Verify owner and mode of the folder and file before sourcing (or regenerate unconditionally), and use the pinned helper plus an untracked-file check; compare the recreated clone's HEAD to the durable candidate.

## Info

### IN-01: twin_producers re-implements GitPins.spawn_env/0

**File:** `lib/crosswake/proof_lane/twin_producers.ex:787-796`, `lib/crosswake/proof_lane/git_pins.ex:68-74`
**Issue:** The funnel copies the "unset every inherited GIT_ name, then apply the env" logic that GitPins.spawn_env/0 now provides (with an extra step for the per-call index file). The two can drift, which defeats the point of one shared environment. The drift check in gitpin-compare-190.sh compares only the static lists.
**Fix:** Give spawn_env an extra-env argument and call it from both places.

### IN-02: Credential class in the privacy scan is case-sensitive

**File:** `.planning/workstreams/quality-ratchet-release/phases/190-fix-warnings-before-landing/scripts/scan-privacy-190.sh:25, 83`
**Issue:** The pattern matches lower-case spellings only, so capitalised or upper-case forms are not reported. It is inherited from the 188 scan but is a gap in a scan whose purpose is to catch leaks.
**Fix:** Use case-insensitive matching for that one class and add a control (see WR-07).

### IN-03: The gate deadline is checked only after every step has finished

**File:** `.planning/workstreams/quality-ratchet-release/phases/190-fix-warnings-before-landing/scripts/run-once-05-190.sh:262-266`
**Issue:** A hung compile or preflight never reaches the deadline test; the 45-minute limit only classifies a gate that already finished. The self-test (C31) covers the slow-but-finishing case only.
**Fix:** Run the slow steps under a timeout, or state in the script header that the deadline is advisory.

### IN-04: Origin check passes when the generated shell folder is missing, and self-tests hard-code counts

**File:** `lib/crosswake/proof_lane/physical_iphone_preflight.ex:160-163`, `.planning/workstreams/quality-ratchet-release/phases/190-fix-warnings-before-landing/scripts/selftest-190.sh:(c26 check count 30, final count 44)`
**Issue:** A missing generated shell folder skips the unreadable-input refusal and falls through to `observe/2`, which treats missing files as no signal; this matches the documented behaviour but means a typo in the shell root path passes the origin check (other preflight checks must catch it). The self-test hard-codes 30 labels and 44 controls instead of deriving them, so adding a label fails the self-test for the wrong reason.
**Fix:** Confirm another preflight rule fails closed for a missing shell folder and add a test that pins that; derive the counts from the same label derivation the coverage check already uses.

---

_Reviewed: 2026-10-19_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
