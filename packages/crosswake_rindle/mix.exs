defmodule CrosswakeRindle.MixProject do
  use Mix.Project

  @version "0.1.0" # x-release-please-version — D-22: separate from core 0.1.2; do NOT touch core release-please config/manifest
  @source_url "https://github.com/szTheory/crosswake"

  def project do
    [
      app: :crosswake_rindle,
      version: @version,
      name: "crosswake_rindle",
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
  # This appends the fake top-level Rindle stub (D-33) without compile-baking
  # engine presence. The advisory lane alias sets this env var before running tests.
  #
  # NOTE: test/support/example_host/ is deliberately EXCLUDED from elixirc_paths.
  # Those media helpers are loaded ONLY via Code.require_file/2 inside the moved
  # phase45/phase72 proof tests (the phase72 hermeticity self-scan asserts on those
  # require_file basenames). Compiling them here too would double-load the modules
  # and emit "redefining module" warnings at test runtime. So we compile only the
  # StudySessionLive stub from test/support and leave example_host/ to require_file.
  defp elixirc_paths(:test) do
    base = [
      "lib",
      "test/support/study_session_live.ex",
      "test/support/example_host.ex"
    ]

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
      # D-16: engine cap ~> 0.1 admits every 0.x (>= 0.1.0 and < 1.0.0), so rindle 0.3.x
      # resolves engine-present — proven green by the 132-03 engine-present lane. A 1.0.0
      # engine would fall outside the cap; widening past the next major is deferred until
      # the companion contract is proven against it.
      {:rindle, "~> 0.1", optional: true},
      # ex_doc is required by `mix hex.publish` to build package docs (matches core).
      {:ex_doc, "~> 0.38", only: [:dev, :test], runtime: false}
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
    "Rindle companion adapter for the Crosswake route-policy system."
  end

  defp package do
    [
      name: "crosswake_rindle",
      licenses: ["Apache-2.0"],
      links: %{
        "Changelog" => "#{@source_url}/blob/main/CHANGELOG.md",
        "Documentation" => "https://hexdocs.pm/crosswake_rindle",
        "GitHub" => @source_url
      },
      # D-24: test/ EXCLUDED from files: allowlist (verified with mix hex.build --unpack).
      # The companion ships NO priv/ or guides/ either.
      files: ~w(lib mix.exs README.md LICENSE CHANGELOG.md)
    ]
  end
end
