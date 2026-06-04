defmodule Crosswake.Proof.Phase64RuntimeLinePolicyTest do
  use ExUnit.Case, async: false

  alias Crosswake.RuntimeLine.RebuildPolicy
  alias Crosswake.Manifest.Types.Capability

  # -----------------------------------------------------------------------
  # RLINE-01: classify/2, rebuild_required?/1 contract assertions
  # -----------------------------------------------------------------------

  @tag :rline_01
  test "rebuild_required?/1 returns false for :none" do
    assert RebuildPolicy.rebuild_required?(:none) == false
  end

  @tag :rline_01
  test "rebuild_required?/1 returns true for :native_required" do
    assert RebuildPolicy.rebuild_required?(:native_required) == true
  end

  @tag :rline_01
  test "rebuild_required?/1 returns true for :companion_required" do
    assert RebuildPolicy.rebuild_required?(:companion_required) == true
  end

  @tag :rline_01
  test "classify/2 capability-axis class with :native_required rebuild returns {:rebuild_required, :native_shell}" do
    cap = %Capability{id: "haptics", version: "1.0.0", rebuild: :native_required}
    assert RebuildPolicy.classify(:capability_family_add, cap) == {:rebuild_required, :native_shell}
  end

  @tag :rline_01
  test "classify/2 capability-axis class with :companion_required rebuild returns {:rebuild_required, :companion_shell}" do
    cap = %Capability{id: "haptics", version: "1.0.0", rebuild: :companion_required}
    assert RebuildPolicy.classify(:capability_family_add, cap) == {:rebuild_required, :companion_shell}
  end

  @tag :rline_01
  test "classify/2 capability-axis class with :none rebuild returns :ota_safe" do
    cap = %Capability{id: "haptics", version: "1.0.0", rebuild: :none}
    assert RebuildPolicy.classify(:capability_family_add, cap) == :ota_safe
  end

  @tag :rline_01
  test "classify/2 :bridge_schema_change with :native_required returns {:rebuild_required, :native_shell}" do
    cap = %Capability{id: "bridge_test", version: "1.0.0", rebuild: :native_required}
    assert RebuildPolicy.classify(:bridge_schema_change, cap) == {:rebuild_required, :native_shell}
  end

  @tag :rline_01
  test "classify/2 :permission_add with :none returns :ota_safe" do
    cap = %Capability{id: "perm", version: "1.0.0", rebuild: :none}
    assert RebuildPolicy.classify(:permission_add, cap) == :ota_safe
  end

  @tag :rline_01
  test "classify/2 :entitlement_add with :companion_required returns {:rebuild_required, :companion_shell}" do
    cap = %Capability{id: "ent", version: "1.0.0", rebuild: :companion_required}
    assert RebuildPolicy.classify(:entitlement_add, cap) == {:rebuild_required, :companion_shell}
  end

  @tag :rline_01
  test "classify/2 :push_capability_change with :native_required returns {:rebuild_required, :native_shell}" do
    cap = %Capability{id: "push", version: "1.0.0", rebuild: :native_required}
    assert RebuildPolicy.classify(:push_capability_change, cap) == {:rebuild_required, :native_shell}
  end

  @tag :rline_01
  test "classify/2 :url_scheme_change with :none returns :ota_safe" do
    cap = %Capability{id: "url", version: "1.0.0", rebuild: :none}
    assert RebuildPolicy.classify(:url_scheme_change, cap) == :ota_safe
  end

  @tag :rline_01
  test "classify/2 :sdk_floor_bump returns {:rebuild_required, :native_shell} (system class)" do
    assert RebuildPolicy.classify(:sdk_floor_bump, nil) == {:rebuild_required, :native_shell}
  end

  @tag :rline_01
  test "classify/2 :privacy_manifest_entry returns {:rebuild_required, :native_shell} (system class)" do
    assert RebuildPolicy.classify(:privacy_manifest_entry, nil) == {:rebuild_required, :native_shell}
  end

  @tag :rline_01
  test "classify/2 never returns :ota_safe for :companion_required (D-06b)" do
    cap = %Capability{id: "c", version: "1.0.0", rebuild: :companion_required}

    for change_class <- [
          :bridge_schema_change,
          :capability_family_add,
          :permission_add,
          :entitlement_add,
          :push_capability_change,
          :url_scheme_change
        ] do
      verdict = RebuildPolicy.classify(change_class, cap)
      refute verdict == :ota_safe,
             "Expected #{change_class} with :companion_required to not be :ota_safe, got #{inspect(verdict)}"
    end
  end

  @tag :rline_01
  test "classify/2 raises ArgumentError when capability-axis class is given nil capability" do
    assert_raise ArgumentError, fn ->
      RebuildPolicy.classify(:capability_family_add, nil)
    end
  end

  @tag :rline_01
  test "classify/2 raises ArgumentError for all 6 capability-axis classes with nil capability" do
    capability_axis_classes = [
      :bridge_schema_change,
      :capability_family_add,
      :permission_add,
      :entitlement_add,
      :push_capability_change,
      :url_scheme_change
    ]

    for change_class <- capability_axis_classes do
      assert_raise ArgumentError,
                   fn -> RebuildPolicy.classify(change_class, nil) end,
                   "Expected ArgumentError for #{change_class} with nil capability"
    end
  end

  @tag :rline_01
  test "diff/2 returns list of {change_class, verdict} tuples" do
    root_a = make_root()
    root_b = make_root()
    result = RebuildPolicy.diff(root_a, root_b)
    assert is_list(result)

    Enum.each(result, fn item ->
      assert is_tuple(item)
      assert tuple_size(item) == 2
    end)
  end

  # Helper: build a minimal Root struct for diff/2 tests
  defp make_root do
    alias Crosswake.Manifest.Types

    Types.new_root(
      crosswake_version: "0.1.0",
      generated_at: "2026-01-01T00:00:00Z",
      host: Types.new_host(),
      compatibility: Types.new_compatibility(),
      support_matrix: Types.new_support_matrix([
        phoenix: [],
        live_view: [],
        ios: [],
        android: [],
        shells: [],
        capability_families: [],
        package_surfaces: [],
        release_boundaries: [],
        change_classes: []
      ])
    )
  end
end
