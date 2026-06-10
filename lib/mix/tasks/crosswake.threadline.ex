defmodule Mix.Tasks.Crosswake.Threadline do
  use Mix.Task

  @shortdoc "Inspects Threadline Native->Bridge->Phoenix events via text tree"

  @moduledoc """
  Presents a Native -> Bridge -> Phoenix chronological timeline visualization
  for a given `thread_id` or `actor_ref`.

  ## Usage

      mix crosswake.threadline --thread-id <id>
      mix crosswake.threadline --actor-ref <ref>

  ## Posture

  If the host application has not configured an audit repository and ledger
  (via `:audit_repo` and `:audit_ledger` under `:crosswake` config), the task
  prints:

      Posture: Ephemeral. No ledger configured.

  and exits 0. This is a valid documented state — the ledger is opt-in.

  If the host is configured with a durable ledger, the task queries the ledger
  and renders events grouped by tier (Native -> Bridge -> Phoenix) as a Unicode
  text tree.

  ## Configuration (durable posture)

      config :crosswake,
        audit_repo: MyApp.Repo,
        audit_ledger: MyApp.Audit.Ledger
  """

  @tier_order ["native", "bridge", "phoenix"]
  @tier_labels %{"native" => "Native", "bridge" => "Bridge", "phoenix" => "Phoenix"}

  # Sort sentinel for events that carry no recognizable timestamp.
  @epoch_sentinel ~N[1970-01-01 00:00:00]

  @impl Mix.Task
  def run(args) do
    {opts, _argv, _invalid} =
      OptionParser.parse(args, strict: [thread_id: :string, actor_ref: :string])

    thread_id = Keyword.get(opts, :thread_id)
    actor_ref = Keyword.get(opts, :actor_ref)

    if thread_id == nil and actor_ref == nil do
      Mix.raise("Expected either --thread-id <id> or --actor-ref <ref>")
    end

    case ledger_posture() do
      :ephemeral ->
        Mix.shell().info("Posture: Ephemeral. No ledger configured.")

      {:durable, repo, schema} ->
        Mix.Task.run("app.start")
        events = query_events(repo, schema, thread_id, actor_ref)
        render_durable(events)
    end
  end

  @doc false
  def ledger_posture do
    repo = Application.get_env(:crosswake, :audit_repo)
    schema = ledger_schema(Application.get_env(:crosswake, :audit_ledger))

    # repo.all/1 requires a queryable — only a module atom qualifies here.
    # Non-atom values (e.g. a string :schema from runtime.exs) fail closed
    # to :ephemeral rather than crashing at query time.
    if repo && is_atom(schema) && not is_nil(schema) && not is_boolean(schema) do
      {:durable, repo, schema}
    else
      :ephemeral
    end
  end

  # Normalizes the four documented :audit_ledger config shapes to a schema
  # module or nil, mirroring Crosswake.Doctor.ledger_schema/1:
  #   nil                     → nil
  #   keyword list            → Keyword.get(list, :schema)
  #   map                     → Map.get(config, :schema) || Map.get(config, "schema")
  #   bare atom (module ref)  → config itself
  #   anything else           → nil
  defp ledger_schema(nil), do: nil

  defp ledger_schema(config) when is_list(config) do
    if Keyword.keyword?(config) do
      Keyword.get(config, :schema)
    else
      nil
    end
  end

  defp ledger_schema(config) when is_map(config) do
    Map.get(config, :schema) || Map.get(config, "schema")
  end

  defp ledger_schema(config) when is_atom(config) and not is_nil(config) and not is_boolean(config) do
    config
  end

  defp ledger_schema(_config), do: nil

  # Fetches events from the host repo at runtime.
  # Ecto is not a compile-time dependency of this library — it lives in the host
  # app. After `app.start` is called, the host's Repo and Ecto are running and
  # we can invoke Repo.all/1 dynamically.
  defp query_events(repo, schema, thread_id, actor_ref) do
    all_events = repo.all(schema)

    all_events
    |> Enum.filter(fn event ->
      cond do
        thread_id != nil ->
          Map.get(event, :thread_id) == thread_id or
            Map.get(event, "thread_id") == thread_id

        actor_ref != nil ->
          Map.get(event, :actor_ref) == actor_ref or
            Map.get(event, "actor_ref") == actor_ref

        true ->
          false
      end
    end)
    |> Enum.sort_by(&timestamp_of/1, fn a, b -> compare_ts(a, b) != :gt end)
  end

  # Extracts the best available timestamp from an event map using the canonical
  # fallback chain: occurred_at (atom) → inserted_at (atom) → occurred_at (string)
  # → inserted_at (string) → epoch sentinel. Returns a NaiveDateTime or DateTime.
  defp timestamp_of(event) do
    Map.get(event, :occurred_at) ||
      Map.get(event, :inserted_at) ||
      Map.get(event, "occurred_at") ||
      Map.get(event, "inserted_at") ||
      @epoch_sentinel
  end

  # Chronological comparator that tolerates every timestamp shape an event can
  # carry: NaiveDateTime (host schemas using :inserted_at), DateTime (the
  # canonical ledger template typing :occurred_at / :recorded_at as
  # :utc_datetime_usec), ISO-8601 strings (JSON-decoded or string-keyed event
  # maps), and anything else. Coercing through to_naive/1 means the sort can
  # never crash mid-Enum.sort_by with a FunctionClauseError.
  defp compare_ts(a, b) do
    NaiveDateTime.compare(to_naive(a), to_naive(b))
  end

  # Coerces any timestamp shape to a NaiveDateTime for comparison. DateTime
  # values from the canonical ledger are UTC, so dropping the zone preserves
  # ordering. Unparseable or unknown shapes fall back to the epoch sentinel.
  defp to_naive(%NaiveDateTime{} = ts), do: ts
  defp to_naive(%DateTime{} = ts), do: DateTime.to_naive(ts)

  defp to_naive(ts) when is_binary(ts) do
    case NaiveDateTime.from_iso8601(ts) do
      {:ok, parsed} -> parsed
      _ -> @epoch_sentinel
    end
  end

  defp to_naive(_), do: @epoch_sentinel

  defp render_durable(events) do
    Mix.shell().info("Posture: Durable")

    grouped =
      Enum.group_by(events, fn event ->
        Map.get(event, :tier) || Map.get(event, "tier")
      end)

    tiers_with_events =
      @tier_order
      |> Enum.filter(&Map.has_key?(grouped, &1))
      |> Enum.map(fn tier -> {tier, Map.fetch!(grouped, tier)} end)

    tier_count = length(tiers_with_events)

    tiers_with_events
    |> Enum.with_index()
    |> Enum.each(fn {{tier, tier_events}, tier_idx} ->
      tier_connector = if tier_idx == tier_count - 1, do: "└──", else: "├──"
      label = Map.get(@tier_labels, tier, String.capitalize(tier))
      Mix.shell().info("#{tier_connector} #{label}")

      event_count = length(tier_events)

      tier_events
      |> Enum.with_index()
      |> Enum.each(fn {event, event_idx} ->
        is_last_event = event_idx == event_count - 1
        is_last_tier = tier_idx == tier_count - 1

        branch_prefix = if is_last_tier, do: "    ", else: "│   "
        event_connector = if is_last_event, do: "└──", else: "├──"

        event_type = Map.get(event, :event_type) || Map.get(event, "event_type") || "unknown"

        # Reuse the canonical fallback chain from timestamp_of/1 so the sort key
        # and the displayed timestamp can never disagree. String interpolation
        # (not NaiveDateTime.to_string/1) formats NaiveDateTime, DateTime
        # (canonical :utc_datetime_usec columns), and ISO-8601 string
        # timestamps alike without raising FunctionClauseError.
        timestamp = timestamp_of(event)

        timestamp_str =
          if timestamp == @epoch_sentinel do
            ""
          else
            " (#{timestamp})"
          end

        Mix.shell().info("#{branch_prefix}#{event_connector} #{event_type}#{timestamp_str}")
      end)
    end)
  end
end
