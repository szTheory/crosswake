defmodule CrosswakeExample.Commerce.MockBackend do
  @moduledoc """
  Pure-Elixir, provider-neutral mock verification pipeline for the example host.

  Bridges the verification gap: `ReconciliationInbox.ingest_evidence/2` always
  returns `status: :awaiting_verification`, but `EntitlementProjection.project_snapshot/2`
  requires a verified `reconciliation.state` (one of `:projection_refreshed`,
  `:verification_failed`, `:conflict`, or `:stale_authority`). This module manufactures
  the verified `%EntitlementSnapshot{}` for the granted terminal outcome and broadcasts
  the derived state atom via PubSub.

  ## Same code path for example and proof

  `PaywallEntryLive` delegates here via a fire-and-forget `Task`; the Phase 36 hermetic
  proof calls `build_verified_snapshot/2` and `verify_and_broadcast/2` directly without
  a running server (D-02). Because both public functions are synchronous and have no
  dependency on a LiveView socket, channel stack, or process registry, they are reachable
  via `Code.require_file` at module scope in the proof test.

  ## Verification gap — the teachable moment

  In production, a real backend webhook delivers a verified `%EntitlementSnapshot{}` with
  a `:projection_refreshed` reconciliation state. In this mock lane, `MockBackend`
  manufactures that verified snapshot explicitly, then runs the same
  `EntitlementProjection.project_snapshot/2` → `derived_state/1` pipeline the production
  path uses. This makes the mock path honest: the derivation logic is real, only the
  evidence source is simulated.

  ## No provider-SDK code

  `provider: "mock"` is the only value ever produced. See `AF-01` / `AF-07` in the
  phase constraints. The Phase 36 proof asserts this via `PROOF-03`.
  """

  alias Crosswake.Commerce.Contracts
  alias CrosswakeExample.Commerce.EntitlementProjection

  @subscription_entry_id "sub_pro_monthly"

  @doc """
  Builds a verified `%EntitlementSnapshot{}` and broadcasts the derived entitlement
  state atom on the `"entitlement:" <> group_id` PubSub topic.

  Called by `PaywallEntryLive` via a fire-and-forget `Task` (D-04/D-05) and by
  `CorridorController.purchase/2` and `restore/2` (D-07). The Phase 36 hermetic
  proof calls this function directly without a running LiveView/channel stack (D-02).

  Broadcasts `{:entitlement_update, derived_state}` carrying the derived atom only —
  never the raw snapshot or lane fields (D-11/D-14/T-35-01).

  Returns `:ok`.
  """
  @spec verify_and_broadcast(Contracts.ReconciliationEvidence.t(), String.t()) :: :ok
  def verify_and_broadcast(evidence, group_id) do
    snapshot = build_verified_snapshot(evidence, group_id)
    {:ok, projected} = EntitlementProjection.project_snapshot(nil, snapshot)
    state = EntitlementProjection.derived_state(projected)

    Phoenix.PubSub.broadcast(
      CrosswakeExample.PubSub,
      "entitlement:" <> group_id,
      {:entitlement_update, state}
    )

    :ok
  end

  @doc """
  Constructs a verified `%EntitlementSnapshot{}` for the granted terminal outcome.

  This is the synchronous core callable without a server (D-02). The Phase 36 hermetic
  proof calls this directly, then passes the result to `EntitlementProjection.project_snapshot/2`
  and `derived_state/1` to assert the full pipeline.

  The snapshot is built with field values that produce `derived_state/1 == :granted`:
  - `reconciliation.state: :projection_refreshed` (verified — passes `project_snapshot/2`)
  - `freshness.state: :fresh` (required for granted)
  - `authority.state: :active` (grantable authority state)
  - `access.decision: :granted` (explicit grant)
  - `as_of: System.system_time(:microsecond)` (monotonic — safe on repeated calls, Pitfall 6)

  Construction mirrors the phase21 test snapshot helpers (`struct!` form, D-03).
  """
  @spec build_verified_snapshot(Contracts.ReconciliationEvidence.t(), String.t()) ::
          Contracts.EntitlementSnapshot.t()
  def build_verified_snapshot(_evidence, group_id) do
    now_iso = DateTime.utc_now() |> DateTime.to_iso8601()

    struct!(Contracts.EntitlementSnapshot, %{
      group_id: group_id,
      authority: %Contracts.EntitlementSnapshot.AuthorityLane{
        state: :active,
        reason: nil
      },
      access: %Contracts.EntitlementSnapshot.AccessLane{
        decision: :granted,
        reason: nil
      },
      reconciliation: %Contracts.EntitlementSnapshot.ReconciliationLane{
        state: :projection_refreshed,
        reference: "mock_backend_ref_" <> @subscription_entry_id
      },
      freshness: %Contracts.EntitlementSnapshot.FreshnessLane{
        state: :fresh,
        checked_at: now_iso,
        stale_after: nil
      },
      effective: %Contracts.EntitlementSnapshot.EffectiveLane{
        effective_from: now_iso,
        effective_until: nil
      },
      evidence: %Contracts.EntitlementSnapshot.EvidenceLane{
        source: :storefront,
        reference: "mock_evt_" <> @subscription_entry_id <> "_purchase",
        observed_at: now_iso
      },
      as_of: System.system_time(:microsecond)
    })
  end
end
