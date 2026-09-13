defmodule Crosswake.ReleaseCandidate.Receipt do
  @moduledoc false

  alias Crosswake.ReleaseCandidate.Identity

  @schema_version "1.0.0"
  @states ["READY FOR APPROVAL", "BLOCKED", "STALE", "PARTIAL", "COMPLETE"]
  @check_statuses ~w(PASS FAIL MISSING AMBIGUOUS)
  @publication_states ~w(NONE PARTIAL COMPLETE)
  @credential_states ["PROVEN", "NOT CHECKED", "DENIED"]

  @type t :: %{
          schema_version: String.t(),
          identity: %{bound: map(), observed: map()},
          checks: [map()],
          external_state: map(),
          credentials: map(),
          state: String.t(),
          next_action: String.t()
        }

  @spec build!(map()) :: t()
  def build!(input) do
    unless exact_map?(input, ~w(identity checks external_state credentials)a), do: invalid!()
    unless exact_map?(input.identity, ~w(bound observed)a), do: invalid!()

    receipt = %{
      schema_version: @schema_version,
      identity: %{
        bound: Identity.normalize!(input.identity.bound),
        observed: Identity.normalize!(input.identity.observed, consistent?: false)
      },
      checks: normalize_checks!(input.checks),
      external_state: normalize_external_state!(input.external_state),
      credentials: normalize_credentials!(input.credentials)
    }

    state = derive_state(receipt)

    receipt
    |> Map.put(:state, state)
    |> Map.put(:next_action, next_action(state))
  rescue
    KeyError -> invalid!()
  end

  @spec validate!(map()) :: map()
  def validate!(receipt) do
    unless exact_map?(
             receipt,
             ~w(schema_version identity checks external_state credentials state next_action)a
           ),
           do: invalid!()

    unless receipt.schema_version == @schema_version, do: invalid!()
    unless receipt.state in @states, do: invalid!()
    unless receipt.next_action == next_action(receipt.state), do: invalid!()

    rebuilt =
      build!(%{
        identity: receipt.identity,
        checks: receipt.checks,
        external_state: receipt.external_state,
        credentials: receipt.credentials
      })

    unless rebuilt == receipt, do: invalid!()
    receipt
  rescue
    KeyError -> invalid!()
  end

  @spec encode!(map()) :: String.t()
  def encode!(receipt) do
    receipt
    |> validate!()
    |> Jason.encode!()
  end

  @spec state?(term()) :: boolean()
  def state?(state), do: state in @states

  defp derive_state(receipt) do
    cond do
      not Identity.same?(receipt.identity.bound, receipt.identity.observed) ->
        "STALE"

      receipt.external_state.publication == "PARTIAL" ->
        "PARTIAL"

      receipt.external_state.publication == "COMPLETE" ->
        "COMPLETE"

      ready?(receipt) ->
        "READY FOR APPROVAL"

      true ->
        "BLOCKED"
    end
  end

  defp ready?(receipt) do
    Enum.all?(receipt.checks, &(&1.status == "PASS")) and
      Identity.ready?(receipt.identity.bound) and
      receipt.credentials == %{mirror_write_authority: "PROVEN", exercised: true} and
      receipt.external_state == %{
        publication: "NONE",
        successful_coordinates: [],
        failed_step: nil,
        changed: false,
        all_linked_proven: false
      }
  end

  defp normalize_checks!(checks) when is_list(checks) and checks != [] do
    normalized =
      Enum.map(checks, fn check ->
        unless exact_map?(check, ~w(id status)a), do: invalid!()
        %{id: id!(check.id), status: enum!(check.status, @check_statuses)}
      end)

    ids = Enum.map(normalized, & &1.id)
    unless Enum.uniq(ids) == ids, do: invalid!()
    Enum.sort_by(normalized, & &1.id)
  end

  defp normalize_checks!(_checks), do: invalid!()

  defp normalize_external_state!(external) do
    unless exact_map?(
             external,
             ~w(publication successful_coordinates failed_step changed all_linked_proven)a
           ),
           do: invalid!()

    normalized = %{
      publication: enum!(external.publication, @publication_states),
      successful_coordinates: normalize_coordinates!(external.successful_coordinates),
      failed_step: normalize_failed_step!(external.failed_step),
      changed: boolean!(external.changed),
      all_linked_proven: boolean!(external.all_linked_proven)
    }

    valid? =
      case normalized.publication do
        "NONE" ->
          normalized.successful_coordinates == [] and is_nil(normalized.failed_step) and
            not normalized.changed and not normalized.all_linked_proven

        "PARTIAL" ->
          normalized.successful_coordinates != [] and is_binary(normalized.failed_step) and
            normalized.changed and not normalized.all_linked_proven

        "COMPLETE" ->
          normalized.successful_coordinates != [] and is_nil(normalized.failed_step) and
            normalized.changed and normalized.all_linked_proven
      end

    if valid?, do: normalized, else: invalid!()
  end

  defp normalize_credentials!(credentials) do
    unless exact_map?(credentials, ~w(mirror_write_authority exercised)a), do: invalid!()

    normalized = %{
      mirror_write_authority: enum!(credentials.mirror_write_authority, @credential_states),
      exercised: boolean!(credentials.exercised)
    }

    if normalized.mirror_write_authority == "PROVEN" and not normalized.exercised,
      do: invalid!()

    normalized
  end

  defp normalize_coordinates!(coordinates) when is_list(coordinates) do
    normalized = Enum.map(coordinates, &coordinate!/1)
    unless Enum.uniq(normalized) == normalized, do: invalid!()
    Enum.sort(normalized)
  end

  defp normalize_coordinates!(_coordinates), do: invalid!()

  defp coordinate!(value) when is_binary(value) and byte_size(value) in 1..160 do
    if Regex.match?(~r/\A[a-z0-9._-]+:[a-z0-9._:-]+@[0-9]+\.[0-9]+\.[0-9]+\z/, value),
      do: value,
      else: invalid!()
  end

  defp coordinate!(_value), do: invalid!()

  defp normalize_failed_step!(nil), do: nil
  defp normalize_failed_step!(value), do: id!(value)

  defp id!(value) when is_binary(value) do
    if byte_size(value) in 1..80 and Regex.match?(~r/\A[a-z0-9][a-z0-9._-]*\z/, value),
      do: value,
      else: invalid!()
  end

  defp id!(_value), do: invalid!()

  defp enum!(value, allowed) do
    if value in allowed, do: value, else: invalid!()
  end

  defp boolean!(value) when is_boolean(value), do: value
  defp boolean!(_value), do: invalid!()

  defp exact_map?(value, keys) when is_map(value),
    do: Map.keys(value) |> Enum.sort() == Enum.sort(keys)

  defp exact_map?(_value, _keys), do: false

  defp next_action("READY FOR APPROVAL"), do: "approve_exact_candidate"
  defp next_action("BLOCKED"), do: "resolve_blocked_evidence"
  defp next_action("STALE"), do: "recapture_candidate"
  defp next_action("PARTIAL"), do: "recover_failed_coordinate"
  defp next_action("COMPLETE"), do: "no_action_required"

  defp invalid!, do: raise(ArgumentError, "candidate receipt input is invalid")
end
