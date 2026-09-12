Code.require_file(
  "../../../examples/phoenix_host/lib/crosswake_example/commerce/reconciliation_keys.ex",
  __DIR__
)

Code.require_file(
  "../../../examples/phoenix_host/lib/crosswake_example/commerce/reconciliation_inbox.ex",
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

defmodule Crosswake.Proof.Phase34PaywallCorridorProofTest do
  @moduledoc """
  Hermetic merge-blocking proof lane for the Phase 34 paywall corridor.

  Asserts the must-have truths for PROOF-01 and PROOF-03:
  - All four derived_state/1 outcomes (:stale, :pending, :denied, :granted) from
    distinct inline-built snapshots (PROOF-01 / SC#1).
  - The :pending -> :granted transition: ingest_evidence/2 yields
    :awaiting_verification (the :pending origin), then MockBackend.build_verified_snapshot/2
    -> project_snapshot(nil, verified) -> derived_state == :granted (PROOF-01 / SC#2).
  - Mock-boundary fence as the three real D-06 truths: authority_mutation_allowed_from_evidence?/1
    returns false unconditionally; project_snapshot/2 rejects unverified reconciliation states;
    a verified-but-not-refreshed snapshot does NOT derive :granted (PROOF-03 / SC#3).
  - Self-scan hermeticity guard structurally enforcing the above contract (SC#4).

  Hermeticity contract: This proof reaches the real shipped code via Code.require_file
  of the FOUR PURE example-host commerce modules (reconciliation_keys, reconciliation_inbox,
  entitlement_projection, mock_backend) — no runtime/server paths, no process start,
  no PubSub, no network. The Crosswake.Commerce.Reconciliation lib module is in the
  standard compilation path (lib/) and needs no require_file.

  Intentionally UNtagged (no @moduletag :requires_example_host) — hermetic via
  Code.require_file and pure function calls, so it runs in the merge-blocking lane
  under `mix test --exclude requires_example_host`.
  """

  use ExUnit.Case, async: false

  alias Crosswake.Commerce.Contracts
  alias CrosswakeExample.Commerce.ReconciliationInbox
  alias CrosswakeExample.Commerce.EntitlementProjection
  alias CrosswakeExample.Commerce.MockBackend

  @group_id "sub_pro_monthly"
  @allowed_require_file_paths [
    "../../../examples/phoenix_host/lib/crosswake_example/commerce/reconciliation_keys.ex",
    "../../../examples/phoenix_host/lib/crosswake_example/commerce/reconciliation_inbox.ex",
    "../../../examples/phoenix_host/lib/crosswake_example/commerce/entitlement_projection.ex",
    "../../../examples/phoenix_host/lib/crosswake_example/commerce/mock_backend.ex"
  ]

  # ---------------------------------------------------------------------------
  # SC#1 — four derived states (PROOF-01, D-04)
  # ---------------------------------------------------------------------------

  describe "four derived states (SC#1)" do
    test ":stale — freshness.state :stale wins over all other states" do
      snap = phase34_snapshot(%{freshness: phase34_freshness_lane(:stale)})
      assert EntitlementProjection.derived_state(snap) == :stale
    end

    test ":pending — fresh + :awaiting_verification reconciliation" do
      snap =
        phase34_snapshot(%{reconciliation: phase34_reconciliation_lane(:awaiting_verification)})

      assert EntitlementProjection.derived_state(snap) == :pending
    end

    test ":denied — fresh + verified reconciliation but access :denied (not a granting combination)" do
      # Base defaults: freshness :fresh, reconciliation :projection_refreshed, access :denied
      # granted_snapshot? returns false (access :denied) -> fallthrough to :denied
      snap = phase34_snapshot()

      assert EntitlementProjection.derived_state(snap) == :denied,
             "base snapshot with access :denied and reconciliation :projection_refreshed should fall through to :denied"
    end

    test ":granted — routes through SHIPPED MockBackend.build_verified_snapshot/2 -> project_snapshot(nil, verified)" do
      verified = MockBackend.build_verified_snapshot(phase34_mock_evidence(), @group_id)
      {:ok, projected} = EntitlementProjection.project_snapshot(nil, verified)
      assert EntitlementProjection.derived_state(projected) == :granted
    end
  end

  # ---------------------------------------------------------------------------
  # SC#2 — :pending -> :granted transition (PROOF-01, D-05)
  # ---------------------------------------------------------------------------

  describe ":pending -> :granted transition (SC#2)" do
    test "ingest_evidence/2 on mock purchase evidence returns {:ok, map} with status :awaiting_verification" do
      evidence = phase34_mock_evidence()
      assert {:ok, result} = ReconciliationInbox.ingest_evidence(evidence)
      assert result.status == :awaiting_verification
    end

    test ":pending origin — derived_state on :awaiting_verification + fresh snapshot == :pending" do
      snap =
        phase34_snapshot(%{reconciliation: phase34_reconciliation_lane(:awaiting_verification)})

      assert EntitlementProjection.derived_state(snap) == :pending
    end

    test "verified -> project -> :granted — MockBackend.build_verified_snapshot/2 -> project_snapshot(nil, _) -> derived_state == :granted" do
      # Step 3 of D-05: the honest :granted path through the real shipped pipeline
      verified = MockBackend.build_verified_snapshot(phase34_mock_evidence(), @group_id)
      assert {:ok, projected} = EntitlementProjection.project_snapshot(nil, verified)
      assert EntitlementProjection.derived_state(projected) == :granted
    end
  end

  # ---------------------------------------------------------------------------
  # SC#3 — mock-boundary fence (PROOF-03, D-06 three real truths)
  # ---------------------------------------------------------------------------

  describe "mock-boundary fence (SC#3 / PROOF-03)" do
    test "D-06.1: authority_mutation_allowed_from_evidence?/1 returns false for mock evidence (lib contract)" do
      evidence = phase34_mock_evidence()

      assert Crosswake.Commerce.Reconciliation.authority_mutation_allowed_from_evidence?(evidence) ==
               false,
             "authority_mutation_allowed_from_evidence?/1 returns false unconditionally for any ReconciliationEvidence — this is the lib contract and the anti-grant fence anchor"
    end

    test "D-06.2: project_snapshot/2 rejects unverified (:awaiting_verification) reconciliation state" do
      unverified =
        phase34_snapshot(%{reconciliation: phase34_reconciliation_lane(:awaiting_verification)})

      assert {:error, :unverified_reconciliation_outcome} =
               EntitlementProjection.project_snapshot(nil, unverified),
             "raw ingested evidence (:awaiting_verification) cannot be projected — unverified reconciliation state is rejected"
    end

    test "D-06.3: verified-but-not-refreshed (:verification_failed) projects {:ok, _} but does NOT derive :granted" do
      # :verification_failed is in @verified_reconciliation_states so project_snapshot passes it,
      # but resolved_reconciliation?/1 returns false for it, so granted_snapshot? is false.
      # Together: mock evidence can never directly grant entitlement authority.
      vfailed_snap =
        phase34_snapshot(%{
          reconciliation: phase34_reconciliation_lane(:verification_failed),
          authority: phase34_authority_lane(:active),
          access: phase34_access_lane(:granted),
          freshness: phase34_freshness_lane(:fresh)
        })

      assert {:ok, projected} = EntitlementProjection.project_snapshot(nil, vfailed_snap)

      refute EntitlementProjection.derived_state(projected) == :granted,
             "only a real :projection_refreshed reconciliation outcome can derive :granted; :verification_failed must not grant"
    end
  end

  # ---------------------------------------------------------------------------
  # SC#4 — hermeticity self-scan guard (D-03)
  # ---------------------------------------------------------------------------

  describe "hermeticity self-scan guard (SC#4 / D-03)" do
    test "no runtime-path Code.require_file lines; only the four allowed pure-commerce modules" do
      assert :ok = validate_require_file_contract(File.read!(__ENV__.file))
    end

    test "a computed fifth Code.require_file call is counted and rejected" do
      allowed_calls =
        Enum.map_join(@allowed_require_file_paths, "\n", fn path ->
          "Code.require_file(" <> inspect(path) <> ", __DIR__)"
        end)

      source =
        allowed_calls <>
          "\nruntime_path = Path.join(__DIR__, \"runtime.ex\")" <>
          "\nCode.require_file(runtime_path, __DIR__)\n"

      assert {:error, {:unexpected_require_file_count, 5}} =
               validate_require_file_contract(source)
    end

    test "a fully qualified computed load is counted while comments and strings are ignored" do
      allowed_calls =
        Enum.map_join(@allowed_require_file_paths, "\n", fn path ->
          "Code.require_file(" <> inspect(path) <> ", __DIR__)"
        end)

      source =
        allowed_calls <>
          "\n# Elixir.Code.require_file(comment_path, __DIR__)" <>
          "\ndecoy = \"Elixir.Code.require_file(string_path, __DIR__)\"" <>
          "\nruntime_path = Path.join(__DIR__, \"runtime.ex\")" <>
          "\nElixir.Code.require_file(runtime_path, __DIR__)\n"

      assert {:error, {:unexpected_require_file_count, 5}} =
               validate_require_file_contract(source)
    end

    test "no process-start or server tokens in the proof body" do
      source = File.read!(__ENV__.file) |> String.downcase()

      # Tokens built via concatenation so the self-scan guard does not match its OWN assertion lines
      forbidden_tokens = [
        "start" <> "_supervised",
        "phoenix" <> ".pubsub",
        "genserver" <> ".start",
        "liveview" <> "test"
      ]

      for token <- forbidden_tokens do
        refute String.contains?(source, String.downcase(token)),
               "proof body contains a process-start or server token #{inspect(token)}; hermetic lane must not start processes or use Phoenix server infrastructure"
      end
    end

    test "proof uses async: false (required for hermetic determinism)" do
      source = File.read!(__ENV__.file)

      assert String.contains?(source, "async: false"),
             "proof must use ExUnit.Case, async: false for hermetic determinism"
    end

    test "proof is untagged — no @moduletag :requires_example_host (merge-blocking lane)" do
      source = File.read!(__ENV__.file) |> String.downcase()

      # A real @moduletag directive always appears at the start of a line (after optional whitespace).
      # The moduledoc prose mentioning it is embedded mid-line inside documentation text, not at line start.
      # Use a line-by-line scan: filter lines that are actual @moduletag directives (start of line),
      # then assert none of those directive lines contain the forbidden tag name.
      directive_lines =
        source
        |> String.split("\n")
        |> Enum.filter(&Regex.match?(~r/^\s*@moduletag\s/, &1))

      # The forbidden tag name, split to avoid matching this scan code itself
      tag_name = "requires" <> "_example_host"

      for line <- directive_lines do
        refute String.contains?(line, tag_name),
               "proof must not have @moduletag :requires_example_host directive; found: #{inspect(line)}"
      end
    end
  end

  defp validate_require_file_contract(source) do
    with {:ok, ast} <- Code.string_to_quoted(source) do
      require_file_arguments = collect_require_file_arguments(ast)

      cond do
        length(require_file_arguments) != 4 ->
          {:error, {:unexpected_require_file_count, length(require_file_arguments)}}

        not Enum.all?(require_file_arguments, &is_binary/1) ->
          {:error, :non_literal_require_file_path}

        Enum.sort(require_file_arguments) != Enum.sort(@allowed_require_file_paths) ->
          {:error, :unexpected_require_file_paths}

        true ->
          :ok
      end
    else
      {:error, _parse_error} -> {:error, :invalid_elixir_source}
    end
  end

  defp collect_require_file_arguments(ast) do
    {_ast, arguments} =
      Macro.prewalk(ast, [], fn
        {{:., _dot_meta, [receiver, :require_file]}, _call_meta, [first_argument | _rest]} = node,
        arguments ->
          if code_module?(receiver) do
            {node, [first_argument | arguments]}
          else
            {node, arguments}
          end

        node, arguments ->
          {node, arguments}
      end)

    Enum.reverse(arguments)
  end

  defp code_module?({:__aliases__, _meta, segments}), do: Module.concat(segments) == Code
  defp code_module?(_receiver), do: false

  # ---------------------------------------------------------------------------
  # Private inline fixture builders (phase34_-prefixed; phase21 pattern, D-07)
  # Fixed timestamp strings for determinism (Phase 34 D-08/D-09).
  # ---------------------------------------------------------------------------

  defp phase34_mock_evidence do
    %Contracts.ReconciliationEvidence{
      source: :storefront,
      provider: "mock",
      provider_reference: "mock_txn_sub_pro_monthly",
      event_kind: "purchase",
      evidence_ref: "mock_evt_sub_pro_monthly_purchase",
      captured_at: "2026-05-29T00:00:00Z"
    }
  end

  defp phase34_snapshot(overrides \\ %{}) do
    base = %{
      group_id: @group_id,
      authority: phase34_authority_lane(:none),
      access: phase34_access_lane(:denied),
      reconciliation: phase34_reconciliation_lane(:projection_refreshed),
      freshness: phase34_freshness_lane(:fresh),
      effective: %Contracts.EntitlementSnapshot.EffectiveLane{
        effective_from: "2026-05-29T00:00:00Z",
        effective_until: nil
      },
      evidence: %Contracts.EntitlementSnapshot.EvidenceLane{
        source: :storefront,
        reference: "phase34_evidence_ref",
        observed_at: "2026-05-29T00:00:00Z"
      },
      as_of: 100
    }

    struct!(Contracts.EntitlementSnapshot, Map.merge(base, overrides))
  end

  defp phase34_authority_lane(state) do
    %Contracts.EntitlementSnapshot.AuthorityLane{
      state: state,
      reason: nil
    }
  end

  defp phase34_access_lane(decision) do
    %Contracts.EntitlementSnapshot.AccessLane{
      decision: decision,
      reason: nil
    }
  end

  defp phase34_reconciliation_lane(state, reference \\ "phase34_attempt_ref") do
    %Contracts.EntitlementSnapshot.ReconciliationLane{
      state: state,
      reference: reference
    }
  end

  defp phase34_freshness_lane(state) do
    %Contracts.EntitlementSnapshot.FreshnessLane{
      state: state,
      checked_at: "2026-05-29T00:00:00Z",
      stale_after: nil
    }
  end
end
