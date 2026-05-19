# Phase 11: Capability Taxonomy And Contract Rubric - Research

**Researched:** 2026-05-19
**Domain:** Phoenix-first capability taxonomy, manifest metadata, and support-truth classification for hybrid mobile contracts
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
Verbatim copy from `.planning/phases/11-capability-taxonomy-and-contract-rubric/11-CONTEXT.md`. [VERIFIED: 11-CONTEXT.md]

### Taxonomy shape
- **D-01:** Crosswake capability taxonomy is family-first and route-owner-aware. Public capability ids should name stable semantic families such as `haptics`, `share`, `app_info`, `deep_link`, `permissions.status`, `notification_token`, `media_capture`, `scanner`, `document_scan`, `paywall`, `purchase`, `restore`, and `entitlement_snapshot`, not generic plugin buckets or raw bridge command ids.
- **D-02:** Bridge commands remain operation-level protocol details under a family, not the primary public taxonomy. Example: `haptics` is the family; `haptics.impact` is a command.
- **D-03:** Crosswake should not publish umbrella/plugin-shaped capability buckets such as `device`, `media`, `payments`, `bridge`, or `native`. Those names hide ownership differences and make support truth dishonest.
- **D-04:** The public classification model should stay separate across two axes:
  - capability family taxonomy
  - route-owner/package/support classification metadata
- **D-05:** Package classification remains distinct from runtime ownership. `core`, `companion`, `example/docs-only`, and `defer` describe packaging and support posture, not which runtime owns a route interaction.

### Ownership rubric
- **D-06:** Crosswake should use a ladder-first ownership rubric as the primary public rule. Start by asking who must own the interaction loop on the route, not by asking what API shape looks convenient.
- **D-07:** Classify a family as `bounded_bridge` only when the route remains Phoenix-owned and the native action is low-frequency, semantic, request/reply, and non-authoritative.
- **D-08:** Classify a family as `native_screen` when native code must own the interaction loop, permission choreography, capture/scan session, or platform-specific UI fidelity.
- **D-09:** Classify a family as `backend_seam` or `defer` when the surface is primarily control-plane, provider-coupled, background-heavy, review-sensitive, or would require Crosswake to pretend route-local bridge calls own backend truth.
- **D-10:** Use a capability-scoring checklist only as an internal maintainer backstop, not as the public-facing primary rubric. The public rule should stay simple and ownership-first.
- **D-11:** Use a native-risk veto layer for policy-heavy or sensitive families. If a family materially depends on storefront rules, auth/browser policy, background delivery, scanner/camera loops, or audit/regulatory posture, bias toward `native_screen`, `companion`, or `defer`.
- **D-12:** Deep-link handling remains manifest-first shell activation truth, not a generic JS/native bridge authority. Route-local deep-link metadata may exist, but link resolution belongs to shell activation.

### Classification rules for candidate families
- **D-13:** `haptics`, `share`, `app_info`, `permissions.status`, and `notification_token` are the model bounded-bridge families.
- **D-14:** `media_capture`, `scanner`, and `document_scan` are native-screen-first families because they imply session loops, frequent native state, and stronger device/policy variance.
- **D-15:** `rollout`, `auth`, `audit`, and notification delivery providers stay Phoenix/backend seams rather than route-local bridge authority. Crosswake may later support them through companions or docs, but not as core bridge-owned families.
- **D-16:** Commerce family names such as `paywall`, `purchase`, `restore`, and `entitlement_snapshot` are valid taxonomy entries, but their core seam and provider boundaries remain milestone work centered in Phase 13 rather than full public capability support in Phase 11.

### Manifest and support metadata
- **D-17:** Phase 11 should use a manifest-primary capability contract with generated support output. Route entries stay lean and route-local; capability-family truth lives on capability registry entries.
- **D-18:** Extend the manifest capability registry with typed metadata that answers:
  - expected route owner
  - package class
  - proof class
  - rebuild expectation
  - prerequisites
  - denial behavior
  - fallback behavior
  - guide boundary link
- **D-19:** Keep the current platform baseline support matrix intact. Add capability-family support rendering derived from manifest truth instead of turning the support matrix into a second competing source of truth.
- **D-20:** Denial posture stays fail-closed. Capability metadata must never imply silent WebView fallback, generic wrapper degradation, or runtime authority wider than the active route declaration.
- **D-21:** Rebuild truth must stay explicit and separate from generic support status. Any family that needs new binary/runtime code must declare rebuild expectations directly instead of hiding them behind broad support labels.
- **D-22:** Do not duplicate family metadata on every route. Routes declare capability ids; the registry owns family-level semantics and support truth.

### Public exemplar set
- **D-23:** Phase 11 should publish a narrow, exemplar-aligned public example set rather than a broad “mobile API catalog.”
- **D-24:** The first canonical `core` example families are `deep_link`, `app_info`, `haptics`, and `share`. These reinforce Phoenix-owned routes, manifest-first shell truth, and low-frequency typed bridge semantics without widening runtime authority.
- **D-25:** The first `companion`-leaning example families are `media_capture`, `notification_token`, `rollout`, and `audit`. These fit Crosswake but carry meaningful native, backend, operator, or release-boundary pressure and should not be marketed as lightweight core capabilities.
- **D-26:** The first `example/docs-only` families are `permissions.status`, `auth`, and pre-Phase-13 commerce examples. These are useful for classification guidance but are not part of the first canonical supported capability set.
- **D-27:** `scanner` and `document_scan` remain deferred in the first public example set because they imply heavier native ownership, policy burden, and support-matrix breadth than this phase can honestly support.

### Developer ergonomics and planning posture
- **D-28:** The public rules should optimize for least surprise to Phoenix teams: small semantic family names, router-local declarations, typed manifest structs, explicit denial behavior, and backend-owned truth for security-sensitive or provider-heavy surfaces.
- **D-29:** Crosswake should shift normal classification and metadata-detail choices left within GSD. Downstream researcher, planner, and implementer agents should make principled decisions without re-asking unless a choice materially changes the public taxonomy, ownership rubric, package class boundaries, support claims, or backend-truth posture.

### the agent's Discretion
Verbatim copy from `.planning/phases/11-capability-taxonomy-and-contract-rubric/11-CONTEXT.md`. [VERIFIED: 11-CONTEXT.md]

- Exact field names for new capability metadata, as long as the concepts above remain explicit and typed.
- Exact scoring checklist dimensions and thresholds used internally by maintainers, as long as the public rule stays ownership-first.
- Exact rendered guide structure and table layout for capability-family support output, as long as it derives from manifest truth and does not become a second source of truth.
- Exact example copy, guide headings, and doc ordering, as long as the exemplar-aligned narrow posture remains intact.

### Deferred Ideas (OUT OF SCOPE)
Verbatim copy from `.planning/phases/11-capability-taxonomy-and-contract-rubric/11-CONTEXT.md`. [VERIFIED: 11-CONTEXT.md]

- Broad public capability catalogs or plugin-marketplace framing
- Storefront/provider-specific billing adapters before Phase 13 commerce seam work
- Broad scanner/document-scan support claims before package, rebuild, and proof posture mature
- Generic permission-broker workflows or app-global permission onboarding abstractions
- Notification delivery, rollout orchestration, auth, or audit as route-local bridge-owned capabilities
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| CAPA-01 | Phoenix teams can classify candidate native affordances into bounded bridge, explicit native screen, or deferred categories using one published rubric. | Publish an ownership-first ladder with a native-risk veto and example family classifications. [VERIFIED: REQUIREMENTS.md][VERIFIED: 11-CONTEXT.md] |
| CAPA-02 | Crosswake can express capability-family metadata, route-owner expectations, and support posture in manifest and support-matrix truth without widening runtime authority. | Extend `Capability` registry structs and render support docs from manifest truth instead of route duplication or guide-only state. [VERIFIED: REQUIREMENTS.md][VERIFIED: lib/crosswake/manifest/types.ex][VERIFIED: lib/crosswake/support_matrix/renderer.ex] |
| CAPA-03 | Adopters can read explicit rules for when a capability family belongs in `core`, requires a `companion`, or stays deferred. | Keep package class as registry metadata distinct from route ownership, then publish exemplar classifications and defer rules. [VERIFIED: REQUIREMENTS.md][VERIFIED: 11-CONTEXT.md] |
</phase_requirements>

## Summary

Phase 11 should plan around one canonical move: convert Crosswake’s public capability surface from operation-shaped ids into family-shaped ids, then keep operation-level bridge commands as an internal protocol map under each family. The current codebase already centralizes capability truth in `manifest.capability_registry`, but that registry only stores `id`, `version`, and `status`, while tests and bridge lookups still treat commands such as `haptics.impact` and `files.pick` as capability ids. [VERIFIED: lib/crosswake/manifest/types.ex][VERIFIED: lib/crosswake/manifest/builder.ex][VERIFIED: lib/crosswake/bridge/registry.ex][VERIFIED: test/crosswake/bridge/registry_test.exs]

The best planning posture is to keep three planes separate: public capability family taxonomy, operation-level bridge protocol, and support/package metadata. That separation matches the locked phase decisions, fits the existing route-first manifest architecture, and lines up with current ecosystem patterns from Hotwire Native, Expo, and Tauri: bounded web-owned routes can use small semantic bridge components, high-fidelity flows become explicit native screens, native-runtime compatibility changes require explicit rebuild truth, and capability/security metadata should be centralized and fail closed. [VERIFIED: 11-CONTEXT.md][CITED: https://native.hotwired.dev/overview/bridge-components][CITED: https://native.hotwired.dev/overview/native-screens][CITED: https://docs.expo.dev/eas-update/runtime-versions/][CITED: https://v2.tauri.app/security/capabilities/]

**Primary recommendation:** Plan Phase 11 as a registry-and-docs refactor: add typed family metadata to `Crosswake.Manifest.Types.Capability`, map bridge commands to families instead of reusing command ids as public capability ids, and generate capability-family support guidance from manifest truth. [VERIFIED: lib/crosswake/manifest/types.ex][VERIFIED: lib/crosswake/bridge/registry.ex][VERIFIED: lib/crosswake/support_matrix/renderer.ex]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Capability-family taxonomy and ownership rubric | Phoenix compile/manifest tier | Generated docs | Route declarations already compile into a manifest-first contract, so family truth belongs in typed manifest generation and is then published via guides. [VERIFIED: lib/crosswake/manifest/builder.ex][VERIFIED: guides/native_shell.md] |
| Operation-level bridge command authorization | Native shell bridge layer | Manifest registry | Crosswake’s bridge is request/reply-only and checks route declarations plus manifest registry before side effects, so command execution should resolve through manifest family truth rather than act as taxonomy truth itself. [VERIFIED: guides/bridge.md][VERIFIED: lib/crosswake/bridge/registry.ex] |
| Native-screen ownership classification | Native shell activation layer | Manifest registry | Hotwire Native documents that some interactions need fully native screens with corresponding URLs and per-platform implementations, which matches Crosswake’s explicit `:native_screen` route model. [CITED: https://native.hotwired.dev/overview/native-screens][VERIFIED: lib/crosswake/policy/schema.ex] |
| Capability-family support posture and rebuild truth | Manifest registry | Support matrix renderer | Rebuild expectations and support posture should be metadata on a family entry, then rendered into guides without creating a second policy source. [VERIFIED: 11-CONTEXT.md][VERIFIED: lib/crosswake/support_matrix/renderer.ex] |
| Deep-link capability treatment | Native shell activation layer | Manifest route metadata | Locked decisions keep deep links as shell activation truth, not bridge authority, so any family metadata here should inform activation and support docs rather than add a JS/native command path. [VERIFIED: 11-CONTEXT.md][VERIFIED: guides/native_shell.md] |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir | `~> 1.19` | Compile-time manifest generation, typed structs, and validators. [VERIFIED: mix.exs] | The current project already targets Elixir `~> 1.19`, so Phase 11 should stay in the existing compile-time contract layer instead of introducing a parallel toolchain. [VERIFIED: mix.exs] |
| Phoenix | `~> 1.8` | Host router metadata and route-policy integration. [VERIFIED: mix.exs] | Route policy and manifest compilation are Phoenix-first by project thesis and current implementation. [VERIFIED: AGENTS.md][VERIFIED: PROJECT.md][VERIFIED: mix.exs] |
| Phoenix LiveView | `~> 1.1` | Server-owned route baseline that bounded bridge capabilities must not supersede. [VERIFIED: mix.exs] | Current guides and support matrix explicitly preserve LiveView as server-owned and route-first. [VERIFIED: guides/support_matrix.md][VERIFIED: guides/native_shell.md] |
| NimbleOptions | `~> 1.1` | Typed route-policy schema validation. [VERIFIED: mix.exs][VERIFIED: lib/crosswake/policy/schema.ex] | Crosswake already uses NimbleOptions to keep route declarations typed and fail closed. [VERIFIED: lib/crosswake/policy/schema.ex] |

### Supporting
| Library / Surface | Version | Purpose | When to Use |
|-------------------|---------|---------|-------------|
| `Crosswake.Manifest.Types` | internal | Typed manifest structs, including the capability registry extension point. [VERIFIED: lib/crosswake/manifest/types.ex] | Use for all new family metadata fields so one canonical struct owns capability truth. [VERIFIED: lib/crosswake/manifest/types.ex][VERIFIED: 11-CONTEXT.md] |
| `Crosswake.Manifest.Builder` | internal | Canonical registry construction from route policy. [VERIFIED: lib/crosswake/manifest/builder.ex] | Use when deriving family entries from route declarations or a fixed catalog. [VERIFIED: lib/crosswake/manifest/builder.ex] |
| `Crosswake.Manifest.Validator` | internal | Fail-closed validation of manifest invariants. [VERIFIED: lib/crosswake/manifest/validator.ex] | Use to enforce vocabulary, metadata completeness, and route-to-registry consistency. [VERIFIED: lib/crosswake/manifest/validator.ex] |
| `Crosswake.SupportMatrix.Renderer` | internal | Deterministic generated Markdown output. [VERIFIED: lib/crosswake/support_matrix/renderer.ex] | Use to render capability-family support sections from manifest truth instead of hand-authored docs. [VERIFIED: lib/crosswake/support_matrix/renderer.ex][VERIFIED: 11-CONTEXT.md] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Manifest-owned family metadata | Per-route duplicated capability metadata | This would conflict with locked decision D-22 and create drift between routes, registry, and guides. [VERIFIED: 11-CONTEXT.md][VERIFIED: lib/crosswake/manifest/types.ex] |
| Family ids plus command map | Operation-shaped public capability ids | The current code does this for some tests and bridge entries, but Phase 11 explicitly locks the opposite direction. [VERIFIED: lib/crosswake/bridge/registry.ex][VERIFIED: test/crosswake/bridge/registry_test.exs][VERIFIED: 11-CONTEXT.md] |
| Ownership-first rubric | API-convenience-first rubric | Hotwire Native and the locked Crosswake decisions both distinguish bounded bridge enhancements from fully native screens by interaction ownership, not by “can we expose this API” convenience. [CITED: https://native.hotwired.dev/overview/bridge-components][CITED: https://native.hotwired.dev/overview/native-screens][VERIFIED: 11-CONTEXT.md] |

**Installation:**
```bash
mix deps.get
```

**Version verification:** Project dependency requirements are declared in `mix.exs`; this phase does not require adding a new external library. [VERIFIED: mix.exs]

## Architecture Patterns

### System Architecture Diagram
```text
Phoenix route policy
  -> normalized route declarations
    -> manifest builder
      -> capability family registry
      -> route entries with capability references only
      -> pack registry
      -> support matrix baseline
        -> manifest validator
          -> bridge registry command lookup
          -> shell activation / deep-link resolution
          -> support-matrix renderer
            -> generated capability-family docs
```
This data flow matches the current manifest-first architecture and keeps docs downstream of canonical typed state. [VERIFIED: lib/crosswake/manifest/builder.ex][VERIFIED: lib/crosswake/manifest/validator.ex][VERIFIED: lib/crosswake/bridge/registry.ex][VERIFIED: lib/crosswake/support_matrix/renderer.ex]

### Recommended Project Structure
```text
lib/crosswake/
├── manifest/          # typed family metadata, builder, validator, serializer
├── bridge/            # command-to-family mapping and fail-closed command lookup
├── support_matrix/    # baseline platform truth plus capability-family rendering
├── policy/            # route DSL and compile-time capability vocabulary checks
└── doctor/            # prerequisite and denial surfacing from manifest truth

guides/
├── bridge.md          # bounded command protocol, not public family taxonomy
├── native_shell.md    # activation, deep-link, and native-screen boundaries
└── support_matrix.md  # generated capability-family and platform support output

test/
├── crosswake/manifest/
├── crosswake/bridge/
├── crosswake/support_matrix/
└── crosswake/proof/
```
The structure above preserves current subsystem boundaries and gives Phase 11 a clean place to add family metadata, guide rendering, and classification tests. [VERIFIED: lib/crosswake/manifest/types.ex][VERIFIED: lib/crosswake/bridge/registry.ex][VERIFIED: lib/crosswake/support_matrix/renderer.ex]

### Pattern 1: Registry Owns Family Truth
**What:** Routes should only list family ids, while the capability registry owns owner class, package class, proof class, rebuild expectations, prerequisites, denial posture, fallback posture, and guide linkage. [VERIFIED: 11-CONTEXT.md][VERIFIED: lib/crosswake/manifest/types.ex]
**When to use:** For every family-level property that would otherwise be repeated across multiple routes or docs. [VERIFIED: 11-CONTEXT.md]
**Example:**
```elixir
# Source: lib/crosswake/manifest/builder.ex
routes
|> Enum.flat_map(& &1.capabilities)
|> Enum.uniq()
|> Enum.sort()
|> Map.new(fn capability ->
  {capability, Types.new_capability(id: capability, version: capability_version(capability))}
end)
```
This existing builder seam is the right place to centralize richer family metadata. [VERIFIED: lib/crosswake/manifest/builder.ex]

### Pattern 2: Commands Are Protocol Details Under Families
**What:** Bridge commands should resolve through a family registry instead of serving as the public capability taxonomy. [VERIFIED: 11-CONTEXT.md]
**When to use:** Whenever a family supports multiple operations or when public docs need stable semantics while protocol commands evolve. [VERIFIED: 11-CONTEXT.md]
**Example:**
```elixir
# Source: lib/crosswake/bridge/registry.ex
@capability_commands %{
  "app.info.get" => "app.info.get",
  "haptics.impact" => "haptics.impact",
  "files.pick" => "files.pick"
}
```
Phase 11 should keep the map but change the values to family ids such as `app_info`, `haptics`, and `share`. [VERIFIED: lib/crosswake/bridge/registry.ex][VERIFIED: 11-CONTEXT.md]

### Pattern 3: Native-Screen Veto For Stateful Or Policy-Heavy Flows
**What:** If the interaction loop, permission choreography, or fidelity burden moves into native state, classify the family as `native_screen` or `defer` rather than stretching the bridge. [VERIFIED: 11-CONTEXT.md]
**When to use:** Camera, scanning, document capture, storefront review-sensitive flows, auth/browser policy, and similar surfaces. [VERIFIED: 11-CONTEXT.md]
**Example:**
```text
bounded_bridge only if:
  route stays Phoenix-owned
  action is low-frequency
  request/reply semantics are enough
  native side is non-authoritative

otherwise:
  native_screen or backend_seam/defer
```
This matches Hotwire Native’s split between bridge components and fully native screens. [CITED: https://native.hotwired.dev/overview/bridge-components][CITED: https://native.hotwired.dev/overview/native-screens]

### Anti-Patterns to Avoid
- **Public capability ids equal bridge command ids:** Current tests and bridge lookup use this shape, but Phase 11 explicitly rejects it for public taxonomy. [VERIFIED: test/crosswake/bridge/registry_test.exs][VERIFIED: 11-CONTEXT.md]
- **Package class equals runtime ownership:** `core` versus `companion` is support and release posture, not a substitute for `bounded_bridge` versus `native_screen`. [VERIFIED: 11-CONTEXT.md]
- **Guide-first support truth:** Hand-maintained capability docs would drift from manifest truth and undermine the existing generated-doc pattern. [VERIFIED: lib/crosswake/support_matrix/renderer.ex][VERIFIED: 11-CONTEXT.md]
- **Silent fallback to generic WebView behavior:** Current shell and bridge docs are explicitly fail closed, and Phase 11 keeps that posture. [VERIFIED: guides/native_shell.md][VERIFIED: guides/bridge.md][VERIFIED: 11-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Capability classification | Plugin-style “category buckets” or ad hoc labels | One ownership-first family rubric plus typed enum/vocabulary checks | Broad buckets hide route ownership and make support truth dishonest. [VERIFIED: 11-CONTEXT.md] |
| Per-route support posture | Repeated metadata blobs on routes | Central capability registry entries referenced by routes | Duplication creates drift and conflicts with locked decision D-22. [VERIFIED: 11-CONTEXT.md][VERIFIED: lib/crosswake/manifest/types.ex] |
| Rebuild compatibility rules | Implicit “supported” labels only | Explicit rebuild expectation metadata per family | Expo’s current runtime-version guidance shows native-runtime changes need explicit compatibility management. [CITED: https://docs.expo.dev/eas-update/runtime-versions/] |
| Capability security boundaries | Broad app-wide access or generic bridge buses | Family-scoped manifest truth with fail-closed command lookup | Tauri’s current capability model centralizes permissions and warns that merged scopes widen boundaries. [CITED: https://v2.tauri.app/security/capabilities/][VERIFIED: guides/bridge.md] |
| High-fidelity device flows | Bigger bridge payloads and polling loops | Explicit `:native_screen` routes | Hotwire Native’s current model uses fully native screens when bridge components are not enough. [CITED: https://native.hotwired.dev/overview/native-screens][VERIFIED: lib/crosswake/policy/schema.ex] |

**Key insight:** The hard part in this domain is not exposing a method call; it is preserving truthful ownership, support posture, and compatibility boundaries once that method exists. [VERIFIED: 11-CONTEXT.md][CITED: https://docs.expo.dev/eas-update/runtime-versions/][CITED: https://v2.tauri.app/security/capabilities/]

## Common Pitfalls

### Pitfall 1: Family/Command Drift
**What goes wrong:** Public docs say `haptics`, but the registry, tests, and bridge still treat `haptics.impact` as the capability id. [VERIFIED: 11-CONTEXT.md][VERIFIED: lib/crosswake/bridge/registry.ex][VERIFIED: test/crosswake/bridge/registry_test.exs]
**Why it happens:** The current Phase 3 bridge contract encoded commands directly as capability ids because the public taxonomy had not been frozen yet. [VERIFIED: guides/bridge.md][VERIFIED: lib/crosswake/bridge/registry.ex]
**How to avoid:** Add a stable family id to registry truth first, then migrate command lookup and tests to resolve commands through family ids. [VERIFIED: 11-CONTEXT.md]
**Warning signs:** Tests assert `entry.capability == "haptics.impact"` or guides list command names where they should list public family names. [VERIFIED: test/crosswake/bridge/registry_test.exs][VERIFIED: guides/bridge.md]

### Pitfall 2: Metadata Duplication Across Routes And Guides
**What goes wrong:** Routes start carrying package class, rebuild notes, prerequisite notes, and support text, while guides hand-maintain similar tables separately. [VERIFIED: 11-CONTEXT.md]
**Why it happens:** It feels faster to attach new output fields wherever they are rendered instead of extending the typed registry. [VERIFIED: lib/crosswake/support_matrix/renderer.ex][VERIFIED: lib/crosswake/manifest/types.ex]
**How to avoid:** Keep route entries lean and extend only the registry plus deterministic renderers. [VERIFIED: 11-CONTEXT.md][VERIFIED: lib/crosswake/manifest/builder.ex]
**Warning signs:** Two files need manual edits for the same support claim, or route entries start duplicating family-level prose. [VERIFIED: lib/crosswake/support_matrix/renderer.ex][VERIFIED: 11-CONTEXT.md]

### Pitfall 3: Using Bounded Bridge For Stateful Native Loops
**What goes wrong:** Camera, scanning, or permission choreography gets modeled as a series of bridge calls even though native code owns the interaction loop. [VERIFIED: 11-CONTEXT.md]
**Why it happens:** The API surface looks small at first, so the ownership cost is hidden until denial, review, or fidelity constraints appear. [VERIFIED: 11-CONTEXT.md][CITED: https://native.hotwired.dev/overview/native-screens]
**How to avoid:** Apply the native-risk veto before naming the family as bridge-owned. [VERIFIED: 11-CONTEXT.md]
**Warning signs:** The family needs continuous native state, multi-step permission flow, or native-first UI correctness. [VERIFIED: 11-CONTEXT.md][CITED: https://native.hotwired.dev/overview/native-screens]

### Pitfall 4: Conflating Support Status With Rebuild Truth
**What goes wrong:** A family is labeled “supported” without saying whether enabling it requires a new binary/runtime. [VERIFIED: 11-CONTEXT.md]
**Why it happens:** Support matrices often compress installability, runtime compatibility, and proof status into one label. [VERIFIED: guides/support_matrix.md]
**How to avoid:** Keep rebuild expectation as a separate required metadata field on each capability family. [VERIFIED: 11-CONTEXT.md]
**Warning signs:** A capability can be turned on by docs alone even though it changes shell-native code. [CITED: https://docs.expo.dev/eas-update/runtime-versions/][VERIFIED: 11-CONTEXT.md]

## Code Examples

Verified patterns from official sources and the current codebase:

### Registry-Based Capability Construction
```elixir
# Source: lib/crosswake/manifest/builder.ex
defp capability_registry(routes) do
  routes
  |> Enum.flat_map(& &1.capabilities)
  |> Enum.uniq()
  |> Enum.sort()
  |> Map.new(fn capability ->
    {capability, Types.new_capability(id: capability, version: capability_version(capability))}
  end)
end
```
This is the canonical place to upgrade family metadata in Phase 11. [VERIFIED: lib/crosswake/manifest/builder.ex]

### Fail-Closed Bridge Lookup
```elixir
# Source: lib/crosswake/bridge/registry.ex
with true <- command_supported?(command) || {:error, :unsupported_command},
     %RouteEntry{} = route <- Map.get(manifest.routes, route_id) || {:error, :inactive_route} do
  lookup_entry(manifest, route, command)
end
```
This pattern should stay intact after family ids replace command ids as public taxonomy. [VERIFIED: lib/crosswake/bridge/registry.ex]

### Hotwire Native Split Between Bridge Components And Native Screens
```text
Bridge Components:
  web controller + native counterpart
Native Screens:
  fully native Kotlin/Swift screens when bridge components are not enough
```
Hotwire Native’s current docs explicitly draw this line, which makes it a useful external sanity check for Crosswake’s rubric. [CITED: https://native.hotwired.dev/overview/bridge-components][CITED: https://native.hotwired.dev/overview/native-screens]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Public capability ids mirror operation names such as `haptics.impact` or `files.pick`. [VERIFIED: lib/crosswake/bridge/registry.ex][VERIFIED: test/crosswake/bridge/registry_test.exs] | Public capability ids should be stable family names such as `haptics`, `share`, and `app_info`, with commands beneath them. [VERIFIED: 11-CONTEXT.md] | Locked in Phase 11 context on 2026-05-19. [VERIFIED: 11-CONTEXT.md] | Planning must account for a taxonomy migration seam across builder, bridge registry, tests, fixtures, and docs. [VERIFIED: lib/crosswake/manifest/builder.ex][VERIFIED: lib/crosswake/bridge/registry.ex][VERIFIED: test/crosswake/bridge/registry_test.exs] |
| Capability support is mostly platform-baseline output plus route-local declarations. [VERIFIED: guides/support_matrix.md][VERIFIED: lib/crosswake/manifest/types.ex] | Capability-family support posture should be rendered from registry metadata while preserving the narrow baseline matrix. [VERIFIED: 11-CONTEXT.md] | Locked in Phase 11 context on 2026-05-19. [VERIFIED: 11-CONTEXT.md] | The renderer likely needs a new capability-family section, but the existing platform baseline counts should remain narrow and intact. [VERIFIED: 11-CONTEXT.md][VERIFIED: lib/crosswake/support_matrix/support_matrix.ex] |
| Hybrid frameworks often lead with broad plugin APIs. [CITED: https://capacitorjs.com/docs] | Crosswake should lead with ownership-first family classification and a narrow exemplar set. [VERIFIED: 11-CONTEXT.md] | Current milestone `v3.0` activates contract-first breadth planning. [VERIFIED: PROJECT.md][VERIFIED: ROADMAP.md] | Public docs should read like a contract guide, not a feature catalog. [VERIFIED: 11-CONTEXT.md] |

**Deprecated/outdated:**
- Operation-shaped capability ids as the public taxonomy are outdated for Crosswake after Phase 11 locking, even if they still exist in current bridge code and tests. [VERIFIED: 11-CONTEXT.md][VERIFIED: lib/crosswake/bridge/registry.ex][VERIFIED: test/crosswake/bridge/registry_test.exs]
- Plugin-bucket framing such as `device`, `media`, `payments`, or `native` is explicitly out for this phase. [VERIFIED: 11-CONTEXT.md]
- Any design that treats deep links as a page-owned bridge capability instead of shell activation truth is explicitly out. [VERIFIED: 11-CONTEXT.md][VERIFIED: guides/native_shell.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| None | All substantive claims in this document were verified in the current codebase or cited from current official docs. | — | — |

## Open Questions

1. **Which exact existing command-shaped ids need migration in Phase 11 versus later cleanup?**
   - What we know: `app.info.get`, `haptics.impact`, and `files.pick` are current bounded bridge commands, and tests already assert them as capability ids. [VERIFIED: guides/bridge.md][VERIFIED: lib/crosswake/bridge/registry.ex][VERIFIED: test/crosswake/bridge/registry_test.exs]
   - What's unclear: Whether Phase 11 should fully rename route declarations and fixtures to family ids or introduce a compatibility shim first. [VERIFIED: 11-CONTEXT.md]
   - Recommendation: Plan a deliberate migration layer inside this phase because taxonomy truth is the phase goal, not incidental cleanup. [VERIFIED: ROADMAP.md][VERIFIED: 11-CONTEXT.md]

2. **Should `share` subsume `files.pick`, or should file picking remain a separate family later?**
   - What we know: Locked decisions list `share` but not `files.pick` in the exemplar family set, while current bridge commands include `files.pick`. [VERIFIED: 11-CONTEXT.md][VERIFIED: guides/bridge.md]
   - What's unclear: Whether the intended Phase 11 public family for that command is `share`, a future `document_pick`, or an example-only classification. [VERIFIED: 11-CONTEXT.md]
   - Recommendation: Resolve this in planning before implementation because it affects migration scope, docs wording, and command-to-family mapping. [VERIFIED: 11-CONTEXT.md]

3. **Where should capability-family support output live?**
   - What we know: Locked decisions require generated support output derived from manifest truth and forbid a second competing source of truth. [VERIFIED: 11-CONTEXT.md]
   - What's unclear: Whether the capability-family section belongs inside `guides/support_matrix.md`, a sibling generated guide, or both via links. [VERIFIED: lib/crosswake/support_matrix/renderer.ex]
   - Recommendation: Keep one renderer as the source and prefer adding a section to the existing support surface unless formatting pressure proves otherwise. [VERIFIED: lib/crosswake/support_matrix/renderer.ex][VERIFIED: 11-CONTEXT.md]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Authentication flows are explicitly backend seams or deferred for this phase, not route-local bridge authority. [VERIFIED: 11-CONTEXT.md] |
| V3 Session Management | no | This phase does not define session storage or rotation mechanics. [VERIFIED: REQUIREMENTS.md][VERIFIED: ROADMAP.md] |
| V4 Access Control | yes | Route ids, active-route checks, origin allowlists, command allowlists, and capability declarations already form Crosswake’s access boundary pattern. [VERIFIED: guides/bridge.md][VERIFIED: lib/crosswake/bridge/registry.ex][VERIFIED: lib/crosswake/compatibility/compatibility.ex] |
| V5 Input Validation | yes | Route policy uses NimbleOptions and manifest validation uses typed struct checks plus explicit error reporting. [VERIFIED: lib/crosswake/policy/schema.ex][VERIFIED: lib/crosswake/manifest/validator.ex] |
| V6 Cryptography | no | Phase 11 metadata classification does not introduce new cryptographic primitives. [VERIFIED: REQUIREMENTS.md][VERIFIED: ROADMAP.md] |

### Known Threat Patterns for Crosswake Capability Taxonomy

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Command/family confusion grants wider authority than docs imply | Elevation of privilege | Resolve commands through family registry metadata and keep docs generated from the same registry. [VERIFIED: lib/crosswake/bridge/registry.ex][VERIFIED: lib/crosswake/support_matrix/renderer.ex][VERIFIED: 11-CONTEXT.md] |
| Over-broad remote or origin access to bridge/native commands | Spoofing / Tampering | Preserve route-local allowlisted origins and fail-closed lookup behavior. [VERIFIED: guides/bridge.md][VERIFIED: lib/crosswake/bridge/registry.ex] |
| Capability metadata drift creates false support claims | Repudiation / Information disclosure | Centralize support posture in manifest truth and render docs deterministically. [VERIFIED: lib/crosswake/support_matrix/renderer.ex][VERIFIED: 11-CONTEXT.md] |
| Native-sensitive families exposed as bounded bridge calls | Tampering / Elevation of privilege | Apply the native-risk veto and classify session-heavy surfaces as `native_screen`, `backend_seam`, or `defer`. [VERIFIED: 11-CONTEXT.md][CITED: https://native.hotwired.dev/overview/native-screens] |

## Sources

### Primary (HIGH confidence)
- `.planning/phases/11-capability-taxonomy-and-contract-rubric/11-CONTEXT.md` - locked taxonomy, rubric, metadata, and exemplar decisions. [VERIFIED: 11-CONTEXT.md]
- `.planning/REQUIREMENTS.md` - `CAPA-01` through `CAPA-03` and support/proof gates. [VERIFIED: REQUIREMENTS.md]
- `.planning/PROJECT.md`, `.planning/ROADMAP.md`, `.planning/STATE.md`, `AGENTS.md` - milestone thesis, sequencing, and project constraints. [VERIFIED: PROJECT.md][VERIFIED: ROADMAP.md][VERIFIED: STATE.md][VERIFIED: AGENTS.md]
- `lib/crosswake/manifest/types.ex`, `builder.ex`, `validator.ex` - current manifest extension points and validation seams. [VERIFIED: lib/crosswake/manifest/types.ex][VERIFIED: lib/crosswake/manifest/builder.ex][VERIFIED: lib/crosswake/manifest/validator.ex]
- `lib/crosswake/bridge/registry.ex`, `lib/crosswake/support_matrix/*.ex`, `lib/crosswake/policy/schema.ex`, `lib/crosswake/policy/validator.ex` - current bridge, support, and vocabulary behavior. [VERIFIED: lib/crosswake/bridge/registry.ex][VERIFIED: lib/crosswake/support_matrix/support_matrix.ex][VERIFIED: lib/crosswake/support_matrix/renderer.ex][VERIFIED: lib/crosswake/policy/schema.ex][VERIFIED: lib/crosswake/policy/validator.ex]
- `guides/bridge.md`, `guides/native_shell.md`, `guides/support_matrix.md`, `guides/adopter_profiles.md` - current public contract surfaces. [VERIFIED: guides/bridge.md][VERIFIED: guides/native_shell.md][VERIFIED: guides/support_matrix.md][VERIFIED: guides/adopter_profiles.md]
- Hotwire Native official docs - bridge components and native screens. [CITED: https://native.hotwired.dev/overview/bridge-components][CITED: https://native.hotwired.dev/overview/native-screens]
- Expo official docs - runtime versions and rebuild compatibility. [CITED: https://docs.expo.dev/eas-update/runtime-versions/]
- Tauri official docs - capability-scoped permissions and boundary warnings. [CITED: https://v2.tauri.app/security/capabilities/]

### Secondary (MEDIUM confidence)
- Capacitor official docs - representative plugin-centric hybrid runtime baseline used as a contrast case for Crosswake’s anti-plugin-sprawl stance. [CITED: https://capacitorjs.com/docs]

### Tertiary (LOW confidence)
- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - all recommendations stay inside the current project stack and codebase seams. [VERIFIED: mix.exs][VERIFIED: lib/crosswake/manifest/types.ex]
- Architecture: HIGH - the locked phase decisions align with the current code architecture and current official Hotwire/Expo/Tauri docs. [VERIFIED: 11-CONTEXT.md][CITED: https://native.hotwired.dev/overview/bridge-components][CITED: https://native.hotwired.dev/overview/native-screens][CITED: https://docs.expo.dev/eas-update/runtime-versions/][CITED: https://v2.tauri.app/security/capabilities/]
- Pitfalls: HIGH - the largest risks are already visible in current code and guides, especially command-shaped ids and duplicated support truth pressure. [VERIFIED: lib/crosswake/bridge/registry.ex][VERIFIED: test/crosswake/bridge/registry_test.exs][VERIFIED: lib/crosswake/support_matrix/renderer.ex]

**Research date:** 2026-05-19
**Valid until:** 2026-06-18
