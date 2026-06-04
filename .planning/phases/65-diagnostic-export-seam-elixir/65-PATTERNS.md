# Phase 65: Diagnostic Export Seam (Elixir) - Pattern Map

**Mapped:** 2026-06-04
**Files analyzed:** 7 (3 new, 2 modified additive, 1 new fixtures dir, 1 new proof test)
**Analogs found:** 7 / 7

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/crosswake/shell/diagnostic_export.ex` | contract module + behaviour | request-response (behaviour-only, no sender) | `lib/crosswake/companions/chimeway/intent_consumer.ex` (callback shape) + `lib/crosswake/companions/chimeway/contracts.ex` (constructor/validation/to_map) | exact (dual analog) |
| `test/fixtures/diagnostic/*.json` | test fixtures | batch (per-layer × per-exit-reason) | `test/fixtures/proof/phase52_operator_inspection.json` | role-match |
| `test/crosswake/proof/phase65_*.exs` | proof test (merge-blocking) | event-driven (hermetic ExUnit) | `test/crosswake/proof/phase64_runtime_line_policy_test.exs` | exact |
| `lib/crosswake/support_matrix/support_matrix.ex` (additive) | config / truth registry | CRUD (read-only accessor) | `lib/crosswake/support_matrix/support_matrix.ex` `@notification_support_truth` block (lines 251–270 + 404–405) | exact (self-analog — mirror existing entry) |
| `lib/crosswake/doctor/doctor.ex` (additive) | service / rule engine | request-response (doctor run pipeline) | `lib/crosswake/doctor/doctor.ex` `phase_62_notification_findings/1` (lines 800–844) | exact |
| `lib/mix/tasks/crosswake.doctor.ex` (formatter parity — if needed) | utility / formatter | transform | `lib/crosswake/doctor/formatter.ex` | role-match |

---

## Pattern Assignments

---

### `lib/crosswake/shell/diagnostic_export.ex` (contract module, request-response behaviour)

**Primary analog — callback shape:** `lib/crosswake/companions/chimeway/intent_consumer.ex`

**Secondary analog — constructor/validation/to_map:** `lib/crosswake/companions/chimeway/contracts.ex`

**Tertiary analog — Shell namespace + to_map nil-rejection:** `lib/crosswake/shell/denial.ex`

---

#### Imports / module header pattern
(from `lib/crosswake/companions/chimeway/intent_consumer.ex` lines 1–15 and `lib/crosswake/bridge/contract.ex` lines 1–22)

```elixir
# intent_consumer.ex — passive behaviour module with no sender
defmodule Crosswake.Companions.Chimeway.IntentConsumer do
  @moduledoc """
  Behaviour for host registry/resolver to implement intent and state checks
  for notification opens.
  """

  alias Crosswake.Companions.Chimeway.Contracts.NotificationOpenEvidence
  alias Crosswake.Companions.Chimeway.Contracts.OpenResolution

  @callback consume_intent(NotificationOpenEvidence.t()) ::
              {:ok, OpenResolution.t()} | {:error, map() | keyword()}
end
```

```elixir
# bridge/contract.ex lines 9–22 — @protocol + @version + @commands pattern
@protocol "crosswake.bridge"
@version "1.0.0"
@commands ~w(
  app.info.get
  haptics.impact
  permissions.status
  notifications.token.get
  share.invoke
  files.pick
  transfer.download
  transfer.export
  transfer.import
  transfer.upload.prepare
)
```

**Copy:** Use `@protocol "crosswake.diagnostic"` + own `@schema_version "1"` at module top. The `@commands` list above is the Bridge.Contract proof anchor — the proof must assert no `"diagnostics.*"` string appears in it.

---

#### @callback export/1 (behaviour-only, no sender)
(from `lib/crosswake/companions/chimeway/intent_consumer.ex` lines 13–14)

```elixir
@callback consume_intent(NotificationOpenEvidence.t()) ::
            {:ok, OpenResolution.t()} | {:error, map() | keyword()}
```

**Copy shape:** `@callback export(Envelope.t()) :: :ok | {:error, term()}`. Document fire-and-forget POST semantics in `@doc` (no response awaited, host-owned endpoint, method = POST, content-type = application/json). Do NOT ship any Elixir HTTP-sending code.

---

#### @enforce_keys defstruct + @type t pattern
(from `lib/crosswake/companions/chimeway/contracts.ex` lines 54–93 — TokenEvidence as template)

```elixir
defmodule TokenEvidence do
  @moduledoc false

  @enforce_keys [
    :provider,
    :platform,
    :environment,
    :installation_ref,
    :token_ref,
    :token_fingerprint,
    :notification_status,
    :observed_at
  ]
  defstruct [
    :provider,
    :platform,
    :environment,
    :installation_ref,
    :token_ref,
    :token_fingerprint,
    :notification_status,
    :observed_at,
    :app_identity_posture,
    :correlation_id,
    metadata: %{}
  ]

  @type t :: %__MODULE__{
          provider: atom(),
          platform: atom(),
          # ...
        }
end
```

**Copy for Envelope:** Replace fields with the 7 locked enforce-keyed fields: `schema_version`, `layer`, `platform`, `native_runtime_version`, `kind`, `correlation_id`, `observed_at`. All 7 are `@enforce_keys`. No optional `metadata: %{}` map (redaction wins — D-13).

**Copy for NativeDiagnostic inner struct:** `source` (`:metrickit | :app_exit_info`) + `exit_reason` (closed enum). Both `@enforce_keys`. No `raw_payload` or open map field.

---

#### Closed-enum module attributes + accessor functions
(from `lib/crosswake/companions/chimeway/contracts.ex` lines 12–52 and lines 303–334)

```elixir
@providers [:apns, :fcm]
@platforms [:ios, :android]
@environments [:sandbox, :production, :development, :unknown]
@forbidden_public_token_keys [
  :token, :raw_token, :device_token, :registration_token, :apns_token, :fcm_token
]

@spec providers() :: [atom()]
def providers, do: @providers

@spec forbidden_public_token_keys() :: [atom()]
def forbidden_public_token_keys, do: @forbidden_public_token_keys
```

**Copy pattern for Phase 65:** Define `@layers`, `@platforms`, `@kinds`, `@sources`, `@exit_reasons` module attributes; expose public accessors `layers/0`, `allowed_keys/0`, `forbidden_keys/0`. The `forbidden_keys/0` and `allowed_keys/0` accessors are the proof test's assertion target for DIAG-03.

---

#### Constructor pipeline: normalize_attrs → build → validate_*
(from `lib/crosswake/companions/chimeway/contracts.ex` lines 336–341, 407–424, 568–622)

```elixir
# Constructor entry point
@spec new_token_evidence(map() | keyword()) :: {:ok, TokenEvidence.t()} | {:error, keyword()}
def new_token_evidence(attrs),
  do:
    attrs
    |> normalize_attrs()
    |> build(TokenEvidence, &validate_token_evidence/1)

# Validator using closed-enum + required-string helpers
def validate_token_evidence(%TokenEvidence{} = evidence) do
  []
  |> validate_closed(:provider, evidence.provider, @providers)
  |> validate_closed(:platform, evidence.platform, @platforms)
  |> validate_closed(:environment, evidence.environment, @environments)
  |> validate_required_string(:installation_ref, evidence.installation_ref)
  |> validate_required_string(:observed_at, evidence.observed_at)
  |> to_result()
end

def validate_token_evidence(_evidence), do: {:error, [token_evidence: :invalid_contract]}

# build/3 pipeline internals
defp build(:invalid_attrs, _module, _validator), do: {:error, [attrs: :invalid]}

defp build(attrs, module, validator) do
  with :ok <- reject_forbidden_token_attrs(attrs),
       {:ok, struct} <- struct_from_attrs(module, attrs),
       :ok <- validator.(struct) do
    {:ok, struct}
  end
end

# Key helpers (copy verbatim)
defp validate_closed(errors, key, value, allowed) do
  if value in allowed, do: errors, else: [{key, {:unsupported, value, allowed}} | errors]
end

defp validate_optional_closed(errors, _key, nil, _allowed), do: errors
defp validate_optional_closed(errors, key, value, allowed),
  do: validate_closed(errors, key, value, allowed)

defp validate_required_string(errors, key, value) when is_binary(value) do
  if byte_size(String.trim(value)) > 0, do: errors, else: [{key, :required} | errors]
end

defp validate_required_string(errors, key, _value), do: [{key, :required} | errors]

defp to_result([]), do: :ok
defp to_result(errors), do: {:error, Enum.reverse(errors)}

defp normalize_key(key) when is_atom(key), do: key
defp normalize_key(key) when is_binary(key) do
  try do
    String.to_existing_atom(key)
  rescue
    ArgumentError -> key
  end
end
```

**Copy:** Use `new_envelope/1` as the entry point calling `normalize_attrs/1 |> build(Envelope, &validate_envelope/1)`. Validator calls `validate_closed/4` for `:layer`, `:platform`, `:kind`; `validate_required_string/3` for `schema_version`, `native_runtime_version`, `correlation_id`, `observed_at`.

---

#### sanitize/1 — fail-closed (STRICTER than Telemetry.metadata/1)
(from `lib/crosswake/companions/chimeway/telemetry.ex` lines 119–135 — the drop-and-continue pattern to INVERT)

```elixir
# Telemetry.metadata/1 — DROP-AND-CONTINUE (do NOT copy this semantics for sanitize/1)
def metadata(attrs) when is_map(attrs) do
  attrs
  |> Enum.reduce(%{}, fn {key, value}, acc ->
    cond do
      key in @forbidden_metadata_keys -> acc          # silently drops
      key in @metadata_keys and safe_value?(value) -> Map.put(acc, key, normalize_value(value))
      true -> acc                                     # silently drops
    end
  end)
end
```

**DO NOT copy the drop-and-continue semantics above for `sanitize/1`.** Instead, `sanitize/1` must FAIL-CLOSED:

```elixir
# Target shape for sanitize/1 (new code — D-14)
@spec sanitize(map()) :: {:ok, Envelope.t()} | {:error, :redaction_failed}
def sanitize(input) when is_map(input) do
  # Validate: reject if any key in input is not in @allowed_envelope_keys
  # Validate: reject if any value fails closed-enum check
  # On any failure: {:error, :redaction_failed}
  # On success: build Envelope struct via new_envelope/1 path
  case new_envelope(input) do
    {:ok, envelope} -> {:ok, envelope}
    {:error, _} -> {:error, :redaction_failed}
  end
end

def sanitize(_input), do: {:error, :redaction_failed}
```

The key semantic: if an unknown key is present or any enum value is out-of-range, return `{:error, :redaction_failed}` — never drop-and-continue.

---

#### safe_value? guard (copy verbatim from Telemetry)
(from `lib/crosswake/companions/chimeway/telemetry.ex` lines 163–167)

```elixir
defp safe_value?(nil), do: false
defp safe_value?(value) when is_atom(value), do: true
defp safe_value?(value) when is_integer(value) and value >= 0, do: true
defp safe_value?(value) when is_binary(value), do: String.length(value) <= 128
defp safe_value?(_value), do: false
```

**Copy verbatim** — this is the Chimeway-canonical value guard. Used if any bounded metadata sub-map is introduced on `NativeDiagnostic` (locked: none by default; use `safe_value?` if added).

---

#### @forbidden_metadata_keys (the canonical set for the proof test)
(from `lib/crosswake/companions/chimeway/telemetry.ex` lines 40–60)

```elixir
@forbidden_metadata_keys [
  :token,
  :raw_token,
  :device_token,
  :registration_token,
  :apns_token,
  :fcm_token,
  :provider_payload,
  :raw_payload,
  :notification_title,
  :notification_body,
  :route_params,
  :actor_id,
  :subject_ref,
  :session_ref,
  :device_id,
  :ip,
  :user_agent,
  :email,
  :provider_response_body
]
```

**Copy:** Expose `forbidden_keys/0` returning this exact 19-key list. The proof test calls `assert key in DiagnosticExport.forbidden_keys(); refute key in DiagnosticExport.allowed_keys()` for every key in this set.

---

#### manual to_map/1 — stringify atoms, reject nils (NO @derive Jason.Encoder)
(from `lib/crosswake/companions/chimeway/contracts.ex` lines 550–566 and `lib/crosswake/shell/denial.ex` lines 71–84)

```elixir
# contracts.ex lines 550-566
@spec to_map(struct()) :: map()
def to_map(%module{} = struct)
    when module in [TokenEvidence, TokenBinding, ...] do
  struct
  |> Map.from_struct()
  |> Enum.reject(fn {_key, value} -> is_nil(value) end)
  |> Enum.map(fn {key, value} -> {Atom.to_string(key), stringify(value)} end)
  |> Map.new()
end

defp stringify(value) when is_atom(value), do: Atom.to_string(value)
defp stringify(value) when is_list(value), do: Enum.map(value, &stringify/1)
defp stringify(value) when is_map(value),
  do: Map.new(value, fn {key, value} -> {to_string(key), stringify(value)} end)
defp stringify(value), do: value
```

```elixir
# denial.ex lines 71-84 — nil + empty-map rejection pattern
def to_map(%__MODULE__{} = denial) do
  %{
    "reason" => Atom.to_string(denial.reason),
    "code" => denial.code,
    # ...
  }
  |> Enum.reject(fn {_key, value} -> is_nil(value) or value == %{} end)
  |> Map.new()
end
```

**Copy for `Envelope.to_map/1`:** Reject nils (and empty maps for optional fields). Stringify all atom values (`:native` → `"native"`, `:ios` → `"ios"`, etc.). `schema_version` is already a string; pass through as-is. The output is what `assert_normalized_json_fixture` validates against saved fixtures.

---

### `test/fixtures/diagnostic/*.json` (test fixtures, batch)

**Analog:** `test/fixtures/proof/phase52_operator_inspection.json` (role-match — JSON fixture normalized by `assert_normalized_json_fixture`)

**Convention:** New sub-directory `test/fixtures/diagnostic/` sibling to the existing `test/fixtures/proof/` sub-directory (the only existing sub-dir at this level). Fixture files are JSON-encoded `Envelope.to_map/1` output, one per meaningful layer × exit-reason axis.

**Fixture file list (D-10):**
```
test/fixtures/diagnostic/native_ios_crash.json
test/fixtures/diagnostic/native_ios_metrickit_hang.json
test/fixtures/diagnostic/native_android_anr.json
test/fixtures/diagnostic/native_android_low_memory.json
test/fixtures/diagnostic/web_liveview_fault.json
test/fixtures/diagnostic/bridge_command_fault.json
```

**Generation rule:** Fixtures must be generated from running code (`Envelope.new_envelope!/1 |> DiagnosticExport.to_map/1 |> Jason.encode!/1`), then saved and locked — never written manually from memory (D-10 pitfall 5). The proof test then calls `assert_normalized_json_fixture` against each saved file.

**Expected JSON shape (illustrative for `native_ios_crash.json`):**
```json
{
  "schema_version": "1",
  "layer": "native",
  "platform": "ios",
  "native_runtime_version": "1.0.0",
  "kind": "crash",
  "correlation_id": "test-corr-001",
  "observed_at": "2026-06-04T00:00:00Z"
}
```

Note: all atom values stringified by `to_map/1` (`"native"` not `:native`).

---

### `test/crosswake/proof/phase65_*.exs` (proof test, hermetic ExUnit)

**Analog:** `test/crosswake/proof/phase64_runtime_line_policy_test.exs` (exact)

---

#### Module header + async: false
(from `test/crosswake/proof/phase64_runtime_line_policy_test.exs` lines 1–11)

```elixir
defmodule Crosswake.Proof.Phase64RuntimeLinePolicyTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias Crosswake.TestSupport.ProofAssertions
  alias Crosswake.RuntimeLine.RebuildPolicy
  alias Crosswake.SupportMatrix
  alias Crosswake.Manifest.Types
end
```

**Copy:** `defmodule Crosswake.Proof.Phase65DiagnosticExportSeamTest` with `use ExUnit.Case, async: false`. No `@moduletag`. Alias `ProofAssertions`, `DiagnosticExport`, `SupportMatrix`, `Bridge.Contract`, `Doctor`.

---

#### @tag per requirement group
(from `test/crosswake/proof/phase64_runtime_line_policy_test.exs` lines 21–22, 61)

```elixir
@tag :rline_01
test "rebuild_required?/1 returns false for :none ..." do
```

**Copy:** Use `@tag :diag_01`, `@tag :diag_02`, `@tag :diag_03`, `@tag :diag_04` per requirement group so `mix test --include :diag_01` works.

---

#### stable_id_message usage in assertion failures
(from `test/crosswake/proof/phase64_runtime_line_policy_test.exs` lines 24–32 and `test/support/proof_assertions.ex` lines 8–13)

```elixir
# stable_id_message/7 signature:
def stable_id_message(id, subject, source, observed, path, hint, posture)

# Usage in proof:
message = ProofAssertions.stable_id_message(
  "proof.rline_01.rebuild_required.none",
  "rebuild_required?(:none) must be false",
  "RebuildPolicy.rebuild_required?/1",
  ":none",
  "lib/crosswake/runtime_line/rebuild_policy.ex",
  "ensure :none is always OTA-safe",
  :merge_blocking
)
refute RebuildPolicy.rebuild_required?(:none), message
```

**Copy:** Every proof assertion in phase65 must include a `stable_id_message` call. IDs follow `"proof.diag_NN.description"` format. `posture:` is `:merge_blocking` for all assertions in this lane.

---

#### assert_normalized_json_fixture usage (fixture round-trip)
(from `test/support/proof_assertions.ex` lines 15–37)

```elixir
def assert_normalized_json_fixture(id, json_payload, fixture_path, opts \\ []) do
  normalized_actual =
    json_payload
    |> Jason.decode!()
    |> normalize()

  normalized_expected =
    fixture_path
    |> File.read!()
    |> Jason.decode!()
    |> normalize()

  assert normalized_actual == normalized_expected,
         stable_id_message(id, ..., source: opts[:source], hint: opts[:hint], posture: opts[:posture])
end
```

**Copy for Phase 65:** Call once per fixture file:
```elixir
# In the proof test, for each fixture axis:
envelope = DiagnosticExport.new_envelope!(native_ios_crash_attrs())
json = DiagnosticExport.to_map(envelope) |> Jason.encode!()
ProofAssertions.assert_normalized_json_fixture(
  "proof.diag_02.fixture.native_ios_crash",
  json,
  "test/fixtures/diagnostic/native_ios_crash.json",
  source: "Crosswake.Shell.DiagnosticExport.to_map/1",
  hint: "regenerate fixture from to_map/1 output if fields change",
  posture: :merge_blocking
)
```

---

#### Allowlist proof idiom (forbidden ∉ allowed, mirrors Phase 58)
(from `test/crosswake/proof/phase58_auth_diagnostics_closeout_test.exs` lines 59–63)

```elixir
assert :access_token in Telemetry.forbidden_metadata_keys()
refute :access_token in Telemetry.metadata_keys()
assert :provider_payload in Telemetry.forbidden_metadata_keys()
refute :session_ref in Telemetry.metadata_keys()
```

**Copy for Phase 65:**
```elixir
for forbidden_key <- [
  :token, :raw_token, :device_token, :registration_token, :apns_token, :fcm_token,
  :provider_payload, :raw_payload, :notification_title, :notification_body,
  :route_params, :actor_id, :subject_ref, :session_ref, :device_id,
  :ip, :user_agent, :email, :provider_response_body
] do
  assert forbidden_key in DiagnosticExport.forbidden_keys(),
         "#{forbidden_key} must be in forbidden_keys()"
  refute forbidden_key in DiagnosticExport.allowed_keys(),
         "#{forbidden_key} must NOT be in allowed_keys()"
end
```

---

#### No Bridge.Contract vocabulary proof assertion
(pattern: `Bridge.Contract.commands/0` returns the 10-element list from `bridge/contract.ex` lines 11–22)

```elixir
# Phase 65 must assert this list gained no diagnostics.* entry:
refute Enum.any?(Bridge.Contract.commands(), &String.starts_with?(&1, "diagnostics")),
       ProofAssertions.stable_id_message(
         "proof.diag_01.no_bridge_vocab",
         "diagnostics.* must not appear in Bridge.Contract.commands()",
         "Crosswake.Bridge.Contract.commands/0",
         "diagnostics.* found in commands list",
         "lib/crosswake/bridge/contract.ex",
         "diagnostic export uses fire-and-forget HTTP, never a bridge command",
         :merge_blocking
       )
```

---

#### Hermetic lane guard
(from `test/crosswake/proof/phase64_runtime_line_policy_test.exs` lines 742–753)

```elixir
test "hermetic lane guard: no @moduletag :requires_example_host and no example-host references" do
  source = File.read!(__ENV__.file)

  refute Regex.match?(~r/^\s*@moduletag\s+:/m, source),
         "phase64 proof lane must not carry any @moduletag — it is hermetic"

  refute String.contains?(source, "Crosswake" <> "Example."),
         "phase64 proof lane must not reference example-host modules"

  refute String.contains?(source, "MIX_" <> "INCLUDE_"),
         "phase64 proof lane must not reference " <> "MIX_" <> "INCLUDE_* env flags"
end
```

**Copy verbatim** — rename to `"phase65 proof lane"` in messages. This must be the final test in the file.

---

### `lib/crosswake/support_matrix/support_matrix.ex` — additive: `@diagnostic_export_support_truth` + accessor

**Analog:** Same file, `@notification_support_truth` block (lines 251–270) + `notification_support_truth/0` accessor (lines 404–405).

---

#### @notification_support_truth shape to mirror exactly
(from `lib/crosswake/support_matrix/support_matrix.ex` lines 251–270 and 404–405)

```elixir
@notification_support_truth [
  %{
    surface: "notification_token provider snapshot",
    proof_class: :advisory,
    action_class: "companion_native",
    docs_anchor: "guides/capabilities.md#bounded-bridge",
    delivery_supported: false,
    telemetry: %{
      status: :shipped,
      event_names: Crosswake.Companions.Chimeway.Telemetry.event_names(),
      metadata_keys: Crosswake.Companions.Chimeway.Telemetry.metadata_keys(),
      forbidden_metadata_keys: Crosswake.Companions.Chimeway.Telemetry.forbidden_metadata_keys(),
      authority_source: :diagnostic_evidence_only,
      proof_class: :merge_blocking
    },
    deferred: [:chimeway_delivery, :push_delivery_guarantees],
    posture:
      "notification_token and notification_open readiness are fully supported/resolvable; ..."
  }
]

@spec notification_support_truth() :: [map()]
def notification_support_truth, do: @notification_support_truth
```

**Copy for Phase 65:** Replace with `@diagnostic_export_support_truth`. Key differences (D-16/D-17):
- `surface:` — describes the diagnostic export contract surface
- `proof_class: :merge_blocking` (allowlist proof is merge-blocking, not just advisory)
- `delivery_supported: false`
- `telemetry.authority_source: :host_configured_endpoint` (not `:diagnostic_evidence_only`)
- `deferred: [:native_diagnostic_export, :metrickit_capture, :application_exit_info_capture]`
- `posture:` — "Diagnostics-export envelope and sanitize contract are shipped and merge-blocking allowlist proof is enforced; native MetricKit/ApplicationExitInfo transport is not shipped until Phase 67; the host owns the endpoint and the data — Crosswake is not a crash-reporting service."

Placement: add the `@diagnostic_export_support_truth` attribute immediately after the `@notification_support_truth` block. Add the `diagnostic_export_support_truth/0` accessor immediately after `notification_support_truth/0` (line 405).

---

### `lib/crosswake/doctor/doctor.ex` — additive: `phase_65_diagnostic_export_findings/0`

**Analog:** Same file, `phase_62_notification_findings/1` function (lines 800–844) and the run pipeline accumulation (lines 149–168).

---

#### phase_62_notification_findings/1 structural model
(from `lib/crosswake/doctor/doctor.ex` lines 800–844)

```elixir
defp phase_62_notification_findings(nil), do: []

defp phase_62_notification_findings(manifest) do
  routes = manifest.routes |> Map.values()
  has_notifications? = Enum.any?(routes, fn route -> ... end)

  if has_notifications? do
    truth = SupportMatrix.notification_support_truth() |> List.first(%{})
    telemetry = Map.get(truth, :telemetry, %{})

    [
      check(
        :advisory,
        "notification.telemetry_contract",
        "notification_posture",
        "Crosswake notifications expose strict telemetry...",
        "Check chimeway telemetry events...",
        %{
          event_names: Map.get(telemetry, :event_names, []),
          forbidden_metadata_keys: Map.get(telemetry, :forbidden_metadata_keys, []),
          authority_source: Map.get(telemetry, :authority_source),
          proof_class: Map.get(telemetry, :proof_class)
        }
      ),
      check(
        :advisory,
        "notification.delivery_deferred",
        "notification_posture",
        Map.get(truth, :posture, ""),
        "Use the local notification_token capability...",
        %{
          delivery_supported: Map.get(truth, :delivery_supported, false),
          deferred: Map.get(truth, :deferred, [])
        }
      )
    ]
  else
    []
  end
end
```

**Copy for Phase 65 — key differences:**
- Function signature: `defp phase_65_diagnostic_export_findings()` — **no manifest argument, no conditional** (fires unconditionally per D-18).
- Single check (not two): severity `:advisory`, code `"diagnostic_export.contract_shipped"`.
- Details include `delivery_supported: false`, `deferred:` list (3 atoms), `authority_source: :host_configured_endpoint`.
- Message and hint draw from the support truth `posture:` string (non-overclaiming — no "crash-reporting service" in message).

---

#### check/6 helper (private — always use this, never %Check{} directly)
(from `lib/crosswake/doctor/doctor.ex` lines 1702–1711)

```elixir
defp check(severity, code, check_name, message, hint, details \\ %{}) do
  %Check{
    severity: severity,
    code: code,
    check: check_name,
    message: message,
    hint: hint,
    details: details
  }
end
```

**Copy:** Call as `check(:advisory, "diagnostic_export.contract_shipped", "diagnostic_export_posture", message, hint, details)`.

---

#### Pipeline accumulation in run/1
(from `lib/crosswake/doctor/doctor.ex` lines 149–168)

```elixir
phase_62_findings = phase_62_notification_findings(manifest)

findings =
  findings ++
    # ... earlier findings ++
    phase_62_findings ++
    publish_findings
```

**Copy:** Add `phase_65_findings = phase_65_diagnostic_export_findings()` after the `phase_62_findings` line. Append `phase_65_findings` to the accumulation. Because it takes no manifest argument and fires unconditionally, it does not need a `nil`-guard clause.

---

## Shared Patterns

### Construction-time allowlist enforcement (never @derive Jason.Encoder)
**Source:** `lib/crosswake/companions/chimeway/contracts.ex` lines 550–566 + `lib/crosswake/companions/chimeway/redaction.ex` lines 174–180
**Apply to:** `DiagnosticExport` module — all constructors and `to_map/1`

The typed struct shape IS the allowlist. Forbidden fields (`:raw_payload`, `:token`, etc.) cannot be expressed in any `Envelope` or `NativeDiagnostic` field. `to_map/1` uses manual atom-to-string stringify; never `@derive Jason.Encoder`.

```elixir
# redaction.ex lines 174-180 — safe_metadata (construction-time drop)
defp safe_metadata(metadata) when is_map(metadata) do
  metadata
  |> Enum.reject(fn {key, _value} -> normalize_key(key) in @forbidden_public_token_keys end)
  |> Enum.into(%{})
end
defp safe_metadata(_metadata), do: %{}
```

### fail-closed error return (distinguish from telemetry drop-and-continue)
**Source:** D-14 (design decision); contrast with `lib/crosswake/companions/chimeway/telemetry.ex` lines 119–135
**Apply to:** `DiagnosticExport.sanitize/1` only

`sanitize/1` returns `{:error, :redaction_failed}` on any invalid/unexpected input. Silent partial data loss (drop-and-continue) is acceptable for telemetry; it is NOT acceptable for diagnostic export where a rejected payload is better than a silently truncated one.

### ProofAssertions.stable_id_message/7 for all proof assertions
**Source:** `test/support/proof_assertions.ex` lines 8–13
**Apply to:** All test assertions in `test/crosswake/proof/phase65_*.exs`

Every `assert`/`refute` in the proof lane must carry a `stable_id_message` call as the failure message, with `posture: :merge_blocking`.

### @spec + accessor pattern for module-attribute truth lists
**Source:** `lib/crosswake/support_matrix/support_matrix.ex` lines 401–405
**Apply to:** Both the new `diagnostic_export_support_truth/0` accessor and the `forbidden_keys/0` + `allowed_keys/0` accessors in `DiagnosticExport`

```elixir
@spec notification_support_truth() :: [map()]
def notification_support_truth, do: @notification_support_truth
```

Every public accessor for a module attribute truth list follows this exact `@spec` + single-expression pattern.

---

## No Analog Found

All files in this phase have strong analogs. No "no analog" entries.

---

## Metadata

**Analog search scope:** `lib/crosswake/companions/chimeway/`, `lib/crosswake/shell/`, `lib/crosswake/bridge/`, `lib/crosswake/support_matrix/`, `lib/crosswake/doctor/`, `test/crosswake/proof/`, `test/support/`, `test/fixtures/`
**Files scanned:** 13 analog files read directly
**Pattern extraction date:** 2026-06-04
