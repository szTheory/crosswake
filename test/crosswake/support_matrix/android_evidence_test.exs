defmodule Crosswake.SupportMatrix.AndroidEvidenceTest do
  use ExUnit.Case, async: true

  alias Crosswake.SupportMatrix

  @repo_root Path.expand("../../..", __DIR__)

  @above_ceiling "invalid android evidence: above_ceiling"
  @unsupported_level "invalid android evidence: unsupported_level"

  test "android_evidence_levels/0 lists the four levels in ascending order" do
    assert SupportMatrix.android_evidence_levels() == [
             :not_claimed,
             :jvm_hermetic,
             :emulator,
             :device
           ]
  end

  test "android_evidence_ceiling/0 is JVM hermetic" do
    assert SupportMatrix.android_evidence_ceiling() == :jvm_hermetic
  end

  test "android_evidence_label/1 returns the four exact labels" do
    assert SupportMatrix.android_evidence_label(:not_claimed) == "not claimed"
    assert SupportMatrix.android_evidence_label(:jvm_hermetic) == "JVM hermetic proof"
    assert SupportMatrix.android_evidence_label(:emulator) == "emulator evidence"
    assert SupportMatrix.android_evidence_label(:device) == "device evidence"
  end

  test "android_evidence_label/1 raises for an unknown level" do
    error = assert_raise ArgumentError, fn -> SupportMatrix.android_evidence_label(:bogus) end
    assert error.message == @unsupported_level

    assert_raise ArgumentError, fn -> SupportMatrix.android_evidence_label("jvm_hermetic") end
  end

  test "validate_android_evidence!/1 returns levels at or below the ceiling unchanged" do
    assert SupportMatrix.validate_android_evidence!(:not_claimed) == :not_claimed
    assert SupportMatrix.validate_android_evidence!(:jvm_hermetic) == :jvm_hermetic
  end

  test "validate_android_evidence!/1 raises above the ceiling without echoing the value" do
    # Same call CapabilityMap.row/1 makes, so a canonical row at :device cannot be built.
    for level <- [:emulator, :device] do
      error =
        assert_raise ArgumentError, fn -> SupportMatrix.validate_android_evidence!(level) end

      assert error.message == @above_ceiling
      refute error.message =~ Atom.to_string(level)
    end
  end

  test "validate_android_evidence!/1 raises for unknown values without echoing them" do
    for value <- [:bogus, "jvm_hermetic"] do
      error =
        assert_raise ArgumentError, fn -> SupportMatrix.validate_android_evidence!(value) end

      assert error.message == @unsupported_level
      refute error.message =~ "bogus"
    end
  end

  test "android_boundary/0 states the JVM hermetic ceiling and the missing claims" do
    boundary = SupportMatrix.android_boundary()

    assert boundary =~ "JVM hermetic proof"
    assert boundary =~ "no emulator, device or new-feature claim"
  end

  # guides/native_shell.md is hand-authored (hard-wrapped), not a docs.sync projection, so it
  # cannot render from android_boundary/0. It is pinned to the function instead.
  test "hand-written native shell guide carries the boundary sentence exactly once" do
    normalize = fn text -> text |> String.split() |> Enum.join(" ") end

    guide = @repo_root |> Path.join("guides/native_shell.md") |> File.read!() |> normalize.()
    sentence = normalize.(SupportMatrix.android_boundary())

    occurrences = guide |> String.split(sentence) |> length() |> Kernel.-(1)
    assert occurrences == 1
  end
end
