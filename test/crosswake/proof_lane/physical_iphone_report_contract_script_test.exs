defmodule Crosswake.ProofLane.PhysicalIphoneReportContractScriptTest do
  use ExUnit.Case, async: false

  @root Path.expand("../../..", __DIR__)
  @script Path.join(@root, "script/verify_physical_iphone_report_contract.sh")

  test "Phoenix producer failures and invalid output cannot reach the advisory join" do
    for producer <- [
          "exit 9",
          ":",
          "printf malformed",
          "printf '%s' '{\"schema_version\":1,\"device_class\":\"physical_iphone\",\"assertions\":[]}'"
        ] do
      {output, status} = run_contract(producer)

      assert status != 0
      refute output =~ "PI-CONTRACT-SERIALIZATION"
    end
  end

  test "the script supplies producer bytes unchanged to the backend report parser" do
    producer =
      "printf '%s' '{\"schema_version\":1,\"device_class\":\"physical_iphone\",\"assertions\":[{\"id\":\"PI-LOGOUT-ACCOUNT-FENCE\",\"outcome\":\"passed\"},{\"id\":\"PI-ENTRY-DISABLEMENT\",\"outcome\":\"passed\"},{\"id\":\"PI-REPLAY-DISABLEMENT\",\"outcome\":\"passed\"},{\"id\":\"PI-EXACTLY-ONCE-EMPTY-OUTBOX\",\"outcome\":\"passed\"}]}'"

    {output, status} = run_contract(producer)

    assert status == 0
    assert output =~ "PI-CONTRACT-SERIALIZATION"
  end

  defp run_contract(producer) do
    root =
      Path.join(
        System.tmp_dir!(),
        "physical-contract-script-#{System.unique_integer([:positive])}"
      )

    bin = Path.join(root, "bin")
    File.mkdir_p!(bin)

    on_exit(fn -> File.rm_rf(root) end)

    device =
      ~s|#!/usr/bin/env bash\nprintf '%s\\n' '{"assertions":[{"id":"PI-PACK-AUDIO-OFFLINE","outcome":"passed"},{"id":"PI-OFFLINE-RELAUNCH-REPLAY","outcome":"passed"},{"id":"PI-REJECTED-RETAINED","outcome":"passed"},{"id":"PI-RECOVERY-ACTION","outcome":"passed"},{"id":"PI-REDACTED-EVIDENCE","outcome":"passed"}],"device_class":"physical_iphone","schema_version":1}'\n|

    mix = """
    #!/usr/bin/env bash
    if [[ "$1" == "run" && -n "${BACKEND_REPORT_FILE:-}" ]]; then
      grep -q 'PI-EXACTLY-ONCE-EMPTY-OUTBOX' "$BACKEND_REPORT_FILE" || exit 1
      grep -q 'PI-PACK-AUDIO-OFFLINE' "$DEVICE_REPORT_FILE" || exit 1
    fi
    exit 0
    """

    File.write!(Path.join(bin, "xcodebuild"), device)
    File.write!(Path.join(bin, "mix"), mix)
    File.chmod!(Path.join(bin, "xcodebuild"), 0o755)
    File.chmod!(Path.join(bin, "mix"), 0o755)

    System.cmd("bash", [@script],
      cd: @root,
      env: [
        {"PATH", bin <> ":" <> System.get_env("PATH", "")},
        {"CROSSWAKE_PHYSICAL_IPHONE_CONTRACT_TEST_MODE", "1"},
        {"CROSSWAKE_PROOF_LANE_PHOENIX_PRODUCER", producer}
      ],
      stderr_to_stdout: true
    )
  end
end
