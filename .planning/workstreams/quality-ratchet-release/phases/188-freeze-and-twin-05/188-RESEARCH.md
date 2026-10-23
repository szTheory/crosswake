# Phase 188: Freeze and twin-05 - Research

**Researched:** 2026-10-16
**Domain:** one-shot evidence tooling (POSIX shell + jq + shasum + git) around an already-built Elixir/Simulator proof task. No product code changes.
**Confidence:** HIGH for interfaces, shapes and exit codes (all read from source or run records this session); MEDIUM for the MIX_BUILD_PATH finding (mechanism proven in scratch, effect on the real run not run because running the twin is forbidden here).

Read-only research. Nothing was written in the candidate, the run directory, or the recovery checkout. Scratch experiments lived under the session scratchpad only. `verify_twin`, `twin_preflight` and the Simulator were not run.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Freeze (TWIN-07, criterion 1)**
- **D-01:** The frozen candidate commit is the current HEAD `a53fbef70d20e6ee49f1ebd2ee783c991f95a7b4` (`fix(187)`). "One frozen candidate commit" means the cumulative tree at a single final HEAD. The twin binds `expected_head` and `expected_tree` and attests the whole tree, not a file list.
  - Do not squash. A squash would rewrite the SHAs named in the 184–187 verification records and the history manifests, and twin-05 attests a tree anyway.
  - Do not add a `fix(188)` commit (D-04).
  - The plan records the reading of criterion 1 in one plain sentence so verification does not read it as "one commit since `50fcd57`".
  - **Reversibility:** one-way. Once twin-05 starts, the run root is consumed against this head. Any later commit that changes twin-attested source needs twin-06, which is a new decision.
- **D-02:** The first freeze step asserts all of the following and records the result:
  - candidate `git rev-parse HEAD` equals `a53fbef…`;
  - the porcelain status is empty;
  - the Phase 184 probe reports all zeros;
  - the push URL is still `no-push-phase180`.
  If HEAD differs, stop and report it. Never re-point the freeze at a different head without a new decision.
- **D-03:** Twin-attested source means the entire candidate tree, plus the freeze inputs:
  - the prepared record (`expected_head`, `expected_tree`, `origin`, `resource_digests`, `fixture_digests`);
  - the identity file;
  - the `verify_twin` and `twin_preflight` task sources, which are inside the tree.
  Nothing after D-02 may write into the candidate. All new scripts live outside it.

**Pre-freeze fix scope**
- **D-04:** No open review warning is fixed before the freeze. Research traced every open item against the twin-05 path:
  - 186 WR-01 and WR-02 are only on the physical-iPhone preflight path. `IOSHostOriginMode.observe`, called via `origin_refusal_for` in `physical_iphone_preflight.ex`, is reached only from `crosswake.proof_lane.physical_iphone`. A Simulator twin never calls it.
  - 187 WR-02 and WR-04: `Provenance` is reached only from `verify_navigation_shell`. Nothing in the twin producers or runtime uses it.
  - 187 IN-03: doctor JSON. No twin artifact retains it, and D-07 check (c) confirms that before the run.
  - The twin-path items either fail closed (184 GAP4-WR-01 hangs, it does not pass) or are closed by script checks in D-12:
    - 184 WR-05 (digest comparison gating the real run);
    - 184 D-36 (submodules);
    - 185 WR-02 and WR-04 (cleanup edge cases).
  Fixing the off-path items would buy twin-05 no honesty. It would cost a new HEAD and a rebuilt record, and twin-05 would leave the new code untested. Each item keeps its existing trigger. 186 WR-01/WR-02 are fixed together at the first physical-iPhone run or the next preflight change. 187 WR-02 is fixed at the first use of provenance from a nested host directory.
- **D-05:** The owner's open question from STATE.md ("decide whether 186 WR-01/WR-02 and 187 WR-02 must be fixed before the freeze") is answered no, by D-04. Remove that question from STATE.md and ROADMAP.md once this context is accepted.
- **D-06:** 186 WR-03 (empty or bare `--evidence`) was already fixed in 187-05. Nothing further.
- **D-07:** These preconditions replace code fixes. Each is a check in the go/no-go script (D-12). If any one fails, do not edit the frozen candidate. Stop before the run root is touched and record a new-candidate decision.
  - (a) Digests from a fresh `git show HEAD:<path>` recompute equal the prepared record and the identity file (184 WR-05).
  - (b) Zero mode-160000 entries in `HEAD^{tree}`, and no `.gitmodules` (184 D-36).
  - (c) The run directory inputs contain no doctor JSON (187 IN-03). After the run, `twin-05/` and the result contain no router module name.

**Scripted refresh and run-directory records (TWIN-07, criteria 1–2)**
- **D-08:** All refresh and run tooling lives in `/private/tmp/crosswake-phase180-run/`, next to the precedents `prepare-record.sh`, `preflight-04.sh`, `run-once-04.sh` and the twin-01..04 roots. Each script is copied byte for byte into the phase directory as evidence, with its sha256 recorded.
  - Do not create a candidate `script/` file or a mix task. That would change the frozen tree.
  - Shell only: `zsh`/`sh` plus `jq`, `shasum` and `git`, which are already in use. No new dependencies.
  - Every git call uses the scrubbed `g()` wrapper pattern from `prepare-record.sh`.
- **D-09:** `refresh-handoffs-188.sh <freeze_sha>` takes the freeze SHA as a required argument with no default. It:
  1. refuses unless the candidate is clean and HEAD equals the argument;
  2. checks `git merge-base --is-ancestor` of each record's old head against the freeze head;
  3. copies each old record to `*.pre-188.json`;
  4. writes values from `git rev-parse` only:
     - `180-SEAM-HANDOFF.json`: `repaired_head`, `repaired_tree`;
     - `182-FINAL-HEAD.json`: `head`, `tree`, `core_diff_paths`;
  5. adds a `supersedes` object holding the previous values;
  6. writes temp then `mv`;
  7. verifies with `jq -e` that each record's head equals HEAD and its tree equals `HEAD^{tree}`.

  The 182 record's Simulator and check fields describe 182-era evidence. The script marks them `not_rerun_at_freeze_head` rather than leaving them looking current. twin-05 is the run that proves the freeze head; the old harness gates are not rerun.
- **D-10:** A new `188-IDENTITY.json` (schema `crosswake.phase180.identity/1`, `183-IDENTITY.json` as the template) is computed from `git show HEAD:<path>` outputs only, as in 183-04 Task 1. A new prepared record `twin-05-candidate.json` (mode 0600, written with `mv -n`) comes from `prepare-record.sh <candidate> <out> twin-04-candidate.json`. Both are written after D-02 and before D-11.
- **D-11:** twin-01..04 are proven byte-unchanged with the existing manifest. Run `shasum -a 256 -c history-184.before.sha256` (87 entries, including `183-TWIN-RESULT.json`) at three points: before the refresh, after the refresh, and inside the go/no-go. Also run `cmp twin-04/twin-result.json` against `183-TWIN-RESULT.json`. The refresh never touches a `twin-0[1-4]*` path, and the `*.pre-188.json` copies are new files.

**Go/no-go and the single run (TWIN-07 criterion 2, TWIN-08 criterion 3)**
- **D-12:** One script, `run-once-05.sh` in the run directory (modelled on `run-once-04.sh`), owns both the gate and the run. Separate scripts would open a time-of-check/time-of-use gap. In order:
  1. **Environment.** Set `MIX_ENV=test` and a fresh, dedicated `MIX_BUILD_PATH=/private/tmp/crosswake-phase180-run/_build_188_twin05`, outside the candidate. Run `mix compile` there, then run the probe again (a compile can dirty the tree). STATE.md records two 187 hazards this avoids: a stale build, and `mix` subprocesses corrupting a shared build.
  2. **Go/no-go checks.** Each check is a fixed label with a pass/fail status:
     - HEAD equals the record's `expected_head`, and `HEAD^{tree}` equals `expected_tree`;
     - the probe reports all zeros;
     - D-07 checks (a), (b) and (c) pass;
     - the handoff records match a fresh `git rev-parse`;
     - the history manifest passes;
     - the root `twin-05` exists, has mode 0700, is owned by the user, lies outside the candidate, and contains no `receipt.json` or `twin-result.json`;
     - no `twin-05.started` or `twin-05.exit` sibling exists;
     - there are exactly four `twin-NN` root directories;
     - port 4790 is not listening (`lsof`);
     - no stale `crosswake-phase180-*` Simulator device exists and a Simulator runtime is available;
     - the prepared record has mode 0600.
  3. **Read-only preflight.** Run `mix crosswake.proof_lane.twin_preflight ios --candidate … --run-root … --identity …` in the same environment. It must exit 0. It writes nothing.
  4. **Gate output.** Write `go-no-go-05.json` with one `{label, status}` per check, plus one plain-language line first. Any failure exits non-zero before anything is created.
  5. **Sentinel.** Create `twin-05.started` with noclobber (`set -C`), UTC time and mode 0600. This is the exactly-once lock: a second invocation fails at this line.
  6. **The run.** Exactly one `mix crosswake.proof_lane.verify_twin ios --candidate … --run-root … --identity 188-IDENTITY.json`, with stdout and stderr sent to sibling files. Write `rc` to `twin-05.exit`. There is no loop, no retry and no external `timeout` wrapper; the task's own run deadline governs.
- **D-13:** The script never creates the root. A separate step immediately before the script runs `mkdir -m 0700 /private/tmp/crosswake-phase180-run/twin-05`.
  - The code requires a pre-existing root (`run_root_check` has `create?: false`), so a pre-created root is never removed on refusal. This avoids the 183 IN-03 leftover.
  - "Root absent" is the wrong check (CHALLENGE R2).
  - **Reversibility:** one-way. Once `twin-05.started` exists the root is consumed.
- **D-14:** "The run happened" means `twin-05.started` exists. If `.started` exists without `.exit`, the result is recorded as "ran once, outcome unknown" with a privacy-safe cause. Never guess why; twin-02's stall is the precedent. The sentinel stays forever, so `run-once-05.sh` refuses permanently afterwards.
- **D-15:** The executor runs the script as local Simulator work inside execute-phase, the same pattern as twin-01..04. It needs no new external authority (v26 SUMMARY "Authority for twin-05").
  - The run can exceed a foreground shell timeout. Run it in the background and watch for `twin-05.exit` with an until-loop or monitor. Do not poll by restarting the script.
  - The orchestrator independently re-reads `twin-05.exit` and the result afterwards.
  - No `checkpoint:human-verify`. Every assertion is scripted.
- **D-16:** No rehearsal and no dry twin run. The read-only preflight is the rehearsal (CHALLENGE K6). Any dry check of the scripts points at a throwaway directory, never at `twin-05`, and never invokes `verify_twin`.

**Result capture, limits and failure (TWIN-08)**
- **D-17:** Byte-copy only `twin-05/twin-result.json` to `188-TWIN-RESULT.json`, following the 183-05 pattern.
  - It is already a closed projection (ids, closed enums, closed cause atoms, limits, `receipt_sha256`), so byte-copy and privacy do not conflict.
  - Run `cmp`, and record the full sha256 of source and copy.
  - Assert that `receipt_sha256` equals the sha256 of `twin-05/receipt.json`.
  - Do not copy raw `receipt.json`, stdout, stderr or the xcresult into planning. Quote only the printed `result:`, `first cause:` and `next action:` lines, and the report path with the home prefix stripped.
  - Run a privacy scan over every file written to planning: home paths, `/private/var`, `/var/folders`, UUID or UDID patterns, `token`, `secret`, `@` and the username. The scan must report zero hits, and the command and its result are recorded, as in 187-07.
- **D-18:** A mechanical result assertion, `assert-twin-05.sh` in the run directory, decides TWIN-08. Exit 0 and `overall_status == "passed"` are necessary but not sufficient. The script checks:
  - exactly 10 groups, with ids T01..T10;
  - every group passed, with at least one sub-observation, and every observation passed with a null cause;
  - exactly 7 identity joins, with ids equal to the `@identity_joins` set (source, dependency_lock, generated_resources, served_static, installed_media, installed_build, backend_build), all passed with null causes;
  - `fidelity_limits` deep-equal to the five receipt strings;
  - the `receipt_sha256` match from D-17.
  Expected counts and ids are constants in the script, never read from the file under test. A negative self-test feeds it an empty-groups file and a 9-group file and requires a non-zero exit from both; this guards against an empty check passing.
- **D-19:** The fidelity limits are listed in a plain-language sidecar, `188-TWIN-RECORD.md`. The receipt's `@fidelity_limits` literal is not changed; that would change the receipt and break the freeze. The record opens with "A pass means the Simulator twin saw X; it does not mean Y." It lists:
  - **The receipt's five limits, verbatim** (`twin_receipt.ex` ~58-64): Simulator, not a physical speaker; Simulator, not a signed device; synthetic test authority, not a real adopter; trusted local runner, not cryptographic certification; edit-and-revert during a run not detected. The last is DEF-SNAP, so it covers TWIN-08 limit 1.
  - **Planning-record limits the receipt cannot vouch for,** under that heading:
    - ignored files are not counted (TWIN-08);
    - the Phase 179 identity join is deferred (TWIN-08);
    - DEBT-IDENT: the twin attests the hardcoded bundle id `org.crosswake.twin` (`twin_journey.ex:20`), not the generated identity (CHALLENGE S3).
  - **Open warnings not exercised by twin-05,** listed separately so they do not dilute the twin limits:
    - 186 WR-01 and WR-02 (physical-iPhone preflight);
    - 187 WR-02 and WR-04 (nested-host provenance);
    - 184 GAP4-WR-01 (a FIFO hang, fails closed);
    - 185 WR-02, WR-03, WR-04 and WR-05;
    - the five carried `routing.unclassified_path` adoption-scan findings.
  - The receipt's `residual_external_gates`: a physical iPhone signed-device run, and the first adopter's sanitized route handoff.
- **D-20:** If twin-05 fails, is blocked, or ends without `.exit`:
  - Still byte-copy the result JSON, when one exists.
  - Record the stage, the closed cause atom from `first_cause` and the exit status (1 failed, 2 blocked). An unknown cause stays `cause_not_retained`. Say "raw output not retained" where that is true.
  - The plan leaves `188-NN-BLOCKED.md`, not a SUMMARY.
  - TWIN-08 stays unticked and is marked failed with a recorded cause. The phase goes to gaps status, with no verification pass.
  - STATE.md and ROADMAP.md carry exactly one handoff: "no command is eligible until an explicit twin-06 decision".
  - No retry to green and no reuse of the root. twin-06 needs all of the following:
    - a new explicit owner decision citing a materially different cause or fix;
    - a new root and prepared record;
    - a re-freeze.
  - The superseded result is annotated by sha256, never edited.
  - The v26 milestone may close only through an explicit override that names the failed proof in plain language.

**Phase mechanics**
- **D-21:** On success, verification re-runs D-11, D-17's `cmp` and sha256 checks, and D-18 in its success and negative self-test modes. It confirms the candidate HEAD is still `a53fbef`, its status is empty, and the push URL is unchanged. STATE.md and ROADMAP.md then record v26 Phase 188 complete. The handoff is "v26.0 ready for milestone audit/close", and the candidate delivery gate stays open.

### Claude's Discretion
- Exact script names and JSON label strings, as long as each check has a fixed label and the output carries no paths.
- Plan split: for example, freeze and refresh records; then go/no-go and the run; then capture, assertion and record. The run plan must depend on every record being written.
- The exact `jq` expressions and privacy-scan regex, provided they meet D-17 and D-18.

### Deferred Ideas (OUT OF SCOPE)
- Fix 186 WR-01 and WR-02 (physical-iPhone preflight). Trigger: the first physical-iPhone run or the next preflight change.
- Fix 187 WR-02 and WR-04 (nested-host provenance and the public predicate). Trigger: provenance used from a nested host directory, or the next `Evidence` change.
- 184 GAP4-WR-01 (bounded read of git local files). Trigger: the next twin-touching change.
- 185 WR-02..05. Trigger: their recorded triggers; a leftover twin process after twin-05 reopens WR-02.
- DEF-SNAP snapshot-clone run source; DEBT-IDENT generated-identity attestation. Disclosed as limits.
- Promote the go/no-go into a reusable candidate mix task. Only in a future change that is not frozen, and only if twin runs recur.
- Deliver candidate commits into the authoritative tree. This needs separate authorization.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| TWIN-07 | After all code changes are frozen in one candidate commit: a scripted refresh updates the seam and loopback handoff records; the read-only preflight (PROBE-04) and a scripted go/no-go both pass (frozen HEAD, clean probe, matching digests, a 0700 `twin-05` root with no receipt); then run root `twin-05` is run exactly once. | Script interfaces (section "Precedent script interfaces"), preflight CLI (section "CLI surface"), handoff record shapes and the `core_diff_paths` rule, manifest command, noclobber sentinel (tested), env hazards (MIX_BUILD_PATH, DATABASE_PATH). |
| TWIN-08 | twin-05 exits 0 with ten groups and seven identity joins passing; result byte-copied; disclosed fidelity limits; on failure a privacy-safe cause and no retry. | Exact `twin-result.json` shape, a tested `assert-twin-05.sh` (positive plus seven negative controls), privacy-scan regex validated against the twin-04 precedent, failure-record fields (`run-stages.json`, `first cause:` line), limits that the result does NOT carry (sidecar needed). |
</phase_requirements>

## Summary

Phase 188 is evidence tooling, not product work. Everything needed already exists: the candidate is clean at `a53fbef…` with tree `f7c4d7dc1a86f251c3ba845d3cde8d4c770ae729`, push URL `no-push-phase180`, zero gitlinks, no `.gitmodules`, the history manifest verifies (87 OK, exit 0, run during this research), `twin-05` and its siblings do not exist, four `twin-NN` roots exist, nothing listens on 4790, no `crosswake-phase180-*` Simulator device exists, and one available iOS runtime (26.5) and iPhone device types are present. The twin task sources (`twin_receipt.ex`, `twin_journey.ex`) are byte-unchanged since `50fcd57`, so the roster (10 groups, 49 sub-observations), the 7 join ids and the 5 limit strings are identical to what twin-04 produced. The four fixture digests at the freeze HEAD equal the twin-04 record's digests, so the new prepared record will differ from the old only in `expected_head` and `expected_tree`.

Six findings change or sharpen the plan beyond what CONTEXT states (details in the sections named):

1. **MIX_BUILD_PATH must not reach the real run.** `verify_twin` spawns `mix compile`, `mix ecto.migrate` and `mix phx.server` children with an `env:` list that EXTENDS the inherited environment (proven in scratch). The freeze digest is read from the fixed path `examples/phoenix_host/_build/test/lib/crosswake_example/ebin`, while the running backend reports the digest of whatever build it loaded. An exported dedicated `MIX_BUILD_PATH` splits those two, so the `backend_build` join can fail (or silently compare a stale directory). Use the dedicated path for the outer compile, probe and preflight only, and run `verify_twin` under `env -u MIX_BUILD_PATH -u DATABASE_PATH` like twin-04 did. This is consistent with D-12 (which does not say the run inherits it) and with how 187 ran its full suite.
2. **`core_diff_paths` has a precise rule.** In `182-FINAL-HEAD.json` it equals `git diff --name-only <base_head> <head>` exactly (verified: 33 paths for `12f84cd..da53c54`). At the freeze head the same rule yields 129 paths, mostly twin and proof-lane code from 180 and 183-187, not "core" in the 182 sense. The refresh must state that meaning change inside the record.
3. **Planning-bound script copies must be home-path free.** D-08 copies scripts byte for byte into planning, and D-17's scan forbids the home path and username in every planning file. The precedent scripts hard-code `/Users/<name>/…`. The new scripts must build planning paths from `$HOME` so the copies scan clean.
4. **The result JSON carries only the five receipt limits.** "Ignored files are not counted" and "Phase 179 identity join deferred" cannot be found in `twin-result.json`. They exist only in the sidecar (D-19). Verification must check the sidecar for them, not the JSON.
5. **A usage error looks like a test failure.** `verify_twin` raises `Mix.raise` for bad options or a missing `--identity`, which exits 1 (the same number as "observed failure") with no receipt, after the sentinel was written. Build the argument vector once and use the identical vector for preflight and run (the preflight maps bad options to exit 2, so a vector that passes preflight cannot be a usage error).
6. **The canary `xcodebuild: failed` in `run-stages.json` is normal in a passing run** (twin-04 shows it). Do not assert "no failed stage" from that file.

**Primary recommendation:** Build four small POSIX-sh scripts in the run directory (`refresh-handoffs-188.sh`, `make-identity-188.sh`, `run-once-05.sh`, `assert-twin-05.sh`) plus a privacy scan and a self-test script, each derived by minimal diff from `prepare-record.sh`, `preflight-04.sh` and `run-once-04.sh`; reuse `prepare-record.sh` unchanged; give every script a negative control; run the single twin in the background with `env -u MIX_BUILD_PATH -u DATABASE_PATH`.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Freeze assertion (HEAD/tree/clean/push URL) | Run-dir scripts (git read-only) | Candidate (read-only) | Candidate must not be written after D-02 (D-03). |
| Handoff record refresh | Planning files (phase 180/182 dirs) | Run-dir script | Records are planning-only; no product code reads them [VERIFIED: grep of recovery checkout and candidate for both file names found no .ex/.exs/.sh/.mjs reader]. |
| Prepared record + identity file | Run dir (record, 0600) and planning (identity) | `prepare-record.sh` | Digests must come from `git show HEAD:<path>` only. |
| Go/no-go gate | `run-once-05.sh` | `twin_preflight` mix task | Preflight is read-only and does record-vs-identity digest comparison; the script adds the fresh-recompute, gitlink, root, sibling and environment checks. |
| Exactly-once lock | Filesystem (`twin-05.started`, noclobber) | — | Atomic create-if-absent; tested. |
| The run | `mix crosswake.proof_lane.verify_twin` | Simulator, Phoenix child, example host | Writes `receipt.json`, `twin-result.json`, `run-stages.json`, `expectations.json`, `obs/` into the root. |
| Result assertion + capture | `assert-twin-05.sh`, `cp`/`cmp`/`shasum` | Planning phase dir | Closed projection only. |
| Fidelity-limit disclosure | `188-TWIN-RECORD.md` sidecar | — | Receipt literal cannot change without breaking the freeze. |

## Standard Stack

No packages are installed in this phase. Everything is already present and in use by the precedent scripts.

### Core
| Tool | Version (observed) | Purpose | Why standard |
|------|---------|---------|--------------|
| `/bin/sh` (bash 3.2 posix on macOS) or `zsh` | system | scripts | Precedents: `prepare-record.sh` and `preflight-04.sh` are `#!/bin/sh`; `run-once-04.sh` is `#!/bin/zsh`. Recommend `#!/bin/sh` for all new scripts (see Pitfalls on zsh). |
| `jq` | jq-1.7.1-apple | JSON build/assert | Already used by `prepare-record.sh`. |
| `shasum -a 256` | system | digests and manifest check | Already used. |
| `git` (scrubbed `g()` wrapper) | system | read-only candidate state | Wrapper copied from `prepare-record.sh`. |
| `lsof`, `xcrun simctl`, `stat -f` (BSD) | system | environment checks | Used by `preflight-04.sh`. |
| `mix` (Elixir 1.19.5 / OTP 27.3 via asdf) | per candidate `.tool-versions` | preflight, probe, run | Needs a cwd containing `.tool-versions` (see Pitfalls). |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| zsh `run-once` | POSIX sh | sh avoids zsh-only traps (`status`, `path`, non-matching globs, `>>` under noclobber); noclobber sentinel verified to work in both. |
| `set -C` sentinel | `mkdir` lock directory | `set -C` is what D-12 locked; both are atomic enough. Keep `set -C`. |

**Installation:** none. **Package Legitimacy Audit:** not applicable. No external package is installed or recommended; no `package-legitimacy` run is needed.

**Version verification:** `jq --version` printed `jq-1.7.1-apple`; `elixir --version` printed `Elixir 1.19.5 (compiled with Erlang/OTP 27)`; `xcodebuild -version` printed `Xcode 26.6`. [VERIFIED: local command output this session]

## Precedent script interfaces

All in `/private/tmp/crosswake-phase180-run/` (the "RUNS" directory). Contents read this session.

### `prepare-record.sh` (`#!/bin/sh`, mode 0700, `set -eu`, `umask 077`)
- **Args:** `$1` candidate dir (required), `$2` output record path (required), `$3` previous record (optional, printed alongside). `$3` is tested with `-f` relative to the cwd, so pass an absolute path.
- **Writes:** one JSON file, mode 0600, via `mktemp "$OUTDIR/.prep-record.XXXXXX"` then `mv -n`. Never overwrites.
- **Record shape (verbatim from the script's `jq -n`):** `{candidate_path,expected_head,expected_tree,origin:"http://127.0.0.1:4790",resource_digests:[manifest,activation,study_js],fixture_digests:[media]}`. `candidate_path` is `pwd -P` of the candidate.
- **Exit codes and fixed stdout:** 0 ok; 3 `refused: source_dirty`; 4 `refused: probe_unavailable`; 5 `refused: record_exists`; 6 `refused: write_failed`. On success prints `new head …`, `new tree …`, `new manifest …`, `new activation …`, `new study_js …`, `new media …`, then the same six `old …` lines when `$3` exists.
- **Probe it runs:** `status --porcelain=v1 -z --untracked-files=all --ignore-submodules=none` must be 0 bytes, and `info/exclude` must have no non-comment line.
- **Caveat:** `P=$(g status … | wc -c)` is a pipeline, so a failing git status is masked by `wc`. The earlier `rev-parse --git-dir` guard covers a missing repo only. Fine for reuse; do not copy this idiom into new scripts.
- **Reuse unchanged** for D-10: `prepare-record.sh /private/tmp/crosswake-phase180-impl /private/tmp/crosswake-phase180-run/twin-05-candidate.json /private/tmp/crosswake-phase180-run/twin-04-candidate.json`.
- **Expected old/new table at the freeze head** (computed read-only with `git show HEAD:<path> | shasum -a 256`): all four digests equal the old record's (manifest `917ef9d0…9493`, activation `085eb4b2…48e6`, study_js `d9d3ac41…f307`, media `5d8b3f72…abf5b`); only head and tree change (old head `50fcd57…8687`, tree `d71bc587…1e17`; new head `a53fbef70d20e6ee49f1ebd2ee783c991f95a7b4`, tree `f7c4d7dc1a86f251c3ba845d3cde8d4c770ae729`). A digest difference would be a surprise worth stopping on. [VERIFIED: local git show and shasum this session]

### `preflight-04.sh` (`#!/bin/sh`, mode 0700, `set -eu`) — the WR-05 digest-recompute precedent
- **Env overrides:** `CANDIDATE` (default candidate), `RECORD` (default `twin-04-candidate.json`).
- **Failure mode:** prints `preflight: <label> failed` to stderr and exits 1 on the first failing check. Labels, in order: `clean probe`, `record present`, `head equals record`, `tree equals record`, `fix ancestry`, `manifest digest`, `activation digest`, `study_js digest`, `media digest`, `record mode`, `identity present`, `identity head`, `identity tree`, `identity media`, `identity manifest`, `identity activation`, `port 4790 free`, `no leftover simulator`, `twin-04 absent`, `twin-04.started absent`, `twin-04.exit absent`, `run count stable`, `run count three`, `gen.shell check`, `clean probe after gen.shell`. On success prints `preflight: ok`.
- **Mechanics worth copying:** `probe()` function (0-byte porcelain plus `info/exclude` has zero non-comment lines); `dig() { g show "HEAD:$1" | shasum -a 256 | cut -d' ' -f1; }`; `[ "$(stat -f %Lp "$REC")" = 600 ]`; `[ -z "$(lsof -nP -iTCP:4790 -sTCP:LISTEN 2>/dev/null)" ]`; `xcrun simctl list devices | grep -q 'crosswake-phase180-'`; run count via `ls -d twin-[0-9][0-9] | wc -l` recorded once in `twin-run-count.before-04` (value 3).
- **Check not in D-12's list:** `(cd "$CAND/examples/phoenix_host" && MIX_ENV=test mix crosswake.gen.shell ios --check >/dev/null 2>&1)` followed by a second probe. Recommend keeping it (cheap, precedent), run with `env -u MIX_BUILD_PATH` so the subprocess does not touch the dedicated build (the 187 corruption hazard).
- **Minimal diff for twin-05:** rename `04`→`05`, `RECORD` to `twin-05-candidate.json`, identity to `188-IDENTITY.json`, replace the `fix-183.commit` ancestry check with an ancestry check against the freeze SHA, expected run count 4, add the gitlink/`.gitmodules` check, the doctor-JSON/router scan, handoff-record match, manifest check, and the root checks. Use `$HOME`-derived planning paths.

### `run-once-04.sh` (`#!/bin/zsh`, mode 0700, `set -eu`) — verbatim flow
1. `$RUNS/preflight-04.sh`
2. `mkdir -m 0700 "$R"` (R = `$RUNS/twin-04`) — **D-13 moves this out of the script**
3. `date -u +%Y-%m-%dT%H:%M:%SZ > "$R.started"` (no noclobber in the precedent; D-12 adds `set -C`)
4. `printf '%s\n' "$R" > $RUNS/twin-run-path-04`
5. `cd $C`; `set +e`; `MIX_ENV=test mix crosswake.proof_lane.verify_twin ios --candidate $RUNS/twin-04-candidate.json --run-root "$R" --identity $PD/183-IDENTITY.json > "$R.stdout" 2> "$R.stderr"`; `rc=$?`; `set -e`; `echo $rc > "$R.exit"`.

Sibling artefacts the precedent leaves (twin-04): `twin-04.started` (`2026-10-15T13:43:32Z`, 21 bytes), `twin-04.exit` (`0`), `twin-04.stdout` (4 lines), `twin-04.stderr` (0 bytes), `twin-run-path-04`, `twin-run-count.before-04`. twin-04 took about 6 minutes (started 09:43, exit 09:49 local). [VERIFIED: ls and cat this session]

### The scrubbed `g()` wrapper (identical in `prepare-record.sh` and `preflight-04.sh`)
```sh
g() {
  env -u GIT_DIR -u GIT_WORK_TREE -u GIT_INDEX_FILE -u GIT_OBJECT_DIRECTORY -u GIT_ALTERNATE_OBJECT_DIRECTORIES -u GIT_COMMON_DIR -u GIT_NAMESPACE -u GIT_CEILING_DIRECTORIES -u GIT_CONFIG -u GIT_CONFIG_COUNT -u GIT_CONFIG_PARAMETERS -u GIT_PREFIX GIT_OPTIONAL_LOCKS=0 GIT_CONFIG_NOSYSTEM=1 GIT_TERMINAL_PROMPT=0 LC_ALL=C git --no-optional-locks -c core.excludesFile=/dev/null -c core.quotePath=false -c core.fsmonitor=false -C "$CAND" "$@"
}
```
`$CAND` must be set before any call.

### Other run-dir precedents
- No separate "refresh" script exists. A search of the run directory and planning for `refresh`, `handoff` or `final` found none used before twin-04; `refresh-handoffs-188.sh` is new.
- `history-184.before.sha256` — see next section.
- `twin-run-count.before-04` (content `3`), `twin-run-path-04` (content the twin-04 root path). Create `twin-run-count.before-05` (content `4`) and `twin-run-path-05` analogously; both are new files, not in the manifest.

## History manifest (D-11)

- **Location:** `/private/tmp/crosswake-phase180-run/history-184.before.sha256`, mode `-r--------`, 87 lines, format `<sha256>␠␠<absolute path>`. [VERIFIED: wc -l and head this session]
- **cwd does not matter:** every path is absolute (planning files under `/Users/<name>/projects/crosswake/.planning/...`, run files under `/private/tmp/crosswake-phase180-run/...`). Command: `shasum -a 256 -c /private/tmp/crosswake-phase180-run/history-184.before.sha256`. Run this session: exit 0, 0 non-OK lines.
- **Coverage (verified by grep):** 68 entries under `twin-0[1-4]`, including `twin-04/twin-result.json`, `twin-04/receipt.json`, `twin-04/run-stages.json`, `twin-04/expectations.json`, the `obs/c1..c5` JSONL files, `twin-0[1-4].exit/.started`, `twin-04.stdout/.stderr`, `twin-02-candidate.json`, `twin-04-candidate.json`, `180-IDENTITY.json`, `180-TWIN-RESULT.json`, `180-TWIN-RESULT.twin-02.json`, `183-IDENTITY.json`, `183-TWIN-RESULT.json`, `fidelity-limits*.txt`, `fix-183.commit`, `history-183.before.sha256`, `twin-run-count.before(-04)`, `twin-run-path(-04)`.
- **Not covered, so the refresh may touch them:** `180-SEAM-HANDOFF.json` and `182-FINAL-HEAD.json` do not appear (grep returned nothing).
- **Prior pass-reporting idiom (from `history-187.after.out`):** each line printed with `<home>` substituted, ending `: OK`. A robust gate must capture `rc` and the OK count separately (tested snippet below), because piping `shasum -c` into a counter masks its exit status.
- `cmp /private/tmp/crosswake-phase180-run/twin-04/twin-result.json <phase183>/183-TWIN-RESULT.json` — verified identical this session.

## Candidate CLI surface

### `mix crosswake.proof_lane.twin_preflight ios --candidate <record> --run-root <dir> --identity <file>`
Source read: `lib/mix/tasks/crosswake.proof_lane.twin_preflight.ex` and `lib/crosswake/proof_lane/twin_preflight.ex` in the candidate. [VERIFIED: full-file Read this session]
- **Switches (strict):** `candidate`, `run_root`, `identity`, all strings. Positional must be exactly `["ios"]`. Anything else is a **blocked** result, not a raise.
- **Exit codes:** 0 allowed; 2 blocked, for every cause, including bad options and an unreadable identity file. Never 1 from the task's own logic. Exits other than 0/2 can only come from Mix itself (compile error), so the gate must treat any non-zero as no-go and require exactly four output lines.
- **Output, exactly four lines:** `result: allowed` or `result: blocked`; `first cause: none` or the atom; `report: none written; no run root was created or consumed`; `next action: …`.
- **Order of checks:** `:run_root_given`, `:run_checks`, `:source_gate`, `:identity_digests`.
  - `run_checks` = `TwinRuntime.check/1`: run root must `lstat` as a real directory (not a symlink), `(mode &&& 0o077) == 0`, owned by the current uid (`id -u`); then `not_reused` (blocks only if `<root>/receipt.json` exists, `lstat`); then the candidate record (regular file, `(mode &&& 0o077) == 0`, JSON with `candidate_path`, 40-hex `expected_head`/`expected_tree`, `origin`, `resource_digests`, `fixture_digests`, and `candidate_path` must be a directory); then the root must be outside the candidate (device/inode walk over ancestors); then database path (default `<root>/twin.sqlite3`, must not exist; a `DATABASE_PATH` env var, if set, must be inside the root and not exist); then origin must parse as `http://127.0.0.1:<port>`; then the port is bound and released at once.
  - `source_gate`: reads identity (`media.sha256`, `media.size` integer, `generated.manifest_sha256`, `generated.activation_sha256`, each a digest), checks `rev-parse HEAD` and `HEAD^{tree}` against the record, clean tree (probe creates and removes a private temp index outside candidate and root), both lockfiles (`mix.lock`, `examples/phoenix_host/mix.lock`), and the study script digest.
  - `identity_digests`: `[identity.manifest, identity.activation, study_js] == record.resource_digests` and `[identity.media] == record.fixture_digests`. This is the WR-05 comparison the real run does not repeat. [CITED: the moduledoc in `twin_preflight.ex`, "Phase 188's scripted pre-run check … is where that comparison gates the real run"]
- **Writes nothing** in the candidate or the run root. It reads no `candidate_head`/`candidate_tree` from the identity file; the shell gate must (as `preflight-04.sh` checks 11-16 do).
- **Honours `DATABASE_PATH`** from the environment. Unset it.

### `mix crosswake.proof_lane.verify_twin ios --candidate <record> --run-root <dir> --identity <file>`
Source read: `lib/mix/tasks/crosswake.proof_lane.verify_twin.ex`, `twin_runtime.ex` (lines 55-135, 340-643). [VERIFIED: Read this session]
- **Switches (strict):** `candidate`, `run_root`, `identity`. Bad positional/unknown switch raises `Mix.raise("verify_twin.invalid_options")`; a missing `--identity` raises `verify_twin.identity_required`. A Mix raise exits **1** with no receipt (the same number the task uses for "observed failure").
- **Exit codes (task moduledoc):** 0 complete pass, 1 observed failure, 2 missing prerequisite or missing observation (unknown rule id also 2). Exits via `System.halt(status)` for non-zero.
- **stdout, exactly four lines:** `result: <passed|failed|blocked> (exit N)`; `first cause: <none | "<id> <cause>" | atom>`; `report: <receipt path | none written>`; `next action: …`. On pass line 4 is `Copy twin-result.json byte for byte into the planning artifact` (twin-04: `result: passed (exit 0)`, `first cause: none`, `report: /private/tmp/crosswake-phase180-run/twin-04/receipt.json`, `next action: Copy twin-result.json byte for byte into the planning artifact`).
- **What it refuses:**
  - run root missing, not a directory, a symlink, group/other-accessible (`mode &&& 0o077 != 0`), or not owned by the current user: `prerequisite_missing` with action "Create a private run root directory (mode 0700) and run again with it". A pre-created root is never deleted on refusal (`create?: false`).
  - `<root>/receipt.json` already present: `run_root_reused`.
  - port 4790 in use: `origin_port_occupied`.
  - record not mode 0600-style (any group/other bit), malformed, or the root inside the candidate: `prerequisite_missing`.
  - `DATABASE_PATH` set and not inside the root / already existing: `database_path_rejected`.
  After a refused `prepare`, no `receipt.json` or `twin-result.json` is written (`{:error, …}` → `summarize(:blocked, …, nil, action)`, report `none written`). Once the root is accepted, even an early block writes an all-blocked receipt plus `twin-result.json` (`blocked_receipt/2`), so "each accepted run root ends with receipt.json and twin-result.json" (source comment).
- **Where it writes:** `<run-root>/receipt.json` and `<run-root>/twin-result.json` via `write_private` (exclusive create, then `chmod 0600`), `<run-root>/expectations.json` (freeze; twin-04 shows mode 0644), `<run-root>/run-stages.json`, `<run-root>/obs/c1..c5/*.jsonl`. `twin-result.json` is verified to carry `receipt_sha256` equal to the sha256 of the written `receipt.json` bytes before the task prints its lines.
- **Deadline:** `@default_run_deadline_ms 3_600_000` (one hour) for the whole run; the backend `mix compile` child has its own `deadline_ms: 900_000`. No external timeout is needed or wanted (D-12).
- **Children and environment:** children are started with `Port.open({:spawn_executable, …}, [… env: env …])`. Erlang's `env` option extends the inherited environment [CITED: erlang.org open_port docs, and VERIFIED by a scratch Elixir run in which a parent `MIX_BUILD_PATH` appeared in a child launched with only `MIX_ENV` in `env:`]. So `MIX_BUILD_PATH`, `DATABASE_PATH`, `HEX_*`, `PATH` and `ASDF_*` all reach `mix compile`, `mix ecto.migrate`, `mix phx.server`, `xcrun`, `xcodebuild`.

### The Phase 184 probe command (D-02, D-12 re-probe)
Precedent (184-10 plan, 186-05 plan, 187-07 plan, output file `real-probe-187.out` last line):
```sh
cd /private/tmp/crosswake-phase180-impl && MIX_ENV=test MIX_BUILD_PATH=$B mix run --no-start -e 'IO.inspect(Crosswake.ProofLane.TwinProducers.probe_source(File.cwd!()))'
```
Observed expected term, verbatim: `{:ok, %{modified: 0, excludes: 0, flagged: 0}}`. The key order printed differs between runs (187 deviation 3), so do not string-compare. Use a pattern match that exits non-zero otherwise:
```sh
mix run --no-start -e '{:ok, %{modified: 0, flagged: 0, excludes: 0}} = Crosswake.ProofLane.TwinProducers.probe_source(File.cwd!()); IO.puts("probe: all zero")'
```
(Not executed here; the pattern is the read-only form of the recorded call. [ASSUMED: runs as written; confirm in the plan's self-test against the scratch clone, not the real candidate.]) Running it compiles the project into whichever `MIX_BUILD_PATH` is set, so for D-02 use the dedicated build path and not the candidate's default `_build`.

## JSON shapes

All verified by reading the named files this session.

### `twin-result.json` (closed projection, schema `crosswake.twin_result/1`), twin-04 (byte-identical to `183-TWIN-RESULT.json`)
Top-level keys, in file order: `exit_status` (0), `fidelity_limits`, `groups`, `identity_joins`, `overall_status` ("passed"), `receipt_sha256`, `residual_external_gates`, `run_id`, `schema`. Single line, no trailing newline.
- `groups[]`: `{"id":"T01","status":"passed","sub_observations":[{"cause":null,"id":"TW-T01-01","outcome":"passed","owner":"host_adapter"}, …]}`. Ids `T01`…`T10`, in order. Sub-observation counts T01..T10: `4,5,3,7,4,5,5,3,5,8` = **49**. Owners seen: `host_adapter`, `webview`, `phoenix_ecto`, `fault_boundary`, `app_process`, `runner`.
- `identity_joins[]`: `{"cause":null,"id":"source","outcome":"passed"}`, in this order: `source`, `dependency_lock`, `generated_resources`, `served_static`, `installed_media`, `installed_build`, `backend_build` (7). These match the receipt literal `@identity_joins [:source, :dependency_lock, :generated_resources, :served_static, :installed_media, :installed_build, :backend_build]`.
- `fidelity_limits` (verbatim, five, in receipt order):
  1. `simulator not physical speaker`
  2. `simulator not signed device`
  3. `synthetic_test_authority not real adopter`
  4. `trusted local runner not cryptographic certification`
  5. `source edit made and reverted during a run not detected`
- `residual_external_gates` (verbatim): `physical iPhone signed-device run`, `first adopter sanitized route handoff`.
- `receipt_sha256`: 64-hex sha256 of `receipt.json` bytes (twin-04: `c726b584f0f3d97733ebabbff9c6f9e086cb67796103bced9e0d8f53c752da00`). `run_id` form `twin-` + 16 hex.
- Non-pass shape (twin-02, blocked): `exit_status: 2`, `overall_status: "blocked"`, the first non-passed sub-observation has `outcome: "blocked"` and a closed `cause` (twin-02: `attachment_check_unavailable` on `TW-T01-01`).
- **Closed cause atoms** (`twin_receipt.ex` `@causes`, verbatim): `observation_missing`, `contradiction_observed`, `identity_mismatch`, `identity_unknown`, `prerequisite_missing`, `origin_port_occupied`, `run_root_reused`, `run_root_rejected`, `database_path_rejected`, `child_timeout`, `host_denied`, `backend_denied`, `unavailable_observation`, `backend_listener_not_owned`, `capture_not_prevented`, `attachment_check_unavailable`, `session_control_unavailable`, `source_dirty`, `cause_not_retained`. Outcomes: `passed`, `failed`, `blocked`. Unknown causes are rewritten to `cause_not_retained` by `safe_cause/1`.
- `first_cause/1` ordering: failures sort before blocked; the first non-passed observation `{id, cause, outcome}`; printed as `"<id> <cause>"` on line 2.
- **Receipt file** (`receipt.json`) is mode 0600 and is not copied to planning.

### `run-stages.json` (schema `crosswake.twin_run_stages/1`, twin-04)
`{"not_reached":[],"run_id":"…","schema":"crosswake.twin_run_stages/1","stages":[{"attachments":"counted_zero","stage":"canary","xcodebuild":"failed"},{… "stage":"c1","xcodebuild":"succeeded"}, … c5]}`. The canary stage reports `xcodebuild: "failed"` in a passing run; that is by design. For D-20 stage recording, use `not_reached` and the last stage entry (closed values only). It lives in the run root, is not copied, and is in the history manifest only for twin-04.

### `expectations.json` (twin-04)
Keys: `tree`, `head`, `lock_digests` (2), `activation_sha256`, `backend_build_sha256`, `manifest_sha256`, `media_sha256`, `served_static_sha256`. Useful as a post-run cross-check that the run froze the expected head/tree and fixture digests; it is not planning-bound.

### Twin-04 run root contents (what a clean pass leaves)
`expectations.json` (0644), `obs/c1..c5/{twin-app-process,twin-host-adapter,twin-webview}.jsonl`, `receipt.json` (0600), `run-stages.json` (0600), `twin-result.json` (0600). Leftover-file assertion precedent (183-05): no `*.xcresult`, `*.sqlite3*`, `*.db`, `*.aiff` under the root after a completed run.

### `twin-04-candidate.json` (prepared record, mode 0600) — verbatim
```json
{
  "candidate_path": "/private/tmp/crosswake-phase180-impl",
  "expected_head": "50fcd5743243c0b20275a7e2bd9338bf25468687",
  "expected_tree": "d71bc587ce73d8a253465ea8c31f9eed5e286e17",
  "origin": "http://127.0.0.1:4790",
  "resource_digests": ["917ef9d0…9493", "085eb4b2…48e6", "d9d3ac41…f307"],
  "fixture_digests": ["5d8b3f72…abf5b"]
}
```
(full digests are in the file; they equal the freeze-head recompute.)

### Identity record (schema `crosswake.phase180.identity/1`), `183-IDENTITY.json` — template for `188-IDENTITY.json`
Keys: `schema`, `supersedes` ("180-IDENTITY.json"), `candidate_head`, `candidate_tree`, `media` `{path, size (33706), sha256}`, `generated` `{manifest_sha256, activation_sha256}`, `note`. Lives in `.planning/workstreams/quality-ratchet-release/phases/183-close-gap-twin-source-binding-fails-closed-on-uncommitted-co/183-IDENTITY.json`. The twin reads only `media.sha256`, `media.size` (must be an integer), `generated.manifest_sha256`, `generated.activation_sha256`; head/tree in the identity file are for the shell gate only. For 188: `supersedes` "183-IDENTITY.json", `media.size` from `git show HEAD:<media> | wc -c` (33706 expected), `media.path` is the `@media_rel` string `examples/phoenix_host/native/ios/CrosswakeProofLane/Resources/ReferenceLearningBundle/pronunciation.aiff` (twin_producers.ex:615).

### `180-SEAM-HANDOFF.json` (schema `crosswake.phase180.seam_handoff/1`)
Keys: `schema`, `decision_candidate_head` and `base_head` (both `96e5a63e…`), `source_repo` (`/private/tmp/crosswake-phase181-impl`), `source_branch`, `repaired_head` (`12f84cd950d4574921767df823faed6797c17c26`), `repaired_tree` (`e51f069d52b1c1303d8d606d6000ff146654948e`), `authorized_paths[]` (52), `probe_route_id`, `probe_command`, `preflight`, `expected_verdict`, `declaration_driven_evidence[]`, `deviations[]`, `remote_writes_authorized` (false), `created_at`. Lives in `…/phases/180-bounded-digital-twin-demonstration/`. D-09 rewrites only `repaired_head` and `repaired_tree` (plus a `supersedes` object and, recommended, a `refreshed_at`/`refreshed_by` marker); `12f84cd` is an ancestor of the freeze HEAD, so the ancestry check passes.

### `182-FINAL-HEAD.json` (schema `crosswake.phase182.final_head/1`)
Keys: `schema`, `candidate` (`/private/tmp/crosswake-phase182-impl`), `branch`, `base_head` (`12f84cd…`), `head` (`da53c54db06e54be5a80fb4be144a70d3fed36a5`), `tree` (`d1cbbe30ffca9da79c5506004ad2bf8c8da38665`), `core_diff_paths[]` (33), `checks[]` (10 objects with `name`, `command`, `exit`, `tests`/`failures`), `simulator_evidence`, `simulator_candidate_head`, `simulator_candidate_tree`, `recorded_at`. Lives in `…/phases/182-loopback-origin-for-local-ios-host/`.
- **Verified rule for `core_diff_paths`:** `git diff --name-only 12f84cd da53c54` equals the recorded list exactly (33 lines, `diff` empty). At the freeze head `git diff --name-only 12f84cd a53fbef…` gives 129 paths. The refresh should compute `git diff --name-only "$base_head" "$freeze"` and state in the record's `supersedes`/note field that the list now covers every change since the 181 head, not only Phase 182 core files.
- **Not-rerun marking:** leave `checks[]`, `simulator_evidence`, `simulator_candidate_head/tree` untouched under `supersedes` (they are true statements about `da53c54`) and add a top-level `checks_status: "not_rerun_at_freeze_head"` and `simulator_status: "not_rerun_at_freeze_head"` rather than editing each check's `exit`. [ASSUMED: this satisfies D-09's "marks them not_rerun_at_freeze_head"; the exact field layout is Claude's discretion.]

## Existing precedents for D-07

- **(a) WR-05 digest recompute:** `preflight-04.sh` checks 7-10 (record vs `git show HEAD:<path> | shasum -a 256`) and 11-16 (identity vs record). The mix preflight itself compares record vs identity but trusts the identity file's digests; only the shell recompute proves identity vs committed bytes. Both are needed.
- **(b) mode-160000 check:** 184-10/12/14 plans: `git -C C ls-tree -r HEAD` to a file, count lines starting `160000 ` (written to `gitlinks-184-13.count`, value `0`), and require `C/.gitmodules` absent. Verified now: `git ls-tree -r HEAD | awk '$1=="160000"' | wc -l` prints 0 and `.gitmodules` is absent. Use `git ls-tree -r "$HEAD" | awk '$1=="160000"{n++} END{exit n>0}'`-style (no pipe into the status decision; capture the count into a variable).
- **(c) doctor/router-name privacy scan:** no script exists. IN-03 text (187-REVIEW) names the router module as the identifier. The only router module in the example host is `CrosswakeExample.Router` (`examples/phoenix_host/lib/crosswake_example/router.ex:70`), the synthetic one. Doctor JSON keys are `unmanaged_routes` (check name) and `unmanaged_paths`/`router` (details; `doctor.ex:385-392`). A scan regex that covers both the module name pattern and the doctor keys: `CrosswakeExample\.Router|unmanaged_(routes|paths)|[A-Za-z0-9]\.Router\b`. **Validated read-only:** run over `twin-04/`, `twin-04.stdout`, `twin-04.stderr` it reports zero hits (grep exit 1).
- **Home-path/username scan precedent:** 186-05 and 187-07 (`home-scan-18N.files`, `.log`): list files first, require each to be a readable regular file, then `grep -lF "$HOME"` and `grep -lw "$(id -un)"` over the list; empty output required. Record the file list so "none found" names what was scanned. **Validated read-only:** the D-17 pattern set plus username gives zero hits over the twin-04 root, its stdout/stderr, `183-TWIN-RESULT.json` and `183-IDENTITY.json`, and a planted `/Users/…` file is detected (negative control).

## Architecture Patterns

### System Architecture Diagram
```
 [candidate a53fbef, clean, read-only]         [recovery checkout planning dirs]
        |  git show HEAD:<path>                      ^  plain uncommitted files
        v                                            |
  D-02 freeze assert ──> prepare-record.sh ──> twin-05-candidate.json (0600, RUNS)
        |                    make-identity-188.sh ──> 188-IDENTITY.json (phase dir)
        |                    refresh-handoffs-188.sh <sha> ──> 180-SEAM-HANDOFF.json, 182-FINAL-HEAD.json (+ *.pre-188.json)
        v
  manifest check #1 ... #2 (after refresh)
        |
  [separate step]  mkdir -m 0700 RUNS/twin-05
        |
  run-once-05.sh ──────────────────────────────────────────────────────────────┐
   env: MIX_ENV=test, dedicated MIX_BUILD_PATH (compile/probe/preflight only)  │
   1 compile  2 re-probe  3 checks (labels) 4 manifest #3                       │
   5 twin_preflight (exit 0, 4 lines)  6 go-no-go-05.json  ── any fail: exit, nothing created
   7 ( set -C; > twin-05.started )   ← exactly-once lock                         │
   8 env -u MIX_BUILD_PATH -u DATABASE_PATH mix …verify_twin ios … > .stdout 2> .stderr
   9 echo rc > twin-05.exit                                                      │
        v                                                                        │
  twin-05/{receipt.json,twin-result.json,run-stages.json,expectations.json,obs/} ◄┘
        |
  assert-twin-05.sh twin-result.json receipt.json  (constants in script)
        |  pass                                   |  fail / blocked / no .exit
        v                                         v
  cp -> 188-TWIN-RESULT.json; cmp; sha256     cp result if present; 188-NN-BLOCKED.md; no retry
  scan planning files (D-17); 188-TWIN-RECORD.md; STATE/ROADMAP/REQUIREMENTS
```

### Recommended file layout
- `RUNS/` (new): `refresh-handoffs-188.sh`, `make-identity-188.sh`, `run-once-05.sh`, `assert-twin-05.sh`, `scan-privacy-188.sh`, `selftest-188.sh`, `twin-05-candidate.json`, `go-no-go-05.json`, `twin-run-count.before-05`, `twin-run-path-05`, then (created by the run) `twin-05.started/.stdout/.stderr/.exit`, `twin-05/`. Build dir `_build_188_twin05`.
- `PD` = this phase dir (new, plain files): `188-IDENTITY.json`, `188-TWIN-RESULT.json`, `188-TWIN-RECORD.md`, script copies (e.g. `scripts/*.sh` with a `188-SCRIPTS.sha256`), `188-NN-SUMMARY.md` or `188-NN-BLOCKED.md`, `188-VALIDATION.md`.
- `phases/180-…/` and `phases/182-…/`: refreshed records plus `*.pre-188.json` copies.

### Suggested plan split (waves)
1. **188-01 freeze + records:** D-02 assertions; `prepare-record.sh` (reuse); `make-identity-188.sh`; `refresh-handoffs-188.sh` + self-tests; manifest checks #1/#2; the one-sentence reading of criterion 1.
2. **188-02 gate + run script:** `run-once-05.sh`, `assert-twin-05.sh`, `scan-privacy-188.sh`, `selftest-188.sh` (all self-tests against throwaway dirs only); script copies + sha256 into the phase dir. Depends on 01.
3. **188-03 the run:** `mkdir -m 0700`, background `run-once-05.sh`, monitor for `.exit`, orchestrator re-read. Depends on 01 and 02 (every record written). One task only; no loop.
4. **188-04 capture + record:** assert, `cp`, `cmp`, sha256, privacy scan, `188-TWIN-RECORD.md`, STATE/ROADMAP/REQUIREMENTS edits, or the BLOCKED branch.

### Anti-Patterns to Avoid
- **Exporting `MIX_BUILD_PATH` into the `verify_twin` process** (Finding 1).
- **Different argument vectors for preflight and run.** Build one array once.
- **Piping a check into `tail`/`wc`/`grep -c` and trusting the `&&`.** Capture the command's rc first (project rule from MEMORY: pipe masks exit codes).
- **Variables named `status`, `path`, `pipestatus` in zsh** (read-only or tied to `PATH`).
- **Asserting `canary xcodebuild == succeeded`.** It is `failed` in a pass.
- **A loop, `|| retry`, `until`-restart or `timeout` around `verify_twin`** (D-12).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Prepared record | A new generator | `prepare-record.sh` unchanged | Already refuses dirty probes and existing outputs, atomic `mv -n`. |
| Candidate-state gate | New git logic | Precedent `probe()` and `g()` from `preflight-04.sh` | Same scrub env as the Elixir probe; fewer divergences. |
| Read-only twin verdict | Re-implementing source/identity checks | `mix …twin_preflight` | It is the PROBE-04 deliverable and the TWIN-07 gate names it. |
| Result shape check | Ad-hoc `grep` | One `jq -e` with constants in the filter | Tested below; guards against empty/partial pass. |
| History proof | Custom hashing | `shasum -a 256 -c history-184.before.sha256` | Existing 87-entry manifest. |

## Common Pitfalls

### Pitfall 1: Inherited `MIX_BUILD_PATH` splits the freeze digest from the running backend
**What goes wrong:** the `backend_build` join fails (or compares stale beams).
**Why:** `compile_and_hash` runs `mix compile` in `examples/phoenix_host` and then reads beams from the fixed path `examples/phoenix_host/_build/test/lib/crosswake_example/ebin` (twin_producers.ex ~1531-1541). The backend child (`mix ecto.migrate`, `mix phx.server`) reports `build_sha256` from the modules loaded by the running VM (`twin_fault_controller.ex:278-287`, md5 of `Application.spec(:crosswake_example, :modules)`). With a dedicated `MIX_BUILD_PATH` inherited by those children, they build and load from the dedicated directory while the freeze reads the default one. The example host sources are unchanged since `50fcd57` (empty `git diff --stat`), so a coincidental match is possible, which is exactly the "absence scored as success" shape; do not rely on it. Also, the path dep `crosswake` would be compiled by the child into the same dedicated directory the outer VM has loaded.
**How to avoid:** `env -u MIX_BUILD_PATH -u DATABASE_PATH MIX_ENV=test mix crosswake.proof_lane.verify_twin …` from `cd` to the candidate, exactly like twin-04. Keep the dedicated path for the outer `mix compile`, probe and preflight only (these spawn no host children). Add a go/no-go label asserting both vars are unset in the run's environment. [Mechanism VERIFIED in scratch; effect on the real run MEDIUM/untested because the twin may not be run here.]
**Warning signs:** `identity_mismatch`/`installed_build` or `backend_build` not passed; a freshly created `_build_188_twin05/lib/crosswake_example`.

### Pitfall 2: Choosing to warm-compile
Compiling the example host (`cd examples/phoenix_host && env -u MIX_BUILD_PATH MIX_ENV=test mix compile`) before the sentinel avoids spending the run's 900 s child deadline on a cold compile. It writes only to ignored `_build` directories, as the run itself would, but it is a write inside the candidate directory. Decide explicitly in the plan (Open Question 2); re-run the probe afterwards, as D-12 already does after the outer compile.

### Pitfall 3: A usage error consumes the run
The sentinel is written before `verify_twin`. A malformed argument vector raises (exit 1, no receipt, no `twin-result.json`). Mitigation: one shared argv, preflight on the same argv, argument names asserted in the self-test.

### Pitfall 4: Sentinel and redirects under noclobber
Tested this session:
- `( set -C; umask 077; date -u +%Y-%m-%dT%H:%M:%SZ > "$R.started" )` creates mode 600; the second identical call fails (`/bin/sh`: "cannot overwrite existing file"; zsh: "file exists"). A dangling symlink at the sentinel path is also refused by zsh.
- In **zsh**, `>>` to a not-yet-existing file also fails under `set -C`. Do not use `>>` for logs while noclobber is on.
- Keep `set -C` inside a subshell so the later `> "$R.stdout"`/`"$R.stderr"` redirects (new files) stay ordinary; those files must not pre-exist, which noclobber would additionally enforce.
- With `set -e`, a failed noclobber redirect aborts the script with non-zero before anything else runs (tested under zsh; sh behaves the same way when the command is the redirect).

### Pitfall 5: Shell dialect traps
- `mix` is an asdf shim; run outside a directory with `.tool-versions` it fails ("No version is set for command mix", tested). Always `cd` into the candidate before `mix`.
- zsh: a non-matching glob (`ls -d twin-[0-9][0-9]`) aborts. Count roots with `find "$RUNS" -maxdepth 1 -type d -name 'twin-[0-9][0-9]' | wc -l` (183-05 precedent), captured to a variable.
- zsh: never assign to `status` (read-only), `path` (tied to `PATH`) or `pipestatus`; precedent uses `rc`.
- macOS BSD `stat`: `stat -f %Lp file` (octal permission), `stat -f %u file` (uid). GNU `stat -c` does not exist here. Compare with `id -u`.
- `lsof` prints nothing and exits 1 when nothing listens; use `[ -z "$(lsof -nP -iTCP:4790 -sTCP:LISTEN 2>/dev/null)" ]`, never branch on its exit status. A foreign `beam.smp` process exists on this machine right now (pid not ours), so do not add a blanket "no beam process" check.

### Pitfall 6: Background monitoring
`verify_twin` ran about 6 minutes in twins 03 and 04. The run deadline is 60 minutes. Start `run-once-05.sh` once with `run_in_background`, then watch `twin-05.exit` with an until-loop that has an upper bound near 75 minutes. If `.exit` never appears, record "ran once, outcome unknown" (D-14); never restart. The orchestrator re-reads `twin-05.exit` and `twin-result.json`. If the executing session ends while the script runs, the run may be killed after `.started`; that is the D-14 outcome, not a reason to retry.

### Pitfall 7: Planning copies leak the home path
The precedents contain `PD=/Users/<name>/projects/…`. If the new scripts are byte-copied into the phase dir (D-08) and then scanned (D-17), the scan fails. Write `PD="$HOME/projects/crosswake/.planning/workstreams/quality-ratchet-release/phases/188-freeze-and-twin-05"` and avoid the words `token`, `secret` and the `@` character in script text (jq's `@sh`/`@json` included) or exclude script copies from the scan scope explicitly and say so. Recommended: keep them clean so the scan covers everything under the phase directory.

### Pitfall 8: Pipe-masked and swallowed status
Examples: `shasum -c … | grep -c OK` hides a non-zero `shasum`; `P=$(git … | wc -c)` hides a git failure (present in `prepare-record.sh`); `$(…)` inside `[ … ]` under `set -e` is not checked. For each gate capture `out=$(cmd 2>&1); rc=$?` (guarded with `|| rc=$?` under `set -e`).

### Pitfall 9: Time-of-check gap between `mkdir` and the script
D-13 puts `mkdir -m 0700` in a separate step. Nothing else should touch the directory between that step and the script; the gate requires the root be completely empty (`[ -z "$(ls -A "$R")" ]`), which is stricter than "no receipt".

### Pitfall 10: Wording of the sidecar versus the result
`twin-result.json` lists five limits, none of which is "ignored files are not counted" or "Phase 179 identity join deferred". If verification greps the JSON for them it will fail. Check them in `188-TWIN-RECORD.md`.

## Code Examples

All examples below were executed in the session scratchpad (never against twin-05 or the candidate) unless noted.

### Result assertion (positive on twin-04, seven negative controls fail)
```sh
#!/bin/sh
# usage: assert-twin-05.sh <twin-result.json> [<receipt.json>]   exit 0 = TWIN-08 shape holds, 1 = it does not
set -u
RES=${1:?result json}; REC=${2:-}
[ -f "$RES" ] || { echo "assert: result missing"; exit 1; }
jq -e '
  ["T01","T02","T03","T04","T05","T06","T07","T08","T09","T10"] as $groups
  | ["source","dependency_lock","generated_resources","served_static","installed_media","installed_build","backend_build"] as $joins
  | ["simulator not physical speaker","simulator not signed device","synthetic_test_authority not real adopter","trusted local runner not cryptographic certification","source edit made and reverted during a run not detected"] as $limits
  | ["physical iPhone signed-device run","first adopter sanitized route handoff"] as $gates
  | .schema == "crosswake.twin_result/1"
  and .exit_status == 0 and .overall_status == "passed"
  and (.groups | map(.id)) == $groups
  and (.groups | all(.status == "passed" and (.sub_observations | length) >= 1
        and (.sub_observations | all(.outcome == "passed" and .cause == null))))
  and (.identity_joins | map(.id)) == $joins
  and (.identity_joins | all(.outcome == "passed" and .cause == null))
  and .fidelity_limits == $limits
  and .residual_external_gates == $gates
  and (.receipt_sha256 | test("^[0-9a-f]{64}$"))
' "$RES" >/dev/null || { echo "assert: shape check failed"; exit 1; }
if [ -n "$REC" ]; then
  [ -f "$REC" ] || { echo "assert: receipt missing"; exit 1; }
  want=$(jq -r .receipt_sha256 "$RES"); got=$(shasum -a 256 "$REC" | cut -d' ' -f1)
  [ "$want" = "$got" ] || { echo "assert: receipt digest mismatch"; exit 1; }
fi
echo "assert: ok"
```
Observed this session: twin-04 result plus its receipt returned `assert: ok` (rc 0). rc 1 for: empty groups/joins file, 9-group file, 6-join file, a planted non-null cause, an emptied sub-observation list, a 4-limit file, the twin-02 blocked result, a mismatching receipt (twin-03's), and a missing file. The sub-observation total (49) is deliberately not asserted as a constant beyond `>= 1` per group, matching D-18; add `([.groups[].sub_observations[].id] | length) == 49 and (unique | length) == 49` if the planner wants the 183-05 strictness. [VERIFIED: scratch run]

### History manifest + root checks + exactly-once sentinel + scan control (all passed in scratch)
```sh
# manifest: rc and OK count captured separately (no pipe masking)
out=$(shasum -a 256 -c "$RUNS/history-184.before.sha256" 2>&1); rc=$?
n=$(printf '%s\n' "$out" | grep -c ': OK$')
[ "$rc" -eq 0 ] && [ "$n" -eq 87 ]            # printed: history_manifest pass
# root: BSD stat
[ "$(stat -f '%Lp' "$R")" = 700 ] && [ "$(stat -f '%u' "$R")" = "$(id -u)" ] && [ -z "$(ls -A "$R")" ]
# sentinel
( set -C; umask 077; date -u +%Y-%m-%dT%H:%M:%SZ > "$R.started" )   # 2nd call: refused
```
Scan (two greps, because `-w` and a pattern containing `@` do not mix):
```sh
pat='/Users/|/private/var|/var/folders|[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}|token|secret|@|CrosswakeExample\.Router|unmanaged_(routes|paths)'
grep -IlE -e "$pat" "$@" ; [ $? -eq 1 ]          # 1 = no file matched
grep -Ilw -e "$(id -un)" "$@" ; [ $? -eq 1 ]
```
Precedent run: zero hits across `twin-04/`, `twin-04.stdout`, `twin-04.stderr`, `183-TWIN-RESULT.json`, `183-IDENTITY.json`. A planted `/Users/…` file was detected. Note `grep -r` exit 2 on an unreadable path would otherwise read as "clean" under a naive `! grep`; require rc exactly 1.

### Record the stage and cause for the failure branch (D-20)
```sh
sed -n 2p "$RUNS/twin-05.stdout"          # "first cause: <id> <cause>" or atom
jq -c '{not_reached, last: (.stages|last)}' "$R/run-stages.json"   # closed values only
cat "$RUNS/twin-05.exit"                  # 1 failed, 2 blocked
```
If `twin-result.json` is absent, say "raw output not retained" and keep `cause_not_retained`.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| twin-04 gate: `preflight-04.sh` then `mkdir` inside `run-once-04.sh`, no lock | One script, pre-created 0700 root, noclobber sentinel | D-12/D-13 | A second invocation fails at the sentinel; a refused run leaves the pre-created root alone. |
| Real run did not compare record and identity digests | Preflight compares; shell gate also recomputes from committed bytes | Phase 184 (D-31), Phase 188 (D-07a) | WR-05 closed by the gate. |
| Source gate read HEAD/tree only | Source gate also checks clean tree, lockfiles, study script; probe pins git behaviour | Phase 183-184 | Twin-05 cannot silently run on uncommitted code. |

**Deprecated/outdated for this phase:** `gate.sh`, `run-once.sh`, `run-once-02/03.sh` (183-04 forbids reuse); `twin-02-candidate.json`.

## Runtime State Inventory

Not a rename/refactor/migration phase. Omitted per the template, except one explicit note: after the run the following runtime state exists outside git and must be recorded, not cleaned: `twin-05/` (root), `twin-05.started/.stdout/.stderr/.exit`, `twin-run-path-05`, `go-no-go-05.json`, `_build_188_twin05/`. A leftover `crosswake-phase180-twin-*` Simulator device after the run is the 185 WR-02 reopen trigger and must be reported (check `xcrun simctl list devices | grep -c crosswake-phase180-` after the run).

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `jq` | all scripts | yes | jq-1.7.1-apple | none needed |
| `shasum` | digests, manifest | yes | system | — |
| `git` | freeze, refresh | yes | system (>= 2.41 required by the task, `action_for(:prerequisite_missing)`) | — |
| `lsof` | port 4790 check | yes | `/usr/sbin/lsof` | — |
| `perl` | `group_leader_wrapper` in the runtime | yes | `/usr/bin/perl` | runtime falls back without it |
| Elixir/OTP via asdf | preflight, probe, run | yes | 1.19.5-otp-27 / erlang 27.3 (`.tool-versions`) | — |
| Xcode / `xcrun simctl` | the run | yes | Xcode 26.6 | none (blocks) |
| iOS Simulator runtime | the run | yes | iOS 26.5 available; iPhone device types present (`simctl list -j` check printed `true`) | none |
| Port 4790 free | origin listener | yes | `lsof` printed nothing | — |
| Free disk | build + Simulator | yes | 491 GiB free | — |

Simulator availability command used by the journey and mirrored for the gate: `xcrun simctl list -j devicetypes runtimes | jq -e '([.runtimes[]|select(.isAvailable==true and (.name|startswith("iOS ")))]|length) as $r | ([.devicetypes[]|select(.identifier|contains("iPhone"))]|length) as $d | ($r>=1 and $d>=1)'` (printed `true`, rc 0). Stale device check: `xcrun simctl list devices | grep -q 'crosswake-phase180-'` (the journey creates devices named `crosswake-phase180-twin-<run_id>`, twin_journey.ex:339); currently zero. Booted devices: none.

**Missing dependencies:** none.

## Validation Architecture

`workflow.nyquist_validation` is `true` in `.planning/config.json`.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | POSIX `sh` scripts with `jq -e` assertions and negative controls; no ExUnit work (no product code changes) |
| Config file | none; scripts live in `/private/tmp/crosswake-phase180-run/` |
| Quick run command | `sh /private/tmp/crosswake-phase180-run/selftest-188.sh` (throwaway dirs only, stub `mix` on `PATH`, never `verify_twin`, never `twin-05`) |
| Full suite command | selftest + the D-11 manifest check + `assert-twin-05.sh` on the real result + the D-17 scan |
| Typical runtime | selftest under 30 s (no compile); the real compile+preflight takes minutes |

Rules carried from project memory: never pipe a check into `tail`/`head` and trust the `&&`; never accept a test that ran zero cases (the selftest must print the number of controls executed and the gate requires the expected number).

### Self-test design (D-16 compliant)
- `selftest-188.sh` builds a throwaway repo (`git init` under a scratch dir, commit small files at the four fixture paths plus two lockfiles) and a throwaway RUNS directory. It points the scripts at them through environment overrides (`CANDIDATE`, `RUNS`, `PD`, `RECORD`) as `preflight-04.sh` does, and refuses to run if the resolved run root equals the real `twin-05` path or the real candidate path.
- A stub `mix` earlier on `PATH` records its argv to a file and exits 0 or 2. This proves the sentinel/exit-file/argv logic without any Simulator. The stub proves that the `verify_twin` argv is byte-identical to the preflight argv except the task name.
- Every control prints a fixed label and result; the script exits non-zero if any control behaved unexpectedly or if the count of executed controls is not the expected constant.

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | Exists? |
|--------|----------|-----------|-------------------|---------|
| TWIN-07 / crit 1 | HEAD, tree, clean, push URL, zero probe at freeze | script | D-02 block: `g rev-parse HEAD` equals `a53fbef…`; `g status --porcelain=v1 -z --untracked-files=all` is 0 bytes; probe pattern-match exits 0; `g remote get-url --push origin` equals `no-push-phase180` | Wave 0 |
| TWIN-07 / crit 1 | refresh writes git-derived values only, copies old records, is idempotence-safe | script + negative | `refresh-handoffs-188.sh a53fbef…` then `jq -e '.repaired_head==$h and .repaired_tree==$t'` on the seam record and `jq -e '.head==$h and .tree==$t and (.core_diff_paths==$paths)'` on the 182 record, where `$paths` is `git diff --name-only <base> <head>` as a JSON array; negative controls in the throwaway repo: wrong SHA argument, dirty tree, record head not an ancestor, missing argument (each must exit non-zero and write nothing), and a second run must not overwrite an existing `*.pre-188.json` | Wave 0 |
| TWIN-07 / crit 1 | twin-01..04 records byte-unchanged | script | `shasum -a 256 -c history-184.before.sha256` rc 0 and 87 OK at three points; `cmp twin-04/twin-result.json 183-TWIN-RESULT.json`; negative control: a copied manifest with one byte-altered scratch file must fail | Wave 0 |
| TWIN-07 / crit 1 | no later commit changes attested source | script | after the run: `g rev-parse HEAD` still `a53fbef…`, porcelain 0 bytes, push URL unchanged (also D-21) | Wave 0 |
| TWIN-07 / crit 2 | gate: matching digests (record vs fresh `git show`, identity vs record) | script + negative | gate labels `record_digests`, `identity_digests`; negative controls in the throwaway repo: change one digest in a copy of the record, change `media.sha256` in a copy of the identity | Wave 0 |
| TWIN-07 / crit 2 | gate: 0700 root with no receipt, empty, owned, outside candidate | script + negative | controls: mode 0755, mode 0700 plus `receipt.json`, plus `twin-result.json`, non-empty root, root inside the throwaway candidate, symlink root, `twin-05.started` present, wrong root count | Wave 0 |
| TWIN-07 / crit 2 | D-07(b) gitlinks and `.gitmodules` | script + negative | positive on real candidate (count 0); negative: throwaway repo with a mode-160000 entry (`git update-index --add --cacheinfo 160000,<sha>,sub`) and one with `.gitmodules` | Wave 0 |
| TWIN-07 / crit 2 | D-07(c) no doctor JSON in inputs | script + negative | positive over the identity file, record, handoff records; negative: planted `"unmanaged_paths"` file | Wave 0 |
| TWIN-07 / crit 2 | preflight passes, read-only | command | `cd candidate && env -u DATABASE_PATH MIX_ENV=test MIX_BUILD_PATH=$B mix crosswake.proof_lane.twin_preflight ios --candidate … --run-root … --identity …` rc 0, exactly 4 lines `^(result|first cause|report|next action): `, `result: allowed`, `report: none written; no run root was created or consumed`; afterwards the root is still empty and the candidate porcelain is 0 bytes | at go/no-go only (reserved) |
| TWIN-07 / run once | second invocation fails at the sentinel | script | in throwaway dirs with the stub `mix`: first run creates `.started` (mode 600) and `.exit`; second run exits non-zero before invoking the stub (stub argv log has exactly one entry); a pre-existing `.started` blocks the first run | Wave 0 |
| TWIN-07 / run once | exactly one `verify_twin` call | script | `grep -c 'verify_twin' run-once-05.sh` equals 1 for the invoking line; no `while`, `until`, `for`, `timeout`, `||` retry around it (static grep controls); after the real run, exactly five `twin-NN` roots | Wave 0 |
| TWIN-08 / crit 3 | exit 0 | file | `[ "$(cat twin-05.exit)" = 0 ]` and line 1 of `twin-05.stdout` is `result: passed (exit 0)` | at run |
| TWIN-08 / crit 3 | ten groups, seven joins, limits, receipt digest | script | `assert-twin-05.sh twin-05/twin-result.json twin-05/receipt.json` rc 0; self-test: passes on the twin-04 result and fails on empty-groups, 9-group, 6-join, non-null cause, empty sub-observations, 4-limit, blocked (twin-02) and mismatching receipt (all observed this session) | Wave 0 |
| TWIN-08 / crit 3 | byte copy | file | `cp twin-05/twin-result.json 188-TWIN-RESULT.json`; `cmp` rc 0; full 64-hex sha256 of both equal and recorded | at run |
| TWIN-08 / crit 3 | privacy | script + negative | `scan-privacy-188.sh` over every file under the phase dir plus the two refreshed records and `twin-05/` + stdout/stderr: grep rc exactly 1 for each of the two greps; positive control proves a planted hit is found; positive-hit-free precedent proven on twin-04 | Wave 0 |
| TWIN-08 / crit 3 | limits disclosed | grep | `188-TWIN-RECORD.md` contains the five limit strings verbatim, "ignored files", "Phase 179 identity join", "DEBT-IDENT", `org.crosswake.twin`, and both residual gates; opens with "A pass means the Simulator twin saw" | at record |
| TWIN-08 / crit 4 | failure preserved honestly | script | if `.exit` is 1 or 2: result copied only if it exists; `188-NN-BLOCKED.md` exists and no `188-NN-SUMMARY.md`; stage and cause lines present; no second `twin-05.started`/`twin-06` path exists; STATE/ROADMAP contain the single handoff sentence | conditional |

### Sampling Rate
- **Per task commit (no commits here; per task completion):** the selftest plus the manifest check.
- **Per wave:** selftest, manifest check, candidate untouched (`HEAD`, porcelain, push URL).
- **Phase gate:** D-21 list: manifest, `cmp`/sha256, `assert-twin-05.sh` success mode and negative mode, candidate unchanged, privacy scan.

### Wave 0 Gaps
- [ ] `selftest-188.sh` and its throwaway fixtures (scratch repo with gitlink and `.gitmodules` variants)
- [ ] `assert-twin-05.sh` (draft above passes the controls)
- [ ] `scan-privacy-188.sh` (regex above; positive-hit control)
- [ ] `run-once-05.sh`, `refresh-handoffs-188.sh`, `make-identity-188.sh`
- [ ] `188-VALIDATION.md` seeded from this section

## Security Domain

`security_enforcement` is absent in `.planning/config.json`, so it is treated as enabled.

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — |
| V3 Session Management | no | — |
| V4 Access Control | yes (local) | file modes: record 0600, root 0700 owned by the current uid, sentinel 0600, `umask 077` |
| V5 Input Validation | yes | scripts take only a required SHA argument and fixed paths; SHA validated as 40 lowercase hex before use; all jq values passed with `--arg` |
| V6 Cryptography | no (integrity only) | `shasum -a 256` for digests; never hand-roll |
| V7/V8 Logging, data protection | yes | privacy-safe closed outputs only; no raw receipts, no xcresult, no stdout/stderr content in planning; scan with zero hits |

### Known Threat Patterns
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| TOCTOU between gate and run | Tampering | gate and run in one script; the run re-checks everything itself |
| Candidate modified after freeze | Tampering | gate recomputes HEAD/tree/probe; post-run D-21 check |
| Env/redirect injection into git | Tampering | scrubbed `g()` wrapper, `GIT_*` unset |
| Symlink at sentinel or root | Spoofing | `lstat` root check in the task; noclobber refuses dangling symlink (tested) |
| Consumed binding replay (second run) | Repudiation | sentinel never removed; script refuses permanently (D-14) |
| Home path, username, device ids leaking into planning | Information disclosure | D-17 scan with positive control; script copies built from `$HOME` |
| Adopter identification | Information disclosure | codename only; the example router module name is synthetic but still scanned (D-07c) |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The pattern-match form of the probe call (`{:ok, %{modified: 0, flagged: 0, excludes: 0}} = …`) works as written under `mix run --no-start` | CLI surface | Gate false-fails; fix in the selftest against a scratch clone |
| A2 | Marking 182-era fields with top-level `checks_status`/`simulator_status` satisfies D-09's "marks them not_rerun_at_freeze_head" | JSON shapes | Reviewer wants per-field marking; cheap to change |
| A3 | A background Bash task survives until `twin-05.exit`; if the session ends it may be killed after `.started` | Pitfall 6 | Outcome becomes "ran once, outcome unknown" per D-14 |
| A4 | A warm host compile (Pitfall 2) is acceptable inside D-03's "nothing writes into the candidate" because it only touches ignored `_build` dirs, as the run itself does | Pitfall 2 | Owner may prefer no pre-run write; then skip it and rely on the run's 900 s compile deadline |
| A5 | Running `verify_twin` with `MIX_BUILD_PATH` unset reuses the candidate's default `_build/test` (last touched 2026-10-16 15:07) and Mix recompiles stale sources automatically | Pitfall 1 | Verified for a scratch project (stale task source recompiled on `mix <task>`); not verified on the real candidate |

## Open Questions

1. **How to treat `MIX_BUILD_PATH` for the run itself.**
   - What we know: D-12 sets the dedicated path for compile, probe and preflight; the run's children inherit any exported value.
   - What's unclear: whether the owner intended the dedicated path to cover the run. The twin-04 precedent and 187's full-suite runs used no `MIX_BUILD_PATH`.
   - Recommendation: unset it for the run (`env -u MIX_BUILD_PATH -u DATABASE_PATH`) and add a gate label proving both are unset; state this as a refinement of D-12 in the plan.
2. **Warm-compile the example host before the sentinel?** Recommended yes (avoids burning the run's compile deadline), with a re-probe after; planner decides and records.
3. **`core_diff_paths` semantics at the freeze head.** Recommend computing `git diff --name-only <base_head> <freeze>` (129 paths) and noting the meaning change in the record. If the owner would rather keep the 182-scoped list, the record would instead keep the original 33 paths under `supersedes` and add the new list under a different key.
4. **Scope of the D-17 scan for script copies.** Recommend making the scripts free of the scan tokens so the whole phase directory can be scanned; otherwise name the exclusion explicitly.
5. **Strictness of the 49-observation count.** D-18 requires each group to have at least one passing observation; 183-05 additionally required 49 unique ids. Recommend adding the 49/unique check as an extra constant since the roster source is byte-unchanged.

## Sources

### Primary (HIGH confidence, read this session)
- `/private/tmp/crosswake-phase180-run/prepare-record.sh`, `preflight-04.sh`, `run-once-04.sh`, `run-once-03.sh`, `twin-04-candidate.json`, `history-184.before.sha256`, `twin-04/{twin-result.json,run-stages.json,expectations.json}`, `twin-04.{started,exit,stdout}`, `twin-02/twin-result.json`, `history-187.after.out`, `real-probe-187.out`
- Candidate `lib/mix/tasks/crosswake.proof_lane.verify_twin.ex`, `…twin_preflight.ex`, `lib/crosswake/proof_lane/twin_preflight.ex`, `twin_runtime.ex` (L55-135, L340-643), `twin_producers.ex` (L615-800, L1515-1600), `twin_receipt.ex` (L15-80, project/first_cause L385-445), `twin_journey.ex` (L215-262, L318-400, L720-735), example host `twin_fault_controller.ex` (L278-287)
- Candidate git state: `rev-parse`, `status --porcelain`, `remote get-url --push`, `ls-tree`, `diff --name-only`, `merge-base --is-ancestor`
- Planning: `188-CONTEXT.md`, `REQUIREMENTS.md` (TWIN-07/08, Acceptance Boundaries), `ROADMAP.md` (Phase 188), `STATE.md`, `183-IDENTITY.json`, `180-SEAM-HANDOFF.json`, `182-FINAL-HEAD.json`, `183-04-PLAN.md`, `183-05-PLAN.md`, `184-10/12/14-PLAN.md` (gitlink check), `186-05-PLAN.md`, `187-07-PLAN.md`, `187-VALIDATION.md`
- Scratch experiments (session scratchpad): noclobber behaviour in zsh and `/bin/sh`; Mix project-task recompilation; Erlang `Port.open` `env` extension; assert script controls; scan controls

### Secondary (MEDIUM)
- Erlang `open_port/2` `env` semantics, as cited from documentation memory and confirmed by the scratch run

### Tertiary (LOW)
- None

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH, nothing new installed.
- Script interfaces, CLI surface, exit codes, JSON shapes: HIGH, read from source and run records.
- Architecture and plan split: MEDIUM-HIGH, follows the locked decisions.
- Pitfalls: HIGH for shell and file-system behaviour (tested); MEDIUM for the MIX_BUILD_PATH effect on the real run (mechanism proven, run forbidden).

**Research date:** 2026-10-16
**Valid until:** until the candidate HEAD moves off `a53fbef…` or twin-05 starts, whichever comes first.

## Project Constraints (from AGENTS.md; no CLAUDE.md exists)

- Recovery checkout: no staging, commits, tags, branches or worktrees; planning files are plain uncommitted files. Nothing is pushed, merged or released.
- Sensitive data: never record or infer the real adopter identity; use "first adopter" / `first_b2c_adopter`; no raw answers, media, transcripts, credentials, account identifiers, tokens or stable device identifiers in proof artifacts.
- Zero-human verification: no `checkpoint:human-verify`; the agent runs the checks and the result is the gate.
- Plain-language status first (what was checked, what happened, what is unknown and why, whether anything changed, next action); do not explain with status codes; say "raw output not retained" when that is true.
- Handoff discipline: one active handoff in STATE/ROADMAP; retire superseded handoffs to history; name the exact next command from the workstream.
- Before displaying a write proposal, exercise the production adapter with the dependency's real return shape; retain a privacy-safe cause for every blocked runner stage.
- Tooling rule from project memory: never pipe a check into `tail`/`head` and trust the `&&`; blocked plans leave `NN-BLOCKED.md`, not `NN-SUMMARY.md`; the gap-analysis gate is workstream-unaware, so verify TWIN-07/08 coverage by grep.
