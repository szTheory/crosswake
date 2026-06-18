# Phase 114: Merge-Blocking CI Gate + Permanent Honesty Guard - Context

**Gathered:** 2026-06-18
**Status:** Ready for planning

<domain>
## Phase Boundary

Turn the honest offline-sync Playwright E2E (built in phases 112–113) into a **real
merge gate** on `main`, and make it **structurally impossible** for a future PR to
silently revert the test to fabrication (injection-based fake sync). Also harden the
test-only proof endpoint so it can never become a production data-leak path.

Pure CI / test-infrastructure / Phoenix-routing work — **no UI surface**. The JTBD is
the maintainer/contributor: they must be able to *trust* the gate as honest proof, and
nobody (including a well-meaning future contributor) can make the proof lie.

Requirements **GATE-01, GUARD-01, GUARD-02** define WHAT. This file locks the HOW,
backed by four parallel research deliverables (see Canonical References).

**In scope:** rename the E2E job + workflow file; register one required status check;
the structural honesty check; the prod-route-absence proof; in-suite route/controller
assertions; the registration runbook/script; a small REQUIREMENTS/ROADMAP wording
amendment + PITFALLS correction.

**Out of scope:** changing the E2E test's actual behavior (locked in 112–113);
migrating to repository rulesets / merge queues; LiveView migration of the reconnect
trigger (already locked out in the milestone); any production feature work.
</domain>

<decisions>
## Implementation Decisions

### CI topology (how many required checks, how guards are arranged)
- **D-01 (Aggregator pattern — "Option C"):** Use **granular sibling jobs + one aggregator job** that is the *single* required status check. This was chosen over both "one job with ordered steps" (slow, coarse signal, shared `_build` risk) and "three separate required checks" (three branch-protection strings = rename-deadlock footgun ×3).
  - Sibling jobs: `guard-01-e2e-honesty` (~2s Node, no browser, no Elixir), `guard-02-prod-route-absence` (`MIX_ENV=prod`, isolated runner), `e2e-proof` (`MIX_ENV=test` compile + Playwright).
  - Aggregator job **`merge-blocking-offline-sync-e2e`**: `if: always()`, `needs: [guard-01-e2e-honesty, guard-02-prod-route-absence, e2e-proof]`, rolls up via `re-actors/alls-green` with `jobs: ${{ toJSON(needs) }}`. **This aggregator name is the one and only required check** registered on `main`.
  - This satisfies GATE-01's singular wording verbatim (the named job IS the required check), GUARD-01's "registered alongside the E2E job" (sibling `needs:`), and isolates the `MIX_ENV=test`/`MIX_ENV=prod` compiles onto separate parallel runners.
  - **`_build` isolation is mandatory:** never share `_build` or a cache key across `MIX_ENV`. Use env-scoped cache keys (`build-test-…`, `build-prod-…`). Mix already writes `_build/<env>/`, so the only contamination vector is a shared cache key — close it.

### Advisory-vs-required lane split (the GATE-01 conflict)
- **D-02 (Honor intent, NOT the literal text — keep D-06):** Advisory (non-merge-blocking) lanes are made non-blocking by **omission from the branch-protection `checks[]` array** (and trigger-scoping to `schedule`/`workflow_dispatch` where they shouldn't run per-PR), **never** via `continue-on-error: true`. A soft-failed `continue-on-error` job reports **green**, can never be promoted to a real gate, and (on a publishing lib) lets downstream `needs:` jobs run on failure — exactly the anti-honesty failure mode this milestone exists to kill. Confirmed by Oban/Phoenix/Ecto (none use `continue-on-error` for advisory signal) and by the repo's own D-06 (`phase96-proof-advisory.yml`).
  - Advisory marker = `advisory-`-prefixed job `name:` + a `::notice` annotation + a `$GITHUB_STEP_SUMMARY` promotion-path note. Failures surface as **honest red**.
- **D-03 (Requirement amendment — planner must do this):** GATE-01's final sentence ("Every non-required CI lane keeps `continue-on-error: true` …") contradicts D-02 and is a copy-paste artifact from the older `brand-visual` pattern. The plan must **amend REQUIREMENTS.md line 27 and ROADMAP.md line 116** to the omission/trigger-scoping wording, add a D-06 cross-reference, and **correct `.planning/research/PITFALLS.md`** (lines ~117/284/306/322/337) which currently prescribe the rejected `continue-on-error` pattern. (Exact replacement wording is in the advisory-lane research deliverable.)

### GUARD-01 — structural honesty check
- **D-04 (Zero-new-dependency TypeScript AST):** Implement `script/check-e2e-honesty.mjs` as a Node ESM script that parses `examples/phoenix_host/e2e/offline_sync.spec.ts` with the TypeScript compiler API (`import ts from 'typescript'`). `typescript` already resolves transitively via `@playwright/test` → **zero new deps**; pin `typescript` explicitly in `devDependencies` as cheap insurance against a future Playwright major dropping it. AST (not regex) is required because two of the three anti-patterns are scope/ordering-sensitive.
- **D-05 (Ban the cheat shapes unconditionally — no allowlist):** Do **NOT** key the guard on the `// OBSERVATION_ONLY` comment (trivially bypassable). Instead ban the specific fabrication shapes, which the honest test never contains:
  1. string literal `crosswake_offline_mutations` appears anywhere → fail.
  2. a network call (`fetch` / `XMLHttpRequest` / `*.sendBeacon`) **inside a `page.evaluate` callback** → fail. (IndexedDB reads and `window.dispatchEvent('online')` in the same callback are untouched — that's why the legitimate OBSERVATION_ONLY blocks pass naturally.)
  3. `crypto.randomUUID` (or a uuid import) appears anywhere → fail (the honest test *reads* `client_mutation_id` out of IndexedDB; minting one is the tell).
  - Also `exit 1` if the spec file is missing (anti-rename/delete evasion). Failure message must teach the WHY (link GUARD-01 + the 112–113 honest rewrite). Document that the guard is necessary-not-sufficient; the test body's exactly-one-row / duplicate-idempotency assertions are the behavioral backstop.

### GATE-01 — required-check registration (harness-blocked write)
- **D-06 (GET-then-replace script + green-first preflight):** Ship a committed `script/register-e2e-gate.sh` (`set -euo pipefail`, `DRY_RUN=1` support, idempotent) that **reads** the live `required_status_checks`, merges in `merge-blocking-offline-sync-e2e` (pinned to `app_id: 15368`), `unique_by(.context)`, and PATCHes back — preserving the two existing required checks (`merge-blocking rulestead proof (hermetic)`, `brand-structural`) and `strict: true`. **Never hardcode the checks array** (a hardcode silently drops checks added later). The script **refuses to register until the new check has gone green on `main` at least once** (`gh api .../check-runs` success probe → `exit 2`), preventing the "Expected — Waiting for status" repo-wide deadlock. The exact `gh api … PATCH` one-liner is mirrored as a comment block in the workflow. Branch-protection writes are harness-blocked → the maintainer runs the script out-of-band. **Correct ordering: merge the rename → let it go green on `main` → run the script.**

### GUARD-02 — prod-route safety
- **D-07 (Executable prod-absence proof, generalized):** The `guard-02-prod-route-absence` job (`MIX_ENV=prod`) does `rm -rf _build/prod` (force a clean prod compile — never inspect a `:test`-compiled router beam), then asserts `! grep -qE '/_e2e(/|$)'` over `mix phx.routes CrosswakeExample.Router`. Generalize to the whole **`/_e2e` reserved prefix** so future test-only routes inherit the guard. `mix phx.routes` compiles the router but does **not** boot the supervision tree → hermetic, no `SECRET_KEY_BASE`/DB needed. **Footgun:** use `! grep -q` (assert absence), not `grep -v` (whose exit code under `pipefail` is misleading).
- **D-08 (In-suite assertions):** Add `test/crosswake_example/router_test.exs` — a plain `ExUnit.Case` positive assertion via `Phoenix.Router.routes/1` that the `/_e2e/sync-state/:client_mutation_id` route is present under `:test` with correct `verb`/`plug`/`plug_opts`. Add a controller unit test proving `count` is scoped to `client_mutation_id` (insert ≥2 distinct rows; assert `count == 1`) — guards the bare-`Repo.aggregate(:count)`-counts-whole-table footgun already flagged in the controller. Do **not** reference `/_e2e` via `~p` verified routes (conditionally-compiled routes break `~p` verification).
- **D-09 (Keep `Mix.env()` compile-time gating; no runtime guard):** Keep `if Mix.env() in [:test, :e2e]` in the router. Do **not** switch to `Application.compile_env` (would force per-env config files for one boolean; this app has a single `config.exs`). `Mix.env()` here is compile-time-safe — the branch is erased from prod beams; the "Mix unavailable in releases" rule only bites *runtime* calls. Do **not** add a belt-and-suspenders runtime refusal guard — compile-out ("the code doesn't exist") is strictly stronger than "exists but guarded," and a redundant guard wrongly implies the route ships to prod. Add a one-line comment above the `if` documenting `/_e2e` as the reserved test-harness namespace.

### Workflow file rename
- **D-10 (Rename now):** `git mv .github/workflows/phase90-proof.yml .github/workflows/offline-sync-e2e-gate.yml` in this phase (the file + job + check are already being touched/re-registered — coupling the rename is free). Set a stable top-level `name: Offline-Sync E2E Gate` and a one-line archaeology comment (`# Renamed from phase90-proof.yml (2026-06). Permanent merge gate — purpose-named, not phase-scoped.`). Renaming the **file** does NOT change the required-check string (that's job-name-keyed) — the registration script targets the job/check name, not the path. Update the ~13 `.planning/*.md` references to the old filename in the same commit. (The other `phaseNN-proof.yml` files are genuine one-off phase proofs and stay as-is; this one is renamed because it's a *standing* gate.)

### Claude's Discretion
- Exact AST node-walking implementation details of `check-e2e-honesty.mjs`; precise CI step names and `$GITHUB_STEP_SUMMARY` copy; whether the in-suite controller test uses an existing `DataCase`/`ConnCase` or a minimal sandboxed-Repo call (none exist yet — planner picks the lowest-footprint option); exact Elixir/OTP/Playwright action versions (mirror the current workflow); cache key spelling.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase requirements & roadmap
- `.planning/REQUIREMENTS.md` §GATE-01 (line 27), §GUARD-01 (line 34), §GUARD-02 (line 35) — the locked requirements. NOTE: GATE-01's `continue-on-error` clause is amended by D-02/D-03.
- `.planning/ROADMAP.md` — Phase 114 section (Success Criteria 1–4; mirror of the GATE-01 wording at ~line 116 also needs the D-03 amendment).

### Research deliverables (this discussion — the decisive rationale behind D-01…D-10)
- `.planning/phases/114-merge-blocking-ci-gate-permanent-honesty-guard/114-RESEARCH-SYNTHESIS.md` — consolidated four-area research (advisory lane, topology, GUARD-02 idiom, file rename) + the requirement-level GATE-01/GUARD-01/GUARD-02 research. **Written alongside this CONTEXT.md; the planner should read it for exact YAML/script/code sketches, the `gh api` PATCH command, the REQUIREMENTS wording amendment, and source URLs.**

### Code under change
- `.github/workflows/phase90-proof.yml` → rename to `.github/workflows/offline-sync-e2e-gate.yml`; job `e2e-offline-sync` → restructured into sibling jobs + aggregator `merge-blocking-offline-sync-e2e`.
- `.github/workflows/phase96-proof-advisory.yml` — the canonical D-06 advisory pattern to mirror (trigger-scoping + `::notice`, no `continue-on-error`).
- `examples/phoenix_host/e2e/offline_sync.spec.ts` — the spec the honesty check scans (note the legitimate `// OBSERVATION_ONLY` `page.evaluate` blocks that must keep passing).
- `examples/phoenix_host/lib/crosswake_example/router.ex` — the `if Mix.env() in [:test, :e2e]` `/_e2e` scope (~line 378).
- `examples/phoenix_host/lib/crosswake_example/e2e/sync_state_controller.ex` — docstring already cites GUARD-02; `count`-scoping comment is what D-08's controller test protects.
- `examples/phoenix_host/config/config.exs` — single config file (no per-env split — the reason D-09 keeps `Mix.env()`).
- `examples/phoenix_host/mix.exs` / `package.json` — toolchain (`elixirc_paths(:test)`; `@playwright/test` provides `typescript` transitively).
- `script/verify_*.sh` — house style for the new `register-e2e-gate.sh` (and any `verify_e2e_honesty.sh` wrapper).

### Project ethos (why honesty is brand-load-bearing)
- `.planning/research/PITFALLS.md` — needs the D-03 correction (currently prescribes `continue-on-error`).
- `prompts/crosswake-elixir-oss-dna.md`, `.planning/research/SUMMARY.md` — the honest-proof OSS positioning the whole phase serves.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `phase96-proof-advisory.yml`: the working advisory-lane pattern (trigger-scoping + `::notice`, no `continue-on-error`) to mirror for D-02.
- `phase75-closeout-gate.yml`: house pattern for `merge-blocking-*` job naming + explicit `name:`.
- `script/verify_*.sh`: `set -euo pipefail` / `DRY_RUN` shell-script house style for `register-e2e-gate.sh`.
- `@playwright/test` (in `examples/phoenix_host`): ships `typescript` transitively → the honesty check's AST parser costs no new dep.

### Established Patterns
- Classic branch protection on `main` (rulesets empty): `strict: true`, `enforce_admins: true`, required checks `merge-blocking rulestead proof (hermetic)` + `brand-structural`, both `app_id: 15368`. Registration is a GET-then-replace PATCH of `required_status_checks`.
- `if Mix.env() in [:test, :e2e]` route gating is already in place and idiomatic; the controller docstring already states the test-only purpose.

### Integration Points
- The aggregator job is the single new entry in branch protection's `checks[]` (added by `register-e2e-gate.sh`, run out-of-band by the maintainer).
- The three sibling jobs connect to the aggregator via `needs:`; adding a future GUARD-03 = one job + one `needs:` entry, zero branch-protection edits.
</code_context>

<specifics>
## Specific Ideas

- The single most important footgun across the whole phase: **renaming a required check (job name) before it has reported green deadlocks every PR** on "Expected — Waiting for status." The registration script's green-first preflight + the aggregator pattern (one stable required name) exist to neutralize it.
- Honesty guard must distinguish a `fetch(` *inside* `page.evaluate` (fabrication) from a `page.evaluate` that reads IndexedDB / dispatches `online` (legitimate) — this is why AST, not regex, and why no `OBSERVATION_ONLY` allowlist.
- Prod-absence proof must run from a clean `MIX_ENV=prod` `_build` and use `! grep -q`, not `grep -v`.
</specifics>

<deferred>
## Deferred Ideas

- Migrating from classic branch protection to **repository rulesets / required-workflows / merge queue** — newer GitHub primitives; out of scope this phase (repo is on classic protection and GATE-01 maps cleanly to it). Note that required-*workflows* rulesets ARE path-keyed, so a future migration would make the file rename (D-10) a breaking reference — revisit then.
- Retiring old `phase90-proof.yml` run history from the Actions sidebar (`gh run delete …`) — cosmetic cleanup, optional, does not affect gating.
- Generalizing `register-e2e-gate.sh` into a reusable multi-check registration helper for the other `phaseNN` gates — future DX nicety, not needed now.

*Discussion stayed within phase scope; no new capabilities introduced.*
</deferred>

---

*Phase: 114-merge-blocking-ci-gate-permanent-honesty-guard*
*Context gathered: 2026-06-18*
