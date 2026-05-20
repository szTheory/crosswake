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
end
