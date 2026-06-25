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
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      # D-19: core is a RUNTIME dep of the companion (no :runtime option needed).
      # A real adopter needs :crosswake application started at runtime.
      {:crosswake, path: "../.."},
      # D-28: optional: true — Swoosh gold-standard optional-dep idiom.
      # The engine is optional; absence is handled via Code.ensure_loaded? + @compile {:no_warn_undefined}.
      {:rulestead, "~> 0.1", optional: true}
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
