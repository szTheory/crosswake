defmodule CrosswakeRulestead.MixProject do
  use Mix.Project

  @version "0.1.0" # x-release-please-version — D-22: separate from core 0.1.2; do NOT touch core release-please config/manifest
  @source_url "https://github.com/szTheory/crosswake"

  def project do
    [
      app: :crosswake_rulestead,
      version: @version,
      name: "crosswake_rulestead",
      elixir: "~> 1.19",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
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

  # Mirror core's pattern (mix.exs lines 35-36).
  # When ENGINE_PRESENT_LANE=1 is set, also compile the engine_present/ stub dir.
  # This appends the fake top-level Rulestead stub (D-33) without compile-baking
  # engine presence. The advisory lane alias sets this env var before running tests.
  defp elixirc_paths(:test) do
    base = ["lib", "test/support"]

    if System.get_env("ENGINE_PRESENT_LANE") == "1" do
      base ++ ["test/engine_present"]
    else
      base
    end
  end

  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      # D-19: core is a RUNTIME dep of the companion (no :runtime option needed).
      # A real adopter needs :crosswake application started at runtime.
      # D-11/D-13: env-conditional resolver — see crosswake_dep/0 below.
      crosswake_dep(),
      # D-28: optional: true — Swoosh gold-standard optional-dep idiom.
      # The engine is optional; absence is handled via Code.ensure_loaded? + @compile {:no_warn_undefined}.
      {:rulestead, "~> 0.1", optional: true}
    ]
  end

  # D-11/D-13: Env-conditional crosswake dep resolver — the publish seam.
  # Local dev + in-tree CI: test against LOCAL core (path dep, high fidelity — D-11).
  # Publish job sets CROSSWAKE_RELEASE=1 so the tarball records an honest Hex requirement
  # rather than a path: dep (which hex.build would error on — D-13).
  # NOTE: the string "path:" appearing in this function body is expected (Pitfall 4 in RESEARCH.md);
  # it does NOT represent an active bare path dep in deps/0.
  defp crosswake_dep do
    if System.get_env("CROSSWAKE_RELEASE") == "1",
      do: {:crosswake, "~> 0.1"},
      else: {:crosswake, path: "../.."}
  end

  # D-26 (package-level): engine-present advisory lane alias.
  # Default mix test = engine-ABSENT (hermetic, merge-blocking).
  # Advisory lane: mix engine-present.test — sets ENGINE_PRESENT_LANE=1 and runs
  # mix clean first to avoid a stale stub .beam leaking into the absent lane (D-33).
  defp aliases do
    [
      "engine-present.test": [
        "clean",
        "cmd ENGINE_PRESENT_LANE=1 mix test --only engine_present"
      ]
    ]
  end

  defp description do
    "Rulestead companion adapter for the Crosswake route-policy system."
  end

  defp package do
    [
      name: "crosswake_rulestead",
      licenses: ["Apache-2.0"],
      links: %{
        "Changelog" => "#{@source_url}/blob/main/CHANGELOG.md",
        "Documentation" => "https://hexdocs.pm/crosswake_rulestead",
        "GitHub" => @source_url
      },
      # D-24: test/ EXCLUDED from files: allowlist (verified with mix hex.build --unpack).
      # The companion ships NO priv/ or guides/ either.
      files: ~w(lib mix.exs README.md LICENSE CHANGELOG.md)
    ]
  end
end
