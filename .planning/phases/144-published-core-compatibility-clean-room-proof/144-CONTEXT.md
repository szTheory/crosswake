# Phase 144: Published-Core Compatibility & Clean-Room Proof - Context

**Gathered:** 2026-07-07
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 144 owns the published-core clean-room proof surface for the Crosswake package family. It repairs the companion clean-room harness so release proof installs the exact companion version under test, derives the real `crosswake` compatibility floor from the published package under test, proves `mix crosswake.doctor --router` can load a freshly compiled clean-room router, and makes these claims merge-blocking through deterministic release-integrity tests.

This is release-proof and operator-trust work, not new product breadth. It validates already-present v18 implementation spillover where relevant, but does not claim Phase 145 native mirror/backfill parity or Phase 146 release-status DX completion.

</domain>

<decisions>
## Implementation Decisions

### Dependency Proof Exactness
- **D-01:** The clean-room release proof must derive the `crosswake` floor from Hex release metadata for the exact published package/version under test, specifically the release's `requirements.crosswake.requirement`. Local `packages/${PACKAGE}/mix.exs` and `guides/companion_compatibility.md` are supporting drift guards, not the release-truth authority.
- **D-02:** The companion artifact under test must be installed exactly as `{:package, "== ${VERSION}"}` using the Release Please component version output. A range such as `~> 0.1` or `~> 0.2` is not acceptable for the companion package under test.
- **D-03:** The script must fail closed when the Hex release API returns 404, a mismatched version, a retired/unusable release state, missing `requirements.crosswake.requirement`, invalid semver input, or an unknown package outside the allowlisted Crosswake package family.
- **D-04:** After `mix deps.get`, the proof must assert the generated `mix.lock` contains the exact companion version and a selected `crosswake` version that satisfies the derived requirement. The selected core version is a postcondition, not the source of the floor.
- **D-05:** Preserve mixed companion floors as release truth: `crosswake_rulestead` and `crosswake_rindle` remain `~> 0.1`; `crosswake_sigra`, `crosswake_chimeway`, and `crosswake_threadline` remain `~> 0.2`. Do not normalize older-compatible packages upward for automation neatness.

### Fresh Router Doctor Proof
- **D-06:** `mix crosswake.doctor --router` should own loading/config readiness for host code. The idiomatic Mix shape is `@requirements ["app.config"]` or an equivalent doctor-owned mechanism, because the task interacts with user modules and runtime config. Do not require `app.start`; the doctor should not boot the host supervision tree, endpoint, or database just to inspect route policy.
- **D-07:** The clean-room harness may compile after writing `CleanRoomHost.Router` and appending runtime config, but it must not rely on a separate router pre-load as the proof. The command `mix crosswake.doctor --router CleanRoomHost.Router` itself must prove the fresh router is loadable.
- **D-08:** A minimal `defmodule CleanRoomHost.Router do use Phoenix.Router end` is sufficient for the positive fresh-router proof. It matches the phase goal: prove router module loading, not route-policy richness.
- **D-09:** Add regression coverage for the negative cases that matter to DX: module unavailable after host compile/config, module exists but is not a Phoenix router, and valid fresh router accepted. Failure microcopy should distinguish those cases instead of flattening everything into "router unavailable."

### Merge-Blocking Guardrails
- **D-10:** Keep `script/check_release_workflow_integrity.exs` plus ExUnit as the authoritative PREF-03 merge-blocking proof. It is deterministic, repo-local, idiomatic for this codebase, and can encode Crosswake-specific release identity policy that generic Actions linters cannot know.
- **D-11:** Do not introduce a YAML parser or generated release-graph contract in Phase 144 unless the current scanner becomes unable to express the required invariants. GitHub Actions expression semantics still require policy-aware string checks even with a structured YAML reader.
- **D-12:** `actionlint` can be an additive/advisory syntax check after pin validation, but it must not replace the semantic scanner. Current local evidence shows `actionlint 1.7.12` does not yet understand `queue: max`, while GitHub's current docs do.
- **D-13:** PREF-03 must fail on aggregate `releases_created` gates in behavioral jobs, stale or locally-derived dependency floors, proof jobs that can run before matching publish jobs, native proof cascades, missing mirror-token preflight, missing package-family members, comment-only or step-text false passes, missing `queue: max`, and `cancel-in-progress: true`.
- **D-14:** Guard failures should use stable check IDs and actionable messages. Negative fixture tests should mutate real workflow/script text and assert the intended check ID fails.

### Package Matrix Coverage
- **D-15:** Phase 144 covers all five release-managed companion/observer packages: `crosswake_rulestead`, `crosswake_rindle`, `crosswake_sigra`, `crosswake_chimeway`, and `crosswake_threadline`. A proof that only covers the newer `~> 0.2` packages would create inconsistent family guarantees.
- **D-16:** The packages share one structural proof contract: per-component Release Please gate, publish job success, exact Hex package/version identity, derived `crosswake` floor, clean-room compile, public-seam smoke test, and doctor proof.
- **D-17:** Semantic smoke tests are package-profile-specific, not copy/paste identical. `rulestead` and `rindle` use engine-present profiles; `sigra` and `chimeway` use no-engine companion profiles; `threadline` uses observer/module-shipment canaries and must not be registered under `:companions`.
- **D-18:** Absence is part of the proof. Chimeway must not pull in Sigra for release proof, and Threadline must install without Sigra or Chimeway. Optional engines are installed only in the engine-present profiles that intentionally prove them.

### Operator And Developer Experience
- **D-19:** Logs and failure copy should follow the current Brand Spec: calm, technical, and specific. Use `[crosswake]`, name the package, version, derived floor, selected core version, proof state, and next safe command or file to inspect.
- **D-20:** Hide backend mechanics unless they change the operator's next action. Operators need to know "which package/version was proven, against which core floor, and what failed"; they do not need raw registry JSON unless a field is missing or malformed.
- **D-21:** Keep the normal proof path boring: publish or already-live exact package -> Hex metadata floor -> clean-room deps -> compile -> smoke -> doctor -> cleanup/status. Avoid clever shortcuts that make release logs harder to audit.

### Claude's Discretion
Downstream agents may choose helper function names, exact JSON parsing mechanics, and test factoring. They should not revisit the policy decisions above unless official Hex, Mix, GitHub Actions, or Release Please behavior contradicts them.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Planning And Prior Decisions
- `.planning/PROJECT.md` - v18 thesis, constraints, and release-integrity scope.
- `.planning/REQUIREMENTS.md` - PREF-01, PREF-02, PREF-03 traceability.
- `.planning/ROADMAP.md` - Phase 144 boundary relative to MIRR and STAT phases.
- `.planning/STATE.md` - current position and already-present implementation spillover notes.
- `.planning/phases/143-guarded-auto-publish-train/143-CONTEXT.md` - exact Release Please identity, idempotent already-live semantics, mixed floors, and Hex recovery posture.
- `.planning/phases/142-release-graph-governance-contract/142-CONTEXT.md` - release graph gates, concurrency, cleanup-after-proof, and semantic proof posture.
- `.planning/phases/141-core-first-publish-family-release/141-CONTEXT.md` - core-first publish root cause and `0.2.0` floor decisions.

### Project Voice And Research Prompts
- `brandbook/BRAND-SPEC.md` - current brand voice; supersedes older prompt brand notes.
- `prompts/crosswake-elixir-oss-dna.md` - install truth, proof lanes, release truth, doctor tasks, and optional dependency diagnostics.
- `prompts/crosswake-gsd-project-brief.md` - CI/CD, release discipline, proof posture, and recovery-conscious release flow as product surface.
- `prompts/crosswake-integrations-and-companions.md` - companion classification and opt-in integration posture.
- `prompts/crosswake-research-synthesis.md` - route/runtime thesis and anti-scope boundaries.
- `prompts/elixir-mobile-oss-lib-deep-research.md` - package-family, CI/CD, release automation, Hex/SPM/Maven, and test-layer lessons.
- `prompts/elixir-mobile-oss-refined-plan-deep-research.md` - Mix task, Plug/Phoenix, doctor, and DX idioms.
- `prompts/elixir-mobile-apptypes-design-stresstest-deep-research.md` - modular package design and compatibility/versioning lessons.

### Local Release Code
- `.github/workflows/release-please.yml` - publish jobs, clean-room proof jobs, path/component gates, concurrency, mirror preflight, and cleanup conditions.
- `.github/workflows/hex-publish.yml` - exact-ref Hex recovery surface from Phase 143.
- `release-please-config.json` - root/native linked group and independent companion components.
- `.release-please-manifest.json` - current release graph versions.
- `script/verify_companion_cleanroom.sh` - clean-room harness to harden for PREF-01/PREF-02.
- `script/guarded_hex_publish.sh` - exact package/version publish helper and already-live semantics.
- `script/check_release_workflow_integrity.exs` - PREF-03 semantic scanner to extend.
- `test/crosswake/proof/phase142_release_integrity_test.exs` - existing merge-blocking proof wrapper and negative fixture pattern.
- `lib/mix/tasks/crosswake.doctor.ex` - doctor router loading and Mix task requirements.
- `lib/crosswake/doctor/doctor.ex` - doctor report behavior and findings.
- `guides/companion_compatibility.md` - package-family floor matrix and docs drift target.
- `packages/crosswake_rulestead/mix.exs` - `~> 0.1` floor and engine-present profile.
- `packages/crosswake_rindle/mix.exs` - `~> 0.1` floor and engine-present profile.
- `packages/crosswake_sigra/mix.exs` - `~> 0.2` floor and no-engine companion profile.
- `packages/crosswake_chimeway/mix.exs` - `~> 0.2` floor and no-Sigra proof boundary.
- `packages/crosswake_threadline/mix.exs` - `~> 0.2` floor and observer/non-companion profile.

### External Primary References Consulted
- `https://hex.pm/docs/usage` - Hex dependency requirements and `mix.lock` resolution behavior.
- `https://hex.pm/docs/publish` - Hex package publish constraints; only Hex production dependencies are included.
- `https://hex.hexdocs.pm/Mix.Tasks.Hex.Publish.html` - Hex publish, dry-run, replace/revert windows, package metadata.
- `https://hexdocs.pm/elixir/Version.html` - version requirement semantics, `==`, `~>`, and matching.
- `https://hexdocs.pm/mix/Mix.Task.html` - Mix task `@requirements`, especially `loadpaths`, `app.config`, and `app.start`.
- `https://hexdocs.pm/mix/main/Mix.Tasks.Compile.html` - `mix compile` as the project compile/load path entry point.
- `https://hexdocs.pm/elixir/Code.html` - compiled/loaded module semantics and `ensure_compiled` caveats.
- `https://hexdocs.pm/phoenix/Phoenix.Router.html` - Phoenix router modules and route macro shape.
- `https://docs.github.com/en/enterprise-cloud@latest/actions/how-tos/write-workflows/choose-when-workflows-run/control-workflow-concurrency` - `queue: max`, cancellation, and FIFO caveats.
- `https://docs.github.com/en/actions/reference/workflows-and-actions/expressions` - `contains(fromJSON(...), item)` for array membership.
- `https://docs.github.com/en/actions/reference/workflows-and-actions/contexts` - `needs` context and workflow data access.
- `https://github.com/googleapis/release-please-action` - Release Please Release PR model and Conventional Commit behavior.
- `https://github.com/marketplace/actions/release-please-action` - Release Please outputs including `releases_created` and `paths_released`.
- `https://github.com/rhysd/actionlint` - generic GitHub Actions linter scope and limits.
- `https://doc.rust-lang.org/cargo/reference/features.html` - optional dependency/features lessons from Cargo.
- `https://docs.npmjs.com/cli/v8/using-npm/workspaces` - package identity lessons from npm workspaces.
- `https://packaging.python.org/en/latest/guides/writing-pyproject-toml/` - optional dependency/extras lessons from Python packaging.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `script/verify_companion_cleanroom.sh`: already creates a throwaway host outside the monorepo, installs exact package deps, compiles, runs package-specific smoke tests, registers companion config, and invokes doctor. It currently derives the core floor from local package source when available; Phase 144 should shift release proof to Hex release metadata.
- `script/guarded_hex_publish.sh`: already models package allowlisting, exact version validation, already-live Hex success, dry-run before publish, and registry polling. Reuse its operator-copy style and package-map discipline.
- `script/check_release_workflow_integrity.exs`: already checks exact path/component gates, proof decoupling, mirror preflight, cleanup-after-proof, and component proof gates. Extend it for PREF-specific dependency-floor and matrix assertions rather than replacing it.
- `test/crosswake/proof/phase142_release_integrity_test.exs`: already contains stable check-ID negative tests and comment/text decoy coverage. This is the right pattern for Phase 144.
- `lib/mix/tasks/crosswake.doctor.ex`: currently tries to compile and ensure the router module in task code. Phase 144 planning should consider Mix `@requirements ["app.config"]` and targeted regression tests so the task owns host-code readiness.
- `guides/companion_compatibility.md`: documents the current mixed floors and Threadline's non-companion observer status.

### Established Patterns
- Proof lanes are product surface. The correct shape is deterministic ExUnit and named scripts with actionable `[crosswake]` output, not a review-only checklist.
- Package identity is first-class. Behavioral jobs use Release Please path/component outputs; aggregate `releases_created` is only acceptable for summaries/logging.
- Optional dependencies fail honestly. Enabled-but-missing companion/engine state should deny or report explicitly; proof should include deliberate absence where absence is part of the contract.
- Crosswake favors precise Mix tasks, docs-contract tests, and support matrices over broad claims.

### Integration Points
- PREF-01 connects to `script/verify_companion_cleanroom.sh`, Hex release metadata, generated clean-room `mix.exs`, and lockfile postconditions.
- PREF-02 connects to `lib/mix/tasks/crosswake.doctor.ex`, the clean-room router stub, and doctor regression tests.
- PREF-03 connects to `script/check_release_workflow_integrity.exs`, `test/crosswake/proof/phase142_release_integrity_test.exs`, `.github/workflows/release-please.yml`, and the five package proof jobs.
- Phase 145 owns native mirror/backfill execution; Phase 144 only preserves the static mirror-token preflight guard as part of PREF-03.
- Phase 146 owns final release-status text/JSON/live probe UX; Phase 144 should avoid log shapes that make STAT harder.

</code_context>

<specifics>
## Specific Ideas

Recommended clean-room dependency flow:

1. Validate `PACKAGE` against the allowlist and validate `VERSION` as semver before interpolation.
2. Poll `https://hex.pm/api/packages/${PACKAGE}/releases/${VERSION}` until the exact release appears.
3. Parse the published release metadata and derive `CORE_REQUIREMENT` from `requirements.crosswake.requirement`.
4. Generate clean-room deps with `{:crosswake, CORE_REQUIREMENT}` and `{PACKAGE, "== ${VERSION}"}`.
5. Run `mix deps.get` and assert `mix.lock` pins `PACKAGE` exactly to `VERSION` and pins `crosswake` to a version matching `CORE_REQUIREMENT`.
6. Compile with warnings-as-errors.
7. Run package-profile smoke tests.
8. Run `mix crosswake.doctor --router CleanRoomHost.Router` as the proof that the doctor can load a fresh router.

Recommended package profiles:

- `crosswake_rulestead`: companion + engine-present profile; preserve `~> 0.1` core floor.
- `crosswake_rindle`: companion + engine-present profile; preserve `~> 0.1` core floor.
- `crosswake_sigra`: no-engine companion profile; preserve `~> 0.2` core floor.
- `crosswake_chimeway`: no-engine companion profile; do not install `crosswake_sigra`; preserve `~> 0.2` core floor.
- `crosswake_threadline`: observer profile; do not register in `:companions`; assert module-shipment canaries and no Sigra/Chimeway sibling deps; preserve `~> 0.2` core floor.

Recommended PREF-03 check IDs:

- `release.cleanroom.hex_metadata_floor`
- `release.cleanroom.exact_companion_pin`
- `release.cleanroom.lockfile_postcondition`
- `release.cleanroom.package_matrix_complete`
- `release.doctor.app_config_requirement`
- `release.doctor.fresh_router_loaded`
- `release.workflow.aggregate_gate.behavioral_jobs_absent`
- `release.workflow.proof_after_publish`
- `release.workflow.native_proof_decoupled`
- `release.workflow.mirror_token_preflight`

</specifics>

<deferred>
## Deferred Ideas

- Full native registry recovery/backfill for SwiftPM and Maven Central remains Phase 145.
- Missing iOS `v0.2.0` mirror tag verification/backfill remains Phase 145.
- Full `mix crosswake.release.status` text/JSON/live-probe completion remains Phase 146.
- A graphical dashboard/operator UI remains DASH-01 and is out of scope for v18 Phase 144.
- A structured YAML parser or generated release-graph contract is deferred until the semantic scanner proves too brittle for the release policy surface.
- Actionlint may become an additive lane after its pinned version understands current GitHub `queue: max` syntax; it is not the authoritative PREF-03 proof.
- New runtime capabilities, native feature breadth, offline-sync productization, and companion package additions remain deferred behind v18 release integrity.

</deferred>

---

*Phase: 144-Published-Core Compatibility & Clean-Room Proof*
*Context gathered: 2026-07-07*
