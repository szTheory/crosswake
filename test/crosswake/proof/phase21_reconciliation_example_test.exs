Code.require_file("../../support/example_host.exs", __DIR__)
Code.require_file("../../../examples/phoenix_host/lib/crosswake_example/commerce/reconciliation_keys.ex", __DIR__)
Code.require_file("../../../examples/phoenix_host/lib/crosswake_example/commerce/reconciliation_inbox.ex", __DIR__)
Code.require_file("../../../examples/phoenix_host/lib/crosswake_example/commerce/entitlement_projection.ex", __DIR__)

defmodule Crosswake.Proof.Phase21ReconciliationExampleTest do
  use ExUnit.Case, async: false

  alias Crosswake.Commerce.Contracts
  alias CrosswakeExample.Commerce.EntitlementProjection
  alias CrosswakeExample.Commerce.ReconciliationInbox
  alias CrosswakeExample.Commerce.ReconciliationKeys

  test "ingests every canonical reconciliation evidence source without granting authority" do
    for source <- [:device, :storefront, :webhook, :support] do
      evidence =
        sample_evidence(%{
          source: source,
          provider_reference: "tx_#{source}",
          evidence_ref: "evidence_#{source}"
        })

      assert {:ok, attempt} = ReconciliationInbox.ingest_evidence(evidence)
      assert attempt.source == source
      assert attempt.status == :awaiting_verification
      refute Map.has_key?(attempt, :authority)
      refute Map.has_key?(attempt, :access)
    end
  end

  test "duplicate event keys are replay-safe and non-failing" do
    evidence = sample_evidence()

    assert {:ok, first_attempt} = ReconciliationInbox.ingest_evidence(evidence)

    assert {:ok, replay_attempt} =
             ReconciliationInbox.ingest_evidence(
               evidence,
               seen_event_keys: [first_attempt.event_key]
             )

    assert replay_attempt.replay?
    assert replay_attempt.event_key == first_attempt.event_key
    assert replay_attempt.subject_key == first_attempt.subject_key
    assert replay_attempt.status == :awaiting_verification
  end

  test "correlation id variation does not change event or subject identity keys" do
    evidence = sample_evidence()

    assert {:ok, first_attempt} =
             ReconciliationInbox.ingest_evidence(
               evidence,
               correlation_id: "corr-alpha",
               group_id: "group-pro"
             )

    assert {:ok, second_attempt} =
             ReconciliationInbox.ingest_evidence(
               evidence,
               correlation_id: "corr-beta",
               group_id: "group-pro"
             )

    assert first_attempt.event_key == second_attempt.event_key
    assert first_attempt.subject_key == second_attempt.subject_key
    assert ReconciliationKeys.event_key(evidence) == first_attempt.event_key
    assert ReconciliationKeys.subject_key(evidence, group_id: "group-pro") == first_attempt.subject_key
    refute first_attempt.trace_metadata == second_attempt.trace_metadata
  end

  test "provider-issued identifiers remain case-sensitive in event and subject keys" do
    base = sample_evidence()
    upper_provider_ref = sample_evidence(%{provider_reference: "Tx_ABC"})
    lower_provider_ref = sample_evidence(%{provider_reference: "tx_abc"})
    upper_evidence_ref = sample_evidence(%{evidence_ref: "Receipt_ABC"})
    lower_evidence_ref = sample_evidence(%{evidence_ref: "receipt_abc"})

    refute ReconciliationKeys.event_key(upper_provider_ref) == ReconciliationKeys.event_key(lower_provider_ref)
    refute ReconciliationKeys.subject_key(upper_provider_ref) == ReconciliationKeys.subject_key(lower_provider_ref)
    refute ReconciliationKeys.event_key(upper_evidence_ref) == ReconciliationKeys.event_key(lower_evidence_ref)

    assert ReconciliationKeys.event_key(base) == ReconciliationKeys.event_key(sample_evidence())
  end

  test "projection precedence returns stale, pending, denied, and granted deterministically" do
    stale_snapshot = snapshot(%{freshness: freshness_lane(:stale)})
    pending_snapshot = snapshot(%{reconciliation: reconciliation_lane(:awaiting_verification)})
    denied_snapshot = snapshot()

    granted_snapshot =
      snapshot(%{
        authority: authority_lane(:active),
        access: access_lane(:granted),
        reconciliation: reconciliation_lane(:projection_refreshed),
        freshness: freshness_lane(:fresh)
      })

    assert EntitlementProjection.derived_state(stale_snapshot) == :stale
    assert EntitlementProjection.derived_state(snapshot(%{freshness: freshness_lane(:unknown)})) == :stale
    assert EntitlementProjection.derived_state(pending_snapshot) == :pending
    assert EntitlementProjection.derived_state(denied_snapshot) == :denied
    assert EntitlementProjection.derived_state(granted_snapshot) == :granted
  end

  test "project_snapshot blocks out-of-order as_of updates fail-closed" do
    current =
      snapshot(%{
        as_of: 200,
        authority: authority_lane(:active),
        access: access_lane(:granted),
        reconciliation: reconciliation_lane(:projection_refreshed)
      })

    stale_incoming =
      snapshot(%{
        as_of: 150,
        authority: authority_lane(:active),
        access: access_lane(:granted),
        reconciliation: reconciliation_lane(:projection_refreshed, "attempt_stale")
      })

    assert {:error, {:stale_authority, rejected_snapshot}} =
             EntitlementProjection.project_snapshot(current, stale_incoming)

    assert rejected_snapshot.as_of == current.as_of
    assert rejected_snapshot.reconciliation.state == :stale_authority
    assert rejected_snapshot.reconciliation.reference == "attempt_stale"
  end

  test "unknown event kinds stay non-authoritative with verification_failed status" do
    evidence = sample_evidence(%{event_kind: "status_unknown"})
    assert {:ok, attempt} = ReconciliationInbox.ingest_evidence(evidence)
    assert attempt.status == :verification_failed
  end

  test "example reconciliation modules remain provider-neutral" do
    forbidden_tokens = [
      "store" <> "kit",
      "play" <> "_billing",
      "play" <> " " <> "billing",
      "revenue" <> "cat"
    ]

    files = [
      "examples/phoenix_host/lib/crosswake_example/commerce/reconciliation_keys.ex",
      "examples/phoenix_host/lib/crosswake_example/commerce/reconciliation_inbox.ex",
      "examples/phoenix_host/lib/crosswake_example/commerce/entitlement_projection.ex",
      "test/crosswake/proof/phase21_reconciliation_example_test.exs"
    ]

    for file <- files do
      content = File.read!(file) |> String.downcase()

      for forbidden <- forbidden_tokens do
        refute String.contains?(content, forbidden), "#{file} leaked provider token #{forbidden}"
      end
    end
  end

  defp sample_evidence(overrides \\ %{}) do
    base = %{
      source: :device,
      provider: "provider_a",
      provider_reference: "tx_123",
      event_kind: "purchase",
      evidence_ref: "receipt_123",
      captured_at: "2026-05-27T10:00:00Z",
      integrity_digest: "sha256:abc",
      idempotency_ref: "idem_123"
    }

    struct!(Contracts.ReconciliationEvidence, Map.merge(base, overrides))
  end

  defp snapshot(overrides \\ %{}) do
    base = %{
      group_id: "group_123",
      authority: authority_lane(:none),
      access: access_lane(:denied),
      reconciliation: reconciliation_lane(:projection_refreshed),
      freshness: freshness_lane(:fresh),
      effective: %Contracts.EntitlementSnapshot.EffectiveLane{
        effective_from: "2026-05-01T00:00:00Z",
        effective_until: nil
      },
      evidence: %Contracts.EntitlementSnapshot.EvidenceLane{
        source: :webhook,
        reference: "evidence_123",
        observed_at: "2026-05-27T10:00:00Z"
      },
      as_of: 100
    }

    struct!(Contracts.EntitlementSnapshot, Map.merge(base, overrides))
  end

  defp authority_lane(state) do
    %Contracts.EntitlementSnapshot.AuthorityLane{
      state: state,
      reason: nil
    }
  end

  defp access_lane(decision) do
    %Contracts.EntitlementSnapshot.AccessLane{
      decision: decision,
      reason: nil
    }
  end

  defp reconciliation_lane(state, reference \\ "attempt_123") do
    %Contracts.EntitlementSnapshot.ReconciliationLane{
      state: state,
      reference: reference
    }
  end

  defp freshness_lane(state) do
    %Contracts.EntitlementSnapshot.FreshnessLane{
      state: state,
      checked_at: "2026-05-27T10:00:00Z",
      stale_after: nil
    }
  end
end
