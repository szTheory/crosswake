# ADR: First B2C Adopter Readiness

This document records the decisions that govern Crosswake while it prepares for its first real
consumer adopter. The adopter is intentionally identified only as **First B2C Adopter**. Do not
add identifying business, founder, pricing, geography, customer, or proprietary-domain details to
this repository.

## GET-6 — Crosswake is infrastructure for the First B2C Adopter

**Decision**

Treat Crosswake as infrastructure for the First B2C Adopter. Sequence work only by what proves one
real Phoenix application on one physical iPhone with one offline mutation island. Stop after the
dated v21 adoption proof unless that proof exposes a blocking defect.

**Why**

Framework generalization has no natural stopping condition. The current substrate is already much
broader than the first adopter's public-release path requires, while physical-device proof,
host-reusable proof, privacy-safe replay, and real offline media remain gaps. Infrastructure
framing creates a forcing function and protects the adopter from being starved by framework work.

**Alternatives considered**

- Operate Crosswake as an independent business line with positioning, launch collateral, broad
  Android parity, multiple adopter profiles, and a wider native-control catalog.
- Continue switching between infrastructure and business-line behavior without declaring either.

**What would change my mind**

Two independent active adopters need overlapping generalized behavior, or Crosswake receives a
separately funded business-line mandate with its own schedule and success metrics.

**Date**

2026-07-30

**Confidence**

High

**Status**

Accepted

## Alpha does not depend on Crosswake

**Decision**

If the First B2C Adopter's customer Alpha is web-only, Crosswake has no Alpha deliverable. A
one-day route inventory may run early to expose design risk, but it must not delay the monolith,
billing, or customer acquisition.

**Why**

The adopter can validate revenue on the web. Crosswake belongs to the later public-release path
where iPhone and offline study are required.

**Alternatives considered**

- Make native shipping an Alpha gate.
- Treat the route inventory as product implementation rather than a bounded design input.

**What would change my mind**

The adopter makes iPhone availability a contractual Alpha promise or obtains evidence that the
target Alpha cohort cannot use the product without offline study.

**Date**

2026-07-30

**Confidence**

High

**Status**

Accepted

## v21 is an iOS-only adoption milestone

**Decision**

Freeze Android at its current generated-shell and hermetic JVM proof posture. Do not add Android
features, templates, device proof, parity work, or Android release requirements during v21.

**Why**

Android is outside the first adopter's public v1. Maintaining parity doubles native implementation,
review, proof, and release surface without moving the adoption milestone.

**Alternatives considered**

- Preserve feature parity for every shared contract change.
- Delete Android generation entirely.

**What would change my mind**

The first adopter brings Android into its committed release scope, or a second active adopter needs
Android before the iPhone proof is complete.

**Date**

2026-07-30

**Confidence**

High

**Status**

Accepted

## The highest-impact framework change is a host-reusable proof lane

**Decision**

Build `mix crosswake.gen.proof_lane ios` as the first reusable v21 implementation change. It copies
host-owned, configurable ExUnit, Playwright, shell, and physical-device proof scaffolding. Time-box
the extraction to three focused days.

**Why**

The first adopter already has valuable browser tests and fixtures. Crosswake's current proof lane
is credible but tied to its in-repository example host. A narrow generator lets the adopter
preserve browser coverage and add only the native/offline flows the browser cannot reach.

**Alternatives considered**

- Build pack storage first.
- Build more native controls.
- Add more doctor taxonomy.
- Treat a one-off device run as sufficient test infrastructure.

**What would change my mind**

By the end of the three-day time-box, existing host tests cannot be parameterized without
framework-specific coupling. In that case, stop generalizing and copy an adopter-specific slice.

**Date**

2026-07-30

**Confidence**

High

**Status**

Accepted

## Offline journal payloads are sensitive and scope-bound

**Decision**

Crosswake core requires an opaque `scope_ref` on journal and replay envelopes and treats payloads
as sensitive. Outboxes are partitioned by scope; replay stops on logout or account switch; raw
payloads are excluded from telemetry, doctor output, inspection, and evidence artifacts. The host
maps scope to an account, authorizes replay, and owns retention, encryption, and logout cleanup.

**Why**

Offline mutations can contain learner-authored free-form content. A technically correct
exactly-once replay is still unsafe if events cross accounts or leak through diagnostics.

**Alternatives considered**

- Make payload privacy entirely host-owned.
- Teach core the adopter's domain payload schema.
- Permit raw payloads in proof artifacts for easier debugging.

**What would change my mind**

Crosswake stops transporting opaque host mutation payloads, or a stronger platform storage
boundary replaces the outbox contract while preserving account isolation and redaction.

**Date**

2026-07-30

**Confidence**

High

**Status**

Accepted

## Pronunciation media uses a narrow host-supplied iOS pack adapter

**Decision**

Move the pack boundary only far enough to support one host-supplied iOS foreground installer.
Crosswake owns declarations, lifecycle vocabulary, installed inventory, activation denial, and
diagnostics. The host owns archive URLs, authentication, content grouping, codecs, CDN behavior,
retention, storage budget, UI, and the actual download. Availability is granted only after size and
SHA-256 verification followed by atomic installation.

**Why**

Offline audio is a release requirement, while Crosswake currently simulates native pack
installation. A bounded adapter closes that collision without turning Crosswake into a content
distribution or generic storage product.

**Alternatives considered**

- Claim the existing simulated pack transition as production storage.
- Build background transfer, delta updates, eviction policy, and both-platform storage.
- Leave pack lifecycle entirely host-specific with no activation contract.

**What would change my mind**

Two active adopters demonstrate the same storage, eviction, and background-transfer requirements,
or iOS platform constraints make a foreground atomic installer insufficient for the first proof.

**Date**

2026-07-30

**Confidence**

Medium-high

**Status**

Accepted

## Server-side disablement remains host-owned

**Decision**

Use the existing route `gated_by` seam with a host-supplied flag source. The replay endpoint must
re-check both authorization and the flag. A disabled path retains queued events and reports a
visible blocked state. Do not build a Crosswake flag service.

**Why**

App Store latency makes server-side disablement essential, but flag evaluation and rollout policy
already belong to the host. Crosswake only needs to preserve the fail-closed route and replay
contract.

**Alternatives considered**

- Add a Crosswake-specific remote-config service.
- Disable only route entry while allowing queued replay to continue silently.

**What would change my mind**

The existing route gate cannot represent a safe native-path kill switch without expanding its
public contract, as demonstrated by the physical-device proof.

**Date**

2026-07-30

**Confidence**

High

**Status**

Accepted

## The broad sync non-goals remain in force

**Decision**

Do not claim generic app-wide sync, background sync, silent last-write-wins, multiple proven
islands, productionized generic native content-pack storage, or broad reusable runtime sync
helpers. v21 may add privacy-safe envelope constraints, test scaffolding, and one host-supplied iOS
pack adapter only.

**Why**

One route-local journal and replay flow is the honest unit of proof. General sync abstractions would
hide domain conflicts, privacy rules, and authority decisions that belong to the host.

**Alternatives considered**

- Promote the example outbox into a generic sync engine.
- Add reusable domain reconciliation and conflict-resolution helpers.

**What would change my mind**

At least two independent adopters prove the same mutation, conflict, and storage semantics and the
shared contract can remain fail-closed without erasing host authority.

**Date**

2026-07-30

**Confidence**

High

**Status**

Accepted

## Proxy audit for the unavailable historical failure taxonomy

The canonical names from the adopter's earlier product history are intentionally not stored here.
Until the adopter supplies a sanitized taxonomy, v21 decisions are tested against these six proxy
risks:

1. Framework work starves the product that needs it.
2. A team of one accumulates operational surface.
3. Mobile behavior is treated as validated before device evidence exists.
4. A rewrite discards valuable automated tests and fixtures.
5. Offline support is claimed more broadly than the proven island.
6. App Store latency leaves a broken binary path without server-side disablement.

