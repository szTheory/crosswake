defmodule Crosswake.Guides.CommerceTest do
  use ExUnit.Case, async: true

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

  test "makes authority vs evidence semantics explicit for entitlement_snapshot", %{content: content} do
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
    assert content =~ "backend verification/replay runs through host-owned workers and provider adapters"
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

  test "locks corridor ownership matrix and canonical denial taxonomy language", %{content: content} do
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

  test "keeps lifecycle guidance provider-neutral and preserves phase scope fences", %{content: content} do
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
      |> String.split("## Entitlement Snapshot Lanes")
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
      |> Enum.filter(&Regex.match?(~r/^\| `[a-z_]+` \| `(phoenix_owned|native_or_companion_required)` \|/, &1))

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
end
