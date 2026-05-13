# Phase 1: Route Policy Foundation - Research

**Researched:** 2026-05-12
**Scope:** Phase 1 planning support
**Confidence:** HIGH

## Executive Summary

Phase 1 should establish Crosswake's Phoenix-side authoring contract before any manifest, shell, or offline runtime work. The recommended approach is a router-adjacent DSL that keeps route truth local to Phoenix routes, validates declaration shape and semantic contradictions at compile time, and normalizes the result into typed policy structs attached to Phoenix route metadata for downstream manifest generation.

Because the repository is still planning-only, Phase 1 is effectively a greenfield library build. Planning should therefore separate foundation work into explicit slices for project scaffolding, DSL authoring ergonomics, normalization and schema enforcement, compile-time diagnostics, router introspection, and additive setup generators. The plan should avoid any work that implies native runtime behavior, broad capability execution, or environment-dependent proof that belongs to later phases.

## Locked Inputs From Phase Context

- Public runtime ownership classes for Phase 1 are `:live_view`, `:offline_island`, and `:native_screen`.
- `adapter` is reserved for future extension points and is not a public Phase 1 runtime class.
- Policy is declared next to Phoenix routes via `crosswake:` route metadata plus scope-level defaults.
- Every Crosswake-managed route requires `id` and `runtime`.
- Defaults are narrow and explicit: `offline: :unavailable`, `capabilities: []`, `packs: []`, `sync: []`.
- Validation should use typed schemas and normalized structs, with `NimbleOptions` for option shape and semantic checks layered on top.
- Compile time should catch local contradictions and missing required metadata, but should not depend on native artifacts, release packaging, or support-matrix state.
- The intended additive DX path is `mix crosswake.install` plus `mix crosswake.gen.shell ios|android`.

## Recommended Architecture

### Router-Adjacent DSL

The primary authoring surface should extend normal Phoenix router declarations rather than introducing a second registry. The DSL should support:

- Route-level `crosswake: [...]` metadata on individual routes
- Scope-level Crosswake defaults that merge into route-level declarations
- Explicit normalization rules so route declarations compile into a consistent internal shape

This preserves locality, keeps Phoenix routing authoritative, and avoids duplicate route registries that would drift from the router.

### Normalized Policy Pipeline

Phase 1 should convert author-authored route metadata into typed internal policy structs that can serve as the basis for manifest work later. The pipeline should be:

1. Capture route-level and scope-level metadata
2. Validate basic option shape with `NimbleOptions`
3. Normalize defaults and canonical field values
4. Run semantic invariant checks across the normalized policy
5. Attach compiled policy to Phoenix route metadata for introspection

The plan should include a clear internal boundary between raw router options and normalized policy structures so later phases do not build directly on ad hoc metadata maps.

### Compile-Time Validation Posture

Validation should fail compilation for:

- Missing `id` or `runtime` on Crosswake-managed routes
- Unknown runtime or enum values
- Contradictory declarations, such as offline semantics incompatible with runtime ownership
- Invalid capability, pack, sync, or security declarations
- Duplicate or ambiguous route-policy identifiers where the system requires uniqueness

Validation should not attempt to prove environment truth, shell readiness, release state, or package compatibility in Phase 1. Those belong to later doctor and manifest phases.

### Diagnostics And Error Ergonomics

The error posture should match strong Phoenix/Ecto ergonomics:

- Include route, file/line, offending keys, and why the declaration is invalid
- Aggregate errors where feasible instead of failing on only the first issue
- Include a short fix hint when the corrective action is obvious

Warnings are appropriate for adoption guidance such as incomplete route coverage, but warnings should not blur hard failures for contradictory declarations.

### Generator Boundaries

The install/generator work in this phase should make ownership boundaries explicit:

- `mix crosswake.install` should be idempotent and patch the Phoenix host in a way that is reviewable and host-owned after generation
- `mix crosswake.gen.shell ios|android` should generate shell skeletons and handoff docs without pretending the generated native app remains library-owned
- Crosswake-owned code in Phase 1 should remain focused on DSL, validation, normalization, and setup tooling

## Planning Implications

Phase 1 planning should break the work into distinct executable slices:

1. Create the core Elixir library scaffold and baseline test structure
2. Define internal policy types, schemas, and normalization rules
3. Add router-adjacent DSL and metadata attachment
4. Implement compile-time semantic validation and developer-facing diagnostics
5. Add introspection surfaces needed by later manifest work
6. Ship the additive install and shell generator path with explicit ownership boundaries
7. Back the public contract with focused tests and proof-oriented examples

Because the repo has no implementation code yet, each slice should create durable substrate for later phases instead of mock or placeholder abstractions.

## Risks And Pitfalls

- Universal-runtime drift: avoid APIs or docs that imply Crosswake is a generic WebView wrapper or shared UI system.
- Taxonomy drift: do not reintroduce `adapter` as a Phase 1 peer runtime.
- Metadata leakage: avoid building later phases directly against raw metadata maps; normalize early.
- Environment overreach: do not put shell existence, manifest compatibility, or platform truth into compile-time checks.
- Generator overreach: avoid a heavy framework-style template as the main public entrypoint.

## Verification Recommendations

Planning should require evidence for:

- Route declarations that cover each supported runtime class and default merge behavior
- Compile-time failures for missing required fields and contradictory declarations
- Introspection of compiled policy from router metadata
- Idempotent install behavior for a host Phoenix app
- Shell skeleton generation with explicit handoff/ownership documentation

Tests should prioritize public contract truth over internal implementation detail, since later phases will depend on the policy surface remaining stable.

## Suggested Deliverable Shape

A strong Phase 1 plan should likely produce multiple plan files rather than one giant document. The natural seams are:

- foundation/scaffold
- policy schema and normalization
- router DSL and defaults
- compile-time validation and diagnostics
- install/generator DX and examples

## RESEARCH COMPLETE

Phase 1 should plan around a Phoenix-local route-policy DSL, a typed normalization pipeline, strict compile-time semantic validation, and additive generator boundaries. The biggest planning consequence is that this is greenfield substrate work, so the plan needs clear foundational slices instead of assuming existing modules or reusable code.
