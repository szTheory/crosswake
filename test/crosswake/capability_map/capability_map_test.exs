defmodule Crosswake.CapabilityMapTest do
  use ExUnit.Case, async: true

  alias Crosswake.CapabilityMap

  @categories [:shipped, :demoed, :missing, :deferred, :next_pack_candidate]

  @display_labels [
    "Available today",
    "Proof-backed example",
    "Demo pressure",
    "Advisory evidence",
    "Future gap",
    "Next-pack candidate"
  ]

  @package_owners [:core, :native_shell, :first_party_companion, :example_docs_only, :deferred]
  @proof_postures [:merge_blocking, :advisory, :not_yet_proven, :unsupported]
  @rebuild_classes [:none, :native_required, :companion_required]

  @route_runtime_owners [
    :live_view,
    :bounded_bridge,
    :native_shell,
    :native_screen,
    :offline_island,
    :backend_projection,
    :future_native_control
  ]

  @required_fields [
    :id,
    :surface,
    :route_or_evidence_source,
    :category,
    :display_label,
    :route_runtime_owner,
    :package_owner,
    :proof_posture,
    :rebuild,
    :denial_fallback,
    :v20_implication
  ]

  @required_ids [
    "route-policy",
    "deep-link-activation",
    "bounded-bridge-app-info",
    "bounded-bridge-haptics",
    "bounded-bridge-share",
    "permissions-status",
    "notification-token",
    "adminpilot-approval-haptics",
    "fieldserv-capture-handoff",
    "fieldserv-scanner",
    "fieldserv-document-scan",
    "fieldserv-media-upload",
    "fieldserv-offline-inspection",
    "learnloop-offline-study",
    "learnloop-native-storage",
    "learnloop-sync-productization",
    "learnloop-paywall-projection",
    "commerce-provider-integration",
    "native-controls-alert-confirm",
    "native-controls-action-menu",
    "native-controls-toast-review"
  ]

  test "D-02/D-04/D-05 capability-map vocabularies are exact and conservative" do
    assert CapabilityMap.categories() == @categories
    assert CapabilityMap.display_labels() == @display_labels
    assert CapabilityMap.package_owners() == @package_owners
    assert CapabilityMap.proof_postures() == @proof_postures
    assert CapabilityMap.route_runtime_owners() == @route_runtime_owners
  end

  test "D-53 rebuild vocabulary mirrors Crosswake.Manifest.Types.Capability.rebuild/0 exactly (Phase 154, CTRL-05)" do
    assert CapabilityMap.rebuild_classes() == @rebuild_classes
  end

  test "D-53 every canonical row declares an explicit rebuild class from the locked vocabulary" do
    for row <- canonical_rows() do
      assert row.rebuild in @rebuild_classes,
             "D-53: #{inspect(row.id)} uses unsupported rebuild class #{inspect(row.rebuild)}"
    end
  end

  test "D-53 rows backed by a real manifest capability match its catalog rebuild class" do
    rows = canonical_rows()

    # These row ids map 1:1 onto Crosswake.Manifest.Builder.capability_catalog/0
    # entries; the guide must never understate or overstate their real rebuild cost.
    assert row!(rows, "deep-link-activation").rebuild == :none
    assert row!(rows, "bounded-bridge-app-info").rebuild == :none
    assert row!(rows, "bounded-bridge-haptics").rebuild == :none
    assert row!(rows, "bounded-bridge-share").rebuild == :none
    assert row!(rows, "permissions-status").rebuild == :none
    assert row!(rows, "notification-token").rebuild == :companion_required
    assert row!(rows, "fieldserv-capture-handoff").rebuild == :native_required
    assert row!(rows, "fieldserv-scanner").rebuild == :companion_required
    assert row!(rows, "fieldserv-document-scan").rebuild == :companion_required
  end

  test "D-03 canonical rows expose every public support-truth axis" do
    rows = canonical_rows()

    assert rows != []

    assert Enum.map(rows, & &1.id) == Enum.uniq(Enum.map(rows, & &1.id)),
           "D-03/D-30: capability map row ids must stay stable and unique"

    for row <- rows do
      for field <- @required_fields do
        assert Map.has_key?(row, field),
               "D-03: #{inspect(row.id)} missing required capability-map field #{field}"
      end

      assert row.category in @categories,
             "D-02: #{inspect(row.id)} uses unsupported category #{inspect(row.category)}"

      assert row.display_label in @display_labels,
             "D-02/D-28: #{inspect(row.id)} uses unsupported display label #{inspect(row.display_label)}"

      assert row.route_runtime_owner in @route_runtime_owners,
             "D-03/D-31: #{inspect(row.id)} hides route runtime ownership"

      assert row.package_owner in @package_owners,
             "D-04: #{inspect(row.id)} uses unsupported package owner #{inspect(row.package_owner)}"

      assert row.proof_posture in @proof_postures,
             "D-05/D-14: #{inspect(row.id)} uses unsupported proof posture #{inspect(row.proof_posture)}"

      refute to_string(row.proof_posture) =~ ~r/screenshot|collateral/i,
             "D-05/D-14: screenshots and collateral are not proof postures"

      assert non_empty?(row.denial_fallback),
             "D-03: #{inspect(row.id)} must name denial or fallback behavior"

      assert non_empty?(row.v20_implication),
             "D-03/D-13: #{inspect(row.id)} must name v20 implication or exclusion"
    end
  end

  test "D-08 through D-12 and D-33/D-34 canonical rows cover v19 evidence and v20 pressure" do
    rows = canonical_rows()

    ids = MapSet.new(Enum.map(rows, & &1.id))
    assert MapSet.subset?(MapSet.new(@required_ids), ids)

    assert row!(rows, "route-policy").package_owner == :core
    assert row!(rows, "deep-link-activation").package_owner == :native_shell
    assert row!(rows, "bounded-bridge-haptics").route_runtime_owner == :bounded_bridge
    assert row!(rows, "bounded-bridge-share").route_runtime_owner == :bounded_bridge

    assert row!(rows, "fieldserv-capture-handoff").route_runtime_owner == :native_screen
    assert row!(rows, "fieldserv-scanner").category in [:missing, :deferred]
    assert row!(rows, "fieldserv-document-scan").category in [:missing, :deferred]

    assert row!(rows, "learnloop-offline-study").route_runtime_owner == :offline_island
    assert row!(rows, "learnloop-native-storage").package_owner == :deferred
    assert row!(rows, "learnloop-sync-productization").package_owner == :deferred

    paywall = row!(rows, "learnloop-paywall-projection")
    assert paywall.route_runtime_owner == :backend_projection
    assert paywall.denial_fallback =~ ~r/backend/i

    commerce = row!(rows, "commerce-provider-integration")
    assert commerce.package_owner == :deferred
    assert commerce.v20_implication =~ ~r/Commerce\/Paywall Productionization|later/i

    for id <- [
          "native-controls-alert-confirm",
          "native-controls-action-menu",
          "native-controls-toast-review"
        ] do
      row = row!(rows, id)
      assert row.category == :next_pack_candidate
      assert row.display_label == "Next-pack candidate"
      assert row.route_runtime_owner == :future_native_control
    end
  end

  test "D-22 example, deferred, unsupported, and advisory rows cannot render as broad shipped support" do
    rows = canonical_rows()

    for row <- rows do
      if row.package_owner in [:example_docs_only, :deferred] do
        refute row.category == :shipped,
               "D-22: #{row.id} is #{row.package_owner} but renders as shipped"

        refute row.display_label == "Available today",
               "D-22: #{row.id} is #{row.package_owner} but uses a broad available-today label"
      end

      if row.proof_posture in [:advisory, :not_yet_proven, :unsupported] do
        refute row.display_label == "Available today",
               "D-05/D-22: #{row.id} has #{row.proof_posture} posture but renders as broad shipped support"
      end
    end
  end

  test "D-12/D-33/D-34 offline and commerce rows keep authority claims honest" do
    rows = canonical_rows()

    offline = row!(rows, "learnloop-offline-study")
    refute offline.denial_fallback =~ ~r/everything works offline|local-first mutation/i
    assert offline.denial_fallback =~ ~r/outbox|browser-owned|offline island|reconciliation/i

    storage = row!(rows, "learnloop-native-storage")
    assert storage.v20_implication =~ ~r/Offline Sync\/Native Storage Productization|later/i
    refute storage.display_label == "Available today"

    paywall = row!(rows, "learnloop-paywall-projection")
    assert paywall.denial_fallback =~ ~r/backend/i
    refute paywall.denial_fallback =~ ~r/device grants|storefront grants|subscriber truth/i

    provider = row!(rows, "commerce-provider-integration")
    assert provider.v20_implication =~ ~r/Commerce\/Paywall Productionization|later/i
    refute provider.display_label == "Available today"
  end

  defp canonical_rows do
    CapabilityMap.canonical()
    |> Enum.map(&normalize_row/1)
  end

  defp normalize_row(%_{} = row), do: Map.from_struct(row)
  defp normalize_row(row) when is_map(row), do: row

  defp row!(rows, id) do
    Enum.find(rows, &(&1.id == id)) || flunk("expected capability-map row #{inspect(id)}")
  end

  defp non_empty?(value), do: is_binary(value) and String.trim(value) != ""
end
