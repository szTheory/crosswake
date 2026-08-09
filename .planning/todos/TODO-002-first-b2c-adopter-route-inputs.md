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

## Available handoff signal

The adopter has confirmed that a comprehensive screen/flow coverage artifact already exists and
can be supplied as a route-policy-map handoff. Do not reconstruct it or paste the raw artifact into
git. Request a sanitized export that maps each relevant route to the closed fields above plus the
minimum navigation presentation needed by Phase 161.1.

Safe media facts available for normalization:

- codec family is MP3;
- archive/pack size remains `unknown_blocking` until the adopter supplies an approved size band;
- some study route classes require pronunciation media to render a usable prompt, so missing
  required media needs an explicit designed fallback and must never silently omit the route item.

Do not durably record object-store vendors, URL derivation formulas, exact content counts, language
or voice taxonomy, per-item media layout, or the raw screen/flow inventory.

## Constraints

- Use **First B2C Adopter** in durable planning and **first adopter** in public guides.
- Record payload categories, never real learner content or customer data.
- Keep product-domain schemas, curriculum taxonomy, media layout, CDN/auth choices, billing model,
  feature-flag names, and UI copy host-specific.
- Do not let this one-day design pass delay a web-only customer Alpha.

## Routing

Transform the offered handoff during `$gsd-discuss-phase 161.1`. Once every required route row is
sanitized and validates, update the route-policy map and close this todo. Fast-changing execution drafts are in
`.planning/FIRST-B2C-ADOPTER-LINEAR-ISSUE-DRAFTS.md`.
