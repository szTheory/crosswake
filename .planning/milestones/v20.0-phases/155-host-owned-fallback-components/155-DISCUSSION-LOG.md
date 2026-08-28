# Phase 155: Host-Owned Fallback Components - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-29
**Phase:** 155-host-owned-fallback-components
**Areas discussed:** all 8 selected — Fallback trigger & artifact shape; Undeclared → raise vs
rendered denial; Action-menu form factor; Menu fallback before the native menu exists; Token &
theming contract; Focus trap + where the JS lives; Regeneration/drift/no-`Crosswake.UI` guard;
Proof-lane placement

---

## Method

The user selected all 8 gray areas across two rounds and requested research-backed
recommendations rather than sequential questioning ("one-shot a perfect set of recommendations
so i dont have to think"), with explicit lenses: idiomatic Elixir/Phoenix practice, cross-
ecosystem lessons from successful projects, DX/ergonomics from the consumer's perspective,
JTBD and who/what/where/when/why framing, design pillars, brandbook adherence, microcopy,
creative direction, and API design from the consumer's rather than the provider's side.

Five `gsd-advisor-researcher` agents ran in parallel:

| Agent | Scope |
|---|---|
| R1 | Fallback trigger semantics + generator artifact shape |
| R2 | Undeclared raise-vs-denial + menu-before-native sequencing |
| R3 | Confirm/menu form & feel, a11y contract, tokens, microcopy, creative direction |
| R4 | Token & theming contract for adopter-owned files; focus trap + JS delivery |
| R5 | Second-run/drift policy, FALL-02 guard, PROOF-01 lane placement |

Full reports were written to a session-local scratch directory
(`/Users/jon/.claude/jobs/fe4cda4b/tmp/155-R{1..5}-*.md`) and are **not** durable project
artifacts. CONTEXT.md is the record.

---

## Convergent findings (reached independently — recorded because independence is the signal)

| Finding | Agents | Evidence path |
|---|---|---|
| Phase 155 pushes nothing (fallback-first) | R1, R2 | R1 via shipping order (`contract.ex:11-22` has no menu); R2 via three shipped guards incl. mount-time death |
| Zero new JS; focus trap is `Phoenix.Component.focus_wrap/1` | R3, R4 | `phoenix_component.ex:3173`; built-in hook already served + imported |
| `role="menu"` must be rejected | R3, R4 | APG Menu contract obliges roving tabindex → JS |
| `resolve/2` raises despite docstring promising otherwise | R1, R2 | `bridge.ex:270-271` vs `fetch_state!` |
| Criterion 3's wording is wrong; the raise stays | R2, R4, R5 | "undeclared" is three distinct moments; only (B) renders |
| Panel must be `surface-inset`; `surface-raised` fails AA at 4.11:1 | R3, R4 | same ratio computed separately via `contrast.mjs` |
| `--cw-action-focus-ring` fails WCAG 1.4.11 today, invisibly | R3, R4 | 2.93:1 / 2.61:1; `contrast.test.mjs:96-122` tests text pairs only |
| `--cw-status-error` is 2.44:1 on dark | R3, R4 | red text/border mathematically dead on dark |
| Drift MANIFEST is curated, not a glob | R3, R4, R5 | `check-consumer-drift.mjs:29` |
| Proof lane needs no new workflow or required check | R2, R4, R5 | `e2e-proof` → `merge-blocking-offline-sync-e2e` |

---

## Conflicts and how they were resolved

### Token scoping — direct `var(--cw-*)` vs a scoped alias layer

| Option | Description | Selected |
|--------|-------------|----------|
| Direct `var(--cw-*)` references (R3) | Generated CSS reads Crosswake semantics directly, zero theme logic, exactly like `offline.css` | |
| Host-owned `--cwfb-*` alias layer (R4) | One alias block mapping to `var(--cw-*)`; adopter re-points ~12 lines to adopt their own system | ✓ |

**Resolution:** R4. The adopter-with-their-own-design-system path is the common case, and R4's
approach turns it into a 12-line edit instead of a fight with every declaration. In-repo
precedent exists (`app.css:220-224`), and the drift gate was written to permit alias layers
(`check-consumer-drift.mjs:99-114`). R3 did not argue against it — it simply proposed the
simpler option.

### Scrim mechanism — `color-mix` vs 8-digit hex primitive

| Option | Description | Selected |
|--------|-------------|----------|
| `color-mix` (R3) | Compose the scrim; needs a `resolveAlias` fix at `compile-tokens.js:22-26` for embedded `{…}` aliases | |
| 8-digit hex primitive (R4) | `current.950a72 = #09141AB8`, universal support, no compiler change | ✓ |

**Resolution:** R4, decisively and on evidence R3 lacked. `color-mix` has an **iOS 16.2 floor**
and this project's floor is **iOS 15.0** (`Package.swift:9`) — R3's approach would break on
supported devices. R4 also caught that `compile-tokens.js:67`'s `groups` array must gain
`'overlay'` or the token is *silently dropped*, which would render the modal transparent with
no gate failure.

### How many tokens to add

| Option | Description | Selected |
|--------|-------------|----------|
| Zero — literals only (R1) | Adding tokens is itself a tier decision; SEED-005 owns it | |
| Two (R3) | `--cw-status-error-fg` + `--cw-surface-scrim` | ✓ (as amended) |
| Three (R5) | `overlay-scrim`, `elevation-raised`, `layer-overlay` | |

**Resolution:** two tokens — the scrim (named `--cw-overlay-scrim`, built by R4's mechanism) and
`--cw-status-error-fg`. Elevation/z/motion declined 3-to-1 (R1, R3, R4 against R5) and routed to
SEED-005. R3 supplied the constraint the others missed: this takes the semantic count **27 → 29
against a documented hard cap of 30** (`AUDIT.md:392`).

### `tokens.css` — copied into the host, or library-served

| Option | Description | Selected |
|--------|-------------|----------|
| Copy into host (R1, following `gen.offline_ui`) | Precedent-consistent; adopter owns it | |
| Library-served via a second `Plug.Static` (R4) | One source of truth at `/crosswake/tokens.css` | ✓ |

**Resolution:** R4. It also fixes two verified latent defects R1's approach would perpetuate:
`gen.offline_ui`'s `~p"/assets/tokens.css"` **404**, and a byte-identical **third** copy of
tokens.css that nothing gates.

### Proof spec — extend the existing tour, or a new file

| Option | Description | Selected |
|--------|-------------|----------|
| Extend `route_tour.spec.ts` (R2) | Reuses existing harness | |
| New `native_controls_fallback.spec.ts` (R4, R5) | ~200-line new file rather than growing a 613-line one | ✓ |

**Resolution:** new file. Both land in the same already-required job, so the cost is identical
and the maintainability is not.

---

## Questions put to the user

### Focus-ring token: fix in Phase 155?

| Option | Description | Selected |
|--------|-------------|----------|
| Fix in 155 + close the gate hole | Light → wake-700, **and** add focus-ring pairs to `contrast.test.mjs` | ✓ |
| Fix the ring, defer the gate test | Cheaper, but the next regression ships silently | |
| Defer both to SEED-005 | Composite box-shadow ring in generated CSS only; shipped defect stays | |

**User's choice:** Fix in 155 + close the gate hole.
**Notes:** The token is failing WCAG SC 1.4.11 in already-shipped code (`offline.css:9-12`,
`app.css:75`) and CI cannot see it. Criterion 2 requires the fallbacks "meet the existing
contrast gates," so shipping through a blind gate would be the DNA doc's
"marketing framing outrunning architectural truth" footgun. Recorded as D-33.

### Destructive action treatment

| Option | Description | Selected |
|--------|-------------|----------|
| Filled button + `--cw-status-error-fg` | 6.02:1 both themes; costs one token (27→29 of 30) | ✓ |
| Text + border-left shape cue, no new token | Zero tokens; weaker affordance on dark | |

**User's choice:** Filled button, add the token.
**Notes:** Without it a destructive confirm has **no color signal at all** on dark, only shape.
For "Delete this job? It cannot be undone," losing the danger channel on half of users' devices
is a safety regression rather than a style preference. Recorded as D-32.

### Ready to write CONTEXT.md?

| Option | Description | Selected |
|--------|-------------|----------|
| Write CONTEXT.md | Lock all decisions | ✓ |
| Push on the 155→156 data shape first | The `actions` shape is the phase's one-way door | |
| Push on the confirm-modal framing first | Confirm has no native path, ever | |

**User's choice:** Write CONTEXT.md.
**Notes:** Both deferred topics were captured as decisions rather than dropped — the `actions`
shape as D-53 (flagged one-way, dedicated planning review requested) and the confirm-modal
framing as D-07/D-08.

---

## Claude's Discretion

- Exact `--cwfb-*` alias names and their ordering (D-24 fixes the mapping, not the spelling).
- Wireframe-level spacing, the 20° wake-seam geometry, scroll-shadow treatment.
- Test-file organization within the new spec; which existing helpers to reuse.
- Whether the token-count cap gains a mechanical test in this phase (D-27).

## Notable side-findings (not gray areas — defects found while researching)

- `script/automated_uat.mjs` is **not** the browser route tour, contrary to an assumption made
  early in this session. It is a hand-run phase-UAT markdown writer keyed to Phase 150 with zero
  hits in `.github/`. The correction is recorded as D-41.
- Phase 154's **D-29 is factually wrong** about which denial reason old natives emit (D-56).
- `UX-CONTRACT.md:15` and `research/v20/SUMMARY.md:76-77` mis-cite "BRAND-SPEC §7" for the
  module-level no-component-tier rule; §7 is the *token* tier rule (D-57).
- `patcher.ex:129-131` returns `[:marker_reused]` without reconciling block contents, so existing
  Phase 154 adopters would silently miss the new tokens plug (D-52).
- `Phoenix.LiveComponent` is *technically blocked* for this use, not merely disfavored —
  `diff.ex:1145-1152` (D-04).
- `e2e-proof` uploads no failure artifacts, unlike `route-tour-proof:231-241` — must be fixed
  before landing a required browser assertion (D-49).

## Deferred Ideas

- Elevation / z-index / motion / border-width / padding token tier → SEED-005.
- Trigger-anchored dropdown for the action menu at wide viewports → SEED-005.
- The five unbounded native denial `String` seams → SEED-008.
- `igniter` adoption for generator codemods / three-way merge → not this phase.
- A mechanical semantic-token count test against the cap of 30.
- Phase 156 must re-derive D-29's premise rather than trusting it.
- Fixing `--cw-status-error`'s dark-theme text/border contrast generally, beyond the filled
  button case.
