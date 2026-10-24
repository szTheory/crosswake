---
phase: 192-pr-ci-and-merge
reviewed: 2026-10-23T00:00:00Z
depth: standard
files_reviewed: 20
files_reviewed_list:
  - .planning/workstreams/quality-ratchet-release/phases/192-pr-ci-and-merge/scripts/common-192.sh
  - .planning/workstreams/quality-ratchet-release/phases/192-pr-ci-and-merge/scripts/push-192.sh
  - .planning/workstreams/quality-ratchet-release/phases/192-pr-ci-and-merge/scripts/privacy-192.sh
  - .planning/workstreams/quality-ratchet-release/phases/192-pr-ci-and-merge/scripts/gh-shim-192.sh
  - .planning/workstreams/quality-ratchet-release/phases/192-pr-ci-and-merge/scripts/ci-poll-192.sh
  - .planning/workstreams/quality-ratchet-release/phases/192-pr-ci-and-merge/scripts/merge-gate-192.sh
  - .planning/workstreams/quality-ratchet-release/phases/192-pr-ci-and-merge/scripts/postmerge-192.sh
  - .planning/workstreams/quality-ratchet-release/phases/191-integration-branch-and-local-suite/scripts/scan-191.sh
  - lib/crosswake/proof_lane/twin_runtime.ex
  - lib/crosswake/proof_lane/twin_producers.ex
  - lib/crosswake/proof_lane/twin_fault_boundary.ex
  - lib/crosswake/release_candidate/artifact.ex
  - script/verify_repository.mjs
  - test/test_helper.exs
  - test/mix/tasks/crosswake_gen_shell_host_test.exs
  - test/crosswake/shell/ios_host_migration_security_test.exs
  - test/crosswake/proof_lane/twin_journey_test.exs
  - test/crosswake/proof_lane/twin_producers_test.exs
  - test/js/repository_verification.test.mjs
  - .github/workflows/crosswake-ci.yml
findings:
  critical: 0
  warning: 8
  info: 6
  total: 14
status: issues_found
---

# Phase 192: Code Review Report

**Reviewed:** 2026-10-23
**Depth:** standard
**Files Reviewed:** 20 (selftests skimmed for piped-exit and tautology patterns only)
**Status:** issues_found

## Summary

The landing gates (push, CI poll, merge gate, post-merge verifier) are mostly fail-closed: every
read failure maps to exit 2, the merge argv is allow-listed, the binding is consumed before the write,
and post-merge re-derives parents, tree and compare status from GitHub. No blocker was found. The
real weak spots are (1) the new failure-tail masking in `verify_repository.mjs` demonstrably leaks
bearer tokens and `AWS_SECRET_ACCESS_KEY`-style values into public CI logs, (2) the `os_pid = nil`
change in `TwinRuntime` was not followed through to its consumer in `TwinFaultBoundary`, (3) the new
`requires_xcodebuild` exclusion removes coverage that no macOS lane replaces, and (4) the post-merge
"other push runs are green" check can be satisfied by an empty set. Hand-checked: the scan-191 WR-03
fix is correct (`git notes list` and `cat-file` now `fail`).

## Warnings

### WR-01: Failure-tail credential masking leaks bearer tokens and `*_SECRET_ACCESS_KEY` values

**File:** `script/verify_repository.mjs` (`rootProofFailureTail`, the two `.replace` calls added in 24c4ca0c)
**Issue:** The generic mask `(authorization|bearer|token|secret|password|api[_-]?key)(["':=\s]+)[^\s"']{6,}` consumes the first non-space token after the keyword. I ran the function: `Authorization: Bearer eyJhbGciOi...` prints `Authorization: *** eyJhbGciOi...`, because the word `Bearer` itself is taken as the value, so the token survives. `AWS_SECRET_ACCESS_KEY=wJalr...` is printed unmasked, because `secret` is followed by `_`, not a separator. `COOKIE: session=...` is also unmasked. The output goes to the public Actions log on every root-proof failure, and the 9f33c071 follow-up widened it to include ExUnit failure details, which echo assertion values. The unit test only covers `token=xxxxxxxxxxxx` and a `ghp_` literal, so it cannot see these gaps.
**Fix:** Mask the whole credential line shape instead of the next word, and test it with the shapes above:
```js
.replace(/(authorization\s*[:=]\s*(?:bearer|basic|token)?\s*)\S+/gi, "$1***")
.replace(/\b([A-Z0-9_]*(?:TOKEN|SECRET|PASSWORD|PASSWD|API_?KEY|ACCESS_?KEY|PRIVATE_?KEY)[A-Z0-9_]*)(\s*[:=]\s*)[^\s"']+/gi, "$1$2***")
```
Add test cases for `Authorization: Bearer <jwt>`, `AWS_SECRET_ACCESS_KEY=...` and a short (under 6 character) value.

### WR-02: `os_pid: nil` is not handled by `TwinFaultBoundary.verify_upstream_owner/2`

**File:** `lib/crosswake/proof_lane/twin_fault_boundary.ex:131,746-754`, caller `lib/crosswake/proof_lane/twin_journey.ex:246`
**Issue:** 9f33c071 made `start_child/3` return `os_pid: nil` for a child whose port is already closed, and updated `alive?/1` only. `twin_journey.ex:246` still passes `child.os_pid` straight into `verify_upstream_owner`. If `lsof` then finds any listener on the port, `owned?/2` takes its second clause and calls `Integer.to_string(nil)`, which raises `ArgumentError` instead of returning `{:blocked, :backend_listener_not_owned}`. This is a crash where the contract is a typed denial (the AGENTS.md rule is explicit denial, not degradation). A dead backend with a foreign listener on its port is exactly the case this guard exists for.
**Fix:** Treat a missing pid as not owned:
```elixir
defp owned?(_pid, nil), do: false
defp owned?(pid, os_pid) when pid == os_pid, do: true
```
and add a test that passes `os_pid: nil` with a foreign listener. Widen the `@spec`s and the `verify_upstream_owner` docs.

### WR-03: `requires_xcodebuild` exclusion leaves no lane that runs the excluded tests

**File:** `test/test_helper.exs` (new `:requires_xcodebuild` block); `test/mix/tasks/crosswake_gen_shell_host_test.exs`; `test/crosswake/shell/ios_host_migration_security_test.exs` (`assert_xcode_bundle_ids/2`)
**Issue:** The exclusion is "exclude whenever `xcodebuild` is missing", with no counterpart. I checked `crosswake-ci.yml`: the macOS jobs (`ios-package-unit`, the generated-shell jobs at `macos-15`) run `script/verify_generated_ios_shell.sh`, not `mix test --only requires_xcodebuild`. So after CI-FIX-1 the generated-host build test and the Xcode bundle-identifier read run only on a developer's Mac, and nothing reports that they were skipped. `assert_xcode_bundle_ids` also returns `:ok` silently when Xcode is absent. This is the repo's recurring "absence scored as success" defect. A Mac with only Command Line Tools silently skips the tests too.
**Fix:** Add a macOS CI step (`mix test --only requires_xcodebuild`, with `xcodebuild` asserted present so the lane cannot be empty), or have the exclusion print the count of excluded tests and fail on `CI=true` when the host is `Darwin` and the tag was excluded.

### WR-04: Post-merge "other push runs are green" is vacuous when sibling runs are not yet created

**File:** `.planning/workstreams/quality-ratchet-release/phases/192-pr-ci-and-merge/scripts/postmerge-192.sh` (poll loop and `NOTH`/`NOGR` check, about lines 120-160)
**Issue:** The loop exits as soon as a Release Please run is `completed` and `PEND` (non-advisory runs not completed) is 0. Runs that GitHub has not yet queued are invisible, so `PEND` is 0 and `NOTH == NOGR` holds as `0 == 0` or as a partial set. Evidence line `other_push_runs N green N` and `main_green yes` then assert more than was observed. No expected set is compared.
**Fix:** Record the expected push-triggered workflow names (from the merge commit's `.github/workflows/*.yml` with `on: push`, or from the pre-merge baseline) and require each to appear and be `success` before `main_green yes`. Failing that, require `NOTH >= 1` and wait one extra poll interval after the last new run appears.

### WR-05: CI evidence hard-codes facts the poller never proved

**File:** `.planning/workstreams/quality-ratchet-release/phases/192-pr-ci-and-merge/scripts/ci-poll-192.sh` (evidence block, `required_set ok`, `ran_on synthetic_merge`, `run_event pull_request`)
**Issue:** `ran_on synthetic_merge` is a literal. The script reads `merge_commit_sha` after the run finished and checks its parents are `MAIN_SHA` and the head, but GitHub regenerates the preview merge commit on demand, so this SHA is not shown to be the one the run checked out (`refs/pull/N/merge` at run time). Post-merge later compares the merged tree to this recorded tree, so a mismatch would surface only at that point, after the merge is irreversible. `required_set ok` is likewise a literal from an earlier read in the same invocation, not re-read at completion.
**Fix:** Take the workflow run's `GITHUB_SHA` for the PR merge ref (for example from a job step annotation or `gh api .../actions/runs/ID` `head_commit` plus the checkout log) and compare it with `SYN`; otherwise rename the evidence line to `synthetic_merge_at_read` and drop `ran_on`. Re-run `req_core` immediately before writing the record.

### WR-06: `push-192.sh` mis-classifies causes and reports uncertain delivery as "not delivered"

**File:** `.planning/workstreams/quality-ratchet-release/phases/192-pr-ci-and-merge/scripts/push-192.sh` (`cause_word`, and the push-mode tail)
**Issue:** (a) `grep -Eiq '...|403|...'` is unanchored. `git push --porcelain` prints `old..new` abbreviated SHAs on fast-forward, so any hex run containing `403` is classified `auth`. About one in ten fast-forwards will hit this (two of the three real pushes were fast-forwards). The cause is written to the permanent evidence line. (b) When the push exits 0 or non-zero but the post-push `live_ref` read fails (`RA=unread`), the script prints `not delivered` and records `result failed`. That is delivery-uncertain, the same case the merge gate reports with exit 3. The next operator step ("never repeat") then depends on a wrong statement.
**Fix:** Match `HTTP 403|error: 403|The requested URL returned error: 403` and drop bare `403`. Add `if [ "$RA" = unread ]; then record uncertain; echo "push: delivery uncertain"; exit 3; fi` before the failed branch.

### WR-07: `privacy-192.sh` has no device-identifier or bearer-header class, though `scan-191.sh` has one

**File:** `.planning/workstreams/quality-ratchet-release/phases/192-pr-ci-and-merge/scripts/privacy-192.sh` (pattern block, about lines 40-52)
**Issue:** `scan-191.sh` has `P_UDID` (`[0-9A-F]{8}-[0-9A-F]{16}`). The Phase 192 gate for public PR text and evidence does not, and the phase scope is explicit that device identifiers must not reach logs or evidence. It also has no `Authorization:`/`Bearer` class and no generic `*_TOKEN=` assignment (`CK` lists only Hex, Maven and signing keys; `GITHUB_TOKEN`/`GH_TOKEN` are covered only when the value has a known `gh*_` prefix of 36+ characters). `P_CRED` exempts values starting with `$ { ( <` and requires 8+ characters.
**Fix:** Copy `P_UDID` and add `Authorization:[[:space:]]*(Bearer|Basic)[[:space:]]+[A-Za-z0-9._~+/=-]{12,}` and `[A-Z_]*(TOKEN|SECRET)[A-Z_]*=` with a 6 character floor. Add selftest controls for each.

### WR-08: `gh-shim-192.sh` stub pipes `jq` into `jq` and returns the last status

**File:** `.planning/workstreams/quality-ratchet-release/phases/192-pr-ci-and-merge/scripts/gh-shim-192.sh` (stub body, `--json` branch: `jq -c ... | jq -r "$JQE"; exit $?`)
**Issue:** The first `jq` can fail on a corrupt or truncated scenario file while the second `jq` reads empty input and exits 0 with no output. The test double then reports success with empty output, so a selftest control can pass while exercising nothing (the repo's piped-exit lesson). `SCEN=__SCEN__` is also substituted unquoted, which breaks on a path with a space.
**Fix:** Write the first stage to a temp file, check `$?`, then run the second `jq`; quote the substitution: `SCEN='__SCEN__'`.

## Info

### IN-01: `start_child/3` still rescues every exception as `prerequisite_missing`; a nil-pid child's descendants are never signalled

**File:** `lib/crosswake/proof_lane/twin_runtime.ex:162-190`
**Issue:** The race fix removed one cause, but the blanket `rescue _ ->` still turns any raise (registry `Agent` failure, bad `:cd`) into "install the missing executable". For a child whose port closed early, `alive?(nil)` is false, so `terminate/2` sends no group signal; a wrapper that forks a long-lived descendant and exits at once would leave that descendant running. Harmless for `sqlite3`/`lsof`, but the function is generic.
**Fix:** Rescue only `ErlangError` from `Port.open/2`, and when `os_pid` is nil, still attempt cleanup through the wrapper's group id if the wrapper reports it.

### IN-02: PR #242 body is stale against the merged head

**File:** `.planning/workstreams/quality-ratchet-release/phases/192-pr-ci-and-merge/192-EVIDENCE/pr-body-192.md`
**Issue:** The public body links `191-VERIFICATION.md` at `4a6c1af2`, says the privacy scan is clean "at this head", and counts 114 commits. The PR merged at `9f33c071` after three more commits (117). The push log shows each head was rescanned (binding pass), so the claim holds in substance, but the text was never edited (`gh-writes-192.txt` has no `pr edit`). It also records that the adopter-term check was skipped (A-14), so "clean" excludes the adopter identity check.
**Fix:** State the final head and commit count in the phase summary; keep the A-14 caveat in the Phase 193 hand-off.

### IN-03: scan-191 notes scan covers only the default notes ref

**File:** `.planning/workstreams/quality-ratchet-release/phases/191-integration-branch-and-local-suite/scripts/scan-191.sh` (notes block, `git notes list`)
**Issue:** The WR-03 fix is correct. Two neighbours remain: `git notes list` reads only `refs/notes/commits`, so other notes refs are never scanned, and `append_units` ends in an `awk` whose status is not checked.
**Fix:** Iterate `git for-each-ref refs/notes` with `git notes --ref=... list`, and append `|| fail "awk failed"` to the `awk` in `append_units`.

### IN-04: Failure-tail bounds count characters and `read_rows` keeps raw sqlite3 text

**File:** `script/verify_repository.mjs` (`ROOT_PROOF_*_BYTES` slices); `lib/crosswake/proof_lane/twin_producers.ex` (`bounded_text/1`)
**Issue:** `.length`/`.slice` bound UTF-16 units, not bytes as the constants say. `bounded_text/1` keeps the first 200 bytes of sqlite3's own message, and newer `sqlite3` builds put the database path in "unable to open database" errors; the path (a temp or home path) then travels in `{:error, {:rows_unavailable, ...}}` and into CI failure output.
**Fix:** Use `Buffer.byteLength` for the caps. In `bounded_text/1`, replace occurrences of `database_path` with `"<db>"` before truncating.

### IN-05: `privacy-192.sh` account match is word-bounded and case-insensitive on a short name

**File:** `.planning/workstreams/quality-ratchet-release/phases/192-pr-ci-and-merge/scripts/privacy-192.sh` (`probe account`)
**Issue:** The local account name is matched as `-i -w -F`. A short or common account name will false-positive on ordinary prose; a hit costs a re-run only, but a team that learns to ignore the label weakens the gate. Email matching also flags retina-image file names (a name with an at sign before a size suffix).
**Fix:** Keep it (fail-closed is right), but print the file index only (already done) and document the expected noise in the script header.

### IN-06: `ci-history-192.txt` holds a duplicated line

**File:** `.planning/workstreams/quality-ratchet-release/phases/192-pr-ci-and-merge/192-EVIDENCE/ci-history-192.txt`
**Issue:** The `24c4ca0c` / run `40029165177` line appears twice (the poller appends on every `wait` completion, and was re-run on the same finished head). Harmless, but the append is not idempotent and the count of rounds is inferred by line count elsewhere.
**Fix:** Skip the append when `head`, `check_run` and `run` already appear in the file.

---

_Reviewed: 2026-10-23_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
