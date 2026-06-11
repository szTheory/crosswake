# Phase 101: Offline UI Consolidation & Polish - Discussion Log

**Date:** 2026-06-11
**Context Record:** `101-CONTEXT.md`

> **Note:** This log records the discussion that led to the phase context. It is for human reference and retrospective only. Downstream agents (researcher, planner, executor) consume `CONTEXT.md`, not this log.

---

## Generator route injection
**Options presented:**
- Generator route injection: Does `mix crosswake.gen.offline_ui` just drop the files, or does it also attempt to inject the route into `router.ex`?
- Tailwind dependency: Should the generated UI rely on the host's existing `app.css`/Tailwind setup, or use inline styles/standalone CSS?
- Microcopy localization: Should the microcopy be hardcoded in the HTML for easy editing, or extracted via Gettext?
- JS payload stripping: Should we completely omit Phoenix.js and LiveView JS from the offline layout to save bandwidth, or keep them but disable connection attempts?

**User selected:**
All options selected via one-shot autonomy directive.

**Notes:**
User requested deep research leveraging subagents/autonomous analysis to provide one-shot perfect recommendations for all gray areas, prioritizing Elixir/Phoenix idioms, DX, the brand book, and existing prompts research.

**Claude's Discretion Applied:**
- Synthesized the recommendations directly based on strict Phoenix generator idioms (print instructions, no AST injection).
- Chose host-owned Tailwind utility classes over standalone CSS.
- Chose hardcoded template strings over forced Gettext for host-owned templates.
- Chose dedicated `offline_root.html.heex` to strip LiveView JS completely.

---
