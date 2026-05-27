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
end
