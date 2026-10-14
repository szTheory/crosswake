defmodule Crosswake.Shell.HostCommandSeamSwiftConstantTest do
  use ExUnit.Case, async: true

  alias Crosswake.Shell.ShellPackage

  test "the Swift HostCommandSeam constant equals the Elixir seam version" do
    package = Path.expand("../../../packages/crosswake-shell-core-ios", __DIR__)
    assert ShellPackage.seam_version_at(package) == Crosswake.HostCommands.seam_version()
  end
end
