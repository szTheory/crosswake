# Phase 91: Identity + Telemetry Contract - Research

**Researched:** 2026-06-09
**Domain:** Elixir struct contract extension + telemetry allowlist module (mirror-an-existing-pattern)
**Confidence:** HIGH — all claims verified directly from codebase source files

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** `thread_id` is optional (default nil, NOT in `@enforce_keys`) on `Bridge.Contract.Request`, `Bridge.Contract.Reply`, `Bridge.Denial`, and `Shell.Activation.Request`.
- **D-02:** Type spec is `thread_id: String.t() | nil` — opaque string, no format validation in the contract.
- **D-03:** `thread_id` is copied through `ok_reply/2`, `deny_reply/2`, `Denial.from_request/2` exactly like `correlation_id`.
- **D-04:** Bump `Contract.@version` `"1.0.0" → "1.1.0"` (informational only — NOT gate-wired).
- **D-05:** Fix `to_map(%Request{})` footgun: add `|> Enum.reject(fn {_k, v} -> is_nil(v) end) |> Map.new()` so nil `thread_id` serializes as absent, not `"thread_id" => null`.
- **D-06:** Hex patch bump `0.1.0 → 0.1.1`.
- **D-07:** `@event_names` declares exactly three names: `[:crosswake, :threadline, :request, :start]`, `[:crosswake, :threadline, :request, :stop]`, `[:crosswake, :threadline, :request, :exception]`.
- **D-08:** One declared event = one emitter, introduced together. No pre-declared unemitted events.
- **D-09:** `source` metadata key value domain is `:inbound | :minted`.
- **D-10:** Rationale for `source` semantics locked.
- **D-11:** Mirror `Crosswake.Companions.Sigra.Telemetry` structure exactly; `@metadata_keys [:thread_id, :correlation_id, :route_id, :source]`.

### Claude's Discretion
- Exact ordering of `defstruct` keys.
- Precise `@forbidden_metadata_keys` membership (derive from Sigra — research task).
- Whether a small `Event` helper struct is worth it for Threadline's narrow surface.
- Test file organization.

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PROP-02 | Plug emits `[:crosswake, :threadline, :request, :start\|:stop\|:exception]` telemetry with low-cardinality metadata allowlist and forbidden-key rejection | Sigra.Telemetry verified as exact pattern; `@forbidden_metadata_keys` membership derived below |
| PROP-04 | `thread_id` first-class field on bridge + activation contracts, carried across all activation sources | All four target structs read; nil-filter footgun in Request.to_map confirmed and fix specified |
</phase_requirements>

---

## Summary

Phase 91 is a pure mirror-and-extend operation. There are no new architectural decisions to make — the CONTEXT.md decisions are authoritative and all findings below confirm them. The work is: (1) add `thread_id` to four struct definitions and thread it through their factory/serialization helpers; (2) create `Crosswake.Threadline.Telemetry` by adapting `Crosswake.Companions.Sigra.Telemetry` with a narrow four-key `@metadata_keys` and a domain-appropriate `@forbidden_metadata_keys`; (3) bump `Contract.@version` and `mix.exs`/`mix_lock` version strings; (4) write hermetic proof tests.

Zero runtime dependencies change. Zero OTel ever. No new packages. The `telemetry` hex dependency is already present (Sigra uses `:telemetry.execute/3`).

**Primary recommendation:** Follow Sigra.Telemetry line-for-line. The only divergence is the four-key `@metadata_keys`, the three-name `@event_names`, and the domain-appropriate `@forbidden_metadata_keys` list derived below.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| `thread_id` field on wire envelopes | Bridge / Activation contract structs | — | Field lives in typed Elixir structs; no persistence |
| `to_map/1` nil-filter fix | Bridge / Activation contract structs | — | Serialization correctness; no tier change |
| `Threadline.Telemetry` allowlist guard | Library module (compile-time contract) | — | Pure module attribute + reduce-filter; no runtime state |
| `@version` bump | Bridge / Contract module attribute | — | Informational string; not evaluated at runtime gate |
| Hex version bump | mix.exs | — | Package manifest; no code logic |

---

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `:telemetry` | already in deps (Sigra uses it) | `:telemetry.execute/3` wrapper | Standard Erlang/Elixir telemetry bus; already a dep |

No new packages are added in this phase. [VERIFIED: codebase grep]

### Supporting
None. This phase is entirely in-project Elixir module work.

### Alternatives Considered
None applicable — decisions are locked.

**Installation:** No new packages. No `mix deps.get` step required.

---

## Package Legitimacy Audit

No external packages are installed in this phase.

**Packages removed due to slopcheck [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

---

## Architecture Patterns

### System Architecture Diagram

```
  Bridge.Contract.Request  ──────────────────────────────────────────┐
    fields: correlation_id (existing)                                  │
            thread_id       (NEW, optional)                            │
            version         (bumped 1.0.0→1.1.0)                      │
    to_map: nil-filter added (footgun fix)                             │
                                                                       ▼
  Bridge.Contract.ok_reply/2 ──────────────────────────────── Bridge.Contract.Reply
  Bridge.Contract.deny_reply/2                                   fields: thread_id (NEW)
  Bridge.Denial.from_request/2                                   to_map: already nil-filters
    propagates request.thread_id                                         │
                                                                         ▼
  Shell.Activation.Request ─────── new_request/1 ─────────── (thread_id flows through)
    fields: thread_id (NEW, optional)                          to_map: already nil-filters
    @enforce_keys: unchanged


  Crosswake.Threadline.Telemetry  (NEW MODULE, mirrors Sigra)
    @event_names      ──── [:crosswake, :threadline, :request, :start|:stop|:exception]
    @metadata_keys    ──── [:thread_id, :correlation_id, :route_id, :source]
    @forbidden_keys   ──── (PII denylist — see below)
    safe_value?/1     ──── atom | non_neg_int | binary ≤128 | nil→false
    metadata/1        ──── reduce-filter: drops forbidden, keeps allowlisted+safe
    execute/3         ──── :telemetry.execute/3 wrapper via metadata/1
    valid_event_name?/1 ── name in @event_names
    event_names/0     ──── accessor
```

### Recommended Project Structure
```
lib/crosswake/
├── bridge/
│   ├── contract.ex          # MODIFY: add thread_id to Request/Reply, fix Request.to_map, bump @version
│   └── denial.ex            # MODIFY: add thread_id to struct + from_request/2
├── shell/
│   └── activation.ex        # MODIFY: add thread_id to Activation.Request
└── threadline/
    └── telemetry.ex         # CREATE: Crosswake.Threadline.Telemetry

test/crosswake/
├── bridge/
│   └── contract_test.exs    # MODIFY: update to_map equality assertions; add thread_id tests
├── shell/
│   └── activation_test.exs  # MODIFY: add thread_id round-trip test
└── threadline/
    └── telemetry_test.exs   # CREATE: hermetic proof tests (mirrors sigra/telemetry_test.exs)

test/crosswake/proof/
    phase91_threadline_contract_closeout_test.exs  # CREATE: published-allowlist proof
```

---

## Verified Module Shapes (Code Evidence)

### 1. Sigra.Telemetry — the exact pattern to mirror

**Source:** `lib/crosswake/companions/sigra/telemetry.ex` [VERIFIED: codebase read]

**`@forbidden_metadata_keys` — complete list:**
```elixir
@forbidden_metadata_keys [
  :access_token,
  :actor_id,
  :authorization_code,
  :credential_id,
  :device_id,
  :email,
  :id_token,
  :ip,
  :nonce,
  :org_id,
  :passkey_credential_id,
  :pkce_verifier,
  :provider_payload,
  :raw_return_to,
  :refresh_token,
  :return_to,
  :session_ref,
  :subject_ref,
  :user_agent
]
```

**`safe_value?/1` — exact implementation:**
```elixir
defp safe_value?(nil), do: false
defp safe_value?(value) when is_atom(value), do: true
defp safe_value?(value) when is_integer(value) and value >= 0, do: true
defp safe_value?(value) when is_binary(value), do: String.length(value) <= 128
defp safe_value?(_value), do: false
```

**`metadata/1` — exact reduce-filter:**
```elixir
def metadata(attrs) when is_map(attrs) do
  attrs
  |> Enum.reduce(%{}, fn {key, value}, acc ->
    key = normalize_key(key)

    cond do
      key in @forbidden_metadata_keys ->
        acc

      key in @metadata_keys and safe_value?(value) ->
        Map.put(acc, key, normalize_value(value))

      true ->
        acc
    end
  end)
end
```

**`execute/3`:**
```elixir
@spec execute([atom()], map(), map() | keyword()) :: :ok
def execute(name, measurements \\ %{}, metadata \\ %{}) do
  :telemetry.execute(name, measurements, metadata(metadata))
end
```

**`valid_event_name?/1`:**
```elixir
@spec valid_event_name?(term()) :: boolean()
def valid_event_name?(name), do: name in @event_names
```

**`Event` helper struct:** Sigra and Chimeway both use an inner `defmodule Event` with `@enforce_keys [:name]`. The `new_event/1` constructor raises `ArgumentError` on unknown names. Threadline's surface is narrow (three names, four metadata keys) — the planner should include it for consistency with the established pattern (Claude's discretion per D-11 note; recommendation: include `Event` struct).

**`normalize_key/1`:** Handles string→atom coercion using `String.to_existing_atom/1` for known keys; passes unknowns through as strings (which then fall through the allowlist and are silently dropped).

### 2. Bridge.Contract — verified struct shapes and to_map diff

**Source:** `lib/crosswake/bridge/contract.ex` [VERIFIED: codebase read]

**`@version` current value:** `"1.0.0"` (line 10). [VERIFIED: codebase read]

**Request `@enforce_keys`** (all nine must stay enforced; `thread_id` is NOT added):
```elixir
@enforce_keys [
  :protocol, :version, :command, :capability,
  :route_id, :active_route_id, :origin,
  :native_runtime_version, :correlation_id
]
```

**D-05 confirmed — the exact footgun:** `to_map(%Request{})` (lines 165-179) returns a plain map literal with no nil-filter pipe. `to_map(%Reply{})` (lines 182-195) already ends with:
```elixir
|> Enum.reject(fn {_key, value} -> is_nil(value) end)
|> Map.new()
```
After adding `thread_id` to both structs, a nil `thread_id` on `Request` would serialize as `"thread_id" => nil`. The fix is to add the same reject pipe to the `Request` clause. The `Reply` clause needs no change (already nil-filters).

**`ok_reply/2` — thread_id propagation target:**
```elixir
def ok_reply(%Request{} = request, payload \\ %{}) when is_map(payload) do
  new_reply(
    command: request.command,
    route_id: request.route_id,
    correlation_id: request.correlation_id,  # <-- thread_id must be added here
    status: :ok,
    payload: payload
  )
end
```
D-03 requires adding `thread_id: request.thread_id` to both `ok_reply/2` and `deny_reply/2`.

**`deny_reply/2` — same pattern:**
```elixir
def deny_reply(%Request{} = request, %Denial{} = denial) do
  new_reply(
    command: request.command,
    route_id: request.route_id,
    correlation_id: request.correlation_id,  # <-- thread_id must be added here
    status: :deny,
    denial: denial
  )
end
```

### 3. Bridge.Denial — verified struct shape

**Source:** `lib/crosswake/bridge/denial.ex` [VERIFIED: codebase read]

**Current `@enforce_keys`:** `[:command, :route_id, :correlation_id, :denial]` — all four are always present. `thread_id` joins as optional (not in `@enforce_keys`).

**`from_request/2` — thread_id propagation target:**
```elixir
def from_request(%Contract.Request{} = request, %ShellDenial{} = denial) do
  new(
    command: request.command,
    route_id: request.route_id,
    correlation_id: request.correlation_id,  # <-- thread_id must be added here
    denial: denial
  )
end
```

**`to_map/1`:** Uses `|> Types.to_map()` at line 48. Verify whether `Types.to_map/1` nil-filters — if not, same footgun as `Contract.Request`. Research note: `Types.to_map/1` is the manifest types helper; inspect its behavior for `nil` values.

### 4. Shell.Activation.Request — verified struct and to_map

**Source:** `lib/crosswake/shell/activation.ex` [VERIFIED: codebase read]

**Current `@enforce_keys`:**
```elixir
@enforce_keys [
  :source, :origin, :manifest_source,
  :bridge_protocol_version, :native_runtime_version, :correlation_id
]
```
`thread_id` is NOT in `@enforce_keys` (D-01 compliant). Note: `correlation_id` IS in `@enforce_keys` on `Activation.Request` — contrast with `Bridge.Contract.Request` where it is also enforced.

**`to_map(%Request{})` already nil-filters (confirmed):**
```elixir
def to_map(%Request{} = request) do
  %{
    "route_id" => request.route_id,
    "url" => request.url,
    ...
  }
  |> Enum.reject(fn {_key, value} -> is_nil(value) end)  # <-- already present
  |> Map.new()
end
```
D-05 footgun does NOT apply to `Activation.Request.to_map/1`. Adding `"thread_id" => request.thread_id` to the map literal is sufficient; the nil-filter already handles absent values. [VERIFIED: codebase read, lines 148-164]

**`new_request/1` — thread_id propagation target:**
```elixir
struct!(Request, %{
  ...
  correlation_id: Keyword.fetch!(attrs, :correlation_id),
  # thread_id: Keyword.get(attrs, :thread_id)  ← must be added
})
```

### 5. Compatibility gate — D-04 confirmed

**Source:** `lib/crosswake/compatibility/compatibility.ex` lines 604-613 [VERIFIED: codebase read]

```elixir
defp bridge_target(%Contract.Request{} = request) do
  %Target{
    manifest_schema_version: "1.0.0",
    bridge_protocol_version: request.version,  # <-- gated value is request.version
    native_runtime_version: request.native_runtime_version,
    ...
  }
end
```

The gate evaluates `request.version` (the `bridge_protocol_version` field from the native shell, NOT the `Contract.@version` module attribute). The `Contract.@version` attribute (`"1.0.0"`) is used as the default in `new_request/1` when no explicit version is passed, meaning it is passed as `request.version` to the native side and reflected back. However, `validate_bridge_protocol/4` (lines 300-323) compares `target.bridge_protocol_version` against `compatibility.bridge_protocol_version` from the manifest's `CompatibilityTruth` struct — this is sourced from the manifest definition, not from bumping the Elixir module attribute.

**Conclusion:** Bumping `Contract.@version "1.0.0" → "1.1.0"` changes the default value injected by `new_request/1` at runtime. This would change what `request.version` carries, and thus what `bridge_target` constructs as `bridge_protocol_version` — which IS compared against the manifest's `CompatibilityTruth.bridge_protocol_version`. This is a subtle but important finding: **the `@version` module attribute IS the default protocol version sent on the wire.** If existing integration tests construct requests without an explicit `version:` kwarg, they pick up the default, and if the manifest's `CompatibilityTruth` still declares `"1.0.0"`, the gate will see `"1.1.0"` from the new default and pass (since `Version.compare("1.1.0", "1.0.0") != :lt`). However, the `@version` bump is additive-minor, so `compatible_version?/2` (lines 616-628) uses semver `>=` logic, meaning `"1.1.0"` satisfies a `"1.0.0"` requirement. Gate will not break.

**Important planner note:** The version bump changes the default `version` field on new `Contract.Request` structs. Any test with a literal `to_map` equality assertion that asserts `"version" => "1.0.0"` WILL break (see `contract_test.exs` line 79). These tests must be updated to `"version" => "1.1.0"`.

### 6. Offline.Telemetry — the LOOSER shape to NOT follow

**Source:** `lib/crosswake/offline/telemetry.ex` [VERIFIED: codebase read]

Offline has no `@event_names`, no `@forbidden_metadata_keys`, no `execute/3`, no `metadata/1` reduce-filter, no `valid_event_name?/1`. It also has required `@enforce_keys` on its `Event` struct (brittle). DO NOT follow this pattern for Threadline.

---

## Recommended `@forbidden_metadata_keys` for Threadline.Telemetry

Derived from Sigra's list, narrowed and extended for the Threadline context. The Threadline telemetry surface carries thread correlation fields — no auth tokens, no actor identity, no session handles.

**Recommended list:**
```elixir
@forbidden_metadata_keys [
  :access_token,
  :actor_id,
  :actor_ref,
  :authorization_code,
  :credential_id,
  :device_id,
  :email,
  :id_token,
  :ip,
  :nonce,
  :org_id,
  :passkey_credential_id,
  :pkce_verifier,
  :provider_payload,
  :raw_return_to,
  :refresh_token,
  :return_to,
  :session_ref,
  :subject_ref,
  :user_agent
]
```

**Reasoning vs Sigra:**
- `:actor_ref` added — Phase 91 context introduces `actor_ref` as the opaque identity field for Phase 94's ledger; it must never appear in telemetry (PII-adjacent opaque handle).
- All Sigra entries retained — the Threadline surface is a superset of what Sigra guards against; no reason to relax.
- `:credential_id` retained — general token material.

This list is marked as Claude's Discretion in D-11 and flagged `[ASSUMED]` pending planner/user confirmation.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Metadata safe-value filtering | Custom validator | Exact `safe_value?/1` from Sigra | Already tested; ≤128-char binary rule is non-obvious |
| Forbidden-key rejection | Per-call guard | `metadata/1` reduce-filter | Stateless, no raise, idempotent — reuse exactly |
| Telemetry emission | Direct `:telemetry.execute/3` calls | `execute/3` wrapper | Passes metadata through guard; no accidental PII leakage |
| Nil serialization | Manual map construction | nil-filter pipe already in Reply/Activation | Apply same pattern to Request |

**Key insight:** The forbidden-key denylist and the reduce-filter are the entire security story for this phase's telemetry contract. Hand-rolling either produces PII exposure risk; reusing the exact Sigra shape produces a verifiable, proof-tested contract.

---

## Common Pitfalls

### Pitfall 1: Enforcing `thread_id` in `@enforce_keys`
**What goes wrong:** Every caller (tests, native shell, existing integration code) breaks at compile time.
**Why it happens:** Instinct to "make required fields required."
**How to avoid:** D-01 is explicit. `@enforce_keys` = fields the caller is definitionally responsible for NOW. `thread_id` has no current callers until Phase 92/93.
**Warning signs:** Any `ArgumentError` mentioning `thread_id` in struct construction.

### Pitfall 2: Forgetting to add `thread_id` to `new_request/1` opts fetch
**What goes wrong:** `thread_id` is on the struct but `new_request/1` silently ignores it; callers who pass `thread_id:` in opts see it disappear.
**Why it happens:** `struct!` call inside `new_request/1` explicitly maps kwargs — it is not automatic.
**How to avoid:** Add `thread_id: Keyword.get(attrs, :thread_id)` to the `struct!` map in all four `new_request/new` constructors.
**Warning signs:** Round-trip test fails — `new_request([..., thread_id: "x"]).thread_id == nil`.

### Pitfall 3: `Request.to_map/1` serializing `"thread_id" => nil`
**What goes wrong:** Wire format carries explicit null key; native shell or JSON decoder may choke.
**Why it happens:** `to_map(%Request{})` is a plain map literal with no nil-filter (unlike Reply/Activation). D-05 documents this exactly.
**How to avoid:** Add `|> Enum.reject(fn {_k, v} -> is_nil(v) end) |> Map.new()` to the `Request` clause only. Do not change the Reply clause (already correct).
**Warning signs:** `contract_test.exs` to_map equality assertion contains `"thread_id" => nil`.

### Pitfall 4: Breaking the existing `to_map` equality assertion for `"version"`
**What goes wrong:** `contract_test.exs` line 79 asserts `"version" => "1.0.0"` in a `to_map` equality. After the `@version` bump, that assertion fails.
**Why it happens:** Test builds `Contract.new_request/1` without an explicit `version:` kwarg, so the default `@version` is used.
**How to avoid:** Update the equality assertion to `"version" => "1.1.0"` when bumping `@version`.
**Warning signs:** `ContractTest` test "bridge requests carry the typed route..." fails after version bump.

### Pitfall 5: Pre-declaring unemitted event names
**What goes wrong:** Adopters attach handlers to declared names; handlers never fire; adopter trust erodes.
**Why it happens:** Desire to document the "full future" shape now.
**How to avoid:** D-08 is explicit — exactly three names, matching the Phase 92 Plug span triplet. No extras.
**Warning signs:** `@event_names` contains names without a corresponding emitter in the codebase.

### Pitfall 6: `Denial.to_map/1` nil-handling via `Types.to_map/1`
**What goes wrong:** Adding `"thread_id" => denial.thread_id` to `Denial.to_map/1` may serialize as null if `Types.to_map/1` does not nil-filter.
**Why it happens:** `Denial.to_map/1` delegates to `Types.to_map/1` rather than using the direct nil-filter pipe.
**How to avoid:** Verify `Types.to_map/1` behavior for nil values before writing the Denial.to_map change. If it does not nil-filter, apply the same `Enum.reject` pattern directly before delegating.
**Warning signs:** Test asserting Denial serialization contains `"thread_id" => nil`.

---

## Code Examples

### Threadline.Telemetry skeleton (adapted from Sigra)
```elixir
# Source: lib/crosswake/companions/sigra/telemetry.ex (verified)
defmodule Crosswake.Threadline.Telemetry do
  @moduledoc """
  Stable telemetry contract for Threadline correlation diagnostics.
  ...
  """

  @event_names [
    [:crosswake, :threadline, :request, :start],
    [:crosswake, :threadline, :request, :stop],
    [:crosswake, :threadline, :request, :exception]
  ]

  @metadata_keys [:thread_id, :correlation_id, :route_id, :source]

  @forbidden_metadata_keys [
    :access_token, :actor_id, :actor_ref, :authorization_code,
    :credential_id, :device_id, :email, :id_token, :ip, :nonce,
    :org_id, :passkey_credential_id, :pkce_verifier, :provider_payload,
    :raw_return_to, :refresh_token, :return_to, :session_ref,
    :subject_ref, :user_agent
  ]

  defmodule Event do
    @moduledoc false
    @enforce_keys [:name]
    defstruct [:name, :thread_id, :correlation_id, :route_id, :source]
    @type t :: %__MODULE__{name: [atom()]}
  end

  # accessors, new_event/1, metadata/1, execute/3, valid_event_name?/1
  # — all identical in shape to Sigra.Telemetry
end
```

### Bridge.Contract.Request — thread_id addition pattern
```elixir
# Modify defstruct to add: thread_id: nil  (after correlation_id, before capabilities)
# Modify to_map(%Request{}) to add nil-filter:
def to_map(%Request{} = request) do
  %{
    "protocol" => request.protocol,
    "version" => request.version,
    "command" => request.command,
    "capability" => request.capability,
    "route_id" => request.route_id,
    "active_route_id" => request.active_route_id,
    "origin" => request.origin,
    "native_runtime_version" => request.native_runtime_version,
    "correlation_id" => request.correlation_id,
    "thread_id" => request.thread_id,           # NEW
    "capabilities" => Types.to_map(request.capabilities),
    "installed_packs" => Types.to_map(request.installed_packs),
    "payload" => Types.to_map(request.payload)
  }
  |> Enum.reject(fn {_k, v} -> is_nil(v) end)  # NEW (footgun fix D-05)
  |> Map.new()
end
```

### ok_reply/2 thread_id propagation
```elixir
# Source: lib/crosswake/bridge/contract.ex (verified pattern)
def ok_reply(%Request{} = request, payload \\ %{}) when is_map(payload) do
  new_reply(
    command: request.command,
    route_id: request.route_id,
    correlation_id: request.correlation_id,
    thread_id: request.thread_id,   # NEW (D-03)
    status: :ok,
    payload: payload
  )
end
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| No `thread_id` on envelopes | Optional `thread_id` alongside `correlation_id` | Phase 91 (this phase) | Enables thread correlation from Phase 92 onward |
| No Threadline telemetry contract | `Crosswake.Threadline.Telemetry` with PII denylist | Phase 91 (this phase) | Phase 92 Plug can emit immediately after this ships |
| `Contract.@version "1.0.0"` | `"1.1.0"` | Phase 91 (this phase) | Informational signal; additive |
| `Request.to_map` serializes nil fields | nil-filtered (matches Reply/Activation) | Phase 91 (this phase) | Wire format hygiene |

**Deprecated/outdated:**
- `Contract.@version "1.0.0"`: replaced by `"1.1.0"` in this phase.

---

## Existing Test Files

### Files that must stay green after this phase

| File | What it asserts | Change needed |
|------|-----------------|---------------|
| `test/crosswake/bridge/contract_test.exs` | `to_map` equality with `"version" => "1.0.0"` (line 79); `to_map(reply)` with exact key set; `to_map` with denial | Update `"version"` assertion to `"1.1.0"`; verify nil `thread_id` is absent from map output |
| `test/crosswake/shell/activation_test.exs` | `new_request` round-trips; `to_map` implicit nil-filter for `route_id`/`url` | Verify `thread_id: nil` not serialized (already nil-filters); add thread_id round-trip |
| `test/crosswake/companions/sigra/telemetry_test.exs` | Sigra event names, metadata keys, forbidden-key rejection | No change expected |
| `test/crosswake/proof/phase58_auth_diagnostics_closeout_test.exs` | Exact Sigra event_names list, forbidden keys | No change expected |
| `test/crosswake/compatibility/compatibility_test.exs` | Gate uses `bridge_protocol_version` from request | If any test uses default `@version` from `new_request/1` without explicit `version:`, may need update |

### Files to create in this phase

| File | Purpose |
|------|---------|
| `test/crosswake/threadline/telemetry_test.exs` | Unit tests for Threadline.Telemetry (mirror sigra/telemetry_test.exs pattern) |
| `test/crosswake/proof/phase91_threadline_contract_closeout_test.exs` | Published-allowlist proof: exact `event_names/0` list, exact `metadata_keys/0` list, exact `forbidden_metadata_keys/0` list; forbidden-key rejection via `execute/3`; `thread_id` on all four structs; `to_map` nil-filter behavior |

---

## Runtime State Inventory

Step 2.5: SKIPPED — this is a greenfield module creation + struct field addition, not a rename/refactor/migration phase. No stored data, live service config, OS-registered state, secrets, or build artifacts reference any renamed string.

---

## Validation Architecture

**Note:** `nyquist_validation` key is absent from `.planning/config.json` — treated as enabled.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (project standard) |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test test/crosswake/threadline/ test/crosswake/bridge/contract_test.exs test/crosswake/shell/activation_test.exs` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PROP-02 | `Threadline.Telemetry.event_names/0` returns exactly three span names | unit | `mix test test/crosswake/threadline/telemetry_test.exs` | Wave 0 |
| PROP-02 | `metadata_keys/0` returns `[:thread_id, :correlation_id, :route_id, :source]` | unit | `mix test test/crosswake/threadline/telemetry_test.exs` | Wave 0 |
| PROP-02 | `forbidden_metadata_keys/0` contains PII keys; excluded from `metadata_keys/0` | unit | `mix test test/crosswake/threadline/telemetry_test.exs` | Wave 0 |
| PROP-02 | `metadata/1` drops forbidden keys silently (no raise) | unit | `mix test test/crosswake/threadline/telemetry_test.exs` | Wave 0 |
| PROP-02 | `execute/3` with forbidden metadata does not raise | unit | `mix test test/crosswake/threadline/telemetry_test.exs` | Wave 0 |
| PROP-02 | Published-allowlist proof: exact list equality | proof | `mix test test/crosswake/proof/phase91_threadline_contract_closeout_test.exs` | Wave 0 |
| PROP-04 | `Bridge.Contract.Request` has `thread_id` field, default nil | unit | `mix test test/crosswake/bridge/contract_test.exs` | exists (modify) |
| PROP-04 | `Bridge.Contract.Reply` has `thread_id` field | unit | `mix test test/crosswake/bridge/contract_test.exs` | exists (modify) |
| PROP-04 | `Bridge.Denial` has `thread_id` field | unit | `mix test test/crosswake/bridge/contract_test.exs` | exists (modify) |
| PROP-04 | `Activation.Request` has `thread_id` field, default nil | unit | `mix test test/crosswake/shell/activation_test.exs` | exists (modify) |
| PROP-04 | `Request.to_map` nil-filters `thread_id` when nil (footgun fix) | unit | `mix test test/crosswake/bridge/contract_test.exs` | exists (modify) |
| PROP-04 | `ok_reply` propagates `thread_id` from request | unit | `mix test test/crosswake/bridge/contract_test.exs` | exists (modify) |
| PROP-04 | `deny_reply` propagates `thread_id` from request | unit | `mix test test/crosswake/bridge/contract_test.exs` | exists (modify) |
| PROP-04 | `Denial.from_request/2` propagates `thread_id` | unit | `mix test test/crosswake/bridge/contract_test.exs` | exists (modify) |
| PROP-04 | `Contract.@version` is `"1.1.0"` | unit | `mix test test/crosswake/proof/phase91_threadline_contract_closeout_test.exs` | Wave 0 |

**Validation signals — what is observable hermetically:**
1. Struct field presence: `%Contract.Request{thread_id: nil}` compiles without error.
2. `to_map` serialization: nil `thread_id` → key absent; non-nil `thread_id` → key present with value.
3. Forbidden-key rejection: `execute/3` with forbidden metadata executes without raising.
4. `@version` attribute value: `Contract.version() == "1.1.0"`.
5. Published-allowlist proof: exact list equality assertions (mirrors phase-58 closeout test pattern).
6. Propagation round-trip: `new_request([..., thread_id: "t-123"])` → `ok_reply(request, %{})` → `reply.thread_id == "t-123"`.

**Nothing here requires Ecto, network, or device.** All signals are pure struct construction, map serialization, and module attribute accessors.

### Sampling Rate
- **Per task commit:** `mix test test/crosswake/threadline/ test/crosswake/bridge/contract_test.exs test/crosswake/shell/activation_test.exs`
- **Per wave merge:** `mix test`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `test/crosswake/threadline/telemetry_test.exs` — covers PROP-02 (unit; mirrors sigra/telemetry_test.exs)
- [ ] `test/crosswake/proof/phase91_threadline_contract_closeout_test.exs` — covers PROP-02 published-allowlist proof + PROP-04 contract version assertion

---

## Environment Availability

Step 2.6: Verified standard Elixir/Mix toolchain is sufficient. No external services, databases, or non-project CLIs are required. The `:telemetry` hex dependency is already present in the project (in use by Sigra, Chimeway, and Offline).

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir / Mix | all | confirmed (project compiles) | project-standard | — |
| `:telemetry` hex | `execute/3` wrapper | confirmed (already a dep) | in lockfile | — |

**Missing dependencies with no fallback:** none
**Missing dependencies with fallback:** none

---

## Security Domain

> `security_enforcement` not explicitly disabled in config — section included.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — |
| V3 Session Management | no | — |
| V4 Access Control | no | — |
| V5 Input Validation | yes | `safe_value?/1` + reduce-filter (no raise, fail-silent on forbidden) |
| V6 Cryptography | no | — |

### Known Threat Patterns for telemetry allowlist contract

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| PII leakage via telemetry metadata | Information Disclosure | `@forbidden_metadata_keys` denylist + `metadata/1` reduce-filter; keys dropped silently |
| High-cardinality value injection (unbounded string) | Denial of Service (cardinality explosion in time-series) | `safe_value?/1` binary ≤128 char limit |
| Unknown keys passing through | Information Disclosure | All-or-nothing allowlist: only `@metadata_keys` keys with `safe_value?/1` values pass; everything else is silently dropped |

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `:actor_ref` should be added to `@forbidden_metadata_keys` beyond Sigra's list | Recommended `@forbidden_metadata_keys` | Low — conservative to include it; worst case is a slightly longer denylist |
| A2 | `Event` helper struct is worth including for Threadline's narrow surface | Code Examples / Claude's Discretion | Low — Sigra and Chimeway both have it; omitting is also valid |

---

## Open Questions

1. **`Denial.to_map/1` nil-handling via `Types.to_map/1`**
   - What we know: `to_map/1` delegates to `Types.to_map(denial)` at the end (line 48 of `denial.ex`), which calls `ShellDenial.to_map` on the nested denial struct.
   - What's unclear: The body of `Denial.to_map/1` builds a literal map and then pipes to `Types.to_map()` — it's not obvious whether `Types.to_map/1` nil-filters. Need to verify before writing the `thread_id => denial.thread_id` addition.
   - Recommendation: Planner should read `lib/crosswake/manifest/types.ex` for `Types.to_map/1` behavior before writing the Denial task. If it does not nil-filter, apply `Enum.reject` before the `Types.to_map()` delegation.

2. **Whether `compatibility_test.exs` uses default `@version`**
   - What we know: The compatibility test file was identified as touching `to_map` — but we confirmed it exercises `bridge_protocol_version` from the request, not from `Contract.@version` directly.
   - What's unclear: Whether any test calls `Contract.new_request/1` without an explicit `version:` kwarg and then asserts on the version string.
   - Recommendation: Planner should run `grep -n "version.*1.0.0\|1\.0\.0.*version" test/crosswake/compatibility/compatibility_test.exs` before writing that wave.

---

## Sources

### Primary (HIGH confidence)
- `lib/crosswake/companions/sigra/telemetry.ex` — complete module text verified; all function signatures, `@forbidden_metadata_keys`, `safe_value?/1`, `metadata/1`, `execute/3`
- `lib/crosswake/companions/chimeway/telemetry.ex` — verified as same shape as Sigra (confirming the pattern is established)
- `lib/crosswake/offline/telemetry.ex` — verified as the LOOSER shape to avoid
- `lib/crosswake/bridge/contract.ex` — `@version "1.0.0"`, `Request`/`Reply` structs, `@enforce_keys`, `to_map` nil-filter presence/absence confirmed
- `lib/crosswake/bridge/denial.ex` — `Denial` struct, `from_request/2`, `to_map/1` confirmed
- `lib/crosswake/shell/activation.ex` — `Activation.Request` `@enforce_keys` (incl. `correlation_id`), `new_request/1`, `to_map/1` nil-filter confirmed
- `lib/crosswake/compatibility/compatibility.ex` (lines 300-323, 604-613) — confirmed `bridge_target` uses `request.version`; `validate_bridge_protocol` compares against manifest `CompatibilityTruth.bridge_protocol_version`; semver `>=` logic confirmed
- `lib/crosswake/compatibility/route_gate.ex` — confirmed gate does not directly reference `Contract.@version`
- `test/crosswake/companions/sigra/telemetry_test.exs` — full test text; pattern for Threadline telemetry tests
- `test/crosswake/proof/phase58_auth_diagnostics_closeout_test.exs` — published-allowlist proof pattern confirmed
- `test/crosswake/bridge/contract_test.exs` — confirmed exact `to_map` equality assertion at line 77-96 (version `"1.0.0"` will need updating)
- `test/crosswake/shell/activation_test.exs` — confirmed `new_request` round-trips; nil-filter already present for `route_id`/`url`

### Secondary (MEDIUM confidence)
None required — all findings verified from codebase source.

### Tertiary (LOW confidence)
None.

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new packages; `:telemetry` already present
- Architecture: HIGH — all four target structs read and verified
- Pitfalls: HIGH — all sourced from direct code reading
- Forbidden-key list: MEDIUM — Sigra list confirmed; `:actor_ref` addition is Claude's discretion (A1)

**Research date:** 2026-06-09
**Valid until:** 2026-07-09 (stable — all findings are from internal codebase, no external dependencies)

---

## RESEARCH COMPLETE

**Phase:** 91 — Identity + Telemetry Contract
**Confidence:** HIGH

### Key Findings

1. **`Sigra.Telemetry` is the exact template.** The full `@forbidden_metadata_keys` list (19 keys) is verified. `safe_value?/1`, `metadata/1`, `execute/3`, and the `Event` struct pattern are all confirmed. Threadline diverges only in `@metadata_keys` (4 keys vs 17) and `@event_names` (3 vs 14).

2. **`Request.to_map/1` footgun confirmed (D-05).** Lines 165-179 of `contract.ex` — plain map literal, no nil-filter. The `Reply.to_map/1` already has the fix. The `Activation.Request.to_map/1` already has the fix. Only `Bridge.Contract.Request` needs the footgun fixed.

3. **`@version` bump has one test breakage.** `contract_test.exs` line 79 asserts `"version" => "1.0.0"`. After bumping `Contract.@version` to `"1.1.0"`, this assertion must be updated. The compatibility gate uses semver `>=` so `"1.1.0"` satisfies a `"1.0.0"` requirement without breaking the gate.

4. **`Activation.Request.@enforce_keys` does NOT include `thread_id`.** Adding `thread_id` as optional is correct and straightforward — `new_request/1` just needs `Keyword.get(attrs, :thread_id)` added to the `struct!` map.

5. **No test file for `Threadline.Telemetry` exists yet.** Two new test files are needed: `test/crosswake/threadline/telemetry_test.exs` (unit) and `test/crosswake/proof/phase91_threadline_contract_closeout_test.exs` (proof/closeout).

6. **`Denial.to_map/1` nil-handling is an open question.** The `Types.to_map/1` delegation needs one quick verification before the Denial task is written. Planner should add a micro-investigation step.

### File Created
`.planning/phases/91-identity-telemetry-contract/91-RESEARCH.md`

### Confidence Assessment
| Area | Level | Reason |
|------|-------|--------|
| Standard Stack | HIGH | No new packages; telemetry already present |
| Contract shapes (all 4 structs) | HIGH | All source files read verbatim |
| to_map nil-filter behavior | HIGH | Exact line numbers verified |
| Compatibility gate | HIGH | Lines 300-323 and 604-613 read verbatim |
| Forbidden-key list | MEDIUM | Sigra list verified; `:actor_ref` addition is discretionary |
| `Types.to_map/1` nil behavior for Denial | LOW | Not verified in this session — flagged as open question |

### Open Questions
- Whether `Types.to_map/1` nil-filters (affects `Denial.to_map/1` implementation for `thread_id`).
- Whether `compatibility_test.exs` has any test asserting `"1.0.0"` as the default version string.

### Ready for Planning
Research complete. Planner can now create PLAN.md waves.
