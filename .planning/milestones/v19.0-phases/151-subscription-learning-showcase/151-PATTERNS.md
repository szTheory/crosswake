# Phase 151: Subscription Learning Showcase - Pattern Map

**Mapped:** 2026-07-11
**Files analyzed:** 31 new/modified files inferred from CONTEXT.md and RESEARCH.md
**Analogs found:** 31 / 31

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `examples/phoenix_host/lib/crosswake_example/learn_loop.ex` | service | transform, request-response | `examples/phoenix_host/lib/crosswake_example/field_service/jobs.ex` | role-match |
| `examples/phoenix_host/lib/crosswake_example/learn_loop/fixtures.ex` | utility | transform | `examples/phoenix_host/lib/crosswake_example/field_service/fixtures.ex` | exact |
| `examples/phoenix_host/lib/crosswake_example/learn_loop/diagnostics.ex` | utility | transform | `examples/phoenix_host/lib/crosswake_example/field_service/diagnostics.ex` | exact |
| `examples/phoenix_host/lib/crosswake_example/learn_loop/entitlement.ex` | service | event-driven, transform | `examples/phoenix_host/lib/crosswake_example/commerce/entitlement_projection.ex` | role-match |
| `examples/phoenix_host/lib/crosswake_example/learn_loop/components.ex` | component | request-response | `examples/phoenix_host/lib/crosswake_example/field_service/components.ex` | exact |
| `examples/phoenix_host/lib/crosswake_example/learn_loop/dashboard_live.ex` | component | request-response | `examples/phoenix_host/lib/crosswake_example/field_service/jobs_live.ex` | exact |
| `examples/phoenix_host/lib/crosswake_example/learn_loop/course_live.ex` | component | request-response | `examples/phoenix_host/lib/crosswake_example/field_service/job_live.ex` | exact |
| `examples/phoenix_host/lib/crosswake_example/learn_loop/pack_live.ex` | component | request-response | `examples/phoenix_host/lib/crosswake_example/field_service/job_live.ex` | exact |
| `examples/phoenix_host/lib/crosswake_example/learn_loop/history_live.ex` | component | request-response, CRUD-read | `examples/phoenix_host/lib/crosswake_example/local_first/study_history_live.ex` | exact |
| `examples/phoenix_host/lib/crosswake_example/learn_loop/subscription_live.ex` | component | event-driven | `examples/phoenix_host/lib/crosswake_example/paywall_entry_live.ex` | exact |
| `examples/phoenix_host/lib/crosswake_example/learn_loop/study_controller.ex` | controller | request-response | `examples/phoenix_host/lib/crosswake_example_web/controllers/offline_controller.ex` | exact |
| `examples/phoenix_host/lib/crosswake_example_web/controllers/learn_loop_study_html.ex` | component | request-response | `examples/phoenix_host/lib/crosswake_example_web/controllers/offline_html.ex` | exact |
| `examples/phoenix_host/lib/crosswake_example_web/controllers/learn_loop_study_html/index.html.heex` | component | request-response, file-I/O | `examples/phoenix_host/lib/crosswake_example_web/controllers/offline_html/index.html.heex` | exact |
| `examples/phoenix_host/lib/crosswake_example/router.ex` | route | request-response | `examples/phoenix_host/lib/crosswake_example/router.ex` | exact |
| `examples/phoenix_host/lib/crosswake_example/showcase/branding.ex` | config | transform | `examples/phoenix_host/lib/crosswake_example/showcase/branding.ex` | exact |
| `examples/phoenix_host/lib/crosswake_example/showcase/catalog.ex` | config | transform | `examples/phoenix_host/lib/crosswake_example/showcase/catalog.ex` | exact |
| `examples/phoenix_host/lib/crosswake_example/showcase/hub_live.ex` | component | request-response | `examples/phoenix_host/lib/crosswake_example/showcase/hub_live.ex` | exact |
| `examples/phoenix_host/lib/crosswake_example/showcase/reset.ex` | service | batch, CRUD | `examples/phoenix_host/lib/crosswake_example/showcase/reset.ex` | exact |
| `examples/phoenix_host/priv/static/css/app.css` | config | transform | Fieldserv styles in `examples/phoenix_host/priv/static/css/app.css` | role-match |
| `examples/phoenix_host/priv/static/offline_study.js` | utility | event-driven, file-I/O | `examples/phoenix_host/priv/static/offline_study.js` | exact |
| `examples/phoenix_host/test/crosswake_example/learn_loop/fixtures_test.exs` | test | transform | `examples/phoenix_host/test/crosswake_example/field_service/fixtures_test.exs` | exact |
| `examples/phoenix_host/test/crosswake_example/learn_loop/diagnostics_test.exs` | test | transform | `examples/phoenix_host/test/crosswake_example/field_service/diagnostics_test.exs` | exact |
| `examples/phoenix_host/test/crosswake_example/learn_loop/dashboard_live_test.exs` | test | request-response | `examples/phoenix_host/test/crosswake_example/field_service/jobs_live_test.exs` | exact |
| `examples/phoenix_host/test/crosswake_example/learn_loop/subscription_live_test.exs` | test | event-driven | `examples/phoenix_host/lib/crosswake_example/paywall_entry_live.ex` plus commerce tests by contract style | role-match |
| `examples/phoenix_host/test/crosswake_example/showcase/catalog_test.exs` | test | transform | `examples/phoenix_host/test/crosswake_example/showcase/catalog_test.exs` | exact |
| `examples/phoenix_host/test/crosswake_example/showcase/reset_test.exs` | test | batch, CRUD | `examples/phoenix_host/test/crosswake_example/showcase/reset_test.exs` | exact |
| `examples/phoenix_host/test/crosswake_example/showcase/hub_live_test.exs` | test | request-response | `examples/phoenix_host/test/crosswake_example/showcase/hub_live_test.exs` | exact |
| `examples/phoenix_host/e2e/learnloop_offline.spec.ts` | test | event-driven, file-I/O | `examples/phoenix_host/e2e/offline_sync.spec.ts` | exact |
| `examples/phoenix_host/e2e/offline_sync.spec.ts` | test | event-driven, file-I/O | `examples/phoenix_host/e2e/offline_sync.spec.ts` | exact |
| `examples/phoenix_host/e2e/route_tour.spec.ts` | test | request-response, event-driven | `examples/phoenix_host/e2e/route_tour.spec.ts` | exact |
| `examples/phoenix_host/e2e/support/offline_route_proof.ts` | test utility | file-I/O | `examples/phoenix_host/e2e/support/offline_route_proof.ts` | exact |

## Pattern Assignments

### `examples/phoenix_host/lib/crosswake_example/learn_loop.ex` (service, transform/request-response)

**Analog:** `examples/phoenix_host/lib/crosswake_example/field_service/jobs.ex`

**Imports and context boundary pattern** (lines 1-7):
```elixir
defmodule CrosswakeExample.FieldService.Jobs do
  @moduledoc """
  Read-only Fieldserv job context backed by deterministic fixtures.
  """

  alias CrosswakeExample.FieldService.Fixtures
```

**Read-model assembly pattern** (lines 16-59):
```elixir
def list_jobs do
  Fixtures.jobs()
  |> Enum.sort_by(& &1.queue_rank)
end

def job_summary!(job_or_id) do
  job = job_or_id |> job_id_for() |> get_job!()
  asset = asset_for!(job.asset_id)
  technician = technician_for!(job.technician_id)
  evidence = evidence_for!(job.evidence_id)

  %{
    id: job.id,
    claim_id: job.claim_id,
    title: job.title,
    route_id: job.route_id,
    priority_label: priority_label(job.priority),
    status_label: job_status_label(job.status),
    cached_snapshot: "Cached read-only"
  }
end
```

**Error handling pattern** (lines 21-27):
```elixir
def get_job!(id) when is_binary(id) do
  Fixtures.jobs()
  |> Enum.find(&(&1.id == id))
  |> case do
    nil -> raise ArgumentError, "unknown Fieldserv job: #{inspect(id)}"
    job -> job
  end
end
```

**Apply to LearnLoop:** expose dashboard/course/pack/history/subscription read models from one context facade. Keep courses, lessons, packs, learners, route posture, support findings, and content-pack metadata deterministic unless a narrow persisted evidence record is required. Do not persist a broad LMS catalog.

---

### `examples/phoenix_host/lib/crosswake_example/learn_loop/fixtures.ex` (utility, transform)

**Analog:** `examples/phoenix_host/lib/crosswake_example/field_service/fixtures.ex`

**Deterministic fixture module pattern** (lines 1-4):
```elixir
defmodule CrosswakeExample.FieldService.Fixtures do
  @moduledoc """
  Deterministic Fieldserv fixtures for the field-service showcase lane.
  """
```

**Route posture and support truth fixture pattern** (lines 264-315):
```elixir
@route_postures [
  %{
    route_id: "fieldserv-jobs",
    path: "/fieldserv/jobs",
    runtime_owner: :live_view,
    offline_posture: :cached_read_only,
    security_posture: :standard,
    support_label: "Demo pressure",
    badge_label: "LiveView route",
    rough_edge: "Cached job snapshots are read-only."
  },
  %{
    route_id: "fieldserv-job-capture",
    path: "/fieldserv/jobs/:id/capture",
    runtime_owner: :native_screen,
    offline_posture: :cached_read_only,
    security_posture: :sensitive,
    support_label: "Next-pack candidate",
    badge_label: "Requires native runtime",
    rough_edge: "Camera capture requires the native app runtime."
  }
]
```

**Seed and digest pattern** (lines 423-472):
```elixir
def seed do
  %{
    jobs: @jobs,
    assets: @assets,
    technicians: @technicians,
    route_postures: @route_postures,
    support_findings: @support_findings,
    permission_pressure: @permission_pressure
  }
end

def digest_components do
  [
    Enum.map(@jobs, &digest_component(:job, &1)),
    Enum.map(@route_postures, &digest_component(:route_posture, &1)),
    Enum.map(@support_findings, &digest_component(:support_finding, &1))
  ]
  |> List.flatten()
  |> Enum.sort()
end
```

**Apply to LearnLoop:** define deterministic learner/course/lesson/content-pack/progress projection/support rows with stable ids like `learner-iris`, `course-elixir-routing`, `learnloop_daily_pack`, and route ids matching router metadata. Digest components must be `learning_training.*` or `learn_loop.*` scoped and should include route posture plus entitlement/offline support labels.

---

### `examples/phoenix_host/lib/crosswake_example/learn_loop/diagnostics.ex` (utility, transform)

**Analog:** `examples/phoenix_host/lib/crosswake_example/field_service/diagnostics.ex`

**Imports and source-of-truth comment** (lines 1-13):
```elixir
defmodule CrosswakeExample.FieldService.Diagnostics do
  @moduledoc """
  Lane-local Fieldserv route policy diagnostics.

  Compiled router metadata is the source of truth for route ownership.
  """

  alias Crosswake.Policy.RouterMetadata
  alias CrosswakeExample.Router
  alias CrosswakeExample.Showcase.Catalog
```

**Route id allowlist pattern** (lines 14-20):
```elixir
@route_ids [
  "fieldserv-jobs",
  "fieldserv-job",
  "fieldserv-inspection",
  "fieldserv-job-capture",
  "fieldserv-evidence-review"
]
```

**Compiled router metadata extraction pattern** (lines 153-193):
```elixir
def route_policy_rows(router \\ Router) do
  router
  |> compiled_fieldserv_routes()
  |> Enum.sort_by(fn %{policy: policy} ->
    Enum.find_index(@route_ids, &(&1 == policy.id)) || length(@route_ids)
  end)
  |> Enum.map(&route_row/1)
end

defp compiled_fieldserv_routes(router) do
  router
  |> Phoenix.Router.routes()
  |> Enum.flat_map(fn route ->
    with true <- String.starts_with?(route.path, "/fieldserv"),
         {:ok, policy} <- RouterMetadata.fetch(route.metadata) do
      [%{route: route, policy: policy}]
    else
      _other -> []
    end
  end)
end

defp route_row(%{route: route, policy: policy}) do
  %{
    route_id: policy.id,
    path: route.path,
    runtime_owner: policy.runtime,
    offline_posture: policy.offline,
    security_posture: policy.security,
    capabilities: policy.capabilities,
    packs: policy.packs,
    transfers: policy.transfers
  }
  |> Map.merge(enrichment!(policy.id))
end
```

**Apply to LearnLoop:** filter paths with `String.starts_with?(route.path, "/learnloop")`, keep a stable `@route_ids` list, and enrich rows with support labels. Critical labels: `LiveView route`, `Cached read-only`, `Offline island`, `Local-first outbox`, `Backend projection`, `Mocked storefront evidence`.

---

### `examples/phoenix_host/lib/crosswake_example/learn_loop/components.ex` (component, request-response)

**Analog:** `examples/phoenix_host/lib/crosswake_example/field_service/components.ex`

**Phoenix.Component shell pattern** (lines 10-31):
```elixir
use Phoenix.Component

alias CrosswakeExample.FieldService.Diagnostics
alias CrosswakeExample.Showcase.Branding

attr(:page_title, :string, required: true)
attr(:route_id, :string, required: true)
attr(:diagnostics_rows, :list, default: [])
attr(:diagnostics_links, :list, default: [])
attr(:posture_badges, :list, default: [])
slot(:inner_block)

def fieldserv_shell(assigns) do
  assigns =
    assigns
    |> assign(:brand, Branding.brand_for!(:field_service))
    |> assign(:nav_items, nav_items(assigns[:job]))
    |> assign_new(:diagnostics_rows, fn -> Diagnostics.route_policy_rows() end)
    |> assign_new(:diagnostics_links, fn -> Diagnostics.guide_links() end)

  ~H"""
```

**Diagnostics disclosure pattern** (lines 100-152):
```elixir
def diagnostics_panel(assigns) do
  assigns =
    assigns
    |> assign_new(:rows, fn -> Diagnostics.route_policy_rows() end)
    |> assign_new(:guide_links, fn -> Diagnostics.guide_links() end)

  ~H"""
  <details class="fieldserv-diagnostics" data-route-id={@route_id}>
    <summary>
      <span>Route policy diagnostics</span>
      <small>Fieldserv routes only</small>
    </summary>

    <div class="fieldserv-diagnostics-body">
      <div class="fieldserv-diagnostics-table" role="table" aria-label="Fieldserv route policy rows">
        ...
      </div>
    </div>
  </details>
  """
end
```

**Status badge pattern** (lines 210-216):
```elixir
attr(:label, :string, required: true)
attr(:tone, :atom, default: :default)

def status_badge(assigns) do
  ~H"""
  <span class={["fieldserv-status-badge", status_tone_class(@tone)]}>{@label}</span>
  """
end
```

**Apply to LearnLoop:** build a lane-local `learnloop_shell/1`, `status_badge/1`, `progress_strip/1`, `course_path/1`, `pack_manifest/1`, `sync_ledger/1`, `entitlement_badge/1`, and `diagnostics_panel/1`. Do not introduce a generic course UI framework.

---

### `examples/phoenix_host/lib/crosswake_example/learn_loop/dashboard_live.ex` (component, request-response)

**Analog:** `examples/phoenix_host/lib/crosswake_example/field_service/jobs_live.ex`

**LiveView imports and mount pattern** (lines 1-25):
```elixir
defmodule CrosswakeExample.FieldService.JobsLive do
  use Phoenix.LiveView

  alias CrosswakeExample.FieldService.Components
  alias CrosswakeExample.FieldService.Diagnostics
  alias CrosswakeExample.FieldService.Fixtures
  alias CrosswakeExample.FieldService.Jobs
  alias CrosswakeExample.PageTitle

  @impl true
  def mount(_params, _session, socket) do
    job_summaries =
      Jobs.list_jobs()
      |> Enum.map(&job_queue_summary/1)

    {:ok,
     assign(socket,
       page_title: PageTitle.field("Jobs"),
       jobs: job_summaries,
       diagnostics_rows: Diagnostics.route_policy_rows(),
       diagnostics_links: Diagnostics.guide_links()
     )}
  end
```

**Render pattern** (lines 29-92):
```elixir
@impl true
def render(assigns) do
  ~H"""
  <Components.fieldserv_shell
    page_title="Ridgeway job queue"
    route_id="fieldserv-jobs"
    diagnostics_rows={@diagnostics_rows}
    diagnostics_links={@diagnostics_links}
    posture_badges={["LiveView route", "Cached read-only", "Dispatcher queue"]}
  >
    <Components.job_status_strip items={@status_items} />
    <section class="fieldserv-panel" aria-labelledby="fieldserv-jobs-heading">
      ...
    </section>
  </Components.fieldserv_shell>
  """
end
```

**Apply to LearnLoop:** dashboard should mount one learner progress context, next pack, entitlement summary, sync strip, recent history, and diagnostics rows. First viewport should be learner progress and course momentum, not monetization.

---

### `examples/phoenix_host/lib/crosswake_example/learn_loop/course_live.ex` and `pack_live.ex` (component, request-response)

**Analog:** `examples/phoenix_host/lib/crosswake_example/field_service/job_live.ex`

**Route-param load pattern** (lines 22-35):
```elixir
@impl true
def handle_params(%{"id" => job_id}, _uri, socket) do
  job_summary = Jobs.job_summary!(job_id)
  inspection_context = Jobs.inspection_context!(job_id)
  evidence_context = Jobs.evidence_context!(job_id)

  {:noreply,
   assign(socket,
     page_title: PageTitle.field(job_summary.title),
     job_summary: job_summary,
     inspection_context: inspection_context,
     evidence_context: evidence_context
   )}
end
```

**Loading fallback pattern** (lines 37-53):
```elixir
def render(%{job_summary: nil} = assigns) do
  ~H"""
  <Components.fieldserv_shell
    page_title="Fieldserv job"
    route_id="fieldserv-job"
    diagnostics_rows={@diagnostics_rows}
    diagnostics_links={@diagnostics_links}
    posture_badges={["LiveView route", "Cached read-only"]}
  >
    <section class="fieldserv-panel">
      <h2>Job loading</h2>
      <p>Fieldserv job context is loaded by route parameters.</p>
    </section>
  </Components.fieldserv_shell>
  """
end
```

**Action footer pattern** (lines 131-140):
```elixir
<footer class="fieldserv-action-footer">
  <span role="status">{@job_summary.blocker}</span>
  <a class="btn-secondary" href={"/fieldserv/jobs/#{@job_summary.id}/inspection"}>Open inspection</a>
  <a class="btn-primary" href={"/fieldserv/jobs/#{@job_summary.id}/capture"}>Open capture</a>
  <a class="btn-secondary" href={"/fieldserv/jobs/#{@job_summary.id}/evidence/#{@job_summary.evidence_id}/review"}>
    Review evidence
  </a>
</footer>
```

**Apply to LearnLoop:** course/detail routes should load by stable fixture id, show lessons and content-pack metadata, and route users to `/learnloop/study/session` for offline study or `/learnloop/subscription` for gated pressure. Keep offline copy read-only unless on the island.

---

### `examples/phoenix_host/lib/crosswake_example/learn_loop/history_live.ex` (component, request-response/CRUD-read)

**Analog:** `examples/phoenix_host/lib/crosswake_example/local_first/study_history_live.ex`

**Server-confirmed history pattern** (lines 7-35):
```elixir
def mount(_params, _session, socket) do
  events = Study.list_events()
  {:ok, assign(socket, events: events, page_title: PageTitle.learn("Study History"))}
end

def render(assigns) do
  ~H"""
  <div class="study-history">
    <h1>Study History (Cached Read-Only)</h1>
    <p>This lane provides a read-only view of the historically synchronized study events.</p>
    ...
    <span class={"status status-#{event.status}"}>[<%= event.status %>]</span>
    <span class="mutation-id">ID: <%= event.client_mutation_id %></span>
  </div>
  """
end
```

**Apply to LearnLoop:** history/progress must be explicitly server-confirmed and cached read-only. It can summarize `review_events`, progress checkpoints, and rejected events, but must not imply that LiveView history mutates offline.

---

### `examples/phoenix_host/lib/crosswake_example/learn_loop/subscription_live.ex` and `learn_loop/entitlement.ex` (component/service, event-driven)

**Analogs:** `examples/phoenix_host/lib/crosswake_example/paywall_entry_live.ex`, `examples/phoenix_host/lib/crosswake_example/commerce/entitlement_projection.ex`, `examples/phoenix_host/lib/crosswake_example/commerce/mock_storefront.ex`, `examples/phoenix_host/lib/crosswake_example/commerce/mock_backend.ex`

**Paywall imports and subscription topic pattern** (lines 1-31):
```elixir
defmodule CrosswakeExample.PaywallEntryLive do
  use Phoenix.LiveView

  alias CrosswakeExample.PageTitle
  alias Crosswake.Commerce.Contracts

  alias CrosswakeExample.Commerce.{
    MockStorefront,
    ReconciliationInbox,
    MockBackend,
    EntitlementProjection
  }

  @group_id "sub_pro_monthly"
  @default_storefront_adapter MockStorefront

  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(CrosswakeExample.PubSub, "entitlement:" <> @group_id)
    end
    ...
  end
end
```

**Evidence-ingest then backend projection pattern** (lines 35-75):
```elixir
def handle_event("subscribe", _params, socket) do
  intent = %Contracts.PurchaseIntent{
    entry_id: @group_id,
    correlation_id: Ecto.UUID.generate()
  }

  case storefront_adapter().simulate_purchase(intent) do
    {:ok, evidence} ->
      case ReconciliationInbox.ingest_evidence(evidence) do
        {:ok, _attempt} ->
          Phoenix.PubSub.broadcast(CrosswakeExample.PubSub, "entitlement:" <> @group_id, {:entitlement_update, :pending})
          Task.start(fn ->
            :timer.sleep(1_500)
            MockBackend.verify_and_broadcast(evidence, @group_id)
          end)
          {:noreply, socket}
        {:error, _reason} ->
          {:noreply, put_flash(socket, :error, "Something went wrong submitting your purchase. Please try again.")}
      end
    {:error, _reason} ->
      {:noreply, put_flash(socket, :error, "Something went wrong submitting your purchase. Please try again.")}
  end
end
```

**Fail-closed derived state pattern** (EntitlementProjection lines 38-53):
```elixir
def derived_state(%EntitlementSnapshot{} = snapshot) do
  cond do
    snapshot.freshness.state in [:stale, :unknown] ->
      :stale

    snapshot.reconciliation.state in @pending_reconciliation_states ->
      :pending

    granted_snapshot?(snapshot) ->
      :granted

    true ->
      :denied
  end
end
```

**Visible copy pattern** (PaywallEntryLive lines 311-409):
```elixir
defp granted(assigns) do
  ~H"""
  <div class="paywall-state paywall-state--granted" role="status" aria-live="polite">
    <h2>Access active from backend projection</h2>
    <p>Your Pro Monthly access is active after backend entitlement projection.</p>
    <.projection_status derived_state={:granted} />
  </div>
  """
end

defp pending(assigns) do
  ~H"""
  <div class="paywall-state paywall-state--pending" role="status" aria-live="polite">
    <h2>Verifying backend entitlement</h2>
    <p>Purchase or restore evidence was submitted. Access stays closed until backend projection updates.</p>
    <.projection_status derived_state={:pending} />
  </div>
  """
end
```

**No provider SDK pattern** (MockStorefront lines 42-45, 54-88):
```elixir
## No provider-SDK code

This module contains no provider-SDK code. `provider: "mock"` is the only
value ever emitted.

def simulate_purchase(%Contracts.PurchaseIntent{} = intent, opts) do
  %Contracts.ReconciliationEvidence{
    source: :storefront,
    provider: "mock",
    event_kind: "purchase",
    provider_reference: provider_reference(intent.entry_id),
    evidence_ref: evidence_ref(intent.entry_id, "purchase")
  }
end
```

**Apply to LearnLoop:** use learner-facing labels `granted`, `pending`, `stale`, `denied`, but keep access authority backend-owned. Copy must say "Backend projection required", "Access stays closed until backend projection refreshes", and "Mock storefront evidence received"; avoid "subscribed", "unlocked", "purchase succeeded", or live StoreKit/Play Billing/RevenueCat claims.

---

### `examples/phoenix_host/lib/crosswake_example/learn_loop/study_controller.ex` and study HTML files (controller/template, request-response/file-I/O)

**Analogs:** `examples/phoenix_host/lib/crosswake_example_web/controllers/offline_controller.ex`, `examples/phoenix_host/lib/crosswake_example_web/controllers/offline_html.ex`, `examples/phoenix_host/lib/crosswake_example_web/controllers/offline_html/index.html.heex`

**Socketless controller pattern** (OfflineController lines 1-26):
```elixir
defmodule CrosswakeExample.OfflineController do
  use Phoenix.Controller, formats: [:html]

  alias CrosswakeExample.PageTitle
  alias Crosswake.Offline.Contracts

  def index(conn, _params) do
    island =
      Contracts.new_study_session_island(
        "study_session_v1",
        route_id: "study-session",
        sync_seam: "study_reviews",
        storage_budget: {:mb, 50},
        reserve_for_journal: {:mb, 5},
        eviction: :manual
      )

    conn
    |> put_view(CrosswakeExample.OfflineHTML)
    |> put_root_layout(false)
    |> render(:index, page_title: PageTitle.learn("Offline Study"), island: island)
  end
end
```

**Socketless template pattern** (index.html.heex lines 1-8, 74-94):
```heex
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>{@page_title}</title>
    <link rel="stylesheet" href="/css/tokens.css" />
    <!-- Inline styles for the study island - consumes semantic tokens from tokens.css -->
  </head>
  <body
    data-storage-budget={@island.storage_budget}
    data-reserve-for-journal={@island.reserve_for_journal}
    data-eviction-policy={@island.eviction}
  >
    <h1>Offline Study Island</h1>
    <div id="flashcard-container">Loading flashcards...</div>
    <div id="status" aria-live="polite" role="status" aria-atomic="true"></div>
    <script type="module" src="/offline_study.js"></script>
  </body>
</html>
```

**Apply to LearnLoop:** `/learnloop/study/session` must remain controller-rendered and use `put_root_layout(false)`. It must not mount LiveView, must not rely on `phx-click`, and Playwright must prove `window.liveSocket` is absent.

---

### `examples/phoenix_host/priv/static/offline_study.js` (utility, event-driven/file-I/O)

**Analog:** `examples/phoenix_host/priv/static/offline_study.js`

**IndexedDB setup pattern** (lines 3-7, 55-75):
```javascript
const DB_NAME = 'crosswake_offline_study';
const DB_VERSION = 1;
const STORE_CARDS = 'flashcards';
const STORE_MUTATIONS = 'mutations';

function initDB() {
  return new Promise((resolve, reject) => {
    const request = indexedDB.open(DB_NAME, DB_VERSION);
    request.onerror = (event) => reject(event.target.error);
    request.onsuccess = (event) => {
      db = event.target.result;
      resolve();
    };
    request.onupgradeneeded = (event) => {
      const db = event.target.result;
      db.createObjectStore(STORE_CARDS, { keyPath: 'id' });
      db.createObjectStore(STORE_MUTATIONS, { keyPath: 'id', autoIncrement: true });
    };
  });
}
```

**Outbox flush and reconciliation status pattern** (lines 174-236):
```javascript
async function flushOutbox() {
  if (flushing) return;
  flushing = true;
  try {
    const records = await getAllMutations();
    if (records.length === 0) return;

    updateStatus('Syncing...');
    response = await fetch('/study/sync', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        events: records.map(r => ({
          client_mutation_id: r.client_mutation_id,
          card_id: r.card_id,
          rating: r.rating
        }))
      })
    });

    if (response.ok) {
      const data = await response.json();
      const acceptedRecords = (data.data && data.data.accepted_records) || [];
      const acceptedIds = acceptedRecords.map(r => r.client_mutation_id);
      await deleteAcceptedMutations(records, acceptedIds);
      const remaining = await countMutations();
      updateStatus(`Synced ${acceptedIds.length} - queued ${remaining}`);
    }
  } finally {
    flushing = false;
  }
}
```

**Browser-owned mutation pattern** (lines 290-325):
```javascript
async function handleReview(rating) {
  const card = cards[currentCardIndex];

  const mutation = {
    client_mutation_id: crypto.randomUUID(),
    card_id: parseInt(card.id, 10),
    rating: rating
  };

  try {
    await queueMutation(mutation);
    currentCardIndex++;
    renderCurrentCard();

    if (navigator.onLine) {
      flushOutbox();
    }
  } catch (error) {
    if (error && error.name === 'QuotaExceededError') {
      updateStatus('QuotaExceededError handled gracefully.');
    } else {
      updateStatus('Error saving review: ' + (error ? error.message : 'Unknown error'));
    }
  }
}
```

**Apply to LearnLoop:** keep app-generated UUIDs, IndexedDB `flashcards`/`mutations`, visible `Saved locally`/`Queued for replay`/`Syncing`/`Synced N - queued M`/rejected statuses, and reconnect flush. If adding `/learnloop/sync`, make it a URL alias or configurable target that still reaches `LocalFirst.SyncController`.

---

### Sync and review-event files (service/controller/model, event-driven/CRUD)

**Analogs:** `examples/phoenix_host/lib/crosswake_example/local_first/study.ex`, `sync_controller.ex`, `review_event.ex`

**Sync controller validation pattern** (SyncController lines 5-20):
```elixir
def sync(conn, %{"events" => events}) when is_list(events) do
  case Study.sync_events(events) do
    {:ok, result} ->
      json(conn, %{data: result})
    {:error, reason} ->
      conn
      |> put_status(:unprocessable_entity)
      |> json(%{error: to_string(reason)})
  end
end

def sync(conn, _params) do
  conn
  |> put_status(:bad_request)
  |> json(%{error: "invalid payload, expected 'events' list"})
end
```

**Changeset validation pattern** (ReviewEvent lines 15-22):
```elixir
def changeset(review_event, attrs) do
  review_event
  |> cast(attrs, [:client_mutation_id, :card_id, :rating, :status])
  |> validate_required([:client_mutation_id, :card_id, :rating])
  |> validate_inclusion(:rating, ["good", "hard"])
  |> validate_inclusion(:status, ["accepted", "rejected"])
  |> unique_constraint(:client_mutation_id)
end
```

**Idempotent append-only replay pattern** (Study lines 9-51):
```elixir
def sync_events(events_payload) when is_list(events_payload) do
  now = DateTime.utc_now() |> DateTime.truncate(:second)

  {valid, rejections} =
    Enum.reduce(events_payload, {[], []}, fn payload, {valid_acc, rejections_acc} ->
      changeset = ReviewEvent.changeset(%ReviewEvent{}, payload)
      ...
    end)

  Ecto.Multi.new()
  |> Ecto.Multi.insert_all(:sync, ReviewEvent, Enum.reverse(valid),
    on_conflict: :nothing,
    conflict_target: :client_mutation_id,
    returning: true
  )
  |> Repo.transaction()
  |> case do
    {:ok, %{sync: {count, records}}} ->
      serializable = Enum.map(records, fn r ->
        Map.from_struct(r) |> Map.drop([:__meta__])
      end)
      {:ok, %{accepted_count: count, accepted_records: serializable, rejected: Enum.reverse(rejections)}}
    {:error, _, reason, _} ->
      {:error, reason}
  end
end
```

**Apply to LearnLoop:** do not create a second sync implementation. Add `/learnloop/sync` only as a route alias to `CrosswakeExample.LocalFirst.SyncController, :sync` if the product path needs it.

---

### `examples/phoenix_host/lib/crosswake_example/router.ex` (route, request-response)

**Analog:** `examples/phoenix_host/lib/crosswake_example/router.ex`

**Existing `/study/sync` API seam** (lines 122-125):
```elixir
scope "/study", CrosswakeExample.LocalFirst do
  pipe_through([:api])
  post("/sync", SyncController, :sync)
end
```

**Anti-pattern to avoid: LiveView study simulation declared as island** (lines 127-148):
```elixir
live("/session", StudySessionLive,
  crosswake: [
    id: "local-first-study-session",
    runtime: :offline_island,
    offline: :local_first,
    packs: [[id: :daily_study, version: "1.0.0", kind: :content]],
    security: :standard
  ]
)
```

This route currently uses a LiveView module, so it must not become the canonical Phase 151 offline proof unless converted away from LiveView mutation.

**Correct socketless offline route pattern** (lines 165-172):
```elixir
get("/offline", CrosswakeExample.OfflineController, :index,
  crosswake: [
    id: "offline-study",
    runtime: :offline_island,
    offline: :local_first,
    security: :standard
  ]
)
```

**Product lane route group pattern** (Fieldserv lines 305-363):
```elixir
scope "/fieldserv", CrosswakeExample.FieldService do
  pipe_through([:browser])

  crosswake_defaults runtime: :live_view, offline: :cached_read_only, security: :standard do
    live("/jobs", JobsLive,
      crosswake: [
        id: "fieldserv-jobs",
        runtime: :live_view,
        offline: :cached_read_only,
        security: :standard
      ]
    )

    live("/jobs/:id", JobLive,
      crosswake: [
        id: "fieldserv-job",
        runtime: :live_view,
        offline: :cached_read_only,
        security: :standard
      ]
    )
  end
end
```

**Commerce route metadata pattern** (lines 423-433):
```elixir
scope "/commerce", CrosswakeExample do
  pipe_through([:browser])

  crosswake_defaults runtime: :live_view, offline: :unavailable, security: :standard do
    live("/paywall", PaywallEntryLive, :index,
      crosswake: [
        id: "commerce-paywall-entry",
        runtime: :live_view,
        commerce: [corridor: :subscription_default, role: :paywall_entry]
      ]
    )
```

**Apply to LearnLoop:** add `/learnloop`, `/learnloop/courses/:id`, `/learnloop/packs/:id`, `/learnloop/history`, and `/learnloop/subscription` as LiveView routes with `offline: :cached_read_only`. Add `/learnloop/study/session` as a controller route with `runtime: :offline_island`, `offline: :local_first`, and `packs: [[id: :learnloop_daily_pack, version: "...", kind: :content]]`.

---

### Showcase integration files (branding/catalog/hub/reset)

**Analogs:** `showcase/branding.ex`, `showcase/catalog.ex`, `showcase/hub_live.ex`, `showcase/reset.ex`

**LearnLoop brand is already locked** (Branding lines 65-84):
```elixir
learning_training: %{
  id: :learning_training,
  name: "LearnLoop",
  category: "Subscription Learning",
  tagline: "Courses, progress, subscriptions, and offline study loops in one lane.",
  tone: "Polished course progress and offline study",
  theme_class: "showcase-brand-learnloop",
  mark: "LL",
  style_identifier: "violet-teal-learning",
  fixture_brief: %{
    organization: "Brightpath Academy",
    people: ["Iris Learner", "Theo Coach", "Mina Admin"],
    records: ["Daily Elixir Pack", "Offline Review Queue", "Subscription renewal check"],
    pressure: "Offline study state is browser-owned; server reset does not clear IndexedDB."
  }
}
```

**Catalog card pattern to update from proof route to product route** (Catalog lines 75-99):
```elixir
%{
  id: :learning_training,
  heading: "Learning/Training",
  body: "Content packs and offline study without pretending every action commits offline.",
  primary_path: "/offline",
  primary_route_id: "offline-study",
  primary_cta: "Open Offline Study Proof",
  route_posture: %{
    runtime: :offline_island,
    offline: :local_first,
    security: :standard,
    capabilities: []
  },
  runtime_labels: ["Offline island", "Local-first outbox"],
  support_labels: ["Available today", "Proof-backed example"],
  boundary_note: "Offline study state is browser-owned; server reset does not clear IndexedDB."
}
```

For Phase 151, point `primary_path` at `/learnloop` and keep `/offline` as a secondary proof link.

**Hub card render pattern** (HubLive lines 48-105):
```elixir
<section id="showcase-lanes" class="showcase-lane-grid" aria-label="Showcase lanes">
  <article
    :for={lane <- @lanes}
    id={"showcase-lane-#{lane.id}"}
    class={["card", "showcase-lane-card", lane.brand.theme_class]}
    data-brand={lane.brand.name}
    data-style={lane.brand.style_identifier}
  >
    ...
    <a class="btn-secondary showcase-lane-cta" href={lane_href(lane)}>
      <%= lane.primary_cta %>
    </a>
    ...
    <p class="showcase-boundary-warning"><%= lane.boundary_note %></p>
    <p class="showcase-v20-note"><%= lane.v20_pressure_note %></p>
  </article>
</section>
```

**Secondary proof routes pattern** (HubLive lines 117-121):
```elixir
<nav class="showcase-proof-links" aria-label="Proof routes">
  <a class="btn-secondary" href="/offline">View Offline Study Proof</a>
  <a class="btn-secondary" href="/bridge-proof">View Bridge Proof</a>
  <a class="btn-secondary" href="/native/claims">View Native-Pressure Routes</a>
</nav>
```

**Reset browser-owned-state honesty pattern** (Reset lines 5-24):
```elixir
The reset mutates only fixed server-owned resources. Browser-owned IndexedDB
and outbox state remain reset by the Playwright helpers that own browser state.

@browser_state_reset false

def reset! do
  counts = %{
    saas_admin: Fixtures.reset_saas_admin!(),
    field_service: Fixtures.reset_field_service!(),
    learning_training: Flashcards.reset_seed!()
  }

  %{
    counts: counts,
    digest: digest(counts),
    browser_state_reset: @browser_state_reset
  }
end
```

**Apply to LearnLoop:** reset should delegate to LearnLoop/Flashcards helpers, include deterministic breadth counts plus `synced_reviews`, and preserve `browser_state_reset: false`.

---

### `examples/phoenix_host/priv/static/css/app.css` (config, transform)

**Analog:** Fieldserv styles in `examples/phoenix_host/priv/static/css/app.css`

**Existing LearnLoop brand token pattern** (lines 262-267):
```css
.showcase-brand-learnloop {
  --app-accent: #6f52c2;
  --app-ink: #252047;
  --app-highlight: #2f9e9a;
  --app-soft: #f0ecff;
}
```

**Lane-scoped shell pattern** (lines 1015-1033):
```css
.fieldserv-shell {
  --fieldserv-accent: #c96f21;
  --fieldserv-accent-strong: #8d4516;
  --fieldserv-highlight: #f0c541;
  --fieldserv-support: #2f6f73;
  --fieldserv-soft: #fff1df;
  --fieldserv-panel-bg: var(--cw-surface-inset);

  max-width: 1180px;
  margin: 0 auto;
  padding: calc(var(--cw-spacing-base) * 5);
}

.fieldserv-shell,
.fieldserv-shell *,
.fieldserv-shell *::before,
.fieldserv-shell *::after {
  box-sizing: border-box;
}
```

**Accessible badge and panel pattern** (lines 1168-1187, 1257-1267):
```css
.fieldserv-status-strip,
.fieldserv-action-footer {
  display: flex;
  flex-wrap: wrap;
  gap: calc(var(--cw-spacing-base) * 2);
}

.fieldserv-route-badge,
.fieldserv-status-badge {
  display: inline-flex;
  align-items: center;
  min-height: 28px;
  border: 1px solid currentColor;
  border-radius: 999px;
  overflow-wrap: anywhere;
}

.fieldserv-panel,
.fieldserv-evidence-timeline,
.fieldserv-checklist {
  border: 1px solid color-mix(in srgb, var(--fieldserv-accent) 24%, var(--cw-border-default));
  border-radius: 8px;
  background-color: var(--fieldserv-panel-bg);
  padding: calc(var(--cw-spacing-base) * 4);
  min-width: 0;
}
```

**Responsive/focus/reduced-motion pattern** (lines 1450-1523):
```css
.fieldserv-nav-link:focus-visible,
.fieldserv-diagnostics summary:focus-visible,
.fieldserv-diagnostics-links a:focus-visible,
.fieldserv-action-footer a:focus-visible,
.fieldserv-action-footer button:focus-visible {
  ...
}

@media (max-width: 820px) {
  .fieldserv-topbar,
  .fieldserv-page-heading,
  .fieldserv-job-grid,
  .fieldserv-diagnostics-row {
    grid-template-columns: 1fr;
  }
}

@media (prefers-reduced-motion: reduce) {
  .fieldserv-nav-link,
  .fieldserv-diagnostics summary {
    transition: none;
  }
}
```

**Apply to LearnLoop:** add `.learnloop-*` styles scoped to the lane, use violet-teal plus neutrals/status colors, keep card radii 8px or less, provide visible focus and mobile single-column flow, and avoid a one-note purple/blue gradient UI.

---

### ExUnit proof files (tests)

**Analogs:** Fieldserv and showcase tests

**Fixture density contract pattern** (`field_service/fixtures_test.exs` lines 6-27, 94-108):
```elixir
@tag :fieldserv_fixture_density
test "Fieldserv fixture density contract covers jobs, assets, inspection, people, evidence, pressure, and digest" do
  module =
    assert_exported!(
      @fixtures,
      :seed,
      0,
      "Fieldserv fixture density contract requires #{@fixtures}.seed/0"
    )

  data = apply(module, :seed, [])
  jobs = assert_min_list(data, :jobs, 3, "requires at least three realistic jobs")
  ...
  digest_components = apply(digest_module, :digest_components, [])
  assert Enum.all?(digest_components, &String.starts_with?(&1, "field_service."))
end
```

**Diagnostics drift test pattern** (`field_service/diagnostics_test.exs` lines 21-73):
```elixir
test "Fieldserv diagnostics route rows contract derives five Fieldserv rows from compiled router metadata" do
  rows = apply(module, :route_policy_rows, [@router])
  assert Enum.map(rows, & &1.route_id) == @route_ids

  compiled = compiled_route_map()

  for row <- rows do
    compiled_row = Map.fetch!(compiled, row.route_id)
    assert row.path == compiled_row.route.path
    assert row.runtime_owner == compiled_row.policy.runtime
    assert row.offline_posture == compiled_row.policy.offline
    assert row.security_posture == compiled_row.policy.security
    assert normalized(row.capabilities) == normalized(compiled_row.policy.capabilities)
  end
end
```

**LiveView contract pattern** (`field_service/jobs_live_test.exs` lines 7-28):
```elixir
test "Fieldserv jobs LiveView contract renders dense job queue and support truth" do
  {:ok, mounted} = apply(module, :mount, [%{}, %{}, socket()])
  html = render_to_string(module, mounted.assigns)

  assert html =~ "Fieldserv"
  assert html =~ "Ridgeway"
  assert html =~ "LiveView route"
  assert html =~ "Cached read-only"
  assert html =~ "role=\"status\""
  refute html =~ ~r/saved locally|queued for sync|camera bridge|scanner bridge/i
end
```

**Catalog route drift pattern** (`showcase/catalog_test.exs` lines 43-88):
```elixir
test "every card route id and path exists in compiled Crosswake route metadata" do
  compiled = compiled_route_map()

  for card <- Catalog.cards() do
    route_id = Map.fetch!(card, :primary_route_id)
    path = Map.fetch!(card, :primary_path)
    assert Map.has_key?(compiled, route_id)
    %{route: route} = Map.fetch!(compiled, route_id)
    assert route.path == path
  end
end
```

**Reset honesty pattern** (`showcase/reset_test.exs` lines 42-90):
```elixir
test "reset result explicitly does not claim browser-owned offline state reset" do
  result = Reset.reset!()

  assert result.browser_state_reset == false,
         "server reset must return browser_state_reset: false"
end

test "reset counts cover all three showcase lanes without future-domain schemas" do
  result = Reset.reset!()
  assert result.counts.learning_training == %{
    browser_state_reset: false,
    cards: 3,
    decks: 1,
    progress: 0,
    synced_reviews: 0
  }
end
```

**Apply to LearnLoop:** add tests for fixture density, route metadata drift, support-label allowlist, fail-closed entitlement copy, unsupported storefront/native-storage claims, reset digest stability, and no overclaiming of LiveView/offline behavior.

---

### Playwright proof files (tests/utilities)

**Analogs:** `examples/phoenix_host/e2e/offline_sync.spec.ts`, `route_tour.spec.ts`, `e2e/support/offline_route_proof.ts`

**Offline proof pattern** (`offline_sync.spec.ts` lines 17-68):
```typescript
test('offline rating queues in IndexedDB, reconnect via app flush, Ecto confirms one row, duplicate is idempotent', async ({ page, context }) => {
  await page.goto('/offline');
  expect(await page.evaluate(() => !!window.liveSocket)).toBe(false);

  await context.setOffline(true);
  await page.click('#btn-flip');
  await page.click('#btn-good');

  const mutations = await readQueuedOfflineMutations(page);
  expect(mutations).toHaveLength(1);
  assertAppGeneratedMutation(mutations[0]);

  await context.setOffline(false);
  await page.evaluate(() => window.dispatchEvent(new Event('online')));
  await page.waitForResponse(r => r.url().includes('/study/sync') && r.status() === 200);

  await expectSyncedReview(page.request, capturedId);
  await expectOutboxEmpty(page);

  const dupRes = await page.request.post('/study/sync', {
    data: { events: [{ client_mutation_id: capturedId, card_id, rating }] }
  });
  expect(dupBody.data.accepted_count).toBe(0);
});
```

**Browser-owned IndexedDB helper pattern** (`offline_route_proof.ts` lines 10-30, 33-52):
```typescript
export async function resetOfflineStudyDatabase(page: Page) {
  await page.addInitScript(() => {
    indexedDB.deleteDatabase('crosswake_offline_study');
  });
}

export async function readQueuedOfflineMutations(page: Page): Promise<OfflineMutationRecord[]> {
  return page.evaluate(() => {
    return new Promise((resolve, reject) => {
      const req = indexedDB.open('crosswake_offline_study', 1);
      ...
    });
  });
}

export function assertAppGeneratedMutation(record: OfflineMutationRecord) {
  expect(typeof record.client_mutation_id).toBe('string');
  expect(record.client_mutation_id).toMatch(/^[0-9a-f-]{36}$/);
  expect(record.rating).toMatch(/^(good|hard)$/);
}
```

**Route-tour semantic-first pattern** (`route_tour.spec.ts` lines 27-49, 242-278):
```typescript
test('proves LiveView, bounded bridge, offline island, and native-owned fallback route semantics before screenshots', async ({ page, context }) => {
  await proveShowcaseHub(page);
  await proveSaasRoute(page);
  await proveAdminPilotApprovalFlow(page);
  await proveFieldservRoute(page);
  await proveOfflineRoute(page, context);
  await captureRouteScreenshot(page, 'offline-study-replayed.png');
});

async function proveOfflineRoute(page: Page, context: BrowserContext) {
  await page.goto('/offline');
  expect(await page.evaluate(() => !!window.liveSocket)).toBe(false);
  await context.setOffline(true);
  await page.click('#btn-flip');
  await page.click('#btn-good');
  const mutations = await readQueuedOfflineMutations(page);
  assertAppGeneratedMutation(mutations[0]);
  await context.setOffline(false);
  await page.evaluate(() => window.dispatchEvent(new Event('online')));
  await expectSyncedReview(page.request, mutations[0].client_mutation_id);
}
```

**Apply to LearnLoop:** route tour must exercise hub -> `/learnloop` -> course or pack detail -> gated lesson/subscription pressure -> `/learnloop/study/session` -> reconnect sync -> history/progress -> diagnostics. Assertions come before screenshots. Add `window.liveSocket === false`, IndexedDB queue, app-generated UUID, exactly-one Ecto row, duplicate replay idempotency, fail-closed entitlement copy, and support labels.

## Shared Patterns

### Phoenix-First Route Ownership
**Source:** `examples/phoenix_host/lib/crosswake_example/router.ex`
**Apply to:** all `/learnloop/*` routes

LiveView shell routes should copy Fieldserv's `crosswake_defaults runtime: :live_view, offline: :cached_read_only` pattern. Only the study session controller should declare `runtime: :offline_island` and `offline: :local_first`.

### Browser-Owned Offline State
**Source:** `examples/phoenix_host/lib/crosswake_example/showcase/reset.ex`, `examples/phoenix_host/e2e/support/offline_route_proof.ts`
**Apply to:** reset, study island, Playwright specs

Server reset must keep `browser_state_reset: false`. Browser tests clear IndexedDB with `resetOfflineStudyDatabase/1`; Phoenix reset code must not claim to clear browser state.

### Idempotent Review Replay
**Source:** `examples/phoenix_host/lib/crosswake_example/local_first/study.ex`, `review_event.ex`
**Apply to:** `/study/sync`, optional `/learnloop/sync`, route-tour assertions

Use `ReviewEvent.changeset/2`, `Ecto.Multi.insert_all`, `on_conflict: :nothing`, and `conflict_target: :client_mutation_id`. Do not add a separate sync implementation for LearnLoop.

### Backend-Owned Entitlement Projection
**Source:** `examples/phoenix_host/lib/crosswake_example/commerce/entitlement_projection.ex`, `mock_storefront.ex`, `mock_backend.ex`
**Apply to:** `learn_loop/entitlement.ex`, `subscription_live.ex`, gated lesson/paywall UI

Storefront evidence is evidence only. Backend projection grants access. Pending/stale/denied states must fail closed and use support-truth copy.

### Lane-Local Components and CSS
**Source:** `examples/phoenix_host/lib/crosswake_example/field_service/components.ex`, `priv/static/css/app.css`
**Apply to:** LearnLoop shell, dashboard/detail/history/subscription routes

Use lane-scoped components/classes, token-backed CSS, visible focus, 44px mobile actions, no horizontal overflow, and compact diagnostics. Do not create a generic LMS UI framework.

### Semantic-First Proof
**Source:** `examples/phoenix_host/e2e/route_tour.spec.ts`
**Apply to:** route tour and offline specs

Screenshots are collateral after assertions prove route owner, socket absence, IndexedDB queueing, idempotent replay, entitlement fail-closed copy, diagnostics, support labels, and no unsupported claims.

## No Analog Found

No required file lacks a close analog. The planner should not add broad LMS schemas, generic sync helpers, native storage layers, live commerce adapters, or `crosswake_dashboard` files in Phase 151. If it chooses a narrow entitlement snapshot table, use Fieldserv's narrow persisted-evidence pattern rather than creating catalog/course/subscription persistence.

## Metadata

**Analog search scope:** `examples/phoenix_host/lib/crosswake_example`, `examples/phoenix_host/lib/crosswake_example_web`, `examples/phoenix_host/test/crosswake_example`, `examples/phoenix_host/e2e`, `examples/phoenix_host/priv/static/css/app.css`, `examples/phoenix_host/priv/static/offline_study.js`

**Files scanned:** 100+ via `rg --files` plus targeted route/CSS/test searches

**Pattern extraction date:** 2026-07-11

**Project skills:** no repo-local `.codex/skills` or `.agents/skills` `SKILL.md` files found

**Guardrails preserved:** Phoenix-first route-policy/runtime-contract thesis; offline study is socketless/browser-owned when declared `runtime: :offline_island`; no broad LMS, generic sync engine, production commerce adapter, or native-storage scope.
