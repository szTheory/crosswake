defmodule Crosswake.Proof.Phase175ReceiptArtifactRosterTest do
  use ExUnit.Case, async: true

  @helper "script/release_candidate/assert_candidate_receipt_artifact.sh"
  @expected ~w(artifacts.json candidate-receipt.json candidate-receipt.md)

  test "accepts the exact canonical receipt artifact roster" do
    dir = temp_dir!()
    on_exit(fn -> File.rm_rf!(dir) end)
    write_roster!(dir, @expected)

    assert run_helper(dir) == 0
  end

  test "rejects a missing receipt member" do
    dir = temp_dir!()
    on_exit(fn -> File.rm_rf!(dir) end)
    write_roster!(dir, Enum.drop(@expected, -1))

    assert run_helper(dir) != 0
  end

  test "rejects an extra top-level receipt member" do
    dir = temp_dir!()
    on_exit(fn -> File.rm_rf!(dir) end)
    write_roster!(dir, @expected ++ ["unexpected.txt"])

    assert run_helper(dir) != 0
  end

  test "rejects nested receipt files" do
    dir = temp_dir!()
    on_exit(fn -> File.rm_rf!(dir) end)
    write_roster!(dir, @expected)
    File.mkdir!(Path.join(dir, "nested"))
    File.write!(Path.join([dir, "nested", "extra.json"]), "{}")

    assert run_helper(dir) != 0
  end

  test "rejects a symlinked receipt member" do
    dir = temp_dir!()
    on_exit(fn -> File.rm_rf!(dir) end)
    write_roster!(dir, @expected)

    linked_member = Path.join(dir, "candidate-receipt.json")
    File.rm!(linked_member)
    File.ln_s!(Path.join(dir, "artifacts.json"), linked_member)

    assert run_helper(dir) != 0
  end

  defp write_roster!(dir, names) do
    Enum.each(names, &File.write!(Path.join(dir, &1), "{}"))
  end

  defp run_helper(dir) do
    case System.cmd("bash", [@helper, dir], stderr_to_stdout: true) do
      {_output, status} -> status
    end
  end

  defp temp_dir! do
    dir = Path.join(System.tmp_dir!(), "phase175-receipt-#{System.unique_integer([:positive])}")
    File.mkdir_p!(dir)
    dir
  end
end
