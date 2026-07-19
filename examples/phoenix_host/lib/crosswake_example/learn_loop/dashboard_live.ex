defmodule CrosswakeExample.LearnLoop.DashboardLive do
  use Phoenix.LiveView

  alias CrosswakeExample.LearnLoop
  alias CrosswakeExample.LearnLoop.Components
  alias CrosswakeExample.LearnLoop.Diagnostics
  alias CrosswakeExample.PageTitle

  @impl true
  def mount(_params, _session, socket) do
    context = LearnLoop.dashboard_context("learner-iris")

    {:ok,
     assign(socket,
       page_title: PageTitle.learn("Dashboard"),
       learner: context.learner,
       active_course: context.active_course,
       next_lesson: context.next_lesson,
       next_pack: context.next_pack,
       sync_ledger: context.sync_ledger,
       entitlement_summary: context.entitlement_summary,
       recent_server_review_events: context.recent_server_review_events,
       posture_badges: context.posture_badges,
       diagnostics_rows: Diagnostics.route_policy_rows(),
       diagnostics_links: Diagnostics.guide_links()
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Components.learnloop_shell
      page_title="Iris learner path"
      route_id="learnloop-dashboard"
      course_id={@active_course.id}
      pack_id={@next_pack.id}
      diagnostics_rows={@diagnostics_rows}
      diagnostics_links={@diagnostics_links}
      posture_badges={@posture_badges}
    >
      <Components.progress_header
        learner={@learner}
        course={@active_course}
        next_lesson={@next_lesson}
        pack={@next_pack}
      />

      <section class="learnloop-panel" aria-labelledby="learnloop-next-heading">
        <div class="learnloop-section-heading">
          <div>
            <p class="learnloop-eyebrow">Today's path</p>
            <h2 id="learnloop-next-heading">Course momentum</h2>
            <p>
              Continue {@active_course.title} through {@next_lesson.title}, then open the
              socketless study island when local review authority is needed.
            </p>
          </div>
          <Components.status_badge label="LiveView route" tone={:default} />
        </div>

        <ul class="learnloop-record-list" role="list" aria-label="LearnLoop dashboard actions">
          <li>
            <div>
              <strong>{@active_course.id}</strong>
              <p>{@active_course.subtitle}</p>
            </div>
            <a class="btn-secondary" href={"/learnloop/courses/#{@active_course.id}"}>Open course</a>
          </li>
          <li>
            <div>
              <strong>{@next_pack.id}</strong>
              <p>{@next_pack.summary}</p>
            </div>
            <a class="btn-secondary" href={"/learnloop/packs/#{@next_pack.id}"}>Inspect pack</a>
          </li>
          <li>
            <div>
              <strong>{@next_lesson.id}</strong>
              <p>Local answers belong in the browser-owned study island.</p>
            </div>
            <a class="btn-primary" href="/learnloop/study/session">Start offline study</a>
          </li>
        </ul>
      </section>

      <Components.pack_manifest pack={@next_pack} action_path="/learnloop/study/session" />

      <Components.sync_ledger items={@sync_ledger} />

      <Components.entitlement_badge summary={@entitlement_summary} />

      <section class="learnloop-panel" aria-labelledby="learnloop-recent-heading">
        <div class="learnloop-section-heading">
          <div>
            <p class="learnloop-eyebrow">Server-confirmed history</p>
            <h2 id="learnloop-recent-heading">Recent review evidence</h2>
            <p>History is cached read-only until the browser-owned outbox replays review events.</p>
          </div>
          <a class="btn-secondary" href="/learnloop/history">Open history</a>
        </div>

        <p :if={@recent_server_review_events == []} role="status">
          No server-confirmed review events yet. Complete the offline study session to create evidence.
        </p>

        <ol :if={@recent_server_review_events != []} class="learnloop-record-list">
          <li :for={event <- Enum.take(@recent_server_review_events, 3)}>
            <div>
              <strong>{event.status_label}</strong>
              <p>{event.card_id} - {event.rating}</p>
            </div>
            <Components.status_badge label="Cached read-only" tone={:cached} />
          </li>
        </ol>

        <footer class="learnloop-action-footer">
          <span role="status" aria-live="polite">Backend projection and route support stay visible below.</span>
          <a class="btn-secondary" href="/learnloop/subscription">Review subscription</a>
        </footer>
      </section>
    </Components.learnloop_shell>
    """
  end
end
