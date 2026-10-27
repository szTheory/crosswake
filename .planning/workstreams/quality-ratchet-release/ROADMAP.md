# Roadmap: Quality Ratchet & Release

## Milestones

- 🚧 **v28.0 Truth and Release Train** — phases 194–199; started 2026-10-24; 30 requirements (PLAN, ADR, REL, HYG, SPEC, ARCH, DOCS, AND). Land the bearings and ADR amendments, make `main` and the release pipeline trustworthy, harden the sensitive specs, correct the public docs, prove Android from a foreign host, and cut one real release behind per-publish `allow`. [Scope](v28.0-SCOPE.md), [requirements](REQUIREMENTS.md), [research synthesis](v28.0-research/SYNTHESIS.md).
- ✅ **v27.0 Land and Clean Up** — phases 189–193; shipped 2026-10-24; 18/18 requirements, 55 plans, 127 tasks; audit `tech_debt` with no blocker. The v25 and v26 work is on GitHub `main` with CI green (PR #242, merge `d12aed75`), the recovery checkout was retired for a clean `main` checkout, and changes now land through PRs branched from `main`. [Archive](milestones/v27.0-ROADMAP.md).
- **v26.0 Harden Before Trust** — phases 184–188; planning closeout complete 2026-10-16; 18/18 requirements, 37 plans, 96 tasks; audit `tech_debt` with no blocker; twin-05 passed against the frozen candidate `a53fbef`. The product code was delivered to `main` in v27.0. [Archive](milestones/v26.0-ROADMAP.md).
- **v25.0 iOS Host Setup & Digital Twin Proof** — phases 179–183; planning closeout complete 2026-10-15; 20/20 requirements, 32 plans, 78 tasks; re-audit `tech_debt` with no blocker. The product code was delivered to `main` in v27.0. [Archive](milestones/v25.0-ROADMAP.md).
- **v24.0 Repository Cleanup & Maintenance** — phases 176–178; planning closeout complete 2026-10-12; 8/8 requirements, 15 plans, 28 tasks; six retained debt records. [Archive](milestones/v24.0-ROADMAP.md).
- **v23.0 Release Pipeline Repair & Proof-Lane Truth** — phases 169–175, archived with exceptions 2026-10-11; 42/43 requirements; REL-10 breached. [Archive](milestones/v23.0-ROADMAP.md).
- **v22.0 Quality Ratchet & Release Readiness** — phases 164–168, archived with overrides 2026-09-15. [Archive](milestones/v22.0-ROADMAP.md).

## Phases

### 🚧 v28.0 Truth and Release Train (Phases 194–199) — IN PROGRESS

- [x] **Phase 194: Bearings reset and ADR amendments** - Rolling roadmap, bearings, personas, a short STATE and a bearings report land, and the ADR amendments (Android unfrozen for parity; synthetic-profile reversal gate) change every rule text together (completed 2026-10-25)
- [x] **Phase 195: Pipeline repair and hygiene** - The release PR goes green with no hand edits, the PR queue and CI schedules are clean, secrets are masked, the repository root and branches are tidy, and one clean-room command runs against real published artifacts (completed 2026-10-27)
- [ ] **Phase 196: Spec and structure ratchet** - Sensitive offline, policy and bridge specs can no longer pass empty, boundary and exhaustive policy specs exist, a Muex pilot decides adopt or drop, and compile-cycle, bare-rescue and dependency ratchets hold
- [ ] **Phase 197: Public docs truth** - The documented install path runs on a normal host, version and telemetry claims are true, "Android frozen" text is gone, and docs checks report counts
- [ ] **Phase 198: Android foreign-host proof** - A generated parity ledger, a Kotlin test floor, and a fresh foreign Gradle project that resolves the published Maven coordinate and passes JVM tests on Linux CI
- [ ] **Phase 199: Release 0.2.12** - One real release, core first, with a separate `allow` per merge, publish and tag, and a post-publish check that the iOS mirror tag equals the release version

### Ordering rules for v28.0

- **Land before leap.** Phase 194 lands first so every later rule text (AGENTS.md, ADR, PROJECT.md, support truth) agrees with this roadmap before any Android or release work starts.
- **A red base hides regressions.** Phase 195 makes `main` and the release PR green before the ratchet (196), docs (197) and Android (198) phases add checks.
- **Every irreversible step has its own `allow`.** Merges to `main`, the release-PR merge, each Hex/Maven/iOS publish, each tag and each remote branch delete need a fresh one-use `allow` bound to the displayed attempt. No `--admin`, no force-push or hand edit to the release-please branch, never close release PR #236, never retry an uncertain delivery.
- **No new check is merge-blocking before its findings on `main` are measured.** Guards are delta-only; report-mode checks stay advisory for one cycle.
- **Overrun cut order.** If Phase 196 overruns, move SPEC-04 (Muex pilot) and then ARCH-03 (dependency ratchet) to v29 through a recorded roadmap change; do not shrink their success criteria in place.
- **No twin run in v28.** twin-05 still attests `a53fbef`; the twin-06 decision is asked at v30 entry.
- Never name, infer or search for the real first adopter; synthetic profiles stay generic.

## Phase Details

### Phase 194: Bearings reset and ADR amendments

**Goal**: A new session can orient from three short files and one command, and every governing rule text says the same thing about Android and synthetic profiles.
**Depends on**: Nothing (first phase of v28.0)
**Requirements**: PLAN-01, PLAN-02, PLAN-03, PLAN-04, PLAN-05, ADR-01, ADR-02
**Success Criteria** (what must be TRUE):
  1. `.planning/ROADMAP-ROLLING.md` (at most 120 lines, NOW/NEXT/LATER/PARKED/DROPPED, every row with outcome, horizon, effort, `adr:` and promotion trigger), `.planning/BEARINGS.md` (at most 60 lines, listed first in AGENTS.md Project Context) and `.planning/PERSONAS.md` (P1–P7, J1–J5, at most one page) exist; MILESTONE-ARC.md is marked historical with its durable lessons in BEARINGS; AGENTS.md is at most 102 lines (measured cap, recorded 2026-10-25) with the approval-gate paragraph byte-identical to `main` and a disposition for every removed rule; the superseded root JTBD ordering is recorded as not executed.
  2. The workstream STATE.md is at most 40 lines with one handoff and no "Handoff history" section, and the milestone-start convention no longer contains the byte-snapshot ritual.
  3. `script/bearings-report` prints at most 40 plain-language lines covering CI for the main tip (Crosswake CI runs only on pull requests, so the line names the PR-head commit CI ran on and says its status belongs to that head; CONTEXT D-11 amendment) and whether CI has run on local HEAD, ahead/behind, open PR classes, worktrees, stashes and unlanded branches, line caps (including the 120/60/40 caps above) and fired seed/debt triggers; it exits non-zero and prints UNVERIFIED when any read fails; each check has a negative-control test that turns it red; it is not a required check.
  4. One PR carries the ADR amendments: Android unfrozen for proof and parity of existing contracts with the re-freeze trigger (Android work delays an iOS gate by more than one milestone), and the synthetic-profile reversal gate (profile, failing criterion, cited artifact, smallest slice, rollback; at most one reopened item per milestone) that permits profile scenario rows over one host; in that same PR a grep for Android "frozen" posture text in AGENTS.md, the ADR, PROJECT.md, the support matrix and the capability map finds only amendment history.
  5. A check confirms every requirement in the active milestone REQUIREMENTS file carries a persona/job tag or `M`.

**Plans**: 9 plans (PR1: 01-03; PR2: 04-09; sequential waves 1-9 in one checkout)

Plans:
**Wave 1**
- [x] 194-01-PLAN.md — Android posture in support matrix, capability map, native shell guide and both golden fixtures (regenerated); pins rewritten; one `fix(support-matrix):` commit

**Wave 2** *(blocked on Wave 1 completion)*
- [x] 194-02-PLAN.md — ADR amendments A1/A2, AGENTS.md Android bullet, PROJECT.md posture, SC4 grep with negative controls

**Wave 3** *(blocked on Wave 2 completion)*
- [x] 194-03-PLAN.md — Land PR1 (privacy, push, CI on head, one-use merge allow), reconcile #246, branch PR2 from fresh main

**Wave 4** *(blocked on Wave 3 completion)*
- [x] 194-04-PLAN.md — ROADMAP-ROLLING, BEARINGS, PERSONAS; MILESTONE-ARC and JTBD banners; PROJECT.md pointer

**Wave 5** *(blocked on Wave 4 completion)*
- [x] 194-05-PLAN.md — AGENTS.md trim with disposition table and gate contract test; STATE to 40 lines; byte-snapshot ritual settled

**Wave 6** *(blocked on Wave 5 completion)*
- [x] 194-06-PLAN.md — bearings-report core: launcher, verdict/exit contract, CI for the main tip via its PR head, CI negative controls

**Wave 7** *(blocked on Wave 6 completion)*
- [x] 194-07-PLAN.md — bearings-report ahead/behind, open PR classes, worktrees/stashes/unlanded branches, exact-output test

**Wave 8** *(blocked on Wave 7 completion)*
- [x] 194-08-PLAN.md — bearings-report caps, seed/debt triggers, persona-tag check, 40-line cap, live and not-required evidence

**Wave 9** *(blocked on Wave 8 completion)*
- [x] 194-09-PLAN.md — Land PR2 (pre-push checks, privacy, CI on head, its own merge allow), bearings-report on main, closeout PR opened

**Research**: Skip (small, decided)

### Phase 195: Pipeline repair and hygiene

**Goal**: `main`, the release PR and the PR queue are green and trustworthy, CI runs only recurring lanes and never echoes secrets, the repository holds no scratch state, and one fail-closed clean-room command is proven against real published artifacts.
**Depends on**: Phase 194
**Requirements**: REL-01, REL-02, REL-03, REL-04, REL-05, REL-06, HYG-01, HYG-02
**Success Criteria** (what must be TRUE):
  1. The Info.plist golden and Swift seam fixture comparisons ignore the `Generated by crosswake X.Y.Z` line (a test that changes only that line passes), and the release-please PR for the next version passes the eight test jobs on its PR head commit with zero hand edits to the bot branch.
  2. The parity-workflow test asserts a 40-hex SHA plus version comment rather than a literal SHA; Dependabot is configured as one grouped monthly actions PR plus security updates; #210/#211 are green after rebase or closed, #239/#240/#241 are merged, #238 is merged or closed as superseded, and `gh pr list` shows no open PR older than 14 days without a recorded reason.
  3. A test seeds a fake secret and proves it never appears in captured CI step output or the root-proof failure tail (bearer, secret-access-key, cookie and short-value shapes masked), and fails when the mask is removed; the workflow tree contains no `phaseNN-proof` schedule, no Cancel Obsolete controller and no `script/select_obsolete_ci_runs.py`, has one weekly canary on `main`, and See It Run `web-and-gif` completes independently of the split-out `native` job.
  4. A root-allowlist test fails on any new tracked root file or `*.bundle`; the 13 root scratch files and `crosswake-checkpoint-24c8389.bundle` are gone (bundle confirmed not the only copy; the denylist string in `first_adopter_context.ex` stays); `SETUP.md` lives under `docs/` without the personal email; merged or superseded remote branches are deleted (unmerged work tagged `archive/<name>` first, each delete behind its own `allow`) and `git worktree list` shows only the main checkout.
  5. SEED-003 is closed with mirror-tag evidence, and one clean-room command has run once against the real 0.2.11 artifacts with its output retained, and fails closed on a negative control (missing or wrong artifact).

**Plans**: 21 plans; 01–21 executed with retained summaries; round-3 REL-03 closure verified on actual main in sequential waves 4–6 after completed round-2 wave 3. One main checkout.

Plans:

**Wave 1**
- [x] 195-01-PLAN.md — Version-agnostic shell fixture comparisons and shape-based action pins, rehearsed against the real #236, #210 and #211 diffs

**Wave 2** *(blocked on Wave 1 completion)*
- [x] 195-02-PLAN.md — Land PR1 (privacy, CI on head, its own merge allow); observe release-please rewrite #236 and its eight test jobs pass on the new head

**Wave 3** *(blocked on Wave 2 completion)*
- [x] 195-03-PLAN.md — PR queue: #239/#240/#241 merged, #210/#211 and #238 merged or closed by recorded rule, one allow per merge, pin provenance checked

**Wave 4** *(blocked on Wave 3 completion)*
- [x] 195-04-PLAN.md — Secret masking: maskSecretShapes on the root-proof tail, add-mask for derived workflow secrets proven by a spawned-shell run, mask-removed negative controls

**Wave 5** *(blocked on Wave 4 completion)*
- [x] 195-05-PLAN.md — Recurring-lanes contract test (measured on main) and the first seven phase-proof schedules removed

**Wave 6** *(blocked on Wave 5 completion)*
- [x] 195-06-PLAN.md — Remaining seven phase-proof schedules removed; one advisory weekly canary on main

**Wave 7** *(blocked on Wave 6 completion)*
- [x] 195-07-PLAN.md — Cancel Obsolete controller and selector removed; controller-bound monitor subcommands retired explicitly; absence pinned

**Wave 8** *(blocked on Wave 7 completion)*
- [x] 195-08-PLAN.md — See It Run native split into a manual workflow; Dependabot grouped monthly with security updates separate

**Wave 9** *(blocked on Wave 8 completion)*
- [x] 195-09-PLAN.md — Land PR2 (own allow); See It Run web-and-gif and canary observed on main; Dependabot security updates enabled

**Wave 10** *(blocked on Wave 9 completion)*
- [x] 195-10-PLAN.md — Root allowlist test, 13 scratch files and the checkpoint bundle removed (refs proven on origin), SETUP.md under docs/ without personal email

**Wave 11** *(blocked on Wave 10 completion)*
- [x] 195-11-PLAN.md — Fail-closed clean-room command run against real 0.2.11 Hex/Maven/iOS with retained output and negative controls; SEED-003 closed

**Wave 12** *(blocked on Wave 11 completion)*
- [x] 195-12-PLAN.md — Land PR3 (own allow, bundle heads re-checked right before the gate); clean root confirmed on main

**Wave 13** *(blocked on Wave 12 completion)*
- [x] 195-13-PLAN.md — Remote branch cleanup (archive tags first, one allow per tag and per delete), stale PRs closed by recorded rule, one worktree, PR age audit, closeout branch pushed

**Gap closure (REL-03 masking, from 195-VERIFICATION.md)**
- [x] 195-14-PLAN.md — Seeds-first masker fix: quoted, multi-word, mid-line Cookie, Digest, userinfo and JWT shapes masked; prose no longer masked; linear-time; non-vacuous add-mask guard (CR-01, CR-02, WR-01 to WR-03)
- [x] 195-15-PLAN.md — Land PR4 (own allow); verifier leak cases closed on main; review dispositions recorded, WR-04 to WR-06 and IN-03 carried to Phase 197

**Gap closure round 2 (REL-03 masking, from 195-VERIFICATION.md and 195-REVIEW-GAP.md)**
- [x] 195-16-PLAN.md — Seeds-first criticals: escaped-JSON, tuple, quoted-Bearer, next-line, CLI-flag and double-equals credential forms masked; named value groups; single-quoted add-mask rejected (GR-01, GR-02, GR-10)
- [x] 195-17-PLAN.md — Seeds-first warnings: provider tokens, PEM bodies, userinfo/key-ID/JWT variants, query and plural keys; literal-value exemptions; 200 ms budget; GR-06 census; final controls (GR-03 to GR-05, GR-07 to GR-09)
- [x] 195-18-PLAN.md — Land PR5 (own allow); GR-01 and GR-02 closed on main; GR dispositions recorded, GR-06 route asked separately (recommended: carry to Phase 196)

**Gap closure round 3 — REL-03 (complete; actual-main proof passed)**

**Wave 4** *(depends on completed 195-18)*
- [x] 195-19-PLAN.md — Structural credential identifiers, workflow-name inventory, container/armor masking and bounded whitespace performance; mandatory executed-family checks

**Wave 5** *(blocked on 195-19)*
- [x] 195-20-PLAN.md — Exact add-mask registration, non-vacuous tail windows, diagnostic tradeoffs and remaining GAP2 regressions

**Wave 6** *(blocked on 195-20)*
- [x] 195-21-PLAN.md — Independent GAP3 review, exact-head green CI, fresh per-operation approval and process-derived proof on actual main

Round-3 result: REL-03 is complete from fresh actual-main proof on b8398c38; all twelve GAP2 findings and eight GAP3 findings have passing checks; prior GR-06/Phase197 deferrals remain; every commit/push uses conditional privacy scans; fresh one-use approval for each main merge or remote deletion; no release or tag in this round. Tests prove supported rules and the workflow-name inventory, with no universal arbitrary-secret claim.

**Research**: Skipped for round-3 gap closure; existing inspected code and reproduced failures. Independent plan checker passed on its second review; see 195-PLAN-CHECK.md.

### Phase 196: Spec and structure ratchet

**Goal**: The offline, policy and bridge specs that Android and later parity work consume cannot pass by asserting nothing, and the module structure has ratchets that fail on regressions.
**Depends on**: Phase 195 (green base)
**Requirements**: SPEC-01, SPEC-02, SPEC-03, SPEC-04, SPEC-05, ARCH-01, ARCH-02, ARCH-03
**Success Criteria** (what must be TRUE):
  1. `evidence_manifest_test.exs` and `phase139_threadline_cleanroom_test.exs` no longer pass vacuously, and the Elixir, Swift and Kotlin vector-consuming tests each assert vector count equals a pinned expectation and fail when a vector file is removed; the delta-only guard in `script/check_absence_is_not_success.exs` fails on new non-empty-less collection assertions, `for`-over-glob without cardinality and literal `assert true`, each with a negative control, with the known sites fixed in the same change.
  2. Boundary specs pass for `Journal.scope_ref!/1` (15/16/128/129 chars, newline injection, input never echoed) and `SafeObservation.new/1` (measurement 0, 1_000_000, 1_000_001; adversarial strings in every field never survive); the finite route-policy option product is enumerated exhaustively against a hand-written verdict table, compiler error assertions pin `{key, route_id}` pairs, and `Compiler.validation_key/1` never returns `nil` for a compiler error.
  3. A Muex pilot record covers `SafeObservation`, `Journal`, `Policy.Compiler`/`Route` and `Bridge.Contract` with a non-zero mutant count, a wrapper that fails on zero mutants, baseline scores, runtime, survivors keyed by file + mutator + normalized text, and a written adopt/drop decision; `mix.exs` and `mix.lock` contain no Muex dependency.
  4. A test fails on any compile-label xref cycle (the `bridge/contract`, `bridge/denial`, `manifest/types`, `shell/denial` cycle is broken) and on an all-cycles count above the committed baseline; an AST test fails on bare `rescue _ ->` in the `bridge`, `policy`, `router`, `offline`, `manifest` and `compatibility` modules (the three in `bridge.ex` now return explicit results); a test fails when a package's runtime direct deps differ from the committed list with one-line justifications; each ratchet has a negative control.

**Plans**: 17 plans, 40 tasks; sequential waves 1–17 in one main checkout. Plans01–10 complete; plans11–17 remain pending.

Plans:
**Wave 1**
- [x] 196-01-PLAN.md — Wave 1: Preserve planning and establish actual-main measurement

**Wave 2** *(blocked on Wave 1 completion)*
- [x] 196-02-PLAN.md — Wave 2: Strict optional proof lanes

**Wave 3** *(blocked on Wave 2 completion)*
- [x] 196-03-PLAN.md — Wave 3: Elixir and primary Swift request-vector proof

**Wave 4** *(blocked on Wave 3 completion)*
- [x] 196-04-PLAN.md — Wave 4: Remaining real Swift vector readers

**Wave 5** *(complete)*
- [x] 196-05-PLAN.md — Wave 5: Kotlin request, reply and metadata reader proof

**Wave 6** *(ready; Wave 5 complete)*
- [x] 196-06-PLAN.md — Wave 6: Branch-sensitive delta-only absence guard

**Wave 7** *(complete)*
- [x] 196-07-PLAN.md — Wave 7: Scope and observation privacy boundaries

**Wave 8** *(complete)*
- [x] 196-08-PLAN.md — Wave 8: Independent finite policy oracle and diagnostic provenance

**Wave 9** *(ready; Wave 8 complete)*
- [x] 196-09-PLAN.md — Wave 9: Protocol leaf and real Mix compile-cycle ratchet

**Wave 10** *(complete)*
- [x] 196-10-PLAN.md — Wave 10: Explicit diagnostic fallbacks and exact broad-containment exceptions

**Wave 11** *(ready; Wave 10 complete)*
- [ ] 196-11-PLAN.md — Wave 11: Evaluated six-project production runtime dependency ratchet

**Wave 12** *(blocked on Wave 11 completion)*
- [ ] 196-12-PLAN.md — Wave 12: Close GR-06 with conserved workflow statement classification

**Wave 13** *(blocked on Wave 12 completion)*
- [ ] 196-13-PLAN.md — Wave 13: Freeze the pilot protocol and validate real nonempty Muex output

**Wave 14** *(blocked on Wave 13 completion)*
- [ ] 196-14-PLAN.md — Wave 14: Complete five-file baseline and honest adopt/drop decision

**Wave 15** *(blocked on Wave 14 completion)*
- [ ] 196-15-PLAN.md — Wave 15: Promote measured recurring guards and verify final candidate

**Wave 16** *(blocked on Wave 15 completion)*
- [ ] 196-16-PLAN.md — Wave 16: Prepare one exact-head PR and observe its CI

**Wave 17** *(blocked on Wave 16 completion)*
- [ ] 196-17-PLAN.md — Wave 17: Fresh one-use main merge and actual-main phase proof

**Research**: Complete bounded research and pattern map (196-RESEARCH.md, 196-PATTERNS.md); no product fixes or full pilot are claimed. Guard findings on actual main, repaired cycle baseline and complete five-file pilot remain execution gates.
**Carried from Phase 195 gap review**: GR-06 (derived-secret guard grammar: local/declare/readonly, +=, read and printf -v, GITHUB_ENV and GITHUB_OUTPUT writes, several assignments or a use on the assignment line) in test/js/ci_secret_masking.test.mjs; see 195-REVIEW-DISPOSITION.md.

### Phase 197: Public docs truth

**Goal**: A first adopter following the public docs from a normal host gets commands that exist, versions that are real and capability claims backed by evidence.
**Depends on**: Phase 195 (clean-room command), Phase 194 (Android amendment)
**Requirements**: DOCS-01, DOCS-02, DOCS-03
**Success Criteria** (what must be TRUE):
  1. The REL-06 clean-room command executes the README "Integrating" and `install.md` steps on a host without a repository clone and passes; neither file contains a repo-only command, both state which steps need a clone, and both include the bridge hook, esbuild flags, `attach/1` and `:ios_host` wiring.
  2. The companion matrix matches the versions actually published on Hex (checked against the registry, not a copied literal), the phase132 test no longer hardcodes stale values, CHANGELOG makes no false "current release" claim and points to GitHub Releases for 0.2.2–0.2.11, the telemetry guide lists `[:crosswake, :offline, :replay]`, and `see_it_run.md` states that the twin receipt attests `a53fbef`.
  3. `mix docs` warnings, a relative link/anchor check and a public internal-code leak scan (`Phase N`, `TODO-`, `D-NN`, `v2x`) run in report mode with their counts recorded, and none is a required check.
  4. `android_uat.md` has no automated "Last verified" stamp and no phantom capability families, and a grep for "Android frozen" posture text in README, the support matrix and the native shell guide returns zero hits.

**Plans**: TBD
**Research**: Skip
**Carried from Phase 195 review**: WR-04 (clean-room curl timeout, retry and protocol pin), WR-05 (report resolve or parse failures separately from not_published), WR-06 (POM project-coordinate check) and IN-03 (need_tools completeness) in script/verify_published_cleanroom.sh; see 195-REVIEW-DISPOSITION.md.

### Phase 198: Android foreign-host proof

**Goal**: A cross-platform team can see which existing contracts Android honors, generated from the same vectors as iOS, and a generated Android shell built in a foreign Gradle project resolves the published Maven artifact and passes JVM tests.
**Depends on**: Phase 194 (ADR-01 unfreeze), Phase 196 (Kotlin vector count pins), Phase 195 (clean-room command shape)
**Requirements**: AND-01, AND-02, AND-03
**Success Criteria** (what must be TRUE):
  1. A parity ledger with an Android column is generated from `priv/contract_vectors/*.json` (regenerating it produces no diff), and a test asserts Swift and Kotlin reference the same vector-set hash and fails on a mismatch.
  2. The Kotlin core JVM test count is at least 25 (up from 12) and includes `BridgeChannel` boundary cases; `androidx.webkit` is absent from the build files if no source imports it; the Android JSON-stack choice is recorded in writing.
  3. A fresh foreign Gradle project built from `mix crosswake.gen.shell android` output resolves the published Maven coordinate and passes JVM tests on the Linux CI head commit as an advisory leg (required only after two clean runs), and a negative control with a wrong coordinate fails.
  4. No Android claim in the support matrix or capability map exceeds JVM-hermetic evidence (no device, emulator or feature-breadth claim).

**Plans**: TBD
**Research**: Needs `--research-phase` (Android build files, `androidx.webkit` and `org.json` usage, generator templates versus Gradle files were read at grep level only)

### Phase 199: Release 0.2.12

**Goal**: Users can install the next release from Hex, Maven and the iOS mirror, published core-first, with every irreversible step individually approved and verified after the fact.
**Depends on**: Phases 194–198
**Requirements**: REL-07
**Success Criteria** (what must be TRUE):
  1. The release-please PR is green on its head commit with zero hand edits and is merged only after its own `allow`.
  2. Publishing runs core first, then companions, then Maven, then the iOS mirror; each publish and each tag follows a separate one-use `allow`; the published versions are visible on Hex and Maven.
  3. A post-publish check asserts the iOS mirror tag equals the release version and fails on a mismatch.
  4. `script/bearings-report` exits 0 with no UNVERIFIED line at milestone close.

**Plans**: TBD
**Research**: Skip

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 194. Bearings reset and ADR amendments | 9/9 | Complete | 2026-10-25 |
| 195. Pipeline repair and hygiene | 21/21 | Complete | 2026-10-27 |
| 196. Spec and structure ratchet | 10/17 | In progress; plan11 next | - |
| 197. Public docs truth | 0/TBD | Not started | - |
| 198. Android foreign-host proof | 0/TBD | Not started | - |
| 199. Release 0.2.12 | 0/TBD | Not started | - |

<details>
<summary>✅ v27.0 Land and Clean Up (Phases 189–193) — SHIPPED 2026-10-24</summary>

- [x] Phase 189: Inventory and backup (13/13 plans) — completed 2026-10-18
- [x] Phase 190: Fix warnings before landing (10/10 plans) — completed 2026-10-19
- [x] Phase 191: Integration branch and local suite (12/12 plans) — completed 2026-10-23
- [x] Phase 192: PR, CI and merge (10/10 plans) — completed 2026-10-23
- [x] Phase 193: Cleanup and new working rules (10/10 plans) — completed 2026-10-24

</details>

<details>
<summary>v26.0 Harden Before Trust (Phases 184–188) — planning closeout 2026-10-16</summary>

- [x] Phase 184: Twin probe and safe preflight (15/15 plans) — completed 2026-10-16
- [x] Phase 185: Checks that cannot pass empty (5/5 plans) — completed 2026-10-16
- [x] Phase 186: Host seam and harness honesty (5/5 plans) — completed 2026-10-16
- [x] Phase 187: Doctor and proof fidelity (7/7 plans) — completed 2026-10-16
- [x] Phase 188: Freeze and twin-05 (5/5 plans) — completed 2026-10-16

</details>

<details>
<summary>v25.0 iOS Host Setup & Digital Twin Proof (Phases 179–183) — planning closeout 2026-10-15</summary>

- [x] Phase 179: iOS Host Setup Without Hand Patches (4/4 plans) — completed 2026-10-13
- [x] Phase 180: Bounded Digital Twin Demonstration (7/7 plans) — completed 2026-10-15
- [x] Phase 181: Core Host-Command Seam (10/10 plans) — completed 2026-10-14
- [x] Phase 182: Loopback Origin for Local iOS Host (6/6 plans) — completed 2026-10-14
- [x] Phase 183: Close gap: twin source binding fails closed on uncommitted code (5/5 plans) — completed 2026-10-15

</details>

## Exact Next Action

Last completed phase:195 (21/21 plans; passed8/8 on actual main b8398c38). Active phase196: executing,10/17 plans complete. Plans01-09 retain optional/browser/vector,absence,privacy,policy and compile proof. Plan10:62 tests passed including30 real-script guard tests;three advisory helpers return closed results and exactlytwo arbitrary-extension records preserve denials and original throw/exit behavior. Candidate42 files/9 clauses/2 records;actual-main41 files/5 broad/2 stale findings,exact restoration and final capsule identities retained. Collection default stays report-only until Plan15. Next: `$gsd-execute-phase 196 --ws quality-ratchet-release`, resuming at196-11-PLAN.md. Do not repeat plans01-10,completed Phase195 work or Phase196 planning. All eight Phase196 requirements and GR-06 remain pending independent verification;SPEC-05/unclassified,ARCH-02/unclassified and WINDOWS40/41 process deviations need independent review;dependency guard,full Muex pilot and new CI remain pending. Original cleanroom debt stays with Phase197;adopter lane stays parked. No irreversible-operation approval transfers.
