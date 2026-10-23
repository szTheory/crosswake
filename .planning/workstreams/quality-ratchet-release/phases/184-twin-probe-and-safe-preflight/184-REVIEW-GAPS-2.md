---
phase: 184-twin-probe-and-safe-preflight
reviewed: 2026-10-16T00:17:57Z
depth: deep
files_reviewed: 4
files_reviewed_list:
  - lib/crosswake/proof_lane/twin_producers.ex
  - guides/see_it_run.md
  - test/crosswake/proof_lane/twin_source_probe_test.exs
  - test/mix/tasks/crosswake_proof_lane_twin_preflight_test.exs
findings:
  critical: 2
  warning: 0
  info: 3
  total: 5
status: issues_found
---

# Phase 184: Gap-closure code review, round 2 (b5399e51 over 3786de95)

**Reviewed:** 2026-10-16
**Depth:** deep. The candidate is /private/tmp/crosswake-phase180-impl at HEAD b5399e51, and `git status --porcelain` was empty before and after. I made all reproductions in a scratch clone and in scratch repos under the session scratchpad, using git 2.41.0.
**Status:** issues_found

## Summary

The commit closes the three round-1 findings in the form they were reported:
- **GAP-CR-01 (rule-file folder names that look like `info/exclude:1:z` or `.gitignore:1:x`).** Closed. The NUL-only parse returns the real source, and the two new tests pass.
- **GAP-WR-01 (quoted folder names).** Closed. The `-z` output is not quoted.
- **GAP-IN-01 (folder collapsing).** Closed. `--directory` is gone. With 100,000 files ignored by a committed rule, the probe took under 2 s, so removing collapsing causes no timeout.

The 80 tests in the two changed test files pass in a scratch copy. The output is in the scratchpad at `review/tests.out`.

The D-35 contract is still not met. It says that an ignore rule from anywhere other than a committed `.gitignore` counts every file it hides, and that `.git/info/exclude` rules "are counted on their own". I reproduced two separate ways for hidden untracked source to make the probe report clean:

1. **CR-01.** git reads every path sent to `check-ignore` as a *pathspec*. A path starting with `:` gets pathspec magic, so git judges a different path but echoes back the original. The new positional binding check therefore passes for a record that describes the wrong file.
2. **CR-02.** The `.git/info/exclude` rule counter treats some lines as inactive even though git applies them. D-35 now trusts info/exclude as a deciding source on the basis of that counter.

Both also reproduce at the parent commit 3786de95, so they are not regressions from this change. They are fail-open paths the fix did not close, and they make the new guide sentence false.

Other things I checked and found sound:
- A `.gitignore` that is staged but not committed is not trusted. The trusted set comes from the fresh HEAD index, and the repro counted 2.
- Index flags cannot get a rule file trusted. The fresh index has no flags, so a changed tracked `.gitignore` shows in status.
- A gitdir inside the work tree counts everything (27 in the repro).
- `:!x` and `--literal-pathspecs` both make check-ignore exit 128, which is `:unavailable` (fail-closed).
- Glob characters can only make the "seen in index" path print `::`, which counts.
- The stdin file path is passed as an argv element only.
- Every new error path maps to `:unavailable`.

## Critical Issues

### GAP2-CR-01: A top-level name starting with `:` makes check-ignore judge a different path, so untracked source hidden by an uncommitted rule reads clean

**File:** `lib/crosswake/proof_lane/twin_producers.ex:1245-1286` (`ignore_sources`, `parse_ignore_sources`, `bound?`) and `:1302-1307` (`trusted_source?`)
**Issue:** `check-ignore --stdin` runs each input line through `parse_pathspec` with every magic except `top` allowed. It decides the rule for `pathspec.match` but prints `pathspec.original`. For an entry like `:deps/evil.ex`, git strips the short-magic prefix `:` (`:(top)` behaves the same), so it evaluates `deps/evil.ex` and prints `:deps/evil.ex`.

The layout: the candidate commits a root `.gitignore` containing `/deps/`, which every Phoenix app does. An untracked folder `:deps/` holds a `.gitignore` containing `*` and an `evil.ex`. `git status` prints nothing. check-ignore then returns `.gitignore NUL 1 NUL /deps/ NUL :deps/evil.ex`. Because of that output:
- the framing check passes;
- the binding check passes, because `recorded == entry` compares against the echoed original;
- `trusted_source?` sees a tracked `.gitignore`.

The real deciding rule, `:deps/.gitignore` (untracked), is never seen.

**Reproduced:** yes. In the scratch repo `r1`, `probe_source` returned `{:ok, %{modified: 0, flagged: 0, excludes: 0}}` and `clean_tree` returned `:ok`. The long form `:(top)deps/` (`r5`) gives the same result. The control, with the same files in a plain folder `z/` (`r2`), returned `modified: 2` and `{:blocked, :source_dirty}`. At parent 3786de95, `r1` was also clean.

The positional binding check is the step D-35 added to catch this class of problem, but it cannot see this case. Passing `--literal-pathspecs` is not a fix: check-ignore rejects it for every path with "pathspec magic not supported by this command: 'literal'" and exit 128. That is fail-closed, but every candidate would then be `:unavailable`.

**Fix:** Send each path as `./<entry>`, which turns off magic parsing. Verified: `./:deps/evil.ex` returns source `:deps/.gitignore`, which is untracked and therefore counted. Bind each record against that exact sent text. As defence in depth, also count any listed entry that starts with `:` as untrusted. Add tests for `:deps/` and `:(top)deps/` beside a committed `/deps/` rule.

```elixir
payload = Enum.map(listed, &("./" <> &1 <> <<0>>))
# ...
ok and recorded == "./" <> entry and line_matches_source?(source, line)
```

### GAP2-CR-02: info/exclude lines that git applies but `active_rule?` treats as blank or as comments hide untracked source, and D-35 trusts info/exclude as the deciding source

**File:** `lib/crosswake/proof_lane/twin_producers.ex:1426-1429` (`active_rule?`), `:1408-1416` (`exclude_rules`), and `:1302-1307` (`trusted_source?`, the `== exclude` branch)
**Issue:** `active_rule?` runs `String.trim` before the blank and `#` checks. git does not do that:
- It treats a line as a comment only when its first byte is `#`.
- It strips only trailing, unescaped ASCII spaces.
- It never strips tabs, leading spaces or Unicode whitespace.

So a line `"  #*"` is an active git pattern, but `active_rule?` reads it as a comment. A line that is only a tab, or only U+00A0, is an active git pattern, but `active_rule?` reads it as blank.

A file under `"  #lib/"`, or under a folder named by a single tab, is then ignored by info/exclude while `excludes` is 0. D-35 trusts any source equal to info/exclude, so the hidden file is not counted as modified either.

**Reproduced:** yes. `r3` (`"  #*\n"` in info/exclude, file `"  #lib/evil.ex"`) returned `{:ok, %{modified: 0, flagged: 0, excludes: 0}}`. So did `r4` (`"\t\n"`, a file inside a folder named by a tab). `clean_tree` returned `:ok` for both. Both also reproduce at 3786de95.

The guide sentence added in this commit, "rules in .git/info/exclude are counted on their own", is false for these lines.

**Fix:** Count lines the way git parses them. Keep `String.trim` for `attributes_refusal`: attr.c does skip leading blanks, so trimming is right there. Simplest fail-closed alternative: count every hidden path whose source is info/exclude as modified, rather than trusting it.

```elixir
defp exclude_active?(line) do
  line = String.trim_trailing(line, "\r")
  not (line == "" or String.starts_with?(line, "#") or String.trim_trailing(line, " ") == "")
end
```

A line with a UTF-8 BOM before `#` would then be counted. That is fail-closed and acceptable.

## Info

### GAP2-IN-01: Docs and comments still describe the old model

**File:** `lib/crosswake/proof_lane/twin_producers.ex:792-796`, `:909-910`
**Issue:**
- The `git_invocation` comment still lists only the `:pinned` and `:bare` modes, not `:pinned_stdin`.
- `dirty_counts/2` still says "an uncommitted `.gitignore` that hides untracked files adds one finding per hidden path". D-35 now counts any source that is not trusted, including empty sources and non-`.gitignore` sources.

**Fix:** Update both texts so they match D-35.

### GAP2-IN-02: The temp stdin file holds the candidate's ignored path names; it outlives a killed BEAM

**File:** `lib/crosswake/proof_lane/twin_producers.ex:1245-1250`, `:1330-1363`
**Issue:**
- `check-ignore.in` lists every ignored untracked path name. That can include names like `.env` or credential file names, but never their contents.
- The file is created with the umask mode, not 0600. Today only the 0700 parent folder protects it.
- It is removed together with the folder, except when the VM is killed, which is the same exposure the temp index already has.

Reproduced: not applicable. This is a reading of the code, not a bypass.

**Fix:** Optional: `File.chmod(stdin_path, 0o600)` after writing, or open the file with mode 0600. Mention the file next to the temp index in the moduledoc.

### GAP2-IN-03: The new tests do not cover pathspec magic or how info/exclude lines are parsed

**File:** `test/crosswake/proof_lane/twin_source_probe_test.exs:621-770`
**Issue:**
- The binding test only swaps the order of records. It does not model git echoing one path while judging another, which is the CR-01 case.
- No test puts lines in info/exclude that git applies and `String.trim` misreads, which is the CR-02 case.

**Fix:** Add real-git tests for the layouts `r1`, `r5`, `r3` and `r4` from CR-01 and CR-02.

---

_Reviewed: 2026-10-16T00:17:57Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: deep_
