---
phase: 96-docs-contract-proof
reviewed: 2026-06-10T00:00:00Z
depth: standard
files_reviewed: 9
files_reviewed_list:
  - .github/workflows/phase96-proof-advisory.yml
  - .github/workflows/phase96-proof.yml
  - examples/phoenix_host/lib/crosswake_example/audit/ledger.ex
  - examples/phoenix_host/lib/crosswake_example/saas_portal/step_up_challenge_live.ex
  - examples/phoenix_host/mix.exs
  - examples/phoenix_host/priv/repo/migrations/20260611000000_create_crosswake_audit_events.exs
  - examples/phoenix_host/test/crosswake_example/threadline/phase96_example_host_ledger_proof_test.exs
  - guides/threadline.md
  - test/crosswake/proof/phase96_threadline_docs_contract_test.exs
findings:
  critical: 2
  warning: 4
  info: 3
  total: 9
status: issues_found
---

# Phase 96: Code Review Report

**Reviewed:** 2026-06-10T00:00:00Z
**Depth:** standard
**Files Reviewed:** 9
**Status:** issues_found

## Summary

Phase 96 ships a docs-contract proof suite (hermetic + advisory lanes), the example-host Ecto audit ledger, a guide, and a step-up LiveView. The hermetic lane is structurally sound. Two blockers were found: an atom-table exhaustion vector in the LiveView and a nil-dereference crash on route lookup. Four warnings cover a misleading function name, a wrong arity in the guide, a mislabeled hash algorithm in the guide, and an unhandled non-info shell message type in the proof test.

## Critical Issues

### CR-01: `String.to_atom/1` on DB-sourced map keys — atom table exhaustion DoS

**File:** `examples/phoenix_host/lib/crosswake_example/saas_portal/step_up_challenge_live.ex:109`

**Issue:** `normalize_key/1` calls `String.to_atom/1` on every key from `intent.projected_authority`, which is a `:map` (JSON) column loaded from the database. Atoms in the BEAM are never garbage-collected; the atom table is bounded (default 1_048_576 atoms). An attacker — or a logic bug — that writes arbitrary string keys into the `projected_authority` column of a `StepUpIntent` row can exhaust the atom table and crash the node. The companion helper `string_to_existing_atom/1` correctly uses `String.to_existing_atom/1` with a rescue, but the map-key normalizer at line 109 uses the unsafe variant for all keys, bypassing that protection entirely.

**Fix:** Replace the unsafe `String.to_atom` in `normalize_key/1` with `String.to_existing_atom/1` using the same rescue pattern already in the file, or enumerate the finite set of known keys explicitly:

```elixir
defp normalize_key(key) when is_atom(key), do: key
defp normalize_key(key) when is_binary(key) do
  String.to_existing_atom(key)
rescue
  ArgumentError -> key   # unknown key: pass through as string; caller ignores it
end
defp normalize_key(key), do: key
```

---

### CR-02: Nil-dereference crash when `return_route_id` maps to no manifest route

**File:** `examples/phoenix_host/lib/crosswake_example/saas_portal/step_up_challenge_live.ex:73,102`

**Issue:** Line 73 does `route = manifest.routes[intent.return_route_id]`. If `intent.return_route_id` does not exist in the compiled manifest (stale intent, route deleted/renamed, or a serialization mismatch), `route` is `nil`. Line 102 then evaluates `route.path`, which raises `UndefinedFunctionError` (nil has no `.path` field) inside `handle_event/3`. LiveView will crash and the user sees an error page with no recovery path. The `Manifest.compile/1` failure at line 72 shares the same pattern: a bare `{:ok, ...} =` match raises `MatchError` on `{:error, _}` with no user-facing fallback.

**Fix:** Guard route lookup and provide a graceful degradation:

```elixir
case manifest.routes[intent.return_route_id] do
  nil ->
    {:noreply,
     socket
     |> put_flash(:error, "Step-up complete but return route is unavailable.")
     |> redirect(to: "/")}

  route ->
    {:noreply, redirect(socket, to: route.path)}
end
```

Apply the same pattern to the `Manifest.compile/1` and `Contracts.new_session_authority_lane/1` calls:

```elixir
case Manifest.compile(Router) do
  {:ok, %{manifest: manifest}} -> # ... proceed
  {:error, _diag} ->
    {:noreply, put_flash(socket, :error, "Internal configuration error.")}
end
```

---

## Warnings

### WR-01: `record/1` returns a changeset, not a persisted record — misleading name and doc

**File:** `examples/phoenix_host/lib/crosswake_example/audit/ledger.ex:136-139`

**Issue:** The public function is named `record/1` and documented as "Records an audit event standalone." It does not persist anything — it returns a raw changeset. A caller who writes `Ledger.record(attrs)` and discards the return value silently drops the event. The name and docstring both imply persistence. The WARNING note in the doc points to `record_in_multi/3` but does not clarify that this function does zero I/O.

**Fix:** Rename to `build_changeset/1` or `new_changeset/1`, or update the `@doc` to open with `Builds (but does not insert) an audit event changeset.` to make the no-I/O contract explicit:

```elixir
@doc """
Builds an audit event changeset without inserting it.

Call `Repo.insert(record(attrs))` to persist, or prefer `record_in_multi/3`
to insert within an existing transaction.
"""
def record(attrs) do
```

---

### WR-02: `guides/threadline.md` documents `record_in_multi/2` but the function has arity 3

**File:** `guides/threadline.md:128`

**Issue:** The guide reads: `Use \`record_in_multi/2\` to insert audit events...` The actual function signature in both `ledger.ex` (line 146) and the generator template (`priv/templates/crosswake/audit/ledger.ex.eex:126`) is `def record_in_multi(multi, name, attrs)` — arity 3. Any adopter following the guide doc to look up or call the function will find a function_clause error or no-match. The docs-contract proof test (`phase96_threadline_docs_contract_test.exs`) does not assert the arity, so this discrepancy is not caught by the suite.

**Fix:** Update `guides/threadline.md` line 128:
```
Use `record_in_multi/3` to insert audit events inside an existing `Ecto.Multi`...
```

---

### WR-03: `guides/threadline.md` describes `row_hash`/`prev_hash` as "Advisory HMAC" but the implementation is plain SHA-256

**File:** `guides/threadline.md:88-89`

**Issue:** The LEDG-02 schema table labels `row_hash` as "Advisory HMAC of this row's content" and `prev_hash` as "Advisory HMAC of the preceding row". HMAC is a keyed message authentication code (RFC 2104). The implementation in `ledger.ex` (line 118) uses `:crypto.hash(:sha256, payload)` — an unkeyed hash. The distinction matters: an HMAC provides authentication (only holders of the key can forge it); a plain SHA-256 hash does not. Readers who understand HMAC semantics will expect a key; operators who rely on this for tamper evidence get weaker assurance than documented. The Honest Limitations section correctly says the ledger is not a "cryptographically sealed ledger", but the column description still says HMAC.

**Fix:** Update the guide table to accurately describe the implementation:

```markdown
| `row_hash` | `:string` | Advisory SHA-256 hash of this row's content (`thread_id|actor_ref|event_class`) |
| `prev_hash` | `:string` | Advisory SHA-256 hash carried from the preceding row (or `"genesis"` for the first row) |
```

---

### WR-04: `collect_shell_messages/1` silently discards `:error` and `:prompt` shell messages

**File:** `examples/phoenix_host/test/crosswake_example/threadline/phase96_example_host_ledger_proof_test.exs:104-111`

**Issue:** `Mix.Shell.Process` routes messages to the test process as `{:mix_shell, :info, [msg]}`, `{:mix_shell, :error, [msg]}`, and `{:mix_shell, :prompt, [msg]}`. `collect_shell_messages/1` only matches `:info` tuples; the `after 0` clause exits the receive loop immediately when a non-info message is at the head of the mailbox. If the `crosswake.threadline` task ever emits an error (e.g., unexpected DB state), the `:error` message is left in the mailbox and the `:info` messages that follow are also not collected. The assertion on line 94 would then fail with a confusing empty-list message rather than showing the error text.

**Fix:** Extend the receive to drain all shell message types:

```elixir
defp collect_shell_messages(acc) do
  receive do
    {:mix_shell, :info, [msg]} -> collect_shell_messages([msg | acc])
    {:mix_shell, :error, [msg]} -> collect_shell_messages(["[error] " <> msg | acc])
    {:mix_shell, :prompt, [msg]} -> collect_shell_messages([msg | acc])
  after
    0 -> Enum.reverse(acc)
  end
end
```

---

## Info

### IN-01: `request_ref` assigned in `mount/3` but never used

**File:** `examples/phoenix_host/lib/crosswake_example/saas_portal/step_up_challenge_live.ex:23`

**Issue:** `request_ref: "req_#{System.unique_integer()}"` is assigned to the socket in the happy-path branch of `mount/3` but is not referenced in `render/1` or `handle_event/3`. This is dead state that bloats the socket diff and may confuse future maintainers.

**Fix:** Remove the `request_ref` assignment unless it is intentionally reserved for a future expansion. If keeping it as a placeholder, add a comment.

---

### IN-02: Hermetic lane guard error message describes wrong module naming convention

**File:** `test/crosswake/proof/phase96_threadline_docs_contract_test.exs:45`

**Issue:** The error message on line 45 reads `"...must not reference the example-host (Crosswake.Example.*)"`. The actual Elixir module prefix is `CrosswakeExample.` (CamelCase, no dots). The `String.contains?` check correctly searches for `"CrosswakeExample."`, but the parenthetical in the failure message would send a developer looking for a `Crosswake.Example.Foo` style module that does not exist in this codebase.

**Fix:**
```elixir
"guides/threadline.md parity test must not reference the example-host " <>
"(CrosswakeExample.*) — the hermetic lane runs without the example Phoenix host"
```

---

### IN-03: `System.unique_integer()` without `:positive` option in `mount/3`

**File:** `examples/phoenix_host/lib/crosswake_example/saas_portal/step_up_challenge_live.ex:23`

**Issue:** `System.unique_integer()` (no options) can return negative integers, producing strings like `"req_-12345"`. The proof test correctly uses `[:positive]` for the same purpose (line 48, 66). If `request_ref` is ever surfaced in logs, external calls, or correlation IDs, a negative-prefixed string may be surprising or fail downstream validation.

**Fix:**
```elixir
request_ref: "req_#{System.unique_integer([:positive])}"
```

---

_Reviewed: 2026-06-10T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
