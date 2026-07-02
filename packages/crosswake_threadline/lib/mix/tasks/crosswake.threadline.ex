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

    # Load host config — including config/runtime.exs, the conventional
    # production home of :audit_repo / :audit_ledger — BEFORE reading posture.
    # Reading Application env first would report a false "Ephemeral" posture
    # for runtime.exs-configured hosts during incident triage (IN-01).
    Mix.Task.run("app.config")

    case ledger_posture() do
      :ephemeral ->
        Mix.shell().info(
          "Posture: Ephemeral — no audit ledger configured.\n" <>
            "Set :audit_repo and :audit_ledger under :crosswake in your config, then run:\n" <>
            "  mix crosswake.gen.audit"
        )

      {:durable, repo, schema} ->
        Mix.Task.run("app.start")
        events = query_events(repo, schema, thread_id, actor_ref)
        filter = cond do
          thread_id != nil -> {:thread_id, thread_id}
          actor_ref != nil -> {:actor_ref, actor_ref}
          true -> nil
        end
        render_durable(events, filter)
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

  # Extracts the tier from an event map (atom key first, then string key).
  # Returns nil when the event carries no tier at all.
  defp tier_of(event) do
    Map.get(event, :tier) || Map.get(event, "tier")
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

  # ASCII tree glyphs for NO_COLOR mode (per no-color.org: any non-nil value triggers fallback).
  # Unicode box-drawing glyphs are preferred in terminals that support them.
  # NO_COLOR aids screen-readers and CI environments that mangle Unicode.
  defp ascii_mode?, do: not is_nil(System.get_env("NO_COLOR"))

  defp glyph(:tier_last), do: if(ascii_mode?(), do: "\\--", else: "└──")
  defp glyph(:tier_mid), do: if(ascii_mode?(), do: "+--", else: "├──")
  defp glyph(:event_last), do: if(ascii_mode?(), do: "\\--", else: "└──")
  defp glyph(:event_mid), do: if(ascii_mode?(), do: "+--", else: "├──")
  defp glyph(:branch_prefix), do: if(ascii_mode?(), do: "|   ", else: "│   ")
  defp glyph(:branch_blank), do: "    "

  defp render_durable(events, filter \\ nil)

  defp render_durable([], filter) do
    Mix.shell().info("Posture: Durable — querying audit ledger")

    filter_desc =
      case filter do
        {:thread_id, id} -> "thread_id=#{id}"
        {:actor_ref, ref} -> "actor_ref=#{ref}"
        _ -> "the given filter"
      end

    Mix.shell().info("No events found for #{filter_desc}.")
  end

  defp render_durable(events, _filter) do
    Mix.shell().info("Posture: Durable — querying audit ledger")

    grouped = Enum.group_by(events, &tier_of/1)

    tiers_with_events =
      @tier_order
      |> Enum.filter(&Map.has_key?(grouped, &1))
      |> Enum.map(fn tier -> {Map.fetch!(@tier_labels, tier), Map.fetch!(grouped, tier)} end)

    # Honest append-only reconstruction must never silently drop events: any
    # event whose tier is nil, misspelled, or from a future tier vocabulary is
    # rendered in a trailing "Other" bucket instead of being omitted (IN-02).
    # Rejecting from the sorted `events` list (not the grouped map) preserves
    # chronological order across unrecognized tier values.
    other_events = Enum.reject(events, fn event -> tier_of(event) in @tier_order end)

    tiers_with_events =
      if other_events == [] do
        tiers_with_events
      else
        tiers_with_events ++ [{"Other (unrecognized tier)", other_events}]
      end

    tier_count = length(tiers_with_events)

    tiers_with_events
    |> Enum.with_index()
    |> Enum.each(fn {{label, tier_events}, tier_idx} ->
      tier_connector = if tier_idx == tier_count - 1, do: glyph(:tier_last), else: glyph(:tier_mid)
      Mix.shell().info("#{tier_connector} #{label}")

      event_count = length(tier_events)

      tier_events
      |> Enum.with_index()
      |> Enum.each(fn {event, event_idx} ->
        is_last_event = event_idx == event_count - 1
        is_last_tier = tier_idx == tier_count - 1

        branch_prefix = if is_last_tier, do: glyph(:branch_blank), else: glyph(:branch_prefix)
        event_connector = if is_last_event, do: glyph(:event_last), else: glyph(:event_mid)

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
