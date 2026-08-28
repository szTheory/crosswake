defmodule CrosswakeExample.LocalFirst.PhysicalIphoneAuthorityTest do
  use ExUnit.Case, async: false

  import Phoenix.ConnTest, only: [build_conn: 0]

  alias CrosswakeExample.LocalFirst.ReviewEvent
  alias CrosswakeExample.LocalFirst.{PhysicalIphoneAuthority, PhysicalIphoneRunProvenance}
  alias CrosswakeExample.LocalFirst.PhysicalIphoneAuthorityFixture
  alias CrosswakeExample.Repo

  test "Phoenix independently returns every closed backend authority observation" do
    assert {:ok, report} = PhysicalIphoneAuthorityFixture.run()

    assert %{
             "schema_version" => schema_version,
             "device_class" => "physical_iphone",
             "assertions" => assertions
           } = report

    assert schema_version == Crosswake.ProofLane.PhysicalIphoneContract.schema_version()

    assert assertions ==
             Crosswake.ProofLane.PhysicalIphoneContract.assertions()
             |> Enum.filter(&(&1.owner == :backend_authority))
             |> Enum.map(&%{"id" => &1.id, "outcome" => "passed"})

    rendered = Jason.encode!(report)

    for forbidden <- ["fixture-alpha", "fixture-beta", "selected-private", "free-form-private"] do
      refute rendered =~ forbidden
    end
  end

  test "reference host persists a bounded free-form answer only in an exact admitted mutation" do
    scope = "v1.fixture_alpha_scope_001"

    event = %{
      "client_mutation_id" => "00000000-0000-4000-8000-000000000099",
      "card_id" => 1,
      "rating" => "good",
      "free_form_answer" => "neutral-answer"
    }

    assert {:ok, result} =
             CrosswakeExample.LocalFirst.SyncController.sync_events(
               build_conn(),
               scope,
               [event],
               CrosswakeExample.LocalFirst.PhysicalIphoneAuthorityFixture.opts()
             )

    assert [%{outcome: :accepted}] = result.accepted_records

    assert %ReviewEvent{free_form_answer: "neutral-answer", scope_ref: ^scope} =
             Repo.get_by(ReviewEvent, client_mutation_id: event["client_mutation_id"])
  end

  test "prepared case cannot pass verification before a correlated device result" do
    assert {:ok, run} = PhysicalIphoneRunProvenance.start()
    assert :ok = PhysicalIphoneRunProvenance.claim(run.nonce, run.mutation_id)

    assert {:ok, :prepared} = PhysicalIphoneAuthority.prepare_case(run, :rejection)
    assert {:error, :unavailable} = PhysicalIphoneAuthority.verify_case(run, :rejection)

    assert :ok =
             PhysicalIphoneAuthority.observe_device_result(
               %{"physical_proof_nonce" => run.nonce, "client_mutation_id" => run.mutation_id},
               :rejected
             )

    assert {:ok, :passed} = PhysicalIphoneAuthority.verify_case(run, :rejection)
    assert {:error, :unavailable} = PhysicalIphoneAuthority.verify_case(run, :rejection)

    assert :ok = PhysicalIphoneRunProvenance.cleanup(run)
  end
end
