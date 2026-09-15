---
id: SEED-015
status: dormant
planted: 2026-09-15
planted_during: quality-ratchet-release Phase 168
trigger_when: any milestone touching the Hotwire integration guide, doctor's shell-posture checks, or adopter onboarding
scope: small (guide section + one doctor check); the underlying behavior is not ours to fix
---

# SEED-015: SSO-fronted origins silently lose the entire native layer on cold boot

## Why This Matters

An adopter whose origin sits behind an SSO gateway that 302s cross-origin (Cloudflare Access, Okta,
Entra, a staging basic-auth gateway) will have their **whole app render inside
`SFSafariViewController`** on first launch. Inside that sheet there is no `WKUserContentController`
of theirs, so the Crosswake bridge, the audio shim, the haptic path and the offline island are all
simply *absent*.

The app keeps working — it is a website — so nothing crashes and nothing logs. Everything native is
just gone. The adopter's founder described it as *"the entire app appears like a 'sheet' pullup UI
element with a big X at top left"*. Haptics looked broken; they were not broken, they were
unreachable.

**The failure mode is a misdiagnosis, not an outage.** An adopter in this state will file bugs
against the bridge. That is the cost Crosswake pays for saying nothing about this.

## This is explicitly not a Crosswake defect

Read off hotwire-native-ios 1.3.1, not inferred: during a **cold boot** the navigation delegate is
`ColdBootVisit`, not `Session`, and it hardcodes its own rule —
`redirectIsCrossOrigin` → `decisionHandler(.cancel)` + `visitDidProposeVisitToLocation(url)` — so
the redirect never reaches `WebViewPolicyManager` at all. The proposal lands in the Router, where
the default Safari handler matches on a host difference alone and presents a `.pageSheet`.

Neither library is misbehaving, and this is emphatically **not** an argument that Hotwire should
change — the reporting adopter, who hit it, argues against relaxing it. `ColdBootVisit` refusing to
cold-boot into a foreign origin is correct behavior. Do not let this seed become a
patch-Hotwire or fork-Hotwire proposal.

There is also **no in-app fix**, and the reason is worth recording:
`ASWebAuthenticationSession` and `SFSafariViewController` both set the SSO cookie in a store the
`WKWebView` cannot read, so the cookie can only be obtained inside the webview that needs it — and
the cold boot refuses to let a foreign origin render there. The constraints have no intersection.

The reporting adopter tried three fixes and refuted every one with a device screenshot: a policy
handler is dead code on this path; a Router `.navigate` opens a Turbo visit of a page carrying no
turbo.js and spins forever; an in-place load races the cold boot's own cancel and produces "frame
load interrupted". All three were reverted. They resolved it by removing Access from the app
origin — i.e. **the fix is architectural on the host side**, and that is the thing Crosswake should
be telling adopters before they spend a day on it.

## When to Surface

Any milestone that touches the Hotwire integration guide, doctor's generated-shell posture checks,
or the adopter onboarding path.

## Scope

Two small pieces, either independently useful:

1. **Guide section** in the Hotwire integration docs: "If your origin is behind SSO." State the
   cold-boot cross-origin rule, state that the native layer is absent rather than broken, and state
   that the resolution is to keep the app origin out of the SSO hop. Name the symptom in the words
   an adopter would search for — a full-screen sheet with an X in the top-left corner.

2. **Doctor check.** The signal available at generation/doctor time: `WKAppBoundDomains` listing a
   host that is **not** the start origin is a strong indicator the adopter has an auth hop the cold
   boot will reject. The reporting adopter's own `Info.plist` carries exactly that signal today.

   The predicate matters, and it is not the obvious one. The check is **not** "is every entry a real,
   resolvable domain" — the reporting adopter's `WKAppBoundDomains` was *correct and complete* and
   they still lost the entire native layer. A correct list says nothing about whether the cold boot
   will let those hosts render. The check is **"does this list name a host that is not the start
   origin"**, and that second condition is the SSO tell. It is cheap.

   Note this is a *different* predicate from the one TODO-006 wants on the same line (TODO-006 is
   about the shipped `example.com` placeholder being a non-origin). Same line, two checks, and they
   should be written as two findings rather than conflated into one "WKAppBoundDomains looks wrong".

## Breadcrumbs

- `priv/templates/crosswake/shell/ios/Info.plist.eex` — ships `WKAppBoundDomains` as a single
  `example.com` entry; the same line is already flagged from a different angle in TODO-006.
- TODO-006 — the `.invalid` origin defect; its notes already carry a shorter version of the
  `WKAppBoundDomains` observation. This seed is the full mechanism behind it.
- TODO-008 / CW-REQ-M7 — arrived in the same adopter report.
- SEED-013 — the simulator-green / device-red family this belongs to.

## The one sentence to ship

Everything above compresses to one adopter-facing fact, and it should be stated in close to this
shape rather than broadened:

> If your origin is fronted by SSO that redirects cross-origin, the native layer is absent on first
> launch, and nothing will tell you.

The fix is on the adopter's infrastructure — not in the shell, and not in Hotwire. Keep the claim
that narrow; a wider claim ("SSO is unsupported") would be wrong.

## Provenance

First B2C Adopter, 2026-09-15, alongside CW-REQ-M7. Filed by them as intel, explicitly **not** as a
Crosswake defect. Evidence (device screenshots of all three refuted fixes) is retained on the
adopter side; it is deliberately not copied here.
