defmodule Crosswake.Proof.Phase52OperatorTruthTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias Crosswake.TestSupport.ProofAssertions

  @inspect_task "crosswake.inspect"
  @doctor_task "crosswake.doctor"
  @inspect_fixture "test/fixtures/proof/phase52_operator_inspection.json"
  @readiness_fixture "test/fixtures/proof/phase52_publish_readiness.json"

  @tag :phase52_smoke
  test "stable proof id helper contract is present for operator drift checks" do
    message =
      ProofAssertions.stable_id_message(
        "proof.operator.inspect.schema_version",
        "operator inspection schema version",
        "Crosswake.OperatorInspection.Types.schema_version/0",
        "schema_version drift",
        "test/fixtures/proof/phase52_operator_inspection.json",
        "update canonical inspection output and fixture together",
        :merge_blocking
      )

    assert message =~ "proof.operator.inspect.schema_version"
    assert message =~ "merge_blocking"
  end

  test "normalized inspect json matches fixture and keeps schema stable" do
    output =
      capture_io(fn ->
        Mix.Task.reenable(@inspect_task)

        Mix.Task.run(@inspect_task, [
          "--router",
          "Elixir.Crosswake.TestSupport.RouterFixtures.ManagedRouter",
          "--format",
          "json"
        ])
      end)

    assert output =~ "\"schema_version\""

    ProofAssertions.assert_normalized_json_fixture(
      "proof.operator.inspect.json_contract",
      output,
      @inspect_fixture,
      source: "mix crosswake.inspect --format json",
      path: @inspect_fixture,
      hint: "normalize volatile fields and refresh fixture only for intended semantic changes",
      posture: :merge_blocking
    )
  end

  test "normalized publish-readiness json matches fixture and keeps readiness semantics stable" do
    output =
      capture_io(fn ->
        Mix.Task.reenable(@doctor_task)

        try do
          Mix.Task.run(@doctor_task, [
            "--router",
            "Elixir.Crosswake.TestSupport.RouterFixtures.ManagedRouter",
            "--format",
            "json",
            "--check-publish"
          ])
        rescue
          Mix.Error -> :ok
        end
      end)

    decoded = Jason.decode!(output)
    assert decoded["publish_readiness"]["schema_version"] == "1.0.0"

    ProofAssertions.assert_normalized_json_fixture(
      "proof.readiness.publish.json_contract",
      Jason.encode!(decoded["publish_readiness"]),
      @readiness_fixture,
      source: "mix crosswake.doctor --check-publish --format json",
      path: @readiness_fixture,
      hint: "preserve readiness category/code/proof-class/rebuild semantics when updating fixture",
      posture: :merge_blocking
    )
  end

  test "support matrix generated guide and authored docs keep non-claims in sync" do
    ProofAssertions.assert_file_exact(
      "proof.docs.support_matrix.byte_parity",
      "guides/support_matrix.md",
      Crosswake.SupportMatrix.Renderer.render(Crosswake.SupportMatrix.canonical()),
      source: "Crosswake.SupportMatrix.Renderer.render/1",
      hint: "regenerate support matrix guide from canonical renderer output",
      posture: :merge_blocking
    )

    ProofAssertions.assert_contains_exact(
      "proof.docs.non_claims.store_providers",
      "guides/support_matrix.md",
      "StoreKit and Play Billing adapters are not shipped in v3.6",
      source: "Crosswake.SupportMatrix.canonical/1",
      hint: "keep provider non-claims explicit in public docs",
      posture: :merge_blocking
    )

    ProofAssertions.assert_contains_exact(
      "proof.docs.non_claims.sigra_contract_only",
      "guides/companions.md",
      "Sigra is contract-only",
      source: "guides/companions.md and auth contract support truth",
      hint: "do not imply full Sigra machinery shipped",
      posture: :merge_blocking
    )
  end

  test "hermetic lane guard keeps module untagged at file level and env-independent" do
    source = File.read!(__ENV__.file)

    refute Regex.match?(~r/^\s*@moduletag\s+:/m, source)
    refute String.contains?(source, "Crosswake" <> "Example.")
    refute String.contains?(source, "MIX_INCLUDE_")
  end
end
