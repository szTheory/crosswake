defmodule Crosswake.Proof.Phase68AndroidUATTest do
  use ExUnit.Case, async: true

  alias Crosswake.SupportMatrix

  @guide "guides/android_uat.md"
  @heading "## Capability families (registry mirror)"

  defp registry_families do
    SupportMatrix.canonical().capability_families
    |> Enum.map(& &1.family)
    |> Enum.uniq()
  end

  # Backticked bullets under the registry-mirror heading only, up to the next `## ` heading.
  # A family named elsewhere in the guide must not count as listed.
  defp listed_families(content) do
    case String.split(content, @heading, parts: 2) do
      [_before, rest] ->
        slice = rest |> String.split(~r/^## /m, parts: 2) |> hd()

        ~r/^- `([a-z_.]+)`$/m
        |> Regex.scan(slice, capture: :all_but_first)
        |> List.flatten()

      [_whole] ->
        []
    end
  end

  defp family_diff(listed, registry) do
    listed_set = MapSet.new(listed)
    registry_set = MapSet.new(registry)

    {
      listed_set |> MapSet.difference(registry_set) |> Enum.sort(),
      registry_set |> MapSet.difference(listed_set) |> Enum.sort()
    }
  end

  test "UAT checklist lists exactly the capability registry families" do
    content = File.read!(@guide)
    registry = registry_families()
    listed = listed_families(content)

    assert registry != [], "capability registry is empty; the check would assert nothing"
    assert listed != [], "no families found under '#{@heading}' in #{@guide}"

    {phantom, missing} = family_diff(listed, registry)

    assert {phantom, missing} == {[], []},
           "guides/android_uat.md family list differs from the registry. " <>
             "Phantom (listed, not in registry): #{inspect(phantom)}. " <>
             "Missing (in registry, not listed): #{inspect(missing)}."
  end

  test "control: a phantom plus a missing family are both reported" do
    content = File.read!(@guide)
    registry = registry_families()

    assert "share" in registry

    mutated =
      content
      |> String.replace("- `share`\n", "- `phantom_family`\n", global: false)

    refute mutated == content, "control mutation did not change the guide"

    assert family_diff(listed_families(mutated), registry) == {["phantom_family"], ["share"]}
  end

  test "control: a family named outside the heading slice does not count" do
    content = File.read!(@guide)
    registry = registry_families()

    mutated =
      content <>
        "\nProse mentioning `account_management` outside the slice.\n- `account_management`\n"

    refute mutated == content, "control mutation did not change the guide"

    assert family_diff(listed_families(mutated), registry) == {[], []}
  end
end
