defmodule CrosswakeExample.LearnLoop.CourseLive do
  use Phoenix.LiveView

  alias CrosswakeExample.LearnLoop
  alias CrosswakeExample.LearnLoop.Components
  alias CrosswakeExample.LearnLoop.Diagnostics
  alias CrosswakeExample.PageTitle

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: PageTitle.learn("Course"),
       context: nil,
       diagnostics_rows: Diagnostics.route_policy_rows(),
       diagnostics_links: Diagnostics.guide_links()
     )}
  end

  @impl true
  def handle_params(%{"id" => course_id}, _uri, socket) do
    context = LearnLoop.course_context!(course_id)

    {:noreply,
     assign(socket,
       page_title: PageTitle.learn(context.course.title),
       context: context
     )}
  end

  @impl true
  def render(%{context: nil} = assigns) do
    ~H"""
    <Components.learnloop_shell
      page_title="LearnLoop course"
      route_id="learnloop-course"
      diagnostics_rows={@diagnostics_rows}
      diagnostics_links={@diagnostics_links}
      posture_badges={["LiveView route", "Cached read-only"]}
    >
      <section class="learnloop-panel">
        <h2>Course loading</h2>
        <p>LearnLoop course context is loaded by route id.</p>
      </section>
    </Components.learnloop_shell>
    """
  end

  def render(assigns) do
    ~H"""
    <Components.learnloop_shell
      page_title={@context.course.title}
      route_id="learnloop-course"
      course_id={@context.course.id}
      pack_id={@context.content_pack.id}
      diagnostics_rows={@diagnostics_rows}
      diagnostics_links={@diagnostics_links}
      posture_badges={["LiveView route", "Cached read-only", @context.course.id]}
    >
      <section class="learnloop-panel" aria-labelledby="learnloop-course-heading">
        <div class="learnloop-section-heading">
          <div>
            <p class="learnloop-eyebrow">Course detail</p>
            <h2 id="learnloop-course-heading">{@context.course.id}</h2>
            <p>{@context.course.subtitle}</p>
          </div>
          <span role="status">Cached read-only course route.</span>
        </div>

        <dl class="learnloop-manifest-grid">
          <div>
            <dt>Level</dt>
            <dd>{format_atom(@context.course.level)}</dd>
          </div>
          <div>
            <dt>Progress</dt>
            <dd>{@context.course.progress_percent}%</dd>
          </div>
          <div>
            <dt>Pack</dt>
            <dd>{@context.content_pack.id}</dd>
          </div>
        </dl>
      </section>

      <section class="learnloop-panel" aria-labelledby="learnloop-lessons-heading">
        <div class="learnloop-section-heading">
          <div>
            <p class="learnloop-eyebrow">Lesson path</p>
            <h2 id="learnloop-lessons-heading">Lessons</h2>
            <p>{@context.offline_notice}</p>
          </div>
          <Components.status_badge label="LiveView route" tone={:default} />
        </div>

        <ol class="learnloop-lesson-list" role="list" aria-label="LearnLoop lessons">
          <li :for={lesson <- @context.lessons}>
            <div>
              <strong>{lesson.id}</strong>
              <p>{lesson.title}</p>
              <p :if={lesson.gate_copy}>{lesson.gate_copy}</p>
              <p :if={lesson.access_state in [:pending, :stale]}>
                Backend projection required
              </p>
            </div>
            <Components.status_badge label={format_atom(lesson.status)} tone={status_tone(lesson.status)} />
          </li>
        </ol>
      </section>

      <Components.pack_manifest
        pack={@context.content_pack}
        lessons={Enum.take(@context.lessons, 2)}
        action_path={@context.study_session_path}
      />

      <section class="learnloop-panel" aria-labelledby="learnloop-course-actions-heading">
        <h2 id="learnloop-course-actions-heading">Study handoff</h2>
        <p>
          The course route is cached read-only. Review answers move to the socketless island
          and subscription access stays closed until backend projection refreshes.
        </p>
        <footer class="learnloop-action-footer">
          <span role="status">Backend projection required for gated lessons.</span>
          <a class="btn-primary" href={@context.study_session_path}>Start offline study</a>
          <a class="btn-secondary" href={@context.subscription_path}>Review access</a>
        </footer>
      </section>
    </Components.learnloop_shell>
    """
  end

  defp status_tone(:complete), do: :success
  defp status_tone(:next), do: :authority
  defp status_tone(:gated), do: :warning
  defp status_tone(_status), do: :default

  defp format_atom(atom) when is_atom(atom) do
    atom
    |> Atom.to_string()
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  defp format_atom(value), do: to_string(value)
end
