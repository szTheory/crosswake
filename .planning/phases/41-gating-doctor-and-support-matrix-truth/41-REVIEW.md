---
phase: 41-gating-doctor-and-support-matrix-truth
reviewed: 2026-05-30T00:00:00Z
depth: standard
files_reviewed: 4
files_reviewed_list:
  - lib/crosswake/companion/state.ex
  - lib/crosswake/doctor/doctor.ex
  - lib/crosswake/support_matrix/support_matrix.ex
  - test/crosswake/proof/phase41_gating_doctor_test.exs
findings:
  critical: 1
  warning: 2
  info: 1
  total: 4
status: issues_found
---

# Phase 41: Code Review Report

**Reviewed:** 2026-05-30T00:00:00Z
**Depth:** standard
**Files Reviewed:** 4
**Status:** issues_found

## Summary

Reviewed the Phase 41 gating doctor implementation across four files: the `Companion.State` struct, `Doctor` (phase_41 gating findings + phase_38 companion seam findings), `SupportMatrix` (gating_truth/0 and gate_state_display/1), and the hermetic proof test.

The core logic is sound: the three gating finding types (advisory per route, error for unknown companion, warning for missing fallback target) are correctly derived, the kill-switch-first precedence in `gate_state_display/1` is correct, and the test hermeticity pattern is solid. One critical production crash was found in the JSON formatter path: the `on_unavailable` tuple stored in advisory finding details is not JSON-serializable and will cause `Protocol.UndefinedError` at runtime when `mix crosswake.doctor --json` is used against any manifest with a `{:fallback_phoenix, route_id}` route. Two warnings cover a missing catch-all in `gate_state_display/1` and a test that could pass trivially under unexpected manifest compile failure. One info item covers a dual `Application.get_env` read across phase 38 and phase 41.

## Critical Issues

### CR-01: `{:fallback_phoenix, atom()}` tuple in advisory finding details crashes JSON formatter

**File:** `lib/crosswake/doctor/doctor.ex:629`

**Issue:** `gating_advisory_finding/1` stores `route.on_unavailable` verbatim in the details map:

```elixir
%{route_id: route.id, gated_by: route.gated_by, on_unavailable: route.on_unavailable}
```

When `on_unavailable` is `{:fallback_phoenix, :some_route}`, the details map contains an Elixir tuple as a value. `JSONFormatter.render/1` passes `check.details` directly to `Jason.encode!/2` (via `check_to_map/1` at `lib/crosswake/doctor/json_formatter.ex:168`), and Jason has no encoder for Elixir tuples. This raises `Protocol.UndefinedError` at runtime whenever `mix crosswake.doctor --json` (or any caller of `JSONFormatter.render/1`) processes a report that includes a gating advisory finding for a route with `on_unavailable: {:fallback_phoenix, _}`.

The text formatter (`formatter.ex:344`) also reaches a catch-all `format_value(value), do: to_string(value)` for tuples, and `to_string/1` on a tuple raises `Protocol.UndefinedError` via `String.Chars`.

The proof tests do not exercise either formatter, so all SC#1 tests pass while the production code path remains broken.

**Fix:** Serialize `on_unavailable` to a JSON-safe representation before storing it in details. The manifest types module already has `serialize_on_unavailable/1` (`lib/crosswake/manifest/types.ex:977`) for exactly this purpose. Use it here:

```elixir
# In gating_advisory_finding/1, replace the raw on_unavailable field:
on_unavailable_serialized =
  case route.on_unavailable do
    {:fallback_phoenix, id} -> "fallback_phoenix:#{id}"
    :deny -> "deny"
    nil -> nil
  end

check(
  :advisory,
  "gating.route_gated",
  "gating.#{route.id}",
  "Route \"#{route.id}\" is gated by :#{route.gated_by}; on_unavailable: #{posture_label}",
  hint,
  %{route_id: route.id, gated_by: route.gated_by, on_unavailable: on_unavailable_serialized}
)
```

Alternatively, add a `Jason.Encoder` protocol implementation for the `{:fallback_phoenix, atom()}` tuple shape, but that is not idiomatic. The string serialization approach matches what the manifest builder already does.

## Warnings

### WR-01: `gate_state_display/1` has no catch-all clause — FunctionClauseError on unexpected state

**File:** `lib/crosswake/support_matrix/support_matrix.ex:611-615`

**Issue:** `gate_state_display/1` covers the five typed patterns for `gate_status` and `kill_switch_status` that are valid per the `Companion.State` type spec. However, there is no catch-all clause. If a companion's `report_state/0` returns a `State` struct with a `gate_status` or `kill_switch_status` value outside the typed set (e.g., a newly added status variant introduced in a companion before the core package is updated, or a hand-built test fixture with an invalid value), `SupportMatrix.gating_truth/0` will raise `FunctionClauseError` and crash the caller with no useful diagnostic context.

The `gating_truth/0` function has no `try/rescue`, so the crash propagates to whichever tool calls it (doctor, JSON formatter, release notes generator, etc.).

**Fix:** Add a catch-all clause that returns the raw value stringified, preventing the crash while surfacing the unexpected state:

```elixir
defp gate_state_display(%Crosswake.Companion.State{} = state) do
  "unknown(gate_status=#{inspect(state.gate_status)},kill_switch=#{inspect(state.kill_switch_status)})"
end
```

This ensures `gating_truth/0` always returns a displayable string (or nil for the typed nil-returning cases) and never crashes the host tool due to an out-of-band companion implementation.

### WR-02: SC#1f (`no gating findings for non-gated routes`) passes trivially if manifest compilation fails

**File:** `test/crosswake/proof/phase41_gating_doctor_test.exs:451-470`

**Issue:** SC#1f uses `MinimalRouter` (with `offline: :cached_read_only` and no `gated_by` declarations) and asserts that no `gating.*` findings appear. The assertion is:

```elixir
assert gating_findings == []
```

If `Manifest.compile/2` fails for `MinimalRouter` (returning `{nil, ...}`), `phase_41_gating_findings(nil)` returns `[]` immediately — so the test passes vacuously even though no gating logic was exercised. A future breakage in `MinimalRouter` compilation would keep SC#1f green while the actual gating filter logic is untested.

The test also does not assert `report.status == :ok`, so a manifest compilation error producing `:error` status is invisible.

**Fix:** Add a guard assertion on `report.status` or `report.manifest` before the gating filter check, so the test fails loudly if the scenario degrades:

```elixir
assert report.manifest != nil,
       "MinimalRouter must compile to a non-nil manifest for SC#1f to be meaningful; got manifest=nil in report"

gating_findings = Enum.filter(report.findings, &String.starts_with?(&1.code, "gating."))

assert gating_findings == [],
       "expected no gating findings for non-gated routes; got: #{inspect(gating_findings)}"
```

## Info

### IN-01: `Application.get_env(:crosswake, :companions)` read twice per `Doctor.run/1` call

**File:** `lib/crosswake/doctor/doctor.ex:517` and `lib/crosswake/doctor/doctor.ex:585`

**Issue:** `phase_38_companion_seam_findings/0` and `phase_41_gating_findings/1` each call `Application.get_env(:crosswake, :companions, [])` independently within a single `Doctor.run/1` invocation. In production this is harmless (application env is stable across a single doctor run), but it means the two phases could theoretically observe a different companion list if the env is modified between calls (not expected in practice). It also means companion list construction happens twice.

**Fix:** Fetch the companion list once at the top of `run/1` and thread it into both phase functions as a parameter:

```elixir
def run(opts \\ []) do
  companions = Application.get_env(:crosswake, :companions, [])
  # ...
  phase_38_findings = phase_38_companion_seam_findings(companions)
  phase_41_findings = phase_41_gating_findings(manifest, companions)
  # ...
end
```

This is a low-priority cleanup; it does not affect current correctness.

---

_Reviewed: 2026-05-30T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
