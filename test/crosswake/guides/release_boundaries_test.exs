defmodule Crosswake.Guides.ReleaseBoundariesTest do
  use ExUnit.Case, async: true

  @public_release_truth_docs [
    "README.md",
    "CHANGELOG.md",
    "examples/QUICK_START.md",
    "examples/phoenix_host/README.md",
    "guides/adoption.md",
    "guides/install.md",
    "guides/native_shell.md",
    "guides/compatibility.md",
    "guides/support_matrix.md"
  ]

  @manifest_paths [
    "examples/phoenix_host/priv/crosswake/install_manifest.json",
    "examples/ios_shell_host/Fixtures/crosswake_manifest.json",
    "examples/android_shell_host/app/src/main/assets/crosswake_manifest.json"
  ]

  test "guide surfaces publish the four change classes and rebuild-first wording" do
    install = File.read!("guides/install.md")
    native_shell = File.read!("guides/native_shell.md")
    compatibility = File.read!("guides/compatibility.md")
    example_host = File.read!("examples/phoenix_host/README.md")

    assert install =~ "Do I need to rebuild?"
    assert install =~ "docs-only"
    assert install =~ "core-only/no native rebuild"
    assert install =~ "compatibility-bump only"
    assert install =~ "native or companion rebuild required"
    assert install =~ "docs integrity only"
    assert install =~ "core contract + doctor/support proof"
    assert install =~ "fail-closed compatibility fixtures"
    assert install =~ "generated-shell or companion verification lanes"

    assert native_shell =~ "native or companion rebuild required"
    assert compatibility =~ "Change class `docs-only`"
    assert compatibility =~ "Change class `core-only/no native rebuild`"
    assert compatibility =~ "Change class `compatibility-bump only`"
    assert compatibility =~ "Change class `native or companion rebuild required`"

    assert example_host =~ "reclassification plus proof and support-matrix updates"
    assert example_host =~ "supported example"
    assert example_host =~ "not a separate supported runtime package"
  end

  test "guide surfaces link rebuild guidance to canonical promotion and non-claim truth" do
    guide_paths = [
      "guides/install.md",
      "guides/native_shell.md",
      "guides/compatibility.md"
    ]

    for path <- guide_paths do
      guide = File.read!(path)

      assert guide =~ "Do I need to rebuild?"
      assert guide =~ "Promotion rules"
      assert guide =~ "guides/support_matrix.md#action-classes"
      assert guide =~ "guides/support_matrix.md#promotion-rules"
      assert guide =~ "StoreKit/Play Billing seams in v3.7 emit reconciliation evidence only"
      assert guide =~ "Sigra session-authority route evaluation"
      assert guide =~ "Phase 55 handoff ticket/server-record contracts"
      assert guide =~ "Phase 56 step-up intent plus Plug/LiveView ceremony"
      assert guide =~ "Phase 57 OAuth/passkey/native auth-return boundary contracts"
      assert guide =~ "Phase 58 telemetry/security closeout are shipped"
      assert guide =~ "refresh-token helpers"
      assert guide =~ "native auth UI are deferred"
      assert guide =~ "notification-token readiness is provider-snapshot only"

      assert guide =~
               "standalone native shell core packages are published through SwiftPM and Maven Central at the Crosswake package version"

      assert guide =~ "compatibility-window narrowing is distinct from a native rebuild"
    end
  end

  test "public start surfaces expose route-owner guides and support-truth labels" do
    readme = File.read!("README.md")
    install = File.read!("guides/install.md")
    user_flows = File.read!("guides/user_flows.md")
    docs = Crosswake.MixProject.project()[:docs]
    extras = docs[:extras]
    groups = docs[:groups_for_extras]

    assert_contains_sentence(
      readme,
      "Crosswake's one job is to declare, enforce, and diagnose which runtime owns each route as a Phoenix app crosses into mobile."
    )

    # Anchor the "support-truth comes after route-owner guides" ordering to the
    # plain nav links (support_matrix.md)) so it skips the See-it-run advisory
    # legend deep-link (support_matrix.md#support-truth-label-legend) that the
    # v15.0 "See It Run" section legitimately introduces earlier in the README.
    assert_order(readme, "guides/route_policy.md", "guides/support_matrix.md)")
    assert_order(readme, "guides/web_to_mobile_migration.md", "guides/support_matrix.md)")

    assert readme =~ "guides/support_matrix.md#support-truth-label-legend"
    assert readme =~ "merge-blocking proof"
    assert readme =~ "advisory evidence"
    assert readme =~ "checked-in public-coordinate proof"
    assert readme =~ "local-dev proof"
    assert readme =~ "generated public-coordinate proof"
    assert readme =~ "verification-required"
    assert readme =~ "rebuild-required"

    for guide <- [install, user_flows] do
      assert guide =~ "guides/route_policy.md"
      assert guide =~ "guides/web_to_mobile_migration.md"
    end

    assert docs[:main] == "readme"
    assert "guides/route_policy.md" in extras
    assert "guides/web_to_mobile_migration.md" in extras

    for path <- extras do
      assert File.exists?(path), "ExDoc extra #{path} must exist"
    end

    assert Keyword.keys(groups) == [:Start, :Adopt, :"Runtime Owners", :Truth, :Telemetry, :"Extension Authors", :"Advanced/Companions"]
    assert "guides/route_policy.md" in groups[:Start]
    assert "guides/web_to_mobile_migration.md" in groups[:Adopt]
    assert "guides/support_matrix.md" in groups[:Truth]
  end

  test "public release truth docs and manifests reject stale current-proof claims" do
    current_version = current_version()

    failures =
      scan_public_docs(public_release_truth_docs(), current_version) ++
        scan_manifests(public_manifests(), current_version)

    assert_no_release_truth_failures(failures)
  end

  test "release-truth scanner flags synthetic stale public-doc claims" do
    current_version = current_version()
    old_version = stale_package_versions(current_version) |> List.first()

    failures =
      scan_public_docs(
        [
          {"synthetic/latest_hex.md",
           "The latest Hex release remains `#{old_version}` until native evidence is finished."},
          {"synthetic/current_pending.md",
           "Crosswake `#{current_version}` remains pending and unreleased."},
          {"synthetic/old_baseline.md", "Current baseline: Crosswake version `#{old_version}`."},
          {"synthetic/standalone_shell.md",
           "Standalone public shell packages are deferred until a later milestone."}
        ],
        current_version
      )

    assert_failure(failures, :stale_latest_hex, "synthetic/latest_hex.md")
    assert_failure(failures, :current_version_pending, "synthetic/current_pending.md")
    assert_failure(failures, :old_current_baseline, "synthetic/old_baseline.md")
    assert_failure(failures, :standalone_shell_deferred, "synthetic/standalone_shell.md")
  end

  test "release-truth scanner flags synthetic stale manifest claims" do
    current_version = current_version()
    old_version = stale_package_versions(current_version) |> List.first()

    failures =
      scan_manifest(
        {"synthetic/manifest.json",
         %{
           "crosswake_version" => old_version,
           "support_matrix" => %{
             "package_surfaces" => [
               %{
                 "surface" => "Standalone native shell core packages",
                 "release_burden" => "Standalone public shell packages are deferred."
               }
             ],
             "shells" => [
               %{
                 "target" => "ios_shell",
                 "version" => old_version
               }
             ]
           }
         }},
        current_version
      )

    assert_failure(
      failures,
      :manifest_crosswake_version,
      "synthetic/manifest.json",
      "$.crosswake_version"
    )

    assert_failure(
      failures,
      :manifest_standalone_shell_deferred,
      "synthetic/manifest.json",
      "$.support_matrix.package_surfaces[0].release_burden"
    )

    assert_failure(
      failures,
      :manifest_shell_old_version,
      "synthetic/manifest.json",
      "$.support_matrix.shells[0].version"
    )
  end

  defp current_version do
    Application.spec(:crosswake, :vsn) |> to_string()
  end

  defp public_release_truth_docs do
    Enum.map(@public_release_truth_docs, &{&1, File.read!(&1)})
  end

  defp public_manifests do
    Enum.map(@manifest_paths, &{&1, File.read!(&1) |> Jason.decode!()})
  end

  defp scan_public_docs(docs, current_version) do
    Enum.flat_map(docs, &scan_public_doc(&1, current_version))
  end

  defp scan_public_doc({path, contents}, current_version) do
    stale_versions = stale_package_versions(current_version)

    contents
    |> String.split("\n")
    |> Enum.with_index(1)
    |> Enum.flat_map(fn {line, line_number} ->
      scan_public_line(path, line, line_number, current_version, stale_versions)
    end)
  end

  defp scan_public_line(path, line, line_number, current_version, stale_versions) do
    line_context = historical_or_fixture_context?(path, line)

    version_failures =
      Enum.flat_map(stale_versions, fn stale_version ->
        cond do
          stale_latest_hex_claim?(line, stale_version) and not line_context ->
            [
              failure(path, :stale_latest_hex,
                line: line_number,
                claim: line,
                detail:
                  "old version #{stale_version} is presented as the latest/current Hex release"
              )
            ]

          old_current_baseline_claim?(line, stale_version) and not line_context ->
            [
              failure(path, :old_current_baseline,
                line: line_number,
                claim: line,
                detail: "old version #{stale_version} is presented as current baseline truth"
              )
            ]

          true ->
            []
        end
      end)

    current_failures =
      if current_version_pending_claim?(line, current_version) and not line_context do
        [
          failure(path, :current_version_pending,
            line: line_number,
            claim: line,
            detail: "current version #{current_version} is described as pending or unreleased"
          )
        ]
      else
        []
      end

    standalone_failures =
      if standalone_shell_deferred_claim?(line) and not line_context do
        [
          failure(path, :standalone_shell_deferred,
            line: line_number,
            claim: line,
            detail: "standalone shell package truth still uses deferred/unavailable wording"
          )
        ]
      else
        []
      end

    version_failures ++ current_failures ++ standalone_failures
  end

  defp scan_manifests(manifests, current_version) do
    Enum.flat_map(manifests, &scan_manifest(&1, current_version))
  end

  defp scan_manifest({path, manifest}, current_version) do
    stale_versions = stale_package_versions(current_version)
    top_level_version = Map.get(manifest, "crosswake_version")

    crosswake_version_failures =
      if top_level_version == current_version do
        []
      else
        [
          failure(path, :manifest_crosswake_version,
            field_path: "$.crosswake_version",
            detail: "expected #{inspect(current_version)}, got #{inspect(top_level_version)}"
          )
        ]
      end

    package_surface_failures =
      manifest
      |> get_in(["support_matrix", "package_surfaces"])
      |> List.wrap()
      |> Enum.with_index()
      |> Enum.flat_map(fn {surface, index} ->
        scan_manifest_package_surface(path, surface, index)
      end)

    shell_failures =
      manifest
      |> get_in(["support_matrix", "shells"])
      |> List.wrap()
      |> Enum.with_index()
      |> Enum.flat_map(fn {shell, index} ->
        scan_manifest_shell(path, shell, index, stale_versions)
      end)

    crosswake_version_failures ++ package_surface_failures ++ shell_failures
  end

  defp scan_manifest_package_surface(path, surface, index) when is_map(surface) do
    surface
    |> string_fields()
    |> Enum.flat_map(fn {field, value} ->
      if standalone_shell_deferred_claim?(value) and not manifest_fixture_context?(surface, value) do
        [
          failure(path, :manifest_standalone_shell_deferred,
            field_path: "$.support_matrix.package_surfaces[#{index}].#{field}",
            claim: value,
            detail:
              "embedded support-matrix package surface still defers standalone shell packages"
          )
        ]
      else
        []
      end
    end)
  end

  defp scan_manifest_package_surface(_path, _surface, _index), do: []

  defp scan_manifest_shell(path, shell, index, stale_versions) when is_map(shell) do
    version = Map.get(shell, "version")

    if is_binary(version) and shell_version_stale?(shell, version, stale_versions) do
      [
        failure(path, :manifest_shell_old_version,
          field_path: "$.support_matrix.shells[#{index}].version",
          claim: version,
          detail: "embedded shell artifact version still reports old package truth"
        )
      ]
    else
      []
    end
  end

  defp scan_manifest_shell(_path, _shell, _index, _stale_versions), do: []

  defp stale_package_versions(current_version) do
    "CHANGELOG.md"
    |> File.read!()
    |> then(&Regex.scan(~r/^## \[(\d+\.\d+\.\d+)\]/m, &1))
    |> Enum.map(fn [_match, version] -> version end)
    |> Enum.reject(&(&1 == current_version))
    |> case do
      [] -> ["0.1.0"]
      versions -> versions
    end
  end

  defp stale_latest_hex_claim?(line, stale_version) do
    version = version_ref(stale_version)

    Regex.match?(
      ~r/(?:latest|current)\s+(?:published\s+)?(?:hex\s+)?(?:package|release)?[^.\n;:]*#{version}/i,
      line
    ) or
      Regex.match?(
        ~r/#{version}[^.\n;:]*\b(?:latest|current)\b[^.\n;:]*\bhex\b/i,
        line
      )
  end

  defp current_version_pending_claim?(line, current_version) do
    version = version_ref(current_version)

    Regex.match?(
      ~r/#{version}\s+(?:release\s+)?(?:is|remains|stays|still|currently)?\s*(?:pending|unreleased|not\s+(?:yet\s+)?published|not\s+cut)/i,
      line
    ) or
      Regex.match?(
        ~r/(?:pending|unreleased|not\s+(?:yet\s+)?published|not\s+cut)\s+(?:release\s+)?#{version}/i,
        line
      )
  end

  defp old_current_baseline_claim?(line, stale_version) do
    version = version_ref(stale_version)

    Regex.match?(
      ~r/(?:current\s+baseline|current\s+package|current\s+release|crosswake\s+version|package\s+version)[^.\n;:]{0,80}#{version}/i,
      line
    ) or
      Regex.match?(
        ~r/#{version}[^.\n;:]{0,80}(?:current\s+baseline|current\s+package|current\s+release)/i,
        line
      )
  end

  defp standalone_shell_deferred_claim?(line) do
    Regex.match?(
      ~r/standalone\s+(?:public\s+)?(?:native\s+)?shell(?:\s+core)?\s+packages?[^.\n;:]{0,120}(?:deferred|unavailable|not\s+(?:yet\s+)?published|remain(?:s)?\s+unavailable)/i,
      line
    )
  end

  defp shell_version_stale?(shell, version, stale_versions) do
    Enum.any?(stale_versions, &String.contains?(version, &1)) and
      not manifest_fixture_context?(shell, version)
  end

  defp manifest_fixture_context?(map, value) do
    [value | Enum.map(string_fields(map), fn {_field, text} -> text end)]
    |> Enum.any?(&historical_or_fixture_text?/1)
  end

  defp historical_or_fixture_context?(path, line) do
    historical_or_fixture_text?(line) or
      (path == "CHANGELOG.md" and historical_changelog_line?(line))
  end

  defp historical_or_fixture_text?(text) do
    text
    |> String.downcase()
    |> then(fn normalized ->
      String.contains?(normalized, "historical") or
        String.contains?(normalized, "fixture") or
        String.contains?(normalized, "archived")
    end)
  end

  defp historical_changelog_line?(line) do
    trimmed = String.trim(line)

    Regex.match?(~r/^## \[\d+\.\d+\.\d+\]/, trimmed) or
      Regex.match?(~r/^\[\d+\.\d+\.\d+\]:\s+https?:\/\//, trimmed)
  end

  defp string_fields(map) when is_map(map) do
    map
    |> Enum.filter(fn {_field, value} -> is_binary(value) end)
    |> Enum.map(fn {field, value} -> {field, value} end)
  end

  defp version_ref(version) do
    "`?#{Regex.escape(version)}`?"
  end

  defp failure(path, category, opts) do
    %{
      path: path,
      category: category,
      field_path: Keyword.get(opts, :field_path),
      line: Keyword.get(opts, :line),
      claim: Keyword.get(opts, :claim),
      detail: Keyword.fetch!(opts, :detail)
    }
  end

  defp assert_no_release_truth_failures(failures) do
    assert failures == [],
           "stale release-truth claims found:\n" <> format_release_truth_failures(failures)
  end

  defp assert_failure(failures, category, path, field_path \\ nil) do
    assert Enum.any?(failures, fn failure ->
             failure.category == category and failure.path == path and
               (is_nil(field_path) or failure.field_path == field_path)
           end),
           "expected #{inspect(category)} for #{path}#{format_field_path(field_path)}, got:\n" <>
             format_release_truth_failures(failures)
  end

  defp format_release_truth_failures(failures) do
    failures
    |> Enum.map_join("\n", fn failure ->
      location =
        cond do
          failure.field_path -> "#{failure.path} #{failure.field_path}"
          failure.line -> "#{failure.path}:#{failure.line}"
          true -> failure.path
        end

      claim =
        failure.claim
        |> to_string()
        |> String.trim()

      claim_suffix =
        if claim == "" do
          ""
        else
          " -- #{claim}"
        end

      "- #{location} [#{failure.category}] #{failure.detail}#{claim_suffix}"
    end)
  end

  defp format_field_path(nil), do: ""
  defp format_field_path(field_path), do: " #{field_path}"

  # The four verbatim change-class strings that must be used in ### Upgrade Impact blocks.
  # Shared by both the vocabulary test and the legend-parity test so a rename breaks both.
  @upgrade_impact_change_classes [
    "docs-only",
    "core-only/no native rebuild",
    "compatibility-bump only",
    "native or companion rebuild required"
  ]

  test "upgrade impact — structural: every versioned release has exactly one block" do
    changelog = File.read!("CHANGELOG.md")
    lines = String.split(changelog, "\n")

    # Use historical_changelog_line?/1 to identify ## [x.y.z] heading lines (versioned releases).
    # ## [Unreleased] and prose headings do not match, so they are not checked.
    versioned_release_lines =
      Enum.filter(lines, fn line ->
        trimmed = String.trim(line)
        Regex.match?(~r/^## \[\d+\.\d+\.\d+\]/, trimmed) and historical_changelog_line?(trimmed)
      end)

    assert versioned_release_lines != [],
           "CHANGELOG.md must contain at least one ## [x.y.z] release heading"

    # For each versioned release, collect the lines in that release section and assert
    # exactly one ### Upgrade Impact block is present.
    release_sections = split_changelog_into_release_sections(lines)

    for {heading, section_lines} <- release_sections do
      impact_count =
        Enum.count(section_lines, fn line ->
          String.trim(line) == "### Upgrade Impact"
        end)

      assert impact_count == 1,
             "Release #{inspect(heading)} must have exactly one ### Upgrade Impact subsection; " <>
               "found #{impact_count}"
    end
  end

  test "upgrade impact — vocabulary/legend parity: labels use the locked 4-string set and exist in support_matrix.md" do
    changelog = File.read!("CHANGELOG.md")
    support_matrix = File.read!("guides/support_matrix.md")

    # Collect all ### Upgrade Impact label lines from CHANGELOG.md.
    # A label is the bold line immediately following "### Upgrade Impact"
    # (matching **some string** on its own line or a plain string).
    impact_labels = extract_upgrade_impact_labels(changelog)

    # Every label must be one of the 4 verbatim change-class strings.
    for label <- impact_labels do
      assert label in @upgrade_impact_change_classes,
             "### Upgrade Impact label #{inspect(label)} is not in the locked 4-string vocabulary. " <>
               "Use one of: #{inspect(@upgrade_impact_change_classes)}"
    end

    # Each of the 4 change-class strings must still exist verbatim in the support_matrix.md
    # Change Classes table — legend parity so a rename breaks guide + changelog tests together.
    for class_string <- @upgrade_impact_change_classes do
      assert String.contains?(support_matrix, class_string),
             "Change class #{inspect(class_string)} must still exist verbatim in " <>
               "guides/support_matrix.md Change Classes table (legend parity)"
    end
  end

  # Splits CHANGELOG.md lines into a list of {heading, section_lines} pairs,
  # one per ## [x.y.z] release section (excluding ## [Unreleased] and prose headings).
  # Uses historical_changelog_line?/1 to identify versioned release heading lines.
  defp split_changelog_into_release_sections(lines) do
    {sections, current_heading, current_lines} =
      Enum.reduce(lines, {[], nil, []}, fn line, {sections, heading, acc_lines} ->
        trimmed = String.trim(line)

        if historical_changelog_line?(trimmed) and Regex.match?(~r/^## \[\d+\.\d+\.\d+\]/, trimmed) do
          completed = if heading, do: [{heading, Enum.reverse(acc_lines)}], else: []
          {sections ++ completed, line, []}
        else
          {sections, heading, [line | acc_lines]}
        end
      end)

    # Flush the last section
    last = if current_heading, do: [{current_heading, Enum.reverse(current_lines)}], else: []
    sections ++ last
  end

  # Extracts the upgrade-impact label strings from CHANGELOG.md by scanning for
  # ### Upgrade Impact headings and collecting the bold label on the following non-blank line.
  defp extract_upgrade_impact_labels(changelog) do
    lines = String.split(changelog, "\n")

    {labels, _} =
      Enum.reduce(lines, {[], false}, fn line, {labels, capture_next} ->
        trimmed = String.trim(line)

        cond do
          trimmed == "### Upgrade Impact" ->
            {labels, true}

          capture_next and trimmed == "" ->
            {labels, true}

          capture_next ->
            # Strip bold markers if present: **label** -> label
            label = Regex.replace(~r/^\*\*(.+)\*\*$/, trimmed, "\\1")
            {[label | labels], false}

          true ->
            {labels, false}
        end
      end)

    Enum.reverse(labels)
  end

  defp assert_order(contents, earlier, later) do
    assert String.contains?(contents, earlier), "expected #{inspect(earlier)} in contents"
    assert String.contains?(contents, later), "expected #{inspect(later)} in contents"

    assert :binary.match(contents, earlier) < :binary.match(contents, later),
           "expected #{inspect(earlier)} to appear before #{inspect(later)}"
  end

  defp assert_contains_sentence(contents, sentence) do
    assert normalize_whitespace(contents) =~ normalize_whitespace(sentence)
  end

  defp normalize_whitespace(contents) do
    Regex.replace(~r/\s+/, contents, " ")
  end
end
