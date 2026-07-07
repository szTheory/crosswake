# Phase 143: Guarded Auto-Publish Train - Research

**Researched:** 2026-07-07
**Domain:** GitHub Actions release automation, Release Please monorepo outputs, Hex publish idempotency, exact-ref recovery
**Confidence:** MEDIUM

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

Copied verbatim from `.planning/phases/143-guarded-auto-publish-train/143-CONTEXT.md`. [VERIFIED: 143-CONTEXT.md]

#### Publish Authority Boundary
- **D-01:** Treat the Release Please Release PR merge as the human approval boundary. After that merge, CI owns package publishing for the artifacts Release Please says were released.
- **D-02:** The happy path must not require a maintainer to run `mix hex.publish` locally or dispatch a manual publish workflow.
- **D-03:** Do not use a permanent hybrid model where some package classes publish automatically and others require manual approval. It creates split-brain release truth and contradicts AUTO-01.
- **D-04:** Manual dispatch remains valid only for exact-ref recovery and fire-drills. It is not the normal publish path.
- **D-05:** First-publish caution is already past for the current published family. Future first-publish canaries may be human-gated in their own phases, but Phase 143 should make the current family train automatic.

#### Idempotent Already-Live Semantics
- **D-06:** If the exact package/version/tag/coordinate expected by Release Please is already live, treat that as a successful publish state, print a clear `[crosswake] OK: ... already live` message, skip the irreversible publish command, and continue to the appropriate proof job.
- **D-07:** "Already live" is success only when identity is proven against the expected package and version. If the workflow cannot tie the live artifact to the expected Release Please output/ref, fail closed with a clear next action.
- **D-08:** Do not use `mix hex.publish --replace` as the normal recovery behavior. Hex replacement belongs only inside the narrow registry grace window after deliberate operator review.
- **D-09:** Registry immutability should be modeled as state, not as a scary error. A rerun after partial success should converge: already-published artifact -> proof -> cleanup/status, not duplicate publish failure.
- **D-10:** Publish job output should say what happened, what was skipped, and what proof or command establishes truth. Hide backend mechanics unless they change the operator's next action.

#### Exact-Ref Recovery Surface
- **D-11:** Broaden `.github/workflows/hex-publish.yml` from root-only recovery to component-aware Hex recovery for `crosswake`, `crosswake_rulestead`, `crosswake_rindle`, `crosswake_sigra`, `crosswake_chimeway`, and `crosswake_threadline`.
- **D-12:** Keep Phase 143 recovery scoped to Hex packages only. SwiftPM mirror recovery, Maven Central recovery, and the missing iOS `v0.2.0` mirror backfill belong to Phase 145.
- **D-13:** Recovery workflow inputs should be explicit and hard to misuse: package/component, exact ref, and expected release version. Reject branch names; accept tags or full commit SHAs; resolve and print the checked-out SHA before publishing.
- **D-14:** Recovery must reuse the same idempotency policy as the automatic train: preflight registry presence, report already-live exact versions as success, otherwise dry-run then publish, then poll/verify registry presence.
- **D-15:** Map each Hex package to its working directory, version file, dependency-release env, test command, and publish command in one maintained package map or helper. Avoid copy/paste divergence between root and companion recovery logic.

#### Package Eligibility And Compatibility Floors
- **D-16:** The train covers every configured package in the current release graph: root Hex, iOS core, Android core, and all five `crosswake_*` companions.
- **D-17:** Preserve the current versioning model: root Hex + iOS core + Android core are the only lockstep linked group; all companions remain independently versioned Release Please components.
- **D-18:** Preserve honest companion floors. `rulestead` and `rindle` may keep publishing against `~> 0.1`; `sigra`, `chimeway`, and `threadline` require `~> 0.2`. Do not bump older companion floors to `~> 0.2` for automation convenience.
- **D-19:** Mixed floors are not a problem to hide; they are release truth. Surface them in docs/status output so maintainers and adopters can see why each package requires its floor.
- **D-20:** If a companion later uses a `0.2`-only core API, bump that package's floor in the package's own release. Do not preemptively constrain adopters of older-compatible companions.

#### Proof And Guardrails
- **D-21:** Extend the Phase 142 semantic workflow proof rather than relying on code review. The proof should lock idempotent publish preflight/reporting, component-aware Hex recovery, exact-ref checkout, and continued proof after already-live detection.
- **D-22:** Keep exact Release Please path/component gates from Phase 142. Aggregate `releases_created` remains allowed only for summaries/logging, never for publish, proof, cleanup, mirror, or recovery behavior.
- **D-23:** Cleanup after companion release remains publish+proof gated. A publish job that reports exact already-live success counts as publish success only when proof still runs and passes.
- **D-24:** Keep GitHub Actions release concurrency non-canceling with `queue: max`; release runs should not disappear when multiple Release PRs land close together.
- **D-25:** Use small named scripts/helpers and ExUnit assertions where they improve readability. The planner may choose exact factoring, but the final operator path must be easier to reason about than duplicated YAML shell fragments.

#### Developer Experience And Operator UX
- **D-26:** The user-facing surface is CI logs, workflow names, recovery workflow inputs, docs/runbook copy, and release-status output. There is no graphical UI requirement in this phase.
- **D-27:** Follow the current Brand Spec: calm, explicit, technical, and honest. Prefix release logs with `[crosswake]`; avoid "magic", "seamless", or vague success language.
- **D-28:** Use nouns/operators that match the domain: package, component, release ref, version, registry, live artifact, proof, cleanup PR, recovery.
- **D-29:** Favor the operator's JTBD: "Did this package publish? If not, is the exact version already live? What proof ran? What is the next safe command?" Do not expose low-level Release Please internals unless needed to choose the next action.
- **D-30:** JSON/status consumers should receive structured state, not prose scraping. Phase 146 owns the full release-status DX, but Phase 143 should not introduce log shapes that make STAT harder.

#### Ecosystem Lessons Applied
- **D-31:** Hex and Maven Central both reward immutable-release thinking. Normal recovery is roll-forward or exact already-live detection, not overwrite attempts.
- **D-32:** Release Please, Lerna, Nx, and Changesets all reinforce package identity as first-class in monorepos. Crosswake should keep exact package membership visible instead of using a broad "something released" flag.
- **D-33:** GitHub Actions `queue: max` now supports queued release/deploy runs. This is appropriate for release workflows where older pending release runs must not be replaced.
- **D-34:** SwiftPM tags and Maven artifacts have different recovery semantics from Hex. Do not generalize Hex recovery into native registry behavior in Phase 143.

### the agent's Discretion

Copied verbatim from `.planning/phases/143-guarded-auto-publish-train/143-CONTEXT.md`. [VERIFIED: 143-CONTEXT.md]

The user asked for all gray areas to be researched and a one-shot recommendation set. Downstream agents may choose implementation mechanics such as helper script names, exact workflow input names, or test factoring, but should not revisit the policy choices above unless official registry/API behavior contradicts them.

### Deferred Ideas (OUT OF SCOPE)

Copied verbatim from `.planning/phases/143-guarded-auto-publish-train/143-CONTEXT.md`. [VERIFIED: 143-CONTEXT.md]

- Native registry recovery/backfill for SwiftPM and Maven Central belongs to Phase 145.
- The missing iOS `v0.2.0` mirror tag backfill belongs to Phase 145.
- Clean-room exact companion install/floor derivation is validated in Phase 144.
- Full release-status text/JSON/live-probe completion belongs to Phase 146.
- A graphical dashboard/operator UI remains DASH-01 and is out of scope for v18 Phase 143.
- Broad YAML parsing or a new workflow parser dependency remains deferred unless the semantic checker becomes broad workflow inventory.
- New product integrations, native capability breadth, offline-sync productization, and `crosswake_dashboard` remain deferred behind v18 release integrity.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| AUTO-01 | The happy-path release train publishes package artifacts from Release Please outputs without maintainer-run `mix hex.publish` commands. [VERIFIED: REQUIREMENTS.md] | Release Please exposes exact root/path outputs and `paths_released`, and the current workflow already gates publish jobs from those outputs; Phase 143 should add idempotent publish preflight before irreversible Hex publishes. [CITED: https://github.com/googleapis/release-please-action#outputs] [VERIFIED: .github/workflows/release-please.yml] |
| AUTO-02 | Core/native artifacts remain lockstep while `crosswake_*` companions remain independently versioned. [VERIFIED: REQUIREMENTS.md] | `release-please-config.json` has a `linked-versions` group only for `hex`, `ios-core`, and `android-core`, while each companion is a separate package entry with its own manifest version. [VERIFIED: release-please-config.json] [VERIFIED: .release-please-manifest.json] |
| AUTO-03 | Recovery paths stay exact-ref and idempotent so already-live versions are reported rather than re-published. [VERIFIED: REQUIREMENTS.md] | GitHub manual dispatch supports typed inputs, Hex documents immutability plus narrow replace/revert windows, and current manual recovery is root-only with no already-live preflight. [CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#onworkflow_dispatchinputs] [CITED: https://hex.pm/docs/faq] [VERIFIED: .github/workflows/hex-publish.yml] |
</phase_requirements>

## Project Constraints (from AGENTS.md)

- Read `.planning/PROJECT.md`, `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, and `.planning/STATE.md` before planning or implementation work. [VERIFIED: AGENTS.md]
- Preserve the core thesis: Crosswake is Phoenix-first route-policy and runtime-contract infrastructure, not a universal UI framework. [VERIFIED: AGENTS.md]
- Keep runtime ownership explicit per route and avoid generic WebView-wrapper or LiveView-driven native-rendering designs. [VERIFIED: AGENTS.md]
- Treat bridge contracts as semantic, typed, versioned, and low-frequency; continuous client authority belongs in offline islands or native screens. [VERIFIED: AGENTS.md]
- Keep offline claims honest by distinguishing cached read-only behavior from local-first mutation with journals, outboxes, and reconciliation. [VERIFIED: AGENTS.md]
- Treat diagnostics, support matrices, proof lanes, and rough-edge documentation as product surface. [VERIFIED: AGENTS.md]
- Respect v1 scope boundaries before adding integrations or wider native breadth. [VERIFIED: AGENTS.md]
- Keep planning artifacts aligned as work progresses. [VERIFIED: AGENTS.md]

## Summary

Phase 143 should be planned as a release-ops hardening phase, not as new runtime functionality. [VERIFIED: 143-CONTEXT.md] The current `release-please.yml` already has exact root/native path gates, per-companion gates, non-canceling `queue: max`, cleanup-after-proof, native mirror preflight, and native proof decoupling, and the remaining Hex gaps are the direct `mix hex.publish --yes` steps and root-only manual recovery. [VERIFIED: .github/workflows/release-please.yml] [VERIFIED: .github/workflows/hex-publish.yml] [VERIFIED: script/check_release_workflow_integrity.exs]

Use one maintained publish helper for both automatic and manual Hex paths. [VERIFIED: 143-CONTEXT.md] The helper should map package -> working directory/version file/release env/test command, verify the expected version at the checked-out ref, query the exact Hex package/version before any irreversible publish, return success with `[crosswake] OK` when the exact version is already live, otherwise dry-run, publish, poll, and return success only after the exact version is visible. [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html] [CITED: https://hex.pm/docs/faq] [VERIFIED: curl https://hex.pm/api/packages/crosswake/releases/0.2.0]

The planner should extend the Phase 142 semantic proof instead of relying on review discipline. [VERIFIED: 143-CONTEXT.md] The existing scanner and ExUnit wrapper are green today, and Phase 143 should add checks for already-live preflight before each Hex publish, no normal `--replace`, component-aware recovery inputs, exact-ref rejection of branch-shaped refs, package-map coverage, and proof continuation after already-live success. [VERIFIED: script/check_release_workflow_integrity.exs] [VERIFIED: test/crosswake/proof/phase142_release_integrity_test.exs] [VERIFIED: `elixir script/check_release_workflow_integrity.exs`] [VERIFIED: `mix test test/crosswake/proof/phase142_release_integrity_test.exs`]

**Primary recommendation:** add `script/guarded_hex_publish.sh`, route every automatic and manual Hex publish through it, broaden `hex-publish.yml` to `package`/`ref`/`release_version`, and extend `script/check_release_workflow_integrity.exs` plus `phase142_release_integrity_test.exs` to prove those semantics. [VERIFIED: 143-CONTEXT.md] [VERIFIED: .github/workflows/release-please.yml] [VERIFIED: .github/workflows/hex-publish.yml]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Release identity selection | GitHub Actions / Release Please | Release Please config | Release Please emits aggregate, root, path, and component outputs; Crosswake workflow already aliases exact path/component outputs for downstream jobs. [CITED: https://github.com/googleapis/release-please-action#outputs] [VERIFIED: .github/workflows/release-please.yml] |
| Hex idempotent publish | CI helper script | Hex.pm registry | The irreversible operation is `mix hex.publish --yes`, so the helper should own version verification, exact registry preflight, dry-run, publish, and poll. [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html] [CITED: https://hex.pm/docs/faq] |
| Exact-ref recovery | Manual GitHub Actions workflow | CI helper script | `workflow_dispatch` inputs are available through the `inputs` context, and the existing recovery workflow already accepts an exact ref/version but only for root. [CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#onworkflow_dispatchinputs] [VERIFIED: .github/workflows/hex-publish.yml] |
| Version graph preservation | Release Please config | Package `mix.exs` files | Core Hex/iOS/Android are linked, while companions are separately configured and carry their own `@version` and `crosswake_dep/0` floors. [VERIFIED: release-please-config.json] [VERIFIED: .release-please-manifest.json] [VERIFIED: packages/crosswake_rulestead/mix.exs] |
| Proof guardrails | ExUnit + semantic scanner | GitHub Actions workflow files | Phase 142 already proves workflow semantics through `script/check_release_workflow_integrity.exs`; Phase 143 should extend that same scanner. [VERIFIED: script/check_release_workflow_integrity.exs] [VERIFIED: test/crosswake/proof/phase142_release_integrity_test.exs] |
| Operator copy | CI logs and workflow names | Future release-status output | Phase 143 surface is logs, workflow names, recovery inputs, docs/runbook copy, and status-compatible structured state. [VERIFIED: 143-CONTEXT.md] |

## Standard Stack

### Core

| Library / Tool | Version | Purpose | Why Standard |
|----------------|---------|---------|--------------|
| GitHub Actions workflow syntax | Current docs | Release workflow orchestration, `workflow_dispatch` inputs, `needs` outputs, expressions, and concurrency. [CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax] | It is the existing release execution tier and already owns Release Please, Hex, iOS, Android, proof, cleanup, and alert jobs. [VERIFIED: .github/workflows/release-please.yml] |
| `googleapis/release-please-action` | v4.1.3 pinned by SHA `45996ed...` | Release PR and GitHub Release/tag creation in manifest mode. [VERIFIED: .github/workflows/release-please.yml] | It officially exposes `releases_created`, `paths_released`, root outputs, and path-prefixed outputs used by Crosswake's exact gates. [CITED: https://github.com/googleapis/release-please-action#outputs] |
| Hex `mix hex.publish` | Hex docs v2.5.0 | Hex package dry-run, publish, replace, and revert task. [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html] | It is the authoritative publish command for Elixir packages, and Hex's immutability rules make preflight idempotency mandatory for reruns. [CITED: https://hex.pm/docs/faq] |
| Bash + `curl` + Python stdlib JSON | Bash 5.2.37, curl 8.7.1, Python 3.14.4 locally | One helper script to orchestrate CLI commands and parse exact Hex API responses. [VERIFIED: env audit] | The current workflow already uses shell and Python for release automation, and Python avoids grepping JSON for exact package/version identity. [VERIFIED: .github/workflows/release-please.yml] |
| ExUnit | Elixir 1.19.5 locally | Semantic proof wrapper and negative fixtures. [VERIFIED: env audit] | The existing Phase 142 proof is an ExUnit file that shells to the scanner and negative fixtures. [VERIFIED: test/crosswake/proof/phase142_release_integrity_test.exs] |

### Supporting

| Library / Tool | Version | Purpose | When to Use |
|----------------|---------|---------|-------------|
| `actions/checkout` | v7.0.0 pinned by SHA `9c091...` | Checkout exact Release Please tags and recovery refs. [VERIFIED: .github/workflows/release-please.yml] | Use in both automatic and manual publish workflows before invoking the shared helper. [VERIFIED: .github/workflows/release-please.yml] [VERIFIED: .github/workflows/hex-publish.yml] |
| `erlef/setup-beam` | v1.24.0 pinned by SHA `fc68...` | Install Elixir/Erlang from `.tool-versions`. [VERIFIED: .github/workflows/release-please.yml] | Use for every Hex publish and recovery job before `mix` commands. [VERIFIED: .github/workflows/release-please.yml] |
| `actions/cache` | v5.0.5 pinned by SHA `27d5...` | Cache root and companion deps/build directories. [VERIFIED: .github/workflows/release-please.yml] | Keep existing cache shape per package; do not centralize in a way that mixes root and companion builds. [VERIFIED: .github/workflows/release-please.yml] |
| `gh` CLI | 2.95.0 locally | Cleanup PR and issue automation. [VERIFIED: env audit] | Existing release cleanup/failure alert uses `gh`; Phase 143 should not require it for Hex publish idempotency. [VERIFIED: .github/workflows/release-please.yml] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Shared Bash publish helper | Inline YAML shell in every job | Inline YAML matches current style but repeats registry/idempotency logic across six Hex jobs and the recovery workflow. [VERIFIED: .github/workflows/release-please.yml] [VERIFIED: 143-CONTEXT.md] |
| Python JSON parse inside helper | `grep -q '"version"'` | `grep` proves a response contains a version field, but exact identity requires parsed package/version comparison. [VERIFIED: .github/workflows/release-please.yml] [VERIFIED: curl https://hex.pm/api/packages/crosswake/releases/0.2.0] |
| Extending semantic scanner | Adding a broad YAML parser dependency | The context defers broad YAML parsing unless the checker becomes broad workflow inventory, and the current scanner already proves release semantics. [VERIFIED: 143-CONTEXT.md] [VERIFIED: script/check_release_workflow_integrity.exs] |

**Installation:**

```bash
# No new package install is recommended for Phase 143.
```

**Version verification:** No new ecosystem packages are required; tool versions were verified from workflow pins, local probes, and official docs. [VERIFIED: .github/workflows/release-please.yml] [VERIFIED: env audit] [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html]

## Package Legitimacy Audit

Phase 143 should not install new external packages. [VERIFIED: 143-CONTEXT.md] The recommended implementation uses existing GitHub Actions, existing pinned action versions, existing Elixir/ExUnit tests, shell, `curl`, and Python stdlib. [VERIFIED: .github/workflows/release-please.yml] [VERIFIED: env audit]

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| none | — | — | — | — | OK | No package legitimacy gate required because no new external package install is recommended. [VERIFIED: 143-CONTEXT.md] |

**Packages removed due to [SLOP] verdict:** none. [VERIFIED: no package install]
**Packages flagged as suspicious [SUS]:** none. [VERIFIED: no package install]

## Architecture Patterns

### System Architecture Diagram

This diagram reflects current workflow ownership plus the Phase 143 helper boundary. [VERIFIED: .github/workflows/release-please.yml] [VERIFIED: .github/workflows/hex-publish.yml] [VERIFIED: 143-CONTEXT.md]

```text
Release PR merge
  |
  v
Release Please action
  |
  +-- root/native paths_released -> publish-hex / publish-ios-core / publish-android-core
  |
  +-- companion component outputs -> publish-hex-{component}
                                      |
                                      v
                            script/guarded_hex_publish.sh
                                      |
                  +-------------------+--------------------+
                  |                                        |
        Hex API exact package/version present?      Hex API absent?
                  |                                        |
                  v                                        v
       print [crosswake] OK, skip publish          dry-run -> publish -> poll exact release
                  |                                        |
                  +-------------------+--------------------+
                                      |
                                      v
                         clean-room proof / cleanup gates

Manual recovery workflow_dispatch
  |
  v
package + exact ref + expected version -> reject branch-shaped ref -> checkout -> print SHA
  |
  v
same guarded_hex_publish helper
```

### Recommended Project Structure

```text
script/
├── guarded_hex_publish.sh                 # shared automatic/recovery Hex publish helper [VERIFIED: 143-CONTEXT.md]
├── check_release_workflow_integrity.exs   # extend semantic workflow scanner [VERIFIED: script/check_release_workflow_integrity.exs]
└── verify_companion_cleanroom.sh          # remains post-publish proof helper, deeper exactness is Phase 144 [VERIFIED: 143-CONTEXT.md]

.github/workflows/
├── release-please.yml                     # call guarded helper from every Hex publish job [VERIFIED: .github/workflows/release-please.yml]
└── hex-publish.yml                        # component-aware exact-ref Hex recovery [VERIFIED: .github/workflows/hex-publish.yml]

test/crosswake/proof/
└── phase142_release_integrity_test.exs    # add Phase 143 assertions/negative fixtures [VERIFIED: test/crosswake/proof/phase142_release_integrity_test.exs]
```

### Pattern 1: Shared Guarded Hex Publish Helper

**What:** Route every Hex publish path through one helper that owns package mapping, version verification, exact live preflight, dry-run, publish, and poll. [VERIFIED: 143-CONTEXT.md] [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html]

**When to use:** Use for root `crosswake`, all five `crosswake_*` companions, and manual Hex recovery. [VERIFIED: 143-CONTEXT.md] [VERIFIED: .github/workflows/release-please.yml]

**Example:**

```bash
# Source: synthesized from Crosswake workflow patterns and Hex official docs.
# [VERIFIED: .github/workflows/release-please.yml] [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html]
script/guarded_hex_publish.sh crosswake_sigra "${SIGRA_VERSION}"
```

The helper should model a `200` response for `https://hex.pm/api/packages/$package/releases/$version` as exact already-live only after parsed JSON confirms `.version == $version`. [VERIFIED: curl https://hex.pm/api/packages/crosswake_sigra/releases/0.1.1]

### Pattern 2: Component-Aware Exact-Ref Recovery

**What:** Replace root-only `tag` input with `package`, `ref`, and `release_version`, then reject branch-shaped refs before checkout. [VERIFIED: .github/workflows/hex-publish.yml] [VERIFIED: 143-CONTEXT.md]

**When to use:** Use only for manual recovery/fire-drills after automatic release train failure or retry. [VERIFIED: 143-CONTEXT.md]

**Example:**

```yaml
# Source: GitHub workflow_dispatch inputs plus Phase 143 decisions.
# [CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#onworkflow_dispatchinputs] [VERIFIED: 143-CONTEXT.md]
on:
  workflow_dispatch:
    inputs:
      package:
        description: "Hex package to recover."
        required: true
        type: choice
        options:
          - crosswake
          - crosswake_rulestead
          - crosswake_rindle
          - crosswake_sigra
          - crosswake_chimeway
          - crosswake_threadline
      ref:
        description: "Exact release tag or full commit SHA; branch names are rejected."
        required: true
        type: string
      release_version:
        description: "Expected @version at that ref."
        required: true
        type: string
```

### Pattern 3: Semantic Proof Extensions

**What:** Extend the existing scanner with stable check IDs for idempotency and recovery invariants. [VERIFIED: script/check_release_workflow_integrity.exs]

**When to use:** Use whenever a workflow invariant affects publish authority, recovery safety, or proof continuation. [VERIFIED: 143-CONTEXT.md]

**Required check IDs:** `release.hex_publish.already_live_preflight`, `release.hex_publish.no_replace`, `release.hex_publish.shared_helper`, `recovery.hex.component_input`, `recovery.hex.exact_ref_only`, `recovery.hex.package_map_complete`, and `recovery.hex.already_live_success_continues`. [VERIFIED: 143-CONTEXT.md]

### Anti-Patterns to Avoid

- **Publishing directly after dry-run with no live preflight:** a rerun after partial success fails against Hex immutability instead of converging to proof. [CITED: https://hex.pm/docs/faq] [VERIFIED: .github/workflows/release-please.yml]
- **Using `--replace` as routine recovery:** Hex documents `--replace` as a narrow overwrite option for public packages only inside the allowed window, so normal recovery should not depend on it. [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html] [CITED: https://hex.pm/docs/faq]
- **Treating aggregate `releases_created` as publish authority:** Release Please documents it as aggregate truth, and Crosswake Phase 142 already forbids aggregate gates for behavioral jobs. [CITED: https://github.com/googleapis/release-please-action#outputs] [VERIFIED: script/check_release_workflow_integrity.exs]
- **Accepting branch names in recovery:** branch refs are mutable, while Phase 143 recovery requires tags or full commit SHAs. [VERIFIED: 143-CONTEXT.md]
- **Collapsing companion floors to `~> 0.2`:** package `mix.exs` files show `rulestead`/`rindle` use `~> 0.1`, while `sigra`/`chimeway`/`threadline` use `~> 0.2`. [VERIFIED: packages/crosswake_rulestead/mix.exs] [VERIFIED: packages/crosswake_rindle/mix.exs] [VERIFIED: packages/crosswake_sigra/mix.exs]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Release identity | Custom inference from tag names or changelog text | Release Please exact root/path/component outputs | Release Please officially exposes exact outputs, and Crosswake already aliases them for downstream jobs. [CITED: https://github.com/googleapis/release-please-action#outputs] [VERIFIED: .github/workflows/release-please.yml] |
| Registry idempotency | Parsing human `mix hex.publish` failure text | Exact Hex API preflight + parsed JSON | Hex immutability is registry state; a `200` exact release response lets reruns skip publish and continue proof. [CITED: https://hex.pm/docs/faq] [VERIFIED: curl https://hex.pm/api/packages/crosswake/releases/0.2.0] |
| JSON identity checks | `grep -q '"version"'` | Python stdlib JSON parse | Existing workflow grep is enough for coarse polling but not enough for exact identity. [VERIFIED: .github/workflows/release-please.yml] [VERIFIED: curl https://hex.pm/api/packages/crosswake_sigra/releases/0.1.1] |
| Recovery package mapping | Copy/pasted per-package YAML | One helper map for directory/version file/env/test/publish command | The context explicitly requires one maintained map or helper to avoid root/companion divergence. [VERIFIED: 143-CONTEXT.md] |
| Native registry recovery | Generalized Hex recovery workflow | Defer SwiftPM/Maven recovery to Phase 145 | Phase 143 is scoped to Hex recovery only. [VERIFIED: 143-CONTEXT.md] |

**Key insight:** Hex recovery should be state-driven, not exception-driven; already-live exact package/version is a successful state when tied to the expected release identity. [CITED: https://hex.pm/docs/faq] [VERIFIED: 143-CONTEXT.md]

## Common Pitfalls

### Pitfall 1: Duplicate Publish Reruns Fail Instead Of Converging

**What goes wrong:** a partial-success rerun reaches `mix hex.publish --yes` and fails because the exact public package version already exists. [CITED: https://hex.pm/docs/faq] [VERIFIED: .github/workflows/release-please.yml]

**Why it happens:** the current publish jobs dry-run and publish without preflighting the exact Hex package/version. [VERIFIED: .github/workflows/release-please.yml]

**How to avoid:** query the exact Hex release endpoint before publish, treat exact live as success, and let proof jobs continue. [VERIFIED: curl https://hex.pm/api/packages/crosswake/releases/0.2.0] [VERIFIED: 143-CONTEXT.md]

**Warning signs:** workflow contains `mix hex.publish --yes` with no preceding already-live check in the same job/helper. [VERIFIED: .github/workflows/release-please.yml]

### Pitfall 2: Already-Live Without Identity Binding

**What goes wrong:** a workflow sees some live package/version but cannot prove it belongs to the expected Release Please output/ref. [VERIFIED: 143-CONTEXT.md]

**Why it happens:** registry presence alone does not prove the workflow checked out the intended tag/SHA or verified the local version file. [VERIFIED: .github/workflows/hex-publish.yml]

**How to avoid:** verify the checked-out SHA, expected `@version`, package map entry, and parsed registry version before printing `[crosswake] OK`. [VERIFIED: 143-CONTEXT.md] [VERIFIED: packages/crosswake_sigra/mix.exs]

**Warning signs:** success log says "already live" without naming package, version, ref, and proof continuation. [VERIFIED: 143-CONTEXT.md]

### Pitfall 3: Root-Only Recovery Becomes A Companion Fire-Drill Dead End

**What goes wrong:** the manual workflow can recover `crosswake` root only, so companion failures require ad hoc local commands. [VERIFIED: .github/workflows/hex-publish.yml]

**Why it happens:** current `hex-publish.yml` has only `tag` and `release_version` inputs and assumes root `mix.exs`. [VERIFIED: .github/workflows/hex-publish.yml]

**How to avoid:** add a `package` choice input and use the shared helper's package map. [VERIFIED: 143-CONTEXT.md] [CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#onworkflow_dispatchinputs]

**Warning signs:** workflow greps only root `mix.exs` and has no `working-directory` branch for companions. [VERIFIED: .github/workflows/hex-publish.yml]

### Pitfall 4: Compatibility Floors Get Flattened For Automation Convenience

**What goes wrong:** older-compatible companions get bumped to `~> 0.2` only to simplify scripting. [VERIFIED: 143-CONTEXT.md]

**Why it happens:** package automation treats all companions as the same dependency shape. [VERIFIED: 143-CONTEXT.md]

**How to avoid:** package map must preserve each companion's existing `CROSSWAKE_RELEASE=1` dependency behavior and not edit floors in Phase 143. [VERIFIED: packages/crosswake_rulestead/mix.exs] [VERIFIED: packages/crosswake_rindle/mix.exs] [VERIFIED: packages/crosswake_sigra/mix.exs]

**Warning signs:** any Phase 143 diff changes `crosswake_dep/0` floors. [VERIFIED: packages/crosswake_rulestead/mix.exs]

### Pitfall 5: Normal Recovery Uses `--replace`

**What goes wrong:** the workflow tries to overwrite a public package version as normal retry behavior. [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html]

**Why it happens:** the operator models immutability as an error to fix rather than state to detect. [CITED: https://hex.pm/docs/faq]

**How to avoid:** scanner should fail any normal workflow path containing `mix hex.publish --replace`; docs can mention replacement only as deliberate operator action inside Hex's narrow window. [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html] [VERIFIED: 143-CONTEXT.md]

**Warning signs:** `--replace` appears in `release-please.yml`, `hex-publish.yml`, or the shared helper. [VERIFIED: .github/workflows/release-please.yml] [VERIFIED: .github/workflows/hex-publish.yml]

## Code Examples

Verified patterns from official sources and local code. [CITED: https://github.com/googleapis/release-please-action#outputs] [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html] [VERIFIED: .github/workflows/release-please.yml]

### Exact Hex Release Probe

```bash
# Source: Hex API live probe and Python stdlib parse recommendation.
# [VERIFIED: curl https://hex.pm/api/packages/crosswake/releases/0.2.0]
tmp="$(mktemp)"
http_code="$(curl -sS -o "$tmp" -w "%{http_code}" "https://hex.pm/api/packages/${PACKAGE}/releases/${VERSION}" || true)"

if [ "$http_code" = "200" ]; then
  parsed_version="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1])).get("version",""))' "$tmp")"
  if [ "$parsed_version" = "$VERSION" ]; then
    echo "[crosswake] OK: ${PACKAGE} ${VERSION} is already live on Hex.pm; no publish attempted. Continuing to proof."
    exit 0
  fi
  echo "[crosswake] FAIL: ${PACKAGE} registry response did not prove expected version ${VERSION}."
  exit 1
fi

if [ "$http_code" != "404" ]; then
  echo "[crosswake] FAIL: Hex.pm probe for ${PACKAGE} ${VERSION} returned HTTP ${http_code}."
  exit 1
fi
```

### Shared Helper Invocation From Automatic Publish Jobs

```yaml
# Source: current release-please.yml job shape plus Phase 143 shared-helper recommendation.
# [VERIFIED: .github/workflows/release-please.yml] [VERIFIED: 143-CONTEXT.md]
- name: Guarded Hex publish
  env:
    HEX_API_KEY: ${{ secrets.HEX_API_KEY }}
    CROSSWAKE_RELEASE: "1"
  run: script/guarded_hex_publish.sh crosswake_sigra "${{ needs.release-please.outputs.sigra_version }}"
```

### Exact Ref Validation For Recovery

```bash
# Source: Phase 143 exact-ref decision and Git checkout recovery surface.
# [VERIFIED: 143-CONTEXT.md] [VERIFIED: .github/workflows/hex-publish.yml]
case "$REF" in
  refs/heads/*|heads/*|main|master)
    echo "[crosswake] FAIL: recovery ref must be a release tag or full commit SHA, not a branch."
    exit 1
    ;;
esac

if ! [[ "$REF" =~ ^[0-9a-f]{40}$ || "$REF" =~ ^[^[:space:]]*v[0-9]+\.[0-9]+\.[0-9]+.*$ ]]; then
  echo "[crosswake] FAIL: recovery ref must be a full SHA or release tag."
  exit 1
fi

checked_out_sha="$(git rev-parse HEAD)"
echo "[crosswake] checked out ${REF} at ${checked_out_sha}"
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Aggregate Release Please gate `releases_created` for behavioral jobs | Exact `paths_released` and per-component outputs | Phase 142 on 2026-07-07 [VERIFIED: STATE.md] | Companion-only releases cannot publish core/native artifacts. [VERIFIED: script/check_release_workflow_integrity.exs] |
| Cancel or replace queued release runs | Non-canceling concurrency with `queue: max` | Phase 142 on 2026-07-07 [VERIFIED: STATE.md] | Multiple release runs can queue instead of disappearing. [CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#concurrency] [VERIFIED: .github/workflows/release-please.yml] |
| Manual root-only Hex recovery | Component-aware exact-ref Hex recovery | Phase 143 target [VERIFIED: 143-CONTEXT.md] | Every Hex package gets the same idempotent recovery surface. [VERIFIED: 143-CONTEXT.md] |
| Duplicate publish failure as operator error | Already-live exact package/version as successful state | Phase 143 target [VERIFIED: 143-CONTEXT.md] | Reruns after partial publish continue to proof and cleanup. [CITED: https://hex.pm/docs/faq] |
| Registry overwrite mindset | Roll-forward or exact already-live detection | Current ecosystem guidance [CITED: https://hex.pm/docs/faq] [CITED: https://central.sonatype.org/publish/requirements/immutability/] | Normal recovery does not depend on mutable public artifacts. [CITED: https://hex.pm/docs/faq] |

**Deprecated/outdated:**
- Root-only manual Hex recovery is insufficient for the current package graph. [VERIFIED: .github/workflows/hex-publish.yml] [VERIFIED: release-please-config.json]
- `mix hex.publish --replace` is not a normal recovery mechanism for public packages. [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html] [CITED: https://hex.pm/docs/faq]
- Grepping Hex JSON for `"version"` is weaker than parsed exact identity. [VERIFIED: .github/workflows/release-please.yml] [VERIFIED: curl https://hex.pm/api/packages/crosswake/releases/0.2.0]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| — | All planning-critical claims were verified from local files, command output, live Hex probes, or official docs during this research. | all | — |

## Open Questions

1. **Why do `crosswake_rulestead` and `crosswake_rindle` return 404 from Hex at their manifest versions?**
   - What we know: `.release-please-manifest.json` lists `packages/crosswake_rulestead` and `packages/crosswake_rindle` at `0.1.0`, and their `mix.exs` package names are `crosswake_rulestead` and `crosswake_rindle`. [VERIFIED: .release-please-manifest.json] [VERIFIED: packages/crosswake_rulestead/mix.exs] [VERIFIED: packages/crosswake_rindle/mix.exs]
   - What we know: live probes on 2026-07-07 returned HTTP 404 for `https://hex.pm/api/packages/crosswake_rulestead/releases/0.1.0` and `https://hex.pm/api/packages/crosswake_rindle/releases/0.1.0`, while `crosswake`, `crosswake_sigra`, `crosswake_chimeway`, and `crosswake_threadline` returned 200 for their current versions. [VERIFIED: curl Hex API 2026-07-07]
   - What's unclear: whether these two packages are unpublished, private, removed, or documented incorrectly. [VERIFIED: curl Hex API 2026-07-07]
   - Recommendation: before execution, add a Wave 0 verification task that reruns the live probe and asks the maintainer whether Phase 143 should auto-publish these two if absent or treat them as a first-publish exception requiring a separate decision. [VERIFIED: 143-CONTEXT.md]

2. **Should the helper live as Bash or Elixir?**
   - What we know: publish orchestration is CLI-heavy and existing workflow helpers already use shell for CI glue. [VERIFIED: .github/workflows/release-please.yml] [VERIFIED: script/verify_companion_cleanroom.sh]
   - What's unclear: whether maintainers prefer a richer Elixir helper for argument parsing and tests. [VERIFIED: 143-CONTEXT.md]
   - Recommendation: use Bash for the publish helper and keep semantic correctness in `check_release_workflow_integrity.exs` plus ExUnit fixtures. [VERIFIED: script/check_release_workflow_integrity.exs] [VERIFIED: test/crosswake/proof/phase142_release_integrity_test.exs]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir | Scanner, ExUnit proof, Mix publish commands | ✓ | 1.19.5 | GitHub workflow uses `erlef/setup-beam` from `.tool-versions`. [VERIFIED: env audit] [VERIFIED: .github/workflows/release-please.yml] |
| Mix | Hex publish/test commands | ✓ | Elixir 1.19.5 Mix | `erlef/setup-beam` in CI. [VERIFIED: env audit] [VERIFIED: .github/workflows/release-please.yml] |
| Git | Exact-ref checkout/verification | ✓ | 2.41.0 | GitHub hosted runner includes checkout; local fallback is required for tests only. [VERIFIED: env audit] [VERIFIED: .github/workflows/hex-publish.yml] |
| Bash | Shared helper script | ✓ | 5.2.37 | POSIX shell is possible but Bash matches existing script style. [VERIFIED: env audit] [VERIFIED: script/verify_companion_cleanroom.sh] |
| curl | Hex API preflight/poll | ✓ | 8.7.1 | No fallback recommended; workflow already uses `curl` for registry/mirror checks. [VERIFIED: env audit] [VERIFIED: .github/workflows/release-please.yml] |
| Python 3 | JSON parse without jq dependency | ✓ | 3.14.4 | `jq` is available locally, but Python stdlib is already used in workflow release automation. [VERIFIED: env audit] [VERIFIED: .github/workflows/release-please.yml] |
| jq | Local live-probe audit | ✓ | 1.7.1 | Use Python stdlib in committed helper to avoid jq reliance. [VERIFIED: env audit] |
| gh | Existing cleanup/alert automation | ✓ | 2.95.0 | Not required for guarded publish helper. [VERIFIED: env audit] [VERIFIED: .github/workflows/release-please.yml] |

**Missing dependencies with no fallback:** none found for planning and local proof. [VERIFIED: env audit]

**Missing dependencies with fallback:** none found for planning and local proof. [VERIFIED: env audit]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit with Elixir 1.19.5 locally. [VERIFIED: env audit] |
| Config file | `test/test_helper.exs`. [VERIFIED: rg --files] |
| Quick run command | `elixir script/check_release_workflow_integrity.exs && mix test test/crosswake/proof/phase142_release_integrity_test.exs` [VERIFIED: command run] |
| Full suite command | `mix verify` [VERIFIED: mix.exs] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| AUTO-01 | Every automatic Hex publish job uses Release Please exact outputs and a guarded already-live preflight before irreversible publish. [VERIFIED: REQUIREMENTS.md] | Semantic workflow proof | `mix test test/crosswake/proof/phase142_release_integrity_test.exs --only phase143_auto_publish` | ✅ existing file; Wave 0 adds assertions. [VERIFIED: test/crosswake/proof/phase142_release_integrity_test.exs] |
| AUTO-02 | Core/native lockstep remains limited to `hex`, `ios-core`, and `android-core`; companions remain independent. [VERIFIED: REQUIREMENTS.md] | Config/proof assertion | `mix test test/crosswake/proof/phase142_release_integrity_test.exs --only phase143_version_graph` | ✅ existing file; Wave 0 adds assertions. [VERIFIED: release-please-config.json] |
| AUTO-03 | Manual recovery is component-aware, exact-ref only, and already-live idempotent. [VERIFIED: REQUIREMENTS.md] | Semantic workflow proof + negative fixtures | `mix test test/crosswake/proof/phase142_release_integrity_test.exs --only phase143_recovery` | ✅ existing file; Wave 0 adds assertions and negative fixtures. [VERIFIED: .github/workflows/hex-publish.yml] |

### Sampling Rate

- **Per task commit:** `elixir script/check_release_workflow_integrity.exs` plus focused ExUnit test for the touched invariant. [VERIFIED: script/check_release_workflow_integrity.exs]
- **Per wave merge:** `mix test test/crosswake/proof/phase142_release_integrity_test.exs`. [VERIFIED: command run]
- **Phase gate:** `mix verify` plus the focused release integrity proof. [VERIFIED: mix.exs]

### Wave 0 Gaps

- [ ] Extend `script/check_release_workflow_integrity.exs` with Phase 143 check IDs. [VERIFIED: script/check_release_workflow_integrity.exs]
- [ ] Extend `test/crosswake/proof/phase142_release_integrity_test.exs` with Phase 143 positive and negative fixtures. [VERIFIED: test/crosswake/proof/phase142_release_integrity_test.exs]
- [ ] Add a live-registry verification task for `crosswake_rulestead` and `crosswake_rindle` before implementation changes rely on D-05 for those packages. [VERIFIED: curl Hex API 2026-07-07]

## Security Domain

OWASP ASVS provides a basis for testing technical security controls, and security enforcement is enabled because `.planning/config.json` does not set `workflow.security_enforcement` to `false`. [CITED: https://owasp.org/www-project-application-security-verification-standard/] [VERIFIED: .planning/config.json]

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | no | Phase 143 does not add application authentication; it uses repository secrets already referenced by workflows. [VERIFIED: .github/workflows/release-please.yml] |
| V3 Session Management | no | Phase 143 does not create user sessions or cookies. [VERIFIED: 143-CONTEXT.md] |
| V4 Access Control | yes | Use least-privilege job permissions and exact Release Please gates for publish authority. [VERIFIED: .github/workflows/release-please.yml] [CITED: https://github.com/googleapis/release-please-action#outputs] |
| V5 Input Validation | yes | Validate `workflow_dispatch` `package`, `ref`, and `release_version`; reject branch-shaped mutable refs. [CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#onworkflow_dispatchinputs] [VERIFIED: 143-CONTEXT.md] |
| V6 Cryptography | yes | Do not hand-roll artifact integrity; rely on Hex package checksums and registry immutability behavior. [CITED: https://hex.pm/docs/faq] |

### Known Threat Patterns for Release Automation

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Mutable branch recovery publishes the wrong code | Tampering | Reject branch names, accept tags/full SHAs, print `git rev-parse HEAD`, verify package version file. [VERIFIED: 143-CONTEXT.md] |
| Aggregate release output triggers unrelated publish | Elevation of privilege | Gate behavioral jobs on exact path/component outputs, not `releases_created`. [CITED: https://github.com/googleapis/release-please-action#outputs] [VERIFIED: script/check_release_workflow_integrity.exs] |
| Secret exposure in logs | Information disclosure | Keep `HEX_API_KEY` in `env`, never echo it, and keep logs focused on package/version/ref. [VERIFIED: .github/workflows/release-please.yml] [VERIFIED: 143-CONTEXT.md] |
| Duplicate immutable publish causes failed recovery | Denial of service | Treat exact already-live package/version as success and continue proof. [CITED: https://hex.pm/docs/faq] [VERIFIED: 143-CONTEXT.md] |
| Routine overwrite of public artifacts | Tampering | Scanner forbids normal `--replace`; operator review is required inside Hex's narrow window. [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html] [VERIFIED: 143-CONTEXT.md] |

## Sources

### Primary (HIGH confidence)

- `.planning/phases/143-guarded-auto-publish-train/143-CONTEXT.md` - locked Phase 143 decisions, scope, deferred ideas, and helper/proof expectations. [VERIFIED: 143-CONTEXT.md]
- `.github/workflows/release-please.yml` - current automatic release train, exact gates, direct Hex publish gaps, cleanup/proof dependencies, pinned action versions. [VERIFIED: .github/workflows/release-please.yml]
- `.github/workflows/hex-publish.yml` - current root-only manual Hex recovery. [VERIFIED: .github/workflows/hex-publish.yml]
- `script/check_release_workflow_integrity.exs` - current semantic workflow scanner and extension point. [VERIFIED: script/check_release_workflow_integrity.exs]
- `test/crosswake/proof/phase142_release_integrity_test.exs` - current ExUnit proof wrapper and negative-fixture pattern. [VERIFIED: test/crosswake/proof/phase142_release_integrity_test.exs]
- `release-please-config.json` and `.release-please-manifest.json` - linked core/native group and independent companion version baselines. [VERIFIED: release-please-config.json] [VERIFIED: .release-please-manifest.json]
- Live Hex probes for current package versions on 2026-07-07 - exact release endpoint behavior and current package visibility. [VERIFIED: curl Hex API 2026-07-07]

### Secondary (MEDIUM confidence)

- `https://github.com/googleapis/release-please-action#outputs` - official Release Please action outputs. [CITED: https://github.com/googleapis/release-please-action#outputs]
- `https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax` - official workflow syntax, `workflow_dispatch`, concurrency, and job syntax. [CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax]
- `https://docs.github.com/en/actions/reference/workflows-and-actions/contexts` - official `needs` and `inputs` context behavior. [CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/contexts]
- `https://docs.github.com/en/actions/reference/workflows-and-actions/expressions` - official `contains` and `fromJSON` expression behavior. [CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/expressions]
- `https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html` - official `mix hex.publish` options. [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html]
- `https://hex.pm/docs/faq` - official Hex immutability, replacement/revert windows, and retirement guidance. [CITED: https://hex.pm/docs/faq]
- `https://hex.pm/docs/publish` - official Hex package publishing guide. [CITED: https://hex.pm/docs/publish]
- `https://central.sonatype.org/publish/requirements/immutability/` - official Maven Central immutability and roll-forward guidance. [CITED: https://central.sonatype.org/publish/requirements/immutability/]
- `https://owasp.org/www-project-application-security-verification-standard/` - official ASVS purpose and security-verification standard basis. [CITED: https://owasp.org/www-project-application-security-verification-standard/]

### Tertiary (LOW confidence)

- None used for planning-critical recommendations. [VERIFIED: research process]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - existing workflow pins and local tool versions were verified, and no new package install is recommended. [VERIFIED: .github/workflows/release-please.yml] [VERIFIED: env audit]
- Architecture: HIGH - implementation boundaries come from local workflow code and locked Phase 143 decisions. [VERIFIED: .github/workflows/release-please.yml] [VERIFIED: 143-CONTEXT.md]
- Pitfalls: MEDIUM - Hex/GitHub behavior is from official docs fetched through websearch fallback, and live Hex probes surfaced one registry-state discrepancy for `crosswake_rulestead`/`crosswake_rindle`. [CITED: https://hex.pm/docs/faq] [VERIFIED: curl Hex API 2026-07-07]

**Research date:** 2026-07-07
**Valid until:** 2026-07-14 for GitHub Actions/Hex behavior; local code findings remain valid until the workflow files change. [CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax] [VERIFIED: .github/workflows/release-please.yml]
