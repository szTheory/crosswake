defmodule CrosswakeExample.LocalFirst.PhysicalIphoneAuthority do
  @moduledoc false

  import Phoenix.ConnTest, only: [build_conn: 0]

  alias Crosswake.Companions.Sigra.Contracts
  alias Crosswake.Manifest.Builder
  alias Crosswake.Manifest.Types.RouteEntry
  alias Crosswake.Policy.Route
  alias Crosswake.Compatibility.{RouteGate, Target}
  alias CrosswakeExample.LocalFirst.{ReviewEvent, SyncController}
  alias CrosswakeExample.Repo

  @scope_current "v1.reference_scope_current"
  @scope_other "v1.reference_scope_other00"
  @backend_ids [
    "PI-LOGOUT-ACCOUNT-FENCE",
    "PI-ENTRY-DISABLEMENT",
    "PI-REPLAY-DISABLEMENT",
    "PI-EXACTLY-ONCE-EMPTY-OUTBOX"
  ]

  @spec ready?() :: :ok | :blocked
  def ready? do
    with true <- Process.whereis(Repo) != nil,
         true <- Process.whereis(CrosswakeExample.RulesteadFlagSource) != nil,
         {:ok, _} <- auth_context() do
      :ok
    else
      _ -> :blocked
    end
  end

  @spec report(map()) :: binary() | {:error, :unavailable}
  def report(%{schema_version: 1, device_class: :physical_iphone}) do
    # Ecto debug output can contain the opaque mutation/scope values exercised
    # below. Keep the producer silent and return only its closed report.
    Logger.disable(self())

    with :ok <- reset_fixture(),
         %{effect_count: 1, idempotency_count: 1} <- accepted_replay(),
         %{effect_count: 1, idempotency_count: 1} <- duplicate_replay(),
         :ok <- reset_fixture(),
         %{retained_count: rejected, halted: :rejected} when rejected > 0 <- retained_rejection(),
         :ok <- reset_fixture(),
         %{retained_count: conflict, halted: :conflict} when conflict > 0 <- retained_conflict(),
         :ok <- reset_fixture(),
         %{retained_count: scoped, fenced: true} when scoped > 0 <- scope_fence(),
         :ok <- reset_fixture(),
         %{retained_count: logged_out, fenced: true} when logged_out > 0 <- logout_fence(),
         :ok <- reset_fixture(),
         %{retained_count: entry, blocked: true} when entry > 0 <- entry_disablement(),
         :ok <- reset_fixture(),
         %{retained_count: replay, blocked: true} when replay > 0 <- replay_disablement() do
      Jason.encode!(%{
        "schema_version" => 1,
        "device_class" => "physical_iphone",
        "assertions" => Enum.map(@backend_ids, &%{"id" => &1, "outcome" => "passed"})
      })
    else
      _ -> {:error, :unavailable}
    end
  rescue
    _ -> {:error, :unavailable}
  after
    CrosswakeExample.RulesteadFlagSource.delete_flag(:rulestead)
    safe_reset_fixture()
    Logger.enable(self())
  end

  def report(_), do: {:error, :unavailable}

  def reset_fixture do
    Repo.delete_all(ReviewEvent)
    :ok
  end

  defp safe_reset_fixture do
    reset_fixture()
  rescue
    _ -> :ok
  end

  def accepted_replay, do: assert_accepted(event("00000000-0000-4000-8000-000000000001"))
  def duplicate_replay, do: assert_accepted(event("00000000-0000-4000-8000-000000000001"))

  def retained_rejection do
    id = "00000000-0000-4000-8000-000000000002"
    insert_event(id, @scope_current, "rejected")

    case SyncController.sync_events(
           build_conn(),
           @scope_current,
           [event(id)],
           authority_options()
         ) do
      {:ok, %{halted: :rejected, accepted_records: []}} -> retained(:rejected)
      _ -> :error
    end
  end

  def retained_conflict do
    id = "00000000-0000-4000-8000-000000000003"
    insert_event(id, @scope_other, "accepted")

    case SyncController.sync_events(
           build_conn(),
           @scope_current,
           [event(id)],
           authority_options()
         ) do
      {:ok, %{halted: :transaction_failed, accepted_records: []}} -> retained(:conflict)
      _ -> :error
    end
  end

  def scope_fence do
    insert_event("00000000-0000-4000-8000-000000000004", @scope_current, "accepted")

    case SyncController.sync_events(
           build_conn(),
           @scope_current,
           [event("00000000-0000-4000-8000-000000000005")],
           authority_options(session_scope: @scope_other)
         ) do
      {:blocked, :scope_mismatch} -> %{retained_count: event_count(), fenced: true}
      _ -> :error
    end
  end

  defp logout_fence do
    insert_event("00000000-0000-4000-8000-000000000006", @scope_current, "accepted")

    case SyncController.sync_events(
           build_conn(),
           @scope_current,
           [event("00000000-0000-4000-8000-000000000007")],
           authority_options(logged_out: true)
         ) do
      {:blocked, :authority_unavailable} -> %{retained_count: event_count(), fenced: true}
      _ -> :error
    end
  end

  def entry_disablement do
    insert_event("00000000-0000-4000-8000-000000000008", @scope_current, "accepted")
    CrosswakeExample.RulesteadFlagSource.set_flag(:rulestead, :gated)

    manifest =
      Builder.build(
        [
          %Route{
            id: "reference-entry-gate",
            runtime: :live_view,
            offline: :unavailable,
            gated_by: :rulestead
          }
        ],
        [
          %{
            path: "/entry-gate",
            metadata: %{crosswake: [id: "reference-entry-gate"]},
            helper: "entry_gate",
            verb: :get
          }
        ]
      )

    result =
      case RouteGate.evaluate(manifest, "reference-entry-gate", %Target{},
             activation_source: :in_app_navigation
           ) do
        %{status: :deny} -> %{retained_count: event_count(), blocked: true}
        _ -> :error
      end

    CrosswakeExample.RulesteadFlagSource.delete_flag(:rulestead)
    result
  end

  def replay_disablement do
    insert_event("00000000-0000-4000-8000-000000000009", @scope_current, "accepted")

    case SyncController.sync_events(
           build_conn(),
           @scope_current,
           [event("00000000-0000-4000-8000-000000000010")],
           authority_options(feature: :deny)
         ) do
      {:blocked, :feature_disabled} -> %{retained_count: event_count(), blocked: true}
      _ -> :error
    end
  end

  defp assert_accepted(event) do
    case SyncController.sync_events(build_conn(), @scope_current, [event], authority_options()) do
      {:ok, %{accepted_records: [%{outcome: :accepted}], halted: nil}} ->
        %{effect_count: event_count(), idempotency_count: event_count()}

      _ ->
        :error
    end
  end

  defp authority_options(overrides \\ []) do
    session_scope = Keyword.get(overrides, :session_scope, @scope_current)
    logged_out? = Keyword.get(overrides, :logged_out, false)
    feature = Keyword.get(overrides, :feature, :allow)
    {:ok, context} = auth_context()

    [
      session: fn _ ->
        if logged_out?,
          do: {:error, :auth_required},
          else: {:ok, %{scope_ref: session_scope, auth_context: context}}
      end,
      route: fn _ -> {:ok, route()} end,
      feature: fn _ -> feature end,
      domain: fn _, _, _ -> :allow end
    ]
  end

  defp auth_context do
    Contracts.new_auth_context(%{
      actor_id: "reference-actor",
      org_id: "reference-host",
      mfa_level: :mfa,
      auth_age: 0
    })
  end

  defp route do
    %RouteEntry{
      id: "route-1630000000000001",
      path: "/study/session",
      runtime: :offline_island,
      offline: :local_first,
      auth_min_level: :password,
      auth_posture: :fresh_required
    }
  end

  defp event(id), do: %{"client_mutation_id" => id, "card_id" => 1, "rating" => "good"}

  defp insert_event(id, scope, status) do
    %ReviewEvent{}
    |> Ecto.Changeset.change(%{
      client_mutation_id: id,
      card_id: 1,
      rating: "good",
      status: status,
      scope_ref: scope
    })
    |> Repo.insert!()
  end

  defp retained(halted), do: %{retained_count: event_count(), halted: halted}
  defp event_count, do: Repo.aggregate(ReviewEvent, :count, :id)
end
