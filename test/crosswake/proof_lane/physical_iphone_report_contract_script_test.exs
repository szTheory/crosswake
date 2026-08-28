defmodule Crosswake.ProofLane.PhysicalIphoneReportContractScriptTest do
  use ExUnit.Case, async: false

  alias Mix.Tasks.Crosswake.ProofLane.PhysicalIphone

  @root Path.expand("../../..", __DIR__)
  @script Path.join(@root, "script/verify_physical_iphone_report_contract.sh")

  test "malformed, passed, partial, extra-key, wrong-class, and wrong-ID simulator envelopes fail closed" do
    valid = envelope(:device_local, "unavailable")

    invalid_envelopes = [
      "malformed",
      envelope(:device_local, "passed"),
      put_in(valid, ["assertions"], Enum.drop(valid["assertions"], 1)),
      Map.put(valid, "owner", "device_local"),
      Map.put(valid, "device_class", "simulator"),
      put_in(valid, ["assertions", Access.at(0), "id"], "PI-UNKNOWN")
    ]

    for device <- invalid_envelopes do
      {output, status} = run_contract(device)

      assert status != 0
      refute output =~ "PI-CONTRACT-SERIALIZATION"
    end
  end

  test "the script validates an unavailable simulator envelope with the real parser" do
    {output, status} = run_contract(envelope(:device_local, "unavailable"))

    assert status == 0

    assert Jason.decode!(output) == %{
             "outcome" => "passed",
             "scope" => "advisory",
             "rule_id" => "PI-CONTRACT-SERIALIZATION"
           }
  end

  test "real parser and owner-disjoint join accept only passed canonical fixtures" do
    device = Jason.encode!(envelope(:device_local, "passed"))
    backend = Jason.encode!(envelope(:backend_authority, "passed"))

    assert {:ok, device_entries} = PhysicalIphone.parse_report(device, :device_local)
    assert {:ok, backend_entries} = PhysicalIphone.parse_report(backend, :backend_authority)

    assert {:ok, %{outcome: "passed"}} =
             PhysicalIphone.join_report_entries(device_entries, backend_entries)

    assert {:error, "PI-REPORT-OWNER"} = PhysicalIphone.parse_report(device, :backend_authority)

    assert {:ok, unavailable_entries} =
             PhysicalIphone.parse_report(
               Jason.encode!(envelope(:device_local, "unavailable")),
               :device_local
             )

    assert {:error, "PI-REPORT-COMPLETE"} =
             PhysicalIphone.join_report_entries(unavailable_entries, backend_entries)

    assert {:error, "PI-REPORT-ENVELOPE"} =
             PhysicalIphone.parse_report("malformed", :device_local)

    assert {:error, "PI-REPORT-OWNER"} =
             PhysicalIphone.parse_report(
               Jason.encode!(put_in(envelope(:device_local, "passed"), ["assertions"], [])),
               :device_local
             )
  end

  defp run_contract(device) do
    root =
      Path.join(
        System.tmp_dir!(),
        "physical-contract-script-#{System.unique_integer([:positive])}"
      )

    bin = Path.join(root, "bin")
    File.mkdir_p!(bin)

    on_exit(fn -> File.rm_rf(root) end)

    output = if is_binary(device), do: device, else: Jason.encode!(device)
    xcodebuild = "#!/usr/bin/env bash\nprintf '%s\\n' '#{output}'\n"

    File.write!(Path.join(bin, "xcodebuild"), xcodebuild)
    File.chmod!(Path.join(bin, "xcodebuild"), 0o755)

    System.cmd("bash", [@script],
      cd: @root,
      env: [
        {"PATH", bin <> ":" <> System.get_env("PATH", "")}
      ],
      stderr_to_stdout: true
    )
  end

  defp envelope(owner, outcome) do
    %{
      "schema_version" => Crosswake.ProofLane.PhysicalIphoneContract.schema_version(),
      "device_class" => "physical_iphone",
      "assertions" =>
        Crosswake.ProofLane.PhysicalIphoneContract.assertions()
        |> Enum.filter(&(&1.owner == owner))
        |> Enum.map(&%{"id" => &1.id, "outcome" => outcome})
    }
  end
end
