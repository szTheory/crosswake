---
id: SEED-016
status: dormant
planted: 2026-09-15
planted_during: quality-ratchet-release Phase 168
trigger_when: next milestone touching the iOS core bridge seam, the proof lanes, or adopter onboarding guidance
scope: medium (a host-run conformance suite + a guidance section); option 2 below is a separate, larger decision — see "control, not size"
---

# SEED-016: Crosswake requires a host webview it does not supply — and cannot see

## Why This Matters

Crosswake's iOS core ships **no `WKWebView`**. Per D-35, `createBridgeChannel` expects the *host* to
hand it a way to evaluate script against the host's own webview. `crosswake-shell-core-ios`'s
`Package.swift` declares no external package dependencies at all, and the generated shell
(`CrosswakeShellApp.swift.eex`, `CrosswakeCoordinator.swift.eex`, `Info.plist.eex`, the pbxproj)
references no webview framework. Crosswake is framework-agnostic here, deliberately.

The consequence is the seed: **the single most failure-prone integration point in every adopter's
app is invisible to Crosswake and untestable by it.**

An adopter hit exactly this. Their `WKAppBoundDomains` was correct, their bridge was correct, their
install manifest was correct, and `mix crosswake.doctor` exited 0 — while the entire native layer
was absent at runtime, because of a policy decision inside a navigation library Crosswake has never
heard of. **No Crosswake proof lane could have caught it, because none of them can see the host's
webview host.**

This is a gap, not a defect. But it is the gap that makes Crosswake's green gates unfalsifiable at
the seam that matters most.

## Options, in the order the reporting session weighed them

**1. A host-run conformance contract (recommended).** Define what Crosswake actually requires of a
host webview and ship it as a test suite the adopter runs against *their* host:

- script evaluation reaches the page
- `userContentController` handlers survive navigation
- the bridge reply landing pad is reachable after a cold boot
- **the webview presented to the user is the instance the bridge is attached to** — assert the
  visible webview is what `makeCustomWebView` returned

That last one is the cheapest possible check and is the condition the reporting adopter would have
failed. The whole contract is navigation-framework-agnostic, so it holds for Turbo-based hosts,
hand-rolled hosts, and whatever replaces them.

**2. An optional first-party host for the offline-island case.** The island is a non-Turbo page by
definition, so a Turbo navigator is the wrong shape for it specifically. A thin Crosswake-owned
`WKWebView` host scoped to island routes only would remove the framework dependency where it fits
worst, while adopters wanting Turbo navigation keep bringing their own for the rest. Strangler-fig,
not replacement. **This is a much larger commitment than option 1 and should not ride along with
it** — it puts Crosswake back in the business of owning `WKWebView` lifecycle.

**3. Do nothing.** Defensible. Navigation frameworks in this space are mature and maintained,
reimplementing `WKWebView` lifecycle is a well-known trap, and "we don't depend on one" is already
true today.

Recommendation from the reporting session: **do 1 now, consider 2 later.** 1 is cheap, catches a
whole class, and commits Crosswake to owning nothing.

## If Crosswake ever fills this hole: control, not size

A first pass at this seed recorded the adopter's ten-identical-default path rules as *"evidence
about that integration, not about the framework"* and cautioned against reading their case as an
argument against Hotwire. **The reporting session subsequently retracted that framing as too
generous, and it is corrected here** — building on the weaker version would aim a future host at the
wrong target.

**It is a category mismatch, not a size or subset problem.** The adopter's client navigates between
all ten of its entry points with full page loads (`window.location.href = …`), carries no `turbo.js`
anywhere, and uses no Turbo links or frames. Hotwire Native's core abstraction is the **Turbo
visit**, and that app has never satisfied it. "We use a subset" implies growing into a corner of
something that fits; they never fit. The direction of travel makes it worse rather than better —
their roadmap is a strangler-fig onto Sigra **LiveViews**, which are not Turbo either. There is no
future state of that app in which a Turbo navigator is the right host.

This also explains a symptom reported earlier without explanation: a refuted fix that returned
`Router.Decision.navigate` for the identity host and **spun forever**. It was first attributed to the
SSO login page specifically carrying no `turbo.js`. The general truth is that *no page in that app
carries `turbo.js`*, so a Turbo visit of any of them is a visit that can never report completion. The
app works today because the cold-boot path tolerates it, not because the abstraction fits.

**The design consequence, which is the load-bearing part of this seed.** What bit the adopter was
not bloat and not churn. It was a **hardcoded policy inside `ColdBootVisit` that neither
`RouteDecisionHandler` nor `WebViewPolicyDecisionHandler` could reach** — Hotwire publishes two
handler protocols as its extension surface and then bypasses both on cold boot (see [[SEED-015]] for
the mechanism). A *smaller* dependency would not have prevented that. **Owning the policy would.**

So if Crosswake ever fills this hole, the goal is **control, not size**: every navigation policy
decision reachable from a seam, and testable. If such a host ever gets justified on *"fewer lines
than Hotwire"*, it will end up equally inflexible and this whole class recurs. Treat a
lines-of-code argument as a signal the design has gone wrong.

## The honest cost of ever owning a host

Recorded now so nobody discovers it after committing. What Hotwire actually sells is not features —
it is **absorbed WebKit edge cases**: web content process termination and recovery, state
restoration, scroll position, cookie and session continuity across navigations, error surfaces, the
back-swipe gesture. Hotwire's own churn is visible and occasional; **WebKit's is invisible and
constant**, and Hotwire eats it on the adopter's behalf today. Anyone writing a host inherits that
permanently.

The reporting adopter's surface is small enough to make the trade worth it for them — one webview,
full screen, same-origin full-page navigations. **That is a fact about them and it does not
generalize to every adopter.**

**Where it would go, if it goes anywhere:** an optional target *inside* Crosswake, not a new
standalone package. Crosswake's core already requires a webview it does not supply and that hole is
exactly this shape, so filling it makes Crosswake more coherent rather than larger. A separate OSS
repo with one consumer is a maintenance obligation with no feedback signal — **extract when a second
adopter asks**, because that is when you learn what was actually general. The offline island is the
natural first surface, being non-Turbo by definition.

**None of this displaces option 1.** The conformance contract remains the thing to do first: it is
cheap, it is framework-agnostic, and it would have caught the adopter. This section only constrains
what a *later* host would optimize for, if one is ever built.

The reporting adopter is not shedding their navigation framework — nothing is blocked for them —
though they have recorded it as a strangler-fig candidate for their own tree, on the
category-mismatch grounds above rather than on bloat.

## Relationship to neighbouring seeds

- **[[SEED-015]]** (SSO cold boot loses the native layer) is one *instance* of this class: a host
  navigation policy silently detaching the bridge. SEED-016 is the general contract that would make
  such instances detectable by the adopter rather than reported as bridge bugs.
- **[[SEED-014]]** (proof-lane and doctor fidelity) is the sibling complaint that Crosswake's gates
  produce evidence adopters cannot act on. SEED-016 says some of that evidence is not merely
  low-fidelity but *structurally unobtainable* from inside Crosswake — which is why the contract has
  to run in the host.
- **[[SEED-013]]** (adopter device proof-lane reachability) shares the "green gate, absent runtime"
  shape.

## When to Surface

**Trigger:** next milestone touching the iOS core bridge seam, the proof-lane contracts, or adopter
onboarding guidance. Option 1 is the actionable half; treat option 2 as a separate decision needing
its own discussion.

## Provenance

Raised by a peer session working in an adopter tree, with the framework-free claims verified against
that tree (`grep -rln -i hotwire deps/crosswake/priv/templates/ deps/crosswake/lib/` empty;
`Package.swift` declaring no external dependencies) rather than assumed. Sent as an unsolicited
contribution to Crosswake, with no action requested on the adopter's behalf.
