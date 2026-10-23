---
phase: 183-close-gap-twin-source-binding-fails-closed-on-uncommitted-co
review: 183-REVIEW.md
critical: 0
warning: 4
info: 4
recorded: 2026-10-15
---

# Phase 183 review disposition

The review found no critical issues. All eight findings stay open, because fixing any of them would add a commit after `fix(183-03)`. Under D-16 that would also mean a new prepared record and a new run root (twin-05), since twin-04 is consumed. The review is advisory, so the phase verdict (183-VERIFICATION.md, passed) stands.

**Two findings can let a future run degrade silently (WR-01, WR-02).** A candidate where git index flags (`assume-unchanged` / `skip-worktree`) or `core.filemode=false` hide a change would pass the clean-tree gate. These findings did not affect twin-04. On 2026-10-15, after the run, the candidate had:
- all 3257 index entries flagged `H` (no assume-unchanged or skip-worktree entries);
- repo `core.filemode=true` and no global value set;
- zero `.git/info/exclude` rules;
- an empty porcelain with `-c core.filemode=true`.

So the twin-04 source join still attests the code that ran. The fix belongs in the next twin-touching change:
- count `git ls-files -v` entries whose tag is not `H` as dirty;
- pin `-c core.filemode=true` in the probe;
- add tests for both.

| Finding | Severity | Disposition | Note |
|---------|----------|-------------|------|
| WR-01 | warning | open | Index flags (`assume-unchanged`, `skip-worktree`) hide modified files from the clean-tree probe. This is a fail-open path for future runs. It was not present at twin-04 (0 non-`H` entries). |
| WR-02 | warning | open | Only system git config is disabled, so a global or repo `core.filemode=false` hides mode-only changes, and the code comment overstates the isolation. It was not present at twin-04 (filemode true, no global value). |
| WR-03 | warning | open | The message counts `.git/info/exclude` rules as "files" and suggests `git status`, which shows nothing when only an exclude rule triggered the block. A race can also print "0 files". The run still fails closed, but the wording misleads. |
| WR-04 | warning | open | Some tests are weak: the journey test greps the source, the CLI leak test injects a producer that already blocks, and there is no index-flag test. The eight mutation controls (mutation-183.log) still show that each guard is load-bearing. |
| IN-01 | info | open | `checked_identities` takes `git_cmd`, but `observe_identities` probes git a second time. |
| IN-02 | info | open | Duplicated dead `{:ok, ...}` return in the `repo_fixture` setup. |
| IN-03 | info | open | A refused run root created by `run_root(nil)` is left behind. |
| IN-04 | info | open | `run_git` rescues only `ErlangError`; an argv with a NUL byte would raise an `ArgumentError` whose message could contain a path. |
