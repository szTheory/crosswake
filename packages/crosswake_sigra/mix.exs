defmodule CrosswakeSigra.MixProject do
  use Mix.Project

  @version "0.1.0" # x-release-please-version — D-22: separate from core 0.1.2; do NOT touch core release-please config/manifest
  @source_url "https://github.com/szTheory/crosswake"

  def project do
    [
      app: :crosswake_sigra,
      version: @version,
      name: "crosswake_sigra",
      elixir: "~> 1.19",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      source_url: @source_url,
      homepage_url: @source_url,
      package: package()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # NOTE: No ENGINE_PRESENT_LANE branch — sigra has no optional engine library.
  # Sigra auth machinery is pure Elixir; no third-party engine dep is needed.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      # D-19: core is a RUNTIME dep of the companion.
      # D-11/D-13: env-conditional resolver — see crosswake_dep/0 below.
      crosswake_dep(),
      # ex_doc is required by `mix hex.publish` to build package docs. only: [:dev, :test]
      # so it's present regardless of the publish job's MIX_ENV, runtime: false so it never
      # ships. Matches core; its absence failed publish-hex-sigra at the docs dry-run.
      {:ex_doc, "~> 0.38", only: [:dev, :test], runtime: false}
      # NOTE: No optional engine dep — sigra has no third-party engine library.
      # The auth machinery is pure Elixir.
    ]
  end

  # D-11/D-13: Env-conditional crosswake dep resolver — the publish seam.
  # Local dev + in-tree CI: test against LOCAL core (path dep, high fidelity — D-11).
  # Publish job sets CROSSWAKE_RELEASE=1 so the tarball records an honest Hex requirement
  # rather than a path: dep (which hex.build would error on — D-13).
  defp crosswake_dep do
    if System.get_env("CROSSWAKE_RELEASE") == "1",
      do: {:crosswake, "~> 0.2"},
      else: {:crosswake, path: "../.."}
  end

  defp description do
    "Sigra auth companion adapter for the Crosswake route-policy system."
  end

  defp package do
    [
      name: "crosswake_sigra",
      licenses: ["Apache-2.0"],
      links: %{
        "Changelog" => "#{@source_url}/blob/main/CHANGELOG.md",
        "Documentation" => "https://hexdocs.pm/crosswake_sigra",
        "GitHub" => @source_url
      },
      # D-24: test/ EXCLUDED from files: allowlist.
      # The companion ships NO priv/ or guides/ either.
      files: ~w(lib mix.exs README.md LICENSE CHANGELOG.md)
    ]
  end
end
