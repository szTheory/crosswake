# Phase 146: Release Status DX & Docs Truth - Research

**Researched:** 2026-07-08  
**Domain:** Elixir Mix task release-ops DX, JSON contract, optional registry probes, and docs truth  
**Confidence:** HIGH for repo-local findings; LOW for external docs fetched through web fallback per confidence seam

## User Constraints (from CONTEXT.md)

### Locked Decisions [VERIFIED: .planning/phases/146-release-status-dx-docs-truth/146-CONTEXT.md]

#### Completed Evidence Truth
- **D-01:** Treat Phase 146 as a completion and truth-reconciliation pass over existing release-status spillover, not a greenfield command. The task already exists in `lib/mix/tasks/crosswake.release.status.ex` and `lib/crosswake/release_status.ex`; planning should harden that surface.
- **D-02:** Remove phase-era user-facing wording such as "PREF validation remains Phase 144." Phase 144 verification passed on 2026-07-08, and Phase 145 verification passed on 2026-07-08. Status must report the current evidence directly.
- **D-03:** The clean-room evidence check should become a direct local evidence check. If Phase 144 scanner/script evidence is present, report `ok`; if it is missing or stale, report an actionable `error` naming the missing evidence and next command, not a planning-phase caveat.
- **D-04:** The Phase 145 `native-release-status` artifact remains CI release evidence. The default local command must not require GitHub API access or artifact downloads. If artifact consumption is useful, add only an explicit file-based input such as `--native-status PATH`, or leave artifact consumption to future automation.
- **D-05:** Keep source authority separated: `mix crosswake.release.status` is the authority for local release graph and optional registry presence; `guides/companion_compatibility.md` is the authority for companion compatibility floors; recovery scripts/workflows are the authority for mutation and backfill.
- **D-06:** `mix crosswake.release.status` must never publish, push, backfill, delete, move tags, or open release PRs. It may point to the next safe command or workflow.

#### JSON Contract Shape
- **D-07:** Keep one public Mix task with `--json` rather than a separate JSON-only task. This matches Elixir CLI expectations and prevents text/JSON drift.
- **D-08:** Treat `--json` as an automation API. It must emit parseable JSON only from the task path; no banners, prose, ANSI labels, or trailing explanatory text in JSON mode.
- **D-09:** Lock top-level JSON fields for Phase 146: `schema_version`, `generated_at`, `status`, `live_checked`, `core`, `companions`, and `checks`.
- **D-10:** Use additive JSON compatibility. New optional fields may be added under the same `schema_version`, but deleting or renaming stable fields or changing enum meaning requires a schema major bump.
- **D-11:** Normalize component objects around explicit nouns: `kind` (`core`, `native`, `companion`, `observer`), `name` or `component`, `package` when applicable, `path`, `manifest_version`, `configured_version`, `core_requirement` when applicable, `release_as`, `release_as_tag_exists`, and `live`.
- **D-12:** Lock check objects around stable machine fields: `code`, `status` (`ok`, `warning`, `error`), `message`, `next_action`, `source`, and optionally `evidence` for file/check references. Stable `code` values are the primary automation key.
- **D-13:** Do not expose GSD requirement IDs such as `PREF-01`, `MIRR-01`, or `STAT-01` as user-facing completion claims. If internal requirement mapping is useful, keep it out of the default text output and do not make issue automation parse planning prose.
- **D-14:** JSON consumers should not scrape human `message` prose. Automation should branch on `status`, `code`, and structured fields.

#### Live Probe Semantics
- **D-15:** Default status remains local-only and deterministic. `--live` is the only path that checks public registries.
- **D-16:** Live probes must distinguish `ok`, `missing`, and `unavailable`. `missing` means the exact artifact/ref was checked and absent. `unavailable` means network, timeout, 5xx, tool missing, or registry access failure prevented a truthful absence claim.
- **D-17:** Live registry misses and unavailable probes should be `warning` by default, not `error`, because STAT-03 says live checks are optional and normal CI must not depend on live network state.
- **D-18:** Blocking local contradictions remain `error`: core/native lockstep drift, configured version drift, stale `release-as` pins that point at existing release tags, missing required source files, or scanner evidence that proves release workflow guard drift.
- **D-19:** Hex probes should check the exact release endpoint for each package/version and, when available, validate exact version identity and non-retired usable release state. The companion `requirements.crosswake.requirement` from Hex metadata is useful live evidence but should not replace local source-floor drift guards.
- **D-20:** Maven probes should check the exact Android core POM URL for the manifest version. Maven Central immutability makes exact-coordinate presence meaningful.
- **D-21:** SwiftPM/iOS probes should check `refs/tags/v${version}` on `szTheory/crosswake-shell-core-ios` with bounded `git ls-remote --tags`. The probe must not push or infer success from mirror `main`.
- **D-22:** Live probes need bounded timeouts and concise failure reporting. Raw registry payloads, stack traces, token mechanics, and long curl/git logs do not belong in normal text output.

#### Exit Behavior And Automation
- **D-23:** Aggregate status precedence is `error > warning > ok`.
- **D-24:** The task should exit 0 for `ok` and `warning`. It should exit non-zero for `error` and invalid invocation. This keeps optional live warnings visible without breaking normal CI.
- **D-25:** If a stricter scheduled workflow or issue-opening path is added, prefer an explicit strict option such as `--fail-on-warning`; do not make `--live` warnings fatal by default.
- **D-26:** If issue-opening automation is added in this phase, it must dedupe on a stable key such as `release-status:{version}:{check.code}`, use least privilege (`contents: read`, `issues: write`), upload the JSON artifact with `if-no-files-found: error`, and write a GitHub job summary. It is not required by STAT-02 if JSON is clearly suitable for such automation.
- **D-27:** The status task should not duplicate release workflow scanner logic. Reuse `script/check_release_workflow_integrity.exs` output or the same stable scanner IDs where practical so source policy does not split between two brittle parsers.

#### Operator UX And Docs Truth
- **D-28:** Text output should stay grouped by operator job-to-be-done: core/native lockstep, companions, checks, and live registry state when enabled.
- **D-29:** Every non-OK check in text and JSON should include a next action. The next action should be a command, workflow, or file to inspect, not a generic "investigate."
- **D-30:** Use Crosswake brand voice: calm, direct, short, specific, and actionable. Prefer "registry missing", "local graph drift", "release-as pin stale", and "next action" over vague success or failure language.
- **D-31:** Use exact labels consistently across docs and output: "configured version", "manifest version", "requires_crosswake", "live registry state", "native_core", "release-as pin", and "next action."
- **D-32:** Reconcile docs that currently describe Phase 146 as future work once the implementation lands. At minimum review `docs/COMPANION-PUBLISH-RUNBOOK.md`, `guides/companion_compatibility.md`, `guides/support_matrix.md`, `CHANGELOG.md`, and `README.md`.
- **D-33:** Keep release-status docs explicit that default status reads checked-in source/config/workflow files only. Public registry truth requires `--live`.
- **D-34:** Update stale docs to distinguish registry presence from compatibility floors. `mix crosswake.release.status --live` owns registry presence; `guides/companion_compatibility.md` owns floor semantics and must not normalize older-compatible companions upward just because registry status is being checked.
- **D-35:** Add focused docs/tests for the JSON schema and exit behavior. Do not rely on casual examples only; this command is an operator contract.

### the agent's Discretion [VERIFIED: .planning/phases/146-release-status-dx-docs-truth/146-CONTEXT.md]

Downstream agents may choose exact helper names, whether JSON schema documentation lives in the runbook or task moduledoc, and whether to add a strict automation flag. They should not revisit the local-first default, read-only command boundary, advisory `--live` posture, stable JSON fields, or stale Phase 144/145 wording removal unless official registry or Mix behavior contradicts these decisions.

### Deferred Ideas (OUT OF SCOPE) [VERIFIED: .planning/phases/146-release-status-dx-docs-truth/146-CONTEXT.md]

- A graphical release dashboard or Phoenix LiveDashboard panel remains DASH-01.
- Full automatic issue-opening can be deferred if Phase 146 locks JSON suitability and check-code stability; if implemented now, it must be deduped and least-privilege.
- Broad Maven Central recovery, SwiftPM mutation, Hex publish recovery, and iOS mirror backfill remain guarded workflow/script surfaces outside `mix crosswake.release.status`.
- New runtime capabilities, companion packages, offline-sync productization, native disk budgets, and commerce/native breadth remain deferred behind v18 release integrity.

## Summary

Phase 146 should harden an existing implementation, not invent a new command: `Crosswake.ReleaseStatus.build/1`, `Crosswake.ReleaseStatus.render/1`, and `Mix.Tasks.Crosswake.Release.Status.run/1` already exist, and the task already supports `--json` and `--live`. [VERIFIED: lib/crosswake/release_status.ex:23] [VERIFIED: lib/mix/tasks/crosswake.release.status.ex:21] The current spillover is not yet release-ready because the clean-room evidence heuristic is stale, focused tests fail, JSON check objects are not yet the locked machine contract, and live probes collapse unavailable registry checks into `missing`. [VERIFIED: mix crosswake.release.status --json output 2026-07-08] [VERIFIED: mix test test/mix/tasks/crosswake_release_status_test.exs output 2026-07-08]

The highest-leverage implementation path is three slices: first make local status truth direct and scanner-aligned; second lock JSON/schema/exit behavior and tests; third add live probe taxonomy and docs truth reconciliation. [VERIFIED: .planning/phases/146-release-status-dx-docs-truth/146-CONTEXT.md] The planner should keep this a read-only release-ops product surface, with mutation still owned by `script/verify_ios_mirror_backfill.sh`, `.github/workflows/ios-mirror-backfill.yml`, Release Please publish jobs, and Hex recovery workflows. [VERIFIED: script/verify_ios_mirror_backfill.sh:247] [VERIFIED: .github/workflows/ios-mirror-backfill.yml:79] [VERIFIED: docs/COMPANION-PUBLISH-RUNBOOK.md:57]

**Primary recommendation:** Replace brittle Phase 144/145 wording and heuristics with stable scanner-backed checks, preserve `ok|warning|error` exit semantics, implement `ok|missing|unavailable` live probe states, and reconcile release docs so status, compatibility floors, and mutation workflows each own one truth boundary. [VERIFIED: script/check_release_workflow_integrity.exs command output 2026-07-08] [VERIFIED: guides/companion_compatibility.md:30]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Local release graph inspection | Mix task / local CLI | Repository config | Reads `.release-please-manifest.json`, `release-please-config.json`, package `mix.exs`, Android Gradle config, and release workflow text without network by default. [VERIFIED: lib/crosswake/release_status.ex:28] |
| Workflow guard status | Release-integrity scanner | Mix task renderer | `script/check_release_workflow_integrity.exs` is already the semantic source for Phase 142-145 IDs; status should reuse or mirror those stable IDs instead of diverging. [VERIFIED: script/check_release_workflow_integrity.exs command output 2026-07-08] |
| JSON automation contract | Mix task / local CLI | CI consumers | `--json` must be parseable JSON only and keep stable fields/check codes for scripts and issue automation. [VERIFIED: .planning/phases/146-release-status-dx-docs-truth/146-CONTEXT.md] [CITED: https://doc.rust-lang.org/cargo/commands/cargo-metadata.html] |
| Optional registry presence | Mix task / bounded probes | Public registries | `--live` checks Hex exact release URLs, Maven exact POM URL, and SwiftPM mirror tag refs while staying advisory and read-only. [VERIFIED: lib/crosswake/release_status.ex:475] [VERIFIED: lib/crosswake/release_status.ex:482] [VERIFIED: lib/crosswake/release_status.ex:490] |
| Native backfill / mutation | Guarded scripts and workflows | Release Please CI | Status must point to `script/verify_ios_mirror_backfill.sh` or `.github/workflows/ios-mirror-backfill.yml`, never perform the mutation itself. [VERIFIED: script/verify_ios_mirror_backfill.sh:222] [VERIFIED: .github/workflows/ios-mirror-backfill.yml:79] |
| Companion compatibility floors | Documentation and package source | Status display | `guides/companion_compatibility.md` owns floor semantics; status may display `requires_crosswake` but must not normalize older-compatible floors upward. [VERIFIED: guides/companion_compatibility.md:13] |

## Project Constraints (from AGENTS.md)

- Preserve Crosswake as a Phoenix-first route-policy and runtime-contract system, not a universal UI framework. [VERIFIED: AGENTS.md:10]
- Keep runtime ownership explicit per route; do not collapse release/status surfaces into generic WebView wrapper behavior or LiveView-driven native rendering. [VERIFIED: AGENTS.md:11]
- Treat bridge contracts as semantic, typed, versioned, and low-frequency; continuous client authority belongs outside this phase. [VERIFIED: AGENTS.md:12]
- Keep offline claims honest; distinguish cached read-only behavior from local-first mutation. [VERIFIED: AGENTS.md:13]
- Treat diagnostics, support matrices, proof lanes, rough-edge docs, and release status as product surface. [VERIFIED: AGENTS.md:14]
- Respect v18 release-integrity scope and avoid integrations or native breadth outside `.planning/PROJECT.md` and `.planning/REQUIREMENTS.md`. [VERIFIED: AGENTS.md:15] [VERIFIED: .planning/REQUIREMENTS.md:83]

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| STAT-01 | Maintainers can run one local command to inspect core/native lockstep, companion versions, compatibility floors, release-as pins, and release workflow guard status. [VERIFIED: .planning/REQUIREMENTS.md:34] | Existing command reads manifest/config/workflow/package versions, but local clean-room truth currently false-errors and needs scanner-backed evidence plus next actions. [VERIFIED: lib/crosswake/release_status.ex:28] [VERIFIED: mix crosswake.release.status --json output 2026-07-08] |
| STAT-02 | The release status command has JSON output suitable for CI or issue-opening automation. [VERIFIED: .planning/REQUIREMENTS.md:35] | Current JSON is parseable but check/component objects lack locked `kind`, `source`, `next_action`, and `evidence` fields, and error behavior currently prevents the default local JSON command from succeeding. [VERIFIED: lib/crosswake/release_status.ex:37] [VERIFIED: lib/crosswake/release_status.ex:418] |
| STAT-03 | Release status can optionally probe live public registries without making live network checks mandatory for normal CI. [VERIFIED: .planning/REQUIREMENTS.md:36] | Current `--live` is optional and local default is deterministic, but probe functions return booleans and cannot distinguish `missing` from `unavailable`. [VERIFIED: lib/crosswake/release_status.ex:473] [VERIFIED: lib/crosswake/release_status.ex:504] |

## Current Implementation State

| Area | Current State | Gap To Plan |
|------|---------------|-------------|
| Public task | `mix crosswake.release.status`, `--json`, and `--live` exist. [VERIFIED: lib/mix/tasks/crosswake.release.status.ex:11] | Add stable JSON field coverage, invalid option tests, and exit behavior tests for `ok`, `warning`, and `error`. [VERIFIED: .planning/phases/146-release-status-dx-docs-truth/146-CONTEXT.md] |
| Local graph | Core/native manifest/config versions are read and compared; companion versions/floors/release-as pins are read. [VERIFIED: lib/crosswake/release_status.ex:95] [VERIFIED: lib/crosswake/release_status.ex:123] | Add explicit component `kind` values and ensure rindle/rulestead `release-as` pins remain warnings/OK unless the local tag exists. [VERIFIED: release-please-config.json:95] [VERIFIED: release-please-config.json:114] |
| Clean-room check | Current check says "PREF validation remains Phase 144" and now errors because the heuristic expects an old `PACKAGE_REQUIREMENT` fallback string. [VERIFIED: lib/crosswake/release_status.ex:173] [VERIFIED: script/check_release_workflow_integrity.exs:370] | Make the check direct: `ok` when scanner IDs such as `release.cleanroom.hex_metadata_floor`, `release.cleanroom.exact_companion_pin`, `release.cleanroom.lockfile_postcondition`, and `release.doctor.fresh_router_loaded` pass; `error` with next action when missing. [VERIFIED: elixir script/check_release_workflow_integrity.exs output 2026-07-08] |
| Governance checks | Status has local approximations for queue max, exact gates, cleanup-after-proof. [VERIFIED: lib/crosswake/release_status.ex:188] | Prefer reusing the scanner output/check IDs or a shared helper so release policy does not split across two fragile parsers. [VERIFIED: script/check_release_workflow_integrity.exs command output 2026-07-08] |
| Live probes | `--live` uses `curl --max-time 5` and `git ls-remote --tags`; false currently means `missing`. [VERIFIED: lib/crosswake/release_status.ex:504] [VERIFIED: lib/crosswake/release_status.ex:513] | Return structured `ok`, `missing`, `unavailable` with source/ref/url and next action; do not conflate tool absence, timeout, 5xx, or registry access failure with absence. [VERIFIED: .planning/phases/146-release-status-dx-docs-truth/146-CONTEXT.md] |
| Tests | Focused release-status test file currently has 2 failures because tests preserve stale warning copy while implementation now emits error. [VERIFIED: mix test test/mix/tasks/crosswake_release_status_test.exs output 2026-07-08] | Replace stale assertions with current evidence truth, JSON schema assertions, live taxonomy fixtures, and exit behavior assertions. [VERIFIED: test/mix/tasks/crosswake_release_status_test.exs:21] |
| Docs | Runbook and compatibility guide still frame Phase 146 as future; changelog says standalone companions are not yet published. [VERIFIED: docs/COMPANION-PUBLISH-RUNBOOK.md:152] [VERIFIED: guides/companion_compatibility.md:71] [VERIFIED: CHANGELOG.md:17] | Update docs after command hardening to state current status command behavior and live registry boundary; fix changelog companion publication truth. [VERIFIED: .planning/MILESTONES.md:7] |

## Stale Spots And Evidence Caveats

- `lib/crosswake/release_status.ex` reports "PREF validation remains Phase 144"; this is stale because Phase 144 verification passed on 2026-07-08. [VERIFIED: lib/crosswake/release_status.ex:177] [VERIFIED: .planning/phases/144-published-core-compatibility-clean-room-proof/144-VERIFICATION.md]
- `test/mix/tasks/crosswake_release_status_test.exs` explicitly asserts the stale Phase 144 wording and refutes the final clean-room wording; this should be inverted or replaced with scanner-backed evidence assertions. [VERIFIED: test/mix/tasks/crosswake_release_status_test.exs:25] [VERIFIED: test/mix/tasks/crosswake_release_status_test.exs:49]
- `docs/COMPANION-PUBLISH-RUNBOOK.md` and `guides/companion_compatibility.md` still describe Phase 146 as owning future status DX; after implementation lands they should document the current command and keep mutation/floor boundaries explicit. [VERIFIED: docs/COMPANION-PUBLISH-RUNBOOK.md:139] [VERIFIED: guides/companion_compatibility.md:66]
- `CHANGELOG.md` `[Unreleased]` is materially stale: it says standalone companion packages are not yet published, while `.planning/MILESTONES.md` records `crosswake_rulestead`, `crosswake_rindle`, `crosswake_sigra`, `crosswake_chimeway`, and `crosswake_threadline` as live Hex packages after v17.0. [VERIFIED: CHANGELOG.md:27] [VERIFIED: .planning/MILESTONES.md:7]
- Keep the `MIRROR_PUSH_TOKEN` scope caveat honest: Phase 145 is complete, but live apply-mode mirror mutation still needs the external token configured when a maintainer actually applies backfill. [VERIFIED: .planning/phases/145-native-registry-mirror-parity/145-VERIFICATION.md] [VERIFIED: script/verify_ios_mirror_backfill.sh:228]

## Standard Stack

### Core

| Library / Tool | Version | Purpose | Why Standard |
|----------------|---------|---------|--------------|
| Elixir / Mix | 1.19.5 local; project requires `~> 1.19` | Public Mix task, OptionParser, tests, file parsing | Existing project runtime and task system. [VERIFIED: elixir --version 2026-07-08] [VERIFIED: mix.exs:12] |
| Jason | `~> 1.4` | JSON encoding/decoding for status output and local manifest/config parsing | Existing dependency already used by the task; no new JSON dependency needed. [VERIFIED: mix.exs:48] [VERIFIED: lib/mix/tasks/crosswake.release.status.ex:38] |
| ExUnit + CaptureIO | Elixir stdlib with 1.19.5 | Focused CLI, JSON, exit behavior, and deterministic probe tests | Existing test style for Mix task output. [VERIFIED: test/mix/tasks/crosswake_release_status_test.exs:1] |
| git CLI | 2.41.0 local | Local tag checks and optional SwiftPM mirror ref probe | Existing implementation uses `git tag --list` and `git ls-remote --tags`. [VERIFIED: git --version 2026-07-08] [VERIFIED: lib/crosswake/release_status.ex:467] |
| curl CLI | 8.7.1 local | Optional Hex/Maven live probes | Existing implementation uses bounded `curl --max-time 5`. [VERIFIED: curl --version 2026-07-08] [VERIFIED: lib/crosswake/release_status.ex:514] |

### Supporting

| Library / Tool | Version | Purpose | When to Use |
|----------------|---------|---------|-------------|
| `script/check_release_workflow_integrity.exs` | Repo-local script | Stable release workflow proof IDs for Phases 142-145 | Use as the source for local governance and clean-room evidence checks. [VERIFIED: elixir script/check_release_workflow_integrity.exs output 2026-07-08] |
| jq | 1.7.1 local | Manual validation of JSON parseability | Use in verification commands and docs examples, not production code. [VERIFIED: jq --version 2026-07-08] |
| GitHub Actions summaries/artifacts | Hosted Actions feature | Human summary and machine artifact precedent for optional automation | Use only if a CI wrapper or issue-opening workflow is added. [CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-commands#adding-a-job-summary] [CITED: https://docs.github.com/en/actions/tutorials/store-and-share-data] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Existing Elixir scanner | YAML parser or actionlint | Deferred because scanner already encodes Crosswake-specific release policy and Phase 144 explicitly kept it authoritative. [VERIFIED: .planning/phases/144-published-core-compatibility-clean-room-proof/144-CONTEXT.md] |
| Jason | New JSON/schema package | Do not add dependency; stable map-shape tests and Jason are enough for this phase. [VERIFIED: mix.exs:48] |
| Boolean live probe result | Structured probe result tuples/maps | Use structured maps; booleans cannot represent `unavailable` without conflating with `missing`. [VERIFIED: lib/crosswake/release_status.ex:475] |
| GitHub API artifact download by default | Optional `--native-status PATH` | Default must stay local-only; artifact input is explicit if added. [VERIFIED: .planning/phases/146-release-status-dx-docs-truth/146-CONTEXT.md] |

**Installation:**

No new external packages should be installed for Phase 146. [VERIFIED: mix.exs:39]

## Package Legitimacy Audit

No new external package installation is recommended for this phase; the phase should use existing project dependencies and standard CLIs. [VERIFIED: mix.exs:39]

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| none | none | n/a | n/a | n/a | n/a | No install |

**Packages removed due to [SLOP] verdict:** none  
**Packages flagged as suspicious [SUS]:** none

## Architecture Patterns

### System Architecture Diagram

```text
Maintainer / CI
  |
  v
mix crosswake.release.status [--json] [--live]
  |
  +--> Local release graph reader
  |      +--> .release-please-manifest.json
  |      +--> release-please-config.json
  |      +--> root and package mix.exs
  |      +--> Android build.gradle.kts
  |
  +--> Local evidence reader
  |      +--> script/check_release_workflow_integrity.exs stable IDs
  |      +--> release-please.yml path gates, cleanup, native rollup
  |
  +--> Optional live probes when --live is set
  |      +--> Hex exact release endpoint
  |      +--> Maven exact Android POM
  |      +--> SwiftPM mirror refs/tags/vVERSION
  |
  +--> Aggregate status: error > warning > ok
         |
         +--> Text renderer: human next actions
         +--> JSON renderer: stable fields, no prose scraping
```

Diagram facts are derived from the existing `ReleaseStatus.build/1` data flow and Phase 146 locked decisions. [VERIFIED: lib/crosswake/release_status.ex:23] [VERIFIED: .planning/phases/146-release-status-dx-docs-truth/146-CONTEXT.md]

### Recommended Project Structure

```text
lib/
  crosswake/
    release_status.ex              # status data model, local checks, live probes, text rendering
  mix/tasks/
    crosswake.release.status.ex    # public Mix task, option parsing, exit behavior
test/
  mix/tasks/
    crosswake_release_status_test.exs
docs/
  COMPANION-PUBLISH-RUNBOOK.md     # maintainer command and mutation boundary
guides/
  companion_compatibility.md       # floor authority, link to status for registry presence
  support_matrix.md                # proof labels and native evidence boundary
```

Structure follows existing file ownership; no new module tree is required unless helper extraction reduces duplication. [VERIFIED: rg --hidden --files inspection 2026-07-08]

### Pattern 1: Scanner-Backed Status Checks

**What:** Build status checks from stable scanner IDs or shared scanner helper output, not from a second set of ad hoc string predicates. [VERIFIED: script/check_release_workflow_integrity.exs command output 2026-07-08]

**When to use:** Use for Phase 142-145 release policy, clean-room exactness, doctor fresh-router evidence, native proof decoupling, mirror preflight, native rollup, and companion floor honesty. [VERIFIED: script/check_release_workflow_integrity.exs:360] [VERIFIED: script/check_release_workflow_integrity.exs:806]

**Example:**

```elixir
# Source: script/check_release_workflow_integrity.exs stable IDs.
%{
  code: "release.cleanroom_dependency_floor",
  status: :ok,
  message: "clean-room proof uses Hex metadata floors and exact companion pins",
  next_action: nil,
  source: "script/check_release_workflow_integrity.exs",
  evidence: [
    "release.cleanroom.hex_metadata_floor",
    "release.cleanroom.exact_companion_pin",
    "release.cleanroom.lockfile_postcondition",
    "release.doctor.fresh_router_loaded"
  ]
}
```

### Pattern 2: Stable JSON With Additive Compatibility

**What:** Keep `schema_version`, stable top-level fields, stable check codes, and explicit check/component fields; add optional fields rather than rename or delete. [VERIFIED: .planning/phases/146-release-status-dx-docs-truth/146-CONTEXT.md]

**When to use:** Use for all `--json` output and tests. [VERIFIED: lib/mix/tasks/crosswake.release.status.ex:37]

**Example:**

```elixir
# Source: Phase 146 CONTEXT D-09 through D-14 and Cargo metadata compatibility precedent.
%{
  schema_version: "1.0.0",
  generated_at: DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601(),
  status: :warning,
  live_checked: false,
  core: core_components,
  companions: companion_components,
  checks: checks
}
```

Cargo documents a machine-readable JSON metadata command where the output format is versioned and adding fields or enum-like values is compatible within the same format version. [CITED: https://doc.rust-lang.org/cargo/commands/cargo-metadata.html]

### Pattern 3: Read-Only Live Probe Results

**What:** Model live probe outcomes as structured data with `status`, `source`, `checked`, `url` or `ref`, and `next_action`; never treat a probe failure as mutation authority. [VERIFIED: .planning/phases/146-release-status-dx-docs-truth/146-CONTEXT.md]

**When to use:** Use only under `--live`. [VERIFIED: lib/mix/tasks/crosswake.release.status.ex:15]

**Example:**

```elixir
# Source: Phase 146 live probe taxonomy.
%{
  source: "ios_mirror",
  status: :unavailable,
  checked: false,
  ref: "refs/tags/v0.2.0",
  next_action: "Retry with network access or run script/verify_ios_mirror_backfill.sh --version 0.2.0 --ref refs/tags/ios-core-v0.2.0"
}
```

### Anti-Patterns to Avoid

- **Stale phase caveats:** Do not print "Phase 144 remains" or "Phase 145 owns" as current user-facing status after those phases are verified. [VERIFIED: .planning/phases/144-published-core-compatibility-clean-room-proof/144-VERIFICATION.md] [VERIFIED: .planning/phases/145-native-registry-mirror-parity/145-VERIFICATION.md]
- **Boolean live probes:** Do not encode registry absence and registry unavailability as the same false value. [VERIFIED: lib/crosswake/release_status.ex:475]
- **Message scraping:** Do not make consumers parse `message`; automation keys are `status`, `code`, and structured fields. [VERIFIED: .planning/phases/146-release-status-dx-docs-truth/146-CONTEXT.md]
- **Mutation in status:** Do not push SwiftPM tags, open PRs, publish Hex, or invoke backfill from the status task. [VERIFIED: script/verify_ios_mirror_backfill.sh:222] [VERIFIED: docs/COMPANION-PUBLISH-RUNBOOK.md:57]
- **Floor normalization:** Do not change `rulestead`/`rindle` `~> 0.1` floors because registry status is being displayed. [VERIFIED: packages/crosswake_rulestead/mix.exs:66] [VERIFIED: packages/crosswake_rindle/mix.exs:81]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| JSON encode/decode | Custom string JSON | Jason | Existing dependency already supports task output and manifest parsing. [VERIFIED: mix.exs:48] |
| Release workflow semantic checks | New parser in `ReleaseStatus` | Existing scanner IDs | The scanner already proves Phase 142-145 invariants and is fixture-backed. [VERIFIED: script/check_release_workflow_integrity.exs command output 2026-07-08] |
| Compatibility floor truth | Status-owned floor policy | Package `mix.exs` plus `guides/companion_compatibility.md` | The guide is documented as floor authority and drift-tested against package source. [VERIFIED: guides/companion_compatibility.md:13] |
| SwiftPM mirror recovery | Mix task mutation | `script/verify_ios_mirror_backfill.sh` and workflow wrapper | Recovery is verify-first and apply-gated with token checks. [VERIFIED: script/verify_ios_mirror_backfill.sh:247] |
| Issue-opening automation state | Prose matching | Stable JSON `code` and dedupe key | Phase 146 context requires stable machine fields and dedupe if issue automation is added. [VERIFIED: .planning/phases/146-release-status-dx-docs-truth/146-CONTEXT.md] |

**Key insight:** Phase 146 is about joining existing proof and docs truth into one read-only operator surface, not inventing new release authority. [VERIFIED: .planning/MILESTONE-ARC.md]

## JSON Contract And Exit Behavior

### Required Top-Level Fields

`schema_version`, `generated_at`, `status`, `live_checked`, `core`, `companions`, and `checks` are locked for Phase 146. [VERIFIED: .planning/phases/146-release-status-dx-docs-truth/146-CONTEXT.md]

### Component Fields

Core/native component objects should include `kind`, `component` or `name`, `path`, `manifest_version`, `configured_version`, and `live`. Companion/observer objects should include `kind`, `package`, `path`, `version`, `configured_version`, `core_requirement`, `release_as`, `release_as_tag_exists`, and `live`. [VERIFIED: .planning/phases/146-release-status-dx-docs-truth/146-CONTEXT.md] Threadline should be `observer`, not `companion`, because it is not registered in `:companions`. [VERIFIED: guides/companion_compatibility.md:37]

### Check Fields

Every check object should include `code`, `status`, `message`, `next_action`, and `source`; include `evidence` when a check is backed by scanner IDs or files. [VERIFIED: .planning/phases/146-release-status-dx-docs-truth/146-CONTEXT.md]

### Exit Behavior

The task should exit 0 for aggregate `ok` and `warning`, and non-zero for aggregate `error` or invalid invocation. [VERIFIED: .planning/phases/146-release-status-dx-docs-truth/146-CONTEXT.md] The current implementation raises only when `status.status == :error`, which matches the locked policy, but the current stale clean-room error makes the local default fail today. [VERIFIED: lib/mix/tasks/crosswake.release.status.ex:45] [VERIFIED: mix crosswake.release.status --json output 2026-07-08]

### Risks

- `Mix.shell().info(output)` appends a newline, but JSON remains parseable in the current test; keep tests asserting `Jason.decode!/1` on captured output. [VERIFIED: test/mix/tasks/crosswake_release_status_test.exs:60]
- Invalid options currently use `OptionParser.parse/2` and `Mix.raise/1`; add focused test coverage for non-zero invalid invocation. [VERIFIED: lib/mix/tasks/crosswake.release.status.ex:22] [CITED: https://hexdocs.pm/elixir/OptionParser.html]
- If `--fail-on-warning` is added, keep it explicit and separate from `--live`; default live warnings must not break normal CI. [VERIFIED: .planning/phases/146-release-status-dx-docs-truth/146-CONTEXT.md]

## Live Probe Behavior

| Registry | Exact Probe | `ok` | `missing` | `unavailable` |
|----------|-------------|------|-----------|---------------|
| Hex | `https://hex.pm/api/packages/{package}/releases/{version}` | HTTP 200, exact version identity, non-retired usable release when payload parsed. [VERIFIED: script/verify_companion_cleanroom.sh:159] [CITED: https://raw.githubusercontent.com/hexpm/specifications/main/apiary.apib] | HTTP 404 from exact release endpoint. [CITED: https://raw.githubusercontent.com/hexpm/specifications/main/apiary.apib] | curl missing, timeout, 5xx, 401/403, malformed payload, or network failure. [VERIFIED: .planning/phases/146-release-status-dx-docs-truth/146-CONTEXT.md] |
| Maven Central | Exact Android POM URL | HTTP 200 for `crosswake-shell-core-android-{version}.pom`. [VERIFIED: lib/crosswake/release_status.ex:490] | HTTP 404 for exact POM. [VERIFIED: lib/crosswake/release_status.ex:490] | curl missing, timeout, 5xx, or network failure. [VERIFIED: .planning/phases/146-release-status-dx-docs-truth/146-CONTEXT.md] |
| SwiftPM mirror | `git ls-remote --tags https://github.com/szTheory/crosswake-shell-core-ios.git refs/tags/v{version}` | Matching tag ref is present. [VERIFIED: lib/crosswake/release_status.ex:482] | `git ls-remote` succeeds and exact tag is absent. [VERIFIED: .planning/phases/146-release-status-dx-docs-truth/146-CONTEXT.md] | git missing, timeout, auth/access failure, DNS/network failure, or remote error. [VERIFIED: .planning/phases/146-release-status-dx-docs-truth/146-CONTEXT.md] |

Default local mode must set `live_checked: false` and avoid network calls. [VERIFIED: lib/crosswake/release_status.ex:26]

## Docs Truth Boundaries

| Truth Boundary | Owner | Phase 146 Update |
|----------------|-------|------------------|
| Local release graph, workflow guard status, release-as staleness, optional live presence | `mix crosswake.release.status` | Document text and JSON examples after command hardening. [VERIFIED: lib/mix/tasks/crosswake.release.status.ex:6] |
| Companion compatibility floors | `guides/companion_compatibility.md` and package `mix.exs` | Keep floor matrix authoritative and add/retain pointer to `--live` for public registry presence. [VERIFIED: guides/companion_compatibility.md:13] |
| iOS mirror verify/apply mutation | `script/verify_ios_mirror_backfill.sh` and `.github/workflows/ios-mirror-backfill.yml` | Status can point to these commands but must not invoke them. [VERIFIED: script/verify_ios_mirror_backfill.sh:222] |
| Native release CI artifact | `native-release-rollup` artifact | Do not require artifact download by default; optional `--native-status PATH` can be a future/manual explicit input. [VERIFIED: .github/workflows/release-please.yml:593] |
| Support labels and native proof | `guides/support_matrix.md` | Preserve distinction between registry evidence, generated-shell proof, simulator/emulator proof, and device proof. [VERIFIED: guides/support_matrix.md:12] |
| Published package history | `CHANGELOG.md` | Fix stale companion-publication statements in `[Unreleased]` before claiming docs truth. [VERIFIED: CHANGELOG.md:17] [VERIFIED: .planning/MILESTONES.md:7] |

## Recommended Plan Slicing

### Slice 1: Local Status Truth And Scanner Evidence

Files: `lib/crosswake/release_status.ex`, `test/mix/tasks/crosswake_release_status_test.exs`. [VERIFIED: rg --hidden --files inspection 2026-07-08]

Work:
- Replace `cleanroom_script_hardened?/1` with scanner-backed or scanner-ID-backed evidence. [VERIFIED: lib/crosswake/release_status.ex:435]
- Remove "PREF validation remains Phase 144" from code and tests. [VERIFIED: lib/crosswake/release_status.ex:177]
- Ensure default local status exits 0 when scanner and local graph are clean. [VERIFIED: elixir script/check_release_workflow_integrity.exs output 2026-07-08]

### Slice 2: JSON Contract And Exit Behavior

Files: `lib/crosswake/release_status.ex`, `lib/mix/tasks/crosswake.release.status.ex`, `test/mix/tasks/crosswake_release_status_test.exs`, possibly task moduledoc. [VERIFIED: lib/mix/tasks/crosswake.release.status.ex:6]

Work:
- Add stable `kind`, `source`, `next_action`, and `evidence` fields. [VERIFIED: .planning/phases/146-release-status-dx-docs-truth/146-CONTEXT.md]
- Add JSON-only output tests that assert no banners/ANSI/trailing prose and no GSD requirement IDs. [VERIFIED: test/mix/tasks/crosswake_release_status_test.exs:84]
- Add exit behavior tests for ok/warning/error and invalid options. [VERIFIED: lib/mix/tasks/crosswake.release.status.ex:30]

### Slice 3: Live Taxonomy And Docs Truth

Files: `lib/crosswake/release_status.ex`, tests, `docs/COMPANION-PUBLISH-RUNBOOK.md`, `guides/companion_compatibility.md`, `guides/support_matrix.md`, `CHANGELOG.md`, maybe `README.md`. [VERIFIED: .planning/phases/146-release-status-dx-docs-truth/146-CONTEXT.md]

Work:
- Implement `ok|missing|unavailable` live probe result maps with deterministic injected probe tests. [VERIFIED: test/mix/tasks/crosswake_release_status_test.exs:89]
- Document default local-only status and `--live` registry presence. [VERIFIED: docs/COMPANION-PUBLISH-RUNBOOK.md:52]
- Update stale Phase 146 future wording and stale changelog companion publication truth. [VERIFIED: docs/COMPANION-PUBLISH-RUNBOOK.md:152] [VERIFIED: CHANGELOG.md:27]

## Common Pitfalls

### Pitfall 1: Stale Planning Caveats Become User-Facing Status

**What goes wrong:** The command keeps saying "PREF validation remains Phase 144" after Phase 144 is verified. [VERIFIED: lib/crosswake/release_status.ex:177]  
**Why it happens:** Spillover code encoded phase sequencing as runtime truth. [VERIFIED: .planning/STATE.md]  
**How to avoid:** Convert phase caveats into direct evidence checks sourced from scanner IDs and verification artifacts. [VERIFIED: script/check_release_workflow_integrity.exs command output 2026-07-08]  
**Warning signs:** Tests assert old phase wording or refute final evidence wording. [VERIFIED: test/mix/tasks/crosswake_release_status_test.exs:48]

### Pitfall 2: Optional Live Probes Break Normal CI

**What goes wrong:** `--live` registry warnings become fatal or default status performs network calls. [VERIFIED: .planning/phases/146-release-status-dx-docs-truth/146-CONTEXT.md]  
**Why it happens:** `missing` and `unavailable` are modeled as `error` or default mode runs probes. [VERIFIED: lib/crosswake/release_status.ex:473]  
**How to avoid:** Keep default local-only and make live outcomes warnings unless paired with local contradictions. [VERIFIED: .planning/REQUIREMENTS.md:36]  
**Warning signs:** Tests require network access or assert non-zero exit for live warning states. [VERIFIED: test/mix/tasks/crosswake_release_status_test.exs:89]

### Pitfall 3: JSON Looks Parseable But Is Not A Contract

**What goes wrong:** Scripts parse `message` text or rely on missing optional fields. [VERIFIED: .planning/phases/146-release-status-dx-docs-truth/146-CONTEXT.md]  
**Why it happens:** Current check objects only include `code`, `message`, and `status`. [VERIFIED: lib/crosswake/release_status.ex:418]  
**How to avoid:** Lock fields and assert schema shape in tests. [VERIFIED: .planning/phases/146-release-status-dx-docs-truth/146-CONTEXT.md]  
**Warning signs:** No test fails when a check loses `next_action` or `source`. [VERIFIED: test/mix/tasks/crosswake_release_status_test.exs:60]

### Pitfall 4: Registry Status Alters Compatibility Floors

**What goes wrong:** Docs or status imply all companions require `~> 0.2` because current live registry work centers on `0.2.0`. [VERIFIED: guides/companion_compatibility.md:48]  
**Why it happens:** Registry presence and compatibility floors get conflated. [VERIFIED: guides/companion_compatibility.md:30]  
**How to avoid:** Keep `guides/companion_compatibility.md` as floor authority and status as presence authority. [VERIFIED: .planning/phases/146-release-status-dx-docs-truth/146-CONTEXT.md]  
**Warning signs:** `rulestead` or `rindle` floors change without a package-source reason. [VERIFIED: packages/crosswake_rulestead/mix.exs:66] [VERIFIED: packages/crosswake_rindle/mix.exs:81]

## Code Examples

Verified patterns from official or repo-local sources:

### Mix Task Shape

```elixir
# Source: https://hexdocs.pm/mix/Mix.Task.html and current task file.
defmodule Mix.Tasks.Crosswake.Release.Status do
  use Mix.Task

  @shortdoc "Report Crosswake package-family release readiness"

  @impl Mix.Task
  def run(args) do
    # parse options, build status, render text or JSON, then exit non-zero only on errors
  end
end
```

Mix docs state public tasks use a `Mix.Tasks.*` module, `use Mix.Task`, and `run/1`; `@shortdoc` makes a task visible in `mix help`. [CITED: https://hexdocs.pm/mix/Mix.Task.html]

### Structured Check Shape

```elixir
# Source: Phase 146 CONTEXT D-12.
%{
  code: "release.live_registry_presence",
  status: :warning,
  message: "live registry checks unavailable for ios-core",
  next_action: "Retry with network access or inspect the registry manually.",
  source: "mix crosswake.release.status --live",
  evidence: [%{source: "ios_mirror", ref: "refs/tags/v0.2.0", status: :unavailable}]
}
```

### Live Probe Function Contract

```elixir
# Source: Phase 146 CONTEXT D-16 through D-22.
{:ok, %{status: :ok, source: "hex", url: url}}
{:ok, %{status: :missing, source: "hex", url: url}}
{:error, %{status: :unavailable, source: "hex", url: url, reason: :timeout}}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Phase-era caveats in status output | Direct evidence checks from completed scanner/verification artifacts | Phase 144/145 verified 2026-07-08 [VERIFIED: 144-VERIFICATION.md] [VERIFIED: 145-VERIFICATION.md] | Status should say what is true now, not what a prior phase still owns. |
| Boolean live probe results | `ok`, `missing`, `unavailable` taxonomy | Locked in Phase 146 context [VERIFIED: 146-CONTEXT.md] | Avoid false absence claims when network/tool/registry is unavailable. |
| Parseable JSON as enough | Stable JSON automation contract with schema version and check codes | Locked in Phase 146 context; Cargo metadata provides precedent [VERIFIED: 146-CONTEXT.md] [CITED: https://doc.rust-lang.org/cargo/commands/cargo-metadata.html] | CI and issue automation can branch on fields instead of prose. |
| Status docs as future work | Status command documented as current maintainer surface | Phase 146 implementation target [VERIFIED: .planning/ROADMAP.md:28] | Runbook/README can point maintainers at one command for read-only status. |

**Deprecated/outdated:**
- `PREF validation remains Phase 144` in release status code/tests is outdated. [VERIFIED: lib/crosswake/release_status.ex:177]
- `[Unreleased]` changelog claims that companion packages are not published are outdated relative to v17 milestone truth. [VERIFIED: CHANGELOG.md:27] [VERIFIED: .planning/MILESTONES.md:7]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Research validity window is estimated as 30 days for repo-local planning and 7 days for live-probe implementation details. [ASSUMED] | Metadata | Planner may need to re-check registry/docs behavior sooner if upstream registries or CLI behavior changes. |

## Open Questions

1. **Should Phase 146 add `--fail-on-warning` now?**  
   - What we know: Context allows a strict option but does not require it. [VERIFIED: .planning/phases/146-release-status-dx-docs-truth/146-CONTEXT.md]  
   - What's unclear: Whether any immediate CI wrapper needs warnings to fail. [VERIFIED: .planning/REQUIREMENTS.md:35]  
   - Recommendation: Defer unless a plan adds scheduled issue-opening automation; default `--live` warnings must stay exit 0. [VERIFIED: .planning/phases/146-release-status-dx-docs-truth/146-CONTEXT.md]
2. **Should `--native-status PATH` be added now?**  
   - What we know: Context permits an explicit file input but says default local command must not require GitHub API/artifact downloads. [VERIFIED: .planning/phases/146-release-status-dx-docs-truth/146-CONTEXT.md]  
   - What's unclear: Whether any current operator flow has a local artifact file to consume. [VERIFIED: .github/workflows/release-please.yml:593]  
   - Recommendation: Defer unless trivial; Phase 146 can satisfy STAT-01/02/03 without artifact consumption. [VERIFIED: .planning/REQUIREMENTS.md:34]
3. **Should README mention the release-status command?**  
   - What we know: README has a maintainer/contributor section but no release-status command today. [VERIFIED: README.md:109]  
   - What's unclear: Whether this maintainer-only surface belongs in public first-read docs or only in the runbook/task help. [VERIFIED: README.md:171]  
   - Recommendation: Add a concise maintainer bullet only if it does not distract from adopter-facing install/proof paths; otherwise document in runbook and task moduledoc. [VERIFIED: .planning/phases/146-release-status-dx-docs-truth/146-CONTEXT.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir | Mix task and ExUnit tests | yes | 1.19.5 | none needed [VERIFIED: elixir --version 2026-07-08] |
| Mix | Task invocation and tests | yes | 1.19.5 | none needed [VERIFIED: mix --version 2026-07-08] |
| git | Local tag checks and optional SwiftPM probes | yes | 2.41.0 | Disable `--live` SwiftPM probe if missing and report `unavailable`. [VERIFIED: git --version 2026-07-08] |
| curl | Optional Hex/Maven live probes | yes | 8.7.1 | Report `unavailable` for HTTP probes if missing. [VERIFIED: curl --version 2026-07-08] |
| jq | Manual JSON verification | yes | 1.7.1 | Use `Jason.decode!/1` in tests. [VERIFIED: jq --version 2026-07-08] |
| Java | Native Android proof, not Phase 146 local task | no usable runtime | `/usr/bin/java` stub reports no runtime | Not required for status command; native proof remains CI/advisory. [VERIFIED: java -version 2026-07-08] |
| splitsh-lite | iOS mirror backfill apply/verify split computation | no | not installed | Not required for local status; status should point to backfill script/workflow. [VERIFIED: command -v splitsh-lite 2026-07-08] |

**Missing dependencies with no fallback:** none for Phase 146 local implementation and focused tests. [VERIFIED: environment probes 2026-07-08]

**Missing dependencies with fallback:**
- Java: only needed for native Android proof outside this phase. [VERIFIED: packages/crosswake-shell-core-android/build.gradle.kts:49]
- splitsh-lite: only needed for iOS mirror backfill script apply/verification outside local status. [VERIFIED: script/verify_ios_mirror_backfill.sh:182]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit through Mix 1.19.5 [VERIFIED: mix --version 2026-07-08] |
| Config file | `mix.exs`; test paths include `lib` and `test/support`. [VERIFIED: mix.exs:36] |
| Quick run command | `mix test test/mix/tasks/crosswake_release_status_test.exs` |
| Full relevant release guard command | `elixir script/check_release_workflow_integrity.exs && mix test test/crosswake/proof/phase142_release_integrity_test.exs test/mix/tasks/crosswake_release_status_test.exs` |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| STAT-01 | Local command reports core/native lockstep, companion versions/floors, release-as pins, workflow guard status, and clean-room/native evidence without stale phase caveats. | unit + scanner integration | `mix test test/mix/tasks/crosswake_release_status_test.exs` and `elixir script/check_release_workflow_integrity.exs` | yes [VERIFIED: test/mix/tasks/crosswake_release_status_test.exs:13] |
| STAT-02 | `--json` emits parseable JSON only, with stable top-level fields, component fields, check fields, no GSD requirement IDs, and correct exit behavior. | unit | `mix test test/mix/tasks/crosswake_release_status_test.exs --only release_status_json` after tagging or full file | yes, needs expansion [VERIFIED: test/mix/tasks/crosswake_release_status_test.exs:60] |
| STAT-03 | `--live` is optional, advisory, deterministic in tests, and distinguishes `ok`, `missing`, `unavailable`. | unit with injected probes | `mix test test/mix/tasks/crosswake_release_status_test.exs` | yes, needs taxonomy expansion [VERIFIED: test/mix/tasks/crosswake_release_status_test.exs:89] |

### Sampling Rate

- **Per task commit:** `mix test test/mix/tasks/crosswake_release_status_test.exs`
- **Per wave merge:** `elixir script/check_release_workflow_integrity.exs && mix test test/crosswake/proof/phase142_release_integrity_test.exs test/mix/tasks/crosswake_release_status_test.exs`
- **Phase gate:** `mix test test/mix/tasks/crosswake_release_status_test.exs test/crosswake/proof/phase142_release_integrity_test.exs test/crosswake/proof/phase145_ios_backfill_script_test.exs` plus docs grep checks for stale Phase 146/future wording. [VERIFIED: .planning/phases/145-native-registry-mirror-parity/145-VERIFICATION.md]

### Current Baseline Results

- `elixir script/check_release_workflow_integrity.exs` passed and emitted all relevant Phase 142-145 IDs as OK. [VERIFIED: command output 2026-07-08]
- `mix crosswake.release.status --json` currently exits 1 because `release.cleanroom_dependency_floor` reports an error with stale Phase 144 wording. [VERIFIED: command output 2026-07-08]
- `mix test test/mix/tasks/crosswake_release_status_test.exs` currently has 2 failures in 4 tests, both tied to the clean-room warning/error mismatch and stale wording. [VERIFIED: command output 2026-07-08]

### Wave 0 Gaps

- [ ] Expand `test/mix/tasks/crosswake_release_status_test.exs` to assert the locked JSON schema fields and exit behavior. [VERIFIED: test/mix/tasks/crosswake_release_status_test.exs:60]
- [ ] Add injected live probe tests for `ok`, `missing`, and `unavailable` across Hex/Maven/iOS. [VERIFIED: lib/crosswake/release_status.ex:497]
- [ ] Add stale-doc guard or focused grep check for removed "Phase 146 owns full release-status DX" future wording after docs update. [VERIFIED: docs/COMPANION-PUBLISH-RUNBOOK.md:152]

## Security Domain

Security enforcement is enabled because `.planning/config.json` does not set `security_enforcement: false`. [VERIFIED: .planning/config.json]

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | no | No auth/session surface in status task. [VERIFIED: lib/mix/tasks/crosswake.release.status.ex:21] |
| V3 Session Management | no | No session state. [VERIFIED: lib/crosswake/release_status.ex:23] |
| V4 Access Control | yes, for mutation boundary | Status task remains read-only; mutation lives in guarded scripts/workflows. [VERIFIED: docs/COMPANION-PUBLISH-RUNBOOK.md:57] |
| V5 Input Validation | yes | Use strict OptionParser flags, semver/version parsing where applicable, allowlisted source paths, and no shell interpolation from user-controlled package names. [VERIFIED: lib/mix/tasks/crosswake.release.status.ex:22] |
| V6 Cryptography | no direct cryptography | Do not handle tokens or secrets in status; mirror token remains workflow/script env. [VERIFIED: .github/workflows/ios-mirror-backfill.yml:80] |

### Known Threat Patterns for Release Status

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| False absence claim from registry outage | Tampering / Reliability | Separate `missing` from `unavailable`; make live outcomes advisory warnings. [VERIFIED: .planning/phases/146-release-status-dx-docs-truth/146-CONTEXT.md] |
| Secret leakage from live probes | Information Disclosure | Do not use tokens in status; do not print raw registry payloads or token mechanics. [VERIFIED: .planning/phases/146-release-status-dx-docs-truth/146-CONTEXT.md] |
| Command injection through probe paths/package names | Elevation of Privilege | Keep package set derived from checked-in manifest/config and avoid shelling through unsanitized user input. [VERIFIED: lib/crosswake/release_status.ex:123] |
| Unauthorized mutation from status command | Tampering | No publish/push/delete/backfill/PR actions in Mix task. [VERIFIED: .planning/phases/146-release-status-dx-docs-truth/146-CONTEXT.md] |

## Sources

### Primary (HIGH confidence)

- `AGENTS.md` - project constraints and workflow. [VERIFIED: AGENTS.md]
- `.planning/PROJECT.md`, `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/STATE.md` - v18 scope and STAT requirements. [VERIFIED: local read]
- `.planning/phases/146-release-status-dx-docs-truth/146-CONTEXT.md` - locked Phase 146 decisions. [VERIFIED: local read]
- `.planning/phases/144-published-core-compatibility-clean-room-proof/144-VERIFICATION.md` - Phase 144 passed evidence. [VERIFIED: local read]
- `.planning/phases/145-native-registry-mirror-parity/145-VERIFICATION.md` - Phase 145 passed evidence. [VERIFIED: local read]
- `lib/crosswake/release_status.ex`, `lib/mix/tasks/crosswake.release.status.ex`, and `test/mix/tasks/crosswake_release_status_test.exs` - current implementation and failing focused test state. [VERIFIED: local read + command]
- `script/check_release_workflow_integrity.exs` - authoritative release scanner IDs. [VERIFIED: command output]

### Secondary (LOW per seam, official docs cited)

- https://hexdocs.pm/mix/Mix.Task.html - Mix task shape, `@shortdoc`, `run/1`, `@requirements`. [CITED: official docs]
- https://hexdocs.pm/elixir/OptionParser.html - strict boolean parsing and invalid option behavior. [CITED: official docs]
- https://doc.rust-lang.org/cargo/commands/cargo-metadata.html - versioned/additive JSON metadata precedent. [CITED: official docs]
- https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-commands#adding-a-job-summary - job summaries. [CITED: official docs]
- https://docs.github.com/en/actions/tutorials/store-and-share-data - workflow artifacts. [CITED: official docs]
- https://raw.githubusercontent.com/hexpm/specifications/main/apiary.apib - Hex exact release endpoint and error semantics. [CITED: official specification]
- https://central.sonatype.org/publish/requirements/immutability/ - Maven Central immutability. [CITED: official docs]
- https://docs.swift.org/swiftpm/documentation/packagemanagerdocs/releasingpublishingapackage/ - SwiftPM semantic tag release identity, retrieved through search snippet due JS docs rendering. [CITED: official docs/search result]

### Tertiary (LOW confidence)

- None used for planner-critical claims; non-official search results were not used as authoritative sources. [VERIFIED: research log]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - derived from `mix.exs`, local tool versions, and existing implementation. [VERIFIED: mix.exs] [VERIFIED: environment probes 2026-07-08]
- Architecture: HIGH - derived from phase context, implementation files, scanner, and verification artifacts. [VERIFIED: 146-CONTEXT.md] [VERIFIED: script/check_release_workflow_integrity.exs]
- Pitfalls: HIGH for local stale spots and failing tests; LOW for external docs precedent due webfetch confidence seam. [VERIFIED: command output 2026-07-08] [CITED: https://doc.rust-lang.org/cargo/commands/cargo-metadata.html]

**Research date:** 2026-07-08  
**Valid until:** 2026-08-07 for repo-local planning; re-check registry/docs behavior within 7 days if live-probe implementation changes. [ASSUMED]
