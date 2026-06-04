---
phase: 65-diagnostic-export-seam-elixir
reviewed: 2026-06-04T00:00:00Z
depth: standard
files_reviewed: 5
files_reviewed_list:
  - lib/crosswake/shell/diagnostic_export.ex
  - lib/crosswake/support_matrix/support_matrix.ex
  - lib/crosswake/doctor/doctor.ex
  - test/crosswake/proof/phase65_diagnostic_export_seam_test.exs
  - test/crosswake/shell/diagnostic_export_test.exs
findings:
  critical: 1
  warning: 2
  info: 1
  total: 4
findings_resolved: 4
status: resolved
resolution_commit: pending
---

# Phase 65: Code Review Report

**Reviewed:** 2026-06-04
**Depth:** standard
**Files Reviewed:** 5
**Status:** resolved (all 4 findings fixed in-phase; 868 tests, 0 failures)

## Resolution (2026-06-04)

All four findings were fixed before phase completion:

- **CR-01 (Critical)** — `build_envelope/1` now coerces a raw-map `native_diagnostic`
  through the typed, fail-closed `new_native_diagnostic/1` constructor, so nested
  forbidden/unexpected/out-of-enum values are rejected for every construction path
  (including `sanitize/1`) instead of being stored verbatim and serialized by `to_map/1`.
- **WR-01 (Warning)** — support-truth `action_class` corrected `"shell_native"` → `"native_shell"`
  to match the canonical vocabulary.
- **WR-02 (Warning)** — proof lane gained 4 `:diag_03` assertions: unexpected top-level key,
  nested forbidden key (CR-01 regression guard), nested unexpected key, and a valid-nested
  positive control.
- **IN-01 (Info)** — `@allowed_keys` / `allowed_keys/0` docs clarified to state that `sanitize/1`
  validates outer keys against `@envelope_fields` and the nested map against `@native_diagnostic_fields`.

## Summary

Phase 65 adds `Crosswake.Shell.DiagnosticExport` (behaviour-only seam, typed envelopes, fail-closed `sanitize/1`), a `@diagnostic_export_support_truth` entry in `SupportMatrix`, and an unconditional `:advisory` doctor finding. The overall structure correctly mirrors the Chimeway/IntentConsumer precedent, uses `@enforce_keys` structs, manual `to_map/1`, and no HTTP client dependency. Contract integrity and non-overclaiming posture are sound.

Three issues undermine the redaction guarantee: one critical (forbidden sub-map keys bypass `sanitize/1`), one warning (`action_class: "shell_native"` is an invented value not in the canonical vocabulary), and one warning (the merge-blocking proof lane lacks the test asserting `sanitize/1` rejects unexpected non-forbidden keys). One info item (the `@allowed_keys` includes `@native_diagnostic_fields` in its definition but `sanitize/1` only checks `@envelope_fields`, creating a silent asymmetry).

---

## Critical Issues

### CR-01: `sanitize/1` does not sanitize the `native_diagnostic` sub-map value — forbidden keys can bypass redaction through it

**File:** `lib/crosswake/shell/diagnostic_export.ex:305-324`

**Issue:** `sanitize/1` checks only the top-level keys of the input map against `@envelope_fields` and `@forbidden_keys`. If a caller passes `native_diagnostic` as a plain map (rather than a pre-validated `%NativeDiagnostic{}` struct), any keys inside that sub-map — including `:token`, `:device_id`, `:email`, or any other forbidden key — are never inspected.

Trace: `sanitize(%{..., native_diagnostic: %{source: :metrickit, exit_reason: :crash, token: "secret"}})`:
1. Top-level normalized keys: `[:schema_version, :layer, ..., :native_diagnostic]` — all pass the `@envelope_fields` check.
2. `new_envelope(input)` calls `struct!(Envelope, attrs)`, which stores `native_diagnostic: %{source: :metrickit, exit_reason: :crash, token: "secret"}` verbatim on the struct.
3. `validate_envelope/1` validates only the 7 named top-level fields; the `native_diagnostic` value is not inspected.
4. Result: `{:ok, %Envelope{..., native_diagnostic: %{..., token: "secret"}}}` — redaction bypassed.

The spec (D-14) says `sanitize/1` must be fail-closed on "any key in `forbidden_keys/0`", which implies this check must be recursive. D-09 says `NativeDiagnostic` has exactly `source` and `exit_reason` — so an unexpected key inside `native_diagnostic` should also be rejected.

Neither the proof lane nor the unit tests cover this path.

**Fix:**

Add recursive sanitization of the `native_diagnostic` value inside `sanitize/1`. The simplest correct fix is to check, when `native_diagnostic` is present and is a map, that it contains no forbidden keys and only the known sub-struct keys:

```elixir
def sanitize(input) when is_map(input) do
  normalized_keys =
    input
    |> Map.keys()
    |> Enum.map(&normalize_key/1)

  cond do
    Enum.any?(normalized_keys, &(&1 in @forbidden_keys)) ->
      {:error, :redaction_failed}

    Enum.any?(normalized_keys, &(&1 not in @envelope_fields)) ->
      {:error, :redaction_failed}

    :else ->
      case sanitize_native_diagnostic_value(Map.get(input, :native_diagnostic)) do
        :ok ->
          case new_envelope(input) do
            {:ok, envelope} -> {:ok, envelope}
            {:error, _} -> {:error, :redaction_failed}
          end

        :error ->
          {:error, :redaction_failed}
      end
  end
end

# Returns :ok when nd_value is nil, a valid %NativeDiagnostic{} struct,
# or a map with only the two allowed keys and no forbidden keys.
defp sanitize_native_diagnostic_value(nil), do: :ok
defp sanitize_native_diagnostic_value(%NativeDiagnostic{}), do: :ok

defp sanitize_native_diagnostic_value(nd_map) when is_map(nd_map) do
  nd_keys = nd_map |> Map.keys() |> Enum.map(&normalize_key/1)

  if Enum.any?(nd_keys, &(&1 in @forbidden_keys)) or
       Enum.any?(nd_keys, &(&1 not in @native_diagnostic_fields)) do
    :error
  else
    :ok
  end
end

defp sanitize_native_diagnostic_value(_), do: :error
```

Also add a proof-lane test in `phase65_diagnostic_export_seam_test.exs` under DIAG-03:

```elixir
@tag :diag_03
test "sanitize/1 returns {:error, :redaction_failed} when a forbidden key is nested in native_diagnostic" do
  attrs = %{
    schema_version: "1",
    layer: :native,
    platform: :ios,
    kind: :crash,
    native_runtime_version: "1.0.0",
    correlation_id: "phase65-sanitize-nested",
    observed_at: "2026-06-04T00:00:00Z",
    native_diagnostic: %{source: :metrickit, exit_reason: :crash, token: "injected"}
  }
  assert DiagnosticExport.sanitize(attrs) == {:error, :redaction_failed}
end
```

---

## Warnings

### WR-01: `action_class: "shell_native"` is not in the canonical action-class vocabulary

**File:** `lib/crosswake/support_matrix/support_matrix.ex:275`

**Issue:** The `@diagnostic_export_support_truth` entry declares `action_class: "shell_native"`. The canonical action-class vocabulary in `action_class_entries/0` (and the `allowed` list in `validate_action_class_rows/1`, line 801) contains exactly `"docs_only"`, `"route_manifest"`, `"compatibility"`, `"native_shell"`, `"companion_native"`, `"provider_adapter"`. The value `"shell_native"` is a naming inversion — it does not exist anywhere else in the codebase. Every other entry that references native shell surfaces uses `"native_shell"`.

The `validate_action_class_rows` validator does not cover support-truth maps (only typed `ActionClassEntry` structs), so this will not surface as a compile-time or test failure. It will cause silent inconsistency in any downstream consumer that cross-references `action_class` values between support truth and the action class registry.

**Fix:**

```elixir
# support_matrix.ex line 275 — change "shell_native" to "native_shell"
action_class: "native_shell",
```

### WR-02: Proof lane lacks a test asserting `sanitize/1` rejects unexpected (non-forbidden, non-allowed) keys

**File:** `test/crosswake/proof/phase65_diagnostic_export_seam_test.exs`

**Issue:** The DIAG-03 proof section tests: (a) all 19 canonical forbidden keys are rejected, (b) out-of-enum layer value is rejected, (c) non-map input is rejected, and (d) valid attrs round-trip succeeds. It does NOT assert that an unexpected key outside both `@forbidden_keys` and `@envelope_fields` (e.g. `:some_attacker_key`) causes `{:error, :redaction_failed}`.

This gap means a regression that accidentally drops the unexpected-key check from `sanitize/1` (line 315) would not be caught by the merge-blocking proof lane. The unit test (`diagnostic_export_test.exs:206`) covers this for the non-proof test suite, but the merge-blocking proof lane should be self-contained.

D-14 and D-15 require the merge-blocking allowlist proof to cover all three rejection paths (forbidden key, unexpected key, out-of-enum value).

**Fix:**

Add to the DIAG-03 section of `phase65_diagnostic_export_seam_test.exs`:

```elixir
@tag :diag_03
test "sanitize/1 returns {:error, :redaction_failed} for an unexpected key outside allowed_keys" do
  base_attrs = %{
    schema_version: "1",
    layer: :native,
    platform: :ios,
    kind: :crash,
    native_runtime_version: "1.0.0",
    correlation_id: "phase65-sanitize-unexpected",
    observed_at: "2026-06-04T00:00:00Z"
  }

  attrs_with_unexpected = Map.put(base_attrs, :unexpected_attacker_key, "value")
  result = DiagnosticExport.sanitize(attrs_with_unexpected)

  assert result == {:error, :redaction_failed},
         ProofAssertions.stable_id_message(
           "proof.diag_03.sanitize.rejects_unexpected_key",
           "sanitize/1 must return {:error, :redaction_failed} for any unexpected key",
           "Crosswake.Shell.DiagnosticExport.sanitize/1",
           "sanitize/1 returned #{inspect(result)} — should have rejected unexpected key",
           "lib/crosswake/shell/diagnostic_export.ex",
           "fail-closed: unexpected keys outside allowed_keys must be rejected (DIAG-03 D-14)",
           :merge_blocking
         )
end
```

---

## Info

### IN-01: `@allowed_keys` includes `@native_diagnostic_fields` but `sanitize/1` only checks `@envelope_fields` — silent asymmetry

**File:** `lib/crosswake/shell/diagnostic_export.ex:102` and `315`

**Issue:** The module defines `@allowed_keys = @envelope_fields ++ @native_diagnostic_fields` (line 102), and the public `allowed_keys/0` accessor returns this combined set. However, `sanitize/1` at line 315 only validates against `@envelope_fields` (`&(&1 not in @envelope_fields)`), not `@allowed_keys`. This is actually architecturally correct (the check is on the top-level input map, not on sub-struct fields), but creates a documentation mismatch: the `@doc` on `allowed_keys/0` says it is "the explicit allowlist that sanitize/1 validates against", which is inaccurate — `sanitize/1` does NOT check against `@allowed_keys`; it checks against `@envelope_fields`.

This asymmetry can mislead future maintainers into thinking `sanitize/1` validates sub-struct fields via `@allowed_keys`. Combined with CR-01 (which it contributes to), the naming is misleading.

**Fix:**

Either:
1. Update the `@doc` on `allowed_keys/0` to accurately describe that it is the union of envelope fields + native diagnostic fields for documentation/proof purposes, and that `sanitize/1` validates top-level keys against `@envelope_fields`:

```elixir
@doc """
Returns the declared allowed key set (envelope fields + native_diagnostic sub-struct fields).
Shares no key with `forbidden_keys/0`.

Note: `sanitize/1` validates top-level input keys against `@envelope_fields`; this combined
set is exposed for proof assertions and documentation purposes.
"""
```

2. Or (preferred, following CR-01 fix) make `sanitize/1` validate against `@allowed_keys` for top-level keys AND validate sub-map keys recursively, so the documented contract matches the implementation.

---

_Reviewed: 2026-06-04_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
