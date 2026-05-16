defmodule Crosswake.Packs.Runtime do
  @moduledoc """
  Derives fail-closed lifecycle state from manifest pack references and installed inventory.
  """

  alias Crosswake.Packs.Contracts
  alias Crosswake.Packs.Inventory

  @spec lifecycle(String.t(), Inventory.t() | String.t() | nil) :: Contracts.t()
  def lifecycle(pack_reference, nil) when is_binary(pack_reference) do
    {pack_id, required_version} = parse_reference(pack_reference)
    Contracts.not_installed(pack_id: pack_id, required_version: required_version)
  end

  def lifecycle(pack_reference, installed_version) when is_binary(installed_version) do
    {pack_id, required_version} = parse_reference(pack_reference)

    if compatible?(installed_version, required_version) do
      Contracts.available(
        pack_id: pack_id,
        required_version: required_version,
        installed_version: installed_version,
        bytes: 0,
        integrity_status: :verified,
        verified_at: nil
      )
    else
      Contracts.stale(
        pack_id: pack_id,
        required_version: required_version,
        installed_version: installed_version,
        bytes: 0,
        integrity_status: :verified,
        verified_at: nil,
        stale_reason: :version_mismatch
      )
    end
  end

  def lifecycle(pack_reference, %Inventory{} = record) do
    {pack_id, required_version} = parse_reference(pack_reference)

    cond do
      record.status == :invalidating ->
        Contracts.from_inventory(record)
        |> Contracts.invalidate(
          reason: record.invalidation_reason || :invalidated,
          invalidated_at: record.invalidated_at || DateTime.utc_now() |> DateTime.truncate(:second)
        )
        |> Map.put(:last_known_state, record.last_known_state || %{state: :available, version: record.installed_version})

      record.integrity_status != :verified or is_nil(record.verified_at) ->
        Contracts.failed(
          pack_id: pack_id,
          required_version: required_version,
          failure_reason: :verification_missing,
          retry_hint: :retry
        )

      compatible?(record.installed_version, required_version) ->
        Contracts.available(
          pack_id: pack_id,
          required_version: required_version,
          installed_version: record.installed_version,
          bytes: record.bytes,
          integrity_status: record.integrity_status,
          verified_at: record.verified_at
        )

      true ->
        Contracts.stale(
          pack_id: pack_id,
          required_version: required_version,
          installed_version: record.installed_version,
          bytes: record.bytes,
          integrity_status: record.integrity_status,
          verified_at: record.verified_at,
          stale_reason: :version_mismatch
        )
    end
  end

  @spec available?(Contracts.t()) :: boolean()
  def available?(%Contracts{state: :available}), do: true
  def available?(_other), do: false

  @spec stale?(Contracts.t()) :: boolean()
  def stale?(%Contracts{state: :stale}), do: true
  def stale?(_other), do: false

  @spec failure_reason(Contracts.t()) :: atom() | nil
  def failure_reason(%Contracts{failure: %{reason: reason}}), do: reason
  def failure_reason(_other), do: nil

  defp parse_reference(pack_reference) do
    case String.split(pack_reference, "@", parts: 2) do
      [pack_id, version] -> {pack_id, version}
      [pack_id] -> {pack_id, nil}
    end
  end

  defp compatible?(available, required) when is_binary(available) and is_binary(required) do
    case {normalize_version(available), normalize_version(required)} do
      {{:ok, normalized_available}, {:ok, normalized_required}} ->
        Version.compare(normalized_available, normalized_required) != :lt

      _other ->
        available == required
    end
  end

  defp compatible?(_available, _required), do: false

  defp normalize_version(value) do
    parts = String.split(value, ".")

    normalized =
      case parts do
        [major] -> "#{major}.0.0"
        [major, minor] -> "#{major}.#{minor}.0"
        [_, _, _] -> value
        _other -> value
      end

    Version.parse(normalized)
  end
end
