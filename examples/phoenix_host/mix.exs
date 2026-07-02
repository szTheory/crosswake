defmodule CrosswakeExample.MixProject do
  use Mix.Project

  def project do
    [
      app: :crosswake_example,
      version: "0.1.2",
      elixir: "~> 1.19",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      # Phoenix 1.8 drives compile-on-request code reloading through a Mix listener;
      # without it the dev code reloader raises on every request.
      listeners: [Phoenix.CodeReloader],
      deps: deps(),
      aliases: aliases()
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  def application do
    [
      mod: {CrosswakeExample.Application, []},
      extra_applications: [:logger]
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "ecto.setup"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      # Provisions the SQLite DB and applies all migrations before running tests.
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"]
    ]
  end

  defp deps do
    [
      {:crosswake, path: "../.."},
      # Companion packages this example adopts (extracted in Phases 130/132/137/138). The example
      # uses the Rulestead gate (config.exs), the Rindle media seam (lib/.../media/*), the
      # Sigra auth companion (saas_portal/handoff.ex uses Sigra.Handoff/Contracts/DenialCodes),
      # and the Chimeway notification companion — so it declares them as ordinary path deps,
      # exactly how a real adopter would add
      # `{:crosswake_rulestead, "~> 0.1"}` / `{:crosswake_rindle, "~> 0.1"}` /
      # `{:crosswake_sigra, "~> 0.1"}` / `{:crosswake_chimeway, "~> 0.1"}` from Hex.
      {:crosswake_rulestead, path: "../../packages/crosswake_rulestead"},
      {:crosswake_rindle, path: "../../packages/crosswake_rindle"},
      {:crosswake_sigra, path: "../../packages/crosswake_sigra"},
      {:crosswake_chimeway, path: "../../packages/crosswake_chimeway"},
      {:phoenix, "~> 1.8"},
      {:phoenix_live_view, "~> 1.1"},
      {:phoenix_live_reload, "~> 1.5", only: :dev},
      {:plug, "~> 1.16"},
      {:jason, "~> 1.4"},
      {:ecto_sql, "~> 3.10"},
      {:ecto_sqlite3, "~> 0.16"},
      {:bandit, "~> 1.0"}
    ]
  end
end
