defmodule CrosswakeExample.SaaSPortal.Approvals do
  @moduledoc """
  Server-owned approval workflow context for the AdminPilot SaaS/admin lane.

  Static account, team, member, role, settings, and broad operational records
  remain deterministic fixture data. This context persists only mutable approval
  status and approval activity evidence.
  """

  import Ecto.Query

  alias Ecto.Multi
  alias CrosswakeExample.Repo
  alias CrosswakeExample.SaaSPortal.Approval
  alias CrosswakeExample.SaaSPortal.ApprovalActivityEvent
  alias CrosswakeExample.SaaSPortal.Auth
  alias CrosswakeExample.SaaSPortal.Fixtures

  @base_requested_at ~U[2026-07-10 12:00:00Z]
  @base_activity_at ~U[2026-07-10 12:05:00Z]
  @default_route_id "saas-approval"

  def list_approvals(account_id) when is_binary(account_id) do
    Approval
    |> where([approval], approval.account_id == ^account_id)
    |> order_by([approval], asc: approval.approval_id)
    |> Repo.all()
    |> Enum.map(&approval_to_map/1)
  end

  def list_approvals(scope) when is_map(scope) do
    scope
    |> normalize_scope()
    |> Map.fetch!(:account_id)
    |> list_approvals()
  end

  def get_approval!(approval_id) when is_binary(approval_id) do
    approval_by_id(approval_id)
    |> case do
      nil ->
        raise ArgumentError, "unknown SaaS approval: #{inspect(approval_id)}"

      approval ->
        approval_to_map(approval)
    end
  end

  def get_approval!(scope, approval_id) when is_map(scope) and is_binary(approval_id) do
    case get_approval(scope, approval_id) do
      {:ok, approval} ->
        approval

      {:error, :not_found} ->
        raise ArgumentError, "unknown SaaS approval: #{inspect(approval_id)}"
    end
  end

  def get_approval(scope, approval_id) when is_map(scope) and is_binary(approval_id) do
    %{account_id: account_id} = normalize_scope(scope)

    Approval
    |> where([approval], approval.account_id == ^account_id)
    |> where([approval], approval.approval_id == ^approval_id)
    |> Repo.one()
    |> case do
      nil -> {:error, :not_found}
      approval -> {:ok, approval_to_map(approval)}
    end
  end

  def approve(%{id: approval_id}, user) when is_binary(approval_id) do
    approve_approval(
      %{
        account_id: user.account_id,
        user_id: user.id,
        role: user.role,
        route_id: @default_route_id
      },
      approval_id,
      %{}
    )
  end

  def approve(_approval, _user), do: {:error, :forbidden}

  def approve_approval(scope, approval_id) when is_binary(approval_id) do
    approve_approval(scope, approval_id, %{})
  end

  def approve_approval(scope, approval_id, metadata)
      when is_map(scope) and is_binary(approval_id) and is_map(metadata) do
    %{account_id: account_id, user_id: user_id, role: role, route_id: route_id} =
      normalize_scope(scope)

    with true <- Auth.approver?(%{role: role}),
         %Approval{} = approval <- approval_by_id(approval_id),
         true <- approval.account_id == account_id do
      persist_approval(approval, user_id, route_id, metadata)
    else
      _ -> {:error, :forbidden}
    end
  end

  def activity_events(scope) when is_map(scope) do
    %{account_id: account_id} = normalize_scope(scope)

    ApprovalActivityEvent
    |> where([event], event.account_id == ^account_id)
    |> order_by([event], asc: event.occurred_at, asc: event.event_id)
    |> Repo.all()
    |> Enum.map(&activity_to_map/1)
  end

  def activity_for_approval(approval_id) when is_binary(approval_id) do
    ApprovalActivityEvent
    |> where([event], event.approval_id == ^approval_id)
    |> order_by([event], asc: event.occurred_at, asc: event.event_id)
    |> Repo.all()
    |> Enum.map(&activity_to_map/1)
  end

  def reset! do
    fixtures = Fixtures.approvals()

    {:ok, counts} =
      Repo.transaction(fn ->
        Repo.delete_all(ApprovalActivityEvent)
        Repo.delete_all(Approval)

        fixtures
        |> Enum.with_index()
        |> Enum.each(fn {fixture, index} ->
          fixture
          |> approval_attrs(index)
          |> then(&Approval.changeset(%Approval{}, &1))
          |> Repo.insert!()

          fixture
          |> seed_activity_attrs(index)
          |> then(&ApprovalActivityEvent.changeset(%ApprovalActivityEvent{}, &1))
          |> Repo.insert!()
        end)

        %{
          approvals: length(fixtures),
          approval_activity_events: length(fixtures)
        }
      end)

    counts
  end

  def digest_components do
    [
      "saas_admin.persisted.approvals=#{Repo.aggregate(Approval, :count)}",
      "saas_admin.persisted.approval_activity_events=#{Repo.aggregate(ApprovalActivityEvent, :count)}",
      persisted_approval_components(),
      persisted_activity_components()
    ]
    |> List.flatten()
    |> Enum.sort()
  end

  defp persist_approval(%Approval{status: "approved"} = approval, _user_id, _route_id, _metadata) do
    {:ok, approval_to_map(approval)}
  end

  defp persist_approval(%Approval{} = approval, user_id, route_id, metadata) do
    occurred_at = DateTime.truncate(DateTime.utc_now(), :second)

    event_attrs = %{
      event_id: "#{approval.approval_id}-approved",
      approval_id: approval.approval_id,
      account_id: approval.account_id,
      actor_id: user_id,
      event_type: "approval_approved",
      outcome: "approved",
      route_id: route_id,
      support_ref: approval.support_ref,
      occurred_at: occurred_at,
      metadata: support_metadata(metadata)
    }

    Multi.new()
    |> Multi.update(
      :approval,
      Approval.changeset(approval, %{
        status: "approved",
        reviewed_by: user_id,
        reviewed_at: occurred_at
      })
    )
    |> Multi.insert(
      :activity,
      ApprovalActivityEvent.changeset(%ApprovalActivityEvent{}, event_attrs)
    )
    |> Repo.transaction()
    |> case do
      {:ok, %{approval: approval}} -> {:ok, approval_to_map(approval)}
      {:error, _step, _changeset, _changes} -> {:error, :invalid}
    end
  end

  defp approval_by_id(approval_id) do
    Repo.one(from(approval in Approval, where: approval.approval_id == ^approval_id))
  end

  defp approval_attrs(fixture, index) do
    requested_at = DateTime.add(@base_requested_at, index, :minute)
    reviewed_at = if fixture.reviewed_by, do: DateTime.add(requested_at, 30, :minute)

    %{
      approval_id: fixture.id,
      account_id: fixture.account_id,
      title: fixture.title,
      status: Atom.to_string(fixture.status),
      requested_by: fixture.requested_by,
      reviewed_by: fixture.reviewed_by,
      policy_id: fixture.policy_id,
      support_ref: support_ref_for(fixture),
      route_id: fixture.route_id,
      requested_at: requested_at,
      reviewed_at: reviewed_at,
      metadata: support_metadata(%{amount: fixture.amount, policy_id: fixture.policy_id})
    }
  end

  defp seed_activity_attrs(fixture, index) do
    %{
      event_id: "#{fixture.id}-seeded",
      approval_id: fixture.id,
      account_id: fixture.account_id,
      actor_id: fixture.reviewed_by || fixture.requested_by,
      event_type: "approval_seeded",
      outcome: "seeded",
      route_id: fixture.route_id,
      support_ref: support_ref_for(fixture),
      occurred_at: DateTime.add(@base_activity_at, index, :minute),
      metadata: support_metadata(%{status: fixture.status, policy_id: fixture.policy_id})
    }
  end

  defp support_ref_for(%{policy_id: policy_id}) do
    "support:adminpilot:#{policy_id}"
  end

  defp support_metadata(metadata) when is_map(metadata) do
    metadata
    |> Enum.reject(fn {key, _value} ->
      key in [:token, :session, :session_ref, :provider_payload, :secret]
    end)
    |> Map.new(fn {key, value} -> {to_string(key), stringify_metadata_value(value)} end)
  end

  defp stringify_metadata_value(value) when is_atom(value), do: Atom.to_string(value)
  defp stringify_metadata_value(value), do: value

  defp normalize_scope(%{current_saas_user: user, current_saas_account: account} = scope) do
    normalize_scope(%{
      user: user,
      account: account,
      route_id: Map.get(scope, :route_id, @default_route_id)
    })
  end

  defp normalize_scope(%{user: user, account: account} = scope) do
    %{
      account_id: account.id,
      user_id: user.id,
      role: user.role,
      route_id: Map.get(scope, :route_id, @default_route_id)
    }
  end

  defp normalize_scope(scope) when is_map(scope) do
    %{
      account_id: Map.get(scope, :account_id),
      user_id: Map.get(scope, :user_id) || Map.get(scope, :actor_id),
      role: Map.get(scope, :role),
      route_id: Map.get(scope, :route_id, @default_route_id)
    }
  end

  defp approval_to_map(%Approval{} = approval) do
    %{
      id: approval.approval_id,
      account_id: approval.account_id,
      title: approval.title,
      status: String.to_atom(approval.status),
      requested_by: approval.requested_by,
      reviewed_by: approval.reviewed_by,
      policy_id: approval.policy_id,
      support_ref: approval.support_ref,
      route_id: approval.route_id,
      requested_at: approval.requested_at,
      reviewed_at: approval.reviewed_at,
      metadata: approval.metadata || %{}
    }
  end

  defp activity_to_map(%ApprovalActivityEvent{} = event) do
    %{
      id: event.event_id,
      event_id: event.event_id,
      approval_id: event.approval_id,
      account_id: event.account_id,
      actor_id: event.actor_id,
      event_type: String.to_atom(event.event_type),
      outcome: String.to_atom(event.outcome),
      route_id: event.route_id,
      support_ref: event.support_ref,
      occurred_at: event.occurred_at,
      metadata: event.metadata || %{}
    }
  end

  defp persisted_approval_components do
    Approval
    |> order_by([approval], asc: approval.approval_id)
    |> Repo.all()
    |> Enum.map(fn approval ->
      "saas_admin.persisted.approval:#{approval.approval_id}:#{approval.status}:#{approval.reviewed_by || "pending"}"
    end)
  end

  defp persisted_activity_components do
    ApprovalActivityEvent
    |> order_by([event], asc: event.event_id)
    |> Repo.all()
    |> Enum.map(fn event ->
      "saas_admin.persisted.approval_activity:#{event.event_id}:#{event.event_type}:#{event.outcome}:#{event.actor_id}"
    end)
  end
end
