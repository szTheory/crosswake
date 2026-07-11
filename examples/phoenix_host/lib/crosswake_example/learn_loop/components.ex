defmodule CrosswakeExample.LearnLoop.Components do
  @moduledoc """
  LearnLoop-specific function components for the subscription learning showcase.

  These components keep the learner-facing shell, content-pack posture, sync
  ledger, entitlement copy, and diagnostics lane-local.
  """

  use Phoenix.Component

  alias CrosswakeExample.LearnLoop.Diagnostics
  alias CrosswakeExample.Showcase.Branding

  attr(:page_title, :string, required: true)
  attr(:route_id, :string, required: true)
  attr(:course_id, :string, default: "course-elixir-routing")
  attr(:pack_id, :string, default: "learnloop_daily_pack")
  attr(:diagnostics_rows, :list, default: [])
  attr(:diagnostics_links, :list, default: [])
  attr(:posture_badges, :list, default: [])
  slot(:inner_block)

  def learnloop_shell(assigns) do
    assigns =
      assigns
      |> assign(:brand, Branding.brand_for!(:learning_training))
      |> assign_new(:diagnostics_rows, fn -> Diagnostics.route_policy_rows() end)
      |> assign_new(:diagnostics_links, fn -> Diagnostics.guide_links() end)
      |> assign(:nav_items, nav_items(assigns.course_id, assigns.pack_id))

    ~H"""
    <div class={"learnloop-shell #{@brand.theme_class}"} data-route-id={@route_id}>
      <header class="learnloop-topbar" aria-label="LearnLoop workspace">
        <div class="learnloop-brand-lockup">
          <span class="learnloop-mark" aria-hidden="true">{@brand.mark}</span>
          <div class="learnloop-brand-copy">
            <p class="learnloop-category">{@brand.category}</p>
            <p class="learnloop-product">{@brand.name}</p>
            <p class="learnloop-tagline">{@brand.tagline}</p>
          </div>
        </div>

        <div class="learnloop-context-summary" aria-label="LearnLoop context">
          <span>{@brand.fixture_brief.organization}</span>
          <span>{@brand.fixture_brief.pressure}</span>
        </div>
      </header>

      <nav class="learnloop-nav" aria-label="LearnLoop routes">
        <a
          :for={item <- @nav_items}
          href={item.path}
          class={[
            "learnloop-nav-link",
            item.route_id == @route_id && "learnloop-nav-link-active"
          ]}
          aria-current={if item.route_id == @route_id, do: "page", else: nil}
        >
          {item.label}
        </a>
      </nav>

      <main class="learnloop-main" aria-labelledby="learnloop-page-title">
        <header class="learnloop-page-heading">
          <div>
            <p class="learnloop-page-kicker">{@brand.tone}</p>
            <h1 id="learnloop-page-title">{@page_title}</h1>
          </div>
          <.posture_badges badges={@posture_badges} />
        </header>

        {render_slot(@inner_block)}

        <.diagnostics_panel
          route_id={@route_id}
          rows={@diagnostics_rows}
          guide_links={@diagnostics_links}
        />
      </main>
    </div>
    """
  end

  attr(:badges, :list, default: [])

  def posture_badges(assigns) do
    ~H"""
    <div class="learnloop-posture-badges" aria-label="Route posture">
      <span :for={badge <- @badges} class={["learnloop-route-badge", badge_tone_class(badge)]}>
        {badge}
      </span>
    </div>
    """
  end

  attr(:learner, :map, required: true)
  attr(:course, :map, required: true)
  attr(:next_lesson, :map, required: true)
  attr(:pack, :map, default: nil)

  def progress_header(assigns) do
    ~H"""
    <section class="learnloop-progress-header" aria-labelledby="learnloop-progress-heading">
      <div class="learnloop-progress-copy">
        <p class="learnloop-eyebrow">{@learner.organization}</p>
        <h2 id="learnloop-progress-heading">{@learner.name}</h2>
        <p>{@learner.headline}</p>
      </div>

      <div class="learnloop-progress-meter" role="status" aria-live="polite">
        <div>
          <span>Active course</span>
          <strong>{@course.title}</strong>
          <code>{@course.id}</code>
        </div>
        <progress value={@course.progress_percent} max="100">
          {@course.progress_percent}%
        </progress>
        <small>{@course.progress_percent}% complete - next lesson: {@next_lesson.title}</small>
      </div>

      <dl class="learnloop-progress-facts">
        <div>
          <dt>Streak</dt>
          <dd>{@learner.streak_days} days</dd>
        </div>
        <div>
          <dt>Next lesson</dt>
          <dd>{@next_lesson.id}</dd>
        </div>
        <div :if={@pack}>
          <dt>Pack</dt>
          <dd>{@pack.id}</dd>
        </div>
      </dl>
    </section>
    """
  end

  attr(:label, :string, required: true)
  attr(:tone, :atom, default: :default)

  def status_badge(assigns) do
    ~H"""
    <span class={["learnloop-status-badge", status_tone_class(@tone)]}>{@label}</span>
    """
  end

  attr(:pack, :map, required: true)
  attr(:lessons, :list, default: [])
  attr(:action_path, :string, default: "/learnloop/study/session")

  def pack_manifest(assigns) do
    ~H"""
    <section class="learnloop-pack-manifest" aria-labelledby={"#{@pack.id}-manifest-heading"}>
      <div class="learnloop-section-heading">
        <div>
          <p class="learnloop-eyebrow">Content pack</p>
          <h2 id={"#{@pack.id}-manifest-heading"}>{@pack.title}</h2>
          <p>{@pack.summary}</p>
        </div>
        <.status_badge label={format_atom(@pack.status)} tone={status_tone(@pack.status)} />
      </div>

      <dl class="learnloop-manifest-grid">
        <div>
          <dt>Pack id</dt>
          <dd>{@pack.id}</dd>
        </div>
        <div>
          <dt>Version</dt>
          <dd>{@pack.version}</dd>
        </div>
        <div>
          <dt>Cards</dt>
          <dd>{@pack.card_count}</dd>
        </div>
        <div>
          <dt>Storage owner</dt>
          <dd>{storage_owner_label(@pack.storage_owner)}</dd>
        </div>
      </dl>

      <ul :if={@lessons != []} class="learnloop-lesson-list" role="list">
        <li :for={lesson <- @lessons}>
          <div>
            <strong>{lesson.title}</strong>
            <p>{lesson.id} - {format_atom(lesson.access_state)}</p>
          </div>
          <.status_badge label={format_atom(lesson.status)} tone={status_tone(lesson.status)} />
        </li>
      </ul>

      <footer class="learnloop-action-footer">
        <span role="status">IndexedDB outbox owns local review answers.</span>
        <a class="btn-primary" href={@action_path}>Start offline study</a>
      </footer>
    </section>
    """
  end

  attr(:items, :list, default: [])
  attr(:title, :string, default: "Sync ledger")

  def sync_ledger(assigns) do
    ~H"""
    <section class="learnloop-sync-ledger" aria-labelledby="learnloop-sync-heading">
      <div class="learnloop-section-heading">
        <div>
          <p class="learnloop-eyebrow">Reconciliation visibility</p>
          <h2 id="learnloop-sync-heading">{@title}</h2>
          <p>Review evidence stays route-local and append-only; no broad sync product is implied.</p>
        </div>
        <span role="status" aria-live="polite">Synced rows and queued rows stay visible.</span>
      </div>

      <ol>
        <li :for={item <- @items}>
          <div>
            <strong>{item.label}</strong>
            <p>{ledger_copy(item.copy)}</p>
          </div>
          <.status_badge label={status_label(item.status)} tone={status_tone(item.status)} />
        </li>
      </ol>
    </section>
    """
  end

  attr(:summary, :map, required: true)
  attr(:authority_label, :string, default: "Backend projection required")

  def entitlement_badge(assigns) do
    ~H"""
    <section class="learnloop-entitlement" role="status" aria-live="polite">
      <div>
        <p class="learnloop-eyebrow">Subscription access</p>
        <strong>{@authority_label}</strong>
        <span>{@summary.label}</span>
        <p>{@summary.access_copy}</p>
      </div>
      <.status_badge label="Backend projection" tone={:authority} />
      <.status_badge label="Mocked storefront evidence" tone={:warning} />
    </section>
    """
  end

  attr(:route_id, :string, required: true)
  attr(:rows, :list, default: [])
  attr(:guide_links, :list, default: [])

  def diagnostics_panel(assigns) do
    assigns =
      assigns
      |> assign_new(:rows, fn -> Diagnostics.route_policy_rows() end)
      |> assign_new(:guide_links, fn -> Diagnostics.guide_links() end)

    ~H"""
    <details class="learnloop-diagnostics" data-route-id={@route_id}>
      <summary>
        <span>Route policy diagnostics</span>
        <small>LearnLoop routes only</small>
      </summary>

      <div class="learnloop-diagnostics-body">
        <div class="learnloop-diagnostics-table" role="table" aria-label="LearnLoop route policy rows">
          <div class="learnloop-diagnostics-row learnloop-diagnostics-row-head" role="row">
            <span role="columnheader">Route</span>
            <span role="columnheader">Owner</span>
            <span role="columnheader">Offline</span>
            <span role="columnheader">Support truth</span>
          </div>

          <div
            :for={row <- @rows}
            class={[
              "learnloop-diagnostics-row",
              row.route_id == @route_id && "learnloop-diagnostics-row-current"
            ]}
            role="row"
          >
            <span role="cell">
              <strong>{row.route_id}</strong>
              <code>{row.path}</code>
            </span>
            <span role="cell">{row.runtime_owner_label}</span>
            <span role="cell">{row.offline_posture_label}</span>
            <span role="cell">
              <strong>{row.support_label}</strong><br />
              <small>{row.rough_edge}</small><br />
              <small>{list_text(row.visible_labels)}</small><br />
              <small>{list_text(row.pack_labels)}</small>
            </span>
          </div>
        </div>

        <div class="learnloop-diagnostics-links" aria-label="LearnLoop support references">
          <a :for={link <- @guide_links} href={"/#{link.path}"}>{link.label}</a>
        </div>
      </div>
    </details>
    """
  end

  defp nav_items(course_id, pack_id) do
    [
      %{label: "Dashboard", path: "/learnloop", route_id: "learnloop-dashboard"},
      %{label: "Course", path: "/learnloop/courses/#{course_id}", route_id: "learnloop-course"},
      %{label: "Pack", path: "/learnloop/packs/#{pack_id}", route_id: "learnloop-pack"},
      %{label: "Study", path: "/learnloop/study/session", route_id: "learnloop-study-session"},
      %{label: "History", path: "/learnloop/history", route_id: "learnloop-history"},
      %{label: "Subscription", path: "/learnloop/subscription", route_id: "learnloop-subscription"}
    ]
  end

  defp badge_tone_class(label) do
    label = to_string(label)

    cond do
      String.contains?(label, "Offline") or String.contains?(label, "outbox") ->
        "learnloop-route-badge-offline"

      String.contains?(label, "Backend") or String.contains?(label, "storefront") ->
        "learnloop-route-badge-authority"

      String.contains?(label, "Cached") ->
        "learnloop-route-badge-cached"

      String.contains?(label, "LiveView") ->
        "learnloop-route-badge-liveview"

      true ->
        "learnloop-route-badge-default"
    end
  end

  defp status_tone(:active), do: :success
  defp status_tone(:available), do: :success
  defp status_tone(:complete), do: :success
  defp status_tone(:granted), do: :success
  defp status_tone(:offline_ready), do: :success
  defp status_tone(:next), do: :authority
  defp status_tone(:server_confirmed), do: :success
  defp status_tone(:saved_locally), do: :local
  defp status_tone(:queued_for_replay), do: :warning
  defp status_tone(:pending), do: :warning
  defp status_tone(:stale), do: :warning
  defp status_tone(:cached_read_only), do: :cached
  defp status_tone(:blocked_by_backend_projection), do: :warning
  defp status_tone(:gated), do: :warning
  defp status_tone(:server_rejected), do: :danger
  defp status_tone(_status), do: :default

  defp status_tone_class(:authority), do: "learnloop-status-badge-authority"
  defp status_tone_class(:cached), do: "learnloop-status-badge-cached"
  defp status_tone_class(:danger), do: "learnloop-status-badge-danger"
  defp status_tone_class(:local), do: "learnloop-status-badge-local"
  defp status_tone_class(:success), do: "learnloop-status-badge-success"
  defp status_tone_class(:warning), do: "learnloop-status-badge-warning"
  defp status_tone_class(_tone), do: "learnloop-status-badge-default"

  defp status_label(:server_confirmed), do: "Server confirmed"
  defp status_label(status), do: format_atom(status)

  defp storage_owner_label(:browser_indexed_db), do: "IndexedDB"
  defp storage_owner_label(:server_snapshot), do: "Server snapshot"
  defp storage_owner_label(owner), do: format_atom(owner)

  defp ledger_copy(copy) when is_binary(copy) do
    String.replace(copy, "not a generic sync engine", "route-local reconciliation evidence")
  end

  defp ledger_copy(copy), do: copy

  defp format_atom(nil), do: "Not declared"

  defp format_atom(atom) when is_atom(atom) do
    atom
    |> Atom.to_string()
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  defp format_atom(value), do: to_string(value)

  defp list_text(nil), do: "Not declared"
  defp list_text([]), do: "Not declared"
  defp list_text(values), do: Enum.join(values, ", ")
end
