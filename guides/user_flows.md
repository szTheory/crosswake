# Crosswake User Flows And Jobs To Be Done

Crosswake is easiest to understand when you stop thinking about frameworks and start
thinking about jobs.

Not "how do I get mobile features into Phoenix?"

Think instead:

- How do I keep my main product Phoenix-owned on mobile without lying to myself?
- How do I carve out one device-heavy corridor without turning the whole app native?
- How do I support one meaningful offline workflow without pretending the whole app is
  local-first?

That is the real shape of Crosswake today.

If you want the profile matrix first, read
[guides/adopter_profiles.md](adopter_profiles.md).
If you want the route-owner decision map before the examples, read
[guides/route_policy.md](route_policy.md).
If you want to apply that map to an existing Phoenix product, read
[guides/web_to_mobile_migration.md](web_to_mobile_migration.md).
If you want the boundary details after this guide clicks, keep
[guides/bridge.md](bridge.md),
[guides/packs.md](packs.md),
[guides/offline.md](offline.md),
[guides/commerce.md](commerce.md), and
[guides/support_matrix.md](support_matrix.md)
nearby.

## Why Crosswake Exists

Most Phoenix teams do not actually want a universal mobile UI framework.

They want something much more practical:

- keep the product logic and most screens in Phoenix
- use native ownership only where it is clearly the right tool
- keep offline claims honest
- ship mobile apps without inventing a generic plugin bus
- know exactly what is supported and what is still their responsibility

Crosswake exists to make those decisions explicit per route.

That is why the core question in Crosswake is never "can mobile do this?"

It is:

**Who should own this route?**

## The Core Mental Model

Think of Crosswake as a route-by-route ownership map.

Each important route in your app tends to fall into one of a few buckets:

1. Phoenix should own it end to end.
2. Phoenix should own the route, but the shell may help with one small native affordance.
3. The route can degrade to cached read-only behavior.
4. One route needs true local-first mutation and replay.
5. One route needs native ownership because the device interaction loop is the product.

Crosswake gives you language and contracts for those buckets. It does not try to blur
them together.

That is the memorable rule:

**Crosswake does not "make mobile happen." It makes the crossing explicit.**

## Three Canonical Jobs

Crosswake currently proves three canonical jobs. If your app fits one of these, the
library is speaking your language already.

### Job 1: Keep The Main Product Phoenix-Owned On Mobile

This is the `Phoenix SaaS Portal` job.

**Trigger**

You have a normal SaaS product: dashboard, accounts, approvals, settings, maybe some
deep links from email or notifications. Most of the product is already working well as
LiveView. You do not want to rewrite it into a mobile UI stack just to get a credible
app in the store.

**Desired outcome**

Keep the main product Phoenix-owned, put it inside an honest shell, and add one narrow
native flourish where it actually helps.

**What Crosswake is really buying you**

- a shell that activates routes from manifest truth instead of generic WebView vibes
- explicit denial behavior when a route is unsupported
- one bounded bridge seam for low-frequency native help
- a support posture that tells you what is real and what is not

**Happy-path flow**

Imagine an approvals workflow in your SaaS.

1. A manager opens the app from a deep link into an approval detail screen.
2. The shell resolves that route from manifest truth before loading the runtime.
3. The route stays `:live_view`; Phoenix still owns the data, rendering, and decision.
4. The manager approves the request.
5. The route optionally asks for `haptics` as a one-shot confirmation signal.
6. The approval succeeds even if haptics does not.

The product authority never left Phoenix. The shell helped, but it did not take over.

**Degraded path**

- If the shell cannot activate the route honestly, the user gets `route unavailable`.
- If the shell cannot satisfy the native affordance, the Phoenix-owned action still
  completes and the route remains authoritative.

**Why this boundary is right**

This is the sweet spot for teams who mostly need "our Phoenix app, but mobile and
credible." Crosswake helps you avoid overreacting and rebuilding product screens that
already belong on the server.

### Job 2: Move One Device-Heavy Corridor Native Without Contaminating The Rest

This is the `Selective Native Flow` job.

**Trigger**

Most of your app is still fine as Phoenix-owned UI, but one corridor is clearly a bad
fit for a bounded web container. Common example: capture evidence for a claim,
inspection, or field workflow.

**Desired outcome**

Promote exactly one route into explicit native ownership, keep the surrounding queue,
detail, and review surfaces Phoenix-owned, and make the handoff obvious.

**What Crosswake is really buying you**

- explicit `:native_screen` ownership instead of a blurry web fallback
- route-local pack and transfer seams
- fail-closed activation when the native prerequisites are missing
- discipline against "while we're here, let's move five more flows native"

**Happy-path flow**

Imagine a claims app.

1. An adjuster opens a Phoenix-owned claims queue.
2. They choose one claim and move through Phoenix-owned detail and review screens.
3. They tap `Capture evidence`.
4. That route is declared `:native_screen`, so the shell owns the capture session.
5. Media is staged locally.
6. Phoenix regains control when the user returns to review and explicitly starts the
   upload preparation flow.

Only the capture corridor goes native. The rest of the product keeps the simpler,
safer ownership model.

**Media evidence recovery proof**

Crosswake also ships a hermetic Rindle proof lane for the recovery side of this job. The proof language is intentionally narrow:

- `Capture recorded locally; media is not available yet`
- `Upload failed during simulated network degradation`
- `Evidence is queued for reconciliation`
- `Network recovered. Reconciliation can retry`
- `Device evidence recorded; backend verification still required`
- `Backend verification in progress`
- `Backend verified media is available`
- `Backend rejected this media object`

`This proof does not use a real storage provider`, and `Local capture evidence does not grant media availability`. The proof models queued evidence, Rindle reconciliation, projection, and backend verification. Host apps still choose their own persistence and storage architecture.

**Degraded path**

- If the required pack is missing or incompatible, activation fails with
  `pack_incompatible`.
- If native capture is required, Crosswake does not silently dump the user into a web
  upload fallback and pretend the experience is equivalent.

**Why this boundary is right**

Device-heavy loops have a way of spreading. Crosswake’s job here is not just to help
you go native once. It is to stop that one native decision from infecting the rest of
the app architecture.

### Job 3: Keep One Meaningful Workflow Useful Offline Without Pretending The Whole App Is Local-First

This is the `Local-First Study Flow` job.

**Trigger**

You have one route where a user should keep making progress offline, but the rest of
the app still lives comfortably in Phoenix and on the server.

**Desired outcome**

Support one real local-first workflow with journaling and replay, while keeping nearby
read-only routes clearly different from local mutation authority.

**What Crosswake is really buying you**

- a clear distinction between cached read-only routes and true offline islands
- explicit journal and replay semantics
- conflict visibility instead of silent overwrite stories
- a narrow, believable offline claim

**Happy-path flow**

Imagine a study or training app.

1. A learner opens a study session on a train with bad connectivity.
2. The study session route is an `:offline_island`.
3. Answers and progress are saved locally.
4. Completed semantic actions are appended to a journal.
5. A nearby history route can still show cached read-only data.
6. When connectivity returns, replay runs explicitly and Phoenix becomes authoritative
   again after reconciliation.

This is not "the app works offline." It is "this route has a real local-first
contract."

**Degraded path**

- Replay may end in `accepted`, `rejected`, or `conflict`.
- `conflict requires attention` is a feature, not a defect. It is Crosswake refusing
  to invent fake certainty.
- There is no promise of broad background sync or magical app-wide offline state.

**Why this boundary is right**

Offline credibility comes from saying less and proving more. Crosswake would rather
ship one honest offline island than market a vague sync fantasy.

## Route-By-Route User Flows

When you adopt Crosswake, the real work is to classify your routes honestly.

### Keep It `:live_view`

Use this when:

- the route is mostly server truth and normal product interaction
- mobile adds convenience, not ownership pressure
- failure should look like ordinary Phoenix behavior, not native session recovery

Typical examples:

- dashboard
- account detail
- settings
- approval list
- approval detail
- billing history

### Keep It Phoenix-Owned, Add One Bounded Capability

Use this when:

- the route stays server-owned
- the native interaction is one-shot and semantic
- the shell is helping, not driving

Typical examples:

- haptic confirmation after approval
- share a generated link or export
- read app info
- inspect notification permission status before showing setup guidance

### Notification Re-Entry For A Phoenix-Owned Route

Use this when a notification interaction should attempt to open a Phoenix-owned route without letting the notification become authority.

Typical example: a SaaS approval route with `notification_open: [actions: ["tap", "approve"]]`, `auth_min_level: :mfa`, and `requires_recent_auth: 300`.

Flow:

1. Backend token binding and one-time open intent records are created by the host.
2. A simulated notification-open event becomes `NotificationOpenEvidence`.
3. Chimeway resolves the open intent against the manifest-known route and action allowlist.
4. Notification open resolved through RouteGate.
5. Sigra checks backend-projected session authority and recent authentication.
6. Recent authentication required before opening this route returns a step-up denial and no fallback route is activated.
7. Fresh backend MFA allows the Phoenix-owned route to activate.

Token evidence is bound by the backend; possession does not grant access. APNs/FCM delivery is not part of this proof.

### Use Cached Read-Only

Use this when:

- stale content is acceptable
- local mutation is not
- the route should degrade, not fork into a local authority model

Typical examples:

- study history
- content library
- read-only reference material

### Use `:offline_island`

Use this when:

- progress must continue offline
- semantic mutations can be journaled
- replay and conflict semantics are acceptable product behavior

Typical examples:

- study session
- training checklist with explicit replay

### Use `:native_screen`

Use this when:

- the device session loop is the product
- permission choreography or capture fidelity matters
- pretending the route is "just another bridge call" would be dishonest

Typical examples:

- camera-driven evidence capture
- future scanner or document scan corridors when they are truly native-first

## What Crosswake Deliberately Does Not Do

Crosswake is not trying to be:

- a universal shared UI system
- a generic WebView wrapper
- a plugin marketplace
- a high-frequency client-state bridge
- an app-wide offline engine
- a billing engine

Those are not missing marketing bullets. They are deliberate thesis protection.

## How To Decide If Your Flow Fits

Ask these in order:

1. If mobile vanished, would Phoenix still be the obvious owner of this route?
2. Is the native help one-shot and semantic, or is it the interaction loop itself?
3. If offline matters, do I need cached read-only or true local mutation?
4. If the route fails, do I want explicit denial, explicit conflict, or a native
   session surface?

If your answers cluster around:

- mostly Phoenix, one narrow affordance: Crosswake already fits well
- one device-heavy corridor: Crosswake already fits well
- one honest offline workflow: Crosswake already fits well
- broad plugin catalogs, constant native chatter, or app-wide sync magic: you are
  outside the current thesis

## What Is Next

The next most natural jobs for Crosswake to deepen are:

- commerce and paywall corridors
- notification-driven re-entry flows
- auth and account-security-sensitive mobile seams
- richer operator truth and diagnostics

Those matter because they introduce new ownership decisions, new denial behavior, and
new support obligations. They are more valuable than piling on minor capability
families that do not change the route-ownership story.

For the deeper roadmap view of those gaps and their likely order, read the planning
research memo maintained alongside the project’s milestone artifacts.
