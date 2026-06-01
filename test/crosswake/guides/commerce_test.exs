Code.require_file(
  "../../../examples/phoenix_host/lib/crosswake_example/commerce/reconciliation_keys.ex",
  __DIR__
)

Code.require_file(
  "../../../examples/phoenix_host/lib/crosswake_example/commerce/reconciliation_inbox.ex",
  __DIR__
)

Code.require_file(
  "../../../examples/phoenix_host/lib/crosswake_example/commerce/mock_storefront.ex",
  __DIR__
)

Code.require_file(
  "../../../examples/phoenix_host/lib/crosswake_example/commerce/entitlement_projection.ex",
  __DIR__
)

Code.require_file(
  "../../../examples/phoenix_host/lib/crosswake_example/commerce/mock_backend.ex",
  __DIR__
)

defmodule Crosswake.Guides.CommerceTest do
  use ExUnit.Case, async: false
  alias Crosswake.TestSupport.ProofAssertions

  @guide_path Path.join([File.cwd!(), "guides", "commerce.md"])

  setup_all do
    content = File.read!(@guide_path)
    %{content: content}
  end

  test "includes exact normalized surface names", %{content: content} do
    assert content =~ "paywall_entry"
    assert content =~ "purchase_intent"
    assert content =~ "restore_intent"
    assert content =~ "entitlement_snapshot"
    assert content =~ "reconciliation_evidence"
  end

  test "makes authority vs evidence semantics explicit for entitlement_snapshot", %{
    content: content
  } do
    assert content =~ "Entitlement Snapshot Lanes"
    assert content =~ "authority"
    assert content =~ "access"
    assert content =~ "reconciliation"
    assert content =~ "freshness"
    assert content =~ "effective"
    assert content =~ "authority"
    assert content =~ "evidence"
    assert content =~ "entitlement_snapshot"
    assert content =~ "device"
    assert content =~ "storefront"
    assert content =~ "webhook"
    assert content =~ "support"
    assert content =~ "pending_purchase"
    assert content =~ "pending_restore"
    assert content =~ "awaiting_verification"
    assert content =~ "billing_retry"
    assert content =~ "refunded"
    assert content =~ "expired"
    assert content =~ "fresh"
    assert content =~ "stale"
    assert content =~ "unknown"
  end

  test "documents the canonical flow", %{content: content} do
    assert content =~ "device or native commerce route emits typed purchase or restore evidence"
    assert content =~ "Phoenix persists a reconciliation_attempt"

    assert content =~
             "backend verification/replay runs through host-owned workers and provider adapters"

    assert content =~ "backend updates one authoritative entitlement_snapshot"
    assert content =~ "Phoenix/native consumers refresh from that snapshot"
  end

  test "locks minimal reconciliation example, dual keys, and projection precedence contracts", %{
    content: content
  } do
    assert content =~ "## Minimal Reconciliation Inbox Example"
    assert content =~ "`purchase`"
    assert content =~ "`restore`"
    assert content =~ "`webhook`"
    assert content =~ "`support`"
    assert content =~ "example/docs-only"
    assert content =~ "event_key"
    assert content =~ "subject_key"
    assert content =~ "correlation_id"
    assert content =~ "stale"
    assert content =~ "pending"
    assert content =~ "denied"
    assert content =~ "granted"
    assert content =~ "as_of"
    assert content =~ "Ingestion outcomes are non-authoritative"
  end

  test "documents explicit commerce moment classifications", %{content: content} do
    assert content =~ "Commerce Moment Map"
    assert content =~ "Phoenix-owned"
    assert content =~ "Native-screen required"
    assert content =~ "Thin exception case"
  end

  test "locks corridor ownership matrix and canonical denial taxonomy language", %{
    content: content
  } do
    assert content =~ "## Commerce Corridor Ownership"
    assert content =~ "paywall_entry"
    assert content =~ "account_management"
    assert content =~ "purchase_intent"
    assert content =~ "restore_intent"
    assert content =~ "commerce.corridor.prerequisite_missing"
    assert content =~ "commerce.corridor.runtime_incompatible"
    assert content =~ "provider adapters are out of scope"
  end

  test "documents explicit offline non-goals and split-brain rejection copy", %{content: content} do
    assert content =~ "offline purchase replay"
    assert content =~ "device-local authority"
    assert content =~ "split-brain"
  end

  test "keeps lifecycle guidance provider-neutral and preserves phase scope fences", %{
    content: content
  } do
    assert content =~ "provider adapters are out of scope"

    lifecycle_section =
      content
      |> String.split("## Entitlement Snapshot Lanes")
      |> List.last()
      |> String.split("## Commerce Moment Map")
      |> hd()
      |> String.downcase()

    refute lifecycle_section =~ "storekit"
    refute lifecycle_section =~ "play_billing"
    refute lifecycle_section =~ "play billing"
    refute lifecycle_section =~ "revenuecat"
  end

  test "provider adapter docs lock shipped seam, backend authority, advisory proof, and restore first-class language" do
    ProofAssertions.assert_contains_exact(
      "proof.docs.provider_adapters.seams_shipped",
      "guides/commerce.md",
      "StoreKit and Play Billing adapter seams ship as reconciliation evidence emitters only.",
      source: "guides/commerce.md provider adapter posture",
      hint: "keep adapter seams evidence-only and never storefront-authoritative",
      posture: :merge_blocking
    )

    ProofAssertions.assert_contains_exact(
      "proof.docs.provider_adapters.backend_authority",
      "guides/commerce.md",
      "backend projection grants entitlement authority",
      source: "guides/commerce.md entitlement authority contract",
      hint: "device/provider evidence must never grant access directly",
      posture: :merge_blocking
    )

    ProofAssertions.assert_contains_exact(
      "proof.docs.provider_adapters.advisory_proof",
      "guides/commerce.md",
      "provider/device sandbox proof remains advisory unless promotion criteria pass",
      source: "guides/commerce.md provider proof posture",
      hint: "preserve advisory-vs-merge-blocking distinction for provider lanes",
      posture: :merge_blocking
    )

    ProofAssertions.assert_contains_exact(
      "proof.docs.provider_adapters.restore_required",
      "guides/commerce.md",
      "Restore is first-class for both StoreKit and Play Billing",
      source: "guides/commerce.md reviewer/storefront restore guidance",
      hint: "restore guidance must remain explicit for both providers",
      posture: :merge_blocking
    )

    ProofAssertions.assert_contains_exact(
      "proof.docs.provider_adapters.revenuecat_deferred",
      "guides/commerce.md",
      "RevenueCat remains deferred.",
      source: "guides/commerce.md deferred provider scope",
      hint: "do not imply RevenueCat shipped in v3.7 docs",
      posture: :merge_blocking
    )
  end

  test "keeps reconciliation guidance provider-neutral and non-authoritative", %{content: content} do
    # The reconciliation flow narrative lives inside Layer 1 (Commerce Support Truth) and
    # must remain provider-neutral. The layered restructure introduces Layer 2 (Reviewer
    # And Storefront Playbooks) right after the Layer 1 fallback section, so the
    # reconciliation section now terminates at the Layer 2 boundary rather than the old
    # H2 "## Non-Goals & explicit Rejections" boundary (which moved into Layer 3).
    reconciliation_section =
      content
      |> String.split("### The Canonical Reconciliation Flow")
      |> List.last()
      |> String.split("## Reviewer And Storefront Playbooks")
      |> hd()
      |> String.downcase()

    refute reconciliation_section =~ "storekit"
    refute reconciliation_section =~ "play_billing"
    refute reconciliation_section =~ "play billing"
    refute reconciliation_section =~ "revenuecat"
    refute reconciliation_section =~ "evidence directly grants authority"
    assert reconciliation_section =~ "non-authoritative"
  end

  test "commerce guide corridor ownership section publishes proof_class and rebuild posture", %{
    content: content
  } do
    assert content =~ "proof_class"
    assert content =~ "native_rebuild_required"
    assert content =~ "merge_blocking"
    assert content =~ "advisory"

    # Every corridor row in the ownership matrix carries an explicit proof_class
    assert content =~ "| `paywall_entry` | `phoenix_owned` | `merge_blocking` |"

    assert content =~
             "| `account_management` | `phoenix_owned` | `merge_blocking` |"

    assert content =~
             "| `purchase_intent` | `native_or_companion_required` | `merge_blocking` (core) + `advisory` (provider) |"

    assert content =~
             "| `restore_intent` | `native_or_companion_required` | `merge_blocking` (core) + `advisory` (provider) |"
  end

  test "commerce guide publishes explicit non-claim that advisory checks cannot redefine core support truth",
       %{content: content} do
    assert content =~ "Proof Posture"
    assert content =~ "Advisory checks cannot redefine core support truth"
    assert content =~ "explicit requirement/roadmap scope change"
  end

  test "commerce guide denial taxonomy row publishes proof_class column", %{content: content} do
    assert content =~ "| denial_code | fail_closed_reason | fallback | proof_class |"

    assert content =~
             "| `commerce.corridor.undeclared` | route declared commerce without a canonical corridor profile | `return_to_phoenix_guidance` | `merge_blocking` |"

    assert content =~
             "| `commerce.corridor.pack_incompatible` | required pack/runtime posture is incompatible for the corridor | `return_to_phoenix_guidance` | `merge_blocking` |"
  end

  test "commerce guide corridor roles match canonical support matrix corridor roles exactly", %{
    content: content
  } do
    support_matrix_roles =
      Crosswake.SupportMatrix.commerce_corridors()
      |> Enum.map(& &1.corridor_role)
      |> Enum.sort()

    # Each canonical corridor role must appear as a backtick-quoted entry in the
    # Commerce Corridor Ownership section of the guide.
    ownership_section =
      content
      |> String.split("## Commerce Corridor Ownership")
      |> List.last()
      |> String.split("### Entitlement Snapshot Lanes")
      |> hd()

    for role <- support_matrix_roles do
      assert ownership_section =~ "`#{role}`",
             "commerce guide ownership section missing canonical corridor role `#{role}` (support matrix declares: #{inspect(support_matrix_roles)})"
    end

    # The guide must not introduce additional corridor roles that are not in
    # the canonical support matrix source. We approximate this by checking that
    # every row of the corridor ownership table corresponds to a canonical role.
    table_rows =
      ownership_section
      |> String.split("\n")
      |> Enum.filter(
        &Regex.match?(~r/^\| `[a-z_]+` \| `(phoenix_owned|native_or_companion_required)` \|/, &1)
      )

    guide_roles =
      table_rows
      |> Enum.map(fn row ->
        [_, role | _] = String.split(row, "|", parts: 3)
        role |> String.trim() |> String.trim("`")
      end)
      |> Enum.sort()

    assert guide_roles == support_matrix_roles,
           "commerce guide ownership corridor roles #{inspect(guide_roles)} must match support matrix corridor roles #{inspect(support_matrix_roles)} exactly"
  end

  # --- Phase 23 Plan 03: layered docs hub assertions ---

  test "commerce guide publishes three explicit layer headings", %{content: content} do
    # Layer 1: support truth, Layer 2: reviewer/storefront playbooks, Layer 3: rough edges/non-claims.
    # All three must be H2 headings so navigation is mechanically unambiguous.
    assert content =~ ~r/^## Commerce Support Truth\s*$/m,
           "commerce guide missing Layer 1 heading `## Commerce Support Truth`"

    assert content =~ ~r/^## Reviewer And Storefront Playbooks\s*$/m,
           "commerce guide missing Layer 2 heading `## Reviewer And Storefront Playbooks`"

    assert content =~ ~r/^## Rough Edges And Non-Claims\s*$/m,
           "commerce guide missing Layer 3 heading `## Rough Edges And Non-Claims`"
  end

  test "reviewer playbooks carry explicit Advisory — provider-specific guidance callout", %{
    content: content
  } do
    playbook_section =
      content
      |> String.split("## Reviewer And Storefront Playbooks")
      |> List.last()
      |> String.split("## Rough Edges And Non-Claims")
      |> hd()

    # The layer-level advisory callout must be present so reviewers/adopters cannot
    # mistake provider-specific guidance for core support truth.
    assert playbook_section =~ "Advisory — provider-specific guidance",
           "Reviewer playbook section missing layer-level `Advisory — provider-specific guidance` callout"

    # Both platform templates must carry their own advisory callout.
    app_store_section =
      playbook_section
      |> String.split("### App Store Reviewer Notes")
      |> List.last()
      |> String.split("### Play Store Reviewer Notes")
      |> hd()

    assert app_store_section =~ "Advisory — provider-specific guidance",
           "App Store reviewer template missing per-template advisory callout"

    play_store_section =
      playbook_section
      |> String.split("### Play Store Reviewer Notes")
      |> List.last()

    assert play_store_section =~ "Advisory — provider-specific guidance",
           "Play Store reviewer template missing per-template advisory callout"
  end

  test "non-claims section explicitly names StoreKit, Play Billing, device-local authority, and offline replay",
       %{content: content} do
    non_claims_section =
      content
      |> String.split("## Rough Edges And Non-Claims")
      |> List.last()

    # Each non-claim must be stated explicitly using "not shipped" language so reviewers
    # cannot misread silence as a claim. Device-local authority is the only one stated
    # both as a non-claim and as an explicit contract-direction rejection.
    assert non_claims_section =~ ~r/StoreKit adapter is not shipped/i,
           "non-claims section missing explicit `StoreKit adapter is not shipped` statement"

    assert non_claims_section =~ ~r/Play Billing adapter is not shipped/i,
           "non-claims section missing explicit `Play Billing adapter is not shipped` statement"

    assert non_claims_section =~ ~r/Device-local entitlement authority is not shipped/i,
           "non-claims section missing explicit `Device-local entitlement authority is not shipped` statement"

    assert non_claims_section =~ ~r/Offline purchase replay is not shipped/i,
           "non-claims section missing explicit `Offline purchase replay is not shipped` statement"

    assert non_claims_section =~ ~r/Storefront purchase UI is not shipped/i,
           "non-claims section missing explicit `Storefront purchase UI is not shipped` statement"
  end

  test "reviewer templates contain owner, proof_class, failure_posture, and rebuild_requirement columns",
       %{content: content} do
    playbook_section =
      content
      |> String.split("## Reviewer And Storefront Playbooks")
      |> List.last()
      |> String.split("## Rough Edges And Non-Claims")
      |> hd()

    # The exact reviewer template header must appear at least once in each platform template
    # so the four canonical metadata columns are mechanically locked.
    expected_header = "| surface | owner | proof_class | failure_posture | rebuild_requirement |"

    matches = playbook_section |> String.split("\n") |> Enum.count(&(&1 == expected_header))

    assert matches >= 2,
           "reviewer playbook section expected at least 2 reviewer template tables with header `#{expected_header}`, found #{matches}"
  end

  test "reviewer fallback language uses canonical commerce.corridor.* denial codes", %{
    content: content
  } do
    playbook_section =
      content
      |> String.split("## Reviewer And Storefront Playbooks")
      |> List.last()
      |> String.split("## Rough Edges And Non-Claims")
      |> hd()

    canonical_denial_codes = Crosswake.SupportMatrix.commerce_corridor_denial_codes()

    # At least the failure-posture-relevant denial codes (prerequisite_missing,
    # runtime_incompatible, unsupported) must appear in reviewer fallback descriptions.
    required_in_fallback = [
      "commerce.corridor.prerequisite_missing",
      "commerce.corridor.runtime_incompatible",
      "commerce.corridor.unsupported"
    ]

    for code <- required_in_fallback do
      assert code in canonical_denial_codes,
             "test invariant: `#{code}` must exist in canonical denial codes (got: #{inspect(canonical_denial_codes)})"

      assert playbook_section =~ code,
             "reviewer playbook fallback descriptions missing canonical denial code `#{code}`"
    end
  end

  test "reviewer template corridor roles cross-reference canonical SupportMatrix corridor roles",
       %{
         content: content
       } do
    playbook_section =
      content
      |> String.split("## Reviewer And Storefront Playbooks")
      |> List.last()
      |> String.split("## Rough Edges And Non-Claims")
      |> hd()

    canonical_roles =
      Crosswake.SupportMatrix.commerce_corridors()
      |> Enum.map(& &1.corridor_role)

    # Reviewer templates reference corridor identities by canonical role name
    # (purchase_intent, restore_intent, paywall_entry, account_management) so adopters
    # cannot drift their reviewer language away from the canonical contract surface.
    # We assert each canonical role appears at least once inside the reviewer playbook
    # layer; this is the parity guard required by Task 3.
    for role <- canonical_roles do
      assert playbook_section =~ role,
             "reviewer playbook section missing canonical corridor role `#{role}` referenced by SupportMatrix"
    end
  end

  test "reviewer playbooks include How To Use These Templates preamble anchored to canonical accessors",
       %{content: content} do
    playbook_section =
      content
      |> String.split("## Reviewer And Storefront Playbooks")
      |> List.last()
      |> String.split("## Rough Edges And Non-Claims")
      |> hd()

    assert playbook_section =~ "How To Use These Templates",
           "reviewer playbook section missing `How To Use These Templates` preamble"

    # The preamble must cite the canonical accessors so adopter customization remains
    # mechanically anchored to support truth, not free-form prose.
    assert playbook_section =~ "Crosswake.SupportMatrix.commerce_corridor_denial_codes/0",
           "reviewer preamble missing reference to canonical denial codes accessor"

    assert playbook_section =~ "Crosswake.SupportMatrix.commerce_corridors/0",
           "reviewer preamble missing reference to canonical corridors accessor"
  end

  # --- Phase 37 Plan 01: Paywall Corridor Walkthrough docs-contract assertions ---

  describe "paywall corridor walkthrough (DOCS-01 / DOCS-02)" do
    # D-06.1: string-presence assertions — lock the walkthrough heading, module names,
    # canonical field names, mock-vs-real callout, and proof citation against the guide.

    test "walkthrough heading exists in Layer 1 (SC#1)", %{content: content} do
      assert content =~ "### Paywall Corridor Walkthrough",
             "commerce guide missing `### Paywall Corridor Walkthrough` heading (DOCS-01 SC#1)"
    end

    test "MockStorefront named exactly in walkthrough (SC#3)", %{content: content} do
      assert content =~ "CrosswakeExample.Commerce.MockStorefront",
             "commerce guide missing exact module name `CrosswakeExample.Commerce.MockStorefront` (DOCS-01 SC#3)"
    end

    test "canonical field names are present, not invented aliases (SC#3)", %{content: content} do
      assert content =~ "provider_reference",
             "commerce guide missing canonical field name `provider_reference` — do not rename to an alias (DOCS-01 SC#3)"

      assert content =~ "evidence_ref",
             "commerce guide missing canonical field name `evidence_ref` — do not rename to an alias (DOCS-01 SC#3)"
    end

    test "mock-vs-real callout uses provider: \"mock\" and references non-claims section (SC#2)",
         %{
           content: content
         } do
      assert content =~ ~s(provider: "mock"),
             "commerce guide walkthrough missing explicit `provider: \"mock\"` callout (DOCS-01 SC#2 / D-05)"

      assert content =~ "StoreKit",
             "commerce guide missing StoreKit reference — non-claims section must name it (DOCS-01 SC#2)"

      assert content =~ "Play Billing",
             "commerce guide missing Play Billing reference — non-claims section must name it (DOCS-01 SC#2)"
    end

    test "proof file path is cited in the walkthrough (D-08)", %{content: content} do
      assert content =~ "test/crosswake/proof/phase34_paywall_corridor_proof_test.exs",
             "commerce guide walkthrough missing proof citation `test/crosswake/proof/phase34_paywall_corridor_proof_test.exs` (D-08)"
    end

    # D-06.2: live-code guard — six function_exported?/3 assertions confirm that every
    # module and function anchored in the walkthrough resolves to a real export in the
    # shipped example host. These break immediately when an anchored symbol is renamed or
    # removed. Modules are loaded at file scope (above defmodule) in dependency order.
    # Only pure commerce modules are loaded; runtime modules (LiveView, router) are excluded.
    test "example host functions resolve to real exports (SC#3 live-lock)", _context do
      assert function_exported?(CrosswakeExample.Commerce.MockStorefront, :simulate_purchase, 2),
             "CrosswakeExample.Commerce.MockStorefront.simulate_purchase/2 not exported — walkthrough anchor is stale"

      assert function_exported?(CrosswakeExample.Commerce.MockStorefront, :simulate_restore, 2),
             "CrosswakeExample.Commerce.MockStorefront.simulate_restore/2 not exported — walkthrough anchor is stale"

      assert function_exported?(
               CrosswakeExample.Commerce.ReconciliationInbox,
               :ingest_evidence,
               2
             ),
             "CrosswakeExample.Commerce.ReconciliationInbox.ingest_evidence/2 not exported — walkthrough anchor is stale"

      assert function_exported?(
               CrosswakeExample.Commerce.EntitlementProjection,
               :project_snapshot,
               2
             ),
             "CrosswakeExample.Commerce.EntitlementProjection.project_snapshot/2 not exported — walkthrough anchor is stale"

      assert function_exported?(
               CrosswakeExample.Commerce.EntitlementProjection,
               :derived_state,
               1
             ),
             "CrosswakeExample.Commerce.EntitlementProjection.derived_state/1 not exported — walkthrough anchor is stale"

      assert function_exported?(
               CrosswakeExample.Commerce.MockBackend,
               :build_verified_snapshot,
               2
             ),
             "CrosswakeExample.Commerce.MockBackend.build_verified_snapshot/2 not exported — walkthrough anchor is stale"
    end
  end
end
