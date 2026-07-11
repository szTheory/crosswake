defmodule CrosswakeExample.LearnLoop.SubscriptionLive do
  use Phoenix.LiveView

  alias CrosswakeExample.LearnLoop.Components
  alias CrosswakeExample.LearnLoop.Diagnostics
  alias CrosswakeExample.LearnLoop.Entitlement
  alias CrosswakeExample.PageTitle

  @learner_id "learner-iris"
  @events %{
    "set_pending" => :pending,
    "set_stale" => :stale,
    "set_denied" => :denied,
    "set_granted" => :granted
  }

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(
       page_title: PageTitle.learn("Subscription access"),
       learner_id: @learner_id,
       visible_states: Entitlement.visible_states(),
       state_copies: Enum.map(Entitlement.visible_states(), &Entitlement.state_copy/1),
       support_rows: Entitlement.support_rows(),
       diagnostics_rows: Diagnostics.route_policy_rows(),
       diagnostics_links: Diagnostics.guide_links(),
       posture_badges: ["LiveView route", "Cached read-only", "Backend projection"]
     )
     |> assign_projection(:pending)}
  end

  @impl true
  def handle_event(event, _params, socket) when is_map_key(@events, event) do
    {:noreply, assign_projection(socket, Map.fetch!(@events, event))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Components.learnloop_shell
      page_title="LearnLoop subscription access"
      route_id="learnloop-subscription"
      diagnostics_rows={@diagnostics_rows}
      diagnostics_links={@diagnostics_links}
      posture_badges={@posture_badges}
    >
      <section class="learnloop-panel" aria-labelledby="learnloop-access-heading">
        <div class="learnloop-section-heading">
          <div>
            <p class="learnloop-eyebrow">Subscription access</p>
            <h2 id="learnloop-access-heading">LearnLoop access status</h2>
            <p>
              Backend projection owns access for gated lessons and packs; mocked storefront
              evidence only explains why a projection refresh is pending.
            </p>
          </div>
          <Components.status_badge label={state_label(@active_state)} tone={@active_state} />
        </div>

        <div
          class="learnloop-entitlement"
          role="status"
          aria-live="polite"
          data-state={@active_state}
        >
          <div>
            <p class="learnloop-eyebrow">Backend projection</p>
            <strong>{@active_copy.title}</strong>
            <span>{state_label(@active_state)}</span>
            <p>{@active_copy.body}</p>
            <p>{@active_copy.support}</p>
          </div>
          <Components.status_badge label="Backend projection" tone={:authority} />
          <Components.status_badge label="Mocked storefront evidence" tone={:warning} />
        </div>

        <div class="learnloop-action-footer" aria-label="Demo backend projection states">
          <button
            :for={state <- @visible_states}
            type="button"
            class={["btn-secondary", state == @active_state && "btn-primary"]}
            phx-click={"set_#{state}"}
          >
            Demo backend: {state}
          </button>
        </div>
      </section>

      <section class="learnloop-panel" aria-labelledby="learnloop-state-heading">
        <div class="learnloop-section-heading">
          <div>
            <p class="learnloop-eyebrow">Visible states</p>
            <h2 id="learnloop-state-heading">Backend projection states</h2>
            <p>
              Learner UI stays to granted, pending, stale, and denied while deeper commerce
              details remain diagnostic.
            </p>
          </div>
          <a class="btn-secondary" href="/learnloop/study/session">Open study island</a>
        </div>

        <ul class="learnloop-record-list" role="list">
          <li :for={copy <- @state_copies}>
            <div>
              <strong>{copy.state}</strong>
              <p>{copy.title}</p>
              <p>{copy.body}</p>
              <small>{copy.support}</small>
            </div>
            <Components.status_badge label={state_label(copy.state)} tone={copy.state} />
          </li>
        </ul>
      </section>

      <section class="learnloop-panel" aria-labelledby="learnloop-diagnostics-heading">
        <div class="learnloop-section-heading">
          <div>
            <p class="learnloop-eyebrow">Compact diagnostics</p>
            <h2 id="learnloop-diagnostics-heading">Backend projection diagnostics</h2>
            <p>
              Mock storefront evidence is visible for support, but device or storefront evidence
              never grants access by itself.
            </p>
          </div>
          <a class="btn-secondary" href="/learnloop">Back to LearnLoop</a>
        </div>

        <dl class="learnloop-manifest-grid">
          <div>
            <dt>Learner</dt>
            <dd>{@snapshot.learner_id}</dd>
          </div>
          <div>
            <dt>Authority</dt>
            <dd>Backend projection</dd>
          </div>
          <div>
            <dt>Storefront evidence</dt>
            <dd>Mock storefront evidence received</dd>
          </div>
          <div>
            <dt>Access from storefront evidence</dt>
            <dd>false</dd>
          </div>
        </dl>

        <ul class="learnloop-record-list" role="list" aria-label="Entitlement support rows">
          <li :for={row <- @support_rows}>
            <div>
              <strong>{row.label}</strong>
              <p>{row.copy}</p>
            </div>
            <Components.status_badge label={row.posture} tone={support_tone(row.posture)} />
          </li>
        </ul>
      </section>
    </Components.learnloop_shell>
    """
  end

  defp assign_projection(socket, state) do
    assign(socket,
      active_state: state,
      active_copy: Entitlement.state_copy(state),
      snapshot: Entitlement.snapshot_for(state)
    )
  end

  defp state_label(state) do
    state
    |> Atom.to_string()
    |> String.replace("_", " ")
  end

  defp support_tone(:fail_closed), do: :warning
  defp support_tone(:evidence_only), do: :authority
  defp support_tone(:pending_or_stale), do: :warning
  defp support_tone(:unsupported_live_provider), do: :danger
  defp support_tone(_posture), do: :default
end
