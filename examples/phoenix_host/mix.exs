defmodule CrosswakeExample.MixProject do
  use Mix.Project

  def project do
    [
      app: :crosswake_example,
      version: "0.1.0",
      elixir: "~> 1.19",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
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
      # Provisions the SQLite DB and applies all migrations before running tests.
      # Required in CI where the committed .db file is absent or stale.
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"]
    ]
  end

  defp deps do
    [
      {:crosswake, path: "../.."},
      {:phoenix, "~> 1.8"},
      {:phoenix_live_view, "~> 1.1"},
      {:plug, "~> 1.16"},
      {:jason, "~> 1.4"},
      {:ecto_sql, "~> 3.10"},
      {:ecto_sqlite3, "~> 0.16"},
      {:bandit, "~> 1.0"}
    ]
  end
end
