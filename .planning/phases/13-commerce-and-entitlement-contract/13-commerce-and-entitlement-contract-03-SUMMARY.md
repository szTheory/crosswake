# Phase 13 Plan 03: Publish the commerce boundary map for core, companions, and explicit native commerce corridors Summary

**Phase:** 13-commerce-and-entitlement-contract
**Plan:** 03
**Subsystem:** Documentation and Verification
**Completed Date:** 2026-05-19
**Duration:** 1h

## Dependency Graph
- **Requires:** Phase 13-01, Phase 13-02
- **Provides:** Explicit commerce boundary classifications, fail-closed native commerce corridor rules, companion-required rebuild posture, and coherent adopter profile map.
- **Affects:** `guides/capabilities.md`, `guides/commerce.md`, `guides/native_shell.md`, `guides/compatibility.md`, `guides/support_matrix.md`, `guides/adopter_profiles.md`, support matrix rendering logic.

## Tech Stack
- **Added:** N/A
- **Patterns:** Generated docs, explicit non-goals, mechanical docs verification, canonical source of truth for support matrices.

## Key Files
- **Created:** N/A
- **Modified:**
  - `lib/crosswake/support_matrix/support_matrix.ex`
  - `lib/crosswake/support_matrix/renderer.ex`
  - `lib/crosswake/manifest/builder.ex`
  - `guides/capabilities.md`
  - `guides/commerce.md`
  - `guides/native_shell.md`
  - `guides/compatibility.md`
  - `guides/support_matrix.md`
  - `guides/adopter_profiles.md`
  - `test/crosswake/support_matrix/renderer_test.exs`
  - `test/crosswake/guides/capabilities_test.exs`
  - `test/crosswake/guides/commerce_test.exs`
  - `test/crosswake/guides/adopter_profiles_test.exs`

## Key Decisions
- Moved `paywall_entry`, `purchase_intent`, `restore_intent`, `entitlement_snapshot`, and `reconciliation_evidence` to explicit `core` contract vocabulary instead of example/docs-only.
- Classified storefront purchase confirmation and SDK-owned session loops into required native corridors (Native-screen required).
- Explicitly documented that generic silent web checkout for digital goods is unsupported and fails closed.
- Reinforced that Phase 13 still does not ship a billing adapter, tying this explicitly back to existing adopter profiles.
- Established that storefront-sensitive companion adapters carry explicit `native or companion rebuild required` guidance.

## Deviations from Plan
- None - plan executed exactly as written.

## Threat Flags
None.

## Known Stubs
None.
