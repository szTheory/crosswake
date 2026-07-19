# Phase 150: Field-Service Showcase - Pattern Map

**Mapped:** 2026-07-11
**Files analyzed:** 35 new/modified files
**Analogs found:** 35 / 35

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `examples/phoenix_host/lib/crosswake_example/field_service/fixtures.ex` | utility | batch + transform | `examples/phoenix_host/lib/crosswake_example/saas_portal/fixtures.ex` | exact |
| `examples/phoenix_host/lib/crosswake_example/field_service/jobs.ex` | service | request-response + transform | `examples/phoenix_host/lib/crosswake_example/saas_portal/accounts.ex` | exact |
| `examples/phoenix_host/lib/crosswake_example/field_service/evidence.ex` | service | CRUD + event-driven | `examples/phoenix_host/lib/crosswake_example/saas_portal/approvals.ex` | exact |
| `examples/phoenix_host/lib/crosswake_example/field_service/evidence_event.ex` | model | CRUD + event-driven | `examples/phoenix_host/lib/crosswake_example/saas_portal/approval_activity_event.ex` | role-match |
| `examples/phoenix_host/lib/crosswake_example/field_service/technician_job_state.ex` | model | CRUD | `examples/phoenix_host/lib/crosswake_example/saas_portal/approval.ex` | role-match |
| `examples/phoenix_host/priv/repo/migrations/*_create_field_service_evidence_events.exs` | migration | batch | `examples/phoenix_host/priv/repo/migrations/20260710000000_create_saas_admin_approvals_and_activity_events.exs` | exact |
| `examples/phoenix_host/lib/crosswake_example/field_service/diagnostics.ex` | utility | request-response + transform | `examples/phoenix_host/lib/crosswake_example/saas_portal/diagnostics.ex` | exact |
| `examples/phoenix_host/lib/crosswake_example/field_service/components.ex` | component | request-response + transform | `examples/phoenix_host/lib/crosswake_example/saas_portal/components.ex` | exact |
| `examples/phoenix_host/lib/crosswake_example/field_service/jobs_live.ex` | route | request-response | `examples/phoenix_host/lib/crosswake_example/saas_portal/dashboard_live.ex` | role-match |
| `examples/phoenix_host/lib/crosswake_example/field_service/job_live.ex` | route | request-response | `examples/phoenix_host/lib/crosswake_example/saas_portal/dashboard_live.ex` | role-match |
| `examples/phoenix_host/lib/crosswake_example/field_service/inspection_live.ex` | route | request-response + event-driven | `examples/phoenix_host/lib/crosswake_example/saas_portal/approval_live.ex` | role-match |
| `examples/phoenix_host/lib/crosswake_example/field_service/capture_live.ex` | route | request-response + native handoff | `examples/phoenix_host/lib/crosswake_example/selective_native/claim_capture_live.ex` | exact |
| `examples/phoenix_host/lib/crosswake_example/field_service/evidence_review_live.ex` | route | request-response + event-driven | `examples/phoenix_host/lib/crosswake_example/media/media_lane_live.ex` | role-match |
| `examples/phoenix_host/lib/crosswake_example/router.ex` | route config | request-response | existing `/saas` and `/native` scopes in same file | exact |
| `examples/phoenix_host/lib/crosswake_example/showcase/catalog.ex` | config | transform | existing Field Service card in same file | exact |
| `examples/phoenix_host/lib/crosswake_example/showcase/fixtures.ex` | utility | batch + transform | existing SaaS reset delegate in same file | exact |
| `examples/phoenix_host/lib/crosswake_example/showcase/reset.ex` | utility | batch | existing reset orchestrator in same file | exact |
| `examples/phoenix_host/lib/crosswake_example/showcase/hub_live.ex` | route | request-response | existing lane card rendering in same file | exact |
| `examples/phoenix_host/priv/static/css/app.css` | config | transform | scoped `.adminpilot-*` CSS block | exact |
| `examples/phoenix_host/test/crosswake_example/field_service/fixtures_test.exs` | test | batch + transform | `examples/phoenix_host/test/crosswake_example/saas_portal/fixtures_test.exs` | exact |
| `examples/phoenix_host/test/crosswake_example/field_service/jobs_test.exs` | test | request-response | `examples/phoenix_host/test/crosswake_example/saas_portal/fixtures_test.exs` | role-match |
| `examples/phoenix_host/test/crosswake_example/field_service/evidence_test.exs` | test | CRUD + event-driven | `examples/phoenix_host/test/crosswake_example/saas_portal/approvals_test.exs` | exact |
| `examples/phoenix_host/test/crosswake_example/field_service/diagnostics_test.exs` | test | request-response + transform | `examples/phoenix_host/test/crosswake_example/saas_portal/diagnostics_test.exs` | exact |
| `examples/phoenix_host/test/crosswake_example/field_service/components_test.exs` | test | transform | `examples/phoenix_host/test/crosswake_example/saas_portal/components_test.exs` | exact |
| `examples/phoenix_host/test/crosswake_example/field_service/jobs_live_test.exs` | test | request-response | `examples/phoenix_host/test/crosswake_example/saas_portal/approvals_live_test.exs` | role-match |
| `examples/phoenix_host/test/crosswake_example/field_service/job_live_test.exs` | test | request-response | `examples/phoenix_host/test/crosswake_example/saas_portal/approvals_live_test.exs` | role-match |
| `examples/phoenix_host/test/crosswake_example/field_service/inspection_live_test.exs` | test | request-response + event-driven | `examples/phoenix_host/test/crosswake_example/saas_portal/approvals_live_test.exs` | exact |
| `examples/phoenix_host/test/crosswake_example/field_service/capture_live_test.exs` | test | request-response + native handoff | `examples/phoenix_host/test/crosswake_example/selective_native/claim_capture_live_test.exs` | role-match |
| `examples/phoenix_host/test/crosswake_example/field_service/evidence_review_live_test.exs` | test | request-response + event-driven | `examples/phoenix_host/test/crosswake_example/saas_portal/approvals_live_test.exs` | role-match |
| `examples/phoenix_host/test/crosswake_example/showcase/catalog_test.exs` | test | transform | existing catalog drift tests in same file | exact |
| `examples/phoenix_host/test/crosswake_example/showcase/reset_test.exs` | test | batch | existing reset idempotency tests in same file | exact |
| `examples/phoenix_host/test/crosswake_example/showcase/hub_live_test.exs` | test | request-response | `examples/phoenix_host/test/crosswake_example/showcase/hub_live_test.exs` | exact |
| `examples/phoenix_host/test/crosswake_example/e2e/showcase_reset_controller_test.exs` | test | request-response + batch | existing reset controller tests in same file | exact |
| `examples/phoenix_host/e2e/route_tour.spec.ts` | test | browser request-response + event-driven | existing AdminPilot/native route-tour helpers in same file | exact |
| `examples/phoenix_host/e2e/support/evidence_manifest.ts` | utility | file-I/O + transform | existing route-tour manifest writer in same file | exact |

## Pattern Assignments

### `examples/phoenix_host/lib/crosswake_example/field_service/fixtures.ex` (utility, batch + transform)

**Analog:** `examples/phoenix_host/lib/crosswake_example/saas_portal/fixtures.ex`

**Imports/module pattern** (lines 1-4):
```elixir
defmodule CrosswakeExample.SaaSPortal.Fixtures do
  @moduledoc """
  Deterministic AdminPilot fixtures for the SaaS/admin showcase lane.
  """
```

**Static breadth pattern** (lines 6-15, 86-120):
```elixir
@account %{
  id: "acct-north",
  name: "Northwind Workspace",
  health: :steady,
  renewal_window: "14 days",
  open_approvals: 2,
  plan: "Enterprise",
  region: "US East",
  support_ref: "support:acct-north"
}

@approvals [
  %{
    id: "approval-1",
    account_id: @account.id,
    title: "Quarterly spend increase",
    status: :pending,
    requested_by: "member-1",
    reviewed_by: nil,
    amount: "$42,000",
    policy_id: "policy-spend",
    route_id: "saas-approval"
  }
]
```

**Seed/read API pattern** (lines 219-244):
```elixir
def seed do
  %{
    account: @account,
    teams: @team,
    users: @users,
    roles: @roles,
    settings: @settings,
    approvals: @approvals,
    operational_records: @operational_records,
    approval_policies: @approval_policies,
    activity_events: @activity_events,
    admin_pressure: @admin_pressure
  }
end

def account, do: @account
def team, do: @team
def teams, do: @team
def users, do: @users
def roles, do: @roles
```

**Digest pattern** (lines 246-261):
```elixir
def digest_components do
  [
    digest_component(:account, @account),
    Enum.map(@team, &digest_component(:team, &1)),
    Enum.map(@users, &digest_component(:user, &1)),
    Enum.map(@roles, &digest_component(:role, &1)),
    digest_component(:settings, @settings),
    Enum.map(@approvals, &digest_component(:approval, &1)),
    Enum.map(@operational_records, &digest_component(:operational_record, &1)),
    Enum.map(@approval_policies, &digest_component(:approval_policy, &1)),
    Enum.map(@activity_events, &digest_component(:activity_event, &1)),
    digest_component(:admin_pressure, @admin_pressure)
  ]
  |> List.flatten()
  |> Enum.sort()
end
```

**Apply to Fieldserv:** create deterministic fixture maps for jobs, assets, technicians, dispatcher/adjuster context, inspection steps, notes, evidence items, route posture, support findings, and permission/capability pressure. Keep IDs stable for route-tour paths, e.g. `job-1`, `asset-windshield-1`, `evidence-windshield-1`.

---

### `examples/phoenix_host/lib/crosswake_example/field_service/jobs.ex` (service, request-response + transform)

**Analog:** `examples/phoenix_host/lib/crosswake_example/saas_portal/accounts.ex`

**Imports and read-only context pattern** (lines 1-8):
```elixir
defmodule CrosswakeExample.SaaSPortal.Accounts do
  @moduledoc """
  Read-only account context for the AdminPilot SaaS/admin showcase lane.
  """

  alias CrosswakeExample.SaaSPortal.Fixtures

  def get_account!(id) when is_binary(id) do
```

**Lookup/error pattern** (lines 8-16):
```elixir
def get_account!(id) when is_binary(id) do
  account = Fixtures.account()

  if account.id == id do
    account
  else
    raise ArgumentError, "unknown SaaS account: #{inspect(id)}"
  end
end
```

**Derived context pattern** (lines 20-35, 80-90):
```elixir
def account_summary!(account_or_id) do
  account = account_or_id |> account_id_for() |> get_account!()

  %{
    id: account.id,
    name: account.name,
    health: account.health,
    plan: account.plan,
    renewal_window: account.renewal_window,
    open_approvals: account.open_approvals,
    member_count: account_member_count(account.id),
    team_count: account_team_count(account.id),
    role_count: length(Fixtures.roles()),
    cached_read_posture: Fixtures.settings().cached_read_posture
  }
end

def activity_context_for_account!(account_or_id) do
  account_id = account_id_for(account_or_id)
  get_account!(account_id)

  %{
    operational_records: filter_account(Fixtures.operational_records(), account_id),
    approval_policies: Fixtures.approval_policies(),
    activity_events: filter_account(Fixtures.activity_events(), account_id),
    admin_pressure: Fixtures.admin_pressure()
  }
end
```

**Apply to Fieldserv:** use `Jobs.list_jobs/0`, `Jobs.get_job!/1`, `Jobs.job_summary!/1`, `Jobs.inspection_context!/1`, `Jobs.evidence_context!/1`, and `Jobs.route_posture!/1`. Return fixture-derived maps, not Ecto records, for broad job/asset/checklist data.

---

### `examples/phoenix_host/lib/crosswake_example/field_service/evidence.ex` (service, CRUD + event-driven)

**Analog:** `examples/phoenix_host/lib/crosswake_example/saas_portal/approvals.ex`

**Imports pattern** (lines 10-17):
```elixir
import Ecto.Query

alias Ecto.Multi
alias CrosswakeExample.Repo
alias CrosswakeExample.SaaSPortal.Approval
alias CrosswakeExample.SaaSPortal.ApprovalActivityEvent
alias CrosswakeExample.SaaSPortal.Auth
alias CrosswakeExample.SaaSPortal.Fixtures
```

**Scope/authorization guard pattern** (lines 91-103):
```elixir
def approve_approval(scope, approval_id, metadata)
    when is_map(scope) and is_binary(approval_id) and is_map(metadata) do
  %{account_id: account_id, user_id: user_id, role: role, route_id: route_id} =
    normalize_scope(scope)

  with true <- Auth.approver?(%{role: role}),
       %Approval{} = approval <- approval_by_id(approval_id),
       true <- approval.account_id == account_id do
    persist_approval(approval, user_id, route_id, metadata)
  else
    _ -> {:error, :forbidden}
  end
end
```

**Reset/digest pattern** (lines 123-163):
```elixir
def reset! do
  fixtures = Fixtures.approvals()

  {:ok, counts} =
    Repo.transaction(fn ->
      Repo.delete_all(ApprovalActivityEvent)
      Repo.delete_all(Approval)

      fixtures
      |> Enum.with_index()
      |> Enum.each(fn {fixture, index} ->
        fixture
        |> approval_attrs(index)
        |> then(&Approval.changeset(%Approval{}, &1))
        |> Repo.insert!()
      end)

      %{
        approvals: length(fixtures),
        approval_activity_events: length(fixtures)
      }
    end)

  counts
end

def digest_components do
  [
    "saas_admin.persisted.approvals=#{Repo.aggregate(Approval, :count)}",
    "saas_admin.persisted.approval_activity_events=#{Repo.aggregate(ApprovalActivityEvent, :count)}",
    persisted_approval_components(),
    persisted_activity_components()
  ]
  |> List.flatten()
  |> Enum.sort()
end
```

**Ecto.Multi transition pattern** (lines 169-202):
```elixir
defp persist_approval(%Approval{} = approval, user_id, route_id, metadata) do
  occurred_at = DateTime.truncate(DateTime.utc_now(), :second)

  event_attrs = %{
    event_id: "#{approval.approval_id}-approved",
    approval_id: approval.approval_id,
    account_id: approval.account_id,
    actor_id: user_id,
    event_type: "approval_approved",
    outcome: "approved",
    route_id: route_id,
    support_ref: approval.support_ref,
    occurred_at: occurred_at,
    metadata: support_metadata(metadata)
  }

  Multi.new()
  |> Multi.update(:approval, Approval.changeset(approval, %{status: "approved"}))
  |> Multi.insert(:activity, ApprovalActivityEvent.changeset(%ApprovalActivityEvent{}, event_attrs))
  |> Repo.transaction()
  |> case do
    {:ok, %{approval: approval}} -> {:ok, approval_to_map(approval)}
    {:error, _step, _changeset, _changes} -> {:error, :invalid}
  end
end
```

**Metadata sanitization pattern** (lines 248-254):
```elixir
defp support_metadata(metadata) when is_map(metadata) do
  metadata
  |> Enum.reject(fn {key, _value} ->
    key in [:token, :session, :session_ref, :provider_payload, :secret]
  end)
  |> Map.new(fn {key, value} -> {to_string(key), stringify_metadata_value(value)} end)
end
```

**Apply to Fieldserv:** put all workflow mutations here: `record_inspection_event/3`, `record_device_evidence/3`, `start_backend_verification/3`, `mark_backend_verified/3`, `mark_backend_rejected/3`. If more than one row changes, use `Ecto.Multi`. Do not mutate from LiveViews directly.

---

### Fieldserv persisted schemas and migration (model + migration, CRUD/event-driven)

**Analogs:** `approval.ex`, `approval_activity_event.ex`, and `20260710000000_create_saas_admin_approvals_and_activity_events.exs`

**Closed status vocabulary pattern** (`approval.ex` lines 9-13, 34-63):
```elixir
use Ecto.Schema
import Ecto.Changeset

@statuses ["pending", "approved", "rejected"]

def changeset(approval, attrs) do
  approval
  |> cast(attrs, [:approval_id, :account_id, :title, :status])
  |> validate_required([:approval_id, :account_id, :title, :status])
  |> validate_inclusion(:status, @statuses)
  |> unique_constraint(:approval_id)
end
```

**Append-only event schema pattern** (`approval_activity_event.ex` lines 12-28, 34-62):
```elixir
@event_types ["approval_seeded", "approval_approved"]
@outcomes ["seeded", "approved", "denied"]

schema "saas_admin_approval_activity_events" do
  field(:event_id, :string)
  field(:approval_id, :string)
  field(:account_id, :string)
  field(:actor_id, :string)
  field(:event_type, :string)
  field(:outcome, :string)
  field(:route_id, :string)
  field(:support_ref, :string)
  field(:occurred_at, :utc_datetime)
  field(:metadata, :map, default: %{})
end

def changeset(event, attrs) do
  event
  |> cast(attrs, [:event_id, :approval_id, :account_id, :actor_id, :event_type, :outcome])
  |> validate_required([:event_id, :approval_id, :account_id, :actor_id, :event_type, :outcome])
  |> validate_inclusion(:event_type, @event_types)
  |> validate_inclusion(:outcome, @outcomes)
  |> unique_constraint(:event_id)
end
```

**Migration shape** (lines 4-49):
```elixir
def change do
  create table(:saas_admin_approvals) do
    add(:approval_id, :string, null: false)
    add(:account_id, :string, null: false)
    add(:title, :string, null: false)
    add(:status, :string, null: false, default: "pending")
    add(:metadata, :map, null: false, default: %{})

    timestamps(type: :utc_datetime)
  end

  create(unique_index(:saas_admin_approvals, [:approval_id]))
  create(index(:saas_admin_approvals, [:account_id]))

  create table(:saas_admin_approval_activity_events) do
    add(:event_id, :string, null: false)
    add(:approval_id, :string, null: false)
    add(:account_id, :string, null: false)
    add(:actor_id, :string, null: false)
    add(:event_type, :string, null: false)
    add(:outcome, :string, null: false)
    add(:metadata, :map, null: false, default: %{})

    timestamps(type: :utc_datetime)
  end

  create(unique_index(:saas_admin_approval_activity_events, [:event_id]))
  create(index(:saas_admin_approval_activity_events, [:account_id]))
end
```

**Apply to Fieldserv:** if the planner chooses a new table, keep it narrow: evidence/workflow events plus optional technician job state. Good Fieldserv statuses are `device_evidence_recorded`, `backend_verification_pending`, `backend_verified`, and `backend_rejected`; do not encode offline journal/outbox states.

---

### `examples/phoenix_host/lib/crosswake_example/field_service/diagnostics.ex` (utility, request-response + transform)

**Analog:** `examples/phoenix_host/lib/crosswake_example/saas_portal/diagnostics.ex`

**Compiled metadata pattern** (lines 1-12, 83-104):
```elixir
defmodule CrosswakeExample.SaaSPortal.Diagnostics do
  @moduledoc """
  Lane-local AdminPilot route policy diagnostics.

  The route facts here are derived from compiled Phoenix router metadata.
  """

  alias Crosswake.Policy.RouterMetadata
  alias CrosswakeExample.Router
  alias CrosswakeExample.Showcase.Catalog

  def route_policy_rows(router \\ Router) do
    router
    |> compiled_saas_routes()
    |> Enum.sort_by(fn %{policy: policy} ->
      Enum.find_index(@route_ids, &(&1 == policy.id)) || length(@route_ids)
    end)
    |> Enum.map(&route_row/1)
  end

  defp compiled_saas_routes(router) do
    router
    |> Phoenix.Router.routes()
    |> Enum.flat_map(fn route ->
      with true <- String.starts_with?(route.path, "/saas"),
           {:ok, policy} <- RouterMetadata.fetch(route.metadata) do
        [%{route: route, policy: policy}]
      else
        _other -> []
      end
    end)
  end
```

**Row enrichment pattern** (lines 35-72, 106-125):
```elixir
@support_enrichment %{
  "saas-dashboard" => %{
    support_label: "Available today",
    rough_edge: "Cached read-only dashboard context is a degraded read, not offline admin mutation.",
    guide_links: @row_guide_links.default
  }
}

defp route_row(%{route: route, policy: policy}) do
  %{
    route_id: policy.id,
    path: route.path,
    runtime_owner: policy.runtime,
    runtime_owner_label: runtime_owner_label(policy.runtime),
    offline_posture: policy.offline,
    offline_posture_label: offline_posture_label(policy.offline),
    security_posture: policy.security,
    security_posture_label: security_posture_label(policy.security),
    capabilities: policy.capabilities,
    capability_labels: capability_labels(policy.capabilities)
  }
  |> Map.merge(enrichment!(policy.id))
end
```

**Label helpers** (lines 131-181):
```elixir
defp runtime_owner_label(:live_view), do: "LiveView route"
defp runtime_owner_label(runtime), do: humanize_atom(runtime)

defp offline_posture_label(:cached_read_only), do: "Cached read-only"
defp offline_posture_label(:unavailable), do: "Offline unavailable"
defp offline_posture_label(offline), do: humanize_atom(offline)

defp capability_labels([]), do: ["No native capability required"]
defp capability_labels(capabilities), do: Enum.map(capabilities, &to_string/1)
```

**Apply to Fieldserv:** filter `/fieldserv`, not `/saas`; include route ids `fieldserv-jobs`, `fieldserv-job`, `fieldserv-inspection`, `fieldserv-job-capture`, and `fieldserv-evidence-review`. Enrichment should use allowlisted labels only: `Available today`, `Proof-backed example`, `Demo pressure`, `Future gap`, `Next-pack candidate`.

---

### `examples/phoenix_host/lib/crosswake_example/field_service/components.ex` (component, request-response + transform)

**Analog:** `examples/phoenix_host/lib/crosswake_example/saas_portal/components.ex`

**Lane-local component module pattern** (lines 1-13):
```elixir
defmodule CrosswakeExample.SaaSPortal.Components do
  @moduledoc """
  AdminPilot-specific function components for the SaaS/admin showcase lane.

  These components are intentionally lane-local.
  """

  use Phoenix.Component

  alias CrosswakeExample.SaaSPortal.Diagnostics
  alias CrosswakeExample.Showcase.Branding
```

**Shell component pattern** (lines 14-74):
```elixir
attr(:page_title, :string, required: true)
attr(:route_id, :string, required: true)
attr(:current_saas_account, :map, required: true)
attr(:current_saas_user, :map, required: true)
attr(:posture_badges, :list, default: [])
slot(:inner_block)

def admin_shell(assigns) do
  assigns =
    assigns
    |> assign(:brand, Branding.brand_for!(:saas_admin))
    |> assign(:nav_items, nav_items(assigns.current_saas_account.id))

  ~H"""
  <div class={"adminpilot-shell #{@brand.theme_class}"} data-route-id={@route_id}>
    <header class="adminpilot-topbar" aria-label="AdminPilot workspace">
      ...
    </header>

    <nav class="adminpilot-nav" aria-label="AdminPilot routes">
      <a :for={item <- @nav_items} href={item.path} class={["adminpilot-nav-link", item.route_id == @route_id && "adminpilot-nav-link-active"]}>
        {item.label}
      </a>
    </nav>

    <div class="adminpilot-layout">
      <main class="adminpilot-main" aria-labelledby="adminpilot-page-title">
        ...
        {render_slot(@inner_block)}
      </main>
    </div>
  </div>
  """
end
```

**Diagnostics component pattern** (lines 91-151):
```elixir
attr(:route_id, :string, required: true)
attr(:rows, :list, default: [])
attr(:guide_links, :list, default: [])

def diagnostics_panel(assigns) do
  assigns =
    assigns
    |> assign_new(:rows, fn -> Diagnostics.route_policy_rows() end)
    |> assign_new(:guide_links, fn -> Diagnostics.guide_links() end)

  ~H"""
  <details class="adminpilot-diagnostics" data-route-id={@route_id}>
    <summary>
      <span>Route policy diagnostics</span>
      <small>AdminPilot routes only</small>
    </summary>
    ...
  </details>
  """
end
```

**Reusable lane widgets** (lines 153-188):
```elixir
def kpi_strip(assigns) do
  ~H"""
  <div class="adminpilot-kpi-strip" aria-label="AdminPilot workspace metrics">
    <section :for={item <- @items} class="adminpilot-kpi">
      <p>{item.label}</p>
      <strong>{item.value}</strong>
      <span>{item.detail}</span>
    </section>
  </div>
  """
end

def status_badge(assigns) do
  ~H"""
  <span class={["adminpilot-status-badge", status_tone_class(@tone)]}>{@label}</span>
  """
end
```

**Apply to Fieldserv:** rename CSS prefix to `fieldserv-*`; shell should present Fieldserv job language first and route-policy labels as compact badges/panel rows. Include components for job cards, asset summary, checklist rows, evidence timeline, route posture badges, support findings, and disabled/future native-control callouts.

---

### Fieldserv LiveViews (routes, request-response + event-driven)

**Analogs:** `dashboard_live.ex`, `approval_live.ex`, `claim_capture_live.ex`, `media_lane_live.ex`

**List/dashboard LiveView load pattern** (`dashboard_live.ex` lines 1-28):
```elixir
defmodule CrosswakeExample.SaaSPortal.DashboardLive do
  use Phoenix.LiveView

  alias CrosswakeExample.PageTitle
  alias CrosswakeExample.SaaSPortal.Accounts
  alias CrosswakeExample.SaaSPortal.Approvals
  alias CrosswakeExample.SaaSPortal.Components
  alias CrosswakeExample.SaaSPortal.Diagnostics

  @impl true
  def mount(_params, _session, socket) do
    account = socket.assigns.current_saas_account
    approvals = Approvals.list_approvals(account.id)
    account_summary = Accounts.account_summary!(account)
    activity_context = Accounts.activity_context_for_account!(account)

    {:ok,
     assign(socket,
       page_title: PageTitle.admin("Dashboard"),
       account_summary: account_summary,
       activity_context: activity_context,
       pending_approvals: Enum.filter(approvals, &(&1.status == :pending)),
       diagnostics_rows: Diagnostics.route_policy_rows()
     )}
  end
```

**Render through lane shell pattern** (`dashboard_live.ex` lines 30-96):
```elixir
def render(assigns) do
  ~H"""
  <Components.admin_shell
    page_title="Northwind mobile approvals"
    route_id="saas-dashboard"
    current_saas_account={@current_saas_account}
    current_saas_user={@current_saas_user}
    posture_badges={["LiveView route", "Cached read-only", "Server authority"]}
  >
    <Components.kpi_strip items={@kpis} />
    ...
    <Components.diagnostics_panel route_id="saas-dashboard" rows={@diagnostics_rows} />
  </Components.admin_shell>
  """
end
```

**Detail/action event pattern** (`approval_live.ex` lines 29-68):
```elixir
def handle_params(%{"id" => approval_id}, _uri, socket) do
  approval = Approvals.get_approval!(approval_scope(socket), approval_id)

  {:noreply,
   assign(socket,
     approval: approval,
     activity_events: activity_for_display(approval.id),
     page_title: PageTitle.admin(approval.title)
   )}
end

def handle_event("approve", _params, socket) do
  approval = socket.assigns.approval

  case Approvals.approve_approval(approval_scope(socket), approval.id, %{haptics: "post_success_optional"}) do
    {:ok, approved} ->
      {:noreply, assign(socket, approval: approved, approval_notice: "Phoenix recorded the decision")}

    {:error, :forbidden} ->
      {:noreply, assign(socket, approval_error: "Approver role required.")}
  end
end
```

**Native capture fallback pattern** (`claim_capture_live.ex` lines 7-37):
```elixir
def mount(%{"id" => id}, _session, socket) do
  claim = Claims.get_claim!(id)
  # The native shell handles the actual capture UI, so this LiveView
  # serves as the fallback/host context when mounted.
  {:ok,
   assign(socket,
     claim: claim,
     capture_completed: false,
     page_title: PageTitle.field("Capture Evidence")
   )}
end

def render(assigns) do
  ~H"""
  <div class="native-capture-fallback">
    <h1>Capture Evidence for <%= @claim.title %></h1>
    <p>Please use the native mobile application to capture media.</p>
    <.link navigate={"/native/submissions/#{@claim.id}/review"} class="button">
      Simulate Capture Completion (Proceed to Review)
    </.link>
  </div>
  """
end
```

**Evidence status ladder pattern** (`media_lane_live.ex` lines 84-169, 225-249):
```elixir
def handle_event("record_upload", params, socket) do
  correlation_id = Map.get(params, "correlation_id", "corr_live_upload")

  with %Contracts.UploadGrant{} = grant <- socket.assigns.grant,
       {:ok, evidence} <- MockCapture.emit_capture_evidence(grant, correlation_id: correlation_id),
       {:ok, ingestion} <- ReconciliationInbox.ingest_capture_evidence(evidence),
       {:ok, media_object} <- MediaProjection.project_object(socket.assigns.media_object, ingestion) do
    {:noreply,
     assign(socket,
       media_object: media_object,
       derived_state: MediaProjection.derived_state(media_object),
       proof_step: :device_evidence_recorded
     )}
  else
    nil -> {:noreply, put_error(socket, "Media lane unavailable: no active grant")}
    {:error, reason} -> {:noreply, put_error(socket, "Media evidence rejected: #{inspect(reason)}")}
  end
end

defp state_copy(:device_evidence_recorded, _state),
  do: "Device evidence recorded; backend verification still required."

defp state_copy(:backend_verification_in_progress, _state),
  do: "Backend verification in progress."

defp state_copy(:backend_verified_available, _state), do: "Backend verified media is available."
defp state_copy(:backend_rejected, _state), do: "Backend rejected this media object."
```

**Apply to Fieldserv:** create five primary LiveViews:

| File | Copy pattern from | Key behavior |
|---|---|---|
| `jobs_live.ex` | `DashboardLive` mount/render | Load job queue, technician state, evidence blockers, route badges. |
| `job_live.ex` | `DashboardLive` + `ApprovalLive.handle_params/3` | Load one job, asset summary, notes/activity, evidence timeline. |
| `inspection_live.ex` | `ApprovalLive.handle_event/3` | Render checklist; online-only note/step actions call context functions; future offline island copy stays explicit. |
| `capture_live.ex` | `ClaimCaptureLive` | Native-screen handoff/fallback with camera capability and no web camera/scanner. |
| `evidence_review_live.ex` | `MediaLaneLive` | Show device evidence vs backend verification status; avoid `uploaded successfully` as final authority copy. |

---

### `examples/phoenix_host/lib/crosswake_example/router.ex` (route config, request-response)

**Analog:** existing `/saas` and `/native` scopes in `router.ex`

**LiveView lane scope pattern** (lines 212-283):
```elixir
scope "/saas", CrosswakeExample.SaaSPortal do
  pipe_through([:browser, :saas_portal])

  crosswake_defaults runtime: :live_view, offline: :cached_read_only, security: :standard do
    live_session :saas_portal,
      on_mount: [{CrosswakeExample.SaaSPortal.OnMount, :require_authenticated_member}] do
      live("/dashboard", DashboardLive,
        crosswake: [
          id: "saas-dashboard",
          runtime: :live_view,
          offline: :cached_read_only,
          security: :standard
        ]
      )
    end
  end
end
```

**Native-screen metadata pattern** (lines 324-341):
```elixir
live("/claims/:id/capture", ClaimCaptureLive,
  crosswake: [
    id: "selective-native-claim-capture",
    runtime: :native_screen,
    capabilities: [:camera],
    packs: [[id: :camera_capture_assets, version: "1.0.0", kind: :media]],
    transfers: [
      [
        id: :capture_upload,
        intent: :upload,
        source: :native_capture,
        verification: :required,
        media_types: ["image/*"]
      ]
    ],
    offline: :cached_read_only,
    security: :sensitive
  ]
)
```

**Apply to Fieldserv:** add a `/fieldserv` scope with LiveView route metadata for jobs/detail/inspection/evidence review and a native-screen metadata block for `/fieldserv/jobs/:id/capture`. Mirror the capture route shape above, but use route id `fieldserv-job-capture`.

---

### Showcase integration files (catalog, fixtures, reset, hub)

**Analogs:** `showcase/catalog.ex`, `showcase/fixtures.ex`, `showcase/reset.ex`, `showcase/hub_live.ex`

**Catalog support-label allowlist** (`catalog.ex` lines 11-18):
```elixir
@allowed_support_labels [
  "Available today",
  "Proof-backed example",
  "Demo pressure",
  "Advisory evidence",
  "Future gap",
  "Next-pack candidate"
]
```

**Field Service card pattern to replace** (`catalog.ex` lines 45-75):
```elixir
%{
  id: :field_service,
  heading: "Field Service",
  body: "Device-pressure jobs with capture gaps and native-screen candidates named honestly.",
  primary_path: "/native/claims/:id/capture",
  primary_route_id: "selective-native-claim-capture",
  primary_cta: "Preview Field Service",
  route_posture: %{
    runtime: :native_screen,
    offline: :cached_read_only,
    security: :sensitive,
    capabilities: [:camera]
  },
  support_labels: ["Demo pressure", "Future gap", "Next-pack candidate"]
}
```

**Reset delegate pattern** (`showcase/fixtures.ex` lines 9-33 and `reset.ex` lines 15-40):
```elixir
alias CrosswakeExample.SaaSPortal.Approvals
alias CrosswakeExample.SaaSPortal.Fixtures, as: SaaSFixtures

def reset_saas_admin! do
  data = SaaSFixtures.seed()
  persisted = Approvals.reset!()

  %{
    accounts: 1,
    approvals: persisted.approvals,
    approval_activity_events: persisted.approval_activity_events
  }
end

def saas_admin_digest_components do
  SaaSFixtures.digest_components() ++ Approvals.digest_components()
end

def reset! do
  counts = %{
    saas_admin: Fixtures.reset_saas_admin!(),
    field_service_native_pressure: NativeFixtures.seed(),
    learning_training: Flashcards.reset_seed!()
  }

  %{counts: counts, digest: digest(counts), browser_state_reset: @browser_state_reset}
end
```

**Hub lane card rendering/link pattern** (`hub_live.ex` lines 48-105, 127-128):
```elixir
<section id="showcase-lanes" class="showcase-lane-grid" aria-label="Showcase lanes">
  <article :for={lane <- @lanes} class={["card", "showcase-lane-card", lane.brand.theme_class]}>
    ...
    <a class="btn-secondary showcase-lane-cta" href={lane_href(lane)}>
      <%= lane.primary_cta %>
    </a>
    ...
  </article>
</section>

defp lane_href(%{id: :field_service}), do: "/native/claims"
defp lane_href(%{primary_path: path}), do: path
```

**Apply to Fieldserv:** repoint the catalog and `lane_href/1` to `/fieldserv/jobs`. Reset should call a Fieldserv-owned reset helper and include Fieldserv digest components. Preserve `browser_state_reset: false`.

---

### `examples/phoenix_host/priv/static/css/app.css` (config, transform)

**Analog:** scoped `.adminpilot-*` CSS block in `app.css`

**Scoped token/prefix pattern** (lines 554-565):
```css
.adminpilot-shell {
  --adminpilot-accent: #2f6f73;
  --adminpilot-accent-strong: #194d4f;
  --adminpilot-highlight: #d6a34a;
  --adminpilot-soft: #eaf3f2;
  --adminpilot-sensitive: var(--cw-runtime-sensitive);
  --adminpilot-panel-bg: var(--cw-surface-inset);

  max-width: 1180px;
  margin: 0 auto;
  padding: calc(var(--cw-spacing-base) * 5);
}
```

**Responsive navigation/badges pattern** (lines 658-730):
```css
.adminpilot-nav {
  display: flex;
  flex-wrap: wrap;
  gap: calc(var(--cw-spacing-base) * 2);
}

.adminpilot-nav-link {
  min-height: 44px;
  display: inline-flex;
  align-items: center;
  border: 1px solid var(--cw-border-default);
  border-radius: 8px;
}

.adminpilot-route-badge,
.adminpilot-status-badge {
  display: inline-flex;
  align-items: center;
  min-height: 28px;
  border: 1px solid currentColor;
  border-radius: 999px;
  overflow-wrap: anywhere;
}
```

**Diagnostics/focus/mobile pattern** (lines 873-956, 967-1012):
```css
.adminpilot-diagnostics summary {
  min-height: 44px;
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.adminpilot-nav-link:focus-visible,
.adminpilot-diagnostics summary:focus-visible,
.adminpilot-action-footer button:focus-visible {
  outline: var(--cw-focus-ring-width) solid var(--cw-action-focus-ring);
  outline-offset: 2px;
}

@media (max-width: 820px) {
  .adminpilot-topbar,
  .adminpilot-page-heading {
    grid-template-columns: 1fr;
  }

  .adminpilot-kpi-strip,
  .adminpilot-diagnostics-row {
    grid-template-columns: 1fr;
  }
}
```

**Apply to Fieldserv:** copy the scoped-block approach using `fieldserv-*` classes and Fieldserv signal-orange identity from `Branding.brand_for!(:field_service)`. Keep 8px radii, wrapping badges, 44px actions, dark/system theme overrides, reduced-motion handling, and no horizontal-overflow layouts.

## Test Pattern Assignments

### Fieldserv fixture/context tests

**Analogs:** `fixtures_test.exs`, `approvals_test.exs`

**Fixture density pattern** (`fixtures_test.exs` lines 14-101):
```elixir
@tag :fixture_density
test "AdminPilot fixture density contract covers account, team, roles, settings, activity, and digest" do
  module = assert_exported!(@fixtures, :seed, 0, "...")
  data = apply(module, :seed, [])

  assert is_map(data)
  assert_min_list(data, :users, 3, "...")
  assert_min_list(data, :approvals, 3, "...")

  digest_components = apply(digest_module, :digest_components, [])
  assert is_list(digest_components) and digest_components != []
end
```

**Persistence/workflow pattern** (`approvals_test.exs` lines 24-75, 77-107):
```elixir
@tag :approval_schema_persistence
test "AdminPilot approval schema persistence contract persists approval and activity evidence through reset" do
  apply(module, :reset!, [])
  before = apply(module, :list_approvals, [@approver_scope])
  assert Enum.any?(before, &(Map.get(&1, :id) == "approval-1" and Map.get(&1, :status) == :pending))

  {:ok, approved} = apply(module, :approve_approval, [@approver_scope, "approval-1", %{haptics: :missing}])
  assert approved.status == :approved

  activity = apply(module, :activity_events, [@approver_scope])
  assert Enum.any?(activity, &(Map.get(&1, :event_type) == :approval_approved))
end
```

**Apply to:** `field_service/fixtures_test.exs`, `field_service/jobs_test.exs`, `field_service/evidence_test.exs`.

### Fieldserv diagnostics tests

**Analog:** `diagnostics_test.exs`

**Compiled-router drift pattern** (lines 21-65):
```elixir
rows = apply(module, :route_policy_rows, [@router])
assert Enum.map(rows, & &1.route_id) == @route_ids

compiled = compiled_route_map()

for row <- rows do
  compiled_row = Map.get(compiled, row.route_id)
  assert row.path == compiled_row.route.path
  assert row.runtime_owner == compiled_row.policy.runtime
  assert row.offline_posture == compiled_row.policy.offline
  assert row.security_posture == compiled_row.policy.security
  assert normalized(row.capabilities) == normalized(compiled_row.policy.capabilities)
end
```

**Support enrichment pattern** (lines 67-97):
```elixir
for route_id <- @route_ids do
  row = Enum.find(rows, &(Map.get(&1, :route_id) == route_id))
  assert is_binary(row.support_label) and row.support_label != ""
  assert is_binary(row.rough_edge) and row.rough_edge != ""
  assert Enum.all?(row.guide_links, &(&1 in @guide_links))
  refute row.support_label =~ ~r/raw|denial|token|secret/i
end
```

**Apply to:** `field_service/diagnostics_test.exs`.

### Fieldserv LiveView/render tests

**Analog:** `approvals_live_test.exs`

**Render/no-overclaim pattern** (lines 15-48):
```elixir
{:ok, mounted} = apply(module, :mount, [%{}, %{}, socket])
html = render_to_string(module, mounted.assigns)

assert html =~ "role=\"status\""
assert html =~ "Cached read-only"
assert html =~ "Server authority"
refute html =~ ~r/outbox|journal|reconciliation|local[- ]first/i
```

**Event/state pattern** (lines 50-97):
```elixir
{:ok, mounted} = apply(module, :mount, [%{}, %{}, socket])
{:noreply, loaded} = apply(module, :handle_params, [%{"id" => "approval-1"}, "/saas/approvals/approval-1", mounted])

initial_html = render_to_string(module, loaded.assigns)
assert initial_html =~ "Server authority"

{:noreply, approved} = apply(module, :handle_event, ["approve", %{}, loaded])
success_html = render_to_string(module, approved.assigns)
assert success_html =~ "role=\"status\""
assert success_html =~ "Phoenix recorded the decision"
```

**Apply to:** all `field_service/*_live_test.exs`. For `capture_live_test.exs`, also copy `claim_capture_live_test.exs` lines 5-10 for the simple native-return event shape.

### Showcase tests

**Catalog drift pattern** (`catalog_test.exs` lines 43-89, 91-108):
```elixir
for card <- Catalog.cards() do
  route_id = Map.fetch!(card, :primary_route_id)
  path = Map.fetch!(card, :primary_path)
  assert Map.has_key?(compiled, route_id)
  %{route: route} = Map.fetch!(compiled, route_id)
  assert route.path == path
end

for card <- Catalog.cards(), label <- Map.fetch!(card, :support_labels) do
  assert label in @allowed_support_labels
  refute label =~ ~r/\bsupported\b/i
end
```

**Reset idempotency/non-browser claim pattern** (`reset_test.exs` lines 11-24, 43-78):
```elixir
first = Reset.reset!()
second = Reset.reset!()

assert first.counts == second.counts
assert first.digest == second.digest
assert byte_size(first.digest) == 64

result = Reset.reset!()
assert result.browser_state_reset == false
```

**Apply to:** `showcase/catalog_test.exs`, `showcase/reset_test.exs`, `showcase/hub_live_test.exs`, and `e2e/showcase_reset_controller_test.exs`.

### Browser route-tour and manifest tests

**Analog:** `examples/phoenix_host/e2e/route_tour.spec.ts`

**Semantic-before-screenshot pattern** (lines 27-48):
```typescript
test('proves LiveView, bounded bridge, offline island, and native-owned fallback route semantics before screenshots', async ({ page, context }) => {
  mkdirSync(routeTourScreenshotDir, { recursive: true });

  await proveShowcaseHub(page);
  await proveSaasRoute(page);
  await proveAdminPilotApprovalFlow(page);
  await proveNativeOwnedRoute(page);
  await captureRouteScreenshot(page, 'selective-native-claim-capture-unavailable.png');

  writeRouteTourEvidenceManifest(screenshotDir, routeTourCommand);
});
```

**AdminPilot click-path pattern to adapt** (lines 141-207):
```typescript
const reset = await page.request.post('/_e2e/showcase-reset');
expect(reset.ok(), ownerMessage('showcase-reset', 'deterministic showcase reset')).toBe(true);

await page.goto('/saas/dashboard');
await expect(page.getByText(/LiveView route/i).first()).toBeVisible();
await expect(page.getByText(/Cached read-only/i).first()).toBeVisible();

await page.getByRole('link', { name: /Approvals|Review queue/i }).first().click();
await expect(page).toHaveURL(/\/saas\/approvals$/);

await page.getByRole('link', { name: /Quarterly spend increase|approval-1/i }).click();
await expectLiveViewConnected(page, 'saas-approval');
await page.getByRole('button', { name: 'Approve request' }).click();

await page.locator('.adminpilot-diagnostics summary').first().click();
await expect(body).toContainText('Route policy diagnostics');
```

**Native-owned route assertion pattern** (lines 276-288):
```typescript
await page.goto(`/native/claims/${claimId}/capture`);

await expect(page).toHaveTitle('Capture Evidence · Fieldserv · Crosswake');
await expect(page.getByRole('heading', { name: /Capture Evidence for Route Tour Claim/ })).toBeVisible();
await expect(page.locator('.native-capture-fallback')).toContainText('Please use the native mobile application to capture media.');

const router = readFileSync(routerPath, 'utf8');
expect(router).toContain('id: "selective-native-claim-capture"');
expect(router).toContain('runtime: :native_screen');
expect(router).toContain('capabilities: [:camera]');
```

**Mobile/focus/overflow helpers** (lines 50-65, 294-328):
```typescript
await page.setViewportSize({ width: 390, height: 844 });
await page.emulateMedia({ colorScheme: 'dark', reducedMotion: 'reduce' });
await expectNoHorizontalOverflow(page, 'showcase-hub');
await page.keyboard.press('Tab');
await expectVisibleFocus(page, 'saas-approval');

async function expectNoHorizontalOverflow(page: Page, routeId: string) {
  const metrics = await page.evaluate(() => ({
    clientWidth: document.documentElement.clientWidth,
    scrollWidth: document.documentElement.scrollWidth,
    bodyScrollWidth: document.body.scrollWidth,
  }));
  expect(Math.max(metrics.scrollWidth, metrics.bodyScrollWidth)).toBeLessThanOrEqual(metrics.clientWidth + 1);
}
```

**Evidence manifest pattern** (`evidence_manifest.ts` lines 39-65, 68-95):
```typescript
export function writeRouteTourEvidenceManifest(artifactDir: string, command: string) {
  const sourceJob = process.env.GITHUB_JOB || defaultSourceJob;
  const capturedAt = new Date().toISOString();
  const routes = routeTourEntries(command);

  assertRequiredArtifacts(artifactDir, routes);
  mkdirSync(artifactDir, { recursive: true });

  const manifest: EvidenceManifest = {
    schema_version: schemaVersion,
    crosswake_version: crosswakeVersion(),
    commit_sha: commitSha(),
    source_job: sourceJob,
    captured_at: capturedAt,
    retention_label: retentionLabel,
    routes: routes.map(route => ({ ...route, source_job: sourceJob, captured_at: capturedAt })),
  };

  const manifestPath = path.join(artifactDir, 'evidence-manifest.json');
  writeFileSync(manifestPath, `${JSON.stringify(manifest, null, 2)}\n`);
  return manifestPath;
}
```

**Apply to:** add a Fieldserv happy path to `route_tour.spec.ts` and include Fieldserv route artifacts in `evidence_manifest.ts`. Assert route owner, support labels, backend verification copy, no unsupported offline/local-first wording, mobile containment, focus, and screenshots after assertions pass.

## Shared Patterns

### Route Metadata Truth

**Source:** `examples/phoenix_host/lib/crosswake_example/router.ex` lines 215-283 and 324-341.
**Apply to:** router, diagnostics, catalog tests, route-tour tests.

All Fieldserv route ownership must be declared in compiled router metadata. Diagnostics should derive raw policy fields via `Phoenix.Router.routes/1` and `Crosswake.Policy.RouterMetadata.fetch/1`, not from duplicated prose.

### Reset And Digest Discipline

**Source:** `examples/phoenix_host/lib/crosswake_example/showcase/reset.ex` lines 15-40; `examples/phoenix_host/lib/crosswake_example/showcase/fixtures.ex` lines 12-33.
**Apply to:** Fieldserv fixtures/evidence context, showcase reset, reset tests, e2e reset controller tests.

Server reset remains deterministic and must keep `browser_state_reset: false`. If Fieldserv adds persisted evidence rows, include both row counts and stable row digest components.

### Evidence Authority Vocabulary

**Source:** `examples/phoenix_host/lib/crosswake_example/media/media_lane_live.ex` lines 225-249.
**Apply to:** evidence context, evidence review LiveView, tests, route-tour assertions.

Use `Device evidence recorded`, `Backend verification pending`, `Backend verified`, and `Backend rejected` style copy. Do not use `uploaded successfully` as final availability authority.

### Offline Honesty

**Source:** `examples/phoenix_host/test/crosswake_example/saas_portal/approvals_live_test.exs` lines 40-47.
**Apply to:** every Fieldserv LiveView, component test, route-tour proof.

Fieldserv can say `Cached read-only` and show future offline-island requirements. It must not imply `local-first`, `journal`, `outbox`, `replay`, `saved locally`, or `queued for sync` unless a real route-local offline island ships in the same phase.

### Scoped Operational UI

**Source:** `examples/phoenix_host/lib/crosswake_example/saas_portal/components.ex` lines 1-7; `examples/phoenix_host/priv/static/css/app.css` lines 554-1012.
**Apply to:** Fieldserv components, LiveViews, CSS, browser verification.

Build lane-local `fieldserv-*` components and CSS. Do not introduce a generic field-service CRUD framework, generic route inspector, or new styling system.

## No Analog Found

None. Every proposed file has a same-role or same-flow analog in the current codebase.

## Metadata

**Analog search scope:** `examples/phoenix_host/lib/crosswake_example/{saas_portal,selective_native,media,showcase}`, `examples/phoenix_host/test/crosswake_example/{saas_portal,selective_native,showcase,e2e}`, `examples/phoenix_host/e2e`, and `examples/phoenix_host/priv/static/css/app.css`.
**Files scanned:** 53 relevant files from `rg --files` and targeted line-numbered reads.
**Pattern extraction date:** 2026-07-11

