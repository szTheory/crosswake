defmodule Crosswake.Companions.Sigra.Evaluator do
  @moduledoc """
  Pure Sigra route-auth evaluator for backend-owned session authority.

  The evaluator is intentionally transport-agnostic. It does not issue step-up
  intents, renew Phoenix sessions, halt LiveViews, or validate provider returns.
  """

  alias Crosswake.Companions.Sigra.Contracts
  alias Crosswake.Companions.Sigra.Contracts.AuthContext
  alias Crosswake.Companions.Sigra.Contracts.SessionAuthorityLane
  alias Crosswake.Companions.Sigra.DenialCodes
  alias Crosswake.Manifest.Types.RouteEntry
  alias Crosswake.Shell.Denial

  @generic_message "route requires stronger or fresher backend authentication context"

  defmodule Result do
    @moduledoc false
    defstruct [:status, :denial, facts: %{}]
  end

  @spec evaluate_route_auth(RouteEntry.t() | nil, AuthContext.t() | nil, keyword()) ::
          {:allow, Result.t()} | {:deny, Denial.t()}
  def evaluate_route_auth(route, auth_context, opts \\ [])

  def evaluate_route_auth(nil, _auth_context, _opts), do: {:allow, %Result{status: :allow}}

  def evaluate_route_auth(%RouteEntry{} = route, auth_context, opts) do
    if auth_predicated?(route) do
      route
      |> evaluate_predicated_route(auth_context, opts)
    else
      {:allow, %Result{status: :allow, facts: %{auth_posture: route.auth_posture}}}
    end
  end

  defp evaluate_predicated_route(route, nil, opts),
    do: deny(route, "auth.step_up.missing_context", %{}, opts)

  defp evaluate_predicated_route(route, %AuthContext{} = auth_context, opts) do
    case Contracts.validate_auth_context(auth_context) do
      :ok -> evaluate_valid_context(route, auth_context, opts)
      {:error, _errors} -> deny(route, "auth.step_up.invalid_context", %{}, opts)
    end
  end

  defp evaluate_predicated_route(route, _auth_context, opts),
    do: deny(route, "auth.step_up.invalid_context", %{}, opts)

  defp evaluate_valid_context(route, %AuthContext{} = auth_context, opts) do
    checks = [
      fn -> check_lane_state(route, auth_context, opts) end,
      fn -> check_lane_expiry(route, auth_context, opts) end,
      fn -> check_session_version(route, auth_context, opts) end,
      fn -> check_remembered_cached(route, auth_context, opts) end
    ]

    case Enum.find_value(checks, fn check -> check.() end) do
      nil ->
        evaluate_assurance_and_freshness(route, auth_context, opts)

      {:deny, code, details} ->
        deny(route, code, details, opts)
    end
  end

  defp check_lane_state(_route, %AuthContext{session_authority_lane: nil}, _opts), do: nil

  defp check_lane_state(
         _route,
         %AuthContext{session_authority_lane: %SessionAuthorityLane{} = lane},
         _opts
       ) do
    cond do
      lane.state == :revoked or not is_nil(lane.revoked_at) ->
        {:deny, "auth.step_up.revoked", %{authority_state: :revoked}}

      lane.state == :expired ->
        {:deny, "auth.step_up.non_active", %{authority_state: :expired}}

      lane.state != :active ->
        {:deny, "auth.step_up.non_active", %{authority_state: lane.state}}

      true ->
        nil
    end
  end

  defp check_lane_expiry(_route, %AuthContext{session_authority_lane: nil}, _opts), do: nil

  defp check_lane_expiry(
         _route,
         %AuthContext{session_authority_lane: %SessionAuthorityLane{} = lane},
         _opts
       ) do
    as_of = lane.as_of

    cond do
      Contracts.timestamp_before_or_equal?(lane.idle_expires_at, as_of) ->
        {:deny, "auth.step_up.idle_expired", %{authority_state: lane.state}}

      Contracts.timestamp_before_or_equal?(lane.absolute_expires_at, as_of) ->
        {:deny, "auth.step_up.absolute_expired", %{authority_state: lane.state}}

      true ->
        nil
    end
  end

  defp check_session_version(_route, %AuthContext{session_authority_lane: nil}, _opts), do: nil

  defp check_session_version(
         _route,
         %AuthContext{session_authority_lane: %SessionAuthorityLane{} = lane},
         opts
       ) do
    expected = Keyword.get(opts, :expected_session_version)

    if is_integer(expected) and lane.session_version != expected do
      {:deny, "auth.step_up.version_mismatch",
       %{expected_session_version: expected, current_session_version: lane.session_version}}
    end
  end

  defp check_remembered_cached(
         %RouteEntry{} = route,
         %AuthContext{session_authority_lane: nil},
         _opts
       ) do
    if route.auth_posture == :cached_read_only_ok do
      {:deny, "auth.step_up.cached_not_allowed", %{auth_posture: route.auth_posture}}
    end
  end

  defp check_remembered_cached(
         %RouteEntry{} = route,
         %AuthContext{session_authority_lane: %SessionAuthorityLane{} = lane},
         _opts
       ) do
    cond do
      lane.cached and route.auth_posture != :cached_read_only_ok ->
        {:deny, "auth.step_up.cached_not_allowed", %{auth_posture: route.auth_posture}}

      lane.remembered and route.auth_posture != :remembered_ok ->
        {:deny, "auth.step_up.remembered_not_allowed", %{auth_posture: route.auth_posture}}

      true ->
        nil
    end
  end

  defp check_assurance(%RouteEntry{auth_min_level: nil}, _auth_context, _opts), do: nil

  defp check_assurance(
         %RouteEntry{auth_min_level: required} = route,
         %AuthContext{} = auth_context,
         _opts
       ) do
    current = assurance_level(auth_context)

    unless Contracts.assurance_level_meets?(current, required) do
      {:deny, "auth.step_up.insufficient_assurance",
       auth_assurance_details(route, auth_context, required, current)}
    end
  end

  defp check_recent_auth(%RouteEntry{requires_recent_auth: nil}, _auth_context, _opts), do: nil

  defp check_recent_auth(
         %RouteEntry{requires_recent_auth: max_age} = route,
         %AuthContext{} = auth_context,
         _opts
       ) do
    age = Contracts.auth_age_seconds(auth_context)

    if age > max_age do
      {:deny, "auth.step_up.stale_auth",
       auth_freshness_details(route, auth_context, max_age, age)}
    end
  end

  defp auth_assurance_details(
         route,
         %AuthContext{session_authority_lane: %SessionAuthorityLane{}},
         required,
         current
       ) do
    %{
      required_assurance_level: required,
      current_assurance_level: current,
      required_mfa_level: required,
      current_mfa_level: current,
      auth_posture: route.auth_posture
    }
  end

  defp auth_assurance_details(_route, %AuthContext{}, required, current) do
    %{required_mfa_level: required, current_mfa_level: current}
  end

  defp auth_freshness_details(
         route,
         %AuthContext{session_authority_lane: %SessionAuthorityLane{}},
         max_age,
         age
       ) do
    %{max_auth_age_seconds: max_age, auth_age_seconds: age, auth_posture: route.auth_posture}
  end

  defp auth_freshness_details(_route, %AuthContext{}, max_age, age) do
    %{max_auth_age_seconds: max_age, auth_age_seconds: age}
  end

  defp evaluate_assurance_and_freshness(route, auth_context, opts) do
    failures =
      [check_assurance(route, auth_context, opts), check_recent_auth(route, auth_context, opts)]
      |> Enum.reject(&is_nil/1)

    case failures do
      [] ->
        {:allow,
         %Result{
           status: :allow,
           facts: %{
             auth_posture: route.auth_posture,
             authority_state: authority_state(auth_context)
           }
         }}

      [{:deny, code, details} | rest] ->
        merged_details =
          Enum.reduce(rest, details, fn {:deny, _code, more_details}, acc ->
            Map.merge(acc, more_details)
          end)

        deny(route, code, merged_details, opts)
    end
  end

  defp deny(%RouteEntry{} = route, code, details, opts) do
    sanitized =
      details
      |> Map.put_new(
        :evaluated_at,
        DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()
      )
      |> maybe_put_ref(:challenge_ref, Keyword.get(opts, :challenge_ref))
      |> maybe_put_ref(:step_up_token_ref, Keyword.get(opts, :step_up_token_ref))
      |> DenialCodes.sanitize_details()

    {:deny,
     Denial.new(
       reason: :step_up_required,
       code: code,
       message: @generic_message,
       route_id: route.id,
       details: sanitized
     )}
  end

  defp maybe_put_ref(details, _key, nil), do: details
  defp maybe_put_ref(details, key, value), do: Map.put(details, key, value)

  defp auth_predicated?(%RouteEntry{} = route) do
    not is_nil(route.auth_min_level) or not is_nil(route.requires_recent_auth) or
      not is_nil(route.auth_posture)
  end

  defp assurance_level(%AuthContext{session_authority_lane: %SessionAuthorityLane{} = lane}),
    do: lane.assurance_level

  defp assurance_level(%AuthContext{mfa_level: level}), do: level

  defp authority_state(%AuthContext{session_authority_lane: %SessionAuthorityLane{} = lane}),
    do: lane.state

  defp authority_state(_auth_context), do: nil
end
