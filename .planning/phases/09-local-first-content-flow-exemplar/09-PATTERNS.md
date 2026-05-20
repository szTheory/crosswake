# Phase 9: Local-First Content Flow Exemplar - Pattern Map

**Mapped:** 2026-05-18
**Files analyzed:** 6
**Analogs found:** 5 / 6

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `examples/phoenix_host/lib/crosswake_example/router.ex` | router | request-response | `examples/phoenix_host/lib/crosswake_example/router.ex` | exact |
| `examples/phoenix_host/lib/crosswake_example/local_first/study_session_live.ex` | controller (LiveView) | request-response | `examples/phoenix_host/lib/crosswake_example/saas_portal/approvals_live.ex` | role-match |
| `examples/phoenix_host/lib/crosswake_example/local_first/study_history_live.ex` | controller (LiveView) | request-response | `examples/phoenix_host/lib/crosswake_example/selective_native/submission_review_live.ex` | role-match |
| `examples/phoenix_host/lib/crosswake_example_web/controllers/sync_controller.ex` | controller (API) | batch/sync | N/A | none |
| `examples/phoenix_host/lib/crosswake_example/local_first/study.ex` | context | CRUD / event-driven | `examples/phoenix_host/lib/crosswake_example/selective_native/claims.ex` | role-match |
| `examples/phoenix_host/lib/crosswake_example/local_first/review_event.ex` | model (Ecto) | event-driven | `examples/phoenix_host/lib/crosswake_example/selective_native/claim.ex` | exact |

## Pattern Assignments

### `examples/phoenix_host/lib/crosswake_example/router.ex` (router, request-response)

**Analog:** `examples/phoenix_host/lib/crosswake_example/router.ex`

**Routing Scope and Pipeline pattern** (lines 43-44, 98-99):
```elixir
  scope "/native", CrosswakeExample.SelectiveNative do
    pipe_through [:browser]
```

**Crosswake metadata pattern (cached)** (lines 53-59):
```elixir
        live "/dashboard", DashboardLive,
          crosswake: [
            id: "saas-dashboard",
            runtime: :live_view,
            offline: :cached_read_only,
            security: :standard
          ]
```

**Crosswake metadata pattern (island with packs)** (lines 130-136, combined from `library` and `claim_capture`):
```elixir
        live "/study-session", StudySessionLive,
          crosswake: [
            id: "local-study-session",
            runtime: :live_view,
            offline: :island,
            packs: [[id: :daily_study, version: "1.0.0", kind: :content]],
            security: :standard
          ]
```

---

### `examples/phoenix_host/lib/crosswake_example/local_first/study_session_live.ex` (LiveView, request-response)

**Analog:** `examples/phoenix_host/lib/crosswake_example/saas_portal/approvals_live.ex`

**LiveView structural pattern** (lines 1-13):
```elixir
defmodule CrosswakeExample.SaaSPortal.ApprovalsLive do
  use Phoenix.LiveView

  alias CrosswakeExample.SaaSPortal.Approvals

  @impl true
  def mount(_params, _session, socket) do
    approvals = Approvals.list_approvals(socket.assigns.current_saas_account.id)
    # For Phase 9, this would load the daily_study pack details for the island
```

---

### `examples/phoenix_host/lib/crosswake_example/local_first/study_history_live.ex` (LiveView, request-response)

**Analog:** `examples/phoenix_host/lib/crosswake_example/selective_native/submission_review_live.ex`

**Explicit review/conflict UI pattern** (lines 28-36):
```elixir
      <div class="evidence-status">
        <p>Claim Status: <span class="status"><%= @claim.status %></span></p>
      </div>

      <div class="actions">
        <%= if @submission.status == "staged" do %>
          <button phx-click="prepare_upload" class="button primary">
            Upload Evidence
          </button>
```

---

### `examples/phoenix_host/lib/crosswake_example/local_first/study.ex` (context, event-driven)

**Analog:** `examples/phoenix_host/lib/crosswake_example/selective_native/claims.ex`

**Ecto Repository pattern** (lines 1-11):
```elixir
defmodule CrosswakeExample.SelectiveNative.Claims do
  alias CrosswakeExample.Repo
  alias CrosswakeExample.SelectiveNative.Claim

  def list_claims do
    Repo.all(Claim)
  end
```

---

### `examples/phoenix_host/lib/crosswake_example/local_first/review_event.ex` (model, event-driven)

**Analog:** `examples/phoenix_host/lib/crosswake_example/selective_native/claim.ex`

**Ecto Schema pattern** (lines 1-15):
```elixir
defmodule CrosswakeExample.SelectiveNative.Claim do
  use Ecto.Schema
  import Ecto.Changeset

  schema "selective_native_claims" do
    field :title, :string
    field :status, :string, default: "pending"
    
    timestamps()
  end

  def changeset(claim, attrs) do
    claim
    |> cast(attrs, [:title, :status])
    |> validate_required([:title, :status])
  end
end
```

---

## Shared Patterns

### Syncing Events
**Source:** `09-RESEARCH.md`
**Apply to:** `/study-session/sync` API Controller (New)
The project lacks a direct analog for sync controllers. Following the research file:
```elixir
# The controller should accept an array of review_events from the outbox
# and use Ecto.Multi to append to a journal and recompute progress.
```

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `examples/phoenix_host/lib/crosswake_example_web/controllers/sync_controller.ex` | API Controller | batch | Crosswake example does not currently have an explicit API endpoint for outbox synchronization. Planner should create a standard Phoenix controller that handles Ecto.Multi inserts based on RESEARCH.md. |

## Metadata

**Analog search scope:** `examples/phoenix_host/lib/`
**Files scanned:** ~25
**Pattern extraction date:** 2026-05-18