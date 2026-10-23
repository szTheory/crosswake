# Phase 184: Twin probe and safe preflight - Context

**Gathered:** 2026-10-15
**Status:** Ready for planning

<domain>
## Phase Boundary

This phase makes two guarantees and is limited to them:

1. **The twin refuses source that differs from HEAD.** Any candidate whose tracked files differ from HEAD in content or mode is refused, however git is set up to hide the difference.
2. **A maintainer can ask before running.** They can find out whether a twin run would be allowed without creating, consuming or leaving behind a run root.

**Requirements:** PROBE-01, PROBE-02, PROBE-03, PROBE-04.

**Where the work happens:** product code changes only in the candidate `/private/tmp/crosswake-phase180-impl`, starting from `50fcd57`.

**Not in this phase:**
- Phase 185: the absence checker, `stop_children` and `lock_digests`.
- Phase 186: the doctor and seam work.
- Phase 188: the freeze and twin-05 run. Phase 188 uses this phase's preflight.

</domain>

<decisions>
## Implementation Decisions

**How these were decided.** The user chose all four gray areas and asked for a fan-out: research, an adversarial pass, then one coherent set of recommendations to be followed without further questions. That process ran as follows:
- Four Sonnet advisor researchers, one per area.
- One adversarial reviewer. It tested every hiding mechanism in scratch repos on git 2.41.0 (and Apple git 2.50.1), with HOME pointed at an empty directory.
- The orchestrator synthesized the results.

The verified evidence is summarized under `<specifics>`.

### Probe semantics (PROBE-01)

- **D-01: Primary signal.** Compare the worktree with a fresh index built from HEAD.
  - Set `GIT_INDEX_FILE` to a file in a private temp directory. That directory must be outside the candidate, outside its `.git`, and outside the run root.
  - Run `git read-tree HEAD`, then `git status --porcelain=v1 -z --untracked-files=all --ignore-submodules=none` against that index.
  - Delete the temp directory in an `after` block.
  - If the temp directory cannot be created or removed, the result is `prerequisite_missing`, never clean.
  - A fresh index has no stat cache. This defeats assume-unchanged, skip-worktree, `core.ignoreStat`, `core.checkStat=minimal` and `core.trustctime=false` all at once.
- **D-02: Flagged signal (second signal).** Run `git ls-files -v -z` on the **real** index.
  - Every entry whose tag is not `H` counts as flagged. This includes `h`, `S`, `s` and `M` (unmerged). It settles a conflict between researchers in favour of PROBE-01's rule; the reviewer showed unmerged stages can survive in the index.
  - Count unique paths. An unmerged path appears once per stage, so remove duplicates.
  - A tag outside git's documented alphabet `[HhSsMmRrCcKk?]` fails closed as `prerequisite_missing`.
  - Zero tracked entries fails closed. So does a failed `read-tree HEAD`, as in an empty repo.
  - In the fresh index, every entry must be `H`; anything else fails closed.
- **D-03: Exclude-rule signal.** Keep the existing count of active rules in `.git/info/exclude`.
  - The reviewer confirmed the fresh-index status shows nothing for an exclude rule. This count is the only thing that catches it.
- **D-04: Configuration that can hide changes is refused.** When any of these is found, the result is `source_dirty` with `measure: nil` and its own next action. Pins cannot neutralize them:
  - `realpath(git rev-parse --show-toplevel)` is not equal to `realpath(candidate)`. A `core.worktree` redirect makes status completely clean and `-c core.worktree=` cannot undo it. A subdirectory candidate is also refused, which is correct.
  - Any key starting with `filter.` (case-insensitive) in `git config --list --local --includes --name-only`.
    - `--includes` is required; without it, filters in `include.path` files are missed.
    - Refuse the whole prefix rather than listing clean/smudge/process.
  - A non-empty `.git/info/attributes`. Together with a config filter, it fools even the fresh index, and `--attr-source` does not help.
  - `extensions.worktreeConfig`, `core.bare=true` or `core.symlinks=false` in local config.
  - Accepted side effect: repos that use LFS or eol filters fail closed. This is noted, not fixed.

### One git configuration (PROBE-02)

- **D-05: One shared builder.** A single private function in `TwinProducers` builds the argv and env for **every** twin git call, so nothing has a second path (183 IN-01). It covers `freeze/3`, `checked_identities/3`, `observe_identities/2`, the probe, `dirty_count(s)` and the toplevel and config reads.
  - **Top-level argv, before the subcommand:**
    - `--no-optional-locks` (top-level only; `status --no-optional-locks` is an error)
    - `--no-replace-objects`
    - `--attr-source=4b825dc642cb6eb9a060e54bf8d69288fbee4904` (the empty tree). This neutralizes in-tree `.gitattributes` filters.
    - `-c core.fsmonitor=false`. Verified: a repo-local fsmonitor script really runs during status without this pin.
    - `-c core.filemode=true`. The fresh index alone does not catch `filemode=false`.
    - `-c core.excludesFile=/dev/null`
    - `-c core.quotePath=false`
    - `-c core.ignoreStat=false`
    - `-c status.showUntrackedFiles=all`
    - `-c core.autocrlf=false`
    - `-C <candidate>`
  - **Env:**
    - The existing scrub list, plus `GIT_ATTR_SOURCE`, `GIT_EXTERNAL_DIFF` and `GIT_EXEC_PATH` set to nil.
    - `GIT_CONFIG_COUNT` set to nil, which disables `GIT_CONFIG_KEY_*`. There is no glob unset.
    - `GIT_CONFIG_GLOBAL=/dev/null`, `GIT_CONFIG_NOSYSTEM=1`, `GIT_NO_REPLACE_OBJECTS=1`, `GIT_ATTR_NOSYSTEM=1`.
    - Keep `GIT_OPTIONAL_LOCKS=0`, `GIT_TERMINAL_PROMPT=0` and `LC_ALL=C`.
    - Only `GIT_INDEX_FILE` is set per call, and only for the fresh-index pair.
  - **Cut after the adversarial pass** as unnecessary: `core.hooksPath`, `core.splitIndex`, `core.sparseCheckout`, `core.untrackedCache`, `core.checkStat`, `core.trustctime`, `HOME`, `XDG_CONFIG_HOME` and `GIT_CONFIG_SYSTEM`. These were verified harmless but redundant.
  - Keep stderr discarded at the fd level, and keep the candidate path an argv element only.
- **D-06: Git version floor.** Require at least 2.41, the newest version tested here.
  - Check it with one major.minor compare of `git --version`. Anything unparseable or lower is `prerequisite_missing`.
  - Never retry without a flag; a retry is a silent downgrade.
  - A rejected argv (rc 128/129) maps to the same cause.
- **D-07: Path-free failures (183 IN-04).** Any non-zero exit, spawn failure, timeout, truncated or unparseable `-z` output, or rejected argv yields `prerequisite_missing`, the existing "unavailable" cause.
  - The message must not contain the candidate path, `$HOME` or a username.
  - No new cause atoms. The receipt schema version is unchanged; `:source_dirty` and `:prerequisite_missing` are already in `@causes`.
- **D-08: A reason channel.** `clean_tree` currently returns only an atom. Return a reason alongside the cause so the task can write a distinct line 4 for modified, flagged, exclude-rule, hiding-config and unknown cases.
  - Example shape: probe returns `%{modified: m, flagged: f, excludes: x}`, or `{:refused, :hiding_config}`, or `:unavailable`.
  - Add `dirty_counts/2` that returns the map or nil.
  - `dirty_count/2` stays as a function returning the sum or nil.

### Dirty message and counts (PROBE-03, 183 WR-03/WR-04)

- **D-09: Line 2 stays the stable token.** The `first cause:` line stays `source_dirty`, and all prose goes on line 4. The four-line contract is unchanged: one line, no newlines.
- **D-10: Line 4 clauses.** Each non-zero count gets its own clause, joined with "; and" in the order M, F, X. A zero count drops its clause. Singular and plural forms are both handled.
  - **M:** "N changed or untracked files"
  - **F:** "N tracked files marked unchanged in git's index (assume-unchanged or skip-worktree flags), so edits to them would go unseen". This clause names the exact commands: `git update-index --no-assume-unchanged` / `--no-skip-worktree`, and `git ls-files -v` (look for entries not marked H).
  - **X:** "N local ignore rules in .git/info/exclude". Never the word "files".
  - **Hiding config:** "the candidate's git configuration can hide changes (a worktree redirect, a filter, or .git/info/attributes); remove it".
  - **Unknown:** "changes git could not count". This text contains no digit.
  - **Shared tail:** "…, then write a new prepared record and run into a new run root."
  - **Overlap:** a path can be both modified and flagged. Clauses count findings, not distinct files, and the documentation says so.
- **D-11: Receipt `measure`.** `measure` is `M+F+X` as an integer of findings, or nil.
  - Bound the sum, not each part, by the existing 1_000_000 (`@max_measure`). Above the bound, `measure` is nil and the message uses the unknown text.
  - nil means unknown, never clean, and the `dirty_count` doc says so.
  - The breakdown appears only in line 4. The schema is unchanged.

### Preflight entry point (PROBE-04)

- **D-12: A separate task and module.**
  - Command: `mix crosswake.proof_lane.twin_preflight ios --candidate <record> --run-root <dir> --identity <IDENTITY.json>`.
  - Module: `Crosswake.ProofLane.TwinPreflight` with `check/1`.
  - Use this, not a `--preflight` flag on `verify_twin`. Being read-only is structural: the task never calls `TwinRuntime.prepare/1`'s effectful tail, `blocked_receipt`, `write_and_verify` or `write_expectations`.
  - Use strict `OptionParser`; the only positional is `ios`.
  - Provide an `execute/2` seam returning `{status, four_lines}`. `System.halt` is called only in `run/1`.
- **D-13: `--run-root` is required.** A missing root is blocked with `prerequisite_missing` and next action "Name the private run root you plan to use".
  - Preflight never calls the branch that creates a root.
  - This was a conflict between researchers. It was resolved because the 188 go/no-go depends on the root checks.
- **D-14: Output and exit codes.**
  - Four lines:
    - `result: allowed|blocked`
    - `first cause: none|<atom>`
    - `report: none written; no run root was created or consumed`
    - `next action: <plain text>`
  - When the result is `allowed`, line 4 says: "Source and run root pass and the origin port is free at this moment; the backend build and the live journey are checked only by the real run."
  - Exit 0 means allowed. Exit 2 means blocked, for every cause, including bad options and an unreadable identity.
  - Never exit 1, which means an observed failure, and never `Mix.raise`.
  - No `--format json`.
  - Docs call it "preflight", never "go/no-go".

### Preflight depth: one shared set of checks (PROBE-04)

- **D-15: Split `TwinRuntime.prepare/1`.**
  - A pure `check/1`, in the existing order:
    1. run root: exists, is a directory not a symlink, mode 0700, **owned by the current user** (new)
    2. `not_reused`
    3. candidate record
    4. outside candidate
    5. database path
    6. origin parse
    7. origin port bindable
  - An effectful `commit/1`: create the root when nil (the run only), acquire and hold the listener, start the Agent.
  - `prepare/1 = check |> commit`.
  - The owner check is a new behaviour in the real run and gets its own test.
- **D-16: Split `TwinProducers.freeze/3`.**
  - `source_gate/3`: `read_identity`, HEAD/tree `same`, `clean_tree`, `lock_digests`, file digests.
  - The tail: `backend_digest` compile, then `write_expectations`.
  - `freeze/3` calls `source_gate/3` as its single entry, in the same order. Preflight runs `check/1` and `source_gate/3` only.
- **D-17: Origin port.** Do a bind-and-release probe, with the release in `after`.
  - The output says "free at this moment".
  - Keep it, because an occupied port is the most likely way twin-05 gets blocked.
  - A probe error is blocked, never allowed.
- **D-18: Identity check.** Compare the identity file's manifest, activation and media digests with the candidate record's `resource_digests`/`fixture_digests`.
  - If the planner finds the shapes cannot be compared, the output must say this check was not made. It must never be silently skipped.
- **D-19: Out of preflight.** These are excluded and named as unchecked in line 4 (see D-14):
  - the backend compile, which writes `_build`;
  - any write, including receipt, `twin-result.json` and `expectations.json`.
- **D-20: Preflight is never a token.**
  - The real run re-runs every check, and nothing records "preflight passed".
  - An empty check list returns an error, never ok.

### Tests (PROBE-03, acceptance boundaries)

- **D-21: Real temporary git repos.**
  - **Fixtures:** one per mechanism. Each asserts a `source_dirty` block, and an untouched control passes.
    - assume-unchanged, skip-worktree, `core.ignoreStat`
    - `checkStat=minimal` and `trustctime=false`. These must be **same-size, same-mtime edits** to be load-bearing; ordinary status caught naive edits.
    - `filemode=false`, set locally and globally. The global case writes a config file and points `GIT_CONFIG_GLOBAL` at it in the test, asserting that unpinned git is fooled and the pinned run is not.
    - untracked file, exclude rule
    - `core.worktree` redirect, config filter with `info/attributes`, tracked `.gitattributes` filter
    - `submodule.<n>.ignore=all` (only if cheap), unmerged entry
    - zero tracked entries, unknown tag (through an injected `git_cmd`), git failure and truncated output, temp-dir failure
  - **Builder test:** fails if any twin git call site bypasses the shared builder.
  - **Exact strings:** exact-string assertions for each line-4 case (only M, only F, only X, mixed, hiding config, unknown), plus a no-digit check on the unknown text and a "no 'files' in the X clause" check.
  - **Privacy:** a scan proving no output contains the candidate path or `$HOME`.
  - **Four lines:** an exact four-line assertion for both tasks.
  - **Preflight leaves nothing behind:** directory listings before and after of the given root, the candidate and the candidate's `.git`, for each of these cases:
    - allowed
    - dirty
    - reused root
    - missing root
    - bad record
  - **Same causes:** a table test asserting `prepare/1` and `check/1` give the same first cause on the same inputs.
  - Existing `verify_twin` tests still pass.
- **D-22: Mutation controls.** For each guard, a recorded mutation control: revert it and name the test that fails. Guards: fresh index, filemode pin, flagged count, exclude count, toplevel check, filter refusal, attr-source, builder use.
  - A cited test that runs 0 tests counts as a failure.

### Research amendments (adopted 2026-10-15 during plan-phase)

Phase research (`184-RESEARCH.md`, items L1–L19) found that some decisions above do not work exactly as written. Under the user's standing instruction to follow the synthesized recommendations without further questions, the orchestrator adopted each recommendation. These amend D-01..D-22. Where they conflict, the amendment wins.

- **D-23: Pin `core.attributesFile` (amends D-05, L1).** Add `-c core.attributesFile=/dev/null` to the shared builder's argv.
  - Reason: a user-level attributes file (`$XDG_CONFIG_HOME/git/attributes`) hides a CRLF-only edit even with `--attr-source` and `GIT_CONFIG_GLOBAL=/dev/null`.
  - It needs its own fixture and a mutation control.
  - HOME and XDG_CONFIG_HOME stay unscrubbed, as D-05 says.
- **D-24: Read config values with `-z` (amends D-04, L2, L12).**
  - Read config with `git config --list --local --includes -z`. Downcase keys before matching the `filter.` prefix.
  - Read config before calling `rev-parse --show-toplevel`. That way `core.bare=true` gives the hiding-config refusal instead of `prerequisite_missing`.
  - `extensions.worktreeConfig` is refused when its value is true.
  - `.git/info/attributes` counts as non-empty when it has any active line, meaning a line that is neither blank nor a comment.
- **D-25: Toplevel identity by device and inode (amends D-04, L3).** Compare git's toplevel with the candidate by device and inode, as `outside_candidate` already does. Do not compare realpath strings: macOS `/var` → `/private/var` and `/tmp` → `/private/tmp` aliases would break that.
- **D-26: Fixture corrections (amends D-21, D-22, L4, L5).**
  - The global `filemode=false` fixture first runs `git config --local --unset core.filemode`.
  - The attr-source fixture uses a tracked `text eol=lf` attribute with a CRLF-only edit, not a filter.
  - The filter refusal, the info/attributes refusal and the attributesFile pin each get a fixture that only that guard catches.
  - The mutation-control list adds: info/attributes refusal, attributesFile pin, temp-index containment and the owner check.
- **D-27: A staged rename counts as 2 (amends D-09 counting, L6).** Under the fresh index, a staged rename shows as a deletion plus an untracked file. The existing rename test is updated to 2 and renamed, and the documentation sentence about counting changes with it.
- **D-28: Temp index must be absolute and contained (amends D-01, L9).**
  - Reason: a relative `GIT_INDEX_FILE` writes into the candidate.
  - The temp path must be absolute and checked by device and inode to lie outside the candidate, its `.git` and the run root. Otherwise the cause is `prerequisite_missing`.
  - A test runs with `TMPDIR` inside the candidate and asserts that nothing is created there.
- **D-29: Spawn errors (amends D-07, L10).** The single spawn site rescues both `ArgumentError` and `ErlangError`, and refuses a candidate path containing NUL before spawning. A test injects a raising stub whose message carries a distinctive path, and asserts that the path does not leak.
- **D-30: Version compare (amends D-06, L11).**
  - Parse `{major, minor}` as integers from `~r/\Agit version (\d+)\.(\d+)/`.
  - Run the version call without the pinned argv, because git older than 2.40 rejects the pins with exit 129 and would hide the real reason. It still uses the scrubbed env.
- **D-31: Preflight details (resolves research open questions 2–5).**
  - Line 1 is exactly `result: allowed` or `result: blocked`, with no `(exit N)` suffix, locked by an exact-string test.
  - The owner check reads the uid via `id -u` through an options seam, and fails closed.
  - The D-18 record-to-identity comparison is preflight-only in this phase; a mismatch blocks with cause `identity_mismatch`, which is already in `@causes`, so no new atom is added. The real run still re-derives the digests from the identity file, which is disclosed. Making the real run enforce it is left to Phase 188's go/no-go.
- **D-32: Bound constants stay equal (L14).** A test pins `@max_dirty_count` in TwinProducers equal to `@max_measure` in TwinReceipt.
- **D-33: Disclosed behaviour changes (L15–L17).**
  - Because global config is ignored, a candidate owned by another user is refused under `safe.directory` (`prerequisite_missing`).
  - Filesystems without filemode give a false `source_dirty`.
  - A probe makes about 10 git spawns, roughly 0.16 s on the real candidate, with no caching.
  - These are noted in the guide or code docs. No code is needed beyond what D-01..D-32 already require.

### Gap-closure amendments (2026-10-15)

- **D-34: Pin core.hooksPath (amends D-05, review CR-01).** D-05's cut of `core.hooksPath` is reversed. The pin `core.hooksPath=/dev/null` is in the shared git builder, so every pinned call runs with hooks disabled. A local `core.hooksPath` is not refused. A command-line `-c` overrides every config file and the config-injection variables are already unset, so a refusal would add nothing. Proven by the local `core.hooksPath` test and mutation controls 1-2 (184-08, commit 3786de95).
- **D-35: Exact ignore-rule parsing and trust (amends the 184-07 WR-01 design, review GAP-CR-01, GAP-WR-01, GAP-IN-01).** The ignored-path listing no longer collapses directories, so every ignored path is judged as a file and correctness does not depend on how a git version lists collapsed folders. The deciding rules come from one `check-ignore --verbose --non-matching --stdin -z` call; git 2.41 rejects `-z` without `--stdin`, so the paths are written NUL-separated to a file in the private temporary index directory (0700, outside the candidate, removed afterwards) and read as stdin through a new form of the shared git builder. The path is an argv element, never script text. The output is parsed only by splitting on NUL, in two separate checks: a framing check (exactly four fields per sent path) and a path-binding check (each record names, byte for byte, the path sent at that position; the line number is empty exactly when the source is empty). No field is split on a colon. A rule source is trusted only if it is the exact `info/exclude` path git reports (counted by excludes, D-03) or a `.gitignore` that is an exact entry of the fresh HEAD index. Every other source, including an empty one, counts as a modified finding, so folders named like `info/exclude:1:z` or `.gitignore:1:x` cannot hide source and a quoted folder name no longer causes a false block. No new cause, line-4 clause or receipt field (D-07, D-14). Proven by the named tests in twin_source_probe_test.exs and the preflight test, recorded red on 3786de95 (184-09).
- **D-36: IN-02 dispositions (review GAP-IN-02).** (a) Orphan git child after a timeout: the deferral is kept. Task.shutdown closes the port, but a git that hangs without writing may outlive it; macOS has no portable timeout utility and each call is bounded at 60 s. Reopen trigger: a hung or leftover git process observed during a preflight or twin run. (b) Submodule configuration reached by `status --ignore-submodules=none`: deferred with evidence. The candidate has no gitlink entry and no .gitmodules (zero mode-160000 entries at 3786de95; 184-10 records the count again), and refusing gitlinks would need new line-4 wording, which D-07 and D-14 rule out this round. Reopen trigger: any candidate whose HEAD has a mode-160000 entry or a .gitmodules file.
- **D-37: Literal paths for check-ignore (amends D-35 (b) and (c), review GAP2-CR-01).** Git reads every path sent to check-ignore on stdin as a pathspec, so a folder named :deps, :(top)deps or : could make git judge a different path than the one listed and credit a committed rule such as /deps/ to hidden untracked source. Each listed entry is now written to the check-ignore input as the text ./ followed by the entry, then NUL; the leading ./ makes git skip pathspec magic for that line. Checked during planning on git 2.41.0 in scratch repos: for an untracked folder :deps beside a committed /deps/ rule, the bare path was credited to .gitignore line 1, while ./:deps/evil.ex was credited to the untracked :deps/.gitignore (so it counts). The same held for :(top)deps and for a folder : holding deps/. For :!deps, :^deps, :(exclude)deps, :(glob)deps, :(icase)DEPS and :(attr:x)deps the bare path made check-ignore exit 128 (fail-closed, but every such candidate unavailable) and ./ gave the true source. Names with brackets, stars, question marks or backslashes were already judged literally and stay so. The path-binding check now compares each returned record with the exact sent text, ./ plus the entry, byte for byte; the framing check and the binding check stay separate. Rejected alternatives, both checked on git 2.41.0: the --literal-pathspecs option and the GIT_LITERAL_PATHSPECS=1 environment make check-ignore exit 128 (pathspec magic not supported by this command), so every candidate would be unavailable. The reviewer's extra suggestion to also count any entry starting with a colon is not added: behind the ./ prefix no test could show it load-bearing. Closed by 184-11 (commit in 184-12).
- **D-38: info/exclude is counted, never trusted; lines read as git reads them (amends D-35 (d)(i) and D-03, review GAP2-CR-02, GAP2-IN-01, GAP2-IN-02, GAP2-IN-03).** (a) Fail-closed choice: a hidden path whose deciding source is .git/info/exclude is no longer trusted; it counts as one modified finding like any other non-committed rule, so a hidden file blocks whatever the line parser concludes. The only trusted source left is a .gitignore that is an exact entry of the fresh HEAD index, and the rev-parse call made only for the old trust is removed. (b) D-03 still requires the excludes count to be the number of active rules, so the line parser is corrected rather than dropped: after removing one trailing CR, a line is inactive only when it is empty, its first byte is #, or it is made only of spaces. Leading spaces, tabs and other whitespace are significant. Checked during planning on git 2.41.0: two spaces then #* hides a file named two spaces then #evil.ex; a tab-only line hides a folder named by a tab; a three-space line hides nothing; a backslash-# line is a rule. A UTF-8 BOM before # on the first line is a comment to git but is counted here, which over-blocks and is accepted (fail-closed). info/attributes keeps its leading-blank trimming because git's attribute reader skips leading blanks. (c) Counting effect, disclosed: a file hidden by an info/exclude rule now gives one modified finding and the rule gives one excludes finding, so the next-action line names both clauses; clauses count findings, not distinct files (D-10). No new cause, clause, receipt field or line-4 wording (D-07, D-14). (d) IN-02: the check-ignore input file is set to mode 0600 right after it is written and before git reads it; a chmod error makes the probe unavailable. It lives only in the 0700 private index directory and is removed with it; if the VM is killed it can be left behind like the temporary index, and it holds path names only, never contents. (e) IN-01: the git_invocation comment names the :pinned, :pinned_stdin and :bare forms, and the dirty_counts doc describes the D-35/D-38 counting. Closed by 184-11 (commit in 184-12).
- **D-39: Git stderr is a failure signal (amends D-07, D-05/D-23; review GAP3-CR-01).** Every git call (pinned, stdin and bare) keeps git's stderr in a shell variable and exits 125 when it is not empty, so the probe is unavailable (`prerequisite_missing`), never clean. Plain script: `exec 2>/dev/null 3>&1; err=$("$@" 2>&1 1>&3 3>&-); rc=$?; [ -z "$err" ] || exit 125; exit $rc`. Stdin script: `in=$1; shift; exec 2>/dev/null 3>&1; err=$("$@" <"$in" 2>&1 1>&3 3>&-); rc=$?; [ -z "$err" ] || exit 125; exit $rc`. The text is only tested for emptiness, never read, returned, logged or written, and the candidate path stays an argv element. Planning-time checks on git 2.41.0 (APFS): folders of mode 0000, 0111, 0222 and 0311 make status and `ls-files --others` print a "could not open directory" warning, omit the contents and exit 0; 0444 and 0555 list normally enough; the real candidate wrote empty stderr with the pins. Rejected: a work-tree pre-walk (duplicates git's traversal and can disagree), and `source_dirty` (git could not look, so the count is unknown). Residual: a git that skips entries without any warning is not covered; none found on 2.41. Fixed in 184-13/184-15 (commit in 184-14).
- **D-40: Git-format text read as git reads it (amends D-04, D-24, D-38 attributes note; review GAP3-CR-02, GAP3-IN-01).** info/attributes: strip only leading ASCII space, tab, CR and LF; a line is inactive only when nothing is left or the first remaining byte is `#` (NBSP, vertical tab and form feed before `#` leave the attribute active, so they are refused). info/exclude and info/attributes are split on LF only and the exclude predicate removes one trailing CR, so a CR CR LF line is one live rule. Git output (rev-parse values) loses one trailing LF instead of being Unicode-trimmed. Config values are compared after ASCII downcasing with no trim and fail closed: core.bare and extensions.worktreeConfig are refused unless a git false spelling (false, no, off, 0, empty); core.symlinks is refused unless a git true spelling (valueless, true, yes, on, 1). Accepted over-refusals: a UTF-8 BOM before `#` on the first attributes line, and unusual safe spellings. Fixed in 184-13/184-15 (commit in 184-14).
- **D-41: Pin core.ignorecase=false (amends D-05; review GAP3-WR-01).** The shared builder adds `-c core.ignorecase=false` to every pinned call, so committed ignore rules match with exact letter case and a case-only rename shows up. It is never refused, because git sets it true on every case-insensitive filesystem, including the real candidate. Pinning false only adds findings (checked on APFS, git 2.41.0). `core.precomposeUnicode` is not pinned: git honours it only on macOS, whose filesystems treat composed and decomposed forms as one name. Real-candidate tripwire: the probe returns only its changed-path count. Fixed in 184-13/184-15 (commit in 184-14).
- **D-42: Guide and docs match the probe (review GAP3-IN-02).** guides/see_it_run.md states the exact-case known limit, the unusual-name sentence and the unreadable-folder block as a missing prerequisite; a guide test pins the sentences. The moduledoc and the clean_tree, dirty_counts and probe_source docs no longer say stderr is discarded and drop the old "whatever the folder or file is called" clause. Fixed in 184-13/184-15 (commit in 184-14).

### Claude's Discretion

These are left to the planner and executor:
- module and function names beyond the ones fixed above;
- the exact Elixir shape of the reason channel;
- how the git-version compare is written;
- test file layout;
- whether `submodule.*.ignore` gets a fixture or only the argv pin.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Scope and requirements
- `.planning/workstreams/quality-ratchet-release/REQUIREMENTS.md`: PROBE-01..04, Acceptance Boundaries, deferred table.
- `.planning/workstreams/quality-ratchet-release/ROADMAP.md`: Phase 184 success criteria.
- `.planning/workstreams/quality-ratchet-release/v26.0-SCOPE.md`: milestone boundaries; candidate-only product work.

### Research
- `.planning/research/v26/SUMMARY.md`: resolved decisions C5, C12, C16, and the probe method.
- `.planning/research/v26/CHALLENGE.md`: the hiding mechanisms beyond WR-01/02.
- `.planning/research/v26/STACK.md` and `.planning/research/v26/PITFALLS.md`: git pins, root burning, probe pitfalls.

### Prior phase
- `.planning/workstreams/quality-ratchet-release/phases/183-close-gap-twin-source-binding-fails-closed-on-uncommitted-co/183-REVIEW-DISPOSITION.md`: WR-01..04, IN-01, IN-03, IN-04, the findings this phase closes.
- `.planning/workstreams/quality-ratchet-release/phases/183-close-gap-twin-source-binding-fails-closed-on-uncommitted-co/183-CONTEXT.md`: the earlier fail-closed decision ("Fail closed (Recommended)").

### Project rules
- `AGENTS.md`: fail-closed rules, privacy, zero-human verification, recovery-checkout prohibitions.
- `prompts/crosswake-elixir-oss-dna.md`: Elixir quality DNA, with no new dependencies.

### Primary sources (git)
- git-config(1), git-status(1), git-ls-files(1) (the `-t`/`-v` tag alphabet), git-read-tree(1), git(1) (`--attr-source`, `--no-optional-locks`, `--no-replace-objects`), gitattributes(5).

</canonical_refs>

<code_context>
## Existing Code Insights

All paths are in `/private/tmp/crosswake-phase180-impl`.

### Reusable Assets
- **`lib/crosswake/proof_lane/twin_producers.ex`:**
  - `@git_scrub_env` (~686) is the base for the D-05 env.
  - `run_git/2` (~716) already discards stderr at the fd level and takes the path as argv only.
  - `git/3` (~725), `clean_tree/2` (~739), `dirty_count/2`, `probe/2` (~759), `count_records/2` (rename counted once) and `exclude_rules/2`.
  - The `:git_cmd` injection option is already used to model git being unavailable.
- **`lib/crosswake/proof_lane/twin_runtime.ex`:**
  - `prepare/1` (~58) and `run_root/1` (~283; the nil branch creates a root).
  - `not_reused/1`, `outside_candidate/2` (dev/inode), `candidate_record/1`, `origin_port/1`, `acquire_origin/1`.
- **`lib/mix/tasks/crosswake.proof_lane.verify_twin.ex`:**
  - the four-line `summarize/4`, `execute/2` seam and exit-status mapping;
  - `blocked_receipt/2` (~145), `source_dirty_action/1` (~291).
- **`lib/crosswake/proof_lane/twin_receipt.ex`:** `@causes`, `safe_cause/1`, `@max_measure 1_000_000`, `@fidelity_limits`.

### Established Patterns
- Exit codes: 0 pass, 1 observed failure, 2 blocked or prerequisite.
- Four-line output.
- Path-free action text.
- `{:blocked, atom}` tuples.
- Tests in `test/crosswake/proof_lane/twin_producers_test.exs` and `test/mix/tasks/crosswake_proof_lane_verify_twin_test.exs`.

### Integration Points
- `freeze/3` (~628), `observe_identities/2` (~934) and `checked_identities/3` (~990) must move onto the shared builder.
- `verify_twin.blocked_receipt` must use `dirty_counts`.
- Phase 188's go/no-go script will call the new preflight task.

</code_context>

<specifics>
## Specific Ideas

What the adversarial pass verified on git 2.41.0, in scratch repos:
- **Hiding mechanisms:**
  - The fresh index with `filemode=true` reports ` M` for every hiding mechanism, where ordinary status was empty.
  - An `info/exclude` rule shows nothing in the fresh-index status, which is why the X count exists.
- **Worktree redirect:** a `core.worktree` redirect to a clean copy made status fully clean. The toplevel realpath check catches it.
- **Filters:**
  - A config filter with `.git/info/attributes` fools both the real and the fresh index.
  - `--attr-source=<empty tree>` defeats tracked `.gitattributes` filters but not `info/attributes`.
  - `--includes` is needed to see filters in include files.
- **Submodules:** `submodule.<n>.ignore=all` hides changes unless `--ignore-submodules=none` is on the argv.
- **`ls-files` tags seen:** `H`, `h`, `S`, `s`, and `M` (one line per stage). `git add -N` shows `H`, and fresh status catches it as `??`.
- **Version and env:**
  - `--attr-source` is accepted on 2.41.0 and on Apple git 2.50.1; 2.40 was not tested.
  - `GIT_CONFIG_COUNT` with KEY/VALUE does inject config if left set.
- **Precedent:** Go's `vcs.modified` and cargo's dirty check both trust the stat cache. The fresh index closes that gap. This comes from researcher memory and was not verified this session.

</specifics>

<deferred>
## Deferred Ideas

- **Ignored untracked files** (through a tracked `.gitignore`) are not detected. This is a disclosed fidelity limit, already listed for TWIN-08 and stated as a non-goal.
- **Edit-and-revert during a run** is not detected (resolved decision C16, fidelity limit 5).
- **LFS and eol-filter repos** fail closed under the attr-source and filter refusals. Reopen if a real candidate needs filters.
- **A git floor below 2.41** is unverified. Reopen if a maintainer's git is older.
- **`lock_digests` accepting one lockfile** is Phase 185 (GUARD-03).
- **A `--format json` output for preflight.** Reopen if a consumer needs more than line 1 and the exit code.

</deferred>

---

*Phase: 184-twin-probe-and-safe-preflight*
*Context gathered: 2026-10-15*
