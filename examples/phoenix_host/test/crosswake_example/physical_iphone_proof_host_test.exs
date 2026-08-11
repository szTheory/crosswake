defmodule CrosswakeExample.PhysicalIphoneProofHostTest do
  use ExUnit.Case, async: false

  alias Crosswake.ProofLane.{Evidence, PhysicalIphoneContract, PhysicalIphonePreflight}
  alias CrosswakeExample.LocalFirst.{PhysicalIphoneAuthority, ReviewEvent}
  alias CrosswakeExample.{PhysicalIphoneProofHost, Repo}
  alias Mix.Tasks.Crosswake.ProofLane.PhysicalIphone, as: PhysicalIphoneTask

  setup do
    Repo.delete_all(ReviewEvent)
    on_exit(fn -> Repo.delete_all(ReviewEvent) end)
    :ok
  end

  test "generated reference host exposes every closed preflight category" do
    assert is_list(PhysicalIphoneProofHost.preflight_options())

    readiness = PhysicalIphonePreflight.readiness(PhysicalIphoneProofHost.preflight_options())

    assert Enum.map(readiness.checks, & &1.id) == [
             "PI-PREFLIGHT-INVENTORY",
             "PI-PREFLIGHT-CONFIG",
             "PI-PREFLIGHT-GENERATED-LANE",
             "PI-PREFLIGHT-DESTINATION",
             "PI-PREFLIGHT-SIGNING",
             "PI-PREFLIGHT-HOST",
             "PI-PREFLIGHT-FIXTURE",
             "PI-PREFLIGHT-MEDIA",
             "PI-PREFLIGHT-REPLAY",
             "PI-PREFLIGHT-REJECTION-CONFLICT",
             "PI-PREFLIGHT-SCOPE",
             "PI-PREFLIGHT-FEATURE-CONTROLS",
             "PI-PREFLIGHT-DESTINATION-PARENT"
           ]

    assert Enum.all?(readiness.checks, &(&1.state in [:ready, :blocked]))
  end

  test "invalid device contracts remain unavailable without invoking Xcode" do
    assert {:error, :unavailable} = PhysicalIphoneProofHost.device_report(%{})
  end

  test "backend producer independently emits its exact owner-free report" do
    contract = %{schema_version: 1, device_class: :physical_iphone}
    report = PhysicalIphoneAuthority.report(contract)
    assert is_binary(report)
    assert {:ok, assertions} = PhysicalIphoneTask.parse_report(report, :backend_authority)
    assert length(assertions) == 4
    assert Enum.all?(assertions, &(&1.owner == :backend_authority and &1.outcome == :passed))
    assert Repo.aggregate(ReviewEvent, :count, :id) == 0
  end

  test "passed joined candidate becomes a closed evidence input" do
    Process.put({PhysicalIphoneProofHost, :ios_runtime_line}, "26.5")

    assertions =
      PhysicalIphoneContract.assertions()
      |> Enum.reject(&(&1.owner == :evidence_promotion))
      |> Enum.map(&Map.put(&1, :outcome, :passed))

    input =
      PhysicalIphoneProofHost.evidence_input(%{
        outcome: "passed",
        schema_version: 1,
        device_class: "physical_iphone",
        assertions: assertions
      })

    assert is_map(input)

    assert {:ok, evidence} = Evidence.build(input)
    assert evidence.device_class == :physical_iphone
    assert evidence.assertion_ids == Enum.map(PhysicalIphoneContract.assertions(), & &1.id)
    refute Process.get({PhysicalIphoneProofHost, :ios_runtime_line})
  end
end
