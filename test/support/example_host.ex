defmodule Crosswake.TestSupport.ExampleHost do
  @app_root Path.expand("../../examples/phoenix_host", __DIR__)

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
end
