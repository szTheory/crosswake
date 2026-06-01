defmodule Crosswake.Guides.ReleaseBoundariesTest do
  use ExUnit.Case, async: true

  test "guide surfaces publish the four change classes and rebuild-first wording" do
    install = File.read!("guides/install.md")
    native_shell = File.read!("guides/native_shell.md")
    compatibility = File.read!("guides/compatibility.md")
    example_host = File.read!("examples/phoenix_host/README.md")

    assert install =~ "Do I need to rebuild?"
    assert install =~ "docs-only"
    assert install =~ "core-only/no native rebuild"
    assert install =~ "compatibility-bump only"
    assert install =~ "native or companion rebuild required"
    assert install =~ "docs integrity only"
    assert install =~ "core contract + doctor/support proof"
    assert install =~ "fail-closed compatibility fixtures"
    assert install =~ "generated-shell or companion verification lanes"

    assert native_shell =~ "native or companion rebuild required"
    assert compatibility =~ "Change class `docs-only`"
    assert compatibility =~ "Change class `core-only/no native rebuild`"
    assert compatibility =~ "Change class `compatibility-bump only`"
    assert compatibility =~ "Change class `native or companion rebuild required`"

    assert example_host =~ "reclassification plus proof and support-matrix updates"
    assert example_host =~ "supported example"
    assert example_host =~ "not a separate supported runtime package"
  end

  test "guide surfaces link rebuild guidance to canonical promotion and non-claim truth" do
    guide_paths = [
      "guides/install.md",
      "guides/native_shell.md",
      "guides/compatibility.md"
    ]

    for path <- guide_paths do
      guide = File.read!(path)

      assert guide =~ "Do I need to rebuild?"
      assert guide =~ "Promotion rules"
      assert guide =~ "guides/support_matrix.md#action-classes"
      assert guide =~ "guides/support_matrix.md#promotion-rules"
      assert guide =~ "StoreKit/Play Billing adapters are not shipped in v3.6"
      assert guide =~ "Sigra remains contract-only"
      assert guide =~ "notification-token readiness is provider-snapshot only"
      assert guide =~ "standalone public shell packages are deferred"
      assert guide =~ "compatibility-window narrowing is distinct from a native rebuild"
    end
  end
end
