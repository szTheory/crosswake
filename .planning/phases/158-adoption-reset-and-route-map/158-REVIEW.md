---
phase: 158-adoption-reset-and-route-map
reviewed: 2026-07-31T00:00:00Z
depth: standard
files_reviewed: 13
files_reviewed_list:
  - lib/crosswake/adoption/route_inventory.ex
  - test/crosswake/adoption/route_inventory_test.exs
  - lib/crosswake/capability_map.ex
  - lib/crosswake/capability_map/renderer.ex
  - test/crosswake/capability_map/capability_map_test.exs
  - test/crosswake/capability_map/renderer_test.exs
  - guides/capability_map.md
  - lib/crosswake/planning/first_adopter_context.ex
  - test/crosswake/planning/first_adopter_context_test.exs
  - lib/crosswake/support_matrix/support_matrix.ex
  - lib/crosswake/support_matrix/renderer.ex
  - test/crosswake/support_matrix/renderer_test.exs
  - guides/support_matrix.md
findings:
  critical: 3
  warning: 0
  info: 0
  total: 3
status: issues_found
---

# Phase 158: Code Review Report

**Reviewed:** 2026-07-31T00:00:00Z
**Depth:** standard
**Files Reviewed:** 13
**Status:** issues_found

## Summary

The route-inventory and public-guide renderers are deterministic and the scoped tests pass, but the new gate can promote an unsafe or incomplete concrete route. The privacy checker is also only a library/test seam, so it does not enforce the required repository boundary. These defects undermine the phase's fail-closed route and privacy claims.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Safety fields marked `known_default` can be promoted

**File:** `lib/crosswake/adoption/route_inventory.ex:192-206,109-113`
**Issue:** `validate_posture/3` accepts `:known_default` for every route-local safety field and preserves its supplied value. `promotion_status/1` blocks only `:unknown_blocking`, so an inventory whose runtime owner, offline posture, auth, scope, fallback, disablement, and retention facts all come from defaults is eligible. This directly defeats the route-map contract that a `known_default` is eligible only when it is not standing in for a safety field, and it permits a surface default to silently become route authority.
**Fix:** Reject `:known_default` for `@safety_fields` (or remove it from their vocabulary), and add a regression test asserting that such a row returns a field-specific error or `{:blocked, ...}`. Only explicitly confirmed, sanitized route-local values should satisfy the promotion gate.

### CR-02: Semantically contradictory or absent safety posture is eligible

**File:** `lib/crosswake/adoption/route_inventory.ex:192-205,109-113`
**Issue:** `:not_applicable` is accepted without a value for every safety field, and no cross-field validation runs before promotion. For example, a `:local_first` route with `scope_posture`, fallbacks, disablement, and queued-data retention all `:not_applicable` is eligible; so is `auth: :recent_auth` together with `recent_auth: :not_required`. This lets host/device proof promotion proceed without the required replay isolation, server-side disablement, or coherent auth contract.
**Fix:** Define and enforce route-state invariants before returning `{:eligible, ...}`. At minimum, local mutation must require an offline-island owner, confirmed opaque scope/logout/account-switch values, `:queue_local` offline fallback, retained queued data, and entry/replay enforcement; `:recent_auth` must require `recent_auth: :required`; required media must require verified integrity. Permit `:not_applicable` only for fields demonstrably irrelevant to the selected route state, and test each invalid combination.

### CR-03: Privacy checks are neither enforced nor complete for planning artifacts

**File:** `lib/crosswake/planning/first_adopter_context.ex:19-86,102-137,195-196`
**Issue:** The scanner has no production/CI caller: repository search finds only its own tests invoking `scan/1` or `scan_private_terms/2`. Even if a caller is added, the static matrix omits current phase artifacts such as `158-03-SUMMARY.md`, `158-04-PLAN.md`, `158-04-SUMMARY.md`, and `158-VALIDATION.md`, while `private_term_scanned?/1` deliberately skips every `*-PLAN.md`. A prohibited adopter term can therefore be committed to those planning documents without any automated rejection, violating RESET-04 and the project's no-identity rule.
**Fix:** Add a merge-blocking Mix task or test helper that reads every repository-facing durable/public/fast-changing artifact and invokes both scanners with the configured private terms. Derive the in-scope artifact set from approved directories/globs (with explicit narrow exclusions), include all phase documents, and do not blanket-exclude plans from private-term matching; exclude only known non-secret instruction tokens if necessary. Add canary tests for a summary, validation file, and plan file.

---

_Reviewed: 2026-07-31T00:00:00Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
