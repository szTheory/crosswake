---
phase: 189-inventory-and-backup
reviewed: 2026-10-18T00:00:00Z
depth: standard
files_reviewed: 22
files_reviewed_list:
  - scripts/assemble-inventory-189.sh
  - scripts/backup-dirty-189.sh
  - scripts/backup-env-189.sh
  - scripts/backup-ignored-189.sh
  - scripts/backup-refs-189.sh
  - scripts/backup-tmp-189.sh
  - scripts/classify-dirty-189.sh
  - scripts/classify-reflog-189.sh
  - scripts/classify-refs-189.sh
  - scripts/classify-stash-189.sh
  - scripts/classify-tmp-189.sh
  - scripts/export-stash-189.sh
  - scripts/lib-189.sh
  - scripts/manifest-189.sh
  - scripts/prs-189.sh
  - scripts/reconcile-189.sh
  - scripts/restore-189.sh
  - scripts/scan-privacy-189.sh
  - scripts/selftest-189.sh
  - scripts/snapshot-189.sh
  - scripts/verify-189.sh
  - scripts/verify-candidate-189.sh
findings:
  critical: 1
  warning: 15
  info: 6
  total: 22
status: issues_found
---

# Phase 189: Code Review Report

**Reviewed:** 2026-10-18
**Depth:** standard (plus read-only spot checks of RUNS and one <tmp> folder to confirm findings)
**Files Reviewed:** 22 (all under the phase `scripts/` folder; paths below are relative to it)
**Status:** issues_found

## Summary

The core design is sound. `gr` is an allow-list wrapper, `gs`/`gclone` refuse to touch anything outside RUNS, restores compare exact ref lists, trees, sha256 and mode, and the reconcile step fails on empty input. No script was found that writes to the recovery checkout in the runs that were recorded.

One finding is an incorrect classification that leaves real data unbacked-up and marked removable (CR-01). The remaining findings are mostly places where the fail-closed rule is not actually enforced: a gate whose result is only printed, a pipeline that masks an exit code, a default of "yes" that survives a failed command, and a wrapper allow-list that is wider than the behaviour the callers need.

The user-approved `[@]` sed expression in `scan-privacy-189.sh` is narrow in character class but not in context (WR-10).

No home paths or usernames appear below. Locations use `<recovery-checkout>`, `<backup-root>`, `<tmp>` and RUNS.

## Critical Issues

### CR-01: A broken git stub holding 63 MB of git objects is classified "empty/no repo, nothing to keep" and has no backup

**File:** `scripts/classify-tmp-189.sh:74-83` (stub detection), `:405-413` and `:421-425` (class and plan), `scripts/backup-tmp-189.sh:105-167` (no job for it)
**Issue:** A candidate directory counts as a repo only if `HEAD` resolves. Anything else goes to `BROKEN` and nothing is looked at again. In entries mode a folder with zero nested repos and zero files outside `.git` takes the final branch: `cls=obsolete`, `rsn="empty/no repo, nothing to keep"`, `plan=none`. D-04 allows that reason only for "no valid HEAD, 0B".

I confirmed this on the real data. `<tmp>/crosswake-phase175-exact-public-candidate-source` appears in `189-EVIDENCE/tmp-entries.tsv` as `broken_stubs=1`, `files_outside_git=0`, `size_kb=64512`, class `obsolete`. The `.git` there has no `HEAD` but holds `objects`, `logs`, `refs` and 90 files. Pointing a scratch bare repo's alternates at that object store (read-only) shows 3910 commits, 19689 trees and 13230 blobs. Three of those commits (a dependabot bump of `erlef/setup-beam`, one of `actions/checkout`, and a `chore(main): release crosswake_chimeway 0.1.1` commit) are not reachable from any ref in RUNS `compare.git`, and not present in `scratch-06/cmp.git` either, which also holds the fetched `refs/pull/*/head` refs. They may well be public commits of a companion repository, but the inventory never established that. Phase 193 will read the row as "nothing to keep".

The same blind spot applies to every other broken stub: `du` size is computed but never used, so size does not stop the "empty" class.

**Fix:** Do not allow the `empty/no repo, nothing to keep` reason unless the folder is verified empty. For example, in entries mode:
```bash
# after computing kb and nbroken for a dir entry
if [ "$nbroken" -gt 0 ] || [ "${kb:-0}" -gt 0 ]; then
  # a stub with any bytes is never "empty": back its git directory up and leave it unclassified
  cls=unclassified
  rsn="broken git directory ($kb KB, no HEAD); objects not compared; git directory archived"
  plan="gitdir-tar"
fi
```
Add the stub's git directory to `tmp-gitdirs.tsv` so `backup-tmp-189.sh build` tars it (it needs a `reasons` value such as `broken_stub`), and add a reconcile check that no `R-TMP-EMPTY` entry has `size_kb > 0`. For the existing run, either tar the 63 MB `.git` into `<backup-root>` with a restore test, or prove with a read-only fetch/`cat-file` that the three unreferenced commits are on GitHub and record that as the reason.

## Warnings

### WR-01: `gr` allows `symbolic-ref` with any arguments, which can move HEAD of the frozen checkout

**File:** `scripts/lib-189.sh:49`
**Issue:** `symbolic-ref` is in the read-only verb list with no argument check. `gr "$REC" symbolic-ref HEAD refs/heads/x` or `--delete` writes to the checkout. Every current caller uses `symbolic-ref -q HEAD`, so nothing wrote. But the wrapper is the single guard behind requirement (a), and it is wider than the callers need. Other verbs have the same shape (`diff`/`log`/`show` can run repo-configured external diff or textconv helpers; `rev-parse` is fine).
**Fix:** Take it out of the generic list and add a case that accepts only the read form:
```bash
symbolic-ref)
  [ "$#" -eq 2 ] && [ "$1" = -q ] && [ "$2" = HEAD ] || { echo "gr: refused symbolic-ref" >&2; return 3; } ;;
```
Also pass `--no-ext-diff --no-textconv` for `diff`/`log`/`show` callers, or refuse the options that enable external programs.

### WR-02: Nothing stops RUNS from being inside the frozen checkout

**File:** `scripts/lib-189.sh:62-69` (`_scratch_ok`), `:386` (`runs=$_LIB_DIR`)
**Issue:** `locate` sets `RUNS` to the folder holding `lib-189.sh`. The byte copies of these scripts live in the phase folder inside `<recovery-checkout>`. If `bash <phase>/scripts/lib-189.sh locate` is run from that copy, `RUNS` becomes a path under the checkout, `_scratch_ok` then accepts it, and `gs`, `gclone`, `mkdir scratch-*`, `mirror.git`, `restore/` and `env-189.sh` are all written into the frozen checkout. The check is a prefix test, so the layout alone decides whether D-08 holds.
**Fix:** In `_locate` (and cheaply in `_scratch_ok`) refuse when RUNS is under REC:
```bash
case $runs in "$rec"|"$rec"/*) echo "locate: RUNS must not be inside the recovery checkout" >&2; return 1 ;; esac
```

### WR-03: Test-only environment overrides are honoured by the production gating scripts

**File:** `scripts/restore-189.sh:18-19` (`RESTORE_RUNS`, `RESTORE_OUT`), `scripts/snapshot-189.sh:13-16` (`SNAP_REC`, `SNAP_CAND`, `SNAP_TMPROOT`, `SNAP_BR`), `scripts/verify-189.sh:8-9` (`VERIFY_OUT`, `VERIFY_SNAPSHOT`), `scripts/manifest-189.sh:8` (`MANIFEST_OUT`)
**Issue:** These exist for `selftest-189.sh`. In a real run a stale exported variable silently points the restore at other files, or the snapshot at a fixture repository. A restore would print `pass` for artifacts that are not the backups, and `verify-189.sh --quick` could compare a fixture against the real before-snapshot. Nothing prints which targets were used.
**Fix:** Make the overrides require an explicit selftest marker (for example only honour them when `SELFTEST_189=1` and the target sits under `/private/tmp/cw189-selftest.*`), or print the effective targets on the first output line.

### WR-04: `classify-refs-189.sh` creates a stray file named `GF` in the current directory

**File:** `scripts/classify-refs-189.sh:74`
**Issue:** `: > GF 2>/dev/null; : > "$GF"` is missing the `$` on the first redirect. The first command creates an empty file called `GF` in whatever directory the script was run from. The file exists in RUNS now (empty, created during the run). Run with the recovery checkout as working directory, it would add an untracked file there, break the frozen-state snapshot, and violate the no-write rule.
**Fix:** Delete the first redirect: `GF="$S/groups.txt"; : > "$GF"`. Also `cd "$RUNS"` at the top of every script so a mistaken relative write cannot reach the checkout.

### WR-05: `san` silently drops the last line of input that has no trailing newline

**File:** `scripts/lib-189.sh:290-300`
**Issue:** The loop is `while IFS= read -r l1 <&7 && ... read -r l3 <&9`. `read` returns non-zero for a final unterminated line, so the loop ends without processing it. Sanitised evidence then loses its last line with no error. For raw command output (a final `FAIL ...` without a newline), the missing line is the most important one. The callers that feed it with `printf '%s\n'` or `cut` are safe; `san < "$RAW"` and `printf '%s' ... | san` style uses are not guaranteed to be.
**Fix:** Append a newline before processing, or accept a partial last line:
```bash
{ cat; printf '\n'; } > "$o"   # then skip the one empty trailing line
# or: while IFS= read -r l1 <&7 || [ -n "$l1" ]; do ...
```
Add a selftest control that pipes an unterminated line.

### WR-06: Reflog id enumeration masks failures and treats "nothing found" as success

**File:** `scripts/lib-189.sh:150-175` (`reflog_ids`, `reflog_ids_all`)
**Issue:** The body is `printf ... | while read p; do awk ... "$p"; done | grep -v ... | sort -u` followed by `return 0`. An unreadable reflog file makes `awk` fail inside the loop, the pipeline status is `sort`'s, and the function returns 0 with fewer ids. `[ -n "$f" ] || return 0` also returns success with no output when no reflog files are found. Plan 02 later cross-checks against `git log -g --all`, which catches most of this, but `classify-tmp-189.sh` (`:104-107`) relies on the same helpers and only compares sets in the non-error case.
**Fix:** Test readability first and propagate: `[ -r "$p" ] || return 3` inside the loop, run `awk` over all files in one call (`awk '{print $2}' $files`) so its status is the pipeline's, and return 3 when `$f` is empty for a repository that has a `logs` directory.

### WR-07: `verify-189.sh --quick --plan NN` passes when the manifest for plan NN does not exist

**File:** `scripts/verify-189.sh:68-71`
**Issue:** `set_list` starts as `SHA256SUMS.02` and `SHA256SUMS.$plan` is appended only `if [ -f ... ]`. If the plan's manifest is missing the run still reports `ok` after verifying only plan 02. This is the "absence scored as success" shape. The no-`--plan` path has the same gap: it verifies whichever `SHA256SUMS.[0-9][0-9]` files exist, and a deleted manifest is simply not checked (reconcile does require 02-08, which limits the damage).
**Fix:**
```bash
if [ "$plan" != 02 ]; then
  [ -f "$VOUT/SHA256SUMS.$plan" ] || { echo "verify-189 quick: FAIL missing manifest $plan"; exit 1; }
  set_list="$set_list $VOUT/SHA256SUMS.$plan"
fi
```
For the all-plans path, compare the found manifests with a fixed expected list (02..08, 10).

### WR-08: Two gates in the temp-folder backup are printed or hard-coded, not enforced

**File:** `scripts/backup-tmp-189.sh:71-78` and `:247`
**Issue:**
1. The comment says the unique commits "must all be present in the restored bundle". The loop counts `N` present of `M` expected, but nothing compares them. A bundle missing a unique commit still records `pass`, taken from `record`. (The recorded run shows `unique_present 3 of 3`, so the data is fine, but the gate cannot fail.)
2. The `rows` mode appends `R-TMP-COMMITS ... pass` as a literal string, independent of the restore record.
**Fix:** After the loop add `[ "$N" -eq "$M" ] && [ "$M" -gt 0 ] || { res=fail; ...; die restore_failed; }`, and write the `R-TMP-COMMITS` result from the `tmp-commits.bundle` line of `restore-08.tsv` instead of a constant.

### WR-09: Classification helpers default to "yes" and treat a failed command as no differences

**File:** `scripts/classify-refs-189.sh:28`, `:32-38`, `:44`; `scripts/classify-reflog-189.sh:23-28`
**Issue:**
- `pu=$(gs ... cherry ... | awk ...)` returns 0 if `git cherry` fails (pipeline status is awk's).
- `pm=yes` is set before `while ... done < <(gs ... diff --name-only -z ...)`. If the diff fails or prints nothing, no path is compared and `pm` stays `yes`.
- The third rule `ahead>0 && pu==0 && pm==yes` then classes the branch "on main" with the reason "every changed path matches main". Both failure modes need a broken scratch repository, so this is unlikely, but it is the exact "empty output scored as pass" pattern, and "on main" is the class that later permits removal.
- `git diff --name-only` with rename detection lists only the new name of a rename, so the deleted old path is never compared against main.
**Fix:** Capture each command to a file, check its exit status, and only then derive counts; start `pm` at `no` and set `yes` after a successful, non-failed loop; use `diff --name-only --no-renames -z`.

### WR-10: The `[@]` neutralising sed in `scan-privacy-189.sh` is narrow in characters but not in context

**File:** `scripts/scan-privacy-189.sh:70`
**Issue:** The expression `s/\[${AT}\]/neutral-form-three/g` replaces the exact three characters and nothing else (checked against `189-EVIDENCE/scan-fix-10.txt`). A bare at-sign next to it still hits. But it removes the at-sign wherever those three characters occur, including the common anti-scraper spelling `name[@]host.example`, which the scan then reports as clean. Of the three neutralised forms, this is the only one that is also a recognised way of writing an address. The same applies, less plausibly, to `name@template_version 4` and `name$@host`.
**Fix:** Restrict it to bash expansion context so an address form is not exempt:
```bash
-e 's/\${[#!]\{0,1\}[A-Za-z_][A-Za-z0-9_]*\[@\]}/neutral-form-three/g'
```
That covers `"${prune[@]}"`, `${#a[@]}` and `${!a[@]}` (the cases the two hits came from) and leaves `name[@]host` flagged. Re-run the planted-address controls plus `x[@]y.example`.

### WR-11: The privacy scan is case-sensitive, has a very small credential list, and skips symlinks inside scanned directories

**File:** `scripts/scan-privacy-189.sh:30-37`, `:49-53`
**Issue:** The credential class is the two lower-case words in `P_CRED_ERE`. `Token`, `SECRET`, `password`, `api_key`, `Bearer`, `BEGIN ... PRIVATE KEY` are not matched. The user, git user and owner checks are case-sensitive (`grep -wF`, `-F`). When a list entry is a directory, `find -type f` omits symlinks, so a link to a file outside the scope is silently not scanned; a directory holding only links trips "empty directory", but a mix does not. The binary refusal uses `grep -I -c ''` on the original and is fine.
**Fix:** Add `-i` to the word/identity checks, extend `P_CRED_ERE` (`password|passwd|api[_-]?key|bearer|private key`), and make `find` fail (exit 2) on any symlink in scope: `find "$line" ! -type f ! -type d -print -quit` non-empty means refuse.

### WR-12: "Regenerable" is decided from folder names and marker files, so real content in those folders is excluded from backup

**File:** `scripts/lib-189.sh:211-282` (`regen_check`); used by `backup-ignored-189.sh:34,47-50`, `backup-env-189.sh:23-27`, `classify-tmp-189.sh:165,169`, `backup-tmp-189.sh:144,147`
**Issue:** A folder named `_build`, `deps`, `node_modules`, `build`, `.gradle` and so on is called regenerable if one marker exists (one `.beam`, a `mix.lock` entry per top-level dir, a `tmp` or `intermediates` dir under `build`). Only the top-level directories are checked. Loose files at the top of `deps` or `node_modules`, symlinks, a hand-patched dependency, or a hand-written note in `_build` are never examined. Any `bin/erl` makes a whole folder an "installed toolchain". Such folders get class `obsolete` and are removed from the keep list. `backup-tmp` records a sha256 list of excluded files (`.excluded`), which helps, but the other callers record only a KB figure and a kind.
**Fix:** Require that every regular file under the folder is accounted for by the marker rule (for `deps`, no loose files and every directory named in `mix.lock`; for `build`, `_build` and `node_modules`, no file newer than the lock file or outside a known child layout), or write a `.excluded`-style sha256 list for all callers so removal later can be checked against content.

### WR-13: Symlinks and unusual repositories are skipped without a failure

**File:** `scripts/backup-ignored-189.sh:72-73`, `scripts/backup-tmp-189.sh:137-139`, `scripts/backup-env-189.sh:28`, `scripts/classify-tmp-189.sh:57`
**Issue:**
- Ignored content: symlinks are only counted (`n_sym`) and echoed; no gate, and they are not archived, so a restore cannot recreate them.
- Temp-folder tar: `find ... -type f` skips symlinks and empty directories (the second is handled in gitdir jobs only).
- Env files: `find -type f` skips symlinked `.env` files.
- Nested-repo discovery uses `-maxdepth 5`. A repository deeper than that, or a bare repository (no `.git` entry), is never found, and its `.git` is pruned from the folder tar (`-name .git -prune`), so it is neither classified nor backed up.
**Fix:** Count symlinks and deeper `.git` entries in each case and fail (or record an explicit `not archived` row) when the count is non-zero; archive symlinks with `tar` when `-n` is used with explicit paths; replace `-maxdepth 5` with a full search, and also look for `HEAD`+`objects` pairs.

### WR-14: `reconcile-189.sh` accepts any restore cell containing the word "pass"

**File:** `scripts/reconcile-189.sh:179-183` (inventory row check), `:164-169` (backup named)
**Issue:** `okr` is set by `case $rs in *pass*)`, so `not pass`, `fail (bypass ...)` or `fail: no pass recorded` all satisfy it. The backup cell is satisfied by naming any file that exists in `<backup-root>`/OUT; it is not linked to a `pass` line for that artifact in a `restore-0N.tsv`. The global count check (`G == P`) is what actually protects the result.
**Fix:** For each `to land`/`unclassified` row, extract the artifact names and require a `restore-0N.tsv` line with that name and `$3 == "pass"`; match the restore cell with an anchored pattern (`^[^;]*: pass( |$)`).

### WR-15: Environment-file backup can report zero files after find errors, and hides worktree-listing failures

**File:** `scripts/backup-env-189.sh:23`, `:28`, `:36-41`, `:83-86`
**Issue:** Every `find` uses `2>/dev/null`, so a permission error on part of a tree gives fewer files with exit status ignored. `gr ... worktree list | sed | while read` is a pipeline, so a failing `gr` means no extra worktree is scanned and no error is raised. `total 0` ends with `exit 0` and no archive. In this run three files were found, so the result is not wrong, but the script cannot tell "none" from "could not look". Unregistered folders under `.claude/worktrees` (other than the pruned registered worktree) are excluded from the recovery scan and are not walked anywhere else.
**Fix:** Capture `find` status (`find ... > list; [ $? -le 1 ]`), read worktrees from a file after a checked `gr`, and make `total 0` fail unless the caller passes an explicit `--allow-none`.

## Info

### IN-01: Dead or no-op code

**File:** `scripts/verify-candidate-189.sh:126` (`if [ ! -s ... ] || true`, always true), `scripts/backup-tmp-189.sh:248` (awk piped to /dev/null), `scripts/reconcile-189.sh:58` (`HB` never used, key `refs/heads_dummy`), `scripts/classify-dirty-189.sh:66,119` (no-op statements), `scripts/backup-ignored-189.sh:91` (`{ echo "keep"; } >/dev/null`), `scripts/classify-tmp-189.sh:220` (`plan=$(printf '%s' "$plan")`).
**Fix:** Remove them.

### IN-02: Hard-coded counts and commit prefixes make the tools single-use

**File:** `scripts/backup-refs-189.sh:24,80`, `scripts/backup-dirty-189.sh:27-29,80`, `scripts/classify-refs-189.sh:21`, `scripts/reconcile-189.sh` (78, 248, 7, 3, 4), `scripts/classify-tmp-189.sh:255-256` (commit prefix `5923a679`), `scripts/verify-candidate-189.sh:45`.
**Fix:** Acceptable for a one-time phase, but note in the header that the constants are the 2026-10-16 expectations, or load them from one file.

### IN-03: `verify-candidate-189.sh` lets the incremental bundle row pass while the existing bundles show as changed

**File:** `scripts/verify-candidate-189.sh:81` and `:49-55`
**Issue:** `unch=no` fails the full-bundle row only; the incremental row has no `unch` term. `AHEAD` and `BEHIND` are not checked for emptiness before `-ne 90` (an error status makes that `blocked` test false). Evidence keys that are never produced are silently omitted at `:124`.
**Fix:** Add `[ "$unch" = yes ]` to the second condition, and guard `AHEAD`/`BEHIND` with a numeric test.

### IN-04: `san` appends a 12-character sha256 prefix of the raw line to every changed line

**File:** `scripts/lib-189.sh:297-299`
**Issue:** For low-entropy secrets or paths the prefix of a hash of the original line could be guessed offline. It is useful for tracing, but it is a small information leak into planning output.
**Fix:** Use a salted hash (salt kept in RUNS) or a per-run counter.

### IN-05: `gs` blocks verbs by exact name only

**File:** `scripts/lib-189.sh:100-102`
**Issue:** The verb is the second argument, so `gs DIR -c key=val push ...` would treat `-c` as the verb. `DIR` must still be scratch, so this cannot reach the checkout, but a scratch clone with the recovery checkout as `origin` could push into it.
**Fix:** Refuse any verb starting with `-`, and refuse `remote add`/`remote set-url` pointing at a non-scratch path.

### IN-06: Minor parsing gaps in `prs-189.sh`

**File:** `scripts/prs-189.sh:30-31`, `:53`
**Issue:** A title with a newline produces a multi-line table cell. The `uses:` grep pattern `^[-+][^-+]` drops a workflow line written `+- uses: ...` (a list item at column 0). Counts are substring matches, so `checkout@v3` also matches `checkout@v3.1`. The `D=$(... | grep | sed)` pipeline hides a failing diff and then reports 0 uses.
**Fix:** Collapse whitespace in the title, match `^[-+][[:space:]]*-?[[:space:]]*uses:`, and use `-F -x` style whole-reference matching.

---

_Reviewed: 2026-10-18_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
