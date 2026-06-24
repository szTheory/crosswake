defmodule Crosswake.Guides.CaptureCollateralTest do
  use ExUnit.Case, async: true
  import Bitwise

  # Guards the collateral capture harness bin/capture-collateral.sh against drift:
  # strict-mode header, the --web-only flag, the seven collateral filenames, the
  # Playwright→collateral rename mapping, and the native commands being PRINTED
  # (human-gated, D-03) rather than executed. Plus a `bash -n` syntax gate.
  # UAT 5 (static + syntax) — fully automated.

  @script_path "bin/capture-collateral.sh"

  # The seven collateral assets the harness produces or documents.
  @web_filenames ["web-home.png", "web-offline.png", "web-bridge-proof.png"]
  @native_filenames [
    "ios-simulator.png",
    "android-emulator.png",
    "three-runtime-montage.png",
    "see-it-run.gif"
  ]

  # Playwright artifact → collateral rename mapping (src, dst).
  @rename_mapping [
    {"library.png", "web-home.png"},
    {"offline-study-replayed.png", "web-offline.png"},
    {"bridge-proof.png", "web-bridge-proof.png"}
  ]

  # Native capture commands — must be PRINTED (printf/echo), never executed.
  @native_commands [
    "xcrun simctl io booted screenshot",
    "adb exec-out screencap -p",
    "convert +append",
    "gifsicle"
  ]

  @min_emulator_evidence 3

  # ---------------------------------------------------------------------------
  # Readability
  # ---------------------------------------------------------------------------

  test "harness script exists and is executable" do
    assert File.exists?(@script_path), "expected #{@script_path} to exist"
    stat = File.stat!(@script_path)
    assert (stat.mode &&& 0o111) != 0, "expected #{@script_path} to be executable"
  end

  # ---------------------------------------------------------------------------
  # Syntax gate — bash -n parses without error (hermetic; bash is always present)
  # ---------------------------------------------------------------------------

  test "harness script passes bash -n syntax check" do
    {output, status} = System.cmd("bash", ["-n", @script_path], stderr_to_stdout: true)
    assert status == 0, "bash -n #{@script_path} failed (exit #{status}):\n#{output}"
    assert output == "", "expected no bash -n output, got:\n#{output}"
  end

  # ---------------------------------------------------------------------------
  # Main drift guard — [] means the harness is in sync with the contract
  # ---------------------------------------------------------------------------

  test "harness contains the collateral contract facts" do
    assert_no_drift_failures(scan_script({@script_path, File.read!(@script_path)}))
  end

  # ---------------------------------------------------------------------------
  # Anti-vacuity cases — each synthetic mutation MUST trigger a category
  # ---------------------------------------------------------------------------

  test "scanner rejects missing strict mode" do
    mutated = String.replace(File.read!(@script_path), "set -euo pipefail", "set -e")

    assert_failure_category(
      scan_script({"synthetic/no_strict.sh", mutated}),
      :missing_strict_mode
    )
  end

  test "scanner rejects a missing --web-only flag" do
    mutated = String.replace(File.read!(@script_path), "--web-only", "--web-maybe")

    assert_failure_category(
      scan_script({"synthetic/no_web_only.sh", mutated}),
      :missing_web_only_flag
    )
  end

  test "scanner rejects a missing collateral filename" do
    mutated = String.replace(File.read!(@script_path), "three-runtime-montage.png", "montage.png")

    assert_failure_category(
      scan_script({"synthetic/missing_filename.sh", mutated}),
      :missing_filename
    )
  end

  test "scanner rejects a broken rename mapping" do
    mutated = String.replace(File.read!(@script_path), "library.png", "home.png")

    assert_failure_category(
      scan_script({"synthetic/broken_mapping.sh", mutated}),
      :missing_rename_mapping
    )
  end

  test "scanner rejects an executed (un-printed) native command" do
    # Strip the printf wrapper off the xcrun line so it reads as a bare command.
    mutated =
      String.replace(
        File.read!(@script_path),
        ~s(printf "    xcrun simctl io booted screenshot),
        "xcrun simctl io booted screenshot"
      )

    assert_failure_category(
      scan_script({"synthetic/executed_native.sh", mutated}),
      :native_executed
    )
  end

  test "scanner rejects a missing emulator-evidence label" do
    mutated = String.replace(File.read!(@script_path), "emulator evidence", "native shot")

    assert_failure_category(
      scan_script({"synthetic/no_label.sh", mutated}),
      :missing_native_label
    )
  end

  # ---------------------------------------------------------------------------
  # Script scanner — returns a flat list of failures (empty = green)
  # ---------------------------------------------------------------------------

  defp scan_script({path, contents}) do
    [
      require_contains(path, contents, "set -euo pipefail", :missing_strict_mode,
        "harness must run under strict mode (set -euo pipefail)"),
      require_contains(path, contents, "--web-only", :missing_web_only_flag,
        "harness must support the --web-only headless flag"),
      filename_failures(path, contents),
      rename_mapping_failures(path, contents),
      native_command_failures(path, contents),
      native_printed_failures(path, contents),
      emulator_evidence_failure(path, contents)
    ]
    |> List.flatten()
  end

  defp filename_failures(path, contents) do
    Enum.flat_map(@web_filenames ++ @native_filenames, fn name ->
      require_contains(path, contents, name, :missing_filename,
        "harness must reference the collateral file #{name}")
    end)
  end

  defp rename_mapping_failures(path, contents) do
    Enum.flat_map(@rename_mapping, fn {src, dst} ->
      regex = ~r/#{Regex.escape(src)}.*#{Regex.escape(dst)}/

      require_regex(path, contents, regex, :missing_rename_mapping,
        "harness must rename Playwright artifact #{src} → collateral #{dst}")
    end)
  end

  defp native_command_failures(path, contents) do
    Enum.flat_map(@native_commands, fn cmd ->
      require_contains(path, contents, cmd, :missing_native_command,
        "harness must print the native capture command #{inspect(cmd)}")
    end)
  end

  # Every line carrying a native command literal must be a print line (printf /
  # echo) or a comment — never a bare execution. Catches accidental automation
  # of the human-gated native capture (D-03).
  defp native_printed_failures(path, contents) do
    contents
    |> lines()
    |> Enum.flat_map(fn {line, line_number} ->
      trimmed = String.trim_leading(line)

      if Enum.any?(@native_commands, &String.contains?(line, &1)) and not printed?(trimmed) do
        [
          failure(path, :native_executed,
            line: line_number,
            claim: String.trim(line),
            detail: "native command must be printed (printf/echo), not executed"
          )
        ]
      else
        []
      end
    end)
  end

  defp printed?(trimmed) do
    String.starts_with?(trimmed, "printf") or
      String.starts_with?(trimmed, "echo") or
      String.starts_with?(trimmed, "#")
  end

  defp emulator_evidence_failure(path, contents) do
    count =
      ~r/emulator evidence/
      |> Regex.scan(contents)
      |> length()

    if count >= @min_emulator_evidence do
      []
    else
      [
        failure(path, :missing_native_label,
          claim: "#{count} occurrences",
          detail:
            "harness must label native shots 'emulator evidence' at least #{@min_emulator_evidence} times"
        )
      ]
    end
  end

  # ---------------------------------------------------------------------------
  # Per-file helpers (copied per file — house idiom, not extracted to a module)
  # ---------------------------------------------------------------------------

  import Bitwise

  defp require_contains(path, contents, needle, category, detail) do
    if String.contains?(contents, needle), do: [], else: [failure(path, category, detail: detail)]
  end

  defp require_regex(path, contents, regex, category, detail) do
    if Regex.match?(regex, contents), do: [], else: [failure(path, category, detail: detail)]
  end

  defp failure(path, category, opts) do
    %{
      path: path,
      line: Keyword.get(opts, :line),
      category: category,
      claim: Keyword.get(opts, :claim),
      detail: Keyword.fetch!(opts, :detail)
    }
  end

  defp format_failures(failures) do
    Enum.map_join(failures, "\n", fn failure ->
      location = if failure.line, do: "#{failure.path}:#{failure.line}", else: failure.path
      claim = (failure.claim || "") |> to_string() |> String.trim()
      claim_suffix = if claim == "", do: "", else: " -- #{claim}"
      "- #{location} [#{failure.category}] #{failure.detail}#{claim_suffix}"
    end)
  end

  defp assert_no_drift_failures(failures) do
    assert failures == [],
           "capture-collateral harness drift found:\n" <> format_failures(failures)
  end

  defp assert_failure_category(failures, category) do
    assert Enum.any?(failures, &(&1.category == category)),
           "expected #{inspect(category)} failure, got:\n" <> format_failures(failures)
  end

  defp lines(contents) do
    contents
    |> String.split("\n")
    |> Enum.with_index(1)
  end
end
