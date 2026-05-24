# Crosswake JTBD And User-Flow Research

**Project:** Crosswake
**Focus:** Adopter-facing jobs to be done, current flow coverage, future gaps, and diminishing returns
**Updated:** 2026-05-23

## Current JTBD Map

Crosswake currently proves three core jobs. They are not random examples; they are the
three ownership stories the library can explain cleanly today.

### 1. Phoenix-owned mobile product with one narrow native affordance

Crosswake is strong when a team wants to keep the product surface server-owned and use
the shell only for activation, support truth, and one low-frequency semantic native
assist. The Phoenix SaaS Portal lane proves this shape.

### 2. Mostly Phoenix-owned app with one explicit native corridor

Crosswake is also strong when one route clearly needs native ownership, but the rest
of the product should stay Phoenix-owned. The Selective Native Flow lane proves this
shape.

### 3. Mostly Phoenix-owned app with one honest local-first corridor

Crosswake is credible when one route needs real local mutation with journaling and
explicit replay, while neighboring routes stay cached read-only or server-owned. The
Local-First Study Flow lane proves this shape.

## What Is Fully Covered Today

Crosswake has strong coverage for these adopter questions:

- "Can I keep most of my Phoenix SaaS app intact inside a mobile shell?"
- "Can I move exactly one device-heavy route native without changing my whole app architecture?"
- "Can I support one real offline workflow without claiming app-wide sync?"
- "Can I declare route ownership and native prerequisites explicitly?"
- "Can I fail closed instead of silently degrading into generic shell behavior?"

The library also has growing but still partial coverage for these capability-level
questions:

- low-frequency bounded native affordances such as `haptics`, `share`, `app_info`,
  `deep_link`, `permissions.status`, `notification_token`, and `file_picker`
- support truth for capability prerequisites, denial reasons, and rebuild posture

Commerce has vocabulary and boundaries, but not yet a full proof-backed adopter job.

## Biggest Gaps

These are the highest-leverage missing jobs because they add new ownership decisions,
new failure classes, or new support burdens rather than just adding more of the same.

### 1. Commerce And Paywall Corridor

Current state:

- the vocabulary exists
- backend-truth posture is explicit
- provider/storefront execution is still intentionally deferred

Missing adopter question:

- "How do I run a real mobile subscription corridor without letting device callbacks
  become entitlement truth?"

Why it matters:

- subscription products expect this story
- it introduces storefront-sensitive UI, restore flows, reconciliation, and review
  guidance
- it is a new ownership class, not just another capability family

### 2. Notification-Driven Re-Entry Corridor

Current state:

- `notification_token` exists
- deep-link activation exists
- the full "notification arrives, user taps, route opens with honest prerequisites"
  story is not yet proven as an archetype

Missing adopter question:

- "How do notifications re-enter a Phoenix-first app without turning the shell into an
  event-driven control plane?"

Why it matters:

- it combines token acquisition, permission posture, deep links, route activation, and
  partial offline realities
- it is one of the most common mobile expectations for SaaS and companion apps

### 3. Auth And Account-Security Corridor

Current state:

- host-owned auth is acknowledged
- provider-specific guidance remains deferred

Missing adopter question:

- "How do I handle login, re-auth, session expiry, passkeys, MFA, or sensitive account
  recovery without muddying route ownership?"

Why it matters:

- it is a real product adoption blocker for serious SaaS use
- it creates sensitive denial states and native/browser boundary decisions

### 4. Operator Truth And Diagnostic Surfaces

Current state:

- doctor, support matrix, and proof lanes exist
- inspection remains mostly maintainer-facing and text-first

Missing adopter question:

- "When something fails on a real host app, how do I inspect route truth, capability
  truth, and rebuild obligations quickly?"

Why it matters:

- widening support without sharper diagnostics raises support cost faster than it
  raises product value
- this is leverage work for every future flow

### 5. Native-Screen Families Beyond Capture

Current state:

- one clear native-screen corridor exists
- scanner and document scan remain deferred

Missing adopter question:

- "Which future device-heavy flows deserve explicit native ownership instead of bounded
  bridge treatment?"

Why it matters:

- this is where thesis drift is most likely
- it determines whether Crosswake stays disciplined or slides toward generic mobile
  framework behavior

## Proposed Ordering

Recommended ordering for future JTBD and flow expansion:

1. Commerce and paywall corridor
2. Notification-driven re-entry corridor
3. Operator truth and diagnostics expansion
4. Auth and account-security corridor
5. Next explicit native-screen family only after the first four are sharper

Rationale:

- Commerce creates the biggest missing adopter story and has the most policy and
  reconciliation pressure.
- Notifications are common, high-value, and combine already-shipped primitives into a
  missing product corridor.
- Diagnostics should deepen before too many new support claims land.
- Auth is essential, but it is also provider- and policy-sensitive enough that the
  library should approach it after the route/capability/diagnostic contract is even
  clearer.
- More native-screen families should come last because they are the easiest way to
  widen scope without equivalent adopter leverage.

## Diminishing Returns Boundary

The right stopping rule is not "we shipped lots of capabilities." It is "we can cover
the main ownership stories adopters actually expect."

Crosswake is close to "feature-complete enough for expected adopter flows" when it has
one proof-backed story for each of these:

- Phoenix-owned app with narrow native affordances
- explicit native-screen corridor
- honest local-first corridor
- commerce and paywall corridor
- notification and re-entry corridor
- auth and account-security-sensitive corridor

And for each one, Crosswake must publish:

- route-ownership guidance
- denial and degraded behavior
- prerequisites
- rebuild expectations
- proof posture

After that point, additional JTBD research starts showing diminishing returns unless it
surfaces one of these:

- a genuinely new ownership category
- a new failure class that changes support truth
- a new operator burden that current diagnostics do not expose

Research is probably past the efficient frontier when new findings mostly say:

- "another low-frequency capability belongs on a Phoenix-owned route"
- "another provider fits the same backend-owned seam"
- "another vertical app looks like one of the already-proven archetypes"

That kind of result is useful for examples and companion work, but not for expanding
the core JTBD map.

## Ecosystem Lessons That Support This Ordering

These references are informative, not normative. The point is to extract the pressure
they reveal and map it onto Crosswake’s thesis.

### Phoenix / LiveView / Fly

Fly’s Elixir guidance emphasizes that globally deployed Phoenix LiveView apps can feel
fast and low-latency, which reinforces the case for keeping server-owned routes
server-owned when the interaction model still fits LiveView.

Source:

- Fly Elixir docs: https://fly.io/docs/elixir/

### React Native

React Native’s official native-platform docs separate Native Modules from Native
Components. That split is a useful warning: some surfaces are simple platform access,
others are full native UI ownership. Crosswake should keep making that distinction
route-visible instead of flattening everything into a capability bucket.

Source:

- React Native Native Platform: https://reactnative.dev/docs/0.82/native-platform

### Flutter

Flutter’s add-to-app model is a strong reminder that embedded runtime strategies work
best when used piecemeal rather than as a reason to replace the host app’s whole
architecture. Its platform-channel docs also show how quickly bridge surfaces become
system design concerns once threading and task queues matter.

Sources:

- Flutter Add-to-App: https://docs.flutter.dev/add-to-app
- Flutter Platform Channels: https://docs.flutter.dev/platform-integration/platform-channels

### RevenueCat

RevenueCat’s entitlement docs and backend architecture materials reinforce the
importance of separating access vocabulary from system-of-record authority. They are a
good external validation of Crosswake’s backend-truth commerce stance.

Sources:

- RevenueCat Entitlements: https://www.revenuecat.com/docs/getting-started/entitlements
- RevenueCat Backend Architecture: https://www.revenuecat.com/guides/revenuecat-android-sdk/backend-architecture

## Defaults For Future Planning

When future milestone work asks "what flow should we build next?" use these defaults:

- prefer jobs that create a new ownership corridor over jobs that merely add another
  bounded capability
- prefer operator truth before breadth when support claims are expanding
- prefer backend-truth seams over device-authority shortcuts
- prefer one proof-backed archetype over many docs-only variants

## Update Protocol

When rerunning the JTBD/user-flow review in the future:

1. Diff shipped milestones and phase summaries since the last update.
2. Update the public guide only where the adopter mental model changed.
3. Update this memo’s `What Is Fully Covered Today`, `Biggest Gaps`, and `Proposed Ordering` sections.
4. Only expand the JTBD map if a newly shipped feature creates a new ownership story,
   failure class, or support obligation.
