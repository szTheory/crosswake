defmodule Crosswake.Proof.AdopterProfileContractTest do
  use ExUnit.Case, async: true

  @locked_names [
    "Phoenix SaaS Portal",
    "Selective Native Flow",
    "Local-First Study Flow"
  ]

  test "shared host contract preserves the locked profile lanes and boundaries" do
    readme = File.read!("examples/phoenix_host/README.md")
    guide = File.read!("guides/adopter_profiles.md")
    native_shell = File.read!("guides/native_shell.md")
    install = File.read!("guides/install.md")

    for name <- @locked_names do
      assert readme =~ name
      assert guide =~ name
    end

    assert readme =~ "one shared Phoenix host"
    assert readme =~ "paired iOS and Android example hosts"
    assert readme =~ "4-6 routes"
    assert readme =~ "5-8 routes"
    assert readme =~ "`:live_view`"
    assert readme =~ "`:native_screen`"
    assert readme =~ "`:offline_island`"
    assert readme =~ "`route unavailable`"
    assert readme =~ "`pack_incompatible`"
    assert readme =~ "`conflict requires attention`"

    assert readme =~ "Supported behavior"
    assert readme =~ "Degraded behavior"
    assert readme =~ "Deferred behavior"

    assert guide =~ "Supported behavior"
    assert guide =~ "Degraded behavior"
    assert guide =~ "Deferred behavior"
    assert guide =~ "host-owned auth"
    assert guide =~ "guides/support_matrix.md"
    assert guide =~ "guides/install.md"

    assert native_shell =~ "Phoenix SaaS Portal"
    assert native_shell =~ "route unavailable"
    assert native_shell =~ "degraded"

    assert install =~ "Phoenix SaaS Portal"
    assert install =~ "script/verify_phase5_example_hosts.sh"
  end

  test "profile verification scaffold extends the existing example-host proof posture" do
    script = File.read!("script/verify_adopter_profile_contract.sh")

    assert script =~ "guides/adopter_profiles.md"
    assert script =~ "examples/phoenix_host/README.md"
    assert script =~ "script/verify_phase5_example_hosts.sh"

    assert {output, 0} = System.cmd("bash", ["script/verify_adopter_profile_contract.sh"])
    assert output =~ "Adopter profile contract verified."
  end
end
