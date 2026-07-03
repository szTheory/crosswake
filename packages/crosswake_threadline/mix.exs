defmodule CrosswakeThreadline.MixProject do
  use Mix.Project

  @version "0.1.0" # x-release-please-version — D-22: separate from core 0.1.2; do NOT touch core release-please config/manifest
  @source_url "https://github.com/szTheory/crosswake"

  def project do
    [
      app: :crosswake_threadline,
      version: @version,
      name: "crosswake_threadline",
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

  # NOTE: No ENGINE_PRESENT_LANE branch — threadline has no optional engine library.
  # Threadline audit/correlation machinery is pure OTP stdlib; no third-party engine dep is needed.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      # D-19: core is a RUNTIME dep of the companion.
      # D-11/D-13: env-conditional resolver — see crosswake_dep/0 below.
      crosswake_dep(),
      # NOTE: No sibling companion dep (THREAD-02 invariant).
      # threadline has zero dependency on any sibling companion in any env.
      # Optional Phoenix surface — wrap defmodules in Code.ensure_loaded? guards (PromEx precedent).
      # After adding these optional deps to a host, run:
      #   mix deps.compile --force crosswake_threadline
      # (stale-BEAM caveat: optional deps are not compiled by default until forced.)
      {:plug, "~> 1.0", optional: true},
      {:phoenix_live_view, "~> 1.1", optional: true},
      # nimble_options is non-optional — used at @schema module-eval in Crosswake.Plug.Threadline.
      {:nimble_options, "~> 1.1"},
      {:telemetry, "~> 1.0"},
      {:ex_doc, "~> 0.38", only: :dev, runtime: false}
    ]
  end

  # D-11/D-13: Env-conditional crosswake dep resolver — the publish seam.
  # Local dev + in-tree CI: test against LOCAL core (path dep, high fidelity — D-11).
  # Publish job sets CROSSWAKE_RELEASE=1 so the tarball records an honest Hex requirement
  # rather than a path: dep (which hex.build would error on — D-13).
  defp crosswake_dep do
    if System.get_env("CROSSWAKE_RELEASE") == "1",
      do: {:crosswake, "~> 0.1"},
      else: {:crosswake, path: "../.."}
  end

  defp description do
    "Threadline audit and correlation observer for the Crosswake route-policy system."
  end

  defp package do
    [
      name: "crosswake_threadline",
      licenses: ["Apache-2.0"],
      links: %{
        "Changelog" => "#{@source_url}/blob/main/CHANGELOG.md",
        "Documentation" => "https://hexdocs.pm/crosswake_threadline",
        "GitHub" => @source_url
      },
      # D-24: test/ EXCLUDED from files: allowlist.
      # "priv" MUST be included — ships priv/templates/crosswake/audit/*.eex for mix crosswake.gen.audit.
      # Omitting "priv" yields a valid tarball that silently breaks the generator at runtime.
      files: ~w(lib priv mix.exs README.md LICENSE CHANGELOG.md)
    ]
  end
end
