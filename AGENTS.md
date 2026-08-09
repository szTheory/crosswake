# Crosswake Agent Guide

## Project Context

Read these before planning or implementation work:

1. `.planning/ADR-FIRST-B2C-ADOPTER.md` — governing infrastructure decision, reversal conditions,
   privacy boundaries, stop list, and non-goals
2. `.planning/FIRST-B2C-ADOPTER-ADOPTION-BRIEF.md` — RAG-friendly full game plan, surface audit,
   stakeholder lenses, ownership boundaries, proof/media analysis, and dated sequence
3. `.planning/FIRST-B2C-ADOPTER-ROUTE-POLICY-MAP.md` — first-adopter route owners and
   physical-iPhone exit test
4. `.planning/PROJECT.md` — project thesis, constraints, history, and decisions
5. `.planning/REQUIREMENTS.md` — current milestone scope and traceability
6. `.planning/ROADMAP.md` — active phase ordering, time boxes, and stop date
7. `.planning/STATE.md` — current position, blockers, and deferred items

## Current Priority

Crosswake is infrastructure for the **First B2C Adopter**, not a separate business line. Optimize
for one real Phoenix application on one physical iPhone with one offline mutation island.

Priority order:

1. explicit first-adopter route ownership;
2. host-reusable proof that preserves existing browser tests and fixtures;
3. privacy-safe scoped replay and backend auth authority;
4. real offline pronunciation media through one host-supplied foreground iOS adapter;
5. a bounded first-adopter iOS navigation shell with native tabs/back, live safe-area insets, and
   declarative shell presence;
6. physical-iPhone offline/replay evidence;
7. only defects demonstrated by that evidence.

If customer Alpha is web-only, Crosswake has no Alpha deliverable. Complete the bounded route
inventory, then pause Crosswake until the public-v1 mobile path is active.

## Working Rules

- Preserve the core thesis: Crosswake is a Phoenix-first route-policy and runtime-contract system,
  not a universal UI framework.
- Keep runtime ownership explicit per route. Do not collapse designs into generic WebView wrapper
  behavior or LiveView-driven native rendering.
- Treat bridge contracts as semantic, typed, versioned, and low-frequency. Continuous client
  authority belongs in an offline island or native screen.
- Keep offline claims honest. Cached read-only is not local mutation. One study island is not
  generic sync.
- Preserve fail-closed explicit denials. Flag any path that can degrade silently.
- Treat diagnostics and proof as product surface, but prefer one-command host proof over new label
  taxonomy.
- Android is frozen at its current generator, Maven, JVM, and vector posture. Do not add Android
  features, templates, device proof, parity work, or release requirements during v21.
- Native navigation is a shell-level route-policy/runtime-contract concern, not a bounded bridge
  capability. During v21, implement only the first-adopter iOS slice; Android predictive-back and
  renderer work remain frozen even when shared vocabulary anticipates them.
- Do not build native menu/action-button breadth, new companions, capture/device packs, commerce
  productionization, a dashboard, brand/showcase polish, generic sync, background sync, or generic
  native storage unless the governing ADR's reversal condition is met.

## Sensitive Data Rules

- Durable codename: **First B2C Adopter** (`first_b2c_adopter`).
- Public guides: say **first adopter**.
- Never record or infer the real adopter name, founder identity, price, geography, customer
  information, proprietary taxonomy, or revealing links.
- Never search git history or external sources to reidentify the adopter.
- Treat offline mutation payloads as sensitive. Raw answers, media, transcripts, credentials,
  account identifiers, tokens, and stable device identifiers must not enter telemetry, doctor
  output, inspection, logs, aggregates, or proof artifacts.
- Require opaque scope references, scope-partitioned outboxes, replay authorization, and fail-closed
  account-switch/logout behavior.

## Workflow

- Read the current phase from `.planning/STATE.md`; do not use a hard-coded phase number.
- Start it with `$gsd-discuss-phase <current-phase>`.
- Use `$gsd-plan-phase <current-phase>` only when discussion is intentionally skipped.
- Default to zero-human verification and UAT. If a claim can be checked by unit, integration, E2E,
  device automation, or artifact inspection, the agent runs that check and treats its result as the
  gate; do not emit `checkpoint:human-verify` or create a UAT handoff for it.
- Reserve human action for unavoidable credentials, external approvals, or irreversible trust
  actions. A physical-device connection may require human setup, but the assertions and evidence
  evaluation remain automated.
- Promote checks into CI only when they protect a recurring contract and provide stable,
  actionable feedback. Keep one-time reconciliation commands in phase evidence rather than
  creating permanent workflow lanes.
- Update requirements, roadmap, state, ADRs, capability/support truth, and guide renderings together
  when a decision changes.
- Keep settled code-local truth in git. Keep fast-changing adopter execution in the codename-only
  Linear issue drafts.
