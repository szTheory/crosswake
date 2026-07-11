defmodule CrosswakeExample.LearnLoop.HistoryLive do
  use Phoenix.LiveView

  alias CrosswakeExample.LearnLoop
  alias CrosswakeExample.LearnLoop.Components
  alias CrosswakeExample.LearnLoop.Diagnostics
  alias CrosswakeExample.LearnLoop.Fixtures
  alias CrosswakeExample.PageTitle

  @impl true
  def mount(_params, _session, socket) do
    context = LearnLoop.history_context()

    {:ok,
     assign(socket,
       page_title: PageTitle.learn("History"),
       context: context,
       sync_ledger: Fixtures.sync_ledger_preview(),
       diagnostics_rows: Diagnostics.route_policy_rows(),
       diagnostics_links: Diagnostics.guide_links()
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Components.learnloop_shell
      page_title="Study History"
      route_id="learnloop-history"
      diagnostics_rows={@diagnostics_rows}
      diagnostics_links={@diagnostics_links}
      posture_badges={["LiveView route", "Cached read-only", "Backend projection"]}
    >
      <section class="learnloop-panel" aria-labelledby="learnloop-history-heading">
        <div class="learnloop-section-heading">
          <div>
            <p class="learnloop-eyebrow">Server-confirmed evidence</p>
            <h2 id="learnloop-history-heading">History</h2>
            <p>{@context.sync_copy}</p>
          </div>
          <Components.status_badge label="Cached read-only" tone={:cached} />
        </div>

        <p role="status" aria-live="polite">
          This route shows {@context.notice}; review answers are created in the offline study island.
        </p>

        <div :if={@context.events == []} class="learnloop-panel" role="status">
          <h2>No server-confirmed reviews yet</h2>
          <p>
            Complete the offline study session to create review evidence. Server reset only resets
            server-side rows; browser-owned queues are handled by browser proof helpers.
          </p>
          <a class="btn-primary" href="/learnloop/study/session">Start offline study</a>
        </div>

        <ol :if={@context.events != []} class="learnloop-record-list" aria-label="Server-confirmed review events">
          <li :for={event <- @context.events}>
            <div>
              <strong>{event.status_label}</strong>
              <p>{event.card_id} - {event.rating}</p>
              <small>{event.client_mutation_id}</small>
            </div>
            <Components.status_badge label={format_atom(event.status)} tone={status_tone(event.status)} />
          </li>
        </ol>
      </section>

      <section class="learnloop-panel" aria-labelledby="learnloop-progress-checkpoints-heading">
        <div class="learnloop-section-heading">
          <div>
            <p class="learnloop-eyebrow">Progress projection</p>
            <h2 id="learnloop-progress-checkpoints-heading">Checkpoints</h2>
            <p>Progress rows distinguish server-confirmed evidence from queued replay posture.</p>
          </div>
          <a class="btn-secondary" href="/learnloop">Back to dashboard</a>
        </div>

        <ol class="learnloop-record-list" aria-label="LearnLoop progress checkpoints">
          <li :for={checkpoint <- @context.progress_checkpoints}>
            <div>
              <strong>{checkpoint.label}</strong>
              <p>{checkpoint.id} - {checkpoint.route_id}</p>
            </div>
            <Components.status_badge
              label={format_atom(checkpoint.status)}
              tone={status_tone(checkpoint.status)}
            />
          </li>
        </ol>

        <footer class="learnloop-action-footer">
          <span role="status">Synced history remains read-only evidence.</span>
          <a class="btn-primary" href="/learnloop/study/session">Open study session</a>
        </footer>
      </section>

      <Components.sync_ledger items={@sync_ledger} />
    </Components.learnloop_shell>
    """
  end

  defp status_tone(:server_confirmed), do: :success
  defp status_tone(:queued_for_replay), do: :warning
  defp status_tone(:blocked_by_backend_projection), do: :warning
  defp status_tone(:synced), do: :success
  defp status_tone(_status), do: :default

  defp format_atom(atom) when is_atom(atom) do
    atom
    |> Atom.to_string()
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  defp format_atom(value), do: to_string(value)
end
