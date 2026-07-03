defmodule Crosswake.Guides.NativeEvidenceDriftTest do
  use ExUnit.Case, async: true

  @current_version Application.spec(:crosswake, :vsn) |> to_string()

  @scanned_paths [
    "README.md",
    "examples/QUICK_START.md",
    "guides/install.md",
    "guides/native_shell.md",
    "guides/compatibility.md",
    "guides/support_matrix.md",
    "guides/android_uat.md",
    "examples/ios_shell_host/README.md",
    "examples/android_shell_host/README.md",
    "examples/ios_shell_host/CrosswakeShell.xcodeproj/project.pbxproj",
    "examples/android_shell_host/app/build.gradle",
    "priv/templates/crosswake/shell/ios/README.md.eex",
    "priv/templates/crosswake/shell/android/README.md.eex",
    "lib/crosswake/support_matrix/renderer.ex",
    "lib/crosswake/support_matrix/support_matrix.ex",
    "script/capture-native-collateral.mjs",
    ".github/workflows/native-collateral-advisory.yml",
    "examples/native_evidence/evidence-manifest.example.json"
  ]

  test "source-derived facts used by the drift scanner are readable" do
    assert current_version() =~ ~r/^\d+\.\d+\.\d+$/
    assert Enum.all?(@scanned_paths, &File.exists?/1)
  end

  test "public native surfaces keep the checked-in coordinate and label truth in sync" do
    failures = scan_paths(@scanned_paths)

    assert_no_drift_failures(failures)
  end

  test "synthetic regressions fail on stale checked-in iOS local refs" do
    failures =
      scan_surface(
        "examples/ios_shell_host/CrosswakeShell.xcodeproj/project.pbxproj",
        """
        isa = XCLocalSwiftPackageReference;
        relativePath = "../../packages/crosswake-shell-core-ios";
        """
      )

    assert Enum.any?(failures, &(&1.category == :stale_ios_local_reference))
  end

  test "synthetic regressions fail on stale Android coordinates and dynamic versions" do
    current_build_gradle = File.read!("examples/android_shell_host/app/build.gradle")

    stale_gav_failures =
      scan_surface(
        "examples/android_shell_host/app/build.gradle",
        String.replace(
          current_build_gradle,
          "io.github.sztheory:crosswake-shell-core-android:0.2.0",
          "dev.crosswake:shell-core-android:0.1.0"
        )
      )

    assert Enum.any?(stale_gav_failures, &(&1.category == :stale_android_coordinate))

    dynamic_version_failures =
      scan_surface(
        "examples/android_shell_host/app/build.gradle",
        String.replace(
          current_build_gradle,
          "io.github.sztheory:crosswake-shell-core-android:0.2.0",
          "io.github.sztheory:crosswake-shell-core-android:+"
        )
      )

    assert Enum.any?(dynamic_version_failures, &(&1.category == :dynamic_android_coordinate))
  end

  test "synthetic regressions fail when native labels disappear from public proof surfaces" do
    failures =
      scan_surface(
        "README.md",
        """
        # Crosswake

        This README omits the native evidence labels.
        """
      )

    assert Enum.any?(failures, &(&1.category == :missing_label))
  end

  test "synthetic regressions fail on stale Android UAT version wording and overclaims" do
    current_android_uat = File.read!("guides/android_uat.md")

    stale_version_failures =
      scan_surface(
        "guides/android_uat.md",
        String.replace(current_android_uat, "Crosswake v0.2.0", "Crosswake v0.1.0") <>
          "\nPreserved current version marker: Crosswake v0.2.0\n"
      )

    assert Enum.any?(stale_version_failures, &(&1.category == :stale_android_truth))

    overclaim_failures =
      scan_surface(
        "guides/android_uat.md",
        """
        JVM hermetic proof proves physical-device support.
        Emulator evidence is verified Android support.
        """
      )

    assert Enum.any?(overclaim_failures, &(&1.category == :device_support_overclaim))
  end

  test "native collateral manifest example keeps advisory labels and unavailable reasons" do
    failures =
      "examples/native_evidence/evidence-manifest.example.json"
      |> File.read!()
      |> then(&scan_surface("examples/native_evidence/evidence-manifest.example.json", &1))

    assert_no_drift_failures(failures)
  end

  test "synthetic regressions fail when native collateral overclaims simulator or emulator support" do
    simulator_overclaim =
      scan_surface(
        "examples/native_evidence/evidence-manifest.example.json",
        """
        {
          "routes": [
            {
              "route_id": "ios-simulator-route-tour",
              "runtime_owner": "native_shell",
              "platform_runtime": "ios-simulator",
              "command": "CROSSWAKE_IOS_PROJECT_ROOT=examples/ios_shell_host bash script/verify_generated_ios_shell.sh",
              "proof_class": "advisory evidence",
              "support_label": "simulator evidence",
              "coordinate_mode": "checked-in public-coordinate proof",
              "source_job": "native-collateral-advisory",
              "captured_at": "2026-06-19T00:00:00.000Z",
              "artifacts": ["ios-simulator.png"],
              "retention_label": "ci-artifact-14-days",
              "known_limitations": ["simulator evidence proves physical-device support"],
              "status": "captured"
            }
          ]
        }
        """
      )

    assert Enum.any?(simulator_overclaim, &(&1.category == :device_support_overclaim))

    merge_blocking_overclaim =
      scan_surface(
        "examples/native_evidence/evidence-manifest.example.json",
        "emulator evidence is merge-blocking native support"
      )

    assert Enum.any?(merge_blocking_overclaim, &(&1.category == :merge_blocking_native_overclaim))
  end

  test "synthetic regressions fail on screenshot-only proof and native authority claims" do
    screenshot_failures =
      scan_surface(
        "examples/native_evidence/evidence-manifest.example.json",
        "The screenshot proof confirms the native shell works."
      )

    assert Enum.any?(screenshot_failures, &(&1.category == :screenshot_proof_overclaim))

    authority_failures =
      scan_surface(
        "examples/native_evidence/evidence-manifest.example.json",
        "Native capture text claims camera support, media-upload support, and provider authority."
      )

    assert Enum.any?(authority_failures, &(&1.category == :native_authority_overclaim))
  end

  test "synthetic regressions fail on missing native collateral coordinate mode and unavailable reason" do
    current_manifest =
      "examples/native_evidence/evidence-manifest.example.json"
      |> File.read!()
      |> Jason.decode!()

    missing_coordinate_mode =
      current_manifest
      |> update_in(["routes", Access.at(0)], &Map.delete(&1, "coordinate_mode"))
      |> Jason.encode!()
      |> then(&scan_surface("examples/native_evidence/evidence-manifest.example.json", &1))

    assert Enum.any?(missing_coordinate_mode, &(&1.category == :missing_native_coordinate_mode))

    missing_unavailable_reason =
      current_manifest
      |> update_in(["routes", Access.at(1)], &Map.delete(&1, "unavailable_reason"))
      |> Jason.encode!()
      |> then(&scan_surface("examples/native_evidence/evidence-manifest.example.json", &1))

    assert Enum.any?(
             missing_unavailable_reason,
             &(&1.category == :missing_native_unavailable_reason)
           )
  end

  defp current_version do
    @current_version
  end

  defp scan_paths(paths) do
    paths
    |> Enum.flat_map(fn path ->
      path
      |> File.read!()
      |> then(&scan_surface(path, &1))
    end)
  end

  defp scan_surface(path, contents) do
    line_rule_failures(path, contents) ++
      required_label_failures(path, contents) ++
      required_term_failures(path, contents) ++
      native_collateral_manifest_failures(path, contents)
  end

  defp required_label_failures(path, contents) do
    required_labels(path)
    |> Enum.flat_map(fn label ->
      if String.contains?(contents, label) do
        []
      else
        [failure(path, :missing_label, detail: "missing required label `#{label}`")]
      end
    end)
  end

  defp required_term_failures(path, contents) do
    required_terms(path)
    |> Enum.flat_map(fn term ->
      if String.contains?(contents, term) do
        []
      else
        [failure(path, :missing_required_term, detail: "missing required term `#{term}`")]
      end
    end)
  end

  defp line_rule_failures(path, contents) do
    contents
    |> String.split("\n")
    |> Enum.with_index(1)
    |> Enum.flat_map(fn {line, line_number} ->
      []
      |> maybe_line_failure(
        path,
        line,
        line_number,
        ~r/XCLocalSwiftPackageReference/,
        :stale_ios_local_reference,
        "checked-in iOS host still uses a local Swift package reference"
      )
      |> maybe_line_failure(
        path,
        line,
        line_number,
        ~r/relativePath = "\.\.\/\.\.\/packages\/crosswake-shell-core-ios"/,
        :stale_ios_local_reference,
        "checked-in iOS host still points at the local packages checkout"
      )
      |> maybe_line_failure(
        path,
        line,
        line_number,
        ~r/dev\.crosswake:shell-core-android/,
        :stale_android_coordinate,
        "checked-in Android host still references the old dev.crosswake coordinate"
      )
      |> maybe_line_failure(
        path,
        line,
        line_number,
        ~r/project\(':crosswake-shell-core-android'\)/,
        :stale_android_coordinate,
        "checked-in Android host still points at a local project dependency"
      )
      |> maybe_line_failure(
        path,
        line,
        line_number,
        ~r/io\.github\.sztheory:crosswake-shell-core-android:\+|io\.github\.sztheory:crosswake-shell-core-android:\$\{|io\.github\.sztheory:crosswake-shell-core-android:\$[A-Za-z_][A-Za-z0-9_]*/,
        :dynamic_android_coordinate,
        "checked-in Android host still uses a dynamic dependency version"
      )
      |> maybe_line_failure(
        path,
        line,
        line_number,
        ~r/0\.1\.0/,
        stale_version_category(path),
        "stale 0.1.0 truth remains in a public native surface"
      )
      |> maybe_line_failure(
        path,
        line,
        line_number,
        ~r/\bverified Android\b/i,
        :device_support_overclaim,
        "line overstates Android verification"
      )
      |> maybe_line_failure(
        path,
        line,
        line_number,
        ~r/\bphysical-device support\b/i,
        :device_support_overclaim,
        "line overstates physical-device support"
      )
      |> maybe_line_failure(
        path,
        line,
        line_number,
        ~r/\bmerge-blocking native support\b/i,
        :merge_blocking_native_overclaim,
        "line turns advisory native collateral into merge-blocking support"
      )
      |> maybe_line_failure(
        path,
        line,
        line_number,
        ~r/\bscreenshot proof\b|\bscreenshot collateral described as proof\b/i,
        :screenshot_proof_overclaim,
        "line treats screenshot collateral as proof by itself"
      )
      |> maybe_line_failure(
        path,
        line,
        line_number,
        ~r/\b(camera support|media-upload support|provider authority|app-store readiness)\b/i,
        :native_authority_overclaim,
        "line claims native/provider authority from collateral"
      )
      |> maybe_line_failure(
        path,
        line,
        line_number,
        ~r/\b(emulator evidence|device evidence|JVM hermetic proof)\b.*\bsupport\b/i,
        :device_support_overclaim,
        "line turns advisory evidence into support truth"
      )
      |> maybe_line_failure(
        path,
        line,
        line_number,
        ~r/\blocal-development proof\b/i,
        :stale_label_vocabulary,
        "line still uses the old local-development proof label"
      )
    end)
  end

  defp maybe_line_failure(failures, path, line, line_number, regex, category, detail) do
    if Regex.match?(regex, line) and not line_support_negated?(line) do
      [
        failure(path, category, line: line_number, detail: detail)
        | failures
      ]
    else
      failures
    end
  end

  defp line_support_negated?(line) do
    lowered = String.downcase(line)

    String.contains?(lowered, " not ") or
      String.starts_with?(lowered, "not ") or
      String.contains?(lowered, "not claimed:") or
      String.contains?(lowered, " none ") or
      String.starts_with?(lowered, "none ") or
      String.contains?(lowered, " without ") or
      String.contains?(lowered, " cannot ") or
      String.contains?(lowered, " never ") or
      String.contains?(lowered, " imply ")
  end

  defp required_labels(path) do
    case path do
      "README.md" ->
        [
          "checked-in public-coordinate proof",
          "local-dev proof",
          "generated public-coordinate proof",
          "JVM hermetic proof",
          "emulator evidence",
          "device evidence",
          "verification-required",
          "rebuild-required"
        ]

      "examples/QUICK_START.md" ->
        ["checked-in public-coordinate proof", "local-dev proof", "--local"]

      "guides/install.md" ->
        [
          "checked-in public-coordinate proof",
          "generated public-coordinate proof",
          "local-dev proof",
          "--local"
        ]

      "guides/native_shell.md" ->
        [
          "checked-in public-coordinate proof",
          "generated public-coordinate proof",
          "local-dev proof",
          "JVM hermetic proof",
          "emulator evidence",
          "device evidence"
        ]

      "guides/compatibility.md" ->
        [
          "checked-in public-coordinate proof",
          "generated public-coordinate proof",
          "local-dev proof",
          "--local"
        ]

      "guides/support_matrix.md" ->
        [
          "checked-in public-coordinate proof",
          "generated public-coordinate proof",
          "local-dev proof",
          "JVM hermetic proof",
          "emulator evidence",
          "device evidence",
          "verification-required",
          "rebuild-required"
        ]

      "guides/android_uat.md" ->
        [
          "checked-in public-coordinate proof",
          "local-dev proof",
          "JVM hermetic proof",
          "emulator evidence",
          "device evidence",
          "verification-required",
          "rebuild-required"
        ]

      "examples/ios_shell_host/README.md" ->
        ["checked-in public-coordinate proof", "published-coordinate mode", "--local"]

      "examples/android_shell_host/README.md" ->
        ["checked-in public-coordinate proof", "published-coordinate mode", "--local"]

      "priv/templates/crosswake/shell/ios/README.md.eex" ->
        [
          "generated public-coordinate proof",
          "local-dev proof",
          "published-coordinate mode",
          "maintainer/local mode",
          "--local",
          "@local"
        ]

      "priv/templates/crosswake/shell/android/README.md.eex" ->
        [
          "generated public-coordinate proof",
          "local-dev proof",
          "published-coordinate mode",
          "maintainer/local mode",
          "--local",
          "@local"
        ]

      "lib/crosswake/support_matrix/renderer.ex" ->
        [
          "checked-in public-coordinate proof",
          "local-dev proof",
          "generated public-coordinate proof",
          "JVM hermetic proof",
          "emulator evidence",
          "device evidence",
          "verification-required",
          "rebuild-required"
        ]

      "lib/crosswake/support_matrix/support_matrix.ex" ->
        ["checked-in public-coordinate proof"]

      "script/capture-native-collateral.mjs" ->
        [
          "advisory evidence",
          "checked-in public-coordinate proof",
          "simulator evidence",
          "emulator evidence"
        ]

      ".github/workflows/native-collateral-advisory.yml" ->
        ["advisory evidence", "merge-blocking proof", "retention-days"]

      "examples/native_evidence/evidence-manifest.example.json" ->
        ["advisory evidence", "checked-in public-coordinate proof", "simulator evidence"]

      _ ->
        []
    end
  end

  defp required_terms(path) do
    case path do
      "README.md" ->
        [
          "guides/support_matrix.md#support-truth-label-legend",
          "checked-in public-coordinate proof"
        ]

      "examples/QUICK_START.md" ->
        [
          "What this proves:",
          "What this does not prove:",
          "Next link:",
          "published-coordinate mode"
        ]

      "guides/install.md" ->
        ["## Native Evidence Labels", "generated public-coordinate proof", "local-dev proof"]

      "guides/native_shell.md" ->
        ["The checked-in host paths are `checked-in public-coordinate proof`", "local-dev proof"]

      "guides/compatibility.md" ->
        [
          "checked-in public-coordinate proof",
          "generated public-coordinate proof",
          "local-dev proof"
        ]

      "guides/android_uat.md" ->
        [current_version(), "Android 15 (API 35)", "What This Proves", "Boundary"]

      "examples/ios_shell_host/README.md" ->
        ["What this proves:", "What this does not prove:", "Next link:"]

      "examples/android_shell_host/README.md" ->
        ["What this proves:", "What this does not prove:", "Next link:"]

      "priv/templates/crosswake/shell/ios/README.md.eex" ->
        ["What this proves:", "What this does not prove:", "Next link:", "crosswake_shell"]

      "priv/templates/crosswake/shell/android/README.md.eex" ->
        ["What this proves:", "What this does not prove:", "Next link:", "crosswake_shell"]

      "examples/ios_shell_host/CrosswakeShell.xcodeproj/project.pbxproj" ->
        [
          "XCRemoteSwiftPackageReference",
          "repositoryURL = \"https://github.com/szTheory/crosswake-shell-core-ios.git\"",
          "minimumVersion = #{current_version()}"
        ]

      "examples/android_shell_host/app/build.gradle" ->
        [
          "io.github.sztheory:crosswake-shell-core-android:#{current_version()}",
          "versionName \"#{current_version()}\""
        ]

      "lib/crosswake/support_matrix/renderer.ex" ->
        ["## Support-Truth Label Legend", "checked-in public-coordinate proof"]

      "lib/crosswake/support_matrix/support_matrix.ex" ->
        ["checked-in public-coordinate proof"]

      "script/capture-native-collateral.mjs" ->
        [
          "CROSSWAKE_IOS_PROJECT_ROOT=examples/ios_shell_host",
          "CROSSWAKE_ANDROID_PROJECT_ROOT=examples/android_shell_host",
          "CROSSWAKE_ANDROID_CONNECTED_TESTS=1",
          "unavailable_reason",
          "physical-device support"
        ]

      ".github/workflows/native-collateral-advisory.yml" ->
        [
          "workflow_dispatch",
          "crosswake-ios-simulator-advisory-evidence",
          "crosswake-android-emulator-advisory-evidence",
          "Browser route-tour correctness remains the merge-blocking proof",
          "physical-device support"
        ]

      "examples/native_evidence/evidence-manifest.example.json" ->
        [
          "ios-simulator-route-tour",
          "android-emulator-route-tour",
          "unavailable_reason",
          "physical-device support"
        ]

      _ ->
        []
    end
  end

  defp native_collateral_manifest_failures(
         "examples/native_evidence/evidence-manifest.example.json" = path,
         contents
       ) do
    case Jason.decode(contents) do
      {:ok, %{"routes" => routes}} when is_list(routes) ->
        Enum.flat_map(routes, &native_route_failures(path, &1))

      {:ok, _manifest} ->
        [
          failure(path, :missing_native_routes,
            detail: "native manifest missing non-empty routes"
          )
        ]

      {:error, _error} ->
        []
    end
  end

  defp native_collateral_manifest_failures(_path, _contents), do: []

  defp native_route_failures(path, route) do
    route_id = Map.get(route, "route_id", "<unknown>")

    []
    |> maybe_native_field_failure(path, route, route_id, "command")
    |> maybe_native_field_failure(path, route, route_id, "platform_runtime")
    |> maybe_native_field_failure(path, route, route_id, "proof_class")
    |> maybe_native_field_failure(path, route, route_id, "support_label")
    |> maybe_native_field_failure(
      path,
      route,
      route_id,
      "coordinate_mode",
      :missing_native_coordinate_mode
    )
    |> maybe_native_field_failure(path, route, route_id, "captured_at")
    |> maybe_native_field_failure(path, route, route_id, "commit_sha", :missing_native_commit_sha)
    |> then(fn failures ->
      failures ++
        native_status_failures(path, route, route_id) ++
        native_label_failures(path, route, route_id)
    end)
  end

  defp maybe_native_field_failure(
         failures,
         path,
         route,
         route_id,
         field,
         category \\ :missing_native_field
       ) do
    if present?(Map.get(route, field)) do
      failures
    else
      [
        failure(path, category,
          detail: "native collateral route #{route_id} missing required field `#{field}`"
        )
        | failures
      ]
    end
  end

  defp native_status_failures(path, %{"status" => "unavailable"} = route, route_id) do
    if present?(Map.get(route, "unavailable_reason")) do
      []
    else
      [
        failure(path, :missing_native_unavailable_reason,
          detail: "native collateral route #{route_id} is unavailable without a concrete reason"
        )
      ]
    end
  end

  defp native_status_failures(_path, _route, _route_id), do: []

  defp native_label_failures(path, route, route_id) do
    cond do
      route["proof_class"] != "advisory evidence" ->
        [
          failure(path, :native_proof_class_overclaim,
            detail: "native collateral route #{route_id} must use advisory evidence"
          )
        ]

      route["coordinate_mode"] != "checked-in public-coordinate proof" ->
        [
          failure(path, :missing_native_coordinate_mode,
            detail:
              "native collateral route #{route_id} must use checked-in public-coordinate proof"
          )
        ]

      route["status"] == "captured" and
          route["support_label"] not in ["simulator evidence", "emulator evidence"] ->
        [
          failure(path, :missing_native_execution_label,
            detail:
              "captured native collateral route #{route_id} must name simulator or emulator evidence"
          )
        ]

      route["status"] != "captured" and
          route["support_label"] in ["simulator evidence", "emulator evidence"] ->
        [
          failure(path, :native_execution_label_overclaim,
            detail:
              "unavailable native collateral route #{route_id} must not claim simulator/emulator evidence"
          )
        ]

      true ->
        []
    end
  end

  defp stale_version_category("guides/android_uat.md"), do: :stale_android_truth

  defp stale_version_category("examples/android_shell_host/app/build.gradle"),
    do: :stale_android_coordinate

  defp stale_version_category(_path), do: :stale_public_version_truth

  defp present?(value), do: not (is_nil(value) or value == "" or value == [])

  defp failure(path, category, opts) do
    %{
      path: path,
      line: Keyword.get(opts, :line),
      category: category,
      detail: Keyword.fetch!(opts, :detail)
    }
  end

  defp assert_no_drift_failures([]), do: :ok

  defp assert_no_drift_failures(failures) do
    flunk("""
    Native evidence drift detected:

    #{format_failures(failures)}
    """)
  end

  defp format_failures(failures) do
    failures
    |> Enum.sort_by(fn %{path: path, line: line, category: category} ->
      {path, line || 0, to_string(category)}
    end)
    |> Enum.map_join("\n", &format_failure/1)
  end

  defp format_failure(%{path: path, line: nil, category: category, detail: detail}) do
    "#{path} [#{category}] #{detail}"
  end

  defp format_failure(%{path: path, line: line, category: category, detail: detail}) do
    "#{path}:#{line} [#{category}] #{detail}"
  end
end
