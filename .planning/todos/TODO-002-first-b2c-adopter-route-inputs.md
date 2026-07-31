---
id: TODO-002
title: Collect sanitized First B2C Adopter route-inventory inputs
status: open
created: 2026-07-30
surfaced_by: v21.0-adopter-priority-reset
relates_to: RESET-02 (Phase 158), milestone v21.0 First B2C Adopter Readiness
---

# Collect sanitized First B2C Adopter route-inventory inputs

## Outcome

Complete the one-day route-policy map without adding identifying business or personal details to
git.

## Inputs needed

- concrete route IDs and paths;
- mutation actions and payload categories;
- cache staleness tolerance;
- auth level, recent-auth, logout, and account-switch behavior;
- expected pronunciation archive sizes and codecs;
- online, offline, denied, corrupt-pack, and disabled fallbacks; and
- the host flag used to disable study entry and replay.

## Constraints

- Use **First B2C Adopter** in durable planning and **first adopter** in public guides.
- Record payload categories, never real learner content or customer data.
- Keep product-domain schemas, curriculum taxonomy, media layout, CDN/auth choices, billing model,
  feature-flag names, and UI copy host-specific.
- Do not let this one-day design pass delay a web-only customer Alpha.

## Routing

Resolve during `$gsd-discuss-phase 158`. Once resolved, update the route-policy map and close this
todo. Fast-changing execution drafts are in
`.planning/FIRST-B2C-ADOPTER-LINEAR-ISSUE-DRAFTS.md`.

