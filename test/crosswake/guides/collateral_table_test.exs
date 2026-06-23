defmodule Crosswake.Guides.CollateralTableTest do
  use ExUnit.Case, async: true

  # Guards the collateral asset table in brandbook/collateral/see-it-run/README.md
  # against honest-label drift: all seven assets listed, web rows labelled
  # "Web proof", native/montage rows labelled "emulator evidence ... advisory,
  # not physical device", and the raw.githubusercontent.com reference pattern.
  # UAT 6 — fully automated. (Reads the repo file directly; brandbook is
  # Hex-excluded but tests run from the repo, consistent with the sibling guides.)

  @table_path "brandbook/collateral/see-it-run/README.md"

  @web_rows ["web-home.png", "web-offline.png", "web-bridge-proof.png"]
  @native_rows ["ios-simulator.png", "android-emulator.png", "three-runtime-montage.png"]
  @gif_row "see-it-run.gif"
  @all_files @web_rows ++ @native_rows ++ [@gif_row]

  @raw_url_prefix "raw.githubusercontent.com/szTheory/crosswake/main/brandbook/collateral/see-it-run/"

  # ---------------------------------------------------------------------------
  # Readability
  # ---------------------------------------------------------------------------

  test "collateral table file is readable" do
    assert File.exists?(@table_path), "expected #{@table_path} to exist"
  end

  # ---------------------------------------------------------------------------
  # Main drift guard — [] means the table is in sync with the honest-label contract
  # ---------------------------------------------------------------------------

  test "collateral table lists all seven assets with honest labels" do
    assert_no_drift_failures(scan_table({@table_path, File.read!(@table_path)}))
  end

  # ---------------------------------------------------------------------------
  # Anti-vacuity cases — each synthetic mutation MUST trigger a category
  # ---------------------------------------------------------------------------

  test "scanner rejects a missing asset row" do
    mutated = String.replace(File.read!(@table_path), "see-it-run.gif", "demo.gif")

    assert_failure_category(
      scan_table({"synthetic/missing_row.md", mutated}),
      :missing_filename
    )
  end

  test "scanner rejects a web row that drops the Web proof label" do
    mutated = String.replace(File.read!(@table_path), "Web proof — localhost:4700/ ", "screenshot ")

    assert_failure_category(
      scan_table({"synthetic/no_web_label.md", mutated}),
      :missing_web_label
    )
  end

  test "scanner rejects a native row that drops the advisory disclaimer" do
    mutated =
      String.replace(
        File.read!(@table_path),
        "emulator evidence — iOS Simulator (advisory, not physical device)",
        "iOS Simulator screenshot"
      )

    assert_failure_category(
      scan_table({"synthetic/no_native_label.md", mutated}),
      :missing_native_label
    )
  end

  test "scanner rejects a missing raw reference URL" do
    mutated = String.replace(File.read!(@table_path), @raw_url_prefix, "example.com/")

    assert_failure_category(
      scan_table({"synthetic/no_raw_url.md", mutated}),
      :missing_raw_url
    )
  end

  # ---------------------------------------------------------------------------
  # Table scanner — returns a flat list of failures (empty = green)
  # ---------------------------------------------------------------------------

  defp scan_table({path, contents}) do
    [
      filename_failures(path, contents),
      web_label_failures(path, contents),
      native_label_failures(path, contents),
      raw_url_failure(path, contents)
    ]
    |> List.flatten()
  end

  defp filename_failures(path, contents) do
    Enum.flat_map(@all_files, fn name ->
      require_contains(path, contents, name, :missing_filename,
        "table must list the collateral asset #{name}")
    end)
  end

  defp web_label_failures(path, contents) do
    Enum.flat_map(@web_rows, fn name ->
      row_label_failure(path, contents, name, "Web proof", :missing_web_label,
        "web row #{name} must carry the 'Web proof' label")
    end)
  end

  defp native_label_failures(path, contents) do
    Enum.flat_map(@native_rows, fn name ->
      [
        row_label_failure(path, contents, name, "emulator evidence", :missing_native_label,
          "native row #{name} must carry the 'emulator evidence' label"),
        row_label_failure(path, contents, name, "advisory, not physical device", :missing_native_label,
          "native row #{name} must carry the 'advisory, not physical device' disclaimer")
      ]
    end)
  end

  # Finds the table row containing `name` and asserts it also contains `label`.
  # A missing row is reported by filename_failures, so we skip it here to avoid
  # double-counting an absence as a label drift.
  defp row_label_failure(path, contents, name, label, category, detail) do
    case row_for(contents, name) do
      nil -> []
      row -> require_contains(path, row, label, category, detail)
    end
  end

  defp row_for(contents, name) do
    contents
    |> String.split("\n")
    |> Enum.find(&String.contains?(&1, name))
  end

  defp raw_url_failure(path, contents) do
    require_contains(path, contents, @raw_url_prefix, :missing_raw_url,
      "table must document the raw.githubusercontent.com reference pattern")
  end

  # ---------------------------------------------------------------------------
  # Per-file helpers (copied per file — house idiom, not extracted to a module)
  # ---------------------------------------------------------------------------

  defp require_contains(path, contents, needle, category, detail) do
    if String.contains?(contents, needle), do: [], else: [failure(path, category, detail: detail)]
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
           "collateral table drift found:\n" <> format_failures(failures)
  end

  defp assert_failure_category(failures, category) do
    assert Enum.any?(failures, &(&1.category == category)),
           "expected #{inspect(category)} failure, got:\n" <> format_failures(failures)
  end
end
