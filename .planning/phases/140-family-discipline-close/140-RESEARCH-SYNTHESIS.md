# Phase 140 — Research Synthesis (research-then-recommend)

**Produced:** 2026-07-02 · **Feeds:** `/gsd-discuss-phase 140` → planner
**Method:** 5 parallel expert-lens subagents (compat-matrix/DX, telemetry/SRE, extraction-recipe/runbook, publish-pipeline/release-eng, cross-ecosystem lessons), each grounded in the real artifacts + `prompts/` research + web research on comparable multi-package families.

---

## Headline reframe (read this first)

Phase 140 as written in ROADMAP reads like four fresh governance workstreams. The research found the opposite: **136–139 already landed most of it.** What remains is precise, small, and safety-critical. Concretely:

| Req | ROADMAP framing | Actual remaining work |
|---|---|---|
| FAMILY-01 (matrix) | "add drift-tested rows, keep O(N)" | Matrix already has all 5 rows + bidirectional drift test. Remaining = **cell-discipline cleanup + one new O(N) structural guard test + `unpublished` version cells**. |
| FAMILY-02 (recipe) | "add Step 0 + grep guard" | Recipe exists, proven on 2 companions. Remaining = **Step 0 coupling-triage, fix a real grep exit-code bug, widen scope, document observer variant, update proven-on list**. |
| FAMILY-03 (telemetry) | "remove `>=24`, add per-pkg Side-A tests" | **`>=24` already removed in Phase 136** (D-136-D shape assertion is live + green). Anti-drift subset test already live (Phase 139 D-5). Remaining = **per-package Side-A emission tests for sigra & chimeway** (threadline already covered by phase92). |
| FAMILY-04 (publish) | "sequential publish + ship-gate" | All 3 companions **already registered** as independent release-please components w/ `separate-pull-requests: true` + per-component gating. Remaining = **the deferred human-gated publish RUNBOOK + correct `register_required_checks.sh` ordering**. Do NOT add CI DAG edges. |

**Implication for scope:** this is a low-LOC, high-precision phase. The risk isn't "build a lot," it's "get the irreversible publish ordering right and don't add brittle enforcement." Bias the plan toward *verification tests that lock in already-correct behavior* + *one carefully-written runbook*.

---

## Proposed locked decisions (candidates for discuss-phase)

### FAMILY-01 — Compat matrix (adopter-facing version governance)

- **D-140-1 — Cell discipline.** Collapse the Threadline row's prose-in-cell into one-liners. `Companion ID` → `N/A (observer — not a :companions registrant)`; `Engine Dependency` → `none (optional :plug + :phoenix_live_view for surface modules)`. Move the wiring explanation (`Crosswake.Plug.Threadline` / `on_mount:`) to prose below the table. *Rationale: a 300-char table cell is a paragraph, not data — principle of least surprise for the reader whose JTBD is "which core version + engine do I need?"*
- **D-140-2 — Add O(N) structural guard to the drift test.** New assertion in `phase132_compat_matrix_drift_test.exs`: parse the header row and `refute` any column header (beyond col 1) matching `` `crosswake_\w+` ``. *Rationale: the requirement's core intent ("no inter-companion columns") is currently unenforced — a future contributor could add a "Requires crosswake_sigra" column and pass CI. This is the one machine-check that makes the O(N) invariant real.*
- **D-140-3 — `Current Version` cells → `unpublished` until the batch publish fires.** The publish wave (FAMILY-04) owns writing the real number back. Add `<!-- do not hand-edit; publish pipeline owns this column -->`. *Rationale: `0.1.0` becomes a lie the moment `0.1.1` ships; the drift test correctly does NOT fence this column (hex.pm is the authority), so honesty pre-publish = `unpublished`.*
- **D-140-4 — Do NOT add columns or a `Companion ID` drift test.** Keep the single `Requires crosswake` fenced cell. No manifest/bridge/native axes (those live in `compatibility.md`). *Rationale: single-question guides beat multi-question guides; a `Companion ID` AST test costs more than the 5-row risk.*
- **Deferred note:** when core hits 1.0, companions may need `~> 0.1 or ~> 1.0`; leave a `# TODO` in the parser so a compound-`or` AST doesn't surface as a cryptic drift failure. (Phoenix `or`-constraint precedent.)

### FAMILY-02 — Extraction recipe (`script/extract_companion.md`)

- **D-140-5 — Add Step 0 as a numbered blocking gate (not a prerequisites bullet).** Insert `## Step 0: Core-coupling audit (required before extraction)` before Step 1, with a **companion-type triage table**: `pure` (skip Step 0 body) / `compile-coupled` (must invert onto `:companions` registry first) / `observer` (non-`:companions`; coupling lives in core `@module_attribute`s + telemetry attach — the threadline pattern). *Rationale: strangler-fig + SRE-runbook literature is unanimous — prerequisite decoupling is an active numbered step; burying it in prose means engineers start Step 1 (move source) before core is decoupled, then hit undiagnosable compile failures.*
- **D-140-6 — FIX the grep-guard exit code (real bug).** The current guard `grep -r "..." lib/ && echo "FAIL" || echo "CLEAN"` **returns exit 0 even on a match** — it never fails CI. Replace every occurrence with `if grep -rn ...; then echo "FAIL: ..."; exit 1; fi`. *Rationale: this is the single most important correctness fix in the phase — a guard that can't fail is theater.*
- **D-140-7 — Widen the guard scope + add the module-attribute pass.** Scope Step-0/Step-1 greps to `lib/ test/ mix.exs` with `--exclude-dir=packages`, matching both `Crosswake\.Companions\.{Companion}` and `Crosswake\.{Companion}\.`; add a second pass for `@attr … {CompanionModule}.fn()` compile-time attribute coupling in `lib/crosswake/` (catches the threadline `@audit_ledger_support_truth` class that call-site greps miss). Document known limits (atom-only config refs are host-owned runtime, not coupling; `apply/3` dynamic dispatch can't be grepped — the Step-11 compile is the hard backstop). *Rationale: package-extraction breakage consistently comes from refs outside `lib/`; module-attribute coupling is the subtlest, hardest-to-grep class and we hit it for real.*
- **D-140-8 — Add inline `> If this step fails:` callouts + update the proven-on footer** to list all 5 companions tagged by type (rulestead/rindle = pure; sigra/chimeway = compile-coupled; threadline = observer). *Rationale: inline failure-modes cut MTTR under pressure (troubleshooting appendices go unread); the proven-on list is trust infrastructure.*

### FAMILY-03 — Telemetry contract tests

- **D-140-9 — Count-assertion removal is DONE; assert it stays done.** `>=24` was replaced in Phase 136 by the D-136-D count-independent shape assertion (`phase133…exs` ~L358). Add/keep a guard that `grep -c '>= 24'` on the file is 0. *Rationale: don't re-do finished work; do lock it against regression.*
- **D-140-10 — Add per-package Side-A "declared ⇔ emitted" tests for sigra and chimeway** in each companion's OWN test suite: pull declared names from `Telemetry.event_names/0`, drive a real code path, `telemetry_test.attach_event_handlers` + `assert_received`, assert declared measurement/metadata keys present via `Map.has_key?` (subset, never exact-count). Sigra events are `:reserved` in core (declared-not-emitted-by-core) — the companion's own Side-A proves the emission exists; the two facts together = the full contract. *Rationale: emission proof must live where the emitter lives; central aggregation re-creates the `>=24` cross-package coupling that independent versioning forbids (Keathley: telemetry breakage fails silently in prod).*
- **D-140-11 — Threadline Side-A: already covered; formalize only if cheap.** `phase92_server_propagation_closeout_test.exs` already drives `Plug.Threadline.call/2` and asserts `:start`/`:stop`/`:exception`. Optional: wrap it as a catalog-driven iteration over `event_names/0`. Low priority. *Rationale: the observer has no `:companions` dispatch path to test; the plug behavior test IS the emission proof.*
- **D-140-12 — Anti-drift subset invariant is DONE; keep it.** `core_baseline ⊆ union(companion forbidden_metadata_keys)` lives in `telemetry_test.exs` (~L258, Phase 139 D-5). *Rationale: confirms the corrected D-5 framing (curated universal floor, companion-domain keys aggregated at runtime) — do not absorb threadline PII minutiae into core.*

### FAMILY-04 — Publish pipeline & ship-gate (the one irreversible decision — bias to safety)

- **D-140-13 — Publish sequencing = RUNBOOK discipline, NOT CI `needs` edges.** Do NOT add `needs: publish-hex-sigra` to chimeway etc. *Rationale (hard correctness bug): GitHub `needs` can't span workflow runs; each companion's Release PR merges in its own run, so a cross-run `needs` would make later publishes **skip**. The existing `separate-pull-requests: true` + per-component `*_release_created` gate already guarantees "a misfire can't publish all three." The within-run `clean-room-proof needs: publish-hex-*` edge is the correct ordering primitive.*
- **D-140-14 — The deferred human-gated wave ships a step-by-step runbook** (autonomous:false), enforcing: merge exactly ONE Release PR → wait for `publish-hex-<name>` + `clean-room-proof-<name>` green on main → confirm `hex.pm/packages/crosswake_<name>/0.1.0` resolves → merge that companion's auto-opened `release-as` cleanup PR → only then next. Canonical order **sigra → chimeway → threadline** (belt-and-suspenders: publish the observer last, so it isn't live before its siblings). Include the 60-min Hex revert-window note + "if `release-failure-alert` fires, STOP." *Rationale: Hex is irreversible after the grace window; the runbook is the safety rail for the human.*
- **D-140-15 — `register_required_checks.sh` runs AFTER new lanes go green on main, never before.** Order: land Phase 140 → let any new `merge-blocking-*` lane run green once on main → `DRY_RUN=1` then `DRY_RUN=0` register → daily `required-checks-audit.yml` confirms. *Rationale: the canonical GitHub footgun is requiring a check that never ran green on HEAD → permanent PR deadlock. The script's green-first preflight guards this; the runbook must state the ordering explicitly. Companion publish/clean-room jobs are post-merge, so they are NOT required-check candidates.*

---

## Cross-decision coherence (the invariants that tie it together)

1. **Companions depend on core only — never on each other.** Keeps the matrix O(N) (FAMILY-01), keeps telemetry namespaces additive/non-overlapping (FAMILY-03), keeps publish order among companions arbitrary-after-core (FAMILY-04), and is the recipe's central rule (FAMILY-02). This is the family's load-bearing architectural invariant; every decision above preserves it.
2. **Floors, not ceilings / not exact pins.** `~> 0.1` everywhere (matrix + companion mix.exs). Phoenix's 2020 patch-pin cascade is the cautionary tale.
3. **"Already correct" gets a lock test, not a rebuild.** FAMILY-01 drift test, FAMILY-03 shape + subset assertions, FAMILY-04 component registration are done — Phase 140 adds *guards that fail if they regress*, not replacements.
4. **Consistent companion-type vocabulary** (`pure` / `compile-coupled` / `observer`) across the recipe (FAMILY-02) and any matrix annotation. Threadline = observer everywhere.
5. **Owner of the version cell = the publish pipeline** (FAMILY-01 D-140-3 ↔ FAMILY-04). Confirm in discuss-phase whether the release changeset writes it back or the human does; simplest = `unpublished` now, human updates post-publish.

---

## Scope fence — IN vs DEFERRED

**IN (FAMILY-01..04 as above):** cell cleanup + O(N) guard test + `unpublished` cells; Step 0 + grep-exit-fix + scope widen + observer variant + proven-on; per-pkg Side-A tests (sigra, chimeway) + regression guards; deferred publish runbook + required-check ordering.

**DEFERRED (surfaced by research, genuinely good, but scope-creep for "Discipline & Close"):**
- `CROSSWAKE_VERSION=local|main|~>x` env helper in every companion mix.exs (Ash `ash_version/1` pattern) — high-leverage contributor DX, but a new cross-package convention → its own follow-up.
- `mix test.as_a_dep` outside-in alias per companion (ecto_sql pattern).
- `nimble_options` companion-config schema; Igniter generators (already deferred per v17 state).
- `mix crosswake.upgrade` migration task; `--warnings-as-errors --no-optional-deps` compile lane.

*Recommend: note these in `## Deferred Ideas` in CONTEXT.md so they're captured, not lost, but keep Phase 140 tight.*

---

## Suggested wave shape (for the planner, not binding)

- **Wave 1 (autonomous):** FAMILY-01 matrix cleanup + O(N) guard test; FAMILY-03 sigra + chimeway Side-A tests + `>=24`-stays-gone guard. (Pure test/doc; independent.)
- **Wave 2 (autonomous):** FAMILY-02 recipe rewrite (Step 0, grep-exit fix, scope, observer variant, callouts, proven-on).
- **Wave 3 (autonomous):** FAMILY-04 *pipeline readiness* — verify component registration, author the publish runbook doc, document the `register_required_checks.sh` ordering. No publishing.
- **Wave 4 (human-gated, autonomous:false):** execute the runbook — the actual sequential publishes + ship-gate registration. Fires only when you trigger it, only after 137/138/139 are execution-verified.

---

## What to lock in discuss-phase

1. Confirm the four `D-140-*` decision clusters above (accept / adjust).
2. Confirm publish-scope: Wave 4 stays deferred human gate (already chosen).
3. Decide the `Current Version` cell owner (pipeline write-back vs human post-publish).
4. Confirm the deferred DX items go to `## Deferred Ideas` (not this phase).
5. Confirm canonical publish order sigra → chimeway → threadline and the "one Release PR at a time" discipline.
