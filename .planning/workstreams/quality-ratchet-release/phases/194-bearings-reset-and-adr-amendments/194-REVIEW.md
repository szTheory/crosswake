---
phase: 194-bearings-reset-and-adr-amendments
reviewed: 2026-10-25T00:00:00Z
depth: standard
files_reviewed: 12
files_reviewed_list:
  - lib/crosswake/capability_map/renderer.ex
  - lib/crosswake/planning/first_adopter_context.ex
  - lib/crosswake/proof_lane/provenance.ex
  - lib/crosswake/support_matrix/renderer.ex
  - lib/crosswake/support_matrix/support_matrix.ex
  - script/bearings-report
  - script/bearings_report.exs
  - test/crosswake/bearings_report_test.exs
  - test/crosswake/planning/agents_contract_test.exs
  - test/crosswake/planning/milestone_arc_closeout_parity_test.exs
  - test/crosswake/support_matrix/renderer_test.exs
  - test/crosswake/support_matrix/support_matrix_test.exs
findings:
  critical: 0
  warning: 6
  info: 4
  total: 10
status: issues_found
---

# Phase 194: Code Review Report

**Reviewed:** 2026-10-25
**Depth:** standard
**Files Reviewed:** 12
**Status:** issues_found

## Summary

The lib changes (Android wording, one scanner allow-list entry, one comment) are wording-only and consistent across the renderer, matrix, guide and tests. I found no leftover "Android frozen" text in lib or guides. The mixed "native-control breadth stays frozen" wording in the capability map is intentional.

`script/bearings_report.exs` is mostly well built. Every external read goes through one seam, and failed gh/git reads, bad JSON, truncated PR lists and missing files all map to UNVERIFIED with fixed reason strings. The recurring defect class (a failed read scored as OK) was not found in the happy paths. I found these gaps:

- An unexpected crash exits 1, which means ATTENTION.
- A malformed seed silently drops its trigger.
- Zero carried debt is reported as UNVERIFIED.
- There is no command timeout.
- stderr is merged into the parsed stdout.

The new AGENTS contract test is partly tautological.

No critical (security or data-loss) issues were found. The script writes nothing, interpolates no shell strings, and validates `--ws` against a restrictive regex.

## Warnings

### WR-01: An uncaught crash exits 1, which collides with ATTENTION

**File:** `script/bearings_report.exs:18-43, 667-668`
**Issue:** The documented exit contract is 0/1/2, with 2 meaning UNVERIFIED. `main/1` has no rescue. Any raise outside `system_run` makes the Elixir VM exit with status 1, and the script prints a stack trace instead of a report. Callers that only look at the exit code read that as "ATTENTION", not "UNVERIFIED".

Reachable examples:
- `JSON` is a stdlib module from Elixir 1.18. The launcher does not check the Elixir version, and the repo pins 1.19.
- A `File.cd` race.
- Any future pattern-match failure in a check.

A crash is the purest absence-as-success hazard, because the failure reads as a normal "needs attention" signal.
**Fix:** Wrap the run in the entry point and map any exception to a fixed UNVERIFIED line with exit 2.
```elixir
def main(argv) do
  do_main(argv)
rescue
  _ -> emit(render([unverified("report", "internal error")]))
end
```
Add a test that injects a raising `deps.read` and asserts exit code 2.

### WR-02: External commands have no timeout

**File:** `script/bearings_report.exs:56-64`
**Issue:** `System.cmd("git", ["fetch", ...])` and the `gh` calls can block indefinitely on a network stall, an auth prompt or a credential helper. The report is the "one-screen orientation" tool, so a hang is worse than a failure. A bounded failure would map cleanly onto the existing `{:error, _}` to UNVERIFIED path.
**Fix:** Run the command in a `Task` and use `Task.yield(task, 30_000) || Task.shutdown(task, :brutal_kill)`. Return `{:error, :timeout}` when it expires. Setting `GIT_TERMINAL_PROMPT=0` through `env:` also prevents prompts.

### WR-03: A seed with malformed frontmatter silently becomes "prose-only" and its trigger never evaluates

**File:** `script/bearings_report.exs:226-241`
**Issue:** `parse_frontmatter` returns `:error` for a missing closing `---`, a leading BOM or blank line, or CRLF line endings (the first line is `"---\r"`, which does not match `"---"`).

UNVERIFIED is raised only when every seed fails to parse. Otherwise `seed_lines` maps `:error` to `%{}`. The seed is counted as open and prose-only, and its `fires_when` is never read. A seed with a satisfied trigger and a typo in its frontmatter therefore yields OK or ATTENTION with the trigger silently missed. The test "prose-only seeds are counted... including a seed with no frontmatter" locks this behaviour in. It does not distinguish "no frontmatter at all" from "frontmatter present but broken".
**Fix:** Distinguish "does not start with `---`" (genuinely prose-only) from "starts with `---` but never closes" (UNVERIFIED seeds: malformed frontmatter in ID). Also normalise `\r\n` before splitting.

### WR-04: Zero carried debt is reported as UNVERIFIED with a misleading reason, and the row count is fragile

**File:** `script/bearings_report.exs:302-322`
**Issue:**
- `k when k > 0 <- carried_rows(text)` collapses "file found, `## Carried` table present, zero rows" into `UNVERIFIED debt: no closeout debt-disposition found`. That is false, because the file was found. The test "a table with no rows" asserts the wrong text on purpose. A closeout with legitimately no carried debt can never reach OK.
- `carried_rows` counts lines starting with `"| "` and subtracts 1 for the header. A separator written `| --- | --- |` (common in formatted markdown) also starts with `"| "`, so the count is off by one. The count stays right only while the separator is `|---|`.
- A missing `## Carried` heading gives 0, which is correctly UNVERIFIED, but under the same wrong message.
**Fix:** Return `{:error, :no_section}` when the heading is absent (UNVERIFIED "no Carried section"). Otherwise return a count. Exclude separator rows with `~r/^\|[\s:|-]+\|?\s*$/`, and report 0 as info.

### WR-05: stderr is merged into the parsed stdout

**File:** `script/bearings_report.exs:57`
**Issue:** `stderr_to_stdout: true` means that on a successful exit (status 0) any warning text git or gh writes to stderr is appended to the output that is then parsed and counted. Examples: git's "warning: ..." lines and gh upgrade or deprecation notices.

- `count_lines` for stashes and unlanded branches will count warning lines as stashes or branches, inflating the ATTENTION counts.
- The JSON decode paths fail closed, but only as a false UNVERIFIED.
- The comment says "never stderr text", which is true for the failure path but not for the success path.
**Fix:** Drop `stderr_to_stdout` and discard stderr. Use `System.cmd(..., stderr_to_stdout: false)`, accepting that stderr then goes to the terminal. To suppress it, run through `sh -c 'exec "$@" 2>/dev/null' _ cmd args...`.

### WR-06: The persona check can silently under-count or mismatch the milestone

**File:** `script/bearings_report.exs:326-329, 340-347`
**Issue:**
- The requirement-ID regex `[A-Z]+-\d+` skips IDs with more than one segment or with lowercase letters (for example `CW-REQ-01`). Those lines are neither counted nor listed as untagged. A file where only some lines match reports "N/N tagged" with the unmatched requirements invisible. There is no cross-check against the checkbox-line count.
- `String.contains?(title, ms)` makes a `v2.1` milestone match a `# ... v2.10` title. The comparison should be token-bounded.
**Fix:** Count all `^- \[[ x]\] \*\*` lines as requirements. Mark a line untagged if its ID does not match the grammar. Match the title with `~r/\b#{Regex.escape(ms)}(?![\d.])/`.

## Info

### IN-01: The `truncate/1` 40-line bound can be exceeded, and it can hide ATTENTION lines

**File:** `script/bearings_report.exs:372-379`
**Issue:** With many UNVERIFIED lines, `room` clamps to 0 but the "... N more lines not shown" footer is still appended, so output can exceed 40 lines. ATTENTION lines are treated as "details" and can be hidden, with only the count in the verdict. That is acceptable, but the footer should say which kind was hidden.
**Fix:** Keep ATTENTION lines ahead of INFO in `details` (already the case), and say "N more lines (info/attention) not shown".

### IN-02: `valid_ws?` uses `^`/`$` anchors, which allow a trailing newline

**File:** `script/bearings_report.exs:50`
**Issue:** `~r/^[a-z0-9][a-z0-9-]*$/` matches `"foo\n"` because `$` matches before a final newline. The character class still rules out `.` and `/`, so there is no traversal, but the validation is looser than intended.
**Fix:** Use `\A...\z`. `ctx.root` is also stored and never read, so it can be removed.

### IN-03: Parts of the test suite are tautological or untested

**File:** `test/crosswake/planning/agents_contract_test.exs:44-65`, `test/crosswake/bearings_report_test.exs`
**Issue:**
- The per-phrase "negative control" first asserts that the live text contains the phrase. It then deletes that phrase globally and asserts that `String.contains?` no longer finds it. That proves only that `contains?` works, and it never exercises a realistic regression.
- The gate predicate accepts the phrases anywhere in AGENTS.md, in any order, even if they are split across unrelated sections. The "ROLLING as first item" control similarly replaces the first occurrence of the string it then looks for.
- In `bearings_report_test.exs`, `system_run/2` (its `exit_status`, `missing_binary` and `exception` branches), `change_root/1` (invalid `--root`) and the crash path of WR-01 have no test.
- The check "no workflow references 'bearings'" fails on any workflow that merely mentions the word.
**Fix:** Scope the gate predicate to the paragraph containing "approval gate". Add tests for `system_run` with a nonexistent binary and for `--root /nonexistent` (exit 2). Narrow the workflow check to `script/bearings`.

### IN-04: The CI line for a feature-branch HEAD is always ATTENTION until a run exists

**File:** `script/bearings_report.exs:647-662`
**Issue:** When local HEAD is neither the main tip nor the PR head, the report emits ATTENTION "CI has not run on HEAD". That is intended, but a locally committed, unpushed HEAD cannot have a run either, so every pre-push report shows ATTENTION. The report does not distinguish "pushed, no CI yet" from "not pushed".
**Fix:** Optionally check `git branch -r --contains HEAD` and label the unpushed case separately.

---

_Reviewed: 2026-10-25_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
