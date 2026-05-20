# Phase 12: Packaging Ledger And Release Boundaries - Context

**Gathered:** 2026-05-19
**Status:** Ready for planning

<domain>
## Phase Boundary

Formalize Crosswake's packaging ledger and release-boundary rules so adopters and maintainers can tell what belongs in `core`, what belongs in `companion`, what remains `example/docs-only`, what stays deferred, and what release/rebuild/compatibility choreography follows from each choice. This phase defines package and release truth; it does not widen the shipped capability catalog, promote docs-only surfaces into supported product lanes, or ship provider/storefront implementations.

</domain>

<decisions>
## Implementation Decisions

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

### the agent's Discretion
- Exact table layout and wording for the packaging ledger, as long as the package classes and change classes above remain explicit.
- Exact names of future first-party companions, as long as they stay bounded to the declared `companion` criteria.
- Exact automation mechanism for compatibility and release-matrix generation, as long as the generated output remains authoritative.
- Exact examples used to teach change classes and docs-only graduation criteria, as long as they do not imply broader support than the ledger allows.

</decisions>

<specifics>
## Specific Ideas

- The public packaging story should feel like Phoenix/Hex, not like a JS plugin marketplace.
- The right mental model is: one obvious `crosswake` package, plus a narrow set of explicit first-party companions when binary churn, provider pressure, or operator coupling justifies them.
- Crosswake should learn from Hotwire Native’s separation of bridge components and native screens, Expo’s runtime-version honesty, Tauri’s explicit scoped capabilities, and Capacitor’s plugin-sprawl footguns.
- Release language should answer the adopter’s real question first: “Do I need to rebuild?”, not “Which internal module changed?”
- Docs-only guidance should help users reason about route ownership and package boundaries without accidentally turning advisory examples into support promises.
- Preference is intentionally shifted left within GSD: only decisions with real thesis, support, rebuild, or package-boundary impact should come back to the user.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and Requirements
- `.planning/PROJECT.md` — project thesis, v3.0 milestone framing, and non-goals that Phase 12 must preserve
- `.planning/REQUIREMENTS.md` — `PKG-01`, `PKG-02`, `PKG-03`, support truth gate, proof posture gate, and packaging ledger context
- `.planning/ROADMAP.md` — Phase 12 goal, plan breakdown, and success criteria
- `.planning/STATE.md` — current milestone position and concerns around package boundaries, support honesty, and rebuild expectations

### Prior Locked Decisions
- `.planning/phases/02-manifest-truth-and-compatibility/02-CONTEXT.md` — route-first manifest truth, compatibility axes, and fail-closed posture
- `.planning/phases/03-native-shell-boot-and-bounded-bridge/03-CONTEXT.md` — bounded bridge rules, shell/runtime contract, and explicit native-screen escape hatch principles
- `.planning/phases/05-packs-native-escape-and-proof-lanes/05-CONTEXT.md` — proof lanes, generated-shell verification, and narrow support-backed public artifact posture
- `.planning/phases/06-adopter-profile-matrix-and-pressure-contract/06-CONTEXT.md` — exemplar artifact boundaries and shared proof-host posture
- `.planning/phases/10-cross-profile-hardening-proof-and-guidance/10-CONTEXT.md` — support honesty, rough-edge truth, and docs as product surface
- `.planning/phases/11-capability-taxonomy-and-contract-rubric/11-CONTEXT.md` — package class taxonomy, rebuild truth, and capability-family support posture

### Existing Contract Surfaces
- `guides/capabilities.md` — current package-class rules and example classifications
- `guides/support_matrix.md` — current capability-family support, proof, and rebuild rendering
- `guides/compatibility.md` — canonical compatibility axes and fail-closed activation/bridge posture
- `guides/native_shell.md` — shell contract, route unavailable posture, and native capture escape hatch
- `guides/bridge.md` — bounded bridge contract and command/family boundary
- `guides/adopter_profiles.md` — proof-backed exemplar lane framing that docs/examples must stay coherent with
- `guides/install.md` — install truth and public adopter path expectations

### Existing Code Truth
- `mix.exs` — current single-package release surface
- `lib/crosswake/manifest/types.ex` — compatibility axes, capability metadata, and rebuild/package/proof fields
- `lib/crosswake/manifest/builder.ex` — manifest and capability registry construction seam
- `lib/crosswake/manifest/validator.ex` — typed vocabulary enforcement for package/proof/rebuild truth
- `lib/crosswake/compatibility/compatibility.ex` — canonical compatibility checks and fail-closed evaluation
- `lib/crosswake/bridge/contract.ex` — bounded bridge protocol versioning
- `lib/crosswake/transfer/contracts.ex` — typed versioned transfer seam posture
- `lib/crosswake/bridge/registry.ex` — command/family compatibility seam and bounded allowlist behavior
- `lib/crosswake/support_matrix/support_matrix.ex` — support-matrix state model
- `lib/crosswake/support_matrix/renderer.ex` — current package/proof/rebuild rendering shape
- `lib/mix/tasks/crosswake.doctor.ex` — operator-facing diagnostics as product surface

### Proof and Example Surfaces
- `script/verify_phase5_example_hosts.sh` — checked-in proof-host contract
- `script/verify_generated_ios_shell.sh` — generated-shell proof lane
- `script/verify_generated_android_shell.sh` — generated-shell proof lane
- `examples/phoenix_host/README.md` — current example-host framing and adopter-facing proof artifact posture

### Research and Design Inputs
- `prompts/crosswake-gsd-project-brief.md` — authoritative product framing, package-boundary expectations, and release/proof posture
- `prompts/crosswake-elixir-oss-dna.md` — maintainer house style around install truth, sibling packages, docs, and release discipline
- `prompts/crosswake-integrations-and-companions.md` — companion heuristics and candidate integration surfaces
- `prompts/elixir-mobile-architecture-apptypes-stresstest-deep-research.md` — ecosystem lessons around versioned native/web boundaries, rebuild truth, and capability scoping

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Crosswake.Manifest.Types.Capability`: already carries `package_class`, `proof_class`, and `rebuild`, which Phase 12 can translate into public packaging and change-class policy.
- `Crosswake.Compatibility`: already models `manifest_schema_version`, `bridge_protocol_version`, and `native_runtime_version`, which should anchor the release policy.
- `Crosswake.SupportMatrix.Renderer`: existing generated support surface where packaging and change-class truth can be rendered consistently.
- `mix crosswake.doctor`: existing operator-facing diagnostics seam that can surface package-boundary and rebuild guidance.
- Generated-shell verification scripts: existing proof hooks that can map directly to rebuild-required change classes.

### Established Patterns
- Crosswake keeps route declarations lean and centralizes truth in typed registries and generated docs.
- Fail-closed compatibility and denial behavior are preferred over silent downgrade or fuzzy support.
- Proof-backed support claims are narrow and tied to checked-in example hosts or deterministic scripts.
- Generated host code remains host-owned even when generator logic lives in the library.

### Integration Points
- Packaging ledger publication in guides and support surfaces
- Compatibility and change-class rendering in support-matrix and release docs
- Doctor messaging for rebuild and compatibility guidance
- Future companion metadata declarations and compatibility windows
- Plan-level verification rules tied to change class

</code_context>

<deferred>
## Deferred Ideas

- Publishing standalone shell packages as first-class public package surfaces before compatibility/release choreography is mature
- Promoting docs-only examples into runnable example-host lanes without reclassification and proof
- Broad plugin-market or community-plugin positioning
- Shipping scanner/document-scan or other policy-heavy native families before proof/support posture matures
- Desktop packaging and broad real-time media/call SDK work

</deferred>

---

*Phase: 12-packaging-ledger-and-release-boundaries*
*Context gathered: 2026-05-19*
