---
phase: 45-rindle-in-tree-companion-mock-example-and-proof
reviewed: 2026-05-31T16:05:00Z
depth: standard
files_reviewed: 13
files_reviewed_list:
  - lib/crosswake/companions/rindle.ex
  - mix.exs
  - test/crosswake/proof/phase45_rindle_companion_test.exs
  - examples/phoenix_host/lib/crosswake_example/media/mock_capture.ex
  - examples/phoenix_host/lib/crosswake_example/media/reconciliation_keys.ex
  - examples/phoenix_host/lib/crosswake_example/media/reconciliation_inbox.ex
  - examples/phoenix_host/lib/crosswake_example/media/media_projection.ex
  - examples/phoenix_host/lib/crosswake_example/media/media_lane_live.ex
  - examples/phoenix_host/lib/crosswake_example/router.ex
  - test/crosswake/proof/phase45_rindle_mock_media_test.exs
  - test/crosswake/proof/phase45_rindle_live_test.exs
  - test/crosswake/proof/phase45_rindle_advisory_test.exs
  - .github/workflows/phase45-proof.yml
findings:
  critical: 0
  warning: 3
  info: 0
  total: 3
status: issues_found
---
# Phase 45: Code Review Report

**Reviewed:** 2026-05-31T16:05:00Z
**Depth:** standard
**Files Reviewed:** 13
**Status:** issues_found

## Summary

Phase 45 introduces a coherent companion seam and proof posture, but there are three correctness/robustness defects in the mock media lane that can cause false proofs, replay-key ambiguity, and runtime LiveView crashes under error conditions.

## Narrative Findings (AI reviewer)

## Warnings

### WR-01: Hard-coded grant expiry/date values create non-deterministic and eventually-invalid proof behavior

**File:** `examples/phoenix_host/lib/crosswake_example/media/mock_capture.ex:15`
**Issue:** `@default_time` and default `expires_at` are fixed to `2026-05-31...`. This makes the mock lane time-dependent and can silently turn grants stale/invalid after that date, breaking proof determinism and giving misleading failures unrelated to seam behavior.
**Fix:**
```elixir
now = DateTime.utc_now()
captured_at = DateTime.to_iso8601(now)
expires_at = now |> DateTime.add(15 * 60, :second) |> DateTime.to_iso8601()
```
Use runtime-relative timestamps (or a deterministic injected clock in tests).

### WR-02: Replay identity key is delimiter-ambiguous and collision-prone

**File:** `examples/phoenix_host/lib/crosswake_example/media/reconciliation_keys.ex:13`
**Issue:** `event_key/2` concatenates raw components with `"::"` without escaping/encoding. If any component contains `"::"` (notably client-influenced fields like `idempotency_key`/`storage_key`), distinct tuples can collapse to the same key, corrupting replay detection semantics.
**Fix:**
```elixir
payload = %{
  kind: "event",
  lane: "media",
  source: "mock",
  grant_id: evidence.grant_id,
  idempotency_key: evidence.idempotency_key,
  event_kind: canonical(event_kind),
  storage_key: evidence.storage_key
}

event_key = :crypto.hash(:sha256, Jason.encode!(payload)) |> Base.encode16(case: :lower)
```
Or use an escaping scheme that guarantees unambiguous boundaries.

### WR-03: LiveView event handlers crash process on expected error paths

**File:** `examples/phoenix_host/lib/crosswake_example/media/media_lane_live.ex:56`
**Issue:** `mount/3`, `handle_event("start_scan", ...)`, and `handle_event("verify_backend", ...)` use hard pattern matches (`{:ok, ...} = ...`). Any contract validation/reconciliation failure exits the LiveView instead of returning a controlled fail-closed UI state. This weakens robustness and proof realism.
**Fix:**
```elixir
with {:ok, evidence} <- MockCapture.emit_capture_evidence(...),
     {:ok, ingestion} <- ReconciliationInbox.ingest_capture_evidence(...),
     {:ok, media_object} <- MediaProjection.project_object(...) do
  {:noreply, assign(socket, ...)}
else
  {:error, reason} ->
    {:noreply, put_flash(socket, :error, "Media evidence rejected: #{inspect(reason)}")}
end
```
Apply the same guarded flow in `mount/3` and all event handlers.

---

_Reviewed: 2026-05-31T16:05:00Z_  
_Reviewer: the agent (gsd-code-reviewer)_  
_Depth: standard_
