---
phase: 44
slug: rindle-media-seam-contracts-and-reconciliation-vocabulary
status: draft
shadcn_initialized: false
preset: none
created: 2026-05-31
---

# Phase 44 — UI Design Contract

> Visual and interaction contract for frontend-hinted obligations in the Phase 44 contract slice. This phase is library-first; UI scope applies to example-host/docs surfaces that present these contracts.

---

## Design System

| Property | Value |
|----------|-------|
| Tool | none |
| Preset | not applicable |
| Component library | none (Phoenix-first existing host patterns) |
| Icon library | none required |
| Font | system-ui, -apple-system, "Segoe UI", sans-serif |

---

## Spacing Scale

Declared values (must be multiples of 4):

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4px | Inline label/icon separation |
| sm | 8px | Field and chip internal spacing |
| md | 16px | Default element spacing |
| lg | 24px | Section grouping |
| xl | 32px | Panel-to-panel gaps |
| 2xl | 48px | Page section breaks |
| 3xl | 64px | Top-level page rhythm |

Exceptions: Minimum touch target 44px for any icon-only or compact action.

---

## Typography

| Role | Size | Weight | Line Height |
|------|------|--------|-------------|
| Body | 16px | 400 | 1.5 |
| Label | 14px | 600 | 1.4 |
| Heading | 20px | 600 | 1.2 |
| Display | 28px | 600 | 1.2 |

---

## Color

| Role | Value | Usage |
|------|-------|-------|
| Dominant (60%) | #F8FAFC | App/document background surfaces |
| Secondary (30%) | #E2E8F0 | Cards, lane panels, code/result blocks |
| Accent (10%) | #0F766E | State badges (`queued/uploaded/scanning/available/rejected`), primary CTA, key invariant callouts |
| Destructive | #B91C1C | Reject/destructive confirmations only |

Accent reserved for: media state badges, "backend authoritative" indicators, primary contract-validation CTA, and invariant pass/fail markers only.

---

## Visual Hierarchy

Primary anchor: contract validation result panel. Secondary anchors: media state badges and backend-authority indicators. Tertiary content: helper copy, field hints, and trace metadata.

---

## Copywriting Contract

| Element | Copy |
|---------|------|
| Primary CTA | Validate Media Contract |
| Empty state heading | No Media Contracts Yet |
| Empty state body | Add an `UploadGrant`, `CaptureEvidence`, and `MediaObject` example to verify the seam before implementation. |
| Error state | Contract validation failed. Fix the highlighted field values, then re-run validation. |
| Destructive confirmation | Reset Draft Contract: This clears unsaved contract example values. Type `reset` to confirm. |

---

## Registry Safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| shadcn official | none | not required |
| third-party | none | not applicable |

---

## Checker Sign-Off

- [x] Dimension 1 Copywriting: PASS
- [x] Dimension 2 Visuals: PASS
- [x] Dimension 3 Color: PASS
- [x] Dimension 4 Typography: PASS
- [x] Dimension 5 Spacing: PASS
- [x] Dimension 6 Registry Safety: PASS

**Approval:** approved 2026-05-31

---

## Pre-Populated Sources

- `44-CONTEXT.md`: contract vocabulary, authority/evidence split, low-frequency bridge posture, and Phase 45 handoff constraints.
- `.planning/REQUIREMENTS.md` (`MEDIA-01`, `MEDIA-02`): required state lane and backend-authoritative availability.
- `.planning/PROJECT.md` and `.planning/MILESTONE-ARC.md`: Phoenix-first thesis, explicit route ownership, no high-frequency bridge progress UI.
- Defaults: typography, spacing, and base neutral palette where upstream artifacts were silent.
