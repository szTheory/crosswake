---
phase: 184-twin-probe-and-safe-preflight
reviewed: 2026-10-15T00:00:00Z
depth: deep
files_reviewed: 9
files_reviewed_list:
  - guides/see_it_run.md
  - lib/crosswake/proof_lane/twin_preflight.ex
  - lib/crosswake/proof_lane/twin_producers.ex
  - lib/crosswake/proof_lane/twin_runtime.ex
  - lib/mix/tasks/crosswake.proof_lane.twin_preflight.ex
  - test/crosswake/proof_lane/twin_runtime_check_test.exs
  - test/crosswake/proof_lane/twin_source_probe_test.exs
  - test/mix/tasks/crosswake_proof_lane_twin_preflight_test.exs
  - test/support/twin_git_fixtures.ex
findings:
  critical: 1
  warning: 1
  info: 2
  total: 4
status: issues_found
---

# Phase 184: Gap-closure code review (3786de95 over 1f5d18ee)

**Reviewed:** 2026-10-15
**Depth:** deep (candidate /private/tmp/crosswake-phase180-impl, HEAD 3786de95, status clean before and after)
**Status:** issues_found

## Summary

The original findings are closed in the code. The WR-01 fix, however, introduced a
fail-open parsing path that I reproduced: an untracked, self-hiding ignore file in a
directory whose name spoofs a trusted rule source makes the probe return clean. The
79 tests in the three changed test files pass (output in
/private/tmp/crosswake-phase180-run/tests-184-review.out). They do not cover this path.

## Original findings

| ID | Closed by the code? | Evidence |
|----|---------------------|----------|
| CR-01 | Yes | `core.hooksPath=/dev/null` is in `@git_pins`. Every `run_git` call except `git --version` goes through `:pinned`, so all git calls in the probe carry the pin. The `:bare` version call runs no repo code. A command-line `-c` beats local config. The hook test has a positive control (the hook does run on a raw `read-tree`). I found no git call that bypasses the pin. |
| WR-01 | Partly. Closed for the stated case, bypassable (CR-01 below) | An untracked `.gitignore` containing `*` is now counted. Control reproduced: 3 findings. |
| WR-02 | Yes | `lock_digests` and `source_gate` no longer pattern-match. A digest error returns `{:blocked, :identity_unknown}`. `file_digest` returns `{:error, _}` on a read error. The mix task wraps the check in rescue and catch. |
| WR-03 | Yes (by wording) | Moduledocs and the guide now state the temp index and the brief port bind. A test pins the temp index under the snapshotted TMPDIR. |
| WR-04 | Yes | `rm_rf` runs only after this call's own `mkdir` succeeded and `chmod` failed. An `:eexist` path is never removed. |
| WR-05 | Closed by disclosure only | The docs now say the real run does not repeat the digest comparison and name Phase 188. The real run still does not enforce it. That is an accepted deferral, not a code fix. |
| IN-01 | Yes | The source-grep test is anchored with `__DIR__`, asserts anchors, and has a matcher sample test. |
| IN-02 | Mostly | Every inherited `GIT_*` name is unset first, then the fixed values and the per-call index are applied. The env ordering is correct. The task body now rescues and catches everything. The orphan git child on timeout is explicitly deferred and still open (IN-02 below). |

## Critical Issues

### CR-01: A directory name that spoofs a trusted rule source makes uncommitted ignore rules count as "committed", so hidden untracked source reads clean

**File:** `lib/crosswake/proof_lane/twin_producers.ex:1240-1257` (`parse_ignore_sources`, lazy regex `\A(.+?):(\d+):`) and `:1262-1277` (`uncommitted_rule?`)
**Issue:** `check-ignore --verbose` prints `<source>:<line>:<pattern>\t<path>`. The source is
parsed by a lazy regex on the first `:<digits>:`. The source file's own path is
attacker-controlled, so a directory name containing `:1:` shortens the parsed source.
`uncommitted_rule?` then trusts the shortened value:
- a parsed source of `info/exclude` returns `false` (treated as the covered `.git/info/exclude`);
- a parsed source equal to a path tracked in HEAD (for example `.gitignore`, which a real
  candidate has) is treated as a committed rule.

Layout: an untracked directory `info/exclude:1:z/` holding `.gitignore` (`*`) and `evil.ex`.
Git status prints nothing. `check-ignore -v` prints
`info/exclude:1:z/.gitignore:1:*\tinfo/exclude:1:z/evil.ex`, which parses to source
`info/exclude`, so nothing is counted.

Reproduced: yes. I ran `TwinProducers.probe_source/1` on a scratch repo with that layout:
it returned `{:ok, %{modified: 0, flagged: 0, excludes: 0}}`, so `clean_tree` returns `:ok`
and the preflight and source gate allow a tree with hidden untracked source. The control
(same files in a plain directory `z/`) returned `modified: 3`. This is the exact outcome
WR-01 was meant to prevent, and the guide now states that such a file "is counted".
Without `info/exclude`, a committed root `.gitignore` gives the same bypass with a directory
named `.gitignore:1:x`.

**Fix:** Do not infer the source from text. Use `check-ignore --verbose -z --non-matching`,
which separates source, line, pattern and path with NULs and does not quote. Then validate
the source against the actual rule locations: accept only exactly `.git/info/exclude`
(resolved from `rev-parse --git-path info/exclude`) or an entry whose full path equals a
path tracked in HEAD whose basename is `.gitignore`. Treat any source that fails this
check as uncommitted and count it. Add tests for a `:1:` directory name in both variants.

## Warnings

### WR-01: A tracked `.gitignore` in a directory with a control character in its name is counted as an uncommitted rule (false block)

**File:** `lib/crosswake/proof_lane/twin_producers.ex:1243-1250, 1262-1277`
**Issue:** With `core.quotePath=false`, git still C-quotes names containing tab, newline,
quote or backslash, in both the source and the path. The parsed source then carries
a leading `"` and a trailing `"`, so `Path.basename(source) == ".gitignore"` fails and the
fallthrough `true -> true` counts it. A clean, committed candidate with such a
directory is blocked as `source_dirty`. It fails closed, but with a wrong reason and no
distinct cause. This is also the same root cause as CR-01 (text-parsed source), so the
`-z` fix covers both.
**Fix:** As in CR-01; the unquoted `-z` output removes the quoting.

## Info

### IN-01: Correctness depends on git 2.41's `--directory` listing members of an ignored directory

**File:** `lib/crosswake/proof_lane/twin_producers.ex:1172-1176` (comment) and `:1262`
**Issue:** `uncommitted_rule?(entry, "", _)` returns `false` for a collapsed directory with
no deciding rule, on the claim that its members are listed separately. On git 2.41 I saw
members listed and the directory itself matched, so I could not make this a bypass. On a
git that collapses ignored directories (the minimum is "2.41 or newer", so newer gits are
in range), a collapsed `dir/` with `::` would be skipped and its members would not be
judged. I could not verify other versions here.
**Fix:** Drop `--directory` so every ignored path is listed, or verify the claim on the
newest supported git and add a test that fails if the listing changes.

### IN-02: Orphan git child on timeout remains open (explicitly deferred)

**File:** `lib/crosswake/proof_lane/twin_producers.ex:830-842`
**Issue:** `Task.shutdown(:brutal_kill)` stops the Elixir task, not necessarily the `sh`/git
OS process. The new comment records the deferral. No code change was made, so the
original IN-02 is only partly closed. Also, a pinned `status --ignore-submodules=none` makes
git run status inside initialized submodules (the `-c` pins reach them via the config
environment), and `config_refusal` only checks the top-level repository's config. I did not
test whether a submodule's own `filter.*` or other config can then run code. Treat it as
unverified.
**Fix:** Spawn git under a process-group wrapper that can be signalled, or confirm and
record that submodules are refused or pinned. Keep the deferral recorded.

---

_Reviewed: 2026-10-15_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: deep_
