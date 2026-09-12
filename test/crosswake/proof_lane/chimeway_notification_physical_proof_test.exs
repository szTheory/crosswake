defmodule Crosswake.ProofLane.ChimewayNotificationPhysicalProofTest do
  use ExUnit.Case, async: true

  alias Crosswake.ProofLane.ChimewayNotificationPhysicalProof, as: Contract
  alias Crosswake.ProofLane.Evidence

  @fixture Path.expand(
             "../../fixtures/proof_lane/chimeway-notification-physical-proof.json",
             __DIR__
           )
  @expected [
    %{id: "permission_observed", owner: :device_local},
    %{id: "authenticated_registration", owner: :backend_authority},
    %{id: "protected_activation_once", owner: :backend_authority}
  ]

  test "publishes the versioned fixed owner-qualified assertion vocabulary" do
    assert 1 == Contract.schema_version()
    assert @expected == Contract.assertions()
  end

  test "accepts only the canonical ordered passed report from the sanitized fixture" do
    report = fixture_report()

    assert :ok = Contract.validate_report(report)
    assert Enum.map(report, & &1.id) == Enum.map(@expected, & &1.id)
    assert Enum.map(report, & &1.owner) == Enum.map(@expected, & &1.owner)
    assert Enum.all?(report, &(&1.outcome == :passed))
  end

  test "rejects malformed, reordered, owner-drifted, closed-outcome, and sensitive reports without echoing input" do
    canary = "CANARY-DEVICE-TOKEN"
    report = fixture_report()

    invalid_reports = [
      :not_a_report,
      Enum.reverse(report),
      List.replace_at(report, 0, %{hd(report) | owner: :backend_authority}),
      List.replace_at(report, 1, %{Enum.at(report, 1) | outcome: :unexpected}),
      List.replace_at(report, 2, Map.put(Enum.at(report, 2), :payload, canary)),
      [%{id: canary, owner: :device_local, outcome: :passed} | tl(report)]
    ]

    for invalid <- invalid_reports do
      assert {:error, rule} = Contract.validate_report(invalid)

      assert rule in [
               "CW-NOTIFICATION-ASSERTIONS-COMPLETE",
               "CW-NOTIFICATION-ASSERTIONS-ORDER",
               "CW-NOTIFICATION-ASSERTIONS-OWNER"
             ]

      refute inspect(rule) =~ canary
    end
  end

  test "source-binds a valid report through CrossWake Evidence.check/2 and fails closed on mismatch" do
    report = fixture_report()

    with_evidence_path(fn path ->
      assert :ok = Contract.validate_source_bound(report, path)

      assert {:error, "CW-NOTIFICATION-SOURCE-BOUND"} =
               Contract.validate_source_bound(report, path <> "-missing")
    end)
  end

  test "the physical host allows only declared local-network callback transport" do
    ios_root =
      Path.expand(
        "../../../examples/phoenix_host/native/ios",
        __DIR__
      )

    plist = File.read!(Path.join(ios_root, "CrosswakeProofLane/Info.plist"))
    project = File.read!(Path.join(ios_root, "CrosswakeProofLane.xcodeproj/project.pbxproj"))

    assert plist =~ "<key>NSLocalNetworkUsageDescription</key>"
    assert plist =~ "<key>NSAppTransportSecurity</key>"
    assert plist =~ "<key>NSAllowsLocalNetworking</key>"
    refute plist =~ "NSAllowsArbitraryLoads"

    assert length(Regex.scan(~r/GENERATE_INFOPLIST_FILE = NO;/, project)) == 2
    assert length(Regex.scan(~r{INFOPLIST_FILE = CrosswakeProofLane/Info.plist;}, project)) == 2
  end

  test "the source-owned task promotes a closed notification result" do
    root =
      Path.join(
        System.tmp_dir!(),
        "crosswake-chimeway-notification-task-#{System.unique_integer([:positive])}"
      )

    destination = Path.join(root, "physical_iphone")
    File.mkdir_p!(root)

    try do
      assert {:ok, result} =
               Mix.Tasks.Crosswake.ProofLane.ChimewayNotificationPhysical.run_with([
                 "--input",
                 @fixture,
                 "--destination",
                 destination,
                 "--ios-runtime-line",
                 "26.6",
                 "--json"
               ])

      assert result.outcome == "passed"
      assert result.owner == "crosswake"
      assert result.run_ref == "cw-physical-fixture-0001"
      assert :ok = Contract.validate_source_bound(fixture_report(), destination)
    after
      File.rm_rf(root)
    end
  end

  defp fixture_report do
    %{"assertions" => assertions} = @fixture |> File.read!() |> Jason.decode!()

    Enum.map(assertions, fn %{"id" => id, "owner" => owner, "outcome" => outcome} ->
      %{id: id, owner: String.to_existing_atom(owner), outcome: String.to_existing_atom(outcome)}
    end)
  end

  defp with_evidence_path(fun) do
    root =
      Path.join(
        System.tmp_dir!(),
        "crosswake-chimeway-notification-#{System.unique_integer([:positive])}"
      )

    destination = Path.join(root, "physical_iphone")
    File.mkdir_p!(root)

    try do
      assert :ok = Evidence.promote(physical_candidate(), destination)
      fun.(destination)
    after
      File.rm_rf(root)
    end
  end

  defp physical_candidate do
    %{
      schema_version: "1",
      crosswake_version: "1.0.0",
      template_version: "1",
      commit_ref: "git-0123456789abcdef0123456789abcdef01234567",
      route_id: "route-0123456789abcdef",
      assertion_ids: Enum.map(@expected, & &1.id),
      status: :passed,
      outcome: :passed,
      captured_at: "2026-08-26T12:00:00Z",
      retention_label: :brief,
      device_class: :physical_iphone,
      ios_runtime_line: "18.0",
      approved_hashes: [
        %{
          kind: :chimeway_notification_run_contract,
          canonical_bytes: canonical_notification_run_contract()
        }
      ]
    }
  end

  defp canonical_notification_run_contract do
    Jason.encode!(%{
      "schema_version" => 1,
      "device_class" => "physical_iphone",
      "ios_runtime_line" => "18.0",
      "outcome" => "passed",
      "assertions" =>
        @expected
        |> Enum.map(fn %{id: id, owner: owner} ->
          %{"id" => id, "owner" => Atom.to_string(owner), "outcome" => "passed"}
        end)
    })
  end
end
