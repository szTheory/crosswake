---
phase: 146-release-status-dx-docs-truth
verified: 2026-07-09T14:01:57Z
status: passed
score: 13/13 must-haves verified
behavior_unverified: 0
overrides_applied: 0
counts:
  truths_verified: 13
  truths_total: 13
  prohibitions_verified: 6
  artifacts_verified: 8
  key_links_verified: 4
  automated_checks_passed: 5
requirements:
  STAT-01: passed
  STAT-02: passed
  STAT-03: passed
gaps: []
human_verification: []
---

# Phase 146: Release Status DX & Docs Truth Verification Report

**Phase Goal:** Ship `mix crosswake.release.status`, JSON output, optional live probes, and reconcile stale release docs.
**Verified:** 2026-07-09T14:01:57Z
**Status:** passed
**Re-verification:** No - initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | STAT-01: maintainers can run one local command to inspect core/native lockstep, companion versions, compatibility floors, release-as pins, and workflow guard status. | VERIFIED | `mix crosswake.release.status` exits 0 and prints `status: ok`, `Core/native lockstep`, all five companions, mixed `requires_crosswake` floors, release-as pins, and check codes. Code path is `Mix.Tasks.Crosswake.Release.Status.run/1` -> `Crosswake.ReleaseStatus.build/1` at `lib/mix/tasks/crosswake.release.status.ex:34` and `lib/crosswake/release_status.ex:62`. |
| 2 | Local graph data is sourced from checked-in truth, not hardcoded output. | VERIFIED | `build/1` reads `.release-please-manifest.json`, `release-please-config.json`, `.github/workflows/release-please.yml`, package `mix.exs` files, Android Gradle config, and local git tags at `lib/crosswake/release_status.ex:66-76`, `153-210`, `728-755`. |
| 3 | Stale Phase 144/145 clean-room caveats are gone; completed evidence is reported directly. | VERIFIED | `release.cleanroom_dependency_floor` is scanner-backed and `ok`; stale guard passed: `! rg -n "Phase 146 owns full release-status DX|future status|[Nn][Oo][Tt] yet published|PREF validation remains" docs guides CHANGELOG.md README.md lib test`. |
| 4 | Release status uses `script/check_release_workflow_integrity.exs` stable IDs for workflow and clean-room evidence. | VERIFIED | `workflow_integrity_evidence/1` runs and parses the scanner at `lib/crosswake/release_status.ex:647-690`; scanner-backed checks cite evidence IDs at `241-260`, `273-299`, `549-616`. Scanner command passed with all referenced IDs OK. |
| 5 | Blocking local contradictions remain `error` checks. | VERIFIED | Lockstep, config drift, scanner failures, and release-as staleness map to `:error` via `check/6`, `scanner_check/7`, and `release_as_checks/1` at `lib/crosswake/release_status.ex:220-265`, `505-571`. Test covers unscoped scanner failure as blocking at `test/mix/tasks/crosswake_release_status_test.exs:45-73`. |
| 6 | STAT-02: `--json` emits parseable machine output suitable for automation. | VERIFIED | `mix crosswake.release.status --json | jq -e ...` passed. Task encodes the status map with `Jason.encode!/2` at `lib/mix/tasks/crosswake.release.status.ex:36-39`. |
| 7 | JSON has stable top-level fields. | VERIFIED | Test asserts exact keys `checks`, `companions`, `core`, `generated_at`, `live_checked`, `schema_version`, `status` at `test/mix/tasks/crosswake_release_status_test.exs:112-117`; live local output had `schema_version == "1.0.0"` and `status == "ok"`. |
| 8 | Component objects expose stable nouns and version/floor fields. | VERIFIED | Core/native maps include `kind`, `name`, `component`, `path`, `manifest_version`, `configured_version`, and `live` at `lib/crosswake/release_status.ex:153-184`; companion maps include `kind`, `name`, `package`, `path`, `manifest_version`, `configured_version`, `core_requirement`, `release_as`, `release_as_tag_exists`, and `live` at `187-210`. |
| 9 | Check objects expose stable automation fields and actionable next actions for non-OK states. | VERIFIED | Check constructors include `code`, `status`, `message`, `next_action`, `source`, and `evidence` at `lib/crosswake/release_status.ex:462-489`, `511-532`, `536-571`; tests enforce required fields and non-OK next actions at `test/mix/tasks/crosswake_release_status_test.exs:128-130`, `200-203`. |
| 10 | Aggregate status and exit behavior are deterministic: `error > warning > ok`, ok/warning exit 0, error/invalid options non-zero. | VERIFIED | `aggregate_status/1` and `exit_code/1` are at `lib/crosswake/release_status.ex:618-628`; tests cover precedence and invalid args at `test/mix/tasks/crosswake_release_status_test.exs:146-160`; `mix crosswake.release.status --bogus` exited 1. |
| 11 | STAT-03: live probes are optional and default mode is local-only. | VERIFIED | Default output showed `live checks: disabled`; local JSON had `live_checked: false` and all component `live` fields `null`. `maybe_*_live(..., false, ...)` returns `nil` at `lib/crosswake/release_status.ex:757`, `772`, `789`. |
| 12 | `--live` distinguishes `ok`, `missing`, and `unavailable` for Hex, Maven, and iOS SwiftPM without making warnings fatal. | VERIFIED | Injected live test covers `ok`, `missing`, and `unavailable` at `test/mix/tasks/crosswake_release_status_test.exs:163-204`. Actual `mix crosswake.release.status --json --live` exited 0 with `status: warning`, Hex/Maven OK where present, and missing iOS/rulestead/rindle reported as advisory live evidence. |
| 13 | Release docs are reconciled and preserve Crosswake's Phoenix-first explicit-boundary thesis. | VERIFIED | Runbook documents current read-only status, JSON, live mode, and mutation boundaries at `docs/COMPANION-PUBLISH-RUNBOOK.md:129-153`; compatibility guide keeps floor authority separate from registry presence at `guides/companion_compatibility.md:13-33`, `66-75`; support matrix states SwiftPM backfill is registry evidence, not device/emulator proof at `guides/support_matrix.md:69`; README adds a maintainer entry point at `README.md:109-118`; changelog avoids overclaiming rindle/rulestead live registry presence at `CHANGELOG.md:14-18`. |

**Score:** 13/13 truths verified (0 present-but-behavior-unverified)

### Prohibitions

| Prohibition | Status | Evidence |
|---|---|---|
| Default local status performs no GitHub API calls or workflow artifact downloads. | VERIFIED | Default path reads repository files and runs scanner; no `gh`, GitHub API, artifact download, or workflow artifact input appears in `lib/crosswake/release_status.ex` / task code. |
| Status never publishes, pushes, backfills, deletes, moves tags, opens PRs, or opens issues. | VERIFIED | Source command scan found only scanner, `git tag --list`, `git ls-remote --tags`, and bounded `curl`; no mutation commands in task path. |
| User-facing text/JSON does not expose GSD requirement IDs. | VERIFIED | Output tests reject `PREF-01`, `MIRR-01`, and `STAT-01`; rendered text and encoded JSON do not contain them. |
| JSON consumers can branch on structure rather than message prose. | VERIFIED | JSON exposes `status`, check `code`, `source`, `next_action`, and evidence fields; tests assert those fields. |
| Live warnings are not fatal by default. | VERIFIED | Actual live run returned aggregate `warning` and exit 0; `exit_code(:warning) == 0` is tested. |
| Status probes do not infer SwiftPM success from mirror `main` and never push. | VERIFIED | iOS live probe checks `refs/tags/v#{version}` via `git ls-remote --tags`; backfill action is only a `next_action` string. |

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `lib/crosswake/release_status.ex` | Scanner-backed local model, JSON map shape, live probe taxonomy | VERIFIED | 920 lines; substantive; plan artifact checks passed; wired by Mix task and tests. |
| `lib/mix/tasks/crosswake.release.status.ex` | Public Mix task, strict args, JSON/text output, exit behavior | VERIFIED | 49 lines; calls `Crosswake.ReleaseStatus.build/1`, `render/1`, `Jason.encode!/2`, and `exit_code/1`. |
| `test/mix/tasks/crosswake_release_status_test.exs` | Focused STAT-01/02/03 tests | VERIFIED | 232 lines; 7 tests passed locally. |
| `docs/COMPANION-PUBLISH-RUNBOOK.md` | Current release-status operator docs | VERIFIED | Documents command, `--json`, `--live`, advisory live semantics, and no-mutation boundary. |
| `guides/companion_compatibility.md` | Floor authority with registry-presence boundary | VERIFIED | Keeps mixed `~> 0.1` / `~> 0.2` floors and points registry truth to `--live`. |
| `guides/support_matrix.md` | Native registry evidence boundary | VERIFIED | States SwiftPM mirror backfill is registry evidence only, not device/emulator proof. |
| `CHANGELOG.md` | Current package-family truth | VERIFIED | Lists live Hex packages and local graph entries without overclaiming rindle/rulestead registry presence. |
| `README.md` | Maintainer release-status entry point | VERIFIED | Links the runbook and names `mix crosswake.release.status [--json] [--live]`. |

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| `lib/crosswake/release_status.ex` | `script/check_release_workflow_integrity.exs` | Scanner execution and stable evidence IDs | VERIFIED | Automated key-link check passed; source lines `647-690`; scanner command passed. |
| `lib/mix/tasks/crosswake.release.status.ex` | `lib/crosswake/release_status.ex` | `Crosswake.ReleaseStatus.build/1`, `render/1`, `exit_code/1`, `Jason.encode!/2` | VERIFIED | Manual verification at task lines `34-45`; automated checker missed the Elixir module link because it expects file-path text. |
| `README.md` | `docs/COMPANION-PUBLISH-RUNBOOK.md` | Maintainer release-status link | VERIFIED | README line `118`. |
| `guides/companion_compatibility.md` | `mix crosswake.release.status --live` | Status owns registry presence; guide owns floors | VERIFIED | Guide lines `30-33`, `66-75`. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|---|---|---|---|---|
| `Crosswake.ReleaseStatus.build/1` | `core`, `companions`, `checks` | Manifest/config/workflow/package files, local git tags, scanner output | Yes | VERIFIED |
| `Mix.Tasks.Crosswake.Release.Status.run/1` | `status` | `Crosswake.ReleaseStatus.build/1` | Yes | VERIFIED |
| JSON output | Encoded status map | `Jason.encode!(status, pretty: true)` | Yes | VERIFIED |
| Text output | Rendered status map | `Crosswake.ReleaseStatus.render(status)` | Yes | VERIFIED |
| Live registry state | `component.live` | Optional Hex/Maven/iOS probes only when `--live` | Yes, advisory | VERIFIED |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Focused release-status tests | `mix test test/mix/tasks/crosswake_release_status_test.exs` | 7 tests, 0 failures | PASS |
| Release workflow scanner | `elixir script/check_release_workflow_integrity.exs` | Exit 0; all scanner IDs OK | PASS |
| JSON parseability | `mix crosswake.release.status --json \| jq -e ...` | Exit 0; schema/status/check arrays valid | PASS |
| Final release proof set | `mix test test/mix/tasks/crosswake_release_status_test.exs test/crosswake/proof/phase142_release_integrity_test.exs test/crosswake/proof/phase145_ios_backfill_script_test.exs` | 69 tests, 0 failures | PASS |
| Stale-doc guard | `! rg -n "Phase 146 owns full release-status DX\|future status\|[Nn][Oo][Tt] yet published\|PREF validation remains" docs guides CHANGELOG.md README.md lib test` | No matches | PASS |
| Live advisory probe | `mix crosswake.release.status --json --live \| jq ...` | Exit 0; aggregate `warning`; OK/missing live states reported as advisory | PASS |
| Invalid option behavior | `mix crosswake.release.status --bogus` | Exit 1 with `invalid options` | PASS |

### Probe Execution

| Probe | Command | Result | Status |
|---|---|---|---|
| Conventional probe scripts | `find script -path '*/tests/probe-*.sh' -type f` | No probe scripts found | SKIPPED |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|---|---|---|---|---|
| STAT-01 | 146-01, 146-03 | Maintainers can run one local command to inspect core/native lockstep, companion versions, compatibility floors, release-as pins, and workflow guard status. | SATISFIED | Text command output `status: ok`; scanner-backed checks; release-as and mixed floors shown; focused tests passed. |
| STAT-02 | 146-02 | Release status command has JSON output suitable for CI or issue-opening automation. | SATISFIED | JSON parses through `jq`; stable schema fields/check codes; no GSD IDs; exit behavior tested. |
| STAT-03 | 146-03 | Release status can optionally probe live public registries without making live network checks mandatory for normal CI. | SATISFIED | Default is local-only; injected tests cover `ok`, `missing`, `unavailable`; actual live run returned advisory warning and exit 0. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---|---|---|---|
| `CHANGELOG.md` | 73 | `placeholder orgs` | INFO | Historical note about a parity guard; not a stub/debt marker. |
| `guides/support_matrix.md` | 204 | `not available yet` | INFO | Existing proof-copy phrase for media evidence; not Phase 146 incompleteness. |
| `test/mix/tasks/crosswake_release_status_test.exs` | 11 | `STAT-01` etc. | INFO | Test fixture blocks public GSD IDs from output; not user-facing output. |

No `TBD`, `FIXME`, or `XXX` markers were found in Phase 146 modified/source artifacts.

### Human Verification Required

None. The phase is CLI/docs/testable, and behavior-dependent assertions have automated coverage or direct command evidence.

### Deferred Items

None. Phase 146 is the final v18 phase; `roadmap.analyze` reports no next phase.

### Gaps Summary

No blocking gaps found. STAT-01, STAT-02, and STAT-03 are satisfied in code, tests, command behavior, and public docs while preserving Crosswake's Phoenix-first, explicit-runtime-ownership boundaries.

---

_Verified: 2026-07-09T14:01:57Z_
_Verifier: the agent (gsd-verifier)_
