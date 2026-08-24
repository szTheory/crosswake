defmodule CrosswakeExample.Chimeway.NotificationRegistrationAdapterTest do
  use ExUnit.Case, async: false

  import Ecto.Query

  alias CrosswakeExample.Chimeway.NotificationRegistrationAdapter
  alias CrosswakeExample.Chimeway.Registry
  alias CrosswakeExample.Chimeway.TokenBinding
  alias CrosswakeExample.Repo

  @forbidden_token "forbidden-apns-token-never-durable"

  test "a transcript stale callback is authenticated and cannot revoke a rotated or unrelated binding" do
    transcript = transcript!()
    assert swift_transcript!() == File.read!(fixture_path())
    refute String.contains?(File.read!(fixture_path()), "token")

    principal = principal(transcript)
    context = registry_context(principal)
    original = bind!(context, unique("fingerprint-a"))
    replacement = bind!(context, unique("fingerprint-b"))
    unrelated_context = registry_context(%{principal | installation_ref: unique("other-installation")})
    unrelated = bind!(unrelated_context, unique("unrelated-fingerprint"))

    assert {:ok, :stale_noop} =
             NotificationRegistrationAdapter.revoke_for_permission_loss(principal, transcript["command"])

    assert %TokenBinding{state: :active} = Repo.get_by!(TokenBinding, binding_ref: replacement.binding_ref)
    assert %TokenBinding{state: :active} = Repo.get_by!(TokenBinding, binding_ref: unrelated.binding_ref)
    assert %TokenBinding{state: :superseded} = Repo.get_by!(TokenBinding, binding_ref: original.binding_ref)

    evidence = %{adapter_result: :stale_noop, binding_refs: [replacement.binding_ref, unrelated.binding_ref]}
    refute inspect(evidence) =~ @forbidden_token
    refute Repo.exists?(from(binding in TokenBinding, where: fragment("metadata LIKE ?", ^"%#{@forbidden_token}%")))
  end

  test "rejects a callback whose authenticated session scope does not match" do
    transcript = transcript!()
    principal = principal(transcript)

    assert {:error, :scope_mismatch} =
             NotificationRegistrationAdapter.revoke_for_permission_loss(
               %{principal | session_version: principal.session_version + 1},
               transcript["command"]
             )
  end

  defp bind!(context, fingerprint) do
    assert {:ok, %{binding: binding}} =
             Registry.bind_or_rotate(
               context,
               %{
                 token_ref: unique("opaque-token-ref"),
                 token_fingerprint: fingerprint,
                 provider: :apns,
                 platform: :ios,
                 environment: :sandbox,
                 installation_ref: context.installation_ref,
                 notification_status: :granted,
                 observed_at: "2026-08-24T12:00:00Z",
                 metadata: %{}
               },
               app_identity_ref: context.topic
             )

    binding
  end

  defp principal(transcript) do
    scope = transcript["scope"]

    %{
      subject_ref: scope["subject_ref"], org_ref: scope["tenant_ref"],
      installation_ref: scope["installation_ref"], provider: scope["provider"],
      environment: scope["environment"], topic: scope["topic"],
      session_ref: scope["session_ref"], session_version: String.to_integer(scope["session_version"]),
      channel: scope["channel"], authenticated?: true
    }
  end

  defp registry_context(principal), do: Map.merge(principal, %{subject_scope: :subject_session, actor_kind: :backend, correlation_id: unique("correlation")})
  defp transcript!, do: fixture_path() |> File.read!() |> Jason.decode!()
  defp fixture_path, do: Path.expand("../../../../../test/fixtures/chimeway_notification_permission_loss_v1.json", __DIR__)
  defp swift_transcript!, do: Path.expand("../../../../../packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/Resources/chimeway_notification_permission_loss_v1.json", __DIR__) |> File.read!()
  defp unique(prefix), do: "#{prefix}-#{System.unique_integer([:positive])}"
end
