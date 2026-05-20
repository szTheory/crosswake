# Phase 11: Capability Taxonomy And Contract Rubric - Research

**Researched:** 2026-05-19
**Domain:** Crosswake capability taxonomy, manifest truth, and support posture
**Confidence:** HIGH

## Summary

Phase 11 should lock Crosswake's capability vocabulary before any new capability breadth ships. The planning center of gravity is not "add more native APIs"; it is "define how Crosswake classifies capability families, where ownership lives, and how manifest and support outputs speak honestly about prerequisites, denial behavior, rebuild expectations, and package boundaries."

The current codebase already gives the right structural seams for this work:

- `Crosswake.Manifest.Types.Capability` is the canonical place to carry family metadata.
- `Crosswake.Manifest.Builder.capability_registry/1` already centralizes capability registry generation from route declarations.
- `Crosswake.Manifest.Validator` already owns fail-closed semantic validation.
- `Crosswake.Bridge.Registry` already proves commands and public capability concepts must stay separate.
- `Crosswake.SupportMatrix` and `Crosswake.SupportMatrix.Renderer` already provide the narrow generated support surface that Phase 11 should extend rather than replace.

The primary recommendation is to split the phase into three plans that move in this order:

1. Publish the ownership-first taxonomy and route-owner rubric in guides and policy-facing docs.
2. Extend manifest/support typed truth so capability-family metadata is canonical and rendered from code.
3. Publish example classifications and defer rules for candidate families without pretending broad support already exists.

## Architectural Responsibility Map

| Concern | Primary surface | Secondary surface | Why |
|---------|-----------------|-------------------|-----|
| Public capability-family vocabulary | Guides + manifest capability metadata | Policy docs | Families must be semantic and stable, not command-shaped or plugin-shaped. |
| Route-owner decision rules | Guides + validation semantics | Bridge docs | Crosswake's differentiator is explicit runtime ownership per route. |
| Package and support posture | Manifest capability metadata | Support matrix renderer | Package class, proof class, prerequisites, denial, fallback, and rebuild truth should be generated from canonical state. |
| Command-level operation mapping | Bridge registry | Manifest registry lookup | Commands remain protocol details under a family rather than the public product taxonomy. |

## Standard Patterns To Reuse

### Pattern 1: Keep route declarations lean and move shared truth into typed registries

Use the existing route/registry split rather than duplicating family metadata onto routes. Routes should continue to declare capability ids only; the registry should own owner class, package class, proof class, prerequisites, denial behavior, fallback behavior, rebuild expectation, and guide boundary linkage.

### Pattern 2: Fail closed through validator-enforced vocabulary

The manifest validator is already the canonical place for semantic checks. New capability metadata should be validated there with explicit allowed vocabularies and route-to-registry consistency checks. Avoid soft validation in docs, generators, or bridge lookup code.

### Pattern 3: Keep bridge commands as a lower layer than public capability families

`Crosswake.Bridge.Registry` currently maps concrete commands like `haptics.impact` and `app.info.get`. Phase 11 should preserve that split. Public docs should say "`haptics` is the family" while bridge code can continue to expose operation-level commands under the hood.

### Pattern 4: Generate support posture from canonical typed state

The support matrix is already generated, narrow, and proof-oriented. Capability-family support should be rendered from manifest truth using the same style rather than hand-maintained markdown tables or a second source of truth.

## Candidate Family Classification Guidance

### Strong bounded-bridge examples

- `haptics`
- `share`
- `app_info`
- `permissions.status` when treated as read-only snapshot only
- `notification_token` when treated as evidence only, not delivery truth

These fit Crosswake when the route remains Phoenix-owned, the action is low-frequency and semantic, and native code does not own an ongoing interaction loop.

### Native-screen-first examples

- `media_capture`
- `scanner`
- `document_scan`

These imply camera or scanning session control, repeated native state changes, stronger permission choreography, and higher device/policy variance. They should bias toward explicit `:native_screen` ownership and often companion-ready packaging.

### Backend seam or deferred examples

- `rollout`
- `auth`
- `audit`
- notification delivery providers

These are control-plane or provider-heavy concerns. Treating them as route-local bridge authority would distort Crosswake's thesis and support posture.

### Commerce examples

- `paywall`
- `purchase`
- `restore`
- `entitlement_snapshot`

These are valid taxonomy entries, but their seam rules remain Phase 13 work. Phase 11 should classify them without implying provider-specific or storefront-ready support.

## Anti-Patterns To Avoid

- Generic capability buckets like `device`, `media`, `payments`, `native`, or `plugins`
- Conflating package class (`core`, `companion`, `example/docs-only`, `defer`) with runtime owner
- Route-local metadata duplication for family-level support facts
- Silent WebView fallback or generic wrapper degradation for unsupported families
- Publishing a broad feature catalog before package, proof, and rebuild truth are explicit

## Suggested Plan Boundaries

### Plan 11-01: Taxonomy and ownership rubric

Best scope:

- `guides/bridge.md`
- `guides/native_shell.md`
- possibly a new focused guide or capability section under existing guides
- any policy-facing docs needed to define family naming and owner-class rules

Deliverable shape:

- One published ownership-first rubric
- Explicit rules for `bounded_bridge`, `native_screen`, and backend-seam/defer outcomes
- Clear examples anchored to current SaaS, selective-native, and local-first exemplar lanes

### Plan 11-02: Manifest and support truth

Best scope:

- `lib/crosswake/manifest/types.ex`
- `lib/crosswake/manifest/builder.ex`
- `lib/crosswake/manifest/validator.ex`
- `lib/crosswake/support_matrix/support_matrix.ex`
- `lib/crosswake/support_matrix/renderer.ex`
- associated tests

Deliverable shape:

- Typed capability metadata in the manifest registry
- Canonical builder population for declared families
- Validator enforcement for allowed vocabularies and route consistency
- Support-matrix output or related generated guide content derived from manifest capability metadata

### Plan 11-03: Example classifications and defer rules

Best scope:

- `guides/support_matrix.md`
- classification guide output and examples
- tests or generation hooks proving docs stay derived from code

Deliverable shape:

- Narrow public example set
- Explicit `core` vs `companion` vs `example/docs-only` vs `defer` examples
- Explicit defer statements for scanner/document-scan and other out-of-thesis surfaces

## Verification Strategy

- Unit-test any new manifest type constructors and serializers.
- Unit-test builder output so route capability declarations compile into the expected registry metadata.
- Unit-test validator rejection paths for unsupported owner classes, package classes, proof classes, or denial/fallback values.
- Verify generated support output contains concrete family metadata, proof posture, and boundary links.
- Verify public guides contain the ownership-first rubric and example classifications without generic plugin framing.

## Common Pitfalls

### Pitfall 1: solving Phase 11 by adding route DSL breadth

This phase should classify future capability work, not widen the route API aggressively. New truth belongs in manifest registry metadata and generated support output before it belongs in route declarations.

### Pitfall 2: collapsing deep links or commerce into generic bridge semantics

Deep links remain shell activation truth. Commerce remains backend-truthful seam work. Do not let taxonomy work imply broader runtime authority than the project thesis allows.

### Pitfall 3: treating support docs as editorial prose instead of generated contract surface

Crosswake's support posture is part of the product. The support matrix and related capability guidance should derive from canonical typed truth where possible, with guides explaining the contract rather than inventing a second contract.

## Phase Requirements Coverage

| ID | Planning implication |
|----|----------------------|
| `CAPA-01` | Requires a public rubric and examples that classify candidate families into bounded bridge, native screen, or deferred/backend seam. |
| `CAPA-02` | Requires typed manifest/support metadata plus validation and rendering changes that keep runtime authority narrow. |
| `CAPA-03` | Requires public guidance distinguishing `core`, `companion`, `example/docs-only`, and `defer` without collapsing those terms into route ownership. |

## Environment Availability

| Dependency | Required by | Available | Notes |
|------------|-------------|-----------|-------|
| Elixir / Mix | Manifest, validator, renderer, and guide generation tests | Expected | This phase is primarily library, docs, and test work. |
| Existing guide generation path | Support-matrix output updates | Expected | Reuse the current support-matrix renderer flow rather than introducing a new docs toolchain. |

## Security And Support Posture

- Capability metadata should encode denial and fallback truth explicitly because vague support claims widen trust boundaries.
- Family classifications should preserve existing fail-closed behavior on inactive routes, undeclared capabilities, and unsupported commands.
- Rebuild truth should be explicit wherever capability support depends on new binary/runtime code rather than pure Phoenix-side changes.
