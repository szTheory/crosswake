# Milestones

## v28.0 Truth and Release Train (Shipped: 2026-11-10)

**Phases completed:** 8 phases, 109 plans, 34 tasks

**Audit:** `tech_debt`, no blocker (milestones/v28.0-MILESTONE-AUDIT.md). SPEC-04 moved to v29.0 with its criteria intact. Threadline 0.1.1 deferred under D-31. Known verification overrides: 1 newly acknowledged (Phase 198 deferred items), 6 carried forward from a prior close (see STATE.md and the audit).

**Key accomplishments:**
- All six pre-existing queue PRs merged by merge commit, each behind its own one-use allow bound to head, with pin provenance verified; release PR #236 untouched.
- Root-proof failure tail now masks Bearer, secret-access-key, cookie and short values via one exported `maskSecretShapes`, the Maven fire-drill derived TOKEN/AUTH are masked before use, and both protections go red when removed.
- One contract test now owns the phase-proof schedule rule (floor >= 14 files, fixture control, exact pending list), and seven of the 14 weekly phase proof schedules are removed while `workflow_dispatch` is kept.
- No phase proof workflow carries a schedule any more (15 matched files, floor 14, fixture control kept), and one advisory read-only Weekly Canary runs the root proof on main each week.
- The controller workflow and its selector are deleted, the two monitor routes that depended on them refuse with exit 2, and a test with a negative control keeps both names out of the live tree.
- The macOS native capture is a dispatch-only, read-only workflow; the collateral run no longer waits on it; Dependabot actions update monthly in one version-updates group.
- PR2 landed, the first Weekly Canary on main was red (missing exact node 22.14.0), a gated fix-forward PR #254 landed, and the canary is now green on main; Dependabot security updates are on.
- The repository root now carries 15 allowlisted files; a root-allowlist test, proven red at HEAD (14 findings) and proven to fail on a live scratch root file and a live `.bundle`, keeps it that way.
- One command, `script/verify_published_cleanroom.sh <version>`, resolves and verifies the Hex, Maven and iOS mirror artifacts from a throwaway directory; the real 0.2.11 run passes all three legs, and a missing or tampered artifact exits 1.
- The root-proof failure tail now masks quoted, multi-word, mid-line header, Digest, URL-userinfo, JWT and access-key-ID shapes in linear time without masking plain prose, each proven by a test that was red first and by a mask-removed control (24 of 24 seeds leak) and a pre-fix-masker control (25 failures).
- PR #256 is merged to main by merge commit 5862a3d on a one-use `allow` bound to head 7db34f2, the verifier's four reproduction cases hold on the merged code, and all eleven review findings now have a recorded disposition.
- maskSecretShapes now masks credential keys written as escaped JSON, Elixir tuples, quoted Bearer values, next-line values, CLI flags, curl `-u` and `==` comparisons, and the add-mask guard rejects single-quoted or unterminated masks; every new test was recorded red first and replayed from its red commit.
- The masker now covers provider-prefixed tokens, PEM key blocks, userinfo/key-ID/JWT variants and query-string credentials, leaves literal nil/true/false/null values readable, and the GR-06 deferral rests on a recorded zero census; every new test was recorded red first and replayed from its red commit.
- PR #257 (merge 7621c0c) put the round-2 secret-masking fix on main, the on-main reproduction shows all nine leaked forms masked and the prose case unchanged, and GR-01 to GR-10 now have recorded dispositions (GR-06 deferred to Phase 196).
- Credential identifiers, nested inspect values, wrapped tuples and private-key armor are masked before root-proof diagnostics are sliced; incomplete armor consumes to EOF.
- Exact stdout registrations, per-row unmasked-window checks and bounded provider/CLI/URL/JWT scanners close the named GAP2 leak and proof gaps while pinning diagnostic costs.
- Planning and both Phase195 receipts are preserved; a fixed-capsule measurement helper proves source identity, rejects failed evidence, and restores its checkout in executed controls.
- Unrequested manifest and Plug proofs are explicitly excluded; requested proofs validate real artifacts and dependencies, with sixteen executed subprocess states distinguishing success, exclusion and failure.
- Elixir proves 15 loaded/9 completed requests and Swift proves 15/14; both real readers reject missing, shortened, empty and fully excluded corpora.
- Swift proves reply 2/2 and topology 5/1/1; three metadata readers independently require 15 requests, with 18 real loss controls and byte-exact restoration.
- Kotlin proves request15/14 and reply2/2; activation requires15 loaded requests with verdicts N/A, backed by12 real clean Gradle mutation controls.
- Journal suffix tables preserve constant errors; SafeObservation rejects trailing LF and revalidates every closed field and measurement before telemetry, logger and doctor projections.
- Core and five companions match 16 reviewed production runtime dependencies, including four optional declarations, through twelve fresh production Mix processes and 25 passing tests.
- The live workflow census accounts for 13 supported credential-connected statements across 28 workflows, with zero denied or unknown statements, backed by 207 passing masking tests and final-blob actual-main measurement.
- Official Muex 0.12.0 with `--no-tce` produced 271 killed and four surviving SafeObservation mutants; all five real known-kill/known-survive pairs discriminated and the 236 original selected tests passed after restoration.
- The full uncapped five-file process timed out at the conserved deadline without emitting a report or output; exact source restoration, forced compilation and236 selected tests passed. SPEC-04 remains pending.
- A process-derived candidate verdict (40 children, 0 failing) bound to a whole-file source identity, behind a reviewed replan amendment, an enforce-default absence guard recaptured on actual main, and an internal review that found and fixed a red full root run and a broken browser producer.
- PR 260 now sits on head bb291f01 with all 49 Crosswake CI check runs green on that exact commit, after a fresh 40-child candidate on the changed source identity and a privacy-gate fix that the plan's own gate caught before the push.
- The actual-main landed proof passed: all 40 children, no base drift, candidate identity equal, run in an isolated worktree of merge commit 51a1885c.
- Report-only `script/docs-report` counts planning leaks and broken relative links over the `mix.exs` extras, treats every unread or under-scanned input as UNVERIFIED (exit 2), and ships with a tested `mix test` gate helper that no longer trusts an exit code alone.
- `script/docs-report` now measures `mix docs` warnings (197 total, 2 in extras on main) with every failed or index-less run UNVERIFIED, the baseline is committed on a tree byte-equal to main before any doc edit, and DOCS-01/DOCS-02/SC1/SC2 state the amended decisions with the superseded clauses replaced in place.
- `verify_published_cleanroom.sh` now bounds and https-pins every network fetch, reports resolve and parse failures under their own reasons instead of `not_published`, binds the Maven POM to the exact project coordinate (proven on the real 0.2.11 POM), and fails closed on any missing tool its legs call.
- `verify_published_cleanroom.sh` now has a fourth `docs` leg that fetches README.md and guides/install.md at a 40-hex commit, parses every marked fence, builds a pinned `phx_new 1.8.13` Phoenix host with assets, and runs each `run` block verbatim under `bash -e` with an allowlisted environment and a per-step process-group time bound; the D-07a doctor mutation fails exactly `cleanroom: FAIL docs step doctor exit 1`.
- Without `CLEANROOM_DOCS_REF` the docs leg now reads README.md and guides/install.md from `repo.hex.pm/tarballs/crosswake-<v>.tar` (only those two members extracted), so docs and code are one artifact; against the real published 0.2.11 it prints the tarball source line and fails `parse unmarked_fence README.md`, and a real-network smoke generated a pinned Phoenix host, ran real `mix deps.get` under the scrubbed env, and failed exactly `step doctor exit 1`.
- The docs leg now executes `apply` blocks: a fixed substitution table maps the documented `my_app`/`MyApp` names and the `{:crosswake, "~> 0.2"}` requirement onto the throwaway host and the version under test, six idempotent modes (`create`, `append`, `deps`, `esbuild-args`, `js-hook`, `router-route`) inject the fragment into the named host file under their own failure rules, and a harness `mix compile` runs before each file's doctor block and fails on a non-zero exit or on a warning located in a file an apply block wrote.
- The docs leg can no longer pass with a wiring step skipped, absent or NOT_APPLICABLE: `since=` above the version under test is skipped and counted, each doc file must execute a bridge-hook, both esbuild flags and `Crosswake.Bridge.attach()` block, the `:ios_host` step is exempt only below 0.2.12 (named on a `docs deferred` line and in `deferred=`, never in `executed`), and an `executed` count under the floor is red.
- The rewritten README and install guide are now guarded in the merge-blocking suite without the network (markers, repo-only labels, wiring tokens, one route id, `since=0.2.12` only on the ios-host block), `DOCS_EXECUTED_FLOOR` is pinned from the placeholder 1 to the measured 18, the documented `:ios_host` values pass the current `IOSHostConfig` validator, and a fail-closed audit of the published 0.2.11 tarball shows every executed step has a reader there, with `:ios_host` the only deferral.
- The companion matrix now carries no version literal and no registry-state wording (a `Latest on Hex` link per package instead), the phase132 drift test proves that with a 5-row set floor and injection, reorder and empty-matrix controls, and one live `mix crosswake.release.status --live` run (rc 0) shows all five matrix packages published with state `ok`.
- CHANGELOG no longer says any release is current; one version-free sentence points to GitHub Releases and hex.pm, the repository's own `publish.parity` still passes through a new pointer-keyed candidate rule, and `[Unreleased]` is guarded by wording, pointer and release-version tests with mutation controls.
- The Android UAT guide now has no automated verification stamp and states plainly that no emulator or device run is recorded; it lists exactly the 15 registry capability families, enforced by a two-way set-equality test; the telemetry guide lists the offline replay event, and see_it_run names the commit the twin receipt attests.
- The finished branch passes the full suite (3134 tests, 0 failures, floor 3114), its docs-report after-counts sit beside the baseline, the baseline-first order is proven from history, and a doctor step that fails against published 0.2.11 turns the docs leg red.
- Real four-leg clean-room PASS against published 0.2.11, the `:ios_host` step recorded as a named Phase 199 deferral, and PR 268 green (38 of 38 Crosswake CI checks) after a separately merged lock-bump fix.
- Every linked guide section that names the `:ios_host` declaration or manifest schema `1.2.0` now says no published release has it yet and points to CHANGELOG `[Unreleased]`, the two generated guides got it through their renderers, and one network-free merge-blocking test keeps all eight claim pairs qualified until Phase 199 removes them.
- Kotlin core JVM tests now run on the AOSP-derived android-json artifact, the request envelope rejects non-string required fields, SemVer fails closed on signed components, and the choices are recorded in 198-DECISIONS.md. JVM evidence only; nothing was run on a device.
- BridgeChannelBoundaryTest now covers every D-12 boundary group with counted near-miss loops and positive controls; the Kotlin core JVM suite is at 37 tests with no failures or skips. JVM evidence only; nothing was run on a device.
- A stdlib checker forces a fresh `testDebugUnitTest` run and fails closed unless fresh JUnit XML shows at least 25 tests, zero failures or skips, XML count equal to the source `@Test` count, 10 or more boundary testcases and every load-bearing named test; a 13-test fixture selftest proves every reason, and both run in the merge-blocking `android-package-unit` job. JVM evidence only; nothing was run on a device.
- One command, `bash script/verify_android_foreign_host.sh`, generates a host with the published Hex generator, builds it against Maven Central in a clean HOME with no credentials, proves the run is not vacuous, and requires a wrong-coordinate control to fail for the right reason.
- `bash script/android_foreign_promotion.sh` counts clean foreign-host CI runs from run history and evidence artifacts (`clean_runs=N/2`), and the bearings report prints that line, so "required only after two clean runs" is measured and never stamped.
- A post-publish check that the SwiftPM mirror tag v<version> holds exactly the released iOS package tree and is the newest mirror tag, proven on the real 0.2.11 mirror in both directions, plus the user's recorded release gate design (D-01..D-08) and the gate protocol.
- Of the three non-release PRs, 252 (Dependabot) and 258 (Codex profile switch) are closed with recorded reasons and nothing was merged, so main did not move; PR 253 (collateral refresh) is still open because its close was denied and is left to the user.
- Four protected GitHub environments now exist and a credential-free preflight, called from the release guard on every push, blocks any linked or companion release if one is missing or unprotected; it failed for real before creation and passes after.
- All eight publisher jobs now wait for an approval environment, and the core run is chained Hex, then Maven, then the iOS mirror; five scanner checks and nine new tests keep each gate from being removed silently.
- Release Please now waits for a `release-tags` approval before creating tags (ordinary pushes still reach it through a `!cancelled()` condition), both runbooks describe the per-step gates, and every iOS mirror publish is followed by a read-only mirror tag check that pages through the failure alert.
- The hosted companion receipt attestation now takes any of the five companions through `CANDIDATE_PACKAGE`, and `companion_publish_authorization.sh render|check` produces and verifies the companion REL-17 trailer, proven against the real release-please guard predicate and context loader.
- The per-step release approval gates are on main (PR 278, merge commit a9c4ff74), the first post-merge Release Please run flowed with a PASS hosted-runner environment preflight, and a git-only predicate proven by 19 controls and 11 mutants shows PR 236 (0.2.12) and PR 262 (threadline 0.1.1) are untouched Release Please commits with CI green on their heads.
- Release PR 236 (0.2.12, head efbc7912) was pinned and rehearsed: Hex and iOS rehearsals changed nothing, one Maven fire drill ran behind the user's `core-maven-drill` allow and was dropped with the real 0.2.12 POM still absent, and the hosted attestation produced one READY FOR APPROVAL receipt (13 of 13 checks, publication NONE, expires 2026-11-22).
- The docs that will ship in 0.2.12 (read from PR 236 head efbc7912) pass the REL-06 clean-room against published 0.2.11 on all four legs with `deferred=ios_host`; the REL-17 pre-merge gate passes on that head and the `publish successor core 42390193460` trailer is rendered, checked, and staged in an unrun merge command.
- Release PR 236 (Crosswake 0.2.12) is merged as `1dcdaad8dea087ddebd62bf7ca0515988d2d3f9c` under its own allow, the three source tags and GitHub Releases exist at that commit under one shared allow, and the release run now waits at the Hex gate with nothing published.
- crosswake 0.2.12 is live on Hex with docs and io.github.sztheory:crosswake-shell-core-android:0.2.12 is live on Maven Central, each published only after its own one-use allow and in Hex-then-Maven order; the release run now waits at the iOS mirror gate with nothing else started.
- The closeout branch `docs/199-record-0-2-14-published` now carries the SC6 edits, the condensed AGENTS.md, 82 planning paths, the 43 pre-merge raw sources plus the gate-order helper (land_and_retire, D-29) and an `.awk` rule for the scan; every landing file is privacy-scanned with one disposition per hit, the local gates pass, and nothing was pushed.
- PR 293 recording 0.2.14 as published is merged under the standing exception (CI green on head 2c722930, merge commit 323227b5), the docs branch is retired with a zero-gap proof (267 paths), and SC4 is annotated as unmet because seven local branches remain: five preserved on origin but not deleted locally (the permission system refused `git branch -D`) and two kept for privacy hits.
- The default `mix crosswake.gen.shell ios` now writes `CrosswakeHostSettings.xcconfig` once, so a plain generated project builds (xcodebuild exit 65 before, 0 after), proven by a regression test that failed on the 0.2.12 generator and passes on the fix.
- `script/verify_default_ios_generation_build.sh` builds a default-generated iOS project with the release clean-room flags, repeats the build with the settings file removed to prove it can see the defect, and was measured failing on the exact 0.2.12 generator and passing on the fix in both the local form and the no-flag remote form built against the public mirror; it is now a blocking step in `phase79-ios-proof`.
- PR 282 (default iOS generation writes the settings file it references, plus the pre-release build gate) was merged to main as merge commit `e8d44c6c` after Crosswake CI was green on its exact head `3696f38c`; the new gate step passed on the hosted macOS runner with its control build detected in 32 seconds, the run cost 174 billable minutes against a baseline of about 250, and issue 281 now carries the diagnosis and the fix link.
- Release PR 280 (0.2.13, head `5a6a7521`, base `e8d44c6c` = the fix merge) was pinned after Crosswake CI passed on that exact head including the new default-iOS build gate; Hex and iOS rehearsals changed nothing, one Maven fire drill ran behind the user's `core-maven-drill` allow and was dropped with the real 0.2.13 POM still 404, and the hosted attestation produced one READY FOR APPROVAL receipt (13 of 13 checks, publication NONE, expires 2026-11-23).
- The docs that will ship in 0.2.13 (read from PR 280 head `5a6a7521`) pass the REL-06 clean-room against published 0.2.12 on all four legs with `deferred=none` and `executed=20`; the exact candidate head's no-flag remote form builds against the public mirror at 0.2.12 with its negative control detected; the REL-17 pre-merge gate passes on that head and the `publish successor core 42558226150` trailer is rendered, checked and staged in an unrun merge command.
- Release PR 280 (Crosswake 0.2.13) was merged under the user's allow as `0aa184704009c5baf9c3550cf7cf7fde9228f2b8` (parents base `e8d44c6c` and approved head `5a6a7521`, tree equal, one trailer); the release run passed its guard, the user's second allow approved only `release-tags`, three source tags and releases now exist at that commit, and the run waits at `publish-hex` with nothing published.
- The 0.2.13 release run published Hex, Maven and the iOS mirror and passed the iOS clean-room proof, then ended FAILURE at the exact-public proof; the plan's COMPLETE truth was met by the 0.2.14 run 42713010358 under Phase 201, and this plan is closed by Phase 201 plan 08.
- Phase 201 plan 08 carried out this plan's closeout from the COMPLETE 0.2.14 run: both earlier runs are dispositioned with nothing re-run, issue 281 is closed, the deferred items keep their owners, and REQUIREMENTS, ROADMAP and STATE agree.
- Three real Hex tarballs (public rulestead 0.1.1, its Hex 2.7.0 rebuild, public core 0.2.13) plus a 19-test file that reproduces the companion `digest_mismatch` on real data: red on the unchanged digest rule (9 failures, exactly the ones reasoned), fix still to come in Plan 03.
- The Phase 201 planning record (PR 286) and the standing release approvals with their matching BEARINGS invariant, runbook sentences and contract test (PR 284) are both on main, each as a CI-green merge commit pinned to its head, planning record first.
- `Artifact` now validates `build_env` fail-closed for every package and leaves it out of the metadata digest only for the five companions, so the real public rulestead 0.1.1 tarball and its Hex 2.7.0 rebuild give equal digests while the core still digests its own Hex version. One `artifact-provenance` stderr line per package names the builder Hex version, and six mutations show every control goes red when its coverage is removed.
- On the six real 0.2.13 tarballs the old rule reproduces the false positives (metadata 1/6, payload 6/6) and the companions-only fix removes them for all five companions under both Hex 2.5.1 and 2.7.0; the core still differs when a different Hex builds it. The fix then landed on main as PR 287, a merge commit pinned to its CI-green head.
- Release PR 283 (0.2.14, head `40739816`, base `fdc218f9` = the fix merge) was pinned after a two-read bounded poll showed it carried both the build_env fix and the standing approvals; Crosswake CI was green on that exact head including the default-iOS build gate, the Hex and iOS rehearsals changed nothing, one Maven fire drill ran behind the user's `core-maven-drill` allow and was dropped with the real 0.2.14 POM still 404, and the hosted attestation produced one READY FOR APPROVAL receipt (13 of 13 checks, publication NONE, expires 2026-11-23) for a core candidate built by Hex 2.7.0.
- The docs that will ship in 0.2.14 (read from PR 283 head `40739816`) pass the REL-06 clean-room against published 0.2.13 on all four legs with `deferred=none` and `executed=20`; the exact head's no-flag remote form builds against the public mirror at 0.2.13 with its negative control detected; the REL-17 pre-merge gate passes on that head with the policy digest unchanged since 0.2.11, and the `publish successor core 42706539601` trailer is rendered, checked and staged in an unrun merge command. Nothing was merged, tagged, published, dispatched or pushed.
- 0.2.14 is on Hex, Maven Central and the iOS mirror, and its release run (42713010358, attempt 1) ended COMPLETE with the exact-public proof passing for all six packages as `fully_proven`, the failure that stopped 0.2.13 is fixed live; one clause is unmet: the run's ledger step opened no 0.2.14 bot PR because the 0.2.13 ledger PR (285) is still open.
- 0.2.12 and 0.2.13 are reconciled in writing against the COMPLETE 0.2.14 run, issue 281 and TODO-012 are closed, REL-08 and REL-09 are Complete, and both ledger lines plus 187 planning-record paths reached main through one privacy-cleared, CI-green, pinned PR (289, merge commit af1dd94e).

---

## v27.0 Land and Clean Up (Shipped: 2026-10-24)

**Status:** Shipped with tech debt; 2026-10-24. The v25 and v26 product code and the v24–v27 planning records are on GitHub `main` with CI green. No package was released.
**Coverage:** 18/18 requirements (INV, FIX, LAND, CLEAN); 5/5 phases (189–193); 55 plans; 127 tasks counted from the plan files (the installed CLI reported 1, an undercount).
**Closeout type:** `verified_closeout` — all five phases verified `passed`; the [audit](milestones/v27.0-MILESTONE-AUDIT.md) is `tech_debt` with no blocker.
**Known verification overrides:** 0 newly acknowledged, 6 carried forward from v23.0 (see STATE.md Deferred Items). No phase verification override.
**Git:** PR #242 (merge `d12aed75`, the landing), PR #243 (`ed853e38`, 193 PR 1), PR #244 (`f34baa7b`, 193 PR 2); 125 commits from `d0dbdf7b` to `f34baa7b`. Each merge followed a one-use `allow`. No tag.

### Key accomplishments

- Every copy of the work that was not on GitHub `main` was inventoried by content (258 rows plus 7 PR dispositions) and backed up outside the temp folder; all 76 restore tests passed before anything was removed (Phase 189).
- The seven carried v26 warnings were fixed, so no landed check passes while checking nothing: empty privacy scopes fail, every gate label has a failing self-test, the gate git helper is pinned, registry timeouts are reported, nested-host provenance is honest, the guard pin equals the real count (253), and the physical-iPhone preflight refuses bad input (Phase 190).
- One integration branch built from current `main` in a durable clone carried the 94 candidate commits, the 4 FIX commits and the planning records, with a clean HEAD-bound privacy scan and all nine local suite stages passing (Phase 191).
- PR #242 passed every required Crosswake CI check on its exact head and merged as `d12aed75` after the user's `allow`. `main` CI was green on the merge commit and every publish job was skipped (Phase 192).
- The recovery checkout was retired for a clean `main` checkout. 300 of 306 listed local copies were removed after hash-matched backups, 6 were kept with reasons, and AGENTS.md "How changes land" replaced the freeze rules with branch-from-`main`-and-PR (Phase 193).

### Retained debt

See the [debt disposition](milestones/v27.0-closeout/debt-disposition.md). Open first: the `crosswake-integration-191` clone holds remote-tracking tips that exist in no backup (back them up, then remove it), and SEED-025's credential-masking gap in CI failure output.

Archive copies: [roadmap](milestones/v27.0-ROADMAP.md), [requirements](milestones/v27.0-REQUIREMENTS.md), [audit](milestones/v27.0-MILESTONE-AUDIT.md). Phase folders stay at their original paths; the workstream REQUIREMENTS.md was removed.

**Closeout record:** [CLOSEOUT.md](milestones/v27.0-closeout/CLOSEOUT.md).

**Next:** `$gsd-new-milestone --ws quality-ratchet-release`; fresh scope is unselected.

---

## v26.0 Harden Before Trust (Planning closeout: 2026-10-16)

**Status:** Planning closeout complete with tech debt; 2026-10-16. Product code is not delivered; it exists only in the `/private/tmp` candidate.
**Coverage:** 18/18 requirements; 5/5 phases (184–188); 37 plans; 96 tasks counted from the plan files (the installed CLI reported 21, an undercount).
**Closeout type:** `verified_closeout` — all five phases verified `passed`; the [audit](milestones/v26.0-MILESTONE-AUDIT.md) is `tech_debt` with no blocker.
**Known verification overrides:** 0 newly acknowledged, 6 carried forward from v23.0 (see STATE.md Deferred Items). No phase verification override.
**Git exceptions:** No commit, tag, staging, branch/worktree change or remote write in the recovery checkout.

### Key accomplishments

- The twin's clean-tree probe can no longer be fooled by git index flags or local/global config: one pinned git funnel serves every product probe call, and `mix crosswake.proof_lane.twin_preflight` tells a maintainer whether a run would be allowed without using up a run root (Phase 184).
- The absence checker, the v25 test loops and the twin runtime helpers now fail when they examine nothing; a guard script refuses an empty scan scope (Phase 185).
- The legacy host-command path denies instead of granting every `host.*` key, doctor stops passing on unreadable input and redacts paths, the physical preflight refuses a loopback origin, and the loopback harness reports its own failures (Phase 186).
- Doctor findings carry actionable details (unmanaged paths, router), an unbacked offline island is an error, proof evidence records real provenance instead of placeholders, and the A/D adopter-request deferrals are recorded with reopen triggers (Phase 187).
- All v26 changes were frozen at candidate `a53fbef`, a 30-label scripted go/no-go passed, and twin-05 ran exactly once and passed (10/10 groups, 7/7 identity joins); the result is byte-copied into planning (Phase 188).

### Retained debt

See the [debt disposition](milestones/v26.0-closeout/debt-disposition.md). Fix before the next twin run or twin-touching change: 188 WR-01 (empty-folder privacy scan passes), 188 WR-08 (gate labels without a failing self-test), the unpinned `g()` gate helper, 185 WR-02, 187 WR-02 and the stale guard pin (249 vs 253). 186 WR-01 (LOOP-07 residual) needs an owner decision. Two hand-offs to Phase 188 were not done there: the guard pin raise and the Swift G4 baseline failure.

### Source and archive limits

Candidate: `/private/tmp/crosswake-phase180-impl`, HEAD `a53fbef70d20e6ee49f1ebd2ee783c991f95a7b4` (tree `f7c4d7dc`), v26 commits over `50fcd57`. Delivery into the authoritative tree needs separate authorization. Residual external gates: a physical signed-iPhone run and the first adopter's sanitized route handoff. No whole-project LOC or milestone commit range is asserted.

Archive copies: [roadmap](milestones/v26.0-ROADMAP.md), [requirements](milestones/v26.0-REQUIREMENTS.md), [audit](milestones/v26.0-MILESTONE-AUDIT.md). Original phases, the root audit file and REQUIREMENTS.md remain in place.

**Closeout record:** [CLOSEOUT.md](milestones/v26.0-closeout/CLOSEOUT.md).

**Next:** `$gsd-new-milestone --ws quality-ratchet-release`; fresh scope is unselected.

---

## v25.0 iOS Host Setup & Digital Twin Proof (Planning closeout: 2026-10-15)

**Status:** Planning closeout complete with tech debt; 2026-10-15. Product code is not delivered; it exists only in the `/private/tmp` candidate.
**Coverage:** 20/20 requirements; 5/5 phases (179–183); 32 plans; 78 tasks counted from the plan files (the installed CLI reported 6, an undercount).
**Closeout type:** `verified_closeout` — all five phases verified `passed`; the [re-audit](milestones/v25.0-MILESTONE-AUDIT.md) is `tech_debt` with no blocker.
**Known verification overrides:** 0 newly acknowledged, 6 carried forward from v23.0 (see STATE.md Deferred Items). No phase verification override.
**Git exceptions:** No commit, tag, staging, branch/worktree change or remote write in the recovery checkout.

### Key accomplishments

- A compile-only Phoenix `:ios_host` declaration generates the iOS host resources and an Xcode-resolved simulator app identity with no hand patches; managed outputs regenerate safely and an interrupted update blocks the build until recovery (Phase 179).
- Routes declare `host.*` commands in a central versioned registry; the manifest (schema 1.2.0) is the sole authority, and activation delivers them to the native session and the bounded-shell offline island (Phase 181).
- A local/dev `:ios_host` mode allows an http loopback origin through `NSAllowsLocalNetworking` only; production stays HTTPS-only and the proof lane refuses local mode (Phase 182).
- One command, `mix crosswake.proof_lane.verify_twin ios`, runs the bounded reference twin across ten fixed groups and 49 observations and writes a privacy-safe receipt (Phase 180).
- The twin refuses an uncommitted or untracked candidate (`source_dirty`) before compile and after the run, and a missing source join can never pass; twin-04 passed against the committed fix `50fcd57` (Phase 183).

### Retained debt

See the [debt disposition](milestones/v25.0-closeout/debt-disposition.md). The two items that can degrade silently are 183 WR-01 (git index flags hide a modified file from the clean-tree probe) and WR-02 (`core.filemode` not pinned). Fix them in the next twin-touching change, before the next run root (twin-05).

### Source and archive limits

Candidate: `/private/tmp/crosswake-phase180-impl`, HEAD `50fcd5743243c0b20275a7e2bd9338bf25468687` (tree `d71bc587`), eight commits over `da53c54`. Delivery into the authoritative tree needs separate authorization. Residual external gates: a physical signed-iPhone run and the first adopter's sanitized route handoff. No whole-project LOC or milestone commit range is asserted.

Archive copies: [roadmap](milestones/v25.0-ROADMAP.md), [requirements](milestones/v25.0-REQUIREMENTS.md), [audit](milestones/v25.0-MILESTONE-AUDIT.md), [initial audit](milestones/v25.0-MILESTONE-AUDIT.initial.md). Original phases, the root audit files and REQUIREMENTS.md remain in place.

**Closeout record:** [CLOSEOUT.md](milestones/v25.0-closeout/CLOSEOUT.md).

**Next:** `$gsd-new-milestone --ws quality-ratchet-release`; fresh scope is unselected.

---

## v24.0 Repository Cleanup & Maintenance (Planning closeout: 2026-10-12)

**Status:** Planning closeout complete with six retained debt records; 2026-10-12.
**Coverage:** 8/8 requirements; 3/3 phases; 15 plans; 28 tasks counted by the installed CLI.
**Closeout type:** `verified_closeout` — all phases verified, with retained milestone debt and carried-forward artifact acknowledgements.
**Known verification overrides:** 0 newly acknowledged, 6 carried forward from v23.0 (see STATE.md Deferred Items). No phase verification override.
**Git exceptions:** No commit, tag, staging, branch/worktree change or remote write.

### Key accomplishments

- Captured all 119 changed paths and proved recovery of 170 eligible units before any cleanup.
- Validated supported maintenance commands while retaining all 78 uncertain historical modes and both unproven reader comparisons.
- Assigned concrete actions to 20 open issues and 4 PRs in the audit refresh.
- Updated maintenance guidance and derived assertion snapshots while preserving all 230 assertion keys and 52 frozen guard rows.
- Delivered the eight-file maintenance proposal as PR #238; it remains open and unmerged.
- Joined nine local verifier stages and 48 required hosted checks to governed merge commit f2d8875ee52d9679157c73b4a701b510ee612cb8.

### Retained debt

- Preserve all 15 original SUMMARY requirement arrays and use the independent audit cross-reference.
- Retain Plan93 source and artifacts until its original reader and receipt support comparison.
- Retain mirror source and artifacts until its original reader and receipt support comparison.
- Retain the historical guidance fixture under its original epoch; validate current scoped state separately.
- Retain the first earlier full-run failure as undiagnosed unless original assertion output appears or an equivalent failure reproduces.
- Retain the second earlier full-run failure under the same condition.

### Source and archive limits

Candidate range: d0dbdf7bf196cea167ced3c50cf620bf3cb2452b → 3e8a4b2601b542323edfd6053f25e56c67873b47. Final verified merge object: f2d8875ee52d9679157c73b4a701b510ee612cb8, tree 27f4073039b4dd976492127549603a76ce22499b. Eight candidate files, 166 additions and 31 deletions according to retained candidate evidence; this is not a whole-milestone Git range. Planning is uncommitted. Summary completion dates span 2026-10-11 through 2026-10-13 UTC; local closeout date is 2026-10-12. No whole-project LOC or fabricated milestone commit range is asserted. Full proof was warm-cache; missing failure output and missing delivery actor attribution remain unavailable.

Archive copies: [roadmap](milestones/v24.0-ROADMAP.md), [requirements](milestones/v24.0-REQUIREMENTS.md), [audit](milestones/v24.0-MILESTONE-AUDIT.md). Original phases, audit supplements and REQUIREMENTS.md remain in place. Protected history retains original bytes and paths.

**Closeout record:** [authorization](milestones/v24.0-closeout/authorization.md) and [debt disposition](milestones/v24.0-closeout/debt-disposition.md).

**Next:** `$gsd-new-milestone --ws quality-ratchet-release`; fresh scope is unselected. PR #238 merge remains a separate decision; the adopter lane stays parked.

---

## v23.0 Release Pipeline Repair & Proof-Lane Truth (Archived: 2026-10-11)

**Closeout type:** `override_closeout` — delivered with a preserved historical failure.
**Coverage:** 42/43 requirements; Phase 175 8/9; integration 8/8; flows 4/4.
**Phase scope:** 169–175. Phases 169–174 passed their dated reports; their current manager projection is stale. Phase 175 is archived with SC-1 breached, never marked passed.
**Known verification overrides:** 6 newly acknowledged, 0 carried forward (see STATE.md Deferred Items). Original bytes and statuses are retained in `milestones/v23.0-closeout/original-artifacts`.

### Key accomplishments

- Diagnostic commands distinguish failed checks from checks that could not run and report the specific cause.
- Release versions derive from the approved manifest; six packages retain independent source references and proof.
- Collection assertions have nonempty guards and a checked 230-site inventory.
- Crosswake 0.2.11 passed three publishers, both generated native consumer builds, exact-public proof and the six-child COMPLETE rollup.
- Chimeway 0.1.2 passed its own fresh gate, ordinary Hex publisher, public-host doctor and direct registry check.
- PR #237 proved ten real installer-before-doctor pairs and passed all 49 CI jobs without another publication.

### Known Gaps

- REL-10 remains unchecked: the incident-response runbook was absent from PR #147's first publish. Later releases cannot change that timing.
- Six accepted historical high limitations and twelve open lower findings remain; current blocking high findings: zero. Nyquist coverage is partial, as detailed in the archived audit.
- Eighteen historical plans lack matching numbered summaries. Fifteen are excluded by the CLI as superseded; Plans 46–48 retain blocked historical states and their forward deliverables are fulfilled by Plan 148. No missing summary was fabricated.
- Debug and v22 records are acknowledged for closure, not rewritten as fixed or passed. Stopped and PARTIAL release attempts remain unchanged.

### Stats and source boundaries

Seven phases; CLI active-plan inventory: 163 plans, 193 tasks. Raw historical files: 178 plans, 161 summaries. Approved-main range `ae08fba33d218bcc7c2a98efd47e543a65a1076a` → `d0dbdf7bf196cea167ced3c50cf620bf3cb2452b`: 371 files changed, 67471 lines added, 1474 removed (0 binary entries), 2026-09-17 → 2026-10-11. This range excludes uncommitted local planning history.

Actual published source: core merge `6da6df6f9ddc0f48614fd99c50decc6dc23387c4`; companion merge `2dbde2d9be8adfa36009e20bf894b00a5bb63e87`; final installer repair merge `d0dbdf7bf196cea167ced3c50cf620bf3cb2452b`. The local milestone tag records planning closeout; it is not a package release tag or a claim that this recovery checkout is published source.

**Archive:** [roadmap](milestones/v23.0-ROADMAP.md), [requirements](milestones/v23.0-REQUIREMENTS.md), [audit](milestones/v23.0-MILESTONE-AUDIT.md), [phase history](milestones/v23.0-phases/).
**Next:** `$gsd-new-milestone --ws quality-ratchet-release`. Fresh scope remains to be chosen; adopter work remains parked.

---

## v22.0 Quality Ratchet & Release Readiness (Shipped: 2026-09-15)

**Phases completed:** 5 phases, 48 plans, 100 tasks

**Closeout type:** `override_closeout`

**Known verification overrides:** 11 newly acknowledged, 0 carried forward

- Phases 167 and 168 both carried `stale` verification at close — their covered files changed
  after verification ran. 167 passed on 2026-09-12; 168 was re-verified at 5/6 must-haves with
  status `human_needed`. Neither was re-run; the milestone closed over both.
- 9 seeds were **deliberately left unacknowledged** so they keep surfacing. `SEED-017` is marked
  BLOCKING before any release past 0.2.1, and suppressing it at a milestone close is the exact
  failure it exists to prevent.
- 17 stale artifacts from archived milestones (v3.2 → v19.0) were acknowledged. Six of those, in
  Phase 121, could not be acknowledged through the CLI at all — the audit scanner reads GFM table
  rows as items but `audit-open acknowledge` refuses to write to a table-row span
  (`audit.cjs:1455`), so the scanner surfaced items its own writer could not clear. All six were
  re-run and pass; the record had gone stale. Worth reporting upstream against
  `@opengsd/gsd-core` 1.14.0.

### Known Gaps

- **The post-publication proof lane has never executed at any release.** Carried to v23.0 as
  `SEED-017` with `TODO-009` (release graph welded to 0.2.1 — any other version tags and then
  publishes nothing), `TODO-011` (companion clean-room lane green at zero of three releases
  inspected), and `TODO-012` (exact-public proof structurally unsatisfiable under D-15/D-16).
  An interim CI tripwire is on `main`.
- Phase 168's single behavior-unverified must-have — the exact-public clean-room proof against the
  live 0.2.1 family — is **deferred, not passed**. It must not be read as evidence that 0.2.1 is
  unsound, nor as evidence that it is proven; the repository simply cannot yet demonstrate
  soundness after publication.
- **PR #164 (`chore: release main`, proposing 0.2.2) must not be merged until SEED-017 lands.**

**Key accomplishments:**

- Patched Phoenix/LiveView/Plug/Bandit/hpax locks now pass independent Hex audits through one fail-closed command and one literal merge-blocking result.
- Strict workflow and executable-test ownership now compose every Phase 164 contract into one credential-free, fail-closed aggregate.
- Exact example-host resource ownership now supports a residue-checked parallel matrix across three tagged and complete-suite seeds.
- Exact aggregator leaf parity and an 11-class credential-free result matrix now prevent omitted, unknown, cancelled, or otherwise non-success work from becoming green.
- Owned WAL/SHM teardown and explicit broad-lane authority close the Phase 164 isolation gap without changing workflow topology.
- Sanitized current-main evidence and a strict authority snapshot now precede a NUL-safe documentation classifier, literal documentation proof, and checkout-free Crosswake CI umbrella.
- A closed documentation classifier and exact four-way proof inventory now guard a 46-job maximum checkout-free Crosswake CI shape before migration begins.
- Strict-lower cancellation now runs through a pure closed selector and a least-privilege default-branch controller that never executes pull-request code.
- Portable Android JVM proof, exact compiled-cache identities, and repository-wide timeout and runner audits now remove macOS waste without widening Android or weakening release trust.
- Core, security, example-host, hermetic-engine, and commerce PR proof now runs once as twelve literal Crosswake CI leaves while ten frozen legacy contexts and scheduled advisories retain their distinct authority.
- Eight named gating, companion, provider, operator, auth, closeout, and subscription proofs now run once under central PR classification while advisory trust stays isolated.
- Four named domain proof leaves now run once through the central classifier, with privacy-safe documentation scheduling and exact frozen-context compatibility preserved.
- Native, browser, offline, package, mirror, and focused documentation proof now runs once through a 40-leaf closed PR graph with explicit runner and advisory boundaries.
- One pull-request-only Crosswake CI graph now owns forty-four required proof leaves while preserving a visibly red, non-authoritative brand visual sibling and all twenty-seven frozen compatibility contexts.
- Exact-SHA live probes proved the complete Crosswake CI topology and monotonic cancellation, then added one strict umbrella context beside all twenty-seven legacy authorities while leaving retirement unapplied.
- The maintainer explicitly approved one freshly verified, digest-bound retirement proposal while strict dual branch protection remained unchanged.
- Strict main protection now requires only `Crosswake CI`; all migration-only compatibility conclusions are gone while the forty-four literal proof leaves remain intact.
- Exact landed CI source provenance and privacy-safe observations now close Phase 165 without claiming an unsupported efficiency improvement.
- A closed nine-stage Node runner now gives maintainers one strict repository proof facade with literal CI ownership, exact preflight rules, and dependency-aware failures.
- A dependency-aware repository runner now continues independent proof, blocks invalid chains, restores invocation-owned state, and reports deterministic non-disclosing results.
- A closed artifact policy now classifies repository intent and regenerates eight tracked contracts byte-for-byte without staging, leaking suspicious contents, or disturbing pre-existing state.
- A mechanically exact ownership ledger now closes the v22 audit cone, while an explicit Playwright repository mode proves first-attempt behavior against fresh server and invocation-owned output state.
- Crosswake CI now consumes the same fixed repository-stage facade as local verification, with mutation-tested ownership closure and one bounded recurring contract gate.
- A fail-closed remediation queue now binds the sole proven browser correction to its exact source owner and regression while making zero findings explicit and deterministic.
- Exact tracked commits can now be verified from dirty source repositories using a checksum-pinned, invocation-local Darwin/arm64 toolchain without leaking worktree bytes, private logs, or global state.
- Exact-commit proof now records nine passing repository stages, byte-identical clean Git state, unchanged index state, and privacy-safe bounded evidence for supported code SHA `1ddf3357973d1cfdff4f2b6140115bdb2f424fd2`.
- A validated three-layer claim owner now keeps reusable contracts, dated reference-host evidence, and blocked first adopter activation distinct across generated guides and parked state.
- A fixed-purpose Mix command now writes or observationally checks both canonical documentation projections, while the existing artifact registry validates and restores both generator families independently.
- The existing documentation leaf now checks generated parity without writes, proves semantic current truth, and keeps generated-guide reviews inexpensive under the sole Crosswake CI umbrella.
- Answer-first authored guidance now routes six reader jobs to current executable owners, generated support truth, bounded recovery, and an explicit Phase 168 publication stop.
- All seven setup-java uses now share the official immutable v6 commit, and PR #121 merged only after exact-head Crosswake CI and fresh-default reachability proof.
- Exact package-floor truth and Phase41-partitioned root verification landed through an ancestry-preserving, 47-of-47-green PR transaction.
- The narrow PackStore waiter-closure cleanup landed as one exact-tested Swift commit, with 47-of-47 same-head CI and receipt-first protected-default integration.
- Seven ordinary PR dispositions, separate recovery provenance, and a tree-identical exact-head closeout merge with a bounded Phase 168 handoff
- Exact seven-field tuple membership now admits only reusable Crosswake authority, retained reference-host evidence, and blocked first adopter activation while rejecting every mixed or incomplete authority claim.
- An exact five-blob protected-default landing, tracked historical runtime authority, and cursor-complete live deferral-marker proof establish trustworthy inputs for the 0.2.1 candidate.
- A closed Elixir authority now binds exact candidate observations, derives five fail-closed states, and emits one canonical JSON receipt with deterministic human projections through the fixed 0.2.1 Mix command.
- Six exact-ref Hex packages now produce officially unpacked, content-addressed observations, while a closed validator proves the 0.2.1 core/native tuple and independent companion compatibility floors.
- Six built package payloads now pass a real `phx_new 1.8.13` five-profile companion matrix twice from isolated state, while exact-public proof remains fail-closed and publication-gated.
- Four fail-closed mirror modes now prove the public baseline and candidate write authority while keeping atomic ordinary publication structurally separate from exact-ref recovery.
- Existing trusted workflows now rehearse an exact candidate without mutation, then require one approved merge with an identical tree before an honest, independently observable Hex/iOS/Android 0.2.1 release graph can run.
- The existing Crosswake CI now provides fast candidate feedback on ordinary PRs and exact-head full local proof at release boundaries, paired with read-only linked-coordinate status and one seven-step approval runbook.
- All reversible 0.2.1 readiness work landed before a fresh Release Please candidate was bound to complete trusted proof, producing one exact receipt and one explicitly approved—but still unexecuted—irreversible release decision.

---
