# Phase 146: Release Status DX & Docs Truth - Context

**Gathered:** 2026-07-08
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 146 owns the finished maintainer-facing release-status surface for the Crosswake package family. It should complete and validate the already-present `mix crosswake.release.status` implementation, make `--json` suitable for CI or issue-opening automation, keep live public registry probes optional, and reconcile stale release docs now that PREF and MIRR work from Phases 144 and 145 is complete.

This phase is release-ops product surface. It is not a dashboard, not new runtime or companion breadth, and not a publish or recovery command. Mutation remains in guarded scripts and workflows such as `script/verify_ios_mirror_backfill.sh`, `.github/workflows/ios-mirror-backfill.yml`, and the release workflow.

</domain>

<decisions>
## Implementation Decisions

### Completed Evidence Truth
- **D-01:** Treat Phase 146 as a completion and truth-reconciliation pass over existing release-status spillover, not a greenfield command. The task already exists in `lib/mix/tasks/crosswake.release.status.ex` and `lib/crosswake/release_status.ex`; planning should harden that surface.
- **D-02:** Remove phase-era user-facing wording such as "PREF validation remains Phase 144." Phase 144 verification passed on 2026-07-08, and Phase 145 verification passed on 2026-07-08. Status must report the current evidence directly.
- **D-03:** The clean-room evidence check should become a direct local evidence check. If Phase 144 scanner/script evidence is present, report `ok`; if it is missing or stale, report an actionable `error` naming the missing evidence and next command, not a planning-phase caveat.
- **D-04:** The Phase 145 `native-release-status` artifact remains CI release evidence. The default local command must not require GitHub API access or artifact downloads. If artifact consumption is useful, add only an explicit file-based input such as `--native-status PATH`, or leave artifact consumption to future automation.
- **D-05:** Keep source authority separated: `mix crosswake.release.status` is the authority for local release graph and optional registry presence; `guides/companion_compatibility.md` is the authority for companion compatibility floors; recovery scripts/workflows are the authority for mutation and backfill.
- **D-06:** `mix crosswake.release.status` must never publish, push, backfill, delete, move tags, or open release PRs. It may point to the next safe command or workflow.

### JSON Contract Shape
- **D-07:** Keep one public Mix task with `--json` rather than a separate JSON-only task. This matches Elixir CLI expectations and prevents text/JSON drift.
- **D-08:** Treat `--json` as an automation API. It must emit parseable JSON only from the task path; no banners, prose, ANSI labels, or trailing explanatory text in JSON mode.
- **D-09:** Lock top-level JSON fields for Phase 146: `schema_version`, `generated_at`, `status`, `live_checked`, `core`, `companions`, and `checks`.
- **D-10:** Use additive JSON compatibility. New optional fields may be added under the same `schema_version`, but deleting or renaming stable fields or changing enum meaning requires a schema major bump.
- **D-11:** Normalize component objects around explicit nouns: `kind` (`core`, `native`, `companion`, `observer`), `name` or `component`, `package` when applicable, `path`, `manifest_version`, `configured_version`, `core_requirement` when applicable, `release_as`, `release_as_tag_exists`, and `live`.
- **D-12:** Lock check objects around stable machine fields: `code`, `status` (`ok`, `warning`, `error`), `message`, `next_action`, `source`, and optionally `evidence` for file/check references. Stable `code` values are the primary automation key.
- **D-13:** Do not expose GSD requirement IDs such as `PREF-01`, `MIRR-01`, or `STAT-01` as user-facing completion claims. If internal requirement mapping is useful, keep it out of the default text output and do not make issue automation parse planning prose.
- **D-14:** JSON consumers should not scrape human `message` prose. Automation should branch on `status`, `code`, and structured fields.

### Live Probe Semantics
- **D-15:** Default status remains local-only and deterministic. `--live` is the only path that checks public registries.
- **D-16:** Live probes must distinguish `ok`, `missing`, and `unavailable`. `missing` means the exact artifact/ref was checked and absent. `unavailable` means network, timeout, 5xx, tool missing, or registry access failure prevented a truthful absence claim.
- **D-17:** Live registry misses and unavailable probes should be `warning` by default, not `error`, because STAT-03 says live checks are optional and normal CI must not depend on live network state.
- **D-18:** Blocking local contradictions remain `error`: core/native lockstep drift, configured version drift, stale `release-as` pins that point at existing release tags, missing required source files, or scanner evidence that proves release workflow guard drift.
- **D-19:** Hex probes should check the exact release endpoint for each package/version and, when available, validate exact version identity and non-retired usable release state. The companion `requirements.crosswake.requirement` from Hex metadata is useful live evidence but should not replace local source-floor drift guards.
- **D-20:** Maven probes should check the exact Android core POM URL for the manifest version. Maven Central immutability makes exact-coordinate presence meaningful.
- **D-21:** SwiftPM/iOS probes should check `refs/tags/v${version}` on `szTheory/crosswake-shell-core-ios` with bounded `git ls-remote --tags`. The probe must not push or infer success from mirror `main`.
- **D-22:** Live probes need bounded timeouts and concise failure reporting. Raw registry payloads, stack traces, token mechanics, and long curl/git logs do not belong in normal text output.

### Exit Behavior And Automation
- **D-23:** Aggregate status precedence is `error > warning > ok`.
- **D-24:** The task should exit 0 for `ok` and `warning`. It should exit non-zero for `error` and invalid invocation. This keeps optional live warnings visible without breaking normal CI.
- **D-25:** If a stricter scheduled workflow or issue-opening path is added, prefer an explicit strict option such as `--fail-on-warning`; do not make `--live` warnings fatal by default.
- **D-26:** If issue-opening automation is added in this phase, it must dedupe on a stable key such as `release-status:{version}:{check.code}`, use least privilege (`contents: read`, `issues: write`), upload the JSON artifact with `if-no-files-found: error`, and write a GitHub job summary. It is not required by STAT-02 if JSON is clearly suitable for such automation.
- **D-27:** The status task should not duplicate release workflow scanner logic. Reuse `script/check_release_workflow_integrity.exs` output or the same stable scanner IDs where practical so source policy does not split between two brittle parsers.

### Operator UX And Docs Truth
- **D-28:** Text output should stay grouped by operator job-to-be-done: core/native lockstep, companions, checks, and live registry state when enabled.
- **D-29:** Every non-OK check in text and JSON should include a next action. The next action should be a command, workflow, or file to inspect, not a generic "investigate."
- **D-30:** Use Crosswake brand voice: calm, direct, short, specific, and actionable. Prefer "registry missing", "local graph drift", "release-as pin stale", and "next action" over vague success or failure language.
- **D-31:** Use exact labels consistently across docs and output: "configured version", "manifest version", "requires_crosswake", "live registry state", "native_core", "release-as pin", and "next action."
- **D-32:** Reconcile docs that currently describe Phase 146 as future work once the implementation lands. At minimum review `docs/COMPANION-PUBLISH-RUNBOOK.md`, `guides/companion_compatibility.md`, `guides/support_matrix.md`, `CHANGELOG.md`, and `README.md`.
- **D-33:** Keep release-status docs explicit that default status reads checked-in source/config/workflow files only. Public registry truth requires `--live`.
- **D-34:** Update stale docs to distinguish registry presence from compatibility floors. `mix crosswake.release.status --live` owns registry presence; `guides/companion_compatibility.md` owns floor semantics and must not normalize older-compatible companions upward just because registry status is being checked.
- **D-35:** Add focused docs/tests for the JSON schema and exit behavior. Do not rely on casual examples only; this command is an operator contract.

### Claude's Discretion
Downstream agents may choose exact helper names, whether JSON schema documentation lives in the runbook or task moduledoc, and whether to add a strict automation flag. They should not revisit the local-first default, read-only command boundary, advisory `--live` posture, stable JSON fields, or stale Phase 144/145 wording removal unless official registry or Mix behavior contradicts these decisions.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Planning And Current Milestone
- `.planning/PROJECT.md` - v18 thesis, release-integrity scope, and no-product-breadth boundary.
- `.planning/REQUIREMENTS.md` - STAT-01, STAT-02, and STAT-03 requirements plus completed PREF/MIRR traceability.
- `.planning/ROADMAP.md` - Phase 146 boundary and v18 success criteria.
- `.planning/STATE.md` - current position and note that `mix crosswake.release.status [--json] [--live]` already exists as implementation spillover.
- `.planning/MILESTONE-ARC.md` - v18 objective: release-status diagnostics as part of package-family release integrity.
- `.planning/MILESTONES.md` - SEED-003 and SEED-004 historical release truth that v18 harvested.

### Prior Phase Decisions And Verification
- `.planning/phases/145-native-registry-mirror-parity/145-CONTEXT.md` - native rollup, iOS mirror backfill, and boundary that local release-status completion remains Phase 146.
- `.planning/phases/145-native-registry-mirror-parity/145-VERIFICATION.md` - MIRR-01, MIRR-02, and MIRR-03 completion evidence.
- `.planning/phases/145-native-registry-mirror-parity/145-02-SUMMARY.md` - `native-release-status` artifact shape and Phase 146 handoff.
- `.planning/phases/144-published-core-compatibility-clean-room-proof/144-CONTEXT.md` - clean-room exactness and release-integrity scanner decisions.
- `.planning/phases/144-published-core-compatibility-clean-room-proof/144-VERIFICATION.md` - PREF-01, PREF-02, and PREF-03 completion evidence that makes current status copy stale.
- `.planning/phases/143-guarded-auto-publish-train/143-CONTEXT.md` - release-status spillover, exact-ref recovery, already-live semantics, and mixed companion floors.

### Project Voice And Research Prompts
- `brandbook/BRAND-SPEC.md` - current voice and docs system; supersedes `prompts/crosswake-brand-book.md`.
- `prompts/crosswake-elixir-oss-dna.md` - install truth, public contract honesty, proof lanes, release truth, and operator surfaces.
- `prompts/crosswake-gsd-project-brief.md` - release automation, proof posture, docs-contract checks, and explicit support matrices as product features.
- `prompts/crosswake-research-synthesis.md` - Crosswake anti-scope and proof-before-claims posture.
- `prompts/elixir-mobile-oss-lib-deep-research.md` - release risk register, docs honesty, and package ecosystem lessons.
- `prompts/elixir-mobile-oss-refined-plan-deep-research.md` - daily DX, doctor/status visibility, and making invisible shell/release state visible.
- `prompts/crosswake-integrations-and-companions.md` - operator visibility and companion-boundary context.

### Local Release Status Code
- `lib/crosswake/release_status.ex` - current release graph model, renderer, checks, live probes, and stale Phase 144 wording.
- `lib/mix/tasks/crosswake.release.status.ex` - public Mix task options and current exit behavior.
- `test/mix/tasks/crosswake_release_status_test.exs` - current tests that intentionally preserve stale downstream wording and need Phase 146 update.
- `.github/workflows/release-please.yml` - path-gated publish jobs, native rollup, `native-release-status` artifact, and release-as cleanup.
- `.github/workflows/ios-mirror-backfill.yml` - verify-first SwiftPM mirror recovery wrapper; status should point here but not duplicate it.
- `script/check_release_workflow_integrity.exs` - stable scanner IDs that release status should reuse or mirror carefully.
- `script/verify_ios_mirror_backfill.sh` - guarded mutation/recovery boundary outside the status task.
- `.release-please-manifest.json` - local release graph version truth.
- `release-please-config.json` - linked core/native group, independent companions, and release-as pins.

### Docs To Reconcile
- `docs/COMPANION-PUBLISH-RUNBOOK.md` - release operator runbook; currently names Phase 146 as future status work.
- `guides/companion_compatibility.md` - companion floor matrix; should remain floor authority while pointing registry presence at status.
- `guides/support_matrix.md` - support truth and native proof labels; must keep SwiftPM mirror backfill as registry evidence, not device proof.
- `CHANGELOG.md` - release truth and public package status claims need review for stale companion/native status.
- `README.md` - package/install truth entry point; update only if release-status command belongs in public maintainer docs.

### External Primary References Consulted
- `https://hexdocs.pm/mix/Mix.Task.html` - Mix task naming, `@shortdoc`, `run/1`, `@requirements`, and public task help behavior.
- `https://hex.hexdocs.pm/Mix.Tasks.Hex.Outdated.html` - Hex precedent for status checks with non-zero exit behavior.
- `https://doc.rust-lang.org/cargo/commands/cargo-metadata.html` - versioned, additive JSON metadata contract precedent.
- `https://docs.npmjs.com/cli/v9/commands/npm-audit/` - JSON output and configurable failure threshold precedent.
- `https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-commands#adding-a-job-summary` - GitHub job summaries as operator UI.
- `https://docs.github.com/en/actions/reference/workflows-and-actions/contexts#needs-context` - `needs.<job_id>.result` states for release rollups.
- `https://docs.github.com/en/actions/tutorials/store-and-share-data` - workflow artifacts for machine evidence.
- `https://github.com/googleapis/release-please-action` - Release Please outputs and post-release publish examples.
- `https://hex.pm/docs/publish` - Hex publish/version metadata and package release context.
- `https://raw.githubusercontent.com/hexpm/specifications/main/apiary.apib` - Hex API release metadata shape.
- `https://central.sonatype.org/publish/requirements/immutability/` - Maven Central immutability and exact artifact identity.
- `https://docs.swift.org/swiftpm/documentation/packagemanagerdocs/releasingpublishingapackage/` - SwiftPM semantic Git tag release identity.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/crosswake/release_status.ex`: already reads `.release-please-manifest.json`, `release-please-config.json`, package `mix.exs` files, Android Gradle version, release workflow text, and optional Hex/Maven/iOS live probes.
- `lib/mix/tasks/crosswake.release.status.ex`: already exposes `mix crosswake.release.status`, `--json`, and `--live`.
- `test/mix/tasks/crosswake_release_status_test.exs`: already covers text output, JSON output, governance check codes, and deterministic injected live probes.
- `script/check_release_workflow_integrity.exs`: already has stable Phase 142/143/144/145 release-integrity IDs and should remain the semantic workflow policy source.
- `.github/workflows/release-please.yml`: already emits `native-release-status.json` as a narrow CI artifact from the Phase 145 rollup.

### Established Patterns
- Release safety is encoded in small scripts, stable check IDs, and ExUnit negative fixtures rather than review-only guidance.
- Default status/proof paths should be deterministic and local; live registries are useful but optional.
- Operator copy uses `[crosswake]` in scripts and calm, specific wording in docs and tasks.
- Crosswake keeps proof labels honest: registry presence, compatibility floors, native proof, and device/emulator evidence are separate claims.

### Integration Points
- STAT-01 connects to local graph checks: core/native lockstep, configured version drift, companion versions, compatibility floors, release-as pins, and release workflow guard status.
- STAT-02 connects to JSON schema stability, check codes, status severities, and possible issue-opening automation.
- STAT-03 connects to optional Hex, Maven Central, and SwiftPM mirror probes with bounded, advisory behavior.
- Docs reconciliation connects to `docs/COMPANION-PUBLISH-RUNBOOK.md`, `guides/companion_compatibility.md`, `guides/support_matrix.md`, `CHANGELOG.md`, and possibly `README.md`.

</code_context>

<specifics>
## Specific Ideas

Recommended text output shape:

```text
Crosswake release status

status: warning
live checks: disabled - local release graph only

Core/native lockstep:
- hex: manifest=0.2.0 configured=0.2.0
- ios-core: manifest=0.2.0 configured=0.2.0
- android-core: manifest=0.2.0 configured=0.2.0

Companions:
- crosswake_sigra: version=0.1.1 configured=0.1.1 requires_crosswake=~> 0.2

Checks:
- OK release.lockstep_manifest: core/native manifest versions match
- WARNING release.live_registry_presence: live checks disabled; run `mix crosswake.release.status --live` for registry state
- ERROR release.release_as_staleness: stale release-as pin detected for crosswake_rindle. Next: run release-as cleanup or inspect release-please-config.json.
```

Recommended JSON check object:

```json
{
  "code": "release.cleanroom_dependency_floor",
  "status": "ok",
  "message": "clean-room proof uses Hex metadata floors and exact companion pins",
  "next_action": null,
  "source": "script/check_release_workflow_integrity.exs",
  "evidence": ["release.cleanroom.hex_metadata_floor", "release.cleanroom.exact_companion_pin"]
}
```

Recommended live object:

```json
{
  "source": "ios_mirror",
  "status": "missing",
  "checked": true,
  "ref": "refs/tags/v0.2.0",
  "next_action": "run .github/workflows/ios-mirror-backfill.yml or script/verify_ios_mirror_backfill.sh --version 0.2.0 --ref refs/tags/ios-core-v0.2.0"
}
```

Recommended native artifact schema if touched:

```json
{
  "schema_version": "1.0.0",
  "generated_at": "2026-07-08T00:00:00Z",
  "run_id": "123456789",
  "version": "0.2.0",
  "native_core": "partial",
  "ios": {"released": true, "publish": "failure", "proof": "skipped", "state": "failed"},
  "android": {"released": true, "publish": "success", "proof": "success", "state": "proven"},
  "next_action": "Fix MIRROR_PUSH_TOKEN or run the iOS mirror backfill workflow."
}
```

Research summary: parallel subagents and local browsing converged on the same recommendation set. Mix task docs support a public task with `@shortdoc` and `run/1`; Cargo's metadata contract is the best precedent for additive JSON with a schema version; npm and Hex status commands show configurable/non-zero exit precedent; GitHub Actions summaries and artifacts map cleanly to the Phase 145 rollup split between human and machine evidence.

</specifics>

<deferred>
## Deferred Ideas

- A graphical release dashboard or Phoenix LiveDashboard panel remains DASH-01.
- Full automatic issue-opening can be deferred if Phase 146 locks JSON suitability and check-code stability; if implemented now, it must be deduped and least-privilege.
- Broad Maven Central recovery, SwiftPM mutation, Hex publish recovery, and iOS mirror backfill remain guarded workflow/script surfaces outside `mix crosswake.release.status`.
- New runtime capabilities, companion packages, offline-sync productization, native disk budgets, and commerce/native breadth remain deferred behind v18 release integrity.

</deferred>

---

*Phase: 146-Release Status DX & Docs Truth*
*Context gathered: 2026-07-08*
