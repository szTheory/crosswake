---
phase: 185-checks-that-cannot-pass-empty
reviewed: 2026-10-16T05:00:00Z
depth: standard
files_reviewed: 15
files_reviewed_list:
  - examples/phoenix_host/test/crosswake_example/phase180_twin_feasibility_test.exs
  - lib/crosswake/proof_lane/twin_producers.ex
  - lib/crosswake/proof_lane/twin_runtime.ex
  - lib/mix/tasks/crosswake.proof_lane.verify_twin.ex
  - script/check_absence_is_not_success.exs
  - script/collection_assertion_ledger.json
  - test/crosswake/doctor/doctor_origin_mode_test.exs
  - test/crosswake/proof/absence_is_not_success_test.exs
  - test/crosswake/proof/phase64_runtime_line_policy_test.exs
  - test/crosswake/proof_lane/twin_journey_test.exs
  - test/crosswake/proof_lane/twin_producers_test.exs
  - test/crosswake/proof_lane/twin_receipt_test.exs
  - test/crosswake/proof_lane/twin_runtime_check_test.exs
  - test/mix/tasks/crosswake_gen_shell_origin_mode_test.exs
  - test/mix/tasks/crosswake_proof_lane_verify_twin_test.exs
findings:
  critical: 0
  warning: 5
  info: 2
  total: 7
status: issues_found
---

# Phase 185: Code Review (25614cf6 over b898e110)

**Candidate:** /private/tmp/crosswake-phase180-impl. `git status --porcelain` was empty before and after. I ran the absence checker (an `elixir` script, no mix) against scratch trees under the session scratchpad and did not run the candidate's test suites.

## Summary

The core moves hold. I could not make the absence checker pass on an empty or partial scope. With the walk-versus-glob comparison in place, these all fail closed:
- an empty test tree;
- a test file in a dot-directory;
- a dangling symlink;
- a dot-named todo;
- a directory named `x.exs` (it is correctly not counted);
- a bare `--root`, an unknown flag, and a missing or non-directory root.

Every route I traced through the lockfile rule needs both lockfiles. That covers `TwinProducers.lock_digests/2`, the observation side, and `VerifyTwin.lock_digests/1`. One missing lockfile no longer produces a join, and the loop floors I read all sit before their loops and test something real.

What is weak:
- The new `:registry_gone` signal is discarded at both production call sites.
- A slow registry is treated as a gone one.
- `--min-test-files` accepts 0 and negative values.
- The lockfile rule differs between the producer path and the verify_twin path in how it treats symlinks.
- One new test is a silent no-op as root.

## Warnings

### WR-01: `:registry_gone` / `:child_still_alive` never reach the verdict, so the new fail-closed result has no production effect

**File:** `lib/mix/tasks/crosswake.proof_lane.verify_twin.ex:76-80`, `lib/crosswake/proof_lane/twin_journey.ex:745`
**Issue:** `conduct(runtime, plan)` is the `try` value and `TwinRuntime.stop_all(runtime)` is in `after`. The result of an `after` clause is thrown away. `finish/2` in the journey calls `TwinRuntime.stop_children(runtime)` as a bare statement. So a run that orphaned an OS process group still exits 0 with "passed". `twin_journey_test.exs` pins the discard as "by design", and `crosswake_proof_lane_verify_twin_test.exs:322` asserts that a run whose registry was killed mid-run still reports `result: passed (exit 0)`. That test pins the false success the phase is meant to remove. The deferral is documented, but the phase title claims the check cannot pass when nothing was verified, and a leaked process is not verified.
**Fix:** Capture the stop result and fold it into the verdict. For example:
```elixir
result = try do conduct(runtime, plan) after stop = TwinRuntime.stop_all(runtime) end
```
Fold a non-`:ok` stop into `:blocked` with a safe cause such as `:cleanup_incomplete`, and flip the test at line 322 to expect the block. If the deferral stands, add a tracked item with an owner and make the Phase 188 reopen condition checkable.

### WR-02: A registry call timeout is read as "gone", and then `stop_all` stops the registry, which really does orphan children

**File:** `lib/crosswake/proof_lane/twin_runtime.ex:244-248`, `:256-266`
**Issue:** `tracked_children/1` catches every `:exit`, including the 5 s `Agent.get` default timeout. A busy or slow registry then returns `:gone`, so `stop_children` terminates nothing. `stop_all` goes on to call `Agent.stop(registry)`, which discards the child list for processes that are still running. The comment says the timeout case is "accepted", but this turns a transient delay into the exact orphan the change is meant to prevent. It is also reported through the discarded channel from WR-01.
**Fix:** Separate `{:exit, {:noproc, _}}` and `{:exit, {:normal | :shutdown, _}}` (gone) from `{:exit, {:timeout, _}}`. For a timeout, retry with a longer timeout, or return `{:error, :child_still_alive}` and do not stop the registry.

### WR-03: `--min-test-files` accepts 0 and negative values, so the pin can be disabled from the command line

**File:** `script/check_absence_is_not_success.exs:135-138`, `:458`
**Issue:** `OptionParser` accepts any integer. I ran `--min-test-files 0` and `--min-test-files -3` against a one-file tree. Both printed `OK ... pin 0` / `pin -3` and exited 0. The flag is not limited to fixtures. It overrides the real repo's pin of 249 for any caller, and `length(actual) >= min` is true for every `min <= 0`. This is the floor the phase adds, with a flag that removes it silently.
**Fix:** Reject `min_test_files < 1` with `usage_fail` (exit 2). Better, only allow the override to lower the pin when `--root` differs from the repo root. At the least, print `pin overridden` in the OK line.

### WR-04: Lockfile symlink handling differs between the two lockfile rules

**File:** `lib/crosswake/proof_lane/twin_producers.ex:1471-1473`, `:1488-1491` versus `lib/mix/tasks/crosswake.proof_lane.verify_twin.ex:230-246`
**Issue:** `VerifyTwin.lock_digests/1` requires `File.lstat` type `:regular`, so a symlinked lockfile blocks. `TwinProducers.lock_digests/2` and `observe_identities` (line 1598) go through `file_digest/2`, which calls `File.open`. That follows symlinks, so a `mix.lock` symlinked to a file outside the candidate, or to a different file, is hashed as the identity. `journey_plan` is the real production path, and it uses the producer rule. `clean_tree` only sees the symlink itself, not its target, so the target can change between freeze and observation without making the tree dirty. A FIFO at a lockfile path would also hang `File.open`.
**Fix:** In `file_digest/2` (or in `lock_digests/2` and the observation reads), check `File.lstat` and require `type: :regular` before opening, the same as verify_twin. Add a symlinked-lockfile case to `twin_producers_test.exs`.

### WR-05: The unreadable-lockfile test is a silent no-op when run as root

**File:** `test/mix/tasks/crosswake_proof_lane_verify_twin_test.exs:566-583`
**Issue:** The `if uid == 0 do :ok` branch makes the test pass with zero assertions. That is absence scored as success, in the phase about removing it. As root, the unreadable-lockfile rule is untested and the test still reports green.
**Fix:** Use `@tag :skip` or `ExUnit.skip` for root (or `flunk` if root is a supported CI user). Or inject the failure through the `:file_digest` seam, as `twin_producers_test.exs` already does, so it runs for every user.

## Info

### IN-01: The absence checker is enforced only through its own ExUnit test

**File:** `script/check_absence_is_not_success.exs` (no reference in `.github/`, `mix.exs`, or any alias)
**Issue:** I grepped `.github`, `mix.exs`, `script` and `package.json`. Nothing runs the script except `absence_is_not_success_test.exs` and the ledger inventory comments. If that test is excluded or tagged out, the check disappears silently. This is acceptable only if the test is part of the default suite.
**Fix:** Confirm the test is not excluded by a tag in `test_helper.exs`, or add the script to the CI lane.

### IN-02: Fail-closed false blocks and weak pins on the planning scopes

**File:** `script/check_absence_is_not_success.exs:67-72`, `:195-205`
**Issue:**
- The `fold_files` walk counts a dangling symlink as a regular file. The glob side drops it via `File.regular?`, so one committed dangling `*.exs` or any dot-named file blocks the checker with "proper subset". That is the safe direction, but the message does not say why.
- The `todos`, `seeds` and `deferred-items` pins are 1. Removing all but one of them stays green, unlike test-files at 249.
- Add-50-delete-50 on test-files stays green, as the file's own comment admits.

**Fix:** Include the first missing path in the "proper subset" message. Consider pinning the planning scopes to measured counts at the final commit.

---

_Reviewed: 2026-10-16_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
