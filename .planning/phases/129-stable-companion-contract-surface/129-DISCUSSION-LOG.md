# Phase 129: Stable Companion Contract Surface - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-25
**Phase:** 129-Stable Companion Contract Surface
**Areas discussed:** Stability-note convention, Guide scope & placement, Contract-freeze test shape, Shell.Denial boundary

**Method:** User requested deep parallel subagent research on all four areas at once, then a single coherent one-shot recommendation (research-then-recommend pattern). Four `gsd-advisor-researcher` agents ran in parallel (Sonnet), each covering ecosystem idiom, DX, lessons from successful libs, and footguns. Synthesis locked below.

---

## Stability-note convention

| Option | Description | Selected |
|--------|-------------|----------|
| Prose `## Stability` section in moduledoc | Markdown section authors actually read; + `since:` badge | ✓ |
| `@moduledoc tags: [:public_api]` | Sidebar filter only; too subtle as primary signal | (supplement only, via groups_for_modules) |
| Custom `@stability :public` attribute | ExDoc silently ignores unknown metadata keys — no payoff | |
| ExDoc `since:`/`deprecated:` only | Communicates WHEN not WHETHER stable | (supplement: `since: "0.1.0"`) |

**User's choice:** Prose `## Stability` section + `since:` badge; three-tier vocabulary (public stable / private / patch-volatile). Verbatim template provided. Replace stale "in-tree for v3.5" line in `Crosswake.Companion`.
**Notes:** Ecosystem (Ecto/Phoenix/Plug/Broadway/Oban) has no machine-readable stability tier beyond `@moduledoc false` vs string. Footgun: empty hexdocs group if `@moduledoc false` types aren't promoted first.

---

## Guide scope & placement

| Option | Description | Selected |
|--------|-------------|----------|
| Pure Diátaxis reference (surface table) | Enumerate the 5 types, don't tutorialize | ✓ |
| Narrative guide | Risks duplicating companions.md | |
| Fold into existing companions.md | Mixes audience/JTBD | |

**User's choice:** Pure reference `guides/companion_contract.md`. New "Extension Authors" `groups_for_extras` group (between Truth and Advanced/Companions). New "Companion Contract" `groups_for_modules` entry — 5 modules by full name, not regex. Clean handoff: contract=what's stable, companions.md=how, compatibility.md=ranges.
**Notes:** Exemplars: Broadway (extension groups first-class), ecto_sql (core/spec/impl split). Anti-pattern: Plug burying `Plug.Conn.Adapter`. Footgun: regex `~r/Crosswake\.Compatibility/` would leak eval machinery.

---

## Contract-freeze test shape

| Option | Description | Selected |
|--------|-------------|----------|
| Inline `behaviour_info(:callbacks)` equality | Matches 3 existing codebase precedents; test IS the snapshot | ✓ |
| Checked-in golden snapshot file | Adds ceremony, no benefit for small team | |
| `Code.Typespec.fetch_callbacks/1` full AST | Brittle across Elixir versions; overkill | |

**User's choice:** Inline `MapSet.equal?` on the 6 frozen callbacks (equality, not membership) + `Code.fetch_docs/1` non-false/`:hidden`/`:none` moduledoc + `@typedoc` on the 4 struct `t()` types. Module list derived from `Mix.Project.config()` docs groups (single source of truth). `test/crosswake/proof/phase129_companion_contract_freeze_test.exs`, untagged, async. Actionable "bump both in same PR" failure hint.
**Notes:** `Code.fetch_docs` moduledoc enum is closed `{:none,:hidden,%{}}`. Write-test-first is the forcing function — fails until promotions land.

---

## Shell.Denial boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Active guard folded into freeze test | Assert Denial absent + Finding present in group | ✓ |
| Passive (just omit from group/guide) | Zero CI value; silent drift risk | |
| Separate dedicated guard test file | Noise vs folding into fresh freeze test | |

**User's choice:** Active enforcement folded into the freeze test (both edges). Add steering note to `Denial`'s own moduledoc (verbatim provided). Guide states companions never reference `Denial.reasons/0`.
**Notes:** Seam audit — frozen `Crosswake.Companion` callback surface is clean (`route_gated?/2` speaks Finding). rulestead/rindle clean; sigra (3 files) + chimeway resolver alias Denial but are internal non-behaviour surfaces extracting later (EXTRACT-FUT-01). Response-ownership precedent: Plug halt, Guardian auth_error, Absinthe middleware, Oban perform.

## Claude's Discretion

- Exact guide-table microcopy / intro within brand voice.
- `stable_id_message` slug wording.
- Whether `@typedoc` assertion extends beyond `t()`.

## Deferred Ideas

- Removing in-tree Denial coupling in sigra/chimeway → EXTRACT-FUT-01/02 (future milestone).
- `boundary` library for compile-time enforcement → out of scope for 129.
- Full telemetry public API → Phase 133.
- iOS UAT / shell lifecycle → Phase 134.
