---
phase: 184-twin-probe-and-safe-preflight
reviewed: 2026-10-16T01:00:00Z
depth: deep
files_reviewed: 4
files_reviewed_list:
  - lib/crosswake/proof_lane/twin_producers.ex
  - guides/see_it_run.md
  - test/crosswake/proof_lane/twin_source_probe_test.exs
  - test/mix/tasks/crosswake_proof_lane_twin_preflight_test.exs
findings:
  critical: 2
  warning: 1
  info: 2
  total: 5
status: issues_found
---

# Phase 184: Gap-closure code review, round 3 (e4344ca5 over b5399e51)

**Reviewed:** 2026-10-16
**Depth:** deep. The candidate is /private/tmp/crosswake-phase180-impl at HEAD e4344ca5. `git status --porcelain` was empty before and after. I made all reproductions in a scratch copy and in scratch repos under the session scratchpad (`review3/`), using git 2.41.0 on macOS. In the scratch copy the two touched test files pass (93 tests, 0 failures).

## Summary

The two claimed fixes hold.

- **D-37 (`./` prefix plus byte-exact binding).** I reproduced the fix and could not break it. Hidden files in folders named `:deps`, `:(top)deps`, `:!deps`, `:/deps` and similar are attributed to their real source and counted. Names holding a newline, a tab, a leading dash, glob characters, 200-byte components, NFD/NFC Unicode (with `core.precomposeUnicode` default, true and false), an untracked nested repository (trailing slash), and a leading-space name were all sent, echoed and bound without a spurious `:unavailable`. A record that does not echo the exact sent text is `:unavailable`. A file really hidden by a committed rule (`:/deps/g` under a committed `deps/`) stays trusted, which is correct.
- **D-38 (info/exclude).** A file ruled out by `info/exclude` now counts, and the parser matches git on the cases that matter (leading-space `#`, tab-only, space-only, CR). The check-ignore input file is 0600 in the 0700 private directory.

The probe is still not fail-closed for two cases that were not in scope of the last two rounds' reproductions. Both report a clean tree while source exists, and both reproduce on this commit.

## Critical Issues

### GAP3-CR-01: A directory git cannot list hides untracked source, and the probe reports clean (reproduced)

**File:** `lib/crosswake/proof_lane/twin_producers.ex:842-880` (`run_git`, stderr discarded at `:810-833`), consumed at `:1177-1198` (`fresh_modified`) and `:1209-1230`

**Issue:** Every pinned git call is spawned with `2>/dev/null` and its exit status alone is trusted. When a directory is readable by name but not listable (for example mode `0111`, or `0311`), `git status` and `git ls-files --others` print `warning: could not open directory 'hid/': Permission denied` to the discarded stderr, exit 0, and omit everything inside. The files stay reachable by an explicit path (an `import_file`, a `Code.require_file`, a config path), so the candidate can run untracked code that git never reported.

Reproduced:
- Committed `.gitignore`, then `mkdir hid; echo 'defmodule Evil do end' > hid/evil.ex; chmod 111 hid`. `git status --porcelain --untracked-files=all` prints only the warning. `probe_source` returned `{:ok, %{modified: 0, flagged: 0, excludes: 0}}`, so `clean_tree` returns `:ok`. `cat hid/evil.ex` still works.
- The same holds for a tracked directory with an untracked new file under mode `0311` (`perm3`): clean.

This is a silent-degrade path: git told us it could not look, and the probe throws that away. It also applies to the `ls-files --others --ignored` listing, so ignored-but-hidden files in an unlistable directory are never judged.

**Fix:** Do not discard the signal. Either (a) run the status and listing calls with stderr captured to a private file and return `:unavailable` when it is non-empty (or contains `could not open directory`, `unable to read`, `unable to stat`), or (b) add a pre-pass that walks the work tree (skipping `.git`) and returns `:unavailable` if `File.ls/1` fails on any directory, or if a directory lacks the owner read and execute bits. Add a test with `chmod 0o111` on an untracked directory expecting `clean_tree == {:blocked, :prerequisite_missing}`.

### GAP3-CR-02: `info/attributes` comment test uses Unicode trimming, so a line git treats as live attributes is read as a comment (reproduced)

**File:** `lib/crosswake/proof_lane/twin_producers.ex:1423-1427` (`attributes_line_active?`), called from `:1100-1106` (`attributes_refusal`)

**Issue:** The commit kept `String.trim/1` for `info/attributes` with the comment "git's attribute reader skips leading blanks". Git's blank set is ASCII only (`" \t\r\n"`). `String.trim/1` strips all Unicode whitespace (NBSP U+00A0, U+2003, U+0085, U+2028, and also `\v` and `\f`). A line made of such a character followed by `#` is a live pattern to git (the pattern is the whole first token, for example ` #x`) but reads as an inactive comment here, so `attributes_refusal` returns `:ok`.

Reproduced end to end. The repo commits a file named `<U+00A0>#x` with content `$Id$`. `.git/info/attributes` holds `<U+00A0>#x ident`. The working file then holds `$Id: CHANGED-CONTENT $`. Results:
- `check-attr` shows `ident: set`.
- With the pinned fresh-index status, the changed file is not reported. Without the attributes file it is reported as ` M`.
- `probe_source` returned `{:ok, %{modified: 0, flagged: 0, excludes: 0}}`.
- A control line `x ident` is correctly `{:refused, :hiding_config}`.

The same class lets `eol=`, `text`, `ident` or `working-tree-encoding` attributes normalize away content differences for any file whose name begins with a Unicode-whitespace character then `#`.

**Fix:** Parse as git does. Strip only leading bytes in `[?\s, ?\t, ?\r, ?\n]`, then treat the line as inactive only if it is empty or its first byte is `?#`:

```elixir
defp attributes_line_active?(line) do
  rest = String.trim_leading(line, " ") |> trim_ascii_blanks()
  rest != "" and not match?(<<?#, _::binary>>, rest)
end
```

(where `trim_ascii_blanks/1` removes only `" \t\r\n"`, not Unicode whitespace). Add a test with a NBSP-prefixed `#` line and an attribute that changes a tracked file's comparison.

## Warnings

### GAP3-WR-01: A local `core.ignorecase=true` widens the trusted committed rules and is not refused (reproduced)

**File:** `lib/crosswake/proof_lane/twin_producers.ex:1073-1082` (`hiding_entry?`), `:1297-1299` (`trusted_source?`)

**Issue:** `core.ignorecase` in the candidate's local config is not in the refusal list. With a committed `deps/` rule and `git config core.ignorecase true`, an untracked `DEPS/x` is judged hidden by the committed `.gitignore` (trusted), so it adds no finding. A sibling `Deps.txt` is counted, `DEPS/x` is not (`modified: 1`). A committed rule therefore hides names it does not literally say, chosen by config the candidate controls. The documented limit is "files ignored by a committed .gitignore"; this widens it silently.

**Fix:** Treat `core.ignorecase` (truthy) and `core.precomposeunicode` differences like the other pinned settings: add `-c core.ignorecase=false` to `@git_pins`, or add `hiding_entry?({"core.ignorecase", v}), do: truthy?(v)` so the candidate is refused. Pinning is simpler, but on a case-insensitive filesystem confirm the probe still behaves (git sets this itself at `init` there, so pinning false there can misjudge case-colliding names; refusing is the safer option).

## Info

### GAP3-IN-01: `info/exclude` rule count is not git-exact for `\r\r\n` (reproduced)

**File:** `lib/crosswake/proof_lane/twin_producers.ex:1415-1417` and `:1428-1437`

**Issue:** `read_exclude/1` splits on `"\r\n"`, and `exclude_line_active?/1` then removes one more CR. A line `\r\r\n` is split to `"\r"`, then to `""`, and read as inactive. Git removes exactly one CR and applies the pattern `"\r"`. `excludes` was 0 where git has one live rule. This does not hide a file, because a file ruled out by `info/exclude` now counts as `modified` anyway (a file named `\r` counted 1). It does make the "git-exact line semantics" claim in D-38 and the doc comment false.

**Fix:** Split on `"\n"` only, so `exclude_line_active?/1` is the sole place that removes one trailing CR. Keep `read_exclude/1` splitting on `"\r\n"` for the attributes caller only if that is intended.

### GAP3-IN-02: The guide and docs claim an ignore rule hides nothing counted "whatever the folder or file is called"

**File:** `guides/see_it_run.md:176`

**Issue:** The sentence is correct for names but silent about the two open holes above (non-listable directories, case-folding config) and the attribute handling. Once GAP3-CR-01, GAP3-CR-02 and GAP3-WR-01 are fixed, no change is needed. Until then, the known-limit sentence ("Untracked files ignored by a committed .gitignore are not counted") understates what a reader can rely on.

**Fix:** After the fixes, add one sentence naming the new refusal reasons (unreadable directory, case-insensitive setting). No fix is needed beyond that.

## Checked and not a finding

- XDG, global and `core.excludesFile` sources: `core.excludesFile=/dev/null` and `GIT_CONFIG_GLOBAL=/dev/null` are pinned, a local `core.excludesFile` cannot override the command-line `-c`, and every `GIT_*` variable is unset at spawn.
- Per-directory untracked `.gitignore`: its source is never in the HEAD index, so every file it hides counts (and it counts itself).
- Input file: created `:exclusive` inside the random 0700 directory outside the candidate and the run root, chmod 0600 after write (the directory is the real protection), and removed with the directory. A failed chmod or write is `:unavailable`.
- Pathspec, `..`, trailing slash, newline, NUL-adjacent, long-name and Unicode entries: bound byte for byte, none produced a spurious `:unavailable` or a wrong trust.
- `exclude_line_active?`: over-counts only in the safe direction (BOM lines), and a counting error cannot hide a file now that `info/exclude` is untrusted.

---

_Reviewed: 2026-10-16_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: deep_
