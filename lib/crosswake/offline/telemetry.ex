defmodule Crosswake.Offline.Telemetry do
  @moduledoc """
  Stable telemetry metadata contract for offline transitions and outcomes.
  """

  @metadata_keys [
    :route_id,
    :runtime,
    :offline_mode,
    :sync_seam,
    :journal_entry_id,
    :manifest_version,
    :native_runtime_version,
    :correlation_id,
    :terminal_outcome
  ]
  @terminal_outcomes [:accepted, :rejected, :conflict]

  defmodule Event do
    @moduledoc false

    @enforce_keys [
      :name,
      :route_id,
      :runtime,
      :offline_mode,
      :sync_seam,
      :manifest_version,
      :native_runtime_version,
      :correlation_id
    ]
    defstruct [
      :name,
      :route_id,
      :runtime,
      :offline_mode,
      :sync_seam,
      :journal_entry_id,
      :manifest_version,
      :native_runtime_version,
      :correlation_id,
      :terminal_outcome
    ]

    @type name :: :status_transition | :terminal_outcome

    @type t :: %__MODULE__{
            name: name(),
            route_id: String.t(),
            runtime: atom(),
            offline_mode: atom(),
            sync_seam: String.t() | nil,
            journal_entry_id: String.t() | nil,
            manifest_version: String.t(),
            native_runtime_version: String.t(),
            correlation_id: String.t(),
            terminal_outcome: :accepted | :rejected | :conflict | nil
          }
  end

  @spec metadata_keys() :: [atom()]
  def metadata_keys, do: @metadata_keys

  @spec terminal_outcomes() :: [atom()]
  def terminal_outcomes, do: @terminal_outcomes

  @spec new_event(keyword()) :: Event.t()
  def new_event(attrs) when is_list(attrs) do
    struct!(Event, %{
      name: Keyword.fetch!(attrs, :name),
      route_id: Keyword.fetch!(attrs, :route_id),
      runtime: Keyword.fetch!(attrs, :runtime),
      offline_mode: Keyword.fetch!(attrs, :offline_mode),
      sync_seam: Keyword.get(attrs, :sync_seam),
      journal_entry_id: Keyword.get(attrs, :journal_entry_id),
      manifest_version: Keyword.fetch!(attrs, :manifest_version),
      native_runtime_version: Keyword.fetch!(attrs, :native_runtime_version),
      correlation_id: Keyword.fetch!(attrs, :correlation_id),
      terminal_outcome: Keyword.get(attrs, :terminal_outcome)
    })
  end

  @spec to_map(Event.t()) :: map()
  def to_map(%Event{} = event) do
    %{
      "name" => Atom.to_string(event.name),
      "route_id" => event.route_id,
      "runtime" => Atom.to_string(event.runtime),
      "offline_mode" => Atom.to_string(event.offline_mode),
      "sync_seam" => event.sync_seam,
      "journal_entry_id" => event.journal_entry_id,
      "manifest_version" => event.manifest_version,
      "native_runtime_version" => event.native_runtime_version,
      "correlation_id" => event.correlation_id,
      "terminal_outcome" => event.terminal_outcome && Atom.to_string(event.terminal_outcome)
    }
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end
end
