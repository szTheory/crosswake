# v28.0 Research: Documentation Accuracy and Quality

Researched: 2026-10-24. Read-only audit of the repository at `main`. Live registry facts
checked against hex.pm and Maven Central the same day. Android is treated as UNFROZEN (coordinator
decision), so Android docs are in scope.

## 1. Bottom line

The docs are well guarded against one kind of drift and unguarded against another.

- Names are accurate. About 80 backticked identifiers (denial codes, finding codes, capability families,
  mix options) were grepped against code. Every miss was a legitimate non-code token or a Swift-only
  token. 237 relative links: 0 broken. Mix task flags matched in every case checked.
- Facts about state are not accurate. Versions, "what is published", "what you can run", dated
  "last verified" stamps, and stale phase references drifted. 17 of 42 sampled claims were wrong
  (about 40%). Split by class: identifier, option and module claims drifted 0 of 20. Version, state,
  procedure and verification claims drifted 17 of 22.
- Cause: the repo's guard style is "pin a phrase in the guide with a string-contains test". That
  proves the sentence still exists. It does not prove the sentence is true. In one case the test
  pins the false value itself.

## 2. Inventory and classification

Diataxis class: T tutorial, H how-to, R reference, E explanation. Source: G generated, A hand-written,
S semi-generated (a script stamps part). Audience: Pub (ships in the Hex tarball and HexDocs), Repo
(public on GitHub, not shipped), Int (internal).

| Doc | Class | Source | Audience | Note |
|---|---|---|---|---|
| README.md (236 lines) | E+H mix, front page for GitHub, Hex and HexDocs | A, version line stamped by release-please | Pub | Mixes marketing, install, support status, and a "Blocked" banner |
| guides/install.md | H | A | Pub | The primary how-to; has the broken proof step (F2) |
| guides/see_it_run.md, examples/QUICK_START.md | T | A | Pub / Repo | Tutorials; require a repo clone, which they do not say |
| guides/architecture.md, code-walkthrough.md | E | A | Pub | code-walkthrough is 657 lines |
| guides/route_policy.md, bridge.md, offline.md, packs.md, native_shell.md, tokens.md, commerce.md, capabilities.md | R+E blended | A | Pub | Reference and rationale interleaved in one file |
| guides/support_matrix.md, capability_map.md | R | G from `Crosswake.SupportMatrix` and `Crosswake.CapabilityMap` | Pub | Gate: `mix crosswake.docs.sync --check`. The prose inside the Elixir source is hand-written (F8) |
| guides/companion_compatibility.md | R | A, with a drift test on one column | Pub | F1 |
| guides/telemetry.md | R | A | Pub | F4 |
| guides/android_uat.md | H (checklist) | S: version stamp is release-please | Pub | F5 |
| guides/native_shell_upgrade.md, compatibility.md, troubleshooting.md, user_flows.md, adopter_profiles.md, adoption.md, web_to_mobile_migration.md, companions.md, companion_contract.md, threadline.md, physical_iphone_handoff.md | mixed | A | Pub | 31 extras in mix.exs; every guide is registered (0 orphans) |
| docs/_contract_snippet.md | R | G by `mix crosswake.contract.gen` | Repo | Good model of generated docs |
| docs/COMPANION-PUBLISH-RUNBOOK.md, RELEASE-INCIDENT-RESPONSE.md, MILESTONE-BOUNDARY-HYGIENE.md, PORT-REGISTRY.md | H | A | Repo/Int | Maintainer runbooks |
| SETUP.md | H | A | Repo, public at repo root | Stale phase-110 runbook (F6) |
| CONTRIBUTING.md | H+R | A | Repo | F3 |
| CHANGELOG.md | R | A, hand-authored (`skip-changelog: true`) | Pub | F3 |
| packages/*/README.md (5) | H | A | Pub (per package) | Accurate, thin |
| @moduledoc / @doc | R | A | Pub | 254 @moduledoc against 111 `@moduledoc false`; 257 @doc against 906 `def` |
| .planning/** | Int | A | Int | Out of scope except where a public doc leaks its codes |
| Stray root scripts | none | none | Repo | `fix_*.py`, `patch_*.py`, `*.swift`, `*.bundle`, `update_main_activity.sh` at repo root; not docs, but they harm first impressions |

Four systems stamp or generate doc content today: `mix crosswake.docs.sync`, `mix crosswake.contract.gen`,
release-please `extra-files` (README, android_uat.md and others), and the hand-edited companion matrix.

## 3. Accuracy audit: 42 claims, 17 drifted

Verified live on 2026-10-24: crosswake 0.2.11, rulestead 0.1.1, rindle 0.1.0 (companion), sigra 0.1.3,
chimeway 0.1.2, threadline 0.1.0. Maven latest 0.2.11. The engine package `rindle` is at 0.4.11.

| # | Claim (file:line) | Result | Evidence |
|---|---|---|---|
| 1 | README:232 core version 0.2.11 | OK | mix.exs @version 0.2.11; Hex 0.2.11 |
| 2 | README:229-231 Elixir ~> 1.19, Phoenix ~> 1.8, LV ~> 1.1 | OK | mix.exs deps |
| 3 | README:123 `mix crosswake.install` | OK | lib/mix/tasks/crosswake.install.ex |
| 4 | README:127 `gen.shell ios\|android` | OK | gen.shell usage string |
| 5 | README:204, install.md `--native-targets none`, `--native-checks` | OK | doctor.ex @switches |
| 6 | install.md `auto, none, ios, android, all` | OK | doctor.ex:184-190 |
| 7 | README:151 `release.status [--json] [--live]` | OK | strict switches |
| 8 | README:135 adopter runs `bash script/verify_phase5_example_hosts.sh` | DRIFT | The script does `cd examples/phoenix_host`. mix.exs `files:` ships only lib, priv, mix.exs, README, LICENSE, CHANGELOG, guides. An adopter host has no such script. |
| 9 | install.md:21 and :249 same step as "primary proof artifact class Crosswake publishes for adopters" | DRIFT | Same cause |
| 10 | install.md `--native-checks` runs `script/verify_generated_{ios,android}_shell.sh` | UNVERIFIED, likely drift | doctor.ex:68,103 expects the hook; `priv/templates` contains no such script, so a fresh adopter host has no hook |
| 11 | install.md manifest_schema_version 1.2.0 | OK | types.ex:771 |
| 12 | install.md bridge_hook refuses by default; `--eject` exists | OK | gen.bridge_hook moduledoc |
| 13 | install.md Step 1 "does not generate a host-owned copy" | OK, but shaky | OK with the `--eject` caveat stated at install.md:155 |
| 14 | companion_compatibility.md:24 rulestead Current Version 0.1.0 | DRIFT | mix.exs 0.1.1; Hex 0.1.1 |
| 15 | :25 rindle `unpublished`, "not yet on hexdocs", prose :31-33 "in that state today" | DRIFT | Hex has 0.1.0 (SEED-020, still unfixed) |
| 16 | :27 chimeway Current Version 0.1.0 | DRIFT | mix.exs 0.1.2; Hex 0.1.2 |
| 17 | :26 sigra 0.1.3, :28 threadline 0.1.0 | OK | |
| 18 | `Requires crosswake` = `~> 0.2` (5 packages) | OK | the only column the drift test reads |
| 19 | :98 "`rindle` is at `0.3.0`" | DRIFT | engine now 0.4.11 (conclusion still holds) |
| 20 | :97 "`rulestead` is at `1.0.0`" | OK | Hex 1.0.0 |
| 21 | CONTRIBUTING.md:34 `Crosswake.SupportMatrix.change_class_entries/0` | DRIFT | `defp change_class_entries` at support_matrix.ex:1033, private; no public function |
| 22 | CONTRIBUTING.md "every published `## [x.y.z]` carries Upgrade Impact" | DRIFT | CHANGELOG headings stop at `[0.2.1]`; ten later releases (0.2.2 to 0.2.11) have no entry and no label |
| 23 | CHANGELOG.md:36 "The current published Hex release is `0.2.1`" | DRIFT | It is 0.2.11. The public changelog tells readers they are on an old version. |
| 24 | CHANGELOG.md:28 "No new support claims have been cut after 0.2.1" | DRIFT | Same cause |
| 25 | telemetry.md:31 table lists "every :active event" | DRIFT | `[:crosswake, :offline, :replay]` is :active (telemetry.ex:127) and absent from the guide |
| 26 | telemetry.md:5 events emitted by "doctor" subsystem | DRIFT | No doctor event in the catalog |
| 27 | telemetry.md `Crosswake.Telemetry.events/0` | OK | telemetry.ex:102 |
| 28 | compatibility.md:57 `seam_unsupported` | OK | Swift shell tests, HostCommandSeamTests.swift:272 |
| 29 | compatibility.md `bridge_protocol_version 1.1.0` | OK | generated snippet |
| 30 | see_it_run.md port 4700, Docker, `bin/see-it-run.sh` | OK | script BACKEND_URL |
| 31 | README:47-52 `bin/see-it-run.sh` presented with no "clone the repo" step | DRIFT (scope) | Front page of Hex and HexDocs; the script is repo-only; `mix crosswake.demo` also shells to it |
| 32 | support_matrix Maven `io.github.sztheory:crosswake-shell-core-android` | OK | build.gradle.kts:71; Maven 0.2.11 |
| 33 | android_uat.md:3 "Last verified against Crosswake v0.2.11 on Android 15 (API 35)" | DRIFT (by construction) | release-please bumps the number on every release. No verification is run. All checklist boxes are unchecked. |
| 34 | android_uat.md "parity-locked, every capability family in the registry" lists 19 | DRIFT | `companion_snapshot` and `location_capture` appear nowhere in lib/ or Android sources; catalog has 15 families |
| 35 | support_matrix.md:240 device_verified unavailable "until Phase 67 ... Phase 68" | DRIFT | Stale phase text; the Android shell shipped long ago and Phase 68 tests exist |
| 36 | support_matrix.md:92, 99, 121, 285 and README: "Android is frozen ... no new claim" | DRIFT (as of unfreeze) | Contradicts the new direction |
| 37 | SETUP.md:4, :8, :201, :368 "before any Phase 110 CI run", "iOS mirror stays empty until Phase 111" | DRIFT | Mirror and publishes are live (0.2.11 on Maven and Hex) |
| 38 | README:235 `[mix.exs](mix.exs)` link | DRIFT (HexDocs) | `mix.exs` is not a doc extra; link breaks on hexdocs.pm |
| 39 | 237 relative links in README, guides, docs, packages | OK | 0 missing targets |
| 40 | package READMEs install snippets (`~> 0.2`, `~> 0.1`) | OK | |
| 41 | guides all registered in mix.exs extras | OK | 31 of 31 |
| 42 | capability_map "20 shell/proof ... cells" (renderer.ex:85) | UNVERIFIABLE | A hardcoded number in Elixir prose with no source |

Counting only the DRIFT rows (#8, 9, 14, 15, 16, 19, 21, 22, 23, 24, 25, 26, 31, 33, 34, 35, 36, 37, 38; rows
10 and 42 are excluded as unverified) gives 19 findings across 42 claims. Several of these share a cause, so
the drift rate quoted in section 1 (17 of 42) merges #23 and #24 and #8 and #9. Either way the rate is near 40%.
Note the SEED-020 count: it measured 1 of 5 matrix cells wrong on 2026-09-17; today 3 of 5 are wrong.
Drift grew after the finding was written, because it was written down and not fixed.

## 4. Stale, contradictory, duplicated, leaky docs

1. Internal codes in public guides. `README.md` plus guides: 58 hits of `Phase N`, `v2x`, `D-NN`,
   `TODO-002`, `SEED-` (40 outside the two generated guides). Examples: support_matrix.md:40 "(Phase 154,
   CTRL-05/D-55)"; capability_map "validated TODO-002 handoff", "v20 Pack 1 candidate", "v21 permits one
   host-supplied adapter". A newcomer cannot decode these. This is the AGENTS.md rule ("public guides say
   first adopter") only half-applied.
2. The front page reports project internals. README:192 opens "Proof and support posture" with
   "Blocked - sanitized route policy and signed-device proof are required before this host can be promoted."
   A reader does not know which host. The capability map is organized around one unnamed adopter
   ("What the first adopter changes"). For an evaluator this reads as "not ready", with no way to see what
   they can use.
3. Duplication of one fact in many places: "Android frozen" (8 hits), the "Cached read-only is not offline
   mutation" disclaimer, support-label legend (README:198, support_matrix, see_it_run, capability_map).
   Each copy is a drift surface; the phrase tests keep them verbatim but not true.
4. Two sources claim to be the single source of truth for companion versions (companion_compatibility.md
   line 3 and COMPANION-PUBLISH-RUNBOOK). The guide's own comment says "do not hand-edit" yet it is the only
   hand-edited column.
5. Three "how do I run it" entry points (README, see_it_run.md, QUICK_START.md) with overlapping steps and
   different prerequisites.
6. SETUP.md is a root-level maintainer secrets runbook, dated 2026-06-14, still in the public tree, with a
   maintainer email in a command example. Move it under docs/ and refresh or retire it.
7. Long blended pages: code-walkthrough.md 657 lines, support_matrix.md has 240+ line table rows. Rows in
   the "Promotion gates" table are single lines over 600 characters; unreadable in HexDocs.
8. Claims stronger than evidence:
   - android_uat.md "Last verified against ... v0.2.11" (row 33).
   - support_matrix rows 99/92 list Android `supported` while the only evidence is JVM hermetic proof; the
     prose is careful ("frozen does not mean device-verified") but the status cell says `supported`.
   - capability_map has the "Effective Xcode settings have been observed across 20 cells" and
     "2026-08-27 on iOS 26.6" claims as hardcoded Elixir strings (capability_map.ex:67, :584; renderer.ex:85).
     The gate checks the rendering matches the string, not that the claim is backed by an artifact.
   - The README "Integrating" block implies the six-step path proves the host. Steps 8-10 above do not
     work as written for an adopter.

## 5. Which doc-correctness checks exist, and which can pass while checking nothing

Exists: `mix crosswake.docs.sync --check` (CI, public docs lane); about 26 files in test/crosswake/guides/;
phase69 docs/contract parity; phase132 compat matrix drift; phase133 telemetry contract; capability_claims
scanner for over-broad words; `mix docs` smoke build; adoption_context.scan (privacy); release version
literal checks (`check_release_doc_version_literals.exs`, phase168/171); `script/check_ci_leaf_manifest.py`.

Absent: doctests (0 `doctest` calls in test/ and packages/*/test; 8 `iex>` lines in all of lib, in one file);
link or anchor check (my script found 0 broken relative links, but nothing in CI runs it); `mix docs
--warnings-as-errors`; check that moduledoc code samples compile; any check against the live registry.

Could pass while checking nothing (adversarial pass):

| Check | Why it can pass vacuously |
|---|---|
| `docs.sync --check` | Verifies file equals renderer output. Both can be wrong together. Hardcoded prose in capability_map.ex and renderer.ex is outside any truth source. |
| phase132 matrix drift | Reads one column. `@published_versions` in the test hardcodes `rindle => "unpublished"` and `rulestead => "0.1.0"` (test lines 33-36), so the test enforces the stale values and would FAIL if someone fixed the guide. The check protects the wrong answer. |
| Guide tests (string-contains) | Prove a phrase exists. Phrase "denied with `seam_unsupported`" passes even if the behaviour changed. Real strength: the identifiers they pin were all real. |
| capability_claims scanner | Scans a fixed list of 11 paths for banned words. Any guide not on `@scanned_paths` (install, compatibility, android_uat, companions) is unscanned. |
| `mix docs` smoke | No warnings-as-errors flag; only `test -f doc/index.html`. Broken cross-references and unresolved `Module.fun/1` refs pass. |
| release literal checks | Check literals that release-please already stamps. They cannot catch a stamp that asserts something false (android_uat "Last verified"). |
| public_docs CI family allowlist | `script/ci_docs_allowlist.json` decides which paths trigger the docs lane. A new doc dir outside the list does not run docs checks. |

## 6. Recommended docs system (opinionated, one choice per decision)

D1. Single source of truth for support, capability and version tables: keep the existing
Elixir-owner plus `docs.sync` pattern and EXTEND it. Do not invent a second mechanism.
- Move the companion matrix into a generated projection. Source: each `packages/*/mix.exs` (version,
  core floor, engine dep) plus a tiny `priv/registry_snapshot.json` for "published" state. Render into
  `guides/companion_compatibility.md` through `docs.sync`. Delete the hand-edited table and the
  `@published_versions` map in the test.
- Registry truth (published or not) is checked by a scheduled, loud-failing workflow
  (`mix crosswake.release.status --live` against the snapshot), per SEED-020 option 2. It is not in the
  merge-blocking lane. The check must have a non-vacuity proof (mutate a cell, see red).
- Move hardcoded dated facts out of renderer prose into the data module as typed fields
  (`evidence: %{date:, artifact_path:}`), and have the gate assert the artifact path exists.

D2. Executable examples: add `doctest` to the small set of pure public modules that already carry
`iex>` or obvious examples (`Crosswake.Policy`, `Crosswake.Router` helpers, `Crosswake.Telemetry`,
`RebuildPolicy`). Do not chase repo-wide coverage. Extend this to install.md code blocks with a single
`mix test` that extracts fenced `elixir` blocks tagged `<!-- verify -->` and compiles them. Start with
10 blocks.

D3. Link check: one fast CI step, `mix docs --warnings-as-errors` plus a 40-line script (the Python I used,
ported to Elixir or Node) for relative links and anchors across README, guides, docs, packages. Use
GitHub-compatible slugging (underscores preserved; my first run produced a false positive on
`#the-shell_unreachable-boundary`). Add lychee for external URLs on a weekly schedule only, with
warn-not-fail. Not merge-blocking: external links flake.

D4. "Claims must cite proof" convention: every dated or status claim in a public guide must be either (a)
generated from a typed record that holds an artifact path, or (b) carry an inline `<!-- proof: path -->`
marker that a 30-line test resolves to an existing file. A verification stamp ("Last verified") is allowed
only when generated from an evidence record; delete the release-please stamp from android_uat.md.

D5. Keep milestones and docs in step: add one line to the phase-completion checklist and to the
release-please PR template: "run `mix crosswake.docs.sync --check && mix docs.verify`; list any public
doc touched". Wire `docs.verify` (D2 + D3 + D4 checks together) to run on every PR that touches
guides/, README, mix.exs, packages/*/mix.exs or lib/ public modules. Also back-fill CHANGELOG from GitHub
releases for 0.2.2 to 0.2.11, or change the policy: replace the hand-authored CHANGELOG with release-please
generated notes plus a hand-written "Upgrade Impact" line enforced by a PR check. I recommend the second,
because the hand-authored process demonstrably stopped after 0.2.1.

D6. Audience split: stop shipping maintainer and adopter-readiness content in the Hex guides. Create
`guides/` = adopters of the library only. Move capability_map's first-adopter sections, "TODO-002", "v20
Pack 1", and support_matrix's promotion-gate table into `docs/` (repo only, not in `files:`) or generate
two projections: a public one (stable support labels only) and an internal one.

## 7. Top 10 fixes ranked by user impact

| Rank | Fix | Horizon | Effort | Why |
|---|---|---|---|---|
| 1 | Fix the adopter proof step: remove `bash script/verify_phase5_example_hosts.sh` from README "Integrating" and install.md steps 4-6, replace with what an adopter can run (`mix crosswake.doctor`, `--native-checks` plus the generated verify hooks). Say clearly which commands need a repo clone. | immediate | S | Every new adopter hits a command that cannot work (F2) |
| 2 | Correct the companion matrix: rulestead 0.1.1, rindle 0.1.0 plus hexdocs link, chimeway 0.1.2, rindle engine "0.4.11"; fix the pinned values in phase132 test at the same time | immediate | S | Public false claim that a published package is unavailable (SEED-020) |
| 3 | Fix CHANGELOG: remove "current published release is 0.2.1" and "no new claims after 0.2.1"; add entries or a pointer to GitHub Releases for 0.2.2 to 0.2.11 | immediate | S | Stated release is ten versions old; Hex package page links here |
| 4 | Android docs: remove "frozen" language (README, support_matrix:92/99/121/285, native_shell), delete the "Last verified" release-please stamp from android_uat.md, remove phantom `companion_snapshot` / `location_capture`, fix the Phase 67/68 row, document minSdk 30, compileSdk 35, Gradle 8.7, JDK 17, Kotlin compiler 1.5.14 in one generated table | immediate (docs part, tied to the unfreeze decision) | M | Unfreeze makes every current Android statement wrong; the "verified" stamp is an unearned claim |
| 5 | Rewrite README top third for an evaluator: one-paragraph value, the three-command install, "what works today" list; move the "Blocked ..." status line and adopter-readiness language out of the front page | near | M | The front page of Hex and HexDocs currently says "Blocked" with no referent |
| 6 | Make `mix docs` fail on warnings, add the link and anchor checker, fix README:235 `mix.exs` link | near | S | Cheap, catches a whole class; found one hexdocs-only break by hand |
| 7 | Telemetry guide: add `[:crosswake, :offline, :replay]`, drop "doctor" from the subsystem list, generate the event table from `events/0` | near | S | Guide claims completeness and is missing an active event; privacy-relevant event |
| 8 | Strip internal codes (`Phase N`, `D-NN`, `TODO-002`, `v20`, `v21`, `CTRL-05`) from public guides and generated renderer prose; add a test that scans `guides/` and README for `\bPhase \d+\b|TODO-\d+|\bD-\d+\b|\bv2\d\b` | near | M | 58 occurrences confuse readers; test prevents re-entry |
| 9 | Move SETUP.md under docs/, retire the phase-110 text, remove the email from the example command | near | S | Public root file is stale and names a personal email |
| 10 | Fix CONTRIBUTING `change_class_entries/0` reference (name the public API that exists or make one) and the Upgrade Impact policy (D5) | near | S | Contributors are told to use a function that does not exist |

Mid and long horizon:
- Mid: generated companion matrix with a scheduled live-registry check (D1); `docs.verify` task (D5);
  doctests on pure modules (D2); the claims-cite-proof test (D4).
- Long: audience split of guides (D6); split reference from explanation in the long guides (route_policy,
  native_shell, bridge) so each page is one Diataxis type; weekly external link check.

## 8. Do NOT do

- Do not add a new label taxonomy or more support-truth label classes. AGENTS.md already says prefer
  one-command host proof over new label taxonomy; the problem is truth of values, not vocabulary.
- Do not snapshot whole guides (broad prose snapshots). CONTRIBUTING already rejects this correctly.
- Do not make the live-registry or external-link checks merge-blocking. They would put the network in
  the fast lane and erode it (SEED-020 option 2).
- Do not make a new check merge-blocking before measuring its findings on current `main`
  (absence-scored-as-success lesson). Run each new check in report mode for one cycle first.
- Do not add a docs dashboard, docs site redesign, or a second doc generator beyond `docs.sync`.
- Do not chase doctest coverage across the 906 public functions; start with pure modules.
- Do not hand-edit generated guides to fix them; change the owner module and regenerate.
- Do not search git history or external sources to learn who the first adopter is while rewriting the
  adopter-facing text; use only the codename and "first adopter".
- Do not write Android feature claims during the docs fix; only remove stale "frozen" text and state what
  the evidence supports (JVM hermetic proof, generated-shell proof) until new device evidence exists.

## 9. Gaps and caveats

- Not run: `mix docs` (writes `doc/`), so ExDoc warning counts are unmeasured. First action of the
  fix phase should be to run it once and record the count.
- Claims 10 (doctor hooks in an adopter host) and 42 need a clean-host check. The clean-room harness
  (SEED-004) may already cover it.
- I did not verify the "fourteenth denial reason" claim, the Sigra "14 reserved events" claim, or most
  of the 40 rows in the Promotion gates table. Those are the next sample.
- `git tag` listed nothing in this checkout, so the CHANGELOG-versus-releases gap rests on Hex and
  Maven versions, not tags.
- External URLs were not link-checked.
