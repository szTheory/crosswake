defmodule Mix.Tasks.Crosswake.Gen.ProofLaneTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  @task "crosswake.gen.proof_lane"

  test "generates an isolated iOS proof lane, retains opaque evidence, and never clobbers host edits" do
    root = Path.join(System.tmp_dir!(), "crosswake_proof_lane_#{System.unique_integer([:positive])}")
    ios_root = Path.join(root, "native/ios")
    evidence_path = Path.join(root, "retained-evidence")

    previous = Application.get_env(:crosswake, :proof_lane)

    Application.put_env(:crosswake, :proof_lane,
      route_id: "route-0123456789abcdef",
      route_path: "/study/:id",
      indexed_db_database: "proof_lane",
      indexed_db_store: "mutations",
      mutation_id_path: "client_mutation_id",
      sync_path: "/study/sync",
      evidence_path: "/_proof/evidence",
      router: CrosswakeWeb.Router,
      ios_shell_root: ios_root
    )

    try do
      capture_io(fn -> Mix.Task.rerun(@task, ["ios"]) end)

      expected = [
        Path.join(root, "test/crosswake_proof_lane/crosswake_proof_lane_test.exs"),
        Path.join(root, "e2e/crosswake_proof_lane/proof_lane.spec.ts"),
        Path.join(ios_root, "CrosswakeProofLane/ProofLaneDriver.swift"),
        Path.join(ios_root, "CrosswakeProofLane.xcodeproj/project.pbxproj"),
        Path.join(root, ".crosswake/proof_lane.json")
      ]

      Enum.each(expected, &assert File.regular?(&1))

      test_source = File.read!(Enum.at(expected, 0))
      assert {:ok, _} = Code.string_to_quoted(test_source)
      assert File.read!(Enum.at(expected, 1)) =~ "runOfflineIslandProof"

      driver = File.read!(Enum.at(expected, 2))
      assert driver =~ "case passed"
      assert driver =~ "case blocked"
      assert driver =~ "case unavailable"

      assert File.read!(Enum.at(expected, 3)) =~ "CrosswakeProofLaneUITests"
      assert {:ok, manifest} = Jason.decode(File.read!(Enum.at(expected, 4)))
      assert manifest["template_version"] == 1

      assert {:ok, evidence} =
               Crosswake.ProofLane.Evidence.build(%{
                 assertion_id: "shell_boot",
                 outcome: "blocked"
               })

      assert :ok = Crosswake.ProofLane.Evidence.promote(evidence, evidence_path)
      assert File.regular?(Path.join(evidence_path, "evidence.json"))
      refute File.read!(Path.join(evidence_path, "evidence.json")) =~ "/study/sync"

      Enum.each(expected, fn path -> File.write!(path, "host edit: #{Path.basename(path)}\n") end)
      output = capture_io(fn -> Mix.Task.rerun(@task, ["ios"]) end)

      Enum.each(expected, fn path ->
        assert File.read!(path) == "host edit: #{Path.basename(path)}\n"
      end)

      assert output =~ "reused"
    after
      if previous, do: Application.put_env(:crosswake, :proof_lane, previous), else: Application.delete_env(:crosswake, :proof_lane)
      File.rm_rf!(root)
    end
  end
end
