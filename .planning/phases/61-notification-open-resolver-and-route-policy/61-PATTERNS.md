# Phase 61: Notification-Open Resolver And Route Policy - Pattern Map

**Mapped:** 2026-06-03
**Files analyzed:** 5
**Analogs found:** 5 / 5

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/crosswake/companions/chimeway/contracts.ex` | contract/struct | data transfer | (Self-modification) | exact |
| `lib/crosswake/companions/chimeway/resolver.ex` | orchestrator | request-response | `lib/crosswake/companions/sigra/evaluator.ex` | role-match |
| `lib/crosswake/policy/schema.ex` | configuration | config validation | (Self-modification) | exact |
| `examples/phoenix_host/lib/crosswake_example/chimeway/notification_open_intent.ex` | model/schema | CRUD | `examples/phoenix_host/lib/crosswake_example/saas_portal/handoff_ticket.ex` | exact |
| `examples/phoenix_host/lib/crosswake_example/chimeway/registry.ex` | service/lifecycle | transactional | `examples/phoenix_host/lib/crosswake_example/saas_portal/handoff.ex` | role-match |
| `lib/crosswake/shell/denial.ex` | error constants | errors | (Self-modification) | exact |
| `lib/crosswake/companions/chimeway/denial_codes.ex` | error config | sanitizer | `lib/crosswake/companions/sigra/denial_codes.ex` | exact |

## Pattern Assignments

### `lib/crosswake/companions/chimeway/contracts.ex` (contract/struct, data transfer)

**Analog:** `lib/crosswake/companions/chimeway/contracts.ex` (Self)

**Struct Definition Pattern** (lines 61-96, `TokenBinding`):
```elixir
    @enforce_keys [
      :binding_ref,
      :installation_ref,
      :provider,
      :platform,
      :environment,
      :token_ref,
      :token_fingerprint,
      :state,
      :reason,
      :bound_at,
      :last_seen_at
    ]
    defstruct [
      :binding_ref,
      :installation_ref,
      :provider,
      ...
```
*Note: Use this structure to define `NotificationOpenEvidence` and `OpenResolution`.*

**Validation Constructor Pattern** (lines 173-177):
```elixir
  @spec new_token_binding(map() | keyword()) :: {:ok, TokenBinding.t()} | {:error, keyword()}
  def new_token_binding(attrs),
    do:
      attrs
      |> normalize_attrs()
      |> build(TokenBinding, &validate_token_binding/1)
```


### `lib/crosswake/companions/chimeway/resolver.ex` (orchestrator, request-response)

**Analog:** `lib/crosswake/companions/sigra/evaluator.ex`

**Denial Packaging Pattern** (lines 201-213):
```elixir
  defp deny(%RouteEntry{} = route, code, details, opts) do
    sanitized =
      details
      |> Map.put_new(
        :evaluated_at,
        DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()
      )
      |> DenialCodes.sanitize_details()

    {:deny,
     Denial.new(
       reason: :step_up_required, # <-- Change to :notification_open_denied
       code: code,
       message: @generic_message,
       route_id: route.id,
       details: sanitized
     )}
  end
```

### `lib/crosswake/policy/schema.ex` (configuration, config validation)

**Analog:** `lib/crosswake/policy/schema.ex` (Self)

**DSL Schema Declaration** (lines 111-114):
```elixir
            auth_return: [
              type: {:custom, __MODULE__, :validate_auth_return_declaration, []},
              type_spec: quote(do: auth_return_declaration() | nil)
            ]
```
*Note: Add `notification_open` attribute using the `custom` validation strategy mirroring `auth_return` or `commerce`.*

**Map/Keyword Validation Function** (lines 418-444):
```elixir
  def validate_auth_return_declaration(declaration) when is_list(declaration) do
    declaration
    |> Enum.into(%{})
    |> validate_auth_return_declaration()
  end

  def validate_auth_return_declaration(declaration) when is_map(declaration) do
    # Map attributes explicitly, pulling atoms and strings
    ...
```

### `examples/phoenix_host/.../notification_open_intent.ex` (model/schema, CRUD)

**Analog:** `examples/phoenix_host/lib/crosswake_example/saas_portal/handoff_ticket.ex`

**Intent Schema Pattern** (lines 12-36):
```elixir
  schema "sigra_handoff_tickets" do
    field(:ticket_ref, :string)
    field(:ticket_digest, :string)
    field(:state, :string, default: "issued")
    field(:subject_ref, :string)
    # ...
    field(:issued_at, :utc_datetime)
    field(:expires_at, :utc_datetime)
    field(:consumed_at, :utc_datetime)
    field(:revoked_at, :utc_datetime)
    # ...
    timestamps(type: :utc_datetime)
  end
```
*Note: Follow this precise Ecto schema definition and changeset constraint validations.*

### Registry / Intent Consumption (service/lifecycle, transactional)

**Analog:** `examples/phoenix_host/lib/crosswake_example/saas_portal/handoff.ex`

**Ecto.Multi Transaction Pattern (Consume & Audit)** (lines 206-258):
```elixir
  defp consume_ticket(ticket, envelope, attrs) do
    evaluated_at = fetch_datetime(attrs, :evaluated_at) || now()
    ticket_ref = ticket.ticket_ref

    query =
      from(row in HandoffTicket,
        where:
          row.ticket_ref == ^ticket_ref and row.state == "issued" and is_nil(row.consumed_at) and
            is_nil(row.revoked_at) and row.expires_at > ^evaluated_at
      )

    Ecto.Multi.new()
    |> Ecto.Multi.update_all(:consume, query,
      set: [state: "redeemed", consumed_at: evaluated_at, updated_at: evaluated_at]
    )
    |> Ecto.Multi.run(:ticket, fn repo, %{consume: {count, _}} ->
      if count == 1 do
        {:ok, repo.get_by!(HandoffTicket, ticket_ref: ticket_ref)}
      else
        {:error, lifecycle_denial(ticket, evaluated_at)}
      end
    end)
    # ... audit insertion
    |> Repo.transaction()
    |> case do
      {:ok, result} ->
        {:ok, result}
      {:error, _step, _reason, _changes} ->
        {:error, ...}
    end
  end
```

### `lib/crosswake/companions/chimeway/denial_codes.ex` (error config, sanitizer)

**Analog:** `lib/crosswake/companions/sigra/denial_codes.ex`

**Allowlist Sanitizer Pattern** (lines 53-85):
```elixir
  @allowed_detail_keys [
    "route_binding",
    "evaluated_at",
    "binding_kind",
    # ... Add Phase 61 specific keys here
  ]

  def sanitize_details(details) when is_map(details) do
    details
    |> Enum.reduce(%{}, fn {key, value}, acc ->
      string_key = stringify_key(key)

      if string_key in @allowed_detail_keys and safe_value?(string_key, value) do
        Map.put(acc, string_key, normalize_value(value))
      else
        acc
      end
    end)
  end
```

### `lib/crosswake/shell/denial.ex` (error constants, errors)

**Analog:** `lib/crosswake/shell/denial.ex` (Self)

**Reason Extension Pattern** (lines 8-20):
```elixir
  @reasons [
    :compatibility_mismatch,
    # ...
    :gate_denied,
    :kill_switch_active,
    :step_up_required
    # <-- ADD :notification_open_denied here
  ]

  @type reason ::
          :compatibility_mismatch
          # ...
          | :step_up_required
          # <-- AND ADD HERE
```

## Shared Patterns

### Error Handling & Responses
**Source:** `Crosswake.Shell.Denial`
**Apply to:** `Crosswake.Companions.Chimeway.Resolver`
- Always return failures as `{:error, %Shell.Denial{}}` or passthrough exactly what `RouteGate.evaluate` returns natively if it is a gate/step-up rejection.

## No Analog Found

All requested boundaries map perfectly to existing Sigra, Routing, and Error Handling precedents. No zero-match patterns.

## Metadata

**Analog search scope:** `lib/crosswake/`, `examples/phoenix_host/`
**Files scanned:** 7 explicitly matched from context globals
**Pattern extraction date:** 2026-06-03
