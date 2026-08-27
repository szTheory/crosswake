defmodule CrosswakeExample.PhysicalIphoneProofHostTest do
  use ExUnit.Case, async: false

  alias Crosswake.ProofLane.{Evidence, PhysicalIphoneContract, PhysicalIphonePreflight}
  alias CrosswakeExample.E2E.ReplayAuthority

  alias CrosswakeExample.LocalFirst.{
    PhysicalIphoneAuthority,
    PhysicalIphoneRunProvenance,
    ReviewEvent
  }

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

  test "a proof ticket is single-use and a host that did not mint it fails closed" do
    assert {:ok, run} = PhysicalIphoneRunProvenance.start()
    assert :ok = PhysicalIphoneRunProvenance.claim(run.nonce, run.mutation_id)
    assert {:error, :unavailable} = PhysicalIphoneRunProvenance.claim(run.nonce, run.mutation_id)

    assert {:error, :unavailable} =
             PhysicalIphoneRunProvenance.claim(
               "remote-host-ticket-000000000000000000",
               run.mutation_id
             )

    assert :ok = PhysicalIphoneRunProvenance.cleanup(run)
  end

  test "physical Xcode invocation builds once, injects the exact UI-test environment, and runs quietly" do
    source = File.read!("lib/crosswake_example/physical_iphone_proof_host.ex")

    assert source =~
             ~r/build_args = \[\s*"-quiet",\s*"-project",.*?"build-for-testing"/s

    assert source =~ ~r/exactly_one_xctestrun\(derived_data\)/
    assert source =~ ~r/\[xctestrun\] -> \{:ok, xctestrun\}/
    assert source =~ ~r/test-without-building.*?-xctestrun.*?xctestrun/s

    for key <- [
          "CROSSWAKE_REFERENCE_HOST_SCOPE_REF",
          "CROSSWAKE_REFERENCE_HOST_BASE_URL",
          "CROSSWAKE_REFERENCE_HOST_ESTABLISH_ACTION",
          "CROSSWAKE_REFERENCE_HOST_PHYSICAL_PROOF_NONCE",
          "CROSSWAKE_REFERENCE_HOST_PHYSICAL_MUTATION_ID"
        ] do
      assert source =~
               "replace_plist_string(\n             environment_plist,\n             \"#{key}\""
    end

    assert source =~ "GENERATE_INFOPLIST_FILE=NO"
    assert source =~ "INFOPLIST_FILE=\#{@physical_info_plist}"
  end

  test "physical-only app plist allows local networking without arbitrary loads" do
    plist = File.read!("native/ios/CrosswakeProofLane/PhysicalProofInfo.plist")

    assert plist =~ "<key>NSAppTransportSecurity</key>"
    assert plist =~ "<key>NSAllowsLocalNetworking</key>"
    assert plist =~ "<key>NSLocalNetworkUsageDescription</key>"
    refute plist =~ "NSAllowsArbitraryLoads"
  end

  test "invalid device contracts remain unavailable without invoking Xcode" do
    assert {:error, :unavailable} = PhysicalIphoneProofHost.device_report(%{})
  end

  test "backend producer fails closed without the device-created replay effect" do
    contract = %{schema_version: 1, device_class: :physical_iphone}
    assert {:error, :unavailable} = PhysicalIphoneAuthority.report(contract)
    assert Repo.aggregate(ReviewEvent, :count, :id) == 0
  end

  test "backend report clears the process-local run after an unavailable result" do
    contract = %{schema_version: 1, device_class: :physical_iphone}
    assert {:ok, run} = PhysicalIphoneRunProvenance.start()
    Process.put({PhysicalIphoneProofHost, :physical_run}, run)

    assert {:error, :unavailable} = PhysicalIphoneProofHost.backend_report(contract)
    refute Process.get({PhysicalIphoneProofHost, :physical_run})
    refute PhysicalIphoneRunProvenance.active?(run.nonce, run.mutation_id)
  end

  test "backend producer rejects stale, wrong-run, and wrong-mutation rows without exposing proof values" do
    scope = ReplayAuthority.physical_fixture().scope_ref
    assert {:ok, run} = PhysicalIphoneRunProvenance.start()
    assert :ok = PhysicalIphoneRunProvenance.claim(run.nonce, run.mutation_id)

    %ReviewEvent{}
    |> ReviewEvent.changeset(%{
      scope_ref: scope,
      client_mutation_id: "00000000-0000-4000-8000-000000000111",
      card_id: 1,
      rating: "good",
      free_form_answer: "neutral-answer",
      physical_proof_nonce: run.nonce
    })
    |> Repo.insert!()

    assert {:error, :unavailable} =
             PhysicalIphoneAuthority.report(
               %{schema_version: 1, device_class: :physical_iphone},
               run
             )

    Repo.delete_all(ReviewEvent)

    %ReviewEvent{}
    |> ReviewEvent.changeset(%{
      scope_ref: scope,
      client_mutation_id: run.mutation_id,
      card_id: 1,
      rating: "good",
      free_form_answer: "neutral-answer",
      physical_proof_nonce: "wrong-run-nonce-value-0000000000000000"
    })
    |> Repo.insert!()

    assert {:error, :unavailable} =
             PhysicalIphoneAuthority.report(
               %{schema_version: 1, device_class: :physical_iphone},
               run
             )

    Repo.delete_all(ReviewEvent)

    %ReviewEvent{}
    |> ReviewEvent.changeset(%{
      scope_ref: scope,
      client_mutation_id: run.mutation_id,
      card_id: 1,
      rating: "good",
      free_form_answer: "neutral-answer",
      physical_proof_nonce: run.nonce
    })
    |> Repo.insert!()

    Process.put({PhysicalIphoneProofHost, :physical_run}, run)

    assert report =
             PhysicalIphoneProofHost.backend_report(%{
               schema_version: 1,
               device_class: :physical_iphone
             })

    refute report =~ run.nonce
    refute report =~ run.mutation_id

    assert Repo.aggregate(ReviewEvent, :count, :id) == 0
    refute Process.get({PhysicalIphoneProofHost, :physical_run})
    refute PhysicalIphoneRunProvenance.active?(run.nonce, run.mutation_id)
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

  test "transaction source handoff stays private and disabled by default" do
    source = File.read!("lib/crosswake_example/physical_iphone_proof_host.ex")

    assert source =~ "maybe_write_transaction_sources"
    assert source =~ "CROSSWAKE_PHYSICAL_IPHONE_TRANSACTION_CAPTURE"

    assert File.read!("../../script/retain_physical_iphone_evidence_transaction.sh") =~
             "binary_to_term"
  end
end
