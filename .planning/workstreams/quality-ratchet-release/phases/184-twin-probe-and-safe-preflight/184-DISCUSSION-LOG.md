# Phase 184: Twin probe and safe preflight - Discussion Log

> **Audit trail only.** Do not use this as input to planning, research or execution agents. The decisions are captured in CONTEXT.md; this log keeps the alternatives that were considered.

**Date:** 2026-10-15
**Phase:** 184-twin-probe-and-safe-preflight
**Areas discussed:** Preflight entry point, Preflight check depth, Dirty message and counts, Hostile repo config

**Selection.** The user selected all four areas and pasted their fan-out prompts. Those asked for:
- research per area, through every relevant lens;
- an adversarial pass;
- one coherent set of recommendations, auto-followed;
- copy-paste rather than a new dependency;
- primary sources.

**Method.** Four Sonnet advisor researchers worked in parallel, one per area. A Sonnet adversarial reviewer then ran experiments in scratch git repos (git 2.41.0 and Apple git 2.50.1). The orchestrator synthesized the results.

---

## Preflight entry point

| Option | Description | Selected |
|--------|-------------|----------|
| `--preflight` flag on verify_twin | One command; a guard bug could spend a root | |
| Separate task + `TwinPreflight.check/1` | Read-only by construction; shares the checks | ✓ |
| Function only | Poor ergonomics; the script hand-rolls exit codes | |

**Choice:** a separate task. `--run-root` is required; the researchers disagreed and the adversarial pass settled it. Exit 0 means allowed and exit 2 means blocked. Exit 1 is never used.

## Preflight check depth

| Option | Description | Selected |
|--------|-------------|----------|
| Every check except writes and the backend compile, shared with the run | `check/1` + `source_gate/3` split; port bind-and-release | ✓ |
| Source probe only | Would miss the root and port checks the go/no-go depends on | |
| Include the backend compile | Writes `_build`; not read-only | |

**Choice:** shared checks. Added by the adversarial pass:
- a run-root owner check;
- a same-cause table test;
- an identity-to-record comparison, or an explicit "not checked";
- "allowed" wording that names what was not checked.

## Dirty message and counts

| Option | Description | Selected |
|--------|-------------|----------|
| Separate M/F/X clauses on line 4, token on line 2, measure = sum | Fixes WR-03; schema unchanged | ✓ |
| One combined count | Repeats WR-03 | |

**Choice:** separate clauses. The adversarial pass changed three things:
- The F wording became "tracked files marked unchanged in git's index".
- Flagged paths are counted uniquely.
- The docs note that the counts can overlap.

## Hostile repo config

| Option | Description | Selected |
|--------|-------------|----------|
| A. Pin keys only | Leaves flags, worktree redirect and filters hidden | |
| B. Refuse only | False refusals; misses filemode | |
| C. Fresh index + minimal pins + narrow refusals | Covers every mechanism tested | ✓ |

**Choice:** C.
- **Cut** after the adversarial pass: the hooksPath, splitIndex, sparseCheckout, untrackedCache, checkStat and trustctime pins, plus the HOME, XDG_CONFIG_HOME and GIT_CONFIG_SYSTEM env settings.
- **Added:** `--ignore-submodules=none`, `GIT_ATTR_SOURCE` scrubbed, refusal of `filter.*` by prefix, and refusal of `core.bare` and `core.symlinks=false`.
- **Version floor:** 2.41.
- **Flag conflict:** counting only S and lowercase tags lost to PROBE-01's rule that every tag other than H is flagged.

## Claude's Discretion

These were left to the planner:
- names beyond the fixed ones;
- the shape of the reason channel;
- how the version compare is written;
- test layout;
- whether `submodule.*.ignore` gets a fixture.

## Deferred Ideas

- ignored untracked files;
- edit-and-revert during a run;
- LFS and eol-filter repos;
- a git floor below 2.41;
- `lock_digests` (Phase 185);
- preflight JSON output.
