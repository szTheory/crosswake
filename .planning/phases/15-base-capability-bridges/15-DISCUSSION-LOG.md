# Phase 15: Base Capability Bridges - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md. This log records the alternatives considered and the synthesized recommendation chosen.

**Date:** 2026-05-20
**Phase:** 15-base-capability-bridges
**Areas discussed:** Share capability payload scope, command string taxonomy.

---

## Share Payload Format and Scope

| Option | Description | Selected |
|--------|-------------|----------|
| Primitive Strings Only (`url`, `title`, `text`) | Pure stateless bridge, exact parity with Web Share API string fields. | ✓ |
| Strings + Base64 Binary Payload | Allows sharing dynamic memory blobs, but risks OOM crashes and demands complex native file setup. | |
| Strings + Native Download-then-Share | Prevents bridge bloat, but introduces async state and mandates temporary file lifecycles. | |

**User's choice:** Autonomous agent recommendation accepted per project guidelines.
**Locked outcome:** Restrict to `url`, `text`, and `title`.
**Notes:** Preserves the Phase 15 mandate for "simplest low-frequency stateless capabilities." Heavy files should be URL-hosted by the server instead.

---

## Command Naming Taxonomy

| Option | Description | Selected |
|--------|-------------|----------|
| Dot-separated verb phrases | E.g. `app.info.get`, `haptics.impact`, `share.invoke` | ✓ |
| Bare nouns | E.g. `app_info`, `haptics`, `share` | |

**User's choice:** Autonomous agent recommendation accepted per project guidelines.
**Locked outcome:** Use dot-separated verb phrases.
**Notes:** `app.info.get` and `haptics.impact` are already present as legacy IDs in `lib/crosswake/manifest/builder.ex`. Following suit with `share.invoke` keeps the bridge registry consistent.
