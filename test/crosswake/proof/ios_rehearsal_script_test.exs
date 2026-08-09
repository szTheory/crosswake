defmodule Crosswake.Proof.IosRehearsalScriptTest do
  use ExUnit.Case, async: true

  @rehearsal "bin/crosswake-ios-rehearsal"
  @physical "bin/crosswake-physical-iphone"

  test "simulator rehearsal opens the checked-in offline study route and labels it advisory" do
    source = File.read!(@rehearsal)

    assert source =~ "/learnloop/study/session"
    assert source =~ "advisory"
    assert source =~ "not physical-device proof"
    assert source =~ "simctl openurl"
    assert source =~ "mix phx.server"
  end

  test "physical wrapper runs readiness before promotion and avoids device identifiers in output" do
    source = File.read!(@physical)

    assert source =~ "--readiness --json"
    assert source =~ "--run --promote --json"
    refute source =~ "xctrace"
    refute source =~ "simctl"
  end
end
