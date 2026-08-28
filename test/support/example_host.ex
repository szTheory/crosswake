defmodule Crosswake.TestSupport.ExampleHost do
  @app_root Path.expand("../../examples/phoenix_host", __DIR__)
  @database_prefix "crosswake-example-host-"

  # Private to the proof harness — deliberately NOT CrosswakeExample.PubSub. See
  # start_endpoint!/0.
  @pubsub Crosswake.TestSupport.ExampleHostPubSub

  defmodule Ownership do
    @moduledoc false
    @enforce_keys [:state, :cleanup]
    defstruct [:state, :cleanup]
  end

  def load! do
    @app_root
    |> Path.join("_build/dev/lib/*/ebin")
    |> Path.wildcard()
    |> Enum.reject(&(Path.basename(Path.dirname(&1)) == "crosswake"))
    |> Enum.each(&prepend_path_owned!/1)

    :ok
  end

  @doc """
  Boot the checked-in example app's SQLite Repo for cross-repo proof tests.

  The SaaS example moved its approvals to an Ecto/SQLite persistence layer, but
  `load!/0` only prepends compiled code — it does not start the example's
  application supervision tree, so `CrosswakeExample.Repo` is never running in
  the main repo's test env. Start it against a throwaway temp database, run the
  example migrations, and let callers seed via `Approvals.reset!/0`. Idempotent.
  """
  def start_saas_repo! do
    # Resolve dynamically: these modules live in the example app's deps, prepended
    # by load!/0 at runtime — referencing them statically would warn under
    # `mix compile --warnings-as-errors` in the main repo (which lacks ecto_sql).
    repo = CrosswakeExample.Repo
    migrator = Ecto.Migrator

    case Process.whereis(repo) do
      pid when is_pid(pid) ->
        :ok

      nil ->
        db = unique_database_path()
        own_file!(db)

        put_env_owned!(:crosswake_example, repo, database: db, pool_size: 1, log: false)

        {:ok, _} = Application.ensure_all_started(:ecto_sql)
        {:ok, _} = Application.ensure_all_started(:ecto_sqlite3)

        _ownership = start_owned!(repo)

        apply(migrator, :run, [
          repo,
          Path.join(@app_root, "priv/repo/migrations"),
          :up,
          [all: true, log: false]
        ])
    end

    :ok
  end

  @doc """
  Boot the checked-in example app's Endpoint so proof tests can drive its LiveViews
  through a real `Phoenix.LiveViewTest` round trip. Idempotent.

  Why this exists: `Crosswake.Bridge.attach/1` registers `Phoenix.LiveView` lifecycle
  hooks, and `Crosswake.Bridge.push/3` dispatches through them. A hand-built
  `%Phoenix.LiveView.Socket{}` has no `:lifecycle` private key and never runs hooks at
  all, so calling `mount/3` and `handle_event/3` directly on a module cannot exercise
  a bridge-bearing route — it raises, and even if it did not, it would be asserting on
  a socket the framework would never produce. Mount the route for real instead.

  Call `start_saas_repo!/0` first: this only supplies the web layer.
  """
  def start_endpoint! do
    endpoint = CrosswakeExample.Endpoint

    if Process.whereis(endpoint) do
      :ok
    else
      configure_and_start_endpoint!(endpoint)
    end
  end

  defp configure_and_start_endpoint!(endpoint) do
    # The example app's own config/*.exs is never loaded in this repo's test env, so
    # the endpoint's configuration has to be supplied here. It mirrors
    # examples/phoenix_host/config/config.exs with two deliberate divergences.
    #
    # `server: false` — a LiveViewTest round trip needs no listening socket, and
    # binding the example's port (4700) would collide with a showcase server a
    # developer may already have running.
    #
    # `pubsub_server: @pubsub` rather than the app's own CrosswakeExample.PubSub —
    # phase35_paywall_live_test.exs `start_supervised!`s that globally-named broker
    # per test, deliberately, to get a fresh one each time. A long-lived broker under
    # the same name squats it and fails that lane with `:already_started` whenever it
    # runs second. Nothing reachable from these round trips broadcasts, so the
    # endpoint gets a private broker and the app-owned name stays unclaimed.
    put_env_owned!(:crosswake_example, endpoint,
      url: [host: "localhost"],
      server: false,
      secret_key_base: String.duplicate("a", 64),
      live_view: [signing_salt: "crosswake"],
      pubsub_server: @pubsub
    )

    {:ok, _} = Application.ensure_all_started(:phoenix)

    _pubsub = start_owned!({Phoenix.PubSub, name: @pubsub})
    _endpoint = start_owned!(endpoint)

    :ok
  end

  @doc false
  def put_env_owned!(app, key, value) do
    prior = Application.fetch_env(app, key)

    token =
      register_cleanup(fn ->
        case prior do
          {:ok, previous} -> Application.put_env(app, key, previous)
          :error -> Application.delete_env(app, key)
        end
      end)

    Application.put_env(app, key, value)
    token
  end

  @doc false
  def prepend_path_owned!(path) do
    if path in Enum.map(:code.get_path(), &List.to_string/1) do
      {:unowned, path}
    else
      true = Code.prepend_path(path)
      token = register_cleanup(fn -> Code.delete_path(path) end)
      {:owned, token}
    end
  end

  @doc false
  def unique_database_path do
    filename =
      @database_prefix <>
        Integer.to_string(System.unique_integer([:positive, :monotonic])) <> ".sqlite3"

    Path.join(System.tmp_dir!(), filename)
  end

  @doc false
  def own_file!(path) do
    register_cleanup(fn -> File.rm(path) end)
  end

  @doc false
  def start_owned!(child_spec) do
    caller = self()
    ref = make_ref()

    owner =
      spawn(fn ->
        result = start_child(child_spec)
        send(caller, {ref, result, self()})

        case result do
          {:ok, pid} ->
            receive do
              {:cleanup, ^ref} -> stop_owned_process(pid)
            end

          _ ->
            :ok
        end
      end)

    receive do
      {^ref, {:ok, pid}, ^owner} ->
        token =
          register_cleanup(fn ->
            monitor = Process.monitor(pid)
            send(owner, {:cleanup, ref})

            receive do
              {:DOWN, ^monitor, :process, ^pid, _reason} -> :ok
            after
              5_000 -> raise "timed out stopping owned process #{inspect(pid)}"
            end
          end)

        {:owned, pid, token}

      {^ref, {:error, {:already_started, pid}}, ^owner} ->
        {:unowned, pid}

      {^ref, {:error, reason}, ^owner} ->
        raise "failed to start owned process: #{inspect(reason)}"
    after
      5_000 ->
        Process.exit(owner, :kill)
        raise "timed out starting owned process"
    end
  end

  @doc false
  def cleanup!(%Ownership{state: state, cleanup: cleanup}) do
    if :atomics.exchange(state, 1, 0) == 1, do: cleanup.()
    :ok
  end

  defp register_cleanup(cleanup) do
    state = :atomics.new(1, signed: false)
    :atomics.put(state, 1, 1)
    token = %Ownership{state: state, cleanup: cleanup}
    ExUnit.Callbacks.on_exit(fn -> cleanup!(token) end)
    token
  end

  defp start_child({module, init, options}) when is_function(init, 0) and is_list(options) do
    apply(module, :start_link, [init, options])
  end

  defp start_child(child_spec) do
    {module, function, arguments} = Supervisor.child_spec(child_spec, []).start
    apply(module, function, arguments)
  end

  defp stop_owned_process(pid) do
    if Process.alive?(pid) do
      GenServer.stop(pid, :normal, 5_000)
    end

    :ok
  catch
    :exit, {:noproc, _} -> :ok
  end
end
