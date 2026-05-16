defmodule Crosswake.Manifest.Validator do
  @moduledoc """
  Validates manifest contract truth before serialization or release artifact output.
  """

  alias Crosswake.Compatibility
  alias Crosswake.Manifest.Types
  alias Crosswake.Policy.Error
  alias Crosswake.SupportMatrix

  @spec validate(Types.Root.t()) :: [Error.t()]
  def validate(%Types.Root{} = manifest) do
    []
    |> validate_top_level_sections(manifest)
    |> validate_compatibility(manifest.compatibility)
    |> validate_support_matrix(manifest.support_matrix)
    |> validate_routes(manifest.routes, manifest.capability_registry, manifest.pack_registry)
  end

  defp validate_top_level_sections(errors, %Types.Root{} = manifest) do
    [
      {:manifest_schema_version, manifest.manifest_schema_version},
      {:crosswake_version, manifest.crosswake_version},
      {:generated_at, manifest.generated_at},
      {:host, manifest.host},
      {:compatibility, manifest.compatibility},
      {:support_matrix, manifest.support_matrix},
      {:capability_registry, manifest.capability_registry},
      {:pack_registry, manifest.pack_registry},
      {:routes, manifest.routes}
    ]
    |> Enum.reduce(errors, fn {key, value}, acc ->
      if present?(key, value) do
        acc
      else
        [
          build_error(
            key: key,
            message: "manifest is missing required top-level section #{inspect(key)}",
            hint: "populate #{inspect(key)} before manifest serialization"
          )
          | acc
        ]
      end
    end)
  end

  defp validate_compatibility(errors, compatibility) do
    Compatibility.validate_contract(compatibility)
    |> Enum.map(&build_error/1)
    |> Kernel.++(errors)
  end

  defp validate_support_matrix(errors, support_matrix) do
    SupportMatrix.validate(support_matrix)
    |> Enum.map(&build_error/1)
    |> Kernel.++(errors)
  end

  defp validate_routes(errors, routes, capability_registry, pack_registry) do
    Enum.reduce(routes, errors, fn {_id, route}, acc ->
      route
      |> route_errors(capability_registry, pack_registry)
      |> Enum.map(&build_error(&1, route))
      |> Kernel.++(acc)
    end)
  end

  defp route_errors(route, capability_registry, pack_registry) do
    []
    |> validate_route_field(route, :path, route.path)
    |> validate_route_field(route, :runtime, route.runtime)
    |> validate_route_capabilities(route, capability_registry)
    |> validate_route_packs(route, pack_registry)
  end

  defp validate_route_field(errors, _route, _key, value) when not is_nil(value), do: errors

  defp validate_route_field(errors, route, key, _value) do
    [
      %{
        key: key,
        route_id: route.id,
        path: route.path,
        message: "route #{route.id} is missing required field #{inspect(key)}",
        hint: "populate #{inspect(key)} for route #{route.id} before manifest generation"
      }
      | errors
    ]
  end

  defp validate_route_capabilities(errors, route, capability_registry) do
    Enum.reduce(route.capabilities, errors, fn capability, acc ->
      if Map.has_key?(capability_registry, capability) do
        acc
      else
        [
          %{
            key: :capabilities,
            route_id: route.id,
            path: route.path,
            message:
              "route #{route.id} declares capability #{inspect(capability)} outside the manifest registry",
            hint:
              "register #{inspect(capability)} in capability_registry before validation passes"
          }
          | acc
        ]
      end
    end)
  end

  defp validate_route_packs(errors, route, pack_registry) do
    Enum.reduce(route.packs, errors, fn pack_reference, acc ->
      if Map.has_key?(pack_registry, pack_reference) do
        acc
      else
        [
          %{
            key: :packs,
            route_id: route.id,
            path: route.path,
            message:
              "route #{route.id} declares pack reference #{inspect(pack_reference)} outside the manifest pack registry",
            hint:
              "compile #{inspect(pack_reference)} into pack_registry before validation passes"
          }
          | acc
        ]
      end
    end)
  end

  defp build_error(attrs, route \\ nil) do
    struct!(Error, %{
      key: attrs[:key],
      route_id: attrs[:route_id] || (route && route.id),
      path: attrs[:path] || (route && route.path),
      message: attrs[:message],
      hint: attrs[:hint]
    })
  end

  defp present?(:pack_registry, value) when is_map(value), do: true
  defp present?(_key, value) when value in [nil, ""], do: false
  defp present?(_key, value) when is_map(value), do: map_size(value) > 0
  defp present?(_key, value) when is_list(value), do: value != []
  defp present?(_key, _value), do: true
end
