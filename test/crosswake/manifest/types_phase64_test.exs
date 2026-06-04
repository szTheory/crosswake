defmodule Crosswake.Manifest.TypesPhase64Test do
  use ExUnit.Case, async: true

  alias Crosswake.Manifest.Types

  # -------------------------------------------------------------------------
  # Task 1: RuntimeLineRow struct + verification_method + required_verification_method
  # -------------------------------------------------------------------------

  describe "RuntimeLineRow struct" do
    test "requires all 6 enforced keys" do
      row =
        Types.new_runtime_line_row(
          runtime_line: "1.x",
          capability_surface: ["haptics", "share"],
          change_class: "native or companion rebuild required",
          ota_safe: false,
          rebuild_required: true,
          evidence_tier: :jvm_hermetic
        )

      assert %Types.RuntimeLineRow{} = row
      assert row.runtime_line == "1.x"
      assert row.capability_surface == ["haptics", "share"]
      assert row.change_class == "native or companion rebuild required"
      assert row.ota_safe == false
      assert row.rebuild_required == true
      assert row.evidence_tier == :jvm_hermetic
    end

    test "missing enforce_key raises at construction time" do
      assert_raise KeyError, fn ->
        Types.new_runtime_line_row(
          runtime_line: "1.x",
          capability_surface: [],
          change_class: "bridge_schema_change",
          ota_safe: true
          # missing rebuild_required and evidence_tier
        )
      end
    end

    test "to_map/1 includes evidence_tier as string" do
      row =
        Types.new_runtime_line_row(
          runtime_line: "1.x",
          capability_surface: ["haptics"],
          change_class: "sdk_floor_bump",
          ota_safe: false,
          rebuild_required: true,
          evidence_tier: :jvm_hermetic
        )

      map = Types.to_map(row)
      assert map["runtime_line"] == "1.x"
      assert map["capability_surface"] == ["haptics"]
      assert map["change_class"] == "sdk_floor_bump"
      assert map["ota_safe"] == false
      assert map["rebuild_required"] == true
      assert map["evidence_tier"] == "jvm_hermetic"
    end

    test "RuntimeLineRow derives Jason.Encoder and encodes to JSON" do
      row =
        Types.new_runtime_line_row(
          runtime_line: "1.x",
          capability_surface: ["haptics"],
          change_class: "permission_add",
          ota_safe: true,
          rebuild_required: false,
          evidence_tier: :device_verified
        )

      assert {:ok, json} = Jason.encode(row)
      assert json =~ "runtime_line"
      assert json =~ "device_verified"
    end
  end

  describe "CapabilitySupportEntry.verification_method" do
    test "defaults to :none when not provided (back-compat)" do
      entry =
        Types.new_capability_support_entry(
          family: "haptics",
          owner: :library,
          package_class: :core,
          proof_class: :merge_blocking,
          rebuild: :not_required
        )

      assert entry.verification_method == :none
    end

    test "preserves explicit verification_method value" do
      entry =
        Types.new_capability_support_entry(
          family: "haptics",
          owner: :library,
          package_class: :core,
          proof_class: :merge_blocking,
          rebuild: :not_required,
          verification_method: :device_verified
        )

      assert entry.verification_method == :device_verified
    end

    test "to_map/1 includes verification_method as string" do
      entry =
        Types.new_capability_support_entry(
          family: "haptics",
          owner: :library,
          package_class: :core,
          proof_class: :merge_blocking,
          rebuild: :not_required,
          verification_method: :jvm_hermetic
        )

      map = Types.to_map(entry)
      assert map["verification_method"] == "jvm_hermetic"
    end

    test "to_map/1 includes verification_method even when :none (not filtered by nil check)" do
      entry =
        Types.new_capability_support_entry(
          family: "haptics",
          owner: :library,
          package_class: :core,
          proof_class: :merge_blocking,
          rebuild: :not_required
        )

      map = Types.to_map(entry)
      assert Map.has_key?(map, "verification_method")
      assert map["verification_method"] == "none"
    end

    test "verification_method is NOT in @enforce_keys — construction without it succeeds" do
      # already tested via default above, but explicit assertion
      assert %Types.CapabilitySupportEntry{verification_method: :none} =
               Types.new_capability_support_entry(
                 family: "share",
                 owner: :library,
                 package_class: :core,
                 proof_class: :advisory,
                 rebuild: :not_required
               )
    end
  end

  describe "PromotionRuleEntry.required_verification_method" do
    test "defaults to :none when not provided (back-compat)" do
      entry = make_promotion_rule_entry([])
      assert entry.required_verification_method == :none
    end

    test "preserves explicit required_verification_method value" do
      entry = make_promotion_rule_entry(required_verification_method: :device_verified)
      assert entry.required_verification_method == :device_verified
    end

    test "to_map/1 includes required_verification_method as string" do
      entry = make_promotion_rule_entry(required_verification_method: :emulator_advisory)
      map = Types.to_map(entry)
      assert map["required_verification_method"] == "emulator_advisory"
    end

    test "required_verification_method is NOT in @enforce_keys — construction without it succeeds" do
      assert %Types.PromotionRuleEntry{required_verification_method: :none} =
               make_promotion_rule_entry([])
    end
  end

  describe "Compatibility struct is unchanged" do
    test "has exactly 5 locked fields — no new field added" do
      fields =
        Map.keys(%Types.Compatibility{
          manifest_schema_version: "1.0.0",
          bridge_protocol_version: "1.0.0",
          native_runtime_version: "1.0.0",
          supported_manifest_sources: [],
          remote_updates: []
        }) -- [:__struct__]

      assert Enum.sort(fields) ==
               Enum.sort([
                 :manifest_schema_version,
                 :bridge_protocol_version,
                 :native_runtime_version,
                 :supported_manifest_sources,
                 :remote_updates
               ])
    end
  end

  describe "SupportEntry (per-platform baseline) gains no new field" do
    test "SupportEntry does not have verification_method" do
      entry = %Types.SupportEntry{target: "ios", version: "18.x", status: :supported}
      refute Map.has_key?(entry, :verification_method)
    end
  end

  # -------------------------------------------------------------------------
  # Task 2: SupportMatrix.rebuild_matrix field
  # -------------------------------------------------------------------------

  describe "SupportMatrix.rebuild_matrix" do
    test "defaults to [] when not provided (back-compat)" do
      matrix =
        Types.new_support_matrix(
          phoenix: [],
          live_view: [],
          ios: [],
          android: [],
          shells: [],
          capability_families: [],
          package_surfaces: [],
          release_boundaries: [],
          change_classes: []
        )

      assert matrix.rebuild_matrix == []
    end

    test "rebuild_matrix is NOT in @enforce_keys — construction without it succeeds" do
      assert %Types.SupportMatrix{rebuild_matrix: []} =
               Types.new_support_matrix(
                 phoenix: [],
                 live_view: [],
                 ios: [],
                 android: [],
                 shells: [],
                 capability_families: [],
                 package_surfaces: [],
                 release_boundaries: [],
                 change_classes: []
               )
    end

    test "new_support_matrix/1 preserves rebuild_matrix when provided" do
      row =
        Types.new_runtime_line_row(
          runtime_line: "1.x",
          capability_surface: ["haptics"],
          change_class: "permission_add",
          ota_safe: false,
          rebuild_required: true,
          evidence_tier: :jvm_hermetic
        )

      matrix =
        Types.new_support_matrix(
          phoenix: [],
          live_view: [],
          ios: [],
          android: [],
          shells: [],
          capability_families: [],
          package_surfaces: [],
          release_boundaries: [],
          change_classes: [],
          rebuild_matrix: [row]
        )

      assert [^row] = matrix.rebuild_matrix
    end

    test "to_map/1 includes rebuild_matrix key mapping rows through to_map/1" do
      row =
        Types.new_runtime_line_row(
          runtime_line: "1.x",
          capability_surface: ["haptics"],
          change_class: "permission_add",
          ota_safe: false,
          rebuild_required: true,
          evidence_tier: :jvm_hermetic
        )

      matrix =
        Types.new_support_matrix(
          phoenix: [],
          live_view: [],
          ios: [],
          android: [],
          shells: [],
          capability_families: [],
          package_surfaces: [],
          release_boundaries: [],
          change_classes: [],
          rebuild_matrix: [row]
        )

      map = Types.to_map(matrix)
      assert Map.has_key?(map, "rebuild_matrix")
      assert [row_map] = map["rebuild_matrix"]
      assert row_map["runtime_line"] == "1.x"
      assert row_map["evidence_tier"] == "jvm_hermetic"
    end

    test "to_map/1 includes rebuild_matrix key even when empty" do
      matrix =
        Types.new_support_matrix(
          phoenix: [],
          live_view: [],
          ios: [],
          android: [],
          shells: [],
          capability_families: [],
          package_surfaces: [],
          release_boundaries: [],
          change_classes: []
        )

      map = Types.to_map(matrix)
      assert Map.has_key?(map, "rebuild_matrix")
      assert map["rebuild_matrix"] == []
    end
  end

  # -------------------------------------------------------------------------
  # Helpers
  # -------------------------------------------------------------------------

  defp make_promotion_rule_entry(overrides) do
    base = [
      claim_id: "test.claim",
      claim_scope: "Test claim scope",
      current_proof_class: :advisory,
      promotes_to: :merge_blocking,
      evidence_class: "test_evidence",
      required_evidence: ["some_check"],
      minimum_consecutive_passes: 2,
      freshness_window: "current release branch",
      failure_budget: "zero merge-blocking failures",
      required_platforms: ["ios"],
      required_docs_anchors: ["guides/test.md"],
      change_class: "native or companion rebuild required",
      action_class: "native_shell",
      check_ids: ["diag.test"],
      demotion_trigger: "Keep or demote when proof is stale."
    ]

    attrs = Keyword.merge(base, overrides)
    Types.new_promotion_rule_entry(attrs)
  end
end
