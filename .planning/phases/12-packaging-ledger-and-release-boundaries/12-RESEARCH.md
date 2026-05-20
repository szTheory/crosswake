# Phase 12: Packaging Ledger And Release Boundaries - Research

**Researched:** 2026-05-19
**Domain:** Crosswake package classification, release choreography, compatibility signaling, and rebuild policy
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

Source: `.planning/phases/12-packaging-ledger-and-release-boundaries/12-CONTEXT.md` `[VERIFIED: codebase grep - .planning/phases/12-packaging-ledger-and-release-boundaries/12-CONTEXT.md]`

### Locked Decisions

### Packaging ledger shape
- **D-01:** Crosswake should publish one primary public package, `crosswake`, as the default adoption surface. Do not split the base contract across multiple required packages.
- **D-02:** The packaging ledger should enumerate product surfaces by ownership and release burden, not by feature wishlist or plugin-style category.
- **D-03:** `core` includes the route-policy DSL and schema, manifest types/builder/validator, compatibility contract axes, bounded-bridge vocabulary, capability registry metadata, denial/fallback semantics, shell generators/installers, native shell templates, `mix crosswake.doctor`, support-matrix rendering, release-boundary rules, and proof-lane policy.
- **D-04:** Crosswake should treat diagnostics, compatibility guidance, release policy, and proof posture as `core` product surface, not maintenance-only tooling.
- **D-05:** Phoenix-facing commerce vocabulary belongs in `core` only at the normalized seam level: `paywall`, `purchase`, `restore`, and `entitlement_snapshot` as backend-owned, typed contract surfaces.
- **D-06:** Provider/storefront implementations, paywall SDK adapters, and other commerce-provider code belong in `companion`, not `core`.
- **D-07:** Native-binary-heavy, backend/operator-coupled, or provider-sensitive integrations belong in `companion`, including media/upload/capture, rollout/remote config, auth/session integrations, notifications, and audit/operator adapters.
- **D-08:** Checked-in example hosts, exemplar apps, install walkthroughs, reviewer/test-account playbooks, and vendor-specific recipes belong in `example/docs-only`, not runtime package boundaries.
- **D-09:** Standalone public shell packages remain `defer` for now. Crosswake should not publish separately versioned shell artifacts as first-class package surfaces until release choreography and compatibility policy are mature enough to support them honestly.
- **D-10:** Generic plugin-market framing is rejected. Companions must be named, typed, first-party-scoped, and explicitly ledgered.

### Release and versioning policy
- **D-11:** Crosswake should use a hybrid versioning policy: independent SemVer for `core`, each first-party companion, and shell artifacts, combined with explicit compatibility epochs for the canonical runtime contract axes.
- **D-12:** `manifest_schema_version`, `bridge_protocol_version`, and `native_runtime_version` remain the canonical compatibility axes and must be versioned independently from package versions.
- **D-13:** Crosswake should not use repo-wide lockstep versioning across `core`, shells, and future companions.
- **D-14:** Breaking manifest shape changes bump `manifest_schema_version` major and require compatibility-guide, support-matrix, and doctor updates before release.
- **D-15:** Breaking bridge envelope or command semantics bump `bridge_protocol_version` major and require compatible shell artifacts before support claims expand.
- **D-16:** Any change that requires new native code, registration, entitlements, permissions, or packaged runtime behavior must re-target the relevant `native_runtime_version` line and be marked as rebuild-required.
- **D-17:** iOS and Android shell artifacts should publish against the same `native_runtime_version` line even if their platform-specific artifact build numbers differ.
- **D-18:** Capability families keep family-local versions. Additive behavior bumps minor; breaking semantic, authority, or ownership changes bump major.
- **D-19:** Future companions must declare minimum supported ranges for `crosswake` core, `manifest_schema_version`, `bridge_protocol_version`, `native_runtime_version`, and any capability-family majors they expose.
- **D-20:** Support claims come from the generated compatibility/support matrix and doctor output, not from package version numbers alone.

### Rebuild and compatibility rules
- **D-21:** Crosswake should publish one adopter-facing, action-first rule system keyed by required adopter action rather than internal file ownership.
- **D-22:** Freeze exactly four public change classes: `docs-only`, `core-only/no native rebuild`, `compatibility-bump only`, and `native or companion rebuild required`.
- **D-23:** `docs-only` means guides, wording, examples, support notes, or advisory docs changed without changing manifest semantics, compatibility-axis values, capability versions, shell templates, companion integration code, or proof expectations.
- **D-24:** `core-only/no native rebuild` means Elixir/core behavior, docs generation, doctor, support rendering, or manifest validation changed within already-supported manifest schema, bridge protocol, native runtime, and declared capability versions.
- **D-25:** `compatibility-bump only` means Crosswake changed compatibility declarations or package compatibility windows so some older `core`/shell/companion combinations become unsupported or fail closed, but adopters already on a compatible shipped shell/runtime do not necessarily need a fresh binary.
- **D-26:** `native or companion rebuild required` is mandatory whenever shipped native code, generated shell projects, native dependencies, entitlements/permissions, platform config, or companion-native integration code changes.
- **D-27:** Every rebuild-required change also carries a compatibility declaration, but not every compatibility bump requires a rebuild.
- **D-28:** `manifest_schema_version`, `bridge_protocol_version`, `native_runtime_version`, and capability required-version changes must be treated as compatibility signals, not prose-only release notes.
- **D-29:** Tie proof lanes directly to change class:
  - `docs-only` runs docs integrity only
  - `core-only/no native rebuild` runs core contract, manifest, doctor, and support-matrix proof
  - `compatibility-bump only` additionally runs fail-closed compatibility fixtures against older combinations
  - `native or companion rebuild required` additionally runs the affected generated-shell or companion verification lanes
- **D-30:** Proof posture stays asymmetric: hermetic/core proof remains merge-blocking by default, while environment-sensitive lanes remain advisory unless the changed class explicitly widens supported native surface.
- **D-31:** Public release notes, support-matrix rows, and compatibility guide examples must carry the change class so users do not have to infer rebuild expectations from raw version numbers.

### Example/docs-only boundary
- **D-32:** `example/docs-only` surfaces should be published as boundary-first guides, not checked-in runnable example-host lanes.
- **D-33:** Every docs-only surface must state `not first-class supported` near the top and link to its package-class/support posture in `guides/capabilities.md` and `guides/support_matrix.md`.
- **D-34:** Every docs-only guide must include explicit sections for `Route owner`, `Why not core/companion`, `Host-owned responsibilities`, `Prerequisites`, `Denial behavior`, `Fallback behavior`, and `Native rebuild required`.
- **D-35:** Docs-only examples may include route-policy snippets, sequence diagrams, and Phoenix/native pseudocode, but not a fully wired host path presented as a supported recipe.
- **D-36:** The shared example host remains reserved for proof-backed lanes only. Adding a runnable docs-only lane requires reclassification to `core` or `companion` plus proof and support-matrix updates.
- **D-37:** Docs-only surfaces must describe graduation criteria so maintainers and adopters can tell what proof, release policy, and rebuild posture would be required for promotion.
- **D-38:** Crosswake should distinguish three documentation strengths publicly: `supported example`, `companion guidance`, and `docs-only classification`.

### Decision posture for downstream GSD agents
- **D-39:** Shift normal package-class, release-note, support-matrix-detail, and guide-structure choices left within GSD. Downstream agents should make principled defaults without re-asking unless a decision materially changes the project thesis, package boundaries, support claims, backend-truth posture, or rebuild burden.
- **D-40:** When uncertain, downstream agents should prefer the least-surprising, support-honest choice: keep `core` lean, preserve fail-closed behavior, avoid silent promotion of examples into promises, and bias toward explicit companion boundaries for native/provider-heavy surfaces.

### Claude's Discretion
- Exact table layout and wording for the packaging ledger, as long as the package classes and change classes above remain explicit.
- Exact names of future first-party companions, as long as they stay bounded to the declared `companion` criteria.
- Exact automation mechanism for compatibility and release-matrix generation, as long as the generated output remains authoritative.
- Exact examples used to teach change classes and docs-only graduation criteria, as long as they do not imply broader support than the ledger allows.

### Deferred Ideas (OUT OF SCOPE)
- Publishing standalone shell packages as first-class public package surfaces before compatibility/release choreography is mature
- Promoting docs-only examples into runnable example-host lanes without reclassification and proof
- Broad plugin-market or community-plugin positioning
- Shipping scanner/document-scan or other policy-heavy native families before proof/support posture matures
- Desktop packaging and broad real-time media/call SDK work
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PKG-01 | Phoenix teams can see a published packaging ledger that classifies major Crosswake surfaces as `core`, `companion`, `example/docs-only`, or `defer`. | Packaging ledger should derive from the existing capability/package metadata, support-matrix output, and guide surfaces instead of inventing a second source of truth. `[VERIFIED: codebase grep - lib/crosswake/manifest/types.ex][VERIFIED: codebase grep - lib/crosswake/support_matrix/renderer.ex][VERIFIED: codebase grep - guides/capabilities.md]` |
| PKG-02 | Maintainers can follow one documented release and versioning policy for companion-ready future work without breaking manifest, shell, or support truth. | Use independent SemVer for packages plus the existing compatibility axes as the real runtime contract. `[VERIFIED: codebase grep - lib/crosswake/compatibility/compatibility.ex][CITED: https://hex.pm/docs/publish][CITED: https://semver.org/]` |
| PKG-03 | Adopters can tell when a capability or companion change requires a native rebuild, compatibility bump, or docs-only update. | Reuse current `rebuild`, `package_class`, `proof_class`, and proof-hook surfaces; add one explicit change-class policy rendered into guides and doctor/support outputs. `[VERIFIED: codebase grep - lib/crosswake/manifest/types.ex][VERIFIED: codebase grep - script/verify_phase5_example_hosts.sh][VERIFIED: codebase grep - lib/mix/tasks/crosswake.doctor.ex]` |
</phase_requirements>

## Summary

Phase 12 should be planned as a contract-publication phase, not a packaging refactor. The repo already has the canonical primitives needed for package and release truth: capability entries carry `package_class`, `proof_class`, and `rebuild`; compatibility truth is already split into `manifest_schema_version`, `bridge_protocol_version`, and `native_runtime_version`; support output is already rendered from typed state; and `mix crosswake.doctor` is already the operator-facing contract surface. `[VERIFIED: codebase grep - lib/crosswake/manifest/types.ex][VERIFIED: codebase grep - lib/crosswake/compatibility/compatibility.ex][VERIFIED: codebase grep - lib/crosswake/support_matrix/renderer.ex][VERIFIED: codebase grep - lib/mix/tasks/crosswake.doctor.ex]`

The plan should therefore avoid creating new runtime abstractions or extra packages now. Instead, it should publish one machine-readable and guide-visible ledger that answers three questions consistently: what class each surface belongs to, which compatibility axis changes when that surface changes, and what adopter action follows from that change. `[VERIFIED: codebase grep - .planning/phases/12-packaging-ledger-and-release-boundaries/12-CONTEXT.md][CITED: https://docs.expo.dev/eas-update/runtime-versions/][CITED: https://v2.tauri.app/security/capabilities/]`

The main planning risk is source-of-truth drift. If Phase 12 adds a handwritten release policy disconnected from manifest/support/doctor truth, later capability and commerce work will fork the product contract. The phase should instead centralize change-class policy in code-backed metadata and render it into `guides/support_matrix.md`, `guides/compatibility.md`, release notes, and doctor output. `[VERIFIED: codebase grep - test/crosswake/support_matrix/renderer_test.exs][VERIFIED: codebase grep - guides/support_matrix.md][VERIFIED: codebase grep - guides/compatibility.md]`

**Primary recommendation:** Use the existing manifest/support/doctor seams as the single source of package and release truth, and add one explicit change-class ledger keyed to adopter action: `docs-only`, `core-only/no native rebuild`, `compatibility-bump only`, and `native or companion rebuild required`. `[VERIFIED: codebase grep - .planning/phases/12-packaging-ledger-and-release-boundaries/12-CONTEXT.md][VERIFIED: codebase grep - lib/crosswake/manifest/types.ex]`

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Package classification ledger | API / Backend | Frontend Server (SSR) | Crosswake’s package truth is compiled and rendered from Elixir manifest/support structures, not from shell code. `[VERIFIED: codebase grep - lib/crosswake/manifest/builder.ex][VERIFIED: codebase grep - lib/crosswake/support_matrix/support_matrix.ex]` |
| Compatibility-axis policy | API / Backend | Database / Storage | Compatibility is evaluated in Elixir against manifest/runtime declarations before route activation or bridge execution. `[VERIFIED: codebase grep - lib/crosswake/compatibility/compatibility.ex]` |
| Rebuild/change-class guidance | API / Backend | Browser / Client | The guidance should be computed from typed contract truth, then surfaced in docs and diagnostics for adopters. `[VERIFIED: codebase grep - lib/mix/tasks/crosswake.doctor.ex][VERIFIED: codebase grep - guides/install.md]` |
| Shell-proof execution | Frontend Server (SSR) | Browser / Client | The public proof lane is orchestrated from the repo, then delegated into iOS and Android shell scripts. `[VERIFIED: codebase grep - script/verify_phase5_example_hosts.sh][VERIFIED: codebase grep - script/verify_generated_ios_shell.sh][VERIFIED: codebase grep - script/verify_generated_android_shell.sh]` |
| Docs-only boundary publication | Frontend Server (SSR) | API / Backend | The docs are static markdown, but they should be generated or mechanically aligned with code-backed support truth. `[VERIFIED: codebase grep - lib/crosswake/support_matrix/renderer.ex][VERIFIED: codebase grep - test/crosswake/guides/capabilities_test.exs]` |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `crosswake` | `0.1.0` | Primary public package surface | The repo is already a single Hex package and Phase 12 explicitly keeps one obvious public package. `[VERIFIED: codebase grep - mix.exs][VERIFIED: codebase grep - .planning/phases/12-packaging-ledger-and-release-boundaries/12-CONTEXT.md]` |
| `phoenix` | `1.8.7` | Host baseline for install, manifest generation, and support matrix | Current support truth and tests assume one narrow Phoenix baseline. `[VERIFIED: hex registry via mix hex.info phoenix][VERIFIED: codebase grep - lib/crosswake/support_matrix/support_matrix.ex]` |
| `phoenix_live_view` | `1.1.30` | Server-owned route baseline | Current support truth and install/docs posture keep LiveView route ownership explicit. `[VERIFIED: hex registry via mix hex.info phoenix_live_view][VERIFIED: codebase grep - guides/support_matrix.md]` |
| `jason` | `1.4.5` | JSON manifest serialization surface | Manifest and install artifacts are JSON-backed and already part of the packaging contract. `[VERIFIED: hex registry via mix hex.info jason][VERIFIED: codebase grep - mix.exs]` |
| `nimble_options` | `1.1.1` | Typed option validation utility in current package stack | Keep current lightweight validation tooling; this phase does not need a new config framework. `[VERIFIED: hex registry via mix hex.info nimble_options][VERIFIED: codebase grep - mix.exs]` |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `Mix` | `1.19.5` | Publish tasks, custom doctor task, package workflow | Use for `mix crosswake.doctor` and any release helper task added in this phase. `[VERIFIED: local tool - mix --version][CITED: https://hexdocs.pm/mix/Mix.Task.html]` |
| `Hex` | `2.2.1` | Package publishing and docs publication contract | Use if Phase 12 adds release instructions or dry-run publish checks. `[CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html][CITED: https://hex.pm/docs/publish]` |
| `ExUnit` | bundled with Elixir 1.19.5 | Contract, renderer, and docs-alignment tests | Reuse for new change-class and docs-contract tests. `[VERIFIED: codebase grep - test/crosswake/support_matrix/renderer_test.exs][VERIFIED: local tool - elixir --version]` |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Independent package SemVer plus compatibility axes | Repo-wide lockstep versions | Lockstep hides whether a release needs a rebuild; the existing repo already treats compatibility axes separately. `[VERIFIED: codebase grep - lib/crosswake/compatibility/compatibility.ex][CITED: https://semver.org/]` |
| One primary `crosswake` package plus explicit first-party companions later | Immediate multi-package split | A premature split would duplicate contract surfaces before release choreography is mature. `[VERIFIED: codebase grep - .planning/phases/12-packaging-ledger-and-release-boundaries/12-CONTEXT.md]` |
| Generated support/docs from typed state | Handwritten package-policy markdown | Handwritten policy will drift from manifest/support tests that already exist. `[VERIFIED: codebase grep - lib/crosswake/support_matrix/renderer.ex][VERIFIED: codebase grep - test/crosswake/support_matrix/renderer_test.exs]` |

**Installation:**
```bash
mix deps.get
```

**Version verification:** Current package versions were verified with `mix hex.info phoenix`, `mix hex.info phoenix_live_view`, `mix hex.info jason`, and `mix hex.info nimble_options` on 2026-05-19. `[VERIFIED: hex registry via mix hex.info phoenix][VERIFIED: hex registry via mix hex.info phoenix_live_view][VERIFIED: hex registry via mix hex.info jason][VERIFIED: hex registry via mix hex.info nimble_options]`

## Architecture Patterns

### System Architecture Diagram
```text
Route policy / capability metadata
        |
        v
Manifest builder -> capability registry + pack registry + compatibility truth
        |                                         |
        |                                         v
        |                                 change-class classifier
        |                                         |
        v                                         v
support matrix canonical ----------------> generated guides / doctor / release notes
        |                                         |
        v                                         v
compatibility checks --------------------> proof-lane selection by change class
        |
        v
adopter answer: docs-only / no rebuild / compatibility bump / rebuild required
```
Diagram rationale: manifest/support/compatibility are already centralized in Elixir, and proof hooks already branch into example-host, iOS, and Android lanes. `[VERIFIED: codebase grep - lib/crosswake/manifest/builder.ex][VERIFIED: codebase grep - lib/crosswake/support_matrix/support_matrix.ex][VERIFIED: codebase grep - script/verify_phase5_example_hosts.sh]`

### Recommended Project Structure
```text
lib/
├── crosswake/manifest/          # Typed package/support/change metadata
├── crosswake/compatibility/     # Compatibility-axis evaluation
├── crosswake/support_matrix/    # Canonical support and rendered publication
└── mix/tasks/                   # Operator-facing diagnostics and release helpers
guides/
├── capabilities.md              # Package-class explanations
├── compatibility.md             # Compatibility-axis and rebuild policy
└── support_matrix.md            # Generated support/package/rebuild ledger
script/
└── verify_*.sh                  # Proof lanes selected by change class
test/
└── crosswake/...                # Renderer, validator, doctor, compatibility, proof tests
```

### Pattern 1: Keep package and release truth in typed manifest/support state
**What:** Extend existing typed metadata rather than inventing a new packaging-policy file format. `[VERIFIED: codebase grep - lib/crosswake/manifest/types.ex]`
**When to use:** For package class, change class, minimum compatible ranges, and rebuild signaling. `[VERIFIED: codebase grep - .planning/phases/12-packaging-ledger-and-release-boundaries/12-CONTEXT.md]`
**Example:**
```elixir
# Source: lib/crosswake/manifest/types.ex
defstruct [
  :id,
  :version,
  :family,
  :owner,
  :package_class,
  :proof_class,
  :rebuild,
  :denial,
  :fallback,
  :guide
]
```

### Pattern 2: Treat compatibility axes as runtime truth, not release-note prose
**What:** Keep `manifest_schema_version`, `bridge_protocol_version`, and `native_runtime_version` authoritative and independent from package version numbers. `[VERIFIED: codebase grep - lib/crosswake/compatibility/compatibility.ex][CITED: https://docs.expo.dev/eas-update/runtime-versions/]`
**When to use:** Whenever a change modifies manifest shape, bridge semantics, or native binary behavior. `[VERIFIED: codebase grep - guides/compatibility.md]`
**Example:**
```elixir
# Source: lib/crosswake/compatibility/compatibility.ex
[]
|> validate_contract_version(compatibility, :manifest_schema_version)
|> validate_contract_version(compatibility, :bridge_protocol_version)
|> validate_contract_version(compatibility, :native_runtime_version)
```

### Pattern 3: Render adopter-facing truth from one canonical renderer
**What:** Use deterministic markdown rendering for the package/rebuild ledger just like the support matrix already does. `[VERIFIED: codebase grep - lib/crosswake/support_matrix/renderer.ex]`
**When to use:** For `guides/support_matrix.md`, package ledger pages, and any compatibility-release summary generated from code. `[VERIFIED: codebase grep - guides/support_matrix.md]`
**Example:**
```elixir
# Source: lib/crosswake/support_matrix/renderer.ex
"| Family | Owner | Package | Proof | Rebuild | Prerequisites | Denial | Fallback | Guide |"
```

### Pattern 4: Select proof by change class, not by file-path intuition
**What:** The public question is “what do I need to rerun?” not “which module changed?”. `[VERIFIED: codebase grep - .planning/phases/12-packaging-ledger-and-release-boundaries/12-CONTEXT.md]`
**When to use:** When writing release policy, CI notes, doctor guidance, and plan verification steps. `[VERIFIED: codebase grep - script/verify_phase5_example_hosts.sh][VERIFIED: codebase grep - script/verify_generated_ios_shell.sh][VERIFIED: codebase grep - script/verify_generated_android_shell.sh]`
**Example:**
```text
docs-only -> docs integrity tests
core-only/no native rebuild -> ExUnit manifest/compatibility/doctor/support tests
compatibility-bump only -> add fail-closed older-combination fixtures
native or companion rebuild required -> run example-host + affected generated-shell/companion lanes
```

### Anti-Patterns to Avoid
- **Lockstep version theater:** Do not imply that one package version alone tells adopters whether they need a rebuild. `[CITED: https://semver.org/][CITED: https://docs.expo.dev/eas-update/runtime-versions/]`
- **Second source of truth:** Do not hand-maintain a release matrix separate from manifest/support/doctor state. `[VERIFIED: codebase grep - test/crosswake/support_matrix/renderer_test.exs]`
- **Example escalation by accident:** Do not let docs-only examples become runnable proof lanes without reclassification. `[VERIFIED: codebase grep - examples/phoenix_host/README.md][VERIFIED: codebase grep - .planning/phases/12-packaging-ledger-and-release-boundaries/12-CONTEXT.md]`

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Package versioning policy | Custom version semantics | SemVer for package versions | Hex requires SemVer for published packages, and the policy is widely understood. `[CITED: https://hex.pm/docs/publish][CITED: https://semver.org/]` |
| Native/update compatibility signaling | Ad hoc release-note text | Explicit runtime compatibility axes | Expo’s runtime-version model and Crosswake’s own compatibility module both separate native compatibility from package versioning. `[CITED: https://docs.expo.dev/eas-update/runtime-versions/][VERIFIED: codebase grep - lib/crosswake/compatibility/compatibility.ex]` |
| Scoped capability exposure | Generic plugin bus framing | Explicit family/package/guide metadata | Tauri’s capability model and Crosswake’s family metadata both show that scoped exposure beats broad plugin surfaces. `[CITED: https://v2.tauri.app/security/capabilities/][VERIFIED: codebase grep - lib/crosswake/manifest/types.ex]` |
| Release ledger rendering | Manual markdown tables | Existing deterministic support-matrix renderer pattern | The renderer already supports mechanical alignment and tests. `[VERIFIED: codebase grep - lib/crosswake/support_matrix/renderer.ex][VERIFIED: codebase grep - test/crosswake/support_matrix/renderer_test.exs]` |

**Key insight:** Phase 12 is mainly about refusing to hand-roll narrative policy outside the typed contract surfaces that already exist. `[VERIFIED: codebase grep - lib/crosswake/manifest/types.ex][VERIFIED: codebase grep - lib/crosswake/support_matrix/support_matrix.ex]`

## Common Pitfalls

### Pitfall 1: Treating package version as the compatibility contract
**What goes wrong:** A package bump looks “safe” even when the native runtime or bridge contract changed. `[CITED: https://docs.expo.dev/eas-update/runtime-versions/][VERIFIED: codebase grep - guides/compatibility.md]`
**Why it happens:** Package SemVer and runtime compatibility solve different problems. `[CITED: https://semver.org/][CITED: https://hex.pm/docs/publish]`
**How to avoid:** Keep package versions independent and force release notes, support rows, and doctor output to name the changed compatibility axis. `[VERIFIED: codebase grep - .planning/phases/12-packaging-ledger-and-release-boundaries/12-CONTEXT.md]`
**Warning signs:** Release notes say “minor update” but never say whether `manifest_schema_version`, `bridge_protocol_version`, or `native_runtime_version` changed. `[VERIFIED: codebase grep - guides/compatibility.md]`

### Pitfall 2: Publishing docs-only guidance like supported product surface
**What goes wrong:** Adopters treat advisory examples as promises, especially if they show runnable host wiring. `[VERIFIED: codebase grep - examples/phoenix_host/README.md][VERIFIED: codebase grep - guides/capabilities.md]`
**Why it happens:** The checked-in example host is already a proof artifact, so docs can accidentally inherit that authority. `[VERIFIED: codebase grep - guides/install.md][VERIFIED: codebase grep - script/verify_phase5_example_hosts.sh]`
**How to avoid:** Require docs-only pages to declare `not first-class supported`, avoid runnable host lanes, and state graduation criteria. `[VERIFIED: codebase grep - .planning/phases/12-packaging-ledger-and-release-boundaries/12-CONTEXT.md]`
**Warning signs:** A docs-only surface needs shell/project files or appears in example-host proof scripts. `[VERIFIED: codebase grep - script/verify_phase5_example_hosts.sh]`

### Pitfall 3: Choosing proof by changed file instead of changed adopter action
**What goes wrong:** Maintainers either under-test a rebuild-required change or over-test a docs-only edit. `[ASSUMED]`
**Why it happens:** File ownership does not map cleanly to whether adopters need a rebuild. `[VERIFIED: codebase grep - .planning/phases/12-packaging-ledger-and-release-boundaries/12-CONTEXT.md]`
**How to avoid:** Classify the change first, then map to proof lanes. `[VERIFIED: codebase grep - .planning/phases/12-packaging-ledger-and-release-boundaries/12-CONTEXT.md]`
**Warning signs:** CI guidance names modules or directories but never names `docs-only`, `compatibility-bump only`, or `rebuild required`. `[ASSUMED]`

### Pitfall 4: Letting release policy fork from doctor/support output
**What goes wrong:** Public docs, diagnostics, and code disagree about whether a surface is supported or rebuild-required. `[VERIFIED: codebase grep - lib/mix/tasks/crosswake.doctor.ex][VERIFIED: codebase grep - guides/support_matrix.md]`
**Why it happens:** Policy gets documented manually in too many places. `[VERIFIED: codebase grep - test/crosswake/support_matrix/renderer_test.exs]`
**How to avoid:** Render all public support/change truth from canonical typed state and test exact guide alignment. `[VERIFIED: codebase grep - lib/crosswake/support_matrix/renderer.ex][VERIFIED: codebase grep - test/crosswake/support_matrix/renderer_test.exs]`
**Warning signs:** A guide edit cannot be traced back to a manifest/support metadata change or a test. `[ASSUMED]`

## Code Examples

Verified patterns from official and code sources:

### Manifest-backed capability metadata
```elixir
# Source: lib/crosswake/manifest/builder.ex
[
  id: "media_capture",
  family: "media_capture",
  owner: :native_screen,
  package_class: :companion,
  proof_class: :merge_blocking,
  rebuild: :native_required,
  prerequisites: ["native screen route", "capture pack availability"],
  denial: "pack_incompatible",
  fallback: "fail closed instead of degrading into a bounded web upload flow",
  guide: "guides/native_shell.md#native-capture-escape-hatch"
]
```

### Deterministic support rendering
```elixir
# Source: lib/crosswake/support_matrix/support_matrix.ex
Types.new_capability_support_entry(
  family: capability.family,
  owner: capability.owner,
  package_class: capability.package_class,
  proof_class: capability.proof_class,
  rebuild: capability.rebuild,
  prerequisites: capability.prerequisites,
  denial: capability.denial,
  fallback: capability.fallback,
  guide: capability.guide
)
```

### Public proof lane fan-out
```bash
# Source: script/verify_phase5_example_hosts.sh
mix test \
  test/mix/tasks/crosswake_install_test.exs \
  test/crosswake/proof/phase5_proof_lane_test.exs \
  test/crosswake/proof/adopter_profile_contract_test.exs \
  test/crosswake/proof/phase7_saas_lane_test.exs \
  test/crosswake/proof/phase8_selective_native_lane_test.exs \
  test/crosswake/proof/phase9_local_first_lane_test.exs
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| One package version stands in for all compatibility truth | Package SemVer plus separate manifest/bridge/native runtime axes | Current official ecosystem guidance still distinguishes package versioning from runtime compatibility. `[CITED: https://hex.pm/docs/publish][CITED: https://docs.expo.dev/eas-update/runtime-versions/]` | Lets Crosswake say “rebuild required” or “compatibility bump only” explicitly. `[VERIFIED: codebase grep - guides/compatibility.md]` |
| Broad plugin framing | Scoped capability/companion boundaries | Tauri v2 capability docs and Crosswake Phase 11 both prefer scoped exposure. `[CITED: https://v2.tauri.app/security/capabilities/][VERIFIED: codebase grep - guides/capabilities.md]` | Supports the thesis that Crosswake is Phoenix-first contract infrastructure, not a plugin bus. `[VERIFIED: codebase grep - AGENTS.md][VERIFIED: codebase grep - .planning/PROJECT.md]` |
| Handwritten support policy | Generated support output with guide tests | Already present in current repo. `[VERIFIED: codebase grep - lib/crosswake/support_matrix/renderer.ex][VERIFIED: codebase grep - test/crosswake/support_matrix/renderer_test.exs]` | Phase 12 should extend the renderer instead of adding another manual ledger. `[VERIFIED: codebase grep - guides/support_matrix.md]` |

**Deprecated/outdated:**
- Repo-wide lockstep versioning for core, shells, and future companions is the wrong model for this phase. `[VERIFIED: codebase grep - .planning/phases/12-packaging-ledger-and-release-boundaries/12-CONTEXT.md]`
- Publishing standalone shell packages now is deferred. `[VERIFIED: codebase grep - .planning/phases/12-packaging-ledger-and-release-boundaries/12-CONTEXT.md]`

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Proof-lane over/under-testing is a likely maintainer failure mode if change classes are not explicit. | Common Pitfalls 3 | Medium: plan may overweight or underweight CI mapping work. |
| A2 | Drift warning signs include guide edits without metadata/test changes. | Common Pitfalls 4 | Low: verification policy may need different heuristics. |

## Open Questions (RESOLVED)

1. **Where should change-class policy live?**
   - **Resolution:** Change-class policy should live in typed support-matrix policy metadata and renderer-backed guide output, not as new per-route manifest truth and not as a detached handwritten release-policy file.
   - **Why:** The repo already centralizes public support truth in `Crosswake.SupportMatrix` and `Crosswake.SupportMatrix.Renderer`, while manifest capability entries already supply the lower-level `package_class`, `proof_class`, and `rebuild` inputs that change-class policy derives from. This keeps one authoritative publication path and avoids widening the manifest with adopter-action policy that is not route activation truth. `[VERIFIED: codebase grep - lib/crosswake/manifest/types.ex][VERIFIED: codebase grep - lib/crosswake/support_matrix/support_matrix.ex][VERIFIED: codebase grep - lib/crosswake/support_matrix/renderer.ex]`
   - **Planning implication:** Phase 12 plans should add typed policy entries under support-matrix truth plus guide parity tests, and only extend manifest types as needed for shared typed structs used by support-matrix policy rendering.

2. **Should doctor surface package/change-class guidance in Phase 12?**
   - **Resolution:** Yes, but narrowly. Phase 12 should surface minimal release/versioning policy in doctor output during Plan `12-02`, while leaving richer support UX and denial-detail expansion to Phase 14.
   - **Why:** D-03, D-04, D-14, and D-20 already treat `mix crosswake.doctor` as part of the core contract and require doctor alignment when compatibility policy changes. At the same time, PKG-03 is adopter-facing rebuild/change-class publication work, so doctor does not need to own that broader workflow in Phase 12. `[VERIFIED: codebase grep - .planning/phases/12-packaging-ledger-and-release-boundaries/12-CONTEXT.md][VERIFIED: codebase grep - lib/mix/tasks/crosswake.doctor.ex][VERIFIED: codebase grep - test/mix/tasks/crosswake_doctor_test.exs]`
   - **Planning implication:** Keep doctor work in `12-02` limited to hybrid versioning and compatibility-axis policy. Keep `12-03` focused on typed change-class truth plus public guide publication/testing, without additional doctor-output scope.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Manifest/support/doctor tests | ✓ | `1.19.5` | — |
| Mix | Release helper tasks and tests | ✓ | `1.19.5` | — |
| Xcode / `xcodebuild` | iOS generated-shell proof lane | ✓ | `26.0.1` | — |
| `adb` | Android proof lane execution | ✗ direct | — | Android script bootstraps tooling. `[VERIFIED: codebase grep - script/verify_generated_android_shell.sh]` |
| `sdkmanager` | Android proof lane execution | ✗ direct | — | Android script bootstraps command-line tools. `[VERIFIED: codebase grep - script/verify_generated_android_shell.sh]` |
| Java runtime | Android Gradle / emulator lane | ✗ direct | — | Android script installs or discovers JDK 17. `[VERIFIED: codebase grep - script/verify_generated_android_shell.sh]` |
| Node.js | Ancillary tooling only | ✓ | `v22.14.0` | — |

**Missing dependencies with no fallback:**
- None for Phase 12 planning work. `[VERIFIED: local tool audit - elixir/mix/xcodebuild present]`

**Missing dependencies with fallback:**
- Android local tooling is absent, but `script/verify_generated_android_shell.sh` provisions JDK and Android command-line tools before running Gradle and emulator tests. `[VERIFIED: local tool audit - adb/sdkmanager/java missing][VERIFIED: codebase grep - script/verify_generated_android_shell.sh]`

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | This phase does not add auth flows; auth/provider integrations stay companion or deferred. `[VERIFIED: codebase grep - guides/capabilities.md][VERIFIED: codebase grep - .planning/REQUIREMENTS.md]` |
| V3 Session Management | no | No session-state feature work is in scope. `[VERIFIED: codebase grep - .planning/ROADMAP.md]` |
| V4 Access Control | yes | Keep route allowlists, capability allowlists, origin checks, and package boundaries fail-closed. `[VERIFIED: codebase grep - lib/crosswake/compatibility/compatibility.ex][VERIFIED: codebase grep - lib/crosswake/bridge/registry.ex]` |
| V5 Input Validation | yes | Validator-enforced vocabularies for capability/package/proof/rebuild metadata. `[VERIFIED: codebase grep - lib/crosswake/manifest/validator.ex]` |
| V6 Cryptography | no | No new crypto surface is introduced in this phase. `[VERIFIED: codebase grep - .planning/ROADMAP.md]` |

### Known Threat Patterns for Crosswake packaging/release policy

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Silent support widening through docs or examples | Tampering | Render support/package truth from code and gate with guide-alignment tests. `[VERIFIED: codebase grep - lib/crosswake/support_matrix/renderer.ex][VERIFIED: codebase grep - test/crosswake/support_matrix/renderer_test.exs]` |
| Native/runtime mismatch hidden behind a package bump | Tampering | Keep compatibility axes explicit and fail closed on mismatches. `[VERIFIED: codebase grep - lib/crosswake/compatibility/compatibility.ex][CITED: https://docs.expo.dev/eas-update/runtime-versions/]` |
| Overexposed companion/plugin authority | Elevation of privilege | Preserve scoped family/package boundaries and explicit route ownership. `[VERIFIED: codebase grep - guides/capabilities.md][CITED: https://v2.tauri.app/security/capabilities/]` |
| Remote update overreach | Tampering | Restrict remote updates to versioned replacement or versioned companion data. `[VERIFIED: codebase grep - lib/crosswake/compatibility/compatibility.ex][VERIFIED: codebase grep - guides/compatibility.md]` |

## Sources

### Primary (HIGH confidence)
- `lib/crosswake/manifest/types.ex` - capability/package/proof/rebuild typed contract `[VERIFIED: codebase grep - lib/crosswake/manifest/types.ex]`
- `lib/crosswake/manifest/builder.ex` - canonical capability catalog and current package/rebuild truth `[VERIFIED: codebase grep - lib/crosswake/manifest/builder.ex]`
- `lib/crosswake/manifest/validator.ex` - fail-closed vocabulary enforcement `[VERIFIED: codebase grep - lib/crosswake/manifest/validator.ex]`
- `lib/crosswake/compatibility/compatibility.ex` - canonical compatibility axes and remote-update constraints `[VERIFIED: codebase grep - lib/crosswake/compatibility/compatibility.ex]`
- `lib/crosswake/support_matrix/support_matrix.ex` - narrow baseline and capability-family support derivation `[VERIFIED: codebase grep - lib/crosswake/support_matrix/support_matrix.ex]`
- `lib/crosswake/support_matrix/renderer.ex` - deterministic markdown rendering surface `[VERIFIED: codebase grep - lib/crosswake/support_matrix/renderer.ex]`
- `lib/mix/tasks/crosswake.doctor.ex` - operator-facing diagnostics surface `[VERIFIED: codebase grep - lib/mix/tasks/crosswake.doctor.ex]`
- `guides/capabilities.md`, `guides/support_matrix.md`, `guides/compatibility.md`, `guides/install.md` - current public contract wording `[VERIFIED: codebase grep - guides/capabilities.md][VERIFIED: codebase grep - guides/support_matrix.md][VERIFIED: codebase grep - guides/compatibility.md][VERIFIED: codebase grep - guides/install.md]`
- `script/verify_phase5_example_hosts.sh`, `script/verify_generated_ios_shell.sh`, `script/verify_generated_android_shell.sh` - proof-lane boundaries and environment sensitivity `[VERIFIED: codebase grep - script/verify_phase5_example_hosts.sh][VERIFIED: codebase grep - script/verify_generated_ios_shell.sh][VERIFIED: codebase grep - script/verify_generated_android_shell.sh]`
- `mix.exs` and `mix hex.info` outputs - current package and dependency versions `[VERIFIED: codebase grep - mix.exs][VERIFIED: hex registry via mix hex.info phoenix][VERIFIED: hex registry via mix hex.info phoenix_live_view][VERIFIED: hex registry via mix hex.info jason][VERIFIED: hex registry via mix hex.info nimble_options]`
- https://hex.pm/docs/publish - Hex publish/package metadata rules `[CITED: https://hex.pm/docs/publish]`
- https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html - current Hex task behavior, dry-run, docs publication, revert window `[CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html]`
- https://semver.org/ - SemVer specification `[CITED: https://semver.org/]`
- https://docs.expo.dev/eas-update/runtime-versions/ - runtime version and rebuild guidance `[CITED: https://docs.expo.dev/eas-update/runtime-versions/]`
- https://v2.tauri.app/security/capabilities/ - scoped capabilities and security-boundary framing `[CITED: https://v2.tauri.app/security/capabilities/]`

### Secondary (MEDIUM confidence)
- None.

### Tertiary (LOW confidence)
- None beyond explicitly tagged assumptions.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - versions and current stack were verified from `mix.exs`, `mix --version`, and Hex registry queries. `[VERIFIED: codebase grep - mix.exs][VERIFIED: local tool - mix --version][VERIFIED: hex registry via mix hex.info phoenix]`
- Architecture: HIGH - release/package policy can reuse existing manifest, compatibility, renderer, guide, doctor, and proof seams already in the repo. `[VERIFIED: codebase grep - lib/crosswake/manifest/builder.ex][VERIFIED: codebase grep - lib/crosswake/compatibility/compatibility.ex][VERIFIED: codebase grep - script/verify_phase5_example_hosts.sh]`
- Pitfalls: MEDIUM - most are grounded in current repo seams and official runtime/package guidance, but two warning-sign heuristics remain assumptions. `[CITED: https://docs.expo.dev/eas-update/runtime-versions/][CITED: https://semver.org/][ASSUMED]`

**Research date:** 2026-05-19
**Valid until:** 2026-06-18
