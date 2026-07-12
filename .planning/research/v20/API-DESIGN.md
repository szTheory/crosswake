# v20 Native Controls Pack 1 — Consumer-Facing API Design

**Lens:** API design / Elixir-Phoenix idiom, from the adopter's chair.
**Scope:** How a Phoenix developer declares and invokes route-level bounded
controls (alert/confirm, menu/action-button, haptics, share, toast/review
prompt) plus reads `permissions.status` / `notification_token` evidence.
**Grounding:** `lib/crosswake/bridge/*`, `lib/crosswake/policy/schema.ex`,
`lib/crosswake/manifest/types.ex`, `lib/crosswake/native_escape/contract.ex`,
`lib/crosswake/runtime_line/rebuild_policy.ex`, `guides/route_policy.md`,
`guides/capabilities.md`, `guides/bridge.md`, `guides/capability_map.md`,
`examples/phoenix_host/lib/crosswake_example/saas_portal/approval_live.ex`
(the Phase 149 haptics baseline), `.planning/phases/152-.../152-V20-HANDOFF.md`.

## 0. The existing baseline is not an API — it's a proof-of-concept

Phase 149's "optional haptics after approval success" is the closest thing to
prior art, and it is instructive precisely because of what's missing:

```elixir
# examples/phoenix_host/.../saas_portal/approval_live.ex (today)
defp haptics_request(approval_id) do
  %{"protocol" => @bridge_protocol, "version" => @bridge_capability_version,
    "command" => "haptics.impact", "capability" => "haptics.impact",
    "route_id" => @bridge_route_id, "active_route_id" => @bridge_route_id,
    "origin" => @shell_origin, "native_runtime_version" => "1.0.0",
    "correlation_id" => "approval-haptics-#{approval_id}", ...}
end

defp bridge_script(request) do
  """
  (() => {
    const payload = #{Jason.encode!(Jason.encode!(request))};
    if (window.webkit?.messageHandlers?.crosswakeBridge) {
      window.webkit.messageHandlers.crosswakeBridge.postMessage(payload);
    } else if (window.crosswakeBridge?.postMessage) {
      window.crosswakeBridge.postMessage(payload);
    }
  })();
  """
end
```

...rendered into a `<script>` tag via `Phoenix.HTML.raw/1`. Three problems
this exposes, which v20 must fix:

1. **The adopter hand-builds the envelope.** Every field `Bridge.Contract`
   already knows how to construct (`protocol`, `version`,
   `native_runtime_version`, `capabilities` map) is retyped by hand in the
   LiveView, with real risk of drift from the manifest.
2. **There is no reply path.** This is fire-and-forget by omission, not by
   design — the shell's answer (if any) is never wired back into the
   LiveView. That's fine for haptics; it is fatal for confirm.
3. **The client dispatch is copy-pasted per LiveView.** Every route that
   wants a bounded affordance would re-invent this IIFE. There is exactly one
   correct place for "does a shell exist, and how do I talk to it" to live:
   a single shipped hook, not N inlined scripts.

Pack 1's API job is to replace this pattern with one server-side helper and
one client-side hook, without changing what the bridge *is* (typed, semantic,
versioned, low-frequency, fail-closed).

## 1. Declaration site

**Recommendation: extend `capabilities:` (unchanged authorization list); add
a same-named scoped keyword only for the two families that need structured
parameters (`confirm`, `menu`).**

```elixir
# before (v19, haptics only)
live("/saas/approvals/:id", ApprovalLive,
  crosswake: [
    id: "saas-approval",
    runtime: :live_view,
    entry: :external,
    capabilities: ["haptics.impact"],
    offline: :cached_read_only,
    cache_contract: :approval_snapshot_v1,
    security: :standard
  ]
)

# after (v20, haptics + confirm)
live("/saas/approvals/:id", ApprovalLive,
  crosswake: [
    id: "saas-approval",
    runtime: :live_view,
    entry: :external,
    capabilities: ["haptics", "confirm"],
    confirm: [
      title: "Reject this request?",
      body: "The requester is notified immediately.",
      confirm_label: "Reject",
      cancel_label: "Keep pending"
    ],
    offline: :cached_read_only,
    cache_contract: :approval_snapshot_v1,
    security: :standard
  ]
)
```

Note the family name changes from `"haptics.impact"` to `"haptics"` — this
actually *fixes* existing doc/code drift, it isn't new surface. `route_policy.md`
shows `capabilities: ["haptics.impact"]` in prose, but `Bridge.Registry.lookup/4`
authorizes against `manifest.capability_registry` family ids (`"haptics"`,
not the wire command `"haptics.impact"`), and `guides/capabilities.md` is
explicit that "Route DSL declarations should use semantic family ids... Transport
commands... remain protocol details rather than the public route-policy
vocabulary." Pack 1 is the right moment to make every route example correct.

**Why not a new `controls:` block or separate DSL?** Because `capabilities:`
is *already* the one list `Bridge.Registry.capability_declared_on_route?/2`
checks, the one list doctor/support-matrix reads, and the one list the
compatibility/RouteGate diff machinery walks for rebuild classification. A
parallel `controls:` list would mean two authorization surfaces that must be
kept in sync by hand — and "capabilities, packs, sync seams... all hang off
the route owner, they are not a separate catalog" is stated as the core DSL
principle in `guides/route_policy.md`. Reusing the existing list is the
smallest, least surprising change; a new top-level concept is the more
surprising one and only earns its keep if the *authorization semantics*
actually differ, which they don't here.

**Why a sibling scoped keyword (`confirm:`, `menu:`) instead of putting the
parameters inline in the `capabilities:` list itself** (e.g. mixing bare
strings with `[id: "confirm", title: ...]` keyword-list entries in one
heterogeneous list)? Two reasons:

- Precedent: Crosswake already pairs a scoped key to a declared mode rather
  than nesting parameters inside the mode list itself — `cache_contract`
  requires `offline: :cached_read_only`; `island_contract` requires
  `runtime: :offline_island`. `confirm:`/`menu:` requiring `"confirm"`/`"menu"`
  in `capabilities` is the same validator idiom (`policy/validator.ex`
  already enforces this class of pairing rule), not a new one.
- A flat list of bare strings stays trivially greppable/diffable
  (`capabilities: ["haptics", "confirm", "share"]` reads as a manifest at a
  glance); a heterogeneous list of strings-or-keyword-lists does not.

`haptics`, `share`, and `toast` need no scoped keyword — they take their one
parameter (`style`, message copy) at the call site, not the declaration site,
because they have no *allowlist* to enforce (unlike menu actions or a
confirm's copy, which the fallback UI and the native affordance must agree on
verbatim, so they belong in policy, not in a `handle_event` body that could
drift per call site).

## 2. Invocation site

**Recommendation: a chainable server-side helper, `Crosswake.Bridge.push/3`,
built on the same seam LiveView already uses for browser-side JS interop
(`push_event/3` + one shipped hook + `handleEvent`) — imperative Elixir on
top of a declarative, shared client hook.** Not a raw `push_event` convention
left to each adopter, not a Hotwire-style `data-cw-*` attribute, not a
generic plugin registry.

```elixir
def handle_event("approve", _params, socket) do
  {:ok, approved} = Approvals.approve(socket.assigns.approval.id)

  {:noreply,
   socket
   |> assign(approval: approved)
   |> Crosswake.Bridge.push("haptics", style: :light)}
end
```

`Crosswake.Bridge.push/3`:

1. Looks up `route_id`/capability against the **compiled manifest** via
   `Bridge.Registry.lookup/3` — server-side, before anything reaches the
   client. If the route's own policy never declared `"haptics"`, this is a
   programmer error, not a runtime condition, and it raises `ArgumentError`
   immediately (see §3).
2. Builds the envelope with `Bridge.Contract.new_request/1` — the adopter
   never retypes `protocol`, `version`, `native_runtime_version`, or
   `capabilities`; those come from the manifest and connection assigns
   Crosswake already tracks.
3. Calls `push_event(socket, "cw:bridge", Contract.to_map(request))` and
   returns the socket, so it composes in the same pipe adopters already
   write.

**On why declarative-HEEx-first (Hotwire Native's approach) is the wrong
model here.** Hotwire Native's `data-turbo-native="true"` works because Turbo
apps are stateless-request-per-navigation: the server renders complete HTML,
the native layer intercepts markup attributes on that HTML, and there is no
persistent process to hand a decision to. LiveView's mental model is the
opposite: a long-lived process that already owns "something happened, now
let a JS hook do a client-side thing" — and Phoenix ships a blessed primitive
for exactly that seam: `push_event/3` + `phx-hook` + `handleEvent`. That's
the same mechanism LiveView docs use for autofocus, clipboard copy, chart
libraries, and sortable lists. A bounded-bridge command is one more instance
of "the server decided, hand it to JS," not a new problem needing a new
markup vocabulary. Declarative HTML attributes would also reintroduce the
Phase 149 problem in reverse — instead of one hand-rolled script per route,
you'd get bespoke `data-cw-*` attribute contracts per template, with the
authorization check now living in markup instead of in the one place
(`Bridge.Registry`) that can see the manifest.

Where declarative HEEx *is* the right shape: **the fallback UI itself.**
Confirm's ground truth is not a JS `window.confirm()` — it's the two Phoenix-
rendered buttons that already exist in the template today. Native confirm is
an accelerant on top of that UI, not a replacement for it (§3, §4).

## 3. The degradation contract

**One `handle_event` clause must handle "no shell," "old shell," and
"capability undeclared" identically — because all three collapse into the
same typed reply shape.** This is the load-bearing design decision.

There are two genuinely different failure axes, and conflating them is the
mistake to avoid:

| Axis | Detectable where | Nature | Pack 1 behavior |
|------|-------------------|--------|------------------|
| Route never declared the capability | Server, at compile/route-table time | Programmer error | `Bridge.push/3` raises `ArgumentError` in dev/test; this is a bug, not a runtime state, and should be as loud as forgetting a required Ecto changeset field |
| No shell / old shell / shell lacks capability version | Client, only knowable from `window.webkit`/`window.crosswakeBridge` presence and the capability-version handshake | Legitimate runtime condition | The shared JS hook synthesizes a **typed deny reply** and pushes it back through the exact same event name a real native denial would use |

Concretely, the shipped hook (one hook, shipped once, not per-route):

```js
// crosswake.js (shipped asset, adopters wire it into Hooks once)
export const CrosswakeBridge = {
  mounted() {
    this.handleEvent("cw:bridge", (request) => {
      const transport = window.webkit?.messageHandlers?.crosswakeBridge
        ?? window.crosswakeBridge;

      if (!transport) {
        // No shell reachable at all — synthesize the SAME reply shape
        // a real native denial would produce. Never silently succeed.
        return this.pushEvent("cw:bridge_reply", denyReply(request, "capability_unavailable"));
      }
      transport.postMessage(JSON.stringify(request)); // native replies asynchronously via this.pushEvent
    });
  }
};
```

Because both "the shell said no" and "there is no shell" arrive as
`%{"status" => "deny", "denial" => %{"reason" => ...}}` through the identical
`handle_event("cw:bridge_reply", ...)`, the adopter writes **one** branch, not
three:

```elixir
def handle_event("cw:bridge_reply", %{"status" => "ok"} = reply, socket),
  do: {:noreply, on_confirm_answer(socket, reply)}

def handle_event("cw:bridge_reply", %{"status" => "deny"}, socket),
  do: {:noreply, socket}  # Phoenix-rendered fallback UI is already on screen
```

Per-control fallback, and which of these are honest vs. dishonest:

| Control | Fallback | Honesty note |
|---------|----------|---------------|
| Alert | Phoenix flash / inline `role="alert"` text | Native alert only accelerates the same message that's already rendered — never the only copy of it |
| Confirm | The two on-page Phoenix buttons (already the ground truth) | Native confirm answers into the identical `handle_event` the buttons target; no race, no double-answer, because the answer *is* the click target either way |
| Menu/action-button | A Phoenix-rendered `<details>`/dropdown with the same declared, allowlisted actions | Native menu presents the same allowlist from `menu:` policy, not a superset |
| Haptics | **No-op.** No visual/CSS substitute. | This is the one place a "fallback" would be *dishonest* — there is no way to simulate touch feedback in a browser, so pretending one exists (a screen flash standing in for a vibration) misrepresents what happened. Silence is the only truthful fallback. |
| Share | `navigator.share()` (Web Share API) if present, else a Phoenix-rendered copy-link/mailto panel | A real three-tier ladder (native > Web Share > copy-link), all progressive enhancement over the same URL/text payload |
| Toast / review prompt | In-page flash via `put_flash/3` | Native review prompts (StoreKit/Play In-App Review) never report an outcome by platform design — see §4, this is not a Crosswake limitation to paper over |

Contract requirement #4 from the v20 handoff ("missing or incompatible
capabilities fail closed into explicit fallback copy") is satisfied by
construction: the fallback copy is the thing already rendered in the
template, not a new denial-specific UI state to build per route.

## 4. Return values / callbacks — modeling "answers" vs. "fire-and-forget" without lying

Add one field to the existing `Capability` struct
(`lib/crosswake/manifest/types.ex`), alongside its existing `rebuild`
axis (`:none | :native_required | :companion_required`):

```elixir
@type interaction :: :fire_and_forget | :answering

defstruct [..., :rebuild, :interaction]
```

- `:answering` (confirm, alert-with-choice) — the reply's `payload` carries a
  real, observable `answer` (`"confirm" | "cancel"`), because a dialog
  interaction is genuinely observable.
- `:fire_and_forget` (haptics, share, toast/review-prompt) — the reply, if
  any, never claims a user outcome. Share and review-prompt specifically get
  `payload: %{"outcome" => "requested"}`, **never** `"completed"` or
  `"accepted"` — because neither `navigator.share()`'s promise resolution nor
  StoreKit's `requestReview()` reliably tells the caller whether the user
  actually shared or reviewed (App Store policy explicitly prevents apps from
  knowing this, precisely to stop review-gating dark patterns). Modeling this
  as `"outcome" => "unknown"` after a definite `"requested"` moment is the
  honest contract; modeling it as `success: true` would be a lie Crosswake's
  whole "fail-closed, never silently wrong" posture explicitly exists to
  avoid.

Correlation ids are not new — `Bridge.Contract.Request.correlation_id` and
`Reply.correlation_id` already exist and already round-trip. `Bridge.push/3`
generates one per call; the reply echoes it verbatim. Pack 1 does not need
adopters to track correlation ids manually for the common one-confirm-at-a-
time case (matching on `command`/event name is enough); it becomes relevant
only when a route can have N concurrent asks in flight (e.g., a list of rows
each with its own delete-confirm), where the existing field already carries
enough information to disambiguate — nothing new to design here, just don't
throw the field away.

## 5. Idiomatic anchors (principle-of-least-surprise audit)

| API element | Phoenix/Elixir precedent it mirrors |
|---|---|
| `socket \|> Crosswake.Bridge.push("haptics", style: :light)` | `Phoenix.LiveView.push_event/3` chainable-in-a-pipe idiom (same shape as `socket \|> assign(...) \|> put_flash(...)`) |
| Shipped `CrosswakeBridge` JS hook + `handleEvent`/`pushEvent` round trip | The standard `phx-hook` + `this.handleEvent(...)` pattern LiveView already documents for JS-library integration (clipboard, charts, sortable lists) — bounded-bridge commands are one more instance of this seam, not a new one |
| `confirm:` / `menu:` scoped keyword paired to a declared capability | `cache_contract` requiring `offline: :cached_read_only`, `island_contract` requiring `runtime: :offline_island` — same validator-enforced pairing rule already in `policy/validator.ex` |
| `Capability.interaction :: :fire_and_forget \| :answering` | The existing `Capability.rebuild :: :none \| :native_required \| :companion_required` field — same "declarative axis lives on the capability record" pattern `RuntimeLine.RebuildPolicy` already keys off of |
| Deny-reply-in-lieu-of-silent-success on missing shell | `Crosswake.Shell.Denial` — the exact same typed denial vocabulary the bridge already returns for a real native denial; Pack 1 reuses it rather than inventing a parallel "environment error" type |
| `ArgumentError` raised for undeclared-capability misuse | Ecto raising on an unloaded/undeclared association access — a coding mistake gets a loud crash, not a silent runtime branch |
| Menu-action allowlist enforced from route policy | `NimbleOptions`/`Ecto.Changeset`-style schema validation already used for route policy fields in `policy/schema.ex` — the allowlist is data the validator checks, not a string the LiveView trusts at the call site |
| `:telemetry` events for command dispatch/deny/miss | `Crosswake.Telemetry`'s existing typed, low-cardinality, PII-free event catalog (already spans companion/doctor/threadline/sigra/chimeway) — Pack 1 adds `[:crosswake, :bridge, :command, :stop]`-shaped spans to the same catalog, it doesn't start a new one |
| Additive command allowlist growth | `Bridge.Contract.@commands` has already grown release-over-release (`haptics.impact` → `permissions.status` → `notifications.token.get` → `share.invoke` → `files.pick` → `transfer.*`) without a protocol major bump — Pack 1 follows the same additive pattern |

## 6. Versioning/evolution — how control #6 doesn't break controls #1–5

This is already solved machinery, not new design: `Bridge.Contract.@commands`
is an allowlist that has grown every phase without breaking existing routes,
because authorization is **per-route, per-declared-capability**, not
per-protocol-version. Adding, say, `"toast"` as control #6:

1. A new `Capability` entry enters `manifest.capability_registry` with its
   own `rebuild` (`:native_required` — a genuinely new shell affordance) and
   `interaction` (`:fire_and_forget`) fields. `RuntimeLine.RebuildPolicy`
   classifies this automatically via the existing `:capability_family_add`
   change class — no special-casing needed, and no adopter code changes
   required for the four *other* families, because `RebuildPolicy.classify/2`
   already derives its verdict from `Capability.rebuild`, never from a
   change-class label alone (the module's own docs call this out as the
   Expo-EAS/CodePush footgun it's specifically designed to avoid).
2. Existing routes on controls #1–5 never declared `"toast"` in
   `capabilities:`, so `Bridge.Registry.lookup/3` for that route/command pair
   still resolves however it always did — nothing about their manifest entry
   changes.
3. An old shell binary that predates `"toast"` simply never reports it in its
   `capabilities` map at connect time; any route that *does* try to declare
   and use it against that old shell gets `unavailable_capability`, which
   flows through the **same** deny-reply seam described in §3 — the adopter's
   fallback code, already written for the "no shell" case, is identical code
   for the "old shell" case. There is no version-branching for the adopter to
   write by hand.
4. `Bridge.Contract.@version` (currently `1.1.0`) only bumps for a breaking
   *envelope* shape change (removing/renaming a required field), not for
   allowlist growth — consistent with its six-command growth history to date.

## 7. What NOT to build

| Shape | Why it's a trap |
|---|---|
| `Crosswake.native_call("anything", payload)` generic escape hatch | Defeats manifest-driven authorization (you cannot `RouteGate`-check an arbitrary string), turns the bridge into an ad hoc RPC bus, and Crosswake has already had this exact temptation and rejected it: `Crosswake.NativeEscape.Contract` — the codebase's actual "escape hatch" module — is scoped to `@purposes [:media_capture]` only, one typed purpose, not a string-keyed grab bag. Pack 1 must hold that same line. |
| A runtime-registerable plugin/capability registry | Contradicts "the manifest capability registry provides the capability version" as the single source of truth, and directly contradicts `guides/capabilities.md`'s explicit disclaimer: "Crosswake does not present capabilities as a generic plugin catalog." |
| An event bus / pub-sub for arbitrary native→LiveView messages | Breaks "request/reply-only" — you cannot fail-closed-authorize or correlate a stream the way you can a bounded request, and it's a straight line to high-frequency native chatter driving LiveView, which is explicitly out of scope. |
| High-frequency/continuous native state push (sensors, location) | Directly contradicts "bounded, low-frequency." If a route needs continuous native state, that's a `:native_screen` job, not a bounded-bridge one — the thesis already has a home for that need, and it isn't this. |
| One do-everything `<.cw_control type="...">` HEEx component with a stringly-typed `type` | Same trap as the generic call, moved into markup — the compiler and doctor lose the ability to reason about which families exist. If a HEEx convenience wrapper ships at all, it's one small named component per family (`<.cw_confirm>`), never a generic dispatcher. |
| Bundling permission *request* UX into `permissions.status` | The v20 handoff scopes this explicitly to read-only snapshot; a `Crosswake.request_permission/2` belongs to the deferred Capture & Device Controls pack, not Pack 1. |

## Rejected alternatives (summary)

- **Separate `controls:` DSL block** — rejected: splits authorization across
  two lists that must stay in sync by hand; `capabilities:` is already the
  single source `Bridge.Registry` reads.
- **Parameters inlined into a heterogeneous `capabilities:` list** (mixed
  bare strings + keyword lists) — rejected: makes the list unreadable at a
  glance and has no existing validator precedent; the `cache_contract`/
  `island_contract` sibling-key pattern is the established idiom.
- **Declarative HEEx/`data-cw-*` attributes as the primary invocation
  mechanism (Hotwire Native style)** — rejected: fits a stateless-render-per-
  navigation model, not LiveView's persistent-process model, which already
  has a blessed seam (`push_event`/`handleEvent`) for exactly this job.
  Declarative markup is the right shape for the *fallback UI* (the on-page
  confirm buttons, the HTML menu), not for triggering the native call.
- **Raw `push_event` left as an ad hoc adopter convention** (status quo) —
  rejected: this is what Phase 149 already does, and its failure mode (hand-
  built envelopes, no reply path, per-route script duplication) is the
  problem Pack 1 exists to fix.
- **Silent "fallback" for haptics** (e.g., a CSS flash standing in for
  vibration) — rejected as dishonest; a genuine no-op is the only truthful
  option when a physical sensation cannot be simulated.
- **Modeling share/review-prompt outcomes as `success`/`completed`** —
  rejected: neither the Web Share API nor StoreKit/Play In-App Review can
  truthfully report user outcome; only `"requested"` is ever knowable, and
  the contract must say so rather than imply otherwise.

## Consumer-perspective critique

**What would annoy an adopter at 3am:**
- If `Bridge.push/3`'s undeclared-capability check only raised in `:dev` and
  silently no-op'd in `:prod`, an adopter would ship a route that "sometimes
  doesn't do the haptic" and spend an hour distrusting their native shell
  before finding a policy typo. The check must be environment-independent —
  raise always; this is a route-authoring bug, not a runtime state, exactly
  like a missing required Ecto field.
- If confirm's native reply and the on-page button's click routed to
  *different* `handle_event` clauses, a fast double-tap (native dialog
  answers a beat after the user also taps the on-page button out of
  impatience) could double-fire the mutation. Routing both into the
  identical event name/shape is what prevents this — it's not just cleaner
  code, it's the thing that stops a real race condition.
- Nothing about "the shell exists but doesn't support this capability
  version yet" should ever look different, in adopter code, from "there is no
  shell at all." If it did, every adopter would end up writing their own
  three-way branch and inevitably get one branch wrong. Collapsing both into
  one typed deny reply removes an entire class of adopter bugs, not just
  boilerplate.

**The 80% case — is it one line?** Yes, for the fire-and-forget half of
Pack 1 (haptics, share, toast), which is most of what most routes need:

```elixir
{:noreply, socket |> assign(approval: approved) |> Crosswake.Bridge.push("haptics", style: :light)}
```

Confirm/alert are inherently two-sided (a request plus a reply clause), so
they cannot be one line and shouldn't pretend to be — but they are still
exactly the same two `handle_event` clauses (ok/deny) an adopter would
already need to write for a plain Phoenix-only confirm-by-buttons flow, plus
one `Bridge.push` call. Pack 1 adds one extra line of code to a pattern
adopters already know, not a new pattern.

## Recommended API — end to end (haptics + confirm)

```elixir
# router.ex
live("/saas/approvals/:id", ApprovalLive,
  crosswake: [
    id: "saas-approval", runtime: :live_view, entry: :external,
    capabilities: ["haptics", "confirm"],
    confirm: [title: "Reject this request?", confirm_label: "Reject",
              cancel_label: "Keep pending"],
    offline: :cached_read_only, cache_contract: :approval_snapshot_v1,
    security: :standard
  ])

# approval_live.ex
def handle_event("approve", _params, socket) do
  {:ok, approved} = Approvals.approve(socket.assigns.approval.id)
  {:noreply, socket |> assign(approval: approved)
             |> Crosswake.Bridge.push("haptics", style: :light)}
end

def handle_event("reject", _params, socket) do
  {:noreply, socket |> assign(show_reject_panel: true)
             |> Crosswake.Bridge.push("confirm", reply_to: "reject_answered")}
end

def handle_event("reject_answered", %{"status" => "ok", "answer" => "confirm"}, socket),
  do: {:noreply, reject!(socket)}
def handle_event("reject_answered", _deny_or_no_shell, socket),
  do: {:noreply, socket}  # on-page Reject/Keep-pending buttons are already shown
def handle_event("reject_confirmed_on_page", _params, socket),
  do: {:noreply, reject!(socket)}  # buttons target the identical mutation
```

**Biggest tradeoff:** raising `ArgumentError` from `Bridge.push/3` on an
undeclared capability is a hard, unconditional API contract — it means a
route policy typo becomes a crash in production, not a soft warning. I chose
this deliberately over a softer "log and no-op" because the alternative
recreates exactly the silently-degraded behavior Crosswake's whole fail-closed
thesis exists to prevent: a haptic that "just doesn't fire sometimes" is a
worse adopter experience than a loud, obvious crash pointing at the missing
`capabilities:` entry. The cost is that a bad deploy can 500 a route instead
of merely feeling broken — acceptable because route policy is compiled,
reviewable, and doctor-checkable before it ever reaches production traffic.
