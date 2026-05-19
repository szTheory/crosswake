---
id: SEED-002
status: harvested
planted: 2026-05-17
planted_during: "Phase 5 complete — v1 roadmap complete, proof-backed repo posture reconciled"
trigger_when: "Surface during v2 planning, when Crosswake shifts from proving the v1 substrate to expanding official Phoenix-first native capabilities and commerce support."
scope: Large
resolved_on: 2026-05-19
resolved_by: "Harvested into post-v2 project direction and future requirements"
---

# SEED-002: Build Phoenix-first native capability and commerce support

## Why This Matters

Crosswake now proves the route-policy substrate, manifest contract, bounded bridge, offline posture, pack lifecycle, transfer seams, and one native-screen escape hatch. The next major product pressure is making real Phoenix mobile apps easier to ship without every adopter writing bespoke native bridge code for common device features or hand-rolling mobile purchase flows.

Adjacent ecosystems already show that teams expect batteries-included support for native affordances like alerts, share sheets, permission checks, scanners, notification tokens, and paywall or subscription flows. Crosswake should eventually close those gaps for Phoenix apps, but in a way that stays faithful to its own architecture instead of copying Rails or Hotwire implementation patterns.

## When to Surface

**Trigger:** Surface during v2 planning, when the roadmap moves from finishing the v1 substrate to expanding official native capabilities, first-party companions, and real-app ergonomics for Phoenix teams.

This seed should be presented during `$gsd-new-milestone` when the milestone scope matches any of these conditions:
- the next milestone is about post-v1 capability expansion for Phoenix-backed mobile apps
- the roadmap discussion turns to first-party companion packages or reducing bespoke native work for adopters
- milestone planning starts asking which table-stakes mobile affordances Crosswake should support officially
- milestone planning starts asking how billing, paywalls, or entitlements should work for real Phoenix apps using Crosswake

## Scope Estimate

**Large** — likely a milestone family or multiple phases covering capability selection, contract design, core-vs-companion packaging, proof lanes, and billing/paywall integration seams.

## Breadcrumbs

Related code, docs, and ecosystem references found in the current project context:

- [.planning/PROJECT.md](/Users/jon/projects/crosswake/.planning/PROJECT.md:38) — defines the capability-ladder thesis and bounded bridge posture that future capabilities must preserve
- [.planning/research/FEATURES.md](/Users/jon/projects/crosswake/.planning/research/FEATURES.md:14) — records baseline mobile affordances like camera, files, share sheet, notifications, haptics, and links as expected capability surface
- [.planning/research/FEATURES.md](/Users/jon/projects/crosswake/.planning/research/FEATURES.md:30) — records billing surfaces and other platform-heavy flows as valid native escape pressure, while warning against broad billing abstractions in core
- [.planning/research/FEATURES.md](/Users/jon/projects/crosswake/.planning/research/FEATURES.md:33) — records first-party companion integrations with `sigra`, `chimeway`, `rindle`, and `threadline` as a coherent ecosystem direction
- [guides/bridge.md](/Users/jon/projects/crosswake/guides/bridge.md:7) — documents the existing bounded bridge posture and current explicit command vocabulary
- [guides/native_shell.md](/Users/jon/projects/crosswake/guides/native_shell.md:92) — documents the current single `:native_screen` native-capture escape hatch that future capability work will expand beyond
- [https://masilotti.com/bridge-components/](https://masilotti.com/bridge-components/) — external comparison point for native capability categories such as alert, barcode scanner, biometrics lock, permissions, notification token, share, search, toast, menu, and review prompt
- [https://purchasekit.com/](https://purchasekit.com/) and [https://purchasekit.com/docs](https://purchasekit.com/docs) — external comparison point for mobile purchase/paywall support and normalized purchase lifecycle handling
- [https://hex.pm/users/sztheory](https://hex.pm/users/sztheory) — published library ecosystem that Crosswake should compose with where appropriate
- [https://hex.pm/packages/accrue](https://hex.pm/packages/accrue) — current primary billing/paywall integration candidate for future Phoenix-first commerce support

## Notes

Future milestone family to preserve:

- **Native capability track**
  Crosswake should eventually support the equivalent of the most important mobile-native capability families, but expressed through explicit route ownership, manifest truth, typed contracts, and bounded bridge semantics.

- **Capability buckets**
  - UI/system affordances: alert, menu, native buttons, search, toast, review prompt, share, haptics
  - Device/security affordances: biometrics lock, permission status, notification token, location
  - Capture/scanning affordances: barcode or QR scanner, document scanner, NFC
  - Commerce affordances: paywall presentation, purchase initiation, entitlement refresh, subscription state callbacks

- **Phoenix-first commerce and paywall track**
  Crosswake should eventually make mobile purchase and paywall flows easy for Phoenix apps. This should be Phoenix-first, not Rails-first. StoreKit and Play Billing complexity should be hidden behind official Crosswake surfaces or first-party companions, and purchase lifecycle events should normalize into Phoenix-facing contracts instead of forcing app authors to build the native bridge layer themselves.

- **First-party library integration track**
  Future capability and commerce work should compose with the broader `sztheory` library ecosystem through explicit seams where that is a natural fit.
  - `accrue`, `accrue_admin`, and `accrue_portal` are the current primary billing, entitlement, portal, and paywall-adjacent integration anchors
  - `sigra` is a likely auth and account-identity seam
  - `rindle` is a likely media lifecycle seam for capture, scanning, import, and export flows
  - `chimeway` is a likely push or notification-token seam
  - `threadline` is a likely auditability seam for permissions, purchases, and sensitive device actions
  - do not treat `oarlock` as part of this seed for now

- **Packaging posture**
  The user-facing goal should feel official and batteries included, but not every capability must live in Crosswake core. Some universal or stable capabilities may belong in core, while heavier or more domain-specific work may belong in first-party companion packages.

- **Architecture constraints**
  - keep contracts semantic, typed, versioned, and low-frequency
  - preserve explicit route ownership and capability allowlists
  - stay fail-closed by default
  - do not drift into a generic plugin bus
  - do not market this as a universal framework or copy Hotwire/Rails architecture directly

- **Comparison framing**
  Masilotti’s Bridge Components and PurchaseKit are reference products only. They prove these feature categories matter. Crosswake should build the Phoenix-native equivalent where it fits the thesis.

## Resolution

This seed was harvested rather than executed in `v2.0`.

- Its scope now lives in `.planning/PROJECT.md` as the next milestone candidate for Phoenix-first native capabilities and commerce support.
- Its future-facing requirement shape already exists in `.planning/PROJECT.md` and the archived requirements as `COMP-*` future requirements.
- It remains intentionally out of the shipped `v2.0` scope so the exemplar milestone stays focused on pressure-testing the substrate instead of widening core capability breadth early.
