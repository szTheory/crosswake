defmodule CrosswakeExample.LocalFirst.PhysicalIphoneAuthorityTest do
  use ExUnit.Case, async: false

  alias CrosswakeExample.LocalFirst.PhysicalIphoneAuthorityFixture

  test "Phoenix independently returns every closed backend authority observation" do
    assert {:ok, report} = PhysicalIphoneAuthorityFixture.run()

    assert Enum.all?(report, &(&1.owner == :backend_authority and &1.outcome == :passed))
  end
end
