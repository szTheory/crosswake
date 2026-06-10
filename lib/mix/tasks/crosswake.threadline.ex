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
    schema = Application.get_env(:crosswake, :audit_ledger)

    if repo && schema do
      {:durable, repo, schema}
    else
      :ephemeral
    end
  end

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
      ~N[1970-01-01 00:00:00]
  end

  # Chronological comparator that handles both NaiveDateTime (from host schemas
  # using :inserted_at) and DateTime (from the canonical ledger template using
  # :occurred_at / :recorded_at typed :utc_datetime_usec). Using a single module
  # (e.g. NaiveDateTime) as the Enum.sort_by comparator would crash on DateTime
  # values, so we dispatch on the struct type.
  defp compare_ts(%NaiveDateTime{} = a, %NaiveDateTime{} = b),
    do: NaiveDateTime.compare(a, b)

  defp compare_ts(%DateTime{} = a, %DateTime{} = b),
    do: DateTime.compare(a, b)

  defp compare_ts(%NaiveDateTime{} = a, %DateTime{} = b) do
    a_dt = DateTime.from_naive!(a, "Etc/UTC")
    DateTime.compare(a_dt, b)
  end

  defp compare_ts(%DateTime{} = a, %NaiveDateTime{} = b) do
    b_dt = DateTime.from_naive!(b, "Etc/UTC")
    DateTime.compare(a, b_dt)
  end

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

        timestamp =
          Map.get(event, :occurred_at) ||
            Map.get(event, :inserted_at) ||
            Map.get(event, "occurred_at") ||
            Map.get(event, "inserted_at")

        timestamp_str =
          if timestamp do
            " (#{NaiveDateTime.to_string(timestamp)})"
          else
            ""
          end

        Mix.shell().info("#{branch_prefix}#{event_connector} #{event_type}#{timestamp_str}")
      end)
    end)
  end
end
