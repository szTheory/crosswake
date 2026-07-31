---
phase: 158-adoption-reset-and-route-map
reviewed: 2026-07-31T15:57:17Z
depth: standard
files_reviewed: 16
files_reviewed_list:
  - .github/workflows/hex-page-proof.yml
  - guides/capability_map.md
  - guides/support_matrix.md
  - lib/crosswake/adoption/route_inventory.ex
  - lib/crosswake/capability_map.ex
  - lib/crosswake/capability_map/renderer.ex
  - lib/crosswake/planning/first_adopter_context.ex
  - lib/crosswake/support_matrix/renderer.ex
  - lib/crosswake/support_matrix/support_matrix.ex
  - lib/mix/tasks/crosswake.adoption_context.scan.ex
  - test/crosswake/adoption/route_inventory_test.exs
  - test/crosswake/capability_map/capability_map_test.exs
  - test/crosswake/capability_map/renderer_test.exs
  - test/crosswake/planning/first_adopter_context_test.exs
  - test/crosswake/support_matrix/renderer_test.exs
  - test/mix/tasks/crosswake_adoption_context_scan_test.exs
findings:
  critical: 2
  warning: 1
  info: 0
  total: 3
status: issues_found
---

# Phase 158: Code Review Report

**Reviewed:** 2026-07-31T15:57:17Z
**Depth:** standard
**Files Reviewed:** 16
**Status:** issues_found

## Summary

The focused tests and generic scan pass, but the new privacy controls do not enforce two stated boundaries: public renderings can use the prohibited hyphenated wording, and purportedly opaque route references can contain identifying/customer values. Both paths can persist sensitive adoption context while passing the new gates.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Public privacy gate accepts prohibited public wording

**File:** `/Users/jon/projects/crosswake/lib/crosswake/planning/first_adopter_context.ex:175-182`

**Classification:** BLOCKER

**Issue:** The public-destination check treats both `first adopter` and `first-adopter` as compliant. AGENTS.md explicitly requires public guides to say `first adopter`; the phase renderer tests also reject the hyphenated form. Consequently, a future public capability/support artifact containing only the prohibited spelling passes `mix crosswake.adoption_context.scan`. Direct verification of `FirstAdopterContext.scan/1` with `"first-adopter"` returns `[]`, so CI cannot enforce the privacy/naming boundary it is intended to protect.

**Fix:** Require the exact approved public phrase and add a separate violation for the hyphenated form (case-insensitive), with regression tests for both conditions.

```elixir
public_phrase = Regex.match?(~r/first adopter/i, contents)
hyphenated_phrase = Regex.match?(~r/first-adopter/i, contents)

[]
|> maybe_add(not public_phrase, "privacy.public_phrase", path)
|> maybe_add(hyphenated_phrase, "privacy.public_hyphenated_phrase", path)
|> maybe_add(codename, "privacy.public_codename", path)
```

### CR-02: Route inventory permits identifying values despite claiming opaque references

**File:** `/Users/jon/projects/crosswake/lib/crosswake/adoption/route_inventory.ex:159-175`

**Classification:** BLOCKER

**Issue:** `route_id` and `path_pattern` accept arbitrary human-readable slugs and static path segments. For example, the validator accepts `route_id: "acme-customer"` and `path_pattern: "/customer/acme-customer"`. Those fields are then retained in the validated struct and may be recorded in planning/proof output. This violates the module's stated sanitized/opaque contract and the project's prohibition on customer information and proprietary taxonomy. The closed posture vocabularies do not mitigate this bypass because the identifying data is carried in the two unbounded string fields.

**Fix:** Make route references mechanically opaque and constrain path patterns to non-identifying, schema-defined route templates. For example, use generated opaque IDs and allow only approved static namespaces plus parameter placeholders; reject arbitrary literal segments. Add negative tests using customer-name and taxonomy-like slugs.

```elixir
defp validate_route_id(value) when is_binary(value) do
  if Regex.match?(~r/^route-[a-f0-9]{16}$/i, value),
    do: {:ok, value},
    else: {:error, error("RI-INVALID", "unresolved", "route_id")}
end
```

## Warnings

### WR-01: Checked-in renderer is not formatted by the repository formatter

**File:** `/Users/jon/projects/crosswake/lib/crosswake/capability_map/renderer.ex:184-190`

**Classification:** WARNING

**Issue:** `mix format --check-formatted` fails on this changed file, which creates a divergent local/CI quality result even though the focused tests pass.

**Fix:** Run `mix format lib/crosswake/capability_map/renderer.ex` and retain the formatted multi-line match clauses.

---

_Reviewed: 2026-07-31T15:57:17Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
