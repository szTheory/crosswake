# Crosswake Agent Guide

## Project Context

Read these first before planning or implementation work:

1. `.planning/PROJECT.md` — project thesis, constraints, non-goals, and decisions
2. `.planning/REQUIREMENTS.md` — current v1/v2 scope and traceability
3. `.planning/ROADMAP.md` — phase ordering, goals, and success criteria
4. `.planning/STATE.md` — current position, blockers, and deferred items

## Working Rules

- Preserve the core thesis: Crosswake is a Phoenix-first route-policy and runtime-contract system, not a universal UI framework.
- Keep runtime ownership explicit per route. Do not collapse designs into generic WebView wrapper behavior or LiveView-driven native rendering.
- Treat bridge contracts as semantic, typed, versioned, and low-frequency. If a flow needs continuous client authority, move it toward an offline island or native screen.
- Keep offline claims honest. Distinguish cached read-only behavior from true local-first mutation with journals, outboxes, and reconciliation.
- Treat diagnostics, support matrices, proof lanes, and rough-edge documentation as product surface, not cleanup work.
- Respect v1 scope boundaries in `.planning/PROJECT.md` and `.planning/REQUIREMENTS.md` before adding integrations or wider native breadth.

## Workflow

- Start the project with `$gsd-discuss-phase 1` to refine phase context before planning.
- Use `$gsd-plan-phase 1` only when discussion is intentionally skipped.
- Update planning artifacts as work progresses so requirements, roadmap state, and project decisions stay aligned.
