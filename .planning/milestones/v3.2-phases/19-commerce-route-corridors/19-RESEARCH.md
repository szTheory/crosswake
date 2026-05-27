# Phase 19 Research: Commerce Route Corridors

Date: 2026-05-27
Phase: 19 - Commerce Route Corridors
Requirements: COMM-04, COMM-05, COMM-06

## What This Phase Must Prove

Phase 19 is not "add more commerce capabilities." It is "make commerce ownership corridors explicit and fail-closed."

- COMM-04: Route policy must represent Phoenix-owned commerce surfaces separately from native-screen or companion storefront loops.
- COMM-05: Manifest and support truth must expose corridor semantics using Crosswake-owned, provider-neutral vocabulary.
- COMM-06: Undeclared/unsupported corridors must deny with explicit code + fallback (no silent fallback to WebView/bridge).

Success criteria in roadmap map directly to:
1) Route DSL expressiveness.
2) Manifest corridor truth.
3) Runtime fail-closed denial behavior.
4) Public guidance clarity.

## Current Baseline (What Already Exists)

The repo already has strong patterns we should reuse rather than invent:

- Typed route DSL + early validation:
  - `Crosswake.Policy.Schema`, `Crosswake.Policy.Route`, `Crosswake.Policy.Compiler`, `Crosswake.Policy.Validator`
- Registry + route-reference manifest shape:
  - `capability_registry` and `pack_registry` at root + route-level references in `RouteEntry`
- Layered manifest validation:
  - `Crosswake.Manifest.Validator` enforces vocabulary, required fields, and referential integrity
- Stable denial envelope:
  - `Crosswake.Shell.Denial` has `reason`, `code`, `message`, `hint`, `details`, `recovery`
- Support truth as product surface:
  - `Crosswake.SupportMatrix`, renderer, doctor formatters, and docs tests keep generated/public truth aligned

Gaps for Phase 19:

- No route-level commerce corridor field in policy schema/route struct.
- No manifest-level `commerce_corridors` registry.
- No corridor-specific denial taxonomy in shell denial reasons.
- No doctor/support output specific to corridor prerequisite posture.
- Guides discuss commerce boundaries, but not route corridor declaration mechanics and denial taxonomy.

## Recommended Implementation Shape

## Standard Stack

- Keep current stack: `NimbleOptions` for policy DSL validation, typed structs in `Crosswake.Manifest.Types`, compile -> manifest -> validate pipeline, compatibility-to-denial mapping for fail-closed runtime behavior.
- Do not add provider SDK abstractions or plugin bus surfaces.
- Keep values serialized as strings at manifest boundary; internal atoms are fine.

## Architecture Patterns

1. **Registry + Reference (existing pattern)**
   - Add root `commerce_corridors` registry.
   - Add route-level reference (`corridor_ref`) plus route-local role.
   - Same design philosophy as `capability_registry` and `packs`.

2. **Layered validation (existing pattern)**
   - Schema-level shape checks.
   - Route-level semantic checks.
   - Manifest-level referential and vocabulary checks.
   - Runtime compatibility checks produce denial payloads.

3. **Fail-closed denial envelope (existing pattern)**
   - Use stable reason family + explicit canonical `code`.
   - Always include explicit fallback/recovery guidance.

## Proposed DSL and Data Model

Recommended route binding shape:

- Route declaration keeps ownership explicit at route site:
  - `commerce: [corridor: :subscription_default, role: :paywall_entry]`

Recommended profile declaration shape:

- Named corridor profiles should be declared once and referenced many times.
- Introduce a router-level profile declaration mechanism (or compile option fallback for tests), then bind per route via `commerce: [corridor: ...]`.
- Keep inline route-local commerce declaration supported for simple cases by allowing `corridor` to be an inline map/keyword.

## Manifest Corridor Registry Shape

Add explicit root registry and typed route reference:

```json
{
  "commerce_corridors": {
    "subscription_default": {
      "id": "subscription_default",
      "moments": {
        "paywall_entry": "phoenix_owned",
        "purchase_intent": "native_or_companion_required",
        "restore_intent": "native_or_companion_required",
        "account_management": "phoenix_owned"
      },
      "prerequisites": [
        "backend_entitlement_contract",
        "storefront_adapter_or_companion",
        "explicit_reviewer_playbook"
      ],
      "denial_defaults": {
        "family": "commerce_corridor",
        "fallback": "return_to_phoenix_guidance"
      }
    }
  },
  "routes": {
    "paywall": {
      "commerce": {
        "corridor_ref": "subscription_default",
        "role": "paywall_entry"
      }
    }
  }
}
```

Notes:

- Keep provider-neutral terms only (`storefront_adapter`, not `storekit`/`play_billing` in core schema vocab).
- Ensure route-local visibility is preserved even when using shared profile.
- Make corridor reference required when `commerce` is declared.

## Denial Code Taxonomy (Explicit)

Use two-layer taxonomy:

- **Reason family (stable):** `:commerce_corridor`
- **Canonical code IDs (stable external strings):**
  - `commerce.corridor.undeclared`
  - `commerce.corridor.unsupported`
  - `commerce.corridor.prerequisite_missing`
  - `commerce.corridor.runtime_incompatible`
  - `commerce.corridor.entry_denied`
  - `commerce.corridor.origin_denied`
  - `commerce.corridor.policy_blocked`
  - `commerce.corridor.pack_incompatible`

Implementation guidance:

- Extend `Crosswake.Shell.Denial.@reasons` with `:commerce_corridor`.
- In compatibility/route-gate mapping, set `reason: :commerce_corridor` and explicit `code: "commerce.corridor.*"`.
- Always include:
  - `details`: corridor id, role, failing moment/prereq.
  - `recovery`: explicit fallback actions (never empty for corridor denials).

## Sequencing Recommendation

1. **Types + Schema first**
   - Add policy schema/route fields and manifest types for corridor registry and route reference.
2. **Compiler + Validator**
   - Normalize corridor declarations and enforce semantic/provider-neutral checks.
3. **Manifest Builder + Validator**
   - Build `commerce_corridors` registry, route `corridor_ref`, and referential integrity checks.
4. **Compatibility + Denials**
   - Add corridor runtime checks and canonical denial codes.
5. **Support truth surfaces**
   - Extend support matrix/doctor output with corridor prerequisite and denial/fallback truth.
6. **Guides + docs tests**
   - Update commerce/capabilities/support_matrix guidance with matrix-first corridor truth.
7. **Verification sweep**
   - Add/adjust tests across policy/manifest/compatibility/doctor/guides.

## Reuse, Do Not Hand-Roll

- Reuse route option normalization path (`Schema -> Route.new -> Compiler`), not ad hoc map munging.
- Reuse registry+reference pattern from packs/capabilities.
- Reuse `Compatibility.finding_to_denial` mapping style for corridor denials.
- Reuse support-matrix generation flow (`SupportMatrix.canonical -> Renderer -> guide equality tests`).
- Reuse doctor finding structure (`code`, `check`, `hint`, `details`) for corridor diagnostics.

## Common Pitfalls and Risk Controls

1. **Manifest schema drift risk**
   - Adding root sections may break strict key assertions and external consumers.
   - Mitigation: additive field with default `%{}` + explicit tests + compatibility guidance review.

2. **Provider vocabulary leakage**
   - Easy to leak StoreKit/Play terms into core corridor schema.
   - Mitigation: strict allowed-value vocab in validators and docs wording checks.

3. **Denial-family fragmentation**
   - Reusing legacy reasons inconsistently will create support drift.
   - Mitigation: route all corridor denials through one family and canonical code list.

4. **Route-level ownership ambiguity**
   - Shared profile use can hide route intent if binding is implicit.
   - Mitigation: require explicit per-route role even when profile is shared.

5. **Over-scoping into adapter implementation**
   - Phase 19 can accidentally slip into provider adapter work.
   - Mitigation: enforce "no provider/storefront implementation" in tests/docs scope checks.

## Verification Ideas Tied to COMM-04/05/06

- COMM-04 (DSL ownership distinction):
  - Policy schema tests for valid `commerce` binding and invalid ownership combos.
  - Compiler tests for explicit route-local role visibility and duplicate corridor id behavior.

- COMM-05 (manifest/support truth provider-neutral):
  - Manifest builder tests for root `commerce_corridors` + route `corridor_ref` output.
  - Manifest validator tests rejecting provider-specific vocab in corridor declarations.
  - Support matrix/doctor tests verifying corridor prerequisites + denial/fallback fields render.

- COMM-06 (fail-closed denials):
  - Compatibility + activation tests for undeclared/unsupported corridor denials.
  - Assertions for exact canonical code values and non-empty fallback/recovery metadata.
  - Negative tests proving no silent bridge/WebView fallback path.

## File-Level Change Map (Concise Planning Input)

- `lib/crosswake/policy/schema.ex` - add `commerce` option schema + validator.
- `lib/crosswake/policy/route.ex` - add normalized route commerce binding and semantic checks.
- `lib/crosswake/policy/compiler.ex` - improve hints/errors for commerce corridor fields.
- `lib/crosswake/policy/validator.ex` - enforce ownership/role/provider-neutral invariants.
- `lib/crosswake/manifest/types.ex` - add corridor structs and root/route fields (`commerce_corridors`, route commerce ref).
- `lib/crosswake/manifest/builder.ex` - compile corridor registry + route references.
- `lib/crosswake/manifest/validator.ex` - validate corridor completeness, refs, vocabulary, fallback presence.
- `lib/crosswake/shell/denial.ex` - add `:commerce_corridor` family support.
- `lib/crosswake/compatibility/compatibility.ex` - map corridor findings to canonical denial codes.
- `lib/crosswake/support_matrix/support_matrix.ex` - include corridor support truth rows/metadata.
- `lib/crosswake/support_matrix/renderer.ex` - render corridor support section in guide output.
- `lib/crosswake/doctor/doctor.ex` - emit corridor prerequisite and denial/fallback diagnostics.
- `lib/crosswake/doctor/formatter.ex` - print corridor diagnostics in human output.
- `lib/crosswake/doctor/json_formatter.ex` - include corridor posture in JSON output.
- `guides/commerce.md` - declaration patterns, corridor matrix, denial/fallback semantics.
- `guides/capabilities.md` - align ownership rubric with corridor roles.
- `guides/support_matrix.md` - generated corridor support truth section.

Likely test files to update/add:

- `test/crosswake/policy/schema_test.exs`
- `test/crosswake/policy/route_test.exs`
- `test/crosswake/policy/compiler_test.exs`
- `test/crosswake/manifest/manifest_test.exs`
- `test/crosswake/manifest/validator_test.exs`
- `test/crosswake/compatibility/compatibility_test.exs`
- `test/crosswake/shell/activation_test.exs`
- `test/crosswake/support_matrix/support_matrix_test.exs`
- `test/crosswake/support_matrix/renderer_test.exs`
- `test/crosswake/doctor/doctor_test.exs`
- `test/crosswake/doctor/formatter_test.exs`
- `test/mix/tasks/crosswake_doctor_test.exs`
- `test/crosswake/guides/commerce_test.exs`
- `test/crosswake/guides/capabilities_test.exs`

## Planning Decisions to Lock Before Implementation

1. Exact mechanism for named corridor profile declaration (router macro vs compile option).
2. Whether corridor support truth is a new support-matrix section now vs minimal doctor-only in Phase 19.
3. Whether adding `commerce_corridors` requires `manifest_schema_version` bump in this phase.

