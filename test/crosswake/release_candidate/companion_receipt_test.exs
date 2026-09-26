defmodule Crosswake.ReleaseCandidate.CompanionReceiptTest do
  use ExUnit.Case, async: true

  alias Crosswake.ReleaseCandidate.CompanionReceipt

  @head String.duplicate("b", 40)
  @base String.duplicate("a", 40)
  @tree String.duplicate("c", 40)

  test "a package-specific same-head CI and Hex rehearsal create a deterministic canonical receipt" do
    input = fixture()

    assert {:ok, first} = CompanionReceipt.build(input)
    assert {:ok, second} = CompanionReceipt.build(input)
    assert first.digest == second.digest
    assert first.canonical_bytes == second.canonical_bytes
    assert first.receipt["package"] == "crosswake_chimeway"
    assert first.receipt["candidate"]["pr"] == 115
    assert first.receipt["hex_run_id"] == 52002

    assert Enum.map(first.receipt["proofs"], & &1["id"]) == [
             "candidate",
             "ci",
             "hex_rehearsal",
             "package_row"
           ]
  end

  test "core and unknown packages, mismatched sources, stale runs, and missing package rows are rejected" do
    input = fixture()

    assert {:error, _} = CompanionReceipt.build(put_in(input, ["package"], "crosswake"))
    assert {:error, _} = CompanionReceipt.build(put_in(input, ["package"], "unknown_package"))
    assert {:error, _} = CompanionReceipt.build(put_in(input, ["candidate", "ci_run_id"], 900))

    assert {:error, _} =
             CompanionReceipt.build(
               put_in(input, ["hex_rehearsal", "head_oid"], String.duplicate("9", 40))
             )

    assert {:error, _} =
             CompanionReceipt.build(
               put_in(input, ["hex_rehearsal", "external_state_changed"], true)
             )

    assert {:error, _} = CompanionReceipt.build(Map.delete(input, "package_row"))

    assert {:error, _} =
             CompanionReceipt.build(put_in(input, ["sources", "package_row", "bytes"], ""))
  end

  test "a different package row cannot be used to mint the selected companion receipt" do
    input = fixture()
    wrong_row = put_in(input, ["package_row", "package"], "crosswake_rulestead")

    assert {:error, _} = CompanionReceipt.build(wrong_row)
  end

  test "the Mix task writes only a local receipt artifact and prints its digest" do
    input = fixture()
    root = Path.join(System.tmp_dir!(), "crosswake-receipt-#{System.unique_integer([:positive])}")
    input_path = Path.join(root, "input.json")
    output_path = Path.join(root, "receipt.json")
    File.mkdir_p!(root)
    File.write!(input_path, Jason.encode!(input))

    {output, status} =
      System.cmd(
        "mix",
        ["crosswake.release.receipt", "--input", input_path, "--output", output_path],
        env: [{"MIX_ENV", "test"}],
        stderr_to_stdout: true
      )

    artifact = output_path |> File.read!() |> Jason.decode!()
    File.rm_rf!(root)

    assert status == 0, output
    assert output =~ "REL-17 RECEIPT PASS package=crosswake_chimeway digest="
    assert artifact["schema_version"] == 1
    assert artifact["receipt"]["package"] == "crosswake_chimeway"
    assert artifact["receipt_digest"] =~ ~r/\A[0-9a-f]{64}\z/
    refute Map.has_key?(artifact["receipt"], "authorized")
  end

  defp fixture do
    package = "crosswake_chimeway"
    version = "0.1.1"

    candidate = %{
      "pr" => 115,
      "base_oid" => @base,
      "head_oid" => @head,
      "tree_oid" => @tree,
      "ci_run_id" => 52001
    }

    ci = %{"run_id" => 52001, "head_oid" => @head, "conclusion" => "success"}

    hex_rehearsal = %{
      "run_id" => 52002,
      "head_oid" => @head,
      "package" => package,
      "version" => version,
      "external_state_changed" => false,
      "target_absent" => true
    }

    package_row = %{
      "run_id" => 52002,
      "package" => package,
      "version" => version,
      "candidate_ref" => @head,
      "outer_checksum" => String.duplicate("1", 64),
      "metadata_digest" => String.duplicate("2", 64),
      "payload_digest" => String.duplicate("3", 64)
    }

    %{
      "package" => package,
      "version" => version,
      "candidate" => candidate,
      "ci" => ci,
      "hex_rehearsal" => hex_rehearsal,
      "package_row" => package_row,
      "sources" => %{
        "candidate" => source("candidate.json", candidate),
        "ci" => source("ci.json", ci),
        "hex_rehearsal" => source("hex-rehearsal.json", hex_rehearsal),
        "package_row" => source("package-row.json", package_row)
      }
    }
  end

  defp source(path, facts), do: %{"path" => path, "bytes" => Jason.encode!(facts)}
end
