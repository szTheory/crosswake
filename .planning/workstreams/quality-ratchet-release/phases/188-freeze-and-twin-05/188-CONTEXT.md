# Phase 188: Freeze and twin-05 - Context

**Gathered:** 2026-10-16
**Status:** Ready for planning

<domain>
## Phase Boundary

Freeze the hardened v26 candidate and prove it with exactly one twin-05 run, preserving the result honestly whether it passes or fails. Two requirements: TWIN-07 (freeze, scripted refresh, read-only preflight, scripted go/no-go, then one run) and TWIN-08 (exit 0 with ten groups and seven identity joins, byte-copy into planning, disclosed fidelity limits, no retry to green on failure).

Phase 188 changes **no product code**. The candidate `/private/tmp/crosswake-phase180-impl` is frozen at its current HEAD. Every artifact this phase writes is a run-directory script or record in `/private/tmp/crosswake-phase180-run/`, or a plain uncommitted planning file in this phase directory. The recovery checkout is never staged, committed, tagged or branched. Nothing is pushed, merged or released, and the candidate commits are not delivered into the main tree; delivery needs separate authorization.

Out of the boundary:
- fixing any open review warning (D-04);
- rerunning the 181-10, 180-01 or 182 Simulator harness gates (D-09);
- any receipt or manifest schema change;
- a rehearsal or dry twin run;
- a second run of any kind (D-20);
- new dependencies or CI lanes.

</domain>

<decisions>
## Implementation Decisions

All four areas were researched in parallel (advisor mode, minimal-decisive tier) under the owner's fan-out brief. The owner asked for the synthesized recommendations to be followed without per-area questions. Research decisions from `.planning/research/v26/` carry forward unchanged: CHALLENGE R1, R2, M4, K6, S3 and the "Twin-05 protocol" section; PITFALLS Pitfall 5 as corrected by R2.

### Freeze (TWIN-07, criterion 1)
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

### Pre-freeze fix scope
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

### Scripted refresh and run-directory records (TWIN-07, criteria 1–2)
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

### Go/no-go and the single run (TWIN-07 criterion 2, TWIN-08 criterion 3)
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

### Result capture, limits and failure (TWIN-08)
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

### Phase mechanics
- **D-21:** On success, verification re-runs D-11, D-17's `cmp` and sha256 checks, and D-18 in its success and negative self-test modes. It confirms the candidate HEAD is still `a53fbef`, its status is empty, and the push URL is unchanged. STATE.md and ROADMAP.md then record v26 Phase 188 complete. The handoff is "v26.0 ready for milestone audit/close", and the candidate delivery gate stays open.

### Claude's Discretion
- Exact script names and JSON label strings, as long as each check has a fixed label and the output carries no paths.
- Plan split: for example, freeze and refresh records; then go/no-go and the run; then capture, assertion and record. The run plan must depend on every record being written.
- The exact `jq` expressions and privacy-scan regex, provided they meet D-17 and D-18.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Scope and decisions
- `AGENTS.md` — working rules, sensitive-data rules, checkout prohibitions, zero-human verification
- `.planning/workstreams/quality-ratchet-release/ROADMAP.md` — Phase 188 goal and success criteria 1–4
- `.planning/workstreams/quality-ratchet-release/REQUIREMENTS.md` — TWIN-07, TWIN-08, Acceptance Boundaries
- `.planning/workstreams/quality-ratchet-release/STATE.md` — Exact Next Action, carried deviations (adoption scan, MIX_BUILD_PATH hazard)
- `.planning/research/v26/CHALLENGE.md` — "Twin-05 protocol", R1, R2, M4, M7, K6, S3
- `.planning/research/v26/PITFALLS.md` — Pitfall 5 (run-root consumption; corrected by R2), stale-binding pitfall
- `.planning/research/v26/SUMMARY.md` and `ARCHITECTURE.md` — freeze ordering, authority for twin-05
- `.planning/research/v26/FEATURES.md` — DEF-SNAP, DEBT-IDENT deferral rows

### Precedent (twin-04 and the handoff records)
- `.planning/workstreams/quality-ratchet-release/phases/183-close-gap-twin-source-binding-fails-closed-on-uncommitted-co/183-03-PLAN.md`, `183-04-PLAN.md`, `183-05-PLAN.md` and their SUMMARYs — prepared record, identity computation, single run, byte-copy
- `.../phases/183-close-gap-twin-source-binding-fails-closed-on-uncommitted-co/183-TWIN-RESULT.json`, `183-IDENTITY.json`
- `.../phases/180-bounded-digital-twin-demonstration/180-SEAM-HANDOFF.json` — refreshed by D-09
- `.../phases/182-loopback-origin-for-local-ios-host/182-FINAL-HEAD.json` — refreshed by D-09
- `.../phases/184-twin-probe-and-safe-preflight/` — preflight (PROBE-04), WR-05/D-31, GAP4-WR-01, D-36
- `.../phases/185-checks-that-cannot-pass-empty/` review and disposition — WR-02..05
- `.../phases/186-host-seam-and-harness-honesty/186-REVIEW-DISPOSITION.md` — WR-01, WR-02
- `.../phases/187-doctor-and-proof-fidelity/187-REVIEW.md`, `187-REVIEW-DISPOSITION.md`, `187-VERIFICATION.md` — WR-02, WR-04, IN-03

### Run directory (`/private/tmp/crosswake-phase180-run/`)
- `prepare-record.sh`, `preflight-04.sh`, `run-once-04.sh` — script precedents
- `twin-04-candidate.json` — prepared-record precedent
- `history-184.before.sha256` — 87-entry byte-unchanged manifest
- `twin-run-count.before-04`, `twin-run-path-04` — run-count precedent

### Code (candidate `/private/tmp/crosswake-phase180-impl`, read-only)
- `lib/mix/tasks/crosswake.proof_lane.verify_twin.ex` — run arguments (~L26)
- `lib/mix/tasks/crosswake.proof_lane.twin_preflight.ex`, `lib/crosswake/proof_lane/twin_preflight.ex` — read-only preflight, exit 0/2
- `lib/crosswake/proof_lane/twin_runtime.ex` — `run_root` and `run_root_check` (`create?: false`), `acquire_origin` port 4790, run deadline
- `lib/crosswake/proof_lane/twin_producers.ex` — `freeze/3` (~627), `clean_tree/2`, probe
- `lib/crosswake/proof_lane/twin_receipt.ex` — closed causes (~23-43), identity joins (~46-54), `@fidelity_limits` (~58-64), residual gates (~65-69), projection, `first_cause` (~433-441)
- `lib/crosswake/proof_lane/twin_journey.ex` — DEBT-IDENT hardcoded bundle id (~20)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `prepare-record.sh`: refuses on a dirty probe or an existing output; writes with `jq -n`, `chmod 0600` and `mv -n`; digests come from `git show HEAD:<path>`; scrubbed `g()` git wrapper.
- `run-once-04.sh`: the sentinel/exit-file single-run shape to copy for twin-05.
- `twin_preflight` mix task: read-only, covers run root and checks, source gate and identity digests; exit 0 allowed, 2 blocked; writes nothing.
- `history-184.before.sha256`: already covers twin-01..04 roots, sibling files, scripts and the 180/183 result and identity files.

### Established Patterns
- One-time evidence scripts live in the run directory, outside both checkouts. They are copied into the phase directory as evidence.
- Each step gets a dedicated `_build_<phase>_<plan>_<kind>` build path.
- Results go into planning as a byte-copy of the closed projection `twin-result.json`, never raw logs.
- Blocked plans leave `NN-BLOCKED.md`, not SUMMARY.

### Integration Points
- No product code reads the handoff records. They are planning-only and are checked by scripts and verification.
- The candidate tree is the attested unit, so any write into it after D-02 invalidates the run.

</code_context>

<specifics>
## Specific Ideas

- The record's first line is in plain language, and states what a pass does and does not mean before any status code (AGENTS.md handoff style).
- Current verified facts at discussion time (2026-10-16): the candidate HEAD is `a53fbef70d20…` with an empty porcelain status; `twin-05` does not exist; there are four twin roots; the history manifest has 87 entries and includes `183-TWIN-RESULT.json`.

</specifics>

<deferred>
## Deferred Ideas

- Fix 186 WR-01 and WR-02 (physical-iPhone preflight). Trigger: the first physical-iPhone run or the next preflight change.
- Fix 187 WR-02 and WR-04 (nested-host provenance and the public predicate). Trigger: provenance used from a nested host directory, or the next `Evidence` change.
- 184 GAP4-WR-01 (bounded read of git local files). Trigger: the next twin-touching change.
- 185 WR-02..05. Trigger: their recorded triggers; a leftover twin process after twin-05 reopens WR-02.
- DEF-SNAP snapshot-clone run source; DEBT-IDENT generated-identity attestation. Disclosed as limits.
- Promote the go/no-go into a reusable candidate mix task. Only in a future change that is not frozen, and only if twin runs recur.
- Deliver candidate commits into the authoritative tree. This needs separate authorization.

</deferred>

---

*Phase: 188-freeze-and-twin-05*
*Context gathered: 2026-10-16*
