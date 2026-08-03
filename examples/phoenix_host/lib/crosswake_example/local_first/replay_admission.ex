defmodule CrosswakeExample.LocalFirst.ReplayAdmission do
  @moduledoc false

  # This example host deliberately keeps current authority in host callbacks.  The
  # browser supplies an opaque scope reference only; it cannot turn that reference
  # into a session, route, feature, or domain allow decision.
  @max_events 20
  @event_keys ["card_id", "client_mutation_id", "rating"]
  @scope_ref_pattern ~r/\Av[1-9][0-9]*\.[A-Za-z0-9_-]{16,128}\z/

  alias Crosswake.Companions.Sigra.Contracts
  alias Crosswake.Manifest.Types.RouteEntry

  @type decision :: {:allow, map()} | {:deny, atom()}

  @spec authorize(Plug.Conn.t(), String.t(), map(), keyword()) :: decision()
  def authorize(conn, scope_ref, event, opts \\ [])

  def authorize(conn, scope_ref, event, opts)
      when is_binary(scope_ref) and is_map(event) and is_list(opts) do
    with :ok <- valid_scope(scope_ref),
         :ok <- valid_event(event),
         {:ok, session} <- resolve(:session, conn, opts),
         :ok <- matching_scope(session, scope_ref),
         {:ok, route} <- resolve(:route, conn, opts),
         :ok <- enabled?(route, conn, opts),
         :ok <- sigra_allows?(route, session, opts),
         :ok <- domain_allows?(route, session, event, opts) do
      {:allow, %{route: route}}
    else
      {:error, reason} -> {:deny, closed_reason(reason)}
      _ -> {:deny, :authority_unavailable}
    end
  rescue
    _ -> {:deny, :authority_unavailable}
  catch
    :exit, _ -> {:deny, :authority_unavailable}
    :throw, _ -> {:deny, :authority_unavailable}
  end

  def authorize(_conn, _scope_ref, _event, _opts), do: {:deny, :invalid_envelope}

  @spec valid_batch?(term()) :: boolean()
  def valid_batch?(events) when is_list(events),
    do: events != [] and length(events) <= @max_events

  def valid_batch?(_), do: false

  defp valid_scope(scope_ref) when is_binary(scope_ref) do
    if Regex.match?(@scope_ref_pattern, scope_ref), do: :ok, else: {:error, :invalid_envelope}
  end

  defp valid_scope(_), do: {:error, :invalid_envelope}

  defp valid_event(event) when is_map(event) do
    if Enum.sort(Map.keys(event)) == @event_keys do
      valid_event_fields(event)
    else
      {:error, :invalid_envelope}
    end
  end

  defp valid_event(_), do: {:error, :invalid_envelope}

  defp valid_event_fields(%{"client_mutation_id" => id, "card_id" => card, "rating" => rating})
       when is_binary(id) and byte_size(id) in 1..120 and is_integer(card) and card > 0 and
              rating in ["good", "hard"],
       do: :ok

  defp valid_event_fields(_), do: {:error, :invalid_envelope}

  defp resolve(name, conn, opts) do
    case Keyword.get(opts, name) do
      fun when is_function(fun, 1) -> normalize_callback(fun.(conn))
      fun when is_function(fun, 0) -> normalize_callback(fun.())
      _ -> default_resolution(name, conn)
    end
  rescue
    _ -> {:error, :authority_unavailable}
  catch
    :exit, _ -> {:error, :authority_unavailable}
  end

  defp normalize_callback({:ok, value}), do: {:ok, value}
  defp normalize_callback(_), do: {:error, :authority_unavailable}

  # Synthetic example-host fixture, deliberately server configured.  It is not a
  # customer route, account lookup, credential, or production session system.
  defp default_resolution(:session, _conn) do
    with {:ok, auth_context} <- default_sigra_auth_context() do
      {:ok,
       %{
         scope_ref:
           Application.get_env(
             :crosswake_example,
             :offline_study_fixture_scope,
             "v1.scope_fixture_alpha_01"
           ),
         auth_context: auth_context
       }}
    end
  end

  defp default_resolution(:route, _conn) do
    {:ok,
     %RouteEntry{
       id: "offline-study",
       path: "/study",
       runtime: :offline_island,
       offline: :local_first,
       gated_by: :offline_study_replay,
       auth_min_level:
         Application.get_env(:crosswake_example, :offline_study_fixture_auth_min_level),
       requires_recent_auth:
         Application.get_env(:crosswake_example, :offline_study_fixture_requires_recent_auth),
       auth_posture: Application.get_env(:crosswake_example, :offline_study_fixture_auth_posture)
     }}
  end

  defp default_sigra_auth_context do
    Application.get_env(
      :crosswake_example,
      :offline_study_fixture_auth_context,
      %{actor_id: "fixture_actor", org_id: "fixture_org", mfa_level: :mfa, auth_age: 0}
    )
    |> Contracts.new_auth_context()
  end

  defp matching_scope(%{scope_ref: scope_ref}, scope_ref), do: :ok
  defp matching_scope(_, _), do: {:error, :scope_mismatch}

  defp enabled?(route, conn, opts) do
    callback = Keyword.get(opts, :feature)

    result =
      cond do
        is_function(callback, 2) -> callback.(route, conn)
        is_function(callback, 1) -> callback.(route)
        true -> Application.get_env(:crosswake_example, :offline_study_replay_enabled, true)
      end

    if result == :allow or result == true, do: :ok, else: {:error, :feature_disabled}
  rescue
    _ -> {:error, :authority_unavailable}
  end

  defp sigra_allows?(route, session, opts) do
    callback = Keyword.get(opts, :sigra)

    result =
      cond do
        is_function(callback, 2) ->
          callback.(route, session)

        is_function(callback, 1) ->
          callback.(session)

        true ->
          case session do
            %{auth_context: auth_context} ->
              Crosswake.Companions.Sigra.replay_decision(route, auth_context, [])

            _ ->
              {:deny, :sigra_denied}
          end
      end

    if result in [:allow, {:allow, :allowed}], do: :ok, else: {:error, :sigra_denied}
  rescue
    _ -> {:error, :sigra_denied}
  end

  defp domain_allows?(route, session, event, opts) do
    callback = Keyword.get(opts, :domain)

    result =
      if is_function(callback, 3), do: callback.(route, session, event), else: :allow

    if result == :allow, do: :ok, else: {:error, :authorization_denied}
  rescue
    _ -> {:error, :authority_unavailable}
  end

  defp closed_reason(reason)
       when reason in [
              :invalid_envelope,
              :scope_mismatch,
              :feature_disabled,
              :sigra_denied,
              :authorization_denied
            ],
       do: reason

  defp closed_reason(_), do: :authority_unavailable
end
