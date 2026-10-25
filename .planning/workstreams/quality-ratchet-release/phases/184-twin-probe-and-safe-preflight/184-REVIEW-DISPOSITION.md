---
phase: 184-twin-probe-and-safe-preflight
review: 184-REVIEW.md
critical: 1
warning: 5
info: 2
recorded: 2026-10-15
---

# Phase 184 review disposition

The review found one critical issue, and the orchestrator reproduced it on git 2.41.0. In a scratch repo, `GIT_INDEX_FILE=<external> git read-tree HEAD` ran `.git/hooks/post-index-change`. Adding `-c core.hooksPath=/dev/null` stopped it. So the probe, the preflight and the real run's source gate all run code the candidate controls, which contradicts the phase's read-only, fail-closed goal. The verifier passed the phase (184-VERIFICATION.md, 4/4) because none of its checks cover hooks.

The user chose gap closure before completion (2026-10-15): Phase 184 stays open. The fixes go in a gap-closure plan as a second candidate commit on top of `feat(184-06)` (`1f5d18ee`). No twin run is needed, because twin-05 belongs to Phase 188.

| ID | Severity | Disposition | Note |
|----|----------|-------------|------|
| CR-01 | critical | closed in 184-07/184-08 | Fix is pin only: `core.hooksPath=/dev/null` on every pinned git call, no refusal of a local `core.hooksPath`, because a command-line `-c` overrides every config file and the config-injection variables are already unset. Proven by the local `core.hooksPath` test and mutation controls 1-2. Commit 3786de95b2b2b8435c3378fd1d194e0fecd84df5 (D-34 in 184-CONTEXT.md). |
| WR-01 | warning | reopened (see GAP-CR-01 below) | The probe lists ignored untracked entries and counts any whose deciding rule is not a `.gitignore` tracked in HEAD or `info/exclude`. A root or nested ignore-all `.gitignore` now blocks with `source_dirty`; a committed `.gitignore` still does not count (disclosed limit unchanged). Mutation control 3. |
| WR-02 | warning | closed in 184-07/184-08 | `lock_digests` returns `{:blocked, :identity_unknown}` on an unreadable lock file; `file_digest` returns `{:error, _}` on a directory or mid-stream read error, never a prefix digest; the preflight task rescues/catches to exit 2 with a fixed path-free action. Mutation controls 4, 8, 12. |
| WR-03 | warning | closed in 184-07/184-08 | Moduledocs and guide now say a private temporary index is created and removed outside the candidate and run root, and the origin port is bound briefly; line 3 of the output unchanged (D-14). A test proves the temp index is in TMPDIR. Mutation control 9. |
| WR-04 | warning | closed in 184-07/184-08 | `commit/1` removes a run root only when its own `mkdir` succeeded. Mutation control 7. |
| WR-05 | warning | kept by decision (D-31) | No code change. The preflight-only digest comparison stays; the moduledoc and guide state the real run does not repeat it. Open item for Phase 188 TWIN-07 ("matching digests"), where the scripted pre-run check gates the real run. |
| IN-01 | info | closed in 184-07/184-08 | The effectful-path test reads through `__DIR__` anchors, asserts positive anchors and refutes bare calls, atoms and capture references; a matcher sample test proves each shape is caught. Mutation controls 10, 11, 13. |
| IN-02 | info | closed in part; orphan deferred | Every inherited `GIT_*` variable is unset by prefix at spawn and the spawn body is total (mutation controls 5, 6). Deferred: an OS git child can outlive a timed-out task; reopen if a hung or leftover git process is seen during a preflight or twin run (code comment in `twin_producers.ex`). |

Separately, a carried-forward debt that is not a review finding: `mix crosswake.adoption_context.scan` exits 1 at `50fcd57` with five `routing.unclassified_path` findings under `examples/phoenix_host/native/ios/crosswake_shell/`. 184-06 gated on the findings matching HEAD exactly (`/private/tmp/crosswake-phase180-run/adoption-scan-head-184.findings`). Any later gate that needs exit 0 has to classify those paths first.

## Gap-closure review (184-REVIEW-GAPS.md, over 3786de95)

The review of the fix commit found that the WR-01 fix opened a new way to report clean wrongly. The orchestrator reproduced it on 2026-10-15 in a scratch repo: an untracked folder named `info/exclude:1:z` containing a `.gitignore` of `*` and a hidden `.ex` file probed `{:ok, %{modified: 0, flagged: 0, excludes: 0}}`, while the same layout in a plain `z/` folder probed `modified: 3`. Cause: `parse_ignore_sources` reads the rule source with a lazy regex up to the first `:<digits>:`, and `uncommitted_rule?` trusts any source whose last two path parts are `info/exclude`. Phase 184 stays open.

| ID | Severity | Disposition | Note |
|----|----------|-------------|------|
| GAP-CR-01 | critical | closed in 184-09/184-10, fix commit b5399e51 (mutation controls 1-9 and 11 prove it): D-35. `check-ignore -z` via a private stdin file, NUL-only parsing with separate framing and path-binding checks, exact trust of info/exclude or a tracked .gitignore. Tests: "a directory named like info/exclude:1:z cannot hide untracked source", "a directory named like .gitignore:1:x beside a committed .gitignore cannot hide untracked source", and the preflight test; red on 3786de95. Original note: Spoofed rule source hides untracked source files (reproduced). Proposed fix: `check-ignore -z` (via stdin, or a parse that never splits on `:`), and trust only the exact `.git/info/exclude` path or a `.gitignore` tracked in HEAD. Correct the guide's "is counted" claim. |
| GAP-WR-01 | warning | closed in 184-09/184-10, fix commit b5399e51 (mutation control 1 proves it): D-35, test "a committed .gitignore in a directory with a quoted name is not counted". Original note: A tracked `.gitignore` under a directory with a quoted name is counted as uncommitted; fails closed with the wrong reason. Covered by the same `-z` fix. |
| GAP-IN-01 | info | fixed in 184-09, committed in b5399e51 (mutation control 10): the listing no longer collapses folders; test "the ignored listing names files, never collapsed directories" pins the argv. Original note: Collapsed ignored directories are skipped on the assumption git 2.41 lists their members; unchecked on newer git. Drop `--directory` or add a guard test. |
| GAP-IN-02 | info | kept deferred by decision (D-36): orphan git child (reopen: a hung or leftover git observed in a preflight or twin run); submodule config (no gitlink or .gitmodules in the candidate: gitlink count 0 at b5399e51; reopen: any HEAD with a mode-160000 entry or .gitmodules). Original note: Orphan git child on timeout still deferred; status in initialized submodules may run submodule config that `config_refusal` does not check (untested). |

## Second gap-closure review (184-REVIEW-GAPS-2.md, over b5399e51)

The review of `fix(184-10)` confirmed that GAP-CR-01, GAP-WR-01 and GAP-IN-01 are closed. It also found two more ways the probe can report clean, and both predate this commit (they reproduce at 3786de95). The orchestrator reproduced both on 2026-10-15 with git 2.41.0 in scratch repos. First: a top-level untracked folder `:deps/` holding a `.gitignore` of `*` and an `evil.ex`, beside a committed root `.gitignore` of `/deps/`. Plain `git status` showed nothing, and `check-ignore --stdin -z` attributed both files to `.gitignore:1:/deps/` while echoing the path as sent. Git reads each stdin path as a pathspec, so the leading `:` was taken as pathspec magic. Second: `.git/info/exclude` holding the line `"  #*"` hid an untracked `"  #evil.ex"`. The probe's `String.trim` treats that line as a comment, so the file counts neither as modified nor as an exclude rule. Phase 184 stays open.

| ID | Severity | Disposition | Note |
|----|----------|-------------|------|
| GAP2-CR-01 | critical | closed in 184-11/184-12 (commit e4344ca5; proven by controls 12, 13, 14 and 15): D-37 | Tests: the :deps, :(top)deps, : holding deps, :!deps, glob-name, echo-binding and :deps preflight tests. Original: Pathspec magic in a stdin path (`:deps/`, `:(top)deps/`) makes `check-ignore` judge a different path than the one echoed, so a committed rule is trusted for hidden untracked source (reproduced). Proposed fix: send `./<entry>` and bind each record to that exact text; `--literal-pathspecs` is rejected by check-ignore. |
| GAP2-CR-02 | critical | closed in 184-11/184-12 (commit e4344ca5; proven by controls 12, 13, 16 and 17): D-38 | Tests: the spaces-before-#, tab-only, hidden-file-counts, inactive-line and spaces preflight tests. Original: The info/exclude rule count trims lines in a way git does not (`"  #*"`, tab-only lines), so a rule git applies is counted as a comment or a blank line (reproduced). Proposed fix: count lines exactly as git parses them, or count every path whose deciding source is info/exclude. |
| GAP2-IN-01 | info | closed in 184-11/184-12 (commit e4344ca5; proven by docs only, no control): D-38 | Comments and docs rewritten; see D-38 (e). Original: The `git_invocation` comment and the `dirty_counts` doc still describe the old model. |
| GAP2-IN-02 | info | closed in 184-11/184-12 (commit e4344ca5; proven by control 18): D-38 | Test: the check-ignore input-file mode and removal test. Original: `check-ignore.in` lists ignored path names (never contents). Its file mode comes from the umask, so only the 0700 parent folder protects it, and it is left behind if the VM is killed. |
| GAP2-IN-03 | info | closed in 184-11/184-12 (commit e4344ca5; proven by controls 12 and 13 (the new tests fail on b5399e51)): D-38 | Tests: the pathspec-magic and info/exclude parsing tests listed above. Original: No tests cover pathspec magic or how info/exclude lines are parsed. |

GAP2 closure (184-12): the two reproduced layouts, a top-level folder named like a pathspec (such as :deps) beside a committed ignore rule and an info/exclude line that starts with spaces or holds only a tab, now both block in the probe and in the preflight. The fix is the single candidate commit e4344ca523a56e146d9e8647ec141b9714e8180f on b5399e51.

## Third gap-closure review (184-REVIEW-GAPS-3.md, over e4344ca5)

The review found the D-37 (`./` prefix, exact binding) and D-38 (info/exclude counted, git-exact lines) fixes sound. It found two other fail-open paths. The orchestrator reproduced the mechanism of both with git 2.41.0 in a scratch repo on 2026-10-16:
- A folder mode 0111 holding a file: `git ls-files --others --exclude-standard` and `git status --porcelain` list nothing for it, print only a warning to stderr, and exit 0.
- `String.trim/1` strips a leading NBSP from `<NBSP>#x ident`, so `attributes_line_active?` reads it as a comment, while `git check-attr ident` reports the attribute set for a path named `<NBSP>#x`.

| ID | Severity | Disposition | Notes |
|----|----------|-------------|-------|
| GAP3-CR-01 | critical | closed in 184-13/184-15/184-14 (commit b898e110, controls 19, 20, 21 and 22): D-39 | Tests: an untracked folder git cannot open makes the probe unavailable; a git call that also writes to stderr makes the probe unavailable; a check-ignore call that also writes to stderr makes the probe unavailable. A folder git cannot open hides untracked source: git warns on the discarded stderr and exits 0, so the probe reports all zeros (reproduced). Proposed fix: capture stderr and return `:unavailable` when it is non-empty, or fail on any folder that cannot be listed. |
| GAP3-CR-02 | critical | closed in 184-13/184-15/184-14 (commit b898e110, controls 21, 22, 23 and 26): D-40 | Tests: an info/attributes line that starts with a no-break space before # is refused; core.symlinks written as 00 is refused. `attributes_line_active?` uses `String.trim/1` (Unicode whitespace), but git's blank set is ASCII only, so an info/attributes line `<NBSP>#x ident` is not refused and a tracked file's `$Id$` expansion can hide a change (reproduced). Proposed fix: strip only ASCII space, tab, CR and LF and test byte 0 for `#`. |
| GAP3-WR-01 | warning | closed in 184-13/184-15/184-14 (commit b898e110, controls 21 and 25): D-41 (pinned, not refused) | Tests: a local core.ignorecase=true cannot widen a committed rule to another letter case; a case-only rename of a tracked file blocks. A local `core.ignorecase=true` is not refused, so a committed `deps/` rule is trusted for an untracked `DEPS/x` (reproduced by the reviewer). |
| GAP3-IN-01 | info | closed in 184-13/184-15/184-14 (commit b898e110, controls 21 and 24): D-40 (b) | Tests: an info/exclude line ending in two CRs is one rule. The excludes count is not git-exact for a `\r\r\n` line ending (count 0 where git sees one rule). Hides nothing, because hidden files now count anyway. |
| GAP3-IN-02 | info | closed in 184-13/184-15/184-14 (commit b898e110, guide pin test, no control): D-42 | Tests: the twin source check paragraph states the exact-case limit, unusual names and the unreadable-folder block. The guide's "whatever the folder or file is called" wording and its known-limit text need updating once the fixes above land. |

The fourth gap closure is landed as one candidate commit (b898e110). A folder git cannot open now blocks the twin source check as a missing prerequisite instead of passing. An info/attributes line that starts with a no-break space now blocks as a configuration that can hide changes. A local case-insensitive setting can no longer stretch a committed ignore rule to another letter case. The real candidate still probes clean, both as a full copy of the committed tree before the commit and as the committed candidate after it.

## Fourth gap-closure review (184-REVIEW-GAPS-4.md, over b898e110)

The review found no critical finding: D-39..D-42 held under every attempted bypass, and a copy of the candidate still probes clean. Rows default to open; the orchestrator triage note says how each one relates to the phase goal.

| ID | Severity | Disposition | Note |
|----|----------|-------------|------|
| GAP4-WR-01 | warning | open | A FIFO at `.git/info/attributes` makes `probe_source/2` wait forever (untimed `File.read` before any timed git call). Reproduced. The preflight never reports allowed, so nothing passes by mistake, but a read-only check can hang. |
| GAP4-WR-02 | warning | open (within the D-36 (b) deferral) | Untracked files inside a gitlink folder with no repository are invisible to git and probe clean. Reproduced in a scratch repo. The candidate has zero mode-160000 entries (184-14 gitlink count 0), so the D-36 reopen trigger is not met; the guide wording reads as complete coverage. |
| GAP4-IN-01 | info | open | Untracked FIFOs and sockets are skipped by git and probe clean. They hold no source text; disclose in the guide. |
| GAP4-IN-02 | info | open | Some legitimate config spellings (for example `core.symlinks=0x1`, `core.bare=0x0`) are refused. This fails closed, as accepted in D-40, but the doc phrase "read as git spells them" and the `:hiding_config` advice overstate it. |
| GAP4-IN-03 | info | open | Three small risks. Any stderr byte blocks, so a future git advisory would block every candidate (not reproduced; git 2.41 only). The unlistable-folder tests need a non-root user. An NFD name committed under `core.precomposeunicode=false` false-blocks under the macOS default (pre-existing, reproduced). |
