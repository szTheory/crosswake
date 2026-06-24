defmodule Crosswake.MixProject do
  use Mix.Project

  @version "0.1.2" # x-release-please-version
  @source_url "https://github.com/szTheory/crosswake"

  def project do
    [
      app: :crosswake,
      version: @version,
      name: "crosswake",
      elixir: "~> 1.19",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      source_url: @source_url,
      homepage_url: @source_url,
      package: package(),
      docs: docs()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Shared test fixtures (test/support/*.ex) are compiled once as project
  # modules in the test env, instead of being loaded per-file via
  # Code.require_file/2. The latter races during parallel test compilation —
  # multiple test files requiring the same fixture concurrently intermittently
  # fails with {:error, :enoent}.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    base = [
      {:jason, "~> 1.4"},
      {:nimble_options, "~> 1.1"},
      {:phoenix, "~> 1.8"},
      {:phoenix_live_view, "~> 1.1"},
      {:telemetry, "~> 1.0"},
      {:ex_doc, "~> 0.38", only: :dev, runtime: false}
    ]

    rulestead =
      if System.get_env("MIX_INCLUDE_RULESTEAD") == "1" do
        [{:rulestead, "~> 0.1.6"}]
      else
        []
      end

    rindle =
      if System.get_env("MIX_INCLUDE_RINDLE") == "1" do
        [{:rindle, "~> 0.1"}]
      else
        []
      end

    base ++ rulestead ++ rindle
  end

  defp description do
    "Route policy and runtime contracts for Phoenix apps that go mobile."
  end

  defp package do
    [
      name: "crosswake",
      licenses: ["Apache-2.0"],
      links: %{
        "Changelog" => "#{@source_url}/blob/main/CHANGELOG.md",
        "Documentation" => "https://hexdocs.pm/crosswake",
        "GitHub" => @source_url
      },
      files: ~w(lib priv mix.exs README.md LICENSE CHANGELOG.md guides),
      exclude_patterns: ["brandbook"]
    ]
  end

  defp docs do
    [
      logo: "brandbook/logo/crosswake-mark.svg",
      main: "readme",
      source_ref: "v#{@version}",
      source_url: @source_url,
      formatters: ["html"],
      extras: [
        "README.md",
        "guides/see_it_run.md",
        "CHANGELOG.md",
        "LICENSE",
        "guides/install.md",
        "guides/route_policy.md",
        "guides/web_to_mobile_migration.md",
        "guides/troubleshooting.md",
        "guides/support_matrix.md",
        "guides/adopter_profiles.md",
        "guides/adoption.md",
        "guides/user_flows.md",
        "guides/capabilities.md",
        "guides/bridge.md",
        "guides/offline.md",
        "guides/tokens.md",
        "guides/commerce.md",
        "guides/companions.md",
        "guides/compatibility.md",
        "guides/native_shell.md",
        "guides/android_uat.md",
        "guides/packs.md",
        "guides/threadline.md"
      ],
      groups_for_modules: [
        Policy: [Crosswake.Policy, Crosswake.Router],
        Bridge: ~r/Crosswake\.Bridge(\.|$)/,
        Manifest: [Crosswake.Manifest],
        Capabilities: ~r/Crosswake\.(Commerce|Offline|Packs)/
      ],
      groups_for_extras: [
        Start: [
          "README.md",
          "guides/see_it_run.md",
          "guides/route_policy.md",
          "guides/install.md"
        ],
        Adopt: [
          "guides/web_to_mobile_migration.md",
          "guides/user_flows.md",
          "guides/adopter_profiles.md",
          "guides/adoption.md"
        ],
        "Runtime Owners": [
          "guides/native_shell.md",
          "guides/bridge.md",
          "guides/capabilities.md",
          "guides/offline.md",
          "guides/packs.md",
          "guides/tokens.md",
          "guides/commerce.md"
        ],
        Truth: [
          "guides/troubleshooting.md",
          "guides/support_matrix.md",
          "guides/compatibility.md",
          "guides/android_uat.md"
        ],
        "Advanced/Companions": [
          "guides/companions.md",
          "guides/threadline.md",
          "CHANGELOG.md",
          "LICENSE"
        ]
      ]
    ]
  end
end
