# Phase 128: Collateral + "See It Run" Guide - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-22
**Phase:** 128-collateral-see-it-run-guide
**Areas discussed:** Collateral capture & storage, see_it_run.md structure & ExDoc slot, README + QUICK_START routing, Doc-contract test scope (all four selected)

---

## Discussion shape

The maintainer selected **all four** gray areas and requested the research-then-recommend
pattern: dispatch parallel research subagents (pros/cons/tradeoffs per option, idiomatic
Elixir/Phoenix/ExDoc, lessons from successful libs/apps incl. other ecosystems, DX/JTBD/UX
lenses, brand-book research in `prompts/` + `brandbook/BRAND-SPEC.md`), then synthesize a
single coherent one-shot recommendation set — explicitly "so I don't have to think". No
sequential one-by-one questions.

Four subagents ran in parallel (one per area). Each returned a structured report; all four
converged coherently. The synthesis is recorded as D-01..D-20 in CONTEXT.md.

---

## Area 1 — Collateral capture & storage (COLL-01, COLL-02)

| Option | Description | Selected |
|--------|-------------|----------|
| Store under `guides/` | ExDoc-native, but SHIPS in the Hex tarball (`files:` allowlist) → bloats every `mix deps.get` | |
| Store under `brandbook/collateral/see-it-run/` + raw.githubusercontent URLs | Hex-excluded, renders inline in GitHub/ExDoc, mirrors existing readme-header pattern | ✓ |
| External CDN / Loom / YouTube for recording | No tarball weight, but link-rot + account-maintenance risk | |

**Decision:** brandbook/ + raw-URL (D-01/D-02). Web shots automated via in-repo Playwright;
native shots human-captured via a `bin/capture-collateral.sh` harness (Xcode/SDK required, can't
be automated — D-03). Recording = committed optimized GIF <5MB, not MP4/external (D-05). Honest
labeling via the canonical `emulator evidence` term everywhere (D-06).
**Notes:** Native capture is an inherent manual gate flagged for the planner/executor. Phase ships
real committed files, never placeholders (honesty culture).

## Area 2 — see_it_run.md structure & ExDoc slot (DOCS-01)

| Option | Description | Selected |
|--------|-------------|----------|
| Numbered TL;DR gameplan | Duplicates QUICK_START steps → drift risk | |
| Blockquote "declaration block" gameplan + payoff-first JTBD sections | Hero command + honest scope up top; visual proof before prose; mirrors banner structure | ✓ |
| Concept-first (explain ownership model before demo) | Forces theory before payoff; wrong Diátaxis type for an orientation gateway | |

**Decision:** Blockquote gameplan (D-07); JTBD section outline A→B→C, each a clean exit point
(D-08); orientation/tutorial-hybrid written action-first (D-09); ExDoc Start slot = README →
see_it_run → route_policy → install (D-10).
**Notes:** Diátaxis classification argued explicitly — orientation gateway, one type per guide.

## Area 3 — README + QUICK_START routing (DOCS-02)

| Option | Description | Selected |
|--------|-------------|----------|
| New bullet in "Evaluating Crosswake" list | Least effort, but buries payoff in link soup | |
| New `## See it run` section between "What this is not" and "Choose your path" | Scope → proof → routing; demo gets first-class prominence | ✓ |
| Demo above the scope sections | Invites "this is React Native" misread | |

**Decision:** ONE hero command = `bin/see-it-run.sh`, docker-compose demoted to fallback (D-11);
README `## See it run` section placement (D-12); link-to-guide image default, optional inline
montage with label in alt text (D-13); QUICK_START top `> New here?` pointer + Option-A rename
(D-14); verbatim honest-label sentence using `emulator evidence` (D-15).
**Notes:** Routing is one-directional/non-circular: README → see_it_run → (forward) QUICK_START.

## Area 4 — Doc-contract test scope (DOCS-03)

| Option | Description | Selected |
|--------|-------------|----------|
| Re-assert banner strings in the guide test | Duplicates Phase-127 banner test → forbidden by D-21 | |
| Markdown-only source-derived test, mirror quick_start_adoption_drift_test.exs | Clean boundary; derives port/routes from source; 3 anti-vacuity cases | ✓ |
| Include binary-existence guards now | Would leave CI red before human captures the binaries (brittleness footgun) | |

**Decision:** `Crosswake.Guides.SeeItRunTest` mirroring the quick-start drift test (D-16); assertion
set all source-derived (D-17); explicit no-overlap boundary with the banner test (D-18); collateral
existence guard deferred to a sibling test added post-capture (D-19); exactly three synthetic
anti-vacuity cases — wrong port / missing route / missing posture label (D-20).
**Notes:** Both this test and the banner test derive port from runtime.exs independently — that's
correct (shared source); the forbidden duplication is asserting the same banner STRING twice.

---

## Claude's Discretion

- GIF capture tool + montage auto-compose vs. hand-made.
- GIF scope (all three GUI windows vs. terminal+browser with static montage for native).
- Secondary `guides/see_it_run.md` bullet in the "Evaluating Crosswake" list (recommended yes).
- Exact `/`-home-route assertion strategy.
- Test-first vs. guide-first authoring order.

## Deferred Ideas

- `see_it_run_collateral_test.exs` binary-existence guard — added after collateral is committed (D-19).
- Automated CI native-collateral capture lane — out (expensive, out of v15.0 scope).
- `bin/see-it-run.sh --backend-url`/port override — deferred (port 4700 locked by Phase 125).
- Vale prose-linter / markdown-link-check toolchain / CI montage compose — out; in-process Elixir
  drift test + optional local ImageMagick sufficient.
