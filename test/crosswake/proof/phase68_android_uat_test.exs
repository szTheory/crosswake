defmodule Crosswake.Proof.Phase68AndroidUATTest do
  use ExUnit.Case, async: true

  alias Crosswake.SupportMatrix

  test "UAT checklist maintains capability registry parity" do
    content = File.read!("guides/android_uat.md")
    
    capability_families =
      SupportMatrix.canonical().capability_families
      |> Enum.map(& &1.family)
      |> Enum.uniq()
      
    for family <- capability_families do
      assert String.contains?(content, "**#{family}**") or String.contains?(content, "`#{family}`") or String.contains?(content, family),
             "Capability family '#{family}' is missing from guides/android_uat.md"
    end
  end
end
