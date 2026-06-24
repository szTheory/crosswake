defmodule Crosswake.Guides.TroubleshootingTest do
  use ExUnit.Case, async: true

  @guide_path "guides/troubleshooting.md"
  @support_matrix_path "guides/support_matrix.md"
  @doctor_truth_path "test/crosswake/doctor/doctor_test.exs"

  @owner_sections [
    "## Phoenix/LiveView Owner",
    "## Bounded Bridge Owner",
    "## Cached Read-Only Owner",
    "## Offline Island Owner",
    "## Native Screen Owner",
    "## Backend/Provider Seam Owner"
  ]

  @required_entries [
    "external_entry_denied",
    "compatibility_mismatch",
    "undeclared_capability",
    "unavailable_capability",
    "pack_incompatible",
    "route_unavailable",
    "native evidence label confusion",
    "rejected offline replay",
    "conflict replay outcome",
    "gate_denied",
    "step_up_required"
  ]

  @required_labels [
    "**What you see:**",
    "**Who owns the fix:**",
    "**Run this:**",
    "**Change this route policy, host setup, or proof command:**",
    "**Proof label:**",
    "**What this does not prove:**"
  ]

  @support_labels [
    "merge-blocking proof",
    "advisory evidence",
    "checked-in public-coordinate proof",
    "generated public-coordinate proof",
    "local-dev proof",
    "emulator evidence",
    "device evidence",
    "verification-required",
    "rebuild-required"
  ]

  test "source-derived facts used by the troubleshooting scanner are readable" do
    assert File.exists?(@guide_path)

    doctor_truth = File.read!(@doctor_truth_path)

    for finding <-
          @required_entries --
            [
              "native evidence label confusion",
              "rejected offline replay",
              "conflict replay outcome"
            ] do
      assert doctor_truth =~ finding or finding == "route_unavailable"
    end

    support_matrix = File.read!(@support_matrix_path)

    for label <- @support_labels do
      assert support_matrix =~ label
    end
  end

  test "troubleshooting guide covers required findings, owners, commands, labels, and limits" do
    guide = File.read!(@guide_path)

    assert_no_drift_failures(scan_troubleshooting({@guide_path, guide}))
  end

  test "synthetic regressions fail when required entry structure is missing" do
    guide = File.read!(@guide_path)

    assert_failure_category(
      scan_troubleshooting(
        {"synthetic/troubleshooting_missing_owner.md",
         String.replace(guide, "**Who owns the fix:**", "**Fix owner:**", global: false)}
      ),
      :missing_entry_label
    )

    assert_failure_category(
      scan_troubleshooting(
        {"synthetic/troubleshooting_missing_run_this.md",
         String.replace(guide, "**Run this:**", "**Command:**", global: false)}
      ),
      :missing_entry_label
    )

    assert_failure_category(
      scan_troubleshooting(
        {"synthetic/troubleshooting_missing_limitation.md",
         String.replace(
           guide,
           "**What this does not prove:**",
           "**Boundary:**",
           global: false
         )}
      ),
      :missing_entry_label
    )
  end

  test "synthetic regressions fail when proof labels, links, or required outcomes are missing" do
    guide = File.read!(@guide_path)

    assert_failure_category(
      scan_troubleshooting(
        {"synthetic/troubleshooting_missing_proof_label.md",
         String.replace(guide, "merge-blocking proof", "required proof", global: false)}
      ),
      :missing_proof_label
    )

    assert_failure_category(
      scan_troubleshooting(
        {"synthetic/troubleshooting_missing_truth_link.md",
         guide
         |> String.replace(
           "[support_matrix.md](support_matrix.md#support-truth-label-legend)",
           "support truth"
         )
         |> String.replace("`test/crosswake/doctor/doctor_test.exs`", "doctor truth")}
      ),
      :missing_truth_link
    )

    assert_failure_category(
      scan_troubleshooting(
        {"synthetic/troubleshooting_missing_route_unavailable.md",
         String.replace(guide, "route_unavailable", "route_missing")}
      ),
      :missing_required_entry
    )

    assert_failure_category(
      scan_troubleshooting(
        {"synthetic/troubleshooting_missing_rejected.md",
         String.replace(guide, "rejected offline replay", "invalid offline replay")}
      ),
      :missing_required_entry
    )

    assert_failure_category(
      scan_troubleshooting(
        {"synthetic/troubleshooting_missing_conflict.md",
         String.replace(guide, "conflict replay outcome", "server disagreement outcome")}
      ),
      :missing_required_entry
    )
  end

  test "synthetic regressions fail on native advisory evidence overclaims" do
    overclaiming =
      """
      # Crosswake Troubleshooting

      ## Symptom And Finding Index

      | native evidence label confusion | support-truth labels | mix test |

      ## Native Screen Owner

      ### native evidence label confusion

      **What you see:** emulator evidence is merge-blocking native support.
      **Who owns the fix:** docs owner.
      **Run this:** `mix test test/crosswake/guides/native_evidence_drift_test.exs`
      **Change this route policy, host setup, or proof command:** use support labels.
      **Proof label:** advisory evidence.
      **What this does not prove:** none.
      """

    assert_failure_category(
      scan_troubleshooting({"synthetic/native_overclaim.md", overclaiming}),
      :native_evidence_overclaim
    )
  end

  defp scan_troubleshooting({path, contents}) do
    required_structure_failures(path, contents) ++
      required_entry_failures(path, contents) ++
      truth_link_failures(path, contents) ++
      offline_boundary_failures(path, contents) ++
      native_evidence_overclaim_failures(path, contents)
  end

  defp required_structure_failures(path, contents) do
    []
    |> require_contains(
      path,
      contents,
      "## Symptom And Finding Index",
      :missing_index,
      "start with a symptom/finding index"
    )
    |> require_all_contains(
      path,
      contents,
      @owner_sections,
      :missing_owner_section,
      "document each route owner section"
    )
  end

  defp required_entry_failures(path, contents) do
    Enum.flat_map(@required_entries, fn entry ->
      case entry_block(contents, entry) do
        nil ->
          [
            failure(path, :missing_required_entry,
              detail: "missing troubleshooting entry for #{entry}"
            )
          ]

        block ->
          entry_label_failures(path, entry, block) ++
            proof_label_failures(path, entry, block) ++
            command_failures(path, entry, block)
      end
    end)
  end

  defp entry_label_failures(path, entry, block) do
    Enum.flat_map(@required_labels, fn label ->
      if String.contains?(block, label) do
        []
      else
        [
          failure(path, :missing_entry_label, detail: "entry #{entry} missing #{label}")
        ]
      end
    end)
  end

  defp proof_label_failures(path, entry, block) do
    if Enum.any?(@support_labels, &String.contains?(block, &1)) do
      []
    else
      [
        failure(path, :missing_proof_label,
          detail: "entry #{entry} missing literal support-truth proof label"
        )
      ]
    end
  end

  defp command_failures(path, entry, block) do
    if Regex.match?(~r/(mix crosswake\.doctor|mix test|npx playwright|bash script\/)/, block) do
      []
    else
      [failure(path, :missing_command, detail: "entry #{entry} missing recovery command")]
    end
  end

  defp truth_link_failures(path, contents) do
    failures = []

    failures =
      if String.contains?(contents, "support_matrix.md") do
        failures
      else
        [failure(path, :missing_truth_link, detail: "link support matrix truth") | failures]
      end

    if String.contains?(contents, @doctor_truth_path) do
      failures
    else
      [failure(path, :missing_truth_link, detail: "link doctor truth source") | failures]
    end
  end

  defp offline_boundary_failures(path, contents) do
    [
      {"rejected", "document rejected replay outcomes"},
      {"conflict", "document conflict replay outcomes"},
      {"background sync", "state that offline proof is not broad background sync"},
      {"bridge mutation authority", "state that bridge does not own offline mutation"}
    ]
    |> Enum.flat_map(fn {term, detail} ->
      if String.contains?(String.downcase(contents), term) do
        []
      else
        [failure(path, :missing_offline_boundary, detail: detail)]
      end
    end)
  end

  defp native_evidence_overclaim_failures(path, contents) do
    contents
    |> lines()
    |> Enum.flat_map(fn {line, line_number} ->
      if Regex.match?(
           ~r/\b(emulator evidence|simulator evidence|device evidence|advisory evidence)\b.*\b(merge-blocking native support|physical-device support|camera support|media-upload support|provider authority|app-store readiness)\b/i,
           line
         ) and
           not negated?(line) do
        [
          failure(path, :native_evidence_overclaim,
            line: line_number,
            detail: "native evidence line overclaims advisory/native support"
          )
        ]
      else
        []
      end
    end)
  end

  defp entry_block(contents, entry) do
    regex = ~r/### `?#{Regex.escape(entry)}`?[\s\S]*?(?=\n### |\n## |\z)/i

    case Regex.run(regex, contents) do
      [block] -> block
      _ -> nil
    end
  end

  defp require_contains(failures, path, contents, term, category, detail) do
    if String.contains?(contents, term) do
      failures
    else
      [failure(path, category, detail: "#{detail}: #{term}") | failures]
    end
  end

  defp require_all_contains(failures, path, contents, terms, category, detail) do
    Enum.reduce(terms, failures, fn term, acc ->
      require_contains(acc, path, contents, term, category, detail)
    end)
  end

  defp negated?(line) do
    lowered = String.downcase(line)

    String.contains?(lowered, " not ") or
      String.contains?(lowered, " does not ") or
      String.contains?(lowered, " cannot ") or
      String.contains?(lowered, " never ") or
      String.contains?(lowered, " unless ")
  end

  defp failure(path, category, opts) do
    %{
      path: path,
      line: Keyword.get(opts, :line),
      category: category,
      detail: Keyword.fetch!(opts, :detail)
    }
  end

  defp assert_failure_category(failures, category) do
    assert Enum.any?(failures, &(&1.category == category)),
           "expected #{inspect(category)} failure, got:\n" <> format_failures(failures)
  end

  defp assert_no_drift_failures([]), do: :ok

  defp assert_no_drift_failures(failures) do
    flunk("""
    Troubleshooting guide drift detected:

    #{format_failures(failures)}
    """)
  end

  defp format_failures(failures) do
    Enum.map_join(failures, "\n", fn failure ->
      location =
        if failure.line do
          "#{failure.path}:#{failure.line}"
        else
          failure.path
        end

      "- #{location} [#{failure.category}] #{failure.detail}"
    end)
  end

  defp lines(contents) do
    contents
    |> String.split("\n")
    |> Enum.with_index(1)
  end
end
