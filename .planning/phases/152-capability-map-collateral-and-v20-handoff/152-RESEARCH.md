# Phase 152: Capability Map, Collateral, and v20 Handoff - Research

**Researched:** 2026-07-12
**Domain:** Phoenix/Elixir support-truth projection, showcase proof, collateral guardrails, and v20 planning handoff
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

Source copied from `.planning/phases/152-capability-map-collateral-and-v20-handoff/152-CONTEXT.md`. [VERIFIED: codebase:.planning/phases/152-capability-map-collateral-and-v20-handoff/152-CONTEXT.md]

### Locked Decisions

#### Capability Map Shape
- **D-01:** Build a narrow, typed v19 capability-map projection as the recommended source of truth. It should sit next to the existing support-truth system, likely as `Crosswake.CapabilityMap` or an equivalent module, rather than living only as prose.
- **D-02:** The projection should classify each capability as `shipped`, `demoed`, `missing`, `deferred`, or `next-pack candidate`, using phase-appropriate display labels that match the existing showcase vocabulary: `Available today`, `Proof-backed example`, `Demo pressure`, `Advisory evidence`, `Future gap`, and `Next-pack candidate`.
- **D-03:** Each row should carry capability/surface, route/evidence source, current category, route runtime owner, package owner, proof posture, denial/fallback behavior, and v20 implication.
- **D-04:** Package ownership should stay explicit and conservative. Recommended ownership classes: `core`, `native shell`, `first-party companion`, `example/docs-only`, and `deferred`.
- **D-05:** Proof posture should use the existing product language where possible: `merge-blocking`, `advisory`, `not-yet-proven`, and `unsupported`. Screenshots are not a proof posture.
- **D-06:** Render an adopter-readable guide from the projection, likely `guides/capability_map.md`. The guide should answer: what is supported today, what has example proof, what is demo pressure, what is deferred, and what v20 intends to pick up.
- **D-07:** Avoid a dashboard, generic plugin registry, or generated-docs system in this phase. A small Mix task or renderer is acceptable only if it reduces drift and keeps the canonical data small.

#### v20 Native Controls Pack 1
- **D-08:** v20 Pack 1 should be bounded, low-frequency, route-local native controls. Recommended primary candidates: alert/confirm, menu or action-button affordances, haptics, share, and toast/review prompt if support truth and policy checks are explicit.
- **D-09:** `permissions.status` and `notification_token` may be included only as read-only/provider-snapshot/evidence surfaces. They must not imply permission-request sprawl, token delivery truth, backend registration truth, APNs/FCM delivery support, or universal notification handling.
- **D-10:** Defer camera, scanner, document scan, media upload, native storage, offline sync helpers, and commerce provider integration to named later packs with promotion criteria.
- **D-11:** Recommended later pack names: Capture & Device Controls, Commerce/Paywall Productionization, Offline Sync/Native Storage Productization, and Operator Dashboard. These should be handoff items, not Phase 152 build work.
- **D-12:** Commerce/paywall production provider work remains future scope. Backend entitlement projection is the authority; device or storefront evidence must not be rendered as subscriber truth.
- **D-13:** The v20 brief should be planning-only and decision-ready, likely `.planning/phases/152-capability-map-collateral-and-v20-handoff/152-V20-HANDOFF.md`, with links from public docs where useful. It should not reopen the whole strategic arc.

#### Proof And Collateral
- **D-14:** Keep route-tour proof semantic-first. Playwright assertions and route-tour evidence establish behavior; screenshots are collateral captured after those assertions pass.
- **D-15:** Generalize `examples/phoenix_host/e2e/support/evidence_manifest.ts` beyond Fieldserv so it covers the showcase hub, AdminPilot, Fieldserv, LearnLoop, bridge behavior, offline study behavior, native fallback, and capability pressure entries.
- **D-16:** Evidence manifest rows should include known limitations and retention labels. They should distinguish product-surface proof, advisory evidence, demo pressure, future gap, and next-pack candidate posture.
- **D-17:** Public docs should add a light capability-map entry point from `README.md` and `examples/phoenix_host/README.md`, without turning either README into a full support database.
- **D-18:** Optional screenshot/collateral bundles are acceptable only if their labels are honest and guard-tested. Good labels: `Web proof`, `Advisory evidence`, `Demo pressure`, `Future gap`, and `Next-pack candidate`.
- **D-19:** Fixture reset proof must remain explicit. Server reset does not clear browser-owned IndexedDB, local outboxes, or other browser state; route-tour/browser helpers own browser-state reset.

#### Support-Truth Guardrails
- **D-20:** Use canonical typed support/capability data with renderer and drift tests as the default guardrail level. Add a narrow forbidden-claim scanner as a second layer.
- **D-21:** Merge-block canonical label allowlists, catalog/support-matrix/capability-map parity, evidence-manifest schema validity, and docs/support-matrix render parity.
- **D-22:** Merge-block `example/docs-only`, `deferred`, or advisory capability rows if they render as broad `supported` claims without explicit future/deferred/demo posture.
- **D-23:** Merge-block screenshot metadata or docs that present screenshots as correctness proof. Screenshots can show product surface; they cannot certify native/device/provider behavior.
- **D-24:** Merge-block broad native/plugin support claims, device/emulator/JVM evidence laundering, `works offline` or local-first copy without journal/outbox/reconciliation proof, live StoreKit/Play Billing/RevenueCat support claims, and purchase/subscriber/unlock claims before backend-granted projection.
- **D-25:** Keep visual screenshot quality, emulator/device freshness, live provider freshness, and prose style warnings advisory unless they affect support truth.

#### UI, UX, And Brand Surface
- **D-26:** The capability guide and collateral should be reader-first. Start with `what works today`, `what evidence exists`, and `what v20 will do`; keep backend mechanics behind deeper sections unless support truth requires them.
- **D-27:** Use the current `brandbook/BRAND-SPEC.md` as brand authority when prompt-era brand guidance conflicts. Favor calm technical presentation, route cards, runtime badges, capability chips, text labels in addition to color, visible focus, light/dark/system support, and WCAG AA contrast.
- **D-28:** Microcopy should be status-oriented and specific. Preferred phrasing includes `Demo pressure`, `Future gap`, `Backend projection required`, `The host app owns this native screen`, and `Screenshots are collateral after route-tour assertions`.
- **D-29:** Avoid copy such as `magic bridge`, `everything works offline`, `native mobile with no native work`, `generic plugin support`, or any wording that hides runtime ownership.

#### Ecosystem Lessons Applied
- **D-30:** Follow Phoenix idiom by putting support and capability truth behind explicit Elixir module APIs with ExUnit coverage, similar to existing context-boundary practice, instead of scattering truth through markdown tables.
- **D-31:** Learn from Hotwire Native: route/path configuration, web-first screens, and bridge/native components work when boundaries are explicit. The footgun is letting bridge components become a broad plugin surface.
- **D-32:** Learn from Capacitor, Expo config plugins, and Flutter platform channels: native capability support needs permission, platform, version, and failure-mode truth. The footgun is advertising capability presence without install/config/runtime support details.
- **D-33:** Learn from Android offline-first architecture: true offline behavior starts in the data layer with local sources, write queues, conflict/retry behavior, and reconciliation. Cached read-only pages are not local-first mutation.
- **D-34:** Learn from Apple and Google billing guidance: backend verification/projection is the stable entitlement authority. Native purchase events are evidence, not product authorization truth.

### the agent's Discretion

The user asked for a one-shot, cohesive recommendation set across all gray areas. Downstream agents should treat the decisions above as the recommended path unless implementation discovery finds a concrete contradiction in the codebase.

### Deferred Ideas (OUT OF SCOPE)

- Native capture/scanner/document-scan/media-upload production pack: defer to Capture & Device Controls.
- Production commerce providers, StoreKit/Play Billing/RevenueCat adapter support, and subscription entitlement automation: defer to Commerce/Paywall Productionization.
- Native storage productization, reusable sync helpers, and true local-first mutation beyond the LearnLoop offline island proof: defer to Offline Sync/Native Storage Productization.
- Crosswake operator dashboard or support-truth UI: defer until support truth becomes too large for docs plus typed projection.
- Broad native plugin ecosystem or Capacitor-style plugin catalog: defer indefinitely unless it can preserve explicit route ownership and proof posture.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| CAPMAP-01 | Capability map classifies each relevant native capability shipped/demoed/missing/deferred/next-pack candidate. | Use a typed `Crosswake.CapabilityMap` projection with enum validation and parity against support matrix, manifest capability catalog, and showcase catalog labels. [VERIFIED: codebase:.planning/REQUIREMENTS.md] [VERIFIED: codebase:lib/crosswake/support_matrix/support_matrix.ex] [VERIFIED: codebase:examples/phoenix_host/lib/crosswake_example/showcase/catalog.ex] |
| CAPMAP-02 | Intended package ownership per capability: core, first-party companion, native shell, example/docs-only, deferred. | Add explicit package-owner fields in capability-map rows; map existing manifest classes `:core`, `:companion`, `:example_docs_only`, `:defer` and derive `native shell` only where route ownership/rebuild semantics justify it. [VERIFIED: codebase:.planning/phases/152-capability-map-collateral-and-v20-handoff/152-CONTEXT.md] [VERIFIED: codebase:lib/crosswake/manifest/types.ex] |
| CAPMAP-03 | Proof posture: merge-blocking, advisory, not-yet-proven, unsupported. | Keep proof posture separate from screenshot/collateral labels; validate via enum allowlists and docs scanner. [VERIFIED: codebase:.planning/phases/152-capability-map-collateral-and-v20-handoff/152-CONTEXT.md] [VERIFIED: codebase:test/crosswake/guides/evidence_manifest_test.exs] |
| CAPMAP-04 | Maintainer can use map to define v20 Pack 1 without relitigating arc. | Generate `guides/capability_map.md` and write `152-V20-HANDOFF.md` with Pack 1 candidates, exclusions, promotion criteria, and named later packs. [VERIFIED: codebase:.planning/ROADMAP.md] [VERIFIED: codebase:.planning/STATE.md] |
| PROOF-01 | CI/local verification can reset fixtures and prove deterministic showcase data does not duplicate/drift. | Reuse `Showcase.Reset` and existing reset tests; keep browser-state reset owned by Playwright helpers. [VERIFIED: codebase:examples/phoenix_host/lib/crosswake_example/showcase/reset.ex] [VERIFIED: codebase:examples/phoenix_host/test/crosswake_example/showcase/reset_test.exs] |
| PROOF-02 | Browser route-tour coverage exercises showcase hub and one happy path per lane. | Expand route-tour evidence-manifest coverage for hub, AdminPilot, Fieldserv, LearnLoop, bridge, offline study, and native fallback entries. [VERIFIED: codebase:examples/phoenix_host/e2e/route_tour.spec.ts] [VERIFIED: codebase:examples/phoenix_host/e2e/learnloop_route_tour.spec.ts] |
| PROOF-03 | Structural docs/support tests prevent unsupported native controls presented as shipped. | Add forbidden-claim scanner and parity tests over capability map, support matrix, evidence manifest, README entry points, and collateral metadata. [VERIFIED: codebase:test/crosswake/support_matrix/support_matrix_test.exs] [VERIFIED: codebase:test/crosswake/guides/collateral_table_test.exs] |
| PROOF-04 | Collateral/docs describe today/demo pressure/planned v20+. | Use guide sections and collateral labels that distinguish today, proof-backed examples, demo pressure, future gaps, and next-pack candidates. [VERIFIED: codebase:brandbook/BRAND-SPEC.md] [VERIFIED: codebase:brandbook/collateral/see-it-run/README.md] |
</phase_requirements>

## Project Constraints (from AGENTS.md)

- Read `.planning/PROJECT.md`, `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, and `.planning/STATE.md` before planning or implementation work. [VERIFIED: codebase:AGENTS.md]
- Preserve the core thesis: Crosswake is Phoenix-first route-policy and runtime-contract infrastructure, not a universal UI framework. [VERIFIED: codebase:AGENTS.md] [VERIFIED: codebase:.planning/PROJECT.md]
- Keep runtime ownership explicit per route; do not collapse designs into generic WebView wrapper behavior or LiveView-driven native rendering. [VERIFIED: codebase:AGENTS.md]
- Keep bridge contracts semantic, typed, versioned, and low-frequency. Move continuous client authority toward offline islands or native screens. [VERIFIED: codebase:AGENTS.md] [VERIFIED: codebase:guides/bridge.md]
- Keep offline claims honest by separating cached read-only behavior from true local-first mutation with journals, outboxes, and reconciliation. [VERIFIED: codebase:AGENTS.md] [VERIFIED: codebase:guides/offline.md]
- Treat diagnostics, support matrices, proof lanes, and rough-edge documentation as product surface. [VERIFIED: codebase:AGENTS.md]
- Respect v1/v2 scope boundaries before adding integrations or wider native breadth. [VERIFIED: codebase:AGENTS.md] [VERIFIED: codebase:.planning/PROJECT.md]
- `CLAUDE.md`, `.claude/CLAUDE.md`, `.claude/skills/`, and `.agents/skills/` were requested by the phase prompt but were not present in this workspace. [VERIFIED: codebase:rg --files]

## Summary

Phase 152 should be planned as a consolidation phase, not a feature-expansion phase. The codebase already has the core patterns this phase needs: canonical typed support truth in `Crosswake.SupportMatrix`, deterministic Markdown rendering in `Crosswake.SupportMatrix.Renderer`, label allowlists in `CrosswakeExample.Showcase.Catalog`, fixture reset semantics in `Showcase.Reset`, semantic-first Playwright route tours, and guard tests for collateral/evidence metadata. [VERIFIED: codebase:lib/crosswake/support_matrix/support_matrix.ex] [VERIFIED: codebase:lib/crosswake/support_matrix/renderer.ex] [VERIFIED: codebase:examples/phoenix_host/lib/crosswake_example/showcase/catalog.ex] [VERIFIED: codebase:examples/phoenix_host/e2e/route_tour.spec.ts]

The planner should create a narrow `Crosswake.CapabilityMap` projection next to support truth, render it to `guides/capability_map.md`, generalize route-tour evidence metadata across all v19 showcase lanes, add a forbidden-claim scanner, and write the planning-only `152-V20-HANDOFF.md`. No new native controls, provider integrations, local-first sync productization, dashboards, or plugin catalogs belong in this phase. [VERIFIED: codebase:.planning/phases/152-capability-map-collateral-and-v20-handoff/152-CONTEXT.md]

**Primary recommendation:** Use typed Elixir data plus deterministic render/drift tests as the authoritative capability-map path; use Playwright route-tour assertions and evidence manifests as proof; use screenshots only as honestly labeled collateral. [VERIFIED: codebase:test/crosswake/support_matrix/renderer_test.exs] [VERIFIED: codebase:examples/phoenix_host/e2e/support/evidence_manifest.ts] [CITED: https://playwright.dev/docs/test-assertions]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Capability-map truth | API / Backend | Docs / Static | Crosswake support truth already lives in Elixir modules and is validated by ExUnit, so the capability map should follow that ownership model. [VERIFIED: codebase:lib/crosswake/support_matrix/support_matrix.ex] |
| Rendered `guides/capability_map.md` | Docs / Static | API / Backend | The artifact is public documentation, but its contents should be generated or drift-checked from typed Elixir data. [VERIFIED: codebase:lib/crosswake/support_matrix/renderer.ex] |
| Showcase catalog parity | API / Backend | Browser / Client | `Showcase.Catalog` owns labels, routes, and lane metadata; browser tests consume that shape. [VERIFIED: codebase:examples/phoenix_host/lib/crosswake_example/showcase/catalog.ex] |
| Fixture reset proof | API / Backend | Browser / Client | Server reset owns deterministic Phoenix fixture state; browser helpers own IndexedDB/outbox reset. [VERIFIED: codebase:examples/phoenix_host/lib/crosswake_example/showcase/reset.ex] [VERIFIED: codebase:examples/phoenix_host/e2e/support/offline_route_proof.ts] |
| Route-tour proof | Browser / Client | API / Backend | Playwright drives semantic user flows while the Phoenix host exposes route metadata and reset endpoints. [VERIFIED: codebase:examples/phoenix_host/e2e/route_tour.spec.ts] |
| Evidence manifest | Browser / Client | Docs / Static | Playwright writes route evidence metadata; ExUnit validates schema and committed examples. [VERIFIED: codebase:examples/phoenix_host/e2e/support/evidence_manifest.ts] [VERIFIED: codebase:test/crosswake/guides/evidence_manifest_test.exs] |
| Forbidden-claim guard | Test / CI | Docs / Static | Unsupported claims are text/metadata regressions, best blocked by small structural tests and focused scanners. [VERIFIED: codebase:test/crosswake/guides/collateral_table_test.exs] |
| v20 handoff brief | Planning / Docs | API / Backend | The brief is planning-only, but it must cite typed capability truth and proof evidence rather than reopen product strategy. [VERIFIED: codebase:.planning/STATE.md] |

## Standard Stack

### Core

| Library / Tool | Version | Purpose | Why Standard |
|----------------|---------|---------|--------------|
| Elixir / Mix | 1.19.5, OTP 28 | Typed capability-map module, renderer, and ExUnit tests | Existing Crosswake core and tests are Elixir/Mix based. [VERIFIED: command:elixir --version] [VERIFIED: command:mix --version] |
| Phoenix example host | Existing app in `examples/phoenix_host` | Showcase reset, route metadata, route-tour target | Phase proof requirements depend on current Phoenix host routes and fixtures. [VERIFIED: codebase:examples/phoenix_host] |
| ExUnit | Bundled with Elixir | Renderer parity, enum validation, forbidden-claim tests | Phoenix testing guidance uses ExUnit, and the repository already uses ExUnit for support/proof tests. [CITED: https://hexdocs.pm/phoenix/testing.html] [VERIFIED: codebase:test/crosswake/support_matrix] |
| Playwright Test | 1.60.0 installed in Phoenix host | Semantic route-tour proof and evidence manifest generation | Existing route tours and evidence helpers are Playwright-based. [VERIFIED: command:npm ls @playwright/test --depth=0 --json] [VERIFIED: codebase:examples/phoenix_host/e2e/route_tour.spec.ts] |

### Supporting

| Library / Tool | Version | Purpose | When to Use |
|----------------|---------|---------|-------------|
| Node.js | 22.14.0 | Runs Playwright route tours and TypeScript helper code | Needed for `examples/phoenix_host/e2e` verification. [VERIFIED: command:node --version] |
| npm | 11.1.0 | Resolves Phoenix host e2e dependencies | Needed when the Playwright workspace is not installed. [VERIFIED: command:npm --version] |
| Git | 2.41.0 | Commit and route-tour commit SHA metadata | Evidence manifest records commit SHA and GSD commits docs. [VERIFIED: command:git --version] [VERIFIED: codebase:examples/phoenix_host/e2e/support/evidence_manifest.ts] |
| `script/collateral-guard.sh` | Existing script | Collateral existence/label guard | Reuse for screenshot/collateral bundle checks; do not replace with a dashboard. [VERIFIED: codebase:script/collateral-guard.sh] |
| `script/check-collateral-size.sh` | Existing script | Collateral size budget | Reuse if new collateral bundle references are added. [VERIFIED: codebase:script/check-collateral-size.sh] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Typed Elixir capability map | Hand-written Markdown table | Faster initially, but violates the existing support-truth drift-test pattern and is easy to overclaim. [VERIFIED: codebase:test/crosswake/support_matrix/renderer_test.exs] |
| ExUnit forbidden-claim tests | Shell-only scanner | Shell scripts are useful for assets, but ExUnit can validate structured data, synthetic regressions, and rendered docs together. [VERIFIED: codebase:test/crosswake/guides/evidence_manifest_test.exs] |
| Route-tour evidence manifest | Screenshot-only proof bundle | Screenshots are visual collateral; route-tour assertions and metadata carry proof posture. [VERIFIED: codebase:examples/phoenix_host/e2e/route_tour.spec.ts] [CITED: https://playwright.dev/docs/screenshots] |

**Installation:**

No new external packages are recommended for this phase. Reuse the installed Elixir/Phoenix/ExUnit and Playwright stack. [VERIFIED: command:npm ls @playwright/test --depth=0 --json]

**Version verification:** Versions were verified locally on 2026-07-12 with `elixir --version`, `mix --version`, `node --version`, `npm --version`, `git --version`, and `npm ls @playwright/test --depth=0 --json`. [VERIFIED: command]

## Package Legitimacy Audit

No new external packages should be installed for Phase 152. The package legitimacy gate is not required because the standard stack reuses existing project dependencies and installed tools. [VERIFIED: codebase:.planning/phases/152-capability-map-collateral-and-v20-handoff/152-CONTEXT.md]

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| None | n/a | n/a | n/a | n/a | n/a | No install planned |

**Packages removed due to [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

## Architecture Patterns

### System Architecture Diagram

```text
SupportMatrix + Manifest capability catalog
        |
        v
Crosswake.CapabilityMap typed rows
        |                 \
        |                  \ parity checks
        v                   v
CapabilityMap.Renderer -> guides/capability_map.md
        |
        v
README / example README entry points

Showcase.Catalog + route metadata + fixture reset
        |
        v
Playwright semantic route tours
        |
        +--> evidence_manifest.ts -> evidence-manifest.json -> ExUnit schema/label checks
        |
        +--> screenshots/collateral after assertions -> collateral guards

Capability map + evidence manifest + v19 phase evidence
        |
        v
152-V20-HANDOFF.md
        |
        v
v20 Native Controls Pack 1 plan boundary
```

### Recommended Project Structure

```text
lib/crosswake/
├── capability_map.ex                 # typed v19 capability-map projection
└── capability_map/
    └── renderer.ex                   # deterministic Markdown renderer

guides/
└── capability_map.md                 # rendered adopter-readable map

test/crosswake/
├── capability_map/
│   ├── capability_map_test.exs       # enums, parity, rows, v20 implications
│   └── renderer_test.exs             # byte-identical guide rendering
└── guides/
    ├── capability_claims_test.exs    # forbidden-claim scanner
    └── evidence_manifest_test.exs    # expanded route/label schema

examples/phoenix_host/e2e/support/
└── evidence_manifest.ts              # generalized v19 evidence manifest

.planning/phases/152-capability-map-collateral-and-v20-handoff/
└── 152-V20-HANDOFF.md                # planning-only v20 Pack 1 brief
```

### Pattern 1: Typed Capability Projection

**What:** Define small, validated row data with explicit enums for category, display label, route runtime owner, package owner, proof posture, fallback, and v20 implication. [VERIFIED: codebase:.planning/phases/152-capability-map-collateral-and-v20-handoff/152-CONTEXT.md]

**When to use:** Use for all CAPMAP rows and rendered guide content. Avoid scattering identical truth into README, docs, TypeScript, and planning files. [VERIFIED: codebase:lib/crosswake/support_matrix/support_matrix.ex]

**Example:**

```elixir
# Source: adapted from existing typed support truth patterns in
# lib/crosswake/support_matrix/support_matrix.ex and lib/crosswake/manifest/types.ex
defmodule Crosswake.CapabilityMap do
  @categories [:shipped, :demoed, :missing, :deferred, :next_pack_candidate]
  @proof_postures [:merge_blocking, :advisory, :not_yet_proven, :unsupported]
  @package_owners [:core, :native_shell, :first_party_companion, :example_docs_only, :deferred]

  def categories, do: @categories
  def proof_postures, do: @proof_postures
  def package_owners, do: @package_owners

  def canonical do
    [
      %{
        capability: "haptics",
        route_source: "/saas/approvals/:id",
        category: :demoed,
        display_label: "Proof-backed example",
        route_runtime_owner: :live_view,
        package_owner: :core,
        proof_posture: :merge_blocking,
        fallback: "Phoenix approval flow remains authoritative if haptics is unavailable.",
        v20_implication: "Candidate for bounded route-local native controls."
      }
    ]
  end
end
```

### Pattern 2: Deterministic Renderer With Byte Parity

**What:** Render Markdown from typed data and assert the checked-in guide equals renderer output byte-for-byte. [VERIFIED: codebase:lib/crosswake/support_matrix/renderer.ex] [VERIFIED: codebase:test/crosswake/support_matrix/renderer_test.exs]

**When to use:** Use for `guides/capability_map.md`; optionally expose a Mix task only if it reduces drift. [VERIFIED: codebase:.planning/phases/152-capability-map-collateral-and-v20-handoff/152-CONTEXT.md]

**Example:**

```elixir
# Source: adapted from lib/crosswake/support_matrix/renderer.ex
def render(rows \\ Crosswake.CapabilityMap.canonical()) do
  [
    "# Crosswake Capability Map",
    "",
    "| Capability | Label | Owner | Proof | v20 implication |",
    "|------------|-------|-------|-------|-----------------|",
    Enum.map(rows, &render_row/1)
  ]
  |> List.flatten()
  |> Enum.join("\n")
  |> Kernel.<>("\n")
end
```

### Pattern 3: Semantic Route-Tour Proof Before Screenshots

**What:** Keep Playwright assertions as proof and capture screenshots/collateral only after assertions pass. [VERIFIED: codebase:examples/phoenix_host/e2e/route_tour.spec.ts] [CITED: https://playwright.dev/docs/test-assertions]

**When to use:** Use for PROOF-02 and any collateral update. The evidence manifest should identify limitations and labels; it should not call screenshots proof. [VERIFIED: codebase:examples/phoenix_host/e2e/support/evidence_manifest.ts]

**Example:**

```typescript
// Source: adapted from examples/phoenix_host/e2e/route_tour.spec.ts
await expect(page.getByTestId('route-runtime-owner')).toContainText('LiveView');
await expect(page.getByText('Screenshots are collateral after this assertion passes')).toBeVisible();
await page.screenshot({ path: 'artifacts/showcase-hub.png', fullPage: true });
```

### Pattern 4: Reset Boundary Is Part Of Proof

**What:** Server reset proves deterministic server fixtures; browser-owned IndexedDB/local outbox state must be reset by browser helpers. [VERIFIED: codebase:examples/phoenix_host/lib/crosswake_example/showcase/reset.ex] [VERIFIED: codebase:examples/phoenix_host/e2e/support/offline_route_proof.ts]

**When to use:** Use for PROOF-01 and for any documentation about reset determinism. Do not claim server reset clears browser state. [VERIFIED: codebase:examples/phoenix_host/test/crosswake_example/showcase/reset_test.exs]

### Anti-Patterns to Avoid

- **Markdown-only truth:** It bypasses support-matrix-style validation and creates drift risk. Use typed data plus renderer parity. [VERIFIED: codebase:test/crosswake/support_matrix/renderer_test.exs]
- **Reusing `supported` as a broad display claim:** The support matrix has contract-status vocabulary; the capability map needs v19 adopter-facing labels like `Available today`, `Demo pressure`, and `Future gap`. [VERIFIED: codebase:lib/crosswake/support_matrix/support_matrix.ex] [VERIFIED: codebase:examples/phoenix_host/lib/crosswake_example/showcase/catalog.ex]
- **Screenshots-as-proof:** Playwright assertions and evidence metadata prove behavior; screenshots are collateral. [VERIFIED: codebase:.planning/phases/152-capability-map-collateral-and-v20-handoff/152-CONTEXT.md] [CITED: https://playwright.dev/docs/screenshots]
- **Provider/device evidence laundering:** Device, emulator, JVM, StoreKit, Play Billing, or RevenueCat evidence must not become subscriber truth or broad native support. [VERIFIED: codebase:guides/commerce.md] [VERIFIED: codebase:test/crosswake/support_matrix/support_matrix_test.exs]
- **Generic native plugin catalog:** Phase 152 should define v20 Pack 1 scope and later-pack names, not a broad plugin registry. [VERIFIED: codebase:.planning/phases/152-capability-map-collateral-and-v20-handoff/152-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Capability truth | Freeform tables duplicated across docs | `Crosswake.CapabilityMap` typed rows plus renderer | Existing support truth is typed and testable; duplicated prose drifts. [VERIFIED: codebase:lib/crosswake/support_matrix/support_matrix.ex] |
| Capability guide generation | One-off script that writes Markdown ad hoc | Renderer modeled after `Crosswake.SupportMatrix.Renderer` | Existing renderer handles deterministic output and escaping. [VERIFIED: codebase:lib/crosswake/support_matrix/renderer.ex] |
| Route proof | Screenshot bundle as correctness evidence | Playwright assertions plus evidence manifest | Playwright assertions are behavioral proof; screenshots are collateral. [VERIFIED: codebase:examples/phoenix_host/e2e/route_tour.spec.ts] |
| Offline proof | Generic `works offline` claim | Route-local offline island or cached read-only classification | Android offline-first guidance requires local data source, queued writes, sync, and conflict handling for mutation claims. [CITED: https://developer.android.com/topic/architecture/data-layer/offline-first] |
| Commerce authority | Storefront/device evidence as entitlement truth | Backend projection language and future provider pack | Existing commerce guide makes backend projection authoritative. [VERIFIED: codebase:guides/commerce.md] |
| Claim guard | Broad text grep with no fixtures | Focused ExUnit scanner with synthetic negative cases | Existing evidence/collateral tests already use structural checks and synthetic regressions. [VERIFIED: codebase:test/crosswake/guides/evidence_manifest_test.exs] |
| Native controls | Alert/share/haptics implementations | v20 handoff brief only | Phase 152 is closeout/handoff; implementation starts in v20. [VERIFIED: codebase:.planning/ROADMAP.md] |

**Key insight:** Phase 152 is about making support, evidence, and future scope hard to misread. Custom feature work increases the risk of overclaiming; typed projections and guard tests lower it. [VERIFIED: codebase:.planning/phases/152-capability-map-collateral-and-v20-handoff/152-CONTEXT.md]

## Common Pitfalls

### Pitfall 1: Support-Matrix Vocabulary Bleeds Into Capability-Map Copy

**What goes wrong:** Rows with contract-level `supported` status render as broad user-facing native support. [VERIFIED: codebase:lib/crosswake/support_matrix/support_matrix.ex]

**Why it happens:** The support matrix and capability map answer different questions: contract support versus v19 proof/collateral/v20 implication. [VERIFIED: codebase:.planning/phases/152-capability-map-collateral-and-v20-handoff/152-CONTEXT.md]

**How to avoid:** Keep capability-map categories and display labels separate from support-matrix statuses; add parity tests that reject broad `supported` rendering for `example/docs-only`, advisory, deferred, or future rows. [VERIFIED: codebase:examples/phoenix_host/lib/crosswake_example/showcase/catalog.ex]

**Warning signs:** `native support`, `supported natively`, `works offline`, `StoreKit support`, or `generic plugin` appears in public docs without explicit posture. [VERIFIED: codebase:.planning/phases/152-capability-map-collateral-and-v20-handoff/152-CONTEXT.md]

### Pitfall 2: Evidence Manifest Label Drift

**What goes wrong:** `evidence_manifest.ts` emits new labels such as demo-pressure/future-gap while `EvidenceManifestTest` still only allows older proof labels. [VERIFIED: codebase:examples/phoenix_host/e2e/support/evidence_manifest.ts] [VERIFIED: codebase:test/crosswake/guides/evidence_manifest_test.exs]

**Why it happens:** Fieldserv-heavy manifest expansion changes posture vocabulary without updating schema tests and committed sample manifests. [VERIFIED: codebase:.planning/phases/152-capability-map-collateral-and-v20-handoff/152-CONTEXT.md]

**How to avoid:** Plan one wave that updates TypeScript types, generated/committed manifest sample, ExUnit schema tests, CI route-tour step summaries, and allowed labels together. [VERIFIED: codebase:.github/workflows/offline-sync-e2e-gate.yml]

**Warning signs:** CI passes route-tour but fails `test/crosswake/guides/evidence_manifest_test.exs`, or unsupported labels appear only in generated artifacts. [VERIFIED: codebase:test/crosswake/guides/evidence_manifest_test.exs]

### Pitfall 3: Server Reset Overclaims Browser-State Cleanup

**What goes wrong:** Docs or evidence imply `/_e2e/showcase-reset` clears IndexedDB, local outboxes, or browser state. [VERIFIED: codebase:examples/phoenix_host/lib/crosswake_example/showcase/reset.ex]

**Why it happens:** Server fixture determinism and browser local-state determinism are both needed for route-tour proof but live in different tiers. [VERIFIED: codebase:examples/phoenix_host/e2e/support/offline_route_proof.ts]

**How to avoid:** Keep `browser_state_reset: false` in server reset output and explicitly call browser reset helpers in route tours. [VERIFIED: codebase:examples/phoenix_host/test/crosswake_example/showcase/reset_test.exs]

**Warning signs:** Copy says `reset clears offline state` or `server reset reset browser outbox`. [VERIFIED: codebase:examples/phoenix_host/e2e/support/offline_route_proof.ts]

### Pitfall 4: v20 Handoff Reopens The Whole Native Roadmap

**What goes wrong:** The handoff becomes a broad native/plugin strategy doc instead of a decision-ready Pack 1 brief. [VERIFIED: codebase:.planning/phases/152-capability-map-collateral-and-v20-handoff/152-CONTEXT.md]

**Why it happens:** Fieldserv and LearnLoop create real pressure for capture, scanner, sync, and commerce, but those are named later packs. [VERIFIED: codebase:.planning/STATE.md]

**How to avoid:** Scope Pack 1 to bounded low-frequency route-local controls and list later packs with promotion criteria. [VERIFIED: codebase:.planning/phases/152-capability-map-collateral-and-v20-handoff/152-CONTEXT.md]

**Warning signs:** Phase 152 tasks add native control implementation files, provider SDKs, APNs/FCM logic, generic plugin registry data, or new operator dashboard routes. [VERIFIED: codebase:.planning/ROADMAP.md]

### Pitfall 5: Commerce And Offline Copy Gets Stronger Than Proof

**What goes wrong:** Docs or collateral imply live provider support, purchase success, subscriber truth, true local-first Fieldserv mutation, or native storage productization. [VERIFIED: codebase:guides/commerce.md] [VERIFIED: codebase:guides/offline.md]

**Why it happens:** Demo lanes intentionally show product pressure, but pressure is not shipped support. [VERIFIED: codebase:.planning/STATE.md]

**How to avoid:** Use `Backend projection required`, `Demo pressure`, `Future gap`, and `Next-pack candidate`; merge-block forbidden copy. [VERIFIED: codebase:brandbook/BRAND-SPEC.md]

**Warning signs:** Copy says `everything works offline`, `live StoreKit`, `Play Billing support shipped`, `RevenueCat support`, `purchase verified on device`, or `subscriber unlocked`. [VERIFIED: codebase:.planning/phases/152-capability-map-collateral-and-v20-handoff/152-CONTEXT.md]

## Code Examples

Verified patterns from official and local sources:

### Renderer Parity Test

```elixir
# Source: test/crosswake/support_matrix/renderer_test.exs
test "checked-in capability guide matches renderer output" do
  rendered = Crosswake.CapabilityMap.Renderer.render()
  checked_in = File.read!("guides/capability_map.md")

  assert checked_in == rendered
end
```

### Capability Label Allowlist

```elixir
# Source: examples/phoenix_host/test/crosswake_example/showcase/catalog_test.exs pattern
test "capability map labels stay in the v19 support vocabulary" do
  labels = Crosswake.CapabilityMap.canonical() |> Enum.map(& &1.display_label) |> Enum.uniq()

  assert labels -- [
           "Available today",
           "Proof-backed example",
           "Demo pressure",
           "Advisory evidence",
           "Future gap",
           "Next-pack candidate"
         ] == []
end
```

### Evidence Manifest Row With Honest Limits

```typescript
// Source: examples/phoenix_host/e2e/support/evidence_manifest.ts pattern
{
  route_id: 'fieldserv-capture-handoff',
  runtime_owner: 'native_screen',
  proof_class: 'advisory',
  support_label: 'Demo pressure',
  capability_posture: 'next-pack-candidate',
  package_owner: 'example/docs-only',
  retention_label: 'route-tour evidence',
  known_limitations: [
    'Browser route-tour evidence does not prove camera capture.',
    'Native screen is owned by the host app until a future pack promotes it.'
  ],
  status: 'unavailable',
  unavailable_reason: 'Native camera flow is intentionally deferred.'
}
```

### Forbidden-Claim Scanner Shape

```elixir
# Source: test/crosswake/guides/evidence_manifest_test.exs and
# examples/phoenix_host/e2e/support/offline_route_proof.ts patterns
@forbidden_claims [
  ~r/native support/i,
  ~r/generic plugin support/i,
  ~r/everything works offline/i,
  ~r/StoreKit support shipped/i,
  ~r/Play Billing support shipped/i,
  ~r/RevenueCat support/i,
  ~r/purchase succeeded/i,
  ~r/subscriber truth/i
]

test "public docs do not overclaim unsupported native, offline, or commerce behavior" do
  text =
    ["README.md", "examples/phoenix_host/README.md", "guides/capability_map.md"]
    |> Enum.map(&File.read!/1)
    |> Enum.join("\n")

  assert Enum.reject(@forbidden_claims, &Regex.match?(&1, text)) == @forbidden_claims
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Prose-only support claims | Typed support matrix, renderer parity, and validation tests | Existing before Phase 152 | Capability map should use the same guardrail level. [VERIFIED: codebase:lib/crosswake/support_matrix/support_matrix.ex] |
| Single demo route proof | Product-shaped v19 showcase lanes: AdminPilot, Fieldserv, LearnLoop | Phases 149-151 | Phase 152 should generalize evidence manifest and docs across lanes. [VERIFIED: codebase:.planning/phases/149-saas-admin-showcase/149-VERIFICATION.md] [VERIFIED: codebase:.planning/phases/151-subscription-learning-showcase/151-VERIFICATION.md] |
| Screenshot proof | Semantic route-tour assertions first, screenshots after | Existing route-tour pattern | Collateral can show surface, not correctness or native provider truth. [VERIFIED: codebase:examples/phoenix_host/e2e/route_tour.spec.ts] |
| Broad offline wording | Cached read-only, offline island, and local-first mutation are distinct | Existing offline guide and LearnLoop proof | Phase 152 copy must not promote cached Fieldserv read-only behavior into local-first mutation. [VERIFIED: codebase:guides/offline.md] |
| Device/storefront evidence as authority | Backend projection is entitlement authority | Existing commerce guide | v20 handoff should defer commerce provider productionization. [VERIFIED: codebase:guides/commerce.md] |

**Deprecated/outdated:**
- Screenshot metadata labeled as proof: replace with semantic proof labels and collateral labels. [VERIFIED: codebase:.planning/phases/152-capability-map-collateral-and-v20-handoff/152-CONTEXT.md]
- Broad native/plugin support wording: replace with package owner, route owner, proof posture, denial/fallback behavior, and v20 implication. [VERIFIED: codebase:brandbook/BRAND-SPEC.md]
- `works offline` copy without data-layer proof: replace with cached read-only or offline-island/local-first details. [CITED: https://developer.android.com/topic/architecture/data-layer/offline-first]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | No assumptions were required for the recommended plan shape; phase scope, constraints, and implementation patterns were verified from local planning artifacts, code, tests, or official docs. | All | n/a |

## Open Questions (RESOLVED)

1. **Should `Crosswake.CapabilityMap` be public API or internal support data?**
   - What we know: Context recommends `Crosswake.CapabilityMap` or equivalent next to support truth. [VERIFIED: codebase:.planning/phases/152-capability-map-collateral-and-v20-handoff/152-CONTEXT.md]
   - What's unclear: Whether it should be documented as public API or treated as internal docs/proof infrastructure.
   - RESOLVED: Implement an explicit `Crosswake.CapabilityMap` module API for renderer/tests/internal support truth, but document `guides/capability_map.md` as the adopter surface. Do not promise the row schema as stable runtime public API in Phase 152.

2. **Should `capability-map evidence` be a proof class or a separate manifest posture?**
   - What we know: Current TypeScript manifest includes capability pressure entries, while existing ExUnit manifest tests have a narrower proof-label allowlist. [VERIFIED: codebase:examples/phoenix_host/e2e/support/evidence_manifest.ts] [VERIFIED: codebase:test/crosswake/guides/evidence_manifest_test.exs]
   - What's unclear: The exact field split after generalization.
   - RESOLVED: Keep `proof_class` constrained to proof posture (`merge-blocking`, `advisory`, `not-yet-proven`, `unsupported`) and represent capability/support classification separately with `capability_posture` plus `support_label` for demo pressure, future gap, and next-pack candidate rows.

3. **Where should Fieldserv final verification be cited from?**
   - What we know: Phase 150 has context and plan summary files with passing verification commands, but no `150-VERIFICATION.md` file was found during research. [VERIFIED: codebase:.planning/phases/150-field-service-showcase/150-CONTEXT.md] [VERIFIED: codebase:.planning/phases/150-field-service-showcase/150-07-SUMMARY.md]
   - What's unclear: Whether a missing final verifier artifact is intentional.
   - RESOLVED: Cite Fieldserv evidence from code/tests and `.planning/phases/150-field-service-showcase/150-07-SUMMARY.md`; do not block Phase 152 planning on reconstructing a missing `150-VERIFICATION.md` artifact.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir | Core capability-map module and ExUnit tests | yes | 1.19.5, OTP 28 | none needed |
| Mix | Test runner and project tasks | yes | 1.19.5 | none needed |
| Node.js | Playwright route tours | yes | 22.14.0 | none needed |
| npm | Phoenix host e2e dependency install | yes | 11.1.0 | Use existing `node_modules` when present |
| `@playwright/test` | Browser route-tour proof | yes | 1.60.0 | Run `npm install` in `examples/phoenix_host` if missing |
| Git | Evidence commit SHA and optional GSD commit | yes | 2.41.0 | none needed |

**Missing dependencies with no fallback:** none found.

**Missing dependencies with fallback:** none found.

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit via Mix 1.19.5; Playwright Test 1.60.0 |
| Config file | Root Mix project and `examples/phoenix_host/playwright.config.ts` |
| Quick run command | `mix test test/crosswake/support_matrix test/crosswake/guides/evidence_manifest_test.exs` |
| Full suite command | `mix test && (cd examples/phoenix_host && mix test --warnings-as-errors && npx playwright test e2e/route_tour.spec.ts e2e/learnloop_route_tour.spec.ts)` |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| CAPMAP-01 | Capability rows classify shipped/demoed/missing/deferred/next-pack candidate | unit | `mix test test/crosswake/capability_map/capability_map_test.exs` | no, Wave 0 |
| CAPMAP-02 | Package owner is explicit per row | unit | `mix test test/crosswake/capability_map/capability_map_test.exs` | no, Wave 0 |
| CAPMAP-03 | Proof posture uses merge-blocking/advisory/not-yet-proven/unsupported and excludes screenshots | unit | `mix test test/crosswake/capability_map/capability_map_test.exs` | no, Wave 0 |
| CAPMAP-04 | Capability map renders v20 implications and handoff inputs | unit/docs | `mix test test/crosswake/capability_map/renderer_test.exs` | no, Wave 0 |
| PROOF-01 | Showcase reset is deterministic and browser reset boundary remains explicit | unit/integration | `cd examples/phoenix_host && mix test --warnings-as-errors test/crosswake_example/showcase/reset_test.exs` | yes |
| PROOF-02 | Route tour covers hub and one happy path per lane | e2e | `cd examples/phoenix_host && npx playwright test e2e/route_tour.spec.ts e2e/learnloop_route_tour.spec.ts` | yes, needs expansion |
| PROOF-03 | Docs/support tests block unsupported native controls as shipped | unit/docs | `mix test test/crosswake/guides/capability_claims_test.exs` | no, Wave 0 |
| PROOF-04 | Collateral/docs distinguish today, demo pressure, and planned v20+ | unit/docs | `mix test test/crosswake/guides/collateral_table_test.exs test/crosswake/capability_map/renderer_test.exs` | partial, Wave 0 gap |

### Sampling Rate

- **Per task commit:** `mix test test/crosswake/capability_map test/crosswake/guides/evidence_manifest_test.exs`
- **Per wave merge:** `mix test && (cd examples/phoenix_host && mix test --warnings-as-errors)`
- **Phase gate:** Root full suite, Phoenix host full suite, route-tour specs, and collateral guards green before `$gsd-verify-work`.

### Wave 0 Gaps

- [ ] `test/crosswake/capability_map/capability_map_test.exs` - covers CAPMAP-01, CAPMAP-02, CAPMAP-03, CAPMAP-04.
- [ ] `test/crosswake/capability_map/renderer_test.exs` - covers rendered `guides/capability_map.md` parity.
- [ ] `test/crosswake/guides/capability_claims_test.exs` - covers PROOF-03 forbidden claims.
- [ ] `test/crosswake/guides/evidence_manifest_test.exs` - expand expected route IDs and allowed posture labels for generalized v19 manifest.
- [ ] `.github/workflows/offline-sync-e2e-gate.yml` - update route-tour evidence checks/summary after manifest generalization.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | no direct auth change | Do not add login/auth flows in Phase 152; preserve backend/session authority language in docs. [VERIFIED: codebase:.planning/phases/152-capability-map-collateral-and-v20-handoff/152-CONTEXT.md] |
| V3 Session Management | yes, indirectly | Do not present route-tour/session evidence as production session hardening. Preserve existing Phoenix host test-only reset/e2e boundaries. [VERIFIED: codebase:examples/phoenix_host/test/crosswake_example/e2e/showcase_reset_controller_test.exs] |
| V4 Access Control | yes | Keep route ownership, capability allowlists, active-route checks, and backend projection authority visible. [VERIFIED: codebase:guides/route_policy.md] [VERIFIED: codebase:guides/bridge.md] |
| V5 Input Validation | yes | Validate capability-map enums, evidence manifest schema, labels, proof posture, and docs claims through ExUnit. [VERIFIED: codebase:test/crosswake/guides/evidence_manifest_test.exs] |
| V6 Cryptography | no new crypto | Do not introduce crypto. Existing reset digest is determinism evidence, not security proof. [VERIFIED: codebase:examples/phoenix_host/lib/crosswake_example/showcase/reset.ex] |

### Known Threat Patterns for Crosswake Support/Proof Surface

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Unsupported native capability rendered as shipped | Spoofing / Tampering | Typed enums, package-owner fields, support/capability parity tests, forbidden-claim scanner. [VERIFIED: codebase:.planning/phases/152-capability-map-collateral-and-v20-handoff/152-CONTEXT.md] |
| Screenshot or emulator evidence treated as correctness proof | Repudiation / Information integrity | Route-tour assertions before screenshots; manifest limitations and retention labels. [VERIFIED: codebase:examples/phoenix_host/e2e/route_tour.spec.ts] |
| Offline/local-first overclaim | Tampering / Availability | Require journal/outbox/reconciliation proof for mutation claims; label cached read-only separately. [VERIFIED: codebase:guides/offline.md] [CITED: https://developer.android.com/topic/architecture/data-layer/offline-first] |
| Commerce/provider evidence treated as entitlement authority | Elevation of Privilege | Keep backend projection as authority and defer provider integrations. [VERIFIED: codebase:guides/commerce.md] |
| Bridge grows into generic plugin surface | Elevation of Privilege / Tampering | Keep bridge semantic, typed, versioned, low-frequency, route-local, and allowlisted. [VERIFIED: codebase:guides/bridge.md] |

## Sources

### Primary (HIGH confidence)

- `.planning/phases/152-capability-map-collateral-and-v20-handoff/152-CONTEXT.md` - locked phase decisions, scope, deferred ideas, and guardrails.
- `.planning/PROJECT.md` - project thesis, constraints, v19/v20 direction.
- `.planning/REQUIREMENTS.md` - CAPMAP and PROOF requirements.
- `.planning/ROADMAP.md` - Phase 152 goal and success criteria.
- `.planning/STATE.md` - current project position and deferred roadmap.
- `AGENTS.md` - project-specific instructions and constraints.
- `lib/crosswake/support_matrix/support_matrix.ex` - canonical support truth model.
- `lib/crosswake/support_matrix/renderer.ex` - deterministic guide renderer pattern.
- `lib/crosswake/manifest/types.ex` and `lib/crosswake/manifest/builder.ex` - capability registry fields and package/proof metadata.
- `examples/phoenix_host/lib/crosswake_example/showcase/catalog.ex` - existing showcase support labels and route/lane metadata.
- `examples/phoenix_host/lib/crosswake_example/showcase/reset.ex` - deterministic reset and browser-state boundary.
- `examples/phoenix_host/e2e/route_tour.spec.ts`, `learnloop_route_tour.spec.ts`, `support/offline_route_proof.ts`, and `support/evidence_manifest.ts` - route proof and manifest patterns.
- `test/crosswake/support_matrix/*`, `test/crosswake/guides/evidence_manifest_test.exs`, `test/crosswake/guides/collateral_table_test.exs` - guard and parity test patterns.
- `guides/bridge.md`, `guides/offline.md`, `guides/commerce.md`, `guides/capabilities.md`, and `brandbook/BRAND-SPEC.md` - public vocabulary and non-claim boundaries.
- `.planning/phases/149-saas-admin-showcase/149-VERIFICATION.md`, `.planning/phases/150-field-service-showcase/150-07-SUMMARY.md`, `.planning/phases/151-subscription-learning-showcase/151-VERIFICATION.md` - lane evidence and verification context.

### Secondary (MEDIUM confidence)

- `https://hexdocs.pm/phoenix/testing.html` - Phoenix uses ExUnit and `mix test` for testing.
- `https://playwright.dev/docs/test-assertions` - Playwright assertion model.
- `https://playwright.dev/docs/screenshots` and `https://playwright.dev/docs/test-snapshots` - screenshot capture and visual comparison are separate APIs.
- `https://developer.android.com/topic/architecture/data-layer/offline-first` - offline-first data-layer, local source, queued write, sync, and conflict guidance.

### Tertiary (LOW confidence)

- None. No recommendations depend on training-only claims.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - verified from local tool versions and existing project dependencies.
- Architecture: HIGH - derived from local code, tests, and locked phase decisions.
- Pitfalls: HIGH - backed by existing guard tests, docs, and explicit context decisions.
- External ecosystem lessons: MEDIUM - checked against official docs via websearch and cached through GSD research-store.

**Research date:** 2026-07-12
**Valid until:** 2026-08-11 for codebase-local planning; re-verify dependency versions and official external docs before implementing later native-provider packs.
