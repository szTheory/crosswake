defmodule Crosswake.TestSupport.ExampleHost do
  @app_root Path.expand("../../examples/phoenix_host", __DIR__)

  # Private to the proof harness — deliberately NOT CrosswakeExample.PubSub. See
  # start_endpoint!/0.
  @pubsub Crosswake.TestSupport.ExampleHostPubSub

  def load! do
    @app_root
    |> Path.join("_build/dev/lib/*/ebin")
    |> Path.wildcard()
    |> Enum.reject(&(Path.basename(Path.dirname(&1)) == "crosswake"))
    |> Enum.each(&Code.prepend_path/1)

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

    db =
      Path.join(System.tmp_dir!(), "cw_saas_proof_#{System.unique_integer([:positive])}.db")

    Application.put_env(:crosswake_example, repo, database: db, pool_size: 1, log: false)

    {:ok, _} = Application.ensure_all_started(:ecto_sql)
    {:ok, _} = Application.ensure_all_started(:ecto_sqlite3)

    case apply(repo, :start_link, []) do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> :ok
    end

    apply(migrator, :run, [
      repo,
      Path.join(@app_root, "priv/repo/migrations"),
      :up,
      [all: true, log: false]
    ])

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
    Application.put_env(:crosswake_example, endpoint,
      url: [host: "localhost"],
      server: false,
      secret_key_base: String.duplicate("a", 64),
      live_view: [signing_salt: "crosswake"],
      pubsub_server: @pubsub
    )

    {:ok, _} = Application.ensure_all_started(:phoenix)

    start_detached!({Phoenix.PubSub, name: @pubsub})
    start_detached!(endpoint)

    :ok
  end

  # Both the PubSub tree and the Endpoint are supervisors, which shut down when their
  # starting process exits. Started from a `setup_all` block that would be exactly the
  # module's lifetime, so unlink and let them outlive any single test module — that is
  # what makes the `{:error, {:already_started, _}}` branch reachable and this function
  # genuinely idempotent across proof modules.
  defp start_detached!(child_spec) do
    {mod, fun, args} = Supervisor.child_spec(child_spec, []).start

    case apply(mod, fun, args) do
      {:ok, pid} ->
        Process.unlink(pid)
        :ok

      {:error, {:already_started, _pid}} ->
        :ok
    end
  end
end
