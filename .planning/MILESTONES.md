# Project Milestones: Crosswake

## v20.0 Native Controls Pack 1 (Stopped / Partial: 2026-07-30)

This milestone is recorded for history but is not a shipped release and has no completion tag.
Phases 153-155 produced retained release, CI, typed-bridge, and generated-fallback substrate.
Phases 156-157 were stopped because native-menu breadth and bundled support-promotion work do not
unblock the first real adopter's iPhone/offline path.

**Archive:**

- `.planning/milestones/v20.0-ROADMAP.md`
- `.planning/milestones/v20.0-REQUIREMENTS.md`
- `.planning/v20.0-MILESTONE-AUDIT.md`

---

## v19.0 Showcase Apps & Capability Map (Shipped: 2026-07-12)

**Phases completed:** 7 phases, 33 plans, 83 tasks

**Key accomplishments:**

- Shipped a Crosswake-owned first-screen showcase hub with deterministic reset/reseed truth and visible route-owner/support labels for all lanes.
- Turned the example host into three realistic demo-app lanes: AdminPilot for SaaS/admin, Fieldserv for field-service/device-pressure workflows, and LearnLoop for subscription learning/training.
- Kept runtime ownership honest across the showcase: LiveView-first flows, cached read-only/degraded posture, socketless offline study behavior, backend-owned entitlement pressure, native-screen capture handoff, and unsupported native gaps are visibly distinct.
- Added generalized browser route-tour evidence, reset proof, collateral manifests, and structural docs/support tests so screenshots remain collateral after semantic assertions pass.
- Published a typed capability map and generated guide that classify shipped, demoed, missing, deferred, and next-pack capabilities with package ownership and proof posture.
- Closed v19 audit gaps in Phase 152.1 by repairing scanner/document-scan support truth, reconstructing Phase 150/152 verification ledgers from fresh reruns, refreshing validation metadata, and preserving the Phase 148 summary exception honestly.

**Verification:** Milestone audit passed 31/31 requirements, 7/7 phases, 10/10 integration checks, and 6/6 E2E flows. Final closeout evidence included 96 support/capability/docs tests, 23 Fieldserv/showcase tests, Playwright route-tour proof, and `git diff --check`.

**Archive:**

- `.planning/milestones/v19.0-ROADMAP.md`
- `.planning/milestones/v19.0-REQUIREMENTS.md`
- `.planning/milestones/v19.0-MILESTONE-AUDIT.md`

---

## v18.0 Release Integrity & Automated Package Operations (Shipped: 2026-07-09)

**Phases completed:** 5 phases (142-146), 15 plans, 34 tasks
**Requirements:** 15/15 v1 satisfied (RELG-01..03, AUTO-01..03, PREF-01..03, MIRR-01..03, STAT-01..03). Audit `passed`; integration CLEAN (0 blockers, 5/5 flows).

**Delivered:** Made Crosswake's package-family release path automated, path-specific, and operator-visible before adding product breadth.

**Key accomplishments:**

- **Path-specific release graph:** Release Please publish/proof jobs now key off exact release identity and component paths, use non-replacing concurrency, and gate `release-as` cleanup on the relevant companion publish/proof success.
- **Guarded automated Hex publishing:** The happy path publishes from CI via `script/guarded_hex_publish.sh`; manual recovery is package-scoped, exact-ref, and idempotent for already-live versions.
- **Published-core clean-room proof:** Companion proof derives the required `crosswake` floor from exact Hex metadata, pins the just-published companion version, verifies `mix.lock`, and lets `mix crosswake.doctor --router` own fresh-router loading.
- **Native registry parity:** iOS mirror publishing now fails fast on missing/invalid `MIRROR_PUSH_TOKEN`; iOS and Android clean-room proofs are decoupled; maintainers have a guarded verify-first path to backfill the missing SwiftPM `v0.2.0` tag.
- **Release-status operator surface:** `mix crosswake.release.status` reports local package-family truth, workflow guard status, compatibility floors, stale pins, JSON output, stable exit behavior, and optional advisory live probes.
- **Scope discipline preserved:** DASH-01, SYNCP-01, NTV-01, and SEED-002 remain deferred until the next milestone is intentionally selected.

**Residual external risks:**

- Real iOS mirror mutation still requires a correctly scoped maintainer `MIRROR_PUSH_TOKEN` and the guarded backfill path.
- Live registry probes remain advisory; normal CI is local/read-only by design.

See `.planning/milestones/v18.0-ROADMAP.md`, `.planning/milestones/v18.0-REQUIREMENTS.md`, and `.planning/milestones/v18.0-MILESTONE-AUDIT.md` for full detail.

---

## v17.0 Companion Family Completion (Shipped: 2026-07-04)

**Phases completed:** 6 phases (136-141), 29 plans
**Git range:** `docs: start milestone v17.0` (15ec46bf, 2026-06-30) → v17.0 close (2026-07-04); 193 commits, 269 files (+24,240/−4,169)
**Requirements:** 20/20 v1 satisfied (DECOUPLE-01..06, SIGRA-01..03, CHIME-01..03, THREAD-01..03, FAMILY-01..05). Closeout type: `override_closeout` — verification was empirical (all four packages proven LIVE on Hex via `mix hex.info`; in-tree suites green through execution; the publish-gated plans' work re-homed to Phase 141). Phase 139 carries a formal `VERIFICATION.md` (passed); 137/138/140/141 closed on publish evidence. No `v17.0-MILESTONE-AUDIT.md` run (family provably live; audit is paper-trail only) — deferred by explicit choice.

**Delivered:** Finished the companion family — the three remaining in-tree companions extracted to standalone, independently-versioned first-party Hex packages, all LIVE on Hex: **`crosswake` 0.2.0** (core; +hexdocs +Android Maven) · **`crosswake_sigra` 0.1.1** (auth) · **`crosswake_chimeway` 0.1.0** (notifications) · **`crosswake_threadline` 0.1.0** (audit observer). Module names preserved throughout (`Crosswake.Companions.Sigra.*`/`.Chimeway.*`, `Crosswake.Threadline.*`) so extraction is non-breaking.

**Key accomplishments:**

- **Core decoupling via runtime registry inversion (DECOUPLE):** All four compile-time core→companion coupling sites (telemetry, route_gate, support_matrix, doctor) inverted onto a `:companions` registry seam using optional `@behaviour` callbacks + `function_exported?/3`. Core compiles `--warnings-as-errors` with no companion present; auth-predicated routes fail **closed** (`:dependency_missing`) when no `auth_authority?/0` companion is registered; a raising companion is rescued and denies. A curated universal PII floor (auth-token/session/identity) is always applied above per-companion runtime aggregation. (Gap-closure 136-06 resolved 34 regressions; full suite 1162/0.)
- **Three standalone extractions, non-breaking (SIGRA/CHIME/THREAD):** sigra emits `Crosswake.Compatibility.Finding` at its boundary (`Crosswake.Shell.Denial` stays core-private); chimeway proven sigra-free by a vacuity-safe clean-room lane (the "chimeway→sigra" dep was a myth — `auth_context: map()`); threadline observes purely via `:telemetry.attach_many` by event-name with a crash-isolated (`try/rescue`) append-only PII-free ledger, and decoupled its own 2 core compile sites atomically.
- **Family discipline (FAMILY):** O(N) compat-matrix rows (single `Requires crosswake >= X` column, no inter-companion columns) with drift guards; per-package Side-A "declared ⇔ emitted" telemetry contract tests (core's hardcoded `>= 24` count assertion replaced by a shape assertion); extraction recipe gained a "Step 0: core decoupling" prerequisite + all-`lib/` stale-reference grep guard; COMPANION-PUBLISH-RUNBOOK authored.
- **Core-first ordered publish (FAMILY-05):** Discovered mid-flight — companions compile against unpublished v17.0 core (`KeyError :code` from published core 0.1.2). Resolved by publishing **core `0.2.0` first** (a `release-as: "0.2.0"` pin forced the intended minor over release-please's pre-major `0.1.3` patch-bump), bumping every companion floor `~> 0.1` → `~> 0.2`, then publishing companions **sequentially** (one Release PR each, never batched) so each resolves against published core 0.2.0 — the real version-mismatch check the path-dep dress rehearsal could not catch.

**Recovery deviations (all resolved; family fully live):**

- sigra `0.1.0` first-publish failed on missing `ex_doc` (docs task) → re-cut `0.1.1`.
- threadline `0.1.0` publish failed `--warnings-as-errors` on a dead default arg (`render_durable/2`) → deleted dud tag, fixed via #70, re-cut clean `0.1.0` via #71; closeout #74 stripped the stale `release-as` pin + deduped CHANGELOG.
- clean-room proof harness (non-required/advisory) hit a chain of bugs — app-name hyphens (#64), mkdir-leaf (#67), and an OPEN doctor-router issue → **SEED-004**; resolvability proven (steps 1-6 green), publishes succeeded.

**Tech debt / follow-ups carried (non-blocking):**

- **SEED-003** — iOS SwiftPM mirror push 403: core `0.2.0` published to Hex + Android Maven, but the iOS split-repo tag was NOT mirrored (`MIRROR_PUSH_TOKEN` lacks push scope). iOS native adopters can't resolve 0.2.0 until the token is fixed and the mirror job re-run. User owns the token.
- **SEED-004** — clean-room proof harness doctor-router bug (advisory, non-required).
- Deferred future requirements: DASH-01 (`crosswake_dashboard`), SYNCP-01 (offline-sync productization), NTV-01 (native storage budgets), SEED-002 (Phoenix-first native breadth).
- Carried from prior milestones (non-blocking): TELEM-04 Side-B vacuity (assessed, deferred); WR-01/02/03 native-proof gaps.

See `.planning/milestones/v17.0-ROADMAP.md` and `.planning/milestones/v17.0-REQUIREMENTS.md` for full detail.

---

## v16.0 Companion Extraction & Package-Family Discipline (Shipped: 2026-06-30)

**Phases completed:** 7 phases (129-135), 24 plans
**Git range:** `docs(129)` context (2026-06-25) → `docs(v16.0)` origin-sync (2026-06-30); 2026-06-25 → 2026-06-30
**Requirements:** 27/27 v1 satisfied (SEAM-01..05, EXTRACT-01..07, COMPAT-01..03, PROOF-01..03, TELEM-01..04, LIFE-01a/01b/02a/02b/02c). Audit `passed`; integration CLEAN (0 blockers, 5/5 E2E flows).

**Delivered:** Turned the in-tree companion seams into real, independently-versioned, fail-closed first-party Hex-ready packages — proving the extraction pattern end-to-end on `rulestead` then `rindle` (both extracted and release-wired; neither has published to Hex yet) — and shipped the lifecycle, compatibility-matrix, and telemetry-as-public-API discipline a package family requires. Module names preserved throughout (`Crosswake.Companions.Rulestead`/`.Rindle`) so extraction is non-breaking.

**Key accomplishments:**

- **Frozen companion contract surface (SEAM):** Replaced the stale "companions live in-tree" framing with a frozen public-surface paragraph naming exactly the 5 public modules and asserting semver stability under `crosswake` >= 0.1.0 — the stable seam every extracted package depends on.
- **Extraction mechanics + footgun guards (EXTRACT/COMPAT):** `rulestead` then `rindle` extracted to standalone `packages/crosswake_*` Hex projects (own `mix.exs`, own `@version`, source + tests moved out of core, module names preserved). Stdlib-only AST guards (`check_source/1`, `check_ensure_loaded_placement/1` via `Macro.prewalk`) make EXTRACT-03/04 merge-blocking and non-vacuous; RouteGate gained `:dependency_missing` as a fail-closed Denial reason so an absent companion denies rather than crashes. A parameterized extraction recipe captured the pattern for the sigra/chimeway/threadline fast-follow.
- **Publish pipeline + clean-room proof (PROOF):** `publish-hex-rulestead`/`-rindle` and `clean-room-proof-*` lanes in `release-please.yml`, with companions carried as separate `elixir` release components (independent versioning, explicitly NOT in the core lockstep group).
- **Compatibility matrix + drift discipline (COMPAT):** `guides/companion_compatibility.md` documents each companion's minimum core version; a drift test keyed on the `Requires crosswake` column fails the build if the matrix and the `~> 0.1` requirement diverge.
- **Telemetry as public API (TELEM):** `Crosswake.Telemetry` public surface + opt-in PII-safe structured logger (core never auto-attaches), a declared `events/0` ↔ emission-site contract test, and `guides/telemetry.md` — the prerequisite for the deferred operator dashboard.
- **Generated-shell lifecycle + native UAT (LIFE):** `@template_version`/live-`crosswake`-version stamping with a drift test, `mix crosswake.shell.status` (N-versions-behind) and `mix crosswake.gen.shell --diff` (non-destructive), and `guides/native_shell_upgrade.md` per-version changelog; native shell generation promoted to a real UAT lane.
- **CI-Ops hardening — 0-human release ops (PROOF-03):** Fail-closed `release-as` staleness guard, auto-cleanup PR that strips stale pins on release, `if: failure()` alert issues on the publish/clean-room jobs, and parametric `register_required_checks.sh` / fail-closed `check_required_checks_registered.sh` superseding the per-gate scripts. A hermetic ExUnit proof pins all 5 CI-ops artifacts as merge-blocking (RED→GREEN via `GIT_DIR` injection, no production code changed).

**Tech debt carried (non-blocking, from audit):**

- **TELEM-04 Side B vacuity** (assessed, deferred) — emitted⇒declared can't catch an undeclared event because emission uses computed names and `:telemetry` has no wildcard handler; the declared set is built from the same source emitters use, so divergence is structurally near-impossible (0 undeclared confirmed). Not worth a fragile test on a green lane.
- **Compat prose** (`companion_compatibility.md:51-54`) — describes real engine-pin friction, not a contradiction with the requirement cell; drift test unaffected. Left as-is.
- Carried from prior milestones (non-blocking): WR-01/02/03 native-proof gaps, `MIRROR_PUSH_TOKEN` scope unexercised.

**Known ship-gates at close (one-time, human, milestone-boundary — not gaps):**

- Origin-sync (PR #40) — local `main` was a clean 64-commit superset of `origin/main`; merged 2026-06-30 (`029aa4a` + `f382291` origin-synced).
- **Register required checks** — provision `BRANCH_PROTECTION_READ_TOKEN`, run `DRY_RUN=0 script/register_required_checks.sh` once to register the 18 unregistered `merge-blocking-*` lanes. Admin-gated by design; **still pending.**

See `.planning/milestones/v16.0-MILESTONE-AUDIT.md` for the full audit.

---

## v15.0 See It Run — Experiential First-Run DX (Shipped: 2026-06-24)

**Phases completed:** 4 phases (125-128), 12 plans
**Requirements:** 16/18 v1 fully satisfied; COLL-01 accepted as advisory-deferred (1 requirement, advisory native evidence). DOCKER-01..05, PORT-01..03, NDEV-01..03, LAUNCH-01..02, DOCS-01..03, COLL-02 complete.

**Delivered:** Made it trivial and delightful for a newcomer to boot the web, iOS-simulator, and Android-emulator views of Crosswake against one shared backend and compare them — one-command Dockerized backend, static port convention, additive native dev-wiring, a human-voiced launch banner, and a reader-empathy guide.

**Key accomplishments:**

- **One-command shared backend (DOCKER/PORT):** `docker compose up` boots the demo backend at `http://localhost:4700` from a clean checkout (no local Elixir/Node/SQLite) — multi-stage cached-deps Dockerfile, polling live-reload over bind-mounts, SQLite in a named volume, lean `.dockerignore`. A committed static port convention (Crosswake = 4700 via `COMPOSE_PROJECT_NAME` + `.env`) is reachable by web/iOS (`localhost:4700`) and Android emulator (`10.0.2.2:4700`), with a reusable `docs/PORT-REGISTRY.md`; the native `mix` path is preserved.
- **Additive native dev-wiring (NDEV):** `mix crosswake.contract.gen --dev` emits iOS + Android dev route-activation fixtures; an additive iOS `Dev` scheme (`Debug-Dev` + `Info-Dev.plist` localhost ATS) and Android `dev` flavor (10.0.2.2 cleartext) point at the local backend, with a source-derived proof-posture guard proving the checked-in prod fixtures/assets/Info.plist are byte-untouched.
- **Launch orchestration (LAUNCH):** `bin/see-it-run.sh` (+ thin `mix crosswake.demo`) boots or reuses :4700 behind a curl readiness gate and prints a plain-ASCII brand-voiced banner with the three honest routes, an explicit proven/needs-build block, and verbatim per-runtime native commands; advisory sim/emulator launch never changes the web-success exit code. A source-derived banner drift guard locks the facts to their sources.
- **Reader-empathy docs (DOCS) + collateral (COLL):** `guides/see_it_run.md` (gameplan-at-top, JTBD-driven) routed from README/QUICK_START and guarded by source-derived doc-contract tests; honest support-truth labels throughout. COLL-02 screen recording (`see-it-run.gif`, vhs terminal-cast) shipped; web route-proof PNGs committed. The collateral capture pipeline (`see-it-run-collateral.yml` + merge-blocking drift guards) is shipped.

**Known deferred items at close (advisory, non-blocking):**

- **COLL-01** native screenshot binaries (iOS simulator, Android emulator, three-runtime montage) accepted as **advisory-deferred** — they are advisory native evidence (non-proof), and could not be produced reliably: CI Android-emulator-on-macOS capture hangs (now bounded by `timeout-minutes`), and local capture is blocked by the Xcode-26-vs-published-`crosswake-shell-core@0.1.2` wall. Capture automation is shipped for opportunistic future runs; the binaries remain the standing D-03/D-19 maintainer capture gate.
- Carried from prior milestones (non-blocking): WR-01/02/03 native-proof gaps, 2 unrun `register-*-gate.sh` branch-protection PATCHes, `MIRROR_PUSH_TOKEN` scope unexercised.

See `.planning/milestones/v15.0-MILESTONE-AUDIT.md` for the full audit.

---

## v14.0 Runtime Contract Confidence (Shipped: 2026-06-21)

**Phases completed:** 4 phases (121-124), 17 plans, 27 tasks
**Git range:** `feat(121-01)` (e2c2d04) → `docs(124)` close; 103 files changed (+14,002 / -118); 2026-06-20 → 2026-06-21
**Requirements:** 18/18 v1 satisfied (CANON-01..05, GUARD-01..04, NTEST-01..04, COMPAT-01..05); audit `tech_debt` (no blockers). Nyquist coverage full (4/4 phases).

**Delivered:** Made the bridge/runtime contract boringly canonical and hard to drift — coherence work, not feature breadth — then proved it directly in the reusable native packages.

**Key accomplishments:**

- **Canonical contract source (CANON):** A single Elixir constant (`Crosswake.Bridge.Contract.version/0`) is the sole declared bridge-protocol literal; `mix crosswake.contract.gen` renders it into JSON fixtures, generated shell templates, native conformance vectors, and a docs snippet (idempotent). The `1.1.0`/`1.0.0` divergence was resolved without breaking the published `crosswake 0.1.x` contract, and the silent Kotlin `?: "1.0.0"` fallback was removed.
- **Drift guards (GUARD):** A browser-free merge-blocking ExUnit drift test reads every committed surface via `Jason.decode` (never text grep) and asserts equality to the canonical version, naming the one file to edit + regenerate command on failure (proven non-vacuous with synthetic regressions); plus a generate-and-diff CI check, a `contract_version_parity` doctor sibling check, and a required-vs-advisory aggregator with registration scripts.
- **Native behavioral proof (NTEST):** The reusable iOS `crosswake-shell-core-ios` (XCTest, no simulator) and Android `crosswake-shell-core-android` (JUnit, no emulator) packages gained real tests for activation, bridge denial, capability allowlist, active-route, pack-version, and delegate/escape-hatch — all driven from one committed `bridge_contract_vectors.json` so a single version bump fails all three suites. CI lane is Android-blocking + iOS-advisory.
- **Floor compatibility reconciliation (COMPAT-01):** Hand-ported `SemVer.compatible(provides:demands:)` into both native packages and converted every version-equality site to `>=` min-version-floor across Elixir and native, eliminating the exact-equality denial footgun — proven by the discriminating vec-014 (request `1.1.0` > session `1.0.0` allows under floor, denied under old `==`) on iOS + Android.
- **Adopter truth (COMPAT-02..05):** A canonical `rebuild_decision_table/0` (axis → rebuild-class) rendered into the support matrix and a decision-table-first `guides/compatibility.md`; an advisory doctor `compatibility_rebuild_guidance` check naming the full regenerate→rebuild→resubmit→deploy sequence (never `:error`); and per-release CHANGELOG `### Upgrade Impact` labels with a CONTRIBUTING intent-gate.

**Known deferred items at close (non-blocking tech debt, carried forward):**

- **WR-01** — the discriminating capability-axis floor proof (vec-014) runs native-only; the Elixir `bridge_behavioral_vector_test.exs` harness hardcodes capabilities and evaluates it vacuously. Test-coverage gap only — `compatible_version?/2` is correct and native proof is green. Fix: tag vec-014 `native_only` or teach the Elixir harness to honor `request_override.capabilities`.
- **WR-02 / WR-03** — latent, unexercised native divergences (Android vs iOS malformed-`@` pack parser; `SemVer.compatible` identical-garbage fallback returns true). Bounded; all current inputs are generated well-formed semver.
- Two committed `register-*-gate.sh` branch-protection PATCHes (`register-contract-gate.sh`, `register-native-gate.sh`) are documented but unrun by design — a maintainer must run them to arm branch protection.
- 4 pre-existing docs-debt test failures (HexPage×2, Phase48, Phase69) predate v14.0; `MIRROR_PUSH_TOKEN` scope remains unexercised; 2 cosmetic "four surfaces" stale comments (actual is 6).

See `.planning/milestones/v14.0-MILESTONE-AUDIT.md` for the full audit and `.planning/RETROSPECTIVE.md` for the milestone retrospective.

---

## v13.0 Adopter Confidence & Native Evidence (Shipped: 2026-06-19)

**Phases completed:** 5 phases, 16 plans, 32 tasks

**Key accomplishments:**

- Schema-aligned Flashcards tests and deterministic Chimeway notification-open fixtures remove TODO-001 from the public proof path
- Crosswake 0.1.2 release truth is now reflected in public docs, example metadata, manifests, and first-read proof-path labels
- Release-truth drift is now guarded by deterministic ExUnit coverage over public docs and example manifests
- Route-owner-first guide and docs-contract test make Crosswake's route-policy mental model explicit
- Phoenix SaaS route-inventory guide defaults to LiveView and promotes only for explicit owner reasons
- Support-truth labels and public guide navigation now make the route-owner docs first-class
- The quick start now runs the Phoenix host on port 4002 and proves the current offline and bounded-bridge architecture without native overclaim
- The adoption guide now teaches the real app-owned IndexedDB outbox, reconnect flush, and Phoenix/Ecto replay path
- Quick-start and adoption guide truth is now guarded by source-derived ExUnit docs-contract tests
- Checked-in native hosts now resolve published coordinates by default and label themselves as checked-in public-coordinate proof
- Public native docs and the canonical support matrix now speak one evidence-label language
- A source-derived ExUnit scanner now blocks stale native coordinates and missing evidence labels
- Merge-blocking browser route-tour proof now verifies route ownership semantically before uploading collateral screenshots.
- Route-tour evidence now ships as a validated run-level manifest with fail-closed CI artifact packaging.
- Advisory iOS simulator and Android emulator collateral now records captured or unavailable native evidence without promoting support claims.
- Route-owner-first troubleshooting now maps doctor findings, denials, native evidence labels, and offline outcomes to concrete owner actions.

---

## Document Truth Precedence

For shipped-state questions, use this order: `MILESTONES.md` curated shipped-state truth > `PROJECT.md` Requirements marks > `v*-MILESTONE-AUDIT.md` point-in-time snapshots. `PROJECT.md` Requirements marks remain active-project truth and must cite verification or CI evidence; audit files preserve the evidence available at the time they were written.

## v12.0 CI Honesty & Real-E2E Sweep (Shipped: 2026-06-18)

**Phases completed:** 4 phases (112-115), 13 plans, 15 tasks
**Git range:** `feat(112-01)` -> `docs(phase-115)` / audit close; 22 non-planning files changed (+1,686 / -260); 2026-06-17 -> 2026-06-18

**Delivered:** Made the offline-sync and closeout proof surfaces honest: real IndexedDB outbox -> reconnect flush -> Ecto proof, merge-blocking E2E aggregator with structural honesty guard, fail-closed closeout verifier, evidence-backed historical ledgers, and canonical v8.0 document truth.

**Key accomplishments:**

- Replaced the fabricated offline-sync proof with a real UI-driven flow: clicking `#btn-good` queues an IndexedDB mutation, CDP reconnect plus an explicit `online` event triggers the app's `flushOutbox`, Ecto confirms the app-generated mutation ID, and duplicate POST proof verifies idempotency.
- Added `MIX_ENV=test mix compile --warnings-as-errors` before Playwright so demo-app compile breaks fail as compile errors instead of port-connection noise.
- Promoted the offline-sync E2E lane into an Option-C merge-blocking aggregator and documented/scripted the branch-protection registration path.
- Shipped GUARD-01 (`script/check-e2e-honesty.mjs`) to ban the three known fabrication shapes and GUARD-02 tests proving `/_e2e` routes stay test-only and count-scoped.
- Hardened `CloseoutVerifier` so malformed `expected_phases` contracts and bare validation ledgers fail closed while preserving report-first Mix diagnostics.
- Closed historical validation-ledger debt with evidence-backed v3.8/v3.9 ledgers and one explicit accepted v3.6 exception.
- Established the document-truth precedence rule, added the curated v8.0 shipped-state entry, and annotated the old v1.0 audit snapshot without overwriting its original 0/10 context.

**Known deferred items at close:** 1 — TODO-001 for pre-existing example-host `FlashcardsTest` field drift and flaky `Chimeway.RegistryNotificationOpenTest`, surfaced by Phase 112 and left as a standalone cleanup candidate.

**Archive:**

- `.planning/milestones/v12.0-ROADMAP.md`
- `.planning/milestones/v12.0-REQUIREMENTS.md`
- `.planning/milestones/v12.0-MILESTONE-AUDIT.md`
- `.planning/milestones/v12.0-phases/`

---

## v11.0 Release & Distribution Truth (Shipped: 2026-06-17)

**Phases completed:** 2 phases (110-111), 8 plans, 13 tasks
**Git range:** `feat(110-01)` → release `0.1.2` · 81 commits · 2026-06-14 → 2026-06-17

**Delivered:** The first lockstep release — `crosswake 0.1.2` shipped to Hex + Maven Central + the SwiftPM mirror from one release-please run, making the v5.0 standalone-package thesis genuinely consumable by an adopter outside the monorepo.

**Key accomplishments:**

- Native cores published & lockstep-versioned: iOS SPM core auto-mirrored to `szTheory/crosswake-shell-core-ios` (splitsh-lite subtree, annotated semver tags), Android core to Maven Central under verified `io.github.sztheory` (signed POM via Vanniktech → Central Portal), with release-please `linked-versions` advancing all three registries to one version per release.
- Credential provisioning hardened: an 8-section one-time SETUP runbook (GPG primary-key-only, Sonatype user tokens, empty iOS mirror repo, least-privilege `MIRROR_PUSH_TOKEN`, tag ruleset) plus a permanent dispatch-only Android fire-drill (preflight → local asserts → validated-upload → DROP) and a lockstep-truth assertion, so the first publish couldn't silently fail or burn an immutable version.
- Generator rewired to published coordinates: `mix crosswake.gen.shell` injects the live `Application.spec(:crosswake)[:vsn]` into iOS/Android dep coordinates at generate-time — no hardcoded version literal, default output references the published coordinates, local scaffold mode preserved.
- Clean-room proof + permanent parity guard: a CI lane scaffolds a host in `$RUNNER_TEMP` outside the monorepo and proves `swift build` / `gradle build` resolve the *published* deps and compile; a merge-blocking `generator_coordinate_parity` readiness check keeps generated coordinates version-matched and pointed at resolvable artifacts.
- Docs reconciled to install truth: `guides/adoption.md`, `guides/support_matrix.md`, and `CHANGELOG.md` now point at the published-coordinate generator path with no 404 install route or monorepo-only claim.
- 0.1.2 cut live (REL-01): Release PR #8 merged; the first live run exposed and fixed latent pipeline bugs (fire-drill artifact assertion, Android auto-publish flag, Central Portal poll auth/endpoint, splitsh-lite version), and the one-time `release-as` pin was removed post-cut.

**Known deferred items at close:** 3 (see STATE.md Deferred Items) — all already-acknowledged carry-overs or stale audit false-positives from a milestone that shipped and is verified live.

---

## v10.0 Brand Normalization (Shipped: 2026-06-14)

**Phases completed:** 3 phases (107-109), 10 plans, 10 tasks
**Git range:** `feat(107-01)` → `fix(109)` · 74 files changed (+9,509 / −368) · 2026-06-13 → 2026-06-14

**Delivered:** `tokens.css` became the genuine single source of truth for the brand system — generated for font/dimension as well as color, distributed through one documented path, consumed by both drifted consumers via semantic custom properties, and protected from regression by a deterministic CI drift gate.

**Key accomplishments:**

- Extended `compile-tokens.js` to emit `font.*` and `dimension.*` tokens (type/display scale, radius) from `crosswake.tokens.json`, plus a byte-identical `priv/static/crosswake/tokens.css` package mirror from one generator run (TOKN-04, TOKN-05).
- Established one documented distribution mechanism (vendor-by-copy + link, `guides/tokens.md` in ExDoc extras) with no hand-maintained duplicate palettes (NORM-03).
- Normalized the example host: removed the flat primitive palette and inline font stacks, remapped all values to semantic `--cw-*` tokens; dark mode works with zero extra `app.css` (NORM-01).
- Rewrote the `offline_ui` generator off Tailwind onto a vendored `offline.css` with semantic `.cw-offline-*` classes and retired the stale hardcoded legacy theme in `crosswake.gen.offline_ui.ex` — no Tailwind dependency in the host (NORM-02).
- Rewrote the generator test to pin the semantic-token contract (asserts `var(--cw-*)`, forbids retired Tailwind class names) (NORM-04).
- Shipped a browser-free `brand-structural` drift gate (`check-consumer-drift.mjs` + contract tests + CI wiring) that fails the build on any reintroduced brand hex or dropped token reference; plus a D-13 Playwright/Chromium render-verify gate with WCAG measurement and human sign-off (PROOF-01).

**Known deferred items at close:** 1 — `tighten-validation-ledger-closeout-gate` quick task (pre-existing, acknowledged at v8.0 close; see STATE.md Deferred Items).

---

## v9.0 Brand System & Visual Identity (Shipped: 2026-06-13)

**Phases completed:** 5 phases (102-106), 16 plans

**Key accomplishments:**

- **Brand audit + frozen design tokens** (P102): 14-section AUDIT.md with pinned Wake Mark geometry, a WCAG 2.2 contrast matrix, and a DTCG token system (`crosswake.tokens.json` → `tokens.css`, primitive→semantic→state tiers incl. runtime-semantic tokens) ratified by the maintainer.
- **Logo system** (P103-104): seven-candidate tournament → user-selected mark → full path-only production SVG suite (8 marks/lockups) with the wordmark generated from Space Grotesk outlines via opentype.js.
- **Standalone HTML brand book + spec** (P105): zero-build `brandbook/index.html` (10 sections, live WCAG contrast badges, copy-hex, scroll-spy) and the audited `BRAND-SPEC.md` v1.0.
- **Collateral + repo integration** (P106): light/dark README headers, social card, favicons; README `<picture>` + ExDoc logo wired; `brandbook/` excluded from the Hex package; committed size held < 1 MB.
- **Shift-left brand UAT into CI** (COLL-05): self-contained Playwright suite (`brandbook/e2e/`, 19 checks) replacing manual brand UAT, promoted to a hybrid gate (`brand-structural` required, `brand-visual` advisory). It caught and fixed a real mobile table-overflow defect that manual render-verify had tolerated.
- **Release hygiene**: added the pending CHANGELOG `[0.1.2]` section, flipping `doctor --check-publish` from `not_ready` → `ready`.

**Known deferred items at close:** 1 — quick task `260603-nzr-tighten-validation-ledger-closeout-gate` (pre-existing v4.0 closeout-verifier ledger debt; see STATE.md Deferred Items).

---

## v8.0 Offline Sync Hardening and UI Polish (Shipped: 2026-06-11)

**Phases completed:** 99-101

**Delivered:** v8.0 hardened the offline-sync proof surface with real network toggling, advisory runtime storage budgets, and a consolidated offline UI while keeping offline claims scoped to the existing Phoenix-first offline island contract.

**Key accomplishments:**

- Real network toggling: Playwright coverage used browser network-offline behavior rather than localStorage-only mocks for the offline study island.
- Advisory runtime storage budgets: the offline contract and generated UI surfaced storage-budget expectations with standard browser APIs and quota-error handling.
- Consolidated offline UI: the host-owned `OfflineController` path generated a single brand-aligned offline surface without LiveView websocket coupling.
- Shipped-state reconciliation: accepted verification debt from the 2026-06-11 audit was carried forward honestly and later addressed by v12.0 proof-honesty work.

**Known deferred items at close:** accepted verification debt for phases 99-101 was recorded in `v1.0-MILESTONE-AUDIT.md` and carried into the v12.0 closeout/doc-truth sweep.

---

## v6.0 Adoption Evidence Demo App (Flashcard Cohort) (Shipped: 2026-06-09)

**Delivered:** A flashcard language-learning demo app that exercises the full `Crosswake.Offline` island philosophy end-to-end — online LiveView dashboard, downloadable content packs, a vanilla-JS offline study engine over IndexedDB, and server-side sync reconciliation on reconnect.

**Phases completed:** 84-90 (7 phases, 9 plans)
**Stats:** 51 files modified (+2727, -32 LOC), 2026-06-08 → 2026-06-09

**Key accomplishments:**

- Defined `Crosswake.Offline.ContentPack` as a strongly-typed struct enforced at the route-policy boundary and compiled into the root manifest's pack registry.
- Defined `Crosswake.Sync.EventLog.Entry` plus a `mix crosswake.gen.sync` task that scaffolds host-owned Ecto schema + Phoenix reconciliation controller with idempotency keys.
- Scaffolded the Flashcard domain (Decks/Cards/Progress) with `binary_id` keys for offline-sync compatibility, Phoenix context, migrations, and demo seeds.
- Built brand-aligned `DeckLive.Index`/`DeckLive.Show` LiveViews wired through the router with `crosswake_defaults` policy, plus a vanilla-JS offline study engine wrapping IndexedDB.
- Connected the offline island to the native shell, applied Brand Book CSS/UI polish, and proved the offline-study loop with network-toggling Playwright E2E tests asserting Ecto sync state post-reconnect.

**Known issues fixed at close:** The demo app's `OfflineController`/`OfflineHTML` (Phase 88) used a non-existent `CrosswakeExampleWeb` macro module and were never wired into the router, breaking compilation — hidden by the mocked Playwright closeout. Fixed to the app's plain-Phoenix convention; `mix test` now passes 15/15.

**Known deferred items at close:** 2 (see STATE.md Deferred Items) — Phase 81 verification gap (human_needed, carried from v5.1) and the `tighten-validation-ledger-closeout-gate` quick task.

---

## v5.1 Adoption Evidence Demo App (Shipped: 2026-06-09)

**Phases completed:** 4 phases, 8 plans, 6 tasks

**Key accomplishments:**

- Task 1
- Implemented native Android Flow publishers for connection state and server events, wired cleanly to Compose overlay and toast elements.
- Implemented native iOS Combine publishers for connection state and server events, wired cleanly to SwiftUI overlay and toast elements.
- Implemented RouteDelegate and capability reporting in iOS and Android shell cores with fail-closed native routing

---

## v5.0 Standalone Publishable Shell Packages (Shipped: 2026-06-06)

**Phases completed:** 76-79 (4 phases, 11 plans)
**Stats:** 96 files modified (+4452, -3497 LOC)

**Key accomplishments:**

- Extracted iOS core logic into standalone Swift Package Manager dependency.
- Extracted Android core logic into standalone Maven Central artifact.
- Replaced raw object generation with unified builder and reactive state APIs.
- Updated generator tooling to output thin dependency-driven host projects.
- Verified all new libraries and generators are hermetic via closeout lane.

**Known deferred items at close:** 3 (see STATE.md Deferred Items)

**Archive:**

- `.planning/milestones/v5.0-ROADMAP.md`
- `.planning/milestones/v5.0-REQUIREMENTS.md`

## v4.1 Multi-SaaS Archetype Proof Lanes (Shipped: 2026-06-05)

**Phases completed:** 6 phases, 13 plans

**Key accomplishments:**

- Proved an end-to-end subscription SaaS commerce corridor using mock storefront adapters, ensuring entitlement projections are strictly backend-promoted.
- Validated a notification-driven workflow, verifying Chimeway push-token binding connects cleanly with Sigra session state and RouteGate enforces auth checks on deep-links without silent fallbacks.
- Verified a media/evidence capture workflow using Rindle reconciliation to recover from degraded network failures, keeping local capture signals non-authoritative.
- Proved an auth-sensitive admin workflow by triggering Sigra step-up ceremonies, ensuring native shell session persistence requires handoff tickets for administrative routes.
- Proved an offline/draft recovery workflow that enforces explicit `:cached_read_only` and `:local_first` policies, rejecting generic universal sync abstractions.
- Ensured all E2E archetype proofs run hermetically in CI without requiring manual device verification.

**Verification:** Milestone closeout (`.planning/milestones/v4.1-CLOSEOUT.md`) passed all checks, enforced by `mix closeout.verify`.

**Archive:**

- `.planning/milestones/v4.1-ROADMAP.md`
- `.planning/milestones/v4.1-REQUIREMENTS.md`
- `.planning/milestones/v4.1-CLOSEOUT.md`

---

## v4.0 Production Shell Runtime Line (Shipped: 2026-06-04)

**Phases completed:** 6 phases, 18 plans

**Key accomplishments:**

- Established the Runtime-Line Policy Contract and Support-Truth Taxonomy.
- Shipped the Diagnostic Export Seam in Elixir.
- Fixed Xcode 26 CI and updated Generator Templates.
- Implemented Native Shells with Android JVM Hermetic Proof.
- Reached Android Verification Closure and Device-UAT.
- Executed the Docs-Contract Parity Gate, Android Promotion, and Closeout.

**Verification:** Milestone closeout (`.planning/milestones/v4.0-CLOSEOUT.md`) completed.

**Archive:**

- `.planning/milestones/v4.0-MILESTONE-AUDIT.md`
- `.planning/milestones/v4.0-CLOSEOUT.md`

---

## v3.9 Chimeway Notification Seam (Shipped: 2026-06-03)

**Phases completed:** 5 phases, 17 plans, 12 tasks

**Key accomplishments:**

- Chimeway contract-only companion entrypoint with provider-neutral token evidence and backend-owned token binding contracts (TOKN-01/02); raw bridge token evidence redacts into Chimeway contracts and is excluded from telemetry, fixtures, denials, and docs
- Host-owned Phoenix registry for binding, rotation, logout/session revocation, permission loss, provider invalidation, and staleness pruning via `Ecto.Multi` with safe audit rows and post-commit telemetry (TOKN-03)
- Notification-open resolver that routes opens through manifest-known route ids, `RouteGate` with `activation_source: :notification`, and Sigra session-authority/step-up reuse — failing closed with stable denial codes for expired/replayed/revoked/route-mismatched/binding-mismatched/unsupported-action/policy-denied opens and no silent fallback (OPEN-01/02/03)
- Operator truth: doctor, operator inspection, support matrix, fixtures, and guides distinguish token-binding/open-routing readiness from APNs/FCM delivery support, backed by stable low-cardinality telemetry that forbids raw tokens, payloads, route params, and PII (DIAG-01/02)
- Merge-blocking hermetic proof covering token contracts, binding/revocation lifecycle, open resolution, Sigra route gating, denial sanitization, support/docs parity, and telemetry redaction (PROOF-01)
- APNs/FCM device delivery, real token issuance, provider credentials, notification-tray behavior, and console metrics kept advisory with explicit promotion criteria; closeout verifies 10/10 requirements mapped and no surface implies first-party push delivery (PROOF-02, REL-01)

**Verification:** Milestone closeout (`.planning/milestones/v3.9-CLOSEOUT.md`) passed all checks — project state, roadmap parity, requirements state, phase verification, SUMMARY frontmatter, thread/seed disposition, release continuity, and support-claim parity all `complete`; validation ledgers `deferred_with_reason`. Closeout enforced by `mix closeout.verify`.

**Known tech debt:** Draft Nyquist VALIDATION.md ledgers for Phases 59, 60, 62, and 63 remain bookkeeping gaps (routed to Phase 64); merge-blocking ExUnit proof and `closeout.verify` cover shipped public support truth.

**Archive:**

- `.planning/milestones/v3.9-ROADMAP.md`
- `.planning/milestones/v3.9-REQUIREMENTS.md`
- `.planning/milestones/v3.9-CLOSEOUT.md`

---

## v3.8 Full Sigra Auth and Session Machinery (Shipped: 2026-06-02)

**Phases completed:** 5 phases, 19 plans, 42 tasks

**Key accomplishments:**

- Backend-owned Sigra session authority contract with canonical auth.step_up denial subcodes and sanitized shell details
- Route-local auth_posture validation and manifest serialization for remembered/cached auth weakening
- Pure Sigra route-auth evaluator wired into RouteGate with canonical fail-closed denial codes
- Session-authority auth posture surfaced through doctor, publish readiness, support matrix, and operator inspection
- Guides, support matrix, release-boundary docs, and proof fixtures now reflect Sigra session-authority route evaluation
- Pure Sigra handoff contracts with backend-authority projection and canonical auth.handoff denial proof
- Ecto-backed one-time Sigra handoff tickets with Phoenix.Token locators, atomic redemption, audit evidence, and host-owned session renewal instructions
- Sigra handoff contract/server-record machinery is now reflected in doctor, support matrix, operator inspection, guides, fixtures, and proof without claiming later auth flows.
- Pure Sigra step-up intent contracts with backend authority projection requirements and canonical intent denial subcodes
- Ecto-backed step-up intent issue and one-time consume flow with backend authority projection and host session renewal instructions
- Shared Sigra ceremony core with Plug and LiveView adapters that fail closed into the same host-issued challenge flow
- Canonical support and docs truth for shipped Sigra step-up intent plus Plug/LiveView ceremony without auth-return overclaims
- Provider-neutral route-local auth-return policy and manifest serialization
- Pure evidence-only auth-return contracts with semantic validation and denial vocabulary
- Example-host server-record proof for auth-return replay, audit, and backend promotion authority
- Public and operator truth for shipped auth-return boundaries without provider/device overclaims
- Stable Sigra auth telemetry and two-axis auth truth now flow through diagnostics, support, operator inspection, and guides.
- Phase 58 security closeout now has a machine-checkable STRIDE ledger and deterministic security-only verifier gate.
- Phase 58 now has CI parity for merge-blocking auth closeout proof and advisory provider/device proof.

**Verification:** Milestone audit satisfied 16/16 requirements, 5/5 phases, 10/10 integration checks, and 5/5 E2E flows. Audit evidence included `mix compile --warnings-as-errors`, security-only closeout verification, and 115 focused proof/support/operator/docs tests with 0 failures.

**Known tech debt:** Nyquist validation ledgers for Phases 54-58 remain stale or partial and are tracked in `STATE.md` Deferred Items.

**Archive:**

- `.planning/milestones/v3.8-ROADMAP.md`
- `.planning/milestones/v3.8-REQUIREMENTS.md`
- `.planning/milestones/v3.8-MILESTONE-AUDIT.md`
- `.planning/milestones/v3.8-phases/`

---

## v3.7 Commerce Provider Adapters (Shipped: 2026-06-01)

**Phases completed:** 2 phases, 7 plans, 17 tasks

**Key accomplishments:**

- Shipped first-party StoreKit and Play Billing companion seams that normalize provider evidence into backend-owned reconciliation contracts without granting device-local entitlement authority.
- Added shared provider evidence and purchase/restore result contracts, preserving provider-specific lineage while keeping entitlement truth backend-projected.
- Wired the example-host paywall through a behaviour-backed storefront adapter contract so the mock remains default and StoreKit/Play Billing provider facades are explicit swap targets.
- Updated support matrix, operator inspection, doctor readiness, commerce guidance, changelog posture, and proof fixtures so provider seams are shipped while provider/device proof remains advisory.
- Closed the milestone-audit blocker with tagged LiveView storefront result handling and merge-blocking proof for the configured provider facade path.

**Verification:** Milestone audit passed 3/3 requirements, 2/2 phases, 10/10 integration checks, and 4/4 E2E flows. Phase 48.1 proof ran 69 focused tests with 0 failures.

**Archive:**

- `.planning/milestones/v3.7-ROADMAP.md`
- `.planning/milestones/v3.7-REQUIREMENTS.md`
- `.planning/milestones/v3.7-MILESTONE-AUDIT.md`
- `.planning/milestones/v3.7-phases/`

---

## v3.5 First-Party Companions (Shipped: 2026-05-31)

**Phases completed:** 10 phases, 22 plans, 40 tasks

**Key accomplishments:**

- Locked the shared `Crosswake.Companion` seam: six-callback behaviour, typed state, fail-closed optional dependency diagnostics, companion telemetry, and in-tree `lib/crosswake/companions/<name>/` convention.
- Shipped the Rulestead gating seam end-to-end: route-policy `gated_by`, manifest binding, local-snapshot runtime evaluation, `:gate_denied`/`:kill_switch_active` denials, doctor/support truth, hermetic/advisory proof, and `/gating` mock example.
- Shipped the Rindle media seam and mock proof: typed upload grant/capture evidence/media object contracts, backend-owned reconciliation, stable idempotency, queued-not-committed semantics, pure-Elixir `/media/proof` lane, and hermetic/advisory proof split.
- Shipped Sigra contract-only auth truth: backend-owned `AuthContext` and `SessionAuthorityLane`, route predicates (`auth_min_level`, `requires_recent_auth`), fail-closed `:step_up_required` denials, and doctor/support truth without claiming deferred Sigra machinery.
- Published `guides/companions.md` as the canonical companion guide and locked it with semantic docs-contract tests against live support matrix, denial vocabulary, and doctor findings.

**Verification:** Milestone audit passed 15/15 requirements; Phase 44 focused proof passed 27 tests; Phase 47 guide/proof passed 12 tests; hermetic suite passed 455 tests with 44 excluded.

**Archive:**

- `.planning/milestones/v3.5-ROADMAP.md`
- `.planning/milestones/v3.5-REQUIREMENTS.md`
- `.planning/milestones/v3.5-MILESTONE-AUDIT.md`
- `.planning/milestones/v3.5-phases/`

---

## v3.4 Commerce Archetype Proof (Shipped: 2026-05-29)

**Phases completed:** 5 phases, 8 plans, 8 tasks

**Key accomplishments:**

- Declared three `:subscription_default` corridor routes (paywall_entry live + purchase/restore_intent post) in `examples/phoenix_host` with canonical `crosswake.commerce` DSL, plus a manifest-introspection proof test confirming correct role_ownership (Phase 33).
- Established the `phase34-proof.yml` two-job CI split — a hermetic merge-blocking lane (`--exclude requires_example_host`) and an advisory `continue-on-error` lane carrying the 4-condition `promotion_path` (Phase 33).
- Built `CrosswakeExample.Commerce.MockStorefront` as a pure-Elixir, provider-neutral evidence emitter (`simulate_purchase/2`, `simulate_restore/2`) documented as the StoreKit/Play Billing swap target, with a hermetic replay/idempotency proof (stable `entry_id` identity, not transient `correlation_id`) and a provider-vocabulary fence (Phase 34).
- Wired the data layer — MockBackend verification-gap bridge, CorridorController POST seams, and PubSub supervision — into a four-state `PaywallEntryLive` LiveView with fail-closed `:stale` mount, exhaustive `case` dispatch to four named components, and dev scenario drivers consuming real `derived_state/1` derivation (Phase 35).
- Added the merge-blocking hermetic `phase34_paywall_corridor_proof_test.exs` driving the full lane (`ingest_evidence/2` → `project_snapshot/2` → `derived_state/1`), asserting all four states, the `:pending` → `:granted` transition, and the mock-boundary fence (`authority_mutation_allowed_from_evidence?/1 == false`), with a hermeticity self-scan guard (Phase 36).
- Added an end-to-end Paywall Corridor Walkthrough to `guides/commerce.md` (anchor-only, `provider: "mock"` callout, proof citation) and locked it to the shipped example via a hybrid string-presence + `function_exported?/3` docs-contract test in `commerce_test.exs`, preserving the phase23 three-layer + four-non-claims fences (Phase 37).

**Highlights:** All 14 requirements validated; milestone audit PASSED (14/14 req · 5/5 phase · 7/7 integration · 2/2 E2E flows). Zero provider-SDK code; zero new dependencies; reused the shipped v3.2 commerce contracts and Phase-21 reconciliation modules. 352 full-suite tests green.

---

## v3.3 Release Readiness (Shipped: 2026-05-29)

**Phases completed:** 6 phases, 11 plans, 5 tasks

**Key accomplishments:**

- Added canonical Apache-2.0 LICENSE file to repo root to back the hex package `:licenses` declaration.
- Replaced placeholder metadata in mix.exs with canonical szTheory block, introducing `@source_url` single source of truth and an explicit `:files` allowlist.
- Automated Hex releases via release-please with SHA-pinned Actions and Dependabot updates

---

## v3.2 Commerce And Entitlement Seams (Shipped: 2026-05-27)

**Phases completed:** 6 phases, 18 plans, 38 tasks

**Key accomplishments:**

- Crosswake now compiles explicit provider-neutral route commerce corridor declarations into a canonical manifest registry with strict referential validation and additive schema compatibility coverage.
- Crosswake now publishes synchronized commerce corridor support truth across support matrix, doctor output, and public guides with canonical fail-closed denial vocabulary.
- Provider-neutral entitlement snapshot lanes now encode authority, access, reconciliation, freshness, effective window, and evidence metadata as explicit typed contracts with non-granting reconciliation semantics.
- Bounded reconciliation evidence ingestion now stays non-authoritative by contract, with explicit fail-closed mappings and nested provider-vocabulary rejection in core validation paths.
- Published explicit entitlement lane semantics and synchronized renderer-generated support truth so stale or pending evidence states remain non-authoritative across public guidance and test-locked outputs.
- Closed the ENTL-03 verification gap by enforcing canonical evidence-source vocabulary fail-closed in both snapshot construction and reconciliation ingestion paths.
- Doctor now emits a typed commerce_summary surface with proof-class-labeled findings, derived from canonical support-matrix metadata, and fails closed on stale/unknown entitlement snapshots.
- Commerce corridor support truth now carries canonical prerequisite_classes, structured rebuild_requirement, and proof_class metadata; renderer emits three new columns; guides are byte-identical to canonical source and lock the advisory-cannot-redefine non-claim mechanically.
- Commerce guide is now a layered docs hub (support truth → advisory reviewer playbooks → explicit non-claims) with App Store and Play Store reviewer notes templates anchored to canonical SupportMatrix accessors and 8 new docs-contract tests that mechanically lock the layered structure, advisory boundary callouts, non-claims naming (StoreKit, Play Billing, device-local authority, offline replay), reviewer metadata columns (owner/proof_class/failure_posture/rebuild_requirement), canonical denial codes in fallback language, and reviewer corridor-role parity against `SupportMatrix.commerce_corridors/0`.
- Hermetic merge-blocking Phase 23 commerce support proof lane (14 tests) plus a two-job CI workflow that splits the required hermetic gate from the scheduled-only advisory provider/storefront/simulator/device lane, with a documented four-condition advisory-to-merge-blocking promotion path surfaced both in the workflow YAML and at runtime via a new `promotion_path` detail on advisory doctor findings.
- Deleted the contradictory trailing sentence from `20-VERIFICATION.md:63`, leaving the accurate Phase 20 final determination at line 61 as the sole conclusion.
- Hardened `summary_frontmatter_test.exs` with four edits (WR-01 third test, WR-02 helper raise, IN-01 `@requirements_path`, IN-02 `[xX ]`) and created both Phase 25 SUMMARYs in one atomic commit, closing all four advisory items from `24-REVIEW.md`.

---

## v2.0 Adopter Stress Profiles (Shipped: 2026-05-19)

**Delivered:** Three adopter-shaped exemplar lanes that pressure-tested the v1 Crosswake substrate and turned the resulting proof, diagnostics, and support posture into public product truth.

**Phases completed:** 6-10 (16 plans total)

**Key accomplishments:**

- Published a locked adopter-profile matrix and one shared example-host contract for realistic Crosswake app shapes.
- Proved a Phoenix-owned SaaS approvals lane with host-owned auth and one bounded haptics seam.
- Proved a selective-native claims-evidence corridor with one explicit `:native_screen` route plus route-local pack and transfer seams.
- Proved a local-first study flow with an append-only journal, sync endpoint, offline-island session, and cached read-only history lane.
- Hardened doctor diagnostics, per-profile verification scripts, CI, and support guidance around the rough edges exposed by the exemplars.

**Stats:**

- 86 files changed
- 6,640 insertions and 124 deletions
- 5 phases, 16 plans, 33 tasks
- 3 days from first seed to shipped milestone

**Git range:** `7f87976` → `45b7ea8`

**What's next:** Define the next milestone around Phoenix-first native capabilities, commerce support, and first-party companion seams without collapsing the route-policy thesis into a generic plugin surface.

---

## v3.0 Capability Contract And Packaging (Shipped: 2026-05-20)

**Delivered:** Capability taxonomy, package-boundary policy, commerce seam vocabulary, and proof/support truth that prepared Crosswake for native capability breadth without widening runtime ownership.

**Phases completed:** 11-14 (12 plans total)

**Key accomplishments:**

- Published capability-family taxonomy and route-owner decision rules.
- Classified `core`, `companion`, `example/docs-only`, and deferred surfaces with release and rebuild rules.
- Defined Phoenix-facing commerce and entitlement seams that keep entitlement truth backend-owned.
- Extended doctor, support-matrix, and proof-lane posture for future capability claims.

**Archive:**

- `.planning/milestones/v3.0-ROADMAP.md`
- `.planning/milestones/v3.0-REQUIREMENTS.md`

---

## v3.1 Native Capabilities and Bridge Expansion (Shipped: 2026-05-27)

**Delivered:** The first official low-frequency native capability families across Crosswake's bounded bridge contract, with route-local enforcement, support truth, and CI-backed proof.

**Phases completed:** 15-18 (16 plans total)

**Key accomplishments:**

- Implemented `haptics`, `share`, and `app_info` as base bounded bridge families across host and native shell surfaces.
- Added deep-link activation truth plus `permissions.status` as a read-only, notifications-scoped system-context bridge.
- Added `notification_token` and `file_picker` as asynchronous user-prompted capability families with provider-tagged evidence and transfer-bound staged handles.
- Canonicalized family-first route capability validation while preserving command-aware bridge lookup and the transfer-backed `file_picker` exception.
- Split support-matrix truth into baseline platform support, proof status, and capability-family posture.
- Added the dedicated `Phase 18 Proof` GitHub Actions lane and made it pass across Elixir proof slices, checked-in iOS shell proof, and Android JVM BridgeChannel proof.

**Verification:**

- `bash script/verify_phase18_contract.sh` — 48 tests, 0 failures.
- `mix test` — 184 tests, 0 failures.
- GitHub Actions `Phase 18 Proof` run `26498172516` — passed in 6m34s.

**Known deferred items at close:** 3 human-UAT checks from Phase 15 remain acknowledged and deferred in `STATE.md`.

**Archive:**

- `.planning/milestones/v3.1-ROADMAP.md`
- `.planning/milestones/v3.1-REQUIREMENTS.md`

**What's next:** Start the next milestone with `$gsd-new-milestone`; the strategic arc currently points toward commerce and entitlement seams or the next operator/companion slice.

---
