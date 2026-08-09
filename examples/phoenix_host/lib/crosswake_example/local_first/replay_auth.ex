defmodule CrosswakeExample.LocalFirst.ReplayAuth do
  @moduledoc false

  import Plug.Conn

  @authority_key :offline_study_replay_authority
  @timeout_ms 1_000

  @type result(value) :: {:ok, value} | {:error, :auth_required | :authority_unavailable}

  def init(opts), do: opts

  def call(conn, _opts) do
    case current_session(conn) do
      {:ok, _session} -> assign(conn, :replay_authenticated, true)
      {:error, reason} -> deny(conn, reason)
    end
  end

  @spec current_session(Plug.Conn.t()) :: result(map())
  def current_session(conn), do: resolve(:current_session, [conn], :auth_required)

  @spec current_route(Plug.Conn.t()) :: result(map())
  def current_route(conn), do: resolve(:current_route, [conn], :authority_unavailable)

  @spec feature_enabled?(map(), Plug.Conn.t()) :: result(:allow)
  def feature_enabled?(route, conn), do: resolve(:feature_enabled?, [route, conn], :authority_unavailable)

  @spec domain_allows?(map(), map(), map()) :: result(:allow)
  def domain_allows?(route, session, event),
    do: resolve(:domain_allows?, [route, session, event], :authority_unavailable)

  defp resolve(function, args, missing_reason) do
    with {:ok, authority} <- authority_module(),
         {:ok, value} <- invoke(authority, function, args),
         :ok <- valid_result?(function, value) do
      {:ok, value}
    else
      {:error, :auth_required} -> {:error, :auth_required}
      _ -> {:error, missing_reason}
    end
  end

  defp authority_module do
    case Application.get_env(:crosswake_example, @authority_key) do
      module when is_atom(module) -> {:ok, module}
      _ -> {:error, :authority_unavailable}
    end
  end

  defp invoke(module, function, args) do
    if Code.ensure_loaded?(module) and function_exported?(module, function, length(args)) do
      task = Task.async(fn -> apply(module, function, args) end)

      case Task.yield(task, @timeout_ms) || Task.shutdown(task, :brutal_kill) do
        {:ok, {:ok, value}} -> {:ok, value}
        {:ok, {:error, :auth_required}} -> {:error, :auth_required}
        _ -> {:error, :authority_unavailable}
      end
    else
      {:error, :authority_unavailable}
    end
  rescue
    _ -> {:error, :authority_unavailable}
  catch
    :exit, _ -> {:error, :authority_unavailable}
    :throw, _ -> {:error, :authority_unavailable}
  end

  defp valid_result?(:current_session, %{scope_ref: scope_ref, auth_context: auth_context})
       when is_binary(scope_ref) and is_map(auth_context),
       do: :ok

  defp valid_result?(:current_route, route) when is_map(route), do: :ok
  defp valid_result?(:feature_enabled?, :allow), do: :ok
  defp valid_result?(:domain_allows?, :allow), do: :ok
  defp valid_result?(_, _), do: {:error, :authority_unavailable}

  defp deny(conn, reason) do
    conn
    |> put_status(:forbidden)
    |> Phoenix.Controller.json(%{error: %{class: reason}})
    |> halt()
  end
end
