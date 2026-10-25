# v28.0 Research Synthesis (DRAFT, not committed)

Synthesized 2026-10-24 from seven reports (ROADMAP-PROCESS, TEST-QUALITY, CI-CD-HYGIENE, ARCHITECTURE-QUALITY, TWINS-AND-PROFILES, JTBD-PERSONAS, DOCS-QUALITY), AGENTS.md and the ADR. Binding user decisions applied: Android unfrozen ASAP; synthetic profiles may reopen stop-list items via recorded amendment; release pipeline repaired, then released on a cadence behind one-use `allow`. No real adopter is named or inferred anywhere.

## 1. Executive read

Crosswake's contracts are strong (names in docs match code; fail-closed denials; privacy-scoped offline). Its weak spots are all one defect class seen from seven angles: **checks and claims that are green or "verified" while asserting nothing true** (docs 17 of 42 claims drifted and one test pins the false value; release PR structurally red because goldens embed the version; Dependabot red because tests pin literal SHAs; Muex exits 0 with zero mutants; twin-05 attests a commit that is not `main`; See It Run native job 13/13 cancelled). The second theme is **selection between milestones**: five inward milestones (v23-v27) moved no adopter-facing matrix cell, and "what is next" lives in four drifting places. The third: **the newcomer path is unmeasured and its documented install step cannot run outside the repo**.

v28.0 is therefore a repair-then-ratchet milestone with exactly one outward bet (Android proof from a foreign host) and ends with a real release. It must be followed by an outward milestone (rule in BEARINGS).

## 2. Conflict resolutions (one decision each)

| Conflict | Decision | Why |
|---|---|---|
| Android ASAP vs "after iOS clean-room harness" (JTBD) vs "after parity inventory" (TWINS) | **In v28.0**: ADR+AGENTS amendment (first phase), generated parity ledger, Kotlin test floor, then ONE proof slice: generated shell into a fresh foreign Gradle project resolving the published Maven coordinate, JVM-only, Linux. Toolchain bump, emulator lane and seam parity go to v29. | The foreign-host slice is cheap, needs no emulator, reuses the same fail-closed single-command shape as the SEED-004 harness (built in v28), and surfaces blind spots now. A toolchain bump before the ledger exists is unmeasured risk. |
| Mix-task renames (JTBD R9) vs L2 package split (ARCH R8) vs "no breaking changes" | **No renames or splits in v28.** v31 hides/aliases maintainer tasks with one-release alias; L2 split stays LATER. | Renames are user-visible breaking changes; the split touches the core-first publish DAG. Neither is needed to ship v28's outcomes. |
| How much planning ceremony to cut (PROCESS E1-E12) | **Cut now (pure deletion/short):** STATE handoff history, STATE cap 40, MILESTONE-ARC retired (lessons migrated), byte-snapshot ritual, ROLLING+BEARINGS+PERSONAS. **Defer:** light-phase mode (tooling unverified), PROJECT.md split, trimming the 393-line parked adopter STATE. | Deletions are free and reversible via git; the others carry tooling or lost-blocker-text risk. |
| `scripts/bearings-report` (PROCESS) vs `repo-hygiene-report.yml` (CI) | **One script now (`script/bearings-report`), workflow later.** The weekly workflow in v29 just runs the script and edits one issue. | Avoid two mechanisms. Measure findings before scheduling or gating. |
| `stream_data` dep vs copy-paste (TEST vs user value) | **Exhaustive enumeration + a ~30-line seeded loop helper for v28.** Adopt `stream_data` (`only: :test`, root only, zero runtime deps) in v29/v30 only if a seeded loop proves inadequate for shrinking; logged in the dep ratchet with a one-line justification. Native sides: seeded loops, never SwiftCheck/Kotest. | Honors "copy-paste beats a dep" while naming the single honest exception candidate (shrinking is not copy-pastable). Finite policy domain needs no PBT. User question Q4. |
| Mutation tool (Muex vs in-repo harness vs Credo-like deps) | **Muex pilot as a throwaway/archive run, not a committed dep**, `--no-optimize`, wrapper fails on zero mutants, 4 modules. In-repo AST harness only if the pilot fails. | Muex is the only live Elixir tool; its defaults silently produced zero mutants (absence-as-success). Pilot decides before any dep or CI lane. |
| When the stale twin re-runs (TWINS R1 "now") | **v30 phase 1, after identity-debt fix, not v28.** In v28 only state honestly in `see_it_run.md` that twin-05 attests `a53fbef`, not `main`. | v28 changes twin-dependent files (denial cycle, goldens, Android shell paths); a run now would be stale again on merge. Needs a fresh user decision (twin-06 rule). |
| Release PR #236: repair vs close | **Fix cause, let release-please refresh, release at v28 end.** Never close it, never hand-edit the bot branch, no `--admin`. | It is the standing change ledger; red is caused by version-embedded goldens (S fix). |
| Quality milestone vs standing slice (PROCESS) | v28.0 is allowed to be repair-heavy because the bearings report is red on an invariant (red release PR). From v29 on: quality slice <=20% of appetite, no quality-only milestones. | PROCESS's own exception clause. |
| Doctor/tool code in Hex tarball | Measure only (hex tarball allowlist test is LATER). | Fixing it is the L2 split. |
| Twin "now" (TWINS) vs "net-new proof only after measurement" | Profiles are rows over one host; no new host apps; catalog skeleton is LATER, not v28. | One-milestone achievability. |

## 3. Roadmap order and why

1. Land before leap: bearings reset and ADR amendments first, so every later rule text agrees with the roadmap.
2. Make main and the release train green (cheap S fixes, high signal), because a red base hides regressions.
3. Spec/structure ratchet on the most sensitive modules (offline, policy, bridge), because Android and later parity work consume those specs.
4. Public docs truth, so the release carries accurate claims.
5. Android proof slice (outward).
6. Release behind separate `allow` per publish.

## 4. DRAFT `.planning/ROADMAP-ROLLING.md` (<=120 lines)

```markdown
---
updated: 2026-10-24            # edited by the new-milestone loop only
active_milestone: v28.0
priority_order_ref: AGENTS.md#Current-Priority
---
# Rolling Roadmap
Crosswake is infrastructure for the First B2C Adopter; synthetic adopter profiles are the proving
ground while that lane is parked. Arc: land truth, then prove Android and the host seams, then the newcomer path.
Horizon = confidence, not dates. Fields: effort S/M/L; adr none|amends|reopens; promotion = entry trigger.

## NOW  (exactly 1)
### v28.0 Truth and Release Train   appetite: 6 phases (194-199), ~20 plans   serves: #2,#3 + repair
- Outcome: main/PR queue clean, release PR green without hand edits and released (one `allow` per
  publish), public docs true, sensitive-module specs hardened, Android unfrozen with one foreign-host proof.
- Exit evidence: `script/bearings-report` green; release published and mirror tag == version;
  `docs.verify` clean in report mode; Android foreign-host JVM leg green on CI head.
- effort L | adr: amends (Android unfreeze; synthetic-profile reversal gate; GET-6 profile rows)
- Quality slice: phases 196 and 195 (>20% by exception: bearings red on release PR).
- Out: twin re-run, emulator, PBT dep, renames, L2 split, README rewrite. Stop: a publish fails twice -> hold, diagnose.

## NEXT  (2-3; no phases; each carries persona/job + readiness criterion moved)
| ID | Outcome | Horizon | Effort | adr | Promotion trigger (all true) |
|---|---|---|---|---|---|
| v29.0 Android Proof | Toolchain bump with templates in one PR; ktlint advisory; emulator advisory lane (Linux KVM, flake<2% over 20 runs before required); P1 offline-study journey on emulator; manifest 1.2.0 host-command seam read (additive, versioned); weekly hygiene workflow | next | L | amends (shared-contract Android disposition in Upgrade Impact) | v28 closed; AND-01/03 green; user says yes. Outward (moves matrix cells P7/C9). |
| v30.0 Twin and Host Trust | Twin identity debt closed (bundle id, app-bound domains, route id); receipt binds head+tree; twin-06 on `main`; SEED-015 guide + one doctor advisory; SEED-016 host-run webview conformance; first Hostile Host rows; iOS brownfield (P5) leg of clean-room; close SEED-011 | next | L | none (profiles as rows over one host) | v29 closed; user approves twin-06 run (macOS time). Outward (device-class blind spots). |
| v31.0 Newcomer Path | README top third rewritten for evaluators; one-page first-route guide; doctor-to-troubleshooting bijection; DSL tiering doc; maintainer mix tasks hidden with alias; Hotwire/PWA decision page; App Review guidance; clean-room as CI lane after 2 clean runs | next | M-L | none | v30 clean-room green twice; C1/C4 measured in scorecard. Outward (P1 C-grade rises). |

## LATER  (one line each; max 8; each has a mechanical or one-glance trigger)
| Theme | Effort | adr | Promotion trigger |
|---|---|---|---|
| Property tests (P1 cross-shell differential corpus, P2-P4, P8) + `stream_data` test-only decision | M | none | Muex pilot survivors show boundary gaps, or seeded loop proves inadequate |
| Weekly advisory Muex run, then PR-scoped `--since`; PIT (Kotlin) and Muter (Swift) pilots | M | none | Muex pilot adopted and 4-week stable baseline |
| L2 split: move proof_lane/release_candidate/planning/support_matrix (~19k LOC) out of the Hex tarball; hex tarball allowlist; dialyzer for L0 after | L | none | v31 done; F2 layer-direction test exists; core-first DAG rehearsal planned |
| Doctor/ActivationCoordinator split; `phase_N` renames and provenance-comment strip (per file, opportunistic) | M | none | touching the file for another reason |
| Scenario catalog + generated capability matrix (platform axis ios/android/both); rename-by-capability aliases | M | none | second profile row set needed (v30 Hostile Host rows exist) |
| Doc system: generated companion matrix, doctests on pure modules, claims-cite-proof, audience split of guides | M-L | none | `docs.verify` stable one cycle |
| Commerce extraction to a companion (not productionization) | M | amends | a profile shows core-names-companion defect, or L2 split starts |
| Notification re-entry corridor | M | reopens | synthetic P2 journey fails a readiness criterion that push would clear (evidence artifact cited) |

## PARKED  (external gate; max 3)
| Lane | Gate | Resume | Checked |
|---|---|---|---|
| First B2C Adopter readiness (v21) | adopter public-v1 mobile path active; real sanitized route rows | `--ws first-b2c-adopter-readiness`, STATE resume posture | each loop run |
| Android physical-device proof | an adopter commits Android scope | new milestone after v29 emulator ceiling | each loop run |
| Physical-iPhone exit test | external gate above plus device availability | existing driver, new run | each loop run |

## DROPPED  (last 10; one-line reason; git remembers)
- Capture/scanner packs, generic/background sync, generic native storage, dashboard: no persona evidence; reopen only via amendment with measured gap.
- In-repo AST mutation harness: wait for Muex pilot failure. Credo/dialyzer as merge gates: noise on 49k LOC.
- SwiftCheck/Kotest deps: seeded 25-line loop first. Merge queue: ~15 PRs/month.
- Per-persona host apps and twins: ADR forbids; rows over one host only.
- Optimizing macOS CI minutes: repo is public, minutes free. 4-researcher fan-out when a NEXT entry is H-confidence.
- LiveView-driven native rendering, on-device BEAM, "write once": thesis.
- Bulk rewrite of 217 source-grep tests; native menu/action breadth; Android feature breadth beyond contract parity.

## Loop rules (see BEARINGS)
Promote only in new-milestone loop; item that ships partially is re-pitched or dropped (no auto-carry);
row unchanged for 3 milestones is demoted; seeds minted only for ideas, review residue becomes debt rows.
```

## 5. DRAFT `.planning/BEARINGS.md` (<=60 lines)

```markdown
# Bearings (read first; <=60 lines; edited only at milestone close; prune >= as many as added)
## Posture invariants (statement | how checked)
1. Land before leap: main green; nothing valuable only in /tmp, a stash or an unpushed branch. | script/bearings-report
2. Fail-closed explicit denials; offline claims honest (cached read-only is not mutation; one island is not sync). | docs-contract + vector tests
3. Privacy: opaque scope refs, scope-partitioned outboxes, no raw payloads/tokens/device ids in telemetry, doctor, logs, proof. | privacy scan before every push
4. Merge to main, release-PR merge, Hex/Maven/iOS publish, tag, remote branch delete: one-use `allow`, never standing, never transferred. No --admin, no force-push to bot branches. | AGENTS.md gate
5. Android is unfrozen for proof and parity of EXISTING contracts only. It never gates the first adopter's iPhone proof. Re-freeze if it delays an iOS gate by >1 milestone. | ADR amendment
6. Every milestone serves an AGENTS.md priority or names the repair it blocks. After 2 inward milestones the next is outward (moves a matrix cell) unless the scope doc records a user override.
7. Never name, infer, search for or link the real first adopter. Synthetic profiles stay generic.
8. Publish DAG is core-first, then companions; irreversible Maven/Hex publishes only after a clean-room run against published coordinates.

## Tripwires: check at plan time (each bit us at least twice)
- A check with no negative control passes by asserting nothing (v23, v25, v26, v27, Muex zero-mutant exit 0, vacuous collection asserts). Require non-empty floor + a mutation that turns it red.
- A check can pin the FALSE value (phase132 pins stale versions; Phase153 pins a literal SHA). Assert shape or derive from source, not a copied literal.
- Piped gate commands report the tail's status. One command per gate; never `| tail && echo OK`.
- Status written before the event, or stamped by automation, goes stale on arrival (v27 STATE, android_uat "Last verified", twin-05 receipt vs main). Derive from git/CI/artifact path.
- A deferral without a receiver that can act is a drop (v26; SEED triggers never evaluated). Debt rows carry owner, trigger, receiver.
- A recurring gate living only in a phase folder is not a gate (v27 scripts, one-time lanes). Promote only recurring contracts; measure findings on main before merge-blocking (PR #173, SEED-018).
- Simulator-green is not device-green (every SEED-013 defect). Twin results never promote a claim.
- Line-number citations and line-keyed allowlists rot; key by file + normalized text.
- Path-dependency rehearsals never catch published-core resolution (core-first lesson, clean-room never green).
- Hand-maintained version/date tables drift (companion matrix, CHANGELOG at 0.2.1, SETUP phase text); generate them.

## Do not re-open (reopen only by ADR amendment citing a measured artifact; max one stop-list item per milestone)
- Generic/background sync, generic native storage, capture packs, commerce productionization, native menu breadth, dashboard.
- Candidate-in-/tmp "freeze" regimes; merge queue below ~3 PRs/day; per-persona host apps/twins; new label taxonomy.
- Rotating MIRROR_PUSH_TOKEN as a SEED-003 fix; deleting archived milestone records.
- Making the twin a per-PR lane; consuming a used twin run root; retrying a failed twin to green.

## Open traps (delete when fixed; max 5)
- Release PR #236 red: goldens embed `Generated by crosswake X.Y.Z` (REL-01).
- Dependabot #210/#211 red: tests pin literal action SHAs (REL-02).
- SEED-025 WR-01: possible secret echo in public CI logs (REL-03).
- twin-05 attests `a53fbef`, not `main`; no CI lane (v30).
- Muex defaults generate zero mutants and exit 0 (SPEC-04 wrapper).
```

## 6. Proposed milestone v28.0

**Name:** v28.0 Truth and Release Train
**Goal:** Land the bearings and ADR amendments, make main and the release pipeline trustworthy, harden the sensitive specs, correct the public docs, prove Android from a foreign host, and cut one real release behind per-publish `allow`.
**Appetite:** 6 phases, about 20 plans, each phase has a mechanical exit check. Light-phase mode is not assumed.

| Phase | Name | Delivers | Pitfalls it must avoid | Research |
|---|---|---|---|---|
| 194 | Bearings reset and ADR amendments | ROLLING, BEARINGS, PERSONAS, STATE trim, ARC retired, bearings-report, ADR + AGENTS + support-truth edits together | Status written ahead of event; rubber-stamped reversal | Skip (S, decided) |
| 195 | Pipeline repair and hygiene | Goldens version-independent, pin-shape asserts, credential masking, schedule/controller retirement, Dependabot config and PR triage, root scratch removal, branch cleanup, SEED-003 closure, clean-room single command | Hand-editing bot branches; new check merge-blocking before measuring | Skip; one feasibility look at clean-room scope |
| 196 | Spec and structure ratchet | Silent-test fixes, vector count pins (3 languages), VACG-01 delta guard, boundary specs for offline modules, Muex pilot, policy matrix, compile-cycle break, bare-rescue removal, dep ratchet | SEED-018 200-finding wall; Muex zero-mutant green | Needs `--research-phase` for Muex pilot runtime/noise only |
| 197 | Public docs truth | Install path runnable from a normal host, companion matrix/CHANGELOG/telemetry fixes, Android "frozen" text removed, docs.verify in report mode | Fixing generated guides by hand; Android claims beyond JVM evidence | Skip |
| 198 | Android foreign-host proof | Parity ledger from contract vectors, Kotlin test floor, webkit dep check, foreign-Gradle-project leg resolving published Maven coordinate | Hand-porting Swift; inheriting iOS labels; device claims | Needs `--research-phase` (verify webkit, org.json, templates vs build files) |
| 199 | Release 0.2.12 | Release PR green on head, separate `allow` per merge/Hex/Maven/iOS/tag, post-publish mirror-tag assertion, bearings green, milestone closeout | Standing approval; retrying uncertain delivery; core-after-companion | Skip |

### Candidate requirements (30)

Each carries `Persona/Job` (P1 study founder, P5 skeptic, P6 privacy, P7 cross-platform, M = Maintainer-infra).

**PLAN (phase 194)**
- PLAN-01 [M] `.planning/ROADMAP-ROLLING.md` exists with NOW/NEXT/LATER/PARKED/DROPPED, every row carrying outcome, horizon, effort, `adr:` field and promotion trigger; `wc -l` <= 120 asserted by bearings-report.
- PLAN-02 [M] `.planning/BEARINGS.md` <= 60 lines, listed as Project Context item 0 in AGENTS.md; top lessons from the Cross-Milestone table migrated, MILESTONE-ARC.md marked historical.
- PLAN-03 [M] quality-ratchet STATE.md <= 40 lines with one handoff; "Handoff history" removed and the byte-snapshot ritual deleted from the milestone-start convention.
- PLAN-04 [M] `script/bearings-report` prints <= 40 plain-language lines (main CI at HEAD stating which commit CI ran on, ahead/behind, open PR classes, worktrees, stashes/unlanded branches, line caps, fired seed/debt triggers); exits non-zero and says UNVERIFIED if any read fails; has a negative-control test per check; is not merge-blocking.
- PLAN-05 [M] `.planning/PERSONAS.md` (<= 1 page, P1-P7, J1-J5) exists; every requirement in a milestone REQUIREMENTS file carries a `Persona/Job` tag or `Maintainer-infra`; the superseded root JTBD ordering is recorded "not executed".

**ADR (phase 194)**
- ADR-01 [P7] An ADR amendment unfreezes Android for proof and parity of existing contracts, with the re-freeze trigger; AGENTS.md, ADR, PROJECT, REQUIREMENTS, support matrix and capability map "frozen" text change in the same PR.
- ADR-02 [M] An ADR amendment records the synthetic-profile reversal gate (profile, failing criterion, artifact cited, smallest slice, rollback; at most one reopened item per milestone) and permits profile scenario rows over one host as proof structure.

**REL (phases 195, 199)**
- REL-01 [M] The Info.plist golden and Swift seam fixture comparison ignore the `Generated by crosswake X.Y.Z` version line; a release-please PR for the next version passes the eight test jobs with zero hand edits (verified on the PR head commit).
- REL-02 [M] The parity-workflow test asserts a 40-hex SHA plus version comment instead of a literal SHA; `@dependabot rebase` on #210 and #211 turns them green or they are closed.
- REL-03 [P6] CI emits `::add-mask::` before any secret-derived value is echoed, with a test that a seeded fake secret never appears in captured step output.
- REL-04 [M] The 14 weekly `phaseNN-proof` schedules, the Cancel Obsolete controller and `script/select_obsolete_ci_runs.py` are removed; one weekly canary on `main` is added; the See It Run `native` job is split out so `web-and-gif` completes.
- REL-05 [M] Dependabot is one grouped monthly actions PR plus a security entry; #239/#240/#241 merged, #238 merged or closed as superseded; no open PR older than 14 days without a recorded reason.
- REL-06 [M] SEED-003 is closed with the mirror-tag evidence; one clean-room command fails closed and is run once against the real 0.2.11 artifacts with output retained.
- REL-07 [M] The release (core first, then companions, Maven, iOS mirror) completes with a separate `allow` per merge/publish/tag; a post-publish check asserts the mirror tag equals the release version.

**HYG (phase 195)**
- HYG-01 [P5] The 13 tracked root scratch files and `crosswake-checkpoint-24c8389.bundle` are removed (denylist string in `first_adopter_context.ex` kept), `SETUP.md` moves under `docs/` with the personal email removed, and a root-allowlist test fails on any new tracked root file or `*.bundle`.
- HYG-02 [M] Merged or superseded remote branches are deleted (5 immediately, 10 after one look, unmerged work tagged `archive/<name>` first); `git worktree list` shows only the main checkout.

**SPEC (phase 196)**
- SPEC-01 [P6] `evidence_manifest_test.exs:98` and `phase139_threadline_cleanroom_test.exs:59` no longer pass by asserting nothing (tag-and-exclude or prerequisite assert); Elixir, Swift and Kotlin vector-consuming tests assert vector count equals a pinned expectation and fail loudly on a missing vector.
- SPEC-02 [M] A delta-only guard (VACG-01) in `script/check_absence_is_not_success.exs` fails on new non-empty-less collection assertions, `for`-over-glob without cardinality, and literal `assert true`, each with a negative control; the ~3 known sites are fixed in the same change.
- SPEC-03 [P6] Boundary specs exist for `Journal.scope_ref!/1` (15/16/128/129 chars, newline injection, non-echo of input) and `SafeObservation.new/1` (measurement 0, 1_000_000, 1_000_001; adversarial strings in every field never survive).
- SPEC-04 [M] A Muex pilot covers `SafeObservation`, `Journal`, `Policy.Compiler`/`Route` and `Bridge.Contract` using `--no-optimize` and `--format json`; the wrapper fails if mutants generated is 0; baseline scores, runtime and survivor classification (kill/equivalent/noise, keyed by file+mutator+normalized text) are recorded and an adopt/drop decision is written. No Muex dep is committed.
- SPEC-05 [P5] The finite route-policy option product is enumerated exhaustively against a hand-written verdict table; compiler error assertions pin `{key, route_id}` pairs; `Compiler.validation_key/1` never returns `nil` for a compiler error.

**ARCH (phase 196)**
- ARCH-01 [M] The `bridge/contract` / `bridge/denial` / `manifest/types` / `shell/denial` compile cycle is broken; a test fails on any compile-label xref cycle and on an all-cycles count above the committed baseline.
- ARCH-02 [P5] The three bare `rescue _ ->` clauses in `bridge.ex` return explicit results, and an AST test fails on bare rescue in `bridge`, `policy`, `router`, `offline`, `manifest`, `compatibility`.
- ARCH-03 [M] A test compares runtime direct deps per package to a committed list; adding a dep requires editing the list with a one-line justification.

**DOCS (phase 197)**
- DOCS-01 [P1] README "Integrating" and `install.md` contain no command that exists only in the repo (the `verify_phase5_example_hosts.sh` step is replaced), state which steps need a clone, and include the bridge hook, esbuild flags, `attach/1` and `:ios_host` wiring; the clean-room command from REL-06 executes the documented steps.
- DOCS-02 [P1] Companion matrix shows rulestead 0.1.1, rindle 0.1.0 (published), chimeway 0.1.2; `phase132` no longer hardcodes the stale values; CHANGELOG states no false "current release 0.2.1" and points to GitHub Releases for 0.2.2-0.2.11; telemetry guide lists `[:crosswake,:offline,:replay]` and drops "doctor"; `see_it_run.md` states which commit the twin receipt attests.
- DOCS-03 [P5] `mix docs --warnings-as-errors`, a relative link/anchor check, and a public-leak scan (`Phase N`, `TODO-`, `D-NN`, `v2x`) run in report mode for one cycle with counts recorded; `android_uat.md` loses the release-please "Last verified" stamp and the phantom capability families; "Android frozen" text is removed from README, support matrix and native shell guide.

**AND (phase 198)**
- AND-01 [P7] A parity ledger is generated from `priv/contract_vectors/*.json` with an Android column, and a test asserts Swift and Kotlin reference the same vector-set hash.
- AND-02 [P7] Kotlin core JVM tests rise from 12 to >= 25, including `BridgeChannel` boundary cases; `androidx.webkit` is removed if unimported; the Android one-JSON-stack question (org.json vs kotlinx.serialization) is decided in writing.
- AND-03 [P7] A fresh foreign Gradle project built from `mix crosswake.gen.shell android` output resolves the published Maven coordinate and passes JVM tests on Linux CI (advisory leg, then required only after two clean runs), with a negative control that a wrong coordinate fails.

### Out of Scope (v28.0)

| Item | Why | Lands in |
|---|---|---|
| Twin-06 run on `main`, twin identity debt, receipt head binding | Would go stale after v28 file churn; needs fresh user decision | v30.0 |
| Android toolchain bump, emulator lane, ktlint, host-command seam parity, Android twin | Needs ledger first; unmeasured risk | v29.0 |
| `stream_data`/property tests, Muex weekly lane, PIT, Muter | Pilot decides first | LATER |
| Mix task renames/hiding, L2 package split, doctor split, `phase_N` renames | Breaking or large | v31.0 / LATER |
| README rewrite, one-page first-route guide, doctor bijection | v28 only removes lies | v31.0 |
| Scenario catalog, P5 iOS brownfield fixture, P6 hostile rows, SSO fixture, SEED-015/016 | Outward proof work | v30.0 |
| Light-phase mode, PROJECT.md split, trimming the 393-line parked adopter STATE | Tooling unverified / blocker-text risk | LATER |
| Merge queue, dialyzer, Credo, SwiftLint merge gates | No measured need | DROPPED/LATER |
| Any stop-list reopening (notification, commerce, sync) | No measured profile evidence yet | gated by ADR-02 |

### Research flags

Needs `--research-phase`: 196 (Muex runtime and noise on real modules), 198 (Android build files and webkit/org.json usage were grep-level only). Standard patterns, skip: 194, 195, 197, 199.

## 7. Questions only the user can make (<=6)

1. **ADR amendment package.** Approve one PR that (a) unfreezes Android for proof/parity of existing contracts with the re-freeze trigger (delays an iOS gate by more than one milestone), (b) records the synthetic-profile reversal gate (measured artifact required, max one reopened item per milestone), (c) permits scenario rows over one host as proof structure under GET-6 while the adopter is parked, and edits AGENTS.md accordingly? **Recommend: yes.**
2. **Inward-streak override.** v28.0 would be the sixth repair-flavoured milestone. Accept it as an explicit override (one outward bet: Android foreign-host proof) with v29 and v30 mandatorily outward, counting hermetically proven matrix cells as outward? **Recommend: yes.**
3. **Release cadence and Rindle.** Release at each milestone boundary, trigger-based (main green + non-empty release PR + bearings green), plus defect patches, each publish a separate `allow`; first release at the end of v28.0. Rindle companion: keep published 0.1.0 in the proof set (fix exact-public-proof to accept partial sets). **Recommend: yes to both.**
4. **Dependency exception.** Allow `stream_data` as a test-only, root-only dep (recorded in the dep ratchet) if a seeded 30-line loop proves inadequate in v29/v30, and run Muex only as an archive/throwaway pilot? Otherwise strict copy-paste everywhere. **Recommend: allow the conditional exception; no Muex dep until the pilot passes.**
5. **Destructive hygiene batch.** Approve deleting the 13 root scratch files and the 434 KB checkpoint bundle (the denylist string stays; confirm the bundle is not the only copy of anything), moving `SETUP.md` under `docs/` without the personal email, deleting 5 clearly merged remote branches now and archiving-then-deleting 10 after one look (each remote delete behind its own `allow`)? **Recommend: yes, as one PR plus separate branch-delete allows.**
6. **Planning-ceremony cuts.** Approve deleting STATE "Handoff history" (69 entries) and the byte-snapshot ritual, retiring MILESTONE-ARC.md after migrating its durable lessons into BEARINGS, and shrinking AGENTS.md to <= 90 lines (approval-gate paragraph kept verbatim)? **Recommend: yes.** (Twin-06 run approval and its macOS cost are asked at v30 entry, not now.)

## 8. Do NOT list (merged, deduped)

- No dashboard, roadmap tool or Linear mirror of the roadmap; no dates in horizons; no calendar cool-down or periodic quality-only milestone; BEARINGS never exceeds 60 lines.
- No hand-written "awaiting merge/next" status; derive from git/CI; no parallel "what is next" surfaces.
- No new check merge-blocking before its findings and flake rate on `main` are measured; no wall of 100+ findings; delta-only guards.
- No piped gate commands; no recurring check that lives only in a phase folder; no line-number-keyed allowlists; no vacuous collections (assert non-empty).
- No Credo, dialyzer, SwiftLint merge gates now; no boundary library; no in-repo AST mutation harness before the Muex pilot fails; never trust Muex default optimizer output as evidence.
- No mutation testing of `doctor`, `release_status`, `support_matrix`, `proof_lane` (~10k LOC report assembly), nor of YAML/shell meta-tests (use hand-written mutation controls); no bulk rewrite of the 217 source-grep tests; no SwiftCheck/Kotest/new PBT deps before a seeded loop fails; no PBT in place of exhaustive finite enumeration.
- No new dependency to replace a dependency; do not copy `jason` or `nimble_options`; no merge queue; do not optimize macOS minutes (public repo); no Android emulator on macOS runners.
- No `--admin` merges, force-pushes or hand edits to release-please branches; do not close the release PR; do not rotate MIRROR_PUSH_TOKEN for SEED-003; publish only after published-coordinate resolution is proven (core first); no standing or transferred `allow`; never retry an uncertain delivery.
- No new host apps, personas-as-apps or per-persona twins; no per-PR twin lane; never consume a used twin run root or retry a failed twin to green; no twin, simulator or synthetic result promotes a claim.
- No capture, scanner, native menu breadth, commerce productionization, generic/background sync, generic native storage, notification corridor, or provider SDKs unless an ADR amendment cites a measured profile artifact; at most one reopened item per milestone.
- No Android hand-port of Swift line by line; no Android feature breadth beyond contract parity; no Android device lane before hermetic vector parity; no generator template and Gradle file pinning different toolchains; no Android claim beyond JVM-hermetic evidence until new evidence exists.
- No new label taxonomy (extend with `claim_ceiling` only); no whole-guide snapshots; no hand-editing generated guides; no second doc generator; live-registry and external-link checks never merge-blocking.
- Do not delete phase-numbered tests or workflows without aliases; do not rewrite or delete archived milestone records; do not rename public modules for aesthetics; no big-bang rewrite of `doctor.ex` or `ActivationCoordinator.swift`.
- Never name, infer, search for or link the real first adopter; synthetic rows stay visibly generic; never invent adopter facts to fill TODO-002.

## 9. Confidence and gaps

| Area | Confidence | Notes |
|---|---|---|
| Diagnosis (repo/CI/docs facts) | HIGH | Measured by the reports; CI numbers from live `gh` reads |
| Sequencing and appetite | MEDIUM | Six phases in one milestone is tight; 196 is the likeliest to overrun (cut SPEC-04 or ARCH-03 first, push to v29) |
| Muex adoption, Android build facts, Muter/PIT | LOW-MEDIUM | Pilot and Android file-level reads still needed (research flags) |
| GSD tooling support for project-level ROLLING file | UNVERIFIED | Check `roadmap.analyze`/progress before wiring (PROCESS gap) |
| Whether `format --check` and xref are already in CI | UNVERIFIED | Confirm in `crosswake-ci.yml` before ARCH-01 |
| Stale-doc counts, 20-40 unguarded assert sites | MEDIUM | Sampled and extrapolated |
