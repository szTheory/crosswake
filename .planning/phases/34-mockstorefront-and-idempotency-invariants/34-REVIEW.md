---
phase: 34-mockstorefront-and-idempotency-invariants
reviewed: 2026-05-29T00:00:00Z
depth: standard
files_reviewed: 2
files_reviewed_list:
  - examples/phoenix_host/lib/crosswake_example/commerce/mock_storefront.ex
  - test/crosswake/proof/phase34_mock_storefront_test.exs
findings:
  critical: 0
  warning: 2
  info: 1
  total: 3
status: issues_found
---

# Phase 34: Code Review Report

**Reviewed:** 2026-05-29T00:00:00Z
**Depth:** standard
**Files Reviewed:** 2
**Status:** issues_found

## Summary

Reviewed `mock_storefront.ex` (new provider-neutral evidence emitter) and `phase34_mock_storefront_test.exs` (hermetic idempotency-invariant proof). The implementation logic is sound: identity derivation is correctly anchored on `entry_id` / `@subscription_entry_id`, `correlation_id` is correctly excluded from all key derivations, the replay invariant proof wire (WIRE-03) is correctly exercised, and the D-06 subject-key sharing between purchase and restore is correctly proven. All 20 tests pass.

Two warnings surfaced, both in the test file. Neither touches `mock_storefront.ex` itself.

## Warnings

### WR-01: Unused alias `ReconciliationKeys` aborts test suite under `--warnings-as-errors`

**File:** `test/crosswake/proof/phase34_mock_storefront_test.exs:31`

**Issue:** `ReconciliationKeys` is aliased but never referenced in any test body. The compiler emits:

```
warning: unused alias ReconciliationKeys
  test/crosswake/proof/phase34_mock_storefront_test.exs:31
```

Verification: running `mix test test/crosswake/proof/phase34_mock_storefront_test.exs --warnings-as-errors` aborts with `ERROR! Test suite aborted after successful execution due to warnings while using the --warnings-as-errors option`. The project's CI uses `mix compile --warnings-as-errors` (which compiles only `lib/`, not test files), so this warning does not currently fail the merge gate. It will, however, break any developer or future CI step that runs `mix test --warnings-as-errors` across the full suite.

**Fix:** Remove the unused alias.

```elixir
# Remove line 31:
alias CrosswakeExample.Commerce.ReconciliationKeys
```

If `ReconciliationKeys` is needed for a future test, add it back at that point.

---

### WR-02: `File.read!` in source-fence and doc tests relies on `mix`-imposed CWD, not `__DIR__`

**File:** `test/crosswake/proof/phase34_mock_storefront_test.exs:43,54`

**Issue:** Both source-file inspection tests use a bare relative path:

```elixir
File.read!("examples/phoenix_host/lib/crosswake_example/commerce/mock_storefront.ex")
```

This resolves relative to the OS process working directory, not relative to the test file's location. `mix test` always sets CWD to the project root, so the tests pass today. However, the three `Code.require_file` calls at the top of the same file (lines 1–3) correctly use `__DIR__`-relative paths:

```elixir
Code.require_file("../../../examples/phoenix_host/lib/.../reconciliation_keys.ex", __DIR__)
```

The inconsistency means that any invocation outside `mix` (e.g., `elixir test/...`, a language-server evaluation, or a future runner that sets a different CWD) will crash with `(File.Error) could not read file ... no such file or directory`, while the `Code.require_file` lines above it succeed.

**Fix:** Use `Path.expand` anchored on `__DIR__` for consistency with the rest of the file:

```elixir
# line 43
content =
  Path.expand("../../../examples/phoenix_host/lib/crosswake_example/commerce/mock_storefront.ex", __DIR__)
  |> File.read!()
  |> String.downcase()

# line 54
source =
  Path.expand("../../../examples/phoenix_host/lib/crosswake_example/commerce/mock_storefront.ex", __DIR__)
  |> File.read!()
```

---

## Info

### IN-01: `simulate_restore/2` accepts but entirely ignores its `RestoreIntent` argument

**File:** `examples/phoenix_host/lib/crosswake_example/commerce/mock_storefront.ex:67`

**Issue:** The function signature accepts a `%Contracts.RestoreIntent{}` struct but the argument is bound to `_intent` and not used at all. All output is derived from the module constant `@subscription_entry_id`. The module-level `@moduledoc` explains the AF-04 single-product anchor, but the function itself carries no inline note that this is intentional.

This is not a bug (the design intent is clear at the module level and the test suite proves the anchor is correct). It is flagged because a future maintainer adding a second subscription tier may instinctively call `_intent.entry_id` inside this function, which would be architecturally correct for a multi-product restore but silently wrong in this single-product mock unless the function signature also changes.

**Fix (optional):** Add a one-line doc comment directly on the function to make the intentional discard explicit:

```elixir
# Anchored on @subscription_entry_id (AF-04 single product). intent is accepted
# for API symmetry with a real adapter but is intentionally unused in the mock.
def simulate_restore(%Contracts.RestoreIntent{} = _intent, opts \\ []) do
```

---

_Reviewed: 2026-05-29T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
