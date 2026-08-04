---
phase: 162
slug: physical-iphone-adoption-proof
status: draft
shadcn_initialized: false
preset: none
created: 2026-08-04
---

# Phase 162 — UI Design Contract

> Visual and interaction contract for the bounded physical-iPhone study proof. This phase extends the host-owned study/recovery surface; it does not create a diagnostic console, a generic sync UI, or Android UI.

---

## Design System

| Property | Value |
|----------|-------|
| Tool | none — existing Crosswake token system and native SwiftUI system components |
| Preset | not applicable; this is not a React/Next.js/Vite project |
| Component library | SwiftUI system controls; host-owned Phoenix/offline-island markup |
| Icon library | SF Symbols (`checkmark.circle`, `arrow.triangle.2.circlepath`, `exclamationmark.triangle`) with a visible text label |
| Font | Native: Dynamic Type system text styles. Web/offline island: `--cw-font-body` (Atkinson Hyperlegible Next); section label: `--cw-font-display` (Space Grotesk) |

Use existing `--cw-*` semantic tokens and the existing `RequiredPackView` accessibility pattern. Do not add a third-party registry, a new component library, or an independent palette. [Source: `162-CONTEXT.md`, `priv/static/crosswake/tokens.css`, `RequiredPackView.swift`]

---

## Surface and Interaction Contract

Render one contextual status row/banner in the active study flow, directly below the study heading and above answer controls. It is a combined semantic element: icon, short state label, and learner sentence. It is not a toast, routine alert, blocking modal, debug card, or backend-result display.

| Semantic state | Visible label and learner copy | Icon / semantic token | Interaction rule |
|---|---|---|---|
| `saved_locally` | **Saved on this iPhone.** It will sync when you’re back online. | `checkmark.circle`; `--cw-status-info` | Remains visible while queued work exists. No retry control. |
| `syncing` | **Syncing saved answers…** | `arrow.triangle.2.circlepath`; `--cw-status-info` | Indeterminate only while an active replay operation is occurring. Do not animate when Reduce Motion is enabled. |
| `needs_attention` | **Some saved answers need review.** | `exclamationmark.triangle`; `--cw-status-warning` | Keep affected work retained. Show **Review saved answers** only when a validated host recovery destination exists; otherwise show no futile action. |
| `sync_paused` | **Your saved answers remain on this iPhone.** | `pause.circle`; `--cw-status-warning` | Used for logged-out, switched-account, remote-disabled, or otherwise fenced replay. No automatic retry and no explanation of account, scope, flag, or server mechanics. |

Pack progress stays within the established required-pack surface. Show a determinate progress indicator only when the host supplies trustworthy byte progress; otherwise show an indeterminate active-operation indicator only for the live install/update operation. Offline audio availability is never implied by the study status row.

Status transitions announce the combined label and learner sentence once through VoiceOver and preserve the learner's existing focus. Each actionable control has a 44pt minimum hit target, an accessibility identifier owned by the host test target, and a visible text label; color alone never carries the state.

The UI can prove only observable local/recovery state. Phoenix evidence independently proves replay authorization, idempotency, conflict, scope isolation, and feature-gate behavior. Never place opaque scope references, mutation IDs, feature flags, routes, backend reasons, paths, hashes, provider information, account identifiers, device identifiers, payloads, media, or test/diagnostic data in learner-facing copy. [Source: D-02, D-07–D-09]

---

## Spacing Scale

Declared values (all multiples of 4; reuse `--cw-spacing-base: 4px`):

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4px | Icon-to-label gap; border/label separation |
| sm | 8px | Internal row stack and compact control gap |
| md | 16px | Status row padding and normal adjacent content gap |
| lg | 24px | Study-section padding; native `VStack` section spacing |
| xl | 32px | Major in-flow group separation |
| 2xl | 48px | Page-level break where an existing host layout needs it |
| 3xl | 64px | Existing page-level spacing only; do not introduce for this row |

Exceptions: iOS action controls use a 44pt minimum width and height. The status row may grow vertically for Dynamic Type; it never clips its label or learner sentence.

---

## Typography

Use exactly these four sizes in web/offline-island styles; native SwiftUI must use the matching Dynamic Type text style rather than fixed point sizes.

| Role | Size | Weight | Line Height |
|------|------|--------|-------------|
| Supporting label | 14px (`text-sm`) | 600 | 20px |
| Body / learner sentence | 16px (`text-md`) | 400 | 24px (1.5) |
| Status value / action label | 18px (`text-lg`) | 600 | 28px |
| Study heading | 20px (`text-xl`) | 600 | 30px (1.5) |

Only weights 400 and 600 are permitted for phase-owned UI. Do not use monospaced or technical text in learner-facing status/recovery content. At accessibility text sizes, content wraps and the enclosing study view scrolls; do not truncate labels, buttons, or status sentences. [Source: existing token scale and `RequiredPackViewAccessibilityTests.swift`]

---

## Color

Use the existing light/dark semantic token mappings; never hard-code a separate Phase 162 color.

| Role | Value | Usage |
|------|-------|-------|
| Dominant (60%) | `--cw-surface-default` (Foam 50 `#F7F1E6` in light; Current 950 `#09141A` in dark) | Study background and open space |
| Secondary (30%) | `--cw-surface-raised` (Foam 100 `#EFE6D6` in light; Current 900 `#0F1E26` in dark) | Status row/card surface with `--cw-border-default` |
| Accent (10%) | `--cw-action-bg` (Wake 700 `#2B756A` in light; Brass 500 `#C98A2E` in dark) | The enabled **Review saved answers** action and its focus/active affordance only |
| Destructive | `--cw-status-error` (Rust 600 `#9A4D35`) | No phase-owned destructive action; reserved and unused |

Accent reserved for: the enabled, validated host recovery action and focus indication for that action. State semantics use `--cw-status-info` and `--cw-status-warning` plus the specified icon and text label; no status color is an accent or a substitute for copy. Use `--cw-text-default` for readable status text and `--cw-text-muted` only for supporting non-status text.

---

## Copywriting Contract

| Element | Copy |
|---------|------|
| Primary CTA | **Review saved answers** — render only for `needs_attention` after the host supplies a validated recovery destination; otherwise omit the CTA. |
| Empty state heading | **No saved answers need review.** |
| Empty state body | **Your saved answers are up to date. Continue studying when you’re ready.** |
| Error / paused state | **Your saved answers remain on this iPhone.** Do not offer retry; return to study or wait until the host allows replay. |
| Destructive confirmation | None in Phase 162. Do not add reset, clear queue, discard answers, account-switch confirmation, or native alert/confirm UI. |

Use the four locked state sentences verbatim in the surface contract. Do not use “sync failed,” “server error,” “conflict,” “idempotency,” or technical explanations in learner copy. A host-owned recovery destination may explain its own domain action after it is validated; Phase 162 does not define generic conflict resolution.

---

## UI Considerations

Applicable state considerations resolved: 6 covered, 2 backstop, 0 unresolved.

| Category | Element(s) | Status | Resolution / Reason |
|----------|------------|--------|---------------------|
| loading | `syncing` status row; active pack operation | ✅ covered | A labeled indeterminate indicator appears only while the operation is active; pack becomes determinate only with real host byte progress. |
| error | `needs_attention`, `sync_paused` status row | ✅ covered | The Copywriting Contract's error/paused copy is visible, retained work is not deleted, and no generic retry appears. |
| empty | recovery destination list | ✅ covered | Empty results use the documented “No saved answers need review.” heading and body. |
| populated | recovery destination list | ✅ covered | Host-owned records use their host domain presentation; Phase 162 adds only the contextual status entry point. |
| partial | recovery destination | ✅ covered | Until a validated host destination exists, render the closed `needs_attention` state with no partial record detail or speculative controls. |
| overflow | status row and recovery list | 🧪 backstop | At Accessibility XXXL, labels and sentences wrap, the containing view scrolls, and 44pt controls remain reachable; prove with XCUITest. |
| zero-one-many | recovery destination list | ✅ covered | Zero uses the empty state; one and many preserve the host's domain list with the same status entry point and no count that implies backend acceptance. |
| long-text | status sentence, CTA, host recovery labels | 🧪 backstop | No ellipsis or clipping at Accessibility XXXL; assert visible full labels and hittable controls in XCUITest. |

---

## Registry Safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| shadcn official | none | not applicable — shadcn is not initialized and does not apply to this stack |
| third-party | none | not applicable — no third-party blocks are authorized |

---

## Scope Guardrails and Verification Hooks

- DEVICE-01 through DEVICE-05 use stable, host-owned accessibility identifiers and semantic visible state for XCUITest only; those identifiers must not encode sensitive or adopter-instance values.
- XCUITest verifies local lifecycle/audio and status/recovery visibility. Phoenix evidence verifies all server-authoritative replay results separately.
- Test the four state copies, single VoiceOver announcement/focus preservation per transition, Dynamic Type wrapping at Accessibility XXXL, 44pt target minimums, light/dark semantic-token contrast, reduce-motion behavior, and absence of sensitive/technical copy.
- The dated proof artifact has no learner-facing screen requirement and must retain only the redacted fields allowed by D-06. Screenshots, video, raw output, logs, and UI-derived identifiers are prohibited evidence.
- Android, generic synchronization/recovery UI, background replay, native alerts/confirms, diagnostic dashboards, and a new support-label taxonomy are out of scope.

---

## Checker Sign-Off

- [ ] Dimension 1 Copywriting: PASS
- [ ] Dimension 2 Visuals: PASS
- [ ] Dimension 3 Color: PASS
- [ ] Dimension 4 Typography: PASS
- [ ] Dimension 5 Spacing: PASS
- [ ] Dimension 6 Registry Safety: PASS

**Approval:** pending
