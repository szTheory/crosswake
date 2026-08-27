defmodule CrosswakeExample.PhysicalIphoneProofHostTest do
  use ExUnit.Case, async: false

  alias Crosswake.ProofLane.{Evidence, PhysicalIphoneContract, PhysicalIphonePreflight}
  alias CrosswakeExample.E2E.ReplayAuthority
  alias CrosswakeExample.LocalFirst.{PhysicalIphoneAuthority, ReviewEvent}
  alias CrosswakeExample.{PhysicalIphoneProofHost, Repo}

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

  test "physical replay fixture is a closed host-owned lifecycle contract" do
    assert %{
             scope_ref: scope,
             establish_action: "establish",
             switch_action: "switch",
             logout_action: "clear"
           } = ReplayAuthority.physical_fixture()

    assert is_binary(scope)
    refute scope == ""
  end

  test "physical Xcode invocation uses quiet mode before executing the focused UI contract" do
    source = File.read!("lib/crosswake_example/physical_iphone_proof_host.ex")

    assert source =~
             ~r/args = \[\s*"-quiet",\s*"-project",.*?only-testing:CrosswakeProofLaneUITests\/ProofLaneUITests\/testReferenceHostPhysicalStudyContract/s
  end

  test "invalid device contracts remain unavailable without invoking Xcode" do
    assert {:error, :unavailable} = PhysicalIphoneProofHost.device_report(%{})
  end

  test "backend producer fails closed without the device-created replay effect" do
    contract = %{schema_version: 1, device_class: :physical_iphone}
    assert {:error, :unavailable} = PhysicalIphoneAuthority.report(contract)
    assert Repo.aggregate(ReviewEvent, :count, :id) == 0
  end

  test "backend producer accepts only the matching scoped device-created effect" do
    scope = ReplayAuthority.physical_fixture().scope_ref

    %ReviewEvent{}
    |> ReviewEvent.changeset(%{
      scope_ref: scope,
      client_mutation_id: "00000000-0000-4000-8000-000000000111",
      card_id: 1,
      rating: "good",
      free_form_answer: "neutral-answer"
    })
    |> Repo.insert!()

    assert is_binary(
             PhysicalIphoneAuthority.report(%{schema_version: 1, device_class: :physical_iphone})
           )

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
