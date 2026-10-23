---
phase: 188-freeze-and-twin-05
reviewed: 2026-10-16T00:00:00Z
depth: standard
files_reviewed: 9
files_reviewed_list:
  - .planning/workstreams/quality-ratchet-release/phases/188-freeze-and-twin-05/scripts/run-once-05.sh
  - .planning/workstreams/quality-ratchet-release/phases/188-freeze-and-twin-05/scripts/selftest-188.sh
  - .planning/workstreams/quality-ratchet-release/phases/188-freeze-and-twin-05/scripts/freeze-check-188.sh
  - .planning/workstreams/quality-ratchet-release/phases/188-freeze-and-twin-05/scripts/make-identity-188.sh
  - .planning/workstreams/quality-ratchet-release/phases/188-freeze-and-twin-05/scripts/refresh-handoffs-188.sh
  - .planning/workstreams/quality-ratchet-release/phases/188-freeze-and-twin-05/scripts/selftest-188-records.sh
  - .planning/workstreams/quality-ratchet-release/phases/188-freeze-and-twin-05/scripts/assert-twin-05.sh
  - .planning/workstreams/quality-ratchet-release/phases/188-freeze-and-twin-05/scripts/scan-privacy-188.sh
  - .planning/workstreams/quality-ratchet-release/phases/188-freeze-and-twin-05/scripts/selftest-188-result.sh
findings:
  critical: 0
  warning: 8
  info: 3
  total: 11
status: issues_found
---

# Phase 188: Code Review Report

**Reviewed:** 2026-10-16
**Depth:** standard
**Files Reviewed:** 9 (selftest-188-records.sh skimmed for structure only)
**Status:** issues_found

## Summary

The gate and sentinel logic in run-once-05.sh is sound on its core promise: the `set -C` sentinel is atomic, the gate record is written noclobber, `verify_twin` is invoked exactly once with the same argument vector as the preflight, and non-pass or not_run labels all count as no-go. No blocker was found in the executed path. The weaknesses are in what the gate and the post-run tools do not discriminate. Two of them were reproduced: the privacy scan passes an empty or symlink-only directory with "files 0, hits 0" and exit 0, and its credential class is case-sensitive. Because the twin run already passed once, these are WARNINGs about evidence strength and reusability, not defects that invalidate the run.

## Warnings

### WR-01: scan-privacy-188.sh exits 0 when a listed directory yields zero files

**File:** `scripts/scan-privacy-188.sh:28-41,58,91-95`
**Issue:** `n_ent` counts list lines, not expanded files. An empty directory, or one holding only symlinks (`find -type f` does not follow them), expands to nothing. The script prints `scan: files 0 / scan: hits 0` and exits 0, which contradicts the header ("2 = scope error, never a clean pass"). I reproduced this. A mistyped or not-yet-populated run-root directory therefore reads as a clean privacy scan.
**Fix:** After step 2, add `[ "$files" -gt 0 ] || { echo "scan: no files scanned"; exit 2; }`. Also fail when an expanded directory yields zero files, and decide explicitly on symlinks (refuse or follow).

### WR-02: Privacy scan credential class is case-sensitive and narrow

**File:** `scripts/scan-privacy-188.sh:21,84`
**Issue:** `to""ken|sec""ret` runs without `-i`. I confirmed that `Bearer abc`, `SECRET=1` and `Password=x` produce zero hits. AGENTS.md lists credentials, tokens, account identifiers and stable device identifiers. There are no classes for password, api_key, authorization or bearer, private-key headers, `/home/`, or a UDID without hyphens. Selftests S10 and S11 only plant lowercase forms, so the gap is untested.
**Fix:** Use `-iE` for the credential class and extend it, for example `to""ken|sec""ret|pass""word|api[_-]?key|bearer|authorization|BEGIN [A-Z ]*PRIVATE`. Add selftest controls for mixed case.

### WR-03: assert-twin-05.sh cannot tell a twin-05 result from an older run

**File:** `scripts/assert-twin-05.sh:8-28`, `scripts/selftest-188-result.sh:45`
**Issue:** The check is purely structural plus the receipt digest. Control A01 shows the twin-04 result and receipt pair passes with `assert: ok`. The script does not bind the result to the freeze head or tree, to the 188 identity record, to `twin-05.exit` being 0, or to the run root. Any earlier passing, self-consistent pair would satisfy "TWIN-08 holds". The hardcoded 49 is also a magic number that duplicates the twin's own group definition.
**Fix:** Take the expected head and tree (or the candidate record) as arguments and compare them to the corresponding fields in the result or receipt. Require the argument paths to live under `twin-05/`. Confirm `twin-05.exit` is `0`. Add a negative control that feeds the twin-04 pair with twin-05 bindings.

### WR-04: Gate deadline is checked only after every check finishes, so a hang is never bounded

**File:** `scripts/run-once-05.sh:279-285,119-121,229`
**Issue:** `E` is computed after all checks complete. A hung `mix compile`, `simctl`, `lsof` or the preflight blocks forever; the 45-minute deadline cannot fire, and no `gate-stalled-05.*` record is ever written (that name is only counted, never produced). Control C04 also asserts the script has no `timeout`, so this is by design, but the C31 evidence only proves that a slow check is noticed after it returns.
**Fix:** Document that the deadline is post hoc. Or bound the long steps with a per-step watchdog that records `stalled` while keeping `verify_twin` unbounded as C04 requires.

### WR-05: Gate evidence is stale by the time the sentinel is written, and HEAD is captured once

**File:** `scripts/run-once-05.sh:102-104,250-252,308`
**Issue:** `HEAD_SHA`, `TREE` and the digests are read at line 102, before two compiles and a gen check that write into or beside the candidate. `head_equals_freeze` and similar checks then compare those stale values. Up to 45 minutes can pass between the checks and the sentinel. Port, simulator and root state are not re-read before launch. `verify_twin` binds `expected_head`/`expected_tree`, so a moved HEAD would fail closed. But the gate record can still say "Go" for a state that no longer holds.
**Fix:** Recompute `HEAD_SHA`/`TREE`/digests immediately before the head, tree and digest labels. Re-run `probe`, `l_nosibling` and `l_rootempty` once immediately before the sentinel write.

### WR-06: Gate attempt number from a file count can truncate an earlier log

**File:** `scripts/run-once-05.sh:55-59,67,297`
**Issue:** `N` is the count of existing go-no-go and gate-stalled files plus 1. If any earlier record was removed or renamed, `N` collides with an existing attempt. `: > "$LOG"` at line 67 truncates the earlier `gate-05.N.log` before the noclobber check on `$G` refuses at line 297. That destroys evidence even though the run is refused. Two concurrent invocations hit the same collision.
**Fix:** Create the log and gate record noclobber first, or derive `N` from the highest existing suffix. Open the log with `set -C` and refuse on collision.

### WR-07: l_port fails open when lsof is missing or errors

**File:** `scripts/run-once-05.sh:208-211`
**Issue:** `pl=$(lsof ...) || pl=` maps "no listeners" (exit 1) and "lsof not found or failed" to the same empty string, so `port_4790_free` passes. The selftest stub always returns 1, so the failure path is never exercised.
**Fix:** `command -v lsof >/dev/null || return 1`. Check the lsof exit code and output separately, accepting exit 1 with empty output only.

### WR-08: Selftest coverage has no negative control for several gate labels

**File:** `scripts/selftest-188.sh:165-372`
**Issue:** Controls C01-C31 never fail `port_4790_free`, `no_leftover_simulator`, `simulator_runtime_available`, `run_env_unsets_build_and_db`, `head_equals_record`, `tree_equals_record`, or the 87-count branch of `history_manifest_87_ok`. They also do not cover the `mode_resolved` real-mode branch, because selftest mode always passes it. `controls 31 of 31` therefore asserts less than the 30-label gate implies. This is the "green while asserting nothing" pattern for those labels.
**Fix:** Add controls with stubs: lsof returning output, xcrun listing a `crosswake-phase180-` device, an empty runtimes list, a record with a mismatched head, and a manifest with 86 entries.

## Info

### IN-01: refresh-handoffs-188.sh is non-atomic across the two records and leaves residue on failure

**File:** `scripts/refresh-handoffs-188.sh:37-55`
**Issue:** The `.pre-188` copies are made first, then `mv` of the two records happens one after the other. A failure between them, or after the copies and before the moves, leaves the copies and `.refresh.*` temp files behind. A rerun is refused with `pre188_exists`, so manual cleanup is needed. There is no trap to remove the temp files. An empty `git diff` also yields `core_diff_paths: []` with no error.
**Fix:** Add a `trap` that removes `$T180`/`$T182`. Treat `NPATHS -eq 0` as `verify_failed`.

### IN-02: make-identity-188.sh and freeze-check-188.sh do not re-check the tree after their last git or mix call

**File:** `scripts/make-identity-188.sh:20-48`, `scripts/freeze-check-188.sh:52-56,79`
**Issue:** The freeze runs `mix run` after the porcelain check and never re-checks cleanliness afterward, unlike run-once-05.sh's `shell_probe_clean_after_preflight`. make-identity-188.sh does not take or compare the freeze SHA. Inside `$(dig ...)` the `exit 4` only leaves the subshell and its message is swallowed; `set -e` still aborts, but silently. Temp files from `mktemp "$PD/.identity.XXXXXX"` and `.freeze.XXXXXX` are left in the planning directory on a `jq` failure.
**Fix:** Re-run the porcelain probe at the end of the freeze, accept the freeze SHA in make-identity-188.sh and compare it, and print the refusal outside the command substitution.

### IN-03: BSD-only `stat -f` and absolute-path history manifest reduce portability and may leak host paths into evidence

**File:** `scripts/run-once-05.sh:130,185-187`, `scripts/refresh-handoffs-188.sh:42`, `history-184.before.sha256`
**Issue:** `stat -f %Lp/%HT/%u` is macOS-only. On other systems it fails closed, which is acceptable for this one-time tool. The history manifest and the `.refreshed.candidate_path` in the handoffs carry absolute host paths. Phase 188 scripts promise "never prints paths", but those artifacts are retained.
**Fix:** Note the macOS-only constraint in the header. Keep the manifest out of any list passed to the privacy scan, or normalize its paths.

---

_Reviewed: 2026-10-16_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
