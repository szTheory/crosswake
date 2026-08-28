# Phase 149: SaaS/Admin Showcase - Pattern Map

**Mapped:** 2026-07-10
**Files analyzed:** 26 core/likely files plus 4 optional persistence files
**Analogs found:** 25 / 26 core files

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `examples/phoenix_host/lib/crosswake_example/saas_portal/fixtures.ex` | utility/fixture | batch, transform | `examples/phoenix_host/lib/crosswake_example/saas_portal/fixtures.ex` | exact |
| `examples/phoenix_host/lib/crosswake_example/saas_portal/accounts.ex` | service/context | request-response, read CRUD | `examples/phoenix_host/lib/crosswake_example/saas_portal/accounts.ex` | exact |
| `examples/phoenix_host/lib/crosswake_example/saas_portal/approvals.ex` | service/context | CRUD, authorization | `examples/phoenix_host/lib/crosswake_example/saas_portal/approvals.ex` | exact |
| `examples/phoenix_host/lib/crosswake_example/saas_portal/diagnostics.ex` | utility/service | transform, request-response | `examples/phoenix_host/lib/crosswake_example/showcase/catalog.ex` + `test/.../showcase/catalog_test.exs` | role-match |
| `examples/phoenix_host/lib/crosswake_example/saas_portal/components.ex` | component | request-response rendering | `examples/phoenix_host/lib/crosswake_example/showcase/hub_live.ex` | role-match |
| `examples/phoenix_host/lib/crosswake_example/saas_portal/dashboard_live.ex` | component/LiveView | request-response | `examples/phoenix_host/lib/crosswake_example/saas_portal/dashboard_live.ex` | exact |
| `examples/phoenix_host/lib/crosswake_example/saas_portal/approvals_live.ex` | component/LiveView | request-response list | `examples/phoenix_host/lib/crosswake_example/saas_portal/approvals_live.ex` | exact |
| `examples/phoenix_host/lib/crosswake_example/saas_portal/approval_live.ex` | component/LiveView | event-driven, request-response | `examples/phoenix_host/lib/crosswake_example/saas_portal/approval_live.ex` | exact |
| `examples/phoenix_host/lib/crosswake_example/saas_portal/account_live.ex` | component/LiveView | request-response | `examples/phoenix_host/lib/crosswake_example/saas_portal/account_live.ex` | exact |
| `examples/phoenix_host/lib/crosswake_example/saas_portal/settings_live.ex` | component/LiveView | request-response, auth posture | `examples/phoenix_host/lib/crosswake_example/saas_portal/settings_live.ex` | exact |
| `examples/phoenix_host/lib/crosswake_example/saas_portal/admin_access_live.ex` | component/LiveView | request-response, auth denial | `examples/phoenix_host/lib/crosswake_example/saas_portal/admin_access_live.ex` | exact |
| `examples/phoenix_host/lib/crosswake_example/saas_portal/auth.ex` | middleware/utility | request-response, session | `examples/phoenix_host/lib/crosswake_example/saas_portal/auth.ex` | exact |
| `examples/phoenix_host/lib/crosswake_example/saas_portal/on_mount.ex` | hook/middleware | request-response, session assignment | `examples/phoenix_host/lib/crosswake_example/saas_portal/on_mount.ex` | exact |
| `examples/phoenix_host/lib/crosswake_example/showcase/fixtures.ex` | utility/reset | batch | `examples/phoenix_host/lib/crosswake_example/showcase/fixtures.ex` | exact |
| `examples/phoenix_host/lib/crosswake_example/showcase/reset.ex` | utility/orchestrator | batch | `examples/phoenix_host/lib/crosswake_example/showcase/reset.ex` | exact |
| `examples/phoenix_host/lib/crosswake_example/showcase/catalog.ex` | utility/catalog | transform | `examples/phoenix_host/lib/crosswake_example/showcase/catalog.ex` | exact |
| `examples/phoenix_host/priv/static/css/app.css` | config/style | transform, responsive rendering | `examples/phoenix_host/priv/static/css/app.css` | exact |
| `examples/phoenix_host/test/crosswake_example/saas_portal/fixtures_test.exs` | test | batch, transform | `examples/phoenix_host/test/crosswake_example/showcase/reset_test.exs` | role-match |
| `examples/phoenix_host/test/crosswake_example/saas_portal/diagnostics_test.exs` | test | transform | `examples/phoenix_host/test/crosswake_example/showcase/catalog_test.exs` | exact |
| `examples/phoenix_host/test/crosswake_example/saas_portal/approvals_test.exs` | test | CRUD, authorization | `examples/phoenix_host/test/crosswake_example/showcase/reset_test.exs` + `selective_native/claims.ex` | role-match |
| `examples/phoenix_host/test/crosswake_example/saas_portal/approvals_live_test.exs` | test | event-driven LiveView | `examples/phoenix_host/test/crosswake_example/bridge_proof_live_test.exs` | partial |
| `examples/phoenix_host/test/crosswake_example/showcase/catalog_test.exs` | test | transform, drift proof | `examples/phoenix_host/test/crosswake_example/showcase/catalog_test.exs` | exact |
| `examples/phoenix_host/test/crosswake_example/showcase/reset_test.exs` | test | batch, idempotency | `examples/phoenix_host/test/crosswake_example/showcase/reset_test.exs` | exact |
| `examples/phoenix_host/test/crosswake_example/page_title_test.exs` | test | request-response | `examples/phoenix_host/test/crosswake_example/page_title_test.exs` | exact |
| `examples/phoenix_host/e2e/route_tour.spec.ts` | test | request-response browser tour | `examples/phoenix_host/e2e/route_tour.spec.ts` | exact |
| Optional `saas_portal/approval.ex`, `activity_event.ex`, and migration(s) | model/migration | CRUD, batch | `selective_native/claim.ex`, `step_up_audit_event.ex`, repo migrations | role-match |

## Pattern Assignments

### SaaS Fixtures And Read Contexts

**Apply to:** `saas_portal/fixtures.ex`, `accounts.ex`, static parts of `approvals.ex`, fixture-density tests.

**Analog:** `examples/phoenix_host/lib/crosswake_example/saas_portal/fixtures.ex`

**Imports and deterministic data pattern** (lines 1-12, 14-29, 31-64):

```elixir
defmodule CrosswakeExample.SaaSPortal.Fixtures do
  @moduledoc """
  Minimal host-owned SaaS fixtures for the Phase 7 example lane.
  """

  @account %{
    id: "acct-north",
    name: "Northwind Workspace",
    health: :steady,
    renewal_window: "14 days",
    open_approvals: 2
  }

  @users [
    %{
      id: "member-1",
      name: "Marta Member",
      email: "marta@example.crosswake.invalid",
      role: :member,
      account_id: @account.id
    },
    %{
      id: "approver-1",
      name: "Alex Approver",
      email: "alex@example.crosswake.invalid",
      role: :approver,
      account_id: @account.id
    }
  ]

  def seed do
    %{account: @account, users: @users, approvals: @approvals}
  end

  def account, do: @account
  def users, do: @users
  def approvals, do: @approvals
```

**Context read pattern** from `accounts.ex` (lines 6-18):

```elixir
alias CrosswakeExample.SaaSPortal.Fixtures

def get_account!(id) when is_binary(id) do
  account = Fixtures.account()

  if account.id == id do
    account
  else
    raise ArgumentError, "unknown SaaS account: #{inspect(id)}"
  end
end

def get_account_for_user!(%{account_id: account_id}), do: get_account!(account_id)
```

**Planner notes:**
- Expand deterministic maps for account, team, members, roles, settings, operational records, route posture, and activity.
- Keep reset deterministic. If approval/activity persistence is added, only mutable approval/activity rows should use Ecto.
- Update stale "Phase 7" moduledocs while touching these modules.

### Approval Context And Server Authority

**Apply to:** `saas_portal/approvals.ex`, `approval_live.ex`, `approvals_test.exs`, optional persisted approval/activity rows.

**Analog:** `examples/phoenix_host/lib/crosswake_example/saas_portal/approvals.ex`

**Imports and authorization pattern** (lines 6-27):

```elixir
alias CrosswakeExample.SaaSPortal.Auth
alias CrosswakeExample.SaaSPortal.Fixtures

def list_approvals(account_id) when is_binary(account_id) do
  Fixtures.approvals()
  |> Enum.filter(&(&1.account_id == account_id))
end

def get_approval!(id) when is_binary(id) do
  Enum.find(Fixtures.approvals(), &(&1.id == id)) ||
    raise ArgumentError, "unknown SaaS approval: #{inspect(id)}"
end

def approve(%{account_id: account_id} = approval, %{account_id: account_id} = user) do
  if Auth.approver?(user) do
    {:ok, %{approval | status: :approved, reviewed_by: user.id}}
  else
    {:error, :forbidden}
  end
end

def approve(_approval, _user), do: {:error, :forbidden}
```

**Mutable Ecto context analog if persistence is chosen:** `selective_native/claims.ex` (lines 1-33):

```elixir
defmodule CrosswakeExample.SelectiveNative.Claims do
  alias CrosswakeExample.Repo
  alias CrosswakeExample.SelectiveNative.Claim

  def list_claims do
    Repo.all(Claim)
  end

  def get_claim!(id), do: Repo.get!(Claim, id)

  def create_claim(attrs \\ %{}) do
    %Claim{}
    |> Claim.changeset(attrs)
    |> Repo.insert()
  end

  def mark_uploaded(%Claim{} = claim, _attrs \\ %{}) do
    claim
    |> Claim.changeset(%{status: "uploaded"})
    |> Repo.update()
  end
end
```

**Planner notes:**
- Context functions should accept current user/account or an explicit scope-like map, not user-supplied account params from templates.
- Return `{:ok, value}` / `{:error, :forbidden}` for action outcomes. LiveViews render outcomes; they do not own authorization.
- If persistence is planned, use a tiny approval status row and activity/audit row. Avoid persisting static account/team/settings breadth.

### LiveView Event And Haptics Pattern

**Apply to:** `approval_live.ex`, `approvals_live_test.exs`, route-tour approval happy path.

**Analog:** `examples/phoenix_host/lib/crosswake_example/saas_portal/approval_live.ex`

**Mount and handle_params pattern** (lines 12-33):

```elixir
@impl true
def mount(_params, _session, socket) do
  {:ok,
   assign(socket,
     page_title: PageTitle.admin("Approval Detail"),
     approval: nil,
     approval_notice: nil,
     approval_error: nil,
     bridge_request: nil
   )}
end

@impl true
def handle_params(%{"id" => approval_id}, _uri, socket) do
  approval = Approvals.get_approval!(approval_id)

  {:noreply,
   assign(socket,
     approval: approval,
     page_title: PageTitle.admin(approval.title)
   )}
end
```

**Server-authoritative event pattern** (lines 36-58):

```elixir
@impl true
def handle_event("approve", _params, socket) do
  approval = socket.assigns.approval
  user = socket.assigns.current_saas_user

  case Approvals.approve(approval, user) do
    {:ok, approved} ->
      {:noreply,
       assign(socket,
         approval: approved,
         approval_notice: "Approval confirmed by #{user.name}. Phoenix remains the authority.",
         approval_error: nil,
         bridge_request: haptics_request(approved.id)
       )}

    {:error, :forbidden} ->
      {:noreply,
       assign(socket,
         approval_notice: nil,
         approval_error: "Approver role required at the action boundary.",
         bridge_request: nil
       )}
  end
end
```

**Post-success bounded bridge pattern** (lines 101-130):

```elixir
defp haptics_request(approval_id) do
  %{
    "protocol" => @bridge_protocol,
    "version" => @bridge_capability_version,
    "command" => "haptics.impact",
    "capability" => "haptics.impact",
    "route_id" => @bridge_route_id,
    "active_route_id" => @bridge_route_id,
    "origin" => @shell_origin,
    "native_runtime_version" => "1.0.0",
    "correlation_id" => "approval-haptics-#{approval_id}",
    "capabilities" => %{"haptics.impact" => @bridge_capability_version},
    "installed_packs" => %{},
    "payload" => %{"style" => "light"}
  }
end
```

**Planner notes:**
- Keep haptics after successful Phoenix approval only.
- Missing haptics should not fail the approval path. Render support truth separately from mutation success.
- Add disabled/loading/success states in HEEx around the existing `phx-click="approve"` action.

### Auth, Session, And Admin Denial Boundaries

**Apply to:** `auth.ex`, `on_mount.ex`, `settings_live.ex`, `admin_access_live.ex`, diagnostics posture badges.

**Analogs:** `auth.ex`, `on_mount.ex`, `admin_access_live.ex`

**Plug/session assignment pattern** from `auth.ex` (lines 16-22, 65-76):

```elixir
def call(conn, :fetch_current_user) do
  user = current_user(conn)

  conn
  |> assign(:current_saas_user, user)
  |> assign(:current_saas_account, Accounts.get_account_for_user!(user))
end

def current_user(conn) do
  conn
  |> get_session(@session_key, Fixtures.user!(:member).id)
  |> current_user_from_session()
end

def approver?(%{role: :approver}), do: true
def approver?(_user), do: false
```

**LiveView on_mount pattern** from `on_mount.ex` (lines 10-23):

```elixir
def on_mount(:require_authenticated_member, _params, session, socket) do
  user =
    session
    |> Map.get(Auth.session_key(), "member-1")
    |> Auth.current_user_from_session()

  socket =
    socket
    |> Component.assign(:current_saas_user, user)
    |> Component.assign(:current_saas_account, Accounts.get_account_for_user!(user))
    |> Component.assign(:saas_role, user.role)

  {:cont, socket}
end
```

**Admin denial proof pattern** from `admin_access_live.ex` (lines 7-19, 49-51):

```elixir
def mount(_params, _session, socket) do
  {:ok,
   assign(socket,
     page_title: PageTitle.admin("Admin Member Access"),
     proof_state: :blocked,
     route_id: "saas-admin-member-access",
     runtime_owner: "Phoenix LiveView",
     offline_policy: "unavailable",
     required_auth: "MFA, strict recent",
     session_source: "persistent native session",
     decision: "step_up_required",
     audit_ref: "support:admin-access"
   )}
end

<p role="status">
  Persistent shell session does not grant admin authority.
</p>
```

**Planner notes:**
- Preserve Plug/session/on_mount boundaries. Do not move session derivation or recent-auth checks into templates.
- Use calm UI text: name what happened, what owns the decision, and what to do next.
- Keep `saas-admin-member-access` as the explicit blocked proof state.

### Route Policy Metadata And Diagnostics

**Apply to:** new `saas_portal/diagnostics.ex`, `components.ex` diagnostics panel, `diagnostics_test.exs`, `catalog_test.exs`.

**Analogs:** `router.ex`, `showcase/catalog.ex`, `showcase/catalog_test.exs`

**SaaS route policy source** from `router.ex` (lines 207-278):

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

      live("/approvals/:id", ApprovalLive,
        crosswake: [
          id: "saas-approval",
          runtime: :live_view,
          entry: :external,
          capabilities: ["haptics.impact"],
          offline: :cached_read_only,
          security: :standard
        ]
      )

      live("/admin/member-access", AdminAccessLive,
        crosswake: [
          id: "saas-admin-member-access",
          runtime: :live_view,
          entry: :internal_only,
          auth_min_level: :mfa,
          requires_recent_auth: 300,
          auth_posture: :strict_recent,
          offline: :unavailable,
          security: :sensitive
        ]
      )
    end
  end
end
```

**Catalog truth boundary** from `showcase/catalog.ex` (lines 1-18):

```elixir
defmodule CrosswakeExample.Showcase.Catalog do
  @moduledoc """
  Curated route-card metadata for the example-host showcase hub.

  The catalog owns product copy and visible labels only. Crosswake route policy
  remains authoritative through compiled router metadata.
  """

  alias CrosswakeExample.Showcase.Branding

  @allowed_support_labels [
    "Available today",
    "Proof-backed example",
    "Demo pressure",
    "Advisory evidence",
    "Future gap",
    "Next-pack candidate"
  ]
```

**Compiled metadata drift-test pattern** from `catalog_test.exs` (lines 43-58, 68-88, 111-127):

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

defp compiled_route_map do
  CrosswakeExample.Router
  |> Phoenix.Router.routes()
  |> Enum.reduce(%{}, fn route, acc ->
    case RouterMetadata.fetch(route.metadata) do
      {:ok, policy} -> Map.put(acc, policy.id, %{route: route, policy: policy})
      :error -> acc
    end
  end)
end

defp normalized_capabilities(capabilities) do
  capabilities
  |> List.wrap()
  |> Enum.map(&to_string/1)
  |> MapSet.new()
end
```

**Planner notes:**
- Diagnostics rows should derive path, route id, runtime, offline, entry, auth posture, security, and capabilities from compiled router metadata.
- A lane-local catalog may own labels, rough edges, and guide links, but tests must compare it to `RouterMetadata.fetch/1`.
- Do not add a dedicated inspector route in Phase 149.

### AdminPilot Components And CSS

**Apply to:** new `saas_portal/components.ex`, all SaaS LiveViews, `app.css`.

**Analogs:** `showcase/hub_live.ex`, `app.css`, `showcase/branding.ex`

**Product shell/render pattern** from `hub_live.ex` (lines 24-45, 84-104):

```elixir
<main class="showcase-shell">
  <header class="showcase-brandbar" aria-label={@parent_brand.name}>
    <picture>
      <source srcset={@parent_brand.logo_dark_path} media="(prefers-color-scheme: dark)" />
      <img
        class="showcase-crosswake-logo"
        src={@parent_brand.logo_path}
        alt="Crosswake"
        width="260"
        height="70"
      />
    </picture>
    <p><%= @parent_brand.eyebrow %></p>
  </header>

  <section class="showcase-intro" aria-labelledby="showcase-heading">
    <p class="showcase-kicker"><%= @parent_brand.name %></p>
    <div class="showcase-intro-copy">
      <h1 id="showcase-heading"><%= @parent_brand.headline %></h1>
      <p><%= @parent_brand.deck %></p>
    </div>
  </section>

  <div class="showcase-badge-row" aria-label={"#{lane.heading} runtime and support labels"}>
    <span :for={label <- lane.runtime_labels} class={["badge", "showcase-badge", badge_class(label)]}>
      <%= label %>
    </span>
  </div>
</main>
```

**Badge helper pattern** from `hub_live.ex` (lines 132-151):

```elixir
defp badge_class(label) do
  cond do
    label =~ "LiveView" -> "showcase-badge-liveview"
    label =~ "Offline" or label =~ "Local-first" or label =~ "Cached" -> "showcase-badge-offline"
    label =~ "Native" or label =~ "native" -> "showcase-badge-native"
    label =~ "Proof" -> "showcase-badge-bridge"
    label =~ "Future" or label =~ "Demo" or label =~ "Sensitive" -> "showcase-badge-sensitive"
    true -> "showcase-badge-support"
  end
end
```

**AdminPilot brand source** from `showcase/branding.ex` (lines 22-41):

```elixir
saas_admin: %{
  id: :saas_admin,
  name: "AdminPilot",
  category: "SaaS/Admin",
  tagline: "Approvals, roles, and account health for teams that run on Phoenix.",
  tone: "Refined enterprise control room",
  theme_class: "showcase-brand-adminpilot",
  mark: "AP",
  style_identifier: "ledger-green-ops",
  fixture_brief: %{
    organization: "Northwind Workspace",
    people: ["Marta Member", "Alex Approver", "Priya Owner"],
    records: [
      "Quarterly spend increase",
      "Vendor access renewal",
      "Contract archive export"
    ],
    activity: ["2 approvals pending", "14-day renewal window", "1 role change staged"],
    pressure: "Auth-sensitive admin posture stays Phoenix-owned."
  }
}
```

**CSS selectors to reuse/extend** from `app.css`:

```css
/* lines 54-78 */
.btn-primary {
  box-sizing: border-box;
  background-color: var(--cw-action-bg);
  color: var(--cw-action-fg);
  border: none;
  border-radius: var(--cw-radius-md);
  padding: calc(var(--cw-spacing-base) * 2) calc(var(--cw-spacing-base) * 4);
  display: inline-flex;
  align-items: center;
  justify-content: center;
}

.btn-primary:focus-visible {
  outline: var(--cw-focus-ring-width) solid var(--cw-action-focus-ring);
  outline-offset: 2px;
}

/* lines 100-111 */
.badge {
  display: inline-block;
  padding: calc(var(--cw-spacing-base) * 1) calc(var(--cw-spacing-base) * 2);
  border-radius: var(--cw-radius-sm);
  font-size: var(--cw-text-scale-xs);
  font-weight: 500;
}

/* lines 208-212 */
.showcase-primary-cta,
.showcase-lane-cta,
.showcase-proof-links .btn-secondary {
  min-height: 44px;
}

/* lines 248-253 */
.showcase-brand-adminpilot {
  --app-accent: #2f6f73;
  --app-ink: #14213d;
  --app-highlight: #d6a34a;
  --app-soft: #eaf3f2;
}
```

**Planner notes:**
- Prefer a lane-specific AdminPilot shell/component module over broad reusable framework components.
- Use dense admin affordances: KPI strip, approval list/detail, role/member summary, activity feed, posture badges, diagnostics disclosure.
- Extend CSS with AdminPilot-specific selectors, but keep tokens, focus rings, 44px preferred tap targets, dark mode, mobile single-column, and reduced-motion behavior.

### Showcase Reset And Digest

**Apply to:** `showcase/fixtures.ex`, `showcase/reset.ex`, `reset_test.exs`, E2E reset controller test.

**Analogs:** `showcase/reset.ex`, `showcase/fixtures.ex`, `showcase/reset_test.exs`

**Reset orchestration pattern** from `showcase/reset.ex` (lines 15-27, 29-41):

```elixir
def reset! do
  counts = %{
    saas_admin: Fixtures.reset_saas_admin!(),
    field_service_native_pressure: NativeFixtures.seed(),
    learning_training: Flashcards.reset_seed!()
  }

  %{
    counts: counts,
    digest: digest(counts),
    browser_state_reset: @browser_state_reset
  }
end

defp digest(counts) do
  [
    "browser_state_reset=#{@browser_state_reset}",
    count_components(counts),
    Fixtures.saas_admin_digest_components(),
    NativeFixtures.digest_components(),
    Flashcards.seed_digest_components()
  ]
  |> List.flatten()
  |> Enum.join("|")
  |> then(&:crypto.hash(:sha256, &1))
  |> Base.encode16(case: :lower)
end
```

**SaaS count/digest pattern** from `showcase/fixtures.ex` (lines 11-33):

```elixir
def reset_saas_admin! do
  data = SaaSFixtures.seed()

  %{
    accounts: 1,
    users: length(data.users),
    approvals: length(data.approvals)
  }
end

def saas_admin_digest_components do
  data = SaaSFixtures.seed()

  [
    "saas_admin.account:#{data.account.id}:#{data.account.name}:#{data.account.health}",
    data.users
    |> Enum.sort_by(& &1.id)
    |> Enum.map_join("|", &"saas_admin.user:#{&1.id}:#{&1.name}:#{&1.role}"),
    data.approvals
    |> Enum.sort_by(& &1.id)
    |> Enum.map_join("|", &"saas_admin.approval:#{&1.id}:#{&1.title}:#{&1.status}")
  ]
end
```

**Idempotency test pattern** from `reset_test.exs` (lines 11-24, 51-65):

```elixir
test "reset is idempotent and returns stable counts plus digest" do
  first = Reset.reset!()
  second = Reset.reset!()

  assert first.counts == second.counts
  assert first.digest == second.digest
  assert is_binary(first.digest)
  assert byte_size(first.digest) == 64
end

test "reset counts cover all three showcase lanes without future-domain schemas" do
  result = Reset.reset!()
  assert result.counts.saas_admin == %{accounts: 1, approvals: 3, users: 2}
end
```

**Planner notes:**
- If static fixture density expands only in maps, update counts/digest accordingly.
- If approval/activity rows become persisted, reset must delete/reseed those rows idempotently and include stable digest components.

### Optional Persistence, Schemas, And Migrations

**Apply to:** optional `saas_portal/approval.ex`, `saas_portal/activity_event.ex`, migration(s), `approvals.ex`, `showcase/fixtures.ex`.

**Analogs:** `selective_native/claim.ex`, `step_up_audit_event.ex`, migrations.

**Schema/changeset pattern** from `selective_native/claim.ex` (lines 1-18):

```elixir
defmodule CrosswakeExample.SelectiveNative.Claim do
  use Ecto.Schema
  import Ecto.Changeset

  schema "selective_native_claims" do
    field :title, :string
    field :status, :string, default: "pending"

    has_many :submissions, CrosswakeExample.SelectiveNative.Submission

    timestamps()
  end

  def changeset(claim, attrs) do
    claim
    |> cast(attrs, [:title, :status])
    |> validate_required([:title, :status])
  end
end
```

**Append-only activity evidence pattern** from `step_up_audit_event.ex` (lines 12-36, 39-78):

```elixir
schema "sigra_step_up_audit_events" do
  field(:event_id, :string)
  field(:event_type, :string)
  field(:step_up_intent_ref, :string)
  field(:outcome, :string)
  field(:denial_code, :string)
  field(:occurred_at, :utc_datetime)
  field(:route_id, :string)
  field(:request_ref, :string)
  field(:actor_kind, :string)
  field(:metadata, :map, default: %{})

  timestamps(type: :utc_datetime)
end

def changeset(event, attrs) do
  event
  |> cast(attrs, [:event_id, :event_type, :outcome, :occurred_at, :route_id, :request_ref, :actor_kind, :metadata])
  |> validate_required([:event_id, :event_type, :outcome, :occurred_at, :route_id, :request_ref, :actor_kind])
  |> validate_inclusion(:event_type, @event_types)
  |> validate_inclusion(:outcome, @outcomes)
  |> unique_constraint(:event_id)
end
```

**Reset-safe persisted fixture pattern** from `selective_native/fixtures.ex` (lines 12-26):

```elixir
def seed do
  {:ok, counts} =
    Repo.transaction(fn ->
      Repo.delete_all(Submission)
      Repo.delete_all(Claim)

      Enum.each(@claims, fn attrs ->
        {:ok, _claim} = Claims.create_claim(attrs)
      end)

      %{claims: length(@claims), submissions: 0}
    end)

  counts
end
```

**Migration pattern** from `20260518164505_create_selective_native_claims_and_submissions.exs` (lines 1-21):

```elixir
defmodule CrosswakeExample.Repo.Migrations.CreateSelectiveNativeClaimsAndSubmissions do
  use Ecto.Migration

  def change do
    create table(:selective_native_claims) do
      add :title, :string, null: false
      add :status, :string, null: false, default: "pending"

      timestamps()
    end

    create index(:selective_native_submissions, [:claim_id])
  end
end
```

**Planner notes:**
- Persistence is optional for Phase 149. Add it only if the plan requires reload-proof approval/activity evidence.
- If added, do not introduce broad account/team/member/settings tables.
- Keep durable activity rows support-safe: low-cardinality event type/outcome/route/request metadata, no secrets.

### Page Titles And Browser Route Proof

**Apply to:** `page_title_test.exs`, LiveViews setting `page_title`, `route_tour.spec.ts`.

**Analog:** `page_title.ex`, `page_title_test.exs`

**Brand title helper pattern** from `page_title.ex` (lines 13-30):

```elixir
@spec crosswake(String.t()) :: String.t()
def crosswake(page), do: join([page, @parent])

@spec admin(String.t()) :: String.t()
def admin(page), do: demo(page, :saas_admin)

@spec demo(String.t(), atom()) :: String.t()
def demo(page, brand_id) do
  join([page, Branding.brand_for!(brand_id).name, @parent])
end

defp join(parts), do: Enum.join(parts, " · ")
```

**Route-title coverage pattern** from `page_title_test.exs` (lines 15-38, 72-91):

```elixir
@expected_route_titles %{
  "saas-account" => PageTitle.admin("Account Health"),
  "saas-admin-member-access" => PageTitle.admin("Admin Member Access"),
  "saas-approval" => PageTitle.admin("Approval Detail"),
  "saas-approvals" => PageTitle.admin("Approvals"),
  "saas-dashboard" => PageTitle.admin("Dashboard"),
  "saas-profile-settings" => PageTitle.admin("Profile Settings")
}

defp assert_title(path, title) do
  html =
    build_conn()
    |> get(path)
    |> html_response(200)

  assert html =~ ~r/<title[^>]*>#{Regex.escape(title)}<\/title>/
  refute html =~ ~r/<title[^>]*>localhost/i
end

defp route_id!(route) do
  case RouterMetadata.fetch(route.metadata) do
    {:ok, policy} -> policy.id
    :error -> raise "browser route #{route.path} is missing Crosswake metadata"
  end
end
```

### Browser Route Tour And Visual Proof

**Apply to:** `examples/phoenix_host/e2e/route_tour.spec.ts`.

**Analog:** existing `route_tour.spec.ts`

**Semantic assertion before screenshot pattern** (lines 23-44, 122-131):

```typescript
test('proves LiveView, bounded bridge, offline island, and native-owned fallback route semantics before screenshots', async ({ page, context }) => {
  mkdirSync(routeTourScreenshotDir, { recursive: true });

  await proveShowcaseHub(page);

  await proveSaasRoute(page);
  await captureRouteScreenshot(page, 'saas-dashboard.png');

  writeRouteTourEvidenceManifest(screenshotDir, routeTourCommand);
});

async function proveSaasRoute(page: Page) {
  await page.goto('/saas/dashboard');

  await expect(page, ownerMessage('saas-dashboard', 'browser title')).toHaveTitle('Dashboard · AdminPilot · Crosswake');
  await expect(page.getByRole('heading', { name: 'Northwind mobile approvals' }), ownerMessage('saas-dashboard', 'live_view')).toBeVisible();

  const router = readFileSync(routerPath, 'utf8');
  expect(router, ownerMessage('saas-dashboard', 'live_view')).toContain('id: "saas-dashboard"');
  expect(router, ownerMessage('saas-dashboard', 'live_view')).toContain('live("/dashboard"');
}
```

**Mobile/focus/overflow checks** (lines 46-58, 218-245):

```typescript
test('keeps the showcase hub readable in mobile dark reduced-motion mode', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 });
  await page.emulateMedia({ colorScheme: 'dark', reducedMotion: 'reduce' });
  await proveShowcaseHub(page);
  await expectNoHorizontalOverflow(page, 'showcase-hub');

  await page.keyboard.press('Tab');
  await expectVisibleFocus(page, 'showcase-hub');
});

async function expectNoHorizontalOverflow(page: Page, routeId: string) {
  const metrics = await page.evaluate(() => ({
    clientWidth: document.documentElement.clientWidth,
    scrollWidth: document.documentElement.scrollWidth,
    bodyScrollWidth: document.body.scrollWidth,
  }));
  expect(Math.max(metrics.scrollWidth, metrics.bodyScrollWidth), ownerMessage(routeId, 'mobile viewport containment')).toBeLessThanOrEqual(metrics.clientWidth + 1);
}
```

**Planner notes:**
- Extend this route tour to click `dashboard -> approvals -> detail -> approve -> diagnostics`.
- Prove route id/owner/capability semantics before screenshots.
- Add mobile dark/reduced-motion/focus/overflow checks for the AdminPilot lane, not just the root hub.

## Shared Patterns

### Route Policy Is Authoritative

**Source:** `examples/phoenix_host/lib/crosswake_example/router.ex` and `test/.../showcase/catalog_test.exs`

Apply compiled `RouterMetadata.fetch/1` checks to any AdminPilot route catalog or diagnostics matrix. Do not duplicate route policy in prose-only maps.

### Backend-Owned Auth And Approval

**Source:** `saas_portal/auth.ex`, `on_mount.ex`, `approvals.ex`

Plug and on_mount assign `current_saas_user` and `current_saas_account`; the context authorizes approval. LiveViews render state and dispatch events only.

### Product-First Support Truth

**Source:** `showcase/catalog.ex`, `hub_live.ex`, `app.css`

Use visible text labels such as `LiveView route`, `Cached read-only`, `Sensitive route`, `MFA required`, and `Server authority`. Keep Crosswake internals in supporting badges/diagnostics, not as the first impression.

### Deterministic Reset

**Source:** `showcase/reset.ex`, `showcase/fixtures.ex`, `reset_test.exs`

Every reset count and digest component should be deterministic. Browser-owned or offline state must not be claimed as reset by server helpers.

### Testing Style

**Source:** current `examples/phoenix_host/test/test_helper.exs`, `page_title_test.exs`, `bridge_proof_live_test.exs`

There is no custom `ConnCase`/`LiveCase`; tests currently use `ExUnit.Case`, direct `Phoenix.ConnTest`, direct render calls, and direct socket event calls. Add the smallest LiveViewTest support needed rather than a broad test harness refactor.

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `examples/phoenix_host/test/crosswake_example/saas_portal/approvals_live_test.exs` | test | event-driven LiveView | No current test imports `Phoenix.LiveViewTest`; closest repo pattern is direct socket/render testing in `bridge_proof_live_test.exs`. Use official LiveViewTest only as narrowly needed. |

## Metadata

**Analog search scope:** `examples/phoenix_host/lib/crosswake_example/saas_portal`, `examples/phoenix_host/lib/crosswake_example/showcase`, `examples/phoenix_host/lib/crosswake_example/router.ex`, `examples/phoenix_host/test/crosswake_example`, `examples/phoenix_host/e2e`, `examples/phoenix_host/priv/static/css`, `brandbook/BRAND-SPEC.md`

**Files scanned:** 60+ source/test/style files via `rg --files`, `rg`, `wc -l`, and targeted line-numbered reads.

**Pattern extraction date:** 2026-07-10

**Planner must read next:** `149-CONTEXT.md`, `149-RESEARCH.md`, the SaaS modules listed above, `router.ex`, `showcase/catalog_test.exs`, `showcase/reset_test.exs`, `route_tour.spec.ts`, `brandbook/BRAND-SPEC.md`, and `examples/phoenix_host/priv/static/css/app.css`.
