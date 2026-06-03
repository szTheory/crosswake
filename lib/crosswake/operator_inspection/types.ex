defmodule Crosswake.OperatorInspection.Types do
  @moduledoc """
  Typed operator inspection contract.

  The inspection document is route-authoritative: summaries, indexes, findings,
  and conditions are derived from the route entries and never replace them as
  support truth.
  """

  @schema_version "1.0.0"

  defmodule Document do
    @moduledoc false

    @enforce_keys [
      :schema_version,
      :generated_at,
      :crosswake_version,
      :source,
      :summary,
      :routes,
      :indexes,
      :findings,
      :provenance
    ]
    defstruct [
      :schema_version,
      :generated_at,
      :crosswake_version,
      :source,
      :summary,
      :routes,
      :indexes,
      :findings,
      :provenance
    ]
  end

  defmodule Route do
    @moduledoc false

    @enforce_keys [
      :id,
      :path,
      :runtime,
      :entry,
      :ownership,
      :offline,
      :capabilities,
      :commerce,
      :companion,
      :auth,
      :notifications,
      :support,
      :rebuild,
      :denials,
      :conditions
    ]
    defstruct [
      :id,
      :path,
      :runtime,
      :entry,
      :ownership,
      :offline,
      :capabilities,
      :commerce,
      :companion,
      :auth,
      :notifications,
      :support,
      :rebuild,
      :denials,
      :conditions
    ]
  end

  defmodule Condition do
    @moduledoc false

    @enforce_keys [:type, :status, :reason, :severity, :message, :route_id, :details]
    defstruct [:type, :status, :reason, :severity, :message, :route_id, :details]
  end

  @spec schema_version() :: String.t()
  def schema_version, do: @schema_version

  @spec document(keyword()) :: Document.t()
  def document(attrs) do
    struct!(Document, %{
      schema_version: Keyword.get(attrs, :schema_version, @schema_version),
      generated_at: Keyword.fetch!(attrs, :generated_at),
      crosswake_version: Keyword.fetch!(attrs, :crosswake_version),
      source: Keyword.fetch!(attrs, :source),
      summary: Keyword.fetch!(attrs, :summary),
      routes: Keyword.fetch!(attrs, :routes),
      indexes: Keyword.fetch!(attrs, :indexes),
      findings: Keyword.get(attrs, :findings, []),
      provenance: Keyword.fetch!(attrs, :provenance)
    })
  end

  @spec route(keyword()) :: Route.t()
  def route(attrs) do
    struct!(Route, %{
      id: Keyword.fetch!(attrs, :id),
      path: Keyword.fetch!(attrs, :path),
      runtime: Keyword.fetch!(attrs, :runtime),
      entry: Keyword.fetch!(attrs, :entry),
      ownership: Keyword.fetch!(attrs, :ownership),
      offline: Keyword.fetch!(attrs, :offline),
      capabilities: Keyword.get(attrs, :capabilities, []),
      commerce: Keyword.fetch!(attrs, :commerce),
      companion: Keyword.fetch!(attrs, :companion),
      auth: Keyword.fetch!(attrs, :auth),
      notifications: Keyword.fetch!(attrs, :notifications),
      support: Keyword.fetch!(attrs, :support),
      rebuild: Keyword.fetch!(attrs, :rebuild),
      denials: Keyword.get(attrs, :denials, []),
      conditions: Keyword.get(attrs, :conditions, [])
    })
  end

  @spec condition(keyword()) :: Condition.t()
  def condition(attrs) do
    struct!(Condition, %{
      type: Keyword.fetch!(attrs, :type),
      status: Keyword.fetch!(attrs, :status),
      reason: Keyword.fetch!(attrs, :reason),
      severity: Keyword.fetch!(attrs, :severity),
      message: Keyword.fetch!(attrs, :message),
      route_id: Keyword.fetch!(attrs, :route_id),
      details: Keyword.get(attrs, :details, %{})
    })
  end

  @spec to_map(term()) :: term()
  def to_map(%Document{} = document) do
    %{
      "schema_version" => document.schema_version,
      "generated_at" => document.generated_at,
      "crosswake_version" => document.crosswake_version,
      "source" => to_map(document.source),
      "summary" => to_map(document.summary),
      "routes" => to_map(document.routes),
      "indexes" => to_map(document.indexes),
      "findings" => to_map(document.findings),
      "provenance" => to_map(document.provenance)
    }
  end

  def to_map(%Route{} = route) do
    %{
      "id" => route.id,
      "path" => route.path,
      "runtime" => atom_label(route.runtime),
      "entry" => atom_label(route.entry),
      "ownership" => to_map(route.ownership),
      "offline" => to_map(route.offline),
      "capabilities" => to_map(route.capabilities),
      "commerce" => to_map(route.commerce),
      "companion" => to_map(route.companion),
      "auth" => to_map(route.auth),
      "notifications" => to_map(route.notifications),
      "support" => to_map(route.support),
      "rebuild" => to_map(route.rebuild),
      "denials" => to_map(route.denials),
      "conditions" => Enum.map(route.conditions, &to_map/1)
    }
  end

  def to_map(%Condition{} = condition) do
    %{
      "type" => atom_label(condition.type),
      "status" => condition_status(condition.status),
      "reason" => atom_label(condition.reason),
      "severity" => atom_label(condition.severity),
      "message" => condition.message,
      "route_id" => condition.route_id,
      "details" => to_map(condition.details)
    }
  end

  def to_map(%_struct{} = struct) do
    struct
    |> Map.from_struct()
    |> to_map()
  end

  def to_map(map) when is_map(map) do
    map
    |> Enum.map(fn {key, value} -> {to_string(key), to_map(value)} end)
    |> Enum.into(%{})
  end

  def to_map(list) when is_list(list), do: Enum.map(list, &to_map/1)
  def to_map(value) when is_boolean(value), do: value
  def to_map(value) when is_atom(value), do: atom_label(value)
  def to_map(value), do: value

  defp atom_label(nil), do: nil
  defp atom_label(value) when is_atom(value), do: Atom.to_string(value)
  defp atom_label(value), do: value

  defp condition_status(value) when value in [true, false], do: value
  defp condition_status(:unknown), do: "unknown"
  defp condition_status("unknown"), do: "unknown"
  defp condition_status(value), do: value
end
