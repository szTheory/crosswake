defmodule CrosswakeExample.LocalFirst.PhysicalIphoneAuthorityTest do
  use ExUnit.Case, async: false

  alias CrosswakeExample.LocalFirst.PhysicalIphoneAuthorityFixture

  test "Phoenix independently returns every closed backend authority observation" do
    assert {:ok, report} = PhysicalIphoneAuthorityFixture.run()

    assert %{
             "schema_version" => 1,
             "device_class" => "physical_iphone",
             "assertions" => assertions
           } = report

    assert assertions ==
             Crosswake.ProofLane.PhysicalIphoneContract.assertions()
             |> Enum.filter(&(&1.owner == :backend_authority))
             |> Enum.map(&%{"id" => &1.id, "outcome" => "passed"})

    rendered = Jason.encode!(report)

    for forbidden <- ["fixture-alpha", "fixture-beta", "selected-private", "free-form-private"] do
      refute rendered =~ forbidden
    end
  end
end

defmodule CrosswakeExample.LocalFirst.PhysicalIphoneAuthorityFixture do
  @moduledoc false

  import Phoenix.ConnTest, only: [build_conn: 0]

  alias CrosswakeExample.LocalFirst.{ReviewEvent, SyncController}
  alias CrosswakeExample.Repo
  alias Crosswake.Compatibility.{RouteGate, Target}
  alias Crosswake.Manifest.Builder
  alias Crosswake.Policy.Route

  @current_scope "v1.fixture_alpha_scope_001"
  @other_scope "v1.fixture_beta_scope_0002"
  @backend_ids [
    "PI-LOGOUT-ACCOUNT-FENCE",
    "PI-ENTRY-DISABLEMENT",
    "PI-REPLAY-DISABLEMENT",
    "PI-EXACTLY-ONCE-EMPTY-OUTBOX"
  ]

  def run do
    with :ok <- reset_fixture(),
         %{effect_count: 1, idempotency_count: 1} <- accepted_replay(),
         %{effect_count: 1, idempotency_count: 1} <- duplicate_replay(),
         :ok <- reset_fixture(),
         %{retained_count: retained_rejection, halted: :rejected}
         when retained_rejection > 0 <- retained_rejection(),
         :ok <- reset_fixture(),
         %{retained_count: retained_conflict, halted: :conflict}
         when retained_conflict > 0 <- retained_conflict(),
         :ok <- reset_fixture(),
         %{retained_count: fenced, fenced: true} when fenced > 0 <- scope_fence(),
         :ok <- reset_fixture(),
         %{retained_count: logged_out, fenced: true} when logged_out > 0 <- logged_out_fence(),
         :ok <- reset_fixture(),
         %{retained_count: entry, blocked: true} when entry > 0 <- entry_disablement(),
         :ok <- reset_fixture(),
         %{retained_count: replay, blocked: true} when replay > 0 <- replay_disablement() do
      {:ok,
       %{
         "schema_version" => 1,
         "device_class" => "physical_iphone",
         "assertions" => Enum.map(@backend_ids, &%{"id" => &1, "outcome" => "passed"})
       }}
    else
      _ -> {:error, :authority_fixture_failed}
    end
  end

  def reset_fixture do
    Repo.delete_all(ReviewEvent)
    :ok
  end

  def accepted_replay do
    assert_accepted(event("selected-private"))
  end

  def duplicate_replay do
    assert_accepted(event("selected-private"))
  end

  def retained_rejection do
    insert_event("free-form-private", @current_scope, "rejected")

    case SyncController.sync_events(
           build_conn(),
           @current_scope,
           [event("free-form-private")],
           opts()
         ) do
      {:ok, %{halted: :rejected, accepted_records: []}} -> retained(:rejected)
      _ -> :error
    end
  end

  def retained_conflict do
    insert_event("fixture-conflict", @other_scope, "accepted")

    case SyncController.sync_events(
           build_conn(),
           @current_scope,
           [event("fixture-conflict")],
           opts()
         ) do
      {:ok, %{halted: :transaction_failed, accepted_records: []}} -> retained(:conflict)
      _ -> :error
    end
  end

  def scope_fence do
    insert_event("fixture-alpha", @current_scope, "accepted")

    case SyncController.sync_events(
           build_conn(),
           @current_scope,
           [event("fixture-beta")],
           opts(session_scope: @other_scope)
         ) do
      {:blocked, :scope_mismatch} -> %{retained_count: event_count(), fenced: true}
      _ -> :error
    end
  end

  def logged_out_fence do
    insert_event("fixture-alpha", @current_scope, "accepted")

    case SyncController.sync_events(
           build_conn(),
           @current_scope,
           [event("fixture-beta")],
           opts(logged_out: true)
         ) do
      {:blocked, :authority_unavailable} -> %{retained_count: event_count(), fenced: true}
      _ -> :error
    end
  end

  def entry_disablement do
    insert_event("fixture-alpha", @current_scope, "accepted")

    CrosswakeExample.RulesteadFlagSource.set_flag(:rulestead, :gated)

    manifest =
      Builder.build(
        [
          %Route{
            id: "physical-entry-gate",
            runtime: :live_view,
            offline: :unavailable,
            gated_by: :rulestead
          }
        ],
        [
          %{
            path: "/entry-gate",
            metadata: %{crosswake: [id: "physical-entry-gate"]},
            helper: "entry_gate",
            verb: :get
          }
        ]
      )

    result =
      with decision <-
             RouteGate.evaluate(manifest, "physical-entry-gate", %Target{},
               activation_source: :in_app_navigation
             ),
           true <- decision.status == :deny do
        %{retained_count: event_count(), blocked: true}
      else
        _ -> :error
      end

    CrosswakeExample.RulesteadFlagSource.delete_flag(:rulestead)
    result
  end

  def replay_disablement do
    insert_event("fixture-alpha", @current_scope, "accepted")

    case SyncController.sync_events(
           build_conn(),
           @current_scope,
           [event("fixture-beta")],
           opts(feature: :deny)
         ) do
      {:blocked, :feature_disabled} -> %{retained_count: event_count(), blocked: true}
      _ -> :error
    end
  end

  defp assert_accepted(event) do
    case SyncController.sync_events(build_conn(), @current_scope, [event], opts()) do
      {:ok, %{accepted_records: [%{outcome: :accepted}], halted: nil}} ->
        %{effect_count: event_count(), idempotency_count: event_count()}

      _ ->
        :error
    end
  end

  defp opts(overrides \\ []) do
    session_scope = Keyword.get(overrides, :session_scope, @current_scope)
    logged_out? = Keyword.get(overrides, :logged_out, false)
    feature = Keyword.get(overrides, :feature, :allow)

    [
      session: fn _ ->
        if logged_out?,
          do: {:error, :auth_required},
          else: {:ok, %{scope_ref: session_scope, auth_context: %{}}}
      end,
      route: fn _ -> {:ok, %{id: "offline-study"}} end,
      feature: fn _ -> feature end,
      sigra: fn _ -> :allow end,
      domain: fn _, _, _ -> :allow end
    ]
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
