---
gsd_state_version: 1.0
milestone: v18.0
milestone_name: Release Integrity & Automated Package Operations
current_phase: 143
current_phase_name: Guarded Auto-Publish Train
status: Executing
stopped_at: Completed 143-02-PLAN.md
last_updated: "2026-07-07T21:58:28.769Z"
progress:
  total_phases: 5
  completed_phases: 1
  total_plans: 6
  completed_plans: 5
  percent: 20
---

# Project State: Crosswake

## Project Reference

See: .planning/PROJECT.md (updated 2026-07-07 after v18.0 milestone start)

**Core value:** Replace host-owned generated shell code with standalone SPM/Maven dependencies, enforcing strict delegate-based customization to eliminate the "eject trap" and boilerplate for adopters.
**Current focus:** Phase 143 — guarded-auto-publish-train

## Current Position

**v18.0 "Release Integrity & Automated Package Operations" ACTIVE as of 2026-07-07.** Scope is CI/CD and release operations, not product breadth. Requirements live in `.planning/REQUIREMENTS.md`; roadmap phases 142-146 are active in `.planning/ROADMAP.md`.

Phase: 143 (guarded-auto-publish-train) — EXECUTING
Plan: 3 of 3

Phase 142 discussion output:

- `.planning/phases/142-release-graph-governance-contract/142-CONTEXT.md`
- `.planning/phases/142-release-graph-governance-contract/142-DISCUSSION-LOG.md`
- Commit: `9d035b1e docs(142): capture phase context`
- Key implementation gaps identified for planning: add/justify `queue: max`, make `release-as-cleanup` wait for released companion proof success, and harden the workflow integrity scanner against aggregate-gate and comment-only false passes.

Phase 142 planning output:

- `.planning/phases/142-release-graph-governance-contract/142-RESEARCH.md`
- `.planning/phases/142-release-graph-governance-contract/142-VALIDATION.md`
- `.planning/phases/142-release-graph-governance-contract/142-01-PLAN.md`
- `.planning/phases/142-release-graph-governance-contract/142-02-PLAN.md`
- `.planning/phases/142-release-graph-governance-contract/142-03-PLAN.md`
- Plan checker: passed after revisions; RELG-01, RELG-02, and RELG-03 covered; decision coverage gate passed 30/30.

Phase 143 planning output:

- `.planning/phases/143-guarded-auto-publish-train/143-RESEARCH.md`
- `.planning/phases/143-guarded-auto-publish-train/143-VALIDATION.md`
- `.planning/phases/143-guarded-auto-publish-train/143-PATTERNS.md`
- `.planning/phases/143-guarded-auto-publish-train/143-01-PLAN.md`
- `.planning/phases/143-guarded-auto-publish-train/143-02-PLAN.md`
- `.planning/phases/143-guarded-auto-publish-train/143-03-PLAN.md`
- Research commit: `70845e96 docs(143): research guarded auto-publish train`
- Validation/pattern/plan commits: `ccd78cba`, `607a5481`, `82896bcb`, `2476f17c`, `3abb7aad`
- Plan checker: passed after two targeted revisions; AUTO-01, AUTO-02, and AUTO-03 covered; decision coverage gate passed 34/34.

Implemented in the current work slice:

- Root/native publish jobs now gate on Release Please `paths_released` instead of aggregate `releases_created`.
- Release workflow publish/proof concurrency is non-canceling and preserves pending runs with `queue: max`.
- iOS mirror job fails fast on missing/invalid `MIRROR_PUSH_TOKEN` and skips an already-existing mirror tag.
- iOS and Android clean-room proofs no longer depend on each other.
- `release-as-cleanup` waits for released companion publish and clean-room proof jobs to finish successfully, then opens a cleanup PR only.
- `script/verify_companion_cleanroom.sh` now derives the core floor from the package under test and installs the exact just-published companion version.
- `mix crosswake.doctor --router` compiles/loadpaths before rejecting a freshly compiled router.
- `mix crosswake.release.status [--json] [--live]` added as the text/JSON release operator surface.

Carried seeds being harvested:

- **SEED-003** — iOS SwiftPM mirror push token / missing `v0.2.0` mirror tag.
- **SEED-004** — companion clean-room proof harness.

Deferred behind v18:

- DASH-01 `crosswake_dashboard`
- SYNCP-01 offline-sync productization
- NTV-01 native disk budgets
- SEED-002 Phoenix-first native capability/commerce breadth

## v16.0 Closed (2026-06-30) — one admin ship-gate carried forward

**Done:** all 7 phases verified passed; `/gsd-audit-milestone` PASSED (27/27 reqs, integration CLEAN); PR #40 merged → origin at v16.0; CI green after 5 lane fixes. **`/gsd-complete-milestone v16.0` run 2026-06-30** — ROADMAP/REQUIREMENTS/AUDIT archived to `.planning/milestones/v16.0-*`, MILESTONES.md + PROJECT.md evolved, REQUIREMENTS.md removed (fresh for next milestone), tag `v16.0` created.

**Carried ship-gate — Register required checks (ADMIN, one-time, human gate by design).** Only 2/20 merge-blocking lanes are currently registered required on main. To make them actually merge-blocking:

   - First confirm the lanes are green on `main` post-merge: `gh run list --branch main --limit 15`.
   - Then (admin gh auth = repo owner szTheory): `DRY_RUN=0 script/register_required_checks.sh`
   - (Optional) provision repo secret `BRANCH_PROTECTION_READ_TOKEN` (Administration:read + Issues:write) so `.github/workflows/required-checks-audit.yml` can run.
   - This ship-gate is scheduled as part of Phase 140 (FAMILY-04) — run before new v17.0 lanes are relied upon as merge-blocking.

**Carried tech-debt (non-blocking):** TELEM-04 Side B vacuity (Phase 133, assessed: fragile fix, non-exposed — leave) and `companion_compatibility.md:51-54` prose (Phase 132, assessed: not a bug — leave). Pre-existing MIRROR_PUSH_TOKEN scope still unexercised.

## v17.0 Roadmap Decisions (2026-06-30, locked)

- Five phases derived from the five requirement categories in the research-mandated sequential order: DECOUPLE (136) → SIGRA (137) → CHIME (138) → THREAD (139) → FAMILY (140).
- Phase ordering is non-negotiable: 136 inverts the four coupling sites before any extraction (core must compile without companions present); 137 first publish (sigra, most entangled, ~3,800 LOC); 138 second publish (chimeway, telemetry-only coupling, clean-room excludes sigra); 139 third publish (threadline, observer, extracted last per D-7 — core telemetry must decouple first); 140 disciplines the family and closes the admin ship-gate.
- The "chimeway depends on sigra AuthContext" coupling is a myth at the type level — chimeway already uses `auth_context: map()`, not a sigra struct. Compatibility matrix stays O(N), single `Requires crosswake >= X` column.
- D-1 mechanism: extend `Crosswake.Companion` behaviour with optional callbacks (`forbidden_metadata_keys/0`, `denial_codes/0`, `evaluate_auth/3`, `auth_authority?/0`); core iterates via `function_exported?/3`; never `compile_env`, never `@before_compile`.
- D-3 fail-closed: auth-predicated route + no auth companion = `:dependency_missing` deny; companion raising = rescued → deny; "no eval = allow" only on non-auth routes.
- D-4 boundary: sigra internals refactor `Denial.new` → `Finding.t()` at the package boundary; `DenialCodes.sanitize_details/1` stays inside `crosswake_sigra`.
- D-5 PII: core baseline hardcoded denylist (auth tokens, identity fields) always applied, layered above per-companion `forbidden_metadata_keys/0` aggregation.
- D-8 versioning: independent `release-please` components, NOT `linked-versions` lockstep (Ash/Broadway/Oban precedent); chimeway `auth_context: map()` moduledoc guard note prevents inter-companion dep creep.
- D-9 sequencing: register_required_checks.sh runs before new v17.0 lanes land; one release-please component per PR (no batch misfire); chimeway clean-room explicitly excludes `crosswake_sigra`.
- Three unreclaimable Hex names (`crosswake_sigra`, `crosswake_chimeway`, `crosswake_threadline`) — dress-rehearsal + `--dry-run` mandatory before each publish.

## Performance Metrics

**Velocity:**

- Total plans completed: 142 across v10.0-v17.0 + 3 in v18.0 Phase 142 = 145
- Average duration: —
- Total execution time: —

*Updated after each plan completion*

## Accumulated Context

### Planning Gate Override (Known Pattern)

The blocking `decision-coverage-plan` gate returns false-negatives on long-bold / embedded-colon `**D-NN: …**` CONTEXT bullets (extracts 0 of N). Cross-check plan-checker Dimension 7 manually + `grep D-0` confirmation when this gate fires. Proceed with override if substance is covered.

### Decisions

Full decision log in PROJECT.md (Key Decisions).

- [Phase ?]: hexpm/elixir Debian bookworm-slim base (glibc) required for ecto_sqlite3 NIF; Alpine/musl unsafe
- [Phase ?]: Plain unconditional re-seed in entrypoint — seeds.exs is delete_all + insert, inherently idempotent
- [Phase ?]: docker-compose.yml collocated in examples/phoenix_host/ so build: . and .:/app bind-mount align with .dockerignore
- [Phase ?]: INFOPLIST_FILE set inline in target-level Debug-Dev config (not xcconfig) to avoid xcconfig GUI-override precedence
- [Phase ?]: WKAppBoundDomains in Info-Dev.plist contains both example.com and localhost to prevent WebKit silent navigation refusal
- [Phase ?]: NSExceptionDomains key uses hostname localhost not 127.0.0.1 (ATS requires hostname not IP)
- [Phase ?]: prod flavor uses no suffix; no src/prod dir needed
- [Phase ?]: tools:replace on networkSecurityConfig attribute for minimal dev manifest overlay
- [Phase ?]: dev intent-filter omits android:autoVerify entirely to avoid App Links cascade failure on older APIs
- [Phase ?]: Parameter-expansion conditional UNIT_TEST_TASK/CONNECTED_TEST_TASK: examples/ uses prod-flavored tasks; template path uses unflavored tasks
- [Phase ?]: Source-derived port in guard test (committed_port/0 regex) closes 10.0.2.2 coverage gap
- [Phase ?]: Anti-vacuity: synthetic plist-with-NSExceptionDomains and dev-fixture-at-proof-domain cases prove guard assertions non-vacuous
- [Phase ?]: QUICK_START native labels placed within new section body to satisfy native_label_failures 1500-char window for all native host references
- [Phase ?]: bin/see-it-run.sh canonical; mix crosswake.demo is thin alias (D-01)
- [Phase ?]: Two exit codes only: 0=backend+banner, 1=backend boot failure; native never changes exit code (D-17)
- [Phase ?]: Banner in shell (not Elixir): plain-ASCII printf/heredoc, ANSI gated on TTY/NO_COLOR/CI (D-02)
- [Phase ?]: mix crosswake.demo resolved script path via __DIR__ walking three levels up to repo root
- [Phase ?]: Banner scan asserts leading-space home route line to avoid false JAVA_HOME substring match
- [Phase ?]: Anti-vacuity wrong-port case replaces localhost:PORT substring (not bare port) to avoid mutating JAVA_HOME path
- [Phase ?]: async: true for Phase 129 freeze test (read-only)
- [Phase ?]: MapSet.equal? callback freeze catches both additions and removals (D-12)
- [Phase ?]: Mix.Project.config()[:docs][:groups_for_modules] single source of truth for contract module list (D-15)
- [Phase ?]: Companion Contract groups_for_modules uses full module atom list
- [Phase ?]: guide+extras registered in same commit satisfying orphan-guard and empty-group prerequisite (moduledocs promoted in prior commit)
- [Phase ?]: Extension Authors extras group positioned between Truth and Advanced/Companions (D-10 distinct audience JTBD)
- [Phase ?]: Derived @banned_alias_parts from string names to avoid {:__aliases__} nodes in own module definition
- [Phase ?]: AST prune-then-walk is authoritative for EXTRACT-04 placement; belt retained as _belt_matches (not authoritative)
- [Phase ?]: Real-lib EXTRACT-03 assertion deferred to Plan 05 — rulestead.ex stays in lib/ until Plan 04 extracts it
- [Phase ?]: D-20: SC#1 adapter tests moved to companion lane; SC#3a/SC#3b doctor tests stay in core via StubRulesteadAbsentCompanion stub
- [Phase ?]: D-31: flag_source uses Application.get_env(:crosswake, :rulestead_flag_source) at runtime; dedicated key avoids :rulestead config map clash
- [Phase ?]: D-33: engine-present advisory lane via conditional elixirc_paths; fake Rulestead stub in test/engine_present/ compiled only with ENGINE_PRESENT_LANE=1
- [Phase ?]: D-25: script/extract_companion.md is parameterized 12-step extraction recipe proven on rulestead, reusable for rindle (Phase 132)
- [Phase ?]: CROSSWAKE_RELEASE=1 returns Hex dep; unset returns path dep
- [Phase ?]: independent elixir component, not in linked-versions, manifest 0.1.0, release-as 0.1.0 first-cut
- [Phase ?]: dress-rehearsal gate removed, hex_metadata.config dep-presence grep under CROSSWAKE_RELEASE=1
- [Phase ?]: D-07 per-component gate: rulestead_release_created not aggregate releases_created
- [Phase ?]: job-level CROSSWAKE_RELEASE=1 covers all mix steps in publish-hex-rulestead; plain mix test (no --exclude) for hermetic companion lane (D-10/D-13)
- [Phase ?]: Open Question 1 resolved: minimal use Phoenix.Router with no routes suffices for doctor --router (router_module!/1 only calls Code.ensure_loaded?)
- [Phase ?]: PROOF-02: needs:[release-please,publish-hex-rulestead] enforces clean-room runs after publish
- [Phase ?]: D-16: thin YAML delegates all proof logic to verify_companion_cleanroom.sh
- [Phase ?]: D-04 runbook: release-as removal after first Release PR merges, cross-ref Step 12f for rindle
- [Phase ?]: Phase 132 P01: rindle config.exs minimal — Rindle reads :crosswake/:rindle directly, no flag-source mock (unlike rulestead MockFlagSource)
- [Phase ?]: Phase 132 P01: crosswake_rindle CHANGELOG is a clean [Unreleased] skeleton, not core-inherited rulestead history — fresh 0.1.0 companion
- [Phase ?]: Phase 132 P03: rindle companion lane is engine-PRESENT (rulestead phase42 D-20 analog) not engine-absent; ~> 0.1 admits <1.0.0 so resolves real rindle 0.3.1; engine-absent seam coverage in core via StubRindleAbsentCompanion
- [Phase ?]: Phase 132 P03: media helpers in test/support/example_host/ are require_file-only (excluded from elixirc_paths) avoiding double-load; phase72 hermeticity self-scan asserts require_file basenames
- [Phase ?]: Phase 132 P03: phase72-proof.yml retired (standalone macOS); proof now runs in rindle companion lane via phase132-proof.yml on ubuntu-latest
- [Phase ?]: 132-02 compat-matrix drift test keys the requirement assertion on the pinned Requires-crosswake column (HTML-comment contract, D-12), exact-matching that cell only; a whole-row contains check false-passed because the Engine Dependency cell carries its own ~> 0.1 literal.
- [Phase ?]: Phase 132 P04: crosswake_rindle wired into release-please as a separate elixir component (release-as 0.1.0 one-shot), NOT in linked-versions lockstep — independent versioning (EXTRACT-07, D-01)
- [Phase ?]: Phase 132 P04: rindle_release_created/tag_name/version output aliases + gated publish-hex-rindle (CROSSWAKE_RELEASE=1, dry-run then publish) + clean-room-proof-rindle (needs publish) delegating to verify_companion_cleanroom.sh crosswake_rindle <ver> rindle Rindle
- [Phase ?]: Phase 132 P04: rindle Contracts.media_state_vocabulary/0 canary appended inside SMOKEEOF heredoc guarded by PACKAGE==crosswake_rindle (D-18); no new script param. Removed pre-existing stray MIX_VERSION echo from rulestead clean-room run (Rule 1)
- [Phase ?]: Elixir 1.19 includes optional callbacks in behaviour_info(:callbacks) — Phase 129 freeze test updated to include telemetry_events: 0 (same-PR pattern per test hint)
- [Phase ?]: events/0 uses private helper functions not module attributes for catalog construction — avoids stale-.beam footgun (D-05)
- [Phase ?]: D-19: guides/telemetry.md follows brandbook §14 concept order (10 sections)
- [Phase ?]: D-18: mix.exs Telemetry group in groups_for_extras and groups_for_modules; Offline.Telemetry discoverability-only
- [Phase ?]: Threadline :exception empty-metadata caveat documented; stop ⊇ start holds for :stop not :exception
- [Phase ?]: D-01 audit-then-prove: all 5 PROOF-03 SCs audited GREEN, no production-code change (Phase 135 plan 01)
- [Phase ?]: Q1 resolved: nested mix test for deferred-failure self-assertion; structural read cannot prove green (Phase 135 plan 01)
- [Phase ?]: @template_version shipped as epoch 2: stamp was genuine template change so bump 1->2 is correct
- [Phase ?]: router opt threaded through generate_ios/android_shell to capture --router flag in manifest params
- [Phase ?]: XML/plist stamp placed after <?xml ?> prolog to maintain well-formed XML
- [Phase ?]: @diff_excluded_templates = [project.pbxproj] only; gradlew/gradlew.bat are diffed (REVIEW FIX finding 6)
- [Phase ?]: run_diff/4 forks before any write — non-destructiveness is structural (D-13)
- [Phase ?]: file_advisory_verdict/1 reuses RebuildPolicy vocabulary without calling diff/2 (D-16)
- [Phase ?]: Rescue denial reason pinned to :dependency_missing (not :auth_evaluator_error) — single atom covers both failure modes for fail-closed auth evaluation
- [Phase ?]: Conflict signal as :telemetry.execute/3 event [:crosswake, :companion, :auth_authority_conflict] with first-registered-wins resolution for multiple auth_authority?/0 companions
- [Phase ?]: Backstop test 3 assertion fixed to check auth-denial absence (not decision.status) — empty Target always generates compatibility denials making status assertion unreliable
- [136-05]: Prefix-match guard via Enum.any?+List.starts_with? in function body (not when guard) — Elixir guards cannot call non-guard-safe functions
- [136-05]: Scope exclusion via list subtraction lib_files -- companion_files — Path.wildcard has no native negative-glob support
- [136-05]: policy/schema.ex mfa_level_vocabulary inlined as @mfa_level_vocabulary module attribute — stable 4-atom list; no runtime companion lookup needed for schema validation
- [Phase 136]: evaluate_auth/3 passes Denial.t() through unchanged (D-136-B); Finding conversion is Phase 137 SIGRA-02 work
- [Phase 136]: mix.exs application/0 env: registers [Sigra, Chimeway] as in-tree bridge; removed when each module is extracted in Phase 137/138
- [Phase 136]: DECOUPLE-03 RESOLVED in gap-closure 136-06 — the 3 Category-B failures (operator_inspection x2, publish_readiness x1) were fixed by registering the real Sigra facade in those tests' setup; full suite green, DECOUPLE-03 flipped Complete (REQUIREMENTS.md)
- [Phase ?]: D-137-A: evaluate_auth/3 callback returns {:deny, Finding.t()}; RouteGate owns Finding→Denial translation via finding_to_denial/2 (Plan 01)
- [Phase ?]: D-137-B: :auth clause in finding_to_denial/2; base_details guarded with cond so :auth passes finding.details UNMERGED (audit fix ①) (Plan 01)
- [Phase ?]: Plan 01 shim: sigra facade converts Denial to %Finding{axis: :auth} this wave; Plan 02 removes shim when Evaluator emits Finding natively
- [Phase ?]: SupportMatrix test moved to package - circular dep; put_env non-vacuity
- [Phase ?]: 8 core test files moved to crosswake_sigra package - sigra structs need module at compile/runtime
- [Phase ?]: chimeway resolver_test: expect :dependency_missing (fail-closed) when no auth-authority companion registered
- [Phase ?]: Independent versioning per D-8
- [Phase ?]: Additive no-engine script mode
- [Phase ?]: Sigra CI pipeline per-component gate
- [Phase ?]: circular-dep fix: removed crosswake_threadline path dep from core mix.exs; phase133 TELEM-04 rewritten to use telemetry.execute directly
- [Phase ?]: anti-drift D-5 test: core_baseline SUBSET union(companion forbidden_metadata_keys), non-vacuous, baseline count = 11 atoms post-139
- [Phase ?]: ledger.ex.eex: try/rescue crash-isolation in handler, on_conflict: :nothing, advisory row_hash/prev_hash moduledoc
- [Phase ?]: crosswake_threadline registered as independent elixir release-please component (NOT in linked-versions, one-shot release-as 0.1.0, THREAD-03)
- [Phase ?]: cleanroom script threadline-correct: companion-behaviour assertions suppressed; three module-shipment canaries (Telemetry/Plug/Ledger) + zero-sibling-dep invariant (T-139-11, THREAD-02)
- [Phase ?]: clean-room-proof-threadline: no-engine non-companion mode; installs crosswake + crosswake_threadline only (NOT sigra, NOT chimeway — T-139-18 zero-sibling-dep at CI level)

### Pending Todos

- None.

### Resolved In Current Phase

*(populated during execution)*

### Blockers/Concerns

- **WR-01 capability-axis Elixir coverage caveat (v14 carried, non-blocking).** The discriminating vec-014 floor proof runs native-only; `bridge_behavioral_vector_test.exs` hardcodes capabilities and evaluates it vacuously. Production `compatible_version?/2` is correct; native proof is green.
- **`MIRROR_PUSH_TOKEN` scope unexercised (carried open item).** Token's `Contents: write` scope is validated by the first iOS mirror on the NEXT release; if it 403s, regenerate the fine-grained PAT.
- **Branch-protection toggle (watch).** `register_required_checks.sh` scripts from prior milestones are committed but have not yet been run — maintainer must run to arm branch protection. Scheduled in Phase 140 (FAMILY-04) before new v17.0 lanes land.
- **Irreversible Hex publish risk (Phases 137/138/139).** Package names `crosswake_sigra`, `crosswake_chimeway`, and `crosswake_threadline` cannot be reclaimed once published. Phase 136 dress-rehearsal and per-phase `--dry-run` gate front-load this risk before any real publish.
- **`build_reserved_events/0` atomicity risk.** Moving from static module-attribute calls to runtime aggregation must be atomic — if sigra extracts before chimeway, a half-removal breaks the other. Phase 136 must complete the full runtime inversion before either companion is extracted.

## Deferred Items

| Category | Item | Status | Deferred At |
|----------|------|--------|-------------|
| v15.0 close | COLL-01 native screenshot binaries (iOS sim, Android emulator, montage) | Advisory-deferred — non-proof advisory native evidence; capture automation shipped but CI Android-emulator-on-macOS hangs and local capture is blocked by the Xcode-26-vs-published-package wall; standing D-03/D-19 maintainer gate. Web route-proof PNGs + COLL-02 GIF are committed. | v15.0 close |
| v8.0 gap | DASH-01: Surfacing offline adoption metrics | Deferred until companion family complete (crosswake_dashboard, unblocked by Phase 133 Telemetry public API) | v8.0 close |
| v8.0 gap | NTV-01: Extend storage budgets to native physical disk space | Deferred until after companion extraction | v8.0 close |
| v14.0 close | WR-01: Elixir capability-axis floor proof (vec-014) vacuous — discriminating proof native-only | Acknowledged — test-coverage gap, no production impact; native proof green | v14.0 close |
| v14.0 close | WR-02 / WR-03: latent unexercised native divergences | Acknowledged — bounded; inputs are generated well-formed semver | v14.0 close |
| v14.0 close | MIRROR_PUSH_TOKEN scope unexercised | Carried — validates on next release | v14.0 close |
| v16.0 tech-debt | TELEM-04 Side B vacuity (Phase 133) | Assessed: structurally near-impossible divergence; fragile fix; leave | v16.0 close |
| v16.0 tech-debt | companion_compatibility.md:51-54 prose (Phase 132) | Assessed: not a bug; leave | v16.0 close |
| v17.0 next | SYNCP-01: offline-sync productization | Deferred behind companion packaging | v17.0 plan |
| v17.0 next | SEED-002: capability/commerce breadth | Deferred behind companion packaging | v17.0 plan |
| Phase 139 P01 | 9m | 2 tasks | 19 files |
| Phase 139-crosswake-threadline-extraction P02 | 55min | 5 tasks | 21 files |
| Phase 139 P03 | 7 min | 3 tasks | 6 files |
| Phase 142 P02 | 5 min | 3 tasks | 2 files |

## Session Continuity

Last session: 2026-07-07T21:58:28.766Z
Stopped at: Completed 143-02-PLAN.md
Resume file: None

## Operator Next Steps

- Run `$gsd-plan-phase 143` using `.planning/phases/143-guarded-auto-publish-train/143-CONTEXT.md`.
- Keep downstream phase ownership honest: Phase 144, 145, and 146 must validate their already-present implementation spillover before being claimed complete.
- Do not perform Hex/package publish operations from this planning pass.

<!-- plan-phase override 2026-07-02: decision-coverage-plan gate returned reason=could-not-parse (0/13) — known parser brittleness on long-bold/embedded-colon D-NN bullets (project_decision_coverage_parser_brittleness). NOT a real gap: gsd-plan-checker Dimension 7 verified all D-01..D-18 covered (all PASS). Proceeded with override. -->
