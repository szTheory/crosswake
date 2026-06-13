defmodule Crosswake.RuntimeLine.RebuildPolicy do
  @moduledoc """
  Policy contract deriving OTA-safe vs. rebuild-required classification from the
  existing `native_runtime_version` compatibility axis.

  ## Derivation principle

  This module does NOT maintain a full static registry of rebuild truth — it
  **derives** classification from the data that already owns that truth:

  - **Capability-axis change classes** (`capability_family_add`,
    `bridge_schema_change`, `permission_add`, `entitlement_add`,
    `push_capability_change`, `url_scheme_change`) derive their verdict from
    `Capability.rebuild`, which is the authoritative field on the capability
    record. Never classify by change-class label alone; always key off
    `Capability.rebuild`. This is the footgun the Expo EAS / CodePush
    "it's-just-JS" OTA break demonstrates: label-only classification silently
    misses native-incompatible changes.

  - **System-level change classes** (`sdk_floor_bump`, `privacy_manifest_entry`)
    have no capability owner; they map via the locked `@system_rebuild_classes`
    closed set. New system classes go through a phase, not a config key.

  ## companion_required is never OTA-safe

  A change that requires a companion rebuild still requires a binary rebuild —
  it is never safe to push OTA. `classify/2` with `:companion_required` always
  returns `{:rebuild_required, :companion_shell}`.

  ## diff/2 is tooling input, NOT a release-gate oracle

  `diff/2` classifies changes between two `Root.t()` manifests and returns a
  list of `{change_class(), verdict()}` pairs. It does NOT know whether a binary
  with the new `native_runtime_version` has already shipped to the App Store or
  Google Play. Using `diff/2` output as a release gate without consulting the
  published version history is incorrect — it is a doctor/tooling input only.
  """

  alias Crosswake.Manifest.Types.Capability
  alias Crosswake.Manifest.Types.Root

  # Closed set. System classes have no capability owner and always require a
  # native shell rebuild. New system classes go through a phase, not a config key.
  @system_rebuild_classes [:sdk_floor_bump, :privacy_manifest_entry]

  # All 8 change classes in the taxonomy.
  @capability_axis_classes [
    :bridge_schema_change,
    :capability_family_add,
    :permission_add,
    :entitlement_add,
    :push_capability_change,
    :url_scheme_change
  ]

  @type change_class ::
          :bridge_schema_change
          | :capability_family_add
          | :permission_add
          | :entitlement_add
          | :sdk_floor_bump
          | :privacy_manifest_entry
          | :push_capability_change
          | :url_scheme_change

  @type verdict :: :ota_safe | {:rebuild_required, :native_shell | :companion_shell}

  @doc """
  Classifies a `change_class()` as OTA-safe or rebuild-required.

  For capability-axis change classes, the `capability` argument must be a
  `Capability.t()` struct — `nil` is not accepted because the source of truth
  (`Capability.rebuild`) is required. Passing `nil` raises `ArgumentError`.

  For system-level classes (`sdk_floor_bump`, `privacy_manifest_entry`), the
  `capability` argument is ignored and may be `nil`.

  ## Examples

      iex> cap = %Capability{id: "haptics", version: "1.0.0", rebuild: :native_required}
      iex> RebuildPolicy.classify(:capability_family_add, cap)
      {:rebuild_required, :native_shell}

      iex> cap = %Capability{id: "haptics", version: "1.0.0", rebuild: :none}
      iex> RebuildPolicy.classify(:capability_family_add, cap)
      :ota_safe

      iex> RebuildPolicy.classify(:sdk_floor_bump, nil)
      {:rebuild_required, :native_shell}
  """
  @spec classify(change_class(), Capability.t() | nil) :: verdict()
  def classify(change_class, _capability) when change_class in @system_rebuild_classes do
    {:rebuild_required, :native_shell}
  end

  def classify(change_class, nil) when change_class in @capability_axis_classes do
    raise ArgumentError,
          "classify/2 requires a Capability struct for capability-axis change class " <>
            "#{inspect(change_class)}; got nil. " <>
            "The source of truth is Capability.rebuild — never classify by label alone."
  end

  def classify(change_class, %Capability{} = capability)
      when change_class in @capability_axis_classes do
    case capability.rebuild do
      :native_required -> {:rebuild_required, :native_shell}
      :companion_required -> {:rebuild_required, :companion_shell}
      :none -> :ota_safe
    end
  end

  @doc """
  Public predicate over `Capability.rebuild()`.

  Returns `true` when a rebuild is required for the given rebuild value,
  `false` when OTA-safe.

  ## Examples

      iex> RebuildPolicy.rebuild_required?(:none)
      false

      iex> RebuildPolicy.rebuild_required?(:native_required)
      true

      iex> RebuildPolicy.rebuild_required?(:companion_required)
      true
  """
  @spec rebuild_required?(Capability.rebuild()) :: boolean()
  def rebuild_required?(:none), do: false
  def rebuild_required?(:native_required), do: true
  def rebuild_required?(:companion_required), do: true

  @doc """
  Detects change classes between two `Root.t()` manifests and classifies each.

  Returns a list of `{change_class(), verdict()}` pairs by comparing `root_a`
  and `root_b` and feeding each detected change through `classify/2`.

  **This function is tooling/doctor input, NOT a release-gate oracle.**
  It classifies changes present between two manifest snapshots; it does not
  know whether a binary with the new `native_runtime_version` has already
  shipped. Do not use the output of `diff/2` alone as a production release gate.
  """
  @spec diff(Root.t(), Root.t()) :: [{change_class(), verdict()}]
  def diff(%Root{} = root_a, %Root{} = root_b) do
    capability_changes(root_a, root_b)
    |> Enum.map(fn {change_class, capability} ->
      {change_class, classify(change_class, capability)}
    end)
  end

  # ---------------------------------------------------------------------------
  # Private helpers
  # ---------------------------------------------------------------------------

  # Detect capability-axis change classes by comparing capability registries.
  # Returns [{change_class(), Capability.t() | nil}] pairs.
  defp capability_changes(%Root{} = root_a, %Root{} = root_b) do
    added_capabilities = added_capabilities(root_a.capability_registry, root_b.capability_registry)
    sdk_changes = sdk_floor_changes(root_a.compatibility, root_b.compatibility)
    privacy_changes = privacy_manifest_changes(root_a, root_b)

    Enum.concat([added_capabilities, sdk_changes, privacy_changes])
  end

  defp added_capabilities(registry_a, registry_b) do
    ids_a = MapSet.new(Map.keys(registry_a))
    ids_b = MapSet.new(Map.keys(registry_b))

    added = MapSet.difference(ids_b, ids_a)

    Enum.map(added, fn id ->
      capability = Map.fetch!(registry_b, id)
      {:capability_family_add, capability}
    end)
  end

  defp sdk_floor_changes(compat_a, compat_b) do
    if compat_a.native_runtime_version != compat_b.native_runtime_version do
      [{:sdk_floor_bump, nil}]
    else
      []
    end
  end

  # Privacy manifest changes are detected by checking for new bridge capabilities
  # that carry a privacy declaration signal. Simplified heuristic: if native_runtime_version
  # changed and there are new capabilities, surface privacy_manifest_entry.
  defp privacy_manifest_changes(%Root{} = root_a, %Root{} = root_b) do
    ids_a = MapSet.new(Map.keys(root_a.capability_registry))
    ids_b = MapSet.new(Map.keys(root_b.capability_registry))
    added = MapSet.difference(ids_b, ids_a)

    # Only flag privacy_manifest_entry if native_runtime_version changed and capabilities added.
    # This is a conservative heuristic; callers can also pass system classes directly.
    if root_a.compatibility.native_runtime_version != root_b.compatibility.native_runtime_version and
         not Enum.empty?(added) do
      [{:privacy_manifest_entry, nil}]
    else
      []
    end
  end
end
