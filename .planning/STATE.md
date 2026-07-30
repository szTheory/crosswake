---
gsd_state_version: 1.0
milestone: v20.0
milestone_name: Native Controls Pack 1
status: planning
stopped_at: Phase 155 context gathered
last_updated: "2026-07-30T03:49:15.647Z"
last_activity: 2026-07-30
progress:
  total_phases: 6
  completed_phases: 2
  total_plans: 15
  completed_plans: 14
  percent: 33
---

# Project State: Crosswake

## Project Reference

See: .planning/PROJECT.md (updated 2026-07-12 after v19.0 milestone completion)

**Core value:** Replace host-owned generated shell code with standalone SPM/Maven dependencies, enforcing strict delegate-based customization to eliminate the "eject trap" and boilerplate for adopters.
**Current focus:** Phase 155 — host owned fallback components

## Current Position

Phase: 155
Plan: Not started
Phase: 153.1 (ci-gate-integrity-and-runner-cost) — **COMPLETE** (3/3 plans)
Phase 153 (ios-mirror-unblock) — 3/4, **BLOCKED on a human gate**
Status: Ready to plan
Last activity: 2026-07-30

Progress: [██████████] 100% of Phase 154

## Blocked: Phase 153-02 (human gate, one-way door)

Mint the deploy key, fire-drill CI's push credential, backfill `v0.2.0`, re-baseline mirror
`main` (MIRROR-01). **The tag push is irreversible and must never be fired automatically —
it requires Jon's explicit go.**

Blocks Phase 156 (MENU). Everything else in the milestone can proceed without it.

Known state: the mirror is still at v0.1.2. The Phase 153 fire-drill was a NO-GO because
splitsh-lite v1.0.1 segfaults; the fix is switching `verify_ios_mirror_backfill.sh`
`compute_split_sha()` to `git subtree split` (verified working, split SHA `658d6025`).

## Phase 153.1 outcome (2026-07-29)

| | before | after |
|---|---:|---:|
| Wall-clock time-to-green | 34.9 min | **5.8 min** (target < 15) |
| Total queued | 21,600 s | 699 s |
| macOS jobs | 20 | 7 |
| Required contexts | 23 | 27 |
| Cache hit rate | — | 93 % |

Full measurements and honest attribution in
`.planning/phases/153.1-ci-gate-integrity-and-runner-cost/153.1-RESULTS.md`. The wall-clock
figure is partly confounded by ambient macOS runner availability; the durable attributable
number is billable-equivalent minutes, 550 -> 259.

Left on the table and recorded: the double compile (likely the largest remaining single
win), release-path cache keys with no OTP dimension, package-level caches for
chimeway/sigra, and all of `CONSOL-*`.

## v20.0 Roadmap Decisions (2026-07-12, locked)

- Milestone: **v20.0 Native Controls Pack 1**. Phase numbering continues from v19.0 (last phase 152.1) — starts at **Phase 153**, not reset to 1.
- 5 phases derived from the 7 requirement categories (MIRROR/CTRL/MENU/FALL/HRDN/EVID/PROOF), 21/21 v1 requirements mapped, no orphans:
  - **153 iOS Mirror Unblock** (MIRROR-01/02) — release-infra prerequisite, landed first because native bridge dispatch is a closed switch compiled into shipped binaries; the SwiftPM mirror stuck at v0.1.2 blocks every future native release from reaching iOS, mirroring the v17 core-first-publish lesson.
  - **154 The Control-Contract Seam** (CTRL-01..05, PROOF-04, HRDN-01) — the load-bearing machinery (`Bridge.push/3`, one typed `Shell.Denial`, closed-vocabulary guard, rebuild-class labeling) plus its own anti-drift structural test (PROOF-04) plus the cheapest real proof (HRDN-01, migrating already-native haptics onto the seam with zero native-side risk) — bundled together because HRDN-01 and PROOF-04 both validate the seam before any new capability is built on it, per research guidance to place them "with or right after CTRL, before MENU."
  - **155 Host-Owned Fallback Components** (FALL-01/02, PROOF-01) — the generated, verbatim-copy fallback tier and its route-tour proof, landed immediately after the seam since MENU's fallback path depends on it existing.
  - **156 Native Menu & Action-Button Control** (MENU-01..03, PROOF-03) — the first genuinely-new native control, the reply-path exemplar; depends on 153 (native release must reach iOS), 154 (seam), and 155 (fallback path).
  - **157 Harden, Promote & Prove Support Truth** (HRDN-02/03, EVID-01/02, PROOF-02) — haptics accessibility + iPad share-crash guard bundled with promoting share/notification_token to merge-blocking proof and the permissions.status/notification_token honesty pass, since the crash guard and docs honesty are both support-truth concerns for the same capabilities being promoted.
- Anti-vacuity discipline: every phase's success criteria are observable/falsifiable behaviors (a LiveView call receiving a reply, a denial shape, a CI test that can fail on a bad control, a native menu rendering) — no phase's criteria are satisfiable by a passing-but-vacuous test, per the v12.0 fabricated-proof lesson.
- Research source: `.planning/research/v20/SUMMARY.md`, `GROUND-TRUTH.md`, `RELEASE-STRATEGY.md` (read in full before roadmapping).

## v19.0 Closed (2026-07-12)

**Done:** all 7 phases verified passed; `/gsd-audit-milestone` PASSED after Phase 152.1 closeout repair (31/31 requirements, integration CLEAN, 6/6 flows); ROADMAP/REQUIREMENTS/AUDIT archived to `.planning/milestones/v19.0-*`; MILESTONES.md, PROJECT.md, ROADMAP.md, STATE.md, and RETROSPECTIVE.md evolved; REQUIREMENTS.md removed for the next milestone.

**Delivered:** Crosswake-owned showcase hub, AdminPilot SaaS/admin lane, Fieldserv field-service lane, LearnLoop subscription learning/training lane, deterministic fixture reset/proof, generalized browser route-tour evidence, public capability-map collateral, structural support-truth claim guards, and v20 Native Controls Pack 1 handoff.

**Accepted debt:** Phase 148 original numbered summaries were never created; the closeout preserves `148-SUMMARY-EXCEPTION.md` plus explicitly retroactive `148-RETRO-SUMMARY.md` rather than fabricating original-looking summaries.

## v19.0 Roadmap Decisions (2026-07-09, locked)

- Milestone: **v19.0 Showcase Apps & Capability Map**.
- Goal: make Crosswake feel like a polished, production-ready Phoenix mobile framework through seeded, click-around examples across realistic app domains, then convert the revealed gaps into a v20 Native Controls Pack 1 handoff.
- Phase ordering: 147 foundation and fixture reset → 148 demo app brand and fixture direction → 149 SaaS/admin lane → 150 field-service lane → 151 subscription learning/training lane → 152 capability map, proof, collateral, and v20 handoff.
- Brand direction: root remains Crosswake-owned; AdminPilot, Fieldserv, and LearnLoop are separate fictional demo app identities inside the single Phoenix example host.
- Selected GSD seed: **SEED-002** as strategic input for Phoenix-first native capability and commerce breadth. SEED-001 remains historical precedent; SEED-003/004 remain release-infrastructure carryovers, not v19 headline scope.
- Product arc sequence: v19 showcase evidence → v20 Native Controls Pack 1 → later capture/device controls, commerce/paywall productionization, operator dashboard, and offline-sync/native-storage productization unless v19 evidence reprioritizes the queue.
- Domain set: SaaS/admin, field service, subscription learning/training.
- Follow-on milestone: **v20.0 Native Controls Pack 1**, likely alert/confirm, menu/action-button affordances, haptics, share sheet, toast/review prompt, permission status, and notification-token UX integration, finalized by v19 evidence.
- Anti-scope: do not implement the full native-controls catalog, scanner/document-scan/biometrics/location/NFC production APIs, live commerce/paywall SDK support, `crosswake_dashboard`, or generic sync-engine behavior in v19.

## v18.0 Closed (2026-07-09)

**Done:** all 5 phases verified passed; `/gsd-audit-milestone` PASSED (15/15 requirements, integration CLEAN, 5/5 flows); ROADMAP/REQUIREMENTS/AUDIT archived to `.planning/milestones/v18.0-*`; MILESTONES.md, PROJECT.md, ROADMAP.md, STATE.md, and RETROSPECTIVE.md evolved; REQUIREMENTS.md removed for the next milestone.

**Delivered:** path-specific Release Please gates, non-canceling release workflow semantics, guarded CI Hex publishing with exact-ref recovery, exact companion/core-floor clean-room proof, doctor-owned fresh-router loading, iOS mirror credential/backfill guardrails, decoupled native proofs, and `mix crosswake.release.status [--json] [--live]`.

**Residual external risks:** real iOS mirror mutation still requires a correctly scoped maintainer `MIRROR_PUSH_TOKEN`; live registry probes remain advisory and are intentionally outside normal local/CI truth.

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

- Total plans completed: 198 (142 across v10.0-v17.0 + 15 in v18.0 Phases 142-146 + 5 in Phase 147 + 7 in Phase 149 + 7 in Phase 150 + 7 in Phase 151 + 4 in Phase 152 + 3 in Phase 152.1)
- Average duration: —
- Total execution time: —

*Updated after each plan completion*
**Per-Plan Metrics:**

| Plan | Duration | Tasks | Files |
|------|----------|-------|-------|
| Phase 154 P01 | 25min | 3 tasks | 13 files |
| Phase 154 P02 | 70min | 3 tasks | 33 files |
| Phase 154 P03 | 80min | 3 tasks | 12 files |
| Phase 154 P04 | 100min | 3 tasks | 8 files |
| Phase 154 P05 | 55min | 3 tasks | 7 files |
| Phase 154 P06 | 34min | 3 tasks | 24 files |
| Phase 154 P07 | 27min | 3 tasks | 22 files |
| Phase 154 P08 | 95min | 2 tasks | 11 files |

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
- [Phase 144]: Kept script/check_release_workflow_integrity.exs plus ExUnit as the authoritative PREF-03 proof instead of introducing a YAML parser or actionlint dependency. — The existing scanner already encodes Crosswake-specific release policy and stable operator-facing IDs, while Phase 144 scope explicitly forbids replacing it with a generic parser.
- [Phase 144]: Added Phase 144 umbrella IDs without replacing the existing Phase 142/143 scanner IDs. — Future operators and tests may still rely on historical stable IDs, while PREF-03 needs its own consolidated IDs.
- [Phase 144]: Required clean-room proof jobs to pass package/version as real script arguments, not loose job-block text. — A job-level string search could be satisfied by comments, labels, or env decoys; argument-order matching keeps PREF-03 non-vacuous.
- [Phase ?]: Phase 149 Plan 01 kept AdminPilot work intentionally RED-only: contracts now define fixture density, diagnostics, approval authority, and route-tour proof while implementation remains in later Phase 149 plans.
- [Phase 149 Plan 02]: AdminPilot static breadth remains deterministic fixture maps; mutable approval/activity persistence remains later-plan work.
- [Phase 149 Plan 02]: SaaS reset digest delegates static breadth to SaaSPortal.Fixtures.digest_components/0 so reset truth changes with fixture IDs, titles, and roles.
- [Phase 149 Plan 03]: AdminPilot diagnostics preserve raw compiled router policy fields beside user-facing support labels so diagnostics stay drift-proof and UI-ready.
- [Phase 149]: Approval mutation authority lives in SaaSPortal.Approvals with server-owned user/account scope and Ecto.Multi writes; LiveViews remain dispatch/render surfaces. — Satisfies T-149-11/T-149-12 and keeps native haptics secondary to Phoenix-owned approval state.
- [Phase 149]: Showcase reset digest now includes persisted approval/activity row counts and stable row components. — Keeps reset deterministic and makes mutable approval evidence visible to proof lanes.
- [Phase 149]: Persisted SaaS state remains limited to approval status and approval activity evidence; accounts, teams, members, roles, settings, and operational records remain deterministic fixture/read-context data. — Preserves D-08/D-10 and avoids widening AdminPilot into static SaaS persistence or a generic admin framework.
- [Phase 149]: AdminPilot UI shell is lane-local Phoenix.Component code, not a generic admin/resource framework. — Plan 149-05 preserves the Phase 149 scope boundary and keeps reusable admin-framework behavior out of the showcase lane.
- [Phase 149]: Diagnostics stay inline on AdminPilot pages and consume SaaSPortal.Diagnostics rows derived from compiled router metadata. — This satisfies SAAS-03 without adding a URL-addressable inspector route or crosswake_dashboard surface.
- [Phase 149]: Approval queue/detail RED contracts remain plan 149-06 scope; plan 149-05 keeps non-approval pages and shared shell complete. — The remaining full-suite failures are already bounded to approval_queue_live and approval_detail_live, which require the approval workflow UI planned next.
- [Phase 149]: Plan 06 keeps approval mutation authority in SaaSPortal.Approvals; LiveViews only load scoped data, dispatch events, and render outcomes.
- [Phase 149]: Plan 06 keeps haptics as optional post-success confirmation with route id, active route id, capability, command, and correlation id in the payload.
- [Phase 149]: The SaaS e2e session helper accepts only fixture user ids and delegates session creation to SaaSPortal.Auth.put_user_session/2; role/account params are ignored. — Preserves Crosswake's test-only e2e helper boundary without creating production auth, provider MFA, native auth UI, or admin-access semantics.
- [Phase 149]: LiveView browser proof uses standard Phoenix client assets and CSRF-backed sessions so approval clicks exercise real phx-click server events. — The route tour must prove server-owned LiveView behavior rather than bypassing clicks or weakening route-owner assertions.
- [Phase 149]: Route-tour screenshots remain collateral evidence after route-owner, support-truth, and typed bridge payload assertions pass. — Keeps browser proof semantic-first and aligned with Crosswake's route-policy/runtime-contract thesis.
- [Phase 150 Plan 01]: Fieldserv Wave 0 is intentionally RED-only; contracts now define fixture density, read contexts, evidence authority, diagnostics, component/CSS expectations, LiveView click path, route-tour proof, and capability-map pressure while implementation remains in later Phase 150 plans.
- [Phase 150 Plan 01]: Fieldserv route-tour evidence must prove route IDs, native capture metadata, cached read-only posture, backend verification, diagnostics, and no-overclaiming assertions before screenshots.
- [Phase 150 Plan 02]: Fieldserv static breadth remains deterministic fixture/read-context data; broad jobs/assets/templates are not persisted, and inspection offline behavior is future requirements text rather than shipped local mutation.
- [Phase 150 Plan 03]: Field Service now enters through product-first `/fieldserv/jobs` while legacy `/native/claims` remains secondary proof; diagnostics derive Fieldserv route facts from compiled router metadata and classify native/offline pressure without shipped-support claims.
- [Phase 150 Plan 04]: Fieldserv persistence is limited to append-only evidence events and current technician job state; device evidence is not media availability until backend verification transitions mark it verified.
- [Phase 150 Plan 05]: Fieldserv UI is lane-local and product-first; jobs/detail/inspection screens surface support truth inline while keeping inspection mutation server-recorded and offline-island behavior future-only.
- [Phase 150 Plan 06]: Fieldserv capture stays native-screen owned while evidence review keeps backend verification as the only availability authority.
- [Phase 150 Plan 07]: Fieldserv route-tour proof treats screenshots as collateral after semantic assertions; Fieldserv capability pressure remains capability-map evidence, not shipped runtime support.
- [Phase ?]: SSH deploy key (MIRROR_DEPLOY_KEY) replaces MIRROR_PUSH_TOKEN entirely in the backfill lane; HTTPS x-access-token branch removed, not deprioritized (153-01)
- [Phase ?]: Explicit-lease --force-with-lease="refs/heads/main:${current_main}" is the only push form that works in a never-fetched CI checkout; no git fetch was added anywhere (153-01, RESEARCH Q1)
- [Phase ?]: Ancestry guard distinguishes unknown-object (advisory, proceed) from known-non-ancestor (fail-closed) via cat-file -e before merge-base --is-ancestor (153-01, D-08/Q2)
- [Phase ?]: publish-ios-core: atomic + explicit-lease mirror push scoped to main alone (D-13), Hex-only gate (D-12), release-tag-pinned checkout (D-11), SSH transport via MIRROR_DEPLOY_KEY (D-03/D-04)
- [Phase ?]: release-failure-alert.needs extended to the four native jobs plus native-release-rollup (D-15); native-release-rollup exits 1 on partial native release (D-17)
- [Phase ?]: Six scanner checks rewritten/added in check_release_workflow_integrity.exs for D-11/D-12/D-13/D-15/D-17/D-03/D-04, each with a decoy test (D-20)
- [Phase ?]: 154-01: flipped published haptics vocabulary to family id (route policy declares families, bridge dispatches commands); fixed self-referential legacy_ids bug universally; added doctor legacy-capability-id advisory
- [Phase ?]: 154-02: Capability.@enforce_keys widened to [:id,:version,:rebuild,:interaction]; manifest_schema_version bumped 1.0.0->1.1.0; fixed two independently hardcoded schema-version literals (Activation.target_from_request/1, Compatibility.bridge_target/1) discovered mid-execution; doctor gains capability_rebuild_findings/1; capability map/support matrix/changelog surface rebuild+interaction cost
- [Phase ?]: 154-03: Crosswake.Bridge seam shipped (push/3, attach/1, on_mount/4, reserved-event + wiring-deadline interceptors); UndeclaredCapabilityError/NotMountedError raise loudly; Shell.Denial gains 14th reason :shell_unreachable; first self-contained Phoenix.LiveViewTest harness in core hermetic suite (test/support/bridge_live_view_case.ex)
- [Phase ?]: 154-04: Bridge exactly-once delivery hardened with per-mount epoch (embedded in correlation_id) + resolve/2 for fallback race + second reply-deadline timer + 5 new [:crosswake, :bridge, ...] telemetry events; Crosswake.Bridge.Test ships for hook-reply simulation without a shell
- [Phase ?]: D-16 resolved (human, 154-05 Task 1): option-b with amendment — merge-blocking catalog guard with an enumerated EIGHT-string seeded allowlist of out-of-vocabulary native denial reasons; zero native release coupling so D-01 holds; the five bare-String delegate seams named as a separately-labelled NON-MECHANICAL exclusion carried by SEED-008, never pretended into the allowlist
- [Phase ?]: Crosswake.Bridge.CatalogGuard lives in lib/ and reads Manifest.Builder's existing capability catalog — no second catalog file (D-42/D-43); a second one here would be five-way drift
- [Phase ?]: The hook ships from priv/static/crosswake.esm.js at the literal D-30 path — nesting under priv/static/crosswake/ would double the URL segment
- [Phase ?]: 154-08 Task 2: the phase's `checkpoint:human-verify` was REPLACED by merge-blocking automation, not deferred — shift-left per PROOF-03/Phase 135. Checks A–F ride the existing `npx playwright test` step (two scheme-scoped projects, `testMatch`/`testIgnore` so no lane's wall clock triples), G rides `merge-blocking-requires-example-host`, H is untagged in `test/crosswake/proof/`. No new required check name, no new workflow file (D-47). Proxies are labelled in each test's own docblock: C-partial, E-partial, F, G's "actionable" leg, H's synthetic-tree caveat.
- [Phase ?]: 154-08: `CatalogGuard.assert_catalog_closed!/1` gained an injection seam (`root:`, `commands:`, `command_capability_map:`, `catalog_capability_ids:`) with every default the real shipped value, so check H drives the REAL raiser through the six-step recipe rather than re-composing its predicates. Zero-arity gate unchanged.
- [Phase ?]: 154-08 KNOWN HOLE, pinned as an assertion: recipe step 1 (the catalog entry) is NOT mechanically caught — `check_attestation/3` has no mapping-to-catalog direction because ten shipped mappings legitimately have none. Recipe step 6 has fail-closed defaults rather than a red gate. Both stated in `phase154_recipe_followable_test.exs`, not papered over.
- [Phase ?]: reply_leg_vectors is its own top-level array, not an entry in vectors (which is a request-evaluation corpus both native harnesses feed through BridgeChannel.evaluate)
- [Phase ?]: D-03's iOS-reply-ships-with-Phase-156 statement lands as a generated Bridge Reply Delivery table, because guides/support_matrix.md is byte-generated from the renderer
- [Phase ?]: The doctor bridge-hook wiring finding is :advisory so the best-effort grep can never fail doctor's exit code (D-37)
- [Phase ?]: HRDN-01: the evidence panel renders from the envelope Bridge.push/3 actually built (Bridge.dispatched/2), never a hand-assembled second copy
- [Phase ?]: The HRDN-01 sweep asserts absence AND presence — no inline dispatch, plus >=2 seam call sites — so deleting the capability cannot satisfy the gate
- [Phase ?]: phase52_publish_readiness.json regenerated for the new CHANGELOG Unreleased subsections rather than watering down the entry or weakening the assertion

### Pending Todos

- None.

### Resolved In Current Phase

- Phase 148 Demo App Brand & Fixture Direction completed 2026-07-09: root showcase is Crosswake-branded, AdminPilot/Fieldserv/LearnLoop are fixed as fictional demo-app identities, fixture briefs define realistic density requirements, and route-tour/browser UAT passed.
- Phase 149 SaaS/Admin Showcase completed 2026-07-11: AdminPilot now has realistic fixture/read-context data, inline route-policy diagnostics, server-authoritative approval persistence, styled LiveView pages, gated e2e session proof, and browser route-tour evidence.
- Phase 150 Plan 01 completed 2026-07-11: Fieldserv RED contracts now define the jobs -> detail -> inspection -> native capture -> evidence review path, backend evidence states, cached-read-only/offline-honesty copy, and capability-map pressure evidence.
- Phase 150 Plan 02 completed 2026-07-11: deterministic Fieldserv fixtures and read contexts now provide jobs, assets, technicians, inspection checklist data, notes, evidence statuses, route posture, and capability-pressure rows without broad persistence.
- Phase 150 Plan 03 completed 2026-07-11: `/fieldserv/*` routes and route-derived diagnostics now expose LiveView jobs/detail/inspection/review, native-screen capture metadata, cached read-only posture, support labels, guide links, and capability-map pressure rows.
- Phase 150 Plan 04 completed 2026-07-11: narrow Fieldserv Ecto evidence/state persistence, backend-authoritative evidence transitions, and deterministic showcase reset/digest integration are complete.
- Phase 150 Plan 05 completed 2026-07-11: Fieldserv components, scoped styles, jobs queue, job detail, and inspection workspace now render the product-first lane with cached read-only posture, diagnostics, and a server-recorded inspection event action.
- Phase 150 Plan 06 completed 2026-07-11: Fieldserv native capture handoff and evidence review now complete the click path while preserving native ownership, permission truth, backend evidence authority, and cached read-only posture.
- Phase 150 Plan 07 completed 2026-07-11: focused Fieldserv/showcase ExUnit, full warnings-as-errors ExUnit, and Playwright route-tour proof now pass with semantic assertions before screenshots and capability-map evidence preserved.
- Phase 150 Field-Service Showcase completed 2026-07-11: FIELD-01 through FIELD-04 are verified across realistic jobs/assets/inspection/evidence data, native-screen capture pressure, backend-authoritative evidence review, cached read-only posture, route diagnostics, and browser proof.
- Phase 152 Plan 03 completed 2026-07-12: route-tour evidence now covers 33 manifest rows across the hub, AdminPilot, Fieldserv, LearnLoop, proof routes, native fallback, and capability pressure; reset proof keeps browser-owned state outside server reset; CI requires all captured screenshots and summarizes screenshots as collateral.
- Phase 152 Plan 04 completed 2026-07-12: README entry points link to the generated capability map, the planning-only v20 Native Controls Pack 1 handoff is written, final support-truth/reset/route-tour proof passed, and Phase 152 is complete.
- Phase 152.1 completed 2026-07-12: scanner/document_scan support truth now matches deferred capability posture, Phase 150 and 152 verification ledgers were reconstructed from fresh reruns, 149/150/151 validation metadata is refreshed, Phase 148's missing summary history is preserved as an accepted exception, and the v19.0 milestone audit rerun passed.

### Blockers/Concerns

- **WR-01 capability-axis Elixir coverage caveat (v14 carried, non-blocking).** The discriminating vec-014 floor proof runs native-only; `bridge_behavioral_vector_test.exs` hardcodes capabilities and evaluates it vacuously. Production `compatible_version?/2` is correct; native proof is green.
- **`MIRROR_PUSH_TOKEN` scope unexercised (carried open item).** Token's `Contents: write` scope is validated by the first iOS mirror on the NEXT release; if it 403s, regenerate the fine-grained PAT.
- **Branch-protection toggle (watch).** `register_required_checks.sh` scripts from prior milestones are committed but have not yet been run — maintainer must run to arm branch protection. Scheduled in Phase 140 (FAMILY-04) before new v17.0 lanes land.
- **Irreversible Hex publish risk (Phases 137/138/139).** Package names `crosswake_sigra`, `crosswake_chimeway`, and `crosswake_threadline` cannot be reclaimed once published. Phase 136 dress-rehearsal and per-phase `--dry-run` gate front-load this risk before any real publish.
- **`build_reserved_events/0` atomicity risk.** Moving from static module-attribute calls to runtime aggregation must be atomic — if sigra extracts before chimeway, a half-removal breaks the other. Phase 136 must complete the full runtime inversion before either companion is extracted.

### Quick Tasks Completed

| # | Description | Date | Commit | Status | Directory |
|---|-------------|------|--------|--------|-----------|
| 260719-nxm | Implement architecture and code walkthrough documentation | 2026-07-19 | bc79dde1 | Verified | [260719-nxm-implement-the-architecture-and-code-walk](./quick/260719-nxm-implement-the-architecture-and-code-walk/) |

### Roadmap Evolution

- Phase 152.1 inserted after Phase 152: Close gap: v19 support-truth and verification closeout (completed 2026-07-12)

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
| v17.0 next | SEED-002: capability/commerce breadth | Active strategic input for v19 capability map and v20 Native Controls Pack 1 handoff; implementation breadth remains deferred to v20+ | v17.0 plan |
| Phase 139 P01 | 9m | 2 tasks | 19 files |
| Phase 139-crosswake-threadline-extraction P02 | 55min | 5 tasks | 21 files |
| Phase 139 P03 | 7 min | 3 tasks | 6 files |
| Phase 142 P02 | 5 min | 3 tasks | 2 files |
| Phase 144 P01 | 9 min | 2 tasks | 3 files |
| Phase 144 P02 | 17 min | 2 tasks | 5 files |
| Phase 144 P03 | 21 min | 2 tasks | 2 files |
| Phase 145 P01 | 8 min | 2 tasks | 4 files |
| Phase 145 P02 | 3 min | 2 tasks | 3 files |
| Phase 145 P03 | 8 min | 3 tasks | 8 files |
| Phase 146 P01 | 34 min | 2 tasks | 3 files |
| Phase 146 P02 | 3 min | 2 tasks | 3 files |
| Phase 146 P03 | 5 min | 2 tasks | 6 files |
| Phase 147 P01 | 6 min | 2 tasks | 5 files |
| Phase 147 P02 | 5 min | 2 tasks | 2 files |
| Phase 147 P03 | 7 min | 3 tasks | 8 files |
| Phase 147 P04 | 9 min | 3 tasks | 7 files |
| Phase 147 P05 | 10 min | 3 tasks | 8 files |
| Phase 149 P01 | 7 min | 2 tasks | 5 files |
| Phase 149 P02 | 8 min | 2 tasks | 6 files |
| Phase 149 P03 | 6 min | 2 tasks | 2 files |
| Phase 149 P04 | 7 min | 2 tasks | 8 files |
| Phase 149 P05 | 13 min | 2 tasks | 10 files |
| Phase 149 P06 | 5 min | 2 tasks | 2 files |
| Phase 149 P07 | 18 min | 2 tasks | 7 files |
| Phase 150 P01 | 13 min | 3 tasks | 12 files |
| Phase 150 P02 | 4 min | 2 tasks | 2 files |
| Phase 150 P03 | 4 min | 2 tasks | 5 files |
| Phase 150 P04 | 4 min | 2 tasks | 7 files |
| Phase 153 P01 | 15min | 3 tasks | 5 files |
| Phase 153 P03 | 45min | 3 tasks | 5 files |

## Session Continuity

Last session: 2026-07-30T03:49:15.640Z
Stopped at: Phase 155 context gathered
Resume file: .planning/phases/155-host-owned-fallback-components/155-CONTEXT.md

## Operator Next Steps

- Start the next milestone with /gsd-new-milestone
