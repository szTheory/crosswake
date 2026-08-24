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

  defp binding_opts(_ctx), do: [app_identity_ref: "com.example.crosswake"]

  defp permission_loss_opts(ctx, binding_ref) do
    [
      binding_ref: binding_ref,
      installation_ref: ctx.installation_ref,
      provider: :apns,
      platform: :ios,
      environment: :production,
      app_identity_ref: "com.example.crosswake"
    ]
  end

  test "same fingerprint refreshes its current scoped revision without creating another binding" do
    ctx = context()
    fingerprint = unique_ref("fingerprint")

    assert {:ok, %{binding: initial}} =
             Registry.bind_or_rotate(
               ctx,
               evidence(fingerprint, ctx.installation_ref),
               binding_opts(ctx)
             )

    assert {:ok, %{binding: refreshed}} =
             Registry.bind_or_rotate(
               ctx,
               evidence(fingerprint, ctx.installation_ref),
               binding_opts(ctx)
             )

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
    other_ctx = %{ctx | installation_ref: unique_ref("other_installation")}

    assert {:ok, %{binding: original}} =
             Registry.bind_or_rotate(
               ctx,
               evidence(unique_ref("fingerprint"), ctx.installation_ref),
               binding_opts(ctx)
             )

    assert {:ok, %{binding: replacement}} =
             Registry.bind_or_rotate(
               ctx,
               evidence(unique_ref("fingerprint"), ctx.installation_ref),
               binding_opts(ctx)
             )

    assert replacement.binding_ref != original.binding_ref

    assert {:ok, %{binding: unrelated}} =
             Registry.bind_or_rotate(
               other_ctx,
               evidence(unique_ref("fingerprint"), other_ctx.installation_ref),
               app_identity_ref: "com.example.crosswake.other-topic"
             )

    assert {:error, :no_active_bindings} =
             Registry.revoke_for_permission_loss(
               ctx,
               permission_loss_opts(ctx, original.binding_ref)
             )

    assert %TokenBinding{state: :active} =
             Repo.get_by!(TokenBinding, binding_ref: replacement.binding_ref)

    assert %TokenBinding{state: :active} =
             Repo.get_by!(TokenBinding, binding_ref: unrelated.binding_ref)

    assert %TokenBinding{state: :superseded} =
             Repo.get_by!(TokenBinding, binding_ref: original.binding_ref)
  end

  test "concurrent rotation and stale permission loss retain the replacement revision" do
    ctx = context()

    assert {:ok, %{binding: original}} =
             Registry.bind_or_rotate(
               ctx,
               evidence(unique_ref("fingerprint"), ctx.installation_ref),
               binding_opts(ctx)
             )

    barrier = :ets.new(:binding_race_barrier, [:set, :public])
    :ets.insert(barrier, {:ready, 0})

    results =
      [:rotate, :permission_loss]
      |> Task.async_stream(
        fn action ->
          await_barrier(barrier, 2)

          case action do
            :rotate ->
              Registry.bind_or_rotate(
                ctx,
                evidence(unique_ref("fingerprint"), ctx.installation_ref),
                binding_opts(ctx)
              )

            :permission_loss ->
              Registry.revoke_for_permission_loss(
                ctx,
                permission_loss_opts(ctx, original.binding_ref)
              )
          end
        end,
        max_concurrency: 2,
        ordered: false,
        timeout: 5_000
      )
      |> Enum.map(fn {:ok, result} -> result end)

    assert Enum.any?(results, &match?({:ok, %{binding: %{binding_ref: _}}}, &1))

    assert %TokenBinding{state: :active, binding_ref: replacement_ref} =
             Repo.one!(
               from(binding in TokenBinding,
                 where: binding.subject_ref == ^ctx.subject_ref and binding.state == :active
               )
             )

    refute replacement_ref == original.binding_ref
  end

  test "registry rejects raw token bytes before they can reach durable rows or returned facts" do
    ctx = context()
    raw_token = "raw-apns-token-#{unique_ref("secret")}"

    assert {:error, {:apns_token, :raw_token_field_forbidden}} =
             Registry.bind_or_rotate(
               ctx,
               evidence(unique_ref("fingerprint"), ctx.installation_ref, %{apns_token: raw_token}),
               binding_opts(ctx)
             )

    refute Repo.exists?(
             from(binding in TokenBinding, where: fragment("metadata LIKE ?", ^"%#{raw_token}%"))
           )
  end

  defp await_barrier(table, total) do
    :ets.update_counter(table, :ready, {2, 1})
    wait_for_barrier(table, total)
  end

  defp wait_for_barrier(table, total) do
    case :ets.lookup_element(table, :ready, 2) do
      ^total ->
        :ok

      _ ->
        Process.sleep(1)
        wait_for_barrier(table, total)
    end
  end
end
