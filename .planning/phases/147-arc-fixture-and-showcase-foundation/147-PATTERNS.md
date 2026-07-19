# Phase 147: Arc, Fixture, and Showcase Foundation - Pattern Map

**Mapped:** 2026-07-09  
**Files analyzed:** 26 new/modified candidate files  
**Analogs found:** 26 / 26, with 3 partial matches where this phase introduces a new showcase namespace

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `.planning/PROJECT.md` | documentation | file-I/O | `.planning/MILESTONE-ARC.md` | role-match |
| `.planning/REQUIREMENTS.md` | documentation | file-I/O | `.planning/REQUIREMENTS.md` current v19 traceability | same-file |
| `.planning/ROADMAP.md` | documentation | file-I/O | `.planning/ROADMAP.md` current Phase 147 entry | same-file |
| `.planning/STATE.md` | documentation | file-I/O | `.planning/STATE.md` current v19 roadmap decisions | same-file |
| `.planning/MILESTONE-ARC.md` | documentation | file-I/O | `.planning/MILESTONE-ARC.md` current active arc | same-file |
| `examples/phoenix_host/lib/crosswake_example/router.ex` | route | request-response | `examples/phoenix_host/lib/crosswake_example/router.ex` | exact |
| `examples/phoenix_host/lib/crosswake_example/showcase/hub_live.ex` | component | request-response | `examples/phoenix_host/lib/crosswake_example/flashcards/deck_live/index.ex` | role-match |
| `examples/phoenix_host/lib/crosswake_example/showcase/catalog.ex` | utility | transform | `examples/phoenix_host/lib/crosswake_example/saas_portal/fixtures.ex` | partial |
| `examples/phoenix_host/lib/crosswake_example/showcase/fixtures.ex` | utility | batch | `examples/phoenix_host/lib/crosswake_example/saas_portal/fixtures.ex` | role-match |
| `examples/phoenix_host/lib/crosswake_example/showcase/reset.ex` | service | batch + CRUD | `examples/phoenix_host/priv/repo/seeds.exs` | role-match |
| `examples/phoenix_host/lib/crosswake_example/flashcards.ex` | service | CRUD | `examples/phoenix_host/lib/crosswake_example/flashcards.ex` | same-file |
| `examples/phoenix_host/lib/crosswake_example/selective_native/fixtures.ex` | utility | CRUD | `examples/phoenix_host/lib/crosswake_example/selective_native/fixtures.ex` | same-file |
| `examples/phoenix_host/lib/crosswake_example/e2e/showcase_reset_controller.ex` | controller | request-response | `examples/phoenix_host/lib/crosswake_example/e2e/native_claim_controller.ex` | role-match |
| `examples/phoenix_host/priv/repo/seeds.exs` | config | batch | `examples/phoenix_host/priv/repo/seeds.exs` | same-file |
| `examples/phoenix_host/mix.exs` | config | batch | `examples/phoenix_host/mix.exs` aliases | exact |
| `examples/phoenix_host/priv/static/css/app.css` | component | transform | `examples/phoenix_host/priv/static/css/app.css` | same-file |
| `examples/phoenix_host/test/crosswake_example/showcase/catalog_test.exs` | test | transform | `examples/phoenix_host/test/crosswake_example/router_test.exs` | role-match |
| `examples/phoenix_host/test/crosswake_example/showcase/reset_test.exs` | test | CRUD + batch | `examples/phoenix_host/test/crosswake_example/e2e/sync_state_controller_test.exs` | role-match |
| `examples/phoenix_host/test/crosswake_example/showcase/hub_live_test.exs` | test | request-response | `examples/phoenix_host/test/crosswake_example/bridge_proof_live_test.exs` | role-match |
| `examples/phoenix_host/test/crosswake_example/e2e/showcase_reset_controller_test.exs` | test | request-response | `examples/phoenix_host/test/crosswake_example/e2e/sync_state_controller_test.exs` | role-match |
| `examples/phoenix_host/test/crosswake_example/router_test.exs` | test | request-response | `examples/phoenix_host/test/crosswake_example/router_test.exs` | same-file |
| `bin/see-it-run.sh` | utility | request-response | `bin/see-it-run.sh` banner/open flow | same-file |
| `README.md` | documentation | file-I/O | `README.md` See it run section | same-file |
| `guides/see_it_run.md` | documentation | file-I/O | `guides/see_it_run.md` first-run guide | same-file |
| `examples/QUICK_START.md` | documentation | file-I/O | `examples/QUICK_START.md` proof command reference | same-file |
| `examples/phoenix_host/README.md` | documentation | file-I/O | `examples/phoenix_host/README.md` example-host boundary | same-file |

## Pattern Assignments

### `examples/phoenix_host/lib/crosswake_example/router.ex` (route, request-response)

**Analog:** `examples/phoenix_host/lib/crosswake_example/router.ex`

**Imports and DSL pattern** (lines 92-118):

```elixir
defmodule CrosswakeExample.Router do
  use Phoenix.Router
  import Phoenix.LiveView.Router, only: [live_session: 3]
  import Crosswake.Router
  @compile {:no_warn_undefined, CrosswakeExample.Crosswake.Policy}
  @crosswake_policy_module CrosswakeExample.Crosswake.Policy
end
```

**Root route pattern to replace** (lines 163-186):

```elixir
scope "/" do
  pipe_through([:browser])

  crosswake_defaults runtime: :live_view, offline: :cached_read_only, security: :standard do
    get("/", CrosswakeExample.PageController, :index, crosswake: [id: "home"])

    live("/bridge-proof", CrosswakeExample.BridgeProofLive,
      crosswake: [
        id: "bridge-proof",
        runtime: :live_view,
        capabilities: ["share"],
        offline: :cached_read_only,
        security: :standard
      ]
    )
  end
end
```

**Pattern to copy:** replace the `get "/"` controller route with a `live "/"` route inside the existing `crosswake_defaults`. Keep the route metadata explicit: `id`, `runtime: :live_view`, `offline: :cached_read_only`, `security: :standard`.

**Authenticated LiveView route pattern** (lines 221-290):

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

**E2E gate pattern** (lines 448-454):

```elixir
# /_e2e is the reserved test-harness namespace — compile-time gated OUT of prod beams.
if Mix.env() in [:test, :e2e] do
  scope "/_e2e", CrosswakeExample.E2E do
    pipe_through([:api])
    get("/sync-state/:client_mutation_id", SyncStateController, :show)
    post("/native-claim", NativeClaimController, :create)
  end
end
```

**Apply to:** optional `/_e2e/showcase-reset` route. Keep it under the existing compile-time `Mix.env() in [:test, :e2e]` guard.

---

### `examples/phoenix_host/lib/crosswake_example/showcase/hub_live.ex` (component, request-response)

**Analog:** `examples/phoenix_host/lib/crosswake_example/flashcards/deck_live/index.ex`

**Imports/mount pattern** (lines 1-10):

```elixir
defmodule CrosswakeExample.Flashcards.DeckLive.Index do
  use Phoenix.LiveView

  alias CrosswakeExample.Flashcards

  @impl true
  def mount(_params, _session, socket) do
    decks = Flashcards.list_decks()
    {:ok, assign(socket, decks: decks)}
  end
end
```

**Token CSS and card render pattern** (lines 12-37):

```elixir
@impl true
def render(assigns) do
  ~H"""
  <link rel="stylesheet" href="/css/tokens.css" />
  <link rel="stylesheet" href="/css/app.css" />
  <div class="page-container">
    <h1 class="page-title">Flashcard Decks</h1>

    <div class="grid grid-cols-2">
      <%= for deck <- @decks do %>
        <div class="card" id={"deck-#{deck.id}"}>
          <div class="card-header">
            <h2 class="card-title"><%= deck.title %></h2>
            <span class="badge">runtime: live_view</span>
          </div>
        </div>
      <% end %>
    </div>
  </div>
  """
end
```

**State/status pattern** from media lane (lines 201-218):

```elixir
<section id="media-proof-lane">
  <h1>Media proof lane</h1>
  <p role="status" data-state={@derived_state} data-step={@proof_step}>
    <%= state_copy(@proof_step, @derived_state) %>
  </p>
  <p>Route owner: Phoenix. Capture seam: Rindle. Authority lane: backend verification.</p>
  <button type="button" phx-click="record_local_capture">Record local capture</button>
</section>
```

**Pattern to copy:** `HubLive` should `use Phoenix.LiveView`, assign catalog lane cards in `mount/3`, include token/app CSS links, render cards from catalog data, and use visible text badges. If reset status is rendered, use `role="status"` and structured assign fields rather than screenshot-only evidence.

---

### `examples/phoenix_host/lib/crosswake_example/showcase/catalog.ex` (utility, transform)

**Analog:** `examples/phoenix_host/lib/crosswake_example/saas_portal/fixtures.ex` plus docs vocabulary.

**Static deterministic data pattern** (lines 1-14, 58-74):

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

  def seed do
    %{account: @account, users: @users, approvals: @approvals}
  end

  def account, do: @account
  def users, do: @users
  def approvals, do: @approvals
end
```

**Allowed support-label vocabulary** from `guides/support_matrix.md` (lines 12-33):

```markdown
## Support-Truth Label Legend

Use these labels literally. Each label says what the evidence proves and what it does not prove.

| merge-blocking proof | Required deterministic proof that must pass before the claim can merge. |
| advisory evidence | Useful evidence that informs confidence but does not block standard merge flow. |
| verification-required | A claim needs an explicit verification lane before it can be treated as supported. |

Cached read-only is not offline mutation.
Bridge is not high-frequency or mutation authority.
```

**Route-owner vocabulary** from `guides/route_policy.md` (lines 19-29):

```markdown
| plain `:live_view` | Phoenix owns data, rendering, auth, and the interaction loop |
| cached read-only | the route may show a stale snapshot but cannot mutate server truth |
| `:offline_island` | one route owns local-first work with outbox or journal replay |
| `:native_screen` | native code owns a device-heavy or policy-sensitive session loop |
| explicit defer | the route needs support Crosswake has not proven honestly yet |
```

**Pattern to copy:** use module attributes for curated cards and small public accessors like `lanes/0`, `card!/1`, or `route_ids/0`. Do not duplicate the route-policy DSL. Catalog records should carry route IDs/paths, labels, CTA copy, support posture, and pressure notes only.

---

### `examples/phoenix_host/lib/crosswake_example/showcase/fixtures.ex` (utility, batch)

**Analog:** `examples/phoenix_host/lib/crosswake_example/saas_portal/fixtures.ex`

**Deterministic record style** (lines 31-56):

```elixir
@approvals [
  %{
    id: "approval-1",
    account_id: @account.id,
    title: "Quarterly spend increase",
    status: :pending,
    requested_by: "member-1",
    reviewed_by: nil
  },
  %{
    id: "approval-3",
    account_id: @account.id,
    title: "Contract archive export",
    status: :approved,
    requested_by: "member-1",
    reviewed_by: "approver-1"
  }
]
```

**Pattern to copy:** use stable IDs, names, states, and timestamps. Use `Showcase.Fixtures` only for foundation-level static records and orchestration helpers; lane-owned contexts should keep owning their real data.

---

### `examples/phoenix_host/lib/crosswake_example/showcase/reset.ex` (service, batch + CRUD)

**Analog:** `examples/phoenix_host/priv/repo/seeds.exs`

**Idempotent seed pattern** (lines 13-25):

```elixir
# The offline study island does not get server-side proof data here. Its
# cards and review outbox are app-owned browser state seeded by
# priv/static/offline_study.js so the v12 proof exercises IndexedDB,
# reconnect-triggered flush, and /study/sync honestly.

alias CrosswakeExample.Repo
alias CrosswakeExample.Flashcards.Deck
alias CrosswakeExample.Flashcards.Card

# Clear existing data for idempotency
Repo.delete_all(Card)
Repo.delete_all(Deck)
```

**Insert-via-context pattern** (lines 27-58):

```elixir
{:ok, deck} =
  Flashcards.create_deck(%{
    title: "Elixir Basics",
    description: "Core concepts of Elixir"
  })

{:ok, _card1} =
  Flashcards.create_card(%{
    deck_id: deck.id,
    front_text: "What is OTP?",
    back_text: "Open Telecom Platform - a collection of middleware, libraries, and tools written in Erlang."
  })

IO.puts("Successfully seeded the database with 'Elixir Basics' deck and cards!")
```

**Pattern to copy:** `Showcase.Reset.reset!/0` should centralize reset orchestration, delete child rows before parents, call lane-owned fixture/context functions, return structured counts plus a deterministic digest, and explicitly report `browser_state_reset: false`.

---

### `examples/phoenix_host/lib/crosswake_example/flashcards.ex` (service, CRUD)

**Analog:** same file.

**Context CRUD pattern** (lines 6-24, 69-89):

```elixir
import Ecto.Query, warn: false
alias CrosswakeExample.Repo
alias CrosswakeExample.Flashcards.Deck
alias CrosswakeExample.Flashcards.Card
alias CrosswakeExample.Flashcards.Progress

def list_decks do
  Repo.all(Deck)
end

def create_deck(attrs \\ %{}) do
  %Deck{}
  |> Deck.changeset(attrs)
  |> Repo.insert()
end

def list_deck_cards(deck_id) do
  Card
  |> where([c], c.deck_id == ^deck_id)
  |> order_by([c], asc: c.inserted_at)
  |> Repo.all()
end

def upsert_progress(attrs) do
  %Progress{}
  |> Progress.changeset(attrs)
  |> Repo.insert(on_conflict: :replace_all, conflict_target: [:card_id, :user_id])
end
```

**Pattern to copy:** if the planner adds learning reset helpers here, keep them context-owned and Ecto-backed. Do not let `Showcase.Reset` imply it resets browser IndexedDB state.

---

### `examples/phoenix_host/lib/crosswake_example/selective_native/fixtures.ex` (utility, CRUD)

**Analog:** same file.

**Current footgun to fix** (lines 1-8):

```elixir
defmodule CrosswakeExample.SelectiveNative.Fixtures do
  alias CrosswakeExample.SelectiveNative.Claims

  def seed do
    Claims.create_claim(%{title: "Broken windshield", status: "pending"})
    Claims.create_claim(%{title: "Hail damage", status: "pending"})
  end
end
```

**Pattern to copy with correction:** keep the fixture module lane-local, but add reset-safe deletion/upsert behavior or return created-record counts so repeated showcase resets do not duplicate rows.

---

### `examples/phoenix_host/lib/crosswake_example/e2e/showcase_reset_controller.ex` (controller, request-response)

**Analog:** `examples/phoenix_host/lib/crosswake_example/e2e/native_claim_controller.ex`

**JSON success/error pattern** (lines 1-20):

```elixir
defmodule CrosswakeExample.E2E.NativeClaimController do
  use Phoenix.Controller, formats: [:json]

  alias CrosswakeExample.SelectiveNative.Claims

  def create(conn, params) do
    title = Map.get(params, "title", "Route Tour Claim")
    status = Map.get(params, "status", "pending")

    case Claims.create_claim(%{title: title, status: status}) do
      {:ok, claim} ->
        json(conn, %{id: claim.id, title: claim.title, status: claim.status})

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: inspect(changeset.errors)})
    end
  end
end
```

**Read-only inspection pattern** from `SyncStateController` (lines 15-27):

```elixir
def show(conn, %{"client_mutation_id" => id}) do
  count =
    from(r in ReviewEvent, where: r.client_mutation_id == ^id)
    |> Repo.aggregate(:count, :id)

  case Repo.get_by(ReviewEvent, client_mutation_id: id) do
    nil -> json(conn, %{synced: false, count: 0})
    record -> json(conn, %{synced: true, status: record.status, count: count})
  end
end
```

**Pattern to copy:** controller should delegate to `Showcase.Reset.reset!/0`, return `%{counts: ..., digest: ..., browser_state_reset: false}`, and rely on router-level `/_e2e` compile gating.

---

### `examples/phoenix_host/priv/repo/seeds.exs` (config, batch)

**Analog:** same file.

**Existing contract** (lines 1-16):

```elixir
# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# The offline study island does not get server-side proof data here. Its
# cards and review outbox are app-owned browser state seeded by
# priv/static/offline_study.js so the v12 proof exercises IndexedDB,
# reconnect-triggered flush, and /study/sync honestly.
```

**Pattern to copy:** replace inline seed logic with a call to `CrosswakeExample.Showcase.Reset.reset!/0`, print counts/digest, and preserve the offline-state warning.

---

### `examples/phoenix_host/mix.exs` (config, batch)

**Analog:** same file.

**Alias pattern** (lines 29-36):

```elixir
defp aliases do
  [
    setup: ["deps.get", "ecto.setup"],
    "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
    "ecto.reset": ["ecto.drop", "ecto.setup"],
    # Provisions the SQLite DB and applies all migrations before running tests.
    test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"]
  ]
end
```

**Pattern to copy:** add a narrow local alias such as `"showcase.reset": ["run -e \"CrosswakeExample.Showcase.Reset.reset!()\""]` only if the implementation needs a CLI reset command. Keep `setup` and `ecto.setup` delegating through `priv/repo/seeds.exs`.

---

### `examples/phoenix_host/priv/static/css/app.css` (component, transform)

**Analog:** same file.

**Token-backed base pattern** (lines 1-21):

```css
body {
  font-family: var(--cw-font-body);
  background-color: var(--cw-surface-default);
  color: var(--cw-text-default);
  margin: 0;
  padding: 0;
  line-height: 1.5;
}

.page-container {
  max-width: 860px;
  margin: 0 auto;
  padding: calc(var(--cw-spacing-base) * 6);
}
```

**Cards/buttons/badges/grid pattern** (lines 29-68, 98-132):

```css
.card {
  background-color: var(--cw-surface-inset);
  border: 1px solid var(--cw-border-default);
  border-radius: var(--cw-radius-lg);
  padding: calc(var(--cw-spacing-base) * 6);
}

.btn-primary {
  background-color: var(--cw-action-bg);
  color: var(--cw-action-fg);
  border-radius: var(--cw-radius-md);
  display: inline-flex;
}

.badge {
  display: inline-block;
  border-radius: var(--cw-radius-sm);
  font-size: var(--cw-text-scale-xs);
  background-color: var(--cw-surface-raised);
}

.grid {
  display: grid;
  gap: calc(var(--cw-spacing-base) * 6);
}
```

**Pattern to copy:** add only narrow `showcase-*` classes, keep them token-backed, preserve light/dark/system behavior, visible focus rings, and responsive grids. No Tailwind, no new UI package, no icon package.

---

### Showcase ExUnit Tests (test, request-response / transform / batch)

**Files:**  
`examples/phoenix_host/test/crosswake_example/showcase/catalog_test.exs`  
`examples/phoenix_host/test/crosswake_example/showcase/reset_test.exs`  
`examples/phoenix_host/test/crosswake_example/showcase/hub_live_test.exs`  
`examples/phoenix_host/test/crosswake_example/e2e/showcase_reset_controller_test.exs`  
`examples/phoenix_host/test/crosswake_example/router_test.exs`

**Analogs:** router, LiveView render, and E2E controller tests.

**Router assertion pattern** (lines 1-17):

```elixir
defmodule CrosswakeExample.RouterTest do
  use ExUnit.Case, async: true

  @path "/_e2e/sync-state/:client_mutation_id"

  test "E2E sync-state route present in :test, wired to scoping controller" do
    route =
      CrosswakeExample.Router
      |> Phoenix.Router.routes()
      |> Enum.find(&(&1.path == @path))

    assert route, "expected #{@path} compiled in :test"
    assert route.verb == :get
    assert route.plug == CrosswakeExample.E2E.SyncStateController
    assert route.plug_opts == :show
  end
end
```

**LiveView render test pattern** (lines 1-14, 24-33):

```elixir
defmodule CrosswakeExample.BridgeProofLiveTest do
  use ExUnit.Case

  alias CrosswakeExample.BridgeProofLive

  test "renders initially without bridge script" do
    assigns = %{bridge_request: nil}
    html = Phoenix.HTML.Safe.to_iodata(BridgeProofLive.render(assigns)) |> IO.iodata_to_binary()

    assert html =~ "Bridge Proof"
    refute html =~ "crosswake-share-"
  end
end
```

**Controller/direct DB cleanup pattern** (lines 1-13, 41-49, 64-72):

```elixir
defmodule CrosswakeExample.E2E.SyncStateControllerTest do
  use ExUnit.Case, async: false

  import Phoenix.ConnTest
  import Ecto.Query, warn: false

  alias CrosswakeExample.Repo
  alias CrosswakeExample.LocalFirst.ReviewEvent

  @endpoint CrosswakeExample.Endpoint

  on_exit(fn ->
    ids = [id_a, id_b]
    Repo.delete_all(from(r in ReviewEvent, where: r.client_mutation_id in ^ids))
  end)

  conn = build_conn()
  conn = CrosswakeExample.E2E.SyncStateController.show(conn, %{"client_mutation_id" => missing_id})
  body = Jason.decode!(conn.resp_body)
end
```

**Route metadata verification sources**:

`lib/crosswake/policy/router_metadata.ex` (lines 20-34):

```elixir
@spec fetch(map()) :: {:ok, Route.t()} | :error
def fetch(metadata) when is_map(metadata) do
  case Map.fetch(metadata, @compiled_key) do
    {:ok, %Route{} = route} -> {:ok, route}
    _other -> :error
  end
end
```

`examples/phoenix_host/lib/crosswake_example/crosswake/policy.ex` (lines 9-15):

```elixir
@router CrosswakeExample.Router

def router, do: @router

def compile(opts \\ []) do
  Crosswake.Policy.Compiler.compile(@router, opts)
end
```

**Pattern to copy:** catalog tests should build a route map from `CrosswakeExample.Router.__routes__()` or `CrosswakeExample.Crosswake.Policy.compile/1`, fetch compiled metadata, and assert each catalog route ID/path/runtime/offline/security posture exists. Reset tests should be `async: false`, prove idempotency, stable counts/digest, and `browser_state_reset: false`.

---

### Playwright Proof Pattern (test, request-response + file-I/O)

**Reference-only for Phase 147 unless planner adds a narrow smoke; Phase 151 owns expanded route-tour coverage.**

**Analog:** `examples/phoenix_host/e2e/route_tour.spec.ts`

**Semantic-before-screenshot pattern** (lines 18-39):

```typescript
test.describe('Crosswake route-owner browser tour', () => {
  test.beforeEach(async ({ page }) => {
    await resetOfflineStudyDatabase(page);
  });

  test('proves LiveView, bounded bridge, offline island, and native-owned fallback route semantics before screenshots', async ({ page, context }) => {
    mkdirSync(routeTourScreenshotDir, { recursive: true });

    await proveLibraryRoute(page);
    await captureRouteScreenshot(page, 'library.png');

    await proveBridgeRoute(page);
    await captureRouteScreenshot(page, 'bridge-proof.png');

    writeRouteTourEvidenceManifest(screenshotDir, routeTourCommand);
  });
});
```

**Route-owner assertion pattern** (lines 42-50, 108-119, 145-147):

```typescript
const router = readFileSync(routerPath, 'utf8');
expect(router, ownerMessage('library', 'live_view')).toContain('id: "library"');
expect(router, ownerMessage('library', 'live_view')).toContain('live("/library"');

expect(router, ownerMessage('selective-native-claim-capture', 'native_screen')).toContain('runtime: :native_screen');

function ownerMessage(routeId: string, owner: string) {
  return `route-tour semantic assertion failed for route id ${routeId} (${owner}); screenshots are collateral after this assertion passes`;
}
```

**Browser-owned offline reset pattern** from `e2e/support/offline_route_proof.ts` (lines 10-14, 33-40):

```typescript
export async function resetOfflineStudyDatabase(page: Page) {
  await page.addInitScript(() => {
    indexedDB.deleteDatabase('crosswake_offline_study');
  });
}

export async function expectSyncedReview(request: APIRequestContext, clientMutationId: string, expectedCount = 1) {
  await expect.poll(async () => {
    const res = await request.get(`/_e2e/sync-state/${clientMutationId}`);
    return res.ok() ? res.json() : { synced: false, count: -1 };
  }).toMatchObject({ synced: true, count: expectedCount });
}
```

**Pattern to preserve:** server-side reset must not clear IndexedDB. Browser reset stays in Playwright helpers.

---

### First-Run Script and Documentation (utility/documentation, file-I/O)

**Files:**  
`bin/see-it-run.sh`  
`README.md`  
`guides/see_it_run.md`  
`examples/QUICK_START.md`  
`examples/phoenix_host/README.md`

**Analog:** same files.

**Launcher banner pattern** from `bin/see-it-run.sh` (lines 150-209):

```bash
print_banner() {
  printf "${BOLD}================================================================${RESET}\n"
  printf "${BOLD}  Crosswake demo backend is running${RESET}\n"
  printf "${BOLD}================================================================${RESET}\n"
  printf "\n"
  printf "  ${ACCENT}${BOLD}%s${RESET}\n" "${BACKEND_URL}"
  printf "\n"
  printf "  Key route owners:\n"
  printf "    /              Phoenix-owned home\n"
  printf "    /offline       app-owned offline island\n"
  printf "    /bridge-proof  LiveView + bounded Share\n"
  printf "\n"
  printf "  What is proven now (no extra toolchain required)\n"
  printf "  - Backend boots from Docker (this script) or native mix phx.server\n"
  printf "  - All three web routes reachable in any browser\n"
  printf "  - Offline replay proof: npx playwright test (examples/phoenix_host/e2e/)\n"
  printf "  - Bounded bridge proof: script/verify_bounded_bridge_proof.sh\n"
}
```

**Auto-open pattern** (lines 216-221):

```bash
if [ "$NO_OPEN" -eq 0 ] && [ -t 1 ] && [ -z "${CI:-}" ] && [ -z "${NO_OPEN:-}" ]; then
  if command -v open >/dev/null 2>&1; then
    open "${BACKEND_URL}/" || true
  elif command -v xdg-open >/dev/null 2>&1; then
    xdg-open "${BACKEND_URL}/" || true
  fi
fi
```

**README See It Run pattern** (lines 45-72):

````markdown
## See it run

```bash
bin/see-it-run.sh
```

Boots the shared backend on port 4700 and auto-opens the browser. Requires Docker.

Three routes, one shared backend at `http://localhost:4700`:

- `/` — home (Phoenix LiveView)
- `/offline` — offline island (app-owned, socketless)
- `/bridge-proof` — bounded bridge (share capability)
````

**First-run guide pattern** from `guides/see_it_run.md` (lines 38-82, 116-134):

````markdown
## Run It Now (Zero Toolchain)

Boot the shared backend with one command:

```bash
bin/see-it-run.sh
```

Open `http://localhost:4700/` in your browser.

## Browse the Route Owners

| Route | Owner | What you see |
| `/` | Phoenix-owned | Crosswake Phoenix Host home — links to route owner examples |

What `bin/see-it-run.sh` proves:
- The Phoenix-owned web routes (`/`, `/offline`, `/bridge-proof`) are live.

What it does not prove:
- Physical-device support.
- Offline replay correctness.
````

**Quick start proof/non-claim pattern** from `examples/QUICK_START.md` (lines 22-75, 229-238):

````markdown
## First Run

Run from the repo root — no local Elixir, Node, or SQLite toolchain required:

```bash
bin/see-it-run.sh
```

What to look for:

- `/` is the Phoenix-owned starting point for the checked-in host.
- `/offline` renders the Offline Study Island.
- `/bridge-proof` renders a LiveView route that declares the bounded `share` capability.

## What This Does Not Prove

- It does not prove broad app-wide local-first behavior or background sync.
- It does not make the bridge offline mutation authority.
- It does not prove simulator, emulator, or physical-device support.
````

**Example-host boundary pattern** from `examples/phoenix_host/README.md` (lines 11-17, 28-72):

```markdown
## Shared Artifact Rules

- Keep one shared Phoenix host under `examples/phoenix_host`.
- Extend profile-specific routes, modules, fixtures, and proof checks inside the shared host.
- Do not turn the example host into a runtime package or kitchen-sink demo.

## Example Boundary

Routes inside the example host still obey the same runtime ownership rules as the product.
Maintainers own example routes, fixtures, proof-lane checks, and README wording that keeps support promises narrow and honest.
```

**Pattern to copy:** rewrite first-run copy so `/` is the showcase hub, proof routes are secondary, and every proof/native/offline claim keeps the same honest labels.

---

### Planning Docs (documentation, file-I/O)

**Files:** `.planning/PROJECT.md`, `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/STATE.md`, `.planning/MILESTONE-ARC.md`

**Analog:** same planning artifacts and `.planning/MILESTONE-ARC.md`.

**Pattern to preserve:** update only Phase 147/v19/v20 wording needed by ARC-01..03. Keep SEED-002 as strategic input for capability breadth, and keep SEED-003/004 as release-infrastructure carryovers rather than v19 headline scope. Do not add broad native-controls implementation scope to Phase 147.

## Shared Patterns

### Route Policy Metadata Verification

**Source:** `lib/crosswake/policy/router_metadata.ex` and `examples/phoenix_host/lib/crosswake_example/crosswake/policy.ex`  
**Apply to:** `showcase/catalog.ex`, `catalog_test.exs`, `router_test.exs`

```elixir
def fetch(metadata) when is_map(metadata) do
  case Map.fetch(metadata, @compiled_key) do
    {:ok, %Route{} = route} -> {:ok, route}
    _other -> :error
  end
end

def compile(opts \\ []) do
  Crosswake.Policy.Compiler.compile(@router, opts)
end
```

### Server Reset Does Not Reset Browser State

**Source:** `priv/repo/seeds.exs` lines 13-16 and `e2e/support/offline_route_proof.ts` lines 10-14  
**Apply to:** `showcase/reset.ex`, `seeds.exs`, E2E reset endpoint, docs copy

```elixir
# The offline study island does not get server-side proof data here. Its
# cards and review outbox are app-owned browser state seeded by
# priv/static/offline_study.js so the v12 proof exercises IndexedDB,
# reconnect-triggered flush, and /study/sync honestly.
```

```typescript
export async function resetOfflineStudyDatabase(page: Page) {
  await page.addInitScript(() => {
    indexedDB.deleteDatabase('crosswake_offline_study');
  });
}
```

### Support Truth Labels

**Source:** `guides/support_matrix.md` lines 12-33  
**Apply to:** `showcase/catalog.ex`, `hub_live.ex`, docs

```markdown
Use these labels literally. Each label says what the evidence proves and what it does not prove.

Support status is not device evidence: `supported` is not the same as device-verified.
Visual collateral is not correctness proof by itself.
Cached read-only is not offline mutation.
Bridge is not high-frequency or mutation authority.
```

### UI Token Discipline

**Source:** `examples/phoenix_host/priv/static/css/app.css` lines 1-21, 29-68, 98-132 and `147-UI-SPEC.md` lines 26-45, 170-231  
**Apply to:** `hub_live.ex`, `app.css`

```css
body {
  font-family: var(--cw-font-body);
  background-color: var(--cw-surface-default);
  color: var(--cw-text-default);
}

.card {
  background-color: var(--cw-surface-inset);
  border: 1px solid var(--cw-border-default);
  border-radius: var(--cw-radius-lg);
}
```

### Semantic Proof Before Screenshots

**Source:** `examples/phoenix_host/e2e/route_tour.spec.ts` lines 18-39, 145-147  
**Apply to:** any route-tour smoke the planner adds; otherwise keep for Phase 151

```typescript
await proveLibraryRoute(page);
await captureRouteScreenshot(page, 'library.png');

function ownerMessage(routeId: string, owner: string) {
  return `route-tour semantic assertion failed for route id ${routeId} (${owner}); screenshots are collateral after this assertion passes`;
}
```

## No Analog Found

No file is completely without a usable analog. The following are partial matches because Phase 147 introduces a new product-shaped showcase namespace:

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `examples/phoenix_host/lib/crosswake_example/showcase/catalog.ex` | utility | transform | No existing example-host product-facing route-card catalog; combine static fixture-module style with support/route-policy vocabulary. |
| `examples/phoenix_host/lib/crosswake_example/showcase/reset.ex` | service | batch + CRUD | No existing reset orchestrator; copy seed idempotency and controller/test patterns while keeping lane ownership explicit. |
| `examples/phoenix_host/lib/crosswake_example/showcase/hub_live.ex` | component | request-response | Existing LiveViews are lane/proof surfaces, not a first-screen hub; copy LiveView/render/CSS mechanics, not page narrative. |

## Metadata

**Analog search scope:** `examples/phoenix_host/lib`, `examples/phoenix_host/test`, `examples/phoenix_host/e2e`, `examples/phoenix_host/priv/repo`, `examples/phoenix_host/priv/static/css`, `bin`, `guides`, `examples`, `README.md`, `lib/crosswake`  
**Files scanned:** 418  
**Pattern extraction date:** 2026-07-09
