---
phase: 60-example-host-registry-and-phoenix-wiring
fixed_at: 2026-06-02T00:00:00Z
review_path: .planning/phases/60-example-host-registry-and-phoenix-wiring/60-REVIEW.md
iteration: 1
findings_in_scope: 6
fixed: 6
skipped: 0
status: all_fixed
---

# Phase 60: Code Review Fix Report

**Fixed at:** 2026-06-02
**Source review:** `.planning/phases/60-example-host-registry-and-phoenix-wiring/60-REVIEW.md`
**Iteration:** 1

**Summary:**
- Findings in scope: 6
- Fixed: 6
- Skipped: 0

## Fixed Issues

### CR-01: Empty-selector provider feedback invalidates ALL active bindings

**Files modified:** `examples/phoenix_host/lib/crosswake_example/chimeway/registry.ex`, `test/crosswake/proof/phase60_chimeway_registry_test.exs`
**Commit:** cd5a7cd
**Applied fix:** Extracted `feedback_target_query/1` private helper that uses a `cond` with three branches:
  (1) match on `token_fingerprint` — scoped to `provider`/`platform`/`environment`,
  (2) match on `token_ref` — scoped to `provider`/`platform`/`environment`,
  (3) neither present → `{:error, :feedback_missing_token_selector}` (fail closed).
`do_feedback_invalidate/5` now wraps the entire `Ecto.Multi` pipeline in a `with {:ok, query} <- feedback_target_query(fb)` guard — if no selector is present the function returns the error immediately before touching the database. The old unbounded `_ -> query` fallthrough is gone.

Regression test added: `"CR-01 regression: feedback with no token selector fails closed and leaves active bindings intact"` — binds two unrelated active bindings, sends `%ProviderFeedback{}` with `token_ref: nil, token_fingerprint: nil`, asserts return is `{:error, :feedback_missing_token_selector}`, and confirms both bindings remain `:active`.

### WR-01: Invalidating feedback reports success when zero bindings matched

**Files modified:** `examples/phoenix_host/lib/crosswake_example/chimeway/registry.ex`, `test/crosswake/proof/phase60_chimeway_registry_test.exs`
**Commit:** cd5a7cd
**Applied fix:** In `do_feedback_invalidate/5`, the `:invalidate` Multi step previously returned `{:ok, 0}` on empty match; it now returns `{:error, :no_active_bindings}`. A new `{:error, :invalidate, :no_active_bindings, _changes} -> {:error, :no_active_bindings}` clause in the `case result` block surfaces this as the function return value, consistent with the revocation flows.

Regression test added: `"WR-01 regression: invalidating feedback matching zero active bindings returns error"` — sends invalidating feedback with a non-existent `token_fingerprint` and asserts `{:error, :no_active_bindings}`.

### WR-02: Telemetry pairs bindings to audit events by position with no shared ordering

**Files modified:** `examples/phoenix_host/lib/crosswake_example/chimeway/registry.ex`
**Commit:** cd5a7cd
**Applied fix:** Fixed the telemetry pairing in all five bulk flows that had the ordering bug:

- `do_revoke_for_logout_scoped`, `do_revoke_for_session_revocation`, `do_revoke_for_permission_loss`, `do_prune_stale`: the `:bindings` re-query now includes `order_by: b.binding_ref`. The `Enum.zip(bindings, events)` telemetry loop is replaced with a `Map.new(events, &{&1.binding_ref, &1})` lookup.

- `insert_revocation_events/6` and `insert_permission_loss_events/5`: `pre_bindings` is sorted by `binding_ref` before the `Enum.reduce_while` so the emitted events are in the same order as the re-queried `:bindings`.

- `do_feedback_invalidate/5`: `pre_bindings` is also sorted by `binding_ref` in the `:audit_events` Multi step; `:bindings` re-query includes `order_by: b.binding_ref`; telemetry loop uses `events_by_ref` map lookup.

### WR-03: `revoke_for_logout` without `session_ref` silently widens scope

**Files modified:** `examples/phoenix_host/lib/crosswake_example/chimeway/registry.ex`
**Commit:** cd5a7cd
**Applied fix:** `do_revoke_for_logout/2` now dispatches on `ctx[:session_ref]`:
- If `session_ref` is a non-empty binary → delegates to `do_revoke_for_logout_scoped/3`, which builds a query scoped to `subject_ref AND org_ref AND session_ref AND state == :active` (no conditional narrowing needed).
- Otherwise → returns `{:error, {:session_ref, :required}}` immediately.

The old unconditional `subject_ref + org_ref` base query with optional `session_ref` narrowing is gone. Callers that were previously relying on the silent widening behavior will now receive an explicit error and need to call a different function if org-wide revocation is desired.

### WR-04: Rotated bindings persist `reason: :initial_bind` instead of `:token_rotated`

**Files modified:** `examples/phoenix_host/lib/crosswake_example/chimeway/registry.ex`
**Commit:** cd5a7cd
**Applied fix:**
- `build_binding_attrs/4` → `build_binding_attrs/5`: added an optional `reason` parameter (defaulting to `:initial_bind` for backward compatibility with non-rotation callers).
- In the `:binding` Multi step, dead code `is_rotation = ...; reason = if is_rotation, do: :initial_bind, else: :initial_bind; _ = reason` replaced with `is_rotation = not Enum.empty?(displaced); reason = if is_rotation, do: :token_rotated, else: :initial_bind`. `build_binding_attrs` called with this `reason`.
- In the `:audit_events` Multi step, the rotation `:bound` event's `reason` field changed from hardcoded `:initial_bind` to `:token_rotated`.
- The `now_dt = now` alias in the rotation branch is preserved as-is (IN-02 is Info-only and out of scope).

### WR-05: `subject_session` bindings accept a missing `session_version`

**Files modified:** `examples/phoenix_host/lib/crosswake_example/chimeway/token_binding.ex`, `test/crosswake/proof/phase60_chimeway_registry_test.exs`
**Commit:** cd5a7cd
**Applied fix:** In `validate_scope_consistency/1`, the `:subject_session` branch now calls `validate_required([:session_ref, :session_version])` (adding `:session_version` to the required set) before `validate_number(:session_version, greater_than_or_equal_to: 0)`. A `nil` `session_version` now produces a validation error rather than silently passing.

Regression test added: `"WR-05 regression: subject_session changeset without session_version is invalid"` — asserts the changeset is invalid without `session_version`, valid with `session_version: 0`, and invalid with `session_version: -1`.

## Skipped Issues

None — all six in-scope findings (CR-01, WR-01 through WR-05) were fixed.

---

_Fixed: 2026-06-02_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
