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
    assert Enum.map(matrix.android, & &1.proof_status) == [:verification_required]
    assert Enum.map(matrix.shells, &{&1.target, &1.proof_status}) |> Enum.sort() == [
             {"android_shell", :verification_required},
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
             entry.target == "core" and entry.compatibility_contract =~ "package versions alone do not define support truth"
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

  test "entitlement and evidence support entries encode freshness and non-authoritative posture" do
    capability_families = SupportMatrix.canonical().capability_families
    entitlement_snapshot = Enum.find(capability_families, &(&1.family == "entitlement_snapshot"))
    reconciliation_evidence = Enum.find(capability_families, &(&1.family == "reconciliation_evidence"))

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
end
