# Phase 107: Token Source & Distribution - Context

**Gathered:** 2026-06-13
**Status:** Ready for planning

<domain>
## Phase Boundary

Extend `brandbook/tools/compile-tokens.js` so `tokens.css` carries the **complete** token set — font families and every dimension group, not just colors — all generated from `brandbook/tokens/crosswake.tokens.json`. Then establish and document the **one** mechanism that carries `tokens.css` to both consumers: the in-repo example host and the code-generated offline UI.

This phase produces the **source and the distribution contract only**. It does NOT rewire consumers (`app.css`, offline_ui templates) onto the tokens — that is Phase 108. It does NOT add the CI drift gate — that is Phase 109. The v9.0 brand contract (`crosswake.tokens.json` values, brand book) is frozen; this is wiring, not a redesign.

**Requirements:** TOKN-04 (emit font tokens), TOKN-05 (emit dimension tokens), NORM-03 (one documented distribution mechanism).

</domain>

<decisions>
## Implementation Decisions

### Token emission scope (TOKN-04 / TOKN-05)
- **D-01:** Emit the **full** font + dimension token set already present in `crosswake.tokens.json` — `font.*` (`display`, `body`, `mono`), `text-scale.*`, `display-scale.*`, `line-height.*`, `spacing.*`, `radius.*`, `focus.*`, `tracking.*` — not just the subset today's consumers reference. "Single source of truth" means complete; emitting everything is drift-proof for Phase 108 and matches success criterion #1/#2 (`--cw-font-display/body/mono`, `--cw-text-scale-*`, `--cw-display-scale-*`, `--cw-radius-*`, "and any other dimension values").
- **D-02:** Keep the existing emit convention: dot-path → `--cw-…` (so `font.display → --cw-font-display`, `text-scale.md → --cw-text-scale-md`, `radius.lg → --cw-radius-lg`). This matches the success-criteria property names verbatim — do not invent a different flattening.
- **D-03:** Font families (DTCG `fontFamily` arrays) serialize to a comma-joined CSS font stack with multi-word names quoted (e.g. `"Space Grotesk", ui-sans-serif, system-ui, …`). Dimension tokens emit their raw `$value` string (e.g. `16px`, `-0.02em`). These are **not** alias values — they bypass the `resolveAlias` path used for semantic colors. (The current `props()` helper only handles colors/aliases; a new non-alias emit path is needed.)
- **D-04:** Non-color tokens are emitted in their own clearly-labeled `:root` block(s) appended after the existing semantic-color tier, preserving the file's tier structure (primitive → semantic color → fonts/dimensions). They have no dark-mode variants (none defined in JSON), so they are NOT duplicated into the dark-mode blocks.

### Distribution mechanism (NORM-03) — "vendor by copy"
- **D-05:** The single mechanism is **generate once → copy the generated artifact → link it.** No consumer ever re-declares brand values; a verbatim mechanical copy of a generated file is permitted under NORM-03 (only *hand-edited* duplicate palettes are forbidden).
- **D-06:** **Binding constraint:** `brandbook/` is excluded from the published Hex package (`mix.exs: exclude_patterns: ["brandbook"]`), so an external host running `mix crosswake.gen.offline_ui` cannot read `brandbook/tokens/tokens.css`. Therefore `compile-tokens.js` must also write a **packaged mirror** of `tokens.css` into `priv/` (recommended path: `priv/static/crosswake/tokens.css`), which ships in the package and is reachable via `Application.app_dir(:crosswake, "priv/...")`. The existing `brandbook/tokens/tokens.css` output is **retained unchanged** — `brandbook/index.html` (frozen v9.0) links and download-offers it via relative path. Both files are emitted from one generator run, byte-identical, from the one JSON source.
- **D-07:** The `crosswake.gen.offline_ui` generator copies the packaged `tokens.css` **verbatim** into the host's static assets (e.g. `priv/static/assets/tokens.css` or `…/css/`) using the existing `ensure_file` no-clobber guard (never overwrite a host-customized copy), and the generated `offline_root.html.heex` links it as a **separate `<link rel="stylesheet">` placed before `app.css`** so token custom properties are defined before consuming rules. (Actual template rewrite to consume the tokens is Phase 108; Phase 107 establishes that the link/copy is the contract.)
- **D-08:** The in-repo example host (`examples/phoenix_host`) uses the **identical** mechanism — it vendors the same packaged `priv/static/crosswake/tokens.css` into its own static dir and links it — so there is genuinely ONE mechanism for both consumers, not two. (The host has no esbuild/Tailwind/bundler; it serves static CSS directly via `<link href="/css/app.css">`. Keep it toolchain-free.)
- **D-09:** **Rejected:** inlining tokens.css into a `<style>` block in the generated template (different mechanism than the host → breaks "one mechanism", goes stale at generate-time, harder for Phase 109's grep gate to verify). **Rejected:** serving the dependency's `priv/static` via host-side `Plug.Static` config (requires per-consumer config, more docs, fragile mount dependency).

### Documentation deliverable (NORM-03)
- **D-10:** The "one distribution mechanism" must be **written down** as a doc this phase delivers (placement TBD by planner — candidates: a section in a guide under `guides/`, or a `DISTRIBUTION.md` near the tokens). It states: source = `crosswake.tokens.json`; run `node brandbook/tools/compile-tokens.js`; outputs = `brandbook/tokens/tokens.css` (brand book) + `priv/static/crosswake/tokens.css` (distributable); consumers receive it by verbatim copy + link; never hand-edit a palette. Success criterion #4: a dev verifies the source is current with one Node command, no other toolchain.

### Verifiability (sets up Phase 109)
- **D-11:** Whatever paths are chosen must be **statically checkable** — each consumer ends up with a single known file containing `--cw-` declarations, and the two generated copies must be diffable for parity. Keep this in mind so Phase 109's textual grep gate has stable, deterministic targets. (Phase 109 implements the gate; 107 just must not make it impossible.)

### Claude's Discretion
- Exact packaged path name (`priv/static/crosswake/tokens.css` recommended) and exact host destination filename — planner/researcher may refine, but keep it a single namespaced file per consumer.
- Internal refactor of `compile-tokens.js` (`props()` helper split, second `writeFileSync`, font/dimension serialization helpers) is an implementation detail.
- Documentation file placement.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements & roadmap
- `.planning/REQUIREMENTS.md` — TOKN-04, TOKN-05, NORM-03 (this phase); NORM-01/02/04 (108), PROOF-01 (109) for downstream awareness.
- `.planning/ROADMAP.md` § "Phase 107: Token Source & Distribution" — goal + 4 success criteria.
- `.planning/STATE.md` § Accumulated Context → Decisions — frozen-contract, wiring-only, hermetic-vs-advisory split, no-new-toolchain decisions.

### Token source & tooling (the things this phase changes)
- `brandbook/tools/compile-tokens.js` — the generator to extend (currently emits only `primitive` + semantic color groups; silently drops `font.*` and all dimension groups).
- `brandbook/tokens/crosswake.tokens.json` — single source of truth (W3C DTCG 2025.10). Contains `font`, `text-scale`, `display-scale`, `line-height`, `spacing`, `radius`, `focus`, `tracking` groups already.
- `brandbook/tokens/tokens.css` — current generated output (colors only). Carries `/* GENERATED … do not edit */` header.
- `mix.exs` §`package` (lines ~69-85) — `files:` whitelist + `exclude_patterns: ["brandbook"]`. This is the constraint that forces the `priv/` mirror.

### Consumers (read for the distribution contract; rewired in Phase 108, not here)
- `lib/mix/tasks/crosswake.gen.offline_ui.ex` — the generator task; has the stale hardcoded Tailwind theme (legacy blue `#699cc9` / amber `#e1b982`, ~lines 68-90) and uses `ensure_file` no-clobber.
- `priv/templates/crosswake/offline_ui/offline_root.html.heex.eex` — generated root layout; currently `<link href={~p"/assets/app.css"}>` + Tailwind body classes. Where the new `tokens.css` `<link>` lands.
- `priv/templates/crosswake/offline_ui/offline_page.html.heex.eex` — generated page (Tailwind classes today).
- `examples/phoenix_host/assets/css/app.css` — example host CSS; currently hand-duplicates the primitive palette (un-prefixed `--cw-foam-50` etc.) and hand-declares font stacks (the drift this milestone removes).
- `brandbook/index.html` (lines 14, 664-665) — frozen v9.0 brand book that links/download-offers `tokens/tokens.css` via relative path → reason the brandbook copy must be retained.

### Brand contract (frozen — context only, do not modify)
- `brandbook/BRAND-SPEC.md`, `brandbook/AUDIT.md` — token system spec, source-of-truth rules, NORM-01 origin note.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `compile-tokens.js` `flattenTokens()` — already flattens the full DTCG tree including font/dimension groups; the data is present, just filtered out by the `groups` allow-list and the alias-only `props()` emitter. Extend, don't rewrite.
- `crosswake.gen.offline_ui.ex` `ensure_file/2` — existing no-clobber file writer; reuse for the `tokens.css` copy so host customizations are never overwritten.
- `get_template_path/1` resolves `Application.app_dir(:crosswake, "priv/...")` with a dev-cwd fallback — same resolution pattern the generator should use to locate the packaged `tokens.css`.

### Established Patterns
- Generated-file discipline: tokens.css carries a `/* GENERATED … do not edit */` header; edit JSON + regenerate. The `priv/` mirror must carry the same header.
- Hermetic / textual checks only for the required gate tier (v9.0 `brand-structural`) — keep distribution targets greppable for Phase 109.
- Zero host build toolchain: example host serves static CSS via `<link>`; no esbuild/Tailwind. Distribution must not introduce a bundler.

### Integration Points
- `compile-tokens.js` write step → add second `writeFileSync` to `priv/static/crosswake/tokens.css`.
- `crosswake.gen.offline_ui.ex` run → add `File.cp!`/`ensure_file` of packaged tokens.css into host static + corresponding `<link>` in `offline_root` template.
- Example host static dir → vendored copy of the same packaged file.

</code_context>

<specifics>
## Specific Ideas

- User confirmed the **"vendor by copy"** approach explicitly over inlining and over serving the dependency's `priv/static` — chosen for self-containment, offline-first robustness, single-mechanism consistency, and Phase 109 static-checkability.
- Profile is opinionated/decisive: low/medium-stakes choices (emission scope, naming, serialization, tier layout) were decided directly rather than asked.

</specifics>

<deferred>
## Deferred Ideas

- **Consumer rewiring** (`app.css` + offline_ui templates onto semantic tokens; remove Tailwind classes + stale generator theme) → **Phase 108** (NORM-01, NORM-02, NORM-04). Phase 107 only delivers the source + link contract.
- **Drift-prevention CI gate** (fail on hardcoded hex / missing `var(--cw-` in normalized consumers) → **Phase 109** (PROOF-01).
- **Parity assertion** that `brandbook/tokens/tokens.css` and `priv/static/crosswake/tokens.css` are byte-identical → likely folded into Phase 109's gate; noted here so it isn't lost.

None of these are in-scope for 107. Discussion stayed within phase scope.

</deferred>

---

*Phase: 107-Token Source & Distribution*
*Context gathered: 2026-06-13*
