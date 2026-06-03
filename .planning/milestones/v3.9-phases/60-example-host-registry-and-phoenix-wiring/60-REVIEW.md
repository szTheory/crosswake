---
phase: 60-example-host-registry-and-phoenix-wiring
reviewed: 2026-06-02T00:00:00Z
depth: standard
files_reviewed: 8
files_reviewed_list:
  - examples/phoenix_host/lib/crosswake_example/chimeway/metadata_sanitizer.ex
  - examples/phoenix_host/lib/crosswake_example/chimeway/token_binding.ex
  - examples/phoenix_host/lib/crosswake_example/chimeway/token_binding_event.ex
  - examples/phoenix_host/lib/crosswake_example/chimeway/registry.ex
  - examples/phoenix_host/priv/repo/migrations/20260602100000_create_chimeway_token_bindings.exs
  - examples/phoenix_host/priv/repo/migrations/20260602100100_create_chimeway_token_binding_events.exs
  - examples/phoenix_host/README.md
  - test/crosswake/proof/phase60_chimeway_registry_test.exs
findings:
  critical: 1
  warning: 5
  info: 4
  total: 10
status: issues_found
---

# Phase 60: Code Review Report

**Reviewed:** 2026-06-02
**Depth:** standard
**Files Reviewed:** 8
**Status:** issues_found

## Summary

Reviewed the backend-owned Chimeway push-token binding registry: two Ecto schemas, two
migrations, a metadata sanitizer, the `Ecto.Multi`-based lifecycle registry, the README
worker guidance, and the hermetic proof test.

The security primitives that were the stated focus hold up well under tracing: no raw
APNs/FCM token columns exist, the sanitizer drops both atom- and string-keyed forbidden
keys without `String.to_atom/1`, audit rows carry no cascade-delete path, and telemetry
genuinely fires only after `Repo.transaction/1` returns `{:ok, _}`. The proof test exercises
these claims directly.

However, the provider-feedback invalidation path contains a **fan-out data-loss bug**: when
feedback arrives with neither a `token_fingerprint` nor a `token_ref`, the matching query
degrades to "all active bindings" and the transaction will invalidate/revoke **every active
token binding in the table**. This is the headline blocker. Several correctness and
consistency warnings follow (success-on-zero-match contract drift, unordered telemetry
zipping, dead rotation-reason code, and a session-version validation gap).

## Critical Issues

### CR-01: Empty-selector provider feedback invalidates ALL active bindings

**File:** `examples/phoenix_host/lib/crosswake_example/chimeway/registry.ex:818-872`

**Issue:** `do_feedback_invalidate/5` builds its target query by progressively narrowing on
`token_fingerprint`, then falling back to `token_ref`:

```elixir
query = from(b in TokenBinding, where: b.state == :active)

query =
  case fb.token_fingerprint do
    fp when is_binary(fp) and byte_size(fp) > 0 -> where(query, [b], b.token_fingerprint == ^fp)
    _ ->
      case fb.token_ref do
        tr when is_binary(tr) and byte_size(tr) > 0 -> where(query, [b], b.token_ref == ^tr)
        _ -> query        # <-- no narrowing applied
      end
  end
```

When an invalidating feedback event (`:token_unregistered`, `:token_invalid`,
`:environment_mismatch`, `:app_identity_mismatch`) arrives with both `token_fingerprint`
and `token_ref` absent or empty (a `%ProviderFeedback{}` allows both to be `nil` — neither
is in `@enforce_keys`, and `Redaction.feedback_from_provider_attrs/1` happily populates them
as `nil`), the `_ -> query` branch leaves the query as "all rows where `state == :active`."
The `:invalidate` step then runs `update_all` over **every active binding in the entire
registry**, transitioning all of them to `:revoked`/`:invalid` and writing one audit row per
binding. There is no provider/platform/environment scoping either, so a single malformed or
hostile feedback payload can wipe the active set for all subjects, orgs, and installations in
one transaction. The terminal-timestamp and audit-event logic all execute, so the damage is
fully committed.

Provider feedback is `actor_kind: :provider, proof_class: :advisory` — i.e. lower-trust,
externally-influenced input — which makes an unbounded fan-out from missing selectors
especially dangerous.

**Fix:** Fail closed when no token selector is present. Require at least one of
`token_fingerprint`/`token_ref` before running an invalidating update, and ideally also scope
by `provider`/`platform`/`environment`:

```elixir
defp do_feedback_invalidate(fb, binding_state, binding_reason, now, opts) do
  with {:ok, base_query} <- feedback_target_query(fb) do
    # ... existing Ecto.Multi pipeline, using base_query ...
  end
end

defp feedback_target_query(fb) do
  fp = fb.token_fingerprint
  tr = fb.token_ref

  cond do
    is_binary(fp) and byte_size(fp) > 0 ->
      {:ok,
       from(b in TokenBinding,
         where:
           b.state == :active and b.token_fingerprint == ^fp and
             b.provider == ^fb.provider and b.platform == ^fb.platform and
             b.environment == ^fb.environment
       )}

    is_binary(tr) and byte_size(tr) > 0 ->
      {:ok,
       from(b in TokenBinding,
         where:
           b.state == :active and b.token_ref == ^tr and
             b.provider == ^fb.provider and b.platform == ^fb.platform and
             b.environment == ^fb.environment
       )}

    true ->
      {:error, :feedback_missing_token_selector}
  end
end
```

Add a regression test: invalidating feedback with `token_fingerprint: nil, token_ref: nil`
must return `{:error, :feedback_missing_token_selector}` and leave all bindings `:active`.

## Warnings

### WR-01: Invalidating feedback reports `:invalidated` success when zero bindings matched

**File:** `examples/phoenix_host/lib/crosswake_example/chimeway/registry.ex:844-846, 878-880, 929-967`

**Issue:** When a (properly selected) invalidating feedback matches no active bindings, the
`:invalidate` step returns `{:ok, 0}`, the `:audit_events` step returns `{:ok, []}`, the
transaction commits, and the final `{:ok, %{bindings: bindings, ...}}` clause runs with
`bindings == []`. It then builds a `BindingResult` with `status: :invalidated` and
`binding_ref: List.first(bindings, %{binding_ref: fb.token_ref || "unknown"}).binding_ref`.
A caller therefore receives `status: :invalidated` and a fabricated `binding_ref` even though
nothing was invalidated and no audit evidence was written. This contradicts the revocation
flows (`revoke_for_logout`, `revoke_for_session_revocation`, `revoke_for_permission_loss`)
which return `{:error, :no_active_bindings}` on an empty match, so the API is internally
inconsistent and callers cannot distinguish "invalidated 3 tokens" from "matched nothing."

**Fix:** Return a distinct no-op result for the empty-match case (e.g.
`{:ok, %{bindings: [], audit_events: [], result: <status: :noop>}}`) or `{:error,
:no_active_bindings}` to mirror the revocation flows. Do not emit `status: :invalidated`
with a synthesized `binding_ref` when nothing changed.

### WR-02: Telemetry pairs bindings to audit events by position with no shared ordering

**File:** `examples/phoenix_host/lib/crosswake_example/chimeway/registry.ex:533-535, 552-558` (and the identical pattern at 621-623/641-647, 702-704/721-727, 874-876/937-943, 1037-1039/1087-1093)

**Issue:** Bulk flows build `bindings` from `repo.all(from b in TokenBinding, where:
b.binding_ref in ^binding_refs)` and `events` from `insert_revocation_events/.../reduce_while`
over `pre_bindings`. The two collections come from different queries: `events` preserves the
`pre_bindings` order, but the `bindings` re-query has **no `order_by`**, so SQL is free to
return rows in any order. `Enum.zip(bindings, events)` then pairs each binding's metadata with
a positionally-unrelated event. Emitted telemetry can attach the wrong `event.proof_class`/
correlation to a binding. For multi-row revocations this silently corrupts per-binding
telemetry attribution.

**Fix:** Sort both collections by `binding_ref` before zipping, or build the telemetry
metadata from a single source. For example, key events by `binding_ref` and look them up:

```elixir
events_by_ref = Map.new(events, &{&1.binding_ref, &1})

for binding <- bindings, event = events_by_ref[binding.binding_ref], not is_nil(event) do
  Telemetry.execute([:crosswake, :notification, :token, :revoked], %{}, telemetry_meta(binding, event))
end
```

### WR-03: `revoke_for_logout` without `session_ref` revokes across all sessions for the subject/org

**File:** `examples/phoenix_host/lib/crosswake_example/chimeway/registry.ex:489-504`

**Issue:** The moduledoc and `@doc` describe `revoke_for_logout/2` as "session-scoped logout
revocation." But when `ctx[:session_ref]` is not a binary, the `case` falls through to the
unfiltered `query`, revoking **every** active binding for `subject_ref` + `org_ref` regardless
of session or installation. A caller that omits `session_ref` (easy to do — it is optional in
`validate_context/1`) silently performs an org-wide subject revocation rather than a
session-scoped one. This is a footgun that contradicts the documented contract and can revoke
bindings belonging to other live sessions/devices of the same subject.

**Fix:** Either require `session_ref` for `revoke_for_logout/2` (return `{:error,
{:session_ref, :required}}` when absent), or rename/redocument the function to make the
broad subject-wide behavior explicit. Do not let an omitted optional field silently widen the
blast radius.

### WR-04: Rotated binding records `reason: :initial_bind` instead of `:token_rotated`

**File:** `examples/phoenix_host/lib/crosswake_example/chimeway/registry.ex:286-296, 367-389, 1194-1217`

**Issue:** When a rotation occurs (displaced bindings exist), the newly inserted binding is
built via `build_binding_attrs/4`, which hardcodes `reason: :initial_bind` (line 1211). The
dead branch at lines 287-290 even computes `is_rotation` and then assigns `:initial_bind` in
both arms before discarding it (`_ = reason`), signaling that `:token_rotated` was intended
for the rotated case but never wired in. The persisted active binding and its `:bound` audit
event both claim `reason: :initial_bind` for what is actually a token rotation. The `:reason`
enum includes `:token_rotated` specifically for this, and the displaced rows are correctly
marked `:token_rotated` — only the new binding is mislabeled. This degrades the audit/forensic
accuracy that is the stated purpose of these rows.

**Fix:** Pass the rotation reason into `build_binding_attrs/4` and the `:bound` audit event:

```elixir
reason = if is_rotation, do: :token_rotated, else: :initial_bind
binding_attrs = build_binding_attrs(ctx, ev, installation_ref, now, reason)
```

and use that `reason` in the rotation `:bound` event at lines 367-389 instead of the
hardcoded `:initial_bind`. Then remove the dead `_ = reason` discard.

### WR-05: `subject_session` bindings accept a missing `session_version`

**File:** `examples/phoenix_host/lib/crosswake_example/chimeway/token_binding.ex:128-141`

**Issue:** `validate_scope_consistency/1` requires `session_ref` for `:subject_session` scope
but only applies `validate_number(:session_version, ...)`, which is a no-op when the field is
absent (Ecto skips number validation for `nil`/missing values). A `:subject_session` binding
can therefore be created with `session_ref` present but `session_version` nil. Downstream,
`revoke_for_session_revocation/2` relies on `session_version` for version-guarded revocation
(`is_nil(b.session_version) or b.session_version <= ^version`, line 588) — a session binding
with a null version will always be revoked regardless of the requested version, defeating the
"newer sessions survive" guarantee (D-21) for any binding that slipped through without a
version.

**Fix:** If `session_version` is semantically required for session-scoped bindings, add it to
the required set within `validate_scope_consistency/1`:

```elixir
:subject_session ->
  changeset
  |> validate_required([:session_ref, :session_version])
  |> validate_number(:session_version, greater_than_or_equal_to: 0)
```

If it is genuinely optional, document and confirm the null-version revocation behavior is
intended.

## Info

### IN-01: Dead/no-op rotation reason computation

**File:** `examples/phoenix_host/lib/crosswake_example/chimeway/registry.ex:287-290`

**Issue:** `is_rotation = not Enum.empty?(displaced)` followed by `reason = if is_rotation,
do: :initial_bind, else: :initial_bind` (both branches identical) and `_ = reason` is dead
code — the computed value is discarded and never influences behavior.

**Fix:** Remove these lines, or wire them into the binding `reason` as described in WR-04.

### IN-02: Repeated `now_dt = now` aliasing adds noise

**File:** `examples/phoenix_host/lib/crosswake_example/chimeway/registry.ex:248, 339`

**Issue:** `now_dt = now` rebinds an already-bound variable to the same value, then uses
`now_dt`. It adds no clarity and is inconsistent with the rest of the module, which uses `now`
directly.

**Fix:** Use `now` directly and delete the `now_dt` aliases.

### IN-03: `:request_ref` column and field are never populated

**File:** `examples/phoenix_host/lib/crosswake_example/chimeway/token_binding_event.ex:80`, `examples/phoenix_host/priv/repo/migrations/20260602100100_create_chimeway_token_binding_events.exs:24,44`

**Issue:** `request_ref` is declared as a schema field, migrated as a column, and indexed, but
`build_audit_attrs/2` never sets it and it is absent from `@optional` cast list — so it is
dead surface area that can never be written through the registry. An indexed column that is
always null is a maintenance/clarity cost.

**Fix:** Either thread `request_ref` through `build_audit_attrs/2` (and add it to
`@optional`) so the index is meaningful, or drop the field, column, and index if it is not
used in Phase 60.

### IN-04: `app_identity_ref` declared but never written by the registry

**File:** `examples/phoenix_host/lib/crosswake_example/chimeway/token_binding.ex:33`, `examples/phoenix_host/lib/crosswake_example/chimeway/registry.ex:1194-1217`

**Issue:** `app_identity_ref` is a schema field and migration column, but `build_binding_attrs/4`
never sets it and it is not in `@optional`, so the registry can never persist it. Like
IN-03, this is dead persistence surface for Phase 60.

**Fix:** Wire `app_identity_ref` from evidence/context into `build_binding_attrs/4` and
`@optional`, or remove it until it is used.

---

_Reviewed: 2026-06-02_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
