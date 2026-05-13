defmodule Crosswake.MixProject do
  use Mix.Project

  @version "0.1.0"

  def project do
    [
      app: :crosswake,
      version: @version,
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:nimble_options, "~> 1.1"},
      {:phoenix, "~> 1.8"},
      {:phoenix_live_view, "~> 1.1"}
    ]
  end

  defp description do
    "Phoenix-first route policy and runtime contract substrate"
  end

  defp package do
    [
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/example/crosswake"}
    ]
  end
end
