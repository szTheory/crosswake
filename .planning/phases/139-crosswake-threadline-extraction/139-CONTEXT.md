# Phase 139: crosswake_threadline Extraction - Context

**Gathered:** 2026-07-02
**Status:** Ready for planning
**Source:** Research-then-recommend pass (4 parallel expert-lens subagents: packaging/optional-deps, telemetry-resilience/SRE, generator-DX/coherence, CLI-UX/brand) + design spine D-7. Synthesized + user-adjudicated scope.

<domain>
## Phase Boundary

Extract threadline — the audit / thread-correlation OBSERVER — into a standalone `packages/crosswake_threadline/` Hex package. Threadline observes core/companion events purely by event-NAME via `:telemetry.attach_many` (zero compile deps on sibling companions), ships an `Audit.Ledger` struct + a `mix crosswake.gen.audit` host-owned scaffolding generator + a `mix crosswake.threadline` terminal timeline tool. Module names are PRESERVED (`Crosswake.Threadline.*`, `Crosswake.Audit.Ledger`, `Crosswake.Plug.Threadline`, `Crosswake.Live.Threadline`) so the extraction is NON-BREAKING and the adopter touch-points stay stable.

This is the FINAL companion (extracted last: core telemetry had to decouple first, Phase 136). It is a near-structural repeat of Phase 137 (sigra) and Phase 138 (chimeway), both executed green in-tree.

**Scope decision (user-adjudicated 2026-07-02):** *Extraction + fold in the free DX wins.* The disciplined, behavior-preserving move + all correctness items, PLUS the cheap/low-risk developer-facing string & output changes (since those files are already being moved). Igniter adoption and the audit hash-chain integrity redesign are DEFERRED.
</domain>

<decisions>
## Implementation Decisions

### A. Package deps & boundary (all DO-NOW — required for correct non-breaking move)
- **Optional Phoenix surface.** `{:plug, "~> 1.0", optional: true}` and `{:phoenix_live_view, "~> 1.1", optional: true}`. Wrap the ENTIRE `defmodule` of `Crosswake.Plug.Threadline` in `if Code.ensure_loaded?(Plug.Conn) do ... end` and `Crosswake.Live.Threadline` in `if Code.ensure_loaded?(Phoenix.LiveView) do ... end` (PromEx precedent). Safe because neither module uses a `use` macro (the `use`-inside-`if` footgun, elixir#8970, does not apply). Add a `@moduledoc` note: after adding the optional dep, run `mix deps.compile --force crosswake_threadline` (stale-BEAM caveat).
- `:phoenix` is NOT a direct dep. `:telemetry` + `:nimble_options` (non-optional — used at `@schema` module-eval in the Plug) are direct deps. `:ex_doc` dev-only.
- **Ecto-free library.** `Crosswake.Audit.Ledger` stays a plain `defstruct` + HMAC helper. Persistence is host-owned: `mix crosswake.gen.audit` generates the Ecto schema + migration INTO the host. The library never depends on `:ecto`. (This is the `mix phx.gen.*` seam — correct, keep it.)
- **`files:` MUST include `"priv"`** — ships `priv/templates/crosswake/audit/*.eex`. Omitting it yields a valid tarball that silently breaks the generator at runtime. Verify with `mix hex.build --unpack`.
- **`app_dir` fix (correctness blocker):** `lib/mix/tasks/crosswake.gen.audit.ex:23-24` `Application.app_dir(:crosswake, ...)` → `Application.app_dir(:crosswake_threadline, ...)`. Keep the existing `File.exists?` cwd fallback.
- **Env-conditional crosswake dep** matching siblings: `CROSSWAKE_RELEASE=1 → {:crosswake, "~> 0.1"}` else `{:crosswake, path: "../.."}`.

### B. Audit-handler resilience (DO-NOW: template hardening)
- The generated telemetry handler MUST `try/rescue` → catch, `Logger.error` (handler remains attached), **never reraise** (`:telemetry` auto-detaches a raising handler → silent audit blackout; confirmed in `telemetry.erl` `do_execute`). Add `on_conflict: :nothing` + `conflict_target: :idempotency_key` so replays are idempotent.
- **Keep the write SYNCHRONOUS inside `Ecto.Multi`** — the audit row commits atomically with the action it describes. No async/GenServer/Oban (would break atomicity + add deps). Async batching is a deliberate later opt-in, not this phase.
- **Hash-chain stays advisory.** `row_hash`/`prev_hash` are an advisory fingerprint, not tamper-evidence (caller-supplied prev, hashes only 3 fields, forks under concurrency). Add a `@moduledoc` note in `ledger.ex.eex` marking it advisory. The `idempotency_key` UNIQUE index is the real integrity guarantee. DEFER real integrity (Postgres trigger / Carbonite-style) to a dedicated hardening phase.

### C. Generator + PII-baseline coherence
- **Keep hand-rolled EEx generator; DEFER Igniter.** One-shot host-owned scaffold ≠ Igniter's AST-patch idempotency use-case; Igniter would drag ~6 transitive deps for zero payoff and its adoption is ~Ash-only.
- **PII baseline decoupling — CORRECTED from the initial "absorb 10→21" framing (this is the key coherence fix):**
  - CUT the static compile-time call `Crosswake.Threadline.Telemetry.forbidden_metadata_keys()` in core `lib/crosswake/telemetry.ex:~245` (`attach_default_logger/1`).
  - Do NOT wholesale-absorb threadline's ~20 keys into core. Per D-5, the core baseline is a CURATED UNIVERSAL FLOOR of "the most dangerous keys (auth tokens, identity fields)" that must be scrubbed with zero companions present — NOT threadline's OAuth/passkey-ceremony minutiae (`pkce_verifier`, `raw_return_to`, `provider_payload`, etc., which are sigra's domain by provenance and are aggregated at runtime when sigra is registered). Planner categorizes each of core's current 10 + threadline's 20 keys as universal-floor (→ core baseline, a small justified delta) vs companion-domain (→ stays companion-local). Threadline still scrubs its own keys at emission (`Threadline.Telemetry.metadata/1`) — unchanged, no regression.
  - **Anti-drift test (DO-NOW):** assert `core_baseline ⊆ union(registered-companion forbidden_metadata_keys)` — any core key without companion provenance fails loudly. Do NOT assert the inverse (companion-domain keys legitimately exceed the floor).
  - BEFORE editing, grep for any existing test asserting the baseline count (currently 10) and update it in the same task.
- **SITE 1 (support_matrix compile-coupling):** freeze `@audit_ledger_support_truth` (calls `ThreadlineTelemetry.event_names/metadata_keys/forbidden_metadata_keys` at compile time, `support_matrix.ex:16,285-300`) as static literals. Direct analog: chimeway's `@notification_support_truth_static` at `support_matrix.ex:263`.

### D. CLI/brand DX wins (DO-NOW per user scope choice — cheap, files already moving)
- **`NO_COLOR` env detection + ASCII tree fallback** in `mix crosswake.threadline` (no-color.org standard): when `NO_COLOR` set, substitute `+--`/`\--`/`|   ` for the Unicode box glyphs (also aids screen-readers). (An explicit `--ascii` flag is DEFERRED.)
- **Empty-result guard:** when durable + zero events matched, print `No events found for thread_id=…` instead of silent output.
- **Microcopy rewrites** (string-only, brand-voice per `brandbook/BRAND-SPEC.md`): ephemeral posture line (add the config-keys guidance), durable posture line (`Posture: Durable — querying audit ledger`), generator "Next steps" (verb-first, concrete `record_in_multi` fields, closing `mix crosswake.threadline` CTA, note `mix ecto.create` if needed, `reused`→`skipping`), and the HMAC-secret `ArgumentError` (name both resolution paths).
- Keep each DX change in its OWN commit(s), separate from the mechanical move, so the "pure move" remains reviewable and the clean-room proof stays meaningful.

### E. Publish (mirrors 137/138; DEFERRED irreversible publish)
- Register `crosswake_threadline` as an INDEPENDENT `elixir` release-please component (NOT in `linked-versions`), one-shot release-as 0.1.0; example-host path dep + compat-matrix row; `publish-hex-threadline` + `clean-room-proof-threadline` CI jobs.
- **Clean-room must be vacuity-safe:** installs NO `crosswake_sigra`, NO `crosswake_chimeway`. ExUnit proof asserts a positive canary (`Telemetry.event_names/0 == 3`, `Plug.Threadline.init([])` OK, `Audit.Ledger.actor_ref/2` → 64-char hex) AND `refute :crosswake_sigra in deps` + `refute :crosswake_chimeway in deps`. Threadline is NOT a Companion behaviour impl (no `enabled?/0`) → clean-room script must suppress the companion-behaviour assertions for this package.
- **The irreversible `mix hex.publish` is HUMAN-GATED and DEFERRED to the batched family publish** (at/after Phase 140), must fire only AFTER sigra + chimeway are live. Wave 4 = `autonomous: false`, mirroring `138-04-PLAN.md`.

### Claude's Discretion
- Exact wave/task decomposition (target: mirror 138's 4 waves), exact key categorization for the baseline floor, precise CI YAML, and file-move ordering — planner's call, grounded in RESEARCH/PATTERNS.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Design + research
- `.planning/research/v17-companion-family-completion.md` — D-5 (core baseline PII floor + runtime aggregation), D-7 (threadline observer, try/rescue, app_dir fix), D-8 (independent versioning), D-9 (sequential publish, vacuity-safe clean-room).
- `.planning/phases/139-crosswake-threadline-extraction/139-RESEARCH.md` — grounded source inventory, two core coupling sites w/ line numbers, validation architecture, security domain.
- `.planning/phases/139-crosswake-threadline-extraction/139-PATTERNS.md` — every new file → closest 137/138 analog; 2 no-clean-analog items (the coupling sites).
- `.planning/phases/139-crosswake-threadline-extraction/139-VALIDATION.md` — Nyquist per-task verification map (reconcile final task IDs).

### The extraction template (executed green in-tree)
- `.planning/phases/138-crosswake-chimeway-extraction/138-01..04-PLAN.md` — mirror the 4-wave structure incl. the wave-4 human publish gate.
- `packages/crosswake_chimeway/mix.exs`, `packages/crosswake_sigra/mix.exs` — copy-from package templates.
- `release-please-config.json`, `.release-please-manifest.json`, `.github/workflows/release-please.yml` — chimeway/sigra blocks are the s/chimeway/threadline/ analogs.

### Brand voice (for the DX microcopy)
- `brandbook/BRAND-SPEC.md` — CANONICAL voice/tone (prefer over the older `prompts/crosswake-brand-book.md`).
</canonical_refs>

<specifics>
## Specific Ideas

- Threadline source (all moves, namespace preserved): `lib/crosswake/threadline/*.ex` (id, telemetry), `lib/crosswake/audit/ledger.ex`, `lib/crosswake/plug/threadline.ex`, `lib/crosswake/live/threadline.ex`, `lib/mix/tasks/crosswake.gen.audit.ex`, `lib/mix/tasks/crosswake.threadline.ex`, `priv/templates/crosswake/audit/*.eex`.
- Zero-sibling-dep invariant: only "Sigra" hits allowed in threadline source are the two PROVENANCE COMMENT lines in `telemetry.ex:38-40`. Wave-1 commit gate: `grep -rn "Crosswake\.Companions\.Sigra\|crosswake_sigra\|Crosswake\.Companions\.Chimeway\|crosswake_chimeway" packages/crosswake_threadline/lib/` empty. Unlike chimeway, NO `only: :test` sibling allowlist needed.
- Core `mix.exs` test-only dep: `phase133_telemetry_contract_test.exs` uses `Crosswake.Plug.Threadline` as a TELEM-04 Side-A trigger → add `{:crosswake_threadline, path: "packages/crosswake_threadline", only: :test}` to core `mix.exs` so it compiles post-extraction.
</specifics>

<deferred>
## Deferred Ideas

- **Igniter adoption** for `mix crosswake.gen.audit` — revisit only if a multi-file re-runnable install use-case emerges.
- **Audit hash-chain real integrity** (Postgres trigger / Carbonite-style, or serialized writer with `SELECT … FOR UPDATE`) — dedicated hardening phase; 139 only marks it advisory.
- **Async/batched audit write** (GenServer buffer / Oban durable enqueue) — opt-in host config in a later phase; 139 keeps synchronous-in-Multi.
- **`--ascii` explicit flag** + ANSI color for the timeline + line-wrapping — a dedicated CLI-polish pass (`NO_COLOR` env covers ~95% now).
</deferred>

---

*Phase: 139-crosswake-threadline-extraction*
*Context gathered: 2026-07-02 via research-then-recommend (4 expert lenses) + user scope adjudication*
