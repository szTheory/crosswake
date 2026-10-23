defmodule Crosswake.Shell.HostCommandSeamSwiftConstantTest do
  use ExUnit.Case, async: true

  alias Crosswake.Shell.ShellPackage

  test "the Swift HostCommandSeam constant equals the Elixir seam version" do
    package = Path.expand("../../../packages/crosswake-shell-core-ios", __DIR__)
    assert ShellPackage.seam_version_at(package) == Crosswake.HostCommands.seam_version()
  end

  test "the Swift supportedCommandMajor equals the Elixir supported command major" do
    source =
      Path.expand(
        "../../../packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/ActivationCoordinator.swift",
        __DIR__
      )
      |> File.read!()

    [_, major] =
      Regex.run(~r/public\s+static\s+let\s+supportedCommandMajor\s*=\s*(\d+)/, source)

    assert String.to_integer(major) == Crosswake.HostCommands.supported_command_major()
  end
end
