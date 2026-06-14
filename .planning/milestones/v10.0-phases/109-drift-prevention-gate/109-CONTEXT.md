# Phase 109: Drift-Prevention Gate - Context

**Gathered:** 2026-06-14
**Status:** Ready for planning

<domain>
## Phase Boundary

Extend the v9.0 `brand-structural` CI gate with a **deterministic, browser-free textual check** that fails the build (non-zero exit) when any **normalized consumer** reintroduces a brand-color drift — specifically: a hardcoded hex color, a primitive-tier token reference, or the loss of all semantic `var(--cw-` references. Codifies the clean state achieved in Phase 108 so it cannot silently regress.

**In scope (PROOF-01):**
1. A new structural drift check (Node script under `brandbook/tools/`) that scans a curated set of normalized consumer files and asserts the per-file rules in `<decisions>` (D-03).
2. Wiring that check into the existing **required** `brand-structural` job (same check name) and broadening the workflow's `on.paths` so the gate fires on consumer/token edits (D-01).
3. A one-command local runner that produces the identical pass/fail result CI produces (success criterion #4).
4. A test/contract pinning the manifest + rules (mirroring the NORM-04 generator-test pattern), so the gate's own assertions don't silently rot.

**Out of scope (deferred — see `<deferred>`):**
- Fixing `offline_study.js` (innerHTML hex) and `step_up_challenge_live.ex` (dead `bg-[#…]` Tailwind) — known, explicitly deferred; the gate must NOT scan them (would break the build day one).
- Any change to token *values/names*, `crosswake.tokens.json`, `compile-tokens.js`, the brand book, or the consumer files themselves (they are already normalized and zero-hex).
- A new separate CI job / new required-status-check name (rejected — see D-01 rationale; branch-protection is harness-blocked).
- Promoting any advisory (`brand-visual`) check to required.

**Requirements:** PROOF-01.

</domain>

<decisions>
## Implementation Decisions

All four areas were researched inline (codebase scout + full prior-context reads + targeted verification greps) and locked decisively per the `opinionated`/`minimal_decisive` profile — nothing here is high-impact (internal CI tooling, no public API, nothing destructive). User accepted all four as-locked.

### Check placement & CI triggers
- **D-01:** The drift check is a **new step inside the existing `brand-structural` job** in `.github/workflows/brandbook-verify.yml` — **same required check name**, so no new branch-protection entry is needed (branch-protection is currently harness-blocked; adding a new required check would compound that). Implement as a **Node script in `brandbook/tools/`** (the established tool location), reusing `contrast.mjs`'s `parseHex()` + 17-color palette and the hex/semantic-var regex idiom already in `compile-tokens.test.mjs`. **No browser, no Playwright, no Elixir toolchain** (satisfies success criterion #3: textual/deterministic, Linux+macOS identical). Place the step **before** the Playwright install steps so a drift failure fails fast and cheap.
- **D-01a:** Broaden the workflow `on.paths` (both `pull_request` and `push`) to add the consumer globs so the gate actually fires on the files it guards:
  - `examples/phoenix_host/priv/static/css/app.css`
  - `priv/static/crosswake/**` (vendored `offline.css` **and** distributed `tokens.css`)
  - `priv/templates/crosswake/offline_ui/**`
  - `examples/phoenix_host/lib/crosswake_example_web/controllers/offline_html/**`
  - **Accepted trade-off:** a consumer-only change now also triggers the full brandbook job (Playwright installs). Acceptable for this low-frequency repo; the value is keeping **one** required check rather than fragmenting the gate the goal says to "extend."
  - **Free win:** adding `priv/static/crosswake/**` makes the *existing* `compile-tokens.test.mjs` byte-parity test (D-04) also run when someone edits the distributed `tokens.css` directly — closing a real gap with zero new code.

### Coverage model — curated manifest, not glob discovery
- **D-02:** The check scans a **curated, declarative manifest** of the normalized consumer files, each annotated with which assertions apply (per-file-type). **NOT** a glob over `examples/**` / `priv/**`. Two hard reasons:
  1. `offline_study.js` (`#9A4D35`/`#fee2e2`/`#ef4444`) and `step_up_challenge_live.ex` (`bg-[#2563EB]`) carry hex/Tailwind but are **explicitly deferred** — a glob would flag them and break the build immediately.
  2. CSS files and HEEX templates need *different* assertions (CSS must contain `var(--cw-`; templates reference tokens via linked CSS, not inline) — a manifest expresses that cleanly; a uniform glob can't.
  - **Accepted maintainability cost:** a future new consumer must be added to the manifest. Make this explicit — a header comment in the manifest plus the D-05 contract test documents the expectation. (A glob-with-exclusion-list was rejected: the exclusion list itself goes stale and silently over-broad globbing reads as "covered" when it isn't.)

### Detection rules (per file)
- **D-03:** Assertions, by file class:
  - **Every listed file:** forbid any `#`-hex color literal — regex shaped `#[0-9a-fA-F]{3,8}` with a guard so CSS `#id` selectors don't false-positive (current files have no all-hex-letter IDs, but the guard is required for robustness). This is **stricter than "matching one of the 17 brand colors"** — but every listed file is **zero-hex today** (verified: served `app.css` 0 hex / 47 `var(--cw-`; `offline.css` 0 hex / 38 `var(--cw-`; templates & example offline page 0 hex), so the strict rule is safe and catches *any* drift, including a non-palette hex. A brand-color match is a subset → satisfies success criterion #1.
  - **Every listed file:** forbid `var(--cw-primitive-` (semantic-only boundary rule, D-04 from Phase 108 — primitives must never cross into consumer CSS).
  - **CSS files** (`examples/.../app.css`, `priv/static/crosswake/offline.css`): require **≥1 `var(--cw-`** reference (success criterion #2: detects regression to hardcoded values).
  - **HEEX templates / example offline page:** forbid the **retired Tailwind utility classes** (e.g. `bg-white`, `bg-cw-*`, `text-cw-*`, `min-h-screen`, `flex`, `border-gray-*`, `border-cw-*`, `space-y-*`, `max-w-md`) and inline hex. They reference tokens through linked stylesheets, so do **not** require inline `var(--cw-` in markup.
  - **Leave the known rgba shadow alone:** `box-shadow: … rgba(9,20,26,0.06)` has no token and is a deferred shadow-opacity item — it is `rgba()`, not a `#`-hex, so the hex regex naturally ignores it. Do not add an rgba rule.

### tokens.css byte-parity — reuse existing, do not duplicate
- **D-04:** Do **not** write a new parity check. `brandbook/tools/compile-tokens.test.mjs:222` already asserts `priv/static/crosswake/tokens.css` is byte-identical to `brandbook/tokens/tokens.css` (verified currently identical), and it already runs in `brand-structural` via the "Token JSON round-trip" step. The only gap was the path trigger — closed by D-01a. Parity drift-prevention is therefore covered for free; the planner must NOT re-implement it.

### Claude's Discretion
- **Script form** — plain `node brandbook/tools/check-consumer-drift.mjs` (exit 1 on violation, mirroring `check-production.mjs`) **or** a `node --test …test.mjs` (mirroring `compile-tokens.test.mjs`). Either satisfies success criterion #4; pick whichever gives the cleaner one-command local runner with a per-file `file:line — rule` violation report. Plain-script is the lighter default.
- Exact manifest representation (inline JS array/object in the script vs. a small adjacent `.json`/`.mjs`), exact regexes (subject to the D-03 guards), exact step name and ordering within the job (subject to "before Playwright install"), and the exact Tailwind blocklist (derive the full retired set from the Phase 108 NORM-04 test contract).
- Wording of the failure message and any `::error` GitHub annotations.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements & roadmap
- `.planning/REQUIREMENTS.md` — PROOF-01 (this phase, line 26); the required-vs-advisory split rationale (≈lines 1–62, 84).
- `.planning/ROADMAP.md` § "Phase 109: Drift-Prevention Gate" — goal + 4 success criteria (the acceptance bar).
- `.planning/STATE.md` § Accumulated Context — frozen-contract, "served-vs-source app.css landmine," deferred offenders.
- `.planning/phases/108-consumer-normalization/108-CONTEXT.md` — what "normalized" means per file (D-01…D-13), the canonical consumer file list, the semantic-only/no-primitive/no-`var()`-fallback rules the gate enforces, and the explicit Phase-109 deferred bullet (`<deferred>`) that pre-scoped this gate.

### CI gate being extended (read before editing the workflow)
- `.github/workflows/brandbook-verify.yml` — the `brand-structural` (required) and `brand-visual` (advisory, `continue-on-error`) jobs; current `on.paths` is `brandbook/**` only; header comment documents the required-vs-advisory contract and the branch-protection integration point. **The new step goes in `brand-structural`; do not touch `brand-visual` or add a new required check name.**

### Reusable tooling (read for code to reuse, not modify)
- `brandbook/tools/contrast.mjs` — `parseHex()` (regex-validated, lines ≈19–29) and the **17 brand-color palette** (lines ≈42–60) — the authoritative brand-hex set; reuse for matching/reporting.
- `brandbook/tools/compile-tokens.test.mjs` — the semantic-tier no-hex scan idiom (`/--cw-(?!primitive-)/` + `/#[0-9a-fA-F]{6}/`, lines ≈129–141), the `>=20 var(--cw-primitive-)` reference count (≈122–127), and **the existing tokens.css byte-parity test (line 222)** D-04 relies on. Also the model for a `node --test` step in this job.
- `brandbook/tools/check-production.mjs` / `check-candidates.mjs` — the plain-`node`-script-exits-nonzero convention (model for the alternative script form).

### Normalized consumers the manifest must cover (the gate's scan targets — verified zero-hex today)
- `examples/phoenix_host/priv/static/css/app.css` — the **SERVED** file DeckLive renders (47 `var(--cw-`, 0 hex). NOT the unserved `assets/css/app.css` (deleted in 108, D-12).
- `priv/static/crosswake/offline.css` — vendored generator component stylesheet (38 `var(--cw-`, 0 hex).
- `priv/templates/crosswake/offline_ui/offline_page.html.heex.eex` and `offline_root.html.heex.eex` — generator templates (no hex / no Tailwind; link order: `tokens.css` → `app.css` → `offline.css`).
- `examples/phoenix_host/lib/crosswake_example_web/controllers/offline_html/index.html.heex` — the example host's own offline page (normalized in 108).
- `priv/static/crosswake/tokens.css` — distributed token source; parity-guarded by D-04 (covered, not re-implemented).

### Token contract (read for the semantic-only boundary rule the gate enforces)
- `brandbook/BRAND-SPEC.md` §7 (primitive-internal rule) / `brandbook/AUDIT.md` §7, §13 — "primitive tokens are internal, never referenced in component CSS; only semantic tokens cross the boundary" (the basis for the `--cw-primitive-` ban in D-03).
- `guides/tokens.md` — distribution contract (vendor-by-copy + `<link>`, no-hand-edit, byte-parity).

### Deferred offenders the gate must EXCLUDE (do not scan)
- `examples/phoenix_host/priv/static/offline_study.js` — innerHTML hardcoded hex (`#9A4D35`/`#fee2e2`/`#ef4444`).
- `examples/phoenix_host/lib/.../saas_portal/step_up_challenge_live.ex` — dead `bg-[#2563EB]` Tailwind utilities.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `contrast.mjs` `parseHex()` + 17-color palette — the authoritative brand-hex source for matching and human-readable violation messages.
- `compile-tokens.test.mjs` — proven regex idiom for hex/semantic-var scanning AND the byte-parity test (D-04) that already covers `tokens.css`; this is the template for adding the new check as a `node --test` step in the same job.
- `check-production.mjs` — the plain-script-nonzero-exit convention (alternative script form, lighter local runner).

### Established Patterns
- **Required-vs-advisory CI split** — `brand-structural` (required, deterministic) vs `brand-visual` (advisory, `continue-on-error`). The new check belongs in the required, deterministic lane and must stay browser-free.
- **Greppable, single-file consumers** (Phase 108 deliberately left each consumer as one greppable file with semantic refs) — stable, deterministic scan targets for this gate.
- **Generated-file header convention** (`/* GENERATED … do not edit */`) — present on vendored consumers; orthogonal to the gate but confirms these files are stable targets.

### Integration Points / Landmines
- **Same required check name** — the new step must live inside `brand-structural` (not a new job) so branch-protection (harness-blocked) needs no change.
- **Path-trigger gap** — the workflow currently only triggers on `brandbook/**`; without D-01a's broadening, edits to `examples/**` / `priv/**` consumers would **never** run the gate (and the existing tokens.css parity test wouldn't run on direct `tokens.css` edits).
- **`#id`-selector false-positive** — the hex regex must guard against CSS ID selectors (e.g. `#status`); current files are safe but the guard is mandatory.
- **rgba shadow** — `rgba(9,20,26,0.06)` is intentionally token-less and deferred; the `#`-hex-only regex naturally skips it. Don't add rgba scanning.
- **Deferred offenders in `examples/**`** — `offline_study.js` and `step_up_challenge_live.ex` contain hex/Tailwind by design-this-milestone; the curated manifest (D-02) must exclude them or CI breaks on day one.

</code_context>

<specifics>
## Specific Ideas

- User invoked the interactive discuss command but, consistent with the `minimal_decisive` profile, accepted all four researched recommendations wholesale at the single confirmation gate ("Lock all & write CONTEXT").
- The phase codifies an **already-achieved** clean state (every listed consumer verified zero-hex with live `var(--cw-` references at context-gathering time), so the gate should PASS on the current tree the moment it lands — a green baseline, not a remediation.

</specifics>

<deferred>
## Deferred Ideas

- **`offline_study.js`** (innerHTML hardcoded `#9A4D35`/`#fee2e2`/`#ef4444`) and **`step_up_challenge_live.ex`** (dead `bg-[#2563EB]` Tailwind) — a different class of fix (JS/HEEX, not CSS-token normalization). Explicitly excluded from this gate's manifest; fold into a future normalization follow-up, then add to the manifest.
- **Shadow-opacity token** — `box-shadow … rgba(9,20,26,0.06)` has no token; left as-is. If a future token is added, the gate could be extended to enforce it.
- **Glob-based auto-discovery of consumers** — rejected now (deferred offenders + per-file-type rules). Could be revisited once all `examples/**` offenders are normalized and a uniform rule becomes safe.
- **Adding the new check to branch-protection required-status-checks** — the integration point is documented in the workflow header; the actual branch-protection update remains harness-blocked (pre-existing constraint, tracked in STATE/memory). Using the same `brand-structural` check name (D-01) means no new entry is needed.

</deferred>

---

*Phase: 109-Drift-Prevention Gate*
*Context gathered: 2026-06-14*
