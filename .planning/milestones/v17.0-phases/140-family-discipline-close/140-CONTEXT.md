# Phase 140: Family Discipline & Close - Context

**Gathered:** 2026-07-02
**Status:** Ready for planning

<domain>
## Phase Boundary

Governance + close-out for the complete 5-package companion family (rulestead, rindle, sigra, chimeway, threadline). This is a **low-LOC, high-precision** phase — Phases 136–139 already landed most of the machinery. Phase 140 delivers:

1. **FAMILY-01** — compat-matrix cell discipline + an O(N) structural guard test + honest pre-publish version cells.
2. **FAMILY-02** — extraction-recipe hardening: a numbered Step 0 core-coupling gate, the grep exit-code correctness fix, widened guard scope + a module-attribute coupling pass, inline failure callouts, updated proven-on footer.
3. **FAMILY-03** — per-package Side-A "declared ⇔ emitted" telemetry contract tests (sigra + chimeway new; threadline minimal upgrade) + regression guards locking the already-done `>=24` removal and anti-drift subset invariant.
4. **FAMILY-04** — publish *readiness*: verify component registration, author the human-gated publish runbook, document `register_required_checks.sh` green-first ordering. **No hex publish in this phase.**

**The risk isn't "build a lot" — it's "get the irreversible publish ordering right and don't add brittle enforcement."** Bias the plan toward verification tests that lock in already-correct behavior + one carefully-written runbook.

**Load-bearing invariant across every decision:** companions depend on **core only, never on each other**. This keeps the matrix O(N), keeps telemetry namespaces additive, and makes publish order among companions arbitrary-after-core.
</domain>

<decisions>
## Implementation Decisions

All four open clusters were researched via a 4-subagent research-then-recommend pass (release-eng/SRE, docs-DX, telemetry-testing, extraction-runbook lenses), each verified against the real repo files. The prior `140-RESEARCH-SYNTHESIS.md` (D-140-1..15) is accepted **with two corrections** (D-140-11 upgraded, D-140-3 gains a format guard) noted below.

### FAMILY-04 — Publish scope & sequencing (the one irreversible cluster)
- **D-01 (USER-LOCKED): Wave 4 is readiness-only with a separate human trigger.** Phase 140 delivers Waves 1–3 autonomously (discipline + tests + recipe + the runbook doc + ship-gate ordering docs). Wave 4 = the batched sigra→chimeway→threadline publish + `register_required_checks.sh` registration, authored as a **human-gated runbook (`autonomous:false`)** that the user fires *separately*, AFTER origin-sync lands + CI green. **No hex publish happens inside Phase 140.** Consistent with the standing "no-publish-now / batched family publish" choice and the boundary-hygiene "no publish this pass" rule. (Note for the eventual trigger: "deferred" ≠ "indefinite" — the family should go live once origin-sync + 137/138/139 execution-verification are done.)
- **D-02: Sequencing = RUNBOOK discipline, NOT GitHub Actions `needs:` edges.** VERIFIED footgun: `needs` cannot span workflow runs; each companion's Release PR merges in its own run, so a cross-companion `needs` edge silently skips (or, with explicit `if: success()`, deadlocks). Do NOT add `publish-hex-chimeway: needs: publish-hex-sigra` etc. The correct primitives — all confirmed present in `release-please.yml` — are: `separate-pull-requests: true` (isolation) + per-component `*_release_created` gate + within-run `clean-room-proof-<name>: needs: [release-please, publish-hex-<name>]` (ordering) + `release-failure-alert` on `failure()`.
- **D-03: Publish runbook (the `autonomous:false` wave doc) enforces:** merge exactly ONE Release PR → wait for `publish-hex-<name>` + `clean-room-proof-<name>` green on main → confirm `hexdocs.pm/crosswake_<name>/0.1.0` resolves → merge that companion's auto-opened `release-as-cleanup` PR → only then next. Canonical order **sigra → chimeway → threadline** (observer published last, belt-and-suspenders). Include the ~60-min Hex revert-window note + "if `release-failure-alert` fires, STOP." Do NOT retry a failed publish without checking the revert window (`mix hex.retire`, not re-push).
- **D-04: `register_required_checks.sh` runs green-first, AFTER new lanes go green on main, never before.** VERIFIED: the script has a paginated green-first preflight (skips lanes with no green run on branch HEAD). Order: land Phase 140 → let any new `merge-blocking-*` lane run green once on main → `DRY_RUN=1` then `DRY_RUN=0` register → daily `required-checks-audit.yml` confirms. Companion `publish-hex-*` / `clean-room-proof-*` jobs are post-merge and MUST NOT be registered as required checks (they skip on normal PRs; requiring them = permanent deadlock).

### FAMILY-01 — Compat matrix
- **D-05: Cell discipline.** Collapse the Threadline row's prose-in-cell into one-liners: `Companion ID` → `N/A (observer — not a :companions registrant)`; `Engine Dependency` → `none (optional :plug + :phoenix_live_view for surface modules)`. Move the `Crosswake.Plug.Threadline` / `on_mount:` wiring explanation to prose below the table.
- **D-06: `Current Version` cells → `` `unpublished` `` until the batched publish fires; human writes the real number back post-publish.** Do NOT automate pipeline write-back (5 racing CI doc-commits + a `contents: write` escalation on tagged-checkout publish jobs is not worth it for 5 rows; hex.pm is the authority). Add a standalone HTML comment ABOVE the table (not inside a cell): `<!-- Current Version: do not hand-edit; update this column post-publish from the confirmed hex.pm release page -->`.
- **D-07: Add an O(N) structural guard to the drift test** (`phase132_compat_matrix_drift_test.exs`): parse the header row and `refute` any column header beyond col 1 matching `` `crosswake_\w+` ``. This is the one machine-check that makes the "no inter-companion columns" invariant real.
- **D-08 (CORRECTION to synthesis D-140-3 — adds a format guard): Add a lightweight version-cell FORMAT assertion** to the drift test: each `Current Version` cell must match `` `unpublished` `` OR a valid semver literal (`` `\d+\.\d+\.\d+` ``). Catches prose-creep / hand-edit mistakes WITHOUT fencing the value (the drift test still must NOT assert a specific version — hex.pm stays authority).
- **D-09: Do NOT add columns or a `Companion ID` drift test.** Keep the single `Requires crosswake` fenced cell (already drift-tested bidirectionally). No manifest/bridge/native axes (those live in `compatibility.md`). Leave a `# TODO` in the parser for the eventual core-1.0 compound-`or` constraint (`~> 0.1 or ~> 1.0`) so it doesn't surface as a cryptic drift failure.

### FAMILY-02 — Extraction recipe (`script/extract_companion.md`)
- **D-10: Add `## Step 0: Core-coupling audit (required before extraction)` as a NUMBERED blocking gate before Step 1**, with a companion-type triage table: `pure` (rulestead/rindle — skip Step 0 body) / `compile-coupled` (sigra/chimeway — invert onto `:companions` registry first, Phase 136 pattern) / `observer` (threadline — non-`:companions`; freeze `@module_attribute`s to literals + cut static companion fn calls in `telemetry.ex`; NO registry step). The observer body must NAME both coupling sites (the `@audit_ledger_support_truth` freeze + the telemetry attach cut) since they're non-obvious.
- **D-11: FIX the grep-guard exit code (VERIFIED real bug, 1 occurrence at ~L51).** Current `grep -r "..." lib/ && echo "FAIL" || echo "CLEAN"` exits 0 even on a match — it can never fail CI. Replace with the exact idiom: `if grep -rn --exclude-dir=packages "PATTERN" lib/ test/ mix.exs; then echo "FAIL: ..."; exit 1; fi; echo "CLEAN"`. Use `-n` (line numbers for MTTR), NOT `-q`. Use `if grep; then exit 1; fi`, NOT `|| exit 1` (the latter breaks under `set -euo pipefail` on a clean tree). Put `--exclude-dir=packages` BEFORE the paths (BSD/macOS grep portability — recipe runs on darwin/zsh). Add a comment: `# use 'if grep...; then exit 1; fi' — never '&& echo FAIL || echo CLEAN' (exit-code trap)`.
- **D-12: Widen guard scope + add a module-attribute pass.** Scope the primary grep to `lib/ test/ mix.exs --exclude-dir=packages`, matching both `Crosswake\.Companions\.{Companion}` and `Crosswake\.{Companion}\.`. Add a SECOND distinct pass over `lib/crosswake/` only for `@\w+ .*Crosswake\.(Companions\.)?{Companion}\.` — the compile-time module-attribute coupling class (VERIFIED: the pre-139 `@audit_ledger_support_truth [..., ThreadlineTelemetry.event_names()]` baked values into the .beam; a call-site/alias grep misses it). Document known limits: atom-only config refs are host-owned runtime (not coupling); `apply/3` dynamic dispatch can't be grepped — the Step-11 compile (`--warnings-as-errors`, `set -e`) is the hard backstop.
- **D-13: When widened `test/` scope flags a legit core file:** the recipe must instruct — confirm the flagged test either belongs in the companion package lane (move it) OR is a core fail-closed contract test that must NOT reference the companion module directly → use the EXTRACT-03 "test the behavior without aliasing the module" pattern (see `phase130_fail_closed_contract_test.exs`).
- **D-14: Add inline `> If this step fails:` callouts** (blockquote immediately after each failable step — appendices go unread) + update the proven-on footer to list all 5 companions tagged by type (rulestead/rindle = pure; sigra/chimeway = compile-coupled; threadline = observer). The footer is trust infrastructure.

### FAMILY-03 — Telemetry contract tests
- **D-15: `>=24` count-assertion removal is DONE (Phase 136 D-136-D shape assertion); lock it against regression.** Add/keep a guard asserting `grep -c '>= 24'` on `phase133_telemetry_contract_test.exs` is 0. Do NOT re-do finished work.
- **D-16: Add per-package Side-A "declared ⇔ emitted" tests for sigra AND chimeway in each companion's OWN suite** (VERIFIED: neither has a catalog-driven test yet — sigra uses membership assertions, chimeway a single hardcoded-name live test). Shape: pull declared names from `Telemetry.event_names/0`, drive a real code path, `:telemetry_test.attach_event_handlers` + `assert_received`, assert declared measurement/metadata keys present via `Map.has_key?` (subset, NEVER exact-count — exact-count re-creates the `>=24` cross-package coupling). Sigra events are `:reserved` in core (declared-not-emitted-by-core); the companion's own Side-A proves emission — the two facts together = the full contract.
- **D-17 (CORRECTION to synthesis D-140-11 — UPGRADED from "skip" to "minimal upgrade"): Threadline gets a ~20-line Side-A upgrade.** VERIFIED the synthesis OVERSTATED phase92's coverage: phase92 hardcodes 3 event names (NOT catalog-driven) and the declared `:exception` event is claimed-proven but NEVER driven live. Add: (a) a ~10-line catalog-iterating test in the existing `crosswake_threadline/test/**/telemetry_test.exs` — `for event_name <- Telemetry.event_names() do ... :telemetry.attach + Telemetry.execute + assert_receive + Map.has_key?(metadata, :thread_id) end` (catches "declared a 4th event, forgot to emit"); (b) ONE plug-behavior test driving `Plug.Threadline` through an error path to fire the currently-unproven `:exception` event. Family-consistent with sigra/chimeway; closes both real gaps for ~20 lines.
- **D-18: Anti-drift subset invariant is DONE (Phase 139 D-5, `telemetry_test.exs` ~L258); keep it.** `core_baseline ⊆ union(companion forbidden_metadata_keys)`. Confirms the curated-universal-floor framing — do NOT absorb threadline's PII minutiae into core.

### Claude's Discretion
- Exact test file names/locations for the new Side-A tests (follow each package's existing `test/` convention).
- Wave decomposition detail (the synthesis's suggested Wave 1 = matrix+sigra/chimeway Side-A+`>=24` guard; Wave 2 = recipe; Wave 3 = publish-readiness docs; Wave 4 = human-gated publish — is a starting point, not binding).
- Precise callout wording in the recipe; exact triage-table column headers.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Prior phase decision trail (read first)
- `.planning/phases/140-family-discipline-close/140-RESEARCH-SYNTHESIS.md` — the 5-lens research-then-recommend synthesis; D-140-1..15 map to the decisions above (accepted with D-08 format-guard addition + D-17 threadline upgrade).
- `.planning/ROADMAP.md` §"Phase 140" — goal + 4 success criteria.
- `.planning/REQUIREMENTS.md` — FAMILY-01..04 (lines 44–47).

### FAMILY-01 (matrix)
- `guides/companion_compatibility.md` — the adopter-facing compat matrix being disciplined.
- `test/crosswake/proof/phase132_compat_matrix_drift_test.exs` — the drift test to extend (O(N) column guard D-07 + version-cell format guard D-08).

### FAMILY-02 (recipe)
- `script/extract_companion.md` — the recipe being hardened (grep bug at ~L51; Step 0 gate; proven-on footer).
- `lib/crosswake/support_matrix/support_matrix.ex` §~L283 — the `@audit_ledger_support_truth` module-attribute coupling comment (the observer-class the module-attr grep pass D-12 catches).
- `test/crosswake/proof/phase130_fail_closed_contract_test.exs` — the EXTRACT-03 "test behavior not module" pattern referenced by D-13.

### FAMILY-03 (telemetry)
- `test/crosswake/proof/phase133_telemetry_contract_test.exs` — the shape assertion that replaced `>=24` (D-15 regression guard target).
- `test/crosswake/telemetry_test.exs` §~L258 — the anti-drift subset invariant (D-18, keep).
- `crosswake_sigra/`, `crosswake_chimeway/`, `crosswake_threadline/` — each package's `lib/**/telemetry.ex` (`event_names/0`) + `test/**/telemetry_test.exs` (Side-A test targets D-16/D-17).
- `crosswake_threadline/` phase92 server-propagation closeout test (grep `phase92` + `Plug.Threadline`) — the existing hardcoded-3-name test D-17 upgrades.

### FAMILY-04 (publish)
- `.github/workflows/release-please.yml` — component registration + per-component gates + `clean-room-proof-*` within-run edges + `release-failure-alert` (all VERIFIED present).
- `release-please-config.json` + `.release-please-manifest.json` — the `separate-pull-requests: true` + `release-as: 0.1.0` + `_TODO_release_as` config.
- `script/register_required_checks.sh` — green-first preflight (D-04); the ship-gate ordering.
- `docs/MILESTONE-BOUNDARY-HYGIENE.md` — the origin-sync-before-publish sequencing this phase's Wave 4 waits on.

### Project vision / voice (reference where relevant)
- `prompts/crosswake-elixir-oss-dna.md`, `prompts/crosswake-integrations-and-companions.md` — family/publishing philosophy.
- `prompts/crosswake-brand-book.md` — adopter-doc voice/microcopy (matrix cells, recipe callouts).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `phase132_compat_matrix_drift_test.exs` — extend in-place for D-07 (O(N) column guard) + D-08 (version-cell format guard); already AST-parses `packages/crosswake_*/mix.exs` and fences the `Requires crosswake` cell.
- Existing companion `Telemetry.event_names/0` in all three packages — the catalog source for the Side-A tests.
- `chimeway` clean-room proof already suppresses sigra install (proves no-sigra-dep) — the pattern the recipe's guard formalizes.

### Established Patterns
- Per-component release-please gating (`*_release_created`) + within-run `needs` for ordering — the correct, already-implemented primitive; the runbook wraps it, CI does not add cross-run edges.
- Curated-universal-floor telemetry model (core baseline ⊆ union of companion forbidden keys) — companion-domain keys stay companion-local; the recipe/tests preserve this.
- EXTRACT-03 "test behavior not module" pattern (`phase130_fail_closed_contract_test.exs`) — how core keeps fail-closed contract tests without aliasing extracted companion modules.

### Integration Points
- The publish runbook (new doc) connects `release-please.yml` behavior → the human operator → hex.pm; it is documentation, not code — no new CI edges.
- The recipe's module-attribute grep pass connects the strangler-fig decoupling discipline (Phase 136/139) to the recipe so a 6th companion extraction won't hit the `@audit_ledger_support_truth`-class footgun undiagnosed.
</code_context>

<specifics>
## Specific Ideas

- Publish order is fixed **sigra → chimeway → threadline** (observer last, belt-and-suspenders), one Release PR at a time.
- Version cell wording is literally `` `unpublished` `` (backtick-wrapped, house style).
- Grep idiom is literally `if grep -rn --exclude-dir=packages "..." lib/ test/ mix.exs; then echo "FAIL: ..."; exit 1; fi`.
- Side-A key assertions use `Map.has_key?` (subset), never exact-count — this is a hard rule (exact-count re-introduces the `>=24` coupling).
</specifics>

<deferred>
## Deferred Ideas

Surfaced by research as genuinely good but scope-creep for "Discipline & Close" — capture, don't build:

- **`CROSSWAKE_VERSION=local|main|~>x` env helper** in every companion `mix.exs` (Ash `ash_version/1` pattern) — high-leverage contributor DX, but a new cross-package convention → its own follow-up phase.
- **`mix test.as_a_dep`** outside-in alias per companion (ecto_sql pattern).
- **`nimble_options` companion-config schema**; **Igniter generators** (already deferred per v17 state).
- **`mix crosswake.upgrade`** migration task; **`--warnings-as-errors --no-optional-deps` compile lane.**
- **Pipeline write-back automation** for the `Current Version` cell — considered and rejected for 5 rows (D-06); revisit only if the family grows large enough that manual write-back drifts.
- **Full catalog-driven rewrite of threadline phase92** — rejected in favor of the minimal upgrade (D-17); the observer's 3-event list is stable.

Also still deferred behind the companion-family wedge (from prior milestones): DASH-01 (crosswake_dashboard), SYNCP-01, NTV-01, SEED-002.

</deferred>

---

*Phase: 140-family-discipline-close*
*Context gathered: 2026-07-02*
