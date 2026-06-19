defmodule Crosswake.Guides.EvidenceManifestTest do
  use ExUnit.Case, async: true

  @example_manifest "examples/phoenix_host/evidence/evidence-manifest.example.json"
  @support_matrix "guides/support_matrix.md"
  @current_version Application.spec(:crosswake, :vsn) |> to_string()

  @root_required_fields ~w(schema_version crosswake_version commit_sha source_job captured_at retention_label routes)

  @route_required_fields ~w(route_id runtime_owner platform_runtime command proof_class support_label coordinate_mode source_job captured_at artifacts retention_label known_limitations status)

  @expected_route_ids ~w(library bridge-proof offline-study selective-native-claim-capture)

  @allowed_labels [
    "merge-blocking proof",
    "advisory evidence",
    "checked-in public-coordinate proof",
    "local-dev proof",
    "generated public-coordinate proof",
    "JVM hermetic proof",
    "emulator evidence",
    "device evidence",
    "verification-required",
    "rebuild-required"
  ]

  test "committed example manifest is complete, bounded, and uses current source truth" do
    manifest = read_manifest!(@example_manifest)

    assert manifest["crosswake_version"] == @current_version

    assert MapSet.new(Enum.map(manifest["routes"], & &1["route_id"])) ==
             MapSet.new(@expected_route_ids)

    with_artifact_fixture(manifest, fn artifact_root ->
      assert validate_manifest(manifest, artifact_root) == :ok
    end)
  end

  test "generated route-tour manifest is valid when a manifest path is provided" do
    case System.get_env("CROSSWAKE_EVIDENCE_MANIFEST_PATH") do
      nil ->
        assert true

      manifest_path ->
        manifest = read_manifest!(manifest_path)

        assert validate_manifest(manifest, Path.dirname(manifest_path)) == :ok
    end
  end

  test "allowed labels are literal support-matrix vocabulary" do
    support_matrix = File.read!(@support_matrix)

    for label <- @allowed_labels do
      assert support_matrix =~ label
    end

    manifest = read_manifest!(@example_manifest)
    labels = manifest_labels(manifest)

    assert Enum.all?(labels, &(&1 in @allowed_labels))
    assert "merge-blocking proof" in labels
    assert "advisory evidence" in labels
  end

  test "synthetic regressions reject missing D-08 root and route fields" do
    manifest = read_manifest!(@example_manifest)

    assert_failure(
      Map.delete(manifest, "source_job"),
      "manifest missing field source_job"
    )

    assert_failure(
      update_in(manifest, ["routes"], fn [route | rest] ->
        [Map.delete(route, "command") | rest]
      end),
      "route library missing field command"
    )
  end

  test "synthetic regressions reject unsupported labels and missing retention labels" do
    manifest = read_manifest!(@example_manifest)

    assert_failure(
      put_in(manifest, ["routes", Access.at(0), "proof_class"], "screenshot proof"),
      "route library unsupported proof_class screenshot proof"
    )

    assert_failure(
      put_in(manifest, ["routes", Access.at(0), "support_label"], "native support"),
      "route library unsupported support_label native support"
    )

    assert_failure(
      update_in(manifest, ["routes", Access.at(0)], &Map.delete(&1, "retention_label")),
      "route library missing field retention_label"
    )
  end

  test "synthetic regressions reject missing limitations and required browser artifacts" do
    manifest = read_manifest!(@example_manifest)

    assert_failure(
      put_in(manifest, ["routes", Access.at(0), "known_limitations"], []),
      "route library missing known_limitations"
    )

    with_artifact_fixture(manifest, fn artifact_root ->
      missing_path = Path.join([artifact_root, "screenshots", "library.png"])
      File.rm!(missing_path)

      assert_failure(
        manifest,
        "route library missing required artifact screenshots/library.png",
        artifact_root
      )
    end)
  end

  test "advisory native unavailable entries require concrete unavailable reasons" do
    manifest = read_manifest!(@example_manifest)

    unavailable_route =
      manifest
      |> get_in(["routes", Access.at(0)])
      |> Map.merge(%{
        "route_id" => "ios-simulator-route-tour",
        "proof_class" => "advisory evidence",
        "support_label" => "emulator evidence",
        "platform_runtime" => "ios-simulator",
        "status" => "unavailable",
        "artifacts" => []
      })
      |> Map.delete("unavailable_reason")

    advisory_manifest = %{manifest | "routes" => [unavailable_route]}

    assert_failure(
      advisory_manifest,
      "route ios-simulator-route-tour missing unavailable_reason"
    )

    assert validate_manifest(
             put_in(
               advisory_manifest,
               ["routes", Access.at(0), "unavailable_reason"],
               "No simulator runtime was available."
             ),
             nil
           ) == :ok
  end

  defp read_manifest!(path) do
    path
    |> File.read!()
    |> Jason.decode!()
  end

  defp validate_manifest(manifest, artifact_root) do
    failures =
      root_field_failures(manifest) ++
        route_collection_failures(manifest) ++
        route_failures(manifest, artifact_root)

    case failures do
      [] -> :ok
      failures -> {:error, failures}
    end
  end

  defp root_field_failures(manifest) do
    Enum.flat_map(@root_required_fields, fn field ->
      if present?(Map.get(manifest, field)) do
        []
      else
        ["manifest missing field #{field}"]
      end
    end)
  end

  defp route_collection_failures(%{"routes" => routes}) when is_list(routes) and routes != [] do
    []
  end

  defp route_collection_failures(_manifest), do: ["manifest missing non-empty routes"]

  defp route_failures(%{"routes" => routes}, artifact_root) when is_list(routes) do
    Enum.flat_map(routes, &validate_route(&1, artifact_root))
  end

  defp route_failures(_manifest, _artifact_root), do: []

  defp validate_route(route, artifact_root) do
    route_id = Map.get(route, "route_id", "<unknown>")

    required_route_field_failures(route, route_id) ++
      route_id_failures(route, route_id) ++
      label_failures(route, route_id) ++
      limitation_failures(route, route_id) ++
      unavailable_failures(route, route_id) ++
      artifact_failures(route, route_id, artifact_root)
  end

  defp required_route_field_failures(route, route_id) do
    Enum.flat_map(@route_required_fields, fn field ->
      if Map.has_key?(route, field) do
        []
      else
        ["route #{route_id} missing field #{field}"]
      end
    end)
  end

  defp route_id_failures(route, route_id) do
    if route_id in @expected_route_ids or
         String.contains?(Map.get(route, "platform_runtime", ""), "simulator") do
      []
    else
      ["route #{route_id} unsupported route_id"]
    end
  end

  defp label_failures(route, route_id) do
    [
      label_failure(route, route_id, "proof_class"),
      label_failure(route, route_id, "support_label"),
      coordinate_mode_failure(route, route_id)
    ]
    |> List.flatten()
  end

  defp label_failure(route, route_id, field) do
    value = Map.get(route, field)

    if value in @allowed_labels do
      []
    else
      ["route #{route_id} unsupported #{field} #{value}"]
    end
  end

  defp coordinate_mode_failure(route, route_id) do
    value = Map.get(route, "coordinate_mode")

    if is_nil(value) or value in @allowed_labels do
      []
    else
      ["route #{route_id} unsupported coordinate_mode #{value}"]
    end
  end

  defp limitation_failures(route, route_id) do
    limitations = Map.get(route, "known_limitations")

    cond do
      not is_list(limitations) or limitations == [] ->
        ["route #{route_id} missing known_limitations"]

      not Enum.any?(limitations, &String.contains?(&1, "does not prove")) ->
        ["route #{route_id} known_limitations missing non-claim language"]

      true ->
        []
    end
  end

  defp unavailable_failures(%{"status" => "unavailable"} = route, route_id) do
    if present?(Map.get(route, "unavailable_reason")) do
      []
    else
      ["route #{route_id} missing unavailable_reason"]
    end
  end

  defp unavailable_failures(_route, _route_id), do: []

  defp artifact_failures(route, route_id, artifact_root) do
    artifacts = Map.get(route, "artifacts", [])

    cond do
      not is_list(artifacts) ->
        ["route #{route_id} missing artifacts"]

      route["proof_class"] == "merge-blocking proof" and route["status"] == "captured" and
          artifacts == [] ->
        ["route #{route_id} missing artifacts"]

      route["proof_class"] == "merge-blocking proof" and route["status"] == "captured" and
          artifact_root ->
        Enum.flat_map(artifacts, fn artifact ->
          if File.exists?(Path.join(artifact_root, artifact)) do
            []
          else
            ["route #{route_id} missing required artifact #{artifact}"]
          end
        end)

      true ->
        []
    end
  end

  defp present?(value), do: not (is_nil(value) or value == "")

  defp manifest_labels(manifest) do
    manifest["routes"]
    |> Enum.flat_map(fn route ->
      [route["proof_class"], route["support_label"], route["coordinate_mode"]]
    end)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
  end

  defp with_artifact_fixture(manifest, fun) do
    root =
      Path.join(
        System.tmp_dir!(),
        "crosswake-evidence-manifest-#{System.unique_integer([:positive])}"
      )

    for route <- manifest["routes"], artifact <- route["artifacts"] do
      path = Path.join(root, artifact)
      File.mkdir_p!(Path.dirname(path))
      File.write!(path, "placeholder artifact for #{route["route_id"]}\n")
    end

    try do
      fun.(root)
    after
      File.rm_rf!(root)
    end
  end

  defp assert_failure(manifest, expected, artifact_root \\ nil) do
    assert {:error, failures} = validate_manifest(manifest, artifact_root)
    assert expected in failures
  end
end
