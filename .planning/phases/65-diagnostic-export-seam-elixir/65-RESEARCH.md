# Phase 65: Diagnostic Export Seam (Elixir) — Research

**Researched:** 2026-06-04
**Domain:** Elixir contract module, behaviour-only seam, allowlist-by-construction redaction, SupportMatrix truth, Doctor advisory finding
**Confidence:** HIGH — all findings are based on verified reads of the actual codebase

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**D-01:** `Crosswake.Shell.DiagnosticExport` ships the envelope contract + a transport `@callback` the host/native-shell implements — mirroring `Crosswake.Companions.Chimeway.IntentConsumer` (passive `@callback consume_intent/1`, no sender). Crosswake ships NO Elixir HTTP-sending code.

**D-02:** Behaviour shape: `@callback export(Envelope.t()) :: :ok | {:error, term()}`. "Fire-and-forget" is a documented semantic of the POST contract (method, content-type, host-owned endpoint, no response awaited), not Elixir transport behaviour. The real senders are native (MetricKit / `ApplicationExitInfo`) in Phase 67.

**D-03:** No HTTP client dependency (Req/Finch/Mint/:httpc) is added to the published lib.

**D-04:** Proof assertions (DIAG-01 / success criterion 1): (a) no `diagnostics.*` / `diagnostic_export.*` entry added to `Bridge.Contract` command vocabulary; (b) no HTTP-client dep introduced.

**D-05:** House contract style: `@protocol "crosswake.diagnostic"` (spelling = planner discretion) + own `@schema_version`; nested `defstruct` with `@enforce_keys`; `@type t`; `new_*` constructor with closed-enum validation; **manual `to_map/1`** (no `@derive Jason.Encoder`).

**D-06:** Outer `Envelope` required enforce-keyed fields: `schema_version`, `layer`, `platform`, `native_runtime_version`, `kind`, `correlation_id`, `observed_at`.

**D-07:** `layer :: :native | :web | :bridge`; `platform :: :ios | :android | :web`; `native_runtime_version` from `Compatibility.native_runtime_version`.

**D-08:** `kind` closed enum: `:crash | :termination | :hang | :cpu | :bridge_fault | :web_fault` (exact set = planner discretion; must be closed + exhaustive).

**D-09:** Inner `NativeDiagnostic` struct: `source :: :metrickit | :app_exit_info`; `exit_reason :: :crash | :anr | :low_memory | :user_requested | :hang | :cpu_resource_limit | :abnormal_exit | :other`. **No `raw_payload` map.**

**D-10:** Fixtures under `test/fixtures/diagnostic/` (per layer × exit-reason), proven via `assert_normalized_json_fixture`.

**D-11:** Allowlist-by-construction is the redaction. The typed structs cannot represent forbidden data.

**D-12:** No free-form crash text in the Elixir contract.

**D-13:** `raw_payload` dropped — redaction wins. Any bounded metadata map must pass Chimeway key-allowlist + `safe_value?` guard.

**D-14:** `sanitize/1` spec: `@spec sanitize(map()) :: {:ok, Envelope.t()} | {:error, :redaction_failed}` — fail-closed (reject, not drop-and-continue).

**D-15:** Merge-blocking allowlist test: `assert forbidden_key in forbidden_keys(); refute forbidden_key in allowed_keys()` over the established forbidden set plus fixture round-trip through `sanitize/1`.

**D-16:** Add `@diagnostic_export_support_truth` module attribute + `diagnostic_export_support_truth/0` accessor to `SupportMatrix`, mirroring `@notification_support_truth` exactly. Entry carries: `surface`, `proof_class: :merge_blocking`, `action_class`, `docs_anchor`, `delivery_supported: false`, `telemetry` sub-map, `deferred`, `posture`.

**D-17:** `posture:` string: "Diagnostics-export envelope and sanitize contract are shipped and merge-blocking allowlist proof is enforced; native MetricKit/ApplicationExitInfo transport is not shipped until Phase 67; the host owns the endpoint and the data — Crosswake is not a crash-reporting service."

**D-18:** One doctor check: severity `:advisory`, code `"diagnostic_export.contract_shipped"`, fires unconditionally.

### Claude's Discretion

- Exact module/struct/callback/function names and field spellings
- Exact `layer` / `kind` / `exit_reason` / `source` atom spellings — preserve closed-enum exhaustiveness
- Sub-module split vs single module
- Fixture directory/naming and proof-lane file placement
- Exact `SupportMatrix` entry field population
- Whether `sanitize/1` fail-closed guard lives in constructor vs dedicated function

### Deferred Ideas (OUT OF SCOPE)

- Optional dep-gated Elixir reference sender (Req/Finch + Task fire-and-forget) — Phase 67
- Bounded free-form crash text / structured stack frames
- Per-platform fully-typed inner structs (MetricKitDiagnostic / AppExitInfoDiagnostic)
- Native MetricKit / ApplicationExitInfo capture + real HTTP transport + JVM lane — Phase 67
- Host endpoint generator scaffolds / ADOPT: markers — Phase 66
- Docs-contract parity gate + Android promotion + closeout — Phase 69
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DIAG-01 | The shell can export crash/diagnostic evidence to a host-owned endpoint as fire-and-forget HTTP POST (NOT through the bounded bridge) | Behaviour-only `@callback export/1` on `DiagnosticExport`; proof asserts no `diagnostics.*` added to `Bridge.Contract.commands/0`; no HTTP dep added |
| DIAG-02 | Diagnostic export payloads carry layer attribution (native/web/bridge) and a stable, typed envelope schema | `Envelope` struct with `layer`, `platform`, `native_runtime_version`, `kind`, `correlation_id`, `observed_at`; fixtures per layer × exit-reason proven via `assert_normalized_json_fixture` |
| DIAG-03 | Diagnostic export applies an explicit, tested redaction allowlist forbidding raw tokens, payloads, route params, PII | Allowlist-by-construction (struct schema = allowlist); `sanitize/1` fail-closed; merge-blocking proof `assert forbidden in forbidden_keys(); refute forbidden in allowed_keys()` |
| DIAG-04 | `mix crosswake.doctor` and support truth report diagnostics-export readiness without implying a first-party crash-reporting service | `@diagnostic_export_support_truth` in `SupportMatrix`; `:advisory` doctor finding `"diagnostic_export.contract_shipped"` with non-overclaiming posture string |
</phase_requirements>

---

## Summary

Phase 65 is a pure Elixir contract addition — no native code, no HTTP client, no manifest schema change, no new external dependency. It adds one module (`Crosswake.Shell.DiagnosticExport`) with a behaviour-only transport callback (mirroring the `IntentConsumer` precedent), two typed structs (`Envelope` and `NativeDiagnostic`) following the Chimeway/Bridge house contract style, a fail-closed `sanitize/1` function, a SupportMatrix truth entry, and one unconditional `:advisory` doctor check. All decisions are locked (18 D-decisions) from the CONTEXT.md.

The primary challenge for the planner is not architectural (that is settled) but integrative: getting all four proof assertions (allowlist gate, no-bridge-vocabulary, no-HTTP-dep, support-truth/doctor present + non-overclaiming, fixtures normalize) into one hermetic phase-65 proof lane that mirrors the Phase 58 and Phase 64 conventions exactly.

**Primary recommendation:** Ground every new construct in the exact existing patterns read in this research. The Chimeway `contracts.ex`, `redaction.ex`, `telemetry.ex`, `intent_consumer.ex`, `support_matrix.ex` (@notification_support_truth), and `doctor.ex` (`check/6` helper, `phase_62_notification_findings` as a structural model) are all direct templates.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Envelope contract + behaviour | Elixir library (`lib/crosswake/shell/`) | — | Crosswake owns the typed schema; host/native shell implements the `@callback` |
| Redaction allowlist enforcement | Elixir library (construction-time) | — | Allowlist-by-construction: struct shape IS the allowlist; no runtime scrubbing |
| `sanitize/1` fail-closed guard | Elixir library | — | Maps untyped input → typed `Envelope.t()`; rejects on invalid/unexpected fields |
| HTTP transport (POST to host endpoint) | Native shell (Phase 67) | Host-owned endpoint | Crosswake defines the contract; the native shell (iOS MetricKit / Android ApplicationExitInfo) does the POST |
| Support truth readiness | `Crosswake.SupportMatrix` | — | `@diagnostic_export_support_truth` mirrors `@notification_support_truth` |
| Doctor finding | `Crosswake.Doctor` | Formatter / JSONFormatter | Unconditional `:advisory` finding fires via `check/6` helper |
| Proof lane (merge-blocking) | `test/crosswake/proof/phase65_*` | — | Hermetic; no example-host refs; no `@moduletag` |
| Fixtures (per layer × exit-reason) | `test/fixtures/diagnostic/*.json` | — | Normalised JSON shapes Phase 67 native shells parity-lock against |

---

## Standard Stack

### Core (no new deps — all existing)

| Library | Current Version in mix.exs | Purpose | Why Standard |
|---------|---------------------------|---------|--------------|
| `jason` | `~> 1.4` | JSON serialisation for `to_map/1` output and fixture assertions | Already in deps; house convention for `to_map/1` → Jason |
| `ex_unit` (stdlib) | built-in | Test assertions, proof lane | Already used across all phases |
| `telemetry` | `~> 1.0` | If a `Telemetry` sub-module is added for diagnostic events | Already in deps |

**No new dependencies.** D-03 is absolute: no Req, Finch, Mint, HTTPoison, or `:httpc` may be added to the published lib. The `mix.exs` currently has `{:jason, "~> 1.4"}`, `{:nimble_options, "~> 1.1"}`, `{:phoenix, "~> 1.8"}`, `{:phoenix_live_view, "~> 1.1"}`, `{:telemetry, "~> 1.0"}`, `{:ex_doc, "~> 0.38", only: :dev}` plus optional companion deps. [VERIFIED: codebase read of mix.exs line 38-63]

### Installation

```bash
# No new install — purely additive within existing crosswake lib
```

---

## Package Legitimacy Audit

> No external packages are introduced in this phase. D-03 locks out all HTTP-client deps. The only deps in play are already present in mix.exs.

| Package | Registry | Status | Disposition |
|---------|----------|--------|-------------|
| (none new) | — | — | No packages to audit |

**Packages removed due to slopcheck [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

---

## Architecture Patterns

### System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│  Crosswake Elixir Library (Phase 65 additions, no new dep)       │
│                                                                   │
│  lib/crosswake/shell/diagnostic_export.ex                        │
│  ┌─────────────────────────────────────────────────────────┐     │
│  │  @protocol "crosswake.diagnostic"  @schema_version "1"  │     │
│  │                                                          │     │
│  │  @callback export(Envelope.t()) :: :ok | {:error, term} │◄────┼─ Host/native shell
│  │           (behaviour only — no sender)                   │     │   implements in Phase 67
│  │                                                          │     │
│  │  defmodule Envelope (enforce-keyed typed struct)         │     │
│  │   schema_version, layer, platform,                       │     │
│  │   native_runtime_version, kind, correlation_id,          │◄────┼─ native_runtime_version
│  │   observed_at                                            │     │   from Compatibility
│  │                                                          │     │
│  │  defmodule NativeDiagnostic (inner struct)               │     │
│  │   source (:metrickit | :app_exit_info)                   │     │
│  │   exit_reason (closed enum)                              │     │
│  │   [no raw_payload — redaction wins]                      │     │
│  │                                                          │     │
│  │  sanitize/1 :: {:ok, Envelope.t()} | {:error, :redaction_failed}
│  │  [fail-closed — rejects unknown/invalid input]           │     │
│  └─────────────────────────────────────────────────────────┘     │
│                                                                   │
│  lib/crosswake/support_matrix/support_matrix.ex (additive)       │
│  ┌──────────────────────────────────────────────────────────┐    │
│  │  @diagnostic_export_support_truth [...]                   │    │
│  │  def diagnostic_export_support_truth/0                    │    │
│  └──────────────────────────────────────────────────────────┘    │
│                                                                   │
│  lib/crosswake/doctor/doctor.ex (additive)                       │
│  ┌──────────────────────────────────────────────────────────┐    │
│  │  :advisory finding "diagnostic_export.contract_shipped"   │    │
│  │  fires unconditionally via check/6 helper                 │    │
│  └──────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘

Proof Lane (merge-blocking, hermetic)
test/crosswake/proof/phase65_*_test.exs
  │
  ├─ (a) allowlist: assert forbidden in forbidden_keys(); refute forbidden in allowed_keys()
  ├─ (b) no Bridge.Contract vocabulary: refute any diagnostics.* in Bridge.Contract.commands()
  ├─ (c) no HTTP dep: assert no Req/Finch/HTTPoison ref; mix.exs deps unchanged
  ├─ (d) support-truth + doctor: assert diagnostic_export_support_truth/0 present + non-overclaim
  └─ (e) fixtures normalize: assert_normalized_json_fixture over test/fixtures/diagnostic/*.json
```

### Recommended Project Structure

```
lib/crosswake/shell/
├── activation.ex           # EXISTING — model for namespace + to_map/1 style
├── denial.ex               # EXISTING — model for closed-enum + to_map/1 style
├── fixtures.ex             # EXISTING — model for fixture export pattern
└── diagnostic_export.ex    # NEW — contract + behaviour + Envelope + NativeDiagnostic + sanitize/1
                            # (optional: *.contracts.ex / *.redaction.ex sub-modules at planner discretion)

test/
├── crosswake/proof/
│   └── phase65_diagnostic_export_seam_test.exs   # NEW — hermetic proof lane
└── fixtures/
    └── diagnostic/                                # NEW — per layer × exit-reason
        ├── native_ios_crash.json
        ├── native_ios_metrickit_hang.json
        ├── native_android_anr.json
        ├── native_android_low_memory.json
        ├── web_liveview_fault.json
        └── bridge_command_fault.json
```

---

## Pattern 1: Behaviour-Only Transport Callback (IntentConsumer Precedent)

**What:** Define a `@callback` that the host/native-shell implements; Crosswake ships NO sender code.
**When to use:** Any seam where the host owns the transport channel (D-01/D-02).

```elixir
# Source: lib/crosswake/companions/chimeway/intent_consumer.ex [VERIFIED: codebase read]

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

**New DiagnosticExport mirrors this exactly:**
```elixir
# Target shape for lib/crosswake/shell/diagnostic_export.ex [ASSUMED — new code]
defmodule Crosswake.Shell.DiagnosticExport do
  @protocol "crosswake.diagnostic"
  @schema_version "1"

  # Documented fire-and-forget POST semantics: no response awaited, host-owned endpoint
  @callback export(Envelope.t()) :: :ok | {:error, term()}
end
```

---

## Pattern 2: Closed-Enum Constructor + Manual to_map/1 (Contracts.ex Precedent)

**What:** `normalize_attrs` → `build/3` → `validate_*/1` pipeline; `validate_closed/4` for enums; `validate_required_string/3` for strings; `to_map/1` that stringifies atoms + rejects nils.
**When to use:** Every typed struct in the house style. No `@derive Jason.Encoder`.

```elixir
# Source: lib/crosswake/companions/chimeway/contracts.ex [VERIFIED: codebase read]

# Constructor pipeline:
def new_token_evidence(attrs),
  do: attrs |> normalize_attrs() |> build(TokenEvidence, &validate_token_evidence/1)

# Validator using closed-enum:
def validate_token_evidence(%TokenEvidence{} = evidence) do
  []
  |> validate_closed(:provider, evidence.provider, @providers)
  |> validate_closed(:platform, evidence.platform, @platforms)
  |> validate_required_string(:installation_ref, evidence.installation_ref)
  |> validate_required_string(:observed_at, evidence.observed_at)
  |> to_result()
end

# Manual to_map/1 — stringifies atoms, rejects nils:
def to_map(%module{} = struct) when module in [...] do
  struct
  |> Map.from_struct()
  |> Enum.reject(fn {_key, value} -> is_nil(value) end)
  |> Enum.map(fn {key, value} -> {Atom.to_string(key), stringify(value)} end)
  |> Map.new()
end
```

---

## Pattern 3: Protocol/Version Envelope House Style (Bridge.Contract Precedent)

**What:** Module-level `@protocol` + `@version` (or `@schema_version`); enforce-keyed nested `defstruct`; `@type t`; `new_*` constructors; `to_map/1`.
**When to use:** Every versioned protocol contract in the Crosswake lib.

```elixir
# Source: lib/crosswake/bridge/contract.ex [VERIFIED: codebase read]

@protocol "crosswake.bridge"
@version "1.0.0"
@commands ~w(app.info.get haptics.impact ...)

defmodule Request do
  @enforce_keys [:protocol, :version, :command, :capability, :route_id, ...]
  defstruct [...]
  @type t :: %__MODULE__{...}
end

@spec commands() :: [String.t()]
def commands, do: @commands   # <-- this is the accessor the proof MUST assert against
```

**Critical for DIAG-01 proof:** `Bridge.Contract.commands/0` returns the 10-element list above. The proof must assert that no string matching `"diagnostics.*"` or `"diagnostic_export.*"` was added to this list.

---

## Pattern 4: Allowlist-by-Construction Redaction (Redaction.ex + Telemetry.ex Precedent)

**What:** `@forbidden_public_token_keys` module attribute; `safe_metadata/1` that drops forbidden keys; `safe_value?/1` that accepts only atoms / non-neg ints / ≤128-byte strings.
**When to use:** Any construction-time allowlist enforcement.

```elixir
# Source: lib/crosswake/companions/chimeway/redaction.ex [VERIFIED: codebase read]

@forbidden_public_token_keys [
  :token, :raw_token, :device_token, :registration_token, :apns_token, :fcm_token
]

defp safe_metadata(metadata) when is_map(metadata) do
  metadata
  |> Enum.reject(fn {key, _value} -> normalize_key(key) in @forbidden_public_token_keys end)
  |> Enum.into(%{})
end
defp safe_metadata(_metadata), do: %{}
```

```elixir
# Source: lib/crosswake/companions/chimeway/telemetry.ex [VERIFIED: codebase read]

@forbidden_metadata_keys [
  :token, :raw_token, :device_token, :registration_token, :apns_token, :fcm_token,
  :provider_payload, :raw_payload, :notification_title, :notification_body,
  :route_params, :actor_id, :subject_ref, :session_ref, :device_id, :ip,
  :user_agent, :email, :provider_response_body
]

# safe_value? — the value guard for any bounded metadata map:
defp safe_value?(nil), do: false
defp safe_value?(value) when is_atom(value), do: true
defp safe_value?(value) when is_integer(value) and value >= 0, do: true
defp safe_value?(value) when is_binary(value), do: String.length(value) <= 128
defp safe_value?(_value), do: false
```

**Key difference for Phase 65 vs Telemetry:** `sanitize/1` is FAIL-CLOSED (`{:error, :redaction_failed}` on unexpected/invalid input), not drop-and-continue. Telemetry's `metadata/1` silently drops; `sanitize/1` must REJECT. This is D-14 and is by design.

---

## Pattern 5: @notification_support_truth Shape (SupportMatrix Precedent)

**What:** Module attribute holding a list of maps; a `@spec ... :: [map()]` accessor. The `@diagnostic_export_support_truth` must mirror this shape.

```elixir
# Source: lib/crosswake/support_matrix/support_matrix.ex lines 251-270 [VERIFIED: codebase read]

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

**For Phase 65:** Replace `notification_support_truth` atom with `diagnostic_export_support_truth`, populate per D-16/D-17. The `delivery_supported: false` and `deferred: [:native_diagnostic_export, :metrickit_capture, :application_exit_info_capture]` keys + `authority_source: :host_configured_endpoint` are the critical non-overclaim markers.

---

## Pattern 6: Doctor Advisory Finding (phase_62_notification_findings Precedent)

**What:** `check/6` helper call with `:advisory` severity; fires unconditionally or on a condition; uses the `SupportMatrix` truth as the source of detail data.

```elixir
# Source: lib/crosswake/doctor/doctor.ex lines 815-838 [VERIFIED: codebase read]

check(
  :advisory,
  "notification.telemetry_contract",
  "notification_posture",
  "...",
  "...",
  %{
    event_names: Map.get(telemetry, :event_names, []),
    forbidden_metadata_keys: Map.get(telemetry, :forbidden_metadata_keys, []),
    ...
  }
)
```

**Doctor.Check struct** (the type findings must conform to):
```elixir
# Source: lib/crosswake/doctor/check.ex [VERIFIED: codebase read]

@enforce_keys [:severity, :code, :message, :check]
defstruct [:severity, :code, :message, :hint, :check, details: %{}]

@type severity :: :error | :warning | :advisory
```

**Private check/6 helper** (always use this, not `%Check{}` directly):
```elixir
# Source: lib/crosswake/doctor/doctor.ex line 1702 [VERIFIED: codebase read]

defp check(severity, code, check_name, message, hint, details \\ %{}) do
  %Check{severity: severity, code: code, check: check_name,
         message: message, hint: hint, details: details}
end
```

---

## Pattern 7: Merge-Blocking Proof Lane (Phase 64 + Phase 58 Precedent)

**What:** `use ExUnit.Case, async: false`; no `@moduletag`; no example-host refs; no `MIX_INCLUDE_*` env flags; `ProofAssertions.stable_id_message` for all assertions; hermetic-lane guard test at the bottom.

```elixir
# Source: test/crosswake/proof/phase64_runtime_line_policy_test.exs [VERIFIED: codebase read]

defmodule Crosswake.Proof.Phase64RuntimeLinePolicyTest do
  use ExUnit.Case, async: false

  # Hermetic-lane guard at bottom:
  test "hermetic lane guard: no @moduletag and no example-host references" do
    source = File.read!(__ENV__.file)
    refute Regex.match?(~r/^\s*@moduletag\s+:/m, source)
    refute String.contains?(source, "Crosswake" <> "Example.")
    refute String.contains?(source, "MIX_" <> "INCLUDE_")
  end
end
```

**Allowlist assertion idiom** (from Phase 58 pattern):
```elixir
# Source: test/crosswake/proof/phase58_auth_diagnostics_closeout_test.exs [VERIFIED: codebase read]

assert :access_token in Telemetry.forbidden_metadata_keys()
refute :access_token in Telemetry.metadata_keys()
```

**Proof assertion helper:**
```elixir
# Source: test/support/proof_assertions.ex [VERIFIED: codebase read]

def assert_normalized_json_fixture(id, json_payload, fixture_path, opts \\ []) do
  # normalises, sorts, strips volatile keys (generated_at, timestamp, etc.)
  # then deep-asserts equality
end
```

---

## Pattern 8: Fixture Convention

**Confirmed fixture layout from codebase read:**

```
test/fixtures/
└── proof/
    ├── phase52_operator_inspection.json
    ├── phase52_publish_readiness.json
    └── phase48_provider_adapter_readiness.json
```

**Finding:** The existing `test/fixtures/` root has only one sub-directory: `proof/`. The CONTEXT.md (D-10) proposes `test/fixtures/diagnostic/` — this is a NEW sub-directory and is consistent with the convention (sibling to `proof/`). [VERIFIED: codebase read — `test/fixtures/` contains only `proof/` subdirectory]

**Phase 65 fixture paths:**
```
test/fixtures/diagnostic/
├── native_ios_crash.json
├── native_ios_metrickit_hang.json
├── native_android_anr.json
├── native_android_low_memory.json
├── web_liveview_fault.json
└── bridge_command_fault.json
```

Each fixture contains a JSON-serialised `Envelope.t()` (via `to_map/1`), verifiable by `assert_normalized_json_fixture`. These become the canonical shapes Phase 67 native shells parity-lock against.

---

## Anti-Patterns to Avoid

- **`@derive Jason.Encoder` on contract structs:** Never use on `Envelope` or `NativeDiagnostic`. Use manual `to_map/1` — confirmed house style across `Bridge.Contract`, `Shell.Denial`, `Shell.Activation`, `NativeEscape.Contract`. [VERIFIED: codebase read]
- **HTTP client dep in the library:** Adding `{:req, ...}` or `{:finch, ...}` to `deps/0` in `mix.exs`. Currently only `jason`, `nimble_options`, `phoenix`, `phoenix_live_view`, `telemetry`, `ex_doc` (dev-only) + optional companion deps. [VERIFIED: codebase read of mix.exs]
- **`diagnostics.*` entry in Bridge.Contract `@commands`:** The current 10-command list must remain unchanged: `app.info.get`, `haptics.impact`, `permissions.status`, `notifications.token.get`, `share.invoke`, `files.pick`, `transfer.download`, `transfer.export`, `transfer.import`, `transfer.upload.prepare`. [VERIFIED: codebase read of bridge/contract.ex]
- **Drop-and-continue in `sanitize/1`:** Telemetry's `metadata/1` drops unknown keys; `sanitize/1` must REJECT with `{:error, :redaction_failed}`. D-14 is explicit.
- **`raw_payload: map()` on `Envelope` or `NativeDiagnostic`:** Redaction wins (D-13). No opaque passthrough.
- **Firing the doctor check conditionally on a feature flag or config:** The `:advisory` `"diagnostic_export.contract_shipped"` finding fires unconditionally — the contract is core (D-18).
- **`@moduletag :requires_example_host` or `MIX_INCLUDE_*` in the proof lane:** The proof lane is hermetic by design.
- **Promoting Android support truth:** Android stays `:verification_required` — Phase 64 locked this and Phase 65 does not touch it.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Atom-string key normalisation | Custom key normaliser | `normalize_key/1` from `Contracts`/`Telemetry` — copy verbatim | Handles `String.to_existing_atom` fallback safely |
| Value serialisation (atom → string) | Custom stringify | `stringify/1` private function in `Contracts.to_map/1` | Already handles atom/list/map/scalar recursively |
| Safe metadata guard | Custom value checker | `safe_value?/1` from `Chimeway.Telemetry` — reuse verbatim | Covers nil / non-neg-int / atom / ≤128-byte-string exactly |
| Stable proof assertion messages | Ad hoc string messages | `ProofAssertions.stable_id_message/7` | Required format for proof traceability |
| Fixture normalisation | Custom equality check | `assert_normalized_json_fixture/4` | Strips volatile keys, sorts, deep-asserts |

---

## Concrete Integration Points

### `native_runtime_version` source (Phase 64 dependency)

```elixir
# Source: lib/crosswake/manifest/types.ex — Compatibility struct [VERIFIED: codebase read]

defmodule Crosswake.Manifest.Types.Compatibility do
  @enforce_keys [
    :manifest_schema_version,
    :bridge_protocol_version,
    :native_runtime_version,   # <-- this is the Phase 64 axis the envelope carries
    :supported_manifest_sources,
    :remote_updates
  ]
end
```

The `Envelope.native_runtime_version` field carries the shell's `native_runtime_version` string (e.g. `"1.0.0"`) sourced from the shell's loaded `Compatibility` struct. This is the Phase 64 dependency link.

### `Crosswake.Shell.*` namespace

The new `DiagnosticExport` module joins `Crosswake.Shell.Activation`, `Crosswake.Shell.Denial`, and `Crosswake.Shell.Fixtures` in the `lib/crosswake/shell/` directory. The `Shell.Denial.to_map/1` nil-rejection style applies directly to `Envelope.to_map/1`.

```elixir
# Source: lib/crosswake/shell/denial.ex to_map/1 [VERIFIED: codebase read]

def to_map(%__MODULE__{} = denial) do
  %{"reason" => Atom.to_string(denial.reason), ...}
  |> Enum.reject(fn {_key, value} -> is_nil(value) or value == %{} end)
  |> Map.new()
end
```

### `SupportMatrix.canonical/1` — where to add `diagnostic_export_support_truth/0`

The accessor is a standalone public function returning the module attribute (same as `notification_support_truth/0` at line 404-405). It does NOT need to be wired into `canonical/1` — it is a separate projection used by doctor and proof tests.

### Doctor integration point

The notification finding in `doctor.ex` fires from a private `phase_62_notification_findings/1` function called at line 152. Phase 65's diagnostic-export finding should follow the same pattern: a private `phase_65_diagnostic_export_findings/0` function (unconditional, no manifest dependency) called from the top-level `run/1` pipeline and appended to findings.

---

## Common Pitfalls

### Pitfall 1: sanitize/1 Semantics — Fail-Closed vs Drop-and-Continue

**What goes wrong:** Copying `Chimeway.Telemetry.metadata/1` drop-and-continue semantics into `sanitize/1`.
**Why it happens:** `metadata/1` silently drops unknown keys and invalid values — that is the correct telemetry posture. `sanitize/1` has the opposite contract: reject on unexpected/invalid input.
**How to avoid:** `sanitize/1` validates that ALL fields in the input map correspond to declared `Envelope` fields with valid enum values; if any field is unexpected or out of enum, return `{:error, :redaction_failed}`.
**Warning signs:** Test that passes `sanitize(%{unexpected_key: "value"})` and returns `{:ok, _}` instead of `{:error, :redaction_failed}`.

### Pitfall 2: Adding diagnostics.* to Bridge.Contract Commands

**What goes wrong:** Adding `"diagnostics.export"` or similar to `@commands` in `Bridge.Contract`.
**Why it happens:** Developer instinct to make the diagnostic export discoverable through the bridge vocabulary.
**How to avoid:** The proof explicitly asserts `refute Enum.any?(Bridge.Contract.commands(), &String.starts_with?(&1, "diagnostics"))`. Never add to the `@commands` list in `bridge/contract.ex`.
**Warning signs:** Any `Req.post`, `Finch.request`, or `HTTPoison.post` call in the new module; any `"diagnostics.*"` string in `bridge/contract.ex`.

### Pitfall 3: HTTP Client Dep Creep

**What goes wrong:** Adding `:req` or `:finch` to `mix.exs deps` "just for the test" or "just as optional".
**Why it happens:** Easy to rationalise "optional dep" when writing sender helpers.
**How to avoid:** The proof test must grep the new module's source for `Req`, `Finch`, `HTTPoison`, `Mint`, `:httpc`, and the proof must also assert `mix.exs` deps are unchanged (no new HTTP client dep at any scope).
**Warning signs:** Any new entry in `mix.exs` `defp deps` with a package name containing `req`, `finch`, `mint`, `http`.

### Pitfall 4: raw_payload Reintroduction

**What goes wrong:** Adding `raw_payload: map() | nil` to `NativeDiagnostic` "as a safety valve".
**Why it happens:** The CONTEXT.md explicitly notes the envelope researcher proposed this; the redaction researcher rejected it. D-13 settles the dispute.
**How to avoid:** `NativeDiagnostic` has exactly: `source` (`:metrickit | :app_exit_info`) and `exit_reason` (closed enum). No open map field of any kind.
**Warning signs:** Any `map()` or `keyword()` field on `NativeDiagnostic` or `Envelope` (other than the optional bounded metadata map if introduced, which itself must pass `safe_value?`).

### Pitfall 5: Proof Fixture Drift

**What goes wrong:** Fixtures in `test/fixtures/diagnostic/` are written manually and then diverge from what `to_map/1` actually produces.
**Why it happens:** Fixtures written ahead of implementation don't stay in sync.
**How to avoid:** Generate fixtures from the running code during Wave 0 (or early implementation), then lock them with `assert_normalized_json_fixture`. The proof test runs the constructor, calls `to_map/1`, and compares against the saved fixture.
**Warning signs:** `assert_normalized_json_fixture` failing because atom values were not stringified (e.g. `"layer"` → `:native` instead of `"native"`).

### Pitfall 6: SupportMatrix `@diagnostic_export_support_truth` Overclaim

**What goes wrong:** Setting `delivery_supported: true` or omitting the `deferred: [:native_diagnostic_export, :metrickit_capture, :application_exit_info_capture]` key.
**Why it happens:** Wanting the support matrix to look "complete".
**How to avoid:** Mirror `@notification_support_truth` exactly: `delivery_supported: false`, `authority_source: :host_configured_endpoint`, all three deferred atoms present, posture string mentions "host owns the endpoint and the data — Crosswake is not a crash-reporting service".
**Warning signs:** `proof.diag_04.no_service_claim` proof assertion failing on the posture string check.

---

## Validation Architecture

> `workflow.nyquist_validation: true` in `.planning/config.json` — this section is required.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (built-in, no version constraint) |
| Config file | `test/test_helper.exs` (existing) |
| Quick run command | `mix test test/crosswake/proof/phase65_diagnostic_export_seam_test.exs` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| DIAG-01 | `DiagnosticExport` module exists with `@callback export/1`; no `diagnostics.*` in `Bridge.Contract.commands()`; no HTTP-client dep in `mix.exs` | unit/proof | `mix test test/crosswake/proof/phase65_diagnostic_export_seam_test.exs --include :diag_01` | ❌ Wave 0 |
| DIAG-02 | `Envelope` struct with all 7 enforce-keyed fields; `NativeDiagnostic` with closed enums; fixtures normalize via `assert_normalized_json_fixture` for all 6 fixture axes | unit/proof | `mix test test/crosswake/proof/phase65_diagnostic_export_seam_test.exs --include :diag_02` | ❌ Wave 0 |
| DIAG-03 | `sanitize/1` returns `{:error, :redaction_failed}` on invalid input; `assert forbidden in DiagnosticExport.forbidden_keys(); refute forbidden in DiagnosticExport.allowed_keys()` over full 18-key forbidden set; `sanitize/1` round-trip over valid fixture input returns `{:ok, %Envelope{}}` | unit/proof | `mix test test/crosswake/proof/phase65_diagnostic_export_seam_test.exs --include :diag_03` | ❌ Wave 0 |
| DIAG-04 | `SupportMatrix.diagnostic_export_support_truth/0` present; `delivery_supported: false`; deferred list contains 3 atoms; posture string contains non-service claim; doctor finding with code `"diagnostic_export.contract_shipped"` and severity `:advisory` present in report | unit/proof | `mix test test/crosswake/proof/phase65_diagnostic_export_seam_test.exs --include :diag_04` | ❌ Wave 0 |

### Full Proof Lane Test Structure

The merge-blocking proof file `test/crosswake/proof/phase65_diagnostic_export_seam_test.exs` must contain these assertion groups:

```
(a) DIAG-01: Vocabulary isolation
    - Bridge.Contract.commands() has no "diagnostics.*" entry
    - mix.exs source: no Req/Finch/HTTPoison/Mint/:httpc in deps

(b) DIAG-01/DIAG-02: Behaviour contract
    - DiagnosticExport defines @callback export(Envelope.t()) with the correct spec
    - Envelope struct has all 7 locked fields
    - NativeDiagnostic struct has source + exit_reason (no raw_payload)
    - layer enum is exactly [:native, :web, :bridge]
    - kind enum covers required values
    - exit_reason enum covers required values

(c) DIAG-03: Allowlist proof (merge-blocking, mirrors Phase 58 idiom)
    for each key in @forbidden_set (:token, :raw_token, :device_token, :registration_token,
      :apns_token, :fcm_token, :provider_payload, :raw_payload, :notification_title,
      :notification_body, :route_params, :actor_id, :subject_ref, :session_ref,
      :device_id, :ip, :user_agent, :email, :provider_response_body):
      assert key in DiagnosticExport.forbidden_keys()
      refute key in DiagnosticExport.allowed_keys()
    - sanitize/1 round-trip: build valid input → sanitize → {:ok, %Envelope{}}
    - sanitize/1 fail-closed: inject unexpected key → {:error, :redaction_failed}

(d) DIAG-04: Support-truth and doctor non-overclaim
    - SupportMatrix.diagnostic_export_support_truth/0 returns non-empty list
    - delivery_supported is false
    - deferred list contains :native_diagnostic_export, :metrickit_capture, :application_exit_info_capture
    - posture string contains "not a crash-reporting service"
    - Doctor.run/1 report contains finding with code == "diagnostic_export.contract_shipped"
    - That finding has severity :advisory
    - That finding's message does NOT contain "crash-reporting service" (non-overclaim)

(e) DIAG-02: Fixtures normalize
    for each fixture in test/fixtures/diagnostic/:
      assert_normalized_json_fixture(id, to_map_output, fixture_path, opts)

(f) Hermetic-lane guard
    - no @moduletag in source
    - no Crosswake.Example. references
    - no MIX_INCLUDE_ env flag references
```

### Sampling Rate

- **Per task commit:** `mix test test/crosswake/proof/phase65_diagnostic_export_seam_test.exs`
- **Per wave merge:** `mix test` (full suite — must stay green)
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps

- [ ] `test/crosswake/proof/phase65_diagnostic_export_seam_test.exs` — covers DIAG-01..04
- [ ] `test/fixtures/diagnostic/` directory + 6 fixture JSON files — covers DIAG-02 fixture axes
  - `native_ios_crash.json`
  - `native_ios_metrickit_hang.json`
  - `native_android_anr.json`
  - `native_android_low_memory.json`
  - `web_liveview_fault.json`
  - `bridge_command_fault.json`

No framework install needed — ExUnit already configured.

---

## Security Domain

> `security_enforcement` is absent from config (treat as enabled).

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — (no auth credentials in diagnostic envelope) |
| V3 Session Management | no | — (no session state) |
| V4 Access Control | no | — (host owns the endpoint; Crosswake is not the recipient) |
| V5 Input Validation | yes | `validate_closed/4`, `validate_required_string/3`, fail-closed `sanitize/1` |
| V6 Cryptography | no | — (no encryption in the contract; host-owned transport) |
| V7 Error Handling | yes | `{:error, :redaction_failed}` fail-closed; no leaking raw data in error responses |
| V13 API / Web Services | partial | POST content-type + method documented as fire-and-forget contract (no server-side implementation in Phase 65) |

### Known Threat Patterns for This Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Token/PII smuggling via open map field | Information Disclosure | Allowlist-by-construction: typed struct cannot hold forbidden data; no `raw_payload` map |
| Partial/silent data loss in sanitize | Repudiation | Fail-closed: `sanitize/1` rejects rather than drops-and-continues |
| Bridge vocabulary expansion (adds diagnostics.* command) | Tampering | Proof assertion: `refute` diagnostics.* in `Bridge.Contract.commands()` |
| HTTP-client dep added to published lib (first-party-service claim) | Elevation of Privilege | Proof assertion: grep new module for Req/Finch/HTTPoison/Mint/:httpc |
| SupportMatrix overclaim (delivery_supported: true) | Spoofing | Proof assertion: `assert support_truth.delivery_supported == false` |

---

## Environment Availability

> This phase is purely code/config changes with no external tooling dependencies beyond the existing Elixir/Mix stack.

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir / Mix | All compilation + test | ✓ | (existing project) | — |
| ExUnit | Proof lane tests | ✓ | built-in | — |
| Jason | `to_map/1` → JSON encoding in fixtures | ✓ | `~> 1.4` (in mix.exs) | — |

**Missing dependencies with no fallback:** none.

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `@derive Jason.Encoder` on contract structs | Manual `to_map/1` with nil rejection | v3.1 pattern established | Prevents accidental nil serialisation; no Jason Encoder protocol pollution |
| Drop-and-continue on bad telemetry input | Fail-closed `sanitize/1` on envelope input | Phase 65 introduces this (stricter than telemetry) | Silent partial data loss is worse than rejected payload for diagnostics |
| Open `map()` passthrough for "raw" data | Typed closed enum structs only (no raw_payload) | Phase 65 decision D-13 | Cannot smuggle token/PII through opaque map |

**Deprecated / not applicable:**
- `Ecto.Schema` / changesets: Not used in Crosswake contracts — use `@enforce_keys defstruct` + manual constructors.
- `Jason.Encoder` protocol: Not derived on contract structs — use manual `to_map/1`.

---

## Assumptions Log

> No claims in this research required [ASSUMED] tagging — all are verified by direct codebase reads.

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| — | All claims verified by codebase read | All | — |

**This table is empty:** All claims in this research were verified via direct codebase reads of the referenced files. No training-data-only assumptions used.

---

## Open Questions

1. **Optional `NativeDiagnostic.metadata` sub-map**
   - What we know: D-13 says "Default posture: typed codes only, no metadata map unless the planner finds a concrete need (user-confirmed: locked without one)."
   - What's unclear: The planner may find a concrete need for a bounded metadata map (e.g., OS exit-code integer). If so, it MUST pass the same Chimeway key-allowlist + `safe_value?` guard.
   - Recommendation: Start with no metadata map (the locked decision). If the planner finds a concrete need, add a `NativeDiagnostic.metadata: %{}` field — but the `sanitize/1` must then also run the `safe_value?` guard on every value.

2. **Sub-module split vs single module**
   - What we know: CONTEXT.md leaves this to planner discretion (whether a `DiagnosticExport.Contracts`, `.Redaction` sub-module split mirrors the Chimeway layout or stays in one module).
   - What's unclear: The Chimeway layout is `chimeway/contracts.ex` + `chimeway/redaction.ex` + `chimeway/telemetry.ex` + `chimeway/intent_consumer.ex`. Phase 65 has fewer moving parts.
   - Recommendation: Start with a single `shell/diagnostic_export.ex` unless the line count makes the module unwieldy. The Chimeway split exists because Chimeway has many more contracts; the diagnostic seam is narrower.

3. **Doctor finding placement — unconditional vs manifest-conditional**
   - What we know: D-18 says "fires unconditionally (the contract is core, not capability-gated)".
   - What's unclear: Exactly where in the `doctor.ex` run pipeline to call the new finding function.
   - Recommendation: Mirror `phase_62_notification_findings/1` — add a `phase_65_diagnostic_export_findings/0` private function (no manifest arg — unconditional) and call it from the main `run/1` findings accumulation.

---

## Sources

### Primary (HIGH confidence — direct codebase reads)

- `lib/crosswake/companions/chimeway/intent_consumer.ex` — `@callback consume_intent/1` behaviour-only precedent
- `lib/crosswake/companions/chimeway/contracts.ex` — full constructor/validation/`to_map` template
- `lib/crosswake/companions/chimeway/redaction.ex` — `@forbidden_public_token_keys` + `safe_metadata/1`
- `lib/crosswake/companions/chimeway/telemetry.ex` — `@forbidden_metadata_keys` + `safe_value?/1`
- `lib/crosswake/bridge/contract.ex` — `@protocol`/`@version`/`@commands` house style; current 10-command vocabulary
- `lib/crosswake/native_escape/contract.ex` — alternative protocol/version envelope style
- `lib/crosswake/shell/denial.ex` — `Shell.*` namespace + closed-enum + `to_map/1` nil-rejection
- `lib/crosswake/shell/activation.ex` — `Shell.Activation` module pattern
- `lib/crosswake/shell/fixtures.ex` — `Shell.Fixtures` module pattern
- `lib/crosswake/manifest/types.ex` — `Compatibility.native_runtime_version` axis
- `lib/crosswake/support_matrix/support_matrix.ex` — `@notification_support_truth` shape + accessor; `rebuild_matrix/1` pattern
- `lib/crosswake/doctor/doctor.ex` — `check/6` helper; `phase_62_notification_findings` structural model
- `lib/crosswake/doctor/check.ex` — `Check` struct + `severity` type
- `lib/crosswake/doctor/formatter.ex` — `format_rebuild_matrix/1` + `format_evidence_tier/1` patterns
- `test/support/proof_assertions.ex` — `assert_normalized_json_fixture/4`, `assert_file_exact/4`, `stable_id_message/7`
- `test/crosswake/proof/phase58_auth_diagnostics_closeout_test.exs` — `assert in forbidden_keys(); refute in allowed_keys()` idiom
- `test/crosswake/proof/phase64_runtime_line_policy_test.exs` — hermetic lane guard; `@tag :rlineNN` pattern; `stable_id_message` usage
- `test/crosswake/companions/chimeway/telemetry_test.exs` — allowlist-drop assertion idiom
- `test/fixtures/` — actual fixture directory structure (`proof/` only sub-dir)
- `mix.exs` — confirmed no HTTP client deps; exact dep list
- `.planning/config.json` — `nyquist_validation: true`

---

## Metadata

**Confidence breakdown:**
- Contract module structure: HIGH — verified from existing code
- Redaction/allowlist patterns: HIGH — verified from existing code
- SupportMatrix truth shape: HIGH — verified from existing code
- Doctor finding patterns: HIGH — verified from existing code
- Proof lane conventions: HIGH — verified from existing code
- Fixture convention: HIGH — verified from filesystem read

**Research date:** 2026-06-04
**Valid until:** 2026-07-04 (stable — no external dependencies; all patterns are internal)

---

## RESEARCH COMPLETE

**Phase:** 65 — Diagnostic Export Seam (Elixir)
**Confidence:** HIGH

### Key Findings

- **No new dependencies.** The entire phase is additive within existing Crosswake code. All helper functions (`validate_closed/4`, `validate_required_string/3`, `safe_value?/1`, `safe_metadata/1`, `to_map/1` stringify pattern) are directly reusable from existing modules.
- **The existing 10-command `Bridge.Contract.commands()` list is the proof anchor.** The proof test must `refute Enum.any?(Bridge.Contract.commands(), &String.starts_with?(&1, "diagnostics"))` to satisfy DIAG-01. This list must not change.
- **`sanitize/1` is STRICTER than `Telemetry.metadata/1`.** Telemetry drops-and-continues; `sanitize/1` must fail-closed (`{:error, :redaction_failed}`). This is the most important semantic difference to not get wrong.
- **`test/fixtures/diagnostic/` is a new sub-directory** (current fixture root has only `proof/`). It is consistent with the convention. Fixtures must be generated from running code (via `to_map/1`), not written manually from memory.
- **The doctor finding fires unconditionally** (not gated on manifest or config), mirrors the structure of `phase_62_notification_findings` but without a manifest argument.

### File Created

`.planning/phases/65-diagnostic-export-seam-elixir/65-RESEARCH.md`

### Confidence Assessment

| Area | Level | Reason |
|------|-------|--------|
| Standard Stack | HIGH | Direct codebase read of mix.exs — no HTTP deps present |
| Architecture | HIGH | Direct codebase read of all 8 referenced integration files |
| Redaction patterns | HIGH | Direct codebase read of chimeway/redaction.ex + telemetry.ex |
| Proof lane conventions | HIGH | Direct codebase read of phase58 + phase64 proof tests |
| SupportMatrix/Doctor | HIGH | Direct codebase read of support_matrix.ex + doctor.ex |
| Fixture convention | HIGH | Direct filesystem inspection of test/fixtures/ |

### Open Questions

- Whether the planner adds a bounded `metadata: %{}` sub-map to `NativeDiagnostic` (locked: no, unless concrete need found)
- Sub-module split (single `diagnostic_export.ex` vs `*/contracts.ex` + `*/redaction.ex`) — planner discretion

### Ready for Planning

Research complete. Planner can now create PLAN.md files.
