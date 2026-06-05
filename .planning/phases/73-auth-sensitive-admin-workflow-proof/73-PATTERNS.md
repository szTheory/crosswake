# Phase 73: Auth-Sensitive Admin Workflow Proof - Pattern Map

**Mapped:** 2026-06-05
**Files analyzed:** 6
**Analogs found:** 6 / 6

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `test/crosswake/proof/phase73_auth_sensitive_admin_workflow_proof_test.exs` | test | request-response | `test/crosswake/proof/phase73_auth_sensitive_admin_workflow_proof_test.exs` (existing) | exact |
| `.github/workflows/phase73-proof.yml` | config | batch | `.github/workflows/phase73-proof.yml` (existing) | exact |
| `examples/phoenix_host/lib/crosswake_example/saas_portal/step_up_on_mount.ex` | middleware | request-response | `examples/phoenix_host/lib/crosswake_example/saas_portal/step_up_on_mount.ex` | exact |
| `examples/phoenix_host/lib/crosswake_example/saas_portal/step_up_plug.ex` | middleware | request-response | `examples/phoenix_host/lib/crosswake_example/saas_portal/step_up_plug.ex` | exact |
| `examples/phoenix_host/lib/crosswake_example/saas_portal/step_up_intent.ex` | model | CRUD | `examples/phoenix_host/lib/crosswake_example/saas_portal/step_up_intent.ex` | exact |
| `examples/phoenix_host/lib/crosswake_example/saas_portal/step_up.ex` | service | state-machine | `examples/phoenix_host/lib/crosswake_example/saas_portal/step_up.ex` | exact |

## Pattern Assignments

### `examples/phoenix_host/lib/crosswake_example/saas_portal/step_up_on_mount.ex` (middleware, request-response)

**Analog:** `examples/phoenix_host/lib/crosswake_example/saas_portal/step_up_on_mount.ex`

**LiveView Gating core pattern** (lines 12-25):
```elixir
  def on_mount({:require_step_up, opts}, _params, _session, socket) do
    case decision(Keyword.fetch!(opts, :route), Keyword.get(opts, :auth_context), opts) do
      {:allow, _facts} ->
        {:cont, socket}

      {:challenge, _intent, challenge} ->
        redirected = LiveView.redirect(socket, to: challenge_path(challenge))
        {:halt, redirected}

      {:deny, %Denial{} = denial} ->
        redirected = LiveView.redirect(socket, to: denied_path(denial))
        {:halt, redirected}
    end
  end
```

### `examples/phoenix_host/lib/crosswake_example/saas_portal/step_up_plug.ex` (middleware, request-response)

**Analog:** `examples/phoenix_host/lib/crosswake_example/saas_portal/step_up_plug.ex`

**Plug Pipeline Gating core pattern** (lines 17-30):
```elixir
  def call(conn, opts) do
    case decision(Keyword.fetch!(opts, :route), Keyword.get(opts, :auth_context), opts) do
      {:allow, _facts} ->
        conn

      {:challenge, _intent, challenge} ->
        conn
        |> Controller.redirect(to: challenge_path(challenge))
        |> halt()

      {:deny, %Denial{} = denial} ->
        conn
        |> Controller.redirect(to: denied_path(denial))
        |> halt()
    end
  end
```

### `examples/phoenix_host/lib/crosswake_example/saas_portal/step_up_intent.ex` (model, CRUD)

**Analog:** `examples/phoenix_host/lib/crosswake_example/saas_portal/step_up_intent.ex`

**Ecto Schema and Ephemeral State Machine Definition** (lines 8-28):
```elixir
  @states ["issued", "challenged", "consumed", "expired", "canceled", "revoked"]

  schema "sigra_step_up_intents" do
    field(:intent_ref, :string)
    field(:locator_digest, :string)
    field(:state, :string, default: "issued")
    # ...
    field(:issued_at, :utc_datetime)
    field(:expires_at, :utc_datetime)
    field(:challenged_at, :utc_datetime)
    field(:consumed_at, :utc_datetime)
    field(:canceled_at, :utc_datetime)
    field(:revoked_at, :utc_datetime)
```

### `examples/phoenix_host/lib/crosswake_example/saas_portal/step_up.ex` (service, state-machine)

**Analog:** `examples/phoenix_host/lib/crosswake_example/saas_portal/step_up.ex`

**Telemetry & Audit Multi-Transaction Pattern** (lines 147-158, 226-248):
```elixir
    Ecto.Multi.new()
    |> Ecto.Multi.update_all(:challenge, query,
      set: [state: "challenged", challenged_at: now, updated_at: now]
    )
    |> Ecto.Multi.run(:intent, fn repo, %{challenge: {count, _}} ->
      if count == 1, do: {:ok, repo.get!(StepUpIntent, intent.id)}, else: {:error, :stale}
    end)
    |> Ecto.Multi.insert(:audit_event, fn %{intent: challenged_intent} ->
      StepUpAuditEvent.changeset(
        %StepUpAuditEvent{},
        audit_attrs(:challenge, challenged_intent, %{
          state_before: "issued",
          state_after: "challenged",
          outcome: "allowed",
          occurred_at: now,
          request_ref: fetch_string(attrs, :request_ref) || ref("req"),
          binding_result: "matched"
        })
      )
    end)
    |> Repo.transaction()
```

### `test/crosswake/proof/phase73_auth_sensitive_admin_workflow_proof_test.exs` (test, request-response)

**Analog:** `test/crosswake/proof/phase73_auth_sensitive_admin_workflow_proof_test.exs`

**Hermetic Route Authority Proof Pattern** (lines 73-89):
```elixir
    test "persistent native session evidence is denied until backend step-up projects fresh authority" do
      route = admin_route()
      target = target()

      persistent_native_context = auth_context(lane: [cached: true, assurance_level: :mfa])
      decision = RouteGate.evaluate(manifest(), @admin_route_id, target, auth_context: persistent_native_context)

      assert route.auth_posture == :strict_recent
      assert decision.status == :deny
      assert decision.denial.reason == :step_up_required
      assert decision.denial.code == "auth.step_up.cached_not_allowed"
      assert decision.transition == :halt

      fresh_context = auth_context(lane: [assurance_level: :mfa, authenticated_at: @fixed_now])
      allowed = RouteGate.evaluate(manifest(), @admin_route_id, target, auth_context: fresh_context)

      assert allowed.status == :allow
      assert allowed.transition == :activate
    end
```

## Shared Patterns

### Error Handling / Denial Formatting
**Source:** `examples/phoenix_host/lib/crosswake_example/saas_portal/step_up.ex`
**Apply to:** Authentication route gates and intents
```elixir
  defp denial(code, details) do
    Denial.new(
      reason: :step_up_required,
      code: code,
      message: "Additional authentication is required.",
      details: DenialCodes.sanitize_details(details)
    )
  end
```

## Metadata

**Analog search scope:** `lib/**/*`, `test/**/*proof*.exs`, `examples/phoenix_host/lib/crosswake_example/saas_portal/**/*`
**Files scanned:** ~100 matching files
**Pattern extraction date:** 2026-06-05
