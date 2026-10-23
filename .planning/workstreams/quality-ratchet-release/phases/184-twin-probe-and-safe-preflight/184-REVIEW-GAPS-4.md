---
phase: 184-twin-probe-and-safe-preflight
reviewed: 2026-10-16T03:00:00Z
depth: deep
files_reviewed: 7
files_reviewed_list:
  - lib/crosswake/proof_lane/twin_producers.ex
  - guides/see_it_run.md
  - test/crosswake/proof_lane/twin_source_probe_test.exs
  - test/crosswake/proof_lane/twin_producers_test.exs
  - test/mix/tasks/crosswake_proof_lane_twin_preflight_test.exs
  - test/crosswake/guides/see_it_run_test.exs
  - test/support/twin_git_fixtures.ex
findings:
  critical: 0
  warning: 2
  info: 3
  total: 5
status: issues_found
---

# Phase 184: Gap-closure code review, round 4 (b898e110 over e4344ca5)

**Reviewed:** 2026-10-16
**Depth:** deep. Candidate: /private/tmp/crosswake-phase180-impl at b898e110. `git status --porcelain` was empty before and after. I made every reproduction in a scratch copy of the candidate and in scratch repos under the session scratchpad (`review4/`), using git 2.41.0 on macOS (APFS, non-root). I drove `probe_source/2` and `clean_tree/2` through `mix run` in the scratch copy. I did not run the candidate's test suites.

## Summary

The four claimed fixes hold. I could not break D-39, D-40 or D-41, and the guide wording (D-42) matches the code.

**D-39 (stderr as a failure signal).**
- Folders at mode 0111, 0311 and 0000, an unreadable `.gitignore`, a symlinked `.gitignore`, a gitfile pointing nowhere, and an unlistable folder that an `info/exclude` rule ignores all give `:unavailable` / `{:blocked, :prerequisite_missing}`.
- An untracked file at mode 000 and a tracked file at mode 000 are counted as modified.
- A legitimate candidate (the scratch copy of the candidate itself) still probes clean, so the capture does not false-block ordinary git output.
- I found no way to bypass the script:
  - Anything on stderr makes the script exit 125, and no caller accepts 125.
  - A shell-level failure such as a missing git, an unopenable stdin file, or a signal gives 127, 1 or 128+n. All of these either fail the `{out, 0}` match or hit the framing check in `parse_ignore_sources`.
  - Stdout goes straight to the port on fd 3, so it cannot interleave with the stderr that the shell buffers.

**D-40 (git-format text).**
- `core.symlinks` set to 00, 0x1 or 2, and `core.bare` set to 00, 0x0, +0, -0 or 0k, are all refused.
- `false`, `No`, `OFF`, `0` and an empty value are accepted for `core.bare`, and `TRUE` and `yes` for `core.symlinks`, which matches what git accepts.
- Every spelling that the code trusts is a spelling git really reads as the safe value. The refusals are fail-closed.

**D-41 (`core.ignorecase=false`).**
- It is a net gain. On a case-insensitive filesystem git skips a nested `.GIT` folder with the default `ignorecase=true`, and with the pin the files under it are listed. I reproduced the pinned behaviour: `sub/.GIT/a` and `sub/b.ex` are both counted.
- An index or config written under `ignorecase=true` does not matter, because the private index is rebuilt from HEAD and the real index is only read for flags.

Two remaining ways give a clean report, or a hang, with a folder or file that matters. Neither is part of D-39..D-42, but both are in the brief's scope. There are also three smaller items.

## Warnings

### GAP4-WR-01: A FIFO at `.git/info/attributes` makes `probe_source/2` block forever (reproduced)

**File:** `lib/crosswake/proof_lane/twin_producers.ex:1441-1447` (`read_exclude/1`), called from `attributes_refusal/2` at `:1125-1133` and `exclude_rules/2` at `:1430-1438`

**Issue:** The probe asks git where `info/attributes` lives, then reads it with `File.read/1` on the calling process. That is the only step in the probe that has no timeout. `attributes_refusal` runs before any git call that would open the file, so the 60 s git timeout does not protect it.

I ran `mkfifo .git/info/attributes` in a scratch repo and called `probe_source/2`. It did not return within 120 s, and I had to kill the BEAM. The preflight and `clean_tree` use the same path, so a candidate can hang the read-only preflight. Nothing reports clean, so this is a robustness defect rather than a fail-open. It still breaks the "never raises, bounded" posture that the rest of `run_git` keeps. The read is also unbounded in size: a very large `info/attributes` is read whole into memory.

**Fix:** Stat first and read only a regular file of bounded size. Refuse anything else.

```elixir
defp read_exclude(file) do
  case File.stat(file) do
    {:ok, %File.Stat{type: :regular, size: size}} when size <= 1_048_576 ->
      case File.read(file) do
        {:ok, text} -> {:ok, String.split(text, "\n")}
        {:error, _} -> :error
      end

    {:error, :enoent} -> {:ok, []}
    _ -> :error
  end
end
```

`File.stat` follows symlinks, so a symlink to a regular file still works. A FIFO, device or socket gives `:error`, which is `:unavailable`. The stat and the read are still two steps. For a hard bound, open the file in a Task with the same `Task.yield` timeout that `run_git` uses.

### GAP4-WR-02: Untracked files inside an uninitialized gitlink folder are invisible, and the probe reports clean (reproduced)

**File:** `lib/crosswake/proof_lane/twin_producers.ex:1204-1228` (`fresh_modified`, the `status ... --ignore-submodules=none` call), with `:1062-1070` (`probe_source`); disposition recorded in 184-CONTEXT.md D-36(b)

**Issue:** When HEAD holds a mode-160000 entry (for example `vendor/sub`) and the folder in the work tree is a plain directory without a `.git`, git treats the folder as the submodule path and does not list anything inside it. No warning goes to stderr, so D-39 cannot see it.

Reproduction:
1. Run `git update-index --add --cacheinfo 160000,<sha>,vendor/sub` and commit.
2. Run `mkdir -p vendor/sub; echo evil > vendor/sub/hidden.ex`.

Result: `probe_source` returns `{:ok, %{modified: 0, flagged: 0, excludes: 0}}` and `clean_tree` returns `:ok`. The file `hidden.ex` is untracked source that the candidate can load by explicit path.

Controls: with a real clone in that folder, a change inside it is counted. With a `.git` file pointing nowhere, the result is `:unavailable`. So only the "folder with no repository" case fails open.

D-36 deferred submodule handling because the candidate has no gitlink and no `.gitmodules`. I confirmed that is still true at b898e110 (zero mode-160000 entries, no `.gitmodules`), so the trigger is not met. The deferral records "submodule config", not this hiding case. The guide sentence "Changes hidden by index flags or by git settings still count" reads as complete coverage, and a user cannot tell this case from it.

**Fix:** The cheapest fix is a refusal. List the fresh index with `ls-files -s -z` and return `{:refused, :hiding_config}` for any entry with mode `160000`. The `:hiding_config` next-action text names `.git/info/attributes` and filters, so either reuse it or add a reason when the next phase touches the wording. If the refusal waits, add a sentence to the guide limit and to the D-36 reopen record that a gitlink folder without a repository hides what is inside it.

## Info

### GAP4-IN-01: Untracked FIFOs and sockets are not listed, and the probe reports clean (reproduced)

**File:** `lib/crosswake/proof_lane/twin_producers.ex:1204-1228`

**Issue:** An untracked FIFO (`mkfifo lib/f`) or Unix socket gives `{:ok, %{modified: 0, ...}}` and `:ok`. Git's directory scan drops anything that is not a regular file, a symlink or a folder, and it prints nothing. A FIFO or socket holds no source text, so I rate this as a disclosure gap and not a hole in the check. A program that opens a FIFO in the candidate would still read whatever another process writes to it.

**Fix:** Either add a sentence to the guide limit ("devices, FIFOs and sockets are not listed by git and are not counted"), or run `find <path> -not -type f -not -type d -not -type l -not -path './.git/*'` style detection in Elixir with `File.lstat` over the listing and refuse non-regular entries. Documenting is enough unless the twin ever reads from such a path.

### GAP4-IN-02: "config values are read as git spells them" overstates the code (reproduced)

**File:** `lib/crosswake/proof_lane/twin_producers.ex:1119-1124`, doc text at `:683-686`, `:912-914`, `:1045-1050`

**Issue:** Git's boolean reader accepts any integer spelling (`0x1`, `01`, `2`, `+1`, `1k`) as true and any zero spelling (`00`, `0x0`, `+0`, `-0`) as false. The code trusts only the literal words and `0`/`1`/empty. The result is fail-closed, so nothing hides. The docs and the guide-adjacent text say the opposite, and a candidate with `core.symlinks=2` (which git reads as true) is refused as `:hiding_config` with the "worktree redirect, filter or info/attributes" advice, which does not describe the problem. I reproduced `core.symlinks` = 00, 0x1, 2 and `core.bare` = 00, 0x0, +0, -0, 0k as refused.

**Fix:** Reword to "config values are read with git's word spellings; unusual numeric spellings are refused", or parse integers with the same rules as `git_parse_int` and keep the current refusal for anything that does not parse.

### GAP4-IN-03: Brittleness left by "any stderr text blocks", and two untested environments

**File:** `lib/crosswake/proof_lane/twin_producers.ex:810-812`; `test/support/twin_git_fixtures.ex:163-178`

**Issue:**
- Not reproduced here (only git 2.41.0 is installed). The script blocks on any stderr byte, so a future git release that prints a harmless advisory (deprecation or config-key notice) on a pinned `-c` key would make every candidate `:prerequisite_missing`. The block is the right default, but nothing pins a maximum tested git version or a smoke test against the newest git in CI. The guide says git "2.41 or newer", which promises more than has been run.
- The new unlistable-folder tests rely on a non-root user. As root (a container CI job), `chmod 0111` does not stop listing, and the three tests would report `source_dirty` or clean and fail with a confusing message. Not reproduced, since I ran as a normal user.
- Reproduced, pre-existing and not from this change: a file committed under `core.precomposeunicode=false` with an NFD name is reported as an untracked NFC name when the local config says `true` (macOS default), so a legitimate candidate is blocked as `source_dirty`. The pin comment says `precomposeUnicode` is "left alone"; the failure direction is a false block, never a false clean.

**Fix:** Add a CI note or a `@tag :requires_non_root` guard that skips the unlistable-folder tests when `System.cmd("id", ["-u"])` returns 0. State the newest git version that was tested next to the "2.41 or newer" line.

---

_Reviewed: 2026-10-16_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: deep_
