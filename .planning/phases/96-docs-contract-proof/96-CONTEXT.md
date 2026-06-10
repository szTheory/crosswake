# Phase 96: Docs-Contract + Proof - Context

**Gathered:** 2026-06-10
**Status:** Ready for planning

<domain>
## Phase Boundary

This phase makes `guides/threadline.md` the honest, mechanically-verified public contract for the Threadline feature (DOCS-01/02/03), and ships two CI proof lanes: a hermetic merge-blocking lane (PROOF-01) and an advisory example-host ledger lane (PROOF-02). No new runtime features — the phase verifies and documents what Phases 91–95 shipped.

Key starting fact: `guides/threadline.md` already exists (70 lines, written as Phase 95's IN-03 fix). It covers posture, the mix task, and doctor findings, but lacks the anti-scope section, honest-limitations section, the 15-field ledger table, the forbidden-key list, telemetry module names, and the "terminal critical events only" scope.

</domain>

<decisions>
## Implementation Decisions

All four areas were researched in two rounds (repo-convention pass, then ecosystem/lessons-learned pass per user request). Decisions below are locked; "Planner guidance" bullets are binding implementation constraints discovered during research.

### Docs-Parity Mechanism (DOCS-01)
- **D-01:** Hybrid assertion strategy in a new `test/crosswake/proof/phase96_threadline_docs_contract_test.exs`:
  - **Code-derived** wherever a public accessor exists: loop `Crosswake.Threadline.Telemetry.metadata_keys/0`, `forbidden_metadata_keys/0`, and event names, asserting each appears in the guide (`assert guide =~ Atom.to_string(key)`).
  - **Header name** derived via `Crosswake.Plug.Threadline.init([])[:header_name]` (NimbleOptions-validated default) — not a hardcoded string, and no new public function added for it.
  - **15 ledger columns hardcoded** in the test (the `defstruct` has no public accessor and LEDG-02 columns are a frozen contract). Add a co-location comment cross-referencing Doctor's `@canonical_ledger_columns`; if a third consumer ever needs the list, extract `canonical_columns/0` then — not now (avoid new public API on the shipped lib).
- **Planner guidance:** Loop each key individually so a rename produces a *named* failure, not a vacuous pass. Assert prose-form strings (`"thread_id"`), not atom syntax (`:thread_id`). Every assertion carries a custom failure message naming the missing contract element and which file to update (precedent: `test/crosswake/support_matrix/support_matrix_test.exs:267`).

### Hermetic Merge-Blocking Lane (PROOF-01)
- **D-02:** New `.github/workflows/phase96-proof.yml` — `name: Phase 96 Proof - Threadline Docs Contract`; job id `merge-blocking-threadline-docs-contract-proof` (lowercase-hyphens; branch protection records the job id, not the display name). Trigger: `push: branches: ['**']` + `pull_request` (phase90 shape). `ubuntu-latest`, `permissions: contents: read`, actions pinned to commit SHAs (phase73/75 pattern), `timeout-minutes` set, `mix compile --warnings-as-errors` as a separate step before `mix test` (repo convention — do NOT fold into `mix test --warnings-as-errors`).
- **D-03:** Test selection by **explicit file list** (matches all 20+ existing proof workflows). Tag-based `--only` is not viable: phase52/64/65 proof tests assert proof modules carry no `@moduletag` (self-enforcing hermetic lane guard). Baseline file set:
  - `test/crosswake/proof/phase91_threadline_contract_closeout_test.exs`
  - `test/crosswake/proof/phase92_server_propagation_closeout_test.exs`
  - `test/crosswake/proof/phase96_threadline_docs_contract_test.exs` (new)
  - `test/crosswake/plug/threadline_test.exs`
  - `test/crosswake/live/threadline_test.exs`
  - `test/crosswake/threadline/telemetry_test.exs`
  - `test/crosswake/threadline/id_test.exs`
  - `test/crosswake/doctor/doctor_threadline_test.exs`
  - `test/mix/tasks/crosswake.gen.audit_test.exs`
- **Planner guidance:** `mix test <nonexistent path>` fails loudly (verified) — file-list rot fails closed. Add a comment block above the `mix test` step mapping each file to the contract it proves. The new proof test must land in the same commit as the workflow. Include `support_matrix_test.exs` only if it runs clean in the lane (it holds the `docs_anchor == "guides/threadline.md"` assertions); if parts of it hit pre-existing failures, scope by `path.exs:LINE`. The phase96 proof test should include the same untagged-module self-guard as phase52. Full suite is off the table (~28 pre-existing failures — curated lane is the documented pragmatic bridge per OSS DNA "one deterministic core lane merge-blocking").

### Advisory Example-Host Lane (PROOF-02)
- **D-04:** Commit `mix crosswake.gen.audit` output (schema `CrosswakeExample.Audit.Ledger` + timestamped migration) into `examples/phoenix_host` — consistent with the three already-committed Sigra audit schema+migration pairs there; the committed schema doubles as the canonical durable-posture adopter example.
- **D-05:** Proof is an **ExUnit test in the example host** (`async: false` — ecto_sqlite3 has no sandbox async support): seed via `Ecto.Multi` + `record_in_multi` + `Repo.transaction`, then `Mix.Task.reenable("crosswake.threadline")` + `Mix.Task.run(...)` with **`Mix.Shell.Process`** (not bare `capture_io` — subtask stdout bleeds through), asserting the shell mailbox for `"Posture: Durable"` and the seeded event. Cleanup via `Repo.delete_all` in `setup` (before, not `on_exit` — SQLite serialized-write race). Config via `Application.put_env(:crosswake, :audit_repo/:audit_ledger)` + `on_exit` restore (matches main-lib threadline task tests).
- **D-06:** Advisory mechanics: **NOT `continue-on-error: true`** (known GitHub UX trap — failed jobs render green on PRs; community discussion #15452). Use the repo's own `phase23-proof.yml` pattern: separate `phase96-proof-advisory.yml` whose job is gated `if: github.event_name == 'schedule' || github.event_name == 'workflow_dispatch'`, weekly Monday cron (`0 6 * * 1`) so the lane can't rot invisibly, and a final `::notice title=Advisory lane::` annotation step.
- **Planner guidance:** Seeded events MUST set `tier` explicitly (`"native"`/`"bridge"`/`"phoenix"`) or they land in the "Other (unrecognized tier)" bucket and output assertions miss. `Mix.Task.reenable` before *every* `Mix.Task.run` (Mix once-semantics make second runs silent `:noop` → vacuous pass). Example host has a single `config/config.exs`, no test-env split — don't assume one.

### Guide Structure & Voice (DOCS-01/02/03)
- **D-07:** Restructure `guides/threadline.md` contract-first (matches `guides/companions.md` "Core Contract First" house style and brand-book §14 doc template). H2 outline, in order:
  1. What Threadline Is
  2. What Threadline Is NOT
  3. The Propagation Contract
  4. Posture: Ephemeral vs Durable
  5. The Audit Ledger Schema (LEDG-02)
  6. PII-Free by Construction
  7. Operations
  8. Doctor Findings (keep existing Code|Severity|Meaning table)
  9. Honest Limitations
  10. Deferred Non-Claims
- **D-08:** Contract content is **verbatim, not pointers** (pointers can't be contains-exact checked): 15 ledger fields as a `| field | type | meaning |` table (including `provenance` as `Ecto.Enum` `:device_claimed | :backend_accepted`); forbidden metadata keys listed verbatim. Note there are TWO forbidden lists — the telemetry-side denylist (`Crosswake.Threadline.Telemetry.forbidden_metadata_keys/0`) and the ledger-side 8-key PII guard in the generated template (`email`, `phone`, `ip_address`, `ssn`, `name`, `first_name`, `last_name`, `address`) — the guide must present both without conflating them.
- **D-09:** Anti-scope section is a real H2 section (DOCS-02 requires a section, not a sentence), framed "non-goals by design, not deferred features," with item language anchored to the REQUIREMENTS.md Out of Scope table (that's what the contains-exact test asserts against): not APM, not OTel replacement, not a logging framework (sets metadata, never emits log lines), not a plugin/event bus, no PII, no session replay.
- **D-10:** Locked microcopy (brand-book "operational truth over hype"; these exact phrasings feed the contains-exact tests):
  - Hash chain: "`row_hash` and `prev_hash` detect gaps and overwrites after the fact. Hash-chaining does not prevent tampering — it reports it." Never the adjective "secure."
  - WebView gap framed as deliberate scoping truth, not a bug; mention the `_crosswake_thread_id` connect-param path for LiveView mounts.
  - OTel coexistence: standard `:telemetry` events, zero OTel dependency, host may attach an OTel handler to bridge spans.
  - Terminal-critical scope: "terminal critical events — auth handoffs, commerce receipts, step-up resolutions, route denials — not high-frequency request logging."
  - Vocabulary: `host-owned` (never Crosswake-owned ledger), `actor_ref` (never "user id"), `append-only`, `device-claimed`/`backend-accepted`. Banned: "magic," "seamless," "universal," "automatically" for the `record_in_multi` path.
  - Keep the existing opening sentence verbatim (it's an anchor): "Threadline is Crosswake's … PII-free correlation thread across the three tiers …"
  - No "Note:"/"Tip:" callout boxes — house style uses plain sections.

### Claude's Discretion
- Exact table column phrasing in the ledger schema table, section prose length, and ordering of files within the workflow's `mix test` list.
- Whether `test/crosswake/guides/` vs `test/crosswake/proof/` hosts the docs-contract test — research recommends `test/crosswake/proof/phase96_threadline_docs_contract_test.exs` as the anchor; planner may also keep a thin guides-style test if it reduces duplication.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Feature definition
- `.planning/threads/threadline-audit.md` — Canonical Threadline definition: header, ledger schema, text-only operator UI.
- `.planning/REQUIREMENTS.md` — DOCS-01/02/03, PROOF-01/02 texts AND the Out of Scope table (anti-scope section language must anchor to it).

### Voice / docs style
- `prompts/crosswake-brand-book.md` §6 (voice: operational truth over hype) and §14 (doc page template) — governs guide tone and structure.
- `prompts/crosswake-elixir-oss-dna.md` — "docs-contract checks prevent drift," "non-goals are written down," "one deterministic core lane merge-blocking."
- `guides/companions.md` — house-style precedent: "Core Contract First" ordering, doctor-findings table format, "What This Guide Does Not Claim."

### Code surfaces under contract
- `guides/threadline.md` — current 70-line guide being restructured (opening sentence is a keep-verbatim anchor).
- `lib/crosswake/threadline/telemetry.ex` — public `metadata_keys/0`, `forbidden_metadata_keys/0` (code-derived assertions).
- `lib/crosswake/plug/threadline.ex` — header default via `init([])[:header_name]`.
- `lib/crosswake/audit/ledger.ex` — `defstruct` with 15 LEDG-02 columns; `record_in_multi`.
- `priv/templates/crosswake/audit/ledger.ex.eex` + `migration.exs.eex` — generated-template source of the 15 columns and the ledger-side 8-key PII guard.
- `lib/crosswake/doctor/doctor.ex` — `@canonical_ledger_columns` (co-location comment target), threadline findings + hints citing the guide.

### Test / CI conventions
- `test/crosswake/guides/release_boundaries_test.exs` — existing hardcoded contains-exact docs test pattern.
- `test/crosswake/support_matrix/support_matrix_test.exs` (~:262–267) — `docs_anchor == "guides/threadline.md"` + custom-message assertion precedent.
- `test/mix/tasks/crosswake.threadline_test.exs` — `Mix.Task.reenable` + capture idiom for task tests.
- `.github/workflows/phase90-proof.yml` — trigger shape (push all branches + PR).
- `.github/workflows/phase73-proof.yml` / `phase75-closeout-gate.yml` — pinned-SHA actions, `permissions: contents: read`, compile-warnings-as-errors step.
- `.github/workflows/phase23-proof.yml` — THE advisory-lane pattern: schedule/dispatch-gated job + weekly cron + `::notice` annotation.
- Phase 52/64/65 proof tests under `test/crosswake/proof/` — untagged-module hermetic lane guard to replicate.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `guides/threadline.md` exists from Phase 95 — restructure, don't greenfield.
- `examples/phoenix_host` already runs ecto_sqlite3 with three committed generated Sigra audit schema+migration pairs — the PROOF-02 lane needs no Postgres service and has a committed-schema precedent.
- Public telemetry introspection functions already exist — no new public API needed for parity tests.

### Established Patterns
- 20+ `phaseNN-proof.yml` workflows: explicit `mix test` file lists, zero tag-based selection.
- Hermetic proof modules are deliberately untagged and self-guard against `@moduletag`.
- Example-host tests use bare `Repo.delete_all` cleanup, not `Ecto.Adapters.SQL.Sandbox` (no SQLite async sandbox support).

### Integration Points
- Branch protection: register `merge-blocking-threadline-docs-contract-proof` as a required check AFTER the workflow's first completed run (GitHub only lists job ids post-run; registering the display name silently never matches).
- Doctor hint strings and `support_matrix` `docs_anchor` already point at `guides/threadline.md` — restructure must not break those contains-exact references (re-verify both tests after the rewrite).

</code_context>

<specifics>
## Specific Ideas

- Anti-scope section modeled on SQLite's "Appropriate Uses" page: direct, honest, credibility-building ("performance will not be great" energy).
- Avoid the Oban anti-pattern of making readers hunt for the field list elsewhere — the 15-field table lives in the guide itself.
- Each parity-assertion failure message names the missing contract element and the file to update — failure output is the primary DX surface of this phase.

</specifics>

<deferred>
## Deferred Ideas

- `Crosswake.Audit.Ledger.canonical_columns/0` public introspection function — extract only when a third consumer needs the column list (currently: test + Doctor co-location comment suffices).
- Hash-chain verification task (`row_hash`/`prev_hash` integrity walking) and `crosswake_dashboard` LiveDashboard UI — already documented as deferred non-claims; the guide states their absence honestly.

</deferred>

---

*Phase: 96-Docs-Contract + Proof*
*Context gathered: 2026-06-10*
