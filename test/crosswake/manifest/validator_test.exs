defmodule Crosswake.Manifest.ValidatorTest do
  use ExUnit.Case, async: true

  alias Crosswake.Manifest
  alias Crosswake.Manifest.Serializer
  alias Crosswake.Manifest.Types
  alias Crosswake.Manifest.Validator
  alias Crosswake.SupportMatrix

  test "manifest validation rejects missing sections and invalid compatibility truth before serialization" do
    manifest =
      Types.new_root(
        manifest_schema_version: "1.0.0",
        crosswake_version: "0.1.0",
        generated_at: "2026-05-14T00:00:00Z",
        host: Types.new_host(),
        compatibility: Types.new_compatibility(remote_updates: [:overlay]),
        support_matrix:
          Types.new_support_matrix(
            phoenix: [],
            live_view: SupportMatrix.canonical().live_view,
            ios: SupportMatrix.canonical().ios,
            android: SupportMatrix.canonical().android,
            shells: SupportMatrix.canonical().shells
          ),
        capability_registry: %{},
        routes: %{}
      )

    errors = Validator.validate(manifest)

    assert Enum.any?(errors, &String.contains?(&1.message, "remote updates"))
    assert Enum.any?(errors, &String.contains?(&1.message, "support matrix is missing phoenix"))
  end

  test "json rendering is deterministic and preserves created, reused, and updated semantics" do
    manifest = manifest_fixture()

    path =
      Path.join(
        System.tmp_dir!(),
        "crosswake-manifest-#{System.unique_integer([:positive])}.json"
      )

    rendered_once = Serializer.render(manifest)
    rendered_twice = Serializer.render(manifest)

    assert rendered_once == rendered_twice
    assert {:ok, :created} = Serializer.write(path, manifest)
    assert {:ok, :reused} = Serializer.write(path, manifest)

    updated_manifest =
      put_in(manifest.routes["camera"].allowlisted_origins, [
        Types.default_origin(),
        "https://cached.crosswake.invalid"
      ])

    assert {:ok, :updated} = Serializer.write(path, updated_manifest)
  end

  test "manifest compile returns structured validation failures instead of opaque strings" do
    invalid_support_matrix =
      Types.new_support_matrix(
        phoenix: SupportMatrix.canonical().phoenix,
        live_view: SupportMatrix.canonical().live_view,
        ios: SupportMatrix.canonical().ios,
        android: SupportMatrix.canonical().android,
        shells: []
      )

    invalid_routes = [
      %{
        path: "/camera",
        helper: "camera",
        verb: :get,
        metadata: %{
          crosswake: [
            id: "camera",
            runtime: :native_screen,
            capabilities: ["camera"],
            security: :sensitive
          ]
        }
      }
    ]

    assert {:error, %{errors: errors}} =
             Manifest.compile(invalid_routes, support_matrix: invalid_support_matrix)

    assert Enum.all?(errors, &match?(%Crosswake.Policy.Error{}, &1))
  end

  test "manifest validation rejects route pack references that are missing from the root pack registry" do
    manifest =
      manifest_fixture()
      |> put_in([Access.key!(:routes), "camera", Access.key!(:packs)], ["missing.pack@9.9.9"])

    errors = Validator.validate(manifest)

    assert Enum.any?(errors, fn error ->
             String.contains?(
               error.message,
               "route camera declares pack reference \"missing.pack@9.9.9\" outside the manifest pack registry"
             )
           end)
  end

  test "manifest validation rejects route pack references that drift from the canonical registry version" do
    manifest =
      manifest_fixture()
      |> put_in([Access.key!(:routes), "camera", Access.key!(:packs)], ["camera_capture_assets@2.0.0"])

    errors = Validator.validate(manifest)

    assert Enum.any?(errors, fn error ->
             String.contains?(
               error.message,
               "route camera declares pack reference \"camera_capture_assets@2.0.0\" outside the manifest pack registry"
             )
           end)
  end

  test "manifest validation rejects transfer seams that are missing required endpoint truth" do
    manifest =
      manifest_fixture()
      |> put_in([Access.key!(:routes), "camera", Access.key!(:transfers)], [
        Types.new_transfer_seam(
          id: "capture_upload",
          intent: :upload,
          direction: :inbound,
          verification: :required,
          media_types: ["image/*"]
        )
      ])

    errors = Validator.validate(manifest)

    assert Enum.any?(errors, fn error ->
             String.contains?(error.message, "transfer seam \"capture_upload\" is invalid")
           end)
  end

  test "manifest validation rejects route runtime drift for native-capture transfer seams" do
    manifest =
      manifest_fixture()
      |> put_in([Access.key!(:routes), "camera", Access.key!(:runtime)], :live_view)

    errors = Validator.validate(manifest)

    assert Enum.any?(errors, fn error ->
             String.contains?(error.message, "native_capture source requires route runtime :native_screen")
           end)
  end

  defp manifest_fixture do
    Types.new_root(
      crosswake_version: "0.1.0",
      generated_at: "2026-05-14T00:00:00Z",
      host: Types.new_host(),
      compatibility: Types.new_compatibility(),
      support_matrix: SupportMatrix.canonical(),
      capability_registry: %{
        "camera" => Types.new_capability(id: "camera", version: "1.0.0")
      },
      pack_registry: %{
        "camera_capture_assets@1.0.0" =>
          Types.new_pack_entry(id: "camera_capture_assets", version: "1.0.0", kind: :media)
      },
      routes: %{
        "camera" =>
          Types.new_route_entry(
            id: "camera",
            path: "/camera",
            runtime: :native_screen,
            offline: :unavailable,
            capabilities: ["camera"],
            packs: ["camera_capture_assets@1.0.0"],
            transfers: [
              Types.new_transfer_seam(
                id: "capture_upload",
                intent: :upload,
                direction: :inbound,
                source: :native_capture,
                verification: :required,
                media_types: ["image/*"]
              )
            ],
            security: :sensitive,
            allowlisted_origins: [Types.default_origin()]
          )
      }
    )
  end
end
