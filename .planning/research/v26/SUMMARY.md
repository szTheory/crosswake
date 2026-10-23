# Project Research Summary: v26.0 Harden Before Trust

**Project:** Crosswake, workstream `quality-ratchet-release`. Phase numbering continues at 184.
**Researched:** 2026-10-15.

**Inputs:**
- [BRIEF](BRIEF.md), [STACK](STACK.md), [FEATURES](FEATURES.md), [ARCHITECTURE](ARCHITECTURE.md), [PITFALLS](PITFALLS.md) and the adversarial [CHALLENGE](CHALLENGE.md).
- The candidate `/private/tmp/crosswake-phase180-impl` at `50fcd57`. It was only read. The twin, the Simulator and xcodebuild were not run.
- All git experiments were done in scratch repos on git 2.41.0.

> **How this file was written.** The synthesizer subagent was not allowed to write files, so it returned its synthesis as text (the #222 self-heal case). The orchestrator wrote this file from that text. It then settled every conflict the synthesizer listed, using CHALLENGE.md. The final decisions are in "Resolved decisions" below; requirements and the roadmap follow those.

## Executive Summary

v26 removes the places where a v25 check can pass while checking nothing, or where a guarantee can quietly weaken. It then runs the reference twin once more, as twin-05, against the hardened commit.

All research files agree on four points:
- Every change modifies an existing seam. There is no new subsystem and no new dependency.
- All code lands before the single run that consumes a run root.
- The twin run is the last phase, and that phase changes no code.
- The guards are measured and their underlying defects are fixed before any guard is made blocking.

The highest-value fix is the twin's clean-tree probe (`TwinProducers.probe/2`, `twin_producers.ex:759`).

The candidate runs only `git status`, which misses several kinds of edit. Each of these was reproduced in a scratch repo:
- an edit to a file marked assume-unchanged;
- an edit to a file marked skip-worktree;
- an edit made while repo-local `core.ignoreStat` is set;
- a same-size, same-mtime edit while `core.trustctime=false` or `core.checkStat=minimal` is set;
- a mode-only change while `core.filemode=false` is set.

**Other silent paths:**
- `script/check_absence_is_not_success.exs` prints OK and exits 0 when it scans an empty or nonexistent root.
- The legacy host-command grant arm gives any registered `host.*` key and drops other keys without saying so (181 M-02).
- Doctor's `host_commands_stale` returns nothing in three cases: the fixture is unreadable, the fixture is malformed (181 M-03), or a router route is missing from the manifest (CHALLENGE).
- Doctor's phase-4 posture filter skips the very misconfiguration it is meant to catch (SEED-014 F).
- The loopback Simulator harness can report a pass after a cleanup failure, and its hash assertion cannot fail (182 WR-03, WR-04, WR-05).
- `TwinRuntime.stop_children/1` returns `:ok` when the registry is already dead.
- `lock_digests/1` silently narrows if one of its two lockfiles is missing.

**The main risks are procedural:**
- A guard made blocking before it is measured turns into a waiver list.
- Running the twin to debug it burns the run root. `verify_twin` has no mode that leaves the root untouched: even a preflight block writes `receipt.json`.
- A contract change can break producers outside this repo, or tests pinned to a SHA.
- New diagnostics can leak local paths.

## Key Findings

### Stack
- **No new dependencies.** Fixes use git argv and environment settings, the Elixir standard library and ExUnit, with copy-paste where code is shared.
- **Probe.** Compare the worktree against a fresh index built from HEAD. Build it with `GIT_INDEX_FILE=<temp file outside the repo> git read-tree HEAD`, then run `git status --porcelain -z --untracked-files=all` against that index.
  - In every hiding case CHALLENGE tried (assume-unchanged, skip-worktree, ignoreStat, checkStat, trustctime), this revealed the edit. It also reveals filemode-only changes once the filemode pin below is added.
  - As a second signal, a `git ls-files -v -z` pass counts every tag other than `H` as dirty. An unknown tag fails closed.
  - Zero tracked entries means `:prerequisite_missing`, never clean.
- **Pins.**
  - Add `-c core.filemode=true` and `GIT_CONFIG_GLOBAL=/dev/null` (verified on git 2.41.0).
  - Keep `GIT_CONFIG_NOSYSTEM=1`, the existing `-c core.excludesFile=/dev/null` (which already closes the global-excludes hole), the fsmonitor disable and the scrubbing of `GIT_*` repo variables.
  - Add other pins (`autocrlf`, `untrackedCache`) only when a test shows they are needed.
- **Do not use:**
  - `update-index --refresh`, which writes the index;
  - `--ignored`, because the example host's `_build` would make every run dirty;
  - a libgit NIF or a hand-written `.gitconfig` parser.
- **Idioms:**
  - `assert [_ | _] = list`, or `assert length(list) == n` where the count is stable;
  - mutation controls must assert `before_digest != after_digest`;
  - test citations go by name, and a citation that runs 0 tests fails.

### Features (scope)

**Table stakes: fails open or degrades silently.**
- 183 WR-01 and WR-02, plus the further probe holes CHALLENGE found.
- 183 WR-04: weak probe tests.
- 183 IN-01: a second probe path with different config.
- 183 IN-04: an exception message can carry a path.
- 181 M-02, M-03 and the missing-route case, and M-04 (privacy).
- The absence checker passing on an empty scope (SEED-023's real caller).
- `stop_children/1` and `lock_digests/1`.
- 182 WR-03, WR-04 and WR-05.
- A preflight mode that cannot consume a run root.
- SEED-014 C, E and F.

**Worth it, small:**
- 183 WR-03: the misleading dirty-count wording.
- 183 IN-03: a refused root must leave nothing behind.
- 181 M-01: the guide says "floor" where the code means something else.
- A regression test for the physical preflight origin mode.

**Deferred, each with a reopen trigger:**

| Item | Why deferred |
|---|---|
| CW-REQ-A haptics assertion | Breaking change to a closed vocabulary; the adopter is not blocked; on the stop list |
| CW-REQ-D denial view | Reopens on the next change to the Swift templates |
| Compile-time `Policy.Route` rule for F | Breaks pinned fixtures |
| Repo-wide VACG-01 non-empty rule | No measurement yet |
| Ledger lift and deletion | Not needed for this milestone |
| Phase 179 identity join (bundle id) | The user deferred it; it would bump the schema and adds no fail-closed value |
| 181 L-01, L-04, L-05, L-06; GEN-W06; route-id mismatch | Fail closed or are cosmetic (CHALLENGE) |
| 181 L-02; 182 WR-01 | Not silent |
| Snapshot-clone refactor | Not needed for this milestone |
| MIX_ENV drift; `local_ios_package` cwd | Documented friction |
| `WKAppBoundDomains` placeholder | Pinned placeholder |
| Nyquist validation | Becomes a closeout task |

**Dropped:**
- The twin-02 case-3 stall: its cause was never retained, so do not infer one.
- 181 IN-02.

**Already done, stale in the seed:** SEED-018's audit. The ledger check exits 0 with 243 sites and none marked `needs-fix`, and v25's 19 rows are all safe. The one gap left is the loop at `twin_receipt_test.exs:289`, which runs with no non-empty floor.

### Architecture
- **Probe.** `freeze/3` (`:636`), `checked_identities/3` (`:990`) and `observe_identities/2` (`:934`) all go through one probe configuration.
  - The receipt keeps `@schema_version 1`.
  - Any commit after `50fcd57` invalidates the prepared record. That forces a new prepared record and run root, twin-05 (D-16).
- **Run root.**
  - The go/no-go check is that the root exists as a 0700 directory with no `receipt.json`. "Root absent" is the wrong check.
  - An ordinary `source_dirty` block at run time also burns the root. So the clean tree must be confirmed by the new read-only preflight immediately before the run.
- **Host seam.** M-02 lives in the legacy arm of `ActivationCoordinator.swift:274-281`. Fix: deny with the existing `not_registered` and `version_unsupported` reasons. Manifest schema 1.2.0 and the public API stay unchanged.
- **Doctor.** E: add a `details` map at `doctor.ex:379-390`; `Policy.Warning` already carries the paths. F: a doctor-time check scoped to `runtime == :offline_island` (`doctor.ex:469-472`).
- **Proof provenance (C).** `verify_navigation_shell.ex:101-115` hardcodes `commit_ref`, version, template and device class. Replace them with real values or explicit "unknown" sentinels; the all-zero hash must be rejected.
- **Handoffs.** Refresh `180-SEAM-HANDOFF.json` and `182-FINAL-HEAD.json` once, by script, at the freeze.

### Pitfalls
1. **Guards before measurement turn into waivers.** Run in report mode first; counts may only go down.
2. **"Fixes" that weaken tests.** Each fix needs a negative control that reverts the fix and fails.
3. **Vacuous mutation controls and 0-test citations.**
4. **A git probe that fails open.** Prevent it with real temp-repo tests, one per tamper class.
5. **Burning the run root.** Freeze first, use a read-only preflight, then a scripted go/no-go. The run happens once; if it fails, there is no retry to green.
6. **Breaking contract changes.** Need a legacy-shaped fixture and a specific diagnostic.
7. **Privacy leaks.** Use one redaction helper (copied, not a dependency) and a sentinel-directory leak test that also covers exception text.

Planning-tool hazards and their mitigations:
- The gap-analysis gate is workstream-unaware: verify coverage by grep instead.
- The decision-coverage parser gives false negatives.
- A blocked plan must be named `NN-BLOCKED.md`.
- Re-arm the dispatch-isolation sentinel immediately before each dispatch.

## Resolved decisions (auto-followed, per the user's instruction)

| # | Conflict | Decision |
|---|---|---|
| C1 | Is CW-REQ-A's reopen trigger met? | Defer either way. Record both readings with evidence so this is not argued again. |
| C2 | Loopback harness: wire into CI or remove? | Fix WR-03, WR-04 and WR-05. Keep the harness as documented, manually run phase evidence. Do not add it to the required CI leaf, because AGENTS.md keeps one-time checks in phase evidence. |
| C3 | Git environment | Pin `GIT_CONFIG_GLOBAL=/dev/null` and `core.filemode=true`. Keep the existing excludesFile and NOSYSTEM pins. Leave HOME alone unless a test shows it is needed. |
| C4 | Do ignored files count as dirty? | No; `--ignored` is not used. Record this as a fidelity limit. |
| C5 | Primary probe | A fresh-index comparison (CHALLENGE's largest finding) plus the `ls-files -v` tag count as a second signal. Report separate counts; the dirty-count bound applies to their sum. |
| C7 | M-02: warn first, or deny now? | Deny now, with the specific existing reasons, plus a doctor finding, a guide update and a legacy-shaped fixture. This follows the AGENTS.md rule to keep explicit denials fail-closed. |
| C8 | Where to fix SEED-014 F | At doctor time, scoped to `:offline_island`. The compile-time rule is deferred. |
| C9 | Add a standing non-empty rule? | Not in v26. Add only the absence checker's own floor, an Elixir copy of `assertFullScope`, and the `twin_receipt_test` floor. |
| C12 | Preflight origin: test or code? | Write a test first. Add code only if the test shows the preflight can reach a local-mode host. |
| C14 | CW-REQ-D | Deferred, with the reopen trigger recorded. |
| C16 | A post-run re-probe to catch edit-and-revert | Not added. Keep disclosed fidelity limit 5. |
| C17 | Which v25 diff base to use | `d0dbdf7`. |
| Phases | How many | Five. The twin run is alone and last. |

**Authority for twin-05:** twin-01 through twin-04 ran inside execute-phase as local Simulator work in `/private/tmp`. twin-05 follows the same pattern. It is local and needs no new external authority. If it fails, the next run, twin-06, is a new decision rather than an automatic retry.

## Implications for Roadmap

| Phase | Name | Owns |
|---|---|---|
| 184 | Twin probe and safe preflight | Fresh-index probe, `ls-files` signal, pins, one probe config (IN-01), IN-04, WR-03 wording, IN-03, a read-only preflight that cannot consume a root, real temp-repo tests |
| 185 | Checks that cannot pass empty | The absence checker's empty-root floor and Elixir full-scope copy; the `twin_receipt_test` floor; `stop_children`; the `lock_digests` exact count; a report-mode measurement table |
| 186 | Host seam and harness honesty | M-02 denial; M-03 plus missing routes; M-04 redaction; M-01 guide; loopback harness WR-03, WR-04, WR-05 kept as manual evidence; the preflight origin regression test |
| 187 | Doctor and proof fidelity | SEED-014 E, F and C; deferral records for A and D |
| 188 | Freeze and twin-05 | Freeze commit; scripted handoff refresh; read-only preflight; go/no-go; one twin-05 run; byte-copy of the result |

**Order:** 184 comes first, because it defines the gate. Phases 185–187 are independent of one another apart from the order of edits to `doctor.ex` (186 before 187). Phase 188 is last.

## Confidence Assessment

| Area | Confidence | Notes |
|---|---|---|
| Probe semantics | HIGH | Reproduced in scratch repos. The `ls-files` tag letters were confirmed by CHALLENGE. |
| Absence checker and SEED-018 status | HIGH | Confirmed by running the commands. |
| Seam (Swift) | MEDIUM | The Swift package was not built. |
| Harness | MEDIUM | Not run; it will be proved with broken-state shims. |
| Doctor churn | MEDIUM | How many fixtures change has to be counted before coding. |

## Gaps

- Whether any manifest outside the repo uses the legacy path cannot be known from the repo.
- Which doctor status atoms are allowed has to be confirmed before writing the "no offline routes" result.
- The macOS case-only-rename behaviour, CRLF and submodules are untested. Record them as residuals unless a scratch test settles them.
- The exact twin-05 prepared-record procedure needs reading from the 183 plan artifacts in 188 planning.
- The v25 product code lives only under `/private/tmp`. If it is lost, all v25 code is lost; moving it needs separate authorization.

## Sources

- **Primary:** git-scm.com pages for git-ls-files, git-update-index, git-status, git-config and git (environment variables).
- **Other ecosystems (per PITFALLS):** Go 1.18 release notes on build info, Bazel hermeticity, Nix flakes, reproducible-builds.org.
- **Repo files:** cited inline in the source research files at candidate `50fcd57`.
