defmodule CrosswakeExample.SaaSPortal.ApprovalLive do
  use Phoenix.LiveView

  alias Crosswake.Bridge
  alias CrosswakeExample.Crosswake.Policy
  alias CrosswakeExample.Layouts
  alias CrosswakeExample.PageTitle
  alias CrosswakeExample.SaaSPortal.Approvals
  alias CrosswakeExample.SaaSPortal.Components
  alias CrosswakeExample.SaaSPortal.Diagnostics
  alias CrosswakeExampleWeb.CrosswakeFallbacks

  @bridge_route_id "saas-approval"

  # The capability family as this route DECLARES it in router policy. The wire command
  # it resolves to (`haptics.impact`) is the library's business, never restated here —
  # restating it is how a hand-built envelope drifts from the manifest.
  @haptics_family "haptics"
  @haptics_ref :approval_haptics

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(
        page_title: PageTitle.admin("Approval Detail"),
        approval: nil,
        activity_events: [],
        approval_notice: nil,
        approval_error: nil,
        bridge_dispatch: nil,
        bridge_reply: nil,
        crosswake_manifest: Policy.manifest(),
        crosswake_route_id: @bridge_route_id,
        diagnostics_rows: Diagnostics.route_policy_rows(),
        diagnostics_links: Diagnostics.guide_links(),
        confirm_open: false,
        confirm_demo_notice: nil,
        confirm_error: nil
      )
      |> Bridge.attach()

    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => approval_id}, _uri, socket) do
    approval = Approvals.get_approval!(approval_scope(socket), approval_id)

    {:noreply,
     assign(socket,
       approval: approval,
       activity_events: activity_for_display(approval.id),
       page_title: PageTitle.admin(approval.title)
     )}
  end

  @impl true
  def handle_event("approve", _params, socket) do
    approval = socket.assigns.approval

    case Approvals.approve_approval(approval_scope(socket), approval.id, %{
           haptics: "post_success_optional"
         }) do
      {:ok, approved} ->
        # Phase 149 D-07/D-12 hold unchanged: the dispatch happens INSIDE the committed
        # branch, after the AdminPilot context has already recorded the decision, and it
        # is confirmation only. What changed is that the shell's answer — including a
        # refusal — is now rendered instead of merely implied.
        socket =
          socket
          |> assign(
            approval: approved,
            activity_events: activity_for_display(approved.id),
            approval_notice:
              "Phoenix recorded the decision for #{approved.title}. Haptics is optional confirmation only.",
            approval_error: nil,
            bridge_reply: nil
          )
          |> Bridge.push(@haptics_family, ref: @haptics_ref, payload: %{"style" => "light"})

        {:noreply, assign(socket, bridge_dispatch: Bridge.dispatched(socket, @haptics_ref))}

      {:error, :forbidden} ->
        {:noreply,
         assign(socket,
           approval_notice: nil,
           approval_error:
             "Approver role required. Phoenix kept the request unchanged at the server boundary.",
           bridge_dispatch: nil,
           bridge_reply: nil
         )}
    end
  end

  # ---------------------------------------------------------------------------
  # Native-controls fallback (Phase 155 FALL-01/PROOF-01) — a generated,
  # host-owned confirm modal. This is additive: it demonstrates the generated
  # confirm_modal/1 on its own trigger and does not alter the "approve"
  # handle_event above, which Phase 154's evidence-panel proof is pinned to.
  # ---------------------------------------------------------------------------

  def handle_event("open_confirm_demo", _params, socket) do
    {:noreply, assign(socket, confirm_open: true, confirm_demo_notice: nil, confirm_error: nil)}
  end

  def handle_event("crosswake_fallback_answer", %{"answer" => "confirm"}, socket) do
    {:noreply,
     assign(socket,
       confirm_open: false,
       confirm_demo_notice: "Approved. The requester was notified.",
       confirm_error: nil
     )}
  end

  def handle_event("crosswake_fallback_dismiss", _params, socket) do
    {:noreply, assign(socket, confirm_open: false)}
  end

  def handle_event("crosswake_fallback_answer", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_info({:crosswake_bridge, @haptics_ref, %Bridge.Reply{} = reply}, socket) do
    {:noreply, assign(socket, bridge_reply: reply)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Components.admin_shell
      page_title={if @approval, do: @approval.title, else: "Approval detail"}
      route_id="saas-approval"
      current_saas_account={@current_saas_account}
      current_saas_user={@current_saas_user}
      posture_badges={["LiveView route", "Cached read-only", "Server authority", "haptics.impact"]}
    >
      <section :if={@approval} class="adminpilot-panel" aria-labelledby="approval-detail-heading">
        <div class="adminpilot-section-heading">
          <div>
            <h2 id="approval-detail-heading">Server-authoritative decision</h2>
            <p>
              Phoenix owns this approval mutation through the AdminPilot context. Optional haptics
              can confirm success after the server records the decision.
            </p>
          </div>
          <Components.status_badge label={status_label(@approval.status)} tone={status_tone(@approval.status)} />
        </div>

        <dl>
          <dt>Status</dt>
          <dd>{status_label(@approval.status)}</dd>
          <dt>Requested by</dt>
          <dd>{@approval.requested_by}</dd>
          <dt>Reviewer</dt>
          <dd>{@approval.reviewed_by || "Pending server review"}</dd>
          <dt>Policy</dt>
          <dd>{@approval.policy_id}</dd>
          <dt>Support ref</dt>
          <dd>{@approval.support_ref}</dd>
        </dl>
      </section>

      <section :if={@approval} class="adminpilot-panel">
        <h2>Action footer</h2>
        <p>
          Server authority is required before any shell confirmation. The success message remains
          visible even when no bridge object is present in the browser.
        </p>

        <p :if={@approval_notice} role="status">
          <strong>{@approval_notice}</strong>
        </p>
        <p :if={@approval_error} role="alert">
          <strong>{@approval_error}</strong>
        </p>

        <button
          :if={@approval.status == :pending}
          class="btn-primary"
          type="button"
          phx-click="approve"
          phx-disable-with="Approving through Phoenix..."
        >
          Approve request
        </button>

        <p :if={@approval.status == :approved} role="status">
          Phoenix recorded the decision. Optional haptics can only acknowledge this completed
          server action.
        </p>
      </section>

      <section :if={@approval} class="adminpilot-panel">
        <h2>Activity trail</h2>
        <Components.activity_feed activities={@activity_events} />
      </section>

      <section
        :if={@approval}
        class="adminpilot-panel"
        id="haptics-evidence"
        data-cw-envelope={Jason.encode!(haptics_evidence(@bridge_dispatch, @bridge_reply))}
      >
        <h2>Optional haptics</h2>
        <p>
          The route declares <code>haptics</code> as a bounded, low-frequency confirmation.
          Approval success does not depend on <code>window.webkit</code> or
          <code>window.crosswakeBridge</code>.
        </p>

        <p :if={@bridge_dispatch == nil}>
          No haptics request sent. Phoenix sends one only after an approval commits.
        </p>

        <dl :if={@bridge_dispatch}>
          <dt>Capability (route policy)</dt>
          <dd>{@bridge_dispatch["capability"]}</dd>
          <dt>Command (wire protocol)</dt>
          <dd>{@bridge_dispatch["command"]}</dd>
          <dt>Route</dt>
          <dd>{@bridge_dispatch["route_id"]}</dd>
          <dt>Impact style</dt>
          <dd>{get_in(@bridge_dispatch, ["payload", "style"])}</dd>
        </dl>

        <p :if={@bridge_dispatch} id="haptics-reply" role="status" aria-live="polite" aria-atomic="true">
          <strong>{reply_verdict(@bridge_reply)}</strong>
          {reply_detail(@bridge_reply)}
        </p>
      </section>

      <section :if={@approval} class="adminpilot-panel" id="native-controls-fallback">
        <h2>Native controls fallback</h2>
        <p>
          Crosswake has no native alert/confirm bridge command. This generated, host-owned
          confirm modal (<code>mix crosswake.gen.native_controls_ui</code>) is the permanent
          surface for that job on every platform.
        </p>

        <button type="button" class="btn-secondary" phx-click="open_confirm_demo">
          Preview the confirm fallback
        </button>

        <p :if={@confirm_demo_notice} role="status">
          <strong>{@confirm_demo_notice}</strong>
        </p>

        <CrosswakeFallbacks.confirm_modal
          id="native-controls-confirm-demo"
          open={@confirm_open}
          title="Approve this request?"
          body="The requester is notified and the decision is recorded."
          confirm_label="Approve request"
          error={@confirm_error}
        />
      </section>

      <Components.diagnostics_panel
        route_id="saas-approval"
        rows={@diagnostics_rows}
        guide_links={@diagnostics_links}
      />

      <Layouts.crosswake_bridge />
    </Components.admin_shell>
    """
  end

  defp approval_scope(socket) do
    %{
      user: socket.assigns.current_saas_user,
      account: socket.assigns.current_saas_account,
      route_id: @bridge_route_id
    }
  end

  defp activity_for_display(approval_id) do
    approval_id
    |> Approvals.activity_for_approval()
    |> Enum.map(fn event -> Map.put_new(event, :summary, activity_summary(event)) end)
  end

  defp activity_summary(%{event_type: :approval_approved, actor_id: actor_id}) do
    "Approved by #{actor_id} through Phoenix server authority."
  end

  defp activity_summary(%{event_type: :approval_seeded, actor_id: actor_id}) do
    "Seeded as deterministic AdminPilot evidence for #{actor_id}."
  end

  defp activity_summary(%{event_type: event_type, actor_id: actor_id}) do
    "#{event_type} by #{actor_id}."
  end

  defp status_label(:pending), do: "Pending review"
  defp status_label(:approved), do: "Approved"
  defp status_label(status), do: status |> to_string() |> String.capitalize()

  defp status_tone(:pending), do: :warning
  defp status_tone(:approved), do: :success
  defp status_tone(_status), do: :default

  # The machine-readable half of the panel (D-74). Every value is projected out of the
  # envelope Crosswake.Bridge.push/3 actually built — nothing is restated — so CI reads
  # one attribute and parses it once, and the human-readable <dl> above stays free to
  # change without breaking the browser lane.
  #
  # Deliberately curated rather than a raw dump (D-68, T-154-30): four semantic fields
  # plus the verdict, and no correlation-internal state. The correlation id stays
  # library-internal (D-20); adopters correlate with their own opaque `ref:`.
  defp haptics_evidence(nil, _reply) do
    %{"capability" => nil, "command" => nil, "route_id" => nil, "style" => nil, "reply" => nil}
  end

  defp haptics_evidence(dispatch, reply) do
    %{
      "capability" => dispatch["capability"],
      "command" => dispatch["command"],
      "route_id" => dispatch["route_id"],
      "style" => get_in(dispatch, ["payload", "style"]),
      "reply" => reply_evidence(reply)
    }
  end

  defp reply_evidence(nil), do: nil
  defp reply_evidence(%Bridge.Reply{status: :ok}), do: %{"status" => "ok", "reason" => nil}

  defp reply_evidence(%Bridge.Reply{status: :deny, denial: denial}) do
    %{"status" => "deny", "reason" => denial && to_string(denial.reason)}
  end

  defp reply_verdict(nil), do: "Waiting for the shell."
  defp reply_verdict(%Bridge.Reply{status: :ok}), do: "Shell confirmed."

  defp reply_verdict(%Bridge.Reply{status: :deny, denial: denial}) do
    "Shell declined — #{denial.reason}."
  end

  defp reply_detail(nil) do
    "Phoenix dispatched the request and armed a deadline. A typed reply always arrives, " <>
      "even when nothing is listening."
  end

  defp reply_detail(%Bridge.Reply{status: :ok}) do
    "The device produced the tap. Phoenix had already recorded the decision before this reply arrived."
  end

  # The default desktop experience, and the strongest thing this route demonstrates: a
  # browser has no shell, so there is no honest way to produce a physical tap.
  defp reply_detail(%Bridge.Reply{status: :deny, denial: %{reason: :shell_unreachable}}) do
    "There is no browser substitute for a physical tap, so Crosswake does nothing rather " <>
      "than fake one. The approval stands."
  end

  defp reply_detail(%Bridge.Reply{status: :deny, denial: denial}) do
    "#{denial.message} The approval stands."
  end
end
