defmodule CrosswakeExample.Chimeway.RegistryTest do
  use ExUnit.Case, async: false

  alias CrosswakeExample.Chimeway.Registry
  alias CrosswakeExample.Chimeway.TokenBinding
  alias CrosswakeExample.Repo
  import Ecto.Query

  defp unique_ref(prefix),
    do: "#{prefix}_#{System.system_time(:nanosecond)}_#{System.unique_integer([:positive])}"

  defp context(overrides \\ %{}) do
    Map.merge(
      %{
        subject_scope: :subject_session,
        subject_ref: unique_ref("subject"),
        org_ref: unique_ref("org"),
        installation_ref: unique_ref("installation"),
        session_ref: unique_ref("session"),
        session_version: 1,
        actor_kind: :backend,
        correlation_id: unique_ref("correlation")
      },
      overrides
    )
  end

  defp evidence(fingerprint, installation_ref, overrides \\ %{}) do
    Map.merge(
      %{
        token_ref: unique_ref("token_ref"),
        token_fingerprint: fingerprint,
        provider: :apns,
        platform: :ios,
        environment: :production,
        installation_ref: installation_ref,
        notification_status: :granted,
        observed_at: "2026-08-24T12:00:00Z",
        metadata: %{}
      },
      overrides
    )
  end

  test "same fingerprint refreshes its current scoped revision without creating another binding" do
    ctx = context()
    fingerprint = unique_ref("fingerprint")

    assert {:ok, %{binding: initial}} = Registry.bind_or_rotate(ctx, evidence(fingerprint, ctx.installation_ref))

    assert {:ok, %{binding: refreshed}} =
             Registry.bind_or_rotate(ctx, evidence(fingerprint, ctx.installation_ref))

    assert refreshed.binding_ref == initial.binding_ref
    assert refreshed.last_seen_at >= initial.last_seen_at

    assert 1 ==
             Repo.aggregate(
               from(binding in TokenBinding,
                 where: binding.binding_ref == ^initial.binding_ref and binding.state == :active
               ),
               :count
             )
  end

  test "stale permission loss only revokes the observed scoped revision after rotation" do
    ctx = context()

    assert {:ok, %{binding: original}} =
             Registry.bind_or_rotate(ctx, evidence(unique_ref("fingerprint"), ctx.installation_ref))

    assert {:ok, %{binding: replacement}} =
             Registry.bind_or_rotate(ctx, evidence(unique_ref("fingerprint"), ctx.installation_ref))

    assert replacement.binding_ref != original.binding_ref
    assert {:error, :no_active_bindings} =
             Registry.revoke_for_permission_loss(ctx, binding_ref: original.binding_ref)

    assert %TokenBinding{state: :active} = Repo.get_by!(TokenBinding, binding_ref: replacement.binding_ref)
    assert %TokenBinding{state: :superseded} = Repo.get_by!(TokenBinding, binding_ref: original.binding_ref)
  end

  test "registry rejects raw token bytes before they can reach durable rows or returned facts" do
    ctx = context()
    raw_token = "raw-apns-token-#{unique_ref("secret")}" 

    assert {:error, {:apns_token, :raw_token_field_forbidden}} =
             Registry.bind_or_rotate(
               ctx,
               evidence(unique_ref("fingerprint"), ctx.installation_ref, %{apns_token: raw_token})
             )

    refute Repo.exists?(from(binding in TokenBinding, where: fragment("metadata LIKE ?", ^"%#{raw_token}%")))
  end
end
