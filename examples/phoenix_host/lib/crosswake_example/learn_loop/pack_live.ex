defmodule CrosswakeExample.LearnLoop.PackLive do
  use Phoenix.LiveView

  alias CrosswakeExample.LearnLoop
  alias CrosswakeExample.LearnLoop.Components
  alias CrosswakeExample.LearnLoop.Diagnostics
  alias CrosswakeExample.PageTitle

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: PageTitle.learn("Content Pack"),
       context: nil,
       diagnostics_rows: Diagnostics.route_policy_rows(),
       diagnostics_links: Diagnostics.guide_links()
     )}
  end

  @impl true
  def handle_params(%{"id" => pack_id}, _uri, socket) do
    context = LearnLoop.pack_context!(pack_id)

    {:noreply,
     assign(socket,
       page_title: PageTitle.learn(context.pack.title),
       context: context
     )}
  end

  @impl true
  def render(%{context: nil} = assigns) do
    ~H"""
    <Components.learnloop_shell
      page_title="LearnLoop pack"
      route_id="learnloop-pack"
      diagnostics_rows={@diagnostics_rows}
      diagnostics_links={@diagnostics_links}
      posture_badges={["LiveView route", "Cached read-only"]}
    >
      <section class="learnloop-panel">
        <h2>Pack loading</h2>
        <p>LearnLoop content-pack context is loaded by route id.</p>
      </section>
    </Components.learnloop_shell>
    """
  end

  def render(assigns) do
    ~H"""
    <Components.learnloop_shell
      page_title={@context.pack.title}
      route_id="learnloop-pack"
      pack_id={@context.pack.id}
      diagnostics_rows={@diagnostics_rows}
      diagnostics_links={@diagnostics_links}
      posture_badges={["LiveView route", "Cached read-only", "Offline island", "Local-first outbox"]}
    >
      <Components.pack_manifest
        pack={@context.pack}
        lessons={@context.lessons}
        action_path={@context.study_session.path}
      />

      <section class="learnloop-panel" aria-labelledby="learnloop-pack-posture-heading">
        <div class="learnloop-section-heading">
          <div>
            <p class="learnloop-eyebrow">Offline handoff</p>
            <h2 id="learnloop-pack-posture-heading">Cached read-only manifest</h2>
            <p>
              Pack metadata is visible here, while answers move into IndexedDB from
              {@context.study_session.path}.
            </p>
          </div>
          <Components.status_badge label="Offline island" tone={:success} />
        </div>
        <footer class="learnloop-action-footer">
          <span role="status">Local-first outbox; native storage remains future capability-map pressure.</span>
          <a class="btn-primary" href={@context.study_session.path}>Start offline study</a>
          <a class="btn-secondary" href="/learnloop/subscription">Review subscription</a>
        </footer>
      </section>

      <Components.sync_ledger items={@context.sync_ledger} />
    </Components.learnloop_shell>
    """
  end
end
