defmodule CrosswakeExample.Chimeway.NotificationRegistrationAdapter do
  @moduledoc """
  Authenticated host boundary for native notification permission-loss callbacks.

  The command is deliberately closed: it contains the exact opaque binding
  revision plus the full authenticated authority scope, never APNs token bytes.
  A stale native callback is normal after rotation and is reported as a safe
  no-op rather than broadening the revocation target.
  """

  alias CrosswakeExample.Chimeway.Registry

  @command_keys ~w(binding_ref tenant_ref subject_ref installation_ref provider environment topic session_ref session_version channel)

  @spec revoke_for_permission_loss(map(), map()) :: {:ok, :revoked | :stale_noop} | {:error, :invalid_command | :scope_mismatch | term()}
  def revoke_for_permission_loss(%{authenticated?: true} = principal, command) when is_map(command) do
    with :ok <- closed_command?(command),
         {:ok, normalized} <- normalize_command(command),
         :ok <- principal_matches?(principal, normalized) do
      context = %{
        subject_scope: :subject_session,
        subject_ref: normalized.subject_ref,
        org_ref: normalized.tenant_ref,
        installation_ref: normalized.installation_ref,
        session_ref: normalized.session_ref,
        session_version: normalized.session_version,
        actor_kind: :backend
      }

      opts = [
        binding_ref: normalized.binding_ref,
        installation_ref: normalized.installation_ref,
        provider: normalized.provider,
        platform: :ios,
        environment: normalized.environment,
        app_identity_ref: normalized.topic
      ]

      case Registry.revoke_for_permission_loss(context, opts) do
        {:ok, _result} -> {:ok, :revoked}
        {:error, :no_active_bindings} -> {:ok, :stale_noop}
        {:error, reason} -> {:error, reason}
      end
    end
  end

  def revoke_for_permission_loss(_principal, _command), do: {:error, :scope_mismatch}

  defp closed_command?(command) do
    if Map.keys(command) |> Enum.sort() == Enum.sort(@command_keys), do: :ok, else: {:error, :invalid_command}
  end

  defp normalize_command(command) do
    with {:ok, binding_ref} <- required(command, "binding_ref"),
         {:ok, tenant_ref} <- required(command, "tenant_ref"),
         {:ok, subject_ref} <- required(command, "subject_ref"),
         {:ok, installation_ref} <- required(command, "installation_ref"),
         {:ok, session_ref} <- required(command, "session_ref"),
         {:ok, topic} <- required(command, "topic"),
         {:ok, "push"} <- required(command, "channel"),
         {:ok, provider} <- atom_value(command, "provider", %{"apns" => :apns}),
         {:ok, environment} <- atom_value(command, "environment", %{"sandbox" => :sandbox, "production" => :production}),
         {:ok, session_version} <- integer_value(command, "session_version") do
      {:ok, %{binding_ref: binding_ref, tenant_ref: tenant_ref, subject_ref: subject_ref, installation_ref: installation_ref, session_ref: session_ref, session_version: session_version, topic: topic, provider: provider, environment: environment}}
    else
      _ -> {:error, :invalid_command}
    end
  end

  defp principal_matches?(principal, command) do
    expected = %{
      subject_ref: command.subject_ref, org_ref: command.tenant_ref,
      installation_ref: command.installation_ref, provider: Atom.to_string(command.provider),
      environment: Atom.to_string(command.environment), topic: command.topic,
      session_ref: command.session_ref, session_version: command.session_version, channel: "push"
    }

    if Enum.all?(expected, fn {key, value} -> Map.get(principal, key) == value end), do: :ok, else: {:error, :scope_mismatch}
  end

  defp required(map, key) do
    case Map.get(map, key) do
      value when is_binary(value) and byte_size(value) > 0 -> {:ok, value}
      _ -> {:error, :invalid}
    end
  end

  defp atom_value(map, key, allowed) do
    with {:ok, value} <- required(map, key), {:ok, atom} <- Map.fetch(allowed, value), do: {:ok, atom}
  end

  defp integer_value(map, key) do
    with {:ok, value} <- required(map, key), {integer, ""} when integer >= 0 <- Integer.parse(value), do: {:ok, integer}
  end
end
