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

  test "concurrent differing-posture observations converge on one active authority binding" do
    ctx = context()
    fingerprint = unique_ref("fingerprint")
    barrier = :ets.new(:posture_binding_race_barrier, [:set, :public])
    :ets.insert(barrier, {:ready, 0})

    results =
      [:matched, :unknown]
      |> Task.async_stream(
        fn posture ->
          await_barrier(barrier, 2)

          Registry.bind_or_rotate(
            ctx,
            evidence(fingerprint, ctx.installation_ref, %{app_identity_posture: posture}),
            binding_opts(ctx)
          )
        end,
        max_concurrency: 2,
        ordered: false,
        timeout: 5_000
      )
      |> Enum.map(fn {:ok, result} -> result end)

    assert Enum.all?(results, &match?({:ok, %{binding: %{binding_ref: _}}}, &1))

    binding_refs =
      Enum.map(results, fn {:ok, %{binding: binding}} -> binding.binding_ref end)

    assert Enum.uniq(binding_refs) |> length() == 1

    assert 1 ==
             Repo.aggregate(
               from(binding in TokenBinding,
                 where:
                   binding.subject_ref == ^ctx.subject_ref and
                     binding.org_ref == ^ctx.org_ref and
                     binding.installation_ref == ^ctx.installation_ref and
                     binding.state == :active
               ),
               :count
             )
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

  test "invalidating provider feedback only mutates its authenticated exact binding scope" do
    fingerprint = unique_ref("shared_fingerprint")
    ctx = context()

    assert {:ok, %{binding: target}} =
             Registry.bind_or_rotate(
               ctx,
               evidence(fingerprint, ctx.installation_ref, %{token_ref: "shared-token"}),
               app_identity_ref: "com.example.crosswake.target"
             )

    other_ctx =
      context(%{
        subject_ref: unique_ref("other_subject"),
        org_ref: unique_ref("other_org"),
        installation_ref: unique_ref("other_installation"),
        session_ref: unique_ref("other_session"),
        session_version: 2
      })

    assert {:ok, %{binding: other}} =
             Registry.bind_or_rotate(
               other_ctx,
               evidence(fingerprint, other_ctx.installation_ref, %{token_ref: "shared-token"}),
               app_identity_ref: "com.example.crosswake.other"
             )

    feedback = %Crosswake.Companions.Chimeway.Contracts.ProviderFeedback{
      provider: :apns,
      platform: :ios,
      environment: :production,
      feedback_event: :token_unregistered,
      occurred_at: "2026-08-24T12:00:00Z",
      token_ref: "shared-token",
      token_fingerprint: fingerprint
    }

    scope = [
      authenticated_context: ctx,
      binding_ref: target.binding_ref,
      app_identity_ref: "com.example.crosswake.target",
      installation_ref: ctx.installation_ref,
      session_ref: ctx.session_ref,
      session_version: ctx.session_version
    ]

    assert {:ok, %{bindings: [revoked]}} = Registry.apply_provider_feedback(feedback, scope)
    assert revoked.binding_ref == target.binding_ref

    assert %TokenBinding{state: :revoked} =
             Repo.get_by!(TokenBinding, binding_ref: target.binding_ref)

    assert %TokenBinding{state: :active} =
             Repo.get_by!(TokenBinding, binding_ref: other.binding_ref)

    assert {:error, :no_active_bindings} = Registry.apply_provider_feedback(feedback, [])

    assert %TokenBinding{state: :active} =
             Repo.get_by!(TokenBinding, binding_ref: other.binding_ref)
  end

  test "installation-scoped provider feedback revokes only its exact binding without session authority" do
    fingerprint = unique_ref("installation_fingerprint")

    installation_ctx =
      context(%{
        subject_scope: :subject_installation,
        session_ref: nil,
        session_version: nil
      })

    session_ctx = context(%{installation_ref: installation_ctx.installation_ref})

    other_installation_ctx =
      context(%{subject_scope: :subject_installation, session_ref: nil, session_version: nil})

    now = DateTime.utc_now() |> DateTime.truncate(:second)

    target =
      Repo.insert!(%TokenBinding{
        binding_ref: unique_ref("installation_binding"),
        subject_scope: :subject_installation,
        subject_ref: installation_ctx.subject_ref,
        org_ref: installation_ctx.org_ref,
        session_ref: nil,
        session_version: nil,
        installation_ref: installation_ctx.installation_ref,
        provider: :apns,
        platform: :ios,
        environment: :production,
        app_identity_posture: :unknown,
        app_identity_ref: "com.example.crosswake.installation",
        token_ref: unique_ref("installation_token"),
        token_fingerprint: fingerprint,
        notification_status: :granted,
        state: :active,
        reason: :initial_bind,
        audit_correlation_ref: unique_ref("installation_correlation"),
        bound_at: now,
        last_seen_at: now
      })

    assert {:ok, %{binding: session_control}} =
             Registry.bind_or_rotate(
               session_ctx,
               evidence(unique_ref("session_control"), session_ctx.installation_ref),
               app_identity_ref: "com.example.crosswake.session-control"
             )

    other_installation_control =
      Repo.insert!(%TokenBinding{
        binding_ref: unique_ref("other_installation_binding"),
        subject_scope: :subject_installation,
        subject_ref: other_installation_ctx.subject_ref,
        org_ref: other_installation_ctx.org_ref,
        session_ref: nil,
        session_version: nil,
        installation_ref: other_installation_ctx.installation_ref,
        provider: :apns,
        platform: :ios,
        environment: :production,
        app_identity_posture: :unknown,
        app_identity_ref: "com.example.crosswake.other-installation",
        token_ref: unique_ref("other_installation_token"),
        token_fingerprint: unique_ref("other_installation_fingerprint"),
        notification_status: :granted,
        state: :active,
        reason: :initial_bind,
        audit_correlation_ref: unique_ref("other_installation_correlation"),
        bound_at: now,
        last_seen_at: now
      })

    feedback = %Crosswake.Companions.Chimeway.Contracts.ProviderFeedback{
      provider: :apns,
      platform: :ios,
      environment: :production,
      feedback_event: :token_unregistered,
      occurred_at: "2026-08-24T12:00:00Z",
      token_fingerprint: fingerprint
    }

    assert {:ok, %{bindings: [revoked]}} =
             Registry.apply_provider_feedback(feedback,
               authenticated_context: installation_ctx,
               binding_ref: target.binding_ref,
               installation_ref: installation_ctx.installation_ref,
               app_identity_ref: "com.example.crosswake.installation"
             )

    assert revoked.binding_ref == target.binding_ref

    assert %TokenBinding{state: :revoked} =
             Repo.get_by!(TokenBinding, binding_ref: target.binding_ref)

    assert %TokenBinding{state: :active} =
             Repo.get_by!(TokenBinding, binding_ref: session_control.binding_ref)

    assert %TokenBinding{state: :active} =
             Repo.get_by!(TokenBinding, binding_ref: other_installation_control.binding_ref)
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
