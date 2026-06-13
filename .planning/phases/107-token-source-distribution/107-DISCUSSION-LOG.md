# Phase 107: Token Source & Distribution - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-13
**Phase:** 107-Token Source & Distribution
**Areas discussed:** Distribution mechanism (advisor mode, research-backed)

---

## Distribution mechanism (NORM-03)

Advisor mode (opinionated / minimal_decisive profile). One research agent investigated design-token distribution idioms against the discovered binding constraint that `brandbook/` is excluded from the Hex package.

| Option | Description | Selected |
|--------|-------------|----------|
| Vendor by copy | compile-tokens.js writes a packaged mirror into `priv/`; the offline_ui generator copies it verbatim into the host's static assets and links it as a separate `<link>` before app.css (ensure_file no-clobber); example host uses the identical mechanism. Statically checkable by Phase 109. | ✓ |
| Inline into `<style>` | Generator inlines tokens.css contents into a `<style>` block in offline_root.html.heex. | |
| Serve dep's priv/static | Host configures Plug.Static to serve crosswake's `priv/static` directly; both consumers link the lib-owned file with no copy. | |

**User's choice:** Vendor by copy (Recommended)
**Notes:** Inline rejected — different mechanism than the host uses (violates NORM-03 "one mechanism"), goes stale at generate-time, harder to grep-verify. Serve-dep's-priv/static rejected — requires per-consumer host config and a fragile mount dependency. Copy chosen for self-containment, offline-first robustness, single-mechanism consistency across both consumers, and clean Phase 109 static checkability.

---

## Claude's Discretion

Decided directly without asking (opinionated profile — low/medium stakes):
- **Emission scope:** emit the full font + dimension token set, not just consumer-referenced subset.
- **Naming/format:** keep existing dot-path → `--cw-…` convention; comma-joined quoted font stacks; raw dimension values; non-color tokens in their own labeled `:root` block(s), no dark variants.
- **Mirror location:** `priv/static/crosswake/tokens.css` recommended; retain `brandbook/tokens/tokens.css` (frozen brand book links it).
- **Internal refactor** of compile-tokens.js (`props()` split, second writeFileSync, serialization helpers) and documentation-file placement left to planner.

## Deferred Ideas

- Consumer rewiring (app.css + offline_ui templates onto tokens; drop Tailwind + stale generator theme) → Phase 108 (NORM-01/02/04).
- Drift-prevention CI gate → Phase 109 (PROOF-01).
- Byte-parity assertion between the brandbook copy and the priv mirror → likely folded into Phase 109's gate.
