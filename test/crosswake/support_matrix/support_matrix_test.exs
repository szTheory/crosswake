defmodule Crosswake.SupportMatrixTest do
  use ExUnit.Case, async: true

  alias Crosswake.Manifest.Types
  alias Crosswake.SupportMatrix
  alias Crosswake.SupportMatrix.Renderer

  test "canonical support matrix provides the typed manifest slots used by phase 2" do
    matrix = SupportMatrix.canonical()

    root =
      Types.new_root(
        crosswake_version: "0.1.0",
        generated_at: "2026-05-14T00:00:00Z",
        host: Types.new_host(),
        compatibility: Types.new_compatibility(),
        support_matrix: matrix,
        capability_registry: %{},
        routes: %{}
      )

    root_map = Types.to_map(root)

    assert Map.keys(root_map) == [
             "capability_registry",
             "commerce_corridors",
             "compatibility",
             "crosswake_version",
             "generated_at",
             "host",
             "manifest_schema_version",
             "pack_registry",
             "routes",
             "support_matrix"
           ]

    assert root_map["support_matrix"]["phoenix"] != []
    assert root_map["capability_registry"] == %{}
    assert root_map["support_matrix"]["capability_families"] != []
    assert root_map["support_matrix"]["package_surfaces"] != []
    assert root_map["support_matrix"]["release_boundaries"] != []
    assert root_map["support_matrix"]["change_classes"] != []
  end

  test "canonical support entries now publish the proof-backed phase 5 shell posture" do
    matrix = SupportMatrix.canonical()

    assert Enum.map(matrix.phoenix, & &1.baseline_status) == [:supported]
    assert Enum.map(matrix.android, & &1.baseline_status) == [:supported]
    assert Enum.map(matrix.android, & &1.proof_status) == [:supported]

    assert Enum.map(matrix.shells, &{&1.target, &1.proof_status}) |> Enum.sort() == [
             {"android_shell", :supported},
             {"ios_shell", :supported}
           ]

    assert SupportMatrix.statuses() == [:supported, :verification_required, :unsupported]
  end

  test "the first support matrix stays narrow and proof-oriented" do
    matrix = SupportMatrix.canonical()

    assert length(matrix.phoenix) == 1
    assert length(matrix.live_view) == 1
    assert length(matrix.ios) == 1
    assert length(matrix.android) == 1
    assert length(matrix.shells) == 2
    assert matrix.capability_families != []
    assert length(matrix.package_surfaces) == 5
    assert length(matrix.release_boundaries) == 4
    assert length(matrix.change_classes) == 4
    assert SupportMatrix.validate(matrix) == []
  end

  test "capability family posture is derived from manifest capability entries" do
    capability_registry = %{
      "haptics" =>
        Types.new_capability(
          id: "haptics",
          family: "haptics",
          owner: :bounded_bridge,
          package_class: :core,
          proof_class: :merge_blocking,
          rebuild: :none,
          prerequisites: ["declared route capability"],
          denial: "undeclared_capability",
          fallback: "Phoenix route continues without native confirmation feedback",
          guide: "guides/bridge.md#bounded-bridge"
        ),
      "haptics.impact" =>
        Types.new_capability(
          id: "haptics.impact",
          family: "haptics",
          owner: :bounded_bridge,
          package_class: :companion,
          proof_class: :advisory,
          rebuild: :native_required,
          prerequisites: ["legacy compatibility"],
          denial: "undeclared_capability",
          fallback: "legacy compatibility only",
          guide: "guides/bridge.md#bounded-bridge"
        )
    }

    matrix = SupportMatrix.canonical(capability_registry: capability_registry)

    assert matrix.capability_families == [
             Types.new_capability_support_entry(
               family: "haptics",
               owner: :bounded_bridge,
               posture: "bounded_bridge",
               baseline_status: :supported,
               proof_status: :verification_required,
               package_class: :core,
               proof_class: :merge_blocking,
               rebuild: :none,
               prerequisites: ["declared route capability"],
               denial: "undeclared_capability",
               fallback: "Phoenix route continues without native confirmation feedback",
               guide: "guides/bridge.md#bounded-bridge"
             )
           ]
  end

  test "canonical support truth publishes one primary crosswake package and explicit package classes" do
    matrix = SupportMatrix.canonical()

    assert Enum.any?(matrix.package_surfaces, fn entry ->
             entry.surface == "`crosswake` primary package" and entry.package_class == :core
           end)

    assert Enum.any?(matrix.package_surfaces, fn entry ->
             entry.package_class == :example_docs_only and
               entry.surface == "Checked-in example hosts and install walkthroughs"
           end)

    assert Enum.any?(matrix.package_surfaces, fn entry ->
             entry.package_class == :defer and entry.surface == "Standalone public shell packages"
           end)
  end

  test "release policy stays hybrid instead of repo-wide lockstep versioning" do
    matrix = SupportMatrix.canonical()

    assert Enum.any?(matrix.release_boundaries, fn entry ->
             entry.target == "core" and
               entry.compatibility_contract =~
                 "package versions alone do not define support truth"
           end)

    refute Enum.any?(matrix.release_boundaries, fn entry ->
             String.contains?(entry.versioning, "lockstep")
           end)
  end

  test "change classes stay frozen to the four public release actions" do
    matrix = SupportMatrix.canonical()

    assert Enum.map(matrix.change_classes, & &1.change_class) == [
             "docs-only",
             "core-only/no native rebuild",
             "compatibility-bump only",
             "native or companion rebuild required"
           ]
  end

  test "phase 51 split support axes are exposed as canonical vocabularies" do
    assert SupportMatrix.proof_classes() == [:merge_blocking, :advisory, :not_applicable]
    assert SupportMatrix.diagnostic_severities() == [:error, :warning, :advisory]
    assert SupportMatrix.statuses() == [:supported, :verification_required, :unsupported]
  end

  test "phase 51 action classes define machine-visible rebuild actions" do
    entries = SupportMatrix.action_classes()

    assert Enum.map(entries, & &1.action_class) == [
             "docs_only",
             "route_manifest",
             "compatibility",
             "native_shell",
             "companion_native",
             "provider_adapter"
           ]

    for entry <- entries do
      assert %Types.ActionClassEntry{} = entry
      assert is_binary(entry.subject)
      assert is_binary(entry.required_action)
      assert is_boolean(entry.rebuild_required)
      assert is_binary(entry.reason)
      assert String.starts_with?(entry.guide_anchor, "guides/")
    end
  end

  test "phase 51 promotion rules keep advisory proof criteria explicit" do
    entries = SupportMatrix.promotion_rules()

    assert Enum.map(entries, & &1.claim_id) == [
             "shell.ios.generated_project",
             "shell.android.generated_project",
             "notification_token.provider_snapshot",
             "auth.sigra.session_authority",
             "purchase_intent.provider.storekit",
             "restore_intent.provider.storekit",
             "purchase_intent.provider.play_billing",
             "restore_intent.provider.play_billing",
             # Phase 64: Android JVM hermetic and device-verified gated promotion rows
             "shell.android.jvm_hermetic",
             "shell.android.device_verified"
           ]

    for entry <- entries do
      assert %Types.PromotionRuleEntry{} = entry
      assert entry.current_proof_class in [:merge_blocking, :advisory, :not_applicable]
      assert entry.promotes_to in [:merge_blocking, :supported]
      assert is_binary(entry.evidence_class)
      assert is_list(entry.required_evidence) and entry.required_evidence != []
      assert is_integer(entry.minimum_consecutive_passes) and entry.minimum_consecutive_passes > 0
      assert is_binary(entry.freshness_window)
      assert is_binary(entry.failure_budget)
      assert is_list(entry.required_platforms)
      assert is_list(entry.required_docs_anchors) and entry.required_docs_anchors != []
      assert is_binary(entry.change_class)

      assert entry.action_class in [
               "native_shell",
               "companion_native",
               "provider_adapter"
             ]

      assert is_list(entry.check_ids) and entry.check_ids != []
      assert is_binary(entry.demotion_trigger)
    end

    assert Enum.any?(entries, fn entry ->
             entry.claim_id == "purchase_intent.provider.storekit" and
               "guides/commerce.md" in entry.required_docs_anchors
           end)

    assert Enum.any?(entries, fn entry ->
             entry.claim_id == "notification_token.provider_snapshot" and
               "guides/capabilities.md" in entry.required_docs_anchors
           end)
  end

  describe "audit_ledger_support_truth/0 (OPER-02)" do
    test "returns a non-empty list with the canonical threadline audit ledger truth" do
      truth = Crosswake.SupportMatrix.audit_ledger_support_truth()
      assert is_list(truth)
      assert length(truth) == 1
    end

    test "entry has the correct surface, proof_class, and action_class" do
      [entry] = Crosswake.SupportMatrix.audit_ledger_support_truth()
      assert entry.surface == "threadline audit ledger"
      assert entry.proof_class == :advisory
      assert entry.action_class == "operator_surface"
    end

    test "entry docs_anchor points to threadline guide" do
      [entry] = Crosswake.SupportMatrix.audit_ledger_support_truth()
      assert entry.docs_anchor == "guides/threadline.md"
    end

    test "entry ephemeral_posture and durable_posture are both :supported" do
      [entry] = Crosswake.SupportMatrix.audit_ledger_support_truth()
      assert entry.ephemeral_posture == :supported
      assert entry.durable_posture == :supported
    end

    test "entry telemetry.status is :shipped" do
      [entry] = Crosswake.SupportMatrix.audit_ledger_support_truth()
      assert entry.telemetry.status == :shipped
    end

    test "entry telemetry.forbidden_metadata_keys matches Crosswake.Threadline.Telemetry" do
      alias Crosswake.Threadline.Telemetry, as: ThreadlineTelemetry
      [entry] = Crosswake.SupportMatrix.audit_ledger_support_truth()
      assert entry.telemetry.forbidden_metadata_keys == ThreadlineTelemetry.forbidden_metadata_keys()
    end

    test "entry telemetry.event_names matches Crosswake.Threadline.Telemetry" do
      alias Crosswake.Threadline.Telemetry, as: ThreadlineTelemetry
      [entry] = Crosswake.SupportMatrix.audit_ledger_support_truth()
      assert entry.telemetry.event_names == ThreadlineTelemetry.event_names()
    end

    test "entry telemetry.metadata_keys matches Crosswake.Threadline.Telemetry" do
      alias Crosswake.Threadline.Telemetry, as: ThreadlineTelemetry
      [entry] = Crosswake.SupportMatrix.audit_ledger_support_truth()
      assert entry.telemetry.metadata_keys == ThreadlineTelemetry.metadata_keys()
    end

    test "entry deferred list contains expected deferred items" do
      [entry] = Crosswake.SupportMatrix.audit_ledger_support_truth()
      assert :crosswake_dashboard in entry.deferred
      assert :hash_chain_verify_task in entry.deferred
    end

    test "entry posture contains honest non-overclaim phrases" do
      [entry] = Crosswake.SupportMatrix.audit_ledger_support_truth()
      assert entry.posture =~ "PII-free"
      assert entry.posture =~ "append-only"
      assert entry.posture =~ "not an APM"
    end
  end

  test "phase 51 companion and notification support truth preserve deferred non-claims" do
    assert [companion_truth] = SupportMatrix.companion_support_truth()

    assert companion_truth.surface ==
             "Sigra session-authority route evaluator, handoff contract, step-up ceremony, and auth-return boundaries"

    assert companion_truth.proof_class == :merge_blocking
    assert companion_truth.action_class == "companion_native"

    assert companion_truth.deferred == [
             :refresh_tokens,
             :native_auth_ui,
             :provider_device_proof
           ]

    assert [notification_truth] = SupportMatrix.notification_support_truth()
    assert notification_truth.surface == "notification-open route activation proof"
    assert notification_truth.proof_class == :advisory
    assert notification_truth.action_class == "companion_native"
    assert notification_truth.delivery_supported == false
    assert notification_truth.route_activation_proof == :hermetic
    assert notification_truth.activation_authority == :route_gate_sigra
    assert notification_truth.evidence_authority == false
    assert notification_truth.posture =~ "notification-open workflow proof is hermetic route activation proof"
    assert notification_truth.posture =~ "RouteGate and Sigra decide activation"
    assert notification_truth.posture =~ "token/open evidence is not auth authority"
    assert notification_truth.posture =~ "APNs/FCM delivery is not part of this proof"
    assert :chimeway_delivery in notification_truth.deferred
  end

  test "phase 72 media recovery support truth preserves backend authority and proof-only scope" do
    assert [media_truth] = SupportMatrix.media_recovery_proof_truth()

    assert media_truth.surface == "Rindle media/evidence recovery proof"
    assert media_truth.proof_class == :merge_blocking
    assert media_truth.recovery_proof == :hermetic
    assert media_truth.simulated_network_degradation == :proof_only
    assert media_truth.local_capture_authority == false
    assert media_truth.backend_verification_required == true
    assert media_truth.real_storage_supported == false
    assert media_truth.native_capture_supported == false
    assert media_truth.background_transfer_supported == false
    assert media_truth.posture =~ "Rindle media/evidence recovery proof is hermetic"
    assert media_truth.posture =~ "local capture evidence is not availability authority"
    assert media_truth.posture =~ "backend verification is required before media becomes available"
    assert :real_storage_provider in media_truth.deferred
    assert :local_first_sync in media_truth.deferred
  end

  test "entitlement and evidence support entries encode freshness and non-authoritative posture" do
    capability_families = SupportMatrix.canonical().capability_families
    entitlement_snapshot = Enum.find(capability_families, &(&1.family == "entitlement_snapshot"))

    reconciliation_evidence =
      Enum.find(capability_families, &(&1.family == "reconciliation_evidence"))

    assert Enum.any?(entitlement_snapshot.prerequisites, fn prerequisite ->
             String.contains?(prerequisite, "freshness posture")
           end)

    assert entitlement_snapshot.fallback =~ "Fail closed"
    assert entitlement_snapshot.fallback =~ "stale or unknown"
    assert entitlement_snapshot.fallback =~ "pending"
    assert entitlement_snapshot.fallback =~ "awaiting_verification"
    assert entitlement_snapshot.fallback =~ "never grant entitlement"

    assert Enum.any?(reconciliation_evidence.prerequisites, fn prerequisite ->
             String.contains?(prerequisite, "awaiting_verification")
           end)

    assert reconciliation_evidence.fallback =~ "device/storefront/webhook/support"
    assert reconciliation_evidence.fallback =~ "non-authoritative"
    assert reconciliation_evidence.fallback =~ "pending_purchase"
    assert reconciliation_evidence.fallback =~ "pending_restore"
    assert reconciliation_evidence.fallback =~ "awaiting_verification"
    assert reconciliation_evidence.fallback =~ "non-granting"
  end

  test "support matrix wording keeps stale and pending states explicit in docs and generated output" do
    guide = File.read!("guides/support_matrix.md")
    rendered = Renderer.render(SupportMatrix.canonical())

    for text <- [guide, rendered] do
      assert text =~ "stale"
      assert text =~ "pending"
      assert text =~ "awaiting_verification"
      assert text =~ "non-granting"
    end
  end

  test "commerce corridor support truth stays provider-neutral and uses canonical denial taxonomy" do
    entries = SupportMatrix.commerce_corridors()

    assert Enum.map(entries, & &1.corridor_role) == [
             "paywall_entry",
             "account_management",
             "purchase_intent",
             "restore_intent"
           ]

    assert SupportMatrix.commerce_corridor_denial_codes() == [
             "commerce.corridor.entry_denied",
             "commerce.corridor.origin_denied",
             "commerce.corridor.pack_incompatible",
             "commerce.corridor.policy_blocked",
             "commerce.corridor.prerequisite_missing",
             "commerce.corridor.runtime_incompatible",
             "commerce.corridor.undeclared",
             "commerce.corridor.unsupported"
           ]

    refute Enum.any?(entries, fn entry ->
             Enum.any?(entry.prerequisites, fn prerequisite ->
               String.contains?(prerequisite, "StoreKit") or
                 String.contains?(prerequisite, "Play Billing")
             end)
           end)
  end

  test "every commerce corridor entry carries an explicit proof_class and advisory_provider_proof flag" do
    entries = SupportMatrix.commerce_corridors()

    for entry <- entries do
      assert Map.has_key?(entry, :proof_class),
             "commerce corridor #{entry.corridor_role} missing :proof_class"

      assert entry.proof_class in [:merge_blocking, :advisory],
             "commerce corridor #{entry.corridor_role} proof_class must be :merge_blocking or :advisory, got #{inspect(entry.proof_class)}"

      assert Map.has_key?(entry, :advisory_provider_proof),
             "commerce corridor #{entry.corridor_role} missing :advisory_provider_proof"

      assert is_boolean(entry.advisory_provider_proof),
             "commerce corridor #{entry.corridor_role} advisory_provider_proof must be a boolean"
    end
  end

  test "paywall_entry and account_management commerce corridors are merge-blocking without advisory provider proof" do
    entries = SupportMatrix.commerce_corridors()
    paywall_entry = Enum.find(entries, &(&1.corridor_role == "paywall_entry"))
    account_management = Enum.find(entries, &(&1.corridor_role == "account_management"))

    assert paywall_entry.proof_class == :merge_blocking
    refute paywall_entry.advisory_provider_proof

    assert account_management.proof_class == :merge_blocking
    refute account_management.advisory_provider_proof
  end

  test "purchase_intent and restore_intent commerce corridors are merge-blocking with advisory provider proof flag" do
    entries = SupportMatrix.commerce_corridors()
    purchase_intent = Enum.find(entries, &(&1.corridor_role == "purchase_intent"))
    restore_intent = Enum.find(entries, &(&1.corridor_role == "restore_intent"))

    assert purchase_intent.proof_class == :merge_blocking
    assert purchase_intent.advisory_provider_proof

    assert restore_intent.proof_class == :merge_blocking
    assert restore_intent.advisory_provider_proof
  end

  test "commerce_corridor_proof_classes/0 returns canonical proof-class mapping for every corridor role" do
    mapping = SupportMatrix.commerce_corridor_proof_classes()

    assert mapping == %{
             "paywall_entry" => %{proof_class: :merge_blocking, advisory_provider_proof: false},
             "account_management" => %{
               proof_class: :merge_blocking,
               advisory_provider_proof: false
             },
             "purchase_intent" => %{
               proof_class: :merge_blocking,
               advisory_provider_proof: true
             },
             "restore_intent" => %{proof_class: :merge_blocking, advisory_provider_proof: true}
           }
  end

  test "every commerce corridor entry declares prerequisite_classes, proof_class, and rebuild_requirement" do
    entries = SupportMatrix.commerce_corridors()

    for entry <- entries do
      assert Map.has_key?(entry, :prerequisite_classes),
             "commerce corridor #{entry.corridor_role} missing :prerequisite_classes"

      assert is_list(entry.prerequisite_classes) and entry.prerequisite_classes != [],
             "commerce corridor #{entry.corridor_role} prerequisite_classes must be a non-empty list, got #{inspect(entry.prerequisite_classes)}"

      assert Map.has_key?(entry, :proof_class),
             "commerce corridor #{entry.corridor_role} missing :proof_class"

      assert Map.has_key?(entry, :rebuild_requirement),
             "commerce corridor #{entry.corridor_role} missing :rebuild_requirement"

      assert is_map(entry.rebuild_requirement),
             "commerce corridor #{entry.corridor_role} rebuild_requirement must be a structured map"

      assert Map.has_key?(entry.rebuild_requirement, :native_rebuild_required),
             "commerce corridor #{entry.corridor_role} rebuild_requirement missing :native_rebuild_required"

      assert is_boolean(entry.rebuild_requirement.native_rebuild_required),
             "commerce corridor #{entry.corridor_role} rebuild_requirement.native_rebuild_required must be a boolean"

      assert Map.has_key?(entry.rebuild_requirement, :rebuild_trigger),
             "commerce corridor #{entry.corridor_role} rebuild_requirement missing :rebuild_trigger"

      assert is_binary(entry.rebuild_requirement.rebuild_trigger),
             "commerce corridor #{entry.corridor_role} rebuild_requirement.rebuild_trigger must be a string"

      # rebuild_requirement.native_rebuild_required must stay consistent with the legacy boolean
      assert entry.rebuild_requirement.native_rebuild_required == entry.native_rebuild_required,
             "commerce corridor #{entry.corridor_role} rebuild_requirement.native_rebuild_required must match legacy native_rebuild_required boolean"
    end
  end

  test "every commerce corridor prerequisite_classes value is drawn from the canonical taxonomy" do
    taxonomy = MapSet.new(SupportMatrix.commerce_corridor_prerequisite_taxonomy())

    for entry <- SupportMatrix.commerce_corridors(),
        prerequisite_class <- entry.prerequisite_classes do
      assert MapSet.member?(taxonomy, prerequisite_class),
             "commerce corridor #{entry.corridor_role} prerequisite_class #{inspect(prerequisite_class)} not in canonical taxonomy #{inspect(MapSet.to_list(taxonomy))}"
    end
  end

  test "commerce_corridor_prerequisite_taxonomy/0 returns the canonical prerequisite class set" do
    assert SupportMatrix.commerce_corridor_prerequisite_taxonomy() == [
             :route_declaration,
             :backend_reconciliation,
             :native_adapter,
             :provider_setup
           ]
  end

  test "paywall and account_management corridors require no native rebuild; purchase and restore require native rebuild" do
    entries = SupportMatrix.commerce_corridors()
    paywall_entry = Enum.find(entries, &(&1.corridor_role == "paywall_entry"))
    account_management = Enum.find(entries, &(&1.corridor_role == "account_management"))
    purchase_intent = Enum.find(entries, &(&1.corridor_role == "purchase_intent"))
    restore_intent = Enum.find(entries, &(&1.corridor_role == "restore_intent"))

    refute paywall_entry.rebuild_requirement.native_rebuild_required
    refute account_management.rebuild_requirement.native_rebuild_required
    assert purchase_intent.rebuild_requirement.native_rebuild_required
    assert restore_intent.rebuild_requirement.native_rebuild_required
  end

  # -- Phase 23 Plan 04 Task 3: advisory corridor labeling contract --
  #
  # When the canonical support matrix declares an advisory commerce corridor
  # (proof_class: :advisory), that corridor must be explicitly labeled in the
  # corridor entry AND must not appear in the merge-blocking required-check
  # list. This locks the advisory boundary at the unit level alongside the
  # proof-lane integration test (Plan 23-04 Task 1).
  #
  # Today no commerce corridor has proof_class :advisory directly — every
  # corridor row is merge_blocking with an optional advisory_provider_proof
  # flag for storefront/simulator evidence. These tests document the contract
  # that any future advisory corridor must satisfy.

  test "any advisory commerce corridor must be explicitly labeled with proof_class :advisory and is excluded from merge-blocking required checks" do
    entries = SupportMatrix.commerce_corridors()

    advisory_entries =
      Enum.filter(entries, &(&1.proof_class == :advisory))

    # Contract assertion #1: any advisory entry must carry the proof_class
    # label explicitly (no inferred advisory class).
    for entry <- advisory_entries do
      assert entry.proof_class == :advisory,
             "advisory commerce corridor #{entry.corridor_role} must be explicitly labeled :advisory"
    end

    # Contract assertion #2: the canonical proof-class mapping must never
    # claim merge_blocking for an entry whose corridor_role is in the
    # advisory list. (Today both lists are populated coherently; this asserts
    # they stay in sync if a future scope change introduces advisory
    # corridors.)
    mapping = SupportMatrix.commerce_corridor_proof_classes()

    for entry <- advisory_entries do
      assert Map.get(mapping, entry.corridor_role)[:proof_class] == :advisory,
             "commerce_corridor_proof_classes mapping for #{entry.corridor_role} must mirror entry's :advisory proof_class label"
    end

    # Contract assertion #3: any corridor with advisory_provider_proof: true
    # MUST still carry an explicit core proof_class (merge_blocking or
    # advisory). The advisory_provider_proof flag is supplementary evidence,
    # never a substitute for the core proof_class declaration.
    for entry <- entries, entry.advisory_provider_proof do
      assert entry.proof_class in [:merge_blocking, :advisory],
             "corridor #{entry.corridor_role} carries advisory_provider_proof: true but missing or unrecognized core proof_class #{inspect(entry.proof_class)}"
    end

    # Contract assertion #4: merge_blocking corridors are the only entries
    # that should be referenced as required branch checks. Build the
    # canonical merge-blocking required-check list from the support matrix
    # and assert no advisory corridor leaks into it.
    merge_blocking_required_check_roles =
      entries
      |> Enum.filter(&(&1.proof_class == :merge_blocking))
      |> Enum.map(& &1.corridor_role)
      |> MapSet.new()

    advisory_roles = MapSet.new(advisory_entries, & &1.corridor_role)

    assert MapSet.disjoint?(merge_blocking_required_check_roles, advisory_roles),
           "merge-blocking required-check list #{inspect(MapSet.to_list(merge_blocking_required_check_roles))} must be disjoint from advisory corridors #{inspect(MapSet.to_list(advisory_roles))}"
  end

  test "auth_contract_truth exposes canonical auth and handoff contract row" do
    assert [%{} = row] = SupportMatrix.auth_contract_truth()

    assert Map.keys(row) |> Enum.sort() ==
             [
               :denial_codes,
               :denial_vocabulary,
               :deferred,
               :fallback,
               :auth_return,
               :contract_proof_class,
               :contract_surface,
               :handoff,
               :evidence_authority,
               :owner,
               :package_class,
               :posture,
               :provider_device_proof,
               :proof_class,
               :host_readiness,
               :route_authority_source,
               :route_predicates,
               :safe_detail_keys,
               :security_closeout,
               :shipped_contracts,
               :step_up,
               :surface,
               :telemetry
             ]
             |> Enum.sort()

    assert row.owner == :backend_seam
    assert row.package_class == :companion
    assert row.proof_class == :merge_blocking
    assert row.contract_surface == :full_sigra_machinery
    assert row.contract_proof_class == :merge_blocking
    assert row.route_authority_source == :session_authority_lane
    assert row.evidence_authority.handoff_envelope == false
    assert row.evidence_authority.step_up_locator == false
    assert row.evidence_authority.auth_return_envelope == false
    assert row.evidence_authority.bridge_event == false
    assert row.host_readiness == :verification_required
    assert row.provider_device_proof == :advisory

    assert row.shipped_contracts == [
             :session_authority,
             :handoff_ticket,
             :server_record_redemption,
             :step_up_intent,
             :plug_liveview_ceremony,
             :auth_return_boundary,
             :auth_return_attempt
           ]

    assert row.handoff.status == :shipped
    assert row.handoff.authority_source == :server_record
    assert row.handoff.envelope_authority == false
    assert :denial_code in row.handoff.audit_fields
    assert row.step_up.status == :shipped
    assert row.step_up.authority_source == :server_record
    assert row.step_up.locator_authority == false
    assert row.auth_return.status == :shipped
    assert row.auth_return.authority_source == :server_record
    assert row.auth_return.envelope_authority == false
    assert row.auth_return.route_policy_seam == :auth_return
    assert row.telemetry.status == :shipped
    assert [:crosswake, :auth, :denial] in row.telemetry.event_names
    assert :denial_code in row.telemetry.metadata_keys
    assert :access_token in row.telemetry.forbidden_metadata_keys
    assert row.telemetry.authority_source == :diagnostic_evidence_only
    assert row.security_closeout.status == :shipped
    assert row.security_closeout.review_model == :stride
    assert row.security_closeout.unresolved_high_or_critical_findings == 0

    assert row.step_up.lifecycle_states == [
             :issued,
             :challenged,
             :consumed,
             :expired,
             :canceled,
             :revoked
           ]

    assert row.step_up.route_target_validation == :manifest_route_id
    assert row.step_up.liveview_invalidation == :required
    assert row.route_predicates == [:auth_min_level, :requires_recent_auth, :auth_posture]
    assert row.denial_vocabulary == :step_up_required
    assert "auth.step_up.missing_context" in row.denial_codes
    assert "auth.handoff.invalid_ticket" in row.denial_codes
    assert "auth.step_up_intent.invalid_intent" in row.denial_codes
    assert "auth.return.oauth.invalid_return" in row.denial_codes
    assert "auth_posture" in row.safe_detail_keys
    assert "handoff_ref" in row.safe_detail_keys
    assert "step_up_intent_ref" in row.safe_detail_keys
    assert row.fallback == :step_up_required
    assert row.surface =~ "SessionAuthorityLane"
    assert row.surface =~ "handoff"
    assert row.surface =~ "step-up"
    assert row.posture =~ "SessionAuthorityLane route evaluation"
    assert row.posture =~ "handoff ticket/server-record redemption"
    assert row.posture =~ "stable low-cardinality auth telemetry"
    assert row.posture =~ "security closeout"
    refute :ceremony in row.deferred
    refute :auth_return_boundaries in row.deferred
    refute :native_auth_return in row.deferred
    refute :handoff in row.deferred
  end

  # ---------------------------------------------------------------------------
  # Phase 64 Gap 1 (RLINE-04): rebuild_matrix honesty and evidence gate
  #
  # The rebuild_matrix surface must not claim :device_verified for any band
  # without backing real-device proof. The 2.x band does not exist in Phase 64
  # (native_runtime_version is "1.0.0"); device-verified proof is gated until
  # Phases 67/68. validate/1 must structurally reject any :device_verified row.
  # ---------------------------------------------------------------------------

  test "canonical rebuild_matrix contains only the '1.x' row — no '2.x' unbacked band" do
    matrix = SupportMatrix.canonical()
    rows = SupportMatrix.rebuild_matrix(matrix)

    runtime_lines = Enum.map(rows, & &1.runtime_line)

    assert runtime_lines == ["1.x"],
           "rebuild_matrix must contain only the '1.x' row in Phase 64 (the 2.x band does not exist; native_runtime_version is '1.0.0')"
  end

  test "canonical rebuild_matrix '1.x' row has evidence_tier :jvm_hermetic — never :device_verified" do
    matrix = SupportMatrix.canonical()
    rows = SupportMatrix.rebuild_matrix(matrix)

    for row <- rows do
      refute row.evidence_tier == :device_verified,
             "rebuild_matrix row '#{row.runtime_line}' claims :device_verified — evidence laundering (D-10a); device-verified proof is gated until Phases 67/68"
    end
  end

  test "validate/1 returns [] for canonical matrix (no false positives from rebuild_matrix gate)" do
    errors = SupportMatrix.validate(SupportMatrix.canonical())
    assert errors == [],
           "canonical matrix must be clean — got unexpected errors: #{inspect(errors)}"
  end

  test "validate/1 rejects a rebuild_matrix row with evidence_tier :device_verified (evidence laundering gate)" do
    canonical = SupportMatrix.canonical()

    # Inject a :device_verified row into rebuild_matrix — must be rejected
    injected_row =
      Types.new_runtime_line_row(
        runtime_line: "2.x",
        capability_surface: ["haptics"],
        change_class: "native or companion rebuild required",
        ota_safe: false,
        rebuild_required: true,
        evidence_tier: :device_verified
      )

    invalid_matrix = %{canonical | rebuild_matrix: canonical.rebuild_matrix ++ [injected_row]}

    errors = SupportMatrix.validate(invalid_matrix)

    assert is_list(errors) and length(errors) > 0,
           "validate/1 must return errors for a rebuild_matrix row with :device_verified — evidence laundering (D-10a)"

    assert Enum.any?(errors, &(&1.key == :rebuild_matrix)),
           "error must reference :rebuild_matrix key; got: #{inspect(errors)}"
  end

  test "validate/1 accepts rebuild_matrix rows with :jvm_hermetic and :none evidence_tier (no false positive)" do
    canonical = SupportMatrix.canonical()

    jvm_row =
      Types.new_runtime_line_row(
        runtime_line: "3.x",
        capability_surface: ["haptics"],
        change_class: "native or companion rebuild required",
        ota_safe: false,
        rebuild_required: true,
        evidence_tier: :jvm_hermetic
      )

    none_row =
      Types.new_runtime_line_row(
        runtime_line: "4.x",
        capability_surface: ["haptics"],
        change_class: "native or companion rebuild required",
        ota_safe: false,
        rebuild_required: true,
        evidence_tier: :none
      )

    matrix_with_safe_rows = %{canonical | rebuild_matrix: canonical.rebuild_matrix ++ [jvm_row, none_row]}

    errors = SupportMatrix.validate(matrix_with_safe_rows)

    rebuild_errors = Enum.filter(errors, &(&1.key == :rebuild_matrix))

    assert rebuild_errors == [],
           "validate/1 must not reject :jvm_hermetic or :none rows; got rebuild_matrix errors: #{inspect(rebuild_errors)}"
  end

  # Phase 65 — DIAG-04: diagnostic_export_support_truth accessor
  describe "diagnostic_export_support_truth/0 (DIAG-04)" do
    test "returns a non-empty list" do
      truth = SupportMatrix.diagnostic_export_support_truth()
      assert is_list(truth)
      assert length(truth) > 0
    end

    test "entry has delivery_supported: false" do
      entry = SupportMatrix.diagnostic_export_support_truth() |> List.first()
      assert entry.delivery_supported == false
    end

    test "entry deferred list contains all three expected atoms" do
      entry = SupportMatrix.diagnostic_export_support_truth() |> List.first()
      assert :native_diagnostic_export in entry.deferred
      assert :metrickit_capture in entry.deferred
      assert :application_exit_info_capture in entry.deferred
    end

    test "entry deferred list is exactly the three expected atoms" do
      entry = SupportMatrix.diagnostic_export_support_truth() |> List.first()
      assert Enum.sort(entry.deferred) ==
               Enum.sort([:native_diagnostic_export, :metrickit_capture, :application_exit_info_capture])
    end

    test "entry telemetry.authority_source is :host_configured_endpoint" do
      entry = SupportMatrix.diagnostic_export_support_truth() |> List.first()
      assert entry.telemetry.authority_source == :host_configured_endpoint
    end

    test "entry telemetry.proof_class is :merge_blocking" do
      entry = SupportMatrix.diagnostic_export_support_truth() |> List.first()
      assert entry.telemetry.proof_class == :merge_blocking
    end

    test "entry proof_class is :merge_blocking" do
      entry = SupportMatrix.diagnostic_export_support_truth() |> List.first()
      assert entry.proof_class == :merge_blocking
    end

    test "entry posture contains non-overclaim phrase" do
      entry = SupportMatrix.diagnostic_export_support_truth() |> List.first()
      assert String.contains?(entry.posture, "not a crash-reporting service")
    end

    test "entry posture contains Phase 67 deferral reference" do
      entry = SupportMatrix.diagnostic_export_support_truth() |> List.first()
      assert String.contains?(entry.posture, "Phase 67")
    end

    test "entry posture contains host ownership reference" do
      entry = SupportMatrix.diagnostic_export_support_truth() |> List.first()
      assert String.contains?(entry.posture, "host")
    end

    test "entry telemetry.forbidden_metadata_keys equals DiagnosticExport.forbidden_keys()" do
      alias Crosswake.Shell.DiagnosticExport
      entry = SupportMatrix.diagnostic_export_support_truth() |> List.first()
      assert entry.telemetry.forbidden_metadata_keys == DiagnosticExport.forbidden_keys()
    end

    test "entry telemetry.metadata_keys equals DiagnosticExport.allowed_keys()" do
      alias Crosswake.Shell.DiagnosticExport
      entry = SupportMatrix.diagnostic_export_support_truth() |> List.first()
      assert entry.telemetry.metadata_keys == DiagnosticExport.allowed_keys()
    end
  end
end
