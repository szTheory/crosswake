---
phase: 158-adoption-reset-and-route-map
reviewed: 2026-07-31T18:58:26Z
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
  warning: 2
  info: 0
  total: 4
status: issues_found
---

# Phase 158: Code Review Report

**Reviewed:** 2026-07-31T18:58:26Z
**Depth:** standard
**Files Reviewed:** 16
**Status:** issues_found

## Summary

The route-inventory, guide-rendering, and context-scanning changes were reviewed together. Focused tests (73 tests) and formatting pass, but the privacy scanner can miss public sensitive content and the protected CI lane rejects every fork PR despite the phase's stated policy.

## Critical Issues

### CR-01: Single-digit dollar prices bypass the privacy scanner

**File:** `/Users/jon/projects/crosswake/lib/crosswake/planning/first_adopter_context.ex:177`
**Issue:** `privacy.commercial_detail` only matches a dollar amount with at least two digits or a decimal fraction. A durable/public artifact containing a prohibited one-digit whole-dollar price is accepted, while a two-digit price is rejected. This violates the durable-data rule that prices must not enter repository-facing artifacts and turns the privacy gate into a bypassable control.
**Fix:** Match any decimal currency amount, while retaining a word/boundary guard to reduce prose false positives. Add filesystem and Mix-task tests for zero, one-digit, two-digit, and decimal amounts.

```elixir
{"privacy.commercial_detail", ~r/\$\s*\d+(?:\.\d{1,2})?\b/}
```

### CR-02: Textual SVG artifacts are excluded from the privacy scan

**File:** `/Users/jon/projects/crosswake/lib/crosswake/planning/first_adopter_context.ex:58`
**Issue:** `.svg` is listed as a binary extension, so a tracked SVG is marked `scan?: false` without its XML/text being inspected. SVGs are routinely textual, rendered in public documentation, and can contain the adopter name, price, links, or private terms. That creates an unscanned public-artifact path despite the scanner's stated repository-facing privacy boundary.
**Fix:** Remove `.svg` from `@binary_extensions` so it is handled by the already-supported textual extension path, and add a test that a tracked SVG containing a synthetic private term or commercial amount produces only the stable rule/path violation.

```elixir
@binary_extensions ~w(.a .app .beam .bundle .dylib .gif .gz .ico .jar .jpeg .jpg .mp3 .mp4 .o .pdf .png .so .webp .zip)
```

## Warnings

### WR-01: Duplicate route fields escape the safe validator error contract

**File:** `/Users/jon/projects/crosswake/lib/crosswake/adoption/route_inventory.ex:89`
**Issue:** A keyword input with the same allowed key twice passes the local field checks and `NimbleOptions.validate/2` returns `%NimbleOptions.ValidationError{}` rather than the documented `%ValidationError{}`. Consequently `validate/1` violates its own result type, and `validate!/1` raises an implementation-specific error instead of the stable `RI-*` safe error required for invalid route rows.
**Fix:** Reject duplicate keys before calling NimbleOptions and return a stable `ValidationError`; add duplicate required-field and duplicate forbidden-field regression tests.

```elixir
defp reject_duplicate_fields(options) do
  case Enum.find(Keyword.keys(options), fn key -> Keyword.get_values(options, key) |> length() > 1 end) do
    nil -> :ok
    field -> {:error, error("RI-DUPLICATE_FIELD", route_ref(options), field)}
  end
end
```

### WR-02: Protected scan makes all fork pull requests fail solely for missing secrets

**File:** `/Users/jon/projects/crosswake/.github/workflows/hex-page-proof.yml:61`
**Issue:** Every PR from a fork reaches this step and exits `1`. The phase decision explicitly requires that ordinary fork PRs not fail merely because private CI secrets are unavailable; the protected scan must instead run from trusted maintainer provenance before promotion. This workflow makes the public CI check permanently red for all external contributors, even after the non-secret scan has passed.
**Fix:** Skip the secret-backed scan for forks without failing that PR's public lane, and enforce the protected scan through a maintainer-controlled merge queue, trusted branch workflow, or separately required protected check.

```yaml
- name: Enforce protected first-adopter private-term gate
  if: github.event_name != 'pull_request' || github.event.pull_request.head.repo.full_name == github.repository
  run: mix crosswake.adoption_context.scan --require-private-terms
# Require this trusted workflow/check in branch protection; do not fail fork PRs here.
```

---

_Reviewed: 2026-07-31T18:58:26Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
