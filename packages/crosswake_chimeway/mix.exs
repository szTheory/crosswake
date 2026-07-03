defmodule CrosswakeChimeway.MixProject do
  use Mix.Project

  @version "0.1.0" # x-release-please-version — D-22: separate from core 0.1.2; do NOT touch core release-please config/manifest
  @source_url "https://github.com/szTheory/crosswake"

  def project do
    [
      app: :crosswake_chimeway,
      version: @version,
      name: "crosswake_chimeway",
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

  # NOTE: No ENGINE_PRESENT_LANE branch — chimeway has no optional engine library.
  # Chimeway notification machinery is pure Elixir; no third-party engine dep is needed.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      # D-19: core is a RUNTIME dep of the companion.
      # D-11/D-13: env-conditional resolver — see crosswake_dep/0 below.
      crosswake_dep(),
      # D-138-02: test-only dep for phase71_notification_workflow_proof_test.exs.
      # phase71 requires a real validated %SigraContracts.AuthContext{} (via
      # SigraContracts.new_session_authority_lane/1 + new_auth_context/1) because
      # the proof pattern-matches on %SigraContracts.AuthContext{} and drives sigra's
      # evaluator through RouteGate — plain map literals cannot reproduce that evaluation.
      # This dep is NEVER compiled into the runtime/prod package:
      # - only: :test scopes it to test compilation only
      # - the package/0 files: allowlist (~w(lib mix.exs README.md LICENSE CHANGELOG.md))
      #   excludes test/ so the Hex tarball never ships this dep or the test source
      # - the clean-room lane (Task 3) installs the published tarball where sigra is absent
      # CHIME-02 invariant preserved: no runtime/prod sigra dep; test-only dep confirmed
      # by the no-runtime-sigra-dep vacuity guard in phase138_chimeway_cleanroom_test.exs.
      {:crosswake_sigra, path: "../../packages/crosswake_sigra", only: :test},
      # ex_doc is required by `mix hex.publish` to build package docs (matches core).
      {:ex_doc, "~> 0.38", only: [:dev, :test]}
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
    "Chimeway notification companion adapter for the Crosswake route-policy system."
  end

  defp package do
    [
      name: "crosswake_chimeway",
      licenses: ["Apache-2.0"],
      links: %{
        "Changelog" => "#{@source_url}/blob/main/CHANGELOG.md",
        "Documentation" => "https://hexdocs.pm/crosswake_chimeway",
        "GitHub" => @source_url
      },
      # D-24: test/ EXCLUDED from files: allowlist.
      # The companion ships NO priv/ or guides/ either.
      files: ~w(lib mix.exs README.md LICENSE CHANGELOG.md)
    ]
  end
end
