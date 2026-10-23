# Phase 177: Maintenance and Queue Reconciliation - Pattern Map

**Mapped:** 2026-10-12  
**Files analyzed:** 11 likely deliverables; exact source changes and evidence filenames remain execution-dependent  
**Analogs found:** 10 / 11 (one isolation/delivery seam unresolved)

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/mix/tasks/crosswake.release.candidate_read.ex` (behavior-level change only if proven) | route/controller | request-response + file-I/O | same file; `lib/crosswake/release_candidate/plan93_candidate_read.ex` | exact role; mixed behavior |
| `lib/mix/tasks/crosswake.release.mirror_tag_026.ex` (behavior-level change only if proven) | route/controller | request-response + file-I/O | same file; `lib/crosswake/release_candidate/plan146_tag_apply.ex` | exact role; mixed behavior |
| Existing affected `test/crosswake/release_candidate/*` and `test/mix/tasks/*` (only selected modes) | test | request-response + file-I/O | `test/mix/tasks/crosswake_release_candidate_test.exs`; `test/crosswake/release_candidate/plan146_tag_apply_test.exs` | role-match |
| `177-evidence/queue-inventory.json` (filename proposed) | evidence / data | request-response + transform | Phase166 ownership ledger validator; Phase167 PR disposition validator | role-match; live identities differ |
| `177-evidence/check_queue_inventory.py` (only if existing validators cannot cover the artifact) | utility | transform + file-I/O | `script/check_phase166_ownership_ledger.py` | role-match |
| `177-evidence/queue-reader-fixture.py` (only if an API/CLI reader is introduced) | test / fixture | request-response + subprocess | `test/js/phase167_pr_dispositions.test.mjs` | role-match, bounded |
| `.planning/PROJECT.md` | document | transform | current project decision docs and Phase167 reconciliation precedent | role-match |
| `.planning/workstreams/quality-ratchet-release/.continue-here.md` | document / handoff | transform | `.planning/workstreams/quality-ratchet-release/STATE.md` exact-action section | role-match |
| `.planning/workstreams/quality-ratchet-release/STATE.md` and `ROADMAP.md` | config / handoff | transform | same workstream artifacts and installed GSD workstream-aware writer (if available) | exact content role; writer availability unresolved |
| Affected canonical `README.md`, `docs/COMPANION-PUBLISH-RUNBOOK.md`, `docs/RELEASE-INCIDENT-RESPONSE.md`, task docs | document | transform | current source docs and `script/check_release_runbook_ancestry.sh` | role-match |
| `guides/capability_map.md`, `guides/support_matrix.md` if rendered projections change | generated document | transform | `lib/mix/tasks/crosswake.docs.sync.ex` | exact |
| Source/patch handoff from qualified GSD isolation | delivery artifact | file-I/O | no verified analog available in this environment | none |

The context leaves exact inventory/checker filenames open. These are candidate assignments, not a mandate to add all files. The dated queue record is a phase evidence artifact; a reusable/permanent queue API, bot, workflow, or CI lane is outside scope. For every mixed release module, classify individual modes and handlers: do not claim an entire file obsolete while inspection remains useful or while any writer is not proven spent. Phase167’s fixed identities must not be reused for the current queue.

## Pattern Assignments

### Mixed release modes: candidate reader and mirror-tag router

**Analogs:** `lib/mix/tasks/crosswake.release.candidate_read.ex`, `lib/mix/tasks/crosswake.release.mirror_tag_026.ex`, `lib/crosswake/release_candidate/plan93_candidate_read.ex`

The Plan93 task parses a strict option set, rejects positional/invalid arguments before dispatch, and uses a closed mode case (`candidate_read.ex:19-47`). Its `plan93-inspect` branch reads and reports the existing artifact (`:75-83`); `plan93-prepare` reserves a fixed locator and explicitly refuses retry (`:54-72`); `plan93-preflight` constructs authorization and invokes a production adapter (`:98-147`). These are distinct data flows and side effects. `Plan93.production_adapter/1` checks the token and supplies the production collector (`plan93_candidate_read.ex:215-236`); the collection seam accepts map or `{:ok, map}`, preserves `{:error, reason}`, and converts malformed values/exceptions to `:observation_unavailable` (`:238-256`). Do not use `prepare`, `hold`, or preflight as caller-discovery reads.

The mirror-tag task has many independent mode branches, including historical/current inspectors and prepare/decision/apply routes (`lib/mix/tasks/crosswake.release.mirror_tag_026.ex:28-291`). Inspect handlers individually. A concrete terminal inspection pattern is `plan142_tag_terminal_inspect_mode/1` (`:423-430`); apply branches have their own terminal failure reporting (`:384-419`). The source module and plan number alone prove neither supported status nor obsolescence. Trace each candidate to implementation, dynamic task invocation, shell, workflow, stage registry, package exposure, docs and tests as required by CONTEXT D-05–D-10. `mix.exs:96-106` includes `lib` in package files, which is exposure to review, not proof of supported API.

When a mode is selected for retirement, keep explicit rejection before credential lookup, API/subprocess launch, evidence writes, or authorization consumption. Preserve an inspector where its archive schema/verdict is still needed, and verify it against the preserved artifact. Keep or adapt tests for enduring guard invariants; remove a test only when its sole contract is the proven-spent invocation. Candidate uncertainty means retain with a specific missing fact and next action.

### Queue inventory and phase-local evidence check

**Analogs:** `script/check_phase166_ownership_ledger.py`, `script/check_phase167_pr_dispositions.py`, `test/js/phase167_pr_dispositions.test.mjs`

Phase166 provides a useful stdlib validator shape: typed problem records with bounded rendering, exact table schemas, uniqueness/completeness checks, and synthetic temporary-repository fixtures (`script/check_phase166_ownership_ledger.py:54-78,111-154,381-455`). Its runnable self-test is:

```sh
python3 script/check_phase166_ownership_ledger.py --self-test
```

This validates its own historical ledger contract, not Phase177’s GitHub queue. Phase167 has useful subprocess and GraphQL pagination precedent: `run_json` uses fixed argv with captured stdout/stderr and JSON decoding (`script/check_phase167_pr_dispositions.py:454-465`); its comment connection checks required fields, total-count stability, unique IDs, cursor progress, and exact observed count (`:1097-1187`). Its tests exercise validator subprocess output using `spawnSync("python3", [script, ...args])` and assert status/stdout/stderr (`test/js/phase167_pr_dispositions.test.mjs:1-30`). However, that checker fixes Phase167 object numbers, receipts and OIDs (`script/check_phase167_pr_dispositions.py:123-200,377-379`) and must not serve as the current queue validator or provide prefilled live identities.

For Phase177, query open issues and open PRs through distinct, fully paginated connections. Check both `totalCount`s, unique `(kind, number)` keys, cursor progression/exhaustion, issue/PR relationships, and a final roster/metadata refresh. Failure, missing permissions, malformed responses, repeated cursors, count mismatch, or drift must produce incomplete/blocked evidence, never an empty complete queue. Every row needs one disposition, rationale, accountable role, action, reopening trigger, safe evidence pointer and explicit release-proposal flag. Record observation start/end and source identity. Avoid raw bodies/logs and use only sanitized allowlisted facts when needed.

Exercise the actual adapter/CLI return shape in temporary fixtures. If production uses a subprocess, the fixture must verify real subprocess stdout/status behavior as well as malformed/error shapes; do not fabricate a friendlier response shape. Do not perform queue writes. Suggested focused commands from research, to run only in the qualified isolated surface, are:

```sh
mix test test/crosswake/release_candidate test/mix/tasks/crosswake_release_candidate_test.exs test/mix/tasks/crosswake_release_status_test.exs
node --test test/js/phase167_pr_dispositions.test.mjs
python3 script/check_phase166_ownership_ledger.py --self-test
```

The first protects supported generic behavior and selected Mix modes; the latter two are analog self-checks only and do not prove MAINT-05. A Phase177 checker must validate the new current artifact and use fixtures with non-fixed identities and incomplete/drifting pages. Do not run these checks in the protected recovery checkout; source edits, Mix compilation, or fixtures require the qualified isolated surface.

### Active documentation, runbooks, generated projections

**Analogs:** `lib/mix/tasks/crosswake.docs.sync.ex`, `script/check_release_runbook_ancestry.sh`, `script/check_release_workflow_integrity.exs`

Edit canonical active guidance at its existing owner; keep frozen history semantically intact. `crosswake.docs.sync --check` renders each projection in memory, compares exact bytes, reports source/target drift and a remediation command (`lib/mix/tasks/crosswake.docs.sync.ex:38-72`). The default command invokes writers (`:21-36`), so any rendering belongs only in the isolated surface. If generated guide sources change, use:

```sh
mix crosswake.docs.sync --check
```

If the incident runbook changes, the ancestry guard takes exact runbook/target commit OIDs and path, checks both commits, verifies the runbook touched the declared path, and requires ancestry plus target-file presence (`script/check_release_runbook_ancestry.sh:5-57`). Its command form is:

```sh
script/check_release_runbook_ancestry.sh "$RUNBOOK_COMMIT" "$TARGET_COMMIT" docs/RELEASE-INCIDENT-RESPONSE.md
```

`script/check_release_workflow_integrity.exs` is the existing caller/workflow integrity owner. Research identifies `elixir script/check_release_workflow_integrity.exs` as its runnable invocation. Run relevant runbook/history and generated-doc tests only after identifying changed owners; these do not replace exact-source Phase178 verification.

### Workstream state and roadmap writing seam

The installed GSD-aware writer seam could not be located from this workspace or the visible Codex plugin/skill command paths during mapping. The current workstream `STATE.md` and `ROADMAP.md` are tracked planning artifacts, but this is not evidence that direct file editing is the permitted writer or that it preserves historical/runtime bytes. Before planning a write action, identify the registered workstream-aware GSD state/roadmap writer and its supported operation/byte-preservation contract. Do not recommend generic direct `Write`/`Edit` while that writer exists but is undiscovered. If no registered writer is available, keep that limitation explicit and do not invent an isolated source handoff. Existing runtime `state.json` is not a substitute for the Markdown handoff.

## Shared Patterns

- **Fail closed:** reject invalid modes/options before adapters or side effects; retain per-behavior denial tests.
- **Real adapter shapes:** preserve actual subprocess/API output, exit status and errors in temporary fixtures; never infer from a fabricated success object.
- **Current versus historical facts:** use Phase167 schema/failure style only; derive Phase177 roster identities at execution and record pagination and refresh evidence.
- **Privacy:** store only needed repository/run/source metadata and sanitized dispositions; omit credentials, raw adopter payloads, private recovery pointers and unnecessary issue bodies/logs.
- **Generated docs:** canonical source first; run the writer/check only in the qualified isolated source surface; check exact generated bytes.
- **Handoff:** maintain one exact active next action from the workstream-aware GSD writer/state. Phase177’s output does not close Phase178’s exact clean-source and hosted-CI gate.

## No Analog Found

| File / seam | Role | Data Flow | Reason |
|---|---|---|---|
| Qualified isolated source and patch handoff | delivery | file-I/O | Research says GSD isolation availability and binding are unverified; no repository or installed command implementation was found. Do not fabricate a worktree or staging/commit route. |
| Live Phase177 queue validator | utility | request-response + transform | Phase167 is fixed historical truth and Phase166 checks a local ownership ledger. Reuse their failure/fixture patterns, but create a bounded current artifact validator only if needed. |

## Metadata

**Tracked-source gate:** named source analogs were checked with `git ls-files`; ignored mirrors are not referenced.  
**Analog search scope:** release Mix routers and Plan93 module, Phase166/167 stdlib validators/tests, docs sync task, runbook/workflow guards, workstream state/roadmap.  
**Execution caveat:** no source change or test/compile/generation was performed; recovery checkout state is protected.  
**Exact next GSD action in current STATE/ROADMAP:** `$gsd-discuss-phase 177 --ws quality-ratchet-release` (the state header also says ready for planning; orchestrator should reconcile this discrepancy before handoff).
