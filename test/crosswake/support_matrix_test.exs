defmodule Crosswake.SupportMatrixTest do
  use ExUnit.Case, async: true

  alias Crosswake.SupportMatrix

  test "provider adapter promotion rules stay criteria-as-code and demotable" do
    claim_ids = [
      "purchase_intent.provider.storekit",
      "restore_intent.provider.storekit",
      "purchase_intent.provider.play_billing",
      "restore_intent.provider.play_billing"
    ]

    rules_by_id =
      SupportMatrix.promotion_rules()
      |> Map.new(fn rule -> {rule.claim_id, rule} end)

    for claim_id <- claim_ids do
      rule = Map.fetch!(rules_by_id, claim_id)

      assert rule.action_class == "provider_adapter"
      assert rule.current_proof_class == :advisory
      assert rule.promotes_to == :merge_blocking
      assert rule.minimum_consecutive_passes >= 1
      assert is_binary(rule.freshness_window) and rule.freshness_window != ""
      assert is_list(rule.check_ids) and rule.check_ids != []
      assert is_list(rule.required_docs_anchors) and rule.required_docs_anchors != []
      assert is_binary(rule.demotion_trigger) and rule.demotion_trigger != ""

      assert "deterministic adapter contract proof" in rule.required_evidence
      assert "backend reconciliation authority proof" in rule.required_evidence
      assert "docs-contract parity proof" in rule.required_evidence
      assert "advisory storefront/provider lane evidence" in rule.required_evidence
    end
  end

  test "provider corridor support keeps shipped seams separate from advisory proof posture" do
    corridors =
      SupportMatrix.commerce_corridors()
      |> Map.new(fn corridor -> {corridor.corridor_role, corridor} end)

    for role <- ["purchase_intent", "restore_intent"] do
      corridor = Map.fetch!(corridors, role)

      assert corridor.owner_posture == "native_or_companion_required"
      assert corridor.native_rebuild_required
      assert corridor.proof_class == :merge_blocking
      assert corridor.advisory_provider_proof
    end
  end
end
